//# DOsinusoidfitter.cc:
//# Copyright (C) 1997,1998,1999,2001,2002,2003
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
//# $Id: DOsinusoidfitter.cc,v 19.6 2005/11/07 21:17:04 wyoung Exp $

//# Includes

#include <appsglish/numerics/DOsinusoidfitter.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Vector.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/BasicSL/String.h>

#include <scimath/Functionals/Sinusoid1D.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/Parameter.h>

#include <casa/Logging.h>
#include <casa/sstream.h>

#include <casa/namespace.h>
sinusoidfitter::sinusoidfitter()
    : dof_p(0), parms_p(3)
{
    init();
}

sinusoidfitter::sinusoidfitter(const sinusoidfitter &other)
    : dof_p(0), parms_p(3)
{
    init();
    *this = other;
}

sinusoidfitter &sinusoidfitter::operator=(const sinusoidfitter &other)
{
    if (this != &other) {
	chisq_p = other.chisq_p;
	parms_p = other.parms_p;
	dof_p = other.dof_p;
	fitter_p = other.fitter_p;
	fitter_p.setParameterValues(parms_p);
    }
    return *this;
}

sinusoidfitter::~sinusoidfitter()
{
    // nothing
}

Bool sinusoidfitter::fit(GlishRecord& state, 
			 const Vector<Double>& x, 
			 const Vector<Double>& y,
			 const Vector<Double>& sigma)
{
    Bool ok = False;
    LogOrigin OR("sinusoidfitter", 
		 "fit(GlishRecord& state,"
		 "const Vector<Double>& x, "
		 "const Vector<Double>& y, "
                 "const Vector<Double>& sigma)",
		 id(), WHERE);
    LogMessage msg(OR);

    // Sanity checks
    // x, y are the same length as is sigma, if
    // it has non-zero length (else sigma==1 is assumed)
    if (x.nelements() != y.nelements()) {
	msg.message("arguments are not all of the same length.").line(__LINE__).
	    priority(LogMessage::SEVERE);
	LogSink::postGlobally(msg);
    } else {
	Vector<Double> thisSigma(sigma);
	if (thisSigma.nelements() != x.nelements()) {
	    thisSigma.resize(x.nelements());
	    // equal weights
	    thisSigma = 1.0;
	}
	// remember the degrees of freedom involved here
	dof_p = x.nelements() - 3;
	// and do the fit
	parms_p = fitter_p.fit(x, y, thisSigma);
	// remember chisq of this fit
	chisq_p = fitter_p.chiSquare();

	// and set the state record for return
	ok = getstate(state);
    }
    return ok;
}

Bool sinusoidfitter::eval(Vector<Double>& y,
			  const Vector<Double>& x)
{
    y.resize(x.nelements());
    Function<AutoDiff<Double> > *sfunc = fitter_p.fittedFunction();
    for (uInt i=0;i<y.nelements();i++) y(i) = (*sfunc)(x(i)).value();
    return True;
}

Bool sinusoidfitter::getstate(GlishRecord& state)
{
    state.add(String("converged"),fitter_p.converged());
    state.add(String("curriter"),Int(fitter_p.currentIteration()));
    state.add(String("maxiter"), Int(fitter_p.getMaxIter()));
    state.add(String("criteria"), fitter_p.getCriteria());
    state.add(String("chisq"), chisq_p);
    state.add(String("amplitude"), parms_p(0));
    state.add(String("period"), parms_p(1));
    state.add(String("x0"), parms_p(2));
    
    // get the errors from the covariance matrix diagonal
    // default to zero if not converged or at least one 
    // element is zero
    Double amperr, pererr, x0err;
    amperr = pererr = x0err = 0.0;
    if (fitter_p.converged()) {
	Matrix<Double> covar(fitter_p.compuCovariance());
	Vector<Double> diag;
	diag = covar.diagonal();
	if (allGE(diag, Double(0.0)) && dof_p > 0) {
	    // correct these for chisq and degrees of freedom
	    diag = sqrt(diag*chisq_p /dof_p);
	    amperr = diag(0);
	    pererr = diag(1);
	    x0err = diag(2);
	}
	state.add(String("covariance"), covar);
    }
    state.add(String("amplitude_error"), amperr);
    state.add(String("period_error"), pererr);
    state.add(String("x0_error"), x0err);

    return True;
}

Bool sinusoidfitter::setstate(const GlishRecord& state)
{
    Bool ok = True;
    LogOrigin OR("sinusoidfitter", 
		 "setstate(GlishRecord& state)",
		 id(), WHERE);
    LogMessage msg(OR);

    GlishArray stateValue;
    Bool parmsHasBeenSet = False;
    for (uInt i=0; i<state.nelements(); i++) {
	if (state.get(i).type() == GlishValue::ARRAY) {
	    stateValue = state.get(i);
	    if (state.name(i) == "maxiter") {
		Int maxiter;
		stateValue.get(maxiter);
		fitter_p.setMaxIter(maxiter);
	    }
	    else if (state.name(i) == "criteria") {
		Double criteria;
		stateValue.get(criteria);
		fitter_p.setCriteria(criteria);
	    }
	    else if (state.name(i) == "amplitude") {
		stateValue.get(parms_p(0));
		parmsHasBeenSet = True;
	    }
	    else if (state.name(i) == "period") {
		stateValue.get(parms_p(1));
		parmsHasBeenSet = True;
	    }
	    else if (state.name(i) == "x0") {
		stateValue.get(parms_p(2));
		parmsHasBeenSet = True;
	    }
	    else {
		String tmp;
		tmp = "This state variable can not be set by the user :" 
		    + state.name(i);
		msg.message(tmp).line(__LINE__);
		LogSink::postGlobally(msg);
	    }
	} else {
	    String tmp;
	    tmp = "This field is a record and is unrecognized :"
		+ state.name(i);
	    msg.message(tmp).line(__LINE__);
	    LogSink::postGlobally(msg);
	}
    }
    if (parmsHasBeenSet) fitter_p.setParameterValues(parms_p);
    // chisq is always reset by this operation
    chisq_p = 0;

    return ok;
}

String sinusoidfitter::className() const
{
    return "sinusoidfitter";
}

Vector<String> sinusoidfitter::methods() const
{
    Vector<String> methods(NUMBER_METHODS);
    methods(FIT) = "fit";
    methods(EVAL) = "eval";
    methods(SETSTATE) = "setstate";
    methods(GETSTATE) = "getstate";
    return methods;
}

Vector<String> sinusoidfitter::noTraceMethods() const
{
  return methods();
}

MethodResult sinusoidfitter::runMethod(uInt which, 
				       ParameterSet &params,
				       Bool runMethod)
{
    static String returnvalString = "returnval";
    static String stateString = "state";
    static String xString = "x";
    static String yString = "y";
    static String sigmaString = "sigma";

    switch(which) {
    case FIT:
	{
	    Parameter<Bool> returnval(params, returnvalString, 
				      ParameterSet::Out);
	    Parameter<GlishRecord> state(params, stateString, ParameterSet::Out);
	    Parameter< Vector<Double> > x(params, xString, ParameterSet::In);
	    Parameter< Vector<Double> > y(params, yString, ParameterSet::In);
	    Parameter< Vector<Double> > sigma(params, sigmaString, ParameterSet::In);
	    if (runMethod) {
		returnval() = fit(state(), x(), y(), sigma());
	    }
        }
	break;
    case EVAL:
	{
	    Parameter<Bool> returnval(params, returnvalString, 
				      ParameterSet::Out);
	    Parameter< Vector<Double> > y(params, yString, ParameterSet::Out);
	    Parameter< Vector<Double> > x(params, xString, ParameterSet::In);
	    if (runMethod) {
		returnval() = eval(y(), x());
	    }
        }
	break;
    case GETSTATE:
	{
	    Parameter<Bool> returnval(params, returnvalString, 
				      ParameterSet::Out);
	    Parameter<GlishRecord> state(params, stateString, ParameterSet::Out);
	    if (runMethod) {
		returnval() = getstate(state());
	    }
        }
    break;
    case SETSTATE:
	{
	    Parameter<Bool> returnval(params, returnvalString, 
				      ParameterSet::Out);
	    Parameter<GlishRecord> state(params, stateString, ParameterSet::In);
	    if (runMethod) {
		returnval() = setstate(state());
	    }
        }
    break;
    default:
	return error("No such method");
    }

    return ok();
}

void sinusoidfitter::init() {
    Sinusoid1D<AutoDiff<Double> > sfunc;
    fitter_p.setFunction(sfunc);

    parms_p(0) = sfunc.amplitude().value();
    parms_p(1) = sfunc.period().value();
    parms_p(2) = sfunc.x0().value();

    chisq_p = 0.0;
}

