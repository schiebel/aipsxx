//# GBTFillerState.cc: this is what does all of the work of GBTFiller
//# Copyright (C) 1995,1996,1997,1998,1999,2001
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
//# $Id: GBTFillerState.cc,v 19.5 2004/11/30 17:50:40 ddebonis Exp $

//# Includes

#include <GBTFillerState.h>

#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Containers/RecordField.h>
#include <casa/Containers/SimOrdMap.h>
#include <fits/FITS/FITSMultiTable.h>
#include <fits/FITS/FITSTimedTable.h>
#include <nrao/FITS/OldGBTBackendTable.h>
#include <nrao/FITS/OldGBTPositionTable.h>
#include <fits/FITS/CopyRecord.h>
#include <casa/Arrays/Slice.h>
#include <casa/BasicMath/Math.h>
#include <casa/OS/Path.h>
#include <casa/OS/File.h>
#include <casa/OS/Directory.h>
#include <casa/OS/DirectoryIterator.h>
#include <tables/Tables.h>
#include <casa/Utilities/Assert.h>

#include <casa/stdio.h>
#include <casa/sstream.h>

#include <casa/namespace.h>
FITSTabular * makeGBTBackend(const String& fileName)
{
    return new OldGBTBackendTable(fileName);
}

FITSTabular * makeGBTPosition(const String& fileName)
{
    return new OldGBTPositionTable(fileName);
}
    
void history(GlishSysEventSource *eventStream, const String& msg)
{
    if (eventStream && eventStream->hasInterpreter()) {
        eventStream->postEvent("history",msg);
    } else {
        cout << msg << endl;
    }
}

Vector<Int> makeMapping(const SimpleOrderedMap<String, Int>& map, 
			const RecordDesc &rd, 
			const String &prefix = String(""))
{
    // construct a mapping of elements on rd to td
    // length of vector is element in rd, value at each element
    // is the appropriate map to td.
    // If not in td, value is -1
    // prefix is prepended to all names in rd before comparison
    
    Vector<Int> mapping(rd.nfields());
    mapping = -1;

    for (uInt i=0;i<rd.nfields();i++) {
	String name = prefix + rd.name(i);
	if (map.isDefined(name)) mapping(i) = map(name);
    }
    return mapping;
}

GBTFillerState::GBTFillerState(int argc, char **argv)
    : endOfTimeRange_(False), stream_p(0), inputs_(argc, argv), 
      backTab_p(0), timedBackTab_p(0), backCopier_p(0), ndap_(0), dapTabs_(0), 
      timedDapTabs_(0), baseDapNames_(0), dapCopiers_(0), outTable_p(0), 
      tableCounter_(0), timeCol_p(0), scanField_p(0), objectField_p(0)  
{
    String msg = "Filling using files in the following time range : ";
    history(stream_p,msg);
    ostringstream startStream;
    startStream << inputs_.startTime();
    ostringstream stopStream;
    stopStream << inputs_.stopTime();
    String start(startStream), stop(stopStream);
    msg = start + " to " + stop;
    history(stream_p,msg);
    msg = "Selecting object names that match : " + inputs_.object();
    history(stream_p, msg);
    lastBackTime_ = inputs_.startTime();
    update();
}

GBTFillerState::GBTFillerState(GlishValue record, GlishSysEventSource *eventStream)
    : endOfTimeRange_(False), stream_p(eventStream), inputs_(record), 
      backTab_p(0), timedBackTab_p(0), backCopier_p(0), ndap_(0), dapTabs_(0), 
      timedDapTabs_(0), baseDapNames_(0), dapCopiers_(0), outTable_p(0),
      tableCounter_(0), timeCol_p(0), scanField_p(0), objectField_p(0)
{
    if (inputs_.ok()) {
       String msg = "Filling using files in the following time range : ";
       history(stream_p,msg);
       ostringstream startStream;
       startStream << inputs_.startTime();
       ostringstream stopStream;
       stopStream << inputs_.stopTime();
       String start(startStream), stop(stopStream);
       msg = start + " to " + stop;
       history(stream_p,msg);
       msg = "Selecting object names that match : " + inputs_.object();
       history(stream_p, msg);
       lastBackTime_ = inputs_.startTime();
       update();
    } 
}

GBTFillerState::~GBTFillerState()
{
    delete backTab_p;
    delete timedBackTab_p;
    delete backCopier_p;

    for (uInt i=0; i<ndap_; i++) {
	delete timedDapTabs_[i];
	delete dapTabs_[i];
	delete dapCopiers_[i];
    }

    delete outTable_p;
    delete timeCol_p;
    delete scanField_p;
    delete objectField_p;
}

void GBTFillerState::setDAPSize(uInt minSize)
{
    // determine new size, default minimum is 8
    uInt currSize = dapTabs_.nelements();
    uInt newSize = max(minSize, 2 * currSize);

    // and resize everything
    dapTabs_.resize(newSize);
    timedDapTabs_.resize(newSize);
    dapCopiers_.resize(newSize);
    baseDapNames_.resize(newSize);

    // and make sure that the pointers are set to zero
    for (uInt i=currSize;i<newSize;i++) {
	dapTabs_[i] = 0;
	timedDapTabs_[i] = 0;
	dapCopiers_[i] = 0;
    }
}

void GBTFillerState::update()
{
    // construct the backend stuff if we haven't already
    // This assumes that the format for the backend files doesn't
    // change after the initial file

    Vector<String> backendFiles(FITSMultiTable::filesInTimeRange(
	inputs_.backendName(), lastBackTime_, inputs_.stopTime()));
    // if nothing was found, simply return
    if (backendFiles.nelements() == 0) return;

    if (backTab_p) {
	// delete backTab_p and timedBackTab_p
	delete timedBackTab_p;
	timedBackTab_p = 0;
	delete backTab_p;
	backTab_p = 0;
	delete backCopier_p;
	backCopier_p = 0;
    }

    backTab_p = new FITSMultiTable(backendFiles, makeGBTBackend);
    AlwaysAssert(backTab_p, AipsError);
    // if the table is invalid, simply return
    if (! backTab_p->isValid()) {
	delete backTab_p;
	backTab_p = 0;
	return;
    }
    // and construct a TimedTable from this
    timedBackTab_p = new FITSTimedTable(backTab_p);
    AlwaysAssert(timedBackTab_p, AipsError);
    if (! timedBackTab_p->isValid()) {
	delete timedBackTab_p;
	timedBackTab_p = 0;
	return;
    }

    // update lastBackTime_ to time of current file in backTab_p
    lastBackTime_ = FITSMultiTable::timeFromFile(backTab_p->name());
    // subtract 1 second just to be sure
    lastBackTime_ = lastBackTime_ + (-1.0/(60.0*24.0*24.0));
	
    // find the list of all directories under the project
    uInt nfiles = inputs_.projectDir().nEntries();
    DirectoryIterator projectDirIter(inputs_.projectDir());
    uInt dirCount = 0;
   
    Vector<String> dirs(nfiles);
    while (! projectDirIter.pastEnd()) {
	File possDirFile(projectDirIter.file());
	projectDirIter++;
	String tmp = possDirFile.path().baseName();
	tmp.upcase();
	// skip this file if it is a backend subdirectory
	// There is no easy way to do this, for now, I'll be
	// quick and VERY dirty - this is NOT a good long 
	// term solution
	if (tmp == "DCR" || tmp == "SP" || tmp == "HOLO") continue;

	// also skip if this is . or ..
	if (tmp == "." || tmp == "..") continue;

	if (possDirFile.isDirectory()) {
	    dirs(dirCount) = possDirFile.path().absoluteName();
	    dirCount++;
	} 
    }
    // cut the Vector down to size
    Vector<String> dapDirs(dirs(Slice(0,dirCount)));

    if (dapDirs.nelements() > timedDapTabs_.nelements())
	setDAPSize(dapDirs.nelements());

    for (uInt i=0;i<ndap_;i++) {
	if (timedDapTabs_[i]) {
	    delete timedDapTabs_[i];
	    delete dapTabs_[i];
	    delete dapCopiers_[i];
	    timedDapTabs_[i] = 0;
	    dapTabs_[i] = 0;
	    dapCopiers_[i] = 0;
	}
    }

    ndap_ = 0;
    for (uInt i=0;i<dapDirs.nelements();i++) {
	Path path(dapDirs(i));
	String pathbasename = path.baseName();
	pathbasename.upcase();
	Vector<String> files(FITSMultiTable::filesInTimeRange(
	    dapDirs(i), lastBackTime_, inputs_.stopTime()));
	if (files.nelements() != 0) {
	    if (pathbasename == "RADEC") {
		dapTabs_[ndap_] =  new FITSMultiTable(files, makeGBTPosition);
	    } else {
		dapTabs_[ndap_] = new FITSMultiTable(files);
	    }
	    timedDapTabs_[ndap_] = new FITSTimedTable(dapTabs_[ndap_]);
	    AlwaysAssert(dapTabs_[ndap_] && 
			 timedDapTabs_[ndap_], AipsError);
	    // only add this if everything is valid
	    if (dapTabs_[ndap_]->isValid() && 
		timedDapTabs_[ndap_]->isValid()) {
		baseDapNames_[ndap_] = path.baseName();
		ndap_++;
	    } else {
		// clean up 
		delete dapTabs_[ndap_];
		delete timedDapTabs_[ndap_];
		dapTabs_[ndap_] = 0;
		timedDapTabs_[ndap_] = 0;
	    }
	}
    }
    setOutTable();
}

void GBTFillerState::setOutTable()
{
    // table descriptor to hold any new descriptions
    TableDesc td;
    // add description from backend table to td
    addRecordDesc(td, backTab_p->description(),"");

    // add a ROW_FLAG column
    td.addColumn(ScalarColumnDesc<Bool>("ROW_FLAG", "Row is bad if True",
    					"IncrementalStMan","IncrementalStMan",
    					False));

    // add description from each DAP table to td
    for (uInt i=0;i<ndap_;i++) {
	addRecordDesc(td, timedDapTabs_[i]->description(), 
		      baseDapNames_[i]);
    }

    String outTabName;
    if (!outTable_p) {
	// need to construct one
	outTabName = makeTableName();

	File tableFile(outTabName);
	if (tableFile.exists() && tableFile.isWritable()) {
	    // open the table
	    outTable_p = new Table(outTabName, Table::Update);
	    if (!outTable_p) {
		throw(AllocError("gbtfiller - fillit() - unable to allocate "
				 "new Table",1));
	    }
	    history(stream_p, outTabName + " - old table re-opened");
	    mergeTableDesc(td);
	} else {
	    // otherwise build one from scratch
	    buildTable(outTabName, td);
	}
	if (timeCol_p) delete timeCol_p;
	timeCol_p = new ROScalarColumn<Double>(*outTable_p, "Time");
	AlwaysAssert(timeCol_p, AipsError);
    } else {
	// table already is open, merge the new stuff we've found, in td
	mergeTableDesc(td);
    }

    // make a map of names to column numbers
    Vector<String> colNames(outTable_p->tableDesc().columnNames());
    SimpleOrderedMap<String, Int> map(-1);
    for (uInt j=0;j<colNames.nelements();j++) map.define(colNames(j),j);

    if (scanField_p) delete scanField_p;
    scanField_p = new RORecordFieldPtr<Int>(timedBackTab_p->currentRow(), 
		   timedBackTab_p->currentRow().description().fieldNumber("SCAN"));
    AlwaysAssert(scanField_p, AipsError);
    if (objectField_p) delete objectField_p;
    if (timedBackTab_p->currentRow().description().fieldNumber("OBJECT") >= 0) {
	objectField_p =  new RORecordFieldPtr<String>(timedBackTab_p->currentRow(),
		   timedBackTab_p->currentRow().description().fieldNumber("OBJECT"));
	AlwaysAssert(objectField_p, AipsError);
    } else {
	objectField_p = 0;
    }

    // set up any copiers as needed
    // one for the backend table
    Vector<Int> mapping = makeMapping(map, timedBackTab_p->description());
    if (backCopier_p) {
      delete backCopier_p;
      backCopier_p = 0;
    }
    backCopier_p = new CopyRecordToTable(*outTable_p,
					 timedBackTab_p->currentRow(),
					 mapping);
    AlwaysAssert(backCopier_p, AipsError);

    // and one each for the DAP tables
    for (uInt i=0;i < ndap_; i++) {
	Vector<Int> mapping = makeMapping(map, timedDapTabs_[i]->description(),
			      (baseDapNames_[i]+String("_")) );
	dapCopiers_[i] = new CopyRecordToTable(*outTable_p,
					       timedDapTabs_[i]->currentRow(),
					       mapping);
	AlwaysAssert(dapCopiers_[i], AipsError);
    }
}

void GBTFillerState::mergeTableDesc(const TableDesc& td)
{
     // fortunately, td only contains ColumnDesc stuff at
     // this point, so we only need to deal with that.
     const TableDesc oldTd(outTable_p->tableDesc());
     IncrementalStMan defaultman ("ISM");;
     StManAipsIO aipsioman;
     String dataManType;
     Bool newTimeColumn = False;

     for (uInt i=0;i<td.ncolumn();i++) {
 	ColumnDesc newCol(td[i]);
 	if (oldTd.isColumn(newCol.name())) {
 	    ColumnDesc oldCol(oldTd[newCol.name()]);
 	    if (oldCol != newCol) {
 		// I think this is an error in any case
 		throw(AipsError("Column in new data is incompatible "
 				"with existing table " +
 				newCol.name()));
 	    }
 	} else {
 	    history(stream_p,"New column : " + newCol.name());
  	    if (newCol.name() == "Time") {
  		dataManType = aipsioman.dataManagerType();
 		newTimeColumn = True;
  	    } else {
  		dataManType = defaultman.dataManagerType();
  	    }
  	    // add it in, this gets ugly
  	    switch (newCol.dataType()) {
  	    case TpBool:
  		outTable_p->addColumn(
  		    ScalarColumnDesc<Bool>(newCol.name(), newCol.comment(),
  					   dataManType,""));
		break;
	    case TpChar:
  		outTable_p->addColumn(
  		    ScalarColumnDesc<Char>(newCol.name(), newCol.comment(),
  					   dataManType,""));
		break;
	    case TpUChar:
  		outTable_p->addColumn(
  		    ScalarColumnDesc<uChar>(newCol.name(), newCol.comment(),
  					    dataManType,""));
		break;
	    case TpShort:
  		outTable_p->addColumn(
  		    ScalarColumnDesc<Short>(newCol.name(), newCol.comment(),
  					    dataManType,""));
		break;
	    case TpUShort:
  		outTable_p->addColumn(
  		    ScalarColumnDesc<uShort>(newCol.name(), newCol.comment(),
  					     dataManType,""));
		break;
	    case TpInt:
  		outTable_p->addColumn(
  		    ScalarColumnDesc<Int>(newCol.name(), newCol.comment(),
  					  dataManType,""));
		break;
	    case TpUInt:
  		outTable_p->addColumn(
  		    ScalarColumnDesc<uInt>(newCol.name(), newCol.comment(),
  					   dataManType,""));
		break;
	    case TpFloat:
  		outTable_p->addColumn(
  		    ScalarColumnDesc<Float>(newCol.name(), newCol.comment(),
  					    dataManType,""));
		break;
	    case TpDouble:
		outTable_p->addColumn(
		    ScalarColumnDesc<Double>(newCol.name(), newCol.comment(),
					     dataManType,""));
		break;
	    case TpComplex:
  		outTable_p->addColumn(
  		    ScalarColumnDesc<Complex>(newCol.name(), newCol.comment(),
  					      dataManType,""));
		break;
	    case TpDComplex:
  		outTable_p->addColumn(
  		    ScalarColumnDesc<DComplex>(newCol.name(), newCol.comment(),
  					       dataManType,""));
		break;
	    case TpString:
  		outTable_p->addColumn(
  		    ScalarColumnDesc<String>(newCol.name(), newCol.comment(),
  					     dataManType,""));
		break;
	    case TpTable:
		// I don't believe we can have columns of tables,
		// at any rate, we shouldn't, so throw an error
		throw(AipsError("A column of TpTable was found : "
				"this should never happen."));
		break;
  	    case TpArrayBool:
  		outTable_p->addColumn(
  		    ArrayColumnDesc<Bool>(newCol.name(), newCol.comment(),
  					  dataManType,"",
  					  newCol.shape()));
  		break;
  	    case TpArrayChar:
  		outTable_p->addColumn(
  		    ArrayColumnDesc<Char>(newCol.name(), newCol.comment(),
  					  dataManType,"",
  					  newCol.shape()));
  		break;
  	    case TpArrayUChar:
  		outTable_p->addColumn(
  		    ArrayColumnDesc<uChar>(newCol.name(), newCol.comment(),
  					   dataManType,"",
  					   newCol.shape()));
  		break;
  	    case TpArrayShort:
  		outTable_p->addColumn(
  		    ArrayColumnDesc<Short>(newCol.name(), newCol.comment(),
  					   dataManType,"",
  					   newCol.shape()));
  		break;
  	    case TpArrayUShort:
  		outTable_p->addColumn(
  		    ArrayColumnDesc<uShort>(newCol.name(), newCol.comment(),
  					    dataManType,"",
  					    newCol.shape()));
  		break;
  	    case TpArrayInt:
  		outTable_p->addColumn(
  		    ArrayColumnDesc<Int>(newCol.name(), newCol.comment(),
  					 dataManType,"",
  					 newCol.shape()));
  		break;
  	    case TpArrayUInt:
  		outTable_p->addColumn(
  		    ArrayColumnDesc<uInt>(newCol.name(), newCol.comment(),
  					  dataManType,"",
  					  newCol.shape()));
  		break;
  	    case TpArrayFloat:
  		outTable_p->addColumn(
  		    ArrayColumnDesc<Float>(newCol.name(), newCol.comment(),
  					   dataManType,"",
  					   newCol.shape()));
  		break;
  	    case TpArrayDouble:
  		outTable_p->addColumn(
  		    ArrayColumnDesc<Double>(newCol.name(), newCol.comment(),
  					    dataManType,"",
  					    newCol.shape()));
  		break;
  	    case TpArrayComplex:
  		outTable_p->addColumn(
  		    ArrayColumnDesc<Complex>(newCol.name(), newCol.comment(),
  					     dataManType,"",
  					     newCol.shape()));
  		break;
  	    case TpArrayDComplex:
  		outTable_p->addColumn(
  		    ArrayColumnDesc<DComplex>(newCol.name(), newCol.comment(),
  					      dataManType,"",
  					      newCol.shape()));
  		break;
  	    case TpArrayString:
 		outTable_p->addColumn(
 		    ArrayColumnDesc<String>(newCol.name(), newCol.comment(),
  					    dataManType,"",
  					    newCol.shape()));
  		break;
  	    case TpOther:
  	    default:
  		// This should never happen
 		throw(AipsError("An unknown column type was found : "
 				"this should never happen."));
  		break;
 	    }
 	}
     }
     if (newTimeColumn) {
 	if (timeCol_p) delete timeCol_p;
 	timeCol_p = new ROScalarColumn<Double>(*outTable_p, "Time");
 	AlwaysAssert(timeCol_p, AipsError);
     }
}

void GBTFillerState::fillit()
{
    // loop through the backend table until pastEnd() or past end of desired time

    // skip if we don't have a backend table
    if (! backTab_p) {
	history(stream_p,"No backend files to fill from in current time range");
	return;
    }

    uInt nrow = outTable_p->nrow();
    char msg[120];
    sprintf(msg,"Filling at row %i",nrow);
    history(stream_p,msg);

    // find the time of the last row in the table, if there are any rows
    Double thisTime = inputs_.startTime().modifiedJulianDay();
    Double finalTime = inputs_.stopTime().modifiedJulianDay();
    Double lastTime = 0.0;
    Int lastScan = -1;
    if (outTable_p->nrow() > 0) {
	// start after the last row
        thisTime = (*timeCol_p)(outTable_p->nrow()-1);
    }

    // advance until the backend table is > thisTime
    uInt nmove = 0;
    while (!timedBackTab_p->pastEnd() && 
	   timedBackTab_p->currentTime() <= thisTime) {
      timedBackTab_p->next();
      nmove++;
    }

    // the underlying backend file descriptor may have changed
    if (timedBackTab_p->hasChanged()) {
	setOutTable();
	timedBackTab_p->resetChangedFlag();
	nrow = outTable_p->nrow();
    }

    Bool alreadySkipped = False;
    if (!objectField_p) {
	sprintf(&(msg[0]),"No OBJECT field available for this backend - no object selection available.");
	history(stream_p,msg);
    }
    while (!timedBackTab_p->pastEnd()  && thisTime <= finalTime) {
	if (**scanField_p != lastScan) {
	    //	do we skip this scan or use it
	    if (objectField_p && 
		!(**objectField_p).matches(inputs_.objectRegex())) {
		sprintf(&(msg[0]),"Skipping scan %i : %s does not match %s",
			**scanField_p,
			(**objectField_p).chars(),
			inputs_.object().chars());
		alreadySkipped = True;
	    } else {
		sprintf(&(msg[0]),"Filling scan : %i",**scanField_p);
		alreadySkipped = False;
	    }
	    history(stream_p,msg);
	    lastScan = **scanField_p;
	}
	if (alreadySkipped) {
	    timedBackTab_p->next();
	    if (timedBackTab_p->hasChanged()) {
		setOutTable();
		timedBackTab_p->resetChangedFlag();
		nrow = outTable_p->nrow();
	    } else {
		nrow++;
	    }
	    continue;
	}
	// we don't know if things have changed until everything has moved
	// move now
 	// if thisTime != lastTime set time on those that require it
 	// everybody moves or interpolates
	if (thisTime != lastTime) {
	    for (uInt i=0;i<ndap_;i++) {
		timedDapTabs_[i]->setTime(thisTime);
	    }
	}

	// see if anything has changed, make a new table, etc, if it has
	Bool changed = timedBackTab_p->hasChanged();
	timedBackTab_p->resetChangedFlag();
	for (uInt i=0;i<ndap_;i++) {
	    changed = (changed || timedDapTabs_[i]->hasChanged());
	    timedDapTabs_[i]->resetChangedFlag();
	}
	if (changed) {
	    setOutTable();
	    nrow = outTable_p->nrow();
	}

	outTable_p->addRow();
 	// copy the backend data for this row
	backCopier_p->copy(nrow);

	thisTime = timedBackTab_p->currentTime();
 	// if thisTime != lastTime set time on those that require it
 	// everybody moves or interpolates
	if (thisTime != lastTime) {
	    for (uInt i=0;i<ndap_;i++) {
		timedDapTabs_[i]->setTime(thisTime);
		// only copy if ok
		if (timedDapTabs_[i]->ok()) dapCopiers_[i]->copy(nrow);
	    }
	    lastTime = thisTime;
       	}

	timedBackTab_p->next();
	if (timedBackTab_p->hasChanged()) {
	    setOutTable();
	    timedBackTab_p->resetChangedFlag();
	    nrow = outTable_p->nrow();
	} else {
	    nrow++;
	}
    }

    endOfTimeRange_ = (thisTime > finalTime);
    // remember where we are, but only if we are actually somewhere
    if (outTable_p->nrow() > 0) {
      thisTime = (*timeCol_p)(outTable_p->nrow()-1);
      // this is an MJD, convert to JD and then to Time
      lastBackTime_ = Time(thisTime + 2400000.5);
    }
    
    // flush out the table
    outTable_p->flush();

    // send a table_name event if connected
    if (stream_p && stream_p->hasInterpreter()) {
        stream_p->postEvent("table_name",outTable_p->tableName());
    }
}

String GBTFillerState::makeTableName()
{
    String tableName;
    // See if tableFile() has a valid file name
    tableName = inputs_.tableFile().path().absoluteName();
    if (tableName.empty()) {
	// otherwise, use the default name
	tableName = inputs_.projectDir().path().baseName() + "_" + 
	    inputs_.backend() + ".Table";
    }

    // append _N where N = tableCounter_ if tableCounter_ > 0
    if (tableCounter_ > 0) {
	char *appendName = new char[10];
	sprintf(appendName,"_%i",tableCounter_);
	tableName = tableName + String(appendName);
	delete appendName;
    }
    return tableName;
}

void GBTFillerState::buildTable(const String &outTabName, const TableDesc &td)
{
    // For now, every column except Time and DATA uses 
    // a Incr storage manager column eventually, when it 
    // is available, it may make sense to use a
    // tiled storage manager on the DATA column
    // Although since it makes sense that the DATA column
    // is an indirect array, perhaps the THSM could not be used here.

    SetupNewTable setup(outTabName, td, Table::New);
    IncrementalStMan defaultman ("ISM");
    StManAipsIO aipsioman;
    setup.bindAll(defaultman);
    setup.bindColumn("Time", aipsioman);
    // the DATA column will not exist for some data (currently just Holo).
    if (td.isColumn("DATA")) {
	setup.bindColumn("DATA", aipsioman);
    }
    outTable_p = new Table(setup);
    if (!outTable_p) {
	throw(AllocError("gbtfiller - update() - unable to allocate "
			 "new Table",1));
    }
    history(stream_p, String(outTabName +  " new output table created."));
}
