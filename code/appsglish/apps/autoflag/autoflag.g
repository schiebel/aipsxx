# autoflag.g: Glish proxy for autoflag DO 
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001
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
#   $Id: autoflag.g,v 19.8 2004/09/28 22:31:03 jmcmulli Exp $

pragma include once

include "servers.g"
#
# constructor
#
const autoflag := function(msname,host='',forcenewserver=F ) {       
  public := [=]                                               
  private := [=]                                                 

# Begin definition of public data
  public.name:='autoflag';

# activate the server process
  private.agent := defaultservers.activate("autoflag", host, forcenewserver)
  private.id := defaultservers.create(private.agent,"autoflag")     
  
#-----------------------------------------------------------------------------
# Private function to convert synthesis selection strings to TAQL
#
   const private.synthselect := function (synth='') {
#
      taql := synth;
      if (strlen(synth) > 0) {
         # Check for '0-rel' or '0-REL'
         zerorel := synth ~ m/0-REL/i;
         if (zerorel) {
	    synth := synth ~ s/0-REL//gi;
         } else {
            # Check for '1-rel' or '1-REL'
            synth := synth ~ s/1-REL//gi;
            # Adjust all relevant MS/calibration indices by 1
            synth := synth ~ s/ANTENNA1/(ANTENNA1+1)/gi;
            synth := synth ~ s/ANTENNA2/(ANTENNA2+1)/gi;
            synth := synth ~ s/FEED1/(FEED1+1)/gi;
            synth := synth ~ s/FEED2/(FEED2+1)/gi;
            synth := synth ~ s/ARRAY_ID/(ARRAY_ID+1)/gi;
            synth := synth ~ s/CORRELATOR_ID/(CORRELATOR_ID+1)/gi;
            synth := synth ~ s/FIELD_ID/(FIELD_ID+1)/gi;
            synth := synth ~ s/OBSERVATION_ID/(OBSERVATION_ID+1)/gi;
            synth := synth ~ s/PULSAR_ID/(PULSAR_ID+1)/gi;
            # Temporary 10/2000; replace with DATA_DESC_ID directly for now
            synth := synth ~ s/SPECTRAL_WINDOW_ID/(DATA_DESC_ID+1)/gi;
            synth := synth ~ s/ANTENNA_ID/(ANTENNA_ID+1)/gi;
            synth := synth ~ s/ORBIT_ID/(ORBIT_ID+1)/gi;
            synth := synth ~ s/PHASED_ARRAY_ID/(PHASED_ARRAY_ID+1)/gi;
            synth := synth ~ s/FEED_ID/(FEED_ID+1)/gi;
            synth := synth ~ s/BEAM_ID/(BEAM_ID+1)/gi;
            synth := synth ~ s/PHASED_FEED_ID/(PHASED_FEED_ID+1)/gi;
            synth := synth ~ s/SOURCE_ID/(SOURCE_ID+1)/gi;
            taql := synth;
         };
      };
      return taql;
   };

#-----------------------------------------------------------------------------
# Private function to pre-process input selection strings
# 
   const private.validstring := function (inputstring) {
#
      outputstring := inputstring;
      # Guard against "" or " "
      if (shape(outputstring) == 0) {
         outputstring:= ' ';
      } else {
         # Convert Glish string arrays 
         outputstring := paste (outputstring);
         # Strip spurious start and end quotes (
         outputstring := outputstring ~ s/^'(.*)'$/$1/;
         outputstring := outputstring ~ s/^"(.*)"$/$1/;
      };
      return outputstring;
   };

#--------------------------------------------------------------------------
# do an attach call immediately
  const public.attach := function (ms) {
    wider private;
    private.msname := ms;
    rec := [_method="attach",_sequence=private.id._sequence,ms=ms];
    res := defaultservers.run(private.agent,rec);   
    if( is_fail(res) )
      fail;
  }
  if( is_fail( public.attach(msname) ) )
    fail;

# define setdata method
  const public.setdata := function (mode='none',nchan=[1],start=[1],step=[1],
                    mstart='0km/s',mstep='0km/s',spwid=[],
                    fieldid=[],msselect= ' ', async=!dowait) {
    wider private;
#    private.msname := ms;
    rec := [_method="setdata",_sequence=private.id._sequence];
    rec.mode:=mode;
    rec.nchan:=nchan;
    rec.start:=start;
    rec.step:=step;
    rec.mstart:=mstart;
    rec.mstep:=mstep;
    rec.spwid:=spwid;
    rec.fieldid:=fieldid;
    rec.msselect:=private.synthselect (private.validstring(msselect));
    res := defaultservers.run(private.agent,rec,async);   
    if( is_fail(res) )
      fail;
    return T;
  }
    
# Do a queryagents and queryoptions call immediately.
# note that defualt options are not used for now (instead, run() sets up
# the options record explicitly from its arguments). But I'll query the options
# anyway since that makes debugging easier.
  rec := [_method="queryoptions",_sequence=private.id._sequence];
  opts   := defaultservers.run(private.agent,rec);   
  if( is_fail(opts) )
    fail;
  private.defopts := opts;
# 
  rec := [_method="queryagents",_sequence=private.id._sequence];
  agents := defaultservers.run(private.agent,rec);   
  if( is_fail(agents) )
    fail;
  private.defagents := agents;
  
  private.agentlist := [=];
  
# create record for calling the run() method  
  private.runRec := [_method="run",_sequence=private.id._sequence]

#---------------
# PRIVATE METHODS
# printRecord() pretty-prints a record
# if refrec is specified, differing fields are highlighted
# 
  const private.printRecord := function(rec,refrec=F) {
    for( f in field_names(rec) ) {
      if( f!="id" && f!="name" ) {
        stat := ' ';
        sf := paste(rec[f]);
        if( is_record(refrec) ) {
          if( !has_field(refrec,f) || paste(refrec[f]) != sf )
            stat := '*';
        }
        printf('   %s%-12s= ',stat,f,sf);
        print rec[f];
      }
    }
    return T;
  }
# addAgent() adds an agent record to the list. It also does all sorts
# of sanity checks in case the set__() methods below get tangled up.
  const private.addAgent := function(id,agentrec) {
    wider private;
    # check that agent ID is known
    rec := F;
    for( id1 in field_names(private.defagents) ) {
      if( id == id1 ) {
        rec := private.defagents[id];
        break;
      }
    }
    if( is_boolean(rec) )
      fail spaste('No such method: ',id,'. Please submit a bug report.'); 
    # check that all parameters are present 
    for( p in field_names(rec) ) {
      if( p!="name" && p!="id" && !has_field(agentrec,p) )
        fail spaste('Missing parameter ',p,' for method ',id,'. Please submit a bug report.');
    }
    # check for spurious extra parameters
    for( p in field_names(agentrec) ) {
      if( !has_field(rec,p) )
        fail spaste('Unknown parameter ',p,' for method ',id,'. Please submit a bug report.');
    }
    # create record and add it to list
    nf := len(private.agentlist);
    agentrec.id := id;
    agentrec.name := rec.name;
    private.agentlist[nf+1] := agentrec;
    print sprintf('Added method %d: %s (%s)',nf+1,id,rec.name);
    private.printRecord(agentrec,refrec=rec);
    return T;
  }
#
# Define standard methods
  const public.objectName := function() { return "autoflag"; };
  const public.type       := function() { return "autoflag"; };
  const public.ok         := function() { return T;};
  const public.display    := function() { fail "not yet implemented"; };

# define detach method
  const public.detach := function () {
    wider private;
    private.msname := F;
    rec := [_method="detach",_sequence=private.id._sequence ];
    res := defaultservers.run(private.agent,rec);   
    if( is_fail(res) )
      fail;
    return res;
  }
# Define done method
  const  public.done := function()
  {
    wider private;
    wider public;
    public.detach();
    ok := defaultservers.done(private.agent,private.id.objectid);
    if( ok ) 
    {
        private := F;
        val public := F;
    }
    return ok;
  }

  const public.delete     := function() { return public.done(); }

#----------------------------------------------------------------------------
# getallmethods()
#   Returns record of available agents and their parameters
  const public.getallmethods := function() {
    wider private;
    return private.defagents;
  }
#----------------------------------------------------------------------------
# helpmethod(id) prints parameters for a particular method
  const public.help := function (...) {
    wider private;
    wider public;
    names := [];
    if( !num_args(...) ) {
      names := field_names(private.defagents);
    } else {
      for( n in 1:num_args(...) ) {
        names := [names,nth_arg(n,...)]
      }
    }
    for( id in names) {
      if( !has_field(private.defagents,id) )
        fail spaste('No such method: ',id);
      rec := private.defagents[id];
      print spaste('set',id,'() - enables method "',rec.name,'", default parameters are:');
      private.printRecord(rec);
    }
    return T;
  }
#----------------------------------------------------------------------------
# resetall() clears all methods previously set up
  const public.resetall := function () {
    wider private;
    private.agentlist := [=];
    print 'All methods reset';
    return T;
  }

#----------------------------------------------------------------------------
# reset(id) or names clears a specific method from the list (by number or ID)
  const public.reset := function (...) {
    wider private;
    if( !num_args(...) )
    {
      print 'Nothing specified so nothing was reset';
      return F;
    }
    newrec := [=];
    cleared := 0;
    for( i in (1:len(private.agentlist)) ) {
      toclear := F;
      for( j in (1:num_args(...)) ) {
        id := nth_arg(j,...);
        if( is_numeric(id) )
          toclear +:= sum(i==id);
        else
          toclear +:= sum(private.agentlist[i].id==id);
      }
      if( toclear ) {
        cleared +:= 1;
      } else {
        newrec[len(newrec)+1] := private.agentlist[i];
      }
    }
    if( cleared ) {
      print sprintf('Reset %d method(s), %d remaining',cleared,len(newrec));
      private.agentlist := newrec;
    } else {
      fail spaste('Method(s) ',...,' not found');
    }
    return T;
  }
#----------------------------------------------------------------------------
# summary()
# prints a summary of active methods
  const public.summary := function () {
    wider private;
    print "Measurement set:",private.msname;
    nf := len(field_names(private.agentlist));
    if( nf ) {
      print "Methods set up:";
      for( i in (1:nf) ) {
        rec := private.agentlist[i];
        print sprintf('%d: %s (%s):',i,rec.id,rec.name);
        private.printRecord(rec,refrec=private.defagents[rec.id]);
      }
    } else {
      print "No methods have been set up";
    }
    return T;
  }
#----------------------------------------------------------------------------
# set___() functions set up agent records  to enable a particular method
  const public.settimemed := function(
      thr=5,hw=10,rowthr=10,rowhw=6,norow=F,
      column="DATA", expr="ABS I",
      debug=F,fignore=F ) {
    wider private;
    return private.addAgent("timemed",
      [thr=thr,hw=hw,rowthr=rowthr,rowhw=rowhw,norow=norow,column=column,expr=expr,
      debug=debug,fignore=fignore]);
  }

 const public.setnewtimemed := function(
      thr=3, column="DATA", expr="ABS I",
      debug=F,fignore=F ) {
    wider private;
    return private.addAgent("newtimemed",
      [thr=thr,column=column,expr=expr,
      fignore=fignore]);
  }   

  const public.setfreqmed := function(
      thr=5,hw=10,rowthr=10,rowhw=6,norow=F,
      column="DATA", expr="ABS I",
      debug=F,fignore=F ) {
    wider private;
    return private.addAgent("freqmed",
      [thr=thr,hw=hw,rowthr=rowthr,rowhw=rowhw,norow=norow,column=column,expr=expr,
      debug=debug,fignore=fignore]);
  }
  const public.setsprej := function(
      region=F,spwid=F,fq=F,chan=F,
      ndeg=2,rowthr=5,rowhw=6,
      column="DATA",expr="ABS I",
      debug=F,fignore=F ) {
    wider private;
#    print 'spwid: ',spwid,type_name(spwid);
    return private.addAgent("sprej",[
      region=region,spwid=spwid,fq=fq,chan=chan,
      ndeg=ndeg,rowthr=rowthr,rowhw=rowhw,
      column=column,expr=expr,
      debug=debug,fignore=fignore
      ]);
  }
  const public.setuvbin := function(
      thr=0.0,minpop=0,nbins=50,plotchan=F,econoplot=T,
      column="DATA",expr="ABS I",
      fignore=F ) {
    wider private;
    return private.addAgent("uvbin",[
      thr=thr,minpop=minpop,nbins=nbins,plotchan=plotchan,econoplot=econoplot,
      column=column,expr=expr,
      fignore=fignore
      ]);
  }
  const public.setselect := function(
      spwid=F,field=F,fq=F,chan=F,corr=F,ant=F,baseline=F,timerng=F,
      autocorr=F,timeslot=F,dtime=10,quack=F,
      clip=F,flagrange=F,unflag=F) {
    wider private;
#    print 'spwid: ',spwid,type_name(spwid);
#    print 'field: ',field,type_name(field);
#    print 'ant: ',ant,type_name(ant);
#    print 'baseline: ',baseline,type_name(baseline);
    return private.addAgent("select",[
      spwid=spwid,field=field,fq=fq,chan=chan,corr=corr,ant=ant,baseline=baseline,timerng=timerng,
      autocorr=autocorr,timeslot=timeslot,dtime=dtime,quack=quack,
      clip=clip,flagrange=flagrange,unflag=unflag
      ]);
  }
  
#----------------------------------------------------------------------------
# run(agents[,globparm][,plot][,plotdev][,devfile])
#   Runs the flagger.
# agents:  record of agents to use, with their parameters
#          call agents() to obtain information on what's available
#
#  Optional arguments:
# globparm:  record of global parameters applied to all agents
# plot:      set to F to disable an on-screen report, or specify [NX,NY] sub-panels.
# plotdev:   set to F to disable a hardcopy report, or specify {NX,NY] sub-panels.
# devfile:   filename for hardcopy (can use PGPlot device names)
# trial:     T to have a trial run (flags compiled but not written out)
# reset:     T to reset all pre-existing flags

#  public.run := function(globparm=[=],plotscr=[3,3],plotdev=[3,3],
  public.run := function(globparm=[=],plotscr=F,plotdev=F,
    devfile='flagreport.ps/ps',trial=F,reset=F,assaying=F ) {
    wider private;
    if( !len(private.agentlist) )
      fail 'No flagging methods have been specified';
    if( !is_record(globparm) )
      fail 'The globparm argument must be a record';
    private.runRec["agents"] := private.agentlist;
    private.runRec["options"] := [ global=globparm,plotscr=plotscr,
             plotdev=plotdev,devfile=devfile,trial=trial,reset=reset ];
    private.runRec["assaying"] := assaying;
    # run the method
    res := defaultservers.run(private.agent, private.runRec);   
    if( assaying )
      print "<<<\n";
    if( is_fail(res) )
      fail;
    return T;
  }
# End of public functions
#------------------------------------------------------------------------
  
# Return a reference to the public interface
  return ref public;
  
}


#af:=autoflag('test.MS2');
#af.help();


