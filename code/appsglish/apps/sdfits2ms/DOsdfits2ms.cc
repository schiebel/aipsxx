//# DOsdfits2ms.cc:  this implements the sdfits2ms DO
//# Copyright (C) 2000,2001,2002
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
//# $Id: DOsdfits2ms.cc,v 19.7 2005/11/07 21:17:04 wyoung Exp $

//# Includes

#include <appsglish/sdfits2ms/DOsdfits2ms.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/MethodResult.h>
#include <casa/OS/File.h>
#include <casa/Logging/LogIO.h>
#include <fits/FITS/SDFITSTable.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/TableDesc.h>
#include <casa/System/ProgressMeter.h>
#include <dish/SDIterators/SDFITSDataIterator.h>
#include <msfits/MSFits/SDAntennaHandler.h>
#include <msfits/MSFits/SDObservationHandler.h>
#include <msfits/MSFits/SDPolarizationHandler.h>
#include <msfits/MSFits/SDHistoryHandler.h>
#include <msfits/MSFits/SDSpWinHandler.h>
#include <msfits/MSFits/SDDataDescHandler.h>
#include <msfits/MSFits/SDFeedHandler.h>
#include <msfits/MSFits/SDPointingHandler.h>
#include <msfits/MSFits/SDSourceHandler.h>
#include <msfits/MSFits/SDFieldHandler.h>
#include <msfits/MSFits/SDSysCalHandler.h>
#include <msfits/MSFits/SDWeatherHandler.h>
#include <msfits/MSFits/SDMainHandler.h>
#include <msfits/MSFits/SDFITSHandler.h>
#include <tables/Tables/TiledShapeStMan.h>
#include <tables/Tables/IncrementalStMan.h>
#include <tables/Tables/StandardStMan.h>
#include <casa/Arrays/ArrayLogical.h>
#include <tables/Tables/ArrColDesc.h>
#include <casa/BasicMath/Math.h>

#include <casa/namespace.h>
Bool sdfits2ms::convert(const String &msname, const String &sdfitsfile)
{

    LogIO los;
    los << LogOrigin("sdfits2ms","convert(const String &msname, const String &sdfitsfile)");

    // sanity check, sdfitsfile must exist as a readable regular file
    File sdfFile(sdfitsfile);
    if (!sdfFile.exists() || !sdfFile.isReadable()|| !sdfFile.isRegular()) {
	los << LogIO::SEVERE 
	    << WHERE
	    << "SDFITS file: " << sdfitsfile << " - does not exist or is not a regular file"
	    << LogIO::POST;
	return False;
    }
    
    // sanity check, msname must not exist as any type of file and it 
    // must be creatable
    File msFile(msname);
    if (msFile.exists() || !msFile.canCreate()) {
	los << LogIO::SEVERE
	    << WHERE
	    << "new MS: " << msname << " - can not be created (it may already exist)"
	    << LogIO::POST;
	return False;
    }

    SDFITSTable sdfTab(sdfitsfile);
    if (!sdfTab.isSDFITS()) {
	los << LogIO::SEVERE
	    << WHERE
	    << "SDFITS file: " << sdfitsfile << " - is not a valid SDFITS file"
	    << LogIO::POST;
	return False;
    }

    if (sdfTab.nrow()==0) {
	// this might be WARN instead, but I think its severe because no output MS 
	// has been made at this point.
	los << LogIO::SEVERE
	    << WHERE
	    << "SDFITS file: " << sdfitsfile << " - is empty, nothing to convert."
	    << LogIO::POST;
	return False;
    }

    los << LogIO::NORMAL
	<< WHERE
	<< "Copying SDFITS file " << sdfitsfile << " to MeasurementSet " << msname
	<< LogIO::POST;

    // An empty default MeasurementSet
    TableDesc reqTD = MS::requiredTableDesc();
    reqTD.addColumn(ArrayColumnDesc<Float> (MS::columnName(MS::FLOAT_DATA), 2));
    // most columns get this as their default storage manager
    IncrementalStMan ism;
    // some get the standard st man
    StandardStMan stdsm;
    // FLOAT_DATA gets the TiledShapeStMan
    Vector<String> dataCols(1);
    dataCols(0) = MS::columnName(MS::FLOAT_DATA);
    reqTD.defineHypercolumn("FLOAT_DATA", 3, dataCols, Vector<String>(3,""));
    // I have no idea what the most appropriate tile shape is.
    // This tile shape puts one 2x128 spectra in each tile.  Who knows.
    TiledShapeStMan dataStMan("FLOAT_DATA", IPosition(3,2,128,1));
    SetupNewTable newTab(msname, reqTD, Table::New);
    newTab.bindAll(ism);
    newTab.bindColumn(MS::columnName(MS::EXPOSURE), stdsm);
    newTab.bindColumn(MS::columnName(MS::INTERVAL), stdsm);
    newTab.bindColumn(MS::columnName(MS::TIME), stdsm);
    newTab.bindColumn(MS::columnName(MS::TIME_CENTROID), stdsm);
    newTab.bindColumn(MS::columnName(MS::FLOAT_DATA), dataStMan);
    MS ms(newTab);

    // ANTENNA
    SetupNewTable antennaSetup(ms.antennaTableName(),
			       MSAntenna::requiredTableDesc(),Table::New);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::ANTENNA),
			       Table(antennaSetup));

    // DATA_DESCRIPTION
    SetupNewTable dataDescSetup(ms.dataDescriptionTableName(),
			       MSDataDescription::requiredTableDesc(),Table::New);
    dataDescSetup.bindAll(ism);
    dataDescSetup.bindColumn(MSDataDescription::columnName(MSDataDescription::SPECTRAL_WINDOW_ID), stdsm);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::DATA_DESCRIPTION), 
			       Table(dataDescSetup));

    // FEED
    SetupNewTable feedSetup(ms.feedTableName(),
			    MSFeed::requiredTableDesc(),Table::New);
    feedSetup.bindAll(ism);
    feedSetup.bindColumn(MSFeed::columnName(MSFeed::SPECTRAL_WINDOW_ID), stdsm);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::FEED), Table(feedSetup));

    // FLAG_CMD
    SetupNewTable flagCmdSetup(ms.flagCmdTableName(),
			       MSFlagCmd::requiredTableDesc(),Table::New);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::FLAG_CMD), 
				  Table(flagCmdSetup));

    // FIELD
    SetupNewTable fieldSetup(ms.fieldTableName(),
			     MSField::requiredTableDesc(),Table::New);
    fieldSetup.bindAll(ism);
    fieldSetup.bindColumn(MSField::columnName(MSField::SOURCE_ID), stdsm);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::FIELD), Table(fieldSetup));

    // HISTORY
    SetupNewTable historySetup(ms.historyTableName(),
			       MSHistory::requiredTableDesc(),Table::New);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::HISTORY), 
				  Table(historySetup));

    // OBSERVATION
    SetupNewTable observationSetup(ms.observationTableName(),
				   MSObservation::requiredTableDesc(),Table::New);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::OBSERVATION), 
				  Table(observationSetup));

    // POINTING
    SetupNewTable pointingSetup(ms.pointingTableName(),
				MSPointing::requiredTableDesc(),Table::New);
    pointingSetup.bindAll(stdsm);
    pointingSetup.bindColumn(MSPointing::columnName(MSPointing::ANTENNA_ID), ism);
    pointingSetup.bindColumn(MSPointing::columnName(MSPointing::NAME), ism);
    pointingSetup.bindColumn(MSPointing::columnName(MSPointing::NUM_POLY), ism);
    pointingSetup.bindColumn(MSPointing::columnName(MSPointing::TIME_ORIGIN), ism);
    pointingSetup.bindColumn(MSPointing::columnName(MSPointing::TRACKING), ism);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::POINTING),
				  Table(pointingSetup));

    // POLARIZATION
    SetupNewTable polarizationSetup(ms.polarizationTableName(),
				    MSPolarization::requiredTableDesc(),Table::New);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::POLARIZATION),
				  Table(polarizationSetup));

    // PROCESSOR
    SetupNewTable processorSetup(ms.processorTableName(),
				 MSProcessor::requiredTableDesc(),Table::New);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::PROCESSOR),
				  Table(processorSetup));

    // SPECTRAL_WINDOW
    SetupNewTable spectralWindowSetup(ms.spectralWindowTableName(),
				      MSSpectralWindow::requiredTableDesc(),Table::New);
    spectralWindowSetup.bindAll(ism);
    spectralWindowSetup.bindColumn(MSSpectralWindow::columnName(MSSpectralWindow::CHAN_FREQ), stdsm);
    spectralWindowSetup.bindColumn(MSSpectralWindow::columnName(MSSpectralWindow::TOTAL_BANDWIDTH), stdsm);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::SPECTRAL_WINDOW),  
				  Table(spectralWindowSetup));

    // STATE
    SetupNewTable stateSetup(ms.stateTableName(),
			     MSState::requiredTableDesc(),Table::New);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::STATE),  
				  Table(stateSetup));

    // and some optional tables

    // SOURCE
    SetupNewTable sourceSetup(ms.sourceTableName(),
			      MSSource::requiredTableDesc(),Table::New);
    sourceSetup.bindAll(ism);
    sourceSetup.bindColumn(MSSource::columnName(MSSource::SPECTRAL_WINDOW_ID), stdsm);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::SOURCE),
				  Table(sourceSetup));

    // SYSCA
    SetupNewTable syscalSetup(ms.sysCalTableName(),
			      MSSysCal::requiredTableDesc(),Table::New);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::SYSCAL),
				     Table(syscalSetup));
    // WEATHER
    SetupNewTable weatherSetup(ms.weatherTableName(),
			      MSWeather::requiredTableDesc(),Table::New);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::WEATHER),
				     Table(weatherSetup));

    ms.initRefs();

    // okay, we have the SDFITS file and new MS ready to go, now we set up 
    // the handlers.

    // reset the handledCols_p, initially all false
    handledCols_p.resize(sdfTab.description().nfields());
    handledCols_p = False;

    // create the DATA iterator
    SDFITSDataIterator dataIter;
    // and prime it with the first row
    String errMsg;
    if (!dataIter.setrow(sdfTab.currentRow(), errMsg)) {
	los << LogIO::WARN
	    << WHERE
	    << errMsg
	    << LogIO::POST;
    }
    // use the handledColumns from the iterator to initialize handledCols_p
    handledCols_p = dataIter.handledColumns();

    // any TDIM columns have been handled by the SDFITSTable class, so mark
    // them as handled here
    for (uInt i=0;i<handledCols_p.nelements();i++) {
	if (!handledCols_p(i))
	    if (sdfTab.currentRow().name(i).matches(Regex("^TDIM.*"))) handledCols_p(i) = True;
    }

    // nothing here depends on MS_VERS yet, just mark it as handled if present
    Int msVersField = sdfTab.currentRow().fieldNumber("MS_VERS");
    if (msVersField >= 0) handledCols_p(msVersField) = True;

    // other handlers and fillers setup goes here

    // AntennaHandler/filler
    SDAntennaHandler antHandler(ms, handledCols_p, sdfTab.currentRow());
    // need to notice when the antenna id changes
    Int lastAntId = -2;
    // This will hold the telescope position froma
    MeasFrame telFrame;

    // ObservationHandler/filler
    SDObservationHandler obsHandler(ms, handledCols_p, sdfTab.currentRow());
    // PolarizationHandler/filler
    SDPolarizationHandler polHandler(ms, handledCols_p, sdfTab.currentRow());
    // HistoryHandler/filler
    SDHistoryHandler histHandler(ms, handledCols_p, sdfTab.currentRow());
    // we need to pay attention to when the OBSERVATION_ID changes (it can never be -2)
    Int lastObsId = -2;
    // SpWindowHandler/filler
    SDSpWindowHandler spwinHandler(ms, handledCols_p, sdfTab.currentRow());
    // DataDescription handler/filler
    SDDataDescHandler dataDescHandler(ms);
    // Feed handler/filler
    SDFeedHandler feedHandler(ms, handledCols_p, sdfTab.currentRow());
    // Pointing handler/filler
    SDPointingHandler pointingHandler(ms, handledCols_p, sdfTab.currentRow());
    // Source handler/filler
    SDSourceHandler sourceHandler(ms, handledCols_p, sdfTab.currentRow());
    // Field handler/filler
    SDFieldHandler fieldHandler(ms, handledCols_p, sdfTab.currentRow());
    Int lastPointingSize = pointingHandler.nrow();
    // SysCal handler/filler
    SDSysCalHandler syscalHandler(ms, handledCols_p, sdfTab.currentRow());
    // Weather handler/filler
    SDWeatherHandler weatherHandler(ms, handledCols_p, sdfTab.currentRow());
    // Main table handler/filler
    SDMainHandler mainHandler(ms, handledCols_p, sdfTab.currentRow());
    // handle everything that isn't handled yet
    SDFITSHandler sdfitsHandler(ms, handledCols_p, sdfTab.currentRow());
    if (anyEQ(handledCols_p, False)) {
	los << LogIO::WARN << WHERE;
	los << "The following columns are unrecognized and will not appear in the resulting MS:\n";
	for (uInt i=0;i<handledCols_p.nelements();i++) {
	    if (handledCols_p(i) == False) {
		los << LogIO::WARN << sdfTab.currentRow().name(i) << "\n";
	    }
	}
	los << LogIO::WARN << "This was unexpected, please report it using the bug() form." << LogIO::POST;
    }
    
    // loop, over each row and then coordinates in that row
    Int skip = sdfTab.nrow() / 200;
    ProgressMeter meter(0, sdfTab.nrow(), "converting SDFITS to MS", "rows",
			"", "", True, skip);

    while (sdfTab.rownr() < Int(sdfTab.nrow())) {
	// for the first row this duplicates work already done above
	// this shouldn't be too painful - if it is, SDFITSDataIterator might
	// need a public init function which could be called earlier
	if (!dataIter.setrow(sdfTab.currentRow(), errMsg)) {
	    los << LogIO::WARN
		<< WHERE
		<< errMsg
		<< LogIO::POST;
	    los << LogIO::WARN
		<< WHERE
		<< "skipping row " << sdfTab.rownr()
		<< LogIO::POST;
	    // advance to the next row
	    sdfTab.next();
	    meter.update(sdfTab.rownr());
	    continue;
	}
	// fill all of the header stuff, which only changes from row to row
	// this which don't depend on where we are in the data array
	// everything but data values, position, beam id, and receiver id
	// changing time in the iterator only applies to these changing values

	antHandler.fill(sdfTab.currentRow());
	if (antHandler.antennaId() != lastAntId) {
	    lastAntId = antHandler.antennaId();
	    telFrame = MeasFrame(antHandler.telescopePosition());
	}
	obsHandler.fill(sdfTab.currentRow(),antHandler.telescopeName(),dataIter.timeRange());
	polHandler.fill(sdfTab.currentRow(),dataIter.stokes());
	spwinHandler.fill(sdfTab.currentRow(), dataIter.frequencies(),
			  dataIter.freqAxisAtRefPix(), dataIter.freqAxisDelt(),
			  Int(dataIter.freqRefType()));
	dataDescHandler.fill(sdfTab.currentRow(), spwinHandler.spWindowId(),
			     polHandler.polarizationId());
	feedHandler.fill(sdfTab.currentRow(), antHandler.antennaId(),
			 spwinHandler.spWindowId(), dataIter.stokes());
	if (lastObsId != obsHandler.observationId()) {
	    // update the history - nothing really changes here
	    lastObsId = obsHandler.observationId();
	    histHandler.fill(sdfTab.currentRow(), lastObsId, 
			     "sdfits2ms", "NORMAL");			    
	}
	sourceHandler.fill(sdfTab.currentRow(), spwinHandler.spWindowId());
	// step through the data array
	Int loopCount = 0;
	Vector<Double> fullTimeRange(2,0.0);
	MEpoch sampleTime;
	Double averageTime = 0.0;
	for (dataIter.origin(); !dataIter.atEnd(); dataIter.next()) {
	    if (loopCount == 0.0) sampleTime = dataIter.time();
	    Double time = dataIter.time().get("s").getValue();
	    averageTime += time;
	    Vector<Double> timeRange = dataIter.timeRange();
	    if (loopCount == 0) {
		fullTimeRange = timeRange;
	    } else {
		fullTimeRange(0) = min(timeRange(0),fullTimeRange(0));
		fullTimeRange(1) = max(timeRange(1), fullTimeRange(1));
	    }

	    obsHandler.updateTimeRange(dataIter.timeRange());
	    telFrame.set(dataIter.time());
	    pointingHandler.fill(sdfTab.currentRow(), antHandler.antennaId(),
				 time, timeRange, dataIter.direction(), telFrame);
	    if (pointingHandler.nrow() != lastPointingSize) {
		// update the field
		lastPointingSize = pointingHandler.nrow();
		// the concept of a field isn't covered by SDFITS, need it here,
		// though, to catch changes in sdfTab.currentRow()? from an SDFITS
		// file that used to be a MS
		fieldHandler.fill(sdfTab.currentRow(), "", 0, Matrix<Double>(2,1,0.0), 0.0,
				  sourceHandler.sourceId());
	    }
	    syscalHandler.fill(sdfTab.currentRow(), antHandler.antennaId(),
			       feedHandler.feedId(), spwinHandler.spWindowId(),
			       time, timeRange, feedHandler.numReceptors());
	    weatherHandler.fill(sdfTab.currentRow(), antHandler.antennaId(),
				time, timeRange);
	    mainHandler.fill(sdfTab.currentRow(), dataIter.time(), antHandler.antennaId(),
			     feedHandler.feedId(), dataDescHandler.dataDescId(),
			     fieldHandler.fieldId(), dataIter.exposure(),
			     obsHandler.observationId(), dataIter.floatData());
	    loopCount++;
	}
	// now we can handle the otherwise unhandled fields
	MEpoch etime((MVEpoch(Quantity(averageTime/loopCount,"s"))), sampleTime.getRef());
	sdfitsHandler.fill(sdfTab.currentRow(), etime, fullTimeRange(1)-fullTimeRange(0));

	// advance to the next row
	sdfTab.next();
	meter.update(sdfTab.rownr());
    }
    return True;
} 

Vector<String> sdfits2ms::methods() const {
    Vector<String> method(NUMBER_METHODS);
    method(CONVERT) = "convert";
    return method;
}

Vector<String> sdfits2ms::noTraceMethods() const
{
    Vector<String> tmp;
    // everything is traced
    return tmp;
}

MethodResult sdfits2ms::runMethod(uInt which,
				    ParameterSet &parameters,
				    Bool runMethod)
{
    static String returnvalString = "returnval";

    switch (which) {
    case CONVERT:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    static String msString = "msname";
	    Parameter<String> msname(parameters, msString,
					ParameterSet::In);
	    static String sdfitsString = "sdfitsfile";
	    Parameter<String> sdfitsfile(parameters, sdfitsString,
					 ParameterSet::In);
	    if (runMethod) returnval() = convert(msname(), sdfitsfile());
	}
	break;
    default:
	return error("No such method");
    }
    return ok();
}


