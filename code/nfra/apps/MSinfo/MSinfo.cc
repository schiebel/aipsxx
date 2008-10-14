//# MSinfo.cc: Show observing mode of NFRA MS
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
//# $Id: MSinfo.cc,v 1.3 2006/09/05 11:29:28 rassendo Exp $

//# Includes

//
// NFRA_MSshow inherits NFRA_MS
//

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


#include <nfra/Wsrt/NFRA_MSshow.h>

#include <casa/namespace.h>
#define VERSION "0.9-20060203RxA"
#define MSStart 9700000

//----------------------------------------------------------------------
// The name of an MS is the directory where the data is stored.
// For WSRT MSses the name is the sequence number with some
// additions. At some points in time the format of the name
// changed. At present (10DEC2005) the name is: <sequence
// nr>_S<subarray number>_T<Time slice>.MS.
// Info on subarrays and time slices can be found elsewhere.
//
// Given a seqnr, subarray, and timeslice, this function creates the
// MS name.
//
String mkMSName(String pth, String sqnr, uInt S, uInt T){
  ostringstream MSName;
  if (pth != "") MSName << pth;
  MSName << sqnr << "_S" << S << "_T" << T << ".MS";
  return MSName;
}

//----------------------------------------------------------------------
// KWDout - write MSname, KWD and VAL to stdout
//
void KWDout(String MS, String kwd, String val)
{
  if (kwd == "all")
    cout << val << endl;
  else
    cout << MS << " " << kwd << " " << val << endl;
}

Int m_atoi(String s)
{
  for (uInt i = 0; i < s.length(); i++){
    if (!isdigit(s[i])) return -1;
  }
  Int i = atoi(s.c_str());
  return i;
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
    inputs.create ("msin", "",
		   "Name of input MeasurementSet", "string");
    inputs.create ("in", "",
		   "Name of input MeasurementSet (synonym of msin)",
		   "string");
    inputs.create ("mode", "std", "Output mode (std, raw, readme, arch)", "string");
    inputs.create ("kwd", "", "Find keyword in PARAMETERS table", "string");
    inputs.create ("path", "", "Find the MS in the given path", "string");
    inputs.create ("silent", "False", "Give no extra output", "Bool");

    // Fill the input structure from the command line.
    inputs.readArguments (argc, argv);

    Bool silent = inputs.getBool("silent");

    if (!silent){
      //
      // No silent - so show some info
      //
      cout << argv[0] << ": version=" << VERSION << endl;
      cout << endl;
      cout << "Gives info on WSRT Measurement Set" << endl;
      cout << "----------------------------------" << endl;
      cout << endl;
    }

    //
    // Get the input MS specification
    // Commandline keywords are msin= or in=
    //
    String inName (inputs.getString("msin"));
    if (inName == "") {
      inName = inputs.getString("in");
    }
    if (inName == "") {
      throw (AipsError(" The MeasurementSet must be given"));
    }

    //
    // Get apath leading to the MS
    // add trailing '/'
    //
    String pth (inputs.getString("path"));
    if (pth != ""){
      uInt l = pth.size()-1;
      if (pth[l] != '/')
	pth += '/';
    }

    //
    // Check if input is a valid filename
    //
    // !!! Note that if a seq. nr. is given the check need not be done,
    // but since the result will be True we still do it.
    //
    String MSName;
    if (pth != "") MSName = pth + inName;
    else MSName = inName;
    Path measurementSet (MSName);    
    if (!measurementSet.isValid()) {
      throw (AipsError(" The MeasurementSet path is not valid"));
    }

    //
    // If the user specified kwd=... on the commandline, only that
    // keyword is extracted from the NFRA_TMS_PARAMETERS tabel.
    //
    String KWD(inputs.getString("kwd"));

    //
    // First check if the MS as given exists
    // If not, then check if a seq.nr. was given (can be converted to
    // int and must be > 9700000 since the first MS with a seq.nr is
    // 9700001.MS
    // If a seq.nr is given, try all S<n>_T<m> with n=0,1,...,
    // m=0,1,... as MSName until an n or m is found that does not give
    // an MS
    //
    // !!! Note that older MSses have a different format.

    //
    // The info on the MS is obtained by the class NFRA_MS, inherited
    // in NFRA_MSshow
    //
    NFRA_MSshow MS;

    MS.setMethod(NFRA_MS::NFRA);

    if (File(measurementSet).exists()) {
      //
      // The input is an existing MS.
      // Either get all info or only the required keyword.
      //
      if (KWD != ""){
	String KVal = MS.getNFRAkwd(MSName, KWD);
	KWDout(MSName, KWD, KVal);
	exit(0);
      } else {
	MS.setInfo(MSName);
      }

    } else {
      //
      // The input is NOT an existing MS.
      // Try if the input is an integer, if so add subarrays and
      // timeslices
      //

      Int SeqNr;
      try{
	SeqNr = m_atoi(inName);
	//
	// m_atoi return -1 if the string contains non-digits
	//
	if (SeqNr == -1) throw (AipsError("Input must be an existing MS"));
      }
      catch(...){
        //
	// input can not be converted to an integer -> no sequence number
	//
	throw (AipsError("Input must be either MS name or a seq.nr. as integer"));
      }

      if (SeqNr < MSStart){
	//
	// input is not a valid sequence number
	//
	throw (AipsError("Not an existing Sequence number, must be > 9700000"));
      }

      //
      // We now have a possible legal SeqNr.
      //  - Start with Subarray S=0 and Timeslice T=0,
      //  - Create the MSName
      //  - if it exists get the info
      //  - Then let S and T run upwards until no existing MSName can
      //     be made
      //  - merge the information of the existing MSses
      //
      uInt S = 0; 
      uInt T = 0;
      String MSName = mkMSName(pth, inName, S, T);
      if (File(Path(MSName)).exists()){
	if (KWD != ""){
	  String KVal = MS.getNFRAkwd(MSName, KWD);
	  KWDout(MSName, KWD, KVal);
	} else {
	  MS.setInfo(MSName);
	}
      } else {
	throw (AipsError("Sequence number can not be linked to an existing MS"));
      }

      //
      // We have T0, now go for T1
      //
      T++;
      Bool MS_S_ready = False;
      Bool MS_T_ready = False;

      while (!MS_S_ready){
      	while (!MS_T_ready){
	  MSName = mkMSName(pth, inName, S, T);
	  //
	  // If the filename does not exist, there are no more
	  // TimeSlices for the current SubArray.
	  //
      	  if (!File(Path(MSName)).exists()) {
	    MS_T_ready = True;
	  } else {
	    if (KWD != ""){
	      String KVal = MS.getNFRAkwd(MSName, KWD);
	      KWDout(MSName, KWD, KVal);
	    } else {
	      MS.mergeInfo(MSName);
	    }
	    T++;
	  }
      	}
	//
	// All TimeSlices for this SubArray have been found
	// If T is still 0, then there was no TimeSlice for the
	// current SubArray and we are ready,
	// otherwise, try the next SubArray
	//
	if (T == 0){
	  MS_S_ready = True;
	} else {
	  T = 0;
	  MS_T_ready = False;
	  S++;
	}
      }
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
    // Find out what kind of output is requested
    //
    String OMode(inputs.getString("mode"));
    if (OMode == "") OMode = "std";

    if (MS.isFilled()) MS.show(OMode);
    
  } catch (AipsError x) {
    cout << "Error: "<< x.getMesg() << endl;
    exit(1);
  } 
  
  exit(0);
}
