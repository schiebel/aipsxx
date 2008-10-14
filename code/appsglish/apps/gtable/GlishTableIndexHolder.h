//# GlishTableIndexHolder.h: Holder of table index for the table glish client
//# Copyright (C) 2002
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
//# $Id: GlishTableIndexHolder.h,v 19.6 2006/02/14 10:28:10 gvandiep Exp $

#ifndef APPSGLISH_GLISHTABLEINDEXHOLDER_H
#define APPSGLISH_GLISHTABLEINDEXHOLDER_H


//# Includes
#include <tables/Tables/TableIndexProxy.h>
#include <casa/Utilities/CountedPtr.h>

#include <casa/namespace.h>
//# Forward Declarations
namespace casa {
class TableRecord;
}


// <summary>
// Holder of table index for the table glish client.
// </summary>

// <use visibility=local>

// <reviewed reviewer="Paul Shannon" date="1995/09/15" tests="tgtable.g" demos="">
// </reviewed>

// <prerequisite>
//# Classes you should understand before using this one.
//   <li> class ColumnsIndex
//   <li> class ColumnsIndexArray
// </prerequisite>

// <synopsis> 
// A GlishTableIndexHolder object holds a ColumnsIndex or ColumnsIndexArray
// object for the table glish client. It is in fact similar to class
// <linkto class=GlishTableHolder>GlishTableHolder</linkto>.
// It is used by <linkto class=GlishTableProxy>GlishTableProxy</linkto>
// to keep track of all table indices used in the glish client.
// </synopsis>

// <example>
// The index functions in class GlishTableProxy show clearly how
// GlishTableIndexHolder is used.

class GlishTableIndexHolder
{
public:
  // Construct for the given proxy.
  GlishTableIndexHolder()
    : tableId_p (-1)
    {}

  // Construct for the given proxy.
  GlishTableIndexHolder (TableIndexProxy* proxy, Int tableId)
    : proxy_p   (proxy),
      tableId_p (tableId)
    {}

  // Is this a null object?
  Bool isNull() const
    { return tableId_p < 0; }

  // Get the table-id used by this index object.
  Int tableId() const
    { return tableId_p; }

  // Get access to the proxy.
  // <group>
  TableIndexProxy& proxy()
    { return *proxy_p; }
  const TableIndexProxy& proxy() const
    { return *proxy_p; }
  // </group>

private:
  CountedPtr<TableIndexProxy> proxy_p;
  Int                         tableId_p;
};


#endif
