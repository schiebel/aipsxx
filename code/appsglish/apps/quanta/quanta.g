# quanta.g: Access to units and quanta classes
# Copyright (C) 1998,1999,2000,2001,2002,2003
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
# $Id: quanta.g,v 19.3 2004/08/25 01:49:08 cvsmgr Exp $
#
pragma include once;

include 'servers.g';
include 'aipsrc.g';
include 'timer.g';
include 'note.g';
include 'choice.g';
include 'widgetserver.g';
#
##defaultservers.trace(T)
##defaultservers.suspend(T)
#
# Global methods
#
# Check if quantity (in this case proper unit)
#
  const is_quantity := function(ref v) {
    return (is_record(v) &&
	    ((has_field(v::, 'id') && v::id == 'quant') ||
	     (!has_field(v::, 'id') && !has_field(v::, 'shape') &&
	      has_field(v, "value") && has_field(v, "unit"))));
  }
#
# Make a record array, initially filled with specified values
#
const r_array := function(ref a=[=], ..., id=F) {
  b := array(0, ...);
  c := [=];
  j := 1;
  for (i in ind(b)) {
    if (len(a) == 0 || (is_record(a) && !has_field(a::, 'shape'))) c[i] := a;
    else { c[i] := a[j]; j := j%len(a) + 1; };
  };
  if (has_field(b::, 'shape')) {
    c::shape := b::shape;
  } else if (len(c) == 1) {
    c := c[1];
  } else {
    c::shape := length(c);
  };
  if (is_string(id)) c::id := id;
  if (!has_field(c::, 'id') && has_field(a::, 'id')) c::id := a::id;
  return c;
}
#
# Get a slice of a record array (all indexing works as for arrays)
#
const r_slice := function(ref v, ...=F) {
  b := r_index(v, ...);
  if (is_fail(b)) fail;
  if (!has_field(v::, 'shape')) return v;
  if (len(b) == 1) {
    c := v[b[1]];
    if (has_field(v::, 'id')) c::id := v::id;
    return c;
  };
  c := [=];
  if (len(b) == 0) return c;
  for (i in ind(b)) c[i] := v[b[i]];
  if (has_field(b::, 'shape')) {
    c::shape := b::shape;
  } else {
    c::shape := length(c);
  };
  if (has_field(v::, 'id')) c::id := v::id;
  return c;
}
#
# Fill a slice of an array with (cyclic) what
#
const r_fill := function(what, ref v, ...=F) {
  b := r_index(v, ...);
  if (is_fail(b)) fail;
  if (!has_field(v::, 'shape')) val v := what;
  j := 1;
  for (i in ind(b)) {
    if (len(what) == 0 || (is_record(what) && !has_field(what::, 'shape'))) {
      val v[b[i]] := what;
    } else { val v[b[i]] := what[j]; j := j%len(what) + 1; };
  };
  return T;
}
#
# get index array for a record array (helper function)
#
const r_index := function(ref v, ...=F) {
  if (!is_record(v)) fail('r_array not a record');
  if (!has_field(v::, 'shape')) {
    a := 1;
    a::shape := 1;
  } else {
    if (len(v) != prod(v::shape)) fail('Length disgrees with shape');
    if (len(v) == 0) return [=];
    a := ind(v);
    a::shape := v::shape;
  };
  mis := missing();
  for (i in 2:len(mis)) {
    if (!mis[i] && is_boolean(nth_arg(i-1,...))) mis[i] := !nth_arg(i-1,...);
  };
  if (num_args(...) == 0) {
    b := a;
  } else {
    if (num_args(...) == 1 && !mis[2] && !is_record(nth_arg(1,...))) {
      b := a[nth_arg(1,...)];
    } else {
      if (num_args(...) == 1 && is_record(nth_arg(1,...))) {
	ix := nth_arg(1,...);
      } else {
	ix := [=];
	for (i in 1:num_args(...)) {
	  if (mis[i+1]) ix[i] := [];
	  else ix[i] := nth_arg(i,...);
	};
      };
      b := a[ix];
    };
  };
  return b;
}
#
# Server
#
  const quanta := function(host='', forcenewserver=F) {
    global system;
    private := [=];
    public := [=];
    public::print.limit := 1;
    private.agent := defaultservers.activate("quanta", host,
					     forcenewserver);
    if (is_fail(private.agent)) return F;
    private.id := defaultservers.create(private.agent, "quanta");
    private.iamdefault := T;
    if (is_defined('dq') && is_function(dq.gui) && is_function(dq.done)) {
      private.iamdefault := F;
    };
    private.frame := [=];
    private.format := [=];
    private.format.lst := [=];
    private.format.lst.long := "hms dms deg +deg rad d";
    private.format.lst.lat  := "dms deg hms rad d";
    private.format.lst.len  := "m km";
    private.format.lst.dtime  := "local utc last solar";
    private.format.lst.elev := "0deg 5deg 10deg ...";
    private.format.lst.auto := "1s 2s 5s 10s ...";
    private.format.lst.vel := "m/s km/s AU/a pc/a () % ...";
    private.format.lst.freq := ["MHz GHz THz s rad/s m cm mm nm cm-1",
			       "(eV) keV kg.m ..."];
    private.format.lst.dop := "true radio opt";
    private.format.lst.unit := "_ ...";
    private.format.form := [=];
    private.format.prec := 9;
    private.format.aprec := 9;
    private.format.tprec := 9;
    private.format.long := 'hms';
    private.format.lat := 'dms';
    private.format.len := 'm';
    private.format.dtime := 'utc';
    private.format.elev := '0deg';
    private.format.auto := '2s';
    private.format.vel := 'km/s';
    private.format.freq := 'MHz';
    private.format.dop := 'true';
    private.format.unit := '_';
    if (!has_field(system, 'print')) system.print := [=];
    system.print.precision := private.format.prec;
    private.units_const :=
      "pi ee c G h HI R NA e mp mp_me mu0 eps0 k F me re a0 R0 k2";
    private.units_const_txt := [=];
    private.units_const_txt.pi := '    3.14..           '; 
    private.units_const_txt.ee := '    2.71..           ';
    private.units_const_txt.c := '     light vel.       ';
    private.units_const_txt.G := '     grav. const      '; 
    private.units_const_txt.h := '     Planck const     '; 
    private.units_const_txt.HI := '    HI line          ';
    private.units_const_txt.R := '     gas const        ';
    private.units_const_txt.NA := '    Avogadro #       ';
    private.units_const_txt.e := '     electron charge  ';
    private.units_const_txt.mp := '    proton mass      ';
    private.units_const_txt.mp_me := ' mp/me            '; 
    private.units_const_txt.mu0 := '   permeability vac.';
    private.units_const_txt.eps0 := '  permittivity vac.';
    private.units_const_txt.k := '     Boltzmann const  ';
    private.units_const_txt.F := '     Faraday const    ';
    private.units_const_txt.me := '    electron mass    ';
    private.units_const_txt.re := '    electron radius  ';
    private.units_const_txt.a0 := '    Bohr\'s radius   ';
    private.units_const_txt.R0 := '    solar radius     ';
    private.units_const_txt.k2 := '    IAU grav. const^2';
#
# Public methods
#
# setformat (t='', v=F) -> set specified format (e.g. 'prec') to value v
#
    const public.setformat := function(t='', v=F) {
      wider private;
      global system;
      if (!has_field(private.format, t)) {
	public.errorgui('Illegal type specified for setformat()');
	return F;
      };
      if (is_string(v) && v == '') v := '0';
      if (is_string(v) && v == '...') {
	v := public.entergui(paste(t, 'format'), private.format[t]);
      };
      if (is_numeric(v)) v := as_string(v);
      if (is_string(v) && v != '...') {
	if (t == 'prec') {
	  private.format.prec := as_integer(v);
	  if (private.format.prec < 1) private.format.prec := 6;
	  system.print.precision := private.format.prec;
	  return T;
	} else if (t == 'aprec') {
	  private.format.aprec := as_integer(v);
	  if (private.format.aprec < 1) private.format.aprec := 6;
	  return T;
	} else if (t == 'tprec') {
	  private.format.tprec := as_integer(v);
	  if (private.format.tprec < 1) private.format.tprec := 6;
	  return T;
	} else if (t == 'long') {
	  a[1:length(private.format.lst.long)] := v;
	  if (sum(a==private.format.lst.long) > 0) {
	    private.format.long := v;
	    return T;
	  };
	} else if (t == 'lat') {
	  a[1:length(private.format.lst.lat)] := v;
	  if (sum(a==private.format.lst.lat) > 0) {
	    private.format.lat := v;
	    return T;
	  };
	} else if (t == 'len') {
	  if (public.check(v) && public.compare(v, '1m')) {
	    private.format.len := v;
	    return T;
	  };
	} else if (t == 'dtime') {
	  a[1:length(private.format.lst.dtime)] := v;
	  if (sum(a==private.format.lst.dtime) > 0) {
	    private.format.dtime := v;
	    return T;
	  };
	} else if (t == 'elev') {
	  if (public.is_angle(v)) {
	    private.format.elev := v;
	    return T;
	  };
	} else if (t == 'auto') {
	  if (public.is_angle(v)) {
	    private.format.auto := v;
	    return T;
	  };
	} else if (t == 'vel') {
	  if (public.check(v) &&
	      (public.compare(v, '1m/s') || public.compare(v, '1'))) {
	    private.format.vel := v;
	    return T;
	  };
	} else if (t == 'freq') {
	  if (public.checkfreq(v)) {
	    private.format.freq := v;
	    return T;
	  };
	} else if (t == 'dop') {
	  a[1:length(private.format.lst.dop)] := v;
	  if (sum(a==private.format.lst.dop) > 0) {
	    private.format.dop := v;
	    return T;
	  };
	} else if (t == 'unit') {
	  if (public.check(v)) {
	    private.format.unit := v;
	    return T;
	  };
	};
      };
      return F;
    }
#
# getformat (t='prec') -> get specified format (e.g. 'prec')
#
    const public.getformat := function(t='prec') {
      if (has_field(private.format, t)) {
	return private.format[t];
      } else {
	fail('getformat()');
      };
    }
#
# form.x(v) -> format value acoording to type x
#
    public.form := [=];

    const public.form.long := function(v, showform=F) {
      if (public.is_angle(v)) {
	if (private.format.long == 'dms') {
	  return (public.angle(v, showform=showform));
	} else if (private.format.long == 'deg') {
	  return (public.tos(public.convert(v, 'deg')));
	} else if (private.format.long == '+deg') {
	  return (public.tos(public.norm(public.convert(v, 'deg'),
					 0)));
	} else if (private.format.long == 'rad') {
	  return (public.tos(public.convert(v, 'rad')));
	} else if (private.format.long == 'd') {
	  return (public.tos(public.convert(v, '1.0d')));
	} else {
	  return (public.time(v, showform=showform));
	};
      } else {
	return  F;
      };
    }

    const public.form.lat := function(v, showform=F) {
      if (public.is_angle(v)) {
	if (private.format.lat == 'hms') {
	  return (public.time(v, showform=showform));
	} else if (private.format.lat == 'deg') {
	  return (public.tos(public.convert(v, 'deg')));
	} else if (private.format.lat == 'rad') {
	  return (public.tos(public.convert(v, 'rad')));
	} else if (private.format.lat == 'd') {
	  return (public.tos(public.convert(v, '1.0d')));
	} else {
	  return (public.angle(v, showform=showform));
	};
      } else {
	return  F;
      };
    }

    const public.form.len := function(v) {
      if (public.check(v)) {
	return (public.tos(public.convert(v, private.format.len)));
      } else {
	return  F;
      };
    }

    const public.form.vel := function(v) {
      if (public.check(v)) {
	if (public.compare(private.format.vel, '1')) {
	  return (public.tos(public.convertdop(v, private.format.vel)));
	} else {
	  return (public.tos(public.convert(v, private.format.vel)));
	};
      } else {
	return  F;
      };
    }

    const public.form.freq := function(v) {
      if (public.check(v)) {
	return (public.tos(public.convertfreq(v, private.format.freq)));
      } else {
	return F;
      };
    }

    const public.form.dtime := function(v, showform=F) {
      if (public.check(v)) {
	if (private.format.dtime == 'last') {
	  return (public.time(v, 6));
	} else if (private.format.dtime == 'local') {
	  return (public.time(v, 6, form="ymd local", showform=showform));
	} else {
	  return (public.time(v, 6, form="ymd", showform=showform));
	};
      } else {
	return F;
      };
    }

    const public.form.unit := function(v) {
      if (public.check(v)) {
	return public.tos(public.convert(v, private.format.unit));
      } else {
	return F;
      };
    }
### Get unit of quanta or quanta array
### Test version
    const public.getunit := function(v) {
      if (!is_quantity(v)) fail('Incorrect input type for dq.getunit()');
      v0 := "";
      if (has_field(v::, 'shape')) {
	for (i in ind(v)) v0[len(v0)+1] := v[i].unit;
      } else {
	v0 := v.unit;
      };
      if (has_field(v::, 'shape')) v0::shape := v::shape;
      return v0;
    } 
### get value of quantity or quantity array
    const public.getvalue := function(v) {
      if (!is_quantity(v)) fail('Incorrect input type for dq.getvalue()');
      v0 := [];
      if (has_field(v::, 'shape')) {
	for (i in ind(v)) v0[len(v0)+1] := v[i].value;
      } else {
	v0 := v.value;
      };
      if (has_field(v::, 'shape')) v0::shape := v::shape;
      return v0;
    }
#
# Show list of frequencies
#
    const public.form.tablefreq := function(v, outunit=F, showunit=F) {
      if (!is_quantity(v)) fail('Argument v must be some quantum');
      tfreqRec :=		[_method="tfreq",
				_sequence=private.id._sequence];
      tfreqRec["arg"] := shape(public.getvalue(v));
      tfreqRec["val"] := v;
      tfreqRec["val"].value:: := [=];
      if (!is_string(outunit)) outunit := public.getformat('freq');
      tfreqRec["form"] := outunit;
      tfreqRec["form2"] := showunit;
      return defaultservers.run(private.agent, tfreqRec);
    }
#
# convert (v='1', out='') -> convert unit v to units as in out 
#
    const public.convert := function(v='1', out='') {
      return private.qfunc2(public.unit(v), public.unit(out), 5);
    }
#
# canonical/canon (v='1') -> canonical value of v
#
    const public.canonical := function(v='1') {
      return private.qfunc1(public.unit(v), 9);
    }
    const public.canon := public.canonical;
#
# define (name, v='1') define name as new unit with value v
#
    const public.define := function(name, v='1') {
      defineRec :=		[_method="define",
				_sequence=private.id._sequence];
      defineRec["val"] := v;
      defineRec["arg"] := name;
      return defaultservers.run(private.agent, defineRec);
    }
#
# unit (v=1., name='') -> unit from string v; or from units name and value v
#
    const public.unit := function(v=1., name='') {
      if (is_quantity(v)) return v;
      unitRec :=		[_method="unit",
				_sequence=private.id._sequence];
      unitRec["val"] := v;
      if (is_string(v)) {
	unitRec._method := "quant";
	return defaultservers.run(private.agent, unitRec);
      };
      unitRec["arg"] := name;
      if (!is_numeric(v)) fail('First argument of dq.unit not string or numeric'); 
      if (!is_string(name) || len(name) > 1) {
	fail('Argument 2 of dq.unit must be scalar string');
      };
      if (length(v) > 1) {
	unitRec._method := "unitv";
	if (is_integer(v::shape)) {
	  a := v::shape;
	  unitRec["val"]:: := [=];
	  b := defaultservers.run(private.agent, unitRec);
	  if (is_record(b) && has_field(b, 'value')) b.value::shape := a;
	  return b;
	};
      };
      return defaultservers.run(private.agent, unitRec);
    }
#
# quantity (v=1., name='') -> quantity from string v; 
#	or from units name and value v
#
    const public.quantity := public.unit;
#
# map (v='all') produce record of strings of specified type of units
#
    const public.map := function(v='all') {
      mapRec :=		[_method="map",
				_sequence=private.id._sequence];
      mapRec["val"] := v;
      b := '\t';
      if (v == 'Constants' || v == 'constants' || v == 'const' ||
	  v == 'Const') {
	b := spaste(b, '== Constants ====\n\t');
	for (j in private.units_const) {
	  b := spaste(b, j); b:= spaste(b, private.units_const_txt[j]);
	  b := spaste(b, '\t\t');
	  b := spaste(b, public.tos(public.constants(j)));
	  b := spaste(b, '\n\t');
	}
      } else {
	a := defaultservers.run(private.agent, mapRec);
	for (j in field_names(a)) {
	  b := spaste(b, a[j]); b := spaste(b, '\n\t');
	}
      }
      return b;
    }
#
# angle (v, prec=0, form="") -> formatted string of angle/time unit
#
    const public.angle := function(v, prec=0, form="",
				   showform=F) {
      angleRec :=		[_method="angle",
				_sequence=private.id._sequence];
      if (is_string(v)) v := public.quantity(v);
      angleRec["arg2"] := shape(public.getvalue(v));
      angleRec["val"] := v;
      private.forcevec(angleRec["val"]);
      if (!prec) prec := private.format.aprec; 
      angleRec["arg"] := prec;
      angleRec["form"] := form;
      angleRec["form2"] := showform;
      return defaultservers.run(private.agent, angleRec);
    }
#
# time (v, prec=0, form="") -> formatted string of time/angle unit
#
    const public.time := function(v, prec=0, form="",
				  showform=F) {
      timeRec :=		[_method="time",
				_sequence=private.id._sequence];
      if (is_string(v)) v := public.quantity(v);
      timeRec["arg2"] := shape(public.getvalue(v));
      timeRec["val"] := v;
      private.forcevec(timeRec["val"]);
      if (!prec) prec := private.format.tprec; 
      timeRec["arg"] := prec;
      timeRec["form"] := form;
      timeRec["form2"] := showform;
      return defaultservers.run(private.agent, timeRec);
    }
#
# Quantum to String
#
    const public.tos := function(v, prec=0) {
      global system;
      local a := system.print.precision;
      if (is_integer(prec) && prec>1) system.print.precision := prec;
      if (is_quantity(v)) {
	local b := as_string(public.getvalue(v));
	system.print.precision := a;
	return (paste(b, public.getunit(v)));
      } else {
	system.print.precision := a;
	if (is_string(v)) return v;
      };
      return '0';
    }
#
# String to Quantum
#
    const private.toq := function(v) {
      if (is_quantity(v)) a := v;
      else {
	if (public.check(v)) a := public.convert(v,v);
	else {
	  public.errorgui('Illegal unit string specified');
	  return (public.convert('0'));
	};
      };
      if (has_field(a, 'value') && a.value == 0) a.value := as_double(1);
      return a;
    }
#
# Check if angle
#
    const public.is_angle := function(v) {
      at := public.unit(1., 's');
      aa := public.unit(1., 'rad');
      return (public.check(v) && (public.compare(v, at) ||
				  public.compare(v, aa)));
    }	
#
# convertfreq (v='1Hz', out='Hz') -> convert frequency to units as in out 
#
    const public.convertfreq := function(v='1Hz', out='Hz') {
      frqcvRec :=		[_method="frqcv",
				_sequence=private.id._sequence];
      frqcvRec.val := v;
      frqcvRec.arg := out;
      return defaultservers.run(private.agent, frqcvRec);
    }
#
# convertdop (v='0km/s', out='km/s') -> convert doppler to units as in out 
#
    const public.convertdop := function(v='0km/s', out='km/s') {
      dopcvRec :=		[_method="dopcv",
				_sequence=private.id._sequence];
      dopcvRec.val := v;
      dopcvRec.arg := out;
      return defaultservers.run(private.agent, dopcvRec);
    }
#
# fits() define FITS related units
#
    const public.fits := function() {
      fitsRec :=		[_method="fits",
				_sequence=private.id._sequence];
      return defaultservers.run(private.agent, fitsRec);
    }
#
# neg (v='1') -> negate units 
#
    const public.neg := function(v='1') {
      a := public.unit(v);
      return public.unit(-public.getvalue(a), public.getunit(a));
    }
#
# add (v, a='0') -> added units
#
    const public.add := function(v, a='0') {
      return private.qfunc2(public.unit(v), public.unit(a), 4);
    }
#
# sub (v, a='0') -> subtracted units
#
    const public.sub := function(v, a='0') {
      return private.qfunc2(public.unit(v), public.unit(a), 3);
    }
#
# div (v, a='1') -> divided units
#
    const public.div := function(v, a='1') {
      return private.qfunc2(public.unit(v), public.unit(a), 2);
    }
#
# mul (v, a='1') -> multiplied units
#
    const public.mul := function(v, a='1') {
      return private.qfunc2(public.unit(v), public.unit(a), 1);
    }
#
# norm (v, a=-0.5) -> normalised angle v
#
    const public.norm := function(v, a= -0.5) {
      normRec :=		[_method="norm",
				_sequence=private.id._sequence];
      normRec.val := v;
      normRec.arg := a;
      if (is_quantity(v) && length(v.value) > 1) {
	normRec.val := [value=v.value[1], unit=v.unit];
	a := defaultservers.run(private.agent, normRec);
	for (i in 2:length(v.value)) {
	  normRec.val := [value=v.value[i], unit=v.unit];
	  a.value[i] := defaultservers.run(private.agent, normRec).value;
	};
	return a;
      } else {
	return defaultservers.run(private.agent, normRec);
      };
    }
#
# le (v, a) -> v <= a;
#
    const public.le := function(v, a) {
      return private.qlogical(public.unit(v), public.unit(a), 0);
    }
#
# lt (v, a) -> v < a;
#
    const public.lt := function(v, a) {
      return private.qlogical(public.unit(v), public.unit(a), 1);
    }
#
# eq (v, a) -> v == a;
#
    const public.eq := function(v, a) {
      return private.qlogical(public.unit(v), public.unit(a), 2);
    }
#
# ne (v, a) -> v != a;
#
    const public.ne := function(v, a) {
      return private.qlogical(public.unit(v), public.unit(a), 3);
    }
#
# gt (v, a) -> v >= a;
#
    const public.gt := function(v, a) {
      return private.qlogical(public.unit(v), public.unit(a), 4);
    }
#
# ge (v, a) -> v > a;
#
    const public.ge := function(v, a) {
      return private.qlogical(public.unit(v), public.unit(a), 5);
    }
#
# force multivalued quantum into a vector shape
#
    const private.forcevec := function(ref v) {
      if (is_quantity(v) && has_field(v::, 'shape') && length(v)>0) {
	for (i in 1:length(v)) {
	  if (has_field(v[i].value::, 'shape')) {
	    v[i].value::shape := [length(v[i].value)];
	  };
	};
      } else if (is_quantity(v) && has_field(v.value::, 'shape')) {
	  if (length(v.value) > 1) {
	    v.value::shape := [length(v.value)];
	  } else v.value:: := [=]; 
      };
    }
#
# qfunc1(v,tp) -> one argument function
#
    const private.qfunc1 := function(v,tp) {
      qfunc1Rec :=		[_method="qfunc1",
				_sequence=private.id._sequence];
      qfunc1Rec.val := v;
      qfunc1Rec.form := tp;
      if (length(v.value) > 1) qfunc1Rec._method := "qvfunc1";
      private.forcevec(qfunc1Rec.val);
      return defaultservers.run(private.agent, qfunc1Rec);
    }
#
# qfunc2(v,a,tp) -> two argument function
#
    const private.qfunc2 := function(v,a,tp) {
      qfunc2Rec :=		[_method="qfunc2",
				_sequence=private.id._sequence];
      qfunc2Rec.val := v;
      qfunc2Rec.arg := a;
      qfunc2Rec.form := tp;
      if (length(v.value) > 1 || length(a.value) > 1) {
	if (length(v.value) == 1) {
	  for (i in 2:length(a.value)) {
	    v.value[i] := v.value[1];
	  };
	  qfunc2Rec.val := v;
	} else if (length(a.value) == 1) {
	  for (i in 2:length(v.value)) {
	    a.value[i] := a.value[1];
	  };
	  qfunc2Rec.arg := a;
	};
	qfunc2Rec._method := "qvvfunc2";
      };
      private.forcevec(qfunc2Rec.val);
      private.forcevec(qfunc2Rec.arg);
      return defaultservers.run(private.agent, qfunc2Rec);
    }
#
# qlogical(v,a,tp) -> comparison function
#
    const private.qlogical := function(v,a,tp) {
      qlogicalRec :=		[_method="qlogical",
				_sequence=private.id._sequence];
      qlogicalRec.val := v;
      qlogicalRec.arg := a;
      qlogicalRec.form := tp;
      return defaultservers.run(private.agent, qlogicalRec);
    }
#
# sin (v) -> sine of angle v
#
    const public.sin := function(v) {
      return private.qfunc1(public.toangle(v), 0);
    }
#
# cos (v) -> cosine of angle v
#
    const public.cos := function(v) {
      return private.qfunc1(public.toangle(v), 1);
    }
#
# tan (v) -> tangent of angle v
#
    const public.tan := function(v) {
      return private.qfunc1(public.toangle(v), 2);
    }
#
# asin (v) -> arcsine of v
#
    const public.asin := function(v) {
      return private.qfunc1(public.unit(v), 3);
    }
#
# acos (v) -> arccosine of v
#
    const public.acos := function(v) {
      return private.qfunc1(public.unit(v), 4);
    }
#
# atan (v) -> arctangent of v
#
    const public.atan := function(v) {
      return private.qfunc1(public.unit(v), 5);
    }
#
# atan2 (v, a) -> arctangent of two variables
#
    const public.atan2 := function(v, a) {
      return private.qfunc2(public.unit(v), public.unit(a), 0);
    }
#
# abs (v) -> absolute value of v
#
    const public.abs := function(v) {
      return private.qfunc1(public.unit(v), 6);
    }
#
# ceil (v) -> ceil of v
#
    const public.ceil := function(v) {
      return private.qfunc1(public.unit(v), 7);
    }
#
# floor (v) -> floor of v
#
    const public.floor := function(v) {
      return private.qfunc1(public.unit(v), 8);
    }
#
# log (v) -> logarithm of v
#
    const public.log := function(v) {
      return private.qfunc1(public.unit(v), 10);
    }
#
# log10 (v) -> logarithm of v
#
    const public.log10 := function(v) {
      return private.qfunc1(public.unit(v), 11);
    }
#
# exp (v) -> exp of v
#
    const public.exp := function(v) {
      return private.qfunc1(public.unit(v), 12);
    }
#
# sqrt (v) -> sqrt of v
#
    const public.sqrt := function(v) {
      return private.qfunc1(public.unit(v), 13);
    }
#
# compare (v, a) -> T if unit dimensions of v and a equal
#
    const public.compare := function(v, a) {
      compareRec :=		[_method="compare",
				_sequence=private.id._sequence];
      if (is_quantity(v) && length(v.value) > 1) {
	v := public.unit(v.value[1], v.unit);
      };
      compareRec.val := v;
      if (is_quantity(a) && length(a.value) > 1) {
	a := public.unit(a.value[1], a.unit);
      };
      compareRec.arg := a;
      return defaultservers.run(private.agent, compareRec);
    }
#
# check (v) -> T if v is proper unit definition
#
    const public.check := function(v) {
      if (is_quantity(v)) return T;
      checkRec :=		[_method="check",
				_sequence=private.id._sequence];
      checkRec.arg := v;
      return defaultservers.run(private.agent, checkRec);
    }
#
# checkfreq (cm) -> T if cm is proper frequency unit definition
#
    const public.checkfreq := function(cm) {
      if (public.check(cm) &&
	  (public.compare(cm,'1s') ||
	   public.compare(cm,'1Hz') ||
	   public.compare(cm,'1deg/s') ||
	   public.compare(cm,'1m') ||
	   public.compare(cm,'1m-1') ||
	   public.compare(cm,'1(eV)') ||
	   public.compare(cm,'1kg.m'))) return T;
      return F;
    }
#
# pow (v, a=1) -> unit raised to power
#
    const public.pow := function(v, a=1) {
      powRec :=			[_method="pow",
				_sequence=private.id._sequence];
      powRec.val := v;
      powRec.arg := a;
      if (is_quantity(v) && length(v.value) > 1) {
	powRec.val := [value=v.value[1], unit=v.unit];
	a := defaultservers.run(private.agent, powRec);
	for (i in 2:length(v.value)) {
	  powRec.val := [value=v.value[i], unit=v.unit];
	  a.value[i] := defaultservers.run(private.agent, powRec).value;
	};
	return a;
      } else {
	return defaultservers.run(private.agent, powRec);
      };
    }
#
# constants (v='pi') -> unit as indicated constant
#
    const public.constants := function(v='pi') {
      constantsRec :=			[_method="constants",
					_sequence=private.id._sequence];
      constantsRec.val := v;
      return defaultservers.run(private.agent, constantsRec);
    }
#
# totime (v) -> unit as time if input angle or time
#
    const public.totime := function(v) {
      totimeRec :=			[_method="totime",
					_sequence=private.id._sequence];
      if (public.is_angle(v)) {
	totimeRec.val := v;
	if (is_quantity(v) && length(v.value) > 1) {
	  totimeRec.val := [value=v.value[1], unit=v.unit];
	  a := defaultservers.run(private.agent, totimeRec);
	  for (i in 2:length(v.value)) {
	    totimeRec.val := [value=v.value[i], unit=v.unit];
	    a.value[i] := defaultservers.run(private.agent, totimeRec).value;
	  };
	  return a;
	} else {
	  return defaultservers.run(private.agent, totimeRec);
	};
      } else {
	public.errorgui('Illegal time format or string specified');
	return (public.unit(0,'d'));
      }
    }
#
# splitdate(v) -> returns a record with time split into:
#     mjd, year, yearday, month, monthday, week, weekday, hour, min, sec
#
    const public.splitdate := function(v) {
	splitdateRec :=			[_method="splitdate",
					 _sequence=private.id._sequence];
	if (public.is_angle(v)) {
	    splitdateRec.val := v;
	    return defaultservers.run(private.agent, splitdateRec);
	} else {
	    public.errorgui('Illegal time format or string specified');
	    return (public.unit(0,'d'));
	};
    }
#
# toangle (v) -> unit as angle, if v angle or time
#
    const public.toangle := function(v) {
      toangleRec :=			[_method="toangle",
					_sequence=private.id._sequence];
      if (public.is_angle(v)) {
	toangleRec.val := v;
	if (is_quantity(v) && length(v.value) > 1) {
	  toangleRec.val := [value=v.value[1], unit=v.unit];
	  a := defaultservers.run(private.agent, toangleRec);
	  for (i in 2:length(v.value)) {
	    toangleRec.val := [value=v.value[i], unit=v.unit];
	    a.value[i] := defaultservers.run(private.agent, toangleRec).value;
	  };
	  return a;
	} else {
	  return defaultservers.run(private.agent, toangleRec);
	};
      } else {
	public.errorgui('Illegal angle format or string specified');
	return (public.unit(0,'deg'));
      }
    }
#
# Start GUI interface method
#
# gui() start GUI interface
#
    const public.startgui := function() {
      if (!has_field(private, "gui")) {
	include 'quantagui.g';
	a := quantagui(private, public);
      };
      return T;
    }
#
    const public.gui := function(parent=F) {
      public.startgui();
      private.gui(parent=parent);
    }

    const public.type := function() {
      return 'quanta';
    }
#
# id() needed for toolmanager kill
#
    const public.id :=function() {
      return private.id.objectid;
    }
#
# Error frame
#
    const public.errorgui := function(txt='') {
      wider private;
      if (has_field(private, "errorgui") && is_function(private.errorgui)) {
	private.errorgui(txt);
      } else {
	print txt;
      };
      return T;
    }
#
# Value enter frame
#
    const public.entergui := function(txt='', deflt='') {
      if (has_field(private, "entergui") && is_function(private.entergui)) {
	return private.entergui(txt, deflt);
      };
      cm := readline(prompt=spaste('Specify value for ', txt,
				   '[', deflt, ']: '));
      if (len(cm) == 0 || strlen(cm) == 0) cm := deflt;
      if (is_string(cm)) return cm;
      fail('dq.entergui');
    }
#
# Create base frame
#
    const public.createbf := function(title='', parent=F, onlyone=F,
				      widgetset=dws) {
      wider private;
      if (!have_gui()) return 0;
      n := 0;
      if (!onlyone || !public.testbf(n=T)) {
	private.frame[len(private.frame) + 1] :=
	  widgetset.frame(parent, title=title);
	n := len(private.frame);
	if (onlyone && public.testbf(n)) private.frame[n].mainbf := T;
      };
      return n;
    }
#
# Test base frame
#
    const public.testbf := function(n=F) {
      b := [];
      if (is_boolean(n)) {
	b := ind(private.frame);
      } else if (is_integer(n) &&
		 n>0 && n <= len(private.frame)) {
	b := n;
	n := F;
      };
      if (len(b) == 0) return F;
      for (i in b) {
	if (is_agent(private.frame[i]) &&
	    !has_field(private.frame[i], 'killed')) {
	  if (!n || (has_field(private.frame[i], 'mainbf') &&
		     private.frame[i].mainbf)) {
	    return T;
	  };
	};
      };
      return F;
    }
#
# Get base frame ref
#
    const public.getbf := function(n=0) {
      if (public.testbf(n)) return ref private.frame[n];
      fail('dq.getbf');
    }
#
# Delete a frame
#
    const public.deletebf := function(n=0) {
      wider private;
      if (public.testbf(n) &&
	  has_field(private, "deletebf") && is_function(private.deletebf)) {
	private.deletebf(n);
      };
      return T;
    }
#
# Delete all frames
#
    const public.delallbf := function(all=F) {
      if (len(private.frame) == 0) return T;
      for (i in len(private.frame):1) {
	if (public.testbf(i)) {
	  if (!has_field(private.frame[i], "mainbf") || all) {
	      public.deletebf(i);
	  };
	};
      };
      return T;
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
	  if (has_field(private, 'gui')) {
	    public.delallbf(T);
	  };
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
  defaultquanta := quanta();
  const defaultquanta := defaultquanta;
  const dq := ref defaultquanta;
#
# Start-up messages
#
  if (!is_boolean(dq)) {
    note('defaultquanta (dq) ready', priority='NORMAL', 
	 origin='quanta');
#
# Start up Gui if defined in .aipsrc or globally set
#
# Logics to get gui:
#	global_use_gui defined && numeric && T && have_gui()    else
#	aipsrc variable set to gui && have_gui()
    if (is_defined("global_use_gui") && is_numeric(global_use_gui)) {
      if (global_use_gui) dq.gui();
    } else if (drc.find(what,"quanta.default") && what == 'gui') {
      dq.gui();
    };
  };

# Add defaultquanta to the GUI if necessary
if (any(symbol_names(is_record)=='objrepository') &&
    has_field(objrepository, 'notice')) {
	objrepository.notice('defaultquanta', 'quanta');
};



