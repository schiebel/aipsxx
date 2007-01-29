# sinusoidfitter.g: The glish side of the sinusoidfitter distributed object
#
#   Copyright (C) 1996,1997,1998,1999
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
#   $Id: sinusoidfitter.g,v 19.2 2004/08/25 01:45:53 cvsmgr Exp $
#
pragma include once

include 'servers.g';
include 'note.g';
# server := sinusoidfitter()
# sinusoidfitterdemo()
# sinusoidfittertest()
#    ok := sinusoidfitter.fit(state, x, y, sigma=1)
#    ok := sinusoidfitter.eval(y, x)
#    ok := sinusoidfitter.setstate(state)
#    ok := sinusoidfitter.getstate(state)
#
const sinusoidfitter := function(host='', forcenewserver=F) {
  private := [=];
  public := [=];

  private.agent := defaultservers.activate("numerics", host, forcenewserver);
  private.id := defaultservers.create(private.agent, "sinusoidfitter");

  private.fitRec := [_method="fit", _sequence=private.id._sequence];
  public.fit := function(ref state, x, y, sigma=1.0) {
    wider private;
    private.fitRec.state := state;
    private.fitRec.x := x;
    private.fitRec.y := y;
    private.fitRec.sigma := sigma;
    returnval := defaultservers.run(private.agent, private.fitRec);
    val state := private.fitRec.state;
    return returnval;
  }

  private.evalRec := [_method="eval", _sequence=private.id._sequence];
  public.eval := function(ref y, x) {
    wider private;
    private.evalRec.y := y;
    private.evalRec.x := x;
    returnval := defaultservers.run(private.agent, private.evalRec);
    val y := private.evalRec.y;
    return returnval;
  }

  private.setstateRec := [_method="setstate", _sequence=private.id._sequence];
  public.setstate := function(state) {
    wider private;
    private.setstateRec.state := state;
    returnval := defaultservers.run(private.agent, private.setstateRec);
    return returnval;
  }
	
  private.getstateRec := [_method="getstate", _sequence=private.id._sequence];
  public.getstate := function(ref state) {
    wider private;
    private.getstateRec.state := state;
    returnval := defaultservers.run(private.agent, private.getstateRec);
    val state := private.getstateRec.state;
    return returnval;
  }

  public.type := function() {return 'sinusoidfitter';}

  return public;
} # sinusoid constructor

const sinusoidfitterdemo := function() {
  # make the fitter
  fitter := sinusoidfitter();
  
  # initial state of fitter
  state := [=];
  ok := fitter.getstate(state);

  note('ok := fitter.getstate(state)',
       '\n\tstate=', state, '(output) (state of fitter)',
       '\n\tok=',ok,' (result of function execution)',
       origin='sinusoidfitterdemo');

  # make some fake data, with a long enough period
  # so that the sinusoid is reasonably well sampled
  amp := 2.0;
  x0 := 20.0;
  p := 40.0;
  x := [1:100];
  y := amp * cos(2*pi*(x-x0)/p);

  # make an initial guess, it is important that
  # the initial period guessed be not too short or
  # the fitter will quickly find a bad minimum
  state := [=];
  state.amplitude := 1.0;
  state.period := 65.0;
  state.x0 := 0.0;
  state.maxiter := 20;
  ok := fitter.setstate(state);
  note('ok := fitter.setstate(state)',
       '\n\tstate=', state, '(input) (state of fitter)',
       '\n\tok=',ok,' (result of function execution)',
       origin='sinusoidfitterdemo');
  
  # Fit the data
  ok := fitter.fit(state, x, y);
  
  note('ok := fitter.fit(state, x, y)',
       '\n\tx=[1:100] (input)',
       '\n\ty=',amp,'*cos(2*pi*(x-',x0,')/',p,') (input) (x*x+5)',
       '\n\tstate=', state, '(output) (resulting state of fitter)',
       '\n\tok=',ok,' (result of function execution)',
       origin='sinusoidfitterdemo');

  yfit := 0;
  ok := fitter.eval(yfit, x);
  note('ok := fitter.eval(yfit, errmsg, x)',
       '\n\tx=[1:100](input)',
       '\n\tsum(abs(yfit-y))/len(yfit)=', sum(abs(yfit-y))/len(yfit), 
       '(output) (mean diff from input y of fit after eval)',
       '\n\tok=',ok,' (result of function execution)',
       origin='sinusoidfitterdemo');

  # set state of fitter
  state := [=];
  state.period := 5.0;
  state.maxiter := 10;
  # this will generate an error message since it can not
  # be set by the user
  state.curriter := 0.0;

  ok := fitter.setstate(state);

  note('ok := fitter.setstate(state)',
       '\n\tstate=', state, '(input) (state of fitter)',
       '\n\tok=',ok,' (result of function execution)',
       origin='sinusoidfitterdemo');

  # get state of fitter
  ok := fitter.getstate(state);
  
  note('ok := fitter.getstate(state)',
       '\n\tstate=', state, '(output) (state of fitter)',
       '\n\tok=',ok,' (result of function execution)',
       origin='sinusoidfitterdemo');

    return T
}

const sinusoidfittertest := function() {
  note('Just running sinusoidfitterdemo() - we should have a real test',
       origin='sinusoidfittertest');
  return sinusoidfitterdemo();
}

