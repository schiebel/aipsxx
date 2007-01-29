# viewerdatamanager.g: gui to simplify data import into the viewer
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
# $Id: viewerdatamanager.g,v 19.1 2005/06/15 18:10:57 cvsmgr Exp $

pragma include once;
include 'viewer.g';
include 'minicatalog.g';

## ************************************************************ ##
##                                                              ##
## VIEWERDATAMANAGER SUBSEQUENCE                                ##
##                                                              ##
## ************************************************************ ##
viewerdatamanager := subsequence(parent=F, viewer, show=T,
				 hasdismiss=T, hasdone=F,
				 widgetset=unset) : 
    [reflect=T] {
    __VCF_('viewerdatamanager');
    ############################################################
    ## SANITY CHECK                                           ##
    ############################################################
    if (!is_record(viewer) || !has_field(viewer, 'type') ||
	(viewer.type() != 'viewer')) {
	return throw('An invalid viewer was given to a viewerdatamanager');
    }
    if (hasdone && hasdismiss) {
	note(spaste('An attempt was made to construct a ',
		    'viewerdatamanager with both Dismiss AND Done ',
		    'buttons'));
	hasdismiss := F;
    }	    

    ############################################################
    ## INITIALISE AND STORE CONSTRUCTOR ARGUMENTS             ##
    ############################################################
    its := [=];
    its.parent := parent;
    its.viewer := viewer;
    its.show := show;
    its.hasdismiss := hasdismiss;
    its.hasdone := hasdone;
    its.wdgts := widgetset;
    
    ############################################################
    ## BASIC SERVICES                                         ##
    ############################################################
    its.type := 'viewerdatamanager';
    self.type := function() { 
	__VCF_('viewerdatamanager.type');
	return its.type;
    }

    self.viewer := function() {
	__VCF_('viewerdatamanager.viewer');
	return its.viewer;
    }

    if (is_unset(its.wdgts)) {
	its.wdgts := its.viewer.widgetset();
	if (is_fail(its.wdgts)) fail;
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
	__VCF_('viewerdatamanager.map');
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
	__VCF_('viewerdatamanager.unmap');
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
	__VCF_('viewerdatamanager.ismapped');
	return its.ismapped;
    }

    ############################################################
    ## DONE FUNCTION                                          ##
    ############################################################
    its.dying := F;
    self.done := function() {
	__VCF_('viewerdatamanager.done');
	wider self, its;
	if (its.dying) {
	    # prevent multiple done requests
	    return F;
	} its.dying := T;
	if (viewer::tracedone) {
	    print 'viewerdatamanager::done()';
	}
	if (is_agent(its.gui.datasets)) {
	    its.gui.datasets.done()
	}
	if (is_agent(its.gui.dpmenu)) {
	    its.gui.dpmenu.done();
	}
	its.deactivate(its.whenevers);
	its.gui.fcat.done();
	self.unmap(T);
	val its := F;
	val self := F;
	return T;
    }

    ############################################################
    ## DISMISS FUNCTION                                       ##
    ############################################################
    self.dismiss := function() {
	__VCF_('viewerdatamanager.done');
	return self.unmap();
    }

    ############################################################
    ## GUI FUNCTION                                           ##
    ############################################################
    self.gui := function() {
	__VCF_('viewerdatamanager.gui');
	return self.map();
    }
    
    ############################################################
    ## DISABLE/ENABLE THE GUI                                 ##
    ############################################################
    self.disable := function() {
	__VCF_('viewerdatamanager.disable');
	if (its.madeparent) {
	    t := its.parent->disable();
	    t := its.parent->cursor("watch");
	} 
	return T;
    }
    self.enable := function() {
	__VCF_('viewerdatamanager.enable');
	if (its.madeparent) {
	    t := its.parent->enable();
	    t := its.parent->cursor(its.originalcursor);
	}
	return T;
    }

    ############################################################
    ## UTILITY FUNCTIONS                                      ##
    ############################################################
    
    its.is_array := function(thing) {
	if (!is_numeric(thing)) return F;
	if (len(shape(thing)) < 2) return F;
	return T;
    }

    ############################################################
    ## FILE UTILITIES                                         ##
    ############################################################
    its.dlformatfromftype := function(ftype) {
	#translate catalog type to viewer type
	if (!is_string(ftype)) {
	    fail 'ftype Not a string';
	}
	if (ftype == 'Image' || ftype == 'FITS' 
	    || ftype == 'Miriad Image' || ftype == 'Gipsy') {
	    return 'image';
	} else if (ftype == 'IERS' || ftype == 'Skycatalog') {
	    return 'table';
   	} else if (ftype == 'Measurement Set') {
   	    return 'ms';
	} else {
	    fail 'File type not supported';
	}
	return;
    }

    its.datasetfromfile := function(name,type) {
	#create a viewer dataset from file
	rec := [=];
	if (!is_string(name)) {
	    return throw('name is not of type string');
	}
	temp := split(name, '/');
	rec.listname := temp[len(temp)];
	rec.data := name;
	if (type=='Image' || type=='FITS' || type=='Miriad Image') {
	    rec.dlformat := 'image';
   	} else if (type == 'Measurement Set') {
   	    rec.dlformat := 'ms';
	} else if (type == 'Skycatalog' || type == 'IERS') {
	    rec.dlformat := 'table';
	} else if (type == 'Gipsy') {
           name =~ s/\.(descr|image)$//;
           rec.listname =~ s/\.(descr|image)$//;
           rec.data := its.viewer.maketempimage(name,type);
           rec.dlformat := 'image';
	} else {
	    return throw(spaste('File type ',type,' not supported'));
	}	
	return rec;
    }

    its.maskfromdisplaytypes := function(dtypes=unset) {
	wider its;	
	i := 1;
	mask := [];
	if (is_unset(mask)) {
	    for (i in 1:len(its.viewer.alldisplaytypes())) {
		mask[i] := F;
	    }
	} else {	
	    for (str in field_names(its.viewer.alldisplaytypes())) {
		for (str2 in field_names(dtypes)) {
		    if (str == str2) {
			mask[i] := T;
			break;
		} else {
		    mask[i] := F;
		}
	    }
		i +:= 1;
	    }
	}
	return mask;
    }

    ############################################################
    ## TOOL UTILITIES                                         ##
    ############################################################

    its.datasetfromname := function(name) {
	for (i in field_names(its.datasets)) {
	    if (its.datasets[i].listname == name) {
		return its.datasets[i];
	    }
	}
	return throw('Couldn\'t find named dataset');
    }

    its.persistentiftemp := function(imagename) {
	if (!is_string(imagename)) return throw('imagename is not of type string');
	if (imagename =~ s/^tempimage://) {
	    return its.viewer.maketempimage(imagename);
	} else {
	    return imagename;
	}
    }

    self.validtools := function() {
	wider its;
	#validtools := "array table image";
	rec := [=];
	list := symbol_names(is_image);
	if (len(list) > 0) {
	    sort(list);
	    for (str in list) {
		if (!(str ~ m/^_/)) {
		    rec[str].listname := spaste('image:', str);
		    if (!eval(str).ispersistent()) {
			rec[str].data := 
			    spaste('tempimage:', str);
		    } else {
			rec[str].data := eval(str).name();;
		    }
		    rec[str].dlformat := 'image';
		}
	    }
	}
	list := symbol_names(is_table);
	if (len(list) > 0) {
	    sort(list);
	    for (str in list) {
		if (!(str ~ m/^_/)) {
		    rec[str].listname := spaste('table:', str);
		    rec[str].data := eval(str).name();
		    rec[str].dlformat := 'table';
		}
	    }
	}
	list := symbol_names(its.is_array);
	if (len(list) > 0) {
	    sort(list);
	    for (str in list) {
		if (!(str ~ m/^_/)) {
		    rec[str].data := eval(str);
		    rec[str].listname := spaste('array:', str);
		    rec[str].dlformat := "array";
		}
	    }
	}
	return rec;
    }

    ############################################################
    ## CONSTRUCT FRAME                                        ##
    ############################################################
    its.wdgts.tk_hold();
    its.madeparent := F;
    if (is_boolean(its.parent)) {
	its.parent := 
	    its.wdgts.frame(title=spaste(its.viewer.title(),
					 ' - Data Manager (AIPS++)'));
	if (is_fail(its.parent))  {
	    its.wdgts.tk_release();
	    return throw(spaste('Failed to construct a frame: probable ',
				'incompatibility between widgetservers'));
	}
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
    ## CONSTRUCT MENUBAR                                      ##
    ############################################################
    its.gui.menubar := its.wdgts.frame(its.wholeframe, side='left', 
				       relief='raised', expand='x');
    
    its.gui.wndwmenu.menu := its.wdgts.button(its.gui.menubar, 'File',
					      type='menu', relief='flat');

    its.gui.dpmenu := viewerdpmenu(its.gui.wndwmenu.menu,its.viewer);
    if (is_fail(its.gui.dpmenu)) fail;
    its.gui.wndwmenu.spacer1 := 
	its.wdgts.button(its.gui.wndwmenu.menu, 
			 '---------------------------------');
    t := its.gui.wndwmenu.spacer1->disabled(T);
    its.gui.wndwmenu.newcmap := its.wdgts.button(its.gui.wndwmenu.menu, 
						 'Colormap manager');
    whenever its.gui.wndwmenu.newcmap->press do {
	its.viewer.newcolormapmanagergui(hasdone=T);
    } its.pushwhenever();
    
    its.gui.wndwmenu.spacer2 := 
	its.wdgts.button(its.gui.wndwmenu.menu, 
			 '---------------------------------');
    t := its.gui.wndwmenu.spacer2->disabled(T);
    
    if (its.hasdismiss) {
	its.gui.wndwmenu.dismiss := 
	    its.wdgts.button(its.gui.wndwmenu.menu, 'Dismiss window', 
			     type='dismiss');
	whenever its.gui.wndwmenu.dismiss->press do {
	    self.dismiss();
	} its.pushwhenever();
    }
    if (its.hasdone) {
	its.gui.wndwmenu.done := 
	    its.wdgts.button(its.gui.wndwmenu.menu, 'Done - Datamanager', 
			     type='halt');
	whenever its.gui.wndwmenu.done->press do {
	    self.done();
	} its.pushwhenever();
    }
    its.gui.wndwmenu.bexit := 
	its.wdgts.button(its.gui.wndwmenu.menu, 'Done', type='halt');
    whenever its.gui.wndwmenu.bexit->press do {
	its.viewer.done();
    } its.pushwhenever();

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
	if (is_fail(oktmp)) fail;
	if (oktmp) {
	    x := help('Refman');
	}
    } its.pushwhenever();
    its.gui.helpm.about := its.wdgts.button(its.gui.helpm.menu, 
				      text='About Aips++');
    whenever its.gui.helpm.about->press do {
	oktmp := eval('include \'about.g\'');
	if (is_fail(oktmp)) fail;
	if (oktmp) {
	    x := about();
	}
    } its.pushwhenever();
    its.gui.helpm.ask := its.wdgts.button(its.gui.helpm.menu, 
				    text='Ask a question');
    whenever its.gui.helpm.ask->press do {
	oktmp := eval('include \'askme.g\'');
	if (is_fail(oktmp)) fail;
	if (oktmp) {
	    x := askme();
	}
    } its.pushwhenever();
    its.gui.helpm.bug := its.wdgts.button(its.gui.helpm.menu, 
					    text='Report a bug');
    whenever its.gui.helpm.bug->press do {
	oktmp := eval('include \'bug.g\'');
	if (is_fail(oktmp)) fail;
	if (oktmp) {
	    x := bug();
	}
    } its.pushwhenever();
    
    ############################################################
    ## GUI FUNCTIONS                                          ##
    ############################################################

    its.showdtypebuttons := function(mask) {
	wider its;
	for (i in 1:len(mask)) {
	    if (mask[i]) {
		its.gui.dtypes.f[i]->map();
	    } else {
		its.gui.dtypes.f[i]->unmap();		
	    }
	}
    }

    self.reset := function(filecat=T,dataset=T,gui=T) {
	wider its;
	if (filecat) {
	    its.selfile := [=];
	    its.gui.fcat->clear();
	}
	if (dataset) {
	    its.seldataset := [=];
	    its.gui.datasets.deselect();
	}
	if (gui) {
	    its.showdtypebuttons(its.maskfromdisplaytypes());
	}
	return T;
    }

    ############################################################
    ## MAIN GUI                                               ##
    ############################################################
    its.gui.upperframe := its.wdgts.frame(its.wholeframe,side='left',
					  padx=0,pady=0);

    ############################################################
    ## FILE CATLOG GUI                                        ##
    ############################################################
    its.selfile := [=];
    its.gui.inputframe := its.wdgts.frame(its.gui.upperframe,
					 padx=2,pady=0,borderwidth=0);    
    its.gui.fcatframe := its.wdgts.frame(its.gui.inputframe,
					 padx=2,pady=0);
    its.wdgts.popuphelp(its.gui.fcatframe,hlp='Choose a file...');
    its.allowedtypes:= ['Directory','<Any Table>',
			'FITS','Miriad Image','Gipsy']
    its.gui.fcat := 
	minicatalog(its.gui.fcatframe,
		    allowedtypes=its.allowedtypes,
		    widgetset=its.wdgts);
    if (is_fail(its.gui.fcat )) return throw('Couldn\'t create File Catalog');
    whenever its.gui.fcat->select do {
	format := its.dlformatfromftype($value.ftype);
	if (!is_fail(format)) {
	    its.selfile.name := $value.fname;
	    its.selfile.type := $value.ftype;	    
	    rec := its.viewer.validdisplaytypes(format);
	    mask := its.maskfromdisplaytypes(rec);
	    its.showdtypebuttons(mask);
	} else {
	    self.reset(filecat=F);
	}
    } its.pushwhenever();


    ############################################################
    ## TOOL GUI                                               ##
    ############################################################
     
    its.gui.datasetsframe := its.wdgts.frame(its.gui.inputframe,
					     padx=0,pady=0);
    its.wdgts.popuphelp(its.gui.datasetsframe,hlp='Choose a tool...');
    its.gui.datasets := viewerlistarea(its.gui.datasetsframe,
				       'Tool Name', buttons="Update",
				       widgetset=its.wdgts);
    if (is_fail(its.gui.datasets)) fail;
    its.datasets := self.validtools();
    its.gui.datasets.fill(its.datasets);


    its.buttonmask := [];    
    i := 1;
    its.gui.dtypes.f := [=];
    its.gui.rightframe := its.wdgts.frame(its.gui.upperframe,padx=0,pady=0, expand='y');
    its.gui.dtypeframe := its.wdgts.frame(its.gui.rightframe, expand='y',
					  padx=2,pady=0,
					  relief='groove');
    its.gui.dtypelbl := its.wdgts.label(its.gui.dtypeframe,
				      'DisplayData Type');
    its.wdgts.popuphelp(its.gui.dtypelbl,
			txt=spaste('Click on one of the buttons below ',
				   'to create a DisplayData of that ',
				   'display type'),
			hlp=spaste('This shows the available ',
				   'DisplayData types for the ',
				   'selected file or tool.'));

    its.gui.dtypes.mf:= its.wdgts.frame(its.gui.dtypeframe);
    its.gui.dtypes.btns := [=];
    rec := its.viewer.alldisplaytypes();
    if (is_fail(rec)) fail;
    for (str in field_names(rec)) {
	its.gui.dtypes.f[str] := its.wdgts.frame(its.gui.dtypes.mf,
						 expand='none');
	its.gui.dtypes.btns[str] := 
	    its.wdgts.button(its.gui.dtypes.f[str],text=rec[str].listname, 
			     width=18,relief='groove',value=rec[str]);
	its.gui.dtypes.f[str]->unmap();
	its.buttonmask[i] := F; 
	    whenever its.gui.dtypes.btns[str]->press do {
		its.showdtypebuttons(its.maskfromdisplaytypes());
		its.gui.datasets.deselect();
		if (len(its.selfile)>0) {
		    its.seldataset := 
			its.datasetfromfile(its.selfile.name,
					    its.selfile.type);
		}
		dd := self.createdd(its.seldataset,$value);
		if(is_fail(dd)) note(dd::message,
		  origin=spaste(its.viewer.title(),' (viewerdatamanager.g)'),
		  priority='SEVERE');
		  # NB: Without this test, such a fail is _silent_ (!)
	    } its.pushwhenever();
	i +:= 1;
    }
    its.gui.autoregbtn := its.wdgts.button(its.gui.rightframe,
					  text='Autoregister',
					   fill='x',type='check');
    its.gui.autoregbtn->state(T);
    its.wdgts.popuphelp(its.gui.autoregbtn,
			txt=spaste('Check this button ',
				   'to register (make visible) ',
				   'your DisplayData automatically.'),
			hlp=spaste('This determines wether the ',
				   'Displaydata will be displayed ',
				   'automatically'));

    its.seldataset := [=];
    self.createdd := function(dataset,displaytype,register=F) {
	autoregister := its.gui.autoregbtn->state();
	if ( dataset.dlformat == 'image' ) {
	    dataset.data := its.persistentiftemp(dataset.data);
	}
	if (is_record(dataset)) {
	    temp := its.viewer.createdata(dataset,displaytype);
	} else {	    
	}
	self.reset();
	if (is_fail(temp)) {
	    fail spaste('Unable to create DisplayData:',temp::message);
	}
	if (autoregister) {
	    its.viewer.autoregister(temp);
	}
	return T;
    } 

    whenever its.gui.datasets->select do {
	# clear its.gui.fcat
	self.reset(dataset=F)
	its.seldataset := its.datasetfromname($value);
	rec := its.viewer.validdisplaytypes(its.seldataset.dlformat);
	mask := its.maskfromdisplaytypes(rec);
	its.showdtypebuttons(mask);	
    } its.pushwhenever();


    whenever its.gui.datasets->press do {
	if ($value == 'Update') {
	    its.gui.fcat.update(types=its.allowedtypes);
	    its.datasets := self.validtools();
	    its.gui.datasets.fill(its.datasets);
	    its.showdtypebuttons(its.maskfromdisplaytypes());
	}
    } its.pushwhenever();

    ############################################################
    ## DISMISS DONE GUI ELEMENTS                              ##
    ############################################################
    
    its.gui.lowerframe := its.wdgts.frame(its.wholeframe, expand='x');
    its.gui.rightbbar := its.wdgts.frame(its.gui.lowerframe, side='right',
					 relief='flat', expand='x');
    if (its.hasdismiss) {
	its.gui.dismissb := its.wdgts.button(its.gui.rightbbar, 'Dismiss',
					     type='dismiss');
	its.wdgts.popuphelp(its.gui.dismissb,
		  txt=spaste('Press this button to hide this data manager - ',
			     'you can probably retrieve it later via the ',
			     'application you are using, or via the ',
			     'command line'),
		  hlp='Hide this data manager');
	whenever its.gui.dismissb->press do {
	    self.dismiss();
	} its.pushwhenever();
    }
    if (its.hasdone) {
	its.gui.doneb := its.wdgts.button(its.gui.rightbbar, 'Done',
					  type='halt');
	its.wdgts.popuphelp(its.gui.doneb,
		  txt=spaste('Press this button to be finished with this ',
			     'data manager - you can always get another ',
			     'one back!'),
		  hlp='Finish with this data manager');
	whenever its.gui.doneb->press do {
	    self.done();
	} its.pushwhenever();
    }

    # map the gui to the screen if show=T in constructor
    if (its.show) {
	t := self.map();
    }    

     t := its.viewer.registerdatamanager(self);
     if (is_fail(t)) {
	self.done();
	return throw(t::message);
    }
}
