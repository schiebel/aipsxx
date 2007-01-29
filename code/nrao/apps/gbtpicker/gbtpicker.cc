//# gbtpicker.cc: Program to pick GBT scans out of one project and add them to another
//# Copyright (C) 2002
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
//# $Id: gbtpicker.cc,v 19.4 2006/09/11 20:28:11 bgarwood Exp $

//# Includes

#include <nrao/FITS/GBTScanLogReader.h>

#include <casa/Arrays/ArrayUtil.h>
#include <casa/Exceptions/Error.h>
#include <fits/FITS/fits.h>
#include <fits/FITS/fitsio.h>
#include <fits/FITS/hdu.h>
#include <fits/FITS/FITSKeywordUtil.h>
#include <fits/FITS/FITSTable.h>
#include <casa/Inputs/Input.h>
#include <casa/OS/Directory.h>
#include <casa/OS/RegularFile.h>
#include <tables/Tables/ArrayColumn.h>
#include <tables/Tables/ArrColDesc.h>
#include <tables/Tables/ExprNode.h>
#include <tables/Tables/ScalarColumn.h>
#include <tables/Tables/ScaColDesc.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/StandardStMan.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/TableDesc.h>
#include <casa/Utilities/Regex.h>

#include <casa/sstream.h>

#include <casa/namespace.h>

void copyCurrentLog(const GBTScanLogReader &reader,
		    const String &inproject,
		    const String &outproject) {
    Block<String> allFiles = reader.allFiles();
    for (uInt i=0;i<allFiles.nelements();i++) {
	String baseName = allFiles[i].after(inproject);
	String outFile = outproject + baseName;
	Path outPath(outFile);
	Directory outDir(outPath.dirName());
	if (!outDir.exists()) {
	    if (!outDir.canCreate()) {
		cerr << "unable to copy to : " 
		     << outPath.baseName() << " - can not create " << endl;
		exit(1);
	    }
	    outDir.create();
	}
	RegularFile inFile(allFiles[i]);
	inFile.copy(outPath);
    }
}

int main(int argc, char **argv) 
{
    Bool result = False;
    String error = "";
    try {
	Input inputs(1);
	inputs.create("inproject", "", "Input project directory", "String");
	inputs.create("outproject", "", "Output project directory", "String");
	inputs.create("scans","","Scans to use as comma separated list, ranges indicated with colon", "String");
	inputs.create("makescanlog","False","Make the new ScanLog.fits file using previously saved scanlog table", "Bool");
	
	inputs.readArguments(argc, argv);
	String inproject = inputs.getString("inproject");
	String outproject = inputs.getString("outproject");
	String scans = inputs.getString("scans");
	Bool makescanlog = inputs.getBool("makescanlog");

	String scanLogTabName = outproject + "/ScanLog.tab";
	
	if (inproject.length() > 0) {
	    cout << "Picking scans from " << inproject << endl;
	    if (scans.length() == 0) {
		cout << "   copying ALL scans" << endl;
	    } else {
		cout << "   copying these scans : " << scans << endl;
	    }

	    Directory inProjDir(inproject);
	    if (!inProjDir.exists()) {
		cerr << inproject << " does not exist" << endl;
		exit(1);
	    }
	    if (!inProjDir.isDirectory()) {
		cerr << inproject << " is not a directory" << endl;
		exit(1);
	    }
	    Directory outProjDir(outproject);
	    if (!outProjDir.exists()) {
		// try and create it
		if (!outProjDir.canCreate()) {
		    cerr << outproject << " can not be created" <<endl;
		    exit(1);
		}
		outProjDir.create();
	    } else {
		if (!outProjDir.exists()) {
		    cerr << outproject << " exists and is not a directory" << endl;
		    exit(1);
		}
	    }
	    
	    String scanLogFile = inproject + "/ScanLog.fits";
	    if (!File(scanLogFile).exists()) {
		cerr << "No ScanLog.fits found in " << inproject << endl;
		exit(1);
	    }
	    
	    Vector<String> scansVec;
	    Vector<Int> iscansVec, minScanVec, maxScanVec;
	    if (scans.length() > 0) {
		// digest scans - first, split it
		scansVec = stringToVector(scans);
		// first pass, count individual scans and ranges
		// also watch for badly given fields (non-numeric except for a colon signifying a range)
		Int scanCount, rangeCount;
		scanCount = rangeCount = 0;
		// single scans are positive integers - white space should never happen here.
		Regex scanRegex("^[0-9]+$");
		// ranges are optional positive integers separated by a colon.   Abscence of either
		// integer implies no limit at that end.
		Regex rangeRegex("^[0-9]*:[0-9]*$");
		for (uInt i=0;i<scansVec.nelements();i++) {
		    String thisScan = scansVec[i];
		    if (thisScan.matches(scanRegex)) {
			scanCount++;
		    } else if (thisScan.matches(rangeRegex)) {
			rangeCount++;
		    } else {
			// unrecognized
			cerr <<  "invalid scan or range given as : " << thisScan << endl;
			exit(1);
		    }
		}
		// second pass, convert and extract them
		iscansVec.resize(scanCount);
		minScanVec.resize(rangeCount);
		maxScanVec.resize(rangeCount);
		scanCount = rangeCount = 0;
		for (uInt i=0;i<scansVec.nelements();i++) {
		    String thisScan = scansVec[i];
		    if (thisScan.matches(scanRegex)) {
			istringstream instr(thisScan.chars());
			instr >> iscansVec[scanCount++];
		    } else {
			// must be a range specification, anything else has already caused an exit
			// split it at the colon
			String low = thisScan.before(":");
			String high = thisScan.after(":");
			if (low == "") {
			    minScanVec[rangeCount] = -1;
			} else {
			    istringstream instr(low.chars());
			    instr >> minScanVec[rangeCount];
			}
			if (high == "") {
			    maxScanVec[rangeCount] = -1;
			} else {
			    istringstream instr(high.chars());
			    instr >> maxScanVec[rangeCount];
			}
			rangeCount++;
		    }
		}
	    } else {
		// all scans
		iscansVec.resize(0);
		minScanVec.resize(1);
		maxScanVec.resize(1);
		minScanVec = maxScanVec = -1;
	    }

	    GBTScanLogReader reader(scanLogFile);

	    // construct output scan log table if necessary

	    if (!File(scanLogTabName).exists()) {
		cout << "Creating output aips++ scan log table in " << outproject << endl;
		TableDesc td;
		td.rwKeywordSet() = reader.primaryKeywords();
		td.addColumn(ScalarColumnDesc<String>("DATE-OBS"));
		td.addColumn(ScalarColumnDesc<Int>("SCAN"));
		td.addColumn(ArrayColumnDesc<String>("FILEPATH",1));
		td.addColumn(ScalarColumnDesc<String>("STARTING"));
		td.addColumn(ScalarColumnDesc<String>("FINISHED"));
		SetupNewTable newtab(scanLogTabName, td, Table::New);
		StandardStMan stmanStand;
		newtab.bindAll(stmanStand);
		Table tab(newtab);
	    } else {
		cout << "Appending to existing aips++ scan log table in " << outproject << endl;
	    }
	    Table tab(scanLogTabName, Table::Update);
	    ScalarColumn<String> dateObs(tab,"DATE-OBS");
	    ScalarColumn<Int> scan(tab,"SCAN");
	    ArrayColumn<String> filepath(tab,"FILEPATH");
	    ScalarColumn<String> starting(tab,"STARTING");
	    ScalarColumn<String> finished(tab,"FINISHED");
	    
	    String newPrefix = "./" + outProjDir.path().baseName();
	    
	    while (reader.scan() > 0) {
		Int thisScan = reader.scan();
		Bool found = False;
		uInt iscanPtr = 0;
		while (!found && iscanPtr < iscansVec.nelements()) {
		    if (thisScan == iscansVec[iscanPtr++]) found = True;
		}
		iscanPtr = 0;
		while (!found && iscanPtr < minScanVec.nelements()) {
		    Int minScan = minScanVec[iscanPtr];
		    Int maxScan = maxScanVec[iscanPtr];
		    iscanPtr++;
		    if ((minScan < 0 || thisScan >= minScan) &&
			(maxScan < 0 || thisScan <= maxScan)) found = True;
		}
		if (found) {
		    cout << "Copying scan " << reader.scan() << " @ " << reader.dmjd() << endl;
		    copyCurrentLog(reader, inproject, outproject);
		    // see if this timestamp is already there, if so, remove those rows
		    // from tab
		    Table dupTab = tab(tab.col("DATE-OBS") == reader.dmjd().string());
		    if (dupTab.nrow() > 0) {
			cout << "Removing duplicate rows from existing scanlog table" << endl;
			cout << dupTab.rowNumbers() << endl;
			tab.removeRow(dupTab.rowNumbers());
		    }
		    uInt thisrow = tab.nrow();
		    tab.addRow();
		    dateObs.put(thisrow, reader.dmjd().string());
		    scan.put(thisrow, reader.scan());
		    // remove the stuff upstream from inproject, inclusive
		    // replacing it with new prefix
		    Vector<String> files(reader.allFiles());
		    for (uInt i=0;i<files.nelements();i++) {
			files[i] = newPrefix + files[i].after(inproject);
		    }
		    filepath.put(thisrow, files);
		    starting.put(thisrow, reader.starting());
		    finished.put(thisrow, reader.finished());
		}
		reader.next();
	    }
	}
       
	if (makescanlog) {
	    cout << "Making a new ScanLog.fits file in " << outproject << endl;
	    if (!File(scanLogTabName).exists()) {
		cerr << "scanlog table used to construct ScanLog.fits does not exist" << endl;
		exit(1);
	    }
	    String scanLogName = outproject + "/ScanLog.fits";
	    if (File(scanLogName).exists()) {
		cout << "Removing existing ScanLog.fits file" << endl;
		RegularFile(scanLogName).remove();
	    }

	    Table origtab(scanLogTabName);
	    Table tab(origtab.sort("DATE-OBS"));
	    ROScalarColumn<String> dateObs(tab,"DATE-OBS");
	    ROScalarColumn<Int> scan(tab,"SCAN");
	    ROArrayColumn<String> filepath(tab,"FILEPATH");
	    ROScalarColumn<String> starting(tab,"STARTING");
	    ROScalarColumn<String> finished(tab,"FINISHED");
	    
            String fullName(Path(scanLogName).expandedName());
	    const char *name = fullName.chars();
	    FitsOutput *fitsOut = new FitsOutput(name, FITS::Disk);
	    FitsKeywordList pkwl;

	    TableRecord kwSet = tab.keywordSet();

	    // do the standard ones first, in the expected order
	    pkwl.mk(FITS::SIMPLE,True,"file does conform to FITS standard");
	    pkwl.mk(FITS::BITPIX,8,"number of bits per data pixel");
	    pkwl.mk(FITS::NAXIS,0,"number of data axes");
	    pkwl.mk(FITS::EXTEND,True,"FITS dataset may contain extensions");

	    // and remove these from kwSet if they are present
	    if (kwSet.fieldNumber("SIMPLE")>=0) kwSet.removeField("SIMPLE");
	    if (kwSet.fieldNumber("BITPIX")>=0) kwSet.removeField("BITPIX");
	    if (kwSet.fieldNumber("NAXIS")>=0) kwSet.removeField("NAXIS");
	    if (kwSet.fieldNumber("EXTEND")>=0) kwSet.removeField("EXTEND");

	    FITSKeywordUtil::addComment(kwSet,"Pseudo ScanLog.fits created by gbtpicker");

	    FITSKeywordUtil::addKeywords(pkwl, kwSet);

	    // and add the END keyword
	    pkwl.end();
	    PrimaryArray<unsigned char> phdu(pkwl);
	    phdu.write_hdr(*fitsOut);

	    // prepare to generate the table HDU
	    // number of rows in output FITS table is sum(nelements of FILEPATH array for each row) + 2*nrow of table
	    uInt noutRows = 0;
	    for (uInt i=0;i<tab.nrow();i++) {
		noutRows += filepath.shape(i).product();
	    }
	    noutRows += 2*tab.nrow();

	    RecordDesc fitsDesc;
	    fitsDesc.addField("DATE-OBS", TpString);
	    fitsDesc.addField("SCAN", TpInt);
	    fitsDesc.addField("FILEPATH", TpString);

	    Record maxLengths;
	    maxLengths.define("FILEPATH", 192);
	    maxLengths.define("DATE-OBS", 20);

	    Record extraKeys;
	    // no extra keywords

	    Record units;
	    units.define("DATE-OBS","UTC");
	    units.define("SCAN","none");
	    units.define("FILEPATH","none");

	    FITSTableWriter tabWriter(fitsOut, fitsDesc, maxLengths,
				      noutRows, extraKeys, units);

	    RecordFieldPtr<String> dateObsField(tabWriter.row(), "DATE-OBS");
	    RecordFieldPtr<Int> scanField(tabWriter.row(), "SCAN");
	    RecordFieldPtr<String> filePathField(tabWriter.row(), "FILEPATH");

	    for (uInt i=0;i<tab.nrow();i++) {
		*dateObsField = dateObs(i);
		*scanField = scan(i);
		Vector<String> filePaths(filepath(i));
		for (uInt j=0;j<filePaths.nelements();j++) {
		    *filePathField = filePaths[j];
		    tabWriter.write();
		}
		*filePathField = starting(i);
		tabWriter.write();
		*filePathField = finished(i);
		tabWriter.write();
	    }

	    // destructor of FITSTableWriter deletes fitsOut
	}

       	result = True;
	
    } catch (AipsError x) {
	error = x.getMesg();
	result = False;
    }
    
    if (result == False) {
	cerr << "Aborted : " << error << endl;
	exit(1);
    }
    
    cout << "Finished successfully." << endl;
    exit(0);
}
