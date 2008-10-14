# imflistmanager: data manager for an imagingfieldlist data item
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
# $Id: imflistmanager.g,v 19.1 2004/08/25 01:24:15 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for imagingfieldlist data item type
#
const is_imagingfieldlist:= function (const item)
{
# Is this variable a valid imagingfieldlist item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isImagingFieldList')) {
     valid := T;
   };
   return valid;
};  

#
# Define a imagingfieldlist manager instance
#
const _define_imagingfieldlistmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.imagingfieldlist_type := function (const type)
   {
   # Define enum values for the imagingfieldlist type
   #
   #   -1 = undefined
   #    0 = IMAGINGFIELDLIST
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='imagingfieldlistmanager.imagingfieldlist_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'IMAGINGFIELDLIST') {
         enum := 0;
      } else {
         msg := spaste('Unrecognized imagingfieldlist type: ',type);
         return throw (msg, 
            origin='imagingfieldlistmanager.imagingfieldlist_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.imagingfieldlist := function(model1='', imagingfield1=unset,
                                             model2='', imagingfield2=unset,
                                             model3='', imagingfield3=unset,
                                             model4='', imagingfield4=unset,
                                             model5='', imagingfield5=unset,
                                             model6='', imagingfield6=unset,
                                             model7='', imagingfield7=unset,
                                             model8='', imagingfield8=unset,
                                             model9='', imagingfield9=unset)
      
   {
   # Create a imagingfieldlist from a list of models names and 
   # associated imagingfield data items.
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'IMAGINGFIELDLIST');
      item.set('isImagingFieldList', 
         private.imagingfieldlist_type('IMAGINGFIELDLIST'));
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
      rec[1] := imagingfield1;
      rec[2] := imagingfield2;
      rec[3] := imagingfield3;
      rec[4] := imagingfield4;
      rec[5] := imagingfield5;
      rec[6] := imagingfield6;
      rec[7] := imagingfield7;
      rec[8] := imagingfield8;
      rec[9] := imagingfield9;
      item.set('imagingfields', rec);
      return item;
   };

   const public.imagingcoord := function(imagingfieldlist=unset)
   {
   # Retrieve the imaging coordinates for the first valid
   # imaging field in an imaging field list
   #
      wider private, public;

      # Initialization
      imcoord := unset;

      # Find first non-empty imaging field
      imagingfields := imagingfieldlist.get('imagingfields');;
      nfields := len(imagingfields);
      found := F;
      j := 1;
      while ((j < nfields) && !found) {
         if (!is_unset(imagingfields[j])) {
            imcoord := imagingfields[j].get('imagingcoord');
            if (!is_unset(imcoord)) found := T;
         };
         j := j + 1;
      };

      return imcoord;
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
      return 'imagingfieldlistmanager';
   }

   plugins.attach('imagingfieldlistmanager', public);
   return ref public;

} # _define_imagingfieldlistmanager()

#
# Null constructor
#
const imagingfieldlistmanager := function() {
#   
   return ref _define_imagingfieldlistmanager();
} 

#
# Create default imagingfieldlist manager, and return its name
#
const createdefaultimagingfieldlistmanager := function() {
#
   if (!serverexists('dil', 'imagingfieldlistmanager', dil)) {
      global dil, defaultimagingfieldlistmanager;
      const defaultimagingfieldlistmanager := imagingfieldlistmanager();
      const dil := ref defaultimagingfieldlistmanager;
      note ('defaultimagingfieldlistmanager (dil) ready for use', 
            priority='NORMAL', origin='imagingfieldlistmanager');
   };
   return 'dil';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const imagingfieldlistmanagerdemo:=function() {
   myil:=imagingfieldlistmanager();
   note(paste("Demonstation of ", myil.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const imagingfieldlistmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dil, the default imagingfieldlist manager
createdefaultimagingfieldlistmanager();
#------------------------------------------------------------------------

