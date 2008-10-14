pragma include once

include 'widgetserver.g'
include 'note.g'

const twodactionoptionmenu := subsequence (ref parent, names="", 
					   values="", images="", 
					   ncolumn=3,
					   hlp='', hlp2='', padx=2, 
					   pady=2,
					   borderwidth=2,
					   widgetset=dws)
{
    if (!is_agent(parent)) {
	return throw ('Variable "parent" must be an agent', 
		      origin='optionmenu');
    }

    its := [=];
    its.empty := T;
    its.menu := [=];           # Menu
    its.data := [=];           # labels, names, values
    its.gui := [=];
    its.isEnabled := T;
    its.framemapped := F;
    its.usepics := F;
    its.hlp := hlp;
    its.hlp2 := hlp2;


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


    ##########
    ## BUILD THE PRIMARY BUTTON
    ##########

    its.buildbutton := function() {
	wider its;

	# Check values

	if ((len(its.data.images) <=0) && (len(its.data.names) <=0))
	    return throw(spaste('Cannot build menu with 0 elements. ',
				'Either supply at least one image or at',
				' least one name'), 
			 origin = 'twodactionoptionmenu');

	if (len(its.data.images) >= len(its.data.names)) 
	    its.usepics := T;
	else its.usepics := F;

	if (its.usepics) {
	    if (len(its.data.images) != len(its.data.values))
		return throw(spaste('When using images, number of elements ',
				    'in images must equal number in values.'),
			     origin = 'twodactionoptionmenu');
	    
	} else {
	    if (len(its.data.names) != len(its.data.values))
		return throw(spaste('When using names, number of elements ',
				    'in names must equal number in values.'),
			     origin = 'twodactionoptionmenu');

	}

	## Create the button

	if (its.usepics) {
	    its.gui.mainbutton := 
			its.widgetset.button(its.gui.parent,
					     bitmap = its.data.images[1]);

	    its.gui.buttonhelp := 
		its.widgetset.popuphelp(its.gui.mainbutton, 
					hlp = its.hlp, txt = its.hlp2);

	    if (is_fail(its.gui.mainbutton)) 
		return throw(spaste('twodactionoptiomenu.g - Couldn\'t ', 
				    'make my main button'));
	
	} else {
	    its.gui.mainbutton := 
		its.widgetset.button(its.gui.parent,
				     text = its.data.names[1]);

	    its.gui.buttonhelp := 
		its.widgetset.popuphelp(its.gui.mainbutton, 
					hlp = its.hlp, txt = its.hlp2);
	    
	    if (is_fail(its.gui.mainbutton)) 
		return throw(spaste('twodactionoptiomenu.g - Couldn\'t make ',
			     'my main button'));

	} 

	## Opening and closing of pop up frame

	whenever its.gui.mainbutton->press do {
	    if (its.framemapped) {
		its.gui.popup->unmap();
		its.framemapped := F;
	    } else {
		its.gui.popup->map();
		its.framemapped := T;
	    }		
	} its.pushwhenever();
    }

    ##########
    ## BUILD THE SUB MENU (POP UP FRAME)
    ##########


    its.buildsubmenu := function() {
	wider its;

	its.widgetset.tk_hold();
	
	its.gui.popup := its.widgetset.frame(tlead = its.gui.mainbutton, 
					     side = 'top', padx=its.padx,
					     pady=its.pady,
					     borderwidth=its.borderwidth);
	numberadded := 0;
	currentframe := 1;
	
	its.gui.frames[paste(currentframe)] := 
	    its.widgetset.frame(its.gui.popup,
				side = 'left',padx=its.padx,
					     pady=its.pady,
					     borderwidth=its.borderwidth);
	
	if (its.usepics) {
	    
	    # Add all the pictures

	    for (i in 1:len(its.data.images)) {
		its.gui.buttons[paste(i)] := 
		    its.widgetset.button(its.gui.frames[paste(currentframe)],
					 value=i,
					 bitmap=its.data.images[i], 
					 padx=its.padx, pady=its.pady,
					 borderwidth=its.borderwidth);
		
		numberadded := numberadded+1;

		if (numberadded % its.gui.ncol==0 && 
		    numberadded!=len(its.data.images)) {
		    currentframe := currentframe+1;
		    its.gui.frames[paste(currentframe)] := 
			its.widgetset.frame(its.gui.popup,
					    side = 'left',padx=its.padx,
					    pady=its.pady,
					    borderwidth=its.borderwidth);
		}
	    }
	} else {

	    # Add all the text buttons

	    for (i in 1:len(its.data.names)) {
		its.gui.buttons[paste(i)] :=
		    its.widgetset.button(its.gui.frames[paste(currentframe)], 
					 text=its.data.names[i], 
					 value=(i),
					 padx=its.padx, pady=its.pady,
					 borderwidth=its.borderwidth);
		
		numberadded := numberadded+1;
		
		if (numberadded % its.gui.ncol==0 && 
		    numberadded!=len(its.data.names)) {
		    currentframe := currentframe+1;
		    its.gui.frames[paste(currentframe)] := 
			its.widgetset.frame(its.gui.popup,
					    side = 'left',padx=its.padx,
					    pady=its.pady,
					    borderwidth=its.borderwidth);
		}
	    }
	}
	

	#Start unmapped;
	its.gui.popup->unmap();
	its.widgetset.tk_release();
	
	for (i in 1:len(its.gui.buttons)) {
	    whenever its.gui.buttons[paste(i)]->press do {
		self.newselection($value);
	    } its.pushwhenever();
	}

    
    }    

    self.currentvalue := function() {
	wider its;
	return its.data.values[its.data.currentselection];
    }

    self.raised := function () {
	wider its;
	if (is_agent(its.gui.mainbutton)) its.gui.mainbutton->relief('raised');
    }

    self.sunken := function() {
	wider its;
	if (is_agent(its.gui.mainbutton)) its.gui.mainbutton->relief('sunken');
    }

    self.newselection := function(index) {
	wider its;
	its.gui.popup->unmap();
	its.framemapped := F;

	if (its.data.currentselection != index) {
	    its.data.currentselection := index;
	    if (index > (len(its.data.values)))
		return throw('Bad selection in twodactionoption');
	    else {
		if (its.usepics) {
		    its.gui.mainbutton->bitmap(its.data.images[index]);
		} else {
		    its.gui.mainbutton->text(its.data.names[index]);
		}
	    }
	    self->changed(its.data.values[index]);  
	    
	} else self->same(its.data.values[index]);
	
    }

    ##########
    ## DONE / DISMISS
    ##########

    self.dismiss := function() {
	if (is_agent(its.gui.popup)) 
	    if (its.framemapped) its.popup->unmap();

	if (is_agent(its.gui.mainbutton))
	{}
	    
    }

    self.done := function() {
	wider its;
	if (is_agent(its.gui.popup)) 
	    if (its.framemapped) its.popup->unmap();

	its.deactivate(len(its.whenevers));
	its := F;
    }

    # Constructor / Store params
    its.data.currentselection := 1;
    its.data.values := values;
    its.data.images := images;
    its.data.names := names;
    
    its.gui.parent := parent;
    its.gui.ncol := ncolumn;
    its.widgetset := widgetset;
 
    its.pady := pady;
    its.padx := padx;
    its.borderwidth := borderwidth;

    its.buildbutton();
    its.buildsubmenu();

    return T;
}








const twodtest := function() {
    
    f := frame();
    g := twodactionoptionmenu(f, 
			      values="1 2 3 4 5 6 7", 
			      names = "", 
			      images = "spanner.xbm spanner.xbm spanner.xbm spanner.xbm spanner.xbm spanner.xbm spanner.xbm");
    
    whenever g->* do {
	print "Name: " , $name;
	print "Value: ", $value;
    }
}

