//# GTkMWCPolyLine.h: GlishTk-based MultiPanel polyline  drawing
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
//# $Id

#ifndef TRIALDISPLAY_GTKMWCPOLYLINE_H
#define TRIALDISPLAY_GTKMWCPOLYLINE_H

//# aips includes:
#include <casa/aips.h>
#include <casa/Arrays/Vector.h>

//# trial includes:

//# display library includes:
#include <display/DisplayEvents/MWCPolylineTool.h>

namespace casa {
// forwards:
class GTkMultiPanel;

class GTkMWCPolyLine : public MWCPolylineTool {
  
public:
  
  // Constructor.
  GTkMWCPolyLine(GTkMultiPanel *gtkpdisplay,
		 Display::KeySym keysym = Display::K_Pointer_Button1, 
		 String eventname = "polyline");
  
  // Destructor.
  virtual ~GTkMWCPolyLine();

protected:
  
  virtual void polylineReady();
  
private:

  // we need this to know where to send Tk events...
  GTkMultiPanel* itsGTkMultiPanel;
  
  // this is the name of the event to emit
  String itsEventName;

};
}

#endif
