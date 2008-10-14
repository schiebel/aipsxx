# textwindow.g: general-purpose text-window object.

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
# $Id: textwindow.g,v 19.2 2004/08/25 02:21:32 cvsmgr Exp $

#---------------------------------------------------------

pragma include once
# print 'include textwindow.g  h01sep99'

include 'guicomponents.g';	# ....?
# include 'popuphelp.g';		#
include 'menubar.g';
# include 'guimisc.g';		# filechooser()
include 'textformatting.g'

#=========================================================
test_textwindow := function () {
    private := [=];
    public := [=];

    public.tw := textwindow('test_textwindow', launch=F)
    whenever public.tw.agent->message do {
	print 'message:',$value;
    }
    whenever public.tw.agent->close do {
	print 'textwindow close event';
    }
    public.tw.launch();
    public.tw.standardmenu();

    include 'list.g';						# only if needed
    public.list := list('tw-items');				# define a list
    whenever public.list.agent->message do {
	public.tw.message(paste($value));
    }
    public.list.gui(public.tw.menuframe());			# 
    public.list.append(public.tw,'textwindow-record');
    public.list.append(public.tw.menubar(),'menubar-record');

    defrec := public.tw.menubar().defrecinit('align','test'); 
    defrec.paramchoice := ". left right centre =";
    defrec.action := ref function(align='left') {
	ss := "ab.=c de=fg.tj h=g =g gt.ein=ns aiui.ygau=yufxvf"
	cc := public.tw.lineup(ss, nchar=20, align=align, header='header');
	ss := [' ',' ',' ',ss,' '];
	public.tw.columns(cc,ss);
    }
    public.tw.menubar().makemenuitem(defrec);			# 

    defrec := public.tw.menubar().defrecinit('columns1','test'); 
    defrec.action := ref function(dummy=F) {
	s1 := public.tw.lineup([1:10], align='left', header='[1:10]');
	s2 := public.tw.lineup([-5:5], align='right', header='[-5:5]');
	s3 := public.tw.lineup([-10:1]/3, align='.', header='[-10:1]/3');
	public.tw.columns(s1,s2,s3);
    }
    public.tw.menubar().makemenuitem(defrec);		# 

    defrec := public.tw.menubar().defrecinit('columns2','test'); 
    defrec.action := ref function(dummy=F) {
	s1 := [1:10];
	s2 := [-5:5];
	s3 := [-10:1]/3;
	s4 := complex(s3,-s3/2);
	s5 := rep("g h i",10); s5[5] := 'prrt';
	public.tw.columns(s1,s2,s3,s4,s5);
    }
    public.tw.menubar().makemenuitem(defrec);		# 

    defrec := public.tw.menubar().defrecinit('pattern','test');
    defrec.paramchoice := "%8.1d %8.4d %8.6d %+8.3d %-8.3d"
    defrec.prompt := 'give pattern' 
    defrec.action := ref function(pattern=F) {
	vv := [-5:5]/3;
	ss := public.tw.format(vv, pattern=pattern)
	public.tw.append(paste(' \n pattern=',pattern));
	for (i in ind(ss)) {
	    cc := split(ss[i],'')
	    s := spaste(ss[i],'  n=',len(cc),' v=',vv[i]);
	    public.tw.append(s);
	}
    }
    public.tw.menubar().makemenuitem(defrec);		# 

    defrec := public.tw.menubar().defrecinit('pprec','test');
    defrec.paramchoice := [0:10]
    # defrec.prompt := 'give pattern' 
    defrec.action := ref function(pprec=F) {
	vv := [-5:5]/3;
	ss := public.tw.format(vv, pprec=pprec)
	public.tw.append(paste(' \n pprec=',pprec));
	for (i in ind(ss)) {
	    cc := split(ss[i],'')
	    s := spaste(ss[i],'  n=',len(cc),' v=',vv[i]);
	    public.tw.append(s);
	}
    }
    public.tw.menubar().makemenuitem(defrec);

    defrec := public.tw.menubar().defrecinit('label','test');
    defrec.paramchoice := public.tw.label();
    defrec.prompt := 'give new label' 
    public.tw.menubar().makemenuitem(defrec, public.tw.label);

    colors := "white black grey lightgrey red blue green yellow";
    colors := [colors,"tan magenta khaki cyan pink"];
    colors := [colors,'lime green','medium turquoise','green yellow'];
    colors := [colors,'medium blue','green orchid'];

    defrec := public.tw.menubar().defrecinit('background','color');
    defrec.paramchoice := colors;
    # defrec.prompt := 'give new background color' 
    public.tw.menubar().makemenuitem(defrec, public.tw.background); 

    defrec := public.tw.menubar().defrecinit('foreground','color');
    defrec.paramchoice := colors;
    # defrec.prompt := 'give new foreground color' 
    public.tw.menubar().makemenuitem(defrec, public.tw.foreground); 

    rr := random(10)
    rr /:= max(rr)
    rr -:= sum(rr)/len(rr);
    public.tw.columns(rr,rr+10,rr*10,rr*100,rr/10)

    return ref public.tw;
};


#=========================================================
textwindow := function (label='textwindow', launch=T) {
    private := [=];
    public := [=];

    private.label := label;			# input argument
    private.launch_now := launch;

    private.init := function() {
	wider private;
	private.background := 'white';		# textwidget background color
	private.foreground := 'black';		# textwidget foreground color
	private.twf := textformatting();	# text-formatting services
	private.parentframe := F;
	private.guiframe := F;
	private.menubar := F;
	private.statusline := F;		# see public.message()
	private.messagebox := F;		# see public.message()
	private.filename := spaste(private.label,'.gls');  # save/restore
	private.printcommand := 'pri';		# aips++ default
	private.clear();			# create/clear textbuffer	
	if (private.launch_now) {
	    private.launch();			# launch standalone gui
	}
	return T;
    }

#=============================================================
# Public interface:
#=============================================================

    public.agent := create_agent();
    whenever public.agent->* do {
	s := paste('textwindow event:',$name,$value);
	# print s;
    }
    whenever public.agent->message do {
	private.message($value);
    }
    public.message := function (text) {
	return private.message(text);
    }

    public.standardmenu := function (optional=F) {
    	return private.standardmenu (optional);
    }
    public.standardmenuitem := function (name) {
    	return private.standardmenuitem (name);
    }
    public.append := function (ss, tmargin=0, bmargin=0, prefix=' ') {
	return private.append (ss, tmargin, bmargin, prefix);
    }
    public.get := function () {
	return private.get ();
    }
    public.clear := function () {
	return private.clear ();
    }
    public.launch := function (ref parentframe=F) {
	return private.launch (parentframe);
    }
    public.menuframe := function () {
	return ref private.menuframe;
    }
    public.menubar := function () {
	return ref private.menubar;
    }
    public.textformatting := function () {
	return ref private.twf;
    }
    public.close := function () {
	return private.close ();
    }
    public.save := function (filename=F, txt=F) {
	return private.save (filename, txt);
    }
    public.saveas := function (filename=F, txt=F) {
    	return private.saveas (filename, txt);
    }
    public.restore := function (filename=F, clear=T) {
    	return private.restore (filename, clear);
    }
    public.print := function (filename=F, txt=F) {
    	return private.print (filename, txt);
    }
    public.open_file := function (name='dummy', option='read') {
	return private.open_file (name, option);
    }
    public.close_file := function (ref file=F) {
    	return private.close_file (file);
    }
    public.printcommand := function (printcommand=F) {
    	return private.setprintcommand (printcommand);
    }
    public.filename := function (filename=F) {
    	return private.setfilename (filename);
    }
    public.label := function (label=F) {
    	return private.setlabel (label);
    }
    public.background := function (color=F) {
    	return private.setbackground (color);
    }
    public.foreground := function (color=F) {
    	return private.setforeground (color);
    }

# Text-formatting services (temporary):

    public.format := function (vv, pattern=F, pprec=F) {
    	return private.twf.format (vv, pattern, pprec);
    }
    public.lineup := function (vv, nchar=F, align=F, header=F, pattern=F) {
    	return private.twf.lineup (vv, nchar, align, header, pattern);
    }
    public.columns := function (...) {
    	s := private.twf.columns (...);
	private.append(s);
	return T;
    }



#=======================================================================
#=======================================================================
# Private functions:
#=======================================================================

#-----------------------------------------------------------------------
# Getting text in and out:

    private.append := function(sv, tmargin=0, bmargin=0, prefix=' ') {
	wider private;
	if (tmargin>0) sv := [rep(' ',tmargin),sv];	# top-margin
	if (bmargin>0) sv := [sv,rep(' ',bmargin)];	# bottom_margin
	for (sss in sv) {			# line-by-line
	    ss := split(sss,'\n');		# split at
	    for (s in ss) { 
		sapp := spaste(prefix,s,'\n');
		if (is_agent(private.guiframe)) {
    	    	    private.textWidget->append (sapp);
		} else {
		    private.textbuffer := spaste(private.textbuffer,sapp);
		}
	    }
	}
	return T;
    }

    private.get := function() {
	if (is_agent(private.guiframe)) {
    	    return private.textWidget->get('start','end');
	} else {
	    return private.textbuffer;
	}
    }

    private.clear := function() {
	wider private;
	private.textbuffer := '\n';
	if (is_agent(private.guiframe)) {
    	    private.textWidget->delete ('start','end');
	}
	return F;
    }

#---------------------------------------------------------------------
# Print a hardcopy of (a subset of) the log:
 
    private.setprintcommand := function (printcommand=F) {
	wider private;
	if (is_string(printcommand)) {
	    if (printcommand=='check') {
	    	s := paste('current printcommand=',private.printcommand);
	    } else {
	    	private.printcommand := printcommand;
	    	s := paste('printcommand set to:',private.printcommand);
	    }
	    private.message(s);
	}
	return private.printcommand;
    }

    private.print := function (filename='textwindow.text', txt=F) {
	file := public.open_file(filename,'write');
	if (is_fail(file)) fail(file);			# problem
	if (is_boolean(txt)) txt := public.get(); 	# window-text
	write(file, paste('\n',txt));
	public.close_file(file);
	shell(paste(private.printcommand, filename));	# print the file
	shell(paste('rm -f', filename));		# remove the file
	s := spaste('printed window-text')
	s := spaste(s,' (printcommand=\'',private.printcommand,'\')');
	private.message(s);
	return T;
    }

    private.open_file := function (name='dummy', option='read') {
	if (option=='read') option := '<';
	if (option=='write') option := '>';
	if (option=='append') option := '>>';
	file := open(s := paste(option,name));
	if (!is_file(file)) {
	    print s := paste('open_file problem:',s); 
	    fail(s);
	} 
	# print 'open file:',file; 
	return ref file;
    }

    private.close_file := function (ref file) {
	# print 'close file:',file; 
	file := F;
	return T;
    }


#------------------------------------------------------------------------
# Save/restore in a file:

# NB: These functions are passed to menubar.standardmenuitem!!!! 

    private.saveas := function (filename=F, txt=F) {
    	defrec := public.menubar().defrecinit('filename','...'); 
	defrec.prompt := 'give file-name';
	defrec.help := 'help: file-name';
    	defrec.paramchoice := [filename,'dummy'];	# temporary
    	defrec.action := ref function(filename) {
	    print 'filename=',filename,'txt=',txt;
	    private.save(filename, txt);	# still knows txt?
    	}
    	# public.menubar().userentry(defrec);	# problems...?

	private.save(filename, txt);		# .....
    }

    private.save := function (filename=F, txt=F) {
	filename := private.checkfilename(filename);
	if (is_boolean(filename)) return F;	# problem
	s := paste('save to file:',filename);
	private.message(s);
	file := public.open_file(filename,'write');
	if (is_fail(file)) fail(file);		# problem
	if (is_boolean(txt)) txt := public.get(); # window-text
	write(file, paste(txt));
	public.close_file(file);
	s := paste('saved to file:',filename);
	private.message(s);
	return T;
    }

    private.read := function (filename=F, clear=T) {
	private.restore('filechooser', clear=clear);	#.....?
    }

    private.restore := function (filename=F, clear=T) {
	filename := private.checkfilename(filename);
	if (is_boolean(filename)) return F;	# problem
	s := paste('restore from file:',filename);
	private.message(s);
	file := public.open_file(filename,'read');
	if (is_fail(file)) fail(file);
	if (clear) public.clear();		# clear window
	txt := ' ';
	while(<file>) txt := paste(txt,_);
	public.append(txt);			# 
	public.close_file(file);
	s := paste('restored from file:',file);
	private.message(s);
	return T;
    }

    private.checkfilename := function (file=F) {
	wider private;
	if (!is_string(file)) {
	    file := private.filename;			# default
	} else if (file=='filechooser') {
	    fc := filechooser();
	    #...........................
	    file := fc.guiReturns;
    	    if (!is_string(file)) {
	    	s := paste('no action, file=',file);
	    	private.message(s);
		return F;
	    }
	}
	ss := split(file,'.');				# 
	if (len(ss)==0) {
	    file := spaste(private.label,'.gls');	# repair....?
	} else if (len(ss)==1) {
	    file := spaste(ss[1],'.gls');		# add extension
	} else {
	    # any further checks?
	}
	private.filename := file;			# keep for later
	return file;
    }

    private.setfilename := function (filename=F) {
	wider private;
	if (is_string(filename)) {
	    private.filename := filename;
	    s := private.label;
	    s := paste(s,': default filename set to:',private.filename);
	    private.message(s);
	}
	return private.filename;
    }



#-----------------------------------------------------------------
# Launch a textwindow gui, either standalone or embedded:

    private.launch := function (ref parentframe=F) {
	wider private, public;
	# private.close(notify=F);		# remove any existing one...

	private.parentframe := parentframe;
	if (!is_agent(parentframe)) {
	    s := paste(private.label);
	    private.guiframe := frame(title=s) 
	    private.standalone := T;		# stand-alone gui
	} else {
	    private.guiframe := parentframe;	# use given frame 
	    private.standalone := F;		# embedded gui		
	}
	whenever private.guiframe->killed do {	# 
	    public.agent -> close();		# to outside world
	    # NB: calling .close() here causes Glish to exit (!?)
	}

	# Neil's suggestions (..?)
	# tk_hold()
	# private.guiframe -> unmap()	# make invisible
	# tk_release()
	# ..... make all the Tk widgets ......
	# private.guiframe -> map()	# shows all in one go

	private.menuframe := frame(private.guiframe, expand='x');
	private.menubar := menubar(private.menuframe);
	whenever private.menubar.agent -> message do {
	    s := $value;
	    print 'textwindow: menubar message event:',s;	
	    private.message(s);
	}
	private.menubar.savefile(private.filename);

	private.maketextwidget(private.guiframe);
	private.makestatusline(private.guiframe);
	whenever private.menubar.agent -> cleanup do {
	    # private.message(' ');		# clear message
	}
	return T;
    }

    private.setlabel := function(label=F) {
	wider private;
	if (is_string(label)) {
	    private.label := label;
	    s := paste('label set to:',private.label);
	    if (is_agent(private.guiframe)) {
		if (is_boolean(private.parentframe)) {
		    private.guiframe -> title(private.label);
		}
	    }
	    # private.message(s);
	}
	return private.label;
    }


#----------------------------------------------------------------------------
# Make a status-line underneath:

    private.makestatusline := function (ref guiframe) {
	wider private;
	private.statusframe := frame(guiframe, side='right', expand='x');
	private.dismissbutton := button(private.statusframe,'dismiss',
					background='orange');
	private.statusline := status_line(private.statusframe);

	whenever private.dismissbutton -> press do {private.close()}
	return T;
    }

    private.message := function (text) {
	if (is_record(private.statusline)) {
	    # print 'tw.message(statusline):',text
	    private.statusline.show(text);
	} else if (is_agent(private.messagebox)) {
	    private.messagebox -> text(text);
	} else {
	    s := spaste('textwindow(',private.label,'):');
	    # print paste(s,text);
	    print text;
	}
    }


#----------------------------------------------------------------------------
# Close the textwindow in an organised manner:

    private.close := function(notify=T) {
	wider private;
	if (is_record(private.menubar)) private.menubar.close();	# for cleanup
	private.clear();			# clear textbuffer
	private.statusline := F;		# remove status_line
	if (is_agent(private.guiframe)) {
	    private.guiframe -> unmap();
	}
    	val private.guiframe := F;		# remove textwindow frame
	if (notify) public.agent -> close();	# notify outside world
	return T;
    }


#-----------------------------------------------------------------------------
# Make text-widget:

    private.maketextwidget := function (ref guiframe, cols=50, rows=12) {
	wider private;

  	defaults := [=];
  	defaults.normal_font := spaste ('-adobe-courier-medium-r-normal--',12,'-*');
  	defaults.bold_font   := spaste ('-adobe-courier-bold-r-normal--',12,'-*');

    	private.topframe := frame (guiframe, 
		side='left', borderwidth=0);
    	private.textWidget := text (private.topframe, 
		relief='sunken', wrap='none',
                background='white', width=cols, height=rows,
                font=defaults.normal_font);
    	private.verticalScrollbar := scrollbar (private.topframe);

    	private.bottomframe := frame (guiframe,
		side='right',borderwidth=0,
                expand='x',borderwidth=0);
    	private.cornerPad := frame (private.bottomframe,
		expand='none', width=23, height=23, relief='groove');
    	private.horizontalScrollbar := scrollbar(private.bottomframe,
		orient='horizontal');
  
    	whenever private.verticalScrollbar->scroll, 
	         private.horizontalScrollbar->scroll do {
    		private.textWidget->view ($value);
        }
    	whenever private.textWidget->yscroll do {
    		private.verticalScrollbar->view ($value);
    	}
    	whenever private.textWidget->xscroll do {
    		private.horizontalScrollbar->view ($value);
    	}
	private.append(private.textbuffer);		# ....?
	return T;
    }

    private.setbackground := function(color=F) {
	wider private;
	if (is_string(color)) {
	    private.background := color;
	    s := paste('background color set to:',private.background);
	    if (is_agent(private.guiframe)) {
		private.textWidget -> background(private.background);
	    }
	    private.message(s);
	}
	return private.background;
    }

    private.setforeground := function(color=F) {
	wider private;
	if (is_string(color)) {
	    private.foreground := color;
	    s := paste('foreground color set to:',private.foreground);
	    if (is_agent(private.guiframe)) {
		private.textWidget -> foreground(private.foreground);
	    }
	    private.message(s);
	}
	return private.foreground;
    }

#--------------------------------------------------------------
# Predefined menu-items:

    private.standardmenu := function (optional=F) {
	ss := "read save saveas restore print printcommand";
	ss := [ss,"clear"];
	ss := [ss,"dismiss"]; 			#.....optional?
	ss := [ss,"popupmenu"];			# ...?
	ss := [ss,"aips Glish: Refman: web"];
	ss := [ss,"glishelp bug_report"];
	if (is_string(optional)) ss := [ss,optional];
	for (s in ss) private.standardmenuitem(s);
	return T;
    }

    private.standardmenuitem := function (name) {
	if (name=='save') {
    	    m := private.menubar.standardmenuitem(name, private.save);
	} else if (name=='saveas') {
    	    m := private.menubar.standardmenuitem(name, private.saveas);
	} else if (name=='open' || name=='read') {
    	    m := private.menubar.standardmenuitem(name, private.read);
	} else if (name=='restore') {
    	    m := private.menubar.standardmenuitem(name, private.restore);
	} else if (name=='print') {
    	    m := private.menubar.standardmenuitem(name, private.print);
	} else if (name=='printcommand') {
    	    m := private.menubar.standardmenuitem(name,
						private.setprintcommand);
	} else if (any(name=="close dismiss exit")) {
    	    m := private.menubar.standardmenuitem(name, private.close);
	} else if (name=='clear') {
    	    m := private.menubar.standardmenuitem(name, private.clear);
	} else {
    	    m := private.menubar.standardmenuitem(name);
	}
	return ref m;
    }


#=========================================================
# Finished. Initialise and return the public interface:

    public.private := function() {
	return ref private;
    }

    private.init();
    return ref public;

};				# closing bracket of textwindow
#=========================================================

# tw := test_textwindow();		# run test-routine




