# helpmenu: construct an aips++ Help menu
# Copyright (C) 1999,2000,2001
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
# $Id: helpmenu.g,v 19.2 2004/08/25 02:14:55 cvsmgr Exp $

# include guard
pragma include once;

include 'widgetserver.g';   # for dws
include 'unset.g';


# other items are included when a specific button is pressed

const helpmenu := function(parent, menuitems=unset, refmanitems=unset, callback=unset,
			   helpitems=unset, widgetset=dws) {
    private := [=];
    public := [=];

    if (!is_agent(parent)) fail 'helpmenu: parent is not an agent';

    private.callback := unset;
    private.buttons := [=];
    private.whenevers := [];
    private.dws := widgetset;
    private.localparent := private.dws.frame(parent, borderwidth=0,height=1,width=1,expand='none');
    private.helpbutton := F;

    private.help := function(what) {
        private.localparent->disable();
	include 'aips2help.g';
        ok := help(what);
        private.localparent->enable();
    }

    private.cleanup := function() {
	wider private;
	# deactivate the whenevers
	deactivate private.whenevers;
	private.whenevers := [];
	private.dws.popupremove(private.helpbutton);
	# wipe out the help buttons
	for (i in ind(private.buttons)) {
	    private.buttons[i] := F;
	}
	private.buttons := [=];
	# wipe out the menu, need to start from scratch
	# val is necessary here because the popup menu still exists and we
	# can't remove that here
	val private.helpbutton := F;
    }

    const public.reset := function(menuitems=unset, refmanitems=unset, 
				   callback=unset, helpitems=unset) {
	wider private;
	# add any local menu items as necessary
	count := 0;
	if (!is_unset(menuitems)) {
	    # sanity checks
	    if (is_unset(refmanitems))
		fail 'helpmenu: menuitems has been set but refmanitems remains unset';
	    if (!is_unset(refmanitems) && (len(menuitems) != len(refmanitems)))
		fail 'helpmenu: mis-matched number of items in menuitems and refmanitems';
	    if (!is_unset(callback) && !is_function(callback))
		fail 'helpmenu: the callback argument is neither unset or a function';
	    if (is_unset(callback) && any(strlen(refmanitems)==0)) 
		fail 'helpmenu: there are empty refmanitems but callback is unset';
	    # things look okay from here
	    private.cleanup();
	    private.helpbutton := private.dws.button(private.localparent, type='menu', text='Help');
	    private.callback := callback;

	    for (i in ind(menuitems)) {
		count +:= 1;
		if (strlen(refmanitems[i]) > 0) {
		    # reference manual help
		    private.buttons[count] := private.dws.button(private.helpbutton, text=menuitems[i],
								 value=refmanitems[i]);
		    whenever private.buttons[count]->press do {
			private.help($value);
		    }
		} else {
		    private.buttons[count] := private.dws.button(private.helpbutton, text=menuitems[i],
								 value=menuitems[i]);
		    whenever private.buttons[count]->press do {
			private.callback($value);
		    }
		}
		private.whenevers[count] := last_whenever_executed();
	    }
	} else {
	    # just do the cleanup and reset
	    private.cleanup();
	    private.helpbutton := private.dws.button(private.localparent, type='menu', text='Help');
	}
	# add the popup help text to the main menu button
	fullhelptext := 'Help Menu';
	if (is_unset(helpitems)) helpitems := as_string([]);
	helpitems[len(helpitems)+1] := 'set the popup help style';
	helpitems[len(helpitems)+1] := 'browse the Reference Manual';
	helpitems[len(helpitems)+1] := 'about AIPS++';
	helpitems[len(helpitems)+1] := 'ask a question';
	helpitems[len(helpitems)+1] := 'report a bug';
	for (helptxt in helpitems) {
	    fullhelptext := spaste(fullhelptext,'\n','- ',helptxt);
	}
	private.dws.popuphelp(private.helpbutton,txt=fullhelptext);

	# the standard items

	# Popup help control
	# should this button label be "Popup help" instead of "?" ?
	# should this use a widgetserver?
	private.popup := private.dws.popupmenu(private.helpbutton,
					       buttonlabel='Popup help style');

	# Reference Manual
	count +:= 1;
	private.buttons[count] := private.dws.button(private.helpbutton, text='Reference Manual');
	whenever private.buttons[count]->press do {
	    ok := private.help('Refman');
	}
	private.whenevers[count] := last_whenever_executed();

	# About AIPS++ ...
	include 'about.g';
	count +:= 1;
	private.buttons[count] := private.dws.button(private.helpbutton, text='About AIPS++ ...');
	whenever private.buttons[count]->press do {
	    ok := about();
	}
	private.whenevers[count] := last_whenever_executed();

	# Ask a question ...
	count +:= 1;
	private.buttons[count] := private.dws.button(private.helpbutton, text='Ask a question ...');
	include 'askme.g';
	whenever private.buttons[count]->press do {
	    ok := askme();
	}
	private.whenevers[count] := last_whenever_executed();

	# Report a bug ...
	count +:= 1;
	private.buttons[count] := private.dws.button(private.helpbutton, text='Report a bug ...');
	whenever private.buttons[count]->press do {
	    ok := bug();
	}
	private.whenevers[count] := last_whenever_executed();
        return T;
    }

    retval := public.reset(menuitems, refmanitems, callback, helpitems);
    if (is_fail(retval)) {
	private.helpbutton := F;
	fail;
    }

    public.done := function() {
      wider private, public;
      private.cleanup();
      val private := F;
      val public := F;
      return T;
    }

    return ref public;
}


const testhelpmenu := function(widgetset=dws) {
    rec := [=];
    rec.cb2count := 0;

    okinc := eval('include \'note.g\'');
    rec.cb1 := function(name) {
	note('test callback 1 called with name :',name, origin='testhelpmenu');
	menuitems[1] := 'Imager';
	refitems[1] := 'Refman:imager';
	menuitems[2] := 'Help menu test 2 - press me';
	refitems[2] := '';
	menuitems[3] := 'Dish';
	refitems[3] := 'Refman:dish';
	rec.hm.reset(menuitems, refitems, rec.cb2,
		     helpitems=['About imager','About dish',
			       'a test help callback']);
    }

    rec.cb2 := function(name) {
	wider rec;
	note('test callback 2 called with name :', name, origin='testhelpmenu');
	if (rec.cb2count == 0) {
	    note('first pass of callback 2 - verifying that fails occur as expected', origin='testhelpmenu');
	    note('Expected errors will be logged as NORMAL status messages');
	    # make a helpmenu with parent not an agent
	    note('trying to make a helpmenu with a parent which is not an agent');
	    ok := helpmenu(F);
	    if (!is_fail(ok)) {
		return throw('expected error in ctor when parent is not an agent did not happen!', 
			     origin='testhelpmenu');
	    } else {
		note(ok, origin='testhelpmenu');
	    }
	    menuitems[1] := 'Imager';
	    menuitems[2] := 'Dish';
	    # menuitems set, but refitems is not
	    note('trying a reset with menuitems set but refmanitems unset', origin='testhelpmenu');
	    ok := rec.hm.reset(menuitems, helpitems=['About imager', 
						     'About dish']);
	    if (!is_fail(ok)) {
		return throw('expected error when menuitems set but refmanitems not set did not happen!',
			     origin='testhelpmenu');
	    } else {
		note(ok, origin='testhelpmenu');
	    }
	    # mismatch in number of items in menuitems and refmanitems
	    refmanitems[1] := 'Refman:imager';
	    note('trying a reset with a mismatch in the number of menuitems and refmanitems', origin='testhelpmenu');
	    ok := rec.hm.reset(menuitems, refmanitems,
			       helpitems='About imager');
	    if (!is_fail(ok)) {
		return throw('expected error due to mismatch between menuitems and refmanitems did not happen!',
			     origin='testhelpmenu');
	    } else {
		note(ok, origin='testhelpmenu');
	    }
	    # callback is set but is not a function
	    refmanitems[2] := 'Refman:dish';
	    note('trying a reset with callback set to something other than a function', origin='testhelpmenu')
	    ok := rec.hm.reset(menuitems, refmanitems, 'hello world');
	    if (!is_fail(ok)) {
		return throw('expected error due to callback being set to something other than a function did not happen!',
			     origin='testhelpmenu');
	    } else {
		note(ok, origin='testhelpmenu');
	    }
	    # empty refmanitems but callback is unset
	    refmanitems[1] := '';
	    note('trying a reset with an empty refmanitem but callback unset', origin='testhelpmenu');
	    ok := rec.hm.reset(menuitems,refmanitems);
	    if (!is_fail(ok)) {
		return throw('expected error due to empty refmanitems and callback being unset did not happen!',
			     origin='testhelpmenu');
	    } else {
		note(ok, origin='testhelpmenu');
	    }
	    rec.cb2count +:= 1;
	} else {
	    note('second pass of callback 2, resetting to default help, end of test', origin='testhelpmenu');
	    rec.hm.reset();
	}
    }

    rec.hf := widgetset.frame(relief='raised',side='right');
    menuitems[1] := 'Dish';
    refitems[1] := 'Refman:dish';
    menuitems[2] := 'Help menu test 1 - press me';
    refitems[2] := '';
    rec.hm := helpmenu(rec.hf,menuitems,refitems,rec.cb1,
		       helpitems=['About dish', 'test callback help'],
		       widgetset=widgetset);
    return rec;
}
