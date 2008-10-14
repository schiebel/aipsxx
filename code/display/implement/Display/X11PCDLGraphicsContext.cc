//# X11PCDLGraphicsContext.cc: X11 PixelCanvas store/cache of Context commands
//# Copyright (C) 1993,1994,1995,1996,1999,2000
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
//# $Id: X11PCDLGraphicsContext.cc,v 19.4 2005/06/15 17:56:41 cvsmgr Exp $

#include <casa/aips.h>
#include <display/Display/X11PCDLGraphicsContext.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
X11PCDLGraphicsContext::X11PCDLGraphicsContext(const XGCValues & values, 
					       uLong mask) {
  // Some functions not supported by PixelCanvas
  uLong supportedMask = (GCFunction | GCForeground | GCBackground | 
			 GCLineWidth |
			 GCLineStyle | GCCapStyle | GCJoinStyle | GCFillStyle |
			 GCFillRule | GCFont | GCArcMode);
  mask_ = mask & supportedMask;
  if (mask_ & GCFunction) values_.function = values.function;
  // if (mask & GCPlaneMask) values_.plane_mask = values.plane_mask;
  if (mask_ & GCForeground) values_.foreground = values.foreground;
  if (mask_ & GCBackground) values_.background = values.background;
  if (mask_ & GCLineWidth) values_.line_width = values.line_width;
  if (mask_ & GCLineStyle) values_.line_style = values.line_style;
  if (mask_ & GCCapStyle) values_.cap_style = values.cap_style;
  if (mask_ & GCJoinStyle) values_.join_style = values.join_style;
  if (mask_ & GCFillStyle) values_.fill_style = values.fill_style;
  if (mask_ & GCFillRule) values_.fill_rule = values.fill_rule;
  // if (mask & GCTile) values_.tile = values.tile;
  // if (mask & GCStipple) values_.stipple = values.stipple;
  // if (mask & GCTileStipXOrigin) values_.ts_x_origin = values.ts_x_origin;
  // if (mask & GCTileStipYOrigin) values_.ts_y_origin = values.ts_y_origin;
  if (mask_ & GCFont) values_.font = values.font;
  // if (mask & GCSubwindowMode) values_.subwindow_mode = values.subwindow_mode;
  // if (mask & GCGraphicsExposures) values_.graphics_exposures = values.graphics_exposures;
  // if (mask & GCClipXOrigin) values_.clip_x_origin = values.clip_x_origin;
  // if (mask & GCClipYOrigin) values_.clip_y_origin = values.clip_y_origin;
  // if (mask & GCClipMask) values_.clip_mask = values.clip_mask;
  // if (mask & GCDashOffset) values_.dash_offset = values.dash_offset;
  // if (mask & GCDashList) values_.dashes = values.dashes;
  if (mask_ & GCArcMode) values_.arc_mode = values.arc_mode;
}

void X11PCDLGraphicsContext::translate(Int, Int) {
}

void X11PCDLGraphicsContext::draw(::XDisplay * display, Drawable, GC gc, 
				  Int, Int) {
  XChangeGC(display, gc, mask_, &values_);
}

// Destructor
X11PCDLGraphicsContext::~X11PCDLGraphicsContext() {
}


} //# NAMESPACE CASA - END

