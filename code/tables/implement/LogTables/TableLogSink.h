//# TableLogSink.h: Save log messages in an AIPS++ Table
//# Copyright (C) 1996,1997,1998,2000,2001,2003
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
//# $Id: TableLogSink.h,v 19.7 2004/11/30 17:51:00 ddebonis Exp $

#ifndef TABLES_TABLELOGSINK_H
#define TABLES_TABLELOGSINK_H

//# Includes
#include <casa/aips.h>
#include <casa/Logging/LogSink.h>
#include <casa/Logging/LogFilter.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/ScalarColumn.h>
#include <tables/Tables/ArrayColumn.h>
#include <casa/Utilities/Assert.h>
#include <casa/Exceptions/Error.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward Declarations
class TableDesc;
class SetupNewTable;

// <summary>
// Save log messages in an AIPS++ Table
// </summary>

// <use visibility=export>

// <reviewed reviewer="wbrouw" date="1996/08/21" tests="tLogging.cc" demos="dLogging.cc">
// </reviewed>

// <prerequisite>
//   <li> <linkto class=LogSinkInterface>LogSinkInterface</linkto>
//   <li> <linkto module=Tables>Tables</linkto>
// </prerequisite>
//
// <etymology>
// Log to an AIPS++ Table.
// </etymology>
//
// <synopsis>
// Unlike the other classes derived from 
// <linkto class=LogSinkInterface>LogSinkInterface</linkto>, there are utility
// functions in this class which might be of some modest interest. In
// particular, the member functions which define the structure of the table
// and define the column names might be of interest.
//
// This class posts messages which pass the filter to an AIPS++
// <linkto class=Table>Table</linkto>. It puts ever field of the
// <linkto class=LogMessage>LogMessage</linkto> into its own column.
// </synopsis>
//
// <example>
// See <linkto file="Logging.h">Logging.h</linkto>.
// </example>
//
// <motivation>
// "Persistent" log messages must be stored in a Table.
// </motivation>
//
// <todo asof="2001/06/12">
//   <li> Allow a subset of the columns to be written? e.g., only time, 
//        message, and priority.
//   <li> Allow time sorting in concatenate?
// </todo>

class TableLogSink : public LogSinkInterface
{
public:
  // If <src>fileName</src> exists, attach and append to it, otherwise create
  // a table with that name. If the table exists, it must have all the
  // required columns defined by <src>logTableDescription()</src>.
  // <p>
  // The <src>useSSM</src> is a temmporary fix to make it possible
  // to use the old StManAipsIO storage manager for a log table.
  // It is used by PagedImage to make it possible to access release 1.4
  // images with release 1.3 software.
  // <group>
  TableLogSink (LogMessage::Priority filter, const String& fileName,
		Bool useSSM=True);
  TableLogSink (const LogFilterInterface& filter, const String& fileName,
		Bool useSSM=True);
  // </group>

  // Open the log table for readonly.
  // If needed, reopenRW can be used later to define a filter and
  // to open the logtable for writing.
  explicit TableLogSink (const String& fileName);

  // After copying, both sinks will write to the same <src>Table</src>.
  // <group>
  TableLogSink (const TableLogSink& other);
  TableLogSink& operator= (const TableLogSink& other);
  // </group>

  ~TableLogSink();

  // Reopen the logtable for read/write (if needed).
  // When it actually reopens, the given filter will be used.
  void reopenRW (const LogFilterInterface& filter);

  // If the message passes the filter, write it to the log table.
  virtual Bool postLocally (const LogMessage& message);

  // Get number of messages in sink.
  virtual uInt nelements() const;

  // Get given part of the i-th message from the sink.
  // <group>
  virtual Double getTime (uInt i) const;
  virtual String getPriority (uInt i) const;
  virtual String getMessage (uInt i) const;
  virtual String getLocation (uInt i) const;
  virtual String getObjectID (uInt i) const;
  // </group>

  // Access to the actual log table and its columns.
  // <note role=caution>
  // Functions <src>time, priority, message, location, objectID</src>
  // return a null <src>ScalarColumn</src> object when the logtable is
  // not writable. Using it may result in using a null pointer
  // causing a core dump. In debug mode it is checked if the object
  // is not null.
  // </note>
  // <group>
  const Table& table() const;
  Table& table();
  const ROScalarColumn<Double>& roTime() const;
  ScalarColumn<Double>& time();
  const ROScalarColumn<String>& roPriority() const;
  ScalarColumn<String>& priority();
  const ROScalarColumn<String>& roMessage() const;
  ScalarColumn<String>& message();
  const ROScalarColumn<String>& roLocation() const;
  ScalarColumn<String>& location();
  const ROScalarColumn<String>& roObjectID() const;
  ScalarColumn<String>& objectID();
  // </group>
  
  // Defines the minimal set of columns in the table (more may exist, but
  // are ignored.
  enum Columns { 
    // MJD in seconds, UT. (Double.)
    TIME, 
    // Message importance. (String).
    PRIORITY,
    // Informational message. (String).
    MESSAGE, 
    // Source code origin of the log message. Usually a combination of
    // class name, method name, file name and line number, but any String
    // is legal.
    LOCATION, 
    // ObjectID of distributed object that created the message (String).
    // If empty, no OBJECT_ID was set.
    OBJECT_ID
  };

  // Turn the <src>Columns</src> enum into a String which is the actual
  // column name in the <src>Table</src>.
  static String columnName(Columns which);

  // Description of the log table. You can use this if, e.g., you do not
  // want to use the storage managers that this class creates by default
  // (currently Miriad).
  static TableDesc logTableDescription();

  // Write out any pending output to the table.
  virtual void flush (Bool global=True);

  // Write a message (usually from another logsink) into the local one.
  virtual void writeLocally (Double time, const String& message,
			     const String& priority, const String& location,
			     const String& objectID);

  // Clear the local sink (i.e. remove all messages from it).
  virtual void clearLocally();

  // Returns the id for this class...
  static String localId( );
  // Returns the id of the LogSink in use...
  String id( ) const;

  // Make a LogSink for a TableLogSink with a new table.
  // Default filter is <src>NORMAL</src>.
  // <group>
  static LogSink makeSink (const String& fileName);
  static LogSink makeSink (LogMessage::Priority filter,
			   const String& fileName);
  static LogSink makeSink (const LogFilterInterface& filter,
			   const String& fileName);
  // </group>

private:
  // Undefined and inaccessible
  TableLogSink();
  // Avoid duplicating code in copy ctor and assignment operator
  void copy_other(const TableLogSink& other);
  // Make a new log table.
  void makeTable (SetupNewTable&, Bool useSSM);
  // Attach the column objects and create unit keywor if needed.
  void attachCols();
  // Initialize the object.
  void init (const String& fileName, Bool useSSM);


  Table log_table_p;
  // Message
  ROScalarColumn<Double>  roTime_p;
  ROScalarColumn<String>  roPriority_p;
  ROScalarColumn<String>  roMessage_p;
  // Origin
  ROScalarColumn<String>  roLocation_p;
  // ObjectID
  ROScalarColumn<String>  roId_p;
  ScalarColumn<Double>  time_p;
  ScalarColumn<String>  priority_p;
  ScalarColumn<String>  message_p;
  // Origin
  ScalarColumn<String>  location_p;
  // ObjectID
  ScalarColumn<String>  id_p;
};

//# Inlines
inline const Table& TableLogSink::table() const {return log_table_p;}
inline Table& TableLogSink::table() {return log_table_p;}

inline const ROScalarColumn<Double>& TableLogSink::roTime() const
  {return roTime_p;}
inline ScalarColumn<Double>& TableLogSink::time()
  {DebugAssert(!time_p.isNull(),AipsError); return time_p;}
inline const ROScalarColumn<String>& TableLogSink::roPriority() const 
   {return roPriority_p;}
inline ScalarColumn<String>& TableLogSink::priority()
  {DebugAssert(!priority_p.isNull(),AipsError); return priority_p;}
inline const ROScalarColumn<String>& TableLogSink::roLocation() const 
  {return roLocation_p;}
inline ScalarColumn<String>& TableLogSink::location()
  {DebugAssert(!location_p.isNull(),AipsError); return location_p;}
inline const ROScalarColumn<String>& TableLogSink::roObjectID() const 
  {return roId_p;}
inline ScalarColumn<String>& TableLogSink::objectID()
  {DebugAssert(!id_p.isNull(),AipsError); return id_p;}
inline const ROScalarColumn<String>& TableLogSink::roMessage() const
  {return roMessage_p;}
inline ScalarColumn<String>& TableLogSink::message()
  {DebugAssert(!message_p.isNull(),AipsError); return message_p;}

inline LogSink TableLogSink::makeSink (const String& fileName)
  { return makeSink (LogFilter(), fileName); }
inline LogSink TableLogSink::makeSink (LogMessage::Priority filter,
				       const String& fileName)
  { return makeSink (LogFilter(filter), fileName); }



} //# NAMESPACE CASA - END

#endif
