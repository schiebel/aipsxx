//# CorrDataKeywords.cc: Implementation of CorrDataKeywords.h
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
//# $Id: CorrDataKeywords.cc,v 19.1 2004/08/25 05:48:50 gvandiep Exp $
//----------------------------------------------------------------------------

#include <alma/MeasurementSets/CorrDataKeywords.h>

#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MDoppler.h>

//----------------------------------------------------------------------------

CorrDataKeywords::CorrDataKeywords(ConstFitsKeywordList& kwl) :
  itsScanNum(0),
  itsObsNum(0),
  itsNPolznCorr(0),
  itsNSideBand(0),
  itsNLO(0),
  itsNPhasCorr(0),
  itsNChan(0),
  itsBaseBandNo(0),
  itsLOPresent(2, False),
  itsFreqLO(2, MFrequency()),
  itsLOSideBand(2, USB),
  itsIntermediateFreq(),
  itsFluxDensity(4,0),
  itsFluxDensityPresent(False),
  itsLinePresent(2, False),
  itsRestFreq(2, MFrequency()),
  itsLineName(2, ""),
  itsSideBandPresent(2, False),
  itsRefChan(2, 0),
  itsRefFreq(2, MFrequency()),
  itsChanWidth(2, MVFrequency()),
  itsVelocityPresent(2, False),
  itsVelRefChan(2, 0),
  itsRefVel(2, MRadialVelocity()),
  itsChanWidthVel(2, MVRadialVelocity()),
  itsSysVel(2, MRadialVelocity()),
  itsStokesRefPixel(2,1.0),
  itsStokesRefVal(2,-5.0),
  itsStokesIncr(2,1.0),
  itsPhasCorrPresent(2, False)
{
// Construct from a FITS keyword list
// Input:
//    kwl                   ConstFitsKeywordList&   Input FITS keyword list
// Output to private data:
//    itsScanNum            Int            Scan number
//    itsObsNum             Int            Observation number
//    itsNPolznCorr         Int            Number of polarization correlations
//    itsNSideBand          Int            Number of side bands
//    itsNLO                Int            Number of LO's
//    itsNPhasCorr          Int            Number of phase correction axes
//    itsNChan              Int            Number of frequency channels
//    itsBaseBandNo         Int            Baseband number
//    itsLOPresent          Vec<Bool>      True if present (LO1,LO2)
//    itsFreqLO             Vec<MFreq>     LO frequency as Measure (LO1,LO2)
//    itsLOSideBand         Vec<sideBand>  LO sideband (LO1, LO2)
//    itsIntermediateFreq   MFrequency     Intermediate freq as Measure
//    itsFluxDensity        Vec<Float>     (I,Q,U,V) flux densities
//    itsFluxDensityPresent Bool           True if source flux density given
//    itsLinePresent        Vec<Bool>      True if line info given (A,B)
//    itsRestFrequency      Vec<MFreq>     Line rest frequency (A,B)
//    itsLineName           Vec<String>    Line identifier (A,B)
//    itsSideBandPresent    Vec<Bool>      True if sideband present (LSB,USB)
//    itsRefChan            Vec<Float>     Frequency ref channel (LSB,USB)
//    itsRefFreq            Vec<MFreq>     Reference frequency value (LSB,USB)
//                                         as Measure
//    itsChanWidth          Vec<MVFreq>    Frequency channel width (LSB,USB)
//                                         as Quantum
//    itsVelocityPresent    Vec<Bool>      True if vel axis given (LSB,USB)
//    itsVelRefChan         Vec<Float>     Velocity axis ref channel (LSB,USB)
//    itsRefVel             Vec<MRadVel>   Ref velocity as Measure (LSB,USB)
//    itsChanWidthVel       Vec<MVRadVel>  Velocity channel width (LSB,USB) 
//                                         as Quantum
//    itsSysVel             Vec<MRadVel>   Source systemic velocity (LSB,USB)
//                                         as Measure
//    itsStokesRefPixel     Vec<Float>     Stokes ref pixel (LSB,USB)
//    itsStokesRefVal       Vec<Float>     Stokes FITS ref value (LSB,USB)
//    itsStokesIncr         Vec<Float>     Stokes FITS increment (LSB,USB)
//    itsPhasCorrPresent    Vec<Bool>      True if on-line phase corrected 
//                                         data present (LSB,USB)
//
  // Translate the input FITS keyword list
  const FitsKeyword* kw;

  // Iterate through, extracting relevant keywords
  kwl.first();

  while ((kw = kwl.next())) {

    String kwname = kw->name();

    // Case keyword name of:
    //
    // SCAN-NUM
    if (kwname == "SCAN-NUM") {
      itsScanNum = kw->asInt();

      // OBS-NUM
    } else if (kwname == "OBS-NUM") {
      itsObsNum = kw->asInt();

      // NO_POL
    } else if (kwname == "NO_POL") {
      itsNPolznCorr = kw->asInt();

      // NO_SIDE
    } else if (kwname == "NO_SIDE") {
      itsNSideBand = kw->asInt();

      // NO_LO
    } else if (kwname == "NO_LO") {
      itsNLO = kw->asInt();

      // NO_PHCOR
    } else if (kwname == "NO_PHCOR") {
      itsNPhasCorr = kw->asInt();

      // CHANNELS
    } else if (kwname == "CHANNELS") {
      itsNChan = kw->asInt();

      // BASEBAND
    } else if (kwname == "BASEBAND") {
      itsBaseBandNo = kw->asInt();

      // TABLEID
    } else if (kwname == "TABLEID") {
      itsTableId = kw->asInt();

      // FREQLO1
    } else if (kwname == "FREQLO1") {
      itsLOPresent(LO1) = True;
      // Create a topocentric frequency Measure for the LO1 frequency
      MVFrequency freqHz(Quantity(kw->asDouble(), "Hz"));
      itsFreqLO(LO1) = MFrequency(freqHz, MFrequency::TOPO);

      // SIDEBLO1
    } else if (kwname == "SIDEBLO1") {
      itsLOSideBand(LO1) = kw->asInt() < 0 ? LSB : USB;

      // FREQLO2
    } else if (kwname == "FREQLO2") {
      itsLOPresent(LO2) = True;
      // Create a topocentric frequency Measure for the LO2 frequency
      MVFrequency freqHz(Quantity(kw->asDouble(), "Hz"));
      itsFreqLO(LO2) = MFrequency(freqHz, MFrequency::TOPO);

      // SIDEBLO2
    } else if (kwname == "SIDEBLO2") {
      itsLOSideBand(LO2) = kw->asInt() < 0 ? LSB : USB;

      // INTERFRE
    } else if (kwname == "INTERFRE") {
      MVFrequency freqHz(Quantity(kw->asDouble(), "Hz"));
      itsIntermediateFreq = MFrequency(freqHz, MFrequency::TOPO);

      // IFLUX
    } else if (kwname == "IFLUX") {
      itsFluxDensity(0) = kw->asFloat();
      itsFluxDensityPresent = True;

      // QFLUX
    } else if (kwname == "IFLUX") {
      itsFluxDensity(1) = kw->asFloat();
      itsFluxDensityPresent = True;

      // UFLUX
    } else if (kwname == "IFLUX") {
      itsFluxDensity(2) = kw->asFloat();
      itsFluxDensityPresent = True;

      // VFLUX
    } else if (kwname == "IFLUX") {
      itsFluxDensity(3) = kw->asFloat();
      itsFluxDensityPresent = True;

      // RESTFREA
    } else if (kwname == "RESTFREA") {
      itsLinePresent(A) = True;
      MVFrequency freqHz(Quantity(kw->asDouble(), "Hz"));
      itsRestFreq(A) = MFrequency(freqHz, MFrequency::REST);
      
      // TRANSITA
    } else if (kwname == "TRANSITA") {
      itsLineName(A) = kw->asString();

      // RESTFREB
    } else if (kwname == "RESTFREA") {
      itsLinePresent(B) = True;
      MVFrequency freqHz(Quantity(kw->asDouble(), "Hz"));
      itsRestFreq(B) = MFrequency(freqHz, MFrequency::REST);
      
      // TRANSITB
    } else if (kwname == "TRANSITA") {
      itsLineName(B) = kw->asString();

      // Frequency, velocity and phase correction axis coordinates (USB1)
      //
      // 1CTYP4
    } else if (kwname == "1CTYP4") {
      itsSideBandPresent(USB) = True;

      // 2CRPX4
    } else if (kwname == "2CRPX4") {
      itsRefChan(USB) = kw->asFloat();

      // 2CRVL4
    } else if (kwname == "2CRVL4") {
      MVFrequency freqHz(Quantity(kw->asDouble(), "Hz"));
      itsRefFreq(USB) = MFrequency(freqHz, MFrequency::TOPO);
      
      // 22CD4
    } else if (kwname == "22CD4") {
      itsChanWidth(USB) = MVFrequency(Quantity(kw->asFloat(), "Hz"));

      // 2CTYP4A
    } else if (kwname == "2CTYP4A") {
      itsVelocityPresent(USB) = True;
      
      // 2CRPX4A
    } else if (kwname == "2CRPX4A") {
      itsVelRefChan(USB) = kw->asFloat();

      // 2CRVL4A
    } else if (kwname == "2CRVL4A") {
      MVRadialVelocity velMS(Quantity(kw->asDouble(), "m/s"));
      itsRefVel(USB) = MRadialVelocity(velMS, MRadialVelocity::LSRK);

      // 22CD4A
    } else if (kwname == "22CD4A") {
      itsChanWidthVel(USB) = Quantity(kw->asFloat(), "m/s");

      // 2VSOU4A
    } else if (kwname == "2VSOU4A") {
      MVRadialVelocity velMS(Quantity(kw->asDouble(), "m/s"));
      itsSysVel(USB) = MRadialVelocity(velMS, MRadialVelocity::LSRK);

      // 3CRPX4
    } else if (kwname == "3CRPX4") {
      itsStokesRefPixel(USB) = kw->asFloat();

      // 3CRVL4
    } else if (kwname == "3CRVL4") {
      itsStokesRefVal(USB) = kw->asFloat();

      // 33CD4
    } else if (kwname == "33CD4") {
      itsStokesIncr(USB) = kw->asFloat();

      // 4CTYP4
    } else if (kwname == "4CTYP4") {
      itsPhasCorrPresent(USB) = True;

      // Frequency, velocity and phase correction axis coordinates (LSB1)
      //
      // 1CTYP5
    } else if (kwname == "1CTYP5") {
      itsSideBandPresent(LSB) = True;

      // 2CRPX5
    } else if (kwname == "2CRPX5") {
      itsRefChan(LSB) = kw->asFloat();

      // 2CRVL5
    } else if (kwname == "2CRVL5") {
      MVFrequency freqHz(Quantity(kw->asDouble(), "Hz"));
      itsRefFreq(LSB) = MFrequency(freqHz, MFrequency::TOPO);
      
      // 22CD5
    } else if (kwname == "22CD5") {
      itsChanWidth(LSB) = MVFrequency(Quantity(kw->asFloat(), "Hz"));

      // 2CTYP5B
    } else if (kwname == "2CTYP5B") {
      itsVelocityPresent(LSB) = True;
      
      // 2CRPX5B
    } else if (kwname == "2CRPX5B") {
      itsVelRefChan(LSB) = kw->asFloat();

      // 2CRVL5B
    } else if (kwname == "2CRVL5B") {
      MVRadialVelocity velMS(Quantity(kw->asDouble(), "m/s"));
      itsRefVel(LSB) = MRadialVelocity(velMS, MRadialVelocity::LSRK);

      // 22CD5B
    } else if (kwname == "22CD5B") {
      itsChanWidthVel(LSB) = Quantity(kw->asFloat(), "m/s");

      // 2VSOU5B
    } else if (kwname == "2VSOU5B") {
      MVRadialVelocity velMS(Quantity(kw->asDouble(), "m/s"));
      itsSysVel(LSB) = MRadialVelocity(velMS, MRadialVelocity::LSRK);

      // 3CRPX5
    } else if (kwname == "3CRPX5") {
      itsStokesRefPixel(LSB) = kw->asFloat();

      // 3CRVL5
    } else if (kwname == "3CRVL5") {
      itsStokesRefVal(LSB) = kw->asFloat();

      // 33CD5
    } else if (kwname == "33CD5") {
      itsStokesIncr(LSB) = kw->asFloat();

      // 4CTYP5
    } else if (kwname == "4CTYP5") {
      itsPhasCorrPresent(LSB) = True;
    };
  };
};

//----------------------------------------------------------------------------

Vector<MFrequency> CorrDataKeywords::chanFreq(const sideBand& sbEnum)
{
// Compute an array of frequency axis values for FITS channels [1,N]
// Input:
//    sbEnum        const sideBand&        Sideband number (LSB,USB)
// Output:
//    chanFreq      Vector<MFrequency>     Frequency axis as array of Measures
//
  // Initialization
  Vector<MFrequency> freqAxis(nChan());

  // Get reference frequency value and reference frame 
  MeasRef<MFrequency> refFrame = refFreq(sbEnum).getRef();
  MVFrequency refVal = refFreq(sbEnum).getValue();

  // Compute frequency axis for FITS frequency channels [1..N]
  MVFrequency chanVal;
  for (Int chan=0; chan<nChan(); chan++) {
    chanVal = ((chan+1) - refChan(sbEnum)) * chanWidth(sbEnum) + refVal;
    freqAxis(chan) = MFrequency(chanVal, refFrame);
  };
  
  return freqAxis;
};

//----------------------------------------------------------------------------

Bool CorrDataKeywords::chanFreqLSRK(const sideBand& sbEnum,
				    Vector<MFrequency>& freqAxis)
{
// Compute the frequency axis values in an LSRK frame
// Input:
//    sbEnum        const sideBand&        Sideband number (LSB,USB)
// Output:
//    freqAxis      Vector<MFrequency>     Frequency axis as array of Measures
//    chanFreqLSRK  Bool                   True if axis could be constructed,
//                                         else False.
//
  // Initialization
  Bool retval;

  // Compute the reference frequency value in an LSRK frame
  if (isLinePresent(A) && isVelocityPresent(sbEnum)) {
    MDoppler sysVelDop(sysVel(sbEnum).get("m/s"), MDoppler::RADIO);
    MFrequency refFreqLSRK =
      MFrequency::fromDoppler(sysVelDop, restFreq(A).getValue(), 
			      MFrequency::LSRK);
    MVFrequency refValLSRK = refFreqLSRK.getValue();

    // Fill the axis values (adopt the approximation that topocentric
    // and LSRK channel width are equal)
    freqAxis.resize(nChan());
    MVFrequency chanVal;
    for (Int chan=0; chan<nChan(); chan++) {
      chanVal = ((chan+1) - refChan(sbEnum)) * chanWidth(sbEnum) + refValLSRK;
      freqAxis(chan) = MFrequency(chanVal, MFrequency::LSRK);
    };
    retval = True;

  } else {
    // Insufficient information to construct an LSRK frequency axis
    retval = False;
  };
  return retval;
};

//----------------------------------------------------------------------------

Bool CorrDataKeywords::chanFreqLSRK(const sideBand& sbEnum,
				    const MRadialVelocity& dopVel,
				    Vector<MFrequency>& freqAxis)
{
// Compute the frequency axis values in an LSRK frame
// Input:
//    sbEnum        const sideBand&        Sideband number (LSB,USB)
//    dopVel        const MRadialVelocity& Total Doppler velocity
// Output:
//    freqAxis      Vector<MFrequency>     Frequency axis as array of Measures
//    chanFreqLSRK  Bool                   True if axis could be constructed,
//                                         else False.
//
  // Compute the reference frequency value in an LSRK frame
  // using the specified total Doppler velocity
  MDoppler sysVelDop(dopVel.get("m/s"), MDoppler::RADIO);
  MFrequency refFreqLSRK = 
    MFrequency::fromDoppler(sysVelDop, refFreq(sbEnum).getValue(),
			    MFrequency::LSRK);
  MVFrequency refValLSRK = refFreqLSRK.getValue();

  // Fill the axis values (adopt the approximation that topocentric
  // and LSRK channel width are equal)
  freqAxis.resize(nChan());
  MVFrequency chanVal;
  for (Int chan=0; chan<nChan(); chan++) {
    chanVal = ((chan+1) - refChan(sbEnum)) * chanWidth(sbEnum) + refValLSRK;
    freqAxis(chan) = MFrequency(chanVal, MFrequency::LSRK);
  };

  return True;
};

//----------------------------------------------------------------------------

Vector<Int> CorrDataKeywords::stokesAxis(const sideBand& sbEnum)
{
// Compute an array of Stokes enums defining the polarization axis
// Input:
//    sbEnum        const sideBand&        Sideband number (LSB,USB)
// Output:
//    stokesAxis    Vector<Int>            Vector of Stokes.h enums
//                                         defining the polarization axis
//
  // Initialization
  Vector<Int> stokes(nPolznCorr());
  Float fitsValue;

  // Compute the Stokes axis
  for (Int i=0; i < nPolznCorr(); i++) {
    fitsValue = ((i+1) - itsStokesRefPixel(sbEnum)) * itsStokesIncr(sbEnum) +
      itsStokesRefVal(sbEnum);
    stokes(i) = Stokes::fromFITSValue(floor(fitsValue));
  };
  
  return stokes;
};

//----------------------------------------------------------------------------
