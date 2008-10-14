# functionals.g: Access to functionals classes
# Copyright (C) 2002,2003,2004
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: functionals.g,v 19.4 2004/09/03 07:38:17 cvsmgr Exp $
#
pragma include once;

include 'servers.g';
include 'aipsrc.g';
include 'note.g';
include 'unset.g';
#
##defaultservers.trace(T)
##defaultservers.suspend(T)
#
# Global methods
#
# Check if function
#
const is_functional := function(v) {
  if (is_record(v) && has_field(v, 'state') && is_function(v.state) &&
      has_field(v.state()::, 'id') && v.state()::id == 'fnc') return T;
  return F;
}
#
# Server
#
const functionals := function(host='', forcenewserver = F) {
  private := [=];
  public := [=];
  public::print.limit := 1;
#  defaultservers.suspend(T);
  
  private.agent := defaultservers.activate("functionals", host,
					   forcenewserver);
#  defaultservers.suspend(F);
  
  if (is_fail(private.agent)) return F;
  private.id := defaultservers.create(private.agent, "functionals");
  private.iamdefault := T;
  if (is_defined('dfs') && is_function(dfs.id) && is_function(dfs.done)) {
    private.iamdefault := F;
  };
#
# Private methods
#
# Define the functional defined with nam (like 'gaussian1d'), and with an
# optional order (e.g. for polynomials, gaussianNd).
#
  const private.define := function(nam, order=-1, progtext='', mode=unset) {
    defineRec :=		[_method="define",
				 _sequence=private.id._sequence];
    defineRec.arg := [type=nam, order=order, progtext=progtext];
    if (is_record(mode) && ! is_unset(mode)) defineRec.arg.mode := mode;
    return defaultservers.run(private.agent, defineRec);
  }
#
# Execute a functional and get the values for the specified argument value
# (x is considered to be a vector of 'tuples'. Each tuple with ndimension
# values. E.g. for a 2D Gaussian, x:=[1,2,3,4] will produce two output
# values for coordinates [1,2] and [3,4].
#
  const private.f := function(tp, x) {
    fRec :=			[_method="f",
				 _sequence=private.id._sequence];
    fRec.arg := tp;
    fRec.val := as_double(x);
    return defaultservers.run(private.agent, fRec);
  }
#
  const private.cf := function(tp, x) {
    fcRec :=			[_method="fc",
				 _sequence=private.id._sequence];
    fcRec.arg := tp;
    fcRec.val := as_dcomplex(x);
    return defaultservers.run(private.agent, fcRec);
  }
#
# Get value and derivatives. The argument x is as defined for 'f()'. The
# result is formatted as an array, with each row the value and the derivatives
# wrt the parameters. 
#
  const private.fdf := function(tp, x) {
    fdfRec :=			[_method="fdf",
				_sequence=private.id._sequence];
    fdfRec.arg := tp;
    fdfRec.val := as_double(x);
    nd := 1;
    if (tp.ndim != 0) nd := tp.ndim;
    return array(defaultservers.run(private.agent, fdfRec), len(x)/nd,
		 1+tp.npar);
  }
#
  const private.cfdf := function(tp, x) {
    fdfcRec :=			[_method="fdfc",
				_sequence=private.id._sequence];
    fdfcRec.arg := tp;
    fdfcRec.val := as_dcomplex(x);
    nd := 1;
    if (tp.ndim != 0) nd := tp.ndim;
    return array(defaultservers.run(private.agent, fdfcRec), len(x)/nd,
		 1+tp.npar);
  }
#
# Add a function to a combi/compound
#
  const private.add := function(tp, x) {
    addRec :=			[_method="add",
				_sequence=private.id._sequence];
    if (!is_functional(x)) fail("Can only add functionals");
    if (!has_field(tp, "nfunc") || !has_field(tp, "funcs") ||
	!is_record(tp.funcs)) fail("Only add function to combi/compound");
    addRec.arg := tp;
    addRec.val := x.state();
    return defaultservers.run(private.agent, addRec);
  }
#
# Public methods
#
# Get known names
#
  const public.names := function() {
    namesRec :=			[_method="names",
				 _sequence=private.id._sequence];
    return defaultservers.run(private.agent, namesRec);
  }
#
# Save names
#
  private.names := split(public.names());
#
# Make a Function of specified order/dimension (or use the default or fixed
# value), and set the parameters (or use the default ones).
#
  const public.functional := function(name=unset, order=unset, params=unset,
				      mode=unset) 
  {
    if (is_unset(name) || !is_string(name) || len(name) != 1) {
      fail("No name specified for functional creator");
    };
    wider private;
    ord := -1;
    progtext := '';
    if (!is_unset(order)) {
      if (is_numeric(order) && len(order) == 1 && order >= 0) ord := order;
      else if (is_string(order)) progtext := paste(order);
      else fail("Illegal functional order specified"); 
    };
    if (is_fail(a := private.define(name, ord, progtext, mode))) fail;
    if (is_unset(params) || len(params) == 0) {
    } else if (is_numeric(params) && len(params) == a.npar) {
      for (i in 1:a.npar) a.params[i] := params[i];
    } else fail("Incorrect number of parameters specified in functional");
    itsprivate := [=];
    public := [=];
    itsprivate.fnc := a;
    const public.f := function(x=[]) {
      return private.f(itsprivate.fnc, x);
    }
    const public.cf := function(x=[]) {
      wider itsprivate;
      itsprivate.fnc.params := as_dcomplex(itsprivate.fnc.params);
      return private.cf(itsprivate.fnc, as_dcomplex(x));
    }
    const public.fdf := function(x=[]) {
      return private.fdf(itsprivate.fnc, x);
    }
    const public.cfdf := function(x=[]) {
      wider itsprivate;
      itsprivate.fnc.params := as_dcomplex(itsprivate.fnc.params);
      return private.cfdf(itsprivate.fnc, as_dcomplex(x));
    }
    const public.add := function(x) {
      wider itsprivate;
      itsprivate.fnc := private.add(itsprivate.fnc, x);
      return T;
    }
    const public.type := function() {
      return private.names[itsprivate.fnc.type+1]; }
    const public.npar := function() { return itsprivate.fnc.npar; }
    const public.ndim := function() { return itsprivate.fnc.ndim; }
    const public.order := function() { return itsprivate.fnc.order; }
    const public.state := function() { return itsprivate.fnc; }
    const public.copyfrom := function(funcin=unset) {
      if (is_functional(funcin)) {
	wider itsprivate;
	itsprivate.fnc := funcin.state();
	return T;
      };
      fail("Argument is not a function");
    }
    const public.parameters := function() { return itsprivate.fnc.params; }
    const public.setparameters := function(par=unset) {
      wider itsprivate;
      if (!is_numeric(par) || len(par) != itsprivate.fnc.npar) {
	fail("Incorrect number of parameters in setparameters()");
      };
      if (itsprivate.fnc.npar > 0) {
	for (i in 1:itsprivate.fnc.npar) itsprivate.fnc.params[i] := par[i];
      };
      return T;
    }
    const public.par := function(n=1) {
      if (!is_numeric(n) || n<1 || n > public.npar()) {
	fail("Incorrect parameter number");
      };
      return itsprivate.fnc.params[n];
    }
    const public.setpar := function(n=1, v=1) {
      wider itsprivate;
      if (!is_numeric(n) || n<1 || n > public.npar()) {
	fail("Incorrect parameter number");
      };
      if (!is_numeric(v) || len(v) != 1) {
	fail("Incorrect value for a parameter");
      };
      itsprivate.fnc.params[n] := as_double(v);
      return itsprivate.fnc.params;
    }
    const public.masks := function() { return itsprivate.fnc.masks; }
    const public.setmasks := function(mask=unset) {
      wider itsprivate;
      if (!is_boolean(mask) || len(mask) != itsprivate.fnc.npar) {
	fail("Incorrect number of masks in setmasks()");
      };
      if (itsprivate.fnc.npar > 0) {
	for (i in 1:itsprivate.fnc.npar) itsprivate.fnc.masks[i] := mask[i];
      };
      return T;
    }
    const public.mask := function(n=1) {
      if (!is_numeric(n) || n<1 || n > public.npar()) {
	fail("Incorrect mask number");
      };
      return itsprivate.fnc.masks[n];
    }
    const public.setmask := function(n=1, v=T) {
      wider itsprivate;
      if (!is_numeric(n) || n<1 || n > public.npar()) {
	fail("Incorrect mask number");
      };
      if (!is_boolean(v) || len(v) != 1) {
	fail("Incorrect value for a mask");
      };
      itsprivate.fnc.masks[n] := as_boolean(v);
      return itsprivate.fnc.masks;
    }
    const public.done := function() {
      wider itsprivate, public;
      val public := F;
      itsprivate := F;
      return T; 
    }
    return const ref public;
  }
#
# Make a gaussian1d
#
  const public.gaussian1d := function(height=1, center=0, width=1) {
    if (len(height) == 3) {
      return const ref public.functional(name='gaussian1D',
					 params=height);
    } else {
      return const ref public.functional(name='gaussian1D',
					 params=[height, center, width]);
    };
  }
#
# Make a gaussian2d
#
  const public.gaussian2d := function(params=[1,0,0,1,1,0]) {
    return const ref public.functional(name='gaussian2D',
				       params=params);
  }
#
# Make a polynomial (with default parameters == 1; rather than standard 0)
#
  const public.poly := function(order=unset, params=unset) {
    a := const ref public.functional(name='poly', order=order,
				     params=params);
    if (is_unset(params)) a.setparameters(1+a.parameters());
    return a;
  }
#
# Make an odd polynomial (with default parameters == 1; rather than standard 0)
#
  const public.oddpoly := function(order=unset, params=unset) {
    a := const ref public.functional(name='oddpoly', order=order,
				     params=params);
    if (is_unset(params)) a.setparameters(1+a.parameters());
    return a;
  }
#
# Make an even polynomial (with default parameters == 1; rather than 0)
#
  const public.evenpoly := function(order=unset, params=unset) {
    a := const ref public.functional(name='evenpoly', order=order,
				     params=params);
    if (is_unset(params)) a.setparameters(1+a.parameters());
    return a;
  }
# 
# Make a Chebyshev polynomial
#
  private.chebmodes := "constant zeroth extrapolate cyclic edge";
#
  const public.chebyshev := function(order=unset, params=unset, xmin=-1, 
				     xmax=1, ooimode='constant', def=0)
  {
    wider private;
    ooimode := to_lower(ooimode);
    local minmatch := eval(spaste('m/^', ooimode, '/'));
    if (! any(private.chebmodes ~ minmatch)) 
	return throw('Unrecognized ooimode: ', ooimode, 
		     origin="functionals");

    local mode := [interval=as_double([xmin,xmax]), intervalMode=ooimode, 
		   default=as_double(0)];

    a := const ref public.functional(name='chebyshev', order=order,
				     params=params, mode=mode);
    if (is_unset(params)) a.setparameters(1+a.parameters());
    return a;
  }

#
# Make a Butterworth bandpass 
# 
  const public.butterworth := function(minorder=1, maxorder=1, mincut=-1.0,
				       maxcut=1.0, center=0.0, peak=1.0) 
  {
      if (! is_numeric(mincut) || ! is_numeric(center) || ! is_numeric(maxcut))
      {
	  local bad := "";
	  if (! is_numeric(mincut)) bad := [bad, 'mincut'];
	  if (! is_numeric(center)) bad := [bad, 'center'];
	  if (! is_numeric(maxcut)) bad := [bad, 'maxcut'];
	  return throw('bad type for inputs: ', bad, origin='functionals');
      }
	  
      mincut := as_double(mincut);
      maxcut := as_double(maxcut);
      if (mincut >= center || center >= maxcut) {
	  return throw('Values out of order for mincut, center, maxcut:',
		       [mincut, center, maxcut], origin='functionals');
      }

      a := const ref public.functional(name='butterworth', 
				       params=[center, mincut, maxcut, peak],
				       mode=[minOrder=minorder, 
					     maxOrder=maxorder]);
      return a;
  }

#
# Make a combi
#
  const public.combi := function() {
    return const ref public.functional(name='combi');
  }
#
# Make a compound
#
  const public.compound := function() {
    return const ref public.functional(name='compound');
  }
#
# Make a compiled 
#
  const public.compiled := function(code='', params=unset) {
    return const ref public.functional(name='compiled', order=code,
				       params=params);
  }
#
# id() needed for toolmanager kill
#
  const public.id :=function() {
    return private.id.objectid;
  }
#
# type() for toolmanager
#
  const public.type := function() {
    return 'functionals';
  }
#
# done()
#
  public.done := function(kill=F) {
    wider private, public;
    if (!private.iamdefault || (is_boolean(kill) && kill)) {
      ok := defaultservers.done(private.agent, public.id());
      if (is_fail(ok)) fail;
      if (ok) {
	val public := F;
	private := F;
      };
      return ok; 
    };
    return F;
  }
#
# End server constructor
#
  return ref public;

} # constructor
#
# Create a defaultserver
#
defaultfunctionals := functionals();
const defaultfunctionals := defaultfunctionals;
const dfs := ref defaultfunctionals;
#
# Start-up messages
#
if (!is_boolean(dfs)) {
  note('defaultfunctionals (dfs) ready', priority='NORMAL', 
       origin='functionals');
};
#
# Add defaultfunctionals to the GUI if necessary
#
if (any(symbol_names(is_record)=='objrepository') &&
    has_field(objrepository, 'notice')) {
  objrepository.notice('defaultfunctionals', 'functionals');
};



