//#---------------------------------------------------------------------------
//# pksreader.cc: Glish client that reads single-dish data.
//#---------------------------------------------------------------------------
//# Copyright (C) 2000-2006
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
//# $Id: pksreader.cc,v 19.23 2006/07/13 06:26:00 mcalabre Exp $
//#---------------------------------------------------------------------------
//# Original: 2000/07/21 Mark Calabretta, ATNF
//#---------------------------------------------------------------------------

// AIPS++ includes.
#include <casa/iostream.h>
#include <casa/sstream.h>
#include <casa/stdio.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Slice.h>
#include <casa/Arrays/Vector.h>
#include <casa/Exceptions/Error.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishEvent.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>
#include <casa/BasicSL/Complex.h>
#include <casa/BasicSL/String.h>

// Parkes includes.
#include <atnf/pks/pksmb_support.h>
#include <atnf/PKSIO/PKSreader.h>

#include <casa/namespace.h>

// Glish event handlers.
Bool  init_event(GlishSysEvent &event, void *);
Bool  read_event(GlishSysEvent &event, void *);
Bool close_event(GlishSysEvent &event, void *);


// Client parameters.
Bool gCalibrate;			// Apply flux calibration?
Bool gRecalibrate;			// Reapply flux calibration?
Int  gAggregate;			// Grouping factor, 1, 2, 3, ...
Matrix<Float> gCalFctr;			// Calibration factors for each beam
					// and polarization.
Vector<Complex> gXCalFctr;		// Cross-polarization calibration
					// factors for each beam.

// Global variables.
String gClientName = "pksreader";
PKSreader *gReader = 0;			// Parkes single-dish reader.

GlishRecord gObsHeader;
Int    gNBeam;				// Number of beams selected for input.
Int    gNIF;				// Number of IFs   selected for input.

Bool   gDeferredEOF;			// True if EOF was deferred from last
					// read.
Bool   gGetXPol;			// True if reading cross-pol data.
String gScanId;				// Scan identification.
Int    gScanNo;				// Scan number of last record read.
Int    gNScan;				// Number of scans read.
Int    gCycleNo;			// Integration cycle number of last
					// record read.
Int    gNRecord;			// Number of records read.
Int    gNRecordS;			// Number of records read in the
					// current scan.
Int    gNFlag;				// Number of flagged integrations.

//----------------------------------------------------------------------- main

int main(int argc, char **argv)
{
  try {
    // Set up the Glish event stream.
    GlishSysEventSource glishStream(argc, argv);
    glishStream.addTarget(init_event, "init");
    glishStream.addTarget(read_event, "read");
    glishStream.addTarget(close_event, "close");
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
  String version = "$Revision: 19.23 $";
  String date = "$Date: 2006/07/13 06:26:00 $";

  logMessage("pksreader (v" + String(version.after(' ')).before(' ') +
             ", " + String(date.after(' ')).before(' ') + ") initializing.");

  GlishSysEventSource *glishBus = event.glishSource();
  GlishValue glishVal = event.val();

  // Check that argument is a record.
  if (glishVal.type() != GlishValue::RECORD) {
    logError("Initialization error, argument to \"init\" should be a record.");
    glishBus->postEvent("init_error", "Client initialization failed");
    return True;
  }

  GlishRecord parms = glishVal;

  // Construct a PKSreader.
  Bool   interpolate;
  Int    retry;
  String directory, file;
  getParm(parms, "directory",   String(""), directory);
  getParm(parms, "file",        String(""), file);
  getParm(parms, "retry",       0,          retry);
  getParm(parms, "interpolate", True,       interpolate);

  delete gReader;
  Bool   haveBase, haveSpectra;
  Vector<Bool> beams, haveXPol, IFs;
  Vector<uInt> nChan, nPol;
  String format, inName = directory + "/" + file;
  if ((gReader = getPKSreader(inName, retry, interpolate, format, beams, IFs,
                              nChan, nPol, haveXPol, haveBase,
                              haveSpectra)) == 0) {
    logError(inName + " initialization error, " + format + ".");
    glishBus->postEvent("init_error", format);
    return True;
  }

  // Check that spectral data is present.
  if (!haveSpectra) {
    delete gReader;
    gReader = 0;
    logError(inName + " initialization error, spectral data absent.");
    glishBus->postEvent("init_error", "Spectral data absent.");
    return True;
  }

  logMessage("Reading " + format + " format from " + inName);


  // Extract remaining parameters from the glish record.
  Int    endChan, startChan;
  Vector<Bool> beamSel(13), IFsel(16);
  gCalFctr.resize(13,2);
  gXCalFctr.resize(13);

  getParm(parms, "beamsel",     True,          beamSel);
  getParm(parms, "IFsel",       True,          IFsel);
  getParm(parms, "startChan",   1,             startChan);
  getParm(parms, "endChan",     0,             endChan);
  getParm(parms, "getXpol",     False,         gGetXPol);
  getParm(parms, "calibrate",   False,         gCalibrate);
  getParm(parms, "recalibrate", False,         gRecalibrate);
  getParm(parms, "calfctr",     0.0f,          gCalFctr);
  getParm(parms, "xcalfctr",    Complex(0.0f), gXCalFctr);

  // The aggregation option has been removed from pksreader.g.
  gAggregate = 1;


  // Beam selection.
  if (ntrue(beamSel) == 0) {
    delete gReader;
    gReader = 0;
    logError("Initialization error, no beams were selected.");
    glishBus->postEvent("init_error", "No beams were selected.");
    return True;
  }

  Int nBeam = beams.nelements();
  Int nBeamSel = beamSel.nelements();
  if (nBeamSel != nBeam) {
    // Resize the beam selection vector.
    beamSel.resize(nBeam, True);
    if (nBeamSel < nBeam) {
      beamSel(Slice(nBeamSel,nBeam-nBeamSel)) = False;
    }
    nBeamSel = nBeam;
  }
  beamSel = beams && beamSel;
  gNBeam  = ntrue(beamSel);

  Char text[120];
  if (nBeam == 1) {
    logMessage("Single-beam data.");

  } else {
    if (gNBeam == nBeam) {
      sprintf(text, "Multibeam data, all %d beams selected for input.",
              nBeam);
    } else {
      sprintf(text, "Multibeam data, %d of %d beams selected for input.",
              gNBeam, nBeam);
    }

    logMessage(text);
  }

  if (gNBeam == 0) {
    delete gReader;
    gReader = 0;
    logError("Initialization error, none of the selected beams are available "
             "in the input file.");
    glishBus->postEvent("init_error", "No selected beams available.");
    return True;
  }


  // IF selection.
  if (ntrue(IFsel) == 0) {
    delete gReader;
    gReader = 0;
    logError("Initialization error, no IFs were selected.");
    glishBus->postEvent("init_error", "No IFs were selected.");
    return True;
  }

  uInt nIF = IFs.nelements();
  uInt nIFsel = IFsel.nelements();
  if (nIFsel != nIF) {
    // Resize the IF selection vector.
    IFsel.resize(nIF, True);
    if (nIFsel < nIF) {
      IFsel(Slice(nIFsel,nIF-nIFsel)) = False;
    }
    nIFsel = nIF;
  }
  IFsel = IFs && IFsel;
  gNIF  = ntrue(IFsel);

  Vector<Int> start(nIF, startChan);
  Vector<Int> end(nIF, endChan);
  for (uInt iIF = 0; iIF < nIF; iIF++) {
    Int nchan = nChan(iIF);

    if (start(iIF) < 1) {
      start(iIF) += nchan;
      if (start(iIF) < 1) start(iIF) = 1;
    } else if (start(iIF) > nchan) {
      start(iIF) = nchan;
    }

    if (end(iIF) < 1) {
      end(iIF) += nchan;
      if (end(iIF) < 1) end(iIF) = 1;
    } else if (end(iIF) > nchan) {
      end(iIF)   = nchan;
    }
  }

  Bool chanSel = False;
  if (nIF == 1) {
    sprintf(text, "Single IF data with %d channel%s and %d polarization%s.",
            nChan(0), (nChan(0) > 1) ? "s" : "",
            nPol(0) + (haveXPol(0) ? 2 : 0), (nPol(0) > 1) ? "s" : "");
    logMessage(text);

    if (start(0) == 1 && end(0) == Int(nChan(0))) {
      sprintf(text, "Channels selected: ALL");
    } else {
      sprintf(text, "Channels selected: %d - %d", start(0), end(0));
      chanSel = True;
    }
    logMessage(text);

  } else if (nIF > 1) {
    logMessage("Multiple IF data:   IF   nChan   nPol");
    for (uInt iIF = 0; iIF < nIF; iIF++) {
      sprintf(text, "%22d%8d%6d", iIF+1, nChan(iIF), nPol(iIF));
      if (IFsel(iIF)) {
        if (start(iIF) == 1 && end(iIF) == Int(nChan(iIF))) {
          strcat(text, "   ...selected, channels: ALL");
        } else {
          sprintf(text+strlen(text), "   ...selected, channels: %d - %d",
            start(iIF), end(iIF));
          chanSel = True;
        }
      }
      logMessage(text);
    }
  }

  if (gNIF < 1 || 2 < gNIF) {
    delete gReader;
    gReader = 0;
    if (gNIF < 1) {
      logError("Initialization error, none of the selected IFs are available "
               "in the input file.");
    } else {
      logError("Initialization error, more than two IFs were selected.");
    }
    glishBus->postEvent("init_error", "No selected IFs available.");
    return True;
  }

  // Check IFs for consistent numbers of channels and polarizations.
  uInt nchans = 0;
  uInt npols  = 0;
  for (uInt iIF = 0; iIF < nIF; iIF++) {
    if (!IFsel(iIF)) continue;

    uInt nChanSel = abs(end(iIF) - start(iIF)) + 1;
    if (nchans) {
      if (nChanSel != nchans || nPol(iIF) != npols) {
        delete gReader;
        gReader = 0;
        logError("Initialization error, selected IFs have differing numbers "
                 "of channels and/or polarizations.");
        logWarning("livedata normally only processes one IF at a time.  "
                   "However two IFs may be processed");
        logWarning("simultaneously if the spectra are conformant; this "
                   "includes frequency-switched data.");
        glishBus->postEvent("init_error", "Inconsistent spectra sizes.");
        return True;
      }

    } else {
      nchans = nChanSel;
      npols  = nPol(iIF);
    }
  }

  if (chanSel) {
    logMessage("Number of channels selected for input: ", nchans);
  }

  // Is cross-polarization data available?
  if (gGetXPol) {
    if (ntrue(haveXPol) == 0) {
      gGetXPol = False;
      logWarning("WARNING: Cross-polarization data was requested but is not "
                 "available.");

    } else {
      for (uInt iIF = 0; iIF < nIF; iIF++) {
        if (!IFsel(iIF)) continue;

        if (!haveXPol(iIF)) {
          gGetXPol = False;
          logWarning("WARNING: Cross-polarization data is present for some "
                     "IFs but not others, skipping.");
          break;
        }
      }
    }
  }


  // Apply selection criteria.
  Vector<Int> ref;
  nchans = gReader->select(beamSel, IFsel, start, end, ref, True, gGetXPol);


  // Get basic parameters.
  Double bandwidth, refFreq, utc;
  String antName, dopplerFrame, observer, obsType, project;
  Float  equinox;
  Vector<Double> antPos(3);
  Int status = gReader->getHeader(observer, project, antName, antPos,
                                  obsType, equinox, dopplerFrame, utc,
                                  refFreq, bandwidth);
  if (status) {
    delete gReader;
    gReader = 0;
    logError("Initialization error, failed to get data description.");
    glishBus->postEvent("init_error", "Failed to get data description.");
    return True;
  }

  // Store scan-invariant data for later use.
  gObsHeader.add("OBSERVER", observer);
  gObsHeader.add("PROJECT",  project);
  gObsHeader.add("ANTENNA_NAME", antName);
  gObsHeader.add("ANTENNA_POSITION", antPos);
  gObsHeader.add("EQUINOX", equinox);
  gObsHeader.add("DOPPLER_FRAME", dopplerFrame);


  // Return information about the content of the data.
  GlishRecord header;
  header.add("format", format);
  header.add("beams",  beams);
  header.add("IFs",    IFs);
  header.add("nchans", Int(nchans));
  header.add("npols",  Int(npols));
  header.add("xpol",   gGetXPol);
  header.add("utc",    utc);
  header.add("reffreq", refFreq);
  header.add("bandwidth", bandwidth);

  glishBus->postEvent("initialized", header);


  gDeferredEOF = False;
  gScanNo = 0;
  gNScan  = 0;
  gNRecord = 0;
  gNFlag  = 0;

  return True;
}

//----------------------------------------------------------------- read_event

// Handler for "read" event; package (gAggregate * gNBeam) integrations into
// one output Glish record.

Bool read_event(GlishSysEvent &event, void *)
{
  GlishSysEventSource *glishBus = event.glishSource();

  // Check for EOF held over from last time.
  if (gDeferredEOF) {
    glishBus->postEvent("eof", "End-of-file");
    return True;
  }

  Int    beamNo, IFno, cycleNo, refBeam, scanNo;
  Float  azimuth, elevation, focusAxi, focusRot, focusTan, humidity, parAngle,
         pressure, temperature, windAz, windSpeed;
  Double bandwidth, freqInc, interval, mjd, refFreq, restFreq, srcVel;
  String          fieldName, obsType, srcName, tcalTime;
  Vector<Float>   calFctr, sigma, tcal, tsys;
  Matrix<Float>   baseLin, baseSub;
  Vector<Double>  direction(2), scanRate(2), srcDir(2), srcPM(2);
  Matrix<Float>   spectra;
  Matrix<uChar>   flagtra;
  Complex         xCalFctr;
  Vector<Complex> xPol;


  GlishRecord aggRec;
  Int iRec = 0;
  while (iRec < gAggregate) {
    // A record contains data for all selected beams but only one IF.
    GlishRecord intRec;
    GlishRecord intRecHeader = gObsHeader;

    //------------------------------------------------------------------------
    // For gNBeam == 1, each of the simultaneous (or sequential) IFs will be
    // emitted in a separate Glish record.
    //
    // For gNBeam > 1, multiple simultaneous IFs are not currently handled,
    // though multiple sequential IFs (e.g. frequency-switching data) are.  A
    // relatively simple way to generalize this would be to remove the option
    // to aggregate cycles and replace it with IF-based aggregation.
    //------------------------------------------------------------------------

    Int status = 0;
    Bool allFlagged = True;
    for (Int ibeam = 0; ibeam < gNBeam; ibeam++) {
      // Read the next data record.
      status = gReader->read(scanNo, cycleNo, mjd, interval, fieldName,
                             srcName, srcDir, srcPM, srcVel, obsType, IFno,
                             refFreq, bandwidth, freqInc, restFreq, tcal,
                             tcalTime, azimuth, elevation, parAngle, focusAxi,
                             focusTan, focusRot, temperature, pressure,
                             humidity, windSpeed, windAz, refBeam, beamNo,
                             direction, scanRate, tsys, sigma, calFctr,
                             baseLin, baseSub, spectra, flagtra, xCalFctr,
                             xPol);

      // Check for incomplete cycles.
      if (ibeam && (status == -1 || cycleNo > gCycleNo)) {
        ostringstream buffer;
        buffer << "Scan " << gScanNo << ", integration cycle " << gCycleNo
               << " contained only " << ibeam << " of the " << gNBeam
               << " selected beams";
        logWarning(buffer);
        logWarning("that should have been present, skipped.");

        // Start again.
        ibeam = 0;
      }

      if (status) {
        if (status == -1) {
          // EOF.
          if (iRec) {
            // Have to process the data from previous records.
            gDeferredEOF = True;
            break;
          } else {
            glishBus->postEvent("eof", "End-of-file");
            return True;
          }
        }

        logError("Read error.");
        glishBus->postEvent("read_error", "Read error");
        return True;
      }

      if (ibeam == 0) {
        if (scanNo != gScanNo) {
          if (gScanNo) {
            ostringstream buffer;
            buffer << "Scan " << gScanNo << ", ";
            int nBin = gNRecordS / gCycleNo / gNIF;
            if (nBin > 1) {
              // Binning mode factor.
              buffer << nBin << " x " << gCycleNo << " binned";
            } else {
              buffer << gCycleNo;
            }
            buffer << " integration cycles, field name " << gScanId << ".";
            logMessage(buffer);

          } else {
            logMessage("Integration time: ", interval, "s.");
          }

          gScanId = "\"" + fieldName + "\"";
          gScanNo = scanNo;
          gNScan++;
          gNRecordS = 0;
        }

        gCycleNo = cycleNo;
      }


      if (ibeam == 0) {
        // Store beam-invariant data.
        intRecHeader.add("SCAN_NO",   scanNo);
        intRecHeader.add("CYCLE_NO",  cycleNo);
        intRecHeader.add("TIME",      mjd*86400.0);
        intRecHeader.add("INTERVAL",  interval);
        intRecHeader.add("FIELD_NAME",  fieldName);
        intRecHeader.add("SOURCE_NAME", srcName);
        intRecHeader.add("REFERENCE_DIR", srcDir);
        intRecHeader.add("PROPER_MOTION", srcPM);
        intRecHeader.add("SOURCE_SYSVEL", srcVel);
        intRecHeader.add("OBSTYPE",       obsType);
        intRecHeader.add("IFNO",          IFno);
        intRecHeader.add("REST_FREQUENCY", restFreq);
        intRecHeader.add("REFBEAM",   refBeam);
        intRecHeader.add("TCAL",      tcal);
        intRecHeader.add("TCALTIME",  tcalTime);
        intRecHeader.add("FOCUSAXI",  focusAxi);
        intRecHeader.add("FOCUSTAN",  focusTan);
        intRecHeader.add("FOCUSROT",  focusRot);
        intRecHeader.add("TEMPERATURE",  temperature);
        intRecHeader.add("PRESSURE",     pressure);
        intRecHeader.add("REL_HUMIDITY", humidity);
        intRecHeader.add("WINDSPEED",    windSpeed);
        intRecHeader.add("WINDAZ",       windAz);
      }

      GlishRecord beamRec = intRecHeader;
      Int nChan = spectra.nrow();
      Int nPol  = spectra.ncolumn();

      // Should be beam-invariant but stored with each beam for convenience.
      beamRec.add("NUM_CHANNEL", nChan);
      beamRec.add("NOPOL", nPol);

      // Store beam-specific data (frequency varies due to Doppler).
      beamRec.add("BEAM", beamNo);
      beamRec.add("POINTING_DIR", direction);
      beamRec.add("PHASE_DIR_RATE", scanRate);
      beamRec.add("REF_FREQUENCY", refFreq);
      beamRec.add("TOTAL_BANDWIDTH", bandwidth);
      beamRec.add("RESOLUTION", freqInc);
      beamRec.add("AZIMUTH",   azimuth);
      beamRec.add("ELEVATION", elevation);
      beamRec.add("PARANGLE",  parAngle);

      // Apply calibration if required.
      if (gCalibrate) {
        for (Int ipol = 0; ipol < nPol; ipol++) {
          if (calFctr(ipol) == 0.0f || gRecalibrate) {
            if (gCalFctr(ibeam,ipol) != 0.0f) {
              // Create a reference to stop the compiler whinging.
              Vector<Float> spectrum = spectra.column(ipol);

              Float factor = gCalFctr(ibeam,ipol);
              if (calFctr(ipol) != 0.0f) {
                // Undo previous factor.
                factor /= calFctr(ipol);
              }

              tsys(ipol)  *= factor;
              sigma(ipol) *= factor;
              spectrum    *= factor;

              calFctr(ipol) = gCalFctr(ibeam,ipol);
            }
          }
        }
      }

      beamRec.add("TSYS", tsys);
      beamRec.add("SIGMA", sigma);

      beamRec.add("CALFCTR", calFctr);
      if (baseLin.nelements()) {
        beamRec.add("BASELIN", baseLin);
        beamRec.add("BASESUB", baseSub);
      }
      beamRec.add("FLOAT_DATA", spectra);

      // Flagging.
      Bool compress = True;
      for (Int ipol = 0; ipol < nPol; ipol++) {
        if (allEQ(flagtra, flagtra(0,ipol))) {
          if (!flagtra(0,ipol)) allFlagged = False;
        } else {
          compress = False;
          allFlagged = False;
        }
      }

      if (compress) {
        beamRec.add("FLAGGED", flagtra(Slice(0,1),Slice()));
      } else {
        beamRec.add("FLAGGED", flagtra);
      }

      // Cross-polarization data.
      if (gGetXPol) {
        if (gCalibrate) {
          if (xCalFctr == Complex(0.0f,0.0f) || gRecalibrate) {
            if (gXCalFctr(ibeam) != Complex(0.0f,0.0f)) {
              Complex factor = gXCalFctr(ibeam);
              if (xCalFctr != Complex(0.0f,0.0f)) {
                // Undo previous factor.
                factor /= xCalFctr;
              }

              xPol *= factor;
              xCalFctr = gXCalFctr(ibeam);
            }
          }
        }

        beamRec.add("XCALFCTR", xCalFctr);
        beamRec.add("DATA", xPol);
      }

      char beamLabel[7];
      sprintf(beamLabel, "beam%02d", beamNo);
      intRec.add(beamLabel, beamRec);
    }

    if (status) {
      // Can only get here if iRec > 0.
      break;
    }

    // Check that we have the required number of beams.
    Int nBeam = intRec.nelements();
    if (nBeam != gNBeam) {
      // No, drop this record.
      ostringstream buffer;
      buffer << "Scan " << scanNo << ", integration " << cycleNo
             << " contained " << nBeam << " beams instead of " << gNBeam
             << " - dropped.";
      logWarning(buffer);
      continue;
    }

    // Drop this cycle if it's all flagged.
    if (allFlagged) {
      gNFlag++;
      ostringstream buffer;
      buffer << "Scan " << scanNo << ", integration " << cycleNo
             << " was completely flagged - dropped.";
      logWarning(buffer);
      continue;
    }

    char intRecLabel[6];
    sprintf(intRecLabel, "int%02d", ++iRec);
    aggRec.add(intRecLabel, intRec);

    gNRecordS++;
    gNRecord++;
  }

  glishBus->postEvent("data", aggRec);

  return True;
}

//---------------------------------------------------------------- close_event

// Handler for "close" event.

Bool close_event(GlishSysEvent &event, void *)
{
  GlishSysEventSource *glishBus = event.glishSource();

  delete gReader;
  gReader = 0;

  if (gNFlag) {
    ostringstream buffer;
    buffer << gNFlag << " completely flagged integrations were dropped.";
    logWarning(buffer);
  }

  ostringstream buffer;
  buffer << "Scan " << gScanNo << ", ";
  int nBin = gNRecordS / gCycleNo / gNIF;
  if (nBin > 1) {
    // Binning mode factor.
    buffer << nBin << " x " << gCycleNo << " binned";
  } else {
    buffer << gCycleNo;
  }
  buffer << " integration cycles, field name " << gScanId << ".";
  logMessage(buffer);

  logMessage("File closed, ", gNRecord / gNIF, " complete integration cycles "
             "read.");
  glishBus->postEvent("closed", "Input file closed");

  return True;
}
