# solvermanager: data manager for a solver data item
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
# $Id: solvermanager.g,v 19.1 2004/08/25 01:26:42 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for solver data item type
#
const is_solver:= function (const item)
{
# Is this variable a valid solver item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isSolver')) {
     valid := T;
   };
   return valid;
};  

#
# Define a solver manager instance
#
const _define_solvermanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.solver_type := function (const type)
   {
   # Define enum values for the solver type
   #
   #   -1 = undefined
   #    0 = GENERAL
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='solvermanager.solver_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'GENERAL') {
         enum := 0;
      } else {
         msg := spaste('Unrecognized solver type: ',type);
         return throw (msg, origin='solvermanager.solver_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.general := function(t=60, preavg=60, phaseonly=F, refant=-1,
                                    table='', append=F, unset=F)
   {
   # Create a solver data item for a general VisJones matrix
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'GENERAL');
      item.set('isSolver', private.solver_type('GENERAL'));
      item.set('t', t);
      item.set('preavg', preavg);
      item.set('phaseonly', phaseonly);
      item.set('refant', refant);
      item.set('table', table);
      item.set('append', append);
      item.set('unset', unset);
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
      return 'solvermanager';
   }

   plugins.attach('solvermanager', public);
   return ref public;

} # _define_solvermanager()

#
# Null constructor
#
const solvermanager := function() {
#   
   return ref _define_solvermanager();
} 

#
# Create default solver manager, and return its name
#
const createdefaultsolvermanager := function() {
#
   if (!serverexists('dsv', 'solvermanager', dsv)) {
      global dsv, defaultsolvermanager;
      const defaultsolvermanager := solvermanager();
      const dsv := ref defaultsolvermanager;
      note ('defaultsolvermanager (dsv) ready for use', priority='NORMAL',
         origin='solvermanager');
   };
   return 'dsv';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const solvermanagerdemo:=function() {
   mysv:=solvermanager();
   note(paste("Demonstation of ", mysv.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const solvermanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dsv, the default solver manager
createdefaultsolvermanager();
#------------------------------------------------------------------------

