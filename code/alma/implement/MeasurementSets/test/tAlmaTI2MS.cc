//# tAlmaTI2MS.cc: Test program for class tAlmaTI2MS
//# Copyright (C) 2000,2002
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
//# $Id: tAlmaTI2MS.cc,v 19.4 2004/11/30 17:50:06 ddebonis Exp $

#include <casa/OS/File.h>
#include <casa/OS/RegularFile.h>
#include <casa/OS/Directory.h>
#include <casa/System/Aipsrc.h>
#include <alma/MeasurementSets/AlmaTI2MS.h>
#include <casa/Exceptions/Error.h>

#include <casa/namespace.h>

int
main() {
	Path        aPath(File::newUniqueName("./","junk_"));
	RegularFile rFile(aPath);
	String      inFile(Aipsrc::aipsRoot()+"/data/alma/test/07-feb-1997-g067-04.fits");
	String      outFile(aPath.originalName());

	rFile.create();	// readable temporary file used for testing
	rFile.setPermissions(0644);

	try {
		// public:
		//
		// Construct from a tape device name and MS output file name
		//  AlmaTI2MS(const Path& tapeDevice, const String& msOut, 
		//  	    const Bool& overWrite);
		{
		  Path tapeDevice1(inFile);
		  Path tapeDevice2(aPath);

		  // tapeDevice must be readable; msOut may or may not
		  // exist.  If it exists and isn't writable an exception
		  // occurs.  If it exists as a regular writable file than
		  // no error is signalled here but the fill() method
		  // (tested later) will have an exception because it
		  // expects a Table (ie., a directory).
		  AlmaTI2MS aFiller(Path("/dev/null"),"/dev/null",False);
		  AlmaTI2MS bFiller(Path("/dev/null"),"/dev/null",True);
		  try {
		    AlmaTI2MS cFiller(tapeDevice1,inFile,False);
		    AlmaTI2MS dFiller(tapeDevice1,inFile,True);
		  }
		  catch (AipsError x) {
		    cout << "****Ignore the preceding error message!****"
			 << endl;
		  }
		  AlmaTI2MS eFiller(tapeDevice1,"/dev/null",False);
		  AlmaTI2MS fFiller(tapeDevice1,"/dev/null",True);
		  AlmaTI2MS gFiller(tapeDevice2,tapeDevice2.originalName(),False);
		  AlmaTI2MS hFiller(tapeDevice2,tapeDevice2.originalName(),True);
		  AlmaTI2MS iFiller(tapeDevice2,"./_NonExistant_",True);
		  AlmaTI2MS jFiller(tapeDevice2,"./_NonExistant_",False);
		}

  		// Construct from an input file name and an MS output file name
		//   AlmaTI2MS(const String& inFile,
		//   	 const String& msOut, const Bool& overWrite);
		{
		  // inFile must be readable;
		  // msOut must be writable if it exists
		  AlmaTI2MS aFiller("/dev/null","/dev/null",False);
		  AlmaTI2MS bFiller("/dev/null","/dev/null",True);
		  try {
		    AlmaTI2MS cFiller(inFile,inFile,False);
		    AlmaTI2MS dFiller(inFile,inFile,True);
		  }
		  catch (AipsError x) {
		    cout << "****Ignore the preceding error message!****"
			 << endl;
		  }
		  AlmaTI2MS eFiller(inFile,"/dev/null",False);
		  AlmaTI2MS fFiller(inFile,"/dev/null",True);
		  AlmaTI2MS gFiller(outFile,outFile,False);
		  AlmaTI2MS hFiller(outFile,outFile,True);
		  AlmaTI2MS iFiller(inFile,outFile,False);
		  AlmaTI2MS jFiller(inFile,outFile,True);
		  AlmaTI2MS kFiller(inFile,"./_NonExistant_",True);
		  AlmaTI2MS lFiller(inFile,"./_NonExistant_",False);
		}
		
		// Destructor
		//   ~AlmaTI2MS();
		AlmaTI2MS * aFillerp;
		aFillerp = new AlmaTI2MS("/dev/null","/dev/null",False);
		delete(aFillerp);		

  		// Set general options (MS compression, baseband concatenation)
		//  void setOptions(Bool compress=True,
		//			Bool combineBaseBand=True);
		{
		  AlmaTI2MS aFiller(inFile,outFile,False);
		  aFiller.setOptions(True,True);
		  aFiller.setOptions(True,False);
		  aFiller.setOptions(False,True);
		  aFiller.setOptions(False,False);
		}

		// Set which files are selected (1-rel; for tape-based data)
		//  void selectFiles(const Vector<Int>& files);
		{
		  AlmaTI2MS aFiller(inFile,outFile,False);
		  aFiller.setOptions(True,True);
		  Vector<Int> files(5);
		  files(0)=5;
		  files(1)=15;
		  files(2)=7;
		  files(3)=8;
		  files(4)=9;
		  aFiller.selectFiles(files);
		}

  		// General data selection: observation mode, channel-zero
		//  void select(const Vector<String>& obsMode,
		// 			 const String& chanZero);
		{
		  AlmaTI2MS aFiller(inFile,outFile,False);
		  aFiller.setOptions(True,False);
		  Vector<String> obsModeA(1,"CORR");
		  aFiller.select(obsModeA,"TIME_AVG");
		  Vector<String> obsModeB(1);
		  obsModeB(0) = "CORR";
		  aFiller.select(obsModeB,"TIME_AVG");
		}

  		// Convert the ALMA-TI data to MS format
		// Bool fill();
		{
		  try {
		    AlmaTI2MS aFiller(inFile,inFile,True);
		    aFiller.setOptions(False,True);
		    Vector<String> obsModeA(1,"CORR");
		    aFiller.select(obsModeA,"TIME_AVG");
		    if (aFiller.fill())
			cout << "filled unexpectedly" << endl;
		  }
		  catch (AipsError x) {
		    cout << "****Ignore the preceding error message!****"
			 << endl;
		  }
		}

		rFile.remove();	// remove regular file "outFile" created
				// earlier so Table (ie., directory)
				// "outFile" can be built by fill();
		AlmaTI2MS aFiller(inFile,outFile,False);
		aFiller.setOptions(False,False);
		Vector<String> obsModeA(1,"CORR");
		aFiller.select(obsModeA,"TIME_AVG");
		// "outFile" must either exist and be writable or
		// be creatable when AlmaTI2MS::fill() is invoked.
		// NOTE: If it is a pre-existing regular file
		// than fill() fails because it expects a Table
		// (i.e., a directory).
		if (!aFiller.fill())
			cout << "unexpected fill() failure" << endl;

		// Construct an empty MeasurementSet with the supplied table
		// name, with or without compression enabled.
		// Throw an exception (AipsError) if the specified
		// Table already exists unless the overwrite argument 
		// is set to True. 
		//   static MeasurementSet emptyMS(const Path& tableName, 
		//	const Bool compress=True, const Bool overwrite=False);
		// ***Not tested directly***

		// A FITS error handler which will ignore those FITS compliance
		// issues in the ALMA-TI format which have no significant
		// impact in practice.
		//  static void fitsErrorHandler(const char*,
		//  				 FITSError::ErrorLevel);
		// ***Not tested directly***	

		// protected:
		//
		// Initialization (called by all constructors)
		//  void init(const String& dataSource,
		//  		const FITS::FitsDevice& deviceType,
		//		const String& msOut, const Bool& overWrite);
		// ***Not tested directly***	

		// Read and process a ALMA-TI file
		//  void readFITSFile(Bool& atEnd);
		// ***Not tested directly.  Called in method fill().***

		// Create a new, empty output MS
		//  void createOutputMS();
		// ***Not tested directly.  Called in method fill().***

	}
	catch (AipsError x) {
		cerr << "aipserror: error " << x.getMesg() << endl;
		return 1;
	}

	cout << "No errors detected.  Removing temporary files." << endl;

	// clean up
	Directory dir(outFile);
	dir.removeRecursive();

	return 0;
};
