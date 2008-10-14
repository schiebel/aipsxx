# selectablelist.g: Select entry from either a mneu or list box list
# Copyright (C) 1998,1999,2000
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: selectablelist.g,v 19.2 2004/08/25 02:19:51 cvsmgr Exp $
#
pragma include once

include 'widgetserver.g';
#
const selectablelist := subsequence (parent, lead, list, nbreak=20,
                                     label='Label', updatelabel=F,
                                     casesensitive=F,
                                     hlp='', padx=7, pady=3, width=-1,
                                     height=1, justify='center', font='',
                                     relief='groove', borderwidth=2,
                                     foreground='black', background='lightgrey',
                                     disabled=F, anchor='c',
                                     fill='none', widgetset=dws)

{
  private := [=];
  private.list := "";
  private.nbreak := 0;
  private.f0 := [=];
  private.isListBox := F;
  private.whenevers := [=];
  private.whenevers.holder := 0;  
  private.whenevers.menu := [];

###
  const private.findIt := function (const thing, const list)
  {
     for (i in 1:length(list)) {
        if (list[i] >= thing) return i;
     }
     return 1;
  }

###
   const private.makeListBox := function (list, updatelabel, lead)
   {
       wider private;
       nList := length(list);
#
# Just remap if we already have the listbox
#
       if (length(private.f0)>0) {
          private.f0->map();
          return;
       }
#
# Create listbox
#
       widgetset.tk_hold();
       private.f0 := widgetset.frame(tlead=lead, tpos='sw', relief='ridge');
       private.f0->unmap();
       widgetset.tk_release();
#
       private.f0.f0 := widgetset.frame(private.f0);
       private.f0.f1 := widgetset.frame(private.f0, side='left');
       width2 := max(strlen(list)) + 1;
       private.f0.f1.lb := widgetset.listbox(private.f0.f1, width=width2,
                                             borderwidth=1, mode='browse',
                                             exportselection=F, 
                                             height=min(10,nList+1));
       widgetset.popuphelp(private.f0.f1.lb,
                 'Select entry with MB1 after typing name or scrolling');
       private.f0.f1.sb := widgetset.scrollbar(private.f0.f1);
       widgetset.popuphelp(private.f0.f1.sb,
                 'Select entry with MB1 after typing name or scrolling');
       private.f0.db := widgetset.button(private.f0, 'Dismiss', 
                                         type='dismiss',borderwidth=1);
       whenever private.f0.f1.sb->scroll do {
          private.f0.f1.lb->view($value);
       }
       whenever private.f0.f1.lb->yscroll do {
          private.f0.f1.sb->view($value);
       }
       private.f0.f1.lb->insert(list);
       private.f0.f1.lb->select('start');
#
# Now the entry box
#
       private.f0.f0.en := widgetset.entry(private.f0.f0, width=width2);
       private.f0.f0.en->bind('<Key>', 'key');
       private.f0.f0.en->bind('<Tab>', 'tab');
       widgetset.popuphelp(private.f0.f0.en,
                 'Find entry in list by typing characters or by scrolling');
#
       whenever private.f0.f0.en->tab do {
          private.f0.f0.en->delete('start', 'end');
          private.f0.f0.en->insert(list[private.f0.f1.lb->selection() + 1]);
       }
#
       tr := private.trigger_event();
          whenever private.f0.f0.en->key do {
          tr->trigger();
       }
       whenever tr->triggered do {
         item := private.f0.f0.en->get()
         if (!casesensitive) item := to_upper(item);
         idx := private.findIt(item, list);
         idx2 := as_string(idx-1);       # 0-rel index for listbox
#        
         ok := private.f0.f1.lb->see(idx2);
         ok := private.f0.f1.lb->clear('start', 'end');
         ok := private.f0.f1.lb->select(idx2);
       }
#
       whenever private.f0.f1.lb->select, private.f0.f0.en->return do {
         idx := private.f0.f1.lb->selection() + 1;
         rec := [=];
         rec.index := idx;
         rec.item := list[idx];
         if (updatelabel) private.b0->text(rec.item);
         self->select(rec);
         private.f0->unmap();
       }
#
       whenever private.f0.db->press do {  
          private.f0->unmap();
       }
       private.f0->map();
   }


###
   const private.makeMenu := function (list, updatelabel)
   {
      wider private;
      private.whenevers.menu := [];
      i := 1;
      for (field in list) {
         private.b0[field] := widgetset.button(private.b0, field, value=i);
         whenever private.b0[field]->press do {
#
# Return menu item as value
#
           rec := [=];
           rec.index := $value;
           rec.item := list[rec.index];
           self->select(rec);
           if (updatelabel) private.b0->text(rec.item);
         }
         private.whenevers.menu[i] := last_whenever_executed();
         i +:= 1;
       }
    }

###
   const private.setList := function (list, nbreak, casesensitive)
   {
      wider private;
      if (!casesensitive) {
         private.list := to_upper(list);
      } else {
         private.list := list;
      }
      private.nbreak := nbreak;
   }

###
   const private.setWidth := function (width, updatelabel, label)
   {
      width2 := width;
      if (updatelabel) {
         if (width<0) width2 := max(strlen(private.list), strlen(label)) + 1;
      } else {
         if (width<0) width2 := strlen(label) + 1;
      }
      return width2;
   }

###
   const private.trigger_event := subsequence ()
   {
      whenever self->trigger do {
         self->triggered();
      }
   }

###
   const self.done := function ()
   {
     wider private, self;
     popupremove(private.b0);
     val private := F;
     val self := F;
     return T;
   }

###
   const self.disabled := function (disable=T)
   {
      private.b0->disabled(disable);
      return T;
   }

###
   const self.replace := function (lead, list, label='Label',
                                   updatelabel=F, casesensitive=F, width=-1)
   {
      wider private;
#
# We can't change nbreak in this function because then
# we would need to rpelace the holder button, private.b0
# and then the location in the parent would be lost
#
      nbreak0 := private.nbreak;
#
# Sort out width of holder button
#
      width2 := private.setWidth(width, updatelabel, label);
      private.b0->width(width2);
#
# Shutdown old  and make new
#
      widgetset.tk_hold();
      if (private.isListBox) {
         deactivate private.whenevers.holder;
         private.f0 := F;
         private.f0 := [=];
#
         private.setList(list, nbreak0, casesensitive);
         whenever private.b0->press do {
            private.makeListBox(private.list, updatelabel, lead);
         }
         private.whenevers.holder := last_whenever_executed();
      } else {
         i := 1;
         for (field in private.list) {
            private.b0[field] := F;
            deactivate private.whenevers.menu[i];
            i +:= 1;
         }
#
         private.setList(list, nbreak0, casesensitive);
         private.makeMenu(private.list, updatelabel);
      }
      private.b0->text(label);
#
      widgetset.tk_release();
#
      return T;
   }


###
   const self.setbackground := function (color)
   {
       private.b0->background(color);
       return T;
   }


###
   const self.setforeground := function (color)
   {
       private.b0->foreground(color);
       return T;
   }


###
   const self.setlabel := function (text)
   {
     private.b0->text(text);
   }

###
   const self.setwidth := function (width)
   {
      wider private;
      private.b0->width(width);
   }



### Constructor

#
  const nList := length(list);
  if (nList==0) {
     return throw ('You must give a non-empty list of items', 
                   origin='selectablelist.g');
  }
#
# Save list
#
  private.setList(list, nbreak, casesensitive);
  bType := 'plain';
  if (nList < nbreak) bType := 'menu'
  private.isListBox := (nList >= nbreak);
#
# Sort out button widths
# -1 is autofixed, 0 is autovariable, >0 is givenfixed
#
  width2 := private.setWidth(width, updatelabel, label);
#
# Holder button
#
  private.b0 := widgetset.button(parent=parent, text=label, 
                                 type=bType, padx=padx, 
                                 pady=pady, width=width2,
                                 height=height, justify=justify,
                                 font=font, relief=relief,
                                 borderwidth=borderwidth,
                                 foreground=foreground,
                                 background=background,
                                 disabled=disabled,
                                 anchor=anchor, fill=fill);
  if (strlen(hlp)>0) widgetset.popuphelp(private.b0, hlp);
#
# Create menu if < nBreak items and then we are done with it
#
  if (private.isListBox) {
     whenever private.b0->press do {
       private.makeListBox(private.list, updatelabel, lead);
     }
     private.whenevers.holder := last_whenever_executed();
  } else {
     private.makeMenu(private.list, updatelabel);
  }
#
# Handle incoming setwidth event
#
   whenever self->setwidth do {
      self.setwidth($value);
   }
}
