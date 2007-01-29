# wnbt.g: Access to wnbt classes
# Copyright (C) 2000
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
# $Id: wnbt.g,v 19.2 2004/08/25 01:57:26 cvsmgr Exp $
#
pragma include once

  incok := include "servers.g";
  incok := include "note.g";
#
##defaultservers.trace(T)
##defaultservers.suspend(T)
#
# Global methods
#
#
# Server
#
  const wnbt := function(host='', forcenewserver = F) {
    global system;
    private := [=];
    public := [=];
    public::print.limit := 1;
    private.agent := defaultservers.activate("wnbt", host,
					     forcenewserver);

    if (is_fail(private.agent)) return F;
    private.id := defaultservers.create(private.agent, "wnbt");
    if (!has_field(system, 'print')) system.print := [=];
    system.print.precision := 6;
#
# Public methods
#
    const public.type := function() {
      return 'wnbt';
    }
    const public.done := function() {
      wider private, public;
      ok := defaultservers.done(private.agent, private.id);
      if (is_fail(ok)) fail;
#
      if (ok) {
	val private := F;
	val public := F;
      }
      return ok;
    }
#
# imop(infile) -> open image v
#
    const public.imop := function(infile) {
      imopR :=		[_method="imageop",
			_sequence=private.id._sequence];
      imopR["val"] := infile;
      return defaultservers.run(private.agent, imopR);
    }
#
# imcl() -> close image
#
    const public.imcl := function() {
      imclR :=		[_method="imagecl",
			_sequence=private.id._sequence];
      return defaultservers.run(private.agent, imclR);
    }
#
# imph() -> Print image header
#
    const public.imph := function() {
      imphR :=		[_method="imageph",
			_sequence=private.id._sequence];
      return defaultservers.run(private.agent, imphR);
    }
#
# imel(x) -> show element
#
    const public.imel := function(index=[0,0,0,0]) {
      imelR :=		[_method="imageel",
			_sequence=private.id._sequence];
      imelR["arg"] := index;
      return defaultservers.run(private.agent, imelR);
    }
#
# imfd(n, maplim, afind) -> find a maximum of N sources up to maplim*highest
#			find highest absolute if afind true, else only pos
#			sources. Returns a 2d array of ampl, x, y pixels.
#
    const public.imfd := function(number=20, maplim=0.1, afind=F) {
      imfdR :=		[_method="imagefd",
			_sequence=private.id._sequence];
      imfdR['val'] := number;
      imfdR['form'] := maplim;
      imfdR['form2'] := afind;
      return defaultservers.run(private.agent, imfdR);
    }
#
# compdef(comp list): define a component update object for a component list
#
    const public.compdef := function(compl) {
      codfR :=          [_method="compdef",
			_sequence=private.id._sequence];
      codfR['val'] := compl;
      return defaultservers.run(private.agent, codfR);      
    }
#
# comprem: remove a component update object for a component list
#
    const public.comprem := function(compl) {
      cormR :=          [_method="comprem",
			_sequence=private.id._sequence];
      return defaultservers.run(private.agent, cormR);      
    }
#
# compmak: Use data and derivatives to create normal equations
# deriv is [3, nmodel, nuv]; data is [nuv]. Both complex doubles
#
    const public.compmak := function(deriv, dat) {
      comkR :=          [_method="compmak",
			_sequence=private.id._sequence];
      comk['val'] := deriv;
      comk['arg'] := dat;
      return defaultservers.run(private.agent, comkR);      
    }
#
# compsol: solve the update equations. Returned are the solutions and their
# errors as [3, nmodel] matrices of doubles
#
    const public.compsol := function(ref sol, ref err) {
      coslR :=          [_method="compsol",
			_sequence=private.id._sequence];
      cosl['val'] := sol;
      cosl['arg'] := err;
      defaultservers.run(private.agent, coslR); 
      val sol :=  cosl['val'];
      val err :=  cosl['arg'];
      return T;
    }
#
# compsol: solve the update equations. Returned are the solutions and their
# errors as [3, nmodel] matrices of doubles
#
#
# End server constructor
#
    return ref public;

  } # constructor
#
# Create a defaultserver
#
defaultwnbt := wnbt();
const defaultwnbt := defaultwnbt;
const wnb := ref defaultwnbt;
#
# Start-up messages
#
if (!is_boolean(wnb)) {
  note('defaultwnbt (wnb) ready', 
       priority='NORMAL', origin='wnbt');
};
#
# Add defaultwnbt to the GUI if necessary
#
if (any(symbol_names(is_record)=='objrepository') &&
    has_field(objrepository, 'notice')) {
  objrepository.notice('defaultwnbt', 'wnbt');
};
