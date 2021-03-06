//# MWCAniTemplates.cc: templates for the MWCAnimator class
//# Copyright (C) 2000,2001
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
//# $Id: MWCAniTemplates.cc,v 19.4 2005/06/15 18:02:22 cvsmgr Exp $

#include <casa/aips.h>
#include <display/DisplayEvents/MWCAnimator.h>
#include <display/Display/AttributeBuffer.h>

namespace casa { //# NAMESPACE CASA - BEGIN

template <class T>
void MWCAnimator::setLinearRestriction(const String &name,
				       const T &value, const T &increment,
				       const T& tol) {
  AttributeBuffer resbuf, incbuf;
  resbuf.add(name, value, tol);
  incbuf.add(name, increment);
  setLinearRestrictions(resbuf, incbuf);
}

} //# NAMESPACE CASA - END

