# regionmanagergui.g: Access to regionmanager using a gui
# Copyright (C) 1998,1999,2000,2001,2002
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
#
# This file is not meant to be included independently. regionmanager.g 
# will include it if and when necessary.
#
# Emits events
#   dismissed     when the gui is dismissed
#   sent          when the send button is pressed
#
# $Id: regionmanagergui.g,v 19.2 2004/08/25 01:01:01 cvsmgr Exp $


pragma include once

include 'helpmenu.g'
include 'coordsyssupport.g'
include 'coordsys.g'
include 'image.g'
include 'quanta.g'
include 'choice.g'
include 'serverexists.g'
include 'regionsupport.g'
include 'clipboard.g'
include 'widgetserver.g'
include 'scripter.g'



const regionmanagergui := subsequence (widgetset=dws, ref which)
{
   if (!have_gui()) {
      return throw('No Gui is available, possibly the  DISPLAY environment variable is not set',
                   origin='regionmanagergui.g');
   }
   if (!serverexists('dq', 'quanta', dq)) {
      return throw('The quanta server "dq" is either not running or not valid',
                    origin='regionmanagergui.g');
   }
   if (!serverexists('dcb', 'clipboard', dcb)) {
      return throw('The clipboard server "dcb" is either not running or not valid',
                    origin='regionmanagergui.g');
   }
#
   qrec := [=];
   global __regionmanager_rm := ref which;      # A global reference to who called us
   qrec.support := regionsupport(widgetset);    # Support object
   qrec.ge := widgetset.guientry(expand='x');
#
   private := [=];
   private.scripter := scripter();
   if (is_fail(private.scripter)) fail;
#
   grec := [=];                          # main control panel
   grec.built := F;   
   grec.hidden := F;
   grec.entryWidth := 20;
   grec.entryWidth2 := 35;
   grec.buttonWidth := 7;
   grec.actionBorderWidth := 2;
   grec.confirm := T;
   grec.region_helps := "";
#
   grec.format := [=];                   # Formatting lists
   grec.format.Direction := [=];
   grec.format.Spectral := [=];
   grec.format.Linear := [=];
   grec.format.Stokes := [=];
   grec.format.Unknown := [=];
#
   grec.format.Direction.list := ["deg arcsec arcmin rad pix frac"];
   grec.format.Direction.width := 5;
#   grec.format.Spectral.list := ["GHz MHz Hz km/s m/s pix frac"];
   grec.format.Spectral.list := ["GHz MHz Hz pix frac"];              # No conversions yet to km/s
   grec.format.Spectral.width := 4;
   grec.format.Stokes.list := ["pix frac"];
   grec.format.Stokes.width := 4;
   grec.format.Linear.list := ["pix frac"];
   grec.format.Linear.width := 4;
   grec.format.Unknown.list := ["pix frac"];
   grec.format.Unknown.width := 4;
#
   hrec := [=];                           # creation panels (how many days was that ?)
#
   irec := [=];                           # save entry box values from last time
   irec.union := [=];                     # for compound regions edit recovery
   irec.compl := [=];
   irec.diff := [=];
   irec.int := [=];
   irec.ext := [=];
   irec.concat := [=];
#
   jrec := [=];                           # values of global symbols made with eval
#
   krec := [=];                           # whenever lists that get activated/deactivated
   krec.save := [];
   krec.restore := [];
   krec.delete := [];
   krec.interactive := [=];               # Field names are image ids
#
   lrec := [=];                           # Regions last deleted
# 


const self.gui := function(parent=F, tlead=F, tpos='sw')
{
#
# Main frame
#
   wider grec;
   wider hrec;
   wider irec;
   wider krec;
   wider lrec;
   if (grec.built == T) {
      grec.f0->map();
      return T;
   }
   grec.built := T;
#
   widgetset.tk_hold();
   grec.f0 := widgetset.frame(parent=parent, title='regionmanager',side='top', 
                              relief='flat', expand='both', tlead=tlead, tpos=tpos);
   grec.f0->unmap();
   widgetset.tk_release();
#
# Main menu items
#
   grec.f0.f0 := widgetset.frame(grec.f0, side='left', expand='x', relief='raised');
   grec.f0.f0.file := widgetset.button(grec.f0.f0, 'File', type='menu', relief='flat');
   grec.f0.f0.space := widgetset.frame(grec.f0.f0, height=1, width=10, expand='x', 
                                       relief='flat');
   grec.f0.f0.help := widgetset.helpmenu(parent=grec.f0.f0, menuitems="Image Regionmanager",
                               refmanitems=['Refman:images.image','Refman:images.regionmanager'],
                               helpitems=['about Images', 'about the Regionmanager']);
#
   helptxt := spaste('Menu of File operations:\n',
                     '- show scripter\n',
                     '- save regions to a table\n',
                     '- restore regions from a table\n',
                     '- delete regions from a table\n\n',
                     '- dismiss all regionmanager windows, preserving state (recover with function gui)\n',
                     '- destroy all regionmanager windows, destroying state (recover with function gui)\n');
   widgetset.popuphelp(grec.f0.f0.file, helptxt, 'File menu', combi=T);
#
# Menu for "file" button
#
   grec.f0.f0.file.scripter := widgetset.button(grec.f0.f0.file, text='Show scripter', relief='flat');
   whenever grec.f0.f0.file.scripter->press do {
      private.scripter.gui();
   }
#
   grec.f0.f0.file.save := widgetset.button(grec.f0.f0.file, text='Save', relief='flat');
   grec.f0.f0.file.restore := widgetset.button(grec.f0.f0.file, text='Restore', relief='flat');
   grec.f0.f0.file.delete := widgetset.button(grec.f0.f0.file, text='Delete', relief='flat');
   grec.f0.f0.file.spacer := widgetset.button(grec.f0.f0.file, text='-------', relief='flat', 
                                        disabled=T, pady=0, foreground='lightgrey');
   grec.f0.f0.file.dismiss := widgetset.button(grec.f0.f0.file, text='Dismiss Window', type='dismiss',
                                         relief='flat');
   grec.f0.f0.file.close := widgetset.button(grec.f0.f0.file, text='Done', type='halt',
                                             relief='flat');
#
   whenever grec.f0.f0.file.close->press do {
     self->closed();
     self.done(F);
   }
#
# Frame to hold boxes for 1) available region types for creation, 2) available 
# images and 3) available regions 
#
   grec.f0.f1 := widgetset.frame(grec.f0, side='left', 
                                 expand='both', relief='flat');
#
# Selection box for the different sorts of regions that can be created
#
   grec.f0.f1.types := widgetset.frame(grec.f0.f1, side='top', 
                                       expand='both', relief='raised');
   grec.f0.f1.types.f0 := widgetset.frame(grec.f0.f1.types, side='top', 
                                          expand='both', relief='flat');
   grec.f0.f1.types.f0.label := widgetset.label(grec.f0.f1.types.f0, 
                                                'Region Types');
   grec.f0.f1.types.f0.f0 := widgetset.frame(grec.f0.f1.types.f0, side='left', 
                                             expand='both', relief='flat');
   grec.f0.f1.types.f0.f0.f0 := widgetset.frame(grec.f0.f1.types.f0.f0, 
                                                side='top', expand='both', 
                                                relief='flat');
   grec.f0.f1.types.f0.f0.f0.lb := widgetset.scrolllistbox(grec.f0.f1.types.f0.f0.f0, height=8, 
                                                           width=13, mode='single', fill='both');
#
   grec.typesListBox := ref grec.f0.f1.types.f0.f0.f0.lb;    # Copy for convenience
#
   widgetset.popuphelp(grec.typesListBox.listbox(), private.regions_type_help);
   helptxt := spaste('These are the different sorts of\n',
                     'regions that you can create.\n',
                     'Select one of them\n');
   widgetset.popuphelp(grec.f0.f1.types.f0.label, helptxt, 
                      'Region types that can be created', combi=T);
#
# Selection box for the available images
#
   grec.f0.f1.images := widgetset.frame(grec.f0.f1, side='top', 
                                  expand='both', relief='raised');
   grec.f0.f1.images.f0 := widgetset.frame(grec.f0.f1.images, side='top', 
                                     expand='both', relief='flat');
   grec.f0.f1.images.f0.label := widgetset.label(grec.f0.f1.images.f0, 'Images');
#
   grec.f0.f1.images.f0.f0 := widgetset.frame(grec.f0.f1.images.f0, side='left', 
                                        expand='both', relief='flat');
   grec.f0.f1.images.f0.f0.f0 := widgetset.frame(grec.f0.f1.images.f0.f0, side='top', 
                                           expand='both', relief='flat');
   grec.f0.f1.images.f0.f0.f0.lb := widgetset.scrolllistbox(grec.f0.f1.images.f0.f0.f0, height=8, 
                                                            width=16, mode='single', fill='both');
#
   grec.imagesListBox := ref grec.f0.f1.images.f0.f0.f0.lb;  # Copy for convenience
#
   helptxt := spaste('These are the Glish image\n',
                     'objects that you have created.\n',
                     'Select an image object before\n',
                     'trying to create a world region\n');
   widgetset.popuphelp(grec.f0.f1.images.f0.label, helptxt, 
             'Image objects that are available', combi=T);
#
# Button to deselect images 
#
   grec.f0.f1.images.f1 := widgetset.frame(grec.f0.f1.images, side='left', expand='x', 
                                     relief='flat');
   grec.f0.f1.images.f1.deselect := widgetset.button(grec.f0.f1.images.f1, text='Deselect');
   widgetset.popuphelp(grec.f0.f1.images.f1.deselect, 'Deselect all images');
#
   whenever grec.f0.f1.images.f1.deselect->press do {
      grec.imagesListBox->clear('start', 'end');
   }
#
# Selection box for the available regions
#
   grec.regionsListBox := [=];
   grec.f0.f1.regions := widgetset.frame(grec.f0.f1, side='top', expand='both',
                                         relief='flat');
   qrec.support.build_listBoxes (grec.regionsListBox, 
                                 grec.f0.f1.regions);
#
# Deferred until now so we have the list box references 
#
   private.build_regions (jrec, irec, hrec, grec.typesListBox ,
                          grec.imagesListBox, grec.regionsListBox);
#
   whenever grec.f0.f0.file.save->press do {
      private.save_regions(krec, hrec, grec.imagesListBox, 
                           grec.regionsListBox);
   }
   whenever grec.f0.f0.file.restore->press do {
      private.restore_regions(krec, hrec, grec.imagesListBox, 
                              grec.regionsListBox);
   }
   whenever grec.f0.f0.file.delete->press do {
      private.tabledelete_regions(krec, hrec, grec.imagesListBox, 
                                  grec.regionsListBox);
   }
#
# Buttons to manipulate regions
#
   grec.f0.f1.regions.f1 := widgetset.frame(grec.f0.f1.regions, side='left', expand='x', 
                                            relief='flat');
   grec.f0.f1.regions.f1.delete := widgetset.button(grec.f0.f1.regions.f1, 'Delete', 
                                             width=grec.buttonWidth);
   widgetset.popuphelp(grec.f0.f1.regions.f1.delete, 'Delete selected regions');
   grec.f0.f1.regions.f1.undelete := widgetset.button(grec.f0.f1.regions.f1, 'Undelete', 
                                               width=grec.buttonWidth);
   widgetset.popuphelp(grec.f0.f1.regions.f1.undelete, 'Undelete last deleted regions');
   grec.f0.f1.regions.f1.edit := widgetset.button(grec.f0.f1.regions.f1, 'Edit', 
                                           width=grec.buttonWidth);
   widgetset.popuphelp(grec.f0.f1.regions.f1.edit, 'Edit selected region');
   grec.f0.f1.regions.f2 := widgetset.frame(grec.f0.f1.regions, side='left', expand='x', 
                                      relief='flat');
   grec.f0.f1.regions.f2.copy := widgetset.button(grec.f0.f1.regions.f2, 'Copy', 
                                           width=grec.buttonWidth);
   widgetset.popuphelp(grec.f0.f1.regions.f2.copy, 'Copy selected region');
   grec.f0.f1.regions.f2.rename := widgetset.button(grec.f0.f1.regions.f2, 'Rename', 
                                             width=grec.buttonWidth);
   widgetset.popuphelp(grec.f0.f1.regions.f2.rename, 'Rename selected region');
   grec.f0.f1.regions.f2.clipboard := widgetset.actionoptionmenu(parent=grec.f0.f1.regions.f2,
                                            labels="Copy Paste", hlp='Copy to and paste from clipboard',
                                            updatelabel=F, width=grec.buttonWidth, padx=9, pady=4);
   grec.f0.f1.regions.f2.clipboard.setlabel('Clipboard');
   grec.f0.f1.regions.f2.f0 := widgetset.frame(grec.f0.f1.regions.f2, side='left', 
                                         expand='x', width=5, height=1, relief='flat');
# 
   whenever grec.f0.f1.regions.f1.edit->press do {
      private.edit_regions (jrec, irec, hrec, grec.imagesListBox, grec.regionsListBox);
   }
#
   whenever grec.f0.f1.regions.f2.copy->press do {
      private.copy_regions (hrec, grec.regionsListBox);
   }
   whenever grec.f0.f1.regions.f2.rename->press do {
      private.rename_regions (hrec, grec.regionsListBox);
   }
   whenever grec.f0.f1.regions.f2.clipboard->select do {
      if ($value.label=='Copy') {
         private.copy_to_clipboard(hrec, grec.regionsListBox);
      } else if ($value.label=='Paste') {
         private.paste_from_clipboard(hrec, grec.regionsListBox);
      }
   }
#
   whenever  grec.f0.f1.regions.f1.delete->press do {
      private.delete_regions (lrec, grec.regionsListBox);
   }
   whenever grec.f0.f1.regions.f1.undelete->press do {
      private.undelete_regions (lrec, hrec, grec.regionsListBox);
   }
#
# Update button
#
   grec.f0.f2 := widgetset.frame(grec.f0, side='left', expand='x', relief='flat');
   grec.f0.f2.update := widgetset.button(grec.f0.f2, 'Refresh');
   widgetset.popuphelp(grec.f0.f2.update, 'Refresh list of available images and regions');
   grec.f0.f2.space := widgetset.frame(grec.f0.f2, height=1, expand='x');
#
   grec.f0.f2.senddismiss := widgetset.button(grec.f0.f2, 'Send&dismiss', value='s&d');
   widgetset.popuphelp(grec.f0.f2.senddismiss, 
             'Send region to current connected region entry widget and dimiss the GUI',
             width=100);
   grec.f0.f2.send := widgetset.button(grec.f0.f2, 'Send', value='s');
   widgetset.popuphelp(grec.f0.f2.send, 'Send region to current connected region entry widget');
   grec.f0.f2.break := widgetset.button(grec.f0.f2, 'Break');
   widgetset.popuphelp(grec.f0.f2.break, 'Break connection with current connected region entry widget');
   self.setsendbreakstate(enable=F);
#
   whenever grec.f0.f2.update->press do {
      private.update_images(grec.imagesListBox);
      private.update_regions(grec.regionsListBox);
   }
   whenever grec.f0.f2.send->press,grec.f0.f2.senddismiss->press do {
      selectList := grec.regionsListBox->selection();
      if (length(selectList>0)) {
         selectNames := grec.regionsListBox->get(selectList)[1];
         self->sent(selectNames);
      } else {
         note ('You must select a region to send', priority='WARN',
               origin='regionmanagergui.g');
      }
      if ($value=='s&d') private.dismiss()
   }
   whenever grec.f0.f2.break->press do {
      __regionmanager_rm.setselectcallback(0);
   }
#
# Second dismiss button.
#
   grec.f0.f2.dismiss2 := widgetset.button(grec.f0.f2, text='Dismiss',
					   type='dismiss');
   widgetset.popuphelp(grec.f0.f2.dismiss2, 'Dismiss all regionmanager windows, preserving state');
   whenever grec.f0.f0.file.dismiss->press,
            grec.f0.f2.dismiss2->press do {
      private.dismiss()
   }
#
# Force update of list boxes
#
   private.update_types(grec.typesListBox);
   private.update_regions(grec.regionsListBox);
   private.update_images(grec.imagesListBox);
#
   grec.f0->map();
   return T;
}



const self.done := function(destroy=T)
#
# With destroy=F, this will destroy the GUI state but the 
# regionmanagergui object will remain viable and the GUI 
# can be restarted.  With destroy=T then the regionmanagergui object is 
# put to sleep as well.
#
{
  wider grec, hrec, irec, jrec, krec, lrec, self, private;
#    
  private.scripter.done();
  grec.f0->unmap();
  widgetset.popupremove(grec.f0);
  grec.f0 := F;
  grec.built := F;
  grec.hidden := F;
  if (has_field(hrec, 'quarter')) widgetset.popupremove(hrec.quarter);
  if (has_field(hrec, 'box')) widgetset.popupremove(hrec.box);
  if (has_field(hrec, 'worldbox')) widgetset.popupremove(hrec.worldbox);
  if (has_field(hrec, 'worldpoly')) widgetset.popupremove(hrec.worldpoly);
  if (has_field(hrec, 'worldrange')) widgetset.popupremove(hrec.worldrange);
  if (has_field(hrec, 'union')) widgetset.popupremove(hrec.union);
  if (has_field(hrec, 'compl')) widgetset.popupremove(hrec.compl);
  if (has_field(hrec, 'diff')) widgetset.popupremove(hrec.diff);
  if (has_field(hrec, 'int')) widgetset.popupremove(hrec.int);
  if (has_field(hrec, 'ext')) widgetset.popupremove(hrec.ext);
  if (has_field(hrec, 'concat')) widgetset.popupremove(hrec.concat);
  if (has_field(hrec, 'save')) widgetset.popupremove(hrec.save);
  if (has_field(hrec, 'restore')) widgetset.popupremove(hrec.restore);
  if (has_field(hrec, 'delete')) widgetset.popupremove(hrec.delete);
  val hrec := F;             # Creation frames
  val irec := F;             # Save entry box values from last time
  if (has_field(jrec, 'cSys') && is_coordsys(jrec.cSys)) {
     jrec.cSys.done();
  }
#
  val jrec := F;             # Globals made with eval
  val lrec := F;             # Regions last deleted
#
# Deactivate forever
#
  private.activate_deactivate(krec.save, F);
  private.activate_deactivate(krec.restore, F);
  private.activate_deactivate(krec.delete, F);
  private.activate_deactivate(krec.interactive, F);
  krec.save := [];                    # Whenevers
  krec.restore := [];
  krec.delete := [];
  krec.interactive := [=];
#
  if (destroy) {
     val grec := F;                   # Main panel, formats
     val krec := F;                   # Whenevers
     val self := F;
     val private := F;
     qrec.support.done();
     val qrec := F;
#
     if (is_defined('__regionmanager_rm')) symbol_delete(__regionmanager_rm);
     if (is_defined('__regionmanager_rec')) symbol_delete(__regionmanager_rec);
     if (is_defined('__regionmanager_blc')) symbol_delete(__regionmanager_blc);
     if (is_defined('__regionmanager_trc')) symbol_delete(__regionmanager_trc);
     if (is_defined('__regionmanager_cSys')) symbol_delete(__regionmanager_cSys);
     if (is_defined('__regionmanager_xVector')) symbol_delete(__regionmanager_xVector);
     if (is_defined('__regionmanager_yVector')) symbol_delete(__regionmanager_yVector);
     if (is_defined('__regionmanager_region')) symbol_delete(__regionmanager_region);
  }
}


const private.assignImage := function (ref destroyIt, imageName)
#
# Evaluate symbol or open disk file and return 
# image tool.  indicate whether the image tool
# should be destroyed by the caller or not
#
{
   val destroyIt := F;
   if (is_defined(imageName)) {
      tempImage := symbol_value(imageName);            # image tool
      if (!tempImage.isopen()) {
         return throw ('Image tool is not open',
                       origin='private.assignImage');
      }
   } else {
      tempImage := image(imageName);                   # disk image file
      val destroyIt := T;
   }
   return tempImage;
}



const private.activate_deactivate := function (const list, doActivate)
{
   n := length(list);
   if (n > 0) {
      for (i in 1:n) {
         if (is_record(list[i])) {
            n2 := length(list[i]);
            for (j in 1:n2) {
               if (doActivate) {
                  activate list[i][j];
               } else {
                  deactivate list[i][j];
               }
            }
         } else {
            if (doActivate) {
               activate list[i];
            } else {
               deactivate list[i];
            }
         }
      }
   }
   return T;
}


const private.add_unit_to_menu_and_list := function (ref menu, unit, 
                                                     list, width, fieldName)
#
# A region may be made with a unit that is not in our
# basic list.  Check the unit and add it to the menu and
# to the basic list if it's ok
# 
{
   if (strlen(unit)>0) {
      found := menu.selectlabel(unit);
      if (is_boolean(found) && !found) {
         if (private.unit_checker (unit, list, dq)) {
            menu.extend(unit, width=width);
            menu.selectlabel(unit);
#
            wider grec;
            n := length(grec.format[fieldName]['list']);
            grec.format[fieldName]['list'][n+1] := unit;
         }
      }
   }
#
#   labels := menu.getlabels();
#   private.strip_string_field(labels, '...');
#   grec.format[fieldName]['list'] := labels;
#
   return T;   

}


const private.build_compound_regions := function (ref irec, ref hrec, const type,
                                                  ref regionsListBox)
#
# Make the compound region creation frames and service them
#
{
   buildIt := F;
   if (type==qrec.support.name_to_string('WCUNION')) {
      if (has_field(hrec, 'union')) {
#
# Remap it
#
         hrec.union.regionName.insert(private.defaultname('union'));
         hrec.union->map();
         return T;
      }
#
# Create GUI
#
      widgetset.tk_hold();
      hrec.union:= widgetset.frame(title='Union', side='top', expand='both', 
                                   relief='raised');
      hrec.union->unmap();
      widgetset.tk_release();
#
      hrec.union.regionName := [=];
      hrec.union.inRegions := [=];
      hrec.union.comment := [=];
#
      qrec.support.create_entry(hrec.union.regionName, hrec.union, 'Output region', 
                                grec.entryWidth2);
      hrec.union.regionName.insert(private.defaultname('union'));
      qrec.support.create_entry(hrec.union.inRegions, hrec.union,  'Input regions', 
                                grec.entryWidth2,
                                labelhlp1='Enter regions to find the union of');
      qrec.support.create_entry(hrec.union.comment, hrec.union,    'comment      ', 
                                width=grec.entryWidth2,
                                labelhlp1='This comment is stored with the region');
      hrec.union.space := widgetset.frame(hrec.union, height=5, expand='x');
      hrec.union.action := widgetset.frame(hrec.union, expand='x', side='left');
      hrec.union.action.confirm := [=];
      qrec.support.create_confirm(hrec.union.action.confirm, hrec.union.action, 
                                  width=8, value=grec.confirm);
      hrec.union.action2 := widgetset.frame(hrec.union, expand='x', side='left');
      private.create_compound_action(hrec.union.action2, T, F, widthReplace=8,
                                     widthAppend=-1, widthCreate=-1);
      private.create_dismiss(hrec.union, hrec.union.action2, T, -1);
#
# Service it
#
      whenever hrec.union.action2.replace->press do {
         inputRegionsString := private.selection_string(regionsListBox);
         hrec.union.inRegions.insert(inputRegionsString);
      }
      whenever hrec.union.action2.append->press do {
         inputRegionsString := private.selection_string(regionsListBox);
         regions := hrec.union.inRegions.get();
         if (strlen(regions)==0) {
            hrec.union.inRegions.insert(inputRegionsString);
         } else {
            hrec.union.inRegions.insert(spaste(regions, ', ',inputRegionsString));
         }
      }
      whenever hrec.union.action2.go->press do {  
         name := hrec.union.regionName.get();
         regions := hrec.union.inRegions.get();
         comment := hrec.union.comment.get();
         confirm := hrec.union.action.confirm.getvalue();
#
         if (private.string_check(name, 'Output region', T) &&
             private.input_regions_check(regions, 2)) {
            doIt := T;
            qrec.support.isRegion_defined (name, doIt, name, confirm);
            if (doIt) {
               command := spaste(name,':= __regionmanager_rm.union(', regions,
                                 ',', as_evalstr(comment), ')');
               ff := eval(command);
               if (!is_fail(ff)) {
                  irec['union'][name] := [=];
                  irec['union'][name]['inputRegions'] := regions;
                  private.update_regions (regionsListBox);
                  hrec.union->unmap();
#
                  private.scripter.log(command);
               } else {
                  note(ff::message, priority='SEVERE', 
                       origin='regionmanagergui.build_compound_regions');
                  if (is_defined(name)) {
                     symbol_delete(name);
                  }
               }
            }
         }
      }         
      hrec.union->map();
   } else if (type==qrec.support.name_to_string('WCCOMPLEMENT')) {
      if (has_field(hrec, 'compl')) {
#
# Remap it
#
         hrec.compl.regionName.insert(private.defaultname('compl'));
         hrec.compl->map();
         return T;
      }
#
#
# Create GUI
#
      widgetset.tk_hold();
      hrec.compl:= widgetset.frame(title='Complement', side='top', expand='both', 
                             relief='raised');
      hrec.compl->unmap();
      widgetset.tk_release();
#
      hrec.compl.regionName := [=];
      hrec.compl.inRegions := [=];
      hrec.compl.comment := [=];
#
      qrec.support.create_entry(hrec.compl.regionName, hrec.compl, 'Output region', 
                                grec.entryWidth2);
      hrec.compl.regionName.insert(private.defaultname('compl'));
      qrec.support.create_entry(hrec.compl.inRegions, hrec.compl,  'Input region ', 
                                grec.entryWidth2,
                                labelhlp1='Enter region to find the complement of');
      qrec.support.create_entry(hrec.compl.comment, hrec.compl,    'comment      ', 
                                width=grec.entryWidth2,
                                labelhlp1='This comment is stored with the region');
      hrec.compl.space := widgetset.frame(hrec.compl, height=5, expand='x');
      hrec.compl.action := widgetset.frame(hrec.compl, expand='x', side='left');
      hrec.compl.action.confirm := [=];
      qrec.support.create_confirm(hrec.compl.action.confirm, hrec.compl.action, width=8,
                                  value=grec.confirm);
      hrec.compl.action2 := widgetset.frame(hrec.compl, expand='x', side='left');
      private.create_compound_action(hrec.compl.action2, F, F, widthReplace=8,
                                     widthCreate=-1);
      private.create_dismiss(hrec.compl, hrec.compl.action2, T, -1);
#
# Service it
#
      whenever hrec.compl.action2.replace->press do {
         inputRegionString := private.selection_string(regionsListBox, 1);
         hrec.compl.inRegions.insert(inputRegionString);
      }
      whenever hrec.compl.action2.go->press do {  
         name := hrec.compl.regionName.get();
         regions := hrec.compl.inRegions.get();
         comment := hrec.compl.comment.get();
         confirm := hrec.compl.action.confirm.getvalue();  
#
         if (private.string_check(name, 'Output region', T) &&
             private.input_regions_check(regions, 1, 1)) {
            doIt := T;
            qrec.support.isRegion_defined (name, doIt, name, confirm);
            if (doIt) {
               command := spaste(name,
                                 ':= __regionmanager_rm.complement(', 
                                 regions, ',', as_evalstr(comment), ')');
               ff := eval(command);
               if (!is_fail(ff)) {
                  irec['compl'][name] := [=];
                  irec['compl'][name]['inputRegions'] := regions;
                  private.update_regions (regionsListBox);
                  hrec.compl->unmap();
#
                  private.scripter.log(command);
               } else {
                  note(ff::message, priority='SEVERE', 
                       origin='regionmanagergui.build_compound_regions');

                  if (is_defined(name)) {
                     symbol_delete(name);
                  }
               }
            }
         }
      }         
      hrec.compl->map();
   } else if (type==qrec.support.name_to_string('WCDIFFERENCE')) {
      if (has_field(hrec, 'diff')) {
#
# Remap it
#
         hrec.diff.regionName.insert(private.defaultname('diff'));
         hrec.diff->map();
         return T;
      }
#
# Create GUI
#
      widgetset.tk_hold();
      hrec.diff:= widgetset.frame(title='Difference', side='top', expand='both', 
                            relief='raised');
      hrec.diff->unmap();
      widgetset.tk_release();
#
      hrec.diff.regionName := [=];
      hrec.diff.inRegions := [=];
      hrec.diff.comment := [=];
      qrec.support.create_entry(hrec.diff.regionName, hrec.diff, 'Output region', 
                                grec.entryWidth2);
      hrec.diff.regionName.insert(private.defaultname('diff'));
      qrec.support.create_entry(hrec.diff.inRegions, hrec.diff, 'Input regions', 
                                grec.entryWidth2,
                                labelhlp1='Enter regions to find the difference of');
      qrec.support.create_entry(hrec.diff.comment, hrec.diff, 'comment', 
                                width=grec.entryWidth2,
                                labelhlp1='This comment is stored with the region');
      hrec.diff.space := widgetset.frame(hrec.diff, height=5, expand='x');
      hrec.diff.action := widgetset.frame(hrec.diff, expand='x', side='left');
      hrec.diff.action.confirm := [=];
      qrec.support.create_confirm(hrec.diff.action.confirm, hrec.diff.action, width=8,
                                  value=grec.confirm);
      hrec.diff.action2 := widgetset.frame(hrec.diff, expand='x', side='left');
      private.create_compound_action(hrec.diff.action2, T, F, widthReplace=8,
                                     widthAppend=-1, widthCreate=-1);
      private.create_dismiss(hrec.diff, hrec.diff.action2, T, -1);
#
# Service it
#
      whenever hrec.diff.action2.replace->press do {
         inputRegionString := private.selection_string(regionsListBox, 2);
         hrec.diff.inRegions.insert(inputRegionString);
      }
      whenever hrec.diff.action2.append->press do {
         inputRegionsString := private.selection_string(regionsListBox, 2);
         regions := hrec.diff.inRegions.get();
         if (strlen(regions)==0) {
            hrec.diff.inRegions.insert(inputRegionsString);
         } else {
            hrec.diff.inRegions.insert(spaste(regions, ', ',inputRegionsString));
         }
      }
      whenever hrec.diff.action2.go->press do {  
         name := hrec.diff.regionName.get();
         regions := hrec.diff.inRegions.get();
         comment := hrec.diff.comment.get();
         confirm := hrec.diff.action.confirm.getvalue();  
#
         if (private.string_check(name, 'Output region', T) &&
             private.input_regions_check(regions, 2, 2)) {
            doIt := T;
            qrec.support.isRegion_defined (name, doIt, name, confirm);
            if (doIt) {
               command := spaste(name,
                                 ' := __regionmanager_rm.difference(', 
                                 regions, ',', as_evalstr(comment), ')');
               ff := eval(command);
               if (!is_fail(ff)) {
                  irec['diff'][name] := [=];
                  irec['diff'][name]['inputRegions'] := regions;
                  private.update_regions (regionsListBox);
                  hrec.diff->unmap();
#
                  private.scripter.log(command);
               } else {
                  note(ff::message, priority='SEVERE', 
                       origin='regionmanagergui.build_compound_regions');
                  if (is_defined(name)) {
                     symbol_delete(name);
                  }
               }
            }
         }
      }         
      hrec.diff->map();
   } else if (type==qrec.support.name_to_string('WCINTERSECTION')) {
      if (has_field(hrec, 'int')) {
#
# Remap it
#
         hrec.int.regionName.insert(private.defaultname('int'));
         hrec.int->map();
         return T;
      }
#
#
# Create GUI
#
      widgetset.tk_hold();
      hrec.int:= widgetset.frame(title='Intersection', side='top', expand='both', 
                           relief='raised');
      hrec.int->unmap();
      widgetset.tk_release();
#
      hrec.int.regionName := [=];
      hrec.int.inRegions := [=];
      hrec.int.comment := [=];
      qrec.support.create_entry(hrec.int.regionName, hrec.int, 'Output region', 
                                grec.entryWidth2);
      hrec.int.regionName.insert(private.defaultname('int'));
      qrec.support.create_entry(hrec.int.inRegions, hrec.int,  'Input regions', 
                                grec.entryWidth2,
                                labelhlp1='Enter regions to find the intersection of');
      qrec.support.create_entry(hrec.int.comment, hrec.int,    'comment      ', 
                                width=grec.entryWidth2,
                                labelhlp1='This comment is stored with the region');
      hrec.int.space := widgetset.frame(hrec.int, height=5, expand='x');
      hrec.int.action := widgetset.frame(hrec.int, expand='x', side='left');
      hrec.int.action.confirm := [=];
      qrec.support.create_confirm(hrec.int.action.confirm, hrec.int.action, width=8,
                                  value=grec.confirm);
      hrec.int.action2 := widgetset.frame(hrec.int, expand='x', side='left');
      private.create_compound_action(hrec.int.action2, T, F, widthReplace=8,
                                     widthAppend=-1, widthCreate=-1);
      private.create_dismiss(hrec.int, hrec.int.action2, T, -1);
#
# Service it
#
      whenever hrec.int.action2.replace->press do {
         inputRegionString := private.selection_string(regionsListBox);
         hrec.int.inRegions.insert(inputRegionString);
      }
      whenever hrec.int.action2.append->press do {
         inputRegionsString := private.selection_string(regionsListBox);
         regions := hrec.int.inRegions.get();
         if (strlen(regions)==0) {
            hrec.int.inRegions.insert(inputRegionsString);
         } else {
            hrec.int.inRegions.insert(spaste(regions, ', ',inputRegionsString));
         }
      }
      whenever hrec.int.action2.go->press do {  
         name := hrec.int.regionName.get();
         regions := hrec.int.inRegions.get();
         comment := hrec.int.comment.get();
         confirm := hrec.int.action.confirm.getvalue();  
#
         if (private.string_check(name, 'Output region', T) &&
             private.input_regions_check(regions, 2)) {
            doIt := T;
            qrec.support.isRegion_defined (name, doIt, name, confirm);
            if (doIt) {
               command := spaste(name,
                                 ' := __regionmanager_rm.intersection(', 
                                 regions, ',', as_evalstr(comment), ')');
               ff := eval(command);
               if (!is_fail(ff)) {
                  irec['int'][name] := [=];
                  irec['int'][name]['inputRegions'] := regions;
                  private.update_regions (regionsListBox);
                  hrec.int->unmap();
#
                  private.scripter.log(command);
               } else {
                  note(ff::message, priority='SEVERE',
                       origin='regionmanagergui.build_compound_regions');
                  if (is_defined(name)) {
                     symbol_delete(name);
                  }
               }
            }                   
         }
      }         
      hrec.int->map();
   } else if (type==qrec.support.name_to_string('WCEXTENSION')) {
      if (has_field(hrec, 'ext')) {
#
# Remap it
#
         hrec.ext.regionName.insert(private.defaultname('ext'));
         hrec.ext->map();
         return T;
      }
#
# Create GUI
#
      widgetset.tk_hold();
      hrec.ext:= widgetset.frame(title='Extension', side='top', expand='both', 
                           relief='raised');
      hrec.ext->unmap();
      widgetset.tk_release();
#
      hrec.ext.regionName := [=];
      hrec.ext.inRegions := [=];
      hrec.ext.extBox := [=];
      hrec.ext.comment := [=];
      qrec.support.create_entry(hrec.ext.regionName, hrec.ext, 'Output region',
                                grec.entryWidth2);
      hrec.ext.regionName.insert(private.defaultname('ext'));
      qrec.support.create_entry(hrec.ext.inRegions, hrec.ext,  'Input region ',
                                grec.entryWidth2,
                                labelhlp1='Enter region name to find the extension of');
      qrec.support.create_entry(hrec.ext.extBox, hrec.ext,     'Extension box',
                                grec.entryWidth2,
                                labelhlp1='Enter extension world box region');
      qrec.support.create_entry(hrec.ext.comment, hrec.ext,    'comment      ',
                                width=grec.entryWidth2,
                                labelhlp1='This comment is stored with the region');
      hrec.ext.space := widgetset.frame(hrec.ext, height=5, expand='x');
      hrec.ext.action := widgetset.frame(hrec.ext, expand='x', side='left');
      hrec.ext.action.confirm := [=];
      qrec.support.create_confirm(hrec.ext.action.confirm, hrec.ext.action, width=8,
                                  value=grec.confirm);
      hrec.ext.action2 := widgetset.frame(hrec.ext, expand='x', side='left');
      private.create_compound_action(hrec.ext.action2, F, T, widthReplace=8,
                                     widthReplaceBox=-1, widthCreate=-1);
      private.create_dismiss(hrec.ext, hrec.ext.action2, T, -1);
#
# Service it
#
      whenever hrec.ext.action2.replace->press do {
         inputRegionString := private.selection_string(regionsListBox,1 );
         hrec.ext.inRegions.insert(inputRegionString);
      }
      whenever hrec.ext.action2.replaceBox->press do {
         inputRegionString := private.selection_string(regionsListBox, 1);
         hrec.ext.extBox.insert(inputRegionString);
      }
      whenever hrec.ext.action2.go->press do {  
         name := hrec.ext.regionName.get();
         regions := hrec.ext.inRegions.get();
         extBox :=  hrec.ext.extBox.get();
         comment := hrec.ext.comment.get();
         confirm := hrec.ext.action.confirm.getvalue();  
#
         ok := private.string_check(name, 'Output region', T) &&
               private.input_regions_check(regions, 1, 1) &&
               private.string_check(extBox, 'Extension box', T);
         if (ok) {
            doIt := T;
            qrec.support.isRegion_defined (name, doIt, name, confirm);
            if (doIt) {
               command := spaste(name, 
                                 ' := __regionmanager_rm.extension(box=', 
                                 extBox, ', region=', regions, 
                                 ', comment=', as_evalstr(comment),')');
               ff := eval(command);
               if (!is_fail(ff)) {
                  irec['ext'][name] := [=];
                  irec['ext'][name]['inputRegions'] := regions;
                  hrec.ext[name]['extBox'] := extBox;
                  private.update_regions (regionsListBox);
                  hrec.ext->unmap();
#
                  private.scripter.log(command);
               } else {
                  note(ff::message, priority='SEVERE',
                       origin='regionmanagergui.build_compound_regions');
                  if (is_defined(name)) {
                     symbol_delete(name);
                  }
               }
            }
         }
      }         
      hrec.ext->map();
   } else if (type==qrec.support.name_to_string('WCCONCATENATION')) {
      if (has_field(hrec, 'concat')) {
#
# Remap it
#
         hrec.concat.regionName.insert(private.defaultname('concat'));
         hrec.concat->map();
         return T;
      }
#
#
# Create GUI
#
      widgetset.tk_hold();
      hrec.concat:= widgetset.frame(title='Concatenate', side='top', expand='both', 
                              relief='raised');
      hrec.concat->unmap();
      widgetset.tk_release();
#
      hrec.concat.regionName := [=];
      hrec.concat.inRegions := [=];
      hrec.concat.extBox := [=];
      hrec.concat.comment := [=];
      qrec.support.create_entry(hrec.concat.regionName, hrec.concat, 'Output region',
                                grec.entryWidth2);
      hrec.concat.regionName.insert(private.defaultname('concat'));
      qrec.support.create_entry(hrec.concat.inRegions, hrec.concat,  'Input regions',
                                grec.entryWidth2,
                                labelhlp1='Enter regions to concatenate');
      qrec.support.create_entry(hrec.concat.extBox, hrec.concat,     'Extension box',
                                grec.entryWidth2,
                                labelhlp1='Enter world box defining concatentation axis');
      qrec.support.create_entry(hrec.concat.comment, hrec.concat,    'comment      ',
                                width=grec.entryWidth2,
                                labelhlp1='This comment is stored with the region');
#
      hrec.concat.space := widgetset.frame(hrec.concat, height=5, expand='x');
      hrec.concat.action := widgetset.frame(hrec.concat, expand='x', side='left');
      hrec.concat.action.confirm := [=];
      qrec.support.create_confirm(hrec.concat.action.confirm, hrec.concat.action, width=8,
                                  value=grec.confirm);
      hrec.concat.action2 := widgetset.frame(hrec.concat, expand='x', side='left');
      private.create_compound_action(hrec.concat.action2, F, T, widthReplace=8,
                                     widthReplaceBox=-1, widthCreate=-1);
      private.create_dismiss(hrec.concat, hrec.concat.action2, T, -1);
#
# Service it
#
      whenever hrec.concat.action2.replace->press do {
         inputRegionString := private.selection_string(regionsListBox);
         hrec.concat.inRegions.insert(inputRegionString);
      }
      whenever hrec.concat.action2.replaceBox->press do {
         inputRegionString := private.selection_string(regionsListBox, 1);
         hrec.concat.extBox.insert(inputRegionString);
      }
      whenever hrec.concat.action2.go->press do {  
         name := hrec.concat.regionName.get();
         regions := hrec.concat.inRegions.get();
         extBox :=  hrec.concat.extBox.get();
         comment := hrec.concat.comment.get();
         confirm := hrec.concat.action.confirm.getvalue();  
#
         ok := private.string_check(name, 'Output region', T) &&
               private.input_regions_check(regions, 1) &&
               private.string_check(extBox, 'Extension box', T);
         if (ok) {
            doIt := T;
            qrec.support.isRegion_defined (name, doIt, name, confirm);
            if (doIt) {
#
# Put regions into a record
#
               names := split(regions,',');
               nRegions := length(names);
               global __regionmanager_rec := [=];
               for (i in 1:nRegions) {
                  regionName := names[i];
                  regionName =~ s/^\s*//;              # remove leading blanks.  Bloody split.
                  regionName =~ s/\s*$//;              # remove trailing blanks
                  __regionmanager_rec[i] := symbol_value(regionName);
               }
               command := spaste(name, 
                                 ' := __regionmanager_rm.concatenation(box=', 
                                  extBox, 
                                  ', regions=__regionmanager_rec, comment=',  
                                  as_evalstr(comment), ')');
               ff := eval(command);
               if (!is_fail(ff)) {
                  hrec.concat[name]['inputRegions'] := regions;
                  hrec.concat[name]['extBox'] := extBox;
                  private.update_regions (regionsListBox);
                  hrec.concat->unmap();
#
                  private.scripter.log(command);
               } else {
                  note(ff::message, priority='SEVERE',
                       origin='regionmanagergui.build_compound_regions');
                  if (is_defined(name)) {
                     symbol_delete(name);
                  }
               }
            }
         }
      }         
      hrec.concat->map();
   } else {
      msg := spaste('There is no GUI for this world region type');
      note(msg, priority='WARN', origin='regionmanagergui.build_compound_regions');
   }
   return T;
}



const private.build_pixel_regions := function (ref hrec, const type,
                                               ref regionsListBox)
#
# Make the pixel region creation frames and service them
#
{
   if (type == 'quarter') {
      if (has_field(hrec, 'quarter')) {
         hrec.quarter.regionName.insert(private.defaultname('quarter'));
         hrec.quarter->map();
      } else {
         private.build_quarter (hrec, regionsListBox);
      }
   } else if (type==qrec.support.name_to_string('LCSLICER')) {
      if (has_field(hrec, 'box')) {
         hrec.box.regionName.insert(private.defaultname('box'));
         hrec.box->map();
      } else {
         private.build_box (hrec, regionsListBox);
      }
   } else if (type == 'mask') {
      if (has_field(hrec, 'mask')) {
         hrec.mask.regionName.insert(private.defaultname('mask'));
         hrec.mask->map();
      } else {
         private.build_mask (hrec, regionsListBox);
      }
   } else {
      msg := spaste('There is no GUI for this pixel region type');
      note(msg, priority='WARN', origin='regionmanagergui.build_pixel_regions');
      return F;
   }
   return T;
}

const private.build_regions := function (ref jrec, ref irec, ref hrec,
                                         ref typesListBox, ref imagesListBox, 
                                         ref regionsListBox)
{
    whenever typesListBox->select do {
#
# Read region creation type and act upon its type
#
      ok := T;
      typeSelect := typesListBox->selection();   
      if (length(typeSelect)==0) {
         msg := 'You must select a region type to create';
         note(msg, priority='WARN', origin='regionmanagergui.build_regions');
      } else {
         item := typesListBox->get(typeSelect[1])
         if (item=='mask' || item=='quarter' || 
             item==qrec.support.name_to_string('LCSLICER')) {
            ok := private.build_pixel_regions(hrec, item, regionsListBox);
         } else if (item==qrec.support.name_to_string('WCBOX') || 
                    item==qrec.support.name_to_string('WCPOLYGON') || 
                    item=='world range' ||
                    item==qrec.support.name_to_string('WCELLIPSOID')) {
            ok := private.build_world_regions(jrec, hrec, item, imagesListBox,
                                              regionsListBox);
         } else if (item=='interactive') {
            ok := private.make_interactive_region(imagesListBox, regionsListBox);
         } else if (item==qrec.support.name_to_string('WCUNION') || 
                    item==qrec.support.name_to_string('WCCOMPLEMENT') || 
                    item==qrec.support.name_to_string('WCEXTENSION') || 
                    item==qrec.support.name_to_string('WCDIFFERENCE') || 
                    item==qrec.support.name_to_string('WCINTERSECTION') || 
                    item==qrec.support.name_to_string('WCCONCATENATION')) {
            ok := private.build_compound_regions(irec, hrec, item, regionsListBox);
         } else {
            msg := 'Not a known region';
            note(msg, priority='WARN', origin='regionmanagergui.build_regions');
         }
         if (is_fail(ok)) {
            note(ok::message, priority='SEVERE', origin='regionmanagergui.build_regions');
         }
      }
   }
}


const private.build_unitMenu := function (ref parent, const coordinateType, 
                                          const axisUnit)
{ 
   local list, width, fieldName;
   private.whichFormatList(list, width, fieldName, coordinateType)
#
   hlp := 'Select default units (used if no units specified)';
   hlp2 := spaste('Select "..." to enter new units \n',
                  'Any units specified in the entry box \n',
                  'over-ride the default units');
   parent.units := widgetset.extendoptionmenu(parent=parent, labels=list,
                                              width=width, hlp=hlp, hlp2=hlp2,
                                              symbol='...', dialoglabel='Unit',
                                              dialogtitle='Enter new unit <CR>',
                                              callback2=private.unit_checker,
                                              callbackdata=dq);
   parent.units.coordinateType := fieldName;
#
# Set initial default units to axis unit.  Some axes don't
# have units (e.g. Stokes). Then the first in the 
# list will show.
#
   if (strlen(axisUnit)>0) parent.units.selectlabel(axisUnit);
#
# Update the private units list with the user's new unit added
#
   private.update_units(parent.units);
#
   return T;
}




const private.build_world_regions := function (ref jrec, ref hrec, const type,
                                               ref imagesListBox,
                                               ref regionsListBox)
#
# Make the world region creation frames and service them
#
{
   imageList := imagesListBox->selection();
   if (length(imageList) == 0) {
      msg := spaste('You must select an image as well to make a world region');
      note(msg, priority='WARN', origin='regionmanagergui.build_world_regions');
      return T;
   }
#
   if (type!=qrec.support.name_to_string('WCBOX') &&
       type!=qrec.support.name_to_string('WCPOLYGON') &&
       type!='world range') {
      msg := spaste('There is no GUI for this world region type');
      note(msg, priority='WARN', origin='regionmanagergui.build_world_regions');
      return T;
   } 
#
   local destroyIt;
   imageName := imagesListBox->get(imageList[1])
   tempImage := private.assignImage (destroyIt, imageName);
   if (is_fail(tempImage)) fail;
#
   newID := tempImage.id();
   oldID := [=];
   buildIt := F;
#
   if (type==qrec.support.name_to_string('WCBOX')) {
      if (has_field(hrec, 'worldbox')) {
         oldID := hrec.worldbox.id;
         if (!private.compareID (newID, oldID)) {
            buildIt := T;
            val hrec.worldbox := F;
         }
      } else {
         buildIt := T;
      }
      if (buildIt) {
         if (has_field(jrec, 'cSys') &&
             is_coordsys(jrec.cSys)) {
            jrec.cSys.done();
         }
         jrec.cSys := tempImage.coordsys();
         if (is_fail(jrec.cSys)) fail;
         private.build_worldbox (jrec, hrec, newID, regionsListBox);
      } else {
         hrec.worldbox.regionName.insert(private.defaultname('box'));
         hrec.worldbox->map();
      }
   } else if (type==qrec.support.name_to_string('WCPOLYGON')) {
      if (has_field(hrec, 'worldpoly')) {
         oldID := hrec.worldpoly.id;
         if (!private.compareID (newID, oldID)) {
            buildIt := T;
            val hrec.worldpoly := F;
         }
      } else {
         buildIt := T;
      }
      if (buildIt) {
         if (has_field(jrec, 'cSys') &&
             is_coordsys(jrec.cSys)) jrec.cSys.done();
         jrec.cSys := tempImage.coordsys();
         if (is_fail(jrec.cSys)) fail;
         private.build_worldpoly (jrec, hrec, newID, regionsListBox);
      } else {
         hrec.worldpoly.regionName.insert(private.defaultname('poly'));
         hrec.worldpoly->map();
      }
   } else if (type=='world range') {
      if (has_field(hrec, 'worldrange')) {
         oldID := hrec.worldrange.id;
         if (!private.compareID (newID, oldID)) {
            buildIt := T;
            val hrec.worldrange := F;
         }
      } else {
         buildIt := T;
      }
      if (buildIt) {
         if (has_field(jrec, 'cSys') &&
             is_coordsys(jrec.cSys)) jrec.cSys.done();
         jrec.cSys := tempImage.coordsys();
         if (is_fail(jrec.cSys)) fail;
         private.build_worldrange (jrec, hrec, newID, regionsListBox);
      } else {
         hrec.worldrange.regionName.insert(private.defaultname('range'));
         hrec.worldrange->map();
      }
   }
#
   if(destroyIt) tempImage.done();
   return T;
}


const private.build_box := function (ref parent, ref regionsListBox)
{
   widgetset.tk_hold();
   parent.box := widgetset.frame(title='Pixel Box', side='top', 
                           relief='raised', expand='both', width=40);
   parent.box->unmap();
   widgetset.tk_release();
#
   parent.box.regionName := [=];
   parent.box.blc := [=];
   parent.box.trc := [=];
   parent.box.inc := [=];
   parent.box.comment := [=];
#
   qrec.support.create_entry(parent.box.regionName, parent.box, 'Output region',
                             grec.entryWidth, 
                             labelhlp1='This is the Glish variable name for the region');
   parent.box.regionName.insert(private.defaultname('box'));
   helptxt1 := 'Enter vector of values. Empty takes start of image';
   helptxt2 := spaste('Examples: "2 3 4" or "[2, 3, 4].  \n',
                      'A predefined Glish variable name can be given');
   qrec.support.create_vectorentry(parent.box.blc, parent.box,        'blc          ',
                                   grec.entryWidth, helptxt1, helptxt2, [1,1]);
#
   helptxt1 := 'Enter vector of values. Empty takes end of image';
   qrec.support.create_vectorentry (parent.box.trc, parent.box,       'trc          ',
                                    grec.entryWidth, helptxt1, helptxt2, [128,128]);
#
   helptxt1 := 'Enter vector of values. Empty takes unit increments';
   qrec.support.create_vectorentry(parent.box.inc, parent.box,        'inc          ',
                                   grec.entryWidth, helptxt1, helptxt2, [1,1]);
   qrec.support.create_entry(parent.box.comment, parent.box,    'comment      ',
                             width=grec.entryWidth,
                             labelhlp1='This comment is stored with the region');
   parent.box.space := widgetset.frame(parent.box, height=5, expand='x');
   parent.box.action := widgetset.frame(parent.box, expand='x', side='left');
   private.create_absrel(parent.box.action, width=8);
   private.create_fraction(parent.box.action, width=8);
#
   parent.box.action2 := widgetset.frame(parent.box, expand='x', side='left');
   parent.box.action2.confirm := [=];
   qrec.support.create_confirm(parent.box.action2.confirm, parent.box.action2, 
                               width=8, value=grec.confirm);
   private.create_go(parent.box.action2, F);
   private.create_dismiss(parent.box, parent.box.action2, T, -1);
#
   whenever parent.box.action2.go->press do {
      name := parent.box.regionName.get();
      blc  := parent.box.blc.get();
      trc  := parent.box.trc.get();
      inc := parent.box.inc.get();
      absRelValue := parent.box.action.absrel.getvalue();
      fractionValue := parent.box.action.fraction.getvalue();
      confirm := parent.box.action2.confirm.getvalue();
      comment := parent.box.comment.get();
#
      if (private.string_check(name, 'Output region', T)) {
         doIt := T;
         qrec.support.isRegion_defined (name, doIt, name, confirm);
         if (doIt) {
            command := spaste(name,':= __regionmanager_rm.box(blc=', 
                              as_evalstr(blc),', trc=', as_evalstr(trc),
                              ', inc=', as_evalstr(inc),
                              ', absrel=', as_evalstr(absRelValue),
                               ', frac=', fractionValue,
                              ', comment=', as_evalstr(comment),')');
            ff := eval(command);
            if (!is_fail(ff)) {
               private.update_regions(regionsListBox);
               parent.box->unmap();
#
               private.scripter.log(command);
            } else {
               note(ff::message, priority='SEVERE',
                    origin='regionmanagergui.build_box');
               if (is_defined(name)) {
                  symbol_delete(name);
               }
            }
         }
      }
   }
   parent.box->map();
   return T;
}


const private.build_quarter := function (ref parent, ref regionsListBox)
{
   widgetset.tk_hold();
   parent.quarter := widgetset.frame(title='Quarter', side='top', 
                               relief='raised', expand='both');
   parent.quarter->unmap();
   widgetset.tk_release();
#
   parent.quarter.regionName := [=];
   parent.quarter.comment := [=];
   qrec.support.create_entry(parent.quarter.regionName, parent.quarter, 'Output region', 
                             grec.entryWidth,
                             labelhlp1='This is the Glish variable name for the region');
   parent.quarter.regionName.insert(private.defaultname('quarter'));
   qrec.support.create_entry(parent.quarter.comment, parent.quarter,    'comment      ',
                             grec.entryWidth,
                             labelhlp1='This comment is stored with the region');
   parent.quarter.space := widgetset.frame(parent.quarter, height=5, expand='x');
   parent.quarter.action := widgetset.frame(parent.quarter, expand='x', side='left');
   parent.quarter.action.confirm := [=];
   qrec.support.create_confirm(parent.quarter.action.confirm, parent.quarter.action, 
                               width=8, value=grec.confirm);
   private.create_go(parent.quarter.action, F)
   private.create_dismiss(parent.quarter, parent.quarter.action, T, -1);
#
   whenever parent.quarter.action.go->press do {
      name := parent.quarter.regionName.get();
      comment := parent.quarter.comment.get();
      confirm := parent.quarter.action.confirm.getvalue();
      if (private.string_check(name, 'Output region', T)) {
         doIt := T;
         qrec.support.isRegion_defined (name, doIt, name, confirm);
         if (doIt) {
            command := spaste(name,
                              ' := __regionmanager_rm.quarter(comment=', 
                              as_evalstr(comment),')');
            ff := eval(command);
            if (!is_fail(ff)) {
               private.update_regions(regionsListBox);
               parent.quarter->unmap();
#
               private.scripter.log(command);
            } else {
               note(ff::message, priority='SEVERE',
                    origin='regionmanagergui.build_quarter');
               if (is_defined(name)) {
                  symbol_delete(name);
               }
            }
         }
      }
   }
   parent.quarter->map();
   return T;
}


const private.build_mask := function (ref parent, ref regionsListBox)
{
   widgetset.tk_hold();
   parent.mask := widgetset.frame(title='Mask', side='top', 
                                     relief='raised', expand='both');
   parent.mask->unmap();
   widgetset.tk_release();
#
   parent.mask.regionName := [=];
   qrec.support.create_entry(parent.mask.regionName, parent.mask, 'Output region', 
                             grec.entryWidth,
                             labelhlp1='This is the Glish variable name for the region');
   parent.mask.regionName.insert(private.defaultname('mask'));
#
   parent.mask.expr := [=];
   qrec.support.create_entry(parent.mask.expr , parent.mask, 'Expression',
                             grec.entryWidth,
                             labelhlp1='LEL Boolean expression');
#
   parent.mask.comment := [=];
   qrec.support.create_entry(parent.mask.comment, parent.mask,    'comment      ',
                             grec.entryWidth,
                             labelhlp1='This comment is stored with the region');
   parent.mask.space := widgetset.frame(parent.mask, height=5, expand='x');
   parent.mask.action := widgetset.frame(parent.mask, expand='x', side='left');
   parent.mask.action.confirm := [=];
   qrec.support.create_confirm(parent.mask.action.confirm, parent.mask.action, 
                               width=8, value=grec.confirm);
   private.create_go(parent.mask.action, F)
   private.create_dismiss(parent.mask, parent.mask.action, T, -1);
#
   whenever parent.mask.action.go->press do {
      name := parent.mask.regionName.get();
      expr := parent.mask.expr.get();
      comment := parent.mask.comment.get();
      confirm := parent.mask.action.confirm.getvalue();
      if (private.string_check(name, 'Output region', T)) {
         doIt := T;
         qrec.support.isRegion_defined (name, doIt, name, confirm);
         if (doIt) {
            command := spaste(name,
               ' := __regionmanager_rm.wmask(comment=', as_evalstr(comment),
                                            ', expr=', as_evalstr(expr), ')');
            ff := eval(command);
            if (!is_fail(ff)) {
               private.update_regions(regionsListBox);
               parent.mask->unmap();
#
               private.scripter.log(command);
            } else {
               note(ff::message, priority='SEVERE',
                    origin='regionmanagergui.build_mask');
               if (is_defined(name)) {
                  symbol_delete(name);
               }
            }
         }
      }
   }
   parent.mask->map();
   return T;
}


const private.build_worldbox := function (ref jrec, ref hrec,
                                          const id,
                                          ref regionsListBox)
{
#
# Get some things from the CS
#
   nAxes := jrec.cSys.naxes(world=F);
   nWorldAxes := jrec.cSys.naxes(world=T);
   axisNames := jrec.cSys.names();
   axisUnits := jrec.cSys.units();
   coordinateTypes := jrec.cSys.axiscoordinatetypes();
#
# Build GUI
#
   widgetset.tk_hold();
   hrec.worldbox := widgetset.frame(title='World Box', side='top', 
                                    relief='raised', expand='both');
   hrec.worldbox->unmap();
   widgetset.tk_release();
   hrec.worldbox.id := id;
#
   hrec.worldbox.regionName := [=];
   qrec.support.create_entry(hrec.worldbox.regionName, hrec.worldbox, 'Output region', 
                             grec.entryWidth,
                             labelhlp1='This is the Glish variable name for the region');
   hrec.worldbox.regionName.insert(private.defaultname('box'));
#
   hrec.worldbox.holder := widgetset.frame(hrec.worldbox, side='left', expand='x');
#
   help2 := spaste('Extra units "pix" (pixels) "frac\n',
                   '(fractional), "def" (take default on\n',
                   'application) are defined. The unit can\n',
                   'be left off and the unit from the default\n',
                   'unit box below will be used. Units in \n',
                   'the coordinate boxes over-ride the\n',
                   'default unit.   \n',
                   'RA and DEC given in standard aips++ formats \n\n',
                   'Examples: 1.3GHz, 5h3m2.0s, -29d20m34.324s, 3e20km \n',
                   'A predefined Glish variable name can be given');
#
   for (i in 1:nAxes) {
      fN := spaste('axis', i);
      hrec.worldbox.holder[fN] :=widgetset.frame(hrec.worldbox.holder, side='top');
      hrec.worldbox.holder[fN]['axes'] := widgetset.frame(hrec.worldbox.holder[fN], 
                                                   side='top', expand='x', height=60);
      text1 := axisNames[i];
      if (i==1) text1 := spaste('      ', axisNames[i]);
      hrec.worldbox.holder[fN]['axes']['label'] := widgetset.label(hrec.worldbox.holder[fN]['axes'],
                                                                   text=text1);
#
      hrec.worldbox.holder[fN]['blc'] := widgetset.frame(hrec.worldbox.holder[fN], side='left',
                                                         expand='x');
      label1 := unset; help1 := unset; 
      if (i==1) {
         label1 := 'blc   ';
         help1 := 'Enter value & unit for each desired axis';
      }
      hrec.worldbox.holder[fN].blc.entry := [=];
      qrec.support.create_entry(entryBox=hrec.worldbox.holder[fN]['blc']['entry'], 
                                parent=hrec.worldbox.holder[fN]['blc'], 
                                labelName=label1, width=15, 
                                labelhlp1=help1, labelhlp2=help2);
#
      hrec.worldbox.holder[fN]['trc'] :=widgetset.frame(hrec.worldbox.holder[fN], side='left',
                                                        expand='x');
      label1 := unset; help1 := unset; 
      if (i==1) {
         label1 := 'trc   ';
         help1 := 'Enter value & unit for each desired axis';
      }
      hrec.worldbox.holder[fN].trc.entry := [=];
      qrec.support.create_entry(entryBox=hrec.worldbox.holder[fN]['trc']['entry'], 
                                parent=hrec.worldbox.holder[fN]['trc'], 
                                labelName=label1, width=15, 
                                labelhlp1=help1, labelhlp2=help2);
#
      hrec.worldbox.holder[fN]['buttons'] :=widgetset.frame(hrec.worldbox.holder[fN], 
                                                            side='left', expand='x');
      if (i==1) {
         hrec.worldbox.holder[fN]['buttons'].label :=
            widgetset.label(hrec.worldbox.holder[fN]['buttons'], text='      '); 
      }
      private.build_unitMenu(hrec.worldbox.holder[fN]['buttons'],
                             coordinateTypes[i], axisUnits[i]);
#
      private.create_absrel(hrec.worldbox.holder[fN]['buttons'], width=8);
   }
#
   hrec.worldbox.comment := [=];
   qrec.support.create_entry(hrec.worldbox.comment, hrec.worldbox, 'comment     ', 
                             grec.entryWidth,
                             labelhlp1='This comment is stored with the region');
   hrec.worldbox.action := widgetset.frame(hrec.worldbox, expand='x', side='left');
   hrec.worldbox.action.confirm := [=];
   qrec.support.create_confirm(hrec.worldbox.action.confirm, hrec.worldbox.action, 
                               width=8, value=grec.confirm);
   private.create_go(hrec.worldbox.action, F);
   private.create_dismiss(hrec.worldbox, hrec.worldbox.action, T, -1);
#
# Service requests
#
   whenever hrec.worldbox.action.go->press do {
      name := hrec.worldbox.regionName.get();
      comment := hrec.worldbox.comment.get();
      confirm := hrec.worldbox.action.confirm.getvalue();
      ok := private.string_check(name, 'Output region', T);
#
      pixelAxes := [];
      if (ok) {
#
# Find out for which axes the user gave some values
#
         j := 0;
         for (i in 1:nAxes) {
            fN := spaste('axis', i);
            text1 := hrec.worldbox.holder[fN]['blc']['entry'].get();
            text2 := hrec.worldbox.holder[fN]['trc']['entry'].get();
            if (strlen(text1)!=0 || strlen(text2)!=0) {
               j +:= 1;
               pixelAxes[j] := i;     
            }
         }
#
# Work hard to set blc/trc quantity vectors.  The scalar/vector
# r_array mess makes this irksome.
#
         global __regionmanager_blc := [=];
         global __regionmanager_trc := [=];
# 
         nGivenAxes := length(pixelAxes);
         if (nGivenAxes > 0) {
            global __regionmanager_blc := r_array(dq.quantity('1rad'),nGivenAxes);
            global __regionmanager_trc := r_array(dq.quantity('1rad'),nGivenAxes);
#
            for (i in 1:nGivenAxes) {
               j := pixelAxes[i];
               fN := spaste('axis', j);
               text1 := hrec.worldbox.holder[fN]['blc']['entry'].get();
               text2 := hrec.worldbox.holder[fN]['trc']['entry'].get();
               text3 := hrec.worldbox.holder[fN]['buttons']['units'].getlabel();
#
               local blcQ, trcQ;
               if (private.quantity_check(blcQ, text1, text3) &&
                   private.quantity_check(trcQ, text2, text3)) {
#
# WCBox.cc handles the differences between vectors and non-vectors
#
                 if (nGivenAxes==1) {
                    __regionmanager_blc := blcQ;
                    __regionmanager_trc := trcQ;
                 } else {
                    __regionmanager_blc[i] := blcQ;
                    __regionmanager_trc[i] := trcQ;
                 }
               } else {
                  ok := F;
               }
            }
         }
      }
#
# Set absrel string.  To avoid another global, I do this with
# paste, which means a few more hoops to jump through. 
#
      absRel := '';
      if (ok) {
         nGivenAxes := length(pixelAxes);
         if (nGivenAxes > 0) {
            absRel2 := array('', nGivenAxes);
            for (i in 1:nGivenAxes) {
               j := pixelAxes[i];
               fN := spaste('axis', j);
               absRel2[i] := hrec.worldbox.holder[fN]['buttons']['absrel'].getvalue();
            }
            absRel := paste(absRel2);
         }
      }
#
# Create region
#
      if (ok) {
         doIt := T;
         qrec.support.isRegion_defined (name, doIt, name, confirm);
         if (doIt) {
            global __regionmanager_cSys := jrec.cSys; 
            command := spaste(name,
                              ' := __regionmanager_rm.wbox(blc=__regionmanager_blc',
                              ', trc=__regionmanager_trc',
                              ', pixelaxes=', as_evalstr(pixelAxes),
                              ', absrel=', as_evalstr(absRel),
                              ', csys=__regionmanager_cSys', 
                              ', comment=', as_evalstr(comment),')');
            ff := eval(command);
            if (!is_fail(ff)) {
               private.update_regions(regionsListBox);
               hrec.worldbox->unmap();
#
               private.scripter.log(command);
            } else {
               note(ff::message, priority='SEVERE',
                    origin='regionmanagergui.build_worldbox');
               if (is_defined(name)) {
                  symbol_delete(name);
               }
            }
         }
      }
   }
#
   hrec.worldbox->map();
   return T;
}



const private.build_worldpoly := function (ref jrec, ref hrec, 
                                           const id,
                                           ref regionsListBox)
{
   wider grec;
#
# Get some things from the CS
#
   nAxes := jrec.cSys.naxes(world=F);
   nWorldAxes := jrec.cSys.naxes(world=T);
   axisNames := jrec.cSys.names();
   axisUnits := jrec.cSys.units();
   coordinateTypes := jrec.cSys.axiscoordinatetypes();
#
# Build GUI
#
   widgetset.tk_hold();
   hrec.worldpoly := widgetset.frame(title='World Polygon', side='top', 
                                     relief='raised', expand='both');
   hrec.worldpoly->unmap();
   widgetset.tk_release();
   hrec.worldpoly.id := id;
#
   hrec.worldpoly.regionName := [=];
   qrec.support.create_entry(hrec.worldpoly.regionName, hrec.worldpoly, 
                             'Output region', width=grec.entryWidth,
                             labelhlp1='This is the Glish variable name for the region');
   hrec.worldpoly.regionName.insert(private.defaultname('poly'));
#
   help1 := 'Enter a vector of vertex coordinate values';
   help2 := spaste('You can specify \n',
                   ' - a numeric vector and take the unit from the \n',
                   '   option-menu below \n',
                   ' - a pre-defined Glish variable.  This variable may \n',
                   '   hold a numeric vector as above, or a Quantity \n',
                   '   vector with the unit included \n\n',
                   ' Examples: [1,2,3,4], or a variable which holds \n',
                   '   dq.quantity([1,2,3,4],"deg")');
#
   hrec.worldpoly.xvector := [=];
   qrec.support.create_vectorentry(hrec.worldpoly.xvector, hrec.worldpoly, 'X vector',
                                   grec.entryWidth, help1, help2, []);
   hrec.worldpoly.xaxis := widgetset.frame(hrec.worldpoly, side='left', expand='x');
   hrec.worldpoly.xaxis.label := widgetset.label(hrec.worldpoly.xaxis, 'X axis');
   widgetset.popuphelp (hrec.worldpoly.xaxis.label,  'Specify which axis is the "x" vector');
   for (i in 1:nAxes) {
      fN := spaste('axis', i);
      hrec.worldpoly.xaxis[fN] := widgetset.button(hrec.worldpoly.xaxis, type='radio',
                                                   value=i, text=axisNames[i]);
      hrec.worldpoly.xaxis[fN]['index'] := i;
   }
#
   help3 := 'Select vertex units';
   help4 := 'Select "..." to enter new units';
   hrec.worldpoly.xaxis.unitMenu := 
       widgetset.extendoptionmenu(parent=hrec.worldpoly.xaxis,
                                  hlp=help3, hlp2=help4, symbol='...',
                                  dialoglabel='Unit',
                                  dialogtitle='Enter new unit <CR>',
                                  callback2=private.unit_checker,
                                  callbackdata=dq);
#
   hrec.worldpoly.xaxis.axis1->state(T);
   private.updateUnitsMenu (1, coordinateTypes, axisUnits,
                            hrec.worldpoly.xaxis.unitMenu)
#
   for (i in 1:nAxes) {
      fN := spaste('axis', i);
      whenever hrec.worldpoly.xaxis[fN]->press do {
#
# The user has selected an axis.  Replace the menu with the
# units for this axis.
#

         idx := ref $agent.index;
         private.updateUnitsMenu (idx, coordinateTypes, axisUnits,
                                  hrec.worldpoly.xaxis.unitMenu)
      }
   }
   private.update_units(hrec.worldpoly.xaxis.unitMenu);
#
   hrec.worldpoly.yvector := [=];
   qrec.support.create_vectorentry(hrec.worldpoly.yvector, hrec.worldpoly, 'Y vector',
                                   grec.entryWidth, help1, help2, []);

   hrec.worldpoly.yaxis := widgetset.frame(hrec.worldpoly, side='left', expand='x');
   hrec.worldpoly.yaxis.label := widgetset.label(hrec.worldpoly.yaxis, 'Y axis');
   widgetset.popuphelp (hrec.worldpoly.yaxis.label, 
              'Specify which axis is the "y" vector');
#
   for (i in 1:nAxes) {
      fN := spaste('axis', i);
      hrec.worldpoly.yaxis[fN] := widgetset.button(hrec.worldpoly.yaxis, type='radio',
                                             value=i, text=axisNames[i]);
      hrec.worldpoly.yaxis[fN]['index'] := i;
   }
#
   hrec.worldpoly.yaxis.unitMenu := 
       widgetset.extendoptionmenu(parent=hrec.worldpoly.yaxis,
                                  hlp=help3, hlp2=help4, symbol='...',
                                  dialoglabel='Unit', dialogtitle='Enter new unit <CR>',
                                  callback2=private.unit_checker, 
                                  callbackdata=dq);
   hrec.worldpoly.yaxis.axis2->state(T);
   private.updateUnitsMenu (2, coordinateTypes, axisUnits,
                            hrec.worldpoly.yaxis.unitMenu)
#
   for (i in 1:nAxes) {
      fN := spaste('axis', i);
      whenever hrec.worldpoly.yaxis[fN]->press do {
         idx := ref $agent.index;
         private.updateUnitsMenu (idx, coordinateTypes, axisUnits,
                                  hrec.worldpoly.yaxis.unitMenu)
      }
   }
   private.update_units(hrec.worldpoly.yaxis.unitMenu);
#
   hrec.worldpoly.comment := [=];
   qrec.support.create_entry(hrec.worldpoly.comment, hrec.worldpoly, 'comment', 
                             grec.entryWidth,
                             labelhlp1='This comment is stored with the region');
   hrec.worldpoly.action := widgetset.frame(hrec.worldpoly, expand='x', side='left');
   hrec.worldpoly.action.confirm := [=];
   qrec.support.create_confirm(hrec.worldpoly.action.confirm, hrec.worldpoly.action, 
                               width=8, value=grec.confirm);
   private.create_absrel(hrec.worldpoly.action, width=8);
   private.create_go(hrec.worldpoly.action, F);
   private.create_dismiss(hrec.worldpoly, hrec.worldpoly.action, T, -1);
#
# Service it
#
   whenever hrec.worldpoly.action.go->press do {
      name := hrec.worldpoly.regionName.get();
      xValue := hrec.worldpoly.xvector.get();
      xUnit  := hrec.worldpoly.xaxis.unitMenu.getlabel();
      yValue := hrec.worldpoly.yvector.get();
      yUnit  := hrec.worldpoly.yaxis.unitMenu.getlabel();
      absRelValue := hrec.worldpoly.action.absrel.getvalue();
      comment := hrec.worldpoly.comment.get();
      confirm := hrec.worldpoly.action.confirm.getvalue();
#
      ok := private.string_check(name, 'Output region', T) &&
            private.string_check(xUnit, 'X units', T, T) &&
            private.string_check(yUnit, 'Y units', T, T);
#
      pixelAxes := array(-1,2);
      pixelAxesText := '';
#
# Find out which plane holds the polygon
#
      if (ok) {
         for (i in 1:nAxes) {
            fN := spaste('axis', i);
            if (hrec.worldpoly.xaxis[fN]->state()==T) pixelAxes[1] := i;
            if (hrec.worldpoly.yaxis[fN]->state()==T) pixelAxes[2] := i;
         }
         if (pixelAxes[1]==-1 || pixelAxes[2]==-1) {
            msg := spaste('You must select the x and y axes');
            note(msg, priority='WARN', origin='regionmanagergui.build_worldpolygon');
            ok := F;
         } else if(pixelAxes[1]==pixelAxes[2]) {
            ok := F;
            msg := spaste('You must select different x and y axes');
            note(msg, priority='WARN', origin='regionmanagergui.polygon_build_worldpolygon');
            ok := F;
         } else {
            pixelAxesText := as_evalstr(pixelAxes);
         } 
      }
#
      if (ok) {
        local tempQuant;
        ok := private.parse_polygonVector (tempQuant, xValue, xUnit, 'x');
        if (ok) global __regionmanager_xVector := tempQuant;
#
        if (ok) {
           ok := private.parse_polygonVector (tempQuant, yValue, yUnit, 'y');
           if (ok) global __regionmanager_yVector := tempQuant;
        }
      }
      if (ok) {
         doIt := T;
         qrec.support.isRegion_defined (name, doIt, name, confirm);
         if (doIt) {
            global __regionmanager_cSys := jrec.cSys;
            command := spaste(name, 
                              ':= __regionmanager_rm.wpolygon(',
                              'x=__regionmanager_xVector',
                              ', y=__regionmanager_yVector',
                              ', pixelaxes=', pixelAxesText,
                              ', absrel=\'', absRelValue,
                             '\', csys=__regionmanager_cSys',
                              ', comment=\'', comment, '\')');
            ff := eval(command);
            if (!is_fail(ff)) {
               private.update_regions(regionsListBox);
               hrec.worldpoly->unmap();
#
               private.scripter.log(command);
            } else {
               note(ff::message, priority='SEVERE',
                    origin='regionmanagergui.build_worldpoly');
               if (is_defined(name)) {
                  symbol_delete(name);
               }
            }
         }
      }
   }
#
   hrec.worldpoly->map();
   return T;
}


const private.build_worldrange := function (ref jrec, ref hrec,
                                          const id,
                                          ref regionsListBox)
{
#
# Get some things from the CS
#
   w2p := jrec.cSys.axesmap(toworld=F);
   nAxes := jrec.cSys.naxes(world=F);
   nWorldAxes := jrec.cSys.naxes(world=T);
   axisNames := jrec.cSys.names()[w2p];
   axisUnits := jrec.cSys.units()[w2p];
   coordinateTypes := jrec.cSys.axiscoordinatetypes(world=F);
#
# Build GUI
#
   widgetset.tk_hold();
   hrec.worldrange := widgetset.frame(title='World Range', side='top', 
                                    relief='raised', expand='both');
   hrec.worldrange->unmap();
   widgetset.tk_release();
   hrec.worldrange.id := id;
#
   hrec.worldrange.regionName := [=];
   qrec.support.create_entry(hrec.worldrange.regionName, hrec.worldrange, 'Output region', 
                             grec.entryWidth,
                             labelhlp1='This is the Glish variable name for the region');
   hrec.worldrange.regionName.insert(private.defaultname('range'));
#
   hrec.worldrange.axis := widgetset.frame(hrec.worldrange, side='left');
   hrec.worldrange.axis.label := widgetset.label(hrec.worldrange.axis, 'Axis');
   widgetset.popuphelp (hrec.worldrange.axis.label, 
                       'Specify which axis the range pertains to');
   labels := axisNames;
   hrec.worldrange.axis.value := widgetset.optionmenu(hrec.worldrange.axis, 
                                                      labels=labels, values=1:nAxes);
#
   hrec.worldrange.holder := widgetset.frame(hrec.worldrange, side='top', expand='x');
#
   help2 := spaste('Extra units "pix" (pixels) "frac\n',
                   '(fractional), "def" (take default on\n',
                   'application) are defined. The unit can\n',
                   'be left off and the unit from the default\n',
                   'unit box below will be used. Units in \n',
                   'the coordinate boxes over-ride the\n',
                   'default unit.   \n',
                   'RA and DEC given in standard aips++ formats \n\n',
                   'Examples: 1.3GHz, 5h3m2.0s, -29d20m34.324s, 3e20km \n',
                   'A predefined Glish variable name can be given');
#
   hrec.worldrange.holder.blc := widgetset.frame(hrec.worldrange.holder, side='left',
                                                 expand='x');
   label1 := unset; help1 := unset; 
   label1 := 'blc   ';
   help1 := 'Enter value & unit';
   hrec.worldrange.holder.blc.entry := [=];
   qrec.support.create_entry(entryBox=hrec.worldrange.holder.blc.entry,
                             parent=hrec.worldrange.holder.blc, 
                             labelName=label1, width=15, 
                             labelhlp1=help1, labelhlp2=help2);
#
   hrec.worldrange.holder.trc :=widgetset.frame(hrec.worldrange.holder, side='left',
                                                expand='x');
   label1 := unset; help1 := unset; 
   label1 := 'trc   ';
   help1 := 'Enter value & unit';
   hrec.worldrange.holder.trc.entry := [=];
   qrec.support.create_entry(entryBox=hrec.worldrange.holder.trc.entry,
                             parent=hrec.worldrange.holder.trc,
                             labelName=label1, width=15, 
                             labelhlp1=help1, labelhlp2=help2);
#
   hrec.worldrange.holder.buttons :=widgetset.frame(hrec.worldrange.holder, 
                                                    side='left', expand='x');
   hrec.worldrange.holder.buttons.label :=
      widgetset.label(hrec.worldrange.holder.buttons, text='      '); 
   private.build_unitMenu(hrec.worldrange.holder.buttons,
                          coordinateTypes[1], axisUnits[1]);
   private.create_absrel(hrec.worldrange.holder.buttons, width=8);
#
   hrec.worldrange.comment := [=];
   qrec.support.create_entry(hrec.worldrange.comment, hrec.worldrange, 'comment     ', 
                             grec.entryWidth,
                             labelhlp1='This comment is stored with the region');
   hrec.worldrange.action := widgetset.frame(hrec.worldrange, expand='x', side='left');
   hrec.worldrange.action.confirm := [=];
   qrec.support.create_confirm(hrec.worldrange.action.confirm, hrec.worldrange.action, 
                               width=8, value=grec.confirm);
   private.create_go(hrec.worldrange.action, F);
   private.create_dismiss(hrec.worldrange, hrec.worldrange.action, T, -1);
#
# Service requests
#
   whenever hrec.worldrange.axis.value->select do {
      axis := $value.value;
      private.updateUnitsMenu (axis, coordinateTypes, axisUnits,
                               hrec.worldrange.holder.buttons.units)
   }
#
   whenever hrec.worldrange.action.go->press do {
      name := hrec.worldrange.regionName.get();
      blc := hrec.worldrange.holder.blc.entry.get();
      trc := hrec.worldrange.holder.trc.entry.get();
      unit := hrec.worldrange.holder.buttons.units.getlabel();
      absRelValue := hrec.worldrange.holder.buttons.absrel.getvalue();
      axis := hrec.worldrange.axis.value.getvalue();
      confirm := hrec.worldrange.action.confirm.getvalue();
      comment := hrec.worldrange.comment.get();
      ok := private.string_check(name, 'Output region', T);
#
      if (ok) {
         doIt := T;
         qrec.support.isRegion_defined (name, doIt, name, confirm);
         if (doIt) {
            global __regionmanager_cSys := jrec.cSys;
            global __regionmanager_blc := r_array(dq.quantity('0pix'),2);
#
            local q1, q2;
            if (private.quantity_check(q1, blc, unit) &&
                private.quantity_check(q2, trc, unit)) {
               __regionmanager_blc[1] := q1;
               __regionmanager_blc[2] := q2;
            } else {
               ok := F;
            }
#
            if (ok) {
               command := spaste(name,
                  ' := __regionmanager_rm.wrange(range=__regionmanager_blc',
                  ', pixelaxis=', axis,
                  ', absrel="', absRelValue,'", csys=__regionmanager_cSys', 
                  ', comment=\'', comment, '\')');
              ff := eval(command);
              if (!is_fail(ff)) {
                 private.update_regions(regionsListBox);
                 hrec.worldrange->unmap();
#
                 private.scripter.log(command);
              } else {
                 note(ff::message, priority='SEVERE',
                      origin='regionmanagergui.build_worldrange');
                 if (is_defined(name)) {
                    symbol_delete(name);
                 }
              }
            }
         }
      }
   }
#
   hrec.worldrange->map();
   return T;
}





const private.compareID := function (newID, oldID) 
{
   same := has_field(newID, 'sequence') && has_field(oldID, 'sequence') &&
              newID.sequence==oldID.sequence &&
           has_field(newID, 'pid') && has_field(oldID, 'pid') &&
              newID.pid ==oldID.pid &&
           has_field(newID, 'time') && has_field(oldID, 'time') &&
              newID.time==oldID.time &&
           has_field(newID, 'host') && has_field(oldID, 'host') &&
              newID.host==oldID.host &&
           has_field(newID, 'agentid') && has_field(oldID, 'agentid') &&
              newID.agentid==oldID.agentid;
   return same;
}


const private.copy_regions := function (ref hrec, ref regionsListBox)
{
  select := regionsListBox->selection();
  if (length(select)==0) {
     msg := 'You must select a region to copy';
     note(msg, priority='WARN', origin='regionmanagergui.copy_regions');
  } else if (length(select)>1) {
     msg := 'You must select only one region for copying';
     note(msg, priority='WARN', origin='regionmanagergui.copy_regions');
  } else {
     inName := regionsListBox->get(select[1])[1];
#
     if (has_field(hrec, 'copy')) {
         hrec.copy->map();
     } else {
        widgetset.tk_hold();
        hrec.copy := widgetset.frame(title='Copy', side='top',  
                               relief='raised', expand='both');
        hrec.copy->unmap();
        widgetset.tk_release();
        hrec.copy.regionName := [=];
        qrec.support.create_entry(hrec.copy.regionName, hrec.copy, 'Output region',
                                  grec.entryWidth);
        hrec.copy.action := widgetset.frame(hrec.copy, expand='x', side='left');
        hrec.copy.action.confirm := [=];
        qrec.support.create_confirm(hrec.copy.action.confirm, hrec.copy.action, 
                                    width=8, value=grec.confirm);
        private.create_go(hrec.copy.action, F, hlp='Copy region');
        private.create_dismiss(hrec.copy, hrec.copy.action, T, -1);
#
        whenever hrec.copy.action.go->press,hrec.copy.regionName->return do {
           outName := hrec.copy.regionName.get();
           confirm := hrec.copy.action.confirm.getvalue();
#
           if (private.string_check(outName, 'Output region')) {
              if (inName == outName) {
                 msg := 'Input and output region names are the same. No action taken';
                 note(msg, priority='WARN', origin='regionmanagergui.copy_regions');
              } else {
                 doIt := T;
                 qrec.support.isRegion_defined (outName, doIt, outName, confirm);
                 if (doIt) {
                    command := spaste(outName,':=', inName);
                    ff := eval(command);
                    if (!is_fail(ff)) {
                       hrec.copy->unmap();
                       private.update_regions(regionsListBox);
                    } else {
                       if (is_defined(outName)) {
                          symbol_delete(outName);
                       }
                    }
                 }
              }
           }
        }
        hrec.copy->map();
     }
  }
  return T;
}

const private.make_interactive_region := function (ref imagesListBox,
                                                   ref regionsListBox)
#
# Make a region interactively with the viewer
#
{
   wider krec;
   imageList := imagesListBox->selection();
#
   if (length(imageList) == 0) {
      msg := spaste('You must select an image as well to interactively make a region');
      note(msg, priority='WARN', origin='regionmanagergui.make_interactive_region');
   } else {
      local destroyIt;
      imageName := imagesListBox->get(imageList[1])
      tempImage := private.assignImage (destroyIt, imageName);
      if (is_fail(tempImage)) fail;
#
# Construct a unique tag for this image.  
#
      imageid := spaste(tempImage.id().time, tempImage.id().sequence);
#
      grec.f0->disable();
      ok := tempImage.view(activatebreak=T, hasdismiss=F);
      if (is_fail(ok)) {
         grec.f0->enable();
         fail;
      }
      grec.f0->enable();
#
# Reactivate the whenever for this image tool, or create it afresh
#
      if (has_field(krec.interactive, imageid)) {
         activate krec.interactive[imageid];
      } else {
         whenever tempImage->region do {
            root := $value.type;

# Capture and display the region now

            for (i in 1:1000000) {
               name := spaste(root, i);         
               if (!is_defined(name)) break;
            }
            command := spaste(name,':= $value.region');
            ff := eval(command);
            if (!is_fail(ff)) {
               private.update_regions(regionsListBox);
            } else {
               if (is_defined(name)) symbol_delete(name);
            }
         }
         krec.interactive[imageid] := last_whenever_executed();
#
# If the break button or done buttons of the image display are pressed, we don't
# listen for region events any more and destroy the temporary image tool
#
         whenever tempImage->breakfromviewer,tempImage->viewerdone do {
           if ($value==T) {
              deactivate krec.interactive[imageid];
           } else if ($value==F) {
              activate krec.interactive[imageid];
           }
           if (destroyIt) {
              ok := tempImage.done();
              if (is_fail(ok)) {
                 note(ok::message, priority='WARN',
                 origin='regionmanagergui.make_interactive_region');
              }
           }
         }
      }
   }
   return T;
}




const private.rename_regions := function (ref hrec, ref regionsListBox)
{
  select := regionsListBox->selection();
  if (length(select)==0) {
     msg := 'You must select a region to rename';
     note(msg, priority='WARN', origin='regionmanagergui.rename_regions');
  } else if (length(select)>1) {
     msg := 'You must select only one region for moving';
     note(msg, priority='WARN', origin='regionmanagergui.rename_regions');
  } else {
     inName := regionsListBox->get(select[1])[1];
#
     if (has_field(hrec, 'rename')) {
         hrec.rename->map();
     } else {
        widgetset.tk_hold();
        hrec.rename := widgetset.frame(title='Rename', side='top',  
                                 relief='raised', expand='both');
        hrec.rename->unmap();
        widgetset.tk_release();
        hrec.rename.regionName := [=];
        qrec.support.create_entry(hrec.rename.regionName, hrec.rename, 'Region name',
                                  grec.entryWidth);
        hrec.rename.action := widgetset.frame(hrec.rename, expand='x', side='left');
        hrec.rename.action.confirm := [=];
        qrec.support.create_confirm(hrec.rename.action.confirm, hrec.rename.action, 
                                    width=8, value=grec.confirm);
        private.create_go(hrec.rename.action, F, hlp='Rename region');
        private.create_dismiss(hrec.rename, hrec.rename.action, -1);
#
        whenever hrec.rename.action.go->press,hrec.rename.regionName->return do {
           outName := hrec.rename.regionName.get();
           confirm := hrec.rename.action.confirm.getvalue();
           if (private.string_check(outName, 'Region name')) {
              if (inName == outName) {
                 msg := 'Input and output region names are the same. No action taken';
                 note(msg, priority='WARN', origin='regionmanagergui.rename_regions');
              } else {
                 doIt := T;
                 qrec.support.isRegion_defined (outName, doIt, outName, confirm);
                 if (doIt) {
                    command := spaste(outName,':=', inName);
                    ff := eval(command);
                    if (!is_fail(ff)) {
                       hrec.rename->unmap();
                       symbol_delete(inName);
                       private.update_regions(regionsListBox);
                    } else {
                       if (is_defined(outName)) {
                          symbol_delete(outName);
                       }
                    }
                }
              }
           }
        }
        hrec.rename->map();
     }
  }
   return T;
}



const private.copy_to_clipboard := function (ref hrec, ref regionsListBox)
{
  select := regionsListBox->selection();
  if (length(select)==0) {
     msg := 'You must select a region to copy to the clipboard';
     note(msg, priority='WARN', origin='regionmanagergui.copy_to_clipboard');
  } else if (length(select)>1) {
     msg := 'You must select only one region for moving';
     note(msg, priority='WARN', origin='regionmanagergui.copy_to_clipboard');
  } else {
     name := regionsListBox->get(select[1])[1];
     dcb.copy(symbol_value(name));    
  }
  return T;
}


const private.paste_from_clipboard := function (ref hrec, ref regionsListBox)
{
  name := private.defaultname('region');
  if (!is_fail(name)) {
     cmd := spaste(name, ' := dcb.paste()');
     ok := eval(cmd);
     if (!is_fail(ok)) private.update_regions(regionsListBox);
  }
  return T;
}



const private.create_absrel := function (ref parent, width=0, relief='groove')
#
# Create the absolute/relative  coordinate selection button,
# add popuphelp and services. 
#
{
   labels := "Absolute RelRef RelCen";
   names := ['Absolute', 'Relative to ref. pixel', 'Relative to center'];
#
# Note these values must be the same as what regionmanager uses.
# Should really make a method there to give them to me.
#
   values := "abs relref relcen";
#
   hlp1 := 'Select absolute or relative coordinates';
   hlp2 := spaste('The coordinates you give can be either\n',
                  'absolute or relative.  If relative they\n',
                  'are relative to either the reference\n',
                  'pixel or the center pixel. Relative\n',
                  'coordinates are in the sense\n',
                  ' rel = abs - reference.  For example,\n',
                  'fractional coordinate relative to the\n',
                  'center pixel are in the range [-.5,.5]');
#
   parent.absrel := widgetset.optionmenu(parent=parent, labels=labels, 
                                         names=names, values=values, 
                                         hlp=hlp1, hlp2=hlp2,
                                         width=width, relief=relief,
                                         padx=9);
   parent.absrel.selectindex(1);
   return T;
}


const private.create_fraction := function (ref parent, width=0, relief='groove')
#
# Create the fractional coordinate selection button, add popuphelp, and
# service it.  Button is fixed width to avoid GUI jitter
# when its label changes.
#
{
   labels := "Pixel Fractional";
   values := [F, T];
   hlp1 := 'Select "pixel" or "fractional" coordinates';
   hlp2 := spaste('"Pixel" means that coordinates are in\n',
                  'pixels.  An absolute pixel of unity\n',
                  'is the bottom left corner of an image.\n',
                  '"Fractional" means that coordinates\n',
                  'are given as a fraction of the image\n',
                  'shape.  Absolute coordinates are in \n',
                  'the range [0,1]. 0 is the bottom left\n',
                  'corner and 1 is the top right corner\n',
                  'of an image');

   parent.fraction := widgetset.optionmenu(parent=parent, labels=labels, values=values,
                                           hlp=hlp1, hlp2=hlp2, 
                                           width=width, relief=relief,
                                           padx=9);
   parent.fraction.selectindex(1);
   return T;
}



const private.create_compound_action := function (ref parent, const append=F, 
                                                  const replaceBox=F, 
                                                  widthReplace=-1,
                                                  widthReplaceBox=-1,
                                                  widthAppend=-1,
                                                  widthCreate=-1)
#
# Create the replace and create buttons for compound regions
# and add popuphelp
#
{
   if (widthReplace < 0) {
      parent.replace := widgetset.button(parent, 'Replace');
   } else {
      parent.replace := widgetset.button(parent, 'Replace', width=widthReplace);
   }
   widgetset.popuphelp(parent.replace, 'Replace "Input regions" entry with selected regions');
   if (replaceBox) {
      if (widthReplaceBox < 0) {
         parent.replaceBox := widgetset.button(parent, 'ReplaceBox');
      } else {
         parent.replaceBox := widgetset.button(parent, 'ReplaceBox', width=widthReplaceBox);
      }
      widgetset.popuphelp(parent.replaceBox, 'Replace "Extension box" entry with selected region');
   }
   if (append) {
      if (widthAppend < 0) {
         parent.append := widgetset.button(parent, 'Append');
      } else {
         parent.append := widgetset.button(parent, 'Append', width=widthAppend);
      }
      widgetset.popuphelp(parent.append, 'Append selected region(s) to "Input region(s)" entry');
   }
   private.create_go(parent, T, widthCreate);
   return T;
}


const private.create_go := function (ref parent, const doSpace, width=-1, hlp='')
#
# Create the region action 'create' button
# and add popuphelp
{
   if (doSpace) {
      parent.space0 := widgetset.frame(parent, width=20, height=1, expand='none');
   }
   if (width < 0) {
      parent.go := widgetset.button(parent, 'Create',  type='action',
                                    borderwidth=grec.actionBorderWidth);
   } else {
      parent.go := widgetset.button(parent, 'Create', type='action',
                                    width=width, borderwidth=grec.actionBorderWidth);
   }
   if (strlen(hlp)==0) {
      widgetset.popuphelp(parent.go, 'Create region');
   } else {
      widgetset.popuphelp(parent.go, hlp);
   }
   return T;
}



const private.create_dismiss := function (ref grandParent, ref parent, 
                                          const doSpace, width=-1)
#
# Create the region action 'dismiss' button, add popuphelp and service
#
{
   if (doSpace) parent.space0 := widgetset.frame(parent, height=1, expand='x');
   if (width < 0) {
      parent.dismiss := widgetset.button(parent, 'Dismiss',
					 type='dismiss');
   } else {
      parent.dismiss := widgetset.button(parent, 'Dismiss',  type='dismiss',
					 width=width);
   }
   widgetset.popuphelp(parent.dismiss, 'Dismiss panel');
#
   whenever parent.dismiss->press do {
      grandParent->unmap();
   }
}

const private.defaultname := function (root)
{
   ok := F;
   for (i in 1:1000000) {
     name := spaste(root, i);         
     if (!is_defined(name)) {
        ok := T;
        break;
     }
   }
   if (ok) {
      return name;
   } else {
      return throw ('Could not find a default region name',
                    origin='regionmanager.defaultname');
   }
}

const private.dismiss := function ()
{
   wider private;
   grec.f0->unmap();
   if (has_field(hrec, 'quarter')) hrec.quarter->unmap();
   if (has_field(hrec, 'mask')) hrec.mask->unmap();
   if (has_field(hrec, 'box')) hrec.box->unmap();
   if (has_field(hrec, 'worldbox')) hrec.worldbox->unmap();
   if (has_field(hrec, 'worldpoly')) hrec.worldpoly->unmap();
   if (has_field(hrec, 'worldrange')) hrec.worldrange->unmap();
   if (has_field(hrec, 'union')) hrec.union->unmap();
   if (has_field(hrec, 'compl')) hrec.compl->unmap();
   if (has_field(hrec, 'diff')) hrec.diff->unmap();
   if (has_field(hrec, 'int')) hrec.int->unmap();
   if (has_field(hrec, 'ext')) hrec.ext->unmap();
   if (has_field(hrec, 'concat')) hrec.concat->unmap();
   if (has_field(hrec, 'save')) hrec.save->unmap();
   if (has_field(hrec, 'restore')) hrec.restore->unmap();
   if (has_field(hrec, 'delete')) hrec.delete->unmap();
#
   private.activate_deactivate(krec.save, F);
   private.activate_deactivate(krec.restore, F);
   private.activate_deactivate(krec.delete, F);
   self->dismissed();
}


const private.delete_regions := function (ref lrec, ref regionsListBox)
{
   delete_list := regionsListBox->selection();
   if (length(delete_list) > 0) {
      val lrec := [=];
#
# We must delete backwards !
#
      j := 1;
      for (i in length(delete_list):1) {
         item := regionsListBox->get(delete_list[i])[1];
         local temp_delete := symbol_value(item);
         symbol_delete(item);
         regionsListBox->delete(as_string(delete_list[i]));
#
         rec := [=];
         rec.name := item;
         rec.value := temp_delete;
         lrec[j] := rec;       
         j +:= 1;
      }
      private.update_regions(regionsListBox);
   } else {
      note('You have not selected a region', priority='WARN', 
           origin='regionmanagergui.delete_regions');
   }
   return T;
}




const private.edit_regions := function (ref jrec, ref irec, ref hrec,
                                        ref imagesListBox,
                                        ref regionsListBox)
{
   selectList := regionsListBox->selection();
   if (length(selectList) == 0) {
      msg := spaste('You must select a region to edit');
      note(msg, priority='WARN', origin='regionmanagergui.edit_regions');
   } else if (length(selectList) > 1) {
      msg := spaste('You can only edit one region at a time');
      note(msg, priority='WARN', origin='regionmanagergui.edit_regions');
   } else if (length(selectList)==1) {
      stuff := regionsListBox->get(selectList[1]);
      regionName := stuff[1];
      regionType := stuff[2];
#
      if (regionType==qrec.support.name_to_string('LCSLICER')) {
#
# Create or remap in the region creation panel. 
#
         private.build_pixel_regions(hrec, regionType, regionsListBox);
#
# Delete old information in entry boxes and replace by that
# appropriate to the region we have.  Note that although 
# LCSlicer can handle it, we don't allow different absRel and
# frac for different axes yet.
#
         tmpRegion := symbol_value(regionName);
         hrec.box.regionName.insert(regionName);
         hrec.box.blc.insert(tmpRegion.get('blc'));
         hrec.box.trc.insert(tmpRegion.get('trc'));
         hrec.box.inc.insert(tmpRegion.get('inc'));
         hrec.box.comment.insert(tmpRegion.get('comment'));
#
         value := tmpRegion.get('arblc');
         if (length(value) > 0) {
            absRelType := __regionmanager_rm.absreltype(value[1]);
            hrec.box.action.absrel.selectvalue(absRelType);
         } else {
            value := tmpRegion.get('artrc');
            absRelType := __regionmanager_rm.absreltype(value);
            if (length(value) > 0) {
               hrec.box.action.absrel.selectvalue(absRelType);
            } else {
               hrec.box.action.absrel.selectindex(1);
            }
         }
#
         value := tmpRegion.get('fracblc');
         if (length(value) > 0) {
            hrec.box.action.fraction.selectvalue(value[1]);
         } else {
            value := tmpRegion.get('fractrc');
            if (length(value) > 0) {
               hrec.box.action.fraction.selectvalue(value[1]);
            } else {
               value := tmpRegion.get('fracinc');
               if (length(value) > 0) {
                  hrec.box.action.fraction.selectvalue(value[1]);
               } else {
                  hrec.box.action.fraction.selectindex(1);
               }
            }
         }
      } else if (regionType==qrec.support.name_to_string('WCLELMASK')) {
#
# Create or remap in the region creation panel. 
#
         private.build_pixel_regions(hrec, regionType, regionsListBox);
#
# Replace entries
#
         tmpRegion := symbol_value(regionName);
         hrec.mask.regionName.insert(regionName);
         hrec.mask.expr.insert(tmpRegion.get('expr'));
         hrec.mask.comment.insert(tmpRegion.get('comment'));
      } else if (regionType==qrec.support.name_to_string('WCBOX')) {
#
# See if we have any images selected as well.  
#
         imageList := imagesListBox->selection();
         tmpRegion := symbol_value(regionName);
         pixelAxes := tmpRegion.get('pixelAxes');
         blc := tmpRegion.get('blc');
         trc := tmpRegion.get('trc');
         absRel := tmpRegion.get('absrel');
#
         if (length(imageList) == 0) {
#
# No selected images, just create the GUI from scratch and stick the entries in
#
            if (has_field(hrec, 'worldbox')) val hrec.worldbox := F;
            jrec.cSys := coordsys();
            if (is_fail(jrec.cSys)) fail;
            ok := jrec.cSys.fromrecord(tmpRegion.get('coordinates'));
            if (is_fail(ok)) fail;
#
            imageName := jrec.cSys.parentName();
            axisNames := jrec.cSys.names();
            axisUnits := jrec.cSys.units();
#
            private.build_worldbox (jrec, hrec, imageName, regionsListBox);
#
            hrec.worldbox.regionName.insert(regionName);
            hrec.worldbox.comment.insert(tmpRegion.get('comment'));
#
            nAxes := length(axisNames);
            nGivenAxes := length(pixelAxes);
            if (nGivenAxes > 0) {
               for (i in 1:nGivenAxes) {
                  j := pixelAxes[i];
                  fN := spaste('axis', j);
                  if (has_field(blc[i], 'orig')) {
                     text := blc[i].orig;
                     tmpQ := dq.quantity(text);
                     if (strlen(tmpQ.unit)==0) {
                        text := spaste(blc[i].value, blc[i].unit);
                     }
                  } else {
                     text := spaste(blc[i].value, blc[i].unit);
                  }
                  if (text ~ m/def/) text := '';         # Filter out default
                  hrec.worldbox.holder[fN]['blc']['entry'].insert(text);
#
                  if (has_field(trc[i], 'orig')) {
                     text := trc[i].orig;
                     tmpQ := dq.quantity(text);
                     if (strlen(tmpQ.unit)==0) {
                        text := spaste(trc[i].value, trc[i].unit);
                     }
                  } else {
                     text := spaste(trc[i].value, trc[i].unit);
                  }
                  if (text ~ m/def/) text := '';         # Filter out default
                  hrec.worldbox.holder[fN]['trc']['entry'].insert(text);
               }
            }
#
# Because GUI is rebuilt, buttons are set to "abs" to start with
#
            nAbsRel := length(absRel);
            if (nAbsRel > 0) {
               for (i in 1:nAbsRel) {
                  fN := spaste('axis', pixelAxes[i]);
                  absRelType := __regionmanager_rm.absreltype(absRel[i]);
                  hrec.worldbox.holder[fN]['buttons']['absrel'].selectvalue(absRelType);
               }
            }
         } else {
#
# Make the GUI with the CS from the selected image.  Then try
# and match axes in the region with axes in the CS and stick
# them in.  Pretty crude comparison is done (just axis names)
#
            if (has_field(hrec, 'worldbox')) val hrec.worldbox := F;
            imageName := imagesListBox->get(imageList[1])
#
            local destroyIt;
            tempImage := private.assignImage (destroyIt, imageName);
            if (is_fail(tempImage)) fail;
#
            jrec.cSys := tempImage.coordsys();
            if (is_fail(jrec.cSys)) fail;
            msg := spaste('Editing with image ', imageName, ' (',
                          tempImage.name(T), ')');
            note(msg, priority='WARN', origin='regionmanagergui.edit_regions');
            if (destroyIt) tempImage.done();
#
            private.build_worldbox (jrec, hrec, imageName, regionsListBox);
#
            hrec.worldbox.regionName.insert(regionName);
            hrec.worldbox.comment.insert(tmpRegion.get('comment'));
#
            axisNames := jrec.cSys.names();
            nAxes := length(axisNames);
#
            pixelAxesOld := tmpRegion.get('pixelAxes');
            cSysOld := coordsys();
            cSysOld.fromrecord(tmpRegion.get('coordinates'));
            axisNamesOld := cSysOld.names();
            nGivenAxesOld := length(pixelAxesOld);
            cSysOld.done();
#
            if (nGivenAxesOld > 0) {
               for (i in 1:nGivenAxesOld) {
                  j := pixelAxesOld[i];
                  iMatch := -1;
                  for (k in 1:nAxes) {
                     if (axisNamesOld[j] == axisNames[k]) {
                        iMatch := k;
                     }
                  }
                  if (iMatch != -1) {
                     fN := spaste('axis', iMatch);
                     if (has_field(blc[i], 'orig')) {
                        text := blc[i].orig;
                        tmpQ := dq.quantity(text);
                        if (strlen(tmpQ.unit)==0) {
                           text := spaste(blc[i].value, blc[i].unit);
                        }
                     } else {
                        text := spaste(blc[i].value, blc[i].unit);
                     }
                     if (text ~ m/def/) text := '';    # Filter out default
                     hrec.worldbox.holder[fN]['blc']['entry'].insert(text);
#
                     if (has_field(trc[i], 'orig')) {
                        text := trc[i].orig;
                        tmpQ := dq.quantity(text);
                        if (strlen(tmpQ.unit)==0) {
                           text := spaste(trc[i].value, trc[i].unit);
                        }
                     } else {
                        text := spaste(trc[i].value, trc[i].unit);
                     }
                     if (text ~ m/def/) text := '';    # FIlter out default
                     hrec.worldbox.holder[fN]['trc']['entry'].insert(text);
                     absRelType := __regionmanager_rm.absreltype(absRel[i]);
                     hrec.worldbox.holder[fN]['buttons']['absrel'].selectvalue(absRelType);
                  }
               }
            }
         }
      } else if (regionType==qrec.support.name_to_string('WCPOLYGON')) {
#
# See if we have any images selected as well.  
#
         imageList := imagesListBox->selection();
         tmpRegion := symbol_value(regionName);
         x := tmpRegion.get('x');
         y := tmpRegion.get('y');
#
         if (length(imageList) == 0) {
#
# No selected images, just create the GUI from scratch and stick the entries in
# using the CS embedded in the region itself.
#
            if (has_field(hrec, 'worldpoly')) val hrec.worldpoly := F;
#
            jrec.cSys := coordsys();
            ok := jrec.cSys.fromrecord(tmpRegion.get('coordinates'));
            if (is_fail(ok)) fail;
            coordinateTypes := jrec.cSys.coordinatetype();
            imageName := jrec.cSys.parentname();
            axisNames := jrec.cSys.names();
#
            private.build_worldpoly (jrec, hrec, imageName, regionsListBox);
#
            widgetset.tk_hold();
            nAxes := length(axisNames);
            pixelAxes := tmpRegion.get('pixelAxes');
            for (i in 1:nAxes) {
               fN := spaste('axis', i);
               if (i==pixelAxes[1]) {
                  hrec.worldpoly.xaxis[fN]->state(T);
               } else {
                  hrec.worldpoly.xaxis[fN]->state(F);
               }               
               if (i==pixelAxes[2]) {
                  hrec.worldpoly.yaxis[fN]->state(T);
               } else {
                  hrec.worldpoly.yaxis[fN]->state(F);
               }               
            }
#
# Get the right list of units for the x and y vectors and install them.
# Then select the actual units of the x and y vectors
#
            local list, width, fieldName;
#
            private.whichFormatList(list, width, fieldName, coordinateTypes[pixelAxes[1]]);
            hrec.worldpoly.xaxis.unitMenu.coordinateType := fieldName;
#
            hrec.worldpoly.xaxis.unitMenu.disabled(F);
            hrec.worldpoly.xaxis.unitMenu.replace(labels=list, width=width);
            private.add_unit_to_menu_and_list (hrec.worldpoly.xaxis.unitMenu,
                                               x.unit, list, width, 
                                               fieldName);
#
            private.whichFormatList(list, width, fieldName, coordinateTypes[pixelAxes[2]]);
            hrec.worldpoly.yaxis.unitMenu.coordinateType := fieldName;
            hrec.worldpoly.yaxis.unitMenu.disabled(F);
            hrec.worldpoly.yaxis.unitMenu.replace(labels=list, width=width);
            private.add_unit_to_menu_and_list (hrec.worldpoly.yaxis.unitMenu,
                                               y.unit, list, width, 
                                               fieldName);
         } else {
#
# Make the GUI with the CS from the selected image.  Then try
# and match axes in the region with axes in the CS and stick
# them in.  Pretty crude comparison is done (just axis names)
#
            if (has_field(hrec, 'worldpoly')) val hrec.worldpoly := F;
            imageName := imagesListBox->get(imageList[1])
#
            local destroyIt;
            tempImage := private.assignImage (destroyIt, imageName);
            if (is_fail(tempImage)) fail;
#
            jrec.cSys := tempImage.coordsys();   
            msg := spaste('Editing with image ', imageName, ' (',
                          tempImage.name(T), ')');
            note(msg, priority='WARN', origin='regionmanagergui.edit_regions');
            if (destroyIt) tempImage.done();
#
            private.build_worldpoly (jrec, hrec, imageName, regionsListBox);
#
            widgetset.tk_hold();
            coordinateTypes := jrec.cSys.coordinatetype();
            axisNames := jrec.cSys.names();
            nAxes := length(axisNames);
#
# Get old pixel axes and axis names
#
            pixelAxesOld := tmpRegion.get('pixelAxes');
            oldCSys := coordsys();
            ok := oldCSys.fromrecord(tmpRegion.get('coordinates'));
            if (is_fail(ok)) fail;
            axisNamesOld := oldCSys.names();
#
            for (i in 1:nAxes) {
               fN := spaste('axis', i);
               hrec.worldpoly.xaxis[fN]->state(F);
               hrec.worldpoly.yaxis[fN]->state(F);
            }
#
            local list, width, fieldName;
            for (i in 1:2) {
               j := pixelAxesOld[i];
               iMatch := -1;
               for (k in 1:nAxes) {
                  if (axisNamesOld[j] == axisNames[k]) {
#
# Found a match
#
                     fN := spaste('axis', k);
                     if (i==1) {
                        hrec.worldpoly.xaxis[fN]->state(T);
#
                        private.whichFormatList(list, width, fieldName, 
                                                coordinateTypes[k]);
                        hrec.worldpoly.xaxis.unitMenu.coordinateType := fieldName;
                        hrec.worldpoly.xaxis.unitMenu.disabled(F);
                        hrec.worldpoly.xaxis.unitMenu.replace(labels=list, width=width);
                        private.add_unit_to_menu_and_list (hrec.worldpoly.xaxis.unitMenu,
                                                           x.unit, list, width,
                                                           fieldName);
                     } else {
                        hrec.worldpoly.yaxis[fN]->state(T);
#
                        private.whichFormatList(list, width, fieldName, 
                                                coordinateTypes[k]);
                        hrec.worldpoly.yaxis.unitMenu.coordinateType := fieldName;
                        hrec.worldpoly.yaxis.unitMenu.disabled(F);
                        hrec.worldpoly.yaxis.unitMenu.replace(labels=list, width=width);
                        private.add_unit_to_menu_and_list (hrec.worldpoly.yaxis.unitMenu,
                                                           y.unit, list, width,
                                                           fieldName);
                     }
                  }
               }
            }
         }
#
         hrec.worldpoly.regionName.insert(regionName);
         hrec.worldpoly.xvector.insert(x.value);
         hrec.worldpoly.yvector.insert(y.value);
         hrec.worldpoly.comment.insert(tmpRegion.get('comment'));
#
# Because GUI is rebuilt, button is set to "abs" to start with
#
         absRel := tmpRegion.get('absrel');
         absRelType := __regionmanager_rm.absreltype(absRel);
         hrec.worldpoly.action.absrel.selectvalue(absRelType);
         widgetset.tk_release();
      } else if (regionType==qrec.support.name_to_string('WCELLIPSOID')) {
         note('Not yet implemented', priority='WARN', 
              origin='regionmanagergui.edit_regions');
      } else if (regionType==qrec.support.name_to_string('WCUNION') ||
                 regionType==qrec.support.name_to_string('WCCOMPLEMENT') || 
                 regionType==qrec.support.name_to_string('WCEXTENSION') || 
                 regionType==qrec.support.name_to_string('WCDIFFERENCE') || 
                 regionType==qrec.support.name_to_string('WCINTERSECTION') || 
                 regionType==qrec.support.name_to_string('WCCONCATENATION')) {
#
# Create or remap in the region creation panel. 
#
         private.build_compound_regions(irec, hrec, regionType, regionsListBox);
#
         theField := '';
         if (regionType==qrec.support.name_to_string('WCUNION')) {
            theField := 'union';
         } else if (regionType==qrec.support.name_to_string('WCCOMPLEMENT')) {
            theField := 'compl';
         } else if (regionType==qrec.support.name_to_string('WCEXTENSION')) {
            theField := 'ext';
         } else if (regionType==qrec.support.name_to_string('WCDIFFERENCE')) {
            theField := 'diff';
         } else if (regionType==qrec.support.name_to_string('WCINTERSECTION')) {
            theField := 'int';
         } else if (regionType==qrec.support.name_to_string('WCCONCATENATION')) {
            theField := 'concat';
         }
#
# Replace information.  I store the region names used to make the regions
# in fields in hrec.  If a compound region was made with the command line,
# it can't know this.  If the GUI is destroyed, this is lost too.
#
         tmpRegion := symbol_value(regionName);
         hrec[theField]['regionName'].insert(regionName);         
         hrec[theField]['comment'].insert(tmpRegion.get('comment'));
#
         if (has_field(irec[theField], regionName)) {
            if (has_field(irec[theField][regionName], 'inputRegions')) {
               hrec[theField]['inRegions'].insert(spaste(irec[theField][regionName]['inputRegions']));
            }
         }
#
         if (regionType==qrec.support.name_to_string('WCEXTENSION') ||
             regionType==qrec.support.name_to_string('WCCONCATENATION')) {
            if (has_field(irec[theField], regionName)) {
               if (has_field(irec[theField][regionName], 'extBox')) {
                  hrec[theField]['extBox'].insert(irec[theField][regionName]['extBox']);
               }
            }
         }
      }
   }
   return T;
}


const private.input_regions_check := function (ref regions, const nmin, const nmax=-1) 
#
# Check that the string contains a valid list of regions
#
{
   if (!private.string_check(regions, 'Input regions')) {
      return F;
   }
#
   txt := regions;
   txt =~ s/^\s*//;              # remove leading blanks
   txt =~ s/\s*$//;              # remove trailing blanks
   txt =~ s/\[//g;               # remove leading "["
   txt =~ s/\]//g;               # remove trailing "["
   txt =~ s/^\s*//;              # remove leading blanks
   txt =~ s/\s*$//               # remove trailing blanks
   txt =~ s/,/ /g;               # replace commas by 1 space
   txt =~ s/\s */ /g;            # replace white space by 1 space
#
   txt2 := split(txt);           # split into vector
   if (nmin > 0) {
      if (length(txt2) < nmin) {
         msg := spaste('There must be at least ', nmin, ' input regions');
         note(msg, priority='WARN', origin='regionmanagergui.input_regions_check');
         return F;
      }
   }
   if (nmax > 0) {
      if (length(txt2) > nmax) {
         msg := spaste('There must be no more than ', nmax, ' input regions');
         note(msg, priority='WARN', origin='regionmanagergui.input_regions_check');
         return F;
      }
   }
#
   txt3 := txt2;
   for (i in 1:length(txt2)) {              
      if (!is_defined(txt2[i])) {
         msg := spaste('Region ', txt2[i], ' does not exist');
         note(msg, priority='WARN', origin='regionmanagergui.input_regions_check');
         return F;
      }
      if (i < length(txt2)) {                 # Put it back together and
         txt3[i] := spaste(txt2[i], ',');     # add comma separator
      }

   }
   val regions := txt3;
#
   return T;
}


const private.restore_regions := function (ref krec,
                                           ref hrec, 
                                           ref imagesListBox,
                                           ref regionsListBox)
{
   imageList := imagesListBox->selection();
   nImages := length(imageList);
   item := '';
   if (nImages>0) item := imagesListBox->get(imageList[1]);
#
   if (!has_field(hrec, 'restore')  ||
       (has_field(hrec, 'restore') && 
        is_boolean(hrec.restore) && hrec.restore==F)) {
      hrec.restore := widgetset.restoreregions(globalrestore=T);
      if (is_fail(hrec.restore)) {
         msg := spaste('Failed to make restoreregions widget because ',
                       hrec.restore::message);
         note (msg, priority='SEVERE', 
               origin='regionmanagergui.restore_regions');
         hrec.restore := F;
         return F;
      }      
      if (strlen(item)>0) hrec.restore.settable(item);
   } else {
      if (strlen(item)>0) hrec.restore.settable(item);
      hrec.restore.gui();
   }
#      
   whenever imagesListBox->select do {
      item := private.selection_string(imagesListBox);
      hrec.restore.settable(item);
   }
   idx := length(krec.restore) + 1;
   krec.restore[idx] := last_whenever_executed();
#
   whenever hrec.restore->restored do {
      private.update_regions(regionsListBox);
   }
   whenever hrec.restore->dismissed do {
      private.activate_deactivate (krec.restore, F);
   }
#
   return T;
}



const private.save_regions := function (ref krec,
                                        ref hrec, 
                                        ref imagesListBox,
                                        ref regionsListBox)
{
   imageList := imagesListBox->selection();
   nImages := length(imageList);
   tableName := '';
   if (nImages>0) tableName := imagesListBox->get(imageList[1]);
#
   if (!has_field(hrec, 'save')  ||
       (has_field(hrec, 'save') && is_boolean(hrec.save) && hrec.save==F)) {
      hrec.save:= widgetset.saveregions(globalsave=T, table=tableName, 
                                        changenames=T);
      if (is_fail(hrec.save)) {
         msg := spaste('Failed to make saveregions widget because ',
                       hrec.save::message);
         note (msg, priority='SEVERE', 
               origin='regionmanagergui.save_regions');
         hrec.save := F;
         return F;
      }      
   } else {
      if (strlen(tableName)>0) {
         ok := hrec.save.settable(tableName);
         if (is_fail(ok)) {
            msg := spaste('Failed to save regions because ',
                           ok::message);
            note (msg, priority='SEVERE', 
                  origin='regionmanagergui.save_regions');
            return F;
         }
      }
      ok := hrec.save.gui();
   }
#
# Set any selected regions
#
   saveList := regionsListBox->selection();
   nSaveRegions := length(saveList);
   if (nSaveRegions > 0) {
      names := "";
      for (i in 1:nSaveRegions) {
         names[i] := regionsListBox->get(saveList[i])[1];
      }
      hrec.save.setregions(names);
   }
#      
   whenever imagesListBox->select do {
      item := private.selection_string(imagesListBox);
      hrec.save.settable(item);
   }
   idx := length(krec.save) + 1;
   krec.save[idx] := last_whenever_executed();
#
   whenever regionsListBox->select do {
      saveList := regionsListBox->selection();
      nSaveRegions := length(saveList);
      names := "";
      for (i in 1:nSaveRegions) {
         names[i] := regionsListBox->get(saveList[i])[1];
      }
      hrec.save.setregions(names);
   }
   idx := length(krec.save) + 1;
   krec.save[idx] := last_whenever_executed();
#
   whenever hrec.save->dismissed do {
      private.activate_deactivate (krec.save, F);
   }
#
   return T;
}


const private.tabledelete_regions := function (ref krec,
                                               ref hrec, 
                                               ref imagesListBox,
                                               ref regionsListBox)
{
   imageList := imagesListBox->selection();
   nImages := length(imageList);
   item := '';
   if (nImages>0) item := imagesListBox->get(imageList[1]);
#
   if (!has_field(hrec, 'delete')  ||
       (has_field(hrec, 'delete') && is_boolean(hrec.delete) && hrec.delete==F)) {
      hrec.delete := widgetset.deleteregions(source='table');
      if (is_fail(hrec.delete)) {
         msg := spaste('Failed to make deleteregions widget because ',
                       hrec.delete::message);
         note (msg, priority='SEVERE', 
               origin='regionmanagergui.tabledelete_regions');
         hrec.delete := F;
         return F;
      }      
   } else {
      if (strlen(item)>0) hrec.delete.settable(item);
      if (strlen(item)>0) hrec.delete.settable(item);
      hrec.delete.gui();
   }
#      
   whenever imagesListBox->select do {
      item := private.selection_string(imagesListBox);
      hrec.delete.settable(item);
   }
   idx := length(krec.delete) + 1;
   krec.delete[idx] := last_whenever_executed();
#
   whenever hrec.delete->dismissed do {
      private.activate_deactivate(krec.delete, F);
   }
#
   return T;
}


const private.updateUnitsMenu := function (idx, coordinateTypes, axisUnits, unitMenu)
{
   local fieldName, list, width;
   private.whichFormatList(list, width, fieldName, coordinateTypes[idx]);
   unitMenu.disabled(F);
   unitMenu.replace(labels=list, width=width);
   if (strlen(axisUnits[idx])>0) {
      unitMenu.selectlabel(axisUnits[idx]);
   }
#
   unitMenu.coordinateType := fieldName;
}




const private.quantity_check := function (ref q, const text, 
                                          const defaultUnit)
#
# This function is for input from entry boxes which is expected to be 
# one quantity. If there is no unit, we put in a default. If text
# is empty, we put in '0default'
#
{
   if (strlen(text)==0) {
      val q := defaultcoordsyssupport.valuetoquantum('0default');
      return T;
   }
#
   if (is_defined(text)) {
      val q := symbol_value(text);
      if (!is_quantity(q)) {
         msg := spaste('"', text, '" is not a valid quantity');
         note(msg, priority='WARN', origin='regionmanagergui.quantity_check');             
         return F;
      }
   } else {
      val q := defaultcoordsyssupport.valuetoquantum(text, defaultUnit);
      if (is_fail(q)) {
         msg := spaste('"', text, '" is not a valid quantity');
         note(msg, priority='WARN', origin='regionmanagergui.quantity_check');             
         return F;
      }
      if (defaultcoordsyssupport.lengthofquantum(q) !=1) {
         msg := spaste('"', text, '" is not a valid single quantity');
         note(msg, priority='WARN', origin='regionmanagergui.quantity_check');             
         return F;
      }
   }
#
   return T;
}


const private.region_type := function(const region)
# 
# What type of region is this ?  Returns a string
# suitable for formatting to the user
# 
{
   if (!is_region(region)) {
      return 'not region';
   }
 
   name := region.get('name');
   if (is_fail(name)) {  
      return 'missing';
   }
   return qrec.support.name_to_string(name);
}
 

const private.selection_string := function (const listBox, const nMax=-1)
#
# Get the list of selected region names. Then convert them
# to one string.  This is used as input to compound regions
#
{
   local list;
   list := listBox->selection();
   if (length(list) == 0) return '';
#  
# get returns a record.  r[1] is the region names
# and r[2] is the region types
#
   str := '';
   str := listBox->get(list[1])[1];
   if (length(list)==1) return str;
#
   if (nMax<0) {
      for (i in 2:length(list)) {
         item := listBox->get(list[i])[1];
         str := spaste(str, ', ', item);
      }
   } else {
      for (i in 2:length(list)) {
         if (i > nMax) break;
         item := listBox->get(list[i])[1];
         str := spaste(str, ', ', item);
      }
   }
   return str;
}



const private.parse_polygonVector := function (ref quant, const valueText, 
                                               const unitText, const axisName)
#
# Allowed are:
#     - valueText is a quantity 
#     - valueText is a numeric vector and unitText a valid unit
#
# Not allowed any more is "1deg 2deg 3deg" as nobody would bother
# typing this anyway
#
{
   local q;
   if (is_quantity(valueText)) {
      q := valueText;
   } else {
      q := dq.quantity(valueText, unitText);
      if (is_fail(q)) {
         msg := spaste('The values and unit for the ', axisName, 
                       ' vector do not constitute a valid quantity');
         note(msg, priority='WARN', origin='regionmanagergui.parse_polygonVector');
         return F;
      }
   }
#
# Now check that the quantity we have made is ok.
#
   if (has_field(q, 'value') && has_field(q, 'unit')) {
#
# Value + unit
#
      v := q.value;
      if (length(v) < 3) {
         msg := spaste('Need at least 3 vertices for the ', axisName, 
                       ' vector');
         note(msg, priority='WARN', origin='regionmanagergui.parse_polygonVector');
         return F;
      }
   } else {
#
# Vector of {value+unit}
#
      nQ := length(q);
      if (nQ < 3) {
         msg := spaste('Need at least 3 vertices for the ', axisName, 
                       ' vector');
         note(msg, priority='WARN', origin='regionmanagergui.parse_polygonVector');
         return F;
      }
#
# See if units all the same.  Convert to quantity of a vector
#
      v := array(1.0, nQ);
      unitOne := q[1].unit;      
      v[1] := q[1].value;
      for (i in 2:nQ) {
         if (q[i].unit != unitOne) {
            msg := spaste('The units of the ', axisName, ' vector must all be the same');
            note(msg, priority='WARN', origin='regionmanagergui.parse_polygonVector');
            return F;
         }
#
         v[i] := q[i].value;
      }
      q := dq.quantity(v, unitOne);
   }
#
   val quant := q;
#
   return T;
}


const private.regions_type_help := function (const name, const idx)
{
   return grec.region_helps[idx+1];
}

    

const private.string_check := function (const str, const thing, 
                                        single=F, canBeEmpty=F)
{
   if (!is_string(str)) {
      msg := spaste('Input for "', thing, '" is not a string');
      return F;
   }
   if (!canBeEmpty) {
      if (strlen(str)==0) {
         msg := spaste('Input for "', thing, '" is empty');
         note(msg, priority='WARN', origin='regionmanagergui.string_check');
         return F;
      }
   }
   if (single) {
      if (length(split(str)) > 1) {
         msg := spaste('Input for "', thing, '" cannot have white space');
         note(msg, priority='WARN', origin='regionmanagergui.string_check');
         return F;
      }
   }
   return T;
}


const private.strip_string_field := function (ref list, field)
{
   list2 := "";
   j := 1;
   for (i in 1:length(list)) {
      if (list[i] != field) {
         list2[j] := list[i];
         j +:= 1;
      }
   }
#
   val list := list2;
   return T;
}


const private.undelete_regions := function (ref lrec, ref hrec, ref regionsListBox)
{
   nRegions := length(lrec);
   if (nRegions==0) {
      note ('There are no regions available for "undeletion"', priority='WARN',
            origin='regionmanagergui.undelete_regions');
      return T;
   }
#      
   if (has_field(hrec, 'undelete')) {
      hrec.undelete->unmap();
      hrec.undelete := F;
   }
#
   widgetset.tk_hold();
   hrec.undelete := widgetset.frame(title='Undelete', side='top',  
                              relief='raised', expand='both');
   hrec.undelete->unmap();
   widgetset.tk_release();
#
   hrec.undelete.regionsListBox := [=];
   qrec.support.build_listBoxes (hrec.undelete.regionsListBox, 
                                 hrec.undelete, height=5, width=12,
                                 expand='x');
   stuff := array('', 2, nRegions);
   for (i in 1:nRegions) {
      stuff[1,i] := lrec[i].name;
      stuff[2,i] := qrec.support.name_to_string(lrec[i].value.get('name'));
   }
   hrec.undelete.regionsListBox->insert(stuff);
   hrec.undelete.regionsListBox->see('start');
#
   hrec.undelete.action := widgetset.frame(hrec.undelete, expand='x', side='left');
   hrec.undelete.action.confirm := [=];
   qrec.support.create_confirm(hrec.undelete.action.confirm, hrec.undelete.action, width=8,
                               value=grec.confirm);
   hrec.undelete.action.undeleteall := widgetset.button(hrec.undelete.action, 'Undelete all');
   widgetset.popuphelp(hrec.undelete.action.undeleteall, 'Undelete all regions');
   hrec.undelete.action.undelete := widgetset.button(hrec.undelete.action, 'Undelete');
   widgetset.popuphelp(hrec.undelete.action.undelete, 'Undelete selected region(s)');
   private.create_dismiss(hrec.undelete, hrec.undelete.action, T, -1);
#
   regions := [=];
#
   whenever hrec.undelete.action.undelete->press,
            hrec.undelete.action.undeleteall->press do {
      regionsList := [];
      doAll := F;
      if ($agent == hrec.undelete.action.undeleteall) {
         n := length(lrec);
         if (n > 0) regionsList := (1:n) - 1;
         doAll := T;
      } else {
         regionsList := hrec.undelete.regionsListBox->selection();
      }
      nRegions := length(regionsList);
      if (nRegions==0) {
         note ('You have not selected any regions', priority='WARN',
               origin='regionmanagergui.undelete_regions');
      } else {
         ok := T;
         confirm := hrec.undelete.action.confirm.getvalue();
         for (i in 1:nRegions) {
            doIt := T;
            name := lrec[i].name;
            qrec.support.isRegion_defined (name, doIt, lrec[i].name, T);
            if (doIt) {
               global __regionmanager_region := lrec[i].value;
               cmd := spaste(name, ' := __regionmanager_region');
               ff := eval(cmd);
               if (is_fail(ff)) ok := F;
            }
         }
         private.update_regions(grec.regionsListBox);
         if (ok) hrec.undelete->unmap();
      }
   }
   whenever hrec.undelete.action.dismiss->press do {
      hrec.undelete->unmap();
   }
   hrec.undelete->map();
   return T;
}



const private.unit_checker := function (item, labels, quantaserver)
{
   ok := T;
   if (strlen(item)==0) {
      ok := F;
   } else if (!quantaserver.check(item)) {
      msg := spaste('Unit "', item, '", is invalid');
      note (msg, priority='WARN', 
            origin='regionmanagergui.unit_checker');
      ok := F;
   } else if (!quantaserver.compare(item,labels[1])) {
      msg := spaste('Unit "', item, '", is inconsistent with axis type');
      note (msg, priority='WARN', 
            origin='regionmanagergui.unit_checker');
      ok := F;
   }
   return ok;
}


const private.update_images := function (ref listBox)
{
   list1 := imagetools(showclosed=F);
   list2 := imagefiles();
   list := [list1, list2];
#
   widgetset.tk_hold();
   listBox->delete('start', 'end');
   if (length(list) == 0) {
      widgetset.tk_release();
      return T;
   }
#
   listBox->insert(list);
   listBox->see('start');
   widgetset.tk_release();
}

const private.update_regions := function (ref listBox)
{
   doSort := T;
   list := private.what_regions(doSort);
#
   widgetset.tk_hold();
   listBox->delete('start', 'end');
#
   n := length(list);
   if (n==0) {
      widgetset.tk_release();
      return T;
   }
#
   stuff := array('',2,n);
   for (i in 1:n) {
      local tt := symbol_value(list[i]);
#
      stuff[1,i] := list[i];
      stuff[2,i] := private.region_type(tt);
   }
#
   listBox->insert(stuff);
   listBox->see('end');
   widgetset.tk_release();
   return T;
}


const private.update_types := function (ref listBox)
{
   widgetset.tk_hold();
   listBox->delete('start', 'end');
   list := private.what_functions();
   listBox->insert(list);
   listBox->see('start');
   widgetset.tk_release();
}




const private.update_units := function (menu)
#
# Generally, whenever the units extendoptionmenus are replaced, then the
# user has extended it.  Recover their new list of units
# and save them in the private record.  There is the situation
# also that the menu may be replaced by an empty one (actually, one
# with just "..." in it).  In that case, don't update the lists !
#
{
   whenever menu->replaced do {
      list := menu.getlabels()
      if (length(list)>1) {
         private.strip_string_field(list, '...');
#
         fieldName := ref $agent.coordinateType;
         wider grec;
         grec.format[fieldName]['list'] := list;
      }
   }
   return T;
}


const private.what_functions := function()
#
# Returns the names of the functions that can be
# used to make regions in the GUI.  If you change this
# list you must change function build_regions too
# 
# FOr the moment, this function is only ever called once
# so it's not really necessary to fuss about whether
# the helps have been made or not.  But it might change ...
#
{
   wider grec;
   makeHelps := T;
   if (length(grec.region_helps) > 1) makeHelps := F;
#
   list := "";
   i := 1;
   if (makeHelps) {
      grec.region_helps[i] := 
          spaste('Takes the central quarter by area\n',
                 'of the first two dimensions and\n',
                 'all pixels of higher dimensions');
   }
   list[i] := 'quarter'; i +:= 1;
#
   if (makeHelps) {
      grec.region_helps[i] := 
          spaste('An optionally strided box\n',
                 'defined in pixel coordinates');
   }
   list[i] := qrec.support.name_to_string('LCSLICER'); i +:= 1;
#
   if (makeHelps) {
      grec.region_helps[i] := 'Makes a LEL mask region';
   }
   list[i] := 'mask'; i +:= 1;
#
   if (makeHelps) {
      grec.region_helps[i] := 
          spaste('A box defined in world coordinates\n',
                 'Units of "pix" and "frac" are also available\n',
                 'You must select an image before you can\n',
                 'make a world region');
   }
   list[i] := qrec.support.name_to_string('WCBOX'); i +:= 1;
#
   if (makeHelps) {
      grec.region_helps[i] := 
          spaste('A polygon defined in world coordinates\n',
                 'Units of "pix" and "frac" are also available\n',
                 'You must select an image before you can\n',
                 'make a world region');
   }
   list[i] := qrec.support.name_to_string('WCPOLYGON'); i +:= 1;
#
   if (makeHelps) {
      grec.region_helps[i] := 
          spaste('A range defined in world coordinates\n',
                 'Units of "pix" and "frac" are also available\n',
                 'You must select an image before you can\n',
                 'make a world region');
   }
   list[i] := 'world range'; i +:= 1;
#
   if (makeHelps) {
      grec.region_helps[i] := 
          spaste('The region is made interactively with an image \n',
                 'and the viewer display');
   }
   list[i] := 'interactive'; i +:= 1;
#
   if (makeHelps) {
      grec.region_helps[i] := '';
   }
   list[i] := ''; i +:= 1;
#
   if (makeHelps) {
      grec.region_helps[i] := 
          spaste('Takes the union of 2 or more regions');
   }
   list[i] := qrec.support.name_to_string('WCUNION'); i +:= 1;
#
   if (makeHelps) {
      grec.region_helps[i] := 
          spaste('Takes the complement of 1 region');
   }
   list[i] := qrec.support.name_to_string('WCCOMPLEMENT'); i +:= 1;
#
   if (makeHelps) {
      grec.region_helps[i] := 
          spaste('Takes the difference of 2 regions.  The\n',
                 'order of the regions is important');
   }
   list[i] := qrec.support.name_to_string('WCDIFFERENCE'); i +:= 1;
#
   if (makeHelps) {
      grec.region_helps[i] := 
          spaste('Takes the intersection of 2 or more regions');
   }
   list[i] := qrec.support.name_to_string('WCINTERSECTION'); i +:= 1;
#
   if (makeHelps) {
      grec.region_helps[i] := 
          spaste('Extends a region over extra dimensions\n',
                 'You specify the extension with a world box');
   }
   list[i] := qrec.support.name_to_string('WCEXTENSION'); i +:= 1;
#
   if (makeHelps) {
      grec.region_helps[i] := 
          spaste('Concatenates regions along one extra \n',
                 'dimension. You specify the concatenation\n',
                 'axis with a 1-D world box');
   }
   list[i] := qrec.support.name_to_string('WCCONCATENATION'); i +:= 1;
#
   return list;
}


const private.what_regions := function(doSort=T)
#
# We filter the full list of symbols ourselves because
# if I pass in is_region, the damn thing sorts them
# But this is next to useless because symbol is not
# time ordered !
#
{
   list := symbol_names();
   n := length(list);
   if (n==0) return [];
#
   list2 := "";
   j := 0;
   for (i in 1:n) {
      if (is_region(symbol_value(list[i]))) {
         if (!(list[i] ~ m/^_/)) {       # Strip symbol with leading underscore
            j +:= 1;            
            list2[j] := list[i];
         }
      }
   }
#
   if (length(list2)==0) return list2;
   if (doSort) {
      return sort(list2);
   } else {
      return list2;
   }
}


const private.whichFormatList := function (ref list, ref width, ref fieldName,
                                           coordinateType)
{
   if (has_field(grec.format, coordinateType)) {
      val list := grec.format[coordinateType]['list'];
      val width := grec.format[coordinateType]['width'];
      val fieldName := coordinateType;
   } else {
      val list := grec.format.Unknown.list;  
      val width := grec.format.Unknown.width;
      val fieldName := 'Unknown';
   }
   return T;
}


const self.setsendbreakstate := function (enable=T) 
{
   wider grec;
   grec.f0.f2.send->disabled(!enable);
   grec.f0.f2.senddismiss->disabled(!enable);
   grec.f0.f2.break->disabled(!enable);
   return T;
}

} 
