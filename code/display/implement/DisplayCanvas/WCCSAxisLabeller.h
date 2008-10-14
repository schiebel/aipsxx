//# WCCSAxisLabeller.h: labelling axes using a CoordinateSystem on a WC
//# Copyright (C) 1999,2000,2001,2002
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
//# $Id: WCCSAxisLabeller.h,v 19.7 2006/01/18 23:51:34 dking Exp $

#ifndef TRIALDISPLAY_WCCSAXISLABELLER_H
#define TRIALDISPLAY_WCCSAXISLABELLER_H

//# aips includes:
#include <casa/aips.h>

//# trial includes:
#include <coordinates/Coordinates/CoordinateSystem.h>

//# display library includes:
#include <display/DisplayCanvas/WCAxisLabeller.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// Base class for WorldCanvas axis labelling using a CoordinateSystem.
// </summary>
//
// <synopsis>
// This (base) class adds to the interface of WCAxisLabeller functions
// which support the use/provision of a CoordinateSystem to assist with
// axis labelling.
// </synopsis>

class WCCSAxisLabeller : public WCAxisLabeller {

 public:

  // Constructor
  WCCSAxisLabeller();

  // Destructor
  virtual ~WCCSAxisLabeller();

  // Install the CoordinateSystem to use
  virtual void setCoordinateSystem(const CoordinateSystem& coordsys);

  // Get the CoordinateSystem
  virtual CoordinateSystem coordinateSystem() const;

  // Do we have a CoordinateSystem yet ?
  Bool hasCoordinateSystem () const { return itsHasCoordinateSystem; };

  // install the default options for this DisplayData
  virtual void setDefaultOptions();

  // apply options stored in rec to the DisplayData; return value
  // True means a refresh is needed.  Any fields added to the
  // updatedOptions argument are options which have changed in
  // some way due to the setting of other options - ie. they 
  // are context sensitive.
  virtual Bool setOptions(const Record &rec, Record &updatedOptions);

  // retrieve the current and default options and parameter types.
  virtual Record getOptions() const;

  // return the X and Y label text - over-ridden from base class
  // <group>
  virtual String xAxisText() const;
  virtual String yAxisText() const;
  // </group>
  virtual String zLabelType() const { return itsZLabelType; };

  virtual void setZIndex(Int zindex) { itsZIndex = zindex; };

  // DD 'Absolute Pixel Coordinates', e.g. channel numbers, are internally
  // 0-based (they begin numbering at 0), but 'Absolute Pixel coordinates'
  // have traditionally been displayed as 1-based in the glish viewer.
  // uiBase_, and related methods uiBase() and setUIBase(), allow newer
  // (python/Qt-based) code to cause such labelling to be produced with
  // 0-based values instead.  Unless setUIBase(0) is called, the
  // traditional 1-based labelling behavior is retained by default.
  //
  // If you are using 0-basing for 'Absolute Pixel Coordinate' labelling,
  // you should call setUIBase(0), before using draw().
  // <group>
  virtual Int uiBase() { return uiBase_;  }
  
  virtual void setUIBase(Int uibase) {
    if(uibase==0 || uibase==1) uiBase_ = uibase;  }
  // </group>
 
 
 protected:
  Bool itsAbsolute;
  Bool itsWorldAxisLabels;
  Bool itsDoVelocity;
  Int itsZIndex;

 private:

  CoordinateSystem itsCoordinateSystem;
  Bool itsHasCoordinateSystem;
  String itsSpectralUnit;
  String itsDoppler;
  String itsDirectionUnit;
  String itsDirectionSystem;
  String itsFrequencySystem;
  String itsZLabelType;

  Int uiBase_;		// (initialized to 1; see uiBase(), above).
  
  // Generate axis text for specified axis
  String axisText(Int worldAxis) const;

  // Set new spectral state in CoordinateSystem
  void setSpectralState ();

  // Set new direction state in CoordinateSystem
  void setDirectionState ();

  // Set absolute/relative state
  void setAbsRelState();

};


} //# NAMESPACE CASA - END

#endif
