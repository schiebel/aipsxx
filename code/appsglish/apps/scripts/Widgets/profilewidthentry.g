# profilewidthentry.g: widget to get width of a 1-D profile
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
#   $Id: profilewidthentry.g,v 19.2 2004/08/25 02:17:49 cvsmgr Exp $
#
#

pragma include once
include 'widgetserver.g'


const profilewidthentry := subsequence (parent, relief='raised',
                                        width=10, widgetset=dws)
{
#
   its := [=];
#
   its.entrywidth := width;
   its.width := 0;          # Profile averaging width in pixels
   its.frames := [=];
   its.ws := widgetset;
#

### Private functions

###
   const its.getAveragingWidth := function ()
   {
      wider its;
#
      t := as_integer(its.frames.f0.f1.width->get());
      if (t < 0) t := 0;
      its.width := t;
      return its.width;
   }


### Public functions


###
   const self.done := function ()
   {
      wider its;
      wider self;
#
      val its := F;
      val self := F;
#
      return T;
   }

###
   self.disable := function ()
   {
      wider its;
      return its.frames.f0->disabled(T);
   }

###
   self.enable := function ()
   {
      wider its;
      return its.frames.f0->disabled(F);
   }

###
   self.getvalue := function ()
   {
      ok := its.getAveragingWidth();    # User may not have pressed return after type in
      if (is_fail(ok)) fail;
#
      r := [=];
      r.value := its.width;
      r.type := its.frames.f0.f0.widthshapes.getvalue();
      return r;
   }


### Constructor 

   its.frames.f0 := its.ws.frame(parent, side='left', relief=relief, expand='x');
#
   its.frames.f0.f0 := its.ws.frame(its.frames.f0, side='top', relief='flat');
   its.frames.f0.f0.label := its.ws.label(its.frames.f0.f0, 'Width shape');
   longTxt := spaste (' - You can average the profile over some shape centered\n',
                      '   on the cursor.  This menu gives you the shape choices');
   its.ws.popuphelp (its.frames.f0.f0.label, longTxt, 'Averaging shape', combi=T);
   its.frames.f0.f0.widthshapes := its.ws.optionmenu(its.frames.f0.f0, labels="box");
   whenever its.frames.f0.f0.widthshapes->select do {
      self->select($value.value);
   }
#
   its.frames.f0.f1 := its.ws.frame(its.frames.f0, side='top', relief='flat');
   its.frames.f0.f1.label := its.ws.label(its.frames.f0.f1, 'Width (pix)');
   longTxt := spaste (' - You can average the profile over some shape centered\n',
                      '   on the cursor.  This entry widget allows you to specify\n',
                      '   the half-width in pixels.  Use 0 for no averaging');
   its.ws.popuphelp (its.frames.f0.f1.label, longTxt, 
                     'Averaging shape half width in pixels', combi=T);
#
   its.frames.f0.f1.width := its.ws.entry(its.frames.f0.f1, width=its.entrywidth);
   its.frames.f0.f1.width->insert(as_string(its.width));
   whenever its.frames.f0.f1.width->return do {
      t := its.getAveragingWidth();
      its.frames.f0.f1.width->delete('start', 'end');
      its.frames.f0.f1.width->insert(as_string(t));
#
      self->value(t);
   }
}

