# viewerimageshowregions.g: Viewer support for display of regions on images
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
# $Id: viewerimageshowregions.g,v 19.1 2005/06/15 18:10:58 cvsmgr Exp $
#

pragma include once

include 'note.g'
include 'serverexists.g'
#
include 'coordsys.g'
include 'regionmanager.g'
include 'quanta.g'

const viewerimageshowregions := subsequence (ddd)
{
    if (!serverexists('drm', 'regionmanager', drm)) {
       return throw('The regionmanager server "drm" is not running',
                     origin='viewerimageshowregions.g');
    }
    if (!serverexists('dq', 'quanta', dq)) {
       return throw('The quanta server "dq" is not running',
                     origin='viewerimageshowregions.g');
    }
#
    its := [=];
    its.ddd := ddd;                        # Registered Drawing display data
#

### Private methods


###
   const its.makedddrec := function (region)
#
# Convert a simple region to a DDD record and create the DDD
# Probably this should be in regionmanager, or regionmanager
# provides some of the info through functions.
#
   {
      local dddrec;
      regionrec := region.torecord();
      if (is_fail(regionrec)) fail;
      csys := coordsys();
      ok := csys.fromrecord(regionrec.coordinates);
      if (is_fail(ok)) fail;
#
      name := to_upper(regionrec.name);
      absrel := regionrec.absrel;
#
      if (name=='WCBOX') {
         pixelaxes := regionrec.pixelAxes;
         if (length(pixelaxes)<2) {
            return throw ('blc/trc must be of length at least 2', 
                          origin='viewerimageshowregions.makedddrec');
         }
#
         for (i in length(absrel)) {
            if (absrel[i]!=1) {
               return throw ('Can currently only handle region with absolute coordinates', 
                             origin='viewerimageshowregions.makedddrec');
            }
         }
#
         blc := regionrec.blc;
         trc := regionrec.trc;      
#
         if (length(blc) != length(trc)) {
            return throw ('blc and trc must be the same length', 
                          origin='viewerimageshowregions.makedddrec');
         }

# pixelaxes says which pixel axes of the CS embedded in the
# region the blc/trc pertain to.   What we want to display
# is the blc/trc of the region that pertain to the first two
# display axes.  For now assume the latter are the first 2 pixelaxes
# of the csys.  this is a bad assumption !  I don't think I will
# try to handle this until we do some serious thinking on DDs
# and reimplement much of this in C++

         p2w := csys.axesmap(toworld=T);      # Map from pixel to world
         worldaxes := p2w[pixelaxes];
         wBlc := csys.referencevalue(format='q');
#
         wBlc[worldaxes[1]] := blc[1];
         wBlc[worldaxes[2]] := blc[2];
         pBlc := csys.topixel(wBlc);
         if (is_fail(pBlc)) fail;
#
         wTrc := csys.referencevalue(format='q');
         wTrc[worldaxes[1]] := trc[1];
         wTrc[worldaxes[2]] := trc[2];
         pTrc := csys.topixel(wTrc);
         if (is_fail(pTrc)) fail;
#
         pTlc := pBlc;
         pTlc[pixelaxes[2]] := pTrc[pixelaxes[2]];
         wTlc := csys.toworld(pTlc, 'q');
         if (is_fail(wTlc)) fail;
#
         pBrc := pTrc;
         pBrc[pixelaxes[2]] := pBlc[pixelaxes[2]];
         wBrc := csys.toworld(pBrc, 'q');
         if (is_fail(wBrc)) fail;
#
         xUnit := dq.getunit(wBlc[worldaxes[1]]);
         yUnit := dq.getunit(wBlc[worldaxes[2]]);
#
         xValues := [dq.getvalue(dq.convert(wBlc[worldaxes[1]], xUnit)),
                     dq.getvalue(dq.convert(wTlc[worldaxes[1]], xUnit)),
                     dq.getvalue(dq.convert(wTrc[worldaxes[1]], xUnit)),
                     dq.getvalue(dq.convert(wBrc[worldaxes[1]], xUnit))];
         if (is_fail(xValues)) fail;
#
         yValues := [dq.getvalue(dq.convert(wBlc[worldaxes[2]], yUnit)),
                     dq.getvalue(dq.convert(wTlc[worldaxes[2]], yUnit)),
                     dq.getvalue(dq.convert(wTrc[worldaxes[2]], yUnit)),
                     dq.getvalue(dq.convert(wBrc[worldaxes[2]], yUnit))];
         if (is_fail(yValues)) fail;
#
         x := dq.quantity(xValues, xUnit);
         if (is_fail(x)) fail;
         y := dq.quantity(yValues, yUnit);
         if (is_fail(y)) fail;

# We use a polygon as I am having some trouble getting my widths
# right otherwise.  

         dddrec := its.ddd.makepolygon(x=x, y=y, outline=T, movable=F, editable=F);      
      } else if (name=='WCPOLYGON') {
         if (absrel!=1) {
            return throw ('Can currently only handle regions with absolute coordinates', 
                          origin='viewerimageshowregions.makedddrec');
         }
#
         x := regionrec.x;
         y := regionrec.y;
         x::id := 'quant';     # FUDGE (see above)
         y::id := 'quant';
         dddrec := its.ddd.makepolygon(x=x, y=y, outline=T, movable=F, editable=F);
      } 
#
      return dddrec;
   }

###
   const its.showsimpleregions := function (region)
#
# Fish out the simple regions and display them
#
   {
      regions := drm.extractsimpleregions (region);
      if (is_fail(regions)) fail;
#
      ids := [=];
      n := length(regions);
      if (n > 0) {
         j := 1;
         for (i in 1:n) {
            d := F;
            if (regions[i].has_item('display')) {
              d := regions[i].get('display');
            }
            display := !(regions[i].has_item('display')) || d==T;
#
            if (display) {
               dddrec := its.makedddrec(regions[i]); 
               if (is_fail(dddrec)) fail;
#
               if (length(dddrec)>0) {
                 id := its.ddd.add(dddrec);
                 if (is_fail(id)) fail;
#
                 ids[j] := id;
                 j +:= 1;
               }
            }
         }         
      } else {
         note ('There are no simple regions to display', priority='WARN',
               origin='viewerimageshowregions.showsimpleregions');
      }
#
      return ids;
   }


### Public methods


###
   const self.hide := function (ids)
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
   const self.show := function (im, region, display=T, list=T)
#
# This function is very rudimentary presently.  DDDs/region interface
# needs quite some work. Some of it should be in regionmanager,
# some in the DDD itself (e.g. construct from region record)
#
   {
      wider its;
#
      if (list) {
         txt := spaste('Bounding box = ', as_string(im.boundingbox(region=region)));
         note (txt, priority='NORMAL', origin='viewerimageshowregions.showRegion');
      }
#
      ids := [=];
      if (display) {
         ids := its.showsimpleregions (region);
         if (is_fail(ids)) fail;
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
