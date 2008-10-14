//#---------------------------------------------------------------------------
//# ObservingFilter.cc: Class to apply smart filtering to Multibeam data
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
//# $Id: ObservingFilter.cc,v 19.7 2004/11/30 17:50:10 ddebonis Exp $
//#---------------------------------------------------------------------------

#include <ObservingFilter.h>

#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Arrays/MaskedArray.h>
#include <casa/Arrays/Slice.h>
#include <casa/Arrays/Vector.h>
#include <lattices/Lattices/ArrayLattice.h>
#include <lattices/Lattices/Lattice.h>
#include <lattices/Lattices/LatticeIterator.h>
#include <lattices/Lattices/TiledLineStepper.h>
#include <casa/BasicSL/Complex.h>
#include <casa/BasicSL/Constants.h>
#include <scimath/Mathematics/FFTServer.h>
#include <scimath/Functionals/ScalarSampledFunctional.h>
#include <scimath/Functionals/Interpolate1D.h>

#include <casa/stdio.h>
#include <casa/iostream.h>

#include <casa/namespace.h>

//------------------------------------------- ObservingFilter::ObservingFilter

// Default constructor.

ObservingFilter::ObservingFilter(void) {}

//------------------------------------------ ObservingFilter::~ObservingFilter

// Destructor.

ObservingFilter::~ObservingFilter(void) {}

//--------------------------------------- ObservingFilter::briggsHarmonicModel

// calculate model using a Briggs-like phase tracking filter

Matrix<Float> ObservingFilter::briggsHarmonicModel(
  const Matrix<Float> &inData,
  const Vector<Int> &harmonics,
  const Vector<Float> &model_harmonic_amps)

{
  //-cerr << "==================================================" << endl;
  //-cerr << "entering ObservingFilter::briggsHarmonicModel" << endl;

  // The following must be settable somewhere...
  Int trackwin_exp = 4; // typically 4
  Int trackwin_width_exp = 3; // typically 3
  Float threshold = 3.0;
  Float rho = -1.5;
  Int smoothing_width = 5; // typically 5


  Int ncycles = inData.nrow();
  Int nChan = inData.ncolumn();
  uInt nharms = harmonics.nelements();

  //-cerr << "ncycles = " << ncycles << ", nChan = " << nChan << ", nharms = " << nharms << endl;

  Vector<Bool> axes(2);
  axes(0) = False;
  axes(1) = True;

  Vector<Bool> shaxes(1);
  shaxes(0) = True;

  Bool forward = True;

  //-cerr << "input data mean = " << mean(inData) << endl;
  //-cerr << "input data median = " << median(inData) << endl;
  //-cerr << "input data min = " << min(inData) << endl;
  //-cerr << "input data max = " << max(inData) << endl;

  //-cerr << "fft'ing input data" << endl;

  Matrix<Complex> arrData(inData.shape());
  convertArray(arrData, inData);
  //RealToComplex(arrData, inData);
  ArrayLattice<Complex> latData(arrData);
  cfft(latData, axes, forward);

  Matrix<Complex> modData(ncycles, nChan);
  modData = Complex(0,0);
  // verifed that modData is correct.

  Int harm_centre = Int(nChan / 2) + 1 - 1; // 0-offset
  //-cerr << "harm_centre = " << harm_centre << endl;

  // loop over all the harmonics
  for (uInt i_harm = 0; i_harm < nharms; i_harm++) {
    Int hmnc = harmonics(i_harm);

    //-cerr << "processing harmonic " << hmnc << " ..." << endl;

    Vector<Complex> harmdata = arrData.column(harm_centre + hmnc);
    Vector<Complex> model_harmdata = arrData.column(harm_centre + hmnc);

    Int N = trackwin_exp;
    Int p = Int(pow(2, N));
    Int olap = Int(pow(2, N - trackwin_width_exp));

    //-cerr << "N = " << N << ", p = " << p << ", olap = " << olap << endl;

    /*
    Int nwin = 0;
    Int ll = 0;
    Int rr = ncycles - 1;
    while (ll + p/2 < rr) {
      ll += olap;
      rr -= olap;
      nwin += 2;
    }

    //-cerr << "nwin is determined to be " << nwin << endl;

    Matrix<Int> window(nwin, p); window=-1;
    Vector<Float> weight(nwin); weight=-1;
    Vector<Float> sig_comp(nwin); sig_comp=-1;
    Vector<Float> sig_arg(nwin); sig_arg=-10;

    ll = 0;
    rr = ncycles - 1;
    Vector<Int> iv_tmp(p);
    for (Int i_tmp = 0; i_tmp < nwin/2; i_tmp++) {
      indgen(iv_tmp, ll); window.row(i_tmp) = iv_tmp;
      indgen(iv_tmp, rr-p+1); window.row(nwin-i_tmp-1) = iv_tmp;
      ll += olap;
      rr -= olap;
    }
    */


    // new way to locate windows, centre middle one, then build
    // outwards...
    Int nwin = 1;
    Int ll = (ncycles+1) / 2 - p/2;
    Int firstll = ll;
    while ((firstll + olap) < (ncycles - (p-1))) {
      firstll += olap;
      nwin++;
    }

    //newbeg
    if (firstll < (ncycles - (p-1))) {
      //-cerr << "grabbing a final window" << endl;
      nwin++; // grab one final window centred on end
    }
    //newend

    firstll = ll;
    while ((firstll - olap) >= 0) {
      firstll -= olap;
      nwin++;
    }

    //newbeg
    if (firstll > 0) {
      //-cerr << "grabbing a first window" << endl;
      nwin++;
    }
    //newend

    // now we make nwin, starting at firstll, stepping by olap
    Matrix<Int> window(nwin, p); window=-1;
    Vector<Float> weight(nwin); weight=-1;
    Vector<Float> sig_comp(nwin); sig_comp=-1;
    Vector<Float> sig_arg(nwin); sig_arg=-10;
    ll = firstll;
    Vector<Int> iv_tmp(p);
    Int i_tmp = 0;
    if (ll > 0) {
      //-cerr << "making first window, i_tmp = " << i_tmp << endl;
      indgen(iv_tmp, 0);
      window.row(i_tmp) = iv_tmp;
      i_tmp++;
    }
    while (ll < (ncycles - (p-1))) {
      //-cerr << "making standard window, i_tmp = " << i_tmp
      //	   << ", ll = " << ll << endl;
      indgen(iv_tmp, ll);
      window.row(i_tmp) = iv_tmp;
      ll += olap;
      i_tmp++;
    }
    if (ll - olap < ((ncycles-1) - (p-1))) {
      //-cerr << "making last window, i_tmp = " << i_tmp << endl;
      indgen(iv_tmp, (ncycles-1) - (p-1));
      window.row(i_tmp) = iv_tmp;
    }


    //-cerr << "window is now " << window << endl;

    //-cerr << "setting up..." << endl;
    for (Int i_tmp = 0; i_tmp < nwin; i_tmp++) {
      Vector<Complex> tvd(p);
      for (Int j_tmp = 0; j_tmp < p; j_tmp++) {
        tvd(j_tmp) = harmdata(window.row(i_tmp)(j_tmp));
      }
      ArrayLattice<Complex> lat_tdata(tvd);
      cfft(lat_tdata, shaxes, forward);

      Vector<Float> tvec = amplitude(tvd);
      Float maxval = tvec(0);
      Int maxidx = 0;
      for (Int j_tmp = 1; j_tmp < p; j_tmp++) {
	if (tvec(j_tmp) > maxval) {
	  maxval = tvec(j_tmp);
	  maxidx = j_tmp;
	}
      }
      if (maxval > threshold * median(tvec)) {
	weight(i_tmp) = maxval;
	sig_comp(i_tmp) = maxidx;
	sig_arg(i_tmp) = arg(tvd(maxidx));
      }
    }

    // track phase of this harmonic...
    //-cerr << "tracking phase of this harmonic" << endl;
    Vector<Complex> pha_track(ncycles);
    pha_track = Complex(1,0);
    for (Int i_tmp = 0; i_tmp < ncycles; i_tmp++) {
    //for (Int i_tmp = p/2; i_tmp < ncycles - p/2; i_tmp++) {

      /*
      // which windows should we use for this integration?
      // require same number of windows left and right, so
      // at ends no tracking will be done.
      Int firstwin, lastwin;
      firstwin = 0;
      while ((ntrue(window.row(firstwin) == i_tmp) == 0) &&
	     (firstwin < nwin-1)) {
	firstwin++;
      }
      if (firstwin >= nwin-1) {
	continue;
      }
      lastwin = firstwin;
      while ((ntrue(window.row(lastwin) == i_tmp) > 0) &&
	     (lastwin < nwin-1)) {
	lastwin++;
      }
      if (lastwin >= nwin) {
	continue;
      }
      Float firstoff = Float(sum(window.row(firstwin))) / Float(p);
      Float lastoff = Float(sum(window.row(lastwin))) / Float(p);
      if ((firstoff > i_tmp) || (lastoff < i_tmp)) {
	continue;
      }
      while ((((i_tmp - firstoff) - (lastoff - i_tmp)) > p/olap) &&
	     (firstwin < nwin-1)) {
	firstwin++;
	firstoff = Float(sum(window.row(firstwin))) / Float(p);
      }
      while ((((i_tmp - firstoff) - (lastoff - i_tmp)) < -p/olap) &&
	     (lastwin < nwin-1)) {
	lastwin++;
	lastoff = Float(sum(window.row(lastwin))) / Float(p);
      }
      if ((firstwin >= lastwin) || (firstoff > i_tmp) ||
	  (lastoff < i_tmp)) {
	continue;
      }
      */

      Complex numsum(0,0);
      Float densum = 0.0;
      for (Int j_tmp = 0; j_tmp < nwin; j_tmp++) {
	//for (Int j_tmp = firstwin; j_tmp <= lastwin; j_tmp++) {
      //for (Int j_tmp = 0 + p/2/olap; j_tmp < nwin - 1 - p/2/olap; j_tmp++) {
	if (sig_comp(j_tmp) > -1) {
	  if (ntrue(window.row(j_tmp) == i_tmp) > 0) {
	    //;Float offset = Float(sum(window.row(j_tmp))) /
	    //;  Float(p);
	    Float offset = window.row(j_tmp)(0) + p/2;
	    Float trans_cen = window.row(j_tmp)(0) + p/2;
	    Float dist = abs(i_tmp - offset+0.25); // +0.25 arb. to keep > 0
	    Float presc = abs(weight[j_tmp] * pow(dist, rho));
	    // dgb 20021120: change sign of first term, div by 2p not p,
	    // and div offset term by 2 as well.
	    // NOTE OFFSET CALC CHANGED SINCE THIS LINE WORKED
	    //;Float pha = 1.0/Float(2*p) * ((sig_comp(j_tmp) - (p/2+1))) *
	    //;  (i_tmp - offset + 0.5)/2.0 * (2 * C::pi) +
	    //;  sig_arg(j_tmp);
	    Float pha = sig_arg(j_tmp) +
	      C::pi * Float(sig_comp(j_tmp) - (Int(p/2) + 1 - 1)) *
	      Float(i_tmp - trans_cen) / Float(p/2);
	    //.  2.0 * C::pi * Float(i_tmp - offset) *
	    //.  Float(sig_comp(j_tmp) - p/2) / Float(p);
	    //.Float pha = sig_arg(j_tmp);
	    numsum += Complex(presc * cos(pha), presc * sin(pha));
	    densum += presc;
	  }
	}
      }
      if (densum > 0) {
	pha_track(i_tmp) = numsum / densum;
      }
    }

    // in glish we plotted the tracked phase...

    // smooth the phases
    //-cerr << "smoothing the phases..." << endl;
    Vector<Complex> the_phases(ncycles);
    the_phases = Complex(0,0);
    for (Int i_tmp = 0; i_tmp < ncycles; i_tmp++) {
      the_phases(i_tmp) = pha_track(i_tmp) / abs(pha_track(i_tmp));
      Float tmp_pha = arg(harmdata(i_tmp)) - arg(pha_track(i_tmp));
      model_harmdata(i_tmp) = abs(harmdata(i_tmp)) *
	Complex(cos(tmp_pha), sin(tmp_pha));

    }

    Int width = smoothing_width;
    (width % 2) ? : width++;

    Int hw = Int(width / 2);
    Int hw2 = Int(smoothing_width);

    Vector<Float> mags(ncycles), phases(ncycles);
    mags = 0.0;
    phases = 0.0;

    for (Int i_tmp = 0; i_tmp < ncycles; i_tmp++) {

      // find the phase of the vector average of the phases
      Int blc = max(0, i_tmp-hw);
      Int trc = min(ncycles-1, i_tmp+hw);
      // adjust to make calculation symmetric about i_tmp
      Int mw = min(i_tmp - blc, trc - i_tmp);
      blc = i_tmp - mw;
      trc = i_tmp + mw;
      phases(i_tmp) = arg(sum(the_phases(Slice(blc, 2*mw+1))));
      // uncomment below for NO SMOOTHING
      //phases(i_tmp) = arg(the_phases(i_tmp));

      // find the robust (non-vector) median of the magnitudes
      // over double the smoothing width
      blc = max(0, i_tmp-hw2);
      trc = min(ncycles-1, i_tmp+hw2);
      mw = min(i_tmp-blc, trc-i_tmp);
      blc = i_tmp - mw;
      trc = i_tmp + mw;
      mags(i_tmp) = median(amplitude(model_harmdata(Slice(blc, 2*mw+1))));
      // uncomment below for NO SMOOTHING
      //mags(i_tmp) = abs(model_harmdata(i_tmp));
    }

    // in glish we did some more plotting...

    // mags contains the strength of eached tracked harmonic, so
    // now we simply subtract the model...
    //-cerr << "calculating the final model" << endl;
    Float new_threshold = 0.0;
    if (model_harmonic_amps.nelements() == nharms) {
      new_threshold = model_harmonic_amps(i_harm);
    } else if (model_harmonic_amps.nelements() == 1) {
      new_threshold = model_harmonic_amps(0);
    }
    mags(mags < new_threshold) = 0.0;
    // mags *= 0.6; # take less off because we're iterating
    // (this param. could be called "loop gain")

    // construct the model
    for (Int i_tmp = 0; i_tmp < ncycles; i_tmp++) {
      modData(i_tmp, harm_centre+hmnc) = mags(i_tmp) *
	Complex(cos(phases(i_tmp)), sin(phases(i_tmp)));
      // and complex conjugate entry...
      modData(i_tmp, harm_centre-hmnc) =
	conj(modData(i_tmp, harm_centre+hmnc));
    }
  }  // harmonic loop

  // tidy up the model...
  //-cerr << "tidying up the model..." << endl;
  modData.column(0) = Complex(0,0);
  for (Int i_tmp = 0; i_tmp < ncycles; i_tmp++) {
    modData(i_tmp, harm_centre) =
      Complex(real(modData(i_tmp, harm_centre)), 0);
  }

  //-cerr << "model fft mean = " << mean(real(modData)) << endl;
  //-cerr << "model fft median = " << median(real(modData)) << endl;
  //-cerr << "model fft min = " << min(real(modData)) << endl;
  //-cerr << "model fft max = " << max(real(modData)) << endl;

  //-cerr << "finally reverse fft'ing the model spectrum" << endl;
  //modData = arrData.copy(); // just forward/reverse trans works ok.

  ArrayLattice<Complex> latModel(modData);
  cfft(latModel, axes, !forward);
  Matrix<Float> retVal(real(modData));

  //-cerr << "output data mean = " << mean(retVal) << endl;
  //-cerr << "output data median = " << median(retVal) << endl;
  //-cerr << "output data min = " << min(retVal) << endl;
  //-cerr << "output data max = " << max(retVal) << endl;

  //-cerr << "leaving ObservingFilter::briggsHarmonicModel" << endl;
  //-cerr << "==================================================" << endl;

  return retVal;

};

//----------------------------------------------- ObservingFilter::flagInFrame

// set flags in the current frequency frame, flagging the
// channel closest to the specified frequency in Hz.

Bool ObservingFilter::flagInFrame(
  Matrix<uChar> &flagtra,
  const Double flagFreq,
  const Double refFreq,
  const Double deltaFreq)

{
  // assumption here that refFreq applies to channel Int(nChan/2).
  uInt nChan = flagtra.nrow();
  Int mask_c = Int(nChan / 2) + Int((flagFreq - refFreq) / deltaFreq);
  if ((mask_c > -1) && mask_c < Int(nChan)) {
    flagtra.row(mask_c) = uChar(1);
  } else {
    return False;
  }
  return True;
}

//----------------------------------------- ObservingFilter::specInterpolate1D

// Interpolate along spectral axis.

Bool ObservingFilter::specInterpolate1D(
  Matrix<Float> &spectra,
  Matrix<uChar> &flagtra)

{
  // fetch num chans and pols
  uInt nChan = spectra.nrow();
  uInt nPol = spectra.ncolumn();

  // sanity check
  if (!nChan || !nPol) {
    return False;
  }
  //-cerr << "nChan = " << nChan << ", nPol = " << nPol << endl;

  // construct abcissa
  Vector<Float> allx(nChan);
  indgen(allx);
  allx = allx - Float(nChan / 2);

  // storage areas
  uInt nknown, nunknown;
  Vector<Float> knownx, unknownx;
  Vector<Float> knowny, unknowny;
  Vector<Bool> msk;

  // loop over polarisations
  for (uInt ipol = 0; ipol < nPol; ipol++) {
    msk = flagtra.column(ipol) > uChar(0);
    nunknown = ntrue(msk);
    nknown = nChan - nunknown;
    if (nunknown && nknown) {
      knownx.resize(nknown);
      knownx = allx(!msk).getCompressedArray();
      knowny.resize(nknown);
      knowny = spectra.column(ipol)(!msk).getCompressedArray();
      ScalarSampledFunctional<Float> fx(knownx);
      ScalarSampledFunctional<Float> fy(knowny);
      Interpolate1D<Float, Float> ip1d(fx, fy);
      // could set method to be spline, but it really doesn't work
      // too well.  Apply the KISS principle and just accept default
      // of  nearest neighbour for one known pt, linear for > one
      // known pt.
      unknownx.resize(nunknown);
      unknownx = allx(msk).getCompressedArray();
      unknowny.resize(nunknown);
      //unknowny = ip1d(unknownx); CANNOT DO THIS: unknowny all end up same
      for (uInt i = 0; i < nunknown; i++) {
	unknowny(i) = ip1d(unknownx(i));
      }
      spectra.column(ipol)(msk).setCompressedArray(unknowny);
    }
  }
  return True;
}

//----------------------------------------- ObservingFilter::specInterpolate1D

Bool ObservingFilter::specInterpolate1D(
  Vector<Float> &spectrum,
  Vector<uChar> &flagtrum)

{
  // fetch num channels
  uInt nChan = spectrum.nelements();

  // sanity check
  if (!nChan) {
    return False;
  }

  // construct abcissa
  Vector<Float> allx(nChan);
  indgen(allx);
  allx = allx - Float(nChan / 2);

  // storage areas
  uInt nknown, nunknown;
  Vector<Float> knownx, unknownx;
  Vector<Float> knowny, unknowny;
  Vector<Bool> msk;

  msk = flagtrum > uChar(0);
  nunknown = ntrue(msk);
  nknown = nChan - nunknown;
  if (nunknown && nknown) {
    knownx.resize(nknown);
    knownx = allx(!msk).getCompressedArray();
    knowny.resize(nknown);
    knowny = spectrum(!msk).getCompressedArray();
    ScalarSampledFunctional<Float> fx(knownx);
    ScalarSampledFunctional<Float> fy(knowny);
    Interpolate1D<Float, Float> ip1d(fx, fy);
    // could set method to be spline, but it really doesn't work
    // too well.  Apply the KISS principle and just accept default
    // of  nearest neighbour for one known pt, linear for > one
    // known pt.
    unknownx.resize(nunknown);
    unknownx = allx(msk).getCompressedArray();
    unknowny.resize(nunknown);
    //unknowny = ip1d(unknownx); CANNOT DO THIS: unknowny all end up same
    for (uInt i = 0; i < nunknown; i++) {
      unknowny(i) = ip1d(unknownx(i));
    }
    spectrum(msk).setCompressedArray(unknowny);
  } else {
    return False;
  }
  return True;
}

//----------------------------------------- ObservingFilter::specInterpolate1D

Bool ObservingFilter::specInterpolate1D(
  Matrix<Matrix<Float> > &lSpecIn,
  Matrix<Matrix<uChar> > &lFlagIn,
  const uInt &nIntegrations)

{
  // fetch num beams and pols
  uInt nPol = lSpecIn.nrow();
  uInt nBeam = lSpecIn.ncolumn();

  // sanity check
  if (!nBeam || !nPol) {
    return False;
  }

  // sanity check (2)
  if ((nPol != lFlagIn.nrow()) || (nBeam != lFlagIn.ncolumn())) {
    return False;
  }

  Bool result = False;
  Bool tmpresult;
  Vector<Bool> cycle_fault(nIntegrations);
  cycle_fault = False;

  for (uInt ipol = 0; ipol < nPol; ipol++) {
    for (uInt ibeam = 0; ibeam < nBeam; ibeam++) {
      for (uInt icyc = 0; icyc < nIntegrations; icyc++) {
	// first try to interpolate along spectral axis
	Vector<Float> spectrum = lSpecIn(ipol,ibeam).row(icyc);
	Vector<uChar> flagtrum = lFlagIn(ipol,ibeam).row(icyc);
	tmpresult = specInterpolate1D(spectrum, flagtrum);
	if (!tmpresult) {
	  //-cerr << "interpolation failure: cycle " << icyc << endl;
	  // record this cycle as one that needs further work
	  cycle_fault(icyc) = True;
	}
	result = tmpresult || result;
      }
    }
  }

  if (ntrue(cycle_fault)) {
    // there were cycle faults, try interpolating along time axis...
    Vector<Float> spectrum; // construct so NOT by reference this time
    Vector<uChar> flagtrum;
    Slice slc(0, nIntegrations);
    for (uInt ipol = 0; ipol < nPol; ipol++) {
      for (uInt ibeam = 0; ibeam < nBeam; ibeam++) {
	for (uInt ichn = 0; ichn < lSpecIn(ipol,ibeam).ncolumn(); ichn++) {
	  spectrum = lSpecIn(ipol,ibeam).column(ichn)(slc);
	  flagtrum = lFlagIn(ipol,ibeam).column(ichn)(slc);
	  tmpresult = specInterpolate1D(spectrum, flagtrum);
	  if (!tmpresult) {
	    //-cerr << " + interpolation failure: channel " << ichn << endl;
	    spectrum = median(lSpecIn(ipol,ibeam));
	  }
	  // copy in only the required results...
	  for (uInt idx = 0; idx < nIntegrations; idx++) {
	    if (cycle_fault(idx)) {
	      lSpecIn(ipol,ibeam)(idx,ichn) = spectrum(idx);
	    }
	  }
	  result = tmpresult || result;
	}
      }
    }
  }

  return result;
}

//--------------------------------------------- ObservingFilter::specGrowFlags

// Grow flags along the spectral axis by +/- the specified number
// of channels.

Bool ObservingFilter::specGrowFlags(
  Matrix<uChar> &flagtra,
  const uInt delta)

{
  // actually we'd like to apply a Minkowski dilation operator, but
  // only in the spectra dimension.  Easier for now to just do it
  // "by hand", ...

  // fetch num chans and pols
  uInt nChan = flagtra.nrow();
  uInt nPol = flagtra.ncolumn();

  // sanity check
  if (!nChan || !nPol) {
    return False;
  }

  for (uInt ioff = 0; ioff < delta; ioff++) {
    for (uInt ipol = 0; ipol < nPol; ipol++) {
      for (uInt iChn = 0; iChn < nChan-1; iChn++) {
	if (flagtra(iChn+1, ipol) > uChar(0)) {
	  flagtra(iChn, ipol) = flagtra(iChn+1, ipol);
	}
      }
      for (uInt iChn = nChan-1; iChn > 0; iChn--) {
	if (flagtra(iChn-1, ipol) > uChar(0)) {
	  flagtra(iChn, ipol) = flagtra(iChn-1, ipol);
	}
      }
    }
  }
  return True;
}

//------------------------------------------------ ObservingFilter::shiftFlags

// Move and grow flags based on a non-integer channel shift.

Bool ObservingFilter::shiftFlags(
  Vector<uChar> &flagtrum,
  const Double shift)

{
  Int nChan = flagtrum.nelements();
  if (shift != 0.0) {
    // based on shift need to move and grow flags in one direction.
    // 1. move the flags
    Int i_cs = Int(shift);
    if (i_cs != 0) {
      //-cerr << "moving by " << i_cs << " channels" << endl;
      for (Int i = 0; i < nChan; i++) {
	if ((i + i_cs >= 0) && (i + i_cs < nChan)) {
	  flagtrum(i + i_cs) = flagtrum(i);
	}
      }
    }
    // 2. grow by one channel in correct direction
    Float f_cs = shift - Float(i_cs);
    if (f_cs > 0) { // grow right
      //-cerr << "growing right..." << endl;
      for (Int iChn = nChan-1; iChn > 0; iChn--) {
	if (flagtrum(iChn-1) > uChar(0)) {
	  flagtrum(iChn) = flagtrum(iChn-1);
	}
      }
    } else if (f_cs < 0) { // grow left
      //-cerr << "growing left..." << endl;
      for (Int iChn = 0; iChn < nChan-1; iChn++) {
	if (flagtrum(iChn+1) > uChar(0)) {
	  flagtrum(iChn) = flagtrum(iChn+1);
	}
      }
    }
  } else {
    return False; // we didn't touch the mask
  }
  return True; // we moved and/or grew the mask
}

//----------------------------------------- ObservingFilter::transientFlagging

// Apply knowledge-based and transient flagging.  Sometime this
// might be divided up a bit...

Bool ObservingFilter::transientFlagging(
  Matrix<Vector<Float> > &lTsysIn,
  Matrix<Matrix<Float> > &lSpecIn,
  Matrix<Matrix<uChar> > &lFlagIn,
  const Int &nIntegrations)
{

  //-cerr << "-> starting flagging... " << endl;

  //-cerr << "SEE CODE FOR IDEA" << endl;
  // WHAT ABOUT COMPARING FLUX IN THE DIFFERENT POLARISATIONS?
  // eg. if median flux in polA is significantly diff. to median
  // flux in polB, flag the cycle.

  Int nPol = lTsysIn.nrow();
  Int nBeam = lTsysIn.ncolumn();

  // sanity check (1)
  if ((nBeam < 1) || (nPol < 1)) {
    return False;
  }

  Int nChan = lSpecIn(0,0).ncolumn();
  Int npts = nIntegrations;

  // sanity check (2)
  if ((nChan < 1) || (npts < 1)) {
    return False;
  }

  Float p_level1 = 8.0;
  uInt p_count1 = 2; // then mult this by nPol;
  Float p_level2 = 4.0;
  uInt p_count2 = 3; // >13 never happens for Parkes Multibeam

  // HACK - copy pol 0 to pol 1, and only filter pol 0
  /*
    cerr << "WARNING: REPLACING POL 1 with POL 0 DATA" << endl;
    lTsysIn(1, ibeam) = lTsysIn(0, ibeam);
    lSpecIn(1, ibeam) = lSpecIn(0, ibeam);
    lFlagIn(1, ibeam) = lFlagIn(0, ibeam);
    nPol = 1;
  */
  p_count1 *= uInt(nPol);
  p_count2 *= uInt(nPol);

  Slice slc(0, npts);
  Float themedian, scatter;
  Vector<Bool> fitMask1(npts), fitMask2(npts);
  Vector<Bool> tsys_if(npts);
  Vector<Float> tsys;
  Vector<uInt> tsys_outliers1(npts), tsys_outliers2(npts);
  tsys_outliers1 = tsys_outliers2 = 0;
  Matrix<uInt> spec_outliers1(npts, nChan), spec_outliers2(npts, nChan);
  spec_outliers1 = spec_outliers2 = 0;
  Vector<Float> timeseries;

  for (Int ibeam = 0; ibeam < nBeam; ibeam++) {

    for (Int pol = 0; pol < nPol; pol++) {

      // 1. consider tsys data
      // a. calculated the incident flags (if) - flag tsys if entire
      //    spectrum flagged
      for (Int zziter = 0; zziter < npts; zziter++) {
	tsys_if(zziter) = allGT(lFlagIn(pol,ibeam).row(zziter), uChar(0));
      }
      // b. evaluate scatter based on flagged data
      tsys.resize(nfalse(tsys_if));
      tsys = (lTsysIn(pol,ibeam)(slc)(!tsys_if)).getCompressedArray();
      themedian = median(tsys);
      scatter = median(abs(tsys - themedian));
      // c. find where thresholds are exceeded
      tsys.resize(npts);
      tsys = (lTsysIn(pol,ibeam)(slc) - themedian);
      fitMask1 = abs(tsys) > (p_level1 * scatter);
      fitMask2 = abs(tsys) > (p_level2 * scatter);
      for (Int zziter = 0; zziter < npts; zziter++) {
	if (fitMask1(zziter)) {
	  tsys_outliers1(zziter)++;
	}
	if (fitMask2(zziter)) {
	  tsys_outliers2(zziter)++;
	}
      }

      // 2. consider the spectral data, one channel at a time.
      for (Int chan = 0; chan < nChan; chan++) {
	//
	// a. fetch incident flags (if)
	Vector<Bool> timeseries_if = lFlagIn(pol,ibeam).column(chan)(slc) >
	  uChar(0);
	if (ntrue(timeseries_if) == uInt(npts)) { // fully masked already
	  continue;
	}
	//
	// b. evaluate scatter based on flagged data
	timeseries.resize(nfalse(timeseries_if));
	timeseries = (lSpecIn(pol,ibeam).column(chan)(slc)
		      (!timeseries_if)).getCompressedArray();
	themedian = median(timeseries);
	scatter = median(abs(timeseries - themedian));

	// c. find where thresholds are exceeded
	timeseries.resize(npts);
	timeseries = (lSpecIn(pol,ibeam).column(chan)(slc) - themedian);
	fitMask1 = abs(timeseries) > (p_level1 * scatter);
	fitMask2 = abs(timeseries) > (p_level2 * scatter);
	for (Int zziter = 0; zziter < npts; zziter++) {
	  if (fitMask1(zziter)) {
	    spec_outliers1(zziter,chan)++;
	  }
	  if (fitMask2(zziter)) {
	    spec_outliers2(zziter,chan)++;
	  }
	}
      } // chan

    } // pol
  } // beam

  uInt opti_count = 0;
  uInt flag_count = 0;

  // search for polarised flux
  /*
  if (nPol == 2) {
    Vector<Float> polAvals(nBeam);
    Vector<Float> polBvals(nBeam);
    for (Int icyc = 0; icyc < npts; icyc++) {
      for (Int chan = 0; chan < nChan; chan++) {
	opti_count++;
	for (Int ibm = 0; ibm < nBeam; ibm++) {
	  polAvals(ibm) = lSpecIn(0,ibm)(icyc,chan);
	  polBvals(ibm) = lSpecIn(1,ibm)(icyc,chan);
	}
	if (abs(median(polAvals - polBvals)) > 10.0 * 100e-3 / 3.0) {
	  flag_count++;
	  for (Int ibm = 0; ibm < nBeam; ibm++) {
	    lFlagIn(0,ibm)(icyc, chan) = uChar(1);
	    lFlagIn(1,ibm)(icyc, chan) = uChar(1);
	  }
	  //spec_outliers1(icyc,chan) = nBeam * nPol;
	  //spec_outliers2(icyc,chan) = nBeam * nPol;
	}
      }
    }
  }
  if (flag_count > 0) {
    cerr << "-> identified " << flag_count << "/" << opti_count
         << " channel-cycle points with high polarisation" << endl;
  }
  */

  // here we'll store the total representative spectrum of what
  // we've flagged...
  Vector<Int> g_rfi_spec;
  g_rfi_spec.resize(nChan);
  g_rfi_spec = 0;

  // flag set 1: coincidences in a particular channel and cycle pair
  //             over multiple beams and polarisations
  opti_count = flag_count = 0;
  // hackme hackme hackme!!!
  //for (Int chan = 0; chan < nChan; chan++) {
  // only applying flagging to channels [129,1024].  This is really
  // only an interim measure so that stats we print are not too
  // distorted by presence of extended Galactic emission.
  Vector<Int> coinc_cyclehits(npts);
  coinc_cyclehits = 0;
  for (Int chan = 128; chan < nChan; chan++) {
    for (Int cyc = 0; cyc < npts; cyc++) {
      opti_count++;
      if ((spec_outliers1(cyc, chan) > p_count1) ||
	  (spec_outliers2(cyc, chan) > p_count2)) {
	//-cerr << "flagging cycle " << cyc << ", channel " << chan << endl;
	coinc_cyclehits(cyc)++;
	flag_count++;
	g_rfi_spec(chan)++;
	for (Int ibeam = 0; ibeam < nBeam; ibeam++) {
	  for (Int pol = 0; pol < nPol; pol++) {
	    lFlagIn(pol,ibeam)(cyc, chan) = uChar(1);
	  }
	}
      }
    }
  }
  if (flag_count > 0) {
    //-cerr << "-> flagged " << flag_count << "/" << opti_count << " channel-cycle points bc/of sig. coincidences" << endl;
  }

  // if more than say 1 flags in cycle or neighbours, remove entire cycle
  uInt tmp_limit = 1;
  opti_count = flag_count = 0;
  for (Int cyc = 0; cyc < npts; cyc++) {
    opti_count++;
    Bool flagme = (ntrue((spec_outliers1.row(cyc) > p_count1) ||
			 (spec_outliers2.row(cyc) > p_count2)) > tmp_limit);
    if (cyc > 0) {
      flagme = flagme ||
	(ntrue((spec_outliers1.row(cyc-1) > p_count1) ||
	       (spec_outliers2.row(cyc-1) > p_count2)) > tmp_limit);
    }
    if (cyc < npts -1) {
      flagme = flagme ||
	(ntrue((spec_outliers1.row(cyc+1) > p_count1) ||
	       (spec_outliers2.row(cyc+1) > p_count2)) > tmp_limit);
    }
    if (flagme) {
      flag_count++;
      for (Int ibeam = 0; ibeam < nBeam; ibeam++) {
	for (Int pol = 0; pol < nPol; pol++) {
	  lFlagIn(pol,ibeam).row(cyc) = uChar(1);
	}
      }
    }
  }
  if (flag_count > 0) {
    //-cerr << "-> flagged " << flag_count << "/" << opti_count << " cycles bc/of nearby multiple channel-cycle flags" << endl;
  }

  // if more than say 1 flags in channel or neighbours, remove entire channel
  tmp_limit = 1;
  opti_count = flag_count = 0;
  for (Int chan = 128; chan < nChan; chan++) {
    opti_count++;
    Bool flagme = (ntrue((spec_outliers1.column(chan) > p_count1) ||
			 (spec_outliers2.column(chan) > p_count2)) >
		   tmp_limit);
    if (chan > 128) {
      flagme = flagme ||
	(ntrue((spec_outliers1.column(chan-1) > p_count1) ||
	       (spec_outliers2.column(chan-1) > p_count2)) > tmp_limit);
    }
    if (chan < nChan-1) {
      flagme = flagme ||
	(ntrue((spec_outliers1.column(chan+1) > p_count1) ||
	       (spec_outliers2.column(chan+1) > p_count2)) > tmp_limit);
    }
    if (flagme) {
      flag_count++;
      //-cerr << "chan being flagged is " << chan << endl;
      for (Int ibeam = 0; ibeam < nBeam; ibeam++) {
	for (Int pol = 0; pol < nPol; pol++) {
	  lFlagIn(pol,ibeam).column(chan) = uChar(1);
	}
      }
    }
  }
  if (flag_count > 0) {
    //-cerr << "-> flagged " << flag_count << "/" << opti_count << " channels bc/of multiple channel-cycle flags" << endl;
  }

  // flag set 2: coincidences in tsys over
  //             multiple beams and polarisations
  opti_count = flag_count = 0;
  for (Int cyc = 0; cyc < npts; cyc++) {
    opti_count++;
    if ((tsys_outliers1(cyc) > p_count1) ||
	(tsys_outliers2(cyc) > p_count2)) {
      flag_count++;
      for (Int chan = 0; chan < nChan; chan++) {
	for (Int ibeam = 0; ibeam < nBeam; ibeam++) {
	  for (Int pol = 0; pol < nPol; pol++) {
	    lFlagIn(pol,ibeam)(cyc, chan) = uChar(1);
	  }
	}
      }
    }
  }
  if (flag_count > 0) {
    //-cerr << "-> flagged " << flag_count << "/" << opti_count << " cycles bc/of sig. Tsys coincidences" << endl;
  }

  // flag set 3: median abs deviation from the median (madm)
  //             elevated for a particular channel over multiple
  //             beams/pols.  eg. > 1.5 * 80e-3 Jy in
  // a. figure out madm for each beam & pol pair over "all"
  //    channels
  Slice slc2(128, nChan - 128);
  Matrix<Float> bp_stats(nBeam, nPol);
  Vector<Float> tmparr;
  for (Int ibeam = 0; ibeam < nBeam; ibeam++) {
    for (Int pol = 0; pol < nPol; pol++) {
      tmparr.resize(ntrue((lFlagIn(pol,ibeam))(slc,slc2) == uChar(0)));
      tmparr = ((lSpecIn(pol,ibeam))(slc,slc2)
		((lFlagIn(pol,ibeam))(slc,slc2) == uChar(0))).
	getCompressedArray();
      themedian = median(tmparr);
      bp_stats(ibeam,pol) = median(abs(tmparr - themedian));
    }
  }
  //-cerr << bp_stats << endl;

  // b. find elevated and flag
  opti_count = flag_count = 0;
  for (Int chan = 128; chan < nChan; chan++) {
    uInt count = 0;
    for (Int ibeam = 0; ibeam < nBeam; ibeam++) {
      for (Int pol = 0; pol < nPol; pol++ ) {
	Vector<Bool> timeseries_if = lFlagIn(pol,ibeam).column(chan)(slc) >
	  uChar(0);
	if (ntrue(timeseries_if) == uInt(npts)) { // fully masked already
	  continue;
	}
	timeseries.resize(nfalse(timeseries_if));
	timeseries = (lSpecIn(pol,ibeam).column(chan)(slc)
		      (!timeseries_if)).getCompressedArray();
	themedian = median(timeseries);
	scatter = median(abs(timeseries - themedian));
	if (scatter > 1.3 * bp_stats(ibeam,pol)) {
	  count++;
	}
      }
    }
    opti_count++;
    if (count > p_count1) {
      flag_count++;
      //-cerr << chan;
      for (Int ibeam = 0; ibeam < nBeam; ibeam++) {
	for (Int ipol = 0; ipol < nPol; ipol++) {
	  lFlagIn(ipol,ibeam).column(chan)(slc) = uChar(1);
	}
      }
    }
  }
  //-cerr << endl;
  if (flag_count > 0) {
    //-cerr << "-> flagged " << flag_count << "/" << opti_count << " channels bc/of increased madm statistic" << endl;
  }

  // now use "consistency" rules to make sure that strong signals
  // behave correctly, ie. fade in, fade out with beam at some
  // point.  Basic theory here is that each integration is 5s
  // separated, = 5 arcmin on the sky, which provides for a
  // typically maximal flux change between integrations of order
  // 2/5 to 5/2.  So we look for strong signals whose adjacent
  // integrations deviate by much more than this, eg. < 1/6 or
  // > 6.

  // this still needs to be smarter, right now if three cycles
  // in a row are high but equal, the middle channel will not
  // be discarded!  To deal with this need to look for
  // contiguous segments over threshold and discard entire
  // segment when only one of the individual elements exhibits
  // a fault.  I think this is now handled at "AAAA".

  if (True) {

    opti_count = flag_count = 0;

    Float med, meddev;
    Int cycle_hit_threshold = 2; // how many times does a cycle have
    // to have faults before the entire cycle is discarded.
    Float check_thresh = 12.0;
    Float check_scale = 6.0 - 2.0;
    Vector<Float> series; // the data we are inspecting
    Vector<Bool> cycmask(npts); // mask where threshold exceeded
    Vector<Bool> faultymask(npts); // mask where data identified as faulty
    Vector<Int> cyclehits(npts); // faults per cycle
    Vector<Int> idx(npts); // an indexing vector
    Vector<Int> idx_hi; // indices of high points in cycmask
    indgen(idx);
    uInt count_hi = 0;
    Int nhi, tidx;
    Float tval;
    Bool faulty;

    uInt opti_count2 = 0;
    uInt flag_count2 = 0;

    for (Int ibeam = 0; ibeam < nBeam; ibeam++) {
      for (Int ipol = 0; ipol < nPol; ipol++) {
	cyclehits = 0;
	for (Int chan = 0; chan < nChan; chan++) {
	  series = lSpecIn(ipol,ibeam).column(chan)(slc);
	  med = median(series);
	  meddev = median(abs(series - med));
	
	  series = fabs(series - med);
	  cycmask = series > check_thresh * meddev;
	  faultymask = False;
	
	  nhi = ntrue(cycmask);
	  opti_count += nhi; // count only hi data points

	  if (nhi) { // we have > 0 hi points...
	    idx_hi.resize(nhi);
	    for (Int tix = 0, tix2 = 0; tix < npts; tix++) {
	      if (cycmask(tix)) {
		idx_hi(tix2++) = tix;
	      }
	    }
	    for (Int i = 0; i < nhi; i++) {
	      tidx = idx_hi(i);
	      tval = series(tidx);
	      faulty = False;
	      if (tidx > 1) { // check to left
		if (cycmask(tidx - 1)) { // left is hi too
		  faulty = (tval > series(tidx - 1) * check_scale) ||
		    (tval * check_scale < series(tidx - 1));
		} else { // compare to maximum non-signif value possible
		  faulty = tval > check_thresh * check_scale * meddev;
		}
	      } else if (tidx < npts - 1) { // check to right
		if (cycmask(tidx + 1)) { // right is hi too
		  faulty = (tval > series(tidx + 1) * check_scale) ||
		    (tval * check_scale < series(tidx + 1));
		} else { // compare to maximum non-signif value possible
		  faulty = tval > check_thresh * check_scale * meddev;
		}
	      }
	      if (faulty) {
		faultymask(tidx) = True;
	      }
	    }

	    // AAAA
	    // now check contiguous segments of cycmask for any faults
	    // and modify it accordingly...
	    for (Int i = 0; i < npts; i++) {
	      Int j;
	      if (faultymask(i)) {
		j = i - 1;
		while (j >= 0 && !faultymask(j)) {
		  if (cycmask(j)) {
		    faultymask(j) = True;
		  }
		  j--;
		}
		j = i + 1;
		while (j < npts && !faultymask(j)) {
		  if (cycmask(j)) {
		    faultymask(j) = True;
		  }
		  j++;
		}
	      }
	    }
	
	    // now modify the data...
	    for (Int tidx = 0; tidx < npts; tidx++) {
	      if (faultymask(tidx)) {
		lFlagIn(ipol,ibeam).column(chan)(tidx) = uChar(1);
		cyclehits(tidx)++; // increment fault count this cycle
		flag_count++;
	      }
	    }
	
	    count_hi += ntrue(cycmask);
	  } // if (nhi) block
	} // chan loop
	
	// ok now let's discard entire cycles and immediately
	// neighbouring cycles where there were more than some
	// number of hits
	for (Int tidx = 0; tidx < npts; tidx++) {
	  opti_count2++;
	  if ((cyclehits(tidx) >= cycle_hit_threshold) ||
	      ((tidx > 0) && (cyclehits(tidx-1) >= cycle_hit_threshold)) ||
	      ((tidx < npts-1) && (cyclehits(tidx+1) >=
				   cycle_hit_threshold))) {
	    flag_count2++;
	    for (Int chan = 0; chan < nChan; chan++) {
	      lFlagIn(ipol,ibeam).column(chan)(tidx) = uChar(1);
	    }
	  }
	}
	
      } // pol loop
    } // beam loop

    if (flag_count > 0) {
      //-cerr << "-> flagged " << flag_count << "/" << opti_count << " high channel-cycle points bc/of non-smooth data" << endl;
    }
    if (flag_count2 > 0) {
      //-cerr << "-> flagged " << flag_count2 << "/" << opti_count2 << " cycle-feed points bc/of multiple non-smooth events" << endl;
    }

  }

  return True; // we did some flagging
}

//------------------------------------------------------ ObservingFilter::cfft

void ObservingFilter::cfft(
  Lattice<Complex>& lattice,
  const Vector<Bool>& whichAxes,
  const Bool toFrequency)

{
  const uInt ndim = lattice.ndim();
  DebugAssert(ndim > 0, AipsError);
  DebugAssert(ndim == whichAxes.nelements(), AipsError);
  FFTServer<Float,Complex> ffts;
  const IPosition latticeShape = lattice.shape();
  const IPosition tileShape = lattice.niceCursorShape();

  for (uInt dim = 0; dim < ndim; dim++) {
    if (whichAxes(dim) == True) {
      TiledLineStepper ts(latticeShape, tileShape, dim);
      LatticeIterator<Complex> li(lattice, ts);
      for (li.reset(); !li.atEnd(); li++) {
        ffts.fft(li.rwVectorCursor(), toFrequency);
      }
    }
  }
}

//----------------------------------------------------------------------------

// following is old code for doing some of the above removed from
// an interim version of pksbandpass.cc.  Please leave it here for
// the time being as it serves as David's reference material...


/* old chunk of code for setting flags
  if (True) { // flag some channels based on knowledge and maybe
    cerr << ". FLAGGING ON INPUT" << endl;
    // a database one day...
    Double freqInc, refFreq;
    tmp = thisBeam->get("REF_FREQUENCY");
    tmp.get(refFreq);
    tmp = thisBeam->get("RESOLUTION");
    tmp.get(freqInc);
    String freqRef;
    tmp = thisBeam->get("FREQREF");
    tmp.get(freqRef);

    if (freqRef == String("TOPO")) {
      // assume refFreq is for channel (nChan / 2), zero offset,
      // and nChan MUST BE EVEN
      Float mask_f;
      Int mask_c;

      // in flagtra (and spectra), row(i) selects channel i
      //                           column(i) selects polarisation i

      // mask a birdie channel
      mask_f = 1400.0e6; // frequency to mask - "birdie"
      mask_c = Int(nChan / 2) + Int((mask_f - refFreq) / freqInc);
      flagtra.row(mask_c) = True;
      // mask a birdie channel
      mask_f = 1408.0e6; // frequency to mask - "birdie"
      mask_c = Int(nChan / 2) + Int((mask_f - refFreq) / freqInc);
      flagtra.row(mask_c) = True;
    }
  }
*/

/* old chunk of code for interpolating...
  if (False) { // interpolate over masked channels prior to filtering
    cerr << ". INTERPOLATING ON INPUT" << endl;
    Vector<Float> allx(nChan);
    indgen(allx);
    allx = allx - Float(nChan / 2);
    uInt nknown, nunknown;
    Vector<Float> knownx, unknownx;
    Vector<Float> knowny, unknowny;
    Vector<Bool> msk;
    for (Int ipol = 0; ipol < nPol; ipol++) {
      msk = flagtra.column(ipol) > uChar(0);
      nunknown = ntrue(msk);
      nknown = nChan - nunknown;
      if (nunknown && nknown) {
	knownx.resize(nknown);
	knownx = allx(!msk).getCompressedArray();
	knowny.resize(nknown);
	knowny = spectra.column(ipol)(!msk).getCompressedArray();
	ScalarSampledFunctional<Float> fx(knownx);
	ScalarSampledFunctional<Float> fy(knowny);
	Interpolate1D<Float, Float> ip1d(fx, fy);
	// default method is nearest neighbour for one known pt,
	// linear for > one known pt.  We choose spline if more
	// than four known pts.
	if (nknown > 4) {
	  ip1d.setMethod(Interpolate1D<Float, Float>::spline);
	}
	unknownx.resize(nunknown);
	unknownx = allx(msk).getCompressedArray();
	unknowny.resize(nunknown);
	unknowny = ip1d(unknownx);
	spectra.column(ipol)(msk).setCompressedArray(unknowny);
      }
    }
  }
*/

/* old chunk of code for moving and growing flags after vel tracking
    cerr << ". MOVING & GROWING FLAGS AFTER TRACKING *without* OBSERVINGFILTER CLASS" << endl;
    Float chanShift = gVelTrack->lastShiftInChannels();
    cerr << "chanShift = " << chanShift << endl;
    if (chanShift != 0.0) {
      // based on chanShift need to move and grow flags in one direction.
      // 1. move the flags
      Int i_cs = Int(chanShift);
      if (i_cs != 0) {
	cerr << "moving by " << i_cs << " channels" << endl;
	for (Int i = 0; i < nChan; i++) {
	  if ((i + i_cs >= 0) && (i + i_cs < nChan)) {
	    flagtrum(i + i_cs) = flagtrum(i);
	  }
	}
      }
      // 2. grow by one channel in correct direction
      Float f_cs = chanShift - Float(i_cs);
      if (f_cs > 0) { // grow right
	cerr << "growing right..." << endl;
	for (Int iChn = nChan-1; iChn > 0; iChn--) {
	  if (flagtrum(iChn-1) > uChar(0)) {
	    flagtrum(iChn) = flagtrum(iChn-1);
	  }
	}
      } else if (f_cs < 0) { // grow left
	cerr << "growing left..." << endl;
	for (Int iChn = 0; iChn < nChan-1; iChn++) {
	  if (flagtrum(iChn+1) > uChar(0)) {
	    flagtrum(iChn) = flagtrum(iChn+1);
	  }
	}
      }
    }
*/
