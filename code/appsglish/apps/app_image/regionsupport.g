# regionsupport.g: support object for regions widgets
#
#   Copyright (C) 1996,1997,1998,1999,2000
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
#   $Id: regionsupport.g,v 19.2 2004/08/25 01:01:06 cvsmgr Exp $
#
# emits events :
 
pragma include once

include 'popuphelp.g'
include 'regionmanager.g'
include 'widgetserver.g'
include 'image.g'
include 'table.g'
include 'serverexists.g'
include 'unset.g'

const regionsupport := subsequence (widgetset=dws)
{
   if (!serverexists('drm', 'regionmanager', drm)) {
      return throw('The regionmanager "drm" is either not running or not valid', 
                    origin='regionsupport.g');
   }

   prvt := [=];
   prvt.listBoxes := [=];
   prvt.dismissButtons := [=];
   prvt.entryBoxes := [=];
   prvt.confirmMenus := [=];
   prvt.ge := widgetset.guientry(expand='x');

###
   const prvt.kind_of_symbol := function (const name, ref isDef, 
                                          ref isConst, ref isFun)
   {
      val isDef := F;
      val isConst := F;
      val isFun := F;
      if (is_defined(name)) {
         val isDef := T;
#
         cmd := spaste('is_const(', name, ')');
         val isConst := eval(cmd);
         if (is_fail(isConst)) { 
            return throw ('Internal error evaluating symbol, this is a bug',
                          origin='regionsupport.kind_of_symbol');
         }
         if (is_function(symbol_value(name))) val isFun := T;
      }
      return T;
   }


###
   const self.build_listBoxes := function (ref regionsListBox,
                                           ref parent, height=8, 
                                           width=12, expand='both',
                                           showtype=T)
   {
      widgetset.tk_hold();
      wider prvt;
      idx := length(prvt.listBoxes) + 1;
#
      prvt.listBoxes[idx] := widgetset.frame(parent, side='top', expand=expand, 
                                   relief='raised');
      if (showtype) {
         prvt.listBoxes[idx].lb := widgetset.synclistboxes(prvt.listBoxes[idx], nboxes=2, 
                                                           mode='extended',
                                                           labels="Name Type", width=width,
                                                           height=height);
      } else {
         prvt.listBoxes[idx].lb := widgetset.synclistboxes(prvt.listBoxes[idx], nboxes=1,
                                                           mode='extended',
                                                           labels="Name", width=width,
                                                           height=height);
      }
      val regionsListBox := ref prvt.listBoxes[idx].lb;          # reference for ease of use
      widgetset.tk_release();
      return T;
   }

###
   const self.insert_regions := function (ref regions, table='',
                                          ref regionsListBox, 
                                          fromTable, showtype=T)
   {
#
# Regions may be fished out of a table, or given in a record
#
      if (fromTable) {
         val regions := drm.fromtabletorecord(table, numberfields=F,
                                              verbose=F);
         if (is_fail(regions)) fail;
      }
#
      regionsListBox->delete('start', 'end');
      nRegions := length(regions);
      if (nRegions>0) {
         local stuff;
         if (showtype) {
            stuff := array('',2,nRegions);
            stuff[1,] := field_names(regions);
            for (i in 1:nRegions) {
              stuff[2,i] := self.name_to_string(regions[stuff[1,i]].get('name'));
            }
         } else {
            stuff := array('',1,nRegions);
            stuff[1,] := field_names(regions);
         }
#
         regionsListBox->insert(stuff);
         regionsListBox->see('start');
         regionsListBox->clear('start', 'end');
      }
      return T;
   }

###
   const self.isRegion_defined := function (ref nameNew, ref doIt, 
                                            nameOld, confirm)
   {
      val doIt := T;
      isFun := F;
      isDef :=F;
      isConst := F;
      prvt.kind_of_symbol(nameNew, isDef, isConst, isFun);
#
      if (!isDef) {
         val doIt := T;
         return T;
      }
#
      if (isConst) {
         msg := spaste('The symbol "', nameNew, '" is an existing ',
                       'const symbol, you cannot overwrite it; aborted');
         note (msg, priority='WARN',
               origin='regionsupport.isRegion_defined');
         val doIt := F;
         return T;
      }
#
      if (confirm | isFun) {
         while (T) {
            if (isDef) {
               if (isFun) {
                  msg := spaste('The symbol "', nameNew, '" is an existing ',
                                 'function, do you really want to overwrite it ?');
               } else {
                  msg := spaste('The symbol "', nameNew, 
                                 '" already exists, overwrite it ?');
               }
               ok := choice(msg, "yes no rename");
#
               if (ok=='no') {
                  note ('Aborted', priority='WARN',
                        origin='regionsupport.isRegion_defined');
                  val doIt := F;
                  return T;     
               } else if (ok=='rename') {  
                  lastName := nameNew;
                  item := widgetset.dialogbox(label=nameOld, title='Enter new name <CR>',
                                              type='string', value='');
                  if (is_fail(item)) {
                     note ('Aborted', priority='WARN',
                           origin='regionsupport.isRegion_defined');
                     val doIt := F;
                     return T;     
                  }
#                  
                  val nameNew := item;
                  if (strlen(nameNew)==0) {
                     note ('Empty string, try again',  priority='WARN',
                           origin='regionsupport.isRegion_defined');
                     val nameNew := lastName;
                  } else {
                     prvt.kind_of_symbol(nameNew, isDef, isConst, isFun);
                     if (!isDef) {
                        val doIt := T;
                        return T;
                     }
                  }           
               } else {
                  msg := spaste('Overwriting the symbol "', nameNew, '"');
                  note (msg, priority='WARN',  
                        origin='regionsupport.isRegion_defined');
                  val doIt := T;
                  return T;
               }
             }
         }
      } else {
         if (is_defined(nameNew)) {
            msg := spaste('Overwriting the symbol "', nameNew, '"');
            note (msg, priority='WARN',  
                  origin='regionsupport.isRegion_defined');
         }
      }
      return T;
   }


###
   const self.getTableName := function(thing) 
#
# Handles Image, Table, file name, name of Image, name of Table
#
   {
      tableName := '';
      ok := T;
      if (is_image(thing)) {
         tableName := thing.name(strippath=F);
      } else if (is_table(thing)) {
         tableName := thing.name();
      } else if (is_string(thing)) {
         if (is_defined(thing)) {
            local tmp := symbol_value(thing);
            if (is_image(tmp)) {
              tableName := tmp.name(F);
            } else if (is_table(tmp)) {
              tableName := tmp.name();
            } else {
               ok := F;
            }
         } else {
            if (strlen(thing)>0) {
               tableName := thing;
            } else {
              ok := F;
            }
         }
      }
      if (!ok) {
         return throw ('The given table name is not an image, table, or string',
                       origin='regionsupport.getTableName');
      }
      return tableName;
   }


###
   const self.create_dismiss := function (ref dismissButton, ref parent, 
                                          doSpace, width=-1)
   {
      wider prvt;
      idx := length(prvt.dismissButtons) + 1;
      prvt.dismissButtons[idx] := [=];
      if (doSpace) prvt.dismissButtons[idx].space0 := widgetset.frame(parent, height=1, expand='x');
      if (width < 0) {
         prvt.dismissButtons[idx].b := widgetset.button(parent, 'Dismiss', type='dismiss');
      } else {
         parent.dismissButtons[idx].b := widgetset.button(parent, 'Dismiss',  type='dismiss',
                                                        width=width);
      }
      widgetset.popuphelp(prvt.dismissButtons[idx].b, 'Dismiss window (recover with function gui)');
      val dismissButton := ref prvt.dismissButtons[idx].b;      
      return T;
   }

###
   const self.create_entry := function (ref entryBox, ref parent, labelName=unset, width, 
                                        labelhlp1=unset, labelhlp2=unset)
   {
      wider prvt;
      idx := length(prvt.entryBoxes) + 1;
      prvt.entryBoxes[idx] := widgetset.frame(parent, side='left', expand='x');
      if (!is_unset(labelName)) {
         prvt.entryBoxes[idx].label := widgetset.label(prvt.entryBoxes[idx],
                                                       text=labelName);
      }
      prvt.entryBoxes[idx].eb := prvt.ge.string(prvt.entryBoxes[idx], editable=T);
      prvt.entryBoxes[idx].eb.setwidth(width);
      val entryBox := ref prvt.entryBoxes[idx].eb;
#
      if (!is_unset(labelName) && !is_unset(labelhlp1)) {
         if (!is_unset(labelhlp2)) {
            widgetset.popuphelp(prvt.entryBoxes[idx].label, labelhlp2, labelhlp1, combi=T);
         } else {
            widgetset.popuphelp(prvt.entryBoxes[idx].label, labelhlp1);
         }
      }
      return T;
   }

###
   const self.create_vectorentry := function (ref entryBox, ref parent, labelName=unset, width, 
                                              labelhlp1=unset, labelhlp2=unset, default)
   {
      wider prvt;
      idx := length(prvt.entryBoxes) + 1;
      prvt.entryBoxes[idx] := widgetset.frame(parent, side='left', expand='x');
      if (!is_unset(labelName)) {
         prvt.entryBoxes[idx].label := widgetset.label(prvt.entryBoxes[idx],
                                                       text=labelName);
      }
      prvt.entryBoxes[idx].eb := prvt.ge.array(prvt.entryBoxes[idx], 
                                               editable=T, default=default);
      prvt.entryBoxes[idx].eb.setwidth(width);
      val entryBox := ref prvt.entryBoxes[idx].eb;
#
      if (!is_unset(labelName) && !is_unset(labelhlp1)) {
         if (!is_unset(labelhlp2)) {
            widgetset.popuphelp(prvt.entryBoxes[idx].label, labelhlp2, labelhlp1, combi=T);
         } else {
            widgetset.popuphelp(prvt.entryBoxes[idx].label, labelhlp1);
         }
      }
      return T;
   }

###
   const self.create_confirm := function (ref confirmMenu, ref parent, value,
                                          width=0, relief='groove')
#
# relief='groove', and type='menu'  is a differnet width from
# relief='groove', and type='plain'.  So I add 2 to the default
# padx to fudge around this.  Yuck.
#
   {
      labels := "Confirm NoConfirm";
      names := ['confirm', 'no confirm'];
      values := [T,F];
#
      wider prvt;
      idx := length(prvt.confirmMenus) + 1;
      prvt.confirmMenus[idx] := widgetset.optionmenu(parent=parent, labels=labels, 
                                                     names=names,  values=values, 
                                                     hlp='Request confirmation for region overwrite',
                                                     width=width, relief=relief, padx=9);
      prvt.confirmMenus[idx].selectvalue(value);
      val confirmMenu := ref prvt.confirmMenus[idx];
      return T;
   }

###
   const self.name_to_string := function(const name)
   {
      x := to_upper(name);
      if (x == 'LCSLICER') {
         return 'pixel box';
      } else if (x == 'WCBOX') {
         return 'world box';   
      } else if (x == 'WCPOLYGON') {
         return 'world polygon';
      } else if (x == 'WCCOMPLEMENT') {
         return 'complement';
      } else if (x == 'WCDIFFERENCE') {
         return 'difference';
      } else if (x == 'WCEXTENSION') {
         return 'extension';
      } else if (x == 'WCCONCATENATION') {
         return 'concatenate';
      } else if (x == 'WCINTERSECTION') {
         return 'intersection';
      } else if (x == 'WCUNION') {
         return 'union';
      } else if (x == 'WCLELMASK') {
         return 'mask';
      } else {
         return 'unknown';
      }
   }

###
   const self.done := function()
   {
      wider prvt, self;
      prvt.ge.done();
      val prvt := F;
      val self := F;
#
      return T;
   }
};

