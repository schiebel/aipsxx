# viewerdisplaypanel.g: provision of (pdisplay)canvases for the viewer
# Copyright (C) 1999,2000,2001,2002,2003
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
include 'viewerdisplaydata.g';
include 'timer.g';
include 'aipsrc.g';
include 'viewerannotations.g';

## ************************************************************ ##
##                                                              ##
## VIEWERDISPLAYPANEL SUBSEQUENCE                               ##
##                                                              ##
## ************************************************************ ##
viewerdisplaypanel := subsequence(parent=F, viewer, width=375,
				  height=350, nx=1, ny=1,
				  maptype='index',
				  newcmap=F, mincolors=unset,
				  maxcolors=unset,
				  autoregister=F, holdsdata=T, 
				  show=T,
				  widgetset=unset) {
    __VCF_('viewerdisplaypanel');
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
    its.nxpanels := nx;#
    its.nypanels:= ny;#
    its.viewer := viewer;
    its.width := width;
    its.height := height;
    its.maptype := maptype;
    its.newcmap := newcmap;
    its.mincolors := mincolors;
    its.maxcolors := maxcolors;
    its.autoregister := autoregister;
    its.holdsdata := holdsdata;
    its.annotationdd := F;
    its.viewerannot := F;
    its.show := show;
    its.wdgts := widgetset;
    if (its.holdsdata) {
	 its.nwedges := 0;
	 its.gui.wedgecanvi := [=];
	 its.wedgeddds := [=];
	 its.wedgeorientation := 'vertical';
    }
    ############################################################
    ## BASIC SERVICES                                         ##
    ############################################################
    its.type := 'viewerdisplaypanel';
    self.type := function() {
	__VCF_('viewerdisplaypanel.type');
	return its.type;
    }

    self.viewer := function() { 
	__VCF_('viewerdisplaypanel.viewer');
	return its.viewer;
    }

    self.pixelcanvasproxy := function() {
	return its.gui.pcanvas;
    }

    if (is_unset(its.wdgts)) {
	its.wdgts := its.viewer.widgetset();
    }

    self.widgetset := function() {
	__VCF_('viewerdisplaypanel.widgetset');
	wider its;
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
    ## MAP/UNMAP CONTAINER OF GUI                             ##
    ############################################################
    its.ismapped := F;
    self.map := function(force=F) {
	__VCF_('viewerdisplaypanel.map');
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
	__VCF_('viewerdisplaypanel.unmap');
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
    self.ismapped := function() {
	__VCF_('viewerdisplaypanel.ismapped');
	return its.ismapped;
    }

    self.hold := function() {
	__VCF_('viewerdisplaypanel.hold');
	if (has_field(its, 'gui')) {
	    if (has_field(its.gui, 'pcanvas') && is_agent(its.gui.pcanvas)) {
		its.gui.pcanvas->hold();
	    }
	    if (has_field(its.gui, 'pdisplay') && is_agent(its.gui.pdisplay)) {
		its.gui.pdisplay->hold();
	    }
	    if (its.holdsdata) {
		if (its.nwedges > 0 ) {
		    for (i in 1:its.nwedges) {
			if (is_agent(its.gui.wedgecanvi[i])) {
			    its.gui.wedgecanvi[i]->hold();
			}
		    }
		}
	    }
	}
	return T;
    }
    self.release := function() {
	__VCF_('viewerdisplaypanel.release');
	if (has_field(its, 'gui')) {
	    if (has_field(its.gui, 'pcanvas') && is_agent(its.gui.pcanvas)) {
		its.gui.pcanvas->release();
	    }
	    if (has_field(its.gui, 'pdisplay') && is_agent(its.gui.pdisplay)) {
		its.gui.pdisplay->release();
	    }

	    if (its.holdsdata) {
		if (its.nwedges > 0 ) {
		    for (i in 1:its.nwedges) {
			if (is_agent(its.gui.wedgecanvi[i])) {
			    its.gui.wedgecanvi[i]->release();
			}
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
    self.dying := function() {
	__VCF_('viewerdisplaypanel.dying');
	return its.dying;
    }
    self.done := function() {
	__VCF_('viewerdisplaypanel.done');
	wider its, self;
	if (its.dying) {
	    # prevent multiple done requests.
	    return F;
	} its.dying := T;
	if (viewer::tracedone) {
	    print 'viewerdisplaypanel::done()';
	}
	if (len(its.whenevers) > 0) {
	    its.deactivate(its.whenevers);
	}
	self.unmap();
	if (is_agent(its.viewer)) {
	    its.viewer.hold();
	}
	
	if (its.holdsdata) {
	   
	    ## viewerannotator
	    if (is_agent(its.viewerannot)) 
		its.viewerannot.done();
	    
	    ## animator
	    if (is_agent(its.animator)) {
		its.animator.done();
	    }

	    ## canvasmanager
	    if (is_agent(its.canvasmanager)) {
		its.canvasmanager.done();
	    }

	    ## canvasprintmanager
	    if (is_agent(its.canvasprintmanager)) {
		its.canvasprintmanager.done();
	    }
	}	
	if (is_agent(self) && is_agent(its.thegui)) {
	    its.thegui.done();
	}
	if (its.holdsdata) {

	    self.disablecontrols();

	    if (len(its.displaydataguis) > 0) {
		for (i in 1:len(its.displaydataguis)) {
		    if (is_agent(its.displaydataguis[i])) {
			its.displaydataguis[i].done();
		    }
		}
	    }
	    self.unregisterall();
	    self.sneakyunregister(its.annotationdd.dddproxy());
	    if (is_agent(its.annotationdd)) {
		its.annotationdd.done();
	    }
	    val its.gui.pdisplay := F;
	}
	val its.gui.pcanvas := F;
	if (is_agent(self) && is_agent(its.viewer)) {
	    its.viewer.release();
	}
	v := ref its.viewer;
	val its := F;
	self->done();
	val self := F;

	if(has_field(v,'alldisplaypanels') && len(v.alldisplaypanels())==0) {
	   v.deleteall(doneit=T, quiet=T);  }
	   # delete all dd's if no more displaypanels.
	   
	return T;
    }

    ############################################################
    ## DISMISS FUNCTION                                       ##
    ############################################################
    self.dismiss := function() {
	__VCF_('viewerdisplaypanel.dismiss');
	return self.unmap();
    }

    ############################################################
    ## GUI FUNCTION                                           ##
    ############################################################
    self.gui := function() {
	__VCF_('viewerdisplaypanel.gui');
	return self.map();
    }
    
    ############################################################
    ## DISABLE/ENABLE THE GUI                                 ##
    ############################################################
    self.disable := function() {
	__VCF_('viewerdisplaypanel.disable');
	if (its.madeparent) {
	    t := its.parent->disable();
	    #t := its.parent->cursor('watch');
	} 
	return T;
    }
    self.enable := function() {
	__VCF_('viewerdisplaypanel.enable');
	if (its.madeparent) {
	    t := its.parent->enable();
	    #t := its.parent->cursor(its.originalcursor);
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
					 ' - Display Panel (AIPS++)'),
			    newcmap=its.newcmap);
#			    width=its.width, height=its.height,
#			    expand='none');
	its.madeparent := T;
    #} else {
    #	note(spaste('\'newcmap\' argument ignored since a parent frame was ',
    #		    'given to a viewerdisplaypanel'), 
    #	     origin=its.viewer.title(), priority='WARN');
    }
    its.originalcursor := its.parent->cursor();
    its.wholeframe := its.wdgts.frame(its.parent, side='top',
				      borderwidth=0, padx=0, pady=0);
    if (is_fail(its.wholeframe)) {
	its.wdgts.tk_release();
	return throw(spaste('Failed to construct a frame: probable ',
			    'incompatibility between widgetservers'));
    }
    self.unmap(T);
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
    its.gui.midframe_a := its.wdgts.frame(its.gui.centreframe, side='top',
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
	__VCF_('viewerdisplaypanel.upperframe');
	return its.gui.upperframe; 
    }
    self.lowerframe := function() { 
	__VCF_('viewerdisplaypanel.lowerframe');
	return its.gui.lowerframe; 
    }
    self.leftframe := function() {
	__VCF_('viewerdisplaypanel.leftframe');
	return its.gui.leftframe;
    }
    self.rightframe := function() {
	__VCF_('viewerdisplaypanel.rightframe');
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

    its.gui.midframe := its.gui.midframe_a;
    ## arrange scrollbars if required
    its.reqwidth := its.width;
    its.reqheight := its.height;
    its.aipsrc := aipsrc();
    its.aipsrc.findint(its.maxwidth, 'viewer.scrollwidth', 800);
    its.aipsrc.findint(its.maxheight, 'viewer.scrollheight', 600);
    its.aipsrc.done();
    its.horiz_sb := (its.reqwidth > its.maxwidth);
    its.verti_sb := (its.reqheight > its.maxheight);
    if (its.horiz_sb || its.verti_sb) {
	its.gui.canvasframe := its.wdgts.frame(its.gui.midframe_a,
					       side='left', borderwidth=0);
	its.canvaswidth := min(its.reqwidth, its.maxwidth);
	its.canvasheight := min(its.reqheight, its.maxheight);
	its.gui.scrollingcanvas := 
	  its.wdgts.canvas(its.gui.canvasframe,
			   region=[0,0,its.reqwidth, its.reqheight],
			   width=its.canvaswidth, height=its.canvasheight,
			   borderwidth=0);
	if (its.verti_sb) {
	    its.gui.vsb := its.wdgts.scrollbar(its.gui.canvasframe);
	    whenever its.gui.vsb->scroll do {
		its.gui.scrollingcanvas->view($value);
	    } its.pushwhenever();
	    whenever its.gui.scrollingcanvas->yscroll do {
		its.gui.vsb->view($value);
	    } its.pushwhenever();
	} 
	if (its.horiz_sb) {
	    its.gui.hsbframe := its.wdgts.frame(its.gui.midframe_a,
						side='right', borderwidth=0,
						expand='x');
	    if (its.verti_sb) {
		its.gui.hsbpad := its.wdgts.frame(its.gui.hsbframe,
						  expand='none', width=23,
						  height=23);
	    }
	    its.gui.hsb := its.wdgts.scrollbar(its.gui.hsbframe,
					       orient='horizontal');
	    whenever its.gui.hsb->scroll do {
		its.gui.scrollingcanvas->view($value);
	    } its.pushwhenever();
	    whenever its.gui.scrollingcanvas->xscroll do {
		its.gui.hsb->view($value);
	    } its.pushwhenever();
	}
	its.gui.midframe := 
	  its.gui.scrollingcanvas->frame(0, 0, borderwidth=0);
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
	__VCF_('viewerdisplaypanel.writexpm');
	if (is_agent(its.gui.pcanvas)) {
	    t := its.gui.pcanvas->writexpm(filename);
	}
	return T;
    }
    self.newcmap := function() {
	__VCF_('viewerdisplaypanel.newcmap');
	if (its.madeparent) {
	    return its.newcmap;
	} else {
	    return unset;
	}
    }

    self.autoregister := function(set=unset) {
	__VCF_('viewerdisplaypanel.autoregister');
	wider its;
	if (is_boolean(set)) {
	    its.autoregister := set;
	}
	return its.autoregister;
    }

    

    self.holdsdata := function() {
	__VCF_('viewerdisplaypanel.holdsdata');
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

    self.status := function() {
	__VCF_('viewerdisplaypanel.status');
	rec := [=];
	rec.pixelcanvas := its.gui.pcanvas->status();
	if (its.holdsdata) {
	    rec.paneldisplay := its.gui.pdisplay->status();
	    rec.nwedges := its.nwedges;
	}
	rec.maptype := its.maptype;
	return rec;
    }

    self.getoptions := function() {
	__VCF_('viewerdisplaypanel.getoptions');
	rec := its.gui.pcanvas->getoptions();
	if (its.holdsdata) {
	    rec2 := its.gui.pdisplay->getoptions();
	    for (i in field_names(rec2)) {
		rec[i] := rec2[i];
	    }
	    str := 'wedgeorientation';
	    rec[str].listname := 'Wedge Orientation';
	    rec[str].dlformat := str;
	    rec[str].ptype := 'choice';
	    rec[str].popt := "vertical horizontal";
	    rec[str].value := its.wedgeorientation;
	    rec[str].default := 'vertical';
	}
	return rec;
    }

    self.setoptions := function(options) {
	if (!is_record(options)) {
	    return [=];
	}
	wider its;
	__VCF_('viewerdisplaypanel.setoptions');
	its.viewer.hold();
	if (its.nwedges > 0 && its.holdsdata) {
	    wdgopt := [=];
	    fnames := "";
	    if (its.wedgeorientation == 'vertical') {
		fnames := "topmarginspacepg bottommarginspacepg";
	    } else {
		fnames := "leftmarginspacepg rightmarginspacepg";
	    }
	    for (i in fnames) {
		if (has_field(options,i)) {
		    if (has_field(options[i],'value')) {
			wdgopt[i].value := options[i].value;
		    } else {
			wdgopt[i].value := options[i];
		    }
		}
	    }

	    for (i in 1:its.nwedges) {
		t:= its.gui.wedgecanvi[i]->setoptions(wdgopt);
	    }
	}
	if (has_field(options,'wedgeorientation')) {
	    newori := F;
	    if (has_field(options.wedgeorientation,'value')) {
		newori := 
		    its.wedgeorientation != options.wedgeorientation.value;
		its.wedgeorientation:= options.wedgeorientation.value;
	    } else {
		newori := 
		    its.wedgeorientation != options.wedgeorientation;
		its.wedgeorientation := options.wedgeorientation;
	    }
	    if (newori) {
		its.arrangewedgerequirements(reset=T);
	    }
	}
	if (its.holdsdata) {

	    rec2 := its.gui.pdisplay->setoptions(options);

	    # need to reinstall animator restrictions, in case additional
	    # canvases have been created on the panel.
	    if (is_agent(its.animator)) {
		its.animator.gotoz(its.animator.currentzframe());
		its.animator.gotob(its.animator.currentbframe());
	    }

	    its.worldcanvasid := its.gui.pdisplay->status().worldcanvasid;
	}

	rec1 := its.gui.pcanvas->setoptions(options);	
	its.viewer.release();
	# rec1 and rec2 may contain options which have changed due
	# to context, so now create a merged options record and return 
	# it.
	if (!is_record(rec1)) {
	    rec1 := [=];
	}
	if (is_record(rec2)) {
	    for (i in field_names(rec2)) {
		rec1[i] := rec2[i];
	    }
	}
	if (is_record(options)) {	    
	    return rec1;
	} else {
	    return [=];
	}
    }

    #######################
    #  Need to rethink this one
    #
    self.index := function() {
	__VCF_('viewerdisplaypanel.index');
	note(spaste('viewerdisplaypanel.index is deprecated.'),
	     origin='viewerdisplaypanel.g',
	     priority='WARN');
	return F;
	#return its.gui.pdisplay->index();
    }
    #
    #
    ########################

    self.disabletools := function() {
	__VCF_('viewerdisplaypanel.disabletools');
	note(spaste('viewerdisplaypanel.disabletools is deprecated, use \n',
		    'viewerdisplaypanel.disablecontrols instead'),
	     origin='viewerdisplaypanel.g',
	     priority='WARN');
	return self.disablecontrols();
    }
    self.disablecontrols := function() {
	__VCF_('viewerdisplaypanel.disablecontrols');
	#its.gui.pcanvas->disabletools();
	t := its.gui.pdisplay->disabletools();
	return T;
    }

    self.enabletools := function() {
	__VCF_('viewerdisplaypanel.enabletools');
	note(spaste('viewerdisplaypanel.enabletools is deprecated, use \n',
		    'viewerdisplaypanel.enablecontrols instead'),
	     origin='viewerdisplaypanel.g',
	     priority='WARN');
	return self.enablecontrols();
    }
    self.enablecontrols := function() {
	__VCF_('viewerdisplaypanel.enablecontrols');
	#its.gui.pcanvas->enabletools();
	t := its.gui.pdisplay->enabletools();
	return T;
    }


    #### redo ######
    its.worldcanvasid := [];
    self.worldcanvasid := function() {
	__VCF_('viewerdisplaypanel.worldcanvasid');
	return its.worldcanvasid;
    }
    
   

    ############################################################
    ## MAKE WORLDCANVAS/ES                                    ##
    ############################################################
    if (its.holdsdata) {
	############################################################
	## WORLDCANVAS                                            ##
	############################################################
	its.gui.pdisplay := its.wdgts.paneldisplay(its.gui.pcanvas,
					       its.nxpanels,
					       its.nypanels);
	if (is_fail(its.gui.pdisplay)) {
	    return throw(spaste('Couldn\'t create a pdisplay:\n',
				its.gui.pdisplay::message));
	} else {
	    whenever its.gui.pdisplay->logmessage do {
		note($value.message, origin=$value.origin, 
		     priority=$value.priority);
	    } its.pushwhenever();
#	    whenever its.gui.wcanvas->motion do {
#		self->motion($value);
#	    } its.pushwhenever();
#	    whenever its.gui.wcanvas->pseudoposition do {
#		self->pseudoposition($value);
#	    } its.pushwhenever();
	    whenever its.gui.pdisplay->localoptions do {
		self->localoptions($value);
	    } its.pushwhenever();

	    self.paneldisplayagent := function() {
		__VCF_('viewerdisplaypanel.paneldisplayagent');
		return its.gui.pdisplay;
	    }
	}
	its.worldcanvasid := its.gui.pdisplay->status().worldcanvasid;




	############################################################
	## ANIMATOR                                               ##
	############################################################

	its.animator := vieweranimator(its.viewer);
	if (is_fail(its.animator)) {
	    return throw(spaste('viewerdisplaypanel failed to make an ',
				'animator - bailing out of\n',
				'creating a displaypanel'));
	} else {
	    its.animator.addpaneldisplay(its.gui.pdisplay);


	    self.setanimator := function(sarec) {
	        # sarec can contain zindex, zlength (cube mode settings),
		# bindex and/or blength fields (blink mode settings).
		# Either can be updated, regardless of current animator mode.
		#
		# Note that the current zlength value (from DDs) is usually
		# [re]set onto the animator during this call, even when it
		# does not appear explicitly in sarec.

	        if(!is_agent(its.animator)) return;
		local anim := its.animator;


		# cube slice settings.

		if(is_integer(sarec.zlength) && sarec.zlength>=0)
		     zlen := sarec.zlength;
		else zlen := its.gui.pdisplay->zlength();
			# if no zlength is given, it is set to that of the
			# first registered dd (0 if none).

		if(is_integer(zlen) && zlen>=0) {
		    anim.setzlength(zlen);
		}

		if(is_integer(sarec.zindex)) frm := sarec.zindex+1;
			# (zindex is numbered from 0, frm from 1)
	        else			     frm := anim.currentzframe();
	        if(frm<1 || frm>anim.nzframes()) frm := 1;
			# check that frame number is in range
			# (set to beginning if not).

		anim.gotoz(frm);


		# blink settings

		if(is_integer(sarec.blength) && sarec.blength>=0) {
		    anim.setblength(sarec.blength);
		}
		if(is_integer(sarec.bindex) && sarec.bindex>=0) {
		    anim.gotob(sarec.bindex+1);
		}
	    }


	    whenever its.gui.pdisplay->setanimator do {
		self.setanimator($value);
	    } its.pushwhenever();


	    self.animator := function() {
		__VCF_('viewerdisplaypanel.animator');
		return its.animator;
	    }
	}

	############################################################
	## CANVASMANAGER                                          ##
	############################################################
	its.canvasmanager := F;
	self.canvasmanager := function() {
	    __VCF_('viewerdisplaypanel.canvasmanager');
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
	    __VCF_('viewerdisplaypanel.newcanvasmanagergui');
	    if (is_agent(its.canvasmanager)) {
		return its.canvasmanager.gui(parent, show, hasdismiss,
					     hasdone, widgetset);
	    } else {
		note(spaste('A viewercanvasmanager is not available'),
		     origin=spaste(its.viewer.title(), ' (viewer.g)'),
		     priority='SEVERE');
	    }
	}

	############################################################
	## CANVASPRINTMANAGER                                     ##
	############################################################
	its.canvasprintmanager := F;
	self.canvasprintmanager := function() {
	    __VCF_('viewerdisplaypanel.canvasprintmanager');
	    return its.canvasprintmanager;
	}
	its.canvasprintmanager := viewercanvasprintmanager(self);
	if (is_fail(its.canvasprintmanager)) {
	    note(spaste('Couldn\'t create a viewercanvasprintmanager - ',
			'printing will not work'),
		 origin=spaste(its.viewer.title(), ' (viewer.g)'),
		 priority='SEVERE');
	    its.canvasprintmanager := F;
	}
	self.newcanvasprintmanagergui := function(parent=F, show=T, 
						  hasdismiss=F, hasdone=F,
						  widgetset=unset) {
	    __VCF_('viewerdisplaypanel.newcanvasprintmanagergui');
	    if (is_agent(its.canvasprintmanager)) {
		return its.canvasprintmanager.gui(parent, show, hasdismiss,
						  hasdone, widgetset);
	    } else {
		note(spaste('A viewercanvasprintmanager is not available'),
		     origin=spaste(its.viewer.title(), ' (viewer.g)'),
		     priority='SEVERE');
	    }
	}
	self.print := function(filename=unset, media='A4', landscape=F,
			       dpi=100, zoom=1.0, eps=F) {
	    __VCF_('viewerdisplaypanel.print');
	    note(spaste('viewerdisplaypanel.print function is no longer \n',
			'available - use the viewercanvasprintmanager'),
		 origin='viewerdisplaypanel.g',
		 priority='SEVERE');
	}
   
	############################################################
	## VIEWERANNOTATOR                                        ##
	############################################################
	its.viewerannot := F;
	
	self.annotator := function() {
	    return its.viewerannot;
	}
	its.viewerannot := viewerannotations(self,paste("Annotating - ",  
							its.viewer.title()), 
					     its.wdgts);
	
	if (is_fail(its.viewerannot)) {
	    note(spaste('Couldn\'t create a viewerannotations - ',
			'annotations unavailable'),
		 origin=spaste(its.viewer.title(), ' (viewer.g)'),
		 priority='WARN');
	    its.viewerannot := F;
	}
	
    }
    
    ############################################################
    ## "SUPPORT" FOR REGIONS DRAWN ON THE WORLDCANVAS/ES      ##
    ############################################################

    if (its.holdsdata) {
	whenever its.gui.pdisplay->* do {
	    self->[$name]($value);
	} its.pushwhenever();
    }

    ############################################################
    ## DEAL WITH REFRESH CYCLES COMING OUT TO GLISH/TK        ##
    ############################################################
    if (its.holdsdata) {
	its.refresheventhandlers := [=];
	self.callrefresheventhandlers := function() {
	    __VCF_('viewerdisplaypanel.callrefresheventhandlers');
	    wider its;
	    if (len(its.refresheventhandlers) > 0) {
		for (i in 1:len(its.refresheventhandlers)) {
		    its.refresheventhandlers[i](its.gui.pdisplay);
		}
	    }
	}
	self.addrefresheventhandler := function(handler) {
	    __VCF_('viewerdisplaypanel.addrefreshhandler');
	    wider its;
	    its.refresheventhandlers[len(its.refresheventhandlers) + 1] :=
		handler;
	}
	whenever its.gui.pdisplay->refresh do {
	    self.callrefresheventhandlers();
	} its.pushwhenever();
    }

    ############################################################
    ## DEAL WITH CONSTRUCTING, MAPPING AND UNMAPPING THE GUI  ##
    ############################################################
    its.thegui := F;
    self.addgui := function(guihasmenubar=T, guihascontrolbox=T,
			    guihasanimator=T, guihasbuttons=T,
			    guihastracking=T,
			    hasdismiss=unset, hasdone=unset,
			    isolationmode=F, show=T) {
	__VCF_('viewerdisplaypanel.addgui');
        wider its;
	if (!is_agent(its.thegui)) {
	    its.thegui := its.viewerdisplaypanelgui(self, guihasmenubar,
						    guihascontrolbox,
						    guihasanimator,
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

        # Forward events
        whenever its.thegui->* do {
           if ($name=='region' || $name=='position' || $name=='statistics') {
              self->[$name]($value);
           }
        } its.pushwhenever();

	return T;
    }

    ############################################################
    ## UTILITY FUNCTIONS                                      ##
    ############################################################
    self.testpattern := function(onoff) {
	__VCF_('viewerdisplaypanel.testpattern');
	if (is_boolean(onoff)) {
	    t := its.gui.pcanvas->testpattern(onoff);
	}
    }
    self.registercolormap := function(map) {
	__VCF_('viewerdisplaypanel.registercolormap');
	t := its.viewer.colormapmanager().colormap(map);
	if (is_agent(t) && is_agent(its.gui.pcanvas)) {
	    tmp := its.gui.pcanvas->registercolormap(t);
	}
    }
    self.unregistercolormap := function(map) {
	__VCF_('viewerdisplaypanel.unregistercolormap');
	if (is_agent(its.viewer)) {
	    t := its.viewer.colormapmanager().colormap(map);
	    if (is_agent(t) && is_agent(its.gui.pcanvas)) {
		tmp := its.gui.pcanvas->unregistercolormap(t);
	    }
	}
    }
    self.replacecolormap := function(newcmapname, oldcmapname) {
	__VCF_('viewerdisplaypanel.replacecolormap');
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
	__VCF_('viewerdisplaypanel.setcolortablesize');
	its.viewer.hold();
	t := its.gui.pcanvas->colortablesize(size);
	its.viewer.release();
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
	
	self.sneakyregister := function(displaydataproxy) {
	    __VCF_('viewerdisplaypanel.sneakyregister');
	    its.viewer.disable();
	    its.viewer.hold();
	    t := its.gui.pdisplay->add(displaydataproxy);
	    its.viewer.release();
	    its.viewer.enable();
	}

	self.sneakyunregister := function(displaydataproxy) {
	    __VCF_('viewerdisplaypanel.sneakyunregister');
	    its.viewer.disable();
	    its.viewer.hold();
	    t := its.gui.pdisplay->remove(displaydataproxy);
	    its.viewer.release();
	    its.viewer.enable();
	}	    
	# this is for drawing annotations in the future

	its.annotationdd := viewerddd(its.viewer);
	self.sneakyregister(its.annotationdd.dddproxy());
	self.annotationdd := function() {
	     __VCF_('viewerdisplaypanel.annotationdd');
	     return its.annotationdd;
	}

	its.lastdisplaydata := [=];
	self.register := function(displaydata) {
	    __VCF_('viewerdisplaypanel.register');
	    wider its;
	    # we need reget=T because in general an emitted event won't
	    # get here before the register command...
	    its.lastdisplaydata := [=];
	    it := its.finddisplaydata(displaydata, reget=T);
	    if (is_boolean(it)) {
		    return throw('Couldn\'t find displaydata to register');
	    }
	
	    if (!its.registrationflags[it]) {
		its.viewer.disable();
		its.viewer.hold();
		self.sneakyunregister(its.annotationdd.dddproxy());
		t := its.gui.pdisplay->add(displaydata.ddproxy());
		if (displaydata.hasbeam()) {
		    t := its.gui.pdisplay->add(displaydata.ddd().dddproxy());
		}
		self.sneakyregister(its.annotationdd.dddproxy());
		#nframes := its.gui.pdisplay->zLength();
		#its.animator.reset(nframes);
		rec := [=];
		for (i in field_names(its.registrationflags)) {
		    if (i != it) {
			rec[i] := its.registrationflags[i];
		    }
		}
		# add this one at the end, otherwise it will be registered
		# at the initial position in the record.
		rec[it] := T;
		# copy the record back
		its.registrationflags := [=];
		for (i in field_names(rec)) {
		    its.registrationflags[i] := rec[i];
		}
                    
		#its.registrationflags[it] := T;

		its.lastdisplaydata[it] := T;
                self->lastdisplaydata(its.lastdisplaydata);
		its.emitdisplaydatas();

		its.viewer.release();
		its.arrangewedgerequirements();
		its.viewer.enable();
		# return T to indicate displaydata was registered
		return T;
	    }
	    # return F to indicate nothing was done
	    return F;
	}
	self.unregister := function(displaydata) {
	    __VCF_('viewerdisplaypanel.unregister');
	    wider its;
	    # we need reget=T because in general an emitted event won't
	    # get here before the unregister command...
	    its.lastdisplaydata := [=];
	    it := its.finddisplaydata(displaydata, reget=T);
	    if (is_boolean(it)) {
		return throw('Couldn\'t find displaydata to unregister');
	    }
	    anydds := F;
	    for (str in field_names(its.registrationflags)) {
		if (str != it) {
		    anydds := anydds || its.registrationflags[str];
		}
	    } 
	    if (!anydds) {
		t := self.sneakyunregister(its.annotationdd.dddproxy());
		t := its.annotationdd.done();
		its.annotationdd := viewerddd(its.viewer);
		t := self.sneakyregister(its.annotationdd.dddproxy());
	    }
	    if (its.registrationflags[it]) {
		its.viewer.disable();
		its.viewer.hold();
		t := its.gui.pdisplay->remove(displaydata.ddproxy());
		if (displaydata.hasbeam()) {
		    t := 
			its.gui.pdisplay->remove(displaydata.ddd().dddproxy());
		}
		its.registrationflags[it] := F;
		its.lastdisplaydata[it] := F;		
                self->lastdisplaydata(its.lastdisplaydata);
		its.emitdisplaydatas();

		its.viewer.release();
		its.arrangewedgerequirements();
		its.viewer.enable();
		# return T to indicate displaydata was unregistered
		return T;
	    } 
	    # return F to indicate nothing was done
	    return F;
	}
	self.isregistered := function(displaydata) {
	    __VCF_('viewerdisplaypanel.isregistered');
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
	    __VCF_('viewerdisplaypanel.unregisterall');
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
	    __VCF_('viewerdisplaypanel.registerednames');
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
	
	self.unzoom := function() {
	    __VCF_('viewerdisplaypanel.unzoom');
	    t := its.gui.pdisplay->unzoom();
	    return T;
	}
	
	self.setzoom := function(blc, trc) {
	    __VCF_('viewerdisplaypanel.setzoom');
	    if ((len(blc) != 2) || (len(trc) != 2)) {
		fail 'blc & trc must each be of length 2 in setzoom';
	    }
	    t := its.gui.pdisplay->setzoom(blc[1], blc[2], trc[1], trc[2]);
	    return T;
	}

	self.zoom := function(xfac=2.0, yfac=unset) {
	    __VCF_('viewerdisplaypanel.zoom');
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
	    __VCF_('viewerdisplaypanel.adjust');
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

	self.registrationflags := function() {
	    __VCF_('viewerdisplaypanel.registrationflags');
	    return its.registrationflags;
	}

	its.getdisplaydatas := function(newdisplaydata=F) {
	    wider its;
	    if (is_boolean(newdisplaydata)) {
		newdisplaydata := its.viewer.alldisplaydatas();
	    }
	    for (i in field_names(newdisplaydata)) {
		if (!has_field(its.displaydatas, i)) {
		    its.registrationflags[i] := F;
		    if (is_agent(newdisplaydata[i])) {
		    	whenever newdisplaydata[i]->
		    	    wedgerequirementschanged do {
		    	    name := $value;
		    	    it := F;
		    	    for (i in field_names(its.displaydatas)) {
		    		if (its.displaydatas[i].name() == name) {
		    		    it := i;
		    		    break;
		    		}
		    	    }
		    	    if (!is_boolean(it) && 
		    		its.registrationflags[it]) {
		    		its.arrangewedgerequirements();
		    	    }
		    	} its.pushwhenever();
		    }
		}
	    }
	    its.displaydatas := newdisplaydata;
	}

	# initialize dds and their registration flags

	its.displaydatas := [=];
	its.registrationflags := [=];
	its.getdisplaydatas();


	whenever its.viewer->displaydatas do {
	    its.getdisplaydatas($value);
	    its.emitdisplaydatas();
	} its.pushwhenever();

	its.emitdisplaydatas := function() {
	    self->registrationflags(its.registrationflags);
	    self->displaydatas(its.displaydatas);
	}

	self.getdisplaydatas := function() {
	    __VCF_('viewerdisplaypanel.getdisplaydatas');
	    its.getdisplaydatas();
	    return its.displaydatas;
	}

	## position tracking support
	self.motioneventhandler := function(ddname, motionevent) {
	    __VCF_('viewerdisplaypanel.motioneventhandler');
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
	__VCF_('viewerdisplaypanel.settool');
	key := rec.dlkey;
	if (rec.tool == 'Colormap fiddling - shift/slope') {
	    t := its.gui.pcanvas->standardfiddler(key);
	} else if (rec.tool == 'Colormap fiddling - brightness/contrast') {
	    t := its.gui.pcanvas->mapfiddler(key);
	} else if (rec.tool == 'Annotations') {
	    if (is_agent(its.viewerannot)) {
		t := its.viewerannot.setkey(key);
	    }
	}
	
	if (its.holdsdata) {
	    if (rec.tool == 'Zooming') {
		t := its.gui.pdisplay->settoolkey("zoomer", key);
	    } else if (rec.tool == 'Panning') {
		t := its.gui.pdisplay->settoolkey("panner", key);
	    } else if (rec.tool == 'Positioning') {
		t := its.gui.pdisplay->settoolkey("positioner", key);
	    } else if (rec.tool == 'Rectangle drawing') {
		t := its.gui.pdisplay->settoolkey("rectangle", key);
	    } else if (rec.tool == 'Polygon drawing') {
		t := its.gui.pdisplay->settoolkey("polygon", key);
	    } else if (rec.tool == 'Polyline drawing') {
		t := its.gui.pdisplay->settoolkey("polyline", key);
	    }
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

    ############################################################
    ## WEDGE THINGS                                           ##
    ############################################################
    if (its.holdsdata) {
	 its.arrangewedgerequirements := function(reset=F) {
	     wider its;

	     nwedgesprev := its.nwedges;
	     its.nwedges := 0;
	     wedgedddsprev := its.wedgeddds;

	     for (i in field_names(its.displaydatas)) {
		 if (its.registrationflags[i]) {
		     opts := its.displaydatas[i].getoptions();
		     if (has_field(opts, 'wedge') &&
			 (opts.wedge.value != F)) {
			 its.nwedges := its.nwedges + 1;
			 its.wedgeddds[its.nwedges] := i;
		     }
		 }
	     }

	     if (reset) {
		 if (its.nwedges > 0) {
		     for (i in its.nwedges:1) {
			 if (is_agent( its.gui.wedgecanvi[i])) {
			     its.gui.wedgecanvi[i] := F;
			 }
		     }
		     nwedgesprev := 0;
		 }
	     }


	     its.viewer.hold();
	     # 1. Arrange for correct number of wedge canvases:
	      if (nwedgesprev < its.nwedges) {
		  for (i in (nwedgesprev + 1):its.nwedges) {
		      its.gui.wedgecanvi[i] := 
			  its.wdgts.paneldisplay(its.gui.pcanvas);
		      if (is_fail(its.gui.wedgecanvi[i])) {
			  fail "Unable to create wedge panel(s)";
		      }
		  }
	     } else if (nwedgesprev > its.nwedges) {
		 for (i in (its.nwedges + 1):nwedgesprev) {
		     if (is_agent( its.gui.wedgecanvi[i])) {
			 its.gui.wedgecanvi[i] := F;
		     }
		 }
	     }    
	     wedgeextent := 0.18;
	     wedgespace := 0.0;
	     if (its.nwedges != nwedgesprev) {
		 if (its.nwedges > 0) {
		     for (i in 1:its.nwedges) {
			 opt := its.gui.wedgecanvi[i]->getgeometry();
			 otheropt :=  its.gui.pdisplay->getgeometry();

			 if (its.wedgeorientation == 'vertical') {
			     opt.xsize := wedgeextent;
			     opt.xorigin := 1.0  - 
				 i * (wedgeextent + wedgespace) + wedgespace;

			     #viewerdisplaypanel doesn't use
			     #xorigin,yorigin,xsize,ysize etc. we can
			     #assume 0.0,0.0,1.0,1.0 here 
			     # change  this if it does in the future
			     #opt.yorigin:= otheropt.yorigin; 
			     #opt.ysize := otheropt.ysize;
			     opt.yorigin := 0.0;
			     opt.ysize := 1.0;
			 } else {
			     opt.ysize := wedgeextent;
			     opt.yorigin := 1.0  - 
				 i * (wedgeextent + wedgespace) + wedgespace;
			     #opt.xorigin := otheropt.xorigin;
			     #opt.xsize := otheropt.xsize;
			     opt.xorigin := 0.0;
			     opt.xsize := 1.0;			     
			 }
			 t := its.gui.wedgecanvi[i]->setgeometry(opt); 
			 t := its.gui.wedgecanvi[i]->disabletools();
			 pdopt := its.gui.pdisplay->getoptions();
			 rec := [=];
			 if (its.wedgeorientation == 'vertical') {
			     rec.leftmarginspacepg := 1;
			     rec.bottommarginspacepg := 
				 pdopt.bottommarginspacepg.value;
			     rec.topmarginspacepg := 
				 pdopt.topmarginspacepg.value;
			     rec.rightmarginspacepg := 10;
			 } else {
			     rec.bottommarginspacepg := 1;
			     rec.leftmarginspacepg := 
				 pdopt.leftmarginspacepg.value;
			     rec.rightmarginspacepg := 
				 pdopt.rightmarginspacepg.value;
			     rec.topmarginspacepg := 6;
			 }
			 t := its.gui.wedgecanvi[i]->setoptions(rec);
		     }     
		 }
	     }
	     
	     
	     # 3. Arrange wedge display datas to put in the canvi...
	     if (its.nwedges > 0) {
		 for (i in 1:its.nwedges) {
		     if (is_agent(its.gui.wedgecanvi[i])) {

			 if (i <= nwedgesprev || reset) {
			     t := its.gui.wedgecanvi[i]->
				 remove(its.displaydatas[wedgedddsprev[i]].
					wedgedd());
			 }
			 rec := [=];
			 rec.orientation.value := its.wedgeorientation;
			 its.displaydatas[its.wedgeddds[i]].wedgedd()->
			     setoptions(rec);
			 t := its.gui.wedgecanvi[i]->
			     add(its.displaydatas[its.wedgeddds[i]].wedgedd());
		     }
		 }
	     }	     

	     if (its.nwedges != nwedgesprev) {
		 opt := its.gui.pdisplay->getgeometry();
		 if (its.wedgeorientation == 'vertical') {
		     opt.xsize := 1.0 - 
			 its.nwedges * (wedgeextent + wedgespace);
		     opt.yorigin := 0.0;
		     opt.ysize := 1.0;

		 } else {
		     opt.ysize := 1.0 - 
			 its.nwedges * (wedgeextent + wedgespace);
		     opt.xorigin := 0.0;
		     opt.xsize := 1.0;
		     
		 }
		 t := its.gui.pdisplay->setgeometry(opt);
		 # update this because the pointer has changed
		 its.worldcanvasid := its.gui.pdisplay->status().worldcanvasid;
	     }

	     t := its.viewer.release();

	 }
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
					     guihasanimator=T,
					     guihasbuttons=T, 
					     guihastracking=T,
					     hasdismiss=unset,
					     hasdone=unset, 
					     isolationmode=F, show=T) {
	__VCF_('viewerdisplaypanelgui');
	
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

	its.setup := [=];
	its.setup.menubar := [=];
	its.setup.controlbox := T;
	its.setup.animator := T;
	its.setup.buttons := T;
	its.setup.tracking := T;

	if (is_record(guihasmenubar) || is_boolean(guihasmenubar)) 
	    its.setup.menubar := guihasmenubar;
	if (is_record(guihascontrolbox) || is_boolean(guihascontrolbox)) 
	    its.setup.controlbox := guihascontrolbox;
	its.setup.animator := guihasanimator;
	if (is_record(guihasbuttons) || is_boolean(guihasbuttons)) 
	    its.setup.buttons := guihasbuttons;
	its.setup.tracking := guihastracking;

	its.hasdismiss := hasdismiss;
	its.hasdone := hasdone;
	its.isolationmode := isolationmode;
        its.busy.pseudoregion := F;
        its.busy.pseudoposition := F;
        its.busy.polyline := F;
	
	############################################################
	## BASIC SERVICES                                         ##
	############################################################
	its.type := 'viewerdisplaypanel';
	self.type := function() {
	    __VCF_('viewerdisplaypanelgui.type');
	    return its.type;
	}
	
	its.viewer := its.displaypanel.viewer();
	self.viewer := function() {
	    __VCF_('viewerdisplaypanelgui.viewer');
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
	    __VCF_('viewerdisplaypanelgui.done');
	    wider its, self;
	    if (its.dying) {
		# prevent multiple done requests
		return F;
	    } its.dying := T;

	    if (len(its.whenevers) > 0) {
		its.deactivate(its.whenevers);
	    }
            if (is_agent(its.via)) {
               ok := its.via.done();
            }
	    if (has_field(its.gui, 'tlktmenu')) {
		its.gui.tlktmenu.menu.done();
	    }
	    if (is_agent(its.gui.controlbox)) {
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
	
	if (is_record(its.setup.menubar) || 
	    (is_boolean(its.setup.menubar) && its.setup.menubar)) {
	    its.gui.menubar := its.wdgts.frame(its.gui.upperframe, 
					       side='left', 
					       relief='raised', expand='x');
	    ############################################################
	    ## WINDOW MENU AND OPERATIONS                             ##
	    ############################################################
	    if ((is_record(its.setup.menubar) && 
		has_field(its.setup.menubar,'file') && 
		its.setup.menubar.file) || 
		(is_boolean(its.setup.menubar) && its.setup.menubar)) {
		its.gui.wndwmenu.menu := 
		    its.wdgts.button(its.gui.menubar, 'File',
				     type='menu', 
				     relief='flat');
		if (!its.isolationmode) {
		    its.gui.dpmenu := 
			viewerdpmenu(its.gui.wndwmenu.menu,its.viewer);
		    its.gui.wndwmenu.spacer0 := 
			its.wdgts.button(its.gui.wndwmenu.menu, 
					 '---------------------------------');
		    t := its.gui.wndwmenu.spacer0->disabled(T);

		    its.gui.wndwmenu.newpanl := 
			its.wdgts.button(its.gui.wndwmenu.menu,
					 'Data manager');
		    whenever its.gui.wndwmenu.newpanl->press do {
			its.viewer.newdatamanager(hasdone=T);
		    } its.pushwhenever();
		}
		its.gui.wndwmenu.newcmap := 
		    its.wdgts.button(its.gui.wndwmenu.menu, 
				     'Colormap manager');
		whenever its.gui.wndwmenu.newcmap->press do {
		    its.viewer.newcolormapmanagergui(hasdone=T);
		} its.pushwhenever();
		
		its.gui.wndwmenu.canmang := 
		    its.wdgts.button(its.gui.wndwmenu.menu,
				     'Canvas manager');
		whenever its.gui.wndwmenu.canmang->press do {
		    its.displaypanel.newcanvasmanagergui(hasdone=T);
		} its.pushwhenever();
		
		its.gui.wndwmenu.print := 
		    its.wdgts.button(its.gui.wndwmenu.menu, 'Print...');
		whenever its.gui.wndwmenu.print->press do {
		    t := its.displaypanel.
			newcanvasprintmanagergui(hasdismiss=T);
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
	    }
	    ############################################################
	    ## DISPLAYDATA MENU AND OPERATIONS                        ##
	    ############################################################
	    if ((is_record(its.setup.menubar) && 
		has_field(its.setup.menubar,'displaydata') && 
		its.setup.menubar.displaydata) || 
		(is_boolean(its.setup.menubar) && its.setup.menubar)) {	    

		its.datamenu := [=];
		its.datamenu.extra := [=];
		its.datamenu.menu := its.wdgts.button(its.gui.menubar, 
						      'DisplayData', 
						      type='menu', 
						      relief='flat');
		its.wdgts.popuphelp(its.datamenu.menu,
				    txt=spaste('Various functions to control ',
					       'the DisplayDatas, ',
					       'eg. registering ',
					       'adjusting or removal from ',
					       'the Viewer'), 
				    hlp='DisplayData control menu');

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
		
		its.displaydatas := [=];
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
			    # register
			    its.datamenu.extra.unregisterall := F;
			    its.datamenu.extra.registerall := F;
			    if (is_agent(its.datamenu.extra.regspacer)) {
				t := its.datamenu.extra.regspacer->disabled(F);
				its.datamenu.extra.regspacer := F;
			    }
			    # delete
			    its.datamenu.extra.deleteall := F;
			    if (is_agent(its.datamenu.extra.delspacer)) {
				t := its.datamenu.extra.delspacer->disabled(F);
				its.datamenu.extra.delspacer := F;
			    }
			    
			    its.datamenu.extra := [=];
			}
			if (len(its.datamenu.items) >= 1) {
			    for (i in len(its.datamenu.items):1) {
				its.datamenu.items[i] := F;
				its.datamenu.delitems[i] := F;
				its.datamenu.adjitems[i] := F;
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
			its.datamenu.extra.delspacer := 
			    its.wdgts.button(its.datamenu.delmenu,
					     '---------------------------------');
			t := its.datamenu.extra.delspacer->disabled(T);
			
			its.datamenu.extra.regspacer := 
			    its.wdgts.button(its.datamenu.regmenu,
					     '---------------------------------');
			t := its.datamenu.extra.regspacer->disabled(T);
			its.datamenu.extra.deleteall := 
			    its.wdgts.button(its.datamenu.delmenu, 'Remove all');
			whenever its.datamenu.extra.deleteall->press do {
			    its.viewer.hold();
			    for (i in field_names(its.displaydatas)) {
				its.viewer.deletedata(its.displaydatas[i]);
			    }
			    its.viewer.release();
			} #its.pushwhenever();
			
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
			    if (its.datamenu.items[$value]->state()) {
				its.displaypanel.
				    register(its.displaydatas[$value]);
			    } else {
				its.displaypanel.
				    unregister(its.displaydatas[$value]);
			    }
			} #its.pushwhenever();
		    }
		    #adjust submenu
		    for (i in field_names(its.datamenu.adjitems)) {
			whenever its.datamenu.adjitems[i]->press do {
			t := its.displaypanel.adjust($value);		    
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
	    }

            ############################################################
            ## TOOL OPERATIONS                                        ##
            ############################################################

	    if ((is_record(its.setup.menubar) && 
		 has_field(its.setup.menubar,'tools') && 
		 its.setup.menubar.tools) || 
		(is_boolean(its.setup.menubar) && its.setup.menubar)) {
		
		its.toolsmenu := its.wdgts.button(its.gui.menubar, 'Tools',
						  type='menu', relief='flat');
		txt := spaste('Various high-level application tools',
			      ' e.g. data statistics/profiles etc');
		its.wdgts.popuphelp(its.toolsmenu, txt=txt, 
				    hlp='Application tools menu');
		
		its.toolsmenu.imageanalysis := 
		    its.wdgts.button(its.toolsmenu, 'ImageAnalysis...');
		its.toolsmenu.annotations := 
		    its.wdgts.button(its.toolsmenu, 'Annotations...');
		#its.toolsmenu.annotations->disable();


               ############
               ## ANNOTATIONS 
               ###########
		if (its.displaypanel.holdsdata()) {
		    whenever its.toolsmenu.annotations->press do {

			if (!is_agent(its.displaypanel.annotator())) {
			    note(spaste('Annotations were not available'),
				 origin=
				 spaste(its.viewer.title(),' (viewer.g)'),
				 priority='WARN');
			    fail;
			} else {
			    its.displaypanel.annotator().gui();
			}

		    } its.pushwhenever();
		} 
		    
		    
               ##################
               ## IMAGE ANALYSIS
               ##################

          	# Start image server now if needed
		include 'servers.g'
                agents := defaultservers.agents();
		if (is_fail(agents)) fail;
		found := F;
#            for (i in 1:length(agents)) {
#              if (has_field(agents[i]agents[i].server=='app_image') {
#                 found := T;
#                 break;
#              }
#            }
		for (i in 1:length(agents)) {
		    if (has_field(agents[i],'server') && 
			agents[i].server=='app_image') {
			found := T;
			break;
		    }
		}
		if (!found) {            
		    include 'image.g'
                    im := imagefromshape(shape=[1], log=F);
		    if (is_fail(im)) fail;
		    ok := im.done();
		}
		
		# Make image analysis tool
		include 'viewerimageanalysis.g'
                its.via := viewerimageanalysis(panel=its.displaypanel);
		if (is_fail(its.via)) fail;
		
		# Set callback to get options from DD name
		const ddop := function (ddname)
		{
		    wider its;
		    dds :=  its.displaypanel.getdisplaydatas();
		    return dds[ddname].getoptions();
		}
		ok := its.via.setcallbacks(ddop);
		if (is_fail(ok)) fail;
		
		# Forward events
		whenever its.via->* do {
		    self->[$name]($value);
		} its.pushwhenever();
		
		# Show GUI
		whenever its.toolsmenu.imageanalysis->press do {
		    its.via.gui();
		} its.pushwhenever();
#
		its.ddwhenevers := [=];
		its.ddaxes := [=];
		# Handle DD (un)registration event
		whenever its.displaypanel->lastdisplaydata do {
		    ddName := field_names($value)[1];
		    alldisplaydatas := its.displaypanel.getdisplaydatas();
		    if (is_agent(alldisplaydatas[ddName])) {  
			dtype := alldisplaydatas[ddName].datatype();
			ptype := alldisplaydatas[ddName].pixeltype();
			datasource := alldisplaydatas[ddName].filename();
#                  Can viewerimageanalysis understand this type of DD ?
			if (its.via.validtype(dtype, ptype) ) {
			    its.toolsmenu.imageanalysis->disabled(T);
			    
			    # Add this dd to the analysis tool 
			    if ($value[ddName]==T) {  
				ok := its.via.add(ddName, datasource, 
						  dtype, ptype);
				if (is_fail(ok)) {
				    note (ok::message, priority='SEVERE', 
					  origin='viewerdisplaypanel');
				}
       
				# Store DD axes
				op := alldisplaydatas[ddName].getoptions();
				its.ddaxes[ddName] := [=];
				its.ddaxes[ddName].xaxis := op.xaxis;
				its.ddaxes[ddName].yaxis := op.yaxis;
				if (has_field(op, 'zaxis')) 
				    its.ddaxes[ddName].zaxis := op.zaxis;
				
				# Catch options event.  If axes are reordered, update analysis tool
				whenever alldisplaydatas[ddName]->options do {
				    op := $value;
				    ddName2 := $agent.name();
#
				    doit1 := has_field(op, 'xaxis') &&
					op.xaxis.value != 
					    its.ddaxes[ddName2].xaxis.value;
				    doit2 := has_field(op, 'yaxis') &&
					op.yaxis.value != 
					    its.ddaxes[ddName2].yaxis.value;
				    doit3 := has_field(op, 'zaxis') && 
					has_field(its.ddaxes[ddName2], 
						  'zaxis') &&
						      op.zaxis.value != 
							  its.ddaxes[ddName2].zaxis.value;
#
				    if (doit1 || doit2 || doit3) {
					its.via.update(ddName2);
					
					# Update DD axes
					its.ddaxes[ddName2].xaxis := op.xaxis;
					its.ddaxes[ddName2].yaxis := op.yaxis;
					if (has_field(op, 'zaxis')) 
					    its.ddaxes[ddName2].zaxis := 
						op.zaxis;
				    }
				}
				its.ddwhenevers[ddName] := 
				    last_whenever_executed();
			    } else {
				ok := its.via.delete(ddName);
				if (is_fail(ok)) {
				    note (ok::message, priority='SEVERE', 
					  origin='viewerdisplaypanel');
				}
				deactivate its.ddwhenevers[ddName];
			    } 
			    its.toolsmenu.imageanalysis->disabled(F);
			}                                    
		    }
		} its.pushwhenever();
		
		# Handle pseudo-region event
		
		whenever its.displaypanel->pseudoregion do {
		    if (its.busy.pseudoregion) {
			note ('You are sending regions too frequently', 
			      priority='WARN', origin='viewerdisplaypanel');
		    } else {
			its.busy.pseudoregion := T;
			ok := its.via.insertregion($value);
			if (is_fail(ok)) {
			    note (ok::message, priority='SEVERE', 
				  origin='viewerdisplaypanel');
			}
			its.busy.pseudoregion := F;
		    }
		} its.pushwhenever();
		
		# Handle pseudo-position event   
		
		whenever its.displaypanel->pseudoposition  do {
		    if (its.busy.pseudoposition) {
#			note ('You are sending positions too frequently', 
#			      priority='WARN', origin='viewerdisplaypanel');
		    } else {
                       if ($value.evtype!='up') {
                          its.busy.pseudoposition := T;
                          ok := its.via.insertposition ($value);
                          if (is_fail(ok)) {
                             note (ok::message, priority='SEVERE', 
                                   origin='viewerdisplaypanel')
                          }
                          its.busy.pseudoposition := F;
                       }
		    }
		} its.pushwhenever();

		# Handle poly-line event
		
		whenever its.displaypanel->polyline do {
		    if (its.busy.polyline) {
#			note ('You are sending polylines too frequently', 
#			      priority='WARN', origin='viewerdisplaypanel');
		    } else {
                       its.busy.polyline := T;
                       ok := its.via.insertpolyline ($value);
                       if (is_fail(ok)) {
                          note (ok::message, priority='SEVERE', 
                                origin='viewerdisplaypanel')
                       }
                       its.busy.polyline := F;
		    }
		} its.pushwhenever();
		############################################################
		## END TOOL OPERATIONS                                    ##
		############################################################
	    }                 

	    if ((is_record(its.setup.menubar) && 
		has_field(its.setup.menubar,'help') && 
		its.setup.menubar.help) || 
		(is_boolean(its.setup.menubar) && its.setup.menubar)) {

		## right hand menubar, Help:
		its.gui.rightmbar := its.wdgts.frame(its.gui.menubar,
						     side='right', expand='x');
		its.gui.helpm.menu := its.wdgts.button(its.gui.rightmbar,
						       text='Help',
						       type='menu');
		its.gui.helpm.viewerref :=
		    its.wdgts.button(its.gui.helpm.menu,
				     text='Viewer reference manual');
		whenever its.gui.helpm.viewerref->press do {
		    oktmp := eval('include \'aips2help.g\'');
		    if (oktmp) {
			x := help('Refman:display.viewer');
		    }
		} its.pushwhenever();
		its.gui.helpm.viewergr :=
		    its.wdgts.button(its.gui.helpm.menu,
				     text='Viewer introduction');
		whenever its.gui.helpm.viewergr->press do {
		    oktmp := eval('include \'aips2help.g\'');
		    if (oktmp) {
			x := help('gettingresults:viewer');
		    }
		} its.pushwhenever();


		its.gui.helpm.popup :=
		    its.wdgts.popupmenu(its.gui.helpm.menu, 1);
		its.gui.helpm.refman :=
		    its.wdgts.button(its.gui.helpm.menu,
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
	}
	if (is_record(its.setup.controlbox) ||
	    (is_boolean(its.setup.controlbox) && its.setup.controlbox)) {
	    ############################################################
	    ## CONTROLBOX BUTTONS - LEFT FRAME                        ##
	    ############################################################
	    its.gui.lframe := its.displaypanel.leftframe();
	    its.gui.ulframe := its.wdgts.frame(its.gui.lframe, side='top',
					       relief='flat', borderwidth=0,
					       padx=0, pady=0, expand='y');
	    tools := "zoom pan standardcolormap mapcolormap position rectangle polygon polyline";
	    if ((its.displaypanel.status().maptype == 'hsv') ||
		(its.displaypanel.status().maptype == 'rgb')) {
		tools := "zoom pan position rectangle polygon polyline";
	    }
	    if (is_record(its.setup.controlbox) &&
		has_field(its.setup.controlbox,'tools') &&
		is_string(its.setup.controlbox.tools)) {
		tools := its.setup.controlbox.tools;
	    }
	    its.gui.controlbox := its.viewer.toolkit().
		controlbox(its.gui.ulframe, tools);
	}
	if (its.setup.animator) {
	    ############################################################
	    ## ANIMATOR (TAPEDECK) BUTTONS - RIGHT FRAME              ##
	    ############################################################
	    its.gui.rframe := its.displaypanel.rightframe();
	    its.gui.urframe := its.wdgts.frame(its.gui.rframe, side='top',
					       relief='flat', borderwidth=0,
					       padx=0, pady=0, expand='y');
	    its.displaypanel.animator().gui(its.gui.urframe,
					    orient='vertical');
	}
	if (its.setup.tracking) {
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
		__VCF_('viewerdisplaypanelgui.maketrackmessagelines');
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
		__VCF_('viewerdisplaypanelgui.motioneventhandler');
		wider its;
		if (has_field(its.gui.trkmlines, ddname)) {
		    if(motionevent.formattedvalue == '') {
			msg:=motionevent.formattedworld;
		    } else {
			msg:=spaste(motionevent.formattedvalue, ' at ',
				    motionevent.formattedworld);
		    }
		    its.gui.trkmlines[ddname]->text(msg);
		}
	    }
	}

	its.gui.btnbar := its.wdgts.frame(its.gui.lowerframe, side='left',
					  height=1, relief='flat', 
					  expand='x', borderwidth=0, 
					  padx=0, pady=0);
    	if (is_record(its.setup.buttons) || 
	    (is_boolean(its.setup.buttons) && its.setup.buttons)) {
	    ############################################################
	    ## BUTTONS                                                ##
	    ############################################################
	    if ((is_record(its.setup.buttons) && 
		 has_field(its.setup.buttons,'adjust') && 
		 its.setup.buttons.adjust) || 
		(is_boolean(its.setup.buttons) && its.setup.buttons)) {
		its.gui.lftbtnbar := its.wdgts.frame(its.gui.btnbar, 
						     side='left', 
						     height=1,
						     relief='flat',
						     expand='x',
						     borderwidth=0, 
						     padx=0, pady=0);
		## adjust displaydata settings
		its.gui.btnbar.badjust := its.wdgts.button(its.gui.lftbtnbar,
							   'Adjust...');
		its.wdgts.popuphelp(its.gui.btnbar.badjust,
				    txt=spaste('Press this button to show a ',
					       'gui which let\'s you adjust ',
					       'display properties of the image/s ',
					       '(eg. colormap,axis labels).'),
				    hlp='Show adjustment panel/s');
		whenever its.gui.btnbar.badjust->press do {
		    its.displaypanel.adjust();
		} its.pushwhenever();
	    }
	    if ((is_record(its.setup.buttons) && 
		has_field(its.setup.buttons,'unzoom') && 
		 its.setup.buttons.unzoom) || 
		(is_boolean(its.setup.buttons) && its.setup.buttons)) {

		## unzoom the displaypanel
		its.gui.btnbar.bunzoom := its.wdgts.button(its.gui.lftbtnbar,
							   'Unzoom');
		its.wdgts.popuphelp(its.gui.btnbar.bunzoom, 
				    txt=spaste('Press this button to unzoom the ',
					       'displaypanel, ie. to show the entire image'),
				    hlp='Unzoom the view');
		whenever its.gui.btnbar.bunzoom->press do {
		    its.displaypanel.unzoom();
		} its.pushwhenever();
		## clear the displaypanel
	    }
	    if ((is_record(its.setup.buttons) && 
		has_field(its.setup.buttons,'clear') && 
		 its.setup.buttons.clear) || 
		(is_boolean(its.setup.buttons) && its.setup.buttons)) {
		
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
	    }
	    if ((is_record(its.setup.buttons) && 
		has_field(its.setup.buttons,'print') && 
		 its.setup.buttons.print ) || 
		(is_boolean(its.setup.buttons) && its.setup.buttons)) {
		## print
		its.gui.btnbar.bprint := its.wdgts.button(its.gui.lftbtnbar, 
							  'Print...');
		its.wdgts.popuphelp(its.gui.btnbar.bprint,
				    txt=spaste('Press this button to get a window from ',
					       'which you can save the current view, ',
					       'and/or send it to a printer'),
				    hlp='Print this view');
		whenever its.gui.btnbar.bprint->press do {
		    t := its.displaypanel.newcanvasprintmanagergui(hasdismiss=T);
		} its.pushwhenever();
	    }
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
#	whenever its.displaypanel->object_lists do {
#	     newlists := $value;
#	     if (has_field(newlists, 'colormap')) {
#		 its.cmapmenu.update(newlists.colormap);
#	     }
#	     if (has_field(newlists, 'displaydata')) {
#		 its.datamenu.func.update(newlists.displaydatas);
#	     }
#	} its.pushwhenever();

	if(show) t := its.displaypanel.map();
    }
}
