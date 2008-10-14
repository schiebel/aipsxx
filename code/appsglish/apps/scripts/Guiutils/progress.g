# progress.g: Provide visual indication of the progress of some task
# Copyright (C) 1997,1998,1999,2001,2002,2003
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
# $Id: progress.g,v 19.2 2004/08/25 02:01:31 cvsmgr Exp $

pragma include once;
include 'timer.g';
include 'note.g'
include 'widgetserver.g'


# result := choice(description,choices,interactive=have_gui(),timeout=30)

# bar := progress(min, max, title="", minlabel="", maxlabel="",
#                 estimate_time=T, barwidth=200, barhight=20, startopen=5)
# frac := bar.update(value, autodisable=T)
# bar.activate()
# bar.deactivate()

# We attach the dismiss button to a frame that can be dismissed but
# deleted

progressmeters := function() {
  priv := [=];
  priv.count := 0;
  public := [=];

  if (!have_gui()) {
# Don't print this warning because progressmeters are not important for computation.
# If there is no GUI, no progress meter will show.
#      note('No GUI is available - cannot create progress meter. Possibly the DISPLAY environment variable is not set',
#           priority='WARN', origin='progressmeters.g');
     return F;
  }

  tk_hold();  
  priv.topframe := dws.frame(title='Progress meters (AIPS++)', side='top',
			 width=300, height=30);
  priv.topframe->unmap();
  priv.showMe := T;
  tk_release();
  
  priv.frame := dws.frame(priv.topframe, side='top');
  priv.nometers := dws.frame(priv.frame, width=200);
  priv.nometersLabe := dws.label(priv.nometers,
                                 text='All quiet: no tools reporting activity');
  
  # priv.dismissframe
  priv.dismissframe := dws.frame(priv.topframe,side='right');
  priv.dismissbutton := dws.button(priv.dismissframe, 'Dismiss',
                                   type='dismiss');
  whenever priv.dismissbutton->press do {
    priv.topframe->unmap();
  }
  
  public.frame := function () {
    wider priv;
    priv.count +:= 1;
    if(priv.showMe){
       priv.topframe->map();
       priv.showMe := F;
    }
    if(priv.count == 1)
       priv.nometers->unmap();
    return ref priv.frame;
  }
  
  public.gui := function () {wider priv; priv.topframe->map();};
  public.map := function () {wider priv; priv.topframe->map();};
  public.unmap := function () {wider priv; priv.topframe->unmap();};
  public.rmframe := function () {wider priv;
                                 priv.count -:= 1;
                                 if(priv.count < 0)
                                     priv.count := 0;
                                 else if (priv.count == 0)
                                    priv.nometers->map();
                                 };

  # Need this to show up in the toolmanager  
  public.type := function() {return 'progressmeters'};

  # Done is a no-op
  public.done := function() {
    return F;
  }

  priv.topframe->unmap();
  return ref public;
  
}

# 
# This line may give a F if !have_gui().  But since
# progress will not access progressmeters() if this is the
# case, and will result in no ops, don't do anything about it
#
const progressmeters := progressmeters();

const progress := function(min, max, title="", subtitle="", minlabel="",
			   maxlabel="", estimate_time=T, barwidth=200,
			   barheight=20, startopen=1.5, showtext=T,
			   parent=F)
{
  self := [=];
  public := [=];
  self.busy:=F;
  self.parent := parent;
  self.showtext := showtext;
  self.initDone := F;
  self.shoulddie := F;
  
  include 'aipsrc.g';

  drc.findbool (self.show, 'progress.show', T);

  # Gui guard
  if(have_gui()&&self.show) {
    self.cache.percent := -99;
    self.cache.remaining := -99;
    self.cache.total := -99;
 
    if(!is_agent(self.parent)) {
      # Make progress frame with global scope.  
      if(!is_defined('progressmeters')) {
	eval('const progressmeters := progressmeters();');
      }
    }
    
    # Validate arguments
    if (!is_string(title) || length(title) != 1 || title=='') {
      title:= 'Progress Meter (AIPS++)';
    }
    self.title := title;
	
    if (!is_numeric(min) || !is_numeric(max)) {
      return throw('min and max must be numbers', origin='progress.g');
    }
    # Do sensible things if min/max aren't really min and max
    if(min == max) 
	return;
    else if(min > max)
	return throw('min must be less than max', origin='progress.g');
	    
    self.min := min;
    self.max := max;
	
    if (!is_string(minlabel) || length(minlabel)==0 || minlabel=='') {
      minlabel := as_string(self.min);
    }
    self.minlabel := minlabel;
	
    if (!is_string(maxlabel) || length(maxlabel)==0 || maxlabel=='') {
      maxlabel := as_string(self.max);
    }
    self.maxlabel := maxlabel;
	
    self.estimate_time := estimate_time;
	    
    self.width := barwidth;
    self.height := barheight;
    if (! is_numeric(self.width)) self.width := 200;
    if (! is_numeric(self.height)) self.height := 20;
			    
			    
    self.init := function()
    {
      wider self;
				  
      if(has_field(self, 'frame') && is_agent(self.frame))
         return T;
      self.frame := F;
      if (! have_gui()) return F;
					  
      self.initDone := F;

      # self.frame
      dws.tk_hold();
      if(is_agent(self.parent)) {
	self.frame := dws.frame(self.parent, relief='raised');
      }
      else {
	self.frame := dws.frame(progressmeters.frame(), title=self.title,
				relief='raised');
      }
      if ( ! is_agent(self.frame) )
	  fail 'progress.init: frame creation failed';
				      
      self.titlelabel := dws.label(self.frame, self.title, justify='center');
					  
      # self.barframe
      self.barframe := dws.frame(self.frame, side='left');
					      
      # self.leftlabel
      if(self.showtext) self.leftlabel := dws.label(self.barframe, self.minlabel);
						  
      # self.barholder
      self.barholder := dws.canvas(self.barframe, width=self.width,
			       height=self.height,
			       background='pink',fill='none');
						      
      # self.rightlabel
      if(self.showtext) self.rightlabel := dws.label(self.barframe, self.maxlabel);
							  
      # self.statuslabel
      if(self.showtext) self.statuslabel :=
	  dws.label(self.frame, '[0%]', justify='center');
      dws.tk_release();
      self.initDone := T;
      return T;
    }
    
    
    public.update := function(value,autodisable=T)
    {
      wider public;
      wider self;

      # Allow reentrancy enough to determine if the widget should die

      frac := (value - self.min)/(self.max - self.min);
      if (frac < 0) frac := 0;
      if (frac > 1) frac := 1;
			      
      if (frac >= 0.999999 && autodisable) {
	self.shoulddie:=T;
      }
      # Now if we are busy, return. We know that when possible we should die
      if(self.busy) return 0;

      if(self.shoulddie) {
	public.deactivate();
	return 0;
      }
      
      self.busy:=T
      self.lastvalue := value;
		  
      if (!has_field(self, 'frame') || !is_agent(self.frame) || !self.initDone){
	self.busy:=F;
	return frac;
      }
	  
      percent := as_integer((frac+0.005)*100);
      # Suppose the remaining fraction computes at the same rate
      # as the fraction to date
      tdiff := time() - self.tstart;;
      remaining := as_integer(tdiff*(1-frac)/frac);
      total := as_integer(tdiff + remaining);
	      
      # Only update the bar if it has changed by one percent or if the
      # time estimate has changed. This is for efficiency so we don't
      # send lots of updates if things in fact have not changed very
      # much
      if (percent != self.cache.percent || 
	  (self.estimate_time && remaining != self.cache.remaining)) {
	
	# update the bar
#	  dws.tk_hold();
	  if (!has_field(self, 'barholder') || !is_agent(self.barholder)) {
	      note(paste('The progress meter is in an unexpected state.',
			 'Please file a defect if this is the first time',
			 'you have seen this message.'), priority='SEVERE', 
			 origin='progress.update');
	      self.busy:=F;
	      return frac;
	  }
	if (has_field(self, 'bar') && is_string(self.bar)) {
	  self.barholder->delete(self.bar);
	}
	self.bar := self.barholder->rectangle(0,0,frac*self.width, 
					      self.height + 2,fill='blue',
					      outline='blue');
#          dws.tk_release();		    

	# update the status line
	updstring := spaste('[',percent,'%');
	if (self.estimate_time && frac > 0) {
	  updstring := spaste(updstring, ', ',total,'s');
	}
	if (self.estimate_time && frac > 0) {
	  updstring := spaste(updstring, ', ',remaining,'s');
	}
	updstring := spaste(updstring, ']');
	if(self.showtext) self.statuslabel->text(updstring);
	self.cache.percent := percent;
	self.cache.remaining := remaining;
	self.cache.total := total;
				    
      }
      # Last check to see if we should die
      if(self.shoulddie) {
	public.deactivate();
	return 0;
      }
      self.busy:=F;
      return frac;
    }
    
    public.activate := function()
    {
      wider public;
      wider self;
      if (have_gui()) {
        if(!has_field(self, 'frame') || !is_agent(self.frame)){
	   self.frame := F;
	   self.init();
        }
	if (has_field(self, 'lastvalue')) public.update(self.lastvalue);
      }
    }
    
    public.deactivate := function()
    {
      wider self;
      global progressmeters;
      if (has_field(self, 'frame') && is_agent(self.frame)){
	  dws.tk_hold();
	  self.frame->unmap(); # Make sure it disappears quickly
          if(!is_agent(self.parent)) {
	    progressmeters.rmframe();
	  }
	  dws.tk_release();
      }
      if (has_field(self, 'timertag')) {
	timer.remove(self.timertag);
      }
      # self.frame := F;
    }
    
    public.done := function() {
      wider self, public;
      public.deactivate();
      val self := F;
      val public := F;
    }
    
    if (startopen) {
      if (is_numeric(startopen) && startopen > 0.5) {
	callback := function(rec, name) {
	  wider public;
	  if (has_field(public, 'activate'))
	      public.activate();
	}
	self.timertag := timer.execute(callback, startopen, oneshot=T);
      } else {
	self.init();	
      }
    }
    
    
    self.tstart := time();
  }
  else {
    public.update := function(value,autodisable=T){};
    public.activate := function() {};
    public.deactivate := function() {};
    public.done := function() {};
  }
  return ref public;
}

const tprogress := function (){
   bar1 := progress(0, 100, 'bar 1');
   bar1.activate();
   bar2 := progress(0, 100, 'bar 2');
   bar2.activate();
   for(count in 1:1000){
       bar1.update(count/10);
       bar2.update(count/10);
   }
   bar1 := F;
   bar2 := F;
   bar1 := progress(0, 100, 'bar 1');
   bar1.activate();
   for(count in 1:1000){
       bar1.update(count/10);

   }
   bar2 := progress(0, 100, 'bar 2');
   bar2.activate();
   for(count in 1:1000){
       bar2.update(count/10);
   }
   f:=frame(title='Special progress meter');
   bar3 := progress(0, 100, 'bar 3', barheight=5, barwidth=100, showtext=F,
		    parent=f);
   bar3.activate();
   for(count in 1:1000){
       bar3.update(count/10);
   }
   val f:=F;
   return T;
}
