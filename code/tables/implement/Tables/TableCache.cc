//# TableCache.cc: Cache of open tables
//# Copyright (C) 1994,1995,1997,1999
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
//# $Id: TableCache.cc,v 19.4 2006/09/04 23:49:45 gvandiep Exp $

#include <tables/Tables/TableCache.h>


namespace casa { //# NAMESPACE CASA - BEGIN

TableCache::TableCache()
: tableMap_p(static_cast<void*>(0))
{}

TableCache::~TableCache()
{}

PlainTable* TableCache::operator() (const String& tableName) const
{
    PlainTable** ptr = (PlainTable**)(tableMap_p.isDefined (tableName));
    if (ptr) {
	return *ptr;
    }
    return 0;
}

PlainTable* TableCache::operator() (uInt index) const
{
    return (PlainTable*) (tableMap_p.getVal (index));
}

uInt TableCache::ntable() const
{
    return tableMap_p.ndefined();
}


void TableCache::define (const String& tableName, PlainTable* tab)
{
    tableMap_p.define (tableName, tab);
}

void TableCache::remove (const String& tableName)
{
    // For static Table objects it is possible that the TableCache is
    // deleted before the Table.
    // Therefore do not delete if the map is already empty
    // (otherwise an exception is thrown).
    if (tableMap_p.ndefined() > 0) {
	tableMap_p.remove (tableName);
    }
}

void TableCache::rename (const String& newName, const String& oldName)
{
    if (tableMap_p.isDefined (oldName)) {
	tableMap_p.rename (newName, oldName);
    }
}

} //# NAMESPACE CASA - END

