//# WCCSAxisLabeller.cc: labelling axes using a CoordinateSystem on a WC
//# Copyright (C) 1999,2000,2001,2002,2004
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
//# $Id: WCCSAxisLabeller.cc,v 19.7 2006/01/18 23:51:34 dking Exp $

//# aips includes:
#include <casa/aips.h>
#include <casa/Exceptions.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MFrequency.h>
#include <measures/Measures/MeasTable.h>
#include <casa/Logging/LogOrigin.h>
#include <casa/Logging/LogIO.h>
#include <casa/iostream.h>
#include <casa/System/Aipsrc.h>
#include <casa/Utilities/Regex.h>

//# trial includes:
#include <coordinates/Coordinates/CoordinateUtil.h>
#include <coordinates/Coordinates/DirectionCoordinate.h>
#include <coordinates/Coordinates/SpectralCoordinate.h>

 
//# display library includes:

//# this include:
#include <display/DisplayCanvas/WCCSAxisLabeller.h>

namespace casa { //# NAMESPACE CASA - BEGIN

WCCSAxisLabeller::WCCSAxisLabeller() : 
  itsAbsolute(True),
  itsWorldAxisLabels(True),
  itsDoVelocity(True),
  itsZIndex(-1),
  itsHasCoordinateSystem(False),
  itsSpectralUnit("km/s"),
  itsDoppler("radio"),
  itsDirectionUnit("arcsec"),
  itsDirectionSystem("J2000"),
  itsFrequencySystem("LSRK"),
  itsZLabelType("none"),
  uiBase_(1) {
  String worldorpix;
  Aipsrc::find(worldorpix,"display.axislabels.world","on");
  itsWorldAxisLabels = 
    !worldorpix.matches(Regex("[ \t]*(([nN]o)|([oO]ff)|([fF](alse)*))[ \t\n]*"));
    
}

WCCSAxisLabeller::~WCCSAxisLabeller() {
}

void WCCSAxisLabeller::setCoordinateSystem(const CoordinateSystem& cSys) {
  itsCoordinateSystem = cSys;
  itsHasCoordinateSystem = True;
}

CoordinateSystem WCCSAxisLabeller::coordinateSystem() const {
  if (!itsHasCoordinateSystem) {
    throw(AipsError("no coordinate system has been set in WCCSAxisLabeller"));
  } 
  return itsCoordinateSystem;
}

void WCCSAxisLabeller::setDefaultOptions() {
  WCAxisLabeller::setDefaultOptions();
//
  itsAbsolute = True;
  //itsWorldAxisLabels = True;
//
  Int after = -1;
  Int iS = itsCoordinateSystem.findCoordinate(Coordinate::SPECTRAL, after);
  if (iS>=0) {
     const SpectralCoordinate coord = itsCoordinateSystem.spectralCoordinate(iS);
     Double restFreq = coord.restFrequency(); 
     Vector<String> vunits;
     if (restFreq > 0) {
        itsSpectralUnit = String("km/s");
     } else {
        itsSpectralUnit = String("GHz");
     }
//
     MFrequency::Types ctype;
     MEpoch epoch;
     MPosition position;
     MDirection direction;
     coord.getReferenceConversion(ctype, epoch, position, direction);
     itsFrequencySystem = MFrequency::showType(ctype);
     itsDoppler = String("radio");
     setSpectralState();
  }
//
  after = -1;
  iS = itsCoordinateSystem.findCoordinate(Coordinate::DIRECTION, after);
  if (iS>=0) {
     const DirectionCoordinate coord = itsCoordinateSystem.directionCoordinate(iS);
     MDirection::Types ctype;
     coord.getReferenceConversion(ctype);
     itsDirectionSystem = MDirection::showType(ctype);
     itsDirectionUnit = String("arcsec");
     setDirectionState();
  }
//
  setAbsRelState();
  itsZLabelType = String("none");
}



Bool WCCSAxisLabeller::setOptions(const Record &rec, Record &updatedOptions) 
{
  Bool ret = WCAxisLabeller::setOptions(rec, updatedOptions);
  Bool localchange = False;

  Bool error;
  if (readOptionRecord(itsDoppler, error, rec,  "axislabelvelocitytype") ||
      readOptionRecord(itsSpectralUnit, error, rec, "axislabelspectralunit") ||
      readOptionRecord(itsFrequencySystem, error, rec, "axislabelfrequencysystem")) {
     setSpectralState();
     localchange = True;
  } 
  if (readOptionRecord(itsDirectionUnit, error, rec, "axislabeldirectionunit") ||
      readOptionRecord(itsDirectionSystem, error, rec, "axislabeldirectionsystem")) {
     setDirectionState();
     localchange = True;
  }
//
  String value;
  if (readOptionRecord(value, error, rec,  "axislabelabsrel")) {
     Bool abs = (value=="absolute");
     if (abs != itsAbsolute) {
        itsAbsolute = abs;
        setAbsRelState();
        localchange = True;
     }
  }
//
  if (readOptionRecord(value, error, rec,  "axislabelpixelworld")) {
     Bool world = (value=="world");
     if (world != itsWorldAxisLabels) {
        itsWorldAxisLabels = world;
        localchange = True;
     }
  }
//
  if (readOptionRecord(itsZLabelType, error, rec, "axislabelzlabeltype")) {
     localchange = True;
  } 
//  
  if (localchange) {
    // invalidate existing draw lists, etc.
    invalidate();
  }
//
  ret = (ret || localchange);
  return ret;
}

Record WCCSAxisLabeller::getOptions() const 
{
  Record rec = WCAxisLabeller::getOptions();
//

  Record pixworld;
  pixworld.define("context", "Axis_label_properties");
  pixworld.define("dlformat", "axislabelpixelworld");
  pixworld.define("listname", "World or pixel coordinates");
  pixworld.define("ptype", "choice");
  Vector<String> v(2);
  v(0) = "world";
  v(1) = "pixel";
  pixworld.define("popt", v);
  pixworld.define("default", "world");
  if (itsWorldAxisLabels) {
     pixworld.define("value", "world");
  } else {
     pixworld.define("value", "pixel");
  }
  pixworld.define("allowunset", False);
  rec.defineRecord("axislabelpixelworld", pixworld);
//
  Record absrel;
  absrel.define("context", "Axis_label_properties");
  absrel.define("dlformat", "axislabelabsrel");
  absrel.define("listname", "Absolute or relative");
  absrel.define("ptype", "choice");
  v.resize(2);
  v(0) = "absolute";
  v(1) = "relative";
  absrel.define("popt", v);
  absrel.define("default", "absolute");
  if (itsAbsolute) {
     absrel.define("value", "absolute");
  } else {
     absrel.define("value", "relative");
  }  
  absrel.define("allowunset", False);
  rec.defineRecord("axislabelabsrel", absrel);
//
  Int after = -1;
  Int iD = itsCoordinateSystem.findCoordinate(Coordinate::DIRECTION, after);
  if (iD>=0) {
     {
        Record directionSystem;
        directionSystem.define("context", "Axis_label_properties");
        directionSystem.define("dlformat", "axislabeldirectionsystem");
        directionSystem.define("listname", "Direction Reference");
        directionSystem.define("ptype", "choice");
        Vector<String> vunits(5);
        vunits(0) = "J2000";
        vunits(1) = "B1950";
        vunits(2) = "GALACTIC";
        vunits(3) = "ECLIPTIC";
        vunits(4) = "SUPERGAL";
        directionSystem.define("popt", vunits);
        directionSystem.define("default", "J2000");
        directionSystem.define("value", itsDirectionSystem);
        directionSystem.define("allowunset", False);
        rec.defineRecord("axislabeldirectionsystem", directionSystem);
     }
//
     {
        Record directionunit;
        directionunit.define("context", "Axis_label_properties");
        directionunit.define("dlformat", "axislabeldirectionunit");
        directionunit.define("listname", "Direction unit");
        directionunit.define("ptype", "userchoice");
        Vector<String> vunits(4);
        vunits(0) = "deg";
        vunits(1) = "arcmin";
        vunits(2) = "arcsec";
        vunits(3) = "rad";
        directionunit.define("popt", vunits);
        directionunit.define("default", "arcsec");
        directionunit.define("value", itsDirectionUnit);
        directionunit.define("allowunset", False);
        rec.defineRecord("axislabeldirectionunit", directionunit);
     }
  }
//
  after = -1;
  Int iS = itsCoordinateSystem.findCoordinate(Coordinate::SPECTRAL, after);
  if (iS>=0) {
     {
        Record frequencySystem;
        frequencySystem.define("context", "Axis_label_properties");
        frequencySystem.define("dlformat", "axislabelfrequencysystem");
        frequencySystem.define("listname", "Spectral Reference");
        frequencySystem.define("ptype", "choice");
        Vector<String> vunits(5);
        vunits(0) = "LSRK";
        vunits(1) = "LSRD";
        vunits(2) = "BARY";
        vunits(3) = "GEO";
        vunits(4) = "TOPO";
        frequencySystem.define("popt", vunits);
        frequencySystem.define("default", "J2000");
        frequencySystem.define("value", itsFrequencySystem);
        frequencySystem.define("allowunset", False);
        rec.defineRecord("axislabelfrequencysystem", frequencySystem);
     }
     {    
        Record spectralunit;
        spectralunit.define("context", "Axis_label_properties");
        spectralunit.define("dlformat", "axislabelspectralunit");
        spectralunit.define("listname", "Spectral unit");
        spectralunit.define("ptype", "userchoice");
//
        const SpectralCoordinate sc = itsCoordinateSystem.spectralCoordinate(iS);
        Double restFreq = sc.restFrequency(); 
        Vector<String> vunits;
        if (restFreq > 0) {
           vunits.resize(5);        
           vunits(0) = "km/s";
           vunits(1) = "m/s";
           vunits(2) = "GHz";
           vunits(3) = "MHz";
           vunits(4) = "Hz";
        } else {
           vunits.resize(3);        
           vunits(0) = "GHz";
           vunits(1) = "MHz";
           vunits(2) = "Hz";
        }
//
        spectralunit.define("popt", vunits);
        spectralunit.define("default", vunits(0));
        spectralunit.define("value", itsSpectralUnit);
        spectralunit.define("allowunset", False);
        rec.defineRecord("axislabelspectralunit", spectralunit);
     }
     {
        Record veltype;
        veltype.define("context", "Axis_label_properties");
        veltype.define("dlformat", "axislabelvelocitytype");
        veltype.define("listname", "Velocity type");
        veltype.define("ptype", "choice");
        Vector<String> vunits(3);
        vunits(0) = "optical";
        vunits(1) = "radio";
        vunits(2) = "true";
        veltype.define("popt", vunits);
        veltype.define("default", "radio");
        veltype.define("value", itsDoppler);
        veltype.define("allowunset", False);
        rec.defineRecord("axislabelvelocitytype", veltype);
     }
  }
  if (itsCoordinateSystem.nWorldAxes() > 2) {
    
    Record zlabeltype;
    zlabeltype.define("context", "Axis_label_properties");
    zlabeltype.define("dlformat", "axislabelzlabeltype");
    zlabeltype.define("listname", "Movie Axis label type");
    zlabeltype.define("ptype", "choice");
    Vector<String> vztype(3);
    vztype(0) = "none";
    vztype(1) = "world";
    vztype(2) = "pixel";
    zlabeltype.define("popt", vztype);
    zlabeltype.define("default", vztype(0));
    zlabeltype.define("value", itsZLabelType);
    zlabeltype.define("allowunset", False);
    rec.defineRecord("axislabelzlabeltype", zlabeltype);

  }
  
  return rec;
}

String WCCSAxisLabeller::xAxisText() const 
//
// The CS is ordered so that the first 2 axes
// are the display axes
//
{
  if (!isXAxisTextUnset()) {
    return WCAxisLabeller::xAxisText();
  }
//
  return axisText(0);
}


String WCCSAxisLabeller::yAxisText() const 
//
// The CS is ordered so that the first 2 axes
// are the display axes
//
{
  if (!isYAxisTextUnset()) {
    return WCAxisLabeller::yAxisText();
  }
//
  return axisText(1);
}


String WCCSAxisLabeller::axisText(Int worldAxis) const 
//
// The CS is ordered so that the first 2 axes
// are the display axes
//
{
  String base0 = itsCoordinateSystem.worldAxisNames()(worldAxis);
//
  String prefUnit = itsCoordinateSystem.worldAxisUnits()(worldAxis);
  if (!itsWorldAxisLabels) prefUnit = String("pixels");
//
  Int coordinate, axisInCoordinate;
  itsCoordinateSystem.findWorldAxis(coordinate, axisInCoordinate, worldAxis);
  Coordinate::Type ctype = itsCoordinateSystem.type(coordinate);
  String base;
  const Vector<Int>& worldAxes = itsCoordinateSystem.worldAxes(coordinate);
//
  if (ctype == Coordinate::DIRECTION) {
     const DirectionCoordinate& dcoord = 
       itsCoordinateSystem.directionCoordinate(coordinate);
//
     MDirection::Types dtype = dcoord.directionType();
     MDirection::Types ctype;
     dcoord.getReferenceConversion(ctype);
//
     Bool isLong = True;
     if (worldAxes(1)==worldAxis) isLong = False;

// Depending on the requested labelling type, we convert
// the axis unit name to something sensible. This is
// because it's confusing to see Galactic coordinates
// called 'Right Ascension' say.

     uInt ctypeI = static_cast<uInt>(ctype);
     MDirection::GlobalTypes gType = MDirection::globalType(ctypeI);
     if (dtype != ctype) {
        if (gType==MDirection::GRADEC) {
           if (isLong) {
              base0 = "Right Ascension";
           } else {
              base0 = "Declination";
           }
        } else if (gType==MDirection::GHADEC) {
           if (isLong) {
              base0 = "Hour Angle";
           } else {
              base0 = "Declination";
           }
        } else if (gType==MDirection::GAZEL) {
           if (isLong) {
              base0 = "Azimuth";
           } else {
              base0 = "Elevation";
           }
        } else if (gType==MDirection::GLONGLAT) {
           if (isLong) {
              base0 = "Longitude";
           } else {
              base0 = "Latitude";
           }
        }
     }
//
     String stype = MDirection::showType(ctype);
     if (itsAbsolute) {
        if (itsWorldAxisLabels) {
           base = stype + String(" ") + base0;
        } else {
           base = stype + String(" ") + base0 + String(" (") + prefUnit + String(")");
        }
     } else {
        base = String("Relative ") + stype + String(" ") + base0 +
               String(" (") + prefUnit + String(")");
     }
  } else if (ctype == Coordinate::SPECTRAL) {
    const SpectralCoordinate& dcoord = itsCoordinateSystem.spectralCoordinate(coordinate);
//
    MFrequency::Types ctype;
    MEpoch epoch;
    MPosition position;
    MDirection direction;
    dcoord.getReferenceConversion(ctype, epoch, position, direction);
    String freqType = MFrequency::showType(ctype);
//
    if (itsWorldAxisLabels) {

// We must avoid making a unit from the String 'pixels'

       Unit pVU(itsSpectralUnit);
       Unit HZ("Hz");
       Unit KMS("km/s");
       if (pVU==KMS) {
          prefUnit = itsSpectralUnit;
          base = freqType + String(" ") + itsDoppler + String(" velocity (") + prefUnit + String(")");
       } else if (pVU==HZ) {
          base = freqType + String(" ") + base0 + String(" (") + prefUnit + String(")");
       } else {
          base = freqType + String(" ") + base0 + String(" (") + prefUnit + String(")"); 
       }
    } else {
       base = freqType + String(" ") + base0 + String(" (") + prefUnit + String(")"); 
    }
//
    if (!itsAbsolute) {
      base = String("Relative ") + base;
    }
  } else if (ctype==Coordinate::STOKES) {
     base = base0;
     if (itsWorldAxisLabels) {
        if (!itsAbsolute) base = String("Relative ") + base;
     } else {
        if (!itsAbsolute) base = String("Relative ") + base + 
          String(" (") + prefUnit + String(")");
     }
  } else {
    base = base0 + String(" (") + prefUnit + String(")");
    if (!itsAbsolute) base = String("Relative ") + base;
  }
  return base;
}





void WCCSAxisLabeller::setSpectralState ()
{
   static LogIO os(LogOrigin("WCCSAxisLabeller", "setSpectralState", WHERE));

// Set velocity and/or world unit state in SpectralCoordinate

   String errorMsg;
   if (!CoordinateUtil::setSpectralState (errorMsg, itsCoordinateSystem,
                                          itsSpectralUnit, itsDoppler)) {
      os << errorMsg << LogIO::EXCEPTION;
   }

// Set Spectral Conversion Layer

   if (!CoordinateUtil::setSpectralConversion (errorMsg, itsCoordinateSystem,
                                               itsFrequencySystem)) {
      os << errorMsg << LogIO::EXCEPTION;
   }

// Set Spectral formatting (for movie axis labelling done via formatter)

   if (!CoordinateUtil::setSpectralFormatting (errorMsg, itsCoordinateSystem,
                                               itsSpectralUnit, itsDoppler)) {
      os << errorMsg << LogIO::EXCEPTION;
   }
   
// Indicate whether we are asking for kms or Hz conformant spectral units

   static Unit KMS(String("km/s"));
   Unit t(itsSpectralUnit);
   itsDoVelocity = (t==KMS);
}


void WCCSAxisLabeller::setDirectionState ()
{
   static  LogIO os(LogOrigin("WCCSAxisLabeller", "setDirectionState", WHERE));

// The user given units are only used for relative labels

   Int after = -1;
   Int iD = itsCoordinateSystem.findCoordinate(Coordinate::DIRECTION, after);
   if (iD>=0) {
      DirectionCoordinate coord(itsCoordinateSystem.directionCoordinate(iD));
      Vector<String> worldAxisUnits(coord.worldAxisUnits().copy());
//
      if (itsAbsolute) {
         worldAxisUnits = String("deg");
      } else {
         worldAxisUnits = itsDirectionUnit;
      }
//
      if (!coord.setWorldAxisUnits(worldAxisUnits)) {
         os << LogIO::SEVERE << coord.errorMessage() << LogIO::POST;
         return;
      }

// Set conversion type.  This lets the DC convert to other direction systems

      MDirection::Types cSystem;
      MDirection::getType(cSystem, itsDirectionSystem);
      coord.setReferenceConversion(cSystem);

// Replace in CS

      itsCoordinateSystem.replaceCoordinate(coord, iD);
   }
}


void WCCSAxisLabeller::setAbsRelState ()
//
// For absolute coordinates
//   Direction  - degrees
//   Spectral   - GHz
//   Linear     - native
// For relative coordinates
//   Direction  
//     RA/DEC  - arcsec
//     LON/LAT - degrees
//   Spectral   - GHz
//   Linear     - native
// 
// The Spectral unit is under user control (e.g. km/s) so we don't
// overwrite what they have provided. At some point the
// other coordinates will be under user control as well,
// but for now above is what they get
//
{
   const uInt n = itsCoordinateSystem.nCoordinates();
   unsetXAxisText();
   unsetYAxisText();
//
   for (uInt i=0; i<n; i++) {
      if (itsCoordinateSystem.type(i)==Coordinate::DIRECTION) {
         setDirectionState();
      } else if (itsCoordinateSystem.type(i)==Coordinate::SPECTRAL) {
         setSpectralState();
      } else {
// Leave as native world axis units
      }
   }
}

} //# NAMESPACE CASA - END

