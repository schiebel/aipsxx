//# sinusoidfitter.h: implement sinusoidal fitting
//# Copyright (C) 1997,1999,2001,2002,2003
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
//# $Id: DOsinusoidfitter.h,v 19.5 2004/11/30 17:50:09 ddebonis Exp $

#ifndef APPSGLISH_DOSINUSOIDFITTER_H
#define APPSGLISH_DOSINUSOIDFITTER_H

#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <scimath/Fitting/NonLinearFitLM.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
template<class T> class Vector;
class String;
class GlishRecord;
} //# NAMESPACE CASA - END


// <summary>The C++ side of the glish sinusoidfitter tool.</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> The Arrays module
//   <li> The Fitting module
//   <li> The glish sinusoidfitter tool
// </prerequisite>
//
// <etymology>
// The name MUST have the 'DO' prefix as this class is derived from
// ApplicationObject, and hence is classified as a distributed object. For the
// same reason the rest of its name must be in lower case. This class
// fits sinusoids
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

class sinusoidfitter : public ApplicationObject {
public:
    enum Methods { FIT=0, EVAL, SETSTATE, GETSTATE,
                   NUMBER_METHODS};

    sinusoidfitter();
    sinusoidfitter(const sinusoidfitter &other);
    sinusoidfitter& operator=(const sinusoidfitter &other);
    virtual ~sinusoidfitter();

    // Fit a sinusoid to y given x  If sigma has the same number 
    // of elements, it is used in the fit, otherwise sigma==1 is 
    // assumed.  The state argument will contain the state
    // of the fitter after the fit happens.  It is not used
    // on input to set the state before the fit begins.
    // Use the setstate() member for that.
    Bool fit(GlishRecord& state, 
	     const Vector<Double>& x, 
	     const Vector<Double>& y,
	     const Vector<Double>& sigma);
    // there is no savings by doing multiple fits in a single
    // pass since there is no setup costs which might be 
    // amortized over several fits.  However, there may be
    // some advantage in sending over several y vectors to
    // be fit to the same x vector from glish in one event.
    // Its probably worth pondering that for the future.

    // evaluate the function at x, placing the result in y.
    Bool eval(Vector<Double>& y, const Vector<Double>& x);

    Bool getstate(GlishRecord& state);

    Bool setstate(const GlishRecord& state);

    // Return the name of this object type.  Always returns "sinusoiditter".
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
private:

    NonLinearFitLM<Double> fitter_p;

    Double chisq_p, dof_p;
    Vector<Double> parms_p;

    void init();
};

#endif


