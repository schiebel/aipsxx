//# GTkMWCPolyLine.cc: GlishTk-based MultiPanel polyline drawing
//# Copyright (C) 2004
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
//# $Id:

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
#include "GTkMWCPolyLine.h"

namespace casa {
GTkMWCPolyLine::GTkMWCPolyLine(GTkMultiPanel* gtkpdisplay,
			       Display::KeySym keysym, 
			       String eventname) :
  MWCPolylineTool(keysym),
  itsGTkMultiPanel(gtkpdisplay),
  itsEventName(eventname) {  
}

GTkMWCPolyLine::~GTkMWCPolyLine() {
}

void GTkMWCPolyLine::polylineReady() {
  GlishRecord emit, pixel, linear, world;
  Vector<Int> x, y;
  get(x, y);
  pixel.add(String("x"), GlishArray(x));
  pixel.add(String("y"), GlishArray(y));

  uInt npoints = x.nelements();
  Vector<Double> t(npoints), u(npoints);
  Vector<Double> v(npoints), w(npoints);
  Vector<Double> to(2), from(2);
  for (uInt i = 0; i < npoints; i++) {
    from(0) = x(i);
    from(1) = y(i);
    itsCurrentWC->pixToLin(to, from);
    t(i) = to(0);
    u(i) = to(1);
    itsCurrentWC->linToWorld(from, to);
    v(i) = from(0);
    w(i) = from(1);
  }
  linear.add(String("x"), GlishArray(t));
  linear.add(String("y"), GlishArray(u));
  world.add(String("x"), GlishArray(v));
  world.add(String("y"), GlishArray(w));
  
  emit.add(String("pixel"), pixel);
  emit.add(String("linear"), linear);
  emit.add(String("world"), world);
  Int zindex = -1;
  WorldCanvasHolder* wch = 
    itsGTkMultiPanel->panelDisplay()->wcHolder(itsCurrentWC);

  String att("zIndex");
  if (wch->restrictionBuffer()->exists(att)) {
    wch->restrictionBuffer()->getValue(att, zindex);
    zindex++; // for zero->one offset
  }
  
  emit.add(String("zindex"), GlishArray(zindex));
  emit.add(String("units"), wch->worldAxisUnits());

  itsGTkMultiPanel->postEvent(itsEventName, emit);
}

}
