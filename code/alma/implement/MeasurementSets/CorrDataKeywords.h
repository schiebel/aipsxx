//# CorrDataKeywords.h: Convert and process CORRDATA-ALMATI FITS keywords
//# Copyright (C) 1996,1997,1998,1999,2001,2002
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
//# Correspondence concerning AIPS++ should be adressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#
//# $Id: CorrDataKeywords.h,v 19.4 2004/11/30 17:50:06 ddebonis Exp $

#ifndef ALMA_CORRDATAKEYWORDS_H
#define ALMA_CORRDATAKEYWORDS_H

// Include files
#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <measures/Measures/MFrequency.h>
#include <measures/Measures/MRadialVelocity.h>
#include <measures/Measures/Stokes.h>
#include <casa/BasicMath/Math.h>
#include <fits/FITS/fits.h>

#include <msvis/MSVis/StokesVector.h>

#include <casa/namespace.h>
// <summary> 
// CorrDataKeywords: process CORRDATA-ALMATI FITS keywords
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="" demos="">

// <prerequisite>
//   <li> <linkto class="AlmaTI2MS">AlmaTI2MS</linkto> module
// </prerequisite>
//
// <etymology>
// From "CORRDATA-ALMATI" and keywords
// </etymology>
//
// <synopsis>
// This class processes and holds FITS keywords from the CORRDATA-ALMATI
// binary table extension, as defined in the ALMA-TI data format. This
// is a helper class for AlmaTI2MS.
// </synopsis>
//
// <example>
// <srcblock>
// </srcblock>
// </example>
//
// <motivation>
// Encapsulate all keyword processing and access for CORRDATA-ALMATI tables
// </motivation>
//
// <todo asof="01/09/15">
// (i) 
// </todo>
//
// $Id: CorrDataKeywords.h,v 19.4 2004/11/30 17:50:06 ddebonis Exp $

class CorrDataKeywords
{
 public:
  // Enum for LO number (LO1 and LO2)
  enum lo {
    LO1=0,
    LO2=1};

  // Enum for sideband type (LSB or USB)
  enum sideBand {
    LSB=0,
    USB=1};

  // Enum for line identifier and rest frequency pair (A or B)
  enum line {
    A=0,
    B=1};

  // Construct from a const FITS keyword list
  CorrDataKeywords(ConstFitsKeywordList& kwl);

  // Destructor
  ~CorrDataKeywords() {};
  
  // Data accessor methods
  //
  // Scan number
  Int scanNum() {return itsScanNum;};

  // Observation number
  Int obsNum() {return itsObsNum;};

  // Number of polarization products
  Int nPolznCorr() {return itsNPolznCorr;};

  // Number of side bands
  Int nSideBand() {return itsNSideBand;};

  // Number of LO's
  Int nLO() {return itsNLO;};

  // Number of phase correction axes
  Int nPhasCorr() {return itsNPhasCorr;};

  // Number of channels
  Int nChan() {return itsNChan;};

  // Baseband number
  Int baseBandNo() {return itsBaseBandNo;};

  // Table id.
  Int tableId() {return itsTableId;};

  // LO1/2 information: frequency and sideband for (LO1, LO2)
  Bool isLOPresent(const lo& loEnum) {return itsLOPresent(loEnum);};
  MFrequency freqLO(const lo& loEnum) {return itsFreqLO(loEnum);};
  Int loSideBand(const lo& loEnum) {return itsLOSideBand(loEnum);};

  // Intermediate frequency at reference channel
  MFrequency intermediateFreq() {return itsIntermediateFreq;};

  // Flux density (I, Q, U, V) as Stokes vector
  CStokesVector fluxDensity() {return CStokesVector(itsFluxDensity(0), 
						    itsFluxDensity(1),
						    itsFluxDensity(2),
						    itsFluxDensity(3));};
  Bool isFluxDensityPresent() {return itsFluxDensityPresent;};

  // Rest frequency and line identifiers (lines A and B)
  Bool isLinePresent(const line& lineEnum) {return itsLinePresent(lineEnum);};
  MFrequency restFreq(const line& lineEnum) {return itsRestFreq(lineEnum);};
  String lineName(const line& lineEnum) {return itsLineName(lineEnum);};

  // Indicate whether USB and/or LSB data are present
  Bool isSideBandPresent(const sideBand& sbEnum) 
    {return itsSideBandPresent(sbEnum);};

  // <group>
  // Frequency axis information: reference channel, reference frequency,
  // channel spacing and array of frequencies for (USB, LSB)
  Float refChan(const sideBand& sbEnum) {return itsRefChan(sbEnum);};
  MFrequency refFreq(const sideBand& sbEnum) {return itsRefFreq(sbEnum);};
  MVFrequency chanWidth(const sideBand& sbEnum) {return itsChanWidth(sbEnum);};
  // Return the frequency axis in the reference frequency frame (topocentric)
  Vector<MFrequency> chanFreq(const sideBand& sbEnum);
  // Compute the frequency axis in the LSRK frame using the rest frequency
  // and the source systemic velocity given in the CORRDATA-ALMATI table
  Bool chanFreqLSRK(const sideBand& sbEnum, Vector<MFrequency>& freqAxis);
  // Compute the frequency axis in the LSRK frame using the total Doppler
  // velocity (VFRAME) given in the DATAPAR-ALMATI table
  Bool chanFreqLSRK(const sideBand& sbEnum, const MRadialVelocity& dopVel,
		    Vector<MFrequency>& freqAxis);
  //</group>

  // Velocity axis information: reference channel, reference velocity, 
  // source systemic velocity and velocity channel spacing for (USB, LSB)
  Bool isVelocityPresent(const sideBand& sbEnum) 
    {return itsVelocityPresent(sbEnum);};
  Float velRefChan(const sideBand& sbEnum) {return itsVelRefChan(sbEnum);};
  MRadialVelocity refVel(const sideBand& sbEnum) {return itsRefVel(sbEnum);};
  MVRadialVelocity chanWidthVel(const sideBand& sbEnum) 
    {return itsChanWidthVel(sbEnum);};
  MRadialVelocity sysVel(const sideBand& sbEnum) { return itsSysVel(sbEnum);};

  // Stokes axis information: reference pixel, reference pixel value
  // and increment per pixel. The reference value is returned in FITS
  // form or as the associated AIPS++ Stokes enum value (in class Stokes).
  // The full Stokes axis is also available as a vector of Stokes enums.
  Float stokesRefPixel(const sideBand& sbEnum) 
    {return itsStokesRefPixel(sbEnum);};
  Float stokesFITSRefVal(const sideBand& sbEnum) 
    {return itsStokesRefVal(sbEnum);};
  Stokes::StokesTypes stokesRefVal(const sideBand& sbEnum) 
    {return Stokes::fromFITSValue(floor(itsStokesRefVal(sbEnum)));};
  Float stokesIncr(const sideBand& sbEnum) {return itsStokesIncr(sbEnum);};
  Vector<Int> stokesAxis(const sideBand& sbEnum);
  
  // Phase correction axis information: indicate if present for (LSB, USB)
  Bool isPhasCorrPresent(const sideBand& sbEnum) 
    {return itsPhasCorrPresent(sbEnum);};
  
 private:
  // Default constructor is prohibited - no useful object produced
  CorrDataKeywords();

  // Keyword values
  //
  // Scan number
  Int itsScanNum;

  // Observation number
  Int itsObsNum;

  // Number of polarization products
  Int itsNPolznCorr;

  // Number of side bands
  Int itsNSideBand;

  // Number of LO's
  Int itsNLO;

  // Number of phase correction axes
  Int itsNPhasCorr;

  // Number of frequency channels
  Int itsNChan;

  // Baseband number
  Int itsBaseBandNo;

  // Table id.
  Int itsTableId;

  // LO data (per LO1, LO2)
  Vector<Bool> itsLOPresent;
  Vector<MFrequency> itsFreqLO;
  Vector<Int> itsLOSideBand;

  // Intermediate frequency
  MFrequency itsIntermediateFreq;

  // Source flux density model
  Vector<Float> itsFluxDensity;
  Bool itsFluxDensityPresent;

  // Rest frequency and line identifiers (per line)
  Vector<Bool> itsLinePresent;
  Vector<MFrequency> itsRestFreq;
  Vector<String> itsLineName;

  // Flags to specify if a sideband is present or not (per sideband)
  Vector<Bool> itsSideBandPresent;

  // Frequency axes (per sideband)
  Vector<Float> itsRefChan;
  Vector<MFrequency> itsRefFreq;
  Vector<MVFrequency> itsChanWidth;

  // Velocity axes (per sideband)
  Vector<Bool> itsVelocityPresent;
  Vector<Float> itsVelRefChan;
  Vector<MRadialVelocity> itsRefVel;
  Vector<MVRadialVelocity> itsChanWidthVel;
  Vector<MRadialVelocity> itsSysVel;

  // Stokes axes (per sideband)
  Vector<Float> itsStokesRefPixel;
  Vector<Float> itsStokesRefVal;
  Vector<Float> itsStokesIncr;

  // Phase correction axes (per sideband)
  Vector<Bool> itsPhasCorrPresent;
};

#endif
