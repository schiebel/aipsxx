//# tableglue.cc: Glue FITS tables together for the GBT
//# Copyright (C) 1995,1996,1997,1998,1999,2000,2001
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
//# $Id: gbtlogfiller.cc,v 19.4 2004/11/30 17:50:40 ddebonis Exp $

#include <fits/FITS/FITSMultiTable.h>
#include <fits/FITS/FITSTimedTable.h>
#include <fits/FITS/CopyRecord.h>
#include <casa/Containers/Record.h>
#include <casa/Containers/RecordField.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayIO.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Utilities/Assert.h>
#include <casa/BasicSL/String.h>
#include <tables/Tables.h>
#include <casa/Exceptions/Error.h>
#include <casa/OS/Time.h>
#include <casa/OS/Path.h>
#include <casa/OS/Timer.h>

#include <casa/iostream.h>

#include <unistd.h>

#include <casa/Containers/SimOrdMapIO.h>

#include <casa/namespace.h>
// this is a work around until the operator>> in Time is fixed to
// deal with leading zeros correctly

// I could just use the c library atoi, but this is probably appropriate
// although it clearly has problems - hopefully Time will be fixed
// before this needs to be checked in.

Int myatoi(const String& s)
{
   Int result = 0;
   Int factor = 1;
   const char zero = '0';
   const char nine = '9';
   uInt stopAt = 0;
   uInt startAt;
   Bool negative = False;

   if (s.length() > 0 && s.firstchar() == '-') {
       negative = True;
       stopAt = 1;
   }
   // skip any leading non-numerals
   for (;stopAt<s.length();stopAt++) {
       if (s[stopAt] >= zero) break;
   }

   // skip any trailing non-numerals
   for (startAt=s.length();startAt>0;startAt--) {
      if (s[startAt-1] >= zero) break;
   }

   // break out at the first non-numeric character
   for (uInt i=startAt;i>stopAt;i--) {
       if (s[i-1] < zero || s[i-1] > nine) break;
       result += (s[i-1]-zero) * factor;
       factor *= 10;
   }
   return result;
}


Time makeTime(const String &in)
{
    String s(in);

    // in has the form month/day/year,hour:min:sec
    uInt year=0, month=0, day=0, hour=0, min=0, sec=0;
    String sub;
    Int marker, position=0;

    // month, before the first slash
    marker = s.index("/", position);
    if (marker > position) {
	sub = s.at(position,(marker-position));
        month = uInt(myatoi(sub));
	position = marker + 1;
    }
    // day, until the next slash
    marker = s.index("/", position);
    if (marker > position) {
	sub = s.at(position,(marker-position));
	day = uInt(myatoi(sub));
	position = marker + 1;
    }
    // year, until the comma
    marker = s.index(",", position);
    if (marker > position) {
	sub = s.at(position,(marker-position));
	year = uInt(myatoi(sub));
	position = marker + 1;
    }
    // hour, until the next :
    marker = s.index(":",position);
    if (marker > position) {
	sub = s.at(position,(marker-position));
	hour = uInt(myatoi(sub));
	position = marker + 1;
    }
    // min, until the next :
    marker = s.index(":",position);
    if (marker > position) {
	sub = s.at(position,(marker-position));
	min = uInt(myatoi(sub));
	position = marker + 1;
    }
    // sec, everything that is left
    sub = s.from(position);
    sec = uInt(myatoi(sub));

    return Time(year, month, day, hour, min, Double(sec));
}

// Finds out what the smallest "next" time is and returns it. It also sets
// isSmallest(i) for all positions which have the smallest time (usually
// just one element is set, but it could be more than one if several FITS
// files have the same time.  If isSmallest(i)==-1, that file is NOT the
// smallest "next", if isSmallest(i)==0, that file IS the smallest but
// it is the CURRENT time and hence should NOT be advanced (this will
// happen at the start of each type that is not the type with values for
// the first row if the start times are different), and if isSmallest(i)==1,
// then next should be called on that file.  currentSmallest is used as
// a comparison against other current times.
Double tmin(const PtrBlock<FITSTimedTable *> tables, Vector<Int> &isSmallest,
	    Double currentSmallest);

// Return True if all files are past EOF or all are past the end time.
Bool done(const PtrBlock<FITSTimedTable *> tables, Double lastTime);

//Usage: tableglue startTime endTime outTable dir1 dir2 ...
// startTime endTime are as described in OS/Time.h
int main(int argc, char **argv)
{
  Timer timer;
  Bool caughtExcp = False;

    try {
	if (argc < 5) {
	    cerr << "Usage: " << argv[0] << " startTime endTime outTable "
		"dir1 dir2 ..." <<
		endl;
	    cout << "Times are expressed as : mm/dd/yyyy,hh:mm:ss" << endl;
	    exit(1);
	}
	cout << "digesting inputs" << endl;

	// Turn the input arguments into Time objects
	String startString(argv[1]);
	String endString(argv[2]);
	Time startTime, endTime;
	startTime = makeTime(startString);
	endTime = makeTime(endString);

	// Start the output table description. Besides its input columns, it
	// has a global time column which contains the time which actually triggered
	// this row.
	cout << "constructing table descriptor" << endl;
	TableDesc td;
	td.addColumn(ScalarColumnDesc<Double>("Time", 
					      "Modified Julian Day Number"));
	td.addColumn(ScalarColumnDesc<Bool>("ROW_FLAG", "Row is bad if True",
					    "IncrementalStMan",
					    "IncrementalStMan",
					    False));

	// Create a Block of FITSTable's, one per input directory. First we 
	// construct a multi-table from all the FITS files which (might) match
	// the time range, and from those we construct a timed table, which knows
	// about the time of the current and next row.
	cout << "constructing descriptor - building FITSMultiTables" << endl;
	uInt nTables = argc - 4;
	PtrBlock<FITSTabular *> tables(nTables);
	PtrBlock<FITSTimedTable *> timedTables(nTables);
	Vector<String> directories(nTables);
	// verbose should probably be another argument
	Bool verbose = True;
	String status_line;
	cout.precision(15);
	for (uInt i=4; Int(i) < argc; i++) {
	    cout << "constructing descriptor - building FITSMultiTable for "
		<< argv[i] << endl;
	    cout << "     - searching for files in time range" << endl;
	    directories(i-4) = argv[i];
	    Path path(directories(i-4));
	    Vector<String> filesInRange(FITSMultiTable::filesInTimeRange(
		directories(i-4), startTime, endTime, verbose, verbose));
	    if (filesInRange.nelements() == 0) {
		cout << "No files of desired type in indicated time range." 
		     << endl;
		cout << "Exiting." << endl;
		return 1;
	    }
	    cout << "     - actually build the tables, first one" << endl;
	    tables[i-4] =  new FITSMultiTable(filesInRange);
	    // Assume column 0 is time for now
	    cout << "     - actually build the tables, then the other" << endl;
	    timedTables[i - 4] = new FITSTimedTable(tables[i - 4]);
	    AlwaysAssertExit(tables[i-4] && timedTables[i-4]);
	    // advance this table to a row n, such that 
	    // time tn+1 >= startTime and time tn < startTime
	    cout << "Advance table type " << i-4 
		 << " to within time range." << endl;
	    uInt count = 0;
	    while ((!timedTables[i-4]->pastEnd()) && 
		   (timedTables[i-4]->currentTime() 
		    < startTime.modifiedJulianDay() &&
		    timedTables[i-4]->nextTime()
		    <= startTime.modifiedJulianDay()) ) {
	      timedTables[i-4]->next();
	      count++;
	    }
	    cout << "Advanced file type " << i-4 << " by " << 
		count << " rows" <<
		endl;
	    // Need better error handling
	    if (timedTables[i-4]->pastEnd()) {
		cout << "File type " << i-4 << 
		    " no data found after indicated start time " << endl;
	    } else {	    
	      cout << "     - and add this to the table description" << endl;
	      addRecordDesc(td, tables[i-4]->description(), path.baseName());
	    }
	}

//    cout << "Table Description " << endl;
//    td.show();
//    cout << endl;

	cout << "Construct the output table." << endl;
    // Finally make the output table. For now, every column except the global
    // Time column is an Incr storage manager column, so values only have to
    // be written into it when they change.
	SetupNewTable setup(argv[3], td, Table::New);
	IncrementalStMan defaultman ("ISM");
	StManAipsIO aipsioman;
	setup.bindAll(defaultman);
//	setup.bindAll(aipsioman);
	setup.bindColumn("Time", aipsioman);
	Table* outTable = new Table(setup);

	cout << "construct the Time column and the Record copiers " << endl;
	ScalarColumn<Double> timeCol(*outTable, "Time");

	// Setup the copiers from the FITS rows to the output table.
	PtrBlock<CopyRecordToTable *> copiers(nTables);
	// Each copier needs a row for each table to copy from
	PtrBlock<Record *> tableRow(nTables);
	Int startColumn = 2; // Would start at zero except we have Time
                             // and ROW_FLAG
	for (uInt i=0; i < nTables; i++) {
	    Vector<Int> mapping(timedTables[i]->description().nfields());
	    if (!timedTables[i]->pastEnd()) {
	      indgen(mapping, startColumn);
	      tableRow[i] = new Record(timedTables[i]->description());
	      *tableRow[i] = timedTables[i]->currentRow();
	      copiers[i] = new CopyRecordToTable(*outTable,
						 *tableRow[i],
						 mapping);
	      AlwaysAssertExit(copiers[i]);
	      startColumn += timedTables[i]->description().nfields();
	    } else {
	      tableRow[i] = 0;
	      copiers[i] = 0;
	    }
	}


	cout << "begin copying values " << endl;

	outTable->addRow();
	// copy the first row of all tables to see the Incr storage manager
	for (uInt i=0; i< nTables; i++) {
	  if (tableRow[i] && copiers[i]) {
	    *tableRow[i] = timedTables[i]->currentRow();
	    copiers[i]->copy(0);
	  }
	}

 	Vector<Int> isSmallest(nTables);
	// And set the Time column to the smallest current time.
	timeCol.put(0, tmin(timedTables, isSmallest, 0.0));

	uInt nrow = 1;

	// Now step through the FITS files, advancing as little as possible each
	// time step, writing out all the matching rows at each minimum step.
	double tEnd = endTime.modifiedJulianDay();
	while (! done(timedTables, tEnd)) {
	    Double smallestNextTime = 
		tmin(timedTables, isSmallest, timeCol(nrow-1));
	    outTable->addRow();
	    for (uInt i=0; i < nTables; i++) {
		if (isSmallest(i) == 0) {
		  // don't advance this one, just copy it
		  if (tableRow[i] && copiers[i]) {
		    *tableRow[i] = timedTables[i]->currentRow();
		    copiers[i]->copy(nrow);
		    // if the next time == this time, advance it here
		    if (timedTables[i]->nextTime() == timedTables[i]->currentTime()) {
		      timedTables[i]->next();
		    }
		  }
		} else if (isSmallest(i) == 1) {
		    //		    String tname = timedTables[i]->name();
		    timedTables[i]->next();
		    //		    if (tname != timedTables[i]->name()) {
		    //			cout << "File change: " << tname << 
		    //			    " to " << timedTables[i]->name() << endl;
		    //		    }
		    if (tableRow[i] && copiers[i]) {
		      *tableRow[i] = timedTables[i]->currentRow();
		      copiers[i]->copy(nrow);
		    }
		}
	    }
	    timeCol.put(nrow, smallestNextTime);
	    nrow++;
	    // if (nrow%100 == 0) cout << "Row : " << nrow << endl;
	} 
	// Delete everything we allocated to precent leaks.
	for (uInt i=0; i < tables.nelements(); i++) {
	    delete tables[i];
	    delete timedTables[i];
	    delete tableRow[i];
	    delete copiers[i];
	}
	cout << "Flushing ouput table to disk." << endl;
	delete outTable;
	cout << nrow << " rows written" << endl;
    } catch (AipsError x) {
	cout << "Exception Caught" << endl;
	caughtExcp = False;
    } 
    if (!caughtExcp) timer.show("Ends successfully : ");
    return 0;
}


Double tmin(const PtrBlock<FITSTimedTable *> tables, Vector<Int> &isSmallest,
	    Double currentSmallest)
{
    AlwaysAssert(tables.nelements() == isSmallest.nelements(), AipsError);

    isSmallest = -1;
    uInt n = tables.nelements();
    if (n == 0)
	return 1.0e+30;

    Double smallest = 1.0e30;
    if (n == 1) {
	isSmallest = 1;
	smallest = tables[0]->currentTime();
	if (smallest <= tables[0]->currentTime()) {
	    smallest = tables[0]->nextTime();
	}
    } else {

	// look at current times first, find smallest currentTime > currentSmallest,
	// don't look at anything already pastEnd()
	Int index = -1;
	for (uInt i=0; i<n; i++) {
	    Double thisOne = tables[i]->currentTime();
	    if (!tables[i]->pastEnd() && 
		thisOne > currentSmallest && thisOne < smallest) {
		smallest = thisOne;
		index = i;
	    }
	}

	// see if any nextTimes are smaller
	for (uInt i=0; i < n; i++) {
	    Double thisOne = tables[i]->nextTime();
	    if (!tables[i]->pastEnd() && thisOne < smallest) {
		smallest = thisOne;
		index = i;
	    }
	}
	if (index < 0) {
	    // find at least one, the first one that isn't past the end
	    for (uInt i=0;i<n;i++) {
		if (!tables[i]->pastEnd()) {
		    index = i;
		    break;
		}
	    }
	    if (index < 0) index = 0;  // ok, give up and use the first one
	}

	if (tables[index]->currentTime() > currentSmallest) {
	    isSmallest(index) = 0;
	    smallest = tables[index]->currentTime();
	} else {
	    isSmallest(index) = 1;
	    smallest = tables[index]->nextTime();
	}

	// See if we have any other matches
	for (uInt i=0; i < n; i++) {
	    // current time
	    if (!tables[i]->pastEnd() && tables[i]->currentTime() == smallest) {
		isSmallest(i) = 0;
	    } else if (!tables[i]->pastEnd() && tables[i]->nextTime() == smallest) {
		isSmallest(i) = 1;
	    }
	}
    }

    return smallest;
}

Bool done(const PtrBlock<FITSTimedTable *> tables, Double lastTime)
{
    uInt n = tables.nelements();

    Bool allPastEof = True;
    for (uInt i=0; i < n; i++) {
	if (! tables[i]->pastEnd()) {
	    allPastEof = False;
	    break;
	}
    }

    Bool allPastEndTime = True;
    for (uInt i=0; i < n; i++) {
	if (tables[i]->nextTime() < lastTime) {
	    allPastEndTime = False;
	    break;
	}
    }

    return (allPastEof || allPastEndTime);
}
