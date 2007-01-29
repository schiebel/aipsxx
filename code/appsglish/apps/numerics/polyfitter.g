# polyfitter.g: Startup script for numerics DO servers
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: polyfitter.g,v 19.2 2004/08/25 01:45:18 cvsmgr Exp $
#
pragma include once

include "servers.g";
include "note.g"

# server := polyfitter()
# polyfitterdemo()
# polyfittertest()
#    ok := polyfitter.fit(coeff,coefferrs,chisq,x,y,sigma,order)
#    ok := polyfitter.multifit(coeff,coefferrs,chisq,x,y,sigma,order)
#    ok := polyfitter.eval(y,errmxg,x,coeff)
#

const polyfitter := function(host='', forcenewserver=F) {
  private := [=];
  public := [=];

  private.agent := defaultservers.activate("numerics", host, forcenewserver);
  private.id := defaultservers.create(private.agent, "polyfitter");

  private.fitRec := [_method="fit", _sequence=private.id._sequence];
  public.fit := function(ref coeff, ref coefferrs, ref chisq, 
			 x, y, sigma=1.0, order=1) {
    wider private;
    private.fitRec.coeff := coeff;
    private.fitRec.coefferrs := coefferrs;
    private.fitRec.chisq := chisq;
    local a := max(abs(max(x)), abs(min(x)));
    if (a == 0) a:= 1;
    private.fitRec.x := x*a;
    private.fitRec.y := y;
    private.fitRec.sigma := sigma;
    private.fitRec.order := order;
    returnval := defaultservers.run(private.agent, private.fitRec);
    local b := a^(ind(private.fitRec.coeff)-1);
    val coeff := private.fitRec.coeff*b;
    val coefferrs := private.fitRec.coefferrs*b;
    val chisq := private.fitRec.chisq;
    return returnval;
  }

  private.multifitRec := [_method="multifit", _sequence=private.id._sequence];
  public.multifit := function(ref coeff, ref coefferrs, ref chisq,
			      x, y, sigma=1.0, order=1) {
    wider private;
    private.multifitRec.coeff := coeff;
    private.multifitRec.coefferrs := coefferrs;
    private.multifitRec.chisq := chisq;
    private.multifitRec.x := x;
    private.multifitRec.y := y;
    private.multifitRec.sigma := sigma;
    private.multifitRec.order := order;
    returnval := defaultservers.run(private.agent, private.multifitRec);
    val coeff := private.multifitRec.coeff;
    val coefferrs := private.multifitRec.coefferrs;
    val chisq := private.multifitRec.chisq;
    return returnval;
  }

  private.evalRec := [_method="eval", _sequence=private.id._sequence];
  public.eval := function(ref y, x, coeff) {
    wider private;
    private.evalRec.y := y;
    private.evalRec.x := x;
    private.evalRec.coeff := coeff;
    returnval := defaultservers.run(private.agent, private.evalRec);
    val y := private.evalRec.y;
    return returnval;
  }

  public.type := function() {return 'polyfitter';}
    
  public.done := function() {
    wider public, private;
    ok := defaultservers.done(private.agent, private.id.objectid);
    if (ok) {
      val private := F;
      val public := F;
    }
    return ok;
  }
#  plugins.attach('componentlist', public);
    
  return ref public;
} # polyfitter constructor

const polyfitterdemo := function() {
  # make the fitter
  fitter := polyfitter();
    
  # make some fake data
  x := [1:10];
  y := x*x + 5;
    
  # Fit the data (sigma defaults to be one)
  local coeff, coefferrs, chisq
  ok := fitter.fit(coeff, coefferrs, chisq, x, y, order=2);

  note('ok := fitter.fit(coeff, coefferrs, chisq, x, y, sigma, order)',
       '\n\tx=', x, '(input)',
       '\n\ty=', y, '(input) (x*x+5)',
       '\n\tsigma=1 (input) (default)',
       '\n\torder=2 (input)  (up to second order polynomial)',
       '\n\tok=', ok, '(output) (did the fit succeed)',
       '\n\tcoeff=', coeff, '(output) (fit coefficients)',
       '\n\tchisq=', chisq, '(output) (chi-square of the fit)',
       '\n\tcoefferrs=', coefferrs, '(output) (est. error in coefficients)',
       origin='polyfitterdemo()');
    
  y := 0;
  ok := fitter.eval(y, x, coeff);
  note('ok := fitter.eval(y, errmsg, x, coeff)',
       '\n\tx=', x, '(input)',
       '\n\tcoeff=', coeff, '(input) (polynomial coefficients)',
       '\n\tok=', ok, '(output) (did the evaluation succeed)',
       '\n\ty=', y, '(output) (fit polynomial evaluated at x)',
       origin='polyfitterdemo()');

  # Fit the data (sigma defaults to be one)
  y := array(0, length(x), 3);
  y[,1] := 5;
  y[,2] := 2*x;
  y[,3] := 10*x*x;
  ok := fitter.multifit(coeff, coefferrs, chisq, x, y, order=2);

  note('ok := fitter.multifit(coeff, coefferrs, chisq, x, y, sigma, order)',
       '\n\tx=', x, '(input)',
       '\n\ty=', y, '(input) 5,(2*x),(10*x*x)',
       '\n\tsigma=1 (input) (default)',
       '\n\torder=2 (input)  (up to second order polynomial)',
       '\n\tok=', ok, ' (output) (did the fit succeed)',
       '\n\tcoeff=', coeff, '(output) (fit coefficients)',
       '\n\tchisq=', chisq, '(output) (chi-square of the fit)',
       '\n\tcoefferrs=', coefferrs, '(output) (est. error in coefficients)',
       origin='polyfitterdemo()');

  y := array(0,3);
  ok := fitter.eval(y, x, coeff);
  note('ok := fitter.eval(y, errmsg, x, coeff)',
       '\n\tx=', x, '(input)',
       '\n\tcoeff=',coeff, '(input) (polynomial coefficients)',
       '\n\tok=', ok, ' (output) (did the evaluation succeed)',
       '\n\ty=', y, '(output) (fit polynomials evaluated at x)',
       origin='polyfitterdemo()');

  return T;
}

const polyfittertest := function() {
  note('Just running polyfitterdemo() - we should have a real test',
       origin='polyfittertest()');
  return polyfitterdemo();
}
