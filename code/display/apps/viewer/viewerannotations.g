pragma include once;

include 'note.g';
include 'ddlws.g';
include 'twodactionoptionmenu.g';
include 'multiautogui.g';
include 'rollup.g';

viewerannotations := subsequence(displaypanel, title="Unknown Draw Area",
				 widgetset = ddlws)  {

    ############################################################
    ## SANITY CHECK                                           ##
    ############################################################
    if (!is_record(displaypanel) || !has_field(displaypanel, 'type') ||
        (displaypanel.type() != 'viewerdisplaypanel')) {
        return throw(spaste('An invalid viewerdisplaypanel was given to a ',
                            'viewerannotator'));
    }
    if (is_agent(displaypanel.annotator())) {
        return throw(spaste('The parent viewerdisplaypanel given to the ',
                            'viewerannotator constructor already ',
                            'has a viewerannotator'));
    }

    if (!displaypanel.holdsdata()) 
	return throw(spaste('The parent viewerdisplaypanel cannot hold ',
			    'any data (holdsdata == F) . Creation of world ',
			    'annotations requires',
			    ' this to be true. Creation of viewerannotations ',
			    'has ',
			    'therefore failed.'));

    ############################################################
    ## INITIALISE AND STORE CONSTRUCTOR ARGUMENTS             ##
    ############################################################
    its := [=];
    its.gui := [=];
    its.title := title;
    its.widgetset := widgetset;
    its.displaypanel := displaypanel;
    its.currentkey := 0;
    its.currentmarker := 4;
    its.killed := F;
    its.mystate := [=];
    its.mystate.state := 'nothing';
    
    its.pd := displaypanel.paneldisplayagent();
    
    if (is_fail(its.pd) || !is_agent(its.pd) ) 
	fail 'Couldn\'t obtain a panel display for use by annotations';

    # Make the proxy
    its.annot := its.widgetset.annotations(its.pd);

    if (is_fail(its.annot)) 
	fail 'Couldn\'t construct the annotations proxy';

    # Set up the default quanta server
    if(!is_defined('dq')) 
	throw (AipsError(spaste('viewerannotations.g - Defaultquanta does',
				' not exist')));
    
    dq.define('pix');
    dq.define('frac');
    
  
    # Ok....

    
    ############################################################
    ## WHENEVER PUSHER                                        ##
    ############################################################
    its.whenevers := [];
    its.pushwhenever := function() {
	wider its;
	its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
    }

    const its.deactivate := function(which) {
	wider its;
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
    ## DONE    FUNCTION                                       ##
    ############################################################
    self.done := function() {
	wider its, self;

	if (its.killed)
	    return F;
	its.killed := T;
	
	its.deactivate(its.whenevers);

	# Clear from screen
	self.dismiss();
	
	# Kill annotator then everything
	val its.annot := F;
	val its := F;
	val self := F;
	return T;
    }

    ############################################################
    ## DISMISS FUNCTION                                       ##
    ############################################################
    self.dismiss := function() {
	wider its;
	return its.dismiss();
    }

    ############################################################
    ## GUI FUNCTIONS                                           ##
    ############################################################
    self.gui := function() {
	wider its;
	if (length(its.gui) == 0) {
	    ok := its.buildgui();
	    if (is_fail(ok)) fail 'Couldn\'t build annotations GUI';
	} else return its.gui.mainframe->map();
    }    

    its.dismiss := function() {
	wider its;
	if (is_agent(its.gui.mainframe)) its.gui.mainframe->unmap();
	return T;
    }
    

    ############################################################
    ## BUILD THE GUI                                          ##
    ############################################################

    its.buildgui := function() {
	wider its;
	its.widgetset.tk_hold();

	#Main frames
	its.gui.mainframe := its.widgetset.frame(side = 'bottom',
						 title=its.title);
	its.gui.bottomframe := its.widgetset.frame(its.gui.mainframe,
						   side = 'right',
						   expand = 'x');

	its.gui.topframe := its.widgetset.frame(its.gui.mainframe,
						side = 'left');

	its.gui.leftframe := its.widgetset.frame(its.gui.topframe,
						 borderwidth =0, padx=1,
						 pady=1, side = 'top', 
						 expand = 'y');
	
	its.gui.rightframe := its.widgetset.frame(its.gui.topframe,
						  borderwidth =0, padx=0,
						  pady=0, side = 'bottom');
	

	## Dismiss / Save / Load 

	its.gui.dismiss := 
	    its.widgetset.button(its.gui.bottomframe,
				 type='dismiss', 
				 text='Dismiss');

	its.gui.saveframe := its.widgetset.frame(its.gui.bottomframe,
						 side = 'left');

	its.gui.save := its.widgetset.button(its.gui.saveframe,
					     'Save');
	its.gui.restore := its.widgetset.button(its.gui.saveframe,
						'Restore');

	its.savename := its.widgetset.guientry(width = 10);
	its.gui.savename := its.savename.string(its.gui.saveframe, 'default',
						default = 'default');


	its.gui.dismisshelp := its.widgetset.popuphelp(its.gui.dismiss,
				 hlp='Dismiss this frame',
				 txt=spaste('Dimiss the options frame. ',
					    'You will still be able to ',
					    'manipulate the shapes using ',
					    'the mouse, and also via command '
					    ,'line calls to ',
					    'yourdisplaypanel.annotator().',
					    '<somefunction>() etc.'));

	#Rollup

	its.gui.rollup := rollup(its.gui.rightframe,
				 side='bottom',
				 show=F, title='Options',
				 widgetset=its.widgetset);

	its.gui.rolluphelp := its.widgetset.popuphelp(its.gui.rollup,
				 hlp='Show / Hide Options...',
				 txt=spaste('This shows or hides context ',
					    'specific options for the ',
					    'currently selected shape.'));
	
	#Option frame - visible when rollup down

	its.gui.optionframe := its.widgetset.frame(its.gui.rollup.frame(),
						   side = 'top');
	
	its.gui.optionlabel := its.widgetset.label(its.gui.optionframe,
					      'Showing options for : None');
	
	its.gui.multigui := multiautogui(toplevel = its.gui.optionframe,
					 widgetset = its.widgetset);
	
	#Frame for canvas selection
	its.gui.canvasframe := its.widgetset.frame(its.gui.rightframe,
						   side = 'left');
	its.gui.canvaslabframe := its.widgetset.frame(its.gui.canvasframe,
						      side = 'left');
	its.gui.canvasselframe := its.widgetset.frame(its.gui.canvasframe,
						      side = 'right');

	
	
	its.gui.canvaslabel := its.widgetset.label(its.gui.canvaslabframe,
						   spaste('Lock to :'));

	its.gui.canvaslonghelp:=
	    spaste('The following options are available for selecting a ',
		   'method by which to \'lock\' shapes in position.',
		   '\n\n- Selecting \'rel. screen\' will lock the shapes onto',
		   ' the screen via their relative positions. For example, ',
		   'a shape which is one quarter of the way from the top of',
		   ' the screen will always remain one quarter of the way ',
		   'from the top. This means that upon resizing the window,',
		   ' shapes will tend to stay in the correct position. This ',
		   'method also produces good results when printing.',
		   '\n- Selecting \'world co-ords\' will *attempt* to ',
		   'position the shape using world co-ordinates. ',
		   'This means that regardless ',
		   'of zoom, resizing etc the annotations will stay locked ',
		   'at the specified world co-ordinates. This obviously means',
		   ' that a shape must be inside a worldcanvas',
		   '. Creation of a shape will fail if this is not true.',
		   '\n- Selecting \'abs. screen\' will lock purely on pixel ',
		   'position, relative from the bottom left corner. This is',
		   ' included more for completeness than anything else. ',
		   'Obviously resizing the window, zooming etc will ',
		   'leave the shapes in their exact same position, relative',
		   ' to the bottom left of the window.',

		   '\n\nGenerally speaking, if you wish the shape to remain',
		   ' locked to a worldcanvas',
		   ' and are happy for that shape to stay within the bounds',
		   ' of the worldcanvas, then choose worldcanvas as the lock ',
		   'method.',
		   ' If you require a shape outside a worldcanvas (anywhere',
		   ' else on the screen), then use relative screen as the ',
		   'lock method.');


	its.gui.canvas := 
	    its.widgetset.actionoptionmenu(its.gui.canvasselframe,
					   labels = ['rel. screen',
						     'world co-ords',
						     'abs. screen'],
					   names = ['rel. screen',
						    'world co-ords',
						    'abs. screen'],
					   values="frac world pix",
					   hlp=spaste('What to use ',
						      'to \'lock\' shapes ',
						      'in position.'),
					   hlp2=its.gui.canvaslonghelp);
	
					    
					    
	#Frame for tools
	
	its.gui.toolframe := its.widgetset.frame(its.gui.rightframe,
						 expand ='none', side='left',
						 pady = 1);


	# The key assignment / Tool selection buttons

	its.gui.keyassign := 
	    its.widgetset.button(its.gui.leftframe,
				 bitmap = 'pointer0.xbm');
	
	its.gui.keyasshelp := 
	    its.widgetset.popuphelp(its.gui.keyassign,
				    hlp='Assign a key...',
				    txt= spaste('Click on this button with a '
						,'mouse key to assign that ',
						'mouse key to control of '
						,'annotations'));
	its.gui.toolbuttons := [=];
	its.gui.toolbuttonstate := [=];

	
	its.gui.images := ['dsmove.xbm' ,'dsarrow.xbm', 'dstext.xbm',
			   'dsrectangle.xbm', 'dssquare.xbm', 
			   'dspolyline.xbm', 'dspoly.xbm',
			   'dsellipse.xbm', 'dscircle.xbm',
			   'dsmarker.xbm'];
	
	its.gui.values := ['none', 'arrow', 'text', 'rectangle',
			   'square', 'polyline', 'polygon',
			   'ellipse', 'circle', 'marker'];
	
	its.gui.markerimages := ['markercircx.xbm','markersqr.xbm',  
				 'markercross.xbm','markerx.xbm',    
				 'markerdia.xbm',  'markercirc.xbm',
				 'markertri.xbm', 'markeritri.xbm',
				 'markerfcirc.xbm', 'markerfsqr.xbm', 
				 'markerfdia.xbm',   'markerftri.xbm', 
				 'markerfitri.xbm',  'markercircc.xbm'];
	
	# Loop to set up all the tool buttons...
	for (i in 1:len(its.gui.values)) {
	    tb := its.gui.values[i];
	    if (i==1) {
		# The move / edit button
		its.gui.toolbuttons[tb] := 
		    its.widgetset.button(its.gui.leftframe,
					 bitmap = its.gui.images[i],
					 value = tb);
	    } else {
		# The marker button (twodactionoption)
		if (i == 10) {
		    its.gui.toolbuttons[tb] := 
			twodactionoptionmenu(its.gui.toolframe,
					     images = its.gui.markerimages,
					     values = ['13', '4', '0', '1', 
						       '2', '3', '5', '6', 
						       '7', '8', '9',
						       '10', '11', '12'],
					     padx=0, pady=0, borderwidth=1, 
					     widgetset=its.widgetset, 
					     ncolumn=4, 
					     hlp='Select marker to use', 
					     hlp2=spaste('Clicking here will',
							 ' bring up a list ',
							 '(a pop up menu) of ',
							 'markers you can ',
							 'use. Select a ',
							 'marker, and then ',
							 'click on the ',
							 'displaypanel to ',
							 'draw the marker.'));
		    
		} else {
		    # One of the normal buttons
		    its.gui.toolbuttons[tb] := 
			its.widgetset.button(its.gui.toolframe,
					     bitmap = its.gui.images[i],
					     value = tb);
		    # NYId BUTTONS
	if (i == 4 || i == 5 || i ==9) { #|| i == 6 || i==7) {
			its.gui.toolbuttons[tb]->disable();
		    }

		    its.gui.tbhelp[tb] := 
			its.widgetset.popuphelp(its.gui.toolbuttons[tb], 
						hlp = spaste('Click to ',
							     'create a shape ',
							     '/ object'), 
						txt = spaste('Select a tool ',
							     'from the ',
							     'panel, and ',
							     'then click on ',
							     'the ',
							     'displaypanel ',
							     'to draw that ',
							     'object / shape')
						);
		}
	    }
	    its.gui.toolbuttonstate[tb] := F;
	}
	
	its.gui.movehelp := 
	    its.widgetset.popuphelp(its.gui.toolbuttons['none'],
				    hlp = 'Edit tool',
				    txt = spaste('Select this tool to move ',
						 '/ manipulate shapes that ',
						 'have already been created, ',
						 'and to cancel creation of ',
						 'a current shape. The ',
						 'control key also acts as ',
						 'a \'modifier\', which ',
						 'alters the action the mouse',
						 ' performs. Hold control and',
						 ' drag',
						 ' a handle to rotate a shape',
						 ', or hold control inside a',
						 ' shape and drag to scale ',
						 ' an object about its center',
						 ' \(not all shapes support',
						 ' this\)'));
	
	
	its.gui.deleteshape := its.widgetset.button(its.gui.leftframe, 
						    bitmap = 'delete.xbm');
	
	its.gui.delehelp := 
	    its.widgetset.popuphelp(its.gui.deleteshape,
				    hlp='Delete shape.',
				    txt=spaste('Click this button to delete',
					       ' the currently selected ',
					       'shape from the ',
					       'displaypanel.'));
	its.gui.deleteshape->foreground('red');
	
	############################################################
        ## WHENEVER SECTION                                       ##
        ############################################################
	whenever its.gui.canvas->select do {
	    # If a shape is selected, we care...
	    if (self.whichshape() != 0) {
		#Shape selected
		if ($value.value == 'pix') {
		    self.reverttopix(self.whichshape());
		} else if ($value.value == 'frac') {
		    if (!self.reverttofrac(self.whichshape())) {
			note(spaste('Couldn\'t change lock to rel. screen'),
			     priority ='WARN', origin = 'viewerannotations.g');
			its.updateoptions();
		    }
		} else if ($value.value == 'world') {
		    if (!self.locktowc(self.whichshape())) {
			note(spaste('Couldn\'t change lock to worldcanvas'),
			     priority ='WARN', origin = 'viewerannotations.g');
			its.updateoptions();
		    }
		}
	    } else {
		#Who cares, will be picked up on creation
	    }
	    
	} its.pushwhenever();
	
	for (i in 1:len(its.gui.values)) {
	    if (i == 10) {
		#Special case for the marker button
		whenever its.gui.toolbuttons[its.gui.values[10]]->changed do {
		    its.currentmarker := as_integer($value);
		    its.select('marker');
		} its.pushwhenever();

		whenever its.gui.toolbuttons[its.gui.values[10]]->same do {
		    if (its.gui.toolbuttonstate['marker']) {
			its.select('none');
			its.annot->cancel();
			its.updateoptions();
		    } else {
			its.currentmarker := as_integer($value);
			its.select('marker');
		    }
		} its.pushwhenever();
	    } else {
		whenever its.gui.toolbuttons[its.gui.values[i]]->press do {
		    its.select($value);
		} its.pushwhenever();
	    }
	}
	
	#Save / load
	whenever its.gui.save->press do {
	    self.saveoptions(its.gui.savename.get());
	} its.pushwhenever();
	
	whenever its.gui.restore->press do {
	    self.restoreoptions(its.gui.savename.get());
	} its.pushwhenever();

	# Listen for done of our displaypanel
	whenever its.displaypanel->done do {
	    self.done();
	} its.pushwhenever();
	
	
	# Delete Button
	whenever its.gui.deleteshape->press do {
	    self.deleteshape(self.whichshape());
	    its.select('none');
	    its.updateoptions();
	} its.pushwhenever();

	# Dismiss Button
	whenever its.gui.dismiss->press do {
	    its.dismiss();
	} its.pushwhenever();

	#Binds for assignment key;
	its.gui.keyassign->bind('<ButtonRelease-1>', '1');
	its.gui.keyassign->bind('<ButtonRelease-2>', '2');
	its.gui.keyassign->bind('<ButtonRelease-3>', '3');

	# Key assignment
	whenever its.gui.keyassign->["1 2 3"] do {
	    if (as_integer($name) != its.currentkey) {
		its.displaypanel.viewer().toolkit().toolkitchange(
					 [tool='Annotations', 
				      key=spaste('Button ', $name)]);
		its.currentkey := as_integer($name);
	    }
	    
	    if ($name == '1') its.gui.keyassign->bitmap("pointer1.xbm");
	    else if ($name == '2') its.gui.keyassign->bitmap("pointer2.xbm");
	    else if ($name == '3') its.gui.keyassign->bitmap("pointer3.xbm");
	} its.pushwhenever();

	# Change of options via multi-gui
	whenever its.gui.multigui->setoptions do {
	    for (i in field_names($value)) {
		self.setshapeoptions(self.whichshape(), $value[i]);
	    }
	} its.pushwhenever();
	

	# Event from C++ / user mouse movements
	whenever its.annot->annotevent do {

	    if ($value.desc == 'endchange') {
		its.select('none');
		its.updateoptions();
	    }
	    
	    if ($value.desc == 'deselect' || $value.desc == 'newselection') 
		its.updateoptions();
	    
	    if ($value.desc == 'worldfail') {
		note(spaste('Couldn\'t lock shape onto a worldcanvas.. shape ',
			    'has been scrapped, sorry. Try using relative ',
			    'screen positions to lock the shape'),
		     priority='WARN', 
		     origin='viewerannotations.g');
		its.select('none');
	    }
	    
	    #if ($value.desc == 'noconvert') {
	    #	note(spaste('Couldn\'t convert the shape',
	    #		    ' to requested co-ordinates.'),
	    #	     priority='WARN', 
	    #	     origin='viewerannotations.g');
	    #	
	    #    }
	} its.pushwhenever();
	
	its.widgetset.tk_release();
    }
    
    #################
    ## MISC FNS
    ##################
    self.print := function(paneldisplay) {
	wider its;
	
	if (len(self.getalloptions()) > 0) {
	    self.disable();
	    
	    note('Adding annotations to print out...',
		 priority='NORMAL', 
		 origin='viewerannotations.g');
	    
	    if (!is_agent(paneldisplay)) 
		return throw(spaste('Bad argument passed to ',
				    'viewerannotations::print!'));
	    
	    its.printer := its.widgetset.annotations(paneldisplay);

	    if (is_fail(its.printer)) 
		return throw(spaste('Error printing annotations!!! ',
				    its.printer));
	    
	    its.tmp := its.printer->setalloptions(its.annot->getalloptions());
	    if (is_fail(its.tmp)) {
		val its.printer := F;
		self.enable();
		return throw(spaste('Error printing annotations!!! ',
				    its.printer));
	    } else {
		
		val its.printer := F;
		
		note('Annotations added to print out.',
		     priority='NORMAL', 
		     origin='viewerannotations.g');
	    }
	    self.enable();
	}
	
	return T;
    }
    
    #Change type of annotation on the fly
    self.reverttofrac := function(whichshape = F) {
	wider its;

	if (is_boolean(whichshape)) {
	    if (self.whichshape != 0)
		whichshape := self.whichshape();
	    else return F;
	}
	
	its.annot->reverttofrac(whichshape - 1);
	return T;
    }
    
    self.reverttopix := function (whichshape = F) {
	wider its;
	
	if (is_boolean(whichshape)) {
	    if (self.whichshape != 0)
		whichshape := self.whichshape();
	    else return F;
	}
	
	its.annot->reverttopix(whichshape - 1);
	return T;
    }
    
    self.locktowc := function (whichshape = F) {
	wider its;

	if (is_boolean(whichshape)) {
	    if (self.whichshape != 0)
		whichshape := self.whichshape();
	    else return F;
	}
	
	return its.annot->locktowc(whichshape - 1);
    }

    its.handlecreate := function(newtype) {
	wider its;
	# I should gather all settings
	shapeoptions := [=];
	shapeoptions.type := newtype;
	shapeoptions.coords := its.gui.canvas.getvalue();

	if (newtype == 'marker') 
	    shapeoptions.markerstyle := its.currentmarker;
	
	self.createshape(shapeoptions);
    }
    
    its.select := function(newvalue) {
	
	wider its;
	if (its.gui.toolbuttonstate[newvalue]) {
	    #The button was down and is NOW up

	    if (newvalue != 'none') {
		its.gui.toolbuttonstate[newvalue] := F;
		if (newvalue != 'marker') {
		    if (is_agent(its.gui.toolbuttons[newvalue])) {
			its.gui.toolbuttons[newvalue]->relief('raised');
		    }
		}
		
		# Cancel the creation (C++ level)
		its.annot->cancel();
		its.gui.toolbuttonstate['none'] := T;
		
		if (is_agent(its.gui.toolbuttons['none'])) {
		    its.gui.toolbuttons['none']->relief('sunken');
		}
	    } 
	} else {
	    #The button was up and NOW down

	    if (newvalue != 'none') {
		its.mystate.state := 'creation';
	    } else {
		its.mystate.state := 'moving';
	    }

	    its.gui.toolbuttonstate[newvalue] := T;
	    
	    if (newvalue == 'marker') { 
		if (is_agent(its.gui.toolbuttons[newvalue])) {
		    its.gui.toolbuttons[newvalue].sunken();
		}
	    } else {
		if (is_agent(its.gui.toolbuttons[newvalue])) {
		    its.gui.toolbuttons[newvalue]->relief('sunken');
		}
	    }
	    
	    # Check we are the only one
	    for (i in its.gui.values) {
		if(its.gui.toolbuttonstate[i] && i != newvalue) {
		    {
			if (i != 'marker') {
			    if (is_agent(its.gui.toolbuttons[i])) {
				its.gui.toolbuttons[i]->relief('raised');
				if(i != 'none') {
				    #ok, a shape was being created
				    #print "GLISH - Calling cancel";
				    #its.annot->cancel();
				}
			    }
			} else  {
			    if (is_agent(its.gui.toolbuttons[i])) {
				its.gui.toolbuttons[i].raised();
			    }
			}
			its.gui.toolbuttonstate[i] := F;
		    }
		}
	    }
	    
	    if (newvalue != 'none') {
		its.handlecreate(newvalue);
	    }

	    its.updateoptions();
	}
    }


    its.nokey := function() {
	wider its;
	if (is_agent(its.gui.keyassign)) {
	    its.gui.keyassign->bitmap("pointer0.xbm");
	}
    }

    its.nooptions := function() {
	wider its;
	if (is_agent(its.gui.markerframe))
	    its.gui.markerframe->unmap();
	if (is_agent(its.gui.multigui))
	    its.gui.multigui.shownone(); 
	if (is_agent(its.gui.canvas)) 
	    its.gui.canvas.selectvalue('frac');
	its.heading("None");
    }
    
    its.heading := function(text) {
	wider its;
	its.widgetset.tk_hold();
	if (is_agent(its.gui.optionlabel)) 
	    its.gui.optionlabel->text(spaste('Showing options for : ', text));
	its.widgetset.tk_release();
    }

    its.updateoptions := function() {
	wider its;
	its.widgetset.tk_hold();

	if (self.whichshape() == 0) {  #Nothing selected
	    its.nooptions();
	} else {
	    currentshape := self.getshapeoptions(self.whichshape());

	    if (is_fail(currentshape)) {
		note(spaste('There was an error trying to retrieve the ',
			    'options for the current shape : ', 
			    currentshape), priority = 'WARN');
		return F;
	    }
	    
	    if (!has_field(currentshape, 'type')) {
		return throw(spaste('Bad option record returned for ',
				    'requested shape; no \'type\' field!'));
	    }

	    type := currentshape.type;
	    
	    if (is_agent(its.gui.canvas)) {
		if (!has_field(currentshape, 'coords'))
		    return throw(spaste('Bad option record returned for ',
					'requested shape; no \'coords\' ',
					'field!'));

		its.gui.canvas.selectvalue(currentshape.coords);
	    }	    
	    
	    if (is_agent(its.gui.markerframe)) {
		if (type == 'marker') {
		    its.gui.markerframe->map();
		} else its.gui.markerframe->unmap();
	    }

	    if (its.mystate.state == 'creation') 
	      its.heading(spaste(type, ' (Creating)'));
	    else its.heading(spaste(type, ' (Modifying)'));

	    newoptions := [=];
	    newoptions[type] := currentshape;
	    its.gui.multigui.fillgui(newoptions);
	    its.gui.multigui.show(type);
	}
	its.widgetset.tk_release();	
    }
    
    ############################################################
    ## WRAPPER / PUBLIC FUNCTIONS                             ##
    ############################################################

    self.cshape := function() {
	return its.annot->cshape();
    }

    
    
    self.enable := function() {
	wider its;
	
	if (is_agent(its.gui.mainframe)) 
	    its.gui.mainframe->enable();

	its.annot->enable();
	return T;
    }

    self.draw := function(pixelcan, handles = F) {
	if (!is_agent(pixelcan))
	    return throw('Bad agent');
	its.annot->draw(pixelcan, handles);

    }

    self.disable := function() {
	wider its;
	if (is_agent(its.gui.mainframe)) 
	    its.gui.mainframe->disable();
	
	its.annot->disable();
	
	return T;
    }

    self.deleteshape := function(index) {
	wider its;
	if (index >= 1)
	    its.annot->deleteshape(index - 1);
	else throw(spaste('Bad shape index in call to deteleshape'));
    }

    self.whichshape := function() {
	wider its;
	return (its.annot->whichshape() + 1);
    }
    
    self.createshape := function(shapesettings) {
	wider its;
	
	# If the user has specifically requested to create a shape with
	# a certaing type (abs, frac or world), that's what they get...
	# if not, frac I guess is the default
	
	if (!has_field(shapesettings, 'coords')) {
	    note(spaste('No \'coords\' field found. \'coords\' specifies',
			' the way the shape will be positioned (world, pix,',
			' or frac). Defaulting to \'frac\''),
		 priority = 'WARN', origin = 'viewerannotations.g');
	    shapesettings.coords := 'frac';
	}
	
	its.tmp := its.annot->createshape(shapesettings);
	
	if (is_fail(its.tmp)) {
	    its.select('none');
	    note(spaste('There was an error making a new shape : ', 
			its.tmp), priority = 'WARN', 
		 origin = 'viewerannotations.g');
	}
	return T;
    }	
    
    

    self.newshape := function(shapesettings) {
	wider its;
	makeworld := F;
	
	if (!has_field(shapesettings, "coords")) {
	    for (i in field_names(shapesettings)) {
		if (has_field(shapesettings[i], "units")) {
		    if (shapesettings[i].units == 'pix') {
			shapesettings.coords := 'pix';
		    } else if (shapesettings[i].units == 'frac') {
			shapesettings.coords := 'frac';
		    } else {
			shapesettings.coords := 'world';
		    }
		}
	    }
	    
	}
	
	its.tmp := its.annot->newshape(shapesettings);
	
	if (is_fail(its.tmp)) {
	    its.select('none');
	    note(spaste('There was an error making a new shape : ', 
			its.tmp), prority = 'WARN', 
		 origin = 'viewerannotations.g');
	    return F;
	}
	
	return T;
    }

    self.availableshapes := function() {
	wider its;
	# This is a temporary measure. This will move to lower levels
	# shapes := "square rectangle circle arrow marker text";
	return its.annot->availableshapes();#shapes;
    }

    self.setkey := function(newkeysym) {
	wider its;
	if (newkeysym == 0) {
	    its.currentkey := 0;
	    its.nokey();
	    its.annot->setkey(newkeysym);
	} else if (newkeysym == Display::K_Pointer_Button1 ||
		   newkeysym == Display::K_Pointer_Button2 ||
		   newkeysym == Display::K_Pointer_Button3) {
	    its.annot->setkey(newkeysym);
	    
	    
	    if (newkeysym == Display::K_Pointer_Button1) {
		its.currentkey := 1;
		if (is_agent(its.gui.keyassign)) {
		    its.gui.keyassign->bitmap("pointer1.xbm");
		}
	    } else if (newkeysym == Display::K_Pointer_Button2) {
		its.currentkey := 2;
		if (is_agent(its.gui.keyassign)) {
		    its.gui.keyassign->bitmap("pointer2.xbm");
		}
	    } else if (newkeysym == Display::K_Pointer_Button3) {
		its.currentkey := 3;
		if (is_agent(its.gui.keyassign)) {
		    its.gui.keyassign->bitmap("pointer3.xbm");
		}
	    }
	}
	return T;
    }
    
    self.getalloptions := function() {
	wider its;
	return its.annot->getalloptions();
    }

    self.setalloptions := function(alloptions) {
	wider its;
	if (!is_agent(its.annot)) 
	    return (throw("Can't set all options - problem"));

	its.annot->setalloptions(alloptions);
	return T;
    }

    self.getshapeoptions := function(whichshape) {
	wider its;
	return its.annot->getshapeoptions(whichshape - 1);
    }

    self.setshapeoptions := function(whichshape, whatsettings) {
	wider its;
	its.annot->setshapeoptions(whichshape - 1, whatsettings);
    }

    self.addlockedtocurrent := function(lockeditem) {
	wider its;
	its.annot->addlockedtocurrent(lockeditem - 1);
    }
    
    self.removelockedfromcurrent := function(lockedtoremove) {
	wider its;
	its.annot->removelockedfromcurrent(lockedtoremove - 1);
    }

    self.saveoptions := function(name) {
	t := eval('include \'inputsmanager.g\'');
	t := self.getalloptions();
	rec := [=];
	for (i in field_names(t)) {
	    if (has_field(t[1], 'value')) {
		rec[i] := t[i].value;
	    } else {
		rec[i] := t[i];
	    }
	}
	return inputs.savevalues('viewerannotations', name, rec);
    }
    
    self.restoreoptions := function(name) {
	t := eval('include \'inputsmanager.g\'');
	t := inputs.getvalues('viewerannotations', name);
	if (len(field_names(t)) > 0) {
	    return self.setalloptions(t);
	} else {
	    note('No inputs found for given name');
	    return F;
	}
	return T;
    }

    
    return T;

} # End sub














