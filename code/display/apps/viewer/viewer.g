# viewer.g: AIPS++ data viewer tool
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
# $Id: viewer.g,v 19.9 2005/06/15 18:10:55 cvsmgr Exp $


pragma include once;

include 'guimisc.g';
include 'image.g';
include 'imagetemporary.g';
include 'autogui.g';
include 'getrc.g';
include 'note.g';
include 'popuphelp.g';
include 'printer.g';
include 'guientry.g';
include 'catalog.g';
include 'plugins.g';
include 'ddlws.g';

## ************************************************************ ##
##                                                              ##
## VIEWER SUBSEQUENCE                                           ##
##                                                              ##
## ************************************************************ ##
const viewer := subsequence(title='viewer', deleteatexit=T, widgetset=ddlws) {
    __VCF_('viewer');
    
    ############################################################
    ## CHECK THAT DISPLAY LIBRARY IS LOADED                   ##
    ############################################################
    if (!is_record(widgetset) || !has_field(widgetset, 'type') ||
	!is_function(widgetset.type) || 
	(widgetset.type() != 'widgetserver') ||
	!has_field(widgetset, 'pixelcanvas') ||
	!has_field(widgetset, 'paneldisplay') ||
	!has_field(widgetset, 'displaydata') ||
	!has_field(widgetset, 'colormap') ||
	!has_field(widgetset, 'mwcanimator') ||
	!has_field(widgetset, 'pspixelcanvas')) {
	return throw(spaste('Could not create a viewer object because the ',
			    'supplied widgetserver is either invalid, or ',
			    'does not support the viewer'));
    }

    ############################################################
    ## INITIALISE                                             ##
    ############################################################
    its := [=];
    its.title := title;
    its.deleteatexit := deleteatexit;
    its.wdgts := widgetset;

    ############################################################
    ## BASIC SERVICES                                         ##
    ############################################################
    its.type := 'viewer';
    self.type := function() {
	__VCF_('viewer.type');
	return its.type;
    }
    #do not document
    its.id := time();
    self.id := function() {
	__VCF_('viewer.id');
	return its.id;
    }

    self.title := function() { 
	__VCF_('viewer.title');
	return its.title;
    }

    self.widgetset := function() {
	__VCF_('viewer.widgetset');
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
	return T;
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
    self.dying := function() {
	__VCF_('viewer.dying');
	return its.dying;
    }
    self.done := function(force=F) {
	__VCF_('viewer.done');
	wider its, self;
	if (its.dying) {
	    # prevent multiple done requests
	    return F;
	}
	if (!force && any(symbol_names() == 'dv')) {
	    if (is_agent(dv) && has_field(dv, 'id') &&
		is_function(dv.id)) {
		if (dv.id() == its.id) {
		    return throw('Cannot \'done\' default viewer');
		}
	    }
	}
	its.dying := T;
	if (viewer::tracedone) {
	    print 'viewer::done()';
	}
	if (len(its.whenevers) > 0) {
	    its.deactivate(its.whenevers);
	}
	its.wdgts.tk_hold();
	## viewerdatamanagers
	if (len(its.datamanagers) > 0) {
	    for (i in 1:len(its.datamanagers)) {
		if (is_agent(its.datamanagers[i])) {
		    its.datamanagers[i].done();
		}
	    }
	}
	## viewerdisplaydatas
	self.deleteall(quiet=T);
	# cleanup any temporary persistent images
	if (len(its.imtemp) > 0) {
	    for (i in 1:len(its.imtemp)) {
		if (is_agent(its.imtemp[i])) {
		    its.imtemp[i].done();
		}
	    }
	}
	# done the toolkit
	if (is_agent(its.toolkit)) {
	    its.toolkit.done();
	}
	## viewerdisplaypanels
	if (len(its.displaypanels) > 0) {
	    for (i in 1:len(its.displaypanels)) {
		if (is_agent(its.displaypanels[i])) {
		    its.displaypanels[i].done();
		}
	    }
	}
	## viewercolormapmanager
	if (is_agent(its.colormapmanager)) {
	    its.colormapmanager.done();
	}

	its.wdgts.tk_release();
	if (viewer::tracedone) {
	    note(spaste('viewer \'', its.title, '\' closing down'), 
		 priority='NORMAL', 
		 origin=spaste(its.title, ' (viewer.g)'));
	}
	val its := F;
	val self := F;
	return T;
    }
    if (its.deleteatexit) {
	whenever system->exit do {
	    self.done(force=T);
	} its.pushwhenever();
    }

    ############################################################
    ## GUI FUNCTION                                           ##
    ############################################################
    self.gui := function(datamanager=T, displaypanel=T) {
	__VCF_('viewer.gui');
	if (datamanager) {
	    t := self.newdatamanager(show=T, hasdone=T);
	} 
	if (displaypanel) {
	    t := self.newdisplaypanel(hasdone=T,autoregister=T);
	}
	return T;
    }

    ############################################################
    ## MAKE A NEW DATAMANAGER                                ##
    ############################################################
    its.datamanagers := [=];
    self.registerdatamanager := function(datamanager) {
	__VCF_('viewer.registerdatamanager');
	wider its;
	if (is_agent(datamanager) &&
	    has_field(datamanager, 'type') &&
	    (datamanager.type() == 'viewerdatamanager')) {
	    its.datamanagers[len(its.datamanagers) + 1] := datamanager;
	} else {
	    return throw(spaste('An invalid viewerdatamanager attempted ',
				'to register as a datamanager'),
			 origin=spaste(its.title, ' (viewer.g)'),
			 priority='SEVERE');
	}
	return T;
    }
    self.newdatamanager := function(parent=F, show=T,
				    hasdismiss=F, hasdone=F,
				    widgetset=unset) {
	__VCF_('viewer.newdatamanager');
	temp := viewerdatamanager(parent, self, show, 
				  hasdismiss, hasdone, widgetset);
	return temp;
    }

    ############################################################
    ## MAKE A NEW DISPLAYPANEL                                ##
    ############################################################
    its.displaypanels := [=];
    self.registerdisplaypanel := function(displaypanel) {
	__VCF_('viewer.registerdisplaypanel');
	wider its;
	if (is_agent(displaypanel) &&
	    has_field(displaypanel, 'type') &&
	    (displaypanel.type() == 'viewerdisplaypanel')) {
	    its.displaypanels[len(its.displaypanels) + 1] := displaypanel;
	} else {
	    return throw(spaste('An invalid viewerdisplaypanel attempted ',
				'to register as a displaypanel'),
			 origin=spaste(its.title, ' (viewer.g)'),
			 priority='SEVERE');
	}
	return T;
    }
    self.newdisplaypanel := function(parent=F, width=375, height=350,
				     nx=1,ny=1,
				     maptype='index', newcmap=unset,
				     mincolors=unset, maxcolors=unset,
				     autoregister=F, holdsdata=T,
				     show=T, hasgui=unset, 
				     guihasmenubar=T, guihascontrolbox=T,
				     guihasanimator=T, guihasbuttons=T,
				     guihastracking=T,
				     hasdismiss=unset, hasdone=unset,
				     isolationmode=F, widgetset=unset,
				     slicepanel=F) {
	__VCF_('viewer.newdisplaypanel');
	wider its;
	its.wdgts.tk_hold();
	if (is_boolean(newcmap) || is_agent(parent)) {
	    if (!is_boolean(newcmap)) {
		newcmap := F;
	    }
	    if (!slicepanel) {
		temp := viewerdisplaypanel(parent, self, width, height,
					   nx,ny,
					   maptype, newcmap, 
					   mincolors, maxcolors, 
					   autoregister, holdsdata,
					   show, widgetset);
	    } else {
		temp := viewerslicedp(parent, self, width, height, maptype,
				      newcmap,mincolors, maxcolors,
				      autoregister, holdsdata,
				      show, widgetset);
	    }
	    
	} else if (is_unset(newcmap)) {
	    if (!slicepanel) {
		temp := viewerdisplaypanel(parent, self, width, height,
					   nx,ny,
					   maptype, F,
					   mincolors, maxcolors,
					   autoregister, holdsdata,
					   show, widgetset);
	    } else {
		temp := viewerslicedp(parent, self, width, height, maptype,
				      F, mincolors, maxcolors,
				      autoregister, holdsdata,
				      show, widgetset);		
	    }
	    if (is_fail(temp)) {
		if (!any(split(to_lower(temp::message)) == 'visual') &&
		    !any(split(to_lower(temp::message)) == 'visuals')) {
		    note('Resorting to private (flashing) colormap',
			 origin=spaste(its.title, ' (viewer.g)'),
			 priority='NORMAL');
		    if (!slicepanel) {
			temp := viewerdisplaypanel(parent, self, width, height,
						   nx,ny,
						   maptype, T,
						   mincolors, maxcolors,
						   autoregister, holdsdata,
						   show, widgetset);
		    } else {
			temp := viewerslicedp(parent, self, width,
					      height, maptype,
					      F, mincolors, maxcolors,
					      autoregister, holdsdata,
					      show, widgetset);
		    }
		} else {
		    its.wdgts.tk_release();
		    return throw(spaste('Failed to create displaypanel:\n',
					temp::message));
		}
	    }
	} else {
	    its.wdgts.tk_release();
	    return throw(spaste('Invalid value for \'newcmap\' argument'));
	}
	if (is_agent(temp)) {
	    if ((is_unset(hasgui) && is_boolean(parent) && !parent) ||
		(is_boolean(hasgui) && hasgui)) {
		if (is_agent(parent) && is_unset(hasdismiss) &&
		    is_unset(hasdone)) {
		    hasdismiss := F;
		    hasdone := F;
		}
		temp.addgui(guihasmenubar=guihasmenubar,
			    guihascontrolbox=guihascontrolbox,
			    guihasanimator=guihasanimator,
			    guihasbuttons=guihasbuttons,
			    guihastracking=guihastracking,
			    hasdismiss=hasdismiss, hasdone=hasdone,
			    isolationmode=isolationmode, show=show);
	    }
	} else {
	    its.wdgts.tk_release();
	    return throw(spaste('Failed to create displaypanel'));
	}
	its.wdgts.tk_release();
	return temp;
    }
    self.alldisplaypanels := function() {
	__VCF_('viewer.alldisplaypanels');
	rec := [=];
	k := 1;
	if (len(its.displaypanels) > 0) {
	    for (i in 1:len(its.displaypanels)) {
		if (is_agent(its.displaypanels[i])) {
		    rec[as_string(k)] := its.displaypanels[i];
		}
		k +:= 1;
	    }
	}
	return rec;
    }

    ############################################################
    ## global hold/release - these just pass the hold/release ##
    ## onto all the displaypanels                             ##
    ############################################################
    self.hold := function() {
	__VCF_('viewer.hold');
	if (len(its.displaypanels) > 0) {
	    for (i in field_names(its.displaypanels)) {
		if (is_agent(its.displaypanels[i])) {
		    its.displaypanels[i].hold();
		}
	    }
	}
	return T;
    }
    self.release := function() {
	__VCF_('viewer.release');
	if (len(its.displaypanels) > 0) {
	    for (i in field_names(its.displaypanels)) {
		if (is_agent(its.displaypanels[i])) {
		    its.displaypanels[i].release();
		}
	    }
	}
	return T;
    }

    ############################################################
    ## global disable/enable - these just pass the disable/   ##
    ## enable onto all the displaypanels and datamanagers    ##
    ############################################################
    self.disable := function() {
	__VCF_('viewer.disable');
	if (len(its.displaypanels) > 0) {
	    for (i in field_names(its.displaypanels)) {
		if (is_agent(its.displaypanels[i])) {
		    its.displaypanels[i].disable();
		}
	    }
	}
	if (len(its.datamanagers) > 0) {
	    for (i in field_names(its.datamanagers)) {
		if (is_agent(its.datamanagers[i])) {
		    its.datamanagers[i].disable();
		}
	    }
	}
	return T;
    }
    self.enable := function() {
	__VCF_('viewer.enable');
	if (len(its.displaypanels) > 0) {
	    for (i in field_names(its.displaypanels)) {
		if (is_agent(its.displaypanels[i])) {
		    its.displaypanels[i].enable();
		}
	    }
	}
	if (len(its.datamanagers) > 0) {
	    for (i in field_names(its.datamanagers)) {
		if (is_agent(its.datamanagers[i])) {
		    its.datamanagers[i].enable();
		}
	    }
	}
	return T;
    }

    ############################################################
    ## DATASET HANDLING                                       ##
    ############################################################
    its.is_image := function(thing) {
	#if (!is_record(thing)) return F;
	#if (!has_field(thing, 'type')) return F;
	#if (!is_function(thing.type)) return F;
	#if (!(thing.type() == 'image')) return F;
	if (!is_image(thing)) return F;
	#if (!thing.ispersistent()) return F;
	return T;
    }
    its.is_array := function(thing) {
	if (!is_numeric(thing)) return F;
	if (len(shape(thing)) < 2) return F;
	return T;
    }
    its.is_table := function(thing) {
	#if (!is_record(thing)) return F;
	#if (!has_field(thing, 'type')) return F;
	#if (!is_function(thing.type)) return F;
	if (!is_table(thing)) return F;
	#if (!(thing.type() == 'table')) return F;
	return T;
    }
    self.updatedatasets := function() {
	__VCF_('viewer.updatedatasets');
	wider its;
	its.datasets := [=];

	# null - for displaydatas needing no data
	its.datasets.null.data := "null";
	its.datasets.null.listname := 'none';
	its.datasets.null.dlformat := "null";

	# image
	list := symbol_names(its.is_image);
	if (len(list) > 0) {
	    sort(list);
	    for (i in list) {
		if (!(i ~ m/^_/)) {
		    eval(spaste('__viewer_temp := ', i, '.name()'));
		    #its.datasets[i].data := __viewer_temp;
		    its.datasets[i].data := eval(i);
		    temp := split(__viewer_temp, '/');
		    its.datasets[i].listname := spaste('image:', 
							temp[len(temp)]);
		    its.datasets[i].dlformat := "image";
		}
	    }
	}

	# table
	list := symbol_names(its.is_table);
	if (len(list) > 0) {
	    sort(list);
	    for (i in list) {
		if (!(i ~ m/^_/)) {
		    eval(spaste('__viewer_temp := ', i, '.name()'));
		    its.datasets[i].data := __viewer_temp;
		    temp := split(__viewer_temp, '/');
		    its.datasets[i].listname := spaste('table:',
						       temp[len(temp)]);
		    its.datasets[i].dlformat := 'table';
		}
	    }
	}

	# array
	list := symbol_names(its.is_array);
	if (len(list) > 0) {
	    sort(list);
	    for (i in list) {
		if (!(i ~ m/^_/)) {
		    its.datasets[i].data := eval(i);
		    its.datasets[i].listname := spaste('array:', i);
		    its.datasets[i].dlformat := "array";
		}
	    }
	}

	self->datasets_updated();
	return T;
    }
    its.firstupdate := T;
    self.validdatasets := function(dataformat) {
	__VCF_('viewer.validdatasets');
	rec := [=];
	for (i in field_names(its.datasets)) {
	    for (j in its.displaytypes[dataformat].validfor) {
		if (any(its.datasets[i].dlformat == j)) {
		    rec[i] := its.datasets[i];
		    break;
		}
	    }
	}
	return rec;
    }
    self.datasetfromname := function(name) {
	__VCF_('viewer.datasetfromname');
	for (i in field_names(its.datasets)) {
	    if (its.datasets[i].listname == name) {
		return its.datasets[i];
	    }
	}
	fail 'Couldn\'t find named dataset';
    }

    ############################################################
    ## DISPLAYTYPE HANDLING                                   ##
    ############################################################
    
    # TableAsXXX temporarily disabled
    # use self.createdata or viewerdisplaydata instead of self.loaddata
    its.displaytypes := [=];
    its.displaytypes.raster.listname := 'Raster Image';
    its.displaytypes.raster.validfor := "image array ms";# table";
    its.displaytypes.raster.dlformat := "raster";
    its.displaytypes.contour.listname := 'Contour Map';
    its.displaytypes.contour.validfor := "image array";# table";
    its.displaytypes.contour.dlformat := "contour";
    its.displaytypes.skycatalog.listname := 'Sky catalog overlay';
    its.displaytypes.skycatalog.validfor := "table";
    its.displaytypes.skycatalog.dlformat := "skycatalog";
    its.displaytypes.simpleaxes.listname := 'Simple axis labels';
    its.displaytypes.simpleaxes.validfor := "null";
    its.displaytypes.simpleaxes.dlformat := "simpleaxes";
    its.displaytypes.worldaxes.listname := 'World axis labels';
    its.displaytypes.worldaxes.validfor := "null";
    its.displaytypes.worldaxes.dlformat := "worldaxes";
    its.displaytypes.vector.listname := 'Vector Map';
    its.displaytypes.vector.validfor := "image array";
    its.displaytypes.vector.dlformat := "vector";
    its.displaytypes.marker.listname := 'Marker Map';
    its.displaytypes.marker.validfor := "image array";
    its.displaytypes.marker.dlformat := 'marker';
    its.displaytypes.profile.listname := 'Profile Plot';
    its.displaytypes.profile.dlformat := 'profile';
    its.displaytypes.profile.validfor := 'null';
    #its.displaytypes.plot.listname := 'XY Plot';
    #its.displaytypes.plot.validfor := "table";
    #its.displaytypes.plot.dlformat := "plot";

    its.displaytypes.scroll.listname := 'Scrolling Raster';
    its.displaytypes.scroll.validfor := 'null';           
    its.displaytypes.scroll.dlformat := 'scroll';       
    its.displaytypes.pksmultibeam.listname := 'PKS Multibeam';
    its.displaytypes.pksmultibeam.validfor := 'null';        
    its.displaytypes.pksmultibeam.dlformat := 'pksmultibeam'; 

    self.alldisplaytypes := function() {
	__VCF_('viewer.alldisplaytypes');
	return its.displaytypes;
    }
    self.validdisplaytypes := function(dataformat) {
	__VCF_('viewer.validdisplaytypes');
	rec := [=];
	for (i in field_names(its.displaytypes)) {
	    if (any(its.displaytypes[i].validfor == dataformat)) {
		rec[i] := its.displaytypes[i];
	    }
	}
	return rec;
    }
    self.displaytypefromname := function(name) {
	__VCF_('viewer.displaytypefromname');
	for (i in field_names(its.displaytypes)) {
	    if (its.displaytypes[i].listname == name) {
		return its.displaytypes[i];
	    }
	}
	fail 'Couldn\'t find named displaytype';
    }    

    ############################################################
    ## DISPLAYDATA HANDLING                                   ##
    ############################################################
    its.displaydatas := [=];
    its.datasets := [=];
    its.imtemp := [=];
    ############################################################
    ## explicit load from command line: give string or array, ##
    ## type, and whether to register it on all auto panels... ##
    ############################################################

    self.maketempimage := function(data,type='image') {
	wider its;
	self.disable();
	n := len(its.imtemp);
	if (n > 0) {
	    for (i in 1:n) {
		if (has_field(its.imtemp[i],'data') &&
		    its.imtemp[i].data == data) {
		    self.enable();
		    return its.imtemp[i].access();
		}
	    }
	}
	name := data;
	if (type == 'image' && is_string(data)) {
	    data := eval(data);
	}
	its.imtemp[n+1] := imagetemporary(data,type);
	fullpath := its.imtemp[n+1].access();
	its.imtemp[n+1].data := name;
	self.enable();
	return fullpath;
    }

    self.loaddata := function(data, drawtype, autoregister=F) {
	# this basically does the same as the viewerdatamanagergui
	wider its;
	__VCF_('viewer.loaddata');
	self.disable();
	i := 1;
	name := spaste('explicit-load:', as_string(i));
	while (has_field(its.datasets, name)) {
	    i := i + 1;
	    name := spaste('explicit-load:', as_string(i));
	}
	localdataset := [=];
	madepersistent := F;
	if (is_string(data)) {
	    tmp := dc.whatis(data);
	    if (tmp.type == 'Image' || tmp.type == 'FITS' ||
                tmp.type == 'Miriad Image') { 
		type := 'image';
            } else if (tmp.type == 'Gipsy') {
		type := 'image';
		temp := split(data, '/');
		data := self.maketempimage(data,tmp.type);
		if (is_fail(data)) {
		    self.enable();
		    fail spaste('Couldn\'t create temporary image');
		}
		localdataset.listname := spaste(type,':', temp[len(temp)]);
		madepersistent := T;
	    } else if (tmp.type == 'Skycatalog' || tmp.type == 'IERS' ) {
		# IERS is the testskycatalog format
		type := 'table';
            } else if (tmp.type == 'Measurement Set') {
                type := 'ms';
	    #} else if (data == 'null') {
		# nothing to do
	    } else {		
		self.enable();
		fail spaste('Data of type \"',tmp.type,'\" not supported.');
	    }	    
	    localdataset.data := data;
	    if (!has_field(localdataset,'listname')) {
		temp := split(localdataset.data, '/');
		localdataset.listname := spaste(type,':', temp[len(temp)]);
	    }
	    localdataset.dlformat := type;
	} else if (its.is_image(data)) {
	    if (!data.ispersistent()) {
		data := self.maketempimage(data);
		if (is_fail(data)) {
		    self.enable();
		    fail spaste('Couldn\'t create temporary image');
		}		
		madepersistent := T;
	    } else {
		# we were given an image, so grab its name and continue
		data := data.name();
	    }
	    localdataset.data := data;
	    temp := split(localdataset.data, '/');
	    localdataset.listname := spaste('image:', temp[len(temp)]);
	    localdataset.dlformat := "image";	    
	} else if (its.is_table(data)) {
	    localdataset.data := data.name();
	    temp := split(localdataset.data, '/');
	    localdataset.listname := spaste('table:', temp[len(temp)]);
	    localdataset.dlformat := "table";
	} else if (its.is_array(data)) {
	    # we were given an array...
	    localdataset.data := data;
	    localdataset.listname := spaste('array:', name);
	    localdataset.dlformat := "array";
	} else if (is_agent(data) && data.type() == 'viewerdisplaydata') {
#	    print data.type();
	    localdataset.data := data;
	    localdataset.listname := spaste('profile:', name);
	    localdataset.dlformat := "profile";
        } else if (is_unset(data)) {
            # we were given an array...  
            localdataset.data := 'null'; 
            localdataset.listname := spaste('other:', name);  
            localdataset.dlformat := "null";  
	} else {
	    self.enable();
	    fail 'Cripes - I dunno what data you gave me mate...';
	}

	result := self.createdata(localdataset, 
				  its.displaytypes[drawtype]);
	if (is_fail(result)) {
	    self.enable();
	    return throw(spaste('viewer.loaddata failed; ', result::message));
	}
	if (madepersistent) {
	    its.imtemp[len(its.imtemp)].name := result.name();
	}
	if (autoregister) {
	    self.autoregister(result);
	}
	self.enable();
	return ref result;
    };
 
    self.autoregister := function(displaydata) {
	__VCF_('viewer.autoregister');
	for (i in 1:len(its.displaypanels)) {
	    temp := ref its.displaypanels[i];
	    if (is_agent(temp) && temp.autoregister() && temp.holdsdata()) {
		temp.register(displaydata);
	    }
	}
	return T;
    }

    self.deleteimtemporary := function(ddname) {
	wider its;
	# delete temporary persistent image
	for (str in field_names(its.imtemp)) {
	    if (is_record(its.imtemp[str]) && 
		has_field(its.imtemp[str],'name') ) {
		if (its.imtemp[str].name == ddname) {
		    its.imtemp[str].done();
		}
	    }
	}
	return T;
    }

    ############################################################
    ## create data using internal dataset, displaytype        ##
    ## record structures...                                   ##
    ############################################################
    self.createdata := function(dataset, displaytype) {
	__VCF_('viewer.createdata');
	self.disable();
	wider its;
	i := 1;
	name := spaste(dataset.listname, '(', displaytype.listname, ':',
		       as_string(i), ')');
	while (has_field(its.displaydatas, name)) {
	    i := i + 1;
	    name := spaste(dataset.listname, '(', displaytype.listname, ':',
			   as_string(i), ')');
	}
	tvdd := viewerdisplaydata(self, name, displaytype, 
				  dataset);
	if (is_fail(tvdd)) {
	    self.enable();
	    fail (spaste('viewer.createdata failed; ', tvdd::message));
	} else {
	    its.displaydatas[name] := tvdd;
	    whenever its.displaydatas[name]->done do {
		if (is_string($value)) {
		    self.deleteimtemporary($value);
		}
	    } its.pushwhenever();
	}
	self.emitdisplaydatalist();
	self.enable();
	return ref its.displaydatas[name];
    }

    ############################################################
    ## remove a displaydata object from memory/list           ##
    ############################################################

    self.deletedata := function(displaydata, doneit=T, quiet=F) {
	__VCF_('viewer.deletedata');
	wider its;
	self.hold();
	if (len(its.displaypanels) > 0) {
	    for (i in 1:len(its.displaypanels)) {
		if (is_agent(its.displaypanels[i]) &&
		    its.displaypanels[i].holdsdata()) {
		    its.displaypanels[i].unregister(displaydata);
		}
	    }
	}
	if (doneit) {
	    displaydata.done();
	}
	self.release();
	if (!quiet) {
	    self.emitdisplaydatalist();
	}
	return T;
    }
    self.deleteall := function(doneit=T, quiet=F) {
	__VCF_('viewer.deleteall');
	if (len(its.displaydatas) > 0) {
	    self.hold();
	    for (i in field_names(its.displaydatas)) {
		if (is_agent(its.displaydatas[i])) {
		    self.deletedata(its.displaydatas[i], doneit=doneit,
				    quiet=quiet);
		}
	    } 
	    self.release();
	}
	return T;
    }
    self.emitdisplaydatalist := function() {
	__VCF_('viewer.emitdisplaydatalist');
	self->displaydatas(self.alldisplaydatas());
	return T;
    }
    self.displaydatafromname := function(name) {
	__VCF_('viewer.displaydatafromname');
	for (i in field_names(its.displaydatas)) {
	    if (is_agent(its.displaydatas[i]) && 
		(its.displaydatas[i].name() == name)) {
		return its.displaydatas[i];
	    }
	}
	fail 'couldn\'t find named displaydata';
    }
    self.alldisplaydatas := function() {
	__VCF_('viewer.alldisplaydatas');
	rec := [=];
	for (i in field_names(its.displaydatas)) {
	    if (is_agent(its.displaydatas[i])) {
		rec[i] := its.displaydatas[i];
	    }
	}
	return rec;
    }

    its.toolkit := viewertoolkit(self);
    self.toolkit := function() {
	__VCF_('viewer.toolkit');
	return its.toolkit;
    }

    ############################################################
    ## COLORMAPS                                              ##
    ############################################################
    its.colormapmanager := F;
    self.colormapmanager := function() {
	__VCF_('viewer.colormapmanager');
	return its.colormapmanager;
    }
    its.colormapmanager := viewercolormapmanager(self);
    its.colormapmanagerguis := [];
    self.newcolormapmanagergui := function(parent=F, show=T, hasdismiss=F,
					   hasdone=F, widgetset=unset) {
	__VCF_('viewer.newcolormapmanagergui');
	return its.colormapmanager.gui(parent, show, hasdismiss,
				       hasdone, widgetset);
    }

    ############################################################
    ## PRINTING SUPPORT FUNCTION/S                            ##
    ############################################################
    its.quanta := F;
    its.os := F;
    its.filecount := 1;
    self.generatefilename := function(base=unset, ext='') {
	__VCF_('viewer.generatefilename');
	wider its;
	originalbase := base;
	if (is_unset(base) || !is_string(base)) {
	    #base := its.title;
	    base := 'viewer';
	}
	if (is_boolean(its.quanta)) {
	    t := eval('include \'quanta.g\'');
	    its.quanta := quanta();
	}
	base := spaste(base, '.', 
		       split(its.quanta.time(its.quanta.quantity('today'),
					     form="dmy local"), '/')[1]);
	base := spaste(base, ':', its.filecount);
	its.filecount := its.filecount + 1;
	if (len(ext) > 0) {
	    base := spaste(base, '.', ext);
	}
	if (is_boolean(its.os)) {
	    t := eval('include \'os.g\'');
	    its.os := os();
	}
	if (its.os.fileexists(base)) {
	    return self.generatefilename(originalbase, ext);
	} else {
	    return base;
	}
    }

    ############################################################
    ## POSITION TRACKING SUPPORT                              ##
    ############################################################
    self.motioneventhandler := function(ddname, motionevent) {
	__VCF_('viewer.motioneventhandler');
	wcid := motionevent.worldcanvasid;
	thedps := self.alldisplaypanels();
	if (len(thedps) > 0) {
	    for (i in 1:len(thedps)) {
		if (any(thedps[i].worldcanvasid() == wcid)) {
		    thedps[i].motioneventhandler(ddname, motionevent);
		}
	    }
	}
	return T;
    }
    t := plugins.attach('viewer', self);
}

## do not document
viewerlistarea := subsequence(parent, title, width=20, height=6,
			      buttons="", multiple=F,
			      widgetset=ddlws) {
    its := [=];
    its.whenevers := [];
    its.pushwhenever := function() {
	wider its;
	its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
	return T;
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

    its.frame := widgetset.frame(parent, side='top', relief='groove');
    if (strlen(title) > 0) {
	its.subf0 := widgetset.frame(its.frame, side='left', relief='flat', 
				expand='x');
	its.title := widgetset.label(its.subf0, title);
    }
    its.subf1 := widgetset.frame(its.frame, side='left', relief='flat');
    if (multiple) {
	mode := 'extended';
    } else {
	mode := 'browse';
    }
    its.list := widgetset.listbox(its.subf1, width=width, height=height,
				relief='sunken', fill='both', mode=mode);
    its.scroll := widgetset.scrollbar(its.subf1);
    whenever its.scroll->scroll do {
	t := its.list->view($value);
    } its.pushwhenever();
    whenever its.list->yscroll do {
	t := its.scroll->view($value);
    } its.pushwhenever();
    whenever its.list->select do {
	if (its.listcount > 0) {
	    t := its.list->selection();
	    if (len(t) > 0) {
		self->select(its.list->get(t[1]));
	    } else {
		note('Steady on there! - just one at a time please',
		     priority='WARN', origin='viewer.g');
	    }
	}
    } its.pushwhenever();
    
    its.subf2 := F;
    if (len(buttons)) {
	its.subf2 := widgetset.frame(its.frame, side='left', relief='flat',
				   expand='x');
	for (i in buttons) {
	    its.button[i] := widgetset.button(its.subf2, i, value=i);
	    whenever its.button[i]->press do {
		self->press($value);
	    } its.pushwhenever();
	}
    }
    self.done := function() {
	wider its,self;
	its.deactivate(its.whenevers);
	val its := F;
	val self := F;
    }
    self.enablebutton := function(name, enable=T) {
	for (i in name) {
	    if (has_field(its.button, i)) {
		t := its.button[i]->disabled(!enable);
	    }
	}
    }
    
    its.listcount := 0;
    self.fill := function(record) {
	wider its;
	t := its.list->delete('start','end');
	its.listcount := 0;
	if (!is_record(record) || !len(record)) {
	    return;
	}
	for (i in field_names(record)) {
	    if (has_field(record[i], 'listname')) {
		t := its.list->insert(record[i].listname);
	    } else if (has_field(record[i], 'name') &&
		       is_function(record[i].name)) {
		t := its.list->insert(record[i].name());
	    }
	    its.listcount := its.listcount + 1;
	}
    }
    self.deselect := function() {
	t := its.list->clear('start','end');
    }
}


############################################################
## VIEWERTOOLKIT SUBSEQUENCE                              ##
############################################################
viewertoolkit := subsequence(viewer, widgetset=unset) {

    ############################################################
    ## SANITY CHECK                                           ##
    ############################################################
    if (!is_record(viewer) || !has_field(viewer, 'type') ||
	(viewer.type() != 'viewer')) {
	return throw('An invalid viewer was given to a viewertoolkit');
    }

    ############################################################
    ## INITIALISE AND STORE CONSTRUCTOR ARGUMENTS             ##
    ############################################################
    its := [=];
    its.viewer := viewer;
    its.wdgts := widgetset;

    ############################################################
    ## BASIC SERVICES                                         ##
    ############################################################
    its.type := 'viewertoolkit';
    self.type := function() {
	__VCF_('viewertoolkit.type');
	return its.type;
    }
    self.viewer := function() {
	__VCF_('viewertoolkit.viewer');
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
    self.done := function() {
	wider its,self;	
	val its := F;
	val self := F;
    }
    ############################################################
    ## TOOLKIT SETUP                                          ##
    ############################################################
    its.tools := ['Zooming', 
		  'Panning',
		  'Colormap fiddling - shift/slope', 
		  'Colormap fiddling - brightness/contrast',
		  'Positioning',
		  'Rectangle drawing',
		  'Polygon drawing',
		  'Polyline drawing',
		  'Multipanel crosshair',
		  'Annotations'];
    its.toolshorthands := ['zoom',
			   'pan', 
			   'standardcolormap',
			   'mapcolormap',
			   'position',
			   'rectangle',
			   'polygon',
			   'polyline',
			   'multicrosshair',
			   'annotations'];
    its.basebitmaps := ['magnify',
			'hand',
			'arrowcross',
			'brightcontrast',
			'crosshair',
			'rectregion',
			'polyregion',
			'polyline',
			'mpcrosshair',
			'dontuse'];
    
    its.commonhelp := '\n<Esc> to cancel';
    its.helptext := [spaste('\nUse the assigned mouse button to drag out a rectangle.\nUse handles to resize.\nDouble click inside rectangle-> zoom in\nDouble click outside rectangle -> zoom out',its.commonhelp),
		     '\nDrag tool using the assigned mouse button.',
		     '\nDrag tool using the assigned mouse button.',
		     '\nDrag tool using the assigned mouse button.',
		     spaste('\n Click assigned mouse button to drop cursor at that position.\nDouble click inside to execute.',its.commonhelp),
		     spaste('\nUse the assigned mouse button to drag out a rectangle.\nUse handles to resize.\nDouble click inside to execute.',its.commonhelp),
		     spaste('\nPlace polygon points by clicking the assigned mouse button.\nDoubleclick on last point to finish polygon.\nUse handles to resize.\nDouble click inside to execute.',its.commonhelp),
		     spaste('\nPlace polyline points by clicking the assigned mouse button.\nDoubleclick on last point to finish the polyline.\nUse handles to rearrange points.',its.commonhelp),
		     spaste('\nSelect a shape to draw and then click / drag on screen to place it. Select "more" to show more options', its.commonhelp)];
    its.keys := ['Button 1', 
		 'None', 
		 'Button 2', 
		 'None',
		 'None',
		 'Button 3', 
		 'None',
		 'None',
		 'None',
		 'None'];
    its.keyopts := ['None', 
		    'Button 1', 
		    'Button 2', 
		    'Button 3'];
    its.bitmapsuffixes := ['b0',
			   'b1', 
			   'b2',
			   'b3'];
    its.dlkeys := [0, 
		   Display::K_Pointer_Button1,
		   Display::K_Pointer_Button2, 
		   Display::K_Pointer_Button3];

    ############################################################
    ## EMIT TOOLKITLIST                                       ##
    ############################################################
    self.emittoolkitlist := function() {
	__VCF_('viewertoolkit.emittoolkitlist');
	self->toolkit(self.toolkitlist());
	return T;
    }

    ############################################################
    ## RETRIEVE TOOLKITLIST                                   ##
    ############################################################
    self.toolkitlist := function() {
	__VCF_('viewertoolkit.toolkitlist');
	rec := [=];
	rec.tools := its.tools;
	rec.toolshorthands := its.toolshorthands;
	rec.keyopts := its.keyopts;
	rec.keys := its.keys;
	rec.dlkeyopts := its.dlkeys;
	return rec;
    }

    its.self := ref self;

    ############################################################
    ## CHANGE THE TOOLKIT                                     ##
    ############################################################
    self.toolkitchange := function(newmap) {
	__VCF_('viewertoolkit.toolkitlist');
	wider its;
	# check validity ...

	if (!any(newmap.tool == its.tools) || 
	    !any(newmap.key == its.keyopts)) {
	    fail 'Unknown tool or key';
	}

	# restrict to one tool per key if in standard mode:
	if ((newmap.key != 'None') && any(newmap.key == its.keys)) {
	    for (i in 1:len(its.keys)) {
		if (its.keys[i] == newmap.key) {
		    its.keys[i] := 'None';
		    self->deltatoolkit([tool=its.tools[i],
					dlkey=its.
					dlkeys[its.keyopts == 'None']]);
		}
	    }
	}
	
	# apply requested change ...
	self->deltatoolkit([tool=newmap.tool, 
			    dlkey=its.dlkeys[its.keyopts == newmap.key]]);
	# emit an event for everything to update against ...
	its.keys[newmap.tool == its.tools] := newmap.key;
	self.emittoolkitlist();
	return T;
    }

    ############################################################
    ## RETURN toolshorthand given tool                        ##
    ############################################################
    its.toshorthand := function(tool) {
	return its.toolshorthands[its.tools == tool];
    }
    
    ############################################################
    ## RETURN tool given toolshorthand                        ##
    ############################################################
    its.totool := function(shorthand) {
	return its.tools[its.toolshorthands == shorthand];
    }

    ############################################################
    ## RETURN basebitmap given toolshorthand                  ##
    ############################################################
    its.tobasebitmap := function(shorthand) {
	return its.basebitmaps[its.toolshorthands == shorthand];
    }

    ################################################################
    ## VIEWER TOOLKIT MENU                                        ##
    ################################################################
    self.menu := subsequence(parent, tools="", widgetset=unset) {
	__VCF_('viewertoolkit.menu');
	wider its;

	############################################################
	## INITIALIZE AND STORE FUNCTION ARGUMENTS                ##
	############################################################

        # (tools is vector strings containing some of 'zoom', 'pan',
        # 'standardcolormap', 'rectangle', 'polygon', 'mapcolormap'.
        # Empty means all.)

	pits := [=];
	pits.parent := parent;
	pits.toolselection := to_upper(tools);
	pits.wdgts := widgetset;
	
	############################################################
	## BASIC SERVICES                                         ##
	############################################################
	its.type := 'viewertoolkitmenu';
	self.type := function() {
	    __VCF_('viewertoolkitmenu.type');
	    return its.type;
	}
	if (is_unset(pits.wdgts)) {
	    pits.wdgts := its.wdgts;
	}

	############################################################
	## WHENEVER PUSHER                                        ##
	############################################################
	pits.whenevers := [];
	pits.pushwhenever := function() {
	    wider pits;
	    pits.whenevers[len(pits.whenevers) + 1] := 
		last_whenever_executed();
	}
	pits.menuwhenevers := [];
	pits.pushmenuwhenever := function() {
	    wider pits;
	    pits.menuwhenevers[len(pits.menuwhenevers) + 1] := 
		last_whenever_executed();
	}
	const pits.deactivate := function(which) {
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
	pits.dying := F;
	self.done := function() {
	    __VCF_('viewertoolkitmenu.done');
	    wider pits, self;
	    if (pits.dying) {
		# prevent multiple done requests
		return F;
	    } pits.dying := T;
	    if (len(pits.menuwhenevers) > 0) {
		pits.deactivate(pits.menuwhenevers);
	    }
	    if (len(pits.whenevers) > 0) {
		pits.deactivate(pits.whenevers);
	    }
	    pits.tlktmenu := F;
	    val pits := F;
	    val self := F;
	    return T;
	}

        ############################################################
	## MATCH FUNCTION                                         ##
	############################################################
	const pits.match := function(tool, selectlist) {
	    const n := length(selectlist);
	    if (n == 0) {
		return T;
	    }
	    thing := to_upper(tool);
	    local find;
	    if (thing=='ZOOMING') {
		find := 'ZOOM';
	    } else if (thing=='PANNING') {
		find := 'PAN';
	    } else if (thing=='COLORMAP FIDDLING - SHIFT/SLOPE') {
		find := 'STANDARDCOLORMAP';
	    } else if (thing=='COLORMAP FIDDLING - BRIGHTNESS/CONTRAST') {
		find := 'MAPCOLORMAP';
	    } else if (thing=='POSITIONING') {
		find := 'POSITIONING';
	    } else if (thing=='RECTANGLE DRAWING') { 
		find := 'RECTANGLE';
	    } else if (thing=='POLYGON DRAWING') { 
		find := 'POLYGON';
	    } else if (thing=='MULTIPANEL CROSSHAIR') { 
		find := 'MULTICROSSHAIR';
	    } else if (thing=='ANNOTATIONS') {
		find := 'ANNOTATIONS';
	    }
	    for (i in 1:n) {
		if (selectlist[i] == find) {
		    return T;
		}
	    }
	    return F;
	}

	############################################################
	## BUILDTOOLKITMENU FUNCTION                              ##
	############################################################
	pits.tlktmenu := [=];
	pits.buildtoolkitmenu := function(setup) {
	    wider pits;
	    pits.tools := setup.tools;
	    pits.keyopts := setup.keyopts;
	    pits.keys := setup.keys;
	    pits.wdgts.tk_hold();
	    pits.tlktmenu.menu := pits.wdgts.button(pits.parent, 'Controls',
						    type='menu', 
						    relief='flat');
	    pits.tlktmenu.tools := [=];
	    i_idx := 1;
	    for (i in (pits.tools)) {
		if (pits.match(i, pits.toolselection)) {
		    pits.tlktmenu.tools[i] := [=];
		    pits.tlktmenu.tools[i].parent := 
			pits.wdgts.button(pits.tlktmenu.menu, i, type='menu');
		    for (j in (pits.keyopts)) {
			pits.tlktmenu.tools[i][j] := 
			    pits.wdgts.button(pits.tlktmenu.tools[i].parent, 
					      j, type='radio', 
					      value=[tool=i, key=j]);
			whenever pits.tlktmenu.tools[i][j]->press do {
			    its.viewer.toolkit().toolkitchange($value);
			} pits.pushmenuwhenever();
			if (j == pits.keys[i_idx]) {
			    t := pits.tlktmenu.tools[i][j]->state(T);
			}
		    }
		} else {
		    its.viewer.toolkit().toolkitchange([tool=i, key='none']);
		}
		i_idx := i_idx + 1;
	    }
	    pits.wdgts.tk_release();
	}
	
	############################################################
	## UPDATETOOLKITMENU FUNCTION                             ##
	############################################################
	pits.updatetoolkitmenu := function(setup) {
	    pits.wdgts.tk_hold();
	    i_idx := 1;
	    for (i in setup.tools) {
		if (pits.match(i, pits.toolselection)) {
		    for (j in setup.keyopts) {
			if (j == setup.keys[i_idx]) {
			    t := pits.tlktmenu.tools[i][j]->state(T);
			} else {
			    t := pits.tlktmenu.tools[i][j]->state(F);
			}
		    }
		} else {
		    its.viewer.toolkit().toolkitchange([tool=i, key='none']);
		}
		i_idx := i_idx + 1;
	    }
	    pits.wdgts.tk_release();
	}
	
	pits.buildtoolkitmenu(its.self.toolkitlist());
	whenever its.self->toolkit do {
	    pits.updatetoolkitmenu($value);
	} pits.pushwhenever();	
    }

    ################################################################
    ## VIEWER TOOLKIT CONTROLBOX                                  ##
    ################################################################
    self.controlbox := subsequence(parent, tools="", widgetset=unset) {
	__VCF_('viewertoolkit.controlbox');
	wider its;

	############################################################
	## INITIALIZE AND STORE FUNCTION ARGUMENTS                ##
	############################################################

        # (tools is vector strings containing some of 'zoom', 'pan',
        # 'standardcolormap', 'rectangle', 'polygon', 'mapcolormap'.
        # Empty means all.)

	pits := [=];
	pits.parent := parent;
	pits.toolselection := to_upper(tools);
	pits.wdgts := widgetset;
	
	############################################################
	## BASIC SERVICES                                         ##
	############################################################
	pits.type := 'viewertoolkitcontrolbox';
	self.type := function() {
	    __VCF_('viewertoolkitcontrolbox.type');
	    return pits.type;
	}
	if (is_unset(pits.wdgts)) {
	    pits.wdgts := its.wdgts;
	}

	############################################################
	## WHENEVER PUSHER                                        ##
	############################################################
	pits.whenevers := [];
	pits.pushwhenever := function() {
	    wider pits;
	    pits.whenevers[len(pits.whenevers) + 1] := 
		last_whenever_executed();
	}
	
	const pits.deactivate := function(which) {
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
	pits.dying := F;
	self.done := function() {
	    __VCF_('viewertoolkitcontrolbox.done');
	    wider pits, self;
	    if (pits.dying) {
		# prevent multiple done requests
		return F;
	    } pits.dying := T;
	    if (len(pits.whenevers) > 0) {
		pits.deactivate(pits.whenevers);
	    }
	    if (is_record(pits.controlbox)) {
		pits.wdgts.popupremove(pits.controlbox);
	    }
		
	    val pits := F;
	    val self := F;
	    return T;
	}

	############################################################
	## BUILDCONTROLBOX FUNCTION                               ##
	############################################################
	pits.buildcontrolbox := function(setup) {
	    wider pits;
	    pits.tools := setup.tools;
	    pits.keyopts := setup.keyopts;
	    pits.keys := setup.keys;
	    pits.wdgts.tk_hold();

	    pits.controlbox.tools := [=];
	    i_idx := 1;
	    for (i in (pits.tools)) {
		k := its.toshorthand(i);
		if (is_string(k)) {
    	        if (((len(pits.toolselection) > 0) &&
		     any(pits.toolselection == to_upper(k))) ||
		    (len(pits.toolselection) == 0)) {
		    basebitmap := its.tobasebitmap(k);
		    bitmapsuffix := its.bitmapsuffixes[its.keyopts==
						       pits.keys[i_idx]];
		    pits.controlbox.tools[i] := 
			pits.wdgts.button(pits.parent, i, 
					  bitmap=spaste(basebitmap,
							bitmapsuffix, '.xbm'),
					  value=i);
		    
		    pits.wdgts.popuphelp(pits.controlbox.tools[i], 
			     txt=spaste('Click on this button with a mouse ',
					'button to assign that button to \'',
					i,'\'',its.helptext[i_idx]), hlp=i);
		    
		    pits.bind[i] := [=];
		    for (ii in 1:3) {
			pits.bind[i][ii] := pits.controlbox.tools[i]->
			    bind(spaste('<ButtonRelease-', as_string(ii), '>'),
				 spaste('releaseX', as_string(ii)));
		    }
		    whenever pits.controlbox.tools[i]->
			["releaseX1 releaseX2 releaseX3"] do {
			k := $name;
			v := $value.id;
			which := as_integer(split(k, 'X')[2]);
			for (xi in field_names(pits.bind)) {
			    for (xj in 1:len(pits.bind[xi])) {
				if (pits.bind[xi][xj] == v) {
				    its.viewer.toolkit().
					toolkitchange([tool=xi, key=
						       pits.keyopts[which+1]]);
				}
			    }
			}
		    }
		}
		} else {
		    its.viewer.toolkit().toolkitchange([tool=i, key='none']);
		}
		i_idx := i_idx + 1;
	    }

	    pits.wdgts.tk_release();
	}
	
	############################################################
	## UPDATECONTROLBOX FUNCTION                              ##
	############################################################
	pits.updatecontrolbox := function(setup) {
	    pits.wdgts.tk_hold();
	    i_idx := 1;
	    for (i in setup.tools) {
		k := its.toshorthand(i);
		if (is_string(k)) {
		    basebitmap := its.tobasebitmap(k);
		    bitmapsuffix := its.bitmapsuffixes[its.keyopts==
						       setup.keys[i_idx]];
		    if (is_agent(pits.controlbox.tools[i])) {
			pits.controlbox.tools[i]->bitmap(spaste(basebitmap,
								bitmapsuffix,
								'.xbm'));
		    }
		} else {
		    its.viewer.toolkit().toolkitchange([tool=i, key='none']);
		}
		i_idx := i_idx + 1;
	    }
	    pits.wdgts.tk_release();
	}
	pits.buildcontrolbox(its.self.toolkitlist());

	whenever its.self->toolkit do {
	    pits.updatecontrolbox($value);
	} 
	t := pits.pushwhenever();	
    }
}

## ************************************************************ ##
##                                                              ##
## VIEWERCANVASPRINTMANAGER SUBSEQUENCE                         ##
##                                                              ##
## ************************************************************ ##
viewercanvasprintmanager := subsequence(displaypanel) {
    __VCF_('viewercanvasprintmanager');

    ############################################################
    ## SANITY CHECK                                           ##
    ############################################################
    if (!is_record(displaypanel) || !has_field(displaypanel, 'type') ||
	(displaypanel.type() != 'viewerdisplaypanel')) {
	return throw(spaste('An invalid viewerdisplaypanel was given to a ',
			    'viewercanvasprintmanager'));
    }
    if (is_agent(displaypanel.canvasprintmanager())) {
	return throw(spaste('The parent viewerdisplaypanel given to the ',
			    'viewercanvasprintmanager constructor alread ',
			    'has a viewercanvasprintmanager'));
    }

    ############################################################
    ## INITIALISE AND STORE CONSTRUCTOR ARGUMENTS             ##
    ############################################################
    its := [=];
    its.displaypanel := displaypanel;
    
    ############################################################
    ## BASIC SERVICES                                         ##
    ############################################################
    its.type := 'viewercanvasprintmanager';
    self.type := function() {
	__VCF_('viewercanvasprintmanager.type');
	return its.type;
    }

    its.viewer := its.displaypanel.viewer();
    self.viewer := function() {
	__VCF_('viewercanvasprintmanager.viewer');
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
	__VCF_('viewercanvasprintmanager.done');
	wider its, self;
	if (its.dying) {
	    # prevent multiple done requests
	    return F;
	}
	if (!its.displaypanel.dying()) {
	    # prevent unsafe done
	    return throw(spaste('Cannot destroy a viewercanvasprintmanager ',
				'unless requested to do so by the owning ',
				'viewerdisplaypanel'));
	}
	its.dying := T;
	if (viewer::tracedone) {
	    print 'viewercanvasprintmanager::done()';
	}
	if (len(its.whenevers) > 0) {
	    its.deactivate(its.whenevers);
	}

	## canvasprintmanagerguis
	if (len(its.canvasprintmanagerguis) > 0) {
	    for (i in 1:len(its.canvasprintmanagerguis)) {
		if (is_agent(its.canvasprintmanagerguis[i])) {
		    its.canvasprintmanagerguis[i].done();
		}
	    }
	}
	val its := F;
	val self := F;
	return T;
    }

    ############################################################
    ## GUI                                                    ##
    ############################################################
    its.canvasprintmanagerguis := [=];
    self.gui := function(parent=F, show=T, hasdismiss=F, 
			 hasdone=F, widgetset=unset) {
	__VCF_('viewercanvasprintmanager.gui');
	wider its;
	temp := viewercanvasprintmanagergui(parent, self, show, hasdismiss,
					    hasdone, widgetset);
	if (is_agent(temp)) {
	    its.canvasprintmanagerguis[len(its.canvasprintmanagerguis) + 1] :=
		temp;
	}
	return temp;
    }

    ############################################################
    ## WRITE X PIXMAP                                         ##
    ############################################################
    self.writexpm := function(filename=unset) {
	__VCF_('viewercanvasprintmanager.writexpm');
	wider its;
	if (is_unset(filename) || !is_string(filename)) {
	    filename := its.viewer.generatefilename(ext='xpm');
	}
	note(spaste('Writing \'', filename, '\' ...'), 
	     origin=its.viewer.title(), priority='NORMAL');
	its.viewer.hold();
	its.displaypanel.writexpm(filename);
	its.viewer.release();
	note(spaste('File \'', filename, '\' successfully written'),
	     origin=its.viewer.title(), priority='NORMAL');
	return filename;
    }

    ############################################################
    ## WRITE POSTSCRIPT                                       ##
    ############################################################
    self.writeps := function(filename=unset, media='A4', landscape=F,
			     dpi=100, zoom=1.0, eps=F) {
	__VCF_('viewercanvasprintmanager.writeps');
	wider its;
	if (is_unset(filename) || !is_string(filename)) {
	    if (eps) {
		filename := its.viewer.generatefilename(ext='eps');
	    } else {
		filename := its.viewer.generatefilename(ext='ps');
	    }
	}
	note(spaste('Writing \'', filename, '\' ...'), 
	     origin=its.viewer.title(), priority='NORMAL');
	its.viewer.hold();
	its.viewer.disable();
	local status := its.displaypanel.status();
	local pcw := status.pixelcanvas.width;
	local pch := status.pixelcanvas.height;
	local mcl;
	if (has_field(status.pixelcanvas, 'colorcubesize')) {
	    mcl := status.pixelcanvas.colorcubesize;
	} else {
	    mcl := status.pixelcanvas.colortablesize;
	}
	local mtp := status.pixelcanvas.maptype;
	p := its.viewer.widgetset().
	  pspixelcanvas(filename, media, landscape, pch/pcw,
			dpi, zoom, eps, mcl, mtp);
	if (is_fail(p)) { fail;	}

	local pdstatus := status.paneldisplay;
	w := its.viewer.widgetset().
	    paneldisplay(p, pdstatus.nxpanels,
			 pdstatus.nypanels,
			 pdstatus.xorigin,
			 pdstatus.yorigin,
			 pdstatus.xsize, pdstatus.ysize,
			 pdstatus.xspacing, pdstatus.yspacing,
			 foreground='black', background='white');
	if (is_fail(w)) { fail;	}
	opts := its.displaypanel.getoptions();
	t := w->setoptions(opts);
	wdgori := opts.wedgeorientation.value;
	wdgcvi := [=];
	if (status.nwedges > 0) {
	    wedgeextent := 0.18;
	    wedgespace := 0.0;
	    for (i in 1:status.nwedges) {
		tmpval :=  1.0  - 
		    i * (wedgeextent + wedgespace) + wedgespace;
		rec := [=];
		if (wdgori == 'vertical') {
		    xorigin := tmpval;
		    yorigin := pdstatus.yorigin;
		    xsize := wedgeextent;
		    ysize := pdstatus.ysize;			     
		    rec.leftmarginspacepg := 1;
		    rec.bottommarginspacepg := 
			opts.bottommarginspacepg.value;
		    rec.topmarginspacepg := 
			opts.topmarginspacepg.value;
		    rec.rightmarginspacepg := 10;

		} else {
		    xorigin :=pdstatus.xorigin ;
		    yorigin := tmpval;
		    ysize := wedgeextent;
		    xsize := pdstatus.xsize;
		    rec.bottommarginspacepg := 1;
		    rec.leftmarginspacepg := 
			opts.leftmarginspacepg.value;
		    rec.rightmarginspacepg := 
			opts.rightmarginspacepg.value;
		    rec.topmarginspacepg := 6;		    
		}
		wdgcvi[i] := its.viewer.widgetset().
		    paneldisplay(p, 1, 1, xorigin, yorigin, xsize, ysize);
		wdgcvi[i]->hold();
		t := wdgcvi[i]->setoptions(rec);
		wdgcvi[i]->release();
	    }
	}
	t := w->hold();
	# set the animation frame
	dpani := its.displaypanel.animator();
	vani := its.viewer.widgetset().mwcanimator();	
	vani->add(w);

	displaydatas := its.displaypanel.getdisplaydatas();
	registrationflags := its.displaypanel.registrationflags();
	

	# preserve order in which the dds are registered, in the following.
	
	ddnames := "";	# names of registered dds.
	wddnames := "";	# names of registered dds with colorwedges on.
	
	for (ddnm in field_names(registrationflags)) {
	  if (registrationflags[ddnm]) {
	    ddnames[len(ddnames)+1] := ddnm;
	    opt:= displaydatas[ddnm].getoptions();
	    if(is_record(opt.wedge) && opt.wedge.value) {
	      wddnames[len(wddnames)+1] := ddnm;
	    }
	  }
	}

	for (str in ddnames) {
	    t := w->add(displaydatas[str].ddproxy());
	    if (displaydatas[str].hasbeam()) {
		t := w->add(displaydatas[str].ddd().dddproxy());
	    }
	}


	addd := its.displaypanel.annotationdd();
	if (is_agent(addd))
	    t := w->add(addd.dddproxy());


	# Set the same zoom as is on displaypanel worldcanvas[es].
	# (Important to set zoom and animation index _after_ dds have
	# been added and have initialized panel state; otherwise the
	# dds might re-initialize these settings).
	
	wcst := status.paneldisplay;
	t := w->setzoom(wcst.linearblc[1], wcst.linearblc[2],
			wcst.lineartrc[1], wcst.lineartrc[2]);

	# duplicate animator settings

	zindex := [=];
	zindex.name := "zIndex";
	zindex.value := dpani.currentzframe()-1;
	zindex.increment := 1;

	if(dpani.mode()=='blink') {
	  bindex := [=];
	  bindex.name := "bIndex";
	  bindex.value := dpani.currentbframe()-1;
	  bindex.increment := 1;

	  vani->setlinearrestriction(bindex);

	  zindex.increment := 0;
	}

	vani->setlinearrestriction(zindex);


	
	# release will refresh, i.e., create postscript for the main panel.
	
	t := w->release();


	
	# colormap wedge panels are separately populated and released.
	
	nw := min(status.nwedges, len(wddnames))  # (should be equal).
	if (nw > 0) {
	  for (i in 1:nw) {
	    wdgcvi[i]->hold();
	    
	    t := wdgcvi[i]->add(displaydatas[wddnames[i]].wedgedd());
	    
	    wdgcvi[i]->release();	# (writes wedge postscript).
	  }
	}     


	# destroy our objets d'art:
	vani->remove(w);
	vani := 0;
	if (status.nwedges > 0) {
	    for (i in 1:status.nwedges) {
		wdgcvi[i] := 0; 
	    }
	}

	# Add annotations to the paneldisplay
	if (has_field(its.displaypanel, 'annotator') &&
	    is_agent(its.displaypanel.annotator())) {
	    tmp := its.displaypanel.annotator().print(w);
	    if (is_fail(tmp)) {
		print tmp;
	    }
	} else {
	    note(spaste('Couldn\'t add annotations to print out; annotations',
			' unavailable'), origin=its.viewer.title(),
		 priority = 'WARN');
	}
	#
	
	w := 0;
	p := 0;
	its.viewer.enable();
	its.viewer.release();
	note(spaste('File \'', filename, '\' successfully written'),
	     origin=its.viewer.title(), priority='NORMAL');
	return filename;
    }
}

## ************************************************************ ##
##                                                              ##

## VIEWERCANVASPRINTMANAGERGUI SUBSEQUENCE                      ##
##                                                              ##
## ************************************************************ ##
viewercanvasprintmanagergui := subsequence(parent=F, canvasprintmanager,
					   show=T, hasdismiss=F, hasdone=F,
					   widgetset=unset) {
    __VCF_('viewercanvasprintmanagergui');

    ############################################################
    ## SANITY CHECK                                           ##
    ############################################################
    if (!is_record(canvasprintmanager) || 
	!has_field(canvasprintmanager, 'type') || 
	(canvasprintmanager.type() != 'viewercanvasprintmanager')) {
	return throw(spaste('An invalid canvasprintmanager was given ',
			    'to a canvasprintmanagergui'));
    }

    ############################################################
    ## INITIALISE AND STORE CONSTRUCTOR ARGUMENTS             ##
    ############################################################
    its := [=];
    its.parent := parent;
    its.canvasprintmanager := canvasprintmanager;
    its.show := show;
    its.hasdismiss := hasdismiss;
    its.hasdone := hasdone;
    its.wdgts := widgetset;

    ############################################################
    ## BASIC SERVICES                                         ##
    ############################################################
    its.type := 'viewercanvasprintmanagergui';
    self.type := function() { 
	__VCF_('viewercanvasprintmanagergui.type');
	return its.type;
    }

    self.canvasprintmanager := function() {
	__VCF_('viewercanvasprintmanagergui.canvasprintmanager');
	return its.canvasprintmanager;
    }

    its.viewer := its.canvasprintmanager.viewer();
    self.viewer := function() {
	__VCF_('viewercanvasprintmanagergui.viewer');
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
	__VCF_('viewercanvasprintmanagergui.map');
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
	__VCF_('viewercanvasprintmanagergui.unmap');
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
	__VCF_('viewercanvasprintmanagergui.ismapped');
	return its.ismapped;
    }

    ############################################################
    ## DONE FUNCTION                                          ##
    ############################################################
    its.dying := F;
    self.done := function() {
	__VCF_('viewercanvasprintmanagergui.done');
	wider self, its;
	if (its.dying) {
	    # prevent multiple done requests
	    return F;
	} its.dying := T;
	if (viewer::tracedone) {
	    print 'viewercanvasprintmanagergui::done';
	}
	if (len(its.whenevers) > 0) {
	    its.deactivate(its.whenevers);
	}
	if (is_record(its.gui)) { 
	    its.wdgts.popupremove(its.gui);
	}
	self.unmap(T);
	val its := F;
	val self := F;
	return T;
    }
    
    ############################################################
    ## DISMISS FUNCTION                                       ##
    ############################################################
    self.dismiss := function() {
	__VCF_('viewercanvasprintmanagergui.dismiss');
	return self.unmap();
    }

    ############################################################
    ## GUI FUNCTION                                           ##
    ############################################################
    self.gui := function() {
	__VCF_('viewercanvasprintmanagergui.gui');
	return self.map();
    }
    
    ############################################################
    ## DISABLE/ENABLE THE GUI                                 ##
    ############################################################
    self.disable := function() {
	__VCF_('viewercanvasprintmanagergui.disable');
	if (its.madeparent) {
	    t := its.parent->disable();
	    #t := its.parent->cursor("watch");
	} 
	return T;
    }
    self.enable := function() {
	__VCF_('viewercanvasprintmanagergui.enable');
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
					 ' - Canvas Print Manager (AIPS++)'));
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

    ############################################################
    ## BUILD AUTOGUI PARAMETER RECORD                         ##
    ############################################################
    its.params := [=];

    printfilename := [=];
    printfilename.dlformat := 'printfilename';
    printfilename.listname := 'Output file';
    printfilename.ptype := 'string';
    printfilename.default := unset;
    printfilename.value := unset;
    printfilename.allowunset := T;
    printfilename.autoapply := F;
    its.params.printfilename := printfilename;

    printmedia := [=];
    printmedia.dlformat := 'printmedia';
    printmedia.listname := '[PS] Output media';
    printmedia.ptype := 'choice';
    printmedia.popt := ['A4', 'LETTER'];
    printmedia.default := 'A4';
    printmedia.value := 'A4';
    printmedia.allowunset := F;
    printmedia.autoapply := F;
    its.params.printmedia := printmedia;

    printorientation := [=];
    printorientation.dlformat := 'printorientation';
    printorientation.listname := '[PS] Orientation';
    printorientation.ptype := 'choice';
    printorientation.popt := ['portrait', 'landscape'];
    printorientation.default := 'portrait';
    printorientation.value := 'portrait';
    printorientation.allowunset := F;
    printorientation.autoapply := F;
    its.params.printorientation := printorientation;

    printresolution := [=];
    printresolution.dlformat := 'printresolution';
    printresolution.listname := '[PS] Resolution (dpi)';
    printresolution.ptype := 'intrange';
    printresolution.pmin := 60;
    printresolution.pmax := 300;
    printresolution.default := 72;
    printresolution.value := 72;
    printresolution.allowunset := F;
    printresolution.autoapply := F;
    its.params.printresolution := printresolution;

    printmagnification := [=];
    printmagnification.dlformat := 'printmagnification';
    printmagnification.listname := '[PS] Magnification';
    printmagnification.ptype := 'floatrange';
    printmagnification.pmin := 0.1;
    printmagnification.pmax := 1.0;
    printmagnification.presolution := 0.02;
    printmagnification.default := 1.0;
    printmagnification.value := 1.0;
    printmagnification.allowunset := F;
    printmagnification.autoapply := F;
    its.params.printmagnification := printmagnification;

    printepsformat := [=];
    printepsformat.dlformat := 'printepsformat';
    printepsformat.listname := '[PS] Write EPS format?';
    printepsformat.ptype := 'boolean';
    printepsformat.default := F;
    printepsformat.value := F;
    printepsformat.allowunset := F;
    printepsformat.autoapply := F;
    its.params.printepsformat := printepsformat;

    its.autogui := autogui(params=its.params, toplevel=its.wholeframe,
			   autoapply=F, widgetset=its.wdgts);
    its.gui.buttonbar := its.wdgts.frame(its.wholeframe, side='left');
    its.gui.leftbbar := its.wdgts.frame(its.gui.buttonbar, side='left');

    its.gui.bwritexpm := its.wdgts.button(its.gui.leftbbar, 'Save XPM');
    its.wdgts.popuphelp(its.gui.bwritexpm, 
	      txt=spaste('Press this button to save an X11 Pixmap image ',
			 'to disk'),
	      hlp='Save X11 Pixmap');
    whenever its.gui.bwritexpm->press do {
	self.disable();
	its.readgui();
	its.writexpm();
	self.enable();
    } its.pushwhenever();

    its.gui.bwriteps := its.wdgts.button(its.gui.leftbbar, 'Save PS');
    its.wdgts.popuphelp(its.gui.bwriteps,
	      txt=spaste('Press this button to save a PostScript image ',
			 'to disk'),
	      hlp='Save PostScript');
    whenever its.gui.bwriteps->press do {
	self.disable();
	its.readgui();
	its.writeps();
	self.enable();
    } its.pushwhenever();

    its.gui.bprintps := its.wdgts.button(its.gui.leftbbar, 'Print');
    its.wdgts.popuphelp(its.gui.bprintps,
	      txt=spaste('Press this button to open a window which ',
			 'will allow you to send a PostScript image ',
			 'to a printer'),
	      hlp='Print to PostScript printer');
    whenever its.gui.bprintps->press do {
	self.disable();
    	its.readgui();
    	its.printps();
	self.enable();
    } its.pushwhenever();

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
    
    its.readgui := function() {
	wider its;
	nprms := its.autogui.get();
	for (i in field_names(nprms)) {
	    its.params[i].value := nprms[i];
	}
    }

    its.writexpm := function() {
	filename := its.params.printfilename.value;
	return its.canvasprintmanager.writexpm(filename);
    }

    its.writeps := function() {
	filename := its.params.printfilename.value;
	media := its.params.printmedia.value;
	if (its.params.printorientation.value == 'landscape') {
	    landscape := T;
	} else {
	    landscape := F;
	}
	resolution := its.params.printresolution.value;
	magnification := its.params.printmagnification.value;
	eps := its.params.printepsformat.value;
	return its.canvasprintmanager.writeps(filename, media, landscape,
					      resolution, magnification, eps);
    }

    its.printer := printer();
    its.printps := function() {
	fname := its.writeps();
	its.printer.gui(files=fname);
    }

    # map the gui to the screen if show=T in constructor
    if (its.show) {
	t := self.map();
    }
}

## ************************************************************ ##
##                                                              ##
## VIEWERCANVASMANAGER SUBSEQUENCE                              ##
##                                                              ##
## ************************************************************ ##
viewercanvasmanager := subsequence(displaypanel) {
    __VCF_('viewercanvasmanager');

    ############################################################
    ## SANITY CHECK                                           ##
    ############################################################
    if (!is_record(displaypanel) || !has_field(displaypanel, 'type') ||
	(displaypanel.type() != 'viewerdisplaypanel')) {
	return throw(spaste('An invalid viewerdisplaypanel was given to a ',
			    'viewercanvasmanager'));
    }
    if (is_agent(displaypanel.canvasmanager())) {
	return throw(spaste('The parent viewerdisplaypanel given to the ',
			    'viewercanvasmanager constructor already ',
			    'has a viewercanvasmanager'));
    }

    ############################################################
    ## INITIALISE AND STORE CONSTRUCTOR ARGUMENTS             ##
    ############################################################
    its := [=];
    its.displaypanel := displaypanel;

    ############################################################
    ## BASIC SERVICES                                         ##
    ############################################################
    its.type := 'viewercanvasmanager';
    self.type := function() {
	__VCF_('viewercanvasmanager.type');
	return its.type;
    }

    its.viewer := its.displaypanel.viewer();
    self.viewer := function() {
	__VCF_('viewercanvasmanager.viewer');
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
	__VCF_('viewercanvasmanager.done');
	wider self, its;
	if (its.dying) {
	    # prevent multiple done requests
	    return F;
	}
	if (!its.displaypanel.dying()) {
	    # prevent unsafe done
	    return throw(spaste('Cannot destroy viewercanvasmanager ',
				'unless requested to do so by the owning ',
				'viewerdisplaypanel'));
	}
	its.dying := T;
	if (viewer::tracedone) {
	    print 'viewercanvasmanager::done()';
	}
	if (len(its.whenevers) > 0) {
	    its.deactivate(its.whenevers);
	}

	## viewercanvasmanagerguis
	if (len(its.canvasmanagerguis) > 0) {
	    for (i in 1:len(its.canvasmanagerguis)) {
		if (is_agent(its.canvasmanagerguis[i])) {
		    its.canvasmanagerguis[i].done();
		}
	    }
	}

	val its := F;
	val self := F;
	return T;
    }

    ############################################################
    ## GUI                                                    ##
    ############################################################
    its.canvasmanagerguis := [=];
    self.gui := function(parent=F, show=T, hasdismiss=F,
			 hasdone=F, widgetset=unset) {
	__VCF_('viewercanvasmanager.gui');
	wider its;
	temp := viewercanvasmanagergui(parent, self, show, hasdismiss,
				       hasdone, widgetset);
	if (is_agent(temp)) {
	    its.canvasmanagerguis[len(its.canvasmanagerguis) + 1] := temp;
	}
	return temp;
    }

    ############################################################
    ## PARAMETERS FOR THE AUTOGUI                             ##
    ############################################################
    its.params := its.displaypanel.getoptions();
    self.getoptions := function() {
	__VCF_('viewercanvasmanager.getoptions');
	return its.params;
    }
    self.setoptions := function(newopts, emit=T) {
	__VCF_('viewercanvasmanager.setoptions');
	wider its;
	its.viewer.hold();
	rec := [=];
	for (i in field_names(newopts)) {
	    if (has_field(its.params, i)) {
		if (is_record(newopts[i]) && 
		    has_field(newopts[i], 'value')) {
		    its.params[i].value := newopts[i].value;
		} else {
		    its.params[i].value := newopts[i];
		}
		rec[i] := its.params[i];
		# probably need to prevent other pixelcanvases
		# getting colortablesize option...
	    }
	}
	if (len(rec) > 0) {
	    newopts := its.displaypanel.setoptions(rec);
	    if (is_record(newopts) && (len(newopts) > 0)) {
		for (i in field_names(newopts)) {
		    if (has_field(its.params, i)) {
			its.params[i] := newopts[i];
		    } else {
			note('Non-existent option in contextoptions event',
			     origin=spaste(its.viewer.title(), ' (viewer.g)'),
			     priority='WARN');
		    }
		}
		self->contextoptions(newopts);
	    }
	}
	if (emit) {
	    self->options(rec);
	}
	t := its.viewer.release();
	return T;
    }

    whenever its.displaypanel->localoptions do {
	newopts := $value;
	self->localoptions(newopts);
	for (i in field_names(newopts)) {
	    if (has_field(its.params, i)) {
		its.params[i] := newopts[i];
	    }
	}
    } its.pushwhenever();
    
    ############################################################
    ## SAVE/RESTORE OPTIONS (usually called from gui          ##
    ############################################################
    self.saveoptions := function(setname) {
	__VCF_('viewercanvasmanager.saveoptions');
	t := eval('include \'inputsmanager.g\'');
	t := self.getoptions();
	rec := [=];
	for (i in field_names(t)) {
	    rec[i] := t[i].value;
	}
	return inputs.savevalues('viewer', setname, rec);
    }
    self.restoreoptions := function(setname) {
	__VCF_('viewercanvasmanager.restoreoptions');
	t := eval('include \'inputsmanager.g\'');
	t := inputs.getvalues('viewer', setname);
	if (len(field_names(t)) > 0) {
	    return self.setoptions(t);
	} else {
	    note('No inputs found for given name');
	    return F;
	}
    }	
}

## ************************************************************ ##
##                                                              ##
## VIEWERCANVASMANAGERGUI SUBSEQUENCE                           ##
##                                                              ##
## ************************************************************ ##
viewercanvasmanagergui := subsequence(parent=F, canvasmanager, show=T,
				      hasdismiss=F, hasdone=F,
				      widgetset=unset) {
    __VCF_('viewercanvasmanagergui');

    ############################################################
    ## SANITY CHECK                                           ##
    ############################################################
    if (!is_record(canvasmanager) || !has_field(canvasmanager, 'type') ||
	(canvasmanager.type() != 'viewercanvasmanager')) {
	return throw(spaste('An invalid viewercanvasmanager was given to a ',
			    'viewercanvasmanagergui'));
    }

    ############################################################
    ## INITIALISE AND STORE CONSTRUCTOR ARGUMENTS             ##
    ############################################################
    its := [=];
    its.parent := parent;
    its.canvasmanager := canvasmanager;
    its.show := show;
    its.hasdismiss := hasdismiss;
    its.hasdone := hasdone;
    its.wdgts := widgetset;
    
    ############################################################
    ## BASIC SERVICES                                         ##
    ############################################################
    its.type := 'viewercanvasmanagergui';
    self.type := function() {
	__VCF_('viewercanvasmanagergui.type');
	return its.type;
    }

    self.canvasmanager := function() {
	__VCF_('viewercanvasmanagergui.canvasmanager');
	return its.canvasmanager;
    }

    its.viewer := its.canvasmanager.viewer();
    self.viewer := function() {
	__VCF_('viewercanvasmanagergui.viewer');
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
	__VCF_('viewercanvasmanagergui.map');
	wider its;
	if (!its.ismapped || force) {
	    if (its.madeparent) {
		t := its.parent->map();
	    } else {
		t := its.wholeframe->map();
	    }
	    its.ismapped := T;
	    return T;
	} else {
	    return F;
	}
    }
    self.unmap := function(force=F) {
	__VCF_('viewercanvasmanagergui.unmap');
	wider its;
	if (its.ismapped || force) {
	    if (its.madeparent) {
		t := its.parent->unmap();
	    } else {
		t := its.wholeframe->unmap();
	    }
	    its.ismapped := F;
	    return T;
	} else {
	    return F;
	}
    }
    self.ismapped := function() {
	__VCF_('viewercanvasmanagergui.ismapped');
	return its.ismapped;
    }
    
    ############################################################
    ## DONE FUNCTION                                          ##
    ############################################################
    its.dying := F;
    self.done := function() {
	__VCF_('viewercanvasmanagergui.done');
	wider its, self;
	if (its.dying) {
	    # prevent multiple done requests
	    return F;
	} its.dying := T;
	if (viewer::tracedone) {
	    print 'viewercanvasmanagergui::done()';
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
	__VCF_('viewercanvasmanagergui.dismiss');
	return self.unmap();
    }

    ############################################################
    ## GUI FUNCTION                                           ##
    ############################################################
    self.gui := function() {
	__VCF_('viewercanvasmanagergui.gui');
	return self.map();
    }
    
    ############################################################
    ## DISABLE/ENABLE THE GUI                                 ##
    ############################################################
    self.disable := function() {
	__VCF_('viewercanvasmanagergui.disable');
	if (its.madeparent) {
	    t := its.parent->disable();
	    #t := its.parent->cursor("watch");
	    return T;
	} else {
	    return F;
	}
    }
    self.enable := function() {
	__VCF_('viewercanvasmanagergui.enable');
	if (its.madeparent) {
	    t := its.parent->enable();
	    #t := its.parent->cursor(its.originalcursor);
	    return T;
	} else {
	    return F;
	}
    }

    ############################################################
    ## CONSTRUCT FRAME                                        ##
    ############################################################
    its.wdgts.tk_hold();
    its.madeparent := F;
    if (is_boolean(its.parent)) {
	its.parent := 
	    its.wdgts.frame(title=spaste(its.canvasmanager.viewer().title(), 
					 '- Canvas manager (AIPS++)'));
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
    its.autogui := autogui(params=its.canvasmanager.getoptions(),
			   toplevel=its.wholeframe, autoapply=T,
			   widgetset=its.wdgts);
    whenever its.autogui->setoptions do {
	its.canvasmanager.setoptions($value, F);
    } its.pushwhenever();
    whenever its.canvasmanager->options do {
	its.autogui.fillgui($value);
    } its.pushwhenever();
    whenever its.canvasmanager->contextoptions do {
	its.autogui.modifygui($value);
    } its.pushwhenever();
    whenever its.canvasmanager->localoptions do {
	its.autogui.fillgui($value);
    } its.pushwhenever();

    its.gui.buttonbar := its.wdgts.frame(its.wholeframe, side='left');
    its.gui.leftbbar := its.wdgts.frame(its.gui.buttonbar, side='left');
    its.gui.bapply := its.wdgts.button(its.gui.leftbbar, 'Apply', 
				       type='action');
    whenever its.gui.bapply->press do {
	nprms := its.autogui.get();
	t := its.canvasmanager.setoptions(nprms);
    } its.pushwhenever();

    its.gui.bsave := its.wdgts.button(its.gui.leftbbar, 'Save');
    whenever its.gui.bsave->press do {
	its.canvasmanager.saveoptions(its.gui.emethod.get());
    } its.pushwhenever();
    its.gui.brestore := its.wdgts.button(its.gui.leftbbar, 'Restore');
    whenever its.gui.brestore->press do {
	its.canvasmanager.restoreoptions(its.gui.emethod.get());
    } its.pushwhenever();
    its.dge := its.wdgts.guientry(width=15);
    its.gui.emethod := its.dge.string(its.gui.leftbbar, 'canvas defaults',
				      default='canvas defaults');

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

## ************************************************************ ##
##                                                              ##
## VIEWERANIMATOR SUBSEQUENCE                                   ##
##                                                              ##
## ************************************************************ ##
vieweranimator := subsequence(viewer) {
    __VCF_('vieweranimator');

    ############################################################
    ## SANITY CHECK                                           ##
    ############################################################
    if (!is_record(viewer) || !has_field(viewer, 'type') ||
	(viewer.type() != 'viewer')) {
	return throw(spaste('An invalid viewer was given to a ',
			    'vieweranimator'));
    }
			    
    ############################################################
    ## INITIALISE AND STORE CONSTRUCTOR ARGUMENTS             ##
    ############################################################
    its := [=];
    its.viewer := viewer;

    ############################################################
    ## BASIC SERVICES                                         ##
    ############################################################
    its.type := 'vieweranimator';
    self.type := function() {
	__VCF_('vieweranimator.type');
	return its.type;
    }
	
    self.viewer := function() {
	__VCF_('vieweranimator.viewer'); 
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
	__VCF_('vieweranimator.done');
	wider self, its;
	if (its.dying) {
	    # prevent multiple done requests
	    return F;
	} its.dying := T;
	if (viewer::tracedone) {
	    print 'vieweranimator::done()';
	}
	self.stop();
	if (len(its.whenevers) > 0) {
	    its.deactivate(its.whenevers);
	}
	## vieweranimatorguis
	if (len(its.animatorguis) > 0) {
	    for (i in 1:len(its.animatorguis)) {
		if (is_agent(its.animatorguis[i])) {
		    its.animatorguis[i].done();
		}
	    }
	}
	
	val its := F;
	val self := F;
    }

    ############################################################
    ## GUI                                                    ##
    ############################################################
    its.animatorguis := [=];
    self.gui := function(parent=F, orient='horizontal', show=T, hasdismiss=F,
			 hasdone=F, widgetset=unset) {
	__VCF_('vieweranimator.gui');
	wider its;
	temp := vieweranimatorgui(parent, self, orient, show, hasdismiss,
				  hasdone, widgetset);
	if (is_agent(temp)) {
	    its.animatorguis[len(its.animatorguis) + 1] := temp;
	}
	return temp;
    }

    ############################################################
    ## Make the animator                                      ##
    ############################################################
    its.animator := its.viewer.widgetset().mwcanimator();
    if (is_fail(its.animator)) {
	return throw(spaste('Failed to make an animator agent:\n',
			    its.animator::message));
    } else {
	whenever its.animator->logmessage do {
	    note($value.message, origin=$value.origin, 
		 priority=$value.priority);
	}
    }

    ############################################################
    ## register/unregister the animator                       ##
    ############################################################
    self.addpaneldisplay := function(paneldisplay) {
	__VCF_('vieweranimator.addworldcanvas');
	t := its.animator->add(paneldisplay);
    }
    self.removepaneldisplay := function(paneldisplay) {
	__VCF_('vieweranimator.removeworldcanvas');
	t := its.animator->remove(paneldisplay);
    }

    ############################################################
    ## basic control the animator                             ##
    ############################################################
    its.nframes := 0;	# will always = nzframes or nbframes below,
    			# according to mode.

    its.zindex := [name="zIndex", value=0, increment=1];
    t := its.animator->setlinearrestriction(its.zindex);


    # blink mode state (8/03  dk)

    its.modez := T;	# T = zIndex (normal) mode   F = bIndex (blink) mode
			# (initial mode is 'normal').
    its.nzframes := 0;
    its.nbframes := 0;
    its.bindex := [name="bIndex", value=0, increment=1];
	# index and nframes for both modes are maintained,
	# regardless of which mode is active.


    # animation mode ('normal' or 'blink')

    self.mode := function() {
      wider its;
      if(its.modez) return 'normal';
      else          return 'blink';
    }

    self.setmode := function(mode) {	# mode should be 'normal' or 'blink'.
      wider its;
      if(!is_string(mode)) return;	# (invalid input).
      newmodez := (to_lower(mode)!='blink');
      if(its.modez==newmodez) return;	# (already there).

      self.stop();
      its.viewer.hold();

      its.modez := newmodez;

      if(its.modez) {

        # Entering normal (plane-of-cube) mode--remove any bIndex restrictions
	# and set the increment on the zIndex restriction back to 1.

	its.zindex.increment := 1;
	its.animator->setlinearrestriction(its.zindex);
	its.animator->removerestriction(its.bindex.name);
	its.nframes := its.nzframes;

      } else {

	# Entering blink mode--the zIndex (plane-of-cube) restriction
	# is retained at its current value, but it will no longer
	# increase from canvas to canvas, so that the dds all display
	# the same plane.  (At present, only dds with the same CS,
	# extents and number of planes are supported in blink mode, except
	# that a single-plane image can be viewed with a spectral one).
	# bIndex restrictions (which have already been placed onto the
	# relevant displaydatas) are now placed on the panel as well,
	# increasing by 1 from canvas to canvas.  This allows blinking
	# via the tapedeck, or side-by-side comparisons (with synchronous
	# zoom) within a multipanel.

	its.zindex.increment := 0;
	its.animator->setlinearrestriction(its.zindex);
	its.animator->setlinearrestriction(its.bindex);
	its.nframes := its.nbframes;
      }

      if (self.enabled()) self->enable(its.nframes);
      else 		  self->disable();

      its.emitstate();
      its.viewer.release();
    }


    # set # of frames.  Length for both modes are maintained.  Changing
    # the one corresponding to the current mode also emits state needed
    # to update the animator (tapedeck) gui, if any.

    self.setlength := function(length) {
      wider its;
      if(its.modez) setzlength(length);
      else          setblength(length);
    }

    self.setzlength := function(length) {
      wider its;
      its.nzframes := length;
      if(its.modez) its.setlen(length);
    }

    self.setblength := function(length) {
      wider its;
      its.nbframes := length;
      if(!its.modez) its.setlen(length);
    }

    its.setlen := function(length) {
      wider its;
      if(its.nframes == length) return;		# already there.

      self.stop();
      its.nframes := length;
      if (self.enabled()) self->enable(its.nframes);
      else 		  self->disable();
      its.emitstate();
    }


    self.nframes := function() {
	__VCF_('vieweranimator.nframes');
        wider its;
	return its.nframes;
    }
    self.nzframes := function() {
	__VCF_('vieweranimator.nzframes');
        wider its;
	return its.nzframes;
    }
    self.nbframes := function() {
	__VCF_('vieweranimator.nbframes');
        wider its;
	return its.nbframes;
    }


    self.currentframe := function() {
	__VCF_('vieweranimator.currentframe');
        wider its;
	if(its.modez) return self.currentzframe();
	else          return self.currentbframe();
    }

    self.currentzframe := function() {
	__VCF_('vieweranimator.currentzframe');
	wider its;
	return its.zindex.value+1;
    }

    self.currentbframe := function() {
	__VCF_('vieweranimator.currentbframe');
	wider its;
	return its.bindex.value+1;
    }


    self.enabled := function() {
	__VCF_('vieweranimator.enabled');
	wider its;
	if (its.nframes > 1) {
	    return T;
	} else {
	    return F;
	}
    }

    its.emitstate := function() {
	wider its;
	stt := [=];
	stt.frame :=  self.currentframe();
	stt.length := its.nframes;
	stt.mode := self.mode();
	self->state(stt);
	return T;
    }

    self.reset := function() {
	__VCF_('vieweranimator.reset');
	wider its;
	self.stop();
	if (self.enabled()) {
	    self->enable(its.nframes);
	} else {
	    self->disable();
	}
	self.tostart();
	its.emitstate();
	return T;
    }
    self.first := function(async=T) {
	__VCF_('vieweranimator.tofirst');
	return self.tostart(async);
    }
    self.tostart := function(async=T) {
	 __VCF_('vieweranimator.tostart');
	 return self.goto(1, async);
    }

    self.last := function(async=T) {
	__VCF_('vieweranimator.last');
	return self.toend(async);
    }
    self.toend := function(async=T) {
	wider its;
	__VCF_('vieweranimator.toend');
	return self.goto(max(1, self.nframes()), async);
    }

    self.forwardstep := function(async=T) {
	__VCF_('vieweranimator.forwardstep');
	return self.next(async);
    }
    self.next := function(async=T, emit=T) {
	__VCF_('vieweranimator.next');
	wider its;
	frm := self.currentframe()+1;
	if(frm<1 || frm>self.nframes()) frm := 1;
	return self.goto(frm, async, emit);
    }

    self.reversestep := function(async=T) {
	__VCF_('vieweranimator.reversestep');
	return self.prev(async);
    }
    self.prev := function(async=T, emit=T) {
	wider its;
	__VCF_('vieweranimator.prev');
	frm := self.currentframe()-1;
	if(frm<1 || frm>self.nframes()) frm := max(1, self.nframes());
	return self.goto(frm, async, emit);
    }


    self.goto := function(frm, async=T, emit=T) {
	# (dk note (9/03): async=F doesn't work, actually; it just hangs,
	# because the proper replies are never received from the library...)

	wider its;
	__VCF_('vieweranimator.goto');
	if(its.modez) return self.gotoz(frm, async, emit);
	else          return self.gotob(frm, async, emit);
    }

    self.gotoz := function(frm, async=T, emit=T) {
        wider its;
        __VCF_('vieweranimator.gotoz');
        if (frm < 1 || frm > max(1, its.nzframes)) return F;

        its.zindex.value := frm-1;

        # plane-of-cube frame number can actually change on the display
        # even during blink mode (e.g. when a displaydata axis changes),
        # although the user must switch mode to control it via the GUI.

        if (async) its.animator->setlinearrestriction(its.zindex);
        else  t := its.animator->setlinearrestriction(its.zindex);

        if (its.modez && emit) its.emitstate();
        return T;
    }

    self.gotob := function(frm, async=T, emit=T) {
        wider its;
        __VCF_('vieweranimator.goto');
        if (frm < 1 || frm > max(1, its.nbframes)) return F;

        its.bindex.value := frm-1;
	    # blink state is always maintained.  However,...
        if(!its.modez) {
	    # ...actual blink restriction is set onto canvases only
	    # during blink mode.

	    if (async) its.animator->setlinearrestriction(its.bindex);
	    else  t := its.animator->setlinearrestriction(its.bindex);
	    if (emit) its.emitstate();
        }
        return T;
    }

    ############################################################
    ## movie control                                          ##
    ############################################################
    self.reverseplay := function() {
	__VCF_('vieweranimator.reverseplay');
	wider its;
	its.direction := -1;
	its.animate();
    }
    self.forwardplay := function() {
	__VCF_('vieweranimator.forwardplay');
	 wider its;
	 its.direction := 1;
	 its.animate();
    }
    self.stop := function() {
	__VCF_('vieweranimator.stop');
	 wider its;
	 its.direction := 0;
	 its.animate();
    }
    its.animating := F;
    its.timerid := 0;
    its.idlecount := 0;
    whenever its.animator->idle do {
	 if (its.idlecount > 0) {
	     its.idlecount := its.idlecount - 1;
	 }
    } its.pushwhenever();

    its.framerate := 4; # frames per second (fps)
    self.setframerate := function(framerate=4, emit=T) {
	__VCF_('vieweranimator.setframerate');
	 wider its;
	 its.framerate := framerate;
	 if (its.animating) {
	     timer.remove(its.timerid);
	     its.timerid := timer.execute(its.animatorcallback,
					  interval=1.0/its.framerate,
					  oneshot=F);
	 }
	 if (emit) {
	     self->framerate(its.framerate);
	 }
	 return T;
    }
    self.getframerate := function() {
	__VCF_('vieweranimator.getframerate');
	return its.framerate;
    }

    its.animateskip := 0;
    self.setanimateskip := function(skip=0, emit=T) {
	__VCF_('vieweranimator.setanimateskip');
	 wider its;
	 its.animateskip := skip;
	 if (its.animateskip < 0) {
	     its.animateskip := 0;
	 }
	 if (emit) {
	     self->animateskip(its.animateskip);
	 }

    }
    self.getanimateskip := function() {
	__VCF_('vieweranimator.getanimateskip');
	return its.animateskip;
    }

    its.animate := function() {
	wider its;
	t := eval('include \'misc.g\'');
	if (its.direction == 0) {
	    if (its.animating) {
		its.animating := F;
		timer.remove(its.timerid);
	    }
	} else if (!its.animating) {
	    # (only setup the timer if we are not already animating)
	    its.animating := T;
	    global _interval;
	    its.timerid := timer.execute(its.animatorcallback,
					 interval=1.0/its.framerate,
					 oneshot=F);
	}
	return;
    }

    its.animatorcallback := function(interval, name) {
	wider its;
	if (!its.animating) {
	    note('Animator callback called, but viewer is not animating', 
		 origin='viewer.g');
	    return;
	 } else if (its.idlecount != 0) {
	     if (viewer::traceskip) {
		 print "vieweranimator skipping a frame";
	     }
	     return;
	} else {
	    if (its.direction == 1) {
		its.idlecount := its.idlecount + its.animateskip + 1;
		its.viewer.hold();
		for (i in 0:its.animateskip) {
		    self.next(async=T, emit=F);
		}
#		self.next(async=T, emit=F);
		its.viewer.release();
		its.emitstate();
	    } else if (its.direction == -1) {
		its.idlecount := its.idlecount + its.animateskip + 1;
		its.viewer.hold();
		for (i in 0:its.animateskip) {
		    self.prev(async=T, emit=F);
#		self.prev(async=T, emit=F);
		}
		its.viewer.release();
		its.emitstate();
	    }
	}
	return;
    }
}

## ************************************************************ ##
##                                                              ##
## VIEWERANIMATORGUI SUBSEQUENCE                                ##
##                                                              ##
## ************************************************************ ##
vieweranimatorgui := subsequence(parent=F, animator, orient='horizontal',
				 show=T, hasdismiss=F, hasdone=F,
				 widgetset=unset) {
    __VCF_('vieweranimatorgui');

    ############################################################
    ## SANITY CHECK                                           ##
    ############################################################
    if (!is_record(animator) || !has_field(animator, 'type') ||
	(animator.type() != 'vieweranimator')) {
	return throw(spaste('An invalid vieweranimator was given to a ',
			    'vieweranimatorgui'));
    }

    ############################################################
    ## INITIALISE AND STORE CONSTRUCTOR ARGUMENTS             ##
    ############################################################
    its := [=];
    its.parent := parent;
    its.animator := animator;
    its.orient := orient;
    its.show := show;
    its.hasdismiss := hasdismiss;
    its.hasdone := hasdone;
    its.wdgts := widgetset;

    ############################################################
    ## BASIC SERVICES                                         ##
    ############################################################
    its.type := 'vieweranimatorgui';
    self.type := function() {
	__VCF_('vieweranimatorgui.type');
	return its.type;
    }

    self.animator := function() {
	__VCF_('vieweranimatorgui.animator');
	return its.animator;
    }

    its.viewer := its.animator.viewer();
    self.viewer := function() {
	__VCF_('vieweranimatorgui.viewer');
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
	__VCF_('vieweranimatorgui.map');
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
	__VCF_('vieweranimatorgui.unmap');
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
	__VCF_('vieweranimatorgui.ismapped');
	return its.ismapped;
    }

    ############################################################
    ## DONE FUNCTION                                          ##
    ############################################################
    its.dying := F;
    self.done := function() {
	__VCF_('vieweranimatorgui.done');
	wider its, self;
	if (its.dying) {
	    # prevent multiple done requests
	    return F;
	} its.dying := T;
	if (viewer::tracedone) {
	    print 'vieweranimatorgui::done()';
	}
	if (is_agent(its.gui.tapedeck)) {
	    if (has_field(its.gui.tapedeck,'done')) {
		its.gui.tapedeck.done();
	    }
	}
	if (has_field(its.gui.subpanel,'done')) {
	    its.gui.subpanel.done();
	}
	if (is_record(its.gui)) {
	    its.wdgts.popupremove(its.gui);
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
	__VCF_('vieweranimatorgui.dismiss');
	return self.unmap();
    }

    ############################################################
    ## GUI FUNCTION                                           ##
    ############################################################
    self.gui := function() {
	__VCF_('vieweranimatorgui.gui');
	return self.map();
    }
    
    ############################################################
    ## DISABLE/ENABLE THE GUI                                 ##
    ############################################################
    its.enabled := T;
    self.enable := function() {
	__VCF_('vieweranimatorgui.enable');
	wider its;
	if (!its.enabled) {
	    its.gui.tapedeck.enable();  
	    its.gui.frametext->enable();
	    its.gui.subpanelbutton->enable();
	    its.enabled := T;
	}
    }
    self.disable := function() {
	__VCF_('vieweranimatorgui.disable');
	wider its;
	if (its.enabled) {
	    its.gui.tapedeck.disable();
	    its.gui.frametext->disable();
	    its.gui.subpanelbutton->disable();
	    its.enabled := F;
	}
    }
    whenever its.animator->enable do {
	self.enable();
    } its.pushwhenever();
    whenever its.animator->disable do {
	self.disable();
    } its.pushwhenever();
    

    ############################################################
    ## CONSTRUCT FRAME                                        ##
    ############################################################
    its.wdgts.tk_hold();
    its.madeparent := F;
    if (is_boolean(its.parent)) {
	its.parent := 
	    its.wdgts.frame(title=spaste(its.animator.name(),
					 ' - Animator'));
	its.madeparent := T;
    }
    its.side := 'top';
    its.aside := 'left';
    its.expand := 'y';
    its.aexpand := 'x';
    if (its.orient == 'vertical') {
	its.side := 'left';
	its.aside := 'top';
	its.expand := 'x';
	its.aexpand := 'y';
    }
    its.wholeframe := its.wdgts.frame(its.parent, side=its.side,
   				      borderwidth=0, padx=0, pady=0);
    if (is_fail(its.wholeframe)) {
	its.wdgts.tk_release();
	return throw(spaste('Failed to construct a frame: probable ',
			    'incompatibility between widgetservers'));
    }
    self.unmap(T);
    its.wdgts.tk_release();
    
    ## build the gui
    its.gui.buttonbar := its.wdgts.frame(its.wholeframe, side=its.aside,
					 borderwidth=0, padx=0, pady=0,
					 width=0, height=0,
					 expand=its.aexpand);
    its.gui.pleftbar := its.wdgts.frame(its.gui.buttonbar, side=its.side,
					borderwidth=0, padx=0, pady=0,
					width=0, height=0, 
					expand=its.expand);
    its.gui.leftbbar := its.wdgts.frame(its.gui.pleftbar, side=its.aside,
					borderwidth=0, padx=0, pady=0,
					width=0, height=0,
					expand=its.aexpand);
    its.gui.tapedeck := its.wdgts.tapedeck(its.gui.leftbbar,
					   orient=its.orient);
    whenever its.gui.tapedeck->tostart do {
	its.animator.tostart();
    } its.pushwhenever();
    whenever its.gui.tapedeck->toend do {
	its.animator.toend();
    } its.pushwhenever();
    whenever its.gui.tapedeck->forwardstep do {
	its.animator.forwardstep();
    } its.pushwhenever();
    whenever its.gui.tapedeck->reversestep do {
	its.animator.reversestep();
    } its.pushwhenever();
    whenever its.gui.tapedeck->reverseplay do {
	its.animator.reverseplay();
    } its.pushwhenever();
    whenever its.gui.tapedeck->forwardplay do {
	its.animator.forwardplay();
    } its.pushwhenever();
    whenever its.gui.tapedeck->stop do {
	its.animator.stop();
    } its.pushwhenever();
    
    its.gui.frametext := its.wdgts.entry(its.gui.leftbbar, width=4,
					 relief='sunken', font='bold',
					 justify='center');
    its.gui.lengthtext := its.wdgts.label(its.gui.leftbbar, '', width=4,
					  relief='sunken');

    whenever its.gui.frametext->return do {
	fno := as_integer($value);
	tmp := its.animator.goto(fno);
	if (!tmp) {
	    its.gui.frametext->delete("start","end");
	    its.gui.frametext->insert(as_string(its.animator.currentframe()));
	}
    } its.pushwhenever();

    whenever its.animator->state do {
	t := $value;
	its.gui.frametext->delete("start","end");
	if (t.length > 0) {
	    its.gui.frametext->insert(as_string(t.frame));
	    its.gui.lengthtext->text(spaste('/', as_string(t.length)));
	} else {
	    its.gui.lengthtext->text('');
	}
	its.gui.mode[t.mode]->state(T);
    } its.pushwhenever();

    its.gui.subpanelbutton := its.wdgts.button(its.gui.leftbbar, '>', 
					       bitmap='rightarrow.xbm');

    its.wdgts.popuphelp(its.gui.subpanelbutton,
	      txt=spaste('Press this button to reveal an Animation ',
			 'Control window.'),
	      hlp='Animation Control...');


    # Normal/Blink mode radio buttons

    its.gui.normaltext  := its.wdgts.label(its.gui.leftbbar,'\nNormal',
					 font='bold');
    its.gui.mode  := [=];
    for (i in "normal blink") {
        its.gui.mode[i] := its.wdgts.button(its.gui.leftbbar, '',
					    type='radio',value=i);
        whenever its.gui.mode[i]->press do {
	    its.animator.setmode($value);
        } its.pushwhenever();
    }
    its.gui.mode[its.animator.mode()]->state(T);
	# initialize radio buttons to mode of the animator.

    its.gui.blinktext := its.wdgts.label(its.gui.leftbbar, 'Blink',
					 font='bold');
    its.wdgts.popuphelp(its.gui.mode['normal'],
			txt=spaste('In this mode the animator selects\n',
				   'the image plane to display.') );
    its.wdgts.popuphelp(its.gui.mode['blink'],
			txt=spaste('Select this mode to \'blink\' between\n',
				   'several images, or view them\n',
				   'side-by-side in a multipanel.') );


    its.gui.subpanel := [=];
    its.gui.firsttime := T;

    # function closure for Animation Control Window
    its.subpanel := function(leadwidget,animator,widgetset) {
	private := [=];
	private.lead := leadwidget;
	private.ws := widgetset;
	private.ani := animator;
	private.whenevers := [];
	private.visible := F;
	private.consumed := F;

	public := [=];

	private.pushwhenever := function() {
	    wider private;
	    private.whenevers[len(private.whenevers) + 1] := 
		last_whenever_executed();
	    return T;
	}
	const private.deactivate := function(which) {
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
	public.isvisible := function() {
	    return private.visible;
	}

	public.gui := function() {
	    wider private;
	    if (private.visible) {
		return F;
	    }
	    private.ws.tk_hold();
	    private.f0->map();	    
	    private.lead->bitmap('leftarrow.xbm');
	    private.ws.tk_release();
	    private.visible := T;
	    return T;
	}
	public.dismiss := function() {
	    wider private;
	    if (!private.visible) {
		return F;
	    }
	    private.ws.tk_hold();
	    private.f0->unmap();	    
	    private.lead->bitmap('rightarrow.xbm');
	    private.ws.tk_release();
	    private.visible := F;
	    return T;
	}
	
	public.done := function() {
	    wider public,private;
	    if (len(private.whenevers) > 0) {
		private.deactivate(private.whenevers);
	    }
	    private.f0->unmap();
	    val private := F;
	    val public := F;
	}

	private.ws.tk_hold();
	private.f0 := private.ws.frame(tlead=private.lead,
				       tpos='ne', relief='raised');
	
	private.title := private.ws.label(private.f0,
					  'Animation control',
					  font='bold');
	
#	 private.stickframe := private.ws.frame(private.f0,
#						side='right');
#	 
#	 private.stickscale := private.ws.scale(private.stickframe,
#						 start=1,
#						 end=private.ani.
#						 nframes(),
#						 resolution=1,
#						 value=private.ani.
#						 currentframe());
#	     
#	 private.sticklabel := private.ws.label(private.stickframe,
#						'Current frame');
	
	private.frateframe := private.ws.frame(private.f0,
					       side='right');
	private.fratescale := private.ws.scale(private.
					       frateframe, 
					       start=1, end=25, 
					       resolution=1,
					       value=private.ani.
					       getframerate());
	private.fskipframe := private.ws.frame(private.f0,
					       side='right');
	private.fskipscale := private.ws.scale(private.
					       fskipframe, 
					       start=0, end=20, 
					       resolution=1,
					       value=private.ani.
					       getanimateskip());
	
	
#	 whenever private.stickscale->value do {		
#	     private.consumed := T;
#	     private.ani.goto($value);
#	 } private.pushwhenever();
	 
#	 whenever private.ani->state do {
#	     tmp := $value;
#		 if (!private.consumed) {
#		     t := private.stickscale->value(tmp.frame);
#		 } 
#	     private.consumed := F;
#	 } private.pushwhenever();
	
	whenever private.ani->framerate do {
		if (private.visible) {
		    t := private.fratescale->value($value);
		}
	    } private.pushwhenever();
	
	whenever private.fratescale->value do {
	    t := private.ani.setframerate($value, F);
	} private.pushwhenever();
	private.fratelabel := private.ws.label(private.frateframe,
					       'Frame rate (tgt fps)');
	
	whenever private.ani->animateskip do {
	    if (its.subpanelvisible) {
		t := private.fskipscale->value($value);
	    }
	} private.pushwhenever();
	whenever private.fskipscale->value do {
	    private.ani.setanimateskip($value, F);
	} private.pushwhenever();
	
	private.fskiplabel := private.ws.label(private.fskipframe,
					       'Frame skip (0=none)');
	    
	private.dismiss := private.ws.button(private.f0, 
					     'Dismiss', 
					     type='dismiss');
	whenever private.dismiss->press do {
	    t := public.dismiss();
	} private.pushwhenever(); 
	
	private.visible := T;
	private.lead->bitmap('leftarrow.xbm');
	t := private.ws.tk_release();  

	return public;
    }
    
    whenever its.gui.subpanelbutton->press do {
	if (its.gui.firsttime) {
	    its.gui.subpanel := its.subpanel(its.gui.subpanelbutton,
					     its.animator,
					     its.wdgts);
	    its.gui.firsttime := F;
	} else {
	    if (its.gui.subpanel.isvisible()) {
		t := its.gui.subpanel.dismiss();	    
		#its.gui.subpanelbutton->bitmap('rightarrow.xbm');
	    } else {
		t := its.gui.subpanel.gui();
		#its.gui.subpanelbutton->bitmap('leftarrow.xbm');
	    }
	}	
    } its.pushwhenever();

    its.gui.rightbbar := its.wdgts.frame(its.gui.buttonbar, side='right',
					 relief='flat', borderwidth=0,
					 padx=0, pady=0, width=0, height=0,
					 expand='none');
    if (its.hasdone) {
	its.gui.bdone := its.wdgts.button(its.gui.rightbbar, 'Done',
					  type='halt');
	whenever its.gui.bdone->press do {
	    self.done();
	} its.pushwhenever();
    }
    if (its.hasdismiss) {
	its.gui.bdismiss := its.wdgts.button(its.gui.bdismiss, 'Dismiss',
					     type='dismiss');
	whenever its.gui.bdismiss->press do {
	    self.done();
	} its.pushwhenever();
    }
					 
    if (its.animator.enabled()) {
	self.enable();
    } else {
	self.disable();
    }

    if (its.show) {
	t := self.map();    
    }
}

const viewerdpmenu := subsequence(leadmenu=unset, viewer=unset) {
    its := [=];
    its.lead := leadmenu;
    its.menu := [=];
    its.viewer := viewer;
    its.wdgts := its.viewer.widgetset();
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
    
    its.menu.indexshare := 
	its.wdgts.button(its.lead, 
			 spaste('New display: colormap mode ',
				'(non-flashing)'));
    whenever its.menu.indexshare->press do {
	if (!is_agent(its.viewer.newdisplaypanel(maptype='index', 
						 newcmap=F, 
						 hasdone=T,
						 autoregister=T))) {
	    note('Could not allocate sufficient colors',
		 origin=its.viewer.title(), priority='SEVERE');
	}
    } its.pushwhenever();
    its.menu.indexits := 
	its.wdgts.button(its.lead, 
			 spaste('New display: colormap mode ',
				'(most colors)'));
    whenever its.menu.indexits->press do {
	if (!is_agent(its.viewer.newdisplaypanel(maptype='index', 
						 newcmap=T, 
						 hasdone=T,
						 autoregister=T))) {
	    note('Could not allocate sufficient colors',
		 origin=its.viewer.title(), priority='SEVERE');
	}
    } its.pushwhenever();
    
    its.menu.sliceindexshare := 
	its.wdgts.button(its.lead, 
			 spaste('New slice display: colormap mode ',
				'(non-flashing)'));
    whenever its.menu.sliceindexshare->press do {
	if (!is_agent(its.viewer.newdisplaypanel(maptype='index', 
						 newcmap=F, 
						 hasdone=T,
						 slicepanel=T,
						 autoregister=T))) {
	    note('Could not allocate sufficient colors',
		 origin=its.viewer.title(), priority='SEVERE');
	}
    } its.pushwhenever();
    its.menu.sliceindexits := 
	its.wdgts.button(its.lead, 
			 spaste('New slice display: colormap mode ',
				'(most colors)'));
    whenever its.menu.sliceindexits->press do {
	if (!is_agent(its.viewer.newdisplaypanel(maptype='index', 
						 newcmap=T, 
						 hasdone=T,
						 slicepanel=T,
						 autoregister=T))) {
	    note('Could not allocate sufficient colors',
		 origin=its.viewer.title(), priority='SEVERE');
	}
    } its.pushwhenever();
    
    its.menu.rgbshare :=
	its.wdgts.button(its.lead,
			 'New display: RGB mode (non-flashing)');
    whenever its.menu.rgbshare->press do {
	if (!is_agent(its.viewer.newdisplaypanel(maptype='rgb',
						 newcmap=F, 
						 hasdone=T))) {
	    note('Could not allocate sufficient colors',
		 origin=its.viewer.title(), priority='SEVERE');
	}
    } its.pushwhenever();
    its.menu.rgbits := 
	its.wdgts.button(its.lead,
			 'New display: RGB mode (most colors)');
    whenever its.menu.rgbits->press do {
	if (!is_agent(its.viewer.newdisplaypanel(maptype='rgb',
						 newcmap=T, 
						 hasdone=T))) {
	    note('Could not allocate sufficient colors',
		 origin=its.viewer.title(), priority='SEVERE');
	}
    } its.pushwhenever();
    its.menu.hsvshare :=
	its.wdgts.button(its.lead,
			 'New display: HSV mode (non-flashing)');
    whenever its.menu.hsvshare->press do {
	if (!is_agent(its.viewer.newdisplaypanel(maptype='hsv',
						 newcmap=F, 
						 hasdone=T))) {
	    note('Could not allocate sufficient colors',
		 origin=its.viewer.title(), priority='SEVERE');
	}
    } its.pushwhenever();
    its.menu.hsvits :=
	its.wdgts.button(its.lead,
			 'New display: HSV mode (most colors)');
    whenever its.menu.hsvits->press do {
	if (!is_agent(its.viewer.newdisplaypanel(maptype='hsv',
						 newcmap=T, 
						 hasdone=T))) {
	    note('Could not allocate sufficient colors',
		 origin=its.viewer.title(), priority='SEVERE');
	}
    } its.pushwhenever();   
    self.done := function() {
	wider its,self;
	if (len(its.whenevers) > 0) {
	    its.deactivate(its.whenevers);
	}
	val its := F;
	val self := F; 
    }    
}

## ************************************************************ ##
##                                                              ##
## "STATIC" FUNCTIONS STORED IN VIEWER AS "ATTRIBUTES"          ##
##                                                              ##
## ************************************************************ ##

############################################################
## TRACE STATUS FLAGS                                     ##
############################################################
viewer::tracedone := F;
viewer::traceskip := F;

############################################################
## VIEWER TOOL IDENTIFICATION                             ##
############################################################
const is_viewer := function(tool) {
  return is_record(tool) && has_field(tool, 'type') && 
    is_function(tool.type) && tool.type() == 'viewer';
}
############################################################
## GENERATION OF TEST ARRAY DATA FUNCTION                 ##
############################################################
const viewermaketestarray := function(size=100) {
    isize := as_integer(abs(size));
    rrsize := as_float(1.0 / as_float(abs(size)));
    tar := array(as_float(0.0), isize, isize);
    for (i in 1:isize) {
	for (j in 1:isize) {
	    tar[i,j] := cos(i*pi*2*rrsize) * sin(j*pi*2*rrsize) + 
		(i*2*rrsize-0.5)*cos(j*2*pi*rrsize*i*2*pi*rrsize);
	}
    }
    return tar;
}
#const viewermaketestarray := function(size=100) {
#    note('viewermaketestarray deprecated, please use viewer::maketestarray',
#	 priority='WARN', origin='viewer');
#    return viewer::maketestarray(size);
#}

############################################################
## GENERATE A TEST IMAGE                                  ##
############################################################
const viewermaketestimage := function(outfile=unset) {
    img := imagemaketestimage(outfile);
    return img;
}

############################################################
## OPENING OF SOURCES SKY CATALOG                         ##
############################################################
const vieweropentestskycatalog := function() {
    if (!has_field(environ, 'AIPSPATH')) {
	fail 'Cannot determine AIPSPATH setting';
    }
    x := spaste(split(environ.AIPSPATH)[1], 
		'/data/ephemerides/Sources');
    if (!tableexists(x)) {
	fail 'Cannot find Sources table';
    }
    include 'table.g';
    tbl := table(x);
    return tbl;
}


############################################################
## INTERNAL STUFF                                         ##
############################################################
	    
############################################################
## FUNCTION COUNTING FUNCTION                             ##
############################################################
viewer::functioncounts := [=];
viewer::functioncalls := as_string([]);
const viewer::countfunction := function(fname) {
    global viewer;
    if (has_field(viewer::functioncounts, fname)) {
	 count := viewer::functioncounts[fname] + 1;
    } else {
	 count := 1;
    }
    viewer::functioncounts[fname] := count;
    viewer::functioncalls[len(viewer::functioncalls) + 1] := fname;
}
const __VCF_ := const viewer::countfunction;

## ************************************************************ ##
##                                                              ##
## INCLUDE THE REST OF THE VIEWER                               ##
##                                                              ##
## ************************************************************ ##
include 'viewerdisplaydata.g';
include 'viewerdisplaypanel.g';
include 'viewerslicedp.g';
include 'viewercolormapmanager.g';
include 'viewerdatamanager.g';

## ************************************************************ ##
##                                                              ##
## CONSTRUCT THE DEFAULTVIEWER                                  ##
##                                                              ##
## ************************************************************ ##
const defaultviewer := viewer('defaultviewer');
const dv := ref defaultviewer;
if (!is_fail(dv)) {
    note(spaste('defaultviewer (dv) ready'), priority='NORMAL', 
	 origin='viewer.g');
    
} else {
    symbol_delete('dv');
    note('Could not make the defaultviewer', priority='SEVERE',
	 origin='viewer.g');
}
