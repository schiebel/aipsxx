//# QtMouseTools.cc: Qt versions of display library mouse tools.
//# Copyright (C) 2005
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//# License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: QtMouseTools.cc,v 1.1 2006/08/11 22:18:39 dking Exp $
//#


#include <display/QtViewer/QtMouseTools.qo.h>
#include <casa/BasicMath/Math.h>
#include <display/Display/WorldCanvas.h>
#include <display/Display/WorldCanvasHolder.h>

namespace casa { //# NAMESPACE CASA - BEGIN

  
  
  
void QtRTRegion::regionReady() {
  
  Record rectRegion,  pixel, linear, world;
  static Vector<Double> pix(2), lin(2), wld(2);
  Int x1, y1, x2, y2;
  
  get(x1, y1, x2, y2);

  pix(0) = min(x1, x2);
  pix(1) = min(y1, y2);
  itsCurrentWC->pixToLin(lin, pix);
  itsCurrentWC->linToWorld(wld, lin);
  
  pixel.define("blc", pix);
  linear.define("blc", lin);
  world.define("blc", wld);

  pix(0) = max(x1, x2);
  pix(1) = max(y1, y2);
  itsCurrentWC->pixToLin(lin, pix);
  itsCurrentWC->linToWorld(wld, lin);
  
  pixel.define("trc", pix);
  linear.define("trc", lin);
  world.define("trc", wld);

  rectRegion.defineRecord("pixel", pixel);
  rectRegion.defineRecord("linear", linear);
  rectRegion.defineRecord("world", world);
  
  WorldCanvasHolder* wch = pd_->wcHolder(itsCurrentWC);
	// Only reason pd_ is 'needed' by this tool (it shouldn't need it):
	// locating the important coordinate state 'zindex' on wch
	// (inaccessible from WC), instead of on WC, was a blunder....

  Int zindex = 0;
  if (wch->restrictionBuffer()->exists("zIndex")) {
    wch->restrictionBuffer()->getValue("zIndex", zindex);  }
  
  rectRegion.define("zindex", zindex);
  rectRegion.define("units", wch->worldAxisUnits());

    
  emit rectangleRegionReady(rectRegion);  }


  
} //# NAMESPACE CASA - END
    
