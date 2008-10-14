# viewerimagesummaries.g: Viewer support for summary display from images
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001
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
#   $Id: viewerimagesummaries.g
#


pragma include once


include 'coordsys.g'
include 'note.g'
include 'unset.g'
include 'widgetserver.g'

const viewerimagesummaries := subsequence (parent, widgetset=dws)
{
    its := [=];
    its.ws := widgetset;

# Callback functions

    its.getImageTool := [=];               # Get Image tool from ddname 
#
    its.td := [=];                         # Tab dialog
    its.tabs := [=];                       # The tabs, indexed by ddname
    its.tabnames := "";                    # The tab names (indexed by integer)
    its.ddnames := "";                     # DisplayData names
    its.index := [=];                      # Tabs index. Indexed by ddname
    its.active := [=];                     # Activity status, indxed by ddname

### Private methods


###
   const its.addOneTab := function (ddname)
   {
      wider its;
# Overwrite if name exists, else we get in big logic tangles.

      if (has_field(its.index, ddname)) {
         n := its.index[ddname];
      } else {
         n := length(its.tabnames) + 1;
      }
#
      tabname := ddname;
      its.tabnames[n] := tabname;
      its.ddnames[n] := ddname;
      its.index[ddname] := n;

# Create TAB, indexed by string converted integer
# and add it to the tabdialog widget

      ok := its.makeTab(n, ddname, tabname);
      if (is_fail(ok)) fail;
#
      return ok;
   }

###
    const its.clearGui := function (ref rec)
    {
       rec.st->delete('start', 'end');
#
       return T;
    }
    

###
    const its.makeTab := function (idx, ddname, tabname)
    {
       wider its;
       its.ws.tk_hold();
#
       its.tabs[ddname] := its.ws.frame(its.tdf, side='top', relief='raised');
       its.tabs[ddname].st := its.ws.scrolltext(its.tabs[ddname], height=18, width=98,
                                                wrap='none');

# Add new TAB to the tabdialog widget

       ok := its.td.add(its.tabs[ddname], tabname);
       if (is_fail(ok)) fail;
       if (length(its.td.list())==1)  its.td.front(tabname);
#
       its.ws.tk_release();
#
       return T;
    }


###
    const its.writeGui := function (rec, summary)
    {
       its.ws.tk_hold();
       rec.st->disabled(F);
       its.clearGui (rec);
       for (i in 1:length(summary)) {
          if (i==1) {
             rec.st->append(summary[i]);
          } else {
             rec.st->append(spaste('\n', summary[i]));
          }
       }
       rec.st->disabled(T);
       its.ws.tk_release();
       return T;
    }


### Public methods

###
    const self.add := function (ddname) 
    {
       wider its;
#
       if (has_field(its.index, ddname) && its.active[ddname]) {
          return throw (spaste('Entry ', ddname, ' is already active'),
                        origin='viewerimagesummaries.add');
       }
#
       ok := its.addOneTab(ddname); 
       if (is_fail(ok)) fail;
       its.active[ddname] := T;
#
       im := its.getImageTool(ddname);
       if (is_fail(im)) fail;
#
       messages := im.summary(list=F);
       if (is_fail(messages)) fail;
       ok := its.writeGui(its.tabs[ddname], messages);
#
       return T;
    }

###
    const self.delete := function (ddname) 
    {
       wider its;
#
       if (has_field(its.active, ddname) && !its.active[ddname]) {
          return throw (spaste('Entry ', ddname, ' is not active'),
                        origin='viewerimagesummaries.delete');
       }
#
       idx := its.index[ddname];
       tabname := its.tabnames[idx];
       ok := its.td.delete(tabname); 
       if (is_fail(ok)) fail;
       ok := its.tabs[ddname].st.done();
       if (is_fail(ok)) fail;
       its.tabs[ddname] := F;
       its.active[ddname] := F;
#
       return T;
    }


###
    const self.done := function () 
    {
       wider its, self;
#
       ok := its.td.done();
#
       for (ddname in its.ddnames) {
          if (its.active[ddname]) {
             ok := its.tabs[ddname].st.done();
          }
       }
#
       val its := F;
       val self := F;
#
       return T;
    }


###
   const self.setcallbacks := function (callback1=unset)
   {
      wider its;

# Arg. ddname, returns image Tool

      if (is_function(callback1)) {
         its.getImageTool := callback1;
      } else {
         if (!is_unset(callback1)) {
            return throw ('callback1 is not a function',
                           origin='viewerimagesummaries.setcallbacks');
         }
      }
#
      return T;
   }

### Constructor


# Tab dialog 

   its.td := its.ws.tabdialog(parent, colmax=3, title=unset);
   if (is_fail(its.td)) fail;

# Frame to put all the TABS in

   its.tdf := its.td.dialogframe();
   if (is_fail(its.tdf)) fail;
}
