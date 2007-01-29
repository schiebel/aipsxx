//# logtable.cc: Distributed Object interface to LogTables
//# Copyright (C) 1997,1998,2000,2001,2002
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
//# $Id: logtable.cc,v 19.5 2004/11/30 17:50:08 ddebonis Exp $

#include <../misc/logtable.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ObjectController.h>
#include <casa/System/Aipsrc.h>
#include <casa/System/AppInfo.h>
#include <tables/LogTables/TableLogSink.h>
#include <casa/Logging/LogSink.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayMath.h>
#include <tables/Tables/TableParse.h>
#include <tables/Tables/RowCopier.h>
#include <casa/Quanta/MVTime.h>
#include <casa/OS/Time.h>
#include <casa/OS/Path.h>
#include <casa/OS/Directory.h>
#include <casa/BasicSL/Constants.h>
#include <casa/Exceptions/Error.h>

#include <casa/fstream.h>
#include <casa/iostream.h>
#include <casa/iomanip.h>

//# For logtableExpr
#include <tables/Tables/ExprNode.h>
#include <tables/Tables/RecordGram.h>
#include <casa/Containers/Record.h>
#include <casa/Containers/Block.h>

#include <casa/namespace.h>
logtable::logtable()
: sink_p    (0),
  tzoffset_p(0.0),
  nmessages_last_flush_p(0)
{
    // Initially attach to cerr so we can be sure we see error mages if
    // logging is hosed.
    LogSink tmp(LogMessage::WARN, &cerr);
    log_p = tmp;

    log_p << LogOrigin("logtable", "logtable()", WHERE);

    String aipsdir = Aipsrc::aipsHome();
    String errmsg;

    String logfile;
    Aipsrc::find(logfile, "logger.file", "aips++.log");
    if (logfile.empty()) {
        logfile = "aips++.log";
        errmsg += "Empty logfile .aipsrc variable found, using aips++.log";
    } else if (logfile == "none") {
        logfile = "";
    }

    if (!logfile.empty()) {
      // prepend aipsdir only if logfile not an absolute path
      // (relative paths ok, as long as directories already exist,
      //  non-existent directory structures are handled elsewhere)
      if (logfile.firstchar() != '/' ) {
	logfile = aipsdir + "/" + logfile;
      } 
      Path path(logfile);
      logfile = path.expandedName();
    }

    // Accumulate the errors in a string so that if we eventually do attach
    // to a file we can post the accumulated errors there.

    attach(logfile);
    if (sink_p == 0) {
	// Our strategy is to first try mv'ing the old log table out of the
	// way, if that fails to try writing in /tmp.
	String newname = 
	    File::newUniqueName(aipsdir, "aips++.garbled.log.").expandedName();

	errmsg += String("Cannot attach to logtable : ") + logfile +
	    " (logtable seems to be garbled)\n" +
	    "Attempting to move old logtable to " + newname + 
	    " and create a new one.\n";

	Bool caught = False;
	try {
	    Directory dir1(logfile);
	    dir1.move(newname);
	    attach(logfile);
	} catch (AipsError x) {
	    caught = True;
	    errmsg += String("Rename/Create failed! : ") + x.getMesg() + "\n";
	} 
	if (!caught) {
	    errmsg += "You may want to examine or delete " +
		newname + "\n";
	}

	if (sink_p == 0) {
	    String newlogfile = 
		File::newUniqueName("/tmp", "aips++.log.").expandedName();
	    errmsg += String("Last resort, attempting to attach to: ") +
		newlogfile + "\n";
	    attach(newlogfile);
	    if (sink_p == 0) {
		errmsg += String("Cannot attach to /tmp/aips++.log. ") +
		    "Log messages will be lost!!\n";
	    }
	}
    }

    // Leave the local sink attached to the cerr global sink in case anything
    // bad happens to logging.
//     if (sink_p != 0) {
// 	// OK, we are attached, so we should be able to disable the local sink
// 	// and attach ourselves to the normal global log sink
// 	ObjectController* controller = 
// 	    ApplicationEnvironment::objectController();
// 	if (controller) {
// 	    controller->setGlobalLogSink();
// 	    // Set the local sink to null since we have a global sink
// 	    LogSink null;
// 	    log_p = LogIO(null); 
// 	}
//     }

    // Flush the error message.
    if (errmsg != "") {
	log_p << LogIO::WARN << WHERE << errmsg << LogIO::POST;
    }
}

logtable::logtable (const logtable& other)
: sink_p    (0),
  tzoffset_p(other.tzoffset_p),
  nmessages_last_flush_p(other.nmessages_last_flush_p)
{
    LogSink tmp(LogMessage::DEBUGGING, &cerr);
    log_p = tmp;

    if (other.sink_p) {
	sink_p = new TableLogSink(*(other.sink_p));
	if (sink_p == 0) {
	    log_p << LogOrigin("logtable", "logtable(const logtable& )",WHERE);
	    log_p << LogIO::SEVERE << "logtable::logtable - memory problem. "
		"Log messages may be dropped." << LogIO::POST;
	}
    }
    if (sink_p != 0) {
	// Log messages are going somewhere now. Make the local sink null.
	LogSink null;
	log_p = LogIO(null);
    }
}

logtable& logtable::operator=(const logtable& other)
{
    if (this != &other) {
	tzoffset_p = other.tzoffset_p;
        nmessages_last_flush_p = other.nmessages_last_flush_p;
	delete sink_p;
	sink_p = 0;
	if (other.sink_p) {
	    sink_p = new TableLogSink(*(other.sink_p));
	    if (sink_p == 0) {
		log_p << LogOrigin("logtable", "operator=", WHERE) <<
		    LogIO::SEVERE;
		log_p << "logtable::operator= - memory problem. Log messages"
		    " may be dropped." << LogIO::POST;
	    }
	}
    }

    if (sink_p != 0) {
	// Log messages are going somewhere now. Make the local sink null.
	LogSink null;
	log_p = LogIO(null);
    } else {
	LogSink tmp(LogMessage::DEBUGGING);
	log_p = tmp;
    }

    return *this;
}

logtable::~logtable()
{
    delete sink_p;
    sink_p = 0;
}

Bool logtable::attach(const String& logTable)
{
    // This is a good place to set tzoffset
    tzoffset_p = AppInfo::timeZone();

    String afterCreationMessage; // message we don't want to send until
                                 // after the table is attached

    Bool ok = False;
    String tabName = logTable;
    // An empty name means a new scratch logtable on /tmp.
    if (logTable.empty()) {
        tabName = File::newUniqueName("/tmp", "aips++log_").originalName();
    }
    try {
	// First see if the logtable already exists and is writable.
	Bool readable = Table::isReadable(tabName);
	Bool writable = False;
	Directory dir = Directory(Path(tabName).dirName());
	if (readable) {
	    writable = Table::isWritable(tabName);
	} else {
	    // Logtable does not exist.
	    // If the directory exists, see if it is a writable directory.
	    // Attempt to make the directory if it does not exist.
	    if (dir.exists()) {
		if (!dir.isDirectory()) {
		    log_p << dir.path().originalName() << 
			" is not a directory! Cannot create a "
			"logfile." << LogIO::SEVERE << LogIO::POST;
		    return False;
		}
		if (!dir.isWritable()) {
		    log_p << "Directory " << dir.path().originalName() << 
			" is not writable! Cannot create a "
			"logfile." << LogIO::SEVERE << LogIO::POST;
		    return False;
		}
	    } else {
		// Directory does not exist, try to create it.
		try {
		    dir.create();
		} catch (AipsError x) {
		    log_p << "Cannot create directory " << 
			dir.path().originalName() << 
			LogIO::SEVERE << LogIO::POST;
		    return False;
		} 
		afterCreationMessage += "Created directory ";
		afterCreationMessage += dir.path().originalName() + "\n";
	    }
	}

	TableLogSink* newsink = 0;
	if (readable && !writable) {
	    // Open as readonly.
	    newsink = new TableLogSink(tabName);
	    afterCreationMessage += tabName + " exists but is not writable.";
	} else {
	    // Create or open as read/write.
	    newsink = new TableLogSink(LogMessage::DEBUGGING, tabName);
	    if (writable) {
		afterCreationMessage += String("Attached to existing file ") +
		    tabName;
	    } else {
		if (logTable.empty()) {
		    // Mark a scratch table for delete.
		    newsink->table().markForDelete();
		    afterCreationMessage += " Using temporary log file " + 
		                            tabName;
		} else {
		    afterCreationMessage += String("Created log file ") + 
		                            Path(tabName).baseName();
		}
	    }
	}
	if (newsink) {
	    if (sink_p) {delete sink_p;}
	    sink_p = newsink;
	    nmessages_last_flush_p = sink_p->table().nrow();
	    ok = True;
	} else {
	    log_p << LogIO::SEVERE << 
		LogOrigin("logtable", "attach()", WHERE) << 
		"Memory problem" << LogIO::POST;
	    return False;
	}
    } catch (AipsError x) {
	log_p << LogIO::SEVERE << "Exception trying to attach to " << 
	    tabName << " (" << x.getMesg() << ")" << LogIO::POST;
	ok = False;
    } 

    if (afterCreationMessage != "") {
	log_p << LogIO::NORMAL << afterCreationMessage << LogIO::POST;
    }
    return ok;
}

Bool logtable::addmessages(const Vector<String>& messages,
			   const Vector<Double>& time, 
			   const Vector<String>& priority,
			   const Vector<String>& location,
			   const Vector<String>& id)
{
    static Int dropCount = 0;
    if (sink_p == 0  ||  !sink_p->table().isWritable()) {
	if (dropCount  == 0 || dropCount%100 == 0) {
	    log_p << LogIO::SEVERE << 
		"Not attached to a writable log file, have dropped " <<
		dropCount << " log messages in total" << LogIO::POST;
	}
	dropCount += messages.nelements();
	return False;
    }

    // Assume that message.nelements() is the most relevant
    const uInt n = messages.nelements();
    const uInt offset = sink_p->table().nrow();

    Double now_mjdsec = Time().modifiedJulianDay()*24.0*3600.0;
    
    sink_p->table().addRow(n);

    for (uInt i=0; i<n; i++) {
	sink_p->message().put(i+offset, messages(i));
	if (i < time.nelements()) {
	    sink_p->time().put(i+offset, time(i));
	} else {
	    // If we don't have a time, use the current time
	    sink_p->time().put(i+offset, now_mjdsec);
	}
	if (i < priority.nelements()) {
	    sink_p->priority().put(i+offset, priority(i));
	}
	if (i < location.nelements()) {
	    sink_p->location().put(i+offset, location(i));
	}
	if (i < id.nelements()) {
	    sink_p->objectID().put(i+offset, id(i));
	}
    }


    flush();

    return True;
}

void logtable::getformatted(Vector<String>& time, Vector<String>& priority, 
			    Vector<String>& messages,
			    Vector<String>& location,
			    Int num, const String& expr, Bool concat) const
{
    if (sink_p == 0) {
	time.resize(0); priority.resize(0); messages.resize(0); 
	location.resize(0);
	return; // no messages if no table!
    }

    // Get the logtable.
    // Do a selection/sort if needed.
    Table logtab(sink_p->table());
    if (! expr.empty()) {
        logtab = tableCommand ("select from $1 " + expr, logtab);
    }
    ROScalarColumn<Double> roTime 
            (logtab, TableLogSink::columnName(TableLogSink::TIME));
    ROScalarColumn<String> roPriority
            (logtab, TableLogSink::columnName(TableLogSink::PRIORITY));
    ROScalarColumn<String> roMessage
            (logtab, TableLogSink::columnName(TableLogSink::MESSAGE));
    ROScalarColumn<String> roLocation
            (logtab, TableLogSink::columnName(TableLogSink::LOCATION));

    const Int nrow = logtab.nrow();
    if (num < 0) {
	num = nrow;
    } else if (num > nrow) {
	num = nrow;
    }

    if (concat) {
	time.resize(1);
	priority.resize(1);
	messages.resize(1); 
	location.resize(1);
    } else {
	time.resize(num);
	priority.resize(num);
	messages.resize(num); 
	location.resize(num);
    }
    if (num == 0) {
        return;
    }

    uInt nr = 0;
    String lastPriority = roPriority(nrow-num);

    String stringtmp;
    String messagetmp;
    MVTime timetmp;
    String timetmp2;
    timetmp.setFormat(MVTime::DMY);
    const String nl = "\n";
    String prioritytmp;
    String locationtmp;
    for (Int i=0; i<num; i++) {
        Int pos = nrow - num + i;
	Double timesec = roTime(pos);
	messagetmp = roMessage(pos);
	prioritytmp = roPriority(pos);
	locationtmp = roLocation(pos);
	if (concat) {
	    // Store a new priority in a new vector.
	    if (prioritytmp != lastPriority) {
	        lastPriority = prioritytmp;
		nr += 1;
		if (time.nelements() <= nr) {
		    time.resize (2*nr, True);
		    priority.resize (2*nr, True);
		    messages.resize (2*nr, True);
		    location.resize (2*nr, True);
		}
	    }

	    // messages
	    if (Int(messages(nr).length() + messagetmp.length() + 1) > 
		Int(messages(nr).allocation())) {
		// Resize exponentially for efficiency
		stringtmp = messages(nr);
		messages(nr).alloc(2*messages(nr).allocation() + 1);
		messages(nr) = stringtmp;
	    }
	    messages(nr) += messagetmp;
	    messages(nr) += nl;
	} else {
	    messages(i) = messagetmp;
	}

	// time
	if (timesec > 0) {
	    timetmp = timesec/3600.0/24.0 + tzoffset_p;
	    timetmp2 = timetmp.string();
	} else {
	    timetmp2 = "";
	}
	if (concat) {
	    if (Int(time(nr).length() + timetmp2.length() + 1) > 
		Int(time(nr).allocation())) {
		// Resize exponentially for efficiency
		stringtmp = time(nr);
		time(nr).alloc(2*time(nr).allocation() + 1);
		time(nr) = stringtmp;
	    }
	    time(nr) += timetmp2;
	    time(nr) += nl;
	} else {
	    time(i) = timetmp2;
	}

	// priority
	if (concat) {
	    if (Int(priority(nr).length() + prioritytmp.length() + 1) > 
		Int(priority(nr).allocation())) {
		// Resize exponentially for efficiency
		stringtmp = priority(nr);
		priority(nr).alloc(2*priority(nr).allocation() + 1);
		priority(nr) = stringtmp;
	    }
	    priority(nr) += prioritytmp;
	    priority(nr) += nl;
	} else {
	    priority(i) = prioritytmp;
	}

	// location
	if (concat) {
	    if (Int(location(nr).length() + locationtmp.length() + 1) > 
		Int(location(nr).allocation())) {
		// Resize exponentially for efficiency
		stringtmp = location(nr);
		location(nr).alloc(2*location(nr).allocation() + 1);
		location(nr) = stringtmp;
	    }
	    location(nr) += locationtmp;
	    location(nr) += nl;
	} else {
	    location(i) = locationtmp;
	}

	// For multi-line messages, we need to pad location etc. with
	// nl's if concat is True.
	if (concat) {
	    // Assume that only messages only have \n's in them; count them.
	    uInt len = messagetmp.length();
	    const char* ptr = messagetmp.chars();
	    uInt nlcount = 0;
	    for (uInt j=0; j<len; j++) {
	        if (ptr[j] == '\n') {
		    nlcount++;
		}
	    }
	    for (uInt j=0; j<nlcount; j++) {
		time(nr) += nl;
		priority(nr) += nl;
		location(nr) += nl;
	    }
	}
    }
    if (concat) {
        time.resize (nr+1, True);
        priority.resize (nr+1, True);
        messages.resize (nr+1, True);
        location.resize (nr+1, True);
    }
}

Int logtable::nmessages() const
{
    Int retval = 0;
    if (sink_p != 0) {
	retval = sink_p->table().nrow();
    }
    return retval;
}

void logtable::purge(Int keeplast, const String& expr)
{
    if (sink_p == 0  ||  !sink_p->table().isWritable()) {
	return; // no-op if we're not attached to a writable table
    }

    // See if its possible to delete rows at all
    if (! sink_p->table().canRemoveRow()) {
	log_p << LogIO::SEVERE << "Cannot remove rows from this table!" <<
	    LogIO::POST;
	return;
    }

    Vector<uInt> deleteList;
    if (expr.empty()) {
        // Keep first keepLast rows in log table.
        Int nrow = sink_p->table().nrow();
        if (nrow <= keeplast) {
	    // no-op if we already have fewer than the requested num or rows
	    return; 
	}
	if (keeplast < 0) {
	    keeplast = 0;
	}
	deleteList.resize (nrow - keeplast);
	indgen (deleteList);
	log_p << LogIO::NORMAL << "Deleting first " << nrow - keeplast
	      << " rows in the log table." << endl;
    } else {
        // Remove rows matching the expression.
        Table tab = tableCommand ("select from $1 " + expr, sink_p->table());
	if (tab.nrow() == 0) {
	    return;
	}
	deleteList = tab.rowNumbers();
	log_p << LogIO::NORMAL << "Deleting " << tab.nrow()
	      << " rows in the log table matching '" << expr << "'" << endl;
    }
    sink_p->table().removeRow (deleteList);
}


String logtable::timestring(Double time, const String& type)
{
    MVTime formatter;
    formatter.setFormat(MVTime::DMY);
    String retval;

    if (type == "mjd") {
	formatter = time + tzoffset_p;
	retval = formatter.string();
    } else if (type == "mjds") {
	formatter = time/C::day + tzoffset_p;
	retval = formatter.string();
    } else if (type == "unix") {
	// Tim Cornwell came up with this constant.
	formatter = time/C::day + 40587.0 + tzoffset_p;
	retval = formatter.string();
    } else {
	retval = "BAD DATE";
    }
    return retval;
}

String logtable::printtofile(Int num, const String& filename,
			     const Vector<Int>& colwidth,
			     const String& expr, Bool ascommand) const
{
    Path file (filename);
    if (filename.empty()) {
        file = Path (File::newUniqueName("/tmp", "aips_"));
    }

    Vector<String> time, priority, messages, location;
    getformatted(time, priority, messages, location, num, expr, False);

    ofstream os(file.expandedName().chars());
    os.setf(ios::left);

    if (ascommand) {
      for (uInt i=0; os && i<messages.nelements(); i++) {
	String& msg = messages(i);
	if (msg.length() > 2  &&  msg[0] == '>'  &&  msg[1] == ' ') {
	  os << msg.from(2) << endl;
	}
      }
    } else {

      Int timewidth = 20;
      if (colwidth.nelements() > 0  &&  colwidth(0) >= 0) {
	timewidth = colwidth(0);
      }
      Int priowidth = 6;
      if (colwidth.nelements() > 1  &&  colwidth(1) >= 0) {
	priowidth = colwidth(1);
      }
      Int originwidth = 25;
      if (colwidth.nelements() > 3  &&  colwidth(3) >= 0) {
	originwidth = colwidth(3);
      }
      for (uInt i=0; os && i<messages.nelements(); i++) {
	Int totwidth = 0;
	if (timewidth > 0) {
	  printString (os, time(i), timewidth);
	  totwidth += timewidth + 2;
	}
	if (priowidth > 0) {
	  printString (os, priority(i), priowidth);
	  totwidth += priowidth + 2;
	}
	if (originwidth > 0) {
	  printString (os, location(i), originwidth);
	  totwidth += originwidth + 2;
	}
	// We need to worry about at least \n's and tabs
	const char* ptr = messages(i).chars();
	const uInt len = messages(i).length();
	uInt messoffset = 0;
	for (uInt j=0; j<len; j++) {
	  Char ch = ptr[j];
	  if (ch == '\n') {
	    os << ch;
	    messoffset = 0;
	    for (Int k=0; k<totwidth; k++) {
	      os << ' ';
	    }
	  } else if (ch == '\t') {
	    // Assume 8 character tabs
	    uInt tabremaining = 8 - (messoffset % 8);
	    for (uInt k=0; k<tabremaining; k++) {
	      os << ' ';
	    }
	    messoffset += tabremaining;
	  } else {
	    // Assume it's an ordinary printing character
	    os << ch;
	    messoffset++;
	  }
	}
	os << '\n';
      }
    }

    if (!os) {
      logtable* This = const_cast<logtable*>(this);
      This->log_p << LogIO::NORMAL << 
	    "Unknown error writing to file. File may be bad." << LogIO::POST;
    }

    return file.expandedName();
}

void logtable::printString (ostream& os, const String& string,
			    uInt width) const
{
    if (string.length() <= width) {
        os << string;
	if (string.length() < width) {
	    uInt rest = width - string.length();
	    for (uInt i=0; i<rest; i++) {
	        os << ' ';
	    }
	}
    } else {
        os << (const_cast<String&>(string))(0,width);
    }
    os << "  ";
}


String logtable::className() const
{
    return "logtable";
}

Vector<String> logtable::methods() const
{
    Vector<String> names(N_METHODS);
    names(ATTACH) = "attach";
    names(ADDMESSAGES) = "addmessages";
    names(GETFORMATTED) = "getformatted";
    names(PURGE) = "purge";
    names(NMESSAGES) = "nmessages";
    names(TIMESTRING) = "timestring";
    names(PRINTTOFILE) = "printtofile";
    return names;
}

Vector<String> logtable::noTraceMethods() const
{
    // all of them!
    return methods();
}

MethodResult logtable::runMethod(uInt which, ParameterSet& inputRecord,
				 Bool runMethod)
{
    switch(which) {
    case ATTACH:
	{
	    static String returnvalString = "returnval";
	    static String logfileString = "logfile";
	    Parameter<Bool> returnval(inputRecord, returnvalString,
				      ParameterSet::Out);
	    Parameter<String> logfile(inputRecord, logfileString, 
				      ParameterSet::In);
	    if (runMethod) {
		returnval() = attach(logfile());
	    }
	}
    break;
    case ADDMESSAGES:
	{
	    static String returnvalString = "returnval";
	    static String timeString = "time";
	    static String priorityString = "priority";
	    static String messagesString = "messages";
	    static String locationString = "location";
	    static String idString = "id";
	    Parameter<Bool> returnval(inputRecord, returnvalString,
				      ParameterSet::Out);
	    Parameter< Vector<String> > messages(inputRecord, messagesString, 
				      ParameterSet::In);
	    Parameter< Vector<Double> > time(inputRecord, timeString, 
				      ParameterSet::In);
	    Parameter< Vector<String> > priority(inputRecord, priorityString, 
				      ParameterSet::In);
	    Parameter< Vector<String> > location(inputRecord, locationString, 
				      ParameterSet::In);
	    Parameter< Vector<String> >   id(inputRecord, idString,
					  ParameterSet::In);
	    if (runMethod) {
		returnval() = addmessages(messages(), time(), priority(),
					  location(), id());
	    }
	}
    break;
    case GETFORMATTED:
	{
	    static String timeString("time");
	    static String priorityString("priority");
	    static String messagesString("messages");
	    static String locationString("location");
	    static String numString("num");
	    static String exprString("expr");
	    static String concatString("concat");
	    Parameter< Vector<String> > time(inputRecord, timeString, 
				   ParameterSet::Out);
	    Parameter< Vector<String> > priority(inputRecord, priorityString, 
				   ParameterSet::Out);
	    Parameter< Vector<String> > messages(inputRecord, messagesString, 
				   ParameterSet::Out);
	    Parameter< Vector<String> > location(inputRecord, locationString, 
				   ParameterSet::Out);
	    Parameter<Int> num(inputRecord, numString, 
			       ParameterSet::In);
	    Parameter<String> expr(inputRecord, exprString, 
				   ParameterSet::In);
	    Parameter<Bool> concat(inputRecord, concatString, 
				   ParameterSet::In);
	    if (runMethod) {
		getformatted(time(), priority(), messages(), location(),
			     num(), expr(), concat());
	    }
	}
    break;
    case NMESSAGES:
	{
	    static String returnvalString = "returnval";
	    Parameter<Int> returnval(inputRecord, returnvalString, 
				      ParameterSet::Out);
	    if (runMethod) {
		returnval() = nmessages();
	    }
	}
    break;
    case PURGE:
	{
	    static String keeplastString = "keeplast";
	    static String exprString = "expr";
	    Parameter<Int> keeplast(inputRecord, keeplastString, 
				      ParameterSet::In);
	    Parameter<String> expr(inputRecord, exprString, 
				   ParameterSet::In);
	    if (runMethod) {
		purge(keeplast(), expr());
	    }
	}
    break;
    case TIMESTRING:
	{
	    static String returnvalString = "returnval";
	    static String timeString = "time";
	    static String typeString = "type";
	    Parameter<String> returnval(inputRecord, returnvalString,
				      ParameterSet::Out);
	    Parameter<String> type(inputRecord, typeString, 
				      ParameterSet::In);
	    Parameter<Double> time(inputRecord, timeString, 
				      ParameterSet::In);
	    if (runMethod) {
		returnval() = timestring(time(), type());
	    }
	}
    break;
    case PRINTTOFILE:
	{
	    static String returnvalString = "returnval";
	    static String numString = "num";
	    static String filenameString = "filename";
	    static String colwidthString = "colwidth";
	    static String exprString = "expr";
	    static String ascommandString = "ascommand";
	    Parameter<String> returnval(inputRecord, returnvalString,
				      ParameterSet::Out);
	    Parameter<Int> num(inputRecord, numString, 
				      ParameterSet::In);
	    Parameter<String> filename(inputRecord, filenameString, 
				       ParameterSet::In);
	    Parameter<Vector<Int> > colwidth(inputRecord, colwidthString, 
					     ParameterSet::In);
	    Parameter<String> expr(inputRecord, exprString, 
				   ParameterSet::In);
	    Parameter<Bool> ascommand(inputRecord, ascommandString, 
				      ParameterSet::In);
	    if (runMethod) {
		returnval() = printtofile(num(), filename(), colwidth(),
					  expr(), ascommand());
	    }
	}
    break;
    default:
	return error("Unknown method");
    }

    return ok();
}

void logtable::flush()
{
    Int nrow = 0;
    if (sink_p  ||  !sink_p->table().isWritable()) {
        nrow = sink_p->table().nrow();
    }
    if ((nrow - nmessages_last_flush_p > 100) || 
	(flush_timer_p.real() > 300)) {
	if (sink_p) {
	    sink_p->table().flush();
	    nmessages_last_flush_p = nrow;
	}
        flush_timer_p.mark();
    }
}





logtableExpr::logtableExpr (const String& expr)
: itsExpr (0)
{
  // Make a description for the parser.
  RecordDesc desc;
  desc.addField ("TIME", TpDouble);
  desc.addField ("PRIORITY", TpString);
  desc.addField ("MESSAGE", TpString);
  desc.addField ("ORIGIN", TpString);
  itsExpr = new TableExprNode (RecordGram::parse (Record(desc), expr));
}

logtableExpr::~logtableExpr()
{
  delete itsExpr;
}

Bool logtableExpr::matches (const Double& time, const String& priority,
			    const String& message, const String& origin)
{
  // Evaluate the expression for this message.
  itsTime     = &time;
  itsPriority = &priority;
  itsMessage  = &message;
  itsOrigin   = &origin;
  Bool valb;
  // This class contains the functions to get the values.
  itsExpr->get (*this, valb);
  return valb;
}

Double logtableExpr::getDouble (const Block<Int>& fieldNrs) const
{
  switch (fieldNrs[0]) {
  case 0:
    return *itsTime;
  default:
    throw (AipsError("logtableExpr::getDouble"));
  }
}

String logtableExpr::getString (const Block<Int>& fieldNrs) const
{
  switch (fieldNrs[0]) {
  case 1:
    return *itsPriority;
  case 2:
    return *itsMessage;
  case 3:
    return *itsOrigin;
  default:
    throw (AipsError("logtableExpr::getString"));
  }
}

DataType logtableExpr::dataType (const Block<Int>& fieldNrs) const
{
  switch (fieldNrs[0]) {
  case 0:
    return TpDouble;
  case 1:
  case 2:
  case 3:
    return TpString;
  default:
    throw (AipsError("logtableExpr::dataType"));
  }
}
