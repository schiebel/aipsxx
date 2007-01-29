//# GlishTableHolder.cc: Holder of a table for the table glish client.
//# Copyright (C) 1994,1995,1996
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
//# $Id: GlishTableHolder.cc,v 19.3 2006/02/14 10:28:10 gvandiep Exp $


#include <GlishTableHolder.h>


#include <casa/namespace.h>
GlishTableHolder::GlishTableHolder ()
: tableIsOpen_p(0)
{}

GlishTableHolder::GlishTableHolder (const TableProxy& tablep)
: proxy_p      (tablep),
  tableName_p  (""),
  tableIsOpen_p(0)
{
  const Table& table = tablep.table();
  if (! table.isNull()) {
    if (table.isMarkedForDelete()) {
      tableName_p = "";
    }else{
      tableName_p = table.tableName();
    }
    if (table.isWritable()) {
      tableIsOpen_p = 2;
    }else{
      tableIsOpen_p = 1;
    }
  }
}

//# Close this instance by assigning an empty Table object.
void GlishTableHolder::close()
{
  proxy_p = TableProxy();
  if (tableIsOpen_p > 0) {
    tableIsOpen_p = -tableIsOpen_p;       // not open anymore
  }
}

//# Reopen the table for read/write.
Bool GlishTableHolder::reopenRW()
{
  if (tableIsOpen_p == 2  ||  tableIsOpen_p == -2) {
    return True;                          // already open for write
  }
  if (tableName_p == "") {
    return False;                         // no name available
  }
  if (! Table::isWritable (tableName_p)) {
    return False;                         // not writable
  }
  if (tableIsOpen_p == -1) {
    tableIsOpen_p = -2;                   // set to reopen for write
    return True;
  }
  proxy_p.reopenRW();
  tableIsOpen_p = 2;
  return True;
}

Bool GlishTableHolder::isReadable() const
{
  if (tableIsOpen_p > 0) {
    return True;                          // still open
  }
  if (tableName_p == "") {
    return False;                         // no name available
  }
  return True;
}

Bool GlishTableHolder::isWritable() const
{
  if (! isReadable()) {
    return False;
  }
  if (tableIsOpen_p == 2  ||  tableIsOpen_p == -2) {
    return True;
  }
  return False;
}
