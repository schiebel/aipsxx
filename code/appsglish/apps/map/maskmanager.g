# maskmanager: data manager for a mask data item
# Copyright (C) 1999,2000,2001,2003
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
# $Id: maskmanager.g,v 19.1 2004/08/25 01:25:21 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';
include 'interactivemask.g'

#
# Check for mask data item type
#
const is_mask:= function (const item)
{
# Is this variable a valid mask item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isMask')) {
     valid := T;
   };
   return valid;
};  

#
# Define a mask manager instance
#
const _define_maskmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.mask_type := function (const type)
   {
   # Define enum values for the mask type
   #
   #   -1 = undefined
   #    0 = MASK
   #    1 = BOXMASK
   #    2 = THRESHOLDMASK
   #    3 = REGIONMASK
   #    4 = EXPRMASK
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='maskmanager.mask_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'MASK') {
         enum := 0;
      } else if (tmp == 'BOXMASK') {
         enum := 1;
      } else if (tmp == 'THRESHOLDMASK') {
         enum := 2;
      } else if (tmp == 'REGIONMASK') {
         enum := 3;
      } else if (tmp == 'EXPRMASK') {
         enum := 4;
      } else {
         msg := spaste('Unrecognized mask type: ',type);
         return throw (msg, origin='maskmanager.mask_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.mask := function(mask=unset)
   {
   # Create a mask data item from a specified mask image
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'MASK');
      item.set('isMask', private.mask_type('MASK'));
      item.set('mask', mask);
      return item;
   };

   const public.boxmask := function(blc=[], trc=[], value=1.0)
   {
   # Create a mask data item from a set of box mask parameters
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'BOXMASK');
      item.set('isMask', private.mask_type('BOXMASK'));
      item.set('blc', blc);
      item.set('trc', trc);
      item.set('value', value);
      return item;
   };

   const public.thresholdmask := function(image='', threshold='0.0Jy')
   {
   # Create a mask data item from an image and a threshold value
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'THRESHOLDMASK');
      item.set('isMask', private.mask_type('THRESHOLDMASK'));
      item.set('image', image);
      item.set('threshold', threshold);
      return item;
   };

   const public.regionmask := function(region=unset, value=1.0)
   {
   # Create a mask data item from a region and a mask value
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'REGIONMASK');
      item.set('isMask', private.mask_type('REGIONMASK'));
      item.set('region', region);
      item.set('value', value);
      return item;
   };

   const public.exprmask := function(expr='')
   {
   # Create a mask data item from a LEL expression
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'EXPRMASK');
      item.set('isMask', private.mask_type('EXPRMASK'));
      item.set('expr', expr);
      return item;
   };


   const public.fromimage := function(image='', maskimage='')
   {
   # Create a mask data item by interactive drawing of regions
   #
      wider public, private;
        mygrabregion:=F
       mygrabregion:=interactivemask(image, maskimage);
       mygrabregion.start();
       while(!is_boolean(mygrabregion)){
         timer.wait(5)
       }
      item := itemcontainer();
      item.set('name', 'MASK');
      item.set('isMask', private.mask_type('MASK'));
      item.set('mask', maskimage);
      return item;
   };


   const public.done := function()
   {
      wider private, public;
      private := F;
      val public := F;
      if (has_field(private, 'gui')) {
         ok := private.gui.done(T);
         if (is_fail(ok)) fail;
      }
      return T;
   }

   const public.type := function() {
      return 'maskmanager';
   }

   plugins.attach('maskmanager', public);
   return ref public;

} # _define_maskmanager()

#
# Null constructor
#
const maskmanager := function() {
#   
   return ref _define_maskmanager();
} 

#
# Create default mask manager, and return its name
#
const createdefaultmaskmanager := function() {
#
   if (!serverexists('dmk', 'maskmanager', dmk)) {
      global dmk, defaultmaskmanager;
      const defaultmaskmanager := maskmanager();
      const dmk := ref defaultmaskmanager;
      note ('defaultmaskmanager (dmk) ready for use', priority='NORMAL',
         origin='maskmanager');
   };
   return 'dmk';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const maskmanagerdemo:=function() {
   mymk:=maskmanager();
   note(paste("Demonstation of ", mymk.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const maskmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dmk, the default mask manager
createdefaultmaskmanager();
#------------------------------------------------------------------------

