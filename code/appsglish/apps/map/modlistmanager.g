# modlistmanager: data manager for a modellist data item
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
# $Id: modlistmanager.g,v 19.1 2004/08/25 01:25:51 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for modellist data item type
#
const is_modellist:= function (const item)
{
# Is this variable a valid modellist item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isModelList')) {
     valid := T;
   };
   return valid;
};  

#
# Define a modellist manager instance
#
const _define_modellistmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.modellist_type := function (const type)
   {
   # Define enum values for the modellist type
   #
   #   -1 = undefined
   #    0 = MODELLIST
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='modellistmanager.modellist_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'MODELLIST') {
         enum := 0;
      } else {
         msg := spaste('Unrecognized modellist type: ',type);
         return throw (msg, origin='modellistmanager.modellist_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.modellist := function(source1='', model1=unset,
                                      source2='', model2=unset,
                                      source3='', model3=unset,
                                      source4='', model4=unset,
                                      source5='', model5=unset,
                                      source6='', model6=unset,
                                      source7='', model7=unset,
                                      source8='', model8=unset,
                                      source9='', model9=unset)
      
   {
   # Create a modellist from a list of source names and associated models
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'MODELLIST');
      item.set('isModelList', private.modellist_type('MODELLIST'));
      rec := [=];
      rec[1] := source1;
      rec[2] := source2;
      rec[3] := source3;
      rec[4] := source4;
      rec[5] := source5;
      rec[6] := source6;
      rec[7] := source7;
      rec[8] := source8;
      rec[9] := source9;
      item.set('sources', rec);
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
      return item;
   };

   const public.print := function(modellist=unset)
   {
   # Print a model list data item
   #
      wider private, public;

      # Retrieve model list
      sources := modellist.get('sources');
      models := modellist.get('models');
      nmodels := len(sources);
      note('===============================================================');
      note('Model list');
      note('---------------------------------------------------------------');

      # Loop over models
      for (jmodel in 1:nmodels) {
         if (!is_unset(models[jmodel]) && !is_unset(sources[jmodel])) {
            note(spaste('Source: ', sources[jmodel]));
            dmm.print(models[jmodel]);
         };
      };
      note('===============================================================');
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
      return 'modellistmanager';
   }

   plugins.attach('modellistmanager', public);
   return ref public;

} # _define_modellistmanager()

#
# Null constructor
#
const modellistmanager := function() {
#   
   return ref _define_modellistmanager();
} 

#
# Create default modellist manager, and return its name
#
const createdefaultmodellistmanager := function() {
#
   if (!serverexists('dml', 'modellistmanager', dml)) {
      global dml, defaultmodellistmanager;
      const defaultmodellistmanager := modellistmanager();
      const dml := ref defaultmodellistmanager;
      note ('defaultmodellistmanager (dml) ready for use', priority='NORMAL',
         origin='modellistmanager');
   };
   return 'dml';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const modellistmanagerdemo:=function() {
   myml:=modellistmanager();
   note(paste("Demonstation of ", myml.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const modellistmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dml, the default modellist manager
createdefaultmodellistmanager();
#------------------------------------------------------------------------

