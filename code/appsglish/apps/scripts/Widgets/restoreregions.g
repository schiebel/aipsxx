# restoreregions.g: widget to restore regions from a table
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
#   $Id: restoreregions.g,v 19.2 2004/08/25 02:18:34 cvsmgr Exp $
#
# emits events :
#    restored 
#    dismissed
 
pragma include once

include 'regionsupport.g'
include 'serverexists.g'
include 'regionsupport.g'
include 'widgetserver.g'

const restoreregions := subsequence (ref parent=F, table='', 
                                     changenames=T,
                                     globalrestore=F,
                                     widgetset=dws)
#
# table         - If specified start off showing the regions from this table
# changenames   - If T then you get the chance to change the region names
# globalrestore - If true, the regions are made global with a confirm
#                 optionmenu.   Otherwise, they are only available
#                 via method self.regions in a record
#
{
   prvt := [=];
   prvt.support := regionsupport(widgetset);  # Support object
   if (is_fail(prvt.support)) fail;
   prvt.table := ref table;             # This is what the user gives us. It might be
                                        # an image, table, table name, or image/table
                                        # symbol name.
   prvt.tableName := '';                # The name of the underlying table
   prvt.regions := [=];                 # All the regions in the table
   prvt.selectedRegions := [=];         # The selected regions
   prvt.nEntries := 0;
   prvt.regionsListBox := [=];
   prvt.entryWidth := 25;
   prvt.confirm := F;
   prvt.globalrestore := globalrestore;
   prvt.changenames := changenames;

### Constructor

   widgetset.tk_hold();
   prvt.f0 := widgetset.frame(parent, title='Restore Regions', 
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
                     '- destroy widget');
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
   helptxt1 := 'Enter new table';
   helptxt2 := spaste('and hit <CR> to see the regions\n',
                     'stored in this table');
   prvt.tableNameEntry := [=];
   prvt.support.create_entry(prvt.tableNameEntry, prvt.f0, 'Input table', 
                             prvt.entryWidth, helptxt1, helptxt2);
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
   prvt.f0.action := widgetset.frame(prvt.f0, expand='x', side='left');
   prvt.f0.action.confirm := [=];
   prvt.support.create_confirm(prvt.f0.action.confirm, prvt.f0.action, 
                               width=8, value=prvt.confirm)
#
   prvt.f0.action2 := widgetset.frame(prvt.f0, expand='x', side='left');
   prvt.f0.action2.restoreall := widgetset.button(prvt.f0.action2, 
                                                  'Restore all', type='action');
   widgetset.popuphelp(prvt.f0.action2.restoreall, 'Restore all region(s)');
   prvt.f0.action2.restore := widgetset.button(prvt.f0.action2, 'Restore', 
                                               type='action');
   widgetset.popuphelp(prvt.f0.action2.restore, 'Restore selected region(s)');
   prvt.f0.action2.dismiss := [=];
   prvt.support.create_dismiss(prvt.f0.action2.dismiss, prvt.f0.action2, T, -1);
#
   prvt.regions := [=];
   if (strlen(prvt.tableName)>0) {
      prvt.f0->disable();
      ok := prvt.support.insert_regions(prvt.regions, prvt.tableName,
                                        prvt.regionsListBox, T);
      prvt.f0->enable();
   }
#
   whenever prvt.tableNameEntry->value do {
      item := prvt.tableNameEntry.get();       
      if (!is_illegal(item)) {
         ok := self.settable (item)
         if (is_fail(ok)) {
           note (spaste('Failed to set new table because ', ok::message),
                 priority='WARN', origin='restoreregions.g');
         }
      }
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
   whenever prvt.f0.action2.restore->press, 
            prvt.f0.action2.restoreall->press do {
      confirm := prvt.f0.action.confirm.getvalue();
#
      prvt.f0.action.confirm.disabled(T);
      prvt.f0.action2.restore->disable();
      prvt.f0.action2.restoreall->disable();
      prvt.f0.action2.dismiss->disable();
#
      selectedRegionsList := [];
      doAll := F;
      done := F;
      if ($agent == prvt.f0.action2.restoreall) {
         if (length(prvt.regions)>0) {
            selectedRegionsList := (1:length(prvt.regions)) - 1;
         }
         doAll := T;
      } else {
         selectedRegionsList := prvt.regionsListBox->selection();
      }
#
      nSelectedRegions := length(selectedRegionsList);
      if (nSelectedRegions==0) {
         note ('You have not selected any regions', priority='WARN',
               origin='restoreregions.g');
      } else {
         if (doAll && prvt.nEntries>0) {
            note('Original region names will be used',
                 priority='WARN', origin='restoreregions.g');
         }
         if (prvt.globalrestore) {
            for (i in 1:nSelectedRegions) {
               nameOrig := prvt.regionsListBox->get(selectedRegionsList[i])[1];
               nameNew := nameOrig;
               if (prvt.changenames) {
                  if (!doAll) {
                     fN := spaste('entry', i);
                     nameNew := prvt.f0.prop.entries[fN].get();
                  }
               }
               local doIt;
               prvt.support.isRegion_defined (nameNew, doIt, nameOrig, 
                                              confirm);
               if (doIt) {
                  global __restoreregions_region := prvt.regions[nameOrig];
                  command := spaste(nameNew, ' := __restoreregions_region');
                  ff := eval(command);
               }
            }
         } else {
            prvt.selectedRegions := [=];
            for (i in 1:nSelectedRegions) {
               nameOrig := prvt.regionsListBox->get(selectedRegionsList[i])[1];
               nameNew := nameOrig;
               if (prvt.changenames) {
                  if (!doAll) {
                     fN := spaste('entry', i);
                     nameNew := prvt.f0.prop.entries[fN].get();
                  }
               }
               prvt.selectedRegions[nameNew] := prvt.regions[nameOrig];
            }
         }
         done := T;
      }
      prvt.f0.action2.restore->enable();
      prvt.f0.action2.restoreall->enable();
      prvt.f0.action2.dismiss->enable();
      if (prvt.globalrestore) prvt.f0.action.confirm.disabled(F);
#
      if (done) {
         self->restored();
         prvt.f0->unmap();
         self->dismissed();
      }
   }
   whenever prvt.f0.action2.dismiss->press, prvt.f0.f0.file.dismiss->press do {
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
   const self.refresh := function ()
   {
      return self.settable(prvt.tableName);
   }


###
   const self.regions := function ()
   {
      if (prvt.globalrestore) {
         note ('You are using global restore mode, so this function returns nothing',
               priority='WARN', origin='restoreregions.selectedregions');
         return [=];
      } else {
         return prvt.selectedRegions;
      }
   }

###
   const self.settable := function (table)
#
# table could be a string or image object or table object
#
   {
      wider prvt;
      if (is_string(table)) {
         if (strlen(table)==0) {
            prvt.regionsListBox->delete('start', 'end');
            prvt.regions := [=];
            prvt.table := [=];
            prvt.tablename := '';
            return T;
         }
      }
#
      name := prvt.support.getTableName(table);
      if (is_fail(name)) fail;
#
      prvt.table := table;         
      prvt.tableName := name;
      prvt.selectedRegions := [=];
#
      prvt.tableNameEntry.insert(prvt.tableName);
      if (prvt.globalrestore) {
         if (prvt.nEntries != 0) {
            widgetset.tk_hold();
            val prvt.f0.prop.entries := F;
            val prvt.f0.prop.entries := 
                widgetset.frame(prvt.f0.prop, expand='both', 
                                side='top', height=1);
            widgetset.tk_release();
         }
      }
#
      prvt.f0->disable();
      ok := prvt.support.insert_regions(prvt.regions, prvt.tableName,
                                        prvt.regionsListBox, T);
      prvt.f0->enable();
      return T;
   }
}

