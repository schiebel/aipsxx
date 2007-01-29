# aipsrc.g: interact with the aipsrc DO to get aipsrc values
#
#   Copyright (C) 1996,1997,1998,1999,2001,2002
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
#   $Id: aipsrc.g,v 19.1 2004/08/25 01:33:03 cvsmgr Exp $
#
pragma include once;

include 'note.g';

#
##defaultservers.trace(T)
##defaultservers.suspend(T)

#  ok := aipsrc.find(value, keyword, usehome=T)   # Lookup an aipsrc value
#  ok := aipsrc.init()                            # Reread the .aipsrc files

#
# Server
#
const aipsrc := function(host='', forcenewserver=F) {
  
  public := [=];
  public::print.limit := 1;
  
  private := [=];
  
  private.agent := [=];
  private.id := [=];
  
  include "servers.g";
  
  private.agent := defaultservers.activate("misc", host, forcenewserver);
  if (is_fail(private.agent)) {
    print "Server misc not running: exiting AIPS++ immediately";
    exit(1);
  }
  private.id := defaultservers.create(private.agent, "aipsrc");
  if (is_fail(private.id)) {
    print "Server misc not running: exiting AIPS++ immediately";
    exit(1);
  }
  private.iamdefault := T;
  if (is_defined('drc') && is_function(drc.id) && is_function(drc.done)) {
    private.iamdefault := F;
  };
  
#
# Public methods
#
# find (value, keyword, def=F, usehome=T)
#
  const public.find := function(ref value, keyword, def=F, usehome=T) {
    wider private;
    if (is_string(def)) {
      rec := [_method="finddef", _sequence=private.id._sequence,
	      keyword=keyword, def=def, usehome=usehome];
    } else {
      rec := [_method="find", _sequence=private.id._sequence,
	      keyword=keyword, usehome=usehome];
    };
    returnval := defaultservers.run(private.agent, rec);
    val value := rec.value;
    return returnval;
  };
#
# findbool(value, keyword, def=T)
#
  const public.findbool := function(ref value, keyword, def=F) {
    wider private;
    rec := [_method="findbool", _sequence=private.id._sequence,
	    keyword=keyword, def=def];
    returnval := defaultservers.run(private.agent, rec);
    val value := rec.value;
    return returnval;
  };
#
# findint(value, keyword, def=0, undef=F, unres=f)
#
  const public.findint := function(ref value, keyword, def=0,
				   undef=F, unres=F) {
    wider private;
    if (is_string(undef) || is_string(unres)) {
      if (!is_string(undef)) undef := ' ';
      if (!is_string(unres)) unres := ' ';
      rec := [_method="findxint", _sequence=private.id._sequence,
	      keyword=keyword, def=def, undef=undef, unres=unres];
    } else {
      rec := [_method="findint", _sequence=private.id._sequence,
	      keyword=keyword, def=def];
    };
    returnval := defaultservers.run(private.agent, rec);
    val value := rec.value;
    return returnval;
  };
#
# findfloat(value, keyword, def=0, undef=F, unres=f)
#
  const public.findfloat := function(ref value, keyword, def=0,
				     undef=F, unres=F) {
    wider private;
    if (is_string(undef) || is_string(unres)) {
      if (!is_string(undef)) undef := ' ';
      if (!is_string(unres)) unres := ' ';
      rec := [_method="findxfloat", _sequence=private.id._sequence,
	      keyword=keyword, def=def, undef=undef, unres=unres];
    } else {
      rec := [_method="findfloat", _sequence=private.id._sequence,
	      keyword=keyword, def=def];
    };
    returnval := defaultservers.run(private.agent, rec);
    val value := rec.value;
    return returnval;
  };
#
# findlist(value, keyword, vlist, def="")
#
  const public.findlist := function(ref value, keyword, vlist, def='') {
    wider private;
    rec := [_method="findlist", _sequence=private.id._sequence,
	    keyword=keyword, def=def, unres=vlist];
    returnval := defaultservers.run(private.agent, rec);
    val value := rec.value;
    return returnval;
  };
#
# init()
#
  const public.init := function() {
    wider private;
    rec := [_method="init", _sequence=private.id._sequence];
    return defaultservers.run(private.agent, rec);
  };
#
# aipsroot()
#
  const public.aipsroot := function() {
    wider private;
    rec := [_method="aipsroot", _sequence=private.id._sequence];
    return defaultservers.run(private.agent, rec);
  };
#
# aipsarch()
#
  const public.aipsarch := function() {
    wider private;
    rec := [_method="aipsarch", _sequence=private.id._sequence];
    return defaultservers.run(private.agent, rec);
  };
#
# aipssite()
#
  const public.aipssite := function() {
    wider private;
    rec := [_method="aipssite", _sequence=private.id._sequence];
    return defaultservers.run(private.agent, rec);
  };
#
# aipshost()
#
  const public.aipshost := function() {
    wider private;
    rec := [_method="aipshost", _sequence=private.id._sequence];
    return defaultservers.run(private.agent, rec);
  };
#
# aipshome()
#
  const public.aipshome := function() {
    wider private;
    rec := [_method="aipshome", _sequence=private.id._sequence];
    return defaultservers.run(private.agent, rec);
  };
#
# tzoffset()
#
  const public.tzoffset := function() {
    wider private;
    rec := [_method="tzoffset", _sequence=private.id._sequence];
    return defaultservers.run(private.agent, rec);
  };
  
  const public.ready := function() {
    wider private;
    if(is_record(private)&&has_field(private, 'agent')&&
       is_agent(private.agent)&&has_field(private, 'id')&&
       has_field(private.id, '_sequence')) {
      return T;
    }
    else {
      return F;
    }
  }
#
# Type (needed to show up in Object Catalog)
#
  const public.type := function() {
    return 'aipsrc';
  }
#
# id() needed for toolmanager kill
#
  const public.id := function() {
    return private.id.objectid;
  }
#
# done()
#
  const public.done := function(kill=F) {
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
# Ready
#
  return ref public;

}	# constructor

const defaultaipsrc := const aipsrc();
const drc := ref defaultaipsrc;
const aipsrcbase := aipsrc;		# for legacy reasons
note('defaultaipsrc (drc) ready', priority='NORMAL', origin='aipsrc');
