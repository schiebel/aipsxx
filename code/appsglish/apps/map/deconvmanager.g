# deconvmanager: data manager for a deconvolution data item
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
# $Id: deconvmanager.g,v 19.1 2004/08/25 01:23:31 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'serverexists.g';
include 'itemcontainer.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';

#
# Check for deconvolution data item type
#
const is_deconvolution:= function (const item)
{
# Is this variable a valid deconvolution item ?
#
   valid := F;
   if (is_itemcontainer(item) && item.has_item('isDeconvolution')) {
     valid := T;
   };
   return valid;
};  

#
# Define a deconvolution manager instance
#
const _define_deconvolutionmanager := function() {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private functions
#------------------------------------------------------------------------
#
   const private.deconvolution_type := function (const type)
   {
   # Define enum values for the deconvolution type
   #
   #   -1 = undefined
   #    0 = CLEAN
   #    1 = MEM
   #    2 = NNLS
   #
      if (!is_string(type)) {
         return throw ('Argument must be a string', 
            origin='deconvolutionmanager.deconvolution_type');
      };
      tmp := to_upper(type);
      enum := -1;
      if (tmp == 'CLEAN') {
         enum := 0;
      } else if (tmp == 'MEM') {
         enum := 1;
      } else if (tmp == 'NNLS') {
         enum := 2;
      } else {
         msg := spaste('Unrecognized deconvolution type: ',type);
         return throw (msg, origin='deconvolutionmanager.deconvolution_type');
      };
      return enum;
   };

#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.clean := function(algorithm='clark', niter=1000, gain=0.1,
                                  threshold='0Jy', interactive=F, 
                                  npercycle=100, scalemethod='nscales',
                                  nscales=5, uservector=[0.0, 3.0, 10.0],
                                  cyclefactor=3.0, cyclespeedup=-1,
                                  stoplargenegatives=2, stoppointmode=-1,
                                  scaletype='NONE', minpb=0.1, constpb=0.3,
                                  displayprogress=F)
   {
   # Create a deconvolution data item from CLEAN deconvolution parameters
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'CLEAN');
      item.set('isDeconvolution', private.deconvolution_type('CLEAN'));
      item.set('algorithm', algorithm);
      item.set('niter', niter);
      item.set('gain', gain);
      item.set('threshold', threshold);
      item.set('interactive', interactive);
      item.set('npercycle', npercycle);
      item.set('scalemethod', scalemethod);
      item.set('nscales', nscales);
      item.set('uservector', uservector);
      item.set('cyclefactor', cyclefactor);
      item.set('cyclespeedup', cyclespeedup);
      item.set('stoplargenegatives', stoplargenegatives);
      item.set('stoppointmode', stoppointmode);
      item.set('scaletype', scaletype);
      item.set('minpb', minpb);
      item.set('constpb', constpb);
      item.set('displayprogress', displayprogress);
      return item;
   };

   const public.mem := function(algorithm='entropy', niter=20, sigma='0.001Jy',
                                targetflux='1.0Jy', constrainflux=F,
                                scalemethod='nscales', nscales=5, 
                                uservector=[0.0, 3.0, 10.0],
                                cyclefactor=3.0, cyclespeedup=-1,
                                stoplargenegatives=2, stoppointmode=-1,
                                scaletype='NONE', minpb=0.1, constpb=0.3,
                                displayprogress=F)
   {
   # Create a deconvolution data item from MEM deconvolution parameters
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'MEM');
      item.set('isDeconvolution', private.deconvolution_type('MEM'));
      item.set('algorithm', algorithm);
      item.set('niter', niter);
      item.set('sigma', sigma);
      item.set('targetflux', targetflux);
      item.set('constrainflux', constrainflux);
      item.set('scalemethod', scalemethod);
      item.set('nscales', nscales);
      item.set('uservector', uservector);
      item.set('cyclefactor', cyclefactor);
      item.set('cyclespeedup', cyclespeedup);
      item.set('stoplargenegatives', stoplargenegatives);
      item.set('stoppointmode', stoppointmode);
      item.set('scaletype', scaletype);
      item.set('minpb', minpb);
      item.set('constpb', constpb);
      item.set('displayprogress', displayprogress);
      return item;
   };

   const public.nnls := function(niter=1000, tolerance=0.0000001,
                                 scalemethod='nscales', nscales=5, 
                                 uservector=[0.0, 3.0, 10.0],
                                 cyclefactor=3.0, cyclespeedup=-1,
                                 stoplargenegatives=2, stoppointmode=-1,
                                 scaletype='NONE', minpb=0.1, constpb=0.3,
                                 displayprogress=F)
   {
   # Create a deconvolution data item from NNLS deconvolution parameters
   #
      wider public, private;
      item := itemcontainer();
      item.set('name', 'NNLS');
      item.set('isDeconvolution', private.deconvolution_type('NNLS'));
      item.set('algorithm', 'nnls');
      item.set('niter', niter);
      item.set('tolerance', tolerance);
      item.set('scalemethod', scalemethod);
      item.set('nscales', nscales);
      item.set('uservector', uservector);
      item.set('cyclefactor', cyclefactor);
      item.set('cyclespeedup', cyclespeedup);
      item.set('stoplargenegatives', stoplargenegatives);
      item.set('stoppointmode', stoppointmode);
      item.set('scaletype', scaletype);
      item.set('minpb', minpb);
      item.set('constpb', constpb);
      item.set('displayprogress', displayprogress);
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
      return 'deconvolutionmanager';
   }

   plugins.attach('deconvolutionmanager', public);
   return ref public;

} # _define_deconvolutionmanager()

#
# Null constructor
#
const deconvolutionmanager := function() {
#   
   return ref _define_deconvolutionmanager();
} 

#
# Create default deconvolution manager, and return its name
#
const createdefaultdeconvolutionmanager := function() {
#
   if (!serverexists('ddm', 'deconvolutionmanager', ddm)) {
      global ddm, defaultdeconvolutionmanager;
      const defaultdeconvolutionmanager := deconvolutionmanager();
      const ddm := ref defaultdeconvolutionmanager;
      note ('defaultdeconvolutionmanager (ddm) ready for use', priority='NORMAL',
         origin='deconvolutionmanager');
   };
   return 'ddm';
};

#
# Define demonstration function: return T if successful otherwise fail
#
const deconvolutionmanagerdemo:=function() {
   mydm:=deconvolutionmanager();
   note(paste("Demonstation of ", mydm.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const deconvolutionmanagertest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#

# Create ddm, the default deconvolution manager
createdefaultdeconvolutionmanager();
#------------------------------------------------------------------------

