# table.g: tableserver
#
#   Copyright (C) 1995,1996,1997,1998,1999,2000,2001,2002,2003
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: tableserver.g,v 19.6 2006/11/07 22:23:44 gvandiep Exp $
#
#----------------------------------------------------------------------------

pragma include once

include "note.g";
include "substitute.g";

# Pre declare
if(!is_defined('defaultservers')) defaultservers := F;

tableserver:=function(tablenote=note) {

  self:=[=];
  public:=[=];

  self.tableClient:=F;
  self.tableClient::Died:=T;

# Private functions
#------------------------------------------------------------------------------
  const self.makeclient:=function(clientInit="gtable") {
    this:=client(clientInit);
    if(!is_agent(this)) {
      return throw('table client could not be started');
    }
    whenever this->fail do this::Died:=T;
    whenever this->_memory do {
      if (is_record(defaultservers)&&is_record(defaultservers.memory())&&
	  has_field(defaultservers.memory(), 'chart')) {
	defaultservers.memory().chart('gtable', $value);
      }
    }
    return this;
  }

# This function checks the result of a table operation.
# In case of an error, it prints it and returns a False status.
  const self.checkTableResult := function(const object)
    {
      if (is_record (object)  &&
	  length (object) == 1  &&
	  has_field (object, "error_message")) {
        fail object.error_message;
      }
      return T;
    }
  
# This function checks if the handle is a table handle.
  const self.checkTableHandle := function(const object)
    {
      if (is_record (object)  &&
	  has_field (object, "type") &&
	  object.type == "table") {
        return T;
      }
      fail 'no valid table handle given';
    }
# This function checks if the handle is a table iterator handle.
  const self.checkTableIterHandle := function(const object)
    {
      if (is_record (object)  &&
	  has_field (object, "type") &&
	  object.type == "tableIterator") {
        return T;
      }
      fail 'no valid table iterator handle given';
    }
# This function checks if the handle is a table row handle.
  const self.checkTableRowHandle := function(const object)
    {
      if (is_record (object)  &&
	  has_field (object, "type") &&
	  object.type == "tableRow") {
        return T;
      }
      fail 'no valid table row handle given';
    }
# This function checks if the handle is a table index handle.
  const self.checkTableIndexHandle := function(const object)
    {
      if (is_record (object)  &&
	  has_field (object, "type") &&
	  object.type == "tableIndex") {
        return T;
      }
      fail 'no valid table index handle given';
    }
  
  
# Public functions
#------------------------------------------------------------------------------
  const public.initialize:=function() {
    if(is_boolean(self.tableClient)||self.tableClient::Died) {
      wider self;
      self.tableClient := self.makeclient();
    }
  }

  const public.terminate:=function() {
    self.tableClient->terminate();
  }

  const public.openTable := function(tableName, ack=T, lockOptions='auto')
    {
      local result;
      local object;
      object.type := 'table';
      local rec;
      rec.tableName := tableName;
      if (is_string(lockOptions)) {
        local opt;
        opt.option := lockOptions;
        rec.lockOptions := opt;
      } else {
        rec.lockOptions := lockOptions;
      }
      self.tableClient->open(rec);
      await self.tableClient->open_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      object.id := $value;
      object.file := tableName;
      if (ack) {
        tablenote(spaste('successful readonly open of ',
			  rec.lockOptions.option, '-locked ',
			  'table ', tableName, ': ',
			  public.numberOfColumns (object), ' columns, ',
			  public.numberOfRows (object), ' rows'),
		   priority='NORMAL',
		   origin='table');
      }
      return object;
    }
  
  const public.renameTable := function(tableName, newTableName)
    {
      local result;
      local rec;
      rec.tableName := tableName;
      rec.newTableName := newTableName;
      self.tableClient->rename(rec);
      await self.tableClient->rename_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return T;
    }
  
  const public.copyTable := function(const object, newTableName, deep,
				     valueCopy, dminfo,
				     endianFormat, memtype,
				     noRows, returnHandle)
    {
      local result;
      local rec;
      if (is_string(object)) {
	rec.tableName := object;
      }else{
        result:=self.checkTableHandle (object);
        if(is_fail(result)) return result;
	rec.tableId := object.id;
      }
      rec.newTableName := newTableName;
      rec.deepCopy := deep;
      rec.valueCopy := valueCopy;
      rec.dminfo := dminfo;
      rec.endianFormat := endianFormat;
      rec.memtype := memtype;
      rec.noRows := noRows;
      rec.returnHandle := returnHandle;
      self.tableClient->copy(rec);
      await self.tableClient->copy_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      id := $value;
      if (id < 0) return T;       # no table handle returned
      local newObject;
      newObject.type := 'table';
      newObject.id := id;
      newObject.file := newTableName;
      return newObject;
    }
  
  const public.copyRows := function(const objectIn, const objectOut,
				    startRowIn=1, startRowOut=-1, nrow=-1)
    {
      local result;
      result:=self.checkTableHandle (objectIn);
      if(is_fail(result)) return result;
      result:=self.checkTableHandle (objectOut);
      if(is_fail(result)) return result;
      local rec;
      rec.tableIdIn := objectIn.id;
      rec.tableIdOut := objectOut.id;
      rec.rowIn := startRowIn-1;
      rec.rowOut := startRowOut-1;
      rec.nrow := nrow;
      self.tableClient->copy_rows(rec);
      await self.tableClient->copy_rows_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return T;
    }
  
  const public.openTableForUpdate := function(tableName, ack=T,
                                              lockOptions='auto')
    {
      local result;
      local object;
      object.type := 'table';
      local rec;
      rec.tableName := tableName;
      if (is_string(lockOptions)) {
        local opt;
        opt.option := lockOptions;
        rec.lockOptions := opt;
      } else {
        rec.lockOptions := lockOptions;
      }
      self.tableClient->open_update(rec);
      await self.tableClient->open_update_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      object.id := $value;
      object.file := tableName;
      if (ack) {
        tablenote(spaste('successful read/write open of ',
			  rec.lockOptions.option, '-locked ',
			  'table ', tableName, ': ',
			  public.numberOfColumns (object), ' columns, ',
			  public.numberOfRows (object), ' rows'), 
		  priority='NORMAL', origin='table');
      }
      return object;
    }
  
  const public.createTable := function(tableName, const tableDesc, dminfo,
                                       nrow=0, ack=T, lockOptions='auto',
				       endianFormat='aipsrc', memtype='plain')
    {
      local result;
      local object;
      object.type := 'table';
      local rec;
      rec.tableName := tableName;
      rec.tableDesc := tableDesc;
      if (is_record(dminfo)) {
	rec.dminfo := dminfo;
      }
      rec.memtype := memtype;
      rec.nrow := nrow;
      if (is_string(lockOptions)) {
        local opt;
        opt.option := lockOptions;
        rec.lockOptions := opt;
      } else {
        rec.lockOptions := lockOptions;
      }
      rec.endianFormat := endianFormat;
      self.tableClient->create(rec);
      await self.tableClient->create_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      object.id := $value;
      object.file := tableName;
      if (ack) {
        tablenote(spaste('successful creation of ',
			  rec.lockOptions.option, '-locked ',
			  'table ', tableName, ': ',
			  public.numberOfColumns (object), ' columns, ',
			  public.numberOfRows (object), ' rows'), 
		  priority='NORMAL', origin='table');
      }
      return object;
    }
  
  const public.deleteTable := function(const object, checksubtables, ack=T)
    {
      local result;
      local rec;
      local name;
      if (type_name(object) == "string") {
	rec.tableName := object;
        name := object;
      }else{
        result:=self.checkTableHandle (object);
        if(is_fail(result)) return result;
	rec.tableId := object.id;
        name := object.file;
      }
      rec.checkSubTables := checksubtables;
      self.tableClient->delete(rec);
      await self.tableClient->delete_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      local value := $value;
      if (ack) {
	tablenote(paste('deleted table', name),
		  priority='NORMAL', origin='table');
      }
      return value;
    }
  
  const public.closeTable := function(const object)
    {
      local result;
      local rec;
      if (type_name(object) == "string") {
	rec.tableName := object;
      }else{
        result:=self.checkTableHandle (object);
        if(is_fail(result)) return result;
	rec.tableId := object.id;
      }
      self.tableClient->close(rec);
      await self.tableClient->close_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.closeAllTables := function()
    {
      local result;
      self.tableClient->close_all();
      await self.tableClient->close_all_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.endianFormat := function(const object)
    {
      local result;
      local rec;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      self.tableClient->endian_format(rec);
      await self.tableClient->endian_format_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.flush := function(const object, recursive)
    {
      local result;
      local rec;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      rec.recur   := recursive;
      self.tableClient->flush(rec);
      await self.tableClient->flush_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.resync := function(const object)
    {
      local result;
      local rec;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      self.tableClient->resync(rec);
      await self.tableClient->resync_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.lock := function(const object, write = T, nattempts = 0)
    {
      local result;
      local rec;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      rec.mode := write;
      rec.nattempts := nattempts;
      self.tableClient->lock(rec);
      await self.tableClient->lock_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.unlock := function(const object)
    {
      local result;
      local rec;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      self.tableClient->unlock(rec);
      await self.tableClient->unlock_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.hasDataChanged := function(const object)
    {
      local result;
      local rec;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      self.tableClient->has_data_changed(rec);
      await self.tableClient->has_data_changed_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.hasLock := function(const object, write = T)
    {
      local result;
      local rec;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      rec.mode := write;
      self.tableClient->has_lock(rec);
      await self.tableClient->has_lock_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.lockOptions := function(const object)
    {
      local result;
      local rec;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      self.tableClient->lock_options(rec);
      await self.tableClient->lock_options_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.isMultiUsed := function(const object, checksubtables)
    {
      local result;
      local rec;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      rec.checkSubTables := checksubtables;
      self.tableClient->is_multi_used(rec);
      await self.tableClient->is_multi_used_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.readAscii := function(tableName, fileName, headerName,
				     autoHeader, autoShape,
				     sep, commentMarker,
				     firstLine, lastLine,
				     columnNames, dataTypes) 
    {
      local result;
      local rec;
      rec.fileName      := fileName;
      rec.tableName     := tableName;
      rec.headerName    := headerName;
      rec.autoHeader    := autoHeader;
      rec.autoShape     := autoShape;
      rec.separator     := sep;
      rec.commentMarker := commentMarker;
      rec.firstLine     := firstLine;
      rec.lastLine      := lastLine;
      rec.columnNames   := columnNames;
      rec.dataTypes     := dataTypes;
      self.tableClient->read_ascii(rec);
      await self.tableClient->read_ascii_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.tableNames := function()
    {
      local result;
      self.tableClient->get_open_tables();
      await self.tableClient->get_open_tables_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.tableName := function(object)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      self.tableClient->get_name(object.id);
      await self.tableClient->get_name_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.recoverTableHandle := function(tableName)
    {
      local result;
      self.tableClient->get_id(tableName);
      await self.tableClient->get_id_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      local object;
      object.type := 'table';
      object.id := $value;
      object.file := tableName;
      return object;
    }
  
  const public.tableExists := function(const object)
    {
      local result;
      local rec;
      if (type_name(object) == "string") {
	rec.tableName := object;
      }else{
        result:=self.checkTableHandle (object);
        if(is_fail(result)) return result;
	rec.tableId := object.id;
      }
      self.tableClient->is_readable(rec);
      await self.tableClient->is_readable_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.tableIsWritable := function(const object)
    {
      local result;
      local rec;
      if (type_name(object) == "string") {
	rec.tableName := object;
      }else{
         result:=self.checkTableHandle (object);
         if(is_fail(result)) return result;
  	rec.tableId := object.id;
      }
      self.tableClient->is_writable(rec);
      await self.tableClient->is_writable_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.tableInfo := function(const object)
    {
      local result;
      local rec;
      if (type_name(object) == "string") {
	rec.tableName := object;
      }else{
        result:=self.checkTableHandle (object);
        if(is_fail(result)) return result;
	rec.tableId := object.id;
      }
      self.tableClient->table_info(rec);
      await self.tableClient->table_info_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.putTableInfo := function(const object, const value)
    {
      local result;
      local rec;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      rec.value := value
	self.tableClient->put_table_info(rec);
      await self.tableClient->put_table_info_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.addReadmeLine := function(const object, const value)
    {
      local result;
      local rec;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      rec.value := value
	self.tableClient->add_readme_line(rec);
      await self.tableClient->add_readme_line_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.columnNames := function(const object)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      self.tableClient->column_names(object.id);
      await self.tableClient->column_names_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.isScalarColumn := function(const object, columnName)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      rec.column := columnName;
      self.tableClient->is_scalar_column(rec);
      await self.tableClient->is_scalar_column_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.columnDataType := function (const object, columnName)
# the table client returns a string
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      rec.column := columnName;
      self.tableClient->column_data_type (rec);
      await self.tableClient->column_data_type_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.columnArrayType := function (const object, columnName)
# the table client returns a string
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      rec.column := columnName;
      self.tableClient->column_array_type (rec);
      await self.tableClient->column_array_type_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  
  const public.tableShape := function(const object)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      self.tableClient->shape(object.id);
      await self.tableClient->shape_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.numberOfColumns := function(const object)
    {
      return public.tableShape(object)[1];
    }
  const public.numberOfRows := function(const object)
    {
      return public.tableShape(object)[2];
    }

  const public.rowNumbers := function(const object, const tab2)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      rec.tableId2 := -1;
      if (is_record(tab2)) rec.tableId2 := tab2.id;
      self.tableClient->row_numbers (rec);
      await self.tableClient->row_numbers_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.setMaximumCacheSize := function(const object, columnName, nbytes)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.nbytes := nbytes;
      self.tableClient->set_max_cache_size(rec);
      await self.tableClient->set_max_cache_size_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.cellContentsDefined := function (const object, columnName, rownr)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.row := rownr-1;
      self.tableClient->cell_contents_defined (rec);
      await self.tableClient->cell_contents_defined_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  
  const public.getCell := function (const object, columnName, rownr)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.row := rownr-1;
      self.tableClient->get_cell(rec);
      await self.tableClient->get_cell_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.getCellSlice := function (const object, columnName, rownr,
                                         blc, trc, inc=F)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.row := rownr-1;
      rec.blc := blc-1;
      rec.trc := trc-1;
      if (type_name(inc) != 'boolean') {
        rec.inc := inc;
      }
      self.tableClient->get_cell_slice(rec);
      await self.tableClient->get_cell_slice_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.getColumn := function(const object, columnName,
                                     startRow=1, nrow=-1, rowIncr=1)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.row := startRow-1;
      rec.nrow := nrow;
      rec.rowincr := rowIncr;
      self.tableClient->get_column(rec);
      await self.tableClient->get_column_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.getVarColumn := function(const object, columnName,
					startRow=1, nrow=-1, rowIncr=1)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.row := startRow-1;
      rec.nrow := nrow;
      rec.rowincr := rowIncr;
      self.tableClient->get_var_column(rec);
      await self.tableClient->get_var_column_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.getColumnSlice := function(const object, columnName,
                                          blc, trc, inc=F,
                                          startRow=1, nrow=-1, rowIncr=1)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.blc := blc-1;
      rec.trc := trc-1;
      if (type_name(inc) != 'boolean') {
        rec.inc := inc;
      }
      rec.row := startRow-1;
      rec.nrow := nrow;
      rec.rowincr := rowIncr;
      self.tableClient->get_column_slice(rec);
      await self.tableClient->get_column_slice_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.putCell := function(const object, columnName, rownr, value)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.value := value;
      rec.row := rownr-1;
      self.tableClient->put_cell(rec);
      await self.tableClient->put_cell_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.putCellSlice := function(const object, columnName, rownr, value,
                                        blc, trc, inc=F)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.value := value;
      rec.row := rownr-1;
      rec.blc := blc-1;
      rec.trc := trc-1;
      if (type_name(inc) != 'boolean') {
        rec.inc := inc;
      }
      self.tableClient->put_cell_slice(rec);
      await self.tableClient->put_cell_slice_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.putColumn := function(const object, columnName, value,
                                     startRow=1, nrow=-1, rowIncr=1)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.value := value;
      rec.row := startRow-1;
      rec.nrow := nrow;
      rec.rowincr := rowIncr;
      self.tableClient->put_column(rec);
      await self.tableClient->put_column_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.putVarColumn := function(const object, columnName, value,
					startRow=1, nrow=-1, rowIncr=1)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.value := value;
      rec.row := startRow-1;
      rec.nrow := nrow;
      rec.rowincr := rowIncr;
      self.tableClient->put_var_column(rec);
      await self.tableClient->put_var_column_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.putColumnSlice := function(const object, columnName, value,
                                          blc, trc, inc=F,
                                          startRow=1, nrow=-1, rowIncr=1)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.value := value;
      rec.blc := blc-1;
      rec.trc := trc-1;
      if (type_name(inc) != 'boolean') {
        rec.inc := inc;
      }
      rec.row := startRow-1;
      rec.nrow := nrow;
      rec.rowincr := rowIncr;
      self.tableClient->put_column_slice(rec);
      await self.tableClient->put_column_slice_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.getColumnShapeString := function(const object, columnName,
                                                startRow=1, nrow=-1, rowIncr=1)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.row := startRow-1;
      rec.nrow := nrow;
      rec.rowincr := rowIncr;
      self.tableClient->get_column_shape_string(rec);
      await self.tableClient->get_column_shape_string_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.getTableKeyword := function(const object, keyword)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.keyword := keyword;
      self.tableClient->get_keyword(rec);
      await self.tableClient->get_keyword_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.getTableKeywordSet := function(const object)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      self.tableClient->get_keywordset(rec);
      await self.tableClient->get_keywordset_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.getColumnKeyword := function(const object, columnName, keyword)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.keyword := keyword;
      self.tableClient->get_keyword(rec);
      await self.tableClient->get_keyword_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.getColumnKeywordSet := function(const object, columnName)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      self.tableClient->get_keywordset(rec);
      await self.tableClient->get_keywordset_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.putTableKeyword := function(const object, keyword, value,
					   makesubrecord)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.keyword := keyword;
      rec.makesubrecord := makesubrecord;
      rec.value := value;
      self.tableClient->put_keyword(rec);
      await self.tableClient->put_keyword_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.putTableKeywordSet := function(const object, value)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.value := value;
      self.tableClient->put_keywordset(rec);
      await self.tableClient->put_keywordset_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.putColumnKeyword := function(const object, columnName, keyword, value, makesubrecord)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.keyword := keyword;
      rec.makesubrecord := makesubrecord;
      rec.value := value;
      self.tableClient->put_keyword(rec);
      await self.tableClient->put_keyword_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.putColumnKeywordSet := function(const object, columnName, value)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.value := value;
      self.tableClient->put_keywordset(rec);
      await self.tableClient->put_keywordset_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.removeTableKeyword := function(const object, keyword)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.keyword := keyword;
      self.tableClient->remove_keyword(rec);
      await self.tableClient->remove_keyword_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.removeColumnKeyword := function(const object, columnName, keyword)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.keyword := keyword;
      self.tableClient->remove_keyword(rec);
      await self.tableClient->remove_keyword_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.getFieldNames := function(const object, columnName, keyword)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.keyword := keyword;
      self.tableClient->get_fieldnames(rec);
      await self.tableClient->get_fieldnames_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.addColumns := function(const object, const tableDesc,
				      const dminfo)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.tableDesc := tableDesc;
      rec.dminfo := dminfo;
      self.tableClient->add_columns(rec);
      await self.tableClient->add_columns_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.renameColumn := function(const object, const nameNew,
					const nameOld)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.nameNew := nameNew;
      rec.nameOld := nameOld;
      self.tableClient->rename_column(rec);
      await self.tableClient->rename_column_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.removeColumns := function(const object, const columns)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.columns := columns;
      self.tableClient->remove_columns(rec);
      await self.tableClient->remove_columns_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.addRows := function(const object, nrow=1)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.nrow := nrow;
      self.tableClient->extend(rec);
      await self.tableClient->extend_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.removeRows := function(const object, rowNumbers)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.rowNumbers := rowNumbers;
      self.tableClient->remove_row(rec);
      await self.tableClient->remove_row_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.scalarColumnDesc := function (columnName, value,
					     dataManagerType="", 
					     dataManagerGroup="",
					     options=0, maxlen=0, comment="")
    {
      local rec2;
      rec2.valueType := type_name(value);
      rec2.dataManagerType := dataManagerType;
      rec2.dataManagerGroup := dataManagerGroup;
      rec2.option := options;
      rec2.maxlen := maxlen;
      rec2.comment := comment;
      local rec;
      rec.name := columnName;
      rec.desc := rec2;
      return rec;
    }
  
  const public.arrayColumnDesc := function (columnName, value, ndim=0, shape=F,
					    dataManagerType="",
					    dataManagerGroup="", 
					    options=0, maxlen=0, comment="")
    {
      local rec2;
      rec2.valueType := type_name(value);
      rec2.dataManagerType := dataManagerType;
      rec2.dataManagerGroup := dataManagerGroup;
      rec2.ndim := ndim;
      if (type_name(shape) != 'boolean') {
        rec2.shape := shape;
	if (rec2.ndim <= 0) {
	  rec2.ndim := len(shape);
	}
      }
      rec2.option := options;
      rec2.maxlen := maxlen;
      rec2.comment := comment;
      local rec;
      rec.name := columnName;
      rec.desc := rec2;
      return rec;
    }
  
  const public.tableDesc := function(const columnDesc1, ...)
    {
      local rec;
      rec[columnDesc1.name] := columnDesc1.desc;
      if (num_args(...) > 0)
	for ( i in 1:num_args(...) ) {
	  name := nth_arg(i, ...).name;
          if (has_field(rec, name)) {
	    fail paste('tableserver.tableDesc: column name', name,
		       'multiply used');
	  }
	  rec[name] := nth_arg(i, ...).desc;
        }
      return rec;
    }
  
  const public.getTableDesc := function(const object, actual=T)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.actual := actual;
      self.tableClient->get_table_desc(rec);
      await self.tableClient->get_table_desc_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.getDMinfo := function(const object)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      self.tableClient->get_dm_info(rec);
      await self.tableClient->get_dm_info_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.getColumnDesc := function(const object, columnName, actual=T)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rec;
      rec.tableId := object.id;
      rec.column := columnName;
      rec.actual := actual;
      self.tableClient->get_column_desc(rec);
      await self.tableClient->get_column_desc_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.tableSelectRows := function(const object, const rownumbers, name)
    {
      local result;
      local objout;
      objout.type := 'table';
      local rec;
      rec.tableId := object.id;
      rec.rowNumbers := rownumbers;
      rec.tableName := name;
      self.tableClient->select_rows(rec);
      await self.tableClient->select_rows_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      result := $value;
      objout.id := result.tableId;
      objout.file := result.tableName;
      return objout;
    }
  
  const public.tableCommand := function(comm, ...)
    {
      local result;
      local object;
      object.type := 'table';
      local rec;
      local idrec;
      # Substitute possible tables given as $name.
      # Their handle-ids are stored in idrec.
      # The first nrid entries in idrec are reserved for temporary tables
      # passed in to this command. They can be referenced in the command
      # using $i where i must be in the range 1-nrid.
      nrid := num_args(...);
      rec.command := substitute(comm, 'table', nrid+1, idrec);
      if (idrec.nr > 0) {
        ids := array(-1, idrec.nr);
        if (nrid > 0) {
          for (i in 1:nrid) {
            handle := nth_arg(i, ...);
            result := self.checkTableHandle (handle);
	    if (is_fail(result)) return result;
	    ids[i] := handle.id;
          }
        }
	if (idrec.nr > nrid) {
	  for (i in (nrid+1):(idrec.nr)) {
            ids[i] := idrec[i+1];
          }
        }
        rec.tableIds := ids;
      } else {
        rec.tableIds := [];
      }
      self.tableClient->command(rec);
      await self.tableClient->command_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      result := $value;
      object.id := $value.tableId;
      object.file := $value.tableName;
      object.values := $value.values;
      return object;
    }
  
  const public.makeTableIterator := function(const object, columnNames,
	                                     order, sort)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local iterObject;
      iterObject.type := 'tableIterator';
      local rec;
      rec.tableId := object.id;
      rec.columnNames := columnNames;
      rec.order := order;
      if (is_boolean(sort)) {
        rec.sort := 'h';            # heapsort
        if (!sort) {
	  rec.sort := 'n';          # nosort
        }
      } else {
        rec.sort := sort;
      }
      self.tableClient->make_iterator(rec);
      await self.tableClient->make_iterator_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      result := $value;
      local obj := object;
      obj.id := result.tableId;
      obj.file := "";
      iterObject.id := result.iterId;
      iterObject.handle := obj;
      iterObject.inputHandle := object;
      return iterObject;
    }
  
  const public.stepTableIterator := function(const iterObject)
    {
      local result;
      result:=self.checkTableIterHandle (iterObject);
      if(is_fail(result)) return result;
      self.tableClient->step_iterator(iterObject.id);
      await self.tableClient->step_iterator_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.closeTableIterator := function(const iterObject)
    {
      local result;
      result:=self.checkTableIterHandle (iterObject);
      if(is_fail(result)) return result;
      self.tableClient->close_iterator(iterObject.id);
      await self.tableClient->close_iterator_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.makeTableRow := function(const object, columnNames='', exclude=F)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local rowObject;
      rowObject.type := 'tableRow';
      local rec;
      rec.tableId := object.id;
      if (is_string(columnNames) && columnNames!='') {
        rec.columnNames := columnNames;
        rec.exclude     := exclude;	
      }
      self.tableClient->make_row(rec);
      await self.tableClient->make_row_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      rowObject.id := $value;
      return rowObject;
    }
  
  const public.getRow := function (const rowObject, rownr)
    {
      local result;
      result:=self.checkTableRowHandle (rowObject);
      if(is_fail(result)) return result;
      local rec;
      rec.rowId := rowObject.id;
      rec.row := rownr-1;
      self.tableClient->get_row (rec);
      await self.tableClient->get_row_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.putRow := function(const rowObject, rownr, value)
    {
      local result;
      result:=self.checkTableRowHandle (rowObject);
      if(is_fail(result)) return result;
      local rec;
      rec.rowId := rowObject.id;
      rec.value := value;
      rec.row := rownr-1;
      rec.matchingFields := F;
      self.tableClient->put_row(rec);
      await self.tableClient->put_row_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.putRowMatchingFields := function(const rowObject, rownr, value)
    {
      local result;
      result:=self.checkTableRowHandle (rowObject);
      if(is_fail(result)) return result;
      local rec;
      rec.rowId := rowObject.id;
      rec.value := value;
      rec.row := rownr-1;
      rec.matchingFields := T;
      self.tableClient->put_row(rec);
      await self.tableClient->put_row_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.closeTableRow := function(const rowObject)
    {
      local result;
      result:=self.checkTableRowHandle (rowObject);
      if(is_fail(result)) return result;
      self.tableClient->close_row(rowObject.id);
      await self.tableClient->close_row_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.makeTableIndex := function(const object, columnNames, sort=T)
    {
      local result;
      result:=self.checkTableHandle (object);
      if(is_fail(result)) return result;
      local indexObject;
      indexObject.type := 'tableIndex';
      indexObject.columnNames := columnNames;
      local rec;
      rec.tableId := object.id;
      rec.columnNames := columnNames;
      rec.sort        := sort;
      self.tableClient->make_index(rec);
      await self.tableClient->make_index_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      indexObject.id := $value;
      return indexObject;
    }
  
  const public.indexIsUnique := function (const indexObject)
    {
      local result;
      result:=self.checkTableIndexHandle (indexObject);
      if(is_fail(result)) return result;
      local rec;
      rec.indexId := indexObject.id;
      self.tableClient->index_isunique (rec);
      await self.tableClient->index_isunique_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.indexSetChanged := function (const indexObject, columnNames)
    {
      local result;
      result:=self.checkTableIndexHandle (indexObject);
      if(is_fail(result)) return result;
      local rec;
      rec.indexId := indexObject.id;
      rec.columnNames := columnNames;
      self.tableClient->index_setchanged (rec);
      await self.tableClient->index_setchanged_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.indexGetRowNumber := function(const indexObject, key)
    {
      local result;
      result:=self.checkTableIndexHandle (indexObject);
      if(is_fail(result)) return result;
      local rec;
      rec.indexId := indexObject.id;
      if (is_record(key)) {
	  rec.key := key;
      } else {
	  if (length(indexObject.columnNames) != 1) {
	      fail 'key has to be given as record for multi-column index';
	  }
	  reckey := [=];
	  reckey[indexObject.columnNames] := key;
	  rec.key := reckey;
      }
      self.tableClient->index_getrownumber(rec);
      await self.tableClient->index_getrownumber_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.indexGetRowNumbers := function(const indexObject,
					      lowerKey, upperKey=unset,
					      lowerIncl=T, upperIncl=T)
    {
      local result;
      result:=self.checkTableIndexHandle (indexObject);
      if(is_fail(result)) return result;
      local rec;
      rec.indexId := indexObject.id;
      if (is_record(lowerKey)) {
	  rec.lowerKey := lowerKey;
      } else {
	  if (length(indexObject.columnNames) != 1) {
	      fail 'key has to be given as record for multi-column index';
	  }
	  reckey := [=];
	  reckey[indexObject.columnNames] := lowerKey;
	  rec.lowerKey := reckey;
      }
      if (! is_unset(upperKey)) {
	  if (is_record(upperKey)) {
	      rec.upperKey := upperKey;
	  } else {
	      if (length(indexObject.columnNames) != 1) {
		  fail 'key has to be given as record for multi-column index';
	      }
	      reckey := [=];
	      reckey[indexObject.columnNames] := upperKey;
	      rec.upperKey := reckey;
	  }
	  rec.lowerIncl := lowerIncl;
	  rec.upperIncl := upperIncl;
      }
      self.tableClient->index_getrownumbers(rec);
      await self.tableClient->index_getrownumbers_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  const public.closeTableIndex := function(const indexObject)
    {
      local result;
      result:=self.checkTableIndexHandle (indexObject);
      if(is_fail(result)) return result;
      self.tableClient->close_index(indexObject.id);
      await self.tableClient->close_index_result;
      result:=self.checkTableResult($value);
      if(is_fail(result)) return result;
      return $value;
    }
  
  public.initialize();

  return public;

}

defaulttableserver:=tableserver();
