//# ms2archive.cc : This program will fill a FITS file from a MeasurementSet.
//# Copyright (C) 1997,1998,1999,2000,2001
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: ms2archive.cc,v 19.3 2004/11/30 17:50:08 ddebonis Exp $

#include <casa/Inputs.h>
#include <casa/Utilities/Regex.h>
#include <casa/OS/Path.h>
#include <casa/OS/File.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MeasurementSets/MSColumns.h>
#include <fits/FITS/fitsio.h>  //# FitsOutput
#include <MSToFITS.h>

#include <casa/namespace.h>

int main(int argc, char* argv[])
{
    try {
	cout << " " << endl;
	cout << " Interpret and check the input parameters." << endl;
	cout << " -----------------------------------------" << endl;

	// enable input in no-prompt mode
	Input inputs(1);

	// define the input structure
	inputs.version("ms2archive, 20000925GvD");
	inputs.create ("ms", "",
		       "Name of input MeasurementSet", "string");
	inputs.create ("in", "",
		       "Name of input MeasurementSet (synonym of ms)",
		       "string");
	inputs.create ("fits", "",
		       "Name of output FITS file", "string");
	inputs.create ("out", "",
		       "Name of output FITS file (synonym of fits)",
		       "string");

	// fill the input structure from the command line
	inputs.readArguments (argc, argv);

	// get and check the input MeasurementSet specification
	String msin (inputs.getString("ms"));
	if (msin == "") {
	  msin = inputs.getString("in");
	}
	if (msin == "") {
	    cout << " usage: ms2archive ms=ms_name [fits=fits_name]" << endl;
	    throw (AipsError(" No MeasurementSet ms specified"));
	}
        Path msPath(msin);
	cout << "main: The MeasurementSet is: "
	     << msPath.absoluteName() << endl;
	if (!msPath.isValid()) {
	    throw (AipsError(" The MeasurementSet path is not valid"));
	}
	if (!File(msPath).exists()) {
	    throw (AipsError(" The MeasurementSet file does not exist"));
	}
	if (!File(msPath).isReadable()) {
	    throw (AipsError(" The MeasurementSet file is not readable"));
	}

	// get and check the output FITS file specification
	String fitsout (inputs.getString("fits"));
	if (fitsout == "") {
	  fitsout = inputs.getString("out");
	}
	if (fitsout == "") {
	  fitsout = msin;
	  fitsout = fitsout.before(Regex("\\.MS$")) + ".MSF";
	}
	Path fitsPath(fitsout);
        if (!File(fitsPath).canCreate()) {
            throw (AipsError(" The FITS file cannot be created"));
        }
	cout << "main: The FITS file will be: "
	     << fitsPath.absoluteName() << endl;

	cout << " " << endl;
        cout << " Open the MeasurementSet." << endl;
        cout << " ------------------------" << endl;
        MeasurementSet ms(msPath.absoluteName(), Table::Old);
	ROMSColumns msc(ms);
	cout << "main: OK" <<endl;

	cout << " " << endl;
        cout << " Create the FITS file and write the primary HDU." << endl;
        cout << " -----------------------------------------------" << endl;
	FitsOutput* fits =
	    FITSTableWriter::makeWriter(fitsPath.absoluteName());
	if (fits->err() == FitsIO::IOERR) {
	    throw (AipsError(" FITS output file could not be created"));
	}
	cout << "main: OK" <<endl;

	cout << " " << endl;
	cout << " Do convert the MS to FITS." << endl;
	cout << " --------------------------" << endl;
	// Create the converter
	MSToFITS converter(ms,fits);
	cout << "main: Run the converter" << endl;
	Bool result = converter.convert();
	if (!result) {
	    throw (AipsError(" Conversion failed"));
	}

	cout << " " << endl;
	cout << " Close the FITS file." << endl;
	cout << " --------------------" << endl;
	if (fits) {
	    delete fits;
	    fits = 0;
	}

    } catch (AipsError x) {
        cout << "Exception: " << x.getMesg() << endl;
	return 1;
    } 

    cout << "ms2archive normally ended" << endl;
    return 0;
}

