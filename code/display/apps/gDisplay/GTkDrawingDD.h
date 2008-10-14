//# GTkDrawingDD.h: GlishTk interface to the DrawingDisplayData class
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
//# $Id: GTkDrawingDD.h,v 19.5 2005/06/15 18:09:12 cvsmgr Exp $

#ifndef TRIALDISPLAY_GTKDRAWINGDD_H
#define TRIALDISPLAY_GTKDRAWINGDD_H

#include <casa/aips.h>
#include <display/DisplayDatas/DrawingDisplayData.h>
#include "GTkDisplayProxy.h"

namespace casa {

class GTkDrawingDD : public GTkDisplayProxy, public DrawingDisplayData {
  
 public:

  // constructor; this simply needs to know where the ProxyStore is
  GTkDrawingDD(ProxyStore *s);

  // destructor; this will unregister the animator from anywhere it
  // should
  ~GTkDrawingDD();

  // over-ride the base class IsValid function to allow for 
  // non-graphic agents which are valid even though self is 0.
  int IsValid() const;

  // agent commands: add/remove objects to be drawn
  // <group>
  char *add(Value *);
  char *remove(Value *);
  // </group>

  // agent commands: set/get description of specific object
  // (w_ prefix needed where a function of that name already exists)
  // <group>
  char *w_description(Value *);
  char *setdescription(Value *);
  // </group>

  // return the DrawingDisplayData this wraps.
  DisplayData *displayData() 
    { return (DisplayData *)this; }

  // over-ride this function in base DrawingDD; emit an event when
  // the double click happens.
  virtual void doubleClick(const Int objectID);

 private:

  // store whether we are valid
  int itsIsValid;

};

}

#endif
