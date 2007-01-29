# imgfldmanager: data manager for a imagingfield data item
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
# $Id: imgfldmanager.g,v 19.1 2004/08/25 01:24:25 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for imagingfield data item type
#
const is_imagingfield:= function (const item)
{
# Is this variable a valid imagingfield item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isImagingField')) {
     valid := T;
   };
   return valid;
};  

#
# Define a imagingfield manager instance
#
const _define_imagingfieldmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.imagingfield_type := function (const type)
   {
   # Define enum values for the imagingfield type
   #
   #   -1 = undefined
   #    0 = IMAGINGFIELD
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='imagingfieldmanager.imagingfield_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'IMAGINGFIELD') {
         enum := 0;
      } else {
         msg := spaste('Unrecognized imagingfield type: ',type);
         return throw (msg, origin='imagingfieldmanager.imagingfield_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.imagingfield := function(imagingcoord=unset, mask=unset,
                                         fixed=F, prior='', fluxmask='',
                                         datamask='', fluxscale='')
   {
   # Create a imagingfield from a set of imaging field parameters,
   # including coordinates, deconvolution masks and images to
   # set flux density scaling for mosaicing.
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'IMAGINGFIELD');
      item.set('isImagingField', private.imagingfield_type('IMAGINGFIELD'));
      item.set('imagingcoord', imagingcoord);
      item.set('mask', mask);
      item.set('fixed', fixed);
      item.set('prior', prior);
      item.set('fluxmask', fluxmask);
      item.set('datamask', datamask);
      item.set('fluxscale', fluxscale);
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
      return 'imagingfieldmanager';
   }

   plugins.attach('imagingfieldmanager', public);
   return ref public;

} # _define_imagingfieldmanager()

#
# Null constructor
#
const imagingfieldmanager := function() {
#   
   return ref _define_imagingfieldmanager();
} 

#
# Create default imagingfield manager, and return its name
#
const createdefaultimagingfieldmanager := function() {
#
   if (!serverexists('dif', 'imagingfieldmanager', dif)) {
      global dif, defaultimagingfieldmanager;
      const defaultimagingfieldmanager := imagingfieldmanager();
      const dif := ref defaultimagingfieldmanager;
      note ('defaultimagingfieldmanager (dif) ready for use', priority='NORMAL',
         origin='imagingfieldmanager');
   };
   return 'dif';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const imagingfieldmanagerdemo:=function() {
   myif:=imagingfieldmanager();
   note(paste("Demonstation of ", myif.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const imagingfieldmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dif, the default imagingfield manager
createdefaultimagingfieldmanager();
#------------------------------------------------------------------------

