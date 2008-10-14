# dishbaseline.g: the dish baseline fitting operation.
#------------------------------------------------------------------------------
#   Copyright (C) 1999,2000,2001,2002,2003
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
#    $Id: dishbaseline.g,v 19.1 2004/08/25 01:09:19 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include 'dishbaselinegui.g';
include 'sditerator.g';
include 'mathematics.g';
include 'note.g';

## TODO : use flag and weights appropriately!

const dishbaseline := function(ref itsdish)
{
    public := [=];
    private := [=];

    private.gui := F;
    private.ranges := [=];

    # state information, the following is always kept here, up to date,
    # regardless of the presence or absense of a GUI
    private.type := "polynomial";
    private.recalculate := T;
    private.action := "show";
    private.order := 1;

    private.rms := unset;
    private.converged := unset;
    private.iterations := unset;
    private.lastfit := unset;
    private.lastfitname := unset;

    # this state information is kept here, unless a GUI is present, in which
    # case the state in the GUI takes precedence
    private.ampSine := 1.0;
    private.perSine := 1.0;
    private.x0Sine := 0.0;
    private.maxIterSine := 10;
    private.criteriaSine := 0.001;
    private.rangeString := '';
    private.rangeState := [=];

    # 

    private.dish := itsdish;
    private.sdutil := F;
    private.polyfitter := F;
    private.sinusoidfitter := F;

    public.opmenuname := function() { return 'Baselines';}

    public.opfuncname := function() { return 'baseline';}

    public.gui := function(parent, widgetset=dws) {
	wider private;
	wider public;
	# don't build one if we already have one or there is no display
	if (!is_agent(private.gui) && widgetset.have_gui()) {
	    private.gui:=dishbaselinegui(parent,itsdish,widgetset);
	}
	whenever private.gui->done do {
	    val private.gui := F;
	}
	private.setGUIstate();
	return private.gui;
    }

    # dismiss the gui
    public.dismissgui := function() {
	wider private;
	if (is_agent(private.gui)) private.gui.done();
	private.gui := F;
	return T;
    }

    # return any state information as a record
    public.getstate := function() {
	wider public, private;
	state := [=];
	state.type := private.type;
	state.recalculate := private.recalculate;
	state.action := private.action;
	state.order := private.order;
	state.ampSine := private.getamplitude();
	state.perSine := private.getperiod();
	state.x0Sine := private.getx0();
	state.maxIterSine := private.getmaxiter();
	state.criteriaSine := private.getcriteria();
	state.rangeString := private.dish.plotter.ranges();
#	state.rangeState := private.getRangeState();
	state.rms := private.rms;
	state.converged := private.converged;
	state.iterations := private.iterations;
	state.lastfit := private.lastfit;
	state.lastfitname := private.lastfitname;
	return state;
    }

    # set the state from the indicated record
    # invoking this with an empty record should reset this to its
    # initial state
    public.setstate := function(state) {
	wider private;
	# set default values first
	private.type := "polynomial";
	private.recalculate := T;
	private.action := "show";
	private.order := 1;
	private.ampSine := 1.0;
	private.perSine := 1.0;
	private.x0Sine := 0.0;
	private.maxIterSine := 10;
	private.criteriaSine := 0.001;
	private.rangeString := '';
#	private.rangeState := [=];
	private.rms := unset;
	private.converged := unset;
	private.iterations := unset;
	private.lastfit := unset;
	private.lastfitname := unset;
	if (is_record(state)) {
	    if (has_field(state,'type')) {
		private.type := state.type;
	    }
	    if (has_field(state,'recalculate')) {
		private.recalculate := state.recalculate;
	    }
	    if (has_field(state,'action')) {
		private.action := state.action;
	    }
	    if (has_field(state,'order')) {
		private.order := state.order;
	    }
	    if (has_field(state,'ampSine')) {
		private.ampSine := state.ampSine;
	    }
	    if (has_field(state,'perSine')) {
		private.perSine := state.perSine;
	    }
	    if (has_field(state,'x0Sine')) {
		private.x0Sine := state.x0Sine;
	    }
	    if (has_field(state,'maxIterSine')) {
		private.maxIterSine := state.maxIterSine;
	    }
	    if (has_field(state,'criteriaSine')) {
		private.criteriaSine := state.criteriaSine;
	    }
	    if (has_field(state,'rangeString')) {
		private.rangeString := state.rangeString;
	    }
#	    if (has_field(state,'rangeState')) {
#		private.rangeState := state.rangeState;
#	    }
	    if (has_field(state, 'rms')) {
		private.rms := state.rms;
	    }
	    if (has_field(state, 'converged')) {
		private.converged := state.converged;
	    }
	    if (has_field(state, 'iterations')) {
		private.iterations := state.iterations;
	    }
	    if (has_field(state, 'lastfit') && is_sdrecord(state.lastfit)) {
		private.lastfit := state.lastfit;
	    }
	    if (has_field(state, 'lastfitname'))
		private.lastfitname := state.lastfitname;
	}
	private.setGUIstate();
	return T;
    }

    # done with this closure, this makes it impossible to use the public
    # part of this after invoking this function
    public.done := function() {
	wider private;
	wider public;
	public.dismissgui();
	val private := [=];
	val public := F;
	return T;
    }

    private.append := function (ref list, thing)
    {
	# appends thing to list
	for (i in 1:len (thing)) {
	    list[len (list)+i] := thing;
	}
    }

    public.apply := function(lv=F,outf=F,autoplot=T) {
	wider private;
        if (is_boolean(lv)) {
	   if (private.dish.doselect()) {
                if (private.dish.rm().selectionsize()==1) {
                        lv := private.dish.rm().getselectionvalues();
 			nominee := ref lv;
#			nname := lv.name;
                        nname:=private.dish.rm().getselectionnames();
                } else {
                        return throw('did not work');
                }
	   } else {
		lv := private.dish.rm().getlastviewed();
		nominee := ref lv.value;
		name := lv.name;
	   }
        } else {
		nominee := ref lv;
                nname:='temp';
        }
# temp just to make things easy
	__sdtemp__ := nominee;
	if (is_boolean (nominee)) {
	    private.dish.message ('Error!  An SDRecord has not yet been viewed');
	} else if (is_sdrecord (nominee)) {
#	    type := F;
	    if (!private.recalculate && is_boolean (private.lastfit)) {
		private.dish.message ('No previous baseline available, you must select "Recalculate"');
		return;
	    }
	    if (private.recalculate) {
		arg := F;
		cranges := private.getrangestring('channels');
		# when NOT invoked via the apply button, need to update
		# the range box entry stuff
		rmsoffit := F;
		guess := [=];

		if (private.type == 'polynomial') {
		    rmsoffit := public.polynomial (nominee, private.order, 
						   cranges, F, newFit);
		    arg := spaste(private.order,',',cranges,',',F,',');
		} else if (private.type == 'sinusoid') {
		    state := [=];
		    state.amplitude := private.ampSine;
		    state.period := private.perSine;
		    state.x0 := private.x0Sine;

		    state.maxiter := private.maxIterSine;
		    state.criteria := private.criteriaSine;
		    guess := state;
		    rmsoffit := public.sinusoidal (nominee, state, cranges,
						   F, newFit);
		    if (!is_fail (rmsoffit)) {
			# preserve this, in case we need to change it
			thestate := state;

			# update the state information
			if (has_field(state,'amplitude')) {
			    public.setamplitude(state.amplitude);
			}
			if (has_field(state,'x0')) {
			    public.setx0(state.x0);
			}
			if (has_field(state,'period')) {
			    public.setperiod(state.period);
			}
			if (has_field(state,'maxiter')) {
			    public.setmaxiter(state.maxiter);
			}
			if (has_field(state,'criteria')) {
			    public.setcriteria(state.criteria);
			}
			if (has_field(state,'converged')) {
			    private.converged := state.converged;
			}
			if (has_field(state,'curriter')) {
			    private.iterations := state.curriter;
			}
			if (is_agent(private.gui)) {
			    private.gui.setconverged(private.converged);
			    private.gui.setiterations(private.iterations);
			}
		    }
		    arg := spaste(guess, ',', cranges, ',', F,',');
		} else {
		    private.dish.message(paste('Internal error:',
		    'Unrecognized baseline type - this should never happen'));
		}	       
		if (is_fail (rmsoffit)) {
		    private.dish.message ('Fit failed');
		    return;
		}
		private.rms := rmsoffit;
		if (is_agent(private.gui))
		    private.gui.setrms(private.rms);
		# insert this into the results manager
		# set the history line
		hist := spaste ('rmsoffit := ', cmd, '(', nname, ',', arg, 
				' this)');
		private.append (newFit.hist, hist);
		private.lastfit := newFit;
		resultDescription := spaste(private.type,' fit to data.');
		if (len (split (cranges)) == 0) {
		    cranges := "Entire X axis";
		}
		if (private.type == "polynomial") {
		    resultDescription := spaste (resultDescription, 
						 ' order = ', private.order,
						 ' range = ', cranges);
		} else {
		    resultDescription := spaste (resultDescription, 
						 ' state = ', state,
						 ' range = ', cranges);
		}
		if (autoplot==T) {
		resultName := private.dish.rm().add ('baseline',
						     resultDescription, newFit,
						     'SDRECORD');
		} else {
		resultName := newFit
		};
		private.lastfitname := resultName;

		private.dish.message (resultDescription);
	    }
	    # do things which are not dependent on a recalculation here
	    if (is_unset(private.lastfit)) {
		private.dish.message ('No baseline available for use.');
		return F;
	    }
	    if (private.action == 'show') {
		# just overlay the last fit, do NOT set focus to this result
		if (autoplot==T) {
		private.dish.plotter.plotrec(private.lastfit,overlay=T);
		} else {
		return private.lastfit;
		};
	    } else {
		# subtract - what to do if the following isn't true?
		if (len (private.lastfit.data.arr) != len (nominee.data.arr) ||
		    private.lastfit.data.arr::shape != nominee.data.arr::shape) 		{
		    private.dish.message ('Most recent baseline has difference shape from current data.');
		    return F;
		}
		nominee.data.arr -:= private.lastfit.data.arr;
		hist:=spaste(nname,'.data.arr -:= ',private.lastfitname,
			'.data.arr');
		private.append (nominee.hist, hist);
		resultDescription := spaste (private.lastfitname,
					     ' subtracted from data.');
		if (autoplot==F) {
			return nominee;
		} else {
		resultName := private.dish.rm().add ('blsub', resultDescription,
						     nominee, 'SDRECORD');
		# show the result and set current focus to it this should always
		# be at the 'end', this should automatically view it
		private.dish.rm().select('end');
		private.dish.message('The baseline has been subtracted from the data');
		}; #end cli conditional
	    }
	# sditerator enabled
        } else if (is_sditerator(__sdtemp__)) {
  	    sdlength:=__sdtemp__.length();
            ok:=__sdtemp__.setlocation(1);
            if (is_boolean(outf)) {
           	ok:=private.dish.open(spaste(nname,'_fn'),new=T);
            } else {
               	ok:=private.dish.open(outf,new=T);
            }
            if (is_fail(ok))
            return throw('Error: Couldnt create working set');
	    for (i in 1:sdlength) {
		ok:=__sdtemp__.setlocation(i);
		global __tempsdrec__ := __sdtemp__.get();
                if (!private.recalculate && is_boolean (private.lastfit)) {
                   private.dish.message ('No previous baseline available, you must select "Recalculate"');
                   return;
            	}
                if (private.recalculate) {
                   cmd := spaste('dish.ops().baseline.',private.type);
                   arg := F;
                   cranges := private.getrangestring('channels');
                   # when NOT invoked via the apply button, need to update
                   # the range box entry stuff
                   rmsoffit := F;
                   guess := [=];

                   if (private.type == 'polynomial') {
                       rmsoffit:=public.polynomial(__tempsdrec__,private.order,
                                                   cranges, F, newFit);
                       arg := spaste(private.order,',',cranges,',',F,',');
                   } else if (private.type == 'sinusoid') {
                       state := [=];
                       state.amplitude := private.ampSine;
                       state.period := private.perSine;
                       state.x0 := private.x0Sine;
                       state.maxiter := private.maxIterSine;
                       state.criteria := private.criteriaSine;
                       guess := state;
                       rmsoffit:=public.sinusoidal(__tempsdrec__,state,cranges,
                                                   F, newFit);
                       if (!is_fail (rmsoffit)) {
                           # preserve this, in case we need to change it
                           thestate := state;
                           # update the state information
                           if (has_field(state,'amplitude')) {
                               public.setamplitude(state.amplitude);
                           }
                           if (has_field(state,'x0')) {
                               public.setx0(state.x0);
                           }
                           if (has_field(state,'period')) {
                               public.setperiod(state.period);
                           }
                           if (has_field(state,'maxiter')) {
                               public.setmaxiter(state.maxiter);
                           }
                           if (has_field(state,'criteria')) {
                            public.setcriteria(state.criteria);
                           }
                           if (has_field(state,'converged')) {
                               private.converged := state.converged;
                           }
                           if (has_field(state,'curriter')) {
                               private.iterations := state.curriter;
                           }
                           if (is_agent(private.gui)) {
                               private.gui.setconverged(private.converged);
                               private.gui.setiterations(private.iterations);
                           }
                       }
                       arg := spaste(guess, ',', cranges, ',', F,',');
                } else {
                    private.dish.message(paste('Internal error:',
                    'Unrecognized baseline type - this should never happen'));
                } # end baseline type loop (poly,sin);
                if (is_fail(rmsoffit)) {
                    private.dish.message ('Fit failed');
                    return;
                }
                private.rms := rmsoffit;
                if (is_agent(private.gui))
                    private.gui.setrms(private.rms);
                # insert this into the results manager
                # set the history line
                hist := spaste ('rmsoffit := ', cmd, '(', nname, ',', arg,
                                ' this)');
                private.append (newFit.hist, hist);
                private.lastfit := newFit;
                resultDescription := spaste(private.type,' fit to data.');
                if (len (split (cranges)) == 0) {
                    cranges := "Entire X axis";
                }
                if (private.type == "polynomial") {
                    resultDescription := spaste (resultDescription,
                                                 ' order = ', private.order,
                                                 ' range = ', cranges);
                } else {
                    resultDescription := spaste (resultDescription,
                                                 ' state = ', state,
                                                 ' range = ', cranges);
                }
#                resultName := private.dish.rm().add ('baseline',
#                                                     resultDescription, newFit,
#                                                     'SDRECORD');
#                private.lastfitname := resultName;

                private.dish.message (resultDescription);
            }
            # do things which are not dependent on a recalculation here
            if (is_unset(private.lastfit)) {
                private.dish.message ('No baseline available for use.');
                return F;
            }
            if (private.action == 'show') {
                # just overlay the last fit, do NOT set focus to this result
                private.dish.view_sdrec (private.lastfit, private.lastfitname,
                            overlay=T, refocus=F, frombase=T);
            } else {
                # subtract - what to do if the following isn't true?
                if (len (private.lastfit.data.arr) != len (__tempsdrec__.data.arr) ||
                    private.lastfit.data.arr::shape != __tempsdrec__.data.arr::shape)                 {
                    private.dish.message ('Most recent baseline has difference shape from current data.');
                    return F;
                }
                __tempsdrec__.data.arr -:= private.lastfit.data.arr;
                hist:=spaste(nname,'.data.arr -:= ',private.lastfitname,
                        '.data.arr');
                private.append (__tempsdrec__.hist, hist);
                resultDescription := spaste (private.lastfitname,
                                             ' subtracted from data.');
                private.dish.rm().select('end');
		rmlen:=private.dish.rm().size();
		ok:=private.dish.ops().save.setws(private.dish.rm().getnames(rmlen));
		ok:=private.dish.ops().save.apply(__tempsdrec__);
#               resultName := private.dish.rm().add ('blsub', resultDescription,
#                                                     nominee, 'SDRECORD');
                # show the result and set current focus to it this should always
                # be at the 'end', this should automatically view it
                private.dish.message('The baseline has been subtracted from the data');
            }
	  } # end loop over sditerator
	} else {
	    private.dish.message ('Baseline fitting is not supported on the current selection in the results manager');
	}

	# the prod statistics stuff which happens via the GUI apply, needs
	# to really be here!
	return T;
    }

### temp marker to let me know to stop here for apply function

    private.setGUIstate := function() {
	wider private;
	# force the GUI state to agree with the state here
	# this is used only on GUI startup and in setstate
	if (is_agent(private.gui)) {
	    private.gui.settype(private.type);
	    private.gui.recalculate(private.recalculate);
	    private.gui.setaction(private.action);
	    private.gui.setorder(private.order);
	    private.gui.setamplitude(private.ampSine);
	    private.gui.setperiod(private.perSine);
	    private.gui.setx0(private.x0Sine);
	    private.gui.setmaxiter(private.maxIterSine);
	    private.gui.setcriteria(private.criteriaSine);
	    private.gui.setrange(private.rangeString);
#	    private.gui.setRangeState(private.rangeState);
	    private.gui.setrms(private.rms);
	    private.gui.setconverged(private.converged);
	    private.gui.setiterations(private.iterations);
	}
    }

    public.settype := function(type, updateGUI=T) {
	wider private;
	if (!is_string(type) || (type !="polynomial" && type != "sinusoid")) {
	    fail(spaste('dish.ops().baseline.settype(type): invalid type - ',
			type));
	}
	private.type := type;
	if (updateGUI && is_agent(private.gui)) private.gui.settype(type);
	return T;
    }

#    public.gettype := function() {
#	wider private; return private.type;
#    }
	
    public.setaction := function(action, updateGUI=T) {
	wider private;
	if (!is_string(action) || (action !="show" & action != "subtract")) {
	    fail(spaste('dish.ops().baseline.setaction(action): invalid action - ',
			action));
	}
	private.action := action;
	if (updateGUI && is_agent(private.gui)) private.gui.setaction(action);
	return T;
    }

     public.getaction := function() {
 	wider private; return private.action;
     }
	

    public.setorder := function(order, updateGUI=T) {
	wider private;
	order := as_integer(order);
#	if (order < 0 || order > 8) {
#	    fail(spaste('dish.ops().baseline.setorder(order): invalid order - ',
#			order));
#	}
       if (order < 0) {
           fail(spaste('dish.ops().baseline.setorder(order): invalid order - ',
                       order));
       }
	private.order := order;
	if (updateGUI && is_agent(private.gui)) private.gui.setorder(order);
	return T;
    }

#    public.getorder := function() {
#	wider private; return private.order;
#    }
	
    public.recalculate := function(torf, updateGUI=T) {
	wider private;
	if (!is_boolean(torf)) {
	    fail('dish.ops().baseline.settype(type): torf is not boolean');
	}
	private.recalculate := torf;
	if (updateGUI && is_agent(private.gui)) private.gui.recalculate(torf);
	return T;
    }

#    public.dorecalculate := function() {
#	wider private;
#	return private.recalculate;
#    }

    public.setamplitude := function(amplitude, updateGUI=T) {
	wider private;
	private.ampSine := as_double(amplitude);
	if (updateGUI && is_agent(private.gui)) 
	    private.gui.setamplitude(private.ampSine);
	return T;
    }

    private.getamplitude := function() {
	wider private;
	result := private.ampSine;
	if (is_agent(private.gui)) result := private.gui.getamplitude();
	return result;
    }

    public.setperiod := function(period, updateGUI=T) {
	wider private;
	private.perSine := as_double(period);
	if (updateGUI && is_agent(private.gui)) 
	    private.gui.setperiod(private.perSine);
	return T;
    }

    private.getperiod := function() {
	wider private;
	result := private.perSine;
	if (is_agent(private.gui)) result := private.gui.getperiod();
	return result;
    }

    public.setx0 := function(x0, updateGUI=T) {
	wider private;
	private.x0Sine := as_double(x0);
	if (updateGUI && is_agent(private.gui)) 
	    private.gui.setx0(private.x0Sine);
	return T;
    }

    private.getx0 := function() {
	wider private;
	result := private.x0Sine;
	if (is_agent(private.gui)) result := private.gui.getx0();
	return result;
    }

    public.setmaxiter := function(maxiter, updateGUI=T) {
	wider private;
	private.maxIterSine := as_integer(maxiter);
	if (updateGUI && is_agent(private.gui)) 
	    private.gui.setmaxiter(private.maxIterSine);
	return T;
    }

    private.getmaxiter := function() {
	wider private;
	result := private.maxIterSine;
	if (is_agent(private.gui)) result := private.gui.getmaxiter();
	return result;
    }

    public.setcriteria := function(criteria, updateGUI=T) {
	wider private;
	private.criteriaSine := as_double(criteria);
	if (updateGUI && is_agent(private.gui)) 
	    private.gui.setcriteria(private.criteriaSine);
	return T;
    }

    private.getcriteria := function() {
	wider private;
	result := private.criteriaSine;
	if (is_agent(private.gui)) result := private.gui.getcriteria();
	return result;
    }

    # return the desc record of the last viewed record or
    # one which guarantees no difference between pixel and channel units
    private.getdesc := function() {
	desc := [=];
	lv := ref private.dish.rm().getlastviewed();
	nominee := ref lv.value;
	if (is_sdrecord(nominee)) {
           desc.crval:=nominee.data.desc.chan_freq.value[1];
           crval2:=nominee.data.desc.chan_freq.value[2];
           if (desc.crval>crval2) {
               desc.cdelt:=(-1)*nominee.data.desc.chan_width;
           } else {
               desc.cdelt:=nominee.data.desc.chan_width;
           }
           desc.crpix:=1;
	} else {
	    # the default one
	    desc.crval := 0.0;
	    desc.crpix := 0.0;
	    desc.cdelt := 1.0;
	}
	return desc;
    }

    # ranges is just a set of values to be converted, the converted value
    # is returned, the conversion is from itsunit to tounit
    private.rangesToUnit := function(newranges, itsunit='xaxis',
		tounit='channels', desc=unset) {
	wider private;
	if (len(newranges::shape)<2) return F;
	chan:=array(0,2,newranges::shape[2]);
	xvec:=private.dish.plotter.ips.getcurrentabcissa();
	result := newranges;
	for (i in 1:result::shape[2]) {
		xmin:=min(result[,i]);
		xmax:=max(result[,i]);
		chan[1,i]:=min(seq(xvec)[xvec>=xmin & xvec<=xmax]);
		chan[2,i]:=max(seq(xvec)[xvec>=xmin & xvec<=xmax]);
	}
	result:=chan;
#	if (itsunit != tounit) {
#	    if (is_unset(desc)) desc := private.getdesc();	    
#	    if (tounit == "channels") {
#		# convert from xaxis units to channels
#		result := (result - desc.crval)/desc.cdelt + desc.crpix;
#	    } else {
#		# convert from channels to xaxis units
#		result := (result - desc.crpix)*desc.cdelt + desc.crval;
#	    }
#	}
	return result;
    }

    # convert a range matrix to a string representation
    private.rangesToString := function(newranges) {
	result := '';
	if (has_field(newranges::,"shape") && 
	    len(newranges::shape) == 2 && newranges::shape[2] > 0) {
	    newranges::print.precision := 8;
	    for (i in 1:newranges::shape[2]) {
		if (i != 1) {
		    result := spaste(result,' ');
		}
		if (newranges[1,i] == newranges[2,i]) {
		    result := spaste(result,as_string(newranges[1,i]));
		} else {
		    result := spaste(result, '[',as_string(newranges[1,i]),':',
				     as_string(newranges[2,i]),']');
		}
	    }
	}
	return result;
    }

    # convert a string representation to a range matrix
    private.rangesToMatrix := function(rangeString) {
	wider private;
	# default null value
	result := as_double([]);
	result::shape := [0,0];
	if (strlen(rangeString) > 0) {
	    if (is_boolean(private.sdutil)) private.sdutil := sdutil();
	    result := private.sdutil.parseranges(rangeString);
	}
	return result;
    }

    # set the ranges using the specified matrix of ranges
    # The units argument specifies the units of the ranges used here, if
    # it is unset, the current units are assumed.
    # If changeunits is T and the current units are != the units argument
    # here, then the units in this operation will be changed as a result of
    # this operation.
    # If updateGUI is T, then the GUI is updated, else it isn't (this should
    # only be done by the GUI itself to avoid recursive actions between this
    # function and the GUI).
    public.setrange := function(newrange, units=unset, changeunits=T,
				 updateGUI=T) {
	wider private, public;
	itsunits:=units;
	if (is_string(newrange)) {
		newrange:=private.rangesToMatrix(newrange);
	}
	rangeString := private.rangesToString(newrange);
	private.rangeString := rangeString;
	if (updateGUI && is_agent(private.gui)) {
	    private.gui.setrange(private.rangeString);
	}
	return T;
    }

    # Get the current ranges as a string in the specified units
    private.getrangestring := function(units=unset) {
	wider private, public;
	result := private.dish.plotter.ranges();
	if (result=='') return result;
	# get ranges as a matrix
        result := private.rangesToMatrix(result);
	# convert to channels
        if (len(result::shape)<2) return F;
        chan:=array(0,2,result::shape[2]);
        xvec:=private.dish.plotter.ips.getcurrentabcissa();
        for (i in 1:result::shape[2]) {
                xmin:=min(result[,i]);
                xmax:=max(result[,i]);
                chan[1,i]:=min(seq(xvec)[xvec>=xmin & xvec<=xmax]);
                chan[2,i]:=max(seq(xvec)[xvec>=xmin & xvec<=xmax]);
        }
        result:=chan;
	result := private.rangesToString(result);
	return result;
    }

    #
  const private.draw_indexed_rectangle := function (index)
  {
    wider private,public;

    if (!self.ranges[index]) {
      fail spaste ("Invalid index:", index);
    }
    oldLineStyle := private.dish.plotter.qls();
    private.dish.plotter.sls(1);
    self.draw_rectangle ([self.ranges[index][1], self.ranges[index][2],
                          self.ranges[index][3] - self.ranges[index][4],
                          self.ranges[index][3] + self.ranges[index][4]]);
    private.dish.plotter.sls(oldLineStyle);
    return T;
  };

const private.draw_rectangle := function (coords)
  {
        wider private;
    private.dish.plottersfs(2);
    private.dish.plotter.rect(coords[1], coords[2], coords[3], coords[4]);

    return T;
  }



    # range manipulation functions
    # takes a Matrix of ranges [2,nranges] and orders them,
    # eliminating overlap and duplication
    private.orderRange := function(rmat) {
	if (len(rmat[1,]) < 2) return rmat;

	ord := order(rmat[1,]);
	mask := array(T,len(ord));

	for (i in len(ord):2) {
	    if (rmat[1,ord[i-1]] == rmat[1,ord[i]]) {
		mask[ord[i]] := F;
		rmat[2,ord[i-1]] := max(rmat[2,ord[[i-1]:i]]);
	    }
	}

	if (sum(mask) < 2) return rmat[,ord[mask]];

	ord := ord[mask];
	mask := array(T,len(ord));

	for (i in len(ord):2) {
	    if (rmat[2,ord[i-1]] >= rmat[1,ord[i]]) {
		mask[ord[i]] := F;
		rmat[1,ord[i-1]] := min(rmat[1,ord[[i-1]:i]]);
		rmat[2,ord[i-1]] := max(rmat[2,ord[[i-1]:i]]);
	    }
	}

	if (sum(mask) < 2) return rmat[,ord[mask]];

	# and similarly for the max side
	rmat := rmat[,ord[mask]];
	ord := order(rmat[2,]);
	mask := array(T,len(ord));

	for (i in len(ord):2) {
	    if (rmat[2,ord[i-1]] == rmat[2,ord[i]]) {
		mask[ord[i]] := F;
		rmat[1,ord[i-1]] := min(rmat[1,ord[[i-1]:i]]);
	    }
	}

	if (sum(mask) < 2) return rmat[,ord[mask]];

	ord := ord[mask];
	mask := array(T,len(ord));

	for (i in len(ord):2) {
	    if (rmat[2,ord[i-1]] >= rmat[1,ord[i]]) {
		mask[ord[i]] := F;
		rmat[1,ord[i-1]] := min(rmat[1,ord[[i-1]:i]]);
		rmat[2,ord[i-1]] := max(rmat[2,ord[[i-1]:i]]);
	    }
	}
	return rmat[,ord[mask]];
    }
    
    # converts a Matrix of ranges [2,nranges] [1,n] := min; [2,n] := max
    # the units expected here are channel numbers
    private.maskFromRanges := function(rmat)
    {
	wider private;
	m := F;
	# round to nearest integer
	rmat := as_integer(rmat+0.5);
	rmat := private.orderRange(rmat);
	# watch for the range going below a certain size and the shape
	# getting too small
	if (len(rmat)==2) rmat::shape := [2,1];
	for (i in 1:rmat::shape[2]) {
	    if (i == 1) {
		curr := 0;
	    } else {
		curr := len(m);
	    }
	    new := rmat[2,i]-rmat[1,i]+1;
	    m[(curr+1):(curr+new)] := rmat[1,i]:rmat[2,i];
	}
	return m;
    }

    # the functions which actually do the fitting

    # returns rms of initial values wrt fit over the given ranges
    # ranges is a string containing the ranges to use in the fit
    # result is a valid sdrec (uses initial sdrec with data.arr replaced
    # by result of fit, name changed to 'POLYNOMIAL FIT')
    public.polynomial := function(sdrec, order, cranges, rangesAreXValues, ref result)
    {
	wider private;
	if (!is_sdrecord(sdrec)) fail('The input data is not an sdrecord.');
	if (!is_integer(order)) fail('order is not an integer');
	if (!is_string(cranges)) fail('cranges is not a string');

	if (is_boolean(private.polyfitter)) private.polyfitter := polyfitter();
	if (is_boolean(private.sdutil)) private.sdutil := sdutil();

	if (len(split(cranges)) == 0) {
	    rmat := 1:sdrec.data.arr::shape[2];
	} else {
	    # first, convert the ranges to a matrix
	    rmat := private.rangesToMatrix(cranges);
	    if (is_fail(rmat)) fail;

	    # then convert them to channel numbers if necessary
	    if (rangesAreXValues) {
		rmat := private.rangesToUnit(rmat, 'xaxis', 'channels',
					     sdrec.data.desc);
		if (sdrec.data.desc.cdelt < 0) {
		    # ranges are now out of order, reorder
		    rtmp := rmat[2,];
		    rmat[2,] := rmat[1,];
		    rmat[1,] := rtmp;
		}
	    }

	    # only use the ones >1 and < number of channels
	    rmat[rmat < 1] := 1;
	    rmat[rmat > sdrec.data.arr::shape[2]] := sdrec.data.arr::shape[2];

	    # then turn them into a mask of channel values
	    rmat := private.maskFromRanges(rmat);
	    #get the flags relevant to the selected region
	    myfl := sdrec.data.flag[rmat];
 	    #mask out bits of the region which are flagged bad
	    rmat := rmat[!myfl];
	}
	# make sure that there are enough points for the selected order
	if (len(rmat) <= order) fail(paste('Not enough points for desired order polynomial'));

	# set things up to accept the fit
	val result := sdrec;
	val result.header.source_name := 'POLYNOMIAL FIT';
	fullx := [1:result.data.arr::shape[2]];
	# diffs is used to hold the differences so that a std deviation can be
	# determined for all the data used here - might be better to return 
	# stddev for each pol. fit
	diffs := as_float([]);
	# fit each available polarization
	for (i in 1:sdrec.data.arr::shape[1]) {
	    # flags are T if the data has been flagged - we won't use those points
	    flags := !sdrec.data.flag[i,rmat];
	    thisy := (sdrec.data.arr[i,rmat])[flags];
	    thisx := rmat[flags];
	    # check that there are enough points for the desired order
	    if (len(thisx)>order) {
		# fit this polarization - no sigmas or weights used here yet
		ok := private.polyfitter.fit(coeff,coefferrs,chisq,thisx,thisy,order=order);
		# I don't think this can ever fail, but what the heck
		if (!ok) fail(paste('Polnomial fit failed'));
		# evaluate this polynomial over all x and put into result
		if (!private.polyfitter.eval(y=result.data.arr[i,],x=fullx,coeff=coeff)) {
		    fail(paste('Polynomial evaluation of fit failed'));
		}
		# accumulate the differences
		ndiff := len(diffs);
		diffs[(ndiff+1):(ndiff+len(thisx))] := (thisy - (result.data.arr[i,rmat])[flags]);
	    } else {
		# everything is flagged, nothing to fit to here
		note(paste('Not enough unflagged points for desired order polynomial for polarization = ',
			   sdrec.data.desc.corr_type[i]),priority='WARN',origin='dishbaseline.polynomial');
		# just put zeros in the result here
		result.data.arr[i,] := array(0.0,sdrec.data.arr::shape[2]);
	    }
	}
	totstddev := 0.0;
	if (len(diffs)>0) totstddev := stddev(diffs);
	return totstddev;
    }

    # returns rms of initial values wrt fit over the given ranges
    # state is the state of the sinusoid fitter, it is used at
    # invocation to set the initial guesses and other controlling
    # parameters and at conclusion to return the current state
    # of the fitter.
    # ranges is a string containing the ranges to use in the fit
    # result is a valid sdrec (uses initial sdrec with data.arr replaced
    # by result of fit, name changed to "SINUSOIDAL FIT"
    public.sinusoidal := function(sdrec, ref state, cranges, rangesAreXValues, ref result)
    {
	wider private;
	if (!is_sdrecord(sdrec)) fail('The input data is not an sdrecord.');
	if (!is_record(state)) fail('state is not a record');
	if (!is_string(cranges)) fail('cranges is not a string');

	if (is_boolean(private.sinusoidfitter)) private.sinusoidfitter := sinusoidfitter();
	if (is_boolean(private.sdutil)) private.sdutil := sdutil();

	if (len(split(cranges)) == 0) {
	    rmat := 1:sdrec.data.arr::shape[2];
	} else {
	    # first, convert the ranges to a matrix
	    rmat := private.rangesToMatrix(cranges);
	    if (is_fail(rmat)) fail;

	    # then convert them to channel numbers if necessary
	    if (rangesAreXValues) {
		rmat := private.rangesToUnit(rmat, 'xaxis', 'channels',
					     sdrec.data.desc);
		if (sdrec.data.desc.cdelt < 0) {
		    # ranges are now out of order, reorder
		    rtmp := rmat[2,];
		    rmat[2,] := rmat[1,];
		    rmat[1,] := rtmp;
		}
	    }

	    # only use the ones >1 and < number of channels
	    rmat[rmat < 1] := 1;
	    rmat[rmat > sdrec.data.arr::shape[2]] := sdrec.data.arr::shape[2];

	    # then turn them into a mask of channel values
	    rmat := private.maskFromRanges(rmat);
            #get the flags relevant to the selected region
            myfl := sdrec.data.flag[rmat];
            #mask out bits of the region which are flagged bad
            rmat := rmat[!myfl];
	}
	# make sure that there are enough points to fit the 3 parameters
	if (len(rmat) <= 3) fail(paste('Not enough points to fit a sinusoid'));

	# set things up to accept the fit
	val result := sdrec;
	val result.header.source_name := "SINUSOIDAL FIT";
	# diffs is used to hold the differences so that a std deviation can be
	# determined for all the data used here - might be better to return
	# stddev for each pol. fit
	diffs := as_float([]);
	# prepare the covariance in state to hold the correct shape 
	# 3x3 matrix for each polarization
	state.covariance := array(0.0,sdrec.data.arr::shape[1],3,3);
	fullx := [1:result.data.arr::shape[2]];
	# fit each available polarization
	for (i in 1:sdrec.data.arr::shape[1]) {
	    # flags are T if the data has been flagged - we won't use those points
	    flags := !sdrec.data.flag[i,rmat];
	    thisy := (sdrec.data.arr[i,rmat])[flags];
	    thisx := rmat[flags];
	    # check that there are enough points
	    if (len(thisx)>3) {
		# okay to fit
		# remove the mean before actually fitting the data
		thismean := mean(thisy);
		thisy -:= thismean;
		# state may contain multiple components, use as needed
		# if only one, assume it applies to all
		for (field in field_names(state)) {
		    # covariance is the one state value which is a matrix
		    # for each fit.  It is not used here, just returned by
		    # the fitter, but watch for it here so that an error is
		    # not generated.
		    if (field != 'covariance') {
			singleState[field] := state[field][min(i,len(state[field]))];
		    } 
		}
		ok := private.sinusoidfitter.setstate(singleState);
		# and do the fit
		ok := private.sinusoidfitter.fit(singleState, x=thisx, y=thisy);
		if (!ok) fail(paste('Sinusoidal fit failed for polarization = ',
			      sdrec.data.desc.corr_type[i]));  
		for (field in field_names(singleState)) {
		    if (field != 'covariance') {
			state[field][i] := singleState[field];
		    } else {
			state.covariance[i,,] := singleState.covariance;
		    }
		}
		# evaluate the fit
		if (!private.sinusoidfitter.eval(y=newy,x=fullx)) {
		    fail(paste('Sinusoidal evaluation of fit failed for polarization = ',
			       sdrec.data.desc.corr_type[i]));  
		}
		result.data.arr[i,] := newy + thismean;
		# accumulate the differences
		ndiff := len(diffs);
		diffs[(ndiff+1):(ndiff+len(thisx))] := (thisy - (newy[rmat])[flags]);
	    } else {
		# everything is flagged, nothing to fit to here
		note(paste('Not enough unflagged points for sinusoidal fit for polarization = ',
			   sdrec.data.desc.corr_type[i]),
		     priority='WARN',origin='dishbaseline.sinusoidal');
		# just put zeros in the result here
		result.data.arr[i,] := array(0.0,len(fullx));
	    }
	}
	totstddev := 0.0;
	if (len(diffs)>0) totstddev := stddev(diffs);
	return totstddev;
    }

##base       Description: Performs a polynomial baseline fit to a scan
##           Example:     mybl := base(order=2,action='subtract',
##                              range='[50:400][1500:2000]',units='channels')
##           Returns:     An SDRecord.
##           Produces:    a polynomial baseline (labeled baselineN where N
##                        is 1,2,3,etc.) and a baseline subtracted scan if
##                        the option 'subtract' is specified.
##           Note:        I assume channels if nothing is specified. There
##                        is no access to the sinusoid fitting here though
##                        it is available through the GUI and through
##                        ssa.dish.ops().baseline
   public.dbase:=function(scanrec=F,order=1,range=F,action='subtract',
		cursor=F,autoplot=T) 
{
        wider private,public;
        if (is_boolean(scanrec)) {
                scanrec:=private.dish.rm().getlastviewed().value;
        }
        if (is_sdrecord(scanrec)) {
           public.settype('polynomial');
           public.setorder(order);
#          sd.ops().baseline.setunits(units);
           if (cursor) {
                dl.note('Use Left Mouse Button to Set Ranges');
                ok:=private.dish.plotter.setranges();
           };
           if (is_boolean(range)) {
                range:=private.dish.plotter.ranges();
           } else {
                private.dish.plotter.putranges(range);
           };
           public.setaction(action);
           ok:=public.apply(scanrec,autoplot=autoplot);
	   return ok;
        } else {
           return throw('FAIL: Not an sdrecord');
        };
#       don't get the last record!
#       return private.getrecord();
	return F;
   }


#    public.debug := function() { wider private; return private;}

    # return the public interface
    return public;
}
