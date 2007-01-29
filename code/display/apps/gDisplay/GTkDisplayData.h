//# GTkDisplayData.h: GlishTk implementation of the DisplayData
//# Copyright (C) 1999,2000,2001,2003
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
//# $Id: GTkDisplayData.h,v 19.9 2006/08/18 21:49:38 dking Exp $

#ifndef TRIALDISPLAY_GTKDISPLAYDATA_H
#define TRIALDISPLAY_GTKDISPLAYDATA_H

#include <casa/aips.h>
#include <casa/Utilities/DataType.h>
#include <casa/Containers/Record.h>
#include <display/DisplayEvents/WCPositionEH.h>
#include <display/DisplayEvents/WCMotionEH.h>
#include <display/DisplayEvents/WCRefreshEH.h>
#include <display/Utilities/DisplayOptions.h>
#include <coordinates/Coordinates/CoordinateSystem.h>

#include "GTkDisplayProxy.h"

namespace casa {
   class DisplayData;
   template <class T> class ImageInterface;
   template <class T> class Array;
   class GTkDisplayData;

// position tracking support
class GDDPosEH : public WCPositionEH {
 public:
  GDDPosEH(GTkDisplayData *gdd) : itsGDD(gdd) { };
  virtual ~GDDPosEH() { };
  virtual void operator()(const WCPositionEvent &ev);
 private:
  GTkDisplayData *itsGDD;
};
class GDDMotEH : public WCMotionEH {
 public:
  GDDMotEH(GTkDisplayData *gdd) : itsGDD(gdd) { };
  virtual ~GDDMotEH() { };
  virtual void operator()(const WCMotionEvent &ev);
 private:
  GTkDisplayData *itsGDD;
};
class GDDDisplayEH : public DisplayEH {
 public:
  GDDDisplayEH(GTkDisplayData *gdd) : itsGDD(gdd) { };
  virtual ~GDDDisplayEH() { };
  virtual void handleEvent(DisplayEvent &ev);
 private:
  GTkDisplayData *itsGDD;
};

class GTkDisplayData : public GTkDisplayProxy,
		       public DisplayOptions {

 public:

  // Constructor for raster/contour of single AIPS++ image.
  // or table
  GTkDisplayData(ProxyStore *, String, String, String);

  // Constructor for raster/contour of a single float array.
  GTkDisplayData(ProxyStore *, String, Array<Float>);

  // Constructor for raster/contour of a single complex array.
  GTkDisplayData(ProxyStore *, String, Array<Complex>);

  // Destructor.
  ~GTkDisplayData();

  // over-ride the base class IsValid function to allow for 
  // non-graphic agents which are valid even though self is 0.
  int IsValid() const;

  // Return a pointer to the DisplayData.
  DisplayData *displayData() { return itsDisplayData; }

  // agent commands: get/set options
  // <group>
  char *getoptions(Value *);
  char *setoptions(Value *);
  // </group>

  // agent commands: set/remove colormap
  // <group>
  char *setcolormap(Value *);
  char *removecolormap(Value *);
  // </group>

  // agent command: get the class type
  // <group>
  char *classtype(Value *);
  // </group>

  // the unit of the data values
  char *dataunit(Value *);
  // the datatype of the pixels
  char *pixeltype(Value *);
  // the length of the zaxis
  char *zlength(Value *);

  // get ImageInfo eg restoringbeam
  char *getinfo(Value *);

  // update ScrollingRasterDD
  char *update(Value *);

  // <group>
  // attach/detach a displaydata to this displaydata (for profiles)
  char *attach(Value *);
  char *detach(Value *);
  // get data from a DisplayData as a record (currently only for profiles)
  char *getdata(Value *);
  // </group>

  // position tracking support
  void operator()(const WCPositionEvent &ev);
  void operator()(const WCMotionEvent &ev);

  // Display event handler
  void handleEvent(DisplayEvent &ev);

 private:
 
  // Heuristic used internally to set initial axes to display on X, Y and Z,
  // for PADDs.  shape should be that of Image/Array, and have same nelements
  // as axs.  On return, axs[0], axs[1] and (if it exists) axs[2] will be axes
  // to display initially on X, Y, and animator, respectively.
  // If you pass a CS for the image, it will give special consideration to
  // Spectral [/ Direction] axes (users expect their spectral axes on Z, e.g.)
  virtual void getInitialAxes(Block<uInt>& axs, const IPosition& shape,
			      const CoordinateSystem* cs=0);

  // the ImageInterface that we are constructed from
  ImageInterface<Float>* itsFloatImage;
  ImageInterface<Complex>* itsComplexImage;  

  Record itsImageInfo;
  
  // or the Array<Float> that we are constructed from
  Array<Float> *itsFloatArray;

  // or the Array<Complex> that we are constructed from
  Array<Complex> *itsComplexArray;

  // the DisplayData we are "managing"
  DisplayData *itsDisplayData;

  // place to record the type of DisplayData
  String itsType;
  
  DataType itsPixelType;
  // store whether we are valid
  int itsIsValid;

  // support for the constructors
  void commonCtor();
  
  // position tracking handlers
  GDDPosEH *itsPositionEH;
  GDDMotEH *itsMotionEH;
  // Data Mod event handler
  GDDDisplayEH *itsDisplayEH;
  casa::Bool itsTrackingState;
  String itsTrackingValue;	// Last strings sent out
  String itsTrackingPosition;	// by motion event handler.

};

}

#endif
		       
