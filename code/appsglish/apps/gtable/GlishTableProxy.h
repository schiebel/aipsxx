//# GlishTableProxy.h: Glish interface to tables
//# Copyright (C) 1994,1995,1996,1997,1998,1999,2000,2001,2002,2003
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
//# $Id: GlishTableProxy.h,v 19.8 2006/09/18 04:58:05 gvandiep Exp $

#ifndef APPSGLISH_GLISHTABLEPROXY_H
#define APPSGLISH_GLISHTABLEPROXY_H


//# Includes
#include <casa/aips.h>
#include <GlishTableHolder.h>
#include <GlishTableIteratorHolder.h>
#include <GlishTableRowHolder.h>
#include <GlishTableIndexHolder.h>
#include <tasking/Glish.h>
#include <casa/BasicSL/String.h>
#include <casa/Containers/Block.h>
#include <vector>

#include <casa/namespace.h>
//# Forward Declarations
namespace casa { //# NAMESPACE CASA - BEGIN
class Table;
class ColumnDesc;
class TableExprNode;
template<class T> class Vector;
class Slicer;
} //# NAMESPACE CASA - END


// <summary>
// Glish interface to tables
// </summary>

// <use visibility=export>

// <reviewed reviewer="Paul Shannon" date="1995/09/15" tests="tgtable.g" demos="">
// </reviewed>

// <prerequisite>
//# Classes you should understand before using this one.
//   <li> class Table
//   <li> class GlishTableHolder
//   <li> class GlishTableIteratorHolder
//   <li> class GlishTableRowHolder
//   <li> class Glish
//   <li> program gtable
//   <li> script gtable.g
// </prerequisite>

// <etymology>
// GlishTableProxy is a proxy for access to tables from a glish script.
// </etymology>

// <synopsis> 
// The Glish client "gtable.cc" and its companion glish script "gtable.g"
// provide convenient access to tables from within the Glish environment.
// The client uses class GlishTableProxy to execute the various
// glish events operating on tables. Furthermore it keeps track of the
// tables, table iterators, and table row objects in use.
// <p>
// The functions in class GlishTable allow gtable.cc to be
// a simple program; it decodes glish events and forwards them to the
// appropriate function.
// The return value of the functions indicate success or failure.
// In case of failure they fill the message argument, which will be
// posted as a table_error event by gtable.cc. In case of success,
// the function will post the table_result event with the appropriate
// value (which will be caught by the glish script gtable.g).
// <p>
// The functions use an object of type
// Block&lt;GlishTableHolder&gt; to keep track of the currently open tables.
// The index in this block is used by the glish script as the table id.
// The <linkto class=GlishTableHolder>GlishTableHolder</linkto>
// object also maintains a mapping between
// a Table object and the table name for all tables used by gtable.cc.
// The same table can be opened only once, unless it has been closed before.
// <p>
// Each time a new table is opened, a GlishTableHolder object is created
// and added to the tableBlock. When a table gets closed permanently,
// that GlishTable object is rendered invalid. In this way it can be
// detected if an old (and now invalid) table id is used in the glish script.
// </synopsis>

// <example>
// The file gtable.cc shows how the functions are used to
// handle a glish event. It makes no sense to repeat it here.
// The glish command "tableHelp (1)" gives quite an extensive explanation
// of the available glish command for the table system. This should make
// things clearer (tableHelp() gives a shorter explanation).
// </example>

// <motivation>
// GlishTableProxy is needed to keep track of tables used in
// glish scripts.
// It also makes the main program gtable.cc as short as possible,
// so one can see the possible events in one glance.
// </motivation>

class GlishTableProxy
{
public:
    // Default constructor initializes to not open.
    // This constructor is only needed for the Block container.
    GlishTableProxy();

    ~GlishTableProxy();

    // Compose the return event name (= event name + "_result").
    static String returnEventName (const GlishSysEvent& event);

    // Open the table with a given name for readonly.
    // The event should contain a GlishArray with the table name.
    // On success it adds the table to the tableBlock and posts an
    // event with the table id.
    Bool open (GlishSysEvent& event,
	       GlishSysEventSource& eventStream,
	       String& message);

    // Open the table with a given name for read/write.
    // The event should contain a GlishArray with the table name.
    // On success it adds the table to the tableBlock and posts an
    // event with the table id.
    Bool openUpdate (GlishSysEvent& event,
		     GlishSysEventSource& eventStream,
		     String& message);

    // Create a table with given name and description.
    // The event should contain a GlishRecord with the fields
    // tableName, tableDesc and optionally nrow (default to 0).
    // tableDesc is a GlishRecord. Each field in it is a columnDesc
    // record; the name of each field is the column name.
    // On success it adds the table to the tableBlock and posts an
    // event with the table id.
    Bool create (GlishSysEvent& event,
		 GlishSysEventSource& eventStream,
		 String& message);

    // Select the given rows from the table.
    // The event should contain a GlishRecord with the fields
    // tableId, rowNumbers, and tableName.
    // tableName is the name of the new table. If blank, a temporary
    // table is returned.
    // On success it adds the table to the tableBlock and posts an
    // event with the table id.
    Bool selectRows (GlishSysEvent& event,
		     GlishSysEventSource& eventStream,
		     String& message);

    // Execute a table select/sort command (as defined in TableGram).
    // The event should contain a GlishArray with the command string.
    // The GlishArray may have multiple values, which will be combined
    // to form the entire string (this is needed to overcome a Glish bug).
    // On success it adds the table to the tableBlock and posts an
    // event with a record containing the fields tableId and tableName.
    // <note>
    // When the command string contains no GIVING part, the resulting
    // table is temporary and its name is blank.
    // </note>
    Bool command (GlishSysEvent& event,
		  GlishSysEventSource& eventStream,
		  String& message);

    // Resync the table with a given id.
    // The event should contain a GlishRecord with the field
    // tableName or tableId.
    // On success it posts a Glish event with the value True.
    Bool resync (GlishSysEvent& event,
		 GlishSysEventSource& eventStream,
		 String& message);

    // Flush the table with a given id.
    // The event should contain a GlishRecord with the field
    // tableName or tableId.
    // On success it posts a Glish event with the value True.
    Bool flush (GlishSysEvent& event,
		GlishSysEventSource& eventStream,
		String& message);

    // Close the table with a given id or name.
    // The event should contain a GlishRecord with the field
    // tableName or tableId.
    // On success it posts a Glish event with the value True.
    Bool close (GlishSysEvent& event,
		GlishSysEventSource& eventStream,
		String& message);

    // Close all open tables.
    // It posts a Glish event with the value True.
    Bool closeAll (GlishSysEvent& event,
		   GlishSysEventSource& eventStream,
		   String& message);

    // Get the endian format of the table.
    // The event should contain a GlishRecord with the field tableId.
    // It posts a GlishEvent with value "big" or "little".
    Bool endianFormat (GlishSysEvent& event,
		       GlishSysEventSource& eventStream,
		       String& message);

    // Acquire a (read or write) lock on the table.
    // The event should contain a GlishRecord with the fields
    // tableId, mode, and nattempts.
    // On success it posts a Glish event with the value True.
    Bool lock (GlishSysEvent& event,
	       GlishSysEventSource& eventStream,
	       String& message);

    // Release a lock on the table.
    // The event should contain a GlishRecord with the field tableId.
    // On success it posts a Glish event with the value True.
    Bool unlock (GlishSysEvent& event,
		 GlishSysEventSource& eventStream,
		 String& message);

    // Determine if data in the table has changed.
    // The event should contain a GlishRecord with the field tableId.
    // It posts a Glish event with the value True when data has changed.
    Bool hasDataChanged (GlishSysEvent& event,
			 GlishSysEventSource& eventStream,
			 String& message);

    // Determine if the process has a read or write lock on the table.
    // The event should contain a GlishRecord with the fields tableId and mode.
    // It posts a Glish event with the value True when it has the lock.
    Bool hasLock (GlishSysEvent& event,
		  GlishSysEventSource& eventStream,
		  String& message);

    // Get the lock options of the table.
    // The event should contain a GlishRecord with the field tableId.
    // It returns a GlishRecord with the fields option, interval,
    // and maxwait.
    Bool lockOptions (GlishSysEvent& event,
		      GlishSysEventSource& eventStream,
		      String& message);

    // Determine if the table is in use in another process.
    // The event should contain a GlishRecord with the field tableId.
    // It posts a Glish event with the value True when it is in use.
    Bool isMultiUsed (GlishSysEvent& event,
		      GlishSysEventSource& eventStream,
		      String& message);

    // Copy the table.
    // The event should contain a GlishArray with the table name
    // and the new table name
    Bool copy (GlishSysEvent& event,
	       GlishSysEventSource& eventStream,
	       String& message);

    // Copy rows from one table to another.
    // The event should contain a GlishArray with the table id-s
    // and optionally start rows and nr of rows.
    Bool copyRows (GlishSysEvent& event,
		   GlishSysEventSource& eventStream,
		   String& message);

    // Rename the table
    // The event should contain a GlishArray with the table name
    // and the new table name
    Bool rename (GlishSysEvent& event,
		 GlishSysEventSource& eventStream,
		 String& message);

    // Delete the table
    // The event should contain a GlishArray with the table name or id.
    // When the table is still open, it is closed first.
    Bool deleteTable (GlishSysEvent& event,
		      GlishSysEventSource& eventStream,
		      String& message);

    // Create a table from an Ascii file.
    // On success it posts and event with a string containing the names
    // and types of the columns (in the form COL1=R, COL2=D, ...).
    Bool readAscii (GlishSysEvent& event,
		    GlishSysEventSource& eventStream,
		    String& message);

    // Get names of all open tables.
    // It posts a Glish event with a GlishArray containing the names.
    Bool getOpenTables (GlishSysEvent& event,
			GlishSysEventSource& eventStream,
			String& message);

    // Get the table name for a given table-id.
    // The event should contain a GlishArray with the table id.
    // On success it posts an event with the name.
    Bool getName (GlishSysEvent& event,
		  GlishSysEventSource& eventStream,
		  String& message);

    // Get the table-id of a given table name.
    // The event should contain a GlishArray with the table name.
    // It fails when no table with this name has been opened.
    // On success it posts an event with the id.
    Bool getId (GlishSysEvent& event,
		GlishSysEventSource& eventStream,
		String& message);

    // Get the table info of the given table.
    // The event should contain a GlishRecord with the field
    // tableName or tableId.
    // On success it posts a Glish event with the value True.
    Bool tableInfo (GlishSysEvent& event,
		    GlishSysEventSource& eventStream,
		    String& message);

    // Put the table info of the given table.
    // The event should contain a GlishRecord with the fields
    // tableId and value. Value should be a GlishRecord with the
    // fields type, subType and/or readme.
    // On success it posts a Glish event with the value True.
    Bool putTableInfo (GlishSysEvent& event,
		       GlishSysEventSource& eventStream,
		       String& message);

    // Adda line to the TableInfo readme.
    // The event should contain a GlishRecord with the fields
    // tableId and value. Value should be a string.
    // On success it posts a Glish event with the value True.
    Bool addReadmeLine (GlishSysEvent& event,
			GlishSysEventSource& eventStream,
			String& message);

    // Test if a table with given name or id is readable.
    // The event should contain a GlishRecord with the field
    // tableName or tableId.
    // On success it posts an event with the value True or False.
    Bool isReadable (GlishSysEvent& event,
		     GlishSysEventSource& eventStream,
		     String& message);

    // Test if a table with given name or id is writable.
    // The event should contain a GlishRecord with the field
    // tableName or tableId.
    // On success it posts an event with the value True or False.
    Bool isWritable (GlishSysEvent& event,
		     GlishSysEventSource& eventStream,
		     String& message);

    // Set the maximum cache size for the given column in the
    // table with the given id.
    // The event should contain a GlishRecord with the fields
    // tableId, column, and nbytes.
    // On success it posts an event with the value True.
    Bool setMaximumCacheSize (GlishSysEvent& event,
			      GlishSysEventSource& eventStream,
			      String& message);

    // Add one or more columns to the table.
    // The event should contain a GlishRecord with the fields
    // tableId and tableDesc.
    // On success it posts an event with the value True.
    Bool addColumns (GlishSysEvent& event,
		     GlishSysEventSource& eventStream,
		     String& message);

    // Rename a columns in the table.
    // The event should contain a GlishRecord with the fields
    // tableId, nameOld, and nameNew..
    // On success it posts an event with the value True.
    Bool renameColumn (GlishSysEvent& event,
		       GlishSysEventSource& eventStream,
		       String& message);

    // Remove one or more columns from the table.
    // The event should contain a GlishRecord with the fields
    // tableId and columns.
    // On success it posts an event with the value True.
    Bool removeColumns (GlishSysEvent& event,
			GlishSysEventSource& eventStream,
			String& message);

    // Add rows to a table with the given id.
    // The event should contain a GlishRecord with the fields
    // tableId and optionally nrow (defaults to 1).
    // On success it posts an event with the value True.
    Bool addRow (GlishSysEvent& event,
		 GlishSysEventSource& eventStream,
		 String& message);

    // Remove rows from a table with the given id.
    // The event should contain a GlishRecord with the fields
    // tableId and rownrs.
    // On success it posts an event with the value True.
    Bool removeRow (GlishSysEvent& event,
		    GlishSysEventSource& eventStream,
		    String& message);

    // Get some or all values from a column in a table with a given id.
    // The event should contain a GlishRecord with the fields tableId,
    // column, row, nrow (-1 = all values from row on), and rowincr. 
    // On success, it posts an event with the value(s).
    // <group>
    Bool getColumn (GlishSysEvent& event,
		    GlishSysEventSource& eventStream,
		    String& message);
    Bool getVarColumn (GlishSysEvent& event,
		       GlishSysEventSource& eventStream,
		       String& message);
    // </group>

    // Get some or all value slices from a column in a table with a given id.
    // The event should contain a GlishRecord with the fields tableId,
    // column, blc, trc, optionally inc, row,
    // nrow (-1 = all values from row on),and rowincr.
    // On success, it posts an event with the value(s).
    Bool getColumnSlice (GlishSysEvent& event,
			 GlishSysEventSource& eventStream,
			 String& message);

    // Put some or all values into a column in a table with a given id.
    // The event should contain a GlishRecord with the fields tableId,
    // column, value, row, nrow (-1 = all values from row on), and rowincr. 
    // On success it posts an event with the value True.
    // <group>
    Bool putColumn (GlishSysEvent& event,
		    GlishSysEventSource& eventStream,
		    String& message);
    Bool putVarColumn (GlishSysEvent& event,
		       GlishSysEventSource& eventStream,
		       String& message);
    // </group>

    // Put some or all value slices into a column in a table with a given id.
    // The event should contain a GlishRecord with the fields tableId,
    // column, value, blc, trc, optionally inc, row,
    // nrow (-1 = all values from row on), and rowincr. 
    // On success it posts an event with the value True.
    Bool putColumnSlice (GlishSysEvent& event,
			 GlishSysEventSource& eventStream,
			 String& message);

    // posts true or false.  expects a record containing table id, column
    // name and row number.
    Bool cellContentsDefined (GlishSysEvent& event,
                              GlishSysEventSource& eventStream,
                              String& message);

    // Get a value from a column in a table with a given id.
    // The event should contain a GlishRecord with the fields tableId,
    // column, and row.
    // On success, it posts an event with the value(s).
    Bool getCell (GlishSysEvent& event,
		  GlishSysEventSource& eventStream,
		  String& message);

    // Get a value slice from a column in a table with a given id.
    // The event should contain a GlishRecord with the fields tableId,
    // column, row, blc, trc, and optionally inc.
    // On success, it posts an event with the value(s).
    Bool getCellSlice (GlishSysEvent& event,
		       GlishSysEventSource& eventStream,
		       String& message);

    // Put a value into a column in a table with a given id.
    // The event should contain a GlishRecord with the fields tableId,
    // column, value, and row.
    // On success it posts an event with the value True.
    Bool putCell (GlishSysEvent& event,
		  GlishSysEventSource& eventStream,
		  String& message);

    // Put a value slice into a column in a table with a given id.
    // The event should contain a GlishRecord with the fields tableId,
    // column, value, row, blc, trc, and optionally inc.
    // On success it posts an event with the value True.
    Bool putCellSlice (GlishSysEvent& event,
		       GlishSysEventSource& eventStream,
		       String& message);

    // Put a value into a column in a table with a given id.
    // The event should contain a GlishRecord with the fields tableId,
    // column, row, nrow (-1 = all values from row on), and incr. 
    // On success, it posts an event with the a Vector<String>
    // containing the shapes as [a,b,c].
    // When the shape is fixed, a single String is returned.
    Bool getColumnShapeString (GlishSysEvent& event,
			       GlishSysEventSource& eventStream,
			       String& message);

    // Get a table or column keyword value in a table with a given id.
    // The event should contain a GlishRecord with the fields tableId,
    // keyword, and optionally column.
    // The keyword can be given as a name or a number.
    // An event is posted with the value of the keyword.
    Bool getKeyword (GlishSysEvent& event,
		     GlishSysEventSource& eventStream,
		     String& message);

    // Get the table or column keyword values in a table with a given id.
    // The event should contain a GlishRecord with the field tableId
    // and optionally column.
    // An event is posted with a GlishRecord containing fields with the
    // values of the keywords (the field names are the keyword names).
    Bool getKeywordSet (GlishSysEvent& event,
			GlishSysEventSource& eventStream,
			String& message);

    // Define a table or column keyword in a table with a given id.
    // The event should contain a GlishRecord with the fields tableId,
    // keyword, value and, optionally column.
    // The keyword can be given as a name or a number.
    // The value should be a GlishArray containing the value of the keyword.
    // On success it posts an event with the value True.
    Bool putKeyword (GlishSysEvent& event,
		     GlishSysEventSource& eventStream,
		     String& message);

    // Define one or more table keywords in a table with a given id.
    // The event should contain a GlishRecord with the fields tableId,
    // value, and optionally column.
    // The value should be a GlishRecord containing fields with the
    // keyword values (the field names are the keyword names).
    // On success it posts an event with the value True.
    Bool putKeywordSet (GlishSysEvent& event,
			GlishSysEventSource& eventStream,
			String& message);

    // Remove a table or column keyword from a table with a given id.
    // The event should contain a GlishRecord with the fields tableId,
    // keyword, and optionally column.
    // The keyword can be given as a name or a number.
    // On success it posts an event with the value True.
    Bool removeKeyword (GlishSysEvent& event,
			GlishSysEventSource& eventStream,
			String& message);

    // Get the names of all field in a record in a table with a given id.
    // The event should contain a GlishRecord with the fields tableId,
    // column, and optionally keyword.
    // If keyword is not given, the names of all keywords are returned.
    // Otherwise the names of all fields in the keyword value are given.
    // That value has to be a record.
    // On success it posts an event with the field names as a GlishArray.
    Bool getFieldNames (GlishSysEvent& event,
			GlishSysEventSource& eventStream,
			String& message);

    // Get the shape (#columns, #rows) of the table with a given id.
    // The event should contain a GlishArray with the table id.
    // On success it posts an event with the shape as a GlishArray.
    Bool shape (GlishSysEvent& event,
		GlishSysEventSource& eventStream,
		String& message);

    // Get the row numbers of the table with a given id.
    // The event should contain a GlishArray with the table id.
    // On success it posts an event with the row numbers as a GlishArray.
    Bool rowNumbers (GlishSysEvent& event,
		     GlishSysEventSource& eventStream,
		     String& message);

    // Get all column names in a table with a given id.
    // The event should contain a GlishArray with the table id.
    // On success it posts an event with the column names as a GlishArray.
    Bool columnNames (GlishSysEvent& event,
		      GlishSysEventSource& eventStream,
		      String& message);

    // when passed the name of a column and a table id, it posts 
    // true or false to the glish bus.
    Bool isScalarColumn (GlishSysEvent& event,
		         GlishSysEventSource& eventStream,
                         String& message);


    // when passed the name of a column and a table id, it posts 
    // a string to the glish bus:  Bool, UChar, Short, UShort, Int, UInt, 
    // Float, Double, Complex, DComplex, String, Table, or unknown

    Bool columnDataType (GlishSysEvent& event,
                         GlishSysEventSource& eventStream,
                         String& message);

    // when passed the name of a column and a table id, it posts 
    // a string to the glish bus: 
    //   Direct
    //   Undefined
    //   FixedShape
    //   Direct,Undefined
    //   Direct,FixedShape
    //   Undefined,FixedShape
    //   Direct,Undefined,FixedShape
    //   Error -- unexpected column type
    Bool columnArrayType (GlishSysEvent& event,
                          GlishSysEventSource& eventStream,
                          String& message);

    // Get the data manager info of the table with the id specified
    // in the value field of <event>.
    // The event should contain a GlishRecord with the field tableId.
    Bool getDataManagerInfo (GlishSysEvent& event,
			     GlishSysEventSource& eventStream,
			     String& message);

    // Get the table description of the table with the id specified
    // in the value field of <event>.
    // A table description consists of a collection of all of the
    // individual column descriptions
    // The event should contain a GlishRecord with the field tableId.
    Bool getTableDescription (GlishSysEvent& event,
                              GlishSysEventSource& eventStream,
                              String& message);

    // Get the column description of a table with the id specified
    // in the value field of <event>
    // The event should contain a GlishRecord with the field 'tableId'
    // and the field 'column'
    Bool getColumnDescription (GlishSysEvent& event,
                               GlishSysEventSource& eventStream,
                               String& message);


    // Extend the table block and add a GlishTable object to it
    // for the given Table.
    // It returns the index of the new table in the block.
    Int addTable (TableProxy& table);

    // Check if the table id is valid, thus if there is a GlishTable
    // object in the block. When the id is invalid, the message buffer gets
    // filled and a False return status is returned.
    // It will check if a put is possible for the table.
    // Optionally it will reopen the table when it is closed.
    Bool validTableId (Int id, String& message,
		       Bool toPut = False,
		       Bool reopen = True);

    // Make a table iterator for a table with the given id.
    // The event should contain a GlishRecord with the fields tableId
    // and columnNames. Similarly to class
    // <linkto class=TableIterator>TableIterator</linkto> the column
    // names are used to construct the iterator.
    // On success it posts an event with a GlishRecord containing the
    // fields iterId and tableId. This table id is used for the tables
    // resulting from each iteration step.
    Bool makeIterator (GlishSysEvent& event,
		       GlishSysEventSource& eventStream,
		       String& message);

    // Do a step in the table iterator with the given id.
    // The table id returned by makeIterator refers to the table
    // resulting from this step.
    // When no more subtables are available, it invalidates the
    // GlishTableIteratorHolder and GlishTableHolder object 
    // (to prevent future use
    // It posts an event with the value True or False. False indicates
    // that the iterator reached the end.
    Bool stepIterator (GlishSysEvent& event,
		       GlishSysEventSource& eventStream,
		       String& message);

    // Delete a TableIter object.
    Bool closeIterator (GlishSysEvent& event,
			GlishSysEventSource& eventStream,
			String& message);

    // Make a TableRow object for a table with the given id.
    // The event should contain a GlishRecord with the fields tableId
    // and optionally columnNames. When columnNames is not given, all
    // columns with a standard data type will be part of the object.
    // Otherwise only the given columns will be used.
    // On success it posts an event with a GlishValue containing the
    // rowId. This row id can be used in the getRow and putRow functions.
    Bool makeRow (GlishSysEvent& event,
		  GlishSysEventSource& eventStream,
		  String& message);

    // Posts the row values as a record.
    // Expects a record containing row id and row number.
    Bool getRow (GlishSysEvent& event,
		 GlishSysEventSource& eventStream,
		 String& message);

    // Puts new values to the specified row. Expects a record 
    // containing table id, row number, and new values (as a record).
    Bool putRow (GlishSysEvent& event,
		 GlishSysEventSource& eventStream,
		 String& message);

    // Delete a TableRow object.
    Bool closeRow (GlishSysEvent& event,
		   GlishSysEventSource& eventStream,
		   String& message);

    // Make an index object for a table with the given id.
    // The event should contain a GlishRecord with the fields tableId,
    // columnNames, and noSort.
    // On success it posts an event with a GlishValue containing the
    // indexId. This index id can be used in the getRowNumber functions.
    Bool makeIndex (GlishSysEvent& event,
		    GlishSysEventSource& eventStream,
		    String& message);

    // Are all keys in the index unqiue?
    // The event should contain a GlishRecord with the field indexId.
    Bool indexIsUnique (GlishSysEvent& event,
			GlishSysEventSource& eventStream,
			String& message);

    // Indicate that some or all columns are changed.
    // The event should contain a GlishRecord with the fields indexId
    // and optionally columnNames.
    Bool indexSetChanged (GlishSysEvent& event,
			  GlishSysEventSource& eventStream,
			  String& message);

    // Get the row number for the given key.
    // The event should contain a GlishRecord with the fields indexId
    // and key (as a record).
    Bool indexGetRowNumber (GlishSysEvent& event,
			    GlishSysEventSource& eventStream,
			    String& message);

    // Get the row number for the given keys(s).
    // The event should contain a GlishRecord with the fields indexId,
    // lowerKey (as a record), and optionally upperKey, lowerIncl, and
    // upperIncl.
    Bool indexGetRowNumbers (GlishSysEvent& event,
			     GlishSysEventSource& eventStream,
			     String& message);

    // Delete a TableIndex object.
    Bool closeIndex (GlishSysEvent& event,
		     GlishSysEventSource& eventStream,
		     String& message);

private:
    // Copy constructor is not needed, so make it private.
    // When it would be implemented, it should take care of the
    // correct copy semantics.
    GlishTableProxy (const GlishTableProxy&);

    // Assignment is not needed, so make it private.
    // When it would be implemented, it should take care of the
    // correct copy semantics.
    GlishTableProxy& operator= (const GlishTableProxy&);

    // Sometimes Glish splits a string into a vector of strings.
    // This functions recombines it to a single string.
    String recombineString (const GlishArray& value) const;

    // Close the table and row objects using it.
    void closeTable (Int tableId);

    // Check if the table name is valid.
    // When <src>canBeOpen==True</src> it is allowed that a table with that
    // name is already open. It returns the id of that table.
    // When the block contains a closed table with this name, that name
    // is cleared to avoid having duplicate names in the table.
    Bool validTableName (const String& name, String& message,
			 Bool canBeOpen, Int& id);

    // Get the lock options from the lockOptions field in the record.
    Record getLockOptions (const GlishRecord& rec);


    // Extend the iterBlock and add a GlishTableIteratorHolder object to it
    // for the given TableIterator.
    // It returns the index of the new iterator in the block.
    Int addIterator (TableIterProxy& iter);

    // Check if the iter id is valid, thus if there is a
    // GlishTableIteratorHolder object in the block.
    // When the id is invalid, the message buffer gets
    // filled and a False return status is returned.
    Bool validIterId (Int id, String& message);

    // Extend the tableRowBlock and add a GlishTableRowHolder object to it.
    // It returns the index of the new object in the block.
    Int addTableRow (const TableRowProxy& row, Int tableId);

    // Check if the row id is valid, thus if there is a
    // GlishTableRowHolder object in the block.
    // When the id is invalid, the message buffer gets
    // filled and a False return status is returned.
    Bool validRowId (Int id, String& message);

    // Extend the indexBlock and add a GlishTableIndexHolder object to it.
    // It returns the index of the new object in the block.
    Int addIndex (TableIndexProxy* index, Int tableId);

    // Check if the index id is valid, thus if there is a
    // GlishTableIndexHolder object in the block.
    // When the id is invalid, the message buffer gets
    // filled and a False return status is returned.
    Bool validIndexId (Int id, String& message);


    // Functions to convert row numbers from and to glish
    // (by subtracting or adding 1).
    // <group>
    static Int rownrToGlish (Int rownr);
    static Array<Int> rownrsToGlish (const Vector<Int>& rownrs);
    static Array<Int> rowposToGlish (const IPosition& rowpos);
    static Int rownrFromGlish (Int rownr);
    static Vector<Int> rownrsFromGlish (const Array<Int>& rownrs);
    static IPosition rowposFromGlish (const Array<Int>& rowpos);
    // </group>

    // Functions to convert a ValueHolder to/from Glish.
    // <group>
    static GlishValue valueToGlish (const ValueHolder&);
    static ValueHolder valueFromGlish (const GlishValue&);
    // </group>


    //# The data members.
    std::vector<GlishTableHolder>          tables_p;
    std::vector<GlishTableIteratorHolder>  iterators_p;
    std::vector<GlishTableRowHolder>       rows_p;
    std::vector<GlishTableIndexHolder>     indices_p;
};


inline Int GlishTableProxy::rownrToGlish (Int rownr)
{
  return rownr+1;
}
inline Int GlishTableProxy::rownrFromGlish (Int rownr)
{
  return rownr-1;
}


#endif
