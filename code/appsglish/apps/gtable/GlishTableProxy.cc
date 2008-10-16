//# GlishTableProxy.cc: Glish interface to tables
//# Copyright (C) 1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004
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
//# $Id: GlishTableProxy.cc,v 19.15 2006/09/19 06:41:55 gvandiep Exp $


#include <GlishTableProxy.h>
#include <tables/Tables/TableProxy.h>
#include <tables/Tables/PlainTable.h>
#include <tables/Tables/TableCache.h>
#include <tables/Tables/TableError.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Containers/ValueHolder.h>
#include <casa/OS/Path.h>

#include <casa/namespace.h>

GlishTableProxy::GlishTableProxy()
{}

GlishTableProxy::~GlishTableProxy()
{}

//# Add table object to the block.
//# If the table name already exists, close it and clear its name.
//# This can only happen in case of a table created by tableCommand
//# or selectRows.
Int GlishTableProxy::addTable (TableProxy& tablep)
{
  Int ntables = tables_p.size();
  if (! tablep.table().isNull()) {
    const String& name = tablep.table().tableName();
    if (! name.empty()) {
      for (Int i=0; i<ntables; i++) {
	if (tables_p[i].tableName() == name) {
	  tables_p[i].close();
	  tables_p[i].clearName();
	}
      }
    }
  }
  tables_p.push_back (GlishTableHolder (tablep));
  return ntables;
}

String GlishTableProxy::returnEventName (const GlishSysEvent& event)
{
  return event.type() + "_result";
}


Bool GlishTableProxy::validTableName (const String& name, String& message,
				      Bool canBeOpen, Int& id)
{
  id = -1;
  if (name.empty()) {
    message = "Blank table name given";
    return False;
  }
  String absName = Path(name).absoluteName();
  for (uInt i=0; i<tables_p.size(); i++) {
    if (absName == tables_p[i].tableName()) {
      if (canBeOpen) {
	id = i;
	return True;
      }
      if (tables_p[i].isOpen() > 0) {
	message = "Table " + name + " already open; maybe close it first";
	return False;
      }else{
	tables_p[i].clearName();
      }
    }
  }
  return True;
}

Bool GlishTableProxy::validTableId (Int id, String& message,
				    Bool toPut, Bool reopen)
{
  if (id < 0  ||  uInt(id) >= tables_p.size()
  ||  (tables_p[id].isNull() && tables_p[id].tableName().empty())) {
    message = "Illegal table-id sent (no such table)";
    return False;
  }
  Int mode = tables_p[id].isOpen();
  //# Check if a put is possible.
  if (toPut) {
    if (mode != 2  &&  mode != -2) {
      message = "Put is not possible for this table";
      return False;
    }
  }
  //# Reopen the table when it was closed.
  if (reopen) {
    if (mode <= 0) {
      if (tables_p[id].tableName().empty()) {
	message = "Cannot reopen table with a blank name";
	return False;
      }
      Table table;
      if (mode == -1) {
	table = Table(tables_p[id].tableName());
      }else{
	table = Table(tables_p[id].tableName(), Table::Update);
      }
      tables_p[id] = GlishTableHolder (table);
    }
  }
  return True;
}

void GlishTableProxy::closeTable (Int tableId)
{
  // Close the table.
  // Close the rows and indices using this table (otherwise they refer to it).
  tables_p[tableId].close();
  for (uInt i=0; i<rows_p.size(); i++) {
    if (rows_p[i].tableId() == tableId) {
      rows_p[i] = GlishTableRowHolder();
    }
  }
  for (uInt i=0; i<indices_p.size(); i++) {
    if (indices_p[i].tableId() == tableId) {
      indices_p[i] = GlishTableIndexHolder();
    }
  }
}

String GlishTableProxy::recombineString (const GlishArray& value) const
{
  //# For one reason or another Glish sometimes splits up the string.
  //# So combine it back.
  String str;
  if (value.nelements() > 0) {
    Vector<String> vec (value.nelements());
    value.get (vec);
    for (uInt i=0; i<vec.nelements(); i++) {
      if (i > 0) {
	str += " ";
      }
      str += vec(i);
    }
  }
  return str;
}

Record GlishTableProxy::getLockOptions (const GlishRecord& rec)
{
  GlishRecord options (rec.get("lockOptions"));
  Record optRec;
  options.toRecord (optRec);
  return optRec;
}


Bool GlishTableProxy::open (GlishSysEvent& event,
			    GlishSysEventSource& eventStream,
			    String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableName"))
  ||  (! GlishRecord(event.val()).exists("lockOptions"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab (event.val());
  String tableName;
  GlishArray(gtab.get("tableName")).get(tableName);
  // Check if the name is valid and if the table is already open.
  Int id;
  if (! validTableName (tableName, message, True, id)) {
    return False;
  }
  // Get the lock options.
  Record lockOptions = getLockOptions (gtab);
  // The table is not open yet, so open it.
  if (id < 0) {
    TableProxy tab(tableName, lockOptions, Table::Old);
    // Open succeeded; add table to the block.
    // Just return the sequence number to the remote user
    id = addTable (tab);
  }
  eventStream.postEvent (returnEventName(event), GlishArray(id));
  return True;
}

Bool GlishTableProxy::openUpdate (GlishSysEvent& event,
				  GlishSysEventSource& eventStream,
				  String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableName"))
  ||  (! GlishRecord(event.val()).exists("lockOptions"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab (event.val());
  String tableName;
  GlishArray(gtab.get("tableName")).get(tableName);
  // Check if the name is valid and if the table is already open.
  Int id;
  if (! validTableName (tableName, message, True, id)) {
    return False;
  }
  // Check if the table is writable.
  if (! Table::isWritable (tableName)) {
    message = "Table " + tableName + " is not writable";
    return False;
  }
  // Get the lock options.
  Record lockOptions = getLockOptions (gtab);
  // If the table is already open, reopen for read/write if needed.
  // Otherwise open the table.
  if (id >= 0) {
    tables_p[id].reopenRW();
  }else{
    TableProxy tab(tableName, lockOptions, Table::Update);
    // Open succeeded; add table to the block.
    // Just return the sequence number to the remote user
    id = addTable (tab);
  }
  eventStream.postEvent (returnEventName(event), GlishArray(id));
  return True;
}

Bool GlishTableProxy::create (GlishSysEvent& event,
			      GlishSysEventSource& eventStream,
			      String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableName"))
  ||  (! GlishRecord(event.val()).exists("lockOptions"))
  ||  (! GlishRecord(event.val()).exists("endianFormat"))
  ||  (! GlishRecord(event.val()).exists("memtype"))
  ||  (! GlishRecord(event.val()).exists("tableDesc"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab (event.val());
  String tableName;
  GlishArray(gtab.get("tableName")).get(tableName);
  Int id;
  if (! validTableName (tableName, message, False, id)) {
    return False;
  }
  // Get the lock options.
  Record lockOptions = getLockOptions (gtab);
  // Get the endian option.
  String endianFormat;
  GlishArray(gtab.get("endianFormat")).get(endianFormat);
  // Get the type.
  String typstr;
  GlishArray(gtab.get("memtype")).get(typstr);
  Int nrow = 0;
  if (gtab.exists("nrow")) {
    GlishArray(gtab.get("nrow")).get(nrow);
  }
  if (nrow < 0) {
    nrow = 0;
  }
  GlishRecord gdesc (gtab.get("tableDesc"));
  Record tableDesc;
  gdesc.toRecord (tableDesc);
  // Get a possible dminfo object.
  Record dminfo;
  if (gtab.exists("dminfo")) {
    GlishRecord gdminfo (gtab.get("dminfo"));
    gdminfo.toRecord (dminfo);
  }
  // Create the table.
  TableProxy tab(tableName, lockOptions, endianFormat, typstr,
		 nrow, tableDesc, dminfo);
  // Open succeeded; add table to the block.
  // Just return the sequence number to the remote user
  id = addTable (tab);
  eventStream.postEvent (returnEventName(event), GlishArray(id));
  return True;
}

Bool GlishTableProxy::endianFormat (GlishSysEvent& event,
				    GlishSysEventSource& eventStream,
				    String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  // Return the endian format as a string.
  String str = tables_p[id].proxy().endianFormat();
  eventStream.postEvent (returnEventName(event), GlishArray(str));
  return True;
}

Bool GlishTableProxy::lock (GlishSysEvent& event,
			    GlishSysEventSource& eventStream,
			    String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("mode"))
  ||  (! GlishRecord(event.val()).exists("nattempts"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  Bool mode;
  GlishArray(location.get("mode")).get(mode);
  Int nattempts;
  GlishArray(location.get("nattempts")).get(nattempts);
  tables_p[id].proxy().lock (mode, nattempts);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::unlock (GlishSysEvent& event,
			      GlishSysEventSource& eventStream,
			      String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  tables_p[id].proxy().unlock();
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::hasDataChanged (GlishSysEvent& event,
				      GlishSysEventSource& eventStream,
				      String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  Bool flag = tables_p[id].proxy().hasDataChanged();
  eventStream.postEvent (returnEventName(event), GlishArray(flag));
  return True;
}

Bool GlishTableProxy::hasLock (GlishSysEvent& event,
			       GlishSysEventSource& eventStream,
			       String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("mode"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  Bool mode;
  GlishArray(location.get("mode")).get(mode);
  Bool haslock = tables_p[id].proxy().hasLock (mode);
  eventStream.postEvent (returnEventName(event), GlishArray(haslock));
  return True;
}

Bool GlishTableProxy::lockOptions (GlishSysEvent& event,
				   GlishSysEventSource& eventStream,
				   String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  // Return the lock options as a Glish record.
  GlishRecord rec;
  rec.fromRecord (tables_p[id].proxy().lockOptions());
  eventStream.postEvent (returnEventName(event), rec);
  return True;
}

Bool GlishTableProxy::isMultiUsed (GlishSysEvent& event,
				   GlishSysEventSource& eventStream,
				   String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("checkSubTables"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  Bool checkSubTables;
  GlishArray(location.get("checkSubTables")).get(checkSubTables);
  Bool flag = tables_p[id].proxy().isMultiUsed (checkSubTables);
  eventStream.postEvent (returnEventName(event), GlishArray(flag));
  return True;
}

Bool GlishTableProxy::rename (GlishSysEvent& event,
			      GlishSysEventSource& eventStream,
			      String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableName"))
  ||  (! GlishRecord(event.val()).exists("newTableName"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab (event.val());
  String tableName;
  GlishArray(gtab.get("tableName")).get(tableName);
  Int id, tabid;
  if (! validTableName (tableName, message, True, tabid)) {
    return False;
  }
  if (! Table::isWritable(tableName)) {
    message = tableName + " cannot be renamed (is not writable)";
    return False;
  }

  String newTableName;
  GlishArray(gtab.get("newTableName")).get(newTableName);
  if (! validTableName (newTableName, message, False, id)) {
    return False;
  }

  // An already opened table is not valid anymore.
  if (tabid >= 0) {
    tables_p[tabid].close();
    tables_p[tabid].clearName();
  }
  Table table(tableName, Table::Update);
  Bool renamed = True;
  try {
    table.rename(newTableName, Table::New);
  } catch (AipsError x) {
    renamed = False;
    message = "Rename " + tableName + " failed: " + x.getMesg();
  } 
  if (!renamed) {
    return False;
  }

  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::copy (GlishSysEvent& event,
			    GlishSysEventSource& eventStream,
			    String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("newTableName"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab (event.val());
  TableProxy table;
  Int id;
  if (gtab.exists("tableId")) {
    GlishArray(gtab.get("tableId")).get(id);
    if (! validTableId (id, message, False, False)) {
      return False;
    }
    table = tables_p[id].proxy();
  }else{
    String name;
    GlishArray(gtab.get("tableName")).get(name);
    if (! validTableName (name, message, True, id)) {
      return False;
    }
    if (! Table::isReadable(name)) {
      message = name + " does not exist";
      return False;
    }
    table = TableProxy(Table(name));
  }
  String newTableName;
  GlishArray(gtab.get("newTableName")).get(newTableName);
  if (! validTableName (newTableName, message, False, id)) {
    return False;
  }
  Bool deep = False;
  if (gtab.exists("deepCopy")) {
    GlishArray(gtab.get("deepCopy")).get(deep);
  }
  Bool valueCopy = False;
  if (gtab.exists("valueCopy")) {
    GlishArray(gtab.get("valueCopy")).get(valueCopy);
  }
  // Get a possible dminfo object.
  // Always copy if dminfo is not empty.
  Record dminfo;
  if (gtab.exists("dminfo")) {
    GlishRecord gdminfo (gtab.get("dminfo"));
    gdminfo.toRecord (dminfo);
  }
  // Get the endian option.
  String endianFormat;
  if (gtab.exists("endianFormat")) {
    GlishArray(gtab.get("endianFormat")).get(endianFormat);
  }
  // Get the type.
  Bool toMemory = False;
  if (gtab.exists("memtype")) {
    String typstr;
    GlishArray(gtab.get("memtype")).get(typstr);
    toMemory = (typstr == "memory");
  }
  // Determine if rows have to be copied.
  Bool noRows = False;
  if (gtab.exists("noRows")) {
    GlishArray(gtab.get("noRows")).get(noRows);
  }
  // Do we have to return a handle?
  // We sure do if the copy is made to a memory table.
  Bool returnHandle = toMemory;
  if (!returnHandle) {
    if (gtab.exists("returnHandle")) {
      GlishArray(gtab.get("returnHandle")).get(returnHandle);
    }
  }

  Bool copied = True;
  int outid = -1;
  try {
    TableProxy out = table.copy (newTableName, toMemory, deep, valueCopy,
				 endianFormat, dminfo, noRows);
    if (returnHandle) {
      outid = addTable (out);
    }
  } catch (AipsError x) {
    copied = False;
    if (deep) {
      message = "DeepCopy of ";
    } else {
      message = "Copy of ";
    }
    message += table.table().tableName() + " failed: " + x.getMesg();
  } 
  if (!copied) {
    return False;
  }
  eventStream.postEvent (returnEventName(event), GlishArray(outid));
  return True;
}

Bool GlishTableProxy::copyRows (GlishSysEvent& event,
				GlishSysEventSource& eventStream,
				String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableIdIn"))
  ||  (! GlishRecord(event.val()).exists("tableIdOut"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab (event.val());
  Int idIn;
  GlishArray(gtab.get("tableIdIn")).get(idIn);
  if (! validTableId (idIn, message, False, False)) {
    return False;
  }
  TableProxy& tableIn = tables_p[idIn].proxy();
  Int idOut;
  GlishArray(gtab.get("tableIdOut")).get(idOut);
  if (! validTableId (idOut, message, True)) {
    return False;
  }
  TableProxy& tableOut = tables_p[idOut].proxy();
  Int stin;
  Int nrow;
  Int stout;
  GlishArray(gtab.get("rowIn")).get(stin);
  GlishArray(gtab.get("nrow")).get(nrow);
  GlishArray(gtab.get("rowOut")).get(stout);
  tableIn.copyRows (tableOut, stin, stout, nrow);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::deleteTable (GlishSysEvent& event,
				   GlishSysEventSource& eventStream,
				   String& message)
{
  if (event.val().type() != GlishValue::RECORD) {
    message = "No record sent";
    return False;
  }
  GlishRecord rec(event.val());
  Bool checkSubTables;
  GlishArray(rec.get("checkSubTables")).get(checkSubTables);
  Int id;
  Bool found = False;
  if (rec.exists("tableId")) {
    found = True;
    GlishArray(rec.get("tableId")).get(id);
  }else{
    String name;
    GlishArray(rec.get("tableName")).get(name);
    if (name.empty()) {
      message = "No table name given on delete";
      return False;
    }
    name = Path(name).absoluteName();
    for (id=0; uInt(id)<tables_p.size(); id++) {
      if (tables_p[id].tableName() == name) {
	found = True;
	break;
      }
    }
    // If not in use here, delete it explicitly.
    if (!found) {
      Table::deleteTable (name, checkSubTables);
    }
  }
  if (found) {
    if (! validTableId (id, message, True)) {
      return False;
    }
    tables_p[id].proxy().deleteTable (checkSubTables);
    closeTable (id);
  }
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::readAscii (GlishSysEvent& event,
			         GlishSysEventSource& eventStream,
                                 String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("fileName"))
  ||  (! GlishRecord(event.val()).exists("tableName"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab (event.val());
  String fileName;
  String tableName;
  String hdrName;
  Bool autoHeader;
  Vector<Int> autoShape;
  String separator;
  String commentMarker;
  Int firstLine, lastLine;
  GlishArray(gtab.get("fileName")).get(fileName);
  GlishArray(gtab.get("tableName")).get(tableName);
  GlishArray(gtab.get("headerName")).get(hdrName);
  GlishArray(gtab.get("autoHeader")).get(autoHeader);
  GlishArray(gtab.get("autoShape")).get(autoShape);
  GlishArray(gtab.get("separator")).get(separator);
  GlishArray(gtab.get("commentMarker")).get(commentMarker);
  GlishArray(gtab.get("firstLine")).get(firstLine);
  GlishArray(gtab.get("lastLine")).get(lastLine);
  TableProxy tab(fileName, hdrName, tableName,
		 autoHeader, autoShape,
		 separator, commentMarker,
		 firstLine, lastLine);
  String inputFormat = tab.getAsciiFormat();
  eventStream.postEvent (returnEventName(event), GlishArray(inputFormat));
  return True;
}

Bool GlishTableProxy::selectRows (GlishSysEvent& event,
				  GlishSysEventSource& eventStream,
				  String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("rowNumbers"))
  ||  (! GlishRecord(event.val()).exists("tableName"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab (event.val());
  Int id;
  Array<Int> rownrs;
  String tableName;
  GlishArray(gtab.get("tableId")).get(id);
  GlishArray(gtab.get("rowNumbers")).get(rownrs);
  GlishArray(gtab.get("tableName")).get(tableName);
  if (! validTableId (id, message)) {
    return False;
  }
  TableProxy& table = tables_p[id].proxy();
  TableProxy ntable = table.selectRows (rownrsFromGlish(rownrs), tableName);
  // Command succeeded; add table.
  id = addTable (ntable);
  // Just return the sequence number and file name
  // to the remote user
  GlishRecord rec;
  rec.add ("tableId", id);
  rec.add ("tableName", tables_p[id].tableName());
  eventStream.postEvent (returnEventName(event), rec);
  return True;
}

Bool GlishTableProxy::command (GlishSysEvent& event,
			       GlishSysEventSource& eventStream,
			       String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("command"))
  ||  (! GlishRecord(event.val()).exists("tableIds"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab (event.val());
  String command (recombineString (gtab.get("command")));
  Vector<Int> ids;
  GlishArray(gtab.get("tableIds")).get(ids);
  std::vector<TableProxy> tables(ids.nelements());
  for (uInt i=0; i<ids.nelements(); i++) {
    if (! validTableId (ids(i), message)) {
      return False;
    }
    tables[i] = tables_p[ids(i)].proxy();
  }
  // Try to execute the command.
  TableProxy ntable(command, tables);
  Record result = ntable.getCalcResult();
  GlishRecord rec;
  rec.fromRecord (result);
  // Command succeeded.
  // Add table if result is a table.
  if (! ntable.table().isNull()) {
    Int id = addTable (ntable);
    // Just return the sequence number and file name
    // to the remote user
    rec.add ("tableId", id);
    rec.add ("tableName", tables_p[id].tableName());
    rec.add ("values", GlishArray(False));
  } else {
    // Result is a calculation. Insert the other fields.
    rec.add ("tableId", GlishArray(False));
    rec.add ("tableName", False);
  }
  eventStream.postEvent (returnEventName(event), rec);
  return True;
}

Bool GlishTableProxy::getDataManagerInfo (GlishSysEvent& event,
					  GlishSysEventSource& eventStream,
					  String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "event value not a record, or has no tableId field";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  // Return the info as a Glish record.
  GlishRecord grec;
  grec.fromRecord (tables_p[id].proxy().getDataManagerInfo());
  eventStream.postEvent (returnEventName(event), grec);
  return True;
}

Bool GlishTableProxy::getTableDescription (GlishSysEvent& event,
			                   GlishSysEventSource& eventStream,
                                           String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("actual"))) {
    message = "event value not a record, or has no tableId/actual fields";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  Bool actual;
  GlishArray(location.get("actual")).get(actual);
  // Return the table description as a Glish record.
  GlishRecord gdesc;
  gdesc.fromRecord (tables_p[id].proxy().getTableDescription(actual));
  eventStream.postEvent (returnEventName(event), gdesc);
  return True;
}

Bool GlishTableProxy::getColumnDescription (GlishSysEvent& event,
			                    GlishSysEventSource& eventStream,
			                    String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "event value not a record, or has no tableId field";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  String columnName;
  GlishArray(location.get("column")).get(columnName);
  Bool actual;
  GlishArray(location.get("actual")).get(actual);
  // Return the column description as a Glish record.
  GlishRecord gdesc;
  gdesc.fromRecord (tables_p[id].proxy().getColumnDescription(columnName,
							      actual));
  eventStream.postEvent (returnEventName(event), gdesc);
  return True;
}

Bool GlishTableProxy::shape (GlishSysEvent& event,
			     GlishSysEventSource& eventStream,
			     String& message)
{
  if (event.val().type() != GlishValue::ARRAY
  ||  GlishArray(event.val()).elementType() == GlishArray::STRING) {
    message = "Non-numeric table-id sent";
    return False;
  }
  Int id;
  GlishArray(event.val()).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  TableProxy& table = tables_p[id].proxy();
  eventStream.postEvent (returnEventName(event), table.shape());
  return True;
}

Bool GlishTableProxy::rowNumbers (GlishSysEvent& event,
				  GlishSysEventSource& eventStream,
				  String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("tableId2"))) {
    message = "event value not a record, or has no tableId/tableId2 field";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  TableProxy& table = tables_p[id].proxy();
  TableProxy tab2;
  Int id2;
  GlishArray(location.get("tableId2")).get(id2);
  if (id2 >= 0) {
    if (! validTableId (id2, message)) {
      return False;
    }
    tab2 = tables_p[id].proxy();
  }
  eventStream.postEvent (returnEventName(event),
			 rownrsToGlish(table.rowNumbers(tab2)));
  return True;
}

Bool GlishTableProxy::columnNames (GlishSysEvent& event,
				   GlishSysEventSource& eventStream,
				   String& message)
{
  if (event.val().type() != GlishValue::ARRAY
  ||  GlishArray(event.val()).elementType() == GlishArray::STRING) {
    message = "Non-numeric table-id sent";
    return False;
  }
  Int id;
  GlishArray(event.val()).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  eventStream.postEvent (returnEventName(event),
			 tables_p[id].proxy().columnNames());
  return True;
}

Bool GlishTableProxy::setMaximumCacheSize (GlishSysEvent& event,
					   GlishSysEventSource& eventStream,
					   String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("nbytes"))
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, False)) {
    return False;
  }
  String columnName;
  GlishArray (location.get("column")).get(columnName);
  Int nbytes;
  GlishArray (location.get("nbytes")).get(nbytes);
  tables_p[id].proxy().setMaximumCacheSize (columnName, nbytes);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::isScalarColumn (GlishSysEvent& event,
                                      GlishSysEventSource& eventStream,
                                      String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, False)) {
    return False;
  }
  String columnName;
  GlishArray (location.get("column")).get(columnName);
  Bool isScalar = tables_p[id].proxy().isScalarColumn (columnName);
  eventStream.postEvent (returnEventName(event), GlishArray(isScalar));
  return True;
}

Bool GlishTableProxy::columnDataType (GlishSysEvent& event,
                                      GlishSysEventSource& eventStream,
                                      String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, False)) {
    return False;
  }
  String columnName;
  GlishArray (location.get("column")).get(columnName);
  eventStream.postEvent (returnEventName(event),
			 tables_p[id].proxy().columnDataType (columnName));
  return True;
}

Bool GlishTableProxy::columnArrayType (GlishSysEvent& event,
				       GlishSysEventSource& eventStream,
                                       String& message)

{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, False)) {
    return False;
  }
  String columnName;
  GlishArray (location.get("column")).get(columnName);
  eventStream.postEvent (returnEventName(event),
			 tables_p[id].proxy().columnArrayType (columnName));
  return True;
}

Bool GlishTableProxy::getColumn (GlishSysEvent& event,
				 GlishSysEventSource& eventStream,
				 String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("row"))
  ||  (! GlishRecord(event.val()).exists("nrow"))
  ||  (! GlishRecord(event.val()).exists("rowincr"))
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, False)) {
    return False;
  }
  String column;
  GlishArray(location.get("column")).get(column);
  Int row, nrow, incr;
  GlishArray(location.get("row")).get(row);
  GlishArray(location.get("nrow")).get(nrow);
  GlishArray(location.get("rowincr")).get(incr);
  eventStream.postEvent (returnEventName(event),
			 valueToGlish(tables_p[id].proxy().getColumn
				      (column, row, nrow, incr)));
  return True;
}

Bool GlishTableProxy::getVarColumn (GlishSysEvent& event,
				    GlishSysEventSource& eventStream,
				    String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("row"))
  ||  (! GlishRecord(event.val()).exists("nrow"))
  ||  (! GlishRecord(event.val()).exists("rowincr"))
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, False)) {
    return False;
  }
  String column;
  GlishArray(location.get("column")).get(column);
  Int row, nrow, incr;
  GlishArray(location.get("row")).get(row);
  GlishArray(location.get("nrow")).get(nrow);
  GlishArray(location.get("rowincr")).get(incr);
  GlishRecord grec;
  grec.fromRecord (tables_p[id].proxy().getVarColumn (column, row,nrow,incr));
  eventStream.postEvent (returnEventName(event), grec);
  return True;
}

Bool GlishTableProxy::getColumnSlice (GlishSysEvent& event,
				      GlishSysEventSource& eventStream,
				      String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("blc"))
  ||  (! GlishRecord(event.val()).exists("trc"))
  ||  (! GlishRecord(event.val()).exists("row"))
  ||  (! GlishRecord(event.val()).exists("nrow"))
  ||  (! GlishRecord(event.val()).exists("rowincr"))
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, False)) {
    return False;
  }
  String column;
  GlishArray(location.get("column")).get(column);
  Int row, nrow, incr;
  GlishArray(location.get("row")).get(row);
  GlishArray(location.get("nrow")).get(nrow);
  GlishArray(location.get("rowincr")).get(incr);
  Vector<Int> blc, trc, inc;
  GlishArray (location.get("blc")).get(blc);
  GlishArray (location.get("trc")).get(trc);
  if (location.exists("inc")) {
    GlishArray (location.get("inc")).get(inc);
  }
  eventStream.postEvent (returnEventName(event),
			 valueToGlish(tables_p[id].proxy().getColumnSlice
				      (column, blc, trc, inc,
				       row, nrow, incr)));
  return True;
}

Bool GlishTableProxy::putColumn (GlishSysEvent& event,
				 GlishSysEventSource& eventStream,
				 String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("row"))
  ||  (! GlishRecord(event.val()).exists("nrow"))
  ||  (! GlishRecord(event.val()).exists("rowincr"))
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("value"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, True)) {
    return False;
  }
  String column;
  GlishArray(location.get("column")).get(column);
  Int row, nrow, incr;
  GlishArray(location.get("row")).get(row);
  GlishArray(location.get("nrow")).get(nrow);
  GlishArray(location.get("rowincr")).get(incr);
  GlishValue value = location.get("value");
  ValueHolder vh = valueFromGlish(value);
  tables_p[id].proxy().putColumn (column, vh, row, nrow, incr);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::putVarColumn (GlishSysEvent& event,
				    GlishSysEventSource& eventStream,
				    String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("row"))
  ||  (! GlishRecord(event.val()).exists("nrow"))
  ||  (! GlishRecord(event.val()).exists("rowincr"))
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("value"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, True)) {
    return False;
  }
  String column;
  GlishArray(location.get("column")).get(column);
  Int row, nrow, incr;
  GlishArray(location.get("row")).get(row);
  GlishArray(location.get("nrow")).get(nrow);
  GlishArray(location.get("rowincr")).get(incr);
  GlishRecord value (location.get("value"));
  Record rec;
  value.toRecord (rec);
  tables_p[id].proxy().putVarColumn (column, rec, row, nrow, incr);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::putColumnSlice (GlishSysEvent& event,
				      GlishSysEventSource& eventStream,
				      String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("blc"))
  ||  (! GlishRecord(event.val()).exists("trc"))
  ||  (! GlishRecord(event.val()).exists("row"))
  ||  (! GlishRecord(event.val()).exists("nrow"))
  ||  (! GlishRecord(event.val()).exists("rowincr"))
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("value"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, True)) {
    return False;
  }
  String column;
  GlishArray(location.get("column")).get(column);
  Int row, nrow, incr;
  GlishArray(location.get("row")).get(row);
  GlishArray(location.get("nrow")).get(nrow);
  GlishArray(location.get("rowincr")).get(incr);
  Vector<Int> blc, trc, inc;
  GlishArray (location.get("blc")).get(blc);
  GlishArray (location.get("trc")).get(trc);
  if (location.exists("inc")) {
    GlishArray (location.get("inc")).get(inc);
  }
  GlishValue value = location.get("value");
  ValueHolder vh = valueFromGlish(value);
  tables_p[id].proxy().putColumnSlice (column, vh, blc, trc, inc,
				       row, nrow, incr);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::getCell (GlishSysEvent& event,
			       GlishSysEventSource& eventStream,
			       String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("row"))
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, False)) {
    return False;
  }
  String column;
  GlishArray (location.get("column")).get(column);
  Int rownr;
  GlishArray (location.get("row")).get(rownr);
  eventStream.postEvent (returnEventName(event),
			 valueToGlish(tables_p[id].proxy().getCell
				      (column, rownr)));
  return True;
}

Bool GlishTableProxy::getCellSlice (GlishSysEvent& event,
				    GlishSysEventSource& eventStream,
				    String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("row"))
  ||  (! GlishRecord(event.val()).exists("blc"))
  ||  (! GlishRecord(event.val()).exists("trc"))
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, False)) {
    return False;
  }
  String column;
  GlishArray (location.get("column")).get(column);
  Int rownr;
  GlishArray (location.get("row")).get(rownr);
  Vector<Int> blc, trc, inc;
  GlishArray (location.get("blc")).get(blc);
  GlishArray (location.get("trc")).get(trc);
  if (location.exists("inc")) {
    GlishArray (location.get("inc")).get(inc);
  }
  eventStream.postEvent (returnEventName(event),
			 valueToGlish(tables_p[id].proxy().getCellSlice
				      (column, rownr, blc, trc, inc)));
  return True;
}

Bool GlishTableProxy::putCell (GlishSysEvent& event,
                               GlishSysEventSource& eventStream,
                               String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("row"))
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("value"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, True)) {
    return False;
  }
  String column;
  GlishArray(location.get("column")).get(column);
  Vector<Int> rownrs;
  GlishArray(location.get("row")).get(rownrs);
  GlishValue value = location.get("value");
  ValueHolder vh = valueFromGlish(value);
  tables_p[id].proxy().putCell (column, rownrs, vh);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::putCellSlice (GlishSysEvent& event,
				    GlishSysEventSource& eventStream,
				    String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("row"))
  ||  (! GlishRecord(event.val()).exists("blc"))
  ||  (! GlishRecord(event.val()).exists("trc"))
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("value"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, True)) {
    return False;
  }
  String column;
  GlishArray(location.get("column")).get(column);
  Int rownr;
  GlishArray(location.get("row")).get(rownr);
  Vector<Int> blc, trc, inc;
  GlishArray (location.get("blc")).get(blc);
  GlishArray (location.get("trc")).get(trc);
  if (location.exists("inc")) {
    GlishArray (location.get("inc")).get(inc);
  }
  GlishValue value = location.get("value");
  ValueHolder vh = valueFromGlish(value);
  tables_p[id].proxy().putCellSlice (column, rownr, vh, blc, trc, inc);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::getColumnShapeString (GlishSysEvent& event,
					    GlishSysEventSource& eventStream,
					    String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("row"))
  ||  (! GlishRecord(event.val()).exists("nrow"))
  ||  (! GlishRecord(event.val()).exists("rowincr"))
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, False)) {
    return False;
  }
  String column;
  GlishArray(location.get("column")).get(column);
  Int rownr, nrow, incr;
  GlishArray(location.get("row")).get(rownr);
  GlishArray(location.get("nrow")).get(nrow);
  GlishArray(location.get("rowincr")).get(incr);
  eventStream.postEvent (returnEventName(event),
			 tables_p[id].proxy().getColumnShapeString
			                   (column, rownr, nrow, incr));
  return True;
}

Bool GlishTableProxy::cellContentsDefined (GlishSysEvent& event,
                                           GlishSysEventSource& eventStream,
                                           String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("row"))
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, False)) {
    return False;
  }
  String column;
  GlishArray (location.get("column")).get(column);
  Int rownr;
  GlishArray (location.get("row")).get(rownr);
  Bool result = tables_p[id].proxy().cellContentsDefined(column, rownr);
  eventStream.postEvent (returnEventName(event), GlishArray(result));
  return True;
}

Bool GlishTableProxy::getKeyword (GlishSysEvent& event,
				  GlishSysEventSource& eventStream,
				  String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("keyword"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  GlishArray keyid(location.get("keyword"));
  String keyName;
  Int keyInx = -1;
  if (keyid.elementType() == GlishArray::STRING) {
    keyid.get (keyName);
  } else {
    keyid.get (keyInx);                     // 1-relative index
  }
  String column;
  if (location.exists ("column")) {
    GlishArray(location.get("column")).get(column);
  }
  eventStream.postEvent (returnEventName(event),
			 valueToGlish(tables_p[id].proxy().getKeyword
				      (column, keyName, keyInx-1)));
  return True;
}

Bool GlishTableProxy::getKeywordSet (GlishSysEvent& event,
				     GlishSysEventSource& eventStream,
				     String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  String column;
  if (location.exists ("column")) {
    GlishArray(location.get("column")).get(column);
  }
  GlishRecord grec;
  grec.fromRecord (tables_p[id].proxy().getKeywordSet (column));
  eventStream.postEvent (returnEventName(event), grec);
  return True;
}

Bool GlishTableProxy::putKeyword (GlishSysEvent& event,
				  GlishSysEventSource& eventStream,
				  String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("keyword"))
  ||  (! GlishRecord(event.val()).exists("value"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, True)) {
    return False;
  }
  String column;
  if (location.exists ("column")) {
    GlishArray(location.get("column")).get(column);
  }
  GlishArray keyid(location.get("keyword"));
  GlishArray makesr(location.get("makesubrecord"));
  Bool makeSubRecord;
  makesr.get (makeSubRecord);
  String keyName;
  Int keyInx = -1;
  if (keyid.elementType() == GlishArray::STRING) {
    keyid.get (keyName);
  } else {
    keyid.get (keyInx);                     // 1-relative index
  }
  GlishValue value = location.get("value");
  ValueHolder vh = valueFromGlish(value);
  tables_p[id].proxy().putKeyword (column, keyName, keyInx-1,
				   makeSubRecord, vh);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::putKeywordSet (GlishSysEvent& event,
				     GlishSysEventSource& eventStream,
				     String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("value"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, True)) {
    return False;
  }
  String column;
  if (location.exists ("column")) {
    GlishArray(location.get("column")).get(column);
  }
  GlishRecord grec (location.get("value"));
  Record rec;
  grec.toRecord (rec);
  tables_p[id].proxy().putKeywordSet (column, rec);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}


Bool GlishTableProxy::removeKeyword (GlishSysEvent& event,
				     GlishSysEventSource& eventStream,
				     String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("keyword"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, True)) {
    return False;
  }
  String column;
  if (location.exists ("column")) {
    GlishArray(location.get("column")).get(column);
  }
  String keyName;
  Int keyInx = -1;
  GlishArray keyid(location.get("keyword"));
  if (keyid.elementType() == GlishArray::STRING) {
    keyid.get (keyName);
  } else {
    keyid.get (keyInx);                     // 1-relative index
  }
  tables_p[id].proxy().removeKeyword (column, keyName, keyInx-1);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::getFieldNames (GlishSysEvent& event,
				     GlishSysEventSource& eventStream,
				     String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("column"))
  ||  (! GlishRecord(event.val()).exists("keyword"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  String column;
  GlishArray(location.get("column")).get(column);
  String keyName;
  Int keyInx = -1;
  GlishArray keyid(location.get("keyword"));
  if (keyid.elementType() == GlishArray::STRING) {
    String keyname;
    keyid.get (keyName);
  } else {
    keyid.get (keyInx);                     // 1-relative index
  }
  eventStream.postEvent (returnEventName(event),
			 tables_p[id].proxy().getFieldNames (column, keyName,
							     keyInx-1));
  return True;
}

Bool GlishTableProxy::flush (GlishSysEvent& event,
			     GlishSysEventSource& eventStream,
			     String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  // Determine if subtables have to be flushed.
  Bool recur = False;
  if (location.exists("recursive")) {
    GlishArray(location.get("recursive")).get(recur);
  }
  tables_p[id].proxy().flush (recur);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::resync (GlishSysEvent& event,
			      GlishSysEventSource& eventStream,
			      String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  tables_p[id].proxy().resync();
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::close (GlishSysEvent& event,
			     GlishSysEventSource& eventStream,
			     String& message)
{
  if (event.val().type() != GlishValue::RECORD) {
    message = "No record sent";
    return False;
  }
  GlishRecord rec(event.val());
  if (rec.exists("tableId")) {
    Int id;
    GlishArray(rec.get("tableId")).get(id);
    if (! validTableId (id, message, False, False)) {
      return False;
    }
    closeTable (id);
  }else{
    String name;
    GlishArray(rec.get("tableName")).get(name);
    if (name.empty()) {
      message = "No table name given on close";
      return False;
    }
    name = Path(name).absoluteName();
    for (uInt i=0; i<tables_p.size(); i++) {
      if (tables_p[i].tableName() == name) {
	closeTable (i);
      }
    }
  }
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::closeAll (GlishSysEvent& event,
				GlishSysEventSource& eventStream,
				String&)
{
  for (uInt i=0; i<tables_p.size(); i++) {
    closeTable(i);
  }
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::getOpenTables (GlishSysEvent& event,
				     GlishSysEventSource& eventStream,
				     String&)
{
  const TableCache& cache = PlainTable::tableCache;
  uInt i;
  uInt nr=0;
  Vector<String> names(tables_p.size());
  for (i=0; i<tables_p.size(); i++) {
    if (tables_p[i].isOpen() > 0) {
      const String& name = tables_p[i].tableName();
      if (!name.empty()  &&  cache(name) == 0) {
	names(nr++) = name;
      }
    }
  }
  uInt ntab = cache.ntable();
  names.resize (nr+ntab, True);
  for (uInt i=0; i<ntab; i++) {
    names(nr++) = cache(i)->tableName();
  }
  eventStream.postEvent (returnEventName(event), GlishArray(names));
  return True;
}

Bool GlishTableProxy::tableInfo (GlishSysEvent& event,
				 GlishSysEventSource& eventStream,
				 String& message)
{
  if (event.val().type() != GlishValue::RECORD) {
    message = "No record sent";
    return False;
  }
  TableProxy proxy;
  GlishRecord rec(event.val());
  if (rec.exists("tableId")) {
    Int id;
    GlishArray(rec.get("tableId")).get(id);
    if (! validTableId (id, message, False)) {
      return False;
    }
    proxy = tables_p[id].proxy();
  } else {
    String name;
    GlishArray(rec.get("tableName")).get(name);
    if (name.empty()) {
      message = "No table name given for tableInfo";
      return False;
    }
    proxy = Table(name);
  }
  GlishRecord grec;
  grec.fromRecord (proxy.tableInfo());
  eventStream.postEvent (returnEventName(event), grec);
  return True;
}

Bool GlishTableProxy::putTableInfo (GlishSysEvent& event,
				    GlishSysEventSource& eventStream,
				    String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("value"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord rec(event.val());
  Int id;
  GlishArray(rec.get("tableId")).get(id);
  if (! validTableId (id, message, True)) {
    return False;
  }
  GlishRecord value (rec.get("value"));
  Record val;
  value.toRecord (val);
  tables_p[id].proxy().putTableInfo (val);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::addReadmeLine (GlishSysEvent& event,
				     GlishSysEventSource& eventStream,
				     String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("value"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord rec(event.val());
  Int id;
  GlishArray(rec.get("tableId")).get(id);
  if (! validTableId (id, message, True)) {
    return False;
  }
  String str (recombineString (rec.get("value")));
  tables_p[id].proxy().addReadmeLine (str);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::isReadable (GlishSysEvent& event,
				  GlishSysEventSource& eventStream,
				  String& message)
{
  if (event.val().type() != GlishValue::RECORD) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord rec(event.val());
  Bool result = False;
  if (rec.exists("tableId")) {
    Int id;
    GlishArray(rec.get("tableId")).get(id);
    if (id >= 0  &&  uInt(id) < tables_p.size()) {
      result = tables_p[id].isReadable();
    }
  }else{
    String name;
    GlishArray(rec.get("tableName")).get(name);
    result = Table::isReadable (name);
  }
  eventStream.postEvent (returnEventName(event), GlishArray(result));
  return True;
}

Bool GlishTableProxy::isWritable (GlishSysEvent& event,
				  GlishSysEventSource& eventStream,
				  String& message)
{
  if (event.val().type() != GlishValue::RECORD) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord rec(event.val());
  Bool result = False;
  if (rec.exists("tableId")) {
    Int id;
    GlishArray(rec.get("tableId")).get(id);
    if (id >= 0  &&  uInt(id) < tables_p.size()) {
      result = tables_p[id].isWritable();
    }
  }else{
    String name;
    GlishArray(rec.get("tableName")).get(name);
    result = Table::isWritable (name);
  }
  eventStream.postEvent (returnEventName(event), GlishArray(result));
  return True;
}

Bool GlishTableProxy::getName (GlishSysEvent& event,
			       GlishSysEventSource& eventStream,
			       String& message)
{
  if (event.val().type() != GlishValue::ARRAY
  ||  GlishArray(event.val()).elementType() == GlishArray::STRING) {
    message = "Non numeric sent";
    return False;
  }
  Int id;
  GlishArray(event.val()).get (id);
  if (! validTableId (id, message, False, False)) {
    return False;
  }
  eventStream.postEvent (returnEventName(event), 
			 GlishArray(tables_p[id].tableName()));
  return True;
}

Bool GlishTableProxy::getId (GlishSysEvent& event,
			     GlishSysEventSource& eventStream,
			     String& message)
{
  if (event.val().type() != GlishValue::ARRAY
  ||  GlishArray(event.val()).elementType() != GlishArray::STRING) {
    message = "Non string sent";
    return False;
  }
  String tableName;
  GlishArray(event.val()).get (tableName);
  if (tableName.empty()) {
    message = "Blank table name sent";
    return False;
  }
  tableName = Path(tableName).absoluteName();
  Int id;
  for (id=0; uInt(id)<tables_p.size(); id++) {
    if (tableName == tables_p[id].tableName()) {
      break;
    }
  }
  if (uInt(id) >= tables_p.size()) {
    message = "Table " + tableName + " has no handle";
    return False;
  }
  eventStream.postEvent (returnEventName(event), GlishArray(id));
  return True;
}

Bool GlishTableProxy::addColumns (GlishSysEvent& event,
				  GlishSysEventSource& eventStream,
				  String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("tableDesc"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, True)) {
    return False;
  }
  GlishRecord gdesc (location.get("tableDesc"));
  Record tdrec;
  gdesc.toRecord (tdrec);
  Record dminfo;
  if (location.exists ("dminfo")) {
    GlishRecord gdminfo (location.get("dminfo"));
    gdminfo.toRecord (dminfo);
  }
  tables_p[id].proxy().addColumns (tdrec, dminfo);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::renameColumn (GlishSysEvent& event,
				    GlishSysEventSource& eventStream,
				    String& message)
{
  if (event.val().type() != GlishValue::RECORD
   ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("nameNew"))
  ||  (! GlishRecord(event.val()).exists("nameOld"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, True)) {
    return False;
  }
  String nameNew, nameOld;
  GlishArray(location.get("nameNew")).get(nameNew);
  GlishArray(location.get("nameOld")).get(nameOld);
  tables_p[id].proxy().renameColumn (nameNew, nameOld);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::removeColumns (GlishSysEvent& event,
				     GlishSysEventSource& eventStream,
				     String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("columns"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, True)) {
    return False;
  }
  Vector<String> cols;
  GlishArray(location.get("columns")).get(cols);
  tables_p[id].proxy().removeColumns (cols);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::addRow (GlishSysEvent& event,
			      GlishSysEventSource& eventStream,
			      String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, True)) {
    return False;
  }
  Int nrow = 1;
  if (location.exists("nrow")) {
    GlishArray(location.get("nrow")).get(nrow);
  }
  if (nrow < 0) {
    nrow = 0;
  }
  tables_p[id].proxy().addRow (nrow);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::removeRow (GlishSysEvent& event,
				 GlishSysEventSource& eventStream,
				 String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("rowNumbers"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord location(event.val());
  Int id;
  GlishArray(location.get("tableId")).get(id);
  if (! validTableId (id, message, True)) {
    return False;
  }
  Array<Int> rownrs;
  GlishArray(location.get("rowNumbers")).get(rownrs);
  tables_p[id].proxy().removeRow (rownrsFromGlish (rownrs));
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}




//# Add iterator object to the block.
Int GlishTableProxy::addIterator (TableIterProxy& iter)
{
  Int niters = iterators_p.size();
  //# Get an associated tableId for the iterator object.
  TableProxy table;
  Int tableId = addTable (table);
  iterators_p.push_back (GlishTableIteratorHolder (iter, tableId));
  return niters;
}

Bool GlishTableProxy::validIterId (Int id, String& message)
{
  if (id < 0  ||  uInt(id) >= iterators_p.size()
  ||  iterators_p[id].iterator().isNull()) {
    message = "Illegal iterator-id sent (no such iterator)";
    return False;
  }
  return True;
}

Bool GlishTableProxy::makeIterator (GlishSysEvent& event,
				    GlishSysEventSource& eventStream,
				    String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("columnNames"))
  ||  (! GlishRecord(event.val()).exists("order"))
  ||  (! GlishRecord(event.val()).exists("sort"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab(event.val());
  Int id;
  GlishArray(gtab.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  GlishArray cols(gtab.get("columnNames"));
  Vector<String> columns(cols.nelements());
  cols.get (columns);
  String order, sort;
  GlishArray(gtab.get("order")).get(order);
  GlishArray(gtab.get("sort")).get(sort);
  TableIterProxy iter (tables_p[id].proxy(), columns, order, sort);
  // Open succeeded; add iter to the block.
  // Just return the sequence number to the remote user
  Int iterId = addIterator (iter);
  GlishRecord rec;
  rec.add ("iterId", iterId);
  rec.add ("tableId", iterators_p[iterId].tableId());
  eventStream.postEvent (returnEventName(event), rec);
  return True;
}

Bool GlishTableProxy::stepIterator (GlishSysEvent& event,
				    GlishSysEventSource& eventStream,
				    String& message)
{
  if (event.val().type() != GlishValue::ARRAY
  ||  GlishArray(event.val()).elementType() == GlishArray::STRING) {
    message = "Non-numeric iterator-id sent";
    return False;
  }
  Int id;
  GlishArray(event.val()).get(id);
  if (! validIterId (id, message)) {
    return False;
  }
  // Get the next subtable (stored in table in GlishTableHolder object).
  // When at the end, nullify the GlishTableHolder and
  // GlishTableIteratorHolder object to prevent future use.
  Int tableId = iterators_p[id].tableId();
  Bool result = iterators_p[id].next (tables_p[tableId]);
  if (!result) {
    tables_p[tableId] = GlishTableHolder();
    iterators_p[id]   = GlishTableIteratorHolder();
  }
  eventStream.postEvent (returnEventName(event), GlishArray(result));
  return True;
}

Bool GlishTableProxy::closeIterator (GlishSysEvent& event,
				     GlishSysEventSource& eventStream,
				     String& message)
{
  if (event.val().type() != GlishValue::ARRAY
  ||  GlishArray(event.val()).elementType() == GlishArray::STRING) {
    message = "Non-numeric iterator-id sent";
    return False;
  }
  Int id;
  GlishArray(event.val()).get(id);
  if (! validIterId (id, message)) {
    return False;
  }
  // Nullify the GlishTableHolder and
  // GlishTableIteratorHolder object to prevent future use.
  Int tableId = iterators_p[id].tableId();
  tables_p[tableId] = GlishTableHolder();
  iterators_p[id]   = GlishTableIteratorHolder();
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}



//# Add row object to the block.
Int GlishTableProxy::addTableRow (const TableRowProxy& row, Int tableId)
{
  Int nrows = rows_p.size();
  rows_p.push_back (GlishTableRowHolder (row, tableId));
  return nrows;
}

Bool GlishTableProxy::validRowId (Int id, String& message)
{
  if (id < 0  ||  uInt(id) >= rows_p.size()
  ||  rows_p[id].isNull()) {
    message = "Illegal row-id sent (no such TableRow object)";
    return False;
  }
  return True;
}

Bool GlishTableProxy::makeRow (GlishSysEvent& event,
			       GlishSysEventSource& eventStream,
			       String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab(event.val());
  Int id;
  GlishArray(gtab.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  Vector<String> columns;
  if (gtab.exists ("columnNames")) {
    GlishArray cols(gtab.get("columnNames"));
    cols.get (columns);
  }
  Bool exclude;
  if (gtab.exists ("exclude")) {
    GlishArray(gtab.get("exclude")).get(exclude);
  }
  Int rowId = addTableRow (TableRowProxy (tables_p[id].proxy(),
					  columns, exclude), id);
  eventStream.postEvent (returnEventName(event), GlishArray(rowId));
  return True;
}

Bool GlishTableProxy::getRow (GlishSysEvent& event,
			      GlishSysEventSource& eventStream,
			      String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("rowId"))
  ||  (! GlishRecord(event.val()).exists("row"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab(event.val());
  Int id;
  GlishArray(gtab.get("rowId")).get(id);
  if (! validRowId (id, message)) {
    return False;
  }
  Int rownr;
  GlishArray(gtab.get("row")).get(rownr);
  GlishRecord record;
  record.fromRecord (rows_p[id].proxy().get (rownr));
  eventStream.postEvent (returnEventName(event), record);
  return True;
}

Bool GlishTableProxy::putRow (GlishSysEvent& event,
			      GlishSysEventSource& eventStream,
			      String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("rowId"))
  ||  (! GlishRecord(event.val()).exists("row"))
  ||  (! GlishRecord(event.val()).exists("value"))
  ||  (! GlishRecord(event.val()).exists("matchingFields"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab(event.val());
  Int id;
  GlishArray(gtab.get("rowId")).get(id);
  if (! validRowId (id, message)) {
    return False;
  }
  Int rownr;
  GlishArray(gtab.get("row")).get(rownr);
  GlishRecord value (gtab.get("value"));
  Bool matchingFields;
  GlishArray(gtab.get("matchingFields")).get(matchingFields);
  TableRecord record;
  value.toRecord (record);
  rows_p[id].proxy().put (rownr, record, matchingFields);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::closeRow (GlishSysEvent& event,
				GlishSysEventSource& eventStream,
				String& message)
{
  if (event.val().type() != GlishValue::ARRAY
  ||  GlishArray(event.val()).elementType() == GlishArray::STRING) {
    message = "Non-numeric iterator-id sent";
    return False;
  }
  Int id;
  GlishArray(event.val()).get(id);
  if (! validRowId (id, message)) {
    return False;
  }
  // Nullify the GlishTableRowHolder object to prevent future use.
  rows_p[id] = GlishTableRowHolder();
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}



//# Add index object to the block.
Int GlishTableProxy::addIndex (TableIndexProxy* index, Int tableId)
{
  Int ninx = indices_p.size();
  indices_p.push_back (GlishTableIndexHolder (index, tableId));
  return ninx;
}

Bool GlishTableProxy::validIndexId (Int id, String& message)
{
  if (id < 0  ||  uInt(id) >= indices_p.size()
  ||  indices_p[id].isNull()) {
    message = "Illegal index-id sent (no such table index)";
    return False;
  }
  return True;
}

Bool GlishTableProxy::makeIndex (GlishSysEvent& event,
				 GlishSysEventSource& eventStream,
				 String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("tableId"))
  ||  (! GlishRecord(event.val()).exists("columnNames"))
  ||  (! GlishRecord(event.val()).exists("sort"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab(event.val());
  Int id;
  GlishArray(gtab.get("tableId")).get(id);
  if (! validTableId (id, message)) {
    return False;
  }
  GlishArray cols(gtab.get("columnNames"));
  Vector<String> columnNames;
  cols.get (columnNames);
  Bool sort;
  GlishArray(gtab.get("sort")).get(sort);
  Int indexId = addIndex (new TableIndexProxy (tables_p[id].proxy(),
					       columnNames, !sort), id);
  eventStream.postEvent (returnEventName(event), GlishArray(indexId));
  return True;
}

Bool GlishTableProxy::indexIsUnique (GlishSysEvent& event,
				     GlishSysEventSource& eventStream,
				     String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("indexId"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab(event.val());
  Int id;
  GlishArray(gtab.get("indexId")).get(id);
  if (! validIndexId (id, message)) {
    return False;
  }
  Bool uniq = indices_p[id].proxy().isUnique();
  eventStream.postEvent (returnEventName(event), GlishArray(uniq));
  return True;
}

Bool GlishTableProxy::indexSetChanged (GlishSysEvent& event,
				       GlishSysEventSource& eventStream,
				       String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("indexId"))
  ||  (! GlishRecord(event.val()).exists("columnNames"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab(event.val());
  Int id;
  GlishArray(gtab.get("indexId")).get(id);
  if (! validIndexId (id, message)) {
    return False;
  }
  Vector<String> columnNames;
  if (gtab.exists("columnNames")) {
    GlishArray cols(gtab.get("columnNames"));
    cols.get (columnNames);
  }
  indices_p[id].proxy().setChanged (columnNames);
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}

Bool GlishTableProxy::indexGetRowNumber (GlishSysEvent& event,
					 GlishSysEventSource& eventStream,
					 String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("indexId"))
  ||  (! GlishRecord(event.val()).exists("key"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab(event.val());
  Int id;
  GlishArray(gtab.get("indexId")).get(id);
  if (! validIndexId (id, message)) {
    return False;
  }
  GlishRecord gkey(gtab.get("key"));
  Record key;
  gkey.toRecord (key);
  Int row = indices_p[id].proxy().getRowNumber (key);
  eventStream.postEvent (returnEventName(event),
			 GlishArray(rownrToGlish(row)));
  return True;
}

Bool GlishTableProxy::indexGetRowNumbers (GlishSysEvent& event,
					  GlishSysEventSource& eventStream,
					  String& message)
{
  if (event.val().type() != GlishValue::RECORD
  ||  (! GlishRecord(event.val()).exists("indexId"))
  ||  (! GlishRecord(event.val()).exists("lowerKey"))) {
    message = "Incorrect record sent";
    return False;
  }
  GlishRecord gtab(event.val());
  Int id;
  GlishArray(gtab.get("indexId")).get(id);
  if (! validIndexId (id, message)) {
    return False;
  }
  Vector<Int> rows;
  GlishRecord glkey(gtab.get("lowerKey"));
  Record lkey;
  glkey.toRecord (lkey);
  if (! gtab.exists("upperKey")) {
    rows = indices_p[id].proxy().getRowNumbers (lkey);
  } else {
    GlishRecord gukey(gtab.get("upperKey"));
    Record ukey;
    gukey.toRecord (ukey);
    Bool lincl, uincl;
    GlishArray(gtab.get("lowerIncl")).get(lincl);
    GlishArray(gtab.get("upperIncl")).get(uincl);
    rows = indices_p[id].proxy().getRowNumbersRange (lkey, ukey, lincl, uincl);
  }
  eventStream.postEvent (returnEventName(event), rownrsToGlish(rows));
  return True;
}

Bool GlishTableProxy::closeIndex (GlishSysEvent& event,
				  GlishSysEventSource& eventStream,
				  String& message)
{
  if (event.val().type() != GlishValue::ARRAY
  ||  GlishArray(event.val()).elementType() == GlishArray::STRING) {
    message = "Non-numeric index-id sent";
    return False;
  }
  Int id;
  GlishArray(event.val()).get(id);
  if (! validIndexId (id, message)) {
    return False;
  }
  // Nullify the GlishTableIndexHolder object to prevent future use.
  indices_p[id] = GlishTableIndexHolder();
  eventStream.postEvent (returnEventName(event), GlishArray(True));
  return True;
}



Array<Int> GlishTableProxy::rownrsToGlish (const Vector<Int>& rownrs)
{
  return rownrs+1;
}

Array<Int> GlishTableProxy::rowposToGlish (const IPosition& rowpos)
{
  return rowpos.asVector() + 1;
}

Vector<Int> GlishTableProxy::rownrsFromGlish (const Array<Int>& rownrs)
{
  return Vector<Int> (rownrs-1);
}

IPosition GlishTableProxy::rowposFromGlish (const Array<Int>& rownrs)
{
  IPosition out(rownrs);
  out -= 1;
  return out;
}

GlishValue GlishTableProxy::valueToGlish (const ValueHolder& val)
{
  // Exit immediately if no value.
  if (val.isNull()) {
    return GlishValue::getUnset();
  }
  GlishArray retval;
  switch (val.dataType()) {
  case TpBool:
    retval = val.asBool();
    break;
  case TpUChar:
    retval = val.asuChar();
    break;
  case TpShort:
    retval = val.asShort();
    break;
  case TpInt:
    retval = val.asInt();
    break;
  case TpFloat:
    retval = val.asFloat();
    break;
  case TpDouble:
    retval = val.asDouble();
    break;
  case TpComplex:
    retval = val.asComplex();
    break;
  case TpDComplex:
    retval = val.asDComplex();
    break;
  case TpString:
    retval = val.asString();
    break;
  case TpArrayBool:
    retval = val.asArrayBool();
    break;
  case TpArrayUChar:
    retval = val.asArrayuChar();
    break;
  case TpArrayShort:
    retval = val.asArrayShort();
    break;
  case TpArrayInt:
    retval = val.asArrayInt();
    break;
  case TpArrayFloat:
    retval = val.asArrayFloat();
    break;
  case TpArrayDouble:
    retval = val.asArrayDouble();
    break;
  case TpArrayComplex:
    retval = val.asArrayComplex();
    break;
  case TpArrayDComplex:
    retval = val.asArrayDComplex();
    break;
  case TpArrayString:
    retval = val.asArrayString();
    break;
  case TpRecord:
    {
      GlishRecord rec;
      rec.fromRecord (val.asRecord());
      return rec;
    }
  default:
    throw TableError ("gtable::valueToGlish: Unknown data type");
  }
  return retval;
}

ValueHolder GlishTableProxy::valueFromGlish (const GlishValue& val)
{
  if (val.type() == GlishValue::RECORD) {
    GlishRecord grec(val);
    if (grec.isUnset()) {
      return ValueHolder();
    }
    Record rec;
    grec.toRecord (rec);
    return ValueHolder (rec);
  }
  // Value is a scalar or array.
  GlishArray arrVal(val);
  if (arrVal.nelements() == 1) {
    switch (arrVal.elementType()) {
    case GlishArray::BOOL:
      {
	Bool v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::BYTE:
      {
	uChar v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::SHORT:
      {
	Short v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::INT:
      {
	Int v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::FLOAT:
      {
	Float v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::DOUBLE:
      {
	Double v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::COMPLEX:
      {
	Complex v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::DCOMPLEX:
      {
	DComplex v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::STRING:
      {
	String v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    }
  } else {
    switch (arrVal.elementType()) {
    case GlishArray::BOOL:
      {
	Array<Bool> v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::BYTE:
      {
	Array<uChar> v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::SHORT:
      {
	Array<Short> v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::INT:
      {
	Array<Int> v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::FLOAT:
      {
	Array<Float> v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::DOUBLE:
      {
	Array<Double> v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::COMPLEX:
      {
	Array<Complex> v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::DCOMPLEX:
      {
	Array<DComplex> v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    case GlishArray::STRING:
      {
	Array<String> v;
	arrVal.get (v);
	return ValueHolder(v);
      }
    }
  }
  return ValueHolder();
}
