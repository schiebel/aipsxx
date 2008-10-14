# gtable.g: wraps table events into Glish functions
#
#   Copyright (C) 1995,1996,1997,1999
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
#   $Id: gtable.g,v 19.1 2004/08/25 00:53:11 cvsmgr Exp $
#
#----------------------------------------------------------------------------

pragma include once

include "tableserver.g"

const gtable:=ref defaulttableserver;
  
const helpTable:=ref gtable.helpTable; 
const openTable:=ref gtable.openTable; 
const openTableForUpdate:=ref gtable.openTableForUpdate; 
const createTable:=ref gtable.createTable; 
const copyTable:=ref gtable.copyTable; 
const renameTable:=ref gtable.renameTable; 
const closeTable:=ref gtable.closeTable; 
const closeAllTables:=ref gtable.closeAllTables; 
const deleteTable:=ref gtable.deleteTable; 
const tableNames:=ref gtable.tableNames; 
const tableName:=ref gtable.tableName; 
const recoverTableHandle:=ref gtable.recoverTableHandle; 
const tableExists:=ref gtable.tableExists; 
const tableIsWritable:=ref gtable.tableIsWritable; 
const tableInfo:=ref gtable.tableInfo; 
const putTableInfo:=ref gtable.putTableInfo; 
const addReadmeLine:=ref gtable.addReadmeLine; 
const columnNames:=ref gtable.columnNames; 
const isScalarColumn:=ref gtable.isScalarColumn; 
const columnDataType:=ref gtable.columnDataType; 
const columnArrayType:=ref gtable.columnArrayType; 
const tableShape:=ref gtable.tableShape; 
const numberOfColumns:=ref gtable.numberOfColumns; 
const numberOfRows:=ref gtable.numberOfRows; 
const rowNumbers:=ref gtable.rowNumbers;
const setMaximumCacheSize:=ref gtable.setMaximumCacheSize;
const cellContentsDefined:=ref gtable.cellContentsDefined; 
const getCell:=ref gtable.getCell; 
const getCellSlice:=ref gtable.getCellSlice; 
const getColumn:=ref gtable.getColumn; 
const getColumnSlice:=ref gtable.getColumnSlice; 
const putCell:=ref gtable.putCell; 
const putCellSlice:=ref gtable.putCellSlice; 
const putColumn:=ref gtable.putColumn; 
const putColumnSlice:=ref gtable.putColumnSlice; 
const getTableKeyword:=ref gtable.getTableKeyword; 
const getTableKeywordSet:=ref gtable.getTableKeywordSet; 
const getColumnKeyword:=ref gtable.getColumnKeyword; 
const getColumnKeywordSet:=ref gtable.getColumnKeywordSet; 
const putTableKeyword:=ref gtable.putTableKeyword; 
const putTableKeywordSet:=ref gtable.putTableKeywordSet; 
const putColumnKeyword:=ref gtable.putColumnKeyword; 
const putColumnKeywordSet:=ref gtable.putColumnKeywordSet; 
const removeTableKeyword:=ref gtable.removeTableKeyword; 
const removeColumnKeyword:=ref gtable.removeColumnKeyword; 
const addRows:=ref gtable.addRows; 
const scalarColumnDesc:=ref gtable.scalarColumnDesc; 
const arrayColumnDesc:=ref gtable.arrayColumnDesc; 
const tableDesc:=ref gtable.tableDesc; 
const getTableDesc:=ref gtable.getTableDesc; 
const getColumnDesc:=ref gtable.getColumnDesc; 
const tableCommand:=ref gtable.tableCommand; 
const makeTableIterator:=ref gtable.makeTableIterator; 
const stepTableIterator:=ref gtable.stepTableIterator; 
const closeTableIterator:=ref gtable.closeTableIterator; 
const makeTableRow:=ref gtable.makeTableRow; 
const getRow:=ref gtable.getRow; 
const putRow:=ref gtable.putRow; 
const putRowMatchingFields:=ref gtable.putRowMatchingFields; 
const closeTableRow:=ref gtable.closeTableRow; 
