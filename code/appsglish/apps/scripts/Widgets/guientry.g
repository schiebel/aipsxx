# guientry: Gui for input and output of parameters
# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
# $Id: guientry.g,v 19.3 2004/08/25 02:14:35 cvsmgr Exp $


pragma include once
    
include 'widgetserver.g';
include 'note.g';

# Notes:
#
# guientry serves widgets for the entry of various types. Since many
# of the operations are almost common, widgets are implemented using
# a number of standard functions, which are defined and located in
# the "private" record of guientry. Data and functions private to each
# widget are stored in the "its" record of each widget. Since each
# widget is subsequence, the public functions of the widget are
# located in "self". This means that the private functions of guientry
# take as arguments refs to "self" and "its". 
#
# Each widget works as follows:
#
# - original and default values are passed in on construction
# - actual and displayed values are notionally separate. The former
#   is usually a value, and the latter a string representation of 
#   the value. This latter may be a name or the as_string'ed version of
#   of the value. In those cases where we don't want to display the
#   full value, we display instead a standard string like "<array>" or
#   "<measure>".
# - A menu of operations on the actual value is presented as 
#   a separate menu button. These operations include clipboard copy
#   and paste, resetting values, setting unset, and, where possible,
#   invoking the relevant viewer or editor.
# - The status of the entry is shown in a status area at the right 
#   hand end of the entry widget.
# - A valid value is denoted by a green check in the status area.
# - An "unset" state may be set by using the menu. It may be 
#   banished by typing in or selecting a value. An unset value is
#   denoted by a yellow check in the status area.
# - Widgets can be uneditable. This means that the user cannot type
#   into them. This is denoted by a stop sign in the status area.
# - insert(value) and get() functions provide the public interface
#   for setting and querying the values.
# - The user may type-in illegal values. In this case, the displayed
#   field is unmodified but the status flag shows a cross for an
#   error. A get operation is this state will return a fail.
# - Two functions, done() and disable(), complete the public interface
#   of each widget.
# - A generic widget can be used for many purposes. All that is needed
#   is the name of the corresponding parser in entryparser.

const guientry := function(width=30, relief='none', font='',
			   background='lightgray',
			   foreground='black',
			   editablecolor='white',
			   uneditablecolor='lightgray',
			   unsetcolor='yellow',
			   illegalcolor='red',
			   borderwidth=1,
			   expand='none',
			   widgetset=dws)
{
  
  include 'unset.g';
  include 'illegal.g';
  include 'serverexists.g';
  include 'popuphelp.g';

  public := [=];
  private := [=];

  include 'toolmanagersupport.g';
  private.tms := toolmanagersupport;

  include 'catalog.g';
  
  private.catalog := catalog();

##########################################################################
#
# Private functions and data
#
  private.font := font;
  private.relief := relief;
  private.background := background;
  private.foreground := foreground;
  private.editablecolor := editablecolor;
  private.uneditablecolor := uneditablecolor;
  private.unsetcolor := unsetcolor;
  private.illegalcolor := illegalcolor;
  private.width := width;
  private.borderwidth := borderwidth;
  private.expand := expand;
  
  private.optionmenu.resources := widgetset.resources('optionmenu');
  
  # Starting from the right, first make the status indicator
  private.frame.resources := widgetset.resources('frame');

  # Defer initializing measures, etc.
  private.initmeasures := function() {
    wider private;
    if (!is_defined('dm')) {
      include 'measures.g';
      if (!is_defined('dm')) fail "defaultmeasures does not exist";
    
    }
    if (!has_field(private, 'sourcelist')) {
      private.sourcelist := split(dm.sourcelist());
    }
  }

  # Standard processing of the arguments
  private.stringarguments := function(ref its, ref value, ref default,
				      allowunset,
				      editable, options=F, hlp=unset) {
    
    its.allowunset := allowunset;
    its.editable := editable;
    its.disabled := !its.editable;
    
    if (!its.allowunset) {
      if (is_unset(value)) value := its.truedefault;
      if (is_unset(default)) default := its.truedefault;
    }

    its.originalvalue := value;
    if (length(its.originalvalue)) {
      for (i in 1:length(its.originalvalue)) {
	its.originalvalue[i]=~s/^ //g;
	its.originalvalue[i]=~s/ $//g;
      }
    }
    
    its.defaultvalue := default;
    if (length(its.defaultvalue)) {
      for (i in 1:length(its.defaultvalue)) {
	its.defaultvalue[i]=~s/^ //g;
	its.defaultvalue[i]=~s/ $//g;
      }
    }
    
    its.options := options;
    if (is_string(its.options)) {
      if (length(its.options)) {
	for (i in 1:length(its.options)) {
	  its.options[i]=~s/^ //g;
	  its.options[i]=~s/ $//g;
	}
      }
    }

    its.actualvalue := value;

    if (is_unset(hlp)) {
      if (its.editable) {
	its.hlp := spaste(its.widgetname, ': Enter value here');
      }
      else {
	its.hlp := spaste(its.widgetname, ': Value is returned here');
      }
    }
    else {
      its.hlp := hlp;
    }

    return T;

  }
    
  # Process untyped arguments
  private.untypedarguments := function(ref its, value, default, allowunset,
				       editable, options=unset, hlp=unset) {
    
    its.allowunset := allowunset;
    its.editable := editable;
    its.disabled := !its.editable;
    if (!its.allowunset) {
      if (is_unset(value)) value := its.truedefault;
      if (is_unset(default)) default := its.truedefault;
    }

    its.originalvalue := value;
    its.defaultvalue := default;
    
    its.originalvalue := value;
    its.defaultvalue := default;
    its.actualvalue := value;

    if (!is_unset(options)) {
      its.options := options;
    }

    if (is_unset(hlp)) {
      if (its.editable) {
	its.hlp := spaste(its.widgetname, ': Enter value here');
      }
      else {
	its.hlp := spaste(its.widgetname, ': Value is returned here');
      }
    }
    else {
      its.hlp := hlp;
    }

    return T;

  }

  # Check for unset
  private.checkunset := function(ref entry) {
    if (is_string(entry)) {
      all := spaste(entry);
      if(strlen(all)&&(all~m/<unset>/)) {
	val entry := unset;
      }
    }
  }

# Format error messages
  private.errormessage := function(rec, type) {
#
    include 'itemcontainer.g';
    include 'regionmanager.g';
    include 'modelmanager.g';
    include 'modlistmanager.g';
    include 'selectmanager.g';
    include 'calmanager.g';
    include 'callistmanager.g';
    include 'solvermanager.g';
    include 'slvlistmanager.g';
    include 'freqselmanager.g';
    include 'beammanager.g';
    include 'deconvmanager.g';
    include 'imcoordmanager.g';
    include 'imgfldmanager.g';
    include 'imflistmanager.g';
    include 'imwgtmanager.g';
    include 'maskmanager.g';
    include 'transfmmanager.g';
#
    if ((is_string(rec)&&strlen(rec)==0)) {
      # Don't complain about empty entries since the user
      # will see <set me>
    }
    else if (is_unset(rec)) {
      note('Could not insert unset value ',
	   priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_region(rec)) {
      note(paste('Could not insert region ', as_evalstr(rec.torecord())),
	   priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_model(rec)) {
      note(paste('Could not insert model ', as_evalstr(rec.torecord())),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_modellist(rec)) {
      note(paste('Could not insert modellist ', as_evalstr(rec.torecord())),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_selection(rec)) {
      note(paste('Could not insert selection '),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_calibration(rec)) {
      note(paste('Could not insert calibration ', as_evalstr(rec.torecord())),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_calibrationlist(rec)) {
      note(paste('Could not insert calibrationlist '),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_solver(rec)) {
      note(paste('Could not insert solver ', as_evalstr(rec.torecord())),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_solverlist(rec)) {
      note(paste('Could not insert solverlist ', as_evalstr(rec.torecord())),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_freqsel(rec)) {
      note(paste('Could not insert freqsel', as_evalstr(rec.torecord())),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_restoringbeam(rec)) {
      note(paste('Could not insert restoringbeam', as_evalstr(rec.torecord())),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_deconvolution(rec)) {
      note(paste('Could not insert deconvolution', as_evalstr(rec.torecord())),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_imagingcoord(rec)) {
      note(paste('Could not insert imagingcoord', as_evalstr(rec.torecord())),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_imagingfield(rec)) {
      note(paste('Could not insert imagingfield', as_evalstr(rec.torecord())),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_imagingfieldlist(rec)) {
      note(paste('Could not insert imagingfieldlist', 
           as_evalstr(rec.torecord())),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_imagingweight(rec)) {
      note(paste('Could not insert imagingweight', as_evalstr(rec.torecord())),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_mask(rec)) {
      note(paste('Could not insert mask', as_evalstr(rec.torecord())),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_transform(rec)) {
      note(paste('Could not insert transform', as_evalstr(rec.torecord())),
           priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_itemcontainer(rec)) {
      note(paste('Could not insert itemcontainer ', as_evalstr(rec.torecord())),
	   priority='WARN', origin=spaste('guientry.',type));
    }
    else if (is_function(rec)) {
      note('Could not insert function', 
	   priority='WARN', origin=spaste('guientry.',type));
    }
    else {
      note(paste('Could not insert ', as_evalstr(rec)),
	   priority='WARN', origin=spaste('guientry.',type));
    }
  }

  ####
  # The next are standard elements of any widget. its refers to
  # the private data of the widget and self to the public part
  # i.e. the subsequence

  # Standard get: return an illegal if the value is illegal
  private.get := function(ref its, ref self) {
    # WYSIWYG
    wider private; 
    if (is_illegal(its.actualvalue)) return illegal;
    if (its.editable) {
      entry := its.entry->get();
      ##
      ## Apparently, sometimes this is an optionmenu
      ## which does not reply to ->get()...
      ##
      if ( ! is_fail(entry) ) {
        private.checkunset(entry);
#        self.insert(entry);
      }
    }
    return its.actualvalue;
  }

  # Standard options for standard menu
  private.menu := [=];
  private.menu.standard := [=];

  private.menu.standard["Original"] := function(ref self, ref its) {
    if (self.insert(its.originalvalue)) self->value(its.actualvalue);
  }
  private.menu.standard["Default"] := function(ref self, ref its) {
    if (self.insert(its.defaultvalue)) self->value(its.actualvalue);
  }
  private.menu.standard["Unset"] := function(ref self, ref its) {
    its.actualvalue := unset;
    its.displayvalue := '';
    its.putentry();
    self->value(its.actualvalue);
  }
  private.menu.standard["Set"] := function(ref self, ref its) {
    if (self.insert(truedefault=T)) self->value(its.actualvalue);
  }
  private.menu.standard["Clear"] := function(ref self, ref its) {
    its.clearentry();
  }
  private.menu.standard["Copy"] := function(ref self, ref its) {
    include 'clipboard.g';
    dcb.copy(self.get());
  }
  private.menu.standard["Paste"] := function(ref self, ref its) {
    include 'clipboard.g';
    if (self.insert(dcb.paste())) self->value(its.actualvalue);
  }
  private.menu.standard["Save"] := function(ref self, ref its) {
    include 'recordmanager.g';
    rec := self.get();
    if (is_string(rec)) {
      name := self.get();
      if (is_defined(name)) {
	drcm.saverecord(name, symbol_value(name),
			spaste('Saved from guientry.', its.widgetname));
      }
      else {
	throw('Cannot save ', name, ' since it is not defined');
      }
    }
    else {
      result :=
	  drcm.saverecordviagui(unset, rec,
				spaste('Saved from guientry.', its.widgetname));
      if (is_fail(result)) {
	throw('Failed to save record ', result::message);
      }
    }
  }
  private.menu.standard["Restore"] := function(ref self, ref its) {
    include 'recordmanager.g';
    name := self.get();
    if (is_string(name)) {
      comments := '';
      if (drcm.contains(name)) {
	symbol_set(name, drcm.getrecord(name, comments=comments));
	note('Successfully restored ', name, ': ', comments);
      }
      else {
	throw('Failed to restore ', name, ': ', rec::message);
      }
    }
    else {
      drcm.restorerecordviagui(self.insertandemit);
    }
  }

  # Set the status, also map/unmap as necessary
  private.setstatus := function(ref its) {
    wider private;

    if (its.disabled) return F;

    if (has_field(its, 'unsetframe')) {
      if (is_unset(its.actualvalue)) {
        its.unsetframe->map();
	its.entryframe->unmap();
      }
      else {
        its.unsetframe->unmap();
	its.entryframe->map();
      }
    }
    its.entrystatus->background(private.frame.resources.background);
    if (is_unset(its.actualvalue)) {
      its.entrystatus->bitmap('tick.xbm');
      its.entrystatus->foreground('darkgreen');
    }
    else if (is_illegal(its.actualvalue)) {
      its.entrystatus->bitmap('cross.xbm');
      its.entrystatus->foreground('red');
      its.entrystatus->background('black');
    }
    else {
      if (!its.editable) {
	its.entrystatus->bitmap('noentry.xbm');
	its.entrystatus->foreground('darkred');
      } else {
	its.entrystatus->bitmap('tick.xbm');
	its.entrystatus->foreground('darkgreen');
      }
    }
  }

  # Make entry
  private.makeentry := function(ref its, ref self) {
    wider private;
    its.disabled := !its.editable;
    if (its.editable) {
      its.entryframe := widgetset.frame(its.topframe, side='right',
					borderwidth=private.borderwidth,
					expand=private.expand);
      widgetset.popuphelp(its.entryframe, its.hlp);
      its.entry := widgetset.entry(its.entryframe,
				   background=private.editablecolor,
				   width=private.width,
				   borderwidth=private.borderwidth);
      if (is_fail(its.entry)) return throw('Failed to make entry ',
					  its.entry::message);
      # Don't make the whenever until the frame is active
      whenever its.topframe->enter do {
	widgetset.popuphelp(its.entry,  its.hlp);
	whenever its.entry->return, its.entry->lve do {
	  eventname := $name;
	  # Get the value
	  entry := its.entry->get();
	  # If its the nodisplay string for this type then
	  # just emit an event
	  if (has_field(its, 'nodisplay')&&is_string(its.nodisplay)&&
	     (entry==its.nodisplay)) {
	    if(eventname=='return') self->value(its.actualvalue);
	  }
	  else {
	    private.checkunset(entry);
	    # Otherwise try to insert it and emit a value
	    # event if it worked
	    if (self.insert(entry)) {
	      if(eventname=='return') self->value(its.actualvalue);
	    }
	    else {
	      its.actualvalue := illegal;
	      its.displayvalue := '';
	    }
	  }
	}
	deactivate;
      }
    }
    else {
      its.entry := widgetset.entry(its.topframe,
				   background=private.uneditablecolor,
				   borderwidth=private.borderwidth,
				   width=private.width);
      widgetset.popuphelp(its.entry,  its.hlp);
      its.entry->disabled(T);
    }
    return T;
  }
  
  # Put an entry to the entry widget
  private.putentry := function(ref its) {
    wider private;

    if (length(its.actualvalue)>100) {
      its.displayvalue := '<array>';
    }

    its.entry->delete('start', 'end');

    private.setstatus(its);

    if (is_unset(its.actualvalue)) {
      if (has_field(its, 'entry')) {
	its.entry->insert('<unset>');
	its.entry->background(private.unsetcolor);
	return T;
      }
    }

    if (has_field(its, 'displayvalue')&&is_string(its.displayvalue)
       &&strlen(its.displayvalue)&&its.displayvalue!=' ') {
      its.entry->insert(its.displayvalue);
      if (has_field(its, 'viewright')&&its.viewright) its.entry->view('xview end')
    }

    # Take care of background colors

    its.entry->foreground('black');
    its.entry->disabled(its.disabled);
    if (its.editable&&!its.disabled) {
      its.entry->background(private.editablecolor);
    }
    else {
      its.entry->background(private.uneditablecolor);
    }
    return T;
  }

  private.clearentry := function(ref its) {
    wider private;
    its.disabled := !its.editable;
    its.entry->delete('start', 'end');
    its.entry->foreground('black');
    its.entry->background('white');
    its.entry->disabled(its.disabled);
    if (its.editable&&!its.disabled) {
      its.entry->background(private.editablecolor);
    }
    else {
      its.entry->background(private.uneditablecolor);
    }
    return T;
  }
  
  # Disable the widget and popupmenu?
  private.disable := function(ref its, disable=T) {
    wider private;
    if (!its.editable) return F;
    if (has_field(its, 'wrenchbutton')&&is_agent(its.wrenchbutton)) {
      if (disable&&!its.disabled) {
	its.wrenchbutton->disabled(disable);
      }
      else if (!disable&&its.disabled) {
	its.wrenchbutton->disabled(disable);
      }
    }
    if (disable&&!its.disabled) {
      its.topframe->disable();
      if (has_field(its, 'menu')&&has_field(its.menu, 'disable')) {
	its.menu.disable();
      }
      if (has_field(its, 'entry')&&is_agent(its.entry)) {
	its.entry->disabled(T);
	its.entry->background(private.uneditablecolor);
      }
    }
    else if (!disable&&its.disabled) {
      its.topframe->enable();
      if (has_field(its, 'menu')&&has_field(its.menu, 'enable')) {
	its.menu.enable();
      }
      if (has_field(its, 'entry')&&is_agent(its.entry)) {
        if (its.editable) {
	  its.entry->disabled(F);
	  its.entry->background(private.editablecolor);
	  if (has_field(its, 'actualvalue')&&is_unset(its.actualvalue)) {
	    its.entry->background(private.unsetcolor);
	  }
	}
      }
    }
    its.disabled := disable;
    return private.setstatus(its);
  }

  # Add standard versions of private and public functions. These
  # Can be overridden afterwards
  private.makestandardfunctions := function(ref its, ref self) {

    its.actualvalue := unset;
    its.displayvalue := '';

    # Put an entry to the entry box
    its.putentry := function() {
      wider its, private;
      return private.putentry(its);
    }
    # Clear the entry box
    its.clearentry := function() {
      wider its, private;
      return private.clearentry(its);
    }
    ########
    # Public interface:
    its.contexts := [=];

    # Add to the widget contexts
    self.setcontexts := function(contexts) {
      wider its;
      its.contexts := contexts;
      return T;
    }
    # Add to the widget contexts
    self.setcontext := function(name, value) {
      wider its;
      its.contexts[name] := value;
      return T;
    }
    # Return the widget contexts
    self.getcontexts := function() {
      wider its;
      return its.contexts;
    }
    # Does this widget have the following context
    self.hascontext := function(context) {
      wider its;
      return has_field(its.contexts, context);
    }
    # Get the individual context
    self.getcontext := function(context) {
      wider its;
      if (has_field(its.contexts, context)) {
	return its.contexts[context];
      }
      else {
	return unset;
      }
    }
    self.setwidth := function(value=unset) {
      wider its, self;
      if (is_unset(value)) value:=private.width;
      if (has_field(its, 'entry')) its.entry->width(value);
      return T;
    }
    # Add to the wrench
    self.addtowrench := function(name, fun) {
      wider its, private;
      if (is_function(fun)) {
	its.wrench.write[name] := fun;
	whenever its.topframe->enter do {
	  name := its.wrench.write[len(its.wrench.write)];
	  its.wrenchmenu[name] :=
	      widgetset.button(its.wrenchbutton, name,
			       borderwidth=private.borderwidth);
	  its.busy := T;
	  whenever its.wrenchmenu[name]->press do {
	    if(!its.busy) {
	      its.busy := T;
	      private.processmenu(its, self, $agent->text());
	      its.busy := F;
	    }
	  }
	  deactivate;
	}
      }
      else {
	return throw(paste('Non-function specified for wrench button ', name));
      }
    }
    # Insert and emit
    self.insertandemit := function(rec=unset) {
      wider self, its;
      if (self.insert(rec)) {
	self->value(its.actualvalue);
      }
    }
    # Insert a value
    self.insert := function(rec=unset, truedefault=F) {
      wider its, private;
      include 'entryparser.g';

      if (!has_field(its, 'parser')) {
	return throw('Entry parser not specified',
		     origin=spaste('guientry.',its.parser));
      }

      if (!is_record(dep)||!has_field(dep, its.parser)||
	 !is_function(dep[its.parser])) {
	return throw('Entry parser not valid',
		     origin=spaste('guientry.',its.parser));
      }
      
      if (truedefault) rec:=its.truedefault;

      if (dep[its.parser](rec, its.allowunset, its.actualvalue,
			 its.displayvalue)) {
	its.putentry();
	return T;
      }
      else {
	private.errormessage(rec, its.parser);
	private.setstatus(its);
	return F;
      }
    }
    # Get the current value
    self.get := function() {
      wider its, private;
      return private.get(its, self);
    }
    self.clear := function() {
      wider its;
      return its.clearentry();
    }
    # Disable the widget
    self.disable := function(disable=T) {
      wider its, private;
      if (!its.editable) return F;
      return private.disable(its, disable);
    }
    # Done function
    self.done := function() {
      wider its, self;
      # Remove in reverse

      for (field in "codesbutton entry leftframe entryframe entryholderframe unitsbutton unsetlabel unsetframe") {
        if (has_field(its, field)) {
	  if (has_field(its[field], 'done')) {
	    its[field].done();
	  }
	  if (is_agent(its[field])) {
	    popupremove(its[field]);
	  }
	  val its[field] := F;
	}
      }
      if (has_field(its, 'wrenchmenu')) {
	names := field_names(its.wrenchmenu);
	if (len(names) > 0) {
	  for (field in names[len(names):1]) {
	    if (is_agent(its.wrenchmenu[field])) {
	      if (has_field(its.wrenchmenu[field], 'done')) {
		its.wrenchmenu[field].done();
	      }
	      its.wrenchmenu[field]->unmap();
	      popupremove(its.wrenchmenu[field]);
	    }
	  }
	}
      }
      popupremove(its.wrenchbutton);
      val its.wrenchbutton := F;
      popupremove(its.entrystatus);
      val its.entrystatus := F;
      its.topframe := F;
      val its := F;
      val self := F;
      return T;
    }
    # Set the status externally
    self.setstatus := function(valid = T) {
      wider private;
      if (valid) {
	its.entrystatus->bitmap('tick.xbm');
	its.entrystatus->foreground('darkgreen');
	private.frame.resources := widgetset.resources('frame');
	its.entrystatus->background(private.frame.resources.background);
      } else {
	its.entrystatus->bitmap('cross.xbm');
	its.entrystatus->foreground('red');
	its.entrystatus->background('black');
      }
    }
  }

  private.processmenu := function(ref its, ref self, menuoption) {
    wider private;
    if (has_field(its.wrench, 'standard')&&
       any(field_names(its.wrench.standard)==menuoption)) {
      its.wrench.standard[menuoption](self, its);
    }
    else if (has_field(its.wrench, 'readonly')&&
	    any(field_names(its.wrench.readonly)==menuoption)) {
      its.wrench.readonly[menuoption](self, its);
    }
    else if (has_field(its.wrench, 'write')&&
	    any(field_names(its.wrench.write)==menuoption)) {
      its.wrench.write[menuoption](self, its);
    }
    private.setstatus(its);
  }

  private.makestandard := function(ref its, ref self, parent, title,
				   addunsetframe=F, allowclear=T) {
    wider private;
    # Make top frame
    if (!is_agent(parent)) {
      its.topframe:=widgetset.frame(side='right', title=title,
				    expand=private.expand,
				    relief='flat',
				    borderwidth=private.borderwidth);
    }
    else {
      its.topframe:=widgetset.frame(parent, side='right',
				    expand=private.expand,
				    relief='flat',
				    borderwidth=private.borderwidth);
    }
    # Do we need an unset frame?
    if (addunsetframe) {
      its.unsetframe := widgetset.frame(its.topframe,
					side='right',
					expand=private.expand,
					borderwidth=private.borderwidth);
      its.unsetframe->unmap();
      its.unsetlabel := widgetset.label(its.unsetframe, '<unset>',
					background=private.unsetcolor,
					borderwidth=private.borderwidth);
    }
    # We bind enter so that some options can be loaded on entry
    its.topframe->bind('<Enter>', 'enter');
    
    its.entrystatus :=
	widgetset.button(its.topframe, '', bitmap='',
			 background=private.frame.resources.background,
			 relief='flat');
    if (!its.editable) {
      its.entrystatus->bitmap('noentry.xbm');
      its.entrystatus->foreground('darkred');
    } else {
      its.entrystatus->bitmap('tick.xbm');
      its.entrystatus->foreground('darkgreen');
    }
    
    if (!has_field(its, 'wrench')) its.wrench := [=];
    if (!has_field(its.wrench, 'standard'))
	its.wrench.standard := private.menu.standard;
    if (!has_field(its.wrench, 'readonly')) its.wrench.readonly := [=];
    if (!has_field(its.wrench, 'write')) its.wrench.write := [=];
    if (!has_field(its.wrench, 'active')) its.wrench.active := [=];

    # Set up correct combination of wrench items
    if (its.editable) {
      poptions := field_names(its.wrench.standard);
      if (!its.recordbased) {
	poptions =~ s/Save//g;
	poptions =~ s/Restore//g;
      }
    }
    else {
      if (its.recordbased) {
	poptions := "Copy";
      }
      else {
	poptions := "Copy Save";
      }
    }
    if (!allowclear) {
      poptions =~ s/Clear//g;
    }
    if (!its.allowunset) {
      poptions =~ s/Unset//g;
      poptions =~ s/Set//g;
    }
    poptions =~ s/ //g;
    poptions := [field_names(its.wrench.readonly), poptions];
    if (its.editable) {
      poptions := [field_names(its.wrench.write), poptions];
    }
    its.poptions := poptions;

    # Make the spanner
    its.wrenchbutton :=
	widgetset.button(its.topframe, 'Menu', bitmap='spanner.xbm', 
			 type='menu', relief='raised',
			 borderwidth=private.borderwidth);

    its.wrenchmenu := [=];

    whenever its.topframe->enter do {
      widgetset.popuphelp(its.wrenchbutton,
			  'Menu for various operations on the entry');
      widgetset.popuphelp(its.entrystatus, 'Status of entry:\n green tick->valid value,\n red cross->invalid value, \n no entry->no entry allowed');
      for (poption in its.poptions) {
	if ((poption!='')&&(poption!=' ')) {
	  its.wrenchmenu[poption] :=
	      widgetset.button(its.wrenchbutton,
			       poption,
			       borderwidth=private.borderwidth);
	  if(is_agent(its.wrenchmenu[poption])) {
	    its.busy := F;
	    whenever its.wrenchmenu[poption]->press do {
	      if(!its.busy) {
		its.busy := T;
		private.processmenu(its, self, $agent->text());
		its.busy := F;
	      }
	    }
	  }
	}
      }
      deactivate;
    }

    if (has_field(its, 'makeentry')) {
      if (is_fail(its.makeentry(its, self))) fail;
    }
    else {
      if (is_fail(private.makeentry(its, self))) fail;
    }

    # Uncomment this to debug event streams
    if(0) {
      if(is_agent(its.entry)) {
	whenever its.entry->* do {
	  print 'widget ', its.widgetname, ' event ', $name;
	}
      }
    }

  }

  private.genericmsindex := subsequence(type, parser='array',
					parent=unset, value=[], default=[],
					options='', allowunset=F, editable=T,
					maxdisplay=100,
					hlp=unset) {
    
    wider private;
    widgetset.tk_hold();
    
    its := [=];
    its.recordbased := F;
    its.truedefault := [];
    its.parser := parser;
    its.nodisplay := spaste('<',type,'>');
    its.widgetname := type;
    if (is_integer(maxdisplay) && maxdisplay>0) {
       its.maxdisplay := maxdisplay;
    } else {
       its.maxdisplay := 100;
    }

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }

    private.makestandardfunctions(its, self);

    its.putentry := function() {
      wider its, private;
      if (length(its.actualvalue)>its.maxdisplay) {
	its.displayvalue := its.nodisplay;
      }
      return private.putentry(its);
    }

    its.makeentry := function(ref its, ref self) {
      wider private, its, self;
      its.disabled := !its.editable;
      if (its.editable) {
	its.entryframe := widgetset.frame(its.topframe, side='right',
					  expand=private.expand,
					  borderwidth=private.borderwidth);
	widgetset.popuphelp(its.entryframe, its.hlp);
	its.entry := widgetset.entry(its.entryframe,
				     background=private.editablecolor,
				     width=private.width,
				     borderwidth=private.borderwidth);
	whenever its.topframe->enter do {
	  widgetset.popuphelp(its.entry,  its.hlp);
	  whenever its.entry->return, its.entry->lve  do {
	    # Get the value
	    eventname := $name;
	    entry := its.entry->get();
	    # If its the nodisplay string for this type then
	    # just emit an event
	    if (has_field(its, 'nodisplay')&&is_string(its.nodisplay)&&
	       (entry==its.nodisplay)) {
	      if(eventname=='return') self->value(its.actualvalue);
	    }
	    else {
	      private.checkunset(entry);
	      # Otherwise try to insert it and emit a value
	      # event if it worked
	      if (self.insert(entry)) {
		if(eventname=='return') self->value(its.actualvalue);
	      }
	      else {
		its.actualvalue := illegal;
		its.displayvalue := '';
	      }
	    }
	  }
	  deactivate;
	}
      }
      else {
	its.entry := widgetset.entry(its.topframe,
				     background=private.uneditablecolor,
				     borderwidth=private.borderwidth,
				     width=private.width);
	widgetset.popuphelp(its.entry,  its.hlp);
	its.entry->disabled(T);
      }
      return T;
    };
    its.wrench := [=];
    its.wrench.write := [=];
    its.wrench.write['From MS'] := function(ref self, ref its) {
      include 'gopher.g';
      if (self.hascontext('ms')) {
        dgo.fromms(self.getcontext('ms'), type, self.insertandemit);
      }
      else {
        dgo.fromms(unset, type, self.insertandemit);
      } 
    }
    private.makestandard(its, self, parent, 
			 title=paste('AIPS++', type, 'Chooser'));
#    ok := self.insert(its.defaultvalue);
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }

  private.genericmsstring := subsequence(type, parser='string',
					parent=unset, value='', default='',
					options='', allowunset=F, editable=T,
					onestring=F, hlp=unset) {
    
    wider private;
    widgetset.tk_hold();

    its := [=];
    its.recordbased := F;
    its.truedefault := '';

    its.parser := parser;
    its.widgetname := type;
    if (is_fail(private.stringarguments(its, value, default, allowunset,
				       editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);

    its.viewright := T;
    its.onestring := onestring;
    its.hlp := hlp;                # Overwrite one stringarguments put here

    its.putentry := function() {
      wider its, private;
      height := len(its.actualvalue);
      its.entry->delete('start', 'end');
      private.setstatus(its);

      if (is_unset(its.actualvalue)) {
	if (has_field(its, 'entry')) {
	  its.entry->disabled(F);
	  if (its.onestring) {
	    its.entry->insert('<unset>');
	  }
	  else {
	    its.entry->insert('<unset>', 'start');
	    its.entry->height(1);
	    its.entry->see('start');
	  }
	  its.entry->background(private.unsetcolor);
	  its.entry->disabled(!its.editable);
	  return T;
	}
      }
      else {
	its.entry->disabled(F);
        if (its.onestring&&is_string(its.displayvalue)) {
	  its.entry->insert(its.displayvalue);
	}
	else {
	  if (is_string(its.displayvalue)) {
	    its.entry->insert(its.displayvalue, 'start');
	  }
	  its.entry->height(min(3,height));
	  its.entry->see('start');
	}
	its.entry->foreground('black');
	its.entry->background('white');
	its.entry->disabled(its.disabled);
	if (its.editable&&!its.disabled) {
	  its.entry->background(private.editablecolor);
	}
	else {
	  its.entry->background(private.uneditablecolor);
	}
	its.entry->disabled(!its.editable);
      }
      return T;
    }

    its.clearentry := function() {
      wider its, private;
      its.entry->delete('start', 'end');
      if (!its.onestring) {
	its.entry->height(1);
      }
      return T;
    }

    its.adjustheight := function() {
      wider its;
      itxt := as_byte(its.entry->get('start', 'end'));
      height := min(3, len(itxt[itxt == 10]));
      if (height != its.height) {
 	its.height := height;
 	its.entry->height(its.height);
      }
    }

    its.makeentry := function(ref its, ref self) {
      
      wider private;
      its.height := 1;
      its.disabled := !its.editable;
      its.entryframe := widgetset.frame(its.topframe, side='right',
					expand=private.expand,
					borderwidth=private.borderwidth);
      local hlpstring;
      if (is_unset(its.hlp)) {
         hlpstring := 'Multiple strings will be displayed on different lines: use the up and down arrow keys to scroll up and down in the list of strings';
         if (its.onestring) {
            hlpstring := 'Enter string here';
         }
      } else {
         hlpstring := its.hlp;
      }      
      widgetset.popuphelp(its.entryframe, hlpstring);

      if (its.editable) {
        if (its.onestring) {
	  its.entry := widgetset.entry(its.entryframe,
				       background=private.editablecolor,
				       width=private.width,
				       borderwidth=private.borderwidth);
          whenever its.entry->return, its.entry->lve  do {
	    eventname := $name;
	    if (self.insert(self.get())) {
	      if(eventname=='return') self->value(its.actualvalue);
	    }
	  }
	}
	else {
	  its.entry := widgetset.text(its.entryframe,
				      background=private.editablecolor,
				      width=private.width,
				      height=1,
				      borderwidth=private.borderwidth);
	  # Check for \n every character!
          whenever its.entry->yscroll do {
	    its.adjustheight();
	  }
	}
      }
      else {
        if (its.onestring) {
	  its.entry := widgetset.entry(its.entryframe,
				       background=private.uneditablecolor,
				       width=private.width,
				       borderwidth=private.borderwidth);
	}
	else {
	  its.entry := widgetset.text(its.entryframe,
				      background=private.uneditablecolor,
				      width=private.width,
				      height=1,
				      borderwidth=private.borderwidth);
	  # Check for \n every character!
          whenever its.entry->yscroll do {
	    its.adjustheight();
	  }
	}
	its.entry->disabled(T);
      }
      widgetset.popuphelp(its.entry, hlpstring);
      its.clearentry();
    }
  
    self.get := function() {
      wider private, its;
      if (is_illegal(its.actualvalue)) return illegal;
      entry := its.displayvalue;
      if (its.editable&&!its.disabled) {
        if (its.onestring) {
	  entry := its.entry->get();
	}
	else {
	  entry := split(its.entry->get('start', 'end'), '\n');
	}
	private.checkunset(entry);
#	self.insert(entry);
      }
      return its.actualvalue;
    }

    self.insert := function(rec=unset, truedefault=F) {
      wider its, private;
      include 'entryparser.g';
      if (!is_record(dep)||!has_field(dep, its.parser)||
	 !is_function(dep[its.parser])) {
	return throw('Entry parser not valid',
		     origin=spaste('guientry.',its.parser));
      }
      
      if (truedefault) rec:=its.truedefault;

      if (dep[its.parser](rec, its.allowunset, its.actualvalue,
			 its.displayvalue)) {
	its.putentry();
	return T;
      }
      else {
	private.errormessage(rec, its.parser);
	private.setstatus(its);
	return F;
      }
    }

    its.wrench := [=];
    its.wrench.write := [=];
    its.wrench.write['From MS'] := function(ref self, ref its) {
      include 'gopher.g';
      if (self.hascontext('ms')) {
        dgo.fromms(self.getcontext('ms'), type, self.insertandemit);
      }
      else {
        dgo.fromms(unset, type, self.insertandemit);
      } 
    }
    private.makestandard(its, self, parent, 
			 title=paste('AIPS++', type, 'Chooser'));
    ok := self.insert(its.defaultvalue);
    ok := widgetset.tk_release();
  }

  private.generic := subsequence(type, parent=unset,
				 value='', default='', allowunset=F,
				 editable=T, options=unset, hlp=unset) {
   
    wider private;
    widgetset.tk_hold();
    
    its := [=];
    its.recordbased := T;
    its.truedefault := F;
    
    its.parser := type;
    its.widgetname := type;
    
    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);
  
    its.makeentry := function(ref its, ref self) {
      wider private, its, self;
      its.disabled := !its.editable;
      if (its.editable) {
	its.entryframe := widgetset.frame(its.topframe, side='right',
					  expand=private.expand,
					  borderwidth=private.borderwidth);
	widgetset.popuphelp(its.entryframe, its.hlp);
	its.entry := widgetset.entry(its.entryframe,
				     background=private.editablecolor,
				     width=private.width,
				     borderwidth=private.borderwidth);
	whenever its.topframe->enter do {
	  widgetset.popuphelp(its.entry,  its.hlp);
	  whenever its.entry->return, its.entry->lve  do {
	    # Get the value
	    eventname := $name;
	    entry := its.entry->get();
	    # If its the nodisplay string for this type then
	    # just emit an event
	    if (has_field(its, 'nodisplay')&&is_string(its.nodisplay)&&
	       (entry==its.nodisplay)) {
	      if(eventname=='return') self->value(its.actualvalue);
	    }
	    else {
	      private.checkunset(entry);
	      # Otherwise try to insert it and emit a value
	      # event if it worked
	      if (self.insert(entry)) {
		if(eventname=='return') self->value(its.actualvalue);
	      }
	      else {
		its.actualvalue := illegal;
		its.displayvalue := '';
	      }
	    }
	  }
	  deactivate;
	}
      }
      else {
	its.entry := widgetset.entry(its.topframe,
				     background=private.uneditablecolor,
				     borderwidth=private.borderwidth,
				     width=private.width);
	widgetset.popuphelp(its.entry,  its.hlp);
	its.entry->disabled(T);
      }
      return T;
    };
    private.makestandard(its, self, parent, addunsetframe=T,
			 title=paste('AIPS++', type, 'Chooser'));
#    ok := self.insert(its.defaultvalue);
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
    
  }

  private.genericitem := subsequence(ref createdefaultmanager, type,
                                           parent, value, default, options, 
                                           allowunset, editable, hlp)
  {
    # Subsequence used in defining generic data item types (e.g. model)
    #
    wider private;
    widgetset.tk_hold();

    its := [=];
    its.recordbased := T;
    its.truedefault := [=];

    if (!allowunset&&is_unset(value)) value := spaste('my', type);
    if (!allowunset&&is_unset(default)) default := spaste('my', type);
    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);
    

    its.parser := type;
    its.widgetname := type;

    # Create related strings for this type
    mantype := spaste(type, 'manager');
    tmp := split(type, '');
    tmp[1] := to_upper(tmp[1]);
    tmp := spaste(tmp);
    wrenchwrite := spaste(tmp, 'Manager');
    title1 := spaste(tmp, ' data item manager');
    title2 := spaste('AIPS++', tmp, ' Manager');

    # Ensure that the default manager is available
    defmanname := createdefaultmanager();
    defman := ref symbol_value(defmanname);

    if (!serverexists(defmanname, mantype, defman)) {
      widgetset.tk_release();
      messg := spaste('The default ', mantype, ' ', defmanname, 
        ' is either not running or not valid');
      return throw (messg, origin=spaste('guientry.', type));
    };

    if (!serverexists('tm', 'toolmanager', tm)) {
      widgetset.tk_release();
      return throw ('The default toolmanager tm is either not running or not valid', origin='guientry.genericitem');
    };

    its.whenever := -1;
    
    if (its.editable) background := private.editablecolor;
    
    its.wrench := [=];

    self.addtowrench := function(name, fun) {
      wider its;
      its.wrench.write[name] := fun;
    }

    # Insert a value
    self.insert := function(rec=unset, truedefault=F) {
      wider its, private;
      include 'entryparser.g';

      if (!has_field(its, 'parser')) {
	return throw('Entry parser not specified',
		     origin=spaste('guientry.',its.parser));
      }

      if (!is_record(dep)||!has_field(dep, its.parser)||
	 !is_function(dep[its.parser])) {
	return throw('Entry parser not valid',
		     origin=spaste('guientry.',its.parser));
      }
      
      if (truedefault) rec:=its.truedefault;

      if (dep[its.parser](rec, its.allowunset, its.actualvalue,
			 its.displayvalue)) {
	its.putentry();
	return T;
      }
      else {
	# Try converting from a record
	global __guientry_holder;
	command := spaste('__guientry_holder:=',defmanname,'[1]()');
	eval(command);
	global __guientry_value;
	__guientry_value := rec;
	command := '__guientry_holder.fromrecord(__guientry_value)';
	eval(command);
	rec := __guientry_holder;
	if (dep[its.parser](rec, its.allowunset, its.actualvalue,
			   its.displayvalue)) {
	  its.putentry();
	  return T;
	}
	else {
	  private.errormessage(rec, its.parser);
	  private.setstatus(its);
	  return F;
	}
      }
    }
    self.get := function() {
      wider its, private;
      if (is_illegal(its.actualvalue)) return illegal;
      if (its.editable) {
	entry := its.entry->get();
	private.checkunset(entry);
#	self.insert(entry);
      }
      private.setstatus(its);
      return its.actualvalue;
    }
    self.insertandemit := function(rec) {
      wider self, private;
      t := self.insert(rec);
      if (t) {
	self->value(its.actualvalue);
      }
      # De-register the Send button callback function in the toolmanager
      private.tms.deregistersendcallback();
      return t;
    }

    self.done := function() 
    {
      wider its, self;
      val its := F;
      val self := F;

      return T;
    }
    its.wrench.write['Create'] := function(ref self, ref its) {
      wider private;
      include 'toolmanager.g';
      if (!tm.isregistered(defmanname)) {
        tm.registertool(defmanname, status='Running');
      };
      # Register the Send button callback function in the toolmanager
      private.tms.registersendcallback(self.insertandemit);
      private.tms.registerlocationframe(its.topframe);
      # Now show the itemmanager
      tm.usegui();
      tm.showitemmanager(defmanname, title=title1);
    }
    private.makestandard(its, self, parent, addunsetframe=T, title=title2);
#    ok := self.insert(its.defaultvalue);
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }

#########################################################################
#
# Start of public functions

# antennas baselines spectralwindows polarizations fields 
# datadescriptions msselect
  public.antennas := function(parent=unset, value=[], default=[],
			      options='', allowunset=F, editable=T,
			      maxdisplay=100, hlp=unset) {
    return private.genericmsindex('antennas', 'array',
				  parent, value, default,
				  options, allowunset, editable,
				  maxdisplay, hlp);
  }
    
  public.baselines := function(parent=unset, value=[], default=[],
			       options='', allowunset=F, editable=T,
			       maxdisplay=100, hlp=unset) {
    return private.genericmsindex('baselines', 'array',
				  parent, value, default,
				  options, allowunset, editable,
				  maxdisplay, hlp);
  }
    
  public.fields := function(parent=unset, value=[], default=[],
			    options='', allowunset=F, editable=T,
			    maxdisplay=100, hlp=unset) {
    return private.genericmsindex('fields', 'array',
				  parent, value, default,
				  options, allowunset, editable,
				  maxdisplay, hlp);
  }
    
  public['fieldnames'] := subsequence(parent=unset, value=[], default=[],
			      options='', allowunset=F, editable=T,
			      onestring=F, hlp=unset) {
    
    
    self := ref private.genericmsstring('fieldnames', 'string',
				       parent, value, default,
				       options, allowunset, editable,
				       onestring, hlp);
  }
    
  public['polarizations'] := subsequence(parent=unset, value=[], default=[],
			      options='', allowunset=F, editable=T,
			      maxdisplay=100, hlp=unset) {
    
    
    self := ref private.genericmsindex('polarizations', 'array',
				       parent, value, default,
				       options, allowunset, editable,
				       maxdisplay, hlp);
  }
    
  public['spectralwindows'] := subsequence(parent=unset, value=[], default=[],
			      options='', allowunset=F, editable=T,
			      maxdisplay=100, hlp=unset) {
    
    
    self := ref private.genericmsindex('spectralwindows', 'array',
				       parent, value, default,
				       options, allowunset, editable,
				       maxdisplay, hlp);
  }
    
  public['datadescriptions'] := subsequence(parent=unset, value=[], default=[],
			      options='', allowunset=F, editable=T,
			      maxdisplay=100, hlp=unset) {
    
    
    self := ref private.genericmsindex('datadescriptions', 'array',
				       parent, value, default,
				       options, allowunset, editable,
				       maxdisplay, hlp);
  }
    
  public['msselect'] := subsequence(parent=unset, value=[], default=[],
			      options='', allowunset=F, editable=T,
			      maxdisplay=100, hlp=unset) {
    
    
    self := ref private.genericmsindex('msselect', 'array',
				       parent, value, default,
				       options, allowunset, editable,
				       maxdisplay, hlp);
  }
    
  public.array := subsequence(parent=unset, value=[], default=[],
			      options='', allowunset=F, editable=T,
			      maxdisplay=100, hlp=unset) {
    
    wider private;
    widgetset.tk_hold();
    
    its := [=];
    its.recordbased := F;
    its.truedefault := [];
    its.parser := 'array';
    its.nodisplay := '<array>';
    its.widgetname := 'array';
    if (is_integer(maxdisplay) && maxdisplay>0) {
       its.maxdisplay := maxdisplay;
    } else {
       its.maxdisplay := 100;
    }

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }

    private.makestandardfunctions(its, self);

    its.putentry := function() {
      wider its, private;
      if (length(its.actualvalue)>its.maxdisplay) {
	its.displayvalue := its.nodisplay;
      }
      return private.putentry(its);
    }

    its.makeentry := function(ref its, ref self) {
      wider private, its, self;
      its.disabled := !its.editable;
      if (its.editable) {
	its.entryframe := widgetset.frame(its.topframe, side='right',
					  expand=private.expand,
					  borderwidth=private.borderwidth);
	widgetset.popuphelp(its.entryframe, its.hlp);
	its.entry := widgetset.entry(its.entryframe,
				     background=private.editablecolor,
				     width=private.width,
				     borderwidth=private.borderwidth);
	whenever its.topframe->enter do {
	  widgetset.popuphelp(its.entry,  its.hlp);
	  whenever its.entry->return, its.entry->lve  do {
	    # Get the value
	    entry := its.entry->get();
	    eventname := $name;
	    # If its the nodisplay string for this type then
	    # just emit an event
	    if (has_field(its, 'nodisplay')&&is_string(its.nodisplay)&&
	       (entry==its.nodisplay)) {
	      if(eventname=='return') self->value(its.actualvalue);
	    }
	    else {
	      private.checkunset(entry);
	      # Otherwise try to insert it and emit a value
	      # event if it worked
	      if (self.insert(entry)) {
		if(eventname=='return') self->value(its.actualvalue);
	      }
	      else {
		its.actualvalue := illegal;
		its.displayvalue := '';
	      }
	    }
	  }
	  deactivate;
	}
      }
      else {
	its.entry := widgetset.entry(its.topframe,
				     background=private.uneditablecolor,
				     borderwidth=private.borderwidth,
				     width=private.width);
	widgetset.popuphelp(its.entry,  its.hlp);
	its.entry->disabled(T);
      }
      return T;
    };
    its.wrench := [=];
    its.wrench.write := [=];
    its.wrench.write['Edit'] := function(ref self, ref its) {
      value := self.get();
      if (!is_unset(value)&&!is_fail(value)) {
	include 'newab.g';
	ab:=newab(value, title=its.displayvalue, readonly=F);
	if (!is_fail(ab)) {
	  if (self.insert(value)) self->value(its.actualvalue);
	}
      }
    }
    its.wrench.readonly := [=];
    its.wrench.readonly['View'] := function(ref self, ref its) {
      value := self.get();
      if (!is_unset(value)&&!is_fail(value)) {
	include 'newab.g';
	ab:=newab(value, title=its.displayvalue, readonly=T);
      }
    }
    private.makestandard(its, self, parent, 
			 title=paste('AIPS++ Array Chooser'));
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }

#########################################################################
#
# Start of public functions
  
  public.booleanarray := subsequence(parent=unset, value=[T], default=[T],
				     options='', allowunset=F, editable=T,
				     maxdisplay=100, hlp=unset) {
    
    wider private;
    widgetset.tk_hold();
    
    #####################################################################
    # Private functions and data
    
    its := [=];
    its.recordbased := F;
    its.truedefault := [F];
    its.parser := 'booleanarray';
    its.widgetname := 'booleanarray';
    its.nodisplay := '<array>';
    if (is_integer(maxdisplay) && maxdisplay>0) {
       its.maxdisplay := maxdisplay;
    } else {
       its.maxdisplay := 100;
    }

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }

    private.makestandardfunctions(its, self);

    its.putentry := function() {
      wider its, private;
      if (length(its.actualvalue)>its.maxdisplay) {
	its.displayvalue := its.nodisplay;
      }
      return private.putentry(its);
    }
    its.makeentry := function(ref its, ref self) {
      wider private, its, self;
      its.disabled := !its.editable;
      if (its.editable) {
	its.entryframe := widgetset.frame(its.topframe, side='right',
					  expand=private.expand,
					  borderwidth=private.borderwidth);
	widgetset.popuphelp(its.entryframe, its.hlp);
	its.entry := widgetset.entry(its.entryframe,
				     background=private.editablecolor,
				     width=private.width,
				     borderwidth=private.borderwidth);
	whenever its.topframe->enter do {
	  widgetset.popuphelp(its.entryframe,  its.hlp);
	  widgetset.popuphelp(its.entry,  its.hlp);
	  whenever its.entry->return, its.entry->lve  do {
	    # Get the value
	    eventname := $name;
	    entry := its.entry->get();
	    # If its the nodisplay string for this type then
	    # just emit an event
	    if (has_field(its, 'nodisplay')&&is_string(its.nodisplay)&&
	       (entry==its.nodisplay)) {
	      if(eventname=='return') self->value(its.actualvalue);
	    }
	    else {
	      private.checkunset(entry);
	      # Otherwise try to insert it and emit a value
	      # event if it worked
	      if (self.insert(entry)) {
		if(eventname=='return') self->value(its.actualvalue);
	      }
	      else {
		its.actualvalue := illegal;
		its.displayvalue := '';
	      }
	    }
	  }
	  deactivate;
	}
      }
      else {
	its.entry := widgetset.entry(its.topframe,
				     background=private.uneditablecolor,
				     borderwidth=private.borderwidth,
				     width=private.width);
	widgetset.popuphelp(its.entry,  its.hlp);
	its.entry->disabled(T);
      }
      return T;
    };
    #####################################################################
    # Setup initial values
    
    its.wrench := [=];
    its.wrench.write := [=];
    its.wrench.write['Edit'] := function(ref self, ref its) {
      value := self.get();
      if (!is_unset(value)&&!is_fail(value)) {
	include 'newab.g';
	ab:=newab(value, title=its.displayvalue, readonly=F);
	if (!is_fail(ab)) {
	  if (self.insert(value)) self->value(its.actualvalue);
	}
      }
    }
    its.wrench.readonly := [=];
    its.wrench.readonly['Edit'] := function(ref self, ref its) {
      value := self.get();
      if (!is_unset(value)&&!is_fail(value)) {
	include 'newab.g';
	ab:=newab(value, title=its.displayvalue, readonly=T);
      }
    }
    private.makestandard(its, self, parent,
			 title=paste('AIPS++ Boolean Array Chooser'));

    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }

  public.boolean := subsequence(parent=unset, value=T, default=T,
				options='', allowunset=F, editable=T,
				hlp=unset)
  {

    #####################################################################
    # Private functions and data
    
    its := [=];
    its.recordbased := F;
    its.truedefault := T;
    its.parser := 'boolean';
    its.widgetname := 'boolean';

    widgetset.tk_hold();

    if (!allowunset) {
      if (is_fail(private.untypedarguments(its, as_boolean(value),
					  as_boolean(default), allowunset,
					  editable, ['True', 'False'],
					  hlp))) {
	widgetset.tk_release();
	fail;
      }
    } else {
      if (is_fail(private.untypedarguments(its, value, default,
					   allowunset, editable, 
					   ['True', 'False'], hlp))) {
	widgetset.tk_release();
	fail;
      }
    }
    
    private.makestandardfunctions(its, self);

    its.putentry := function() {
      wider its, private;
      its.entry.disabled(F);
      if (!is_unset(its.actualvalue)) its.entry.selectlabel(its.displayvalue);
      if (its.disabled) its.entry.disabled(T);
      return private.putentry(its);
    }
    its.clearentry := function() {
      wider its, private;
      return F;
    }
    its.makeentry := function(ref its, ref self) {
      wider private;
      its.entryframe := widgetset.frame(its.topframe, expand=private.expand,
					side='right',
					borderwidth=private.borderwidth);
      widgetset.popuphelp(its.entryframe, its.hlp);
      its.entry :=
	  widgetset.optionmenu(its.entryframe, its.options,
			       borderwidth=private.borderwidth,
			       background=private.optionmenu.resources.background);
      whenever its.entry->select do {
	# Only report valid values
	self.insert($value.label);
	self->value(its.actualvalue);
      }
    }
    self.disable := function(disable=T) {
      wider its, private;
      if (!its.editable) return F;
      if (disable&&!its.disabled) {
	its.entry.disabled(disable);
      }
      else if (!disable&&its.disabled) {
	its.entry.disabled(disable);
      }
      return private.disable(its, disable);
    }
    private.makestandard(its, self, parent, addunsetframe=T,
			 title='AIPS++ Boolean Chooser', allowclear=F);
    

    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }
  
  public.check := subsequence(parent=unset, value="", default="",
			      options="", allowunset=F,
			      editable=T, nperline=4, hlp=unset)
  {
    
    wider private;
    widgetset.tk_hold();
    
    its := [=];
    its.recordbased := F;
    its.nperline := nperline;
    its.truedefault := options[1];

    its.parser := 'string';
    its.widgetname := 'check';

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }

    private.makestandardfunctions(its, self);

    its.putentry := function() {
      wider its, private;
      for (lab in its.options) {
	its.entry[lab]->enable();
	its.entry[lab]->state(F);
	if (its.disabled) its.entry[lab]->disable();
      }
      if (!is_unset(its.actualvalue)) {
	for (lab in split(its.displayvalue)) {
          its.entry[lab]->enable();
	  its.entry[lab]->state(T);
          if (its.disabled) its.entry[lab]->disable();
	}
      }
      private.setstatus(its);

      return T;
    }
    its.clearentry := function() {
      wider its, private;
      for (i in 1:length(its.options)) {
	its.entry[its.options[i]]->state(F);
      }
      return T;
    }

    its.makeentry := function(ref its, ref self) {
      its.entryframe := widgetset.frame(its.topframe, expand=private.expand,
					side='right',
					borderwidth=private.borderwidth);
      widgetset.popuphelp(its.entryframe, its.hlp);
      its.leftframe := widgetset.frame(its.entryframe, side='top',
				       borderwidth=private.borderwidth);
      its.entry := [=];
      width:=max(strlen(its.options));
      its.buttonframe := [=];
      nlines := 0;
      for (i in 1:length(its.options)) {
	if (i%nperline==1) {
	  nlines+:=1;
	  its.buttonframe[nlines] := widgetset.frame(its.leftframe,
						     side='left',
						     expand=private.expand,
						     borderwidth=private.borderwidth);
	}
	its.entry[its.options[i]] := widgetset.button(its.buttonframe[nlines],
						      width=width,
						      text=its.options[i],
						      value=its.options[i],
						      type='check',
						      borderwidth=private.borderwidth);
	its.busy := T;
	whenever its.entry[its.options[i]]->press do {
	  if(!its.busy) {
	    its.busy := T;
	    its.actualvalue := [''];
	    j := 0;
	    for (k in 1:length(its.options)) {
	      if (its.entry[its.options[k]]->state()) {
		j +:= 1;
		its.actualvalue[j] := its.options[k];
	      }
	    }
	    self->value(its.actualvalue);
	    its.busy := F;
	  }
	}
      }
    }

    # Public interface:
    self.setwidth := function(value=unset) {
      wider its, self;
      if (is_unset(value)) value:=private.width;
      if (has_field(its, 'entry')) {
	for (i in 1:length(its.options)) {
	  its.entry[its.options[i]]->width(value/its.nperline);
	}
      }
      return T;
    }
    self.get := function() {
      wider its, private;
      if (is_illegal(its.actualvalue)) return illegal;
      if (!is_unset(its.actualvalue)) {
	its.actualvalue := [''];
	j := 0;
	for (i in 1:length(its.options)) {
	  if (its.entry[its.options[i]]->state()) {
	    j +:= 1;
	    its.actualvalue[j] := its.options[i];
	  }
	}
      }
      private.setstatus(its);
      return its.actualvalue;
    }
    self.disable := function(disable=T) {
      wider its, private;
      if (!its.editable) return F;
      for (i in 1:length(its.options)) {
	if (disable&&!its.disabled) {
	  its.entry[its.options[i]]->disabled(disable);
	}
	else if (!disable&&its.disabled) {
	  its.entry[its.options[i]]->disabled(disable);
	}
      }
      return private.disable(its, disable);
    }
    if (is_fail(private.stringarguments(its, value, default, allowunset,
				       editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }

    private.makestandard(its, self, parent, addunsetframe=T,
			 title='AIPS++ Check list chooser');

    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }

  const public.choice := subsequence(parent=unset, value='', default='',
				     options='', allowunset=F,
				     editable=T, hlp=unset)
  {

    wider private;
    widgetset.tk_hold();

    its := [=];
    its.hlp := hlp;
    its.recordbased := F;

    its.parser := 'string';
    its.widgetname := 'choice';
    its.truedefault := options[1];

    if (is_fail(private.stringarguments(its, value, default, allowunset,
				       editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);

    its.putentry := function() {
      wider its, private;
      its.entry.disabled(F);
      if (!is_unset(its.actualvalue)) its.entry.selectlabel(its.displayvalue);
      if (its.disabled) {
        its.entry.disabled(T);
      }
      return private.putentry(its);
    }
    its.clearentry := function() {
      wider its, private;
      return F;
    }
    
    its.makeentry := function(ref its, ref self) {
      wider private;
      its.entryframe := widgetset.frame(its.topframe, expand=private.expand,
					side='right', borderwidth=private.borderwidth);
      widgetset.popuphelp(its.entryframe, its.hlp);
      its.entry := widgetset.optionmenu(its.entryframe, its.options,
					borderwidth=private.borderwidth,
					background=private.optionmenu.resources.background);
      whenever its.entry->select do {
	# Only report valid values
	its.actualvalue := $value.label;
	self->value(its.actualvalue);
      }
    }
    self.get := function() {
      wider its, private;
      if (is_illegal(its.actualvalue)) fail 'Value of entry is illegal';
      if (is_unset(its.actualvalue)) {
        return unset;
      }
      else {
	return its.entry.getvalue();
      }
    }
    self.disable := function(disable=T) {
      wider its, private;
      if (!its.editable) return F;
      if (disable&&!its.disabled) {
	its.entry.disabled(disable);
      }
      else if (!disable&&its.disabled) {
	its.entry.disabled(disable);
      }
      return private.disable(its, disable);
    }
    
    private.makestandard(its, self, parent, addunsetframe=T,
			 title='AIPS++ Chooser', allowclear=F);
    
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }
  
  const public.file := subsequence(parent=unset, value='', default='',
				   options='', allowunset=F,
				   editable=T, types='All', hlp=unset) {
    
    wider private;
    widgetset.tk_hold();
    
    local self;

    its := [=];
    its.recordbased := F;
    its.truedefault := '';

    its.parser := 'file';
    its.widgetname := 'file';
    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);

    its.viewright := T;
    
    its.putentry := function() {
      wider its, private;
      s:= '';
      if (!has_field(its, 'displayvalue')) its.displayvalue := [''];
      for (i in 1:length(its.displayvalue)) {
        s:=spaste(s, its.displayvalue[i]);
        if (i<length(its.displayvalue)) s:=spaste(s, ', ');
      }
      its.displayvalue := s;
      return private.putentry(its);
    }
    its.makeentry := function(ref its, ref self) {
      wider private, its, self;
      its.disabled := !its.editable;
      if (its.editable) {
	its.entryframe := widgetset.frame(its.topframe, side='right',
					  expand=private.expand,
					  borderwidth=private.borderwidth);
	widgetset.popuphelp(its.entryframe, its.hlp);
	its.entry := widgetset.entry(its.entryframe,
				     background=private.editablecolor,
				     width=private.width,
				     borderwidth=private.borderwidth);
	whenever its.topframe->enter do {
	  widgetset.popuphelp(its.entry,  its.hlp);
	  whenever its.entry->return, its.entry->lve  do {
	    # Get the value
	    eventname := $name;
	    entry := its.entry->get();
	    # If its the nodisplay string for this type then
	    # just emit an event
	    if (has_field(its, 'nodisplay')&&is_string(its.nodisplay)&&
	       (entry==its.nodisplay)) {
	      if(eventname=='return') self->value(its.actualvalue);
	    }
	    else {
	      private.checkunset(entry);
	      # Otherwise try to insert it and emit a value
	      # event if it worked
	      if (self.insert(entry)) {
		if(eventname=='return') self->value(its.actualvalue);
	      }
	      else {
		its.actualvalue := illegal;
		its.displayvalue := '';
	      }
	    }
	  }
	  deactivate;
	}
      }
      else {
	its.entry := widgetset.entry(its.topframe,
				     background=private.uneditablecolor,
				     borderwidth=private.borderwidth,
				     width=private.width);
	widgetset.popuphelp(its.entry,  its.hlp);
	its.entry->disabled(T);
      }
      return T;
    };

    #####################################################################
    # Setup initial values
    
    its.wrench := [=];
    its.wrench.write := [=];
    its.wrench.write['From catalog'] := function(ref self, ref its) {
      msg := 'Starting filecatalog GUI. Select an entry';
      note (msg, priority='NORMAL', origin='guientry.file');
      private.catalog.gui(unset);       # Don't refresh for speed
      private.catalog.show(show_types=types);
      private.catalog.setselectcallback(self.insertandemit);
    }
    its.wrench.readonly := [=];
    its.wrench.readonly["View"] := function(ref self, ref its) {
      file := self.get();
      if (strlen(file)&&!is_unset(file)) {
	include 'os.g';
	if (!serverexists('dos', 'os', dos)) {
	  throw ('dos is either not running or not valid',
		 origin='guientry.file');
	}
	else {
	  if (dos.fileexists(file)) {
	    private.catalog.view(file);
	  }
	  else {
	    note(paste('File ', file, 'does not exist'), 
		 priority='WARN', origin=spaste('guientry.file'));
	  }
	}
      }
    }
    its.wrench.readonly["Tool"] := function(ref self, ref its) {
      file := self.get();
      if (strlen(file)&&!is_unset(file)) {
	include 'toolmanager.g';
	if (!serverexists('tm', 'toolmanager', tm)) {
	  throw ('toolmanager is either not running or not valid',
		 origin='guientry.file');
	}
	else {
	  tm.usegui();
          tm.showtoolfromtable(file);
	}
      }
    }
    if (is_fail(private.stringarguments(its, value, default, allowunset,
				       editable, types, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);

    self.insertandemit := function(rec) {
	# the dc will call this with an unset when the connection is broken
	# ignore unset values here
        wider self;
	result := F;
	if (!is_unset(rec)) {
	    result := self.insert(rec);
	    if (result) {
		self->value(its.actualvalue);
	    } 
	}
	return result;
    }

    private.makestandard(its, self, parent,
			 title=paste('AIPS++ File Chooser'));
    
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }

  const public.minmaxhist := subsequence(parent=unset, value=unset, default=unset,
					 allowunset=F, editable=T, minvalue=-1, 
					 maxvalue=1,title='Histogram Window',
					 hlp=unset, histarray=unset, 
					 imageunits=unset, options='')    
  {
      wider private;
      widgetset.tk_hold();
      
      its := [=];
      its.imageunits := imageunits;
      its.hlp := hlp;
      its.recordbased := F;
      its.types := 'double';
      its.widgetname := 'minmaxhist';
      its.exists := F;
      its.title := title;
      if (is_fail(private.untypedarguments(its, value, default, allowunset, #check for untyped
					  editable, options, hlp))) {
	  widgetset.tk_release();
	  fail;
      }

      private.makestandardfunctions(its, self); 

      its.cast := function(value) {
	  if (is_numeric(value)) {
	      if (its.types == 'integer') {
		  return as_integer(value);
	      } else {
		  return as_double(value);
	      }
	  } else {
	      return value;
	  }
      }

      its.pushhistwhenever := function() {
	  wider its;
	  its.histwhenevers[len(its.histwhenevers) + 1] := last_whenever_executed();
	  return T;    
      } 
      
      its.putentry := function() {
	  wider its, private;

	  if (!its.disabled) {
	      its.entry->enable();
	  }

	  private.setstatus(its);
	  if (!is_unset(its.actualvalue)) {
	      its.entry.insert(its.actualvalue);
	  }
	  if (its.disabled) {
	      its.entry->disable();
	  }
	  return T;
      }
      
      its.clearentry := function() {           #What about if allowunset = T?
	  return F;
      }

      #Initial values
      its.allowunset := allowunset;
      its.editable := editable;
      its.disabled := !its.editable;
      its.actualvalue := value;
      its.displayvalue := its.actualvalue;
      its.minvalue := minvalue;
      its.maxvalue := maxvalue;
      its.histarray := histarray;

      its.originalvalue := value;
      its.defaultvalue := default;
      its.busy := F;

      its.makeentry := function(ref its, ref self) {
	  wider private;

	  its.entryframe := widgetset.frame(its.topframe, side='right', 
					    borderwidth=private.borderwidth);
	  widgetset.popuphelp(its.entryframe, its.hlp);
	  its.histogrambutton := widgetset.button(its.entryframe, bitmap='hist.xbm', 
						  relief='raised', 
						  borderwidth=private.borderwidth);

	  widgetset.popuphelp(its.histogrambutton, 'Click to open histogram window');
	  its.entry := public.twoentry(its.entryframe, its.actualvalue, 
				       min=minvalue, max=maxvalue);
	  
	  if (is_fail(its.entry)) {
	      widgetset.tk_release();
	      fail;
	  }
	  
	  whenever its.histogrambutton->press do {
	    if(!its.busy) {
	      its.busy :=T;
	      if (!its.exists) {       
		  include 'histogramgui.g';
		  its.histwindow := histogramgui(xmin=its.actualvalue[1], 
						 xmax=its.actualvalue[2], 
						 array=its.histarray, 
						 units=its.imageunits, 
						 title=its.title);

		  its.histwindowgui := its.histwindow.gui();
		  
		  whenever its.wrenchmenu[3]->press do {        #"Default"
		      its.histwindow.setselection(its.defaultvalue);	       
		  }
		  its.pushhistwhenever();
		  
		  whenever its.wrenchmenu[2]->press do {       #"Original"
		      its.histwindow.setselection(its.originalvalue);
		  }
		  its.pushhistwhenever();
		  
		  whenever its.entry->return, its.entry->lve  do {
		    eventname := $name;
		    self.insert($value);       
		    its.histwindow.setselection(its.actualvalue);
		    if(eventname=='return') self->value(its.actualvalue);
		  }
		  its.pushhistwhenever();
		  
		  whenever its.histwindow->change do {
		      its.actualvalue := as_double($value);     # Hist will have checked range
		      self->value(its.actualvalue);
		      its.putentry();
		  }
		  its.pushhistwhenever();
		  
		  whenever its.histwindow->newstats do {
		      self->newstats($value);
		  }
		  its.pushhistwhenever();
		  
		  whenever its.histwindow->close do {
		      its.exists := F;
		      self->updatehistogram(F);
		      for (i in 1:len(its.histwhenevers)) {
			  deactivate its.histwhenevers[i];
		      }
		  }
		  its.pushhistwhenever();
		  
		  its.exists := T;
		  self->updatehistogram(T);
	      } else {
		  its.histwindow.gui();
	      }
	      its.busy := F;
	    }  
	  }
	  
	  if (its.editable) {
	      whenever its.entry->return, its.entry->lve  do {
		eventname := $name;
		  self.insert($value);
		  if(eventname=='return') self->value(its.actualvalue);
	      } 
	  } else {
	      its.entry.disable();
	  }
      }
  	  
      #Public interface
      self.setdata := function(newhistarray)   # Assumes updated setrange (new actualvalue)
      {
	  wider its;
	  if (its.exists) {
	      its.histwindow.newdata(newhistarray, its.actualvalue[1], its.actualvalue[2]);
	  }
	  
      }  

      self.setstats := function(stats) {
	  wider its;
	  
	  if (its.exists) {
	      if (is_record(stats)) {
		  if (has_field(stats, 'mean')) {
		      mean := stats.mean;
		  } else mean := F;
		  
		  if (has_field(stats, 'median')) {
		      median := stats.median;
		  } else median := F;

		  if (has_field(stats, 'stddev')) {
		      stddev := stats.stddev;
		  } else stddev := F;

		  its.histwindow.setstats(mean, median, stddev);
	      }
	  }
      }
      

      self.setrange := function(newmin, newmax) {       
	  wider its;
	  
	  its.defaultvalue := [newmin, newmax];
	  its.maxvalue := newmax; 
	  its.minvalue := newmin;
	  
          if (its.minvalue > its.actualvalue[1]) {
	      its.actualvalue[1] := its.minvalue;
	  }
	  if (its.maxvalue < its.actualvalue[2]) {
	      its.actualvalue[2] := its.maxvalue;
	  }
      }
      

      self.insert := function(toins=unset) {  #All insertions should go through here,
	                                      #as this is where error checking occurs
	  wider private, its;

	  toinsert[1] := as_float(toins[1]);
	  toinsert[2] := as_float(toins[2]);

	  if (!(  (is_numeric(toinsert[1]) || is_integer(toinsert[1]) 
		|| is_double(toinerts[1]) || is_float(toinsert[1]))
		&& 
	      (is_numeric(toinsert[2]) || is_integer(toinsert[2]) 
		|| is_double(toinsert[2]) || is_float(toinsert[2])))
	      ) {
	      
	      self.setstatus(F);
	      return F;

	  } else {
	      if (toinsert[1] > toinsert[2]) {
		  self.setstatus(F);
		  return F;
	      } else {
		  its.actualvalue := toinsert;
		  its.putentry();
		  return T;
	      }
	  }
      }
  
      self.get := function() {
	  wider its, private;
	  return its.cast(private.get(its, self));
      }

      self.disable := function(disable=T) {
	  wider its, private;
	  if (!its.editable) return F;
	  if (disable&&!its.disabled) {
	      its.entry.disable();
	  } else if (!disable&&its.disabled) {
	      its.entry.enable();
	  }
	  return private.disable(its, disable);
      }

      self.dismiss := function() {
	  wider its;
	  if (its.exists) {
	      its.histwindow.done();
	  }
      }

      #Standard done, but also close hist window if open
      self.done := function() {
	  wider its, self;
	  
	  # Remove in reverse
	  
	  for (field in "codesbutton entry leftframe entryframe entryholderframe unitsbutton unsetlabel unsetframe") {
	      if (has_field(its, field)) {
		  if (has_field(its[field], 'done')) {
		      its[field].done();
		  }
		  if (is_agent(its[field])) {
		      popupremove(its[field]);
		  }
		  val its[field] := F;
	      }
	  }
	  if (has_field(its, 'wrenchmenu')) {
	      names := field_names(its.wrenchmenu);
	      if (len(names) > 0) {
		  for (field in names[len(names):1]) {
		      if (is_agent(its.wrenchmenu[field])) {
			  if (has_field(its.wrenchmenu[field], 'done')) {
			      its.wrenchmenu[field].done();
			  }
			  its.wrenchmenu[field]->unmap();
			  popupremove(its.wrenchmenu[field]);
		      }
		  }
	      }
	  }
	  popupremove(its.wrenchbutton);

	  if (its.exists) {
	      for (i in 1:len(its.histwhenevers)) {
		  ok := whenever_active(its.histwhenevers[i]);
		  if (is_fail(ok)) {
		  } else {
		      if (ok) deactivate its.histwhenevers[i];
		  }
	      }
	      its.histwindow.done();
	  }
	  
	  val its.wrenchbutton := F;
	  popupremove(its.entrystatus);
	  val its.entrystatus := F;
	  its.topframe := F;
	  val its := F;
	  val self := F;
	  return T;
      }

      private.makestandard(its, self, parent, addunsetframe=T,
			   title='AIPS++ Range Chooser With Histogram',
			   allowclear=F);
      
      ok := self.insert(its.originalvalue);
      ok := widgetset.tk_release();
  }
      



  
  
  const public.scalarmeasure := subsequence(parent=unset, value=unset,
					    default=unset, options='',
					    allowunset=F,
					    editable=T, type=unset, hlp=unset)
  {
    
    wider private;
    widgetset.tk_hold();

    #####################################################################
    # Private functions and data
    
    private.initmeasures();
    
    its := [=];
    its.recordbased := T;
    its.truedefault := dm.frequency();

    its.parser := 'measure';
    its.widgetname := 'scalarmeasure';
    its.truedefault := unset;

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);

    its.putentry := function() {
      wider its, private;
      if (!is_unset(its.actualvalue)&&is_record(its.actualvalue.m0)) {
	its.unit := its.actualvalue.m0.unit;
	its.unitsbutton.selectlabel(its.unit);
	its.code := its.actualvalue.refer;
	its.codesbutton.selectlabel(its.code);
	its.displayvalue := as_string(its.actualvalue.m0.value);
      }
      return private.putentry(its);
    }

    its.makeentry := function(ref its, ref self) {
      wider private, its, self;
      its.disabled := !its.editable;
      if (its.editable) {
	its.entryframe := widgetset.frame(its.topframe, side='right',
					  expand=private.expand,
					  borderwidth=private.borderwidth);
	widgetset.popuphelp(its.entryframe, its.hlp);
	its.entry := widgetset.entry(its.entryframe,
				     background=private.editablecolor,
				     width=private.width,
				     borderwidth=private.borderwidth);
	whenever its.topframe->enter do {
	  widgetset.popuphelp(its.entry,  its.hlp);
	  whenever its.entry->return, its.entry->lve  do {
	    eventname := $name;
	    # Get the value
	    entry := its.entry->get();
	    # If its the nodisplay string for this type then
	    # just emit an event
	    if (has_field(its, 'nodisplay')&&is_string(its.nodisplay)&&
	       (entry==its.nodisplay)) {
	      if(eventname=='return') self->value(its.actualvalue);
	    }
	    else {
	      private.checkunset(entry);
	      # Otherwise try to insert it and emit a value
	      # event if it worked
	      if (self.insert(entry)) {
		if(eventname=='return') self->value(its.actualvalue);
	      }
	      else {
		its.actualvalue := illegal;
		its.displayvalue := '';
	      }
	    }
	  }
	  deactivate;
	}
      }
      else {
	its.entry := widgetset.entry(its.topframe,
				     background=private.uneditablecolor,
				     borderwidth=private.borderwidth,
				     width=private.width);
	widgetset.popuphelp(its.entry,  its.hlp);
	its.entry->disabled(T);
      }
      return T;
    };
    #####################################################################
    # Setup initial values
    
    its.allowunset := allowunset;
    its.editable := editable;
    its.disabled := !its.editable;
    
    if (is_unset(type)) {
      if (is_measure(value)) {
	its.type := value.type;
      }
      else {
	widgetset.tk_release();
        return throw('Cannot determine measure type', origin='guientry.scalarmeasure');
      }
    }
    else {
      its.type := type;
    }
    its.guiname := spaste(type, 'gui');
    
    if (its.type=='frequency') {
      its.code := 'REST';
      its.unit := 'Hz';
      its.defaultrefer := 'REST';
      its.units := ['Hz', 'MHz', 'GHz', 's', 'eV', 'keV'];
    }
    else if (its.type=='radialvelocity') {
      its.code := 'REST';
      its.unit := 'm/s';
      its.defaultrefer := 'REST';
      its.units := ['m/s', 'km/s'];
    }
    else if (its.type=='doppler') {
      its.code := 'radio';
      its.unit := 'm/s';
      its.defaultrefer := 'radio';
      its.units := ['m/s', 'km/s'];
    }
    else {
      widgetset.tk_release();
      return throw(paste('Unknown scalarmeasure type', its.type),
		   origin='guientry.scalarmeasure');
    }
    
    if (is_unset(value)&&!allowunset) value:=dm[its.type](its.defaultrefer);
    if (is_unset(default)&&!allowunset) default:=dm[its.type](its.defaultrefer);
    its.originalvalue := value;
    its.defaultvalue := default;
    its.truedefault := dm[its.type](its.defaultrefer);
    
    if (is_measure(value)) {
      its.codes := dm.listcodes(value).normal;
    }
    else {
      its.codes := dm.listcodes(dm.frequency('')).normal;
    }

    its.wrench := [=];
    its.wrench.write := [=];
    its.wrench.write['From measures'] := function(ref self, ref its) {
      value := self.get();
      private.initmeasures();
      if (serverexists('dm', 'measures', dm)) {
	note('Starting Measures GUI: use Copy (there) and Paste (here) to transfer a measure');
	dm[to_lower(its.guiname)]();
      }
      else {
	widgetset.tk_release();
	return throw('Measures server is missing: cannot start the GUI');
      }
    }
    if ((its.type=='frequency')||(its.type=='radialvelocity')) {
      its.getandgo := function(value) {
	wider self;
	if (is_record(value)&&
	   has_field(value, 'position')&&
	   has_field(value.position, 'world')&&
	   has_field(value.position.world, 'measure')&&
	   has_field(value.position.world.measure, 'spectral')&&
	   has_field(value.position.world.measure.spectral, type)) {
	  self.insertandemit(value.position.world.measure.spectral[type]);
	}
      }
      its.wrench.write['From image'] := function(ref self, ref its) {
	include 'gopher.g';
	if (self.hascontext('image')) {
	  dgo.fromimage(self.getcontext('image'), 'measure', its.getandgo);
	}
	else {
	  dgo.fromimage(unset, 'measure', its.getandgo);
	}
      }
    }
    its.wrench.write['Edit'] := function(ref self, ref its) {
      value := self.get();
      if (!is_unset(value)&&!is_fail(value)) {
	rb:=widgetset.recordbrowser(therecord=value, readonly=F);
	its.actualvalue := value;
	its.putentry();
	self->value(its.actualvalue);
      }
    }
    its.wrench.readonly := [=];
    its.wrench.readonly['View'] := function(ref self, ref its) {
      value := self.get();
      if (!is_unset(value)&&!is_fail(value)) {
	rb:=widgetset.recordbrowser(therecord=value, readonly=T);
      }
    }
    its.wrench.readonly["Save"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.saverecordviagui(unset, self.get(),
			    spaste('Saved from guientry.', its.widgetname));
    }
    its.wrench.write["Restore"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.restorerecordviagui(self.insertandemit);
    }
    its.makeentry := function(ref its, ref self) {
      wider private;
      its.unitsbutton := 
	  widgetset.optionmenu(its.topframe,
			       labels=its.units,
			       names=its.units,
			       hlp='Units for quantity',
			       borderwidth=private.borderwidth);
      if (its.editable) {
	whenever its.topframe->enter do {
	  whenever its.unitsbutton->select do {
	    its.unit := its.unitsbutton.getlabel();
	    entry := its.entry->get();
	    private.checkunset(entry);
	    if (self.insert(entry)) self->value(its.actualvalue);
	  }
	  deactivate;
	}
      }
      its.entryframe := widgetset.frame(its.topframe, side='right',
					expand=private.expand,
					borderwidth=private.borderwidth);
      widgetset.popuphelp(its.entryframe, its.hlp);
      if (its.editable) {
	its.entry := widgetset.entry(its.entryframe,
				     background=private.editablecolor,
				     width=private.width,
				     borderwidth=private.borderwidth);
	whenever its.entry->return, its.entry->lve  do {
	  eventname := $name;
	  if (self.insert(self.get())) {
	    if(eventname=='return') self->value(its.actualvalue);
	  }
	}
      }
      else {
	its.entry := widgetset.entry(its.entryframe,
				     background=private.uneditablecolor,
				     width=private.width,
				     borderwidth=private.borderwidth);
	its.entry->disabled(T);
      }
      its.codesbutton := widgetset.optionmenu(its.topframe,
					      labels=its.codes,
					      names=its.codes,
					      hlp='Types for entry',
					      borderwidth=private.borderwidth);
      if (its.editable) {
	whenever its.topframe->enter do {
	  whenever its.codesbutton->select do {
	    its.code := its.codesbutton.getlabel();
	    entry := its.entry->get();
	    private.checkunset(entry);
	    if (self.insert(entry)) self->value(its.actualvalue);
	  }
	  deactivate;
	}
      }
    }
    
    #####################################################################
    self.setwidth := function(value) {
      wider its, self;
      return T;
    }
    self.insert := function(rec=unset, truedefault=F) {
      wider its, private;
      include 'entryparser.g';
      if (!is_record(dep)||!has_field(dep, 'scalar')||
	 !is_function(dep['scalar'])) {
         return throw('Entry parser not valid',
                      origin='guientry.frequency');
      }

      if (truedefault) rec:=its.truedefault;


      include 'measures.g'
      if (is_string(rec)) {
        its.actualvalue := [type=its.type, refer=its.code,
			    m0=[value=as_double(rec), unit=its.unit]];
	its.displayvalue := its.actualvalue.m0.value;
	its.putentry();
        return T;
      }
      else if (is_measure(rec)&&(rec.type==its.type)) {
        its.actualvalue := rec;
        its.displayvalue := rec.m0.value;
	its.putentry();
	return T;
      }
      else if (is_unset(rec)) {
        its.actualvalue := unset;
	its.putentry();
	return T;
      }	
      else {
        private.errormessage(rec, 'measure');
	private.setstatus(its);
        return F;
      }
    }
    private.makestandard(its, self, parent,
			 title=paste('AIPS++', type, 'Chooser'));
#    ok := self.insert(its.defaultvalue);
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }
  
  const public['frequency'] := subsequence(parent=unset, value=unset,
					   default=unset, options='',
					   allowunset=F,
					   editable=T, hlp=unset) {
    self := public.scalarmeasure(parent, value,
				 default, options,
				 allowunset,
				 editable, type='frequency', hlp=hlp);
  }

  const public['radialvelocity'] := subsequence(parent=unset, value=unset,
					   default=unset, options='',
					   allowunset=F,
					   editable=T, hlp=unset) {
    self := public.scalarmeasure(parent, value,
				 default, options,
				 allowunset,
				 editable, type='radialvelocity', hlp=hlp);
  }

  const public['doppler'] := subsequence(parent=unset, value=unset,
					 default=unset, options='',
					 allowunset=F,
					 editable=T,
					 hlp=unset) {
    self := public.scalarmeasure(parent, value,
				 default, options,
				 allowunset,
				 editable, type='doppler', hlp=hlp);
  }

  const public.epoch := subsequence(parent=unset, value=unset,
				    default=unset, options='', allowunset=F,
				    editable=T, hlp=unset)
  {
    
    wider private;
    widgetset.tk_hold();

    private.initmeasures();
    
    its := [=];
    its.recordbased := T;
    its.truedefault := dm.epoch('utc', 'today');
    its.hlp := hlp;

    its.parser := 'measure';
    its.widgetname := 'epoch';

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);

    its.putentry := function() {
      wider its, private;
      if (!is_unset(its.actualvalue)&&is_measure(its.actualvalue)) {
        if (has_field(its, 'displayvalue')&&is_defined(its.displayvalue)) {
	  its.codesbutton.disabled(T);
	}
	else {
	  its.code := its.actualvalue.refer;
	  its.codesbutton.disabled(F);
	  its.codesbutton.selectlabel(its.code);
	  its.displayvalue := dq.time(its.actualvalue.m0, form="ymd time");
	}
      }
      return private.putentry(its);
    }
    its.allowunset := allowunset;
    its.editable := editable;
    its.disabled := !its.editable;
    
    its.code := 'utc';
    candidate :=  to_lower(options[1]);
    its.codes := dm.listcodes(dm.epoch('utc', 'today')).normal;
    if (candidate!='') {
      if (any(to_lower(its.codes)==candidate)) {
        its.code := to_upper(candidate);
      }
    }

    if (is_unset(value)&&!allowunset) value:=dm.epoch(its.code, 'today');
    if (is_unset(default)&&!allowunset) default:=dm.epoch(its.code, 'today');
    its.originalvalue := value;
    its.defaultvalue := default;
    its.actualvalue := dm.epoch(its.code, 'today');

    its.wrench := [=];
    its.wrench.write := [=];
    its.wrench.write['From measures'] := function(ref self, ref its) {
      value := self.get();
      private.initmeasures();
      if (serverexists('dm', 'measures', dm)) {
	note('Starting Measures GUI: use Copy (there) and Paste (here) to transfer a measure');
	dm.epochgui();
      }
      else {
	widgetset.tk_release();
	return throw('Measures server is missing: cannot start the GUI');
      }
    }
    its.wrench.write['Today'] := function(ref self, ref its) {
      value := self.get();
      if (serverexists('dm', 'measures', dm)) {
	value := dm.epoch(its.code, 'today');
	if (self.insert(value)) self->value(its.actualvalue);
      }
    }
    its.wrench.readonly["Save"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.saverecordviagui(unset, self.get(),
			    spaste('Saved from guientry.', its.widgetname));
    }
    its.wrench.write["Restore"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.restorerecordviagui(self.insertandemit);
    }
    its.makeentry := function(ref its, ref self) {
      wider private, its, self;
      its.disabled := !its.editable;
      if (its.editable) {
	its.entryframe := widgetset.frame(its.topframe, side='right',
					  expand=private.expand,
					  borderwidth=private.borderwidth);
	widgetset.popuphelp(its.entryframe, its.hlp);
	its.entry := widgetset.entry(its.entryframe,
				     background=private.editablecolor,
				     width=private.width,
				     borderwidth=private.borderwidth);
	whenever its.topframe->enter do {
	  widgetset.popuphelp(its.entry,  its.hlp);
	  whenever its.entry->return, its.entry->lve  do {
	    eventname := $name;
	    # Get the value
	    entry := its.entry->get();
	    # If its the nodisplay string for this type then
	    # just emit an event
	    if (has_field(its, 'nodisplay')&&is_string(its.nodisplay)&&
	       (entry==its.nodisplay)) {
	      if(eventname=='return') self->value(its.actualvalue);
	    }
	    else {
	      private.checkunset(entry);
	      # Otherwise try to insert it and emit a value
	      # event if it worked
	      if (self.insert(entry)) {
		if(eventname=='return') self->value(its.actualvalue);
	      }
	      else {
		its.actualvalue := illegal;
		its.displayvalue := '';
	      }
	    }
	  }
	  deactivate;
	}
      }
      else {
	its.entry := widgetset.entry(its.topframe,
				     background=private.uneditablecolor,
				     borderwidth=private.borderwidth,
				     width=private.width);
	widgetset.popuphelp(its.entry,  its.hlp);
	its.entry->disabled(T);
      }
      its.codesbutton := widgetset.optionmenu(its.topframe,
					      labels=its.codes,
					      names=its.codes,
					      borderwidth=private.borderwidth,
					      hlp='Select code for epoch');
      its.codesbutton.selectlabel(its.code);
      if (its.editable) {
	whenever its.topframe->enter do {
	  whenever its.codesbutton->select do {
	    its.code := its.codesbutton.getlabel();
	    entry := its.entry->get();
	    private.checkunset(entry);
	    if (self.insert(entry)) self->value(its.actualvalue);
	  }
	  deactivate;
	}
      }
    }
    self.insert := function(rec=unset, truedefault=F) {
      wider its, private;
      include 'entryparser.g';

      if (!is_record(dep)||!has_field(dep, its.parser)||
	 !is_function(dep[its.parser])) {
         return throw('Entry parser not valid',
                      origin='guientry.epoch');
      }

      if (truedefault) rec:=its.truedefault;

      if (is_unset(rec)) {
        its.actualvalue := unset;
	its.putentry();
	return T;
      }	

      include 'measures.g'
      if (is_string(rec)) {
        if (dq.is_angle(rec)) {
	  its.actualvalue := dm.epoch(its.code, dq.totime(rec));
	  its.displayvalue := its.actualvalue.m0.value;
	  its.putentry();
	  return T;
	}
	else if (dep['measure'](rec, its.allowunset, its.actualvalue,
				its.displayvalue, type='epoch')) {
	  its.putentry();
	  return T;
	}
        else {
	  private.errormessage(rec, 'measure');
	  private.setstatus(its);
	  return F;
	}
      }
      else if (is_measure(rec)&&(rec.type=='epoch')) {
        its.actualvalue := rec;
        its.displayvalue := its.actualvalue.m0.value;
	its.putentry();
	return T;
      }
      else {
        private.errormessage(rec, 'measure');
	private.setstatus(its);
        return F;
      }
    }
    private.makestandard(its, self, parent, title='AIPS++ Epoch Chooser');
#    ok := self.insert(its.defaultvalue);
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }
  
  const public.direction := subsequence(parent=unset, value=unset,
					default=unset, options='',
					allowunset=F,
					editable=T, hlp=unset)
  {

    wider private;
    widgetset.tk_hold();

    private.initmeasures();
    its := [=];
    its.recordbased := T;
    its.truedefault := dm.direction();
    its.parser := 'measure';
    its.widgetname := 'direction';

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);

    its.options := options;
    
    its.putentry := function() {
      wider its, private;

      its.code := 'J2000';
      its.codesbutton.disabled(F);
      for (i in 1:2) {
	its.entry[i]->delete('start', 'end');
      }

      if (is_measure(its.actualvalue)) {
	its.code := its.actualvalue.refer;
	its.codesbutton.selectlabel(its.code);
        if (has_field(its, 'displayvalue')&&is_defined(its.displayvalue)) {
	  its.codesbutton.disabled(T);
	}
        else {
	  if (any(its.extracodes==its.code)) {
	    its.actualvalue.m0 := dq.toangle('0d');
	    its.actualvalue.m1 := dq.toangle('90d');
	  }
          its.displayvalue := ['', '']
	  its.displayvalue[1] := dq.angle(its.actualvalue.m1, form="angle");
	  its.displayvalue[2] := dq.angle(its.actualvalue.m0, form="time");
	}
      }

      private.setstatus(its);
      
      if (has_field(its, 'entry')) {
	if (is_unset(its.actualvalue)) {
	  for (i in 1:2) {
	    its.entry[i]->insert('<unset>');
	    its.entry[i]->background(private.unsetcolor);
	  }
	  return T;
	}
	else if (is_measure(its.actualvalue)&&has_field(its, 'displayvalue')) {
          if ((len(its.displayvalue)==1)&&(is_string(its.displayvalue))) {
	    its.entry[2]->insert(its.displayvalue[1]);
	  }
          else {
	    for (i in 1:2) {
	      if (is_string(its.displayvalue)&&strlen(its.displayvalue[i])) {
		its.entry[i]->insert(its.displayvalue[i]);
	      }
	    }
	  }
	}
	
	# Take care of background colors
	for (i in 1:2) {
	  its.entry[i]->foreground('black');
	  its.entry[i]->disabled(its.disabled||any(its.extracodes==its.code));
	  if (its.editable&&!(its.disabled||any(its.extracodes==its.code))) {
	    its.entry[i]->background(private.editablecolor);
	  }
	  else {
	    its.entry[i]->background(private.uneditablecolor);
	  }
	}
      }
      return T;
    }
    its.clearentry := function() {
      wider its, private;
      its.code := its.codes[1];
      its.codesbutton.selectlabel(its.code);
      its.disabled := !its.editable;
      its.codesbutton.disabled(its.disabled);
      for(i in 1:2) {
	its.entry[i]->delete('start', 'end');
	its.entry[i]->foreground('black');
	its.entry[i]->disabled(its.disabled);
	if (its.editable&&!(its.disabled)) {
	  its.entry[i]->background(private.editablecolor);
	}
	else {
	  its.entry[i]->background(private.uneditablecolor);
	}
      }
      return T;
    }

    #####################################################################
    # Setup initial values
    
    its.allowunset := allowunset;
    its.editable := editable;
    its.disabled := !its.editable;
    
    if (is_unset(value)&&!allowunset) value:=dm.direction('j2000');
    if (is_unset(default)&&!allowunset) default:=dm.direction('j2000');
    its.originalvalue := value;
    its.defaultvalue := default;
    its.actualvalue := value;
    
    codes := dm.listcodes(dm.direction('j2000'));
    if (is_record(codes)&&has_field(codes, 'normal')&&
       has_field(codes, 'extra')) {
      its.codes := codes.normal;
      its.extracodes := codes.extra;
      its.allcodes := split(paste(its.codes, its.extracodes));
    }
    else {
      widgetset.tk_release();
      return throw(spaste('Value ', value, ' is not a valid direction'));
    }
    its.code := 'j2000';

    its.wrench := [=];
    its.wrench.write['From measures'] := function(ref self, ref its) {
      value := self.get();
      if (serverexists('dm', 'measures', dm)) {
	note('Starting Measures GUI: use Copy (there) and Paste (here) to transfer a measure');
	dm.directiongui();
      }
      else {
	return throw('Measures server is missing: cannot start the Direction GUI');
      }
    }

    its.getandgo := function(value) {
      wider self;
      if (is_record(value)&&
	 has_field(value, 'position')&&
	 has_field(value.position, 'world') &&
	 has_field(value.position.world, 'measure') &&
	 has_field(value.position.world.measure, 'direction')) {
	self.insertandemit(value.position.world.measure.direction);
      }
    }
    its.wrench.write['From image'] := function(ref self, ref its) {
      include 'gopher.g';
      if (self.hascontext('image')) {
	dgo.fromimage(self.getcontext('image'), 'measure', its.getandgo);
      }
      else {
	dgo.fromimage(unset, 'measure', its.getandgo);
      }
    }
    its.makeentry := function(ref its, ref self) {
      its.entryframe := [=];
      its.entry := [=];
      hlp:=['Latitude term (e.g. Declination, Elevation)', 
	    'Longitude term (e.g. Right Ascension, Azimuth)'];
      if (any(options=='vertical')) {
        its.entryholderframe := widgetset.frame(its.topframe, side='bottom',
						expand=private.expand,
						borderwidth=private.borderwidth);
      }
      else {
        its.entryholderframe := ref its.topframe;
      }
      its.disabled := !its.editable;
      if (its.editable) {
	for (i in 1:2) {
	  its.entryframe[i] := widgetset.frame(its.entryholderframe,
					       expand=private.expand,
					       side='right',
					       borderwidth=private.borderwidth);
	  if (any(options=='vertical')) {
	    its.entry[i] := widgetset.entry(its.entryframe[i],
					    background=private.editablecolor,
					    width=private.width,
					    borderwidth=private.borderwidth);
	  } else {
	    its.entry[i] := widgetset.entry(its.entryframe[i],
					    background=private.editablecolor,
					    width=private.width/2,
					    borderwidth=private.borderwidth);
	  }
	  its.entry[i]->bind('<Enter>', 'ent');
	  its.entry[i]->bind('<Leave>', 'lve');
	}
	whenever its.topframe->enter do {
	  its.busy := F;
	  whenever its.entry[1]->return, its.entry[2]->return,
	      its.entry[1]->lve, its.entry[2]->lve do {
		# Get the value: remember to flip
		eventname := $name;
	    its.code := its.codesbutton.getlabel();
	    if(!its.busy) {
	      its.busy := T;
	      entry := '';
	      for (i in 1:2) {
		entry[i] := its.entry[3-i]->get();
		private.checkunset(entry[i]);
	      }
	      # Try to insert it and emit a value
	      # event if it worked
	      if (self.insert(entry)) {
		if(eventname=='return') self->value(its.actualvalue);
	      }
	      else {
		its.actualvalue := illegal;
		its.displayvalue := '';
	      }
	      its.busy := F;
	    }
	  }
	  deactivate;
	}
      }
      else {
	for (i in 1:2) {
	  if (any(options=='vertical')) {
	    its.entry[i] := widgetset.entry(its.entryholderframe,
					    borderwidth=private.borderwidth,
					    background=private.uneditablecolor,
					    width=private.width);
	  }
	  else {
	    its.entry[i] := widgetset.entry(its.entryholderframe,
					    borderwidth=private.borderwidth,
					    background=private.uneditablecolor,
					    width=private.width/2);
	  }
	  its.entry[i]->disabled(T);
	}
	widgetset.popuphelp(its.entry[i], hlp[i]);
      }
      its.codesbutton := widgetset.optionmenu(its.topframe,
					      labels=its.allcodes, 
					      names=its.allcodes,
					      borderwidth=private.borderwidth,
					      hlp='Codes for directions');
      if (its.editable) {
	whenever its.topframe->enter do {
	  whenever its.codesbutton->select do {
	    its.code := its.codesbutton.getlabel();
	    if (any(its.extracodes)==its.code) {
	      entry[1] := '0d';
	      entry[2] := '0d';
	    }
	    else {
	      for (i in 1:2) {
		entry[i] := its.entry[3-i]->get();
		private.checkunset(entry[i]);
	      }
	    }
	    if (self.insert(entry)) self->value(its.actualvalue);
	  }
	  deactivate;
	}
      }
    }

    self.setwidth := function(value=unset) {
      wider its, self;
      if (is_unset(value)) value:=private.width;
      if (has_field(its, 'entry')) {
        if (any(options=='vertical')) {
	  for(i in 1:2) its.entry[i]->width(value);
	}
	else {
	  for(i in 1:2) its.entry[i]->width(value/2);
	}
      }
      return T;
    }
    self.insert := function(rec=unset, truedefault=F) {
      wider its, private;
      include 'entryparser.g';
      if (!is_record(dep)||!has_field(dep, 'angle')||
	 !is_function(dep['angle'])) {
         return throw('Entry parser not valid',
                      origin='guientry.direction');
      }

      if (truedefault) rec:=its.truedefault;

      its.displayvalue := ['', ''];
      its.actualvalue := illegal;
#
      if (is_unset(rec)&&its.allowunset) {
	its.actualvalue := unset;
	its.displayvalue := '<unset>';
	its.putentry();
      } else if (is_string(rec)) {
	rec := split(rec);
        its.actualvalue := [=];
	if (dep.angle(rec[1], its.allowunset, its.actualvalue.m0,
		     its.displayvalue[1])&&
	   dep.angle(rec[2], its.allowunset, its.actualvalue.m1,
		     its.displayvalue[2])) {
	  its.actualvalue.type := 'direction';
	  its.actualvalue.refer := its.codesbutton.getlabel();
	  its.putentry();
	} else if (dep['measure'](rec[1], its.allowunset, its.actualvalue,
			       its.displayvalue, type='direction')) {
	  its.putentry();
	} else {
          its.actualvalue := illegal;
          its.displayvalue := '';
	  its.putentry();
	  return F;
	}
      } else if (is_measure(rec)&&(rec.type=='direction')) {
        its.actualvalue := rec;
	its.codesbutton.setlabel(its.actualvalue.refer);
	its.putentry();
      } else {
        private.errormessage(rec, 'measure');
	private.setstatus(its);
        return F;
      }
      return T;
    }
    self.get := function() {
      wider private, its;
      if (is_illegal(its.actualvalue)) return illegal;
#
      values := [=];
      if (!is_unset(its.actualvalue)) {
	values := dm.getvalue(its.actualvalue);
      }
#
      for (i in 1:2) {  
	zz := its.entry[3-i]->get();
	private.checkunset(zz);
#
	local v, d;
	if (dep.angle(zz, T, v, d)) {
	  if (is_unset(v)) {
	    values := unset;
	    break;
	  } else {
	    values[i] := v;
	  }
	} else {
	  values := illegal;
	}
      }

# At this point, values is a vector of quanta, unset, or illegal or empty

      v := illegal;
      if (!is_unset(values) && !is_illegal(values)) {
         v := dm.direction(its.code, values);
         if (is_fail(v)) v := illegal;
      }
       
# Try to insert it and emit a value
# event if it worked

      if (self.insert(v)) {
         self->value(its.actualvalue);
      }  else {
         its.actualvalue := illegal;
         its.displayvalue := '';
      }
#
      return its.actualvalue;
    }

    self.disable := function(disable=T) {
      wider its, private;
      if (!its.editable) return F;
      if (disable&&!its.disabled) {
	if (has_field(its, 'menu')&&has_field(its.menu, 'disable')) {
	  its.menu.disable();
	}
	its.topframe->disable();
	for (i in 1:2) {
	  its.entry[i]->background(private.uneditablecolor);
	}
      }
      else if (!disable&&its.disabled) {
	if (has_field(its, 'menu')&&has_field(its.menu, 'enable')) {
	  its.menu.enable();
	}
	its.topframe->enable();
	if (its.editable&&!any(its.extracodes==its.code)) {
	  for (i in 1:2) {
	    if (has_field(its, 'actualvalue')&&is_unset(its.actualvalue)) {
	      its.entry[i]->background(private.unsetcolor);
	    }
            else {
	      its.entry[i]->background(private.editablecolor);
	    }
	  }
	}
      }
      its.disabled := disable;
      return private.disable(its, disable);
    }
    self.done := function() 
    {
      wider its, self;
      if (has_field(its, 'entry')&&has_field(its.entry, 'done'))
	  its.entry.done();
      if (has_field(its, 'optionbutton')&&has_field(its.optionbutton, 'done'))
	  its.optionbutton.done();
      for (field in field_names(its.wrenchmenu)) {
	if (is_record(its.wrenchmenu[field])&&
	   has_field(its.wrenchmenu[field], 'done')) its.wrenchmenu[field].done();
      }
      if (has_field(its, 'codesbutton')&&has_field(its.codesbutton, 'done'))
	  its.codesbutton.done();
      for (field in field_names(its)) val its[field] := F;
      val its := F;
      val self := F;
      return T;
    }

    its.wrench.readonly["Save"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.saverecordviagui(unset, self.get(),
			    spaste('Saved from guientry.', its.widgetname));
    }
    its.wrench.write["Restore"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.restorerecordviagui(self.insertandemit);
    }

    private.makestandard(its, self, parent,
			 title='AIPS++ Direction Chooser');
    # Add a final button
    if (its.editable) {
      include 'selectablelist.g';
      its.wrenchmenu['From sourcelist'] := 
	  widgetset.selectablelist(its.wrenchbutton,
				   its.wrenchbutton,
				   private.sourcelist,
				   label='From source list');
      whenever its.wrenchmenu['From sourcelist']->select do {
	if (is_record($value)&&has_field($value, 'item')) {
	  value := dm.source($value.item);
	  if (self.insert(value)) self->value(its.actualvalue);
	}
      }
    }
#    ok := self.insert(its.defaultvalue);
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }
  
  const public.position := subsequence(parent=unset, value=unset,
				       default=unset, options='',
				       allowunset=F,
				       editable=T, hlp=unset)
  {
    
    wider private;
    widgetset.tk_hold();

    private.initmeasures();
    its := [=];
    its.recordbased := T;
    its.truedefault := dm.position();

    its.parser := 'position';
    its.widgetname := 'position';

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);

    its.putentry := function() {
      wider its, private;

      its.code := 'ITRF';
      for (i in 1:3) {
	its.entry[i]->delete('start', 'end');
      }

      if (is_measure(its.actualvalue)) { 
	its.code := its.actualvalue.refer;
	its.codesbutton.selectlabel(its.code);
        if (has_field(its, 'displayvalue')&&is_defined(its.displayvalue)) {
	  its.codesbutton.disabled(T);
	}
        else {
	  its.codesbutton.disabled(F);
	  its.code := its.actualvalue.refer;
	  its.codesbutton.selectlabel(its.code);
	  its.displayvalue[1] := dq.form.len(its.actualvalue.m2);
	  its.displayvalue[2] := dq.angle(its.actualvalue.m1, form="angle");
	  its.displayvalue[3] := dq.angle(its.actualvalue.m0, form="angle");
	}
      }

      private.setstatus(its);
      
      if (has_field(its, 'entry')) {
	if (is_unset(its.actualvalue)) {
	  for (i in 1:3) {
	    its.entry[i]->delete('start', 'end');
	    its.entry[i]->insert('<unset>');
	    its.entry[i]->background(private.unsetcolor);
	  }
	  return T;
	}
	else if (is_measure(its.actualvalue)&&has_field(its, 'displayvalue')) {
          if (is_string(its.displayvalue)&&(len(its.displayvalue)==1)) {
	    its.entry[3]->insert(its.displayvalue[1]);
	  }
	  else {
	    for (i in 1:3) {
	      if (is_string(its.displayvalue)&&strlen(its.displayvalue[i])) {
		its.entry[i]->insert(its.displayvalue[i]);
	      }
	    }
	  }
	}
	
	# Take care of background colors
	for (i in 1:3) {
	  its.entry[i]->foreground('black');
	  its.entry[i]->disabled(its.disabled||any(its.extracodes==its.code));
	  if (its.editable&&!(its.disabled||any(its.extracodes==its.code))) {
	    its.entry[i]->background(private.editablecolor);
	  }
	  else {
	    its.entry[i]->background(private.uneditablecolor);
	  }
	}
      }
      return T;
    }
    its.clearentry := function() {
      wider its, private;
      its.code := its.codes[1];
      its.codesbutton.selectlabel(its.code);
      its.disabled := !its.editable;
      its.codesbutton.disabled(its.disabled);
      for(i in 1:3) {
	its.entry[i]->delete('start', 'end');
	its.entry[i]->foreground('black');
	its.entry[i]->disabled(its.disabled);
	if (its.editable&&!its.disabled) {
	  its.entry[i]->background(private.editablecolor);
	}
	else {
	  its.entry[i]->background(private.uneditablecolor);
	}
      }
      return T;
    }

    #####################################################################
    # Setup initial values
    
    its.allowunset := allowunset;
    its.editable := editable;
    its.disabled := !its.editable;
    
    if (is_unset(value)&&!allowunset) value:=dm.position('itrf');
    if (is_unset(default)&&!allowunset) default:=dm.position('itrf');
    its.originalvalue := value;
    its.defaultvalue := default;
    its.actualvalue := dm.position('itrf');
    
    codes := dm.listcodes(dm.observatory('VLA'));
    if (is_record(codes)&&has_field(codes, 'normal')&&
       has_field(codes, 'extra')) {
      its.codes := codes.normal;
      its.extracodes := codes.extra;
      its.allcodes := split(paste(its.codes, its.extracodes));
    }
    else {
      widgetset.tk_release();
      return throw(spaste('Value ', value, ' is not a valid position'));
    }
    its.code := 'ITRF';

    its.wrench := [=];
    its.wrench.write['From measures'] := function(ref self, ref its) {
      value := self.get();
      if (serverexists('dm', 'measures', dm)) {
	note('Starting Measures GUI: use Copy (there) and Paste (here) to transfer a measure');
	dm.positiongui();
      }
      else {
	return throw('Measures server is missing: cannot start the Direction GUI');
      }
    }
    its.makeentry := function(ref its, ref self) {
      wider private;
      its.entryframe := [=];
      its.entry := [=];
      hlp:=['Height or Z',
	    'Latitude term (e.g. Declination, Elevation) or Y', 
	    'Longitude term (e.g. Right Ascension, Azimuth) or X'];
      if (any(options=='vertical')) {
        its.entryholderframe := widgetset.frame(its.topframe, side='bottom',
						expand=private.expand,
						borderwidth=private.borderwidth);
      }
      else {
        its.entryholderframe := ref its.topframe;
      }
      its.disabled := !its.editable;
      if (its.editable) {
	for (i in 1:3) {
	  its.entryframe[i] := widgetset.frame(its.entryholderframe,
					       expand=private.expand,
					       side='right',
					       borderwidth=private.borderwidth);
	  its.entry[i] := widgetset.entry(its.entryframe[i],
					  background=private.editablecolor,
					  width=private.width/2,
                                          borderwidth=private.borderwidth);
	  its.entry[i]->bind('<Enter>', 'ent');
	  its.entry[i]->bind('<Leave>', 'lve');
	}
	its.busy := F;
	whenever its.topframe->enter do {
	  whenever its.entry[1]->return, its.entry[1]->lve,
	      its.entry[2]->return, its.entry[2]->lve,
		  its.entry[3]->return, its.entry[3]->lve do {
		    eventname := $name;
		    # Get the value: remember to flip
	  if(!its.busy) {
	      its.busy := T;
	      for (i in 1:3) {
		entry[i] := its.entry[4-i]->get();
		private.checkunset(entry[i]);
	      }
	      # Try to insert it and emit a value
	      # event if it worked
	      if (self.insert(entry)) {
		if(eventname=='return') self->value(its.actualvalue);
	      }
	      else {
		its.actualvalue := illegal;
		its.displayvalue := '';
	      }
	      its.busy := F;
	    }
	}
	  deactivate;
	}
      }
      else {
	for (i in 1:3) {
	  its.entry[i] := widgetset.entry(its.entryholderframe,
					  background=private.uneditablecolor,
					  borderwidth=private.borderwidth,
					  width=private.width);
	  its.entry[i]->disabled(T);
	  widgetset.popuphelp(its.entry[i], hlp[i]);
	}
      }
      its.codesbutton := 
	widgetset.optionmenu(its.topframe,
			       labels=its.allcodes, 
			       names=its.allcodes,
			       borderwidth=private.borderwidth,
			       hlp='Codes for position');
      if (its.editable) {
	whenever its.topframe->enter do {
	  whenever its.codesbutton->select do {
	    its.code := its.codesbutton.getlabel();
	    if (any(its.extracodes)==its.code) {
	      entry[1] := '0m';
	      entry[2] := '0m';
	      entry[3] := '0m';
	      its.disabled := T;
	    }
	    else {
	      for (i in 1:3) {
		entry[i] := its.entry[4-i]->get();
		private.checkunset(entry[i]);
	      }
	      its.disabled := F;
	    }
	    if (self.insert(entry)) self->value(its.actualvalue);
	  }
	}
	deactivate;
      }
    }
    #####################################################################
    self.setwidth := function(value=unset) {
      wider its, self;
      if (is_unset(value)) value:=private.width;
      if (has_field(its, 'entry')) {
        if (any(options=='vertical')) {
	  for(i in 1:3) its.entry[i]->width(value);
	}
	else {
	  for(i in 1:3) its.entry[i]->width(value/3);
	}
      }
      return T;
    }
    self.insert := function(rec=unset, truedefault=F) {
      wider its, private;
      include 'entryparser.g';
      if (!is_record(dep)||!has_field(dep, 'angle')||
	 !is_function(dep['angle'])) {
         return throw('Entry parser not valid',
                      origin='guientry.position');
      }

      if (truedefault) rec:=its.truedefault;

      its.displayvalue := ['', '', ''];
      its.actualvalue := illegal;

      if (is_unset(rec)&&its.allowunset) {
	its.actualvalue := unset;
	its.displayvalue := '<unset>';
	its.putentry();
	return T;
      }
      else if (is_string(rec)) {
	rec := split(rec);
        its.actualvalue := [=];
	its.actualvalue.refer := its.codesbutton.getlabel();
	if (dep.angle(rec[1], its.allowunset, its.actualvalue.m0,
		     its.displayvalue[1])&&
	   dep.angle(rec[2], its.allowunset, its.actualvalue.m1,
		     its.displayvalue[2])&&
	   dep.quantity.parse(rec[3], its.allowunset, its.actualvalue.m2,
			      its.displayvalue[3], type='len')) {
	  its.actualvalue.type := 'position';
	  its.actualvalue.refer := its.codesbutton.getlabel();
	  its.putentry();
	  return T;
	}
	else if (dep['measure'](rec[1], its.allowunset, its.actualvalue,
				its.displayvalue, type='position')) {
	  its.putentry();
	  return T;
	}
	its.actualvalue := illegal;
	its.displayvalue := '';
	its.putentry();
	return F;
      }
      else if (is_measure(rec)&&(rec.type=='position')) {
        its.actualvalue := rec;
	its.codesbutton.setlabel(its.actualvalue.refer);
	its.putentry();
	return T;
      }
      else {
        private.errormessage(rec, 'measure');
        return F;
      }
    }
    self.get := function() {
      wider private, its;
      if (is_illegal(its.actualvalue)) return illegal;
      # Get the value: remember to flip
      entry := "";
      for (i in 1:3) {
        zz := its.entry[4-i]->get();
        private.checkunset(zz);
        if (is_unset(zz)) {
           entry := unset; 
           break;
        } else { 
           entry[i] := zz;
        }
      }  
       
      # Try to insert it and emit a value
      # event if it worked
      if (self.insert(entry)) {
        self->value(its.actualvalue);
      }
      else {
        its.actualvalue := illegal;
        its.displayvalue := '';
      }
      return its.actualvalue;
    }
    self.disable := function(disable=T) {
      wider its, private;
      if (!its.editable) return F;
      if (disable&&!its.disabled) {
	if (has_field(its, 'menu')&&has_field(its.menu, 'disable')) {
	  its.menu.disable();
	}
	its.topframe->disable();
	for (i in 1:3) {
	  its.entry[i]->background(private.uneditablecolor);
	}
      }
      else if (!disable&&its.disabled) {
	if (has_field(its, 'menu')&&has_field(its.menu, 'enable')) {
	  its.menu.enable();
	}
	its.topframe->enable();
	if (its.editable&&!any(its.extracodes==its.code)) {
	  for (i in 1:3) {
	    if (has_field(its, 'actualvalue')&&is_unset(its.actualvalue)) {
	      its.entry[i]->background(private.unsetcolor);
	    }
	    else {
	      its.entry[i]->background(private.editablecolor);
	    }
	  }
	}
      }
      its.disabled := disable;
      return private.disable(its, disable);
    }
    self.done := function() 
    {
      wider its, self;
      if (has_field(its, 'entry')&&has_field(its.entry, 'done'))
	  its.entry.done();
      if (has_field(its, 'optionbutton')&&has_field(its.optionbutton, 'done'))
	  its.optionbutton.done();
      for (field in field_names(its.wrenchmenu)) {
	if (is_record(its.wrenchmenu[field])&&
	   has_field(its.wrenchmenu[field], 'done')) its.wrenchmenu[field].done();
      }
      if (has_field(its, 'codesbutton')&&has_field(its.codesbutton, 'done'))
	  its.codesbutton.done();
      for (field in field_names(its)) val its[field] := F;
      val its := F;
      val self := F;
      return T;
    }
    its.wrench.readonly["Save"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.saverecordviagui(unset, self.get(),
			    spaste('Saved from guientry.', its.widgetname));
    }
    its.wrench.write["Restore"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.restorerecordviagui(self.insertandemit);
    }
    private.makestandard(its, self, parent,
			 title='AIPS++ Direction Chooser');
    ok := self.insert(its.originalvalue);
    # Add a final button
    if (its.editable) {
      include 'selectablelist.g';
      its.wrenchmenu['Observatorylist'] := 
	  widgetset.selectablelist(its.wrenchbutton,
				   its.wrenchbutton,
				   split(dm.obslist()),
				   label='From observatory list');
      whenever its.wrenchmenu['Observatorylist']->select do {
	if (is_record($value)&&has_field($value, 'item')) {
	  value := dm.observatory($value.item);
	  if (self.insert(value)) self->value(its.actualvalue);
	}
      }
    }
    ok := widgetset.tk_release();
  }
  
  const public.measurecodes := subsequence(parent=unset, 
					   value=unset,
					   default=unset,
					   options='frequency',
					   allowunset=F,
					   editable=T, hlp=unset)
  {
    
    wider private, public;

    private.initmeasures();

    its.codes := 'unknown';

    if ((options=='frequency')||
       (options=='epoch')||
       (options=='direction')||
       (options=='position')||
       (options=='doppler')||
       (options=='radialvelocity')||
       (options=='baseline')||
       (options=='earthmagnetic')||
       (options=='uvw')) {
      its.codes := [dm.listcodes(dm[options]()).normal,
		    dm.listcodes(dm[options]()).extra];
    }
    else {
      return throw(paste('Unknown measure type ', options));
    }

    self := public.choice(parent=parent, value=value, default=default,
			  options=its.codes, allowunset=allowunset,
			  editable=editable, hlp=unset);
  }

  const public.measure := subsequence(parent=unset, value=unset, default=unset,
				      options='', allowunset=F, editable=T,
				      hlp=unset)
  {
    
    wider private, public;

    widgetset.tk_hold();

    private.initmeasures();

    if (is_measure(value)) {
      if (value.type=='epoch') {
	self := public.epoch(parent, value, default, options, allowunset, editable, hlp=hlp);
      }
      else if (value.type=='direction') {
	self := public.direction(parent, value, default, options, allowunset, editable, hlp=hlp);
      }
      else if (value.type=='position') {
	self := public.position(parent, value, default, options, allowunset, editable, hlp=hlp);
      }
      else if ((value.type=='frequency')||
	      (value.type=='radialvelocity')||
	      (value.type=='doppler')) {
	self := public.scalarmeasure(parent, value, default, allowunset,
				     options,
				     editable, type=value.type, hlp=hlp);
      }
    }
    else {
      self := public.genericmeasure(parent, value, default, options, allowunset, editable, hlp=hlp);
    }
  }    

  const public.genericmeasure := subsequence(parent=unset, value=unset, default=unset,
					     options='', allowunset=F, editable=T, hlp=unset)
  {
    
    private.initmeasures();
    its := [=];
    its.recordbased := T;
    its.truedefault := dm.direction();

    its.parser := 'measure';
    its.widgetname := 'genericmeasure';

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);

    its.allowunset := allowunset;
    its.editable := editable;
    its.disabled := !its.editable;
    
    its.type := unset;
    
    if (is_unset(value)&&!allowunset) value:=dm.direction('');
    if (is_unset(default)&&!allowunset) default:=dm.direction('');
    its.originalvalue := value;
    its.defaultvalue := default;
    
    its.wrench := [=];
    its.wrench.write['From measures'] := function(ref self, ref its) {
      value := self.get();
      if (serverexists('dm', 'measures', dm)) {
	note('Starting Measures GUI: use Copy (there) and Paste (here) to transfer a measure');
	dm.gui();
      }
      else {
	return throw('Measures server is missing: cannot start the GUI');
      }
    }
    its.wrench.readonly["Save"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.saverecordviagui(unset, self.get(),
			    spaste('Saved from guientry.', its.widgetname));
    }
    its.wrench.write["Restore"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.restorerecordviagui(self.insertandemit);
    }
    #####################################################################
    # Public interface
    self.insert := function(rec=unset, truedefault=F) {
      wider its, private;
      include 'entryparser.g';
      if (!is_record(dep)||!has_field(dep, 'measure')||
	 !is_function(dep['measure'])) {
         return throw('Entry parser not valid',
                      origin='guientry.measure');
      }

      if (truedefault) rec:=its.truedefault;

      if (dep.measure(rec, its.allowunset, its.actualvalue,
		     its.displayvalue, its.type)) {
	its.putentry();
	return T;
      }
      else {
        private.errormessage(rec, 'measure');
	private.setstatus(its);
        return F;
      }
    }
    private.makestandard(its, self, parent,
			 title='AIPS++ Measure Chooser');
#    ok := self.insert(its.defaultvalue);
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }
  
  const public.quantity := subsequence(parent=F, value=unset, default=unset,
				       type=unset, options='', allowunset=F,
				       editable=T, hlp=unset) {
    
    wider private;
    widgetset.tk_hold();
    
    its := [=];
    its.recordbased := T;

    its.parser := 'quantity';
    its.widgetname := 'quantity';
    its.truedefault := unset;

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      return throw('Arguments are invalid');
    }
    private.makestandardfunctions(its, self);

    # Defer inclusion to avoid circular dependencies
    include 'quanta.g';
    
    if (!is_defined('dq')) {
      return throw('defaultquanta does not exist');
    }
    
    its.putentry := function() {
      wider its, private;
      if (!is_unset(its.actualvalue)) {
	its.optionbutton.selectlabel(its.actualvalue.unit);
      }
      if (its.disabled) its.optionbutton.disabled(T);
      return private.putentry(its);

    }
    #####################################################################
    # Setup initial values
    include 'entryparser.g';
    if (is_string(type)) {
      its.type := type;
    }
    else if (!is_unset(type)) {
      its.type := type;
    }
    else if (!is_unset(options)&&any(options==dep.quantity.types())) {
      its.type := options;
    }
    else {
      include 'entryparser.g';
      if (!is_record(dep)||!has_field(dep, 'quantity')||
	 !is_record(dep['quantity'])) {
         return throw('Entry parser not valid',
                      origin='guientry.quantity');
      }
      its.type := unset;
      if (is_fail(dep.quantity.findtype(its.originalvalue, its.defaultvalue,
					its.type))) {
	widgetset.tk_release();
	return throw('Cannot find type', origin='guientry.quantity');
      }
    }
    
    its.makeentry := function(ref its, ref self) {
      wider private;
      include 'entryparser.g';
      labels:=dep.quantity.type(its.type);
      if (is_fail(labels)) fail;
      names:=dep.quantity.type(its.type);
      if (is_fail(names)) fail;
      its.optionbutton :=  widgetset.optionmenu(its.topframe, labels=labels,
						names=names,
						borderwidth=private.borderwidth);
      widgetset.popuphelp(its.optionbutton, 'Units for Quantity');
      its.disabled := !its.editable;
      if (its.editable) {
	whenever its.topframe->enter do {
	  whenever its.optionbutton->select do {
	    its.unit := its.optionbutton.getlabel();
	    entry := its.entry->get();
	    private.checkunset(entry);
	    if (self.insert(entry)) self->value(its.actualvalue);
	  }
	  deactivate;
	}
	its.entryframe := widgetset.frame(its.topframe, side='right',
					  expand=private.expand,
					  borderwidth=private.borderwidth);
	widgetset.popuphelp(its.entryframe, its.hlp);
	its.entry := widgetset.entry(its.entryframe,
				     background=private.editablecolor,
				     width=private.width,
				     borderwidth=private.borderwidth);
	whenever its.topframe->enter do {
	  widgetset.popuphelp(its.entry,  its.hlp);
	  whenever its.entry->return, its.entry->lve  do {
	    eventname := $name;
	    # Get the value
	    entry := its.entry->get();
	    # If its the nodisplay string for this type then
	    # just emit an event
	    if (has_field(its, 'nodisplay')&&is_string(its.nodisplay)&&
	       (entry==its.nodisplay)) {
	      if(eventname=='return') self->value(its.actualvalue);
	    }
	    else {
	      private.checkunset(entry);
	      # Otherwise try to insert it and emit a value
	      # event if it worked
	      if (self.insert(entry)) {
		if(eventname=='return') self->value(its.actualvalue);
	      }
	      else {
		its.actualvalue := illegal;
		its.displayvalue := '';
	      }
	    }
	  }
	  deactivate;
	}
      }
      else {
	its.entry := widgetset.entry(its.topframe,
				     background=private.uneditablecolor,
				     borderwidth=private.borderwidth,
				     width=private.width);
	widgetset.popuphelp(its.entry,  its.hlp);
	its.entry->disabled(T);
      }
    }
	
    #####################################################################
    # Public interface
    
    self.insert := function(rec=unset, truedefault=F) {
      wider its, private;
      
      include 'entryparser.g';
      if (!is_record(dep)||!has_field(dep, 'quantity')||
	 !is_record(dep['quantity'])) {
         return throw('Entry parser not valid',
                      origin='guientry.quantity');
      }
#
      if (truedefault) rec:=its.truedefault;

      if (dep.quantity.parse(rec, its.allowunset, its.actualvalue,
			    its.displayvalue, its.type, its.unit)) {
	its.putentry();
	return T;
      }
      else {
	private.errormessage(rec, 'quantity');
	private.setstatus(its);
        return F;
      }
    }
    self.disable := function(disable=T) {
      wider its, private;
      if (!its.editable) return F;
      if (disable&&!its.disabled) {
	its.optionbutton.disabled(disable);
      }
      else if (!disable&&its.disabled) {
	its.optionbutton.disabled(disable);
      }
      return private.disable(its, disable);
    }
    self.get := function() {
      wider its, private;
      value := private.get(its, self);
      return value;
    }

    its.wrench := [=];

    its.wrench.readonly["Save"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.saverecordviagui(unset, self.get(),
			    spaste('Saved from guientry.', its.widgetname));
    }

    its.wrench.write["Restore"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.restorerecordviagui(self.insertandemit);
    }

    private.makestandard(its, self, parent, addunsetframe=F,
			 title='AIPS++ Quantity Chooser',
			 allowclear=T);

#    ok := self.insert(its.defaultvalue);
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  } 
 
  const public.range := subsequence(parent=unset, value=0, default=0,
				    options='',
				    allowunset=F, editable=T,
				    rmin=0.0, rmax=1.0, rresolution=0.1,
				    provideentry=F, hlp=unset)
  {
    
    wider private;
    widgetset.tk_hold();
    
    its := [=];
    its.hlp := hlp;
    its.recordbased := F;

    its.parser := 'scalar';
    its.widgetname := 'range';
    its.truedefault := 0;

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);

    its.cast := function(value) {
      if (is_numeric(value)) {
	if (its.types == 'integer') {
	  return as_integer(value);
	} else {
	  return as_double(value);
	}
      }
      else {
        return value;
      }
    }
    
   its.putentry := function() {
      wider its, private;
      if (!its.disabled) {
	its.entry.enable();
      }
      private.setstatus(its);
      if (!is_unset(its.actualvalue)) its.entry.setvalues(its.actualvalue);
      if (its.disabled) {
	its.entry.disable();
      }
      return T;
    }
    its.clearentry := function() {
      wider its, private;
      return F;
    }
    
    #####################################################################
    # Setup initial values
    
    its.allowunset := allowunset;
    its.editable := editable;
    its.disabled := !its.editable;
    its.actualvalue := value;
    
    if (is_integer(rresolution)) {
      its.types := 'integer';
    }
    else {
      its.types := 'double';
    }

    its.originalvalue := value;
    its.defaultvalue := default;

    its.makeentry := function(ref its, ref self) {
      wider private;
      its.entryframe := widgetset.frame(its.topframe, 
					side='right',
					borderwidth=private.borderwidth);
      widgetset.popuphelp(its.entryframe, its.hlp);

      its.entry := widgetset.multiscale(its.entryframe, names='',
					background=private.background,
					start=rmin, end=rmax, values=rmin,
					resolution=rresolution, length=145,
					entry=provideentry, 
					extend=provideentry,
					borderwidth=private.borderwidth);
      if (is_fail(its.entry)) {
	widgetset.tk_release();
	fail;
      }
      if (its.editable) {
	whenever its.entry->values do {
	  its.actualvalue := $value;
	  its.displayvalue := $value;
	  self->value(its.actualvalue);
	}
      }
      else {
	its.entry.disable();
      }
    }
    
    #####################################################################
    # Public interface

    # set the range of the multiscale
    self.setrange := function(...) {
      wider its;
      its.entry.setrange(...);
    }
    
    self.setwidth := function(value) {
      wider its, self;
      if (is_unset(value)) value:=private.width;
      if (has_field(its, 'entry')) its.entry->width(value);
      return T;
    }
    self.insert := function(rec=unset, truedefault=F) {
      wider private, its;
      include 'entryparser.g';
      if (!is_record(dep)||!has_field(dep, 'scalar')||
	 !is_function(dep['scalar'])) {
	return throw('Entry parser not valid',
		     origin='guientry.range');
      }
      
      if (truedefault) rec:=its.truedefault;

      if (dep['scalar'](rec, its.allowunset, its.actualvalue,
		       its.displayvalue)) {
	its.putentry();
	return T;
      }
      else {
	private.errormessage(rec, 'scalar');
	private.setstatus(its);
	return F;
      }
    }
    self.get := function() {
      wider its, private;
      return its.cast(private.get(its, self));
    }
    self.disable := function(disable=T) {
      wider its, private;
      if (!its.editable) return F;
      if (disable&&!its.disabled) {
	its.entry.disable();
      }
      else if (!disable&&its.disabled) {
	its.entry.enable();
      }
      return private.disable(its, disable);
    }

    private.makestandard(its, self, parent, addunsetframe=T,
			 title='AIPS++ Range Chooser',
			 allowclear=F);
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }
  
  const public.record := subsequence(parent=unset, value=[=], default=[=],
				     options='', allowunset=F, editable=T,
				     hlp=unset)
  {
    
    wider private;
    widgetset.tk_hold();
    
    its := [=];
    its.recordbased := T;
    its.truedefault := [=];

    its.parser := 'record';
    its.widgetname := 'record';

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);

    its.wrench := [=];

    its.wrench.write["Edit"] := function(ref self, ref its) {
      value := self.get();
      if (!is_unset(value)&&!is_fail(value)) {
	rb:=widgetset.recordbrowser(therecord=value, readonly=F);
	if (self.insert(value)) self->value(its.actualvalue);
      }
    }

    its.wrench.readonly["View"] := function(ref self, ref its) {
      value := self.get();
      if (!is_unset(value)&&!is_fail(value)) {
	rb:=widgetset.recordbrowser(therecord=value, readonly=T);
      }
    }

    its.wrench.readonly["Save"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.saverecordviagui(unset, self.get(),
			    spaste('Saved from guientry.', its.widgetname));
    }

    its.wrench.write["Restore"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.restorerecordviagui(self.insertandemit);
    }

    its.makeentry := function(ref its, ref self) {
      wider private, its, self;
      its.disabled := !its.editable;
      if (its.editable) {
	its.entryframe := widgetset.frame(its.topframe, side='right',
					  expand=private.expand,
					  borderwidth=private.borderwidth);
	widgetset.popuphelp(its.entryframe, its.hlp);
	its.entry := widgetset.entry(its.entryframe,
				     background=private.editablecolor,
				     width=private.width,
				     borderwidth=private.borderwidth);
	whenever its.topframe->enter do {
	  widgetset.popuphelp(its.entry,  its.hlp);
	  whenever its.entry->return, its.entry->lve  do {
	    eventname := $name;
	    # Get the value
	    entry := its.entry->get();
	    # If its the nodisplay string for this type then
	    # just emit an event
	    if (has_field(its, 'nodisplay')&&is_string(its.nodisplay)&&
	       (entry==its.nodisplay)) {
	      if(eventname=='return') self->value(its.actualvalue);
	    }
	    else {
	      private.checkunset(entry);
	      # Otherwise try to insert it and emit a value
	      # event if it worked
	      if (self.insert(entry)) {
		if(eventname=='return') self->value(its.actualvalue);
	      }
	      else {
		its.actualvalue := illegal;
		its.displayvalue := '';
	      }
	    }
	  }
	  deactivate;
	}
      }
      else {
	its.entry := widgetset.entry(its.topframe,
				     background=private.uneditablecolor,
				     borderwidth=private.borderwidth,
				     width=private.width);
	widgetset.popuphelp(its.entry,  its.hlp);
	its.entry->disabled(T);
      }
      return T;
    };
    private.makestandard(its, self, parent, title='AIPS++ Record Chooser');
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }
  
  const public.coordinates := subsequence(parent=unset, value=unset,
					  default=unset,
					  options='', allowunset=F,
					  editable=T, hlp=unset)
  {
    wider private;
    widgetset.tk_hold();

    its := [=];
    its.recordbased := F;
    its.truedefault := [=];

    its.parser := 'coordinates';
    its.widgetname := 'coordinates';

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);

    its.nodisplay := '<coordinates>';
    its.whenever := -1;
    
    if (its.editable) background := private.editablecolor;
    
    its.wrench := [=];

    self.insertandemit := function(rec) {
      wider self;
      t := self.insert(rec);
      if (t) {
	self->value(its.actualvalue);
      }
      return t;
    }
    self.done := function() 
    {
      wider its, self;
      val its := F;
      val self := F;

      return T;
    }
    its.wrench.readonly["Save"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.saverecordviagui(unset, self.get(),
			    spaste('Saved from guientry.', its.widgetname));
    }
    its.wrench.write["Restore"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.restorerecordviagui(self.insertandemit);
    }
    private.makestandard(its, self, parent, title='AIPS++ Coordinates Chooser');
#    ok := self.insert(its.defaultvalue);
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }
  
  const public.region := subsequence(parent=unset, value=unset, default=unset,
				     options='', allowunset=F, editable=T, hlp=unset)
  {
    wider private;
    widgetset.tk_hold();

    its := [=];
    its.recordbased := T;
    its.truedefault := [=];

    its.parser := 'region';
    its.widgetname := 'region';

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);

    include 'regionmanager.g';

    if (!serverexists('drm', 'regionmanager', drm)) {
      widgetset.tk_release();
      return throw ('The default regionmanager drm is either not running or not valid',
		    origin='regionentry.g');
    }
    
    its.nodisplay := '<region>';
    its.whenever := -1;
    
    if (its.editable) background := private.editablecolor;
    
    its.wrench := [=];

    its.getandgo := function(value) {
      wider self;
      include 'toolmanager.g';
      if (is_string(value)) {
	self.insertandemit(value);
      }
      else {
	name := self.get();
	if (!is_string(name)) {
	  name := 'myregion';
	}
	name := tm.getnewitemname(name);
	note('Constructing new region called ', name);
	symbol_set(name, value);
	self.insertandemit(name);
      }
  }
    
    its.wrench.write['From image'] := function(ref self, ref its) {
	include 'gopher.g';
	if (self.hascontext('image')) {
	    dgo.fromimage(self.getcontext('image'), 'region', its.getandgo);
	}
	else {
	    dgo.fromimage(unset, 'region', its.getandgo);
	}
    }
    its.wrench.write["Create"] := function(ref self, ref its) {
	msg := 'Starting regionmanager GUI. Create and select a region';
	note (msg, priority='NORMAL', origin='guientry.region');
	drm.gui();
	drm.setselectcallback(its.getandgo);
    }
    
    its.wrench.readonly["Save"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.saverecordviagui(unset, self.get(),
			    spaste('Saved from guientry.', its.widgetname));
    }
    its.wrench.write["Restore"] := function(ref self, ref its) {
      include 'recordmanager.g';
      drcm.restorerecordviagui(self.insertandemit);
    }

    self.insertandemit := function(rec) {
      wider self; 
      t := self.insert(rec);
      if (t) {
	self->value(its.actualvalue);
      }
      return t;
    }

    #self.dismiss := function() {
      #If this function shuts any open windows, it could be used as a quicker alternative to done
    #}

    self.done := function() 
    {
      wider its, self;
      if (is_function(drm.getselectcallback()) &&
	  drm.getselectcallback()==self.insert) {
	drm.setselectcallback(0);
      }
      val its := F;
      val self := F;

      return T;
    }

    its.makeentry := function(ref its, ref self) {
      wider private, its, self;
      its.disabled := !its.editable;
      if (its.editable) {
	its.entryframe := widgetset.frame(its.topframe, side='right',
					  expand=private.expand,
					  borderwidth=private.borderwidth);
	widgetset.popuphelp(its.entryframe, its.hlp);
	its.entry := widgetset.entry(its.entryframe,
				     background=private.editablecolor,
				     width=private.width,
				     borderwidth=private.borderwidth);
	whenever its.topframe->enter do {
	  widgetset.popuphelp(its.entry,  its.hlp);
	  whenever its.entry->return, its.entry->lve  do {
	    eventname := $name;
	    # Get the value
	    entry := its.entry->get();
	    # If its the nodisplay string for this type then
	    # just emit an event
	    if (has_field(its, 'nodisplay')&&is_string(its.nodisplay)&&
	       (entry==its.nodisplay)) {
	      if(eventname=='return') self->value(its.actualvalue);
	    }
	    else {
	      private.checkunset(entry);
	      # Otherwise try to insert it and emit a value
	      # event if it worked
	      if (self.insert(entry)) {
		if(eventname=='return') self->value(its.actualvalue);
	      }
	      else {
		its.actualvalue := illegal;
		its.displayvalue := '';
	      }
	    }
	  }
	  deactivate;
	}
      }
      else {
	its.entry := widgetset.entry(its.topframe,
				     background=private.uneditablecolor,
				     borderwidth=private.borderwidth,
				     width=private.width);
	widgetset.popuphelp(its.entry,  its.hlp);
	its.entry->disabled(T);
      }
      return T;
    };
    private.makestandard(its, self, parent, title='AIPS++ Region Chooser');
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }
  
  const public.model := subsequence(parent=unset, value=unset, default=unset,
			            options='', allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'modelmanager.g';

    self := private.genericitem(createdefaultmodelmanager, 'model',
                                parent, value, default, options, allowunset,
                                editable, hlp);
  }

  const public.modellist := subsequence(parent=unset, value=unset, 
                                        default=unset, options='', 
                                        allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'modlistmanager.g';

    self := private.genericitem(createdefaultmodellistmanager, 'modellist',
                                parent, value, default, options, allowunset,
                                editable, hlp);
  }

  const public.selection := subsequence(parent=unset, value=unset, 
                                        default=unset, options='', 
                                        allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'selectmanager.g';

    self := private.genericitem(createdefaultselectionmanager, 'selection',
                                parent, value, default, options, allowunset,
                                editable, hlp);
  }

  const public.calibration := subsequence(parent=unset, value=unset, 
                                          default=unset, options='', 
                                          allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'calmanager.g';

    self := private.genericitem(createdefaultcalibrationmanager, 'calibration',
                                parent, value, default, options, allowunset,
                                editable, hlp);
  }

  const public.calibrationlist := subsequence(parent=unset, value=unset, 
                                              default=unset, options='', 
                                              allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'callistmanager.g';

    self := private.genericitem(createdefaultcalibrationlistmanager, 
                                'calibrationlist', parent, value, 
                                default, options, allowunset, editable, hlp);
  }

  const public.solver := subsequence(parent=unset, value=unset, 
                                     default=unset, options='', 
                                     allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'solvermanager.g';

    self := private.genericitem(createdefaultsolvermanager, 'solver',
                                parent, value, default, options, allowunset,
                                editable, hlp);
  }

  const public.solverlist := subsequence(parent=unset, value=unset, 
                                         default=unset, options='', 
                                         allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'slvlistmanager.g';

    self := private.genericitem(createdefaultsolverlistmanager, 'solverlist',
                                parent, value, default, options, allowunset,
                                editable, hlp);
  }

  const public.freqsel := subsequence(parent=unset, value=unset, 
                                      default=unset, options='', 
                                      allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'freqselmanager.g';

    self := private.genericitem(createdefaultfreqselmanager, 'freqsel',
                                parent, value, default, options, allowunset,
                                editable, hlp);
  }


  const public.restoringbeam := subsequence(parent=unset, value=unset, 
                                            default=unset, options='', 
                                            allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'beammanager.g';

    self := private.genericitem(createdefaultrestoringbeammanager, 
                                'restoringbeam', parent, value, 
                                default, options, allowunset, editable, hlp);
  }

  const public.deconvolution := subsequence(parent=unset, value=unset, 
                                            default=unset, options='', 
                                            allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'deconvmanager.g';

    self := private.genericitem(createdefaultdeconvolutionmanager, 
                                'deconvolution', parent, value, 
                                default, options, allowunset, editable, hlp);
  }

  const public.imagingcoord := subsequence(parent=unset, value=unset, 
                                           default=unset, options='', 
                                           allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'imcoordmanager.g';

    self := private.genericitem(createdefaultimagingcoordmanager, 
                                'imagingcoord', parent, value, 
                                default, options, allowunset, editable, hlp);
  }

  const public.imagingfield := subsequence(parent=unset, value=unset, 
                                           default=unset, options='', 
                                           allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'imgfldmanager.g';

    self := private.genericitem(createdefaultimagingfieldmanager, 
                                'imagingfield', parent, value, 
                                default, options, allowunset, editable, hlp);
  }

  const public.imagingfieldlist := subsequence(parent=unset, value=unset, 
                                               default=unset, options='', 
                                               allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'imflistmanager.g';

    self := private.genericitem(createdefaultimagingfieldlistmanager, 
                                'imagingfieldlist', parent, value, 
                                default, options, allowunset, editable, hlp);
  }

  const public.imagingweight := subsequence(parent=unset, value=unset, 
                                            default=unset, options='', 
                                            allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'imwgtmanager.g';

    self := private.genericitem(createdefaultimagingweightmanager, 
                                'imagingweight', parent, value, 
                                default, options, allowunset, editable, hlp);
  }

  const public.mask := subsequence(parent=unset, value=unset, 
                                   default=unset, options='', 
                                   allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'maskmanager.g';

    self := private.genericitem(createdefaultmaskmanager, 
                                'mask', parent, value, 
                                default, options, allowunset, editable, hlp);
  }

  const public.transform := subsequence(parent=unset, value=unset, 
                                        default=unset, options='', 
                                        allowunset=F, editable=T, hlp=unset)
  {
    wider private;

    include 'toolmanager.g';
    include 'transfmmanager.g';

    self := private.genericitem(createdefaulttransformmanager, 
                                'transform', parent, value, 
                                default, options, allowunset, editable, hlp);
  }

  const public.scalar := function(parent=unset, value=unset, default=unset,
				  options='', allowunset=F, editable=T,
				  hlp=unset) {
    wider private;
    if (!allowunset) {
      if (is_unset(value)) {
	if (is_string(options)) {
	  value := 0;
	} else {
	  value := options;
	}
      }
      if (is_unset(default)) default := value;
    }
    return private.generic('scalar', parent, value, default,
			   allowunset, editable, options, hlp);
  }

  # .twoentry basically just lets two boxes be used via an array
  # Does no error checking.
  const public.twoentry := subsequence(parent=unset, value=unset, default=unset,
				       options='', allowunset=F, editable=T, min=-1,
				       max=1, widths=10, hlp=unset)      
  {

      wider private;

      maxbox := widgetset.entry(parent, width = widths);
      maxlabel := widgetset.label(parent, text='  Max: ');
      
      minbox := widgetset.entry(parent, width = widths);
      minlabel := widgetset.label(parent, text='  Min: ');

      whenever minbox->return, maxbox->return do
      {
	  self->return([minbox->get(), maxbox->get()])
      }

      self.insert := function(toinsert)
      {
	  minbox->delete('start', 'end');
	  minbox->insert(toinsert[1], 'start');
	  if (len(toinsert)>=2) {
	      maxbox->delete('start', 'end');
	      maxbox->insert(toinsert[2], 'start');	    
	  }
	  else {
	      maxbox->delete('start', 'end');
	      maxbox->insert('Oh no.', 'start');
	  }
      }

      self.get := function()
      {
	  return [minbox->get(), maxbox->get()];
      }

      self.enable := function()
      {
	  minbox.enable();
	  maxbox.enable();
      }
	  
      self.disable := function()
      {
	  minbox.disable();
	  maxbox.disable();
      }

      return [maxbox,maxlabel,minbox,minlabel];
  }


  const public.string := subsequence(parent=unset, value='', default='',
				     options='',
				     allowunset=F,
			             editable=T, onestring=T, hlp=unset)
  {
    
    wider private;
    widgetset.tk_hold();

    its := [=];
    its.recordbased := F;
    its.truedefault := '';

    its.parser := 'string';
    its.widgetname := 'string';
    if (is_fail(private.stringarguments(its, value, default, allowunset,
				       editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);

    its.viewright := T;
    its.onestring := onestring;
    its.hlp := hlp;                # Overwrite one stringarguments put here

    its.putentry := function() {
      wider its, private;
      height := len(its.actualvalue);
      its.entry->delete('start', 'end');
      private.setstatus(its);

      if (is_unset(its.actualvalue)) {
	if (has_field(its, 'entry')) {
	  its.entry->disabled(F);
	  if (its.onestring) {
	    its.entry->insert('<unset>');
	  }
	  else {
	    its.entry->insert('<unset>', 'start');
	    its.entry->height(1);
	    its.entry->see('start');
	  }
	  its.entry->background(private.unsetcolor);
	  its.entry->disabled(!its.editable);
	  return T;
	}
      }
      else {
	its.entry->disabled(F);
        if (its.onestring&&is_string(its.displayvalue)) {
	  its.entry->insert(its.displayvalue);
	}
	else {
	  if (is_string(its.displayvalue)) {
	    its.entry->insert(its.displayvalue, 'start');
	  }
	  its.entry->height(min(3,height));
	  its.entry->see('start');
	}
	its.entry->foreground('black');
	its.entry->background('white');
	its.entry->disabled(its.disabled);
	if (its.editable&&!its.disabled) {
	  its.entry->background(private.editablecolor);
	}
	else {
	  its.entry->background(private.uneditablecolor);
	}
	its.entry->disabled(!its.editable);
      }
      return T;
    }

    its.clearentry := function() {
      wider its, private;
      its.entry->delete('start', 'end');
      if (!its.onestring) {
	its.entry->height(1);
      }
      return T;
    }

    its.adjustheight := function() {
      wider its;
      itxt := as_byte(its.entry->get('start', 'end'));
      height := min(3, len(itxt[itxt == 10]));
      if (height != its.height) {
 	its.height := height;
 	its.entry->height(its.height);
      }
    }

    its.makeentry := function(ref its, ref self) {
      
      wider private;
      its.disabled := !its.editable;
      its.entryframe := widgetset.frame(its.topframe, side='right',
					expand=private.expand,
					borderwidth=private.borderwidth);
      its.height := 1;
      local hlpstring;
      if (is_unset(its.hlp)) {
         hlpstring := 'Multiple strings will be displayed on different lines: use the up and down arrow keys to scroll up and down in the list of strings';
         if (its.onestring) {
            hlpstring := 'Enter string here';
         }
      } else {
         hlpstring := its.hlp;
      }      
      widgetset.popuphelp(its.entryframe, hlpstring);

      if (its.editable) {
        if (its.onestring) {
	  its.entry := widgetset.entry(its.entryframe,
				       background=private.editablecolor,
				       width=private.width,
				       borderwidth=private.borderwidth);
          whenever its.entry->return, its.entry->lve  do {
	    eventname := $name;
	    if (self.insert(self.get())) {
	      if(eventname=='return') self->value(its.actualvalue);
	    }
	  }
	}
	else {
	  its.entry := widgetset.text(its.entryframe,
				      background=private.editablecolor,
				      width=private.width,
				      height=its.height,
				      borderwidth=private.borderwidth);
	  # Check for \n every character!
 	  whenever its.entry->yscroll do {
	    its.adjustheight();
  	  }
	}
      }
      else {
        if (its.onestring) {
	  its.entry := widgetset.entry(its.entryframe,
				       background=private.uneditablecolor,
				       width=private.width,
				       borderwidth=private.borderwidth);
 	}
 	else {
	  its.entry := widgetset.text(its.entryframe,
				      background=private.uneditablecolor,
				      width=private.width,
				      height=its.height,
				      borderwidth=private.borderwidth);
	  # Check for \n every character!
	  whenever its.entry->yscroll do {
	    its.adjustheight();
	  }
 	}
	its.entry->disabled(T);
      }
      widgetset.popuphelp(its.entry, hlpstring);
      its.clearentry();
    }
  
    self.get := function() {
      wider private, its;
      if (is_illegal(its.actualvalue)) return illegal;
      entry := its.displayvalue;
      if (its.editable&&!its.disabled) {
        if (its.onestring) {
	  entry := its.entry->get();
	}
	else {
	  entry := split(its.entry->get('start', 'end'), '\n');
	}
	private.checkunset(entry);
	self.insert(entry);
      }
      return its.actualvalue;
    }

    self.insert := function(rec=unset, truedefault=F) {
      wider its, private;
      include 'entryparser.g';
      if (!is_record(dep)||!has_field(dep, its.parser)||
	 !is_function(dep[its.parser])) {
	return throw('Entry parser not valid',
		     origin=spaste('guientry.',its.parser));
      }
      
      if (truedefault) rec:=its.truedefault;

      if (dep[its.parser](rec, its.allowunset, its.actualvalue,
			 its.displayvalue)) {
	its.putentry();
	return T;
      }
      else {
	private.errormessage(rec, its.parser);
	private.setstatus(its);
	return F;
      }
    }

    private.makestandard(its, self, parent, title='AIPS++ String Chooser');
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
  }
  const public.tool := subsequence(parent=unset, value=unset,
				   default=unset,
				   options='',
				   allowunset=F,
				   editable=T, hlp=unset)
  {
    
    wider private;
    widgetset.tk_hold();
    
    its := [=];
    its.recordbased := T;
    its.truedefault := F;
    its.nodisplay := '<tool>';
    
    its.parser := 'tool';
    its.widgetname := 'tool';

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);
    
    
    its.makeentry := function(ref its, ref self) {
      wider private, its, self;
      its.disabled := !its.editable;
      if (its.editable) {
	its.entryframe := widgetset.frame(its.topframe, side='right',
					  expand=private.expand,
					  borderwidth=private.borderwidth);
	widgetset.popuphelp(its.entryframe, its.hlp);
	its.entry := widgetset.entry(its.entryframe,
				     background=private.editablecolor,
				     width=private.width,
				     borderwidth=private.borderwidth);
	whenever its.topframe->enter do {
	  widgetset.popuphelp(its.entry,  its.hlp);
	  whenever its.entry->return, its.entry->lve  do {
	    eventname := $name;
	    # Get the value
	    entry := its.entry->get();
	    # If its the nodisplay string for this type then
	    # just emit an event
	    if (has_field(its, 'nodisplay')&&is_string(its.nodisplay)&&
	       (entry==its.nodisplay)) {
	      if(eventname=='return') self->value(its.actualvalue);
	    }
	    else {
	      private.checkunset(entry);
	      # Otherwise try to insert it and emit a value
	      # event if it worked
	      if (self.insert(entry)) {
		if(eventname=='return') self->value(its.actualvalue);
	      }
	      else {
		its.actualvalue := illegal;
		its.displayvalue := '';
	      }
	    }
	  }
	  deactivate;
	}
      }
      else {
	its.entry := widgetset.entry(its.topframe,
				     background=private.uneditablecolor,
				     borderwidth=private.borderwidth,
				     width=private.width);
	widgetset.popuphelp(its.entry,  its.hlp);
	its.entry->disabled(T);
      }
      return T;
    };
    # Insert a value
    self.insert := function(rec=unset, truedefault=F) {
      wider its, private;
      include 'entryparser.g';

      if (!has_field(its, 'parser')) {
	return throw('Entry parser not specified',
		     origin=spaste('guientry.',its.parser));
      }

      if (!is_record(dep)||!has_field(dep, its.parser)||
	 !is_function(dep[its.parser])) {
	return throw('Entry parser not valid',
		     origin=spaste('guientry.',its.parser));
      }
      
      if (truedefault) rec:=its.truedefault;

      if (dep[its.parser](rec, its.allowunset, its.actualvalue,
			 its.displayvalue)) {
	its.putentry();
	return T;
      }
      else {
	private.errormessage(rec, its.parser);
	private.setstatus(its);
	return F;
      }
    }
    # Get the current value
    self.get := function() {
      wider its, private;
      return private.get(its, self);
    }
    private.makestandard(its, self, parent, addunsetframe=T,
			 title='AIPS++ Tool Chooser');
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
    
  }
  const public.untyped := subsequence(parent=unset, value=unset,
				      default=unset,
				      options='',
				      allowunset=F,
				      editable=T, hlp=unset)
  {
    wider private;

    widgetset.tk_hold();
    
    its := [=];
    its.recordbased := T;
    its.truedefault := F;

    its.widgetname := 'untyped';

    if (is_fail(private.untypedarguments(its, value, default, allowunset,
					editable, options, hlp))) {
      widgetset.tk_release();
      fail;
    }
    private.makestandardfunctions(its, self);
    
    include 'measures.g';

    its.search := "measure array coordinates region record string untyped";

    its.makeentry := function(ref its, ref self) {
      wider private, its, self;
      its.disabled := !its.editable;
      if (its.editable) {
	its.entryframe := widgetset.frame(its.topframe, side='right',
					  expand=private.expand,
					  borderwidth=private.borderwidth);
	widgetset.popuphelp(its.entryframe, its.hlp);
	its.entry := widgetset.entry(its.entryframe,
				     background=private.editablecolor,
				     width=private.width,
				     borderwidth=private.borderwidth);
	whenever its.topframe->enter do {
	  widgetset.popuphelp(its.entry,  its.hlp);
	  whenever its.entry->return, its.entry->lve  do {
	    eventname := $name;
	    # Get the value
	    entry := its.entry->get();
	    # If its the nodisplay string for this type then
	    # just emit an event
	    if (has_field(its, 'nodisplay')&&is_string(its.nodisplay)&&
	       (entry==its.nodisplay)) {
	      if(eventname=='return') self->value(its.actualvalue);
	    }
	    else {
	      private.checkunset(entry);
	      # Otherwise try to insert it and emit a value
	      # event if it worked
	      if (self.insert(entry)) {
		if(eventname=='return') self->value(its.actualvalue);
	      }
	      else {
		its.actualvalue := illegal;
		its.displayvalue := '';
	      }
	    }
	  }
	  deactivate;
	}
      }
      else {
	its.entry := widgetset.entry(its.topframe,
				     background=private.uneditablecolor,
				     borderwidth=private.borderwidth,
				     width=private.width);
	widgetset.popuphelp(its.entry, its.hlp);
	its.entry->disabled(T);
      }
      return T;
    };
    self.setsearch := function(search) {
      wider its;
      its.search := search;
      return T;
    }
    self.search := function() {
      wider its;
      return its.search;
    }
    # Insert a value
    self.insert := function(rec=unset, truedefault=F) {
      wider its, private;
      include 'entryparser.g';

      if (truedefault) rec:=its.truedefault;

      for (type in its.search) {
	if (dep[type](rec, its.allowunset, its.actualvalue,
		     its.displayvalue)) {
	  its.putentry();
	  return T;
	}
      }
      private.errormessage(rec, 'untyped');
      private.setstatus(its);
      return F;
    }
    # Non - standard get: don't update the type of parser
    self.get := function() {
      # WYSIWYG
      wider its, private;
      if (is_illegal(its.actualvalue)) return illegal;
      if (its.editable) {
	entry := its.entry->get();
	private.checkunset(entry);

#	for (type in its.search) {
#	  if (dep[type](entry, its.allowunset, its.actualvalue,
#		       its.displayvalue)) {
#	    its.putentry();
#	    break;
#	  }
#	}
      }
      return its.actualvalue;
    }

    private.makestandard(its, self, parent, addunsetframe=T,
			 title=paste('AIPS++ Untyped Chooser'));
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
    
  }

  const public.list := subsequence(parent=unset, types=unset,
				   name=unset, names=unset,
				   values=unset, defaults=unset, allowunset=F,
				   editable=T, options=unset, hlps=unset)
  {
    wider public, private;
    
    its := [=];
    
    if (is_fail(private.untypedarguments(its, values, defaults, allowunset,
					editable, options, hlps))) {
      fail;
    }
    private.makestandardfunctions(its, self);
    
    its.lastfield :=  unset;
    
    its.recordbased := T;
    its.truedefault := F;

    its.widgetname := 'list';
    its.parser := 'record';

    its.entries := [=];
    
    its.busy := F;
    its.lock := function() {
      wider its;
      if (its.busy) return F;
      its.busy := T;
      return T;
    }
    its.unlock := function() {
      wider its;
      its.busy := F;
      return T;
    }
    
    its.types := types;
    
    if (is_unset(name)) {
      its.name := 'Composite';
    }
    else {
      its.name := name;
    }
    
    if (is_unset(names)) {
      its.names := types;
    }
    else {
      its.names := names;
    }
    
    its.nentries := length(types);
    
    if (!is_unset(defaults)&&(length(defaults)!=its.nentries)) {
      return throw('Number of defaults does not match number of types');
    }
    
    if (!is_unset(hlps)&&(length(hlps)!=its.nentries)) {
      return throw('Number of hlps does not match number of types');
    }
    
    if (is_unset(values)) {
      its.values := [=];
      for (i in 1:its.nentries) {
	its.values[its.names[i]] := unset;
      }
    }
    else {
      its.values := [=];
      for (i in 1:its.nentries) {
	its.values[its.names[i]] := values[i];
      }
    }
    
    if (is_unset(defaults)) {
      its.defaults := [=];
      for (i in 1:its.nentries) {
	its.defaults[its.names[i]] := unset;
      }
    }
    else {
      its.defaults := [=];
      for (i in 1:its.nentries) {
	its.defaults[its.names[i]] := defaults[i];
      }
    }
    
    if (is_unset(hlps)) {
      its.hlps := [=];
      for (i in 1:its.nentries) {
	its.hlps[its.names[i]] := unset;
      }
    }
    else {
      its.hlps := [=];
      for (i in 1:its.nentries) {
	its.hlps[its.names[i]] := hlps[i];
      }
    }
    
    if (is_unset(options)) {
      its.options := [=];
      for (i in 1:its.nentries) {
	its.options[its.names[i]] := unset;
      }
    }
    else {
      its.options := [=];
      for (i in 1:its.nentries) {
	its.options[its.names[i]] := options[i];
      }
    }
    
    its.lastvalid := function() {
      wider its;
      last := 0;
      if (length(its.entries) > 0) {
	for (i in 1:length(its.entries)) {
	  if (is_record(its.entries[i])&&
	     has_field(its.entries[i], 'isvalid')&&
	     its.entries[i].isvalid) {
	    last := i;
	  }
	}
      }
      return last;
    }
    
    its.showentry := function(field) {
      wider its;
      if (!is_unset(its.lastfield)&&
	 has_field(its.entries, its.lastfield)&&
	 is_record(its.entries[its.lastfield])) {
	its.entries[its.lastfield].frame->unmap();
      }
      if (has_field(its.entries, field)&&
	 is_record(its.entries[field])&&
	 has_field(its.entries[field], 'frame')) {
	its.entries[field].frame->map();
      }
      its.lastfield := field;
      self->show(field);
    }
    
    its.addentry := function() {
      wider its;
      widgetset.tk_hold();
      last:=its.lastvalid();
      field := spaste(its.name, last+1);
      its.range.setrange(1, last+1);
      its.range.setvalues(last+1);
      its.entries[field] := [=];
      its.entries[field].isvalid := T;
      its.entries[field].frame :=
	  widgetset.frame(its.entriesframe, side='top');
      its.entries[field].guientry := [=];
      its.entries[field].frames := [=];
      its.entries[field].labels := [=];
      
      for (i in 1:length(its.names)) {
	name := its.names[i];
	type := its.types[i];
	its.entries[field].frames[name] :=
	    widgetset.frame(its.entries[field].frame, side='right');
	its.entries[field].guientry[name] :=
	    public[type](its.entries[field].frames[name],
			 value=its.defaults[name],
			 default=its.defaults[name],
			 allowunset=allowunset,
			 editable=editable,
			 options=its.options[name],
			 hlp=its.hlps[name]);
	if (is_fail(its.entries[field].guientry[name])) {
	  widgetset.tk_release();
	  fail;
	}
	its.entries[field].labels[name] :=
	    widgetset.label(its.entries[field].frames[name], name);
      }
      self->add(field);
      its.showentry(field);
      widgetset.tk_release();
    }
    
    its.deleteentry := function() {
      wider its;
      widgetset.tk_hold();
      last:=its.lastvalid();
      field := spaste(its.name, last);
      its.range.setrange(1, last);
      its.range.setvalues(last);
      if (has_field(its.entries, field)) {
	its.entries[field].isvalid := F;
	for (i in 1:length(its.names)) {
	  name := its.names[i];
	  if (has_field(its.entries, field)&&
	     is_record(its.entries[field])) {
	    its.entries[field].guientry[name].done();
	    its.entries[field].frames[name]->unmap();
	    its.entries[field].frames[name] := F;
	    its.entries[field].labels[name] := F;
	  }
	}
	its.entries[field].label := F;
	its.entries[field].frame->unmap();
	its.entries[field].frame := F;
	its.entries[field] := F;
	self->delete(field);
      }
      last:=its.lastvalid();
      field := spaste(its.name, last);
      its.showentry(field);
      widgetset.tk_release();
    }
    
    its.all := function(fn, ...) {
      wider its;
      result := T;
      for (field in field_names(its.entries)) {
	if (is_record(its.entries[field])&&
	   has_field(its.entries[field], 'isvalid')) {
	  for (name in its.names) {
	    result := its.entries[field].guientry[name][fn](...) && result;
	  }
	}
      }
      return result;
    }
    
    self.get := function() {
      wider its, private;
      if (is_illegal(its.actualvalue)) return illegal;
      if (!is_unset(its.actualvalue)) {
	rec := [=];
	for (field in field_names(its.entries)) {
	  if (is_record(its.entries[field])&&
	     has_field(its.entries[field], 'isvalid')&&
	     its.entries[field]['isvalid']) {
	    rec[field] := [=];
	    for (name in its.names) {
	      rec[field][name] := its.entries[field].guientry[name].get();
	    }
	  }
	}
	its.actualvalue := rec;
      }
      private.setstatus(its);
      return its.actualvalue;
    }
    
    self.clear := function() {
      wider its;
      return its.all('clear');
    }
    
    self.disable := function(disable=T) {
      wider its;
      return private.disable(its, disable)&&its.all('disable', disable);
    }
    
    self.setcontexts := function(contexts) {
      wider its;
      return its.all('setcontexts', contexts);
    }
    
    self.setwidth := function(width) {
      wider its;
      return its.all('setwidth', width);
    }
    
    its.putentry := function() {
      wider its;
      result := T;
      nentries := its.lastvalid();
      rec := its.actualvalue;
      if (length(rec)>nentries) {
	for (i in nentries:(length(rec)-1)) {
	  its.addentry();
	}
      }
      else if (length(rec)<nentries) {
	for (i in length(rec):(nentries-1)) {
	  its.deleteentry();
	}
      }
      for (field in field_names(rec)) {
	if (has_field(its.entries, field)&&
	   is_record(its.entries[field])&&
	   has_field(its.entries[field], 'isvalid')) {
	  for (name in its.names) {
	    if (has_field(rec[field], name)) {
	      result := its.entries[field].guientry[name].insert(rec[field][name]) && result;
	    }
	  }
	}
      }
      return result;
    }
    self.insert := function(rec=unset, truedefault=F) {
      wider its, private;
      include 'entryparser.g';

      if (truedefault) rec:=its.truedefault;

      if (dep['record'](rec, its.allowunset, its.actualvalue,
		       its.displayvalue)) {
	its.putentry();
	return T;
      }
      private.errormessage(rec, 'record');
      private.setstatus(its);
      return F;
    }

    # Insert and emit
    self.insertandemit := function(rec=unset) {
      wider self, its;
      if (self.insert(rec)) {
	self->value(its.actualvalue);
      }
    }
    self.done := function() {
      wider its;
      widgetset.tk_hold();
      for (i in 1:length(its.entries)) {
	its.deleteentry();
      }
      its.buttons['add'] := F;
      its.buttons['delete'] := F;
      its.topframe->unmap();
      its.topframe := F;
      widgetset.tk_release();
    }
    
    its.makeentry := function(ref its, ref self) {

      its.entryframe := widgetset.frame(its.topframe, side='top',
				       relief='sunken');

      its.menuframe := widgetset.frame(its.entryframe, side='left');

      its.buttons['add'] := widgetset.button(its.menuframe, 'Add',
					     type='action');
      widgetset.popuphelp(its.buttons['add'], 'Add new entry at end of list');
      whenever its.buttons['add']->press do {
	if (its.lock()) {
	  widgetset.tk_hold();
	  its.addentry();
	  widgetset.tk_release();
	  its.unlock();
	}
      }
      
      its.buttons['delete'] := widgetset.button(its.menuframe, 'Delete');
      widgetset.popuphelp(its.buttons['delete'], 'Delete last entry in list');
      whenever its.buttons['delete']->press do {
	if (its.lock()) {
	  widgetset.tk_hold();
	  its.deleteentry();
	  widgetset.tk_release();
	  its.unlock();
	}
      }
      
      its.range := widgetset.multiscale(its.menuframe, names='',
					start=1, end=1, values=1,
					resolution=1,
					helps='Switch between different entries');
      whenever its.range->values do {
	if (its.lock()) {
	  field := spaste(its.name, $value);
	  its.showentry(field);
	  its.unlock();
	}
      }

      its.entriesframe := widgetset.frame(its.entryframe, side='top');

      if (is_fail(self.insert(its.values))) fail;
    
    }
    ok := widgetset.tk_hold();
    
    private.makestandard(its, self, parent, addunsetframe=T,
			 title=paste('AIPS++ List Widget'));

#    ok := self.insert(its.defaultvalue);
    ok := self.insert(its.originalvalue);
    ok := widgetset.tk_release();
    
  }
  public.done := function() 
  {
    wider private, public;
    popupremove(private);
    val private := F;
    val public := F;
    return T;
  }
  public.type := function ()
  {
    return 'guientry';
  }
  return ref public;
}

# Test script for guientry

const guientrytest := function(autodestruct=T, editable=T, allowunset=T, expand='none') {
  
  include 'measures.g';
  include 'quanta.g';
  include 'widgetserver.g';
  include 'regionmanager.g';
  
  dge := dws.guientry(expand=expand);
  
# we will put a "parameter set" into "parameters":
  parameters := [=];
  
# Set up various widgets:
  
  realtopf:=dws.frame(title='guientrytest', side='top');

  topf:=dws.frame(realtopf, side='left');

  f:=dws.frame(topf, side='top');

  dws.tk_hold();
  
  stime := time();

  parameters['imagingcoord'] := dge.imagingcoord(f, allowunset=T);
  
# floatrange
# give min, max and resolution: it makes a scale widget
  parameters['power'] := dge.range(f, rmin=-5.0, rmax=5.0, rresolution=0.1,
				   default=0.0, value=1.5, editable=editable,
				   allowunset=allowunset);
  
  parameters['switch'] := dge.boolean(f, allowunset=allowunset, default=T, value=F,
				      editable=editable);
  
  parameters['booleans'] := dge.booleanarray(f, allowunset=allowunset, default=T, value=F,
					     editable=editable);
  
# vector
# just an entry box at the moment: needs some smarts like the ones
# in regionmanager and others.
  parameters['levels'] := dge.array(f, default=[0.2, 0.4, 0.6, 0.8],
				    value=[0.2, 0.4, 0.6, 0.9], editable=editable,
				    allowunset=allowunset);
  
# scalar
# just an entry box at the moment - perhaps a scale or "winding entry
# box" in the future.
  parameters['scale'] := dge.scalar(f, default=0.5, value=1.2, editable=editable,
				    allowunset=allowunset);
  
# intrange
# give min/max: this makes a scale widget with step size 1.
  parameters['line'] := dge.range(f, rmin=0, rmax=6, rresolution=1,
				  default=1, value=1, editable=editable,
				  allowunset=allowunset);
  
# just like 'choice', but allows extension by user via extendoptionmenu.
  parameters['tool'] := dge.tool(f, 'myleftfoot', editable=editable,
				 allowunset=allowunset);

  parameters['color choice'] :=
      dge.choice(f, options="black white red green blue yellow",
		 default='blue', value='blue', editable=editable, allowunset=allowunset);
  
  parameters['color check'] :=
      dge.check(f, options="black white red green blue yellow",
		default='blue', value='blue', editable=editable, allowunset=allowunset);
  
  f1 := dws.frame(topf, side='top');

  parameters['filename'] := dge.file(f1, default='', value="part a part b foo",
				     allowunset=allowunset, editable=editable);
  

  parameters['string'] := dge.string(f1, default='',
				     value=['part a', 'part b', 'foo'],
				     allowunset=allowunset, editable=editable,
				     onestring=F);
  
  parameters['onestring'] := dge.string(f1, default='',
				     value='macaroni cheese',
				     allowunset=allowunset, editable=editable,
				     onestring=T);
  
  parameters['cellsize'] := dge.quantity(f1, default='0rad', value='0.7arcsec',
					 allowunset=allowunset, editable=editable);
  
  parameters['imagesize'] := dge.scalar(f1, default=unset,  value=256,
					allowunset=allowunset, editable=editable);
  
  parameters['array'] := dge.array(f1, default=unset,  value='array(1:60, 5, 12)',
				   allowunset=allowunset, editable=editable);
  
  parameters['record'] := dge.record(f1, default=unset, value='[=]',
				     allowunset=allowunset, editable=editable);
  
  parameters['untyped'] := dge.untyped(f1, default=unset, value='[=]',
				       allowunset=allowunset, editable=editable);
  
  parameters['region'] := dge.region(f1, default=unset, value='drm.box()',
				     allowunset=allowunset, editable=editable);
  
  parameters['resample'] := dge.choice(f1, allowunset=allowunset,
				       options=['nearest',  'bilinear'],
				       default='nearest', value='nearest', editable=editable);
  
  parameters['epoch'] := dge.epoch(f1, default=unset,
				   value=unset, options='tai',
				   allowunset=allowunset, editable=editable);
  
  parameters['direction'] := dge.direction(f1, default=unset,
					   value=dm.direction('sun'),
					   options='vertical',
					   allowunset=allowunset,
					   editable=editable);

  f2 := dws.frame(topf, side='top');

  parameters['coordinates'] := dge.coordinates(f2, default=unset,
					       value=unset,
					       allowunset=allowunset,
					       editable=editable);
  
  parameters['frequency'] := dge.frequency(f2, default=unset,
					   value=unset,
					   allowunset=allowunset,
					   editable=editable);
  
  parameters['position'] := dge.position(f2, default=unset,
					 value=dm.position('itrf'),
					 allowunset=allowunset,
					 editable=editable);
  
  parameters['measurecodes'] := dge.measurecodes(f2, options='frequency',
						 default='REST',
						 value=unset,
						 allowunset=allowunset,
						 editable=editable);
  
  parameters['antennas'] := dge.antennas(f2, default=[],
					 value=unset,
					 allowunset=allowunset,
					 editable=editable);
  
  parameters['baselines'] := dge.baselines(f2, default=[],
					 value=unset,
					 allowunset=allowunset,
					 editable=editable);
  
  parameters['fieldnames'] := dge.fieldnames(f2, default='',
					 value=unset,
					 allowunset=allowunset,
					 editable=editable);
  
  parameters['list'] := dge.list(f2, types=['string', 'direction'],
				 names="Source Direction",
				 name='Source',
				 defaults=unset,
				 values=[Name='3C273',
					 Direction=dm.direction()],
				 allowunset=allowunset,
				 editable=editable);
  
  dws.tk_release();

  note(paste("Time to make guientry widgets = ", time()-stime, "s"),
       origin='guientrytest');

  alldone := function(ref parameters) {
    for (field in field_names(parameters)) {
      parameters[field].done();
    }
  }

  if (autodestruct) {
    f->unmap(); f1->unmap(); f2->unmap();
    alldone(parameters);
    f := F; f1 := F; f2 := F;
  }
  else {
    for (parameter in field_names(parameters)) {
      whenever parameters[parameter]->* do {
      }
      whenever parameters[parameter]->value do {
	par := $value;
	if (is_function(par)) {
	}
	if (is_region(par)) {
	}
	else if (length(par)>1) {
	  mp := min(10, length(par));
	}
	else {
	}
      }
    }
    
    
    bf := dws.frame(realtopf, side='left');
    b:=dws.button(bf, 'Show', type='action');
    whenever b->press do {
      stime := time();
      for (parameter in field_names(parameters)) {
	par := parameters[parameter].get();
	if (is_function(par)) {
	  print parameter, '<function>';
	}
	if (is_region(par)) {
	  print parameter, '<region>';
	}
	else if (length(par)>1) {
	  mp := min(10, length(par));
	  print parameter, par[1:mp];
	}
	else {
	  print parameter, par;
	}
      }
      print "Time to show = ", time() - stime;
    }
    eb:=dws.button(bf, 'Enable');
    whenever eb->press do {
      for (parameter in field_names(parameters)) {
	parameters[parameter].disable(F);
      }
    }
    db:=dws.button(bf, 'Disable');
    whenever db->press do {
      for (parameter in field_names(parameters)) {
	parameters[parameter].disable(T);
      }
    }
    exb:=dws.button(bf, 'Expand');
    whenever exb->press do {
      for (parameter in field_names(parameters)) {
	parameters[parameter].setwidth(60);
      }
    }
    cb:=dws.button(bf, 'Compress');
    whenever cb->press do {
      for (parameter in field_names(parameters)) {
	parameters[parameter].setwidth(30);
      }
    }
    cl:=dws.button(bf, 'Clear');
    whenever cl->press do {
      for (parameter in field_names(parameters)) {
	parameters[parameter].clear();
      }
    }

    df := dws.frame(bf, side='right');
    dh:=dws.button(df, 'Done', type='halt');
    whenever dh->press do {
      f->unmap(); f1->unmap(); f2->unmap();
      alldone(parameters);
      f := F; f1 := F; f2 := F;
      df:=F;
      bf:=F;
    }

  }

}
