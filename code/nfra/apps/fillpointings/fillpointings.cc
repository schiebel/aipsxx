//# fillpointings.cc: Fill a pointing subtable from a WSRT holog observation
//# Copyright (C) 1998,1999,2000,2001,2002
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
//# $Id: fillpointings.cc,v 19.3 2004/11/30 17:50:39 ddebonis Exp $


#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MeasurementSets/MSColumns.h>
#include <ms/MeasurementSets/MSFieldColumns.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/ScaColDesc.h>
#include <tables/Tables/ArrColDesc.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/TableRecord.h>
#include <tables/Tables/ArrayColumn.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Cube.h>
#include <casa/Arrays/Slicer.h>
#include <casa/BasicSL/Constants.h>
#include <casa/BasicMath/Math.h>
#include <casa/Inputs.h>
#include <casa/OS/Path.h>
#include <casa/OS/File.h>
#include <casa/Utilities/Assert.h>
#include <casa/Exceptions/Error.h>
#include <casa/iostream.h>


#include <casa/namespace.h>
void fillPositions (MeasurementSet& itsMS, const String& msName, Double factor,
		    Double tolerance, Bool canexist)
{
    // Exit or delete if POINTING subtable already exists.
    if (itsMS.keywordSet().isDefined ("POINTING")) {
	if (!canexist) {
	    throw (AipsError ("POINTING subtable already exists"));
	}
    }

    // We must add the subtable, thus be able to write into the MS.
    itsMS.reopenRW();
    // Open the MS containing the pointing positions.
    // Check it has the same size and only 1 frequency channel.
    // Get the number of polarizations.
    Table posMS (msName);
    ROArrayColumn<Complex> posMSDataCol (posMS, "DATA");
    uInt nrow = itsMS.nrow();
    AlwaysAssert (nrow == posMS.nrow(), AipsError);
    IPosition dataShape = posMSDataCol.shape(0);
    AlwaysAssert (dataShape(1) == 1, AipsError);

    // Get field id and its RA and DEC.
    ROMSColumns mscol (itsMS);
    ROMSFieldColumns fieldc (itsMS.field());
    Int fieldid = mscol.fieldId()(0);
    String ref = fieldc.delayDir().keywordSet().asString("MEASURE_REFERENCE");
    AlwaysAssert (fieldc.delayDir().keywordSet().asString("UNIT") == "rad",
		  AipsError);
    Vector<Double> fieldPos (fieldc.delayDir()(fieldid));
    Double posfactor = 180 / C::pi;
    factor /= posfactor;                            // convert deg to rad
    cout << "Field center: " << posfactor*fieldPos(0) << ' '
	 << posfactor*fieldPos(1) << " deg" << endl;

    // Setup description of subtable, create it, and add to MS.
    TableDesc td;
    td.addColumn (ScalarColumnDesc<Int> ("ANTENNA_ID"));
    td.addColumn (ScalarColumnDesc<Double> ("TIME"));
    td.rwColumnDesc("TIME").rwKeywordSet().define ("UNIT", "s");
    td.addColumn (ScalarColumnDesc<Double> ("INTERVAL"));
    td.rwColumnDesc("INTERVAL").rwKeywordSet().define ("UNIT", "s");
    td.addColumn (ScalarColumnDesc<String> ("NAME"));
    td.addColumn (ArrayColumnDesc<Double> ("POSITION", IPosition(1,2),
					   ColumnDesc::FixedShape));
    td.rwColumnDesc("POSITION").rwKeywordSet().define ("UNIT", "rad");
    td.rwColumnDesc("POSITION").rwKeywordSet().define ("MEASURE_REFERENCE",
						       ref);
    td.addColumn (ScalarColumnDesc<Bool> ("ON_POSITION"));
    SetupNewTable newtab(itsMS.tableName() + "/POINTING", td, Table::New);

    Table postab(newtab);
    ScalarColumn<Int> posAntCol (postab, "ANTENNA_ID");
    ScalarColumn<Double> posTimCol (postab, "TIME");
    ArrayColumn<Double> posPosCol (postab, "POSITION");
    ScalarColumn<Bool> posOnCol (postab, "ON_POSITION");
    uInt posNrow = 0;

    // Now we start filling the subtable.
    ROScalarColumn<Double> posMSTimeCol (posMS, "TIME");
    Array<Double> times = posMSTimeCol.getColumn();
    Cube<Complex> posData = posMSDataCol.getColumn();

    Bool deleteIt;
    const Double* timesData = times.getStorage (deleteIt);
    Double lasttim = timesData[0] - 1;
    Vector<Complex> lastPos(14);
    lastPos = Complex(-32768*32768,0.);
    Vector<Float> minra(14);
    minra = 1.0e10;
    Vector<Float> mindec(14);
    mindec = 1.0e10;
    Vector<Float> maxra(14);
    maxra = -1.0e10;
    Vector<Float> maxdec(14);
    maxdec = -1.0e10;
    uInt i;
    for (i=0; i<nrow; i++) {
	if (timesData[i] != lasttim) {
	    lasttim = timesData[i];
	    // Write the telescope positions if different from the
	    // previous ones.
	    // First get the position deviations which are stored in the
	    // first 14 data values from this row on.
	    const Complex* posDatac = &(posData(0,0,i));
	    Vector<Double> val(2);
	    for (uInt j=0; j<14; j++) {
		if (posDatac[j].real() != lastPos(j).real()
		||  posDatac[j].imag() != lastPos(j).imag()) {
		    lastPos(j) = posDatac[j];
		    if (posDatac[j].real() < minra(j)) {
			minra(j) = posDatac[j].real();
		    }
		    if (posDatac[j].real() > maxra(j)) {
			maxra(j) = posDatac[j].real();
		    }
		    if (posDatac[j].imag() < mindec(j)) {
			mindec(j) = posDatac[j].imag();
		    }
		    if (posDatac[j].imag() > maxdec(j)) {
			maxdec(j) = posDatac[j].imag();
		    }
		    postab.addRow();
		    val(0) = fieldPos(0) + posDatac[j].real() * factor;
		    val(1) = fieldPos(1) + posDatac[j].imag() * factor;
		    posAntCol.put (posNrow, j);
		    posTimCol.put (posNrow, lasttim);
		    if (near (val(0), fieldPos(0), tolerance)
		    &&  near (val(1), fieldPos(1), tolerance)) {
			posOnCol.put (posNrow, True);
		    } else {
			posOnCol.put (posNrow, False);
		    }
		    posPosCol.put (posNrow, val);
		    posNrow++;
		}
	    }
	}
    }
    cout << postab.nrow() << " rows written in POINTING subtable" << endl;
    AlwaysAssert (posNrow == postab.nrow(), AipsError);
    itsMS.rwKeywordSet().defineTable ("POINTING", postab);
    for (i=0; i<14; i++) {
	cout << "Antenna " << i << ": min/max offset in RA "
	     << minra(i) << ' ' << maxra(i)
	     << ", in DEC " 
	     << mindec(i) << ' ' << maxdec(i)
	     << endl;
    }

}


int main (Int argc, char** argv)
{
    try {
	// enable input in no-prompt mode
	Input inputs(1);

	// define the input structure
	inputs.version("fillpointings, 980717GvD");
	inputs.create ("ms", " ",
		       "Name of MeasurementSet", "string");
	inputs.create ("posms", " ",
		       "Name of MS containing pointings", "string");
	inputs.create ("factor", "1.0e-3", "Factor to convert to degrees",
		       "double");
	inputs.create ("tolerance", "1.0e-2", "Tolerance (deg) for on-position",
		       "double");
	inputs.create ("canexist", "False", "Can POINTING subtable exist",
		       "boolean");
	// fill the input structure from the command line
	inputs.readArguments (argc, argv);
	// get and check the input file specifications
	{
	    Path measurementSet(inputs.getString("ms"));
	    if (measurementSet.originalName() == " ") {
		throw (AipsError(" the MeasurementSet ms must be given"));
	    }
	    cout << "The MeasurementSet is: " 
		 << measurementSet.absoluteName() << endl;
	    if (!measurementSet.isValid()) {
		throw (AipsError(" The ms path is not valid"));
	    }
	    if (!File(measurementSet).exists()) {
		throw (AipsError(" The ms file does not exist"));
	    }
	    if (!File(measurementSet).isWritable()) {
		throw (AipsError(" The ms file is not writable"));
	    }
	}
	{
	    Path measurementSet(inputs.getString("posms"));
	    if (measurementSet.originalName() == " ") {
		throw (AipsError(" the MeasurementSet posms must be given"));
	    }
	    cout << "The MeasurementSet containing pointings is: " 
		 << measurementSet.absoluteName() << endl;
	    if (!measurementSet.isValid()) {
		throw (AipsError(" The posms path is not valid"));
	    }
	    if (!File(measurementSet).exists()) {
		throw (AipsError(" The posms file does not exist"));
	    }
	    if (!File(measurementSet).isReadable()) {
		throw (AipsError(" The posms file is not readable"));
	    }
	}
	Double factor = inputs.getDouble("factor");
	Double tolerance = inputs.getDouble("tolerance");
	Bool canexist = inputs.getBool("canexist");
	cout << "Scale factor " << factor
	     << " will be used for position offsets" << endl;
	cout << "Tolerance " << tolerance
	     << " deg will be used to determine on-position" << endl;
	tolerance /= 180/C::pi;
	cout << "It will ";
	if (canexist) cout << "NOT";
	cout << " be checked if the POINTING subtable already exists" << endl;
	MeasurementSet ms (inputs.getString("ms"));
	fillPositions (ms, inputs.getString("posms"), factor,
		       tolerance, canexist);
	cout << "OK" << endl;

    } catch (AipsError x) {
	cout << "Exception thrown: \"" << x.getMesg() << "\"" << endl;
	return 1;
    } 
    return 0;
}
