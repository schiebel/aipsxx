# slvlistmanager: data manager for a solverlist data item
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
# $Id: slvlistmanager.g,v 19.2 2004/08/25 01:26:27 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for solverlist data item type
#
const is_solverlist:= function (const item)
{
# Is this variable a valid solverlist item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isSolverList')) {
     valid := T;
   };
   return valid;
};  

#
# Define a solverlist manager instance
#
const _define_solverlistmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.solverlist_type := function (const type)
   {
   # Define enum values for the solverlist type
   #
   #   -1 = undefined
   #    0 = SOLVERLIST
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='solverlistmanager.solverlist_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'SOLVERLIST') {
         enum := 0;
      } else {
         msg := spaste('Unrecognized solverlist type: ',type);
         return throw (msg, 
                       origin='solverlistmanager.solverlist_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.solverlist := function(type1='T', solver1=unset,
                                       type2='G', solver2=unset,
                                       type3='D', solver3=unset,
                                       type4='B', solver4=unset)
      
   {
   # Create a solverlist from a list of types and solvers
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'SOLVERLIST');
      item.set('isSolverList', 
         private.solverlist_type('SOLVERLIST'));
      rec := [=];
      rec[1] := type1;
      rec[2] := type2;
      rec[3] := type3;
      rec[4] := type4;
      item.set('types', rec);
      rec := [=];
      rec[1] := solver1;
      rec[2] := solver2;
      rec[3] := solver3;
      rec[4] := solver4;
      item.set('solvers', rec);
      return item;
   };

   const public.types := function(solverlist)
   {
   # Return the valid solver types contained in a solver list data item
   #
      wider private, public;

      # Initialization
      solvetypes := as_string([]);
      n := 0;

      # Retrieve the list of solvers
      types := solverlist.get('types');
      solvers := solverlist.get('solvers');
      nsolve := len(solvers);

      # Compile a list of valid solver types
      for (jsolve in 1:nsolve) {
         if (!is_unset(solvers[jsolve]) && is_solver(solvers[jsolve])) {
            n +:= 1;
            solvetypes[n] := types[jsolve];
         };
      };
      return solvetypes;
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
      return 'solverlistmanager';
   }

   plugins.attach('solverlistmanager', public);
   return ref public;

} # _define_solverlistmanager()

#
# Null constructor
#
const solverlistmanager := function() {
#   
   return ref _define_solverlistmanager();
} 

#
# Create default solverlist manager, and return its name
#
const createdefaultsolverlistmanager := function() {
#
   if (!serverexists('dsl', 'solverlistmanager', dsl)) {
      global dsl, defaultsolverlistmanager;
      const defaultsolverlistmanager := solverlistmanager();
      const dsl := ref defaultsolverlistmanager;
      note ('defaultsolverlistmanager (dsl) ready for use', 
         priority='NORMAL', origin='solverlistmanager');
   };
   return 'dsl';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const solverlistmanagerdemo:=function() {
   mysl:=solverlistmanager();
   note(paste("Demonstation of ", mysl.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const solverlistmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dsl, the default solverlist manager
createdefaultsolverlistmanager();
#------------------------------------------------------------------------

