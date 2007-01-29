# catalogsink.g: helper classes to actually display catalogs
# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
# $Id: catalogsink.g,v 19.1 2004/08/25 01:05:39 cvsmgr Exp $

pragma include once

include 'widgetserver.g'
include 'helpmenu.g'
include 'guicomponents.g'
include 'clipboard.g'
include 'choice.g';
include 'note.g';
include 'timer.g';
include 'unset.g'
include 'os.g';

textcatalogsink := subsequence(show_types='All')
{
    its :=   [=]    # private data and helpers
    its.options := [=]
    its.options.confirm := 'yes';
    its.options.tablesizeoption := 'no';
    its.options.alwaysshowdir := T;
    its.options.sortbytype := F;

    its.show_types := show_types;
    its.directory := '.';
    its.mask := '';

    self.write := function(names,types,sizes,dates)
    {
      wider its;

      width := function(strings) {
        result:=array(0, len(strings))
        for (i in 1:len(strings)) {
          result[i]:=strlen(strings[i]);
        }
        return max(result);
      }
      widthnumber := 3
      widthnames:=width(names);
      if (widthnames<4) widthnames:=4;
      widthtypes:=width(types);
      if (widthtypes<4) widthtypes:=4;
      widthsizes:=width(sizes);
      if (widthsizes<13) widthsizes:=13;
      widthdates:=width(dates);
      if (widthdates<4) widthdates:=4;

      print 'Directory for ', its.directory;

      # Do header first
      line := sprintf('%*s', widthnumber, 'Num');
      line := paste(line, sprintf('%*s', widthnames, 'Name'));
      line := paste(line, sprintf('%*s', widthtypes, 'Type'));
      line := paste(line, sprintf('%*s', widthsizes, 'Size (bytes)'));
      line := paste(line, sprintf('%*s', widthdates, 'Date'));
      print line;
      # Now do the lines
      for (i in 1:len(names)) {
        line := sprintf('%*s', widthnumber, paste(i));
        line := paste(line, sprintf('%*s', widthnames, names[i]));
	line := paste(line, sprintf('%*s', widthtypes, types[i]));
	line := paste(line, sprintf('%*s', widthsizes, sizes[i]));
	line := paste(line, sprintf('%*s', widthdates, dates[i]));
	print line;
      }
    }

    self.query := function(prompt)
    {
      answer:=to_lower(readline(paste(prompt,
				      ' choices are yes, no, cancel [n]')));
      if (answer=='yes' || answer=='y') {
        return 'yes';
      }
      if (answer=='cancel' || answer=='c') {
        return 'cancel';
      }
      return 'no';
    }

    self.setoptions :=function(confirm=unset, tablesizeoption=unset,
			       alwaysshowdir=unset, sortbytype=unset)
    {
      wider its;
      if (!is_unset(confirm)) its.options.confirm := confirm;
      if (!is_unset(tablesizeoption)) its.options.tablesizeoption := tablesizeoption;
      if (!is_unset(alwaysshowdir)) its.options.alwaysshowdir := alwaysshowdir;
      if (!is_unset(sortbytype)) its.options.sortbytype := sortbytype;
    }

    self.writetoname := function(name='')
    {
	print 'File Catalog (AIPS++) : ', name;
    }

    self.setdirectory := function(directory='.')
    {
      wider its;
      its.directory := directory;
    }

}

guicatalogsink := subsequence (parent, vscrollbarright=T,
			       show_types=F, widgetset=dws)
{
    its :=  [=]             # private data and helpers
    its.parent:=parent;
    its.topframe := F;
    its.options:=[=];
    its.options.confirm := parent.getconfirm();
    its.options.tablesizeoption := parent.gettablesizeoption();
    its.options.alwaysshowdir := parent.getalwaysshowdir();
    its.options.sortbytype := parent.getsortbytype();
    its.avtypes := array('', 2+len(its.parent.availabletypes()));
    its.avtypes[1] := 'All';
    its.avtypes[2] := '<Any Table>';
    its.avtypes[3:len(its.avtypes)] := its.parent.availabletypes();
    its.seltypes := array(F, len(its.avtypes));
    its.seltypes[1] := T;
    its.directory := parent.lastdirectory();
    its.cwd := dos.fullname('.');
    if (is_string(show_types)) {
	its.show_types := show_types;
    } else {
	its.show_types := parent.lastshowtypes();
    }
    its.mask := parent.getmask();
    its.vscrollbarright := vscrollbarright;

    # Update the list of types that we can show
    its.updatetypes := function(types)
    {
      wider its;
      added := F;
      if (is_string(types)) {
	for (type in types) {
          if (strlen(type) > 0) {
	    if (!any(type==its.avtypes)) {
	      note('Adding \'', type, '\' to the list of recognized types');
	      its.avtypes[length(its.avtypes)+1] := type;
	      its.seltypes[length(its.seltypes)+1] := F;
	      added := T;
	    }
	  }
	}
      } else {
	added := T;
      }
      if (added) {
	its.makeshowmenu();
      }
      str := '';
      for (i in 1:length(its.avtypes)) {
	its.seltypes[i] := any(its.avtypes[i] == its.show_types);
      }
      if (added) {
	its.fillshowmenu();
      }
    }

    its.fillshowmenu := function()
    {
      wider its;
      its.show_types := "";
      str := '';
      for (i in 1:len(its.avtypes)) {
	flag := its.seltypes[i];
	its.showmenu[i]->state (flag);
        if (flag) {
	  tp := its.avtypes[i];
	  str := spaste(str,',',tp);
	  its.show_types[len(its.show_types)+1] := tp;
        }
      }

      its.showentry->delete('start' ,'end');
      its.showentry->insert(str~s/^,//);
    }

    its.makeshowmenu := function()
    {
      wider its;
      its.showmenu := [=];
      for (i in 1:len(its.avtypes)) {
	its.showmenu[i] := widgetset.button(its.showbutton, its.avtypes[i],
					    type='check');
	its.showmenu[i].typeindex := i;
	whenever its.showmenu[i]->press do {
	  seltype := $agent->state();
	  i := $agent.typeindex;
	  if (its.lock()) {
	    if (i == 1) {
	      its.seltypes[1:len(its.seltypes)] := F;
	      if (seltype) {
	        its.seltypes[1] := T;          # All selected
	      } else {
	        its.seltypes[2] := T;          # All deselected, set Any Table
	      }
	    } else {
	      its.seltypes[i] := seltype;
	      its.seltypes[1] := !any(its.seltypes[2:len(its.seltypes)]);
	    }
	    its.fillshowmenu();
	    its.showdir();
	    its.unlock();
	  }
        }
      }
    }

    its.tryshowdir := function(dir)
    {
      its.status.append('Showing...');
      dirtype:=dos.filetype(dir);
      if ((dirtype!='Table') && (dirtype!='Directory')) {
	its.status.append(paste('Failed!', dir, 'is not a directory'));
	return F;
      } 
      self.setdirectory(dir);
      return its.showdir();
    }

    its.showdir := function(writestatus=T)
    {
      its.inputfileentry->delete ('start', 'end');
      return its.parent.show(its.directory, its.show_types, writestatus)
    }

    its.adddirectory := function(file)
    {
      for (i in 1:length(file)) {
	file[i]:=spaste(its.directory,'/',file[i]);
	file[i]~:=s!//!/!g;
      }
      return file;
    }
    its.getmultifilesel := function (adddir=F)
    {
      # If the selection has only one file, return the file entry
      # because the user might have changed it.
      sel := its.text->selection();
      if (len(sel) == 0) {
	str := its.getfileentry(adddir);
      } else {
        str := its.text.listbox(1)->get (sel);
	if (length(str) <= 1) {
	  str := its.getfileentry(adddir);
	} else {
	  # If we are not in the current directory, return a full name.
	  if (its.directory != its.cwd) {
	    str := its.adddirectory(str);
	  }
        }
      }
      return [inx=sel, str=str];
    }

    its.getmultifileentry := function (adddir=F)
    {
	return its.getmultifilesel(adddir).str;
    }

    its.getsinglefileentry := function (adddir=F)
    {
	str := its.getmultifileentry(adddir);
	if (length(str) > 1) {
print 'a'
	  its.status.append ('Error: only 1 file can be selected');
	  fail 'error';
	}
	return str;
    }

    its.getfileentry := function (adddir=F)
    {
      # If addir=T and not starting with /, add the directory.
      # Otherwise add the directory if we are not in the working directory.
      selection:=its.inputfileentry->get();
      if (selection != '') {
        if (adddir) {
	  if (selection ~ m%^/%) {
	    return selection;
          }
        } else {
	  if (its.directory == its.cwd) {
	    return selection;
          }
        }
	return its.adddirectory(selection);
      }
      return selection;
    }

    its.handleview := function (view=F)
    {
      selection := '';
      if (its.lock()) {
	selection := its.getmultifileentry();
	if (len(selection) == 0  ||  selection=='') {
	  its.status.clear();
	  its.status.append ('No file(s) selected');
        } else {
	  for (item in selection) {
	    its.status.clear();
	    what:=its.parent.whatis(item);
	    if (!is_fail(what) && (what.type=='Directory')) {
	      its.status.append(paste('Viewing', item));
              its.tryshowdir(item);
	    } else {
	      if (view) {
	        its.status.append(paste('Viewing', item));
		f:=its.parent.view(item);
		if (is_fail(f)) {
		  its.status.append(paste('view failed', f::message));
	        }
	      }
	    }
	  }
        }
	its.unlock();
      }
      return selection;
    }

    its.handleselect := function (select, dismiss)
    {
      its.status.clear();
      selection := its.getsinglefileentry(T);
      if (is_fail(selection)) {
	return F;
      }
      if (!select) {
        what := its.parent.whatis(selection);
	if (!is_fail(what)) {
	  if (its.lock()) {
	    its.status.append(paste('Viewing', selection));
	    its.tryshowdir (selection);
	    its.unlock();
	  }
	  return T;
        }
      }
      if (!its.disabled) {
        callback := its.parent.selectcallback();
	if (is_function(callback)) {
          callback(selection);
        }
	its.parent.setselectcallback(F);
	if (dismiss) {
	  self.deactivate();
        }
	its.status.clear();
      }
      return T;
    }


    its.isbusy := F;

    const its.lock := function()
    {
      wider its;
      if (!its.isbusy) {
        its.isbusy := T;
	its.topframe->cursor('watch');
	return T;
      } else {
	return F;
      }
    }
    const its.unlock := function()
    {
      wider its;
      its.isbusy := F;
      its.topframe->cursor('left_ptr');
      return T;
    }

    its.whenevers := [];
    its.pushwhenever := function()
    {
      wider its;
      its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
    }
  
    its.init := function()
    {
      wider its;
      widgetset.tk_hold();

      its.topframe := widgetset.frame(title='File Catalog (AIPS++)',
				      side='top');
      
      its.menubar := widgetset.frame(its.topframe,side='left',relief='raised',
				     expand='x');

      its.filebutton := widgetset.button(its.menubar, 'File', relief='flat',
					 type='menu');
      its.filebutton.shorthelp := 'Do various file operations; you can also use the buttons below. Use the left button <MB1> to select files, shift-<MB1> to select a range of files, control-<MB1> to add to the selected files';
      its.filemenu := [=];
      its.filemenu['view'] := widgetset.button(its.filebutton, 'View');
      its.filemenu['summary'] := widgetset.button(its.filebutton, 'Summarize');
      its.filemenu['execute'] := widgetset.button(its.filebutton, 'Execute');
      its.filemenu['show'] := widgetset.button(its.filebutton, 'ShowDir');
      its.filemenu['copy'] := widgetset.button(its.filebutton, 'Copy');
      its.filemenu['rename'] := widgetset.button(its.filebutton, 'Rename');
      its.filemenu['delete'] := widgetset.button(its.filebutton, 'Delete');
      its.filemenu['edit'] := widgetset.button(its.filebutton, 'Edit');
      its.filemenu['tool'] := widgetset.button(its.filebutton, 'Tool');
      its.filemenu['refresh'] := widgetset.button(its.filebutton, 'Refresh Display');
      its.filemenu['exit'] := widgetset.button(its.filebutton, 'Dismiss',
					       type='dismiss');
      
      its.optionsbutton := widgetset.button(its.menubar, 'Options',
				       relief='flat', type='menu');
      its.optionsbutton.shorthelp := 'Various optional operations, such as copy names of selected files to the clipboard';
      its.optionsmenu := [=];
      its.optionsmenu['copy'] := widgetset.button(its.optionsbutton, 'Copy list to clipboard');
      its.optionsmenu['confirm'] := widgetset.button(its.optionsbutton,
						     'Confirm file operations',
						     type='menu',
						     relief='flat');
      confirmoptl := ['Confirm for all files',
		      'Confirm for directories only',
		      'Never confirm'];
      confirmoptv := ['yes', 'directory', 'no'];
      its.optionsmenu['confirm'].popupmenu := [=];
      for (i in 1:len(confirmoptv)) {
	  v := confirmoptv[i];
	  its.optionsmenu['confirm'].popupmenu[v] :=
	      widgetset.button(its.optionsmenu['confirm'],
			       confirmoptl[i], value=v, type='radio');
	  if (v == its.options.confirm) {
	      its.optionsmenu['confirm'].popupmenu[v]->state(T);
	  }
	  whenever its.optionsmenu['confirm'].popupmenu[i]->press do {
	      if (its.lock()) {
		  its.options.confirm := $value;
		  its.parent.setconfirm(its.options.confirm);
		  its.unlock();
	      }
	  } its.pushwhenever();
      }
      its.optionsmenu['alwaysshowdir'] := widgetset.button(its.optionsbutton, 
						 'Always show directories',
						 type='check');
      its.optionsmenu['alwaysshowdir']->state(its.options.alwaysshowdir);
      its.optionsmenu['tablesizeoption'] := widgetset.button(its.optionsbutton,
						       'Show table sizes',
						       type='menu',
						       relief='flat');
      tablesizeoptl := ['Do not show table sizes',
			'Show table sizes in bytes',
			'Show table/image shapes'];
      tablesizeoptv := ['no', 'bytes', 'shape'];
      its.optionsmenu['tablesizeoption'].popupmenu := [=];
      for (i in 1:len(tablesizeoptv)) {
	  v := tablesizeoptv[i];
	  its.optionsmenu['tablesizeoption'].popupmenu[v] :=
	      widgetset.button(its.optionsmenu['tablesizeoption'],
			       tablesizeoptl[i], value=v, type='radio');
	  if (v == its.options.tablesizeoption) {
	      its.optionsmenu['tablesizeoption'].popupmenu[v]->state(T);
	  }
	  whenever its.optionsmenu['tablesizeoption'].popupmenu[i]->press do {
	      if (its.lock()) {
		  its.options.tablesizeoption := $value;
		  its.parent.settablesizeoption(its.options.tablesizeoption);
		  its.unlock();
	      }
	  } its.pushwhenever();
      }
      its.optionsmenu['sortbytype'] := widgetset.button(its.optionsbutton, 
						 'Show files in order of type',
						 type='check');
      its.optionsmenu['sortbytype']->state(its.options.sortbytype);
      
      its.rightmenubar := widgetset.frame(its.menubar,side='right');
      its.helpmenu := widgetset.helpmenu(parent=its.rightmenubar,
					 menuitems='catalog',
					 refmanitems='Refman:catalog.catalog',
					 helpitems='about catalog');

# Add a toolbar

      its.toolbarframe := widgetset.frame(its.topframe, side='left',
					  expand='x');

      its.toolbar := [=];
      its.toolbar['view'] := widgetset.button(its.toolbarframe, 'View');
      its.toolbar['view'].shorthelp := 'View the selected file(s) using the appropriate viewer (e.g. viewer for images, tablebrowser for tables, etc).';
      its.toolbar['summary'] := widgetset.button(its.toolbarframe, 'Summarize');
      its.toolbar['summary'].shorthelp := 'Log a summary of the selected file(s)';
      its.toolbar['execute'] := widgetset.button(its.toolbarframe, 'Execute');
      its.toolbar['execute'].shorthelp := 'Execute the selected Glish file(s)';
      its.toolbar['show'] := widgetset.button(its.toolbarframe, 'ShowDir');
      its.toolbar['show'].shorthelp := 'Show the selected directory (default is current directory)';
      its.toolbar['copy'] := widgetset.button(its.toolbarframe, 'Copy');
      its.toolbar['copy'].shorthelp := 'Copy one or more selected files: you will be prompted for the output name or directory as appropriate';
      its.toolbar['rename'] := widgetset.button(its.toolbarframe, 'Rename');
      its.toolbar['rename'].shorthelp := 'Rename one or more selected files: you will be prompted for the output name or directory as appropriate';
      its.toolbar['delete'] := widgetset.button(its.toolbarframe, 'Delete');
      its.toolbar['delete'].shorthelp := 'Delete one or more selected files';
      its.toolbar['edit'] := widgetset.button(its.toolbarframe, 'Edit');
      its.toolbar['edit'].shorthelp := 'Edit a selected file';
      its.toolbar['tool'] := widgetset.button(its.toolbarframe, 'Tool');
      its.toolbar['tool'].shorthelp := 'Construct a tool from the selected file(s) using the toolmanager';

      its.toolbarframeright := widgetset.frame(its.toolbarframe, side='right');
      its.toolbar['create'] := widgetset.button(its.toolbarframeright,
						'Create', relief='raised',
						type='menu');
      its.toolbar['create'].shorthelp := 'Create a file (choices are ascii, Glish or Directory)';
      its.toolbar['create'].menu := [=];
      its.toolbar['create'].menu['ascii'] := widgetset.button(its.toolbar['create'], 'ascii');
      its.toolbar['create'].menu['Glish'] := widgetset.button(its.toolbar['create'], 'Glish');
      its.toolbar['create'].menu['Directory'] := widgetset.button(its.toolbar['create'], 'Directory');


# The various inputs : mask
      hlps := 'Set the directory to be displayed';
      its.directoryframe := widgetset.frame (its.topframe, relief='ridge',
					     expand='x');
      its.directoryentry := widgetset.combobox (its.directoryframe,
					'Directory:',
					items=". ..",
					autoinsertorder='head',
					borderwidth=0,
					entrybackground='white',
					arrowbutton='smalldownarrow.xbm',
					help=hlps);
      uniquelastcombobox (its.directoryentry);

      its.inputbar := widgetset.frame (its.topframe, side='left', expand='x')

      its.maskframe := widgetset.frame(its.inputbar, side='left',
				       relief='ridge');
      its.maskbutton:=widgetset.label(its.maskframe,'Mask:');
      its.maskbutton.shorthelp := 'Set a mask to limit the files displayed: e.g. 3C273.*';
      its.maskentry:=widgetset.entry(its.maskframe);
      its.maskentry.shorthelp := 'Set a mask to limit the files displayed: e.g. 3C273.*';
      its.maskentry->insert('');

      its.showframe := widgetset.frame(its.inputbar, side='left', relief='ridge');
##      its.showlabel := widgetset.label(its.showframe, 'Types:')
##      its.showlabel.shorthelp :='Control which types of file are shown';
      its.showbutton := widgetset.button(its.showframe, 'Types:',
					 type='menu',relief='groove');
      its.showbutton.shorthelp := 'Possible file types (can be added to or removed from entry';
      its.showentry:=widgetset.entry(its.showframe);
      its.showentry.shorthelp := 'Set types of the files to be shown';
      its.showentry->insert('');
      its.updatetypes(F);
      its.showentry->disable();

# This next part is for interactive selection
      its.inputfileframe := widgetset.frame(its.topframe, side='left',
				       relief='ridge', expand='x');
      its.inputfilelabel:=widgetset.label(its.inputfileframe,'Current selection:');
      its.inputfilelabel.shorthelp := 'Display current selection. Type here to alter the selected name.';
      its.inputfileentry:=widgetset.entry(its.inputfileframe);
      its.inputfileentry.shorthelp := 'Display current selection. Type here to alter the selected name.';

      its.selectanddismissbutton := widgetset.button(its.inputfileframe, 'Send&dismiss');
      its.selectanddismissbutton.shorthelp := 'Send selection on to the connected file entry widget and dismiss this widget';
      its.selectingbutton := widgetset.button(its.inputfileframe, 'Send');
      its.selectingbutton.shorthelp := 'Send selection on to the connected file entry widget but keep connection open to file entry widget';
      its.cancelbutton := widgetset.button(its.inputfileframe, 'Break');
      its.cancelbutton.shorthelp := 'Break connection to the file entry widget';
      its.selectanddismissbutton->disable();
      its.selectingbutton->disable();
      its.cancelbutton->disable();
      its.disabled := T;
      whenever its.selectanddismissbutton->press do {
	its.handleselect (T, T);
      } its.pushwhenever();
      whenever its.selectingbutton->press do {
	its.handleselect (T, F);
      } its.pushwhenever();
      whenever its.cancelbutton->press do {
        callback := its.parent.selectcallback();
        if (is_function(callback)) {
          callback(unset);
	}
	its.parent.setselectcallback(F);
      } its.pushwhenever();


# Set up the actual display list

	ncol := 0
	widths := 0
	colors := ''
        colnames := ''
        ncol +:= 1
	widths[ncol] := 24
	colors[ncol] := 'blue'	    
        colnames[ncol] := 'File Name'
        ncol +:= 1
	widths[ncol] := 15
	colors[ncol] := 'red'
        colnames[ncol] := 'File Type'
	ncol +:= 1
	widths[ncol] := 16
	colors[ncol] := 'black'    
        colnames[ncol] := 'Size (bytes)'
	ncol +:= 1
	widths[ncol] := 19
	colors[ncol] := 'black'    
        colnames[ncol] := 'Date'

        its.outertextframe := widgetset.frame(its.topframe, expand='both');

        its.textframe := widgetset.frame(its.outertextframe, side='left',
					 relief='sunken', expand='both');

        its.text := widgetset.synclistboxes(parent=its.textframe,
				nboxes=ncol, labels=colnames,
				vscrollbarright=its.vscrollbarright,
			        height=12, width=widths,
				mode='extended',
				foreground=colors,
				fill='both');
        its.text->bind('<Double-ButtonPress-1>', 'doubleclick');

# Set up refresh, status line and dismiss

        its.status:=status_line(its.outertextframe);
        its.status.clear();

	its.bottomframe:=widgetset.frame(its.outertextframe,side='left',
					 expand='x', borderwidth=0);
	its.bottomleftframe:=widgetset.frame(its.bottomframe,side='left',
					     borderwidth=0);

        its.refreshbutton := widgetset.button(its.bottomleftframe, 'Refresh');
        its.refreshbutton.shorthelp := 'Refresh the display'

        its.bottomrightframe := widgetset.frame(its.bottomframe, side='right',
						borderwidth=0);
        its.dismissbutton := widgetset.button (its.bottomframe, 'Dismiss',
					       type='dismiss');
        its.dismissbutton.shorthelp:='Dismiss the GUI (but the screen catalog remains active)';

# Show selected file
        whenever its.filemenu['show']->press, its.toolbar['show']->press do {
          if (its.lock()) {
	    its.status.clear();
	    selection:=its.getsinglefileentry();
	    if (! is_fail(selection)) {
	      if (selection=='') {
	        selection := its.directoryentry.getentry();
	      }
	      its.tryshowdir(selection);
	    }
	    its.unlock();
	  }
	} its.pushwhenever();

# Delete the selected file or files
        whenever its.filemenu['delete']->press, its.toolbar['delete']->press do {
	  if (its.lock()) {
	    refresh := F;
	    nrdel := 0;
	    status := T;
	    its.status.clear();
	    sel:=its.getmultifilesel();
	    inx := sel.inx;
	    selections := sel.str;
	    if (len(selections) == 0  ||  selections=='') {
	      its.status.append ('No file(s) selected');
	    } else {
	      its.status.append(paste('Processing delete of', selections));
	      for (i in ind(selections)) {
		selection := selections[i];
	        if (is_string(selection) && strlen(selection)) {
		  res := its.parent.delete(selection, F);
		  if (is_fail(res)) {
		    its.status.append(paste('Delete failed!', res::message));
		    status := F;
		  } else {
		    # remove file from listboxes if actually deleted
		    # and if the selection index is known.
		    if (res > 0) {
		      if (!refresh) {
			if (i > len(inx)) {
			  refresh := T;
		        } else {
			  its.text->delete (as_string(inx[i] - nrdel));
		        }
		      }
		      nrdel +:= 1;
		    }
		  }
		}
	      }
	      if (refresh) {
		its.showdir(status);
	      } else {
		its.status.clear();
	      }
	      # If selection was given, set cursor to line after last file
	      # selected. This is useful in case some files were not deleted.
	      if (len(inx) > 0) {
		goto := inx[len(inx)] - nrdel + 1;
		if (goto > 0) {
		  its.text->select (as_string(goto));
	        }
	      }
	    }
	    its.unlock();
	  }
	} its.pushwhenever();

# Edit the selected file
        whenever its.filemenu['edit']->press, its.toolbar['edit']->press do {
	  if (its.lock()) {
	    its.status.clear();
	    selection:=its.getsinglefileentry();
	    if (! is_fail(selection)) {
	      if (len(selection) == 0  ||  selection=='') {
	        its.status.append ('No file selected');
	      } else {
	        f:=its.parent.edit(selection);
		if (is_fail(f)) {
		  its.status.append(paste('Edit failed!', f::message));
	        } else {
		  its.status.append(paste('Editing', selection, '...'));
	        }
	        its.showdir(!is_fail(f));
	      }
	    }
	    its.unlock();
          }
	} its.pushwhenever();

# Create a file
      its.create := function(type='ascii')
      {
	its.status.clear();
	include 'inputbox.g';
	newname:=inputbox('Please enter new name');
	if (is_string(newname) && newname!='') {
	  newname:=its.adddirectory(newname);
	  its.status.append(paste('Creating', type, 'file',
				  newname, '...'));
	  f:=its.parent.create(newname, type, F);
	  if (is_fail(f)) {
	    its.status.append(paste('Create failed!', f::message));
	  }
	  its.showdir(!is_fail(f));
	}
      }
      whenever its.toolbar['create'].menu['ascii']->press do {
	if (its.lock()) {
	  its.create('ascii');
	  its.unlock();
	}
      } its.pushwhenever();
      whenever its.toolbar['create'].menu['Glish']->press do {
	if (its.lock()) {
	  its.create('Glish');
	  its.unlock();
	}
      } its.pushwhenever();
      whenever its.toolbar['create'].menu['Directory']->press do {
	if (its.lock()) {
	  its.create('Directory');
	  its.unlock();
	}
      } its.pushwhenever();

# Copy the selected file
        whenever its.filemenu['copy']->press, its.toolbar['copy']->press do {
	  if (its.lock()) {
	    its.status.clear();
	    selection:=its.getmultifileentry();
	    if (len(selection) == 0  ||  selection=='') {
	      its.status.append ('No file(s) selected');
	    } else {
	      include 'inputbox.g';
	      if (len(selection)>1) {
		newname:=inputbox('Please enter target directory:');
	      } else {
		sr:=stat(selection,follow=T);
		if (length(sr)==0) {
		  its.status.append(paste('Unknown file',selection));
		  newname:='';
		} else {
		  newname:=inputbox('Please enter new name');
	        }
	      }
	      if (is_string(newname) && newname!='') {
		newname:=its.adddirectory(newname);
		its.status.append(paste('Copying', selection, 'to',
					newname, '...'));
		f:=its.parent.copy(selection,newname);
		if (is_fail(f)) {
		  its.status.append(paste('Copy failed!', f::message));
	        }
		its.showdir(!is_fail(f));
	      } else {
		its.status.append('  Invalid file, Copy aborted!');
	      }
	    }
	    its.unlock();
	  }
	} its.pushwhenever();

# Rename the selected file
        whenever its.filemenu['rename']->press, its.toolbar['rename']->press do {
	  if (its.lock()) {
	    its.status.clear();
	    selection:=its.getmultifileentry();
	    if (len(selection) == 0  ||  selection=='') {
	      its.status.append ('No file(s) selected');
	    } else {
	      include 'inputbox.g';
	      if (len(selection)>1) {
		newname:=inputbox('Please enter target directory:');
	      } else {
		sr:=stat(selection,follow=T);
		if (length(sr)==0) {
		  its.status.append(paste('Unknown file',selection));
		  newname:='';
		} else {
		  newname:=inputbox('Please enter new name');
	        }
	      }
	      if (is_string(newname) && newname!='') {
		newname:=its.adddirectory(newname);
		its.status.append(paste('Renaming', selection, 'to', newname,
					'...'));
		f:=its.parent.rename(selection,newname);
		if (is_fail(f)) {
		  its.status.append(paste('Rename failed!', f::message));
		}
		its.inputfileentry->delete('start', 'end');
		its.showdir(!is_fail(f));
	      } else {
		its.status.append('  Invalid file, Rename aborted!');
	      }
	    }
	    its.unlock();
          }
	} its.pushwhenever();


# View the selected files
        whenever its.filemenu['view']->press, its.toolbar['view']->press do {
	  its.handleview(T);
	} its.pushwhenever();

        whenever its.text->doubleclick do {
	  its.handleselect (F, T);
	} its.pushwhenever();

# Convert the selected files into tools
        whenever its.filemenu['tool']->press, its.toolbar['tool']->press do {
	  if (its.lock()) {
	    selection:=its.getmultifileentry();
	    if (len(selection) == 0  ||  selection=='') {
	      its.status.append ('No file(s) selected');
	    } else {
	      for (item in selection) {
		its.status.clear();
		its.status.append(paste('Constructing tool from', item));
		what:=its.parent.whatis(item);
		if (!is_fail(what) && (what.type=='Directory')) {
		  its.tryshowdir(item);
		} else {
		  f:=its.parent.tool(item);
		  if (is_fail(f)) {
		    its.status.clear();
		    its.status.append(paste('Construction of tool failed', f::message));
		  };
		}
	      }
	    }
	    its.unlock();
	  }
	} its.pushwhenever();

# File in the top selected file into the input file name
        whenever its.text->select do {
	  local evalue := $value
	  if (its.lock()) {
	    selection := its.text.listbox(1)->get (evalue);
	    its.inputfileentry->delete('start', 'end');
	    if (len(selection) == 1
            &&  is_string(selection)  &&  strlen(selection)) {
	      its.inputfileentry->insert(selection);
	    }
	    its.unlock();
	  }
	} its.pushwhenever();

# Summarize the selected files
        whenever its.filemenu['summary']->press, its.toolbar['summary']->press do {
	  if (its.lock()) {
	    selection:=its.getmultifileentry();
	    if (len(selection) == 0  ||  selection=='') {
	      its.status.append ('No file(s) selected');
	    } else {
	      for (item in selection) {
		its.status.clear();
		its.status.append(paste('Showing summary of', item));
		f:=its.parent.summary(item);
		if (is_fail(f)) {
		  its.status.append(paste('summary failed', f::message));
		};
	      }
	    }
	    its.unlock();
	  }
	} its.pushwhenever();


# Execute the selected file
        whenever its.filemenu['execute']->press,
	    its.toolbar['execute']->press do {
	  if (its.lock()) {
	    selection:=its.getmultifileentry();
	    if (len(selection) == 0  ||  selection=='') {
	      its.status.append ('No file(s) selected');
	    } else {
	      for (item in selection) {
		its.status.clear();
		its.status.append(paste('Executing', item));
		f:=its.parent.execute(item);
		if (is_fail(f)) {
		  its.status.append(paste('Execution failed', f::message));
	        } else {
		  its.status.clear();
		  its.status.append(paste('Successfully executed', item));
	        }
	      }
	    }
	    its.unlock();
	  }
	} its.pushwhenever();


# Refresh the display
        whenever its.refreshbutton->press, its.filemenu['refresh']->press do {
	  # This always unlocks
	  its.unlock();
	  if (its.lock()) {
	    its.status.clear();
	    its.status.append('Refreshing');
	    its.showdir();
	    its.unlock();
	  }
	} its.pushwhenever();

# Killed (closing the gui)
        whenever its.topframe->killed do {
	  its.topframe := F;
	  deactivate its.whenevers;
	  its.parent.screen();
        } its.pushwhenever();


# Exit (closing the gui)
        whenever its.filemenu['exit']->press do {
	  if (its.lock()) {
	    its.topframe := F;
            deactivate its.whenevers;
	    its.status.delete();
	    its.parent.screen();
	  }
        } its.pushwhenever();

        whenever its.directoryentry.agent()->return,
	         its.directoryentry.agent()->select do {
	  if (its.lock()) {
	    its.status.clear();
	    directory:= its.directoryentry.getentry();
	    f:=its.tryshowdir(directory);
	    if (!f) {
	      self.setdirectory (its.directory);
	    }
	    its.unlock();
	  }
        } its.pushwhenever();


        whenever its.maskentry->return do {
	  if (its.lock()) {
	    its.status.clear();
	    its.mask:=its.maskentry->get();
	    its.status.append('Setting mask...');
	    f:=its.parent.setmask(its.mask);
	    if (is_fail(f)) {
	      its.status.append(paste('Failed!', f::message));
	    }
	    its.unlock();
	  }
        } its.pushwhenever();


        whenever its.optionsmenu['copy']->press do {
	  if (its.lock()) {
	    its.status.clear();
	    selection:=its.getmultifileentry();
	    if (is_string(selection) && strlen(selection)) {
	      dcb.copy(selection);
	    }
	    its.unlock();
	  }
	} its.pushwhenever();
        
        whenever its.optionsmenu['alwaysshowdir']->press do {
	  if (its.lock()) {
	    its.options.alwaysshowdir := 
                                  its.optionsmenu['alwaysshowdir']->state();
	    its.parent.setalwaysshowdir(its.options.alwaysshowdir);
	    its.unlock();
	  }
	} its.pushwhenever();
        
        whenever its.optionsmenu['sortbytype']->press do {
	  if (its.lock()) {
	    its.options.sortbytype:=its.optionsmenu['sortbytype']->state();
	    its.parent.setsortbytype(its.options.sortbytype);
	    its.unlock();
	  }
	} its.pushwhenever();
        

        whenever its.dismissbutton->press do {
  	  if (its.lock()) {
	    its.parent.setselectcallback(F);
	    self.deactivate();
            its.parent.screen();
	    its.unlock();
	  }
	} its.pushwhenever();
      
      widgetset.tk_release();
    
    }
    its.init();

    self.writetostatus := function(message='')
    {
      if (message=='') {
        its.status.clear();
      } else {
        its.status.append(message);
      }
    }

    self.writetoname := function(name='')
    {
        wider its;
	its.topframe->title(paste('AIPS++ File Catalog: ', name));
    }

    self.deactivate := function()
    {
      wider its;
      its.topframe->unmap();
      return T;
    }

    self.isactive := function()
    {
	wider its;
	return is_agent(its.topframe);
    }

    self.activate := function()
    {
	wider its;
	if (!is_agent(its.topframe)) {
	  its.init();
	}
	if (is_agent(its.topframe)) {
	  its.topframe->map();
	  its.topframe->deiconify();
          return T;
        }
	return F;
    }

    self.busy := function(makebusy, wasbusy=F)
    {
      wider its;
      if (makebusy) {
	wasbusy := its.lock();
      } else {
	if (!wasbusy) {
	  its.unlock();
        }
      }
    }

    self.write := function(names,types,sizes,dates)
    {
      wider its;
      its.topframe->deiconify();
      its.updatetypes(types);
      self.clear();
      if (len(names) > 0) {
	messages := array('', 4, len(names));
	nr := 0;
	for (i in 1:len(names)) {
	  if (types[i] == 'Directory') {
	    nr +:= 1;
	    messages[1, nr] := names[i];
	    messages[2, nr] := types[i];
	    messages[3, nr] := sizes[i];
	    messages[4, nr] := dates[i];
          }
        }
	for (i in 1:len(names)) {
	  if (types[i] != 'Directory') {
	    nr +:= 1;
	    messages[1, nr] := names[i];
	    messages[2, nr] := types[i];
	    messages[3, nr] := sizes[i];
	    messages[4, nr] := dates[i];
	  }
        }
	its.text->insert(messages);
        its.text->see('begin');
      }
    }

    self.query := function(prompt)
    {
      choices:=['no', 'yes', 'cancel'];
      answer:=choice(prompt, choices)
      if (answer=='yes' || answer=='y') {
        return 'yes';
      }
      if (answer=='cancel' || answer=='c') {
        return 'cancel';
      }
      return 'no';
    }

    self.clear := function()
    {
        its.text->delete ('start', 'end');
	return T;
    }

    self.setparent := function(ref parent)
    {
      wider its;
      its.parent:=parent;
    }

    self.setoptions :=function(confirm=unset, tablesizeoption=unset,
			       alwaysshowdir=unset, sortbytype=unset)
    {
      wider its;
      showdir := F;
      if (!is_unset(confirm)) {
	its.options.confirm := confirm;
	its.optionsmenu['confirm'].popupmenu[confirm]->state(T);
      }
      if (!is_unset(tablesizeoption)) {
	its.options.tablesizeoption := tablesizeoption;
	its.optionsmenu['tablesizeoption'].popupmenu[tablesizeoption]->state(T);
        showdir := T;
      }
      if (!is_unset(alwaysshowdir)) {
	its.options.alwaysshowdir := alwaysshowdir;
	its.optionsmenu['alwaysshowdir']->state(alwaysshowdir);
        showdir := T;
      }
      if (!is_unset(sortbytype)) {
	its.options.sortbytype := sortbytype;
	its.optionsmenu['sortbytype']->state(sortbytype);
        showdir := T;
      }
      if (showdir) {
        its.showdir();
      }
    }

    self.showdir := function()
    {
      its.showdir();
    }

    self.setmask :=function(mask='')
    {
      wider its;
      its.mask := mask;
      its.maskentry->delete('start', 'end');
      its.maskentry->insert(mask);
      its.showdir();
    }

    self.select := function()
    {
      wider its;
      its.status.clear();
      its.status.append('Click on desired file and press Send&dismiss, Send, or Break');
      if (its.disabled) {
	its.selectanddismissbutton->enable();
	its.selectingbutton->enable();
	its.cancelbutton->enable();
	# its.inputfileframe->map();
	its.disabled := F;
      }
    }

    self.noselect := function()
    {
      wider its;
      its.status.clear();
      if (!its.disabled) {
	its.selectanddismissbutton->disable();
	its.selectingbutton->disable();
	its.cancelbutton->disable();
	its.disabled := T;
	# its.inputfileframe->unmap();
      }
    }

    self.setdirectory := function(directory='.')
    {
      wider its;
      its.directory := directory;
      its.directoryentry.insert (directory);
      its.directoryentry.insertentry (directory);
    }

    self.setshowtypes := function(show_types)
    {
      wider its;
      nr := 0;
      if (len(show_types) > 0) {
	its.show_types := show_types;
	its.updatetypes (F);
      }
    }

    result := self.setdirectory('.');
    result := widgetset.addpopuphelp(its, 5);
    if (is_function (parent.selectcallback())) {
      self.select();
    }
}
