# saveregions.g: widget to save regions to a table
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
#   $Id: saveregions.g,v 19.2 2004/08/25 02:19:14 cvsmgr Exp $
#
# emits events :
#    saved 
#    dismissed
 
pragma include once

include 'regionsupport.g'
include 'widgetserver.g'
include 'regionmanager.g'
include 'serverexists.g'


const saveregions := subsequence (ref parent=F, table='',
                                  ref regions=[=],
                                  changenames=T,
                                  globalsave=F, widgetset=dws)
#
# regions       - record with regions (globalsve=F) or region names
#                 (globalsave=T)
# changenames   - If T you get the chance to rename the regions
#
{
   if (!serverexists('drm', 'regionmanager', drm)) {
      return throw ('The default regionmanager drm is either not running or not valid',
                     origin='saveregions.g');
   }
#
   prvt := [=];
   prvt.support := regionsupport(widgetset);  # Support object
   if (is_fail(prvt.support)) fail;
   prvt.globalsave := globalsave;
   prvt.changenames := changenames;
   prvt.table := table;
   prvt.tableName := '';
   prvt.regions := regions;             # All the regions passed in (just names
                                        # if globalsave=T)
   prvt.selectedRegions := [=];         # The selected regions
   prvt.nEntries := 0;                  # Number of region name entry boxes
   prvt.regionsListBox := [=];
   prvt.entryWidth := 25;
   prvt.confirm := F;


###
   const prvt.insert_regions := function (ref regions, ref regionsListBox, 
                                          globalsave)
   {
      regionsListBox->delete('start', 'end');
      nRegions := length(regions);
      if (nRegions>0) {
         stuff := array('',2, nRegions);
         if (globalsave) {
            stuff[1,] := regions;
         } else { 
            stuff[1,] := field_names(regions);
         }
         for (i in 1:nRegions) {
            if (globalsave) {
               tmp := symbol_value(stuff[1,i]);
               if (is_region(tmp)) {
                  stuff[2,i] := prvt.support.name_to_string(tmp.get('name'));
               } else {
                  msg := spaste('Region ', i, ' of name ', stuff[1,i], 
                                ' is not a valid region');
                  return throw (msg, origin='saveregions.g');
               }
            } else {
               stuff[2,i] := prvt.support.name_to_string(regions[i].get('name'));
            }
         }
#
         regionsListBox->insert(stuff);
         regionsListBox->see('start');
         regionsListBox->clear('start', 'end');
      }
      return T;
   }

###
const prvt.string_check := function (const str, const thing,
                                     single=F)
{
   if (strlen(str)==0) {
      msg := spaste('Input for "', thing, '" is empty');
      note(msg, priority='WARN', origin='saveregions.string_check');
      return F;
   }
   if (single) {
      if (length(split(str)) > 1) {
         msg := spaste('Input for "', thing, '" cannot have white space');
         note(msg, priority='WARN', origin='saveregions.string_check');
         return F;
      }
   }
   return T;
}




### Constructor

   widgetset.tk_hold();
   prvt.f0 := widgetset.frame(parent, title='Save Regions', 
                              side='top',  relief='raised', 
                              expand='both');
   prvt.f0->unmap();
   widgetset.tk_release();
#
   prvt.f0.f0 := widgetset.frame(prvt.f0, side='left', expand='x', relief='raised');
   prvt.f0.f0.file := widgetset.button(prvt.f0.f0, 'File', type='menu', relief='flat');
   prvt.f0.f0.space := widgetset.frame(prvt.f0.f0, height=1, width=10, expand='x',
                                       relief='flat');
   prvt.f0.f0.help := widgetset.helpmenu(parent=prvt.f0.f0, menuitems="Image Regionmanager",
                               refmanitems=['Refman:images.image', 'Refman:images.regionmanager'],
                               helpitems=['about Images', 'about the Regionmanager']);         
#
   helptxt := spaste('Menu of File operations:\n',
                     '- dismiss GUI (recover with function gui)\n',
                     '- destroy widget\n');
   widgetset.popuphelp(prvt.f0.f0.file, helptxt, 'File menu', combi=T);
   prvt.f0.f0.file.dismiss := widgetset.button(prvt.f0.f0.file, text='Dismiss Window',
                                               type='dismiss', relief='flat');
   prvt.f0.f0.file.done := widgetset.button(prvt.f0.f0.file, text='Done',
                                            type='dismiss', relief='flat');
#
   whenever prvt.f0.f0.file.done->press do {
     self.done();
   }
#   
   prvt.support.build_listBoxes (prvt.regionsListBox, prvt.f0, width=15);
#
   prvt.tableNameEntry := [=];
   prvt.support.create_entry(prvt.tableNameEntry, prvt.f0, 'Output table', 
                             prvt.entryWidth);
#
   if (is_string(prvt.table) && strlen(prvt.table)==0) {
# No table given yet 
   } else {
      prvt.tableName := prvt.support.getTableName(prvt.table);
      if (is_fail(prvt.tableName)) fail;
      prvt.tableNameEntry.insert(prvt.tableName);   
   }
#
   if (prvt.changenames) {
      prvt.f0.prop := widgetset.frame(prvt.f0, expand='x', 
                                      side='top', height=1);
      prvt.f0.prop.entries := widgetset.frame(prvt.f0.prop, expand='both', 
                                              side='top', height=1);
   }
   prvt.nEntries := 0;
#
   prvt.f0.action := widgetset.frame(prvt.f0, expand='x', side='left');
   prvt.f0.action.confirm := [=];
   prvt.support.create_confirm(prvt.f0.action.confirm, prvt.f0.action, width=8,
                               value=prvt.confirm)
#
   prvt.f0.action2 := widgetset.frame(prvt.f0, expand='x', side='left');
   prvt.f0.action2.saveall := widgetset.button(prvt.f0.action2, 
                                               'Save all', type='action');
   helpText := 'but with the original region names';
   widgetset.popuphelp(prvt.f0.action2.saveall, helpText, 'Save all region(s)', combi=T);
   prvt.f0.action2.save := widgetset.button(prvt.f0.action2, 'Save', type='action');
   helpText := 'honouring any region name changes';
   widgetset.popuphelp(prvt.f0.action2.save, helpText, 'Save selected region(s)', combi=T);
   prvt.f0.action2.dismiss := [=];
   prvt.support.create_dismiss(prvt.f0.action2.dismiss, prvt.f0.action2, 
                               T, -1);
#
   if (length(prvt.regions)>0) {
      prvt.f0->disable();
      ok := prvt.insert_regions(prvt.regions, 
                                prvt.regionsListBox, 
                                prvt.globalsave);
      prvt.f0->enable();
      if (is_fail(ok)) fail;
   }
#
   whenever prvt.regionsListBox->select do {
      selectedRegionsList := prvt.regionsListBox->selection();
      nSelectedRegions := length(selectedRegionsList);
#  
      if (prvt.changenames) {
         widgetset.tk_hold();
         if (prvt.nEntries != 0) {
            val prvt.f0.prop.entries := F;
            val prvt.f0.prop.entries := 
                  widgetset.frame(prvt.f0.prop, expand='both',
                                  side='top', height=1);
         }
#      
         for (i in 1:nSelectedRegions) {
            fN := spaste('entry', i);
            item := prvt.regionsListBox->get(selectedRegionsList[i])[1];
            prvt.f0.prop.entries[fN] := [=];
            prvt.support.create_entry(prvt.f0.prop.entries[fN], prvt.f0.prop.entries, 
                                      spaste(item), prvt.entryWidth);
            prvt.f0.prop.entries[fN].insert(item);
         }
         prvt.nEntries := nSelectedRegions;
         widgetset.tk_release();
      }
   }
#
   whenever prvt.f0.action2.save->press, 
            prvt.f0.action2.saveall->press do {
      confirm := prvt.f0.action.confirm.getvalue();
#
      prvt.f0.action.confirm.disabled(T);
      prvt.f0.action2.save->disable();
      prvt.f0.action2.saveall->disable();
      prvt.f0.action2.dismiss->disable();
#
      selectedRegionsList := [];
      doAll := F;
      done := F;
      if ($agent == prvt.f0.action2.saveall) {
         if (length(prvt.regions)>0) {
            selectedRegionsList := (1:length(prvt.regions)) - 1;
            doAll := T;
         }
      } else {
         selectedRegionsList := prvt.regionsListBox->selection();
      }
#
      nSelectedRegions := length(selectedRegionsList);
      if (doAll &&  prvt.nEntries>0) {
         note('Original region names will be used',
              priority='WARN', origin='saveregions.g');
      }
      if (nSelectedRegions==0) {
         note ('You have not selected any regions', priority='WARN',
               origin='saveregions.g');
      } else {
         prvt.table := prvt.tableNameEntry.get();
         if (!is_illegal(prvt.table) && 
             prvt.string_check(prvt.table, 'Output table', T)) {
            prvt.tableName := prvt.support.getTableName(prvt.table);
            if (is_fail(prvt.tableName)) {
               msg := prvt.tableName::message;
               note (msg, priority='SEVERE', origin='saveregions.g');
            } else {
               regionNames := "";
               regions := [=];
               if (prvt.globalsave) {
                  for (i in 1:nSelectedRegions) { 
                     if (doAll) {
                        regions[i] := symbol_value(prvt.regions[i]);
                        regionNames[i] := prvt.regions[i];
                     } else {
                        item := 
                           prvt.regionsListBox->get(selectedRegionsList[i])[1];
                        if (prvt.changenames) {
                           fN := spaste('entry', i);
                           regionNames[i] := 
                              prvt.f0.prop.entries[fN].get();
                        } else {
                           regionNames[i] := item;
                        }
                        regions[i] := symbol_value(item);
                     }
                  }
               } else {
                  fieldnames := field_names(prvt.regions);
                  for (i in 1:nSelectedRegions) {
                     if (doAll) {
                        regions[i] := prvt.regions[i];
                        regionNames[i] := fieldnames[i];
                     } else {
                        if (prvt.changenames) {
                           fN := spaste('entry', i);
                           regionNames[i] := 
                              prvt.f0.prop.entries[fN].get();
                        } else {
                           regionNames[i] := fieldnames[selectedRegionsList[i]+1];
                        }
                        regions[i] := prvt.regions[selectedRegionsList[i]+1];
                     }
                  }
               }
#
# Do it
#
               drm.fromrecordtotable(prvt.tableName, confirm, T,
                                     regionNames, regions);
               done := T;
            }
         }
      }
#
      prvt.f0.action2.save->enable();
      prvt.f0.action2.saveall->enable();
      prvt.f0.action2.dismiss->enable();
      prvt.f0.action.confirm.disabled(F);
#
      if (done) {
         self->saved();
         prvt.f0->unmap();
         self->dismissed();
      }
   }
   whenever prvt.f0.action2.dismiss->press,prvt.f0.f0.file.dismiss->press do {
      prvt.f0->unmap();
      self->dismissed();
   }
   prvt.f0->map();


### Public functions

   const self.done := function() 
   {
       wider prvt, self;
       prvt.f0->unmap();
       val prvt := F;
       val self := F;
       return T;
    }

###
   const self.gui := function() 
   {
      prvt.f0->map();
      return T;
   }

###
   const self.setregions := function (ref regions)
   {
      wider prvt;
      prvt.regions := regions;
#
      prvt.f0->disable();
      ok := prvt.insert_regions(prvt.regions, 
                                prvt.regionsListBox, 
                                prvt.globalsave);
      prvt.f0->enable();
      if (is_fail(ok)) fail;
#
      if (prvt.changenames) {
         if (prvt.nEntries != 0) {
            widgetset.tk_hold();
            val prvt.f0.prop.entries := F;
            val prvt.f0.prop.entries := 
                  widgetset.frame(prvt.f0.prop, expand='both',
                                  side='top', height=1);
            widgetset.tk_release();
         }

      }
      return T;
   }

###
   const self.settable := function (table)
   {
      wider prvt;
      prvt.table := table;
      prvt.tableName := prvt.support.getTableName(prvt.table);
      prvt.tableNameEntry.insert(prvt.tableName);
      return T;
   }
}     
