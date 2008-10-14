#   itemcontainer.g: A Glish object to contain items in a Glish record
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
#   $Id: itemmanager.g,v 19.1 2004/08/25 01:16:55 cvsmgr Exp $

pragma include once;
include 'note.g';
include 'illegal.g';
include 'unset.g';
include 'listenermanager.g';

const is_itemmanager := function(const container)
#
# Is this variable a valid itemcontainer object ?  
#
{
   if (!is_record(container)) return F;
   if (!has_field(container, 'type')) return F;
   if (!is_function(container.type)) return F;
   if (container.type() == 'itemcontainer') return T;
   return F;
}

#@constructor
# @param type     the type of item container
# @param name     an optional identifying name for this collection
# @param dotell   if true, listener alerts will be enabled.  By default, this
#                    is false so that initial values may be set up.
##
const itemmanager := function(type='', name=unset, dotell=F)
#
# Constructor
#
{
    public :=[=];

    private := [=];
    private.const := F;
    private.holes := [];
    private.dotell := dotell;

    private.items := [=];
    private.items::type := type;
    if (is_unset(name)) name := type;
    private.items::name := name;

    private.listeners := listenermanager(private.items::name);

    #------------------------------------------------------------------------
    # Private functions
    #
    # Utility functions for a vector of holes, which contains indices of
    # elements deleted from the itemcontainer. The deleted fields are still
    # part of the container but the values are 'illegal'
    # If a new item is added or set holes are _plugged_ in order of 
    # index.
    #  
    const private.addhole := function(const value) {
	wider private;
	local n := length(private.holes);
	private.holes[n+1]:= value;
	private.holes := sort(private.holes);
	return min(private.holes);
    }
    
    const private.removehole := function() {    
	wider private;
	local n := length(private.holes);
	# is this the last hole in vector
	if ( n > 1 ) {
	    private.holes := private.holes[2:n];
	} else {
	    # empty
	    private.holes := [];
	}
	return min(private.holes);
    }
    const private.hashole := function() {
	wider private;
	if (length(private.holes) > 0) {
	    return T;
	} else {
	    return F;
	}
    }

    const private.plughole := function(const index, const item, const value) {
	wider private;
	itemscopy := [=];
	if (has_field(private.items::, 'type'))
	    itemscopy::type := private.items::type;
	if (has_field(private.items::, 'name'))
	    itemscopy::name := private.items::name;
	k:=1;
	for (str in field_names(private.items)) {	
#    for (k in 1:length(private.items)) {
	    if ( k == index ) {
		itemscopy[item] := value;	    
	    } else {
		itemscopy[str] := private.items[str];
	    }
	    k +:=1;
	}
	private.items := itemscopy;
	return T;
    } 


    #-----------------------------------------------------------------------
    # Public functions
    #

    const public.gui := function () {
	# shut object catalog up
	return T;
    }

    const public.done := function() {
	wider public;
	wider private;
	private := F;
	val public := F;
	return T;
    }

    const public.get := function (const item, default=unset)
    #
    # Get the value of the specified item.
    # If the type of item is an integer, then
    # the numbered field will be recovered.
    # If its not present, you get a fail
    #   
    {
	if (is_integer(item)) {
	    if (item > 0 && item <= public.length() && 
		(!is_illegal(private.items[item])) ) {
		return private.items[item];
	    }
	} else if (is_string(item)) {
	    if (public.has_item(item)) {
		return private.items[item];
	    }
	} else {
	    fail 'the given item was neither an integer nor a string'
	    }

	if (! is_unset(default)) return default;

	msg := spaste('Requested item "', item, '" is not present');
	fail msg;
    }

    const public.has_item := function (const item)
    #
    # See if the specified item exists and is not illegal
    #   
    {
	if (has_field(private, 'items') && has_field(private.items, item)) {
	    if ( is_illegal(private.items[item]) ) {
		return F;
	    } else {
		return T;
	    }
	}
	return F;
    }


    const public.makeconst := function()
    #
    # Make this object non-writable
    #   
    {
	wider private;
	private.const := T;
	return T;
    }

    const public.makeunconst := function()
    #
    # Make this object writable again
    #   
    {
	wider private;
	private.const := F;
	return T;
    }

    const public.length := function(showdeleted=F) {
	if (type_name(showdeleted) != 'boolean') {
	    fail 'flag must be a boolean';
	}
	if (has_field(private, 'items')) {
	    if (showdeleted) {
		return length(private.items);
	    } else {
		return (length(private.items)-length(private.holes));
	    }
	} else {
	    return 0;
	}
    }

    const public.names := function() {
	fnames := [''];
	if (has_field(private, 'items')) {
	    count :=1;
	    for (str in field_names(private.items) ) {
		if (!is_illegal(private.items[str])) {
		    fnames[count] := str;
		    count +:=1;
		}
	    }
	    return fnames;
	} else {
	    return '';
	}
    }

    const public.set := function(const item, const value, who='', skipwho=T) 
    #
    # Make a record in the private data whose field name
    # is the value of "item", and whose value is the
    # value of "value".  You can make anything you
    # like !  
    #
    # Returns a fail if the object is const or the item
    # name is not a string.  
    #
    {   
	wider private, public;
	if (private.const == T) {
	    fail 'This is a const object; you cannot write to it';
	}
	if (!is_string(item)) {
	    fail 'Item must be a string';
	}

	local hasit := public.has_item(item);
	local old := unset;
	if (hasit) old := private.items[item];

	if ( (private.hashole()) && (! hasit) ) {
	    private.plughole(private.holes[1],item,value);
	    private.removehole();
	} else {
	    private.items[item] := value;
	}

	# tell listeners about update
	if (private.dotell) 
	    private.listeners.tell([item=item, old=old, new=value], 
				   who, skipwho);

	return T;
    }

    const public.add := function(const value, who='', skipwho=T) 
    #
    # Make the next record in the private data whose 
    # value is the value of "value".  
    #
    # Returns a fail if the object is const 
    #
    {   
	wider private;
	if (private.const == T) {
	    fail 'This is a const object, you cannot write to it';
	}
	if (!has_field(private, 'items')) private.items := [=];
	if (private.hashole()) {
	    n := private.holes[1];
	    private.removehole();
	} else {
	    n := length(private.items)+1;
	}
	private.items[n] := value;

	# tell listeners about update
	if (private.dotell) 
	    private.listeners.tell([item=n, old=unset, new=value], 
				   who, skipwho);

	return n;
    }

    const public.delete := function(const item, who='', skipwho=T) {
    #
    # Delete a record in the private data whose field name
    # is "item".
    #
    # Returns a fail if the object is const or the item
    # name is not a string/integer or the field doesn't exist
    #    
	wider private;
	if (!has_field(private, 'items')) {
	    fail 'Container is empty';
	}
	if ( (!is_string(item)) && (!is_integer(item)) ) {
	    fail 'Item must be string or integer';
	}
	if (private.const == T) {
	    fail 'This is a const object, you cannot delete from it';
	}

	local fields := field_names(private.items);
	local count := 1;
	local old;
	if (is_string(item)) {
	    if (!public.has_item(item)) {
		fail 'The specified item is not in the container';
	    }	
	    n := fields;
	} else {
	    if (is_illegal(private.items[item])) {
		fail 'The specified item is not in the container';	
	    }
	    n := [1:length(private.items)];
	}
	for ( i in n ) {
	    if ( i == item ) {
		old := private.items[i];
		private.items[i] := illegal;
		private.addhole(count);

		if (private.dotell && ! is_illegal(old)) {
		    if (is_integer) i := fields[i];
		    private.listeners.tell([item=i, old=old, new=unset], 
					   who, skipwho);
		}
	    }
	    count +:=1;
	}

	return T;
    }        

    const public.fromrecord := function (rec=[=], override=T, dotell=F, 
					 who='', skipwho=T) {
	wider public;
	local olddotell := public.willtell();
	public.settell(dotell);

	local nfields := length(rec);
	if (nfields > 0) {
	    local names := field_names(rec);
	    for (i in 1:nfields) {
		if (! override && public.has_item(names[i])) continue;
		ok := public.set(names[i], rec[names[i]], who, skipwho);
		if (is_fail(ok)) fail;
	    }
	}

	public.settell(olddotell);

	return T;
    }

    const public.torecord := function(showdeleted=F) {
	if (type_name(showdeleted) != 'boolean') {
	    fail 'showdeleted must be a boolean'
	    }
	if (has_field(private, 'items')) {
	    if (!showdeleted) {
		outrecord := [=];
		for ( str in split(public.names()) ) {
		    if (!is_illegal(private.items[str])) {
			if (is_itemmanager(private.items[str])) {
			    outrecord[str] := private.items[str].torecord();
			} else {
			    outrecord[str] := private.items[str];
			}
		    }
		}

		if (len(private.items::type) > 0) 
		    outrecord::type := private.items::type;
		if (len(private.items::name) > 0) 
		    outrecord::name := private.items::name;
		return outrecord;
	    } else {
		return private.items;
	    }
	} else {
	    out := [=];
	    if (len(private.items::type) > 0) 
		outrecord::type := private.items::type;
	    if (len(private.items::type) > 0) 
		outrecord::type := private.items::name;
	    return out;
	}
    }

    const public.type := function() {
	return 'itemcontainer';
    }

    #@ 
    # add a listener
    # @param callback   a function to be called when an item is updated.  This 
    #                     function should have the following signature:
    #                     <pre>
    #                        function(state=[=], name='', who='')
    #                     where 
    #                        state    a record desribing the state change (see
    #                                   below)
    #                        name     the name associated with the state; this
    #                                   will be the name associated with this
    #                                   manager set at construction.
    #                        who      the name of the actor that changed the
    #                                   state; an empty string means "unknown".
    #                     </pre>
    #                     The state record will have the following fields:
    #                     <pre>
    #                        item     the name (if updated with set or delete)
    #                                   or number (if updated with add) of the 
    #                                   item that was changed.
    #                        old      the old value
    #                        new      the new value
    #                     </pre>
    #                     If the item was previously unset, old will equal 
    #                        the Glish unset value.
    # @param who        the name to associate with the listener.  This will
    #                     be returned by this function.  If a name is not 
    #                     provided, a unique name will be provided and returned.
    # @return string  represting the name given to the new listener.  
    ##
    public.addlistener := function(callback, who='') {
	wider private;
	return private.listeners.addlistener(callback, who);
    }

    #@
    # remove a listener.  The callback associated with the given name will
    # be thrown away.
    # @param who   the name of the listener to remove
    ##
    public.removelistener := function(who) {
	wider private;
	return private.listeners.removelistener(who);
    }	

    #@
    # return true if listener alerts are enabled.  That is, if true, 
    # listener callbacks will be called when an item is updated.  
    ##
    public.willtell := function() { wider private; return private.dotell; }

    #@
    # set whether listener alerts are enabled.
    # @param value   if true, listeners will be alerted to item updates
    ##
    public.settell := function(value) {
	wider private;
	if (! is_boolean(value)) 
	    fail paste('non-boolean value passed to settell():', value);
	private.dotell := value;
	return T;
    }

    return const ref public;
}

const itemmanagertest := function() {

    ok := listenermanagertest();
    if (is_fail(ok)) return ok;
    if (! ok) fail 'listenermanagertest apparently failed';

    local heard := [];
    local problems := [=];

    checker := function(value, state=[=], name='', who='') {
	wider heard, problems;

	if (! is_string(name) || name != 'test') {
	    if (! has_field(problems, 'name')) 
		problems.name := "Failure passing name";
	}	    
	if (! is_string(who) || who != '2') {
	    if (! has_field(problems, 'who'))
		problems.who := "Failure passing who";
	}	    
	if (! is_record(state) || len(state) != 3) {
	    if (! has_field(problems, 'state'))
		problems.state := paste('Failure setting up state:', state);
	}
	else {
	    if (! has_field(state, 'item') || state.item != 'lamb') {
		if (! has_field(problems, 'item'))
		    problems.item := paste('Failure passing field item:', 
					   state.item);
	    }
	    if (! has_field(state, 'old') || state.old != '.') {
		if (! has_field(problems, 'old'))
		    problems.old := paste('Failure passing field old:', 
					  state.old);
	    }
	    if (! has_field(state, 'new') || state.new != '!') {
		if (! has_field(problems, 'new'))
		    problems.new := paste('Failure passing field new:', 
					  state.item);
	    }
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

    local indata := [mary='had', a='little', lamb='.'];
    local ic := itemmanager(type='test', dotell=T);

    ok := ic.addlistener(cb1, '1');
    if (is_fail(ok)) return ok;
    ok := ic.addlistener(cb2, '2');
    if (is_fail(ok)) return ok;
    ok := ic.addlistener(cb3, '3');
    if (is_fail(ok)) return ok;

    ok := ic.fromrecord(indata);
    if (is_fail(ok)) return ok;
    ok := ic.torecord();
    if (is_fail(ok)) return ok;
    print ok;

    if (!has_field(ok::, 'type') || ok::type != 'test' || 
	!has_field(ok::, 'name') || ok::type != 'test')
	fail paste('failed to set attributes:', ok::);

    if (len(heard) > 0)
	fail paste('listeners mistakenly notified:', heard);

    ok := ic.set('lamb', '!', who='2');
    if (is_fail(ok)) return ok;
    print ic.torecord();

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
