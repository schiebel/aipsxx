# dishresman: Dish results manager closure
# Copyright (C) 1998,1999,2000,2001,2002,2003
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
# $Id: dishresman.g,v 19.1 2004/08/25 01:11:05 cvsmgr Exp $
#
#----------------------------------------------------------------------------

# include guard
# pragma include once;

include 'note.g';
include 'guicomponents.g';
include 'popuphelp.g';
include 'inspect.g';
include 'clipboard.g';

# TBD: 
#   1) make sure the test functions test everything as much as possible
#   2) move the test function to tdishresman.g


 
const dishresman := function(itbrowsefn, recbrowsefn, recplotfn, 
			ref parentdish=F)
{
    public := [=];
    private := [=];

    # The state at startup is to NOT have a GUI
    private.gui := F;
    private.dish := ref parentdish;

    # the known types are 'OTHER', 'SDRECORD', and 'SDITERATOR'
    # records can be plotted and browsed, iterators can be browsed
    # and OTHER can do neither
    private.itbrowsefn := itbrowsefn;
    private.recbrowsefn := recbrowsefn;
    private.truerecplotfn := recplotfn;
    private.reallyplot := T;
    private.recplotfn := function (avalue, aname) {
	wider private;
	if (private.reallyplot) private.truerecplotfn(avalue,aname);
    }

    # WS comboboxes, this info is NOT preserved as state info
    # the items which request that a combobox be created must do
    # so again and, if necessary, they must set the current selection
    # in that combobox to reflect its state
    private.wscbs := [=];
    private.wscbcallbacks := [=];
    private.wscbcount := 0;
    private.wsindices := [=];
    # translated from 'r','w','rw' to 0,1,2
    private.ONLYREAD := 0;
    private.ONLYWRITE := 1;
    private.ALL := 2;
    private.wsmodes := [=];

    private.browsers := [=];
    private.bcount := 0;
    private.dbcount := 0;

    # the private data store
    # how many items are known
    private.count := 0;
    # the actual data: names, descriptions, and types
    # each are indexed and have the same length == private.count
    # the value is a global value, since the name is made global, and that
    # global value is always used.  This means that it is possible for the
    # user to screw with this value without the results manager knowing about
    # it, but that is the price to be payed for making these global and
    # available to the user.
    #
    private.names := F;
    private.descriptions := F;
    private.types := F;
    # remember what the details of the last viewed item - this is the
    # most recent thing sent to the plotter - we need to make a copy
    # since the user might delete it from the results manager but it
    # would remain on the plotter and still be thought of as the last
    # viewed item.  Normally, this will be a reference that is broken 
    # if the user deletes it.
    private.lastViewed := [=];
    private.lastViewed.name := '';
    private.lastViewed.value := F;
    private.lastViewed.description := '';

    # remember what is currently selected, by index numbers
    # initially nothing is selected
    private.selection := F;

    # for autodecoration, whenever a variable is added to this
    # this with the autodecoration flag true (the default)
    # then the name is used as a base and a variable is tracked
    # for that type to add a number to it.
    # e.g. if the name is "average" and the next index for
    # the "average" name is 3, then autodecoration would give the
    # name "average3" and increase the counter for that name
    # by 1, if that name has not been seen before, a new counter is made
    private.autodec := [=];

    # hack to allow the paste function to signal to add that this value
    # already exists and need not be created - i.e. use it as it
    # it is set in paste and cleared in add
    private.noCreateValue := F;

    private.decorate := function(name) {
	wider private;
	if (!has_field(private.autodec, name)) {
	    private.autodec[name] := 1;
	}
	result := spaste(name,private.autodec[name]);
	private.autodec[name] +:= 1;
	return result;
    }

    # verify that an index is valid
    # If the index is NOT ok then the message is logged to
    # the logger via note().  If priority=='SEVERE', then this
    # will also fail.  message is the ... arguments. 
    # Otherwise this returns T.
    # Note that this works for an array of indices too.
    private.indexok := function(index, ..., priority='SEVERE') {
	wider private;
	msg:=spaste(...);
	notok := as_boolean(!is_integer(index) || sum(index > private.count) || sum(index < 1));
	if (notok) {
	    note(msg,priority=priority,origin='DISH Results Manager');
	    if (priority=='SEVERE') {
		fail msg;
	    }
	}
	return (!notok);
    }

    private.browseit := function(itsname, itstype) {
        wider private;
        if (is_record(private.dish) && has_field(private.dish,'busycursor') &&
            is_function(private.dish.busycursor)) {
            private.dish.busycursor();
        }
        private.bcount +:= 1;
	brtime:=time()
        bname:=itsname;
       bname := as_string(private.bcount);
       private.browsers[bname] := [=];
       private.browsers[bname].name := itsname;
#        private.browsers[itsname].name:=itsname;
        if (itstype == 'SDRECORD') {
            private.browsers[bname].browser :=
                private.recbrowsefn(symbol_value(itsname), itsname);
        } else {
            private.browsers[bname].browser := private.itbrowsefn(symbol_value(itsname), itsname);
        }
        if (is_agent(private.browsers[bname].browser)) {
            whenever private.browsers[bname].browser->dismissed do {
                private.brdismissed(bname);
            }
        }
        if (is_record(private.dish) && has_field(private.dish,'normalcursor') &&
            is_function(private.dish.normalcursor)) private.dish.normalcursor();
        return bname;
    }

    # called when a browser is dismissed
    private.brdismissed := function(itsname) {
	wider private;
	if (has_field(private.browsers, itsname)) {
	    private.browsers[itsname] := F;
	    private.dbcount +:= 1;
	}
	if (private.dbcount > 20) {
	    # do garbage collection
	    newbr := [=];
	    for (name in field_names(private.browsers)) {
		if (is_record(private.browser[name])) {
		    newbr[name] := [=];
		    newbr[name].name := private.browsers[name].name;
		    newbr[name].browser := private.browsers[name].browser;
		}
	    }
	    private.dbcount := 0;
	    private.browsers := newbr;
	}
    }

    # add an item, maintain current selection, symbol_set() makes this symbol
    # a global symbol after decoration, this returns name after decoration
    # No clobbering of existing symbols is allowed, name must be
    # undefined or throw is used to throw an error and a fail.
    # auto decoration is turned off if decorate=F
    const public.add := function(name, description, ref value, type='OTHER',
				 decorate=T) {
	wider private;
	name =~ s/-/_/g; # substitute any '-' with '_'
	name =~ s/\./_/g; # substitute any '.' with '_'

	if (decorate) name := private.decorate(name);
	if (is_defined(name) && !private.noCreateValue) {
	    notok := throw(paste('The named value',name,
				 'already exists it can not be added'),
			   origin='dishresman');
	    return notok;
	}
	# make sure we really don't need to create this value
	if (private.noCreateValue) private.noCreateValue := is_defined(name);
        # try out the symbol_set on a boolean value to see if this is a
        # valid glish variable
        if (!private.noCreateValue) {
	    # this regex can be used to see if a glish value is a valid variable name
	    regname := m/^[_a-zA-Z]+[_0-9a-zA-Z]*$/ ;
	    if (!(name ~ regname)) {
                note(paste('The default value of', name,'is not a valid glish variable.'),
                     priority='WARN', origin='dish results manager');
                oldname := name;
		# see if adding an "x" in the front make it work
		name := spaste('x',name);
		if (!(name ~ regname)) {
		    # ultimate fallback position
		    name := private.decorate('dishresman');
		}
                note(paste('Using',name,'instead of',oldname),
                     priority='WARN', origin='dish results manager');
            } else {
                # make sure we remove this one
                symbol_delete(name);
            }
        } else {
	    private.noCreateValue := F;
	}
	private.count +:= 1;
	if (private.count > 1) {
	    private.names[private.count] := name;
	    private.descriptions[private.count] := description;
	    private.types[private.count] := type;
	    if (private.wscbcount > 0) {
		for (whichcb in 1:private.wscbcount) {
		    private.wsindices[whichcb][private.count] := -1;
		}
	    }
        } else {
	    private.names := name;
	    private.descriptions := description;
	    private.types := type;
	    if (private.wscbcount > 0) {
		for (whichcb in 1:private.wscbcount) {
		    private.wsindices[whichcb] := -1;
		}
	    }
	}
	if (!is_boolean(private.gui)) {
	    private.gui.add(name);
	}
	# need to go through a global for SDITERATORs to preserve the reference
	# and tool nature
	j := F;
	if (type == 'SDITERATOR') {
	    global system;
	    # use system.scratch.dishresman - create if not there
	    if (!has_field(system,'scratch')) {
		system.scratch := [=];
	    }
	    if (!has_field(system.scratch,'dishresman')) {
		system.scratch.dishresman := [=];
	    }
	    system.scratch.dishresman.sdit := ref value;
#	    j := eval(paste(name,':= ref system.scratch.dishresman.sdit'));
	    j := symbol_set(name,value);
	} else {
	    j := symbol_set(name, value);
	}
        if (is_fail(j)) {
            return throw(paste('Unexpected failure in creating named value :',name), origin='dishresman');
        }

	# and deal with any WS callbacks
	if (type == 'SDITERATOR' && private.wscbcount > 0) {
	    for (whichcb in 1:private.wscbcount) {
		if (private.wsmodes[whichcb]==private.ALL ||
		    (private.wsmodes[whichcb]==private.ONLYREAD && !value.iswritable()) ||
		    (private.wsmodes[whichcb]==private.ONLYWRITE && value.iswritable())) {
		    private.wscbs[whichcb].insert(name);
		    selectit := F;
		    if (any(private.wsindices[whichcb] >= 0)) {
			private.wsindices[whichcb][private.wsindices[whichcb]>=0] +:= 1;
		    } else {
			# this is the first entry, select it
			selectit := T;
		    }
		    private.wsindices[whichcb][private.count] := 0;
		    if (selectit) private.wscbs[whichcb].select(0);
		    if (is_function(private.wscbcallbacks[whichcb])) {
			private.wscbcallbacks[whichcb]('INSERT');
		    }
		}
	    }
	}
	return name;
    }

    # get the current state info in a record
    # the structure of this record is:
    # rec - record holding the internal data info
    #            in the following fields names,
    #            descriptions, types and values.
    #            In the case of an SDITERATOR, the
    #            value is a string array which, when
    #            evaluated results in that SDITERATOR.
    #            These are the steps necessary to reconstruct
    #            that iterator.
    #       One additional field, selection, holds the
    #            current selection info.
    const public.getstate := function() {
	wider private;
	wider public;
	state := [=];
	# the basics
	state.names := private.names;
	state.descriptions := private.descriptions;
	state.types := private.types;
	state.autodec := private.autodec;
	state.lastViewed := private.lastViewed;
	# now get the values;
	if (private.count == 0) {
	    state.values := [=];
	} else {
	    if (private.count == 1) {
		state.values[state.names[1]] := public.getvalues(1);
	    } else {
		state.values := public.getvalues(1:private.count);
	    }
	    # this mask is T for things to keep and F for things (sditerators)
	    # which have gone bad (no longer valid sditerators)
	    keepmask := array(T,private.count);
	    # and replace those values by the sditerator history only
	    for (i in 1:private.count) {
		if (state.types[i] == 'SDITERATOR') {
		    # verify that its still an sditerator
		    if (is_sditerator(state.values[state.names[i]])) {
			state.values[state.names[i]] := state.values[state.names[i]].history();
		    } else {
			# mark this as something to not keep
			keepmask[i] := F;
			# just to be safe
			state.values[state.names[i]] := F;
		    }
		}
		
	    }
	    if (!all(keepmask)) {
		# some things to delete
		if (all(keepmask==F)) {
		    # everything was deleted
		    state.names := [=];
		    state.descriptions := [=];
		    state.types := [=];
		    state.values := [=];
		} else {
		    # somethings were kept
		    state.names := state.names[keepmask];
		    state.descriptions := state.descriptions[keepmask];
		    state.types := state.types[keepmask];
		    # values have to be set using the correct name, can't rely on order
		    oldvals := state.values;
		    state.values := [=];
		    for (i in 1:len(state.names)) {
			state.values[state.names[i]] := oldvals[state.names[i]];
		    }
		}
	    }
	}
	state.selection := private.selection;
	# and the browser state information
	state.browsers := [=];
	brcount := 0;
	for (name in field_names(private.browsers)) {
	    if (is_record(private.browsers[name])) {
		brcount +:= 1;
		state.browsers[brcount] := [=];
		state.browsers[brcount].name := private.browsers[name].name;
		state.browsers[brcount].state := private.browsers[name].browser.getstate();
	    }
	}
	return state;
    }

    # set the state from the input state record, same
    # format as that returned by getstate.
    # All previous state information is lost.
    # if (overwrite==F) then state information which would
    # overwrite an existing global variable is not set
    # and an error message is sent to the logger
    # In any case, an attempt is made to use all of the
    # info in the record.  If some of it is ignored or can
    # not be recovered (e.g. a disk file required to make
    # an sditerator is no longer there) then this may lead
    # to cascading errors.
    const public.setstate := function(staterec, overwrite=T) {
	wider private;
	wider public;
	rmtime:=time();
	# turn off actual plotting until end
	private.reallyplot := F;
	# if an empty record, reset to default state, forgetting everything
	if (len(staterec) == 0) {
	    staterec := [=];
	    staterec.names := F;
	    staterec.descriptions := F;
	    staterec.types := F;
	    staterec.values := [=];
	    staterec.selection := F;
	    staterec.autodec := [=];
	    staterec.lastViewed := [=];
	    private.lastViewed.name := '';
	    private.lastViewed.value := F;
	    private.lastViewed.description := '';
	} else {
	    # do a sanity check first
	    if (!(has_field(staterec,'names') && 
		  has_field(staterec ,'descriptions') &&
		  has_field(staterec,'types') &&
		  has_field(staterec,'values') &&
		  has_field(staterec,'selection') &&
		  has_field(staterec,'autodec') &&
		  has_field(staterec,'lastViewed'))) {
		private.reallyplot := T;
		notok := throw('Results Manager: the indicated state record does not have all of the required fields',
			       origin='dishresman.setstate');
		return notok;
	    }
	}
	# first, delete ALL of the current state
	if (private.count > 0) public.delete(1:private.count);
	# if overwrite is T, delete any global symbols that would be overwritten
	if (overwrite && len(staterec.names) > 0 && is_string(staterec.names)) {
	    n := symbol_names()
	    for (i in 1:len(staterec.names)) {
		if (any(n==staterec.names[i])) {
		    junk := symbol_delete(staterec.names[i]);
		}
	    }
	}
	# dismiss any browsers
	for (name in field_names(private.browsers)) {
	    if (is_record(private.browsers[name])) {
		private.browsers[name].browser.dismiss();
	    }
	}
	private.browsers := [=];
	private.brcount := 0;
	private.dbcount := 0;

	# and now set most everything
	private.count := 0;
	private.names := staterec.names;
	if (is_string(private.names)) private.count := len(private.names);
	private.types := staterec.types;
	private.descriptions := staterec.descriptions;
	private.selection := staterec.selection;
	private.autodec := staterec.autodec;
	if (private.wscbcount > 0) {
	    for (whichcb in 1:private.wscbcount) {
		if (private.count > 0) {
		    private.wsindices[whichcb] := array(-1,private.count);
		} else {
		    private.wsindices[whichcb] := as_integer([]);
		}
	    }
	}
	# and set the values
	n := symbol_names();
	if (private.count > 0) {
	    for (i in 1:private.count) {
		name := private.names[i];
		if (any(n==name)) {
		    # emit some error message via note, but continue;
		    junk := note('The global symbol ',name,' is already defined. ',
				 'It can not be reset in this results manager. ',
				 'This may lead to cascading errors.',
				 priority='SEVERE',origin='dishresman.setstate');
		} else {
		    if (!has_field(staterec.values, name)) {
			# this shouldn't be happening, but it sometimes does
			# for now, just set the problem value to be an F
			junk := symbol_set(name, F);
			# make sure the indicated TYPE is OTHER
			private.types[i] := 'OTHER';
		    } else {
			if (private.types[i] != 'SDITERATOR') {
			    junk := symbol_set(name, staterec.values[name]);
			} else {
			    ithist := staterec.values[name];
			    if (len(ithist) == 0) {
				junk := note('The sditerator history in the state record ',
					     'has no information.  Hence the sditerator named ',
					     name,' can not be reconstructed. ',
					     'This may lead to cascading errors.',
					     priority='SEVERE',origin='dishresman.setstate');
				# should never happen, emit an error message
				private.types[i] := 'OTHER';
			    } else {
				# first line is the initial constructor
				# early versions did not specify arguments by name, watch for that
				ctor := ithist[1];
				if (!(ctor ~ m/sditerator\(filename/)) {
				    # further sanity check
				    if (ctor ~ m/sditerator\(\'.*?\',[TF],\[.*\],\'.*?\',\'.*?\',[TF],[TF]/ ) {
					# and finally add the argument names, in two passes - seems to crash glish otherwise
					ctor ~:=  s/(sditerator\()(\'.*?\'\,)([TF]\,)(\[.*?\]\,)(\'.*?\'\,)(\'.*?\'\,)(.*)/$1filename=$2readonly=$3selection=$4lockoptions=$5host=$6$7/ ;
					ctor ~:= s/(.*?host=\'.*?\,)([TF]\,)([TF]\))/$1forcenewserver=$2shm=$3/ ;
				    }
				}
				theit := eval(ctor);
				# need to go through a global for SDITERATORs to preserve the reference
				# and tool nature
				j := F;
				global system;
				# use system.scratch.dishresman - create if not there
				if (!has_field(system,'scratch')) {
				    system.scratch := [=];
				}
				if (!has_field(system.scratch,'dishresman')) {
				    system.scratch.dishresman := [=];
				}
				system.scratch.dishresman.sdit := ref theit;
				j := eval(paste(name,':= ref system.scratch.dishresman.sdit'));
				if (is_fail(theit) || !is_record(theit)) {
				    junk := note('Failed to re-construct sditerator named ', name,
						 ' from this history line : ', ctor,
						 '.  This may lead to cascading errors.',
						 priority='SEVERE',origin='dishresman.setstate');
				    private.types[i] := 'OTHER';
				} else {
				    if (len(ithist) >= 2) {
					# additional lines are operators on the global name
					for (i in 2:len(ithist)) {
					    action := spaste(name,' := ',name,'.',ithist[i]);
					    junk := eval(action);
					    if (eval(spaste('is_fail(',name,')')) || 
						!eval(spaste('is_record(',name,')'))) {
						junk := note('Failed to re-construct sditerator named ', name,
							     ' from this history line : ', ithist[i],
							     '.  This may lead to cascading errors.',
							     priority='SEVERE', origin='dishresman.setstate');
						private.types[i] := 'OTHER';
						# end the loop here
						break;
					    }
					}
				    }
				}
			    }
			}
		    }
		}
	    }
	    # add these to any existing ws comboboxes 
	    # the delete call above already deleted things
	    if (private.wscbcount > 0) {
		indxs := [1:private.count];
		indxsmask := private.types=='SDITERATOR';
		if (any(indxsmask) == T) {
		    for (whichcb in 1:private.wscbcount) {
			locmask := indxsmask;
			if (private.wsmodes[whichcb] == private.ONLYREAD) {
			    for (indx in indxs[indxsmask]) {
				ws := symbol_value(private.names[indx]);
				if (ws.iswritable()) locmask[indx] := F;
			    }
			} else if (private.wsmodes[whichcb] == private.ONLYWRITE) {
			    for (indx in indxs[indxsmask]) {
				ws := symbol_value(private.names[indx]);
				if (!ws.iswritable()) locmask[indx] := F;
			    }
			}
			locindxs := indxs[locmask];
			if (len(locindxs) > 0) {
			    for (indx in locindxs) {
				private.wscbs[whichcb].insert(private.names[indx]);
			    }
			    if (is_function(private.wscbcallbacks[whichcb])) {
				private.wscbcallbacks[whichcb]('INSERT');
			    }
			    # insert adds to the head so indices are reverse order
			    indices := [(len(locindxs)-1):0];
			    private.wsindices[whichcb][locmask] := indices;
			}
		    }
		}
	    }
	    
	    # Finally, update the GUI, if present
	    if (!is_boolean(private.gui)) {
		private.gui.add(private.names);
		private.gui.newselection();
	    }
	}
	# and finally any browsers, we must also check to see if the
	# named value still exists for each browser with state info
	if (has_field(staterec,'browsers') &&
	    is_record(staterec.browsers)) {
	    for (field in field_names(staterec.browsers)) {
		brrec := staterec.browsers[field];
		if (is_record(brrec) && 
		    has_field(brrec,'name') && is_string(brrec.name) &&
		    has_field(brrec,'state')) {
		    # does this named thing exist in this results manager
		    mask := private.names == brrec.name;
		    if (sum(mask) == 1) {
			type := private.types[mask];
			name := private.names[mask];
			itsval := symbol_value(name);
			if (type == 'SDRECORD' && is_sdrecord(itsval)) {
			    bname := private.browseit(name, type);
			    if (has_field(private.browsers[bname],'setstate')) {
#				private.browsers[bname].setstate(brrec.state);
			    }
			} else if (type == 'SDITERATOR' && is_sditerator(itsval)) {
			    bname := private.browseit(name, type);
			    if (has_field(private.browsers[bname].browser,'setstate')) {
#				private.browsers[bname].browser.setstate(brrec.state);
			    }
			}
		    }
		}
	    }
	}
	# set last viewed last to ensure that it really is the
	# last viewed thing
	private.reallyplot := T;
	if (is_record(private.gui) && is_record(staterec.lastViewed) &&
	    has_field(staterec.lastViewed,'name') &&
	    has_field(staterec.lastViewed,'value') &&
	    has_field(staterec.lastViewed,'description') &&
	    is_string(staterec.lastViewed.name) &&
	    is_string(staterec.lastViewed.description) &&
	    is_sdrecord(staterec.lastViewed.value) &&
	    is_function(private.recplotfn)) {
	    private.lastViewed := staterec.lastViewed;
#	    print 'dishresman invoking recplotfn while setting state';
	    junk := private.recplotfn(private.lastViewed.value, private.lastViewed.name);
	} else {
	    private.lastViewed.name := '';
	    private.lastViewed.value := F;
	    private.lastViewed.description := '';
	}
	return T;
    }

    # delete items - item can be any array of valid index items
    const public.delete := function(items) { 
	wider private;
	if (private.indexok(items,'delete(items), items out of range') && len(items) > 0) {
	    mask := array(T,private.count);
	    mask[items] := F;
	    deletedNames := private.names[!mask];
	    deletedTypes := private.types[!mask];
	    deletedWSIndices := [=];
	    if (private.wscbcount > 0) {
		for (whichcb in 1:private.wscbcount) {
		    deletedWSIndices[whichcb] := private.wsindices[whichcb][!mask];
		    if (any(deletedWSIndices[whichcb]>=0)) {
			locs := [1:private.count];
			locs := locs[!mask];
			locs := locs[deletedWSIndices[whichcb] >= 0];
			deletedWSIndices[whichcb] := deletedWSIndices[whichcb][deletedWSIndices[whichcb] >= 0];
			# adjust all other indices appropriately
			grad := array(0,private.count);
			for (i in [len(locs):1]) {
			    grad[1:locs[i]] +:= 1;
			}
			grad[private.wsindices[whichcb]<0] := 0;
			private.wsindices[whichcb] -:= grad;
		    } else {
			deletedWSIndices[whichcb] := as_integer([]);
		    }
		    private.wsindices[whichcb] := private.wsindices[whichcb][mask];
		}
	    }
	    # update the selection
	    if (is_integer(private.selection)) {
		selectionMask := array(F,private.count);
		selectionMask[private.selection] := T;
		selectionMask := selectionMask[mask];
	    } else {
		selectionMask := F;
	    }
	    private.names := private.names[mask];
	    private.descriptions := private.descriptions[mask];
	    private.types := private.types[mask];
	    private.count := len(private.names);
	    # clean them out of the global name space
	    for (i in 1:len(deletedNames)) {
		if (deletedTypes[i] == 'SDITERATOR') {
		    ws := symbol_value(deletedNames[i]);
#		    print 'fnames ',field_names(ws),is_sditerator(ws),ws.name();#		    MYSTICAL: this gets rid of a transient problem where
#		    the error:
#                   Method type fails!
#		    No such object (6) has been created
		    # verify that its still an sditerator
		    if (is_sditerator(ws)) {
			ok:=ws.name();
			junk := ws.done();
		    }
		}
		junk := symbol_delete(deletedNames[i]);
	    }
	    # anything T in selectionMask IS the remaining selection
	    if (sum(selectionMask) > 0) {
		private.selection := [1:private.count][selectionMask];
		if (len(private.selection) < 1) private.selection := F;
	    } else {
		private.selection := F;
	    }
	    # and update the GUI
	    if (!is_boolean(private.gui)) {
		private.gui.delete(items);
	    }
	    # and any ws comboboxes
	    if (private.wscbcount > 0) {
		for (whichcb in 1:private.wscbcount) {
		    if (len(deletedWSIndices[whichcb]) > 0) {
			# mostly these will be deleted one at a time, so
			# just do that here although for those times when
			# there is more than one, it might make sense to
			# look for contiguous indices and do it all at once
			# do it in reverse order to preserve the indecies
			# even as they are deleted
			# also, if the entry contents is the current index
			# delete it as well
			currEntry := private.wscbs[whichcb].getentry();
			# this does it in reverse sorted order
			for (indx in sort(deletedWSIndices[whichcb])[len(deletedWSIndices[whichcb]):1]) {
			    if (currEntry == private.wscbs[whichcb].get(indx)) {
				private.wscbs[whichcb].insertentry('');
			    }
			    private.wscbs[whichcb].delete(indx);
			}
			if (is_function(private.wscbcallbacks[whichcb])) {
			    private.wscbcallbacks[whichcb]('DELETE');
			}
		    }
		}
	    }
	}
	# if nothing is left, also reset the autodecoration indices
	if (private.count == 0) private.autodec := [=];
	return T;
    }

    # how many items are currently known
    const public.size := function() {
	wider private;
	return private.count;
    }

    # how many selections are there currently
    const public.selectionsize := function() {
	wider private;
	result := len(private.selection);
	if (is_boolean(private.selection)) result := 0;
	return result;
    }

    # index of selected
    const public.getselectind := function() {
	wider private;
	return private.selection;
    };

    # get the names associated with the selections
    const public.getselectionnames := function() {
	wider private;
	result := as_string([]);
	if (!is_boolean(private.selection)) {
	    result := private.names[private.selection];
	}
	return result;
    }
    # get the value associated with the selections, returned in a 
    # record where the value of each selection is a separate field,
    # the name of that selection.
    const public.getselectionvalues := function() {
	wider private;
	wider public;
	names := public.getselectionnames();
	result := [=];
	if (len(names)) {
	    result := symbol_value(names);
	}
	return result;
    }

    # get the description for the selections
    const public.getselectiondescriptions := function() {
	wider private;
	result := as_string([]);
	if (!is_boolean(private.selection)) {
	    result := private.descriptions[private.selection];
	}
	return result;
    }

    # return the names corresponding to the given indices
    private.getnames := function(indices) {
	wider private;
	result := as_string([]);
	if (private.indexok(indices,'getnames: index/indices out of range')) 
	    result :=  private.names[indices];
	return result;
    }
    const public.getnames := function(indices) {
	wider private;
	return private.getnames(indices);
    }

    # return the descriptions corresponding to the given indices
    const public.getdescriptions := function(indices) {
	wider private;
	result := as_string([]);
	if (private.indexok(indices,'getdescriptions: index/indices out of range')) 
	    result :=  private.descriptions[indices];
	return result;
    }

    const public.setdescription := function(index, newdescription) {
	wider private;
	if (len(index) != 1) {
	    notok := throw('Results Manager: you can only set one discription at a time',
			   origin='dishresman.setdescription()');
	    return notok;
	}
	if (private.indexok(index,'setdescription: index out of range'))
	    private.descriptions[index] := newdescription;
    }

    # decipher the type of the argument, SDRECORD, SDITERATOR, or OTHER
    private.whichtype := function(arg) {
	if (is_sdrecord(arg)) return 'SDRECORD';
	if (is_sditerator(arg)) return 'SDITERATOR';
	return 'OTHER';
    }
    # copy the current selections, making a record of names,
    # descriptions and values, sends these to the default clipboard, dcb
    const public.copy := function() {
	wider public;
	cbrec := [=];
	cbrec.names := public.getselectionnames();
	cbrec.descriptions := public.getselectiondescriptions();
	if (len(cbrec.names) == 1) {
	    cbrec.values := [=];
	    cbrec.values[cbrec.names[1]] := public.getselectionvalues();
	} else {
	    cbrec.values := public.getselectionvalues();
	}
	return dcb.copy(cbrec);
    }

    const public.paste := function() {
	wider public;
	wider private;
	cbrec := dcb.paste();
	# is this from within dish
	if (has_field(cbrec, "names") &&
	    has_field(cbrec, "descriptions") && 
	    has_field(cbrec, "values")) {
	    # apparently so
	    if (len(cbrec.names) > 0) {
		names := as_string([]);
		if (public.size() > 0) 
		    names := public.getnames(1:public.size());
		for (i in 1:len(cbrec.names)) {
		    decorate := F;
		    # make sure we have a unique name, decorate if necessary
		    usename := cbrec.names[i];
		    if (any(names == usename)) {
			# its not unique, need a decoration
			decorate := T;
			# and a modified name
			usename := spaste(cbrec.names[i],'paste');
		    } else {
			if (has_field(cbrec, "valueIsGlobal")) {
			    private.noCreateValue := cbrec.valueIsGlobal;
			}
		    }
		    public.add(usename, cbrec.descriptions[i],
			       cbrec.values[cbrec.names[i]],
			       private.whichtype(cbrec.values[cbrec.names[i]]), 
			       decorate);
		}
	    }
	}else if (len(cbrec) > 0) {
	    # just add this in as is
	    public.add('paste','pasted from the clipboard',
		       cbrec, private.whichtype(cbrec), T);
	}
      
	return T;
    }
  
    # return the values associated with the indices, if there is only
    # one index, the value is returned, else a record with each value
    # held in a field having its associated name is returned.
    const public.getvalues := function(indices) {
	wider private;
	result := [=];
	if (private.indexok(indices,'getbyindex: index/indices out of range')) 
	    result :=  symbol_value(private.names[indices]);
	return result;
    }

    # copy this value to the clipboard

    # make a selection
    const public.select := function(indices,plotIt=T) {
	wider private;
	if (is_string(indices) && len(indices) < 3) {
	    indices[indices=='start'] := '1';
	    indices[indices=='end'] := as_string(private.count);
	    indices := as_integer(indices);
	}
	if (private.indexok(indices,'select: index/indices out of range')) {
	    private.selection := indices;
	    if (len(private.selection) < 1) private.selection := F;
	    if (!is_boolean(private.gui)) private.gui.newselection(plotIt);
	}
    }

    # selects a single entry by name
    # if name is a vector, all elements past the first are ignored
    const public.selectbyname := function(name) {
	wider private;
	mask := private.names == name[1];
	if (any(mask)) {
	    index := [1:len(mask)][mask];
	    public.select(index);
	}
    }

    # request that a new ws combobox be created
    # callback is optionally a function which takes
    # as an argument the type of operation which just
    # happened (RENAME, INSERT, and DELETE) as a string.
    # mode is one of : r - read only, excludes writable ones, w
    # writeable, excluse read only ones, and rw - all of them
    const public.wscombobox := function(parentframe, labeltext,
					callback=F, mode='r',
					help='The working set in use by this operation.',
					widgetset=dws) {
	wider private;
	if (is_agent(parentframe) && is_string(labeltext)) {
	    private.wscbcount +:= 1;
	    # anything to add initially?
	    wsnames := F;
	    wsindmask := F;
	    # decipher the mode
	    locmode := private.ALL;
	    if (mode == 'r') locmode := private.ONLYREAD;
	    if (mode == 'w') locmode := private.ONLYWRITE;
	    private.wsmodes[private.wscbcount] := locmode;
	    if (private.count > 0) {
		wsindmask := private.types == 'SDITERATOR';
		if (locmode != private.ALL && any(wsindmask)) {
		    for (i in 1:len(wsindmask)) {
			if (wsindmask[i]) {
			    ws := symbol_value(private.names[i]);
			    if (locmode == private.ONLYREAD && ws.iswritable()) wsindmask[i] := F;
			    if (locmode == private.ONLYWRITE && !ws.iswritable()) wsindmask[i] := F;
			}
		    }
		}
		if (any(wsindmask)) wsnames := private.names[wsindmask];
	    }
	    # reverse the order of wsnames
	    wsnames := wsnames[len(wsnames):1];
	    private.wscbs[private.wscbcount] := 
		widgetset.combobox(parentframe,labeltext, wsnames, entrydisabled=T,
				   autoinsertorder='head',
				   help=help);
	    private.wscbcallbacks[private.wscbcount] := callback;
	    if (private.count > 0) {
		private.wsindices[private.wscbcount] := array(-1,private.count);
	    } else {
		private.wsindices[private.wscbcount] := as_integer([]);
	    }
	    if (is_string(wsnames)) {
		newindices := [(len(wsnames)-1):0];
		private.wsindices[private.wscbcount][wsindmask] := newindices;
	    }
	}
	return private.wscbs[private.wscbcount];
    }
	

    # return the last viewed data [value, name, description]
    const public.getlastviewed := function() {
	wider private;
	return private.lastViewed;
    }

    # set the lastviewed record
    const public.setlastviewed := function(rec) {
	wider private;
	if (!(has_field(rec,'value') && has_field(rec,'name') && 
	      has_field(rec,'description'))) {
	    return throw('Missing fields in last viewed record',
			 origin='dishresman.setlastviewed()');
	}
	private.lastViewed.value := rec.value;
	private.lastViewed.name := rec.name;
	private.lastViewed.description := rec.description;
    }	

    # construct the GUI frontend to the results manager within the given
    # frame using the indicated title
    const public.gui := function(parent, title='Variable',
				 watchedagent=F,
				 widgetset = dws)
    {
	wider private;
	wider public;

	# only do this if one has not already been provided
	if (!is_boolean(private.gui)) return;

	private.gui := [=];
	if (is_agent(parent)) {
	    private.gui.topFrame := 
		widgetset.frame(parent, side='top', expand='both');
	} else {
	    private.gui.topFrame := 
		widgetset.frame(title='Results Manager', side='top', 
				expand='both');
	}
	private.gui.topLabel := 
	    widgetset.label(private.gui.topFrame, 
			    text='Results Manager', 
			    justify='center');
	private.gui.outerFrame := 
	    widgetset.frame(private.gui.topFrame, side='left', expand='both');
	private.gui.leftFrame := 
	    widgetset.frame(private.gui.outerFrame, side='top', expand='y');
	private.gui.lbLabel := 
	    widgetset.label(private.gui.leftFrame, title);
	private.gui.lbFrame := 
	    widgetset.frame(private.gui.leftFrame, side='left', expand='y');
	# is there a good reason NOT to export the selection here?
	private.gui.listbox := 
	    widgetset.listbox(private.gui.lbFrame, width=20, 
			      height=5, fill='both', 
			      mode='extended', exportselection=F);
	popuphelp(private.gui.lbLabel,
		  hlp='Global variables known to DISH.',
		  txt='Created by operations and made known via dish.rm().add',
		  combi=T);
	# add the copy/paste popup
        copyItems := ['Copy to clipboard', 'Paste from clipboard', 
			'Copy to calculator'];
	private.gui.copypastemenu := 
	    widgetset.popupselectmenu(private.gui.listbox, copyItems);
	whenever private.gui.copypastemenu->select do {
	    wider private,public;
	    option := $value;
	    if (option == 'Copy to clipboard') {
		public.copy();
	    } else if (option == 'Paste from clipboard') {
		public.paste();
	    } else if (option == 'Copy to calculator') {
                if (has_field(private.dish.ops(),'calculator')) {
                    # use the clipboard, first copy it to the CB
                    public.copy():
                    # then paste it from the clipboard
                    private.dish.ops().calculator.paste();
                }
            }
	}
#        private.gui.copypastemenu :=
#            widgetset.popupselectmenu(private.gui.listbox, copyItems);
#        whenever private.gui.copypastemenu->select do {
#            wider public;
#            option := $value;
#            if (option == 'Copy to clipboard') {
#                public.copy();
#            } else if (option == 'Paste from clipboard') {
#                public.paste();
#            } else if (option == 'Copy to calculator') {
#                if (has_field(private.dish.ops(),'calculator')) {
#                    # use the clipboard, first copy it to the CB
#                    public.copy():
#                    # then paste it from the clipboard
#                    private.dish.ops().calculator.paste();
#                }
#            }
#        }
	private.gui.verticalSB := widgetset.scrollbar(private.gui.lbFrame);
	private.gui.rightFrame := 
	    widgetset.frame(private.gui.outerFrame, side='top');
	private.gui.infoLabel := 
	    widgetset.label(private.gui.rightFrame, 'Info');
	private.gui.entryFrame := 
	    widgetset.frame(private.gui.rightFrame, side='top', expand='both');
	private.gui.absorberFrame := 
	    widgetset.frame(private.gui.rightFrame, height=1);
	private.gui.fieldFrame := 
	    widgetset.frame(private.gui.entryFrame, side='left', expand='x');
	private.gui.descriptionLabel := 
	    widgetset.label(private.gui.fieldFrame, text='Description');
	private.gui.descriptionField := 
	    widgetset.entry(private.gui.fieldFrame, width=38, 
			    exportselection=T, disabled=T);
	popuphelp(private.gui.descriptionLabel,
		  hlp='A short description of the selection.',
		  txt='To change, type in the new description and hit "Enter" or "Return"',
		  combi=T);
	private.gui.field3Frame := 
	    widgetset.frame(private.gui.entryFrame, side='left', expand='x');
	private.gui.renamingLabel := 
	    widgetset.label(private.gui.field3Frame, text='   New name');
	private.gui.renamingEntry := 
	    widgetset.entry(private.gui.field3Frame, width=38,
			    exportselection=T, disabled=T);
	popuphelp(private.gui.renamingLabel,
		  hlp='A new name for the selection.',
		  txt='To have this name take effect, hit "Enter" or "Return"',
		  combi=T);
	private.gui.bottomFrame := 
	    widgetset.frame(private.gui.entryFrame, side='left');
	private.gui.buttonFrame := 
	    widgetset.frame(private.gui.bottomFrame, side='left');
	private.gui.spacer0 := 
	    widgetset.frame(private.gui.buttonFrame,height=2,
			    expand='x');
	private.gui.browseButton := 
	    widgetset.button(private.gui.buttonFrame, text='Browse', 
			     disabled=T, height=2, width=9);
	popuphelp(private.gui.browseButton,
		  hlp='Browse the selection.',
		  txt='This is only possible for working sets.',
		  combi=T);
	private.gui.deleteButton := 
	    widgetset.button(private.gui.buttonFrame, text='Delete', 
			     disabled=T, height=2, width=9);
	popuphelp(private.gui.deleteButton,
		  hlp='Remove the selection',
		  txt=paste('The variables are set to F.',
			    'If it is a working set, the underlying disk file is NOT deleted.'),
		  combi=T);
	private.gui.inspectButton := 
	    widgetset.button(private.gui.buttonFrame, text='Inspect',
			     disabled=T, height=2, width=9);
	popuphelp(private.gui.inspectButton,
		  hlp='Start the inspector on the selected glish variable.');

	private.gui.startInspector := function() {
	    wider private;
	    if (!is_boolean(private.selection)) {
		if (len(private.selection) == 1) {
		    junk := inspect (symbol_value(private.names[private.selection]),
				     private.names[private.selection]);
		}
	    }
	}

	private.gui.add := function(name) {
	    wider private;
	    private.gui.listbox->insert(name);
	    private.gui.listbox->see('end');
	}

	private.gui.delete := function(items) {
	    wider private;
	    if (len(items) > 0) {
		# sort this and delete in reverse order
		sorted := sort(items);
		for (i in len(sorted):1) {
		    private.gui.listbox->delete(as_string(items[i]-1));
		}
		private.gui.newselection();
	    }
	}


	private.gui.clearInfo := function() {
	    wider private;
	    private.gui.descriptionField->delete('start','end');
	    private.gui.descriptionField->disabled(T);
	    private.gui.inspectButton->disabled(T);
	    private.gui.renamingEntry->disabled(T);
	    private.gui.browseButton->disabled(T);
	    private.gui.deleteButton->disabled(T);
	    private.gui.inspectButton->disabled(T);
	}

	private.gui.setInfo := function(index) {
	    wider private;
	    private.gui.clearInfo();
	    private.gui.descriptionField->disabled(F);
	    private.gui.descriptionField->insert(private.descriptions[index]);
	    private.gui.inspectButton->disabled(F);
	    private.gui.renamingEntry->disabled(F);
	    private.gui.deleteButton->disabled(F);
	    if (private.types[index]=='SDITERATOR' || private.types[index]=='SDRECORD') {
		private.gui.browseButton->disabled(F);
	    }
	}
	
	private.gui.handleSelectEvent := function(indices) {
	    wider private;
	    if (is_integer(private.selection)) {
		if (len(private.selection) != len(indices) ||
		    private.selection != indices) {
		    # truely a new selection
		    private.selection := indices;
	            if (len(private.selection) < 1) private.selection := F;
		    private.gui.newselection();
		}
	    } else {
                private.selection := indices;
	        if (len(private.selection) < 1) private.selection := F;
                private.gui.newselection();
            }
	}

	private.gui.newselection := function(plotIt=T) {
	    wider private;
	    private.gui.listbox->clear('start','end');
	    if (!is_boolean(private.selection)) {
		if (len(private.selection) > 1) {
		    # multiple selection, only deletion is possible
		    private.gui.clearInfo();
		    private.gui.deleteButton->disabled(F);
		} else {
		    # single selection, fill in the info
		    index := private.selection;
		    private.gui.setInfo(index);
		    # if this is an SDRECORD, plot this selection
		    if (private.types[index] == 'SDRECORD' && is_function(private.recplotfn)) {
			name := private.names[index];
			value := symbol_value(name);
			private.lastViewed.name := name;
			private.lastViewed.value := value;
			private.lastViewed.description := private.descriptions[index];
			if (plotIt)
	                        junk := private.recplotfn(value, name);
		    }
		}
		for (i in private.selection)
		    private.gui.listbox->select(as_string(i-1));
	    } else {
		# otherwise no selections, clear the info
		private.gui.clearInfo();
	    }
	}

	private.gui.browseit := function() {
	    wider private;
	    # only called when the browser button is present, which only
	    # happens if it can be browsed
	    # which also can only happen if there is one and only one selection
	    private.browseit(private.names[private.selection],
			     private.types[private.selection]);
	}

	private.gui.rename := function(newname) {
	    wider private;
	    # Do not allow a rename to clobber an existing variable
	    if (is_defined(newname)) {
		notok := throw(paste('The new name \',',newname,'\', is already in use'),
			       origin='dishresman');
		return notok;
	    }
	    # only called when there is just one selection, rename it
	    lbindex := private.selection - 1;
	    lbindexAsString := as_string(lbindex);
	    oldName := private.gui.listbox->get(lbindexAsString);
	    # SDITERATORs need to be copied by reference
	    junk := F;
	    if (is_sditerator(symbol_value(oldName))) {
		junk := eval(paste(newname,':= ref ',oldName));
	    } else {
		junk := eval(paste(newname,' := ',oldName));
	    }
            if (is_fail(junk)) {
                return throw(paste(newname,'is an invalid name, unable to rename',oldName), 
			     origin='dish results manager');
            }
	    private.gui.listbox->delete(lbindexAsString);
	    private.gui.listbox->insert(newname, lbindexAsString);
	    private.gui.listbox->select(lbindexAsString);
	    private.gui.listbox->see(lbindexAsString);
	    junk := symbol_delete(oldName);
	    private.gui.renamingEntry->delete('start','end');
	    private.names[private.selection] := newname;
	    if (private.wscbcount > 0 && 
		private.types[private.selection] == 'SDITERATOR') {
		for (whichcb in 1:private.wscbcount) {
		    if (private.wscbs[whichcb].getentry() == 
			private.wscbs[whichcb].get(private.wsindices[whichcb][private.selection])) {
			private.wscbs[whichcb].insertentry(newname);
		    }
		    private.wscbs[whichcb].insert(newname,
						  private.wsindices[whichcb][private.selection]);
		    private.wscbs[whichcb].delete(private.wsindices[whichcb][private.selection]+1);
		    if (is_function(private.wscbcallbacks[whichcb])) { 
			private.wscbcallbacks[whichcb]('RENAME');
		    }
		}
	    }
	}

	private.gui.done := function() {
	    wider private;
	    # it may be desirable to explicitly delete other aspects
	    # here, such as the whenevers.
	    val private.gui.topFrame := F;
	    val private.gui := F;
	}


	# finally, the whenevers to tie it all together
	if (is_agent(watchedagent)) {
	    whenever watchedagent->["killed done"] do {
		private.gui.done();
	    }
	}

	whenever private.gui.inspectButton->press do {
	    private.gui.startInspector();
	}

	whenever private.gui.listbox->select do {
	    indices := $value + 1;
	    private.gui.handleSelectEvent(indices);
	}

	whenever private.gui.deleteButton->press do {
	    # delete the current selection
            bname:=public.getnames(private.selection);
	    for (i in 1:len(bname)) {
            if (any(field_names(private.browsers)==bname[i])) {
#                ok:=private.browsers[bname[i]].browser.dismiss();
                ok:=private.brdismissed(bname[i]);
            }
	    }
	    public.delete(private.selection);
	}

	whenever private.gui.browseButton->press do {
	    private.gui.browseit();
	}

	whenever private.gui.listbox->yscroll do {
	    private.gui.verticalSB->view($value);
	}

	whenever private.gui.verticalSB->scroll do {
	    private.gui.listbox->view($value);
	}

	whenever private.gui.descriptionField->return do {
	    # this can only happen where there is just one selection
	    newDescription := private.gui.descriptionField->get();
	    public.setdescription(private.selection, newDescription);
	    private.gui.descriptionField->foreground('red');
	}

	whenever private.gui.renamingEntry->return do {
	    # this can only happen when there is just one selection
	    private.gui.rename(private.gui.renamingEntry->get());
	}

	whenever private.gui.topFrame->killed do {
	    private.gui.done();
	}

	# finally, go through and add all of the current names
	if (private.count > 0) private.gui.add(private.names);
	# and select any that are already selected
	private.gui.newselection();

	return T;
    }

    const public.rename := function(newname) {
	wider private;
	ok:=private.gui.rename(newname);
	return T;
    }

    const public.nogui := function() {
	wider private;
	if (is_record(private.gui) && has_field(private.gui,'done')) {
	    private.gui.done();
	}
	val private.gui := F;
    }

    const public.done := function() {
	wider private;
	wider public;
	private.gui.done();
	val private := F;
	val public := F;
    }

#    const public.debug := function() { wider private; return private;}

    return ref public;
  
}
