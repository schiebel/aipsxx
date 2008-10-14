# buttonscript.g: Tool for genarating a script from button presses:
# Copyright (C) 1996,1997,1998,1999
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
# $Id: buttonscript.g,v 19.2 2004/08/25 02:12:00 cvsmgr Exp $

#---------------------------------------------------------	
# J.E.Noordam, june 1998

pragma include once
print 'include buttonscript.g'

include 'textwindow.g'


#=========================================================
test_buttonscript := function () {
    bscr := buttonscript();
    for (i in [1:5]) {
    	bscr.verbatim(paste('line',i))
    }
    bscr.gui();
    bscr.comment('comment 1');
    return ref bscr;
};

#=========================================================
const buttonscript := function (name='unnamed') {
    private := [=];
    public := [=];

    private.name := name;		# name of the script

    private.init := function() {
	wider private;
	private.messagebox := F;	# ...?
	private.tw := F;		# text-window (gui)
	private.setname();		
	private.reset();
	return T;
    }


#=========================================================
# Public interface:

    public.agent := create_agent();	# communication

    public.reset := function () {
    	return private.reset();
    }
    public.finish := function () {
    	return private.finish();
    }
    public.verbatim := function (text=F) {
    	return private.verbatim (text);
    }
    public.comment := function (text=F) {
    	return private.comment (text);
    }
    public.funcall := function (funcname=F, pp=F) {
    	return private.funcall (funcname, pp);
    }
    public.name := function (name=F) {
    	return private.setname (name);
    }
    public.gui := function(parentframe=F) {
	return private.launch();
    }
    public.close := function() {
	if (is_record(private.tw)) private.tw.close();
    }


#==========================================================
#==========================================================
# 
    private.message := function (text) {
	if (is_record(private.tw)) {
	    private.tw.message(text);		# text-window statusline
	} else {
	    print paste(text);			# print
	}
    }

    private.text := function (text) {
	if (is_record(private.tw)) {
	    private.tw.append(text);		# text-window itself
	} else {
	    print paste(text);			# print
	}
    }


    private.setname := function (name=F) {
	wider private;
	if (is_string(name)) private.name := name;
	s := split(private.name,'.');
	if (len(s)==1) {
	    private.name := spaste(private.name,'.g');
	} else if (len(s)==2) {
	    cc := split(s[2],'');		# characters
	    if (len(cc)==1 & cc[1]=='g') {
	    } else {
	    	private.name := spaste(s[1],'.g');
	    }
	} else {
	    private.name := spaste('unnamed.g');
	} 

	if (is_record(private.tw)) {
	    s := paste('buttonscript: ',private.name);
	    private.tw.label(s);
	    private.tw.filename(private.name);
	    private.show();
	}
	return private.name;			# always
    }


#==========================================================
# Make the buttonscript gui:

     private.launch := function () {
	wider private;
	if (is_record(private.tw)) {
 	    private.tw.close();			# remove any existing
	}
    	private.tw := textwindow('buttonscript')
    	whenever private.tw.agent->message do {
	    # print 'message:',$value;
    	}
    	whenever private.tw.agent->close do {
	    # print 'textwindow close event';
	    val private.messagebox := F;
    	}

	private.makefilemenu();
	private.makeviewmenu();
	private.makeeditmenu();
	private.maketestmenu();

	defrec := private.tw.menubar().defrecinit('buttonscript','help');  
	private.tw.menubar().makemenuitem(defrec, private.help_buttonscript);

	private.setname();    
	return T;
    }

#-----------------------------------------------------------------
# Various help-functions:

    private.help_buttonscript := function() {
	s := 'help_buttonscript'		# temporary
	private.tw.menubar().givehelp(s);
    }


#-----------------------------------------------------------------

    private.makefilemenu := function() {
	menu := 'file';
    	private.tw.standardmenuitem('open');    
    	private.tw.standardmenuitem('save');    
    	private.tw.standardmenuitem('saveas');    
    	private.tw.standardmenuitem('dismiss');    
	return T;
    }

#-----------------------------------------------------------------

    private.makeviewmenu := function() {
	menu := 'view';
    	private.tw.standardmenuitem('print');    
    	private.tw.standardmenuitem('printcommand');    
    	private.tw.standardmenuitem('clear');    
	return T;
    }


#-----------------------------------------------------------------

    private.makeeditmenu := function() {
	wider private;
	menu := 'edit';
	
	defrec := private.tw.menubar().defrecinit('init',menu); 
	defrec.shorthelp := '(re-)initialise the script';
	defrec.caution := 'are you sure?'
	private.tw.menubar().makemenuitem(defrec, private.reset);

	defrec := private.tw.menubar().defrecinit('name',menu); 
	defrec.shorthelp := 'give the name of the script';
	defrec.prompt := 'give the name of the script';
	defrec.paramchoice := private.name;
	private.tw.menubar().makemenuitem(defrec, private.setname);

	defrec := private.tw.menubar().defrecinit('finish',menu); 
	defrec.shorthelp := 'finish the script';
	private.tw.menubar().makemenuitem(defrec, private.finish);
    }

#-----------------------------------------------------------------

    private.maketestmenu := function() {
	wider private;
	menu := 'test';
	
	defrec := private.tw.menubar().defrecinit('verbatim',menu); 
	defrec.paramchoice := "The rain in Spain"; 
	private.tw.menubar().makemenuitem(defrec, private.verbatim);

	defrec := private.tw.menubar().defrecinit('comment',menu); 
	defrec.paramchoice := "The rain in Spain"; 
	private.tw.menubar().makemenuitem(defrec, private.comment);

	defrec := private.tw.menubar().defrecinit('funcall',menu); 
	defrec.action := function() {
	    pp := [=];
	    pp.a := 'xyz'
	    pp.b := [T,F];
	    pp.c := [1:10];
	    private.funcall('object.method',pp);
	}
	private.tw.menubar().makemenuitem(defrec);
    }

#==================================================================
# Actual script functions:
#==================================================================


    private.reset := function () {
	wider private;
	private.scribuf := ' ';
	private.show();
    }

    private.show := function () {
	wider private;
	private.scribuf[1] := ' ';
	private.scribuf[2] := paste('# Glish script:',private.name);
	private.scribuf[3] := ' ';
	if (is_record(private.tw)) {
	    private.tw.clear();
	    for (i in [1:len(private.scribuf)]) {
	    	private.tw.append(private.scribuf[i]);
	    }
	}
    }

    private.finish := function () {
	private.addline('finish off');
    }

# Add a line to the script:

    private.addline := function (text) {
	wider private;
	n := 1 + len(private.scribuf);
	private.scribuf[n] := text;
	if (is_record(private.tw)) {
	    private.tw.append(text);
	}
	return n;
    }

#-------------------------------------------------------------------
# A verbatim script-line:

    private.verbatim := function (text=F) {
	if (is_string(text)) {
	    s := spaste('    ',text);
	} else {
	    s := paste('type not recognised:',type_name(text));
	}
	return private.addline(s)
    }

#-------------------------------------------------------------------
# comment:

    private.comment := function (text=F) {
	if (is_string(text)) {	
	    n := private.addline(' ');		# blank line
    	    for (t in text) {			# may be string vector
	    	ss := split(t,'\n');		# split along any <CR>'s
		for (s in ss) {
	    	    n := private.addline(paste('#',s));
		}
	    }
	    s := ' ';				# blank line
	} else {
	    s := paste('type not recognised:',type_name(text));
	}
	return private.addline(s);
    }

#-------------------------------------------------------------------
# Function call:

    private.funcall := function (funcname=F, pp=F) {
	s := spaste(funcname,'(');
	if (is_record(pp)) {
	    pnames := field_names(pp);
	    np := 0;
	    for (pname in pnames) {
	    	if (pname=='funcname') next;		# ignore
	    	np +:= 1;
	    	if (np>1) s := spaste(s,', ');
	    	if (is_string(pp[pname])) {
		    s1 := spaste('\'',pp[pname],'\'');
	    	} else if (is_numeric(pp[pname])) {
		    s1 := spaste(pp[pname]);
	    	} else {
		    return F;
	    	}
	    	s := spaste(s,pname,'=',s1);
	    }
	}
	s := spaste('    ',s,')');
	return private.addline(s)
	return T;
    }

#=========================================================
# Finished. Initialise and return the public interface:

    private.init();
    return public
};		# closing bracket of make_mans_aux
#=========================================================


# bscr := test_buttonscript();		# run test-routine














