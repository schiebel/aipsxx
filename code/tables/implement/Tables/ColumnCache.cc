//# ColumnCache.cc: A caching object for a table column
//# Copyright (C) 1997
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
//# $Id: ColumnCache.cc,v 19.3 2004/11/30 17:51:01 ddebonis Exp $


//# Includes
#include <tables/Tables/ColumnCache.h>


namespace casa { //# NAMESPACE CASA - BEGIN

ColumnCache::ColumnCache()
: itsIncr (1)
{
    invalidate();
}


void ColumnCache::set (uInt startRow, uInt endRow, const void* dataPtr)
{
    itsStart = startRow;
    itsEnd   = endRow;
    itsData  = dataPtr;
}

} //# NAMESPACE CASA - END

