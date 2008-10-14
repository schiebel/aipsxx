# selectmanager: data manager for a selection data item
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
# $Id: selectmanager.g,v 19.1 2004/08/25 01:26:11 cvsmgr Exp $

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
const is_selection:= function (const item)
{
# Is this variable a valid selection item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isSelection')) {
     valid := T;
   };
   return valid;
};  

#
# Define a selection manager instance
#
const _define_selectionmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.selection_type := function (const type)
   {
   # Define enum values for the selection type
   #
   #   -1 = undefined
   #    0 = SELECTION
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='selectionmanager.selection_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'SELECTION') {
         enum := 0;
      } else {
         msg := spaste('Unrecognized selection type: ',type);
         return throw (msg, origin='selectionmanager.selection_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.selection := function(freqsel=unset, fieldnames='',
                                      spwids=0, uvrange=0, msselect='')
   {
   # Create a selection data item from synthesis selection string
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'SELECTION');
      item.set('isSelection', private.selection_type('SELECTION'));
      item.set('freqsel', freqsel);
      item.set('fieldnames', fieldnames);
      item.set('spwids', spwids);
      item.set('uvrange', uvrange);
      item.set('msselect', msselect);
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
      return 'selectionmanager';
   }

   plugins.attach('selectionmanager', public);
   return ref public;

} # _define_selectionmanager()

#
# Null constructor
#
const selectionmanager := function() {
#   
   return ref _define_selectionmanager();
} 

#
# Create default selection manager, and return its name
#
const createdefaultselectionmanager := function() {
#
   if (!serverexists('dsm', 'selectionmanager', dsm)) {
      global dsm, defaultselectionmanager;
      const defaultselectionmanager := selectionmanager();
      const dsm := ref defaultselectionmanager;
      note ('defaultselectionmanager (dsm) ready for use', priority='NORMAL',
         origin='selectionmanager');
   };
   return 'dsm';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const selectionmanagerdemo:=function() {
   mysm:=selectionmanager();
   note(paste("Demonstation of ", mysm.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const selectionmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dsm, the default selection manager
createdefaultselectionmanager();
#------------------------------------------------------------------------

