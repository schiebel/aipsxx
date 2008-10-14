//# DOatmosphere.h: Define the atmosphere DO
//# Copyright (C) 1996,1997,1998,1999,2000,2001
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

#ifndef APPSGLISH_DOATMOSPHERE_H
#define APPSGLISH_DOATMOSPHERE_H

#include <casa/aips.h>
#include <tasking/Tasking.h>
#include <casa/BasicSL/String.h>
#include <synthesis/MeasurementComponents/Atmosphere.h>
#include <casa/Arrays/Array.h>
#include <casa/Quanta/Quantum.h>

namespace casa { //#Begin casa namespace
// <summary> 
// atmosphere: atmosphere class, the basis for atmospheric
// calculations based on atmospheric models for mm radio observations
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="" demos="">

// <prerequisite>
//   <li> <linkto class="skyImpl">skyImpl</linkto> module
// </prerequisite>
//
// <etymology>
// From "atmosphere".
// </etymology>
//
// <synopsis>
// This DO defines the atmospheric calculations needed for 
// the estimating effects of the water, oxygen etc.. in the 
// atmosphere. These are needed for mm wave calibration,
// data editing etc 
//  
// 
// </etymology>
//
// <example>
// <srcblock>
// </srcblock>
// </example>
//
// <motivation>
// Support for mm radio astronomy with ALMA in sight
//  
//
// </linkto>.
// </motivation>
//
// <todo asof="01/12/05">
// Get newer models that include O3 etc ...
// Also data for different latitudes
// </todo>

using namespace std;

/**
 *
 * The class atmosphere is the DO interface for the FORTRAN ATM library
 * written by Juan R. Pardo.
 *
 */

class atmosphere : public ApplicationObject
{

 public:

  //-------------------------------------------------------------------
  /**
   * Constructor:
   *  setup things in the atmosphere that are not supposed to change fast
   *  with time and water content.

   *  Builds the atmospheric profile with a guessed startup water content.
   *  \par
   *  Calls fortran subroutine ATM_telluric()
   *
   *  @param altitude    at site in [m]
   *  @param temperature at site in [K]
   *  @param pressure    at site in [Pa]
   *  @param maxAltitude to top of modelled atmosphere in [m]
   *  @param humidity    percent humidity used to guess water content
   *  @param dTem_dh     change ot T with height in [K/m]
   *  @param dP          initial pressure step (P[1]-P[0]) in [Pa]
   *  @param dPm         pressure multiplicative factor for steps : P[i+1]-P[i] = dPm * ( P[i]-P[i-1]) 
   *  @param h0          scale height for water (exp distribution) in [m]
   *  @param atmType     One of:
   *   - 1: tropical
   *   - 2: mid latitude summer
   *   - 3: mid latitude winter
   *   - 4: subarctic summer
   *   - 5: subarctic winter
   *
   * @exception -         invalid parameters. 
   * @exception -         too many atmosphere layers  
   */
  //-------------------------------------------------------------------

  atmosphere(const Quantity &altitude, 
	     const Quantity &temperature,
	     const Quantity &pressure,
	     const Quantity &maxAltitude,
	     const Double &humidity,
	     const Quantity &dTem_dh,
	     const Quantity &dP,
	     const Double &dPm,
	     const Quantity &h0,
	     const Int &atmType);


  //---------------------------------------------------------------------
  /// Destructor
  //---------------------------------------------------------------------

  ~atmosphere();


  //---------------------------------------------------------------------
  // Methods
  //---------------------------------------------------------------------


  //-------------------------------------------------------------------
  // getStartupWaterContent()
  // ------------------------
  /**
   *  Get the guessed startup water content computed by initatmosphere()
   * @return 
   *  precWater  - guessed precipitable water content in [m]
   */
  //-------------------------------------------------------------------
  Quantity getStartupWaterContent() const;


  //-------------------------------------------------------------------
  // getProfiles()
  //-------------------------------------------------------------------
  /**
   * Get atmospheric profile for layers [1:natmlayers]
   *
     @param[out] thickness        [m]
     @param[out] temperature      [K]
     @param[out] water            [Kg/m^3]
     @param[out] pressure         [mbar]
     @param[out] O3               [m^-3]
     @param[out] CO               [m^-3]
     @param[out] N2O              [m^-3]
   */
  void getProfile(Quantum<Vector<Double> > &thickness,
		  Quantum<Vector<Double> > &temperature,
		  Quantum<Vector<Double> > &water,
		  Quantum<Vector<Double> > &pressure,
		  Quantum<Vector<Double> > &O3,
		  Quantum<Vector<Double> > &CO,
		  Quantum<Vector<Double> > &N2O) const;
  //-------------------------------------------------------------------
  

  //-------------------------------------------------------------------
  //  initWindow()
  //  -----------
  //
  /**
   *    Define a spectral window, compute absorption and emission
   *    coefficients for this window, using the above atmospheric
   *    parameters.
   *
   *    Calls fortran subroutine INI_telluric()
   * \param[in]   nbands    - number of bands ( = num of vector elements)
   * \param[in]   fCenter   - (sky) frequencies [Hz]
   * \param[in]   fWidth    - frequency widths [Hz]
   * \param[in]   fRes      - resolution inside band [Hz]
   * @exception -  invalid parameters
   */
  void initWindow(const Int nbands,
		  const Quantum<Vector<Double> > &fCenter,//const double fCenter[],
		  const Quantum<Vector<Double> > &fWidth, //const double fWidth[],
		  const Quantum<Vector<Double> > &fRes);  //const double fRes[]);


  //-------------------------------------------------------------------
  // getNdata()
  // -----------
  /**
   *  Return the number of channels of ith band
   *  @param[in]  iband     - identifier of band 
   *  @return     ndata     - number of channels
   *  @exception  - invalid parameters
   */
  Int getNdata(const Int iband) const;


  //-------------------------------------------------------------------
  //  getOpacity()
  //  ------------
  /**  Get the integrated optical depth of each frequency band [1:nbands]
   *  
   *   @param[out] dryOpacity - dry opacity for each frequency band
   *   @param[out] wetOpacity - opacity for each frequency band [per millimeter of precipitable water vapor]
   */
  void getOpacity(Vector<Double> &dryOpacity, Quantum<Vector<Double> > &wetOpacity) const ;


  //-------------------------------------------------------------------
  //  getOpacitySpec()
  //  ----------------
  /**  Get the integrated optical depth for each channel of each band
   *   [1:nbands][1:ndata].
   *
   *   @param[out] dryOpacitySpec - dry opacity for each channel of each frequency band
   *   @param[out] wetOpacitySpec - opacity for each channel of each frequency band [per millimeter of precipitable water vapor]
   */
  void getOpacitySpec(Array<Double> &dryOpacitySpec, Quantum<Array<Double> > &wetOpacitySpec) const;

  //-------------------------------------------------------------------
  //  getAbsCoeff()
  //  -------------
  /**
   * Get absorption coefficients for each band, for each channel of band
   * (???, for each atmospheric layer [1:natmlayers] ???)[1:ndata][1:nbands].
   * Units are [m^-1].
   *
     @param[out] kH2OLines  - H2O lines
     @param[out] kH2OCont   - H2O continuum
     @param[out] kO2        - O2 lines
     @param[out] kDryCont   - dry continuum
     @param[out] kO3        - O3 minor gases
     @param[out] kCO        - CO   "
     @param[out] kN2O       - N2O  "
   */
  //void  getAbsCoeff(AbsCoeff &) const;
  void getAbsCoeff(Quantum<Vector<Double> > &kH2OLines,
		   Quantum<Vector<Double> > &kH2OCont,
		   Quantum<Vector<Double> > &kO2,
		   Quantum<Vector<Double> > &kDryCont,
		   Quantum<Vector<Double> > &kO3,
		   Quantum<Vector<Double> > &kCO,
		   Quantum<Vector<Double> > &kN2O) const;

  //-------------------------------------------------------------------
  // getAbsCoeffDer
  // --------------
  /**
   * Get derivative of absorption coefficients for each band,
   * for each channel of each band
   * (???, for each atmospheric layer [1:natmlayers] ???)[1:ndata][1:nbands].
   * Units are [m^-1].
   *
     @param[out] kH2OLinesDer  - H2O lines
     @param[out] kH2OContDer   - H2O continuum
     @param[out] kO2Der        - O2 lines
     @param[out] kDryContDer   - dry continuum
     @param[out] kO3Der        - O3 minor gases
     @param[out] kCODer        - CO   "
     @param[out] kN2ODer       - N2O  "
   */
  void  getAbsCoeffDer(Quantum<Vector<Double> > &kH2OLinesDer,
		       Quantum<Vector<Double> > &kH2OContDer,
		       Quantum<Vector<Double> > &kO2Der,
		       Quantum<Vector<Double> > &kDryContDer,
		       Quantum<Vector<Double> > &kO3Der,
		       Quantum<Vector<Double> > &kCODer,
		       Quantum<Vector<Double> > &kN2ODer) const;
         
  //-------------------------------------------------------------------
  // getPhaseFactor()
  // ----------------
  //
  /**  
   *   Get dispersive and non-dispersive phase delay factor for each frequency
   *   band [1:nband].  Units are [deg/mm].
   *   @param[out] dispPhase 
   *   @param[out] nonDispPhase
   */
  void getPhaseFactor(Quantum<Vector<Double> > &dispPhase,
		      Quantum<Vector<Double> > &nonDispPhase) const ;


  //-------------------------------------------------------------------
  // computeSkyBrightness()
  // ----------------------
  /**
   * Compute atmospheric brightness by integrating the transfer equation.
   * Calls  fortran subroutine SPE_telluric()
   *
     @param[in] airMass   - Air mass
     @param[in] tbgr      - Temperature of cosmic background in [K]
     @param[in] precWater - Precipitable water content in [m]
   *
   *  @exception -  no spectral band initialized
   *  @exception -  invalid parameters
   */
  void computeSkyBrightness(const Double &airMass,
			    const Quantity &tbgr,
			    const Quantity &precWater);



  //-------------------------------------------------------------------
  // getSkyBrightness()
  // ----------------------
  //
  /**
   *  Get sky brightness computed by method computeSkyBrightness().
   *  Computed for each frequency band [1:nbands].  Units are [K].
   *
     @param[in] temperatureType - One of:
   *  - 1:  selects blackbody temperature
   *  - 2:  selects Rayleigh Jeans temperature
   * @return
   *    Quantum<Vector<Double>  Tspec
   */
  Quantum<Vector<Double> > getSkyBrightness(const Int temperatureType);



  //-------------------------------------------------------------------
  // getSkyBrightnessSpec()
  // ----------------------
  /**
   *  Get sky brightness by integrating the transfer equation of each channel
   *  for each frequency band [1:nbands][1:ndata].  Units are [K]
     @param[in] temperatureType - One of:
   *    -     1:  selects blackbody temperature
   *    -     2:  selects Rayleigh Jeans temperature
   * @return
   *    Quantum<Array<Double>  Tspec
   */
  Quantum<Array<Double> > getSkyBrightnessSpec(const Int temperatureType);



 //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 /**
  * Set sky coupling
  */
  void   setSkyCoupling(const float c);

 /**
  * Retrieve sky coupling
  */
  float  getSkyCoupling();


  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 private:

  /// Inaccessible copy constructor and assignment operator
  atmosphere(const atmosphere& atm);
  atmosphere& operator=(const atmosphere& atm);
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  // Methods enum
  enum methods{GETSTARTUPWATERCONTENT, GETPROFILEVAL,
	       GETPROFILEREF, INITWINDOW, GETNDATA,
	       GETOPACITYVAL, GETOPACITYREF,
	       GETOPACITYSPECVAL, GETOPACITYSPECREF,
	       GETABSCOEFFVAL, GETABSCOEFFREF,
	       GETABSCOEFFDERVAL, GETABSCOEFFDERREF,
	       GETPHASEFACTORVAL, GETPHASEFACTORREF,
	       COMPUTESKYBRIGHTNESS, GETSKYBRIGHTNESS,
	       GETSKYBRIGHTNESSSPEC, COMPUTEWATERVAPORCOLUMN,
	       SETSKYCOUPLING, GETSKYCOUPLING,
	       NUM_METHODS};

  enum notrace_methods{NT_GETSTARTUPWATERCONTENT, NT_GETPROFILEVAL,
		       NT_GETPROFILEREF, NT_INITWINDOW, NT_GETNDATA,
		       NT_GETOPACITYVAL, NT_GETOPACITYREF,
		       NT_GETOPACITYSPECVAL, NT_GETOPACITYSPECREF,
		       NT_GETABSCOEFFVAL, NT_GETABSCOEFFREF,
		       NT_GETABSCOEFFDERVAL, NT_GETABSCOEFFDERREF,
		       NT_GETPHASEFACTORVAL, NT_GETPHASEFACTORREF,
		       NT_COMPUTESKYBRIGHTNESS, NT_GETSKYBRIGHTNESS,
		       NT_GETSKYBRIGHTNESSSPEC, NT_COMPUTEWATERVAPORCOLUMN,
		       NT_SETSKYCOUPLING, NT_GETSKYCOUPLING,
		       NUM_NOTRACE_METHODS};


  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   // Methods required to distribute the class as an aips++ DO
   // i) return the class name
   virtual String className() const;

   // ii) return a list of class methods
   virtual Vector <String> methods() const;

   // iii) return a list of methods for which no logging is required
   virtual Vector <String> noTraceMethods() const;
   
   // iv) Execute individual methods
   virtual MethodResult runMethod (uInt which, ParameterSet& inpRec,
      Bool runMethod);

 private:

   Atmosphere *itsAtm; 

 };

  //-------------------------------------------------------------------
  // atmosphereFactory
  // ------------------------
  /**
   * Mechanism to allow non-standard constructors for class
   * atmosphere as an aips++ distributed object.
   */
  //-------------------------------------------------------------------
class atmosphereFactory : public ApplicationObjectFactory
{
 public:
  //-------------------------------------------------------------------
  // make()
  // ------------------------
  /**
   * Override make for non-standard constructors.
   */
  //-------------------------------------------------------------------
   virtual MethodResult make (ApplicationObject*& newObject,
      const String& whichConstructor, ParameterSet& inpRec,
      Bool runConstructor);
 };

} //# End casa namespace

#endif
