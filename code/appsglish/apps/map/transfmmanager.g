# transfmmanager: data manager for a transform data item
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
# $Id: transfmmanager.g,v 19.1 2004/08/25 01:26:57 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for transform data item type
#
const is_transform:= function (const item)
{
# Is this variable a valid transform item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isTransform')) {
     valid := T;
   };
   return valid;
};  

#
# Define a transform manager instance
#
const _define_transformmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.transform_type := function (const type)
   {
   # Define enum values for the transform type
   #
   #   -1 = undefined
   #    0 = GRIDFT
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='transformmanager.transform_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'GRIDFT') {
         enum := 0;
      } else {
         msg := spaste('Unrecognized transform type: ',type);
         return throw (msg, origin='transformmanager.transform_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.gridft := function(cache=0, tile=16, gridfunction='SF', 
                                   padding=1.2)
   {
   # Create a transform from a set of parameters for a gridded FT
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'GRIDFT');
      item.set('isTransform', private.transform_type('GRIDFT'));
      item.set('cache', cache);
      item.set('tile', tile);
      item.set('gridfunction', gridfunction);
      item.set('padding', padding);
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
      return 'transformmanager';
   }

   plugins.attach('transformmanager', public);
   return ref public;

} # _define_transformmanager()

#
# Null constructor
#
const transformmanager := function() {
#   
   return ref _define_transformmanager();
} 

#
# Create default transform manager, and return its name
#
const createdefaulttransformmanager := function() {
#
   if (!serverexists('dtm', 'transformmanager', dtm)) {
      global dtm, defaulttransformmanager;
      const defaulttransformmanager := transformmanager();
      const dtm := ref defaulttransformmanager;
      note ('defaulttransformmanager (dtm) ready for use', priority='NORMAL',
         origin='transformmanager');
   };
   return 'dtm';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const transformmanagerdemo:=function() {
   mytm:=transformmanager();
   note(paste("Demonstation of ", mytm.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const transformmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dtm, the default transform manager
createdefaulttransformmanager();
#------------------------------------------------------------------------




