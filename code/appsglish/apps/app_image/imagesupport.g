# imagesupport.g: Some support services for image.g constructors and functions
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: imagesupport.g,v 19.3 2004/08/25 01:00:10 cvsmgr Exp $
#

pragma include once

include 'coordsys.g'
include 'note.g'
include 'os.g'
include 'regionmanager.g'
include 'serverexists.g'
include 'substitute.g'
include 'unset.g'

const imagesupport := subsequence () 
{
   if (!serverexists('drm', 'regionmanager', drm)) {
      return throw('The regionmanager server "drm" is not running',
                    origin='imagesupport.g');
   }
   if (!serverexists('dos', 'os', dos)) {
      return throw('The os server "dos" is not running',
                    origin='imagesupport.g');
   }
#

### Private functions



### Public functions

   const self.coordinatescheck := function (csys)
#
# Gives back a Glish record, not a coordsys tool
#
   { 
      cs := [=];
      if (!is_unset(csys)) {
         ok := T;
         if (is_coordsys(csys)) {
           cs := csys.torecord();
           if (is_fail(cs)) ok := F;
         } else {
           ok := F;
         }
         if (!ok) {
           return throw('Invalid coordinate system',
                         origin='imagesupport.coordinatescheck');
         }
      }
#
      return cs;
   }

###
   const self.defaultname := function (root) 
   {
      ok := F;
      for (i in 1:1000000) {
        name := spaste(root, i);
        if (!dos.fileexists(name, F)) {
           ok := T;
           break;
        }
      }
      if (ok) {
         return name;
      } else {
         return throw ('Could not find a new temporary file name',
                       origin='imagesupport.defaultname');
      }
   }

###
   const self.unusedtoolname := function (root) 
   {
      ok := F;
      for (i in 1:1000000) {
        name := spaste(root, i);
        if (!is_defined(name)) {
           ok := T;
           break;
        }
      }
      if (ok) {
         return name;
      } else {
         return throw ('Could not find a new unused tool name',
                       origin='imagesupport.unusedtoolname');
      }
   }

###
    const self.maskcheck := function (mask, doRegions=F, ref idrec=[=])
    {
       if (is_string(mask) && length(mask)==1 && mask=='') return '';
#
       local expr;
       if (is_unset(mask)) {
          return '';
       } else if (drm.isworldregion(mask)) {
          if (mask.hasitem('expr')) {   
             expr := mask.get ('expr');
          } else {
             return throw ('This is not a mask region', origin='imagesupport.maskcheck');
          }
       } else if (is_string(mask)) {
          expr := mask;
       } else if (is_boolean(mask)) {
          expr := as_string(mask);      # E.g. T -> 'T'
       } else {
          return throw ('This is not a valid mask expression', origin='imagesupport.maskcheck');
       }
#
# The Image tools will be substituted with ObjectIDs and idrec will not
# hold anything useful so we don't pass it on to the DO
#
       if (doRegions) {
          val idrec := [=];
          return substitute (expr, "image region", idrec=idrec);
       } else {
          local idrec2;
          return substitute (expr, 'image', idrec=idrec2);
       }
    }
         

###
   const self.regioncheck := function (region, csys=unset, torec=T)
   {
      if (length(region)==0 || is_unset(region)) {
         if (torec) {
            return [=];
         } else {
            return drm.wbox(csys=csys);
         }
      } else if (is_region(region)) {
         if (torec) {
            return region.torecord();
         } else {
            return region;
         }
      } else {
         return throw ('Given region object is invalid',
                        origin='imagesupport.regioncheck');
      }
   }
 
###
   const self.done := function ()
   {
      wider self;
      val self := F;
      return T;
   }

###
   const self.type := function ()
   {
      return 'imagesupport';
   }
} 

const defaultimagesupport := imagesupport();

