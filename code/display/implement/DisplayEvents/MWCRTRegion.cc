//# MWCRTRegion.cc: WorldCanvas event-based rectangle region drawer
//# Copyright (C) 1999,2000,2001,2002
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
//# $Id: MWCRTRegion.cc,v 19.5 2005/06/15 18:02:23 cvsmgr Exp $

// aips includes:
#include <casa/aips.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/BasicSL/String.h>

// display library includes:
#include <display/Display/WorldCanvas.h>
#include <display/DisplayEvents/RectRegionEvent.h>
#include <display/DisplayEvents/MWCEvents.h>

// this include:
#include <display/DisplayEvents/MWCRTRegion.h>

namespace casa { //# NAMESPACE CASA - BEGIN

MWCRTRegion::MWCRTRegion(Display::KeySym keysym) :
  MWCRectTool(keysym, True) {
}

MWCRTRegion::~MWCRTRegion() {
}

void MWCRTRegion::doubleInside() {
  Vector<Double> linBlc, linTrc;
  getLinearCoords(linBlc, linTrc);
  if ((fabs(linBlc(0) - linTrc(0)) > Double(0.0)) &&
      (fabs(linBlc(1) - linTrc(1)) > Double(0.0))) {

    Int x1,y1, x2,y2;
    get(x1,y1, x2,y2);
    RectRegionEvent ev(itsCurrentWC, x1,y1, x2,y2);
    itsCurrentWC->handleEvent(ev);
			// send region event to WC's handlers.

    regionReady();  }	// send region event to derived handlers (e.g. Gtk)
}

void MWCRTRegion::getLinearCoords(Vector<Double> &blc, Vector<Double> &trc) {
  // get the pixel coordinates of the rectangular region
  Int x1, y1, x2, y2;
  get(x1, y1, x2, y2);
  // sort them into blc, trc
  static Vector<Double> pixblc(2);
  static Vector<Double> pixtrc(2);
  pixblc(0) = min(x1, x2);
  pixtrc(0) = max(x1, x2);
  pixblc(1) = min(y1, y2);
  pixtrc(1) = max(y1, y2);
  // convert pixel to linear coordinates
  blc.resize(2);
  trc.resize(2);
  itsCurrentWC->pixToLin(blc, pixblc);
  itsCurrentWC->pixToLin(trc, pixtrc);
}

void MWCRTRegion::handleEvent(DisplayEvent& ev) {
  // currently just for reset events.
  ResetRTRegionEvent* rrev = dynamic_cast<ResetRTRegionEvent*>(&ev);
  if(rrev != 0) reset(rrev->skipRefresh());
  MultiWCTool::handleEvent(ev);  }	// Let base class handle too.

} //# NAMESPACE CASA - END

