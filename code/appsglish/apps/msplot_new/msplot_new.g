# msplot: Tool for plotting from a MeasurementSet
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
# $Id: msplot_new.g,v 1.9 2005/12/07 17:31:36 gli Exp $

if (! is_defined('msplot_g_included')) {    
    msplot_g_included := 'yes';

include "servers.g"  

######### DEBUG ###########
#defaultservers.suspend(T);
###########################

#################################################
########## Glish-bound Functions ################
#################################################

const _define_msplot := function(ref agent, id) { 
    self := [=]  
    public := [=] 

    self.agent := ref agent;
    self.id := id;    

# Select a subset of the MeasurementSet
  self.setdataRec := [_method="setdata",_sequence=self.id._sequence]
  public.setdata := function( antennaNames=[''], antennaIndex=[-1],
                              spwNames=[''], spwIndex=[-1],
			      fieldNames=[''], fieldIndex=[-1],
			      uvDists=[''], times=[''], correlations=['']) 
  {
      wider self;
      self.setdataRec.antennaNames := antennaNames;
      self.setdataRec.antennaIndex := antennaIndex;
      self.setdataRec.spwNames := spwNames;
      self.setdataRec.spwIndex := spwIndex;
      self.setdataRec.fieldNames := fieldNames;
      self.setdataRec.fieldIndex := fieldIndex;
      self.setdataRec.uvDists := uvDists;
      self.setdataRec.times := times;
      self.setdataRec.correlations := correlations;
      return defaultservers.run( self.agent, self.setdataRec );
  }
#  set the plotting axes ( X and Y ) # Give default value!!!
   self.setaxesRec := [_method="setaxes",_sequence=self.id._sequence]
   public.setaxes := function( xAxes=[''], yAxes=[''] )
   {
	wider self;
        self.setaxesRec.xAxes := xAxes;
        self.setaxesRec.yAxes := yAxes;
        return defaultservers.run( self.agent, self.setaxesRec );
   }
# set labels for the plot. # Give default labels matching the default axes!!!
    self.setlabelsRec := [_method="setlabels",_sequence=self.id._sequence]
    public.setlabels := function( poption=[nxpanels=1,nypanels=1,windowsize=6,aspectratio=0.8,plotstyle=1,plotcolour=1,fontsize=1.0], labels=['','',''] )
    {
	wider self;
        self.setlabelsRec.poption := poption;
	self.setlabelsRec.labels := labels;
        return defaultservers.run( self.agent, self.setlabelsRec );
    }
# plot the uv coverage
   self.uvcoverageRec := [_method="uvcoverage",_sequence=self.id._sequence]
   public.uvcoverage := function()
   {
	wider self;
        return defaultservers.run( self.agent, self.uvcoverageRec );
   }
# plot the antenna distribution
   self.arrayRec := [_method="array",_sequence=self.id._sequence]
   public.array := function()
   {
	wider self;
        return defaultservers.run( self.agent, self.arrayRec );
   }
# plot various quantities versus uv distance
   self.uvdistRec := [_method="uvdist",_sequence=self.id._sequence]
   public.uvdist := function( column='data', what='amp' )
   {
 	     wider self;
        self.uvdistRec.column := column;
        self.uvdistRec.what := what;
        return defaultservers.run( self.agent, self.uvdistRec );
   }
# plot various quantities( amp, phase) versus time
   self.gaintimeRec := [_method="gaintime",_sequence=self.id._sequence]
   public.gaintime := function( column='data', what='amp', iteration='' )
   {
 	     wider self;
        self.gaintimeRec.column := column;
        self.gaintimeRec.what := what;
		  self.gaintimeRec.iteration := iteration;
        return defaultservers.run( self.agent, self.gaintimeRec );
   }
# plot various quantities( amp, phase) versus channel
   self.gainchannelRec := [_method="gainchannel",_sequence=self.id._sequence]
   public.gainchannel := function( column='data', what='amp', iteration='' )
   {
 	     wider self;
        self.gainchannelRec.column := column;
        self.gainchannelRec.what := what;
		  self.gainchannelRec.iteration := iteration;
        return defaultservers.run( self.agent, self.gainchannelRec );
   }
# plot various quantities versus each other
   self.plotxyRec := [_method="plotxy",_sequence=self.id._sequence]
   public.plotxy := function( X='uvdist', Y='data', iteration='', what='amp' )
   {
 	     wider self;
        self.plotxyRec.X := X;
		  self.plotxyRec.Y := Y;
		  self.plotxyRec.iteration := iteration;
        self.plotxyRec.what := what;
        return defaultservers.run( self.agent, self.plotxyRec );
   }
# plot various quantities( amp, phase) versus baseline
   self.baselineRec := [_method="baseline",_sequence=self.id._sequence]
   public.baseline := function( column='data', what='amp' )
   {
 	     wider self;
        self.baselineRec.column := column;
        self.baselineRec.what := what;
        return defaultservers.run( self.agent, self.baselineRec );
   }
# plot various quantities( amp, phase) versus hour angle
   self.hourangleRec := [_method="hourangle",_sequence=self.id._sequence]
   public.hourangle := function( column='data', what='amp' )
   {
 	     wider self;
        self.hourangleRec.column := column;
        self.hourangleRec.what := what;
        return defaultservers.run( self.agent, self.hourangleRec );
   }
# plot various quantities( amp, phase) versus azimuth
   self.azimuthRec := [_method="azimuth",_sequence=self.id._sequence]
   public.azimuth := function( column='data', what='amp' )
   {
 	     wider self;
        self.azimuthRec.column := column;
        self.azimuthRec.what := what;
        return defaultservers.run( self.agent, self.azimuthRec );
   }
# plot various quantities( amp, phase) versus elevation
   self.elevationRec := [_method="elevation",_sequence=self.id._sequence]
   public.elevation := function( column='data', what='amp' )
   {
 	     wider self;
        self.elevationRec.column := column;
        self.elevationRec.what := what;
        return defaultservers.run( self.agent, self.elevationRec );
   }
# plot various quantities( amp, phase) versus parallactic angle
   self.parallacticangleRec := [_method="parallacticangle",_sequence=self.id._sequence]
   public.parallacticangle := function( column='data', what='amp' )
   {
 	     wider self;
        self.parallacticangleRec.column := column;
        self.parallacticangleRec.what := what;
        return defaultservers.run( self.agent, self.parallacticangleRec );
   }

# plot the data
   self.plotRec := [_method="plot",_sequence=self.id._sequence]
   public.plot := function()
   {
	wider self;
        return defaultservers.run( self.agent, self.plotRec );
   }
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
    
##    self.plotdataRec := [_method="plotdata",_sequence=self.id._sequence]
##    public.plotdata := function(poption=[nxpanels=1,nypanels=1,windowsize=6,aspectratio=0.8,plotstyle=1,plotcolour=1,fontsize=1.0],labels=[' ',' ',' '],datastr=['',''])
##    {
##        wider self
##	self.plotdataRec.poption:= poption
##	self.plotdataRec.labels:= labels
##	self.plotdataRec.datastr:= datastr
##        ret := defaultservers.run(self.agent, self.plotdataRec)
##	return ret
##    }

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

}  # _define_msplot


##########################################
#### Multiple Constructors ###############
##########################################

const msplot := function( msname=[''], host='', forcenewserver=F) {
    if( msname=='' ){
        return throw('msplot constructor requires a MeasurementSet name - see the help file');
    }
    ##print 'ms name is ', msname;
    agent := defaultservers.activate("msplot", host, forcenewserver);
    ##print 'defaultservers.activate() called.';
    id := defaultservers.create(agent, "msplot","msplot", [msName=msname]);
    ##print 'defaultservers.create() called.';
    defaultservers.suspend(F);
    ##print 'Before return _define_msplot().';
    return _define_msplot(agent,id);
} # msplot()

}  # include guard

########################################################################
