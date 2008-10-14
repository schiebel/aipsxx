# imcoordmanager: data manager for an imaging coordinates data item
# Copyright (C) 1999,2000,2003
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
# $Id: imcoordmanager.g,v 19.1 2004/08/25 01:24:03 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for selection data item type
#
const is_imagingcoord:= function (const item)
{
# Is this variable a valid imagingcoord item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isImagingCoord')) {
     valid := T;
   };
   return valid;
};  

#
# Define a imagingcoord manager instance
#
const _define_imagingcoordmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.imagingcoord_type := function (const type)
   {
   # Define enum values for the imagingcoord type
   #
   #   -1 = undefined
   #    0 = IMAGINGCOORD
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='imagingcoordmanager.imagingcoord_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'IMAGINGCOORD') {
         enum := 0;
      } else {
         msg := spaste('Unrecognized imagingcoord type: ',type);
         return throw (msg, origin='imagingcoordmanager.imagingcoord_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.imagingcoord := function(nx=128, ny=128, cellx='1arcsec',
                                         celly='1arcsec', facets=1,
                                         doshift=F, phasecenter=F,
                                         shiftx='0arcsec', shifty='0arcsec',
                                         location=F, distance='0m',
                                         fieldid=1, stokes='I', mode='mfs', 
                                         freqsel=unset, spwid=1)
   {
   # Create a imagingcoord data item from a set of imaging coord. parameters
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'IMAGINGCOORD');
      item.set('isImagingCoord', private.imagingcoord_type('IMAGINGCOORD'));
      item.set('nx', nx);
      item.set('ny', ny);
      item.set('cellx', cellx);
      item.set('celly', celly);
      item.set('facets', facets);
      item.set('doshift', doshift);
      item.set('phasecenter', phasecenter);
      item.set('shiftx', shiftx);
      item.set('shifty', shifty);
      item.set('location', location);
      item.set('distance', distance);
      item.set('fieldid', fieldid);
      item.set('stokes', stokes);
      item.set('mode', mode);
      item.set('freqsel', freqsel);
      item.set('spwid', spwid);
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
      return 'imagingcoordmanager';
   }

   plugins.attach('imagingcoordmanager', public);
   return ref public;

} # _define_imagingcoordmanager()

#
# Null constructor
#
const imagingcoordmanager := function() {
#   
   return ref _define_imagingcoordmanager();
} 

#
# Create default imagingcoord manager, and return its name
#
const createdefaultimagingcoordmanager := function() {
#
   if (!serverexists('dic', 'imagingcoordmanager', dic)) {
      global dic, defaultimagingcoordmanager;
      const defaultimagingcoordmanager := imagingcoordmanager();
      const dic := ref defaultimagingcoordmanager;
      note ('defaultimagingcoordmanager (dic) ready for use',priority='NORMAL',
         origin='imagingcoordmanager');
   };
   return 'dic';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const imagingcoordmanagerdemo:=function() {
   myic:=imagingcoordmanager();
   note(paste("Demonstation of ", myic.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const imagingcoordmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dic, the default imagingcoord manager
createdefaultimagingcoordmanager();
#------------------------------------------------------------------------








