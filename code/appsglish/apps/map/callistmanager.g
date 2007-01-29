# callistmanager: data manager for a calibrationlist data item
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
# $Id: callistmanager.g,v 19.1 2004/08/25 01:22:51 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'calmanager.g';
include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for calibrationlist data item type
#
const is_calibrationlist:= function (const item)
{
# Is this variable a valid calibrationlist item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isCalibrationList')) {
     valid := T;
   };
   return valid;
};  

#
# Define a calibrationlist manager instance
#
const _define_calibrationlistmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.calibrationlist_type := function (const type)
   {
   # Define enum values for the calibrationlist type
   #
   #   -1 = undefined
   #    0 = CALIBRATIONLIST
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='calibrationlistmanager.calibrationlist_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'CALIBRATIONLIST') {
         enum := 0;
      } else {
         msg := spaste('Unrecognized calibrationlist type: ',type);
         return throw (msg, 
                       origin='calibrationlistmanager.calibrationlist_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.calibrationlist := function(type1='T', calibration1=unset,
                                            type2='G', calibration2=unset,
                                            type3='D', calibration3=unset,
                                            type4='B', calibration4=unset,
                                            type5='VP', calibration5=unset)
   {
   # Create a calibrationlist containing a list of types and calibration
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'CALIBRATIONLIST');
      item.set('isCalibrationList', 
         private.calibrationlist_type('CALIBRATIONLIST'));
      rec := [=];
      rec[1] := type1;
      rec[2] := type2;
      rec[3] := type3;
      rec[4] := type4;
      rec[5] := type5;
      item.set('types', rec);
      rec := [=];
      rec[1] := calibration1;
      rec[2] := calibration2;
      rec[3] := calibration3;
      rec[4] := calibration4;
      rec[5] := calibration5;
      item.set('calibrations', rec);
      return item;
   };

   const public.print := function(calibrationlist=unset)
   {
   # Print a calibration list data item
   #
      wider private, public;

      if (!is_unset(calibrationlist)) {
         # Retrieve calibration list
         types := calibrationlist.get('types');
         calibrations := calibrationlist.get('calibrations');
         ncal := len(types);
         
         # Print each calibration item
         note('=============================================================');
         note('Calibration list');
         note('-------------------------------------------------------------');
         for (jcal in 1:ncal) {
            if (!is_unset(calibrations[jcal])) {
               note(paste('Type:', types[jcal]));
               dcm.print(calibrations[jcal]);
            };
         };
         note('=============================================================');
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
      return 'calibrationlistmanager';
   }

   plugins.attach('calibrationlistmanager', public);
   return ref public;

} # _define_calibrationlistmanager()

#
# Null constructor
#
const calibrationlistmanager := function() {
#   
   return ref _define_calibrationlistmanager();
} 

#
# Create default calibrationlist manager, and return its name
#
const createdefaultcalibrationlistmanager := function() {
#
   if (!serverexists('dcl', 'calibrationlistmanager', dcl)) {
      global dcl, defaultcalibrationlistmanager;
      const defaultcalibrationlistmanager := calibrationlistmanager();
      const dcl := ref defaultcalibrationlistmanager;
      note ('defaultcalibrationlistmanager (dcl) ready for use', 
         priority='NORMAL', origin='calibrationlistmanager');
   };
   return 'dcl';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const calibrationlistmanagerdemo:=function() {
   mycl:=calibrationlistmanager();
   note(paste("Demonstation of ", mycl.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const calibrationlistmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dcl, the default calibrationlist manager
createdefaultcalibrationlistmanager();
#------------------------------------------------------------------------

