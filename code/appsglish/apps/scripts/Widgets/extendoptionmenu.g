# extendoptionmenu.g: a widget for creating extendable flat menus whose label reflects the selection
# Copyright (C) 1996,1997,1998,1999,2000
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
#   $Id: extendoptionmenu.g,v 19.2 2004/08/25 02:13:33 cvsmgr Exp $
 
pragma include once
include 'widgetserver.g'

const extendoptionmenu := subsequence (ref parent, labels="", hlp='', hlp2='', 
                                       nbreak=20, symbol='...',  
                                       callback1=F, callback2=F, 
                                       callbackdata=F,
                                       dialoglabel='Item',
                                       dialogtitle='Enter new item <CR>',
                                       padx=7, pady=3, width=-1, updatelabel=T,
                                       height=1, justify='center', font='',
                                       relief='groove', borderwidth=2,
                                       foreground='black', background='lightgrey',
                                       disabled=F, anchor='c',
                                       fill='none', widgetset=dws)
{
   private := [=];

###
   private.duplicate := function (list, item)
   {
      for (i in 1:length(list)) {
         if (item==list[i]) return T;
      }
      return F;
   }   

###
   private.getlabels := function ()
   {
      return private.labels;
   }   

###
    self.done := function()
    {
      wider private, self;
      private.menu.done();
      val private := F; 
      val self := F;
      return T;
    }
   
###
   const self.disabled := function (disable=T)
   {
      return private.menu.disabled(disable);
   }


###
   const self.extend := function (labels="", updatelabel=T, width=-1) 
   {
      labels2 := [private.getlabels(), labels];
      return self.replace(labels=labels2, updatelabel=updatelabel, 
                          width=width);
   }

###
   const self.findlabel := function (label)
   {
      return private.menu.findlabel();
   }
      
###
   const self.getindex := function ()
   {
      return private.menu.getindex();
   }

###
   const self.getpreviousindex := function ()
   {
      return private.menu.getpreviousindex();
   }   
    
###
   const self.geteventmask := function ()
   {
      return private.menu.geteventmask();
   }          

### 
   const self.getlabel := function ()
   {
      return private.menu.getlabel();
   }
         
###
   const self.getlabels := function ()
   {
      return private.menu.getlabels();
   }
  

###
   const self.replace := function (labels="", updatelabel=T, width=-1) 
   {
      labels2 := [labels, private.symbol];
      private.menu.replace(labels=labels2, updatelabel=updatelabel, 
                           width=width)
#
      wider private;
      private.labels := labels;
      private.width := width;
      return T;
   }

###
   const self.selectindex := function (idx)
   {
      return private.menu.selectindex(idx);
   }

###
   const self.selectlabel := function (label)
   {
      return private.menu.selectlabel(label);
   }
       

###
   const self.setbackground := function (color)
   {
       private.menu.setbackground(color);
       return T;
   }

   
###
   const self.seteventmask:= function (mask)
   {
      return private.menu.seteventmask(mask);
   }

###
   const self.setforeground := function (color)
   {
       private.menu.setforeground(color);
       return T;
   }

###
   const self.setwidth := function (width)
   {
       wider private;
       return private.menu.setwidth(width);
   }



###  Constructor

   if (!is_agent(parent)) {
      return throw ('Variable "parent" must be an agent', origin='extendoptionmenu');
   }
#
   private.menu := widgetset.optionmenu(parent=parent, labels=[labels,symbol],
                                hlp=hlp, hlp2=hlp2, nbreak=nbreak, 
                                padx=padx, pady=pady, width=width,
                                updatelabel=updatelabel, height=height, 
                                justify=justify, font=font,
                                relief=relief, borderwidth=borderwidth,
                                foreground=foreground, background=background,
                                disabled=disabled, anchor=anchor,
                                fill=fill);
#
   private.labels := labels;
   private.width := width;
   private.symbol := symbol;
#
   whenever private.menu->replaced do {
      self->replaced();
   }
   whenever private.menu->select do {
#
      item := self.getlabel();
      if (item==private.symbol) {
         local newitem;
         ok := T;
#
         if (ok) {
            if (is_function(callback1)) {
               newitem := callback1()
               if (newitem==private.symbol || 
                   private.duplicate(private.labels, newitem)) ok := F;
            } else {
               private.menu.disabled(T);               
               newitem := widgetset.dialogbox(label=dialoglabel, title=dialogtitle);
               if (newitem==symbol || strlen(newitem)==0 ||
                   private.duplicate(private.labels, newitem)) ok := F;
               if (ok && is_function(callback2)) {
                  ok := callback2(newitem, private.menu.getlabels(), callbackdata);
               }
               private.menu.disabled(F); 
            }
         }
#
         if (ok) {
            labels2 := [private.labels, newitem];
            private.labels := labels2;
            labels2 := [private.labels, symbol];
            private.menu.replace(labels=labels2, updatelabel=updatelabel, 
                                 width=private.width)
            if (updatelabel) private.menu.selectlabel(newitem);
#
# Emit select event like optionmenu
#
            result := [=];
            result.label := newitem;
            result.name := result.label;
            result.value := result.label;
            self->select(result);
         } else {
            idx := private.menu.getpreviousindex();
            private.menu.selectindex(idx);
         }
      } else {
         self->select($value);
      }
   }
#
# Handle incoming setwidth event
#
   whenever self->setwidth do {
      self.setwidth($value);
   }
}
