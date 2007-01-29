# sysinfo.g: Startup script for sysinfo DO servers
#
#   Copyright (C) 1996,1997,2000
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
#   $Id: sysinfo.g,v 19.1 2004/08/25 01:35:21 cvsmgr Exp $
#
pragma include once

include "servers.g";

#defaultservers.suspend(T)

#info := sysinfo()
#   n := info.numcpu()                         # #CPU's
#   n := info.memory()                         # Memory in MB
#
#
#                                              # Version information
#                                              # all except dolog are ouput
#        info.version(major,minor,patch,date,info,formatted,dolog)
#   a := info.arch()                           # Architecture

# Nobody will want to have multiple sysinfo's around, so always return
# a global one.
_sysinfo_self := [=]

const sysinfo := function()
{
    global _sysinfo_self
    public := [=];
    public::print.limit := 1;

    assign := function(ref out, from) {val out := from;}

    if (length(_sysinfo_self) == 0) {
        _sysinfo_self.agent := [=]
        _sysinfo_self.id := [=]
	assign(_sysinfo_self.agent, defaultservers.activate("misc"))
        assign(_sysinfo_self.id,
		defaultservers.create(_sysinfo_self.agent, "sysinfo"))
    }

    public.numcpu := function()
    {
	global _sysinfo_self
        rec := [_method="numcpu", _sequence=_sysinfo_self.id._sequence]
        return defaultservers.run(_sysinfo_self.agent, rec);
    }

    public.memory := function()
    {
	global _sysinfo_self
        rec := [_method="memory", _sequence=_sysinfo_self.id._sequence]
        return defaultservers.run(_sysinfo_self.agent, rec);
    }

    public.version := function(ref major=F,ref minor=F, ref patch=F,
			ref date=F, ref info=F, ref formatted=F, dolog=T)
    {
	global _sysinfo_self
        rec := [_method="version", _sequence=_sysinfo_self.id._sequence]
        rec.dolog := dolog
        returnval := defaultservers.run(_sysinfo_self.agent, rec);
        val major := rec.major
        val minor := rec.minor
        val patch := rec.patch
        val date := rec.date
        val info := rec.info
        val formatted := rec.formatted
        return returnval
    }

    public.arch := function()
    {
	global _sysinfo_self
        rec := [_method="arch", _sequence=_sysinfo_self.id._sequence]
        return defaultservers.run(_sysinfo_self.agent, rec);
    }

    public.root := function()
    {
	global _sysinfo_self
        rec := [_method="root", _sequence=_sysinfo_self.id._sequence]
        return defaultservers.run(_sysinfo_self.agent, rec);
    }

    public.site := function()
    {
	global _sysinfo_self
        rec := [_method="site", _sequence=_sysinfo_self.id._sequence]
        return defaultservers.run(_sysinfo_self.agent, rec);
    }

    public.host := function()
    {
	global _sysinfo_self
        rec := [_method="host", _sequence=_sysinfo_self.id._sequence]
        return defaultservers.run(_sysinfo_self.agent, rec);
    }

    public.type := function() 
    {
      return 'sysinfo';
    }

    return public
}
