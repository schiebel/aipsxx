//# polyfitter.h: implement polynomial fitting
//# Copyright (C) 1996,1997,1999,2003
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
//# $Id: DOpolyfitter.h,v 19.5 2004/11/30 17:50:09 ddebonis Exp $

#ifndef APPSGLISH_DOPOLYFITTER_H
#define APPSGLISH_DOPOLYFITTER_H

#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
template<class T> class Vector;
template<class T> class Array;
class String;
} //# NAMESPACE CASA - END


// <summary>The C++ side of the glish polyfitter tool.</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> The Arrays module
//   <li> The glish polyfitter tool
// </prerequisite>
//
// <etymology>
// The name MUST have the 'DO' prefix as this class is derived from
// ApplicationObject, and hence is classified as a distributed object. For the
// same reason the rest of its name must be in lower case. This class
// fits polynomials.
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

class polyfitter : public ApplicationObject
{
public:
    polyfitter();
    polyfitter(const polyfitter &other);
    polyfitter& operator=(const polyfitter &other);
    virtual ~polyfitter();

    // the actual implementation of the virtual functions
    Bool fit(Vector<Double>& coeff, Vector<Double>& coefferrs,
	     Double& chisq, 
	     const Vector<Double>& x, 
	     const Vector<Double>& y,
	     const Vector<Double>& sigma,
	     Int order);

    Bool multifit(Array<Double>& coeff, Array<Double>& coefferrs,
		  Vector<Double>& chisq,
		  const Vector<Double>& x, 
		  const Array<Double>& y,
		  const Array<Double>& sigma,
		  Int order);


    Bool eval(Array<Double>& y, 
	      const Vector<Double>& x,
	      const Array<Double>& coeff);

    // Return the name of this object type.  Always returns "polyfitter".
    // This function is required as part of the DO system.
    virtual String className() const;

    // The returned vector contains the names of all of the methods
    // which may be used via the distributed object system.
    // This function is required as part of the DO system.
    virtual Vector<String> methods() const;

    // the returned vector contains the names of all the methods which are too
    // trivial to warrent automatic logging. Currently no functions are logged.
    // This function is required as part of the DO system.
    virtual Vector<String> noTraceMethods() const;

    // Run the specified method. This is the function used by the distributed
    // object system to invoke any of the specified member functions in thi s
    // class.
    virtual MethodResult runMethod(uInt which, 
                                   ParameterSet &inputRecord,
                                   Bool runmethod);
};

#endif


