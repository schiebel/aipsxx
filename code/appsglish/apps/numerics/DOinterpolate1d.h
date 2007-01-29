//# interpolate_1d_impl.h: implement interpolate_1d 
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
//#
//# $Id: DOinterpolate1d.h,v 19.5 2004/11/30 17:50:09 ddebonis Exp $

#ifndef APPSGLISH_DOINTERPOLATE1D_H
#define APPSGLISH_DOINTERPOLATE1D_H

#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <scimath/Functionals/Interpolate1D.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class MethodResult;
class ParameterSet;
class String;
template <class T> class Vector;
} //# NAMESPACE CASA - END


// <summary>The C++ side of the glish interpolate1d tool.</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> The Arrays module
//   <li> The glish interpolate1d tool
// </prerequisite>
//
// <etymology>
// The name MUST have the 'DO' prefix as this class is derived from
// ApplicationObject, and hence is classified as a distributed object. For the
// same reason the rest of its name must be in lower case. This class is a
// simplified version of the Interpolate1d class.
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

class interpolate1d : public ApplicationObject
{
public:
    interpolate1d();
    virtual ~interpolate1d();
  
    // the actual implementation of the virtual functions
    Vector<Double> interpolate(const Vector<Double>& x);
    Bool initialize(const Vector<Double>& x, const Vector<Double>& y, 
			  const String &method);
    // neearest, linear, cubic or spline
    void setmethod(const String& method);

    // Needed for the DO system
    virtual String className() const;
    virtual Vector<String> noTraceMethods() const;
    virtual Vector<String> methods() const;
    virtual MethodResult runMethod(uInt which, 
                                   ParameterSet &inputRecord,
                                   Bool runmethod);
private:
  interpolate1d(const interpolate1d &other);
  interpolate1d& operator=(const interpolate1d &other);

  Interpolate1D<Double, Double> itsInterpolator;
};

#endif
