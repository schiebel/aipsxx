//# GTkMultiPanel.h Absttract class to wrap up different PanelDisplays
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
//# $Id: GTkMultiPanel.h,v 19.5 2005/06/15 18:09:13 cvsmgr Exp $

#ifndef TRIALDISPLAY_GTKMULTIPANEL_H
#define TRIALDISPLAY_GTKMULTIPANEL_H

#include <casa/aips.h>
#include <tasking/Glish/GlishRecord.h>
#include <display/Utilities/DisplayOptions.h>
#include <display/DisplayEvents/WCMotionEH.h>

namespace casa {
   class PanelDisplay;

class GTkMultiPanel : public WCMotionEH,
		      public DisplayOptions {

public:

  GTkMultiPanel() {}; 

  virtual ~GTkMultiPanel() {};

  // Return the stored PanelDisplay to those who are interested.
  virtual PanelDisplay* panelDisplay() = 0;

  // various event handlers
  virtual void operator()(const WCMotionEvent &ev) = 0;
  
  virtual void postEvent(const String& name, const GlishRecord& rec) = 0;

  // over-ride the base class IsValid function to allow for 
  // non-graphic agents which are valid even though self is 0.
  virtual int IsValid() const = 0;

  // over-ride the base class replyIfPending function to also
  // deliver refresh events to glish when necessary...
  virtual void replyIfPending(const Bool &value = True) = 0;

  // agent command: query the status of this widget
  virtual char *status(Value *args) = 0;

  // agent commands: hold/release refresh of the PanelDisplay
  // <group>
  virtual char *hold(Value *args) = 0;
  virtual char *release(Value *args) = 0;
  // </group>

  // agent commands: add/remove a displaydata agent to/from this PanelDisplay
  // <group>
  virtual char *add(Value *args) = 0;
  virtual char *remove(Value *args) = 0;
  // </group>

  // <group>
  virtual char *getoptions(Value *args) = 0;
  virtual char *setoptions(Value *args) = 0;
  // </group>

  // <group>
  virtual char *unzoom(Value *args) = 0;
  virtual char *setzoom(Value *args) = 0;
  // </group>

  // <group>
  virtual char *disabletools(Value *args) = 0;
  virtual char *enabletools(Value *args) = 0;
  virtual char* settoolkey(Value* args) = 0;
  // </group>

};

}

#endif
