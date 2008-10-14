//#---------------------------------------------------------------------------
//# VelTracker.cc: Class to track velocity
//#---------------------------------------------------------------------------
//# Copyright (C) 1994-2005
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
//# $Id: VelTracker.cc,v 19.9 2005/07/27 01:03:31 mcalabre Exp $
//#---------------------------------------------------------------------------

#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/Constants.h>
#include <casa/Quanta/MVPosition.h>
#include <casa/Quanta/QC.h>
#include <casa/Quanta/Quantum.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MeasConvert.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MRadialVelocity.h>

#include <VelTracker.h>

#include <casa/namespace.h>

//----------------------------------------------------- VelTracker::VelTracker

// Constructor.

VelTracker::VelTracker(
  const Bool   rescale,
  const String inFrame,
  const String outFrame,
  const Vector<Double> antPos,
  const Int    nChan,
  const Double freqInc)
{
  cDoRescale = rescale;
  cDoShift = inFrame != outFrame;
  cFFTserver = 0;

  if (cDoShift) {
    // Translate input Doppler frame name for MRadialVelocity.
    String frame = inFrame;
    if (inFrame == "TOPOCENT") {
      frame = "TOPO";
    } else if (inFrame == "GEOCENTR") {
      frame = "GEO";
    } else if (inFrame == "BARYCENT") {
      frame = "BARY";
    } else if (inFrame == "GALACTOC") {
      frame = "GALACTO";
    } else if (inFrame == "LOCALGRP") {
      frame = "LGROUP";
    } else if (inFrame == "CMBDIPOL") {
      frame = "CMB";
    } else if (inFrame == "SOURCE") {
      frame = "REST";
    }

    // Point at rest in the input frame.
    MRadialVelocity::Types inFrameType;
    MRadialVelocity::getType(inFrameType, frame);
    MRadialVelocity restVel(Quantity(0, "m/s"), inFrameType);

    // Partially define the Doppler tracker.
    cConverter.setModel(restVel);

    // Partially define the velocity output reference frame.
    MPosition position((MVPosition(antPos)), MPosition::ITRF);
    cOutFrameParms.set(position);

    // Translate output Doppler frame name.
    frame = outFrame;
    if (outFrame == "TOPOCENT") {
      frame = "TOPO";
    } else if (outFrame == "GEOCENTR") {
      frame = "GEO";
    } else if (outFrame == "BARYCENT") {
      frame = "BARY";
    } else if (outFrame == "GALACTOC") {
      frame = "GALACTO";
    } else if (outFrame == "LOCALGRP") {
      frame = "LGROUP";
    } else if (outFrame == "CMBDIPOL") {
      frame = "CMB";
    } else if (outFrame == "SOURCE") {
      frame = "REST";
    }

    // Partially define the output Doppler reference frame type.
    MRadialVelocity::Types outFrameType;
    MRadialVelocity::getType(outFrameType, frame);
    cOutRef.setType(outFrameType);

    // Number of spectral channels.
    cNChan = nChan;

    // FFT work arrays.
    cLag.resize(cNChan/2 + 1);
    cFFTserver = new FFTServer<Float, Complex>(IPosition(1,cNChan));

    // Set the reference frequency to an integer multiple of this channel
    // increment (in Hz) when rescaling the frequency axis.  For Parkes and
    // Mopra data the value is adjusted to 1024 MHz divided by an integer
    // power of 2 (the only possible channel spacings for ATNF correlators)
    // to account for the possibility that Doppler tracking may have been
    // enabled in TCS.
    Double s = 1024e6 / abs(freqInc);
    cFreqInc = 1024e6 / pow(2.0, Double(Int(log(s)/log(2.0) + 0.5)));

    // If the adjustment amounted to more than 0.0002 (which exceeds the
    // maximum Doppler factor for the Topocentric - LSRK correction) then it
    // is probably foreign data (e.g. ALFA) with a non-ATNF channel spacing.
    if (abs((cFreqInc - freqInc) / freqInc) > 0.0002) {
       cFreqInc = abs(freqInc);
    }

    // Account for frequency switched observations.
    cRefFreq = -1.0;
  }
}

//---------------------------------------------------- VelTracker::~VelTracker

// Destructor.

VelTracker::~VelTracker(void)
{
  delete cFFTserver;
}

//-------------------------------------------------------- VelTracker::correct

// Doppler shift the spectrum using FFT.

void VelTracker::correct(
  const Double time,
  const Vector<Double> &raDec,
  const Double refFreq,
  const Double freqInc,
  Double &newRefFreq,
  Double &newFreqInc,
  Double &chanShift,
  Vector<Float> &spectrum)
{
  newRefFreq = refFreq;
  newFreqInc = freqInc;
  chanShift  = 0.0;

  if (cDoShift) {
    // Compute Doppler velocity as a fraction of the speed of light.
    Double beta = findVelocity(time, raDec) / C::c;

    if (cDoRescale) {
      // Rescale the frequency axis; this is the right way to do it.  The
      // Doppler relativistic formula is
      //
      //   f' =  f * K
      //
      // whence
      //
      //  df' = df * K
      //
      // where f is the observed (e.g. topocentric) frequency, f' is the
      // frequency in the new frame of reference (e.g. LSRK), and
      //
      //    K = sqrt((1-beta)/(1+beta)).
      //
      // At low velocities this reduces to
      //
      //   K ~= 1 - beta.
      //
      // The velocity (beta) is positive for motion towards the new frame of
      // reference in which case f' < f.

      Double scale = sqrt((1.0 - beta)/(1.0 + beta));
      newRefFreq *= scale;
      newFreqInc *= scale;

      // Having rescaled the frequency axis we now want to adjust it slightly
      // so that the reference frequency is an integer multiple of the
      // frequency increment, cFreqInc, specified to the constructor.  This
      // guarantees consistency between the spectra in each scan.  It also
      // facilitates combining different scans by allowing alignment of the
      // spectra in one scan with those of other scans to within an integer
      // channel shift.

      if (cRefFreq < 0.0) {
        // Force frequency grid alignment.
        Double sInc = newRefFreq / cFreqInc;
        Int nInc = Int(sInc + 0.5);
        cRefFreq = nInc * cFreqInc;
      }

      // Required fractional channel shift.
      chanShift = (newRefFreq - cRefFreq)/newFreqInc;

      newRefFreq = cRefFreq;

    } else {
      // Just shift the spectrum; this HIPASS/ZOA method is an approximation
      // because it does not take into account the change in channel spacing:
      //
      //    f' - f = (K - 1) * f
      //
      // i.e. the Doppler frequency shift is proportional to the observed
      // frequency.  It also uses the low velocity Doppler formula
      //
      //    f' - f ~= -beta * f.
      //
      // For HIPASS/ZOA the fixed frequency shift was computed from the HI
      // line rest frequency,
      //
      //    shift = -beta * f0.
      //
      // Since f0 is towards one end of the HIPASS/ZOA spectrum, using it
      // rather than the central reference frequency accentuates the error at
      // the far end of the spectrum.  The error is
      //
      //    error = -beta(f0 - f)
      //
      // which for the worse case Doppler velocity of 50 km/s and frequency
      // separation of 58MHz amounts to about 2 km/s or 0.15 of the 62.5kHz
      // channel.  This error would be roughly halved by using the reference
      // frequency.

      // HI line rest frequency.
      Double restFreq = QC::HI.get("Hz").getValue();

      // If the reference frequency is within 100MHz of the HI line then
      // use the HI line rest frequency for compatibility with HIPASS/ZOA.
      if (fabs(refFreq - restFreq) < 100e6) {
        chanShift = -beta * restFreq / freqInc;
      } else {
        chanShift = -beta * refFreq / freqInc;
      }
    }


    if (abs(chanShift) < 0.0001) {
      // Ignore this trivial shift.
      chanShift = 0.0;

    } else {
      // Transform spectrum to lag domain.
      cFFTserver->fft0(cLag, spectrum);

      // Compute phase gradient: positive gradient shifts right.
      Float phaseGradient = C::_2pi * (chanShift/cNChan);

      // Apply phase gradient.
      for (Int i = 1; i < cNChan/2 + 1; i++) {
        Float amp = abs(cLag(i));
        Float pha = arg(cLag(i)) - phaseGradient*Float(i);

        cLag(i) = polar(amp, pha);
      }

      // Transform phase-shifted lag spectrum back to frequency domain.
      cFFTserver->fft0(spectrum, cLag);
    }
  }
}

//--------------------------------------------------- VelTracker::findVelocity

// Find the difference in velocity between the observatory and the selected
// velocity reference frame.

Double VelTracker::findVelocity(const Double time, const Vector<Double> raDec)
{
  // Complete the definition of the output Doppler reference frame.
  Double ra  = raDec(0);
  Double dec = raDec(1);
  MDirection sourcePosi((MVDirection(Quantity(ra,"rad"), Quantity(dec,"rad"))),
                        MDirection::J2000);

  MEpoch obsTime((MVEpoch(Quantity(time, "s"))), MEpoch::UTC);

  cOutFrameParms.set(sourcePosi, obsTime);
  cOutRef.set(cOutFrameParms);

  // Complete the definition of the output Doppler tracker.
  cConverter.setOut(cOutRef);

  // Use it.
  return cConverter().get("m/s").getValue();
}
