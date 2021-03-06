//# ColormapInfo.cc: store information about the dynamic mapping of a Colormap
//# Copyright (C) 1994,1995,1996,1997,1998,1999,2000
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
//# $Id: ColormapInfo.cc,v 19.3 2005/06/15 17:56:27 cvsmgr Exp $

#include <display/Display/ColormapInfo.h>

namespace casa { //# NAMESPACE CASA - BEGIN

ColormapInfo::ColormapInfo() :
  itsColormap(0),
  itsWeight(0),
  itsOffset(0),
  itsSize(2),
  itsRefCount(0) {
}

ColormapInfo::ColormapInfo(const Colormap *colormap, const Float &weight,
			   const uInt &offset, const uInt &size) :
  itsColormap(colormap),
  itsWeight(weight),
  itsOffset(offset),
  itsSize(size),
  itsRefCount(0) {
}

void ColormapInfo::setWeight(const Float &weight) {
  itsWeight = weight;
}

void ColormapInfo::setOffset(const uInt &offset) {
  itsOffset = offset;
}

void ColormapInfo::setSize(const uInt &size) {
  itsSize = size;
}

void ColormapInfo::ref() {
  itsRefCount++;
}

void ColormapInfo::unref() {
  itsRefCount--;
}


} //# NAMESPACE CASA - END

