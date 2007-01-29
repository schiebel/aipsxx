# tabdialog: an ongoing attempt at a tab dialog box
# Copyright (C) 1999,2000,2001
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
# $Id: tabdialog.g,v 19.3 2005/04/14 21:18:32 dking Exp $

pragma include once;

include 'widgetserver.g';
include 'note.g';
include 'unset.g';

const tabdialogtest := function () {
  include 'tabdialogtest.g';
  return tabdialogwidgettest();
}

 
const tabdialog := subsequence (ref parent, colmax=5, title='Select',
				hlthickness=5, widgetset=dws) 
{
  private := [=];
  resource := widgetset.resources('frame');
  private.framebackground := resource.background;
  resource := widgetset.resources('button', 'plain');
  private.buttonbackground := resource.background;
#
  private.rowmax := 2;             # Extended as needed
  private.colmax := colmax;
  private.col := [=]
  private.row := [=]
  private.indices := [=];
#
  private.names := array('', private.colmax, private.rowmax);
  private.rows := [=];
  private.buttons := [=];
  private.buttonframes := [=];
  private.frames := [=];
  private.currTop := F;
  private.whenevers := [=];

# this frame holds the rows of buttons

  private.outerFrame := widgetset.frame(parent,side='top',borderwidth=0);
  private.buttFrame := widgetset.frame(private.outerFrame,side='top');
  if (!is_unset(title)) {
    private.title := widgetset.label(private.buttFrame, title);
  }
  private.maxButtPerRow := private.rowmax;

# this is the top level frame within which tab frame are constructed
# access to this is via the dialogueFrame() member

  private.dframe := widgetset.frame(private.outerFrame,side='top');

# Set up all the frames

  index := 0;
  for (row in 1:private.rowmax) {
    private.rows[row] := widgetset.frame(private.buttFrame,side='left');
    private.rows[row]->unmap();
    for (col in 1:private.colmax) {
      index +:= 1;
      private.buttonframes[index] := widgetset.frame(private.rows[row]);
      private.buttonframes[index]->unmap();
    }
  }
  

# Private functions

###
  const private.getindex := function (tabname) 
  {
    wider private;
    if (any(private.names==tabname)) {
      index := private.indices[tabname];
      return index;
    } else {
      t := spaste('Tab "', tabname, '" does not exist');
      return throw (t, origin='tabdialog.replace');
    }
  }


# Public functions

###
  const self.add := function(tab, tabname, hlp=F) 
  {
    wider private;
    tabname2 := as_string(tabname);
    if(tabname2=='') {
      return throw('Tab name cannot be null', origin='tabdialog.add');
    }  
    if (any(private.names==tabname2)) {
      txt := spaste('Tab ', tabname2, ' already exists');
      return throw(txt, origin='tabdialog.add');
    }
#
# Search for an empty slot
#
    index := 0;
    found := F;
    for (row in 1:private.rowmax) {
      for (col in 1:private.colmax) {
	index +:= 1;
	if(private.names[col, row]=='') {
	  private.rows[row]->map();
	  private.col[tabname2] := col;
	  private.row[tabname2] := row;
	  private.indices[tabname2] := index;
	  private.names[col, row] := tabname2;
	  found := T;
	  break;
	}
      }
      if (found) break;
    }
    widgetset.tk_hold();
#
    if (!found) {

# No slots. Add a new row.

       private.rowmax +:= 1;
       t := private.names;
       private.names := array(t, private.colmax, private.rowmax);
       private.names[,private.rowmax] := '';
       row := private.rowmax;
#
       private.rows[row] := widgetset.frame(private.buttFrame,side='left');
       private.rows[row]->unmap();
       index := (private.rowmax-1)*private.colmax + 1;
       for (col in 1:private.colmax) {
          private.buttonframes[index] := widgetset.frame(private.rows[row]);
          private.buttonframes[index]->unmap();
          index +:= 1;
       }

# Now add the entry for this new tab


       index := (private.rowmax-1)*private.colmax + 1;
       col := 1;
       private.col[tabname2] := col;
       private.row[tabname2] := row;
       private.indices[tabname2] := index;
       private.names[col, row] := tabname2;
    }

#  Add the TAB

    private.buttonframes[index]->map();
    private.buttons[index] := widgetset.button(private.buttonframes[index],
					       tabname2, 
					       relief='raised',
					       value=tabname2);
    if(is_string(hlp)) {
      widgetset.popuphelp(private.buttons[index], txt=hlp);
    }
    private.frames[index] := tab;
    private.frames[index]->unmap();
    if (is_boolean(private.currTop)) {
      private.currTop := index;
      self.front(tabname2);
    }
    whenever private.buttons[index]->press do { 
      self->front($value);
      self.front($value);
    }
    private.whenevers[index] := last_whenever_executed();
    widgetset.tk_release();
#
    return T;
  }

###
  const self.dialogframe := function() 
  {
    return ref private.dframe;
  }
  
###
  const self.done := function() 
  {
    wider private, self;
    widgetset.popupremove(private.buttons);
    val private := F;
    val self := F;
    return T;
  }

###
  const self.front := function(tabname) 
  {
    wider private;
    widgetset.tk_hold();
    tabname2 := as_string(tabname);
    index := private.getindex(tabname2);
    if (is_fail(index)) fail;
#
    if (!is_boolean(private.currTop) &&
	is_agent(private.buttons[private.currTop])) {
      private.buttons[private.currTop]->relief('raised');
      private.buttons[private.currTop]->background(private.buttonbackground);
      private.frames[private.currTop]->unmap();
    }
    private.buttons[index]->relief('sunken');
    private.buttons[index]->background(private.framebackground);
    private.frames[index]->map();
    private.currTop := index;
    widgetset.tk_release();
    return T;
  }
  
###
  const self.replace := function(tab, tabname) 
  {
    wider private;
    tabname2 := as_string(tabname);
    index := private.getindex(tabname2);
    if (is_fail(index)) fail;
#        
    private.frames[index]->unmap();
    private.frames[index] := F;
    private.frames[index] := tab;
#
    if (!is_boolean(private.currTop)) {
      self.front(tabname2);
    }

#
    return T;
  }

###
  const self.which := function () 
  {
    wider private;
    rec := [=];
    if(private.currTop==F) return rec;
    
    for(nm in field_names(private.indices)) {
      if(private.indices[nm]==private.currTop) {
        rec.name := nm;
        rec.index := private.indices[nm];
        rec.col := private.col[nm];
        rec.row := private.row[nm];
      }
    }
    return rec;
  }

###  
  const self.available := function (tabname)
  {
    wider private;
    tabname2 := as_string(tabname);
    return tabname2 != ''  &&  any(private.names==tabname2);
  }

###  
  const self.list := function () 
  {
    wider private;
#
    s := shape(private.names);
    names := "";
    k := 1;
    for (j in 1:s[2]) {
       for (i in 1:s[1]) {
         if (strlen(private.names[i,j])>0) {
           names[k] := private.names[i,j];
           k +:= 1;
         }
       }
    }
#
    return names;
  }

###
  const self.delete := function (tabname) 
  {
    wider private;
#
    if(!is_string(tabname)) return F;
    if(!has_field(private.indices, tabname) ||
       private.indices[tabname]==F) return F;
#
    index := private.indices[tabname];
    col := private.col[tabname];
    row := private.row[tabname];
    val private.names[col, row] := '';
    val private.indices[tabname] := F;
    val private.buttons[index] := F;
    private.buttonframes[index]->unmap();
    private.frames[index]->unmap();
#
    ok := whenever_active(private.whenevers[index]);
    if (!is_fail(ok) && is_boolean(ok) && ok==T) {
       deactivate private.whenevers[index];
    }
#    
    for (name in field_names(private.indices)) {
      if(self.available(name)) {
	self.front(name);
	return T;
      }
    }
    return F;
  }

###
  const self.deleteall := function () 
  {
    wider private;
#
    widgetset.tk_hold();
    names := field_names(private.indices);
    for (name in names) {
      ok := self.delete(name);
      if (is_fail(ok)) {
         widgetset.tk_release(); 
         fail;
      }
    }
    widgetset.tk_release();
#
    return T;
  }
}
