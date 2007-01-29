# viewerslicedp.g: provision of 3d slicing for the viewer
# Copyright (C) 1999,2000,2001,2003
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

pragma include once;

include 'viewer.g';
include 'timer.g';
include 'aipsrc.g';

## ************************************************************ ##
##                                                              ##
## VIEWERSLICEDP SUBSEQUENCE                                    ##
##                                                              ##
## ************************************************************ ##
viewerslicedp := subsequence(parent=F, viewer, width=300, 
			     height=300,
			     maptype='index',
			     newcmap=F, mincolors=unset,
			     maxcolors=unset,
			     autoregister=F, holdsdata=T, 
			     show=T,
			     widgetset=unset) {
    
    ############################################################
    ## SANITY CHECK                                           ##
    ############################################################
    if (!is_record(viewer) || !has_field(viewer, 'type') ||
	(viewer.type() != 'viewer')) {
	return throw(spaste('An invalid viewer was given to a ',
			    'viewerdisplaypanel'));
    }

    ############################################################
    ## INITIALISE AND STORE CONSTRUCTOR ARGUMENTS             ##
    ############################################################
    its := [=];
    its.parent := ref parent;
    its.gui := [=];
    its.gui.slicepanel := F;

    its.viewer := viewer;
    its.width := width;
    its.height := height;
    its.maptype := maptype;
    its.newcmap := newcmap;
    its.mincolors := mincolors;
    its.maxcolors := maxcolors;
    its.autoregister := autoregister;
    its.holdsdata := holdsdata;
    its.show := show;
    its.wdgts := widgetset;

    ############################################################
    ## BASIC SERVICES                                         ##
    ############################################################
    its.type := 'viewerdisplaypanel';
    self.type := function() {	
	return its.type;
    }

    self.viewer := function() { 
	return its.viewer;
    }

    if (is_unset(its.wdgts)) {
	its.wdgts := its.viewer.widgetset();
    }
    self.widgetset := function() {	
	return its.wdgts;
    }
    
    ############################################################
    ## WHENEVER PUSHER                                        ##
    ############################################################
    its.whenevers := [];
    its.pushwhenever := function() {
	wider its;
	its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
    }
    const its.deactivate := function(which) {
	if (is_integer(which)) {
	    n := length(which);
	    if (n>0) {
		for (i in 1:n) {
		    ok := whenever_active(which[i]);
		    if (is_fail(ok)) {
		    } else {
			if (ok) deactivate which[i];
		    }
		}
	    }
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
	    its.wdgts.frame(title=spaste(its.viewer.title(),
					 ' - 3D Slice Panel (AIPS++)'),
			    newcmap=its.newcmap);
	its.madeparent := T;
    }
    its.originalcursor := its.parent->cursor();
    its.wholeframe := its.wdgts.frame(its.parent, side='top',
				      borderwidth=0, padx=0, pady=0);
    if (is_fail(its.wholeframe)) {
	its.wdgts.tk_release();
	return throw(spaste('Failed to construct a frame: probable ',
			    'incompatibility between widgetservers'));
    }

    its.wdgts.tk_release();

    ## make upper and middle frame
    its.gui.upperframe := its.wdgts.frame(its.wholeframe, side='top',
					  relief='flat', height=1, expand='x',
					  borderwidth=0, padx=0, pady=0);
    its.gui.centreframe := its.wdgts.frame(its.wholeframe, side='left',
					   relief='flat', expand='both',
					   borderwidth=0, padx=0, pady=0);
    its.gui.leftframe := its.wdgts.frame(its.gui.centreframe, side='top',
					 relief='flat', expand='y',
					 borderwidth=0, padx=0, pady=0,
					 width=0);
    its.gui.midframe := its.wdgts.frame(its.gui.centreframe, side='top',
					  relief='flat', expand='both',
					  borderwidth=0, padx=0, pady=0);
    its.gui.rightframe := its.wdgts.frame(its.gui.centreframe, side='top',
					  relief='flat', expand='y',
					  borderwidth=0, padx=0, pady=0,
					  width=0);
    its.gui.lowerframe := its.wdgts.frame(its.wholeframe, side='top', 
					  relief='flat', height=1, expand='x',
					  borderwidth=0, padx=0, pady=0);
    self.upperframe := function() { 
	
	return its.gui.upperframe; 
    }
    self.lowerframe := function() { 
	
	return its.gui.lowerframe; 
    }
    self.leftframe := function() {
	
	return its.gui.leftframe;
    }
    self.rightframe := function() {
	
	return its.gui.rightframe;
    }

    ## apply context-sensitive defaults for min/maxcolors
    if (its.maptype == 'index') {
	if (its.newcmap) {
	    if (is_unset(its.mincolors)) {
		its.mincolors := 128;
	    }
	    if (is_unset(its.maxcolors)) {
		its.maxcolors := 220;
	    }
	} else {
	    if (is_unset(its.mincolors)) {
		its.mincolors := 8;
	    }
	    if (is_unset(its.maxcolors)) {
		its.maxcolors := 80;
	    }
	}
    } else {
	if (is_unset(its.mincolors)) {
	    its.mincolors := 4;
	}
	if (is_unset(its.maxcolors)) {
	    its.maxcolors := 7;
	}
    }

    ## build a pixelcanvas as requested
    its.gui.pcanvas := 
      its.wdgts.pixelcanvas(its.gui.midframe, its.width, its.height,
			    fill='both', background='black',
			    mincolors=its.mincolors, 
			    maxcolors=its.maxcolors,
			    maptype=its.maptype);
    if (is_fail(its.gui.pcanvas)) {
#	return throw(spaste('Couldn\'t create a pixelcanvas:\n',
#			    its.gui.pcanvas::message));
	val its := 0;
	val self := 0;
	fail 'Could not create a pixelcanvas';
    } else {
	## pass on pixelcanvas events - eg. needed to pass on contextoptions
	## event...
	whenever its.gui.pcanvas->* do {
	    self->[$name]($value);
	} its.pushwhenever();
	whenever its.gui.pcanvas->logmessage do {
	    note($value.message, origin=$value.origin, 
		 priority=$value.priority);
	} its.pushwhenever();
    }
    self.writexpm := function(filename) {
	
	if (is_agent(its.gui.pcanvas)) {
	    t := its.gui.pcanvas->writexpm(filename);
	}
	return T;
    }
    self.newcmap := function() {
	
	if (its.madeparent) {
	    return its.newcmap;
	} else {
	    return unset;
	}
    }

    self.autoregister := function(set=unset) {
	
	wider its;
	if (is_boolean(set)) {
	    its.autoregister := set;
	}
	return its.autoregister;
    }

    self.holdsdata := function() {
	
	return its.holdsdata;
    }

    ############################################################
    ## HOW TO DEAL WITH DEATH                                 ##
    ############################################################
    whenever its.parent->killed do {
	note(spaste('A frame containing a pixelcanvas was killed.  AIPS++ ',
		    'may fail, or show \n\'pure virtual method\' errors ',
		    'at exit'), priority='SEVERE', origin='viewer.g');
	note(spaste('You are urged to use the \'Done\' ',
		    'button to close displaypanels'), 
	     origin=its.viewer.title(), priority='WARN');
	if (len(its.whenevers) > 0) {
	    its.deactivate(its.whenevers);
	}
	val its := F;
	val self := F;
    } its.pushwhenever();


    #### redo ######
    its.worldcanvasid := [];
    self.worldcanvasid := function() {
	
	return its.worldcanvasid;
    }
    
    ############################################################
    ## MAKE WORLDCANVAS/ES                                    ##
    ############################################################

    if (its.holdsdata) {
	############################################################
	## WORLDCANVAS                                            ##
	############################################################
	its.gui.slicepanel := its.wdgts.slicepd(its.gui.pcanvas);
	if (is_fail(its.gui.slicepanel)) {
	    return throw(spaste('Couldn\'t create a slicepd:\n',
				its.gui.slicepanel::message));
	} else {
	    pdopt := [=];
	    pdopt.topmarginspacepg.value :=0;
	    pdopt.leftmarginspacepg.value :=0;
	    pdopt.rightmarginspacepg.value :=0;
	    pdopt.bottommarginspacepg.value :=0;
	    its.gui.slicepanel->setoptions(pdopt);
	    whenever its.gui.slicepanel->logmessage do {
		note($value.message, origin=$value.origin, 
		     priority=$value.priority);
	    } its.pushwhenever();
	    whenever its.gui.slicepanel->localoptions do {
		self->localoptions($value);
	    } its.pushwhenever();
	    self.paneldisplayagents := function() {		    
		return its.gui.slicepanel;
	    }
	    ############################################################
	    ## "SUPPORT" FOR REGIONS DRAWN ON THE WORLDCANVAS/ES      ##
	    ############################################################
	    whenever its.gui.slicepanel->* do {
		self->[$name]($value);
	    } its.pushwhenever();
	}
	its.worldcanvasid := its.gui.slicepanel->status().worldcanvasid;
    }

    self.hold := function() {	
	if (has_field(its, 'gui')) {
	    if (has_field(its.gui, 'slicepanel')) {
		if (is_agent(its.gui.slicepanel)) {
		    t := its.gui.slicepanel->hold();
		}
	    }
	    if (has_field(its.gui, 'pcanvas') && is_agent(its.gui.pcanvas)) {
		t := its.gui.pcanvas->hold();
	    }
	}
	return T;
    }
    self.release := function() {	
	if (has_field(its, 'gui')) {
	    if (has_field(its.gui, 'pcanvas') && is_agent(its.gui.pcanvas)) {
		t := its.gui.pcanvas->release();
	    }
	    if (has_field(its.gui, 'slicepanel')) {
		if (is_agent(its.gui.slicepanel)) {
		    t := its.gui.slicepanel->release();
		}
	    }
	}
	return T;
    }

    ############################################################
    ## MAP/UNMAP CONTAINER OF GUI                             ##
    ############################################################
    its.ismapped := F;
    self.map := function(force=F) {
	
	wider its;
	if (!its.ismapped || force) {
	    if (its.madeparent) {
		t := its.parent->map();
	    } else {
		t := its.wholeframe->map();
	    }
	    its.ismapped := T;
	    self.release();
	}
	return T;
    }
    self.unmap := function(force=F) {	
	wider its;
	if (its.ismapped || force) {
	    self.hold();
	    if (its.madeparent) {
		t := its.parent->unmap();
	    } else {
		t := its.wholeframe->unmap();
	    }
	    its.ismapped := F;
	}
	return T;
    }
    self.unmap(T);
    self.ismapped := function() {
	return its.ismapped;
    }


    ############################################################
    ## DISMISS FUNCTION                                       ##
    ############################################################
    self.dismiss := function() {	
	return self.unmap();
    }

    ############################################################
    ## GUI FUNCTION                                           ##
    ############################################################
    self.gui := function() {	
	return self.map();
    }
    
    ############################################################
    ## DISABLE/ENABLE THE GUI                                 ##
    ############################################################
    self.disable := function() {	
	if (its.madeparent) {
	    t := its.parent->disable();
	    #t := its.parent->cursor('watch');
	} 
	return T;
    }
    self.enable := function() {
	
	if (its.madeparent) {
	    t := its.parent->enable();
	    #t := its.parent->cursor(its.originalcursor);
	}
	return T;
    }


    ############################################################
    ## DONE FUNCTION                                          ##
    ############################################################
    its.dying := F;
    self.dying := function() {
	
	return its.dying;
    }
    self.done := function() {
	
	wider its, self;
	if (its.dying) {
	    # prevent multiple done requests.
	    return F;
	} its.dying := T;
	if (viewer::tracedone) {
	    print 'viewerslicedp::done()';
	}
	#self->done();
	if (len(its.whenevers) > 0) {
	    its.deactivate(its.whenevers);
	}
	if (its.holdsdata) {
	    ## canvasmanager
	    if (is_agent(its.canvasmanager)) {
		its.canvasmanager.done();
	    }
	}

	if (is_agent(its.viewer)) {
	    its.viewer.hold();
	}

	self.disablecontrols();

	if (its.holdsdata) {
	    if (len(its.displaydataguis) > 0) {
		for (i in 1:len(its.displaydataguis)) {
		    if (is_agent(its.displaydataguis[i])) {
			its.displaydataguis[i].done();
		    }
		}
	    }
	    self.unregisterall();
	    val its.gui.slicepanel := F;	    
	}
	val its.gui.pcanvas := F;
	if (is_agent(self) && is_agent(its.thegui)) {	    
	    its.thegui.done();
	}
	if (is_agent(self) && is_agent(its.viewer)) {
	    its.viewer.release();
	}
	val its := F;
	self->done();
	val self := F;
	return T;
    }
    self.status := function() {	
	rec := [=];
	rec.pixelcanvas := its.gui.pcanvas->status();
	if (its.holdsdata) {
	    rec.paneldisplay := its.gui.slicepanel->status();
	}
	rec.maptype := its.maptype;
	return rec;
    }
    
    self.getoptions := function() {	
	rec := its.gui.pcanvas->getoptions();
	if (its.holdsdata) {
	    rec2 := its.gui.slicepanel->getoptions();
	    unwanted := "nxpanels nypanels xspacing yspacing";
	    if (is_record(rec2)) {
		for (i in field_names(rec2)) {
		    if (all(unwanted != i)) {		    
			rec[i] := rec2[i];
		    }
		}
	    }
	}
	return rec;
    }

    self.setoptions := function(options) {
	wider its;
	
	its.viewer.hold();
	rec1 := its.gui.pcanvas->setoptions(options);
	if (its.holdsdata) {
	    rec2 := its.gui.slicepanel->setoptions(options);
	}
	its.viewer.release();

	# rec1 and rec2 may contain options which have changed due
	# to context, so now create a merged options record and return 
	# it.
	if (is_record(rec2)) {
	    for (i in field_names(rec2)) {
		unwanted := "nxpanels nypanels xspacing yspacing";
		if (all(unwanted != i)) {
		    rec1[i] := rec2[i];
		}	   
	    }
	}
	return rec1;
    }

    self.disablecontrols := function() {	
	t := its.gui.slicepanel->disabletools();
	return T;
    }

    self.enablecontrols := function() {
	t := its.gui.slicepanel->enabletools();
	return T;
    }



    ############################################################
    ## DEAL WITH CONSTRUCTING, MAPPING AND UNMAPPING THE GUI  ##
    ############################################################
    its.thegui := F;
    self.addgui := function(guihasmenubar=T, guihascontrolbox=T,
			    guihasanimator=F, guihasbuttons=T,
			    guihastracking=T,
			    hasdismiss=unset, hasdone=unset,
			    isolationmode=F, show=T) {
	
        wider its;
	if (!is_agent(its.thegui)) {
	    its.thegui := its.viewerdisplaypanelgui(self, guihasmenubar,
						    guihascontrolbox,
						    guihasbuttons,
						    guihastracking,
						    hasdismiss, 
						    hasdone, 
						    isolationmode, show=show);
	}
	if (!is_agent(its.thegui)) {
	    return throw(spaste('Catastrophic failure: couldn\'t add ',
				'GUI to viewerdisplaypanel'));
	}		
	if (guihastracking) {
	    its.thegui.maketrackmessagelines(self.registerednames(ignore=
                [Display::Annotation, Display::CanvasAnnotation]));
	}
	return T;
    }
    
    ############################################################
    ## UTILITY FUNCTIONS                                      ##
    ############################################################
    self.registercolormap := function(map) {
	
	t := its.viewer.colormapmanager().colormap(map);
	if (is_agent(t) && is_agent(its.gui.pcanvas)) {
	    tmp := its.gui.pcanvas->registercolormap(t);
	}
    }
    self.unregistercolormap := function(map) {
	
	if (is_agent(its.viewer)) {
	    t := its.viewer.colormapmanager().colormap(map);
	    if (is_agent(t) && is_agent(its.gui.pcanvas)) {
		tmp := its.gui.pcanvas->unregistercolormap(t);
	    }
	}
    }
    self.replacecolormap := function(newcmapname, oldcmapname) {
	
	t1 := its.viewer.colormapmanager().colormap(newcmapname);
	t2 := its.viewer.colormapmanager().colormap(oldcmapname);
	if (is_agent(t1) && is_agent(t2) && is_agent(its.gui.pcanvas)) {
		newcmapname;
	    tmp := its.gui.pcanvas->replacecolormap(t1, t2);
	} else if (is_agent(t1) && is_agent(its.gui.pcanvas)) {
	    tmp := its.gui.pcanvas->registercolormap(t1);
	} else {
	    fail 'Could not replace or register colormap';
	}
    }
    self.setcolortablesize := function(size) {
	
	its.viewer.hold();
	t := its.gui.pcanvas->colortablesize(size);
	its.viewer.release();
    }
    
    if (its.holdsdata) {
	############################################################
	## CANVASMANAGER                                          ##
	############################################################
	its.canvasmanager := F;
	self.canvasmanager := function() {
	    return its.canvasmanager;
	}
	its.canvasmanager := viewercanvasmanager(self);
	if (is_fail(its.canvasmanager)) {
	    note(spaste('Couldn\'t create a viewercanvasmanager - ',
			'canvas adjustments unavailable'),
		 origin=spaste(its.viewer.title(), ' (viewer.g)'),
		 priority='SEVERE');
	    its.canvasmanager := F;
	}
	self.newcanvasmanagergui := function(parent=F, show=T,
					     hasdismiss=F, hasdone=F,
					     widgetset=unset) {
	    
	    if (is_agent(its.canvasmanager)) {
		return its.canvasmanager.gui(parent, show, hasdismiss,
					     hasdone, widgetset);
	    } else {
		note(spaste('A viewercanvasmanager is not available'),
		     origin=spaste(its.viewer.title(), ' (viewer.g)'),
		     priority='SEVERE');
	    }
	}
    }
    ############################################################
    ## DISPLAYDATA HANDLING                                   ##
    ############################################################
    if (its.holdsdata) {
	its.finddisplaydata := function(displaydata, reget=F) {
	    wider its;
	    if (reget) {
		its.getdisplaydatas();
	    }
	    it := F;
	    for (i in field_names(its.displaydatas)) {
		if (its.displaydatas[i].name() == displaydata.name()) {
		    it := i;
		    break;
		}
	    }
	    return it;
	}
	its.hiddendds := [=];
	its.hashiddendds := function(displaydata) {
	    tmp := displaydata.name();
	    if (len(its.hiddendds) > 0) {
		for (str in field_names(its.hiddendds)) {
		    if (str == spaste(tmp,'zy')) {
			if (is_agent(its.hiddendds[str])) {
			    return T;
			}
		    }
		}
	    }
	    return F;
	}

	its.createslicedds := function(displaydata) {
	    wider its;
	    axisnames := displaydata.getoptions().xaxis.popt;
	    zlength := displaydata.zlength();
	    if (len(axisnames) >= 3 && zlength > 1) {
		fname := displaydata.filename();
		id := displaydata.name();
		displaytype := displaydata.displaytype();
		datatype := displaydata.datatype();
		its.viewer.hold();
		opt := displaydata.getoptions();
		newopt := [=];
		for (str in field_names(opt)) {
		    if (str != "region") {
			newopt[str] := opt[str];
		    }
		}
		# ZY 
		newopt.xaxis.value := axisnames[3];
		newopt.yaxis.value := axisnames[2];
		newopt.zaxis.value := axisnames[1];
		its.hiddendds[spaste(id,'zy')] :=
		    its.wdgts.displaydata(displaytype,fname,datatype);
		t := its.hiddendds[spaste(id,'zy')]->setoptions(newopt);

		#XZ
		newopt.xaxis.value := axisnames[1];
		newopt.yaxis.value := axisnames[3];
		newopt.zaxis.value := axisnames[2];
		its.hiddendds[spaste(id,'xz')] :=
		    its.wdgts.displaydata(displaytype,fname,datatype);
		t := its.hiddendds[spaste(id,'xz')]->setoptions(newopt);
		
		whenever displaydata.ddproxy()->motion do {
		    its.worldcanvasid := 
			its.gui.slicepanel->status().worldcanvasid;
		} its.pushwhenever();
		whenever its.hiddendds[spaste(id,'zy')]->motion do {
		    its.worldcanvasid := 
			its.gui.slicepanel->status().worldcanvasid;
		    its.viewer.motioneventhandler(id, $value);
		} its.pushwhenever();
		whenever its.hiddendds[spaste(id,'xz')]->motion do {
		    its.worldcanvasid := 
			its.gui.slicepanel->status().worldcanvasid;
		    its.viewer.motioneventhandler(id, $value);
		} its.pushwhenever();
		whenever displaydata->options do {
		    rec := $value;
		    rec1 := [=];
		    for (i in field_names(rec)) {
			unwanted := "xaxis yaxis zaxis region";
			if (all(unwanted != i)) {
			    rec1[i] := rec[i];
			}	   
		    }
		    #remove axis fields
		    its.hiddendds[spaste(id,'zy')]->setoptions(rec1);
		    its.hiddendds[spaste(id,'xz')]->setoptions(rec1);
		} its.pushwhenever();

		its.viewer.release();
	    }	   	    
	}
	its.lastdisplaydata := [=];
	self.register := function(displaydata) {	    
	    wider its;
	    # we need reget=T because in general an emitted event won't
	    # get here before the register command...
	    it := its.finddisplaydata(displaydata, reget=T);
	    if (is_boolean(it)) {
		return throw('Couldn\'t find displaydata to register');
	    }
	    if (!its.registrationflags[it]) {
		its.viewer.disable();
		its.viewer.hold();
		its.createslicedds(displaydata);
		if (its.hashiddendds(displaydata)) {
		    rec := [=];
		    rec[1] := displaydata.ddproxy();
		    rec[2] := its.hiddendds[spaste(displaydata.name(),'zy')];
		    rec[3] := its.hiddendds[spaste(displaydata.name(),'xz')];
		    t := its.gui.slicepanel->add(rec);
		    its.registrationflags[it] := T;
		    its.lastdisplaydata := [=];
		    its.lastdisplaydata[it] := T;
		    its.emitdisplaydatas();
		} else {
		    its.registrationflags[it] := F;		    
		    its.viewer.release();
		    its.viewer.enable();
		    return throw('Only cubes can be displayed on this panel.');
		}
		its.viewer.release();
		its.viewer.enable();
		# return T to indicate displaydata was registered
		return T;
	    }
	    # return F to indicate nothing was done
	    return F;
	}
	self.unregister := function(displaydata) {
	    
	    wider its;
	    # we need reget=T because in general an emitted event won't
	    # get here before the unregister command...
	    it := its.finddisplaydata(displaydata, reget=T);
	    if (is_boolean(it)) {
		return throw('Couldn\'t find displaydata to unregister');
	    }
	    if (its.registrationflags[it]) {
		its.viewer.disable();
		its.viewer.hold();		
		if (its.hashiddendds(displaydata)) {
		    rec := [=];
		    rec[1] := displaydata.ddproxy();
		    rec[2] := its.hiddendds[spaste(displaydata.name(),'zy')];
		    rec[3] := its.hiddendds[spaste(displaydata.name(),'xz')];
		    t := its.gui.slicepanel->remove(rec);
		    its.hiddendds[spaste(displaydata.name(),'zy')] := F
		    its.hiddendds[spaste(displaydata.name(),'xz')] := F
		    its.registrationflags[it] := F;
		    its.lastdisplaydata := [=];
		    its.lastdisplaydata[it] := F;           
		    its.emitdisplaydatas();
		}		
		its.viewer.release();
		its.viewer.enable();
		# return T to indicate displaydata was unregistered
		return T;
	    } 
	    # return F to indicate nothing was done
	    return F;
	}
	self.isregistered := function(displaydata) {
	    
	    wider its;
	    if (!has_field(displaydata, 'type') ||
		displaydata.type() != 'viewerdisplaydata') {
		return throw(spaste('Invalid displaydata given to ',
				    'viewerdisplaypanel.isregistered'));
	    }
	    it := its.finddisplaydata(displaydata, reget=F);
	    if (!is_boolean(it)) {
		return its.registrationflags[it];
	    } else {
		return throw(spaste('Unknown displaydata given to ',
				    'viewerdisplaypanel.isregistered'));
	    }
	}

	self.unregisterall := function() {
	    
	    its.viewer.hold();
	    for (i in field_names(its.displaydatas)) {
		if (its.registrationflags[i]) {
		    self.unregister(its.displaydatas[i]);
		}
	    }
	    its.viewer.release();
	    return T;
	}
	self.registerednames := function(ignore=[]) {
	    
	    wider its;
	    result := "";
	    its.getdisplaydatas();
	    for (i in field_names(its.displaydatas)) {
		if (its.registrationflags[i]) {
		    if (!any(its.displaydatas[i].classtype() == ignore)) {
			if (len(result) == 0) {
			    result := [its.displaydatas[i].name()];
			} else {
			    result := [result, its.displaydatas[i].name()];
			}
		    }
		}
	    }
	    return result;
	}
	self.precompute := function() {
	    self.disable();
	    for (str in its.registrationflags) {
		if (its.registrationflags[str]) {
		    t:= its.gui.slicepanel->precompute();
		    break;
		}
	    }	    
	    self.enable();
	}
	
	self.unzoom := function() {
	    t := its.gui.slicepanel->unzoom();
	    return T;
	}
	
	self.setzoom := function(blc, trc) {
	    if ((len(blc) != 2) || (len(trc) != 2)) {
		fail 'blc & trc must each be of length 2 in setzoom';
	    }
	    t := its.gui.slicepanel->setzoom(blc[1], blc[2], trc[1], trc[2]);
	    return T;
	}

	self.zoom := function(xfac=2.0, yfac=unset) {
	    
	    if (is_unset(yfac)) {
		yfac := xfac;
	    }
	    wcst := self.status().paneldisplay;
	    cx1 := wcst.linearblc[1];
	    cy1 := wcst.linearblc[2];
	    cx2 := wcst.lineartrc[1];
	    cy2 := wcst.lineartrc[2];
	    nx1 := cx1 + ((cx2 - cx1) - (cx2 - cx1) / xfac) / 2.0;
	    nx2 := cx2 - ((cx2 - cx1) - (cx2 - cx1) / xfac) / 2.0;
	    ny1 := cy1 + ((cy2 - cy1) - (cy2 - cy1) / yfac) / 2.0;
	    ny2 := cy2 - ((cy2 - cy1) - (cy2 - cy1) / yfac) / 2.0;
	    return self.setzoom([nx1, ny1], [nx2, ny2]);
	}

	its.displaydataguis := [=];
	self.adjust := function(displaydata=F) {
            wider its;
            if (is_boolean(displaydata)) {
                for (i in field_names(its.registrationflags)) {
                    if ((its.registrationflags[i]) && 
                        is_agent(its.displaydatas[i])) {
                        if (has_field(its.displaydataguis, i) &&
                            is_agent(its.displaydataguis[i])) {
                            its.displaydataguis[i].unmap();
                            its.displaydataguis[i].map();
                        } else {
                            its.displaydataguis[i] := 
                                its.displaydatas[i].
                                    newdisplaydatagui(hasdismiss=T);
                        }
                    }
                }
            } else {
                #tbi: add a check if the displaydata name given is valid
                if (!is_string(displaydata)) {
                    return F;
                }
                if (has_field(its.displaydataguis, displaydata) &&
                    is_agent(its.displaydataguis[displaydata])) {
                    its.displaydataguis[displaydata].unmap();
                    its.displaydataguis[displaydata].map();
                } else {
                    its.displaydataguis[displaydata] := 
                        its.displaydatas[displaydata].
                            newdisplaydatagui(hasdismiss=T);                
                }
            }
        }

	its.displaydatas := its.viewer.alldisplaydatas();
	its.registrationflags := [=];
	self.registrationflags := function() {
	    
	    return its.registrationflags;
	}
	for (i in field_names(its.displaydatas)) {
	    its.registrationflags[i] := F;
	}
	its.getdisplaydatas := function(newdisplaydata=F) {
	    wider its;
	    if (is_boolean(newdisplaydata)) {
		newdisplaydata := its.viewer.alldisplaydatas();
	    }
	    for (i in field_names(newdisplaydata)) {
		if (has_field(its.displaydatas, i) && 
		    its.registrationflags[i]) {
		    its.registrationflags[i] := T;
		} else {
		    its.registrationflags[i] := F;
		}
	    }
	    its.displaydatas := newdisplaydata;
	}

	whenever its.viewer->displaydatas do {
	    its.getdisplaydatas($value);
	    its.emitdisplaydatas();
	} its.pushwhenever();

	its.emitdisplaydatas := function() {
	    self->registrationflags(its.registrationflags);
	    self->displaydatas(its.displaydatas);
	    if (is_record(its.lastdisplaydata) && 
		len(its.lastdisplaydata) > 0) {
		self->lastdisplaydata(its.lastdisplaydata);
	    }	    
	}

	self.getdisplaydatas := function() {
	    
	    its.getdisplaydatas();
	    return its.displaydatas;
	}

	## position tracking support
	self.motioneventhandler := function(ddname, motionevent) {
	    
	    if ( !any(self.worldcanvasid() == motionevent.worldcanvasid)) {
		return F;
	    }
	    if (is_agent(its.thegui) && has_field(its.thegui,
						  'motioneventhandler')) {
		its.thegui.motioneventhandler(ddname, motionevent);
	    }
	    return T;
	}

    }


    ############################################################
    ## TOOLKIT HANDLING                                       ##
    ############################################################
    ############################################################
    ## this applies toolkit "options" if relevant             ##
    ############################################################
    whenever its.viewer.toolkit()->deltatoolkit, self->deltatoolkit do {
        self.settool($value);
    } its.pushwhenever();
    self.settool := function(rec) {	
	key := rec.dlkey;
	if (rec.tool == 'Colormap fiddling - shift/slope') {
	    t := its.gui.pcanvas->standardfiddler(key);
	} else if (rec.tool == 'Colormap fiddling - brightness/contrast') {
	    t := its.gui.pcanvas->mapfiddler(key);
	} else if (rec.tool == 'Zooming') {
	    t := its.gui.slicepanel->settoolkey("zoomer", key);
	} else if (rec.tool == 'Panning') {
	    t := its.gui.slicepanel->settoolkey("panner", key);
	} else if (rec.tool == 'Positioning') {
	    t := its.gui.slicepanel->settoolkey("positioner", key);
	} else if (rec.tool == 'Rectangle drawing') {
	    t := its.gui.slicepanel->settoolkey("rectangle", key);
	} else if (rec.tool == 'Polygon drawing') {
	    t := its.gui.slicepanel->settoolkey("polygon", key);
	} else if (rec.tool == 'Multipanel crosshair') {
	    t := its.gui.slicepanel->settoolkey("slice", key);
	}
    }
    ############################################################
    ## update the local toolkit options according to viewer  ##
    ############################################################
    temp := its.viewer.toolkit().toolkitlist();
    for (i in temp.tools) {
	rec.tool := i;
	rec.dlkey := temp.dlkeyopts[temp.keyopts==temp.keys[i==temp.tools]];
	self.settool(rec);
    }


    if (its.show) {
	t := self.map();
    }

    t := its.viewer.registerdisplaypanel(self);
    if (is_fail(t)) {
	self.done();
	return throw(t::message);
    }

    ## ************************************************************ ##
    ##                                                              ##
    ## VIEWERDISPLAYPANELGUI SUBSEQUENCE                            ##
    ##                                                              ##
    ## ************************************************************ ##
    its.viewerdisplaypanelgui := subsequence(displaypanel, guihasmenubar=T,
					     guihascontrolbox=T, 
					     guihasbuttons=T, 
					     guihastracking=T,
					     hasdismiss=unset,
					     hasdone=unset, 
					     isolationmode=F, show=T) {
	
	
	############################################################
	## SANITY CHECK                                           ##
	############################################################
	if (!is_record(displaypanel) || !has_field(displaypanel, 'type') ||
	    (displaypanel.type() != 'viewerdisplaypanel')) {
	    return throw(spaste('An invalid viewerdisplaypanel was given to ',
				'a viewerdisplaypanelgui'));
	}

	# deal with unset hasdone, hasdismiss
	if (is_unset(hasdone)) {
	    if (is_unset(hasdismiss)) {
		hasdone := T;
		hasdismiss := F;
	    } else {
		hasdone := !hasdismiss;
	    }
	} else if (is_unset(hasdismiss)) {
	    hasdismiss := !hasdone;
	}
	if (hasdone && hasdismiss) {
	    note(spaste('An attempt was made to adorn a viewerdisplaypanel ',
			'with both Dismiss AND Done buttons'));
	    hasdismiss := F;
	}

	############################################################
	## INITIALISE AND STORE CONSTRUCTOR ARGUMENTS             ##
	############################################################
	its := [=];
	its.displaypanel := displaypanel;
	its.guihasmenubar := guihasmenubar;
	its.guihascontrolbox := guihascontrolbox;
	its.guihasbuttons := guihasbuttons;
	its.guihastracking := guihastracking;
	its.hasdismiss := hasdismiss;
	its.hasdone := hasdone;
	its.isolationmode := isolationmode;
	
	############################################################
	## BASIC SERVICES                                         ##
	############################################################
	its.type := 'viewerdisplaypanel';
	self.type := function() {
	    return its.type;
	}
	
	its.viewer := its.displaypanel.viewer();
	self.viewer := function() {
	    
	    return its.viewer;
	}
	
	its.wdgts := its.displaypanel.widgetset();
	
	############################################################
	## WHENEVER PUSHER                                        ##
	############################################################
	its.whenevers := [];
	its.pushwhenever := function() {
	    wider its;
	    its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
	}
	const its.deactivate := function(which) {
	    if (is_integer(which)) {
		n := length(which);
		if (n>0) {
		    for (i in 1:n) {
			ok := whenever_active(which[i]);
			if (is_fail(ok)) {
			} else {
			    if (ok) deactivate which[i];
			}
		    }
		}
	    }
	return T;
	}
	############################################################
	## DONE FUNCTION                                          ##
	############################################################
	its.dying := F;
	self.done := function() {	    
	    wider its, self;
	    if (its.dying) {
		# prevent multiple done requests
		return F;
	    } its.dying := T;
		
	    if (len(its.whenevers) > 0) {
		its.deactivate(its.whenevers);
	    }

	    if (has_field(its.gui, 'tlktmenu')) {
		its.gui.tlktmenu.menu.done();
	    }
	    if (its.guihascontrolbox) {
		its.gui.controlbox.done();
	    }
	    
	    if (is_agent(its.gui.dpmenu)) {
		its.gui.dpmenu.done();
	    }
	    if (is_record(its.gui.trkmlines) && len(its.gui.trkmlines) > 0) {
		for (str in field_names(its.gui.trkmlines)) {
		    if (is_agent(its.gui.trkmlines[str])) {
			its.gui.trkmlines[str]:=F;
		    }
		}
	    }
	    # disable until fully understood- cause crash on multiple display
	    # panels ???
	    #if (is_record(its.gui)) {
		#for (str in field_names(its.gui)) {
		    #its.wdgts.popupremove(its.gui[str]);
		#}
	    #}
	    val its := F;
	    val self := F;
	    return T;
	}
	
	############################################################
	## CONSTRUCT FRAMES THAT ARE NEEDED                       ##
	############################################################
	its.gui.upperframe := its.displaypanel.upperframe();
	its.gui.lowerframe := its.displaypanel.lowerframe();
	its.displaypanel.unmap();
	
	if (its.guihasmenubar) {
	    its.gui.menubar := its.wdgts.frame(its.gui.upperframe, 
					       side='left', 
					       relief='raised', expand='x');
	    ############################################################
	    ## WINDOW MENU AND OPERATIONS                             ##
	    ############################################################
	    its.gui.wndwmenu.menu := its.wdgts.button(its.gui.menubar, 'File',
						      type='menu', 
						      relief='flat');
	    if (!its.isolationmode) {
		its.gui.dpmenu := viewerdpmenu(its.gui.wndwmenu.menu,
					       its.viewer);
		its.gui.wndwmenu.spacer0 := 
		    its.wdgts.button(its.gui.wndwmenu.menu, 
				     '---------------------------------');
		t := its.gui.wndwmenu.spacer0->disabled(T);

		its.gui.wndwmenu.newpanl := 
		    its.wdgts.button(its.gui.wndwmenu.menu, 'Data manager');
		whenever its.gui.wndwmenu.newpanl->press do {
		    its.viewer.newdatamanager(hasdone=T);
		} its.pushwhenever();
	    }

	    its.gui.wndwmenu.newcmap := 
		its.wdgts.button(its.gui.wndwmenu.menu, 'Colormap manager');
	    whenever its.gui.wndwmenu.newcmap->press do {
		its.viewer.newcolormapmanagergui(hasdone=T);
	    } its.pushwhenever();
	    
	    its.gui.wndwmenu.canmang := its.wdgts.button(its.gui.wndwmenu.menu,
							 'Canvas manager');
	    whenever its.gui.wndwmenu.canmang->press do {
		its.displaypanel.newcanvasmanagergui(hasdone=T);
	    } its.pushwhenever();
	    
	    if (its.hasdismiss || its.hasdone || !its.isolationmode) {
		its.gui.wndwmenu.spacer2 := 
		    its.wdgts.button(its.gui.wndwmenu.menu, 
				     '---------------------------------');
		t := its.gui.wndwmenu.spacer2->disabled(T);
	    }		

	    if (its.hasdismiss) {
		its.gui.wndwmenu.dismiss := 
		    its.wdgts.button(its.gui.wndwmenu.menu, 'Dismiss window', 
				     type='dismiss');
		whenever its.gui.wndwmenu.dismiss->press do {
		    its.displaypanel.dismiss();
		} its.pushwhenever();
	    }
	    if (its.hasdone) {
		its.gui.wndwmenu.done := 
		    its.wdgts.button(its.gui.wndwmenu.menu, 
				     'Display Panel - Done', 
				     type='halt');
		whenever its.gui.wndwmenu.done->press do {
		    its.displaypanel.done();
		} its.pushwhenever();
	    }
	    if (!its.isolationmode) {
		its.gui.wndwmenu.bexit := 
		    its.wdgts.button(its.gui.wndwmenu.menu, 'Done',
				     type='halt');
		whenever its.gui.wndwmenu.bexit->press do {
		    its.viewer.done();
		} its.pushwhenever();
	    }	    
	    
	    ############################################################
	    ## DISPLAYDATA MENU AND OPERATIONS                        ##
	    ############################################################
	    its.datamenu.menu := its.wdgts.button(its.gui.menubar, 
 						  'DisplayData', 
						  type='menu', relief='flat');
	    its.datamenu.regmenu := its.wdgts.button(its.datamenu.menu,
						     'Register...', 
						     type='menu',
						     relief='flat');
	    its.datamenu.adjmenu := its.wdgts.button(its.datamenu.menu,
						     'Adjust...', 
						     type='menu',
						     relief='flat');
	    its.datamenu.delmenu := its.wdgts.button(its.datamenu.menu,
						     'Remove...', 
						     type='menu',
						     relief='flat');

	    its.displaydatas := F;
	    its.registrationflags := F;
	    whenever its.displaypanel->registrationflags do {
		its.registrationflags := $value;
	    } its.pushwhenever();
	    its.datamenu.items := [=];
	    its.datamenu.delitems := [=];
	    its.datamenu.adjitems := [=];
	    whenever its.displaypanel->displaydatas do {
		newdisplaydata := $value;
		# then rebuild our menu...
		if (is_record(its.datamenu.items)) {
		    its.wdgts.tk_hold();
		    if (len(its.datamenu.items) > 1) {
			its.datamenu.extra.unregisterall := F;
			its.datamenu.extra.registerall := F;
			t := its.datamenu.extra.regspacer->disabled(F);
			its.datamenu.extra.regspacer := F;
                       # delete
                        its.datamenu.extra.deleteall := F;
                        t := its.datamenu.extra.delspacer->disabled(F);
                        its.datamenu.extra.delspacer := F;

			its.datamenu.extra := F;
		    }
		    if (len(its.datamenu.items) >= 1) {
			for (i in len(its.datamenu.items):1) {
			    its.datamenu.items[i] := 0;
			    its.datamenu.delitems[i] := 0;
			    its.datamenu.adjitems[i] := 0;
			}
		    }
		    its.datamenu.items := [=]; 
		    its.datamenu.adjitems := [=];
		    its.datamenu.delitems := [=];
		    its.wdgts.tk_release();
		}
		its.displaydatas := newdisplaydata;
 		its.wdgts.tk_hold();
		#delete submenu
		for (i in field_names(its.displaydatas)) {
		    its.datamenu.delitems[i] := 
			its.wdgts.button(its.datamenu.delmenu, 
					 its.displaydatas[i].name(),
					 value=i);
		}
		#adjust submenu
		for (i in field_names(its.displaydatas)) {
		    its.datamenu.adjitems[i] := 
			its.wdgts.button(its.datamenu.adjmenu, 
					 its.displaydatas[i].name(),
					 value=i);
		}

		#register submenu
		for (i in field_names(its.displaydatas)) {
		    its.datamenu.items[i] := 
			its.wdgts.button(its.datamenu.regmenu, 
					 its.displaydatas[i].name(),
					 type='check', value=i);
		}
		if (len(its.datamenu.items) > 1) {
		    #delete
                     its.datamenu.extra.delspacer := 
                         its.wdgts.button(its.datamenu.delmenu,
                                          '---------------------------------');
                     t := its.datamenu.extra.delspacer->disabled(T);
                     its.datamenu.extra.deleteall := 
                         its.wdgts.button(its.datamenu.delmenu, 'Remove all');
                     whenever its.datamenu.extra.deleteall->press do {
                         its.viewer.hold();
                         for (i in field_names(its.displaydatas)) {
                             its.viewer.deletedata(its.displaydatas[i]);
                         }
                         its.viewer.release();
                     } #its.pushwhenever();
		     #register
		    its.datamenu.extra.regspacer := 
			its.wdgts.button(its.datamenu.regmenu,
					 '---------------------------------');
		    t := its.datamenu.extra.regspacer->disabled(T);
		    its.datamenu.extra.registerall := 
			its.wdgts.button(its.datamenu.regmenu, 'Register all');
		    whenever its.datamenu.extra.registerall->press do {
			its.viewer.hold();
			for (i in field_names(its.displaydatas)) {
			    if (!its.registrationflags[i]) {
				its.displaypanel.register(its.displaydatas[i]);
			    }
			}
			its.viewer.release();
		    } #its.pushwhenever();
		    its.datamenu.extra.unregisterall := 
			its.wdgts.button(its.datamenu.regmenu, 'Unregister all');
		    whenever its.datamenu.extra.unregisterall->press do {
			its.displaypanel.unregisterall();
		    } #its.pushwhenever();
		} 
		
		its.wdgts.tk_release();
		#register submenu
		for (i in field_names(its.datamenu.items)) {
		    if (its.registrationflags[i]) {
			t := its.datamenu.items[i]->state(T);
		    } else {
			t := its.datamenu.items[i]->state(F);
		    }
		    whenever its.datamenu.items[i]->press do {
			if (its.datamenu.items[i]->state()) {
			    t :=its.displaypanel.
				register(its.displaydatas[$value]);
			    if (!its.registrationflags[$value]) {
				t := its.datamenu.items[$value]->state(F);
			    }
			} else {
			    its.displaypanel.
				unregister(its.displaydatas[$value]);
			}
		    } #its.pushwhenever();
		}
		#adjust submenu
		for (i in field_names(its.datamenu.adjitems)) {
		    whenever its.datamenu.adjitems[i]->press do {
			if (its.registrationflags[$value]) {
			    t := its.displaypanel.adjust($value);
			}
		    } #its.pushwhenever();
		}
		#delete submenu
		for (i in field_names(its.datamenu.delitems)) {
		    whenever its.datamenu.delitems[i]->press do {
			its.viewer.deletedata(its.displaydatas[$value]);
		    } #its.pushwhenever();
		}	
	    } its.pushwhenever();
	    
	    its.viewer.emitdisplaydatalist();
	    
	    ## right hand menubar, Help:
	    its.gui.rightmbar := its.wdgts.frame(its.gui.menubar,
						 side='right', expand='x');
	    its.gui.helpm.menu := its.wdgts.button(its.gui.rightmbar,
						   text='Help', type='menu');
            its.gui.helpm.viewerref := its.wdgts.button(its.gui.helpm.menu,
                                                     text='Viewer reference manual');
            whenever its.gui.helpm.viewerref->press do {
                oktmp := eval('include \'aips2help.g\'');
                if (oktmp) {
                    x := help('Refman:display.viewer');
                }
            } its.pushwhenever();
            its.gui.helpm.viewergr := its.wdgts.button(its.gui.helpm.menu,
                                                     text='Viewer introduction');
            whenever its.gui.helpm.viewergr->press do {
                oktmp := eval('include \'aips2help.g\'');
                if (oktmp) {
                    x := help('gettingresults:viewer');
                }
            } its.pushwhenever();

	    its.gui.helpm.popup := its.wdgts.popupmenu(its.gui.helpm.menu, 1);
	    its.gui.helpm.refman := its.wdgts.button(its.gui.helpm.menu, 
					       text='Reference Manual');
	    whenever its.gui.helpm.refman->press do {
		oktmp := eval('include \'aips2help.g\'');
		if (oktmp) {
		    x := help('Refman');
		}
	    } its.pushwhenever();
	    its.gui.helpm.about := its.wdgts.button(its.gui.helpm.menu, 
					      text='About Aips++');
	    whenever its.gui.helpm.about->press do {
		oktmp := eval('include \'about.g\'');
		if (oktmp) {
		    x := about();
		}
	    } its.pushwhenever();
	    its.gui.helpm.ask := its.wdgts.button(its.gui.helpm.menu, 
					    text='Ask a question');
	    whenever its.gui.helpm.ask->press do {
		oktmp := eval('include \'askme.g\'');
		if (oktmp) {
		    x := askme();
		}
	    } its.pushwhenever();
	    its.gui.helpm.bug := its.wdgts.button(its.gui.helpm.menu, 
					    text='Report a bug');
	    whenever its.gui.helpm.bug->press do {
		oktmp := eval('include \'bug.g\'');
		if (oktmp) {
		    x := bug();
		}
	    } its.pushwhenever();
	    
	}

	if (its.guihascontrolbox) {
	    ############################################################
	    ## CONTROLBOX BUTTONS - LEFT FRAME                        ##
	    ############################################################
	    its.gui.lframe := its.displaypanel.leftframe();
	    its.gui.ulframe := its.wdgts.frame(its.gui.lframe, side='top',
					       relief='flat', borderwidth=0,
					       padx=0, pady=0, expand='y');
	    tools := "multicrosshair zoom pan standardcolormap mapcolormap";
	    
	    if ((its.displaypanel.status().maptype == 'hsv') ||
		(its.displaypanel.status().maptype == 'rgb')) {
		tools := "multicrosshair zoom pan";# pan position rectangle polygon";
	    }
	    rec := [=];
	    rec.tool := 'Multipanel crosshair';
	    rec.key := 'Button 1';
	    its.viewer.toolkit().toolkitchange(rec);
	    rec.tool := 'Zooming';
	    rec.key := 'Button 3';
	    its.viewer.toolkit().toolkitchange(rec);
	    its.gui.controlbox := its.viewer.toolkit().
		controlbox(its.gui.ulframe, tools);
	    
	}

	if (its.guihastracking) {
	    ############################################################
	    ## TRACKING                                               ##
	    ############################################################

	    # a frame to put messagelines in
	    its.gui.trkbar := its.wdgts.frame(its.gui.lowerframe,
					      side='top',
					      height=1, relief='flat', 
					      expand='both', borderwidth=0,
					      padx=0, pady=0);

	    # a function to provide requested number of messagelines
	    its.gui.trkmlines := [=];
	    self.maketrackmessagelines := function(messagelinenames) {
		
		wider its;
		its.displaypanel.viewer().hold();
		its.wdgts.tk_hold();
		for (i in field_names(its.gui.trkmlines)) {
		    its.gui.trkmlines[i]:=F;
		}
		its.gui.trkmlines := [=];
		for (i in messagelinenames) {
		    local hlptext := spaste(i, ' data');
		    its.gui.trkmlines[i] :=
			its.wdgts.message(its.gui.trkbar, font='bold',
					  text='no position to report',
					  aspect=100000, anchor='nw',
					  justify='left', relief='sunken',
					  fill='both');
		}
		its.wdgts.tk_release();
		its.displaypanel.viewer().release();
		return T;
	    }
	    whenever its.displaypanel->registrationflags do {
		tmp := its.displaypanel.registerednames(ignore=
                    [Display::Annotation, Display::CanvasAnnotation]);
		self.maketrackmessagelines(tmp);
	    } its.pushwhenever();

	    self.motioneventhandler := function(ddname, motionevent) {
		
		wider its;
		if (has_field(its.gui.trkmlines, ddname)) {
		    msg:=spaste(motionevent.formattedvalue, ' at ',
				motionevent.formattedworld);
		    its.gui.trkmlines[ddname]->text(msg);
		}
	    }
	}
	its.gui.btnbar := its.wdgts.frame(its.gui.lowerframe, side='left',
					  height=1, relief='flat', expand='x',
					  borderwidth=0, padx=0, pady=0);
	if (its.guihasbuttons) {
	    ############################################################
	    ## BUTTONS                                                ##
	    ############################################################
	    its.gui.lftbtnbar := its.wdgts.frame(its.gui.btnbar, side='left', 
						 height=1,
						 relief='flat', expand='x',
						 borderwidth=0, padx=0, pady=0);
	    ## adjust displaydata settings
	    its.gui.btnbar.badjust := its.wdgts.button(its.gui.lftbtnbar,
						       'Adjust...');
	    its.wdgts.popuphelp(its.gui.btnbar.badjust, 
				txt=spaste('Press this button to show a gui ',
					   'which let\'s you adjust ',
					   'display properties of the image/s ',
					   '(eg. colormap,axis labels).'),
				hlp='Show adjustment panel/s');
	    whenever its.gui.btnbar.badjust->press do {
		its.displaypanel.adjust();
	    } its.pushwhenever();
	    ## unzoom the displaypanel
	    its.gui.btnbar.bunzoom := its.wdgts.button(its.gui.lftbtnbar,
						       'Unzoom');
	    t := its.gui.btnbar.bunzoom->disable();
	    its.wdgts.popuphelp(its.gui.btnbar.bunzoom, 
		      txt=spaste('Press this button to unzoom the ',
				 'displaypanel, ie. to show the entire image'),
		      hlp='Unzoom the view');
	    whenever its.gui.btnbar.bunzoom->press do {
		its.displaypanel.unzoom();
	    } its.pushwhenever();
	    ## clear the displaypanel
	    its.gui.btnbar.bclear := its.wdgts.button(its.gui.lftbtnbar, 
						      'Clear');
	    its.wdgts.popuphelp(its.gui.btnbar.bclear,
		      txt=spaste('Press this button to clear the ',
				 'displaypanel - ',
				 'this will unregister all displaydatas from ',
				 'the panel'),
		      hlp='Clear the displaypanel of data');
	    whenever its.gui.btnbar.bclear->press do {
		its.displaypanel.unregisterall();
	    } its.pushwhenever();
	    ## print
	    its.gui.btnbar.bload := its.wdgts.button(its.gui.lftbtnbar, 
						      'Preload');
	    its.wdgts.popuphelp(its.gui.btnbar.bload,
		      txt=spaste('Press this button to preload the  ',
				 'images. This can take a while, but speeds ',
				 'up the crosshair.'),
		      hlp='Preload images into memory');
	    whenever its.gui.btnbar.bload->press do {
		t := its.displaypanel.precompute();
	    } its.pushwhenever();
	}

	its.gui.rgtbtnbar := its.wdgts.frame(its.gui.btnbar, side='right', 
					     height=1, relief='flat', 
					     expand='x',
					     borderwidth=0, padx=0, pady=0);
	if (its.hasdone) {
	    its.gui.btnbar.bdone := its.wdgts.button(its.gui.rgtbtnbar,
						     'Done', 
						     type='halt');
	    its.wdgts.popuphelp(its.gui.btnbar.bdone,
		      txt=spaste('Press this button to be finished with this ',
				 'displaypanel - you can always get another ',
				 'one back!'),
		      hlp='Finish with this displaypanel');
	    whenever its.gui.btnbar.bdone->press do {
		its.displaypanel.done();
	    } its.pushwhenever();
	}
	if (its.hasdismiss) {
	    its.gui.btnbar.bdismiss := its.wdgts.button(its.gui.rgtbtnbar, 
							'Dismiss', 
							type='dismiss');
	    its.wdgts.popuphelp(its.gui.btnbar.bdismiss,
		      txt=spaste('Press this button to hide this ',
				 'displaypanel - ',
				 'you can probably retrieve it later via the ',
				 'application you are using, or via the ',
				 'command line'),
		      hlp='Hide this displaypanel');
	    whenever its.gui.btnbar.bdismiss->press do {
		its.displaypanel.dismiss();
	    } its.pushwhenever();
	}
	
	############################################################
	## RESPONSE TO EVENTS FROM THE DISPLAYPANEL               ##
	############################################################
	#whenever its.displaypanel->object_lists do {
	#    newlists := $value;
	#    if (has_field(newlists, 'colormap')) {
	#	 its.cmapmenu.update(newlists.colormap);
	#    }
	#    if (has_field(newlists, 'displaydata')) {
	#	 its.datamenu.func.update(newlists.displaydatas);
	#    }
	#} its.pushwhenever();	
	if(show) t := its.displaypanel.map();
    }
    
}
