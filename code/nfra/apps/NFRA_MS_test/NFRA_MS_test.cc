//# j2convert.cc: This program demonstrates conversion of UVW for WSRT
//# Copyright (C) 1998,1999,2000,2001,2002,2003
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
//# $Id: NFRA_MS_test.cc,v 1.3 2006/07/18 12:29:57 rassendo Exp $

//# Includes

#include <strstream>
#include <measures/Measures/MBaseline.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MeasConvert.h>
#include <measures/Measures/MeasData.h>
#include <measures/Measures/MeasFrame.h>
#include <measures/Measures/MeasRef.h>
#include <measures/Measures/MeasTable.h>
#include <measures/Measures/Muvw.h>
#include <measures/Measures/Stokes.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Quanta/MVAngle.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Quanta/MVBaseline.h>
#include <casa/Quanta/MVuvw.h>
#include <casa/Containers/Record.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MeasurementSets/MSColumns.h>
#include <ms/MeasurementSets/MSField.h>
#include <ms/MeasurementSets/MSFieldColumns.h>
#include <ms/MeasurementSets/MSAntenna.h>
#include <ms/MeasurementSets/MSAntennaColumns.h>
#include <ms/MeasurementSets/MSSummary.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/TableRow.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/ArrayColumn.h>
#include <tables/Tables/TableRecord.h>
#include <tables/Tables/ExprNode.h>
#include <tables/Tables/ColumnDesc.h>
#include <tables/Tables/ArrColDesc.h>
#include <measures/TableMeasures/ArrayMeasColumn.h>
#include <measures/TableMeasures/TableMeasDesc.h>
#include <measures/TableMeasures/TableMeasValueDesc.h>
#include <measures/TableMeasures/TableMeasRefDesc.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayIO.h>
#include <casa/Arrays/MatrixMath.h>
#include <casa/Arrays/ArrayUtil.h>
#include <casa/System/ProgressMeter.h>
#include <casa/Inputs.h>
#include <casa/OS/Path.h>
#include <casa/OS/File.h>
#include <casa/BasicMath/Math.h>
#include <casa/Utilities/Assert.h>
#include <casa/Utilities/Sort.h>
#include <casa/Exceptions/Error.h>
#include <casa/iostream.h>
#include <casa/iomanip.h>
#include <casa/Logging/LogOrigin.h>


//
// NFRA_MSshow inherits NFRA_MS
//
#include <nfra/Wsrt/NFRA_MS.h>

#include <casa/namespace.h>
#define VERSION "20060515-dev-RxA"

//----------------------------------------------------------------------
// KWDout - write MSname, KWD and VAL to stdout
//
void KWDout(String MS, String kwd, String val)
{
  cout << MS << " " << kwd << " " << val << endl;
}

//======================================================================
// Main
//
int main (Int argc, char** argv)
{

  //
  // Must have at least one parameter
  //
  if (argc == 1){
    cout << "\nMust have some parameters, try " << argv[0] << " -h" << endl;
    exit(0);
  }

  //
  // All fatal errors are catched - we 'never' end with a segmentation fault.
  //
  try {

    // enable input in no-prompt mode
    Input inputs(1);

    //
    // The readArguments method (called below) _always_ shows a
    // version unless it is empty. Since we have a 'silent' mode we
    // must set the version to 'empty'.
    //
    inputs.version("");

    // define the input structure
    inputs.create ("in", "",
                   "Name of input MeasurementSet (synonym of msin)",
                   "string");
    inputs.create ("in2", "",
                   "Name of input MeasurementSet (synonym of msin)",
                   "string");
    inputs.create ("kwd", "", "Find keyword in PARAMETERS table", "string");

    // Fill the input structure from the command line.
    inputs.readArguments (argc, argv);

    cout << argv[0] << ": version=" << VERSION << endl;
    cout << endl;
    cout << "Gives info on WSRT Measurement Set" << endl;
    cout << "----------------------------------" << endl;
    cout << endl;

    //
    // Get the input MS specification
    // Commandline keywords are msin= or in=
    //
    String inName = inputs.getString("in");
    if (inName == "") {
      throw (AipsError(" The MeasurementSet must be given"));
    }

    //
    // Check if input is a valid filename
    //
    // !!! Note that if a seq. nr. is given the check need not be done,
    // but since the result will be True we still do it.
    //
    Path measurementSet (inName);    
    if (!measurementSet.isValid()) {
      throw (AipsError(" The MeasurementSet path is not valid"));
    }

    //
    // If the user specified kwd=... on the commandline, only that
    // keyword is extracted from the NFRA_TMS_PARAMETERS tabel.
    //
    String KWD(inputs.getString("kwd"));

    NFRA_MS MS;

    if (File(measurementSet).exists()) {
      //
      // The input is an existing MS.
      // Either get all info or only the required keyword.
      //
      if (KWD != ""){
        String KVal = MS.getNFRAkwd(inName, KWD);
        if (KVal == ""){
          throw(AipsError(MS.getErrStr()));
        }
        if (KVal == "None") KVal = "ERROR - keyword not found";
        KWDout(inName, KWD, KVal);
        exit(0);
      } else {
        if (!MS.setMethod(NFRA_MS::NFRA)){
          throw(AipsError(MS.getErrStr()));
        }
        if (!MS.setInfo(inName)){
          throw(AipsError(MS.getErrStr()));
        }
      }
    } else {
      throw(AipsError(MS.getErrStr()));
    }

    //
    // For KWD mode, we are ready now
    //
    if (KWD != "") exit(0);
    
    //
    // If any error occured inside the object, exit now
    //
    if (MS.getError() != 0){
      cerr << "DEBUG - main - error" << endl;
      String msg = "\nERROR - " + MS.getErrStr();
      if (MS.getErrStr() == "") msg += "???";
      throw (AipsError(msg));
    }

    //
    // If there is a second MS - merge it
    //
    inName = inputs.getString("in2");
    if (inName != ""){
      MS.mergeInfo(inName);
      if (MS.getError() != 0){
        cerr << "Error during merge:" << endl;
        cerr << "  " << MS.getErrStr() << endl;
        exit(1);
      }
    }

    if (MS.isFilled()){
      MS.dump();
    } else {
      cerr << "Not filled ..." << endl;
    }
    
  } catch (AipsError x) {
    cout << "Error: "<< x.getMesg() << endl;
    exit(1);
  } 
  
  exit(0);
}
