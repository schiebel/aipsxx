# table.g: table object
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
#   $Id: table.g,v 19.9 2006/11/10 01:26:06 gvandiep Exp $
#
#----------------------------------------------------------------------------

# Still to be done: 

pragma include once

include "tableserver.g";
include "note.g";
include "unset.g";

# check to see if this is a valid table object
#------------------------------------------------------------------------------
  const is_table := function(tab) {
    return is_record(tab)&&has_field(tab, 'ok')&&is_function(tab.ok)&&tab.ok();
  }

# Define table object
#------------------------------------------------------------------------------


table:=function(tablename=F, tabledesc=F, nrow=0, readonly=T,
		lockoptions='default', ack=T, dminfo=F, endian='aipsrc',
		memorytable=F,
		tableserver=defaulttableserver, tablenote=note, handle=F)
{

  self:=[=];
  public:=[=];

  self.ack:=ack;
  self.handle:=handle;
  self.server:=tableserver;
  self.note:=tablenote;
  self.readonly:=readonly;
  self.tableRow:=F;
  self.tablebrowser:=F;
  
  if(!is_record(tabledesc) || is_unset(tabledesc)) {
      tabledesc:=F;
  }
  if(!is_record(dminfo) || length(dminfo)==0 || is_unset(dminfo)) {
      dminfo:=F;
  }
#
# Private functions
#------------------------------------------------------------------------------

  const public.type:=function() {return 'table';}

  const public.ok:=function() {
    if(is_fail(self.server)) fail paste("tableserver is invalid: ",
					self.server::message);
    if(is_boolean(self.handle)) fail "invalid: no handle";
    return T;
  }
  
# Make a table object from an existing table 
  const public.open := function(tablename, readonly=T, lockoptions='default')
    {
      wider self;
      if(readonly) {
        self.handle:=self.server.openTable(tablename, self.ack,
                                           lockoptions);
        if(is_fail(self.handle)) fail;
        return T;
      } else {
        self.handle:=self.server.openTableForUpdate(tablename, self.ack,
                                                    lockoptions);
        if(is_fail(self.handle)) fail;
        return T;
      }
      if(is_boolean(self.handle)) {
	fail "invalid handle";
      } else {
        if(self.ack) self.note(paste('opened table',tablename), 
			       priority= 'NORMAL', origin='table.open');
	return T;
      }
    }
  
# create a table object from a table descriptor and a number of rows
  const self.create := function (tablename, tabledesc, dminfo,
				 nrow, lockoptions, endian, memorytable)
  {
      wider self;
      memtype := 'plain';
      if (memorytable) memtype := 'memory';
      self.handle:=self.server.createTable(tablename, tabledesc, dminfo,
					   nrow, self.ack, lockoptions,
					   endian, memtype);
      if(is_fail(self.handle)) fail;
      self.readonly := F;
      if(nrow>0) {
	  if(self.ack) self.note(paste('created', memtype, 'table', tablename,
				       'with', nrow, 'rows'), 
				 priority= 'NORMAL', origin='table.create');
      } else {
	  if(self.ack) self.note(paste('created', memtype, 'table', tablename,
				       'with zero rows'), 
				 priority= 'NORMAL', origin='table.create');
      }
      return T;
  }

# Public functions
#------------------------------------------------------------------------------

# return table handle: really a friend!
  const public.handle := function()
  {
    return self.handle;
  }

# return table server: really a friend!
  const public.server := function()
  {
    return self.server;
  }

# write to ascii
  const public.toascii := function(asciifile, headerfile='', columns='',
				   sep=' ')
  {
    include 'table_a.g';
    return tabletoascii (public, asciifile, headerfile, columns, sep);
  }
  
# browse a table
  const public.browse := function()
  {
    wider self;
    if(!have_gui()) fail "No GUI available";
    name:=public.name();
    if(!is_boolean(name)) {
      include "tablebrowser.g";
      if(!is_agent(self.tablebrowser)){
         self.tablebrowser:=tablebrowser(public);
      } else {
         self.tablebrowser->map();
      }
      return T;
    } else {
      return F;
    } 
  }
  
# flush
  const public.flush:=function(recursive=F)
  {
    if(is_fail(public.ok())) fail;
    return self.server.flush(self.handle, recursive);
  }
  
# resync
  const public.resync:=function()
  {
    if(is_fail(public.ok())) fail;
    return self.server.resync(self.handle);
  }
  
# copy
  const public.copy:=function(newtablename, deep=F, valuecopy=F, dminfo=[=],
			      endian='aipsrc', memorytable=F,
			      returnobject=F, copynorows=F)
  {
    if(is_fail(public.ok())) fail;
    public.flush();
    memtype := 'plain';
    if (memorytable) memtype := 'memory';
    return self.server.copyTable(self.handle, newtablename, deep, valuecopy,
				 dminfo, endian, memtype, copynorows,
				 returnobject);
  }
  
# copyrows
  const public.copyrows:=function(outtable, startrowin=1, startrowout=-1,
				  nrow=-1)
  {
    if(is_fail(public.ok())) fail;
    if(is_fail(outtable.ok())) fail;
    return self.server.copyRows(self.handle, outtable.handle(),
				startrowin, startrowout, nrow);
  }
  
# close
  const public.close:=function(unmap=T)
  {
    if(is_fail(public.ok())) fail;
    wider self;
    if(is_fail(self.server.closeTable(self.handle))) fail;
    if(unmap){
       if(is_agent(self.tablebrowser)){
          self.tablebrowser->close();
          self.tablebrowser := F;
       }
    }
    self.handle:=F;
    return T;
  }

# done
  const public.done:=function()
  {
    wider self, public;
    public.close(unmap=T);
    val self := F;
    val public := F;
    return T;
  }

# is the table writable
  const public.iswritable:=function() {
    if(is_fail(public.ok())) fail;
    return self.server.tableIsWritable(self.handle)==1;
  }
  
# endian format
  const public.endianformat:=function() {
    if(is_fail(public.ok())) fail;
    return self.server.endianFormat(self.handle);
  }
  
# lock
  const public.lock:=function(write=T, nattempts=0) {
    if(is_fail(public.ok())) fail;
    return self.server.lock(self.handle, write, nattempts);
  }
  
# unlock
  const public.unlock:=function() {
    if(is_fail(public.ok())) fail;
    return self.server.unlock(self.handle);
  }
  
# datachanged
  const public.datachanged:=function() {
    if(is_fail(public.ok())) fail;
    return self.server.hasDataChanged(self.handle);
  }
  
# haslock
  const public.haslock:=function(write=T) {
    if(is_fail(public.ok())) fail;
    return self.server.hasLock(self.handle, write);
  }
  
# lockoptions
  const public.lockoptions:=function() {
    if(is_fail(public.ok())) fail;
    return self.server.lockOptions(self.handle);
  }
  
# ismultiused
  const public.ismultiused:=function(checksubtables=F) {
    if(is_fail(public.ok())) fail;
    return self.server.isMultiUsed(self.handle, checksubtables);
  }
  
# Return name of this table
  const public.name := function() {
    if(is_fail(public.ok())) fail;
    return self.server.tableName(self.handle);
  }    
  
# Create a new (named) table from row numbers
  const public.selectrows := function(rownrs, name='') {
    if(is_fail(public.ok())) fail;
    local myhandle;
    myhandle:=self.server.tableSelectRows(self.handle, rownrs, name);
    if (is_fail(myhandle)) fail;
    return table(handle=myhandle);
  }

# Create a new (named) table from a query of the sort "TIME > 54500.45";
  const public.query := function(query='', name='', sortlist='',
                                 columns='', style='') {
    if(is_fail(public.ok())) fail;
    if (is_unset(query)  ||  (query=='' && sortlist=='' && columns=='')) {
      if (!have_gui()) {
	fail 'No selection (arguments query, sortlist, and columns are empty)';
      }
      include 'taqlwidget.g';
      tw := taqlwidget (public.getdesc(), canselect=T, cansort=T, cangiving=T,
			giving=name);
      if (is_fail(tw)) {
	fail;
      }
      await tw->returns;
      rec := $value;
      query := rec.where;
      name := rec.giving;
      sortlist := rec.orderby;
      columns := rec.select;
      if (query=='' && name=='' && sortlist=='' && columns=='') {
	return F;
      }
    }
    command:= 'select';
    if (is_string(columns) && columns!='') {
      command:=paste (command, columns);
    }
    command:= paste (command, 'from $1');
    if (is_string(query) && query!='') {
      command:=paste (command, 'where', query);
    }
    if (is_string(sortlist) && sortlist!='') {
      command:=paste (command, 'orderby', sortlist);
    }
    if (is_string(name) && name!='') {
      command:=paste (command, 'giving', name);
    }
    return tablecommand(command, style, self.handle);
  }

# Calculate an expression on the table.
  const public.calc := function(expr, style='') {
    command:= paste ('calc from $1 calc', expr);
    return tablecommand(command, style, self.handle);
  }

# get the info
  const public.info := function() {
    if(is_fail(public.ok())) fail;
    return self.server.tableInfo(self.handle);     
  }

# set the info
  const public.putinfo := function(const value) {
    if(is_fail(public.ok())) fail;
    return self.server.putTableInfo(self.handle, value);
  }
  
# add a ReadmeLine
  const public.addreadmeline := function(const value) {
    if(is_fail(public.ok())) fail;
    return self.server.addReadmeLine(self.handle, value);
  }
  
# log a summary consisting of name, shape, info, keywords, column
# names and keywords
  const public.summary := function(recurse=F) {
    if(is_fail(public.ok())) fail;
    self.note(paste("Table summary: ", public.name()), 
	      priority= 'NORMAL', origin='table.summary');
    self.note(paste("Shape: ", public.ncols(),
		    "columns by ", public.nrows(), "rows"),
	      priority= 'NORMAL', origin='table.summary');
    self.note(paste("Info: ", public.info()),
	      priority= 'NORMAL', origin='table.summary');
    keys:=public.getkeywords();
    if(len(keys)) {
      self.note(paste("Table keywords:", keys),
		priority= 'NORMAL', origin='table.summary');
      if(recurse) {
        for (key in field_names(keys)) {
          wider public;
          if(tableexists(keys[key])) {
	    self.note(paste("Summarizing subtable:", keys[key]), 
		      priority= 'NORMAL', origin='table.summary');
            local lt:=table(keys[key]);
            if(!lt.summary(recurse)) break;
            lt.done();
	  }
	}
      }
    }
    columns:=public.colnames();
    if(len(columns)) {
      self.note(paste("Columns:", columns),
		priority= 'NORMAL', origin='table.summary');
      for (column in columns) {
        keys:=public.getcolkeywords(column);
        if(len(keys)) self.note(paste(column, "keywords:", keys),
				priority= 'NORMAL', origin='table.summary');
      }
    }
    return T;
  }

# set maximum cache size
  const public.setmaxcachesize := function(columnname, nbytes) {
    if(is_fail(public.ok())) fail;
    return self.server.setMaximumCacheSize(self.handle, columnname, nbytes);
  }

# return row numbers
  const public.rownumbers := function (tab=F) {
    if(is_fail(public.ok())) fail;
    hand := F;
    if (is_record(tab)) hand := tab.handle();
    return self.server.rowNumbers(self.handle, hand);
  }

# return column names
  const public.colnames := function() {
    if(is_fail(public.ok())) fail;
    return self.server.columnNames(self.handle);
  }

# is the specified column scalar?
  const public.isscalarcol := function(columnname) {
    if(is_fail(public.ok())) fail;
    return self.server.isScalarColumn(self.handle, columnname);
  }
  
# tell if the column contains variable shaped arrays
  const public.isvarcol := function(columnname) {
    if(is_fail(public.ok())) fail;
    desc := public.getcoldesc(columnname);
    return has_field(desc,'ndim') && !has_field(desc,'shape');
  }

# return data type of specified column
  const public.coldatatype := function(columnname) {
    if(is_fail(public.ok())) fail;
    return self.server.columnDataType(self.handle, columnname);
  }
  
  const public.colarraytype := function(columnname) {
    if(is_fail(public.ok())) fail;
    return self.server.columnArrayType(self.handle, columnname);
  }
  
  const public.ncols := function() {
    if(is_fail(public.ok())) fail;
    return self.server.numberOfColumns(self.handle);
  }
  
  const public.nrows := function() {
    if(is_fail(public.ok())) fail;
    return self.server.numberOfRows(self.handle);
  }

# add columns
  const public.addcols := function(desc, dminfo=[=]) {
    if(is_fail(public.ok())) fail;
    if(len(desc)==2 && has_field(desc,'name') && has_field(desc,'desc')) {
	return self.server.addColumns(self.handle, tablecreatedesc(desc),
				      dminfo);
    }
    return self.server.addColumns(self.handle, desc, dminfo);
  }
  
# rename column
  const public.renamecol := function(oldname, newname) {
    if(is_fail(public.ok())) fail;
    return self.server.renameColumn(self.handle, newname, oldname);
  }
  
# remove columns
  const public.removecols := function(columnnames) {
    if(is_fail(public.ok())) fail;
    return self.server.removeColumns(self.handle, columnnames);
  }
  
# add rows
  const public.addrows := function(nrow=1) {
    if(is_fail(public.ok())) fail;
    return self.server.addRows(self.handle, nrow);
  }
  
# remove rows
  const public.removerows := function(rownrs) {
   if(is_fail(public.ok())) fail;
    return self.server.removeRows(self.handle, rownrs);
  }

# Does a cell contain a defined value?
  const public.iscelldefined := function (columnname, rownr) {
    if(is_fail(public.ok())) fail;
    return self.server.cellContentsDefined(self.handle, columnname, rownr);
  }

# Get the cell contents
  const public.getcell := function (columnname, rownr) {
    if(is_fail(public.ok())) fail;
    return self.server.getCell(self.handle, columnname, rownr);
  }
  
# Get the cell slice
  const public.getcellslice := function (columnname, rownr, blc, trc, inc=F) {
    if(is_fail(public.ok())) fail;
    return self.server.getCellSlice(self.handle, columnname,
                                    rownr, blc, trc, inc);
  }
  
# Get the specified column
  const public.getcol := function (columnname, startrow=1, nrow=-1, rowincr=1) {
    if(is_fail(public.ok())) fail;
    return self.server.getColumn(self.handle, columnname,
                                 startrow, nrow, rowincr);
  }
  
# Get the specified column as record containing variable arrays
  const public.getvarcol := function (columnname, startrow=1, nrow=-1, rowincr=1) {
    if(is_fail(public.ok())) fail;
    return self.server.getVarColumn(self.handle, columnname,
				    startrow, nrow, rowincr);
  }
  
# Get the specified column slice
  const public.getcolslice := function (columnname, blc, trc, inc=F,
                                        startrow=1, nrow=-1, rowincr=1) {
    if(is_fail(public.ok())) fail;
    return self.server.getColumnSlice(self.handle, columnname, blc, trc, inc,
                                      startrow, nrow, rowincr);
  }
  
# Put the cell contents
  const public.putcell := function (columnname, rownr, value) {
    if(is_fail(public.ok())) fail;
    return self.server.putCell(self.handle, columnname, rownr, value);
  }
  
# Put the cell slice
  const public.putcellslice := function (columnname, rownr, value,
                                         blc, trc, inc=F) {
    if(is_fail(public.ok())) fail;
    return self.server.putCellSlice(self.handle, columnname, rownr, value,
                                    blc, trc, inc);
  }
  
# Put the specified column
  const public.putcol := function (columnname, value,
                                   startrow=1, nrow=-1, rowincr=1) {
    if(is_fail(public.ok())) fail;
    return self.server.putColumn(self.handle, columnname, value,
                                 startrow, nrow, rowincr);
  }

# Get the specified column from record containing variable arrays
  const public.putvarcol := function (columnname, value,
				      startrow=1, nrow=-1, rowincr=1) {
    if(is_fail(public.ok())) fail;
    return self.server.putVarColumn(self.handle, columnname, value,
				    startrow, nrow, rowincr);
  }
  
# Put the specified column slice
  const public.putcolslice := function (columnname, value, blc, trc, inc=F,
                                        startrow=1, nrow=-1, rowincr=1) {
    if(is_fail(public.ok())) fail;
    return self.server.putColumnSlice(self.handle, columnname, value,
                                      blc, trc, inc, startrow, nrow, rowincr);
  }

# Get the shapes of the arrays in the specified column.
  const public.getcolshapestring := function (columnname, startrow=1,
                                              nrow=-1, rowincr=1) {
    if(is_fail(public.ok())) fail;
    return self.server.getColumnShapeString(self.handle, columnname,
                                            startrow, nrow, rowincr);
  }


# The next set of functions are dealing with table and column keywords.

# Get a specified table keyword
  const public.getkeyword := function(keyword) {
    if(is_fail(public.ok())) fail;
    return self.server.getTableKeyword(self.handle, keyword);
  }
  
# Get the set of all keywords
  const public.getkeywords := function() {
    if(is_fail(public.ok())) fail;
    return self.server.getTableKeywordSet(self.handle);
  }
  
# Get a specified column keyword
  const public.getcolkeyword := function(columnname, keyword) {
    if(is_fail(public.ok())) fail;
    return self.server.getColumnKeyword(self.handle, columnname, keyword);
  }
  
# Get the set of all column keywords
  const public.getcolkeywords := function(columnname) {
    if(is_fail(public.ok())) fail;
    return self.server.getColumnKeywordSet(self.handle, columnname);
  }

# Put the specified table keyword
  const public.putkeyword := function(keyword, value, makesubrecord=F) {
    if(is_fail(public.ok())) fail;
    if (is_table(value)) {
      value := paste('Table:', value.name());
    }
    return self.server.putTableKeyword(self.handle, keyword, value,
				       makesubrecord);
  }
  
# Put the set of table keywords
  const public.putkeywords := function(value) {
    if(is_fail(public.ok())) fail;
    return self.server.putTableKeywordSet(self.handle, value);
  }
  
# Put the specified column keyword
  const public.putcolkeyword := function(columnname, keyword,
					 value, makesubrecord=F) {
    if(is_fail(public.ok())) fail;
    if (is_table(value)) {
      value := paste('Table:', value.name());
    }
    return self.server.putColumnKeyword(self.handle, columnname, keyword,
					value, makesubrecord);
  }

# Put the set of column keywords
  const public.putcolkeywords := function(columnname, value) {
    if(is_fail(public.ok())) fail;
    return self.server.putColumnKeywordSet(self.handle, columnname, value);
  }
  
# Remove the specified table keyword
  const public.removekeyword := function(keyword) {
    if(is_fail(public.ok())) fail;
    return self.server.removeTableKeyword(self.handle, keyword);
  }
  
# Remove the specified column keyword
  const public.removecolkeyword := function(columnname, keyword) {
    if(is_fail(public.ok())) fail;
    return self.server.removeColumnKeyword(self.handle, columnname, keyword);
  }
  
# Get the names of all table keywords.
  const public.keywordnames := function() {
    if(is_fail(public.ok())) fail;
    return self.server.getFieldNames (self.handle, '', '');
  }
  
# Get the names of all keywords in given column.
  const public.colkeywordnames := function (columnname) {
    if(is_fail(public.ok())) fail;
    return self.server.getFieldNames (self.handle, columnname, '');
  }
  
# Get the names of all fields in a table keyword.
  const public.fieldnames := function (keyword='') {
    if(is_fail(public.ok())) fail;
    return self.server.getFieldNames (self.handle, '', keyword);
  }
  
# Get the names of all fields in a column keyword.
  const public.colfieldnames := function (columnname, keyword='') {
    if(is_fail(public.ok())) fail;
    return self.server.getFieldNames (self.handle, columnname, keyword);
  }
  
# get the data manager info
  const public.getdminfo := function() {
    if(is_fail(public.ok())) fail;
    return self.server.getDMinfo(self.handle);
  }

# get the description of this table
  const public.getdesc := function(actual=T) {
    if(is_fail(public.ok())) fail;
    return self.server.getTableDesc(self.handle, actual);
  }
  
# get the description of a specified column
  const public.getcoldesc := function(columnname, actual=T) {
    if(is_fail(public.ok())) fail;
    return self.server.getColumnDesc(self.handle, columnname, actual);
  }

  
# End of definitions

# Now initialize as appropriate
# Initialization by a handle is needed by tableiterator and query
# but is otherwise deprecated: we need a friend facility!

  if(!is_boolean(handle)) {
    self.handle:=handle;
    return ref public;
  }
  if(! is_string(tablename)) fail "must specify tablename (as string)";

# The tablename may have the prefix 'Table: ', which is added by
# getkeyword if the table is stored in a keyword.

  name := tablename ~ s/^Table: //
  if(!is_boolean(tabledesc)) {
    if(is_fail(self.create(name, tabledesc, dminfo, nrow,
			   lockoptions, endian, memorytable))) fail;
  } else {
    if(is_fail(public.open(name, readonly, lockoptions))) fail;
  }
  
# Return this object
  return ref public;

}



tablerow:=function(tab, columns=unset, exclude=F)
{
  self:=[=];
  public:=[=];
  self.tableRow:=F;

# Private functions
#------------------------------------------------------------------------------

# Public functions
#------------------------------------------------------------------------------

# specify which columns to return in a row
  const public.set := function(tab, columns=unset, exclude=F)
  {
    wider self;
    if (!is_boolean(self.tableRow)) public.close();
    if (is_string(columns)) {
      cols := columns;
    } else {
      cols := tab.colnames();
    }
    trow:=tab.server().makeTableRow(tab.handle(), columns, exclude);
    if (is_fail(trow)) fail;
    self.tableRow:=trow;
    self.table:=tab;
    return T;
  }
  
# get a row
  const public.get := function (rownr)
  {
    return self.table.server().getRow(self.tableRow, rownr);
  }
  
# put a row
  const public.put := function(rownr, value, matchingfields=T)
  {
    if(matchingfields) {
      return self.table.server().putRowMatchingFields(self.tableRow,
						      rownr, value);
    } else {
      return self.table.server().putRow(self.tableRow, rownr, value);
    }
  }

# close
  const public.close := function()
  {
    wider self;
    status := T;
    if (!is_boolean(self.tableRow)) {
      status := self.table.server().closeTableRow(self.tableRow);
    }
    self.tableRow := F;
    return status;
  }

# done
  const public.done := function()
  {
    wider self, public;
    public.close();
    val self := F;
    val public := F;
    return T;
  }

  if(is_fail(public.set(tab, columns, exclude))) fail;
  return ref public;
}



tablecolumn:=function(ref tab, column)
{
  self:=[=];
  public:=[=];
  self.tab := ref tab;
  self.col := column;


# Public functions
#------------------------------------------------------------------------------

  const public.name := function() {
    return self.col;
  }

  const public.table := function() {
    return ref self.tab;
  }

  const public.isscalar := function() {
    return self.tab.isscalarcol (self.col);
  }

  const public.isvar := function() {
    return self.tab.isvarcol (self.col);
  }

  const public.datatype := function() {
    return self.tab.coldatatype (self.col);
  }

  const public.arraytype := function() {
    return self.tab.colarraytype (self.col);
  }

  const public.nrows := function() {
    return self.tab.nrows();
  }

# Get the shapes of the arrays.
  const public.getshapestring := function (startrow=1, nrow=-1, rowincr=1) {
    return self.tab.getcolshapestring(self.col, startrow, nrow, rowincr);
  }

# Does a cell contain a defined value?
  const public.iscelldefined := function (rownr) {
    return self.tab.iscelldefined(self.col, rownr);
  }

# Get the cell contents
  const public.getcell := function (rownr) {
    return self.tab.getcell(self.col, rownr);
  }
  
# Get the cell slice
  const public.getcellslice := function (rownr, blc, trc, inc=F) {
    return self.tab.getcellslice(self.col, rownr, blc, trc, inc);
  }
  
# Get the specified column
  const public.getcol := function (startrow=1, nrow=-1, rowincr=1) {
    return self.tab.getcol(self.col, startrow, nrow, rowincr);
  }
  
# Get the specified column as record containing variable arrays
  const public.getvarcol := function (startrow=1, nrow=-1, rowincr=1) {
    return self.tab.getvarcol(self.col, startrow, nrow, rowincr);
  }
  
# Get the specified column slice
  const public.getcolslice := function (blc, trc, inc=F,
                                        startrow=1, nrow=-1, rowincr=1) {
    return self.tab.getcolslice(self.col, blc, trc, inc,
                                startrow, nrow, rowincr);
  }
  
# Put the cell contents
  const public.putcell := function (rownr, value) {
    return self.tab.putcell(self.col, rownr, value);
  }
  
# Put the cell slice
  const public.putcellslice := function (rownr, value, blc, trc, inc=F) {
    return self.tab.putcellslice(self.col, rownr, value, blc, trc, inc);
  }
  
# Put the specified column
  const public.putcol := function (value, startrow=1, nrow=-1, rowincr=1) {
    return self.tab.putcol(self.col, value, startrow, nrow, rowincr);
  }

# Get the specified column from record containing variable arrays
  const public.putvarcol := function (value, startrow=1, nrow=-1, rowincr=1) {
    return self.tab.putvarcol(self.col, value, startrow, nrow, rowincr);
  }
  
# Put the specified column slice
  const public.putcolslice := function (value, blc, trc, inc=F,
                                        startrow=1, nrow=-1, rowincr=1) {
    return self.tab.putcolslice(self.col, value,
                                blc, trc, inc, startrow, nrow, rowincr);
  }


# The next set of functions are dealing with column keywords.
  
# Get a specified column keyword
  const public.getkeyword := function(keyword) {
    return self.tab.getcolkeyword(self.col, keyword);
  }
  
# Get the set of all column keywords
  const public.getkeywords := function() {
    return self.tab.getcolkeywords(self.col);
  }

# Put the specified column keyword
  const public.putkeyword := function(keyword, value, makesubrecord=F) {
    return self.tab.putcolkeyword(self.col, keyword, value, makesubrecord);
  }

# Put the set of column keywords
  const public.putkeywords := function(value) {
    return self.tab.putcolkeywords(self.col, value);
  }
  
# Remove the specified column keyword
  const public.removekeyword := function(keyword) {
    return self.tab.removecolkeyword(self.col, keyword);
  }
  
# Get the names of all keywords in given column.
  const public.keywordnames := function () {
    return self.tab.colkeywordnames (self.col);
  }
  
# Get the names of all fields in a column keyword.
  const public.fieldnames := function (keyword='') {
    return self.tab.colfieldnames (self.col, keyword);
  }

  const public.getdesc := function(actual=T) {
    return self.tab.getcoldesc (self.col, actual);
  }

  const public.makeiter := function(order='', sort=T) {
    return tableiterator (self.tab, self.col, order, sort);
  }

  const public.makeindex := function(sort=T) {
    return tableindex (self.tab, self.col, sort);
  }

# close
  const public.close := function()
  {
    self.tab := F;
  }

# done
  const public.done := function()
  {
    wider self, public;
    public.close();
    val self := F;
    val public := F;
    return T;
  }

  return ref public;
}



tableindex:=function(tab, columns, sort=T)
{
  self:=[=];
  public:=[=];
  self.tableIndex:=F;

# Private functions
#------------------------------------------------------------------------------

# Public functions
#------------------------------------------------------------------------------

# specify which columns to use in an index
  const public.set := function(tab, columns, sort=T)
  {
    wider self;
    if (!is_boolean(self.tableIndex)) public.close();
    tinx := tab.server().makeTableIndex(tab.handle(), columns, sort);
    if (is_fail(tinx)) fail;
    self.tableIndex := tinx;
    self.table:=tab;
    return T;
  }  

# are all keys in the index unique?
  const public.isunique := function()
  {
    return self.table.server().indexIsUnique (self.tableIndex);
  }

# tell that some or all columns have changed.
  const public.setchanged := function (columns=[])
  {
    return self.table.server().indexSetChanged (self.tableIndex, columns);
  }

# get a single rownr
  const public.rownr := function (key)
  {
    return self.table.server().indexGetRowNumber (self.tableIndex, key);
  }
  
# get multiple rownrs
  const public.rownrs := function (key, upperkey=unset,
				   lowerincl=T, upperincl=T)
  {
    return self.table.server().indexGetRowNumbers(self.tableIndex,
						  key, upperkey,
						  lowerincl, upperincl);
  }

# close
  const public.close := function()
  {
    wider self;
    status := T;
    if (!is_boolean(self.tableIndex)) {
      status := self.table.server().closeTableIndex(self.tableIndex);
    }
    self.tableIndex := F;
    return status;
  }

# done
  const public.done := function()
  {
    wider self, public;
    public.close();
    val self := F;
    val public := F;
    return T;
  }

  if (is_fail(public.set(tab, columns, sort))) fail;
  return ref public;  
}



tableiterator:=function(tab, columns, order='', sort=T)
{
  self:=[=];
  public:=[=];

  self.table:=tab;
  self.iterhandle:=F;
  self.columns:=columns;
  self.order:=order;
  self.sort:=sort;
  self.subtable:=F;
  self.atend:=F;

# Private functions
#------------------------------------------------------------------------------

# Public functions
#------------------------------------------------------------------------------

  const public.table:=function() {
      if(is_boolean(self.subtable)) fail "subtable not available";
    return ref self.subtable;
  }

  const public.reset:=function() {
    wider self;
    if(!is_boolean(self.subtable)) {
	self.subtable.done();
    }
    if(!is_boolean(self.iterhandle)) {
	self.table.server().closeTableIterator(self.iterhandle);
    }
    self.subtable:=F;
    self.atend:=F;
    self.iterhandle:=self.table.server().makeTableIterator(self.table.handle(),
      self.columns, self.order, self.sort);
    if(is_fail(self.iterhandle)) fail;
    return T;
  }
  
  const public.next:=function() {
    wider self;
    if(!is_boolean(self.subtable)) if(is_fail(self.subtable.done())) fail;
    self.subtable:=F;
    if(is_boolean(self.iterhandle)) fail "table iterator invalid";
    if(self.atend) {
      return F;
    }
    if(self.table.server().stepTableIterator(self.iterhandle)) {
      self.subtable:=table(handle=self.iterhandle.handle);
      return T;
    }
    self.atend:=T;
    return F;
  }
  
  const public.terminate:=function() {
    if(!is_boolean(self.subtable)) self.subtable.done();
    wider self;
    self.subtable:=F;
    # If at end, iterator was already closed by the table client.
    # Closing it again would result in an exception.
    if (self.atend) {
      return T;
    }
    status := self.table.server().closeTableIterator(self.iterhandle);
    self.iterhandle := F;
    self.atend := T;
    return status;
  }
  
  const public.close:=function() {
    public.terminate();
  }

  const public.done:=function() {
    wider self, public;
    public.terminate();
    val self := F;
    val public := F;
    return T;
  }

  if(is_fail(public.reset())) fail;
  return ref public;
}



# Global functions
#------------------------------------------------------------------------------

# Create from FITS
  const tablefromfits := function(tablename, fitsfile, whichhdu=1,
				  storage='standard', convention='sdfits',
				  readonly=T, lockoptions='default',
				  ack=T,
				  tableserver=defaulttableserver) {

    if(convention=='sdfits') {
      sdfits:='True';
    } else {
      sdfits:='False';
    }
    include "os.g";
    if(!dos.fileexists(fitsfile)) {
      return throw(paste('FITS file', fitsfile, 'does not exist'));
    }

    command := spaste('fits2table input=', fitsfile,' output=', tablename,
		      ' which_hdu=', whichhdu, ' storage=', storage,
		      ' sdfits=', sdfits);

    note(paste('Executing ', command));
    result := shell(command);
    if(result::status!=0  ||  !tableexists(tablename)) {
      return throw(paste('Execution of fits2table failed: ', result));
    }
    return table(tablename, readonly=readonly, lockoptions=lockoptions,
		 ack=ack, tableserver=tableserver);
  }

# Create from an ascii file
  const tablefromascii := function(tablename, asciifile,
				   headerfile='',
				   autoheader=F, autoshape=[],
				   sep=' ',
				   commentmarker='',
				   firstline=1, lastline=-1,
				   columnnames="", datatypes="",
				   readonly=T,
				   lockoptions='default', ack=T,
				   tableserver=defaulttableserver)
  {
    if(!is_string(tablename)) {
	return throw('tablename must be a string argument',
		     origin='tablefromascii');
    }
    if(!is_string(asciifile)) {
	return throw('asciifile must be a string argument',
		     origin='tablefromascii');
    }
    if(!is_string(headerfile)) {
	return throw('headerfile must be a string argument',
		     origin='tablefromascii');
    }
    include "os.g";
    if(!dos.fileexists(asciifile)) {
	return throw (paste("asciifile", asciifile, "does not exist"),
		      origin='tablefromascii');
    }
    if(headerfile!='') {
	if(!dos.fileexists(headerfile)) {
	    return throw (paste("headerfile ", headerfile, "does not exist"),
			  origin='tablefromascii');
	}
    }
    result := tableserver.readAscii(tablename, asciifile, headerfile,
				    autoheader, autoshape, sep, commentmarker,
				    firstline, lastline,
				    columnnames, datatypes);
    if (is_fail(result)) fail;
    note(spaste('Input format: [', result, ']'));
    return table(tablename, readonly=readonly, lockoptions=lockoptions,
		 ack=ack, tableserver=tableserver);
  }


# Return names of all tables
const tableopentables := function(tableserver=defaulttableserver) {
  return tableserver.tableNames();
}    


# does the table exist?
const tableexists := function(tablename,tableserver=defaulttableserver) {
  return (tableserver.tableExists(tablename ~ s/^Table: //)==1);
}

# is the table writable?
const tableiswritable := function(tablename,tableserver=defaulttableserver) {
  return (tableserver.tableIsWritable(tablename ~ s/^Table: //)==1);
}

# get the info
const tableinfo := function(tablename,tableserver=defaulttableserver) {
  return tableserver.tableInfo(tablename ~ s/^Table: //);
}

# copy
const tablecopy:=function(tablename, newtablename, deep=F,
			  tableserver=defaulttableserver) {
  if(is_fail(tableserver.copyTable(tablename ~ s/^Table: //,
				   newtablename, deep,
				   F, [=], 'aipsrc', 'plain', F, F))) fail;
  return T;
}

# rename
const tablerename:=function(tablename, newtablename,
			    tableserver=defaulttableserver) {
  if(tableexists(newtablename)) fail paste(newtablename, "exists");
  if(is_fail(tableserver.renameTable(tablename ~ s/^Table: //,
				     newtablename))) fail;
  return T;
}

# delete
const tabledelete:=function(tablename, checksubtables=T, ack=T,
			    tableserver=defaulttableserver) {
  tabname := tablename ~ s/^Table: //;
  t:=table(tabname,readonly=F,ack=F);
  if (is_fail(t)) fail;
  t.done();
  if(is_fail(tableserver.deleteTable(tabname, checksubtables, ack))) fail;
  return T;
}

# close all tables
const tablecloseall:=function(tableserver=defaulttableserver) {
  if(is_fail(tableserver.closeAllTables())) fail;
  return T;
}

# The next functions create descriptions of various sorts
# create a description of a scalar column
const tablecreatescalarcoldesc := function (columnname, value,
					    datamanagertype='', 
					    datamanagergroup='',
					    options=0, maxlen=0, comment='',
					    tableserver=defaulttableserver) {
  return tableserver.scalarColumnDesc(columnname, value, datamanagertype,
				      datamanagergroup, options, maxlen,
				      comment)
    }

# create a description of an array column
const tablecreatearraycoldesc := function (columnname, value, ndim=0,
					   shape=F, datamanagertype='',
					   datamanagergroup='', 
					   options=0, maxlen=0, comment='',
					   tableserver=defaulttableserver) {
  return tableserver.arrayColumnDesc(columnname, value, ndim, shape,
				     datamanagertype, datamanagergroup, 
				     options, maxlen, comment)
    }

# create a table description from a set of column descriptions
const tablecreatedesc := function(const columndesc1, ...)
{
  return defaulttableserver.tableDesc(columndesc1, ...);
}

# define a hypercolumn in the table description.
const tabledefinehypercolumn := function(ref tabdesc,
					 name, ndim, datacolumns,
					 coordcolumns=unset,
					 idcolumns=unset)
{
  local rec := [=];
  rec.HCndim := ndim;
  rec.HCdatanames := datacolumns;
  if (! is_unset(coordcolumns)) {
    rec.HCcoordnames := coordcolumns;
  }
  if (! is_unset(idcolumns)) {
    rec.HCidnames := idcolumns;
  }
  
  tabdesc["_define_hypercolumn_"][name] := rec;
  return T;
}


# execute a table command
const tablecommand := function(command, style='', handle=F,
                               tableserver=defaulttableserver) {
  local result;
  if (style != '') {
    command := paste('using style',style,command);
  }
  if (is_boolean(handle)) {
    result:=tableserver.tableCommand(command);
  } else {
    result:=tableserver.tableCommand(command, handle);
  }
  if(is_fail(result)) fail;
  # If the command was a CALC expression, return the values.
  if (is_boolean(result.file)) {
    return result.values;
  }
  if (result.file != '') {
    if (is_fail (tableserver.closeTable(result))) fail;
  }
  return table(handle=result);
}

const tabletest := function()
{
  include "ttable.g";
  dotabletest();
}

#------------------------------------------------------------------------------
if(is_fail(defaulttableserver)) {
  throw('table system is not ready');
} else {
  note('table system ready');
}
