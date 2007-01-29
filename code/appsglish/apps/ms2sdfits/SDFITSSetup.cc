//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//# License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#
//# $Id: SDFITSSetup.cc,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#include <SDFITSSetup.h>
#include <FieldHandlers.h>
#include <FITSFieldFillers.h>
#include <FieldCalculator.h>
#include <DataFieldWriter.h>

#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Containers/RecordFieldWriter.h>
#include <fits/FITS/FITSKeywordUtil.h>
#include <fits/FITS/FITSTable.h>
#include <casa/Logging/LogIO.h>
#include <casa/Logging/LogMessage.h>
#include <ms/MeasurementSets/MSReader.h>
#include <tables/Tables/ExprNode.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/TableDesc.h>
#include <casa/Utilities/Assert.h>

#include <casa/namespace.h>
SDFITSSetup::SDFITSSetup(const String &msName, const String &FITSName)
    : itsReader(0), itsWriter(0), itsCalc(0), itsCopier(new MultiRecordFieldWriter)
{
    LogIO os;
    os << LogIO::NORMAL
       << LogOrigin("SDFITSSetup", 
		    "SDFITSSetup(const String &msName, const String &FITSName)", WHERE)
       << "Copying MeasurementSet " << msName << " to SDFITS file " << FITSName
       << LogIO::POST;

    MeasurementSet ms;
    try {
	MeasurementSet fullms(msName, Table::Old);
	// select only those rows where ANTENNA1=ANTENNA2 (which is the definition
	// of single dish) and FEED1=FEED2 (which is too restrictive in the long
	// run but which avoids the need to deal with complex DATA column for now)
	ms = fullms(fullms.col("ANTENNA1") == fullms.col("ANTENNA2") &&
		    fullms.col("FEED1") == fullms.col("FEED2"));
    } catch (AipsError x) {
	os << LogIO::SEVERE
	   << "Could not open " << msName << "as a MeasurementSet, error=" << x.getMesg()
	   << LogIO::EXCEPTION;
    } 

    try {
        itsReader = new MSReader(ms);
	AlwaysAssert(itsReader, AipsError);
	itsReader->gotoRow(0);
    } catch (AipsError x) {
	os << LogIO::SEVERE
	   << "Could not read " << msName << " - probably badly formatted, error=" << x.getMesg()
	   << LogIO::EXCEPTION;
    } 

    try {
	itsCalc = new FieldCalculator(*itsReader);
	AlwaysAssert(itsCalc, AipsError);
    } catch (AipsError x) {
	os << LogIO::SEVERE
	   << "Could not set up the field calculator - this should never happen." << x.getMesg()
	   << LogIO::EXCEPTION;
    }

    itsNames = itsReader->tables();
    itsPrefixes = itsNames;
    setupTableIdxs();
    // reset some of those prefixes - given that we've already ensures that ANTENNA1==ANTENNA2
    // and FEED1==FEED2
    itsPrefixes(itsAntenna1Idx) = "ANTENNA";
    itsPrefixes(itsAntenna2Idx) = "";
    if (itsSyscal1Idx >= 0) {
	itsPrefixes(itsSyscal1Idx) = "SYSCAL";
	itsPrefixes(itsSyscal2Idx) = "";
    }
    itsPrefixes(itsFeed1Idx) = "FEED";
    itsPrefixes(itsFeed2Idx) = "";
    if (itsWeather1Idx >= 0) {
	itsPrefixes(itsWeather1Idx) = "WEATHER";
	itsPrefixes(itsWeather2Idx) = "";
    }
    itsPrefixes(itsPointing1Idx) = "POINTING";
    itsPrefixes(itsPointing2Idx) = "";
    // DATA_DESCRIPTION is completely ignored.  Its is only an indexing table and it
    // is fully reconstructed by sdfits2ms.
    itsPrefixes(itsDataDescIdx) = "";
    // FLAG_CMD is completely ignored.  There will, in general, be multiple rows in that
    // table for the same row in the main table and I can't see how to deal with that
    // in the SDFITS format.
    itsPrefixes(itsFlagCmdIdx) = "";
    // HISTORY is not even handled by MSReader

    uInt ntables = itsNames.nelements();
    itsMaxLengths.resize(ntables);
    itsMaxLengths = 0;
    itsTdims.resize(ntables);
    itsTdims = 0;
    itsSpecialHandlers.resize(ntables);
    itsSpecialHandlers = 0;
    itsHandlers.resize(ntables);
    itsHandlers = 0;
    itsIsHandled.resize(ntables);
    itsIsHandled = 0;
    itsBlockedColumns.resize(ntables);
    itsBlockedColumns = 0;

    for (uInt i=0; i < itsNames.nelements(); i++) {
        itsSpecialHandlers[i] = 0;
	uInt nfields = getRecord(i).description().nfields();
	itsIsHandled[i] = new Vector<Bool>(nfields, False);
	itsTdims[i] = new Record;
	AlwaysAssert(itsTdims[i], AipsError);
	itsMaxLengths[i] = new Record(scanTable(getTable(i), *(itsTdims[i])));
	itsBlockedColumns[i] = new Vector<String>();
    }
    setup_blockers();
    setup_special_handlers();

    initCoupledSubtables();
    for (uInt i=0; i < ntables; i++) {
        init(i);
    }

    try {
	Record extraKeywords;
	extraKeywords.define("EXTNAME", "SINGLE DISH");
	extraKeywords.setComment("EXTNAME","Single Dish FITS convention");
	extraKeywords.define("EXTVER", 1);
	extraKeywords.setComment("EXTVER", "Version");
	if (itsReader->ms().keywordSet().isDefined("MS_VERSION")) {
	    extraKeywords.define("MS_VERS",
				 itsReader->ms().keywordSet().asFloat("MS_VERSION"));
	    extraKeywords.setComment("MS_VERS", "MS version, from MS_VERSION keyword in original MS");
	}
	FitsOutput *the_writer = FITSTableWriter::makeWriter(FITSName);
	itsWriter = new FITSTableWriter(the_writer, itsFITSDescription,
					itsMaxOutLengths, itsReader->ms().nrow(),
					extraKeywords, itsFITSUnits, True,
					itsFITSTdims);
    } catch (AipsError x) {
	os << LogIO::SEVERE
	   << "Could not create output FITS file " << FITSName
	   << " perhaps file is not writable or supplied format is "
	   << "illegal, error=" << x.getMesg()
	   << LogIO::EXCEPTION;
    } 

    createCoupledSubtables();
    for (uInt i=0; i < ntables; i++) {
        create(i);
    }

}

SDFITSSetup::~SDFITSSetup()
{
    delete itsReader; itsReader = 0;
    delete itsWriter; itsWriter = 0;
    delete itsCopier; itsCopier = 0;

    for (uInt j=0; j<itsMaxLengths.nelements(); j++) {
	PtrBlock<RecordFieldHandler *> *handlerBlock = static_cast<PtrBlock<RecordFieldHandler *> *>(itsHandlers[j]);
        if (handlerBlock) {
	    for (uInt i=0; i < handlerBlock->nelements(); i++) {
		delete (*handlerBlock)[i];
	    }
	}
	delete handlerBlock;
	handlerBlock = 0;
	delete itsSpecialHandlers[j];
	itsSpecialHandlers[j] = 0;
	delete itsBlockedColumns[j];
	itsBlockedColumns[j] = 0;
	delete itsMaxLengths[j];
	itsMaxLengths[j] = 0;
	delete itsTdims[j];
	itsTdims[j] = 0;
    }
    LogIO os;
    os << LogIO::NORMAL
       << LogOrigin("SDFITSSetup", "~SDFITSSetup()", WHERE)
       << "Finished!"
       << LogIO::POST;
}

const RecordInterface &SDFITSSetup::getRecord(uInt whichTable)
{
    DebugAssert(whichTable < itsNames.nelements(), AipsError);
    String name = itsNames(whichTable);
    return itsReader->tableRow(name);
}

const RecordInterface &SDFITSSetup::getUnitRecord(uInt whichTable)
{
    // not yet available - not sure what this really needs
    DebugAssert(whichTable < itsNames.nelements(), AipsError);
    String name = itsNames(whichTable);
    return itsReader->units(name);
}

const Table &SDFITSSetup::getTable(uInt whichTable)
{
    DebugAssert(whichTable < itsNames.nelements(), AipsError);
    return itsReader->table(itsNames(whichTable));
}

void SDFITSSetup::setup_blockers()
{
    // here ID columns are generally blocked as are columns we can't deal with (complex DATA)
    // or shouldn't need to deal with (UVW)
    // keep FEED1 and FEED2 although they are identical at this point eventually they may
    // not be and that preserves a FEED ID which may be something unique to that telescope.
    itsBlockedColumns[itsMainIdx]->resize(13);
    (*itsBlockedColumns[itsMainIdx])(0) = MS::columnName(MS::ANTENNA1);
    (*itsBlockedColumns[itsMainIdx])(1) = MS::columnName(MS::ANTENNA2);
    (*itsBlockedColumns[itsMainIdx])(2) = MS::columnName(MS::ANTENNA3);
    (*itsBlockedColumns[itsMainIdx])(3) = MS::columnName(MS::DATA_DESC_ID);
    (*itsBlockedColumns[itsMainIdx])(4) = MS::columnName(MS::PROCESSOR_ID);
    (*itsBlockedColumns[itsMainIdx])(5) = MS::columnName(MS::OBSERVATION_ID);
    (*itsBlockedColumns[itsMainIdx])(6) = MS::columnName(MS::FIELD_ID);
    (*itsBlockedColumns[itsMainIdx])(7) = MS::columnName(MS::STATE_ID);
    (*itsBlockedColumns[itsMainIdx])(8) = MS::columnName(MS::UVW);
    (*itsBlockedColumns[itsMainIdx])(9) = MS::columnName(MS::UVW2);
    (*itsBlockedColumns[itsMainIdx])(10) = MS::columnName(MS::DATA);
    (*itsBlockedColumns[itsMainIdx])(11) = MS::columnName(MS::LAG_DATA);
    // I'm just not sure what to do with the FLAG_CATEGORY columns
    (*itsBlockedColumns[itsMainIdx])(12) = MS::columnName(MS::FLAG_CATEGORY);

    // nothing to block in antenna

    // DATA_DESCRIPTION is completely blocked by setting itsPrefixes to an empty
    // string for that table.  This table is only an indexing table and it is
    // fully reconstructed by sdfits2ms.

    // for DOPPLER table, block SOURCE_ID but not DOPPLER_ID
    if (itsDopplerIdx >= 0) {
	itsBlockedColumns[itsDopplerIdx]->resize(1);
	(*itsBlockedColumns[itsDopplerIdx])(0) = MSDoppler::columnName(MSDoppler::SOURCE_ID);
    }

    itsBlockedColumns[itsFeed1Idx]->resize(3);
    (*itsBlockedColumns[itsFeed1Idx])(0) = MSSysCal::columnName(MSSysCal::ANTENNA_ID);
    (*itsBlockedColumns[itsFeed1Idx])(1) = MSSysCal::columnName(MSSysCal::FEED_ID);
    (*itsBlockedColumns[itsFeed1Idx])(2) = MSSysCal::columnName(MSSysCal::SPECTRAL_WINDOW_ID);

    itsBlockedColumns[itsFeed2Idx]->resize(3);
    (*itsBlockedColumns[itsFeed2Idx])(0) = MSSysCal::columnName(MSSysCal::ANTENNA_ID);
    (*itsBlockedColumns[itsFeed2Idx])(1) = MSSysCal::columnName(MSSysCal::FEED_ID);
    (*itsBlockedColumns[itsFeed2Idx])(2) = MSSysCal::columnName(MSSysCal::SPECTRAL_WINDOW_ID);

    itsBlockedColumns[itsFieldIdx]->resize(2);
    (*itsBlockedColumns[itsFieldIdx])(0) = MSField::columnName(MSField::SOURCE_ID);
    (*itsBlockedColumns[itsFieldIdx])(1) = MSField::columnName(MSField::NUM_POLY);

    // FLAG_CMD is currently ignored completely because I don't know how to handle it.

    if (itsFreqOffsetIdx >= 0) {
	itsBlockedColumns[itsFreqOffsetIdx]->resize(4);
	(*itsBlockedColumns[itsFreqOffsetIdx])(0) = MSFreqOffset::columnName(MSFreqOffset::ANTENNA1);
	(*itsBlockedColumns[itsFreqOffsetIdx])(1) = MSFreqOffset::columnName(MSFreqOffset::ANTENNA2);
	(*itsBlockedColumns[itsFreqOffsetIdx])(2) = MSFreqOffset::columnName(MSFreqOffset::FEED_ID);
	(*itsBlockedColumns[itsFreqOffsetIdx])(3) = MSFreqOffset::columnName(MSFreqOffset::SPECTRAL_WINDOW_ID);
    }

    // HISTORY is completely ignored because I don't know how to handle it.

    // Block these because we can't write Arrays of strings to FITS yet
    itsBlockedColumns[itsObservationIdx]->resize(2);
    (*itsBlockedColumns[itsObservationIdx])(0) = "SCHEDULE";
    (*itsBlockedColumns[itsObservationIdx])(1) = "LOG";

    // POINTING::DIRECTION is handled in FieldCalculator
    itsBlockedColumns[itsPointing1Idx]->resize(5);
    (*itsBlockedColumns[itsPointing1Idx])(0) = MSPointing::columnName(MSPointing::ANTENNA_ID);
    (*itsBlockedColumns[itsPointing1Idx])(1) = MSPointing::columnName(MSPointing::DIRECTION);
    // sdfits2ms can't yet deal with NUM_POLY values, block here for now until that can be fixed
    (*itsBlockedColumns[itsPointing1Idx])(2) = MSPointing::columnName(MSPointing::NUM_POLY);
    (*itsBlockedColumns[itsPointing1Idx])(3) = MSPointing::columnName(MSPointing::TARGET);
    // not much point in carrying this around until the NUM_POLY values can be handled
    (*itsBlockedColumns[itsPointing1Idx])(4) = MSPointing::columnName(MSPointing::TIME_ORIGIN);

    itsBlockedColumns[itsPointing2Idx]->resize(5);
    (*itsBlockedColumns[itsPointing2Idx])(0) = MSPointing::columnName(MSPointing::ANTENNA_ID);
    (*itsBlockedColumns[itsPointing2Idx])(1) = MSPointing::columnName(MSPointing::DIRECTION);
    // sdfits2ms can't yet deal with NUM_POLY values, block here for now until that can be fixed
    (*itsBlockedColumns[itsPointing2Idx])(2) = MSPointing::columnName(MSPointing::NUM_POLY);
    (*itsBlockedColumns[itsPointing2Idx])(3) = MSPointing::columnName(MSPointing::TARGET);
    // not much point in carrying this around until the NUM_POLY values can be handled
    (*itsBlockedColumns[itsPointing2Idx])(4) = MSPointing::columnName(MSPointing::TIME_ORIGIN);

    // nothing is blocked in POLARIZATION

    // nothing is blocked in PROCESSOR

    // SOURCE table is optional
    if (itsSourceIdx >= 0) {
	itsBlockedColumns[itsSourceIdx]->resize(4);
	(*itsBlockedColumns[itsSourceIdx])(0) = MSSource::columnName(MSSource::SOURCE_ID);
	(*itsBlockedColumns[itsSourceIdx])(1) = MSSource::columnName(MSSource::SPECTRAL_WINDOW_ID);
	(*itsBlockedColumns[itsSourceIdx])(2) = MSSource::columnName(MSSource::NUM_LINES);
	// REST FREQ for NUM_LINES==1 is handled elsewhere, the sdfits2ms reader can't
	// yet handle multiple lines on the other end so block it here for now
	(*itsBlockedColumns[itsSourceIdx])(3) = 
	    MSSource::columnName(MSSource::REST_FREQUENCY);
    }

    // NUM_CHAN is redundent, RESOLUTION, CHAN_FREQ and REF_FREQUENCY are
    // handled elsewhere, and CHAN_WIDTH and EFFECTIVE_BW can't yet be
    // handled here.  MEAS_FREQ_REF is only written by the table measures system
    // and so it is blocked here.
    itsBlockedColumns[itsSpecWinIdx]->resize(7);
    (*itsBlockedColumns[itsSpecWinIdx])(0) = 
	MSSpectralWindow::columnName(MSSpectralWindow::NUM_CHAN);
    (*itsBlockedColumns[itsSpecWinIdx])(1) = 
	MSSpectralWindow::columnName(MSSpectralWindow::RESOLUTION);
    (*itsBlockedColumns[itsSpecWinIdx])(2) = 
	MSSpectralWindow::columnName(MSSpectralWindow::CHAN_FREQ);
    (*itsBlockedColumns[itsSpecWinIdx])(3) = 
	MSSpectralWindow::columnName(MSSpectralWindow::REF_FREQUENCY);
    (*itsBlockedColumns[itsSpecWinIdx])(4) = 
	MSSpectralWindow::columnName(MSSpectralWindow::CHAN_WIDTH);
    (*itsBlockedColumns[itsSpecWinIdx])(5) = 
	MSSpectralWindow::columnName(MSSpectralWindow::EFFECTIVE_BW);
    (*itsBlockedColumns[itsSpecWinIdx])(6) = 
	MSSpectralWindow::columnName(MSSpectralWindow::MEAS_FREQ_REF);

    // nothing is blocked in STATE

    // SYSCAL table is optional
    if (itsSyscal1Idx >= 0) {
	// *_SPECTRUM can't be handled here
	itsBlockedColumns[itsSyscal1Idx]->resize(9);
	(*itsBlockedColumns[itsSyscal1Idx])(0) = MSSysCal::columnName(MSSysCal::ANTENNA_ID);
	(*itsBlockedColumns[itsSyscal1Idx])(1) = MSSysCal::columnName(MSSysCal::FEED_ID);
	(*itsBlockedColumns[itsSyscal1Idx])(2) = MSSysCal::columnName(MSSysCal::SPECTRAL_WINDOW_ID);
	(*itsBlockedColumns[itsSyscal1Idx])(3) = MSSysCal::columnName(MSSysCal::TCAL_SPECTRUM);
	(*itsBlockedColumns[itsSyscal1Idx])(4) = MSSysCal::columnName(MSSysCal::TRX_SPECTRUM);
	(*itsBlockedColumns[itsSyscal1Idx])(5) = MSSysCal::columnName(MSSysCal::TSKY_SPECTRUM);
	(*itsBlockedColumns[itsSyscal1Idx])(6) = MSSysCal::columnName(MSSysCal::TSYS_SPECTRUM);
	(*itsBlockedColumns[itsSyscal1Idx])(7) = MSSysCal::columnName(MSSysCal::TANT_SPECTRUM);
	(*itsBlockedColumns[itsSyscal1Idx])(8) = MSSysCal::columnName(MSSysCal::TANT_TSYS_SPECTRUM);

	itsBlockedColumns[itsSyscal2Idx]->resize(9);
	(*itsBlockedColumns[itsSyscal2Idx])(0) = MSSysCal::columnName(MSSysCal::ANTENNA_ID);
	(*itsBlockedColumns[itsSyscal2Idx])(1) = MSSysCal::columnName(MSSysCal::FEED_ID);
	(*itsBlockedColumns[itsSyscal2Idx])(2) = MSSysCal::columnName(MSSysCal::SPECTRAL_WINDOW_ID);
	(*itsBlockedColumns[itsSyscal1Idx])(3) = MSSysCal::columnName(MSSysCal::TCAL_SPECTRUM);
	(*itsBlockedColumns[itsSyscal1Idx])(4) = MSSysCal::columnName(MSSysCal::TRX_SPECTRUM);
	(*itsBlockedColumns[itsSyscal1Idx])(5) = MSSysCal::columnName(MSSysCal::TSKY_SPECTRUM);
	(*itsBlockedColumns[itsSyscal1Idx])(6) = MSSysCal::columnName(MSSysCal::TSYS_SPECTRUM);
	(*itsBlockedColumns[itsSyscal1Idx])(7) = MSSysCal::columnName(MSSysCal::TANT_SPECTRUM);
	(*itsBlockedColumns[itsSyscal1Idx])(8) = MSSysCal::columnName(MSSysCal::TANT_TSYS_SPECTRUM);
    }

    // WEATHER table is optional
    if (itsWeather1Idx >= 0) {
	itsBlockedColumns[itsWeather1Idx]->resize(1);
	(*itsBlockedColumns[itsWeather1Idx])(0) = MSWeather::columnName(MSWeather::ANTENNA_ID);
	
	itsBlockedColumns[itsWeather2Idx]->resize(1);
	(*itsBlockedColumns[itsWeather2Idx])(0) = MSWeather::columnName(MSWeather::ANTENNA_ID);
    }

    // block all columns with size == 0 in maxLengths[whichTable]
    // There's nothing in the columns so there should be no need to
    // retain them in the FITS file.
    for (uInt i=0;i<itsNames.nelements();i++) {
	Vector<Int> sizes(itsMaxLengths[i]->nfields());
	uInt nzero = 0;
	for (uInt j=0;j<itsMaxLengths[i]->nfields();j++) {
	    if (itsMaxLengths[i]->type(j) == TpArrayInt) {
		Vector<Int> shape;
		itsMaxLengths[i]->get(j,shape);
		sizes(j) = shape.nelements();
	    } else {
		itsMaxLengths[i]->get(j,sizes(j));
	    }
	    if (sizes(j) == 0) nzero++;
	}
	if (nzero > 0) {
	    uInt oldSize = itsBlockedColumns[i]->nelements();
	    itsBlockedColumns[i]->resize(oldSize+nzero, True);
	    nzero = 0;
	    for (uInt j=0;j<itsMaxLengths[i]->nfields();j++) {
		if (sizes(j) == 0) {
		    (*itsBlockedColumns[i])(nzero+oldSize) = itsMaxLengths[i]->name(j);
		    nzero++;
		}
	    }
	}
    }
}

void SDFITSSetup::setup_special_handlers()
{
    itsSpecialHandlers[itsMainIdx] = new HandleSpecialMainSDFITSFields(*itsReader);
    itsSpecialHandlers[itsObservationIdx] = new HandleSpecialObservationSDFITSFields(*itsReader);
    // SOURCE table is optioanl
    if (itsSourceIdx >= 0) {
	itsSpecialHandlers[itsSourceIdx] = new HandleSpecialSourceSDFITSFields(*itsReader);
    }
    itsSpecialHandlers[itsSpecWinIdx] = 
        new HandleSpecialSpectralWindowSDFITSFields(*itsReader);
    // this assumes FEED1==FEED and ANTENNA1==ANTENNA2
    // SYSCAL table is optional
    if (itsSyscal1Idx >= 0) {
	itsSpecialHandlers[itsSyscal1Idx] = new HandleSpecialSysCalSDFITSFields(*itsReader);
    }
}

void SDFITSSetup::initCoupledSubtables()
{
    // DATA (FLOAT_DATA -> DATA)
    const RecordInterface &mainRow = itsReader->tableRow("MAIN");
    String dataColName = MS::columnName(MS::FLOAT_DATA);
    Int whichField = mainRow.description().fieldNumber(dataColName);
    AlwaysAssert(whichField >= 0, AipsError);
    (*itsIsHandled[itsMainIdx])(whichField) = True;

    // variable shaped data?
    Vector<Int> shape;
    (*itsMaxLengths[itsMainIdx]).get(dataColName, shape);
    if (anyLT(shape, 0)) {
	AlwaysAssert((*itsTdims[itsMainIdx]).fieldNumber(dataColName)>=0, AipsError);
	itsFITSDescription.addField("DATA", TpArrayFloat);
	itsMaxOutLengths.define("DATA", abs(product(shape)));
	// decode the shape in itsTdims back into a shape
	String maxTdim = (*itsTdims[itsMainIdx]).asString(dataColName);
	IPosition maxShape;
	FITSKeywordUtil::fromTDIM(maxShape, maxTdim);
	// convert this into the max swapped shape
	IPosition trueMaxShape(4);
	trueMaxShape(0) = maxShape(1);
	trueMaxShape(1) = maxShape(0);
	trueMaxShape(2) = trueMaxShape(3) = 1;
	// and back into a string
	FITSKeywordUtil::toTDIM(maxTdim, trueMaxShape);
	// and put it here to pass along to other classes
	itsFITSTdims.define("DATA", maxTdim);
    } else {
	// fixed shape
	IPosition degenerateShape(4); // Add RA/DEC
	degenerateShape(0) = shape(1);
	degenerateShape(1) = shape(0); // swap stokes/freq axes
	degenerateShape(2) = degenerateShape(3) = 1;
	itsFITSDescription.addField("DATA", TpFloat, degenerateShape);
    }
    
    // are there units for the FLOAT_DATA column?, don't know what to do here
    //if (reader->mainUnits().isDefined(MS::columnName(MS::FLOAT_DATA))) {
    //	FITSUnits.define("DATA", reader->mainUnits().asString(MS::columnName(MS::FLOAT_DATA)));
    //}

    // Coordinates
    itsFITSDescription.addField("CRVAL1", TpDouble);
    itsFITSDescription.addField("CRVAL2", TpDouble);
    itsFITSDescription.addField("CRVAL3", TpDouble);
    itsFITSDescription.addField("CRVAL4", TpDouble);
    itsFITSDescription.addField("CRPIX1", TpDouble);
    itsFITSDescription.addField("CRPIX2", TpDouble);
    itsFITSDescription.addField("CRPIX3", TpDouble);
    itsFITSDescription.addField("CRPIX4", TpDouble);
    itsFITSDescription.addField("CDELT1", TpDouble);
    itsFITSDescription.addField("CDELT2", TpDouble);
    itsFITSDescription.addField("CDELT3", TpDouble);
    itsFITSDescription.addField("CDELT4", TpDouble);
    itsFITSDescription.addField("CTYPE1", TpString);
    itsFITSDescription.addField("CTYPE2", TpString);
    itsFITSDescription.addField("CTYPE3", TpString);
    itsFITSDescription.addField("CTYPE4", TpString);
    itsFITSDescription.addField("CUNIT1", TpString);
    itsFITSDescription.addField("CUNIT2", TpString);
    itsFITSDescription.addField("CUNIT3", TpString);
    itsFITSDescription.addField("CUNIT4", TpString);
    itsFITSDescription.addField("EQUINOX", TpDouble);
    itsFITSDescription.addField("RADECSYS", TpString);
    itsFITSDescription.addField("VELDEF", TpString);
    itsMaxOutLengths.define("CTYPE1", 8);
    itsMaxOutLengths.define("CTYPE2", 8);
    itsMaxOutLengths.define("CTYPE3", 8);
    itsMaxOutLengths.define("CTYPE4", 8);
    itsMaxOutLengths.define("CUNIT1", 8);
    itsMaxOutLengths.define("CUNIT2", 8);
    itsMaxOutLengths.define("CUNIT3", 8);
    itsMaxOutLengths.define("CUNIT4", 8);
    itsMaxOutLengths.define("RADECSYS", 8);
    itsMaxOutLengths.define("VELDEF", 8);
    // Need to get rid of the columns that go into the above
}

void SDFITSSetup::createCoupledSubtables()
{
    // DATA (FLOAT_DATA -> DATA)
    itsCopier->addWriter(new DataFieldWriter(itsWriter->row(), itsReader->tableRow("MAIN")));
    itsCopier->addWriter(new CoordinateWriter(itsWriter->row(), *itsCalc));
}

void SDFITSSetup::init(uInt forWhichTable)
{
    const RecordInterface &record = getRecord(forWhichTable);
    // const RecordInterface &units = getUnitRecord(forWhichTable);
    Record units;

    // Special first
    if (itsSpecialHandlers[forWhichTable]) {
	RecordDesc desc = record.description();
	itsSpecialHandlers[forWhichTable]->setupFieldHandling(itsFITSDescription, itsMaxOutLengths, itsFITSUnits, 
							      itsFITSTdims, desc, *(itsMaxLengths[forWhichTable]), 
							      units, *(itsTdims[forWhichTable]),
							      *(itsIsHandled[forWhichTable]));
    }
    // then the regular handler
    if (itsHandlers[forWhichTable]) {
	delete static_cast<PtrBlock<RecordFieldHandler *> *>(itsHandlers[forWhichTable]);
	itsHandlers[forWhichTable] = 0;
    }
    // we don't want a handler at all if itsPrefixes(forWhichTable) is empty
    // Also, we don't want a handler at all if the table in question has no rows
    if (itsPrefixes(forWhichTable).length() > 0 && getTable(forWhichTable).nrow() > 0) {
	PtrBlock<RecordFieldHandler *> *handler = new PtrBlock<RecordFieldHandler *>(0);
	AlwaysAssert(handler, AipsError);
	itsHandlers[forWhichTable] = handler;
	handler->resize(2);
	
	(*handler)[0] = new HandleRecordFieldsByBlocking(*(itsBlockedColumns[forWhichTable]));
	(*handler)[1] = new HandleRecordFieldsByCopying(itsPrefixes(forWhichTable),*itsReader);
	
	uInt n = handler->nelements();
	for (uInt i=0; i<n; i++) {
	    (*handler)[i]->setupFieldHandling(itsFITSDescription, itsMaxOutLengths, itsFITSUnits,
					      itsFITSTdims, record.description(), *(itsMaxLengths[forWhichTable]), 
					      units, *(itsTdims[forWhichTable]), 
					      *(itsIsHandled[forWhichTable]));
	}
    }
}

void SDFITSSetup::create(uInt forWhichTable)
{
    const RecordInterface &row = getRecord(forWhichTable);

    // Specials first
    if (itsSpecialHandlers[forWhichTable]) {
	itsSpecialHandlers[forWhichTable]->setupCopiers(*itsCopier, itsWriter->row(), row);
    }

    // regulars, when necessary
    if (itsHandlers[forWhichTable]) {
	uInt n = static_cast<PtrBlock<RecordFieldHandler *> *>(itsHandlers[forWhichTable])->nelements();

	for (uInt i=0; i<n; i++) {
	    static_cast<PtrBlock<RecordFieldHandler *> *>(itsHandlers[forWhichTable])->
		operator[](i)->setupCopiers(*itsCopier, itsWriter->row(), row);
	}
    }
}

void SDFITSSetup::setupTableIdxs()
{
    itsMainIdx = itsAntenna1Idx = itsAntenna2Idx = itsFieldIdx = itsObservationIdx =
	itsSourceIdx = itsSpecWinIdx = itsSyscal1Idx = itsSyscal2Idx = itsFeed1Idx = itsFeed2Idx =
	itsWeather1Idx = itsWeather2Idx = itsPointing1Idx = itsPointing2Idx = itsDataDescIdx = 
	itsDopplerIdx = itsFlagCmdIdx = itsFreqOffsetIdx = -1;

    for (uInt i=0; i<itsNames.nelements(); i++) {
	String name = itsNames(i);
	if (name == "MAIN") itsMainIdx = i;
	else if (name == "ANTENNA1") itsAntenna1Idx = i;
	else if (name == "ANTENNA2") itsAntenna2Idx = i;
	else if (name == "FIELD") itsFieldIdx = i;
	else if (name == "OBSERVATION") itsObservationIdx = i;
	else if (name == "SOURCE") itsSourceIdx = i;
	else if (name == "SPECTRAL_WINDOW") itsSpecWinIdx = i;
	else if (name == "SYSCAL1") itsSyscal1Idx = i;
	else if (name == "SYSCAL2") itsSyscal2Idx = i;
	else if (name == "FEED1") itsFeed1Idx = i;
	else if (name == "FEED2") itsFeed2Idx = i;
	else if (name == "WEATHER1") itsWeather1Idx = i;
	else if (name == "WEATHER2") itsWeather2Idx = i;
	else if (name == "POINTING1") itsPointing1Idx = i;
	else if (name == "POINTING2") itsPointing2Idx = i;
	else if (name == "DATA_DESCRIPTION") itsDataDescIdx = i;
	else if (name == "DOPPLER") itsDopplerIdx = i;
	else if (name == "FLAG_CMD") itsFlagCmdIdx = i;
	else if (name == "FREQ_OFFSET") itsFreqOffsetIdx = i;
    }
}

Record SDFITSSetup::scanTable(const Table &table, Record &tdims)
{
    LogIO os;
    os << LogOrigin("SDFITSSetup","scanTable(const Table &table");

    Record retval;

    // reset tdims
    tdims = Record();

    Vector<String> columnsToRead;
    TableDesc desc = table.tableDesc();

    uInt ncol = desc.ncolumn();
    for (uInt i=0; i<ncol; i++) {
        uInt which = columnsToRead.nelements();
        ColumnDesc coldesc = desc[i];
	if (coldesc.isArray()) {
	    if (coldesc.dataType() == TpArrayString ||
		coldesc.dataType() == TpString) {
		// Arrays of Strings are not yet supported in our
		// FITS writer, so this is part of an attept to deal with it
		columnsToRead.resize(which+1, True);
		columnsToRead(which) = coldesc.name();
		retval.define(coldesc.name(), Int(0));
	    } else if (coldesc.isFixedShape()) {
		// initial tdims field is an empty string
		tdims.define(coldesc.name(),"");
	        retval.define(coldesc.name(), coldesc.shape().asVector());
	    } else {
		// initial tdims field is an empty string
		tdims.define(coldesc.name(),"");
	        columnsToRead.resize(which+1, True);
		columnsToRead(which) = coldesc.name();
		IPosition dummy;
		retval.define(coldesc.name(), dummy.asVector());
	    }
	} else if (coldesc.dataType() == TpString) {
	    columnsToRead.resize(which+1, True);
	    columnsToRead(which) = coldesc.name();
	    retval.define(coldesc.name(), Int(0));
	}
    }

    ROTableRow reader(table, columnsToRead);
    uInt nrow = reader.table().nrow();

    // Figure out which fields in retval map to which columns
    // in reader.record().
    Block<Int> retvalMap(columnsToRead.nelements());
    Block<Int> readerMap(columnsToRead.nelements());
    Block<Int> tdimsMap(columnsToRead.nelements());
    for (uInt i=0; i<retvalMap.nelements(); i++) {
        readerMap[i] = reader.record().description().fieldNumber(columnsToRead(i));
	retvalMap[i] = retval.description().fieldNumber(columnsToRead(i));
	tdimsMap[i] = tdims.description().fieldNumber(columnsToRead(i));
	AlwaysAssert(retvalMap[i] >= 0, AipsError);
	AlwaysAssert(readerMap[i] >= 0, AipsError);
    }

    uInt nfields = columnsToRead.nelements();
    String tmpstring;
    Array<String> tmpArrString;
    Vector<Int> tmpvec;

    for (uInt row=0; row<nrow; row++) {
        reader.get(row);
	for (uInt field=0; field < nfields; field++) {
	    DataType type = reader.record().description().type(readerMap[field]);
	    if (type == TpString) {
	        // Interested in length
	        reader.record().get(readerMap[field], tmpstring);
		Int newlength = tmpstring.length();
		// It was initialized to zero, so the following will always work.
		Int oldlength;
		retval.get(retvalMap[field], oldlength);
		if (newlength > oldlength) {
		    retval.define(retvalMap[field], newlength);
		}
	    } else if (type == TpArrayString) {
		ostringstream ost;
		reader.record().get(readerMap[field], tmpArrString);
		ost << tmpArrString;
		Int oldlength;
		retval.get(retvalMap[field], oldlength);
		String strost(ost);
		if (strost.length() > oldlength) {
		    retval.define(retvalMap[field], Int(strost.length()));
		}
	    } else if (isArray(type)) {
	        // It's an array, Interested in shape
	        IPosition tmpshape = reader.record().shape(readerMap[field]);
		if (row == 0) {
		    retval.define(retvalMap[field], tmpshape.asVector());
		    if (tmpshape.nelements() > 1) {
			// this always gets a tdim value
			String tdim;
			FITSKeywordUtil::toTDIM(tdim, tmpshape);
			tdims.define(tdimsMap[field], tdim);
		    }
		} else {
		    // Verify that the shape hasn't changed
		    retval.get(retvalMap[field], tmpvec);
		    uInt n = tmpshape.nelements();
		    if (tmpvec.nelements() != n) {
			os << WHERE
			   << LogIO::WARN
			   << "Variable number of dimensions in column "
			   << reader.record().description().name(readerMap[field])
			   << ", of table " << table.tableName() 
			   << " - this is not yet supported.  This column will be ignored."
			   << LogIO::POST;
			retval.define(retvalMap[field], Vector<Int>());
		    }
		    // are the shapes the same
		    Bool sameShape = True;
		    uInt i=0;
		    while (i<n && sameShape) {
			if (abs(tmpvec(i)) != tmpshape(i)) sameShape = False;
			i++;
		    }
		    if (!sameShape) {
			// remember the one with largest number of elements in the array
			// and store it as negative values
			if (tmpshape.product() > product(abs(tmpvec))) {
			    retval.define(retvalMap[field],-(tmpshape.asVector()));
			} else {
			    // ensure that tmpvec has negative values
			    if (anyGT(tmpvec,0)) {
				retval.define(retvalMap[field], -(abs(tmpvec)));
			    }
			}
			// what is the TDIM of this one
			String tdim;
			FITSKeywordUtil::toTDIM(tdim, tmpshape);
			// is this one bigger
			if (tdim.length() > tdims.asString(tdimsMap[field]).length())
			    tdims.define(tdimsMap[field], tdim);
		    }
		}
	    }
	}
    }
    return retval;
}
