//# DOinterpolate1d.cc
//# Copyright (C) 1996,1998,1999,2001
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
//# $Id: DOinterpolate1d.cc,v 19.6 2005/11/07 21:17:04 wyoung Exp $

//# Includes

#include <appsglish/numerics/DOinterpolate1d.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/Parameter.h>
#include <casa/Arrays/Vector.h>
#include <scimath/Functionals/ScalarSampledFunctional.h>
#include <casa/Logging.h>
#include <casa/BasicSL/String.h>
#include <casa/iostream.h>

#include <casa/namespace.h>
interpolate1d::interpolate1d()
{
    // Nothing
}

interpolate1d::~interpolate1d()
{
    // Nothing
}

Vector<Double> interpolate1d::interpolate(const Vector<Double>& x)
{
    Vector<Double> yinterp(x.nelements());
    yinterp = x;
    yinterp.apply(itsInterpolator);

    return yinterp;
}

Bool interpolate1d::initialize(const Vector<Double>& x, 
			       const Vector<Double>& y,
			       const String &method)
{
    if (x.nelements() != y.nelements()) {
	return False;
    }

    itsInterpolator.setData(ScalarSampledFunctional<Double>(x),
		     ScalarSampledFunctional<Double>(y));
    setmethod(method);
    return True;
}
	     
void interpolate1d::setmethod(const String& method)
{
    if (method == "linear") {
	itsInterpolator.setMethod(Interpolate1D<Double,Double>::linear);
    } else if (method.contains("near")) {
	itsInterpolator.setMethod(Interpolate1D<Double,Double>::nearestNeighbour);
    } else if (method == "cubic") {
	itsInterpolator.setMethod(Interpolate1D<Double,Double>::cubic); 
    } else if(method == "spline") {
	itsInterpolator.setMethod(Interpolate1D<Double,Double>::spline);
    } else {
	LogOrigin OR("interpolate1d", "setmethod(const String& method)",
		     WHERE);
	LogMessage msg(OR, LogMessage::SEVERE);
	msg.message(String("Unknown method=") + method + ": must be one of " +
	    "linear, nearest_neighbor, cubic, spline").line(__LINE__);
	LogSink::postGloballyThenThrow(msg);
    }
}

String interpolate1d::className() const
{
    return "interpolate1d";
}

Vector<String> interpolate1d::methods() const
{
    Vector<String> tmp(3);
    tmp(0) = "interpolate";
    tmp(1) = "initialize";
    tmp(2) = "setmethod";
    return tmp;
}

Vector<String> interpolate1d::noTraceMethods() const {
  Vector<String> tmp(3);
  tmp(0) = "interpolate";
  tmp(1) = "initialize";
  tmp(2) = "setmethod";
  return tmp;
}

MethodResult interpolate1d::runMethod(uInt which, 
                                   ParameterSet &params,
                                   Bool runMethod)
{
    static String returnvalString = "returnval";
    static String xString = "x";
    static String yString = "y";
    static String methodString = "method";

    switch(which) {
    case 0:
	{
	    Parameter< Vector<Double> > returnval(params, returnvalString, 
					       ParameterSet::Out);
	    Parameter< Vector<Double> > x(params, xString, ParameterSet::In);
	    if (runMethod) {
		returnval() = interpolate(x());
	    }
        }
    break;
    case 1:
	{
	    Parameter<Bool> returnval(params, returnvalString, 
				      ParameterSet::Out);
	    Parameter< Vector<Double> > x(params, xString, ParameterSet::In);
	    Parameter< Vector<Double> > y(params, yString, ParameterSet::In);
	    Parameter<String> method(params, methodString, ParameterSet::In);
	    if (runMethod) {
		returnval() = initialize(x(), y(), method());
	    }
        }
    break;
    case 2:
	{
	    Parameter<String> method(params, methodString, ParameterSet::In);
	    if (runMethod) {
		setmethod(method());
	    }
        }
    break;
    default:
	return error("No such method");
    }

    return ok();
}

// Local Variables: 
// compile-command: "gmake OPTLIB=1 DOinterpolate1d"
// End: 
