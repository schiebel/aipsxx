# toolguiserver: Serves GUIs for tools
#
#   Copyright (C) 1998,1999,2000,2001,2002
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
#   $Id: toolguiserver.g,v 19.2 2004/08/25 02:06:03 cvsmgr Exp $
#

include 'widgetserver.g';

pragma include once;

# Serves gui elements to toolmanager. The guts of the GUIs are all
# in subsequences but the subsequences are cached locally and
# the public interface is all via functions. The cache of subsequences
# is available for use where necessary.
const toolguiserver := subsequence(widgetset=dws) {
  
  include 'types.g';
  include 'note.g';
  include 'timer.g';
  include 'aipsrc.g';
  
  include 'toolguibasefunction.g';
  
  private := [ctor=[=], tool=[=], globalfunction=[=],
	      item=[=], manager=[=]];
  
  include 'toolmanagersupport.g';
  private.tms := toolmanagersupport;

########################################################################
# Public functions
  
# Constructor GUI: this simply stores and calls the subsequence
  const self.constructor := function(type, ref tool=unset, parent=F) {

    wider private;
    
    self.showmanager();
    
    prvt:=[=];
    prvt.type := type;
    
    prvt.whenevers := [];
    prvt.pushwhenever := function() {
      wider prvt;
      prvt.whenevers[len(prvt.whenevers) + 1] :=
	  last_whenever_executed();
    }
    
    prvt.done := function() {
      wider prvt, private;
      deactivate prvt.whenevers;;
      if(is_record(private.ctor)&&has_field(private.ctor, prvt.key)&&
	 is_record(private.ctor[prvt.key])&&
	 has_field(private.ctor[prvt.key], 'frame')) {
	private.ctor[prvt.key].frame->unmap();
	private.ctor[prvt.key].frame := F;
	private.ctor[prvt.key].subs := F;
      }
      return T;
    }
    
    prvt.key := type;
    
    if(!private.manager.available(type)) {
      widgetset.tk_hold();
      hlptxt := paste('Press to see view for', type, 'constructors');
      private.ctor[prvt.key].frame :=
	  private.manager.add(prvt.key, prvt.key, hlptxt);
      private.ctor[prvt.key].subs :=
	  toolguibasefunction(type=type, tool=unset,
			      parent=private.ctor[prvt.key].frame,
			      title=spaste('Create AIPS++ ', type),
			      mode='construct',
			      widgetset=widgetset);
      widgetset.tk_release();
      if(is_fail(private.ctor[prvt.key].subs)) {
	private.manager.delete(prvt.key);
	private.ctor[prvt.key] := F;
	fail;
      }
      if(!is_agent(private.ctor[prvt.key].subs)) {
	private.manager.delete(prvt.key);
	private.ctor[prvt.key] := F;
	return throw ('Could not create constructor ', prvt.key);
      }
      
      whenever private.ctor[prvt.key].subs->show_return,
	private.ctor[prvt.key].subs->go_return,
	private.ctor[prvt.key].subs->dismiss_return do {
        name := $name;
	rec := $value;
	rec.type := prvt.type;
	self->[name](rec);
      } prvt.pushwhenever();
      
      whenever private.ctor[prvt.key].subs->fail, 
        private.ctor[prvt.key].subs->go_return,
	private.ctor[prvt.key].subs->dismiss_return do {
        status := $name;
	value := $value;
	if(status=="fail") {
	  private.manager.delete(prvt.key);
	  throw ('Construction of tool failed: ', status);
	}
	else if(status=='go_return') {
	  private.manager.delete(prvt.key);
	  tool := value.tool;
	  type := value.type;
	  include 'toolmanager.g';
	  if(tm.istool(tool)) {
	    tm.registertool(tool);
	    tm.show(tool);
	  }
	  else {
	    throw('Logical error: constructed a non-tool ', tool);
	  }
	}
	else if(status=='dismiss_return') {
	  private.manager.delete(prvt.key);
	  type := value.type;
	  note ('GUI for constructor ', type, ' no longer needed');
	}
	prvt.done();
      } prvt.pushwhenever();
      private.ctor[prvt.key].subs->init();
    }
    
    return private.manager.front(prvt.key);
  }
  
# global function GUI: this simply stores and calls the subsequence
  const self.globalfunction := function(method, parent=F) {
    
    wider private;
    
    self.showmanager();
    
    prvt := [=];
    
    prvt.done := function() {
      wider prvt, private;
      deactivate prvt.whenevers;;
      if(is_record(private.globalfunction)&&
	 has_field(private.globalfunction, prvt.key)&&
	 is_record(private.globalfunction[prvt.key])&&
	 has_field(private.globalfunction[prvt.key], 'frame')) {
	private.globalfunction[prvt.key].frame->unmap();
	private.globalfunction[prvt.key].frame := F;
	private.globalfunction[prvt.key].subs := F;
      }
      return T;
    }
    
    prvt.whenevers := [];
    prvt.pushwhenever := function() {
      wider prvt;
      prvt.whenevers[len(prvt.whenevers) + 1] :=
	  last_whenever_executed();
    }
    
    title:=spaste('Execute AIPS++ function ', method);
    include 'toolmanager.g';
    
    type := tm.findtype(method);
    if(is_fail(type)) fail;
    meta := types.meta(type, globals=T);
    methods := sort(field_names(meta));
    if(length(methods)==0) {
      return throw('There are no global function ', method, ' for type ', type,
		   origin='toolguiserver.globalfunction');
    }
    prvt.key := method;
    
    if(!private.manager.available(prvt.key)) {
      private.globalfunction[prvt.key] := [=];
      hlptxt := paste('Press to see view for ', method, 'global function');
      widgetset.tk_hold();
      private.globalfunction[prvt.key].frame :=
	  private.manager.add(prvt.key, prvt.key, hlptxt);
      private.globalfunction[prvt.key].subs :=
	  toolguibasefunction(type=type, tool=method, title=title,
			      parent=private.globalfunction[prvt.key].frame,
			      methods=method,
			      mode='global',
			      widgetset=widgetset);
      private.manager.front(prvt.key);
      widgetset.tk_release();
      # Fails on construction with explicit fail
      if(is_fail(private.globalfunction[prvt.key].subs)) {
	private.manager.delete(prvt.key);
	prvt.done();
	fail;
      }
      if(!is_agent(private.globalfunction[prvt.key].subs)) {
	private.manager.delete(prvt.key);
	prvt.done();
	return throw ('Could not create GUI for function execution');
      }
      
      whenever private.globalfunction[prvt.key].subs->show_return,
        private.globalfunction[prvt.key].subs->dismiss_return,
	private.globalfunction[prvt.key].subs->go_return do {
	if(is_record(prvt)) {
	  name := $name;
	  rec := $value;
	  self->[name](rec);
	}
      } prvt.pushwhenever();
      
      # Fail during execution
      whenever private.globalfunction[prvt.key].subs->fail, 
	private.globalfunction[prvt.key].subs->dismiss_return do {
	private.manager.delete(prvt.key);
	if(is_record(prvt)) {
	  if($name=="fail") {
	    throw ('Execution of function failed: ', $value);
	  }
	  else {
	    note ('GUI for global function ', $value.method, ' dismissed');
	  }
	  prvt.done();
	}
      } prvt.pushwhenever();

      private.globalfunction[prvt.key].subs->init();
    }
    
    return private.manager.front(prvt.key);
  }
  
# Tool GUI: this simply stores and calls the subsequence
  const self.tool := function(tool, type, title=unset, parent=F,
			      hints=[=]) {
    
    wider private;
    
    self.showmanager();
    
    prvt := [=];
    prvt.type := type;
    prvt.tool := tool;
    
    prvt.done := function() {
      wider prvt, private;
      deactivate prvt.whenevers;;
      if(is_record(private.tool)&&has_field(private.tool, prvt.key)&&
	 is_record(private.tool[prvt.key])&&
	 has_field(private.tool[prvt.key], 'frame')) {
	private.tool[prvt.key].frame->unmap();
	private.tool[prvt.key].frame := F;
	private.tool[prvt.key].subs := F;
      }
      return T;
    }
    
    prvt.whenevers := [];
    prvt.pushwhenever := function() {
      wider prvt;
      prvt.whenevers[len(prvt.whenevers) + 1] :=
	  last_whenever_executed();
    }
    
    title:=spaste('Tool type: ', type, ', Tool name: ', tool);
    
    meta := types.meta(type);
    methods := sort(field_names(meta));
    if(length(methods)==0) {
      note('There are no functions to show for tools of type ', type);
      return F;
    }
    
    prvt.key := spaste(type, ':', tool);
    
    if(!private.manager.available(prvt.key)) {
      widgetset.tk_hold();
      private.tool[prvt.key] := [=];
      hlptxt := paste('Press to see view for tool type', type, ', name', tool);
      private.tool[prvt.key].frame :=
	  private.manager.add(prvt.key, prvt.key, hlptxt);
      private.tool[prvt.key].subs :=
	  toolguibasefunction(type=type, tool=tool, title=title,
			      methods=methods,
			      parent=private.tool[prvt.key].frame,
			      mode='tool',
			      hints=hints,
			      widgetset=widgetset);
      widgetset.tk_release();
      
      # Fails on construction with explicit fail
      if(is_fail(private.tool[prvt.key].subs)||
	 !is_agent(private.tool[prvt.key].subs)) {
        private.manager.delete(prvt.key);
	prvt.done();
	return throw ('Construction of tool GUI failed');
      }
      # There were no functions to show
      if(is_boolean(private.tool[prvt.key].subs)&&
	 private.tool[prvt.key].subs) {
        private.manager.delete(prvt.key);
	prvt.done();
	return T;
      }
      
      whenever private.tool[prvt.key].subs->show_return,
	private.tool[prvt.key].subs->go_return,
	private.tool[prvt.key].subs->done_return,
	private.tool[prvt.key].subs->dismiss_return do {
	if(is_record(prvt)) {
	  name := $name;
	  rec := $value;
	  rec.type := prvt.type;
	  rec.tool := prvt.tool;
	  self->[name](rec);
	}
      } prvt.pushwhenever();
      
      whenever private.tool[prvt.key].subs->fail,
        private.tool[prvt.key].subs->done_return,
	private.tool[prvt.key].subs->go_return,
	private.tool[prvt.key].subs->dismiss_return do {
	if(is_record(prvt)) {
	  status := $name;
	  value := $value;
	  if(is_record($value)) {
	    tool := $value.tool;
	  }
	  else {
	    tool := '';
	  }
	  if(status=='fail') {
	    private.manager.delete(prvt.key);
	    throw ('Execution of tool failed: ', value);
	    prvt.done();
	  }
	  else if (status=="dismiss_return") {
	    private.manager.delete(prvt.key);
	    note ('GUI for tool ', tool, ' dismissed');
	    prvt.done();
	  }
	  else if (status=="done_return") {
	    private.manager.delete(prvt.key);
	    include 'toolmanager.g';
	    if(tm.istool(tool)) {
	      note('Deleting tool ', tool);
	      tm.deletetool(tool);
	    }
	    prvt.done();
	  }
	  else if (status=="go_return") {
	    if(has_field(value, 'newtool')) {
	      newtool := value.newtool;
	      include 'toolmanager.g';
	      if(tm.istool(newtool)) {
		tm.registertool(newtool);
		tm.showtool(newtool);
	      }
	    }
	  }
	}
      } prvt.pushwhenever();

      private.tool[prvt.key].subs->init();
    }
    
    return private.manager.front(prvt.key);
  }
  
# Itemmanager GUI: this simply stores and calls the subsequence
  const self.itemmanager := function(itemmanager, type, title=unset, 
				     parent=F) {
    
    wider private;
    
    self.showmanager();
    
    prvt := [=];
    prvt.itemmanager := itemmanager;
    prvt.type := type;
    
    prvt.whenevers := [];
    prvt.pushwhenever := function() {
      wider prvt;
      prvt.whenevers[len(prvt.whenevers) + 1] :=
	  last_whenever_executed();
    }
    
    prvt.done := function() {
      wider private, prvt;
      deactivate prvt.whenevers;
      private.tms.deregisterlocationframe();
      if(is_record(private.item)&&has_field(private.item, prvt.key)&&
	 is_record(private.item[prvt.key])&&
	 has_field(private.item[prvt.key], 'frame')) {
	private.item[prvt.key].subs := F;
	private.item[prvt.key].frame->unmap();
	private.item[prvt.key].frame := F;
      }
      return T;
    }
    
    if(is_unset(title)) {
      title:=spaste('Data item manager: ', itemmanager);
    };
    meta := types.meta(type);
    methods := sort(field_names(meta));
    prvt.key := spaste(type, ':', itemmanager);
#
    widgetset.tk_hold();
    private.item[prvt.key] := [=];
    
# Disable positioning of item manager frame (1/26/01) AK
#
#    if(is_agent(private.tms.locationframe())) {
#      private.item[prvt.key].frame :=
#	  widgetset.frame(tlead=private.tms.locationframe(), tpos='w');
#    }
#    else {
#
      if(is_agent(parent)) {
	private.item[prvt.key].frame := widgetset.frame(parent=parent,
							title=title, 
                                                        side='right');
      }
      else {
	private.item[prvt.key].frame := widgetset.frame(title=title, 
                                                        side='right');
      }
# Disable positioning of item manager frame
#    }
    
    private.item[prvt.key].subs :=
	toolguibasefunction(type=type, tool=itemmanager, title=title,
			    methods=methods,
			    parent=private.item[prvt.key].frame,
			    mode='item',
			    widgetset=widgetset);
    widgetset.tk_release();
    # Handle fail on construction of basefunction window and
    # verify that a valid agent has been created
    if(is_fail(private.item[prvt.key].subs) ||
       !is_agent(private.item[prvt.key].subs)) {
      prvt.done();
      return throw ('Construction of itemmanager gui frame failed');
    }
    whenever private.item[prvt.key].subs->show_return,
      private.item[prvt.key].subs->done_return,
      private.item[prvt.key].subs->dismiss_return,
      private.item[prvt.key].subs->go_return do {
      if(is_record(prvt)) {
	name := $name;
	rec := $value;
	rec.itemmanager := prvt.itemmanager;
	self->[name](rec);
      }
    } prvt.pushwhenever();
    
    # Catch all other events
    whenever private.item[prvt.key].subs->fail,
      private.item[prvt.key].subs->done_return,
      private.item[prvt.key].subs->go_return,
      private.item[prvt.key].subs->dismiss_return do {
      if($name=="fail") {
	throw ('Execution of itemmanager failed: ', $value);
      }
      prvt.done();
    } prvt.pushwhenever();
    
    private.item[prvt.key].subs->init();

    return T;

  }
  
# Manager GUI: this simply stores and calls the subsequence
  const self.showmanager := function() {
    
    wider private;
    
    prvt := [=];
    
    if(has_field(private, 'manager')&&is_record(private['manager'])&&
       has_field(private['manager'], 'gui')&&
       is_function(private['manager'].map)) {
      private.manager.map();
    }
    else {
      include 'toolmanagerguiserver.g';
      private.manager := toolmanagerguiserver(widgetset);
      if(is_fail(private.manager)) fail;
      private.manager.gui();
      include 'servers.g';
      whenever defaultservers.alerter()->activate,
	  defaultservers.alerter()->create,
	      defaultservers.alerter()->add,
		  defaultservers.alerter()->terminate,
		      defaultservers.alerter()->done,
			  defaultservers.alerter()->fail do {
	private.manager.refresh();
      }
      
    }
    return T;
  }
  
  whenever self->show, self->go, self->done, self->dismiss do {
    wider private;
    event := $name;
    rec := $value;
    if(rec.mode=='tool') {
      self.tool(rec.tool, rec.type);
      prvt.key := spaste(rec.type, ':', rec.tool);
      private.tool[prvt.key].subs->[event](rec);
    }
    else if(rec.mode=='construct') {
      self.constructor(rec.type);
      prvt.key := rec.type;
      private.ctor[prvt.key].subs->[event](rec);
    }
    else if(rec.mode=='global') {
      self.globalfunction(rec.method);
      prvt.key := rec.method;
      private.globalfunction[prvt.key].subs->[event](rec);
    }
    else if(rec.mode=='item') {
      self.itemmanager(rec.itemmanager, rec.type);
      prvt.key := spaste(rec.type, ':', rec.itemmanager);
      private.item[prvt.key].subs->[event](rec);
    }
  }
  
}

