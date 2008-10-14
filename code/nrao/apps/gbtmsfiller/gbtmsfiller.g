# gbtmsfiller.g: glish closure for the gbtmsfiler DO in gbtmsfiller.cc
# Copyright (C) 1999,2001,2002,2003
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: gbtmsfiller.g,v 19.2 2006/03/09 22:01:34 bgarwood Exp $

# include guard
pragma include once
 
include "servers.g";
include "unset.g";
include "os.g";

const gbtmsfiller := function(host='', forcenewserver = F) {
    private := [=];
    public := [=];


    # fire up the server and create a filler
    private.agent := defaultservers.activate("gbtmsfiller",host,
					     forcenewserver,
					     terminateonempty=F);

    private.id := defaultservers.create(private.agent, "gbtmsfiller");

    if (!is_record(private.id)) 
	fail "gbtmsfiller: unable to start gbtmsfiller client";

    private.isattachedRec := 
	[_method="isattached", _sequence=private.id._sequence];
    public.isattached := function() {
       wider private;
       return defaultservers.run(private.agent, private.isattachedRec);
    }

    private.fillallRec := [_method="fillall", _sequence=private.id._sequence];
    public.fillall := function(async=F) {
       wider private;
       return defaultservers.run(private.agent, private.fillallRec, 
				 async);
    }

    private.fillnextRec := [_method="fillnext", _sequence=private.id._sequence];
    public.fillnext := function(async=F) {
       wider private;
       return defaultservers.run(private.agent, private.fillnextRec, async);
    }

    private.moreRec := [_method="more", _sequence=private.id._sequence];
    public.more := function() {
       wider private;
       return defaultservers.run(private.agent, private.moreRec);
    }

    private.updateRec := [_method="update", _sequence=private.id._sequence];
    public.update := function(async=F) {
       wider private;
       return defaultservers.run(private.agent, private.updateRec, async);
    }

    private.statusRec := [_method="status", _sequence=private.id._sequence];
    public.status := function() {
       wider private;
       return defaultservers.run(private.agent, private.statusRec);
    }

    private.setprojectRec := 
	[_method="setproject", _sequence=private.id._sequence];
    public.setproject := function(project) {
       wider private;
       private.setprojectRec["project"] := project;
       return defaultservers.run(private.agent, private.setprojectRec);
    }

    private.projectRec := [_method="project", _sequence=private.id._sequence];
    public.project := function() {
       wider private;
       return defaultservers.run(private.agent, private.projectRec);
    }

    private.setbackendRec := 
	[_method="setbackend", _sequence=private.id._sequence];
    public.setbackend := function(backend) {
       wider private;
       private.setbackendRec["backend"] := backend;
       return defaultservers.run(private.agent, private.setbackendRec);
    }

    private.backendRec := [_method="backend", _sequence=private.id._sequence];
    public.backend := function() {
       wider private;
       return defaultservers.run(private.agent, private.backendRec);
    }

    private.setmsdirectoryRec :=
	[_method="setmsdirectory", _sequence=private.id._sequence];
    public.setmsdirectory := function(msdirectory) {
       wider private;
       private.setmsdirectoryRec["msdirectory"] := msdirectory;
       return defaultservers.run(private.agent, private.setmsdirectoryRec);
    }

    private.msdirectoryRec := 
	[_method="msdirectory", _sequence=private.id._sequence];
    public.msdirectory := function() {
       wider private;
       return defaultservers.run(private.agent, private.msdirectoryRec);
    }

    private.setmsrootnameRec :=
	[_method="setmsrootname", _sequence=private.id._sequence];
    public.setmsrootname := function(msrootname) {
       wider private;
       private.setmsrootnameRec["msrootname"] := msrootname;
       return defaultservers.run(private.agent, private.setmsrootnameRec);
    }

    private.msrootnameRec := 
	[_method="msrootname", _sequence=private.id._sequence];
    public.msrootname := function() {
       wider private;
       return defaultservers.run(private.agent, private.msrootnameRec);
    }

    private.setmintimeRec := 
	[_method="setmintime", _sequence=private.id._sequence];
    public.setmintime := function(mintime) {
       wider private;
       private.setmintimeRec["mintime"] := mintime;
       return defaultservers.run(private.agent, private.setmintimeRec);
    }

    private.mintimeRec := [_method="mintime", _sequence=private.id._sequence];
    public.mintime := function() {
       wider private;
       return defaultservers.run(private.agent, private.mintimeRec);
    }

    private.setmaxtimeRec := 
	[_method="setmaxtime", _sequence=private.id._sequence];
    public.setmaxtime := function(maxtime) {
       wider private;
       private.setmaxtimeRec["maxtime"] := maxtime;
       return defaultservers.run(private.agent, private.setmaxtimeRec);
    }

    private.maxtimeRec := [_method="maxtime", _sequence=private.id._sequence];
    public.maxtime := function() {
       wider private;
       return defaultservers.run(private.agent, private.maxtimeRec);
    }

    private.setobjectRec := 
	[_method="setobject", _sequence=private.id._sequence];
    public.setobject := function(object) {
       wider private;
       private.setobjectRec["object"] := object;
       return defaultservers.run(private.agent, private.setobjectRec);
    }

    private.objectRec := [_method="object", _sequence=private.id._sequence];
    public.object := function() {
       wider private;
       return defaultservers.run(private.agent, private.objectRec);
    }

    private.setminscanRec := 
	[_method="setminscan", _sequence=private.id._sequence];
    public.setminscan := function(minscan) {
       wider private;
       private.setminscanRec["minscan"] := minscan;
       return defaultservers.run(private.agent, private.setminscanRec);
    }

    private.minscanRec := [_method="minscan", _sequence=private.id._sequence];
    public.minscan := function() {
       wider private;
       return defaultservers.run(private.agent, private.minscanRec);
    }

    private.setmaxscanRec := 
	[_method="setmaxscan", _sequence=private.id._sequence];
    public.setmaxscan := function(maxscan) {
       wider private;
       private.setmaxscanRec["maxscan"] := maxscan;
       return defaultservers.run(private.agent, private.setmaxscanRec);
    }

    private.maxscanRec := [_method="maxscan", _sequence=private.id._sequence];
    public.maxscan := function() {
       wider private;
       return defaultservers.run(private.agent, private.maxscanRec);
    }

    private.setfillrawpointingRec := 
	[_method="setfillrawpointing", _sequence=private.id._sequence];
    public.setfillrawpointing := function(fillrawpointing) {
       wider private;
       private.setfillrawpointingRec["fillrawpointing"] := fillrawpointing;
       return defaultservers.run(private.agent, private.setfillrawpointingRec);
    }

    private.fillrawpointingRec := [_method="fillrawpointing", _sequence=private.id._sequence];
    public.fillrawpointing := function() {
       wider private;
       return defaultservers.run(private.agent, private.fillrawpointingRec);
    }

    private.setfillrawfocusRec := 
	[_method="setfillrawfocus", _sequence=private.id._sequence];
    public.setfillrawfocus := function(fillrawfocus) {
       wider private;
       private.setfillrawfocusRec["fillrawfocus"] := fillrawfocus;
       return defaultservers.run(private.agent, private.setfillrawfocusRec);
    }

    private.fillrawfocusRec := [_method="fillrawfocus", _sequence=private.id._sequence];
    public.fillrawfocus := function() {
       wider private;
       return defaultservers.run(private.agent, private.fillrawfocusRec);
    }

    private.setfilllagsRec := 
	[_method="setfilllags", _sequence=private.id._sequence];
    public.setfilllags := function(filllags) {
       wider private;
       private.setfilllagsRec["filllags"] := filllags;
       return defaultservers.run(private.agent, private.setfilllagsRec);
    }

    private.filllagsRec := [_method="filllags", _sequence=private.id._sequence];
    public.filllags := function() {
       wider private;
       return defaultservers.run(private.agent, private.filllagsRec);
    }

    private.setvvRec := 
	[_method="setvv", _sequence=private.id._sequence];
    public.setvv := function(vv) {
       wider private;
       private.setvvRec["vv"] := vv;
       return defaultservers.run(private.agent, private.setvvRec);
    }

    private.vvRec := [_method="vv", _sequence=private.id._sequence];
    public.vv := function() {
       wider private;
       return defaultservers.run(private.agent, private.vvRec);
    }

    private.setsmoothRec := 
	[_method="setsmooth", _sequence=private.id._sequence];
    public.setsmooth := function(smooth) {
       wider private;
       private.setsmoothRec["smooth"] := smooth;
       return defaultservers.run(private.agent, private.setsmoothRec);
    }

    private.smoothRec := [_method="smooth", _sequence=private.id._sequence];
    public.smooth := function() {
       wider private;
       return defaultservers.run(private.agent, private.smoothRec);
    }

    private.setusehighcalRec := 
	[_method="setusehighcal", _sequence=private.id._sequence];
    public.setusehighcal := function(usehighcal) {
       wider private;
       private.setusehighcalRec["usehighcal"] := usehighcal;
       return defaultservers.run(private.agent, private.setusehighcalRec);
    }

    private.usehighcalRec := [_method="usehighcal", _sequence=private.id._sequence];
    public.usehighcal := function() {
       wider private;
       return defaultservers.run(private.agent, private.usehighcalRec);
    }

    private.setcompresscalcolsRec := 
	[_method="setcompresscalcols", _sequence=private.id._sequence];
    public.setcompresscalcols := function(compresscalcols) {
       wider private;
       private.setcompresscalcolsRec["compresscalcols"] := compresscalcols;
       return defaultservers.run(private.agent, private.setcompresscalcolsRec);
    }

    private.compresscalcolsRec := [_method="compresscalcols", _sequence=private.id._sequence];
    public.compresscalcols := function() {
       wider private;
       return defaultservers.run(private.agent, private.compresscalcolsRec);
    }

    private.setusebiasRec := 
	[_method="setusebias", _sequence=private.id._sequence];
    public.setusebias := function(usebias) {
       wider private;
       private.setusebiasRec["usebias"] := usebias;
       return defaultservers.run(private.agent, private.setusebiasRec);
    }

    private.usebiasRec := [_method="usebias", _sequence=private.id._sequence];
    public.usebias := function() {
       wider private;
       return defaultservers.run(private.agent, private.usebiasRec);
    }

    private.setoneacsmsRec := 
	[_method="setoneacsms", _sequence=private.id._sequence];
    public.setoneacsms := function(oneacsms) {
       wider private;
       private.setoneacsmsRec["oneacsms"] := oneacsms;
       return defaultservers.run(private.agent, private.setoneacsmsRec);
    }

    private.oneacsmsRec := [_method="oneacsms", _sequence=private.id._sequence];
    public.oneacsms := function() {
       wider private;
       return defaultservers.run(private.agent, private.oneacsmsRec);
    }

    private.setdcbiasRec :=
	[_method="setdcbias", _sequence=private.id._sequence];
    public.setdcbias := function(dcbias) {
	wider private;
	private.setdcbiasRec["dcbias"] := dcbias;
	return defaultservers.run(private.agent, private.setdcbiasRec);
    }

    private.dcbiasRec := [_method="dcbias", _sequence=private.id._sequence];
    public.dcbias := function(dcbias) {
	wider private;
	return defaultservers.run(private.agent, private.dcbiasRec);
    }

    private.setminbiasfactorRec :=
	[_method="setminbiasfactor", _sequence=private.id._sequence];
    public.setminbiasfactor := function(minbiasfactor) {
	wider private;
	private.setminbiasfactorRec["minbiasfactor"] := minbiasfactor;
	return defaultservers.run(private.agent, private.setminbiasfactorRec);
    }

    private.minbiasfactorRec := [_method="minbiasfactor", _sequence=private.id._sequence];
    public.minbiasfactor := function(minbiasfactor) {
	wider private;
	return defaultservers.run(private.agent, private.minbiasfactorRec);
    }

    private.setfixlagsRec := 
	[_method="setfixlags", _sequence=private.id._sequence];
    public.setfixlags := function(fixlags) {
       wider private;
       private.setfixlagsRec["fixlags"] := fixlags;
       return defaultservers.run(private.agent, private.setfixlagsRec);
    }

    private.fixlagsRec := [_method="fixlags", _sequence=private.id._sequence];
    public.fixlags := function() {
       wider private;
       return defaultservers.run(private.agent, private.fixlagsRec);
    }

    private.newmsRec := [_method="newms", _sequence=private.id._sequence];
    public.newms := function() {
       wider private;
       return defaultservers.run(private.agent, private.newmsRec);
    }

    public.done := function()
    {
	wider private, public;
	# notify the GUI that we're finishing up
	if (is_agent(public.gui)) public.gui->done();	
	ok := defaultservers.done(private.agent, private.id.objectid);
	if (ok) {
	    val private := F;
	    val public := F;
	}
	return ok;
    }

    public.type := function() { return 'gbtmsfiller';}

    return ref public;
}

# start up the server when this script is included by starting and
# immediately deleting a gbtmsfiller object.
gbtmsfiller().done();


