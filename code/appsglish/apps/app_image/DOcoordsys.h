//# DOcoordsys.h: coordinate system DO
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
//# $Id: DOcoordsys.h,v 19.9 2004/11/30 17:50:06 ddebonis Exp $



#ifndef APPSGLISH_DOCOORDSYS_H
#define APPSGLISH_DOCOORDSYS_H

#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Quanta/Quantum.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <coordinates/Coordinates/CoordinateSystem.h>
#include <casa/BasicSL/String.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
template<class T> class Matrix;
class ObjectID;
class Index;
class Record;
class GlishRecord;
} //# NAMESPACE CASA - END


// <summary> 
//  Implementation of the coordinate system functionality
// </summary>

// <use visibility=local>   or   <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
// </prerequisite>
//
// <etymology>
//  This implements the functionality for the coordinate system Distributed Object 
// </etymology>
//
// <synopsis>
//  The functionality that is bound to Glish and available via the
//  coordinate system DO is implemented here.
// </synopsis>
//
// <example>
// </example>
//
// <motivation>

// </motivation>
//
// <templating arg=T>
//    <li>
//    <li>
// </templating>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//   <li> 
// </todo>

class coordsys : public ApplicationObject
{
public:
// "coordsys" constructor
   coordsys(Bool direction, Bool spectral, const Vector<String>& stokes,
            Int linear, Bool tabular);

// Construct from given CoordinateSystem
   coordsys(const CoordinateSystem& cSys);

// copy constructor
   coordsys(const coordsys& other);

// assignment
   coordsys& operator=(const coordsys& other);

// Destructor
   ~coordsys();

// Add a new default coordinate. Only Tabular implemented presently.
   void addCoordinate (Bool direction, Bool spectral, const Vector<String>& stokes,
                       Int linear, Bool tabular);

// Axes map
   Vector<Int> axesMap (Bool toWorld) const;

// Axis coordinate types
   Vector<String> axisCoordinateTypes (Bool world) const;

// Coordinate type
   Vector<String> coordinateType (Index which) const;

// Find the specified axis
   Bool findAxis (Int& coordinate,
                  Int& axisInCoordinate,
                  Bool isWorld,
                  Int axis) const;

// Find the axes of the specified coordinate type.
   Bool findCoordinate (Vector<Int>& pixelAxes,
                        Vector<Int>& worldAxes,
                        const String& coordType,
                        Index which) const;

// Convert to/from  a GlishRecord 
// <group>
   GlishRecord toGlishRecord () const;
   void fromGlishRecord (const GlishRecord& rec);
// </group>

// Convert a vector of frequencies to frequency with an offset
   Vector<Double> frequencyToFrequency (const Vector<Double>& frequency,
                                        const String& freqUnit,
                                        const String& doppler,
                                        const Quantum<Double>& velUnit) const;

// Convert a vector of frequencies to velocity 
   Vector<Double> frequencyToVelocity (const Vector<Double>& frequency,
                                       const String& freqUnit,
                                       const String& doppler,
                                       const String& velUnit) const;

// Convert a vector of velocities to frequency 
   Vector<Double> velocityToFrequency (const Vector<Double>& velocity,
                                       const String& freqUnit,
                                       const String& doppler,
                                       const String& velUnit) const;

// Number of coordinates
   Int nAxes (Bool world) const;

// Number of coordinates
   Int nCoordinates () const {return itsCSys.nCoordinates();};

// Get/set the Epoch
// <group>
   MEpoch epoch () const;
   void setEpoch (const MEpoch& epoch);
// </group>

// Get/set reference code
//   <group>
   Vector<String> referenceCode (const String& coordinateType) const;
   void setReferenceCode (const String& coordinateType, const String& code, Bool adjust);
//   </group>

// Set/Get increment
// <group>
   GlishRecord increment (const String& type, const String& format);
   void setIncrement (const String& coordinateType, const GlishRecord& incr);
// </group>

// Get/set the Observer
// <group>
   String observer () const;
   void setObserver (const String& observer);
// </group>

// Set/Get parent image name
// <group>
   String parentImageName () const {return itsParentImageName;};
   void setParentImageName (const String& name) {itsParentImageName = name;};
// </group>

// Set/Get Direction Coordinate projection
// <group>
   GlishRecord projection (const String& type) const;
   void setProjection (const String& type, const Vector<Double>& pars);
// </group>

// Set/Get reference pixel
// <group>
   Vector<Double> referencePixel() const {return itsCSys.referencePixel()+1.0;};   // 1-rel
   void setReferencePixel (const String& coordinateType, const Vector<Double>& refPix);
// </group>

// Set/Get reference value
// <group>
   GlishRecord referenceValue(const String& type, const String& format);
   void setReferenceValue (const String& coordinateType, const GlishRecord& gRec);
// </group>

// Set/Get linear transform
// <group>
   Array<Double> linearTransform (const String& type);
   void setLinearTransform (const String& coordinateType, const Array<Double>& value);
// </group>

// Set/Get rest frequency
// <group>
   Quantum<Vector<Double> > restFrequency () const;
   void setRestFrequency (const Quantum<Vector<Double> >& restFrequency, 
                          Index which, Bool append);
// </group>

// Get/Set new StokesCOordinate info
// <group>
   Vector<String> stokes () const;
   void setStokes (const Vector<String>& stokes);
// </group>


// Set/get extra conversion layers
// <group>
   Bool setConversionType (const String& direction, const String& spectral);
   String getConversionType (const String& type);
// </group>

// Set new DirectionCoordinate info
   void setDirectionCoordinate (const String& ref,
                                const String& proj,
                                const Vector<Double>& projPar,
                                const Vector<Double>& refPix,
                                const GlishRecord& refVal,
                                const GlishRecord& incr,
                                const GlishRecord& poles,
                                const Array<Double>& xform);

// Set new SpectralCoordinate info
   void setSpectralCoordinate (const String& ref,
                               const Quantum<Double>& restFrequency,
                               const Quantum<Vector<Double> >& frequencies,
                               const String& doppler,
                               const Quantum<Vector<Double> >& velocities,
                               Bool dofreq, Bool dovel);

// Set new TabularCoordinate info
   void setTabularCoordinate (const Vector<Double>& pixel,
                              const Vector<Double>& world,
                              Index which);

// Replace coordinates
   void replaceCoordinate (const GlishRecord& cSys, 
                           Index in, Index out);

// Get/set the Telescope
// <group>
   String telescope () const;
   void setTelescope (const String& telescope);
// </group>

// Get/set the world axis names
// <group>
   Vector<String> worldAxisNames () const;
   void setWorldAxisNames (const String& coordinateType, const Vector<String>& names);
// </group>

// Get/set the world axis units
// <group>
   Vector<String> worldAxisUnits() const;
   void setWorldAxisUnits (const String& coordinateType, const Vector<String>& units,
                           Bool overwrite, Index which);
// </group>

// Summary listing
   Vector<String> summary (const String& velocity, Bool list) const;

// absolute world to absolute pixel. 
   Vector<Double> toPixel (const GlishRecord& gRec) const;

// absolute world to absolute pixel for many conversions
   Array<Double> toPixelMany (const Array<Double>& world) const;

// absolute pixel to absolute world
   GlishRecord toWorld (const Vector<Double>& pixel, const String& format);

// absolute pixel to absolute world for many conversions
   Array<Double> toWorldMany (const Array<Double>& coordIn) const;

// absolute coordinate to relative coordinate
   GlishRecord absoluteToRelative (const GlishRecord& absolute, Bool isWorld);

// absolute coordinate to relative coordinate for many conversions
   Array<Double> absoluteToRelativeMany (const Array<Double>& absolute,  Bool isWorld);

// relative coordinate to absolute coordinate
   GlishRecord relativeToAbsolute (const GlishRecord& relative, Bool isWorld);

// relative coordinate to absolute coordinate for many conversions
   Array<Double> relativeToAbsoluteMany (const Array<Double>& absolute,  Bool isWorld);

// General coordinate conversion
   Vector<Double> convert (const Vector<Double>& coordIn,
                           const Vector<Bool>& absIn,
                           const Vector<String>& unitsIn,
                           const String& dopplerIn,
                           const Vector<Bool>& absOut,  
                           const Vector<String>& unitsOut,
                           const String& dopplerOut,
                           const Vector<Int>& shape);

// General coordinate conversion for many conversions
   Array<Double> convertMany (const Array<Double>& coordIn,
                              const Vector<Bool>& absIn,
                              const Vector<String>& unitsIn,
                              const String& dopplerIn,
                              const Vector<Bool>& absOut,  
                              const Vector<String>& unitsOut,
                              const String& dopplerOut,
                              const Vector<Int>& shape);

// reorder
   void reorder (const Vector<Index>& order);

// Stuff needed for distributing this class
   virtual String className() const;
   virtual Vector<String> methods() const;
   virtual Vector<String> noTraceMethods() const;

// If your object has more than one method
   virtual MethodResult runMethod(uInt which, 
                                  ParameterSet &inputRecord,
                                  Bool runMethod);

private:
   CoordinateSystem itsCSys;
   String itsParentImageName;

// Inter convert absolute and relative world or pixel coordinates
// <group>
   GlishRecord absRel (LogIO& os, const RecordInterface& recIn, Bool isWorld, Bool absToRel);
   Record absRelRecord (LogIO& os, const RecordInterface& recIn, Bool isWorld, Bool absToRel);
// </group>

// Add default coordinates to CS
   void addCoordinate (CoordinateSystem& cSys, Bool direction, Bool spectral, const Vector<String>& stokes,
                       Int linear, Bool tabular);

// Copy the world axes of in to out
   void copyWorldAxes (Vector<Double>& out, const Vector<Double>& in, Int c) const;

// Convert record of measures to world coordinate vector
   Vector<Double> measuresToWorldVector (const RecordInterface& rec) const;

// Convert world coordinate to measures and stick in record
   Record worldVectorToMeasures(const Vector<Double>& world, Int c, 
                                Bool abs) const;

// Find coordinate of desired type
   Int findCoordinate (Coordinate::Type type, Bool warn) const;

// Convert a record holding some mixture of numeric, measures, quantity, string
// to a vector of doubles
   void recordToWorldVector (Vector<Double>& world, String& type, Int c,
                             const RecordInterface& rec) const;

// Convert a vector of world to a record holding some mixture 
// of numeric, measures, quantity, string
   Record worldVectorToRecord (const Vector<Double>& world,
                               Int c, const String& format, 
                               Bool isAbsolute, Bool showAsAbsolute);

// Convert Quantum to record
   Record quantumToRecord (LogIO& os, const Quantum<Double>& value) const;

// Set DirectionCoordinate reference code
   void setDirectionCode (const String& code, Bool adjust);

// Set SpectralCoordinate reference code
   void setSpectralCode (const String& code, Bool adjust);

// Convert world String to world vector double.  World vector must be length
// cSys.nWorldAxes()
   Vector<Double> stringToWorldVector (LogIO& os, 
                                       const Vector<String>& world,
                                       const Vector<String>& worldAxisUnits) const;

// Convert user coordinate type string to enum
   Coordinate::Type stringToType(const String& typeIn) const;

// absolute pixel to absolute world
   Record toWorldRecord (const Vector<Double>& pixel, const String& format);

// Add missing values or tim excessive
   void trim (Vector<Double>& in,
              const Vector<Double>& replace) const;

// Convert a vector of quantum doubles in a record to a vector of double
// applying specified units
   Vector<Double> quantumVectorRecordToVectorDouble (const RecordInterface& recQ,
                                                     const Vector<String>& units) const;

// Runmethod enum
    enum methods {ADDCOORDINATE, AXESMAP, AXISCOORDINATETYPES, COORDINATETYPE, 
                  CONVERSIONTYPE, CONVERT, CONVERTMANY, EPOCH,  FINDAXIS,
                  FINDCOORDINATE, FREQUENCYTOFREQUENCY, FREQUENCYTOVELOCITY, 
                  FROMRECORD, INCREMENT, LINEARTRANSFORM, NAMES,
                  NAXES, NCOORDINATES, OBSERVER, PARENTNAME, 
                  PROJECTION, REFERENCECODE,
                  REFERENCEPIXEL, REFERENCEVALUE, REPLACECOORDINATE,
                  REORDER, RESTFREQUENCY, SETCONVERSIONTYPE, SETDIRECTION,
                  SETEPOCH, SETINCREMENT, SETLINEARTRANSFORM, SETNAMES, SETOBSERVER, SETPARENTNAME, 
                  SETPROJECTION, SETREFERENCECODE,
                  SETREFERENCEPIXEL, SETREFERENCEVALUE, SETRESTFREQUENCY,
                  SETSPECTRAL, SETSTOKES, SETTABULAR, SETTELESCOPE, 
                  SETUNITS, STOKES, SUMMARY, TELESCOPE, 
                  TOABS, TOABSMANY, TOPIXEL, TOPIXELMANY, TORECORD, 
                  TOREL, TORELMANY, TOWORLD, 
                  TOWORLDMANY, UNITS, 
                  VELOCITYTOFREQUENCY, NUM_METHODS};
};

#endif
