#   listenermanager.g: A Glish object to contain items in a Glish record
#
#   Copyright (C) 1996,1997,1998,2000,2001,2002
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
#   $Id: listenermanager.g,v 19.1 2004/08/25 01:17:00 cvsmgr Exp $
pragma include once;

#@tool public listenermanager
# a scripting utility used to manage callbacks that react to changes in
# state
#
#@constructor
# create a manager tool
# @param name      the name to associate with the state being monitored.
# @param unique    ensure that listeners are not overwritten without being
#                    explicitly removed.
##
const listenermanager := function(name='', unique=T) {

    private := [name=name, ticker=0, unique=unique, listeners=[=]];
    public := [=];

    if (! is_boolean(unique))
	fail paste('Non-boolean input type for unique:', unique);

    #@ 
    # add a listener
    # @param callback   a function to be called when state is updated.  This 
    #                     function should have the following signiture:
    #                     <pre>
    #                        function(state=[=], name='', who='')
    #                     where 
    #                        state    a record desribing the state change
    #                        name     the name associated with the state; this
    #                                   will be the name associated with this
    #                                   manager set at construction.
    #                        who      the name of the actor that changed the
    #                                   state; an empty string means "unknown".
    # @param who        the name to associate with the listener.  This will
    #                     be returned by this function.  If a name is not 
    #                     provided, a unique name will be provided and returned.
    # @return string  represting the name given to the new listener.  
    ##
    public.addlistener := function(callback, who='') {
	wider private, public;

	if (! is_function(callback)) 
	    fail 'addlistener: non-function passed in callback parameter';
	if (! is_string(who)) 
	    fail 'addlistener: who parameter must be a string';

	# create a name if not provided
	if (strlen(who) == 0) {
	    while (1) {
		private.ticker +:= 1;
		who := spaste(private.name, as_string(private.ticker));
		if (! public.islistening(who)) break;
	    }
	}

	# enforce unique names (if desired)
	else if (unique && public.islistening(who)) {
	    fail paste('addlistener: listener', who, ' already in use;',
		       '\nyou must call removelistener first before reusing',
		       'name');
	}

	# set the listener
	private.listeners[who] := callback;

	return who;
    }

    #@
    # remove a listener.  The callback associated with the given name will
    # be thrown away.
    # @param who   the name of the listener to remove
    ##
    public.removelistener := function(who) {
	wider private;
	if (has_field(private.listeners, who)) private.listeners[who] := F;
	return T;
    }

    #@ 
    # tell listeners about a change in state by calling their callback 
    # functions
    # @param state    a record describing the state change; this will be 
    #                   passed to the listeners' callback functions.
    # @param who      the name of the actor that effected the change; this 
    #                   will be passed to the listeners' callback functions.
    # @param skipwho  if true, a 
    #                   listener whose name matches this will not told 
    #                   about the change (to guard against redundant 
    #                   reactions).
    ##
    public.tell := function(state=[=], who='', skipwho=T) {
	wider private;
	local listener, ok;
	
	if (skipwho) {
	    for (listener in field_names(private.listeners)) {
		if (listener != who) {
		    ok := private.listeners[listener](state=state, 
						      name=private.name,
						      who=who);

		    # give user some idea when something goes wrong
		    if (is_fail(ok)) print ok;
		}
	    }
	}
	else {
	    for (listener in field_names(private.listeners)) {
		ok := private.listeners[listener](state=state, 
						  name=private.name, 
						  who=who);

		# give user some idea when something goes wrong
		if (is_fail(ok)) print ok;
	    }
	}
    }

    #@
    # return true if there exists a listener with a given name
    # @param the listener's name
    ##
    public.islistening := function(who) {
	wider private;
	return (has_field(private.listeners, who) && 
		! is_boolean(private.listeners[who]));
    }

    #@
    # shut down this tool
    ##
    public.done := function() {
	private := F;
	val public := F;
	return T;
    }

    return ref public;
}

const listenermanagertest := function() {
    local heard := [];
    local problems := [=];

    checker := function(value, state=[=], name='', who='') {
	wider heard, problems;
	if (! is_record(state) || len(state)==0 || ! has_field(state, 'hello')){
	    if (! has_field(problems, 'state'))
		problems.state := "Failure passing state";
	}
	if (! is_string(name) || name != 'test') {
	    if (! has_field(problems, 'name')) 
		problems.name := "Failure passing name";
	}	    
	if (! is_string(who) || who != '2') {
	    if (! has_field(problems, 'who'))
		problems.who := "Failure passing who";
	}	    
	heard[len(heard)+1] := value;
	return T;
    }

    cb1 := function(state=[=], name='', who='') {
	return checker(1, state, name, who);
    }

    cb2 := function(state=[=], name='', who='') {
	return checker(2, state, name, who);
    }

    cb3 := function(state=[=], name='', who='') {
	return checker(3, state, name, who);
    }

#    print '###DBG: creating manager';
    local mgr := listenermanager(name='test', unique=F);
    ok := mgr.addlistener(cb1, who='1');
    if (is_fail(ok)) return ok;
    ok := mgr.addlistener(cb2, who='1');
    if (is_fail(ok)) fail 'failed to allow callback overrides';
    ok := mgr.done();
    if (is_fail(ok)) return ok;

#    print '###DBG: recreating manager';
    mgr := listenermanager(name='test');
#    print '###DBG: adding listeners';
    ok := mgr.addlistener(cb1, who='1');
    if (is_fail(ok)) return ok;
    ok := mgr.addlistener(cb2, who='1');
    if (! is_fail(ok)) fail 'failed to disallow callback overrides';

    ok := mgr.addlistener(cb2, who='2');
    if (is_fail(ok)) return ok;
    ok := mgr.addlistener(cb3, who='3');
    if (is_fail(ok)) return ok;

#    print '###DBG: telling';
    ok := mgr.tell([hello='world'], who='2', skipwho=F);
#    print '###DBG: told';
    if (len(heard) != 3 || ! any(heard==1) || 
	! any(heard==2) || ! any(heard==3)) 
	fail paste('failed to alert all listeners', heard);
    if (len(problems) > 0) {
	for(prob in field_names(problems)) {
	    print problems[prob];
	}
	fail 'Trouble passing state update info';
    }

    heard := [];
    ok := mgr.tell([hello='world'], who='2');
    if (len(heard) != 2 || ! any(heard==1) || 
	! any(heard==3)) 
	fail paste('failed to alert proper listeners', heard);
    if (len(problems) > 0) {
	for(prob in field_names(problems)) {
	    print problems[prob];
	}
	fail 'Trouble passing state update info';
    }

    return T;
} 
