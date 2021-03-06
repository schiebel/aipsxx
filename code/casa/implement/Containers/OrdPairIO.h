//# OrdPairIO.h: Functions to perform IO for ordered pair classes
//# Copyright (C) 1993,1994,1995,1999,2000,2001
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
//# $Id: OrdPairIO.h,v 19.6 2005/06/18 21:19:14 ddebonis Exp $

#ifndef CASA_ORDPAIRIO_H
#define CASA_ORDPAIRIO_H

#include <casa/Containers/OrderedPair.h>
#include <casa/iosfwd.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class AipsIO;

//
// These need to be left out **SUN BUG**
// 

// <summary> Global IO functions </summary>
// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="" demos="">
// </reviewed>
// Input/output
// <group name=inoutput>
template<class key, class value> AipsIO& operator<<(AipsIO& ios, const OrderedPair<key,value>& op);
template<class key, class value> AipsIO& operator>>(AipsIO& ios, OrderedPair<key,value>& op);

template<class key, class value> ostream& operator<<(ostream& ios, const OrderedPair<key,value>&);
// </group>


} //# NAMESPACE CASA - END

#ifndef AIPS_NO_TEMPLATE_SRC
#include <casa/Containers/OrdPairIO.cc>
#endif //# AIPS_NO_TEMPLATE_SRC
#endif
