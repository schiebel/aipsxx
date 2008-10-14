//# GTkMWCRTRegion.cc: GlishTk-based MultiPanel rectangle region drawing
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
//# $Id: GTkMWCRTRegion.cc,v 19.5 2005/06/15 18:09:13 cvsmgr Exp $

// aips includes:
#include <casa/aips.h>
#include <casa/Arrays/ArrayMath.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishRecord.h>
#include <casa/BasicSL/String.h>

// trial includes:

// display library includes:
#include "GTkMultiPanel.h"
#include <display/Display/WorldCanvasHolder.h>
#include <display/Display/WorldCanvas.h>
#include <display/Display/PanelDisplay.h>

// this include:
#include "GTkMWCRTRegion.h"

namespace casa {
GTkMWCRTRegion::GTkMWCRTRegion(GTkMultiPanel *gtkpdisplay,
			       Display::KeySym keysym, 
			       String eventname) :
  MWCRTRegion(keysym),
  itsGTkMultiPanel(gtkpdisplay),
  itsEventName(eventname) {  
}

GTkMWCRTRegion::~GTkMWCRTRegion() {
}

void GTkMWCRTRegion::regionReady() {
  GlishRecord emit, pixel, linear, world;
  static Vector<Double> from(2), to(2);
  
  emit.add(String("type"), GlishArray(String("box")));
  emit.add(String("oneRel"), GlishArray(Bool(False)));
  
  Int x1, y1, x2, y2;
  get(x1, y1, x2, y2);

  from(0) = min(x1, x2);
  from(1) = min(y1, y2);
  pixel.add(String("blc"), GlishArray(from));
  itsCurrentWC->pixToLin(to, from);
  linear.add(String("blc"), GlishArray(to));
  itsCurrentWC->linToWorld(from, to);
  world.add(String("blc"), GlishArray(from));

  from(0) = max(x1, x2);
  from(1) = max(y1, y2);
  pixel.add(String("trc"), GlishArray(from));
  itsCurrentWC->pixToLin(to, from);
  linear.add(String("trc"), GlishArray(to));
  itsCurrentWC->linToWorld(from, to);
  world.add(String("trc"), GlishArray(from));

  emit.add(String("pixel"), pixel);
  emit.add(String("linear"), linear);
  emit.add(String("world"), world);
  Int zindex = -1;// non-value
  WorldCanvasHolder* wch = itsGTkMultiPanel->panelDisplay()->wcHolder(itsCurrentWC);

  String att("zIndex");
  if (wch->restrictionBuffer()->exists(att)) {
    wch->restrictionBuffer()->getValue(att, zindex);
    zindex++; // for zero->one offset
  }
  
  emit.add(String("zindex"), GlishArray(zindex));
  emit.add(String("units"), wch->worldAxisUnits());
  
  itsGTkMultiPanel->postEvent(itsEventName, emit);
}

void GTkMWCRTRegion::rectangleReady() {
  String store = itsEventName;
  itsEventName = store + String("ready");
  regionReady();
  itsEventName = store;
}

}
