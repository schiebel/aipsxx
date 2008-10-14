# modelmanager: data manager for a model data item
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
# $Id: modelmanager.g,v 19.1 2004/08/25 01:25:36 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for model data item type
#
const is_model:= function (const item)
{
# Is this variable a valid model item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isModel')) {
     valid := T;
   };
   return valid;
};  

#
# Define a model manager instance
#
const _define_modelmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.model_type := function (const type)
   {
   # Define enum values for the model type
   #
   #   -1 = undefined
   #    0 = IMAGE
   #    1 = FLUXDENSITY
   #    2 = CATALOG
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='modelmanager.model_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'IMAGE') {
         enum := 0;
      } else if (tmp == 'FLUXDENSITY') {
         enum := 1;
      } else if (tmp == 'CATALOG') {
         enum := 2;
      } else {
         msg := spaste('Unrecognized model type: ',type);
         return throw (msg, origin='modelmanager.model_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.image := function(images, complist)
   {
   # Create a model from a set of images and a component list
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'IMAGE');
      item.set('isModel', private.model_type('IMAGE'));
      item.set('images', images);
      item.set('complist', complist);
      return item;
   };

   const public.fluxdensity := function(iquv)
   {
   # Create a model from a point-source [I,Q,U,V]
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'FLUXDENSITY');
      item.set('isModel', private.model_type('FLUXDENSITY'));
      item.set('iquv', iquv);
      return item;
   };

   const public.catalog := function(catalogname)
   {
   # Create a model from a catalog of the specified name
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'CATALOG');
      item.set('isModel', private.model_type('CATALOG'));
      item.set('catalogname', catalogname);
      return item;
   };

   const public.print := function(model)
   {
   # Print a model data item
   #
      wider public, private;

      # Case type of:
      type := model.get('name');
      # IMAGE: 
      if (type == 'IMAGE') {
         images := model.get('images');
         complist := model.get('complist');
         note(spaste('Images= ', images));
         note(spaste('Complist= ', complist));
      };
      return T;
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
      return 'modelmanager';
   }

   plugins.attach('modelmanager', public);
   return ref public;

} # _define_modelmanager()

#
# Null constructor
#
const modelmanager := function() {
#   
   return ref _define_modelmanager();
} 

#
# Create default model manager, and return its name
#
const createdefaultmodelmanager := function() {
#
   if (!serverexists('dmm', 'modelmanager', dmm)) {
      global dmm, defaultmodelmanager;
      const defaultmodelmanager := modelmanager();
      const dmm := ref defaultmodelmanager;
      note ('defaultmodelmanager (dmm) ready for use', priority='NORMAL',
         origin='modelmanager');
   };
   return 'dmm';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const modelmanagerdemo:=function() {
   mymm:=modelmanager();
   note(paste("Demonstation of ", mymm.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const modelmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dmm, the default model manager
createdefaultmodelmanager();
#------------------------------------------------------------------------

