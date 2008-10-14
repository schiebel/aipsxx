//# archive2ms.cc - Convert an MS-type FITS file into a MeasurementSet.
//# Copyright (C) 1995,1996,1997,1998,1999,2000,2001,2002
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
//# $Id: archive2ms.cc,v 19.3 2004/11/30 17:50:06 ddebonis Exp $


#include <MSBinaryTable.h>
#include <fits/FITS/fitsio.h>
#include <casa/Inputs/Input.h>
#include <casa/OS/File.h>
#include <casa/OS/Directory.h>
#include <casa/Arrays/Vector.h>
#include <ms/MeasurementSets/MS1ToMS2Converter.h>
#include <casa/Exceptions/Error.h>
#include <casa/Utilities/Regex.h>
#include <casa/iostream.h>
#include <casa/stdio.h>

#include <casa/namespace.h>
int main(int argc, char **argv)
{
  try {
    cout << endl;
    cout << " Interpret and check the input parameters." << endl;
    cout << " -----------------------------------------" << endl;

    //
    // Enable input in no-prompt mode.
    //
    Input inputs(1);
    inputs.version ("archive2ms, 20000927GvD");

    //
    // Define the input structure.
    //
    inputs.create("fits",
		  "",
		  "The input FITS file",
		  "String");
    inputs.create("in",
		  "",
		  "The input FITS file (synonym of fits)",
		  "String");
    inputs.create("ms",
		  "",
		  "The output MeasurementSet",
		  "String");
    inputs.create("out",
		  "",
		  "The output MeasurementSet (synonym of ms)",
		  "String");
    inputs.create("compress",
		  "keep",
		  "(Un)compress data columns in MS? {F}"
		  "String");

    //
    // Fill the input structure from the command line.
    //
    inputs.readArguments(argc, argv);

    //
    // Get and check the input FITS file specification.
    //
    String inName = inputs.getString("fits");
    if (inName == "") {
      inName = inputs.getString("in");
    }
    if (inName == "") {
      throw (AipsError(" No FITS file fits (or in) specified"));
    }
    Path fitsPath(inName);
    cout << "main: The FITS file is: "
	 << fitsPath.absoluteName() << endl;
    if (!fitsPath.isValid()) {
      throw (AipsError(" The FITS file specification is not valid"));
    }
    if (!File(fitsPath).exists()) {
      throw (AipsError(" The FITS file does not exist"));
    }
    if (!File(fitsPath).isReadable()) {
      throw (AipsError(" The FITS file is not readable"));
    }

    //
    // Get and check the output MeasurementSet specification.
    //
    String msout (inputs.getString("ms"));
    if (msout == "") {
      msout = inputs.getString("out");
      if (msout == "") {
	msout = inName;
	msout = msout.before(Regex("\\.MSF$")) + ".MS";
      }
    }
    Path msPath(msout);
    cout << "main: The MeasurementSet file will be: "
	 << msPath.absoluteName() << endl;
    if (File(msPath).exists()) {
      throw (AipsError(" The MeasurementSet already exists"));
    }
    if (!File(msPath).canCreate()) {
      throw (AipsError(" The MeasurementSet file cannot be created"));
    }
    String compress = inputs.getString("compress");

    // Keep track of the MS version.
    Float msversion = 0;

    {
      cout << " " << endl;
      cout << " Open the FITS file." << endl;
      cout << " -------------------" << endl;
      FitsInput infits(fitsPath.absoluteName().chars(), FITS::Disk);
      if (infits.err() != FitsIO::OK) {
	throw (AipsError(" FITS input could not be instantiated"));
      }
      cout << "main: OK" <<endl;

      cout << " " << endl;
      cout << " Create a _tmp directory to store the subtables." << endl;
      cout << " -----------------------------------------------" << endl;
      //
      // Once the main-table (directory) has been created and filled,
      // the contents of tmpDir will be moved to there.
      //
      String ms = msPath.absoluteName();
      String msdir = Path(ms).dirName();
      Directory tmpDir(ms+"_tmp");
      tmpDir.create();

      cout << " " << endl;
      cout << " Do convert the FITS to MS." << endl;
      cout << " --------------------------" << endl;

      Regex trailing(" *$"); // trailing blanks

      //
      // Loop through all FITS HDU's.
      //
      Vector<String> subTableName;
      Int subTableNr = -1;
      while (!infits.eof() && infits.err() == FitsIO::OK) {
	//
	// Skip non-BinaryTable type HDU's.
	//
	if (infits.hdutype() != FITS::BinaryTableHDU) {
	  cout << "Type of HDU = " << Int(infits.hdutype()) << endl;
	  cout << "This is not a FITS Binary Table. Skip it." << endl;
	  infits.skip_hdu();

	} else {
	  //
	  // Create the MSBinaryTable object.
	  //
	  MSBinaryTable bintab(infits, compress, msdir);
	  if (infits.err() != FitsIO::OK) {
	    cout << "Problem while reading binary table : "
		 << infits.err() << endl;
	    return 1;
	  }

	  //
	  // The main table will be stored in a directory with
	  // the specified name (argument ms). Subtables will
	  // ultimately be stored in directories under ms, but
	  // first are stored in a temporary directory tree.
	  //
	  // Determine the table name.
	  //
	  String hduName = bintab.extname();
	  hduName = hduName.before(trailing);
	  String tableName;
	  if (hduName == "") {
	    cout << endl << "Subtable " << subTableNr+1 
		 << " has no name. We will just ignore it." 
		 << endl << endl;
	    tableName = "";
	  } else if (hduName == "MAIN") {
	    tableName = ms;
	    msversion = bintab.msVersion();
	    cout << endl << "Doing the main table"
		 << " named: " << hduName << endl;
	    cout << "Archived MS version: " << msversion
		 << endl << endl;
	  } else {
	    subTableNr++;
	    subTableName.resize(subTableNr+1,True);
	    cout << endl << "Doing subTableNr " << subTableNr
		 << " named: " << hduName
		 << endl << endl;
	    subTableName(subTableNr) = hduName;
	    tableName = ms + "_tmp/" + hduName;
	  }

	  //
	  // Create the MeasurementSet (subtable) from the HDU.
	  //
	  if (tableName != "") {
///		    cout << "tableName = /" << tableName << "/" << endl;
	    Table tab = bintab.fullTable(tableName);
	    if (infits.err() != FitsIO::OK) {
	      cout << "Problem while making the output table : "
		   << infits.err() << endl;
	      return 1;
	    }
	  }
	}
      }

      //
      // Move the subtables in the proper place and add the subtable
      // references to the main table description.
      //
      cout << "Subtables found: " << subTableName << endl;
      // Open the main table to be updated.
      Table msmain (ms, Table::Update);
      // Loop over all subtables.
      cout << "Nr of subtables = " << subTableNr+1 << endl;
      for (Int isub=0; isub<=subTableNr; isub++) {
	cout << "renaming subtable " << subTableName(isub) << endl;
	// Open the subtable to be updated.
	Table mssub(ms+"_tmp/"+subTableName(isub),Table::Update);
	// Rename the subtable.
	mssub.rename (ms+"/"+subTableName(isub),Table::NewNoReplace);
	// Attach the subtable to the main table.
	msmain.rwKeywordSet().defineTable(subTableName(isub),mssub);
      }
      tmpDir.remove();
    }

    //
    // Convert an old MS to MS version 2 (in place).
    //
    if (msversion < 2) {
      cout << endl << "Convert the restored MS to version 2" << endl;
      MS1ToMS2Converter conv ("", msPath.absoluteName(), True);
      conv.convert();
    }

  } catch (AipsError x) {
    cout << "Exception: " << x.getMesg() << endl;
    return 1;
  }

  cout << "archive2ms normally ended" << endl;
  return 0;
}
