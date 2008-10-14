//# DOpolyfitter.cc:
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
//# $Id: DOpolyfitter.cc,v 19.6 2005/11/07 21:17:04 wyoung Exp $

//# Includes

#include <appsglish/numerics/DOpolyfitter.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/BasicSL/String.h>

#include <scimath/Fitting/LinearFitSVD.h>
#include <scimath/Functionals/Polynomial.h>

#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/Parameter.h>

#include <casa/Logging.h>
#include <casa/sstream.h>

#include <casa/namespace.h>
polyfitter::polyfitter()
{
    // Nothing
}

polyfitter::polyfitter(const polyfitter &)
{
    // Nothing
}

polyfitter &polyfitter::operator=(const polyfitter &)
{
    return *this;
}

polyfitter::~polyfitter()
{
    // Nothing
}

Bool polyfitter::fit(Vector<Double>& coeff, Vector<Double>& coeffErrs,
		     Double& chisq, 
		     const Vector<Double>& x, 
		     const Vector<Double>& y,
		     const Vector<Double>& sigma,
		     Int order)
{
    LogOrigin OR("polyfitter", 
		 "fit(Vector<Double>& coeff, Vector<Double>& coeffErrs"
		 "Double& chisq,"
		 "const Vector<Double>& x, "
		 "const Vector<Double>& y,"
		 "const Vector<Double>& sigma,"
		 "Int order)", id(), WHERE);
    LogMessage msg(OR);

    static Vector<Double> sigmatmp;

    const Vector<Double> *sigmaptr = &sigma;

    // Sanity checks
    // x, y, sigma are the same length
    if (x.nelements() != y.nelements()) {
	msg.message("arguments are not all of the same length.").line(__LINE__).
	    priority(LogMessage::SEVERE);
	LogSink::postGlobally(msg);
	return False;
    } else if (Int(x.nelements()) < order + 1) {
	msg.message("The number of data points is less than the number of"
		    " parameters!").line(__LINE__).
	    priority(LogMessage::SEVERE);
	LogSink::postGlobally(msg);
	return False;
    } else {
	// Make a sigma if we weren't provided a proper one
	if (sigma.nelements() != x.nelements()) {
	    sigmatmp.resize(x.nelements(), False);
	    sigmatmp.set(1.0);
	    sigmaptr = &sigmatmp;
	    msg.message("No sigma provided (or invalid) - assuming sigma=1.0").
		line(__LINE__);
	    LogSink::postGlobally(msg);
	}

	LinearFitSVD<Double> fitter;

	// add the required functions
	Polynomial<AutoDiff<Double> > newFunction(order);

	fitter.setFunction(newFunction);

	// extract the coefficients
	coeff.resize(0);
	// do the fit
	coeff = fitter.fit(x,y,*sigmaptr);

	// and their errors
	coeffErrs.resize(coeff.nelements());
	coeffErrs = sqrt(fitter.compuCovariance().diagonal());

	// and finally chisq
	chisq = fitter.chiSquare();

	// and clean up
	
    }
    sigmatmp.resize(0);
    return True;
}

Bool polyfitter::multifit(Array<Double>& coeff, Array<Double>& coefferrs,
			  Vector<Double>& chisq,
			  const Vector<Double>& x, 
			  const Array<Double>& y,
			  const Array<Double>& sigma,
			  Int order)
{
    LogOrigin OR("polyfitter", 
		 "multifit(Array<Double>& coeff, Array<Double>& coefferrs,"
		 "Vector<Double>& chisq,"
		 "const Vector<Double>& x, "
		 "const Array<Double>& y,"
		 "const Array<Double>& sigma,"
		 "Int order)", id(), WHERE);
    LogMessage msg(OR);


    if (y.ndim() > 2) {
	msg.message("y must be 1 or 2 dimensional").line(__LINE__).
	    priority(LogMessage::SEVERE);
	LogSink::postGlobally(msg);
	return False;
    }

    Matrix<Double> yref(y);

    if (x.nelements() != yref.nrow()) {
	msg.message("x.nelements() must equal y.nrow()").line(__LINE__).
	    priority(LogMessage::SEVERE);
	LogSink::postGlobally(msg);
	return False;
    }

    
    if (Int(x.nelements()) < order + 1) {
	msg.message("The number of data points is less than the number of"
		    " parameters!").line(__LINE__).
	    priority(LogMessage::SEVERE);
	LogSink::postGlobally(msg);
	return False;
    }

    if (sigma.ndim() > 2) {
	msg.message("sigma must be one or two dimensional").line(__LINE__).
	    priority(LogMessage::SEVERE);
	LogSink::postGlobally(msg);
	return False;
    }

    Matrix<Double> sigmaref(sigma);
    if (sigmaref.nrow() != yref.nrow()) {
	msg.message("Assuming all sigmas are 1.0").line(__LINE__).
	    priority(LogMessage::NORMAL);
	LogSink::postGlobally(msg);
	sigmaref.resize(yref.nrow(), 1);
	sigmaref = 1.0;
    }

    if (sigmaref.ncolumn() != yref.ncolumn() && sigmaref.ncolumn() != 1) {
	msg.message("Fewer sigma values than y values").line(__LINE__).
	    priority(LogMessage::SEVERE);
	LogSink::postGlobally(msg);
	return False;
    }

    {
	// inputs OK, issue an informative message
	ostringstream buffer;
	buffer << "Solving " << yref.ncolumn() << " fits for an order " << 
	    order << " polynomial using SVD";
	msg.message(buffer).line(__LINE__).priority(LogMessage::NORMAL);
	LogSink::postGlobally(msg);
    }

    // Create the fitter
    LinearFitSVD<Double> fitter;

    // Put in the polynomial terms
    Polynomial<AutoDiff<Double> > newFunction(order);
    fitter.setFunction(newFunction);

    // Set up the output arrays
    const Int nfits = yref.ncolumn();
    const Int npoints = yref.nrow();

    Matrix<Double> outcoeff(order+1, nfits);
    coeff.reference(outcoeff);
    Matrix<Double> outcoefferrs(order+1, nfits);
    coefferrs.reference(outcoefferrs);
    chisq.resize(nfits);

    // Avoid calling diagonal etc. for efficiency (many new calls).
    Vector<Double> coefftmp(order+1);
    Vector<Double> coefferrstmp(order+1);
    Vector<Double> ytmp(yref.nrow());
    Vector<Double> sigmatmp(sigmaref.column(0).copy());
    
    // There is still some whole array copying in the loop that we could
    // do away with.
    Int i=0;
    Bool ok = True;
    try {
	for (i=0; i<nfits; i++) {
	    // Set up the temporaries
	    Int j;
	    for (j=0; j<npoints; j++) {
		ytmp(j) = yref(j,i);
	    }
	    if (sigmaref.ncolumn() > 1) {
		for (j=0; j<npoints; j++) {
		    sigmatmp(j) = sigmaref(j,i);
		}
	    }

	    // Do the fit
	    coefftmp = fitter.fit(x, ytmp, sigmatmp);
	    chisq(i) = fitter.chiSquare();
	    coefferrstmp = sqrt(fitter.compuCovariance().diagonal());

	    // Copy the output back
	    for (j=0; j<order+1; j++) {
		outcoeff(j,i) = coefftmp(j);
		outcoefferrs(j,i) = coefferrstmp(j);
	    }
	}
    } catch (AipsError x) {
	ok = False;
	ostringstream buffer;
	buffer << "Error during fit # " << i+1 << ":" << x.getMesg();
	msg.message(buffer).line(__LINE__).priority(LogMessage::SEVERE);
	LogSink::postGlobally(msg);
    } 

    return ok;
}


Bool polyfitter::eval(Array<Double>& y, 
		      const Vector<Double>& x,
		      const Array<Double>& coeff)
{
    Bool ok = True;
    // two cases, coeff is either 1D (fit result) or 2D (multifit result)
    if (coeff.ndim() == 1) {
	// cast coeff and y to a Vector
	Vector<Double> vcoeff(coeff);
	y.resize(IPosition(1,x.nelements()));
	Vector<Double> vy(y);
	// I believe this is faster than using the Polynomial class 
	Vector<Double> arg(x.nelements());
	arg = 1;
	vy = vcoeff(0);
	for (uInt i=1;i<vcoeff.nelements();i++) {
	    arg *= x;
	    vy += vcoeff(i) * arg;
	}
    } else if (coeff.ndim() == 2) {
	// cast coeff and y to a Matrix
	Matrix<Double> mcoeff(coeff);
	y.resize(IPosition(2,x.nelements(),mcoeff.ncolumn()));
	Matrix<Double> my(y);
	// I believe this is faster than using the Polynomial class
	Vector<Double> arg(x.nelements());
	arg = 1;
	for (uInt j=0;j<my.ncolumn();j++) {
	    my.column(j) = mcoeff.column(j)(0);
	}
	for (uInt i=1;i<mcoeff.nrow();i++) {
	    arg *= x;
	    for (uInt j=0;j<my.ncolumn();j++) {
	      Vector<Double> myj = my.column(j);
	      myj += mcoeff.column(j)(i) * arg;
	    }
	}
    } else {
	ok = False;
	LogOrigin OR("polyfitter", 
		     "eval(Array<Double>& y, "
		     "String &errorMsg, "
		     "const Vector<Double>& x, "
		     "const Array<Double>& coeff)",
		     id(), WHERE);
	LogMessage msg(OR);
	msg.message("Error in use of eval() : coef has more than 2 dimensions").
	    line(__LINE__).priority(LogMessage::SEVERE);
	LogSink::postGlobally(msg);    
    }
    return ok;
}

String polyfitter::className() const
{
    return "polyfitter";
}

Vector<String> polyfitter::methods() const
{
    Vector<String> tmp(3);
    tmp(0) = "fit";
    tmp(1) = "eval";
    tmp(2) = "multifit";
    return tmp;
}

Vector<String> polyfitter::noTraceMethods() const
{
  return methods();
}

MethodResult polyfitter::runMethod(uInt which, 
				   ParameterSet &params,
				   Bool runMethod)
{
    static String returnvalString = "returnval";
    static String coeffString = "coeff";
    static String coefferrsString = "coefferrs";
    static String chisqString = "chisq";
    static String xString = "x";
    static String yString = "y";
    static String sigmaString = "sigma";
    static String orderString = "order";

    switch(which) {
    case 0:
	{
	    Parameter<Bool> returnval(params, returnvalString, 
				      ParameterSet::Out);
	    Parameter< Vector<Double> > coeff(params, coeffString,
					     ParameterSet::Out);
	    Parameter< Vector<Double> > coefferrs(params, coefferrsString,
						 ParameterSet::Out);
	    Parameter<Double> chisq(params, chisqString, ParameterSet::Out);
	    Parameter< Vector<Double> > x(params, xString, ParameterSet::In);
	    Parameter< Vector<Double> > y(params, yString, ParameterSet::In);
	    Parameter< Vector<Double> > sigma(params, sigmaString, 
					     ParameterSet::In);
	    Parameter<Int> order(params, orderString, ParameterSet::In);
	    if (runMethod) {
		returnval() = fit(coeff(), coefferrs(), chisq(),
				  x(), y(), sigma(), order());
	    }
        }
    break;
    case 1:
	{
	    Parameter<Bool> returnval(params, returnvalString, 
				      ParameterSet::Out);
	    Parameter< Array<Double> > coeff(params, coeffString,
					     ParameterSet::In);
	    Parameter< Vector<Double> > x(params, xString, ParameterSet::In);
	    Parameter< Array<Double> > y(params, yString, ParameterSet::Out);
	    if (runMethod) {
		returnval() = eval(y(), x(), coeff());
	    }
        }
	break;
    case 2:
	{
	    Parameter<Bool> returnval(params, returnvalString, 
				      ParameterSet::Out);
	    Parameter< Array<Double> > coeff(params, coeffString,
					     ParameterSet::Out);
	    Parameter< Array<Double> > coefferrs(params, coefferrsString,
						 ParameterSet::Out);
	    Parameter< Vector<Double> > chisq(params, chisqString, ParameterSet::Out);
	    Parameter< Vector<Double> > x(params, xString, ParameterSet::In);
	    Parameter< Array<Double> > y(params, yString, ParameterSet::In);
	    Parameter< Array<Double> > sigma(params, sigmaString, 
					     ParameterSet::In);
	    Parameter<Int> order(params, orderString, ParameterSet::In);
	    if (runMethod) {
		returnval() = multifit(coeff(), coefferrs(), chisq(), 
				  x(), y(), sigma(), order());
	    }
        }
    break;
    default:
	return error("No such method");
    }

    return ok();
}
