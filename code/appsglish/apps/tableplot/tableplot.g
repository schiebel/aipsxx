# tableplot: Tool for plotting from a 
# Copyright (C) 1995,1996,1997,1998,1999,2000,2001,2002,2003
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
# $Id: tableplot.g,v 1.4 2005/12/09 19:06:44 rurvashi Exp $

if (! is_defined('tableplot_g_included')) {    
    tableplot_g_included := 'yes';

include "servers.g"  

######### DEBUG ###########
#defaultservers.suspend(T);
###########################

#################################################
########## Glish-bound Functions ################
#################################################

const _define_tableplot := function(ref agent, id) { 
    self := [=]  
    public := [=] 

    self.agent := ref agent;
    self.id := id;
    
    self.plotoption.nxpanels := 1;
    self.plotoption.nypanels := 1;
    self.plotoption.windowsize := 6;
    self.plotoption.aspectratio := 0.8;
    self.plotoption.plotstyle := 1;
    self.plotoption.plotcolour := 2;
    self.plotoption.fontsize := 1.0;


# Select a (set of) subtables to operate on.
    
    self.selectdataRec := [_method="selectdata",_sequence=self.id._sequence]
    public.selectdata := function(tabnames=[''],sel=0) 
    {
        wider self
	self.selectdataRec.tabnames := tabnames
	self.selectdataRec.sel := sel
        ret := defaultservers.run(self.agent, self.selectdataRec)
	return ret
    }

# Name a list of tables to operate on
    
    self.settablesRec := [_method="settables",_sequence=self.id._sequence]
    public.settables := function(tabnames=['']) 
    {
        wider self
	self.settablesRec.tabnames := tabnames
        ret := defaultservers.run(self.agent, self.settablesRec)
	return ret
    }

# Plot data specified by TaQL expressions
    
    self.plotdataRec := [_method="plotdata",_sequence=self.id._sequence]
    public.plotdata := function(poption=[nxpanels=1,nypanels=1,windowsize=6,aspectratio=0.8,plotstyle=1,plotcolour=1,fontsize=1.0],labels=[' ',' ',' '],datastr=['',''])
    {
        wider self
	self.plotdataRec.poption:= poption
	self.plotdataRec.labels:= labels
	self.plotdataRec.datastr:= datastr
        ret := defaultservers.run(self.agent, self.plotdataRec)
	return ret
    }

# Mark a flag region on a plot panel
    
    self.markflagsRec := [_method="markflags",_sequence=self.id._sequence]
    public.markflags := function(panel=1) 
    {
        wider self
	self.markflagsRec.panel:= panel
        ret := defaultservers.run(self.agent, self.markflagsRec)
	return ret
    }

#Zoom on a plot panel
    
    self.zoomplotRec := [_method="zoomplot",_sequence=self.id._sequence]
    public.zoomplot := function(panel=1,direction=1) 
    {
        wider self
	self.zoomplotRec.panel:= panel
	self.zoomplotRec.direction:= direction
        ret := defaultservers.run(self.agent, self.zoomplotRec)
	return ret
    }

# Flag data corresponding to marked flag regions
    
    self.flagdataRec := [_method="flagdata",_sequence=self.id._sequence]
    public.flagdata := function(diskwrite=0,rowflag=0) 
    {
        wider self
	self.flagdataRec.diskwrite:= diskwrite
	self.flagdataRec.rowflag:= rowflag
        ret := defaultservers.run(self.agent, self.flagdataRec)
	return ret
    }

# Un-Flag data corresponding to marked flag regions
    
    self.unflagdataRec := [_method="unflagdata",_sequence=self.id._sequence]
    public.unflagdata := function(diskwrite=0,rowflag=0) 
    {
        wider self
	self.unflagdataRec.diskwrite:= diskwrite
	self.unflagdataRec.rowflag:= rowflag
        ret := defaultservers.run(self.agent, self.unflagdataRec)
	return ret
    }

# Clear all flags
    
    self.clearflagsRec := [_method="clearflags",_sequence=self.id._sequence]
    public.clearflags := function() 
    {
        wider self
        ret := defaultservers.run(self.agent, self.clearflagsRec)
	return ret
    }

# Start plot iterations
    
    self.iterplotstartRec := [_method="iterplotstart",_sequence=self.id._sequence]
    public.iterplotstart := function(poption=[nxpanels=1,nypanels=1,windowsize=6,aspectratio=0.8,plotstyle=1,plotcolour=1,fontsize=1.0],labels=[' ',' ',' '],datastr=['',''],iteraxes=['']) 
    {
        wider self
	self.iterplotstartRec.poption:= poption
	self.iterplotstartRec.labels:= labels
	self.iterplotstartRec.datastr:= datastr
	self.iterplotstartRec.iteraxes:= iteraxes
        ret := defaultservers.run(self.agent, self.iterplotstartRec)
	return ret
    }

#Advance to next set of panels
    
    self.iterplotnextRec := [_method="iterplotnext",_sequence=self.id._sequence]
    public.iterplotnext := function() 
    {
        wider self
        ret := defaultservers.run(self.agent, self.iterplotnextRec)
	return ret
    }
    
#Stop iterations
    
    self.iterplotstopRec := [_method="iterplotstop",_sequence=self.id._sequence]
    public.iterplotstop := function() 
    {
        wider self
        ret := defaultservers.run(self.agent, self.iterplotstopRec)
	return ret
    }
    
    public.id := function(){
        wider self;
	return self.id.objectid;
    }

    public.done := function()
    {
        wider self, public;
        ok := defaultservers.done(self.agent, public.id());
        if (ok) {
            self := F;
            val public := F;
        }
        return ok;
    }

    return public

}  # _define_tableplot


##########################################
#### Multiple Constructors ###############
##########################################

const tableplot := function(host='', forcenewserver=F) {
    agent := defaultservers.activate("tableplot", host, forcenewserver)
    id := defaultservers.create(agent, "tableplot","tableplot");
    defaultservers.suspend(F);
    return _define_tableplot(agent,id);
} # tableplot()

#const tableplot := function(msname=0,host='', forcenewserver=F) {
#    agent := defaultservers.activate("newtableplot", host, forcenewserver)
#    id := defaultservers.create(agent, "tableplot","tableplot",[msname=msname]);
#    defaultservers.suspend(F);
#    return _define_tableplot(agent,id);
#} # tableplot()



}  # include guard

########################################################################
