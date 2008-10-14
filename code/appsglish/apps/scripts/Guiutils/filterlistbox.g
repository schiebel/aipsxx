# filterlistbox.g: Listbox with filtering.
#
#   Copyright (C) 1998
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: filterlistbox.g,v 19.2 2004/08/25 01:58:56 cvsmgr Exp $
#


pragma include once;

include 'note.g'
include 'popuphelp.g'
include 'widgetserver.g'

const categoryfilter := function(ref topmenubutton, categories, callback)
{
    private := public := [=];

    private.categories := unique(['all', categories[categories != 'all']]);
    private.callback := callback;
    private.selection := 'all';

    public.select := function(name) {
	wider private;
	topmenubutton->text(name);
	if (is_function(private.callback)) { 
	    return private.callback(name); 
	} else {
	    return T;
	}
    }

    public.selection := function() {
	wider private;
	return private.selection;
    }

    private.selections := [=];
    for (category in private.categories) {
	tmp := split(category, '.');
	if (length(tmp) == 1) {
	    private.selections[category] := button(topmenubutton, tmp);
	    private.selections[category].name := tmp;
	    whenever private.selections[category]->press do {
		public.select($agent.name);
	    }
	} else {	
	    last := length(tmp);
	    for (i in 1:length(tmp)) {
		if (i == length(tmp)) {
		    thisname := paste(tmp[1:i], sep='_');
		    private.selections[thisname] := 
			button(private.selections[last], tmp[i]);
		} else if (i == 1) {
		    thisname := tmp[1];
		    if (!has_field(private.selections, thisname))
			private.selections[thisname] := button(topmenubutton,
						       tmp[i], type='menu');
		    last := thisname;
		} else {
		    thisname := paste(tmp[1:i], sep='_');
		    private.selections[thisname] := 
			button(private.selections[last], tmp[i], type='menu');
		    last := thisname;
		}
		private.selections[thisname].name := paste(tmp[1:i], sep='.');
		whenever private.selections[thisname]->press do {
		    public.select($agent.name);
		}
	    }
	}
    }

    return ref public;
}

const filterlistbox := function(ref parentframe, names, categories, callback,
				shorthelp=F)
{
    public := private := [=];
    private.shorthelp := shorthelp;

    if (!is_agent(parentframe) || !is_string(names) || !is_string(categories) ||
	!(length(categories) == length(names))) {
	throw('filterlistbox - illegal argument');
    }

    private.names := names;
    private.categories := categories;
    private.callback := callback;

    private.frame := dws.frame(parentframe, side='top');
    private.selectbutton := dws.button(private.frame, 'all', type='menu');
    private.selectbutton.shorthelp := 'Choose a category';
    private.listframe := dws.frame(private.frame, expand='none', side='left');
    private.listbox := dws.listbox(private.listframe, height=20);
    if (is_function(private.shorthelp)) {
	private.listbox.shorthelp := private.shorthelp;
    }
    private.vsb := dws.scrollbar(private.listframe);
    whenever private.listbox->yscroll do private.vsb->view($value);
    whenever private.vsb->scroll do private.listbox->view($value);

    private.updatebox := function(category) {
	wider private;
	private.listbox->delete('0', 'end');
	if (length(private.names) == 0) return T;
	if (category == 'all') {
	    private.listbox->insert(private.names);
	    private.inboxnames := private.names;
	} else {
	    tmp := private.names[(private.categories == category)];
	    private.inboxnames := tmp;
	    private.listbox->insert(tmp);
	}
    }
    private.selector := categoryfilter(private.selectbutton, categories, 
				       private.updatebox);

    private.updatebox('all');

    private.listbox.private := ref private;
    whenever private.listbox->select do {
	if (is_function(private.callback)) 
	    private.callback(private.inboxnames[$value+1]);
    }

    addpopuphelp(private);
    return ref private;
}
