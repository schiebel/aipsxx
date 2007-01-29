# inspect.g: inspection tool for Glish variables.

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
# $Id: inspect.g,v 19.2 2004/08/25 02:15:25 cvsmgr Exp $

#---------------------------------------------------------

pragma include once
# print 'include inspect.g  h01sep99'

include "guimisc.g"		# tablechooser...
include 'guicomponents.g'	# tracewindow
include 'popuphelp.g'
include 'textwindow.g'		#
include 'menubar.g'		#
include 'textformatting.g'	#

#=========================================================
test_inspect := function () {
    private := [=];
    public := [=]

    private.f := frame(title='test_inspect')
    private.b := button(private.f,'some Glish variables', type='menu')
    private.rec := button(private.b,'a record')
    private.ivec := button(private.b,'integer vector')
    private.iarr := button(private.b,'integer array')
    private.darr := button(private.b,'double array')
    private.carr := button(private.b,'complex array')
    private.sarr := button(private.b,'string array')
    private.test := button(private.b,'test')

    whenever private.rec -> press do {
	rr.v1 := 5;
	rr.v2 := array([1:10],20,30,2);
	rr.v3 := rep(F,5);
	rr.v4 := array('s',10,12);
	rr.v5 := [T,F,T];
	rr.v6 := "a b c d e f g h i j k";
	rr.v7 := array(1+2i,4,5);
	rr.v8 := create_agent();
	rr.v9 := [=];
	rr.v9.aa := [T,T,F,T,F,F,F];
	rr.v9.cc := [1:10];
	rr.v9.bb := [=];
	rr.v10 := [];
	rr.v11 := [=];
	rr.v11.b1 := array(complex(2,3),12,20);
	rr.v11.b2 := [3,2];
	rr.v13 := array([1:3]*0.00001,10,22);
	rr.v14 := 'abc';
	rr.v15 := "c b a";
	rr.v16 := function(ref arg1='67', arg2=14) {print arg1,arg2}
	public.insp := inspect(rr,'rr');
    }
    whenever private.ivec -> press do {
	vec := [-15:97];
	public.insp := inspect(vec,'ivec');
    }
    whenever private.iarr -> press do {
	v := [1:100];
	arr := array(v,100,100);
	public.insp := inspect(arr,'iarr');
    }
    whenever private.darr -> press do {
	v := [-50:50]*0.1;
	arr := array(v,10,20);
	public.insp := inspect(arr,'darr');
    }
    whenever private.carr -> press do {
	v := complex([1:100],[100:1]);
	arr := array(v,10,20);
	public.insp := inspect(arr,'carr');
    }
    whenever private.sarr -> press do {
	v := 'abcdefghijklmnopqrstuvwxyz';
	arr := array(v,5,20);
	public.insp := inspect(arr,'sarr');
    }
    return ref public;
};


#=========================================================
inspect := function (glivar='use tablechooser', name=F, auxrec=[=]) {
    private := [=];
    public := [=];

    private.should_be_table := F;
    if (glivar=='use tablechooser') {	# no input value: choose one
	tc := tablechooser();
	if (is_boolean(tc.guiReturns)) {# canceled
	    return F;			# exit
	} else {
	    include 'table.g'		# only if necessary
	    name := tc.guiReturns;	# name of table
	    glivar := table(name);	# 
	    private.should_be_table := T;
	}
    }

    private.glivar := glivar;		# glish variable to be inspected
    private.name := paste(name);	# its name
 
    # private.auxrec := [=];		# auxiliary information record
    # if (has_field(auxrec,'xaxis')) private.auxrec.xaxis := auxrec.xaxis;
    # if (has_field(auxrec,'split')) private.auxrec.split := auxrec.split;
    private.auxrec := auxrec;		# auxiliary information record

    private.is_table := F;
    if (is_record(private.glivar)) {
	if (has_field(private.glivar,'handle')) {
	    if (is_function(private.glivar.handle)) {
		if (private.glivar.handle().type=='table') {
		     include 'table.g';		# only if necessary
		     private.is_table := T;
		}
	    }
	}
    }
    if (private.should_be_table) {
	if (!private.is_table) {
	    print 'expected: table'
	    return F;			# exit
	}
    }

    if (is_numeric(private.glivar)) {
	private.label := spaste('inspect ',type_name(private.glivar),
			 '[',shape(private.glivar),']: ',private.name);
    } else if (private.is_table) {
	private.label := paste('inspect table:',private.name);
    } else {
	private.label := spaste('inspect ',type_name(private.glivar),
				': ',private.name);
    }

    private.init := function() {
	wider private;
	private.twf := textformatting();	# text-formatting services
	private.format := F;			# user-defined display format
	private.recursive := F;			# do not display any sub-records
	private.callback := F;			# user-defined display function

	private.split_glivar();			# if required	

	private.rownr := 1;			# for table
	private.launch();			# launch the text-window etc
	return T;
    }

#=============================================================
# Public interface:
#=============================================================

    public.agent := create_agent();
    whenever public.agent->* do {
	s := paste('inspect event:',$name,$value);
	print s;
    }



#=============================================================
#=============================================================
# Private functions:
#=============================================================


#-----------------------------------------------------------------
# Launch a standalone inspection text-window:

    private.launch := function () {
	wider private, public;
	public.tw := textwindow(private.label);
	public.tw.background('pink');
	# public.tw.foreground('black');
	public.tw.standardmenu();	# open/save/print/close etc
	private.makespecificmenu();	# depends on type of private.glivar

	# The initial display-mode of 'private-glivar' depends on it:
	if (is_numeric(private.glivar)) {
	    if (len(private.glivar)<100) {   
		private.full();              # full display 
	    } else {
		private.summary();           # summary only 
	    }
	} else if (is_string(private.glivar)) {
	    private.full();                  # full display
	} else {
	    private.summary();		     # summary only 
	} 
	return T;
    }

# The display menu depends on the type of private.glivar:

    private.makespecificmenu := function () {
	defrec := public.tw.menubar().defrecinit('display summary', 'view');
	defrec.shorthelp := 'display a summary';
	public.tw.menubar().makemenuitem(defrec, private.summary); 

	if (is_record(private.glivar)) {
	    private.makerecordmenu ();
	    
	} else {
	    defrec := public.tw.menubar().defrecinit('display fully', 'view');
	    defrec.shorthelp := 'display fully';
	    public.tw.menubar().makemenuitem(defrec, private.full);

	    if (is_numeric(private.glivar)) {
		private.makenumericmenu ();
	    }
	}
	return T;
    }


# Make menu for glivar-type 'numeric':

    private.makenumericmenu := function () {
	if (is_boolean(private.glivar)) {
	    #.......
	} else {
	    if (is_complex(private.glivar) | is_dcomplex(private.glivar)) { 
	    	defrec := public.tw.menubar().defrecinit('conv->real', 'view');
		defrec.paramchoice := "ampl deg rad real imag"
	    	defrec.shorthelp := 'complex -> real conversion';
	    	public.tw.menubar().makemenuitem(defrec, private.ctor);
	    }
	    if (len(private.glivar)==1) { 
	    	defrec := public.tw.menubar().defrecinit('edit', 'edit');
	    	defrec.shorthelp := 'edit the value';
	    	# public.tw.menubar().makemenuitem(defrec, private.edit);
	    }
	    if (len(private.glivar)>1) { 
	    	defrec := public.tw.menubar().defrecinit('plot', 'view');
	    	defrec.shorthelp := 'make a simple plot';
	    	public.tw.menubar().makemenuitem(defrec, private.plot);
	    }
	    private.makemenu_format();
	    private.makemenu_histogram();
	}
	return T;
    }

# Make menu for glivar-type 'record' (and table if record is_table):

    private.makerecordmenu := function () {
	defrec := public.tw.menubar().defrecinit('set recursive', 'view');
	defrec.paramchoice := [F,T];
	defrec.shorthelp := 'display any sub-records too';
	# public.tw.menubar().makemenuitem(defrec, private.setrecursive); 
	# private.setrecursive(defrec.paramchoice[1]);	# default setting

	ss := "boolean string integer double dcomplex";
	ss := [ss,"function record"];
	for (name in ss) {
	    ff := private.fieldnames(name); 
	    if (is_string(ff)) { 
		caption := paste(name,'fields');
		defrec := public.tw.menubar().defrecinit(caption, 'view');
		defrec.paramchoice := ff;
		public.tw.menubar().makemenuitem(defrec, private.inspectfield);
	    } 
	}
	if (is_string(ff:=private.fieldnames(exclude=ss))) { 
	    defrec := public.tw.menubar().defrecinit('other fields', 'view');
	    defrec.paramchoice := ff;
	    public.tw.menubar().makemenuitem(defrec, private.inspectfield);
	}
	if (has_field(private.glivar,'private')) {
	    defrec := public.tw.menubar().defrecinit('private', 'view');
	    defrec.shorthelp := 'inspect private part';
	    public.tw.menubar().makemenuitem(defrec, private.inspectprivate);
	}
 
	if (private.is_table) private.maketablemenu();
	return T; 
    }


# Make a menu for glivar-type 'table':

    private.maketablemenu := function () {
	colnames := private.glivar.colnames();
	if (len(colnames)>0) {
	    sncolnames := ' '; nsncol := 0;	# scalar cols, type=numeric
	    sicolnames := ' '; nsicol := 0;	# scalar cols, type=integer 
	    sscolnames := ' '; nsscol := 0;	# scalar cols, type=string
	    for (i in ind(colnames)) {
	    	if (private.glivar.isscalarcol(colnames[i])) {
	    	    if (private.glivar.coldatatype(colnames[i])=='Int     ') {
		    	sicolnames[nsicol+:=1] := colnames[i];  # int
		    	sncolnames[nsncol+:=1] := colnames[i];	# numeric
	    	    } else if (private.glivar.coldatatype(colnames[i])=='String  ') {
		    	sscolnames[nsscol+:=1] := colnames[i];	# string
	    	    } else {
		    	sncolnames[nsncol+:=1] := colnames[i];	# numeric...(?)
		    }
		}
	    }


	    defrec := public.tw.menubar().defrecinit('columns', 'table');
	    defrec.paramchoice := colnames;
	    defrec.shorthelp := 'inspect table columns';
	    public.tw.menubar().makemenuitem(defrec, private.table_column);

	    if (nsncol>0) {		# scalar-numeric columns only
		defrec := public.tw.menubar().defrecinit('x-axis', 'table');
		ss := sncolnames;
		if (any(sncolnames=='TIME')) {
		    ss := ['TIME',ss[ss!='TIME']];	# make the first
		    private.table_setxaxis('TIME');
		}
		defrec.paramchoice := ss;
		defrec.shorthelp := 'specify x-axis (plotting)';
		defrec.prompt := 'specify x-axis (plotting)';
		defrec.paramhelp := defrec.shorthelp;
		public.tw.menubar().makemenuitem(defrec, private.table_setxaxis);
	    }

	    if (nsicol>0) {		# scalar-integer columns only
	    	defrec := public.tw.menubar().defrecinit('splitting-vector', 'table');
	    	defrec.paramchoice := [sicolnames,'none'];
		defrec.prompt := 'specify splitting-vector (column)';
	    	defrec.shorthelp := 'specify a split-vector column';
		s := 'columns will be split according to this vector';
		s := paste(s,'\n e.g. in plots and other displays');
	    	defrec.paramhelp := s;
	    	public.tw.menubar().makemenuitem(defrec, private.table_setsplit);
	    }

	    nrows := private.glivar.nrows();
	    if (nrows>1) {
		private.table_setrownr(1);

	    	defrec := public.tw.menubar().defrecinit('row', 'table');
	    	defrec.paramchoice := [1,nrows];
	    	defrec.prompt := 'specify a row number';
	    	defrec.shorthelp := 'for inspecting a single row';
	    	public.tw.menubar().makemenuitem(defrec, private.table_row); 

	    	defrec := public.tw.menubar().defrecinit('cell', 'table');
	    	defrec.paramchoice := colnames;
	    	defrec.prompt := 'specify a column';
	    	defrec.shorthelp := 'inspect a table cell';
	    	public.tw.menubar().makemenuitem(defrec, private.table_cell);
	    }
	} 

	keywords := private.glivar.getkeywords();		# record
	if (len(keywords)>0) {
	    defrec := public.tw.menubar().defrecinit('sub-tables', 'table');
	    defrec.paramchoice := field_names(keywords);
	    defrec.shorthelp := 'inspect sub-tables';
	    public.tw.menubar().makemenuitem(defrec, private.table_keyword); 

	    defrec := public.tw.menubar().defrecinit('keywords', 'table');
	    defrec.paramchoice := field_names(keywords);
	    defrec.prompt := 'inspect table keywords';
	    public.tw.menubar().makemenuitem(defrec, private.table_keyword); 
	}

	defrec := public.tw.menubar().defrecinit('query', 'table');
	defrec.shorthelp := 'make a sub-table, using TaQL';
	ss := ' ';
	if (nsicol>0) {
	    ss := [ss,paste(icolnames[1],'== 1')];
	}
	if (nsicol>1) {
	    ss := [ss,paste(icolnames[2],'< 10')];
	    ss := [ss,paste(icolnames[1],'== 1 &&',icolnames[2],'> 3')];
	}
	if (nsscol>0) {
	    ss := [ss,paste(scolnames[1],'==pattern(\"...*\")')];
	}
	defrec.paramchoice := ss;
	defrec.prompt := 'make a sub-table, using TaQL';
	defrec.help := 'see AIPS++ note 199 on Table Query Language'
	public.tw.menubar().makemenuitem(defrec, private.table_query); 

	defrec := public.tw.menubar().defrecinit('browse', 'table');
	defrec.shorthelp := 'use the table browser';
	public.tw.menubar().makemenuitem(defrec, private.table_browse); 

	defrec := public.tw.menubar().defrecinit('desc', 'table');
	defrec.shorthelp := 'display the table description';
	public.tw.menubar().makemenuitem(defrec, private.table_desc); 

	defrec := public.tw.menubar().defrecinit('table functions', 'table');
	defrec.shorthelp := 'display the table functions';
	public.tw.menubar().makemenuitem(defrec, private.table_functions); 

	defrec := public.tw.menubar().defrecinit('server functions', 'table');
	defrec.shorthelp := 'server functions';
	public.tw.menubar().makemenuitem(defrec, private.table_server); 

	return T;
    }

    private.table_column := function (colname) {
	name := spaste(private.name,'-col:',colname);
	inspect(private.glivar.getcol(colname),
		name, private.auxrec)
	return T;
    }

    private.table_setxaxis := function (colname) {
	wider private;
	xx := private.glivar.getcol(colname);
	dim := shape(xx);
	if (len(dim)==1) {
	    xlabel := colname;
	    if (colname=='TIME') {
		xx := (xx-xx[1])/(3600.0);
		xlabel := 'relative time (hrs)';		 
	    }
	    private.auxrec.xaxis := [=];
	    private.auxrec.xaxis.xx := xx;
	    private.auxrec.xaxis.xlabel := xlabel;
	    private.auxrec.xaxis.ylabel := 'ylabel';
	    s := spaste('x-axis set to ',colname,' (dim=',dim,')')
	    public.tw.message(s);
	}
	return T;
    }

    private.table_setsplit := function (colname) {
	wider private;
	if (colname=='none') {
	    private.auxrec.split := [=];
	    public.tw.message('no split-vector specified')
	    return T;
	}
	ii := private.glivar.getcol(colname);
	dim := shape(ii);
	if (len(dim)==1) {				# only if 1-dim...
	    private.auxrec.split := [=];
	    private.auxrec.split.name := colname;
	    private.auxrec.split.vv := ii;
	    s := spaste('split-vector is column: ',colname,' (dim=',dim,')')
	    public.tw.message(s);
	}
	return T;
    }

    private.ctor := function (ctor) {
	if (ctor=='ampl') {
	    name := paste('ampl of',private.name)
	    vv := abs(private.glivar);
	} else if (ctor=='deg') {
	    name := paste('phase (deg) of',private.name)
	    vv := private.tofase(private.glivar, todeg=T);
	} else if (ctor=='rad') {
	    name := paste('phase (rad) of',private.name)
	    vv := private.tofase(private.glivar, todeg=F);
	} else if (ctor=='real') {
	    name := paste('real part of',private.name)
	    vv := real(private.glivar);
	} else if (ctor=='imag') {
	    name := paste('imag.part of',private.name)
	    vv := imag(private.glivar);
	} else {
	    return F;				# do nothing (?)
	} 
	inspect(vv,name);
	return T;
    }

    private.tofase := function (cc, todeg=F) {
	if ((ncc:=len(cc))<=0) return [];	# no data
	rr := rep(0,ncc);
	sv0 := [abs(cc)==0.0];			# zero amplitude
	sv := [real(cc)>=0];			# if real(cc)>-0:
	# print 'tofase  in:',len(cc),len(sv[sv]),len(sv0[sv0]),type_name(cc),cc[1:3];
	rr[sv] := arg(cc[sv]);			# do direct conversion
	if (any(!sv)) {				# for the others:
    	    spi := acos(-1);			# 3.14...
	    if (sum(imag(cc[!sv]))<0) spi := -spi;	#....useful?
    	    cpi := complex(-1.0,0.0);		# rotation factor 
    	    rr[!sv] := arg(cc[!sv]*cpi) + spi;	# convert and correct
	}
	if (any(sv0)) rr[sv0] := 0.0;		# remove NaN (ampl==0)
	if (todeg) rr *:= 180.0/acos(-1);	# convert to degr
	# print 'tofase out:',len(rr),type_name(rr),rr[1:3];
	return rr;				# phases 
    }


    private.table_cell := function(colname) {
	name := spaste(private.name,'-cell:',colname,'/row=',private.rownr);
	inspect(private.glivar.getcell(colname,private.rownr),name)
	return T;
    }
    private.table_keyword := function (keywordname) {
	name := spaste(private.name,'-key:',keywordname);
	inspect(table(private.glivar.getkeyword(keywordname)),name);
	return T;
    }
    private.table_server := function(dummy=F) {
	inspect(private.glivar.server(),'table.server()');
    }
    private.table_query := function(taql=F) {
	t := private.glivar.query(taql)
	if (is_fail(t)) return F;
	nrows := t.nrows();
	public.tw.message(paste('subset table has ',nrows,'rows'))
	if (nrows==0) return T;
	name := spaste(private.name,'-query:',taql);
	inspect(t,name);
	return T;
    }
    private.table_setrownr := function(rownr=F) {
	wider private;
	private.rownr := rownr;			# remember rownr
	public.tw.message(paste('row nr set to',private.rownr))
    }
    private.table_row := function(rownr=F) {
	private.table_setrownr(rownr);		# remember rownr
	public.tw.append(' ');
	s := spaste('Cells of table-row nr: ',private.rownr,':')
	public.tw.append(s);
	colnames := private.glivar.colnames();
	for (colname in colnames) {
	    s := paste('-',colname,': ');
	    d := private.glivar.getcell(colname, private.rownr)
	    # s := spaste(s,type_name(d));
	    dim := shape(d);
	    if (len(dim)==1) {
		if (dim==1) {
		    s := spaste(s,'  scalar:      ',d);
		} else {
		    s := spaste(s,'  vector[',dim,']: ');
		}
	    } else {
		s := spaste(s,'  array[',dim,']:  ');
	    }
	    public.tw.append(s);
	}
	public.tw.append(' ');
    }
    private.table_browse := function () {
	# private.glivar.browse();		# old browser
	include 'tablebrowser.g';
	r := tablebrowser(private.glivar);		# new browser
	return T;
    }
    private.table_desc := function () {
	ss := private.glivar.getdesc();
	public.tw.append(paste(' \n \n Table decription (table.desc()):'));
	for (s in ss) {
	    public.tw.append(paste('\n',s));
	}
	return T;
    }
    private.table_functions := function () {
	wider private;
	private.is_table := F;			# temporary, to fool it
	name := private.name;			# temporary
	private.name := 'table';
	private.summary();			# treat as normal record
	private.is_table := T;			# restore
	private.name := name;			# restore
	return T;
    }

# Make a number-formatting menu (if required)

    private.makemenu_format := function () {
	defrec := public.tw.menubar().defrecinit('format', 'view');
	defrec.shorthelp := 'select display format';		
	if (!is_numeric(private.glivar)) {
	    return F;
	} else if (is_boolean(private.glivar)) {
	    return F;
	} else if (is_integer(private.glivar)) {
	    # defrec.paramchoice := "ix iy iz";
	    # defrec.prompt := 'give integer format'; 
	} else {
	    # defrec.paramchoice := "xx yy zz";
	    # defrec.prompt := 'give floating format'; 
	}
	public.tw.menubar().makemenuitem(defrec, private.setformat);
	private.setformat(defrec.paramchoice[1]);		# default format
	return T
    }

# Make a histogram menu (if required)

    private.makemenu_histogram := function () {
	defrec := public.tw.menubar().defrecinit('histogram', 'view');
	defrec.shorthelp := 'make a histogram';		
	if (!is_numeric(private.glivar)) {
	    return F;
	} else if (is_boolean(private.glivar)) {
	    return F;
	} else {
	    defrec.paramchoice := [10,20,50];
	    defrec.prompt := 'nr of bins'; 
	}
	public.tw.menubar().makemenuitem(defrec, private.histogram);
	return T
    }

    private.histogram := function (nbins=10) {
	# public.tw.clear();			#....?
	# s := private.twf.summary(private.glivar, private.name)
	# public.tw.append(s);
	s := private.twf.histogram(private.glivar, private.name, nbins=nbins)
	public.tw.append(s);
	return T;
    }

    private.setformat := function (format=F) {
	wider private;
	private.format := format;
	s := paste('private.format set to:',private.format);
	s := 'formatting not yet supported';		# temporary
	public.tw.message(s);
    }

    private.setrecursive := function (recursive=T) {
	wider private;
	private.recursive := recursive;
	s := paste('private.recursive set to:',private.recursive);
	public.tw.message(s);
    }

# Edit-function (place-holder for the moment):

    private.edit := function(dummy=F) {
	public.tw.message('edit not yet implemented')
    }


    private.inspectprivate := function(dummy=F) { 
	name := 'private';
        inspect(private.glivar.private(),name);
    }    


# Inspect a user-selected field (only if private.glivar is a record): 
# NB: The field name has the form: record.field (type), see above.

    private.inspectfield := function (field=F) {
	wider private;
	if (!is_string(field)) {
	    public.tw.message('no field-name given')
	} else if (field==' ') {
	    public.tw.message('no fields of this type in record')
	} else {
	    # print 'decode:',field;
	    field := split(field,'.');			# 
	    field := field[len(field)];			# remove recordname
	    field := split(field,' (')[1];		# remove (type)	
	    if (!has_field(private.glivar,field)) {
		s := paste('no field',field,'(',len(field),')');
		s := paste(s,'in record',private.name);
	    	public.tw.message(s);
	    } else {
		name := spaste(private.name,'.',field);
		inspect(private.glivar[field],name);	# inspect field
	    }
	}
    }

    private.fieldnames := function (types='all', exclude='none') {
	anytype := (types=='all');
	ff := field_names(private.glivar);
	ss := ' ';
	n := 0;
	for (i in ind(ff)) {
	    typename := type_name(private.glivar[ff[i]]);
	    if (anytype || any(types==typename)) {
		if (!any(exclude==typename)) {
	    	    ss[n+:=1] := spaste(private.name,'.',ff[i]);
	    	    ss[n] := spaste(ss[n],' (',typename,')');
		}
	    }
	}
	if (n==0) ss := F;			       # none found
	return ss;
    }


#-------------------------------------------------------------------------
# Split glivar, if required:

    private.split_glivar := function() {
	wider private;
	private.is_split := F;
	if (!has_field(private.auxrec,'split')) {
	    # print 'split: no split-field in auxrec';
	    return F;
	}
	if (!has_field(private.auxrec.split,'vv')) {
	    # print 'split: no split-vector vv';
	    return F;
	}
	if (!is_numeric(private.glivar)) {
	    # print 'split: not numeric: ',type_name(private.glivar);
	    return F;
	}
	vv := ref private.auxrec.split.vv;
	if (!is_integer(vv)) {
	    # print 'split: vv not integer, but',type_name(vv)
	    return F;
	}
	dim := shape(private.glivar);
	nvv := len(vv);
	idim := ind(dim)[dim==nvv];
	if (len(idim)==0) {
	    print 'split: unequal lengths:',nvv,'<>',dim;
	    return F;
	}
	idim := idim[1];
	ndim := len(dim);
	# print nvv,'dim=',dim,' ',idim,ndim
	private.split.glivar := [=];
	private.split.name := [=];
	if (has_field(private.auxrec.split,'name')) {
	    s := spaste(private.auxrec.split.name,'=')
	    private.split.vvname := private.auxrec.split.name;
	} else {
	    s := spaste('split-value=')
	    private.split.vvname := '(un-named)' 
	}
	for (v in [min(vv):max(vv)]) {
	    sv := [vv==v];
	    if (any(sv)) {
		n := 1 + len(private.split.glivar);
		if (ndim==1) {
		    private.split.glivar[n] := private.glivar[sv];
		} else if (ndim==2) {
		    if (idim==1) {
		    	private.split.glivar[n] := private.glivar[sv,];
		    } else if (idim==2) {
		    	private.split.glivar[n] := private.glivar[,sv];
		    } else {
			print 'split: idim out of range:',idim,ndim
		    } 
		} else {
		    print 'split: ndim=',ndim,'>2'
		    return F;				# temporary
		}
		private.is_split := T;
		private.split.name[n] := spaste(n,': ',s,v);
		# print private.split.name[n],len(private.split.glivar[n]);
	    }
	}
	return T;
    }

#-------------------------------------------------------------------------
# Full display of private.glivar:

    private.plot := function() {
	wider private;
	if (is_boolean(private.glivar)) {
	    # do nothing
	} else if (is_numeric(private.glivar)) {
	    private.title := paste('inspect: plot of', private.name);
	    private.xlabel := 'xlabel';		# see private.plotxy()
	    private.ylabel := 'ylabel';		# see private.plotxy()
	    include 'plotter.g'			# only when necessary
	    dp.drawBlockEnter(); 
	    dp.clear();				# ....?
	    dim := shape(private.glivar);
	    if (len(dim)==1) {
		if (private.is_split) {
		    for (i in ind(private.split.glivar)) {
		    	private.plotxy(private.split.glivar[i],
				       private.split.name[i])
		    }
		} else {
		    private.plotxy(private.glivar,private.name)
		}
	    } else if (len(dim)==2) {
		if (dim[1]>dim[2]) {
		    for (i in [1:min(10,dim[2])]) {
			name := spaste('[,',i,']');
			private.plotxy(private.glivar[,i],name)
		    }
		} else {
		    for (i in [1:min(10,dim[1])]) {
			name := spaste('[',i,',]');
			private.plotxy(private.glivar[i,],name)
		    }
		}
	    } else {
		public.tw.message('Too many dimensions for plotting');
	    }
	    dp.setXAxisLabel(private.xlabel);
	    dp.setYAxisLabel(private.ylabel);
	    dp.setPlotTitle(private.title);
	    dp.drawBlockExit(); 
	}
	return T;
    }

# Helper routine for private.plot():

    private.plotxy := function (vv,name) {
	wider private
	style := 'lines';
	if (len(vv)<=200) style := 'linespoints';
	if (is_complex(vv)) {
	    public.tw.append(paste('complex plot',name));
	    private.xlabel := paste('real part')
	    private.ylabel := paste('imag.part')
	    dp.plotxy(real(vv),imag(vv),name,style);
	} else {
	    private.ylabel := spaste('value (',
				type_name(private.glivar),')')
	    if (has_field(private.auxrec,'xaxis')) {
	    	private.ylabel := private.auxrec.xaxis.ylabel;
		private.xlabel := private.auxrec.xaxis.xlabel;
		public.tw.append(paste('plot',name,
				' xaxis=',private.auxrec.xaxis.xlabel));
		xx := private.auxrec.xaxis.xx;
		if (len(xx)!=len(vv)) xx := ind(vv);
	    } else {
		public.tw.append(paste('plot',name));
		xx := ind(vv);
		private.xlabel := paste('vector index')
	    } 
	    dp.plotxy(xx,vv,name,style);
	}
	return T;
    }


#-------------------------------------------------------------------------
# Full display of private.glivar:

    private.full := function() {
	wider private;
	public.tw.clear();			# clear the text-window (?)

	if (is_function(private.callback)) {
	    ss := private.callback(private.glivar);
	} else {
	    ss := private.twf.fully(private.glivar, private.name)
	}
	public.tw.append(ss);
	return T;
    }



#----------------------------------------------------------
# Print the contents of a Glish record in an organised way.

    private.showrecord := function (ref rd, name='record', recurse=F) {
	ast := '';
	level := 1;
	if (level>1) ast := rep('**',level-1);
	s := spaste('\n ',ast,' Contents of Glish record ',name,':');

	ast := rep('**',level);	
	if (!is_record(rd)) {
	    s := paste(s,'\n not a record, but:',type_name(rd));
	    if (level==1) s := paste(s,'\n');
	    return s;
	};

	fn := field_names(rd);
	nfields := len(fn);		# NB: do not use len(rd)!
	if (nfields <= 0) {
	    s := paste(s,' \n [=] (empty)');
	    if (level==1) s := paste(s,'\n');
	    return s;
	}	

	iif := [];
	iia := [];
	iin := [];
	iib := [];
	iir := [];
	iis := [];
	iifail := [];
	n1 := 0;
	for (i in [1:nfields]) {
	    if (is_function(rd[i])) {
		iif:=[iif,i];
	    } else if (is_agent(rd[i])) {   # NB: before record!
		iia:=[iia,i];
	    } else if (is_record(rd[i])) {
		iir:=[iir,i];
	    } else if (is_boolean(rd[i])) {
		iib:=[iib,i];
	    } else if (is_numeric(rd[i])) {
		iin:=[iin,i];
	    } else if (is_string(rd[i])) {
		iis:=[iis,i];
	    } else if (is_fail(rd[i])) {
		iis:=[iifail,i];
	    } else {
		n1 +:= 1;
	        s := paste(s,'\n ',ast,' unaccounted field(?): ',
				fn[i],type_name(rd[i]));
	    }
	}

	for (i in iia) {
	    s1 := spaste(name,'.',fn[i]);
	    s := paste(s,'\n',ast,s1,' ',rd[i]);
	}
	for (i in iif) {
	    s1 := spaste(name,'.',fn[i])
	    s := paste(s,'\n',ast,private.twf.summary(rd[i],s1))
	}
	for (i in iifail) {
	    s1 := spaste(name,'.',fn[i]);
	    s := spaste(s,'\n ',ast,' fail(!): ',fn[i],' ',rd[i]);
	}
	if (len(iib)>0) s := paste(s,'\n \n',ast,'  boolean fields:');
	for (i in iib) {
	    s1 := spaste(name,'.',fn[i])
	    s := paste(s,'\n',ast,private.twf.summary(rd[i],s1))
	}
	if (len(iin)>0) s := paste(s,'\n \n',ast,'  numeric fields:');
	for (i in iin) {
	    s1 := spaste(name,'.',fn[i])
	    s := paste(s,'\n',ast,private.twf.summary(rd[i],s1))
	}
	if (len(iis)>0) s := paste(s,'\n \n',ast,'  string fields:');
	for (i in iis) {
	    s1 := spaste(name,'.',fn[i])
	    s := paste(s,'\n',ast,private.twf.summary(rd[i],s1))
	}

	if (len(iir)>0) s := paste(s,'\n \n',ast,' (sub-)record fields:');
	for (i in iir) {
	    s1 := spaste(name,'.',fn[i]);
	    if (recurse) {
		s := paste(s,'\n',private.showrecord(rd[i],s1,recurse));
	    } else {
	    	s := spaste(s,'\n ',ast,' record: ',s1);
	    }
	}
	if (level==1) s := paste(s,'\n');
	return s;
    }



#-----------------------------------------------------------------
# Display a summary of the Glish variable:

    private.summary := function() {
	if (private.is_table) {
	    s := private.summ_table(private.glivar, private.name)
	} else if (is_record(private.glivar)) {
	    s := private.twf.showrecord(private.glivar, private.name, 
				        private.recursive);
	    if (!private.recursive) {
		s1 := 'NB: Use \'recursive\' to display sub-records too'
		# public.tw.message(s1);
	    }
	} else if (is_numeric(private.glivar)) {
	    if (private.is_split) {
	        s := paste('Split according to vector',private.split.vvname)
		for (i in ind(private.split.glivar)) {
	    	    s := paste(s,'\n',private.twf.summary(
			       private.split.glivar[i], private.split.name[i]))
		}
	    } else {
	    	s := private.twf.summary(private.glivar, private.name)
	    }
	} else {
	    s := private.twf.summary(private.glivar, private.name)
	}
	public.tw.clear();
	public.tw.append(s);
    }


    private.summ_table := function (ref v, name=F) {
	public.tw.message('Making summary of table....');
	s := paste('Columns of table: ',name);
	ss := v.colnames();
	if ((n:=len(ss))<=0) return s;
	for (i in ind(ss)) {
	    s := paste(s,'\n',private.nchar(25,ss[i]));
	    s1 := paste(v.coldatatype(ss[i]));
	    if (v.isscalarcol(ss[i])) {
	        s1 := paste(s1,'scalar');
	    } else {
	        s1 := paste(s1, v.getcolshapestring(ss[i]));
	    }
	    s := paste(s, private.nchar(20,s1));
	    s2 := paste(v.getcolkeywords(ss[i]));
	    s := paste(s, s2);
	}
	s := paste(s,'\n');
	s := paste(s,'\n table.ok()     -> ',v.ok());
	s := paste(s,'\n table.ncols()  -> ',v.ncols());
	s := paste(s,'\n table.nrows()  -> ',v.nrows());
	s := paste(s,'\n table.name()   -> ',v.name());
	s := paste(s,'\n table.handle() -> ',v.handle());
	s := paste(s,'\n table.info()   -> ',v.info());
	# s := paste(s,'\n table.summary()-> ',v.summary(),
	#		' (output in aips++ log-window)');
	# s := paste(s,'\n table.ismultiused()-> ',v.ismultiused());
	# s := paste(s,'\n table.lockoptions()-> ',v.lockoptions());
	# s := paste(s,'\n table.datachanged()-> ',v.datachanged());
	public.tw.message(' ');
	return s;
    }

# Helper function (replace with twf.lineup()?):

    private.nchar := function (n, str) {
	n := max(1,n);
	s := array(' ',n);		# array of n chars
	cc := split(paste(str),'');	# split into chars
	for (i in [1:len(cc)]) {
	    s[i] := cc[i];		# char-by-char
	}
	return spaste(s);		# concatenate;
    }



#=========================================================
# Finished. Initialise and return the public interface:

    private.init();
    # return public;		# only if specifically requested?

};				# closing bracket of inspect
#=========================================================

# ti := test_inspect();		# run test/demo-routine
# inspect();			# test

# tmffe := '/disk5/tms/log/monitor/MFFE-11-TempMeasure'
# inspect(table(tmffe),tmffe)



