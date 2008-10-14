//# GTkMWCPanner.cc: Glish/Tk implementation of WorldCanvas event-based zooming
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
#include "GTkMWCPanner.h"


namespace casa {
GTkMWCPanner::GTkMWCPanner(GTkMultiPanel* gtkpdisplay,
			   Display::KeySym keysym, 
			   String eventname) :
  MWCPannerTool(keysym),
  itsGTkMultiPanel(gtkpdisplay),
  itsEventName(eventname) {
}

GTkMWCPanner::~GTkMWCPanner() {
}

void GTkMWCPanner::zoomed(const Vector<Double>& blc, 
			    const Vector<Double>& trc) {

  GlishRecord emit, pixel, linear, world;
  static Vector<Double> from(2), to(2);
  
  emit.add(String("oneRel"), GlishArray(Bool(False)));
  
  itsCurrentWC->linToPix(to, blc);
  pixel.add(String("comment"),GlishArray(String("of first WC")));
  pixel.add(String("blc"), GlishArray(to));

  itsCurrentWC->linToPix(to, trc);
  pixel.add(String("trc"), GlishArray(to));

  linear.add(String("blc"), GlishArray(blc));
  linear.add(String("trc"), GlishArray(trc));

  
  itsCurrentWC->linToWorld(to, blc);
  world.add(String("blc"), GlishArray(to));
  itsCurrentWC->linToWorld(to, trc);
  world.add(String("trc"), GlishArray(to));

  emit.add(String("pixel"), pixel);
  emit.add(String("linear"), linear);
  emit.add(String("world"), world);
  emit.add(String("units"),
	   itsGTkMultiPanel->panelDisplay()->wcHolder(itsCurrentWC)->worldAxisUnits());
  
  itsGTkMultiPanel->postEvent(itsEventName, emit);
}

}
