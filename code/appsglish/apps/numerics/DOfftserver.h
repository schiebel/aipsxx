//# DOfftserver.h:
//# Copyright (C) 1996,1998,1999,2000
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
//# $Id: DOfftserver.h,v 19.6 2004/11/30 17:50:09 ddebonis Exp $

#ifndef APPSGLISH_DOFFTSERVER_H
#define APPSGLISH_DOFFTSERVER_H

#include <casa/aips.h>
#include <casa/BasicSL/Complexfwd.h>
#include <tasking/Tasking/ApplicationObject.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class ParameterSet;
class String;
template<class T> class Array;
template<class T> class Vector;
} //# NAMESPACE CASA - END


// <summary>The C++ side of the glish fftserver tool.</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> The Arrays module
//   <li> The glish fftserver tool
// </prerequisite>
//
// <etymology>
// The name MUST have the 'DO' prefix as this class is derived from
// ApplicationObject, and hence is classified as a distributed object. For the
// same reason the rest of its name must be in lower case. This class is a
// simplified version of the fftserver class.
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

class fftserver : public ApplicationObject
{
public:
    fftserver();
    fftserver(const fftserver &other);
    fftserver &operator=(const fftserver &other);
    ~fftserver();

    virtual void complexfft(Array<Complex> &a, Int dir);
    virtual Array<Complex> realtocomplexfft(const Array<Float> &a);
    virtual Array<Complex> mfft(const Array<Complex> & a, 
				const Vector<Bool> & axes, Bool forward);

    // We should zero-pad at least this first one
    virtual Array<Float> convolve(const Array<Float> &a, 
				    const Array<Float> &b);
    virtual Array<Float> crosscorr(const Array<Float> &a, 
				      const Array<Float> &b);
    virtual Array<Float> autocorr(const Array<Float> &a);
    virtual Array<Float> shift(const Array<Float> &a,
			       const Vector<Float> &shift);

  // return the name of this object type the distributed object system and
  // always return "fftserver".
  // This function is required as part of the DO system
  virtual String className() const;

  // the returned vector contains the names of all the methods which may be
  // used via the distributed object system.
  // This function is required as part of the DO system
  virtual Vector<String> methods() const;

  // the returned vector contains the names of all the methods which are too
  // trivial to warrent automatic logging. Currently no functions are logged.
  // This function is required as part of the DO system
  virtual Vector<String> noTraceMethods() const;

  // Run the specified method. This is the function used by the distributed
  // object system to invoke any of the specified member functions in thi s
  // class.
  virtual MethodResult runMethod(uInt which, ParameterSet &inputRecord,
				 Bool runMethod);
private:
  enum methods {COMPLEXFFT=0, REALTOCOMPLEXFFT, CONVOLVE, CROSSCORR, 
		AUTOCORR, SHIFT, MFFT, NUM_METHODS};
};

#endif
