# deleteregions.g: widget to delete regions from a table or record or global name space
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
#   $Id: deleteregions.g,v 19.2 2004/08/25 02:12:52 cvsmgr Exp $
#
# emits events :
#    deleted
#    dismissed
 
pragma include once

include 'regionsupport.g'
include 'widgetserver.g'
include 'regionmanager.g'
include 'serverexists.g'
include 'misc.g'
include 'helpmenu.g'

const deleteregions := subsequence (ref parent=F, table='', ref regions="",
                                    source='table', widgetset=dws)
{
   if (!serverexists('drm', 'regionmanager', drm)) {
      return throw ('The default regionmanager drm is either not running or not valid',
                     origin='deleteregions.g');
   }
   if (!serverexists('dms', 'misc', dms)) { 
      return throw('The misc server "dms" is either not running or not valid',
                    origin='deleteregions.g');
   }
   if (source!='table' && source!='global' && source!='record') {
      return throw ('Value of argument "source" must be one of "table", "global" or "record"', 
                    origin='deleteregions.g');
   }
#
   prvt := [=];
   prvt.support := regionsupport(widgetset);  # Support object
   if (is_fail(prvt.support)) fail;
   prvt.table := ref table;             # This is what the user gives us. It might be
                                        # an image, table, table name, or image/table
                                        # symbol name.
   prvt.tableName := '';                # The name of the underlying table
   prvt.nEntries := 0;
   prvt.regionsListBox := [=];
   prvt.entryWidth := 25;
   prvt.confirmValue := F;
#
   prvt.source := source;               # Where do the regions come from ? One of
                                        # 'table', 'record', 'global'
   prvt.regions := [=];                 # All the potential region objects to  delete
   prvt.regionNames := "";              # All the potential region object names to  delete


###
   prvt.confirm := function(name)
   {
      deleteIt := T;
      okinc := eval('include \'choice.g\'');
      if (is_fail(okinc)) {
         msg := paste('Failed to include "choice.g"');
         return throw (msg, origin='deleteregions.g');
      }
      msg := spaste('Delete the region "', name, '" ?');
      ok := choice(msg, "yes no");
      if (ok=='no') {
         msg := spaste('Region ', name, ' spared execution');
         note (msg, priority='WARN', origin='deleteregions.g');
         deleteIt := F;
      }
      return deleteIt;
   }


###
   prvt.deletefromrecord := function (ref regions, ref regionNames, deleteNames,
                                      confirmList)
   {
      r2 := [=];
      rN2 := "";
      const n := length(deleteNames);
      k := 0;
      for (i in 1:length(regions)) {
         found := F;
         for (j in 1:n) {
            if (confirmList[j] && deleteNames[j]==regionNames[i]) {
               found := T;
               break;
            }
         }
         if (!found) {
           k +:= 1;
           r2[regionNames[i]] := regions[i];
           rN2[k] := regionNames[i];
         }
      }
#
      val regions := r2;
      val regionNames := rN2;
   }

###
   const prvt.getglobalregions := function (ref regions, ref regionNames)
   {
      wider prvt;
      val regions := [=];
#
      for (i in 1:length(regionNames)) {
         if (!is_defined(regionNames[i])) {
            msg := spaste('The string ', regionNames[i], ' is not defined as a symbol');
            note(msg, priority='WARN', origin='deleteglobalregions.g');
         } else {
            regions[regionNames[i]] := symbol_value(regionNames[i]);
            if (!is_region(regions[regionNames[i]])) {
               msg := spaste('The symbol ', regionNames[i], ' is not a valid region');
               note(msg, priority='WARN', origin='deleteregions.g');
            }
         }
      }
   }

###
   const prvt.updatelistboxes := function (ref regionsListBox, confirm)
   {
      selectedRegionsList := regionsListBox->selection();
      idx := spaste(selectedRegionsList[1]);
      if (confirm) {
         regionsListBox->delete(as_string(idx));
      } else {
         regionsListBox->clear(as_string(idx));
      }
      return T;
   }



### Constructor

   widgetset.tk_hold();
   prvt.f0 := widgetset.frame(parent, title='Delete Regions', 
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
   if (prvt.source=='table') {
      prvt.tableNameEntry := [=];
      helptxt1 := 'Enter new table';
      helptxt2 := spaste('and hit <CR> to see the regions\n',
                         'stored in this table');
      prvt.support.create_entry(prvt.tableNameEntry, prvt.f0, 'Input table', 
                                prvt.entryWidth, helptxt1, helptxt2);
      if (is_string(prvt.table) && strlen(prvt.table)==0) {
# No table given yet
      } else {
         prvt.tableName := prvt.support.getTableName(prvt.table);
         if (is_fail(prvt.tableName)) fail;
         prvt.tableNameEntry.insert(prvt.tableName);
      }
#
      whenever prvt.tableNameEntry->value do {
         item := prvt.tableNameEntry.get();       
         if (!is_illegal(item)) {
            ok := self.settable (item)
            if (is_fail(ok)) {
               note (spaste('Failed to set new table because ', ok::message),
                     priority='WARN', origin='deleteregions.g');
            }
         }
      }
   }
#
   prvt.f0.action := widgetset.frame(prvt.f0, expand='x', side='left');
   prvt.f0.action.confirm := [=];
   prvt.support.create_confirm(prvt.f0.action.confirm, parent=prvt.f0.action, 
                               width=9, value=prvt.confirmValue)
   prvt.f0.action.deselect := widgetset.button(prvt.f0.action, 'Deselect',
                                               width=9, type='action');
   widgetset.popuphelp(prvt.f0.action.deselect, 'Deselect all regions');
   prvt.nEntries := 0;
#
   prvt.f0.action2 := widgetset.frame(prvt.f0, expand='x', side='left');
   prvt.f0.action2.deleteall := widgetset.button(prvt.f0.action2,  'Delete all', 
                                                 width=9, type='action');
   widgetset.popuphelp(prvt.f0.action2.deleteall, 'Delete all region(s)');
   prvt.f0.action2.delete := widgetset.button(prvt.f0.action2, 'Delete',
                                              type='action', width=9);
   widgetset.popuphelp(prvt.f0.action2.delete, 'Delete selected region(s)');
   prvt.f0.action2.dismiss := [=];
   prvt.support.create_dismiss(prvt.f0.action2.dismiss, prvt.f0.action2, 
                               T, -1);
#
   if (prvt.source=='global') {
      prvt.regionNames := dms.tovector(regions, 'string');
      prvt.getglobalregions(prvt.regions, prvt.regionNames);
   } else if (prvt.source=='record') {
      prvt.regions := ref regions;                   # Important ref
      prvt.regionNames := field_names(prvt.regions);
   }
#
# Insert the regions into the list boxes, either from the
# table or the record
#
   prvt.f0->disable();
   doit := T;
   fromTable := F;
   if (prvt.source=='table') {
      fromTable := T;
      if (is_string(prvt.table) && strlen(prvt.table)==0) doit := F;
   }
   if (doit) {
      ok := prvt.support.insert_regions(prvt.regions, prvt.table,
                                        prvt.regionsListBox, 
                                        fromTable);
      if (is_fail(ok)) {
         note (ok::message, priority='SEVERE', 'origin=deleteregions.g');
      }
   }
   prvt.f0->enable();
   if (prvt.source=='table') {
      prvt.regionNames := field_names(prvt.regions);
   }
#
   whenever prvt.f0.action.deselect->press do {
      prvt.regionsListBox->clear('start', 'end');
   }
   whenever prvt.f0.action2.delete->press, 
            prvt.f0.action2.deleteall->press do {
      confirm := prvt.f0.action.confirm.getvalue();
      prvt.f0.action2.delete->disable();
      prvt.f0.action2.deleteall->disable();
      prvt.f0.action.confirm.disabled(T);
      prvt.f0.action2.dismiss->disable();
      selectedRegionsList := [];
#
      done := F;
      deleteAll := F;
      if ($agent == prvt.f0.action2.deleteall) {
         selectedRegionsList := [1:length(prvt.regions)] - 1;     # 0 rel
         nSelectedRegions := length(selectedRegionsList);
         prvt.regionsListBox->select('start', 'end');
         deleteAll := T;
      } else {
         selectedRegionsList := prvt.regionsListBox->selection();
         nSelectedRegions := length(selectedRegionsList);
      }
      if (nSelectedRegions==0) {
         note ('You have not selected any regions', priority='WARN',
               origin='deleteregions.g');
      } else {
#
# Get the names of the regions we want to delete
#
         deleteRegions := "";
         for (i in 1:nSelectedRegions) {
            deleteRegions[i] := prvt.regionsListBox->get(selectedRegionsList[i])[1];
         }
#
         confirmList := array(T, length(deleteRegions));
         if (confirm) {
            if (source=='table') {
               confirmList := drm.deletefromtable(prvt.tableName, 
                                                  confirm=confirm, 
                                                  regionname=deleteRegions);
               for (i in 1:nSelectedRegions) {
                  prvt.updatelistboxes(prvt.regionsListBox, confirmList[i]);
               }
            } else if (source=='global') {
               for (i in 1:nSelectedRegions) {
                  if (prvt.confirm(deleteRegions[i])) {
                     symbol_delete(deleteRegions[i]);
                  } else {
                     confirmList[i] := F;              
                  }
                  prvt.updatelistboxes(prvt.regionsListBox, confirmList[i]);
               }
            } else if (source=='record') {
               for (i in 1:nSelectedRegions) {
                  if (!prvt.confirm(deleteRegions[i])) confirmList[i] := F;              
                  prvt.updatelistboxes(prvt.regionsListBox, confirmList[i]);
               }
            }
         } else {
            if (source=='table') {
               confirmList := drm.deletefromtable(prvt.tableName, confirm=F, 
                                                  regionname=deleteRegions);
               for (i in 1:nSelectedRegions) {
                  prvt.updatelistboxes(prvt.regionsListBox, T);
               }
            } else if (source=='global') {
               for (i in 1:nSelectedRegions) {
                  symbol_delete(deleteRegions[i]);
                  prvt.updatelistboxes(prvt.regionsListBox, T);
               }
            } else if (source=='record') {
               for (i in 1:nSelectedRegions) {
                  prvt.updatelistboxes(prvt.regionsListBox, T);
               }
            }
         }
#
# Delete from internal record
#
         prvt.deletefromrecord(prvt.regions, prvt.regionNames, deleteRegions,
                               confirmList);
#
# Clear selections
#
         prvt.regionsListBox->clear('start', 'end');
         done := T;
      }
#
      prvt.f0.action2.delete->enable();
      prvt.f0.action2.deleteall->enable();
      prvt.f0.action.confirm.disabled(F);
      prvt.f0.action2.dismiss->enable();
#
      if (done) {
         prvt.f0->unmap();
         self->deleted();
         self->dismissed();
      }
   }
#
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
   const self.refresh := function ()
   {
      if (prvt.source=='table') {
         return self.settable(prvt.tableName);
      } else {
         regionsListBox->clear('start', 'end');
      }
      return T;
   }

###
   const self.setregions := function (ref regions)
   {
      wider prvt;
      if (is_record(regions)) {
         if (prvt.source != 'record') {
            msg := spaste('The source for this widget is "', prvt.source, 
                          '" not "record"');
            note(msg, priority='WARN', origin='deleteregions.g');
            return F;
         }
#
         prvt.regions := ref regions;
         prvt.regionNames := field_names(prvt.regions);
      } else if (is_string(regions)) {
         if (prvt.source != 'global') {
            msg := spaste('The source for this widget is "', prvt.source, 
                          '" not "global"');
            note(msg, priority='WARN', origin='deleteregions.g');
            return F;
         }
#
         prvt.regionNames := regions;
         prvt.getglobalregions(prvt.regions, prvt.regionNames);
      } else {
         msg := spaste('Unrecognized type of regions variable. Must be record or string');
         note(msg, priority='WARN', origin='deleteregions.g');
         return F;
      }
#
# Insert the regions into the list boxes, either from the
# table or the record
#
      prvt.f0->disable();
      fromTable := F;
      if (prvt.source=='table') fromTable := T;
      ok := prvt.support.insert_regions(prvt.regions, prvt.table,
                                        prvt.regionsListBox, 
                                        fromTable);
      prvt.f0->enable();
      return T;
   }


###
   const self.settable := function (table)
#
# table could be a string or image object or table object
#
   {
      wider prvt;
      if (prvt.source != 'table') {
         msg := spaste('The source for this widget is "', prvt.source, 
                      '" not "table"');
         note(msg, priority='WARN', origin='deleteregions.g');
         return F;
      }
#
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
      prvt.tableNameEntry.insert(prvt.tableName);
#
      prvt.f0->disable();
      prvt.regions := [=];
      ok := prvt.support.insert_regions(prvt.regions, prvt.tableName,
                                        prvt.regionsListBox, T);
      prvt.regionNames := field_names(prvt.regions);
      prvt.f0->enable();
      return T;
   }
}
