//# GTkColormap.h: GlishTk implementation of the Colormap class
//# Copyright (C) 1999,2000
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
//# $Id: GTkColormap.h,v 19.5 2005/06/15 18:09:12 cvsmgr Exp $

#ifndef TRIALDISPLAY_GTKCOLORMAP_H
#define TRIALDISPLAY_GTKCOLORMAP_H

#include <casa/aips.h>
#include <casa/BasicSL/String.h>
#include <display/Utilities/DisplayOptions.h>
#include "GTkDisplayProxy.h"

namespace casa {
   class Colormap;

class GTkColormap : public GTkDisplayProxy, public DisplayOptions {

 public:

  // Constructor for raster/contour of single AIPS++ image
  GTkColormap(ProxyStore *, String);

  // Destructor
  ~GTkColormap();

  // over-ride the base class IsValid function to allow for 
  // non-graphic agents which are valid even though self is 0.
  int IsValid() const;  

  // retrieve a pointer to the Colormap
  Colormap *colormap() { return itsColormap; }

  // Widget commands
  // <group>
  char *setshift(Value *);
  char *getshift(Value *);
  char *setslope(Value *);
  char *getslope(Value *);
  char *setbrightness(Value *);
  char *getbrightness(Value *);
  char *setcontrast(Value *);
  char *getcontrast(Value *);
  char *setinvertflags(Value *);
  char *getinvertflags(Value *);
  // </group>

  char *getoptions(Value *);
  char *setoptions(Value *);

 protected:

 private:

  Colormap *itsColormap;

  String itsName;

  // store whether we are valid
  int itsIsValid;

};

}

#endif
		       
