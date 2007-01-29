# logsink.g: helper classes to actually dispose of log messages
# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
# $Id: logsink.g,v 19.2 2004/08/25 02:03:17 cvsmgr Exp $

pragma include once


include 'displaytext.g'
include 'widgetserver.g'
include 'guicomponents.g'
include 'printer.g'


# Conceivably the following could be of general interest.
const errbox := function(widgetset=dws)
{
    self   := [=];
    public := [=];
    self.frame := [=];
    self.gui := F;
    self.count := 0;


    public.addmsg := function(msg)
    {
        wider self;

        if (! have_gui()) {
	    return T;
        }

        if (!is_agent(self.frame) || !self.gui) {
	    self.frame := widgetset.frame(title='SEVERE Errors');
	    self.frame.self := ref self;
            self.tf := widgetset.frame(self.frame,side='left');
            self.text := widgetset.text(self.tf, background='red', width=80,
					relief='sunken');
	    self.text.self := ref self;
            self.gui := T;

            # Add scrollbars
            self.vsb := widgetset.scrollbar(self.tf);
	    self.vsb.self := ref self;
            whenever self.vsb->scroll do {
		$agent.self.text->view($value);
            }
	    whenever self.text->yscroll do {
		$agent.self.vsb->view($value);
            }

            self.bottomframe := widgetset.frame(self.frame, side='left');
            self.msg := widgetset.message(self.bottomframe, '0 errors');
	    self.dismissframe := widgetset.frame(self.bottomframe,
						 side='right');
            self.dismissbutton := widgetset.button(self.dismissframe,
						   'Dismiss', type='dismiss');
            self.dismissbutton.self := ref self;
            whenever self.dismissbutton->press do {
		$agent.self.frame := F;
		$agent.self.count := 0;
            }
	    whenever self.frame->killed do {
                $agent.self.count := 0;
                $agent.self.gui := F;
            }
        }

        self.count +:= 1;
        self.text->append(spaste(msg, '\n\n'), 'end');
        self.msg->text(paste(as_string(self.count), 'errors'));
    }

    return public;
}

const textlogsink := function(show_time = F, show_priority = F, 
			      show_origin = F)
{
    public := [=];    # public functions
    self :=   [=];    # private data and helpers

    self.init := function(show_time, show_priority, show_origin) {
        wider self;
        self.show_time := show_time;
        self.show_priority := show_priority;
        self.show_origin := show_origin;
    }

    self.init(show_time, show_priority, show_origin);

    public.write := function(time,priority,message,origin)
    {
	wider self;
	messages := '';
        where := 0;
	if (self.show_time) {
	    where +:= 1;
	    if (!is_string(time)) time := as_string(time);
            messages[where] := time;
        }
	if (self.show_priority) {
	    where +:= 1;
	    if (!is_string(priority)) priority := as_string(priority);
            messages[where] := priority;
        }
	where +:= 1;
	if (!is_string(message)) message := as_string(message);
	messages[where] := message;
	if (self.show_origin) {
	    where +:= 1;
	    if (!is_string(origin)) origin := as_string(origin);
            messages[where] := origin;
        }
	print messages;
    }

    public.setshow := function(show_time,show_priority,show_origin)
    {
	wider self;
	self.init(show_time, show_priority, show_origin);
    }

    return public;
}

const guilogsink := function(parent=F, height, widths,
			     show, autoscroll, showbuttons,
			     background, level, expr, tzoffset=0.0, id=0,
			     widgetset=dws, title=unset)
{
    public := [=];    # public functions
    self :=   [=];    # private data and helpers
    self.deactivate_callback := F;
    self.printer := printer();
    self.errbox := errbox();
    if (is_string (title)) {
	self.title := title;
    } else {
	self.title := 'Log Messages (AIPS++)';
    }
    self.height := height;
    self.widths := widths;
    self.background := background;
    self.nmessages := 0;
    # Find out which columns to show and in which order.
    # inittext fills in showcoldis, which maps column to column in displaytext.
    self.showcol := [F,F,F,F];
    self.showorder := [0,0,0,0];
    self.showcoldis := [0,0,0,0];
    self.colors := ['blue','DarkGreen','black','black'];
    showv := split (to_lower(show), ', ');
    self.shownames := ['time','priority','message','origin'];
    n := 0;
    for (s in showv) {
	i := (1:4)[self.shownames==s];
	if (len(i) == 1  &&  !self.showcol[i]) {
	    self.showcol[i] := T;
	    n +:= 1;
	    self.showorder[n] := i;
	}
    }
    if (n < 4) {
	for (i in 1:4) {
	    if (!self.showcol[i]) {
		n +:= 1;
		if (i==3) {
		    self.showcol[i] := T;     # message is always shown
		}
		self.showorder[n] := i;
	    }
	}
    }
    self.autoscroll := autoscroll;
    self.showbuttons := showbuttons;
    self.level := level;
    self.expr := expr;
    self.tzoffset := tzoffset;
    self.id := id;
    self.subguis := [=];
    

    # Used for purge, setwidth
    self.num_selector := function(description, most, default)
    {
        f := widgetset.frame(side='top', title='Logger selection');
        r := widgetset.scale(f, default, most, length=300, text=description);
	r->start(0);
        f2 := widgetset.frame(f, side='left');
        ok := widgetset.button(f2, 'OK', type='action');
        ok.name := 'ok';
        f3 := widgetset.frame(f2, side='right');
        cancel := widgetset.button(f3, 'Cancel', type='dismiss');
        cancel.name := 'cancel';
        await cancel->press, ok->press, f->killed;
        if (has_field($agent, 'name')  &&  $agent.name == 'ok') {
	    retval :=  r->value();
	    f := F;
	    return retval;
        }  else {
	    f := F;
	    return -9999;
        }
    }

    self.print_selector := function(nmessages)
    {
	tk_hold();
        topframe := widgetset.frame(side='top',
				    title='AIPS++ Logger print selection');
        r := widgetset.scale(topframe, nmessages, nmessages, length=300,
			     text='Number of rows to PRINT');
	r->start(0);
	colframe := widgetset.frame (topframe, side='left');
	collabel := widgetset.label (colframe, 'Columns to print:');
	timebutton := widgetset.button (colframe, 'Time',
					type='check', relief='flat');
	timebutton->state (self.showcol[1]);
	priobutton := widgetset.button (colframe, 'Priority',
					type='check', relief='flat');
	priobutton->state (self.showcol[2]);
	originbutton := widgetset.button (colframe, 'Origin',
					  type='check', relief='flat');
	originbutton->state (self.showcol[4]);
	printerframe := widgetset.frame (topframe, side='left');
	printerbutton := widgetset.button (printerframe, 'Print',
					   type='radio', relief='flat');
	savebutton := widgetset.button (printerframe, 'Save as',
					type='radio', relief='flat');
	saveentry := widgetset.entry (printerframe);
	saveentry.name := 'ok';
	printstate := T;
	printerbutton->state (T);
	saveentry->disabled (T);
	whenever printerbutton->press do {
	    saveentry->disabled (T);
	    printstate := T;
	}
	whenever savebutton->press do {
	    saveentry->disabled (F);
	    printstate := F;
	}
        f2 := widgetset.frame(topframe, side='left');
        ok := widgetset.button(f2, 'OK', type='action');
        ok.name := 'ok';
        f3 := widgetset.frame(f2, side='right');
        dm := widgetset.button(f3, 'Cancel', type='dismiss');
        dm.name := 'dismiss';
	tk_release();
        await ok->press, saveentry->return, dm->press, topframe->killed;
        rec := [type='dismiss', nrows=0, name=''];
	if (has_field ($agent, 'name')) {
	    rec.type := $agent.name;
	}
	if (rec.type == 'ok') {
	    rec.nrows := r->value();
	    if (rec.nrows == nmessages) {
		rec.nrows := -1;             # all rows
	    }
	    rec.name := saveentry->get();
	    if (printstate) {
		rec.type := 'print';
	    } else {
		rec.type := 'save';
	    }
	}
	rec.colwidth := [-1,-1,-1,-1];
	if (! timebutton->state()) {
	    rec.colwidth[1] := 0;
	}
	if (! priobutton->state()) {
	    rec.colwidth[2] := 0;
	}
	if (! originbutton->state()) {
	    rec.colwidth[4] := 0;
	}
	topframe := F;
	return rec;
    }

    self.doscript := function(nmessages)
    {
	tk_hold();
        topframe := widgetset.frame(side='top',
				    title='AIPS++ Logger script handler');
        r := widgetset.scale(topframe, nmessages, nmessages, length=300,
			     text='Number of rows to SCRIPT');
	r->start(0);
	scriptframe := widgetset.frame (topframe, side='left');
	executebutton := widgetset.button (scriptframe, 'Execute',
					   type='check', relief='flat');
	savebutton := widgetset.button (scriptframe, 'Save as',
					type='check', relief='flat');
	saveentry := widgetset.entry (scriptframe);
	saveentry.name := 'ok';
	executestate := F;
	executebutton->state (F);
	savestate := F;
	savebutton->state (F);
	whenever executebutton->press do {
	    executestate := !executestate;
	}
	whenever savebutton->press do {
	    savestate := !savestate;
	}
        f2 := widgetset.frame(topframe, side='left');
        ok := widgetset.button(f2, 'OK', type='action');
        ok.name := 'ok';
        f3 := widgetset.frame(f2, side='right');
        dm := widgetset.button(f3, 'Cancel', type='dismiss');
        dm.name := 'dismiss';
	tk_release();
        await ok->press, saveentry->return, dm->press, topframe->killed;
        rec := [type='dismiss', nrows=0, name=''];
	if (has_field ($agent, 'name')) {
	    rec.type := $agent.name;
	}
	if (rec.type == 'ok') {
	    rec.nrows := r->value();
	    if (rec.nrows == nmessages) {
		rec.nrows := -1;             # all rows
	    }
	    rec.name := saveentry->get();
	}
	topframe := F;
	if (rec.nrows != 0) {
	    include 'choice.g';
	    include 'os.g';
	    ok := T;
	    if (rec.name != ''  &&  dos.fileexists(rec.name)) {
		answer := choice (paste('Overwrite file',rec.name),
				  ['yes', 'no']);
		if (answer != 'yes'  && answer != 'y') {
		    ok := F;
		}
	    }
	    if (ok) {
		expr := self.expr;
		if (expr[2] != '') {
		    answer := choice(paste('A sort-command is defined which might',
					   'disturb the order of the commands.',
					   'Do you want to sort?',
					   sep='\n'),
				     ['yes', 'no']);
		    if (answer != 'yes'  && answer != 'y') {
			expr[2] := '';
		    }
		}
		rec.name := self.printtofile_callback(rec.nrows, rec.name,
						      0, expr, T);
		# Get full name because glish cannot deal with ~ and $.
		note (paste('Requested logged commands written to script file',
			    rec.name));
		rec.name := dos.fullname (rec.name);
		if (!savestate) {
		    f1 := open(paste (">>", rec.name));
		    write (f1, "shell('rm", rec.name, "');", sep=' ');
		    f1 := F;                       # close file;
		}
		if (executestate) {
		    include rec.name;
		}
	    }
	}
	return T;
    }

    self.init := function(parent) {
        wider self;
        tk_hold();
	
	title := self.title;
	if (self.level > 0) {
	    title := paste (self.title, '   query level', self.level);
	}
	self.topframe := widgetset.frame(parent, title=title, side='top');
        self.menubar := widgetset.frame(self.topframe, side='left', expand='x',
					relief='raised');

        self.leftmenubar := widgetset.frame(self.menubar,side='left',
					    borderwidth=0);
        self.filebutton := widgetset.button(self.leftmenubar, 'File',
					    relief='flat', type='menu');
        self.filemenu := [=];
        self.filemenu['new'] := widgetset.button(self.filebutton,
						 'New Log File...',
						 disabled=T);
        self.filemenu['squery'] := widgetset.button(self.filebutton,
						    'Query...');
        self.filemenu['squery'].self := ref self;
	hlpl := ' Query:   do a selection and/or sort';
        
	self.filemenu['purge'] := widgetset.button(self.filebutton,
						   'Purge...');
	self.filemenu['purge'].self := ref self;
	hlpl := paste(hlpl,
		      ' Purge:   purge the log table',
		      sep='\n');
	if (self.level == 0) {
	    hlpl := paste(hlpl, '(keep last N messages)');
        } else {
	    hlpl := paste(hlpl, '(keep or remove messages)');
            if (self.expr[1] == '') {
		self.filemenu['purge']->disable();
	    }
	}
	self.filemenu['refresh'] := widgetset.button(self.filebutton,
						     'Refresh');
	self.filemenu['refresh'].self := ref self;
	self.filemenu['script'] := widgetset.button(self.filebutton,
						    'Script');
	self.filemenu['script'].self := ref self;
        self.filemenu['print'] := widgetset.button(self.filebutton, 'Print...')
        self.filemenu['print'].self := ref self
	self.filemenu['dismiss'] := widgetset.button(self.filebutton,
						     'Dismiss Window',
						     type='dismiss');
        self.filemenu['dismiss'].self := ref self;
	hlpl := paste(hlpl,
		      ' Refresh: reread the messages',
		      ' Script:  turn commands (messages starting with > )',
                      '          into a script and save and/or execute it',
		      ' Print:   print log messages or save to a file',
		      ' Dismiss: dismiss the widget',
		      sep='\n');
        widgetset.popuphelp (self.filebutton, hlpl,
			     'Menu for various actions', combi=T);

	whenever self.filemenu['purge']->press do {
	    self.dopurge();
        }        
        whenever self.filemenu['squery']->press do {
	    self.doquery (T);
	}
        whenever self.filemenu['script']->press do {
	    nmessages := self.nmessages_callback();
	    self.doscript(nmessages);
	}
        whenever self.filemenu['print']->press do {
	    nmessages := self.nmessages_callback();
	    rec := self.print_selector (nmessages);
            if (rec.type != 'dismiss') {
		include 'choice.g';
		include 'os.g';
		ok := T;
		if (rec.name != ''  &&  dos.fileexists(rec.name)) {
		    answer := choice (paste('Overwrite file',rec.name),
				      ['yes', 'no']);
		    if (answer != 'yes'  && answer != 'y') {
			ok := F;
		    }
		}
		if (ok) {
		    printfile := self.printtofile_callback(rec.nrows,
							   rec.name,
							   rec.colwidth,
							   self.expr, F);
		    if (rec.type == 'save') {
			note (paste('Requested log messages written to file',
				    printfile));
		    } else {
			self.printer.gui(printfile, T, T);
		    }
		}
            }
        }

        self.optionsbutton := widgetset.button(self.leftmenubar, 'Options',
					       type='menu', relief='flat');
        self.optionsmenu := [=];
	self.optionmenu['time'] := widgetset.button(self.optionsbutton,
						    'Show time', type='check');
	self.optionmenu['time'].self := ref self;
	self.optionmenu['time']->state(self.showcol[1]);
	whenever self.optionmenu['time']->press do {
	    if ($agent.self.showcol[1]) {
		$agent.self.showcol[1] := F;
	    } else {
		$agent.self.showcol[1] := T;
	    }
	    $agent.self.inittext();
	}
	self.optionmenu['priority'] := widgetset.button(self.optionsbutton,
							'Show priority',
							type='check');
	self.optionmenu['priority'].self := ref self;
	self.optionmenu['priority']->state(self.showcol[2]);
	whenever self.optionmenu['priority']->press do {
	    if ($agent.self.showcol[2]) {
		$agent.self.showcol[2] := F;
	    } else {
		$agent.self.showcol[2] := T;
	    }
	    $agent.self.inittext();
	}
	self.optionmenu['origin'] := widgetset.button(self.optionsbutton,
						      'Show origin', 
						      type='check');
	self.optionmenu['origin']->state(self.showcol[4]);
	self.optionmenu['origin'].self := ref self;
	whenever self.optionmenu['origin']->press do {
	    if ($agent.self.showcol[4]) {
		$agent.self.showcol[4] := F;
	    } else {
		$agent.self.showcol[4] := T;
	    }
	    $agent.self.inittext();
	}
	self.optionmenu['autoscroll'] := widgetset.button(self.optionsbutton,
							  'Autoscroll', 
							  type='check');
	self.optionmenu['autoscroll']->state(self.autoscroll);
	self.optionmenu['autoscroll'].self := ref self;
	whenever self.optionmenu['autoscroll']->press do {
	    if ($agent.self.autoscroll) {
		$agent.self.autoscroll := F;
	    } else {
		$agent.self.autoscroll := T;
	    }
	    $agent.self.text.setautoscroll ($agent.self.autoscroll);
	}

	self.optionmenu['showbuttons'] := widgetset.button(self.optionsbutton,
							   'Show buttons', 
							   type='check');
	self.optionmenu['showbuttons']->state(self.showbuttons);
	self.optionmenu['showbuttons'].self := ref self;
	whenever self.optionmenu['showbuttons']->press do {
	    if ($agent.self.showbuttons) {
		$agent.self.showbuttons := F;
		$agent.self.bottomframe := F;
	    } else {
		$agent.self.showbuttons := T;
		$agent.self.makebuttons();
	    }
	}

	self.optionmenu['setheight'] := widgetset.button(self.optionsbutton,
							 'Set height');
	self.optionmenu['setheight'].self := ref self;
	whenever self.optionmenu['setheight']->press do {
	    n := self.num_selector ('Height of text panels',
				    80, self.height);
	    if (n > 0) {
		self.height := n;
		self.text.setheight (n);
	    }
	}

	self.widthbutton := widgetset.button(self.optionsbutton,
					     'Set width', type='menu');

        self.widthmenu := [=];
	self.widthmenu['time'] := widgetset.button(self.widthbutton,
						   'Time');
	whenever self.widthmenu['time']->press do {
	    n := self.num_selector ('Width of time column',
				    20, self.widths[1]);
	    if (n > 0) {
		self.widths[1] := n;
		if (self.showcol[1]) {
		    self.text.setcolumnwidth (self.showcoldis[1], n);
		}
	    }
	}
	self.widthmenu['priority'] := widgetset.button(self.widthbutton,
						       'Priority');
	whenever self.widthmenu['priority']->press do {
	    n := self.num_selector ('Width of priority column',
				    10, self.widths[2]);
	    if (n > 0) {
		self.widths[2] := n;
		if (self.showcol[2]) {
		    self.text.setcolumnwidth (self.showcoldis[2], n);
		}
	    }
	}
	self.widthmenu['message'] := widgetset.button(self.widthbutton,
						      'Message');
	whenever self.widthmenu['message']->press do {
	    n := self.num_selector ('Width of message column',
				    120, self.widths[3]);
	    if (n > 0) {
		self.widths[3] := n;
		if (self.showcol[3]) {
		    self.text.setcolumnwidth (self.showcoldis[3], n);
		}
	    }
	}
	self.widthmenu['origin'] := widgetset.button(self.widthbutton,
						     'Origin');
	whenever self.widthmenu['origin']->press do {
	    n := self.num_selector ('Width of origin column',
				    80, self.widths[4]);
	    if (n > 0) {
		self.widths[4] := n;
		if (self.showcol[4]) {
		    self.text.setcolumnwidth (self.showcoldis[4], n);
		}
	    }
	}

	hlpl := paste('Which message fields should be shown?',
		      'Set the height or width of the',
		      ' message fields in the display.',
		      sep='\n');
        widgetset.popuphelp (self.optionsbutton, hlpl,
			     'Options for logger GUI', combi=T);

        self.rightmenubar := widgetset.frame(self.menubar,side='right',
					     borderwidth=0);
	self.helpmenu := widgetset.helpmenu(self.rightmenubar,
					    menuitems='about logger...',
					    refmanitems='Refman:logger',
					    helpitems='about logger');

	if (self.level > 0) {
	    if (strlen(self.expr[1]) > 0) {
		self.qframe := widgetset.frame(self.topframe,
					       side='left', expand='x',
					       borderwidth=0);
		self.qlabel := widgetset.label(self.qframe,
					       'Selected: ');
		self.qmsg := widgetset.entry(self.qframe, fill='x');
		self.qmsg->disabled (T);
		self.qmsg->insert (self.expr[1]);
	    }
	    if (strlen(self.expr[2]) > 0) {
		self.sframe := widgetset.frame(self.topframe,
					       side='left', expand='x',
					       borderwidth=0);
		self.slabel := widgetset.label(self.sframe,
					       'Sorted: ');
		self.smsg := widgetset.entry(self.sframe, fill='x');
		self.smsg->disabled (T);
		self.smsg->insert (self.expr[2]);
	    }
	}

        self.outertextframe := widgetset.frame(self.topframe);

	if (self.showbuttons) {
	    self.makebuttons();
        }

	whenever self.filemenu['dismiss']->press, self.topframe->killed do {
	    self.dodismiss();
        }
	whenever self.filemenu['refresh']->press do {
            self.inittext();
	}

        self.inittext();
        tk_release();
    }

    self.makebuttons := function()
    {
	wider self;
	self.bottomframe:=widgetset.frame(self.topframe,side='left',
					  expand='x');
	self.bottomleftframe:=widgetset.frame(self.bottomframe,
					      side='left',
					      borderwidth=0);
	self.bottomrightframe := widgetset.frame(self.bottomframe,
						 side='right',
						 borderwidth=0);
	self.refreshbutton := widgetset.button(self.bottomleftframe,
					       'Refresh');
	widgetset.popuphelp (self.refreshbutton,
			     'Refresh (reread the messages)');
	self.dismissbutton := widgetset.button (self.bottomrightframe,
						'Dismiss', type='dismiss');
	widgetset.popuphelp (self.dismissbutton,
		   'Dismiss the GUI (but the screen logger remains active)');
	
	whenever self.dismissbutton->press do {
	    self.dodismiss();
	}
	whenever self.refreshbutton->press do {
	    self.inittext();
	}
    }

    self.dodismiss := function()
    {
	wider self;
	self.topframe := F;
	self.parent := F;
	if (len(self.subguis) > 0) {
	    for (i in 1:len(self.subguis)) {
		if (is_record(self.subguis[i])) {
		    self.subguis[i].deactivate();
		}
	    }
	}
	self.subguis := [=];
	if (is_function(self.deactivate_callback)) {
	    self.deactivate_callback(self.id);
	}
    }

    self.dopurge := function()
    {
	if (level == 0) {
	    nmessages := self.nmessages_callback();
	    n := self.num_selector('Number of rows to KEEP',
				   nmessages, as_integer(nmessages/4));
	    if (n >= 0) {
		self.purge_callback(n);
	    }
        } else {
	    include 'choice.g'
	    expr := self.expr[1];
	    answer := choice (paste('Keep or remove messages in this subset',
	                            'obeying expression', expr, sep='\n'),
			      ['keep', 'remove', 'cancel'],
			      ['plain', 'plain', 'dismiss'],
			      default=3);
	    if (answer != 'cancel') {
		if (answer == 'keep') {
		    expr := spaste ('!(', expr, ')');
		}
		self.dodismiss();
		self.purge_callback(0, expr);
	    }
        }
    }

    self.doquery := function(static)
    {
	wider self;
	include 'taqlwidget.g';
	cdesc := [=];
	cdesc.TIME := [valueType='double', istime=T, tzoffset=self.tzoffset];
	cdesc.PRIORITY := [valueType='string'];
	cdesc.PRIORITY.labels := "DEBUGGING NORMAL WARN SEVERE";
	cdesc.MESSAGE := [valueType='string'];
	cdesc.LOCATION := [valueType='string', comment='same as ORIGIN'];
	tw := taqlwidget (cdesc, cansort=static, widgetset=widgetset);
	if (is_fail(tw)) {
	    fail;
	}
	whenever tw->returns do {
	    query := $value.where;
	    sortlist := $value.orderby;
	    if (strlen(query) > 0  ||  strlen(sortlist) > 0) {
		if (len(self.expr) >= 1  &&  strlen(self.expr[1]) > 0) {
		    if (strlen(query) > 0) {
			query := spaste('(', self.expr[1], ')&&(', query, ')');
		    } else {
			query := self.expr[1];
		    }
		}
		if (len(self.expr) >= 2  &&  strlen(self.expr[2]) > 0) {
		    if (strlen(sortlist) > 0) {
			sortlist := spaste(sortlist, ', ', self.expr[2]);
		    } else {
			sortlist := self.expr[2];
		    }
		}
		expr[1] := query;
		expr[2] := sortlist;
		id := 1 + len(self.subguis);
		shownm := self.shownames[self.showorder] \
                                          [self.showcol[self.showorder]];
		ag := self.query_callback (self.height, self.widths, shownm,
					   self.autoscroll, self.showbuttons,
					   self.background,
					   self.level, expr, id, widgetset,
					   self.title);
		ag.set_deactivate_callback (self.deact_subgui);
		ag.set_nmessages_callback (ag.nmessages);
		self.subguis[id] := ag;
	    }
	}
    }        

    self.deact_subgui :=function(id)
    {
	wider self;
	self.subguis[id] := F;
    }

    self.inittext := function()
    {
	wider self;
        tk_hold();
        val self.textframe := widgetset.frame(self.outertextframe,
					      side='left');
	ncol := 0;
	widths := 0;
	colors := '';
	hcolor := '';
	rowseeend := F;

	for (i in self.showorder) {
	    if (self.showcol[i]) {
		ncol +:= 1;
		self.showcoldis[i] := ncol;
		if (i == 3) {
		    widths[ncol] := self.widths[i];  # only message expandable
		} else {
		    widths[ncol] := -self.widths[i];
		}
		if (i == 2) {
		    hconfig[ncol] := 'red';     # highlighted priority in red
		} else {
		    hconfig[ncol] := ''
		}
		if (i == 1  &&  self.widths[1] < 20) {
		    rowseeend[ncol] := T;            # show last part of time
		} else {
		    rowseeend[ncol] := F;
		}
		colors[ncol] := self.colors[i];
	    }
	}

	self.text := display_multi_column_text(ncol, widths, self.height,
					       self.background,
					       colors, hconfig,
					       [highwarn='LightYellow',
						highsevere='Yellow'],
					       rowseeend,
					       parent_frame = self.textframe,
					       widgetset=widgetset);
	self.text.setautoscroll (self.autoscroll);

        if (has_field(self, 'refill_callback') && 
			is_function(self.refill_callback)) {
	    # Initialize the number of messages.
	    self.nmessages := 0;
	    # Write the contents of the log table into the text widget.
	    # We get back a vector of (possibly long) strings. For each
	    # string the priority is the same.
	    # Note that the regex looks for NORMAL (and not for WARN/SEVERE),
	    # because NORMAL occurs much more often, so it is faster.
            local t,p,m,o;
	    res := self.refill_callback(t,p,m,o,expr=self.expr,concat=T);
	    if (is_fail(res)) {
		res := F;
	    }
	    if (res  &&  len(p) > 0) {
		for (i in 1:len(p)) {
		    if ((p[i] ~ m/NORMAL|DEBUGGING/)) {
			self.dowrite (t[i], p[i], m[i], o[i], '', F);
		    } else if ((p[i] ~ m/SEVERE/)) {
			self.dowrite (t[i], p[i], m[i], o[i], 'highsevere', F);
		    } else {
			self.dowrite (t[i], p[i], m[i], o[i], 'highwarn', F);
		    }
		    self.nmessages +:= len(split(p[i],'\n'));
		}
	    }
	}
        tk_release();
	self.text.seeend();
    }

    self.init(parent);


    public.isactive := function()
    {
	wider self;
	return is_agent(self.topframe);
    }

    public.dismiss := function()
    {
	self.dodismiss();
    }

    public.nmessages := function()
    {
	return self.nmessages;
    }

    public.activate := function()
    {
	wider self;
        global system;

        if (has_field(system, 'output')) {
	    if (has_field(system.output, 'ilog')) {
		system.output.ilog::use_gui := T;
            }
        }
        if (has_field(system, 'output')) {
	    if (has_field(system.output, 'olog')) {
		system.output.olog::use_gui := T;
            }
        }

##	if (! is_agent(self.topframe)) {
##	    self.init();
##	}
##	return is_agent(self.topframe);
    }

    public.deactivate := function()
    {
	if (self.level == 0) {
	    global system;
	    if (has_field(system, 'output')) {
		if (has_field(system.output, 'ilog')) {
		    system.output.ilog::use_gui := F;
		}
	    }
	    if (has_field(system, 'output')) {
		if (has_field(system.output, 'olog')) {
		    system.output.olog::use_gui := F;
		}
	    }
        }
	wider self;
	self.topframe := F;
	return T;
    }

    
    public.write := function(time,priority,message,origin)
    {
	wider self;
	self.write(time,priority,message,origin);
    }
    

    self.write := function(time,priority,message,origin,emphasize_severe=F,
                           countnl=T)
    {
        highlight := '';
	if (priority=='SEVERE') {
            highlight := 'highsevere';
	    if (is_function(emphasize_severe)) {
		emphasize_severe(spaste(as_string(time), ':\n', message));
	    }
        } else if (priority == 'WARN') {
	    highlight := 'highwarn';
        }
	self.dowrite(time,priority,message,origin,highlight,countnl);
    }

    self.dowrite := function(time,priority,message,origin,highlight,countnl)
    {
	messages := '';
        where := 0;
	for (i in self.showorder) {
	    if (self.showcol[i]) {
		where +:= 1;
		if (i==1) {
		    if (!is_string(time)) time := as_string(time);
		    messages[where] := time;
		} else if (i==2) {
		    if (!is_string(priority)) priority := as_string(priority);
		    messages[where] := priority;
		} else if (i==3) {
		    if (!is_string(message)) message := as_string(message);
		    messages[where] := message;
		} else {
		    if (!is_string(origin)) origin := as_string(origin);
		    messages[where] := origin;
		}
	    }
        }
        self.text.write(messages,countnl,highlight);
    }

    public.inittext := function(all=F)
    {
	if (public.isactive()) {
	    self.inittext();
	    if (all  &&  len(self.subguis) > 0) {
		for (i in 1:len(self.subguis)) {
		    if (is_record(self.subguis[i])) {
			self.subguis[i].inittext(all);
		    }
		}
	    }
	}
    }

    public.setshow := function(show_time,show_priority,show_origin)
    {
	wider self;
        self.showcol[1] := show_time;
        self.showcol[2] := show_priority;
        self.showcol[4] := show_origin;
	self.optionmenu['time']->state(self.showcol[1]);
	self.optionmenu['priority']->state(self.showcol[2]);
	self.optionmenu['origin']->state(self.showcol[4]);
	if (public.isactive()) self.inittext();
    }

    public.set_deactivate_callback := function(callback)
    {
	wider self
	if (is_function(callback)) {
	    self.deactivate_callback := callback;
	} else {
	    fail 'guilogsink.set_deactivate_callback must be given a function';
	}
    }

    public.set_refill_callback := function(callback)
    {
	wider self;
	if (is_function(callback)) {
	    self.refill_callback := callback;
	} else {
	    fail 'guilogsink.set_refill_callback must be given a function';
	}
        self.inittext();
    }

    public.set_nmessages_callback := function(callback)
    {
	wider self;
	if (is_function(callback)) {
	    self.nmessages_callback := callback;
	} else {
	    fail 'guilogsink.set_nmessages_callback must be given a function';
	}
    }

    public.set_purge_callback := function(callback)
    {
	wider self
	if (is_function(callback)) {
	    self.purge_callback := callback;
	} else {
	    fail 'guilogsink.set_purge_callback must be given a function';
	}
    }

    public.set_printtofile_callback := function(callback)
    {
	wider self
	if (is_function(callback)) {
	    self.printtofile_callback := callback;
	} else {
	    fail 'guilogsink.set_printtofile_callback must be given a function';
	}
    }

    public.set_query_callback := function(callback)
    {
	wider self
	if (is_function(callback)) {
	    self.query_callback := callback;
	} else {
	    fail 'guilogsink.set_query_callback must be given a function';
	}
    }

    return public
}
