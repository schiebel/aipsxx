//# WCRefreshEH.h: WorldCanvas refresh event handler
//# Copyright (C) 1993,1994,1995,1996,1998,1999,2000,2002
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
//# $Id: WCRefreshEH.h,v 19.5 2005/06/15 18:02:25 cvsmgr Exp $

#ifndef TRIALDISPLAY_WCREFRESHEH_H
#define TRIALDISPLAY_WCREFRESHEH_H

#include <casa/aips.h>
#include <display/DisplayEvents/WCRefreshEvent.h>
#include <display/DisplayEvents/DisplayEH.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//
// <summary>
// Base class for handling WorldCanvas refresh events.
// </summary>
//
// <prerequisite>
// <li> <linkto class="WCRefreshEvent">WCRefreshEvent</linkto>
// <li> Understanding of Display library event-handling methodology
// <li> (Optional) Understanding of the
// <linkto class="PixelCanvas">PixelCanvas</linkto> caching mechanism.
// </prerequisite>
//
// <etymology>
// WCRefreshEH : WorldCanvas refresh event-handler
// </etymology>
//
// <synopsis>
// class designed for derivation to provide a standard way of redrawing the
// screen.  To use, derive from this class and implement the () operator.  For simple
// applications, the op () should redraw the screen, or rebuild and redraw all display
// lists if display lists were used.  

// More advanced applications should maintain display lists and perhaps cache information 
// at other levels.  These kinds of applications should examine the reason field to see 
// what changed so they can minimize the computation needed to redraw the screen.
// The meanings of the reason field are as follows:
//
// <li>
// <ul> Display::UserCommand - This is generated only when the user calls 
//      refresh() on the canvas.
// <ul> Display::ColorTableChange - This is generated by a change in the
//      colortable distribution.  
//      Normally all display lists with color information must be rebuilt and redrawn.
// <ul> Display::PixelCoordinateChange - The world canvas has been 
//      resized or repositioned with 
//      respect to the pixel canvas, or the pixelCanvas has changed size.
// <ul> Display::LinearCoordinateChange - linear coordinates changed, typically
//      happens when the image is zoomed.
// <ul> Display::WorldCoordinateChange - world coordinates have changed, generally
//      must redraw everything
// </li>
//
// This class has been modified to inherit interface for handling
// generic display events as well. (1/02)
// See <linkto class="DisplayEH">DisplayEH</linkto> for details.
// </synopsis>
//
// <motivation>
// Provide the user with an object-oriented approach to event handling.
// Allow the user to manage screen refresh in a simplistic way, yet
// providing information for sophisticated approaches like multi-layer caching.
// </motivation>
//
// <example>
// see the test programs in Display/test.
// </example>
//

class WCRefreshEH : public DisplayEH {

 public:

  // Default Constructor Required
  WCRefreshEH();

  // original handler interface (still used for WCRefreshEvents)
  virtual void operator ()(const WCRefreshEvent & ev);

  // Destructor
  virtual ~WCRefreshEH();

};


} //# NAMESPACE CASA - END

#endif



