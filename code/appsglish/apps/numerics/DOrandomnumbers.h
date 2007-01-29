//# DOrandomnumbers.h:
//# Copyright (C) 1996,1999,2000,2001
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
//# $Id: DOrandomnumbers.h,v 19.5 2004/11/30 17:50:09 ddebonis Exp $

#ifndef APPSGLISH_DORANDOMNUMBERS_H
#define APPSGLISH_DORANDOMNUMBERS_H

#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class ACG;
class MethodResult;
class ParameterSet;
class String;
class Random;
template<class T> class Array;
template<class T> class Vector;
} //# NAMESPACE CASA - END


// <summary>The C++ side of the glish randomnumbers tool.</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> The Arrays module
//   <li> The glish randomnumbers tool
// </prerequisite>
//
// <etymology>
// The name MUST have the 'DO' prefix as this class is derived from
// ApplicationObject, and hence is classified as a distributed object. For the
// same reason the rest of its name must be in lower case. This class
// generates randomnumbers.
// </etymology>
//
// <synopsis>

// This class generates random numbers. The random numbers can be from a wide
// variety of distributions. 

// All the functions return the samples in an Array of user specified
// shape. The vector specifying the shape must contain only positive values,
// otherwise and an AipsError exception will be thrown.


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

class randomnumbers: public ApplicationObject
{
public:
  // Construct a class that generates random numbers
  randomnumbers();
  
  // The copy constructor uses copy semantics
  randomnumbers(const randomnumbers& other);
  
  // The assignment operator uses copy semantics
  randomnumbers& operator=(const randomnumbers& other);
  
  // The destructor deletes all data allocated within this class
  ~randomnumbers();
  
  // Generates a random number from the binomial distribution. This models
  // drawing items from a pool. The 'number' parameter indicates how many items
  // are in the pool, and the 'prob' parameter indicates the probability of
  // drawing an item. The returned samples are the number of items actually
  // drawn. The number parameter must be a non-negative integer, and the
  // probablity must be between zero and one; otherwise an AipsError exception
  // is thrown. The returned samples will be a non-negative integers that
  // cannot be greater than the number of items in the pool.
  Array<Int> binomial(Int number, Double prob, const Vector<Int>& shape);

  // Generates a random number from the discrete uniform distribution.  If the
  // low value is higher than the high value an AipsError exception is thrown.
  Array<Int> discreteuniform(Int low, Int high, const Vector<Int>& shape);

  // Generates a random number from the Erlang distribution. The mean cannot be
  // zero and the variance must be positive; otherwise and AipsError exception
  // will be thrown.
  Array<Double> erlang(Double mean, Double variance, const Vector<Int>& shape);

  // Generates a random number from the geometric distribution. The probability
  // must be a non-negative value less than one; otherwise and AipsError
  // exception will be thrown.
  Array<Int> geometric(Double probability, const Vector<Int>& shape);

  // Generates a random number from the hyper-geometric distribution. The
  // variance must be positive and the mean must be non-zero and cannot be
  // bigger than the square-root of the variance; otherwise and AipsError
  // exception will be thrown.
  Array<Double> hypergeometric(Double mean, Double variance,
			       const Vector<Int>& shape);

  // Generates a random number from the normal or Gaussian distribution. The
  // mean and variance can be any values.
  Array<Double> normal(Double mean, Double variance, const Vector<Int>& shape);

  // Generates a random number from the log-normal distribution. The mean must
  // be non-zero and variance must be positive; otherwise and AipsError
  // exception will be thrown.
  Array<Double> lognormal(Double mean, Double variance,
			  const Vector<Int>& shape);

  // Generates a random number from the negative exponential distribution. The
  // mean can be any value.
  Array<Double> negativeexponential(Double mean, const Vector<Int>& shape);

  // Generates a random number from the Poisson distribution. The mean must be
  // non-negative; otherwise and AipsError exception will be thrown.
  Array<Int> poisson(Double mean, const Vector<Int>& shape);

  // Generates a random number from the uniform distribution.  If the low value
  // cannot be higher than the high value; otherwise and AipsError exception
  // will be thrown. The low value may be returned unlike the high value.
  Array<Double> uniform(Double low, Double high, const Vector<Int>& shape);

  // Generates a random number from the Weibull distribution. The alpha
  // parameter cannot be zero; otherwise and AipsError exception will be
  // thrown.
  Array<Double> weibull(Double alpha, Double beta, const Vector<Int>& shape);

  // Specify a new seed to the random number generator. This allows you to get
  // reproducable random numbers.
  void reseed(Int seed);
  
  // return the name of this object type the distributed object system.
  // This function is required as part of the DO system
  virtual String className() const;

  // the returned vector contains the names of all the methods which may be
  // used via the distributed object system.
  // This function is required as part of the DO system
  virtual Vector<String> methods() const;

  // the returned vector contains the names of all the methods which are to
  // trivial to warrent automatic logging.
  // This function is required as part of the DO system
  virtual Vector<String> noTraceMethods() const;

  // Run the specified method. This is the function used by the distributed
  // object system to invoke any of the specified member functions in thi s
  // class.
  virtual MethodResult runMethod(uInt which, 
				 ParameterSet& inputRecord,
				 Bool runMethod);
private:
  Vector<Double> getSamples(Random& distn, uInt nSamples);
  void checkShape(const Vector<Int>& shape, const String& function);
    
  enum methods {BINOMIAL, DISCRETEUNIFORM, ERLANG, GEOMETRIC, HYPERGEOMETRIC,
		NORMAL, LOGNORMAL, NEGATIVEEXPONENTIAL, POISSON, UNIFORM, 
		WEIBULL, RESEED, NUM_METHODS};
  ACG* itsRNGPtr;
};

#endif
