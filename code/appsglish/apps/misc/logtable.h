//# logtable.h: Distributed Object interface to LogTables
//# Copyright (C) 1997,2000
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
//# $Id: logtable.h,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_LOGTABLE_H
#define APPSGLISH_LOGTABLE_H

//# Includes
#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <casa/Logging/LogIO.h>
#include <tables/Tables/TableExprData.h>
#include <casa/OS/Timer.h>

#include <casa/namespace.h>
//# Forward Declarations
namespace casa { //# NAMESPACE CASA - BEGIN
class TableLogSink;
class String;
class TableExprNode;
class Record;
template<class T> class Vector;
template<class T> class Array;
} //# NAMESPACE CASA - END


// <summary>
// Distributed Object interface to LogTables
// </summary>

// <use visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> Distributed objects
//   <li> Logging
// </prerequisite>
//
// <synopsis>
// This class is not intended to be used directly by users, rather it provides
// support for the glish logger class, basically it handles persistence of the
// log messages.
//
// The log file is by default ~/aips++/aips++.log. However this may be
// changed with the aipsdir and logger.file .aipsrc variables. The directory
// will be created if necessary.
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <todo asof="1997/02/06">
//   <li> add merge capability
// </todo>

class logtable : public ApplicationObject
{
public:
    // Attach to the default logtable:
    // ~/aips++/aips++.log by default (it will make this directory and file
    // if they don't already exist.
    // aipsrc: aipsdir and logger.file can override this
    // logger.file == 'none' results in using a temporary logtable on /tmp.
    logtable();

    // Reference semantics.
    // <group>
    logtable (const logtable& other);
    logtable& operator= (const logtable& other);
    // </group>

    ~logtable();
    
    // Creates it if necessary. Returns False and does not change the log table
    // if it cannot be accessed (e.g., not writable).
    Bool attach(const String& logfile);

    // All messages are written to the logtable, 
    // Any of the following that are 0-length are filled with defaults.
    // Note that we can post many-messages at a time for efficiency.
    // The times, if set, must be MJD in seconds. If the times are missing then
    // the time is set to "NOW".
    Bool addmessages (const Vector<String>& messages,
		      const Vector<Double>& time, 
		      const Vector<String>& priority,
		      const Vector<String>& location,
		      const Vector<String>& id);

    // These correspond to the logger gui windows. If num < 0 set
    // all of them. If num >=0 get that many  from the END.
    void getformatted (Vector<String>& time, Vector<String>& priority, 
		       Vector<String>& messages, Vector<String>& location, 
		       Int num, const String& expr, Bool concat) const;


    // <= 0 means delete all messages.
    // If expr is given, delete all messages matching expr.
    void purge (Int keeplast, const String& expr);

    // How many messages are in the log table.
    Int nmessages() const;

    // More elaborate possibilities are available in the measures module, this
    // is here largely for convenience so you don't need to start up the 
    // measures server if you are solely interested in date-string conversions.
    // This function might also attempt to use the timezone info eventually.
    // type==mjd   mjd days
    //       mjds  mjd seconds
    //       unix  seconds from Jan 1 1970
    String timestring (Double time, const String& type);

    // Returns the file name. This is formatted for 132 columns. It's up to
    // some other process to physically print it to a printer if that is what
    // is desired. If no name is given the name is /tmp/aips_NNN where
    // NNN is a number to get a unique file name.
    String printtofile (Int num, const String& filename,
			const Vector<Int>& colwidth,
			const String& expr, Bool ascommand) const;


    // Needed for the DO system
    // <group>
    virtual String className() const;
    virtual Vector<String> methods() const;
    virtual Vector<String> noTraceMethods() const;
    virtual MethodResult runMethod (uInt which, 
				    ParameterSet& inputRecord,
				    Bool runMethod);
    // </group>

protected:
    enum method_names {ATTACH, ADDMESSAGES, GETFORMATTED, NMESSAGES, PURGE, 
		       TIMESTRING, PRINTTOFILE, N_METHODS};

    LogIO log_p;
    TableLogSink *sink_p;
    // Offset in hours from Greenwich. Set with aipsrc tzoffset var, e.g.
    // "-7". set in attach().
    Double tzoffset_p;

    // Write out the log file every so often just to be safe. Once every 5
    // minutes for now and 100 messages for now
    Timer flush_timer_p;
    uInt nmessages_last_flush_p;

    void flush();
    void printString (ostream& os, const String& string, uInt width) const;
};




// <summary>
// Class to deal with a TaQL expression to filter messages.
// </summary>

// <use visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class=TableExprData>TableExprData</linkto>
// </prerequisite>
//
// <synopsis>
// This class is not intended to be used directly by users, rather it provides
// support for selection of log messages based on a TaQL expression.
// </synopsis>

class logtableExpr : public TableExprData
{
public:
  // Construct it from an expression which gets parsed.
  logtableExpr (const String& expr);

  virtual ~logtableExpr();

  // Does this message match the expression?
  Bool matches (const Double& time, const String& priority,
		const String& message, const String& origin);

  // Get the data.
  // <group>
  virtual Double getDouble (const Block<Int>& fieldNrs) const;
  virtual String getString (const Block<Int>& fieldNrs) const;
  // </group>

  // Get the data type of the various values.
  virtual DataType dataType (const Block<Int>& fieldNrs) const;

private:
  // Copy constructor and assignment are forbidden.
  // <group>
  logtableExpr (const logtableExpr&);
  logtableExpr& operator= (const logtableExpr&);
  // </group>

  TableExprNode* itsExpr;
  const Double*  itsTime;
  const String*  itsMessage;
  const String*  itsPriority;
  const String*  itsOrigin;
};

#endif
