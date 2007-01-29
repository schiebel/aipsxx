# glishelp.g: short on-line overview/help on Glish.
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
# $Id: glishelp.g,v 19.2 2004/08/25 02:14:15 cvsmgr Exp $

#---------------------------------------------------------

pragma include once
print 'include glishelp.g'

include 'textwindow.g'		#


#=========================================================
glishelp := function () {
    private := [=];
    public := [=];

    private.init := function() {
	wider private;
	private.margin := 20;		# used in private.item()
	private.lasthelp := ' ';	
        private.launch();		# launch the gui
	return T;
    }

#=============================================================
# Public interface:
#=============================================================

# None (?);

#=============================================================
#=============================================================
# Private functions:
#=============================================================
#-----------------------------------------------------------------
# Launch a standalone glishelp text-window:

    private.launch := function () {
	wider private;
	title := 'glishelp  (quick reference)'
	private.tw := textwindow(title);
	private.tw.background('yellow');
	private.tw.standardmenu();		# printing only?
	private.menu_syntax();
	private.menu_functions();
	private.menu_tk();
	private.menu_util();
	private.menu_misc();
	private.menu_prog();
	return T;
    }

#-----------------------------------------------------------------
# Syntax menu:

    private.menu_syntax := function () {
	menuname := 'syntax';

	defrec := private.tw.menubar().defrecinit('expr',menuname);
	private.tw.menubar().makemenuitem(defrec, private.syntax_expr); 

	defrec := private.tw.menubar().defrecinit('regex',menuname);
	private.tw.menubar().makemenuitem(defrec, private.syntax_regex); 

	defrec := private.tw.menubar().defrecinit('arrays',menuname);
	private.tw.menubar().makemenuitem(defrec, private.syntax_arrays); 

	defrec := private.tw.menubar().defrecinit('records',menuname);
	private.tw.menubar().makemenuitem(defrec, private.syntax_records); 

	defrec := private.tw.menubar().defrecinit('events',menuname);
	private.tw.menubar().makemenuitem(defrec, private.syntax_events); 

	defrec := private.tw.menubar().defrecinit('files',menuname);
	private.tw.menubar().makemenuitem(defrec, private.syntax_files); 

	private.tw.menubar().makemenuseparator(menuname);#------------------ 

	defrec := private.tw.menubar().defrecinit('all syntax',menuname);
	private.tw.menubar().makemenuitem(defrec, private.syntax); 
    }

    private.syntax := function(clear=T) {
	s := private.superheader('Glish syntax', clear);
	private.syntax_expr();
	private.syntax_regex();
	private.syntax_arrays();
	private.syntax_records();
	private.syntax_events();
	private.syntax_files()
    }

    private.syntax_expr := function() {
	s := private.header('Glish expressions');
	private.tw.append(s)
    }
    private.syntax_arrays := function() {
	s := private.header('Glish arrays');
	private.tw.append(s)
    }
    private.syntax_records := function() {
	s := private.header('Glish records');
	private.tw.append(s)
    }
    private.syntax_events := function() {
	s := private.header('Glish events');
	private.tw.append(s)
    }


    private.syntax_files := function() {
	s := private.header('Glish file I/O', margin=40);
	private.separ(s, 'writing (Perl-like):');
	private.item(s,'x := open(\'> filename\')', 
		comment='open for writing (overwrite)'); 
	private.item(s,'x := open(\'>> filename\')', 
		comment='open for writing (append)'); 
	private.item(s,'write(x, 1, 2, [a=1:3, b=\"a bb ccc\"])', 
		comment='write one line (string!)'); 
	private.item(s,'write(x, 1, 2, [a=1:3, b=\"a bb ccc\"], sep=\'\@\')', 
		comment='item separator'); 
	private.item(s,'write(x)', 
		comment='write out a newline char (important for read!)'); 
	private.item(s,'fprintf(x,\'%x\',[76:83])', 
		comment='use of fprintf to convert and write'); 

	private.separ(s);
	private.separ(s, 'reading (Perl-like):');
	private.item(s,'x := open(\'< filename\')', 
		comment='open for reading'); 
	private.item(s,'read(x,40,\'c\')', 
		comment='read 40 characters'); 
	private.item(s,'read(x)', 
		comment='read one line (incl newline char)'); 
	private.item(s,'while (line := read(x)) print line;', 
		comment='read and print all lines'); 
	private.item(s,'while (<x>) print _', 
		comment='<x> is equivalent to: _ := read(x)'); 
	private.item(s,'while (<x>) print ~ s/\\n$//', 
		comment='chop off the newline char'); 
	# private.item(s,'while (_ := read(x)) print _ ~ s/\\n$//', 
	#	comment='equivalent to above'); 
	private.item(s,'s := x', 
		comment='equivalent to s := read(x)?'); 

	private.separ(s);
	private.item(s,'type_name(open(\'< filename\'))', 
		'type_name(open(\'> glishhelp.tmp\'))'); 
	private.item(s,'stat(filepath)', 
		comment='returns info about path'); 
	private.item(s,'is_asciifile(filepath, b=100)', 
		comment='checks the first b bytes'); 

	private.separ(s);
	private.item(s,'fprintf(file,pattern,...)', 
		comment='write to file, see also above'); 
	private.item(s,'s := sprintf(pattern,...)', 
		comment='write to string'); 
	private.item(s,'printf(pattern,...)', 
		comment='write to screen'); 

	private.separ(s);
	private.item(s,'write_value(filename,v)', 
		comment='v can be any type'); 
	private.item(s,'v := read_value(filename)', 
		comment='v can be any type'); 
	private.tw.append(s)
    }



# Notes for regex examples:
# - Each backslash (\) has to be preceded with another backslash (\\) for eval!

    private.syntax_regex := function() {
	s := private.header('Glish regular expressions (like in Perl)', 
		margin=30);

	private.item(s,'type_name()', 'type_name(m/c/)');

	private.separ(s)
	private.separ(s,'matching:')
	private.item(s,'x ~ m/[range]/', '\'abcd\' ~ m/c/');
	private.item(s,'x ~ m/[range]/', '\'abcd\' ~ m/bc/');
	private.item(s,'x ~ m/[range]/', '\'abcd\' ~ m/ca/');
	private.item(s,'x ~ m/^[range]/', '\'abcd\' ~ m/^c/');
	private.item(s,'x ~ m/[range]$/', '\'abcd\' ~ m/cd$/');

	private.separ(s)
	private.separ(s,'substitution:')
	private.item(s,'x := x ~ s/[range]/new/', 
		'\'abcd\' ~ s/c/C/');
	private.item(s,'x := x ~ s/[range]/new/g', 
		'\'abcdc\' ~ s/c/C/g');
	private.item(s,'x := x ~ s/[range]$/new/', 
		'\'((abcd))\' ~ s/\\)$//');
	private.item(s,'x := x ~ s/^[range]/new/', 
		'\'((abcd))\' ~ s/^\\(/P/');

	private.tw.append(s)
    }



#-----------------------------------------------------------------
# Utilities:


    private.menu_util := function () {
	menuname := 'utilities';

	defrec := private.tw.menubar().defrecinit('inspection',menuname);
	private.tw.menubar().makemenuitem(defrec, private.util_inspection); 

	defrec := private.tw.menubar().defrecinit('containers',menuname);
	private.tw.menubar().makemenuitem(defrec, private.util_container); 

	private.tw.menubar().makemenuseparator(menuname);#------------------ 

	defrec := private.tw.menubar().defrecinit('all utilities',menuname);
	private.tw.menubar().makemenuitem(defrec, private.util); 
    }

    private.util := function(clear=T) {
	s := private.superheader('Glish utilities', clear);
	private.util_inspection();
	private.util_container();
	# private.template_object();
    }

    private.util_inspection := function() {
	s := private.header('Inspection of Glish variables');
	private.separ(s,'Interactive inspection');
	private.item(s,'inspect(v)', comment='v can be any Glish type');
	private.tw.append(s)
    }
    private.util_container := function() {
	s := private.header('Containers for Glish variables');
	private.item(s,'list(label=\'xxx\')');
	private.tw.append(s)
    }

#-----------------------------------------------------------------
# Programming:


    private.menu_prog := function () {
	menuname := 'prog';

	defrec := private.tw.menubar().defrecinit('object template',menuname);
	private.tw.menubar().makemenuitem(defrec, private.prog_template_object); 

	defrec := private.tw.menubar().defrecinit('help template',menuname);
	private.tw.menubar().makemenuitem(defrec, private.prog_template_help); 

	defrec := private.tw.menubar().defrecinit('help2html',menuname);
	private.tw.menubar().makemenuitem(defrec, private.prog_help2html); 

	private.tw.menubar().makemenuseparator(menuname);#------------------ 

	defrec := private.tw.menubar().defrecinit('all prog',menuname);
	private.tw.menubar().makemenuitem(defrec, private.prog); 

	private.tw.menubar().makemenuseparator(menuname);#------------------ 

	defrec := private.tw.menubar().defrecinit('execute',menuname);
	private.tw.menubar().makemenuitem(defrec, private.prog_execute); 
    }

    private.prog := function(clear=T) {
	s := private.superheader('Glish programming', clear);
	private.prog_template_object(clear=F);
	private.prog_template_help(clear=F);
	private.prog_help2html();
    }

    private.prog_execute := function() {
	gfile := 'glishelp_execute.g'
	private.tw.save(gfile);
	# print 'include \'',gfile,'\'';
	include gfile;
    }
    private.prog_help2html := function() {
	s := private.header('Documenting Glish programs');
	private.separ(s,'Create file \'myfile.help\' (use template)');
	private.separ(s,'- help2tex myfile.help > myfile.htex');
	private.separ(s,'- latex2html myfile.htex -split 0');
	private.separ(s,'Inspect the result with Netscape');
	private.tw.append(s)
    }


    private.prog_template_help := function(clear=T) {
	# NB: Better to read from file?
	if (clear) private.tw.clear();		# clear textwindow first!
	s := paste(' \n ');
	s := paste(s,'\n# Template for a Glish help file');
	s := paste(s,'\n# Save it in a named .help file, and edit it.');
	s := paste(s,'\n# (...to be elaborated...).');
	private.tw.append(s)
    }

    private.prog_template_object := function(clear=T) {
	# NB: Better to read from file?
	if (clear) private.tw.clear();		# clear textwindow first!
	s := paste(' \n ');
	s := paste(s,'\n# Template for a Glish closure object');
	s := paste(s,'\n# Save it in a named .g file, and edit it.');
	s := paste(s,'\n# (...to be elaborated...).');
	private.tw.append(s)
    }
 
#-----------------------------------------------------------------
# Misc:

    private.menu_misc := function () {
	menuname := 'misc';

	defrec := private.tw.menubar().defrecinit('system',menuname);
	private.tw.menubar().makemenuitem(defrec, private.misc_system); 

	defrec := private.tw.menubar().defrecinit('test/demo',menuname);
	private.tw.menubar().makemenuitem(defrec, private.misc_test); 

	private.tw.menubar().makemenuseparator(menuname);#------------------ 

	defrec := private.tw.menubar().defrecinit('all misc',menuname);
	private.tw.menubar().makemenuitem(defrec, private.misc); 

	private.tw.menubar().makemenuseparator(menuname);#------------------ 

	defrec := private.tw.menubar().defrecinit('mini-manual',menuname);
	private.tw.menubar().makemenuitem(defrec, private.all); 
    }

    private.misc := function(clear=T) {
	s := private.superheader('miscellaneous Glish subjects', clear);
	private.misc_system()
    }

    private.all := function(doprint=F) {
	private.tw.clear();			# clear textwindow first!
	private.syntax (clear=F);
	private.functions (clear=F);
	private.tk (clear=F);
	private.util (clear=F);
	private.misc (clear=F);
	private.prog (clear=F);
	if (doprint) private.tw.print();	# print the 'full manual'
    }


    private.misc_test := function() {
	s := private.header('Test functions');

	private.include(s,'randomnumbers.g',F);
	private.item(s,'randomnumberstest()');
	private.item(s,'randomnumbersdemo()');

	private.tw.append(s)
    }

    private.misc_system := function() {
	s := private.header('Glish system settings (\'print system\')');
	# s := paste(s,'\n system.path.key=',system.path.key);
	# s := paste(s,'\n system.path.bin=',system.path.bin);
	s := paste(s,'\n system.path.include:');
	for (i in [1:len(system.path.include)]) {
	    s := paste(s,'\n',system.path.include[i]);
	}
	private.tw.append(s)
    }



#-----------------------------------------------------------------
# Tk:

    private.menu_tk := function () {
	menuname := 'tk';

	defrec := private.tw.menubar().defrecinit('frame',menuname);
	private.tw.menubar().makemenuitem(defrec, private.tk_frame); 

	defrec := private.tw.menubar().defrecinit('button',menuname);
	private.tw.menubar().makemenuitem(defrec, private.tk_button); 

	private.tw.menubar().makemenuseparator(menuname);#------------------ 

	defrec := private.tw.menubar().defrecinit('progress',menuname);
	private.tw.menubar().makemenuitem(defrec, private.gui_progress); 

	defrec := private.tw.menubar().defrecinit('combobox',menuname);
	private.tw.menubar().makemenuitem(defrec, private.gui_combobox); 

	private.tw.menubar().makemenuseparator(menuname);#------------------ 

	defrec := private.tw.menubar().defrecinit('all tk',menuname);
	private.tw.menubar().makemenuitem(defrec, private.tk); 
    }

    private.tk := function(clear=T) {
	s := private.superheader('aspects of Glish/Tk', clear);
	private.tk_frame()
	private.tk_button()
    }

    private.tk_frame := function() {
	s := private.header('Glish/Tk frames');
	private.tw.append(s)
    }
    private.tk_button := function() {
	s := private.header('Glish/Tk buttons');
	private.tw.append(s)
    }

    private.gui_progress := function() {
	private.tw.clear()
	private.remove_demoframe();
	s := private.header('Progress widget example');
	private.tw.append(s);
	private.gline('include \'progress.g\'');
	s := 'bar := progress(-100,100,\'main title\',\'subtitle\')'
	private.gline(s);
	private.gline('bar.update(-75)');
	private.gline('bar.update(-50)');
	private.gline(' ', bmargin=1);
	private.prog_execute();
	private.showhelp('progress');
	private.showrecord(bar, 'bar');
    }

    private.remove_demoframe := function () {
	# if (is_agent(f)) val f := F;		# remove earlier...!?
    }

    private.gui_combobox := function() {
	private.tw.clear();
	private.remove_demoframe();
	s := private.header('Combobox widget example');
	private.tw.append(s);
	private.gline('include \'combobox.g\'');
	private.gline('f := frame(title=\'combobox\')');
	s := 'cb := combobox(f,\'colors\',\"red green blue yellow\")'
	private.gline(s);
	private.gline('cb.select(2)');
	private.gline('print cb.get(\'selected\')');
	private.gline('cb.insert(\'orange\')');
	private.gline('print cb.get(0,\'end\')');
	private.prog_execute();
	private.showhelp('combobox');
	private.showrecord(cb, 'cb');
	return T;
    }

    private.gline := function (txt) {
	s := spaste('\n ',txt);
	private.tw.append(s);
    }

    private.showrecord := function (ref rec, name=F) {
	private.tw.append(' ');
	s := private.tw.textformatting().showrecord(rec, name);
	s := paste('Public interface of record ',name,':\n',s); 
	private.tw.append(s, tmargin=0, bmargin=0, prefix='# ');
	private.tw.append(' ');	
	return T;
    }

    private.showhelp := function (name) {
	wider private;
	include 'aips2help.g';
	private.tw.append(' ');	
	s1 := help('progress');		# 1st time: object overview
	s2 := help('progress');		# 2nd time: constructor
	s := spaste('Result of typing: help(\'',name,'\')'); 
	private.tw.append(s, tmargin=0, bmargin=0, prefix='# ');
	private.tw.append(s1, tmargin=1, bmargin=1, prefix='# ');
	private.tw.append(' ');	
	s := paste(s,'again');
	private.tw.append(s, tmargin=0, bmargin=0, prefix='# ');
	private.tw.append(s2, tmargin=1, bmargin=1, prefix='# ');
	private.tw.append(' ');
	private.lasthelp := name;	
	return T;
    }

#-----------------------------------------------------------------
# Functions:

    private.menu_functions := function () {
	menuname := 'functions';

	defrec := private.tw.menubar().defrecinit('math',menuname);
	private.tw.menubar().makemenuitem(defrec, private.func_math); 

	defrec := private.tw.menubar().defrecinit('fitting',menuname);
	private.tw.menubar().makemenuitem(defrec, private.func_fitting); 

	defrec := private.tw.menubar().defrecinit('matrix ops',menuname);
	private.tw.menubar().makemenuitem(defrec, private.func_matrix); 

	private.tw.menubar().makemenuseparator(menuname);#------------------ 

	defrec := private.tw.menubar().defrecinit('arrays',menuname);
	private.tw.menubar().makemenuitem(defrec, private.func_array); 

	defrec := private.tw.menubar().defrecinit('records',menuname);
	private.tw.menubar().makemenuitem(defrec, private.func_record); 

	defrec := private.tw.menubar().defrecinit('strings',menuname);
	private.tw.menubar().makemenuitem(defrec, private.func_string); 

	defrec := private.tw.menubar().defrecinit('types',menuname);
	private.tw.menubar().makemenuitem(defrec, private.func_type); 

	defrec := private.tw.menubar().defrecinit('functions',menuname);
	private.tw.menubar().makemenuitem(defrec, private.func_function); 

	defrec := private.tw.menubar().defrecinit('agents',menuname);
	private.tw.menubar().makemenuitem(defrec, private.func_agent); 

	defrec := private.tw.menubar().defrecinit('miscellaneous',menuname);
	private.tw.menubar().makemenuitem(defrec, private.func_misc); 

	private.tw.menubar().makemenuseparator(menuname);#------------------ 

	defrec := private.tw.menubar().defrecinit('all functions',menuname);
	private.tw.menubar().makemenuitem(defrec, private.functions); 
    }

    private.functions := function(clear=T) {
	s := private.superheader('Glish functions', clear);
	private.func_math();
	private.func_fitting();
	private.func_matrix();
	private.func_array();
	private.func_record();
	private.func_string();
	private.func_type();
	private.func_function();
	private.func_agent();
	private.func_misc();
    }

    private.func_misc := function() {
	s := private.header('Miscellaneous Glish functions');
	private.item(s,'eval(Glish expression string)');
	private.separ(s,'NB: Any variables in the expression must be global');
	private.tw.append(s)
    }
    private.func_function := function() {
	s := private.header('Functions associated with Glish functions');
	private.item(s,'f := func[tion](args) {body}');
	private.item(s,'nth_arg(n,...)');
	private.item(s,'num_args(...)');
	private.tw.append(s)
    }
    private.func_agent := function() {
	s := private.header('Functions associated with Glish events');
	private.item(s,'a := create_agent()');
	private.item(s,'a := client(name)');
	private.item(s,'type_name()','type_name(create_agent())');
	private.item(s,'is_agent()','is_agent(create_agent())');
	private.tw.append(s)
    }

    private.func_type := function() {
	s := private.header('Type conversion functions');
	private.item(s,'as_boolean(z)', 'as_boolean(1)');
	private.item(s,'as_byte(z)', 'as_byte(3)');
	private.item(s,'as_short(z)', 'as_short(-5)');
	private.item(s,'as_integer(z)', 'as_integer(-3.14)');
	private.item(s,'as_float(z)', 'as_float(3)');
	private.item(s,'as_double(z)', 'as_double(3+2i)');
	private.item(s,'as_complex(z)', 'as_complex(-5)');
	private.item(s,'as_dcomplex(z)', 'as_dcomplex(7.3)');
	private.item(s,'as_string(z)', 'as_string(-987.456)');
	private.item(s,'paste(z)', 'paste(-987.456)');
	private.item(s,'complex(x,y)', 'complex(2,3)');
	private.separ(s);
	private.item(s,'type_name(z)', 'type_name(-9.8)');
	private.item(s,'full_type_name(z)', 'full_type_name(-9.8)');
	private.separ(s);
	private.item(s,'is_boolean(z)', 'is_boolean(1)');
	private.item(s,'is_byte(z)', 'is_byte(3)');
	private.item(s,'is_short(z)', 'is_short(-5)');
	private.item(s,'is_integer(z)', 'is_integer(-3.14)');
	private.item(s,'is_float(z)', 'is_float(3)');
	private.item(s,'is_double(z)', 'is_double(3+2i)');
	private.item(s,'is_complex(z)', 'is_complex(-5-3i)');
	private.item(s,'is_dcomplex(z)', 'is_dcomplex(7.3)');
	private.item(s,'is_numeric(z)', 'is_numeric(-987.456)');
	private.item(s,'is_string(z)', 'is_string(\'abc\')');
	private.item(s,'is_record(z)', 'is_record([=])');
	private.item(s,'is_function(z)', 'is_function(function(){})');
	private.item(s,'is_agent(z)', 'is_agent(create_agent())');
	# private.item(s,'is_file(z)', 'is_file(-987.456)');
	private.tw.append(s)
    }


    private.func_math := function() {
	s := private.header('Math functions');
	private.item(s,'cos(z)', 'cos(0.1)');
	private.item(s,'sin(z)', 'sin(0.1)');
	private.item(s,'tan(z)', 'tan(0.1)');
	private.item(s,'acos(z)', 'acos(-1)');
	private.item(s,'asin(z)', 'asin([-1,0,1])');
	private.item(s,'atan(z)', 'atan(0)');

	private.separ(s);
	private.item(s,'abs(z)', 'abs([-2:3])');
	private.item(s,'exp(z)', 'exp([-2:3])');
	private.item(s,'log(z)', 'log([0.1,0.5,1,2,10])');
	private.item(s,'sqrt(z)', 'sqrt([0:5])');

	private.separ(s);
	private.item(s,'complex(x,y)', 'complex(2,3)');
	private.item(s,'conj(z)', 'conj(complex(2,3))');
	private.item(s,'arg(z)', 'arg(complex(2,3))');
	private.item(s,'real(z)', 'real(complex(2,3))');
	private.item(s,'imag(z)', 'imag(complex(2,3))');

	private.separ(s);
	private.item(s,'random()', 'random()');
	private.item(s,'random(n)', 'random(5)');
	private.item(s,'random(imin,imax)', 'random(-100,100)');

	private.separ(s);
	private.item(s,'min(z,..)', 'min([-2:5],-10.3)');
	private.item(s,'max(z,..)', 'max([-2:5])');
	private.item(s,'range(z,..)','range([-5:3])');
	private.item(s,'sum(z,..)', 'sum([4:6],complex(1,2),-6.7)');
	private.item(s,'prod(z,..)', 'prod([4:6])');

	private.include(s,'statistics.g',T);
	private.item(s,'mean(z,..)', 'mean([1:10],23)');
	private.item(s,'moments(highest_moment,data,assumed_mean)');
	private.item(s,'kurtosis(z,..)', 'kurtosis([1:10],23)');
	private.item(s,'median(z,..)', 'median([1:10],23)');
	private.item(s,'skew(z,..)', 'skew([1:10],23)');
	private.item(s,'stddev(z,..)', 'stddev([1:10],23)');
	private.item(s,'variance(z,..)', 'variance([1:10],23)');
	private.item(s,'min_with_mask(data,mask)');
	private.item(s,'min_with_location(data,min_location,mask)');
	private.item(s,'max_with_mask(data,mask)');
	private.item(s,'max_with_location(data,max_location,mask)');

	private.include(s,'gaussian.g',F);
	private.item(s,'gaussian1d(xx,height,center,fwhm)');
	private.item(s,'gaussian2d(xx,yy,height,center,fwhm,pa)');

	private.tw.append(s)
    }

    private.func_fitting := function() {
	s := private.header('Math fitting functions');

	private.include(s,'polyfitter.g',F);
	private.item(s,'fitter := polyfitter()');
	private.item(s,'fitter.fit(coeff,coefferrs,chisq,x,y,sigma,order)');
	private.item(s,'fitter.eval(x,y,coeff)');
	private.item(s,'fitter.multifit(coeff,coefferrs,chisq,x,yy,sigma,order)');
	private.item(s,'polyfittertest()');
	private.item(s,'polyfitterdemo()');

	private.include(s,'lsfit.g',T);
	private.item(s,'produces global const object \'lsf\'');
	private.item(s,'lsf.help()');
	s := paste(s,lsf.help());

	private.include(s,'sinusoidfitter.g',F);
	private.item(s,'sinusoidfittertest()');
	private.item(s,'sinusoidfitterdemo()');

	private.include(s,'interpolate1d.g',F);
	private.item(s,'interpolate1dtest()');
	private.item(s,'interpolate1ddemo()');

	private.include(s,'fftserver.g',F);
	private.item(s,'fftservertest()');
	private.item(s,'fftserverdemo()');

	private.tw.append(s)
    }


    private.func_matrix := function() {
	s := private.header('Matrix operations');
	private.include(s,'matrix.g',T);
	private.item(s,'produces global const object \'mx\'');
	s := paste(s,mx.help());
	private.tw.append(s);
    }

    private.func_array := function() {
	s := private.header('Array functions');
	private.item(s,'len[gth](z)', 'len(array([1:10],2,3))');
	private.item(s,'shape(z)','shape(array(\'ab\',2,3))');
	private.separ(s);
	private.item(s,'sort(x)','sort([4,1,23,-7,3.4])');
	private.item(s,'sort(s)','sort(\"a s d f g h j k\")');
	private.item(s,'sort_pair(x,y)','sort_pair([3,1,2],\"a b c\")');
	private.item(s,'order(x)','order([4,1,23,-7,3.4])');
	private.separ(s);
	private.item(s,'ind(z)','ind([-5:3])');
	private.item(s,'seq(x)','seq(8)');
	private.item(s,'seq(x,y)','seq(-3,2)');
	private.item(s,'seq(x,y,z)','seq(-3,10,3)');
	private.item(s,'rep(z)','rep([1:3],10)');
	private.separ(s);
	private.item(s,'array(z,n1,n2,n3,..)');
	private.separ(s);
	private.item(s,'all(b(z))','all([1:10]>6)');
	private.item(s,'any(b(z))','any([1:10]>6)');
	private.tw.append(s);
    }

    private.func_record := function() {
	s := private.header('Record functions');
	private.item(s,'field_names(r)', 'field_names([a=4,b=\'foo\',c=[1:10]])');
	private.item(s,'has_field(r,name)', 'has_field([a=4,aa=-45],\'aa\')');
	private.item(s,' ', '');
	private.tw.append(s);
    }


    private.func_string := function() {
	s := private.header('String functions', margin=30);
	private.item(s,'s := \'aa bb cc\'', 'len(\'aa bb cc\')');
	private.item(s,'s := \"aa bb cc\"', 'len(\"aa bb cc\")');
	private.separ(s);
	private.item(s,'print ..,..,..', 
		comment='format and write to screen');
	private.item(s,'printf(pattern,...)', 
		comment='format and write to screen'); 
	private.item(s,'s := paste(..,..,..)', 
		'paste(\'v=\',[-1:2],\'(Jy)\')');
	private.item(s,'s := spaste(..,..,..)', 
		'spaste(\'v=\',[-1:2],\'(Jy)\')');
	private.item(s,'s := sprintf(pattern,...)', 
		comment='format a string'); 
	private.separ(s);
	private.item(s,'v::print.precision := n', 
		comment='controls formatting'); 
	private.separ(s);
	private.item(s,'split(s)', 'len(split(\'ab cd\'))');
	private.item(s,'split(s,\' \')', 'len(split(\'ab cd\',\' \'))');
	private.item(s,'split(s,sep)', 'len(split(\'abcd\',\'c\'))');
	private.item(s,'split(s,\'\')', 'len(split(\'abcd\',\'\'))');
	private.separ(s);
	private.item(s,'to_lower(s)', 'to_lower(\'sdAJTbdfY123\')');
	private.item(s,'to_upper(s)', 'to_upper(\"sdA JTbdf Y123\")');
	private.separ(s);
	private.item(s,'s := readline()', 
		comment='allow the user to input a string'); 
	private.item(s,'s := readline(prompt=\'input: \')', 
		comment='optional prompt-string'); 
	private.tw.append(s)
    }


#------------------------------------------------------------------------
# Some helper functions for formatting:

    private.superheader := function (subject, clear=T) {
	if (clear) private.tw.clear();		# clear textwindow first!
	s := paste(' \n =============') 
	s := paste(s,'\n Overview of',subject);
	s := paste(s,' \n =============') 
	private.tw.append(s, tmargin=1, bmargin=1, prefix='# ')
	return T;
    }

    private.header := function (header, margin=20) {
	wider private;
	private.margin := margin;		# used in private.item()
	s := spaste(' \n# ',header);
	return s := spaste(s,':\n ');
    }

    private.separ := function (ref ss, comment=F) {
	s := '\n';
	if (is_string(comment)) {
	    s := paste(s,'\n# **',comment);
	}
	val ss := paste(ss,s);
    }

    private.include := function (ref ss, filename, doinclude=F) {
	s := ' \n \n#';
	s := spaste(s,' (include \'',filename,'\'):')
	if (doinclude) {
	    include filename			#
	    # print 'include',filename;		# temporary
	}
	val ss := paste(ss,s);
    }

    private.item := function (ref ss, desc, examp=F, comment=F) {
	s := rep(' ',private.margin);		# reserve e.g. 20 chars
	d := split(desc,'');			# split into chars 
	for (i in ind(d)) {s[i] := d[i]}	# transfer chars to s
	s := spaste(s);				# re-paste
	if (is_string(examp)) {
	    s := paste(s,'example:',examp,'->',eval(examp))
	} else if (is_string(comment)) {
	    s := paste(s,comment)
	}
	val ss := paste(ss,'\n# -',s);
    }

    private.contact := function (ref ss, name, email=F) {
	s := paste('\n# In case of problems, contact',name);
	if (is_string(email)) {
	    s := spaste(s,' (email:',email,')');
	}
	val ss := paste(ss,s);
    }

    private.seealso := function (ref ss, subject) {
	val ss := paste(ss,'\n# See also:',subject);
    }


#=========================================================
# Finished. Initialise and return the public interface:

    private.init();
    # return public;

};					# closing bracket of glishelp
#=========================================================

glishelp();				# run the routine (always!)



