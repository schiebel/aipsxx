# gfitgauss.g: convenience functions for the gfitgauss.cc glish client
#
#   Copyright (C) 1995, 1999
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: gfitgauss.g,v 19.1 2004/08/25 01:17:51 cvsmgr Exp $
#
#----------------------------------------------------------------------------
pragma include once;

include 'note.g';
include 'pgplotter.g';

# The gfitgauss closure - temporary until there is a DO gaussian fitter
# and this can be removed entirely.  The original simple functional
# interface is still here to ensure that existing uses do not break.
# Adding a closure makes it possible to have this appear as a tool
# via meta information and to be documented easily in the reference manual.

# this is still necessary in order to ensure that there be only one
# gfitgauss client.  By default, don't start it until asked to do so.

__fitGaussClient__ := F;

const fitGaussClient := function() {
    global __fitGaussClient__;
    if (!is_agent(__fitGaussClient__)) {
	__fitGaussClient__ := client ("gfitgauss");
	whenever __fitGaussClient__->done do { val __fitGaussClient__ := F; deactivate; }
    }
    return __fitGaussClient__;
}

#------------------------------------------------------------------------------
# That this is needed is embarassing, but it is, for now.
__factor__ := 0;

#------------------------------------------------------------------------------
const fitGauss := function (x_, y_)
{

  args := [x = x_, y = y_];

  state := queryState();

  fitGaussClient()->fitXY (args)
  await fitGaussClient()->fitXY_result;
  result_record := $value;
  if (is_record(result_record)) {
      if (result_record.converged == F) {
	  note('Warning: fit has not converged', priority='WARN', origin='fitGauss');
      } else {
#                multiply errors by sqrt(chisq/dof)
#                save this as factor for use elsewhere 
	  ngauss := len(state.height);
	  dof := len(x_) - (ngauss*3.0); 
	  __factor__ := sqrt(result_record.chisq/dof);
	  result_record.height_error *:= __factor__;
	  result_record.center_error *:= __factor__;
	  result_record.width_error *:= __factor__;
      } 
  } else {
      result_record := throw(as_string(result_record), 'fitGauss');
  }
  return result_record;
}
#------------------------------------------------------------------------------
const evalGauss := function (x_)
{

  args := [x = x_];

  fitGaussClient()->evalGaussian (args)
  await fitGaussClient()->evalGaussian_result;
  return $value;
}

const evalGaussian := evalGauss;

#------------------------------------------------------------------------------
const setHeight := function (height_)
{
  args := [height=height_];
  fitGaussClient()->setState(args);
  await fitGaussClient()->setState_result;
  return $value;
}
const setCenter := function (center_)
{
  args := [center=center_];
  fitGaussClient()->setState(args);
  await fitGaussClient()->setState_result;
  return $value;
}
const setWidth := function (width_)
{
  args := [width=width_];
  fitGaussClient()->setState(args);
  await fitGaussClient()->setState_result;
  return $value;
}
const setMaxIter := function (maxIter_)
{
  args := [maxIter=maxIter_];
  fitGaussClient()->setState(args);
  await fitGaussClient()->setState_result;
  return $value;
}
const setCriteria := function (criteria_)
{
  args := [criteria=criteria_];
  fitGaussClient()->setState(args);
  await fitGaussClient()->setState_result;
  return $value;
}
const queryState := function()
{
 fitGaussClient()->queryState();
 await fitGaussClient()->queryState_result;
 state := $value;
#            multiply errors by  __factor__ if non-zero
 if (__factor__ != 0) {
     state.height_error *:= __factor__;
     state.center_error *:= __factor__;
     state.width_error *:= __factor__;
 }
 return $value;
}
const setState := function(rec)
{
 fitGaussClient()->setState(rec)
 await fitGaussClient()->setState_result;
 return $value;
}
#------------------------------------------------------------------------------

# this closure is just a front end to the above function
# It will exist until this entire client can be replaced by a
# better, more flexible, fitter which will be a true DO.
# This closure exists so that (a) meta information can be
# supplied so that this is available as a tool and (b) it
# can be easily described in the reference manual.

const gauss1dfitter := function()
{

    private := [=];
    public := [=];

    private.nan := 0/0;

    private.getval := function(rec, resultName, defaultValue) {
	result := defaultValue;
	if (has_field(rec, resultName)) result := rec[resultName];
	return result;
    }

    const public.fit := function(x, y) {
	wider private;
	result := fitGauss(x,y);
	if (is_fail(result)) fail;
	# do this to downcase names and remove _ from names
	newresult := [=];
	newresult.converged := private.getval(result,'converged',F);
	newresult.curriter := private.getval(result,'currentIteration',-1);
	newresult.maxiter := private.getval(result,'maxIter',-1);
	newresult.criteria := private.getval(result,'criteria',private.nan);
	newresult.chisq := private.getval(result,'chisq',private.nan);
	newresult.height := private.getval(result,'height',private.nan);
	newresult.center := private.getval(result,'center',private.nan);
	newresult.width := private.getval(result,'width',private.nan);
	newresult.heighterror := private.getval(result,'height_error',private.nan);
	newresult.centererror := private.getval(result,'center_error',private.nan);
	newresult.widtherror := private.getval(result,'width_error',private.nan);

	return result;
    }

    const public.eval := function(x) {
	return evalGauss(x);
    }

    const public.setheight := function(height) {
	ok := setHeight(height);
	if (!is_fail(ok)) ok := ok == "ok";
	return ok;
    }

    const public.setcenter := function(center) {
	ok := setCenter(center);
	if (!is_fail(ok)) ok := ok == "ok";
	return ok;
    }

    const public.setwidth := function(width) {
	ok := setWidth(width);
	if (!is_fail(ok)) ok := ok == "ok";
	return ok;
    }

    const public.setmaxiter := function(maxiter) {
	ok := setMaxIter(maxiter);
	if (!is_fail(ok)) ok := ok == "ok";
	return ok;
    }

    const public.setcriteria := function(criteria) {
	ok := setCriteria(criteria);
	if (!is_fail(ok)) ok := ok == "ok";
	return ok;
    }

    const public.getstate := function() {
	# convert field names to all lower case and remove _
	state := queryState();
	newstate := [=];
	if (has_field(state,'converged')) newstate.converged := state.converged;
	if (has_field(state,'currentIteration')) newstate.curriter := state.currentIteration;
	if (has_field(state,'maxIter')) newstate.maxiter := state.maxIter;
	if (has_field(state,'criteria')) newstate.criteria := state.criteria;
	if (has_field(state,'height')) newstate.height := state.height;
	if (has_field(state,'center')) newstate.center := state.center;
	if (has_field(state,'width')) newstate.width := state.width;
	if (has_field(state,'height_error')) newstate.heighterror := state.height_error;
	if (has_field(state,'center_error')) newstate.centererror := state.center_error;
	if (has_field(state,'width_error')) newstate.widtherror := state.width_error;
	return newstate;
    }

    const public.setstate := function(state) {
	# convert field names back to how they are used in setState
	newstate := [=];
	if (has_field(state,'converged')) newstate.converged := state.converged;
	if (has_field(state,'curriter')) newstate.currentIteration := state.curriter;
	if (has_field(state,'maxiter')) newstate.maxIter := state.maxiter;
	if (has_field(state,'criteria')) newstate.criteria := state.criteria;
	if (has_field(state,'height')) newstate.height := state.height;
	if (has_field(state,'center')) newstate.center := state.center;
	if (has_field(state,'width')) newstate.width := state.width;
	if (has_field(state,'heighterror')) newstate.height_error := state.heighterror;
	if (has_field(state,'centererror')) newstate.center_error := state.centererror;
	if (has_field(state,'widtherror')) newstate.width_error := state.widtherror;
	ok := setState(newstate);
	if (!is_fail(ok)) ok := ok == "ok";
	return ok;
    }

    const public.type := function() { return 'gauss1dfitter';}

    const public.done := function() {
	fitGaussClient()->terminate();
	return T;
    }

    return public;
}

# test function
const tfitgauss := function()
{
#    first, create a vector that is the sum of 3 gaussians
   height := [ 5, 15, 10 ]
   center := [40, 50, 60 ]
   width  := [25,  8, 15 ]
#    and the vector of x values
   x := [1:100]
#    set the fitter and evaluate the gaussian
   ok := setHeight(height);
   ok := setCenter(center);
   ok := setWidth(width);
   ytest := evalGauss(x);
   pg := pgplotter();
   ok := pg.plotxy(x,ytest,title='Y-TEST');
#    now, twiddle the above parms to be used as an initial guess
   gh := [ 4, 17, 8.3]
   gc := [38, 51.5, 62]
   gw := [30, 10, 10]
   ok := setState([height=gh,width=gw,center=gc]);
   setMaxIter(20);
#    query the state
   state := queryState()
   note('', origin='tfitgauss')
   note('gauss fitter state after setting height, width and center guesses',origin='tfitgauss');
   note('-----------------------------------------------------------------',origin='tfitgauss');
   note(as_string(state), origin='tfitgauss');
#   and now try and fit the data
   result := fitGauss(x, ytest);
   
   note('',origin='tfitgauss');
   note('fit result',origin='tfitgauss')
   note('----------',origin='tfitgauss');
   note(as_string(result), origin='tfitgauss');

   note('');
   note('expected result',origin='tfitgauss');
   note('---------------',origin='tfitgauss');
   note('height: [ 5, 15, 10 ], center: [40, 50, 60 ], width: [25,  8, 15 ]',origin='tfitgauss');

   state := queryState();
   note('',origin='tfitgauss');
   note('gauss fitter state after fitting data',origin='tfitgauss');
   note('-------------------------------------',origin='tfitgauss');
   note(as_string(state),origin='tfitgauss');
#
   yfit := evalGauss(x);
   ok := pg.plotxy(x,yfit,newplot=F,title='FIT');
#
   resid := ytest - yfit;
   ok := pg.plotxy(x,resid,newplot=F,title='RESIDUALS');
#
   sum := 0;
   sum2 := 0;
   for (n in 1:len(resid)) {
      sum +:= resid[n];
      sum2 +:= resid[n]*resid[n];
   }
   avg := sum / len(resid);
   rms := sum2 - sum*sum / len(resid);
   rms := sqrt(rms / (len(resid) - 1.0));
   note('',origin='tfitgauss');
   note(paste('mean of residuals:',as_string(avg)), origin='tfitgauss');
   note(paste('rms of residuals:',as_string(rms)), origin='tfitgauss');
#
}
