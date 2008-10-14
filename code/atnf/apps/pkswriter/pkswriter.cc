//#---------------------------------------------------------------------------
//# pkswriter.cc: Glish client that writes single-dish data to file.
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
//# $Id: pkswriter.cc,v 19.17 2006/07/13 07:57:04 mcalabre Exp $
//#---------------------------------------------------------------------------
//# Original: 2000/07/21 Mark Calabretta, ATNF
//#---------------------------------------------------------------------------

// AIPS++ includes.
#include <casa/iostream.h>
#include <casa/sstream.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Slice.h>
#include <casa/Arrays/Vector.h>
#include <casa/Exceptions/Error.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishEvent.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>
#include <casa/BasicSL/String.h>

// Parkes includes.
#include <atnf/pks/pksmb_support.h>
#include <atnf/PKSIO/PKSwriter.h>
#include <atnf/PKSIO/PKSSDwriter.h>

#include <casa/namespace.h>

// Glish event handlers.
Bool  init_event(GlishSysEvent &event, void *);
Bool write_event(GlishSysEvent &event, void *);
Bool close_event(GlishSysEvent &event, void *);


// Global variables.
String gClientName = "pkswriter";

// Parameters.
String gOutName;			// Output name.
Vector<Bool> gBeams(13);		// Mask of beams present in MB record.
Vector<Bool> gIFs(16);			// Mask of IFs   present in MB record.
uInt gNChan;				// Number of channels in each IF.
uInt gNPol;				// Number of polarizations in each IF.
Bool gHaveXPol;				// Cross-polarization data present?

// Global variables.
Bool   gBeamSw;				// Beam switching observation mode.
Bool   gHaveBase;			// Baseline parameters present.
uInt   gNBeam;				// Number of beams in MB record.
uInt   gNRec;				// Number of records written.
uInt   gNRow;				// Number of rows written.
PKSwriter *gWriter;			// Parkes single-dish writer.
Vector<Int> gBeamNos;			// Beam number bookkeeping

//----------------------------------------------------------------------- main

int main(int argc, char **argv)
{
  try {
    // Set up the Glish event stream.
    GlishSysEventSource glishStream(argc, argv);
    glishStream.addTarget(init_event, "init");
    glishStream.addTarget(write_event, "write");
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
  String version = "$Revision: 19.17 $";
  String date = "$Date: 2006/07/13 07:57:04 $";

  logMessage("pkswriter (v" + String(version.after(' ')).before(' ') +
             ", " + String(date.after(' ')).before(' ') + ") initializing.");

  GlishSysEventSource *glishBus = event.glishSource();
  GlishValue glishVal = event.val();

  // Check that argument is a record.
  if (glishVal.type() != GlishValue::RECORD) {
    glishBus->postEvent("init_error", "Client initialization failed");
    logError("Argument to \"init\" should be a record.");
    return True;
  }

  // Extract parameters from the glish record.
  String directory, file, format;
  GlishRecord parms = glishVal;
  getParm(parms, "format", String("SDFITS"), format);

  if (format == "MS2") {
    logWarning("WARNING: MS2 format output is no longer supported.");
  } else if (format != "SDFITS") {
    logWarning("WARNING: " + format + " format output is not supported.");
  }

  format = "SDFITS";
  file = "pksmb.sdfits";

  Int nChan, nPol;
  getParm(parms, "directory", String("."), directory);
  getParm(parms, "file",      file,        file);
  getParm(parms, "beams",     False,       gBeams);
  getParm(parms, "IFs",       False,       gIFs);
  getParm(parms, "nchans",       0,        nChan);
  getParm(parms, "npols",        0,        nPol);
  getParm(parms, "xpol",      False,       gHaveXPol);

  if (directory == "") directory = ".";
  gOutName = directory + "/" + file;

  // Beam number bookkeeping.
  gNBeam = ntrue(gBeams);
  gBeamNos.resize(gNBeam);
  uInt jbeam = 0;
  for (uInt ibeam = 0; ibeam < gBeams.nelements(); ibeam++) {
    if (gBeams(ibeam)) {
      gBeamNos(jbeam++) = ibeam + 1;
    }
  }

  gNChan = nChan;
  gNPol  = nPol;

  gNRec = 0;
  gNRow = 0;

  logMessage("Writing " + format + " format to " + gOutName);

  // Create the writer.
  gWriter = new PKSSDwriter();

  glishBus->postEvent("initialized", "pkswriter initialized");

  return True;
}

//---------------------------------------------------------------- write_event

// Handler for "write" event; write out incoming Glish records.

Bool write_event(GlishSysEvent &event, void *)
{
  GlishSysEventSource *glishBus = event.glishSource();
  GlishValue glishVal = event.val();

  // Check that argument is a record.
  if (glishVal.type() != GlishValue::RECORD) {
    glishBus->postEvent("write_error", "pkswriter failed");
    logError("Argument to \"write\" must be a multibeam Glish Record.");
    return True;
  }

  GlishRecord aggRec = glishVal, beamRec, intRec;
  GlishArray glishArr;

  uInt iRec, nRec = aggRec.nelements();
  for (iRec = 0; iRec < nRec; iRec++) {
    intRec = aggRec.get(iRec);

    if (gNRec == 0) {
      // Get header records from the first beam in the record.
      beamRec = intRec.get(0);

      glishArr = beamRec.get("OBSERVER");
      String observer;
      glishArr.get(observer);

      glishArr = beamRec.get("PROJECT");
      String project;
      glishArr.get(project);

      glishArr = beamRec.get("ANTENNA_NAME");
      String antName;
      glishArr.get(antName);

      glishArr = beamRec.get("ANTENNA_POSITION");
      Vector<Double> antPosition(3);
      glishArr.get(antPosition);

      glishArr = beamRec.get("OBSTYPE");
      String obsType;
      glishArr.get(obsType);

      glishArr = beamRec.get("EQUINOX");
      Float equinox;
      glishArr.get(equinox);

      glishArr = beamRec.get("DOPPLER_FRAME");
      String dopplerFrame;
      glishArr.get(dopplerFrame);

      // Find the maximum IF number.
      uInt maxIFno = gIFs.nelements();
      while (maxIFno > 0 && !gIFs(maxIFno-1)) {
        maxIFno--;
      }

      Vector<uInt> nChan(maxIFno, gNChan);
      Vector<uInt> nPol(maxIFno, gNPol);

      gHaveBase = beamRec.exists("BASELIN");
      Vector<Bool> haveXPol(maxIFno, gHaveXPol);

      // Create the output file and and write static data.
      gWriter->create(gOutName, observer, project, antName, antPosition,
                      obsType, equinox, dopplerFrame, nChan, nPol, haveXPol,
                      gHaveBase);

      // Check for beam-switching.
      gBeamSw = obsType.contains("MX");

      if (gBeamSw) {
        logMessage("Beam switching mode, will write only the signal beam.");
      }

    }


    // Extract beam-invariant data.
    GlishRecord recordHeader = intRec.get(0);

    glishArr = recordHeader.get("SCAN_NO");
    Int scanNo;
    glishArr.get(scanNo);

    glishArr = recordHeader.get("CYCLE_NO");
    Int cycleNo;
    glishArr.get(cycleNo);
    
    if (intRec.nelements() != gNBeam) {
      ostringstream buf;
      buf << "Scan " << scanNo
          << " integration cycle " << cycleNo
          << " contained " << intRec.nelements()
          << " beams instead of " << gNBeam << ".";
      logError(buf);
    }

    glishArr = recordHeader.get("TIME");
    Double mjd;
    glishArr.get(mjd);
    mjd /= 86400.0;

    glishArr = recordHeader.get("INTERVAL");
    Double interval;
    glishArr.get(interval);

    glishArr = recordHeader.get("FIELD_NAME");
    String fieldName;
    glishArr.get(fieldName);

    glishArr = recordHeader.get("SOURCE_NAME");
    String srcName;
    glishArr.get(srcName);

    glishArr = recordHeader.get("REFERENCE_DIR");
    Vector<Double> srcDir(2);
    glishArr.get(srcDir);

    glishArr = recordHeader.get("PROPER_MOTION");
    Vector<Double> srcPM(2);
    glishArr.get(srcPM);

    glishArr = recordHeader.get("SOURCE_SYSVEL");
    Double srcVel;
    glishArr.get(srcVel);

    glishArr = recordHeader.get("OBSTYPE");
    String obsType;
    glishArr.get(obsType);

    glishArr = recordHeader.get("IFNO");
    Int IFno;
    glishArr.get(IFno);

    glishArr = recordHeader.get("REST_FREQUENCY");
    Double restFreq;
    glishArr.get(restFreq);

    Int refBeam = 0;
    if (gBeamSw) {
      // 1-relative reference beam number.
      glishArr = recordHeader.get("REFBEAM");
      glishArr.get(refBeam);
    }

    glishArr = recordHeader.get("TCAL");
    Vector<Float> tcal;
    glishArr.get(tcal);

    glishArr = recordHeader.get("TCALTIME");
    String tcalTime;
    glishArr.get(tcalTime);

    glishArr = recordHeader.get("FOCUSAXI");
    Float focusAxi;
    glishArr.get(focusAxi);

    glishArr = recordHeader.get("FOCUSTAN");
    Float focusTan;
    glishArr.get(focusTan);

    glishArr = recordHeader.get("FOCUSROT");
    Float focusRot;
    glishArr.get(focusRot);

    glishArr = recordHeader.get("TEMPERATURE");
    Float temperature;
    glishArr.get(temperature);

    glishArr = recordHeader.get("PRESSURE");
    Float pressure;
    glishArr.get(pressure);

    glishArr = recordHeader.get("REL_HUMIDITY");
    Float humidity;
    glishArr.get(humidity);

    glishArr = recordHeader.get("WINDSPEED");
    Float windSpeed;
    glishArr.get(windSpeed);

    glishArr = recordHeader.get("WINDAZ");
    Float windAz;
    glishArr.get(windAz);


    // Write out each beam.
    char beamLabel[7];
    for (uInt ibeam = 0; ibeam < gNBeam; ibeam++) {
      // Don't make any assumptions about the ordering of beam records.
      Int beamNo = gBeamNos(ibeam);
      sprintf(beamLabel, "beam%02d", beamNo);

      if (!intRec.exists(beamLabel)) {
        ostringstream buf;
        buf << "Beam " << beamNo << " was absent from scan " << scanNo
            << " integration cycle " << cycleNo << ".";
        logError(buf);
        continue;
      }

      // Extract data from the Glish record.
      GlishRecord beamRec = intRec.get(beamLabel);

      // 1-relative beam number.
      glishArr = beamRec.get("BEAM");
      glishArr.get(beamNo);

      if (gBeamSw) {
        if (beamNo != refBeam) {
          continue;
        }
      }

      glishArr = beamRec.get("POINTING_DIR");
      Vector<Double> direction(2);
      glishArr.get(direction);

      glishArr = beamRec.get("PHASE_DIR_RATE");
      Vector<Double> scanRate(2);
      glishArr.get(scanRate);

      glishArr = beamRec.get("REF_FREQUENCY");
      Double refFreq;
      glishArr.get(refFreq);

      glishArr = beamRec.get("TOTAL_BANDWIDTH");
      Double bandwidth;
      glishArr.get(bandwidth);

      glishArr = beamRec.get("RESOLUTION");
      Double freqInc;
      glishArr.get(freqInc);

      glishArr = beamRec.get("AZIMUTH");
      Float azimuth;
      glishArr.get(azimuth);

      glishArr = beamRec.get("ELEVATION");
      Float elevation;
      glishArr.get(elevation);

      glishArr = beamRec.get("PARANGLE");
      Float parAngle;
      glishArr.get(parAngle);

      glishArr = beamRec.get("TSYS");
      Vector<Float> tsys(glishArr.shape());
      glishArr.get(tsys);

      glishArr = beamRec.get("SIGMA");
      Vector<Float> sigma(glishArr.shape());
      glishArr.get(sigma);

      glishArr = beamRec.get("CALFCTR");
      Vector<Float> calFctr(glishArr.shape());
      glishArr.get(calFctr);

      Matrix<Float> baseLin, baseSub;
      if (gHaveBase) {
        glishArr = beamRec.get("BASELIN");
        baseLin.resize(glishArr.shape());
        glishArr.get(baseLin);

        glishArr = beamRec.get("BASESUB");
        baseSub.resize(glishArr.shape());
        glishArr.get(baseSub);
      }

      // Spectral data.
      glishArr = beamRec.get("FLOAT_DATA");
      Matrix<Float> spectra(glishArr.shape());
      glishArr.get(spectra);

      // Channel flagging.
      glishArr = beamRec.get("FLAGGED");
      Matrix<uChar> flagtra(spectra.shape());
      if (glishArr.shape() == spectra.shape()) {
        glishArr.get(flagtra);
      } else {
        // Uncompress the flagging matrix.
        Matrix<uChar> flagtmp(glishArr.shape());
        glishArr.get(flagtmp);
        uInt nPol = spectra.shape()(1);
        for (uInt iPol = 0; iPol < nPol; iPol++) {
          flagtra.column(iPol) = flagtmp(0,iPol);
        }
      }

      Complex xCalFctr;
      Vector<Complex> xPol;
      if (gHaveXPol) {
        glishArr = beamRec.get("XCALFCTR");
        glishArr.get(xCalFctr);

        glishArr = beamRec.get("DATA");
        xPol.resize(glishArr.shape());
        glishArr.get(xPol);
      }

      // Write the next data record.
      gWriter->write(scanNo, cycleNo, mjd, interval, fieldName, srcName,
                     srcDir, srcPM, srcVel, obsType, IFno, refFreq, bandwidth,
                     freqInc, restFreq, tcal, tcalTime, azimuth, elevation,
                     parAngle, focusAxi, focusTan, focusRot, temperature,
                     pressure, humidity, windSpeed, windAz, refBeam, beamNo,
                     direction, scanRate, tsys, sigma, calFctr, baseLin,
                     baseSub, spectra, flagtra, xCalFctr, xPol);
      gNRow++;
    }

    gNRec++;
  }

  glishBus->postEvent("write_complete", GlishArray(Int(iRec)));
  return True;
}

//---------------------------------------------------------------- close_event

// Handler for "close" event.

Bool close_event(GlishSysEvent &event, void *)
{
  GlishSysEventSource *glishBus = event.glishSource();

  gWriter->close();
  delete gWriter;

  Int nIF = ntrue(gIFs);
  char text[120];
  sprintf(text, "File closed, %d complete integration cycles written in %d "
                "table rows.", gNRec/nIF, gNRow);
  logMessage(text);
  glishBus->postEvent("closed", "output file closed");

  return True;
}
