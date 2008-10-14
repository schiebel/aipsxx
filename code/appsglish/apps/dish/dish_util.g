## dish_util.g: utility functions/objects for dish.
#------------------------------------------------------------------------------
#   Copyright (C) 1997,1998,1999,2000,2001,2002
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
#    $Id: dish_util.g,v 19.2 2004/08/25 01:09:04 cvsmgr Exp $
#
#------------------------------------------------------------------------------

pragma include once;

include 'popuphelp.g';
include 'widgetserver.g';

# this is an object which has two buttons.  It is intended to be used
# to signal which units are to be displayed and to convert between
# the units.  It should be used when there are two possible units.
# For example, "X-Axis Units" and "Channels".  The first button
# is a memu which the user can select from the two units.  The 
# second button, always labeled "Convert" is a simple button which 
# calls the callback function when pressed.
#
# parentFrame = the frame in which to embed this widget
# unitString1, unitString2 = the unit strings
# unitcallback = this is the function called when the units button is pressed.
#                The unitcallback function should take a single argument,
#                the value of the NEW units after the button has been pressed.
# convertcallback = the convert call back function - this is called when
#            the "Convert" button is pressed.  It should take
#            a single argument - the current unit number (1 or 2)
#            at the time the convert button is pressed.  The callback 
#            function is then responsible for the actual conversion 
#            as well as for singnalling a successful conversion by 
#            setting the new units in this widget
# side = Controls the placement of the two buttons.
# optionalLabel = An optional label (e.g. "FWHM" for use by in
#                 specifying a gaussian width in the smoothing app).
#                 This always appears to the right of the units menu.
# optionalButtonWidth = Use this to specify the length of the strings
#                 so that the two buttons have the same size.
#                 This widget could call strlen, but since that
#                 currently involves a client call, this seems faster
#                 (especially in most cases its not a really a run-time
#                 decision - the programmer knows when they use this
#                 what the two strings are and hence what this 
#                 argument should be).
# 
# This widget has the following public members:
#   setunits(whichUnitNumber) : set the units to either 1
#                               unitString1, or 2, unitString2.
#                               This changes the text of the menu button.
#   getunits() : returns the current unit number
#   setconvertcallback(newcallback) : set the convertcallback function to newcallback.
#   setunitcallback(newcallback) : set the unitcallback to newcallback
#   disabled(TorF) : disable these buttons if TorF == T, appearance stays the same 
#   disabledappearance(TorF) : disable/enable the buttons AND change the appearance
#
dishConverterWidget := function(parentFrame=F,
				unitString1, unitString2,
				unitcallback, convertcallback, 
				initialUnitString,
				side='top', optionalLabel=F,
				optionalButtonWidth=F,
				widgetset=dws)
{
    self := [=];
    public := [=];

    self.unitcallback := unitcallback;
    self.convertcallback := convertcallback;
    self.optionalLabel := F;
    self.units := [unitString1, unitString2];
    self.currUnit := 1;
    if (initialUnitString == unitString1) {
	self.currUnit := 1;
    } else {
	if (initialUnitString == unitString2) {
	    self.currUnit := 2;
	} else {
	    fail('dishConverterWidget: unrecognized initialUnitString');
	}
    }
    
    if (is_boolean(parentFrame)) {
	self.frame := widgetset.frame(side=side, borderwidth=0,expand='none');
    } else {
	self.frame := widgetset.frame(parentFrame, side=side, borderwidth=0,expand='none');
    }
    self.menuFrame := widgetset.frame(self.frame, side='left');
    if (is_boolean(optionalButtonWidth)) {
	self.menu := widgetset.button(self.menuFrame, text=self.units[self.currUnit], type='menu',
				      relief='groove');
    } else {
	self.menu := widgetset.button(self.menuFrame, text=self.units[self.currUnit], type='menu',
				      width=optionalButtonWidth, relief='groove');
    }
    popuphelp(self.menu,hlp='The current units.',
	      txt='Select the units for fields controlled by this menu.  Value conversion will NOT occur', 
	      combi=T);
    self.menuButton1 := widgetset.button(self.menu, text=unitString1, value=1);
    self.menuButton2 := widgetset.button(self.menu, text=unitString2, value=2);
    if (!is_boolean(optionalLabel)) {
	self.optionalLabel := widgetset.label(self.menuFrame, text=optionalLabel);
    }
    self.menuPad := widgetset.frame(self.menuFrame,expand='both',borderwidth=0,height=1,width=1);
    self.convertFrame := widgetset.frame(self.frame, side='left',borderwidth=0);
    if ((side == 'top' || side == 'bottom') && is_numeric(optionalButtonWidth)) {
	self.convertButton := widgetset.button(self.convertFrame, text='Convert', padx=6, pady=2,
					       width=optionalButtonWidth);
    } else {
	self.convertButton := widgetset.button(self.convertFrame, text='Convert' ,padx=6, pady=2);
    }
    popuphelp(self.convertButton,
	      hlp='Convert to the other units',
	      txt='Converts all controlled values to the other unit choice');
    self.convertPad := widgetset.frame(self.convertFrame,  borderwidth=0, expand='both',
				       height=1, width=1);

    self.setUnits := function(whichUnitNumber) {
	wider self;
	if (whichUnitNumber != self.currUnit) {
	    if (is_integer(whichUnitNumber) &&
		whichUnitNumber > 0 && whichUnitNumber <= len(self.units)) {
		self.currUnit := whichUnitNumber;
		self.menu->text(self.units[whichUnitNumber]);
	    }
	}
	    return self.currUnit;
    }

    self.dounitcallback := function() {
	wider self;
	if (is_function(self.unitcallback)) 
	    self.unitcallback(self.currUnit);
    }

    self.doconvertcallback := function() {
	wider self;
	if (is_function(self.convertcallback)) 
	    self.convertcallback(self.currUnit);
    }

    whenever self.convertButton->press do {
	wider self;
	self.doconvertcallback();
    }

    whenever self.menuButton1->press, self.menuButton2->press do {
	self.setUnits($value);
	self.dounitcallback();
    }

    public.setunits := function(whichUnitNumber) {
	wider self;
	self.setUnits(whichUnitNumber);
    }

    public.getunits := function() {
	wider self;
	#comment
	return self.currUnit;
    }

    public.setunitcallback := function(newcallback) {
	wider self;
	self.unitcallback := newcallback;
    }

    self.disabled := function(TorF) {
	self.menu->disabled(TorF);
	self.convertButton->disabled(TorF);
    }

    public.disabled := function(TorF) {
	wider self;
	self.disabled(TorF);
    }

    public.disabledappearance := function(TorF) {
	wider self;
	if (TorF) {
	    self.menu->foreground('grey60');
	    self.convertButton->foreground('grey60');
	    if (is_boolean(self.optionalLabel)) self.optionalLabel->foreground('grey60');
	} else {
	    self.menu->foreground('black');
	    self.convertButton->foreground('black');
	    if (is_boolean(self.optionalLabel)) self.optionalLabel->foreground('black');
	}
	self.disabled(TorF);
    }

    public.setconvertcallback := function(newcallback) {
	wider self;
	self.convertcallback := newcallback;
    }

    public.self := function() {
	wider self;
	return self;
    }
    return public;
}

# sdut.parseranges(ranges) : ranges is a string indicating some numerical ranges
#                            it should only contain numbers and the syntax for
#                            indicating a range is one of [# #] [#,#] [#,] [,#] and #
#                            The first two indicate a start and end, the third indicates
#                            a start # and end at MAX_DOUBLE, the fourth indicates
#                            start at -MAX_DOUBLE and end at # and the last indicates
#                            a single value (i.e. start and end at the same number)
#                            The ranges are returned in a 2D matrix of doubles having
#                            the shape: [2,nranges].  No attempt is made to remove 
#                            duplicates, overlaps, etc, although each range is 
#                            always such that the min value is [1,n] and the max is [2,n].
# sdut.parsestringlist(thestring)  This is the equivalent of parseranges for
#                            string items in selection.  The item separator is
#                            either whitespace or a comma unless quotes are used.
#                            Text enclosed between quotes (either single or double)
#                            is interpreted as a single item.  The result is returned.
# sdut.parsefunction(thefunction, recname) This is used by the dish apply function
#                            operation to substitute the tokens with the appropriate
#                            data name.  thefunction is the string to do the
#                            substitution on, recname is the top level name of
#                            the SDRecord in use in the function.
#                            DATA -> recname.data
#                            DESC -> recname.desc
#                            ARR  -> recname.data.arr
#                            HEADER -> recname.header
#                            NS_HEADER -> recname.ns_header
#                            Min-match is used (i.e. DA == DATA, A=ARR, etc).
#                            The result is put into all lower case since all
#                            variables in an SDRecord must be in lower case.
#                            (this allows users to forget and use TSYS when they
#                            meant tsys).  A replacement only occurs if
#                            the possible token is the nearest non-whitespace
#                            character on either side of the token is a
#                            non alphanumeric character (i.e. DATA ARR would
#                            not be replaced [there's no operation there, so
#                            it makes no sense] but DATA, ARR would be (this
#                            might be some function parameterization indicated
#                            by this syntax).
#                            The result is returned.
sdutil := function() {
    private := [=];
    public := [=];

    
    private.parserange := function(therange)
    {
	# all whitespace has been eliminated by here and
	# only comma separators appear, the brackets were
	# removed as well
	mvalue := m/^(([+-]?\d+)|(?:[+-]?((\d+\.\d*)|(\.\d+)|(\d+))([eE][+-]?\d+)?))$/;

	result := [-system.limits.max.double, system.limits.max.double];

	splitThing := split(therange, ',');
	# everything should be a value
	for (it in splitThing) if (! (it ~ mvalue)) {
	    fail(paste('Range contains an invalid value :', it));
	}
	if ((len(splitThing) == 2)) {
	    result[1] := as_double(splitThing[1]);
	    result[2] := as_double(splitThing[2]);
	} else {
	    # too many values ?
	    if (len(splitThing > 2)) fail('Too many values in range');
	    # did the range have leading separator
	    if (therange ~ m/^,/) {
		result[2] := as_double(splitThing[1]);
	    } else {
		# does it have a trailing separator
		if (therange ~ m/,$/) {
		    result[1] := as_double(splitThing[1]);
		} else {
		    # it must not contain any separator, single value
		    result[1] := as_double(splitThing[1]);
		    result[2] := result[1];
		}
	    }
	}

	minrange := min(result);
	maxrange := max(result);
	return [minrange,maxrange];
    }


    public.parseranges := function(ranges) {
	wider private;
	result := as_integer([]);
	# combine
	theranges := paste(ranges,' ');
	# remove trailing whitespace after '[' and before ']'
	theranges ~:= s/\[\s+/[/g;
	theranges ~:= s/\s+\]/]/g;
	# remove surrounding whitespace from commas and :
	theranges ~:= s/\s*[,:]\s*/,/g;
	# any remaining whitespace must be functionally a comma
	theranges ~:= s/\s+/,/g;
	
	count := 0;
	rangePending := F;
	thisRange := F;

	newValuePending := F;

	while (strlen(theranges)) {
	    newValuePending := F;
	    if (!rangePending) {
		# get to next comma
		t := theranges ~ s/(.*?)([,\[])(.*)/$1 $2 $3/;
		if ($m[2] == '[') {
		    rangePending := T;
		}
		# but this value is a single value
		if (strlen($m[1])) {
		    df := as_double($m[1]);
		    theRange := [df, df];
		    newValuePending := T;
		}
		theranges := $m[3];
	    } else {
		# get to the next closing bracket
		t := theranges ~ s/(.*?)\](.*)/$1 $2/;
		theranges := $m[2];
		theRange := private.parserange($m[1]);
		rangePending := F;
		newValuePending := T;
	    }
	    if (newValuePending) {
		count +:= 1;
		if (count == 1) {
		    result := theRange;
		} else {
		    n1 := count*2 - 1;
		    result[n1:(n1+1)] := theRange;
		}
	    }
	}
	result::shape := [2, count];
	
	return result;
    }

    private.parsestring := function(theString)
    {
	wider private;

	# split to individual chars
	chars := split(theString,'');
	inside := F;
	escaped := F;
	# start with a bracket and leading quote
	newchars := '\[\'';
	for (i in 1:len(chars)) {
	    if (!escaped && chars[i] == "\\") {
		# next character is escaped, skip this one
		escaped := T;
	    } else {
		if (!escaped && chars[i] ~ m/[\[\]\"]/) {
		    if (!inside) {
			# going inside group
			inside := T;
			# supply ending quote and comma separator for previous segment
			# and if this was a ", keep it there
			if (chars[i] == '\"') {
			    newchars := spaste(newchars,'\',\"');
			} else {
			    newchars := spaste(newchars,'\',');
			}
		    } else {
			# end of group
			inside := F;
			# supply comma separate and starting quote
			# and if this was a ", keep it there
			if (chars[i] == '\"') {
			    newchars := spaste(newchars,'",\'');
			} else {
			    newchars := spaste(newchars,',\'');
			}
		    }
		} else {
		    # just copy these characters
		    newchars := spaste(newchars,chars[i]);
		}
		escaped := F;
	    }
	}
	# close off remaining open quote at end
	# and make it look like a vector, to be parsed
	newchars := spaste(newchars,'\']');

	# and turn it into a vector
	result := eval(newchars);
	if (!is_fail(result)) {
	    # clean - up
	    # remove leading spaces
	    result ~:= s/^\s+//;
	    # and trailing spaces
	    result ~:= s/\s+$//;

	    result := result[strlen(result)!=0];
	}
	return result;
    }

    public.parsestringlist := function(stringvec) {
	wider private;
	# parse each element separately
	count := 1;
	result := as_string([]);
	if (len(stringvec) > 0) {
	    for (i in 1:len(stringvec)) {
		addin := private.parsestring(stringvec[i]);
                if (is_fail(addin)) {
		    fail;
	        }
		nnew := len(addin);
		if (nnew > 0) {
		    result[count:(count+nnew-1)] := addin;
		    count +:= nnew;
		}
	    }
	}
	return result;
    }

    return public;
}

tsdutil := function() 
{
    sdut := sdutil();

    # these need to be kept in sync by hand
    result := sdut.parseranges("[1,10],[20.25:50.75], [50] [ ,25] [200 ,], 45 50.3 75.25, [80 200], [300 200]");
    tres := array(0.0,2,10);
    tres[,1] := [1,10];
    tres[,2] := [20.25,50.75];
    tres[,3] := [50,50];
    tres[,4] := [-system.limits.max.double,25];
    tres[,5] := [200,system.limits.max.double];
    tres[,6] := [45,45];
    tres[,7] := [50.3,50.3];
    tres[,8] := [75.25,75.25];
    tres[,9] := [80,200];
    tres[,10] := [200,300];
    if (tres != result) fail('test of parseRanges failed');

    return result;
}

