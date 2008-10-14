//# gtable.cc: A Glish client for Tables
//# Copyright (C) 1994,1995,1996,1997,1998,1999,2000,2001,2002,2003
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
//# $Id: gtable.cc,v 19.4 2004/11/30 17:50:07 ddebonis Exp $

//# <todo asof="1997/06/26>
//#  <li>
//# </todo>

#include <GlishTableProxy.h>
#include <tasking/Glish.h>
#include <tables/Tables/Table.h>
#include <casa/System/AipsrcValue.h>
#include <casa/Containers/Block.h>
#include <casa/BasicSL/String.h>
#include <casa/Exceptions/Error.h>

#include <casa/OS/Memory.h>

#include <casa/namespace.h>
int main(int argc, char **argv)
{
    // Get the relinquish autolock period.
    Int relinqMsec = 5000;
    Int relinqAll = 10;
    {
      Float relPeriod;
      AipsrcValue<Float>::find (relPeriod,
				"table.relinquish.reqautolocks.interval", 5);
      if (relPeriod > 0) {
	relinqMsec = Int (1000 * relPeriod + 0.5);
      }
      AipsrcValue<Float>::find (relPeriod,
				"table.relinquish.allautolocks.interval", 60);
      relinqAll = Int (1000*relPeriod / relinqMsec + 0.5);
      if (relinqAll <= 0) {
	relinqAll = 1;
      }
    }
    Int ntimeouts = 0;
    Bool withTimeout = False;
    Bool hasEvent;
    GlishSysEventSource eventStream(argc, argv);
    GlishSysEvent event;
    GlishTableProxy proxy;
    String message;
    while(eventStream.connected()) {
      Bool ok = True;
      try {

	// Wait for next next glish event. Use timeout if switch is set.
	if (withTimeout) {
	  hasEvent = eventStream.nextGlishEvent (event, relinqMsec);
	}else{
	  event = eventStream.nextGlishEvent();     // block until next event
	  hasEvent = True;
	}
	// If timed out, relinquish auto locks when needed by other processes.
	// On every relinqAll-th time out, relinquish all auto locks.
	// If no autolocks left, switch timeout off.
	if (!hasEvent) {
	  if (++ntimeouts >= relinqAll) {
	    Memory::releaseMemory(); // Try releasing memory
	    Table::relinquishAutoLocks (True);
	    ntimeouts = 0;
	  }else{
	    Table::relinquishAutoLocks (False);
	  }
	  // Send our memory use to Glish
	  Double memuse = Memory::assignedMemoryInBytes();
	  memuse /= 1024.0*1024.0;
	  eventStream.postEvent("_memory", GlishArray(memuse));
	  withTimeout =  (Table::nAutoLocks() > 0);
	}else{

	  // There is an event.
	  // This may result in acquiring an autolock, so reset
	  // the timeout variables.
	  ntimeouts = 0;
	  withTimeout = True;
	  message = "";
	  if (event.type() == "open") {
	    ok = proxy.open (event, eventStream, message);
	  } else if (event.type() == "open_update") {
	    ok = proxy.openUpdate (event, eventStream, message);
	  } else if (event.type() == "create") {
	    ok = proxy.create (event, eventStream, message);
	  } else if (event.type() == "command") {
	    ok = proxy.command (event, eventStream, message);
	  } else if (event.type() == "select_rows") {
	    ok = proxy.selectRows (event, eventStream, message);
	  } else if (event.type() == "flush") {
	    ok = proxy.flush (event, eventStream, message);
	  } else if (event.type() == "resync") {
	    ok = proxy.resync (event, eventStream, message);
	  } else if (event.type() == "close") {
	    ok = proxy.close (event, eventStream, message);
	  } else if (event.type() == "close_all") {
	    ok = proxy.closeAll (event, eventStream, message);
	  } else if (event.type() == "endian_format") {
	    ok = proxy.endianFormat (event, eventStream, message);
	  } else if (event.type() == "lock") {
	    ok = proxy.lock(event, eventStream, message);
	  } else if (event.type() == "unlock") {
	    ok = proxy.unlock (event, eventStream, message);
	  } else if (event.type() == "has_data_changed") {
	    ok = proxy.hasDataChanged (event, eventStream, message);
	  } else if (event.type() == "has_lock") {
	    ok = proxy.hasLock (event, eventStream, message);
	  } else if (event.type() == "lock_options") {
	    ok = proxy.lockOptions (event, eventStream, message);
	  } else if (event.type() == "is_multi_used") {
	    ok = proxy.isMultiUsed (event, eventStream, message);
	  } else if (event.type() == "copy") {
	    ok = proxy.copy (event, eventStream, message);
	  } else if (event.type() == "copy_rows") {
	    ok = proxy.copyRows (event, eventStream, message);
	  } else if (event.type() == "rename") {
	    ok = proxy.rename (event, eventStream, message);
	  } else if (event.type() == "delete") {
	    ok = proxy.deleteTable (event, eventStream, message);
	  } else if (event.type() == "read_ascii") {
	    ok = proxy.readAscii (event, eventStream, message);
	  } else if (event.type() == "get_open_tables") {
	    ok = proxy.getOpenTables (event, eventStream, message);
	  } else if (event.type() == "get_name") {
	    ok = proxy.getName (event, eventStream, message);
	  } else if (event.type() == "get_id") {
	    ok = proxy.getId (event, eventStream, message);
	  } else if (event.type() == "is_readable") {
	    ok = proxy.isReadable (event, eventStream, message);
	  } else if (event.type() == "is_writable") {
	    ok = proxy.isWritable (event, eventStream, message);
	  } else if (event.type() == "table_info") {
	    ok = proxy.tableInfo (event, eventStream, message);
	  } else if (event.type() == "put_table_info") {
	    ok = proxy.putTableInfo (event, eventStream, message);
	  } else if (event.type() == "add_readme_line") {
	    ok = proxy.addReadmeLine (event, eventStream, message);
	  } else if (event.type() == "add_columns") {
	    ok = proxy.addColumns (event, eventStream, message);
	  } else if (event.type() == "rename_column") {
	    ok = proxy.renameColumn (event, eventStream, message);
	  } else if (event.type() == "remove_columns") {
	    ok = proxy.removeColumns (event, eventStream, message);
	  } else if (event.type() == "extend") {
	    ok = proxy.addRow (event, eventStream, message);
	  } else if (event.type() == "remove_row") {
	    ok = proxy.removeRow (event, eventStream, message);
	  } else if (event.type() == "set_max_cache_size") {
	    ok = proxy.setMaximumCacheSize (event, eventStream, message);
	  } else if (event.type() == "cell_contents_defined") {
	    ok = proxy.cellContentsDefined (event, eventStream, message);
	  } else if (event.type() == "get_cell") {
	    ok = proxy.getCell (event, eventStream, message);
	  } else if (event.type() == "get_cell_slice") {
	    ok = proxy.getCellSlice (event, eventStream, message);
	  } else if (event.type() == "put_cell") {
	    ok = proxy.putCell (event, eventStream, message);
	  } else if (event.type() == "put_cell_slice") {
	    ok = proxy.putCellSlice (event, eventStream, message);
	  } else if (event.type() == "get_column") {
	    ok = proxy.getColumn (event, eventStream, message);
	  } else if (event.type() == "get_var_column") {
	    ok = proxy.getVarColumn (event, eventStream, message);
	  } else if (event.type() == "get_column_slice") {
	    ok = proxy.getColumnSlice (event, eventStream, message);
	  } else if (event.type() == "put_column") {
	    ok = proxy.putColumn (event, eventStream, message);
	  } else if (event.type() == "put_var_column") {
	    ok = proxy.putVarColumn (event, eventStream, message);
	  } else if (event.type() == "put_column_slice") {
	    ok = proxy.putColumnSlice (event, eventStream, message);
	  } else if (event.type() == "get_column_shape_string") {
	    ok = proxy.getColumnShapeString (event, eventStream, message);
	  } else if (event.type() == "get_keyword") {
	    ok = proxy.getKeyword (event, eventStream, message);
	  } else if (event.type() == "get_keywordset") {
	    ok = proxy.getKeywordSet (event, eventStream, message);
	  } else if (event.type() == "put_keyword") {
	    ok = proxy.putKeyword (event, eventStream, message);
	  } else if (event.type() == "put_keywordset") {
	    ok = proxy.putKeywordSet (event, eventStream, message);
	  } else if (event.type() == "remove_keyword") {
	    ok = proxy.removeKeyword (event, eventStream, message);
	  } else if (event.type() == "get_fieldnames") {
	    ok = proxy.getFieldNames (event, eventStream, message);
	  } else if (event.type() == "get_table_desc") {
	    ok = proxy.getTableDescription (event, eventStream, message);
	  } else if (event.type() == "get_dm_info") {
	    ok = proxy.getDataManagerInfo (event, eventStream, message);
	  } else if (event.type() == "get_column_desc") {
	    ok = proxy.getColumnDescription (event, eventStream, message);
	  } else if (event.type() == "shape") {
	    ok = proxy.shape (event, eventStream, message);
	  } else if (event.type() == "row_numbers") {
	    ok = proxy.rowNumbers (event, eventStream, message);
	  } else if (event.type() == "column_names") {
	    ok = proxy.columnNames (event, eventStream, message);
	  } else if (event.type() == "is_scalar_column") {
	    ok = proxy.isScalarColumn (event, eventStream, message);
	  } else if (event.type() == "column_data_type") {
	    ok = proxy.columnDataType (event, eventStream, message);
	  } else if (event.type() == "column_array_type") {
	    ok = proxy.columnArrayType (event, eventStream, message);
	  } else if (event.type() == "make_iterator") {
	    ok = proxy.makeIterator (event, eventStream, message);
	  } else if (event.type() == "step_iterator") {
	    ok = proxy.stepIterator (event, eventStream, message);
	  } else if (event.type() == "close_iterator") {
	    ok = proxy.closeIterator (event, eventStream, message);
	  } else if (event.type() == "make_row") {
	    ok = proxy.makeRow (event, eventStream, message);
	  } else if (event.type() == "get_row") {
	    ok = proxy.getRow (event, eventStream, message);
	  } else if (event.type() == "put_row") {
	    ok = proxy.putRow (event, eventStream, message);
	  } else if (event.type() == "close_row") {
	    ok = proxy.closeRow (event, eventStream, message);
	  } else if (event.type() == "make_index") {
	    ok = proxy.makeIndex (event, eventStream, message);
	  } else if (event.type() == "index_isunique") {
	    ok = proxy.indexIsUnique (event, eventStream, message);
	  } else if (event.type() == "index_setchanged") {
	    ok = proxy.indexSetChanged (event, eventStream, message);
	  } else if (event.type() == "index_getrownumber") {
	    ok = proxy.indexGetRowNumber (event, eventStream, message);
	  } else if (event.type() == "index_getrownumbers") {
	    ok = proxy.indexGetRowNumbers (event, eventStream, message);
	  } else if (event.type() == "close_index") {
	    ok = proxy.closeIndex (event, eventStream, message);
	  } else if (event.type() != "terminate") {
	    // We don't understand what this event is!
	    eventStream.unrecognized();
	  }
	}
      } catch (AipsError x) {
	// We don't handle any exception; return them as an error
	message = x.getMesg();
	ok = False;
      } 
      if (!ok) {
	GlishRecord rec;
	rec.add ("error_message", event.type() + ": " + message);
	eventStream.postEvent (GlishTableProxy::returnEventName (event),
			       rec);
      }
    }
    return 0;
}
