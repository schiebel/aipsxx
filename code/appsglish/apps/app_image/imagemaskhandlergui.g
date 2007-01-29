# imagemaskhandlergui.g: GUI for image.maskhandler
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
#   $Id: imagemaskhandlergui.g,v 19.2 2004/08/25 00:58:04 cvsmgr Exp $
#
#
 
pragma include once

include 'messageline.g'
include 'note.g'
include 'helpmenu.g'
include 'widgetserver.g'
include 'image.g'
include 'serverexists.g'


const imagemaskhandlergui := subsequence (ref parent=F, imageobject, widgetset=dws)
{
   if (!have_gui()) {
      return throw('No Gui is available, possibly the  DISPLAY environment variable is not set',
                   origin='imagemaskhandlergui.g');
   }
   if (!is_image(imageobject)) {
      return throw('The value of the "image" variable is not a valid image object',
                    origin='imagemaskhandlergui.g');
   }
#
   prvt := [=];
   prvt.ge := widgetset.guientry();         # GUI entry server
   if (is_fail(prvt.ge)) fail;
   prvt.standalone := (is_boolean(parent) &&  parent==F);
#
   prvt.image := [=];              # The image stuff
   prvt.image.object := [=];       # The actual image object
   prvt.image.masks := "";         
   prvt.image.defaultmask := "";    
#
   prvt.image2 := [=];             
   prvt.image2.object := [=];
   prvt.image2.name := '';
   prvt.image2.masks := "";         
   prvt.image2.defaultmask := "";    


###
   const prvt.defaultname := function (root, old, auto)
   {
      if (auto) {    
         ok := F;
         for (i in 1:1000000) {
           name := spaste(root, i);
#
           current := ref prvt.image.masks;
           match := F;
           for (thing in current) {
              if (thing==name) {
                 match := T;
                 break;
              }
           }
           if (!match) {
              ok := T;
              break;
           }
         }
         if (ok) {  
            return name;
         } else {
            return throw ('Could not find a default mask name', 
                          origin='maskhandlergui.defaultname');
         }
      } else {
         return old;
      }
   }   
   

###
   const prvt.getmasks := function (ref parent)
   {
      parent.masks := unset;
      parent.defaultmask := unset;
      parent.masks := parent.object.maskhandler('get');
      if (is_fail(parent.masks)) fail;
      parent.defaultmask := parent.object.maskhandler('default');
      if (is_fail(parent.defaultmask)) fail;     
      return T;
   }

   const prvt.getlist := function (ref listbox, single=T, none=F)
   {
      sel := listbox->selection() + 1;         # One relative for insertion
      n := length(sel);
      if (n==0) {
         if (!none) {
            note('You have not selected any masks', priority='WARN',
                 origin='imagemaskhandlergui.getlist');
            return F;
         }
      } else {
         if (single) {
            if (n>1) {
               note('You can only select one mask for this operation', priority='WARN',
                    origin='imagemaskhandlergui.getlist');
               return F;
            }
         }
      }
      return sel;
   }

   const prvt.updatelistbox := function (ref listbox, ref masks)
   {
      listbox->delete('start', 'end');
      listbox->clear('start', 'end');
      listbox->insert(masks);
      return T;
   }

   const prvt.setdefaultlabel := function (ref label)
   {
      default := prvt.image.defaultmask;
      txt := '';
      if (strlen(default)>0) {
         txt := paste('Default : ', default);
      } else {
         txt := 'Default : none';
      }
      label->text(txt);
   }



### Constructor

   prvt.image.object := imageobject;
#
   tk_hold();
   title := spaste('imagemaskhandler(', prvt.image.object.name(strippath=T), ')');

   prvt.f0 := widgetset.frame(parent, expand='both', side='top', 
                              relief='raised', title=title);
   prvt.f0->unmap();
   tk_release();
   whenever prvt.f0->resize do {
      self->resize();
   }
#
   if(prvt.standalone) {
     prvt.f0.menubar := widgetset.frame(prvt.f0, side='left', relief='raised',
					expand='x');
     prvt.f0.menubar.file  := widgetset.button(prvt.f0.menubar, type='menu', 
					       text='File', relief='flat');
     prvt.f0.menubar.file.dismiss := widgetset.button(prvt.f0.menubar.file,
                                                   text='Dismiss Window', type='dismiss');
     prvt.f0.menubar.file.done := widgetset.button(prvt.f0.menubar.file,
                                                   text='Done', type='halt');
     helptxt := spaste('- dismiss window, preserving state\n',
                       '- destroy window, destroying state');
     widgetset.popuphelp(prvt.f0.menubar.file, helptxt, 'Menus of file operations', combi=T);
#
     whenever prvt.f0.menubar.file.done->press do {
       self->exit(); 
       self.done(); 
     }
     whenever prvt.f0.menubar.file.dismiss->press do {
       prvt.f0->unmap();
     }
#
     prvt.f0.menubar.spacer := widgetset.frame(prvt.f0.menubar, expand='x', 
					       height=1);
#
     prvt.f0.menubar.help := widgetset.helpmenu(parent=prvt.f0.menubar,
                              menuitems="Image Maskhandler MaskhandlerGUI",
                              refmanitems=['Refman:images.image', 'Refman:images.image.maskhandler',
                                           'Refman:images.image.maskhandlergui'],  
                              helpitems=['about Images', 'about maskhandler ', 'about maskhandler GUI']);
   }
#
   ok := prvt.getmasks(prvt.image)
   if (is_fail(ok)) fail;
   prvt.f0.f0 := widgetset.frame(prvt.f0, side='left', expand='both', relief='groove')
#
   prvt.f0.f0.f0 := widgetset.frame(prvt.f0.f0, side='top', expand='both', relief='raised');
   prvt.f0.f0.f0.label := widgetset.label(prvt.f0.f0.f0, 'Current masks');
   widgetset.popuphelp(prvt.f0.f0.f0.label, 'List of masks in this image');
   prvt.f0.f0.f0.list := widgetset.scrolllistbox(parent=prvt.f0.f0.f0,
                                                 mode='extended', height=5,
                                                 width=12);
   prvt.f0.f0.f0.list->insert(prvt.image.masks);
   prvt.f0.f0.f0.currentdefault := widgetset.label(prvt.f0.f0.f0, '');
   prvt.setdefaultlabel(prvt.f0.f0.f0.currentdefault);
   widgetset.popuphelp(prvt.f0.f0.f0.currentdefault, 'This is the default mask');
#
   prvt.f0.f0.f0.f0 := widgetset.frame(prvt.f0.f0.f0, side='left', expand='x');
   prvt.f0.f0.f0.f0.setdefault := widgetset.button(prvt.f0.f0.f0.f0, text='Set',
                                                   width=6);
   widgetset.popuphelp(prvt.f0.f0.f0.f0.setdefault, 'Make the selected mask the default mask');
   prvt.f0.f0.f0.f0.unsetdefault := widgetset.button(prvt.f0.f0.f0.f0, text='Unset',
                                                     width=6);
   widgetset.popuphelp(prvt.f0.f0.f0.f0.unsetdefault, 'Unset the default mask');
#
   prvt.f0.f0.f0.f1 := widgetset.frame(prvt.f0.f0.f0, side='left', expand='x');
   prvt.f0.f0.f0.f1.delete := widgetset.button(prvt.f0.f0.f0.f1, text='Delete',
                                               width=6);
   widgetset.popuphelp(prvt.f0.f0.f0.f1.delete, 'Delete selected mask(s)');
   prvt.f0.f0.f0.f1.rename := widgetset.button(prvt.f0.f0.f0.f1, text='Rename',
                                               width=6);
   widgetset.popuphelp(prvt.f0.f0.f0.f1.rename, 'Rename the selected mask');
#
   prvt.f0.f0.f0.f2 := widgetset.frame(prvt.f0.f0.f0, side='left', expand='x');
   prvt.f0.f0.f0.f2.copy := widgetset.button(prvt.f0.f0.f0.f2, text='Copy',
                                             width=6);
   widgetset.popuphelp(prvt.f0.f0.f0.f2.copy, 'Copy the selected mask');
   prvt.f0.f0.f0.f2.update := widgetset.button(prvt.f0.f0.f0.f2, text='Update',
                                               width=6);
   widgetset.popuphelp(prvt.f0.f0.f0.f2.update, 'Update the list of masks');
#
   prvt.f0.f0.f0.space := widgetset.frame(prvt.f0.f0.f0, expand='both', height=1);
#
   whenever prvt.f0.f0.f0.f0.setdefault->press do {
      idx := prvt.getlist(prvt.f0.f0.f0.list, single=T, none=F);
      if (!is_boolean(idx)) {
         ok := prvt.image.object.maskhandler('set', prvt.image.masks[idx]);
         if (!is_fail(ok)) {
            ok := prvt.getmasks(prvt.image);
            if (!is_fail(ok)) prvt.setdefaultlabel(prvt.f0.f0.f0.currentdefault);
         }
      }
   }
   whenever prvt.f0.f0.f0.f0.unsetdefault->press do {
      idx := prvt.getlist(prvt.f0.f0.f0.list, single=F, none=T)
      if (!is_boolean(idx)) {
         ok := prvt.image.object.maskhandler('set', '');
         if (!is_fail(ok)) {
            ok := prvt.getmasks(prvt.image);
            if (!is_fail(ok)) prvt.setdefaultlabel(prvt.f0.f0.f0.currentdefault);
         }
      }
   }
   whenever prvt.f0.f0.f0.f1.delete->press do {
      idx := prvt.getlist(prvt.f0.f0.f0.list, single=F, none=F);
      if (!is_boolean(idx)) {
         ok := prvt.image.object.maskhandler('delete', prvt.image.masks[idx]);
         if (!is_fail(ok)) {
            ok := prvt.getmasks(prvt.image);
            if (!is_fail(ok)) {
               prvt.updatelistbox(prvt.f0.f0.f0.list, prvt.image.masks);
               prvt.setdefaultlabel(prvt.f0.f0.f0.currentdefault);
#
               if (length(prvt.image2.object)>0) {
                  prvt.getmasks(prvt.image2);
                  prvt.updatelistbox(prvt.f0.f0.f1.list, prvt.image2.masks);
               }
            }
         }
      }
   }
   whenever prvt.f0.f0.f0.f1.rename->press do {
      idx := prvt.getlist(prvt.f0.f0.f0.list, single=T, none=F);
      if (!is_boolean(idx)) {
         oldDefaultMask := prvt.image.defaultmask;
#
         defName := prvt.defaultname('mask', prvt.image.masks[idx], 
                                     prvt.f0.f2.defaultName->state());
         newname := widgetset.dialogbox(label='Enter new mask name',
                                        type='string', value=defName);
         if (!is_fail(newname) && is_string(newname) && strlen(newname)>0) {
            ok := prvt.image.object.maskhandler('rename', [prvt.image.masks[idx], newname]);
#
            if (!is_fail(ok)) {
               if (prvt.image.masks[idx]==oldDefaultMask) {
                  ok := prvt.image.object.maskhandler('set', newname);
               }
            }
#
            if (!is_fail(ok)) {
               ok := prvt.getmasks(prvt.image);
               if (!is_fail(ok)) {
                  prvt.updatelistbox(prvt.f0.f0.f0.list, prvt.image.masks);
                  prvt.setdefaultlabel(prvt.f0.f0.f0.currentdefault);
#
                  if (length(prvt.image2.object)>0) {
                     prvt.getmasks(prvt.image2);
                     prvt.updatelistbox(prvt.f0.f0.f1.list, prvt.image2.masks);
                  }
               }
            }
         }
      }
   }
   whenever prvt.f0.f0.f0.f2.copy->press do {
      idx := prvt.getlist(prvt.f0.f0.f0.list, single=T, none=F);
      if (!is_boolean(idx)) {
         defName := prvt.defaultname('mask', prvt.image.masks[idx], 
                                     prvt.f0.f2.defaultName->state());
         newname := widgetset.dialogbox(label='Enter output mask name',
                                        type='string', value=defName);
         if (!is_fail(newname) && is_string(newname) && strlen(newname)>0) {
            ok := prvt.image.object.maskhandler('copy', 
                      [prvt.image.masks[idx], newname]);
            if (!is_fail(ok)) {
               ok := prvt.getmasks(prvt.image);
               if (!is_fail(ok)) {  
                  prvt.updatelistbox(prvt.f0.f0.f0.list, prvt.image.masks);
                  prvt.setdefaultlabel(prvt.f0.f0.f0.currentdefault);
#
                  if (length(prvt.image2.object)>0) {
                     prvt.getmasks(prvt.image2);
                     prvt.updatelistbox(prvt.f0.f0.f1.list, prvt.image2.masks);
                  }
               }
            }
         }
      }
   }
   whenever prvt.f0.f0.f0.f2.update->press do {
      ok := prvt.getmasks(prvt.image);
      if (!is_fail(ok)) prvt.updatelistbox(prvt.f0.f0.f0.list, prvt.image.masks);
   }
#
#
   prvt.f0.f0.f1 := widgetset.frame(prvt.f0.f0, side='top', expand='both', relief='raised');
   prvt.f0.f0.f1.label := widgetset.label(prvt.f0.f0.f1, 'External masks');
   widgetset.popuphelp(prvt.f0.f0.f1.label, 'List of masks in the given file');
   prvt.f0.f0.f1.list := widgetset.scrolllistbox(parent=prvt.f0.f0.f1,
                                                 mode='extended', height=5,
                                                 width=12);
#
   prvt.f0.f0.f1.f0 := widgetset.frame(prvt.f0.f0.f1, side='left', expand='x');
   prvt.f0.f0.f1.f0.label := widgetset.label(prvt.f0.f0.f1.f0, 'File name');
   widgetset.popuphelp(prvt.f0.f0.f1.f0.label, 'Enter an image file name and press <CR>');
   prvt.f0.f0.f1.f0.file := prvt.ge.file(prvt.f0.f0.f1.f0);
   prvt.f0.f0.f1.f1 := widgetset.frame(prvt.f0.f0.f1, side='left', expand='x');
   prvt.f0.f0.f1.f1.copy := widgetset.button(prvt.f0.f0.f1.f1, text='Copy', width=6);
   widgetset.popuphelp(prvt.f0.f0.f1.f1.copy, 'Copy a mask from the external image file to the current image');
   prvt.f0.f0.f1.f1.update := widgetset.button(prvt.f0.f0.f1.f1, text='Update', width=6);
   widgetset.popuphelp(prvt.f0.f0.f1.f1.update, 'Update the list of masks for the external image file');
   prvt.f0.f0.f1.space := widgetset.frame(prvt.f0.f0.f1, expand='both', height=1);
#
   whenever prvt.f0.f0.f1.f0.file->value do {
#
# Delete old image object if there is one
#
      if (length(prvt.image2.object)>0) {
         prvt.image2.object.done();
         prvt.f0.f0.f1.list->clear('start', 'end');
         prvt.f0.f0.f1.list->delete('start', 'end');
         prvt.image2.object := [=];
      }
#
# Try and open new file
#
      tmp := image($value);
      if (!is_fail(tmp)) {
         prvt.image2.object := tmp;
         prvt.image2.name := $value;
         ok := prvt.getmasks(prvt.image2);
         if (!is_fail(ok)) {
            prvt.image2.masks := prvt.image2.object.maskhandler('get');
            if (!is_fail(prvt.image2.masks)) {
               prvt.updatelistbox(prvt.f0.f0.f1.list, prvt.image2.masks);
            }
         }
      }
   }
   whenever prvt.f0.f0.f1.f1.copy->press do {
      idx := prvt.getlist(prvt.f0.f0.f1.list, single=T, none=F);
      if (!is_boolean(idx)) {
         defName := prvt.defaultname('mask', prvt.image2.masks[idx], 
                                     prvt.f0.f2.defaultName->state());
         newname := widgetset.dialogbox(label='Enter output mask name',
                                        type='string', value=defName);
         if (strlen(newname)>0) {
            ok := prvt.image.object.maskhandler('copy',
                    [spaste(prvt.image2.name,':',prvt.image2.masks[idx]), 
                     newname]);
            if (!is_fail(ok)) {
               ok := prvt.getmasks(prvt.image);
               if (!is_fail(ok)) {
                  prvt.updatelistbox(prvt.f0.f0.f0.list, prvt.image.masks);
                  prvt.setdefaultlabel(prvt.f0.f0.f0.currentdefault);
#
                  prvt.getmasks(prvt.image2);
                  prvt.updatelistbox(prvt.f0.f0.f1.list, prvt.image2.masks);
               }
            }
         }
      }
   }
   whenever prvt.f0.f0.f1.f1.update->press do {
      if (length(prvt.image2.object)>0) {
         ok := prvt.getmasks(prvt.image2);
         if (!is_fail(ok)) prvt.updatelistbox(prvt.f0.f0.f1.list, prvt.image2.masks);
      }
   }
#
# Reset, defaultName, and dismiss 
#
   prvt.f0.f2 := widgetset.frame(prvt.f0, side='left', expand='x', 
                                 relief='raised', height=1);
   if (prvt.standalone) {
      prvt.f0.f2.reset := widgetset.button(prvt.f0.f2, text='Reset', 
                                           type='action');
      widgetset.popuphelp(prvt.f0.f2.reset, 'Reset GUI');
      whenever prvt.f0.f2.reset->press do {
	self.reset();
      }
   }
   prvt.f0.f2.defaultName := widgetset.button(prvt.f0.f2, text='Autoname', 
                                              type='check');
   prvt.f0.f2.defaultName->state(T);
   helptxt := spaste('when copying/renaming masks the default new mask\n',
                     'name is the old mask name unless this box is\n',
                     'checked.  Then, a new name is chosen in the style\n',
                     '"masknn" where nn is an integer starting at 0');
   widgetset.popuphelp(prvt.f0.f2.defaultName, helptxt, 'Auto set new mask name', combi=T);
#
   prvt.f0.f2.f0 := widgetset.frame(prvt.f0.f2, side='left', expand='x', 
                                    height=1);
   if (prvt.standalone) {
      prvt.f0.f2.dismiss := widgetset.button(prvt.f0.f2, text='Dismiss', 
					     type='dismiss');
      widgetset.popuphelp(prvt.f0.f2.dismiss, 'Dismiss GUI');
      whenever prvt.f0.f2.dismiss->press do {
	ok := prvt.f0->unmap();
      }
   }
#
   ok := prvt.f0->map();
#

###
   const self.done := function ()
   {
      wider prvt, self;
      prvt.ge.done();
      prvt.f0.f0.f0.list.done();
      prvt.f0.f0.f1.list.done();
      val prvt := F;
      val self := F;
      return T;
   }

###
   const self.gui := function ()
   {
      prvt.f0->map();
      return T;
   }


###
   const self.setimage := function (imageobject)
   {
      wider prvt;
      if (!is_image(imageobject)) fail;
#
# Set image object
#
      prvt.image.object := imageobject;
#
# Set title
#
      title := spaste('imagemaskhandler (', prvt.image.object.name(strippath=F), ')');
      prvt.f0->title(title);
#
# Update lists
#
      ok := prvt.getmasks(prvt.image);
      if (!is_fail(ok)) {
         prvt.updatelistbox(prvt.f0.f0.f0.list, prvt.image.masks);
         prvt.setdefaultlabel(prvt.f0.f0.f0.currentdefault);
      }
#
      return T;
   }



###
   const self.getstate := function (check=T)
#
# There isn't much state to be had.  Really, only
# the external mask image could be considered state.
#
   {
      rec := [=];
      rec.external := prvt.image2.name;
#
      return rec;
   }


###
   const self.reset := function ()
   {
      wider prvt;
#
      if (length(prvt.image2.object)>0) {
         prvt.image2.object.done();
         prvt.image2.object := [=];
         prvt.image2.name := '';
         prvt.image2.masks := "";         
         prvt.image2.defaultmask := "";    
#
         prvt.f0.f0.f1.list->clear('start', 'end');
         prvt.f0.f0.f1.list->delete('start', 'end');
      }
      prvt.f0.f0.f1.f0.file.insert('');
      prvt.f0.f0.f1.list->clear('start', 'end');
      return T;   
   }


###
   const self.setstate := function (rec)
   {
      wider prvt;
      self.reset();
      rec.external := prvt.image2.name;
      if (has_field('external', rec)) {
         if (is_string(rec.external)) {
            prvt.f0.f0.f1.f0.file.insert(rec.external);
         }
      }
      return T;
   }

###
   const self.update := function ()
   {
      wider prvt;
      if (is_fail(prvt.getmasks(prvt.image))) fail;
      return prvt.updatelistbox(prvt.f0.f0.f0.list, prvt.image.masks);
   }
}
