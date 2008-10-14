//#---------------------------------------------------------------------------
//# ObservingFilter.h: Class to apply various filters to Multibeam data
//#---------------------------------------------------------------------------
//# Copyright (C) 2003-2004
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
//# $Id: ObservingFilter.h,v 19.7 2004/11/30 17:50:10 ddebonis Exp $
//#---------------------------------------------------------------------------

#ifndef ATNF_OBSERVINGFILTER_H
#define ATNF_OBSERVINGFILTER_H

#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <lattices/Lattices/Lattice.h>
#include <casa/BasicSL/Complex.h>
#include <scimath/Mathematics/FFTServer.h>

#include <casa/namespace.h>
class ObservingFilter {
public:
  // Default constructor.
  ObservingFilter();

  // Destructor.
  ~ObservingFilter();

  // Calculate a model of time-varying baseline ripple using a Briggs-like
  // phase tracking filter.  See Briggs et al., 1997, PASA 14, 37 for details.
  // This implementation is based on that, but includes some slight changes to
  // improve robustness to RFI etc.
  Matrix<Float> briggsHarmonicModel(const Matrix<Float> &inData,
                                    const Vector<Int> &harmonics,
                                    const Vector<Float> &model_harmonic_amps);

  // Set some flags in the current frequency frame, flagging the channel
  // closest to the specified frequency in Hz.  refFreq is ASSUMED to apply
  // to channel Int(nchannels/2); deltaFreq gives the pixel increment in
  // frequency, and flagFreq indicates which frequency -> channel to flag.
  Bool flagInFrame(Matrix<uChar> &flagtra,
                   const Double flagFreq,
                   const Double refFreq,
                   const Double deltaFreq);

  // Interpolate along spectral axis where flags are set.  Typically this is
  // required before applying a global filter to the data.  Three different
  // versions given for different input topologies.  nIntegrations is required
  // in the last form as the matrices may be larger than the data volume.
  Bool specInterpolate1D(Matrix<Float> &spectra,
                         Matrix<uChar> &flagtra);
  Bool specInterpolate1D(Vector<Float> &spectrum,
                         Vector<uChar> &flagtrum);
  Bool specInterpolate1D(Matrix<Matrix<Float> > &lSpecIn,
                         Matrix<Matrix<uChar> > &lFlagIn,
                         const uInt &nIntegrations);

  // Grow flags along the spectral axis by +/- the specified number of
  // channels.  This would be used following application of a global filter,
  // as a smooth for example will increase the width of a flagged channel.
  Bool specGrowFlags(Matrix<uChar> &flagtra, const uInt delta);

  // Move and grow flags based on a non-integer channel shift.  This might be
  // used where a velocity track has taken place, which shifts data within the
  // vector.  Any non-integer shift may also increase the width of a flagged
  // channel.  When shift != 0, all flagged channels are grown by one channel.
  Bool shiftFlags(Vector<uChar> &flagtrum, const Double shift);

  // Apply knowledge-based and transient flagging.  This method is incomplete
  // as of Oct 2003 and SHOULD NOT BE USED for non-experimental processing.
  Bool transientFlagging(Matrix<Vector<Float> > &lTsysIn,
                         Matrix<Matrix<Float> > &lSpecIn,
                         Matrix<Matrix<uChar> > &lFlagIn,
                         const Int &nIntegrations);

private:
  FFTServer<Float,Complex> fft;

  void cfft(Lattice<Complex>& lattice,
            const Vector<Bool>& whichAxes,
            const Bool toFrequency);
};

#endif /* ATNF_OBSERVINGFILTER_H */
