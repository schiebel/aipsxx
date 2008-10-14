# measures.g: Access to measures classes
# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
# $Id: measures.g,v 19.3 2004/08/25 01:29:22 cvsmgr Exp $
#
pragma include once;

include 'servers.g';
include 'aipsrc.g';
include 'timer.g';
include 'quanta.g';
include 'note.g';
include 'choice.g';
include 'serverexists.g';
include 'unset.g';
#
##defaultservers.trace(T)
##defaultservers.suspend(T)
#
# Global methods
#
# Check if a measure
#
  const is_measure := function(v) {
    return (is_record(v) &&
	    ((has_field(v::, 'id') && v::id == 'meas') ||
	    (!has_field(v::, 'id') && !has_field(v::, 'shape') &&
	     has_field(v, "type") && v.type != "none" &&
	     has_field(v, "refer") && has_field(v, "m0") &&
	     is_quantity(v.m0))));
  }
#
# Server
#
  const measures := function(host='', forcenewserver=F) {
    global system;
    private := [=];
    public := [=];
    public::print.limit := 1;
    if (!serverexists('dq', 'quanta', dq)) {
      return throw('The quanta server "dq" is not running',
		   origin='measures.g');
    };
    private.agent := defaultservers.activate("measures", host,
					     forcenewserver);

    if (is_fail(private.agent)) return F;
    private.id := defaultservers.create(private.agent, "measures");
    private.iamdefault := T;
    if (is_defined('dm') && is_function(dm.gui) && is_function(dm.done)) {
      private.iamdefault := F;
    };
    if (!has_field(system, 'print')) system.print := [=];
    system.print.precision := dq.getformat('prec');
    private.framestack := [=];
    private.frameshow := [=];
    private.frameshow[1] := F;
    private.autostack := [=];
    private.autoshow := [=];
    private.autoshow[1] := F;
    private.autotime := 2;
    private.applic := [=];
    private.applic.freq := '5GHz';
    private.applic.vel  := '0km/s';
#
# Public methods
#
# dirshow(v=a direction) -> Show a direction formatted
#
    const public.dirshow := function(v) {
      if (is_measure(v)) {
	return [dq.form.long(v.m0), dq.form.lat(v.m1),
	        v.refer];
      } else return '';
    }
#
# show(v=a measure, refcode=T) -> Show a measure formatted (with reference code)
#
    const public.show := function(v, refcode=T) {
      z := "";
      if (is_measure(v)) {
	x := dm.gettype(v);
	y := dm.getvalue(v);
	if (x ~ m/^dir/i) {
	  z := [dq.form.long(y[1]), dq.form.lat(y[2])];
	} else if (x ~ m/^pos/i) {
	  z := [dq.form.long(y[1]), dq.form.lat(y[2]),
	       dq.form.len(y[3])];
	} else if (x ~ m/^epo/i) {
	  z := dq.form.dtime(y[1]);
	} else if (x ~ m/^radial/i || x ~ m/^dopp/i) {
	  z := dq.form.vel(y[1]);
	} else if (x ~ m/^freq/i) {
	  z := dq.form.freq(y[1]);
	} else if (x ~ m/^earth/i) {
	  z := [dq.tos(y[1]), dq.tos(y[2]),
	       dq.tos(y[3])];
	} else if (x ~ m/^base/i || x ~ m/^uvw/i) {
	  y := dm.addxvalue(v);
	  z := [dq.form.len(y[1]), dq.form.len(y[2]),
	       dq.form.len(y[3])];
	} else {
	  return '';
	};
	if (refcode) return [z, dm.getref(v)];
      };
      return z;
    }
#
# Add extra values (for direction and position mainly) as 3D vector
#
    const public.addxvalue := function(ref v) {
      if (!is_measure(v)) fail('Non-measure for addxvalue()');
      addevRec :=		[_method="addev",
				_sequence=private.id._sequence];
      addevRec["val"] := v;
      a := defaultservers.run(private.agent, addevRec);
      if (is_fail(a)) fail;
      return a;
    }      
#
# epoch (rf, v0, off=F) -> epoch from rf, time v0 and optional offset
#
    const public.epoch := function(rf='', v0='0.0d', off=F) {
      loc := [type='epoch', refer=rf];
      if (is_record(v0) && !has_field(v0, 'unit')) {
        if (length(v0) > 1) {
	  v0 := dq.add(dq.quantity(v0[1]), dq.quantity(v0[2]));
	} else if (length(v0) > 0) v0 := v0[1];	
      };
      loc.m0 := dq.quantity(v0);
      if (is_measure(off)) {
	if (off.type == "epoch") loc.offset := off;
	else dq.errorgui('Illegal offset type specified, not used');
      };
      loc := public.measure(loc, rf);
      if (is_measure(loc)) return loc;
      return F;
    }
#
# position (rf, v0, v1='', v2='', off=F) -> position from 
#		rf, long v1, lat v2, height v0 (or x,y,z) and optional offset
#
    const public.position := function(rf='', v0='0..', v1='90..', v2='0m',
				      off=F) {
      loc := [type="position", refer=rf];
      if (is_record(v0) && !has_field(v0, 'unit')) {
	if (length(v0) > 2) v2 := v0[3];
        if (length(v0) > 1) v1 := v0[2];
        if (length(v0) > 0) v0 := v0[1];
      };
      loc.m0 := dq.quantity(v0);
      if (is_string(v1) && v1=='90..' && is_string(v2) && v2=='0m' &&
	  length(dq.getvalue(loc.m0)) > 2) {
	v2 := dq.unit(dq.getvalue(loc.m0)[3], dq.getunit(loc.m0));
	v1 := dq.unit(dq.getvalue(loc.m0)[2], dq.getunit(loc.m0));
	loc.m0 := dq.unit(dq.getvalue(loc.m0)[1], dq.getunit(loc.m0));
      };
      loc.m1 := dq.quantity(v1);
      loc.m2 := dq.quantity(v2);
      if (is_measure(off)) {
	if (off.type == "position") loc.offset := off;
	else dq.errorgui('Illegal offset type specified, not used');
      };
      loc := public.measure(loc, rf);
      if (is_measure(loc)) return loc;
      return F;
    }
#
# direction (rf, v0='0..', v1='90..', off=F) -> direction from rf, long/lat v0,v1
#				 and optional offset
#
    const public.direction := function(rf='', v0='0..', v1='90..', off=F) {
      loc := [type='direction', refer=rf];
      if (is_record(v0) && !has_field(v0, 'unit')) {
        if (length(v0) > 1) v1 := v0[2];
        if (length(v0) > 0) v0 := v0[1];
      };
      loc.m0 := dq.quantity(v0);
      loc.m1 := dq.quantity(v1);
      if (is_measure(off)) {
	if (off.type == "direction") loc.offset := off;
	else dq.errorgui('Illegal offset type specified, not used');
      };
      loc := public.measure(loc, rf);
      if (is_measure(loc)) return loc;
      return F;
    }
#
# frequency (rf, v0, off=F) -> frequency from rf, value v0 and optional offset
#
    const public.frequency := function(rf='', v0='0Hz', off=F) {
      if (is_record(v0) && !has_field(v0, 'unit')) {
        if (length(v0) > 0) v0 := v0[1];
      };
      loc := [type="frequency", refer=rf, m0=dq.quantity(v0)];
      if (is_measure(off)) {
	if (off.type == 'frequency') loc.offset := off;
	else dq.errorgui('Illegal offset type specified, not used');
      };
      loc := public.measure(loc, rf);
      if (is_measure(loc)) return loc;
      return F;
    }
#
# tofrequency (rf, v0, rfq) -> frequency as rf, doppler v0, rest frequency rfq
#
    const public.tofrequency := function(rf, v0, rfq) {
      loc := F;
      if (is_measure(rfq) && rfq.type == 'frequency')
	rfq := rfq.m0;
      if (is_measure(v0) && v0.type == 'doppler' && is_quantity(rfq) &&
	  dq.compare(rfq, dq.quantity(1.,'Hz'))) {
	loc := private.doptofreq(rf, v0, rfq);
      } else {
	dq.errorgui('Illegal Doppler or rest frequency specified');
      };
      if (is_measure(loc)) return loc;
      return F;
    }
#
# torestfrequency (v0, d0) -> rest frequency from freq v0, doppler d0
#
    const public.torestfrequency := function(v0, d0) {
      loc := F;
      if (is_measure(v0) && v0.type == 'frequency' && is_measure(d0) &&
	  d0.type == 'doppler') loc := private.torest(v0, d0);
      else dq.errorgui('Illegal Doppler or rest frequency specified');
      if (is_measure(loc)) return loc;
      return F;
    }
#
# doppler (rf, v0, off=F) -> doppler from rf, doppler v0 and optional offset
#
    const public.doppler := function(rf='', v0='0', off=F) {
      if (is_record(v0) && !has_field(v0, 'unit')) {
        if (length(v0) > 0) v0 := v0[1];
      };
      loc := [type="doppler", refer=rf, m0=dq.quantity(v0)];
      if (is_measure(off)) {
	if (off.type == 'doppler') loc.offset := off;
	else dq.errorgui('Illegal offset type specified, not used');
      };
      loc := public.measure(loc, rf);
      if (is_measure(loc)) return loc;
      return F;
    }
#
# todoppler (rf, v0, rfq) -> Doppler as rf, radvel/freq v0, rest frequency rfq
#
    const public.todoppler := function(rf, v0, rfq=F) {
      loc := F;
      if (is_measure(rfq) && rfq.type == 'frequency') rfq := rfq.m0;
      if (is_measure(v0)) {
	if (v0.type == 'radialvelocity') {
	  loc := private.todop(v0, dq.quantity(1.,'Hz'));
	} else if (v0.type == 'frequency' && is_quantity(rfq) &&
		   dq.compare(rfq, dq.quantity(1.,'Hz'))) {
	  loc := private.todop(v0, rfq);
	} else {
	  dq.errorgui('Illegal Doppler or rest frequency specified');
	};
      };
      if (is_measure(loc)) {
	return public.measure(loc, rf);
      };
      return F;
    }
#
# radialvelocity (rf, v0, off=F) -> radialvelocity from rf, velocity v0 and
#					 optional offset
#
    const public.radialvelocity := function(rf='', v0='0m/s', off=F) {
      if (is_record(v0) && !has_field(v0, 'unit')) {
        if (length(v0) > 0) v0 := v0[1];
      };
      loc := [type="radialvelocity", refer=rf, m0=dq.quantity(v0)];
      if (is_measure(off)) {
	if (off.type == "radialvelocity") loc.offset := off;
	else dq.errorgui('Illegal offset type specified, not used');
      };
      loc := public.measure(loc, rf);
      if (is_measure(loc)) return loc;
      return F;
    }
#
# toradialvelocity (rf, v0) -> radialvelocity as rf, doppler v0
#
    const public.toradialvelocity := function(rf, v0) {
      loc := F;
      if (is_measure(v0) && v0.type == 'doppler') {
	loc := private.doptorv(rf, v0);
      } else {
	dq.errorgui('Illegal Doppler specified');
      };
      if (is_measure(loc)) return loc;
      return F;
    }
#
# baseline (rf, v0, v1='', v2='', off=F) -> baseline from 
#		rf, long v1, lat v2, height v0 (or x,y,z) and optional offset
#
    const public.baseline := function(rf='', v0='0..', v1='', v2='', off=F) {
      loc := [type="baseline", refer=rf];
      if (is_record(v0) && !has_field(v0, 'unit')) {
	if (length(v0) > 2) v2 := v0[3];
        if (length(v0) > 1) v1 := v0[2];
        if (length(v0) > 0) v0 := v0[1];
      };
      loc.m0 := dq.quantity(v0);
      loc.m1 := dq.quantity(v1);
      loc.m2 := dq.quantity(v2);
      if (is_measure(off)) {
	if (off.type == "baseline") loc.offset := off;
	else dq.errorgui('Illegal offset type specified, not used');
      };
      loc := public.measure(loc, rf);
      if (is_measure(loc)) return loc;
      return F;
    }
#
# asbaseline (pos) make a baseline from position
#
    const public.asbaseline := function(pos) {
      if (!is_measure(pos) || (pos.type != 'position' && 
			       pos.type != 'baseline')) {
	fail('Non-position type for asbaseline input');
      };
      if (pos.type == 'position') {
	loc := public.measure(pos, 'itrf');
	loc.type := 'baseline';
	if (!is_measure(loc)) fail('Cannot convert position to baseline');
	loc := public.measure(loc, 'j2000');
	if (!is_measure(loc)) fail('Cannot convert baseline to J2000');
	return loc;
      };
      return pos;
    }
#
# uvw (rf, v0, v1='', v2='', off=F) -> uvw from 
#		rf, long v1, lat v2, height v0 (or x,y,z) and optional offset
#
    const public.uvw := function(rf='', v0='0..', v1='', v2='', off=F) {
      loc := [type="uvw", refer=rf];
      if (is_record(v0) && !has_field(v0, 'unit')) {
	if (length(v0) > 2) v2 := v0[3];
        if (length(v0) > 1) v1 := v0[2];
        if (length(v0) > 0) v0 := v0[1];
      };
      loc.m0 := dq.quantity(v0);
      loc.m1 := dq.quantity(v1);
      loc.m2 := dq.quantity(v2);
      if (is_measure(off)) {
	if (off.type == "uvw") loc.offset := off;
	else dq.errorgui('Illegal offset type specified, not used');
      };
      loc := public.measure(loc, rf);
      if (is_measure(loc)) return loc;
      return F;
    }
#
# touvw (v, dot, xyz) -> baseline v converted to uvw and uvwdot
#
    const public.touvw := function(v, ref dot = unset, ref xyz=unset) {
      uvwRec :=				[_method="uvw",
					_sequence=private.id._sequence];
      uvwRec.val := v;
      a := defaultservers.run(private.agent, uvwRec);
      if (is_fail(a)) fail;
      if (!is_unset(dot) && has_field(uvwRec, 'arg')) {
	uvwRec.arg.value::shape:=[3,len(uvwRec.arg.value)/3];
	val dot := uvwRec.arg;
      };
      if (!is_unset(xyz) && has_field(uvwRec, 'form')) {
	uvwRec.form.value::shape:=[3,len(uvwRec.form.value)/3];
	val xyz := uvwRec.form;
      };
      return a;
    }
#
# expand (v, xyz) -> position v converted to baseline
#
    const public.expand := function(v, ref xyz=unset) {
      expRec :=				[_method="expand",
					_sequence=private.id._sequence];
      if (!(is_measure(v) && (v.type == 'baseline' || v.type == 'uvw' ||
			      v.type == 'position'))) {
	fail("Can only expand baselines, positions, or uvw");
      };
      expRec.val := v;
      expRec.val.type := 'uvw';
      expRec.val.refer := 'J2000';
      a := defaultservers.run(private.agent, expRec);
      if (is_fail(a)) fail;
      a.type := v.type;
      a.refer := v.refer;
      if (!is_unset(xyz) && has_field(expRec, 'arg')) {
	expRec.arg.value::shape := [3,len(expRec.arg.value)/3];
	val xyz := expRec.arg;
      };
      return a;
    }
#
# earthmagnetic (rf, v0, v1='', v2='', off=F) -> earthmagnetic from 
#		rf, long v1, lat v2, height v0 (or x,y,z) and optional offset
#
    const public.earthmagnetic := function(rf='', v0='0G', v1='0..', v2='90..',
					   off=F) {
      loc := [type="earthmagnetic", refer=rf];
      if (is_record(v0) && !has_field(v0, 'unit')) {
	if (length(v0) > 2) v2 := v0[3];
        if (length(v0) > 1) v1 := v0[2];
        if (length(v0) > 0) v0 := v0[1];
      };
      loc.m0 := dq.quantity(v0);
      loc.m1 := dq.quantity(v1);
      loc.m2 := dq.quantity(v2);
      if (is_measure(off)) {
	if (off.type == "earthmagnetic") loc.offset := off;
	else dq.errorgui('Illegal offset type specified, not used');
      };
      loc := public.measure(loc, rf);
      if (is_measure(loc)) return loc;
      return F;
    }
#
# get value of measure or measure[array]
#
    const public.getvalue := function(v) {
      if (!is_measure(v)) fail('Incorrect input type for dm.getvalue()');
      v0 := [=];
      if (has_field(v::, 'shape')) {
	for (i in ind(v)) {
	  if (has_field(v[i], 'm0')) v0[len(v0)+1] := v[i].m0;
	  if (has_field(v[i], 'm1')) v0[len(v0)+1] := v[i].m1;
	  if (has_field(v[i], 'm2')) v0[len(v0)+1] := v[i].m2;
	};
      } else {
	if (has_field(v, 'm0')) v0[len(v0)+1] := v.m0;
	if (has_field(v, 'm1')) v0[len(v0)+1] := v.m1;
	if (has_field(v, 'm2')) v0[len(v0)+1] := v.m2;
      };
      v0::id := 'quant';
      j := 1;
      if (has_field(v::, 'shape')) {
	if (has_field(v[1], 'm2')) j := 3;
	else if (has_field(v[1], 'm1')) j := 2;
	v0::shape := [j, len(v)];
	k := len(v);
      } else {
	if (has_field(v, 'm2')) j := 3;
	else if (has_field(v, 'm1')) j := 2;
	v0::shape := [j];
      };
      return v0;
    }
#
# get type of measure or measure array
#
    const public.gettype := function(v) {
      if (!is_measure(v)) fail('Incorrect input type for dm.gettype()');
      if (has_field(v::, 'shape')) return v[1].type;
      else return v.type;
    } 
#
# get reference of measure or measure array
#
    const public.getref := function(v) {
      if (!is_measure(v)) fail('Incorrect input type for dm.getref()');
      if (has_field(v::, 'shape')) return v[1].refer;
      else return v.refer;
    } 
#
# get offset of measure or measure array
#
    const public.getoffset := function(v) {
      if (!is_measure(v)) fail('Incorrect input type for dm.getoffset()');
      if (has_field(v::, 'shape')) {
	if (has_field(v[1], 'offset')) return v[1].offset;
	else return F;
      } else {
	if (has_field(v, 'offset')) return v.offset;
	else return F;
      };
    } 
#
# measure (v, rf, off=F) -> measure v converted to rf with optional offset
#
    const public.measure := function(v, rf, off=F, ref qv=F) {
      measureRec :=			[_method="measure",
					_sequence=private.id._sequence];
      measureRec.val := v;
      measureRec.form := [none=F];
      if (is_measure(off)) measureRec.form["offset"] := off;
      measureRec.arg := rf;
      return defaultservers.run(private.agent, measureRec);
    }
#
# listcodes(measure)
#
    const public.listcodes := function(ms) {
      alltypesRec :=			[_method="alltyp",
					_sequence=private.id._sequence];
      alltypesRec.val := ms;
      return defaultservers.run(private.agent, alltypesRec);
    }
#
# Measures data
#
    private.epval := [=];
    private.epval.ref := public.listcodes(public.epoch('UTC'))[1];
    private.epval.inref := 'UTC';
    private.epval.outref := 'UTC';
    private.posval := [=];
    private.posval.ref := public.listcodes(public.position('WGS84'))[1];
    private.posval.inref := 'WGS84';
    private.posval.outref := 'WGS84';
    private.dirval := [=];
    private.dirval.ref := public.listcodes(public.direction('J2000'))[1]; 
    private.dirval.planet := public.listcodes(public.direction('J2000'))[2];
    private.dirval.inref := 'J2000';
    private.dirval.outref := 'J2000';
    private.frqval := [=];
    private.frqval.ref := public.listcodes(public.frequency('LSRK'))[1];
    private.frqval.inref := 'LSRK';
    private.frqval.outref := 'LSRK';
    private.dplval := [=];
    private.dplval.ref := public.listcodes(public.doppler('RADIO'))[1];
    private.dplval.inref := 'RADIO';
    private.dplval.outref := 'RADIO';
    private.rvval := [=];
    private.rvval.ref := public.listcodes(public.radialvelocity('LSRK'))[1];
    private.rvval.inref := 'LSRK';
    private.rvval.outref := 'LSRK';
#
# doptorv(rf,v)
#
    const private.doptorv := function(rf, v) {
      doptorvRec :=			[_method="doptorv",
					_sequence=private.id._sequence];
      doptorvRec.val := v;
      doptorvRec.arg := rf;
      return defaultservers.run(private.agent, doptorvRec);
    }
#
# doptofreq(rf,v,rfq)
#
    const private.doptofreq := function(rf, v, rfq) {
      doptofreqRec :=			[_method="doptofreq",
					_sequence=private.id._sequence];
      doptofreqRec.val := v;
      doptofreqRec.arg := rf;
      doptofreqRec.form := rfq;
      return defaultservers.run(private.agent, doptofreqRec);
    }
#
# todop(v,rfq)
#
    const private.todop := function(v, rfq) {
      todopRec :=			[_method="todop",
					_sequence=private.id._sequence];
      todopRec.val := v;
      todopRec.form := rfq;
      return defaultservers.run(private.agent, todopRec);
 }
#
# torest(v,d)
#
    const private.torest := function(v, d) {
      torestRec :=			[_method="torest",
					_sequence=private.id._sequence];
      torestRec.val := v;
      torestRec.arg := d;
      return defaultservers.run(private.agent, torestRec);
    }
#
# obslist() -> get list of observatories
#
    const public.obslist := function() {
      obslistRec := 			[_method="obslist",
					_sequence=private.id._sequence];
      return defaultservers.run(private.agent, obslistRec);
    }
#
# observatory(name) -> get position of observatory named name
#
    const public.observatory := function(name='atca') {
      observatoryRec := 		[_method="observatory",
					_sequence=private.id._sequence];
      observatoryRec.val := name;
      return defaultservers.run(private.agent, observatoryRec);
    }
#
# linelist()
#
    const public.linelist := function() {
      linelistRec := 			[_method="linelist",
					_sequence=private.id._sequence];
      return defaultservers.run(private.agent, linelistRec);
    }
#
# spectralline(name)
#
    const public.spectralline := function(name='HI') {
      lineRec :=			[_method="line",
					_sequence=private.id._sequence];
      lineRec.val := name;
      return defaultservers.run(private.agent, lineRec);
    }
#
# sourcelist()
#
    const public.sourcelist := function() {
      srclistRec := 			[_method="srclist",
					_sequence=private.id._sequence];
      ok := defaultservers.run(private.agent, srclistRec);
      if (is_fail(ok)) ok := "None";
      return ok;
    }
#
# source(name)
#
    const public.source := function(name='PKS1934-638') {
      sourceRec :=			[_method="source",
					_sequence=private.id._sequence];
      sourceRec.val := name;
      ok := defaultservers.run(private.agent, sourceRec);
      return ok;
    }
#
# Fill When with now if not filled
#
    private.fillnow := function() {
      if (!has_field(private.framestack, "epoch") ||
	  !is_measure(private.framestack['epoch'])) {
	public.framenow();
      };
    }
#
# Fill Observatory name list
#
    private.fillobslist := function() {
      wider private;
      if (!has_field(private.posval, 'obs')) {
	private.posval.obs := split(public.obslist());
      };
      return T;
    }
#
# Fill frequency line list
#
    private.filllinelist := function() {
      wider private;
      if (!has_field(private.frqval, 'line')) {
	private.frqval.line := split(public.linelist());
      };
      return T;
    }
#
# Fill source list
#
    private.fillsourcelist := function() {
      wider private;
      if (!has_field(private.dirval, 'source')) {
	private.dirval.source := split(public.sourcelist());
      };
      return T;
    }
#
# Get when or fail
#
    private.getwhen := function() {
      if (!has_field(private.framestack, 'epoch') ||
	  !is_measure(private.framestack['epoch'])) {
	fail;
      };
      return private.framestack['epoch'];
    }
#
# Get where or fail
#
    private.getwhere := function() {
      if (!has_field(private.framestack, 'position') ||
	  !is_measure(private.framestack['position'])) {
	fail;
      };
      return private.framestack['position'];
    }
#
# doframe (v) specify an element of the measurement frame; v as measure
#
    const public.doframe := function(v) {
      wider private;
      doframeRec :=			[_method="doframe",
					_sequence=private.id._sequence];
      if (is_measure(v)) {
	doframeRec.val := v;
	if ((v.type == 'frequency' && (v.refer=='rest' ||
				       v.refer == 'REST')) || 
	    defaultservers.run(private.agent, doframeRec)) {
	  private.framestack[v.type] := v;
	  if (dq.testbf()) public.showframe();
	  return T;
	};
      };
      dq.errorgui('Illegal or unnecessary measure specified for frame');
      return F;
    }
#
# cometname(): get the name of the current comet name (if any)
#
    const public.cometname := function() {
      comnameRec := 			[_method="cometname",
					_sequence=private.id._sequence];
      return defaultservers.run(private.agent, comnameRec);
    }
#
# comettopo(): get the coordinates of the current comet topocentre (if any)
#
    const public.comettopo := function() {
      comtopoRec := 			[_method="comettopo",
					_sequence=private.id._sequence];
      return dq.quantity(defaultservers.run(private.agent, comtopoRec),
			 'm');
    }
#
# comettype(): get the current comet table type
#
    const public.comettype := function() {
      comtypeRec := 			[_method="comettype",
					_sequence=private.id._sequence];
      return defaultservers.run(private.agent, comtypeRec);
    }
#
# posangle(m1, m2): get position angle from direction m1 to m2
#
    const public.posangle := function(m1, m2) {
      posangleRec := 			[_method="posangle",
					_sequence=private.id._sequence];
      posangleRec.val := m1;
      posangleRec.arg := m2;
      return defaultservers.run(private.agent, posangleRec);
    }
#
# separation(m1, m2): get separation angle from direction m1 to m2
#
    const public.separation := function(m1, m2) {
      separationRec := 			[_method="separation",
					_sequence=private.id._sequence];
      separationRec.val := m1;
      separationRec.arg := m2;
      return defaultservers.run(private.agent, separationRec);
    }
#
# framecomet(v) use the table with a name v in the frame (or from aipsrc)
#
    const public.framecomet := function(v='') {
      wider private;
      framecomRec := 			[_method="framecomet",
					_sequence=private.id._sequence];
      if (is_string(v)) {
	framecomRec.val := v;
	if (defaultservers.run(private.agent, framecomRec)) {
	  private.framestack['comet'] := public.cometname();
	  if (dq.testbf()) public.showframe();
	  return T;
	};
      };
      dq.errorgui('Unknown comet table specified for frame');
      return F;
    }
#
# framenow specify a frame time of now
#
    const public.framenow := function() {
      public.doframe(public.measure(public.epoch('UTC',
						 'today'),
				    'UTC'));
      return T;
    }
#
# frameauto(v): start an automatic frame; v as quantity time
#
    const public.frameauto := function(v='2s') {
      wider private;
      if (dq.is_angle(v) && dq.compare(v, '1s')) {
	t := dq.convert(dq.quantity(v), 's').value;
	private.autotime := t;
	private.timcl := client("timer", t);
	whenever private.timcl->ready do {
	  public.doframe(public.measure(public.epoch('UTC',
						     'today'),
					'UTC'));
	  public.showauto();
	};
	return T;
      };
      return F;
    }
#
# framenoauto: stop automatic frame
#
    const public.framenoauto := function() {
      wider private;
      private.timcl := F;
      return T;
    }
#
# showframe (g) show specified frame elements on CLI or GUI
#
    const public.showframe := function(g=T) {
      if (g && has_field(private, "showframe") &&
	  is_function(private.showframe)) {
	return private.showframe(g);
      };
      if (length(private.framestack) > 0) {
	for (i in ind(private.framestack)) {
	  if (field_names(private.framestack)[i] == 'comet') {
	    print spaste(field_names(private.framestack)[i], ': ',
			 private.framestack[i]);
	  } else {
	    print spaste(field_names(private.framestack)[i], ': ',
			 public.show(private.framestack[i]));
	  };
	};
      };
      return T;
    }
#
# doshowauto (v,r,of) specify an element of the auto frame; v as measure;
# 	r as reference; of as offset
#
    const public.doshowauto := function(v, r, of=F) {
      wider private;
      if (is_measure(v)) {
	private.autostack[v.type] := [=];
	private.autostack[v.type]['ref'] := r;
	private.autostack[v.type]['oof'] := of;
	private.autostack[v.type]['meas'] := v;
	return T;
      };
      dq.errorgui('Illegal measure specified for automatic frame');
      return F;
    }
#
# showauto (g) show specified auto elements on CLI or GUI
#
    const public.showauto := function(g=T) {
      if (g && has_field(private, "showauto") &&
	  is_function(private.showauto)) {
	return private.showauto(g);
      };
      if (length(private.autostack) > 0) {
	for (i in ind(private.autostack)) {
	  cr := public.measure(private.autostack[i].meas,
			       private.autostack[i].ref,
			       off=private.autostack[i].oof);
	  if (private.autostack[i].meas.type == 'epoch') {
	    if (has_field(private.framestack, "epoch"))
	      cr := public.measure(private.framestack['epoch'],
				   private.autostack[i].ref,
				   off=private.autostack[i].oof);
	  };
	  print cr;
	};
      };
      return T;
    }
#
# Rise/set sidereal time(coord, elev)
#
    const public.rise := function(crd, ev='5deg') {
      if (!is_measure(crd)) fail('No rise/set coordinates specified');
      if (!is_measure(private.getwhere())) {
	dq.errorgui('Specify where you are in Frame');
	fail('No rise/set Frame->Where specified');
      };
      private.fillnow();
      hd := public.measure(crd, 'hadec');
      c := public.measure(crd, 'app');
      if (!is_measure(hd) || !is_measure(c)) fail('Cannot get HA for rise/set');
      ps := private.getwhere();
      ct := dq.div(dq.sub(dq.sin(ev),
			  dq.mul(dq.sin(hd.m1),
				 dq.sin(ps.m1))),
		   dq.mul(dq.cos(hd.m1), dq.cos(ps.m1)));
      if (ct.value >= 1) return "below below"; 
      if (ct.value <= -1) return "above above"; 
      a := dq.acos(ct);
      return [rise=dq.sub(dq.norm(c.m0, 0), a),
              set=dq.add(dq.norm(c.m0, 0), a)]
    }
#
# Rise/set times(coord, elev)
#
    const public.riseset := function(crd, ev='5deg') {
	a := public.rise(crd, ev);
	if (is_fail(a)) fail;
	if (is_string(a)) {
	  return [solved=F,
		 rise=[last=a[1], utc=a[1]],
		 set=[last=a[2], utc=a[2]]];
	};
	x := a;
	ofe := public.measure(private.framestack['epoch'], 'utc');
	if (!is_measure(ofe)) ofe := public.epoch('utc', 'today');
	for (i in 1:2) {
	  x[i] :=
	      public.measure(public.epoch('last',
					  dq.totime(a[i]),
					  off=public.epoch('r_utc',
							   dq.add(ofe.m0,
								  '0.5d'))),
			     'utc');
	};
	return [solved=T,
	       rise=[last=public.epoch('last', dq.totime(a[1])),
		    utc=x[1]],
	       set=[last=public.epoch('last', dq.totime(a[2])),
		   utc=x[2]]];
    }
#
# Start GUI interface method
#
# gui() start GUI interface
#
    const public.startgui := function() {
      dq.startgui();
      if (!has_field(private, "gui")) {
	  include 'measuresgui.g';
	  a := measuresgui(private, public);
      };
      return T;
    }
#
    const public.gui := function(parent=F) {
      public.startgui();
      private.gui(parent=parent);
    }
#
# Type (needed to show up in Object Catalog)
#
    const public.type := function() {
      return 'measures';
    }
#
# id() needed for toolmanager kill
#
    const public.id :=function() {
      return private.id.objectid;
    }
#
# Start other guis
#
    const public.epochgui := function(parent=F) {
      public.startgui();
      if (has_field(private, "epochgui") &&
          is_function(private.epochgui)) return private.epochgui(parent=parent);
      return F;
    }
#
    const public.positiongui := function(parent=F) {
      public.startgui();
      if (has_field(private, "positiongui") &&
          is_function(private.positiongui)) {
	return private.positiongui(parent=parent);
      };
      return F;
    }
#
    const public.directiongui := function(parent=F) {
      public.startgui();
      if (has_field(private, "directiongui") &&
          is_function(private.directiongui)) {
	return private.directiongui(parent=parent);
      };
      return F;
    }
#
    const public.frequencygui := function(parent=F) {
      public.startgui();
      if (has_field(private, "frequencygui") &&
          is_function(private.frequencygui)) {
	return private.frequencygui(parent=parent);
      };
      return F;
    }
#
    const public.dopplergui := function(parent=F) {
      public.startgui();
      if (has_field(private, "dopplergui") &&
          is_function(private.dopplergui)) {
	return private.dopplergui(parent=parent);
      };
      return F;
    }
#
    const public.radialvelocitygui := function(parent=F) {
      public.startgui();
      if (has_field(private, "radialvelocitygui") &&
          is_function(private.radialvelocitygui)) {
	return private.radialvelocitygui(parent=parent);
      };
      return F;
    }
#
# Subsidiary gui methods
#
# List frame
#
    const public.listgui := function(title='', txt='') {
      if (has_field(private, "listgui") && is_function(private.listgui)) {
	private.listgui(title, txt);
      } else {
	print txt;
      };
      return T;
    }
#
# Recalculate Radial velocity from frequency
#
    private.getrv := function(d, ref b, tp='true') {
      if (is_string(d)) {
	val b := d;
      } else {
	if (!has_field(private.framestack, 'frequency') ||
	    !is_measure(private.framestack.frequency)) {
	  dq.errorgui('No rest frequency in frame for conversion');
	  fail;
	};
	c := public.toradialvelocity(d.refer,
				     public.todoppler('beta', d,
					    private.framestack.frequency));
	if (!is_measure(c)) {
	  dq.errorgui('Error in conversion frequency to radial velocity');
	  fail;
	};
	if (tp != 'true') c := public.todoppler(tp, c);
	val b := dq.form.vel(c.m0);
      };
      return T;
    }
#
# Recalculate frequency from Radial velocity
#
    private.getfrq := function(d, ref b) {
      if (is_string(d)) {
	val b := d;
      } else {
	if (!has_field(private.framestack, 'frequency') ||
	    !is_measure(private.framestack.frequency)) {
	  dq.errorgui('No rest frequency in frame for conversion');
	  fail;
	};
	c := public.tofrequency(d.refer,
				public.todoppler('beta', d),
				private.framestack.frequency);
	if (!is_measure(c)) {
	  dq.errorgui('Error in conversion radial velocity to frequency');
	  fail;
	};
	val b := dq.form.freq(c.m0);
      };
      return T;
    }
#
# Recalculate rise/set
#
    private.getrs := function(d, ref b) {
      if (is_string(d)) {
	val b := d;
      } else {
	x := d;
	if (dq.getformat('dtime') != 'last') {
	  ofe := public.measure(private.framestack['epoch'], 'utc');
	  if (!is_measure(ofe)) ofe := public.epoch('utc', 'today');
	  ofe := ofe.m0;
	  for (i in 1:2) {
	    x[i] := public.measure(public.epoch('last',
						dq.totime(d[i]),
						off=public.epoch('r_utc',
								 ofe)),
				   'utc').m0;
	    if (dq.getformat('dtime') == 'solar') {
	      x[i] := dq.add(x[i],
			     dq.totime(private.framestack['position'].m0));
	    };
	  };
	};
	for (i in 1:2) b[i] := dq.form.dtime(x[i]);
      };
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
	    dq.delallbf(T);
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
  defaultmeasures := measures();
  const defaultmeasures := defaultmeasures;
  const dm := ref defaultmeasures;
#
# Start-up messages
#
  if (!is_boolean(dm)) {
      note('defaultmeasures (dm) ready', 
	   priority='NORMAL', origin='measures');
#
# Get default position
#
    local pos;
    if (drc.find(pos, 'measures.default.observatory')) {
      local cr := dm.observatory(pos);
      if (is_measure(cr)) {
	cr.lb := pos;
	dm.doframe(cr);
      };
    };
#
# Start up Gui if defined in .aipsrc or globally set
#
# Logics to get gui:
#	global_use_gui defined && numeric && T && have_gui()    else
#	aipsrc variable set to gui && have_gui()
    if (is_defined("global_use_gui") && is_numeric(global_use_gui)) {
      if (global_use_gui) {
	dm.gui();
      } else {
      };
    } else if (drc.find(what,"measures.default") && what == 'gui') {
      dm.gui();
    };
  };

# Add defaultmeasures to the GUI if necessary
if (any(symbol_names(is_record)=='objrepository') &&
    has_field(objrepository, 'notice')) {
	objrepository.notice('defaultmeasures', 'measures');
};
