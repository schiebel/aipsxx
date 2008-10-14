//# DOrandomnumbers.cc:
//# Copyright (C) 1996,1998,1999,2000,2001,2003
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
//# $Id: DOrandomnumbers.cc,v 19.6 2005/11/07 21:17:04 wyoung Exp $

#include <appsglish/numerics/DOrandomnumbers.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicMath/Math.h>
#include <casa/BasicMath/Random.h>
#include <casa/Exceptions/Error.h>
#include <casa/Utilities/Assert.h>
#include <casa/BasicSL/String.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterSet.h>
#include <casa/sstream.h>

#include <casa/namespace.h>
randomnumbers::randomnumbers()
  :itsRNGPtr(new ACG(0))
{
  AlwaysAssert(itsRNGPtr != 0, AipsError);
}

randomnumbers::randomnumbers(const randomnumbers& other) 
  :itsRNGPtr(new ACG(*other.itsRNGPtr))
{
  AlwaysAssert(itsRNGPtr != 0, AipsError);
}

randomnumbers& randomnumbers::operator=(const randomnumbers& other) {
  if (this != &other) {
    delete itsRNGPtr;
    itsRNGPtr = new ACG(*other.itsRNGPtr);
    AlwaysAssert(itsRNGPtr != 0, AipsError);
  }
  return *this;
}

randomnumbers::~randomnumbers() {
  delete itsRNGPtr;
  itsRNGPtr = 0;
}

Array<Int> randomnumbers::binomial(Int number, Double prob, 
				   const Vector<Int>& shape) {
  if (number < 0 || prob < 0.0 || prob > 1.0) {
    ostringstream s;
    s << "randomnumbers::binomial - Cannot have fewer than zero "
      << "items (you have " << number << ")," << endl;
    s << "or a probabilty outside  the range of zero to one "
      << "(you have " << prob << ")" << endl;
    String st(s); // egcs-1.1.2 complains when I merge this line and the next
    throw(AipsError(st));
  }
  checkShape(shape, "binomial");
  const IPosition oShape(shape);
  const uInt n = oShape.product();
  Vector<Int> samples(n);
  Binomial distn(itsRNGPtr, number, prob);
  for (uInt i = 0; i < n; i++) {
    samples(i) = distn.asInt();
  }
  return samples.reform(oShape);
}


Array<Int> randomnumbers::discreteuniform(Int low, Int high, 
					  const Vector<Int>& shape) {
  if (low > high ) {
    ostringstream s;
    s << "randomnumbers::discreteuniform - low value of " << low
      << " is greater than the high value of " << high << endl;
    String st(s); 
    throw(AipsError(st));
  }
  checkShape(shape, "discreteuniform");
  const IPosition oShape(shape);
  const uInt n = oShape.product();
  Vector<Int> samples(n);
  DiscreteUniform distn(itsRNGPtr, low, high);
  for (uInt i = 0; i < n; i++) {
    samples(i) = distn.asInt();
  }
  return samples.reform(oShape);
}

Array<Double> randomnumbers::erlang(Double mean, Double variance,
				    const Vector<Int>& shape) {
  if (variance <= 0.0 || near(mean, 0.0)) {
    ostringstream s;
    s << "randomnumbers::erlang - Must have a positive variance "
      << "(you have " << variance << ")," << endl;
    s << "and a non-zero mean "
      << "(you have " << mean << ")" << endl;
    String st(s);
    throw(AipsError(st));
  }
  checkShape(shape, "erlang");
  Erlang distn(itsRNGPtr, mean, variance);
  const IPosition oShape(shape);
  return getSamples(distn, oShape.product()).reform(oShape);
}

Array<Int> randomnumbers::geometric(Double probability,
				    const Vector<Int>& shape) {
  if (probability < 0.0 || probability >= 1.0) {
    ostringstream s;
    s << "randomnumbers::geometric - The probability must be between "
      << "zero and one (you have " << probability << ")." << endl;
    String st(s); 
    throw(AipsError(st));
  }
  checkShape(shape, "geometric");
  const IPosition oShape(shape);
  const uInt n = oShape.product();
  Vector<Int> samples(n);
  Geometric distn(itsRNGPtr, probability);
  for (uInt i = 0; i < n; i++) {
    samples(i) = distn.asInt();
  }
  return samples.reform(oShape);
}

Array<Double> randomnumbers::hypergeometric(Double mean, Double variance, 
					    const Vector<Int>& shape) {
  if (variance <= 0.0 || mean * mean > variance || near(mean, 0.0)) {
    ostringstream s;
    s << "randomnumbers::hypergeometric - Must have a positive variance "
      << "(you have a variance of " << variance << ")," << endl;
    s << "and a non-zero mean that is less than the square-root of "
      << "the variance (you have a mean of " << mean << ")" << endl;
    String st(s); 
    throw(AipsError(st));
  }
  checkShape(shape, "hypergeometric");
  HyperGeometric distn(itsRNGPtr, mean, variance);
  const IPosition oShape(shape);
  return getSamples(distn, oShape.product()).reform(oShape);
}

Array<Double> randomnumbers::normal(Double mean, Double variance, 
				    const Vector<Int>& shape) {
  if (variance <= 0.0) {
    ostringstream s;
    s << "randomnumbers::normal - Must have a positive variance "
      << "(you have " << variance << ")," << endl;
    String st(s); 
    throw(AipsError(st));
  }
  checkShape(shape, "normal");
  Normal distn(itsRNGPtr, mean, variance);
  const IPosition oShape(shape);
  return getSamples(distn, oShape.product()).reform(oShape);
}

Array<Double> randomnumbers::lognormal(Double mean, Double variance, 
				       const Vector<Int>& shape) {
  if (variance <= 0.0 || near(mean, 0.0)) {
    ostringstream s;
    s << "randomnumbers::lognormal - Must have a positive variance "
      << "(you have " << variance << ")," << endl;
    s << "and a non-zero mean "
      << "(you have " << mean << ")" << endl;
    String st(s); 
    throw(AipsError(st));
  }
  checkShape(shape, "lognormal");
  LogNormal distn(itsRNGPtr, mean, variance);
  const IPosition oShape(shape);
  return getSamples(distn, oShape.product()).reform(oShape);
}

Array<Double> randomnumbers::negativeexponential(Double mean,
						 const Vector<Int>& shape) {
  checkShape(shape, "negativeexponential");
  NegativeExpntl distn(itsRNGPtr, mean);
  const IPosition oShape(shape);
  return getSamples(distn, oShape.product()).reform(oShape);
}

Array<Int> randomnumbers::poisson(Double mean, const Vector<Int>& shape) {
  if (mean < 0.0) {
    ostringstream s;
    s << "randomnumbers::poisson - Must have a non-negative mean "
      << "(you have " << mean << ")" << endl;
    String st(s); 
    throw(AipsError(st));
  }
  checkShape(shape, "poisson");
  const IPosition oShape(shape);
  const uInt n = oShape.product();
  Vector<Int> samples(n);
  Poisson distn(itsRNGPtr, mean);
  for (uInt i = 0; i < n; i++) {
    samples(i) = distn.asInt();
  }
  return samples.reform(oShape);
}

Array<Double> randomnumbers::uniform(Double low, Double high, 
				     const Vector<Int>& shape) {
  if (low > high || near(low, high)) {
    ostringstream s;
    s << "randomnumbers::uniform - low value of " << low
      << " is not smaller than the high value of " << high << endl;
    String st(s); 
    throw(AipsError(st));
  }
  checkShape(shape, "uniform");
  Uniform distn(itsRNGPtr, low, high);
  const IPosition oShape(shape);
  return getSamples(distn, oShape.product()).reform(oShape);
}

Array<Double> randomnumbers::weibull(Double alpha, Double beta,
				     const Vector<Int>& shape) {
  if (near(alpha, 0.0)) {
    ostringstream s;
    s << "randomnumbers::weibull - Must have a non-zero value for alpha "
      << "(you have " << alpha << ")" << endl;
    String st(s);
    throw(AipsError(st));
  }
  checkShape(shape, "weibull");
  Weibull distn(itsRNGPtr, alpha, beta);
  const IPosition oShape(shape);
  return getSamples(distn, oShape.product()).reform(oShape);
}

void randomnumbers::reseed(Int seed) {
  delete itsRNGPtr;
  itsRNGPtr = new ACG(seed);
}

String randomnumbers::className() const {
  return String("randomnumbers");
}

Vector<String> randomnumbers::methods() const {
  Vector<String> names(NUM_METHODS);
  names(BINOMIAL) = "binomial";
  names(DISCRETEUNIFORM) = "discreteuniform";
  names(ERLANG) = "erlang";
  names(GEOMETRIC) = "geometric";
  names(HYPERGEOMETRIC) = "hypergeometric";
  names(NORMAL) = "normal";
  names(LOGNORMAL) = "lognormal";
  names(NEGATIVEEXPONENTIAL) = "negativeexponential";
  names(POISSON) = "poisson";
  names(UNIFORM) = "uniform";
  names(WEIBULL) = "weibull";
  names(RESEED) = "reseed";
  return names;
}

Vector<String> randomnumbers::noTraceMethods() const {
  return methods();
}

MethodResult randomnumbers::runMethod(uInt which, ParameterSet& inputRecord,
				      Bool runMethod) {
  static String highString = "high";
  static String lowString = "low";
  static String meanString = "mean";
  static String varianceString = "variance";
  static String shapeString = "shape";
  static String returnvalString = "returnval";
  static String probabilityString = "probability";
  switch (which) {
  case BINOMIAL: {
    static String numberString = "number";
    Parameter<Array<Int> > returnval(inputRecord, returnvalString,
				     ParameterSet::Out);
    Parameter<Int> number(inputRecord, numberString, ParameterSet::In);
    Parameter<Double> probability(inputRecord,
				  probabilityString, ParameterSet::In);
    Parameter<Vector<Int> > shape(inputRecord, shapeString,
				  ParameterSet::In);
    if (runMethod) {
      returnval() = binomial(number(), probability(), shape());
    }
  }
  break;
  case DISCRETEUNIFORM: {
    Parameter<Array<Int> > returnval(inputRecord, returnvalString,
				     ParameterSet::Out);
    Parameter<Int> low(inputRecord, lowString, ParameterSet::In);
    Parameter<Int> high(inputRecord, highString, ParameterSet::In);
    Parameter<Vector<Int> > shape(inputRecord, shapeString,
				  ParameterSet::In);
    if (runMethod) {
      returnval() = discreteuniform(low(), high(), shape());
    }
  }
  break;
  case ERLANG: {
    Parameter<Array<Double> > returnval(inputRecord, returnvalString,
					ParameterSet::Out);
    Parameter<Double> mean(inputRecord, meanString, ParameterSet::In);
    Parameter<Double> variance(inputRecord, varianceString, 
			       ParameterSet::In);
    Parameter<Vector<Int> > shape(inputRecord, shapeString,
				  ParameterSet::In);
    if (runMethod) {
      returnval() = erlang(mean(), variance(), shape());
    }
  }
  break;
  case GEOMETRIC: {
    Parameter<Array<Int> > returnval(inputRecord, returnvalString,
					ParameterSet::Out);
    Parameter<Double> probability(inputRecord, probabilityString,
				  ParameterSet::In);
    Parameter<Vector<Int> > shape(inputRecord, shapeString,
				  ParameterSet::In);
    if (runMethod) {
      returnval() = geometric(probability(), shape());
    }
  }
  break;
  case HYPERGEOMETRIC: {
    Parameter<Array<Double> > returnval(inputRecord, returnvalString,
					ParameterSet::Out);
    Parameter<Double> mean(inputRecord, meanString, ParameterSet::In);
    Parameter<Double> variance(inputRecord, varianceString, 
			       ParameterSet::In);
    Parameter<Vector<Int> > shape(inputRecord, shapeString,
				  ParameterSet::In);
    if (runMethod) {
      returnval() = hypergeometric(mean(), variance(), shape());
    }
  }
  break;
  case NORMAL: {
    Parameter<Array<Double> > returnval(inputRecord, returnvalString,
					ParameterSet::Out);
    Parameter<Double> mean(inputRecord, meanString, ParameterSet::In);
    Parameter<Double> variance(inputRecord, varianceString, 
			       ParameterSet::In);
    Parameter<Vector<Int> > shape(inputRecord, shapeString,
				  ParameterSet::In);
    if (runMethod) {
      returnval() = normal(mean(), variance(), shape());
    }
  }
  break;
  case LOGNORMAL: {
    Parameter<Array<Double> > returnval(inputRecord, returnvalString,
					ParameterSet::Out);
    Parameter<Double> mean(inputRecord, meanString, ParameterSet::In);
    Parameter<Double> variance(inputRecord, varianceString, 
			       ParameterSet::In);
    Parameter<Vector<Int> > shape(inputRecord, shapeString,
				  ParameterSet::In);
    if (runMethod) {
      returnval() = lognormal(mean(), variance(), shape());
    }
  }
  break;
  case NEGATIVEEXPONENTIAL: {
    Parameter<Array<Double> > returnval(inputRecord, returnvalString,
					ParameterSet::Out);
    Parameter<Double> mean(inputRecord, meanString, ParameterSet::In);
    Parameter<Vector<Int> > shape(inputRecord, shapeString,
				  ParameterSet::In);
    if (runMethod) {
      returnval() = negativeexponential(mean(), shape());
    }
  }
  break;
  case POISSON: {
    Parameter<Array<Int> > returnval(inputRecord, returnvalString,
				     ParameterSet::Out);
    Parameter<Double> mean(inputRecord, meanString, ParameterSet::In);
    Parameter<Vector<Int> > shape(inputRecord, shapeString,
				  ParameterSet::In);
    if (runMethod) {
      returnval() = poisson(mean(), shape());
    }
  }
  break;
  case UNIFORM: {
    Parameter<Array<Double> > returnval(inputRecord, returnvalString,
					ParameterSet::Out);
    Parameter<Double> low(inputRecord, lowString, ParameterSet::In);
    Parameter<Double> high(inputRecord, highString, ParameterSet::In);
    Parameter<Vector<Int> > shape(inputRecord, shapeString,
				  ParameterSet::In);
    if (runMethod) {
      returnval() = uniform(low(), high(), shape());
    }
  }
  break;
  case WEIBULL: {
    static String alphaString = "alpha";
    static String betaString = "beta";
    Parameter<Array<Double> > returnval(inputRecord, returnvalString,
					ParameterSet::Out);
    Parameter<Double> alpha(inputRecord, alphaString, ParameterSet::In);
    Parameter<Double> beta(inputRecord, betaString, ParameterSet::In);
    Parameter<Vector<Int> > shape(inputRecord, shapeString,
				  ParameterSet::In);
    if (runMethod) {
      returnval() = weibull(alpha(), beta(), shape());
    }
  }
  break;
  case RESEED: {
    Parameter<Int> seed(inputRecord, "seed", ParameterSet::In);
    if (runMethod) {
      reseed(seed());
    }
  }
  break;
  default:
    return error("No such method");
  }
  return ok();
}

Vector<Double> randomnumbers::getSamples(Random& distn, uInt nSamples) {
  Vector<Double> samples(nSamples);
  for (uInt i = 0; i < nSamples; i++) {
    samples(i) = distn();
  }
  return samples;
}

void randomnumbers::checkShape(const Vector<Int>& shape,
			       const String& function) {
  if (anyLE(shape, 0)) {
    ostringstream s;
    s << shape;
    throw(AipsError("randomnumbers::" + function + 
		    " - invalid output shape of " + String(s)));
  }
}
// Local Variables: 
// compile-command: "gmake DOrandomnumbers"
// End: 
