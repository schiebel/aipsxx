//# QLogical.cc: class to manipulate physical, dimensioned quantities
//# Copyright (C) 1994,1995,1996,1998,2001
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
//# $Id: QLogical2.cc,v 19.4 2004/11/30 17:50:18 ddebonis Exp $

//# Includes
#include <casa/Quanta/QLogical.h>
#include <casa/BasicMath/Math.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Exceptions/Error.h>

namespace casa { //# NAMESPACE CASA - BEGIN

Bool QMakeBool(Int val) {
    return ((val));
}

Bool QMakeBool(const LogicalArray &val) {
    return (allAND(val, True));
}

} //# NAMESPACE CASA - END

