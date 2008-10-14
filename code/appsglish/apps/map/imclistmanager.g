# imclistmanager: data manager for a imagingcoordlist data item
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
# $Id: imclistmanager.g,v 19.1 2004/08/25 01:23:57 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for imagingcoordlist data item type
#
const is_imagingcoordlist:= function (const item)
{
# Is this variable a valid imagingcoordlist item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isImagingCoordList')) {
     valid := T;
   };
   return valid;
};  

#
# Define a imagingcoordlist manager instance
#
const _define_imagingcoordlistmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.imagingcoordlist_type := function (const type)
   {
   # Define enum values for the imagingcoordlist type
   #
   #   -1 = undefined
   #    0 = IMAGINGCOORDLIST
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='imagingcoordlistmanager.imagingcoordlist_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'IMAGINGCOORDLIST') {
         enum := 0;
      } else {
         msg := spaste('Unrecognized imagingcoordlist type: ',type);
         return throw (msg, 
                       origin='imagingcoordlistmanager.imagingcoordlist_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.imagingcoordlist := function(model1='', imagingcoord1=unset,
                                             model2='', imagingcoord2=unset,
                                             model3='', imagingcoord3=unset,
                                             model4='', imagingcoord4=unset,
                                             model5='', imagingcoord5=unset,
                                             model6='', imagingcoord6=unset,
                                             model7='', imagingcoord7=unset,
                                             model8='', imagingcoord8=unset,
                                             model9='', imagingcoord9=unset)
   {
   # Create a imagingcoordlist from a list of models and imagingcoords
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'IMAGINGCOORDLIST');
      item.set('isImagingCoordList', 
         private.imagingcoordlist_type('IMAGINGCOORDLIST'));
      rec := [=];
      rec[1] := model1;
      rec[2] := model2;
      rec[3] := model3;
      rec[4] := model4;
      rec[5] := model5;
      rec[6] := model6;
      rec[7] := model7;
      rec[8] := model8;
      rec[9] := model9;
      item.set('models', rec);
      rec := [=];
      rec[1] := imagingcoord1;
      rec[2] := imagingcoord2;
      rec[3] := imagingcoord3;
      rec[4] := imagingcoord4;
      rec[5] := imagingcoord5;
      rec[6] := imagingcoord6;
      rec[7] := imagingcoord7;
      rec[8] := imagingcoord8;
      rec[9] := imagingcoord9;
      item.set('imagingcoords', rec);
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
      return 'imagingcoordlistmanager';
   }

   plugins.attach('imagingcoordlistmanager', public);
   return ref public;

} # _define_imagingcoordlistmanager()

#
# Null constructor
#
const imagingcoordlistmanager := function() {
#   
   return ref _define_imagingcoordlistmanager();
} 

#
# Create default imagingcoordlist manager, and return its name
#
const createdefaultimagingcoordlistmanager := function() {
#
   if (!serverexists('dil', 'imagingcoordlistmanager', dil)) {
      global dil, defaultimagingcoordlistmanager;
      const defaultimagingcoordlistmanager := imagingcoordlistmanager();
      const dil := ref defaultimagingcoordlistmanager;
      note ('defaultimagingcoordlistmanager (dil) ready for use', 
         priority='NORMAL', origin='imagingcoordlistmanager');
   };
   return 'dil';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const imagingcoordlistmanagerdemo:=function() {
   myil:=imagingcoordlistmanager();
   note(paste("Demonstation of ", myil.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const imagingcoordlistmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dil, the default imagingcoordlist manager
createdefaultimagingcoordlistmanager();
#------------------------------------------------------------------------

