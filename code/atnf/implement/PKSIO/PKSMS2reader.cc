//#---------------------------------------------------------------------------
//# PKSMS2reader.cc: Class to read Parkes Multibeam data from a v2 MS.
//#---------------------------------------------------------------------------
//# Copyright (C) 2000-2006
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
//# $Id: PKSMS2reader.cc,v 19.11 2006/07/05 04:59:20 mcalabre Exp $
//#---------------------------------------------------------------------------
//# Original: 2000/08/03, Mark Calabretta, ATNF
//#---------------------------------------------------------------------------


// AIPS++ includes.
#include <casa/stdio.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/Slice.h>
#include <ms/MeasurementSets/MSColumns.h>
#include <tables/Tables.h>

// Parkes includes.
#include <atnf/pks/pks_maths.h>
#include <atnf/PKSIO/PKSMS2reader.h>


//------------------------------------------------- PKSMS2reader::PKSMS2reader

// Default constructor.

PKSMS2reader::PKSMS2reader()
{
  cMSopen = False;
}

//------------------------------------------------ PKSMS2reader::~PKSMS2reader

PKSMS2reader::~PKSMS2reader()
{
  close();
}

//--------------------------------------------------------- PKSMS2reader::open

// Open the MS for reading.

Int PKSMS2reader::open(
        const String msName,
        Vector<Bool> &beams,
        Vector<Bool> &IFs,
        Vector<uInt> &nChan,
        Vector<uInt> &nPol,
        Vector<Bool> &haveXPol,
        Bool   &haveBase,
        Bool   &haveSpectra)
{
  // Check that MS is readable.
  if (!MS::isReadable(msName)) {
    return 1;
  }

  if (cMSopen) {
    close();
  }

  cPKSMS  = MeasurementSet(msName);
  cIdx    = 0;
  cNRow   = cPKSMS.nrow();
  cMSopen = True;

  // Lock the table for read access.
  cPKSMS.lock(False);

  // Main MS table and subtable column access.
  ROMSMainColumns         msCols(cPKSMS);
  ROMSDataDescColumns     dataDescCols(cPKSMS.dataDescription());
  ROMSFeedColumns         feedCols(cPKSMS.feed());
  ROMSFieldColumns        fieldCols(cPKSMS.field());
  ROMSPointingColumns     pointingCols(cPKSMS.pointing());
  ROMSPolarizationColumns polarizationCols(cPKSMS.polarization());
  ROMSSourceColumns       sourceCols(cPKSMS.source());
  ROMSSpWindowColumns     spWinCols(cPKSMS.spectralWindow());
  ROMSStateColumns        stateCols(cPKSMS.state());
  ROMSSysCalColumns       sysCalCols(cPKSMS.sysCal());
  ROMSWeatherColumns      weatherCols(cPKSMS.weather());

  // Column accessors for required columns.
  cScanNoCol.reference(msCols.scanNumber());
  cTimeCol.reference(msCols.time());
  cIntervalCol.reference(msCols.interval());

  cFieldIdCol.reference(msCols.fieldId());
  cFieldNameCol.reference(fieldCols.name());

  cSrcIdCol.reference(fieldCols.sourceId());
  cSrcNameCol.reference(sourceCols.name());
  cSrcDirCol.reference(sourceCols.direction());
  cSrcPMCol.reference(sourceCols.properMotion());
  cSrcRestFrqCol.reference(sourceCols.restFrequency());

  cStateIdCol.reference(msCols.stateId());
  cObsModeCol.reference(stateCols.obsMode());

  cDataDescIdCol.reference(msCols.dataDescId());
  cChanFreqCol.reference(spWinCols.chanFreq());

  cWeatherTimeCol.reference(weatherCols.time());
  cTemperatureCol.reference(weatherCols.temperature());
  cPressureCol.reference(weatherCols.pressure());
  cHumidityCol.reference(weatherCols.relHumidity());

  cBeamNoCol.reference(msCols.feed1());
  cPointingCol.reference(pointingCols.direction());
  cSigmaCol.reference(msCols.sigma());
  cNumReceptorCol.reference(feedCols.numReceptors());

  // Optional columns.
  if ((cHaveSrcVel = cPKSMS.source().tableDesc().isColumn("SYSVEL"))) {
    cSrcVelCol.attach(cPKSMS.source(), "SYSVEL");
  }

  if ((cHaveTsys = cPKSMS.sysCal().tableDesc().isColumn("TSYS"))) {
    cTsysCol.attach(cPKSMS.sysCal(), "TSYS");
  }

  if ((cHaveCalFctr = cPKSMS.tableDesc().isColumn("CALFCTR"))) {
    cCalFctrCol.attach(cPKSMS, "CALFCTR");
  }

  if ((cHaveBaseLin = cPKSMS.tableDesc().isColumn("BASELIN"))) {
    cBaseLinCol.attach(cPKSMS, "BASELIN");
    cBaseSubCol.attach(cPKSMS, "BASESUB");
  }

  // Spectral data should always be present.
  haveSpectra = True;
  cFloatDataCol.reference(msCols.floatData());
  cFlagCol.reference(msCols.flag());

  if ((cGetXPol = cPKSMS.isColumn(MSMainEnums::DATA))) {
    if ((cHaveXCalFctr = cPKSMS.tableDesc().isColumn("XCALFCTR"))) {
      cXCalFctrCol.attach(cPKSMS, "XCALFCTR");
    }

    cDataCol.reference(msCols.data());
  }

  // Find which beams are present in the data.
  Vector<Int> beamNos = cBeamNoCol.getColumn();
  Int maxBeamNo = max(beamNos) + 1;
  beams.resize(maxBeamNo);

  beams = False;
  for (uInt irow = 0; irow < beamNos.nelements(); irow++) {
    beams(beamNos(irow)) = True;
  }


  // Number of IFs.
  uInt nIF = dataDescCols.nrow();
  IFs.resize(nIF);
  IFs = True;

  // Number of polarizations and channels in each IF.
  ROScalarColumn<Int> spWinIdCol(dataDescCols.spectralWindowId());
  ROScalarColumn<Int> numChanCol(spWinCols.numChan());

  ROScalarColumn<Int> polIdCol(dataDescCols.polarizationId());
  ROScalarColumn<Int> numPolCol(polarizationCols.numCorr());

  nChan.resize(nIF);
  nPol.resize(nIF);
  for (uInt iIF = 0; iIF < nIF; iIF++) {
    nChan(iIF) = numChanCol(spWinIdCol(iIF));
    nPol(iIF)  = numPolCol(polIdCol(iIF));
  }

  // Cross-polarization data present?
  haveXPol.resize(nIF);
  haveXPol = False;

  if (cGetXPol) {
    for (Int irow = 0; irow < cNRow; irow++) {
      if (cDataCol.isDefined(irow)) {
        Int iIF = cDataDescIdCol(irow);
        haveXPol(iIF) = True;
      }
    }
  }


  // Initialize member data.
  cBeams.assign(beams);
  cIFs.assign(IFs);
  cNChan.assign(nChan);
  cNPol.assign(nPol);
  cHaveXPol.assign(haveXPol);


  // Default channel range selection.
  cStartChan.resize(nIF);
  cEndChan.resize(nIF);
  cRefChan.resize(nIF);

  for (uInt iIF = 0; iIF < nIF; iIF++) {
    cStartChan(iIF) = 1;
    cEndChan(iIF)   = cNChan(iIF);
    cRefChan(iIF)   = cNChan(iIF)/2 + 1;
  }

  Slice all;
  cDataSel.resize(nIF);
  cDataSel = Slicer(all, all);

  cScanNo  = 0;
  cCycleNo = 1;
  cTime    = cTimeCol(0);

  return 0;
}

//---------------------------------------------------- PKSMS2reader::getHeader

// Get parameters describing the data.

Int PKSMS2reader::getHeader(
        String &observer,
        String &project,
        String &antName,
        Vector<Double> &antPosition,
        String &obsMode,
        Float  &equinox,
        String &dopplerFrame,
        Double &mjd,
        Double &refFreq,
        Double &bandwidth)
{
  if (!cMSopen) {
    return 1;
  }

  // Observer and project.
  ROMSObservationColumns observationCols(cPKSMS.observation());
  observer = observationCols.observer()(0);
  project  = observationCols.project()(0);

  // Antenna name and ITRF coordinates.
  ROMSAntennaColumns antennaCols(cPKSMS.antenna());
  antName = antennaCols.name()(0);
  antPosition = antennaCols.position()(0);

  // Observation type.
  if (cObsModeCol.nrow()) {
    obsMode = cObsModeCol(0);
    if (obsMode == "\0") obsMode = "RF";
  } else {
    obsMode = "RF";
  }


  // Coordinate equinox.
  ROMSPointingColumns pointingCols(cPKSMS.pointing());
  String dirref = pointingCols.direction().keywordSet().asRecord("MEASINFO").
                    asString("Ref");
  sscanf(dirref.chars()+1, "%f", &equinox);

  // Frequency/velocity reference frame.
  ROMSSpWindowColumns spWinCols(cPKSMS.spectralWindow());
  dopplerFrame = MFrequency::showType(spWinCols.measFreqRef()(0));

  // Translate to FITS standard names.
  if (dopplerFrame == "TOPO") {
    dopplerFrame = "TOPOCENT";
  } else if (dopplerFrame == "GEO") {
    dopplerFrame = "GEOCENTR";
  } else if (dopplerFrame == "BARY") {
    dopplerFrame = "BARYCENT";
  } else if (dopplerFrame == "GALACTO") {
    dopplerFrame = "GALACTOC";
  } else if (dopplerFrame == "LGROUP") {
    dopplerFrame = "LOCALGRP";
  } else if (dopplerFrame == "CMB") {
    dopplerFrame = "CMBDIPOL";
  } else if (dopplerFrame == "REST") {
    dopplerFrame = "SOURCE";
  }

  // MJD at start of observation.
  mjd = cTimeCol(0)/86400.0;

  // Reference frequency and bandwidth.
  refFreq   = spWinCols.refFrequency()(0);
  bandwidth = spWinCols.totalBandwidth()(0);

  return 0;
}

//-------------------------------------------------- PKSMS2reader::getFreqInfo

// Get frequency parameters for each IF.

Int PKSMS2reader::getFreqInfo(
        Vector<Double> &startFreq,
        Vector<Double> &endFreq)
{
  uInt nIF = cIFs.nelements();
  startFreq.resize(nIF);
  endFreq.resize(nIF);

  for (uInt iIF = 0; iIF < nIF; iIF++) {
    Vector<Double> chanFreq = cChanFreqCol(iIF);

    Int nChan = chanFreq.nelements();
    startFreq(iIF) = chanFreq(0);
    endFreq(iIF)   = chanFreq(nChan-1);
  }

  return 0;
}

//------------------------------------------------------- PKSMS2reader::select

// Set data selection by beam number and channel.

uInt PKSMS2reader::select(
        const Vector<Bool> beamSel,
        const Vector<Bool> IFsel,
        const Vector<Int>  startChan,
        const Vector<Int>  endChan,
        const Vector<Int>  refChan,
        const Bool getSpectra,
        const Bool getXPol,
        const Bool getFeedPos)
{
  if (!cMSopen) {
    return 1;
  }

  // Beam selection.
  uInt nBeam = cBeams.nelements();
  uInt nBeamSel = beamSel.nelements();
  for (uInt ibeam = 0; ibeam < nBeam; ibeam++) {
    if (ibeam < nBeamSel) {
      cBeams(ibeam) = beamSel(ibeam);
    } else {
      cBeams(ibeam) = False;
    }
  }

  uInt nIF = cIFs.nelements();
  uInt maxNChan = 0;
  for (uInt iIF = 0; iIF < nIF; iIF++) {
    // IF selection.
    if (iIF < IFsel.nelements()) {
      cIFs(iIF) = IFsel(iIF);
    } else {
      cIFs(iIF) = False;
    }

    if (!cIFs(iIF)) continue;


    // Channel selection.
    if (iIF < startChan.nelements()) {
      cStartChan(iIF) = startChan(iIF);

      if (cStartChan(iIF) <= 0) {
        cStartChan(iIF) += cNChan(iIF);
      } else if (cStartChan(iIF) > Int(cNChan(iIF))) {
        cStartChan(iIF)  = cNChan(iIF);
      }
    }

    if (iIF < endChan.nelements()) {
      cEndChan(iIF) = endChan(iIF);

      if (cEndChan(iIF) <= 0) {
        cEndChan(iIF) += cNChan(iIF);
      } else if (cEndChan(iIF) > Int(cNChan(iIF))) {
        cEndChan(iIF)  = cNChan(iIF);
      }
    }

    if (iIF < refChan.nelements()) {
      cRefChan(iIF) = refChan(iIF);
    } else {
      cRefChan(iIF) = cStartChan(iIF);
      if (cStartChan(iIF) <= cEndChan(iIF)) {
        cRefChan(iIF) += (cEndChan(iIF) - cStartChan(iIF) + 1)/2;
      } else {
        cRefChan(iIF) -= (cStartChan(iIF) - cEndChan(iIF) + 1)/2;
      }
    }

    uInt nChan = abs(cEndChan(iIF) - cStartChan(iIF)) + 1;
    if (maxNChan < nChan) {
      maxNChan = nChan;
    }

    // Inverted Slices are not allowed.
    Slice outPols;
    Slice outChans(min(cStartChan(iIF),cEndChan(iIF))-1, nChan);
    cDataSel(iIF) = Slicer(outPols, outChans);
  }

  // Get spectral data?
  cGetSpectra = getSpectra;

  // Get cross-polarization data?
  cGetXPol = cGetXPol && getXPol;

  // Get feed positions?  (Not available.)
  cGetFeedPos = False;

  return maxNChan;
}

//---------------------------------------------------- PKSMS2reader::findRange

// Find the range of the data in time and position.

Int PKSMS2reader::findRange(
        Int    &nRow,
        Int    &nSel,
        Vector<Double> &timeSpan,
        Matrix<Double> &positions)
{
  if (!cMSopen) {
    return 1;
  }

  nRow = cNRow;

  // Find the number of rows selected.
  nSel = 0;
  Vector<Bool> sel(nRow);
  for (Int irow = 0; irow < nRow; irow++) {
    if ((sel(irow) = cBeams(cBeamNoCol(irow)) &&
                     cIFs(cDataDescIdCol(irow)))) {
      nSel++;
    }
  }

  // Find the time range (s).
  timeSpan.resize(2);
  timeSpan(0) = cTimeCol(0);
  timeSpan(1) = cTimeCol(nRow-1);

  // Retrieve positions for selected data.
  Int isel = 0;
  positions.resize(2,nSel);
  for (Int irow = 0; irow < nRow; irow++) {
    if (sel(irow)) {
      Matrix<Double> pointingDir = cPointingCol(cFieldIdCol(irow));
      positions.column(isel++) = pointingDir.column(0);
    }
  }

  return 0;
}

//--------------------------------------------------------- PKSMS2reader::read

// Read the next data record.

Int PKSMS2reader::read(
        Int             &scanNo,
        Int             &cycleNo,
        Double          &mjd,
        Double          &interval,
        String          &fieldName,
        String          &srcName,
        Vector<Double>  &srcDir,
        Vector<Double>  &srcPM,
        Double          &srcVel,
        String          &obsMode,
        Int             &IFno,
        Double          &refFreq,
        Double          &bandwidth,
        Double          &freqInc,
        Double          &restFreq,
        Vector<Float>   &tcal,
        String          &tcalTime,
        Float           &azimuth,
        Float           &elevation,
        Float           &parAngle,
        Float           &focusAxi,
        Float           &focusTan,
        Float           &focusRot,
        Float           &temperature,
        Float           &pressure,
        Float           &humidity,
        Float           &windSpeed,
        Float           &windAz,
        Int             &refBeam,
        Int             &beamNo,
        Vector<Double>  &direction,
        Vector<Double>  &scanRate,
        Vector<Float>   &tsys,
        Vector<Float>   &sigma,
        Vector<Float>   &calFctr,
        Matrix<Float>   &baseLin,
        Matrix<Float>   &baseSub,
        Matrix<Float>   &spectra,
        Matrix<uChar>   &flagged,
        Complex         &xCalFctr,
        Vector<Complex> &xPol)
{
  if (!cMSopen) {
    return 1;
  }

  // Check for EOF.
  if (cIdx >= cNRow) {
    return -1;
  }

  // Find the next selected beam and IF.
  Int ibeam;
  Int iIF;
  while (True) {
    ibeam = cBeamNoCol(cIdx);
    iIF   = cDataDescIdCol(cIdx);
    if (cBeams(ibeam) && cIFs(iIF)) {
      break;
    }

    // Check for EOF.
    if (++cIdx >= cNRow) {
      return -1;
    }
  }

  // Renumerate scan no. Here still is 1-based
  scanNo = cScanNoCol(cIdx) - cScanNoCol(0) + 1;

  if (scanNo != cScanNo) {
    // Start of new scan.
    cScanNo  = scanNo;
    cCycleNo = 1;
    cTime    = cTimeCol(cIdx);
  }

  Double time = cTimeCol(cIdx);
  mjd      = time/86400.0;
  interval = cIntervalCol(cIdx);

  // Reconstruct the integration cycle number; due to small latencies the
  // integration time is usually slightly less than the time between cycles,
  // resetting cTime will prevent the difference from accumulating.
  cCycleNo += nint((time - cTime)/interval);
  cycleNo = cCycleNo;
  cTime   = time;

  Int fieldId = cFieldIdCol(cIdx);
  fieldName = cFieldNameCol(fieldId);

  Int srcId = cSrcIdCol(fieldId);
  srcName = cSrcNameCol(srcId);
  srcDir  = cSrcDirCol(srcId);
  srcPM   = cSrcPMCol(srcId);

  // Systemic velocity.
  if (!cHaveSrcVel) {
    srcVel = 0.0f;
  } else {
    srcVel  = cSrcVelCol(srcId)(IPosition(1,0));
  }

  // Observation type.
  Int stateId = cStateIdCol(cIdx);
  obsMode = cObsModeCol(stateId);

  IFno = iIF + 1;
  Int nChan = abs(cEndChan(iIF) - cStartChan(iIF)) + 1;

  // Minimal handling on continuum data.
  Vector<Double> chanFreq = cChanFreqCol(iIF);
  if (nChan == 1) {
    cout << "The input is continuum data. "<< endl;
    freqInc  = chanFreq(0);
    refFreq  = chanFreq(0);
    restFreq = 0.0f;
  } else {
    if (cStartChan(iIF) <= cEndChan(iIF)) {
      freqInc = chanFreq(1) - chanFreq(0);
    } else {
      freqInc = chanFreq(0) - chanFreq(1);
    }

    refFreq  = chanFreq(cRefChan(iIF)-1);
    restFreq = cSrcRestFrqCol(srcId)(IPosition(1,0));
  }
  bandwidth = abs(freqInc * nChan);

  tcal.resize(cNPol(iIF));
  tcal      = 0.0f;
  tcalTime  = "";
  azimuth   = 0.0f;
  elevation = 0.0f;
  parAngle  = 0.0f;
  focusAxi  = 0.0f;
  focusTan  = 0.0f;
  focusRot  = 0.0f;

  // Find the appropriate entry in the WEATHER subtable.
  Vector<Double> wTimes = cWeatherTimeCol.getColumn();
  Int weatherIdx;
  for (weatherIdx = wTimes.nelements()-1; weatherIdx >= 0; weatherIdx--) {
    if (cWeatherTimeCol(weatherIdx) <= time) {
      break;
    }
  }

  if (weatherIdx < 0) {
    // No appropriate WEATHER entry.
    pressure    = 0.0f;
    humidity    = 0.0f;
    temperature = 0.0f;
  } else {
    pressure    = cPressureCol(weatherIdx);
    humidity    = cHumidityCol(weatherIdx);
    temperature = cTemperatureCol(weatherIdx);
  }

  windSpeed = 0.0f;
  windAz    = 0.0f;

  refBeam = 0;
  beamNo  = ibeam + 1;

  Matrix<Double> pointingDir = cPointingCol(fieldId);
  direction = pointingDir.column(0);
  uInt ncols = pointingDir.ncolumn();
  if (ncols == 1) {
    scanRate = 0.0f;
  } else {
    scanRate  = pointingDir.column(1);
  }

  // Get Tsys assuming that entries in the SYSCAL table match the main table.
  if (cHaveTsys) {
    Int nTsysColRow = cTsysCol.nrow();
    if (nTsysColRow != cNRow) {
      cHaveTsys=0;
    }
  }
  if (cHaveTsys) {
    cTsysCol.get(cIdx, tsys, True);
  } else {
    Int numReceptor;
    cNumReceptorCol.get(0, numReceptor);
    tsys.resize(numReceptor);
    tsys = 1.0f;
  }
  cSigmaCol.get(cIdx, sigma, True);

  // Calibration factors (if available).
  calFctr.resize(cNPol(iIF));
  if (cHaveCalFctr) {
    cCalFctrCol.get(cIdx, calFctr);
  } else {
    calFctr = 0.0f;
  }

  // Baseline parameters (if available).
  if (cHaveBaseLin) {
    baseLin.resize(2,cNPol(iIF));
    cBaseLinCol.get(cIdx, baseLin);

    baseSub.resize(9,cNPol(iIF));
    cBaseSubCol.get(cIdx, baseSub);

  } else {
    baseLin.resize(0,0);
    baseSub.resize(0,0);
  }


  // Get spectral data.
  if (cGetSpectra) {
    Matrix<Float> tmpData;
    Matrix<Bool>  tmpFlag;
    cFloatDataCol.getSlice(cIdx, cDataSel(iIF), tmpData, True);
    cFlagCol.getSlice(cIdx, cDataSel(iIF), tmpFlag, True);

    // Transpose spectra.
    Int nPol = tmpData.nrow();
    spectra.resize(nChan, nPol);
    flagged.resize(nChan, nPol);
    if (cEndChan(iIF) >= cStartChan(iIF)) {
      // Simple transposition.
      for (Int ipol = 0; ipol < nPol; ipol++) {
        for (Int ichan = 0; ichan < nChan; ichan++) {
          spectra(ichan,ipol) = tmpData(ipol,ichan);
          flagged(ichan,ipol) = tmpFlag(ipol,ichan);
        }
      }

    } else {
      // Transpose with inversion.
      Int jchan = nChan - 1;
      for (Int ipol = 0; ipol < nPol; ipol++) {
        for (Int ichan = 0; ichan < nChan; ichan++, jchan--) {
          spectra(ichan,ipol) = tmpData(ipol,jchan);
          flagged(ichan,ipol) = tmpFlag(ipol,jchan);
        }
      }
    }
  }

  // Get cross-polarization data.
  if (cGetXPol) {
    if (cHaveXCalFctr) {
      cXCalFctrCol.get(cIdx, xCalFctr);
    } else {
      xCalFctr = Complex(0.0f, 0.0f);
    }

    cDataCol.get(cIdx, xPol, True);

    if (cEndChan(iIF) < cStartChan(iIF)) {
      Complex ctmp;
      Int jchan = nChan - 1;
      for (Int ichan = 0; ichan < nChan/2; ichan++, jchan--) {
        ctmp = xPol(ichan);
        xPol(ichan) = xPol(jchan);
        xPol(jchan) = ctmp;
      }
    }
  }

  cIdx++;

  return 0;
}

//--------------------------------------------------------- PKSMS2reader::read

// Read the next data record, just the basics.

Int PKSMS2reader::read(
        Int           &IFno,
        Vector<Float> &tsys,
        Vector<Float> &calFctr,
        Matrix<Float> &baseLin,
        Matrix<Float> &baseSub,
        Matrix<Float> &spectra,
        Matrix<uChar> &flagged)
{
  if (!cMSopen) {
    return 1;
  }

  // Check for EOF.
  if (cIdx >= cNRow) {
    return -1;
  }

  // Find the next selected beam and IF.
  Int ibeam;
  Int iIF;
  while (True) {
    ibeam = cBeamNoCol(cIdx);
    iIF   = cDataDescIdCol(cIdx);
    if (cBeams(ibeam) && cIFs(iIF)) {
      break;
    }

    // Check for EOF.
    if (++cIdx >= cNRow) {
      return -1;
    }
  }

  IFno = iIF + 1;

  // Get Tsys assuming that entries in the SYSCAL table match the main table.
  cTsysCol.get(cIdx, tsys, True);

  // Calibration factors (if available).
  if (cHaveCalFctr) {
    cCalFctrCol.get(cIdx, calFctr, True);
  } else {
    calFctr.resize(cNPol(iIF));
    calFctr = 0.0f;
  }

  // Baseline parameters (if available).
  if (cHaveBaseLin) {
    baseLin.resize(2,cNPol(iIF));
    cBaseLinCol.get(cIdx, baseLin);

    baseSub.resize(9,cNPol(iIF));
    cBaseSubCol.get(cIdx, baseSub);

  } else {
    baseLin.resize(0,0);
    baseSub.resize(0,0);
  }

  if (cGetSpectra) {
    // Get spectral data.
    Matrix<Float> tmpData;
    Matrix<Bool>  tmpFlag;
    cFloatDataCol.getSlice(cIdx, cDataSel(iIF), tmpData, True);
    cFlagCol.getSlice(cIdx, cDataSel(iIF), tmpFlag, True);

    // Transpose spectra.
    Int nChan = tmpData.ncolumn();
    Int nPol  = tmpData.nrow();
    spectra.resize(nChan, nPol);
    flagged.resize(nChan, nPol);
    if (cEndChan(iIF) >= cStartChan(iIF)) {
      // Simple transposition.
      for (Int ipol = 0; ipol < nPol; ipol++) {
        for (Int ichan = 0; ichan < nChan; ichan++) {
          spectra(ichan,ipol) = tmpData(ipol,ichan);
          flagged(ichan,ipol) = tmpFlag(ipol,ichan);
        }
      }

    } else {
      // Transpose with inversion.
      Int jchan = nChan - 1;
      for (Int ipol = 0; ipol < nPol; ipol++) {
        for (Int ichan = 0; ichan < nChan; ichan++, jchan--) {
          spectra(ichan,ipol) = tmpData(ipol,jchan);
          flagged(ichan,ipol) = tmpFlag(ipol,jchan);
        }
      }
    }
  }

  cIdx++;

  return 0;
}

//-------------------------------------------------------- PKSMS2reader::close

// Close the MS.

void PKSMS2reader::close()
{
  cPKSMS = MeasurementSet();
  cMSopen = False;
}
