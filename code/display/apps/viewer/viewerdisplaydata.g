# viewerdisplaydata.g: management of displaydatas for the viewer
# Copyright (C) 2002,2003
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
# $Id: viewerdisplaydata.g,v 19.8 2007/01/17 03:30:21 mmarquar Exp $

pragma include once;

include 'viewer.g';

## ************************************************************ ##
##                                                              ##
## VIEWERDISPLAYDATA SUBSEQUENCE                                ##
##                                                              ##
## ************************************************************ ##
viewerdisplaydata := subsequence(viewer, name, displaytype, data) {
    __VCF_('viewerdisplaydata');
    
    ############################################################
    ## SANITY CHECK                                           ##
    ############################################################
    if (!is_record(viewer) || !has_field(viewer, 'type') ||
	(viewer.type() != 'viewer')) {
	return throw(spaste('An invalid viewer was given to a ',
			    'viewerdisplaydata'));
    }

    ############################################################
    ## INITIALISE AND STORE CONSTRUCTOR ARGUMENTS             ##
    ############################################################
    its := [=];
    its.viewer := viewer;
    its.name := name;
    its.displaytype := displaytype;
    its.dataset := data;
    
    ############################################################
    ## BASIC SERVICES                                         ##
    ############################################################
    its.type := 'viewerdisplaydata';
    self.type := function() {
	__VCF_('viewerdisplaydata.type');
	return its.type;
    }

    self.viewer := function() { 
	__VCF_('viewerdisplaydata.viewer');
	return its.viewer; 
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
    ## DONE FUNCTION                                          ##
    ############################################################
    its.dying := F;
    self.done := function() {
	__VCF_('viewerdisplaydata.done');

	wider self, its;
	myname := self.name();
	if (its.dying) {
	    # prevent multiple done request
	    return F;
	} its.dying := T;
	if (viewer::tracedone) {
	    print 'viewerdisplaydata::done()';
	}
	if (len(its.whenevers) > 0) {
	    its.deactivate(its.whenevers);
	}

	if (len(its.displaydataguis) > 0) {
	    for (i in 1:len(its.displaydataguis)) {
		if (is_agent(its.displaydataguis[i])) {
		    its.displaydataguis[i].done();
		}
	    }
	}

	if (is_agent(its.viewer)) {	    
	    its.viewer.deletedata(self, doneit=F);
	}
	if (is_agent(its.ddd)) {
	    t := its.ddd.done();
	}
	val its.ddproxy := F;
	val its.wedgedd := F;
	self->done(myname);
	val self := F;
	if (is_agent(its.viewer)) {
	    its.viewer.emitdisplaydatalist();
	}
	val its := F;
	return T;
    }

    ############################################################
    ## GUI                                                    ##
    ############################################################
    its.displaydataguis := [=];
    self.newdisplaydatagui := function(parent=F, uneditable="", 
				       show=T, hasdismiss=F, 
				       hasdone=F, widgetset=unset) {
	__VCF_('viewerdisplaydata.newdisplaydatagui');
	wider its;
	its.viewer.disable();
	temp := its.viewerdisplaydatagui(parent, self, uneditable,
					 show, hasdismiss,
					 hasdone, widgetset);
	its.viewer.enable();
	if (is_agent(temp)) {
	    its.displaydataguis[len(its.displaydataguis) + 1] := temp;
	}
	return temp;
    }
    
    ############################################################
    ## MAKE THE DISPLAYDATA PROXY                             ##
    ############################################################
    if (is_record(its.dataset)) {
	if (is_numeric(its.dataset.data) && 
	    (len(its.dataset.data::shape) >= 2)) {
	    if (is_complex(its.dataset.data) || 
		is_dcomplex(its.dataset.data)) {
		cast := as_complex;
	    } else {
		cast := as_float;
	    }
	    its.dataset.data := cast(its.dataset.data);
	}
	if (is_agent(its.dataset.data) && 
	    its.dataset.data.type() ==  'viewerdisplaydata') {
	    its.ddproxy := its.viewer.widgetset().
		displaydata(its.displaytype.dlformat,
			    'null',its.dataset.dlformat);
	    if (is_fail(its.ddproxy) || !is_agent(its.ddproxy)) {
		fail (its.ddproxy::message);
	    }
	    result := its.ddproxy->attach(its.dataset.data.ddproxy());
	    if (is_fail(result)) fail;

	    whenever its.dataset.data->done do {
		its.ddproxy->detach();
	    } its.pushwhenever();
	} else {
	    its.ddproxy := its.viewer.widgetset().
		displaydata(its.displaytype.dlformat,
			    its.dataset.data,its.dataset.dlformat);     
	}		
    }
    if (is_fail(its.ddproxy) || !is_agent(its.ddproxy)) {
	fail (its.ddproxy::message);
    } else {
	whenever its.ddproxy->logmessage do {
	    note($value.message, origin=$value.origin, 
		 priority=$value.priority);
	}  its.pushwhenever();
	whenever its.ddproxy->error do {
	    note($value,
		 origin=spaste(its.viewer.title(),
			       ' (viewercolormapmanager.g)'),
		 priority='WARN');
	} its.pushwhenever();
	whenever its.ddproxy->motion do {
	    self->motion($value);
	} its.pushwhenever();
	whenever its.ddproxy->motion do {
	    its.viewer.motioneventhandler(its.name, $value);
	} its.pushwhenever();

	whenever its.ddproxy->contextoptions do {
	   
	    newopts := $value;

	    # emit contextoptions event
	    self->contextoptions(newopts);
	    # update its.params for following guis.
	    for (i in field_names(newopts)) {
		if (has_field(its.params, i)) {
		    its.params[i] := newopts[i];
		}
	    }

	    if(is_record(newopts.setanimator)) {

	      # note: this is not a change to an 'adjust' GUI value, but
	      # a request to set animator[s] on panels containing the dd.
	      # (a zaxis or zlength has changed in the dd).
	      # setanimator may contain zindex and/or zlength fields.

	      for (dp in its.viewer.alldisplaypanels()) {
		if(is_function(dp.setanimator) &&
		               dp.registrationflags()[its.name]) {
		  # (should also check that dd is the _first_ one
		  # registered on the dp, but there is no interface
		  # for doing that, at present).

		  dp.setanimator(newopts.setanimator);
		}
	      }
	    }

	} its.pushwhenever();

	whenever its.ddproxy->localoptions do {
	    # local options are internal to the agent, but not global
	    # to the Display Library
	    newopts := $value;
	    self->localoptions(newopts);
	    for (i in field_names(newopts)) {
		if (has_field(its.params, i)) {
		    its.params[i] := newopts[i];
		}
	    }
	} its.pushwhenever();
    }

    self.displaytype := function() {
	__VCF_('viewerdisplaydata.displaytype');
	return its.displaytype.dlformat;
    }

    self.classtype := function() {
	__VCF_('viewerdisplaydata.classtype');
	if (is_agent(its.ddproxy)) {
	    return its.ddproxy->classtype();
	} else {
	    fail (spaste('Invalid state for displaydata'));
	}
    }

    ############################################################
    ## DETERMINE THE PARAMETER SET                            ##
    ############################################################
    its.params := its.ddproxy->getoptions();

    for (i in field_names(its.params)) {
	if (has_field(its.params[i], 'ptype')) {
	    if ((its.params[i].ptype == 'region') &&
		is_record(its.params[i].value) && 
		!is_unset(its.params[i].value)) {
		nvalue := itemcontainer();
		nvalue.fromrecord(its.params[i].value);
		nvalue.makeconst();
		its.params[i].value := nvalue;
	    } else if (its.params[i].dlformat == 'mask') {
		its.params[i].help := 'Enter mask expression.\n$this is placeholder for current data, e.g. \n$this > 0 masks all pixels <= 0.';
	    }
	} 
    }
    
    its.ddd := F;
    rec := its.ddproxy->getinfo();
    if (is_record(rec) && has_field(rec,'restoringbeam')) {	
	its.params.beam.listname := 'Plot beam';
    	its.params.beam.dlformat := 'beam';
    	its.params.beam.ptype := 'boolean';
    	its.params.beam.value := F;
    	its.params.beam.default := F;
	its.params.beam.context := 'Beam';

	its.params.beamoutline.listname := 'Draw outline';
    	its.params.beamoutline.dlformat := 'beamoutline';
    	its.params.beamoutline.ptype := 'boolean';
    	its.params.beamoutline.value := T;
    	its.params.beamoutline.default := T;
	its.params.beamoutline.context := 'Beam';

	its.params.beamlinewidth.listname := 'Line width';
    	its.params.beamlinewidth.dlformat := 'beamlinewidth';
    	its.params.beamlinewidth.ptype := 'intrange';
	its.params.beamlinewidth.pmin := 1;
	its.params.beamlinewidth.pmax := 10;
    	its.params.beamlinewidth.value := 1;
    	its.params.beamlinewidth.default := 1;
	its.params.beamlinewidth.context := 'Beam';
	
	its.params.beampos.listname := 'Position';
    	its.params.beampos.dlformat := 'beampos';
    	its.params.beampos.ptype := 'choice';
	its.params.beampos.popt := "bottom-left bottom-right";
    	its.params.beampos.value := 'bottom-left';
    	its.params.beampos.default := 'bottom-left';
	its.params.beampos.context := 'Beam';

	its.params.beamcolor.listname := 'Color';
    	its.params.beamcolor.dlformat := 'beamcolor';
    	its.params.beamcolor.ptype := 'userchoice';
	its.params.beamcolor.popt := 
	    "foreground background black white red green blue yellow";
    	its.params.beamcolor.value := 'foreground';
    	its.params.beamcolor.default := 'foreground';
	its.params.beamcolor.context := 'Beam';
	its.ddd := viewerddd(its.viewer);
	if (is_fail(its.ddd)) fail;
	its.restoringbeam := rec.restoringbeam;
    }

    self.hasbeam := function() {
	if (is_agent(its.ddd)) {
	    return T;
	}
	return F;
    }
    self.ddd := function() {
	return its.ddd;
    }
    
    if ((its.displaytype.dlformat == 'raster') ||
	(its.displaytype.dlformat == 'pksmultibeam')) {
	its.params.colormap.listname := 'Colormap';
	its.params.colormap.dlformat := 'colormap';
	its.params.colormap.ptype := 'choice';
	its.params.colormap.popt := viewer.colormapmanager().colormapnames();
        if (has_field(its.params, 'vistype') &&
            has_field(its.params, 'viscomp') &&
            any(its.params.colormap.popt=='Hot Metal 1')) {
            defcmap := 'Hot Metal 1';   # default colormap for ms raster dd.
            t := its.ddproxy->setcolormap(
                 its.viewer.colormapmanager().colormap(defcmap), 1.0);	
	} else {
	    t := its.ddproxy->
		setcolormap(its.viewer.colormapmanager().colormap('<default>'),
			    1.0);
	    defcmap := its.viewer.colormapmanager().defaultcolormapname();
	}
	its.params.colormap.value := defcmap;
	its.params.colormap.default := defcmap;

	if (its.displaytype.dlformat == 'raster') {
    	  its.params.wedge.listname := 'Color Wedge';
    	  its.params.wedge.dlformat := 'wedge';
    	  its.params.wedge.ptype := 'boolean';
    	  its.params.wedge.value := F;
    	  its.params.wedge.default := F;
	  its.params.wedge.context := 'Color_Wedge';
        }
    }
    
    ############################################################
    ## MAKE WEDGE DD IF NEEDED                                ##
    ############################################################
    its.setwedgeddoptions := function(options) {
    	if (!is_agent(its.wedgedd)) {
	    return F;
    	}
    	rec := [=];
    	if (has_field(options, 'minmaxhist')) {
	    rec.datamin.value := options.minmaxhist[1];
	    rec.datamax.value := options.minmaxhist[2];
    	} else {
	    if (has_field(options, 'datamin')) {
		rec.datamin.value := options.datamin;
	    }
	    if (has_field(options, 'datamax')) {
		rec.datamax.value := options.datamax;
	    }
	}
    	if (has_field(options, 'powercycles')) {
    	    rec.powercycles.value := options.powercycles;
    	}
    	if (has_field(options, 'colormap')) {
	    its.wedgedd->setcolormap(
	      its.viewer.colormapmanager().colormap(options.colormap), 1.0);
    	}
	for (str in field_names(options)) {
	    if (str ~ m/^wedge/) {
		rec[str] := options[str]; 
	    }
	}
    	if (len(rec) > 0) {
    	    t := its.wedgedd->setoptions(rec);
    	}
	if (has_field(options, 'wedge')) {
	    self->wedgerequirementschanged(its.name);
	}
    }
    # color wedge initialization
    its.wedgedd := F;
    if (its.displaytype.dlformat == 'raster') {
	its.wedgedd := its.viewer.widgetset().displaydata('wedge', '','');
	rec := [=];
	rec.dataunit.value := its.ddproxy->dataunit();
	if (has_field(its.params, 'minmaxhist')) { 

	    if (!has_field(rec, 'datamin') || !has_field(rec, 'datamax')) {
		rec.datamin := [=];
		rec.datamax := [=];
	    }
	    rec.datamin.value := its.params.minmaxhist.value[1];
	    rec.datamax.value := its.params.minmaxhist.value[2];

	} else {

	    rec.datamin.value := its.params.datamin.value;
	    rec.datamax.value := its.params.datamax.value;

	}
	
	t := its.wedgedd->setoptions(rec);
	opts := its.wedgedd->getoptions();
	for (str in field_names(opts)) {
	    if (str ~ m/^wedge/) {
		its.params[str] := opts[str];
	    }
	}

	cm := [=];  
	cm.colormap := its.params.colormap.value;
	its.setwedgeddoptions(cm);	# same initial cm as main dd.
    }

    self.wedgedd := function() {
    	if (!is_boolean(its.wedgedd)) {
    	    return its.wedgedd;
    	} else {
    	    fail 'no wedge available';
    	}
    }

    ############################################################
    ## RETURN VARIOUS INFO                                    ##
    ############################################################
    self.name := function() {
	__VCF_('viewerdisplaydata.name');
	return its.name;
    }    
    self.filename := function() {
	__VCF_('viewerdisplaydata.filename');
	return its.dataset.data;
    }
    self.datatype := function() {
	__VCF_('viewerdisplaydata.datatype');
	return its.dataset.dlformat;
    }    
    self.pixeltype := function() {
	__VCF_('viewerdisplaydata.pixeltype');
	str := its.ddproxy->pixeltype();	
	return str;
    }    
    self.ddproxy := function() {
	__VCF_('viewerdisplaydata.ddproxy');
	return its.ddproxy;
    }

    self.zlength := function() {
	__VCF_('viewerdisplaydata.zlength');
	length := its.ddproxy->zlength();
	return length;
    }
    ############################################################
    ## GET/SET OPTIONS                                        ##
    ############################################################
    self.getoptions := function() {
	__VCF_('viewerdisplaydata.getoptions');
	wider its;

	#Backwards compat only.
	if (has_field(its.params, 'minmaxhist')) {
	    if ((!has_field(its.params, 'datamin')) || 
	       (!has_field(its.params, 'datamax'))) {
		its.params.datamin := [=];
		its.params.datamax := [=];
	    }
	    
	    its.params.datamin.value := its.params.minmaxhist.value[1];
	    its.params.datamax.value := its.params.minmaxhist.value[2];
	}

	return its.params;
    }
    self.setoptions := function(newopts, emit=T, id=-1) {
	__VCF_('viewerdisplaydata.setoptions');

	wider its;
	its.viewer.hold();
	rec := [=];
	emitrec := [=];

	# For backwards compat only. Allow use of datamin and datamax 
	# through setoptions
	if (has_field(its.params, 'minmaxhist')) {
	    for (i in field_names(newopts)) {
		if (i == 'datamin' || i == 'datamax') {

		    if (i == 'datamin') {
			if (is_record(newopts[i]) 
			    && has_field(newopts[i], 'value')) {
			    its.params.minmaxhist.value[1] := 
				newopts.datamin.value;
			} else {
			    its.params.minmaxhist.value[1] := newopts.datamin;
			}

		    }
		    if (i == 'datamax') {
			if (is_record(newopts[i]) && 
			    has_field(newopts[i], 'value')) {
			    its.params.minmaxhist.value[2] := 
				newopts.datamax.value;
			} else {
			    its.params.minmaxhist.value[2] := newopts.datamax;
			}

		    }
		    newopts.minmaxhist := its.params.minmaxhist;
		}
	    }
	}#

	for (i in field_names(newopts)) {
	    
	    if (has_field(its.params, i)) {
		if (is_record(newopts[i]) && 
		    has_field(newopts[i], 'value')) {
		    its.params[i].value := newopts[i].value;
		} else {
		    its.params[i].value := newopts[i];
		}
		emitrec[i] := its.params[i];	    
		
		if (has_field(its.params[i], 'ptype')) {
		    if (its.params[i].dlformat == 'colormap') {
			cmname := newopts[i];
			if (has_field(cmname, 'value')) cmname := cmname.value;
			if (is_string(cmname)) {
			    t := its.ddproxy->setcolormap(
			      its.viewer.colormapmanager().colormap(cmname),
							  1.0);
			    cmopt:=[=];  cmopt[i]:=cmname;  # set colormap onto
			    t := its.setwedgeddoptions(cmopt);  # wedgedd too.
			}
		    } else if (its.params[i].dlformat == 'mask') {
		        # stupid eval needs global variables
		        global __txt;
		        __txt := its.params[i].value;
		        if(is_string(__txt)) {
			    tmp2 :=  self.filename();
			    tmp2 =~ s/\//\\\//g;
			    tmp := spaste('__txt =~ s/\\$this/\'',
				          tmp2,
				          '\'/g');
			    x := eval(tmp);
			    if (x) {
			        its.params[i].value := __txt;
			    }
		        }
			rec[i] := its.params[i].value;
			# emitrec[i].value := its.params[i].value;
		    } else if (its.params[i].ptype == 'region') {
			# deal with input into region field, the type is 
			# string and has to be converted into region if exists
			if (is_string(newopts[i]) && is_defined(newopts[i])) {
			    tmp := eval(newopts[i]);
			    if (is_region(tmp)) {
				newopts[i] := tmp;
			    }
			}
			if (is_record(newopts[i])) {
			    if (has_field(newopts[i], "torecord")) {
				rec[i] := newopts[i].torecord();
			    } else if (has_field(newopts[i], "value") &&
				       has_field(newopts[i].value, 
						 "torecord")) {
				rec[i] := newopts[i].value.torecord();
			    } else if (has_field(newopts[i], "value")) {
				rec[i] := newopts[i].value;
			    } else {
				rec[i] := newopts[i];
			    }
			}
			#rec[i] := newopts[i];		    
		    } else if (has_field(its.params[i],'context') &&
			       (its.params[i].context == 'Beam')) {
			its.setbeamoptions(i);
		    } else {
			rec[i] := newopts[i];
		    }
		} else {
		    rec[i] := newopts[i];
		}
	    } else {
		rec[i] := newopts[i];
	    }
	}
	if (len(rec) > 0) {
	    t := its.ddproxy->setoptions(rec);
	    t := its.setwedgeddoptions(rec);
	}

	its.viewer.release();
	self->optionsforgui([options=emitrec, id=id]);
	if (emit) {
	    self->options(emitrec);
	}
	return T;
    }
    its.beamid := F;
    its.setbeamoptions := function(option) {
	wider its;
	if (!is_agent(its.ddd)) fail;
	if (its.params.beam.value) {
	    if (!its.beamid) {
		rec := its.restoringbeam;
		rec.center := dq.quantity("0.1frac 0.1frac");
		rec2 := [=];
		rec2 := its.ddd.makeellipse(center=rec.center, 
					    major=rec.major, 
                                            minor=rec.minor, 
					    positionangle=rec.positionangle,
                                            doreference=T,
					    color=its.params.beamcolor.value,
					    linewidth=
					    its.params.beamlinewidth.value);
		its.beamid := its.ddd.add(rec2);
		if (is_fail(t)) fail;
	    } else {
		rec := [=];
		rec.id := its.beamid;
		if (option == 'beampos') {
		    t := its.params.beampos.value;
		    if (t == 'bottom-right') {
			rec.center := dq.quantity("0.9frac 0.1frac");
		    } else {
			rec.center := dq.quantity("0.1frac 0.1frac");
		    }
		} else {
		    str :=  option ~ s/^beam//;
		    if (is_fail(str)) fail;
		    rec[str] := its.params[option].value;		    
		}
		t := its.ddd.setdescription(rec);
		if (is_fail(t)) fail;
	    }
	} else {
	    if (its.beamid) {
		t := its.ddd.remove(its.beamid);
		if (is_fail(t)) fail;
		its.beamid := F;
	    }
	}
    }

    ############################################################
    ## SAVE/RESTORE OPTIONS (usually called from gui)         ##
    ############################################################
    self.saveoptions := function(setname) {
	__VCF_('viewerdisplaydata.saveoptions');
	t := eval('include \'inputsmanager.g\'');
	t := self.getoptions();
	rec := [=];
	for (i in field_names(t)) {
	    rec[i] := t[i].value;
	}
	note(spaste('Storing options in record field \'', setname,'\''),
	     origin=spaste(its.viewer.title(), 
			   ' (viewerdisplaydata.g)'),
	     priority='NORMAL');
	return inputs.savevalues(self.type(), setname, rec);
    }
    self.restoreoptions := function(setname) {
	__VCF_('viewerdisplaydata.restoreoptions');
	t := eval('include \'inputsmanager.g\'');
	t := inputs.getvalues(self.type(), setname);
	if (len(field_names(t)) > 0) {	
	    # deal with regions
	    for (i in field_names(t)) {
		if (has_field(t[i],'isRegion')) {
		    tmp := itemcontainer();
		    tmp.fromrecord(t[i]);
		    tmp.makeconst();
		    t[i] := tmp;
		}
	    }	    
	    note(spaste('Restoring options from record field \'', 
			setname,'\''),
		 origin=spaste(its.viewer.title(), 
			       ' (viewerdisplaydata.g)'),
		 priority='NORMAL');
	    return self.setoptions(t, emit=F);
	} else {
	    note('No inputs found for given name', 
		 origin=spaste(its.viewer.title(), ' (viewerdisplaydata.g)'),
		 priority='WARN');
	    return F;
	}
    }

    ############################################################
    ## ADD NEW USER CHOICES TO PARAMETER LIST                 ##
    ############################################################
    self.addtouserchoicelist := function(vl) {
	__VCF_('viewerdisplaydata.addtouserchoicelist');
	wider its;
	iparam := vl.param;
	if (its.params[iparam].ptype == 'userchoice') {
	    its.params[iparam].popt := [its.params[iparam].popt,
					vl.newitem];
	    return T;
	}
	fail 'Invalid parameter to update';
    }

    ## ************************************************************ ##
    ##                                                              ##
    ## VIEWERDISPLAYDATAGUI SUBSEQUENCE                             ##
    ##                                                              ##
    ## ************************************************************ ##
    its.viewerdisplaydatagui := subsequence(parent=F, displaydata, 
					    uneditable="", show=T,
					    hasdismiss=F, hasdone=F,
					    widgetset=unset) {
	__VCF_('viewerdisplaydatagui');
	############################################################
	## SANITY CHECK                                           ##
	############################################################
	if (!is_record(displaydata) || !has_field(displaydata, 'type') ||
	    (displaydata.type() != 'viewerdisplaydata')) {
	    return throw(spaste('An invalid viewerdisplaydata was given to a ',
				'viewerdisplaydatagui'));
	}
	if (hasdone && hasdismiss) {
	    note(spaste('An attempt was made to construct a ',
			'viewerdisplaydatagui with both Dismiss AND ',
			'Done buttons'));
	    hasdismiss := F;
	}

	############################################################
	## INITIALISE AND STORE CONSTRUCTOR ARGUMENTS             ##
	############################################################
	its := [=];
	its.parent := parent;
	its.displaydata := displaydata;
	its.uneditable := uneditable;
	its.show := show;
	its.hasdismiss := hasdismiss;
	its.hasdone := hasdone;
	its.wdgts := widgetset;
	
	############################################################
	## BASIC SERVICES                                         ##
	############################################################
	its.type := 'viewerdisplaydatagui';
	self.type := function() {
	    __VCF_('viewerdisplaydatagui.type');
	    return its.type;
	}
	
	self.displaydata := function() {
	    __VCF_('viewerdisplaydatagui.displaydata');
	    return its.displaydata;
	}
	
	its.viewer := its.displaydata.viewer();
	self.viewer := function() {
	    __VCF_('viewerdisplaydatagui.viewer');
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
	    __VCF_('viewerdisplaydatagui.map');
	    wider its;
	    if (!its.ismapped || force) {
		if (its.madeparent) {
		    t := its.parent->map();
		} else {
		    t := its.wholeframe->map();
		}
		its.ismapped := T;
	    }
	}
	self.unmap := function(force=F) {
	    __VCF_('viewerdisplaydatagui.unmap');
	    wider its;
	    if (its.ismapped || force) {
		if (its.madeparent) {
		    t := its.parent->unmap();
		} else {
		    t := its.wholeframe->unmap();
		}
		its.ismapped := F;
	    }
	}
	self.ismapped := function() {
	    __VCF_('viewerdisplaydatagui.ismapped');
	    return its.ismapped;
	}
	
	############################################################
	## DONE FUNCTION                                          ##
	############################################################
	its.dying := F;
	self.done := function() {
	    __VCF_('viewerdisplaydatagui.done');
	    wider its, self;
	    if (its.dying) {
		# prevent multiple done requests
		return F;
	    } its.dying := T;
	    if (viewer::tracedone) {
		print 'viewerdisplaydatagui::done()';
	    }

	    #Kill autogui (use dismiss since done is slow);
	    if (is_agent(its.autogui)) {
		if (has_field(its.autogui, 'dismiss')) {
		    its.wdgts.tk_hold();
		    its.autogui.dismiss();
		    its.wdgts.tk_release();
		}
	    }

	    if (len(its.whenevers) > 0) {
		its.deactivate(its.whenevers);
	    }
	    self.unmap(T);
	    val self := F;
	    val its := F;
	    return T;
	}
	
	############################################################
	## DISMISS FUNCTION                                       ##
	############################################################
	self.dismiss := function() {
	    __VCF_('viewerdisplaydatagu.dismiss');
	    return self.unmap();
	}
	
	############################################################
	## GUI FUNCTION                                           ##
	############################################################
	self.gui := function() {
	    __VCF_('viewerdisplaydatagui.gui');
	    return self.map();
	}
	
	############################################################
	## DISABLE/ENABLE THE GUI                                 ##
	############################################################
	self.disable := function() {
	    __VCF_('viewerdisplaydatagui.disable');
	    if (its.madeparent) {
		t := its.parent->disable();
		t := its.parent->cursor("watch");
	    } 
	    return T;
	}
	self.enable := function() {
	    __VCF_('viewerdisplaydatagui.enable');
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
		its.wdgts.frame(title=spaste(its.displaydata.name(),
					     ' - Adjustment (AIPS++)'));
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
	
	## build the autogui
	its.agparams := its.displaydata.getoptions();
	for (i in split(its.uneditable)) {
	    if (has_field(its.agparams, i)) {
		its.agparams[i].dir := 'out';
	    }
	}
	its.autogui := autogui(params=its.agparams,
			       toplevel=its.wholeframe, autoapply=T,
			       widgetset=its.wdgts,
			       title=its.displaydata.name());
	its.time := -1;
	whenever its.autogui->setoptions do {
	    deactivate;
	    its.time := time();
	    its.displaydata.setoptions($value, id=its.time);
	    activate;
	} its.pushwhenever();
	whenever its.displaydata->optionsforgui do {
	    deactivate;
	    vl := $value;
	    if (((vl.id > 0) && (vl.id != its.time)) || (vl.id < 0)) {
		its.autogui.fillgui(vl.options);
	    }
	    activate;
	} its.pushwhenever();
	whenever its.displaydata->contextoptions do {
	    its.autogui.modifygui($value);
	} its.pushwhenever();
	whenever its.displaydata->localoptions do {
	    its.autogui.fillgui($value);
	}
	whenever its.autogui->newuserchoicelist do {
	    its.displaydata.addtouserchoicelist($value);
	} its.pushwhenever();
	
#	## tracking window
#	its.gui.trkbar := its.wdgts.frame(its.wholeframe, side='left',
#					  height=1, relief='flat', 
#					  expand='x', borderwidth=0,
#					  padx=0, pady=0); 
#	its.gui.trackmsg := its.wdgts.messageline(its.gui.trkbar,
#						  #foreground='darkred',
#						  font='bold');
#	whenever its.displaydata->motion do {
#	    its.gui.trackmsg->postnoforward(as_string($value.formattedworld));
#	} its.pushwhenever();

	its.gui.buttonbar := its.wdgts.frame(its.wholeframe, side='left');
	its.gui.leftbbar := its.wdgts.frame(its.gui.buttonbar, side='left');
	its.gui.bapply := its.wdgts.button(its.gui.leftbbar, 'Apply', 
					   type='action');
	whenever its.gui.bapply->press do {
	    nprms := its.autogui.get();
	} its.pushwhenever();
	
	its.gui.bsave := its.wdgts.button(its.gui.leftbbar, 'Save');
	whenever its.gui.bsave->press do {
	    its.displaydata.saveoptions(its.gui.emethod.get());
	} its.pushwhenever();
	its.gui.brestore := its.wdgts.button(its.gui.leftbbar, 'Restore');
	whenever its.gui.brestore->press do {
	    its.displaydata.restoreoptions(its.gui.emethod.get());
	} its.pushwhenever();
	its.dge := its.wdgts.guientry(width=15);
	if (is_string(its.displaydata.filename())) {
	    tmp := split(its.displaydata.filename(),'/');
	    tmp := spaste(tmp[len(tmp)],':',its.displaydata.displaytype());
	} else {
	    tmp := spaste('Array:',its.displaydata.displaytype());
	}
	its.gui.emethod := its.dge.string(its.gui.leftbbar, 
					  tmp,
					  default=tmp);
#					  'displaydata defaults',
#					  default='displaydata defaults');

	its.gui.rightbbar := its.wdgts.frame(its.gui.buttonbar, side='right');
	if (its.hasdone) {
	    its.gui.bdone := its.wdgts.button(its.gui.rightbbar, 'Done',
					      type='halt');
	    whenever its.gui.bdone->press do {
		self.done();
		
	    } its.pushwhenever();
	}
	if (its.hasdismiss) {
	    its.gui.bdismiss := its.wdgts.button(its.gui.rightbbar, 'Dismiss',
						 type='dismiss');
	    whenever its.gui.bdismiss->press do {
		self.dismiss();
	    } its.pushwhenever();
	}
	
	if (its.show) {
	    t := self.map();
	}
    }
}

const viewerddd := subsequence(viewer) {
    its := [=];
    its.idcount := 1;

    ############################################################
    ## WHENEVER PUSHER                                        ##
    ############################################################
    its.whenevers := [];
    its.pushwhenever := function() {
	wider its;
	its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
    }
    
    its.ddd := viewer.widgetset().drawingdisplaydata();
    whenever its.ddd->objectready do {
	self->objectready($value);
    } its.pushwhenever;

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

    self.done := function() {
	wider its,self;
	its.deactivate(its.whenevers);
	its.ddd := F;
	val its := F;
	val self := F;
	return T;
    }

    self.dddproxy := function() {
	return its.ddd;
    } 
    self.add := function(rec) {
	if (!is_record(rec)) {
	    return throw('argument is not a record');
	}
	rec.id := its.idcount;
	t := its.ddd->add(rec);
	if (is_fail(t)) fail;
	its.idcount +:= 1;
	return rec.id;
    }
    
    self.remove := function(id) {
	if (!is_integer(id)) {
	    return throw('argument is not of type integer');
	}
	t := its.ddd->remove(id);
	if (is_fail(t)) fail;
	return T;
    }
    self.description := function(id) {
	if (!is_integer(id)) {
	    return throw('argument is not of type integer');
	}
	rec := [=];
	rec := its.ddd->description(id);
	return rec;	
    }
    self.setdescription := function(rec) {
	if (!is_record(rec)) {
	    return throw('argument is not a record');
	}
	if (!has_field(rec,'id')) {
	    fail 'record has no "id" field';
	}
	t := its.ddd->setdescription(rec);
	return T;	
    }
   
    self.makeellipse := function(center, major, minor, positionangle,
				 color='foreground', linewidth=1,
				 outline=T, movable=T, editable=F,
                                 doreference=F,
				 label='',
				 drawrectangle=F) {
	wider its;
	if (!is_quantity(major) || !is_quantity(minor) || 
	    !is_quantity(positionangle)) {
	    fail 'argument is not a quantity';
	}
	rec := [=];
#
        ok := length(center)==2 && is_quantity(center[1]) &&
              is_quantity(center[2]);
        if (!ok) {
           fail 'Center must hold a vector of quantities of length 2'
        }
	rec.center := center;
#
	rec.major := major;
	rec.minor := minor;
	rec.positionangle := positionangle;
	rec.type := 'ellipse';
	rec.outline := outline;
	rec.editable := editable;
	rec.movable := movable;
	rec.color := color;
	rec.linewidth := linewidth;
	rec.label := label;
	rec.rectangle := drawrectangle;	
        rec.doreference := doreference;
	return rec;
    }
    self.makerectangle := function(blc,trc,
				   color='foreground', linewidth=1,
				   movable=T, editable=F,
				   label='') {
	wider its;
	if (length(blc) < 2 || length(trc) < 2 || 
	    (length(blc)!=length(trc)) ) {
	    return throw('illegal length of blc,trc');
	}
	
	rec := [=];
	rec.blc := blc;
	rec.trc := trc
	rec.type := 'rectangle';
	rec.editable := editable;
	rec.movable := movable;
	rec.color := color;
	rec.linewidth := linewidth;
	rec.label := label;
	return rec;
    }
    self.makepolygon := function(x, y, 
				 color='foreground', linewidth=1,
				 outline=T, movable=T, editable=F,
				 label='') {

	wider its;
	if (!is_quantity(x) || !is_quantity(y)) {
	    fail 'argument is not a quantity';
	}
	rec := [=];
	rec.x := x;
	rec.y := y;
	rec.type := 'polygon';
	rec.outline := outline;
	rec.editable := editable;
	rec.movable := movable;
	rec.color := color;
	rec.linewidth := linewidth;
	rec.label := label;
	return rec;
    }
}
