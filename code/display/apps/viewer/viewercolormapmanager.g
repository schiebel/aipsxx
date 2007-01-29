# viewercolormapmanager.g: colormap support for the viewer
# Copyright (C) 1999,2000,1001,2001,2002
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
# $Id: viewercolormapmanager.g,v 19.1 2005/06/15 18:10:57 cvsmgr Exp $

pragma include once;

include 'viewer.g';
include 'aipsrc.g';

## ************************************************************ ##
##                                                              ##
## VIEWERCOLORMAPMANAGER SUBSEQUENCE                            ##
##                                                              ##
## ************************************************************ ##
viewercolormapmanager := subsequence(viewer) {
    __VCF_('viewercolormapmanager');

    ############################################################
    ## SANITY CHECK                                           ##
    ############################################################
    if (!is_record(viewer) || !has_field(viewer, 'type') ||
	(viewer.type() != 'viewer')) {
	return throw(spaste('An invalid viewer was given to a ',
			    'viewercolormapmanager'));
    }
    if (is_agent(viewer.colormapmanager())) {
	return throw(spaste('The parent viewer given to the ',
			    'viewercolormapmanager constructor already ',
			    'has a colormapmanager'));
    }

    ############################################################
    ## INITIALISE AND STORE CONSTRUCTOR ARGUMENTS             ##
    ############################################################
    its := [=];
    its.viewer := viewer;
    its.aipsrc := drc;
    ############################################################
    ## BASIC SERVICES                                         ##
    ############################################################
    its.type := 'viewercolormapmanager';
    self.type := function() {
	__VCF_('viewercolormapmanager.type');
	return its.type;
    }

    self.viewer := function() {
	__VCF_('viewercolormapmanager.viewer');
	return ref its.viewer;
    }

    ############################################################
    ## WHENEVER PUSHER                                        ##
    ############################################################
    its.whenevers := [];
    its.pushwhenever := function() {
	wider its;
	its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
    }

    ############################################################
    ## DONE FUNCTION                                          ##
    ############################################################
    its.dying := F;
    self.done := function() {
	__VCF_('viewercolormapmanager.done');
	wider self, its;
	if (its.dying) {
	    # prevent multiple done requests
	    return F;
	}
	if (!its.viewer.dying()) {
	    return throw(spaste('Cannot destroy viewercolormapmanager ',
				'unless requested to do so by the viewer'));
	}
	its.dying := T;
	if (viewer::tracedone) {
	    print 'viewercolormapmanager::done()';
	}
	deactivate its.whenevers;

	## viewercolormapmanagerguis
	if (len(its.colormapmanagerguis) > 0) {
	    for (i in 1:len(its.colormapmanagerguis)) {
		if (is_agent(its.colormapmanagerguis[i])) {
		    its.colormapmanagerguis[i].done();
		}
	    }
	}

	val its := F;
	val self := F;
	return T;
    }

    ############################################################
    ## GUI FUNCTION                                           ##
    ############################################################
    its.colormapmanagerguis := [=];
    self.gui := function(parent=F, show=T, hasdismiss=F, hasdone=F,
			 widgetset=unset) {
	__VCF_('viewercolormapmanager.gui');
	wider its;
	temp := its.viewercolormapmanagergui(parent, self, show, hasdismiss,
					     hasdone, widgetset);
	if (is_agent(temp)) {
	    its.colormapmanagerguis[len(its.colormapmanagerguis) + 1] :=
		temp;
	}
	return temp;
    }

    ############################################################
    ## COLORMAPS TO BE MANAGED                                ##
    ############################################################
    its.colormaps := [=];
    t := its.aipsrc.find(its.defcmap, 'display.colormaps.defaultcolormap',
			    'Greyscale 1');
    junk := its.viewer.widgetset().information();
    listofcmaps := junk->colormapnames();
    if (!any(listofcmaps == its.defcmap)) {
	its.defcmap := 'Greyscale 1';
    }
    for (i in listofcmaps) {
        its.colormaps[i] := [=];
    }
    junk := F;
    self.defaultcolormapname := function() {
	return its.defcmap;
    }

    #its.colormaps.default := F;
    self.colormapnames := function() {
	__VCF_('viewercolormapmanager.colormapnames');
	return field_names(its.colormaps);
    }
    self.colormap := function(name) {
	wider its;
	__VCF_('viewercolormapmanager.colormap');
	if (!has_field(its.colormaps, name) && name != '<default>') {
	    fail 'unknown colormap';
	}
	if (name == '<default>') name := its.defcmap;
        if (is_agent(its.colormaps[name])) {
            return its.colormaps[name];
        } else {
            tcm := its.viewer.widgetset().colormap(name);
            if (is_fail(tcm)) {
                note(spaste('Failed to load colormap \'', i, '\'',
                            ' - the viewer may fail under continued use.\n',
                            tcm::message),
                     origin='viewer.g', priority='SEVERE');
            } else {
                its.colormaps[name] := tcm;
                whenever its.colormaps[name]->logmessage do {
                    note($value.message, origin=$value.origin, 
                         priority=$value.priority);
                } its.pushwhenever();
                whenever its.colormaps[name]->error do {
                    note($value, 
                         origin=spaste(its.viewer.title(), 
                                       ' (viewercolormapmanager.g)'),
                         priority='WARN');
                } its.pushwhenever();
            }
            return its.colormaps[name];
        }
	
    }
    self.nmaps := function() {
	__VCF_('viewercolormapmanager.nmaps');
	return len(its.colormaps);
    }

    ############################################################
    ## PARAMETERS                                             ##
    ############################################################
    self.getoptions := function(name) {
	__VCF_('viewercolormapmanager.getoptions');
	cmap := self.colormap(name);
	if (is_agent(cmap)) {
	    return cmap->getoptions();
	} else {
	    return throw(cmap::message);
	}
    }
    self.setoptions := function(name, newopts) {
	__VCF_('viewercolormapmanager.setoptions');
	cmap := self.colormap(name);
	if (is_agent(cmap)) {
	    return cmap->setoptions(newopts);
	} else {
	    return throw(cmap::message);
	}
    }

    ############################################################
    ## SHIFT CONTROL                                          ##
    ############################################################
    self.getshift := function(name) {
	__VCF_('viewercolormapmanager.getshift');
	cmap := self.colormap(name);
	if (is_agent(cmap)) {
	    return cmap->getshift();
	} else {
	    return throw(cmap::message);
	}
    }
    self.setshift := function(name, value) {
	__VCF_('viewercolormapmanager.setshift');
	cmap := self.colormap(name);
	if (is_agent(cmap)) {
	    t := cmap->setshift(value);
	    self->shift([colormap=name, value=value]);
	    return T;
	} else {
	    return throw(cmap::message);
	}
    }

    ############################################################
    ## SLOPE CONTROL                                          ##
    ############################################################
    self.getslope := function(name) {
	__VCF_('viewercolormapmanager.getslope');
	cmap := self.colormap(name);
	if (is_agent(cmap)) {
	    return cmap->getslope();
	} else {
	    return throw(cmap::message);
	}
    }
    self.setslope := function(name, value) {
	__VCF_('viewercolormapmanager.setslope');
	cmap := self.colormap(name);
	if (is_agent(cmap)) {
	    t := cmap->setslope(value);
	    self->slope([colormap=name, value=value]);
	    return T;
	} else {
	    return throw(cmap::message);
	}
    }

    ############################################################
    ## BRIGHTNESS CONTROL                                     ##
    ############################################################
    self.getbrightness := function(name) {
	__VCF_('viewercolormapmanager.getbrightness');
	cmap := self.colormap(name);
	if (is_agent(cmap)) {
	    return cmap->getbrightness();
	} else {
	    return throw(cmap::message);
	}
    }
    self.setbrightness := function(name, value) {
	__VCF_('viewercolormapmanager.setbrightness');
	cmap := self.colormap(name);
	if (is_agent(cmap)) {
	    t := cmap->setbrightness(value);
	    self->brightness([colormap=name, value=value]);
	    return T;
	} else {
	    return throw(cmap::message);
	}
    }

    ############################################################
    ## CONTRAST CONTROL                                       ##
    ############################################################
    self.getcontrast := function(name) {
	__VCF_('viewercolormapmanager.getcontrast');
	cmap := self.colormap(name);
	if (is_agent(cmap)) {
	    return cmap->getcontrast();
	} else {
	    return throw(cmap::message);
	}
    }
    self.setcontrast := function(name, value) {
	__VCF_('viewercolormapmanager.setcontrast');
	cmap := self.colormap(name);
	if (is_agent(cmap)) {
	    t := cmap->setcontrast(value);
	    self->contrast([colormap=name, value=value]);
	    return T;
	} else {
	    return throw(cmap::message);
	}
    }

    ############################################################
    ## INVERT CONTROL                                         ##
    ############################################################
    self.getinvertflags := function(name) {
	__VCF_('viewercolormapmanager.getinvertflags');
	cmap := self.colormap(name);
	if (is_agent(cmap)) {
	    return cmap->getinvertflags();
	} else {
	    return throw(cmap::message);
	}
    }
    self.setinvertflags := function(name, value) {
	__VCF_('viewercolormapmanager.setinvertflags');
	cmap := self.colormap(name);
	if (is_agent(cmap)) {
	    t := cmap->setinvertflags(value);
	    self->invertflags([colormap=name, value=value]);
	    return T;
	} else {
	    return throw(cmap::message);
	}
    }

    ############################################################
    ## RESET CONTROL                                          ##
    ############################################################
    self.reset := function(name) {
	__VCF_('viewercolormapmanager.reset');
	if (is_agent(self.colormap(name))) {
	    self.setinvertflags(name, [F, F, F]);
	    self.setshift(name, 0.5);
	    self.setslope(name, 1.0);
	    self.setbrightness(name, 0.5);
	    self.setcontrast(name, 0.5);
	    return T;
	} else {
	    return throw('Couldn\'t find named colormap');
	}
    }
    self.resetall := function() {
	__VCF_('viewercolormapmanager.resetall');
	for (i in field_names(its.colormaps)) {
	    self.reset(i);
	}
	return T;
    }

    ## ************************************************************ ##
    ##                                                              ##
    ## VIEWERCOLORMAPMANAGERGUI SUBSEQUENCE                         ##
    ##                                                              ##
    ## ************************************************************ ##
    its.viewercolormapmanagergui := subsequence(parent=F, colormapmanager,
						show=T, hasdismiss=F, 
						hasdone=F, widgetset=unset) {
	__VCF_('viewercolormapmanagergui');
	
	############################################################
	## SANITY CHECK                                           ##
	############################################################
	if (!is_record(colormapmanager) || 
	    !has_field(colormapmanager, 'type') ||
	    (colormapmanager.type() != 'viewercolormapmanager')) {
	    return throw(spaste('An invalid viewercolormapmanager was given ', 
				'to a viewercolormapmanagergui'));
	}
	if (hasdone && hasdismiss) {
	    note(spaste('An attempt was made to construct a ',
			'viewercolormapmanagergui with both Dismiss AND ',
			'Done buttons'));
	    hasdismiss := F;
	}
	
	############################################################
	## INITIALISE AND STORE CONSTRUCTOR ARGUMENTS             ##
	############################################################
	its := [=];
	its.parent := parent;
	its.colormapmanager := colormapmanager;
	its.show := show;
	its.hasdismiss := hasdismiss;
	its.hasdone := hasdone;
	its.wdgts := widgetset;

	############################################################
	## BASIC SERVICES                                         ##
	############################################################
	its.type := 'viewercolormapmanagergui';
	self.type := function() {
	    __VCF_('viewercolormapmanagergui.type');
	    return its.type;
	}
	
	self.colormapmanager := function() {
	    __VCF_('viewercolormapmanagergui.colormapmanager');
	    return ref its.colormapmanager;
	}
	
	its.viewer := its.colormapmanager.viewer();
	self.viewer := function() {
	    __VCF_('viewercolormapmanagergui.viewer');
	    return its.viewer;
	}
	
	if (is_unset(its.wdgts)) {
	    its.wdgts := its.viewer.widgetset();
	}
	
	############################################################
	## WHENEVER PUSHER                                        ##
	############################################################
	its.whenevers := [];
	its.pushwhenever := function() {
	    wider its;
	    its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
	}
	
	############################################################
	## MAP/UNMAP CONTAINER OF GUI                             ##
	############################################################
	its.ismapped := F;
	self.map := function(force=F) {
	    __VCF_('viewercolormapmanagergui.map');
	    wider its;
	    if (!its.ismapped || force) {
		if (its.madeparent) {
		    t := its.parent->map();
		} else {
		    t := its.wholeframe->map();
		}
		its.ismapped := T;
	    }
	    return T;
	}
	self.unmap := function(force=F) {
	    __VCF_('viewercolormapmanagergui.unmap');
	    wider its;
	    if (its.ismapped || force) {
		if (its.madeparent) {
		    t := its.parent->unmap();
		} else {
		    t := its.wholeframe->unmap();
		}
		its.ismapped := F;
	    }
	    return T;
	}
	self.ismapped := function() {
	    __VCF_('viewercolormapmanagergui.ismapped');
	    return its.ismapped;
	}
	
	############################################################
	## DONE FUNCTION                                          ##
	############################################################
	its.dying := F;
	self.done := function() {
	    __VCF_('viewercolormapmanagergui.done');
	    wider its, self;
	    if (its.dying) {
		# prevent multiple done requests
		return F;
	    } its.dying := T;
	    if (viewer::tracedone) {
		print 'viewercolormapmanagergui::done()';
	    }
	    deactivate its.whenevers;
	    if (is_agent(its.viewer)) {
		its.viewer.hold();
	    }
#	     if (is_agent(its.dpanel)) {
#		 its.dpanel.testpattern(F);
#		 if (is_string(its.registeredcolormap)) {
#		     its.dpanel.unregistercolormap(its.registeredcolormap);
#		 }
#	     }
#	    if (is_agent(its.dpanel)) {
#		its.dpanel.done();
#	    }
	    self.unmap(T);
	    if (is_agent(its.viewer)) {
		its.viewer.release();
	    }
	    val self := F;
	    val its := F;	
	    return T;
	}
	
	############################################################
	## DISMISS FUNCTION                                       ##
	############################################################
	self.dismiss := function() {
	    __VCF_('viewercolormapmanagergui.dismiss');
	    return self.unmap();
	}
	
	############################################################
	## GUI FUNCTION                                           ##
	############################################################
	self.gui := function() {
	    __VCF_('viewercolormapmanagergui.gui');
	    return self.map();
	}
	
	############################################################
	## DISABLE/ENABLE THE GUI                                 ##
	############################################################
	self.disable := function() {
	    __VCF_('viewercolormapmanagergui.disable');
	    if (its.madeparent) {
		t := its.parent->disable();
		t := its.parent->cursor("watch");
	    } 
	    return T;
	}
	self.enable := function() {
	    __VCF_('viewercolormapmanagergui.enable');
	    if (its.madeparent) {
		t := its.parent->enable();
		t := its.parent->cursor(its.originalcursor);
	    }
	    return T;
	}
	
	############################################################
	## CONSTRUCT FRAME                                        ##
	############################################################
	its.wdgts.tk_hold();
	its.madeparent := F;
	if (is_boolean(its.parent)) {
	    its.parent := 
		its.wdgts.frame(title=spaste(its.colormapmanager.viewer().
					     title(), ' - Colormap manager'));
	    its.madeparent := T;
	}
	its.originalcursor := its.parent->cursor();
	its.wholeframe := its.wdgts.frame(its.parent, side='top');
	if (is_fail(its.wholeframe)) {
	    its.wdgts.tk_release();
	    return throw(spaste('Failed to construct a frame: probable ',
				'incompatibility between widgetservers'));
	}
	self.unmap(T);
	its.wdgts.tk_release();
	
	## build the gui
	its.frame := its.wdgts.frame(its.wholeframe, side='left');
	its.lowerframe := its.wdgts.frame(its.wholeframe, borderwidth=0,
					  padx=0, pady=0, relief='flat',
					  side='left', expand='x');
	
	its.lbframe := its.wdgts.frame(its.frame, side='top', expand='y');
	its.lboxlabel := its.wdgts.label(its.lbframe, 'Colormaps', anchor='c');
	its.lbox := its.wdgts.scrolllistbox(its.lbframe, mode='single',
					    seeoninsert=F, height=10,
					    fill='y');
	its.lbox->insert(its.colormapmanager.colormapnames());
	
	its.rtframe := its.wdgts.frame(its.frame, side='top', expand='both');
	
#	 its.dpanel := its.colormapmanager.viewer().
#	     newdisplaypanel(its.rtframe, width=300, height=130, holdsdata=F);
#	 if (is_fail(its.dpanel)) {
#	     return throw(its.dpanel::message);
#	 }

	its.registeredcolormap := F;
	its.cmapbusy := F;
	its.warncount := 0;
	whenever its.lbox->select do {
	    if (!its.cmapbusy) {
		its.cmapbusy := T;
		t := its.lbox->selection();
		if (len(t) > 0) {
		    its.viewer.hold();
#		    its.dpanel.testpattern(F);
		    nextcmap := its.lbox->get(t[1]);
		    cmap := its.colormapmanager.colormap(nextcmap);
#		     if (is_string(its.registeredcolormap)) {
#			 its.dpanel.replacecolormap(nextcmap, 
#						    its.registeredcolormap);
#		     } else {
#			 its.dpanel.registercolormap(nextcmap);
#		     }
		    its.registeredcolormap := nextcmap;
		    its.updategui();

#		    its.dpanel.testpattern(T);
		    its.viewer.release();
		} else {
		    note('Steady on there! - just one at a time please',
			 priority='WARN', origin='viewer.g');
		    its.warncount := its.warncount + 1;
		    if (!(its.warncount%5)) {
			note(spaste('This is a *serious* message - you may ',
				    'cause AIPS++ to fail\nif you persist in ',
				    'selecting colormaps so rapidly'),
			     priority='SEVERE', 
			     origin=spaste(its.viewer.title, ' (viewer.g)'));
		    }
		}
		its.cmapbusy := F;
	    } else {
		note('Steady on there! - just one at a time please',
		     priority='WARN', origin='viewer.g');
		its.warncount := its.warncount + 1;
		if (!(its.warncount%5)) {
		    note(spaste('This is a *serious* message - you may well ',
				'cause AIPS++ to fail\nif you persist in ',
				'selecting colormaps so rapidly'),
			 priority='SEVERE', 
			 origin=spaste(its.viewer.title, ' (viewer.g)'));
		}
	    }
	} its.pushwhenever();
	
	its.autogui := F;
	its.updategui := function() {
	    wider its;
	    its.viewer.hold();
	    its.agparams := its.colormapmanager.
		getoptions(its.registeredcolormap);
	    if (!is_fail(its.agparams)) {
		if (is_boolean(its.autogui)) {
		    its.wdgts.tk_hold();
		    its.lframe->unmap();
		    its.wdgts.tk_release();
		    its.autogui := autogui(params=its.agparams, 
					   toplevel=its.lframe,
					   autoapply=T,
					   widgetset=its.wdgts);
		    whenever its.autogui->setoptions do {
			deactivate;
			#its.time := time();
			its.colormapmanager.setoptions(its.registeredcolormap,
						       $value);
			activate;
		    } its.pushwhenever();
		    its.lframe->map();
		} else {
		    its.autogui.fillgui(its.agparams);
		    #print 'autogui exists, needs to update it';
		}
	    } else {
		print 'getoptions failed';
	    }
	    its.viewer.release();
	}
		
	its.lframe := its.wdgts.frame(its.rtframe, side='top', expand='x');

	its.rightbbar := its.wdgts.frame(its.lowerframe, borderwidth=0,
					 padx=0, pady=0, relief='flat',
					 side='right');
	if (its.hasdone) {
	    its.bdone := its.wdgts.button(its.rightbbar, 'Done',
					  type='halt');
	    its.wdgts.popuphelp(its.bdone, 
		      txt=spaste('Press this button to be finished with this ',
				 'colormap manager - you can always get ',
				 'another one back!'),
		      hlp='Finish with this colormap manager');
	    whenever its.bdone->press do {
		self.done();
	    } its.pushwhenever();
	}
	if (its.hasdismiss) {
	    its.bdismiss := its.wdgts.button(its.rightbbar, 'Dismiss', 
					     type='dismiss');
	    its.wdgts.popuphelp(its.bdismiss, 
		      txt=spaste('Press this button to hide this colormap ',
				 'manager - you can probably retrieve it ',
				 'later via the application you are using, ',
				 'or via the command line'),
		      hlp='Hide this colormap manager');
	    whenever its.bdismiss->press do {
		self.dismiss();
	    } its.pushwhenever();
	}
	x := [];
#	x := its.dpanel.status().pixelcanvas.registeredcolormaps.names;
	if (len(x) > 0) {
	    its.registeredcolormap := x[1];
	    cmap := its.colormapmanager.colormap(its.registeredcolormap);
#	    print x;
#	    print x[1];
	    x := [1:its.colormapmanager.nmaps()][its.registeredcolormap == 
						 its.colormapmanager.
						 colormapnames()];
#	    print x;
	    if (len(x) == 1) {
		its.lbox->select(as_string(x-1));
		its.lbox->see(as_string(x-1));
		its.updategui();
#		its.dpanel.registercolormap(its.registeredcolormap);
#		its.dpanel.testpattern(T);
	    }
	}
	if (its.show) {
	    t := self.map();
	}
    }
}
