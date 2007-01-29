// gfitgaus.cc:  a glish client for the gaussian fitter
//# Copyright (C) 1995,1996,2000,2001,2002
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office   }

//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: gfitgauss.cc,v 19.4 2004/11/30 17:50:07 ddebonis Exp $
//#--------------------------------------------------------------------------
#include <GaussFitState.h>

#include <casa/BasicSL/String.h>
#include <tasking/Glish.h>
#include <casa/Arrays/Vector.h>
#include <casa/Exceptions/Error.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayIO.h>
#include <scimath/Functionals/Gaussian1D.h>
#include <scimath/Fitting/NonLinearFitLM.h>
//#----------------------------------------------------------------------------
#include <casa/stdio.h>
#include <assert.h>
#include <casa/string.h>
#include <unistd.h>
#include <casa/iostream.h>
//#---------------------------------------------------------------------------

#include <casa/namespace.h>

//#---------------------------------------------------------------------------
Bool fitXY (GlishSysEvent &event, void *);
Bool evalGaussian (GlishSysEvent &event, void *);
Bool queryState (GlishSysEvent &event, void *);
Bool setState (GlishSysEvent &event, void *);
Bool defaultHandler (GlishSysEvent &event, void *);
//#---------------------------------------------------------------------------
GaussFitState state_;
//#----------------------------------------------------------------------------
int main (int argc, char **argv)
{
    try {

	GlishSysEventSource glishStream (argc, argv);
	glishStream.setDefault (defaultHandler);
	glishStream.addTarget  (fitXY,            "^fitXY$");
	glishStream.addTarget  (evalGaussian,     "^evalGaussian$");
	glishStream.addTarget  (queryState,       "^queryState$");
	glishStream.addTarget  (setState,         "^setState$");
	glishStream.loop ();
    } 
    catch   (AipsError x) {
	cerr << "----------------------- exception! -------------------" << endl;
	cerr << "Exception Caught" << endl;
    } 

    return 0;

} // main
//#----------------------------------------------------------------------------
//#----------------------------------------------------------------------------
Bool defaultHandler (GlishSysEvent &event, void *)
{
    GlishSysEventSource *src =  event.glishSource ();     
    src->postEvent ("default_result", event.type ());        
    return True;                                     
}                                                    
//----------------------------------------------------------------------------
Bool fitXY (GlishSysEvent &event, void *)
{
    GlishValue glishValue = event.val ();
    GlishSysEventSource *glishBus =  event.glishSource ();     

    // does the event contain a record?
    if (glishValue.type () != GlishValue::RECORD)  {
	glishBus->postEvent ("fitXY_result", 
			     "fitXY error: argument not a record");
	return True;
    }

    GlishRecord record = glishValue;
    GlishArray glishArray;

    Vector <Double> x;
    IPosition shape;
    
    // get the data from the record
    if (!record.exists ("x")) {
	glishBus->postEvent ("fitXY_result", "fitXY error: no <x> field");
	return True;
    }
    else {
	glishArray = record.get ("x");
	shape = glishArray.shape ();
	if (shape.nelements () != 1) {
	    glishBus->postEvent ("fitXY_result", "fitXY error: dimension != 1");
	    return True;
	}
	uInt vectorLength = glishArray.nelements ();
	x.resize (vectorLength);
	glishArray.get (x);
    }
    
    Vector <Double> y(x.nelements());
    
    // get the data from the record
    if (!record.exists ("y")) {
	glishBus->postEvent ("fitXY_result", "fitXY error: no <y> field");
	return True;
    }
    else {
	glishArray = record.get ("y");
	shape = glishArray.shape ();
	if (shape.nelements () != 1) {
	    glishBus->postEvent ("fitXY_result", "fitXY error: dimension != 1");
	    return True;
	}
	uInt vectorLength = glishArray.nelements ();
	// must have same length as x
	if (vectorLength != x.nelements()) {
	    glishBus->postEvent("fitXY_result","fitXY error : "
				"length of y != length of x");
	    return True;
	}
	
	glishArray.get (y);
    }
    
    Vector <Double> sigma (x.nelements ());  
    // get the data from the record
    if (!record.exists ("sigma")) {
	// Equal weights
	sigma = 1.0f;
    }
    else {
	glishArray = record.get ("sigma");
	shape = glishArray.shape ();
	if (shape.nelements () != 1) {
	    glishBus->postEvent ("fitXY_result", "fitXY error: dimension != 1");
	    return True;
	}
	uInt vectorLength = glishArray.nelements ();
	if (vectorLength != x.nelements()) {
	    glishBus->postEvent("fitXY_result","fitXY error : "
				"length of sigma != length of x");
	    return True;
	}
	glishArray.get (sigma);
    }

    // extract any state information from this record
    state_.setState(record);

    // set up the fitter using the state information
    if (!state_.setUpFitter()) {
	glishBus->postEvent("fitXY_result","fitXY error : "
			    "initial guesses are inconsistent");
	return True;
    }

    // now perform the fit
    Vector<Double> solution = state_.fitter().fit (x, y, sigma);

    state_.fitter().setParameterValues(solution);

    state_.getStateFromFitter();

    // reformate the state
    GlishRecord result(state_.state());
    // add the value of chisq for this fit
    Double chisq = state_.fitter().chiSquare();
    result.add(String("chisq"), chisq);

    glishBus->postEvent ("fitXY_result", result);

    return True;

} // fit xy
//----------------------------------------------------------------------------
Bool evalGaussian (GlishSysEvent &event, void *)
{
    GlishValue glishValue = event.val ();
    GlishSysEventSource *glishBus =  event.glishSource ();     

    // does the event contain a record?
    if (glishValue.type () != GlishValue::RECORD)  {
	glishBus->postEvent ("evalPolynomial_result", 
			     "evalPolynomial error: argument not a record");
	return True;
    }

    GlishRecord record = glishValue;
    GlishArray glishArray;

    IPosition shape;
    
    Vector <Double> x;
    
    // get the data from the record
    if (!record.exists ("x")) {
	glishBus->postEvent ("evalGaussian_result", 
			     "evalGaussian error: no <x> field");
	return True;
    }
    else {
	glishArray = record.get ("x");
	shape = glishArray.shape ();
	if (shape.nelements () != 1) {
	    glishBus->postEvent ("evalGaussian_result", 
				 "evalGaussian error: dimension != 1");
	    return True;
	}
	uInt vectorLength = glishArray.nelements ();
	x.resize (vectorLength);
	glishArray.get (x);
    }
    
    uInt size = x.nelements ();
    Vector <Double> y (size);

    // get any state information 
    state_.setState(record);

    if (!state_.setUpFitter()) {
	glishBus->postEvent("evalGaussian_result",
			    "evalGaussian error: parameters are inconsistent");
	return True;
    }

    // and evaluate the function in the fitter
    Function<AutoDiff<Double> > *sumfunc = state_.fitter().fittedFunction();
    for (uInt i=0;i<size;i++) y(i) = (*sumfunc)(x(i)).value();

    glishBus->postEvent("evalGaussian_result", y);


    return True;

}                                                    
//----------------------------------------------------------------------------
Bool queryState (GlishSysEvent &event, void *) 
{
    GlishSysEventSource *glishBus =  event.glishSource (); 
    glishBus->postEvent("queryState_result", state_.state());
    return True;
}
//----------------------------------------------------------------------------

Bool setState (GlishSysEvent &event, void *)
{
    GlishValue glishValue = event.val ();
    GlishSysEventSource *glishBus =  event.glishSource ();     

    // does the event contain a record?
    if (glishValue.type () != GlishValue::RECORD)  {
	glishBus->postEvent ("setState_result", 
			     "setState error: argument not a record");
	return True;
    }

    GlishRecord record = glishValue;

    state_.setState(record);

    glishBus->postEvent("setState_result","ok");
    return True;
}
//----------------------------------------------------------------------------
