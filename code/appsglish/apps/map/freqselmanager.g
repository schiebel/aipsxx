# freqselmanager: data manager for a freqsel data item
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
# $Id: freqselmanager.g,v 19.1 2004/08/25 01:23:41 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for freqsel data item type
#
const is_freqsel:= function (const item)
{
# Is this variable a valid freqsel item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isFreqsel')) {
     valid := T;
   };
   return valid;
};  

#
# Define a freqsel manager instance
#
const _define_freqselmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.freqsel_type := function (const type)
   {
   # Define enum values for the freqsel type
   #
   #   -1 = undefined
   #    0 = CHANNEL
   #    1 = VELOCITY
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='freqselmanager.freqsel_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'CHANNEL') {
         enum := 0;
      } else if (tmp == 'VELOCITY') {
         enum := 1;
      } else {
         msg := spaste('Unrecognized freqsel type: ',type);
         return throw (msg, origin='freqselmanager.freqsel_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.channel := function(nchan=0, start=1, step=1)
   {
   # Create a freqsel data item for channel selection
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'CHANNEL');
      item.set('isFreqsel', private.freqsel_type('CHANNEL'));
      item.set('nchan', nchan);
      item.set('start', start);
      item.set('step', step);
      return item;
   };

   const public.velocity := function(frame='LSR', nchan=1, mstart='0km/s', 
                                     mstep='0km/s')
   {
   # Create a freqsel data item for velocity selection
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'VELOCITY');
      item.set('isFreqsel', private.freqsel_type('VELOCITY'));
      item.set('frame', frame);
      item.set('nchan', nchan);
      item.set('mstart', mstart);
      item.set('mstep', mstep);
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
      return 'freqselmanager';
   }

   plugins.attach('freqselmanager', public);
   return ref public;

} # _define_freqselmanager()

#
# Null constructor
#
const freqselmanager := function() {
#   
   return ref _define_freqselmanager();
} 

#
# Create default freqsel manager, and return its name
#
const createdefaultfreqselmanager := function() {
#
   if (!serverexists('dfq', 'freqselmanager', dfq)) {
      global dfq, defaultfreqselmanager;
      const defaultfreqselmanager := freqselmanager();
      const dfq := ref defaultfreqselmanager;
      note ('defaultfreqselmanager (dfq) ready for use', priority='NORMAL',
         origin='freqselmanager');
   };
   return 'dfq';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const freqselmanagerdemo:=function() {
   myfq:=freqselmanager();
   note(paste("Demonstation of ", myfq.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const freqselmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create dfq, the default freqsel manager
createdefaultfreqselmanager();
#------------------------------------------------------------------------

