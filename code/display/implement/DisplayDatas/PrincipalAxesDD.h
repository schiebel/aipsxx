//# PrincipalAxesDD.h: Base class for axis-bound DisplayData objects
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003,2004
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
//# $Id: PrincipalAxesDD.h,v 19.12 2006/09/04 04:17:08 mmarquar Exp $

#ifndef TRIALDISPLAY_PRINCIPALAXESDD_H
#define TRIALDISPLAY_PRINCIPALAXESDD_H

// aips includes:
#include <casa/aips.h>

// trial includes:
#include <coordinates/Coordinates/CoordinateSystem.h>

// display library includes:
#include <display/DisplayDatas/DisplayData.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// forwards:
class WorldCanvas;
class WorldCanvasHolder;
template <class T> class Vector;
class String;
class AttributeBuffer;
class WCPositionEvent;
class WCMotionEvent;
class WCRefreshEvent;
class CoordinateSystem;
class WCCSNLAxisLabeller;
class PrincipalAxesDM;

// <summary>
// Interface for DisplayDatas which have data arranged in axes.
// </summary>
//
// <synopsis>
// This class adds to the interface defined by DisplayData to 
// provide the necessary infrastructure for managing data which 
// is arranged in "axes," ie. lattice or column-based data.
// </synopsis>

class PrincipalAxesDD : public DisplayData {

 public:

  // constructor
  PrincipalAxesDD(uInt xAxis, uInt yAxis, Int mAxis = -1,
     Bool axisLabels = True);

  // destructor
  virtual ~PrincipalAxesDD();

  // Coordinate transformation handlers, called by WorldCanvasHolder
  // <group>
  virtual Bool linToWorld(Vector<Double> &world, 
			  const Vector<Double> &lin);
  virtual Bool worldToLin(Vector<Double> &lin,
			  const Vector<Double> &world);
  virtual Bool linToFullWorld(Vector<Double> &fullWorld,
			      const Vector<Double> &lin);
  // </group>

  // Format a string containing coordinate and data information at the
  // given world coordinate
  virtual String showPosition(const Vector<Double> &world, 
			      const Bool &displayAxesOnly = False);

  // Format a string containing coordinate and data information at the
  // given world coordinate. This function let's you specify output
  // conditions (world/pixel and abs/rel)
  virtual String showPosition(const Vector<Double> &world, 
			      const Bool &showWorld, const Bool &showAbs,
			      const Bool &displayAxesOnly = False);

  
  // Set internal index (activeZIndex_) into the list of DMs (which cache
  // individual drawings), according to passed animator index.  This is
  // called by conformsTo() (via conformsToZIndex()), and serves to
  // 'focus' the DD on the current WCH's zIndex.
  // Returns True if there is only one frame, in which case activeZIndex_
  // is set to 0.  Thus a single frame is considered to apply to any
  // canvas zIndex setting (this allows a continuum image to be blinked
  // with a chosen channel of a spectral image, e.g.).
  // If there is more than one frame, the passed zindex is stored, and
  // the return value will indicate whether it lies within the DD's
  // current number of frames.
  virtual Bool setActiveZIndex(Int zindex);

  // Is the DD is capable (in its current state) of drawing
  // in the current CoordinateSystem of the WCH's WorldCanvas?
  virtual Bool conformsToCS(const WorldCanvasHolder& wch);

  // Miscellaneous information supply routines
  // <group>
  virtual Vector<String> worldAxisNames();
  virtual Vector<String> worldAxisUnits();
  virtual Vector<Double> worldAxisIncrements();
  virtual void worldAxisType(Coordinate::Type &type, Int &coordinate,
			     Int &axisincoord, const uInt &worldaxisnum);
  virtual String worldAxisCode(const uInt &worldaxisnum);
  // </group>

  // Return the number of display elements (eg. drawable images) in this
  // DisplayData
  // <group>
  virtual const uInt nelements(const WorldCanvasHolder &wcHolder) const;
  virtual const uInt nelements() const;
  // </group>

  // Set and retrieve the minimum and maximum data values
  // <group>
  virtual void setDataMin(Double datmin);
  virtual void setDataMax(Double datmax);
  virtual Double getDataMin();
  virtual Double getDataMax();
  // </group>

  // sizeControlFunction, called by the WorldCanvasHolder to setup the
  // WorldCanvas linear coordinate system
  virtual Bool sizeControl(WorldCanvasHolder& wcHolder, 
			   AttributeBuffer& holderBuf);

  // Position event handler, called by the WorldCanvasHolder
  virtual void positionEH(const WCPositionEvent& ev);

  // Motion event handler, called by the WorldCanvasHolder
  virtual void motionEH(const WCMotionEvent& ev);
  

  // refresh handler, called by the WorldCanvasHolder
  virtual void refreshEH(const WCRefreshEvent& ev); 

  // label/draw the axes
  virtual Bool labelAxes(const WCRefreshEvent &ev);

  // required function to tidy up our elements, primarily
  virtual void cleanup();

  // install the default options for this DisplayData
  virtual void setDefaultOptions();

  // apply options stored in val to the DisplayData; return value
  // True means a refresh is needed...
  virtual Bool setOptions(Record &rec, Record &recOut);

  // retrieve the current and default options and parameter types.
  virtual Record getOptions();

  // distribute options to all the axis labellers
  virtual Bool setLabellerOptions(Record &rec, Record &recout);

  // retrieve options from the axis labellers
  virtual Record getLabellerOptions();

  // Sets which axes are on display and animator, and positions for
  // animator and sliders.  Pass 'reset' as False if you don't need
  // an unzoom (e.g. when display axes are unchanged).
  virtual void setAxes(const uInt xAxis, const uInt yAxis, const uInt mAxis,
  		       const IPosition fixedPos, Bool reset=True);

  // query the number of dimensions in the data
  virtual uInt nDim() 
    { return dataDim(); }

  // retrieve the CoordinateSystem
  CoordinateSystem coordinateSystem() const
    { return itsCoordSys; }

  // retrieve the original CoordinateSystem
  CoordinateSystem originalCoordinateSystem() const
    { return itsOrigCoordSys; }

  // set the CoordinateSystem and the original CoordinateSystem
  void setCoordinateSystem(const CoordinateSystem &coordsys);

  // set the CoordinateSystem to be the same as the original
  // CoordinateSystem
  void restoreCoordinateSystem();

  // set a Linear Coordinate in case of pixToWorld undefined for the
  // blc/trc
  void installFakeCoordinateSystem();
  void removeFakeCoordinateSystem();

  // Return the class name of this DisplayData; useful mostly for
  // debugging purposes, and perhaps future use in the glish widget
  // interface.
  virtual String className() { return String("PrincipalAxesDD"); }

  // Get the current fixed position
  virtual IPosition fixedPosition() const 
    { return itsFixedPosition; }

  // Get the current display axis numbers
  virtual Vector<Int> displayAxes() const 
    { return itsDisplayAxes; }

  // Get the current setting of pixel treatment mode
  virtual String pixelTreatment() const
    { return itsOptionsPixelTreatment; }

  
  //# (dk note 12/04: Axis Label state is maintained by eight different
  //# PADD methods; someone has begun using the bool below to bypass that
  //# maintenance.  Well, ok; it can work that way as a construction
  //# parameter that is unchanged thereafter.  But simply turning it back
  //# on later will not make that state available or consistent; it will
  //# just cause crashes.  Please see me for what's needed to properly
  //# support this method if you need to restore it).
  //#  
  //# void usesAxisLabels(Bool state) {
  //#   itsUsesAxisLabels = state;
  //# }

    
  // Convert a 2D worldCoordinate of the WorldCanvas to a full worldcoordinate
  // and full pixel position
  virtual Bool getFullCoord(Vector<Double> &fullWorld, 
			    Vector<Double> &fullPixel, 
			    const Vector<Double> &world);

  virtual void notifyUnregister(WorldCanvasHolder& wcHolder, 
                                Bool ignoreRefresh = False);

 protected:

  // allow PrincipalAxesDM objects to access the coord system in 
  // parent PrincipalAxesDD object
  friend class PrincipalAxesDM;

  virtual void setNumImages(const uInt nimages)
    { itsNumImages = nimages; }

  // Internal state
  Bool iAmRubbish;

  // min and max to use for drawing
  Double datamin;
  Double datamax;

  // internal bookkeeping
  // number of axes
  uInt nArrayAxes;
  uInt nPixelAxes;
  uInt nWorldAxes;

  // do some setup work, part of construction and changing dataset
  void setup(IPosition fixedPos);

  // functions need by above
  virtual const IPosition dataShape() = 0;
  virtual const uInt dataDim() = 0;
  virtual const Unit dataUnit() = 0;
  virtual void setupElements();
  virtual void getMinAndMax() = 0;

  // Helper routine for setting up the transpose vectors for the coordinate
  // system. 
  Bool indexInserted(Int index, Int length, Vector<Int>& testVec);

  // helper to transpose coordinates  
  // <group>
  void normalToTransposed(Vector<Double>& coord, const Vector<Int>& transPos);
  void transposedToNormal(Vector<Double>& coord, const Vector<Int>& transPos);
  // </group>

  // Set velocity state
  void setVelocityState (CoordinateSystem& cSys, 
                         const String& velTypeString, 
                         const String& unitString);

  // Set Spectral formatting
  void setSpectralFormatting (CoordinateSystem& cSys, 
                              const String& velTypeString, 
                              const String& unitString);

  // Determine the active image (if any).
  // (Deprecated (7/04).  Use  confromsToZIndex(wch)  instead).
  Bool findActiveImage(WorldCanvasHolder &wcHolder);

  // (Required) default constructor.
  PrincipalAxesDD();

  // (Required) copy constructor.
  PrincipalAxesDD(const PrincipalAxesDD &other);

  // (Required) copy assignment.
  void operator=(const PrincipalAxesDD &other);

 private:

  // axis numbers IN ORIGINAL COORDINATE SYSTEM; zAxisNum = -1 means 
  // no third axis in data set
  Int itsXAxisNum;
  Int itsYAxisNum;
  Int itsZAxisNum;

  // the x (0), y (1) and z/movie (2) axis numbers
  Vector<Int> itsDisplayAxes;

  // Store options:
  // Axis selection ---
  String itsOptionsXAxis, itsOptionsYAxis, itsOptionsZAxis;
  IPosition itsFixedPosition;

  // treatment of edge pixels
  String itsOptionsPixelTreatment;

  // number of elements (images) in this DisplayData
  uInt itsNumImages;

  // This CS is the one we were constructed with
  CoordinateSystem itsOrigCoordSys;
  CoordinateSystem itsCoordSysBackup;

  // This is the working CS which is transposed and has axes removed
  // all over the place
  
  // (dk note: The authors explain this poorly, and don't seem to make
  // the distinction even for themselves very well: there are _two_
  // relevant coordinate transformations here, not just one.  itsOrigCoordSys
  // defines the world space for the _data_ pixels.  itsCoordSys defines the
  // world space for the _canvas_.  Control and setting of the canvas CS is
  // poorly modularized, and the DDs remain involved in too much of the
  // _canvas's_ coordinate translation chores).

  CoordinateSystem itsCoordSys;

  // List of AxisLabellers.
  PtrBlock<void *> itsAxisLabellers;
  
  // Aspect selection ---
  String itsOptionsAspect;

  // Position tracking variables
  // This CS is the one we use to set the appropriate state for
  // PositionTracking.    It is pretty much the same as itsOriginalCoordSys
  // but the formtting and velocity state (if there is a SC) may differ

  CoordinateSystem itsPosTrackCoordSys;
  String itsSpectralUnit;
  String itsDoppler;
  Bool itsAbsolute;
  Bool itsShowWorldCoordinate;
  Bool itsFractionalPixels;
  // whether the spectral notation is fixed (or otherwise scientific)
  Bool itsSpectralNotationFixed;

  // buffer for string sizecontrol done by this ImageDisplayData
  AttributeBuffer sizeControlBuf;
  
  // the coordinates of the axes that do not vary
  Vector<Double>    itsAddPixPos;

  // how the axes are permuted
  Vector<Int>       itsTransPixelAxes;
  Vector<Int>       itsTransWorldAxes;

  // world ranges for toMix conversions
  Vector<Double> itsWorldMin, itsWorldMax;

  // Temporaries  for coordinate conversions.
  // You should only use one temporary per function.
  Vector<Double> itsWorldInTmp1, itsPixelInTmp1;
  Vector<Bool> itsWorldAxesTmp1, itsPixelAxesTmp1;
  Vector<Double> itsFullWorldTmp1;
  //
  Vector<Double> itsPixelInTmp2;
  //
  Vector<Double> itsWorldInTmp3, itsWorldOutTmp3;
  Vector<Double> itsPixelInTmp3, itsPixelOutTmp3;
  Vector<Bool> itsWorldAxesTmp3, itsPixelAxesTmp3;
  //
  Vector<Double> itsFullWorldTmp4, itsFullPixelTmp4;

  Bool itsUsesAxisLabels;

  // Find out if SpectralCoordinate can have velocity units
  Bool canHaveVelocityUnit (const CoordinateSystem& cSys) const;

  // Remove list of pixel axes from CS
  void removePixelAxes (CoordinateSystem& cSys,
                        uInt startAxis,
                        const IPosition& fixedPosition);

  // Convert list of world axis names to pixel axis names
   Vector<String> worldToPixelAxisNames (const CoordinateSystem& cSys) const;

};
 

} //# NAMESPACE CASA - END

#endif
