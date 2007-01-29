//# DOcoordsys.cc: defines DOcoordsys class which implements functionality
//# for the coordinate system Distributed Object
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
//#
//# $Id: DOcoordsys.cc,v 19.15 2005/11/07 21:17:03 wyoung Exp $

#include <appsglish/app_image/DOcoordsys.h>

#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayUtil.h>
#include <coordinates/Coordinates/CoordinateSystem.h>
#include <coordinates/Coordinates/DirectionCoordinate.h>
#include <coordinates/Coordinates/Projection.h>
#include <coordinates/Coordinates/StokesCoordinate.h>
#include <coordinates/Coordinates/SpectralCoordinate.h>
#include <coordinates/Coordinates/LinearCoordinate.h>
#include <coordinates/Coordinates/TabularCoordinate.h>
#include <coordinates/Coordinates/CoordinateUtil.h>
#include <casa/Containers/Record.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Logging/LogIO.h>
#include <casa/Logging/LogFilter.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MDoppler.h>
#include <measures/Measures/MFrequency.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MeasTable.h>
#include <measures/Measures/MeasureHolder.h>
#include <measures/Measures/Stokes.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Quanta/MVAngle.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Quanta/MVEpoch.h>
#include <casa/Quanta/QuantumHolder.h>
#include <casa/OS/Time.h>
#include <tasking/Tasking/Index.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/ObjectController.h>
#include <casa/Utilities/Assert.h>
#include <casa/Utilities/DataType.h>

#include <casa/sstream.h>

#include <casa/namespace.h>

coordsys::coordsys(Bool direction, Bool spectral, const Vector<String>& stokes,
                   Int linear, Bool tabular)
: itsParentImageName("unknown")
{
   addCoordinate(itsCSys, direction, spectral, stokes, linear, tabular);

// Give it a meaningful ObsInfo

   ObsInfo obsInfo;
   obsInfo.setTelescope(String("ATCA"));
   obsInfo.setObserver(String("Karl Jansky"));

// It must be easier than this...  USe 0.0001
// so that roundoff does not tick the 0 to 24

   Time time;
   time.now();
   MVTime time2(time);
   MVEpoch time4(time2);
   MEpoch date(time4);
   obsInfo.setObsDate(date);
//
   itsCSys.setObsInfo(obsInfo);
}

coordsys::coordsys(const CoordinateSystem& cSys)
: itsCSys(cSys)
{}


coordsys::coordsys(const coordsys& other)
{
    *this = other;
}

coordsys& coordsys::operator=(const coordsys& other)
{
    if (this != &other) {
       itsCSys = other.itsCSys;
    }
//
    return *this;
}

coordsys::~coordsys()
{
}



// Public methods

void coordsys::addCoordinate (Bool direction, Bool spectral, const Vector<String>& stokes,
                              Int linear, Bool tabular)
{
   addCoordinate(itsCSys, direction, spectral, stokes, linear, tabular);
}


Vector<Int> coordsys::axesMap (Bool toWorld) const
{
   Vector<Int> map;
   if (toWorld) {
      map.resize(itsCSys.nPixelAxes());
      for (uInt i=0; i<itsCSys.nPixelAxes(); i++) {
         map(i) = itsCSys.pixelAxisToWorldAxis(i);
         if (map(i) >= 0) map(i)  += 1;    // 1-rel
      }
   } else {
      map.resize(itsCSys.nWorldAxes());
      for (uInt i=0; i<itsCSys.nWorldAxes(); i++) {
         map(i) = itsCSys.worldAxisToPixelAxis(i);
         if (map(i) >= 0) map(i)  += 1;    // 1-rel
      }
   }
   return map;
}


Vector<String> coordsys::axisCoordinateTypes (Bool world) const 
{
   LogIO os(LogOrigin("coordsys", "axisCoordinateTypes", id(), WHERE));
   Int coord;
   Int axisInCoord;
   Vector<String> types;
//
   if (world) {
      const uInt nAxes = itsCSys.nWorldAxes();
      types.resize(nAxes);
      for (uInt i=0; i<nAxes; i++) {
         itsCSys.findWorldAxis(coord, axisInCoord, i);
         if (coord>=0) {
            types(i) = itsCSys.showType (coord);
         } else {

// This should never happen because we found the coordinate from
// a valid world axis

            os << "World axis " << i+1 << " has been removed from the CoordinateSystem" << LogIO::POST;
         }
      }
   } else {
      const uInt nAxes = itsCSys.nPixelAxes();
      types.resize(nAxes);
      for (uInt i=0; i<nAxes; i++) {
         itsCSys.findPixelAxis (coord, axisInCoord, i);
         if (coord>=0) {
            types(i) = itsCSys.showType (coord);
         } else {

// This should never happen because we found the coordinate from
// a valid pixel axis

            os << "Pixel axis " << i+1 << " has been removed from the CoordinateSystem" << LogIO::POST;
         }
      }
   }
//
   return types;
}


Vector<String> coordsys::coordinateType (Index which) const 
{
   const Int n = itsCSys.nCoordinates();
   LogIO os(LogOrigin("coordsys", "coordinateType", id(), WHERE));
   if (n==0) {
      os << "This CoordinateSystem is empty" << LogIO::EXCEPTION;
   }
//
   Vector<String> types;
   Int which2 = which();
   if (which2<0) {
      types.resize(n);
      for (Int i=0; i<n; i++) types(i) = itsCSys.showType(i);
   } else {
      if (which2 < 0 || which2+1 > n) {
         ostringstream oss;
         oss << "There are only " << n << " coordinates available";
         os << String(oss) << LogIO::EXCEPTION;   
      }
      types.resize(1);
      types(0) = itsCSys.showType(which2);
   }
   return types;
}


MEpoch coordsys::epoch () const
{
   const ObsInfo& obsInfo = itsCSys.obsInfo();
   return obsInfo.obsDate();
}

Bool coordsys::findAxis (Int& coordinate,
                         Int& axisInCoordinate,
                         Bool isWorld,
                         Int axis) const
{
   LogOrigin OR("coordsys", "findAxis(...)", id(), WHERE);
   LogIO os(OR);  
//
   axis--;
   if (isWorld) {
      itsCSys.findWorldAxis(coordinate, axisInCoordinate, axis);
   } else {
      itsCSys.findPixelAxis(coordinate, axisInCoordinate, axis);   
   }
   if (coordinate >=0) {
      coordinate++;
      axisInCoordinate++;
      return True;
   }
//
   return False;
}


Bool coordsys::findCoordinate (Vector<Int>& pixelAxes,
                               Vector<Int>& worldAxes,
                               const String& coordType,
                               Index which) const
{    
   LogOrigin OR("coordsys", "findCoordinate(...)", id(), WHERE);
   LogIO os(OR);  
//
   const Coordinate::Type type = stringToType(coordType);
//  
   Int which2 = which();
   if (which2<0) which2 = 0;
   Int after = -1;
   Int count = -1;
//
   pixelAxes.resize(0);
   worldAxes.resize(0);
   while (True) {
      Int c = itsCSys.findCoordinate(type, after);
      if (c<0) {
         return False;
      } else {
         count++;
         if (count==which2) {
            pixelAxes = itsCSys.pixelAxes(c);
            worldAxes = itsCSys.worldAxes(c);
            for (uInt i=0; i<pixelAxes.nelements(); i++) pixelAxes(i) += 1;
            for (uInt i=0; i<worldAxes.nelements(); i++) worldAxes(i) += 1;
            return True;
         }
      }
      after = c;
   }
}


Vector<Double> coordsys::frequencyToFrequency (const Vector<Double>& frequency,
                                               const String& freqUnit,
                                               const String& doppler,
                                               const Quantum<Double>& velocity) const
{
   LogOrigin OR("coordsys", "frequencytofrequency(...)", id(), WHERE);
   LogIO os(OR);  
//
    MDoppler::Types dopplerType;
    if (!MDoppler::getType(dopplerType, doppler)) {
       os << LogIO::WARN << "Illegal velocity doppler, using RADIO" << LogIO::POST;
       dopplerType = MDoppler::RADIO;
    }
//
   MDoppler dop (velocity, dopplerType);
   Quantum<Vector<Double> > tmp(frequency, Unit(freqUnit));
   return dop.shiftFrequency(tmp).getValue();
}


Vector<Double> coordsys::frequencyToVelocity (const Vector<Double>& frequency,
                                              const String& freqUnit,
                                              const String& doppler,
                                              const String& velUnit) const
{
   LogOrigin OR("coordsys", "frequencyToVelocity(...)", id(), WHERE);
   LogIO os(OR);  
//
   Int after = -1;
   Int c = itsCSys.findCoordinate(Coordinate::SPECTRAL, after);
   if (c < 0) {
      os << "There is no spectral coordinate in this Coordinate System" << LogIO::EXCEPTION;
   }

// Get SpectralCoordinate

   const SpectralCoordinate& sc0 = itsCSys.spectralCoordinate(c);
   SpectralCoordinate sc(sc0);
   Vector<String> units(sc.worldAxisUnits().copy());
   units(0) = freqUnit;
   if (!sc.setWorldAxisUnits(units)) {
      os << "Failed to set frequency units of " << freqUnit << " because " << sc.errorMessage() << LogIO::EXCEPTION;
   }

// Convert velocity type to enum

    MDoppler::Types dopplerType;
    if (!MDoppler::getType(dopplerType, doppler)) {
       os << LogIO::WARN << "Illegal velocity doppler, using RADIO" << LogIO::POST;
       dopplerType = MDoppler::RADIO;
    }

// Convert to velocity

   sc.setVelocity (velUnit, dopplerType);
   Vector<Double> velocity;
   if (!sc.frequencyToVelocity (velocity, frequency)) {
     os << "Conversion to velocity failed because " << sc.errorMessage() << endl;
   }
   return velocity;
}

Vector<Double> coordsys::velocityToFrequency (const Vector<Double>& velocity,
                                              const String& freqUnit,
                                              const String& dopplerType,
                                              const String& velUnit) const
{
   LogOrigin OR("coordsys", "velocityToFrequency(...)", id(), WHERE);
   LogIO os(OR);  
//
   Int after = -1;
   Int c = itsCSys.findCoordinate(Coordinate::SPECTRAL, after);
   if (c < 0) {
      os << "There is no spectral coordinate in this Coordinate System" << LogIO::EXCEPTION;
   }

// Get SpectralCoordinate

   const SpectralCoordinate& sc0 = itsCSys.spectralCoordinate(c);
   SpectralCoordinate sc(sc0);
   Vector<String> units(sc.worldAxisUnits().copy());
   units(0) = freqUnit;
   if (!sc.setWorldAxisUnits(units)) {
      os << "Failed to set frequency units of " << freqUnit << " because " << sc.errorMessage() << LogIO::EXCEPTION;
   }

// Convert velocity type to enum

    MDoppler::Types velType;
    if (!MDoppler::getType(velType, dopplerType)) {
       os << LogIO::WARN << "Illegal velocity type, using RADIO" << LogIO::POST;
       velType = MDoppler::RADIO;
    }

// Convert to fequency

   sc.setVelocity (velUnit, velType);
   Vector<Double> frequency;
   if (!sc.velocityToFrequency(frequency, velocity)) {
     os << "Conversion to frequency failed because " << sc.errorMessage() << endl;
   }
   return frequency;
}

 

void coordsys::fromGlishRecord (const GlishRecord& gRec) 
{
   LogIO os(LogOrigin("coordsys", "fromGlishRecord", id(), WHERE));
//
   Record rec;
   gRec.toRecord(rec);
   CoordinateSystem* pCS = CoordinateSystem::restore(rec, "");
   if (pCS==0) {
      os << "Failed to create a CoordinateSystem from this record" << LogIO::EXCEPTION;
   }
//
   itsCSys = *pCS;
   delete pCS;
//
   if (rec.isDefined("parentName")) {
     itsParentImageName = rec.asString("parentName");
   }
}

GlishRecord coordsys::increment (const String& type, const String& format)
{
   Vector<Double> incr;
   Int c = -1;
   if (type.empty()) {
      incr = itsCSys.increment();
   } else {   
      Coordinate::Type cType = stringToType(type);
      Int after = -1;
      c = itsCSys.findCoordinate(cType, after);
      incr = itsCSys.coordinate(c).increment();
   }
//
   Bool isAbsolute = False;
   Bool showAsAbsolute = False;
   Record rec = worldVectorToRecord (incr, c, format, isAbsolute, showAsAbsolute);
//
   GlishRecord gRec;
   gRec.fromRecord(rec);
   return gRec;
}


Array<Double> coordsys::linearTransform (const String& type)
{
   LogIO os(LogOrigin("coordsys", "linearTransform", id(), WHERE));
//
   if (type.empty()) {
      os << "You must specify the coordinate type" << LogIO::EXCEPTION;
   }
//
   Coordinate::Type cType = stringToType(type);
   Int after = -1;
   Int c = itsCSys.findCoordinate(cType, after);
   return itsCSys.coordinate(c).linearTransform();
}


Int coordsys::nAxes (Bool world) const
{
   if (world) {
      return itsCSys.nWorldAxes();
   } else {
      return itsCSys.nPixelAxes();
   }
}

String coordsys::observer() const
{
   const ObsInfo& obsInfo = itsCSys.obsInfo();
   return obsInfo.observer();
}


GlishRecord coordsys::projection (const String& name) const
{
// Exception if type not found

   Int c = findCoordinate (Coordinate::DIRECTION, True);
//
   Record rec;
   const DirectionCoordinate& dc = itsCSys.directionCoordinate(c);
   const Projection proj = dc.projection();
//
   if (name.empty()) {

// Return actual projection

      rec.define("type", proj.name());
      rec.define("parameters", proj.parameters());
   } else {

// Return number of parameters needed for given projection

      String name2 = upcase(name);
      String name3(name2.at(0,3));
//

// Return all types

      if (name3==String("ALL")) {
         const Int nProj = Projection::N_PROJ;
         Vector<String> types(nProj);
         for (Int i=0; i<nProj; i++) {
            Projection::Type type = static_cast<Projection::Type>(i);
            types(i) = Projection::name(type);
         }
         rec.define("types", types);
         rec.define("all", True);
      } else {
         Projection::Type type = Projection::type(name3);

// Throws exception for unknown type

         const Int nP = Projection::nParameters(type);
         rec.define("nparameters", nP);
      }
   }
//
   GlishRecord gRec;
   gRec.fromRecord(rec);
   return gRec;
}


Vector<String> coordsys::referenceCode (const String& coordinateType) const
{
   const uInt nCoords = itsCSys.nCoordinates();
   Vector<String> codes;
   Int iStart, iEnd;
   if (coordinateType.empty()) {
      iStart = 0;
      iEnd  = nCoords-1;
   } else {
      const Coordinate::Type type = stringToType(coordinateType);

// Exception if type not found

      if (type==Coordinate::DIRECTION) {
         iStart = findCoordinate (Coordinate::DIRECTION, True);
      } else if (type==Coordinate::SPECTRAL) {
         iStart = findCoordinate (Coordinate::SPECTRAL, True);
      } else {
         iStart = -1;
      }
      iEnd = iStart;
   }
//
   if (iStart==-1) {
      codes.resize(1);
      codes(0) = String("");
   } else {      
      codes.resize(iEnd-iStart+1);
      for (Int i=iStart,j=0; i<iEnd+1; i++,j++) {
         Coordinate::Type type = itsCSys.type(i);
         if (type==Coordinate::DIRECTION) {
            const DirectionCoordinate& dc = itsCSys.directionCoordinate(i);
            MDirection::Types dt = dc.directionType();
            codes(j) = MDirection::showType (dt);
         } else if (type==Coordinate::SPECTRAL) {
            const SpectralCoordinate& sc = itsCSys.spectralCoordinate(i);
            MFrequency::Types ft = sc.frequencySystem();
            codes(j) = MFrequency::showType (ft);
         } else {
            codes(j) = String("");
         }
      }
   }
   return codes;
} 


GlishRecord coordsys::referenceValue (const String& type, const String& format)
{
   LogIO os(LogOrigin("coordsys", "referenceValue", id(), WHERE));
//
   Vector<Double> refVal;
   Int c = -1;
   if (type.empty()) {
      refVal = itsCSys.referenceValue();
   } else {   
      Coordinate::Type cType = stringToType(type);
      Int after = -1;
      c = itsCSys.findCoordinate(cType, after);
      refVal = itsCSys.coordinate(c).referenceValue();
   }
//
   Bool isAbsolute = True;
   Bool showAsAbsolute = True;
   Record rec = worldVectorToRecord (refVal, c, format, isAbsolute, showAsAbsolute);
//
   GlishRecord gRec;
   gRec.fromRecord(rec);
   return gRec;
}



void coordsys::reorder (const Vector<Index>& order)
//
// This is pretty dody - if the axes have been reordered this
// is all rubbish
//
{
    LogOrigin OR("coordsys", "reorder(...)", id(), WHERE);
    LogIO os(OR);  
//
    Vector<Int> order2(order.nelements());
    Index::convertVector(order2, order);
//
    const uInt nCoord = itsCSys.nCoordinates();
    if (order2.nelements() != nCoord) {       
       os << "order vector must be of length " << nCoord << LogIO::EXCEPTION; 
    }
//
    CoordinateSystem cSys;
    cSys.setObsInfo(itsCSys.obsInfo());
    for (uInt i=0; i<nCoord; i++) {
       cSys.addCoordinate(itsCSys.coordinate(order2(i)));
    }
    itsCSys = cSys;
}


Quantum<Vector<Double> > coordsys::restFrequency () const
{
// Exception if type not found

   Int c = findCoordinate (Coordinate::SPECTRAL, True);
//
   const SpectralCoordinate& sc = itsCSys.spectralCoordinate(c);
//
   const Vector<Double> rfs = sc.restFrequencies();
   Double rf = sc.restFrequency();
   Vector<Double> rfs2(rfs.nelements());
   rfs2(0) = rf;
   uInt j = 1;
   for (uInt i=0; i<rfs.nelements(); i++) {
      if (!::near(rfs(i), rf)) {
         rfs2(j) = rfs(i);
         j++;      
      }     
   }
//
   Quantum<Vector<Double> > q(rfs2, sc.worldAxisUnits()(0));
   return q;
}



Bool coordsys::setConversionType (const String& direction, const String& spectral)
{
   LogIO os(LogOrigin("coordsys", "setConversionType", id(), WHERE));
//
   String errorMsg;
   if (!direction.empty()) {
      if (!CoordinateUtil::setDirectionConversion (errorMsg, itsCSys, direction)) {
         os << "Failed to set the new DirectionCoordinate reference frame because " << errorMsg << LogIO::EXCEPTION;
      }
   }      
//
   if (!spectral.empty()) {
      if (!CoordinateUtil::setSpectralConversion (errorMsg, itsCSys, spectral)) {
         os << "Failed to set the new SpectralCoordinate reference frame because " << errorMsg << LogIO::EXCEPTION;
      }
   }      
//
   return True;
}


String coordsys::getConversionType (const String& type)
{
   LogIO os(LogOrigin("coordsys", "getConversionType", id(), WHERE));
//
   Coordinate::Type cType = stringToType(type);
   if (cType==Coordinate::DIRECTION) {
      Int after = -1;
      Int c = itsCSys.findCoordinate(Coordinate::DIRECTION, after);
      if (c >= 0) {
         const DirectionCoordinate& dCoord = itsCSys.directionCoordinate(c);
         MDirection::Types type;
         dCoord.getReferenceConversion(type);
         return MDirection::showType(type);
      }
   } else if (cType==Coordinate::SPECTRAL) {
      Int after = -1;
      Int c = itsCSys.findCoordinate(Coordinate::SPECTRAL, after);
      if (c >= 0) {
         const SpectralCoordinate& sCoord = itsCSys.spectralCoordinate(c);
         MFrequency::Types type;
         MEpoch epoch;
         MDirection direction;
         MPosition position;
         sCoord.getReferenceConversion(type, epoch, position, direction);
         return MFrequency::showType(type);
      }
   }
//
   return String("");
}


void coordsys::setEpoch (const MEpoch& epoch) 
{
   ObsInfo obsInfo = itsCSys.obsInfo();
   obsInfo.setObsDate(epoch);
   itsCSys.setObsInfo(obsInfo);
}


void coordsys::setIncrement (const String& coordinateType, const GlishRecord& gRec)
{
   LogIO os(LogOrigin("coordsys", "setIncrement", id(), WHERE));
//
   Record rec;
   gRec.toRecord (rec);
   String dummyType;
   Int c;
   Vector<Double> world;
//
   if (coordinateType.empty()) {
      c = -1;
      recordToWorldVector(world, dummyType, c, rec);
      trim(world, itsCSys.increment());
      if (!itsCSys.setIncrement(world)) {
         os << itsCSys.errorMessage() << LogIO::EXCEPTION;
      }
   } else {
      const Coordinate::Type type = stringToType (coordinateType);
      Int c = findCoordinate (type, True);
      recordToWorldVector(world, dummyType, c, rec);
      trim(world, itsCSys.coordinate(c).referenceValue());
//
      Vector<Double> incAll(itsCSys.increment().copy());
      copyWorldAxes(incAll, world, c);
//
      if (!itsCSys.setIncrement(incAll)) {
         os << itsCSys.errorMessage() << LogIO::EXCEPTION;
      }
   }
}


void coordsys::setObserver (const String& observer) 
{
   ObsInfo obsInfo = itsCSys.obsInfo();
   obsInfo.setObserver(observer);
   itsCSys.setObsInfo(obsInfo);
}


void coordsys::setProjection (const String& name, const Vector<Double>& parameters)
{
   
// Exception if type not found

   Int ic = findCoordinate (Coordinate::DIRECTION, True);
//
   LogIO os(LogOrigin("coordsys", "setProjection", id(), WHERE));

   DirectionCoordinate dirCoordFrom(itsCSys.directionCoordinate(ic));      // Copy
   Vector<String> unitsFrom = dirCoordFrom.worldAxisUnits().copy();

// Set radian units so we can copy constructor parameters over

   Vector<String> radUnits(2);
   radUnits = String("rad");
   if (!dirCoordFrom.setWorldAxisUnits(radUnits)) {
      os << "Failed to set radian units for DirectionCoordinate" << LogIO::EXCEPTION;
   }

// Create output DirectionCoordinate

   Projection::Type type = Projection::type(name);
   Projection projTo(type, parameters);
//
   Vector<Double> refValFrom = dirCoordFrom.referenceValue();
   Vector<Double> refPixFrom = dirCoordFrom.referencePixel();
   Vector<Double> incrFrom = dirCoordFrom.increment();
   DirectionCoordinate dirCoordTo (dirCoordFrom.directionType(), projTo,
                                   refValFrom(0), refValFrom(1),
                                   incrFrom(0), incrFrom(1),
                                   dirCoordFrom.linearTransform(),
                                   refPixFrom(0), refPixFrom(1));

// Set original units

   if (!dirCoordTo.setWorldAxisUnits(unitsFrom)) {
      os << dirCoordTo.errorMessage() << LogIO::EXCEPTION;
   }

// Replace in Coordinate System

   itsCSys.replaceCoordinate(dirCoordTo, ic);
} 




void coordsys::setReferenceCode (const String& coordinateType, const String& code, Bool adjust)
{
   const Coordinate::Type type = stringToType (coordinateType);
//
   if (type==Coordinate::DIRECTION) {
      setDirectionCode(code, adjust);
   } else if (type==Coordinate::SPECTRAL) {
      setSpectralCode(code, adjust);
   } else {
      LogIO os(LogOrigin("coordsys", "setReferenceCode", id(), WHERE));
      os << "Coordinate type must be 'Direction' or 'Spectral'" << LogIO::EXCEPTION;
   }
}


void coordsys::setReferencePixel (const String& coordinateType, const Vector<Double>& refPix)
{
   LogIO os(LogOrigin("coordsys", "setReferencePixel", id(), WHERE));
//
   Vector<Double> refPix2;
   refPix2 = refPix - 1.0;                     // 0-rel
//
   if (coordinateType.empty()) {
      trim(refPix2, itsCSys.referencePixel());
      if (!itsCSys.setReferencePixel(refPix2)) {
         os << itsCSys.errorMessage() << LogIO::EXCEPTION;
      }
   } else {
      const Coordinate::Type type = stringToType (coordinateType);
      Int c = findCoordinate (type, True);
      trim(refPix2, itsCSys.coordinate(c).referencePixel());
//
      Vector<Int> pixelAxes = itsCSys.pixelAxes(c);
      Vector<Double> refPixAll = itsCSys.referencePixel();
      for (uInt i=0; i<pixelAxes.nelements(); i++) {
         refPixAll(pixelAxes(i)) = refPix2(i);
      }
//
      if (!itsCSys.setReferencePixel(refPixAll)) {
         os << itsCSys.errorMessage() << LogIO::EXCEPTION;
      }
   }
}


void coordsys::setLinearTransform (const String& coordinateType, const Array<Double>& value)
{
   LogIO os(LogOrigin("coordsys", "setLinearTransform", id(), WHERE));
//
   if (coordinateType.empty()) {
      os << "You must specify the coordinate type" << LogIO::EXCEPTION;
   }
//
   const Coordinate::Type type = stringToType (coordinateType);
   Int c = findCoordinate (type, True);
   if (type==Coordinate::LINEAR) {
      LinearCoordinate lc = itsCSys.linearCoordinate(c);
      lc.setLinearTransform(value);
      itsCSys.replaceCoordinate(lc, c);
   } else if (type==Coordinate::DIRECTION) {
      DirectionCoordinate lc = itsCSys.directionCoordinate(c);
      lc.setLinearTransform(value);
      itsCSys.replaceCoordinate(lc, c);
   } else if (type==Coordinate::SPECTRAL) {
      SpectralCoordinate lc = itsCSys.spectralCoordinate(c);
      lc.setLinearTransform(value);
      itsCSys.replaceCoordinate(lc, c);
   } else if (type==Coordinate::STOKES) {
      StokesCoordinate lc = itsCSys.stokesCoordinate(c);
      lc.setLinearTransform(value);
      itsCSys.replaceCoordinate(lc, c);
   } else if (type==Coordinate::TABULAR) {
      TabularCoordinate lc = itsCSys.tabularCoordinate(c);
      lc.setLinearTransform(value);
      itsCSys.replaceCoordinate(lc, c);
   } else {
      os << "Coordinate type not yet handled " << LogIO::EXCEPTION;
   }
}



void coordsys::setReferenceValue (const String& coordinateType, const GlishRecord& gRec)
{
   LogIO os(LogOrigin("coordsys", "setReferenceValue", id(), WHERE));
//
   Record rec;
   gRec.toRecord (rec);
   String dummyType;
   Int c;
//
   Vector<Double> world;
   if (coordinateType.empty()) {
      c = -1;
      recordToWorldVector(world, dummyType, c, rec);
      trim(world, itsCSys.referenceValue());
      if (!itsCSys.setReferenceValue(world)) {
         os << itsCSys.errorMessage() << LogIO::EXCEPTION;
      }
   } else {
      const Coordinate::Type type = stringToType (coordinateType);
      c = findCoordinate (type, True);
      recordToWorldVector(world, dummyType, c, rec);
      trim(world, itsCSys.coordinate(c).referenceValue());
//
      Vector<Double> refValAll(itsCSys.referenceValue().copy());
      copyWorldAxes(refValAll, world, c);
//
      if (!itsCSys.setReferenceValue(refValAll)) {
         os << itsCSys.errorMessage() << LogIO::EXCEPTION;
      }
   }
}




void coordsys::setRestFrequency (const Quantum<Vector<Double> >& restFrequency, 
                                 Index which, Bool append) 
{
// Exception if type not found

   Int c = findCoordinate (Coordinate::SPECTRAL, True);
   SpectralCoordinate sc = itsCSys.spectralCoordinate(c);
//
   Vector<Double> rf = restFrequency.getValue(Unit(sc.worldAxisUnits()(0)));
//
   if (which() >= 0) {
      sc.setRestFrequencies(rf, which(), append);
   } else {
      LogIO os(LogOrigin("coordsys", "setRestFrequency", id(), WHERE));
      os << "Illegal index '" << which() << "' into restfrequency vector" << LogIO::EXCEPTION;
   }
//
   itsCSys.replaceCoordinate(sc, c);
}



void coordsys::setDirectionCoordinate (const String& ref,
                                       const String& projName,
                                       const Vector<Double>& projPar,
                                       const Vector<Double>& refPix,
                                       const GlishRecord& refValGRec,
                                       const GlishRecord& incrGRec,
                                       const GlishRecord& polesGRec,
                                       const Array<Double>& xform)
{
   LogIO os(LogOrigin("coordsys", "setDirectionCoordinate", id(), WHERE));

// Exception if coordinate not found

   Int ic = findCoordinate (Coordinate::DIRECTION, True);
   const DirectionCoordinate oldDC = itsCSys.directionCoordinate(ic);
   const Vector<String>& oldUnits = oldDC.worldAxisUnits();

// Reference Code

   String ref2 = ref;
   ref2.upcase();
   MDirection::Types refType;
   if (!MDirection::getType(refType, ref2)) {
      os << "Invalid direction code '" << ref << "' given. Allowed are : " << endl;
      for (uInt i=0; i<MDirection::N_Types; i++) os << "  " << MDirection::showType(i) << endl;
      os << LogIO::EXCEPTION;
   }

// Projection

   Projection proj(Projection::type(projName), projPar);

// Reference Value.  Value comes back from recordToWorld in native 
// units of itsCSys for this Coordinate. 

   String dummyType;
   Vector<Double> refval;
   Record refvalRec;
   refValGRec.toRecord (refvalRec);
   recordToWorldVector(refval, dummyType, ic, refvalRec);
   trim(refval, oldDC.referenceValue());

// Increment

   String dummyType2;
   Vector<Double> incr;
   Record incrRec;
   incrGRec.toRecord (incrRec);
   recordToWorldVector(incr, dummyType2, ic, incrRec);
   trim(incr, oldDC.increment());

// Poles

   String dummyType3;
   Vector<Double> poles;
   Record polesRec;
   polesGRec.toRecord (polesRec);
   recordToWorldVector(poles, dummyType3, ic, polesRec);
   Vector<Double> xx(2);
   xx = 999.0;
   trim(poles, xx);
//
   Matrix<Double> xform2(xform);
   DirectionCoordinate newDC(refType, proj, 
                             Quantum<Double>(refval[0], oldUnits[0]),
                             Quantum<Double>(refval[1], oldUnits[1]),
                             Quantum<Double>(incr[0], oldUnits[0]),
                             Quantum<Double>(incr[1], oldUnits[1]),
                             xform2, refPix[0]-1.0, refPix[1]-1.0, 
                             Quantum<Double>(poles[0], oldUnits[0]),
                             Quantum<Double>(poles[1], oldUnits[1]));
//
   itsCSys.replaceCoordinate(newDC, ic);
}


void coordsys::setSpectralCoordinate (const String& ref,
                                      const Quantum<Double>& restFrequency,
                                      const Quantum<Vector<Double> >& frequencies,
                                      const String& doppler,
                                      const Quantum<Vector<Double> >& velocities,
                                      Bool dofreq, Bool dovel)
{
   LogIO os(LogOrigin("coordsys", "setSpectralCoordinate", id(), WHERE));

// Exception if coordinate not found

   Int ic = findCoordinate (Coordinate::SPECTRAL, True);
   SpectralCoordinate oldSpecCoord(itsCSys.spectralCoordinate(ic));
   const Vector<String>& names = oldSpecCoord.worldAxisNames();

// Frequency system

   if (!ref.empty()) {
      MFrequency::Types freqType;
      String code = ref;
      code.upcase();
      if (!MFrequency::getType(freqType, code)) {
         os << "Invalid frequency reference '" << code << "'" << LogIO::EXCEPTION;
      } 
      oldSpecCoord.setFrequencySystem(freqType);
   }

// Rest frequency

   if (restFrequency.getValue() > 0) {
      Quantum<Double> t(restFrequency);
      t.convert(Unit(oldSpecCoord.worldAxisUnits()(0)));
      oldSpecCoord.setRestFrequency(t.getValue(), False);
   }

// Frequencies

   Bool doneFreq = False;
   if (dofreq) {
      if (frequencies.getFullUnit() == Unit(String("Hz"))) {
/*
         os << LogIO::NORMAL << "Creating tabular SpectralCoordinate";
         os << " with " << frequencies.getValue().nelements() << " frequency elements" << LogIO::POST;
*/
         SpectralCoordinate sc(oldSpecCoord.frequencySystem(),
                               frequencies.getValue(Unit(String("Hz"))), 
                               oldSpecCoord.restFrequency());
         sc.setWorldAxisNames(names);
//
         itsCSys.replaceCoordinate(sc, ic);
         doneFreq = True;
      } else {
         os << "Illegal unit for frequencies" << LogIO::EXCEPTION;
      }
   }

// Velocities

   Bool doneVel = False;
   if (dovel) {
      if (velocities.getFullUnit() == Unit(String("km/s"))) {
         if (doneFreq) {
            os << "You cannot specify frequencies and velocities" << LogIO::EXCEPTION;
         }
//
         MDoppler::Types dopplerType;
         if (doppler.empty()) {
            os << "You must specify the doppler type" << LogIO::EXCEPTION;
         }
         if (!MDoppler::getType(dopplerType, doppler)) {
            os << "Invalid doppler '" << doppler << "'" << LogIO::EXCEPTION;
         }
//
/*
         os << LogIO::NORMAL << "Creating tabular SpectralCoordinate";
         os << " with " << velocities.getValue().nelements() << " velocity elements" << LogIO::POST;
*/
         SpectralCoordinate sc(oldSpecCoord.frequencySystem(),
                               dopplerType,
                               velocities.getValue(), 
                               velocities.getFullUnit().getName(),
                               oldSpecCoord.restFrequency());
         sc.setWorldAxisNames(names);
//
         itsCSys.replaceCoordinate(sc, ic);
         doneVel = True;
      } else {
         os << "Illegal unit for velocities" << LogIO::EXCEPTION;
      }
   }
//
   if (!doneFreq && !doneVel) {
      itsCSys.replaceCoordinate(oldSpecCoord, ic);
   }
} 



void coordsys::setStokes(const Vector<String>& stokes)
{
// Exception if type not found

   Int c = findCoordinate (Coordinate::STOKES, True);

//
   if (stokes.nelements()>0) {
      Vector<Int> which(stokes.nelements());
      for (uInt i=0; i<stokes.nelements(); i++) {
         String tmp = upcase(stokes(i));
         which(i) = Stokes::type(tmp);
      }
//
      const StokesCoordinate& sc = itsCSys.stokesCoordinate(c);
      StokesCoordinate sc2(sc);
      sc2.setStokes(which);
      itsCSys.replaceCoordinate(sc2, c);
   } else {
      LogIO os(LogOrigin("coordsys", "setStokes", id(), WHERE));
      os << "You did not specify any new Stokes values" << LogIO::EXCEPTION;
   }
}



void coordsys::setTabularCoordinate (const Vector<Double>& pixel,
                                     const Vector<Double>& world, Index which)
{
   LogIO os(LogOrigin("coordsys", "setTabularCoordinate", id(), WHERE));

// Exception if coordinate not found

   Int idx = which();
   if (idx < 0) {
      os << "The specified TabularCoordinate number must be >= 1" << LogIO::EXCEPTION;
   }
//
   Int ic = -1;
   for (Int i=0,j=0; i<Int(itsCSys.nCoordinates()); i++) {
      if (itsCSys.type(i)==Coordinate::TABULAR) {
         if (j==idx) {
           ic = i;
           break;
         } else {
           j++;
         }
      }
   }         
   if (ic==-1) {
      os << "Specified TabularCoordinate could not be found" << LogIO::EXCEPTION;
   }
//
   TabularCoordinate oldTabularCoord(itsCSys.tabularCoordinate(ic));
   const String  name = oldTabularCoord.worldAxisNames()(0);
   const String  unit = oldTabularCoord.worldAxisUnits()(0);
//
   Vector<Double> oldPixel = oldTabularCoord.pixelValues();
   Vector<Double> oldWorld = oldTabularCoord.worldValues();
//
   uInt nPixel = pixel.nelements();
   uInt nWorld = world.nelements();
//
   if (nPixel==0 && nWorld==0) {
      os << "You must give at least one of the pixel or world vectors" << LogIO::EXCEPTION;
   }
   if (nPixel!=0 && nWorld!=0 && nPixel!=nWorld) {
      os << "Pixel and world vectors must be the same length" << LogIO::EXCEPTION;
   }
//
   Vector<Double> p = oldPixel.copy();
   if (nPixel > 0) {
      p.resize(0);
      p = pixel - 1.0;
   } else {
      os << "Old pixel vector length = " << oldPixel.nelements() << LogIO::POST;
   }
   nPixel = p.nelements();
//
   Vector<Double> w = oldWorld.copy();
   if (nWorld > 0) {
      w.resize(0);
      w = world;
   } else {
      os << "Old world vector length = " << oldWorld.nelements() << LogIO::POST;
   }
   nWorld = w.nelements();
//
   if (nPixel != nWorld) {
      os << "Pixel and world vectors must be the same length" << LogIO::EXCEPTION;
   }
//
   TabularCoordinate tc(p, w, unit, name);
   itsCSys.replaceCoordinate(tc, ic);
} 





void coordsys::replaceCoordinate (const GlishRecord& cSys,
                                  Index in, Index out)
{
   LogIO os(LogOrigin("coordsys", "setTelescope", id(), WHERE));
//
   Record tmp;
   cSys.toRecord(tmp);
   CoordinateSystem* pCS = CoordinateSystem::restore(tmp, "");
   if (!pCS) {
     os << "The supplied CoordinateSYstem is illegal" << LogIO::EXCEPTION;
   }
//
   Int inIdx = in();
   if (inIdx<Int(0) || inIdx>Int(pCS->nCoordinates()-1)) {
      os << "Illegal index for input coordinate" << LogIO::EXCEPTION;
   }
   Int outIdx = out();
   if (outIdx<Int(0) || outIdx>Int(itsCSys.nCoordinates()-1)) {
      os << "Illegal index for output coordinate" << LogIO::EXCEPTION;
   }

// We could implement this case by building a new CS from scratch, but any
// axis reordering would be lost (unlikely to be common)

   if (pCS->coordinate(inIdx).nWorldAxes() != itsCSys.coordinate(outIdx).nWorldAxes()) {
      os << "Coordinates must have the same number of axes" << LogIO::EXCEPTION;
   }
//
   const Coordinate& newCoord = pCS->coordinate (inIdx);
   Bool ok = itsCSys.replaceCoordinate (newCoord, outIdx);
/*
   if (!ok) {
     os << LogIO::WARN << "Replacement incurred warning" << LogIO::POST;
   }
*/
   delete pCS;
   pCS = 0;
}



void coordsys::setTelescope (const String& telescope) 
{
   ObsInfo obsInfo = itsCSys.obsInfo();
   obsInfo.setTelescope(telescope);
   itsCSys.setObsInfo(obsInfo);
//
   MPosition pos;
   if (!MeasTable::Observatory(pos, telescope)) {
      LogIO os(LogOrigin("coordsys", "setTelescope", id(), WHERE));
      os << LogIO::WARN << "This telescope is not known to the AIPS++ system" << endl;
      os << "You can request that it be added" << LogIO::POST;
   }
}


void coordsys::setWorldAxisNames (const String& coordinateType, const Vector<String>& names) 
{
   LogIO os(LogOrigin("coordsys", "setWorldAxisNames", id(), WHERE));
//
   if (coordinateType.empty()) {
      if (!itsCSys.setWorldAxisNames(names)) {
         os << itsCSys.errorMessage() << LogIO::EXCEPTION;
      }
   } else {
      const Coordinate::Type type = stringToType (coordinateType);
      Int c = findCoordinate (type, True);
      Vector<Int> worldAxes = itsCSys.worldAxes(c);
      if (names.nelements() != worldAxes.nelements()) {
         os << "Supplied axis names vector must be of length " << worldAxes.nelements() << LogIO::EXCEPTION;
      }      
//
      Vector<String> namesAll(itsCSys.worldAxisNames().copy());
      for (uInt i=0; i<worldAxes.nelements(); i++) {
         namesAll(worldAxes(i)) = names(i);
      }
//
      if (!itsCSys.setWorldAxisNames(namesAll)) {
         os << itsCSys.errorMessage() << LogIO::EXCEPTION;
      }
   }
}

void coordsys::setWorldAxisUnits (const String& coordinateType, const Vector<String>& units,
                                  Bool overwrite, Index which)
{
   LogIO os(LogOrigin("coordsys", "setWorldAxisUnits", id(), WHERE));
//
   if (coordinateType.empty()) {
      if (!itsCSys.setWorldAxisUnits(units)) {
         os << itsCSys.errorMessage() << LogIO::EXCEPTION;
      }
   } else {
      const Coordinate::Type type = stringToType (coordinateType);
      Int c = which();
      if (c < 0) {
         c = findCoordinate (type, False);
      }
//
      Vector<Int> worldAxes = itsCSys.worldAxes(c);
      if (units.nelements() != worldAxes.nelements()) {
         os << "Supplied axis units vector must be of length " << worldAxes.nelements() << LogIO::EXCEPTION;
      }
//
      if (overwrite && type==Coordinate::LINEAR) {
         const LinearCoordinate& lc = itsCSys.linearCoordinate(c);
         LinearCoordinate lc2(lc);
         if (!lc2.overwriteWorldAxisUnits(units)) {
            os << lc2.errorMessage() << LogIO::EXCEPTION;
         }
         itsCSys.replaceCoordinate(lc2, uInt(c));
      } else if (overwrite && type==Coordinate::TABULAR) {
         const TabularCoordinate& tc = itsCSys.tabularCoordinate(c);
         TabularCoordinate tc2(tc); 
         if (!tc2.overwriteWorldAxisUnits(units)) {
            os << tc2.errorMessage() << LogIO::EXCEPTION;
         }
         itsCSys.replaceCoordinate(tc2, uInt(c));
      } else {
         Vector<String> unitsAll(itsCSys.worldAxisUnits().copy());
         for (uInt i=0; i<worldAxes.nelements(); i++) {
            unitsAll(worldAxes(i)) = units(i);
         }
//       
         if (!itsCSys.setWorldAxisUnits(unitsAll)) {
            os << itsCSys.errorMessage() << LogIO::EXCEPTION;
         }
      }
   }
}


Vector<String> coordsys::stokes() const
{
// Exception if type not found

   Int c = findCoordinate (Coordinate::STOKES, True);
//
   StokesCoordinate sc = itsCSys.stokesCoordinate(c);
   Vector<Int> stokes = sc.stokes();
//
   Vector<String> t(stokes.nelements());
   for (uInt i=0; i<t.nelements(); i++) {
      t(i) = Stokes::name(Stokes::StokesTypes(stokes(i)));
   }
//
   return t;
}



Vector<String> coordsys::summary (const String& dopplerType, Bool list) const
{
   MDoppler::Types velType;
   LogIO os(LogOrigin("coordsys", "summary", id(), WHERE));
   if (!MDoppler::getType(velType, dopplerType)) {
      os << LogIO::WARN << "Illegal doppler type, using RADIO" << LogIO::POST;
      velType = MDoppler::RADIO;
   }
//
   IPosition latticeShape, tileShape;
   Vector<String> messages;
   if (!list) {

// Only write to  local sink so we can fish the messages out

      LogFilter filter;
      LogSink sink(filter, False);
      LogIO osl(sink);
//
      messages = itsCSys.list(osl, velType, latticeShape, tileShape, True);
   } else {
      messages = itsCSys.list(os, velType, latticeShape, tileShape, False);
   }
   return messages;
}

String coordsys::telescope() const
{
   const ObsInfo& obsInfo = itsCSys.obsInfo();
   return obsInfo.telescope();
}



GlishRecord coordsys::toGlishRecord () const
{
   LogIO os(LogOrigin("coordsys", "toGlishRecord", id(), WHERE));
//
   GlishRecord gRec;
   Record rec;
   if (!itsCSys.save(rec,"CoordinateSystem")) {
      os << "Could not convert to record because " 
         << itsCSys.errorMessage() << LogIO::EXCEPTION;
   }

// Put it in a Glish Record

   gRec.fromRecord(rec.asRecord("CoordinateSystem"));
   gRec.add("parentName", itsParentImageName);
//
   return gRec;
}


Vector<Double> coordsys::toPixel (const GlishRecord& gRec) const
{
   LogIO os(LogOrigin("coordsys", "toPixel", id(), WHERE));
//
   Record rec;
   gRec.toRecord (rec);
   String dummyType;
   Int c = -1;
   Vector<Double> world;
   recordToWorldVector(world, dummyType, c, rec);
   trim(world, itsCSys.referenceValue());
//

   Vector<Double> pixel;
   if (!itsCSys.toPixel (pixel, world)) {
      os << itsCSys.errorMessage() << LogIO::EXCEPTION;
   }
//
   return pixel + 1.0;         // 1-rel
}



Array<Double> coordsys::toPixelMany (const Array<Double>& world) const
{
   LogIO os(LogOrigin("coordsys", "toPixelMany", id(), WHERE));
//
    AlwaysAssert(world.shape().nelements()==2, AipsError);
    Matrix<Double> pixels;
    Matrix<Double> worlds(world);
    Vector<Bool> failures;
    if (!itsCSys.toPixelMany(pixels, worlds, failures)) {
       LogIO os(LogOrigin("coordsys", "toPixelMany", id(), WHERE));
       os << itsCSys.errorMessage() << LogIO::EXCEPTION;
    }
    Array<Double> pixel(pixels.copy() + 1.0);     // Make 1-rel
//
    return pixel;
}



GlishRecord coordsys::toWorld (const Vector<Double>& pixel, 
                               const String& format) 
{
   Record rec = toWorldRecord (pixel, format);
   GlishRecord gRec;
   gRec.fromRecord(rec);
   return gRec;
}

Array<Double> coordsys::toWorldMany (const Array<Double>& pixel) const
{
   LogIO os(LogOrigin("coordsys", "toWorldMany", id(), WHERE));
//
    AlwaysAssert(pixel.shape().nelements()==2, AipsError);
    Matrix<Double> worlds;
    Matrix<Double> pixels(pixel);
    Vector<Bool> failures;
    if (!itsCSys.toWorldMany(worlds, pixels-1.0, failures)) {    // Make 0-rel
       LogIO os(LogOrigin("coordsys", "toWorldMany", id(), WHERE));
       os << itsCSys.errorMessage() << LogIO::EXCEPTION;
    }
    Array<Double> world(worlds.copy());
//
    return world;
}




GlishRecord coordsys::absoluteToRelative (const GlishRecord& absRec, Bool isWorld) 
{
   LogIO os(LogOrigin("coordsys", "absoluteToRelative", id(), WHERE));
//
   Bool absToRel = True;
   Record rec;
   absRec.toRecord (rec);
//
   return absRel (os, rec, isWorld, absToRel);
}



Array<Double> coordsys::absoluteToRelativeMany (const Array<Double>& valueIn,
                                                Bool isWorld)
{
   LogIO os(LogOrigin("coordsys", "absoluteToRelativeMany", id(), WHERE));
   AlwaysAssert(valueIn.shape().nelements()==2, AipsError);
   Double offset = 0.0;
   if (!isWorld) offset = -1.0;            // Make 0-rel
   Matrix<Double> values(valueIn + offset);
   if (isWorld) {
      itsCSys.makeWorldRelativeMany(values);
   } else {
      itsCSys.makePixelRelativeMany(values);
   }
   Array<Double> valueOut(values.copy());
   return valueOut;
}
   


GlishRecord coordsys::relativeToAbsolute (const GlishRecord& relRec, Bool isWorld) 
{
   LogIO os(LogOrigin("coordsys", "relativeToAbsolute", id(), WHERE));
//
   Bool absToRel = False;
   Record rec;
   relRec.toRecord (rec);
//
   return absRel (os, rec, isWorld, absToRel);
}

Array<Double> coordsys::relativeToAbsoluteMany (const Array<Double>& valueIn,
                                                Bool isWorld)
{
   LogIO os(LogOrigin("coordsys", "relativeToAbsoluteMany", id(), WHERE));
   AlwaysAssert(valueIn.shape().nelements()==2, AipsError);
   Matrix<Double> values(valueIn);
   Double offset = 0.0;
   if (isWorld) {
      itsCSys.makeWorldAbsoluteMany(values);
   } else {
      itsCSys.makePixelAbsoluteMany(values);   
      offset = 1.0;                       // Make 1-rel
   }
   Array<Double> valueOut(values.copy() + offset);
   return valueOut;
}

Vector<Double> coordsys::convert (const Vector<Double>& coordIn,
                                  const Vector<Bool>& absIn,       
                                  const Vector<String>& unitsIn,     
                                  const String& dopplerIn,
                                  const Vector<Bool>& absOut,     
                                  const Vector<String>& unitsOut, 
                                  const String& dopplerOut,
                                  const Vector<Int>& shape)
{
    LogIO os(LogOrigin("coordsys", "convert", id(), WHERE));
//
    MDoppler::Types dopIn, dopOut;
    if (!MDoppler::getType(dopIn, dopplerIn)) {
       os << "Illegal doppler" << LogIO::EXCEPTION;
    }
    if (!MDoppler::getType(dopOut, dopplerOut)) {
       os << "Illegal doppler" << LogIO::EXCEPTION;
    }
//
    if (shape.nelements() == itsCSys.nPixelAxes()) {
       IPosition p(shape);
       itsCSys.setWorldMixRanges(p);
    }
//
    Vector<Double> coordOut;
    if (!itsCSys.convert(coordOut, coordIn, absIn, unitsIn,
                        dopIn, absOut, unitsOut, dopOut,
                        -1.0, 1.0)) {
       LogIO os(LogOrigin("coordsys", "convert", id(), WHERE));
       os << itsCSys.errorMessage() << LogIO::EXCEPTION;
    }
    return coordOut;
}


Array<Double> coordsys::convertMany (const Array<Double>& coordIn,
                                   const Vector<Bool>& absIn,       
                                   const Vector<String>& unitsIn,     
                                   const String& dopplerIn,
                                   const Vector<Bool>& absOut,     
                                   const Vector<String>& unitsOut, 
                                   const String& dopplerOut,
                                   const Vector<Int>& shape)
{
    LogIO os(LogOrigin("coordsys", "convertMany", id(), WHERE));
//
    MDoppler::Types dopIn, dopOut;
    if (!MDoppler::getType(dopIn, dopplerIn)) {
       os << "Illegal doppler" << LogIO::EXCEPTION;
    }
    if (!MDoppler::getType(dopOut, dopplerOut)) {
       os << "Illegal doppler" << LogIO::EXCEPTION;
    }
//
    if (shape.nelements() == itsCSys.nPixelAxes()) {
       IPosition p(shape);
       itsCSys.setWorldMixRanges(p);
    }
//
    AlwaysAssert(coordIn.shape().nelements()==2, AipsError);
    Matrix<Double> coordsOut;
    Matrix<Double> coordsIn(coordIn);
    if (!itsCSys.convert(coordsOut, coordsIn, absIn, unitsIn,
                         dopIn, absOut, unitsOut, dopOut,
                        -1.0, 1.0)) {
       LogIO os(LogOrigin("coordsys", "convert", id(), WHERE));
       os << itsCSys.errorMessage() << LogIO::EXCEPTION;
    }
    Array<Double> coordOut(coordsOut.copy());
//
    return coordOut;
}

Vector<String> coordsys::worldAxisNames () const
{
   return itsCSys.worldAxisNames();
}


Vector<String> coordsys::worldAxisUnits () const
{
   return itsCSys.worldAxisUnits();
}





// Private methods


void coordsys::addCoordinate (CoordinateSystem& cSys, Bool direction, Bool spectral, 
                              const Vector<String>& stokes, Int linear, Bool tabular)
{
   if (direction) CoordinateUtil::addDirAxes(cSys);
//
   if (stokes.nelements()>0) {
      Vector<Int> which(stokes.nelements());
      for (uInt i=0; i<stokes.nelements(); i++) {      
         String tmp = upcase(stokes(i));
         which(i) = Stokes::type(tmp);
      }
      StokesCoordinate sc(which);
      cSys.addCoordinate(sc);
   }
//
   if (spectral) CoordinateUtil::addFreqAxis(cSys);
//
   if (linear > 0) {
      Vector<String> names(linear);
      Vector<String> units(linear);
      Vector<Double> refVal(linear);
      Vector<Double> refPix(linear);
      Vector<Double> incr(linear);
      for (Int i=0; i<linear; i++) {
        ostringstream oss;
        oss << i+1;
        names(i) = "LinAxis" + String(oss);
        units(i) = "km";
        refVal(i) = 0.0;
        refPix(i) = 0.0;
        incr(i) = 1.0;
      }
//
      Matrix<Double> pc(linear,linear);
      pc.set(0.0);
      pc.diagonal() = 1.0;       
      LinearCoordinate lc(names, units, refVal, incr, pc, refPix);
      cSys.addCoordinate(lc);
   }
// 
   if (tabular) {
      Double refVal = 0.0;
      Double refPix = 0.0;
      Double inc = 1.0;
      String unit("km");
      String name("TabAxis1");
      TabularCoordinate tc(refVal, inc, refPix, unit, name);
      cSys.addCoordinate(tc);
   }
}

void coordsys::copyWorldAxes (Vector<Double>& out, const Vector<Double>& in, Int c) const
{
   Vector<Int> worldAxes = itsCSys.worldAxes(c);
   for (uInt i=0; i<worldAxes.nelements(); i++) {
      out(worldAxes(i)) = in(i);
   }
}


GlishRecord coordsys::absRel (LogIO& os, const RecordInterface& recIn, Bool isWorld, Bool absToRel) 
{
   Record rec = absRelRecord (os, recIn, isWorld, absToRel);
   GlishRecord gRecOut;
   gRecOut.fromRecord(rec);
   return gRecOut;
}
   
Record coordsys::absRelRecord (LogIO& os, const RecordInterface& recIn, Bool isWorld, Bool absToRel) 
{
   Record recIn2;
   Vector<Double> value, value2;
   if (isWorld) {
      String format;
      Int c = -1;
      recordToWorldVector (value, format, c, recIn);
      Bool isAbsolute = False;
      if (absToRel) {
         trim(value, itsCSys.referenceValue());
         itsCSys.makeWorldRelative (value);
         isAbsolute = False;
      } else {
         Vector<Double> zero(itsCSys.nWorldAxes(),0.0);
         trim(value, zero);
         itsCSys.makeWorldAbsolute (value);
         isAbsolute = True;
      }
//
      Bool showAsAbsolute = isAbsolute;
      recIn2 = worldVectorToRecord (value, c, format, isAbsolute, showAsAbsolute);
   } else {
      if (recIn.isDefined("numeric")) {
         value = recIn.asArrayDouble("numeric");
      } else {
         os << "Input does not appear to be a pixel coordinate" << LogIO::EXCEPTION;
      }
      if (absToRel) {
         value -= 1.0;                      // make 0-rel
         trim(value, itsCSys.referencePixel());
         itsCSys.makePixelRelative (value);
      } else {
         Vector<Double> zero(itsCSys.nPixelAxes(),0.0);
         trim(value, zero);
         itsCSys.makePixelAbsolute (value);
         value += 1.0;                      // make 1-rel
      }
      recIn2.define("numeric", value);
   }
//
   return recIn2;
}
   


Int coordsys::findCoordinate (Coordinate::Type type, Bool warn) const
{
   LogIO os(LogOrigin("coordsys", "findCoordinate()", WHERE));
   Int afterCoord = -1;
   Int c = itsCSys.findCoordinate(type, afterCoord);
   if (c<0) {
      os << "No coordinate of type " << Coordinate::typeToString(type)
         << " in this CoordinateSystem" << LogIO::EXCEPTION;
   }
//
   afterCoord = c;
   Int c2 = itsCSys.findCoordinate(type, afterCoord);
   if (warn && c2 >= 0) {
      os << LogIO::WARN 
         << "This CoordinateSystem has more than one coordinate of type "
         << Coordinate::typeToString(type) << LogIO::POST;
   }
   return c;
}



Vector<Double> coordsys::measuresToWorldVector (const RecordInterface& rec) const
//
// Units are converted to those of the CoordinateSystem
// The record may contain one or more measures
// Missing values are given the referenceValue
//
{ 
   LogIO os(LogOrigin("coordsys", "measuresToVector(...)", id(), WHERE));

// The record will have fields from 'direction', 'spectral', 'stokes',
// 'linear', 'tabular'

   Int ic, afterCoord;
   Vector<Double> world(itsCSys.referenceValue().copy());
   String error;
//
   if (rec.isDefined("direction")) {
      afterCoord = -1;
      ic = itsCSys.findCoordinate(Coordinate::DIRECTION, afterCoord);
      if (ic >=0) {
         Vector<Int> worldAxes = itsCSys.worldAxes(ic);
         const RecordInterface& rec2 = rec.asRecord("direction");
         MeasureHolder h;
         if (!h.fromRecord(error, rec2)) {
            os << error << LogIO::EXCEPTION;
         }
//
         MDirection d = h.asMDirection();
         const DirectionCoordinate dc = itsCSys.directionCoordinate (ic);
         Vector<String> units = dc.worldAxisUnits();
         const MVDirection mvd = d.getValue();
         Quantum<Double> lon = mvd.getLong(Unit(units(0)));
         Quantum<Double> lat = mvd.getLat(Unit(units(1)));

// Fill output 

         world(worldAxes(0)) = lon.getValue();
         world(worldAxes(1)) = lat.getValue();
      } else {
         os << LogIO::WARN << "There is no direction coordinate in this Coordinate System" << endl;
         os << LogIO::WARN << "However, the world record you are converting contains " << endl;
         os << LogIO::WARN << "a direction field.  " << LogIO::POST;
      }
   }
//
   if (rec.isDefined("spectral")) {
      afterCoord = -1;
      ic = itsCSys.findCoordinate(Coordinate::SPECTRAL, afterCoord);
      if (ic >=0) {
         Vector<Int> worldAxes = itsCSys.worldAxes(ic);
         const RecordInterface& rec2 = rec.asRecord("spectral");
         if (rec2.isDefined("frequency")) {
            const RecordInterface& rec3 = rec2.asRecord("frequency");
            MeasureHolder h;
            if (!h.fromRecord(error, rec3)) {
              os << error << LogIO::EXCEPTION;
            }
//
            MFrequency f = h.asMFrequency();
            const SpectralCoordinate sc = itsCSys.spectralCoordinate (ic);         
            Vector<String> units = sc.worldAxisUnits();
            world(worldAxes(0)) = f.get(units(0)).getValue();
         } else {
            os << "This spectral record does not contain a frequency field" << LogIO::EXCEPTION;
         }
      } else {
         os << LogIO::WARN << "There is no spectral coordinate in this Coordinate System" << endl;
         os << LogIO::WARN << "However, the world record you are converting contains " << endl;
         os << LogIO::WARN << "a spectral field.  " << LogIO::POST;
      }
   }
//
   if (rec.isDefined("stokes")) {
      afterCoord = -1;
      ic = itsCSys.findCoordinate(Coordinate::STOKES, afterCoord);
      if (ic >=0) {
         Vector<Int> worldAxes = itsCSys.worldAxes(ic);
         Stokes::StokesTypes type = Stokes::type(rec.asString("stokes"));
         const StokesCoordinate sc = itsCSys.stokesCoordinate (ic);         
//
         Int pix;
         Vector<Double> p(1), w(1);
         if (!sc.toPixel (pix, type)) {
            os << sc.errorMessage() << LogIO::EXCEPTION;
         } else {
            p(0) = pix;            
            if (!sc.toWorld (w, p)) {
               os << sc.errorMessage() << LogIO::EXCEPTION;
            }
         }
//
         world(worldAxes(0)) = w(0);
      } else {
         os << LogIO::WARN << "There is no stokes coordinate in this Coordinate System" << endl;
         os << LogIO::WARN << "However, the world record you are converting contains " << endl;
         os << LogIO::WARN << "a stokes field.  " << LogIO::POST;
      }
   }
//
   if (rec.isDefined("linear")) {
      afterCoord = -1;
      ic = itsCSys.findCoordinate(Coordinate::LINEAR, afterCoord);
      if (ic >=0) {
         Vector<Int> worldAxes = itsCSys.worldAxes(ic);
         const LinearCoordinate lc = itsCSys.linearCoordinate (ic); 
         Vector<Double> w = quantumVectorRecordToVectorDouble (rec.asRecord("linear"),
                                                               lc.worldAxisUnits());
//
         for (uInt i=0; i<w.nelements(); i++) {
            world(worldAxes(i)) = w(i);
         }
      } else {
         os << LogIO::WARN << "There is no linear coordinate in this Coordinate System" << endl;
         os << LogIO::WARN << "However, the world record you are converting contains " << endl;
         os << LogIO::WARN << "a linear field.  " << LogIO::POST;
      }
   }
//
   if (rec.isDefined("tabular")) {
      afterCoord = -1;
      ic = itsCSys.findCoordinate(Coordinate::TABULAR, afterCoord);
      if (ic >=0) {
         Vector<Int> worldAxes = itsCSys.worldAxes(ic);
         QuantumHolder h;
         String error;
         if (!h.fromRecord(error, rec.asRecord("tabular"))) {
            os << error << LogIO::EXCEPTION;
         }
//
         const TabularCoordinate tc = itsCSys.tabularCoordinate (ic);         
         String units = tc.worldAxisUnits()(0);
         Quantum<Double> q = h.asQuantumDouble();
//
         world(worldAxes(0)) = q.getValue(Unit(units));
      } else {
         os << LogIO::WARN << "There is no tabular coordinate in this Coordinate System" << endl;
         os << LogIO::WARN << "However, the world record you are converting contains " << endl;
         os << LogIO::WARN << "a tabular field.  " << LogIO::POST;
      }
   }
//
   return world;
} 


void coordsys::recordToWorldVector (Vector<Double>& out, String& type, 
                                    Int c, const RecordInterface& rec) const
//
// The Record may hold any combination of "numeric", "quantity", "measure" and
// "string".  They are all representations of the same thing.  So we only
// need convert from one type to world double in native units
//
{
   LogIO os(LogOrigin("coordsys", "recordToWorldVector(...)", id(), WHERE));
//
   Bool done = False;
   if (rec.isDefined("numeric")) {
      out.resize(0);
      out = rec.asArrayDouble("numeric");     // Assumed native units
      type += "n";
      done = True;
   }
//
   Vector<String> units;
   if (c < 0) {
      units = itsCSys.worldAxisUnits();
   } else {
      units = itsCSys.coordinate(c).worldAxisUnits();
   }
//
   if (rec.isDefined("quantity")) {
      if (!done) {
         const RecordInterface& recQ = rec.asRecord("quantity");
         out.resize(0);
         out = quantumVectorRecordToVectorDouble (recQ, units);
         done = True;
      }
      type += "q";
   }
//
   if (rec.isDefined("measure")) {
      if (!done) {
         const RecordInterface& recM = rec.asRecord("measure");
         Vector<Double> tmp = measuresToWorldVector (recM);
         if (c < 0) {
            out.resize(0);
            out = tmp;
         } else {
            Vector<Int> worldAxes = itsCSys.worldAxes(c);            
            out.resize(worldAxes.nelements());
            for (uInt i=0; i<worldAxes.nelements(); i++) {
               out(i) = tmp(worldAxes(i));
            }            
         }
         done = True;
      }
      type += "m";
   }
//
   if (rec.isDefined("string")) {
      if (!done) {
         Vector<String> world = rec.asArrayString("string");
         out.resize(0);
         out = stringToWorldVector (os, world, units);
         done = True;
      }
      type += "s";
   }
//
   if (!done) {
      os << "Unrecognized format for world coordinate " << LogIO::EXCEPTION;
   }
}

Record coordsys::toWorldRecord (const Vector<Double>& pixel, 
                                const String& format) 
{
   LogIO os(LogOrigin("coordsys", "toWorld", id(), WHERE));
//
   Vector<Double> pixel2 = pixel.copy();
   if (pixel2.nelements()>0) pixel2 -= 1.0;        // 0-rel
   trim(pixel2, itsCSys.referencePixel());

// Convert to world

   Vector<Double> world;
   Record rec;
   if (itsCSys.toWorld (world, pixel2)) {
      Bool isAbsolute = True;
      Bool showAsAbsolute = True;
      Int c = -1;
      rec = worldVectorToRecord (world, c, format, isAbsolute, showAsAbsolute);
   } else {
      os << itsCSys.errorMessage() << LogIO::EXCEPTION;
   }
   return rec;
}


Record coordsys::worldVectorToRecord (const Vector<Double>& world, 
                                      Int c, const String& format, 
                                      Bool isAbsolute, Bool showAsAbsolute)
//
// World vector must be in the native units of cSys
// c = -1 means world must be length cSys.nWorldAxes
// c > 0 means world must be length cSys.coordinate(c).nWorldAxes()
// format from 'n,q,s,m'
//
{
   LogIO os(LogOrigin("coordsys", "worldVectorToRecord", id(), WHERE));
   String ct= upcase(format);
   Vector<String> units;
   if (c < 0) {
      units = itsCSys.worldAxisUnits();
   } else {
      units = itsCSys.coordinate(c).worldAxisUnits();
   }
   AlwaysAssert(world.nelements()==units.nelements(),AipsError);
//
   Record rec;
   if (ct.contains(String("N"))) {
      rec.define("numeric", world);
   }
//
   if (ct.contains(String("Q"))) {
      String error;
      Record recQ1, recQ2;
//
      for (uInt i=0; i<world.nelements(); i++) {
         Quantum<Double> worldQ(world(i), Unit(units(i)));
         recQ1 = quantumToRecord (os, worldQ);
         recQ2.defineRecord(i, recQ1);
      }
      rec.defineRecord("quantity", recQ2);
   }
//
   if (ct.contains(String("S"))) {
      Vector<Int> worldAxes;
      if (c <0) {
         worldAxes.resize(world.nelements());
         indgen(worldAxes);
      } else {
         worldAxes = itsCSys.worldAxes(c);
      }
//
      Coordinate::formatType fType = Coordinate::SCIENTIFIC;
      Int prec = 8;
      String u;
      Int coord, axisInCoord;
      Vector<String> fs(world.nelements());
      for (uInt i=0; i<world.nelements(); i++) {
         itsCSys.findWorldAxis(coord, axisInCoord, i);
         if (itsCSys.type(coord)==Coordinate::DIRECTION ||
             itsCSys.type(coord)==Coordinate::STOKES) {
            fType = Coordinate::DEFAULT;
         } else {
            fType = Coordinate::SCIENTIFIC;
         }
//
         u = "";
         fs(i) = itsCSys.format (u, fType, world(i), worldAxes(i), 
                                 isAbsolute, showAsAbsolute, prec);
         if ((u != String("")) && (u != String(" "))) {
            fs(i) += String(" ") + u;
         }
      }

      rec.define("string", fs);
   }
//
   if (ct.contains(String("M"))) {
      Record recM = worldVectorToMeasures(world, c, isAbsolute);
      rec.defineRecord("measure", recM);
   }
//
   return rec;
}




Vector<Double> coordsys::stringToWorldVector (LogIO& os, 
                                              const Vector<String>& world,
                                              const Vector<String>& units) const
{ 
   Vector<Double> world2 = itsCSys.referenceValue();
   Int coordinate, axisInCoordinate;
   const uInt nIn = world.nelements();
   for (uInt i=0; i<nIn; i++) {
      itsCSys.findWorldAxis(coordinate, axisInCoordinate, i);
      Coordinate::Type type = itsCSys.type(coordinate);
//
      if (type==Coordinate::DIRECTION) {
         Quantum<Double> val;
         if (!MVAngle::read(val, world(i))) {
           os << "Failed to convert string formatted world "
              << world(i) << " to double"  << LogIO::EXCEPTION;
         }
         world2(i) = val.getValue(Unit(units(i)));
      } else if (type==Coordinate::STOKES) {
         Stokes::StokesTypes type2 = Stokes::type(world(i));
         world2(i) = StokesCoordinate::toWorld(type2);
      } else {
         Quantum<Double> val;
         if (!Quantum<Double>::read(val, world(i))) {
           os << "Failed to convert string formatted world "
              << world(i) << " to double"  << LogIO::EXCEPTION;
         }
         world2(i) = val.getValue(Unit(units(i)));
      }
   }
//
   return world2;
} 



Record coordsys::worldVectorToMeasures(const Vector<Double>& world, 
                                       Int c, Bool abs) const
{ 
   LogIO os(LogOrigin("coordsys", "worldVectorToMeasures(...)", id(), WHERE));
//
   uInt directionCount, spectralCount, linearCount, stokesCount, tabularCount;
   directionCount = spectralCount = linearCount = stokesCount = tabularCount = 0;

// Loop over desired Coordinates 

   Record rec;             
   String error;
   uInt s,  e;
   if (c < 0) {
      AlwaysAssert(world.nelements()==itsCSys.nWorldAxes(), AipsError);
      s = 0;
      e = itsCSys.nCoordinates();
   } else {
      AlwaysAssert(world.nelements()==itsCSys.coordinate(c).nWorldAxes(), AipsError);
      s = c;
      e = c+1;
   }
//
   for (uInt i=s; i<e; i++) {

// Find the world axes in the CoordinateSystem that this coordinate belongs to

     const Vector<Int>& worldAxes = itsCSys.worldAxes(i);
     const uInt nWorldAxes = worldAxes.nelements();
     Vector<Double> world2(nWorldAxes);
     const Coordinate& coord = itsCSys.coordinate(i);
     Vector<String> units = coord.worldAxisUnits();           
     Bool none = True;

// Fill in missing world axes if all coordinates specified

     if (c < 0) {
        for (uInt j=0; j<nWorldAxes; j++) {
           if (worldAxes(j)<0) {
              world2(j) = coord.referenceValue()(j);
           } else {
              world2(j) = world(worldAxes(j));
              none = False;
           }
        }
     } else {
        world2 = world;
        none = False;
     }
//
     if (itsCSys.type(i) == Coordinate::LINEAR ||
         itsCSys.type(i) == Coordinate::TABULAR) {
        if (!none) {
           Record linRec1, linRec2;
           for (uInt k=0; k<world2.nelements(); k++) {
              Quantum<Double> value(world2(k), units(k));
              linRec1 = quantumToRecord (os, value);
              linRec2.defineRecord(k, linRec1);
           }
//
           if (itsCSys.type(i) == Coordinate::LINEAR) {
              rec.defineRecord("linear", linRec2);
           } else if (itsCSys.type(i) == Coordinate::TABULAR) {
              rec.defineRecord("tabular", linRec2);
           }
        }
//
       if (itsCSys.type(i) == Coordinate::LINEAR) linearCount++;
       if (itsCSys.type(i) == Coordinate::TABULAR) tabularCount++;
     } else if (itsCSys.type(i) == Coordinate::DIRECTION) {
        if (!abs) {
           os << "It is not possible to have a relative MDirection measure" << LogIO::EXCEPTION;
        }
        AlwaysAssert(worldAxes.nelements()==2,AipsError);
//
        if (!none) {

// Make an MDirection and stick in record

           Quantum<Double> t1(world2(0), units(0));
           Quantum<Double> t2(world2(1), units(1));
           MDirection direction(t1, t2, itsCSys.directionCoordinate(i).directionType());
//
           MeasureHolder h(direction);
           Record dirRec;
           if (!h.toRecord(error, dirRec)) {
              os << error << LogIO::EXCEPTION;
           } else {
              rec.defineRecord("direction", dirRec);       
           }            
        }
        directionCount++;
     } else if (itsCSys.type(i) == Coordinate::SPECTRAL) {
        if (!abs) {
           os << "It is not possible to have a relative MFrequency measure" << LogIO::EXCEPTION;
        }
        AlwaysAssert(worldAxes.nelements()==1,AipsError);
//
        if (!none) {

// Make an MFrequency and stick in record

           Record specRec, specRec1;
           Quantum<Double> t1(world2(0), units(0));
           const SpectralCoordinate& sc0 = itsCSys.spectralCoordinate(i);
           MFrequency frequency(t1, sc0.frequencySystem());
//
           MeasureHolder h(frequency);
           if (!h.toRecord(error, specRec1)) {
              os << error << LogIO::EXCEPTION;
           } else {
             specRec.defineRecord("frequency", specRec1);
           }
//
           SpectralCoordinate sc(sc0);

// Do velocity conversions and stick in MDOppler
// Radio

           sc.setVelocity (String("km/s"), MDoppler::RADIO);
           Quantum<Double> velocity;
           if (!sc.frequencyToVelocity(velocity, frequency)) {
              os << sc.errorMessage() << LogIO::EXCEPTION;
           } else {
              MDoppler v(velocity, MDoppler::RADIO);
              MeasureHolder h(v);
              if (!h.toRecord(error, specRec1)) {
                 os << error << LogIO::EXCEPTION;
              } else {
                 specRec.defineRecord("radiovelocity", specRec1);
              }
           }

// Optical

           sc.setVelocity (String("km/s"), MDoppler::OPTICAL);
           if (!sc.frequencyToVelocity(velocity, frequency)) {
              os << sc.errorMessage() << LogIO::EXCEPTION;
           } else {
              MDoppler v(velocity, MDoppler::OPTICAL);
              MeasureHolder h(v);
              if (!h.toRecord(error, specRec1)) {
                 os << error << LogIO::EXCEPTION;
              } else {
                 specRec.defineRecord("opticalvelocity", specRec1);
              }
           }

// beta (relativistic/true)

           sc.setVelocity (String("km/s"), MDoppler::BETA);
           if (!sc.frequencyToVelocity(velocity, frequency)) {
              os << sc.errorMessage() << LogIO::EXCEPTION;
           } else {
              MDoppler v(velocity, MDoppler::BETA);
              MeasureHolder h(v);
              if (!h.toRecord(error, specRec1)) {
                 os << error << LogIO::EXCEPTION;
              } else {
                 specRec.defineRecord("betavelocity", specRec1);
              }
           }

// Fill spectral record

           rec.defineRecord("spectral", specRec);
        }
        spectralCount++;
     } else if (itsCSys.type(i) == Coordinate::STOKES) {
        if (!abs) {
           os << "It makes no sense to have a relative Stokes measure" << LogIO::EXCEPTION;
        }
        AlwaysAssert(worldAxes.nelements()==1,AipsError);
//
        if (!none) {
          const StokesCoordinate& coord0 = itsCSys.stokesCoordinate(i);
          StokesCoordinate coord(coord0);             // non-const
          String u;
          String s = coord.format(u, Coordinate::DEFAULT, world2(0),
                                  0, True, True, -1);
          rec.define("stokes", s);
       }
       stokesCount++;
     } else {
        os << "Cannot handle Coordinates of type " << itsCSys.showType(i) << LogIO::EXCEPTION;
     }
   }
//  
  if (directionCount > 1) {
     os << LogIO::WARN << "There was more than one DirectionCoordinate in the " << LogIO::POST;
     os << LogIO::WARN << "CoordinateSystem.  Only the last one is returned" << LogIO::POST;
  }
  if (spectralCount > 1) {
     os << LogIO::WARN << "There was more than one SpectralCoordinate in the " << LogIO::POST;
     os << LogIO::WARN << "CoordinateSystem.  Only the last one is returned" << LogIO::POST;
  }
  if (stokesCount > 1) {
     os << LogIO::WARN << "There was more than one StokesCoordinate in the " << LogIO::POST;
     os << LogIO::WARN << "CoordinateSystem.  Only the last one is returned" << LogIO::POST;
  }
  if (linearCount > 1) {
     os << LogIO::WARN << "There was more than one LinearCoordinate in the " << LogIO::POST;
     os << LogIO::WARN << "CoordinateSystem.  Only the last one is returned" << LogIO::POST;
  }             
  if (tabularCount > 1) {
     os << LogIO::WARN << "There was more than one TabularCoordinate in the " << LogIO::POST;
     os << LogIO::WARN << "CoordinateSystem.  Only the last one is returned" << LogIO::POST;
  }             
//         
  return rec;
} 


Vector<Double> coordsys::quantumVectorRecordToVectorDouble (const RecordInterface& recQ,
                                                            const Vector<String>& units) const
//
// Convert vector to world double in native units
//
{
   Record recQ2;
   QuantumHolder h;
   String error;
   Quantum<Double> q;
   const uInt n = recQ.nfields();
   Vector<Double> worldIn(n);
//
   for (uInt i=0; i<n; i++) {
      recQ2 = recQ.asRecord(i);
      if (!h.fromRecord(error, recQ2)) {
         LogIO os(LogOrigin("coordsys", "quantumVectorRecordToVectorDouble", 
                  id(), WHERE));
         os << error << LogIO::EXCEPTION;
      }
      q = h.asQuantumDouble();         
      worldIn(i) = q.getValue(Unit(units(i)));
   }
   return worldIn;
}




Coordinate::Type coordsys::stringToType(const String& typeIn) const
//
// Convert the users string to a Coordinate type.
// We don't allow Tabular coordinates as the user
// does not interact with them directly.
//
{
   String ct= upcase(typeIn);
   String ct1(ct.at(0,1));
   String ct2(ct.at(0,2));
//
   if (ct1==String("L")) return Coordinate::LINEAR;
   if (ct1==String("D")) return Coordinate::DIRECTION;
   if (ct1==String("T")) return Coordinate::TABULAR;
//
   if (ct2==String("ST")) return Coordinate::STOKES;
   if (ct2==String("SP")) return Coordinate::SPECTRAL;
//
   LogIO os(LogOrigin("coordsys", "stringToType", id(), WHERE));
   os << "Unknown coordinate type" << LogIO::EXCEPTION;
//
   Coordinate::Type t(Coordinate::LINEAR);
   return t;
}


void coordsys::setDirectionCode (const String& code, Bool adjust)
{
   
// Exception if type not found

   Int ic = findCoordinate (Coordinate::DIRECTION, True);
//
   LogIO os(LogOrigin("coordsys", "setDirectionCode", id(), WHERE));

// Convert type

   String code2 = code;
   MDirection::Types typeTo;
   code2.upcase();
   if (!MDirection::getType(typeTo, code2)) {
      os << "Invalid direction code '" << code << "' given. Allowed are : " << endl;
      for (uInt i=0; i<MDirection::N_Types; i++) os << "  " << MDirection::showType(i) << endl;
      os << LogIO::EXCEPTION;
   }

// Bug out if nothing to do

   DirectionCoordinate dirCoordFrom(itsCSys.directionCoordinate(ic));      // Copy
   if (dirCoordFrom.directionType() == typeTo) return;
   Vector<String> unitsFrom = dirCoordFrom.worldAxisUnits();
//
   Vector<String> radUnits(2);
   radUnits = String("rad");
   if (!dirCoordFrom.setWorldAxisUnits(radUnits)) {
      os << "Failed to set radian units for DirectionCoordinate" << LogIO::EXCEPTION;
   }

// Create output DirectionCoordinate

   Vector<Double> refValFrom = dirCoordFrom.referenceValue();
   Vector<Double> refPixFrom = dirCoordFrom.referencePixel();
   Vector<Double> incrFrom = dirCoordFrom.increment();
   DirectionCoordinate dirCoordTo (typeTo, dirCoordFrom.projection(),
                                   refValFrom(0), refValFrom(1),
                                   incrFrom(0), incrFrom(1),
                                   dirCoordFrom.linearTransform(),
                                   refPixFrom(0), refPixFrom(1));
//
   if (adjust) {
      MDirection::Convert machine;
      const ObsInfo& obsInfo = itsCSys.obsInfo();
      Bool madeMachine =
         CoordinateUtil::makeDirectionMachine(os, machine, dirCoordTo,
                                              dirCoordFrom, obsInfo, obsInfo);
//      cerr << "made DirectionMachine = " << madeMachine << endl;
//
      if (madeMachine) {
         MVDirection mvdTo, mvdFrom;
         Bool ok = dirCoordFrom.toWorld (mvdFrom, refPixFrom);
         if (ok) {
            mvdTo = machine(mvdFrom).getValue();
            Vector<Double> referenceValueTo(2);
            referenceValueTo(0) = mvdTo.getLong();
            referenceValueTo(1) = mvdTo.getLat();
            if (!dirCoordTo.setReferenceValue(referenceValueTo)) {
               os << dirCoordTo.errorMessage() << LogIO::EXCEPTION;
            }
            if (!dirCoordTo.setWorldAxisUnits(unitsFrom)) {
               os << dirCoordTo.errorMessage() << LogIO::EXCEPTION;
            }
         }
      }
   }
//
   itsCSys.replaceCoordinate(dirCoordTo, ic);
} 



void coordsys::setSpectralCode (const String& code, Bool adjust)
{
// Exception if type not found

   Int ic = findCoordinate (Coordinate::SPECTRAL, True);

// Convert type String to enum

   LogIO os(LogOrigin("coordsys", "setSpectralCode", id(), WHERE));
   MFrequency::Types typeTo;
   String code2 = code;
   code2.upcase();
   if (!MFrequency::getType(typeTo, code2)) {
      os << "Invalid frequency code '" << code << "' given. Allowed are : " << endl;
      for (uInt i=0; i<MFrequency::N_Types; i++) os << "  " << MFrequency::showType(i) << endl;
      os << LogIO::EXCEPTION;
   } 

// Get Spectral Coordinate

   SpectralCoordinate specCoordTo(itsCSys.spectralCoordinate(ic));  // Copy

// Bug out if nothing to do

   if (specCoordTo.frequencySystem() == typeTo) return;

// Set new value

   specCoordTo.setFrequencySystem(typeTo);

// Now adjust reference value if adjust is required

   if (adjust) {

// Generate to/from Coordinate and CoordinateSystem and set new type 

      const CoordinateSystem& cSysFrom = itsCSys;
      const SpectralCoordinate specCoordFrom(cSysFrom.spectralCoordinate(ic));  
//
      CoordinateSystem cSysTo(cSysFrom);
      cSysTo.replaceCoordinate(specCoordTo, ic);
//
      MFrequency::Convert machine;
      CoordinateUtil::makeFrequencyMachine(os, machine, ic, ic,
                                              cSysTo, cSysFrom);
//
      if (!machine.isNOP()) {
         MVFrequency mvfTo, mvfFrom;
         Vector<Double> refPixFrom = specCoordFrom.referencePixel();
         Bool ok = specCoordFrom.toWorld (mvfFrom, refPixFrom(0));
         if (ok) {
            mvfTo = machine(mvfFrom).getValue();
            Vector<Double> refValTo = specCoordTo.referenceValue();
            refValTo(0) = mvfTo.getValue();
//
            Vector<String> unitsTo(1);
            unitsTo = String("Hz");
            if (!specCoordTo.setWorldAxisUnits(unitsTo)) {
               os << specCoordTo.errorMessage() << LogIO::EXCEPTION;
            }
            if (!specCoordTo.setReferenceValue(refValTo)) {
               os << specCoordTo.errorMessage() << LogIO::EXCEPTION;
            }
            if (!specCoordTo.setWorldAxisUnits(specCoordFrom.worldAxisUnits())) {
               os << specCoordTo.errorMessage() << LogIO::EXCEPTION;
            }
         }
      }
   }

// Replace coordinate in CoordinateSystem

   itsCSys.replaceCoordinate(specCoordTo, ic);
} 


void coordsys::trim (Vector<Double>& inout, 
                     const Vector<Double>& replace) const
{
   const Int nIn = inout.nelements();
   const Int nOut = replace.nelements();
   Vector<Double> out(nOut);
   for (Int i=0; i<nOut; i++) {
      if (i > nIn-1) {
         out(i) = replace(i);
      } else {
         out(i) = inout(i);
      }
   }
   inout.resize(nOut);
   inout = out;
}


Record coordsys::quantumToRecord (LogIO& os, const Quantum<Double>& value) const
{
   Record rec;
   QuantumHolder h(value);
   String error;
   if (!h.toRecord(error, rec)) os << error << LogIO::EXCEPTION;
   return rec;
}


// Public methods needed to run DO


String coordsys::className() const
{
    return "coordsys";
}

Vector<String> coordsys::methods() const
{
    Vector<String> method(NUM_METHODS);
    method(ADDCOORDINATE) = "addcoordinate";
    method(AXESMAP) = "axesmap";
    method(AXISCOORDINATETYPES) = "axiscoordinatetypes";
    method(COORDINATETYPE) = "coordinatetype";    
    method(CONVERSIONTYPE) = "conversiontype";    
    method(CONVERT) = "convert";    
    method(CONVERTMANY) = "convertmany";    
    method(EPOCH) = "epoch";
    method(FINDCOORDINATE) = "findcoordinate";
    method(FINDAXIS) = "findaxis";
    method(FREQUENCYTOFREQUENCY) = "frequencytofrequency";
    method(FREQUENCYTOVELOCITY) = "frequencytovelocity";
    method(FROMRECORD) = "fromrecord";
    method(INCREMENT) = "increment";
    method(LINEARTRANSFORM) = "lineartransform";
    method(NAMES) = "names";
    method(NAXES) = "naxes";
    method(NCOORDINATES) = "ncoordinates";
    method(OBSERVER) = "observer";
    method(PROJECTION) = "projection";
    method(PARENTNAME) = "parentname";
    method(REFERENCECODE) = "referencecode";
    method(REFERENCEPIXEL) = "referencepixel";
    method(REFERENCEVALUE) = "referencevalue";
    method(REORDER) = "reorder";
    method(REPLACECOORDINATE) = "replace";
    method(RESTFREQUENCY) = "restfrequency";
    method(SETCONVERSIONTYPE) = "setconversiontype";
    method(SETDIRECTION) = "setdirection";
    method(SETEPOCH) = "setepoch";
    method(SETINCREMENT) = "setincrement";
    method(SETLINEARTRANSFORM) = "setlineartransform";
    method(SETNAMES) = "setnames";
    method(SETOBSERVER) = "setobserver";
    method(SETPROJECTION) = "setprojection";
    method(SETREFERENCECODE) = "setreferencecode";
    method(SETPARENTNAME) = "setparentname";
    method(SETREFERENCEPIXEL) = "setreferencepixel";
    method(SETREFERENCEVALUE) = "setreferencevalue";
    method(SETRESTFREQUENCY) = "setrestfrequency";
    method(SETSTOKES) = "setstokes";    
    method(SETSPECTRAL) = "setspectral";    
    method(SETTABULAR) = "settabular";    
    method(SETTELESCOPE) = "settelescope";
    method(SETUNITS) = "setunits";
    method(STOKES) = "stokes";    
    method(SUMMARY) = "summary";
    method(TELESCOPE) = "telescope";
    method(TOABS) = "toabs";
    method(TOABSMANY) = "toabsmany";
    method(TOPIXEL) = "topixel";
    method(TOPIXELMANY) = "topixelmany";
    method(TORECORD) = "torecord";
    method(TOREL) = "torel";
    method(TORELMANY) = "torelmany";
    method(TOWORLD) = "toworld";
    method(TOWORLDMANY) = "toworldmany";
    method(UNITS) = "units";
    method(VELOCITYTOFREQUENCY) = "velocitytofrequency";
//
    return method;

}

Vector<String> coordsys::noTraceMethods() const
{
    return methods();
}

MethodResult coordsys::runMethod(uInt which, 
                                 ParameterSet &inputRecord,
                                 Bool runMethod)
{
    static String returnvalString = "returnval";
//
    switch (which) {
    case TORECORD:
	{
            Parameter<GlishRecord> returnval(inputRecord, "returnval",
                                             ParameterSet::Out);
	    if (runMethod) {
               returnval() = toGlishRecord();
	    }
	}
    break;
    case SETPARENTNAME:
	{
            Parameter<String> name(inputRecord, "value", ParameterSet::In);
	    if (runMethod) {
               setParentImageName(name());
	    }
	}
    break;
    case PARENTNAME:
	{
            Parameter<String> returnval(inputRecord, "returnval",
                                        ParameterSet::Out);
	    if (runMethod) {
               returnval() = parentImageName();
	    }
	}
    break;
    case FROMRECORD:
	{
            Parameter<GlishRecord> record(inputRecord, "record",
                                          ParameterSet::In);
	    if (runMethod) {
               fromGlishRecord(record());
	    }
	}
    break;
    case NCOORDINATES:
        {
            Parameter<Int> returnval(inputRecord, "returnval",
                                     ParameterSet::Out);
	    if (runMethod) {
               returnval() = nCoordinates();
	    }
	}
    break;
    case COORDINATETYPE:
        {
            Parameter<Vector<String> > returnval(inputRecord, "returnval",
                                                 ParameterSet::Out);
            Parameter<Index> which(inputRecord, "which",
                                   ParameterSet::In);

	    if (runMethod) {
               returnval() = coordinateType(which());
	    }
	}
    break;
    case REFERENCECODE:
        {
            Parameter<Vector<String> > returnval(inputRecord, "returnval",
                                         ParameterSet::Out);
            Parameter<String> type(inputRecord, "type", 
                                     ParameterSet::In);

	    if (runMethod) {
               returnval() = referenceCode(type());
	    }
	}
    break;
    case SETREFERENCECODE:
      {
            Parameter<String> type(inputRecord, "type", ParameterSet::In);
            Parameter<String> value(inputRecord, "value", ParameterSet::In);
            Parameter<Bool> adjust(inputRecord, "adjust", ParameterSet::In);
	    if (runMethod) {
               setReferenceCode(type(), value(), adjust());
	    }
	}
    break;
    case SUMMARY:
        {
            Parameter<Vector<String> > returnval(inputRecord, "returnval", 
                                   ParameterSet::Out);
            Parameter<String> velocity(inputRecord, "velocity", 
                                       ParameterSet::In);
            Parameter<Bool> list(inputRecord, "list", 
                                       ParameterSet::In);
	    if (runMethod) {
               returnval() = summary (velocity(), list());
	    }
	}
    break;
    case EPOCH:
        {
            Parameter<MEpoch> returnval(inputRecord, "returnval", 
                                   ParameterSet::Out);
	    if (runMethod) {
               returnval() = epoch();
	    }
	}
    break;
    case SETEPOCH:
        {
            Parameter<MEpoch> epoch(inputRecord, "value", 
                                    ParameterSet::In);
	    if (runMethod) {
               setEpoch(epoch());
	    }
	}
    break;
    case NAMES:
        {
            Parameter<Vector<String> > returnval(inputRecord, "returnval", 
                                   ParameterSet::Out);
	    if (runMethod) {
               returnval() = worldAxisNames();
	    }
	}
    break;
    case SETNAMES:
        {
            Parameter<String> type(inputRecord, "type", ParameterSet::In);
            Parameter<Vector<String> > names(inputRecord, "value", 
                                             ParameterSet::In);
	    if (runMethod) {
               setWorldAxisNames(type(), names());
	    }
	}
    break;
    case OBSERVER:
        {
            Parameter<String> returnval(inputRecord, "returnval", 
                                   ParameterSet::Out);
	    if (runMethod) {
               returnval() = observer();
	    }
	}
    break;
    case SETOBSERVER:
        {
            Parameter<String> observer(inputRecord, "value", 
                                       ParameterSet::In);
	    if (runMethod) {
               setObserver(observer());
	    }
	}
    break;
    case TELESCOPE:
        {
            Parameter<String> returnval(inputRecord, "returnval", 
                                   ParameterSet::Out);
	    if (runMethod) {
               returnval() = telescope();
	    }
	}
    break;
    case SETTELESCOPE:
        {
            Parameter<String> telescope(inputRecord, "value", 
                                       ParameterSet::In);
	    if (runMethod) {
               setTelescope(telescope());
	    }
	}
    break;
    case UNITS:
        {
            Parameter<Vector<String> > returnval(inputRecord, "returnval", 
                                   ParameterSet::Out);
	    if (runMethod) {
               returnval() = worldAxisUnits();
	    }
	}
    break;
    case SETUNITS:
        {
            Parameter<String> type(inputRecord, "type", ParameterSet::In);
            Parameter<Vector<String> > units(inputRecord, "value", 
                                             ParameterSet::In);
            Parameter<Bool> overwrite(inputRecord, "overwrite", ParameterSet::In);
            Parameter<Index> which(inputRecord, "which", ParameterSet::In);
	    if (runMethod) {
               setWorldAxisUnits(type(), units(), overwrite(), which());
	    }
	}
    break;
    case RESTFREQUENCY:
        {
            Parameter<Quantum<Vector<Double> > > returnval(inputRecord, "returnval", 
                                                           ParameterSet::Out);
	    if (runMethod) {
               returnval() = restFrequency();
	    }
	}
    break;
    case SETRESTFREQUENCY:
        {
            Parameter<Quantum<Vector<Double> > > restFreq(inputRecord, "value", 
                                                          ParameterSet::In);
            Parameter<Bool> append(inputRecord, "append", ParameterSet::In);
            Parameter<Index> which(inputRecord, "which", ParameterSet::In);
	    if (runMethod) {
               setRestFrequency(restFreq(), which(), append());
	    }
	}
    break;
    case REFERENCEPIXEL:
        {
            Parameter<Vector<Double> > returnval(inputRecord, "returnval", 
                                                  ParameterSet::Out);
	    if (runMethod) {
               returnval() = referencePixel();
	    }
	}
    break;
    case SETREFERENCEPIXEL:
        {
            Parameter<String> type(inputRecord, "type", ParameterSet::In);
            Parameter<Vector<Double> > refPix(inputRecord, "value", ParameterSet::In);
	    if (runMethod) {
               setReferencePixel(type(), refPix());
	    }
	}
    break;
    case LINEARTRANSFORM:
        {
            Parameter<String> type(inputRecord, "type", ParameterSet::In);
            Parameter<Array<Double> > returnval(inputRecord, "returnval", 
                                                ParameterSet::Out);
	    if (runMethod) {
               returnval() = linearTransform (type());
	    }
	}
    break;
    case SETLINEARTRANSFORM:
        {
            Parameter<String> type(inputRecord, "type", ParameterSet::In);
            Parameter<Array<Double> > xform(inputRecord, "value", ParameterSet::In);
	    if (runMethod) {
               setLinearTransform (type(), xform());
	    }
	}
    break;
    case REFERENCEVALUE:
        {
            Parameter<GlishRecord> returnval(inputRecord, "returnval", ParameterSet::Out);
            Parameter<String> type(inputRecord, "type", ParameterSet::In);
            Parameter<String> format(inputRecord, "format", ParameterSet::In);
	    if (runMethod) {
               returnval() = referenceValue(type(), format());
	    }
	}
    break;
    case SETREFERENCEVALUE:
        {
            Parameter<String> type(inputRecord, "type", ParameterSet::In);
            Parameter<GlishRecord> refVal(inputRecord, "value", ParameterSet::In);
	    if (runMethod) {
               setReferenceValue(type(), refVal());
	    }
	}
    break;
    case INCREMENT:
        {
            Parameter<GlishRecord> returnval(inputRecord, "returnval", ParameterSet::Out);
            Parameter<String> type(inputRecord, "type", ParameterSet::In);
            Parameter<String> format(inputRecord, "format", ParameterSet::In);
	    if (runMethod) {
               returnval() = increment(type(), format());
	    }
	}
    break;
    case SETINCREMENT:
        {
            Parameter<String> type(inputRecord, "type", ParameterSet::In);
            Parameter<GlishRecord> incr(inputRecord, "value", ParameterSet::In);
	    if (runMethod) {
               setIncrement(type(), incr());
	    }
	}
    break;
    case FINDAXIS:
        {
            Parameter<Bool> returnval(inputRecord, "returnval",
                                      ParameterSet::Out);
            Parameter<Int>  coordinate(inputRecord, "coordinate",
                                       ParameterSet::Out);
            Parameter<Int>  axisInCoordinate(inputRecord, "axisincoordinate",
                                       ParameterSet::Out);
            Parameter<Bool> isWorld(inputRecord, "world",
                                      ParameterSet::In);
            Parameter<Int> axis(inputRecord, "axis", ParameterSet::In);
            if (runMethod) {
               returnval() = findAxis(coordinate(), axisInCoordinate(), isWorld(), axis());
            }
        }
    break;
    case FINDCOORDINATE:
        {
            Parameter<Bool> returnval(inputRecord, "returnval",
                                      ParameterSet::Out);
            Parameter<Vector<Int> > pixelAxes(inputRecord, "pixel",
                                              ParameterSet::Out);
            Parameter<Vector<Int> > worldAxes(inputRecord, "world",
                                              ParameterSet::Out);
            Parameter<Index> which(inputRecord, "which", ParameterSet::In);
            Parameter<String> type(inputRecord, "type", ParameterSet::In);
            if (runMethod) {
               returnval() = findCoordinate(pixelAxes(), worldAxes(), type(), which());
            }
        }
    break;
    case TOWORLD:
        {
            Parameter<GlishRecord> returnval(inputRecord, "returnval",
                                      ParameterSet::Out);
            Parameter<Vector<Double> > pixel(inputRecord, "pixel",
                                             ParameterSet::In);
            Parameter<String> format(inputRecord, "format", ParameterSet::In);
            if (runMethod) {
               returnval() = toWorld (pixel(), format());
            }
        }
    break;
    case TOWORLDMANY:
        {
            Parameter<Array<Double> > returnval(inputRecord, "returnval",
                                                ParameterSet::Out);
            Parameter<Array<Double> > pixel(inputRecord, "pixel",
                                             ParameterSet::In);
            if (runMethod) {
               returnval() = toWorldMany (pixel());
            }
        }
    break;
    case TOPIXEL:
        {
            Parameter<Vector<Double> > returnval(inputRecord, "returnval",
                                              ParameterSet::Out);
            Parameter<GlishRecord> world(inputRecord, "world",
                                         ParameterSet::In);
            if (runMethod) {
               returnval() = toPixel (world());
            }
        }
    break;
    case TOPIXELMANY:
        {
            Parameter<Array<Double> > returnval(inputRecord, "returnval",
                                              ParameterSet::Out);
            Parameter<Array<Double> > world(inputRecord, "world",
                                         ParameterSet::In);
            if (runMethod) {
               returnval() = toPixelMany (world());
            }
        }
    break;
    case AXESMAP:
        {
            Parameter<Vector<Int> > returnval(inputRecord, "returnval",
                                      ParameterSet::Out);
            Parameter<Bool> toworld(inputRecord, "toworld",
                                     ParameterSet::In);
            if (runMethod) {
               returnval() = axesMap (toworld());
            }
        }
    break;
    case NAXES:
        {
            Parameter<Int> returnval(inputRecord, "returnval",
                                      ParameterSet::Out);
            Parameter<Bool> world(inputRecord, "world",
                                     ParameterSet::In);
            if (runMethod) {
               returnval() = nAxes (world());
            }
        }
    break;
    case AXISCOORDINATETYPES:
        {

            Parameter<Vector<String> > returnval(inputRecord, "returnval",
                                      ParameterSet::Out);
            Parameter<Bool> world(inputRecord, "world",
                                     ParameterSet::In);
            if (runMethod) {
               returnval() = axisCoordinateTypes (world());
            }
        }
    break;
    case PROJECTION:
        {
            Parameter<GlishRecord> returnval(inputRecord, "returnval",
                                             ParameterSet::Out);
            Parameter<String> type(inputRecord, "type",
                                   ParameterSet::In);
            if (runMethod) {
               returnval() = projection(type());
            }
        }
    break;
    case SETPROJECTION:
        {
            Parameter<String> type(inputRecord, "type",
                                   ParameterSet::In);
            Parameter<Vector<Double> > parameters(inputRecord, "parameters",
                                                  ParameterSet::In);
            if (runMethod) {
               setProjection (type(), parameters());
            }
        }
    break;
    case REORDER:
        {
            Parameter<Vector<Index> > order(inputRecord, "order", 
                                            ParameterSet::In);
	    if (runMethod) {
               reorder(order());
	    }
	}
    break;
    case FREQUENCYTOFREQUENCY:
        {
            Parameter<Vector<Double> > frequency(inputRecord, "value", 
                                            ParameterSet::In);
            Parameter<String> freqUnit(inputRecord, "frequnit", 
                                            ParameterSet::In);
            Parameter<Quantum<Double> > velocity(inputRecord, "velocity", 
                                            ParameterSet::In);
            Parameter<String> doppler(inputRecord, "doppler", 
                                            ParameterSet::In);

            Parameter<Vector<Double> > returnVal(inputRecord, "returnval",
                                      ParameterSet::Out);
	    if (runMethod) {
               returnVal() = frequencyToFrequency (frequency(), freqUnit(), doppler(), velocity());
	    }
	}
    break;
    case FREQUENCYTOVELOCITY:
        {
            Parameter<Vector<Double> > frequency(inputRecord, "value", 
                                            ParameterSet::In);
            Parameter<String> freqUnit(inputRecord, "frequnit", 
                                            ParameterSet::In);
            Parameter<String> velUnit(inputRecord, "velunit", 
                                            ParameterSet::In);
            Parameter<String> doppler(inputRecord, "doppler", 
                                            ParameterSet::In);
            Parameter<Vector<Double> > returnVal(inputRecord, "returnval",
                                      ParameterSet::Out);
	    if (runMethod) {
               returnVal() = frequencyToVelocity (frequency(), freqUnit(),
                                                  doppler(), velUnit());
	    }
	}
    break;
    case VELOCITYTOFREQUENCY:
        {
            Parameter<Vector<Double> > velocity(inputRecord, "value", 
                                            ParameterSet::In);
            Parameter<String> freqUnit(inputRecord, "frequnit", 
                                            ParameterSet::In);
            Parameter<String> velUnit(inputRecord, "velunit", 
                                            ParameterSet::In);
            Parameter<String> doppler(inputRecord, "doppler", 
                                            ParameterSet::In);
            Parameter<Vector<Double> > returnVal(inputRecord, "returnval",
                                      ParameterSet::Out);
	    if (runMethod) {
               returnVal() = velocityToFrequency (velocity(), freqUnit(),
                                                  doppler(), velUnit());
	    }
	}
    break;
    case TOREL:
        {
            Parameter<GlishRecord> returnVal(inputRecord, "returnval",
                                             ParameterSet::Out);
            Parameter<GlishRecord> rec(inputRecord, "value", 
                                       ParameterSet::In);
            Parameter<Bool> isWorld(inputRecord, "isworld",
                                    ParameterSet::In);
	    if (runMethod) {
               returnVal() = absoluteToRelative(rec(), isWorld());
            }
        }
    break;
    case TORELMANY:
        {
            Parameter<Array<Double> > returnVal(inputRecord, "returnval",
                                             ParameterSet::Out);
            Parameter<Array<Double> > rec(inputRecord, "value", 
                                       ParameterSet::In);
            Parameter<Bool> isWorld(inputRecord, "isworld",
                                    ParameterSet::In);
	    if (runMethod) {
               returnVal() = absoluteToRelativeMany(rec(), isWorld());
            }
        }
    break;
    case TOABS:
        {
            Parameter<GlishRecord> returnVal(inputRecord, "returnval",
                                             ParameterSet::Out);
            Parameter<GlishRecord> rec(inputRecord, "value", 
                                       ParameterSet::In);
            Parameter<Bool> isWorld(inputRecord, "isworld",
                                      ParameterSet::In);
	    if (runMethod) {
               returnVal() = relativeToAbsolute(rec(), isWorld());
	    }
	}
    break;
    case TOABSMANY:
        {
            Parameter<Array<Double> > returnVal(inputRecord, "returnval",
                                             ParameterSet::Out);
            Parameter<Array<Double> > rec(inputRecord, "value", 
                                       ParameterSet::In);
            Parameter<Bool> isWorld(inputRecord, "isworld",
                                      ParameterSet::In);
	    if (runMethod) {
               returnVal() = relativeToAbsoluteMany(rec(), isWorld());
	    }
	}
    break;
    case STOKES:
        {
            Parameter<Vector<String> > returnVal(inputRecord, "returnval",
                                                 ParameterSet::Out);
	    if (runMethod) {
               returnVal() = stokes();
	    }
	}
    break;
    case SETSTOKES:
        {
            Parameter<Vector<String> > stokes(inputRecord, "value",
                                              ParameterSet::In);
	    if (runMethod) {
               setStokes(stokes());
	    }
	}
    break;
    case CONVERT:
        {
            Parameter<Vector<Double> > returnval(inputRecord, "returnval",
                                              ParameterSet::Out);
            Parameter<Vector<Double> > coordIn(inputRecord, "coordin",
                                               ParameterSet::In);
            Parameter<Vector<String> > unitsIn(inputRecord, "unitsin",
                                               ParameterSet::In);
            Parameter<Vector<Bool> > absIn(inputRecord, "absin",
                                           ParameterSet::In);
            Parameter<String> dopplerIn(inputRecord, "dopplerin",
                                        ParameterSet::In);
            Parameter<Vector<String> > unitsOut(inputRecord, "unitsout",
                                               ParameterSet::In);
            Parameter<Vector<Bool> > absOut(inputRecord, "absout",
                                           ParameterSet::In);
            Parameter<String> dopplerOut(inputRecord, "dopplerout",
                                        ParameterSet::In);
            Parameter<Vector<Int> > shape(inputRecord, "shape",
                                           ParameterSet::In);
            if (runMethod) {
               returnval() = convert (coordIn(), absIn(), unitsIn(),
                                      dopplerIn(), absOut(), unitsOut(),
                                      dopplerOut(), shape());
            }
        }
    break;
    case CONVERTMANY:
        {
            Parameter<Array<Double> > returnval(inputRecord, "returnval",
                                              ParameterSet::Out);
            Parameter<Array<Double> > coordIn(inputRecord, "coordin",
                                               ParameterSet::In);
            Parameter<Vector<String> > unitsIn(inputRecord, "unitsin",
                                               ParameterSet::In);
            Parameter<Vector<Bool> > absIn(inputRecord, "absin",
                                           ParameterSet::In);
            Parameter<String> dopplerIn(inputRecord, "dopplerin",
                                        ParameterSet::In);
            Parameter<Vector<String> > unitsOut(inputRecord, "unitsout",
                                               ParameterSet::In);
            Parameter<Vector<Bool> > absOut(inputRecord, "absout",
                                           ParameterSet::In);
            Parameter<String> dopplerOut(inputRecord, "dopplerout",
                                        ParameterSet::In);
            Parameter<Vector<Int> > shape(inputRecord, "shape",
                                           ParameterSet::In);
            if (runMethod) {
               returnval() = convertMany (coordIn(), absIn(), unitsIn(),
                                          dopplerIn(), absOut(), unitsOut(),
                                          dopplerOut(), shape());
            }
        }
    break;
    case SETSPECTRAL:
        {
            Parameter<String> ref(inputRecord, "ref", ParameterSet::In);
            Parameter<Quantum<Double> > restFreq(inputRecord, "restfreq",
                                                 ParameterSet::In);
            Parameter<Quantum<Vector<Double> > > frequencies(inputRecord, "frequencies",
                                                             ParameterSet::In);
            Parameter<String> doppler(inputRecord, "doppler",
                                      ParameterSet::In);
            Parameter<Quantum<Vector<Double> > > velocities(inputRecord, "velocities",
                                                            ParameterSet::In);
            Parameter<Bool> dovel(inputRecord, "dovelocity",
                                  ParameterSet::In);
            Parameter<Bool> dofreq(inputRecord, "dofrequency",
                                  ParameterSet::In);
            if (runMethod) {
               setSpectralCoordinate (ref(), restFreq(),
                                      frequencies(),
                                      doppler(),
                                      velocities(), dofreq(), dovel());
            }
        }
    break;
    case SETTABULAR:
        {
            Parameter<Vector<Double> > pixel(inputRecord, "pixel", ParameterSet::In);
            Parameter<Vector<Double> > world(inputRecord, "world", ParameterSet::In);
            Parameter<Index> which(inputRecord, "which", ParameterSet::In);
            if (runMethod) {
               setTabularCoordinate (pixel(), world(), which());
            }
        }
    break;
    case REPLACECOORDINATE:
        {
            Parameter<Index> in(inputRecord, "in", ParameterSet::In);
            Parameter<Index> out(inputRecord, "out", ParameterSet::In);
            Parameter<GlishRecord> cSys(inputRecord, "csys", ParameterSet::In);

            if (runMethod) {
               replaceCoordinate (cSys(), in(), out());
            }
        }
    break;
    case ADDCOORDINATE:
       {
          Parameter<Bool> direction(inputRecord, "direction",
                                    ParameterSet::In);
          Parameter<Bool> spectral(inputRecord, "spectral",
                                   ParameterSet::In);
          Parameter<Vector<String> > stokes(inputRecord, "stokes",
                                ParameterSet::In);
          Parameter<Int> linear(inputRecord, "linear",
                                ParameterSet::In);
          Parameter<Bool> tabular(inputRecord, "tabular",
                                   ParameterSet::In);
          if (runMethod) {
            addCoordinate(direction(), spectral(), stokes(), linear(), tabular());
          }
       }
    break;
    case SETCONVERSIONTYPE:
       {
          Parameter<String> direction(inputRecord, "direction",
                                    ParameterSet::In);
          Parameter<String> spectral(inputRecord, "spectral",
                                   ParameterSet::In);
          if (runMethod) {
            setConversionType(direction(), spectral());
          }
       }
    break;
    case CONVERSIONTYPE:
       {
          Parameter<String> returnval(inputRecord, "returnval",
                                      ParameterSet::Out);

          Parameter<String> type(inputRecord, "type",
                                    ParameterSet::In);
          if (runMethod) {
            returnval() = getConversionType(type());
          }
       }
    break;
    case SETDIRECTION:
        {
          Parameter<String> ref(inputRecord, "ref", ParameterSet::In);
          Parameter<String> proj(inputRecord, "proj", ParameterSet::In);
          Parameter<Vector<Double> > projPar(inputRecord, "projpar", ParameterSet::In);
          Parameter<Vector<Double> > refPix(inputRecord, "refpix", ParameterSet::In);
          Parameter<GlishRecord> refVal(inputRecord, "refval", ParameterSet::In);
          Parameter<GlishRecord> incr(inputRecord, "incr", ParameterSet::In);
          Parameter<GlishRecord> poles(inputRecord, "poles", ParameterSet::In);
          Parameter<Array<Double> > xform(inputRecord, "xform", ParameterSet::In);
	  if (runMethod) {
             setDirectionCoordinate (ref(), proj(), projPar(), refPix(),
                                     refVal(), incr(), poles(), xform());
	  }
	}
    break;
    default:
	return error("No such method");
    }
    return ok();
}
