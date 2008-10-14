//#---------------------------------------------------------------------------
//# pksbandpass.cc: Glish client for bandpass calibration of single-dish data.
//#---------------------------------------------------------------------------
//# Copyright (C) 1994-2006
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but
//# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
//# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
//# for more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#---------------------------------------------------------------------------
//# Glish client for removing the bandpass from single-dish data and applying
//# corrections to the baseline.
//#
//# Author: David Barnes, February 1997, with extensive input from
//# Lister Staveley-Smith and Taisheng Ye.  Based on the prototype clients
//# gbp.new and tygbp developed by David Barnes and Taisheng Ye in late 1996.
//# These in turn were based on the prototype client developed by David Barnes
//# at Charlottesville and Melbourne in early 1996.
//#
//# Subsequently severely hacked about the face and body by Mark Calabretta.
//#
//# $Id: pksbandpass.cc,v 19.35 2006/07/11 07:56:12 mcalabre Exp $
//#---------------------------------------------------------------------------

// AIPS++ includes.
#include <casa/iostream.h>
#include <casa/math.h>
#include <casa/stdio.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/Cube.h>
#include <casa/Arrays/MaskedArray.h>
#include <casa/Arrays/MaskArrMath.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Slice.h>
#include <casa/BasicSL/Constants.h>
#include <casa/BasicSL/String.h>
#include <casa/Exceptions/Error.h>
#include <casa/Quanta/Quantum.h>
#include <lattices/Lattices/ArrayLattice.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishEvent.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>

// Parkes includes.
#include <atnf/pks/pksmb_support.h>
#include <atnf/pks/pks_maths.h>

#include <FFTfilter.h>
#include <ObservingFilter.h>
#include <RobustLineFit.h>
#include <RPolyFit.h>
#include <VelTracker.h>

#include <casa/namespace.h>

// Glish event handlers.
Bool init_event(GlishSysEvent &event, void *);
Bool correct_event(GlishSysEvent &event, void *);
Bool flush_event(GlishSysEvent &event, void *);

// Worker functions.
void logParameters(void);
Bool loadIntegration(GlishRecord &thisGlob, Int intIn);
Bool loadBeam(GlishRecord &gv, Int ibeam);
void finished(GlishSysEventSource *glishBus);

Bool refSpectrum(GlishRecord &);
void freqSwSpectrum(Int target, GlishRecord &);
void freqSwScan(void);
Bool beamSwSpectrum(Bool flush, GlishRecord &);

Bool correctSpectrum(Int iInt, GlishRecord &);
Vector<Bool> fieldNameMask(Int target);
Vector<Bool> timeMask(Int target);
Vector<Bool> positionMask(Int target, Int ibeam);

void correctExtended(void);
void polyfitBandpass(Matrix<Vector<Float> > &lTsysIn,
                     Matrix<Matrix<Float> > &lSpecIn,
                     Int nInt);

Matrix<uChar> compressFlags(Matrix<uChar> &);
void postBandpass(const Int iif, Vector<Float> &spectrum,
                  Vector<uChar> &flagtrum, Vector<Float> &baseLin,
                  Vector<Float> &baseSub, const Double time,
                  const Vector<Double> position, const Double refFreq,
                  const Double freqInc, Double &newRefFreq,
                  Double &newFreqInc);
int growMask(Vector<Bool> &mask, Float growMin, Float growAdd);

// Parameters.
String gSmoothing;		// "TUKEY", "HANNING" or "NONE"
String gPrescaleMode;		// "NONE", "MEAN" or "MEDIAN"
String gMethod;			// "COMPACT", "EXTENDED", "MX", "SCMX",
				// "FREQSW", or "REFERENCED".
String gEstimator;		// "MEAN", "MEDIAN", "RFIMED", "POLYFIT",
				// "MEDMED", "MINMED", or "NONE".

				// Mask broadening parameters:
Float gChanGrowMin;		// Grow each region in the channel mask by one
				// on each side if it contains this many
				// elements...
Float gChanGrowAdd;		// ... and by a further one on each side for
				// every additional number of elements.
Float gTimeGrowMin;		// And likewise for the time mask.
Float gTimeGrowAdd;

				// RFIMED parameters:
Float gRFIclip;			// Set the clipping threshhold to this
				// multiple of the typical bandpass RMS.
Int gRFIiter;			// Number of clipping iterations.
Int gRFIminInt;			// Minimum number of integrations that must
				// remain after clipping to accept the
				// bandpass calibration for a channel.
Float gRFIlev;			// Reject the bandpass calibration for a
				// channel if the RMS exceeds this multiple of
				// the typical bandpass RMS.
Float gRFIsFlag;		// If more than this fraction of integrations
				// in a channel was clipped then flag them.

				// POLYFIT parameters:
Int   gPolyDegree;		// Polynomial degree.
Float gPolyDev;			// Discrimination level; points outside the
				// specified number of "median deviations"
				// will be discarded after each iteration.
				// The median deviation is computed as the
				// median of the absolute deviation from the
				// median.  Thus, for gPolyDev = 1 half the
				// data points remaining will be discarded at
				// each iteration.
Int  gPolyIter;			// Number of iterations.

Bool gStatRatio;		// Statistic of ratio (recommended) or ratio
				// of statistic (HIPASS/ZOA).
Int gBandpassRecalc;		// This controls the period (in cycles)
				// at which the bandpass is recalculated.
Int gPreCycles, gPostCycles;	// Number of cycles to store and search
				// for valid bandpass spectra.
Int gMaxCycles;			// Maximum number of integrations in a scan in
				// extended source or HVC modes.
Int gBoxSize;			// Box size, in integrations, for the MEDIAN,
				// MEAN and RFIMED estimators for the EXTENDED
				// source bandpass correction method.
Bool gBoxReject;		// If true, reject the one box with the lowest
				// sum(Tsys/channel), else accept the one box
				// with the highest sum(Tsys/channel).
Int gNBoxes;			// Number of subdivisions of the scan for the
				// MEDMED and MINMED estimators for the
				// EXTENDED source bandpass correction method.
Int gMargin;			// Sub-scan margin for SCMX POLYFIT bandpass
				// correction.  Defines the number of
				// integrations to use from the start, and
				// before the end of the current sub-scan.  If
				// zero, use the previous and following
				// subscans.
Bool gXbeam;			// Do cross-beam Tsys correction (for
				// continuum sources)?
Bool gSCMX;			// Is it a scanned, MX mode observation?
Int gFitDegree;			// -1 for no post-bandpass fit,
				//  0 for constant offset (i.e. median),
				// >0 for robust (adaptive) polynomial fit.
Bool gL1Norm;			// Use L1 norm for linear fit rather than
				// adaptive.
Bool gContinuum;		// Preserve the linear component of the
				// baseline fit (continuum flux).
Vector<Bool> gChanMask;		// Channel selection mask.
String gOutFrame;		// Output Doppler reference frame - names
				// defined by FITS WCS Paper III (TOPOCENT,
				// GEOCENTR, LSRK, BARYCENT, etc.).
Bool gRescaleAxis;		// Doppler shift by rescaling frequency axis.

// Mask/validity settings.
Bool gFast;			// If T, do tests for central beam only.
Bool gCheckFieldName;
Bool gCheckTime;
Double gTmax, gTmin, gTjump;	// (seconds)
Bool   gCheckPosition;
Double gDmax, gDmin, gDjump;	// (arcmin)


// Constants.
const Double D2R = C::pi / 180.0;
const Double R2D = 180.0 / C::pi;

// Global data buffers.
Vector<Int> gBeamNumbers;		// Index of true 1-rel beam numbers.
Vector<Int> gIFNumbers;			// Index of true 1-rel IF numbers.

Cube<GlishRecord> gBufferIn;		// Glish records, minus spectra and
					// flags, for each cycle, beam, & IF.
Matrix<Bool> gIFs;			// IFs read in for each cycle.
Vector<String> gFieldNameIn;		// Field names for each cycle.

Vector<Double> gTime;			// Time stamps and
Vector<Double> gTStep;			// time steps for each cycle.

Matrix<Vector<Double> > gCoord;		// Positions(ra,dec), and
Matrix<Double> gDStep;			// position steps(ra,dec) for each
					// cycle and beam.

Vector<Int> gIntIn;			// Integration number in buffer.
Cube<Vector<Float> > gTsysIn;		// Tsys(cycles),
Cube<Matrix<Float> > gSpecIn;		// Spectra(cycle,chan), and
Cube<Matrix<uChar> > gFlagIn;		// Flags(cycle,chan) for each
					// polarization, beam, and IF.

Cube<Float> gTsys;			// Reference Tsys, and
Cube<Vector<Float> > gBandpass;		// reference spectra(channel) for each
					// polarization, beam, and IF.

Vector<Int> gRefCount(2);		// Number of reference integrations
					// accumulated for each IF.
Vector<Bool> gRefStart(2);		// Flag to restart accumulation of
					// reference integrations.

Vector<Int> gPaddleCount(2);		// Number of paddle integrations
					// accumulated for each IF.
Vector<Bool> gPaddleStart(2);		// Flag to restart count of paddle
					// integrations skipped.

Vector<Int> gSLevelCount(2);		// Number of signal level setting
					// integrations accumulated for each
					// IF.
Vector<Bool> gSLevelStart(2);		// Flag to restart count of signal
					// level setting integrations skipped.

Vector<Int> gRefbeam(10);		// MX mode cyclic buffer: 1-relative
					// reference beam number for subscan.
Vector<Int> gSubscanIndex(10);		// MX mode cyclic buffer: integration
					// count at the end of each subscan.

// Global variables.
String gClientName = "pksbandpass";
Int  gIF;				// 0-rel IF index of incoming Glish
					// record.
Int  gNIF, gNBeam;			// Number of IFs and beams in incoming
					// records.
Int  gNChan, gNPol;			// Each IF must have the same number
					// of channels and polarizations.
String gInFrame;			// Doppler reference frame of each IF.
Int  gNCycles;				// Buffer size for input data.

Bool gRefSig;				// True if reference/signal obs.
Bool gFreqSw;				// True if frequency switching.
Bool gBeamSw;				// True if beam-switching.

Int  gScanNo;				// Last scan number read in.
Int  gCycleNo;				// Last integration cycle number read.
Int  gRefBeam;				// Last 1-relative signal beam number
					// read in beam-switching mode.

Int  gNInt;				// Number of integrations read in.
Int  gIntOut;				// Number of integrations written out.
Int  gSubscanCount;			// Number of complete subscans read.
Int  gSubscanOut;			// Number of subscans written out.
Bool gFlushing;				// True if flushing has started.
Int  gFlushInt;
Int  gBandpassAge;

VelTracker *gVelTrack[] = {0x0,0x0};
FFTfilter  *gFilter = 0x0;

ObservingFilter gObsFilter;

RPolyFit<Float> *gBandPoly = 0x0;	// Robust polynomial used for bandpass
					// fitting (fits over time).
RPolyFit<Float> *gBasePoly = 0x0;	// Robust polynomial used for spectral
					// baseline fitting (fits over chan).
Matrix<Matrix<Float> > gTsysCoeffs;
Matrix<Matrix<Float> > gSpecCoeffs;
Vector<Float> gChans;

Bool _test_FlagInput = False;		// Flag input spectra?
Bool _test_SmoothFlags = False;		// Interpolate over flags?
Bool _test_GrowFlags = False;		// Grow flags after filters?
Bool _test_PhaseTracking = False;	// Apply phase tracking?
Bool _test_TranFlags = False;		// Flag transient bad data?

//----------------------------------------------------------------------- main

int main(int argc, char **argv)
{
  try {
    // Set up the Glish event stream.
    GlishSysEventSource glishStream(argc, argv);
    glishStream.addTarget(init_event, "init");
    glishStream.addTarget(correct_event, "correct");
    glishStream.addTarget(flush_event, "flush");
    pksmbSetup(glishStream, gClientName);

  } catch (AipsError x) {
    cerr << x.getMesg() << endl;
  }

  return 0;
}

//----------------------------------------------------------------- init_event

// Handler for "init" event.

Bool init_event(GlishSysEvent &event, void *)
{
  logMessage("");
  String version = "$Revision: 19.35 $";
  String date = "$Date: 2006/07/11 07:56:12 $";

  logMessage("pksbandpass (v" + String(version.after(' ')).before(' ') +
             ", " + String(date.after(' ')).before(' ') + ") initializing.");

  GlishSysEventSource *glishBus = event.glishSource();
  GlishValue glishVal = event.val();

  // Check that argument is a record.
  if (glishVal.type() != GlishValue::RECORD) {
    logError("ERROR: Argument to \"init\" should be a record.");
    return True;
  }

  // Extract parameters.
  GlishRecord parms = glishVal;
  Vector<Int> chanMask(10);

  getParm(parms, "nifs",               2,             gNIF);
  getParm(parms, "nbeams",            13,             gNBeam);
  getParm(parms, "npols",              2,             gNPol);
  getParm(parms, "nchans",          1024,             gNChan);
  getParm(parms, "smoothing",      String("TUKEY"),   gSmoothing);
  getParm(parms, "prescale_mode",  String("NONE"),    gPrescaleMode);
  getParm(parms, "method",         String("COMPACT"), gMethod);
  getParm(parms, "estimator",      String("MEDIAN"),  gEstimator);
  getParm(parms, "chan_growmin",    1.0f,             gChanGrowMin);
  getParm(parms, "chan_growadd",    1.5f,             gChanGrowAdd);
  getParm(parms, "time_growmin",    2.0f,             gTimeGrowMin);
  getParm(parms, "time_growadd",    4.0f,             gTimeGrowAdd);
  getParm(parms, "rfi_clip",        3.0f,             gRFIclip);
  getParm(parms, "rfi_iter",           5,             gRFIiter);
  getParm(parms, "rfi_minint",         5,             gRFIminInt);
  getParm(parms, "rfi_lev",         2.0f,             gRFIlev);
  getParm(parms, "rfi_sflag",      0.75f,             gRFIsFlag);
  getParm(parms, "polydegree",         2,             gPolyDegree);
  getParm(parms, "polydev",         2.0f,             gPolyDev);
  getParm(parms, "polyiter",           3,             gPolyIter);
  getParm(parms, "statratio",       True,             gStatRatio);
  getParm(parms, "bp_recalc",          4,             gBandpassRecalc);
  getParm(parms, "nprecycles",        24,             gPreCycles);
  getParm(parms, "npostcycles",       24,             gPostCycles);
  getParm(parms, "maxcycles",        250,             gMaxCycles);
  getParm(parms, "boxsize",           20,             gBoxSize);
  getParm(parms, "boxreject",       True,             gBoxReject);
  getParm(parms, "nboxes",             5,             gNBoxes);
  getParm(parms, "margin",             0,             gMargin);
  getParm(parms, "xbeam",           True,             gXbeam);
  getParm(parms, "fit_order",          0,             gFitDegree);
  getParm(parms, "l1norm",         False,             gL1Norm);
  getParm(parms, "continuum",      False,             gContinuum);
  getParm(parms, "chan_mask",          0,             chanMask);
  getParm(parms, "doppler_frame", String("BARYCENT"), gOutFrame);
  getParm(parms, "rescale_axis",    True,             gRescaleAxis);
  getParm(parms, "fast",            True,             gFast);
  getParm(parms, "check_field",     True,             gCheckFieldName);
  getParm(parms, "check_time",      True,             gCheckTime);
  getParm(parms, "tmin",             0.0,             gTmin);
  getParm(parms, "tmax",           300.0,             gTmax);
  getParm(parms, "tjump",           20.0,             gTjump);
  getParm(parms, "check_position",  True,             gCheckPosition);
  getParm(parms, "dmin",            15.0,             gDmin);
  getParm(parms, "dmax",           300.0,             gDmax);
  getParm(parms, "djump",           10.0,             gDjump);

  // Spectral smoothing.
  delete gFilter;
  gFilter = 0x0;

  gSmoothing.upcase();
  if (gSmoothing == "TUKEY") {
    gFilter = new FFTfilter(FFTfilter::TUKEY25);
  } else if (gSmoothing == "HANNING") {
    gFilter = new FFTfilter(FFTfilter::HANNING);
  }

  gPrescaleMode.upcase();

  // Scan correction method.
  gMethod.upcase();
  if (gMethod == "COMPACT") {
    gNCycles = gPreCycles + 1 + gPostCycles;
  } else {
    gNCycles = gMaxCycles;

    if (gMethod == "FREQSW") {
      if (gMaxCycles == 2) gFitDegree = 8;
      gContinuum = False;
    }
  }

  // Bandpass estimator.
  gEstimator.upcase();
  delete gBandPoly;
  gBandPoly = 0x0;
  if (gMethod == "COMPACT" && gEstimator == "POLYFIT") {
    Vector<Float> integs(gNCycles);
    indgen(integs);
    integs -= Float(gPreCycles);
    gBandPoly = new RPolyFit<Float>(gPolyDegree+1, integs);
  }

  // No cross-beam Tsys correction for single beam data.
  if (gNBeam < 2) gXbeam = False;

  // Note that fit_order supplied from the GUI is actually the degree.
  if (gContinuum) {
    if (gFitDegree == 0) {
      gFitDegree = -1;
    }
  }

  // Resize buffers.
  if (gNIF   < 1) gNIF   = 1;
  if (gNBeam < 1) gNBeam = 1;
  if (gNPol  < 1) gNPol  = 1;

  gBufferIn.resize(gNCycles,gNBeam,gNIF);
  gIFs.resize(gNCycles,gNIF);
  gIFs = False;

  gFieldNameIn.resize(gNCycles);
  gTime.resize(gNCycles);
  gTStep.resize(gNCycles);
  gCoord.resize(gNCycles,gNBeam);
  gDStep.resize(gNCycles,gNBeam);

  gTsysIn.resize(gNPol,gNBeam,gNIF);
  gSpecIn.resize(gNPol,gNBeam,gNIF);
  gFlagIn.resize(gNPol,gNBeam,gNIF);
  gTsys.resize(gNPol,gNBeam,gNIF);
  gBandpass.resize(gNPol,gNBeam,gNIF);

  gIntIn.resize(gNCycles);
  gIntIn = -1;

  for (Int iif = 0; iif < gNIF; iif++) {
    for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
      for (Int ipol = 0; ipol < gNPol; ipol++) {
        gTsysIn(ipol,ibeam,iif).resize(gNCycles);
        gSpecIn(ipol,ibeam,iif).resize(gNCycles,gNChan);
        gFlagIn(ipol,ibeam,iif).resize(gNCycles,gNChan);
        gBandpass(ipol,ibeam,iif).resize(gNChan);
      }
    }
  }

  gIFNumbers.resize(gNIF);
  gIFNumbers = 0;
  gBeamNumbers.resize(gNBeam);

  // Polynomial baseline fitting; allow up to 15th-degree.
  gChans.resize(gNChan);
  indgen(gChans);
  gChans -= Float(gNChan/2);
  gChans /= gNChan/2.0f;

  delete gBasePoly;
  gBasePoly = new RPolyFit<Float>(16, gChans);

  gChanMask.resize(gNChan);
  gChanMask = True;
  for (Int i = 0; i < 10; i += 2) {
    if (chanMask(i))

    if (chanMask(i) > 0) {
      if (chanMask(i+1) > gNChan) chanMask(i+1) = gNChan;
      Int len = chanMask(i+1) - chanMask(i) + 1;
      if (len > 0) gChanMask(Slice(chanMask(i)-1, len)) = False;
    }
  }

  // Doppler tracking reference frames.
  gInFrame = "";
  gOutFrame.upcase();

  delete gVelTrack[0];
  delete gVelTrack[1];
  gVelTrack[0] = 0x0;
  gVelTrack[1] = 0x0;


  // Work variables.
  gScanNo  = 0;
  gCycleNo = 0;
  gNInt = 0;
  gBandpassAge = 0;
  gFlushing = False;
  gFreqSw  = False;
  gBeamSw  = False;

  glishBus->postEvent("initialized", gClientName);

  logParameters();

  return True;
}

//-------------------------------------------------------------- correct_event

// Handler for "correct" event.  Accept new data in a multibeam glish record,
// and return corrected data.

Bool correct_event(GlishSysEvent &event, void *)
{
  GlishSysEventSource *glishBus = event.glishSource();
  GlishValue glishVal = event.val();

  // Check that argument is a record.
  if (glishVal.type() != GlishValue::RECORD) {
    logError("ERROR: Argument to \"correct\" should be a record.");
    return False;
  }

  char intLabel[6];
  Int intIn  = 1;
  Int intOut = 0;

  GlishRecord aggRec = glishVal, aggRecOut, intRecOut;

  // Buffer the integration(s).
  while (1) {
    if (gFreqSw && gNCycles == 2 && gNInt%2) {
      // Pair-wise frequency switching, check for skipped integrations.
      sprintf(intLabel, "int%02d", intIn);
      if (aggRec.exists(intLabel)) {
        GlishArray glishArr;
        Double freq0, freq1;

        Int iif = gIFs(0,1) ? 1 : 0;
        glishArr = gBufferIn(0,0,iif).get("REF_FREQUENCY");
        glishArr.get(freq0);

        GlishRecord gRec = aggRec.get(intLabel);
        gRec = gRec.get(0);
        glishArr = gRec.get("REF_FREQUENCY");
        glishArr.get(freq1);

        if (freq1 == freq0) {
          // Use the integration already in buffer location 1.
          freqSwSpectrum(0, intRecOut);
          sprintf(intLabel, "int%02d", ++intOut);
          aggRecOut.add(intLabel, intRecOut);

          // Account for the skipped integration.
          gNInt++;
        }
      }
    }

    // Buffer the next integration.
    if (!loadIntegration(aggRec, intIn)) break;

    if (gRefSig) {
      // Referenced mode observations.
      if (refSpectrum(intRecOut)) {
        sprintf(intLabel, "int%02d", ++intOut);
        aggRecOut.add(intLabel, intRecOut);
      }

    } else if (gFreqSw) {
      // Frequency switched (narrow band) data.
      if (gNCycles == 2 && gNInt%2 == 0) {
        freqSwSpectrum(0, intRecOut);
        sprintf(intLabel, "int%02d", ++intOut);
        aggRecOut.add(intLabel, intRecOut);

        freqSwSpectrum(1, intRecOut);
        sprintf(intLabel, "int%02d", ++intOut);
        aggRecOut.add(intLabel, intRecOut);
      }

    } else if (gBeamSw) {
      // Accumulate data in beam-switching mode.
      if (beamSwSpectrum(False, intRecOut)) {
        sprintf(intLabel, "int%02d", ++intOut);
        aggRecOut.add(intLabel, intRecOut);
      }

    } else if (gMethod == "COMPACT") {
      // Do bandpass correcting if there is sufficient data.
      if (gNInt > gPostCycles) {
        // The integration to process.
        Int iInt = gNInt - gPostCycles;

        // Apply the bandpass correction.
        if (correctSpectrum(iInt, intRecOut)) {
          sprintf(intLabel, "int%02d", ++intOut);
          aggRecOut.add(intLabel, intRecOut);

        } else {
          char text[120];
          sprintf(text, "WARNING: Discarding integration cycle %d.", iInt);
          logWarning(text);
        }
      }
    }

    intIn++;
  }

  // Return the result to Glish.
  if (aggRecOut.exists("int01")) {
    glishBus->postEvent("corrected_data", aggRecOut);
  } else {
    glishBus->postEvent("need_more_data", gClientName);
  }

  return True;
}

//---------------------------------------------------------------- flush_event

// Handler for "flush" event.

Bool flush_event(GlishSysEvent &event, void *)
{
  GlishSysEventSource *glishBus = event.glishSource();
  GlishValue glishVal = event.val();
  GlishRecord aggRecOut, intRecOut;

  if (gRefSig) {
    // Referenced data; no buffering.
    finished(glishBus);

  } else if (gFreqSw) {
    if (gNCycles == 2) {
      // Pair-wise frequency switched data; discard unpaired integrations.
      finished(glishBus);
      return True;
    }

    // Scan-wise frequency switched data.
    if (glishVal.type() != GlishValue::ARRAY) {
      logWarning("WARNING: Argument to \"flush\" should be an array.");
      return True;
    }

    if (!gFlushing) {
      // Calculate and apply the bandpass correction to the whole scan.
      logMessage("Calculating and applying bandpass correction...");
      freqSwScan();

      logMessage("Flushing buffer...");
      gFlushing = True;
      gFlushInt = 1;
    }

    // Get number of integrations to flush.
    GlishArray glishArr = glishVal;
    Int num_ints;
    glishArr.get(num_ints);

    // Construct outgoing Glish record.
    Int intOut = 0;
    char labelOut[6];
    GlishRecord beamRecOut;

    Matrix<Float> spectra(gNChan, gNPol);
    Matrix<uChar> flagtra(gNChan, gNPol);

    while (gFlushInt <= gNInt && intOut < num_ints) {
      GlishArray glishArr;

      Int target = gFlushInt - 1;
      Int iif = gIFs(target,1) ? 1 : 0;

      for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
        Double freqInc, refFreq;
        glishArr = gBufferIn(target,ibeam,iif).get("REF_FREQUENCY");
        glishArr.get(refFreq);
        glishArr = gBufferIn(target,ibeam,iif).get("RESOLUTION");
        glishArr.get(freqInc);

        Double newFreqInc, newRefFreq;
        for (Int ipol = 0; ipol < gNPol; ipol++) {
          // Create a reference to stop the compiler whinging.
          Vector<Float> spectrum = gSpecIn(ipol,ibeam,iif).row(target);
          Vector<uChar> flagtrum = gFlagIn(ipol,ibeam,iif).row(target);

          // Doppler reference frame conversion.
          Double chanShift;
          gVelTrack[iif]->correct(gTime(target), gCoord(target,ibeam),
                                  refFreq, freqInc, newRefFreq, newFreqInc,
                                  chanShift, spectrum);

          spectra.column(ipol) = spectrum;
          flagtra.column(ipol) = flagtrum;
        }

        beamRecOut = gBufferIn(target,ibeam,iif);
        beamRecOut.add("DOPPLER_FRAME", gOutFrame);
        beamRecOut.add("REF_FREQUENCY", newRefFreq);
        beamRecOut.add("RESOLUTION", newFreqInc);
        beamRecOut.add("FLOAT_DATA", spectra);
        beamRecOut.add("FLAGGED", compressFlags(flagtra));

        char beamLabel[7];
        sprintf(beamLabel, "beam%02d", gBeamNumbers(ibeam));
        intRecOut.add(beamLabel, beamRecOut);
      }

      sprintf(labelOut, "int%02d", ++intOut);
      aggRecOut.add(labelOut, intRecOut);
      gFlushInt++;
    }

    // Return the data record to Glish.
    if (aggRecOut.exists("int01")) {
      glishBus->postEvent("flushed_data", aggRecOut);
    } else {
      finished(glishBus);
    }

  } else if (gBeamSw) {
    // Flush beam-switched mode buffer.
    if (!gFlushing) {
      gSubscanCount++;

      Int j = gSubscanCount % gSubscanIndex.nelements();
      gSubscanIndex(j) = gNInt;

      char text[120];
      sprintf(text, "EOF after integration %d; flushing buffer...", gNInt);
      logMessage(text);
      gFlushing = True;
    }

    if (beamSwSpectrum(True, intRecOut)) {
      aggRecOut.add("int01", intRecOut);
      glishBus->postEvent("flushed_data", aggRecOut);
    } else {
      finished(glishBus);
    }

  } else if (gMethod == "COMPACT") {
    // Check that argument is an array.
    if (glishVal.type() != GlishValue::ARRAY) {
      logWarning("WARNING: Argument to \"flush\" should be an array.");
      return True;
    }

    // Check for unfilled buffer
    if (gNInt < gPostCycles) {
      finished(glishBus);
      return True;
    }

    if (!gFlushing) {
      logMessage("Flushing buffer...");
      gFlushing = True;
      gFlushInt = max(0, gNInt-gPostCycles) + 1;
    }

    // Get number of integrations to flush.
    GlishArray glishArr = glishVal;
    Int num_ints;
    glishArr.get(num_ints);

    Int intOut = 0;
    while (gFlushInt <= gNInt && intOut < num_ints) {
      if (correctSpectrum(gFlushInt, intRecOut)) {
        char labelOut[6];
        sprintf(labelOut, "int%02d", ++intOut);
        aggRecOut.add(labelOut, intRecOut);
      } else {
        char text[120];
        sprintf(text, "WARNING: Discarding integration cycle %d.", gFlushInt);
        logWarning(text);
      }

      gFlushInt++;
    }

    // Return the data record to Glish.
    if (aggRecOut.exists("int01")) {
      glishBus->postEvent("flushed_data", aggRecOut);
    } else {
      finished(glishBus);
    }

  } else if (gMethod == "EXTENDED") {
    // Check that argument is an array.
    if (glishVal.type() != GlishValue::ARRAY) {
      logWarning("WARNING: Argument to \"flush\" should be an array.");
      return True;
    }

    if (!gFlushing) {
      // Calculate and apply the bandpass correction to the whole scan.
      logMessage("Calculating and applying bandpass correction...");
      correctExtended();

      logMessage("Flushing buffer...");
      gFlushing = True;
      gFlushInt = 1;
    }

    // Get number of integrations to flush.
    GlishArray glishArr = glishVal;
    Int num_ints;
    glishArr.get(num_ints);

    // Construct outgoing Glish record.
    Int intOut = 0;
    char labelOut[6];
    GlishRecord beamRecOut;
    Matrix<Float> baseLin(2, 2);
    Matrix<Float> baseSub(max(2,gFitDegree+1), 2);
    Matrix<Float> spectra(gNChan, gNPol);
    Matrix<uChar> flagtra(gNChan, gNPol);

    while (gFlushInt <= gNInt && intOut < num_ints) {
      Int target = gFlushInt++ - 1;
      GlishArray glishArr;

      for (Int iif = 0; iif < gNIF; iif++) {
        for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
          Double freqInc, refFreq;

          glishArr = gBufferIn(target,ibeam,iif).get("REF_FREQUENCY");
          glishArr.get(refFreq);
          glishArr = gBufferIn(target,ibeam,iif).get("RESOLUTION");
          glishArr.get(freqInc);

          Double newFreqInc, newRefFreq;
          for (Int ipol = 0; ipol < gNPol; ipol++) {
            // Create a reference to stop the compiler whinging.
            Vector<Float> spectrum = gSpecIn(ipol,ibeam,iif).row(target);
            Vector<uChar> flagtrum = gFlagIn(ipol,ibeam,iif).row(target);
            Vector<Float> baseLini = baseLin.column(ipol);
            Vector<Float> baseSubi = baseSub.column(ipol);

            // Apply post-bandpass corrections.
            postBandpass(iif, spectrum, flagtrum, baseLini, baseSubi,
                         gTime(target), gCoord(target,ibeam), refFreq,
                         freqInc, newRefFreq, newFreqInc);

            spectra.column(ipol) = spectrum;
            flagtra.column(ipol) = flagtrum;
          }

          beamRecOut = gBufferIn(target,ibeam,iif);
          beamRecOut.add("DOPPLER_FRAME", gOutFrame);
          beamRecOut.add("REF_FREQUENCY", newRefFreq);
          beamRecOut.add("RESOLUTION", newFreqInc);
          beamRecOut.add("BASELIN", baseLin);
          beamRecOut.add("BASESUB", baseSub);
          beamRecOut.add("FLOAT_DATA", spectra);
          beamRecOut.add("FLAGGED", compressFlags(flagtra));

          if (gEstimator == "RFIMED") {
            // This estimator modifies Tsys.
            Vector<Float> tsys(gNPol);
            for (Int ipol = 0; ipol < gNPol; ipol++) {
              tsys(ipol) = gTsysIn(ipol,ibeam,iif)(target);
            }
            beamRecOut.add("TSYS", tsys);
          }

          char beamLabel[7];
          sprintf(beamLabel, "beam%02d", gBeamNumbers(ibeam));
          intRecOut.add(beamLabel, beamRecOut);
        }

        sprintf(labelOut, "int%02d", ++intOut);
        aggRecOut.add(labelOut, intRecOut);
      }
    }

    // Return the data record to Glish.
    if (aggRecOut.exists("int01")) {
      glishBus->postEvent("flushed_data", aggRecOut);
    } else {
      finished(glishBus);
    }
  }

  return True;
}

//-------------------------------------------------------------- compressFlags

// Compress flag matrix if possible.

Matrix<uChar> compressFlags(Matrix<uChar> &flagtra)
{
  Bool compress = True;
  for (Int ipol = 0; ipol < gNPol; ipol++) {
    if (!allEQ(flagtra, flagtra(0,ipol))) compress = False;
  }

  if (compress) {
    return flagtra(Slice(0,1),Slice());
  } else {
    return flagtra;
  }
}

//-------------------------------------------------------------- logParameters

// Log the input parameters.

void logParameters(void)
{
  logMessage("   Parameter values:");

  // Pre-bandpass calibration options.
  logMessage("           Smoothing = " + gSmoothing);
  logMessage("       Prescale mode = " + gPrescaleMode);

  // Bandpass calibration parameters.
  logMessage("              Method = " + gMethod);

  if (gMethod == "FREQSW") {
    logMessage("          Max cycles = ", gMaxCycles);

    if (gMaxCycles > 2) {
      logMessage("   Grow mask minimum = ", gChanGrowMin, " (channel)");
      logMessage("   Grow mask extra   = ", gChanGrowAdd, " (channel)");
      logMessage("   Grow mask minimum = ", gTimeGrowMin, " (time)");
      logMessage("   Grow mask extra   = ", gTimeGrowAdd, " (time)");
    }

  } else {
    logMessage("   Estimator         = " + gEstimator);
    if (gEstimator == "RFIMED") {
      logMessage("      Clipping level = ", gRFIclip, " x bandpass RMS");
      logMessage("     Clip iterations = ", gRFIiter);
      logMessage("    Min integrations = ", gRFIminInt);
      logMessage("     Rejection level = ", gRFIlev, " x bandpass RMS");
      logMessage("   Flagging fraction = ", gRFIsFlag);
      logMessage("   Grow mask minimum = ", gChanGrowMin);
      logMessage("   Grow mask extra   = ", gChanGrowAdd);
    }

    if (gEstimator == "POLYFIT") {
      logMessage("   Polynomial degree = ", gPolyDegree);
      logMessage("        discriminant = ", gPolyDev, " x Dev");
      logMessage("          iterations = ", gPolyIter);
    }

    if (gStatRatio) {
      logMessage("   Statistic of ratios");
    } else {
      logMessage("   Ratio of statistics");
    }

    if (gMethod == "COMPACT") {
      logMessage("   Bandpass interval = ", gBandpassRecalc);
      logMessage("      No. precycles  = ", gPreCycles);
      logMessage("      No. postcycles = ", gPostCycles);

    } else {
      logMessage("          Max cycles = ", gMaxCycles);

      if (gMethod == "EXTENDED") {
        if (gEstimator == "MEDIAN" || gEstimator == "MEAN") {
          if (gBoxSize > 0) {
            if (gBoxReject) {
              logMessage("            Box size = ", gBoxSize, " (reject)");
            } else {
              logMessage("            Box size = ", gBoxSize, " (accept)");
            }
          } else {
            logMessage("            Box size = 0 (defeat)");
          }

        } else if (gEstimator == "RFIMED") {
          if (gBoxSize > 0) {
            logMessage("     Sub-scan length = ", gBoxSize);
          } else {
            logMessage("     Sub-scan length = whole scan");
          }

        } else if (gEstimator == "MEDMED" || gEstimator == "MINMED") {
          logMessage("    No. subdivisions = ", gNBoxes);
        }

      } else if (gMethod == "SCMX") {
        logMessage("              Margin = ", gMargin);
      }
    }

    if (gXbeam) {
      logMessage("   Cross-beam Tsys correction enabled");
    } else {
      logMessage("   Cross-beam Tsys correction disabled");
    }
  }

  // Post-bandpass calibration options.
  if (gFitDegree == -1) {
    logMessage("   No spectral baseline correction applied");
  } else if (gFitDegree == 0) {
    logMessage("   Median spectral baseline fit applied");
  } else if (gFitDegree == 1 && gL1Norm) {
    logMessage("   Linear L1 norm spectral baseline fit applied");
  } else {
    logMessage("   Robust polynomial baseline fit of degree ", gFitDegree,
               " applied");
  }

  if (gContinuum) {
    logMessage("   Continuum flux preserved");
  } else {
    logMessage("   Continuum flux discarded");
  }

  if (nfalse(gChanMask)) {
    // Derive the channel mask from the Boolean vector.
    char text[120] = "   Input channel mask: ";

    Int ichan = 0, jchan;
    for (jchan = 0; jchan < gNChan; jchan++) {
      if (ichan) {
        if (gChanMask(jchan)) {
          // End of range.
          if (jchan == ichan) {
            // Single isolated channel.
            strcat(text, ",");
          } else {
            // Channel range.
            sprintf(text+strlen(text), "-%d,", jchan);
          }
          ichan = 0;
        }

      } else if (!gChanMask(jchan)) {
        // Start of new channel range; report 1-rel channel number.
        ichan = jchan + 1;
        sprintf(text+strlen(text), "%d", ichan);
      }
    }

    if (ichan) {
      // End of last range.
      if (jchan != ichan) {
        sprintf(text+strlen(text), "-%d", jchan);
      }
    } else {
      // Chop off the trailing comma.
      text[strlen(text)] = '\0';
    }

    logMessage(text);

  } else {
    logMessage("   No channel mask specified");
  }

  logMessage("       Doppler frame = " + gOutFrame);
  if (gRescaleAxis) {
    logMessage("   Rescale freq axis = T");
  } else {
    logMessage("   Rescale freq axis = F");
  }


  // Validity checking.
  if (gMethod == "COMPACT") {
    if (gFast) {
      logMessage("   Check central beam only = T");
    } else {
      logMessage("   Check central beam only = F");
    }
  }

  if (gCheckFieldName) {
    logMessage("    Check field name = T");
  } else {
    logMessage("    Check field name = F");
  }

  if (gCheckTime) {
    logMessage("          Check time = T");
    if (gMethod == "COMPACT") {
      logMessage("               Tmin  = ", gTmin);
      logMessage("               Tmax  = ", gTmax);
    }
    logMessage("               Tjump = ", gTjump);
  } else {
    logMessage("          Check time = F");
  }

  if (gCheckPosition) {
    logMessage("      Check position = T");
    if (gMethod == "COMPACT") {
      logMessage("               Dmin  = ", gDmin);
      logMessage("               Dmax  = ", gDmax);
    }
    logMessage("               Djump = ", gDjump);
  } else {
    logMessage("      Check position = F");
  }
}

//------------------------------------------------------------ loadIntegration

// Buffer the data for a new integration.  Note that:
//
// 1) pksreader splits multiple simultaneous IFs into separate Glish records
//    with the same integration cycle number (CYCLE_NO).
//
// 2) MX mode observations are composed of multiple scans with the integration
//    cycle number (CYCLE_NO) restarting at 1 at the beginning of each scan.
//    The integration number, gNInt, maintained here is a continuous count
//    across scans of the integrations loaded.

Bool loadIntegration(GlishRecord &aggRec, Int intIn)
{
  char text[120];

  char intLabel[6];
  sprintf(intLabel, "int%02d", intIn);
  if (!aggRec.exists(intLabel)) {
    return False;
  }

  // Get beam-invariant parameters and do basic acceptance tests.
  GlishRecord intRec = aggRec.get(intLabel);
  GlishRecord beamRec = intRec.get(0);
  GlishArray glishArr;

  glishArr = beamRec.get("SCAN_NO");
  glishArr.get(gScanNo);

  Int cycleNo;
  glishArr = beamRec.get("CYCLE_NO");
  glishArr.get(cycleNo);

  Int nbeam = intRec.nelements();
  if (nbeam != gNBeam) {
    sprintf(text, "ERROR: Cycle %d:%d skipped, incorrect number of beams: "
            "%d -> %d.", gScanNo, cycleNo, gNBeam, nbeam);
    logError(text);
    return False;
  }

  Int IFNo;
  glishArr = beamRec.get("IFNO");
  glishArr.get(IFNo);

  for (gIF = 0; gIF < gNIF; gIF++) {
    if (IFNo == gIFNumbers(gIF)) break;
    if (gIFNumbers(gIF) == 0) {
      gIFNumbers(gIF) = IFNo;
      break;
    }
  }

  if (gIF == gNIF) {
    sprintf(text, "ERROR: Cycle %d:%d skipped, invalid IF number: %d.",
            gScanNo, cycleNo, IFNo);
    logError(text);
    return False;
  }

  String dopplerFrame;
  glishArr = beamRec.get("DOPPLER_FRAME");
  glishArr.get(dopplerFrame);

  if (gNInt == 0) {
    gInFrame = dopplerFrame;

    // Find out which beams are in the record.
    for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
      String beamLabel = intRec.name(ibeam);
      Int beamNo;
      sscanf(beamLabel.chars()+4, "%d", &beamNo);
      gBeamNumbers(ibeam) = beamNo;
    }

    // Check for referenced observations (Mopra).
    String obstype;
    glishArr = beamRec.get("OBSTYPE");
    glishArr.get(obstype);

    if (gRefSig = (gMethod == "REFERENCED")) {
      if (obstype.contains("RF") ||
          obstype.contains("PA") ||
          obstype.contains("SL")) {
        gNCycles = 1;

        for (Int iif = 0; iif < gNIF; iif++) {
          gRefCount(iif) = 0;
          gRefStart(iif) = True;
          gPaddleCount(iif) = 0;
          gPaddleStart(iif) = True;
          gSLevelCount(iif) = 0;
          gSLevelStart(iif) = True;
        }

        logMessage("Processing referenced data.");

      } else {
        gRefSig = False;
        logError("ERROR: REFERENCED method requested but data is not "
                 "referenced.");
        return False;
      }

    } else {
      // Check for beam-switched observations.
      if (gSCMX = (gMethod == "SCMX")) {
        // For bandpass ripple observations - P424.
        obstype = "SCMX";
        beamRec.add("OBSTYPE", obstype);
      }

      if (obstype.contains("MX")) {
        if (obstype.contains("SC")) {
          logMessage("Processing scanned, beam-switched data.");
        } else {
          logMessage("Processing beam-switched data.");
        }

        gBeamSw  = True;
        gRefbeam = 0;
        gSubscanIndex = 0;
        gSubscanCount = 0;
        gSubscanOut = 0;
        gIntOut  = 0;
      }
    }

  } else if (gNInt == 1 && !gRefSig) {
    // Check for frequency switching.
    gFreqSw = False;
    if (gNIF == 2 && gIFs(0,1-gIF) && !gIFs(0,gIF)) {
      Double freq0, freq1;
      glishArr = gBufferIn(0,0,1-gIF).get("REF_FREQUENCY");
      glishArr.get(freq0);
      glishArr = beamRec.get("REF_FREQUENCY");
      glishArr.get(freq1);

      if (gFreqSw = Bool(freq1 != freq0)) {
        logMessage("Processing frequency switched data.");
      }
    }
  }

  if (dopplerFrame != gInFrame) {
    sprintf(text, "ERROR: Cycle %d:%d skipped, reference frame changed: "
                  "\"%s\" -> \"%s\".", gScanNo, cycleNo, gInFrame.chars(),
                  dopplerFrame.chars());
    logError(text);
    return False;
  }

  if (gBeamSw) {
    glishArr = beamRec.get("REFBEAM");
    glishArr.get(gRefBeam);
  }


  // New integration only when the integration cycle number changes.
  if (cycleNo != gCycleNo) {
    gNInt++;
    gCycleNo = cycleNo;
  }

  Int curr = (gNInt-1) % gNCycles;
  gIntIn(curr) = gNInt;

  gIFs(curr,gIF) = True;

  glishArr = beamRec.get("FIELD_NAME");
  glishArr.get(gFieldNameIn(curr));

  glishArr = beamRec.get("TIME");
  glishArr.get(gTime(curr));


  // Check for breaks in field name or time.
  if (gNInt == 1) {
    gTStep(curr) = 0.0;

  } else {
    Int prev = (curr - 1 + gNCycles) % gNCycles;

    if (gCheckFieldName) {
      if (gFieldNameIn(curr) != gFieldNameIn(prev)) {
        sprintf(text, "WARNING: Cycle %d:%d, FIELD change detected: "
          "\"%s\" -> \"%s\"", gScanNo, gCycleNo, gFieldNameIn(prev).chars(),
          gFieldNameIn(curr).chars());
        logWarning(text);
      }
    }

    Bool checkTime = gCheckTime;
    if (gBeamSw && gCycleNo == 1) {
      // Quash warnings when reference beam changes.
      checkTime = False;
    }

    if (checkTime) {
      Double tJump = fabs(gTime(curr) - gTime(prev));
      gTStep(curr) = tJump;

      if (tJump > gTjump) {
        sprintf(text, "WARNING: Cycle %d:%d, TIME jump detected: %.1f sec.",
          gScanNo, gCycleNo, tJump);
        logWarning(text);
      }
    }
  }

  // Construct Doppler trackers.
  if (gVelTrack[gIF] == 0x0) {
    // Doppler correction.
    Double freqInc;
    glishArr = beamRec.get("RESOLUTION");
    glishArr.get(freqInc);

    // Antenna position (m), ITRF.
    Vector<Double> antPos;
    glishArr = beamRec.get("ANTENNA_POSITION");
    glishArr.get(antPos);

    gVelTrack[gIF] = new VelTracker(gRescaleAxis, gInFrame, gOutFrame,
                                    antPos, gNChan, freqInc);
  }

  // Extract all beams for this integration.
  for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
    if (!loadBeam(intRec, ibeam)) {
      gIntIn(curr) = -2;
      gNInt--;
      return False;
    }
  }

  return True;
}

//------------------------------------------------------------------- loadBeam

Bool loadBeam(GlishRecord &intRec, Int ibeam)
{
  char text[120];

  char beamLabel[7];
  Int beamNo = gBeamNumbers(ibeam);
  sprintf(beamLabel, "beam%02d", beamNo);

  if (!intRec.exists(beamLabel)) {
    sprintf(text, "ERROR: Integration skipped: beam %d has vanished!",
                  beamNo);
    logError(text);
    return False;
  }

  // Use a pointer to speed things up.
  Int curr = (gNInt-1) % gNCycles;
  GlishRecord *beamRec = &(gBufferIn(curr,ibeam,gIF));

  // Store the Glish record.
  *beamRec = intRec.get(beamLabel);

  // Record the position (same for each IF).
  GlishArray glishArr;
  glishArr = beamRec->get("POINTING_DIR");
  gCoord(curr,ibeam).resize(glishArr.shape());
  glishArr.get(gCoord(curr,ibeam));


  // Check for position jumps.
  if (gNInt == 1) {
    gDStep(curr,ibeam) = 0.0;

  } else {
    Int prev = (curr - 1 + gNCycles) % gNCycles;

    Bool checkPosition = gCheckPosition;
    if (gBeamSw && gCycleNo == 1) {
      // Quash warnings when reference beam changes.
      checkPosition = False;
    }

    if (checkPosition) {
      Double dJump = angularDist(gCoord(curr,ibeam)(0), gCoord(curr,ibeam)(1),
                                 gCoord(prev,ibeam)(0), gCoord(prev,ibeam)(1));
      dJump *= R2D * 60.0;
      gDStep(curr,ibeam) = dJump;

      if (dJump > gDjump) {
        char text[120];
        sprintf(text, "WARNING: Cycle %d:%d, beam %d, POSITION jump "
                      "detected: %.1f arcmin.", gScanNo, gCycleNo, beamNo,
                      dJump);
        logWarning(text);
      }
    }
  }


  // Check number of polarizations in data.
  Int npol;
  glishArr = beamRec->get("NOPOL");
  glishArr.get(npol);

  if (npol > 2 && gNPol < 1) {
    logWarning("WARNING: No more than two polarizations are supported - " \
               "ignoring complex cross-polarizations.");
  }

  if (npol > 2) {
    npol = 2;
  }

  if (npol != gNPol) {
    sprintf(text, "ERROR: Integration skipped, number of polarizations "
                  "changed from %d to %d.", gNPol, npol);
    logError(text);
    return False;
  }

  // Check number of channels in data.
  Int nchan;
  glishArr = beamRec->get("NUM_CHANNEL");
  glishArr.get(nchan);

  if (nchan != gNChan) {
    sprintf(text, "ERROR: Integration skipped, number of channels changed "
                  "from %d to %d.", gNChan, nchan);
    logError(text);
    return False;
  }


  // Extract and store Tsys.
  if (!beamRec->exists("TSYS")) {
    logError("ERROR: Integration skipped, Tsys information absent.");
    return False;
  }

  glishArr = beamRec->get("TSYS");
  Vector<Double> tdvec;
  tdvec.resize(glishArr.shape());
  glishArr.get(tdvec);
  for (Int ipol = 0; ipol < gNPol; ipol++) {
    gTsysIn(ipol,ibeam,gIF)(curr) = tdvec(ipol);
  }


  // Extract and store the spectra.
  if (!beamRec->exists("FLOAT_DATA")) {
    logError("ERROR: Integration skipped, no data in the incoming record.");
    return False;
  }

  glishArr = beamRec->get("FLOAT_DATA");
  Matrix<Float> spectra(glishArr.shape());
  glishArr.get(spectra);

  glishArr = beamRec->get("FLAGGED");
  Matrix<uChar> flagtra(spectra.shape());
  if (glishArr.shape()(0) == gNChan) {
    glishArr.get(flagtra);
  } else {
    // Uncompress the flagging matrix.
    Matrix<uChar> flagtmp(glishArr.shape());
    glishArr.get(flagtmp);
    for (Int iPol = 0; iPol < gNPol; iPol++) {
      flagtra.column(iPol) = flagtmp(0,iPol);
    }
  }

  // Purge the data arrays.
  beamRec->add("FLOAT_DATA", False);
  beamRec->add("FLAGGED", False);

  if (_test_FlagInput) {
    // Flag input channels based on prior knowledge (Parkes only).
    Double freqInc, refFreq;
    glishArr = beamRec->get("REF_FREQUENCY");
    glishArr.get(refFreq);

    glishArr = beamRec->get("RESOLUTION");
    glishArr.get(freqInc);

    String dopplerFrame;
    glishArr = beamRec->get("DOPPLER_FRAME");
    glishArr.get(dopplerFrame);

    if (dopplerFrame == String("TOPOCENT")) {
      // 1408 line tends to wander, annoyingly... this is the
      // 11th harmonic of the 128 MHz sampler clock so they say.
      gObsFilter.flagInFrame(flagtra, 1408e6, refFreq, freqInc);

      // 1400 line is apparently either the ethernet bridge or the
      // Hydrogen maser at PKS...
      gObsFilter.flagInFrame(flagtra, 1400e6, refFreq, freqInc);

      // following are unidentified, and not necessarily precise
      // gObsFilter.flagInFrame(flagtra, 1386e6,      refFreq, freqInc);
      // gObsFilter.flagInFrame(flagtra, 1372.3125e6, refFreq, freqInc);
      // gObsFilter.flagInFrame(flagtra, 1368e6,      refFreq, freqInc);
    }
  }

  if (_test_SmoothFlags) {
    gObsFilter.specInterpolate1D(spectra, flagtra);
  }

  if (gFilter) {
    for (Int ipol = 0; ipol < gNPol; ipol++) {
      Vector<Float> spectrum = spectra.column(ipol);
      gFilter->doFilter(spectrum);
      spectra.column(ipol) = spectrum;
    }
  }

  if (_test_GrowFlags) {
    gObsFilter.specGrowFlags(flagtra, 1);
  }

  Bool doPrescale = Bool(gPrescaleMode != "NONE");
  Bool doMedian   = Bool(gPrescaleMode == "MEDIAN");
  for (Int ipol = 0; ipol < gNPol; ipol++) {
    Float scale = 1.0f;

    if (doPrescale) {
      if (doMedian) {
        scale /= median(spectra.column(ipol), False, True);
      } else {
        scale /= mean(spectra.column(ipol));
      }
    }

    gSpecIn(ipol,ibeam,gIF).row(curr) = spectra.column(ipol)*scale;
    gFlagIn(ipol,ibeam,gIF).row(curr) = flagtra.column(ipol);
  }

  return True;
}

//------------------------------------------------------------------- finished

void finished(GlishSysEventSource *glishBus)
{
  logMessage("Finished processing.");

  glishBus->postEvent("finished", gClientName);
}

//---------------------------------------------------------------- refSpectrum

// Process a referenced spectrum.

Bool refSpectrum(GlishRecord &intRecOut)
{
  // Get the OBSTYPE card recorded in the RPFITS header.
  String obstype;
  GlishArray glishArr = gBufferIn(0,0,gIF).get("OBSTYPE");
  glishArr.get(obstype);


  // Is this a paddle scan?
  if (obstype.contains("PA") || obstype.contains("SL")) {
    // Paddle scan, skip it.
    if (gPaddleStart(gIF)) {
      gPaddleCount(gIF) = 0;
      gPaddleStart(gIF) = False;
    }

    gPaddleCount(gIF)++;
    return False;

  } else if (!gPaddleStart(gIF)) {
    // No, finalise paddle scan bookkeeping.
    char text[120];
    sprintf(text, "Skipped %d paddle integrations for IF %d.",
            gPaddleCount(gIF), gIFNumbers(gIF));
    logMessage(text);

    gPaddleStart(gIF) = True;
  }


  // Is this a signal level setting scan?
  if (obstype.contains("SL")) {
    // Signal level setting scan, skip it.
    if (gSLevelStart(gIF)) {
      gSLevelCount(gIF) = 0;
      gSLevelStart(gIF) = False;
    }

    gSLevelCount(gIF)++;
    return False;

  } else if (!gSLevelStart(gIF)) {
    // No, finalise signal level scan bookkeeping.
    char text[120];
    sprintf(text, "Skipped %d signal level setting integrations for IF %d.",
            gSLevelCount(gIF), gIFNumbers(gIF));
    logMessage(text);

    gSLevelStart(gIF) = True;
  }


  // Is it a reference spectrum?
  if (obstype.contains("RF")) {
    // It is, restart reference accumulation?
    if (gRefStart(gIF)) {
      gRefCount(gIF) = 0;
      gRefStart(gIF) = False;
    }

    for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
      for (Int ipol = 0; ipol < gNPol; ipol++) {
        // Accumulate reference spectra.
        if (gRefCount(gIF)) {
          gTsys(ipol,ibeam,gIF)     += gTsysIn(ipol,ibeam,gIF)(0);
          gBandpass(ipol,ibeam,gIF) += gSpecIn(ipol,ibeam,gIF).row(0);
        } else {
          gTsys(ipol,ibeam,gIF)     = 0.0f;
          gBandpass(ipol,ibeam,gIF) = 0.0f;
        }
      }
    }

    gRefCount(gIF)++;
    return False;

  } else if (!gRefStart(gIF)) {
    // No, finish accumuating reference spectra.
    Float refCount = gRefCount(gIF);
    for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
      for (Int ipol = 0; ipol < gNPol; ipol++) {
        // Form averages.
        gTsys(ipol,ibeam,gIF)     /= refCount;
        gBandpass(ipol,ibeam,gIF) /= refCount;
      }
    }
    
    char text[120];
    sprintf(text, "New reference spectrum formed for IF %d, %d integrations.",
            gIFNumbers(gIF), gRefCount(gIF));
    logMessage(text);

    gRefStart(gIF) = True;
  }


  // Must be a signal spectrum, do we have a reference spectrum for this IF?
  if (gRefCount(gIF) < 1) {
    return False;
  }

  // Apply bandpass correction.
  Vector<Matrix<Float> > spectra(gNBeam);
  Vector<Matrix<uChar> > flagtra(gNBeam);
  for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
    spectra(ibeam).resize(gNChan, gNPol);
    flagtra(ibeam).resize(gNChan, gNPol);

    for (Int ipol = 0; ipol < gNPol; ipol++) {
      // Create a reference to stop the compiler whinging.
      Vector<Float> spectrum = spectra(ibeam).column(ipol);
      Vector<uChar> flagtrum = flagtra(ibeam).column(ipol);

      spectrum  = gSpecIn(ipol,ibeam,gIF).row(0) - gBandpass(ipol,ibeam,gIF);
      spectrum /= gBandpass(ipol,ibeam,gIF);
      spectrum *= gTsys(ipol,ibeam,gIF);
      flagtrum  = gFlagIn(ipol,ibeam,gIF).row(0);
    }
  }


  // Do cross-beam Tsys correction (for continuum sources).
  if (gXbeam) {
    Matrix<Float> xbeam(gNBeam, gNPol, 0.0f);

    // RFI-induced excess Tsys appearing simultaneously in each beam.
    for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
      for (Int ipol = 0; ipol < gNPol; ipol++) {
        Vector<Float> spectrum = spectra(ibeam).column(ipol);
        xbeam(ibeam,ipol) = mean(spectrum) / gTsys(ipol,ibeam,gIF);
      }
    }

    Float xsTsys = median(xbeam, False, True);

    // Correct for excess Tsys.
    for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
      for (Int ipol = 0; ipol < gNPol; ipol++) {
        Vector<Float> spectrum = spectra(ibeam).column(ipol);
        spectrum -= xsTsys * gTsys(ipol,ibeam,gIF);
      }
    }
  }


  // Apply post-bandpass corrections and write out the calibrated spectra.
  GlishRecord beamRecOut;

  Matrix<Float> baseLin(2,2);
  Matrix<Float> baseSub(max(2,gFitDegree+1),2);

  for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
    Double refFreq, freqInc;
    glishArr = gBufferIn(0,0,gIF).get("REF_FREQUENCY");
    glishArr.get(refFreq);
    glishArr = gBufferIn(0,0,gIF).get("RESOLUTION");
    glishArr.get(freqInc);

    Double newFreqInc, newRefFreq;
    for (Int ipol = 0; ipol < gNPol; ipol++) {
      Vector<Float> spectrum = spectra(ibeam).column(ipol);
      Vector<uChar> flagtrum = flagtra(ibeam).column(ipol);
      Vector<Float> baseLini = baseLin.column(ipol);
      Vector<Float> baseSubi = baseSub.column(ipol);

      // Apply post-bandpass corrections.
      postBandpass(gIF, spectrum, flagtrum, baseLini, baseSubi, gTime(0),
                   gCoord(0,ibeam), refFreq, freqInc, newRefFreq, newFreqInc);
    }

    // Construct outgoing Glish record.
    beamRecOut = gBufferIn(0,ibeam,gIF);
    beamRecOut.add("DOPPLER_FRAME", gOutFrame);
    beamRecOut.add("REF_FREQUENCY", newRefFreq);
    beamRecOut.add("RESOLUTION", newFreqInc);
    beamRecOut.add("BASELIN", baseLin);
    beamRecOut.add("BASESUB", baseSub);
    beamRecOut.add("FLOAT_DATA", spectra(ibeam));
    beamRecOut.add("FLAGGED", compressFlags(flagtra(ibeam)));

    char beamLabel[7];
    sprintf(beamLabel, "beam%02d", gBeamNumbers(ibeam));
    intRecOut.add(beamLabel, beamRecOut);
  }

  return True;
}

//------------------------------------------------------------- freqSwSpectrum

// Pair-wise frequency switching: normalize the spectrum in buffer location 0
// against that in location 1, or vice versa.  This is inherently insensitive
// to continuum flux density.

void freqSwSpectrum(Int target, GlishRecord &intRecOut)
{
  Int ibeam, ipol;
  GlishRecord beamRecOut;

  Matrix<Float> spectra(gNChan, gNPol);
  Matrix<uChar> flagtra(gNChan, gNPol);
  Matrix<Float> quartic(5,gNPol);
  Matrix<Float> octic(9,gNPol);

  Int iif = gIFs(target,1) ? 1 : 0;

  // Location 0 or 1 normalized against location 1 or 0.
  GlishArray glishArr;
  for (ibeam = 0; ibeam < gNBeam; ibeam++) {
    Double freqInc, refFreq;
    glishArr = gBufferIn(target,ibeam,iif).get("REF_FREQUENCY");
    glishArr.get(refFreq);
    glishArr = gBufferIn(target,ibeam,iif).get("RESOLUTION");
    glishArr.get(freqInc);

    Double newFreqInc, newRefFreq;
    for (ipol = 0; ipol < gNPol; ipol++) {
      // Create a reference to stop the compiler whinging.
      Vector<Float> spectrum = spectra.column(ipol);
      Vector<uChar> flagtrum = flagtra.column(ipol);

      spectrum = gTsysIn(ipol,ibeam,iif)(target) *
        (gSpecIn(ipol,ibeam,iif).row(target) /
         gSpecIn(ipol,ibeam,1-iif).row(1-target) - 1.0f);
      flagtrum = gFlagIn(ipol,ibeam,iif).row(target);

      // Doppler reference frame conversion.
      Double chanShift;
      gVelTrack[iif]->correct(gTime(target), gCoord(target,ibeam), refFreq,
                              freqInc, newRefFreq, newFreqInc, chanShift,
                              spectrum);
    }

    // Do robust polynomial baseline fit.
    gBasePoly->setMask(gChanMask);
    gBasePoly->fit(spectra, quartic, 1, 2.0f, False);
    gBasePoly->fit(spectra, octic,   3, 2.0f, False);

    // Uncomment these to display discarded channels.
    // Vector<Bool> fitMask(gNChan);
    // gBasePoly->getMask(fitMask);
    // spectra.column(0)(!fitMask) = -1.0f;
    // spectra.column(1)(!fitMask) = -1.0f;

    // Construct outgoing Glish record.
    beamRecOut = gBufferIn(target,ibeam,iif);
    beamRecOut.add("DOPPLER_FRAME", gOutFrame);
    beamRecOut.add("REF_FREQUENCY", newRefFreq);
    beamRecOut.add("RESOLUTION", newFreqInc);
    beamRecOut.add("FLOAT_DATA", spectra);
    beamRecOut.add("FLAGGED", compressFlags(flagtra));

    char beamLabel[7];
    sprintf(beamLabel, "beam%02d", gBeamNumbers(ibeam));
    intRecOut.add(beamLabel, beamRecOut);
  }
}

//----------------------------------------------------------------- freqSwScan

// Scan-wise frequency switching: reference spectra for sig/ref and ref/sig
// are constructed from the whole scan, c.f. correctExtended().

void freqSwScan(void)
{
  // Parameters that might be set from the GUI.
  Bool scanning = True;
  Int maskMin = 10;

  // Ensure that gNInt is even.
  if (gNInt%2) gNInt--;

  Vector<Bool>  timeMask(gNInt/2), chanMask(gNChan);
  Vector<Float> avquot(gNChan);

  Slice scan0 = Slice(0, gNInt/2, 2);
  Slice scan1 = Slice(1, gNInt/2, 2);

  Matrix<Float> deg15(16,gNPol);
  Matrix<Float> baseSub(max(2,gFitDegree+1),2);

  Int iif = gIFs(0,1) ? 1 : 0;
  for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
    for (Int ipol = 0; ipol < gNPol; ipol++) {
      // Form quotients.
      for (Int ichan = 0; ichan < gNChan; ichan++) {
        // Usual compiler pacifier.
        Vector<Float> spec0 = gSpecIn(ipol,ibeam,iif).column(ichan)(scan0);
        Vector<Float> spec1 = gSpecIn(ipol,ibeam,1-iif).column(ichan)(scan1);

        // Compute quotients.
        if (scanning) {
          spec0 /= spec1;
          spec1 = 1.0f / spec0;
        } else {
          // Appropriate when tracking a source.
          Float med0 = median(spec0, False, True);
          Float med1 = median(spec1, False, True);
          spec0 /= med1;
          spec1 /= med0;
        }
      }


      // Determine the time-average quotient value (avquot) in each channel.
      // This is done in two passes which differ only in the method of
      // rejecting line emission (and RFI, etc.).

      // First pass, set the discriminant for rejecting line emission to 3x
      // the median of the absolute median deviation.
      Vector<Float> meds(gNInt/2);
      for (Int i = 0; i < gNInt/2; i++) {
        Vector<Float> s = gSpecIn(ipol,ibeam,iif).row(2*i);
        meds(i) = median(s, False, True);
      }
      Float med = median(meds, False, True);

      for (Int i = 0; i < gNInt/2; i++) {
        Vector<Float> s = gSpecIn(ipol,ibeam,iif).row(2*i);
        meds(i) = median(abs(s - med), False, True);
      }
      Float discrim = 3.0f * median(meds, False, True);

      avquot = 1.0f;
      chanMask = False;
      for (Int ichan = 0; ichan < gNChan; ichan++) {
        // Line detection.
        Vector<Float> spec0 = gSpecIn(ipol,ibeam,iif).column(ichan)(scan0);
        timeMask = abs(spec0 - med) < discrim;

        // Broaden the time mask.
        if (gTimeGrowMin > 0.0f || gTimeGrowAdd > 0.0f) {
          growMask(timeMask, gTimeGrowMin, gTimeGrowAdd);
        }

        // Check that there are enough data to form an average.
        Bool someMask = Int(ntrue(timeMask)) > gNInt/maskMin;
        if (someMask) {
          chanMask(ichan) = True;
          avquot(ichan) = median(spec0(timeMask), False, True);
        }
      }

      // Broaden the channel mask.
      if (gChanGrowMin > 0.0f || gChanGrowAdd > 0.0f) {
        growMask(chanMask, gChanGrowMin, gChanGrowAdd);
      }

      // Do a robust polynomial fit.
      Matrix<Float> residuals(gNChan,1);
      residuals.column(0) = avquot;
      chanMask = chanMask && gChanMask;
      gBasePoly->setMask(chanMask);
      gBasePoly->fit(residuals, deg15, 2, 3.0f, False);
      avquot -= residuals.column(0);

      // Second pass, set the discriminant for rejecting line emission to 2x
      // the median of the absolute deviation from the time-average quotient
      // value (avquot) computed in the first pass.
      for (Int i = 0; i < gNInt/2; i++) {
        Vector<Float> s = gSpecIn(ipol,ibeam,iif).row(2*i);
        meds(i) = median(abs(s - avquot), False, True);
      }
      discrim = 2.0f * median(meds, False, True);

      chanMask = False;
      for (Int ichan = 0; ichan < gNChan; ichan++) {
        // Line detection.
        Vector<Float> spec0 = gSpecIn(ipol,ibeam,iif).column(ichan)(scan0);
        timeMask = abs(spec0 - avquot(ichan)) < discrim;

        // Broaden the time mask.
        if (gTimeGrowMin > 0.0f || gTimeGrowAdd > 0.0f) {
          growMask(timeMask, gTimeGrowMin, gTimeGrowAdd);
        }

        // Check that there are enough data to form an average.
        Bool someMask = Int(ntrue(timeMask)) > gNInt/maskMin;
        if (someMask) {
          chanMask(ichan) = True;
          avquot(ichan) = median(spec0(timeMask), False, True);
        }
      }

      // Broaden the channel mask.
      if (gChanGrowMin > 0.0f || gChanGrowAdd > 0.0f) {
        growMask(chanMask, gChanGrowMin, gChanGrowAdd);
      }

      // Interpolate the masked channels using a robust polynomial fit.
      residuals.column(0) = avquot;
      chanMask = chanMask && gChanMask;
      gBasePoly->setMask(chanMask);
      gBasePoly->fit(residuals, deg15, 2, 3.0f, False);
      avquot -= residuals.column(0);

      // Apply the calibration using this estimate of the intrinsic quotient
      // value as a function of channel.
      for (Int ichan = 0; ichan < gNChan; ichan++) {
        // Usual compiler pacifier.
        Vector<Float> spec0 = gSpecIn(ipol,ibeam,iif).column(ichan)(scan0);
        Vector<Float> spec1 = gSpecIn(ipol,ibeam,1-iif).column(ichan)(scan1);

        spec0 /= avquot(ichan);
        spec1 *= avquot(ichan);
      }

      // Rescale.
      Vector<Float> tsys0 = gTsysIn(ipol,ibeam,iif)(scan0);
      Vector<Float> tsys1 = gTsysIn(ipol,ibeam,1-iif)(scan1);
      Vector<Float> mTsys(2);
      mTsys(0) = median(tsys0, False, True);
      mTsys(1) = median(tsys1, False, True);

      for (Int i = 0; i < gNInt; i++) {
        Int iif = gIFs(i,1) ? 1 : 0;
        Vector<Float> s = gSpecIn(ipol,ibeam,iif).row(i);

        s *= gTsysIn(ipol,ibeam,iif)(i) / mean(s);
        s -= mTsys(iif);
      }

      // Do the post-bandpass baseline fit.
      if (gFitDegree >= 0) {
        for (Int i = 0; i < gNInt; i++) {
          Int iif = gIFs(i,1) ? 1 : 0;
          Vector<Float> s = gSpecIn(ipol,ibeam,iif).row(i);

          med = median(s(gChanMask), False, True);
          discrim = 3.0f * median(abs(s - med), False, True);
          chanMask = abs(s - med) < discrim;
          if (gChanGrowMin > 0.0f || gChanGrowAdd > 0.0f) {
            growMask(chanMask, gChanGrowMin, gChanGrowAdd);
          }

          Matrix<Float> spectrum = gSpecIn(ipol,ibeam,iif).row(i);
          chanMask = chanMask && gChanMask;
          gBasePoly->setMask(chanMask);
          gBasePoly->fit(spectrum, baseSub, 2, 2.0f, False);
//s(!chanMask) = 0.0f;
        }
      }
    }
  }
}

//------------------------------------------------------------- beamSwSpectrum

// Accumulate complete subscans before bandpass correction.  In MX mode, the
// source is tracked by each beam in turn for the specified number of
// integrations.  The scan is thereby divided into "subscans", usually one for
// each beam.

Bool beamSwSpectrum(Bool flush, GlishRecord &intRecOut)
{
  // For the time being, assume only one IF in beam-switching mode.
  char text[120];
  Int iif = 0, j;

  Int nSubscanIndex = gSubscanIndex.nelements();

  if (!flush) {
    // Check for new reference beam.
    j = gSubscanCount % gRefbeam.nelements();
    if (gNInt == 1 || gRefBeam != gRefbeam(j)) {
      // Number of complete subscans loaded.
      if (gNInt > 1) gSubscanCount++;

      // Integration count at the end of the subscan (i.e. the previous one).
      j = gSubscanCount % nSubscanIndex;
      gSubscanIndex(j) = gNInt - 1;

      j = gSubscanCount % gRefbeam.nelements();
      gRefbeam(j) = gRefBeam;

      // Notification.
      sprintf (text, "Cycle %d:%d, integration %2d, new beam-switching "
               "reference beam: %d.", gScanNo, gCycleNo, gNInt, gRefBeam);
      logMessage(text);
    }

    // Check that the reference beam is present.
    Int jbeam = 0;
    while (jbeam < gNBeam && gBeamNumbers(jbeam) != gRefBeam) {
      jbeam++;
    }

    if (jbeam >= gNBeam) {
      sprintf(text, "WARNING: Cycle %d:%d, reference beam, %d, is absent "
                    "from data.", gScanNo, gCycleNo, gRefBeam);
      logWarning(text);
    }
  }


  // Do we have any data to send back?
  if (flush) {
    // Flushing - dump this subscan.
    j =  gSubscanCount % nSubscanIndex;
  } else {
    // Still accumulating - dump the previous subscan.
    j = (gSubscanCount-1) % nSubscanIndex;
  }

  Bool emitData = gSubscanCount > 1 && gIntOut < gSubscanIndex(j);

  if (emitData) {
    // We do have something to send back.
    j = gSubscanOut % nSubscanIndex;

    if (gIntOut == gSubscanIndex(j)) {
      // Start writing out a new subscan.
      gSubscanOut++;

      // With regard to buffer recycling, the buffer must be large enough to
      // contain the previous, current, and following subscans, plus the first
      // integration of the subscan following that.
      //
      // For example, if subscan 2 is being processed, the buffer must contain
      // all of subscans 1, 2, and 3 plus the first integration of 4, the
      // presence of which told us that subscan 3 had finished.  The reference
      // spectrum for 2 is computed once when the first integration of subscan
      // 4 is read, and the first integration of subscan 2 is then written
      // out.  The space occupied by subscan 1 is then available for the
      // second and subsequent integrations of subscan 4, and the first
      // integration of subscan 5.

      // Identify integrations used to construct the reference spectrum...
      Int j1, j2;
      Int overrun = 0;
      Int signal  = 0;
      Vector<Int> imask(gNCycles, 0);

      // ...the subscan preceeding,...
      if (gSubscanOut > 1) {
        j1 = gSubscanIndex((gSubscanOut-2) % nSubscanIndex);
        j2 = gSubscanIndex((gSubscanOut-1) % nSubscanIndex);

        for (j = j1; j < j2; j++) {
          Int k = j%gNCycles;
          if (imask(k)) {
            overrun++;
          }

          imask(k) = 1;
        }
      }

      // ...the signal subscan,...
      j1 = gSubscanIndex((gSubscanOut-1) % nSubscanIndex);
      j2 = gSubscanIndex( gSubscanOut % nSubscanIndex);

      for (j = j1; j < j2; j++) {
        Int k = j%gNCycles;
        if (imask(k)) {
          overrun++;
          if (imask(k) == 2) {
            signal++;
          }
        }

        imask(k) = 2;
      }

      // ...the subscan following...
      if (gSubscanOut < gSubscanCount) {
        j1 = gSubscanIndex( gSubscanOut % nSubscanIndex);
        j2 = gSubscanIndex((gSubscanOut+1) % nSubscanIndex);

        for (j = j1; j < j2; j++) {
          Int k = j%gNCycles;
          if (imask(k)) {
            overrun++;
            if (imask(k) == 2) {
              signal++;
            }
          }

          imask(k) = 3;
        }

        if (!flush) {
          // ...and the first integration of the subscan after that.
          Int k = gSubscanIndex((gSubscanOut+1) % nSubscanIndex) % gNCycles;
          if (imask(k)) {
            overrun++;
            if (imask(k) == 2) {
              signal++;
            }
          }

          imask(k) = 4;
        }
      }

      Vector<Bool> mask(gNCycles);
      if (gSCMX && gMargin > 0) {
        mask = (imask == 2);

        j1 = gSubscanIndex((gSubscanOut-1) % nSubscanIndex) + gMargin;
        j2 = gSubscanIndex( gSubscanOut % nSubscanIndex)    - gMargin;

        for (j = j1; j < j2; j++) {
          mask(j%gNCycles) = False;
        }

      } else {
        mask = (imask == 1 || imask == 3);
      }

      if (overrun) {
        sprintf (text, "ERROR: CYCLIC BUFFER OVERRUN, count: %d (%d signal).  "
                       "The reference spectrum will be degraded.", overrun,
                       signal);
        logError(text);

        sprintf(text, "Increase the buffer size (nPreCycles + nPostCycles + "
                      "1) from %d to at least %d.", gNCycles,
                      gNCycles+overrun);
        logError(text);

        if (signal) {
          // Don't send signal spectra that were overrun.
          gIntOut += signal;

          // Anything left?
          if (allNE(imask, 2)) {
            logError("SEVERE ERROR: ALL SIGNAL SPECTRA HAVE BEEN OVERRUN IN "
                     "THE CYCLIC BUFFER.");
            return False;
          }

          logError("SEVERE ERROR: SOME SIGNAL SPECTRA HAVE BEEN OVERRUN IN "
                   "THE CYCLIC BUFFER.");
        }
      }

      // This can happen for the last subscan.
      if (allEQ(mask, False)) {
        logError("SEVERE ERROR: ALL REFERENCE SPECTRA HAVE BEEN OVERRUN IN "
                 "THE CYCLIC BUFFER.");
        return False;
      }


      // Form reference spectrum for this subscan.
      if (gEstimator == "POLYFIT") {
        // Set up robust polynomial fitter.
        Vector<Float> integs(gNCycles, floatNaN());
        for (j = 0; j < gNInt; j++) {
          Int k = j%gNCycles;
// SHOULD BE DONE OVER TIME, NOT INTEGRATION NUMBER.
          if (mask(k)) integs(k) = Float(j);
        }

        if (gBandPoly) delete gBandPoly;
        gBandPoly = new RPolyFit<Float>(gPolyDegree+1, integs);

        Matrix<Float> residuals(gNCycles,1);
        Matrix<Float> coeffs(gPolyDegree+1,1);
        gTsysCoeffs.resize(gNBeam,gNPol);
        gSpecCoeffs.resize(gNBeam,gNPol);

        for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
          for (Int ipol = 0; ipol < gNPol; ipol++) {
            Vector<Float> tsysIn;
            tsysIn = gTsysIn(ipol,ibeam,iif);

            // Do robust polynomial fit to Tsys.
            gTsysCoeffs(ibeam,ipol).resize(gPolyDegree+1,1);
            residuals = tsysIn;
            if (gBandPoly->fit(residuals, coeffs, gPolyIter, gPolyDev)) {
              tsysIn -= residuals.column(0);
            } else {
              logError("ERROR: RPolyFit FAILED FOR Tsys: " +
                gBandPoly->errMsg() + ".");
              coeffs = 0.0f;
            }
            gTsysCoeffs(ibeam,ipol) = coeffs;

            // Do robust polynomial fit for each channel.
            gSpecCoeffs(ibeam,ipol).resize(gPolyDegree+1,gNChan);
            for (Int ichan = 0; ichan < gNChan; ichan++) {
              Vector<Float> channelIn =
                gSpecIn(ipol,ibeam,iif).column(ichan);

              residuals = tsysIn / channelIn;
              if (gBandPoly->fit(residuals, coeffs, gPolyIter, gPolyDev)) {
                gSpecCoeffs(ibeam,ipol).column(ichan) = coeffs.column(0);
              } else {
                logError("ERROR: RPolyFit FAILED FOR SPECTRUM: " +
                  gBandPoly->errMsg() + ".");
                gSpecCoeffs(ibeam,ipol).column(ichan) = 0.0f;
              }
            }
          }
        }

      } else {
        Bool doMedian = Bool(gEstimator == "MEDIAN");
        for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
          for (Int ipol = 0; ipol < gNPol; ipol++) {
            Vector<Float> tsysIn = gTsysIn(ipol,ibeam,iif);

            Float tsys;
            if (doMedian) {
              tsys = median(tsysIn(mask), False, True);
            } else {
              tsys = mean(tsysIn(mask));
            }
            gTsys(ipol,ibeam,iif) = tsys;

            Vector<Float> bandpass = gBandpass(ipol,ibeam,iif);
            if (gStatRatio) {
              // Reciprocal of the gain for this channel.
              Vector<Float> factors;

              if (doMedian) {
                for (Int ichan = 0; ichan < gNChan; ichan++) {
                  factors = tsysIn / gSpecIn(ipol,ibeam,iif).column(ichan);
                  bandpass(ichan) = median(factors(mask), False, True);
                }
              } else {
                for (Int ichan = 0; ichan < gNChan; ichan++) {
                  factors = tsysIn / gSpecIn(ipol,ibeam,iif).column(ichan);
                  bandpass(ichan) = mean(factors(mask));
                }
              }

            } else {
              if (doMedian) {
                for (Int ichan = 0; ichan < gNChan; ichan++) {
                  Vector<Float> channelIn =
                    gSpecIn(ipol,ibeam,iif).column(ichan);
                  bandpass(ichan) = tsys /
                    median(channelIn(mask), False, True);
                }

              } else {
                for (Int ichan = 0; ichan < gNChan; ichan++) {
                  Vector<Float> channelIn =
                    gSpecIn(ipol,ibeam,iif).column(ichan);
                  bandpass(ichan) = tsys / mean(channelIn(mask));
                }
              }
            }
          }
        }

        sprintf(text, "Start flushing subscan %d at integration %d.",
                       gSubscanOut, gIntOut+1);
        logMessage(text);
      }
    }


    // Apply bandpass correction.
    Int target = gIntOut % gNCycles;
    Vector<Matrix<Float> > spectra(gNBeam);
    Vector<Matrix<uChar> > flagtra(gNBeam);
    for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
      spectra(ibeam).resize(gNChan, gNPol);
      flagtra(ibeam).resize(gNChan, gNPol);

      for (Int ipol = 0; ipol < gNPol; ipol++) {
        // Create a reference to stop the compiler whinging.
        Vector<Float> spectrum = spectra(ibeam).column(ipol);
        Vector<uChar> flagtrum = flagtra(ibeam).column(ipol);

        if (gEstimator == "POLYFIT") {
          // Compute the time-variable correction.
          Double xi = Float(gIntOut);

          Vector<Float> coeffs = gTsysCoeffs(ibeam,ipol).column(0);
          Double z = 0.0;
          for (Int j = gPolyDegree; j >= 0; j--) {
            z *= xi;
            z += coeffs(j);
          }
          gTsys(ipol,ibeam,iif) = z;

          for (Int ichan = 0; ichan < gNChan; ichan++) {
            Vector<Float> coeffs = gSpecCoeffs(ibeam,ipol).column(ichan);
            z = 0.0;
            for (Int j = gPolyDegree; j >= 0; j--) {
              z *= xi;
              z += coeffs(j);
            }

            gBandpass(ipol,ibeam,iif)(ichan) = z;
          }
        }

        spectrum = gSpecIn(ipol,ibeam,iif).row(target) *
                     gBandpass(ipol,ibeam,iif) - gTsys(ipol,ibeam,iif);
        flagtrum = gFlagIn(ipol,ibeam,iif).row(target);
      }
    }


    // Do cross-beam Tsys correction (for continuum sources).
    if (gXbeam) {
      Matrix<Float> xbeam(gNBeam, gNPol, 0.0f);

      // RFI-induced excess Tsys appearing simultaneously in each beam.
      for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
        for (Int ipol = 0; ipol < gNPol; ipol++) {
          Vector<Float> spectrum = spectra(ibeam).column(ipol);
          xbeam(ibeam,ipol) = mean(spectrum) / gTsys(ipol,ibeam,iif);
        }
      }

      Float xsTsys = median(xbeam, False, True);

      // Correct for excess Tsys.
      for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
        for (Int ipol = 0; ipol < gNPol; ipol++) {
          Vector<Float> spectrum = spectra(ibeam).column(ipol);
          spectrum -= xsTsys * gTsys(ipol,ibeam,iif);
        }
      }
    }


    // Apply post-bandpass corrections and write out the calibrated spectra.
    GlishArray glishArr;
    GlishRecord beamRecOut;

    Matrix<Float> baseLin(2,2);
    Matrix<Float> baseSub(max(2,gFitDegree+1),2);

    for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
      Double refFreq, freqInc;
      glishArr = gBufferIn(target,0,iif).get("REF_FREQUENCY");
      glishArr.get(refFreq);
      glishArr = gBufferIn(target,0,iif).get("RESOLUTION");
      glishArr.get(freqInc);

      Double newFreqInc, newRefFreq;
      for (Int ipol = 0; ipol < gNPol; ipol++) {
        Vector<Float> spectrum = spectra(ibeam).column(ipol);
        Vector<uChar> flagtrum = flagtra(ibeam).column(ipol);
        Vector<Float> baseLini = baseLin.column(ipol);
        Vector<Float> baseSubi = baseSub.column(ipol);

        // Apply post-bandpass corrections.
        postBandpass(iif, spectrum, flagtrum, baseLini, baseSubi,
                     gTime(target), gCoord(target,ibeam), refFreq,
                     freqInc, newRefFreq, newFreqInc);
      }

      // Construct outgoing Glish record.
      beamRecOut = gBufferIn(target,ibeam,iif);
      beamRecOut.add("DOPPLER_FRAME", gOutFrame);
      beamRecOut.add("REF_FREQUENCY", newRefFreq);
      beamRecOut.add("RESOLUTION", newFreqInc);
      beamRecOut.add("BASELIN", baseLin);
      beamRecOut.add("BASESUB", baseSub);
      beamRecOut.add("FLOAT_DATA", spectra(ibeam));
      beamRecOut.add("FLAGGED", compressFlags(flagtra(ibeam)));

      if (gSCMX && ibeam == 0) {
        // Fix source coordinates; only the scan start position was stored.
        String srcName;
        glishArr = beamRecOut.get("SOURCE_NAME");
        glishArr.get(srcName);

        Vector<Double> srcDir(2);
        if (srcName == "0008-421") {
          srcDir(0) =   2.71883 * D2R;
          srcDir(1) = -41.88633 * D2R;
          beamRecOut.add("REFERENCE_DIR", srcDir);

        } else if (srcName == "0408-65") {
          srcDir(0) =  62.08491 * D2R;
          srcDir(1) = -65.75252 * D2R;
          beamRecOut.add("REFERENCE_DIR", srcDir);

        } else if (srcName == "0823-500") {
          srcDir(0) = 126.36195 * D2R;
          srcDir(1) = -50.17736 * D2R;
          beamRecOut.add("REFERENCE_DIR", srcDir);
        }
      }

      char beamLabel[7];
      sprintf(beamLabel, "beam%02d", gBeamNumbers(ibeam));
      intRecOut.add(beamLabel, beamRecOut);
    }

    gIntOut++;
  }

  return emitData;
}

//------------------------------------------------------------ correctSpectrum

// Do bandpass correction for compact sources.

Bool correctSpectrum(
        Int iInt,
        GlishRecord &intRecOut)
{
  // Assume only one IF for the time being.
  Int iif = 0;

  // 0-relative cyclic array index of target spectrum.
  Int target = (iInt - 1 + gNCycles) % gNCycles;

  // Calculate new bandpass spectrum?
  if (gBandpassAge == 0) {
    Bool doMedian = Bool(gEstimator == "MEDIAN");
    Bool doMean   = Bool(gEstimator == "MEAN");

    // Calculate buffer indices.
    uInt first = ((iInt - gPreCycles) - 1 + gNCycles) % gNCycles;
    uInt l1 = gNCycles - first;
    uInt l2 = first;
    Slice unwound1(0, l1);
    Slice unwound2(l1, l2);
    Slice wound1(first, l1);
    Slice wound2(0, l2);
    Vector<Bool>  polyMask(gNCycles);
    Matrix<Float> residuals(gNCycles,1);
    Matrix<Float> coeffs(gPolyDegree+1,1);

    // Beam-independent mask of integrations to use in the cyclic buffer.
    Vector<Bool> baseMask(gNCycles, False);

    for (Int i = 0; i < gNCycles; i++) {
      Int intIn = gIntIn(i);
      baseMask(i) = intIn > 0 && 
                    intIn != iInt &&
                    intIn >= iInt - gPreCycles &&
                    intIn <= iInt + gPostCycles;
    }

    if (gCheckFieldName) {
      baseMask = baseMask && fieldNameMask(target);
    }

    if (gCheckTime) {
      baseMask = baseMask && timeMask(target);
    }

    for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
      // Determine beam-dependent mask.
      Vector<Bool> mask = baseMask;
      if (!gFast || ibeam == 0) {
        if (gCheckPosition) {
          mask = mask && positionMask(target, ibeam);
        }

        // Check that mask has some True values.
        if (allEQ(mask, False)) {
          gBandpassAge = 0;
          return False;
        }

        // Unwind the mask.
        if (first == 0) {
          polyMask = mask;
        } else {
          polyMask(unwound1) = mask(wound1);
          polyMask(unwound2) = mask(wound2);
        }
      }

      for (Int ipol = 0; ipol < gNPol; ipol++) {
        Vector<Float> tsysIn = gTsysIn(ipol,ibeam,iif);

        Float tsys;
        if (doMedian) {
          tsys = median(tsysIn(mask), False, True);

        } else if (doMean) {
          tsys = mean(tsysIn(mask));

        } else {
          // Unwind the cyclic buffer.
          if (first == 0) {
            residuals = tsysIn;
          } else {
            residuals(unwound1,0) = tsysIn(wound1);
            residuals(unwound2,0) = tsysIn(wound2);
          }

          gBandPoly->setMask(polyMask);
          gBandPoly->fit(residuals, coeffs, gPolyIter, gPolyDev, False);
          tsys = tsysIn(target) - residuals(gPreCycles,0);
        }
        gTsys(ipol,ibeam,iif) = tsys;


        Vector<Float> bandpass = gBandpass(ipol,ibeam,iif);
        if (gStatRatio) {
          // Reciprocal of the gain for this channel.
          Vector<Float> factors;

          if (doMedian) {
            for (Int chan = 0; chan < gNChan; chan++) {
              factors = tsysIn / gSpecIn(ipol,ibeam,iif).column(chan);
              bandpass(chan) = median(factors(mask), False, True);
            }

          } else if (doMean) {
            for (Int chan = 0; chan < gNChan; chan++) {
              factors = tsysIn / gSpecIn(ipol,ibeam,iif).column(chan);
              bandpass(chan) = mean(factors(mask));
            }

          } else {
            for (Int chan = 0; chan < gNChan; chan++) {
              factors = tsysIn / gSpecIn(ipol,ibeam,iif).column(chan);

              // Unwind the cyclic buffer.
              if (first == 0) {
                residuals = factors;
              } else {
                residuals(unwound1,0) = factors(wound1);
                residuals(unwound2,0) = factors(wound2);
              }

              gBandPoly->setMask(polyMask);
              gBandPoly->fit(residuals, coeffs, gPolyIter, gPolyDev, False);
              bandpass(chan) = factors(target) - residuals(gPreCycles,0);
            }
          }

        } else {
          if (doMedian) {
            for (Int chan = 0; chan < gNChan; chan++) {
              Vector<Float> channelIn = gSpecIn(ipol,ibeam,iif).column(chan);
              bandpass(chan) = tsys / median(channelIn(mask), False, True);
            }

          } else if (doMean) {
            for (Int chan = 0; chan < gNChan; chan++) {
              Vector<Float> channelIn = gSpecIn(ipol,ibeam,iif).column(chan);
              bandpass(chan) = tsys / mean(channelIn(mask));
            }

          } else {
            for (Int chan = 0; chan < gNChan; chan++) {
              Vector<Float> channelIn = gSpecIn(ipol,ibeam,iif).column(chan);

              // Unwind the cyclic buffer.
              if (first == 0) {
                residuals = channelIn;
              } else {
                residuals(unwound1,0) = channelIn(wound1);
                residuals(unwound2,0) = channelIn(wound2);
              }

              gBandPoly->setMask(polyMask);
              gBandPoly->fit(residuals, coeffs, gPolyIter, gPolyDev, False);
              bandpass(chan) = tsys / (channelIn(target) -
                                       residuals(gPreCycles,0));
            }
          }
        }
      }
    }
  }


  // Apply bandpass correction.
  Vector<Matrix<Float> > spectra(gNBeam);
  Vector<Matrix<uChar> > flagtra(gNBeam);
  for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
    spectra(ibeam).resize(gNChan, gNPol);
    flagtra(ibeam).resize(gNChan, gNPol);

    for (Int ipol = 0; ipol < gNPol; ipol++) {
      // Create a reference to stop the compiler whinging.
      Vector<Float> spectrum = spectra(ibeam).column(ipol);
      Vector<uChar> flagtrum = flagtra(ibeam).column(ipol);

      spectrum = gSpecIn(ipol,ibeam,iif).row(target) *
                   gBandpass(ipol,ibeam,iif) - gTsys(ipol,ibeam,iif);
      flagtrum = gFlagIn(ipol,ibeam,iif).row(target);
    }
  }


  // Do cross-beam Tsys correction (for continuum sources).
  if (gXbeam) {
    Matrix<Float> xbeam(gNBeam, gNPol, 0.0f);

    // RFI-induced excess Tsys appearing simultaneously in each beam.
    for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
      for (Int ipol = 0; ipol < gNPol; ipol++) {
        Vector<Float> spectrum = spectra(ibeam).column(ipol);
        xbeam(ibeam,ipol) = mean(spectrum) / gTsys(ipol,ibeam,iif);
      }
    }

    Float xsTsys = median(xbeam, False, True);

    // Correct for excess Tsys.
    for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
      for (Int ipol = 0; ipol < gNPol; ipol++) {
        Vector<Float> spectrum = spectra(ibeam).column(ipol);
        spectrum -= xsTsys * gTsys(ipol,ibeam,iif);
      }
    }
  }


  // Apply post-bandpass corrections and write out the calibrated spectra.
  GlishArray glishArr;
  GlishRecord beamRecOut;

  Matrix<Float> baseLin(2,2);
  Matrix<Float> baseSub(max(2,gFitDegree+1),2);

  for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
    Double refFreq, freqInc;
    glishArr = gBufferIn(target,0,iif).get("REF_FREQUENCY");
    glishArr.get(refFreq);
    glishArr = gBufferIn(target,0,iif).get("RESOLUTION");
    glishArr.get(freqInc);

    Double newFreqInc, newRefFreq;
    for (Int ipol = 0; ipol < gNPol; ipol++) {
      Vector<Float> spectrum = spectra(ibeam).column(ipol);
      Vector<uChar> flagtrum = flagtra(ibeam).column(ipol);
      Vector<Float> baseLini = baseLin.column(ipol);
      Vector<Float> baseSubi = baseSub.column(ipol);

      // Apply post-bandpass corrections.
      postBandpass(iif, spectrum, flagtrum, baseLini, baseSubi,
                   gTime(target), gCoord(target,ibeam), refFreq,
                   freqInc, newRefFreq, newFreqInc);
    }

    // Construct outgoing Glish record.
    beamRecOut = gBufferIn(target,ibeam,iif);
    beamRecOut.add("DOPPLER_FRAME", gOutFrame);
    beamRecOut.add("REF_FREQUENCY", newRefFreq);
    beamRecOut.add("RESOLUTION", newFreqInc);
    beamRecOut.add("BASELIN", baseLin);
    beamRecOut.add("BASESUB", baseSub);
    beamRecOut.add("FLOAT_DATA", spectra(ibeam));
    beamRecOut.add("FLAGGED", compressFlags(flagtra(ibeam)));

    char beamLabel[7];
    sprintf(beamLabel, "beam%02d", gBeamNumbers(ibeam));
    intRecOut.add(beamLabel, beamRecOut);
  }

  gBandpassAge = (gBandpassAge + 1) % gBandpassRecalc;

  return True;
}

//-------------------------------------------------------------- fieldNameMask

// Find buffer elements with the same field name as the target.

Vector<Bool> fieldNameMask(Int target)
{
  Int oldest = 0;
  if (gNInt > gNCycles) {
    oldest = gNInt % gNCycles;
  }

  Int newest = (gNInt - 1 + gNCycles) % gNCycles;
  if (newest < oldest) {
     newest += gNCycles;
  }

  // Search through the scrolling buffer.
  Vector<Bool> mask(gNCycles, False);
  for (Int j = oldest; j <= newest; j++) {
    // Buffer cycling.
    Int indx = j % gNCycles;

    if (gFieldNameIn(indx) == gFieldNameIn(target)) {
      mask(indx) = True;
    }
  }

  return mask;
}

//------------------------------------------------------------------- timeMask

// Find buffer elements within the specified time of the target.

Vector<Bool> timeMask(Int target)
{
  Int    newer, older;
  Double delta;
  Vector<Bool> mask(gNCycles, False);

  Int oldest = 0;
  if (gNInt > gNCycles) {
    oldest = gNInt % gNCycles;
  }

  Int newest = (gNInt - 1 + gNCycles) % gNCycles;

  // Search backwards from the target.
  if (target != oldest) {
    newer = target;
    older = (target - 1 + gNCycles) % gNCycles;

    while (True) {
      // Check for time jumps.
      if (gTStep(newer) > gTjump) {
        break;
      }

      delta = gTime(target) - gTime(older);
      mask(older) = Bool(delta > gTmin && delta < gTmax);

      if (older == oldest) {
        break;
      }

      newer = older;
      older = (older - 1 + gNCycles) % gNCycles;
    }
  }

  // Search forwards from the target.
  if (target != newest) {
    older = target;
    newer = (target + 1) % gNCycles;

    while (True) {
      // Check for time jumps.
      if (gTStep(newer) > gTjump) {
        break;
      }

      delta = gTime(newer) - gTime(target);
      mask(newer) = Bool(delta > gTmin && delta < gTmax);

      if (newer == newest) {
        break;
      }

      older = newer;
      newer = (newer + 1) % gNCycles;
    }
  }

  return mask;
}

//--------------------------------------------------------------- positionMask

// Find buffer elements within the specified distance of the target.

Vector<Bool> positionMask(Int target, Int ibeam)
{
  Int    newer, older;
  Double delta;
  Vector<Bool> mask(gNCycles, False);

  Int oldest = 0;
  if (gNInt > gNCycles) {
    oldest = gNInt % gNCycles;
  }

  Int newest = (gNInt - 1 + gNCycles) % gNCycles;

  // Search backwards from the target.
  if (target != oldest) {
    newer = target;
    older = (target - 1 + gNCycles) % gNCycles;

    while (True) {
      // Check for position jumps.
      if (gDStep(newer,ibeam) > gDjump) {
        break;
      }

      delta = angularDist(gCoord(target,ibeam)(0), gCoord(target,ibeam)(1),
                          gCoord(older, ibeam)(0), gCoord(older, ibeam)(1));
      delta *= R2D * 60.0;
      mask(older) = Bool(delta > gDmin && delta < gDmax);

      if (older == oldest) {
        break;
      }

      newer = older;
      older = (older - 1 + gNCycles) % gNCycles;
    }
  }

  // Search forwards from the target.
  if (target != newest) {
    older = target;
    newer = (target + 1) % gNCycles;

    while (True) {
      // Check for position jumps.
      if (gDStep(newer,ibeam) > gDjump) {
        break;
      }

      delta = angularDist(gCoord(newer, ibeam)(0), gCoord(newer, ibeam)(1),
                          gCoord(target,ibeam)(0), gCoord(target,ibeam)(1));
      delta *= R2D * 60.0;
      mask(newer) = Bool(delta > gDmin && delta < gDmax);

      if (newer == newest) {
        break;
      }

      older = newer;
      newer = (newer + 1) % gNCycles;
    }
  }

  return mask;
}

//------------------------------------------------------------ correctExtended

// Do bandpass correction for extended sources.

void correctExtended(void)
{
  if (gEstimator == "MEDIAN" ||
      gEstimator == "MEAN") {
    // Estimators based on the whole scan.
    Slice scan = Slice(0,gNInt);

    // Set up a robust polynomial fitter for Tsys.
    Vector<Float> integs(gNInt);
    indgen(integs);
    integs -= Float(gNInt/2);
    if (gBandPoly) delete gBandPoly;
    gBandPoly = new RPolyFit<Float>(2, integs);

    Matrix<Float> residuals(gNInt,1);
    Matrix<Float> coeffs(2,1);
    Vector<Float> tsysFit(gNInt);

    for (Int iif = 0; iif < gNIF; iif++) {
      for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
        for (Int ipol = 0; ipol < gNPol; ipol++) {
          Vector<Float> tsysIn = gTsysIn(ipol,ibeam,iif)(scan);

          // Do robust polynomial fit to Tsys.
          residuals = tsysIn;
          if (!gBandPoly->fit(residuals, coeffs, 3, 2.0)) {
            logError("ERROR: RPolyFit FAILED FOR Tsys: " +
              gBandPoly->errMsg() + ".");
            continue;
          }

          tsysFit = tsysIn - residuals.column(0);

          for (Int chan = 0; chan < gNChan; chan++) {
            Vector<Float> channelIn =
              gSpecIn(ipol,ibeam,iif).column(chan)(scan);

            Vector<Float> factors = tsysIn / channelIn;

            Vector<Bool> mask(gNInt);
            mask = True;
            if (gBoxSize > 0) {
              Int nRunn = gNInt - gBoxSize + 1;
              if (nRunn > 0) {
                // Compute the running sum.
                Float maxsum, minsum;
                maxsum = minsum = sum(factors(Slice(0,gBoxSize)));

                Int maxj, minj;
                maxj = minj = 0;
                for (Int j = 1; j < nRunn; j++) {
                  Float newsum = sum(factors(Slice(j,gBoxSize)));
                  if (newsum < minsum) {
                    minj = j;
                    minsum = newsum;
                  } else if (newsum > maxsum) {
                    maxj = j;
                    maxsum = newsum;
                  }
                }

                if (gBoxReject) {
                  // Reject the lowest (scan is mostly baseline).
                  mask(Slice(minj,gBoxSize)) = False;
                } else {
                  // Accept the highest (scan is mostly emission).
                  mask = False;
                  mask(Slice(maxj,gBoxSize)) = True;
                }
              }
            }

            Float factor, tsys;
            if (gEstimator == "MEDIAN") {
              factor = median(factors(mask), False, True);
              tsys   = median(tsysIn(mask), False, True);
            } else if (gEstimator == "MEAN") {
              factor = mean(factors(mask));
              tsys   = mean(tsysIn(mask));
            }

            channelIn *= factor;
            channelIn -= tsysFit;
          }
        }
      }
    }

  } else if (gEstimator == "RFIMED") {
    // A clipped median estimator that takes account of strong radar signals
    // such as those that affect Arecibo ALFA data.  The main aim here is to
    // compute a reliable calibration factor for each channel but if this
    // can't be done the whole channel is flagged.  Flagging of sporadic RFI
    // (radar flashes) is a secondary issue, since this can be dealt with
    // later, e.g. via simple clipping in gridzilla.

    Vector<Bool>  chanMask(gNChan);
    Vector<Float> rms(gNChan);
    Vector<Float> chanFctr(gNChan);

    // The scan is subdivided into sub-scans of the user-specified length.
    Int boxStart = 0;
    if (gBoxSize <= 0) {
      gBoxSize = gNInt;
    }

    while (boxStart < gNInt) {
      Int boxSize = min(gBoxSize,gNInt-boxStart);

      Slice scan = Slice(boxStart,boxSize);

      Vector<Bool>  mask(boxSize);
      Vector<Float> fluxes(boxSize);

      for (Int iif = 0; iif < gNIF; iif++) {
        for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
          for (Int ipol = 0; ipol < gNPol; ipol++) {
            Matrix<Float> specIn = gSpecIn(ipol,ibeam,iif);
            Matrix<uChar> flagIn = gFlagIn(ipol,ibeam,iif);

            for (Int chan = 0; chan < gNChan; chan++) {
              Vector<Float> channelIn = specIn.column(chan)(scan);
              rms(chan) = stddev(channelIn);
            }

            // A measure of the typical RMS in the uncalibrated spectra.
            Float medrms = median(rms, False, True);

            // Set the clipping threshhold; x3 the median RMS works well.
            Float clip = gRFIclip * medrms;

            Vector<Float> tsysIn = gTsysIn(ipol,ibeam,iif)(scan);
            Float tsys = median(tsysIn, False, True);

            Float factor;
            for (Int chan = 0; chan < gNChan; chan++) {
              Vector<Float> channelIn = specIn.column(chan)(scan);

              mask = True;
              Int mInt = boxSize;
              for (Int iter = 0; iter < gRFIiter; iter++) {
                // Calibration factor for this channel.
                factor = tsys / median(channelIn(mask), False, True);

                // Channel fluxes (with continuum component).
                fluxes = factor*channelIn - tsys;

                // Where factor is higher, e.g. on the edge of the band, the
                // noise is higher and we want to relax the threshhold.
                // Conversely, where there's strong RFI, factor will be lower
                // and hence the threshhold is lower.
                mask = (fluxes < clip*factor);

                // Minimum number of samples needed for reasonable statistics.
                if ((mInt = ntrue(mask)) < gRFIminInt) break;
              }

              // Best estimate of the calibration factor.
              if (mInt >= gRFIminInt) {
                factor = tsys / median(channelIn(mask), False, True);
              }

              chanFctr(chan) = factor;
              fluxes = factor*channelIn - tsys;

              // If the RMS of the unflagged integrations is much greater
              // than typical then it is likely that strong RFI has escaped
              // flagging and that the calibration is unreliable.
              if (mInt < gRFIminInt) {
                chanMask(chan) = False;
              } else {
                chanMask(chan) = stddev(fluxes(mask)) < gRFIlev*medrms*factor;
              }

              if (chanMask(chan) && mInt < gRFIsFlag*boxSize) {
                // Secondary flagging: apparently the calibration is reliable
                // yet it seems that strong RFI must be present, so propagate
                // the flags determined above.
                Vector<uChar> chanFlags = flagIn.column(chan)(scan);
                chanFlags(!mask) = uChar(1);
              }
            }

            // Expand the mask a bit each way to take care of edge effects.
            if (gChanGrowMin > 0.0f || gChanGrowAdd > 0.0f) {
              growMask(chanMask, gChanGrowMin, gChanGrowAdd);

              for (Int chan = 0; chan < gNChan; chan++) {
                if (!chanMask(chan)) {
                  Vector<uChar> chanFlags = flagIn.column(chan)(scan);
                  chanFlags = uChar(1);
                }
              }
            }

            // Radar interference at Arecibo is often strong enough to affect
            // Tsys significantly, but having now identified the bad channels
            // it is possible to correct it.
            for (Int iInt = 0; iInt < boxSize; iInt++) {
              Vector<Float> spectrum = specIn.row(boxStart+iInt);
              Vector<uChar> flagtrum = flagIn.row(boxStart+iInt);
              tsysIn(iInt) = mean(spectrum(flagtrum == uChar(0)));
            }

            chanFctr /= tsys;
            tsys = median(tsysIn, False, True);
            chanFctr *= tsys;

            // Finally, apply the calibration factor for each channel.
            for (Int chan = 0; chan < gNChan; chan++) {
              Vector<Float> channelIn = specIn.column(chan)(scan);
              channelIn *= chanFctr(chan);
              channelIn -= tsys;
            }
          }
        }
      }

      // Next box.
      boxStart += gBoxSize;
    }

  } else if (gEstimator == "POLYFIT") {
    // Set up robust polynomial fitter.
    Vector<Float> integs(gNInt);
    indgen(integs);
    integs -= Float(gNInt/2);
    if (gBandPoly) delete gBandPoly;
    gBandPoly = new RPolyFit<Float>(gPolyDegree+1, integs);

    for (Int iif = 0; iif < gNIF; iif++) {
      // Create references to the data.
      Matrix<Vector<Float> > tsysIn = gTsysIn.xyPlane(iif);
      Matrix<Matrix<Float> > specIn = gSpecIn.xyPlane(iif);
      Matrix<Matrix<uChar> > flagIn = gFlagIn.xyPlane(iif);

      if (_test_SmoothFlags || _test_PhaseTracking || _test_TranFlags) {
        // For this estimator, we actually do things twice.  Once on a copy of
        // the data so that we can search for data to flag as bad, and then
        // once more after we have flagged the data on the original copy...

        // Create working copies of the data; construct and then assign,
        // otherwise the copy constructor will create references as above -
        // obvious, eh?
        Matrix<Vector<Float> > lTsysIn;
        Matrix<Matrix<Float> > lSpecIn;
        Matrix<Matrix<uChar> > lFlagIn;

        lTsysIn = tsysIn;
        lSpecIn = specIn;
        lFlagIn = flagIn;

        // Processes the copy.
        polyfitBandpass(lTsysIn, lSpecIn, gNInt);

        // Interpolate before phase tracking!
        if (_test_SmoothFlags) {
          gObsFilter.specInterpolate1D(lSpecIn, lFlagIn, gNInt);
        }

        // Phase track the processed data so that ripples escape flagging.
        if (_test_PhaseTracking) {
          Int niters = 1;
          Vector<Int> harmonics(34);
          indgen(harmonics, 1);
          //Vector<Int> harmonics(2); harmonics(0) = 10; harmonics(1) = 21;
          Vector<Float> model_harmonic_amps(1);
          model_harmonic_amps(0) = 4.0;

          Slice slc_int(0, gNInt);
          Slice slc_chn(128, 896);

          for (Int ipol = 0; ipol < gNPol; ipol++) {
            for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
              Matrix<Float> slab =
                lSpecIn(ipol,ibeam)(slc_int, slc_chn).copy();

              for (Int i_tmp = 0; i_tmp < niters; i_tmp++) {
                Matrix<Float> model = gObsFilter.briggsHarmonicModel(slab,
                                      harmonics, model_harmonic_amps);
                slab -= model;
              }

              lSpecIn(ipol,ibeam)(slc_int, slc_chn) = slab;
            }
          }
        }

        // Determine flags.
        if (_test_TranFlags) {
          gObsFilter.transientFlagging(lTsysIn, lSpecIn, lFlagIn, gNInt);
        }

        // Copy new flags to genuine data store.
        flagIn = lFlagIn;
      }

      // Process the genuine data store with these flags.
      polyfitBandpass(tsysIn, specIn, gNInt);

      // Interpolate before phase tracking!
      if (_test_SmoothFlags) {
        gObsFilter.specInterpolate1D(specIn, flagIn, gNInt);
      }

      // phase track the genuine processed data
      if (_test_PhaseTracking) {
        Int niters = 1;
        Vector<Int> harmonics(34);
        indgen(harmonics, 1);
        //Vector<Int> harmonics(2); harmonics(0) = 10; harmonics(1) = 21;
        Vector<Float> model_harmonic_amps(1);
        model_harmonic_amps(0) = 4.0;

        Slice slc_int(0, gNInt);
        Slice slc_chn(128, 896);

        for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
          for (Int ipol = 0; ipol < gNPol; ipol++) {
            Matrix<Float> slab =
              gSpecIn(ipol,ibeam,iif)(slc_int,slc_chn).copy();
            for (Int i_tmp = 0; i_tmp < niters; i_tmp++) {
              Matrix<Float> model =
                gObsFilter.briggsHarmonicModel(slab, harmonics,
                                               model_harmonic_amps);
              slab -= model;
            }

            gSpecIn(ipol,ibeam,iif)(slc_int, slc_chn) = slab;
          }
        }
      }
    }

  } else if (gEstimator == "MEDMED" ||
             gEstimator == "MINMED") {
    // Estimators that decompose the scan into a number of subscans.
    Vector<Slice> slice(gNBoxes);

    Int boxstart  = 0;
    Int boxsize   = gNInt / gNBoxes;
    Int remainder = gNInt % gNBoxes;
    for (Int box = 0; box < gNBoxes; box++) {
      Int boxsiz = boxsize;
      if (remainder) {
        boxsiz++;
        remainder--;
      }

      slice(box) = Slice(boxstart, boxsiz);
      boxstart += boxsiz;
    }

    Vector<Float> cmed(gNBoxes), tmed(gNBoxes);
    for (Int iif = 0; iif < gNIF; iif++) {
      for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
        for (Int ipol = 0; ipol < gNPol; ipol++) {
          Vector<Float> tsysIn = gTsysIn(ipol,ibeam,iif);

          for (Int box = 0; box < gNBoxes; box++) {
            tmed(box) = median(tsysIn(slice(box)), False, True);
          }

          for (Int chan = 0; chan < gNChan; chan++) {
            Vector<Float> channelIn = gSpecIn(ipol,ibeam,iif).column(chan);

            Float factor, tsys;
            if (gEstimator == "MEDMED") {
              // Determine the medians of the subscans.
              for (Int box = 0; box < gNBoxes; box++) {
                cmed(box) = median(tsysIn(slice(box)) / channelIn(slice(box)),
                                      False, True);
              }

              // Throw out the lowest.
              Vector<Bool> mask(gNBoxes);
              mask = cmed > min(cmed);

              // Median of the remaining medians.
              factor = median(cmed(mask), False, True);
              tsys   = median(tmed(mask), False, True);

            } else if (gEstimator == "MINMED") {
              // Minimum of the medians (heritage estimator for HVC survey).
              for (Int box = 0; box < gNBoxes; box++) {
                cmed(box) = median(channelIn(slice(box)), False, True);
              }

              // Biassed as well as inefficient.
              factor = min(tmed) / min(cmed);

              // For backwards compatibility.
              tsys = 0.0f;
            }

            channelIn *= factor;
            channelIn -= tsys;
          }
        }
      }
    }
  }
}

//------------------------------------------------------------ polyfitBandpass

// Correct the time dependence of each channel with a robust polynomial fit.

void polyfitBandpass(
        Matrix<Vector<Float> > &lTsysIn,
        Matrix<Matrix<Float> > &lSpecIn,
        Int nInt)
{
  Slice scan = Slice(0,nInt);

  Cube<Float>   tsys(nInt,gNPol,gNBeam);
  Vector<Float> factors(nInt);
  Matrix<Float> residuals(nInt,1);
  Matrix<Float> coeffs(gPolyDegree+1,1);

  for (Int ipol = 0; ipol < gNPol; ipol++) {
    for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
      Vector<Float> tsysIn = lTsysIn(ipol,ibeam)(scan);

      // Do robust polynomial fit to Tsys.
      residuals = tsysIn;
      gBandPoly->fit(residuals, coeffs, gPolyIter, gPolyDev);
      Vector<Float> tsysFit = tsys(Slice(),ipol,ibeam).nonDegenerate();
      tsysFit = tsysIn - residuals.column(0);

      // Do robust polynomial fit for each channel.
      for (Int ichan = 0; ichan < gNChan; ichan++) {
        Vector<Float> channelIn = lSpecIn(ipol,ibeam).column(ichan)(scan);

        factors = tsysIn / channelIn;

        residuals = factors;
        gBandPoly->fit(residuals, coeffs, gPolyIter, gPolyDev);
        factors -= residuals.column(0);

        channelIn *= factors;
        channelIn -= tsysFit;
      }
    }
  }


  // Do cross-beam Tsys correction (for continuum sources).
  if (gXbeam) {
    for (Int i = 0; i < nInt; i++) {
      Matrix<Float> xbeam(gNPol,gNBeam,0.0f);

      // RFI-induced excess Tsys appearing simultaneously in each beam.
      for (Int ipol = 0; ipol < gNPol; ipol++) {
        for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
          Vector<Float> spectrum = lSpecIn(ipol,ibeam).row(i);
          xbeam(ipol,ibeam) = mean(spectrum) / tsys(i,ipol,ibeam);
        }
      }

      Float xsTsys = median(xbeam, False, True);

      // Correct for excess Tsys.
      for (Int ipol = 0; ipol < gNPol; ipol++) {
        for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
          Vector<Float> spectrum = lSpecIn(ipol,ibeam).row(i);
          spectrum -= xsTsys * tsys(i,ipol,ibeam);
        }
      }
    }
  }
}

//--------------------------------------------------------------- postBandpass

// Apply post-bandpass corrections, baseline removal and Doppler shift.

void postBandpass(
        const Int iif,
        Vector<Float> &spectrum,
        Vector<uChar> &flagtrum,
        Vector<Float> &baseLin,
        Vector<Float> &baseSub,
        const Double time,
        const Vector<Double> position,
        const Double refFreq,
        const Double freqInc,
        Double &newRefFreq,
        Double &newFreqInc)
{
  baseLin = 0.0f;
  baseSub = 0.0f;

  // Apply robust baseline fit of the required order.
  if (gFitDegree <= 0) {
    baseLin(0) = median(spectrum(gChanMask), False, True);

    if (gFitDegree == 0) {
      baseSub(0) = baseLin(0);
      spectrum -= baseSub(0);
    }

  } else if (gFitDegree == 1 && gL1Norm) {
    // Linear L1 norm fit.
    RobustLineFit<Float> fitter(0.001);
    fitter.fit(gChans, spectrum);

    // New estimate of the continuum contribution.
    baseLin(0) = fitter.b();
    baseLin(1) = fitter.a();

    if (!gContinuum) {
      baseSub(0) = baseLin(0);
      baseSub(1) = baseLin(1);
      spectrum -= baseSub(1)*gChans + baseSub(0);
    }

  } else if (gFitDegree > 0) {
    // Do robust (adaptive) polynomial fit.
    Matrix<Float> coeff(gFitDegree+1,1);

    // Construct a Matrix by reference to spectrum for RPolyFit::fit().
    Matrix<Float> spectra(spectrum);
    gBasePoly->setMask(gChanMask);
    gBasePoly->fit(spectra, coeff, 3, 2.0f, False, False);

    // Summed coefficients of the polynomials subtracted.
    baseSub = coeff.column(0);

    // New estimate of the continuum contribution.
    baseLin(0) = baseSub(0);
    baseLin(1) = baseSub(1);

    if (gContinuum) {
      // Reapply the continuum (linear) baseline component.
      spectrum += baseSub(1)*gChans + baseSub(0);
      baseSub(0) = 0.0f;
      baseSub(1) = 0.0f;
    }
  }

  if (_test_SmoothFlags) {
    gObsFilter.specInterpolate1D(spectrum, flagtrum);
  }

  // Doppler reference frame conversion.
  Double chanShift;
  gVelTrack[iif]->correct(time, position, refFreq, freqInc, newRefFreq,
                          newFreqInc, chanShift, spectrum);

  if (_test_GrowFlags) {
    gObsFilter.shiftFlags(flagtrum, chanShift);
  }
}

//------------------------------------------------------------------- growMask

// Broaden an array mask; each region of consecutive False values in the mask
// is extended by one on each side if it is at least growMin elements wide,
// and by a further one on each side for every additional growAdd elements.

int growMask(
        Vector<Bool> &mask,
        Float growMin,
        Float growAdd)
{
  Int nMask = mask.nelements();
  if (nMask == 0) {
    return 0;
  }

  if (nfalse(mask) == 0) {
    return nMask;
  }

  Vector<Bool> orig(nMask);
  orig = mask;

  // Grow forwards.
  Float n = 0.0f;
  for (Int i = 0; i < nMask; i++) {
    if (orig(i)) {
      if (n >= growMin) {
        mask(i) = False;
        n -= growAdd;
      }
      if (n < growMin) {
        n = 0.0f;
      }
    } else {
      n += 1.0f;
    }
  }

  // Grow backwards.
  n = 0.0f;
  Int i = nMask - 1;
  while (i >= 0) {
    if (orig(i)) {
      if (n >= growMin) {
        mask(i) = False;
        n -= growAdd;
      }
      if (n < growMin) {
        n = 0.0f;
      }
    } else {
      n += 1.0f;
    }

    i--;
  }

  return ntrue(mask);
}
