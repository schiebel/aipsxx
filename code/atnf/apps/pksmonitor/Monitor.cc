//#---------------------------------------------------------------------------
//# Monitor.cc: Buffers and averages data for single-dish data display.
//#---------------------------------------------------------------------------
//# Copyright (C) 1994-2006
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but
//# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
//# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
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
//# $Id: Monitor.cc,v 19.17 2006/07/13 06:23:23 mcalabre Exp $
//#---------------------------------------------------------------------------
//# Original: Taisheng Ye, restructured by Tom Oosterloo.
//#---------------------------------------------------------------------------

#include <unistd.h>

// AIPS++ includes.
#include <casa/math.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/Cube.h>
#include <casa/Arrays/MaskedArray.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishEvent.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>

// Parkes includes.
#include <atnf/pks/pksmb_support.h>
#include <atnf/pks/pks_maths.h>

#include <Monitor.h>

#include <casa/namespace.h>

//----------------------------------------------------------- Monitor::Monitor

Monitor::Monitor()

{
  cBlank = -1.0;
  cInitialized = False;
}

//---------------------------------------------------- Monitor::defaultHandler

Bool Monitor::defaultHandler(
  GlishSysEvent &event)

{
  // Tell user that the event was not recognized.
  GlishSysEventSource *glishBus = event.glishSource();
  glishBus->postEvent("error", "Monitor:: unknown event: "+event.type());
  return True;
}

//------------------------------------------------------- Monitor::initHandler

// Read input parameters and initialize arrays and work variables.

Bool Monitor::initHandler(
  GlishSysEvent &event)

{
  GlishSysEventSource *glishBus = event.glishSource();
  GlishValue glishVal = event.val();
  if (glishVal.type() != GlishValue::RECORD) {
    logError("Initialization error, argument to \"init\" should be a record.");
    glishBus->postEvent("init_error", "Client initialization failed");
    return True;
  }

  // Read input parameters.
  GlishRecord parms = glishVal;

  Vector<Bool> beams(13), beamsel(13), IFs(16);
  getParm(parms, "beams",  False, beams);
  getParm(parms, "IFs",    False, IFs);
  getParm(parms, "nchans",     0, cNChanIn);
  getParm(parms, "npols",      0, cNPol);
  getParm(parms, "beamsel", True, beamsel);

  // cBeamMask relates to the beams actually present in the MB record.
  cNBeam = ntrue(beams);
  cBeamMask.resize(cNBeam);
  uInt jBeam = 0;
  for (uInt iBeam = 0; iBeam < beams.nelements(); iBeam++) {
    if (beams(iBeam)) {
      cBeamMask(jBeam++) = beamsel(iBeam);
    }
  }

  // Check the number of IFs selected.
  if (ntrue(IFs) > 2) {
    logError("Initialization error, more than 2 IFs selected.");
    glishBus->postEvent("init_error", "More than 2 IFs selected");
    return True;
  }

  // Translation table, IF number -> IF sequence number.
  uInt nIF = IFs.nelements();
  cIFseq.resize(nIF);
  cIFseq = 0;
  cNIF = 0;
  cIFid1 = "";
  cIFid2 = "";
  for (uInt iIF = 0; iIF < nIF; iIF++) {
    if (IFs(iIF)) {
      cIFseq(iIF) = ++cNIF;

      char id[8];
      sprintf(id, "%d", iIF + 1);
      if (cNIF == 1) cIFid1 = id;
      if (cNIF == 2) cIFid2 = id;
    }
  }

  getParm(parms, "maxspec",   100, cMaxSpec);
  if (cMaxSpec < 1) cMaxSpec = 1;

  // IFs required for display 1.
  String if1;
  getParm(parms, "if1", String("BOTH"), if1);
  cIFs1 = IF_NONE;
  if (if1 == "1st" || cNIF == 1) {
    cIFs1 = IF_1;
  } else if (if1 == "2nd") {
    cIFs1 = IF_2;
  } else if (if1 == "BOTH") {
    cIFs1 = IF_BOTH;
  }

  // IFs required for display 2.
  String if2;
  getParm(parms, "if2", String("BOTH"), if2);
  cIFs2 = IF_NONE;
  if (if2 == "1st" || cNIF == 1) {
    cIFs2 = IF_1;
  } else if (if2 == "2nd") {
    cIFs2 = IF_2;
  } else if (if2 == "BOTH") {
    cIFs2 = IF_BOTH;
  }

  // Do we want IF 1 or IF 2 from the input data?
  cWantIF1 = (cIFs1 == IF_1 || cIFs1 == IF_BOTH ||
              cIFs2 == IF_1 || cIFs2 == IF_BOTH);
  cWantIF2 = (cIFs1 == IF_2 || cIFs1 == IF_BOTH ||
              cIFs2 == IF_2 || cIFs2 == IF_BOTH);

  // Polarizations required for display 1.
  String pol1;
  getParm(parms, "pol1", String("A"), pol1);
  if (pol1 == "A") {
    cPols1 = POL_A;
  } else if (pol1 == "B") {
    cPols1 = POL_B;
  } else if (pol1 == "(A+B)/2") {
    cPols1 = POL_AVG;
  } else if (pol1 == "(A-B)/2") {
    cPols1 = POL_DIF;
  } else {
    cPols1 = POL_NONE;
  }

  if (cNPol == 1) {
    if (cPols1 == POL_B) {
      cPols1 = POL_NONE;
      logWarning("Polarization B is not available for display in monitor "
                 "window 1.");
    } else if (cPols1 != POL_A && cPols1 != POL_NONE) {
      cPols1 = POL_A;
      logWarning("Only one polarization is available for display in monitor "
                 "window 1.");
    }
  }

  // Polarizations required for display 2.
  String pol2;
  getParm(parms, "pol2", String("B"), pol2);
  if (pol2 == "A") {
    cPols2 = POL_A;
  } else if (pol2 == "B") {
    cPols2 = POL_B;
  } else if (pol2 == "(A+B)/2") {
    cPols2 = POL_AVG;
  } else if (pol2 == "(A-B)/2") {
    cPols2 = POL_DIF;
  } else {
    cPols2 = POL_NONE;
  }

  if (cNPol == 1) {
    if (cPols2 == POL_B) {
      cPols2 = POL_NONE;
      logWarning("Polarization B is not available for display in monitor "
                 "window 2.");
    } else if (cPols2 != POL_A && cPols2 != POL_NONE) {
      cPols2 = POL_A;
      logWarning("Only one polarization is available for display in monitor "
                 "window 2.");
    }
  }

  // Smoothing to apply in the time domain.
  String timeMode;
  getParm(parms, "timemode", String("NONE"), timeMode);
  if (timeMode == "MEAN") {
    cTimeMode = MEAN;
  } else if (timeMode == "MEDIAN") {
    cTimeMode = MEDIAN;
  } else if (timeMode == "MAXIMUM") {
    cTimeMode = MAXIMUM;
  } else if (timeMode == "RMS") {
    cTimeMode = RMS;
  } else {
    cTimeMode = NONE;
  }

  // Averaging length in the time domain (the number of integration periods).
  if (cTimeMode == NONE) {
    cBuffLen = 1;
  } else {
    getParm(parms, "averlength", 12, cBuffLen);
    if (cBuffLen < 1) cBuffLen = 1;
  }
  cEmit = cBuffLen;

  // Smoothing to apply in the frequency domain.
  String freqMode;
  getParm(parms, "freqmode", String("NONE"), freqMode);
  cDoHanning = Bool(freqMode == "HANNING");

  // First channel to display.
  if (getParm(parms, "chanstart", 100, cChanStart)) {
    // Convert 1-relative channel range to 0-relative for AIPS++.
    if (cChanStart < 1) {
      // Offset from end of spectrum.
      cChanStart += cNChanIn;
    }
    cChanStart--;
  }

  // Last channel to display.
  if (getParm(parms, "chanend", -100, cChanEnd)) {
    if (cChanEnd <= 0) {
      // Offset from end of spectrum.
      cChanEnd += cNChanIn;
    }
    cChanEnd--;
  }

  // Ensure start precedes end.
  cChanStart = min(max(0, cChanStart), cNChanIn-1);
  cChanEnd   = min(max(0, cChanEnd),   cNChanIn-1);
  if (cChanStart > cChanEnd) {
    Int tmp = cChanStart;
    cChanStart = cChanEnd;
    cChanEnd = tmp;
  }
  cNChanSel = cChanEnd - cChanStart + 1;

  getParm(parms, "chanskip",     0,  cChanSkip);
  getParm(parms, "cfreq",     True,  cDoFreq);
  getParm(parms, "ctime",     True,  cDoTime);
  getParm(parms, "flagblank", False, cFlagBlank);
  getParm(parms, "sumspec",   False, cSumSpec);

  // Resize arrays.
//  cBeamMask.resize(cNBeam);
//  cBeamMask = True;

  // Dual-IFs may be simultaneous (e.g. Mopra data) or they may alternate
  // between integrations (e.g. Parkes frequency-switched data).
  //
  // For simultaneous IFs, each integration is split into a pair of glish
  // records with differing IF numbers but the same integration cycle number,
  // beam number, time, ra, dec, and reference beam.
  //
  // For alternate IFs, each pair of integrations appears as a single glish
  // record, each with a different integration number, and alternate rows in
  // the spectral buffers will be empty.

  cSpecBeam.resize(cNBeam, cBuffLen);
  cSpecTime.resize(cNBeam, cBuffLen);
  cSpecRa.resize(cNBeam, cBuffLen);
  cSpecDec.resize(cNBeam, cBuffLen);
  cSpecRefbeam.resize(cBuffLen);

  if (cWantIF1) {
    cSpecData1.resize(cNChanIn, cNPol*cNBeam, cBuffLen);
    cSpecData1 = cBlank;
  }

  if (cWantIF2) {
    cSpecData2.resize(cNChanIn, cNPol*cNBeam, cBuffLen);
    cSpecData2 = cBlank;
  }

  cIFparms.resize(2);
  cIFparms = False;
  cFreqInc.resize(2);
  cHdrFreq.resize(2);
  cRefFreq.resize(2);

  cChanSep = 0;
  cFirstInChan.resize(2, cBuffLen);
  cFirstOutChan.resize(2, cBuffLen);
  cLength.resize(2, cBuffLen);

  // Initialize work variables.
  cCount = 0;
  cIndx  = -1;
  cPrevIntNo = -1;
  cBeamSw = False;
  cSimulIF = False;
  cInitialized = True;

  return True;
}

//---------------------------------------------------- Monitor::newdataHandler

// Process a batch of spectra.

Bool Monitor::newdataHandler(
  GlishSysEvent &event, uInt &nRec)

{
  nRec = 0;

  GlishSysEventSource *glishBus = event.glishSource();
  if (!cInitialized) {
    glishBus->postEvent("error", "newdata -- not initialized");
    return True;
  }

  GlishValue glishVal = event.val();
  if (glishVal.type() != GlishValue::RECORD) {
    glishBus->postEvent("error", "newdata - argument should be a record");
    return True;
  }

  Int beamNo;
  Double freq, time;
  GlishRecord aggRec = glishVal, beamRec, intRec;
  GlishArray glishArr;

  // Add to spectra buffer.
  nRec = aggRec.nelements();
  for (uInt iRec = 0; iRec < nRec; iRec++) {
    intRec  = aggRec.get(iRec);
    beamRec = intRec.get(0);

    if (cCount == 0) {
      // The integration time is usually a little less than the time between
      // integrations because of small latencies.  If it's within 10% of the
      // nearest integral number of seconds, as is usual, then round it.
      // Otherwise we may have binned data, in which case round to the nearest
      // ms.  Getting this wrong will cause integrations to disappear
      // occasionally from the monitor window as the time axis "beats".
      glishArr = beamRec.get("INTERVAL");
      glishArr.get(cIntTime);
      double intTime = round(cIntTime, 1.0);
      if (intTime > cIntTime && (intTime-cIntTime)/cIntTime < 0.1) {
        // Round to the nearest second.
        cIntTime = intTime;
      } else {
        // Round to the nearest ms.
        cIntTime = round(cIntTime, 0.001);
      }
      logMessage("Time axis increment set to ", cIntTime, "s.");

      // Get observation type.
      glishArr = beamRec.get("OBSTYPE");
      glishArr.get(cObstype);

      // Check for beam-switching.
      cBeamSw = cObstype.contains("MX");
    }

    // Get the IF number.
    Int IFno;
    glishArr = beamRec.get("IFNO");
    glishArr.get(IFno);

    Int IFseq = cIFseq(IFno-1);
    if (IFseq == 1) {
      // First IF, is it wanted?
      if (!cWantIF1) {
        continue;
      }

    } else if (IFseq == 2) {
      // Second IF, is it wanted?
      if (!cWantIF2) {
        continue;
      }

    } else {
      // Not recognized.
      continue;
    }

    cCount++;

    // Get the integration number.
    glishArr = beamRec.get("CYCLE_NO");
    glishArr.get(cIntNo);

    // Get reference frequency stored in the header for beam 0.
    Double hdrFreq;
    glishArr = beamRec.get("REF_FREQUENCY");
    glishArr.get(hdrFreq);

    Double freqInc;
    glishArr = beamRec.get("RESOLUTION");
    glishArr.get(freqInc);

    Double refFreq = hdrFreq;
    Bool inverted = (freqInc < 0.0);
    if (inverted) {
      freqInc = -freqInc;

      if (cNChanIn%2 == 0) {
        refFreq += freqInc;
      }
    }

    Int iIF = IFseq - 1;
    if (!cIFparms(iIF)) {
      // Frequency parameters for the first integration for this IF.
      cHdrFreq(iIF) = hdrFreq;
      cRefFreq(iIF) = refFreq;
      cFreqInc(iIF) = freqInc;
      cIFparms(iIF) = True;

    } else {
      // Check frequency increment; allow a small margin for Doppler shift.
      Double mismatch = fabs(freqInc/cFreqInc(iIF) - 1.0)*cNChanIn;
      if (mismatch > 0.2) {
        char text[120];
        sprintf(text, "WARNING: integration %d, channel spacing mismatch "
          "amounts to %.1f channels in %d.", cIntNo, mismatch, cNChanIn);
        logWarning(text);
      }
    }

    if (cCount == 2) {
      // Check for frequency switching.
      Int jIF = (iIF+1)%2;

      if (cIFparms(jIF)) {
        // Dual IFs, are they simultaneous?
        cSimulIF = (cIntNo == cPrevIntNo);

        if (fabs(hdrFreq-cHdrFreq(jIF)) > 0.01*freqInc &&
            (cIFs1 == IF_BOTH || cIFs2 == IF_BOTH)) {
          if (cDoFreq) {
            // Determine frequency switching offsets.
            cChanSep = nint(fabs(refFreq - cRefFreq(jIF))/cFreqInc(jIF));

            if (cChanSep > cNChanSel) {
              cChanSep = cNChanSel + 8;
              logWarning("The large frequency separation between IFs was "
                         "truncated for display purposes;");
              logWarning("consequently the frequency scale is incorrect for "
                         "the higher frequency IF where both are shown.");
            }
          }

          if (refFreq > cRefFreq(jIF)) {
            // The previous (first) integration goes to the left.
            cIFboth = jIF;
          } else {
            // This (second) integration goes to the left.
            cIFboth = iIF;
          }
        }

      } else {
        // Only one IF.
        if (IFseq == 2) {
          if (cIFs1 == IF_1) {
            logWarning("IF 1 is not available for display in monitor "
                       "window 1.");
          } else if (cIFs1 == IF_BOTH) {
            logMessage("IF 1 is not available for display in monitor "
                       "window 1.");
          }

          if (cIFs2 == IF_1) {
            logWarning("IF 1 is not available for display in monitor "
                       "window 2.");
          } else if (cIFs2 == IF_BOTH) {
            logMessage("IF 1 is not available for display in monitor "
                       "window 2.");
          }

        } else {
          if (cIFs1 == IF_2) {
            logWarning("IF 2 is not available for display in monitor "
                       "window 1.");
          } else if (cIFs1 == IF_BOTH) {
            logMessage("IF 2 is not available for display in monitor "
                       "window 1.");
          }

          if (cIFs2 == IF_2) {
            logWarning("IF 2 is not available for display in monitor "
                       "window 2.");
          } else if (cIFs2 == IF_BOTH) {
            logMessage("IF 2 is not available for display in monitor "
                       "window 2.");
          }
        }

        cIFboth = iIF;

        // Offload the first integration if necessary.
        if (scrollBufferFull()) {
          sendScrollBuffer(glishBus);
        }
      }
    }

    if (cIntNo != cPrevIntNo) {
      // New integration.
      cIndx = (++cIndx) % cBuffLen;

      cFirstInChan.column(cIndx)  = 0;
      cFirstOutChan.column(cIndx) = 0;
      cLength.column(cIndx) = 0;

      cSpecBeam.column(cIndx) = 0;
      cSpecTime.column(cIndx) = 0.0;
      cSpecRa.column(cIndx)   = 0.0;
      cSpecDec.column(cIndx)  = 0.0;
    }

    if (IFseq == 1) {
      cSpecData1.xyPlane(cIndx) = cBlank;
    } else {
      cSpecData2.xyPlane(cIndx) = cBlank;
    }

    if (cDoFreq) {
      // Frequency axis.  Do we shift left or right?  We need to account for
      // the possibility that the reference frequency may shift by a few
      // channels between the start and end of a scan due to Doppler tracking.

      // 0-relative reference pixel.
      Int refPix = cNChanIn/2;

      Int firstInChan = 0;
      freq = refFreq + (firstInChan - refPix)*freqInc;
      Int firstOutChan = nint(refPix + (freq - cRefFreq(iIF))/cFreqInc(iIF));
      if (firstOutChan < 0) {
        // Spectrum is truncated at the left.
        firstInChan  = -firstOutChan;
        firstOutChan = 0;
      }

      cFirstInChan(iIF, cIndx)  = firstInChan;
      cFirstOutChan(iIF, cIndx) = firstOutChan;

      Int lastInChan = cNChanIn - 1;
      freq = refFreq + (lastInChan - refPix)*freqInc;
      Int lastOutChan = nint(refPix + (freq - cRefFreq(iIF))/cFreqInc(iIF));
      if (lastOutChan > cNChanIn-1) {
        // Spectrum is truncated at the right.
        lastInChan -= lastOutChan - (cNChanIn - 1);
        lastOutChan = cNChanIn - 1;
      }

      cLength(iIF, cIndx) = min(lastInChan -firstInChan,
                                lastOutChan-firstOutChan) + 1;

    } else {
      // Channel axis.
      cFirstInChan(iIF, cIndx)  = 0;
      cFirstOutChan(iIF, cIndx) = 0;
      cLength(iIF, cIndx) = cNChanIn;
    }


    Int nBeam = intRec.nelements();
    for (Int iBeam = 0; iBeam < nBeam; iBeam++) {
      beamRec = intRec.get(iBeam);

      glishArr = beamRec.get("FLOAT_DATA");
      Matrix<Float> spectra(glishArr.shape());
      glishArr.get(spectra);

      if (cFlagBlank) {
        Float flagVal = floatNaN();
        // Exract the flags.
        glishArr = beamRec.get("FLAGGED");

        // Apply flags.
        if (glishArr.shape()(0) == cNChanIn) {
          Matrix<uChar> flagtra(spectra.shape());
          glishArr.get(flagtra);
          for (Int iPol = 0; iPol < cNPol; iPol++) {
            spectra.column(iPol)(flagtra.column(iPol) > uChar(0)) = flagVal;
          }

        } else {
          // Uncompress the flagging matrix.
          Matrix<uChar> flagtmp(glishArr.shape());
          glishArr.get(flagtmp);
          for (Int iPol = 0; iPol < cNPol; iPol++) {
            if (flagtmp(0,iPol) > uChar(0)) {
              spectra.column(iPol) = flagVal;
            }
          }
        }
      }

      // 1-relative beam number.
      glishArr = beamRec.get("BEAM");
      glishArr.get(beamNo);
      cSpecBeam(iBeam,cIndx) = beamNo;

      // MJD (sec); MultibeamVis is sensitive to sub-millisecond jitter in the
      // time value so we round to the nearest ms.
      glishArr = beamRec.get("TIME");
      glishArr.get(time);
      time = round(time, 0.001);
      if (iBeam == 0) {
        cSpecTime.column(cIndx) = time;
      } else {
        cSpecTime(iBeam,cIndx) = time;
      }

      // RA and Dec for this beam (radians).
      glishArr = beamRec.get("POINTING_DIR");
      Vector<Double> raDec(glishArr.shape());
      glishArr.get(raDec);
      cSpecRa(iBeam,cIndx)  = raDec(0);
      cSpecDec(iBeam,cIndx) = raDec(1);

      // 1-relative reference beam number in beam-switching mode.
      glishArr = beamRec.get("REFBEAM");
      glishArr.get(beamNo);
      cSpecRefbeam(cIndx) = beamNo;

      // Invert the spectrum if necessary.
      if (inverted) {
        // (Slices with negative strides are not supported).
        Int jChan = cNChanIn - 1;
        Vector<Float> glishArr;
        for (Int iChan = 0; iChan < cNChanIn/2; iChan++, jChan--) {
          glishArr = spectra.row(iChan);
          spectra.row(iChan) = spectra.row(jChan);
          spectra.row(jChan) = glishArr;
        }
      }

      // Store spectral data.
      Slice all, s(cNPol*iBeam, cNPol);
      if (IFseq == 1) {
        cSpecData1.xyPlane(cIndx)(all,s) = spectra;
      } else {
        cSpecData2.xyPlane(cIndx)(all,s) = spectra;
      }
    }

    if (cCount > 1 && scrollBufferFull()) {
      sendScrollBuffer(glishBus);
    }

    cPrevIntNo = cIntNo;
  }

  return True;
}

//------------------------------------------------------ Monitor::flushHandler

// Flush the display buffer.

Bool Monitor::flushHandler(
  GlishSysEvent &event)

{
  GlishSysEventSource *glishBus = event.glishSource();

  // The first integration is always buffered since frequency switching can
  // only be detected after the second integration is received.  Normally the
  // first integration is flushed at that time but if the observation consists
  // of only a single integration then it must be done explicitly.

  if (cCount == 1 && scrollBufferFull()) {
    sendScrollBuffer(glishBus);
  }

  return True;
}

//-------------------------------------------------- Monitor::scrollBufferFull

Bool Monitor::scrollBufferFull()

{
  if (cSimulIF && (cIntNo != cPrevIntNo)) {
    return False;
  }

  if (--cEmit > 0) {
    return False;
  }

  cEmit = cBuffLen;
  return True;
}

//-------------------------------------------------- Monitor::sendScrollBuffer

void  Monitor::sendScrollBuffer(
  GlishSysEventSource *glishBus)

{
  GlishRecord    glishRec, headRec;
  Double         datTime;
  Vector<Int>    datBeam;
  Vector<Double> datRa, datDec;
  Cube<Float>    map;
  Vector<String> axisNames(3);
  Vector<Double> referenceValues(3);
  Vector<Double> referencePixels(3);
  Vector<Double> deltas(3);
  Vector<Int>    imageShape(3,0);

  if (cChanSkip == 0) {
    // Set a value that won't overload the display windows.
    Int nBeam = cNBeam + (cBeamSw?1:0);
    Int nChan = (cNChanSel + cChanSep);
    cChanSkip = 1 + (nChan * nBeam - 1) / 4096;
    logMessage("Channel increment set to ", cChanSkip, ".");
  }

  // Frequency or channel.
  if (cDoFreq) {
    axisNames(0) = "FREQ";
    referencePixels(0) = (cNChanIn/2 - cChanStart)/cChanSkip + 1;

  } else {
    axisNames(0) = "CHANNEL";
    referencePixels(0) = 1.0;
  }

  if (cSumSpec) {
    referencePixels(0) += 2;
  }

  // Beam number.
  axisNames(1) = "BEAM";
  referencePixels(1) = 1;
  referenceValues(1) = 1;
  deltas(1) = 1.0;

  // Time or integration cycle number?
  if (cDoTime) {
    // MJD in seconds.
    axisNames(2) = "TIME";
    deltas(2) = cIntTime*cBuffLen;
  } else {
    axisNames(2) = "CYCLE";
    deltas(2) = 1.0;
  }
  referencePixels(2) = 1;

  for (Int iDisp = 1; iDisp <= 2; iDisp++) {
    Int ifCode  = IF_NONE;
    Int polCode = POL_NONE;
    String eventName;

    if (iDisp == 1) {
      // Send data to display 1.
      ifCode  = cIFs1;
      polCode = cPols1;
      eventName = "scrollBuf1";
    } else if (iDisp == 2) {
      // Send data to display 2.
      ifCode  = cIFs2;
      polCode = cPols2;
      eventName = "scrollBuf2";
    }

    if (ifCode == IF_NONE) {
      continue;
    }

    Int iIF = ifCode - 1;
    if (ifCode == IF_BOTH) {
      iIF = cIFboth;
    }

    String IFid = "";
    if (ifCode == IF_1) {
      IFid = "IF " + cIFid1 + ":  ";
    } else if (ifCode == IF_2) {
      IFid = "IF " + cIFid2 + ":  ";
    } else if (ifCode == IF_BOTH) {
      IFid = "IFs " + cIFid1 + "&" + cIFid2 + ":  ";
    }

    if (polCode == POL_A) {
      headRec.add("name", IFid + "Polarization A");
    } else if (polCode == POL_B) {
      headRec.add("name", IFid + "Polarization B");
    } else if (polCode == POL_AVG) {
      headRec.add("name", IFid + "(A+B)/2 (Stokes I)");
    } else if (polCode == POL_DIF) {
      headRec.add("name", IFid + "(A-B)/2");
    } else {
      continue;
    }

    if (makeScrollMap(ifCode, polCode, map, datTime, datBeam, datRa,
        datDec)) {

      imageShape(0) = map.nrow();
      imageShape(1) = map.ncolumn();
      imageShape(2) = map.nplane();
      headRec.add("imageShape", imageShape);

      headRec.add("axisNames", axisNames);
      headRec.add("referencePixels", referencePixels);

      if (cDoFreq) {
        referenceValues(0) = cRefFreq(iIF);
      } else {
        referenceValues(0) = 1.0;
      }

      if (cDoTime) {
        // Time.
        referenceValues(2) = datTime;
      } else {
        // Integration cycle.
        referenceValues(2) = Double(cCount);
      }
      headRec.add("referenceValues", referenceValues);

      deltas(0) = cChanSkip;
      if (cDoFreq) {
        deltas(0) *= cFreqInc(iIF);
      }

      headRec.add("deltas", deltas);

      headRec.add("dataUnits", "JY/BEAM");
      headRec.add("blankVal", cBlank);

      glishRec.add("header", headRec);
      glishRec.add("BeamNo", datBeam);
      glishRec.add("RAvsBeam", datRa);
      glishRec.add("DECvsBeam", datDec);
      glishRec.add("data", map);

      glishBus->postEvent(eventName, glishRec);
    }
  }
}

//----------------------------------------------------- Monitor::makeScrollMap

Bool Monitor::makeScrollMap(
  Int ifCode,
  Int polCode,
  Cube<Float>& map,
  Double& datTime,
  Vector<Int>& datBeam,
  Vector<Double>& datRa,
  Vector<Double>& datDec)

{
  Int nChanSel = (cNChanSel + cChanSep) / cChanSkip;
  if (cSumSpec) {
    nChanSel += 2;
  }

  // The reference beam is duplicated at the end in beam switching mode.
  Int nBeam = cNBeam + (cBeamSw?1:0);

  map.resize(nChanSel, nBeam, 1);
  map = cBlank;

  datBeam.resize(nBeam);
  datRa.resize(nBeam);
  datDec.resize(nBeam);

  Double rowTime = -1.0;
  Double rowRa, rowDec;

  Bool gotOne = False;

  // True 1-relative reference beam number.
  Int refbeam = cSpecRefbeam(cIndx);

  for (Int iBeam = 0; iBeam < cNBeam; iBeam++) {
    if (copyRowToMap(iBeam, ifCode, polCode, rowTime, rowRa, rowDec, map)) {
      // True 1-relative beam number.
      Int beamNo = cSpecBeam(iBeam, cIndx);

      datTime = rowTime;
      datBeam(iBeam) = beamNo;
      datRa(iBeam)   = rowRa;
      datDec(iBeam)  = rowDec;

      if (cBeamSw && beamNo == refbeam) {
        // Duplicate the reference beam.
        map.xyPlane(0).column(cNBeam) = map.xyPlane(0).column(iBeam);
        datBeam(cNBeam) = beamNo;
        datRa(cNBeam)   = rowRa;
        datDec(cNBeam)  = rowDec;
      }

      gotOne = True;
    }
  }

  return gotOne;
}

//------------------------------------------------------ Monitor::copyRowToMap

Bool Monitor::copyRowToMap(
  Int iBeam,
  Int ifCode,
  Int polCode,
  Double &datTime,
  Double &datRa,
  Double &datDec,
  Cube<Float> &map)

{
  // Reference to the output spectrum.
  Vector<Float> outSpec = map.xyPlane(0).column(iBeam);

  if (!cBeamMask(iBeam)) {
    datTime = -1.0;
    datRa   = -1.0;
    datDec  = -100.0;
    outSpec = 0.0f;

    return False;
  }

  datTime = cSpecTime(iBeam, cIndx);
  datRa   = cSpecRa(iBeam, cIndx);
  datDec  = cSpecDec(iBeam, cIndx);

  Int nChan    = cNChanIn;
  Int nChanSel = cNChanSel;
  if (ifCode == IF_BOTH) {
    nChan    += cChanSep;
    nChanSel += cChanSep;
  }

  Vector<Float> spectrum(nChan);

  if (cTimeMode == NONE) {
    if (!getSpectrum(0, iBeam, ifCode, polCode, spectrum)) {
      return False;
    }

  } else {
    // Some type of time-averaging is required.
    Double lastTime = datTime;
    Double thisTime;

    // Don't span time jumps.
    Int count = 1;
    for (Int ibuff = 1; ibuff < cBuffLen; ibuff++) {
      thisTime = cSpecTime(iBeam, scrollIndex(ibuff));
      if (fabs(lastTime-thisTime) < cIntTime*1.1) {
        count++;
        lastTime = thisTime;
      } else {
        break;
      }
    }

    // Compute mean time and position.
    if (count > 1) {
      switch (cTimeMode) {
        case MEAN:
        case MEDIAN:
        case MAXIMUM:
        case RMS: {
          for (Int ibuff = 1; ibuff < count; ibuff++) {
            Int idx = scrollIndex(ibuff);
            datTime += cSpecTime(iBeam, idx);
            datRa   += cSpecRa(iBeam, idx);
            datDec  += cSpecDec(iBeam, idx);
          }

          datTime /= Float(count);
          datRa   /= Float(count);
          datDec  /= Float(count);

          break;
        }
        default: {
          break;
        }
      }
    }

    switch (cTimeMode) {
      case MEAN: {
        Int n = 0;
        if (getSpectrum(0, iBeam, ifCode, polCode, spectrum)) {
          n = 1;
        }

        if (count > 1) {
          Vector<Float> tmpSpec(nChan);
          for (Int ibuff = 1; ibuff < count; ibuff++) {
            if (getSpectrum(ibuff, iBeam, ifCode, polCode, tmpSpec)) {
              spectrum += tmpSpec;
              n++;
            }
          }
        }

        if (n == 0) {
          return False;
        } else if (n > 1) {
          spectrum /= Float(n);
        }

        break;
      }
      case MEDIAN: {
        if (count > 1) {
          Vector<Float> tmpBuff(count);
          for (Int ichan = cChanStart; ichan < cChanStart+nChanSel; ichan++) {
            getChannel(0, ichan, iBeam, ifCode, polCode, tmpBuff);
            spectrum(ichan) = median(tmpBuff);
          }

        } else {
          datTime = -1.0;
          datRa   = -1.0;
          datDec  = -1.0;
          outSpec = 0.0f;

          return False;
        }

        break;
      }
      case MAXIMUM: {
        if (!getSpectrum(0, iBeam, ifCode, polCode, spectrum)) {
          return False;
        }

        if (count > 1) {
          Vector<Float> tmpSpec(nChan);
          for (Int ibuff = 1; ibuff < cBuffLen; ibuff++) {
            if (getSpectrum(ibuff, iBeam, ifCode, polCode, tmpSpec)) {
              spectrum = max(spectrum, tmpSpec);
            }
          }
        }

        break;
      }
      case RMS: {
        if (count > 2) {
          Vector<Float> tmpBuff(count);
          for (Int ichan = cChanStart; ichan < cChanStart+nChanSel; ichan++) {
            getChannel(0, ichan, iBeam, ifCode, polCode, tmpBuff);
            spectrum(ichan) = stddev(tmpBuff);
          }

        } else {
          datTime = -1.0;
          datRa   = -1.0;
          datDec  = -1.0;
          outSpec = 0.0f;

          return False;
        }
        break;
      }
      default: {
        if (!getSpectrum(0, iBeam, ifCode, polCode, spectrum)) {
          return False;
        }

        break;
      }
    }
  }


  Int chanOff = 0;
  if (cSumSpec) {
    outSpec(0) = mean(spectrum);
    outSpec(1) = 0.0f;
    chanOff = 2;
  }

  Int nOutChan = outSpec.nelements() - chanOff;

  if (cDoHanning) {
    // Apply Hanning smoothing.
    Int i, j = cChanStart + 1;
    for (i = chanOff+1; i < chanOff+nOutChan-1; i++) {
      outSpec(i) = 0.25*(spectrum(j-1) + spectrum(j+1)) + 0.5*spectrum(j);
      j += cChanSkip;
    }

    // Do end channels.
    i = chanOff;
    j = cChanStart;
    outSpec(i) = 0.5*(spectrum(j) + spectrum(j+1));

    i = chanOff + nOutChan - 1;
    j = cChanStart + nChanSel - 1;
    outSpec(i) = 0.5*(spectrum(j-1) + spectrum(j));

  } else {
    // Straight copy.
    Slice chanSel(cChanStart, nOutChan, cChanSkip);
    Slice outChan(chanOff, nOutChan);
    outSpec(outChan) = spectrum(chanSel);
  }

  return True;
}

//------------------------------------------------------- Monitor::getSpectrum

Bool Monitor::getSpectrum(
  Int index,
  Int iBeam,
  Int ifCode,
  Int polCode,
  Vector<Float> &spectrum)

{
  spectrum = cBlank;
  if (ifCode == IF_NONE || !cBeamMask(iBeam) || index < 0) {
    return False;
  }

  Bool gotOne = False;

  Int iPolA = cNPol*iBeam;
  Int iPolB = iPolA + 1;
  Int idx = scrollIndex(index);

  if (cLength(0,idx) && (ifCode == IF_1 || ifCode == IF_BOTH)) {
    Int  firstInChan1 = cFirstInChan(0,idx);
    Int   lastInChan1 = firstInChan1 + cLength(0,idx) - 1;
    Int firstOutChan1 = cFirstOutChan(0,idx);
    if (firstInChan1 < cChanStart) {
      firstOutChan1 += (cChanStart - firstInChan1);
      firstInChan1 = cChanStart;
    }
    if (lastInChan1 > cChanEnd) {
      lastInChan1 = cChanEnd;
    }

    Int len1 = lastInChan1 - firstInChan1 + 1;
    if (len1 > 0) {
      if (ifCode == IF_BOTH && cIFboth == 1) {
        firstOutChan1 += cChanSep;
      }

      Slice  in1( firstInChan1, len1);
      Slice out1(firstOutChan1, len1);

      if (polCode == POL_A) {
        // Polarization A.
        spectrum(out1) = cSpecData1(in1, iPolA, idx).nonDegenerate();
        gotOne = True;

      } else if (polCode == POL_B) {
        // Polarization B.
        spectrum(out1) = cSpecData1(in1, iPolB, idx).nonDegenerate();
        gotOne = True;

      } else if (polCode == POL_AVG) {
        // Stokes I; (A+B)/2.
        spectrum(out1) = (cSpecData1(in1, iPolA, idx).nonDegenerate() +
                          cSpecData1(in1, iPolB, idx).nonDegenerate()) / 2.0f;
        gotOne = True;

      } else if (polCode == POL_DIF) {
        // (A-B)/2.
        spectrum(out1) = (cSpecData1(in1, iPolA, idx).nonDegenerate() -
                          cSpecData1(in1, iPolB, idx).nonDegenerate()) / 2.0f;
        gotOne = True;
      }
    }
  }

  if (cLength(1,idx) && (ifCode == IF_2 || ifCode == IF_BOTH)) {
    Int  firstInChan2 = cFirstInChan(1,idx);
    Int   lastInChan2 = firstInChan2 + cLength(1,idx) - 1;
    Int firstOutChan2 = cFirstOutChan(1,idx);
    if (firstInChan2 < cChanStart) {
      firstOutChan2 += (cChanStart - firstInChan2);
      firstInChan2 = cChanStart;
    }
    if (lastInChan2 > cChanEnd) {
      lastInChan2 = cChanEnd;
    }

    Int len2 = lastInChan2 - firstInChan2 + 1;
    if (len2 > 0) {
      if (ifCode == IF_BOTH && cIFboth == 0) {
        firstOutChan2 += cChanSep;
      }

      Slice  in2( firstInChan2, len2);
      Slice out2(firstOutChan2, len2);

      if (polCode == POL_A) {
        // Polarization A.
        spectrum(out2) = cSpecData2(in2, iPolA, idx).nonDegenerate();
        gotOne = True;

      } else if (polCode == POL_B) {
        // Polarization B.
        spectrum(out2) = cSpecData2(in2, iPolB, idx).nonDegenerate();
        gotOne = True;

      } else if (polCode == POL_AVG) {
        // Stokes I; (A+B)/2.
        spectrum(out2) = (cSpecData2(in2, iPolA, idx).nonDegenerate() +
                          cSpecData2(in2, iPolB, idx).nonDegenerate()) / 2.0f;
        gotOne = True;

      } else if (polCode == POL_DIF) {
        // (A-B)/2.
        spectrum(out2) = (cSpecData2(in2, iPolA, idx).nonDegenerate() -
                          cSpecData2(in2, iPolB, idx).nonDegenerate()) / 2.0f;
        gotOne = True;
      }
    }
  }

  return gotOne;
}

//-------------------------------------------------------- Monitor::getChannel

void Monitor::getChannel(
  Int index,
  Int channel,
  Int iBeam,
  Int ifCode,
  Int polCode,
  Vector<Float> &buff)

{
  if (!cBeamMask(iBeam)) {
    return;
  }

  Int buffLen = buff.nelements();
  Int ichan1 = -1;
  Int ichan2 = -1;
  Int iPolA = cNPol*iBeam;
  Int iPolB = iPolA + 1;

  buff = 0.0f;

  for (Int ibuff = 0; ibuff < buffLen; ibuff++) {
    Int idx = scrollIndex(index++);

    ichan1 = cFirstInChan(0,idx) + (cChanStart + channel) -
             cFirstOutChan(0,idx);
    if (ifCode == IF_BOTH && cIFboth == 1) {
      ichan1 -= cChanSep;
    }

    if (ichan1 < cChanStart || ichan1 > cChanEnd) {
      ichan1 = -1;

      ichan2 = cFirstInChan(1,idx) + (cChanStart + channel) -
               cFirstOutChan(1,idx);
      if (ifCode == IF_BOTH && cIFboth == 0) {
        ichan2 -= cChanSep;
      }

      if (ichan2 < cChanStart || ichan2 > cChanEnd) {
        ichan2 = -1;
      }
    }

    if (polCode == POL_A) {
      // Polarization A.

      if (ichan1 >= 0) {
        buff(ibuff) = cSpecData1(ichan1, iPolA, idx);
      } else if (ichan2 >= 0) {
        buff(ibuff) = cSpecData2(ichan2, iPolA, idx);
      }

    } else if (polCode == POL_B) {
      // Polarization B.
      if (ichan1 >= 0) {
        buff(ibuff) = cSpecData1(ichan1, iPolB, idx);
      } else if (ichan2 >= 0) {
        buff(ibuff) = cSpecData2(ichan2, iPolB, idx);
      }

    } else if (polCode == POL_AVG) {
      // Stokes I; (A+B)/2.
      if (ichan1 >= 0) {
        buff(ibuff) = (cSpecData1(ichan1, iPolA, idx) +
                       cSpecData1(ichan1, iPolB, idx)) / 2.0f;
      } else if (ichan2 >= 0) {
        buff(ibuff) = (cSpecData2(ichan2, iPolA, idx) +
                       cSpecData2(ichan2, iPolB, idx)) / 2.0f;
      }

    } else if (polCode == POL_DIF) {
      // (A-B)/2.
      if (ichan1 >= 0) {
        buff(ibuff) = (cSpecData1(ichan1, iPolA, idx) -
                       cSpecData1(ichan1, iPolB, idx)) / 2.0f;
      } else if (ichan2 >= 0) {
        buff(ibuff) = (cSpecData2(ichan2, iPolA, idx) -
                       cSpecData2(ichan2, iPolB, idx)) / 2.0f;
      }
    }
  }
}

//------------------------------------------------------- Monitor::scrollIndex

// Compute the index into the scroll buffer.
Int Monitor::scrollIndex(Int index)
{
  return (cIndx - index + cBuffLen) % cBuffLen;
}
