# appstate.g: Class/DO to save and restore state in Glish applications.
# Copyright (C) 1997-1998
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
# $Id: appstate.g,v 19.1 2004/08/25 01:33:38 cvsmgr Exp $

pragma include once;

include 'servers.g';

_appstate_self := [=];

const appstate := function ()
{
  global _appstate_self;
  public := [=];
  public::print.limit := 1;

  assign := function (ref out, from) { val out := from; }

  if (length (_appstate_self) == 0) {
    _appstate_self.agent := [=];
    _appstate_self.id := [=];
    assign (_appstate_self.agent, defaultservers.activate ('misc'));
    assign (_appstate_self.id, defaultservers.create (_appstate_self.agent,
						      'appstate'));
  }

  public.init := function (application)
  {
    global _appstate_self;
    rec := [_method='init', _sequence=_appstate_self.id._sequence,
	    application=application];
    return defaultservers.run (_appstate_self.agent, rec);
  }

  public.restore := function ()
  {
    global _appstate_self;
    rec := [_method='restore', _sequence=_appstate_self.id._sequence];
    return defaultservers.run (_appstate_self.agent, rec);
  }

  public.save := function ()
  {
    global _appstate_self;
    rec := [_method='save', _sequence=_appstate_self.id._sequence];
    return defaultservers.run (_appstate_self.agent, rec);
  }

  public.get := function (ref value, keyword)
  {
    global _appstate_self;
    rec := [_method='get', _sequence=_appstate_self.id._sequence,
	    keyword=keyword];
    assign (returnval, defaultservers.run (_appstate_self.agent, rec));

    if (returnval == F) {	# Didn't find it...make sure value is unset.
      val value := F;
    } else {
      val value := rec.value;
    }
    return returnval;
  }

  public.set := function (keyword, value)
  {
    global _appstate_self;
    rec := [_method='set', _sequence=_appstate_self.id._sequence,
	    keyword=keyword, value=value];
    return defaultservers.run (_appstate_self.agent, rec);
  }

  public.list := function ()
  {
    global _appstate_self;
    rec := [_method='list', _sequence=_appstate_self.id._sequence];
    return defaultservers.run (_appstate_self.agent, rec);
  }

  public.unset := function (keyword)
  {
    global _appstate_self;
    rec := [_method='unset', _sequence=_appstate_self.id._sequence,
	    keyword=keyword];
    return defaultservers.run (_appstate_self.agent, rec);
  }

  return public;
}
