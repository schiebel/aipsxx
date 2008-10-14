# multiautogui.g: widget to manage a collection of autoguis
# Copyright (C) 2002
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
# $Id: 

pragma include once

include 'autogui.g'
multiautogui := subsequence(ref params = F, title='autogui', 
			    ref toplevel=F, ref map=T, actionlabel=F,
			    autoapply=T, borderwidth=0, relief='ridge',
			    expand='none', widgetset=dws) : [reflect=T] {

  # Save everything			       
  its := [=];
  its.widgetset := widgetset;
  its.autoguis := [=];
  its.title := title;
  its.map := map;
  its.actionlabel := actionlabel;
  its.autoapply := autoapply;
  its.expand := expand;

  # Our holders
  its.autoguis := [=];
  its.containers := [=];

  # Make a frame if we need to
  its.toplevel := toplevel;
  if (is_boolean(toplevel)) {
      its.toplevel := its.widgetset.frame(title = its.title);
  }

  ###################################################
  # Functions to control mapping.                   #
  ################################################### 

  # Show none.
  self.shownone := function() {
      wider its; 

      its.widgetset.tk_hold();

      for (i in field_names(its.containers))
	  its.containers[i]->unmap();

      its.widgetset.tk_release();
      return T;
  }

  # Show specified
  self.show := function(whichone) {
      wider its;
      foundit := F;

      its.widgetset.tk_hold();

      for (i in field_names(its.containers)) {
	  if (i == whichone) {
	      its.containers[i]->map();
	      foundit := T;
	  } else its.containers[i]->unmap();
      }
      
      its.widgetset.tk_release();

      return foundit;
  }


  ###################################################
  # Functions to control GUIs                       #
  ################################################### 

  # Fill the GUIs
  self.fillgui := function(params) {

      its.widgetset.tk_hold();

      for (i in field_names(params)) {
	  updated := F;
	  for (j in field_names(its.autoguis)) {
	      if (i == j) {
		  its.autoguis[j].fillgui(params[i]);
		  updated := T;
	      }
	  }
	  if (!updated) {
	      self.addautogui(i, params[i]);
	  }
      }

      its.widgetset.tk_release();

      return T;
  }

  # Add a new autogui
  self.addautogui := function(name, params) {
      wider its;
      its.widgetset.tk_hold();

      its.containers[name] := its.widgetset.frame(its.toplevel);

      its.autoguis[name] := autogui(params, its.title,
				 toplevel = its.containers[name], map = T,
				 actionlabel = its.actionlabel,
				 autoapply = its.autoapply,
				 widgetset = its.widgetset);

      if (is_fail(its.autoguis[name])) {
	  its.widgetset.tk_release();
	  return F;
      }

      its.containers[name]->unmap();

      whenever its.autoguis[name]->* do {
	  returnme := [=];
	  returnme[name] := $value;
	  self->[$name](returnme);
      }

      its.widgetset.tk_release();
      return T;
  }

  # Ok, let's build the ones supplied in the constructor
  if (is_record(params)) {
      for (i in field_names(params))
	  its.subparams[i] := params[i];
      
      for (i in field_names(its.subparams))
	  self.addautogui(i, its.subparams[i]);

      # Turn em off by default.
      
  }


}


############################################################
# Very basic multiautogui test - really just to give a     #
# feel for the intended purpose.                           #
############################################################
multiautoguitest := subsequence() {
    
    autoguione := [=];

    p_switch := [dlformat='switch',
		 listname='Plot some contours',
		 ptype='boolean',
		 allowuset=T,
		 default=T,
		 value=F];
    autoguione.switch := p_switch;
    
    p_levels := [dlformat='levels',
		 listname='Contour levels for one set',
		 ptype='vector',
		 default=[0.2, 0.4, 0.6, 0.8],
		 value=[0.2, 0.4, 0.6, 0.9]];
    autoguione.levels := p_levels;
    
    autoguitwo := [=];
    
    p_levels := [dlformat='levels',
		 listname='Contour levels for number 2',
		 ptype='vector',
		 default=[0.2, 0.4, 0.6, 0.8],
		 value=[0.2, 0.4, 0.6, 0.9]];
    autoguitwo.levels := p_levels;

    
    p_power := [dlformat='power',
		listname='Scaling power for number 2',
		ptype='floatrange',
		pmin=-5.0,
		pmax=5.0,
		presolution=0.1,
		default=0.0,
		value=1.5];
    autoguitwo.power := p_power;

    param := [=];
    param.autoguione := autoguione;
    param.autoguitwo := autoguitwo;
    
    autoguithree := [=];
    
    p_switch := [dlformat='switch',
		 listname='Plot contours for a third thing?',
		 ptype='boolean',
		 allowuset=T,
		 default=T,
		 value=F];
    autoguithree.switch := p_switch;

    include 'measures.g';
    stime := time();
    
    topframe := frame();
    
    but := button(topframe, '1');
    but2 := button(topframe, '2');
    but3 := button(topframe, '3');
    
    mymulti := multiautogui(param, toplevel = topframe, title = 'Test Multi');

    note('Construction of multiautogui took ', time()-stime, ' seconds');
    stime := time();
    
    somenewparams := [=];
    somenewparams.autoguithree := autoguithree;

    mymulti.fillgui(somenewparams);
    
    note('Addition of another autogui took ', time()-stime, ' seconds');

    whenever but->press do {
	mymulti.show('autoguione');
    }
    whenever but2->press do {
	mymulti.show('autoguitwo');
    }
    whenever but3->press do {
	mymulti.show('autoguithree');
    }
    
    whenever mymulti->setoptions do {
	print "\nautogui.g - New options for", field_names($value), 
	    "emitted...";
	print as_evalstr($value);

    }

}




