//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996
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
//# $Id: MethodResult.h,v 19.5 2004/11/30 17:51:11 ddebonis Exp $

#ifndef TASKING_METHODRESULT_H
#define TASKING_METHODRESULT_H

#include <casa/aips.h>
#include <casa/BasicSL/String.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward Declarations

// <summary>
// </summary>

// <use visibility=local>   or   <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
//   <li> SomeOtherClass
//   <li> some concept
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <templating arg=T>
//    <li>
//    <li>
// </templating>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>


class MethodResult
{
public:
    // Returns OK
    MethodResult();
    MethodResult(const String &error);
    MethodResult(const char *error);
    MethodResult(const MethodResult &other);
    MethodResult &operator=(const MethodResult &other);
    ~MethodResult();
    Bool ok() const;
    const String &errorMessage() const;
private:
    String error_p;
    Bool ok_p;
};

//# Inlines ------------------------------------------------------------
inline MethodResult::MethodResult()
  : ok_p(True)
{}

inline MethodResult::MethodResult(const String &error)
  : error_p(error), ok_p(False)
{}

inline MethodResult::MethodResult(const char *error)
  : error_p(error), ok_p(False)
{}

inline MethodResult::MethodResult(const MethodResult &other)
  : error_p(other.error_p), ok_p(other.ok_p)
{}

inline MethodResult &MethodResult::operator=(const MethodResult &other)
{
    ok_p = other.ok_p;
    if (!ok_p) {
      // Only copy the error message if we're not OK
      error_p = other.error_p;
    }
    return *this;
}

inline MethodResult::~MethodResult() {}

inline Bool MethodResult::ok() const
{
    return ok_p;
}

inline const String &MethodResult::errorMessage() const
{
    return error_p;
}


} //# NAMESPACE CASA - END

#endif


