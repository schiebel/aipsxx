//# GTkSlicePD.h: GlishTk implementation of the SlicePD class
//# Copyright (C) 2000,2001
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
//# $Id: GTkSlicePD.h,v 19.5 2005/06/15 18:09:13 cvsmgr Exp $

#ifndef TRIALDISPLAY_GTKSLICEPD_H
#define TRIALDISPLAY_GTKSLICEPD_H

#include <casa/aips.h>
#include <display/Display/PanelDisplay.h>
#include <display/Display/SlicePanelDisplay.h>
#include "GTkMultiPanel.h"
#include "GTkDisplayProxy.h"

namespace casa {
   class PixelCanvas;
   class GTkPixelCanvas;

class GTkSlicePD : public GTkDisplayProxy,
		   public GTkMultiPanel {

public:  
  // constructor for GTkPixelCanvas as a base pixelcanvas: this should
  // only be called from within the static global function
  // GTkSlicePD::Create, which is registered with GlishTk to build
  // widgets of this type
  GTkSlicePD(ProxyStore *s, GTkPixelCanvas *gtkpc);

  // destructor; this is used to unmap the widget from the 
  // display, and destroy its contents.
  ~GTkSlicePD();

  // Return the stored PanelDisplay for those who are interested.
  PanelDisplay *panelDisplay()
  { return itsSlicePD->activePanelDisplay(); };

  virtual void postEvent(const String& name, const GlishRecord& rec);

  // various event handlers
  void operator()(const WCMotionEvent &ev);

  // over-ride the base class IsValid function to allow for 
  // non-graphic agents which are valid even though self is 0.
  int IsValid() const;

  // over-ride the base class replyIfPending function to also
  // deliver refresh events to glish when necessary...
  virtual void replyIfPending(const casa::Bool &value = True);

  // agent command: query the status of this widget
  char *status(Value *args);

  // agent commands: hold/release refresh of the SlicePD
  // <group>
  char *hold(Value *args);
  char *release(Value *args);
  // </group>

  // agent commands: add/remove a displaydata agent to/from this SlicePD
  // <group>
  char *add(Value *args);
  char *remove(Value *args);
  // </group>

  // <group>
  char *getoptions(Value *args);
  char *setoptions(Value *args);
  // </group>

  // <group>
  char *unzoom(Value *args);
  char *setzoom(Value *args);
  // </group>

  // <group>
  char *disabletools(Value *args);
  char *enabletools(Value *args);
  char* settoolkey(Value* args);
  // </group>

  char *precompute(Value *args);

private:
  
  // Display library components
  PixelCanvas* itsPixelCanvas;
  SlicePanelDisplay* itsSlicePD;

  // position tracking state
  casa::Bool itsTrackingState;

  // store whether we are valid - must only be examined if
  // this is non-graphic
  int itsIsValid;

  void installTools();

};
}

#endif
