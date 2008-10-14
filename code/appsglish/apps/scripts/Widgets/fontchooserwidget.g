# fontchooserwidget.g: widget for interactively selecting fonts 
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
# $Id: fontchooserwidget.g,v 19.2 2004/08/25 02:13:43 cvsmgr Exp $

pragma include once

include 'combobox.g'
include 'unset.g'
include 'widgetserver.g'

   # This is a very crude font chooser there are likely other more wonderous
   # ones we could create but this will do the job in a pinch.

fontchooserwidget := subsequence(parent=F, font=F, ws=dws){
   public := [=];
   priv := [=];
   priv.font := '-adobe-courier-medium-r-normal--14-*'; 
   priv.ws := ws;
   if(is_string(font)){
      priv.font := font;
   }
       # Make a crude font chooser window.
   if(is_boolean(parent) || is_unset(parent)){
      include "guiframework.g";
      priv.self := self;

      action := [=];
      action.apply := [=];
      action.apply.text := 'Apply';
      action.apply.action := function(){
         wider priv; 
         priv.self->font(priv.newfont);
         priv.gf.dismiss();
      }
      action.reset := [=];
      action.reset.text := 'Reset';
      action.reset.action := function(){wider priv; priv.fc->reset()};
      action.cancel := [=];
      action.cancel.text := 'Dismiss';
      action.cancel.action := function(){wider priv; priv.gf.dismiss()};

      priv.gf := guiframework('Font Chooser', menus=F, helpmenu=F,
                               actions=action);
      priv.parent := priv.gf.getworkframe();
      priv.newfont := priv.font;
   } else {
      priv.parent := parent;
   }

   f := priv.ws.frame(priv.parent);
   kf := f->fonts();
   cb := combobox(f, 'Font', kf, listboxheight=15,
                         entrywidth=max(strlen(kf)), entrydisabled=T)
   fn_ss := priv.font ~ s/\*/.*/g
   eh := ind(kf)[kf ~ eval(spaste('m/',fn_ss,'/'))];
   cb.select(eh[1]-1);  #-1 cause the listbox is zero based.
   cbagent := cb.agent();

   line1 := 'ABCDEFGHIJKLMNOPQRSTUVWXYXZ 0123456789';
   line2 := 'abcdefghijklmnopqrstuvwxyz';
   m1 := priv.ws.message(f, text=line1, font=font, relief='flat', width=350);
   m2 := priv.ws.message(f, text=line2, font=font, relief='flat', width=350);

   priv.newfont := F;
   whenever cbagent->select do {
      newfont := kf[as_integer($value)+1];
      self->newfont(newfont);
      priv.newfont := newfont;
      m1->font(newfont);
      m2->font(newfont);
   }

   whenever self->reset do {
      cb.select(eh[1]-1);  #-1 cause the listbox is zero based.
      m1->font(priv.font);
      m2->font(priv.font);
   }

   whenever self->unmap do {
      if(has_field(priv, 'gf'))
         priv.gf.dismiss();
      else
        f->unmap();
   }

   whenever self->map do {
      f->map();
   }
   whenever self->close do {
      if(has_field(priv, 'gf'))
         priv.gf.dismiss();
      else
         f->unmap();
   }
}
