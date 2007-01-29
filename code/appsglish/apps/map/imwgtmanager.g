# imwgtmanager: data manager for an imaging weight data item
# Copyright (C) 1999,2000
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
# $Id: imwgtmanager.g,v 19.1 2004/08/25 01:24:35 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for weight data item type
#
const is_imagingweight:= function (const item)
{
# Is this variable a valid imagingweight item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isImagingWeight')) {
     valid := T;
   };
   return valid;
};  

#
# Define a imagingweight manager instance
#
const _define_imagingweightmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.imagingweight_type := function (const type)
   {
   # Define enum values for the imagingweight type
   #
   #   -1 = undefined
   #    0 = UNIFORM
   #    1 = NATURAL
   #    2 = BRIGGS
   #    3 = RADIAL
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='imagingweightmanager.imagingweight_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'UNIFORM') {
         enum := 0;
      } else if (tmp == 'NATURAL') {
         enum := 1;
      } else if (tmp == 'BRIGGS') {
         enum := 2;
      } else if (tmp == 'RADIAL') {
         enum := 3;
      } else {
         msg := spaste('Unrecognized imagingweight type: ',type);
         return throw (msg, origin='imagingweightmanager.imagingweight_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.natural := function(uvmin=0.0, uvmax=0.0, bmaj='0rad', 
                                    bmin='0rad', bpa='0deg')
   {
   # Create a imagingweight data item from natural weighting parameters
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'NATURAL');
      item.set('isImagingWeight', private.imagingweight_type('NATURAL'));
      item.set('uvmin', uvmin);
      item.set('uvmax', uvmax);
      item.set('bmaj', bmaj);
      item.set('bmin', bmin);
      item.set('bpa', bpa);
      return item;
   };

   const public.uniform := function(fieldofview='0rad', npixels=0, uvmin=0.0,
                                    uvmax=0.0, bmaj='0rad', bmin='0rad', 
                                    bpa='0deg')
   {
   # Create a imagingweight data item from uniform weighting parameters
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'UNIFORM');
      item.set('isImagingWeight', private.imagingweight_type('UNIFORM'));
      item.set('fieldofview', fieldofview);
      item.set('npixels', npixels);
      item.set('uvmin', uvmin);
      item.set('uvmax', uvmax);
      item.set('bmaj', bmaj);
      item.set('bmin', bmin);
      item.set('bpa', bpa);
      return item;
   };

   const public.briggs := function(rmode="rnorm", noise='0.0Jy', robust=0.0,
                                   fieldofview='0rad', npixels=0, uvmin=0.0,
                                   uvmax=0.0, bmaj='0rad', bmin='0rad', 
                                   bpa='0deg')
   {
   # Create a imagingweight data item from Briggs' weighting parameters
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'BRIGGS');
      item.set('isImagingWeight', private.imagingweight_type('BRIGGS'));
      item.set('rmode', rmode);
      item.set('noise', noise);
      item.set('robust', robust);
      item.set('fieldofview', fieldofview);
      item.set('npixels', npixels);
      item.set('uvmin', uvmin);
      item.set('uvmax', uvmax);
      item.set('bmaj', bmaj);
      item.set('bmin', bmin);
      item.set('bpa', bpa);
      return item;
   };

   const public.radial := function(uvmin=0.0, uvmax=0.0, bmaj='0rad', 
                                   bmin='0rad', bpa='0deg')
   {
   # Create a imagingweight data item from radial weighting parameters
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'RADIAL');
      item.set('isImagingWeight', private.imagingweight_type('RADIAL'));
      item.set('uvmin', uvmin);
      item.set('uvmax', uvmax);
      item.set('bmaj', bmaj);
      item.set('bmin', bmin);
      item.set('bpa', bpa);
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
      return 'imagingweightmanager';
   }

   plugins.attach('imagingweightmanager', public);
   return ref public;

} # _define_imagingweightmanager()

#
# Null constructor
#
const imagingweightmanager := function() {
#   
   return ref _define_imagingweightmanager();
} 

#
# Create default imagingweight manager, and return its name
#
const createdefaultimagingweightmanager := function() {
#
   if (!serverexists('diw', 'imagingweightmanager', diw)) {
      global diw, defaultimagingweightmanager;
      const defaultimagingweightmanager := imagingweightmanager();
      const diw := ref defaultimagingweightmanager;
      note ('defaultimagingweightmanager (diw) ready for use', priority='NORMAL',
         origin='imagingweightmanager');
   };
   return 'diw';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const imagingweightmanagerdemo:=function() {
   myiw:=imagingweightmanager();
   note(paste("Demonstation of ", myiw.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const imagingweightmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create diw, the default imagingweight manager
createdefaultimagingweightmanager();
#------------------------------------------------------------------------

