# taqlwidget.g: a TK widget to form a table query string
# Copyright (C) 2000,2001,2002
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
# $Id: taqlwidget.g,v 19.2 2004/08/25 02:21:07 cvsmgr Exp $

pragma include once;

include 'widgetserver.g';
include 'helpmenu.g'


taqlwidget := subsequence(cdesc, title='Query Dialogue', canselect=F,
			  cansort=F, cangiving=F, height=12,
			  giving='', widgetset=dws)
{
    if (!have_gui()) {
	return throw('No Gui is available, possibly the DISPLAY environment variable is not set',
		     origin='taqlwidget.g');
    }
    if (len(cdesc) == 0) {
	return throw('empty cdesc', origin='taqlwidget.g');
    }

    const operators := "== < <= > >= !=";
    const operators2 := "== < <= > >= != =~ !~ =r !r =p !p"
    const sortlabels := ['No sort', 'Ascending', 'Descending'];

    private := [=];
    private.enabled   := T;
    private.cansort   := cansort;
    private.canselect := canselect;
    private.cangiving := cangiving;
    private.command := [select='', where='', orderby='', giving=''];
    private.sortunique := F;

    privgui := [=];
    privgui.colrecs := [=];

    private.clearselect := function() 
    {
	if (private.canselect) {
	    for (crec in privgui.colrecs) {
		crec.clabel->state(F);
	    }
	    privgui.sentry->delete('start', 'end');
	}
    }
    private.clearwhere := function() 
    {
	privgui.wentry->delete('start', 'end');
    }
    private.clearorderby := function() 
    {
	if (private.cansort) {
	    wider private;
	    for (crec in privgui.colrecs) {
		crec.optsort.selectlabel('No sort');
	    }
	    privgui.oentry->delete('start', 'end');
	    private.sortunique := F;
	    privgui.ounique->state(F);
	}
    }
    private.cleargiving := function() 
    {
	if (private.cangiving) {
	    privgui.gentry->delete('start', 'end');
	}
    }

    widgetset.tk_hold();
    privgui.outerframe := widgetset.frame(borderwidth=0, side='top',
					  title=title, expand='both');

    # top frame with file and help button
    privgui.topframe := widgetset.frame(privgui.outerframe, side='left',
					expand='x', relief='raised');
    privgui.ltopframe := widgetset.frame(privgui.topframe, side='left',
					 borderwidth=0);
    privgui.filebutton := widgetset.button(privgui.ltopframe, 'File',
					   relief='flat', type='menu');
    hlpl := paste(' Expand     expand the query form to a string',
##                  ' Showfunc  show the available TaQL functions',
		  ' Clearform  clear the query form',
		  ' Clearall   clear the query form and all strings',
		  ' Go         remove the widget and exit normally',
		  ' Cancel     cancel and remove the widget',
		  sep='\n');
    widgetset.popuphelp(privgui.filebutton, hlpl, 'File menu', combi=T);
    privgui.filemenu := [=];
    privgui.filemenu['expand'] := widgetset.button(privgui.filebutton,
						   'Expand');
##    privgui.filemenu['showfunc'] := widgetset.button(privgui.filebutton,
##						     'Show TaQL functions');
    privgui.filemenu['clearform'] := widgetset.button(privgui.filebutton,
						      'ClearForm');
    privgui.filemenu['clearall'] := widgetset.button(privgui.filebutton,
						     'ClearAll');
    privgui.filemenu['go'] := widgetset.button(privgui.filebutton,
					       'Go', type='action');
    privgui.filemenu['cancel'] := widgetset.button(privgui.filebutton,
						   'Cancel', type='dismiss');
    privgui.rtopframe := widgetset.frame(privgui.topframe, side='right',
					 borderwidth=0);
    privgui.helpmenu := widgetset.helpmenu(parent=privgui.rtopframe,
			menuitems=['about taqlwidget ...',
				   'note 199 (TaQL)'],
                        refmanitems=['Refman:utility.widgets.taqlwidget',
				     '199:labels.text'],
			helpitems=['about taqlwidget',
				   'note 199 (TaQL)']);

    # Query and sort form frame.
    # Use scrollbars when too many fields.
    if (len(cdesc) > height) {
	hc := len(cdesc)*25
	privgui.cframe := widgetset.frame(privgui.outerframe, side='left', 
					   expand='both', relief='groove',
					  borderwidth=4);
	privgui.cframe1 := widgetset.frame(privgui.cframe, side='left', 
					   expand='both', borderwidth=0);
	privgui.canvas1 := widgetset.canvas(privgui.cframe1, height=height*25,
					    region=[0,0,1000,hc],
					    relief='flat', borderwidth=0);
	privgui.cvframe1 := privgui.canvas1->frame(0, 0, side='top',
						   height=hc);
	privgui.colframe := widgetset.frame(privgui.cvframe1, side='top',
					    expand='both', relief='groove');
	if (private.cansort) {
	    privgui.cframe2 := widgetset.frame(privgui.cframe,
					       side='left', expand='y',
					       borderwidth=0);
	    privgui.canvas2 := widgetset.canvas(privgui.cframe2,
						height=height*25, width=90,
						region=[0,0,90,hc],
						fill='y', relief='flat',
						borderwidth=0);
	    privgui.cvframe2 := privgui.canvas2->frame(0, 0, side='top',
						       height=hc);
	    privgui.sortframe := widgetset.frame(privgui.cvframe2,
						 side='top', expand='y',
						 relief='groove');
	}
	privgui.vsb := widgetset.scrollbar(privgui.cframe);
	whenever privgui.vsb->scroll do {
	    privgui.canvas1->view($value);
	    if (private.cansort) {
		privgui.canvas2->view($value);
	    }
	}
	whenever privgui.canvas1->yscroll do {
            privgui.vsb->view($value);
	    if (private.cansort) {
		privgui.canvas2->view($value);
	    }
	}
	if (private.cansort) {
	    whenever privgui.canvas2->yscroll do {
		privgui.vsb->view($value);
		privgui.canvas1->view($value);
	    }
	}
    } else {
	privgui.dataframe := widgetset.frame(privgui.outerframe, side='left', 
					     expand='both');
	privgui.colframe := widgetset.frame(privgui.dataframe, side='top', 
					    expand='both', relief='groove');
	if (private.cansort) {
	    privgui.sortframe := widgetset.frame(privgui.dataframe,
						 side='top', 
						 expand='y', relief='groove');
	}
    }

    # Bottom frame
    # Use a rollup to hide the more complex functionality.
    # Make its title rather long to force the widget having a decent width.
    title := 'Advanced features                                           ';
    if (private.cansort) {
	title := spaste(title, '            ');
    }
    privgui.advrollup := widgetset.rollup(privgui.outerframe, expand='x',
					  show=F, title=title);
    privgui.expframe := widgetset.frame(privgui.advrollup.frame(), side='left',
					expand='x', borderwidth=0);
    privgui.buttonframe1 := widgetset.frame(privgui.advrollup.frame(),
					    side='left', expand='x');
    privgui.lowerframe := widgetset.frame(privgui.advrollup.frame(),
					  side='top', expand='x',
					  borderwidth=0);

    privgui.buttonframe2 := widgetset.frame(privgui.outerframe, side='left', 
					    expand='x');

    whlps := 'Menu for various operations on the XX entry';
    whlpl := paste(' Clear  clear the XX string',
		   ' Copy   copy the XX string to the clipboard',
		   ' Paste  paste the XX string from the clipboard',
		   sep='\n');
    # resulting select string
    if (private.canselect) {
	hlps := 'Columns to select from the input table';
	hlpl := paste('If no columns are given, all columns will be',
		      'selected. Otherwise only the given columns',
		      'are selected (in the given order).',
		      'It can be filled in by clicking on the',
		      'checkbox in front of the column names',
		      'in the query form.',
		      sep='\n');
	privgui.stframe := widgetset.frame(privgui.lowerframe,
					   side='right', expand='x',
					   borderwidth=0);
	privgui.swrench := widgetset.button(privgui.stframe, 'Menu',
					    bitmap='spanner.xbm', 
					    type='menu', relief='raised');
	widgetset.popuphelp(privgui.swrench, whlpl~s/XX/select/g,
			    whlps~s/XX/select/g, combi=T);
	privgui.sframe := widgetset.frame(privgui.stframe,
					  side='left', expand='x',
					  borderwidth=0);
	privgui.slabel := widgetset.label(privgui.sframe,
					  'Select:');
	widgetset.popuphelp (privgui.slabel, hlpl, hlps, combi=T);
	privgui.sentry := widgetset.entry(privgui.sframe, width=60,
					  fill='x');
	widgetset.popuphelp (privgui.sentry, hlpl, hlps, combi=T);
	privgui.sentry.clearfunc := private.clearselect;
	for (opt in ['clear select entry',
		     'copy to clipboard',
		     'paste from clipboard']) {
	    privgui.swrench[opt] := widgetset.button(privgui.swrench, opt);
	    whenever privgui.swrench[opt]->press do {
		private.handlewrench ($agent->text(), privgui.sentry);
	    }
	}
    }

    # resulting where string
    hlps := 'Resulting (editable) query string';
    hlpl := paste('Its components are formed from the query form above.',
		  'Components can be combined using the buttons (AND, etc.).',
		  'It is possible to edit the query string directly.',
		  sep='\n');
    privgui.wtframe := widgetset.frame(privgui.lowerframe,
				       side='right', expand='x',
				       borderwidth=0);
    privgui.wwrench := widgetset.button(privgui.wtframe, 'Menu',
					bitmap='spanner.xbm', 
					type='menu', relief='raised');
    widgetset.popuphelp(privgui.wwrench, whlpl~s/XX/where/g,
			whlps~s/XX/where/g, combi=T);
    privgui.wframe := widgetset.frame(privgui.wtframe,
				      side='left', expand='x',
				      borderwidth=0);
    privgui.wlabel := widgetset.label(privgui.wframe, 'Where: ');
    widgetset.popuphelp (privgui.wlabel, hlpl, hlps, combi=T);
    privgui.wentry := widgetset.entry(privgui.wframe, width=60, fill='x');
    widgetset.popuphelp (privgui.wentry, hlpl, hlps, combi=T);
    privgui.wentry.clearfunc := private.clearwhere;
    for (opt in ['clear where entry',
		 'copy to clipboard',
		 'paste from clipboard']) {
	privgui.wwrench[opt] := widgetset.button(privgui.wwrench, opt);
	whenever privgui.wwrench[opt]->press do {
	    private.handlewrench ($agent->text(), privgui.wentry);
	}
    }

    # resulting orderby string
    if (private.cansort) {
	hlps := 'Resulting (editable) sort string';
	hlpl := paste('Sort keys are inserted using the sort buttons above.',
		      'Each key can be in ascending or descending order.',
		      'The order of the keys is determined by the order',
		      'in which the sort buttons are pressed.',
		      'It is possible to edit the sort string directly.',
		      sep='\n');
	privgui.otframe := widgetset.frame(privgui.lowerframe,
					   side='right', expand='x',
					   borderwidth=0);
	privgui.owrench := widgetset.button(privgui.otframe, 'Menu',
					    bitmap='spanner.xbm', 
					    type='menu', relief='raised');
	widgetset.popuphelp(privgui.owrench, whlpl~s/XX/orderby/g,
			    whlps~s/XX/orderby/g, combi=T);
	privgui.oframe := widgetset.frame(privgui.otframe,
					  side='left', expand='x',
					  borderwidth=0);
	privgui.olabel := widgetset.label(privgui.oframe,
					  'Orderby:');
	widgetset.popuphelp (privgui.olabel, hlpl, hlps, combi=T);
	privgui.ounique := widgetset.button(privgui.oframe, 'Unique',
					    type='check');
	widgetset.popuphelp (privgui.ounique,
			     'sort uniquely (skip duplicates)');
	privgui.oentry := widgetset.entry(privgui.oframe, width=60,
					  fill='x');
	widgetset.popuphelp (privgui.oentry, hlpl, hlps, combi=T);
	privgui.oentry.clearfunc := private.clearorderby;
	for (opt in ['clear orderby entry',
		     'copy to clipboard',
		     'paste from clipboard']) {
	    privgui.owrench[opt] := widgetset.button(privgui.owrench, opt);
	    whenever privgui.owrench[opt]->press do {
		private.handlewrench ($agent->text(), privgui.oentry);
	    }
	}
	whenever privgui.ounique->press do {
	    private.sortunique := !private.sortunique;
	}
    }

    # giving string
    if (private.cangiving) {
	hlps := 'Name of resulting table';
	hlpl := paste('If no name is given, the resulting reference',
		      'table is transient. Otherwise the result is',
		      'is persistenly stored in table with this name.',
		      sep='\n');
	privgui.gtframe := widgetset.frame(privgui.lowerframe,
					   side='right', expand='x',
					   borderwidth=0);
	privgui.gwrench := widgetset.button(privgui.gtframe, 'Menu',
					    bitmap='spanner.xbm', 
					    type='menu', relief='raised');
	widgetset.popuphelp(privgui.gwrench, whlpl~s/XX/giving/g,
			    whlps~s/XX/giving/g, combi=T);
	privgui.gframe := widgetset.frame(privgui.gtframe,
					  side='left', expand='x',
					  borderwidth=0);
	privgui.glabel := widgetset.label(privgui.gframe,
					  'Giving:');
	widgetset.popuphelp (privgui.glabel, hlpl, hlps, combi=T);
	privgui.gentry := widgetset.entry(privgui.gframe, width=60,
					  fill='x');
	widgetset.popuphelp (privgui.gentry, hlpl, hlps, combi=T);
	if (giving != '') {
	    privgui.gentry->insert (giving);
	}
	privgui.gentry.clearfunc := private.cleargiving;
	for (opt in ['clear giving entry',
		     'copy to clipboard',
		     'paste from clipboard']) {
	    privgui.gwrench[opt] := widgetset.button(privgui.gwrench, opt);
	    whenever privgui.gwrench[opt]->press do {
		private.handlewrench ($agent->text(), privgui.gentry);
	    }
	}
    }

    # expanded query form
    hlpl := paste('As a test the query form can be expanded to a string',
		  'using the Expand button.',
		  'It shows the query string component resulting from',
		  'the current contents of the query form.',
		  'Using the buttons below (Replace, OR, etc.) the query',
		  'form contents can be appended to the query string.',
		  sep='\n');
    privgui.expbut := widgetset.button(privgui.expframe, 'Expand query_form');
    widgetset.popuphelp (privgui.expbut, hlpl,
			 'Expand the query form to a string', combi=T);
    privgui.expentry := widgetset.message(privgui.expframe, text='',
					  width=7*54,
					  fill='x', anchor='w');
    widgetset.popuphelp (privgui.expbut, hlpl,
			 'Expanded query form', combi=T);

    # button frame
    privgui.lbutframe1 := widgetset.frame(privgui.buttonframe1, side='left',
					  expand='x', borderwidth=0);
    privgui.rbutframe1 := widgetset.frame(privgui.buttonframe1, side='right',
					  borderwidth=0);
    privgui.rbutframe1r := widgetset.frame(privgui.rbutframe1, side='right',
					   borderwidth=0);
##    privgui.rbutframe1l := widgetset.frame(privgui.rbutframe1, side='left',
##					   borderwidth=0);

    hlpl := 'Replace the query string by the contents of the query form.';
    privgui.replbut := widgetset.button(privgui.lbutframe1, 'Replace');
    widgetset.popuphelp (privgui.replbut, hlpl,
			 'query_string := query_form', combi=T);

    hlpl := paste('Append the contents of the query form to the query string',
		  'by forming the OR of the string and the form.',
		  sep='\n');
    privgui.orbut := widgetset.button(privgui.lbutframe1, 'OR');
    widgetset.popuphelp (privgui.orbut, hlpl,
			 'query_string := query_string || query_form',
			 combi=T);

    hlpl := paste('Append the contents of the query form to the query string',
		  'by forming the AND of the string and the form.',
		  sep='\n');
    privgui.andbut := widgetset.button(privgui.lbutframe1, 'AND');
    widgetset.popuphelp (privgui.andbut, hlpl,
			 'query_string := query_string && query_form',
			 combi=T);

    hlpl := 'Replace the query string by its negation.';
    privgui.notbut := widgetset.button(privgui.lbutframe1, 'NOT');
    widgetset.popuphelp (privgui.notbut, hlpl,
			 'query_string := !(query_string)', combi=T);

    hlpl := paste('Enclose the query string in parentheses',
		  'to get correct precedences',
		  sep='\n');
    privgui.parbut := widgetset.button(privgui.lbutframe1, 'Parentheses');
    widgetset.popuphelp (privgui.parbut, hlpl,
			 'query_string := (query_string)', combi=T);

##    privgui.funcbut := widgetset.button(privgui.rbutframe1l, 'ShowFunc');
##    widgetset.popuphelp (privgui.funcbut, 'Show the available TaQL functions');

    privgui.clearbut := widgetset.button(privgui.rbutframe1r, 'ClearForm');
    widgetset.popuphelp (privgui.clearbut, 'Clear the query form');

    # Bottom (always visible) buttons.
    privgui.lbutframe2 := widgetset.frame(privgui.buttonframe2, side='left',
					  expand='x', borderwidth=0);
    privgui.rbutframe2 := widgetset.frame(privgui.buttonframe2, side='right',
					  borderwidth=0);
    hlpl := paste('If the query string is still empty, it is filled',
		  'with the contents of the query form (if any).',
		  'If the query string is not empty, it is left as is.',
		  sep='\n');
    privgui.gobut := widgetset.button(privgui.lbutframe2, 'Go', type='action');
    widgetset.popuphelp (privgui.gobut, hlpl,
			 'Remove the widget and exit normally', combi=T);

    privgui.clallbut := widgetset.button(privgui.rbutframe2, 'ClearAll');
    widgetset.popuphelp (privgui.clallbut,
			 'Clear the query form and all strings');
    
    hlpl := 'The query ';
    if (private.cansort) {
	hlpl := spaste(hlpl, 'and sort ');
    }
    hlpl := spaste (hlpl, 'string will be cleared first.');
    privgui.cancelbut := widgetset.button(privgui.rbutframe2, 'Cancel',
					  type='dismiss');
    widgetset.popuphelp (privgui.cancelbut, hlpl,
			 'Cancel and remove the widget', combi=T);


    # callback on wrench menu.
    private.handlewrench := function (type, entry)
    {
	if (type =~ m/^clear/) {
	    entry.clearfunc();
	} else {
	    include 'clipboard.g';
	    if (type =~ m/^copy/) {
		dcb.copy (entry->get());
	    } else {
		entry->insert (dcb.paste());
	    }
	}
    }

    # callback on Go and Expand button.  Creates the specified query string
    private.expand := function() 
    {
	nrparts := 0;
	qstr := '';
	for (crec in privgui.colrecs) {
	    str := private.createcolqstr(crec);
	    if (strlen(str) > 0) {
		if (nrparts > 0) {
		    qstr := spaste(qstr, ' && ');
		}
		qstr := spaste(qstr, str);
		nrparts +:= 1;
	    }
	}
	if (nrparts <= 1) {
	    return qstr;
	}
	return spaste('(', qstr, ')');
    }

    private.clearform := function() 
    {
	for (crec in privgui.colrecs) {
	    crec.op.selectlabel('==');
	    if (has_field(crec, 'optval')) {
		crec.optval.selectindex(1);
	    }
	    if (has_field(crec, 'smenu')) {
		if (crec.smenu1disabled) {
		    crec.smenum->enable();
		    crec.smenuc->enable();
		    crec.smenus->enable();
		    crec.smenue->enable();
		    crec.smenu1disabled := F;
		}
		crec.smenum->state(T);
		crec.qbut->state(T);
		crec.casebut->state(F);
	    }
	    crec.val->delete('start', 'end');
	}
	privgui.expentry->text('');
    }

    private.multivalue := function (ref str, oper, inquotes, ignorecase,
				    smatch, istime, funcname)
    {
	s := split(str,'');
	l := len(s);
	multi := (oper=='IN' | oper=='!IN');
	out := '';
	nparen := 0;
	squote := F;
	dquote := F;
	st := 1;
	for (i in 1:l) {
# Skip characters if needed (e.g. the latter part of <:<).
	  if (i >= st) {
	    tmp := s[i];
# Handle possible single or double quotes.
	    if (tmp == '"'  &&  !squote) {
		dquote := !dquote;
	    } else {
		if (tmp == "'"  &&  !dquote) {
		    squote := !squote;
		} else {
		    if (!dquote && !squote) {
# Count the number of balanced parentheses (outside quoted strings)
# in the subexpression.
			if (tmp == '(') {
			    nparen +:= 1;
			} else if (nparen > 0) {
			    if (tmp == ')') {
				nparen -:= 1;
			    }
			} else {
# Set a switch if we have a comma or so (outside quoted and expressions).
# Get the value and append to the output string.
			    if (tmp ~ m/[,}>]/  ||  (!istime && tmp==':')) {
				multi := T;
				v := ' ';
				if (i > st) {
				    v := s[st:(i-1)];
				}
				private.appendvalue (out, v,
						     inquotes, ignorecase,
						     smatch, oper, istime,
						     funcname, tmp);
				st := i+1;
			    }
# Test if an interval range operator is given.
			    if (tmp == '<'  ||  tmp == '=') {
			      if (i < l-1  &&  s[i+1] == ':') {
				if (s[i+2] == '<'  ||  s[i+2] == '=') {
				  multi := T;
                                  v := ' ';
				  if (i > st) {
				    v := s[st:(i-1)];
				  }
				  private.appendvalue (out, v,
						       inquotes, ignorecase,
						       smatch, oper, istime,
						       funcname,
						       spaste(s[i:(i+2)]));
				  st := i+3;
			        }
			      }
			    }
# Test if a begin or end interval is given.
# The unparsed string before it should be empty.
			    if (i >= st) {
				if (tmp == '{'  || tmp == '<') {
				    ok := T;
				    if (i > st) {
					ok := spaste(s[st:i-1]) ~ m/^ *$/
				    }
				    if (ok) {
					out := spaste(out,tmp);
					st := i+1;
				    }
				}
			    }
			}
		    }
		}
	    }
	  }
	}
# Append last value (if there is one).
        if (st <= l) {
	    private.appendvalue (out, s[st:l], inquotes, ignorecase,
				 smatch, oper, istime, funcname, '');
	}
	if (multi) {
	    out := spaste('[', out, ']');
	}
	val str := out;
	return multi;
    }

    private.appendvalue := function (ref out, value, inquotes, ignorecase,
				     smatch, oper, istime, funcname, sep)
    {
        # Ignore leading and trailing blanks around the value.
	st := 1;
	end := len(value);
	while (st <= end  &&  value[st] == ' ') {
	    st +:= 1;
	}
	while (end >= st  &&  value[end] == ' ') {
	    end -:= 1;
	}
	leng := end-st+1;

	# Only add separator for empty strings.
	if (leng == 0) {
	    val out := spaste(out, sep);
	    return;
	}
	# Do we have a special string match (a regex or pattern).
	re := (oper == '=r'  ||  oper == '!r');    # regex?
	pa := (oper == '=p'  ||  oper == '!p');    # pattern?
	if (oper == '=~'  ||  oper == '!~') {
	    re := T;                               # make regex with
	    smatch := 2;                           # 'contains' option
	}
	# Simply append value if nothing special to do.
	if (!pa && !re && !inquotes && !istime && !ignorecase && smatch==1) {
	    val out := spaste (out, spaste(value[st:end]), sep);
	    return;
	}
	# Determine the quote needed.
	# If quotes are needed, use " as the default quote character.
	# Removes possible quotes around the string.
	quote := '';
	if (inquotes) {
	    quote := '"';
	}
	if (value[st] == '"'  ||  value[st] == "'") {
	    if (end>st  &&  value[end] == value[st]) {
		quote := value[st];
		inquotes := T;
		st +:=1;
		end -:= 1;
	    }
	}
	# Turn the array of characters into a single string.
	v := spaste (value[st:end]);
	# Supply trailing colon if only hours are given.
	if (istime) {
	    if (v ~ m%/[0-9]*$%) {
		v := spaste (v, ':');
	    }
	}
	# Insert regex characters for arbitrary start or end parts.
	# In such a case a regex is needed (if not a pattern already).
	strw := '.*';
	if (pa) strw := '*';
	strs := '';
	stre := '';
	if (smatch == 2  ||  smatch == 3) {
	    stre := strw;                          # anything at end
	    if (!pa) re := T;
	}
	if (smatch == 2  ||  smatch == 4) {
	    strs := strw;                          # anything at beginning
	    if (!pa) re := T;
	}
	# Turn the array into a string.
	# If the string is quoted make the wildcards part of the string.
	if (inquotes) {
	    v := spaste (quote, strs, v, stre, quote);
	}
	# Turn to lowercase if case has to be ignored.
	# A quoted string can be done as such, but an unquoted string
	# (which can be a variable name) has to be done on-the-fly.
	if (ignorecase) {
	    if (inquotes) {
		v := to_lower(v);
	    } else {
		v := spaste('to_lower(', v, ')');
	    }
	}
	# If the value is not quoted (thus a column name or so),
	# append the wildcards by adding them on-the-fly.
	if (!inquotes) {
	    if (strs != '') {
		v := spaste ('"', strs, '"+', v);
	    }
	    if (stre != '') {
		v := spaste (v, '+"', stre, '"');
	    }
	}
	# Turn it into a regex or pattern function when needed.
	# Add a function name if one provided.
	if (re) {
	    v := spaste('regex(', v, ')');
	} else if (pa) {
	    v := spaste('pattern(', v, ')');
	} else if (funcname != '') {
	    v := spaste(funcname, '(', v, ')');
	}
	val out := spaste (out, v, sep);
    }

    private.createcolqstr := function(crec)
    {
	str := crec.val->get();
	smatch := 1;
	inquotes := crec.isstring || crec.istime;
	ignorecase := F;
	if (has_field(crec, 'smenu')) {
	    inquotes := crec.qbut->state();
	    ignorecase := crec.casebut->state();
	    if (! crec.smenu1disabled) {
		if (crec.smenum->state()) smatch := 1;
		if (crec.smenuc->state()) smatch := 2;
		if (crec.smenus->state()) smatch := 3;
		if (crec.smenue->state()) smatch := 4;
	    }
	}
	if (strlen(str) > 0) {
	    op := crec.op.getvalue();
	    funcname := '';
	    if (crec.istime  &&  !crec.isstring) {
		funcname := 'mjd';
	    }
	    multi := private.multivalue(str, op, inquotes, ignorecase,
					smatch, crec.istime, funcname);
	    if (strlen(str) > 0) {
		if (op ~ m/=./) op := '==';      # replace =~, etc. by ==
		if (op ~ m/!./) op := '!=';
		if (multi) {
		    if (op == '==') {
			op := 'IN';
		    } else if (op == '!=') {
			op := '!IN';
		    }
		}
		name := crec.name;
		if (crec.istime) {
		    if (crec.isstring) {
			name := spaste('datetime(', name, ')');
		    } else {
			name := spaste(name, '/(24*3600)');
		    }
		    if (crec.tzoffset != 0) {
			name := spaste('(', name, '+', crec.tzoffset, '/24)');
		    }
		}
		if (ignorecase) {
		    name := spaste('to_lower(', name, ')');
		}
		if (op == '!IN') {
		    str := spaste('!(', name, ' IN ', str, ')');
		} else {
		    str := paste(name, op, str);
		}
	    }
	}
	return str;
    }

    private.createquerybox := function(parent, sortframe, name, colrec, len)
    {
	wider privgui;
	crec := [=];
	
	fstr := spaste('%-', len, 's');
	label := sprintf(fstr, name);
	if (private.canselect) {
	    crec.clabel := widgetset.button(parent, label, type='check',
					    fill='none');
	} else {
	    crec.clabel := widgetset.label(parent, label);
	}
	crec.oframe := widgetset.frame(parent, borderwidth=0, side='left', 
				       expand='x');

	# Build the short and long help string for the lable (field name).
	# Set the isstring and istime variables.
	hlps := '';
	hlpl := '';
	crec.isstring := F;
	crec.istime   := F;
	crec.tzoffset := 0.0;
	if (has_field(colrec, 'valueType')) {
	    hlps := colrec.valueType;
	    if (colrec.valueType == 'string') {
		crec.isstring := T;
	    }
	}
	if (has_field(colrec, 'istime')) {
	    crec.istime := colrec.istime;
	}
	if (crec.istime) {
	    hlps := spaste (hlps, ' time');
	    if (has_field(colrec, 'tzoffset')) {
		crec.tzoffset := colrec.tzoffset;
		hlps := spaste (hlps, ' (tzoffset=', crec.tzoffset, ' hour)');
	    }
	}
	if (has_field(colrec, 'ndim')) {
	    hlps := spaste (hlps, '  ');
	    if (colrec.ndim > 0) {
		hlps := spaste (hlps, colrec.ndim);
	    } else {
		hlps := spaste (hlps, 'n');
	    }
	    hlps := spaste (hlps, 'D array');
	    if (has_field(colrec, 'shape')) {
		hlps := spaste (hlps, ' ', colrec.shape);
	    }
	} else {
	    hlps := spaste (hlps, ' scalar');
	}
	if (crec.tzoffset != 0) {
	    hlpl := paste ('The time zone offset is added to the',
			   'field to convert it to the time zone',
			   sep='\n');
	}
	if (has_field(colrec, 'comment')) {
	    if (colrec.comment != '') {
		hlpl:= paste (hlpl, colrec.comment, sep='\n');
	    }
	}
	if (private.canselect) {
	    hlpl := paste (hlpl,
			   'Pressing the button means that the column',
			   'will be added to the select string, which',
			   'defines the columns in the output table.',
			   'Pressing a button again means that the column',
			   'will be removed from the select string.',
			   'Note that an empty select string means that',
			   'all columns will be selected.',
			   sep='\n');
	}
	widgetset.popuphelp (crec.clabel, hlpl, hlps, combi=T);

	# Comparison operator
	hlpl := paste ('If multiple values are given while == is',
		       'used, == will be changed to IN when expanding',
		       'the query form to a string.',
		       'Similarly != is changed to !IN (when needed).',
		       sep='\n');
	lab := operators;
	# Normal strings can have a regular expression.
	if (crec.isstring  &&  !crec.istime) {
	    lab := operators2;
	    hlpl := paste (hlpl, '',
			   '=~ and !~ mean that the given string',
			   ' is a regular expression (as in egrep)',
			   ' contained in the field value',
			   '=r and !r mean that the given string',
			   ' is a regular expression (as in egrep)',
			   ' matching the field value',
			   '=p and !p mean that the given string',
			   ' is a pattern (as in shell file names)',
			   ' matching the field value',
			   sep='\n');
	}
	crec.op := widgetset.optionmenu(crec.oframe, labels=lab,
					hlp='possible comparison operators',
					hlp2=hlpl);

	# Possible value values (if defined)
	if (has_field(colrec, 'labels')) {
	    if (length(colrec.labels) > 0) {
		crec.labels := colrec.labels;
		# Possible symbolic label names (if defined and same number)
		if (has_field(colrec, 'labelnames')) {
		    if (length(colrec.labels) == length(colrec.labelnames)) {
			for (i in 1:length(colrec.labels)) {
			    colrec.labels[i] :=
				spaste (colrec.labels[i],
					'  (', colrec.labelnames[i], ')');
			}
		    }
		}
		hlpl := paste ('This field has a limited set of values.',
			       'The actual values are shown here',
			       'possibly followed by their symbolic value',
			       'If a value is selected, its actual value',
			       'is appended to the values in the entry box',
			       'on the right.',
			       sep='\n');
		crec.optval := widgetset.optionmenu(crec.oframe,
						    labels=colrec.labels,
						    hlp='possible values',
						    hlp2=hlpl);
	    }

	# Normal strings can have a regular expression.
	} else if (crec.isstring  &&  !crec.istime) {
	    hlpl := paste ('exact:    field and given string must match exactly',
			   'contains: field must contain given string',
			   'starts:   field must start with given string',
			   'ends:     field must end with given string',
			   '',
			   'By default the given string will be enclosed in',
			   'quotes. You can disable this behaviour if you want',
			   'to use a function or the name of another column.',
			   '',
			   'By default the string case is important,',
			   'but you can make it ignore the case.',
			   sep='\n');
	    crec.smenu := widgetset.button(crec.oframe, 'Options', padx=3,
					   type='menu');
	    widgetset.popuphelp (crec.smenu, hlpl,
				 'String comparison options', combi=T);
##	    crec.smenu1 := widgetset.button(crec.smenu, 'String match type',
##					    type='menu');
	    crec.smenu1disabled := F;
	    crec.smenum := widgetset.button(crec.smenu, 'Exact match',
					    type='radio', value=1);
	    crec.smenuc := widgetset.button(crec.smenu, 'Contains',
					    type='radio', value=2);
	    crec.smenus := widgetset.button(crec.smenu, 'Starts with',
					    type='radio', value=3);
	    crec.smenue := widgetset.button(crec.smenu, 'Ends with',
					    type='radio', value=4);
            crec.smenum->state(T);
	    crec.sdummy1 := widgetset.button (crec.smenu, '');
	    crec.qbut := widgetset.button(crec.smenu,
					  'Enclose string in quotes',
					  type='check');
	    crec.qbut->state(T);
	    crec.casebut := widgetset.button(crec.smenu, 'Ignore case',
					     type='check');
	    crec.casebut->state(F);
	}
	

	# Value entry box.
	hlpl := paste ('It is possible to give one or more values.',
		       'Multiple values have to be separated by commas',
		       'and (in principle) enclosed in square brackets.',
		       'However, if needed, square brackets will be',
		       'inserted when expanding the query form.',
		       'The help info on the field name shows the',
		       'data type of the field.',
		       'String literals have to be enclosed in',
		       'single or double quotes.',
		       'A value does not need to be a literal.',
		       'It can also be another column or an expression.',
		       sep='\n');
	if (crec.istime  ||  !crec.isstring) {
	    hlpl := paste (hlpl,
		       'Ranges can be given like {1,2> or 1<:=2',
                       'Sequences can be given as start:end:stride',
		       sep='\n');
	}
	if (crec.istime) {
	    if (crec.isstring) {
		hlpl := paste (hlpl,
		       'This field contains a date/time as a string.',
		       'DATETIME function will be applied to the field.',
		       sep='\n');
	    } else {
		hlpl := paste (hlpl,
		       'This field contains a double date/time (in sec),',
		       'so it will be divided by 24*3600 to get days.',
		       sep='\n');
	    }
	    if (crec.tzoffset != 0) {
		hlpl := paste (hlpl, paste(
		       'Time zone offset', crec.tzoffset, 'will be added'),
			       sep='\n');
	    }
	    if (!crec.isstring) {
		hlpl := paste (hlpl,
		       'The MJD function will be applied to the values.',
		       sep='\n');
	    }
	}
	if (has_field(colrec, 'labels')) {
	    hlpl := paste (hlpl,
			   'Note that this field has a limited set of',
			   'values. They can be taken from the menu',
			   'on the left.',
			   sep='\n');
	}

	# When canvases (with scrollbar) are used, the width must
	# be set high enough. Otherwise don't do it too high because it
        # would create a very wide widget.
	if (has_field(privgui, 'cframe')) {
	    crec.val := widgetset.entry(crec.oframe, width=120, fill='x');
	} else {
	    crec.val := widgetset.entry(crec.oframe, width=30, fill='x');
	}
	widgetset.popuphelp (crec.val, hlpl,
			     'enter value(s) to be selected', combi=T);

	if (private.cansort) {
	    hlps := paste ('Optionally sort on field', name);
	    hlpl := paste ('in ascending or descending order.',
			   'Sorting can be done on multiple fields.',
			   'The sort key order is determined by the order',
			   'in which the sort buttons are pressed. The',
			   'resulting sort string is shown at the bottom.',
			   sep='\n');
	    # If canselect=T, the width need to be 1 more (using pady).
	    # Otherwise the sort buttons do not line up with the field
	    # names and entry box.
	    pady := 3;
	    if (private.canselect) {
		pady := 4;
	    }
	    crec.optsort := widgetset.optionmenu(sortframe, labels=sortlabels, 
						 padx=3, pady=pady,
						 hlp=hlps, hlp2=hlpl);
	}

	crec.name := name;
	nr := length(privgui.colrecs)+1;
	privgui.colrecs[nr] := crec;

	if (has_field(privgui.colrecs[nr], 'optval')) {
	    whenever privgui.colrecs[nr].optval->select do {
		idx := $value.index;
		s := privgui.colrecs[nr].labels[idx];
		str := privgui.colrecs[nr].val->get();
		if (strlen(str) > 0) {
		    str := spaste(str, ',');
		}
		str := spaste (str, s);
		privgui.colrecs[nr].val->delete('start' ,'end');
		privgui.colrecs[nr].val->insert(str);
	    }
	}
	if (has_field(privgui.colrecs[nr], 'smenum')) {
	    whenever privgui.colrecs[nr].op->select do {
		s := $value.index;
		dis := ((s >= 2  &&  s <= 5)  ||  s == 7  ||  s == 8);
		if (dis != privgui.colrecs[nr].smenu1disabled) {
		    privgui.colrecs[nr].smenum->disabled(dis);
		    privgui.colrecs[nr].smenuc->disabled(dis);
		    privgui.colrecs[nr].smenus->disabled(dis);
		    privgui.colrecs[nr].smenue->disabled(dis);
		    privgui.colrecs[nr].smenu1disabled := dis;
		}
	    }
	}
	if (private.canselect) {
	    whenever privgui.colrecs[nr].clabel->press do {
		selcol := privgui.colrecs[nr].clabel->state();
		name := privgui.colrecs[nr].name;
		str := privgui.sentry->get();
		if (strlen(str) == 0) {
		    if (selcol) {
			str := name;
		    }
		} else {
		    vec := split(str, ', ');
		    fnd := (vec == name);
                    if (any(fnd) != selcol) {
			if (selcol) {
			    str := spaste(str, ', ', name);
			} else {
			    str := paste(vec[!fnd], sep=', ');
			}
		    }
		}
		privgui.sentry->delete('start' ,'end');
		privgui.sentry->insert(str);
	    }
	}
	if (private.cansort) {
	    whenever privgui.colrecs[nr].optsort->select do {
		s := $value.index;
		name := privgui.colrecs[nr].name;
		str := privgui.oentry->get();
		namef := paste(name, ["n", "Asc", "Desc"][s]);
		if (strlen(str) == 0) {
		    if (s > 1) {
			str := namef;
		    }
		} else {
		    vec1 := split(str, ',');
		    vec := split(vec1);
		    vec := vec[vec!='Asc' & vec!= 'Desc'];
		    fnd := (vec == name);
                    if (any(fnd) != (s>1)) {
			if (s>1) {
			    str := spaste(str, ', ', namef);
			} else {
			    str := paste(vec1[!fnd], sep=', ');
			}
		    }
		}
		privgui.oentry->delete('start' ,'end');
		privgui.oentry->insert(str);
	    }
	}
    }

    # find the maximum name length
    names := field_names(cdesc);
    maxlen := max(strlen(names));

    privgui.cframes := [=];
    if (private.cansort) {
	privgui.sframes := [=];
    }
    nr := 0;
    for (crec in cdesc) {
	nr +:= 1;
	privgui.cframes[nr] := 
	    widgetset.frame(privgui.colframe, side='left', expand='both',
			    borderwidth=0);
	if (private.cansort) {
	    privgui.sframes[nr] := 
		widgetset.frame(privgui.sortframe, side='left', expand='y',
				borderwidth=0);
	    private.createquerybox(privgui.cframes[nr],
				   privgui.sframes[nr],
				   names[nr], crec, maxlen);
	} else {
	    private.createquerybox(privgui.cframes[nr],
				   F,
				   names[nr], crec, maxlen);
	}
    }

    widgetset.tk_release();


    whenever privgui.expbut->press, privgui.filemenu['expand']->press do {
	privgui.advrollup.show();
	privgui.expentry->text(private.expand());
    }
##    whenever privgui.funcbut->press, privgui.filemenu['showfunc']->press do {
##	private.showfunc();
##    }
    whenever privgui.replbut->press do {
	qstr := private.expand();
	privgui.wentry->delete('start', 'end');
	privgui.wentry->insert(qstr);
    }
    whenever privgui.orbut->press do {
	qstr := spaste(privgui.wentry->get(), ' || ', private.expand());
	privgui.wentry->delete('start', 'end');
	privgui.wentry->insert(qstr);
    }
    whenever privgui.andbut->press do {
	qstr := spaste(privgui.wentry->get(), ' && ', private.expand());
	privgui.wentry->delete('start', 'end');
	privgui.wentry->insert(qstr);
    }
    whenever privgui.notbut->press do {
	qstr := spaste('!(', privgui.wentry->get(), ')');
	privgui.wentry->delete('start', 'end');
	privgui.wentry->insert(qstr);
    }
    whenever privgui.parbut->press do {
	qstr := spaste('(', privgui.wentry->get(), ')');
	privgui.wentry->delete('start', 'end');
	privgui.wentry->insert(qstr);
    }
    whenever privgui.clearbut->press, privgui.filemenu['clearform']->press do {
	private.clearform();
    }
    whenever privgui.clallbut->press, privgui.filemenu['clearall']->press do {
	private.clearselect();
	private.clearform();
	private.clearwhere()
	private.clearorderby();
	private.cleargiving();
    }

    whenever privgui.gobut->press, privgui.filemenu['go']->press do {
	wider private;
	wider privgui;
	private.command.where := privgui.wentry->get();
	if (private.canselect) {
	    private.command.select := privgui.sentry->get();
	}
	if (strlen(private.command.where) == 0) {
	    private.command.where := private.expand();
	}
	if (private.cansort) {
	    private.command.orderby := privgui.oentry->get();
	    if (private.sortunique  &&  private.command.orderby != '') {
		private.command.orderby := paste('Noduplicates',
						 private.command.orderby);
	    }
	}
	if (private.cangiving) {
	    private.command.giving := privgui.gentry->get();
	}
	privgui.outerframe->unmap();
	tmp := private.command;
	val privgui := F;
	val private := F;
	self->returns(tmp);
    }
    whenever privgui.cancelbut->press,
	     privgui.filemenu['cancel']->press,
	     privgui.outerframe->killed do {
	wider private;
	wider privgui;
	if (has_field(privgui, 'outerframe')) {
	    privgui.outerframe->unmap();
	}
	val privgui := F;
	val private := F;
	tmp := [select='', where='', orderby='', giving=''];
	self->returns(tmp);
    }

    whenever self->close do {
	wider private;
	wider privgui;
	if (has_field(privgui, 'outerframe')) {
	    privgui.outerframe->unmap();
	}
	val private := F;
	val privgui := F;
    }


    self.disable := function() 
    {
	if (has_field(privgui, 'outerframe')) {
	    if (private.enabled) {
		wider private;
		privgui.outerframe->disable();
		private.enabled := F;
	    }
	}
	return T;
    }
    self.enable := function() 
    {
	if (has_field(privgui, 'outerframe')) {
	    if (!private.enabled) {
		wider private;
		private.outerframe->enable();
		private.enabled := T;
	    }
	}
	return T;
    }
    self.done := function ()
    {
	wider private;
	wider privgui;
	if (has_field(privgui, 'outerframe')) {
	    privgui.outerframe->unmap();
	}
	val private := F;
	val privgui := F;
	return T;
    }
} 


taqlwidgettest := function(canselect=F,cansort=F,cangiving=F,wait=T,
			   height=10,giving='')
{
    cdesc := [=];
    cdesc.col1 := [=];
    cdesc.col1.valueType := 'integer';
    cdesc.EventOrigin := [=];
    cdesc.EventOrigin.valueType := 'string';
    cdesc.EventOrigin.labels := "the quick brown fox";
    cdesc.col2 := [valueType='integer', ndim=-1];
    cdesc.col2.labels := "1 2 3 4 5 6";
    cdesc.col2.labelnames := "pen sugar jacket at the table";
    cdesc.SequenceNr := [valueType='double', ndim=2, shape=[3,4]];
    cdesc.Time := [valueType='double', istime=T, comment='UTC in sec'];
    cdesc.TimeStr := [valueType='string', istime=T];
    cdesc.Time2 := [valueType='double', istime=T, comment='local in sec',
		    tzoffset=2];
    cdesc.TimeStr2 := [valueType='string', istime=T, tzoffset=2];
    cdesc.col3 := [=];
    cdesc.col3.valueType := 'string';

    q := taqlwidget(cdesc, canselect=canselect,
		    cansort=cansort, cangiving=cangiving,
		    height=height, giving=giving);
    if (!wait) {
	return q;
    }
    await q->returns;
    return $value;
}
