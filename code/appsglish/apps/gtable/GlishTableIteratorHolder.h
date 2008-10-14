//# GlishTableIteratorHolder.h: Holder of table iterators for the table glish client.
//# Copyright (C) 1994,1995,1996,1999,2005
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
//# $Id: GlishTableIteratorHolder.h,v 19.5 2006/02/14 10:28:10 gvandiep Exp $

#ifndef APPSGLISH_GLISHTABLEITERATORHOLDER_H
#define APPSGLISH_GLISHTABLEITERATORHOLDER_H


//# Includes
#include <tables/Tables/TableIterProxy.h>

#include <casa/namespace.h>
//# Forward Declarations
class GlishTableHolder;


// <summary>
// Holder of table iterators for the table glish client.
// </summary>

// <use visibility=export>

// <reviewed reviewer="Paul Shannon" date="1995/09/15" tests="tgtable.g" demos="">
// </reviewed>

// <prerequisite>
//# Classes you should understand before using this one.
//   <li> class TableIterator
// </prerequisite>

// <etymology>
// GlishTableIteratorHolder holds a TableIterator object for the table
// glish client.
// </etymology>

// <synopsis> 
// A GlishTableHolder object holds a TableIterator object for the table
// glish client. It is in fact similar to class
// <linkto class=GlishTableHolder>GlishTableHolder</linkto>.
// It is used by <linkto class=GlishTableProxy>GlishTableProxy</linkto>
// to keep track of all table iterators used in the glish client.
// <p>
// GlishTableIteratorHolder also holds the id of the GlishTableHolder
// object which is used by GlishTableProxy to hold the result of the
// last iterator step.
// </synopsis>

// <example>
// The iterator functions in class GlishTableProxy show clearly how
// GlishTableIteratorHolder is used.
// For completeness, an example follows.
// <srcblock>
//    // Get a tableId for the subtables.
//    GlishTableProxy proxy;
//    Table table;
//    tableId = proxy.addTable (table);
//    // Construct a GlishTableIterator object.
//    Table mainTable ("table.name");
//    TableIterator iter (table, "columnX");
//    GlishTableIteratorHolder tgi (iter, tableId);
//    // Do a step.
//    Table subTable;
//    Bool pastEnd = tgi.next (subTable);
//    // Get the table id for the subtable resulting from the iteration step.
//    Int tableId = tgi.tableId();
// </srcblock>
// </example>

class GlishTableIteratorHolder
{
public:
  // Default constructor initializes to not open.
  // This constructor is only needed for the Block container.
  GlishTableIteratorHolder()
    : tableId_p (-1) {}

  // Construct from the TableIterator object.
  // The given table-id will be used with this iterator.
  GlishTableIteratorHolder (TableIterProxy& iterator, Int tableId)
    : proxy_p   (iterator),
      tableId_p (tableId)
    {}

  // Get the table id used for the tables resulting from each iterator step.
  Int tableId() const
    { return tableId_p; }

  // Get the iterator proxy.
  const TableIterProxy& iterator() const
    { return proxy_p; }

  // Get the next subtable and return it in the GlishTableHolder argument.
  // When no more subtables are available, it returns False.
  Bool next (GlishTableHolder& table);

private:
  TableIterProxy proxy_p;
  Int            tableId_p;             //# -1 = no iterator attached yet
};



#endif
