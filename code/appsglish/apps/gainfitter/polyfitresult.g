# gainpolyfitter_fitter.g: Performs fits for gainpolyfitter.
# Copyright (C) 2001,2002
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: polyfitresult.g,v 19.1 2004/08/25 01:17:21 cvsmgr Exp $

pragma include once

include 'polyfitter.g'

#@itemcontainer PolyFitResultItem
# contains the results of a polynomial fit 
# @field type      must be set to 'PolyFitResultItem' 
# @field order     the order of the fit.  That is, the number of polynomial
#                      components
# @field coeff     the array of fit coefficients
# @field error     the array of errors for the coefficients
# @field chisq     the chi-square value for the fit
# @field n         the number of measurements that went into the fit.
# @field state     the validity of the fit.  Allowed values (in order of
#                     completeness):
#                       POLYFITSTATE.NONE       no valid fit loaded yet
#                       POLYFITSTATE.NEED       current fit is invalid; a new
#                                                  one is needed
#                       POLYFITSTATE.FAILED     last fit attempt failed
#                       POLYFITSTATE.OK         last fit attempt was successful
#                                                  and fit information is valid.
#                       POLYFITSTATE.EVALUATED  last fit attempt was successful
#                                                  and have been evaluated over
#                                                  a range of interest.
# @field deforder  the default order

const POLYFITSTATE := [NONE=0, NEED=1, FAILED=2, OK=3, EVALUATED=4];

const POLYFITRESULTITEM := 'PolyFitResultItem';

#@tool public
#  a tool for handling results from a polynomial fit
#
# @constructor
# create a polyfitresult tool
# @param defaultorder    the default order for the result
##
const polyfitresult := function(order=DEFAULTORDER) {

    result := [type=POLYFITRESULTITEM, order=order, coeff=F, error=F, 
	       chisq=F, state=POLYFITSTATE.NONE, defaultorder=order, n=0];
    public := [type='polyfitresult'];

    # return the default order
    public.getdefaultorder := function() { 
	wider result; 
	return result.defaultorder; 
    }

    # return the current order
    public.getorder := function() { wider result; return result.order; }

    # update the current order.  
    # @param order   the order to set; if not given (or is <0), the 
    #                   current order is set to the default established 
    #                   a construction
    public.setorder := function(order=-1) {
	wider result;
	if(order < 0) {
	    result.order := result.defaultorder;
	    result.state := POLYFITSTATE.NONE;
	}
	else {
	    result.order := order;
	    if (result.state != POLYFITSTATE.NONE) 
		result.state := POLYFITSTATE.NEED;
	}
	return T;
    }

    # Set fit state.
    # @param state   the state to set; should be equal to one of the 
    #                   defined values in POLYFITSTATE (or fail is 
    #                   returned).  The default is POLYFITSTATE.NEED.
    public.setfitstate := function(state=POLYFITSTATE.NEED) {
	wider result;
	if (state > len(POLYFITSTATE)-1) 
	    fail paste("polyfitresult: bad value for setfitstate():", state);

	result.state := state;
	return T;
    }

    # Get the fit state.  
    # @return int   a value equal to one of the states defined in POLYFITSTATE.
    public.getfitstate := function() { wider result; return result.state; }

    # return the result information as a PolyFitResultItem
    public.getdata := function() { wider result; return result; }

    # an assignment operator.  
    # @param item     a PolyFitResultItem containing the result data
    # @param invalid  if true (default), the fit will be considered invalid.
    public.assign := function(item, invalid=T) {
	wider result;

	if (item.type != POLYFITRESULTITEM) 
	    fail paste("polyfitresult.assign(): input not a", 
		       POLYFITRESULTITEM);

	result := item;
	if (invalid) result['state'] := POLYFITSTATE.NEED;
	return T;
    }
	
    # Perform a fit on a region if necessary and store the results
    # internally.  The current order will be used if there are enough
    # data in the input arrays; otherwise the order will be reduced 
    # accordingly.  In no data is available, no fit is attempted.
    # @param xin   	  the independent variable 
    # @param yin   	  the dependent variable
    # @param ein   	  the error on y. Uses current order.
    # @param ifnecessary  if T, the fit will only be done if the current 
    #                       results are invalid
    # @return int  the actual order used.  If no fit is possible, -1 is 
    #                 returned.
    public.fit := function(xin, yin, ein, fitter, ifnecessary=F) {
	wider result;
	
	npts := len(xin);
	result.n := npts;
	if(npts <= result.order) {	# Not enough to do fit.

	    if(npts <= 0) {
		result.state := POLYFITSTATE.NONE;
		return -1;
	    }
	    result.order := npts-1;
	}

	if(!fitter.fit(coeff, coefferrs, chisq,
		       xin, yin, sigma=ein, order=result.order))
	{
	    # Fit Failed.
	    result.state := POLYFITSTATE.FAILED;
	    return -1;
	}

	result.coeff := coeff;
	result.error := coefferrs;
	result.chisq := chisq;
	result.state := POLYFITSTATE.OK;

	return result.order;
    }

    # evaluate the fit for a given array of points.  False is returned if the 
    # current state is not OK.
    public.eval := function(ref yout, xin, fitter) {
	wider result;

	if (result.state < POLYFITSTATE.OK) return F;

	ok := fitter.eval(yout, xin, result.coeff);
	if (is_fail(ok) || ! ok) {
	    return ok;
	} else {
	    return T;
	}
    }

    # shut down this tool
    public.done := function() { public := F; }

    return ref public;
}

const polyfitresulttest := function(fitorder=3) {

    include 'mathematics.g';

    coeff := seq(fitorder,0);

    rand := randomnumbers();
    err := rand.normal(100, 2, 50) / 100 - 1;
    rand.done();

    fitter := polyfitter();
    xin := seq(0, 49);
    yideal := [];
    fitter.eval(yideal, xin, coeff);
    yobs := yideal + err;

    r := polyfitresult(1);
    tests := [=];
    tests['construction'] := 
	(has_field(r, 'type') && r.type == 'polyfitresult' && 
	 r.getorder() == 1);
    if (! tests.construction) fail "polyfitresult construction failed";
    tests['getdata'] := (r.getdata().type == POLYFITRESULTITEM);
    r.setorder(2);
    tests['setorder'] := (r.getdata().order == 2);
    tests['getorder'] := (r.getorder() == 2);
    tests['getfitstate'] := (r.getfitstate() == POLYFITSTATE.NONE);

    r.setorder(fitorder);
    ein := rep(0.02, 50);
    ok := r.fit(xin, yobs, ein, fitter);
    fitter.done();
    if (is_boolean(ok) || is_fail(ok)) {
	test['fit'] := F;
	return;
    }

    item := r.getdata();
    print "results = ", item;
    tests['fit'] := (item.state >= POLYFITSTATE.OK && 
		     len(item.coeff) == fitorder+1 && 
		     len(item.error) == fitorder+1 &&
		     is_double(item.chisq) && item.chisq != 0 && 
		     ok == fitorder);
    tests.results := T;
    for (i in [1:len(item.coeff)]) {
	test.results := (abs(item.coeff[i]-coeff[i]) < item.error[i]);
	if (! test.results) break;
    }
    if (tests.results) tests.results := (item.chisq < 30);

    tnames := field_names(tests);
    succeed := 0;
    failed := 0;
    ftests := [''];
    for(name in tnames) {
	if (tests[name]) {
	    succeed +:= 1;
	} else {
	    failed +:= 1;
	    ftests[failed] := name;
	}
    }
    print spaste("Tests succeeded=", succeed, "; failed=", failed);
    if (failed > 0) {
	print "Failed tests: ", ftests;
    }
    return (failed == 0);
}
