# optionmenu.g: a widget for creating flat menus whose label reflects the selection
# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: optionmenu.g,v 19.2 2004/08/25 02:17:14 cvsmgr Exp $
 
pragma include once
include 'widgetserver.g'
include 'selectablelist.g'
include 'note.g'

const optionmenu := subsequence (ref parent, labels="", names="", values="",
                                 hlp='', hlp2='', nbreak=20, padx=7, 
                                 pady=3, width=-1, updatelabel=T,
                                 height=1, justify='center', font='',
                                 relief='groove', borderwidth=2,
                                 foreground='black', background='lightgrey',
                                 disabled=F, anchor='c',
                                 fill='none', widgetset=dws)
{
   if (!is_agent(parent)) {
      return throw ('Variable "parent" must be an agent', origin='optionmenu');
   }

   private := [=];
   private.empty := T;
   private.menu := [=];           # Menu
   private.data := [=];           # labels, names, values
   private.isEnabled := T;
   private.isSelList := F;        # Are we a selectablelist or menu ?
   private.nbreak := nbreak;

###
   const private.updateInternals := function (idx, updatelabel) 
   {
      wider private;
#
      if (updatelabel) {
         if (private.isSelList) {
            private.menu.setlabel(private.data.labels[idx]);
         } else {
            private.menu->text(private.data.labels[idx]);
         }
      }
#
      private.data.value := private.data.values[idx];
      private.data.label := private.data.labels[idx];
      private.data.name := private.data.names[idx];
      private.data.lastindex := private.data.index;
      private.data.index := idx;
#
      if (private.data.mask[idx]) {
         result := [=];
         result.label := private.data.label;
         result.name := private.data.name;
         result.value := private.data.value;
         result.index := idx;
         self->select(result);
      }
   }

###
   const private.buildSubMenu := function (updatelabel)
   {
      wider private;
#
      private.data.whenevers := [];
      const nLabels := length(private.data.labels);
      if (nLabels>0) {
         for (i in 1:nLabels) {
            field := spaste(i);
            private.menu[field] := widgetset.button(parent=private.menu,
                                                    type='plain',
                                                    text=private.data.names[i], 
                                                    value=private.data.values[i],
                                                    font=font, 
                                                    foreground=foreground,
                                                    background=background);
            private.menu[field]['index'] := i;
#
            whenever private.menu[field]->press do {
               ag := $agent;
               idx := ag.index;
               private.updateInternals (idx, updatelabel);
            }
            private.data.whenevers[i] := last_whenever_executed();
         }
      }
   }


###
   const private.checkInputs := function (labels, ref names, ref values, ref nbreak)
   {
      nLabels := length(labels);
      if (nLabels>0 && !is_string(labels)) {
         return throw('The "labels" variable must be a string', 
                      origin='optionmenu');
      }
      nNames := length(names);
      if (nNames>0 && !is_string(names)) {
         return throw('The "names" variable must be a string', 
                      origin='optionmenu');
      }
      nValues := length(values);      
#      
      if (nNames>0 && nNames!=nLabels) {
         msg := 'The "names" variable must be the same length as the "labels" variable';
         return throw(msg, origin='optionmenu');
      }
      if (nValues>0 && nValues!=nLabels) {
         msg := 'The "values" variable must be the same length as the "labels" variable';
         return throw(msg, origin='optionmenu');
      }
      if (nNames==0) val names := labels;
      if (nValues==0) val values := labels;
#
      if (nbreak <=0) val nbreak := 20;
      return T;
   }

###
   const private.setInitial := function (ref initLabel, ref width2, labels, names, 
                                         values, width)
   {   
      const nLabels := length(labels);
      local initName, initMask, initIndex, initValue;
      if (nLabels > 0) {
         val initLabel := labels[1];
         initName := names[1];
         initValue := values[1];
         val width2 := width;
         if (width<0) {
            val width2 := max(width2,strlen(labels));
         }
        initMask := array(T, nLabels);
        initIndex := 1;
     } else {
        val initLabel := 'Empty menu'; 
        initName := "";
        initValue := "";
        val width2 := width;
        if (width2<0) val width2 := strlen(initLabel);
        initMask := [];
        initIndex := "";
      }
#
      wider private;
      private.data.label := initLabel;
      private.data.name := initName;
      private.data.value := initValue;
      private.data.mask := initMask;
      private.data.index := initIndex;
      private.data.lastindex := initIndex;
#
      return T;
   }


###
   const private.setMenu:= function (labels, names, values, nbreak)
   {
      wider private;
      private.data.labels := labels;
      private.data.names := names;
      private.data.values := values;
      private.nbreak := nbreak;
      private.empty := (length(labels)==0);
#
      return T;
   }

###
    const self.done := function()
    {
      wider private, self;
      if (private.isSelList) {
         private.menu.done();
      } else {
         widgetset.popupremove(private.menu);
      }
#
      val private := F; 
      val self := F;
      return T;
    }


###
   const self.disabled := function (disable=T)
   {
      wider private;
      if (private.isSelList) {
         private.menu.disabled(disable);
      } else {
         private.menu->disabled(disable);
      }
      private.isEnabled := !disable;
      return T;
   }


###
   const self.extend := function (labels="", names="", values="",
                                  updatelabel=T, width=-1)
   {
#
# Check inputs
#
      nbreak0 := private.nbreak;
      check := private.checkInputs(labels, names, values, nbreak0);
      if (is_fail(check)) fail;
#
# Add to existing list.  Fails occur if types are inconsistent
#
      newlabels := [private.data.labels, labels];      
      if (is_fail(newlabels)) fail;
      newnames := [private.data.names, names];      
      if (is_fail(newnames)) fail;
      newvalues := [private.data.values, values];      
      if (is_fail(newvalues)) fail;
      newmask := [self.geteventmask(), array(T, length(labels))];
      if (is_fail(newmask)) fail;
#
# Replace menu
#
      self.replace(newlabels, newnames, newvalues, 
                   updatelabel, width);
#
# Set event mask
#
      self.seteventmask(newmask);
#
      return T;
   }


###
   const self.findlabel := function (label)
   {
      if (private.empty) return F;
#
      const nLabels := length(private.data.labels);
      for (i in 1:nLabels) {
         if (private.data.labels[i] == label) return i;
      }
      return F;
   }

###
   const self.findname := function (name)
   {
      if (private.empty) return F;
#
      const nLabels := length(private.data.labels);
      for (i in 1:nLabels) {
         if (private.data.names[i] == name) return i;
      }
      return F;
   }

###
   const self.findvalue := function (value)
   {
      if (private.empty) return F;
#
      const nLabels := length(private.data.labels);
      for (i in 1:nLabels) {
         if (private.data.values[i] == value) return i;
      }
      return F;
   }


###
   const self.getindex := function ()
   {
      if (private.empty) {
         return F;
      } else {
         return private.data.index;
      }
   }   


###
   const self.getpreviousindex := function ()
   {
      if (private.empty) {
         return F;
      } else {
         return private.data.lastindex;
      }
   }   


###
   const self.getvalue := function ()
   {
      if (private.empty) {
         fail 'Empty menu';
      } else {
         return private.data.value;
      }
   }   

###
   const self.getvalues := function ()
   {
      return private.data.values;
   }   


###
   const self.geteventmask := function ()
   {
      return private.data.mask;
   }   


###
   const self.getlabel := function ()
   {
      if (private.empty) {
         return F;
      } else {
         return private.data.label;
      }
   }   

###
   const self.getlabels := function ()
   {
      return private.data.labels;
   }   

###
   const self.getname := function ()
   {
      if (private.empty) {
         note (msg='Empty menu', priority='WARN', origin='optionmenu');
         return F;
      } else {
         return private.data.name;
      }
   }   

###
   const self.getnames := function ()
   {
      return private.data.names;
   }   


###
   const self.isenabled := function ()
   {
      return private.isEnabled;
   }

###
   const self.replace := function (labels="", names="", values="", 
                                   updatelabel=T, width=-1)
   {
      wider private;
#
# Check inputs
#
      nbreak0 := private.nbreak;
      check := private.checkInputs(labels, names, values, nbreak0);
      if (is_fail(check)) fail;
#
# Store inputs internally
#
      private.setMenu(labels, names, values, nbreak0);
#
# Shut down old and make new
#
      widgetset.tk_hold();
      local width2, initLabel;
      private.setInitial(initLabel, width2, labels, names, 
                         values, width);
#
      if (private.isSelList) {
         private.menu.replace(lead=parent, list=private.data.names,
                              updatelabel=updatelabel, casesensitive=T,
                              width=width2);
         private.menu.setlabel(initLabel);
      } else {
	numwhenevers := length(private.data.whenevers);
	if (numwhenevers > 0) {
	  deactivate private.data.whenevers;
	  private.data.whenevers := [];
	}
	nummenus := length(private.menu);
	if (nummenus > 0) {
	  for (i in nummenus:1) {
            val private.menu[spaste(i)] := F;
	  }
	}
#
	private.menu->text(initLabel);
	private.menu->width(width2);
	private.buildSubMenu(updatelabel);
      }
#
      widgetset.tk_release();
      self->replaced();
#
      return T;
   }



###
   const self.selectindex := function (idx)
   {
      if (!is_integer(idx)) {
         msg := 'The variable "idx" must be an integer';
         note (msg, priority='WARN', origin='optionmenu');   
         return F;
      }
      const nLabels := length(private.data.labels);
      if (private.empty) {
         msg := 'There are no entries in the menu';
         note (msg, priority='WARN', origin='optionmenu');   
         return F;
      }
#
      wider private;
      if (idx<1 || idx>length(private.data.labels)) {
         msg := spaste('Index not in the range [1,',
                       length(private.data.labels), ']');
         note (msg, priority='WARN', origin='optionmenu');   
         return F;
      }
#
      private.data.label := private.data.labels[idx];
      private.data.name := private.data.names[idx];
      private.data.value := private.data.values[idx];
      private.data.lastindex := private.data.index;
      private.data.index := idx;
#
      widgetset.tk_hold();
      if (private.isSelList) {
         private.menu.setlabel(private.data.labels[idx]);
      } else {
         private.menu->text(private.data.labels[idx]);
      }
      widgetset.tk_release();
      return T;
   }


###
   const self.selectlabel := function (label)
   {
      idx := self.findlabel(label);
      if (idx==F) return F;
      return self.selectindex(idx);
   }

###
   const self.selectname := function (name)
   {
      idx := self.findname(name);
      if (idx==F) return F;
      return self.selectindex(idx);
   }

###
   const self.selectvalue := function (value)
   {
      idx := self.findvalue(value);
      if (idx==F) return F;
      return self.selectindex(idx);
   }


###
   const self.setbackground := function (color)
   {
       if (private.isSelList) {
          private.menu.setbackground(color);
       } else {
          private.menu->background(color);
       }
       return T;
   }


###
   const self.seteventmask:= function (mask)
   {
      if (!is_boolean(mask)) {
         msg := '"mask" variable must be Boolean';
         note (msg, priority='WARN', origin='optionmenu');
         return F;
      }
      if (length(mask) != length(private.data.labels)) {
         msg := spaste('"mask" variable must of length ', 
                       length(private.data.labels));
         note (msg, priority='WARN', origin='optionmenu');
      }
#
      wider private;
      private.data.mask := mask;
      return T;
   }

###
   const self.setforeground := function (color)
   {
       if (private.isSelList) {
          private.menu.setforeground(color);
       } else {
          private.menu->foreground(color);
       }
       return T;
   }



###
   const self.setlabel := function (label)
   {
       wider private;
       private.data.label := label;
       if (private.isSelList) {
          private.menu.setlabel(label);
       } else {
          private.menu->text(label);
       }
       return T;
   }

###
   const self.setwidth := function (width)
   {
       wider private;
       if (private.isSelList) {
          return private.menu.setwidth(width);
       } else {
          return private.menu->width(width);
       }
   }



###
#
# Here is the constructor
#
# Checks
#
   check := private.checkInputs(labels, names, values, nbreak);
   if (is_fail(check)) fail;
#
# Store menu inputs internally
#
   private.setMenu(labels, names, values, nbreak);
#   
# Set initial quantities.  Initial state of event mask is T
#
   local initLabel, width2;
   private.setInitial(initLabel, width2, labels, names, values, width);
#
# Create selectablelist or menu 
#
   private.isSelList := (length(private.data.labels)>=nbreak);
   if (private.isSelList) {
      private.menu := widgetset.selectablelist(parent, lead=parent, 
                                               list=private.data.names,
                                               nbreak=1,
                                               label=private.data.labels[1],
                                               updatelabel=F,   # handled in optionmenu.g
                                               casesensitive=T,
                                               padx=padx, pady=pady,
                                               hlp=hlp, width=width,
                                               height=height, justify=justify,
                                               font=font,
                                               relief=relief, 
                                               borderwidth=borderwidth,
                                               foreground=foreground,
                                               background=background,
                                               disabled=disabled, 
                                               anchor=anchor,
                                               fill=fill);
#
      private.data.whenevers := [];
      whenever private.menu->select do {
         idx := $value.index;
         item := $value.item;
         private.updateInternals (idx, updatelabel);
      }
      private.data.whenevers[1] := last_whenever_executed();
   } else {
      private.menu := widgetset.button(parent, type='menu', 
                                       text=initLabel,
                                       padx=padx, pady=pady, 
                                       width=width2,
                                       height=height, justify=justify,
                                       font=font, relief=relief, 
                                       borderwidth=borderwidth,
                                       foreground=foreground,
                                       background=background,
                                       disabled=disabled, 
                                       anchor=anchor, 
                                       fill=fill);
#
      if (strlen(hlp)>0) {
         if (strlen(hlp2)==0) {
             widgetset.popuphelp(private.menu, hlp);
         } else {
            widgetset.popuphelp(private.menu, hlp2, hlp, combi=T);
         }
      }
#
# Add submenu and service 
# 
      private.buildSubMenu(updatelabel);
   }
#
# Handle incoming setwidth event
#
   whenever self->setwidth do {
      self.setwidth($value);
   }
}
