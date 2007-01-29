# calmanager: data manager for a calibration data item
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
# $Id: calmanager.g,v 19.1 2004/08/25 01:23:06 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for calibration data item type
#
const is_calibration:= function (const item)
{
# Is this variable a valid calibration item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isCalibration')) {
     valid := T;
   };
   return valid;
};  

#
# Define a calibration manager instance
#
const _define_calibrationmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.calibration_type := function (const type)
   {
   # Define enum values for the calibration type
   #
   #   -1 = undefined
   #    0 = GENERAL
   #    1 = VP
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='calibrationmanager.calibration_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'GENERAL') {
         enum := 0;
      } else if (tmp == 'VP') {
         enum := 1;
      } else {
         msg := spaste('Unrecognized calibration type: ',type);
         return throw (msg, origin='calibrationmanager.calibration_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.general := function(t=0, table='', select='')
   {
   # Create a calibration data item for a general VisJones matrix
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'GENERAL');
      item.set('isCalibration', private.calibration_type('GENERAL'));
      item.set('t', t);
      item.set('table', table);
      item.set('select', select);
      return item;
   };

   const public.vp := function(usedefaultvp=T, vptable='', dosquint=T,
                               parangleinc='360deg')
   {
   # Create a calibration data item for a VP SkyJones 
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'VP');
      item.set('isCalibration', private.calibration_type('VP'));
      item.set('usedefaultvp', usedefaultvp);
      item.set('vptable', vptable);
      item.set('dosquint', dosquint);
      item.set('parangleinc', parangleinc);
      return item;
   };

   const public.print := function(calibration=unset)
   {
   # Print a calibration data item
   #
      wider private, public;

      if (!is_unset(calibration)) {
         # Use case on type later
         t := calibration.get('t');
         table := calibration.get('table');
         select := calibration.get('select');
         note(paste('t=', t, 'table=', table, 'select=', select));
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
      return 'calibrationmanager';
   }

   plugins.attach('calibrationmanager', public);
   return ref public;

} # _define_calibrationmanager()

#
# Null constructor
#
const calibrationmanager := function() {
#   
   return ref _define_calibrationmanager();
} 

#
# Create default calibration manager, and return its name
#
const createdefaultcalibrationmanager := function() {
#
   if (!serverexists('dcm', 'calibrationmanager', dcm)) {
      global dcm, defaultcalibrationmanager;
      const defaultcalibrationmanager := calibrationmanager();
      const dcm := ref defaultcalibrationmanager;
      note ('defaultcalibrationmanager (dcm) ready for use', priority='NORMAL',
         origin='calibrationmanager');
   };
   return 'dcm';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const calibrationmanagerdemo:=function() {
   mycm:=calibrationmanager();
   note(paste("Demonstation of ", mycm.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const calibrationmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dcm, the default calibration manager
createdefaultcalibrationmanager();
#------------------------------------------------------------------------

