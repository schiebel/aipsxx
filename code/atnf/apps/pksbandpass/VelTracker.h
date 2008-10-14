//#---------------------------------------------------------------------------
//# VelTracker.h: Class to track velocities.
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
//# $Id: VelTracker.h,v 19.8 2005/07/27 01:03:31 mcalabre Exp $
//#---------------------------------------------------------------------------

#ifndef ATNF_VELTRACKER_H
#define ATNF_VELTRACKER_H

#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/Complex.h>
#include <measures/Measures/MeasConvert.h>
#include <measures/Measures/MeasFrame.h>
#include <measures/Measures/MRadialVelocity.h>
#include <scimath/Mathematics/FFTServer.h>

#include <casa/namespace.h>

class VelTracker {
public:
  VelTracker(const Bool   rescale,
             const String inFrame,
             const String outFrame,
             const Vector<Double> antPos,
             const Int    nChan,
             const Double freqInc);

  ~VelTracker();

  void correct(const Double time,
               const Vector<Double> &raDec,
               const Double refFreq,
               const Double freqInc,
               Double &newRefFreq,
               Double &newFreqInc,
               Double &chanShift,
               Vector<Float> &spectrum);

private:
  // True if rescaling of the frequency axis is allowed.
  Bool cDoRescale;

  // False if an identity transformation was requested.
  Bool cDoShift;

  // Number of spectral channels.
  Int cNChan;

  // Set the reference frequency to an integer multiple of this channel
  // increment (in Hz) when rescaling the frequency axis.
  Double cFreqInc;

  // Reference frequency used when rescaling the frequency axis.
  Double cRefFreq;

  // Internal variables for computing the velocity shift.
  MeasFrame cOutFrameParms;
  MRadialVelocity::Ref cOutRef;
  MRadialVelocity::Convert cConverter;

  // Internal variables for performing the FFT.
  FFTServer<Float, Complex> *cFFTserver;
  Vector<Complex> cLag;

  Double findVelocity (const Double time, const Vector<Double> raDec);
};
#endif
