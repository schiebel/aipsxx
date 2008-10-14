//#---------------------------------------------------------------------------
//# pksstats.cc: Glish client that computes statistics for single-dish data.
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
//# $Id: pksstats.cc,v 19.8 2006/06/29 03:41:18 mcalabre Exp $
//#---------------------------------------------------------------------------

// AIPS++ includes.
#include <casa/iostream.h>
#include <casa/stdio.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/MaskedArray.h>
#include <casa/Arrays/MaskArrMath.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Slice.h>
#include <casa/BasicSL/Constants.h>
#include <casa/BasicSL/String.h>
#include <casa/Exceptions/Error.h>
#include <casa/Utilities/GenSort.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishEvent.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>

// Parkes includes.
#include <atnf/pks/pks_maths.h>
#include <atnf/pks/pksmb_support.h>

#include <casa/namespace.h>

// Glish event handlers.
Bool init_event(GlishSysEvent &event, void *);
Bool accumulate_event(GlishSysEvent &event, void *);
Bool stats_event(GlishSysEvent &event, void *);

// Client worker functions.
void doStats(void);
Float interRange(Vector<Float> data, Int frac);

// Parameters.
String gFileName;			// Output file basename.
Int gStartChan, gEndChan;		// First and last channels in the
					// range over which statistics are to
					// be computed.

// Client parameters.
const uInt gMaxBeams = 13;		// Maximum number of beams.
uInt gMaxInts = 128;			// Maximum number of integrations.

// Global variables.
String gClientName = "pksstats";

Bool          gNight;
Matrix<uInt>  gIntCount(gMaxBeams,2);

Matrix<Float> gDataCount(gMaxBeams,2);
Matrix<Float> gDataMin(gMaxBeams,2);
Matrix<Float> gDataMax(gMaxBeams,2);
Matrix<Float> gDataSum(gMaxBeams,2);
Matrix<Float> gDataSsq(gMaxBeams,2);
Matrix<Float> gDataCntrCount(gMaxBeams,2);
Matrix<Float> gDataCntrSum(gMaxBeams,2);
Matrix<Float> gDataCntrSsq(gMaxBeams,2);
Matrix<Vector<Float> > gDataMedians(gMaxBeams,2);
Matrix<Vector<Float> > gDataI4r(gMaxBeams,2);
Matrix<Vector<Float> > gDataI6r(gMaxBeams,2);
Matrix<Vector<Float> > gTsys(gMaxBeams,2);

const Double R2D = 180.0/C::pi;

//----------------------------------------------------------------------- main

int main(int argc, char **argv)
{
  try {
    // Resize data arrays.
    for (uInt ibeam = 0; ibeam < gMaxBeams; ibeam++) {
      for (uInt ipol = 0; ipol < 2; ipol++) {
        gDataMedians(ibeam,ipol).resize(gMaxInts);
        gDataI4r(ibeam,ipol).resize(gMaxInts);
        gDataI6r(ibeam,ipol).resize(gMaxInts);
        gTsys(ibeam,ipol).resize(gMaxInts);
      }
    }

    // Set up the Glish event stream.
    GlishSysEventSource glishStream(argc, argv);
    glishStream.addTarget(init_event, "init");
    glishStream.addTarget(accumulate_event, "accumulate");
    glishStream.addTarget(stats_event, "stats");
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
  String version = "$Revision: 19.8 $";
  String date = "$Date: 2006/06/29 03:41:18 $";

  logMessage("pksstats (v" + String(version.after(' ')).before(' ') +
             ", " + String(date.after(' ')).before(' ') + ") initializing.");

  GlishSysEventSource *glishBus = event.glishSource();
  GlishValue glishVal = event.val();

  // Check that argument is a record.
  if (glishVal.type() != GlishValue::RECORD) {
    glishBus->postEvent("initialized", GlishArray(False));
    logMessage("WARNING: Argument to \"init\" should be a record");
    return True;
  }

  // Extract useful parameters.
  String directory, file;
  GlishRecord parms = glishVal;
  getParm(parms, "directory", String("."),        directory);
  getParm(parms, "file",      String("pksstats"), file);

  if (directory == "") directory = ".";
  gFileName = directory + "/" + file;

  getParm(parms, "startChan", 1, gStartChan);
  getParm(parms, "endChan",   0, gEndChan);

  gNight = True;

  gIntCount  = 0;
  gDataCount = 0;
  gDataSum   = 0.0f;
  gDataSsq   = 0.0f;
  gDataCntrCount = 0.0f;
  gDataCntrSum   = 0.0f;
  gDataCntrSsq   = 0.0f;

  glishBus->postEvent("initialized", GlishArray(True));

  return True;
}

//----------------------------------------------------------- accumulate_event

// Handler for "accumulate" event; accumulate data.

Bool accumulate_event(GlishSysEvent &event, void *)
{
  GlishSysEventSource *glishBus = event.glishSource();
  GlishValue glishVal = event.val();

  // Check that argument is a record.
  if (glishVal.type() != GlishValue::RECORD) {
    glishBus->postEvent("accumulate_error", "Accumulate failed");
    logError("Argument to \"accumulate\" should be a multibeam Glish Record.");
    return True;
  }

  GlishRecord aggRec = glishVal, aggRecStats, beamRec, intRec;
  GlishArray glishArr;

  uInt nRec = aggRec.nelements();
  for (uInt iRec = 0; iRec < nRec; iRec++) {
    intRec  = aggRec.get(iRec);
    beamRec = intRec.get(0);

    // Get timestamp, MJD UTC in seconds.
    glishArr = beamRec.get("TIME");
    Double utc;
    glishArr.get(utc);

    if (gStartChan <= 0 || gEndChan <= 0) {
      glishArr = beamRec.get("NUM_CHANNEL");
      Int nChan;
      glishArr.get(nChan);

      if (gStartChan <= 0) {
        gStartChan += nChan;
      }

      if (gEndChan <= 0) {
        gEndChan += nChan;
      }
    }

    // Night or day?  (Daytime if day at any time during scan.)
    if (gNight) {
      // Compute solar elevation at the start and end of the scan.
      glishArr = beamRec.get("ANTENNA_POSITION");
      Vector<Double> antPos(3);
      glishArr.get(antPos);

      // Low precision coordinates of the Sun.
      Double el = solel(antPos, utc/86400.0)*R2D;

      gNight = el < NIGHTTIME_ELEVATION_LIMIT;
    }

    Matrix<Int>      count(13, 2, 0);
    Matrix<Float>     Tsys(13, 2, 0.0f);
    Matrix<Float>    means(13, 2, 0.0f);
    Matrix<Float>  medians(13, 2, 0.0f);
    Matrix<Float>      rms(13, 2, 0.0f);
    Matrix<Float> quartile(13, 2, 0.0f);
    Matrix<Float>  maximum(13, 2, 0.0f);
    Matrix<Float>  minimum(13, 2, 0.0f);

    // Accumulate data.
    uInt nBeam = intRec.nelements();
    for (uInt ibeam = 0; ibeam < nBeam; ibeam++) {
      beamRec = intRec.get(ibeam);

      // 1-relative beam number.
      glishArr = beamRec.get("BEAM");
      Int beamNo;
      glishArr.get(beamNo);
      Int beam = beamNo - 1;

      glishArr = beamRec.get("FLOAT_DATA");
      Matrix<Float> spectra(glishArr.shape());
      glishArr.get(spectra);

      glishArr = beamRec.get("FLAGGED");
      Matrix<uChar> flagtra(glishArr.shape());
      glishArr.get(flagtra);

      glishArr = beamRec.get("TSYS");
      Vector<Float> tsys(glishArr.shape());
      glishArr.get(tsys);

      uInt nChan = spectra.nrow();
      uInt nPol  = spectra.ncolumn();

      for (uInt ipol = 0; ipol < nPol; ipol++) {
        uInt idx = gIntCount(beam,ipol)++;
        if (idx >= gMaxInts) {
          // Expand buffer length.
          gMaxInts *= 2;

          for (uInt jbeam = 0; jbeam < nBeam; jbeam++) {
            for (uInt jpol = 0; jpol < nPol; jpol++) {
              gDataMedians(jbeam,jpol).resize(gMaxInts, True);
              gDataI4r(jbeam,jpol).resize(gMaxInts, True);
              gDataI6r(jbeam,jpol).resize(gMaxInts, True);
              gTsys(jbeam,jpol).resize(gMaxInts, True);
            }
          }
        }

        // Construct the mask of unflagged channels.
        Vector<uChar> flagtrum = flagtra.column(ipol);
        Vector<Bool> mask(nChan, True);
        if (flagtrum.nelements() == nChan) {
          mask = flagtrum == uChar(0);
        } else if (flagtrum(0) > uChar(0)) {
          mask = False;
        }

        // Apply channel selection.
        if (gStartChan > 1) {
          mask(Slice(0,gStartChan)) = False;
        }
        if (gEndChan < Int(nChan)) {
          mask(Slice(gEndChan-1,nChan-gEndChan+1)) = False;
        }

        Float spi4r, spi6r, spmax, spmean, spmedian, spmin, spssq, spsum;
        Vector<Float> spectrum = spectra.column(ipol);
        Vector<Float> goodchan;

        uInt mChan = ntrue(mask);
        if (mChan == 0) {
          // No good channels.
          spsum  = 0.0f;
          spmean = 0.0f;
          spssq  = 0.0f;
          spmedian = 0.0f;
          spi4r  = 0.0f;
          spi6r  = 0.0f;
          spmin  = 0.0f;
          spmax  = 0.0f;

        } else {
          if (mChan == nChan) {
            // No bad channels.
            goodchan.reference(spectrum);

          } else {
            goodchan.resize(mChan);

            uInt jchan = 0;
            for (uInt ichan = 0; ichan < nChan; ichan++) {
              if (mask(ichan)) {
                goodchan(jchan++) = spectrum(ichan);
              }
            }
          }

          genSort(goodchan);
          spsum  = sum(goodchan);
          spmean = spsum/mChan;
          spssq  = sum(goodchan*goodchan);
          spmedian = median(goodchan, True);
          spi4r = interRange(goodchan, 4);
          spi6r = interRange(goodchan, 6);
          spmin = goodchan(0);
          spmax = goodchan(mChan-1);
        }

        // Stats to be returned.
        count(beam,ipol)    = mChan;
        Tsys(beam,ipol)     = tsys(ipol);
        means(beam,ipol)    = spmean;
        medians(beam,ipol)  = spmedian;
        rms(beam,ipol)      = sqrt(spssq/mChan - spmean*spmean);
        quartile(beam,ipol) = spi4r;
        maximum(beam,ipol)  = spmax;
        minimum(beam,ipol)  = spmin;

        // Cumulative statistics for the whole scan.
        gDataCount(beam,ipol) += mChan;

        gTsys(beam,ipol)(idx) = tsys(ipol);

        gDataSum(beam,ipol) += spsum;
        gDataSsq(beam,ipol) += spssq;

        Slice midqtr(3*nChan/8,nChan/4);
        Vector<Float> centre = spectrum(midqtr);
        gDataCntrCount(beam,ipol) += ntrue(mask(midqtr));
        centre(mask(midqtr)) = 0.0f;
        gDataCntrSum(beam,ipol) += sum(centre);
        gDataCntrSsq(beam,ipol) += sum(centre*centre);

        gDataMedians(beam,ipol)(idx) = spmedian;
        gDataI4r(beam,ipol)(idx) = spi4r;
        gDataI6r(beam,ipol)(idx) = spi6r;

        if (idx == 0) {
          gDataMin(beam,ipol) = spmin;
          gDataMax(beam,ipol) = spmax;
        } else {
          gDataMin(beam,ipol) = min(gDataMin(beam,ipol), spmin);
          gDataMax(beam,ipol) = max(gDataMax(beam,ipol), spmax);
        }
      }
    }

    // Intermediate results for this integration.
    GlishRecord intRecStats;
    intRecStats.add("TIME", utc);

    intRecStats.add("COUNT",    count);
    intRecStats.add("TSYS",     Tsys);
    intRecStats.add("MEAN",     means);
    intRecStats.add("MEDIAN",   medians);
    intRecStats.add("RMS",      rms);
    intRecStats.add("QUARTILE", quartile);
    intRecStats.add("MAXIMUM",  maximum);
    intRecStats.add("MINIMUM",  minimum);

    String intLabel = aggRec.name(iRec);
    aggRecStats.add(intLabel, intRecStats);
  }

  glishBus->postEvent("accumulated", aggRecStats);
  return True;
}

//---------------------------------------------------------------- stats_event

// Handler for "stats" event; compute statistics from the accumulated data.

Bool stats_event(GlishSysEvent &event, void *)
{
  char text[120];

  uInt nChan, nInt;
  Float avg, i4r, i6r, maxval, med, meddev, minval, rms, rms4;
  GlishSysEventSource *glishBus = event.glishSource();


  // Tsys stats.
  FILE *tsysout = fopen((gFileName + ".tsys_stats").chars(), "w");
  if (tsysout == (FILE *)NULL) {
    logError("Failed to open " + gFileName + ".tsys_stats,");
    logError("check directory and file permissions, etc.");
    glishBus->postEvent("finished", "stats finished");
    return True;
  }

  logMessage("");
  logMessage("Tsys statistics:");
  sprintf(text, "BM:P Tm #chn #sp Mean  Sig  Medn  IQ/2 IS/2 MednDev Min"
                "    Max");
  fprintf(tsysout, "%s\n", text);
  logMessage(text);

  char daynight = 'd';
  if (gNight) daynight = 'n';

  // Count over all beams.
  for (uInt ibeam = 0; ibeam < gMaxBeams; ibeam++) {
    for (Int ipol = 0; ipol < 2; ipol++) {
      if (gDataCount(ibeam,ipol) == 0) {
        continue;
      }

      nInt = min(gIntCount(ibeam,ipol), gMaxInts);
      Vector<Float> tsys = gTsys(ibeam,ipol)(Slice(0,nInt));

      nChan = uInt(gDataCount(ibeam,ipol) / nInt);

      avg = mean(tsys);
      rms = sqrt(mean(tsys*tsys) - avg*avg);

      // Median, interquartile range, intersextile range.
      genSort(tsys);
      med = median(tsys, True);
      i4r = interRange(tsys, 4);
      i6r = interRange(tsys, 6);

      // Median deviation.
      meddev = median(fabs(tsys - med));

      // Min, max.
      minval = tsys(0);
      maxval = tsys(nInt-1);

      sprintf(text, "%02d:%1d%2c%6d%4d%6.2f%5.2f%6.2f%5.2f%5.2f%5.2f"
        "%+10.2f%+7.2f", ibeam+1, ipol+1, daynight, nChan, nInt, avg, rms,
        med, i4r, i6r, meddev, minval, maxval);

      fprintf(tsysout, "%s\n", text);
      logMessage(text);
    }
  }

  fclose(tsysout);


  // Data stats.
  FILE *dataout = fopen((gFileName + ".data_stats").chars(), "w");
  if (dataout == (FILE *)NULL) {
    logError("Failed to open " + gFileName + ".data_stats,");
    logError("check directory and file permissions, etc.");
    glishBus->postEvent("finished", "stats finished");
    return True;
  }

  logMessage("");
  logMessage("Spectra statistics:");
  sprintf(text, "BM:P Mean      Sig      SigQ     Medn      IQ/2     IS/2"
                "     MednDev  Min       Max");
  fprintf(dataout, "%s\n", text);
  logMessage(text);

  for (uInt ibeam = 0; ibeam < gMaxBeams; ibeam++) {
    for (uInt ipol = 0; ipol < 2; ipol++) {
      if (gDataCount(ibeam,ipol) == 0) {
        continue;
      }

      avg = gDataSum(ibeam,ipol)/gDataCount(ibeam,ipol);
      rms = sqrt(gDataSsq(ibeam,ipol)/gDataCount(ibeam,ipol) - avg*avg);

      // RMS in the central quarter of the channel range.
      Float avg4 = gDataCntrSum(ibeam,ipol)/gDataCntrCount(ibeam,ipol);
      rms4 = sqrt(gDataCntrSsq(ibeam,ipol)/gDataCntrCount(ibeam,ipol) -
                  avg4*avg4);

      // Median, interquartile range, intersextile range.
      nInt = min(gIntCount(ibeam,ipol), gMaxInts);
      Vector<Float> medians = gDataMedians(ibeam,ipol)(Slice(0,nInt));
      Vector<Float> dataI4r = gDataI4r(ibeam,ipol)(Slice(0,nInt));
      Vector<Float> dataI6r = gDataI6r(ibeam,ipol)(Slice(0,nInt));

      med = median(medians);
      i4r = (median(medians + dataI4r) - median(medians - dataI4r))/2.0;
      i6r = (median(medians + dataI6r) - median(medians - dataI6r))/2.0;

      // Median deviation (not the same as the interquartile range).
      meddev = i4r;

      // Min, max.
      minval = gDataMin(ibeam,ipol);
      maxval = gDataMax(ibeam,ipol);

      sprintf(text,
        "%02d:%1d %+4.2e %4.2e %4.2e %+4.2e %4.2e %4.2e %4.2e %+4.2e %+4.2e",
        ibeam+1, ipol+1, avg, rms, rms4, med, i4r, i6r, meddev, minval,
        maxval);

      fprintf(dataout, "%s\n", text);
      logMessage(text);
    }
  }

  fclose(dataout);


  glishBus->postEvent("finished", "stats finished");

  return True;
}

//----------------------------------------------------------------- interRange

// Calculates the half-range between the (1/frac)th and ((frac-1)/frac)th
// data points assuming the data is sorted.

Float interRange(Vector<Float> data, Int frac)
{
  uInt npoints = data.nelements();

  uInt lpoint1 = npoints/frac;
  Float remf = Float(npoints % frac) - Float(frac)/2.0;
  uInt lpoint2 = (remf >= 0.0) ? (lpoint1+1) : (lpoint1-1);

  Float x = fabs(remf)/Float(frac);

  Float lval = data(lpoint1)*(1.0 - x) + data(lpoint2)*x;
  Float rval = data(npoints - 1 - lpoint1)*(1.0 - x) +
               data(npoints - 1 - lpoint2)*x;

  return (rval - lval)/2.0;
}
