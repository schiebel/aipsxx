//# GTkPSPixelCanvas.h: GlishTk wrapper for a PSPixelCanvas object
//# Copyright (C) 1999,2000,2002
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
//# $Id: GTkPSPixelCanvas.h,v 19.4 2005/06/15 18:09:13 cvsmgr Exp $

#ifndef TRIALDISPLAY_GTKPSPIXELCANVAS_H
#define TRIALDISPLAY_GTKPSPIXELCANVAS_H

//# aips includes:
#include <casa/aips.h>

//# local includes:
#include "GTkDisplayProxy.h"

namespace casa {
//# forwards:
   class PixelCanvas;
   class PSDriver;
   class PSPixelCanvasColorTable;
   class PSPixelCanvas;

class GTkPSPixelCanvas : public GTkDisplayProxy {
  
 public:

  // constructor; this simply needs to know where the ProxyStore is
  GTkPSPixelCanvas(ProxyStore *s, const String &filename,
		   const String &media, const casa::Bool &landscape,
		   const Float &aspect, const Int &dpi, 
		   const Float &zoom, const casa::Bool &eps,
		   const Value *colors, const String &maptype);

  // destructor; this will delete the PSPixelCanvas and thereby close
  // the PostScript file
  ~GTkPSPixelCanvas();

  // over-ride the base class IsValid function to allow for 
  // non-graphic agents which are valid even though self is 0.
  int IsValid() const;

  // get the PSPixelCanvas
  PixelCanvas *pixelCanvas() const;

  // widget event: report the status of the pixelcanvas
  char *status(Value *args);

 protected:

 private:

  PSDriver *itsPSDriver;
  PSPixelCanvasColorTable *itsPSPCColorTable;
  PSPixelCanvas *itsPSPixelCanvas;

  // store whether we are valid
  int itsIsValid;

};

}
#endif
