# viewer.g: skycatalog - a tool which holds special sskycatalog tables
# Copyright (C) 2001,2003
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
# $Id:

pragma include once;

include 'misc.g';
include 'unset.g';
include 'table.g';
#include 'minicatalog.g';
#include 'widgetserver.g';
include 'quanta.g';
include 'measures.g';
include 'componentlist.g';
include 'catalog.g';

const is_skycatalog := function(scat) {
    if (is_agent(scat) && has_field(scat,'type') &&
	scat.type() == 'skycatalog') {
	return T;
    }
    return F;
}


const skycatalog := subsequence(filename=unset) {
    if (is_unset(filename)) {
	fail 'this tool has to be associated with a table';
    } else if (!is_string(filename)) {
	fail 'The argument "filename" is not of type string.';
    }
    its.tblname := filename;
    type := dc.whatis(filename).type;
    if (type == 'Skycatalog') {
	its.skycattbl:= table(filename,readonly=F);
    } else if (type != 'Non-existent') {
	fail 'File already exists and is not a Skycatalog table.'
    } else {
	its.skycattbl := unset;
    }
    const self.type := function() {
	return 'skycatalog';
    }

    self.name := function() {
	return its.tblname;
    }

    self.browse := function() {
	if (is_table(its.skycattbl)) {
	    its.skycattbl.browse();
	} else { 
	    fail 'No table associated with this tool';
	}
    }
    self.table := function() {
	if (is_table(its.skycattbl)) {
	    return its.skycattbl;
	} else { 
	    fail 'No table associated with this tool';
	}
    }
    
    self.done := function(delete=F) {
	wider its,self;
	if (is_table(its.skycattbl)) {
	    x := its.skycattbl.name();
	    t := its.skycattbl.close();

	    if (delete) {
		t := tabledelete(x);
		if (is_fail(t)) fail;
	    }
	}
	val its := F;
	val self := F;
	return T;
    }

    its.hascolumn := function(colname) {
	if (!any(its.skycattbl.colnames() == colname)) {
	    return F;
	}
	return T;
    }
    

    self.addunit := function(colname,unit) {
	if (!is_string(colname) || !is_string(unit))
	    fail 'arguments have to be of type "string"';
	if (!its.hascolumn(colname)) fail 'Specified column doesn\'t exists.';
	t := dq.quantity(unit);
	if (is_fail(t)) fail;
	unit := dq.getunit(t);
 	if (is_table(its.skycattbl)) {
	    ok := its.skycattbl.putcolkeyword(colname,'UNIT',unit);
	    if (is_fail(ok)) fail;
	    t := its.skycattbl.flush();
	    return T;
	}
	return F;	
    }

    self.renamecolumn := function(oldname, newname) {
	if (!is_string(newname)) 
	    fail 'argument "newname" has to be of type "string"';
	if (!its.hascolumn(oldname)) fail 'Specified column doesn\'t exists.';
	t := its.skycattbl.renamecol(oldname,newname);
	if (is_fail(t)) fail;
	return T;
    }

    self.mergecolumns := function(columns,name=unset) {      
	wider its;
	if (length(columns) < 2) fail 'number of columns to merge < 2';
        local newname := '';
	local removeold := F;
        if (is_unset(name)) {
            newname := columns[1];
	    removeold := T;
        } else {
            newname := name;
        }       
	if (is_table(its.skycattbl)) {
	    local ok := T;
	    cols := its.skycattbl.colnames();
	    for (str in columns) {
		ok := ok & any(cols == str);
	    }
	    if (!ok) {
		fail 'Column name not found';
	    }
	    if (removeold) {
		str :=  spaste('__',newname);
		its.skycattbl.renamecol(newname,str);
		columns[1] := str;
	    }
	    td := tablecreatescalarcoldesc(newname,'hastobestring');
	    if (is_fail(td)) fail;
	    t := its.skycattbl.addcols(td);
	    if (is_fail(t)) fail;
	    local newcol := "";
            for (i in 1:its.skycattbl.nrows()) {
                local out :="";	       
                for (k in 1:len(columns)) {
                    colval := its.skycattbl.getcell(columns[k],i);
                    out := spaste(out,colval,' ');
                }
                out =~ s/\s+$//;
                newcol[i] := out;
            }
	    t:= its.skycattbl.removecols(columns);
	    if (is_fail(t)) fail;
	    
	    t:= its.skycattbl.putcol(newname,newcol);
	    if (is_fail(t)) fail;	    
	    t := its.skycattbl.flush();
	    return T;
	}
	return F;
    }


    its.basetable := function(nrows=0) {
	wider its;
	tcol1 := tablecreatescalarcoldesc("Type","J2000");
	if (is_fail(tcol1)) fail;
	tcol2 := tablecreatescalarcoldesc("Long",as_double(0.0));
	if (is_fail(tcol2)) fail;
	tcol3 := tablecreatescalarcoldesc("Lat",as_double(0.0));
	if (is_fail(tcol3)) fail;	
	td:=tablecreatedesc(tcol1,tcol2,tcol3);
	if (is_fail(td)) fail;
	its.skycattbl:=table(its.tblname, nrow=nrows,
			   tabledesc=td, readonly=F);
	if (is_fail(its.skycattbl)) fail;
	its.skycattbl.putinfo([type='Skycatalog', isTable=T, subType='', readme='']);
	its.skycattbl.flush();			    
	return T;
    }


    self.fromcomponentlist := function(cl=unset) {
	if (!is_unset(its.skycattbl)) {
	    return throw('Can\'t execute function. A table already exists and can\'t be overwritten.',
                         origin= 'skycatalog.fromcomponentlist');

	}
	wider its;
	if (is_unset(cl)) {
	    fail 'please specify a compontentlist tool';
	}
	
	if (!is_componentlist(cl)) {
	    fail 'Argument is not a componentlist tool';
	}
	n := cl.length();
	if (n==0) {
	    fail 'empty componentlist';
	}
	t := its.basetable(n);
	if (is_fail(t)) fail;
	tcol1 := tablecreatescalarcoldesc("Annotation","typeisstring");
	if (is_fail(tcol1)) fail;
	tcol2 := tablecreatescalarcoldesc("Flux", as_float(0.0));
	if (is_fail(tcol2)) fail;
	td:=tablecreatedesc(tcol1,tcol2);
	if (is_fail(td)) fail;
	t := its.skycattbl.addcols(td);
	if (is_fail(t)) fail;
	
	# Convert to record	
	rec := [=];
	for (i in 1:n) {
	    rec[i] := [=];
	    rec[i].dirref := dm.getref(cl.getrefdir(i));
	    rec[i].long := as_double(cl.getrefdirra(i, 'deg',16)); 
	    rec[i].lat := as_double(cl.getrefdirdec(i, 'deg',16));
	    rec[i].dirunit := 'deg';	    
	    rec[i].flux := as_float(cl.getfluxvalue(i)[1]);
	    rec[i].fluxunit := cl.getfluxunit(i);    
	    rec[i].annotation := spaste('Src ', i);
	}

	# we grab the units, which are the same for all sources (all from the
	# same image)
	longunit := rec[1].dirunit;
	latunit := rec[1].dirunit;
	fluxunit := rec[1].fluxunit;
	# and we put them as keywords into the table
	ok := its.skycattbl.putcolkeyword('Long','UNIT',longunit);
	if (is_fail(ok)) fail;
	ok := its.skycattbl.putcolkeyword('Lat','UNIT',latunit);
	if (is_fail(ok)) fail;	
	ok := its.skycattbl.putcolkeyword('Flux','UNIT',fluxunit);
	if (is_fail(ok)) fail;	
	# Now fill the skeleton with the sources we found
	for (i in 1:n) {
	    #its.skycattbl.addrows();
	    its.skycattbl.putcell('Annotation',i,rec[i].annotation);
	    its.skycattbl.putcell('Type',i,rec[i].dirref);
	    its.skycattbl.putcell('Long',i,rec[i].long);
	    its.skycattbl.putcell('Lat',i,rec[i].lat);
	    its.skycattbl.putcell('Flux',i,rec[i].flux);
	}
	t := its.skycattbl.flush();
	return T;
    }
    self.fromascii := function(asciifile=unset,hasheader=F,longcol=unset,
			       latcol=unset,dirtype='J2000',unit='deg',
			       sep=' ') {
	if (!is_unset(its.skycattbl)) {
	    return throw('Can\'t execute function. A table already exists and can\'t be overwritten.',
                         origin= 'skycatalog.fromascii');
	}
	wider its;
	pits := [=];
	pits.refcodes := "J2000 B1950 GALACTIC SUPERGAL";       
	if (is_unset(asciifile)) {
	    fail 'No input file given';	   	    
	}
	pits.file := asciifile;
	if ((!is_string(longcol) && !is_integer(longcol)) || 
	    (!is_string(longcol) && !is_integer(latcol))) {
	    fail 'The column specifier was not a "string" or "integer"';
	} else {
	    if (is_integer(longcol) || is_integer(latcol)) {
		pits.longcol := spaste('Column',longcol);
		pits.latcol := spaste('Column',latcol);		
	    } else {
		pits.longcol := longcol;
		pits.latcol := latcol;
	    }
	}
       	if (!is_string(dirtype) || !is_string(unit))
	    fail 'The argument was not of type "string"';
	if (!any(pits.refcodes == dirtype)) 
	    fail 'Direction reference type not supported.';
	pits.dirtype := dirtype;
	t := dq.quantity(unit);
	if (is_fail(t)) fail;
	pits.unit := unit;

	pits.tmptbl := tablefromascii('_skycattmp.tbl',
				      pits.file,autoheader=!hasheader, 
				      sep=sep);
	if (is_fail(pits.tmptbl)) fail;
	cnames := pits.tmptbl.colnames();
	if (any(cnames == 'Long') || any(cnames == 'Lat') || 
	    any(cnames == 'Type')) {
	    pits.cleanup();
	    fail '"Long", "Lat" and "Type" are reserved column names. Please rename them.';
	}

	pits.cleanup := function() {
	    wider its;
	    if (is_table(pits.tmptbl)) {
		tabledelete(pits.tmptbl.name());
	    }
	    if (is_table(its.skycattbl)) {
		tabledelete(its.skycattbl.name());
		its.skycattbl := unset;
	    }
	}

	pits.checkcol := function(colname) {
	    wider pits;
	    if (!any(pits.tmptbl.colnames() == colname)) {
		tabledelete(pits.tmptbl.name());
		fail 'specified column doesn\'t exist in ascii file';
	    }
	    return T;
	}
	t := pits.checkcol(pits.longcol);
	if (is_fail(t)) fail;
	t := pits.checkcol(pits.latcol);
	if (is_fail(t)) fail;
	
	pits.getcell := function(colname) {
	    x := pits.tmptbl.getcell(colname,1);
	    return x;
	}
	pits.toquanta := function(instr,mode='long') {
	    out := [=];
	    if (pits.dirtype == 'J2000' || pits.dirtype == 'B1950') {
		if (mode == 'lat' && is_string(instr)) {
		    instr =~ s/:/\./g;
		}
	    }
	    out := dq.quantity(instr);
	    if (is_fail(out)) fail;
	    return out;
	}

	# create table skeleton
	pits.resttable := function() {
	    wider its;
	    td := [=];
	    for (str in pits.tmptbl.colnames()) {
		if (str != pits.longcol ||
		    str != pits.latcol) {
		    type := pits.tmptbl.coldatatype(str);
		    cast := eval(spaste('as_',to_lower(type)));
		    if (is_fail(cast)) {pits.cleanup();fail;};
		    td :=  tablecreatescalarcoldesc(str,cast(0));
		     if (is_fail(td)){pits.cleanup();fail;};
		    t := its.skycattbl.addcols(td);		    
		    if (is_fail(t)) {pits.cleanup();fail;};	    
		    # take over any keywords
		    x := its.skycattbl.getcolkeywords(str);
		    if (is_fail(x)) {pits.cleanup();fail;};
		    if (length(x) > 0) {
			its.skycattbl.putcolkeywords(x);
		    }
		    t := its.skycattbl.flush();
		}
	    }	    
	    return T;
	}    
	t := its.basetable(pits.tmptbl.nrows());
	if (is_fail(t))  {
	    pits.cleanup();
	    fail;
	}
	t := pits.resttable();
	if (is_fail(t)) {
	    pits.cleanup();
	    fail;
	}
	
	pits.filltable := function() {
	    wider its;        
	    note('Copying columns.',
		 priority='NORMAL', origin='skycatalog.fromascii');	    
	    for (str in pits.tmptbl.colnames()) {
		if (str != pits.longcol || str != pits.latcol) {
		    t := its.skycattbl.putcol(str,
					      pits.tmptbl.getcol(str));
		    if (is_fail(t)) {pits.cleanup();fail;};
		}
	    }
	    longunit :='';
	    latunit := '';
	    note('Converting Direction Coordinates...please wait.',
		 priority='NORMAL', origin='skycatalog.fromascii');
	    for (i in 1:pits.tmptbl.nrows()) {
		long := pits.tmptbl.getcell(pits.longcol,i);
		lat := pits.tmptbl.getcell(pits.latcol,i);
		qlong := pits.toquanta(long,'long');
		if (is_fail(qlong)) {pits.cleanup();fail;};
		qlat := pits.toquanta(lat,'lat');
		if (is_fail(qlat)) {pits.cleanup();fail;};
		t := its.skycattbl.putcell('Long',i,
					   as_double(dq.getvalue(qlong)));
		if (is_fail(t)) {pits.cleanup();fail;};
		t := its.skycattbl.putcell('Lat',i,
					   as_double(dq.getvalue(qlat)));
		if (is_fail(t)) {pits.cleanup();fail;};
		if (i == 1) {
		    longunit:= dq.getunit(qlong);
		    latunit:= dq.getunit(qlat);
		}
	    }
	    if (longunit !~ m/\S/) {
		longunit := pits.unit;
	    }
	    if (latunit !~ m/\S/) {
		latunit := pits.unit;
	    }
	    t := its.skycattbl.putcolkeyword('Long','UNIT',longunit);
	    if (is_fail(t)) fail 'Couldn\'t put UNIT keyword ';
	    t := its.skycattbl.putcolkeyword('Lat','UNIT',latunit);
	    if (is_fail(t)) fail 'Couldn\'t put UNIT keyword ';
	    dirtype := array(pits.dirtype,pits.tmptbl.nrows());
	    t := its.skycattbl.putcol('Type',dirtype);
	    if (is_fail(t)) fail 'Couldn\'t fill Column "Type"';

	    t := its.skycattbl.flush();
	    t := pits.tmptbl.flush();
	    return T;
	}
	t := pits.filltable();
	if (is_table(pits.tmptbl)) {
	    x := pits.tmptbl.name();
	    pits.tmptbl.close();
	    tabledelete(x);
	}
	if (is_fail(t)) fail;
	return T;
    }

}    
#    its.ws := dws;
#    its.gui := [=];
#    its.gui.btn := [=];
#    its.gui.bf : [=];
#    its.gui.lbl := [=];
#    self.gui := function() {
#	 wider its;
#	 its.gui.mf := its.ws.frame(title='ASCII to Skycatalog converter');
#	 its.gui.msgline := its.ws.label(its.gui.mf,'Welcome');
#	 its.gui.df := its.ws.frame(its.gui.mf,side='left');
#    }
#
#    self.dirgui := function() {
#	 wider its;
#	 local btns := [=];
#	 for (str in its.refcodes) {
#	     btns[str] := its.ws.button(its.gui.mf,str,value=str);
#	     whenever  btns[str]->press do {
#		 self->refcode($value);
#	     }
#	 }
#	 await self->refcode;
#	 its.refcode := $value;
#	 btns := F;
#    }
#
#    self.btngui := function() {
#	 wider its;
#	 its.gui.df := its.ws.frame(its.gui.mf);
#	 for (str in its.colnames) {
#	     its.gui.bf[str] := its.ws.frame(its.gui.df,side='left');	
#	     its.gui.btn[str] := its.ws.button(its.gui.bf[str],str,value=str);
#	     whenever  its.gui.btn[str]->press do {
#		 self->colname($value);
#	     }
#	     its.gui.lbl[str] := 
#		 its.ws.label(its.gui.bf[str],
#			      text=as_string(its.tmp.getcell(str,1)));
#	 }
#    }
#

##### EXAMPLE
## my.txt
#Name No RA       DEC       NED-ID       Max    mom0  mom1   mom2   w50
#A    A  A	  A	    A		 R      R     R	     R	    R
#NED  16 19:44:47 -14:46:51 NGC6822ee     24.255 159.8  -60.5  13.1   52.2
#NED  22 01:04:46 +02:07:04 IC1613e       13.002 328.1 -232.6   6.2   25.1
