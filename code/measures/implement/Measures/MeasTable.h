//# MeasTable.h: MeasTable provides Measure computing database data
//# Copyright (C) 1995-1999,2000-2004
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
//# $Id: MeasTable.h,v 19.10 2004/11/30 17:50:34 ddebonis Exp $

#ifndef MEASURES_MEASTABLE_H
#define MEASURES_MEASTABLE_H

//# Includes
#include <casa/aips.h>
#include <measures/Measures/MeasData.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MFrequency.h>
#include <scimath/Functionals/Polynomial.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward Declarations
class RotMatrix;
class Euler;

// <summary>
// MeasTable provides Measure computing database data
// </summary>

// <use visibility=local>

// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="tMeasMath" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class=Measure>Measure</linkto> class 
//   <li> <linkto class=MeasData>MeasData</linkto> class for constant data
//   <li> <linkto class=Aipsrc>Aipsrc</linkto> class for data placement
// </prerequisite>
//
// <etymology>
// MeasTable from Measure and Table
// </etymology>
//
// <synopsis>
// MeasTable contains the database interface for all
// data necessary for precession, nutation and other 
// <linkto class=Measure>Measure</linkto> related calculations.<br>
// All data are obtained by calls to a method. E.g.
// <src> fundArg(1) </src> will provide the first fundamental argument for
// nutation calculations, i.e. 'l'. <br>
// This class contains no constructors or destructors, only static
// methods and (static) constants.
// <br> References:<br> Explanatory supplements to the Astronomical Almanac
// <br> C. Ron and J. Vondrak, Bull. Astron. Inst. Czechosl. 37, p96, 1986
// <br> M. Soma, Th. Hirayama and H. Kinoshita, Celest. Mech. 41, p389, 1988
// <br> V.S. Gubanov, Astron. Zh. 49, p1112, 1992
//
// Where strings are passed in as arguments (observatory names, sources), they
// will be case insensitive, and minimum match.
// </synopsis>
//
// <example>
// Usage examples can be found in <linkto class=Precession>Precession</linkto>
// </example>
//
// <motivation>
// To create a clean interface between the actual calculations and the
// methods to obtain the parameters for these calculations. Note that the
// tables are in general in the format and units found in the literature. This
// is to be able to easy check and change them. However, in the future
// re-arrangement could produce faster and more compact code.
// </motivation>
//
// <todo asof="1997/09/02">
//   <li> more database interfaces, rather than constants
// </todo>

class MeasTable {

public:
  
  //# Enumerations
  // Types to be used in different calls
  enum Types {
    // Planetary information
    MERCURY = 1,
    VENUS = 2,
    EARTH = 3,
    MARS = 4,
    JUPITER = 5,
    SATURN = 6,
    URANUS = 7,
    NEPTUNE = 8,
    PLUTO = 9,
    MOON = 10,
    SUN = 11,
    // Solar system barycentre
    BARYSOLAR = 12,
    // Earth-Moon system barycentre
    BARYEARTH = 13,
    // Nutations
    NUTATION = 14,
    // Librations
    LIBRATION = 15,
    // Number of types
    N_Types };

  // Codes for JPL constants: order should be same as in MeasJPL, length less
  // than or equal
  enum JPLconst {
    // Light velocity used in AU/d
    CAU,
    // Solar mass (GM0)/c<sup>2</sup> in AU
    GMS,
    // AU in km
    AU,
    // Solar radius in AU
    RADS,
    // # of codes
    N_JPLconst };

  //# General Member Functions
  // Selection related data
  // <group>
  // Are the IAU2000 precession/nutation to be used or not (IAU1984)
  static Bool useIAU2000();
  // If IAU2000 model, do we use the high precision 2000A model?
  static Bool useIAU2000A();
  // </group>

  // Precession related data
  // <group>
  // Get the precession-rate part of the IAU2000 precession-nutation models
  // (which 0=dpsi (long) and 1=deps (obliquity) and 2 =0)
  static Double precRate00(const uInt which);

  // Get the frame bias matrix for IAU2000 model.
  static RotMatrix frameBias00();

  // Generate the precession calculation polynomials for a fixed Epoch T
  // in the result area specified.
  // T is given in Julian centuries since J2000.0.
  static void
  precessionCoef(Double T, Polynomial<Double> result[3]);
  
  // Generate the precession polynomials for IAU2000 system.
  static void
  precessionCoef2000(Polynomial<Double> result[3]);
  
  // Generate the precession polynomials for 1950 system for a fixed Epoch T
  // in the area specified. T is given in Tropical centuries since B1850.0
  static void
  precessionCoef1950(Double T, Polynomial<Double> result[3]);
  // </group>
  
  // Nutation related data
  // <group>
  // Generate the polynomial for the fundamental arguments (eps, l, l',
  // F, D, omega) as a function of Julian centuries
  // <group>
  static const Polynomial<Double> &fundArg(uInt which);
  static const Polynomial<Double> &fundArg1950(uInt which);
  static const Polynomial<Double> &fundArg2000(uInt which);
  // </group>

  // Get the planetary arguments (L, L', F, D, Om, Me, Ve, E, Ma, Ju Sa,
  // Ur, Ne, pre) 
  static const Polynomial<Double> &planetaryArg2000(uInt which);

  // Generate the which' vector of the nutation series arguments
  // <group>
  static const Vector<Char> &mulArg(uInt which);
  static const Vector<Char> &mulArg1950(uInt which);
  static const Vector<Char> &mulArg2000A(uInt which);
  static const Vector<Char> &mulArg2000B(uInt which);
  static const Vector<Char> &mulPlanArg2000A(uInt which);
  // </group>

  // Generate the which' vector of the equation of equinoxes (IAU2000)
  // complementary terms series arguments
  static const Vector<Char> &mulArgEqEqCT2000(uInt which);

  // Generate the which' vector of the nutation series multipliers
  // at T, measured in Julian centuries since J2000.0, respectively B1900.0
  // <group>
  static const Vector<Double> &mulSC(uInt which, Double T);
  static const Vector<Double> &mulSC1950(uInt which, Double T);
  static const Vector<Double> &mulSC2000A(uInt which, Double T);
  static const Vector<Double> &mulSC2000B(uInt which, Double T);
  static const Vector<Double> &mulPlanSC2000A(uInt which);
  // </group>

  // Generate the which' vector of the equation of equinoxes (IAU2000)
  // complementary terms series multipliers
  // at T, measured in Julian centuries since J2000.0, respectively B1900.0
  static const Vector<Double> &mulSCEqEqCT2000(uInt which);

  // Get nutation angles corrections for UTC T in rad.
  // which = 0 : dPsi as given by IERS for IAU nutation theory;
  // = 1: dEps as same.
  static Double dPsiEps(uInt which, Double T);
  // </group>

  // Planetary (JPL DE) related data
  // <group>
  // Get the position (AU or rad) and velocity (AU/d or rad/d) for specified
  // code at TDB T. The ephemeris to use (now DE200 or DE405) can be selected
  // with the 'measures.jpl.ephemeris' aipsrc resource (default DE200).
  static const Vector<Double> &Planetary(MeasTable::Types which, 
					 Double T); 
  // Get the JPL DE constant indicated
  static const Double &Planetary(MeasTable::JPLconst what);
  // </group>

  // Observatory positions
  // <group>
  // Initialise list of all observatories from Observatories table
  static void initObservatories();
  // Get list of all observatories
  static const Vector<String> &Observatories();
  // Get position of observatory nam (False if not present)
  static const Bool Observatory(MPosition &obs, const String &nam);
  // </group>

  // Source list positions
  // <group>
  // Initialise list of all source from Sources table
  static void initSources();
  // Get list of all sources
  static const Vector<String> &Sources();
  // get position of source nam (False if not present)
  static const Bool Source(MDirection &obs, const String &nam);
  // </group>
  
  // Rest frequencies
  // <group>
  // Initialise list from internal Table for now
  static void initLines();
  // Get list of all frequencies
  static const Vector<String> &Lines();
  // Get frequency of line name (False if not present)
  static const Bool Line(MFrequency &obs, const String &nam);
  // </group>

  // Earth magnetic field (IGRF) data
  // <group>
  // Get the harmonic terms for specified time (mjd)
  static const Vector<Double> &IGRF(Double t);
  // </group>

  // Aberration related data
  // <group>
  // Generate the polynomial for the fundamental arguments (l1-l8, w, D, l,
  // l', F) for the Ron/Vondrak aberration calculations as a function of 
  // Julian centuries(J2000), or the comparable ones for the Gubanov expansion
  // (B1950). 
  // <group>
  static const Polynomial<Double> &aberArg(uInt which);
  static const Polynomial<Double> &aber1950Arg(uInt which);
  // </group>
  
  // Generate the which' vector of the aberration series arguments
  // <group>
  static const Vector<Char> &mulAberArg(uInt which);
  static const Vector<Char> &mulAber1950Arg(uInt which);
  static const Vector<Char> &mulAberSunArg(uInt which);
  static const Vector<Char> &mulAberEarthArg(uInt which);
  // </group>
  
  // Generate the which' vector of the aberration series multipliers
  // at T, measured in Julian centuries since J2000.0 (or comparable for
  // B1950).
  // <group>
  static const Vector<Double> &mulAber(uInt which, Double T);
  static const Vector<Double> &mulAber1950(uInt which, Double T);
  static const Vector<Double> &mulSunAber(uInt which);
  static const Vector<Double> &mulEarthAber(uInt which);
  // </group>
  
  // Get the E-terms of Aberration correction (0 for position, 1 for velocity)
  // <group>
  static const Vector<Double> &AberETerm(uInt which);
  // </group>
  
  // </group>
  
  // Diurnal aberration factor
  static Double diurnalAber(Double radius, Double T);
  
  // LSR (kinematical) velocity conversion: 0 gives J2000; 1 gives B1950.
  // In both cases a velocity of 20.0 km/s is assumed, and a B1900 RA/Dec
  // direction of (270,30) degrees. This value has been defined between
  // the groups doing HI radio work in the mid 1950s.
  static const Vector<Double> &velocityLSRK(uInt which);
  // LSR (dynamical, IAU definition). Velocity (9,12,7) km/s in galactic
  // coordinates. Or 16.552945 towards l,b = 53.13, +25.02 deg.
  // 0 gives J2000, 1 gives B1950 velocities.
  static const Vector<Double> &velocityLSR(uInt which);
  // Velocity of LSR with respect to galactic centre. 220 km/s in direction
  // l,b = 270, +0 deg. 0 returns J2000, 1 B1950
  static const Vector<Double> &velocityLSRGal(uInt which);
  // Velocity of Local Group wrt bary center (F.Ghigo): 308km/s towards
  // l,b = 105,-7. 0 for J2000, 1 for B1950
  static const Vector<Double> &velocityCMB(uInt which);
  // Velocity of CMB wrt bary center (F.Ghigo): 369.5km/s towards
  // l,b = 264.4,48.4. 0 for J2000, 1 for B1950

  static const Vector<Double> &velocityLGROUP(uInt which);
  // Earth and Sun position related data
  // <group>
  // Fundamental arguments for Soma et al. methods
  // <group>
  static const Polynomial<Double> &posArg(uInt which);
  // </group>
  // Generate the which' vector of the position series arguments
  // <group>
  static const Vector<Char> &mulPosEarthXYArg(uInt which);
  static const Vector<Char> &mulPosEarthZArg(uInt which);
  static const Vector<Char> &mulPosSunXYArg(uInt which);
  static const Vector<Char> &mulPosSunZArg(uInt which);
  // </group>
  
  // Generate the which' vector of the position series multipliers
  // at T, measured in Julian centuries since J2000.0
  // <group>
  static const Vector<Double> &mulPosEarthXY(uInt which, Double T);
  static const Vector<Double> &mulPosEarthZ(uInt which, Double T);
  static const Vector<Double> &mulPosSunXY(uInt which, Double T);
  static const Vector<Double> &mulPosSunZ(uInt which, Double T);
  // </group>
  // Get the rotation matrix to change position from ecliptic to rectangular
  // for Soma et al. analytical expression
  static const RotMatrix &posToRect();
  // Get the rotation matrix to change position from rectangular to ecliptic
  // for Soma et al. analytical expression
  static const RotMatrix &rectToPos();
  // Get the rotation matrix from galactic to supergalactic.
  // Based on De Vaucouleurs 1976:  Pole at 47.37/6.32 deg; 137.37 l0
  // Euler angles: 90, 83.68, 47.37 degrees
  static const RotMatrix &galToSupergal();
  // Get the rotation matrix from ICRS to J2000/FK5.
  // Based on the IAU 2000 resolutions (the bias matrix)
  static const RotMatrix &ICRSToJ2000();
  // </group>
  
  // Position related routines
  // <group>
  // Equatorial radius (0) and flattening(1) of geodetic reference spheroids
  static Double WGS84(uInt which);
  // </group>
  
  // Polar motion related routines
  // <group>
  // Get the polar motion (-x,-y,0)(2,1,3) angles
  static const Euler &polarMotion(Double ut);
  // </group>
  
  // Time related routines
  // <logged>
  //   <li> HIGH, WARNING given if correction not obtainable
  // </logged>
  // <thrown>
  //  <li> AipsError if table seems to be corrupted
  // </thrown>
  // <group>
  // Give TAI-UTC (in s) for MJD utc UTC
  static Double dUTC(Double utc);
  // UT1-UTC (in s) for MJD tai TAI
  static Double dUT1(Double utc);
  // TDT-TAI (in s) for MJD tai TAI. Note this is equal to TT2000-TAI
  static Double dTAI(Double tai=0.0);
  // TDB-TDT (in s) for MJD ut1 UT1
  static Double dTDT(Double ut1);
  // TCB-TDB (in s) for MJD tai TAI
  static Double dTDB(Double tai);
  // TCG-TT (in s) for MJD tai TAI
  static Double dTCG(Double tai);
  // GMST1 at MJD ut1 UT1
  static Double GMST0(Double ut1);
  // GMST (IAU2000) including the ERA (IAU2000 Earth Rotation Angle) in rad
  static Double GMST00(Double ut1, Double tt);
  // Earth Rotation Angle (IAU2000) in rad
  static Double ERA00(Double ut1);
  // s' (IAU2000) in rad (approximate value)
  static Double sprime00(Double tt);
  // UT1 at GMSD gmst1 GMST1
  static Double GMUT0(Double gmst1);
  // Ratio UT1/MST at MJD ut1 UT1
  static Double UTtoST(Double ut1);
  // </group>

private:
  
  //# Constructors
  // Default constructor, NOT defined
  MeasTable();
  
  // Copy assign, NOT defined
  MeasTable &operator=(const MeasTable &other);
  
  //# Destructor
  //  Destructor, NOT defined and not declared to stop warning
  // ~MeasTable();

  //# General member functions

  // Calculate precessionCoef
  // <group>
  static void calcPrecesCoef(Double T, Polynomial<Double> result[3],
			     const Double coeff[3][6]); 
  static void calcPrecesCoef2000(Polynomial<Double> result[3],
				 const Double coeff[3][6]); 
  // </group>

  // Calculate fundArg
  // <group>
  static void calcFundArg(Bool &need, Polynomial<Double> result[6],
			  const Double coeff[6][4]); 
  static void calcFundArg00(Bool &need, Polynomial<Double> result[6],
			    const Double coeff[6][5]); 
  static void calcPlanArg00(Bool &need, 
			    Polynomial<Double> result[14],
			    const Double coeff[8][2]);
  // </group>

  // Calculate mulArg
  // <group>
  static void calcMulArg(Bool &need, Vector<Char> result[],
			 const Char coeff[][5], Int row); 
  static void calcMulPlanArg(Bool &need, Vector<Char> result[],
			     const Char coeff[][14], Int row); 
  // </group>

  // Calculate mulSC
  // <group>
  static void calcMulSC(Bool &need, Double &check, Double T,
			Vector<Double> result[], Int resrow,
			Polynomial<Double> poly[],
			const Long coeffTD[][5], Int TDrow,
			const Short coeffSC[][2]);
  static void calcMulSC2000(Bool &need, Double &check, Double T,
			    Vector<Double> result[], uInt resrow,
			    Polynomial<Double> poly[],
			    const Long coeffSC[][6]);
  static void calcMulSCPlan(Bool &need,
			    Vector<Double> result[], uInt resrow,
			    const Short coeffSC[][4]);
  static void calcMulSCPlan(Bool &need,
			    Vector<Double> result[], uInt resrow,
			    const Double coeffSC[][2]);
  // </group>
  //# Data
  // Observatories table data
  // <group>
  static Bool obsNeedInit;
  static Vector<String> obsNams;
  static Vector<MPosition> obsPos;
  // </group>
  // Spectral line table data
  // <group>
  static Bool lineNeedInit;
  static Vector<String> lineNams;
  static Vector<MFrequency> linePos;
  // </group>
  // Sources table data
  // <group>
  static Bool srcNeedInit;
  static Vector<String> srcNams;
  static Vector<MDirection> srcPos;
  // </group>
  // IGRF data
  // <group>
  static Double timeIGRF;
  static Double dtimeIGRF;
  static Double time0IGRF;
  static Double firstIGRF;
  static Double lastIGRF;
  static Vector<Double> coefIGRF;
  static Vector<Double> dIGRF;
  static Vector<Double> resIGRF;
  // </group>
  // Aipsrc registration (for speed) of use of iau2000 and if so
  // the 2000a version
  // <group>
  static uInt iau2000_reg;
  static uInt iau2000a_reg;
  // </group>

};


} //# NAMESPACE CASA - END

#endif
