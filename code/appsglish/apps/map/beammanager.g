# beammanager: data manager for a restoringbeam data item
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
# $Id: beammanager.g,v 19.1 2004/08/25 01:22:41 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for restoringbeam data item type
#
const is_restoringbeam:= function (const item)
{
# Is this variable a valid restoringbeam item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isRestoringBeam')) {
     valid := T;
   };
   return valid;
};  

#
# Define a restoringbeam manager instance
#
const _define_restoringbeammanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.restoringbeam_type := function (const type)
   {
   # Define enum values for the restoringbeam type
   #
   #   -1 = undefined
   #    0 = GAUSSIAN
   #    1 = FITPSF
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='restoringbeammanager.restoringbeam_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'GAUSSIAN') {
         enum := 0;
      } else if (tmp == 'FITPSF') {
         enum := 1;
      } else {
         msg := spaste('Unrecognized restoringbeam type: ',type);
         return throw (msg, origin='restoringbeammanager.restoringbeam_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.gaussian := function(bmaj='0rad', bmin='0rad', bpa='0rad')
   {
   # Create a restoringbeam from a set of Gaussian parameters
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'GAUSSIAN');
      item.set('isRestoringBeam', private.restoringbeam_type('GAUSSIAN'));
      item.set('bmaj', bmaj);
      item.set('bmin', bmin);
      item.set('bpa', bpa);
      return item;
   };

   const public.fitpsf := function(psf='')
   {
   # Create a restoringbeam from a fit to a specified PSF image
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'FITPSF');
      item.set('isRestoringBeam', private.restoringbeam_type('FITPSF'));
      item.set('psf', psf);
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
      return 'restoringbeammanager';
   }

   plugins.attach('restoringbeammanager', public);
   return ref public;

} # _define_restoringbeammanager()

#
# Null constructor
#
const restoringbeammanager := function() {
#   
   return ref _define_restoringbeammanager();
} 

#
# Create default restoringbeam manager, and return its name
#
const createdefaultrestoringbeammanager := function() {
#
   if (!serverexists('dbm', 'restoringbeammanager', dbm)) {
      global dbm, defaultrestoringbeammanager;
      const defaultrestoringbeammanager := restoringbeammanager();
      const dbm := ref defaultrestoringbeammanager;
      note ('defaultrestoringbeammanager (dbm) ready for use',
         priority='NORMAL', origin='restoringbeammanager');
   };
   return 'dbm';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const restoringbeammanagerdemo:=function() {
   mybm:=restoringbeammanager();
   note(paste("Demonstation of ", mybm.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const restoringbeammanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dbm, the default restoringbeam manager
createdefaultrestoringbeammanager();
#------------------------------------------------------------------------

