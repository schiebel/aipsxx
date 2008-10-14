//# GTkAnnotations.h : GlishTk implementation of Annotations
//# Copyright (C) 1998,1999,2000,2001,2002
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
//# $Id: 

#ifndef TRIALDISPLAY_GTKANNOTATIONS_H
#define TRIALDISPLAY_GTKANNOTATIONS_H

#include <casa/aips.h>
#include <display/DisplayShapes/Annotations.h>
#include "GTkDisplayProxy.h"

namespace casa {
   class GTkPSPixelCanvas;
   class GTkPixelCanvas;
   class GTkPanelDisplay;

// <summary>
// These functions all Annotations functions to be called from glish.
// They generally check for correct parameters, do any conversion needed,
// and then call the underlying function.
// </summary>

class GTkAnnotations : public GTkDisplayProxy,  
		       public Annotations {


public:
  // Constructor. Takes a GTkPanelDisplay which is passed on to the
  // Annotations class.
  GTkAnnotations(ProxyStore* pstore, GTkPanelDisplay* pdisp,
		 const Display::KeySym &mouseButton = 
  		 Display::K_Pointer_Button1, const casa::Bool& useEH = True);
  
  // Destructor
  virtual ~GTkAnnotations();

  int IsValid() const;

  Annotations* annotations() { return ((Annotations*) this); }
  
  // Create a shape based on the record supplied.
  char* newshape(Value *args);

  // Create a shape on the record supplied, and also on user input via mouse
  char* createshape(Value *args);

  // Delete the shape with the specified index
  char* deleteshape(Value *args);

  // Return id of active shape:
  char* whichshape(Value *args);
  
  // Return all existing shapes:
  // id    Type     Centre
  // 0     Square   0.25,0.25
  // 1     Circle   0.5,0.5 
  // etc
  char* listshapes(Value *args);
  
  // Return a list of all available shapes ("Type");
  // "Rectangle"
  // "Ellipse"
  // etc
  char* availableshapes(Value *args);
  
  // Enable motion / position event handlers, these have a w_ prefix
  // to avoid hiding the base class implementation
  char* w_enable(Value *args);

  // Disable motion / position event handlers
  char* w_disable(Value *args);
  
  // Return / Set an option set describing all the current annotations
  // <group>
  char* getalloptions(Value *args);
  char* setalloptions(Value *args);
  // </group>

  // Change the co-ord system of specified shape
  // <group>
  char* reverttopix(Value *args);
  char* reverttofrac(Value *args);
  char* locktowc(Value *args);
  // </group>

  // Get / Set options for an individual shape. The shape index, and also
  // option record must be specified
  // <group>
  char* getshapeoptions(Value *args);
  char* setshapeoptions(Value *args);
  // </group>
  
  // Lock / remove a lock to / from the current shape
  // <group>
  char* addlockedtocurrent(Value *args);
  char* removelockedfromcurrent(Value *args);
  // </group>
  
  // Set the key used to control the shapes;
  char* setkey(Value *args);
  
  // Turn off all handles / cancel any creation currently underway etc
  char* cancel(Value *args);
  
  // Post a glish event. annotEvent() will post an event with 
  // name = "annotevent"
  // <group>
  virtual void annotEvent(const String& event);
  virtual void postEvent(const String& name, const GlishRecord& rec);
  // </group>

private:

  int itsIsValid;

};

}

#endif







