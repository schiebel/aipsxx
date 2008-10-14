# autogui.g: build a GUI from a record
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
# $Id: autogui.g,v 19.3 2004/08/25 02:11:35 cvsmgr Exp $

pragma include once;

include 'widgetserver.g';
include 'illegal.g';

autogui := subsequence(ref params, title='autogui', 
		       ref toplevel=F, ref map=T, actionlabel=F,
		       autoapply=T, borderwidth=0, relief='ridge',
		       expand='none', widgetset=dws) : [reflect=T] {
			 
			 
  ############################################################
  ## store constructor arguments                            ##
  ############################################################
  its := [=];
  its.widgetset := widgetset;

  its.widgetset.tk_hold();
  its.params := params;
  its.title := title;
  its.map := map;
  its.actionlabel := actionlabel;
  its.autoapply := autoapply;
  its.expand := expand;
  
  its.guielem := [=];

  ############################################################
  ## whenever pusher                                        ##
  ############################################################
  its.whenevers := [];
  its.pushwhenever := function() {
    wider its;
    its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
  }
  
  ############################################################
  ## build the GUI                                          ##
  ############################################################
  its.gui.toplevel := toplevel;
  its.madetoplevel := F;
  if (!is_agent(its.gui.toplevel)) {
    its.gui.toplevel := its.widgetset.frame(title=its.title, side='top');
    its.gui.toplevel->unmap();
    its.madetoplevel := T;
  }

  ############################################################
  ## make a Guientry server GUI                             ##
  ############################################################

  its.guientry := its.widgetset.guientry(expand=its.expand);

  ############################################################
  ## callback server for userchoice widgets --- emits new   ##
  ## information when the choice options are increased...   ##
  ############################################################
  its.userchoicecallback := function(newitem, labels, callbackdata) {
      self->newuserchoicelist([param=callbackdata, newitem=newitem]);
      return T;
  }
  
  xfn_tmp := field_names(its.params);
  
  # first, deal with contexts:
  its.contexts := '';
  its.needsbasic := F;
  for (i in xfn_tmp) {
      if (has_field(its.params[i], 'ptype')) {
	  if (has_field(its.params[i], 'context')) {
	      if (!any(split(its.contexts) == its.params[i].context)) {
		  its.contexts := paste(its.contexts, its.params[i].context);
	      }
	  } else {
	      its.needsbasic := T;
	  }
      }
  }
  its.ctxt_rollups := [=];
  for (i in split(its.contexts)) {
    tmp := i ~ s/_/ /g;
    its.ctxt_rollups[i] := its.widgetset.rollup(its.gui.toplevel,
				      title=tmp,
				      show=F, side='top');
  }
  
  # Only make a basic settings rollup if other contexts exist
  if ((its.contexts!='') && its.needsbasic) {
      its.gui.drawrollup := its.widgetset.rollup(its.gui.toplevel,
						 title='Basic settings',
						 show=T, side='top');
      its.gui.drawlevel := its.gui.drawrollup.frame();
  }
  else {
      its.gui.drawlevel := its.widgetset.frame(its.gui.toplevel, side='top',
					       relief=relief);
  }
  # Loop creating widget for each field in params
  for (i in xfn_tmp) {
      
      if (has_field(its.params[i], 'ptype')) {

	  its.guielem[i] := [=];
	
	  allowunset := F;
	  if (!has_field(its.params[i], 'popt')) {
	      its.params[i].popt := '';
	  }
	  if (has_field(its.params[i], 'allowunset')) {
	      allowunset := its.params[i].allowunset;
	  }
	  if (has_field(its.params[i], 'context')) {
	      tmp_parent := its.ctxt_rollups[its.params[i].context].frame();
	  } else {
	      tmp_parent := its.gui.drawlevel;
	  }
	  
	  its.guielem[i].frame := its.widgetset.frame(tmp_parent, side='left',
						      borderwidth=0);
	  its.guielem[i].lframe := its.widgetset.frame(its.guielem[i].frame, 
						       side='left',
						       expand='none', 
						       borderwidth=0);
	  # blinklabel blocks help
	  helptext := 'No help available';
	  if (has_field(its.params[i], 'help')) {
	      helptext := its.params[i].help;
	  }
	  if ((its.params[i].ptype == 'choice') ||
	      (its.params[i].ptype == 'userchoice')) {
	      its.guielem[i].label := 
		  its.widgetset.blinklabel(its.guielem[i].lframe,
					   its.params[i].listname,
					   hlp=helptext,
					   borderwidth=0);
	  } else {
	      its.guielem[i].label := 
		  its.widgetset.label(its.guielem[i].lframe,
				      its.params[i].listname,
				      borderwidth=0);
	      its.guielem[i].label.shorthelp := helptext;
	  }
	  its.guielem[i].rframe := its.widgetset.frame(its.guielem[i].frame,
						       side='right',
						       borderwidth=0);
	  # only make an auto-apply button if this has no dependencies!
	  # (also omit for pushbuttons, which are always 'auto-apply')
	  if (its.autoapply &&
	      its.params[i].ptype != 'button' &&
	      ( !has_field(its.params[i], 'dependency_group') ||
	        len(its.params[i].dependency_list) == 0 ) ) {
	      its.guielem[i].autoapply :=
		  its.widgetset.button(its.guielem[i].rframe,
				       'auto\napply', value=i,
				       type='check',
				       font='small',
				       borderwidth=0);
	      if (has_field(its.params[i], 'autoapply') && 
		  is_boolean(its.params[i].autoapply)) {
		  its.guielem[i].autoapply->state(its.params[i].autoapply);
	      } else {
		  its.guielem[i].autoapply->state(T);
	      }
	      whenever its.guielem[i].autoapply->press do {
		  if (its.guielem[$value].autoapply->state()) {
		      if (has_field(its.guielem[$value].guiagent, 'get') &&
			  !is_fail(its.guielem[$value].guiagent.get())&&
			  !is_illegal(its.guielem[$value].guiagent.get())) {
			  self->changenotice(its.guielem[$value].guiagent);
		      }
		  }
	      } its.pushwhenever();
	  } 
	  
	  editable := T;
	  if (has_field(its.params[i], 'dir')&&its.params[i].dir == 'out') {
	      editable := F;
	  }
	  its.guielem[i].defaultbg := 
	      its.widgetset.resources('frame').background;
	  
	  if (its.params[i].ptype == 'list') {
	      its.guielem[i].guiagent :=
		  its.guientry.list(parent=its.guielem[i].rframe,
				    name=its.params[i].name,
				    names=its.params[i].names,
				    types=its.params[i].types,
				    options=its.params[i].popt,
				    values=its.params[i].value,
				    defaults=its.params[i].default,
				    editable=editable,
				    allowunset=allowunset,
				    hlps=helptext);
	      if (is_fail(its.guielem[i].guiagent)) {
		  fail paste('Fail creating', i, 
			     its.guielem[i].guiagent::message)
		  }
	      whenever its.guielem[i].guiagent->value do {
		  if (its.should_emit($agent)) {
		      self->changenotice($agent);
		  }
	      } its.pushwhenever();
	  } else if (its.params[i].ptype == 'choice') {
	      its.guielem[i].guiagent :=
		  its.guientry.choice(its.guielem[i].rframe,
				      options=its.params[i].popt,
				      value=its.params[i].value,
				      default=its.params[i].default,
				      editable=editable,
				      allowunset=allowunset,
				      hlp=helptext);
	      if (is_fail(its.guielem[i].guiagent)) {
		  fail paste('Fail creating', i, 
			     its.guielem[i].guiagent::message)
		  }
	      whenever its.guielem[i].guiagent->value do {
		  if (its.should_emit($agent)) {
		      self->changenotice($agent);
		  }
	      } its.pushwhenever();
	  } else if (its.params[i].ptype == 'check') {
	      if(has_field(its.params[i], 'nperline')) {
	          nperline := its.params[i].nperline;  }
	      else { nperline := 4;  }
	      its.guielem[i].guiagent :=
		  its.guientry.check(its.guielem[i].rframe,
				     options=its.params[i].popt,
				     value=its.params[i].value,
				     default=its.params[i].default,
				     nperline=nperline,
				     editable=editable,
				     allowunset=allowunset,
				     hlp=helptext);
	      if (is_fail(its.guielem[i].guiagent)) {
		  fail paste('Fail creating', i, 
			     its.guielem[i].guiagent::message)
		  }
	      whenever its.guielem[i].guiagent->value do {
		  if (its.should_emit($agent)) {
		      self->changenotice($agent);
		  }
	      } its.pushwhenever();
	  } else if (its.params[i].ptype == 'userchoice') {
	      its.guielem[i].guiagent := 
		  its.widgetset.extendoptionmenu(its.guielem[i].rframe,
						 its.params[i].popt,
					    callback2=its.userchoicecallback,
						 callbackdata=i,
						 borderwidth=0,
					  dialoglabel=its.params[i].listname,
						dialogtitle=paste('Enter new', 
						     its.params[i].listname));
	      if (is_fail(its.guielem[i].guiagent)) {
		  fail paste('Fail creating', i, 
			     its.guielem[i].guiagent::message)
		  }
	      whenever its.guielem[i].guiagent->select do {
		  if (its.should_emit($agent)) {
		      self->changenotice($agent);
		  }
	      } its.pushwhenever();
	  } else if (its.params[i].ptype == 'minmaxhist') {       
	      its.guielem[i].guiagent := 
		  its.guientry.minmaxhist(its.guielem[i].rframe, 
					  allowunset=allowunset,
					  editable=editable, 
					  value=its.params[i].value,
					  default=its.params[i].default, 
					  minvalue=its.params[i].pmin,
					  maxvalue = its.params[i].pmax,
					  hlp=helptext, title = its.title,
					  imageunits=its.params[i].imageunits,
					  histarray=its.params[i].histarray);
	      
	      if (is_fail(its.guielem[i].guiagent)) {
		  fail paste('Fail creating', i, 
			     its.guielem[i].guiagent::message)
		  }    
	      whenever its.guielem[i].guiagent->value do {
		  tmp_agent := $agent;
		  if (its.should_emit(tmp_agent)) {
		      self->changenotice(tmp_agent);
		  }
	      } its.pushwhenever();
	      
	      whenever its.guielem[i].guiagent->newstats do
	      {
		  self->setoptions([imagestats = $value]);
	      } its.pushwhenever();
	      
	      whenever its.guielem[i].guiagent->updatehistogram do
	      {
		  self->setoptions([alwaysupdate=$value]);
	      } its.pushwhenever();
	      
	  } else if (its.params[i].ptype == 'intrange') {
	      if (has_field(its.params[i], 'provideentry') &&
		  is_boolean(its.params[i].provideentry)) {
		  doen := its.params[i].provideentry;
	      } else {
		  doen := F;
	      }
	      its.guielem[i].guiagent :=
		  its.guientry.range(its.guielem[i].rframe,
				     allowunset=allowunset,
				     rmin=its.params[i].pmin,
				     editable=editable,
				     value=its.params[i].value,
				     default=its.params[i].default,
				     rmax=its.params[i].pmax, 
				     rresolution=1,
				     provideentry=doen,
				     hlp=helptext);
	      if (is_fail(its.guielem[i].guiagent)) {
		  fail paste('Fail creating', i, 
			     its.guielem[i].guiagent::message)
		  }
	      whenever its.guielem[i].guiagent->value do {
		  tmp_agent := $agent;
		  if (its.should_emit(tmp_agent)) {
		      #tmp_result := 
		      self->changenotice(tmp_agent);
		  }
	      } its.pushwhenever();
	  } else if (its.params[i].ptype == 'floatrange') {
	      if (has_field(its.params[i], 'presolution') &&
		  its.params[i].presolution > 0) {
		  resolution := its.params[i].presolution;
	      } else {
		  resolution := its.params[i].pmin - its.params[i].pmax;
		  resolution := abs(resolution / 100);
		  resolution := 10^as_integer(log(resolution) - 0.5);
	      }
	      if (has_field(its.params[i], 'provideentry') &&
		  is_boolean(its.params[i].provideentry)) {
		  doen := its.params[i].provideentry;
	      } else {
		  doen := F;
	      }
	      its.guielem[i].guiagent :=
		  its.guientry.range(its.guielem[i].rframe,
				     allowunset=allowunset,
				     rmin=its.params[i].pmin,
				     editable=editable,
				     value=its.params[i].value,
				     default=its.params[i].default,
				     rmax=its.params[i].pmax,
				     #rresolution=its.params[i].presolution);
				     rresolution=resolution,
				     provideentry=doen,
				     hlp=helptext);
	      if (is_fail(its.guielem[i].guiagent)) {
		  fail paste('Fail creating', i, 
			     its.guielem[i].guiagent::message)
		  }
	      whenever its.guielem[i].guiagent->value do {
		  tmp_agent := $agent;
		  if (its.should_emit(tmp_agent)) {
		      #tmp_result := 
		      self->changenotice(tmp_agent);
		  }
	      } its.pushwhenever();
	  } else if (its.params[i].ptype == 'table') {
	      its.guielem[i].guiagent :=
	      its.guientry.file(its.guielem[i].rframe,
				value=its.params[i].value,
				default=its.params[i].default,
				editable=editable,
				allowunset=allowunset,
				types=its.params[i].popt,
				hlp=helptext);
	  if (is_fail(its.guielem[i].guiagent)) {
	      fail paste('Fail creating', i, its.guielem[i].guiagent::message)
	      }
	      whenever its.guielem[i].guiagent->select do {
		  if (its.should_emit($agent)) {
		      self->changenotice($agent);
		  }
	      } its.pushwhenever();
	  } else if (its.params[i].ptype == 'file') {
	      its.guielem[i].guiagent :=
		  its.guientry.file(its.guielem[i].rframe,
				    value=its.params[i].value,
				    default=its.params[i].default,
				    allowunset=allowunset,
				    editable=editable,
				    types=its.params[i].popt,
				    hlp=helptext);
	      if (is_fail(its.guielem[i].guiagent)) {
		  fail paste('Fail creating', i, 
			     its.guielem[i].guiagent::message)
		  }
	      whenever its.guielem[i].guiagent->select do {
		  if (its.should_emit($agent)) {
		      self->changenotice($agent);
		  }
	      } its.pushwhenever();
	  } else if (its.params[i].ptype == 'directory') {
	      its.guielem[i].guiagent :=
		  its.guientry.file(its.guielem[i].rframe,
				    value=its.params[i].value,
				    default=its.params[i].default,
				    allowunset=allowunset,
				    editable=editable,
				    types='Directory',
				    hlp=helptext);
	      if (is_fail(its.guielem[i].guiagent)) {
		  fail paste('Fail creating', i, 
			     its.guielem[i].guiagent::message)
		  }
	      whenever its.guielem[i].guiagent->select do {
		  if (its.should_emit($agent)) {
		      self->changenotice($agent);
		  }
	      } its.pushwhenever();

	  } else if (its.params[i].ptype == 'button') {
	      local text := '';
	      if(has_field(its.params[i], 'text')) text := its.params[i].text;
	      its.guielem[i].guiagent :=
		      its.widgetset.button(its.guielem[i].rframe, text=text);
	      if (is_fail(its.guielem[i].guiagent)) {
	          fail paste('Fail creating', i,
			     its.guielem[i].guiagent::message)
	      }
	      whenever its.guielem[i].guiagent->press do {
	          self->changenotice($agent);
	      } its.pushwhenever();

	  } else if ((its.params[i].ptype == 'scalar')||
		     (its.params[i].ptype == 'booleanarray')||
		     (its.params[i].ptype == 'array')||
		     (its.params[i].ptype == 'antennas')||
		     (its.params[i].ptype == 'baselines')||
		     (its.params[i].ptype == 'fields')||
		     (its.params[i].ptype == 'fieldnames')||
		     (its.params[i].ptype == 'spectralwindows')||
		     (its.params[i].ptype == 'polarizations')||
		     (its.params[i].ptype == 'datadescriptions')||
		     (its.params[i].ptype == 'quantity')||
		     (its.params[i].ptype == 'coordinates')||
		     (its.params[i].ptype == 'region')||
		     (its.params[i].ptype == 'model')||
		     (its.params[i].ptype == 'modellist')||
		     (its.params[i].ptype == 'selection')||
		     (its.params[i].ptype == 'calibration')||
		     (its.params[i].ptype == 'calibrationlist')||
		     (its.params[i].ptype == 'solver')||
		     (its.params[i].ptype == 'solverlist')||
		     (its.params[i].ptype == 'freqsel')||
		     (its.params[i].ptype == 'restoringbeam')||
		     (its.params[i].ptype == 'deconvolution')||
		     (its.params[i].ptype == 'imagingcoord')||
		     (its.params[i].ptype == 'imagingfield')||
		     (its.params[i].ptype == 'imagingfieldlist')||
		     (its.params[i].ptype == 'imagingweight')||
		     (its.params[i].ptype == 'mask')||
		     (its.params[i].ptype == 'transform')||
		     (its.params[i].ptype == 'tool')||
		     (its.params[i].ptype == 'measure')||
		     (its.params[i].ptype == 'measurecodes')||
		     (its.params[i].ptype == 'scalarmeasure')||
		     (its.params[i].ptype == 'epoch')||
		     (its.params[i].ptype == 'direction')||
		     (its.params[i].ptype == 'position')||
		     (its.params[i].ptype == 'record')||
		     (its.params[i].ptype == 'boolean')||
		     (its.params[i].ptype == 'taql')||
		     (its.params[i].ptype == 'msselect')||
		     (its.params[i].ptype == 'untyped')) {
	      its.guielem[i].guiagent :=
		  its.guientry[its.params[i].ptype](its.guielem[i].rframe,
						    editable=editable,
						    value=its.params[i].value,
						default=its.params[i].default,
						    options=its.params[i].popt,
						    allowunset=allowunset,
						    hlp=helptext);
	      if (is_fail(its.guielem[i].guiagent)) {
		  fail paste('Fail creating', i, 
			     its.guielem[i].guiagent::message)
		  }
	      whenever its.guielem[i].guiagent->value do {
		  if (its.should_emit($agent)) {
		      self->changenotice($agent);
		  }
	      } its.pushwhenever();
	  } else if ((its.params[i].ptype == 'string')||
		     (its.params[i].ptype == 'vector_string')) {
	      its.guielem[i].guiagent :=
		  its.guientry.string(its.guielem[i].rframe,
				      editable=editable,
				      value=its.params[i].value,
				      default=its.params[i].default,
				      allowunset=allowunset,
				      onestring=(its.params[i].ptype == 
						 'string'),
				      hlp=helptext);
	      if (is_fail(its.guielem[i].guiagent)) {
		  fail paste('Fail creating', i, 
			     its.guielem[i].guiagent::message)
		  }
	      whenever its.guielem[i].guiagent->value do {
		  if (its.should_emit($agent)) {
		      self->changenotice($agent);
		  }
	      } its.pushwhenever();
	  } else {
	      its.guielem[i].guiagent :=
		  its.widgetset.entry(its.guielem[i].rframe, width=20, 
				      borderwidth=0);
	      if (is_fail(its.guielem[i].guiagent)) {
		  fail paste('Fail creating', i, 
			     its.guielem[i].guiagent::message)
		  }
	      whenever its.guielem[i].guiagent->return do {
		  if (its.should_emit($agent)) {
		      self->changenotice($agent);
		  }
	      } its.pushwhenever();
	  }
	  
      } #END if(has_field 'ptype')
      
      if (has_field(its.params[i], 'paramcontext')&&
	  has_field(its.guielem[i].guiagent, 'setcontexts')) {
	  its.guielem[i].guiagent.setcontexts(its.params[i]['paramcontext']);
      }
      
  }
  
  if (its.madetoplevel) {
      its.gui.buttonbar := its.widgetset.frame(its.gui.toplevel, side='left', 
					       expand='both');
      self.buttonbar := function() {
	  return its.gui.bbarleft;
      }
      if (is_string(its.actionlabel)) {
	  its.gui.bbarleft := its.widgetset.frame(its.gui.buttonbar, 
						  side='left', 
						  expand='x');
	  # make button bar:
	  its.gui.go := its.widgetset.button(its.gui.bbarleft, its.actionlabel,
					     type='action');
	  whenever its.gui.go->press do {
	      its.readandemit();
	  } its.pushwhenever();
	  # following provided so buttons can be added to autoguis which 
	  # did maketoplevel...
      }
      its.gui.bbarrght := its.widgetset.frame(its.gui.buttonbar, side='right', 
					  expand='x');
      its.gui.dismiss := its.widgetset.button(its.gui.bbarrght, 'Dismiss',
					  type='dismiss');
      whenever its.gui.dismiss->press do {
	  self.done();
      } its.pushwhenever();
  }
  
  ############################################################
  ## fill the GUI                                           ##
  ############################################################
  self.fillgui := function(ref wparams, what='value') {
    wider its;      
    if (!is_record(wparams)) return;

    its.widgetset.tk_hold();
    xfn_tmp := field_names(wparams);
    
    for (i in xfn_tmp) {
	if (has_field(its.params, i))
	    if (has_field(its.params[i], 'ptype')) {
		if (has_field(its.params[i], 'allowunset')) {
		    allowunset := its.params[i].allowunset;
		}
		else {
		    allowunset := F;
		}
		# Don't try to insert unsets if not allowed
		if (is_unset(wparams[i][what])&&!allowunset) continue;

		if (wparams[i].ptype == 'userchoice') {
		    its.guielem[i].guiagent.replace(wparams[i].popt);
		    its.guielem[i].guiagent.selectlabel(
					      as_string(wparams[i][what]));
		} else if (any(wparams[i].ptype ==
			       "intrange minmaxhist floatrange")) {
		    its.guielem[i].guiagent.insert(wparams[i][what]);
		    its.guielem[i].guiagent[what] := wparams[i][what];
		} else if (wparams[i].ptype == 'vector') {
		    its.guielem[i].guiagent->delete('start', 'end');
		    temp := paste(as_string(wparams[i][what]), sep=',');
		    temp := paste('[', temp, ']', sep='');
		    its.guielem[i].guiagent->insert(temp);
		} else if (wparams[i].ptype == 'button') {
			# no need to send any value.
		} else if ((wparams[i].ptype == 'string') ||
			   (wparams[i].ptype == 'vector_string') ||
			   (wparams[i].ptype == 'table') ||
			   (wparams[i].ptype == 'file') ||
			   (wparams[i].ptype == 'directory') ||
			   (wparams[i].ptype == 'boolean') ||
			   (wparams[i].ptype == 'taql') ||
			   (wparams[i].ptype == 'msselect') ||
			   (wparams[i].ptype == 'choice') ||
			   (wparams[i].ptype == 'check') ||
			   (wparams[i].ptype == 'scalar') ||
			   (wparams[i].ptype == 'booleanarray') ||
			   (wparams[i].ptype == 'array') ||
			   (wparams[i].ptype == 'antennas') ||
			   (wparams[i].ptype == 'baselines') ||
			   (wparams[i].ptype == 'fields') ||
			   (wparams[i].ptype == 'fieldnames') ||
			   (wparams[i].ptype == 'spectralwindows') ||
			   (wparams[i].ptype == 'polarizations') ||
			   (wparams[i].ptype == 'datadescriptions') ||
			   (wparams[i].ptype == 'quantity') ||
			   (wparams[i].ptype == 'coordinates') ||
			   (wparams[i].ptype == 'region') ||
			   (wparams[i].ptype == 'model') ||
			   (wparams[i].ptype == 'modellist')||
			   (wparams[i].ptype == 'selection')||
			   (wparams[i].ptype == 'calibration')||
			   (wparams[i].ptype == 'calibrationlist')||
			   (wparams[i].ptype == 'solver')||
			   (wparams[i].ptype == 'solverlist')||
			   (wparams[i].ptype == 'freqsel')||
			   (wparams[i].ptype == 'restoringbeam') ||
			   (wparams[i].ptype == 'deconvolution') ||
			   (wparams[i].ptype == 'imagingcoord') ||
			   (wparams[i].ptype == 'imagingfield') ||
			   (wparams[i].ptype == 'imagingfieldlist') ||
			   (wparams[i].ptype == 'imagingweight') ||
			   (wparams[i].ptype == 'mask') ||
			   (wparams[i].ptype == 'transform') ||
			   (wparams[i].ptype == 'tool') ||
			   (wparams[i].ptype == 'measure') ||
			   (wparams[i].ptype == 'measurecodes') ||
			   (wparams[i].ptype == 'scalarmeasure')||
			   (wparams[i].ptype == 'epoch')||
			   (wparams[i].ptype == 'direction')||
			   (wparams[i].ptype == 'position')||
			   (wparams[i].ptype == 'untyped') ||
			   (wparams[i].ptype == 'list') ||
			   (wparams[i].ptype == 'record')) {
		    its.guielem[i].guiagent.insert(wparams[i][what]);
		} else {
		    its.guielem[i].guiagent->delete('start', 'end');
		    its.guielem[i].guiagent->insert(as_string(wparams[i][what]));
	        }
	    } #END if (has_field 'ptype')
    }
      its.widgetset.tk_release();
      return T;
      
  }
      
# fill the gui...
  self.fillgui(its.params);

  its.widgetset.addpopuphelp(its, 5);

  ok := its.widgetset.tk_release();
  
  
  
# map the gui onto the screen...
  if (map) {
    its.gui.toplevel->map();
  }
  
############################################################
## modify the GUI - a subset of existing options are      ##
## given, and labels are changed, ranges changed, and     ##
## values changed...                                      ##
############################################################
  self.modifygui := function(ref wparams) {
      wider its;

      xfn_tmp := field_names(wparams);
      for (i in xfn_tmp) {
	  if (has_field(wparams[i], 'ptype')) {
	      if (any(wparams[i].ptype == "intrange floatrange minmaxhist")) {

		  its.guielem[i].guiagent.setrange(wparams[i].pmin,
						   wparams[i].pmax);
		  its.guielem[i].guiagent.insert(wparams[i].value);
		  its.guielem[i].label->text(wparams[i].listname);

		  if (wparams[i].ptype == 'minmaxhist') {
		      if (has_field(wparams[i], 'newdata')) {
			  if (wparams[i].newdata)
			      its.guielem[i].guiagent.setdata(
					wparams[i].histarray);
		      }
		      if (has_field(wparams[i], 'stats')) {
			  if (wparams[i].stats.new)
			      its.guielem[i].guiagent.setstats(
					wparams[i].stats);
		      }
		  }
	      } else if (wparams[i].ptype == 'choice' ||
	      		 wparams[i].ptype == 'array') {
		  its.guielem[i].guiagent.insert(wparams[i].value);

	      } else {
		  note(spaste('Cannot modify parameters of type ',
			      wparams[i].ptype), 
		       origin='autogui.g', priority='WARN');
	      }
	  } #END if (has_field 'ptype')
      }
      #return self.fillgui(wparams);
  }

############################################################
## read the GUI                                           ##
############################################################
  its.readgui := function(ref rwparams) {
      wider its;
      xfn_tmp := field_names(rwparams);
      for (i in xfn_tmp) {
	  if (has_field(rwparams[i], 'ptype')) {
	      if (rwparams[i].ptype == 'userchoice') {
		  rwparams[i].value :=
		      its.guielem[i].guiagent.getlabel();
	      } else if (rwparams[i].ptype == 'button') {
		  rwparams[i].value := T;
		          # hard-coded (and irrelevant) 'value'

	      } else if ((rwparams[i].ptype == 'table') ||
			 (rwparams[i].ptype == 'file') ||
			 (rwparams[i].ptype == 'directory') ||
			 (rwparams[i].ptype == 'intrange') ||
			 (rwparams[i].ptype == 'floatrange') ||
			 (rwparams[i].ptype == 'minmaxhist') ||
			 (rwparams[i].ptype == 'scalar') ||
			 (rwparams[i].ptype == 'booleanarray') ||
			 (rwparams[i].ptype == 'array') ||
			 (rwparams[i].ptype == 'antennas') ||
			 (rwparams[i].ptype == 'baselines') ||
			 (rwparams[i].ptype == 'fields') ||
			 (rwparams[i].ptype == 'fieldnames') ||
			 (rwparams[i].ptype == 'spectralwindows') ||
			 (rwparams[i].ptype == 'polarizations') ||
			 (rwparams[i].ptype == 'datadescriptions') ||
			 (rwparams[i].ptype == 'quantity') ||
			 (rwparams[i].ptype == 'coordinates') ||
			 (rwparams[i].ptype == 'region') ||
			 (rwparams[i].ptype == 'model') ||
			 (rwparams[i].ptype == 'modellist')||
			 (rwparams[i].ptype == 'selection')||
			 (rwparams[i].ptype == 'calibration')||
			 (rwparams[i].ptype == 'calibrationlist')||
			 (rwparams[i].ptype == 'solver')||
			 (rwparams[i].ptype == 'solverlist')||
			 (rwparams[i].ptype == 'freqsel')||
			 (rwparams[i].ptype == 'restoringbeam')||
			 (rwparams[i].ptype == 'deconvolution')||
			 (rwparams[i].ptype == 'imagingcoord')||
			 (rwparams[i].ptype == 'imagingfield')||
			 (rwparams[i].ptype == 'imagingfieldlist')||
			 (rwparams[i].ptype == 'imagingweight')||
			 (rwparams[i].ptype == 'mask')||
			 (rwparams[i].ptype == 'transform')||
			 (rwparams[i].ptype == 'tool') ||
			 (rwparams[i].ptype == 'measure') ||
			 (rwparams[i].ptype == 'measurecodes') ||
			 (rwparams[i].ptype == 'scalarmeasure')||
			 (rwparams[i].ptype == 'epoch')||
			 (rwparams[i].ptype == 'direction')||
			 (rwparams[i].ptype == 'position')||
			 (rwparams[i].ptype == 'record') ||
			 (rwparams[i].ptype == 'list') ||
			 (rwparams[i].ptype == 'untyped') ||
			 (rwparams[i].ptype == 'choice') ||
			 (rwparams[i].ptype == 'check') ||
			 (rwparams[i].ptype == 'boolean') ||
			 (rwparams[i].ptype == 'msselect') ||
			 (rwparams[i].ptype == 'taql') ||
			 (rwparams[i].ptype == 'vector_string') ||
			 (rwparams[i].ptype == 'string')) {
		  rwparams[i].value := its.guielem[i].guiagent.get();
	      } else {
		  temp := its.guielem[i].guiagent->get();
		  if (temp!='') {
		      eval(spaste('__aipseye_temp := ', temp));
		      temp := __aipseye_temp;
		      rwparams[i].value := __aipseye_temp;
		  }
	      }
	  } #END if (has_field 'ptype')
      }
  }
  
  its.readandemit := function() {
    wider its;
    its.check_dependencies(reread=T);
    rec := [=];
    xfn_tmp := field_names(its.params);
    failed := F;
    for (i in xfn_tmp) {
        if (   ( !has_field(its.params[i],'dependency_group') ||
	         its.dependency_states[params[i].dependency_group] )   &&
	       has_field(its.params[i],'ptype')   &&
	       its.params[i].ptype != 'button'   ) {
			# (we don't send param for button except
			#  when explicitly pressed...)

	    if (is_fail(its.params[i].value)||
		is_illegal(its.params[i].value)) {
		failed := T;
		break;
	    }
	    else {
		rec[its.params[i].dlformat] := its.params[i].value;
	    }
	}
    }
    if (!failed) {
      self->setoptions(rec);
      return rec;
    }
    else {
      fail "One or more entries are illegal"
    }
  }
  
  its.should_emit := function(theagent) {
    it := F;
    for (i in field_names(its.guielem)) {
      if (its.guielem[i].guiagent == theagent) {
	it := i;
	break;
      }
    }
    if (is_boolean(it)) {
      return F; # agent not found: don't emit.
    }

    # let's check the deps.
    #its.check_dependencies(reread=T);
    
    if (!has_field(its.guielem[it], 'autoapply')) {
      return F; # no autoapply button: don't emit.
    }
    if (its.guielem[it].autoapply->state()) {
	return T;
    } 
    return F;
  }
  
  ############################################################
  ## check all dependencies                                 ##
  ############################################################
  its.dependency_states := [=];
  its.check_dependencies := function(reread=F) {
    wider its;
    if (reread) {
      its.readgui(its.params);
    }
    for (i in field_names(its.params)) {
      if (has_field(its.params[i], 'dependency_group')) {
	its.dependency_states[its.params[i].dependency_group] :=
	    its.check_dependency_group(its.params[i].
				       dependency_group);
      }
    }
  }
  
  ############################################################
  ## check dependencies for this group                      ##
  ############################################################
  its.check_dependency_group := function(group, reread=F) {
    wider its;
    if (reread) {
      its.readgui(its.params);
    }
    fields := '';
    for (i in field_names(its.params)) {
      if (has_field(its.params[i], 'dependency_group') &&
	  its.params[i].dependency_group == group) {
	fields := paste(fields, i);
      }
    }
    fields := split(fields);
    if (len(fields) < 2) {
      return T; # not enough fields to compare!
    }
    # ignore dependency_type here, should check, following code
    # is for "exclusive"...
    for (i in 1:(len(fields) - 1)) {
      for (j in (i + 1):len(fields)) {
	if (its.params[fields[i]].value == 
	    its.params[fields[j]].value) {
	  its.show_dependency(group, F);
	  return F;
	}
      }
    }
    its.show_dependency(group, T);
    return T;
  }
  
  ############################################################
  ## show dependency state in the gui                       ##
  ############################################################
  its.show_dependency :=  function(group, valid=T) {
    wider its;
    for (i in field_names(its.params)) {
      if (has_field(its.params[i], 'dependency_group') &&
	  its.params[i].dependency_group == group) {
	if ((its.params[i].ptype == 'choice') ||
	    (its.params[i].ptype == 'userchoice')) {
	    its.guielem[i].guiagent.setstatus(valid);
	} else {
	  its.params[i].ptype;
	}
      }
    }
  }
  
  ############################################################
  ## deal with changenotice internally                      ##
  ############################################################
  whenever self->changenotice do {
    theagent := $value;

    it := F;
    
    for (i in field_names(its.guielem)) {
	if (is_agent(its.guielem[i].guiagent)) { 
	    if (its.guielem[i].guiagent == theagent) {
		it := i;
		break;
	    }
	}
    }
    if (!is_boolean(it)) {
      # now 'it' is the parameter name...
      if (  ( has_field(its.params[it],'ptype') &&
              its.params[it].ptype == 'button' ) ||
	    its.guielem[it].autoapply->state()  ) {

	# autoapply is true.  (button guielements have no
	# autoapply widget, but are always 'autoapply')

	myparam := [=];
	myparam[it] := its.params[it];
	its.readgui(myparam);
	rec := [=];
	rec[myparam[it].dlformat] := myparam[it].value;
	self->setoptions(rec);
      }
    } 
  } its.pushwhenever();
  
  ############################################################
  ## dismiss self if displaydata was deleted                ##
  ############################################################
  whenever self->dismiss do {
      self.done();
  } its.pushwhenever();
  
  ############################################################
  ## how to dismiss                                         ##
  ############################################################
  self.dismiss := function() {
      wider its;

      #Since self.done is so slow:
      for (i in field_names(its.params)) {
	  if (is_record(its.guielem[i]) &&
	      (has_field(its.guielem[i], 'guiagent')) 
	       && (has_field(its.guielem[i].guiagent, 'dismiss'))) {
	      
	      its.guielem[i].guiagent.dismiss();
	  }
      }
      # 

    #wider its;
    #deactivate its.whenevers;
    #its.gui.toplevel->unmap();
    #its.gui.toplevel := F;
    #return T;
    #note(spaste('autogui.dismiss is deprecated - used \'done\''));
    #self.done();
  }

  self.setcontext := function(context, value) {
    wider its;
    for (i in field_names(its.params)) {
	if (has_field(its.params[i], 'ptype')) {
	    if (has_field(its.guielem[i].guiagent, 'setcontext')) {
		its.guielem[i].guiagent.setcontext(context, value);
	    }
	}
    }
    return T;
  }

  self.setcontexts := function(contexts) {
      wider its;
      for (i in field_names(its.params)) {
	  if (has_field(its.params[i], 'ptype')) {
	      if (has_field(its.guielem[i].guiagent, 'setcontexts')) {
		  its.guielem[i].guiagent.setcontexts(contexts);
	      }
	  }
      }
      return T;
  }
  
  self.done := function() {
      wider its;
      wider self;

      its.widgetset.tk_hold();

      if (its.madetoplevel&&has_field(its.gui, 'toplevel')) {
	its.gui.toplevel->unmap();
      }
      for (i in field_names(its.params)) {
	  if (has_field(its.params[i], 'ptype')) {
	      if (has_field(its.guielem[i].guiagent, 'done')) {
		  its.guielem[i].guiagent.done();
	      }
	      if(its.params[i].ptype=='button') its.guielem[i].guiagent := F;
			# (should probably do this for any ptype...dk)

	      its.guielem[i].label := F;
	      its.guielem[i].frame := F;
	      its.guielem[i].lframe := F;
	      if (has_field(its.guielem[i].guiagent, 'autoapply')) {
		  its.guielem[i].guiagent.autoapply := F;
	      }
	  }
      }
      for (i in split(its.contexts)) {
	if (has_field(its.ctxt_rollups[i], 'done')) {
	  its.ctxt_rollups[i].done();
	}
      }
      if (has_field(its.gui, 'drawrollup')) its.gui.drawrollup.done();
      if (has_field(its.gui, 'buttonbar')) its.gui.buttonbar := F;
      if (its.madetoplevel&&has_field(its.gui, 'toplevel')) {
	its.gui.toplevel := F;
      }
      deactivate its.whenevers;
      val self := F;

      its.widgetset.tk_release();
      val its := F;
      return T;
  }
  
  self.map := function() {
    wider its;
    its.gui.toplevel->map();
    return T;
  }
  
  self.get := function() {
    wider its;
    return its.readandemit();
  }

}

const autoguitest := function(expand='none') {

# we will put a "parameter set" into "parameters":
  parameters := [=];
  
# Set up various widgets:
  
# floatrange
# give min, max and resolution: it makes a scale widget
  p_power := [dlformat='power',
	      listname='Scaling power',
	      ptype='floatrange',
	      pmin=-5.0,
	      pmax=5.0,
	      presolution=0.1,
	      default=0.0,
	      value=1.5];
  parameters.power := p_power;
  
# choice
# give a list of options: it makes an optionmenu widget
  p_resample := [dlformat='resample',
		 listname='Resampling mode',
		 allowuset=T,
		 ptype='choice',
		 popt="nearest bilinear",
		 default='nearest',
		 value='nearest'];
  parameters.resample := p_resample;
  
# orderedvector
# give how many numbers, and the range: it makes "n" scale widgets,
# each constrained to have the slider between those above and below it.
  p_range := [dlformat='range',
	      listname='Data range',
	      ptype='orderedvector',
	      plength=2,
	      prange=[-10, 150],
	      default=[15, 85],
	      value=[15, 85]];
  parameters.range := p_range;
  
# boolean
# Only need to give default
  p_switch := [dlformat='switch',
	       listname='Plot contours',
	       ptype='boolean',
	       allowuset=T,
	       default=T,
	       value=F];
  parameters.switch := p_switch;

# vector
# just an entry box at the moment: needs some smarts like the ones
# in regionmanager and others.
  p_levels := [dlformat='levels',
	       listname='Contour levels',
	       ptype='vector',
	       default=[0.2, 0.4, 0.6, 0.8],
	       value=[0.2, 0.4, 0.6, 0.9]];
  parameters.levels := p_levels;
  
# scalar
# just an entry box at the moment - perhaps a scale or "winding entry
# box" in the future.
  p_scale := [dlformat='scale',
	      listname='Contour scale factor',
	      ptype='scalar',
	      default=0.5,
	      value=1.2];
  parameters.scale := p_scale;
  
# intrange
# give min/max: this makes a scale widget with step size 1.
  p_line := [dlformat='line',
	     listname='Line width',
	     ptype='intrange',
	     pmin=0,
	     pmax=6,
	     default=1,
	     value=1];
  parameters.line := p_line;
  
# userchoice
# just like 'choice', but allows extension by user via extendoptionmenu.
  p_color := [dlformat='color',
	      listname='Line color',
	      ptype='userchoice',
	      popt="black white red green blue yellow",
	      default='blue',
	      value='blue'];
  parameters.color := p_color;
  
# now for Axis selection example:
#
# any parameter can have a context field, which if it exists, forces
# the parameter to be put in a roll-up so it can be squirelled away
# for only occasional use.
#
# then there is also dependency_group, which can have any name, in
# this case "axes" and flags which parameters belong to a particular
# group.  Parameters in this group are only emitted if the dependencies
# are met.
#
# then there is dependency_type: exclusive is the only one known at
# the moment to the autogui.
#
# finally, dependency_list is a string list of the other parameters
# (actually their dlformat field values) which, in this case, must
# be exclusive of this value.
  
  p_xaxis := [dlformat='xaxis',
	      listname='X-axis',
	      ptype='choice',
	      popt="R.A. Dec Vel",
	      default='R.A.',
	      value='R.A.',
	      context='Axis_selection',
	      dependency_group='axes',
	      dependency_type='exclusive',
	      dependency_list="yaxis zaxis"];
  parameters.xaxis := p_xaxis;
  
  p_yaxis := [dlformat='yaxis',
	      listname='Y-axis',
	      ptype='choice',
	      popt="R.A. Dec Vel",
	      default='Dec',
	      value='Dec',
	      context='Axis_selection',
	      dependency_group='axes',
	      dependency_type='exclusive',
	      dependency_list="xaxis zaxis"];
  parameters.yaxis := p_yaxis;
  
  p_zaxis := [dlformat='zaxis',
	      listname='Z-axis',
	      ptype='choice',
	      popt="R.A. Dec Vel",
	      default='Vel',
	      value='Vel',
	      context='Axis_selection',
	      dependency_group='axes',
	      dependency_type='exclusive',
	      dependency_list="xaxis yaxis"];
  parameters.zaxis := p_zaxis;
  
  p_filename := [dlformat='file',
		 listname='File name',
		 ptype='file',
		 default=unset,
		 allowunset=T,
		 value='myfilename',
		 popt='All'];
  parameters.filename := p_filename;
  
  p_strings := [dlformat='strings',
		listname='Strings',
		ptype='vector_string',
		default=unset,
		allowunset=T,
		value="foo bar"]
  parameters.strings := p_strings;
  
  p_cellsize := [dlformat='quantity',
		 listname='Cell size',
		 ptype='quantity',
		 default=unset,
		 allowunset=T,
		 value='0.7arcsec'];
  parameters.cellsize := p_cellsize;
  
  p_imagesize := [dlformat='scalar',
		  listname='Image size',
		  ptype='scalar',
		  default=unset,
                  allowunset=T,
		  value=256];
  parameters.imagesize := p_imagesize;
  
  p_direction := [dlformat='measure',
		  listname='Phase Center',
		  ptype='measure',
		  default=unset,
		  value='dm.direction(\'sun\', \'0deg\', \'0deg\')',
		  allowunset=T];
  
  parameters.direction := p_direction;
  
  include 'measures.g';
  p_source := [dlformat='list',
	       ptype='list',
	       listname='Sources',
	       types=['string', 'direction'],
	       names="Source Direction",
	       name='Source',
	       default=unset,
	       value=[Name='3C273',
		       Direction=dm.direction()],
	       help=['Source name', 'Source direction'],
	       allowunset=T,
	       popt=unset,
	       editable=T];
  
  parameters.source := p_source;
  
  p_measurecodes := [dlformat='measurecodes',
		     listname='Direction codes',
		     ptype='measurecodes',
		     default=unset,
		     value='B1950',
		     popt='direction',
		     allowunset=T];
  
  parameters.direction := p_measurecodes;
  
  stime := time();
  mygui := autogui(parameters, 'My demonstration autogui', autoapply=T,
		   actionlabel='Apply',
		   expand=expand);

  if (is_fail(mygui)) fail;

  note('Construction of autogui took ', time()-stime, ' seconds');
  mygui.setcontexts([foo='foo']);
  
  whenever mygui->setoptions do {
    print "\nautogui.g - New options for", field_names($value), "emitted...";
    print as_evalstr($value);
  }
}

