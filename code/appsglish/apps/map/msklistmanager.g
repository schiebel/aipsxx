# msklistmanager: data manager for a masklist data item
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
# $Id: msklistmanager.g,v 19.1 2004/08/25 01:26:06 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for masklist data item type
#
const is_masklist:= function (const item)
{
# Is this variable a valid masklist item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isMaskList')) {
     valid := T;
   };
   return valid;
};  

#
# Define a masklist manager instance
#
const _define_masklistmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.masklist_type := function (const type)
   {
   # Define enum values for the masklist type
   #
   #   -1 = undefined
   #    0 = MASKLIST
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='masklistmanager.masklist_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'MASKLIST') {
         enum := 0;
      } else {
         msg := spaste('Unrecognized masklist type: ',type);
         return throw (msg, origin='masklistmanager.masklist_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.masklist := function(model1='', mask1=unset,
                                     model2='', mask2=unset,
                                     model3='', mask3=unset,
                                     model4='', mask4=unset,
                                     model5='', mask5=unset,
                                     model6='', mask6=unset,
                                     model7='', mask7=unset,
                                     model8='', mask8=unset,
                                     model9='', mask9=unset)
      
   {
   # Create a masklist from a list of model names and associated masks
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'MASKLIST');
      item.set('isMaskList', private.masklist_type('MASKLIST'));
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
      rec[1] := mask1;
      rec[2] := mask2;
      rec[3] := mask3;
      rec[4] := mask4;
      rec[5] := mask5;
      rec[6] := mask6;
      rec[7] := mask7;
      rec[8] := mask8;
      rec[9] := mask9;
      item.set('masks', rec);
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
      return 'masklistmanager';
   }

   plugins.attach('masklistmanager', public);
   return ref public;

} # _define_masklistmanager()

#
# Null constructor
#
const masklistmanager := function() {
#   
   return ref _define_masklistmanager();
} 

#
# Create default masklist manager, and return its name
#
const createdefaultmasklistmanager := function() {
#
   if (!serverexists('dkl', 'masklistmanager', dkl)) {
      global dkl, defaultmasklistmanager;
      const defaultmasklistmanager := masklistmanager();
      const dkl := ref defaultmasklistmanager;
      note ('defaultmasklistmanager (dkl) ready for use', priority='NORMAL',
         origin='masklistmanager');
   };
   return 'dkl';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const masklistmanagerdemo:=function() {
   mykl:=masklistmanager();
   note(paste("Demonstation of ", mykl.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const masklistmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dkl, the default masklist manager
createdefaultmasklistmanager();
#------------------------------------------------------------------------

