# dishentries.g: various compound tk widgets used as entry fields in the sdbrowser
#------------------------------------------------------------------------------
#   Copyright (C) 1997,1998,1999,2000,2001
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
#    $Id: dishentries.g,v 19.1 2004/08/25 01:09:49 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include "measures.g";
include 'popuphelp.g';
include 'note.g';
include 'widgetserver.g';

# expandable in x, this has a label followed by an entry field containing the
# initialValueString (which must be a string).  It is placed in the baseFrame.
# The entry is currently always disabled although eventually it is
# expected that a return callback will be specified to handle cases where the
# user alters the entry when it is enabled.  The text justification is
# is left by default.  hlp, txt, and combi are the corresponding popuphelp
# values.  If both hlp and txt are F, popuphelp is never called.
const labeledEntry := function(baseFrame, theLabel, initialValueString, pad=T, 
			       labelWidth=F, entryWidth=F, justify='left',
			       hlp=F, txt=F, combi=F, widgetset=dws)
{
    if (!is_string(initialValueString) || !is_string(theLabel) || !is_agent(baseFrame)) fail;

    self := [=];
    self.disabled := T;

    self.outerFrame := widgetset.frame(baseFrame,side='left',borderwidth=0,
				       expand='x')
    self.frame := widgetset.frame(self.outerFrame,side='left',borderwidth=0,
				  expand='none');
    if (is_integer(labelWidth)) 
	self.label := widgetset.label(self.frame, theLabel,width=labelWidth);
    else self.label := widgetset.label(self.frame, theLabel);
    self.fixedEntryWidth := is_integer(entryWidth);
    if (self.fixedEntryWidth) 
	self.entry := widgetset.entry(self.frame, justify=justify,
				      disabled=T, width=entryWidth);
    else self.entry := widgetset.entry(self.frame, justify=justify,
				       disabled=T);
    if (pad) self.pad := widgetset.frame(self.outerFrame,borderwidth=0,height=2,width=0,
					 expand='x');

    if (is_string(hlp) || is_string(txt)) {
	popuphelp(self.label,hlp=hlp,txt=txt,combi=combi);
    }

    self.setEntry := function(value) 
    {
	if (self.disabled) self.entry->disabled(F);
	self.entry->delete("start","end");
	if (!self.fixedEntryWidth) {
	    len := max(strlen(value),2);
	    self.entry->width(len+1);
	}
	self.entry->insert(value);
	if (self.disabled) self.entry->disabled(T);
    }
    self.setEntry(initialValueString);

    public := [=];

    public.setValue := function(newValue) { 
	wider self; 
	if (len(newValue) == 0) newValue := '';
	if (!is_string(newValue)) newValue := as_string(newValue);
	curValue := self.entry->get();
	if (len(curValue) == 0) curValue := '';
	if (newValue == curValue) return;
	self.setEntry(newValue);
    }
    public.getValue := function() { wider self; return self.entry->get();}

    public.setLabel := function(theLabel) { wider self; self.label->text(theLabel);}

    # this changes the appearance AND entries disabled status
    public.disabledAppearance := function(tOrF)
    {
	wider self;
	if (tOrF) {
	    self.label->foreground('grey60');
	    self.entry->background('lightgrey');
	    self.entry->foreground('grey60');
	} else {
	    self.label->foreground('black');
	    self.entry->background('white');
	    self.entry->foreground('black');
	}
	self.entry->disabled(tOrF);
	self.disabled := tOrF;
    }

    # this only changes the disabled status
    public.disabled := function(tOrF)
    {
	wider self;
	self.entry->disabled(tOrF);
	self.disabled := tOrF;
    }

#    public.self := function() { wider self; return self;}
    
    return public;
}

# has a labeledEntry with a label after the entry field to be used as a unit identifier
const labeledEntryWithUnits := function(baseFrame, theLabel, initialValueString, unitString, pad=T,
					labelWidth=F, entryWidth=F, unitsWidth=F, justify='left',
					hlp=F, txt=F, combi=F, widgetset=dws)
{
    # most arguments will be checked in labeledEntry call
    if (!is_string(unitString)) fail;

    self := [=];

    self.outerFrame := widgetset.frame(baseFrame,side='left',borderwidth=0,
				 expand='x')
    self.frame := widgetset.frame(self.outerFrame,side='left',borderwidth=0,
			    expand='none');
    self.labeledEntry := labeledEntry(self.frame, theLabel, initialValueString,F,
				      labelWidth,entryWidth, justify, hlp, txt, combi,
				      widgetset=widgetset);
    if (is_integer(unitsWidth)) 
	self.units := widgetset.label(self.frame,unitString,width=unitsWidth);
    else self.units := widgetset.label(self.frame,unitString);
    if (pad) self.pad := widgetset.frame(self.outerFrame,borderwidth=0,height=0,
				   width=0,expand='x');

    public := [=];

    public.getValue := function() { 
	wider self; 
	return self.labeledEntry.getValue();
    }
    public.setValue := function(newValue) { 
	wider self; 
	return self.labeledEntry.setValue(newValue);
    }
    
    public.setLabel := function(theLabel) { wider self; self.labeledEntry.setLabel(theLabel);}

    public.setUnits := function(theUnits) { wider self; self.units->text(theUnits);}

    # this changes the appearance AND entries disabled status
    public.disabledAppearance := function(tOrF)
    {
	wider self;
	if (tOrF) {
	    self.units->foreground('grey60');
	} else {
	    self.units->foreground('black');
	}
	self.labeledEntry.disabledAppearance(tOrF);
    }

    # this only changes the disabled status
    public.disabled := function(tOrF)
    {
	wider self;
	self.labeledEntry.disabled(tOrF);
    }

    return public;
}

# has a labeledEntry with a Menu following.  The menu items are
# those in menuList.  The label of the menu button is 
# initially menList[initialMenuItem].  As a menu button is
# pressed, the label changes to be identical to that button
# and the name of that button is passed as the only argument
# to the buttonPressCallback function.  This function could
# then be used to modify the entry value appropriately.

const labeledEntryWithMenu := function(baseFrame, theLabel, initialValueString, menuList, initialMenuItem,
				       buttonPressCallback, pad=T, labelWidth=F, entryWidth=F, 
				       justify='left', widgetset=dws)
{
    # arguments not checked here will be checked in labeledEntry call
    if ((len(menuList) == 0) || 
	!is_string(menuList[1]) || 
	!is_integer(initialMenuItem) ||
	(initialMenuItem < 1) ||
	(initialMenuItem > len(menuList)) || 
	!is_function(buttonPressCallback)) 
	fail;

    self := [=];

    self.outerFrame := widgetset.frame(baseFrame,side='left',borderwidth=0,expand='x')
    self.frame := widgetset.frame(self.outerFrame,side='left',borderwidth=0,expand='none');
    self.labeledEntry := labeledEntry(self.frame, theLabel, initialValueString,F,
				      labelWidth,entryWidth, justify, widgetset=widgetset);
    self.menuWidth := 1;
    for (i in menuList) {
	self.menuWidth := max(self.menuWidth,strlen(i));
    }
    self.menuButton := widgetset.button(self.frame,menuList[initialMenuItem],type='menu',
				  width=self.menuWidth, relief='groove');
    if (pad) self.pad := widgetset.frame(self.outerFrame,borderwidth=0,height=0,width=0,
				   expand='x');

    self.buttonPressCallback := buttonPressCallback;

    self.pressCallback := function(name) {
	wider self;
	if (self.buttonPressCallback(name))
	    self.menuButton->text(name);
    }
    self.buttons := [=];
    self.setMenuButtons := function(buttonLabels)
    {
	wider self;
	for (i in field_names(self.buttons)) self.buttons[i] := F;
	self.buttons := [=];
	for (i in buttonLabels) {
	    self.buttons[i] := widgetset.button(self.menuButton, text=i, value=i);
	    whenever self.buttons[i]->press do {self.pressCallback($value); }
	}
    }
    self.setMenuButtons(menuList);

    public := [=];

    public.getValue := function() { 
	wider self; 
	return self.labeledEntry.getValue();
    }

    public.setValue := function(newValue) { 
	wider self; 
	return self.labeledEntry.setValue(newValue);
    }

    public.setLabel := function(theLabel) { wider self; self.labeledEntry.setLabel(theLabel);}

    public.setMenuLabel := function(newLabel) {
	wider self;
	if (!is_string(newLabel)) fail;

	self.menuButton->text(newLabel);
    }

    public.setMenuButtons := function(newButtonLabels)
    { 
	wider self; 
	menuWidth := 0;
	for (i in newButtonLabels) {
	    menuWidth := max(strlen(i),menuWidth);
	}
	if (menuWidth > self.menuWidth) {
	    self.menuWidth := menuWidth;
	    self.menuButton->width(menuWidth);
	}
	self.setMenuButtons(newButtonLabels); 
    }
    
    return public;
}

# like a labeledEntry but the label is a menu.  The menu items are
# those in menuList.  The label retains the same string throughout.
# As a menu button is the name of that button is passed as the 
# only argument to the buttonPressCallback function.  This function 
# could then be used to modify the entry value appropriately.
# There appears to be no way to modify the justification of text in
# a menu.

const menuEntry := function(baseFrame, theLabel, initialValueString, menuList, buttonPressCallback, pad=T,
			    labelWidth=F, entryWidth=F, widgetset=dws)
{
    if (!is_string(initialValueString) || !is_string(theLabel) || !is_agent(baseFrame) ||
	(len(menuList) == 0) || !is_string(menuList[1]) || 
	!is_function(buttonPressCallback)) 
	fail;

    self := [=];
    self.value := initialValueString;
    self.disabled := T;

    self.outerFrame := widgetset.frame(baseFrame,side='left',borderwidth=0,expand='x')
    self.frame := widgetset.frame(self.outerFrame,side='left',borderwidth=0,expand='none');
    if (is_integer(labelWidth)) 
	self.labelMenu := widgetset.button(self.frame,theLabel,type='menu',width=labelWidth, relief='groove');
    else self.labelMenu := widgetset.button(self.frame,theLabel,type='menu', relief='groove');
    if (pad) self.pad := widgetset.frame(self.outerFrame,borderwidth=0,height=0,width=0,expand='x');

    self.buttonPressCallback := buttonPressCallback;

    self.buttons := [=];
    self.setMenuButtons := function(buttonLabels)
    {
	wider self;
	for (i in field_names(self.buttons)) self.buttons[i] := F;
	self.buttons := [=];
	for (i in buttonLabels) {
	    self.buttons[i] := widgetset.button(self.labelMenu,text=i,value=i);
	    whenever self.buttons[i]->press do { self.buttonPressCallback($value);}
	}
    }
    self.setMenuButtons(menuList);
    self.fixedEntryWidth := is_integer(entryWidth);
    if (self.fixedEntryWidth) 
	self.entry := widgetset.entry(self.frame, disabled=T, width=entryWidth);
    else 
	self.entry := widgetset.entry(self.frame, disabled=T);

    self.setEntry := function()
    {
	if (self.disabled) self.entry->disabled(F);
	self.entry->delete("start","end");
	if (!self.fixedEntryWidth) {
	    len := max(strlen(self.value),2);
	    self.entry->width(len+1);
	}
	self.entry->insert(self.value);
	if (self.disabled) self.entry->disabled(T);
    }
    self.setEntry();

    public := [=];

    public.setValue := function(newValue) { 
	wider self; 
	if (newValue == self.value) return;
	if (!is_string(newValue)) fail;
	self.value := newValue;
	self.setEntry();
    }

    public.getValue := function() { wider self; return self.value;}

    public.setMenuLabel := function(newLabel) {
	wider self;
	if (!is_string(newLabel)) fail;

	self.labelMenu->text(newLabel);
    }
        
    public.setMenuButtons := function(newButtonLabels)
    { wider self; self.setMenuButtons(newButtonLabels); }
    
    return public;
}

# has a menuEntry with a named Menu following.  The second
# menu items are those in secondMenuList.  The label of the menu button is 
# initially secondMenuList[initialMenuItem].  As a second menu button is
# pressed, the second menu label changes to be identical to that button
# and the name of that button is passed as the only argument
# to the secondButtonPressCallback function.  This function could
# then be used to modify the entry value appropriately.
# There appears to be no way to modify the justification of text
# within a menu.

const menuEntryWithMenu := function(baseFrame, theLabel, initialValueString, menuList, buttonPressCallback,
				    secondMenuList, initialMenuItem, secondButtonPressCallback, pad=T,
				    labelWidth=F, entryWidth=F, widgetset=dws)
{
    # arguments not checked here will be checked in the manuEntry call
    if ((len(secondMenuList) == 0) || 
	!is_string(secondMenuList[1]) || 
	!is_integer(initialMenuItem) ||
	(initialMenuItem < 1) ||
	(initialMenuItem > len(secondMenuList)) || 
	!is_function(secondButtonPressCallback)) 
	fail;

    self := [=];

    self.outerFrame := widgetset.frame(baseFrame,side='left',borderwidth=0,expand='x')
    self.frame := widgetset.frame(self.outerFrame,side='left',borderwidth=0,expand='none');
    self.menuEntry := menuEntry(self.frame, theLabel, initialValueString, menuList, buttonPressCallback, F,
				labelWidth, entryWidth, widgetset=dws);
    self.menuWidth := 1;
    for (i in secondMenuList) {
	self.menuWidth := max(self.menuWidth, strlen(i));
    }
    self.secondMenuButton := 
	widgetset.button(self.frame,secondMenuList[initialMenuItem],type='menu',
		   width=self.menuWidth,relief='groove');
    if (pad) self.pad := widgetset.frame(self.outerFrame,borderwidth=0,height=0,width=0,expand='x');
    self.secondButtonPressCallback := secondButtonPressCallback;

    self.pressCallback := function(name) {
	wider self;
	if (self.secondButtonPressCallback(name))
	    self.secondMenuButton->text(name);
    }
    self.buttons := [=];
    self.setSecondMenuButtons := function(buttonLabels)
    {
	wider self;
	for (i in field_names(self.buttons)) self.buttons[i] := F;
	self.buttons := [=];
	for (i in buttonLabels) {
	    self.buttons[i] := widgetset.button(self.secondMenuButton,text=i,value=i);
	    whenever self.buttons[i]->press do { self.pressCallback($value);}
	}
    }
    self.setSecondMenuButtons(secondMenuList);

    public := [=];

    public.getValue := function() { 
	wider self; 
	return self.menuEntry.getValue();
    }
    
    public.setValue := function(newValue) { 
	wider self; 
	return self.menuEntry.setValue(newValue);
    }

    public.setMenuLabel := function(newLabel) {
	wider self;
	return self.menuEntry.setMenuLabel(newLabel);
    }

    public.setSecondMenuLabel := function(newLabel) {
	wider self;
	if (!is_string(newLabel)) fail;

	self.secondMenuButton->text(newLabel);
    }

    public.setMenuButtons := function(newButtonLabels)
    { wider self; return self.menuEntry.setMenuButtons(newButtonLabels); }

    public.setSecondMenuButtons := function(newButtonLabels)
    { 
	wider self; 
	menuWidth := 0;
	for (i in newButtonLabels) {
	    menuWidth := max(strlen(i),menuWidth);
	}
	if (menuWidth > self.menuWidth) {
	    self.menuWidth := menuWidth;
	    self.secondMenuButton->width(menuWidth);
	}
	self.setSecondMenuButtons(newButtonLabels); 
    }
    
#    public.self := function() { wider self; return self;}
        
    return public;
}

const epochEntry := function(baseFrame, theLabel, initialTime, initialDisplay, pad=T,
			     widgetset=dws)
{
    if (!is_string(initialDisplay)) fail;

    self := [=];
    self.epoch := initialTime;
    self.displayString := "garbage";
    self.displayType := "garbage";
    self.valid := function(thing) { wider self; return is_measure(thing) && thing.type == 'epoch';}
    self.isvalid := self.valid(self.epoch);
    self.changeUnits := function(toUnits) {
	wider self;
	if (self.isvalid) {
	    theunits := self.units[toUnits];
	    cvtUnits := theunits;
	    if (cvtUnits == "d" || cvtUnits == "h") {
		cvtUnits := spaste(".",cvtUnits);
	    }
	    if (self.epoch.m0.unit != theunits) {
		self.epoch.m0 := dq.convert(self.epoch.m0,cvtUnits);
		self.displayedUnits := toUnits;
	    }
	    self.displayString := paste(as_string(self.epoch.m0.value), theunits);
	    self.displayType := toUnits;
	} else {
	    self.displayString := as_string(self.epoch);
	}
    }
    self.changeDisplay := function(displayType) {
	wider self;
	if (self.isvalid) {
	    if (displayType == "MGST") displayType := 'mjd';
	    self.displayString := dq.time(self.epoch.m0,form=split(displayType));
	    self.displayType := displayType;
	} else {
	    self.displayString := as_string(self.epoch);;
	}
    }
    self.types := [=];
    self.types.ymd := self.changeDisplay;
    self.types.dmy := self.changeDisplay;
    self.types.mjd := self.changeDisplay
    self.types['day ymd'] := self.changeDisplay;
    self.types['day dmy'] := self.changeDisplay;
    self.types['day mjd'] := self.changeDisplay;
    self.types.MGST := self.changeDisplay;
    self.types.seconds := self.changeUnits;
    self.types.minutes := self.changeUnits;
    self.types.hours := self.changeUnits;
    self.types.days := self.changeUnits;
    self.types.years := self.changeUnits;
    self.epochTypes := "UTC TAI LAST LMST GMST1 GAST UT1 UT2 TDT TCG TDB TCB";

    self.units := [=];
    self.units.seconds := 's';
    self.units.minutes := 'min';
    self.units.hours := 'h';
    self.units.days := 'd';
    self.units.years := 'a';

    self.normalMenuButtons := field_names(self.types)[field_names(self.types) != "MGST"];
    self.restrictedMenuButtons := "MGST seconds minutes hours days years";
    self.menuButtons := "normal";

    self.setMenuButtons := function(newType) {
	wider self;
	if (newType == "GMST1" || newType == "LAST" || 
	    newType == "LMST" || newType == "GAST") {
	    if (self.menuButtons == "normal" ) {
		self.menuButtons := "restricted";
		self.entry.setMenuButtons(self.restrictedMenuButtons);
		self.displayType := "MGST";
	    }
	} else if (self.menuButtons != "normal") {
	    self.menuButtons := "normal";
	    self.entry.setMenuButtons(self.normalMenuButtons);
	    self.displayType := 'day ymd';
	}
    }	

    self.convertEpoch := function(newType) {
	wider self;
	success := F;
	if (self.isvalid) {
	    if (self.epoch.refer != newType) {
		newMeas := dm.measure(self.epoch,newType);
		if (self.valid(newMeas)) {
		    self.setMenuButtons(newType);
		    self.setEpoch(newMeas);
		    success := T;
		} else {
		    note(spaste('Unable to convert to ',newType,
				'. Probably due to incomplete reference frame'),
			 priority='SEVERE',
			 origin='epochEntry.convertEpoch(newType)');
		}
	    }
	}
	return success;
    }

    self.types[initialDisplay](initialDisplay);

    # this will be set shortly
    self.setEntry := F;

    self.menuCallback := function(name) {
	wider self;
	self.types[name](name);
	self.setEntry();
    }
    whichTypeNow := F;
    if (self.isvalid) {
	mask := self.epochTypes == self.epoch.refer;
	if (any(mask)) whichTypeNow := ind(self.epochTypes)[mask][1];
	if (is_boolean(whichTypeNow)) fail;
    } else {
	whichTypeNow := 1;
    }

    types := self.normalMenuButtons;
    if (self.isvalid && (self.epoch.refer == "GMST1" || self.epoch.refer == "LAST" || 
			 self.epoch.refer == "LMST" || self.epoch.refer == "GAST")) {
	type := self.restrictedMenuButtons;
	self.menuButtons := "restricted";
    }
    self.entry := menuEntryWithMenu(baseFrame, theLabel, self.displayString, 
				    types, self.menuCallback,
				    self.epochTypes, whichTypeNow, self.convertEpoch, pad,
				    entryWidth = 28, widgetset=dws);
    self.setEntry := function()
    {
	wider self;
	self.entry.setValue(self.displayString);
    }

    self.setEpoch := function(newEpoch)
    {
	wider self;
	# don't do anything if nothing is valid and the values are the same
	if (!is_record(newEpoch) && !is_record(self.epoch) &&
	    newEpoch == self.epoch) return;
	# don't do anything if both are valid and the values are the same
	if (self.isvalid && self.valid(newEpoch) &&
	    newEpoch.refer == self.epoch.refer && 
	    newEpoch.m0.value == self.epoch.m0.value &&
	    newEpoch.m0.unit == self.epoch.m0.unit) return;
	# do everything
	self.epoch := newEpoch;
	self.isvalid := self.valid(self.epoch);
	self.types[self.displayType](self.displayType);
	self.setEntry();
    }

    public.setValue := function(newEpoch)
    {
	wider self;
	if (self.valid(newEpoch)) {
	    newType := newEpoch.refer;
	    self.setMenuButtons(newType);
	    self.entry.setSecondMenuLabel(newType);
	}
	self.setEpoch(newEpoch);
    }
   
    public.getValue := function() { wider self; return self.epoch;}

#    public.self := function() { wider self; return self;}

    return public;
}

const directionEntry := function(baseFrame, theLabel, initialDirection, pad=T,
				 widgetset=dws)
{
    self := [=];
    self.direction := initialDirection;
    self.currentDirType := "garbage";
    self.valid := function(thing) { 
	wider self; 
	return is_measure(thing) && thing.type == 'direction';
    }
    self.isvalid := self.valid(self.direction);
    self.displayXString := "garbage";
    self.displayYString := "garbage";
    self.displayXType := "garbage";
    self.displayYType := "garbage";

    self.xlabel := "X";
    self.ylabel := "Y";

    self.displayAsTime := function(theValue, fieldName) {
	wider self;
	result := F;
	if (self.isvalid) {
	    result := dq.time(theValue[fieldName],prec=7);
	} else {
	    result := as_string(theValue);
	}
	return result;
    }
    self.displayAsAngle := function(theValue, fieldName) {
	wider self;
	result := F;
	if (self.isvalid) {
	    result := dq.angle(theValue[fieldName],prec=8);
	} else {
	    result := as_string(theValue);
	}
	return result;
    }
    self.displayAsDecTime := function(theValue, fieldName) {
	wider self;
	result := F;
	if (self.isvalid) {
	    result := as_string(dq.convert(dq.totime(theValue[fieldName]),'.h').value);
	} else {
	    result := as_string(theValue);
	}
	return result;
    }
    self.displayAsDecDeg := function(theValue, fieldName) {
	wider self;
	result := F;
	if (self.isvalid) {
	    result := as_string(dq.convert(theValue[fieldName],'deg').value);
	} else {
	    result := as_string(theValue);
	}
	return result;
    }
    self.displayXAsTime := function(displayType) {
	wider self;
	self.displayXString := self.displayAsTime(self.direction,"m0");
	self.displayXType := displayType;
    }
    # no need for displayYAsTime
    self.displayXAsAngle := function(displayType) {
	wider self;
	self.displayXString := self.displayAsAngle(self.direction,"m0");
	self.displayXType := displayType;
    }
    self.displayYAsAngle := function(displayType) {
	wider self;
	self.displayYString := self.displayAsAngle(self.direction,"m1");
	self.displayYType := displayType;
    }
    self.displayXAsDecDeg := function(displayType) {
	wider self;
	self.displayXString := self.displayAsDecDeg(self.direction,"m0");
	self.displayXType := displayType;
    }
    self.displayYAsDecDeg := function(displayType) {
	wider self;
	self.displayYString := self.displayAsDecDeg(self.direction,"m1");
	self.displayYType := displayType;
    }
    self.displayXAsDecTime := function(displayType) {
	wider self;
	self.displayXString := self.displayAsDecTime(self.direction,"m0");
	self.displayXType := displayType;
    }
    # no need for displayYAsDecTime

    self.xtypes := [=];
    self.xtypes.DMS := self.displayXAsAngle;
    self.xformats.DMS := '+-ddd.mmm.ss.s';
    self.xtypes.HMS := self.displayXAsTime;
    self.xformats.HMS := 'hh:mm:ss.ss';
    self.xtypes["HH.hhh"] := self.displayXAsDecTime;
    self.xformats["HH.hhh"] := "HH.hhh";
    self.xtypes["DDD.ddd"] := self.displayXAsDecDeg;
    self.xformats["DDD.ddd"] := "DDD.ddd";
    # Y is always only an angle
    self.ytypes := [=];
    self.ytypes.DMS := self.displayYAsAngle;
    self.yformats.DMS := '+-ddd.mmm.ss.s';
    self.ytypes["DDD.ddd"] := self.displayYAsDecDeg;
    self.yformats["DDD.ddd"] := "DDD.ddd";


    # for now, only those types that do not require other reference info
    self.dirTypes.J2000 := 'J2000';
    self.dirTypes.B1950 := 'B1950';
    self.dirTypes.GALACTIC := 'Galactic';
    self.dirTypes.AZEL := 'AzEl';
    self.dirTypes.HADEC := 'HaDec';
    self.referTypes.J2000 := 'J2000';
    self.referTypes.B1950 := 'B1950';
    self.referTypes.Galactic := 'GALACTIC';
    self.referTypes.AzEl := 'AZEL';
    self.referTypes.HaDec := 'HADEC';

    self.convertDirection := function(newType) {
	wider self;
	if (self.isvalid) {
	    if (self.direction.refer != self.referTypes[newType]) {
		newMeas := dm.measure(self.direction,self.referTypes[newType]);
		if (self.valid(newMeas)) {
		    self.setDirection(newMeas);
		    if (self.currentDirType != newType) {
			self.labelMenu->text(newType);
			self.currentDirType := newType;
		    }
		} else {
		    note(spaste('Unable to convert to ',newType,
				'.  Probably due to incomplete reference frame'),
			 priority='SEVERE',\
			 origin='directionEntry.convertDirection(newType)');
		}
	    } else {
		if (self.currentDirType != newType) {
		    self.labelMenu->text(newType);
		    self.currentDirType := newType;
		}
	    }
	}
    }
    self.displayXMenus := F;
    self.displayYMenus := "DMS DDD.ddd";

    self.xtype := 'hrs';
    self.xmenuChangePending := F;

    self.setLabels := function() {
	wider self;
	self.displayXMenus := "DMS DDD.ddd";
	oldxtype := self.xtype;
	self.xtype := 'deg';
	if (self.isvalid) {
	    if (self.direction.refer == "J2000" || self.direction.refer == "B1950") {
		self.xlabel := 'RA ';
		self.ylabel := 'DEC';
		self.displayXType := "HMS";
		self.displayYType := "DMS";
		self.displayXMenus := "HMS HH.hhh DDD.ddd DMS";
		self.xtype := 'hrs';
	    } else if (self.direction.refer == "GALACTIC") {
		self.xlabel := "GLAT";
		self.ylabel := "GLON";
		self.displayXType := "DDD.ddd";
		self.displayYType := "DDD.ddd";
	    } else if (self.direction.refer == "AZEL") {
		self.xlabel := "AZ";
		self.ylabel := "EL";
		self.displayXType := "DDD.ddd";
		self.displayYType := "DDD.ddd";
	    } else if (self.direction.refer == "HADEC") {
		self.xlabel := "HA";
		self.ylabel := "DEC";
		self.displayXType := "HMS";
		self.displayYType := "DMS";
		self.displayXMenus := "HMS HH.hhh DDD.ddd DMS";
		self.xtype := 'hrs';
	    } else {
		self.ylabel := "X";
		self.ylabel := "Y";
		self.displayXType := "DMS";
		self.displayYType := "DMS";
	    }
	} else {
	    self.xlabel := "X";
	    self.ylabel := "Y";
	    self.displayXType := "DMS";
	    self.displayYType := "DMS";
	}
	self.xmenuChangePending := oldxtype != self.xtype;
    }
    self.setLabels();
    self.xmenuChangePending := F;
    self.xtypes[self.displayXType](self.displayXType);
    self.ytypes[self.displayYType](self.displayYType);

    # these will be set shortly
    self.setXEntry := F;
    self.setYEntry := F;

    self.xmenuCallback := function(name) {
	wider self;
	self.xtypes[name](name);
	self.setXEntry();
	return T;
    }
    self.ymenuCallback := function(name) {
	wider self;
	self.ytypes[name](name);
	self.setYEntry();
	return T;
    }
    whichXDispTypeNow := F;
    pos := 1;
    while (pos <= len(self.displayXMenus) && is_boolean(whichXDispTypeNow)) {
	if (self.displayXMenus[pos] == self.displayXType) whichXDispTypeNow := pos;
	pos +:= 1;
    }
    if (is_boolean(whichXDispTypeNow)) fail;
    whichYDispTypeNow := F;
    pos := 1;
    while (pos <= len(self.displayYMenus) && is_boolean(whichYDispTypeNow)) {
	if (self.displayYMenus[pos] == self.displayYType) whichYDispTypeNow := pos;
	pos +:= 1;
    }
    if (is_boolean(whichYDispTypeNow)) fail;

    self.outerFrame := widgetset.frame(baseFrame,side='left',borderwidth=0,expand='x');
    self.menuFrame := widgetset.frame(self.outerFrame,side='top',borderwidth=0,expand='none');
    self.label := widgetset.label(self.menuFrame, theLabel);
    initialMenuLabel := "J2000";
    if (self.isvalid) initialMenuLabel := self.dirTypes[self.direction.refer];
    self.labelMenu := widgetset.button(self.menuFrame,initialMenuLabel,type='menu',width=9, relief='groove');
    self.labelButtons := [=];
    for (i in field_names(self.referTypes)) {
	self.labelButtons[i] := widgetset.button(self.labelMenu,text=i,value=i);
	whenever self.labelButtons[i]->press do { self.convertDirection($value);}
    }
    self.entryFrame := widgetset.frame(self.outerFrame,side='top',borderwidth=0,expand='none');
    self.xentry := labeledEntryWithMenu(self.entryFrame, self.xlabel, self.displayXString, 
					self.displayXMenus, whichXDispTypeNow, self.xmenuCallback, F, 
					labelWidth=4,entryWidth=13, widgetset=widgetset);
    self.yentry := labeledEntryWithMenu(self.entryFrame, self.ylabel, self.displayYString, 
					self.displayYMenus, whichYDispTypeNow, self.ymenuCallback, F, 
					labelWidth=4,entryWidth=13, widgetset=widgetset);
    if (pad) self.pad := widgetset.frame(self.outerFrame,borderwidth=0,height=0,width=0,expand='x');
    self.setXEntry := function()
    {
	wider self;
	self.xentry.setValue(self.displayXString);
    }
    self.setYEntry := function()
    {
	wider self;
	self.yentry.setValue(self.displayYString);
    }

    self.setDirection := function(newDirection)
    {
	wider self;
	# this avoids doing work if nothing is valid and the values are the same
	if (!is_record(newDirection) && !is_record(self.direction) &&
	    newDirection == self.direction) return;
	# this avoids doing work if both are valid and the same
	if (self.isvalid && self.valid(newDirection) &&
	    newDirection.refer == self.direction.refer &&
	    newDirection.m0.value == self.direction.m0.value &&
	    newDirection.m0.unit == self.direction.m0.unit &&
	    newDirection.m1.value == self.direction.m1.value &&
	    newDirection.m1.unit == self.direction.m1.unit) return;
	# otherwise do everything
	self.direction := newDirection;
	self.isvalid := self.valid(self.direction);
	self.setLabels();
	self.xentry.setLabel(self.xlabel);
	if (self.isvalid) {
	    if (self.dirTypes[self.direction.refer] != self.currentDirType) {
		self.currentDirType := self.dirTypes[self.direction.refer];
		self.labelMenu->text(self.currentDirType);
	    }
	}
	self.xentry.setMenuLabel(self.displayXType);
	if (self.xmenuChangePending) {
	    self.xentry.setMenuButtons(self.displayXMenus);
	    self.xmenuChangePending := F;
	}
	self.yentry.setLabel(self.ylabel);
	self.yentry.setMenuLabel(self.displayYType);
	self.xtypes[self.displayXType](self.displayXType);
	self.ytypes[self.displayYType](self.displayYType);
	self.setXEntry();
	self.setYEntry();
    }

    public.setValue := function(newDirection)
    {
	wider self;
	self.setDirection(newDirection);
    }
   
    public.getValue := function() { wider self; return self.direction;}

#    public.self := function() { wider self; return self;}

    return public;
}

const standardPrefixes := function()
{
    self := [=];
    pre := split(dq.map('pre'));
    self.pre := pre[6:len(pre)]
    self.pre[len(self.pre)+1] := '';
    self.pre[len(self.pre)+1] := '';
    self.pre[len(self.pre)+1] := '1';
    self.vals := as_double(self.pre[[1:len(self.pre)] % 3 == 0]);
    self.order := order(self.vals);

    public := [=];
    public.makeMap := function(baseUnitString, theRange=F)
    {
	wider self;
	result := [=];
	if (is_boolean(theRange) || len(theRange) != 2 || !is_numeric(theRange)) 
	    theRange := range(self.vals);
	for (i in self.order) {
	    if (self.vals[i] >= theRange[1] && self.vals[i] <= theRange[2]) {
		name := spaste([self.pre[(i-1)*3+1]],baseUnitString);
		result[name] := self.vals[i];
	    }
	}
	return result;
    }

    return public;
}

_standardPrefixes_ := standardPrefixes(); 

const quantityEntry := function(baseFrame, theLabel, initialQuantity, initialScale='', scaleRange=F, pad=T,
				labelWidth=F, entryWidth=F, widgetset=dws)
{
    if (!is_string(initialScale)) fail;

    self := [=];
    self.quantity := initialQuantity;
    self.valid := function(theValue) { wider self; return is_quantity(theValue);}
    self.isvalid := self.valid(self.quantity);
    self.map := F;
    if (self.isvalid) {
	self.map := _standardPrefixes_.makeMap(self.quantity.unit,scaleRange);
    } else {
	self.map := [=];
	self.map[' '] := 1.0;
    }
    if (self.isvalid) {
	self.displayedUnit := self.quantity.unit;
    } else {
	self.displayedUnit := ' ';
    }
    self.displayedUnit := initialScale;
    self.displayString := "garbage";
    self.setDisplayString := function () 
    {
	wider self;
	if (self.isvalid) {
	    if (has_field(self.map, self.displayedUnit)) {
		self.displayString := as_string(self.quantity.value / self.map[self.displayedUnit]);
	    } else {
		self.displayString := as_string(self.quantity.value);
	    }
	} else {
	    self.displayString := as_string(self.quantity);
	}
    }

    self.setValue := function() {
	wider self;
	self.setDisplayString();
	self.entry.setValue(self.displayString);
    }

    self.menuCallback := function(name) {
	wider self;
	self.displayedUnit := name;
	self.setValue();
	return T;
    }

    i := 1;
    whichIsDisplayed := F;
    names := field_names(self.map);
    while(i <= len(names) && is_boolean(whichIsDisplayed)) {
	if (names[i] == self.displayedUnit) whichIsDisplayed := i;
	i +:= 1;
    }
    if (is_boolean(whichIsDisplayed)) fail;

    self.entry := labeledEntryWithMenu(baseFrame, theLabel, self.displayString, names,
				       whichIsDisplayed, self.menuCallback, pad, labelWidth, 
				       entryWidth, widgetset=widgetset);

    self.setValue();

    public.getValue := function() { wider self; return self.quantity;}
    public.setValue := function(newValue) {
	wider self;

	# this saves setting things if everything is not valid and the same
	if (!is_record(newValue) && !is_record(self.quantity) &&
	    newValue == self.quantity) return;
	# this saves setting things if everything is valid and the same
	if (self.isvalid && self.valid(newValue) && 
	    self.quantity.value  == newValue.value &&
	    self.quantity.unit == newValue.unit) return;
	# otherwise, reset everything
	self.quantity := newValue;
	self.isvalid := self.valid(self.quantity);
	self.setValue();
    }

#    public.self := function() { wider self; return self;}

    return public;
}

const durationEntry := function(baseFrame, theLabel, initialDuration, initialDisplay, pad=T,
				labelWidth=F, entryWidth=F, widgetset=dws)
{
    if (!is_string(initialDisplay)) fail;

    self := [=];
    self.duration := initialDuration;
    self.valid := function() { wider self; return is_quantity(self.duration);}
    self.isvalid := self.valid();
    self.displayString := "garbage";
    self.types := "seconds minutes hours days years";
    self.units := [=];
    self.units.seconds := 's';
    self.units.minutes := 'min';
    self.units.hours := 'h';
    self.units.days := 'd';
    self.units.years := 'a';
    self.displayedUnits := initialDisplay;
    self.changeUnits := function(toUnits) 
    {
	wider self;
	if (self.isvalid) {
	    theunits := self.units[toUnits];
	    cvtUnits := theunits;
	    if (cvtUnits == "d" || cvtUnits == "h") {
		cvtUnits := spaste(".",cvtUnits);
	    }
	    self.duration := dq.convert(self.duration,cvtUnits);
	    self.displayString := as_string(self.duration.value);
	    self.displayedUnits := toUnits;
	} else {
	    self.displayString := as_string(self.duration);
	}
    }

    self.changeUnits(initialDisplay);

    # this will be set shortly
    self.setEntry := F;

    self.menuCallback := function(name) {
	wider self;
	self.changeUnits(name);
	self.setEntry();
	return T;
    }

    i := 1;
    whichIsDisplayed := F;
    while(i <= len(self.types) && is_boolean(whichIsDisplayed)) {
	if (self.types[i] == initialDisplay) whichIsDisplayed := i;
	i +:= 1;
    }
    if (is_boolean(whichIsDisplayed)) fail;

    self.entry := labeledEntryWithMenu(baseFrame, theLabel, self.displayString, self.types,
				       whichIsDisplayed, self.menuCallback, pad,
				       labelWidth, entryWidth, widgetset=widgetset);

    self.setEntry := function()
    {
	wider self;
	self.entry.setValue(self.displayString);
    }

    self.setDuration := function(newDuration)
    {
	wider self;
	if (newDuration == self.duration) return;
	oldDuration := self.duration;
	self.duration := newDuration;
	self.isvalid := self.valid();
	if (self.isvalid && self.duration.value == oldDuration.value &&
	    self.duration.unit == oldDuration.unit) return;
	self.changeUnits(self.displayedUnits);
	self.setEntry();
    }

    public.setValue := function(newValue)
    {
	wider self;
	self.setDuration(newValue);
    }
   
    public.getValue := function() { wider self; return self.duration;}

#    public.self := function() { wider self; return self;}

    return public;
}

const positionEntry := function(baseFrame, theLabel, initialPosition, pad=T, widgetset=dws)
{
    self := [=];
    self.position := initialPosition;
    self.valid := function() { wider self; return is_measure(self.position) && self.position.type == 'position';}
    self.isvalid := self.valid();
    self.displayString := "garbage";
    self.refers := "WGS84 ITRF";

    self.changeRefer := function(toRefer) 
    {
	wider self;
	if (self.isvalid) {
	    if (self.position.refer != toRefer) self.position := dm.measure(self.position,toRefer);
	    if (self.position.refer == "WGS84") {
		self.string0 := dq.angle(self.position.m0);
		self.units0 := "DMS";
		self.label0 := "Long.";
		self.string1 := dq.angle(self.position.m1);
		self.units1:= "DMS";
		self.label1 := "Lat.";
		self.string2 := as_string(self.position.m2.value);
		self.units2 := as_string(self.position.m2.unit);
		self.label2 := "Elev.";
	    } else {
		self.string0 := as_string(self.position.m0.value);
		self.units0 := as_string(self.position.m0.unit);
		self.label0 := "X";
		self.string1 := as_string(self.position.m1.value);
		self.units1 := as_string(self.position.m1.unit);
		self.label1 := "Y";
		self.string2 := as_string(self.position.m2.value);
		self.units2 := as_string(self.position.m2.unit);
		self.label2 := "Z";
	    }
	} else {
	    self.string0 := as_string(self.position);
	    self.units0 := '';
	    self.label0 := "X";
	    self.string1 := as_string(self.position);
	    self.units1 := '';
	    self.label1 := "Y";
	    self.string2 := as_string(self.position);
	    self.units2 := '';
	    self.label2 := "Z";
	}
    }

    whichIsDisplayed := 0;
    if (self.isvalid) {
	i := 1;
	whichIsDisplayed := F;
	while(i <= len(self.refers) && is_boolean(whichIsDisplayed)) {
	    if (self.refers[i] == self.position.refer) whichIsDisplayed := i;
	    i +:= 1;
	}
	if (is_boolean(whichIsDisplayed)) fail;
    }

    initRefer := 'ITRF';
    if (self.isvalid) initRefer := self.position.refer;
    self.changeRefer(initRefer);

    # this will be set shortly
    self.setEntry := F;

    self.menuCallback := function(name) {
	wider self;
	self.changeRefer(name);
	self.setEntry();
	return T;
    }

    self.outerFrame := widgetset.frame(baseFrame,borderwidth=0,side='left', expand='x');
    self.topFrame1 := widgetset.frame(self.outerFrame,borderwidth=0,side='top',expand='none');
    self.labelFrame := widgetset.frame(self.topFrame1,borderwidth=0,side='left',expand='none');
    self.label := widgetset.label(self.labelFrame, theLabel);
    self.menu := widgetset.button(self.labelFrame, type='menu', width=5, text=initRefer, relief='groove');
    self.itrf := widgetset.button(self.menu, text='ITRF',value='ITRF');
    self.wgs84 := widgetset.button(self.menu,text='WGS84',value='WGS84');
    whenever self.itrf->press, self.wgs84->press do {
	self.menu->text($value);
	self.menuCallback($value);
    }


    self.topFrame2 := widgetset.frame(self.outerFrame,borderwidth=0,side='top',expand='none');
    self.entry0 := labeledEntryWithUnits(self.topFrame2, self.label0, self.string0, 
					 self.units0, pad, 5, 14, 3,
					 widgetset=widgetset);
    self.entry1 := labeledEntryWithUnits(self.topFrame2, self.label1, self.string1, 
					 self.units1, pad, 5, 14, 3,
					 widgetset=widgetset);
    self.entry2 := labeledEntryWithUnits(self.topFrame2, self.label2, self.string2, 
					 self.units2, pad, 5, 11, 1,
					 widgetset=widgetset);

    if (pad) self.pad := widgetset.frame(self.outerFrame, borderwidth=0,height=2,width=0,expand='x');
    self.setEntry := function()
    {
	wider self;
	self.entry0.setValue(self.string0);
	self.entry0.setLabel(self.label0);
	self.entry0.setUnits(self.units0);
	self.entry1.setValue(self.string1);
	self.entry1.setLabel(self.label1);
	self.entry1.setUnits(self.units1);
	self.entry2.setValue(self.string2);
	self.entry2.setLabel(self.label2);
	self.entry2.setUnits(self.units2);
    }

    self.setPosition := function(newPosition)
    {
	wider self;
	if (self.isvalid) oldrefer := self.position.refer;
	self.position := newPosition;
	self.isvalid := self.valid();
	refer := "ITRF";
	if (self.isvalid) refer := self.position.refer;
	self.changeRefer(refer);
	self.setEntry();
	if (self.isvalid && oldrefer != self.position.refer) self.menu->text(self.position.refer);
    }

    public.setValue := function(newValue)
    {
	wider self;
	self.setPosition(newValue);
    }
   
    public.getValue := function() { wider self; return self.position;}

#    public.self := function() { wider self; return self;}

    return public;
}

testLabeledEntry := function(baseFrame=F,widgetset=dws,nloop=100)
{
    f := baseFrame;
    if (!is_agent(f)) f := widgetset.frame();
    le := labeledEntry(f,"Test",as_string(0));
    t0 := time();
    for (i in 1:nloop) le.setValue(as_string(i));
    tdelt := time()-t0;
    print "Elapsed : = ",tdelt," = ", nloop/tdelt," sets per second.";
    print "labeledEntry final value : ", le.getValue();
}

testLabeledEntryWithUnits := function(baseFrame=F,widgetset=dws,nloop=100)
{
    f := baseFrame;
    if (!is_agent(f)) f := widgetset.frame();
    le := labeledEntryWithUnits(f,"Test",as_string(0),"s");
    t0 := time();
    for (i in 1:nloop) le.setValue(as_string(i));
    tdelt := time()-t0;
    print "Elapsed : = ",tdelt," = ", nloop/tdelt," sets per second.";
    print "labeledEntryWithUnits final value : ", le.getValue();
}

testLabeledEntryWithMenu := function(baseFrame=F,widgetset=dws,nloop=100)
{
    f := baseFrame;
    if (!is_agent(f)) f := widgetset.frame();
    pressCallback := function(name) { print name," pressed."; return T;}
    le := labeledEntryWithMenu(f,"Test",as_string(0),"A B C D E",1,pressCallback);
    t0 := time();
    for (i in 1:nloop) le.setValue(as_string(i));
    tdelt := time()-t0;
    print "Elapsed : = ",tdelt," = ", nloop/tdelt," sets per second.";
    print "labeledEntryWithMenu final value : ", le.getValue();
    print "Setting menu to D", le.setMenuLabel("D");
}

testMenuEntry := function(baseFrame=F,widgetset=dws,nloop=100)
{
    f := baseFrame;
    if (!is_agent(f)) f := widgetset.frame();
    pressCallback := function(name) { print name," pressed.";}
    le := menuEntry(f,"Test",as_string(0),"A B C D E",pressCallback);
    t0 := time();
    for (i in 1:nloop) le.setValue(as_string(i));
    tdelt := time()-t0;
    print "Elapsed : = ",tdelt," = ", nloop/tdelt," sets per second.";
    print "menuEntry final value : ", le.getValue();
    print "Setting menu to D", le.setMenuLabel("D");
}

testMenuEntryWithMenu := function(baseFrame=F,widgetset=dws,nloop=100)
{
    f := baseFrame;
    if (!is_agent(f)) f := widgetset.frame();
    pressCallback := function(name) { print "First menu : ",name," pressed.";}
    secondPressCallback := function(name) { print "Second menu : ", name," pressed."; return T;}
    le := menuEntryWithMenu(f,"Test",as_string(0),"A B C D E",pressCallback,
			    "Do Re Mi Fa So La Ti",3,secondPressCallback);
    t0 := time();
    for (i in 1:nloop) le.setValue(as_string(i));
    tdelt := time()-t0;
    print "Elapsed : = ",tdelt," = ", nloop/tdelt," sets per second.";
    print "menuEntryWithMenu final value : ", le.getValue();
    print "Setting menu to D", le.setMenuLabel("D");
    print "Setting second menu to So", le.setSecondMenuLabel("So");
}

testEpochEntry := function(baseFrame=F,widgetset=dws,nloop=100)
{
    f := baseFrame;
    if (!is_agent(f)) f := widgetset.frame();
    t := dm.epoch('utc','today');
    te := epochEntry(f,"Epoch",t,'day dmy');
    t0 := time();
    for (i in 1:nloop) {
	# this assumes that the value has units of days
	# add one minute on each pass through the loop
	t.m0.value  +:= 1.0/24.0/60.0;
	te.setValue(t);
    }
    tdelt := time()-t0;
    print "Elapsed : = ",tdelt," = ", nloop/tdelt," sets per second.";
    print "Epoch entry final value : ", te.getValue();
}

testDirectionEntry := function(baseFrame=F,widgetset=dws,nloop=100){
    f := baseFrame;
    if (!is_agent(f)) f := widgetset.frame();
    d := dm.direction('J2000','30deg','40deg');
    de := directionEntry(f,"Direction",d);
    t0 := time();
    for (i in 1:nloop) {
	# this assumes that the value has units of deg
	# add one minute of arc to x and subtract 1 minute of 
	# arc from y on each pass through the loop
	d.m0.value  +:= 1.0/60.0;
	d.m1.value  -:= 1.0/60.0;
	de.setValue(d);
    }
    tdelt := time()-t0;
    print "Elapsed : = ",tdelt," = ", nloop/tdelt," sets per second.";
    print "Direction entry final value : ", de.getValue();
}

testQuantityEntry := function(baseFrame=F, widgetset=dws, nloop=100)
{
    f := baseFrame;
    if (!is_agent(f)) f := widgetset.frame();
    q := dq.quantity("1420.4058e6Hz");
    qe := quantityEntry(f,"Frequency",q,'MHz',[1,1e9]);
    t0 := time();
    for (i in 1:nloop) {
	q.value +:= 1.0e6;
	qe.setValue(q);
    }
    tdelt := time()-t0;
    print "Elapsed : = ",tdelt," = ", nloop/tdelt," sets per second.";
    print "quantityEntry final value : ", qe.getValue();
}

testDurationEntry := function(baseFrame=F, widgetset=dws, nloop=100)
{
    f := baseFrame;
    if (!is_agent(f)) f := widgetset.frame();
    q := dq.quantity("321.45s");
    de := durationEntry(f,"Duration",q,'seconds');
    t0 := time();
    for (i in 1:nloop) {
	q.value +:= 1.0;
	de.setValue(q);
    }
    tdelt := time()-t0;
    print "Elapsed : = ",tdelt," = ", nloop/tdelt," sets per second.";
    print "durationEntry final value : ", de.getValue();
}

testPositionEntry := function(baseFrame=F, widgetset=dws, nloop=100)
{
    f := baseFrame;
    if (!is_agent(f)) f := widgetset.frame();
    p := dm.observatory();
    pe := positionEntry(f,"Direction",p);
    p := dm.observatory('GB');
    t0 := time();
    for (i in 1:nloop) {
	# this doesn't test much, but I'm not sure how to adjust p correctly
	pe.setValue(p);
    }
    tdelt := time()-t0;
    print "Elapsed : = ",tdelt," = ", nloop/tdelt," sets per second.";
    print "Position entry final value : ", pe.getValue();
}

testAllEntries := function(widgetset=dws)
{
    f := widgetset.frame();
    testLabeledEntry(f);
    testLabeledEntryWithUnits(f);
    testLabeledEntryWithMenu(f);
    testMenuEntry(f);
    testMenuEntryWithMenu(f);
    testEpochEntry(f);
    testDirectionEntry(f);
    testQuantityEntry(f);
    testDurationEntry(f);
    testPositionEntry(f);
}
