//# GTkMWCCTPositioner.h: GlishTk-based MultiPanel crosshair tool positioner
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
//# $Id: GTkMWCCTPositioner.h,v 19.5 2005/06/15 18:09:12 cvsmgr Exp $

#ifndef TRIALDISPLAY_GTKMWCCTPOSITIONER_H
#define TRIALDISPLAY_GTKMWCCTPOSITIONER_H

//aips
#include <casa/aips.h>

//trialdisplay
#include <display/DisplayEvents/MWCCrosshairTool.h>

namespace casa {
   class GTkMultiPanel;

class GTkMWCCTPositioner : public MWCCrosshairTool {

 public:

  // Constructor.
  GTkMWCCTPositioner(GTkMultiPanel* gtkpdisplay,
		     Display::KeySym keysym = Display::K_Pointer_Button1,
		     String eventname = "pseudoposition");
  
  // Destructor.
  virtual ~GTkMWCCTPositioner();

 protected:

  // Emit the position to Glish.
  // evtype is "down" "move" or "up" depending on the state of the
  // mouse leading to this event.
  virtual void crosshairReady(const String& evtype);

 private:

  // we need this to know where to send Tk events...
  GTkMultiPanel *itsGTkMultiPanel;
  
  // this is the name of the event to emit
  String itsEventName;

};

} 

#endif
