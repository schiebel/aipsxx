//# GTkMWCCTPositioner.cc: GlishTk-based WorldCanvas crosshair tool positioner
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
//# $Id: GTkMWCCTPositioner.cc,v 19.4 2005/06/15 18:09:12 cvsmgr Exp $

#include <casa/aips.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishRecord.h>
#include <display/Display/WorldCanvas.h>
#include <display/Display/WorldCanvasHolder.h>
#include <display/Display/PanelDisplay.h>

#include "GTkMultiPanel.h"
#include "GTkMWCCTPositioner.h"

namespace casa {

GTkMWCCTPositioner::GTkMWCCTPositioner(GTkMultiPanel *gtkpdisplay,
				     Display::KeySym keysym,
				     String eventname) :
  MWCCrosshairTool(keysym),
  itsGTkMultiPanel(gtkpdisplay),
  itsEventName(eventname) {
}

GTkMWCCTPositioner::~GTkMWCCTPositioner() {
}

void GTkMWCCTPositioner::crosshairReady(const String& evtype) {
  GlishRecord emit, pixel, linear, world;
  static Vector<Double> from(2), to(2);

  emit.add(String("type"), GlishArray(String("point")));
  emit.add(String("oneRel"), GlishArray(casa::Bool(False)));

  Int x,y;  get(x,y);
  from(0)=x; from(1)=y;

  emit.add(String("pixel"), GlishArray(from));
  itsCurrentWC->pixToLin(to, from);
  emit.add(String("linear"), GlishArray(to));
  itsCurrentWC->linToWorld(from, to);
  emit.add(String("world"), GlishArray(from));

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
  emit.add(String("evtype"), GlishArray(evtype));

  itsGTkMultiPanel->postEvent(itsEventName, emit);

}

}
