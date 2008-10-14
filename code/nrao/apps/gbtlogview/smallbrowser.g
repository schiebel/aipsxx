# smallbrowser.g:  simple browser for use with GBT engineering logs.
# Copyright (C) 1999,2000
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
# $Id: smallbrowser.g,v 19.0 2003/07/16 03:42:23 aips2adm Exp $

# include guard
pragma include once;

# R. Norrod  6/2/97
# This utility is primarily for use with the GBT engineering
# logs.  A glish/TK interface allows the user to LOAD a table
# (generated separately by gbtlogfiller), select columns to
# display and to then scroll through a subset of rows.  All
# rows are not converted to the display window at once because
# this was found to be much too slow.  So, for now, it's best
# to convert and load only 50-100 rows at a time.

include 'unset.g';
include 'widgetserver.g';
include 'table.g';
include 'quanta.g';

gbtsmallbrowser := function(sbtable=unset) {
    prvt := [=];
    public := [=];

    prvt.sbtablename := sbtable;
    if (is_unset(prvt.sbtablename)) prvt.sbtablename := 'logtable';

    prvt.rtbl := F;
    prvt.rnames := F;
    prvt.rtime := F;
    prvt.stime := F;

    prvt.gui := [=];
    prvt.whenevers := [=];
    prvt.wheneverCount := 0;

    prvt.toDateVector := function(MJDvector,st,nv)
	# This function returns a vector of date strings from a
	#  input vector of modified julian date floats.
    {
	#  svector := [=]
	svector := '';
	ii := 1;
	endrow:=st+nv-1;
	for (i in st:endrow)
	{
	    dateMeas := dq.unit(MJDvector[i],'d');
	    svector[ii] := as_string(dq.time(dateMeas,prec=6,form="day dmy"));
	    ii := ii+1;
	}
	return svector;
    }

    prvt.addWhenever := function(awhenever) {
	wider prvt;
	prvt.wheneverCount +:= 1;
	prvt.whenevers[prvt.wheneverCount] := awhenever;
    }

    prvt.createTextFrame := function()
    {
	wider prvt;
	prvt.gui.botfr := dws.frame(prvt.gui.allfr,relief='groove');
	prvt.gui.tf := dws.frame(prvt.gui.botfr,side='left',borderwidth=0);
	prvt.gui.t := dws.text(prvt.gui.tf,relief='sunken',wrap='none',width=80,height=20);
	prvt.gui.vsb := dws.scrollbar(prvt.gui.tf);
	prvt.gui.bf := dws.frame(prvt.gui.botfr,side='right',borderwidth=0,expand='x');
	prvt.gui.pad := dws.frame(prvt.gui.bf,expand='none',width=23,height=23,relief='groove');
	prvt.gui.hsb := dws.scrollbar(prvt.gui.bf,orient='horizontal');

	whenever prvt.gui.vsb->scroll,prvt.gui.hsb->scroll do
	    prvt.gui.t->view($value);
	prvt.addWhenever(last_whenever_executed);
	whenever prvt.gui.t->yscroll do
	    prvt.gui.vsb->view($value);
	prvt.addWhenever(last_whenever_executed);
	whenever prvt.gui.t->xscroll do
	    prvt.gui.hsb->view($value);
	prvt.addWhenever(last_whenever_executed);
    }
    

    prvt.updateTextFrame := function() {
	wider prvt;
	# Start with an empty frame
	prvt.gui.t->delete('start','end');
	# Get list of selected columns from the list box
	sel := prvt.gui.lbox->selection() + 1;
	numcols := len(sel);
	# get starting row number
	startrow := as_integer(prvt.gui.startentry->get());
	# and number of rows to display
	numrows := as_integer(prvt.gui.numrowsentry->get());
	#	print 'how about here ';
	# Convert the time vector to strings for display in column 1
	#   prvt.stime := (prvt.toDateVector(prvt.rtime,startrow,numrows))
	ok := (prvt.toDateVector(prvt.rtime,startrow,numrows));
	prvt.stime:=as_string(ok);
	# 	print 'is string ',is_string(prvt.stime);
	#	print 'here? ';
	# Build a 2-D array with the selected columns
	col := array(0, numcols, numrows);
	i := 1;
	
	while (i <= numcols)
	{
	    tcol := prvt.rtbl.getcol(prvt.rnames[sel[i]]);
	    for (j in 1:numrows) col[i,j] := tcol[startrow+j-1];
	    i := i + 1;
	}
	# Build strings and send to the text frame t
	j := 1 ;
	while (j <= numrows)
	{
	    jptr := startrow + j - 1;
	    s := paste(sprintf('%05d',jptr),prvt.stime[j],sep='  ');   
	    i := 1;
	    while (i <= numcols)
	    {
		s := paste(s,sprintf('%15.3f',col[i,j]),sep='  ');
		i := i + 1;
	    }
	    s := paste(s,'\n');
	    prvt.gui.t-> append(s);
	    j := j + 1;
	}
	# Point to the top of the frame
	prvt.gui.t-> see('1.1');
    }

    prvt.done := function() {
	wider prvt;
	# deactivate all of the whenevers
	deactivate prvt.whenevers;
	prvt.whenevers := [=];
	val prvt.gui.allfr := F;
	# close rtbl if already in use
	if (is_record(prvt.rtbl) && has_field(prvt.rtbl,'done') &&
	    is_function(prvt.rtbl.done)) prvt.rtbl.done();
    }

    # build the gui, if not already there
    public.gui := function() {
	wider prvt;
	if (has_field(prvt.gui,'allfr') && is_agent(prvt.gui.allfr))
	    prvt.gui.allfr->map();
	else {
	    dws.tk_hold();
	    prvt.gui.allfr := dws.frame(side='top',title='Small Browser');

	    prvt.gui.topfr := 
		dws.frame(prvt.gui.allfr,side='left',relief='groove',expand='none');

	    #  Build the frame containing the table loading features
	    prvt.gui.loadfr := dws.frame(prvt.gui.topfr,side='top',expand='none');
	    prvt.gui.loadfrsub1 := 
		dws.frame(prvt.gui.loadfr,side='left',expand='none',relief='groove');
	    # The entry field lets user change table name
	    prvt.gui.label1 := dws.label(prvt.gui.loadfrsub1,'Table: ');
	    # it needs a horizontal scroll bar to handle long names
	    prvt.gui.loadfrsub1ef := dws.frame(prvt.gui.loadfrsub1, side='top',borderwidth=0);
	    prvt.gui.tableentry := dws.entry(prvt.gui.loadfrsub1ef,width=12);
	    prvt.gui.tablehsb := dws.scrollbar(prvt.gui.loadfrsub1ef, orient='horizontal');
	    whenever prvt.gui.tablehsb->scroll do { prvt.gui.tableentry->view($value);}
	    prvt.addWhenever(last_whenever_executed);
	    whenever prvt.gui.tableentry->xscroll do { prvt.gui.tablehsb->view($value);}
	    prvt.addWhenever(last_whenever_executed);
	    prvt.gui.tableentry->insert(prvt.sbtablename,'start');
	    whenever prvt.gui.tableentry->return do
		prvt.sbtablename := prvt.gui.tableentry->get();
	    prvt.addWhenever(last_whenever_executed);
	    # The load button 
	    prvt.gui.loadbutton := dws.button(prvt.gui.loadfrsub1,'Load',width=6);
	    whenever prvt.gui.loadbutton->press do
	    {
		# Load table and extract the time vector
		# close rtbl if already in use
		if (is_record(prvt.rtbl) && has_field(prvt.rtbl,'done') &&
		    is_function(prvt.rtbl.done)) prvt.rtbl.done();
		prvt.rtbl := table(prvt.sbtablename);
		prvt.rnames := prvt.rtbl.colnames();
		prvt.rtime := prvt.rtbl.getcol("Time");
		sbnumrows := len(prvt.rtime);
		if (sbnumrows > 50) sbnumrows := 50;

		prvt.gui.label22->text(as_string(sbnumrows));
		prvt.gui.lbox->delete('start','end');
		prvt.gui.lbox->insert(prvt.rnames,'start');
		prvt.gui.numrowsentry->delete('start','end');
		prvt.gui.numrowsentry->insert(as_string(sbnumrows),'start');
		prvt.gui.startentry->delete('start','end');
		prvt.gui.startentry->insert(as_string(1),'start');
	    }
	    prvt.addWhenever(last_whenever_executed);
	    prvt.gui.loadfrsub2 := 
		dws.frame(prvt.gui.loadfr,side='left',expand='none',relief='groove');
	    prvt.gui.label21 := dws.label(prvt.gui.loadfrsub2,'Table Rows: ');  #total rows in table
	    prvt.gui.label22 := dws.label(prvt.gui.loadfrsub2,'0',width=6);

	    prvt.gui.label23 := dws.label(prvt.gui.loadfrsub2,' Start Row: ');
	    prvt.gui.startentry := dws.entry(prvt.gui.loadfrsub2,width=6);
	    prvt.gui.startentry->insert('0');

	    prvt.gui.label24 := dws.label(prvt.gui.loadfrsub2,' Num Rows: ');
	    prvt.gui.numrowsentry := dws.entry(prvt.gui.loadfrsub2,width=6);
	    prvt.gui.numrowsentry->insert('0');

	    # Build the listbox for selecting columns
	    prvt.gui.colfr := dws.frame(prvt.gui.topfr,side='top',expand='none',relief='groove');
	    prvt.gui.labelcol := dws.label(prvt.gui.colfr,'Col Select');

	    prvt.gui.fr := dws.frame(prvt.gui.colfr,side='left',expand='none');
	    prvt.gui.lbox := dws.listbox(prvt.gui.fr,mode='multiple');
	    prvt.gui.sbar := dws.scrollbar(prvt.gui.fr);
	    prvt.gui.bf:=dws.frame(prvt.gui.colfr,side='right',borderwidth=0);
	    prvt.gui.pad:=dws.frame(prvt.gui.bf,expand='none',width=23,height=23,relief='groove');
	    prvt.gui.hbar := dws.scrollbar(prvt.gui.bf,orient='horizontal');
	    whenever prvt.gui.sbar->scroll, prvt.gui.hbar->scroll do
		prvt.gui.lbox->view($value);
	    prvt.addWhenever(last_whenever_executed);
	    whenever prvt.gui.lbox->yscroll do
		prvt.gui.sbar->view($value);
	    prvt.addWhenever(last_whenever_executed);
	    whenever prvt.gui.lbox->xscroll do
		prvt.gui.hbar->view($value);
	    prvt.addWhenever(last_whenever_executed);

	    # Build the button frame
	    prvt.gui.buttfr := dws.frame(prvt.gui.topfr,side='top');

	    # Button 1 (Display) causes the display of selected vectors in the text
	    # widget t
	    prvt.gui.b1 := dws.button(prvt.gui.buttfr,'Display',width=10);
	    whenever prvt.gui.b1->press do
	    {
		junk := prvt.updateTextFrame();
	    }
	    prvt.addWhenever(last_whenever_executed);
	
	    # Button 2 (Done) destroys the gui
	    prvt.gui.b2 := dws.button(prvt.gui.buttfr,'Done', type='dismiss', width=10);
	    whenever prvt.gui.b2->press do {
		prvt.done();
	    }
	    prvt.addWhenever(last_whenever_executed);

	    # Create an empty text frame t and wait for the user to 
	    # do something.
	    prvt.createTextFrame();
	    dws.tk_release();
	}
    }

    public.self := function() { wider prvt; return prvt;}

    return public;
}

