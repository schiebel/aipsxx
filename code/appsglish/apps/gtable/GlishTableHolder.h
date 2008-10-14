//# GlishTableHolder.h: Holder of a table for the table glish client.
//# Copyright (C) 1994,1995,1996,1999
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
//# $Id: GlishTableHolder.h,v 19.6 2006/02/14 10:28:10 gvandiep Exp $

#ifndef APPSGLISH_GLISHTABLEHOLDER_H
#define APPSGLISH_GLISHTABLEHOLDER_H


//# Includes
#include <tables/Tables/TableProxy.h>
#include <casa/BasicSL/String.h>

#include <casa/namespace.h>


// <summary>
// Holder of a table for the table glish client.
// </summary>

// <use visibility=export>

// <reviewed reviewer="Paul Shannon" date="1995/09/15" tests="tgtable.g" demos="">
// </reviewed>

// <prerequisite>
//# Classes you should understand before using this one.
//   <li> class Table
// </prerequisite>

// <etymology>
// GlishTableHolder is used to hold a table for the table glish client.
// </etymology>

// <synopsis> 
// A GlishTableHolder object holds a Table object for the table glish client.
// It is used by <linkto class=GlishTableProxy>GlishTableProxy</linkto>
// to keep track of all tables used in the glish client.
// GlishTableHolder also maps the table to the table name and keeps track
// whether the table is in a open or closed state.
// <p>
// The mapping of table name to Table object is needed in case the
// Table gets automatically closed for synchronization purposes.
// This is, for instance, needed to execute a table command using
// TableParse. If the table would not be closed before executing the
// command, the updates done to the table may not be known to the
// TableParse execution. Similarly, the table needs to be reopened
// afterwards to know updates possibly done in the table browser.
// When an automatically closed table gets used again, it will be
// reopened transparently.
// <note>
// When an unnamed table (e.g. the result of a selection) is closed, it
// cannot be reopened anymore (and is closed permanently).
// </note>
// </synopsis>

// <example>
// <srcblock>
//    // Construct a GlishTableHolder object from a Table.
//    Table table ("table.name");
//    GlishTableHolder tg (table);
//    // Get its name.
//    String tableName = tg.tableName();
// </srcblock>
// </example>

class GlishTableHolder
{
public:
  // Default constructor initializes to not open.
  // This constructor is only needed for the Block container.
  GlishTableHolder();

  // Construct from the Table object.
  // It stores the table name and open-mode (readonly or read/write).
  GlishTableHolder (const TableProxy& table);

  // Do we have a null Table object?
  Bool isNull() const
  { return proxy_p.table().isNull(); }

  // Get the TableProxy object.
  TableProxy& proxy()
    { return proxy_p; }

  // Get the table name.
  const String& tableName() const
    { return tableName_p; }

  // Clear the table name to render a GlishTableHolder object invalid.
  // This is used when a (temporarily) closed table gets reopened
  // to make the closed table invisible.
  void clearName()
    { tableName_p = ""; }

  // Get the open switch.
  Int isOpen() const
    { return tableIsOpen_p; }

  // Test if the table is readable.
  Bool isReadable() const;
  
  // Test if the table is writable.
  Bool isWritable() const;

  // Close the table.
  void close();

  // Reopen the table for read/write.
  // It returns false if the table is not writable.
  Bool reopenRW();

private:
  TableProxy  proxy_p;
  String      tableName_p;
  Int         tableIsOpen_p;   //# 1=readonly; 2=read/write; -1/-2=closed
};



#endif
