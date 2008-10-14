# tracelogger.g: general-purpose tracing/logging object.

# Copyright (C) 1996,1997,1998,1999,2000
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

#---------------------------------------------------------

pragma include once
# print 'include tracelogger.g  h01sep99';

include 'textwindow.g'
include 'guicomponents.g'	# 

#=========================================================
const test_tracelogger := function () {
    private := [=];
    tlg := tracelogger('test_tracelogger')
    whenever tlg.agent->message do {
	print 'message:',$value;
    }
    # tlg.gui();				# make standalone gui

    tw := textwindow('test_tracelogger');
    tw.standardmenu();
    tlg.attach(tw);

    for (i in [1:10]) {
	s := paste(i,':',time());
	tlg.note(i,s);
    }
    tlg.note(1,'string with line-breaks:');
    tlg.note(2,'abc \n cde \n fgh');  
    tlg.note(1,'string-vector:');
    tlg.note(3,"123 456 789");
    tlg.note(1,'record:');
    aa := [=]; aa.name := 'test-record'; aa.data := [-3:2]
    tlg.note(3,aa);
    tlg.note(3,3.14);
    tlg.note(3,[-15:-5]);

    return ref tlg;
};


#=========================================================
const tracelogger := function (label='tracelogger') {
    private := [=];
    public := [=];

    private.label := label;			# input argument

    private.init := function() {
	wider private;
	private.tw := F;			# text-window
	private.filename := 'tracelogger.gls';	# use label....?
	private.showlevel := 1;			# display-level
	private.loglevel := 10000;		# accept-level
	private.loginit();			# initialise log
	return T;
    }

#=============================================================
# Public interface:
#=============================================================

    public.agent := create_agent();

    whenever public.agent->message do {
	s := paste('tracelogger message:',$value);
	public.note(0,$value);
	if (is_record(private.tw)) {
	    private.tw.message(s);
	} else {
	    print s;
	}
    }

# Initialise the circular log with a certain size (nr of lines): 

    public.init := function (size=F) {
	private.loginit(size);		# initialise log
	if (is_record(private.tw)) {
	    public.show()		# display log
	}	
	s := paste('buffer initialised, size=',private.logrec.size);
	public.agent->message(s);
    }

# Gui functions:

    public.gui := function () {
    	return private.gui();
    }
    public.hidegui := function () {
	print 'tracelogger.hidegui(): dummy function..'
    }

    public.guibutton := function(name, ref menu, caption=F) {
    	return private.guibutton (name, menu, caption);
    }

    public.attach := function(ref tw) {
    	return private.attach (tw);
    }

#-------------------------------------------------------------------
# Make a note in the log (if level>private.loglevel):

    public.note := function (level=1, str=F) {	# note the order!
	if (level>private.loglevel) return F;	# level too high
	private.lognote(level, str);		# write into log
	if (is_record(private.tw)) {		# visible
	    ss := private.format(private.logrec.imax, level);
	    if (is_string(ss)) {		# only if string 
		for (s in ss) {			# line-by-line
	    	    private.tw.append(s);
		}
	    }
	}
	return T;
    }

    public.loglevel := function (level=F) {
	wider private;
	if (is_integer(level)) {		# if argument given
	    private.loglevel := max(0,level);	# adjust loglevel
	    s := paste('loglevel set to:',private.loglevel);
	    public.agent->message(s);
	}
	return private.loglevel;		# return current value
    }



#-----------------------------------------------------------------------
# Show (a subset of) the contents of the log: 

    public.show := function (level=F, clear=T) {
	wider private;
	if (!is_record(private.tw)) {
	    return F;
	}
	if (clear) private.tw.clear();	
	public.showlevel(level);		# adjust if specified
	ss := private.extract(private.showlevel);
	for (s in ss) {				# line-by-line
	    private.tw.append(s);
	}
	return T;
    }

    public.showlevel := function (level=F) {
	wider private;
	if (is_integer(level)) {		# if argument given
	    private.showlevel := max(0,level);	# adjust showlevel
	    s := paste('showlevel set to:',private.showlevel);
	    public.agent->message(s);
	}
	return private.showlevel;		# return current value
    }


#------------------------------------------------------------------------
# Save/restore the log in a file:

    public.save := function (file=F) {
	if (!is_string(file)) file := private.filename;
	write_value(private.logrec, file);
	s := paste('saved to file:',file);
	public.agent->message(s);
	return T;
    }

    public.restore := function (file=F) {
	wider private;
	if (!is_string(file)) file := private.filename;
	private.logrec := read_value(file);
	s := paste('restored from file:',file);
	public.agent->message(s);
	public.show();
	return T;
    }

#---------------------------------------------------------------------
# Make a stand-alone gui (textwindow with menubar) for the tracelogger:

    private.gui := function () {
	private.textwindow();

    	private.tw.menubar().standardmenuitem('save', public.save); 
    	private.tw.menubar().standardmenuitem('restore', public.restore);    
    	private.tw.standardmenuitem('print');    
    	private.tw.standardmenuitem('printcommand');    
    	private.tw.menubar().standardmenuitem('dismiss');    

    	private.tw.standardmenuitem('clear');    
	private.guibutton('show','view')
	private.guibutton('status','view')

	private.guibutton('level','logger')
	private.guibutton('init','logger')

	private.guibutton('help','help')

	public.show(1);				# show at level=1
	return T;
    }

# Attach an existing text-window to the trace-logger, and
# attach gui-buttons to a separate menu called 'logger':

    private.attach := function (ref tw) {
	private.textwindow(tw);

	menu := 'logger';
	private.guibutton('save', menu)
	private.guibutton('restore', menu)

	private.guibutton('clear', menu)
	private.guibutton('level', menu)
	private.guibutton('init', menu)

	private.guibutton('show', menu)
	private.guibutton('status', menu)

	private.guibutton('help', menu)
	return T;
    }

# Add the specified button to the given button-agent (menu):

    private.guibutton := function(name, ref menu, caption=F) {
	wider private;

	if (is_boolean(caption)) caption := name;

	if (name=='show') {
    	    defrec := private.tw.menubar().defrecinit(name, menu); 
	    defrec.text := 'show log';
	    defrec.shorthelp := 'show the contents of the log-buffer'; 
	    vv := [0:(private.get_nplmax()-1)];	 
	    defrec.paramchoice := [vv,10,20,50];
	    defrec.prompt := 'level lower than'
    	    private.tw.menubar().makemenuitem(defrec, public.show);    

	} else if (name=='status') {
    	    defrec := private.tw.menubar().defrecinit(name, menu); 
	    defrec.shorthelp := 'show the log status'; 
    	    private.tw.menubar().makemenuitem(defrec, private.logstatus);    

	} else if (name=='help') {
    	    defrec := private.tw.menubar().defrecinit(name, menu); 
    	    private.tw.menubar().makemenuitem(defrec, private.loghelp);    

	} else if (name=='level') {
    	    defrec := private.tw.menubar().defrecinit(name, menu); 
	    defrec.shorthelp := 'only accept notes with level <= n'; 
	    vv := [0:(private.get_nplmax()-1)];	 
	    defrec.paramchoice := [vv,10,20,50];
	    defrec.prompt := 'level lower than'
    	    private.tw.menubar().makemenuitem(defrec, public.loglevel);    

	} else if (name=='init') {
    	    defrec := private.tw.menubar().defrecinit(name, menu); 
	    defrec.shorthelp := 'initialise the log with size..'; 
	    vv := private.logrec.size;		# current size
	    defrec.paramchoice := [vv,200,500,1000,2000];
	    defrec.prompt := 'size (lines)'
	    defrec.caution := 'present contents will be lost'
    	    private.tw.menubar().makemenuitem(defrec, public.init);    

	} else if (name=='save') {
    	    defrec := private.tw.menubar().defrecinit(name, menu); 
	    defrec.shorthelp := 'save the log in a file'; 
    	    private.tw.menubar().makemenuitem(defrec, public.save);    

	} else if (name=='restore') {
    	    defrec := private.tw.menubar().defrecinit(name, menu); 
	    defrec.shorthelp := 'restore the log from a file'; 
    	    private.tw.menubar().makemenuitem(defrec, public.restore);    

	# } else if (name=='separ') {		# separator

	} else {
	    s := paste('guibutton: not recognised:',name);
	    # public.message(s);
	    fail(s);
	}
	return T;
    }

# Define the text-window and set up event-handlers:

    private.textwindow := function (ref tw=F) {
	wider private;
	if (is_record(private.tw)) {
	    private.tw.close();			# just in case
	}
	if (is_record(tw)) { 
	    private.tw := tw;
	} else {
	    s := paste('tracelogger of:', private.label);
	    private.tw := textwindow(s);
	}

    	whenever private.tw.agent->message do {
		# print 'message:',$value;
    	}
    	whenever private.tw.agent->close do {
		# print 'textwindow close event';
    	}
	return T;
    }



#==========================================================
#==========================================================
# Log-buffer functions:
#==========================================================

    private.loghelp := function() {
	s := paste('tracelogger help-text');
	messagebox(s);
    }


    private.loginit := function (size=F) {
	wider private;
	if (is_boolean(size)) size := 750;	# default size
	size := max(10,size);			# ...?

	private.logrec := [=];
	private.logrec.label := private.label;
	private.logrec.imin := 0;		# lowest line nr
	private.logrec.imax := 0;		# highest line nr
	private.logrec.size := size;		# size (circular)
	private.logrec.mess := ' ';		# logging messages
	private.logrec.level := [];		# message levels
	private.logrec.t0 := time();		# ref time (sec)
	private.logrec.trel := [];		# relative time

	private.initcount();			# init counter
	private.lognote(0,' ');			# dummy 1st entry
	return T;
    }

# The log buffer is circular:

    private.logptr := function (index) {
	ptr := 1 + max(0,index) % private.logrec.size;
	# print 'index=',index,'-> ptr=',ptr;
	return ptr;
    }

# Print the status of the log-buffer:

    private.logstatus := function() {
	s := ' ';
	s := paste(s,'\n log-buffer',private.logrec.label)
	imin := private.logrec.imin;
        s := paste(s,'\n  - imin=',imin,'->',private.logptr(imin))
	imax := private.logrec.imax;
        s := paste(s,'\n  - imax=',imax,'->',private.logptr(imax))
        s := paste(s,'\n  - size=',private.logrec.size,imax-imin)
	messagebox(s);
	return T;	
    }

# Write the given note (mess) into the log, and do bookkeeping:

    private.lognote := function (level, mess=F) {
	wider private;
	if (is_string(level)) {
	    level := 1;				# just in case
	}

	private.logrec.imax +:= 1;		# increment
	imin := 1 + private.logrec.imin - private.logrec.size
	private.logrec.min := max(0,imin)
	ptr := private.logptr(private.logrec.imax);# new slot

	private.logrec.level[ptr] := level;
	private.logrec.trel[ptr] := time() - private.logrec.t0;
	if (is_string(mess)) {
	    nss := len(mess);
	    if (nss>1) {
		s := spaste('[n=',nss,'] ',mess)
	    } else {
		s := spaste(mess)
	    }
	} else {
	    s := spaste('[',type_name(mess),'] ',mess)
	}
	private.logrec.mess[ptr] := s;

	private.count(level);			# update counter
	return T;
    }

# Count log-messages by level:

    private.initcount := function() {
	wider private;
	private.logrec.nplmax := 3;		# minimum level..?
	private.logrec.npl := rep(0,private.logrec.nplmax);
	return T;
    }

    private.get_nplmax := function() {		# used in gui()
	return private.logrec.nplmax;
    }

    private.count := function (level) {
	wider private;
	levelplus := 1 + level;
	nplmax := private.logrec.nplmax;
	if (nplmax<levelplus) {
	    private.logrec.npl[(nplmax+1):levelplus] := 0;
	    private.logrec.nplmax := levelplus;
	}
	private.logrec.npl[levelplus] +:= 1;	# increment
	return T;
    }


# Format the message at the indicated log position (index):

    private.format := function (index, maxlevel=F) {
	ptr := private.logptr(index);
	level := private.logrec.level[ptr];
	if (is_integer(maxlevel)) {		# maxlevel specified
	    if (level>maxlevel) return F;	# not required
	}
	s1 := ' ';
	if (level>0) s1 := array('..',level);
	mess := private.logrec.mess[ptr];
	ss := split(mess,'\n');			# make string vector
	nss := len(ss);
	for (i in [1:nss]) {
	    if (i==1) {
		ss[i] := spaste(s1,' ',ss[i]);
	    } else {
		ss[i] := spaste(s1,'+',ss[i]);
	    }
	}
	return ss;
    }

# Extract the logged lines up to the given level from the log;
# Return a string-vector;

    private.extract := function (level) {
	sss := ' ';
	n := 0;
	sss[n+:=1] := paste('Tracelog of:',private.logrec.label);
	sss[n+:=1] := paste('Showing all notes with level <=',level);
	sss[n+:=1] := paste('Available notes per level:',
			private.logrec.npl[1:private.logrec.nplmax]);
	ii := [max(1,private.logrec.imin):private.logrec.imax]
	sss[n+:=1] := ' ';
	for (i in ii) {
	    ss := private.format(i, level);	# 
	    if (is_string(ss)) {		# F if level too high
		for (s in ss) {
		   sss[n+:=1] := s;		# include
		}
	    }
	}
	# s := paste(s,'\n Total processing time=',dt,'sec');
	return sss;
    }



#=========================================================
# Finished. Initialise and return the public interface:

    private.init();
    return public;

};				# closing bracket of tracelogger
#=========================================================

# tlg := test_tracelogger();		# run test-routine



