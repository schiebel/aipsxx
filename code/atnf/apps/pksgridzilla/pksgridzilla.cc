//#---------------------------------------------------------------------------
//# pksgridzilla.cc: Gridder for single-dish spectral data.
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
//# WITHOUT ANY WARRANTY; without even the implied warranty of
//# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
//# Public License for more details.
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
//#---------------------------------------------------------------------------
//# Gridder for single-dish spectral data.
//#
//# $Id: pksgridzilla.cc,v 19.40 2006/07/28 07:11:47 mcalabre Exp $
//#---------------------------------------------------------------------------

// AIPS++ includes.
#include <casa/sstream.h>
#include <casa/stdio.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Slice.h>
#include <casa/BasicMath/Math.h>
#include <casa/BasicSL/Constants.h>
#include <casa/BasicSL/String.h>
#include <casa/Exceptions/Error.h>
#include <casa/Quanta/QC.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishEvent.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>

#include <wcslib/sph.h>
#include <wcslib/spc.h>

// Parkes includes.
#include <atnf/pks/pksmb_support.h>
#include <atnf/pks/pks_maths.h>
#include <atnf/PKSIO/PKSreader.h>

#include <MBGridder.h>

#include <casa/namespace.h>

// Glish event handlers.
Bool init_event(GlishSysEvent &event, void *);
Bool go_event(GlishSysEvent &event, void *);

// Client worker functions.
void parseSources(const GlishRecord &sources);
Bool scanInput(Vector<String> &, Vector<Int> &, String &, Double &, Int &,
        Int &, Int &, Int &, Matrix<Float> &, Vector<Bool> &);
void shutDown(GlishSysEventSource *glishBus);


// Client parameters.
Vector<Bool> gBeamSel;
String gRangeSpec;
Double gStartFreq;
Double gEndFreq;
Double gRestFreq;
Vector<Bool> gIFsel;
String gPolOp;
Bool   gDoCont;
Bool   gDoBase;
Bool   gDoLine;
Vector<String> gDirectories;
Vector<String> gFiles;
String gProjection;
Vector<Double> gPV;
String gCoordSys;
Bool   gRefPoint;
Double gRefLng;
Double gRefLat;
Double gLonpole;
Double gLatpole;
Bool   gAutoSize;
Bool   gIntRefPix;
Double gCentreLng;
Double gCentreLat;
Int    gImageWidth;
Int    gImageHeight;
Float  gPixelWidth;
Float  gPixelHeight;
Float  gTsysMin, gTsysMax;
Float  gDataMin, gDataMax;
Float  gChanErr;
Vector<String> gStatistic;
Float  gClipFraction;
Bool   gTsysWeight;
Int    gBeamWeight;
Float  gBeamFWHM;
Bool   gBeamNormal;
String gKernelType;
Float  gKernelFWHM;
Float  gCutoffRadius;
Float  gBlankLevel;
Int    gStorage;			// Max storage to use in MiB.
String gSpecType;
Bool   gShortInt;
String gFITSfilename;
String gCounts;
SourceParm gSources;

// Constants.
const Double R2D = 180.0 / C::pi;

// Global variables.
String gClientName = "pksgridzilla";

//----------------------------------------------------------------------- main

int main(int argc, char **argv) {
  // Set up the Glish event stream.
  GlishSysEventSource glishStream(argc, argv);
  glishStream.addTarget(init_event, "init");
  glishStream.addTarget(go_event, "go");

  try {
    pksmbSetup(glishStream, gClientName);

  } catch (AipsError x) {
    cout << x.getMesg() << endl;
    shutDown(&glishStream);
  }

  return 0;
}

//----------------------------------------------------------------- init_event

// Handler for "init" event.

Bool init_event(GlishSysEvent &event, void *) {
  logMessage("");
  String version = "$Revision: 19.40 $";
  String date = "$Date: 2006/07/28 07:11:47 $";

  logMessage("=================== pksgridzilla (v" +
             String(version.after(' ')).before(' ') + ", " +
             String(date.after(' ')).before(' ') +
             ") arises! ===================");

  GlishSysEventSource *glishBus = event.glishSource();
  GlishValue glishVal = event.val();

  // Check that argument is a record.
  if (glishVal.type() != GlishValue::RECORD) {
    if (glishBus->replyPending()) {
      glishBus->reply(GlishArray(False));
    }
    logMessage("WARNING: Argument to \"init\" should be a record.");
    return True;
  }

  // Extract useful parameters.
  GlishRecord parms = glishVal;

  gBeamSel.resize(13);
  getParm(parms, "beamsel", True, gBeamSel);

  getParm(parms, "rangeSpec", String("FREQUENCY"), gRangeSpec);
  gRangeSpec.upcase();

  getParm(parms, "restFreq", 1420.40575, gRestFreq);
  gRestFreq *= 1.0e6;

  Double startSpec;
  if (getParm(parms, "startSpec", 0.0, startSpec)) {
    if (gRangeSpec == "FREQUENCY") {
       // Frequency given in MHz.
       gStartFreq = startSpec*1.0e6;

    } else if (gRangeSpec == "VELOCITY") {
       // Convert radio velocity in km/s to frequency.
       gStartFreq = gRestFreq * (1.0 - 1000.0*startSpec/C::c);
    }

  } else {
    gStartFreq = 0.0;
  }

  Double endSpec;
  if (getParm(parms, "endSpec", 200000.0, endSpec)) {
    if (gRangeSpec == "FREQUENCY") {
       // Frequency given in MHz.
       gEndFreq = endSpec*1.0e6;

    } else if (gRangeSpec == "VELOCITY") {
       // Convert radio velocity in km/s to frequency.
       gEndFreq = gRestFreq * (1.0 - 1000.0*endSpec/C::c);
    }

  } else {
    gEndFreq = 999999.0;
  }

  gIFsel.resize(16);
  getParm(parms, "IFsel", True, gIFsel);

  getParm(parms, "pol_op", String("A&B"), gPolOp);
  gPolOp.upcase();

  getParm(parms, "spectral",   True, gDoLine);
  getParm(parms, "continuum",  True, gDoCont);
  getParm(parms, "baseline",  False, gDoBase);

  gDirectories.resize(1);
  getParm(parms, "directories", String("."), gDirectories);

  gFiles.resize(0);
  getParm(parms, "files", String(""), gFiles);

  getParm(parms, "projection", String("SIN"), gProjection);
  gProjection.upcase();

  gPV.resize(20);
  getParm(parms, "pv", 0.0, gPV);
  getParm(parms, "coordSys",  String("EQUATORIAL"), gCoordSys);
  getParm(parms, "refpoint",      False, gRefPoint);
  getParm(parms, "reference_lng",   0.0, gRefLng);
  getParm(parms, "reference_lat", -90.0, gRefLat);
  getParm(parms, "lonpole",       999.0, gLonpole);
  getParm(parms, "latpole",       999.0, gLatpole);

  getParm(parms, "autosize",      False, gAutoSize);
  getParm(parms, "intrefpix",      True, gIntRefPix);
  getParm(parms, "centre_lng",      0.0, gCentreLng);
  getParm(parms, "centre_lat",    -90.0, gCentreLat);
  getParm(parms, "pixel_width",    4.0f, gPixelWidth);
  getParm(parms, "pixel_height",   4.0f, gPixelHeight);
  getParm(parms, "image_width",     170, gImageWidth);
  getParm(parms, "image_height",    160, gImageHeight);

  getParm(parms, "tsysmin",     25.0f, gTsysMin);
  getParm(parms, "tsysmax",  10000.0f, gTsysMax);
  getParm(parms, "datamin", -10000.0f, gDataMin);
  getParm(parms, "datamax",  10000.0f, gDataMax);
  getParm(parms, "chan_err",     0.1f, gChanErr);

  getParm(parms, "statistic",     String("WGTMED"), gStatistic);
  getParm(parms, "clip_fraction",             0.0f, gClipFraction);
  getParm(parms, "tsys_weight",              False, gTsysWeight);
  getParm(parms, "beam_weight",                  1, gBeamWeight);
  getParm(parms, "beam_FWHM",                14.4f, gBeamFWHM);
  getParm(parms, "beam_normal",               True, gBeamNormal);
  getParm(parms, "kernel_type",  String("TOP-HAT"), gKernelType);
  gKernelType.upcase();

  getParm(parms, "kernel_FWHM",   12.0f, gKernelFWHM);
  getParm(parms, "cutoff_radius",  6.0f, gCutoffRadius);
  getParm(parms, "blank_level",    0.0f, gBlankLevel);
  getParm(parms, "storage",          25, gStorage);

  getParm(parms, "short_int",          False, gShortInt);
  getParm(parms, "spectype",  String("FREQ"), gSpecType);
  getParm(parms, "p_FITSfilename", String("gridzilla"), gFITSfilename);
  logMessage("Output FITS file name: " + gFITSfilename + ".fits");

  getParm(parms, "counts",    String("spectra"), gCounts);
  gCounts.downcase();

  if (parms.exists("sources")) {
    GlishRecord sources = parms.get("sources");
    parseSources(sources);
  }

  if (glishBus->replyPending()) {
    glishBus->reply(GlishArray(True));
  }

  return True;
}

//--------------------------------------------------------------- parseSources

// Parse a GlishRecord containing simulation source parameters.

void parseSources(const GlishRecord &sources)
{
  uInt nSrc = sources.nelements();
  gSources.nSrc = nSrc;
  gSources.dLng.resize(nSrc);
  gSources.dLat.resize(nSrc);
  gSources.flux.resize(nSrc);
  gSources.width.resize(nSrc);
  gSources.startChan.resize(nSrc);
  gSources.endChan.resize(nSrc);

  // Extract each source.
  char srcName[10];
  uInt idx = 0;
  for (uInt iSrc = 1; iSrc <= nSrc; iSrc++) {
    sprintf(srcName, "source%03d", iSrc);

    if (sources.exists(srcName)) {
      GlishRecord thissrc = sources.get(srcName);

      // Check validity.
      if (thissrc.exists("ra") && thissrc.exists("dec") &&
          thissrc.exists("flux") && thissrc.exists("width") &&
          thissrc.exists("start_channel") &&
          thissrc.exists("end_channel")) {

        // Extract parameters from the Glish record.
        GlishArray tmp;

        tmp = thissrc.get("ra");
        tmp.get(gSources.dLng(idx));

        tmp = thissrc.get("dec");
        tmp.get(gSources.dLat(idx));

        tmp = thissrc.get("flux");
        tmp.get(gSources.flux(idx));

        tmp = thissrc.get("width");
        tmp.get(gSources.width(idx));

        tmp = thissrc.get("start_channel");
        tmp.get(gSources.startChan(idx));

        tmp = thissrc.get("end_channel");
        tmp.get(gSources.endChan(idx));
        idx++;
      }
    }
  }

  gSources.nSrc = idx;
}

//------------------------------------------------------------------- go_event

// Handler for "go" event.

Bool go_event(
        GlishSysEvent &event, void *)
{
  GlishSysEventSource *glishBus = event.glishSource();
  GlishValue glishVal = event.val();

  Int    chanPerPass, nOutChans, nPass, specCount;
  Double freqStep;
  String dopplerFrame;
  Vector<Int>    nSel;
  Vector<Bool>   nightFlag;
  Vector<String> fileNames;
  Matrix<Float>  celCrd;
  ostringstream  buffer;

  logMessage("Determining dataset sizes...");
  if (!scanInput(fileNames, nSel, dopplerFrame, freqStep, specCount,
                 nOutChans, nPass, chanPerPass, celCrd, nightFlag)) {
    shutDown(glishBus);
    return False;
  }

  MBGridder gridder(gPolOp,
                    fileNames,
                    gProjection,
                    gPV,
                    gCoordSys,
                    gRefPoint,
                    gRefLng,  gRefLat,
                    gLonpole, gLatpole,
                    gAutoSize,
                    gIntRefPix,
                    gCentreLng,  gCentreLat,
                    gImageWidth, gImageHeight,
                    gPixelWidth, gPixelHeight,
                    gBeamFWHM,
                    gCutoffRadius,
                    gFITSfilename,
                    specCount,
                    celCrd,
                    nightFlag,
                    gCounts);

  Int firstOutChan, lastOutChan, nOutChan;
  Double firstOutFreq, lastOutFreq;

  // Set reference frequency at midpoint.
  Double refFreq = gStartFreq + freqStep*(nOutChans/2);


  // Tsys and spectral data arrays.
  Matrix<Float> tsysData;
  Cube<Float> specData;
  Cube<Float> contData;
  Cube<Float> baseData;

  // Polarization modes.
  Bool doA = (gPolOp == "A");
  Bool doB = (gPolOp == "B");
  Bool doAandB = (gPolOp == "A&B");
  Int  polSign = (gPolOp == "A+B") ? 1 : -1;

  Int nPol = 1;
  if (doAandB) nPol = 2;

  Float memory = 0.0;
  if (gTsysWeight) memory += 1;
  if (gDoCont) memory += 2;
  if (gDoBase) memory += 9;
  if (gDoLine) memory += chanPerPass;
  memory *= 4.0f * Float(nPol * specCount) / Float(1024 * 1024);
  logMessage("Allocating ", Int(memory), " MiB of memory...");

  if (gTsysWeight) tsysData.resize(nPol, specCount);
  if (gDoCont) contData.resize(nPol, specCount, 2);
  if (gDoBase) baseData.resize(nPol, specCount, 9);
  if (gDoLine) specData.resize(nPol, specCount, chanPerPass);
  logMessage("...successful.");

  buffer.str("");
  buffer << "Valid Tsys range: " << gTsysMin << " < Tsys < " << gTsysMax;
  logMessage(buffer);

  if (gDoLine) {
    buffer.str("");
    buffer << "Valid data range: " << gDataMin << " < data < " << gDataMax;
    logMessage(buffer);
  }

  logMessage("");

  for (uInt iPass = 0; iPass < uInt(nPass); iPass++) {
    // Determine the 0-relative channel range for this pass.
    firstOutChan = iPass * chanPerPass;
    lastOutChan  = min(firstOutChan + chanPerPass - 1, nOutChans - 1);
    nOutChan = lastOutChan - firstOutChan + 1;

    firstOutFreq = gStartFreq + firstOutChan * freqStep;
    lastOutFreq  = gStartFreq +  lastOutChan * freqStep;

    if (gDoLine) {
      buffer.str("");
      buffer << "------------------- Starting pass " << iPass + 1 << " of "
             << nPass << " -------------------";
      logMessage(buffer);

      buffer.str("");
      buffer << "Reading data for output channels " << firstOutChan + 1
             << " to " << lastOutChan + 1 << "...";
      logMessage(buffer);
    }

    // Read the data.
    uInt nFiles = fileNames.nelements();
    Bool gotNaN = False;
    Int  iSpec  = 0;
    Int  contCount = 0;
    Int  baseCount = 0;
    PKSreader *reader = 0;
    for (uInt ifile = 0; ifile < nFiles; ifile++) {
      if (!nSel(ifile)) {
        continue;
      }

      // Get an appropriate reader for this dataset.
      Bool   haveBase, haveSpectra;
      String format;
      Vector<Bool> beams, haveXPol, IFs;
      Vector<uInt> nChan, nPol;
      if (reader) delete reader;
      if ((reader = getPKSreader(fileNames(ifile), 0, 1, format, beams, IFs,
                                 nChan, nPol, haveXPol, haveBase,
                                 haveSpectra)) == 0) {
        logError("ERROR: FAILED TO OPEN " + fileNames(ifile));
        continue;
      }

      // Get spectral parameters for each IF.
      Vector<Double> startFreq, endFreq;
      reader->getFreqInfo(startFreq, endFreq);

      uInt nIF = IFs.nelements();
      Vector<Int> firstInChan(nIF), lastInChan(nIF);
      if (gDoLine) {
        // Determine the required channel ranges for each IF.
        Vector<Int>  endChan(nIF), refChan, startChan(nIF);

        Vector<Bool> IFsel(nIF, False);
        for (uInt iIF = 0; iIF < min(nIF, gIFsel.nelements()); iIF++) {
          IFsel(iIF) = gIFsel(iIF);

          // Determine 0-relative channel range for this spectral id.
          Int nInChan = nChan(iIF);
          if (nInChan == 1) {
            firstInChan(iIF) = 0;
            lastInChan(iIF)  = 0;
          } else if (nInChan > 1) {
            Double dFreq = (endFreq(iIF) - startFreq(iIF)) / (nInChan - 1);
            firstInChan(iIF) = nint((firstOutFreq-startFreq(iIF))/dFreq);
            lastInChan(iIF)  = nint(( lastOutFreq-startFreq(iIF))/dFreq);
          } else {
            IFsel(iIF) = False;
            continue;
          }

          // Determine 1-relative channel selection.
          startChan(iIF) = firstInChan(iIF) + 1;
          if (startChan(iIF) < 1) {
            startChan(iIF) = 1;
          } else if (startChan(iIF) > nInChan) {
            startChan(iIF) = nInChan;
          }

          endChan(iIF) = lastInChan(iIF) + 1;
          if (endChan(iIF) < 1) {
            endChan(iIF) = 1;
          } else if (endChan(iIF) > nInChan) {
            endChan(iIF) = nInChan;
          }
        }

        // Apply data selection criteria.
        reader->select(gBeamSel, IFsel, startChan, endChan, refChan, True);

      } else if (gDoCont || gDoBase) {
        // Apply beam and IF selection.
        Vector<Int> endChan, refChan, startChan;

        Vector<Bool> IFsel(nIF, False);
        for (uInt iIF = 0; iIF < min(nIF, gIFsel.nelements()); iIF++) {
          IFsel(iIF) = gIFsel(iIF);
        }

        reader->select(gBeamSel, IFsel, startChan, endChan, refChan, False);
      }

      // Compute scaling parameters.
      Vector<Float> fscale(nIF);
      Matrix<Float> bscale(9,nIF);
      if (gDoCont && iPass == 0) {
        Float dFreq, rFreq;
        for (uInt iIF = 0; iIF < nIF; iIF++) {
          dFreq = (endFreq(iIF) - startFreq(iIF)) / (nChan(iIF) - 1);
          rFreq = startFreq(iIF) + dFreq*(nChan(iIF)/2);

          // Frequency scaling for calculation of spectral index.
          fscale(iIF) = rFreq/dFreq;

          // Baseline polynomial coefficient scaling parameters.
          Float scl = 1e6f / dFreq;
          bscale(0,iIF) = 1.0f;
          for (uInt j = 1; j < 9; j++) {
            bscale(j,iIF) = scl * bscale(j-1,iIF);
          }
        }
      }


      Vector<Float> tsys;
      Int nBadTsys[]  = {0, 0};
      Int nFlagTsys[] = {0, 0};

      Vector<Float> calFctr;
      Matrix<Float> baseLin, baseSub;
      Matrix<Float> spectra;
      Int nBadSpec[] = {0, 0};

      Matrix<uChar> flagtra;
      Int nFlagSpec = 0;
      Int nFlagChan = 0;

      // Read through the dataset.
      Int IFno, status;
      while ((status = reader->read(IFno, tsys, calFctr, baseLin, baseSub,
                                    spectra, flagtra)) == 0) {
        Bool useCont = True;
        Bool useBase = True;

        for (uInt ipol = 0; ipol < tsys.nelements(); ipol++) {
          if ((ipol == 0 && doB) || (ipol == 1 && doA)) {
            continue;
          }

          uInt jpol = 0;
          if (doAandB) jpol = ipol;
          Bool copyPol = (jpol == ipol || doB);

          // Check for bad or flagged Tsys values.
          Float tsysi = tsys(ipol);
          if (tsysi <= gTsysMin || gTsysMax <= tsysi || isNaN(tsysi)) {
            if (tsysi == gTsysMin && gTsysMin == 25.0f) {
              nFlagTsys[ipol]++;
            } else {
              nBadTsys[ipol]++;
            }

            if (gTsysWeight) tsysData(jpol,iSpec) = floatNaN();
            if (gDoCont) contData(jpol,iSpec,Slice()) = floatNaN();
            if (gDoBase) baseData(jpol,iSpec,Slice()) = floatNaN();
            if (gDoLine) specData(jpol,iSpec,Slice()) = floatNaN();

            if (doAandB) {
              // The other polarization may be useful.
              continue;
            } else {
              // This spectrum is a write-off.
              break;
            }
          }

          Int iIF = IFno - 1;

          if (gTsysWeight) {
            if (copyPol) {
              tsysData(jpol,iSpec) = tsysi;
            } else {
              tsysData(0,iSpec) = max(tsysData(0,iSpec), tsysi);
            }
          }

          if (iPass == 0) {
            if (gDoCont && useCont) {
              if (baseLin.nelements()) {
                contCount++;
                Float baseLin0 = baseLin(0,ipol);

                if (copyPol) {
                  contData(jpol,iSpec,0) = baseLin0;
                  contData(jpol,iSpec,1) = fscale(iIF) * baseLin(1,ipol) /
                                               baseLin0;
                } else {
                  contData(0,iSpec,0) += polSign * baseLin0;
                  contData(0,iSpec,1) += polSign * baseLin(1,ipol) *
                                         fscale(iIF) / baseLin0;

                  contData(0,iSpec,0) /= 2.0f;
                  contData(0,iSpec,1) /= 2.0f;
                }

              } else {
                contData(jpol,iSpec,Slice()) = floatNaN();
                useCont = doAandB;
              }
            }

            if (gDoBase && useBase) {
              if (baseSub.nelements()) {
                baseCount++;
                Float baseLin0 = baseLin(0,ipol);

                if (copyPol) {
                  baseData(jpol,iSpec,0) = baseLin0;
                  baseData(jpol,iSpec,1) = baseLin(1,ipol) * bscale(1,iIF) /
                                             baseLin0;

                  for (uInt j = 2; j < 9; j++) {
                    baseData(jpol,iSpec,j) = baseSub(j,ipol) * bscale(j,iIF) /
                                               baseLin0;
                  }

                } else {
                  baseData(0,iSpec,0) += polSign * baseLin0;
                  baseData(0,iSpec,1) += polSign * baseLin(1,ipol) *
                                           bscale(1,iIF) / baseLin0;
                  baseData(0,iSpec,0) /= 2.0f;
                  baseData(0,iSpec,1) /= 2.0f;

                  for (uInt j = 2; j < 9; j++) {
                    baseData(0,iSpec,j) += polSign * baseSub(j,ipol) *
                                             bscale(j,iIF) / baseLin0;
                    baseData(0,iSpec,j) /= 2.0f;
                  }
                }

              } else {
                baseData(jpol,iSpec,Slice()) = floatNaN();
                useBase = doAandB;
              }
            }
          }

          if (gDoLine) {
            Int selChan = 0;
            Int nInChan = nChan(iIF);
            Int inChan  = firstInChan(iIF);
            Int inChanInc = (inChan < lastInChan(iIF)) ? 1 : -1;

            Int iFlagChan = 0;
            for (Int outChan = 0; outChan < nOutChan; outChan++) {
              Float flux;
              if (inChan < 0 || inChan >= nInChan) {
                // Set the flux to a quiet NaN value to have it ignored.
                flux = floatNaN();

              } else {
                if (flagtra(selChan, ipol)) {
                  // Ignore flagged channels.
                  flux = floatNaN();
                  iFlagChan++;

                } else {
                  flux = spectra(selChan, ipol);
                  if (isNaN(flux)) {
                    // This NaN shouldn't be here.
                    nBadSpec[ipol]++;
                  } else if (flux <= gDataMin || gDataMax <= flux) {
                    // Discard data outside the valid range.
                    flux = floatNaN();
                    iFlagChan++;
                  }
                }
                selChan++;
              }

              if (copyPol) {
                specData(jpol,iSpec,outChan) = flux;

              } else {
                if (isNaN(specData(0,iSpec,outChan)) || isNaN(flux)) {
                  // Ignore this spectrum.
                  specData(0,iSpec,outChan) = floatNaN();

                } else {
                  specData(0,iSpec,outChan) += polSign * flux;
                  specData(0,iSpec,outChan) /= 2.0f;
                }
              }

              inChan += inChanInc;
            }

            if (iFlagChan) {
              nFlagSpec++;
              nFlagChan += iFlagChan;
            }
          }
        }  // Pol loop.

        iSpec++;
      } // Read loop.

      if (nBadTsys[0] || nBadTsys[1]) {
        buffer.str("");
        buffer << "WARNING: Ignored spectra with bad Tsys (A:"
               << nBadTsys[0] << ",B:" << nBadTsys[1]
               << ") in " << fileNames(ifile);
        logWarning(buffer);
      }

      if (nBadSpec[0] || nBadSpec[1]) {
        buffer.str("");
        buffer << "ERROR: FOUND SPECTRA CONTAINING NaN VALUES (A:"
               << nBadSpec[0] << ",B:" << nBadSpec[1]
               << ") IN " << fileNames(ifile);
        logError(buffer);

        // Signal to abort processing.
        gotNaN = True;
      }

      if (nFlagTsys[0] || nFlagTsys[1]) {
        buffer.str("");
        buffer << "WARNING: Ignored spectra with flagged Tsys (A:"
               << nFlagTsys[0] << ",B:" << nFlagTsys[1]
               << ") in " << fileNames(ifile);
        logWarning(buffer);
      }

      if (nFlagSpec) {
        logMessage(fileNames(ifile) + ", summary of flagged data:");
        buffer.str("");
        buffer << "   " << nFlagSpec
               << " spectra contained flagged channels ("
               << nFlagChan << " channels in total)";
        logMessage(buffer);
      }

      if (status > 0) {
        logWarning("WARNING: Error reading " + fileNames(ifile) +
                   ", continuing.");
        continue;
      }
    }
    if (reader) delete reader;

    // Sanity check.
    if (iSpec != specCount) {
      // MBGridder requires that celCrd match specData, contData & baseData.
      buffer.str("");
      buffer << "ERROR: INCONSISTENT SPECTRA COUNT: specCount = " << specCount
             << " BUT iSpec = " << iSpec << ".";
      logError(buffer);
      logError("INTERNAL ERROR, ABORTING!");
      break;
    }


    if (gDoCont && iPass == 0) {
      if (contCount) {
        nPol = 2;
        if (doA || doB) nPol = 1;

        buffer.str("");
        buffer << "Found continuum baseline data for " << contCount
               << " of " << nPol*specCount << " spectra.";
        logMessage(buffer);
      } else {
        logError("ERROR: NO CONTINUUM BASELINE DATA FOUND.");
        if (!gDoLine && !gDoBase) {
          break;
        }
      }
    }

    if (gDoBase && iPass == 0) {
      if (baseCount) {
        nPol = 2;
        if (doA || doB) nPol = 1;

        buffer.str("");
        buffer << "Found polynomial baseline coefficients for " << baseCount
               << " of " << nPol*specCount << " spectra.";
        logMessage(buffer);
      } else {
        logError("ERROR: NO POLYNOMIAL BASELINE DATA FOUND.");
        if (!gDoLine) {
          break;
        }
      }
    }

    String passCode = "";
    if (nPass > 1) {
      char exten[8];
      sprintf(exten, "_%03d", iPass + 1);
      passCode = String(exten);
    }

    if (gotNaN) {
      logError("ERROR: FOUND NaN VALUES IN SPECTRAL DATA, PLEASE EXAMINE THE "
               "FILES REPORTED ABOVE.");
    }

    Int nStat = gStatistic.nelements();
    for (Int iStat = 0; iStat < nStat; iStat++) {
      gStatistic(iStat).upcase();
      if (nStat > 1) {
        logMessage("");
        logMessage("Doing " + gStatistic(iStat) + " statistic.");
      }

      gridder.setInterp(gStatistic(iStat),
                        gClipFraction,
                        gTsysWeight,
                        gBeamWeight,
                        gBeamNormal,
                        gKernelType,
                        gKernelFWHM,
                        gBlankLevel);

      if (iPass == 0) {
        if (gDoCont) {
          gridder.formCont(contData, tsysData);
        }

        if (gDoBase) {
          gridder.formBase(baseData, tsysData);
        }

        if (!gDoLine) {
          // Finished.
          logMessage("Gridding completed.");
          break;
        }
      }

      if (gDoLine) {
        // Set FITS spectral parameters and add simulation sources.
        Double CRPIX3 = (nOutChans/2 + 1) - firstOutChan;

        Double CDELT3, CRVAL3;
        String CTYPE3  = gSpecType;
        String specSys = dopplerFrame;

        // AIPS convention output?
        Bool doAIPS = False;
        char ctypeS[9];
        if (gSpecType == "VELO-xxx") {
          doAIPS = True;
          CTYPE3 = "VELO";
          strcpy(ctypeS, "VRAD    ");
        } else if (gSpecType == "FELO-xxx") {
          doAIPS = True;
          CTYPE3 = "FELO";
          strcpy(ctypeS, "VOPT-F2W");
        } else {
          sprintf(ctypeS, "%-8s\n", gSpecType.chars());
        }

        if (doAIPS) {
          specSys = " ";

          if (dopplerFrame == "BARYCENT" || dopplerFrame == "HELIOCEN") {
            // AIPS convention confuses barycentric and heliocentric.
            CTYPE3 += "-HEL";
          } else if (dopplerFrame == "LSRK") {
            // AIPS convention does not distinguish between LSRK and LSRD.
            CTYPE3 += "-LSR";
          } else if (dopplerFrame == "TOPOCENT") {
            // In practice -OBS (observer or observatory) has been used to
            // mean topocentric, though AIPS Memo 27 says 'geocentric'.
            CTYPE3 += "-OBS";
          } else {
            // Can't do it - back out.
            CTYPE3 = ctypeS;
            specSys = dopplerFrame;
            logWarning("WARNING: Spectral AIPS convention does not support "
                       "Doppler frame \"" + dopplerFrame + "\";");
            logWarning("         reverting to " + CTYPE3 + ".");
          }
        }

        // Compute the required spectral keyvalues.
        char ptype, xtype;
        int  restreq;
        double dSdX;
        spcxps(ctypeS, refFreq, gRestFreq, 0.0, &ptype, &xtype, &restreq,
               &CRVAL3, &dSdX);
        CDELT3 = freqStep * dSdX;

        gridder.setSpectra(firstOutChan, nOutChan, CRPIX3, CDELT3, CRVAL3,
                           CTYPE3, gRestFreq, specSys, specData, gSources);

        // Grid this lot.
        gridder.formCube(tsysData, gShortInt, passCode);
      }
    }

    if (nPass > 1) {
      buffer.str("");
      buffer << "Pass " << iPass + 1 << " completed.";
      logMessage(buffer);
    }
  }

  shutDown(glishBus);

  return True;
}

//------------------------------------------------------------------ scanInput

// Determine the size of the gridding problem and the number of passes
// required to stay within the memory limits.

Bool scanInput(
        Vector<String> &fileNames,
        Vector<Int>    &nSel,
        String &dopplerFrame,
        Double &freqStep,
        Int    &specCount,
        Int    &nOutChans,
        Int    &nPass,
        Int    &chanPerPass,
        Matrix<Float> &celCrd,
        Vector<Bool>  &nightFlag)
{
  ostringstream buffer;

  uInt nFiles = gFiles.nelements();
  fileNames.resize(nFiles);

  // Number of rows selected in each dataset.
  nSel.resize(nFiles);
  nSel = 0;

  // Dataset ranges.
  Vector<Int> nRow(nFiles);
  Vector<Vector<Double> > timeSpan(nFiles);
  Vector<Matrix<Double> > positions(nFiles);

  // Antenna position for day/night determination.
  Vector<Double> antPos(3);

  // For spectral parameter checking.
  Double freqMin = 0.0;
  Double freqMax = 0.0;
  freqStep = 0.0;

  Double freqPlus  = 0.0;
  Double freqMinus = 0.0;
  Double freqStepMin = 0.0;
  Double freqStepMax = 0.0;

  dopplerFrame = "";

  // The number of rows in the datasets and the number selected.
  Int totalRows = 0;
  Int lineCount = 0;
  specCount = 0;

  PKSreader *reader = 0;
  for (uInt ifile = 0; ifile < nFiles; ifile++) {
    // Construct a PKSreader for this dataset.
    Bool   haveBase, haveSpectra;
    Int    iDir;
    Vector<Bool> beams, haveXPol, IFs;
    Vector<uInt> nChan, nPol;
    String format;
    if (reader) delete reader;
    if ((reader = getPKSreader(gFiles(ifile), gDirectories, 0, 1, iDir,
                               format, beams, IFs, nChan, nPol, haveXPol,
                               haveBase, haveSpectra)) == 0) {
      // The dataset wasn't found.
      fileNames(ifile) = format + ": " + gFiles(ifile);
      logWarning(fileNames(ifile));
      continue;
    }

    uInt nIF = IFs.nelements();
    if (nIF < 1) {
      fileNames(ifile) = gFiles(ifile) +
                         ": SKIPPED, SPECTRAL INFORMATION INVALID";
      logWarning("   " + fileNames(ifile));
      continue;
    }

    // Found the dataset.
    fileNames(ifile) = gDirectories(iDir) + "/" + gFiles(ifile);

    // IF selection.
    Vector<Bool> IFsel(nIF, False);
    for (uInt iIF = 0; iIF < min(nIF, gIFsel.nelements()); iIF++) {
      IFsel(iIF) = gIFsel(iIF);
    }

    // Get spectral parameters for each IF.
    if (gDoLine && haveSpectra) {
      Vector<Double> startFreq, endFreq;
      if (reader->getFreqInfo(startFreq, endFreq)) {
        fileNames(ifile) = gFiles(ifile) +
                           ": SKIPPED, SPECTRAL INFORMATION UNAVAILABLE";
        logWarning("   " + fileNames(ifile));
        continue;
      }

      // Check spectral parameters.
      Bool skipIt = False;
      for (uInt iIF = 0; iIF < nIF; iIF++) {
        if (nChan(iIF) < 1) IFsel(iIF) = False;
        if (!IFsel(iIF)) {
          continue;
        }

        // Check channel spacing.
        Double fqMin = min(startFreq(iIF), endFreq(iIF));
        Double fqMax = max(startFreq(iIF), endFreq(iIF));
        Double fqSpan = fqMax - fqMin;
        Double chSpan = max(1, Int(nChan(iIF))-1);
        Double fqStep = fqSpan / chSpan;

        Double fqPlus    = gChanErr*fqStep;
        Double fqMinus   = fqPlus;
        Double fqStepMin = fqStep - (fqPlus + fqMinus) / chSpan;
        Double fqStepMax = fqStep + (fqPlus + fqMinus) / chSpan;

        if (freqStep <= 0.0) {
          // Initial definition of fiducial grid.
          freqMin  = fqMin;
          freqMax  = fqMax;
          freqStep = fqStep;

          freqPlus    = fqPlus;
          freqMinus   = fqMinus;
          freqStepMin = fqStepMin;
          freqStepMax = fqStepMax;

        } else {
          // Quick test for consistent channel spacing.
          if (fqStepMin > freqStepMax || fqStepMax < freqStepMin) {
            // Mark this dataset as incompatible.
            skipIt = True;
            fileNames(ifile) = gFiles(ifile) +
                               ": SKIPPED, FREQUENCY RESOLUTION INCONSISTENT";
            logWarning("   " + fileNames(ifile));
            break;
          }

          // Fiducial grid points closest to fqMin and fqMax.
          Int cmin;
          if (fqMin > freqMin) {
            cmin = (int)((fqMin - freqMin)/freqStep + 0.5);
          } else {
            cmin = (int)((fqMin - freqMin)/freqStep - 0.5);
          }

          Int cmax;
          if (fqMax > freqMin) {
            cmax = (int)((fqMax - freqMin)/freqStep + 0.5);
          } else {
            cmax = (int)((fqMax - freqMin)/freqStep - 0.5);
          }

          Double fmin = freqMin + cmin*freqStep;
          Double fmax = freqMin + cmax*freqStep;
          Double shiftMin = fqMin - fmin;
          Double shiftMax = fqMax - fmax;

          // Check registration on the fiducial grid.
          Double minPlus  = freqPlus;
          Double minMinus = freqMinus;
          if (fmin < freqMin) {
            minPlus  = ((freqMin + freqPlus) + cmin*freqStepMin) - fmin;
            minMinus = fmin - ((freqMin - freqMinus) + cmin*freqStepMax);

          } else if (fmin > freqMax) {
            minPlus  = ((freqMin - freqMinus) + cmin*freqStepMax) - fmin;
            minMinus = fmin - ((freqMin + freqPlus)  + cmin*freqStepMin);
          }

          Double maxPlus  = freqPlus;
          Double maxMinus = freqMinus;
          if (fmax < freqMin) {
            maxPlus  = ((freqMin + freqPlus) - cmax*freqStepMin) - fmax;
            maxMinus = fmax - ((freqMin - freqMinus) - cmax*freqStepMax);

          } else if (fmax > freqMax) {
            maxPlus  = ((freqMin - freqMinus) + cmax*freqStepMax) - fmax;
            maxMinus = fmax - ((freqMin + freqPlus)  + cmax*freqStepMin);
          }

          if (shiftMin > minPlus + fqMinus    ||
              shiftMin < -(minMinus + fqPlus) ||
              shiftMax > maxPlus + fqMinus    ||
              shiftMax < -(maxMinus + fqPlus)) {
            // Mark this dataset as incompatible.
            skipIt = True;
            fileNames(ifile) = gFiles(ifile) +
                             ": SKIPPED, FREQUENCY GRID INCONSISTENT";
            logWarning("   " + fileNames(ifile));
            break;
          }


          // Redefine the fiducial grid.
          chSpan = (max(freqMax, fmax) - min(freqMin, fmin)) / freqStep;

          if (fmin <= freqMin) {
            if (fqMin > fmin) {
              freqMin = (fmin*fqMinus + fqMin*minPlus) / (minPlus + fqMinus);
            } else {
              freqMin = (fmin*fqPlus + fqMin*minMinus) / (minMinus + fqPlus);
            }

            freqPlus  = (fmin + minPlus) - freqMin;
            freqMinus = freqMin - (fmin - minMinus);
          }

          if (fmax >= freqMax) {
            if (fqMax > fmax) {
              freqMax = (fmax*fqMinus + fqMax*maxPlus) / (maxPlus + fqMinus);
            } else {
              freqMax = (fmax*fqPlus + fqMax*maxMinus) / (maxMinus + fqPlus);
            }

            freqPlus  = min(freqPlus, (fmax + maxPlus) - freqMax);
            freqMinus = min(freqMinus, freqMax - (fmax - maxMinus));
          }

          // Strictly speaking, the extrema should also be redetermined when
          // fmin or fmax fall between freqMin and freqMax, but that is a job
          // for another day.

          fqSpan = freqMax - freqMin;
          freqStep = fqSpan / chSpan;

          freqPlus  = min(freqPlus,  gChanErr*freqStep);
          freqMinus = min(freqMinus, gChanErr*freqStep);
          freqStepMin = freqStep - (freqPlus + freqMinus) / chSpan;
          freqStepMax = freqStep + (freqPlus + freqMinus) / chSpan;
        }
      }

      if (skipIt) continue;

      // Check the frequency reference frame.
      Double bandwidth, refFreq, utc;
      String antName, doppler, observer, obsType, project;
      Float  equinox;
      if (reader->getHeader(observer, project, antName, antPos, obsType,
                        equinox, doppler, utc, refFreq, bandwidth)) {
        fileNames(ifile) = gFiles(ifile) +
                           ": SKIPPED, ERROR READING HEADER INFORMATION";
        logWarning("   " + fileNames(ifile));
        continue;
      }

      if (dopplerFrame == "") {
        dopplerFrame = doppler;

      } else if (doppler != dopplerFrame) {
        // Mark this dataset as incompatible.
        fileNames(ifile) = gFiles(ifile) +
                         ": SKIPPED, DOPPLER REFERENCE FRAME INCONSISTENT";
        logWarning("   " + fileNames(ifile));
        continue;
      }
    }


    // Apply beam and IF selection.
    Vector<Int> endChan, refChan, startChan;
    reader->select(gBeamSel, IFsel, startChan, endChan, refChan, gDoLine,
                   False, gCoordSys == "FEED-PLANE");


    // Determine the dataset limits.
    if (reader->findRange(nRow(ifile), nSel(ifile), timeSpan(ifile),
                          positions(ifile))) {
      fileNames(ifile) = gFiles(ifile) +
                         ": SKIPPED, ERROR DETERMINING DATASET LIMITS";
      logWarning("   " + fileNames(ifile));
      continue;
    }

    totalRows += nRow(ifile);
    specCount += nSel(ifile);

    buffer.str("");
    buffer << "   " << gFiles(ifile) << ": " << nSel(ifile) << " of "
           << nRow(ifile) << " rows (file " << ifile+1 << " of " << nFiles
           << ")";
    logMessage(buffer);

    if (gDoLine) {
      if (haveSpectra) {
        lineCount += nSel(ifile);
      } else {
        logWarning("      Spectral line data absent from the above file "
                   "(DATA column was deleted).");
      }
    }
  }
  if (reader) delete reader;

  // Check that we got something.
  if (!specCount) {
    logError("ERROR: NO VALID DATA FOUND - ABORT!");
    return False;
  }

  // Check that we got some spectra.
  if (gDoLine && !lineCount) {
    if (gDoCont || gDoBase) {
      logWarning("WARNING: No spectral line data found in any input files, "
                 "skipping spectral cube.");
      gDoLine = False;
    } else {
      logError("ERROR: NO SPECTRAL LINE DATA FOUND IN ANY INPUT FILES, "
               "ABORT!");
      return False;
    }
  }


  if (gDoLine) {
    // Report spectral parameters of input data.
    buffer.str("");
    Int nchan;
    if (freqStep != 0.0) {
      nchan = nint((freqMax - freqMin)/freqStep) + 1;
      buffer << "Spectral range: " << freqMin/1.0e6 << " to "
             << freqMax/1.0e6 << " MHz in " << nchan
             << " channels spaced by " << freqStep/1.0e3 << " kHz.";
    } else {
      nchan = 1;
      buffer << "Spectral range: 1 channel at " << freqMin/1.0e6 << " MHz.";
    }
    logMessage(buffer);

    buffer.str("");
    Double velMin  = C::c*(1.0 - freqMax/gRestFreq)/1000.0;
    Double velMax  = C::c*(1.0 - freqMin/gRestFreq)/1000.0;
    Double velStep = C::c*(freqStep/gRestFreq)/1000.0;

    if (nchan > 1) {
      buffer << "Radio velocity range: " << velMin << " to " << velMax
             << " km/s in steps of " << velStep << " km/s.";
    } else {
      buffer << "Radio velocity range: 1 channel at " << velMin << " km/s.";
    }
    logMessage(buffer);

    // Lock start and end frequencies to particular channels.
    gStartFreq = freqMin + nint((gStartFreq - freqMin)/freqStep)*freqStep;
    gEndFreq   = freqMin + nint((gEndFreq   - freqMin)/freqStep)*freqStep;


    if (dopplerFrame == "") {
      logWarning("WARNING: Frequency/velocity reference frame was not "
                 "recorded in the input data.");
    } else {
      logMessage("Frequency/velocity reference frame is \"" + dopplerFrame +
                 "\".");
    }

    // Check frequency range.
    if (gStartFreq < freqMin && gEndFreq < freqMin) {
      logError("ERROR: THE SPECIFIED SPECTRAL RANGE IS BELOW THE MINIMUM "
               "FOUND IN THE DATA - ABORT!");
      return False;
    }

    if (gStartFreq > freqMax && gEndFreq > freqMax) {
      logError("ERROR: THE SPECIFIED SPECTRAL RANGE IS OUTSIDE THE RANGE "
               "FOUND IN THE DATA - ABORT!");
      return False;
    }

    if (gStartFreq < freqMin) gStartFreq = freqMin;
    if (gEndFreq   < freqMin) gEndFreq   = freqMin;
    if (gStartFreq > freqMax) gStartFreq = freqMax;
    if (gEndFreq   > freqMax) gEndFreq   = freqMax;


    // Set the sign of the frequency increment.
    if (gEndFreq < gStartFreq) {
      freqStep = -freqStep;
    }

    if (freqStep != 0.0) {
      nOutChans = nint((gEndFreq - gStartFreq)/freqStep) + 1;

      // Report spectral parameters of output data.
      logMessage("Range selected: ", nOutChans, " output channels,");

      buffer.str("");
      buffer << "                frequency " << gStartFreq/1.0e6 << " to "
             << gEndFreq/1.0e6 << " MHz,";
      logMessage(buffer);

      buffer.str("");
      Double startVel = C::c*(1.0 - gStartFreq/gRestFreq);
      Double endVel   = C::c*(1.0 -   gEndFreq/gRestFreq);
      buffer << "           radio velocity " << startVel/1000.0 << " to "
             << endVel/1000.0 << " km/s.";
      logMessage(buffer);

    } else {
      nOutChans = 1;

      logMessage("Range selected: 1 output channel,");
      logMessage("                frequency ", gStartFreq/1.0e6, " MHz,");
      Double startVel = C::c*(1.0 - gStartFreq/gRestFreq);
      logMessage("          radio velocity ", startVel/1000.0, " km/s.");
    }
  }


  // Each spectrum contains two polarizations; either or both may be used.
  String polMul;
  if (gPolOp == "A" || gPolOp == "B") {
    // Only one polarization was selected.
    polMul = "1";
  } else {
    // Both polarizations are required.
    polMul = "2";
  }

  buffer.str("");
  buffer << "Total number of spectra selected: " + polMul + " * "
         << specCount << " in " << totalRows << " table rows." ;
  logMessage(buffer);

  buffer.str("");
  if (lineCount && lineCount != specCount) {
    buffer << "Total selected for spectral cube: " + polMul + " * "
           << lineCount;
    logMessage(buffer);
  }


  double equ2gal[] = {192.85948125, 62.87174874, 122.93191814,
                      0.455983795747, 0.889988077457};

  // Copy out coordinates.
  uInt k = 0;
  celCrd.resize(specCount, 2);
  for (uInt ifile = 0; ifile < nFiles; ifile++) {
    for (Int isel = 0; isel < nSel(ifile); isel++) {
      Double lat, lng;

      if (gCoordSys == "FEED-PLANE") {
        // Feed-plane coordinates, in degrees.
        lng = positions(ifile)(0,isel) * R2D;
        lat = positions(ifile)(1,isel) * R2D;

      } else {
        // J2000.0 coordinates, in degrees.
        Double ra  = positions(ifile)(0,isel) * R2D;
        Double dec = positions(ifile)(1,isel) * R2D;

        // Check validity
        if (ra < 0.0 || 360.0 < ra || dec < -90.0 || 90.0 < dec) {
          buffer.str("");
          buffer << "WARNING: In " << gFiles(ifile) << "," << endl
                 << ": RA  = " << ra
                 << ", Dec = " << dec << " (deg)";
          logWarning(buffer);
        }

        if (gCoordSys == "GALACTIC") {
          // Convert to galactic coordinates, in degrees.
          sphs2x(equ2gal, 1, 1, 1, 1, &ra, &dec, &lng, &lat);
          if (lng < 0.0) lng += 360.0;
        } else {
          lng = ra;
          lat = dec;
        }
      }

      celCrd(k,0) = Float(lng);
      celCrd(k,1) = Float(lat);
      k++;
    }
  }


  // Determine day/night status.
  k = 0;
  nightFlag.resize(specCount);
  for (uInt ifile = 0; ifile < nFiles; ifile++) {
    if (nSel(ifile)) {
      Double utc1 = timeSpan(ifile)(0);
      Double utc2 = timeSpan(ifile)(1);

      Double el1 = solel(antPos, utc1/86400.0)*R2D;
      Double el2 = solel(antPos, utc2/86400.0)*R2D;

      Bool nightTime = el1 < NIGHTTIME_ELEVATION_LIMIT &&
                       el2 < NIGHTTIME_ELEVATION_LIMIT;

      for (Int isel = 0; isel < nSel(ifile); isel++) {
        nightFlag(k++) = nightTime;
      }
    }
  }


  // Determine the number of passes required; allow 10 MiB for overheads.
  if (gDoLine) {
    Int nPol = 1;
    if (gPolOp == "A&B") nPol = 2;

    chanPerPass = int(((gStorage-10)*1024.0*1024.0) / (nPol*specCount*4.0));

    if (chanPerPass < 1) {
      chanPerPass = 1;

      // This represents the bare minimum amount of memory required.
      int memReq = 10 + (nPol*specCount*4) / (1024*1024);
      if (memReq == 10) memReq = 11;

      buffer.str("");
      buffer << "WARNING: " << gStorage
             << " MiB is inadequate for this problem,";
      logWarning(buffer);

      buffer.str("");
      buffer << "at least " << memReq << " MiB is required per plane.";
      logWarning(buffer);

    } else {
      buffer.str("");
      buffer << gStorage << " MiB of storage is enough to process "
             << chanPerPass << " channel" << ((chanPerPass > 1) ? "s" : "")
             << " per pass.";
      logMessage(buffer);

      if (chanPerPass > nOutChans) {
        chanPerPass = nOutChans;
      }
    }

    nPass = nOutChans / chanPerPass;
    if (nPass*chanPerPass < nOutChans) {
      nPass++;
    }

    buffer.str("");
    if (nPass == 1) {
      logMessage("Only one pass will be required.");
    } else {
      logMessage("", nPass, " passes will be required.");
    }

    logMessage("");

  } else {
    nPass = 1;
  }

  return True;
}

//------------------------------------------------------------------- shutDown

void shutDown(GlishSysEventSource *glishBus)
{
  logMessage("=========================== pksgridzilla is finished "
             "===========================");

  glishBus->postEvent("done", gClientName);
}
