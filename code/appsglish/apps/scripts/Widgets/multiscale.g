# multiscale.g: a widget for specifying one or more ranges, eg. a min and max.
# Copyright (C) 1998,1999,2000,2001
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
# $Id: multiscale.g,v 19.2 2004/08/25 02:16:59 cvsmgr Exp $

pragma include once;
 
include 'widgetserver.g';
include 'note.g';
 
multiscale := subsequence(parent, start=0.0, end=100.0, values=[50.0],
                          names=[''], helps="",
			  constrain=F, entry=F, extend=F,
                          length=110, resolution=unset,
                          orient='horizontal', width=15, 
			  font='', relief='flat', borderwidth=2,
			  foreground='black', background='lightgrey',
                          fill='both', widgetset=dws) {
    its := [=];
    its.parent := parent;
    its.lastvals := values;
    its.constrain := constrain;
    its.disabled := F;
    its.doentry := entry;
    its.ignore := F;
    its.resolution := resolution;      # Remember construction resolution

    # constrain must be False at the moment
    if (its.constrain) {
	return throw('Constraining not supported in multiscale yet');
    }

    # only one slider supported at the moment
    if (len(names) != 1) {
	return throw('Multiscale supports only single scales at present');
    }

    # parent must be an agent
    if (!is_agent(its.parent)) {
       return throw('Parent is not an agent', origin='multiscale.g');
    }

    # there must be a name for every value
    if (len(names) != len(values)) {
       return throw('Number of values and names must be equal', 
		    origin='multiscale.g');
    }

    # either no help, or help for each value
    if (len(helps) > 0 && len(helps) != len(names)) {
       return throw('Number of helps and names must be equal', 
		    origin='multiscale.g');
    }

    its.start := start;
    its.end := end;
    res := resolution;
    if (is_unset(res)) res := 1.0;
    junk := (its.end - its.start) / res;
    if (is_nan(junk)) {
	its.np := 1;
    } else {
	its.np := abs(junk);
    }
    #its.np := abs((its.end - its.start) / res);
    its.isinteger := is_integer(its.start) && is_integer(its.end);

    widgetset.tk_hold();
    if (orient=='horizontal') {
        its.myframe := widgetset.frame(its.parent, expand=fill, relief=relief,
                                       side='top');
        side := 'right';
    } else if (orient=='vertical') {
        its.myframe := widgetset.frame(its.parent, expand=fill, relief=relief,
                                       side='left');
        side := 'top';
    } else {
        return throw('Invalid side argument', origin='multiscale.g');
    }
    its.myframe->unmap();
    widgetset.tk_release();

    # whenever pusher
    its.whenevers := [];
    its.pushwhenever := function() {
	wider its;
	its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
    }

    # dismisser
    self.dismiss := function() {
	wider its;
	deactivate its.whenevers;
	its := [=];
    }

    # build the gui
    its.lwidth := max(strlen(names) + 1);
    its.scale := [=];
    for (i in 1:len(names)) {
	# frame
        its.frame[names[i]] := widgetset.frame(its.myframe, 
                                               side=side);
	# extend checkbox
        if (extend && its.doentry) {
	    its.extend[names[i]] := widgetset.label(its.frame[names[i]],
						    'extend-\nable',
						    font='small',
						    justify='center');
#	   its.extend[names[i]] := widgetset.button(its.frame[names[i]], 
#                                                    type='check', 
#						    text='Extend');
#           hlp := spaste('This occurs if you enter a value in the entry box\n',
#                         'that is beyond the current slider range');
#           widgetset.popuphelp(its.extend[names[i]], hlp, 
#                     'If checked, the scale range can extend', combi=T);
        }
	# scale
        its.scale[names[i]] := widgetset.scale(its.frame[names[i]],
                                                start=its.start,
                                                end=its.end, 
                                                value=values[i],
                                                length=length,
                                                text='', font='small',
                                                resolution=res,
                                                orient=orient, width=width, 
                                                borderwidth=borderwidth,
                                                fill=fill);
        its.scale[names[i]].scalenum := i;
	# entry
        if (its.doentry) {
           its.entry[names[i]] := widgetset.entry(its.frame[names[i]], 
                                                  width=10);
           its.entry[names[i]]['scalenum'] := i;
           its.space[names[i]] := widgetset.label(its.frame[names[i]], 
                                                  width=2, text='');
           t := its.entry[names[i]]->insert(spaste(values[i]));
           hlp := spaste('This will update the slider which determines\n',
                         'the actual value of the widget');
           widgetset.popuphelp(its.entry[names[i]], hlp, 
                               'Hit <CR> after entering a value in the entry box', 
                               combi=T);
        }
	# label
        its.label[names[i]] := widgetset.label(its.frame[names[i]],
                                                names[i], fill='none',
                                                width=its.lwidth);
        if (len(helps)>0) {
           widgetset.popuphelp(its.label[names[i]], helps[i]);
        }
    }

    its.values := values;

    # whenever control
    for (i in 1:len(names)) {
	#whenever its.scale[names[i]]->value do {
#	    ag := $agent;
#	    vl := $value;
#            idx := ag.scalenum;
#	    # keep scales in order if constrained
#	    if (its.constrain) {
#		num := idx + 1;
#		if (num <= len(names)) {
#		    if (vl > its.scale[names[num]]->value()) {
#			if (vl < its.end[num]) {
#			    t := its.scale[names[num]]->value(vl);
#			} else {
#			    t := its.scale[names[num]]->value(its.end[num]);
#			}
#		    }
#		}
#		num := idx - 1;
#		if (num >= 1) {
#		    if (vl < its.scale[names[num]]->value()) {
#			if (vl > its.start[num]) {
#			    t := its.scale[names[num]]->value(vl);
#			} else {
#			    t := its.scale[names[num]]->value(its.start[num]);
#			}
#		    }
#		}
#	    }
#	    t := self->values(self.getvalues());
#	    #its.values[idx] := vl;
#	    #t := self->values(its.values);
	#}
	
	whenever its.scale[names[i]]->value do {
	    ag := $agent;
	    vl := $value;
            idx := ag.scalenum;
            if (its.doentry && !its.ignore) {
		t := its.entry[names[idx]]->delete('start','end');
		t := its.entry[names[idx]]->insert(as_string(vl));
            }
	    if (!its.ignore) {
		#t := self->values(self.getvalues());
		newvals := self.getvalues();
		if (!all(((newvals + its.resolution/2) >= its.lastvals) &
			 ((newvals - its.resolution/2) <= its.lastvals))) {
		    self->values(newvals);		    
		} 		
		its.lastvals := newvals;
	    }
	    its.ignore := F;
	#}
	
	#whenever its.scale[names[i]]->value do {
	    #ag := $agent;
	    #vl := $value;
            #idx := ag.scalenum;
	    its.values[idx] := vl;
	}

	if (its.doentry) {
	    whenever its.entry[names[i]]->return do {
		ag := $agent;
		vl := as_double($value);
		idx := ag.scalenum;
		#res2 := ag->resolution();
		#np := abs(its.end - its.start)/res2;
		if (extend) {
#		    if (its.extend[names[idx]]->state()) {
			if (its.start <= its.end) {
			    if (vl < its.start) {
				if (its.constrain) {
				    for (xig in 1:len(values)) {
					#t := its.scale[names[xig]]->start(vl);
					its.start := vl;
				    }
				} else {
				    #t := its.scale[names[idx]]->start(vl);
				    its.start := vl;
				}
			    } else if (vl > its.end) {
				if (its.constrain) {
				    for (xig in 1:len(values)) {
					#t := its.scale[names[xig]]->end(vl);
					its.end := vl;
				    } 
				} else {
				    #t := its.scale[names[idx]]->end(vl);
				    its.end := vl;
				}
			    }
			} else {
			    if (vl > its.start) {
				if (its.constrain) {
				    for (xig in 1:len(values)) {
					#t := its.scale[names[xig]]->start(vl);
					its.start := vl;
				    } 
				} else {
				    #t := its.scale[names[idx]]->start(vl);
				    its.start := vl;
				}
			    } else if (vl < its.end) {
				if (its.constrain) {
				    for (xig in 1:len(values)) {
					#t := its.scale[names[xig]]->end(vl);
					its.end := vl;
				    } 
				} else {
				    #t := its.scale[names[idx]]->end(vl);
				    its.end := vl;
				}
			    }
			}
#		    }
		    #res2 := abs(its.end - its.start) / np;
		    #t := its.scale[names[idx]]->resolution(res2);             
		    self.setrange(its.start, its.end);
			#print 'calling setresolution';
		    #self.setresolution(res2);
		} else {
		    if (its.start<=its.end) {
			vl := min(vl, its.end);
			vl := max(vl, its.start);
		    } else {
			vl := min(vl, its.start);
			vl := max(vl, its.end);
		    }
		    t := ag->delete('start','end');
		    t := ag->insert(spaste(vl));
		}
		its.ignore := T;
		t := its.scale[names[idx]]->value(vl);
		#t := self->values(self.getvalues());
		newvals := self.getvalues();
		if (!all(((newvals + its.resolution/2) >= its.lastvals) &
			 ((newvals - its.resolution/2) <= its.lastvals))) {
		    self->values(newvals);
		}
		its.lastvals := newvals;
	    }
        }
    }
    its.myframe->map();

    const self.getvalues := function() {
	values := array(0, len(names));
	for (i in 1:len(names)) {
	    if (its.doentry) {
		values[i] := as_float(its.entry[names[i]]->get());
	    } else {
		values[i] := its.scale[names[i]]->value();
	    }
	}
	return values;
    }

    const self.setrange := function(start=unset, end=unset) {
	wider its;
        if (is_unset(start) && is_unset(end)) return T;
#
        if (!is_unset(start)) its.start := start;
	if (!is_unset(end)) its.end := end;
#
	its.isinteger := is_integer(its.start) && is_integer(its.end);

# Put back construction resolution

	res := its.resolution;
        if (is_unset(res)) {
   	   if (its.np > 0) {
	       res := abs((its.end - its.start) / its.np);
	   } else {
	       res := (its.end - its.start) / 100;
	   }
        }
	for (i in 1:len(names)) {
	    self.setresolution(res);
	    its.scale[names[i]]->start(start);
	    its.scale[names[i]]->end(end);
	    #t := its.scale[names[i]]->resolution(res);
	}
	
    }

    const self.setresolution := function(resolution=1.0) {
	for (i in 1:len(names)) {
	    if (its.isinteger) {
		its.scale[names[i]]->resolution(1);
	    } else {
		its.scale[names[i]]->resolution(resolution);
	    }
	}
	wider its;
	junk := (its.end - its.start) / resolution;
	if (is_nan(junk)) {
	    its.np := 0;
	} else {
	    its.np := abs(junk);
	}
	#its.np := abs((its.end - its.start) / resolution);
    }

    const self.setvalues := function(values) {
	wider its;
	if (len(values) != len(names)) {
	    return throw ('incorrect number of values given',
                          origin='multiscale.g');
	}
	if (!extend) {
	    values[values < its.start] := its.start;
	    values[values > its.end] := its.end;
	} else {
	    if (its.start < its.end) {
		newstart := min(values, its.start);
		newend := max(values, its.end);
	    } else {
		newstart := max(values, its.start);
		newend := min(values, its.end);
	    }
	    self.setrange(newstart, newend);
	}
	its.lastvals := values;
#	if (its.constrain) {
#	    for (i in 1:(len(names) - 1)) {
#		if (values[i] > values[i + 1]) {
#		    return throw ('values are not ordered', 
#				  origin='multiscale.g');
#		}
#	    }
#	}
	for (i in 1:len(names)) {
#
# Essential to make this request/reply or events
# get out of synch
#
	    its.ignore := T;
	    t := its.scale[names[i]]->value(values[i]);
	    if (its.doentry) {
		t := its.entry[names[i]]->delete('start', 'end');
		t := its.entry[names[i]]->insert(as_string(values[i]));
	    }
	    #t := self->values(self.getvalues());
	    its.ignore := F;
	}
        return T;
    }
    
    const self.disable := function () {
	wider its;
	if (!its.disabled) {   
	    its.myframe->disable();
	    its.disabled := T;
	}
        return T;
    }
    
    const self.enable := function () {
	wider its;
	if (its.disabled) {   
	    its.myframe->enable();
	    its.disabled := F;
	}
        return T;
    }
    
    const self.done := function () {
	wider its, self;
	val its := F;
	val self := F;
	return T;
    }
    
    ok := self.setvalues(values);
}
