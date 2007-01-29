//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1999
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
//#
//# $Id: Unset.h,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#ifndef TASKING_UNSET_H
#define TASKING_UNSET_H

#include <casa/aips.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class GlishRecord;

// <summary>
// Test for and represent a Glish unset value.
// </summary>

// <use visibility=local>   or   <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> unset.g
// </prerequisite>
//
// <etymology>
// This corresponds to an unset value in Glish.
// </etymology>
//
// <synopsis>
// To allow unset values to cross the C++-Glish interface, we
// introduce a record that is unlikely to be used. The form is
// [i_am_unset="i_am_unset"]. 
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <todo asof="yyyy/mm/dd">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>


class Unset
{
public:
    static Bool isUnset(const GlishRecord& record);
    static GlishRecord unsetRecord();
private:
};


} //# NAMESPACE CASA - END

#endif
