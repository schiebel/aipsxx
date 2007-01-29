//# MeasFrame.h: Container for Measure frame
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
//# $Id: MeasFrame.h,v 19.6 2006/01/11 13:13:04 gvandiep Exp $

#ifndef MEASURES_MEASFRAME_H
#define MEASURES_MEASFRAME_H

//# Includes
#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <measures/Measures/Measure.h>
#include <casa/iosfwd.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward Declarations
class MVEpoch;
class MVPosition;
class MVDirection;
class MVRadialVelocity;
class MeasComet;
class FrameRep;
class MCFrame;
template <class T> class Vector;
template <class Qtype> class Quantum;

// <summary> Container for Measure frame </summary>

// <use visibility=export>

// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="tMeasure" demos="">
// </reviewed>

// <prerequisite>
// <li> <linkto class=Measure>Measure</linkto> class
// <li> <linkto class=MeasRef>MeasRef</linkto> class
// </prerequisite>
//
// <etymology>
// From Measure and Frame
// </etymology>
//
// <synopsis>
// Measurements are made in a reference frame (epoch, position, direction,
// ...).<br>
// The class is a container for the reference frame Measures (MEpoch etc).
// Since a frame will possibly be used by many different Measures, it behaves
// as a smart pointer, with reference rather than copy characteristics.
// Since it caches all its operations, it is advisable to have a 'global'
// MeasFrame across an execution, resetting (or setting) its values
// when appropiate. The frame can also contain other related information. At
// the moment the orbit of a solar system body (MeasComet) can be set.
// In future the planetary ephemeris used (e.g. DE205) and environmental
// information like refraction data will be added.
//
// A MeasFrame is constructed by setting the appropiate Measures, either in
// a constructor, or with a set(). The input to the constructors and set are
// Measures.<br>
//
// Inside the frames automatic conversion to the most appropiate usage of
// its values is done (e.g. time to TBD time, position to astronomical
// longitude). These conversions are done only if an explicit
// Measure::Convert was used that needed information, e.g. the following
// code:
// <srcblock>
//	MeasFrame frame(obser);   // obser is an MPosition
//	MEpoch::Convert conv(MEpoch(12345), MEpoch::Ref(MEpoch::LAST,obser));
//	MEpoch last = conv();
// </srcblock>
// will set-up a state machine to convert UTC(default) to LAST in conv; the
// next call will do the actual conversion. During this conversion, the
// astronomical longitude (among others) will be needed to convert to
// local sidereal time. conv will ask (getLong()) this from the frame, which
// will calculate it (including possible other conversions) from the
// observatory's position specified in a frame. Any calculation done will be
// cached (e.g. a Nutation calculation in this case for dpsi), and used in
// subsequent conversions using the same frame.<br>
// Furthermore, a frame will often be regularly updated (e.g. coordinate
// conversion for a series of times). To make use of cached information, and
// to speed up as much as possible, <src>reset...()</src> functions are 
// available. These reset functions accept the same range of input parameter
// types as the <linkto class=MeasConvert>MeasConvert</linkto> () operator,
// and will keep any determined conversion machines and related information
// intact, only recalculating whatever is necessary.<br>
// The actual frame calculations and interrogations are done in a separate
// <linkto class=MCFrame>MCFrame</linkto> hidden class, which attaches itself
// to MeasFrame when and if necessary (see there if you are really curious).<br>.
// get...() functions can return frame measures. Only when the frame has been
// attached to a calculating machine *MCFrame) are these values available.
// This attachment is done if the frame has been actively used by a
// Measure::Convert engine, or if explicitly done by the
// <src>MCFrame::make(MeasFrame &)</src> static method.
// <note role=caution> An explicit (or implicit) call to MCFrame::make will
// load the whole conversion machinery (including Tables) into your
// linked module).</note><br>
// <linkto class=Aipsrc>Aipsrc keywords</linkto> can be used for additional
// (highly specialised) additional internal conversion parameters.
// </synopsis>
//
// <example>
// <srcblock>
//	MEpoch my_epoch(Quantity(MeasData::MJDB1950,"d")); // an epoch
//	MeasFrame frame(my_epoch);	// used in a frame
// </srcblock>
// </example>
//
// <motivation>
// To separate the frame definition from the measure type
// </motivation>
//
// <todo asof="1997/04/16">
// </todo>

class MeasFrame {

 public:
  
  //# Friends
  // Output a frame
  friend ostream &operator<<(ostream &os, MeasFrame &mf);
  // Machinery
  // <group>
  friend class MCFrame;
  friend Bool MCFrameGetdbl(void *dmf, uInt tp, Double &result);
  friend Bool MCFrameGetmvdir(void *dmf, uInt tp, MVDirection &result);
  friend Bool MCFrameGetmvpos(void *dmf, uInt tp, MVPosition &result);
  friend Bool MCFrameGetuint(void *dmf, uInt tp, uInt &result);
  // </group>

  //# Enumerations
  // Enumeration for the different farme entries possible. This can be used
  // to find out if a certain conversion needs the frame. It will be
  // used in a registration/notify environment to enable bypassing of
  // some new conversion settings.
  enum FrameTypes {
    EPOCH 	= 1,
    POSITION 	= 2,
    DIRECTION 	= 4,
    VELOCITY 	= 8,
    COMET 	= 16 };

  //# Constructors
  // Default constructor
  MeasFrame();
  // Construct frame with specified measures
  // <thrown>
  //   <li> AipsError if a non-frame Measure
  // </thrown>
  // <grp>
  MeasFrame(const Measure &meas1);
  MeasFrame(const Measure &meas1, const Measure &meas2);
  MeasFrame(const Measure &meas1, const Measure &meas2,
	    const Measure &meas3);
  // </grp>
  // Copy constructor (reference semantics)
  MeasFrame(const MeasFrame &other);
  // Copy assignment (reference semantics)
  MeasFrame &operator=(const MeasFrame &other);
  // Destructor
  ~MeasFrame();
  
  //# Operators
  // Comparisons
  // <group>
  Bool operator==(const MeasFrame &other) const;
  Bool operator!=(const MeasFrame &other) const;
  // </group>
  
  //# General member functions
  // Test if empty (i.e. no measure filled in)
  Bool empty() const;
  
  // Set frame elements
  // <thrown>
  //   <li> AipsError if a non-frame Measure
  //   <li> AipsError if illegal or non-existant MeasComet given
  // </thrown>
  // <group>
  void set(const Measure &meas1);
  void set(const Measure &meas1, const Measure &meas2);
  void set(const Measure &meas1, const Measure &meas2,
	   const Measure &meas3);
  void set(const MeasComet &meas);
  // </group>
  // Reset a frame element and its cached derived values.
  // <thrown>
  //   <li> AipsError if the specific Measure not yet present in frame
  // </thrown>
  // <group>
  void resetEpoch(Double val);
  void resetEpoch(const Vector<Double> &val);
  void resetEpoch(const Quantum<Double> &val);
  void resetEpoch(const Quantum<Vector<Double> > &val);
  void resetEpoch(const MVEpoch &val);
  void resetEpoch(const Measure &val);
  void resetPosition(const Vector<Double> &val);
  void resetPosition(const Quantum<Vector<Double> > &val);
  void resetPosition(const MVPosition &val);
  void resetPosition(const Measure &val);
  void resetDirection(const Vector<Double> &val);
  void resetDirection(const Quantum<Vector<Double> > &val);
  void resetDirection(const MVDirection &val);
  void resetDirection(const Measure &val);
  void resetRadialVelocity(const Vector<Double> &val);
  void resetRadialVelocity(const Quantum<Vector<Double> > &val);
  void resetRadialVelocity(const MVRadialVelocity &val);
  void resetRadialVelocity(const Measure &val);
  void resetComet(const MeasComet &val);
  // </group>
  
  // Get the epoch pointer (0 if not present)
  const Measure *const epoch() const;
  // Get the position pointer (0 if not present)
  const Measure *const position() const;
  // Get the direction pointer (0 if not present)
  const Measure *const direction() const;
  // Get the radial velocity pointer (0 if not present)
  const Measure *const radialVelocity() const;
  // Get the comet pointer (0 if not present)
  const MeasComet *const comet() const;
  // Get data from frame. Only available if appropiate measures are set,
  // and the frame is in a calculating state.
  // <group>
  // Get TDB in days
  Bool getTDB(Double &tdb);
  // Get UT1 in days
  Bool getUT1(Double &tdb);
  // Get TT in days
  Bool getTT(Double &tdb);
  // Get the ITRF longitude (in rad)
  Bool getLong(Double &tdb);
  // Get the ITRF latitude (in rad)
  Bool getLat(Double &tdb);
  // Get the position
  Bool getITRF(MVPosition &tdb);
  // Get the geocentric position (in m)
  Bool getRadius(Double &tdb);
  // Get the geodetic latitude
  Bool getLatGeo(Double &tdb);
  // Get the LAST (in days)
  Bool getLAST(Double &tdb);
  // Get the LAST (in rad)
  Bool getLASTr(Double &tdb);
  // Get J2000 coordinates (direction cosines) and its longitude/latitude (rad)
  // <group>
  Bool getJ2000(MVDirection &tdb);
  Bool getJ2000Long(Double &tdb);
  Bool getJ2000Lat(Double &tdb);
  // </group>
  // Get B1950 coordinates (direction cosines)
  // <group>
  Bool getB1950(MVDirection &tdb);
  Bool getB1950Long(Double &tdb);
  Bool getB1950Lat(Double &tdb);
  // </group>
  // Get apparent coordinates (direction cosines)
  // <group>
  Bool getApp(MVDirection &tdb);
  Bool getAppLong(Double &tdb);
  Bool getAppLat(Double &tdb);
  // </group>
  // Get LSR radial velocity (m/s)
  Bool getLSR(Double &tdb);
  // Get the comet table reference type
  Bool getCometType(uInt &tdb);
  // Get the comet coordinates
  Bool getComet(MVPosition &tdb);
  // </group>

  // Get the frame conversion data pointer (0 if none)
  void *getMCFramePoint() const;
  
private:
  
  //# Enumerations
  // Types of known get data routines. The actual work is in MCFrame,
  // using pointers to functions
  enum GetTypes {
    // Get TDB in days
    GetTDB,
    // Get UT1 in days
    GetUT1,
    // Get TT in days
    GetTT,
    // Get the ITRF longitude (in rad)
    GetLong,
    // Get the ITRF latitude (in rad)
    GetLat,
    // Get the geocentric position (in m)
    GetRadius,
    // Get the geodetic latitude
    GetLatGeo,
    // Get the LAST (in days)
    GetLAST,
    // Get the LAST (in rad)
    GetLASTr,
    // Get J2000 coordinates (direction cosines)
    GetJ2000,
    // Get J2000 coordinates (longitude)
    GetJ2000Long,
    // Get J2000 coordinates (latitude)
    GetJ2000Lat,
    // Get B1950 coordinates (direction cosines)
    GetB1950,
    // Get B1950 coordinates (longitude)
    GetB1950Long,
    // Get B1950 coordinates (latitude)
    GetB1950Lat,
    // Get apparent coordinates (direction cosines)
    GetApp,
    // Get App coordinates (longitude)
    GetAppLong,
    // Get App coordinates (latitude)
    GetAppLat,
    // Get LSR radial velocity (m/s)
    GetLSR,
    // Get the position
    GetITRF,
    // Get the comet type
    GetCometType,
    // Get comet coordinates
    GetComet
  };
  
  //# Data
  // Representation of MeasFrame
  FrameRep *rep;
  
  //# Member functions
  // Create an instance of the MeasFrame class
  void create();
  // Fill a MeasFrame element
  // <group>
  void fill(const Measure *in);
  void fill(const MeasComet *in);
  // </group>
  // Make full Epoch
  void makeEpoch();
  // Make full Position
  void makePosition();
  // Make full Direction
  void makeDirection();
  // Make full RadialVelocity
  void makeRadialVelocity();
  // Make full Comet
  void makeComet();
  // Throw reset error
  void errorReset(const String &txt);
  // Get the different set and reset indicators (for use in MCFrame)
  // <group>
  Bool getEpset() const;
  Bool getDirset() const;
  Bool getPosset() const;
  Bool getRadset() const;
  Bool getComset() const;
  Bool getEpreset() const;
  Bool getDirreset() const;
  Bool getPosreset() const;
  Bool getRadreset() const;
  Bool getComreset() const;
  // </group>
  // Set the different set/reset switches
  // <group>
  void setEpset(Bool in);
  void setPosset(Bool in);
  void setDirset(Bool in);
  void setRadset(Bool in);
  void setComset(Bool in);
  void setEpreset(Bool in);
  void setPosreset(Bool in);
  void setDirreset(Bool in);
  void setRadreset(Bool in);
  void setComreset(Bool in);
  // </group>
  // Set the frame conversion data pointer (by MCFrame)
  void setMCFramePoint(void *in);
  // Set the frame conversion deletor
  void setMCFrameDelete(void (*in)(void*));
  // Set the get double routine
  void setMCFrameGetdbl(Bool (*in)(void *, uInt, Double &));
  // Set the get MVDirection routine
  void setMCFrameGetmvdir(Bool (*in)(void *, uInt, MVDirection &));
  // Set the get MVPosition routine
  void setMCFrameGetmvpos(Bool (*in)(void *, uInt, MVPosition &));
  // Set the get uint routine
  void setMCFrameGetuint(Bool (*in)(void *, uInt, uInt &));
  // Lock the frame to make sure deletion occurs when needed
  void lock();
  // Unlock the frame
  void unlock();
};

//# Global functions
// <summary> Global functions </summary>
// <group name=Output>
// Output a frame
ostream &operator<<(ostream &os, MeasFrame &mf);
// </group>


} //# NAMESPACE CASA - END

#endif
