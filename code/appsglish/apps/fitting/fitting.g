# fitting.g: Access to fitting classes
# Copyright (C) 1999,2000,2001,2002,2004
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
# $Id: fitting.g,v 19.4 2004/09/23 05:46:13 wbrouw Exp $
#
pragma include once

include 'servers.g';
include 'serverexists.g';
include 'note.g';
include 'unset.g';
include 'functionals.g';
#
##defaultservers.trace(T)
##defaultservers.suspend(T)
#
# Global methods
#
# Server
#
const fitter := function(n=0, m=1, type=0,
      			 fnct=unset, vfnct=unset, guess=unset,
			 colfac=1e-8, lmfac=1e-3,
			 host='', forcenewserver=F) {
  private := [=];
  public := [=];
  public::print.limit := 1;
#
# Type of solutions possible
#
  const public.real := function() { return 0;}
  const public.complex := function() { return 1;}
  const public.separable := function() { return 3;}
  const public.asreal := function() { return 7;}
  const public.conjugate := function() { return 11;}
#
# The known fitters
#
  private.fitids := [=];
#
# Check fitter type
#
  const private.gettype := function(type='real') {
    if (is_string(type)) {
      local rxtp := spaste('m/', type, '/i');
      if ('real' ~ eval(rxtp)) 		  type := public.real();
      else if ('complex' ~ eval(rxtp)) 	  type := public.complex();
      else if ('separable' ~ eval(rxtp))  type := public.separable();
      else if ('asreal' ~ eval(rxtp)) 	  type := public.asreal();
      else if ('conjugate' ~ eval(rxtp))  type := public.conjugate();
      else return throw('Illegal fitting string type');
    } else if (is_integer(type) &&
	       (type == public.real() || type == public.complex() ||
		type == public.asreal() ||
		type == public.separable() || type == public.conjugate())) {
    } else {
      return throw('Illegal fitting type');
    };
    return type;
  }
#
# Make string fitter type
#
  const private.settype := function(type=0) {
    if (type == public.complex()) return 'complex';
    else if (type == public.separable()) return 'separable';
    else if (type == public.asreal()) return 'asreal';
    else if (type == public.conjugate()) return 'conjugate';
    return 'real';
  }
# 
# Check for correct fitter id
#
  const private.checkid := function(id=0) {
    return (!(id >= length(private.fitids) ||
	      !has_field(private.fitids[id+1], 'stat') ||
	      !is_record(private.fitids[id+1].stat)));
  }
#
# Reshape values
#
  const private.reshape := function(id=0) {
    wider private;
    for (i in field_names(private.fitids[id+1])) {
      if (has_field(private.fitids[id+1][i]::, 'shape') &&
	  len(private.fitids[id+1][i]::shape) > 1 &&
	  private.fitids[id+1][i]::shape[1] == 1) {
	private.fitids[id+1][i]::shape := private.
	  fitids[id+1][i]::shape[2:len(private.fitids[id+1][i]::shape)];
      };
    };
    return T;
  }
#
# Get the state of the fitter
#
  const private.getstate := function(id) {
#
# Connection records
#
    stateRec :=		[_method="getstate",
			 _sequence=private.id._sequence];
    stateRec.id := id;
    a := defaultservers.run(private.agent, stateRec);
    if (has_field(a, 'typ')) a.type := private.settype(a.typ);
    return a;
  }
#
# Initialise a fitter
#
  const public.init := function(n=0, type='real',
				colfac=1e-8, lmfac=1e-3, id=0) {
    wider private;
    type := private.gettype(type);
    if (is_fail(type)) fail;
    if (id >= length(private.fitids) ||
	n<0 || colfac<0 ||
	lmfac<0) return throw('Illegal init argument specified');
    private.fitids[id+1].stat       := F;
    private.fitids[id+1].solved     := F;
    private.fitids[id+1].haserr     := F;
    private.fitids[id+1].fit	    := 1;
    private.fitids[id+1].looped	    := F;
    initRec := 		[_method="init",
			_sequence=private.id._sequence];
    initRec.id := id;
    initRec.val := n;
    initRec.arg1 := type;
    initRec.arg2 := colfac;
    initRec.arg3 := lmfac;
    if (defaultservers.run(private.agent, initRec)) {
      private.fitids[id+1].stat := private.getstate(id=id);
      return T;
    };
    return F;
  }
#
# (Re-)initialise selected fitter properties
#
  const public.set := function(n=unset, type=unset,
			       colfac=unset, lmfac=unset, id=0) {
    wider private;
    if (!private.checkid(id)) {
      return throw('Illegal id used in set');
    };
    if (is_unset(type)) type := -1;
    else {
      type := private.gettype(type);
      if (is_fail(type)) fail;
    };
    if (is_unset(n)) n := -1;
    else if (n<0) return throw('Illegal set argument');
    if (is_unset(colfac)) colfac := -1;
    else if (colfac<0) return throw('Illegal set argument');
    if (is_unset(lmfac)) lmfac := -1;
    else if (lmfac<0) return throw('Illegal set argument');
    private.fitids[id+1].stat := F;
    private.fitids[id+1].solved := F;
    private.fitids[id+1].looped := F;
    private.fitids[id+1].fit := 1;
    private.fitids[id+1].haserr := F;
    if (n != -1 || type != -1 || colfac != -1 ||
	lmfac != -1) {
      setRec := 		[_method="set",
				_sequence=private.id._sequence];
      setRec.id := id;
      setRec.val := n;
      setRec.arg1 := type;
      setRec.arg2 := colfac;
      setRec.arg3 := lmfac;
      if (!defaultservers.run(private.agent, setRec)) return F;
    };
    private.fitids[id+1].stat := private.getstate(id=id);
    return T;
  }
#
# Get a fitter id
#
  const public.fitter := function(n=0, type='real',
				  colfac=1e-8, lmfac=1e-3) {
    wider private;
    idRec :=		[_method="getid",
			_sequence=private.id._sequence];
    local id := defaultservers.run(private.agent, idRec);
    if (is_fail(id)) return throw('Cannot create a fitter');
    private.fitids[id+1] := [=];
    if (!public.init(n=n, type=type,
		     colfac=colfac, lmfac=lmfac, id=id)) {
      return throw('Cannot initialise fitter');
    };
    return id;
  }
#
# Get server and default fitter
#
  if (!serverexists('dfs', 'functionals', dfs)) {
    return throw('The functionals server "dfs" is not running',
		 origin='fitting.g');
  };
  private.agent := defaultservers.activate("fitting", host,
					   forcenewserver);
  if (is_fail(private.agent)) return F;
  private.id := defaultservers.create(private.agent, "fitting");
  private.iamdefault := T;
  if (is_defined('dfit') && is_function(dfit.id) && is_function(dfit.done)) {
    private.iamdefault := F;
  };
  local id := public.fitter(n=n, type=type,
			    colfac=colfac, lmfac=lmfac);
  if (id != 0) return throw("System problem creating fitter server");
#
# Public methods
#
# Type (needed to show up in Object Catalog)
#
  const public.type := function() {
    return 'fitter';
  }
#
# id() needed for toolmanager kill
#
  const public.id := function() {
    return private.id.objectid;
  }
#
# Free the resources
#
  const public.done := function(id=unset, kill=F) {
    wider private, public;
    if (is_unset(id)) {
      if (!private.iamdefault || (is_boolean(kill) && kill)) {
	ok := defaultservers.done(private.agent, private.id.objectid);
	if (is_fail(ok)) fail;
	if (ok) {
	  val public := F;
	  private := F;
	};
	return ok;
      };
      return F;
    };
    if (id >= length(private.fitids)) {
      return throw('Illegal fitter id in done');
    };
    doneRec :=  		[_method="done",
				_sequence=private.id._sequence];
    doneRec.id := id;
    private.fitids[id+1] := [=];
    return defaultservers.run(private.agent, doneRec);
  }
#
# Reset the resources
#
  const public.reset := function(id=0) {
    wider private;
    if (!private.checkid(id)) {
      return throw('Illegal fitter id in reset');
    };
    resetRec :=  		[_method="reset",
				_sequence=private.id._sequence];
    resetRec.id := id;
    private.fitids[id+1].solved := F;
    private.fitids[id+1].haserr := F;
    if (!private.fitids[id+1].looped) {
      return defaultservers.run(private.agent, resetRec);
    } else {
      private.fitids[id+1].looped := F;
    };
    return T;
  }
#
# Get the state of the fitter
#
  const public.getstate := function(id=0) {
    if (!private.checkid(id)) {
      return throw('Illegal fitter id in getstate');
    };
    return private.fitids[id+1].stat;
  }
#
# Clear constraints
#
  const public.clearconstraints := function(id=0) {
    wider private;
    if (!private.checkid(id)) {
      return throw('Illegal fitter id in clearconstraints');
    };
    private.fitids[id+1].constraint := [=];
    return T;
  }
#
# Add constraint
#
  const public.addconstraint := function(fnct=unset, x, y=0, id=0) {
    wider private;
    if (!private.checkid(id)) {
      return throw('Illegal fitter id in addconstraint');
    };
    local i := 1;
    if (has_field(private.fitids[id+1], 'constraint')) {
      i := length(private.fitids[id+1].constraint) + 1;
    } else private.fitids[id+1].constraint := [=];
    if (is_functional(fnct)) {
      private.fitids[id+1].constraint[i].fnct := fnct;
    } else {
      private.fitids[id+1].constraint[i].fnct :=
	dfs.functional('hyper', length([x]));
    };
    private.fitids[id+1].constraint[i].x := [as_double(x)];
    private.fitids[id+1].constraint[i].y := as_double(y);
    return T;
  }
#
# Solve polynomial
#
  const public.fitpoly := function(n, x, y, sd=unset, wt=1.0, id=0) {
    if (public.set(n=n+1, id=id)) {
	return public.linear(dfs.poly(n), x, y, sd, wt, id);
    };
    return F;
  }
#
# Show private
#
  const public.showp := function(n=-1) {
    if (n==-1) print private;
    else print private.fitids[n];
  } ;
#
# Solve scaled polynomial
#
  const public.fitspoly := function(n, x, y, sd=unset, wt=1.0, id=0) {
    wider private;
    local a := max(abs(max(x)), abs(min(x)));
    if (a==0) a := 1;
    a := 1.0/a;
    local b := a^([0:n]);
    if (public.set(n=n+1, id=id)) {
	if (public.linear(dfs.poly(n), x*a, y, sd, wt, id)) {
	    private.fitids[id+1].sol *:= b;
	    private.fitids[id+1].error *:= b;
	    return T;
	};
    };
    return F;
  }
#
# Solve average
#
  const public.fitavg := function(y, sd=unset, wt=1.0, id=0) {
    if (public.set(n=1, id=id)) {
	return public.linear(dfs.compiled('p'), [], y, sd, wt, id);
    };
    return F;
  }
#
# Fit a linear functional to the given data
#
  const public.linear := function(fnct=unset, x, y, sd=unset, wt=1.0, id=0) {
    wider private;
    if (!is_functional(fnct)) fail("No function in dfit.linear given");
    if (!public.set(n=fnct.npar(), id=id)) fail("Illegal id in fit.linear");
    public.reset(id);
    linearRec :=  		[_method='linear',
				_sequence=private.id._sequence];
    if (!is_unset(sd)) {
      wt := sd;
      wt[sd == 0] := 1;
      wt := 1/abs(wt * conj(wt));
# note single | -- can be vector!
      wt[sd == -1 | sd == 0] := 0;
    };
    linearRec.id := id;
    if (public.getstate(id).typ != public.real() ||
	is_complex(x) || is_complex(y) || is_complex(wt) ||
	is_dcomplex(x) || is_dcomplex(y) || is_dcomplex(wt)) {
      linearRec._method := 'cxlinear';
      fnct.setparameters(as_dcomplex(fnct.parameters()));
      linearRec.val := [as_dcomplex(x)];
      linearRec.val0 := [as_dcomplex(y)];
      linearRec.val1 := [as_dcomplex(wt)];
    } else {
      linearRec.val := [as_double(x)];
      linearRec.val0 := [as_double(y)];
      linearRec.val1 := [as_double(wt)];
    };
    linearRec.fnc := fnct.state();
    if (!has_field(private.fitids[id+1], 'constraint')) {
      private.fitids[id+1].constraint := [=];
    };
    linearRec.arg7 := private.fitids[id+1].constraint;
    private.fitids[id+1].solved := F;
    private.fitids[id+1].haserr := F;
    private.fitids[id+1].sol := defaultservers.run(private.agent,
						   linearRec);
    if (is_fail(private.fitids[id+1].sol)) fail;
    private.fitids[id+1].rank := linearRec.arg0;
    private.fitids[id+1].sd := linearRec.arg1;
    private.fitids[id+1].mu := linearRec.arg2;
    private.fitids[id+1].chi2 := linearRec.arg3;
    private.fitids[id+1].constr := linearRec.arg4;
    private.fitids[id+1].covar := linearRec.arg5;
    private.fitids[id+1].error := linearRec.arg6;
    private.fitids[id+1].defic := linearRec.arg8;
    
    private.reshape(id);
    private.fitids[id+1].solved := T;
    private.fitids[id+1].haserr := T;
    private.fitids[id+1].looped := F;
    return T;
  }
#
# Fit a non-linear functional to the given data
#
  const public.functional :=
  function(fnct=unset, x, y, sd=unset, wt=1.0, mxiter=50, id=0) {
    wider private;
    if (!is_functional(fnct)) fail("No function in dfit.functional given");
    if (!public.set(n=fnct.npar(), id=id)) {
      fail("Illegal id in fit.functional");
    };
    public.reset(id);
    functionalRec :=  		[_method='functional',
				_sequence=private.id._sequence];
    if (!is_unset(sd)) {
      wt := sd;
      wt[sd == 0] := 1;
      wt := 1/abs(wt * conj(wt));
# note single | -- can be vector!
      wt[sd == -1 | sd == 0] := 0;
    };
    functionalRec.id := id;
    if (public.getstate(id).typ != public.real() ||
	is_complex(x) || is_complex(y) || is_complex(wt) ||
	is_dcomplex(x) || is_dcomplex(y) || is_dcomplex(wt)) {
      functionalRec._method := 'cxfunctional';
      fnct.setparameters(as_dcomplex(fnct.parameters()));
      functionalRec.val := [as_dcomplex(x)];
      functionalRec.val0 := [as_dcomplex(y)];
      functionalRec.val1 := [as_dcomplex(wt)];
    } else {
      functionalRec.val := [as_double(x)];
      functionalRec.val0 := [as_double(y)];
      functionalRec.val1 := [as_double(wt)];
    };
    functionalRec.fnc := fnct.state();
    functionalRec.val2 := mxiter;
    if (!has_field(private.fitids[id+1], 'constraint')) {
      private.fitids[id+1].constraint := [=];
    };
    functionalRec.arg7 := private.fitids[id+1].constraint;
    private.fitids[id+1].solved := F;
    private.fitids[id+1].haserr := F;
    private.fitids[id+1].sol := defaultservers.run(private.agent,
						   functionalRec);
    if (is_fail(private.fitids[id+1].sol)) fail;
    private.fitids[id+1].rank := functionalRec.arg0;
    private.fitids[id+1].sd := functionalRec.arg1;
    private.fitids[id+1].mu := functionalRec.arg2;
    private.fitids[id+1].chi2 := functionalRec.arg3;
    private.fitids[id+1].constr := functionalRec.arg4;
    private.fitids[id+1].covar := functionalRec.arg5;
    private.fitids[id+1].error := functionalRec.arg6;
    private.fitids[id+1].defic := functionalRec.arg8;
    private.reshape(id);
    private.fitids[id+1].solved := T;
    private.fitids[id+1].haserr := T;
    private.fitids[id+1].looped := F;
    return T;
  }
#
# Get the solution
#
  const public.solution := function(id=0) {
    if (!private.checkid(id) || !private.fitids[id+1].solved) {
      return throw('Illegal fitter id in solution');
    };
    return private.fitids[id+1].sol;
  }
#
# Get the solution rank
#
  const public.rank := function(id=0) {
    if (!private.checkid(id) || !private.fitids[id+1].solved) {
      return throw('Illegal fitter id in rank');
    };
    return private.fitids[id+1].rank;
  }
#
# Get the rank deficiency
#
  const public.deficiency := function(id=0) {
    if (!private.checkid(id) || !private.fitids[id+1].solved) {
      return throw('Illegal fitter id in rank');
    };
    return private.fitids[id+1].defic;
  }
#
# Get Chi^2
#
  const public.chi2 := function(id=0) {
    if (!private.checkid(id) || !private.fitids[id+1].solved) {
      return throw('Illegal fitter id in chi2');
    };
    return private.fitids[id+1].chi2;
  }
#
# Get sd: the standard deviation per unit weight
#
  const public.sd := function(id=0) {
    if (!private.checkid(id) || !private.fitids[id+1].solved) {
      return throw('Illegal fitter id in sd');
    };
    return private.fitids[id+1].sd;
  }
#
# Get mu; the standard deviation per observation
#
  const public.mu := function(id=0) {
    if (!private.checkid(id) || !private.fitids[id+1].solved) {
      return throw('Illegal fitter id in mu');
    };
    return private.fitids[id+1].mu;
  }
  const public.stddev := public.mu;
#
# Get covariance
#
  const private.covariance := function(id) {
    wider private;
    if (!private.fitids[id+1].haserr) {
      covarRec := 		[_method="covar",
				_sequence=private.id._sequence,
				id=id];
      private.fitids[id+1].covar :=
	defaultservers.run(private.agent, covarRec);
      if (is_fail(private.fitids[id+1].covar)) fail;
      private.fitids[id+1].error := covarRec.arg0;
      private.reshape(id);
      if (private.fitids[id+1].stat.typ != public.real()) {
	local sh := private.fitids[id+1].error::;
	local n := len(private.fitids[id+1].error);
	private.fitids[id+1].error := 
	  private.fitids[id+1].error[seq(1,n,2)] + 
	  private.fitids[id+1].error[seq(2,n,2)]*1i;
	if (has_field(sh, 'shape') && len(sh.shape) > 0) {
	  sh.shape[len(sh.shape)] /:= 2;
	};
	private.fitids[id+1].error:: := sh;
      };
      private.fitids[id+1].haserr := T;
    };
    return T;
  }
#
# Get covariance
#
  const public.covariance := function(id=0) {
    if (!private.checkid(id)) {
      return throw('Illegal fitter id in covariance');
    };
    if (!private.covariance(id)) fail;
    return private.fitids[id+1].covar;
  }
#
# Get errors
#
  const public.error := function(id=0) {
    if (!private.checkid(id)) {
      return throw('Illegal fitter id in error');
    };
    if (!private.covariance(id)) fail;
    return private.fitids[id+1].error;
  }
#
# Get constraints
#
  const public.constraint := function(n=0, id=0) {
    if (!private.checkid(id) || !private.fitids[id+1].solved) {
      return throw('Illegal fitter id in constraint');
    };
    if (n<1 || n>private.fitids[id+1].defic) {
      return private.fitids[id+1].constr;
    };
    return private.fitids[id+1].
    constr[length(private.fitids[id+1].sol)*(n-1) +
	  1:length(private.fitids[id+1].sol)];
  }
#
# Is non-linear fitted?
#
  const public.fitted := function(id=0) {
    if (!private.checkid(id)) {
      return throw('Illegal fitter id in fitted');
    };
    return !(private.fitids[id+1].fit > 0 || 
	     private.fitids[id+1].fit < -0.001);
  }
#
# End server constructor
#
  return const ref public;
    
} # constructor
#
# Create a defaultserver
#
const defaultfitter:= fitter();
const dfit := const ref defaultfitter;
#
# Start-up messages
#
if (!is_boolean(dfit)) {
  note('defaultfitter (dfit) ready', priority='NORMAL', origin='fitting');
};
