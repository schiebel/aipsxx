# viewershowcomponentlist.g: Viewer support for display of componentlists
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
# $Id: viewershowcomponentlist.g,v 19.1 2005/06/15 18:10:59 cvsmgr Exp $
#

pragma include once

include 'note.g'
include 'serverexists.g'
#
include 'componentlist.g'
include 'quanta.g'
include 'viewer.g'

const viewershowcomponentlist := subsequence (ddd, beam=unset)
{
    if (!serverexists('dq', 'quanta', dq)) {
       return throw('The quanta server "dq" is not running',
                     origin='viewerimageshowcomponentlist.g');
    }
#
    its := [=];
    its.ddd := ddd;                        # Registered Drawing display data
    its.beam := beam;
#

### Private methods


###
   const its.makedddrec := function (type, dir, shape, color)
   {
      local dddrec;
#
      center := dm.getvalue(dir);
      tp := to_upper(type);
#
      major := dq.quantity('0.0000002arcsec');
      minor := dq.quantity('0.0000001arcsec');
      pa := dq.quantity('0deg');
#
      if (tp=='POINT') {
         if (!is_unset(its.beam)) {
            major := its.beam.major;
            minor := its.beam.minor;
            pa := its.beam.positionangle;
         }
      } else {
         if (has_field(shape, 'majoraxis')) {
            major := shape.majoraxis;
            minor := shape.minoraxis;
            pa := shape.positionangle;
         } 
      }
#
      col := color;
      if (is_unset(color)) col := 'foreground'
#
      dddrec := its.ddd.makeellipse (center=center, major=major, 
                                     minor=minor, positionangle=pa,
                                     outline=T, movable=F, editable=F,
                                     doreference=F, color=col);
#
      return dddrec;
   }


###
   const its.showcomponent := function (type, dir, shape, color)
   {
      wider its;
#
      dddrec := its.makedddrec(type, dir, shape, color);
      if (is_fail(dddrec)) fail;
#
      id := [=];
      if (length(dddrec)>0) {
        id := its.ddd.add(dddrec);
        if (is_fail(id)) fail;
      }
#
      return id;
   }


### Public methods


###
   const self.hide := function (ids)
#
# Provide ID record returned by function show
#
   {
      wider its;
#
      for (i in 1:length(ids)) {
         ok := its.ddd.remove(ids[i]);
         if (is_fail(ok)) fail;
      }
#
      return T;
   }

###
   const self.show := function (list, color=unset)
#
# Returns an ID record which should be given to function
# hide to remove the componentlist from the display
#
   {
      wider its;
#
      if (!is_componentlist(list)) {
         return throw ('Given "list" variable is not a Componentlist tool',
                       origin='viewershowcomponentlist.show')
      } 
#
      ids := [=];
      n := list.length();
      if (n > 0) {
         for (i in 1:n) {
            ids[i] := its.showcomponent (list.shapetype(i), list.getrefdir(i), 
                                         list.getshape(i),  color);
            if (is_fail(ids[i])) fail;
         }
      } else {
         note ('There are no components in the Componentlist', priority='WARN', 
               origin='viewershowcomponentlist.show');
      }
#
      return ids;
   }

###
    const self.done := function () 
    {
       wider its, self;
#
       val its := F;
       val self := F;
#
       return T;
   }

### Constructor

}
