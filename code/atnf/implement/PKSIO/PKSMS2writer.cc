//#---------------------------------------------------------------------------
//# PKSMS2writer.cc: Class to write Parkes multibeam data to a measurementset.
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
//# $Id: PKSMS2writer.cc,v 19.10 2006/07/05 05:50:45 mcalabre Exp $
//#---------------------------------------------------------------------------

#include <atnf/PKSIO/PKSMS2writer.h>

#include <casa/Arrays/ArrayUtil.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/Cube.h>
#include <casa/BasicSL/Complex.h>
#include <casa/BasicSL/Constants.h>
#include <casa/Quanta/QC.h>
#include <measures/Measures/Stokes.h>
#include <tables/Tables/ArrColDesc.h>
#include <tables/Tables/IncrementalStMan.h>
#include <tables/Tables/ScaColDesc.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/StandardStMan.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/TiledShapeStMan.h>

//------------------------------------------------- PKSMS2writer::PKSMS2writer

// Default constructor.

PKSMS2writer::PKSMS2writer()
{
}

//------------------------------------------------ PKSMS2writer::~PKSMS2writer

// Destructor.

PKSMS2writer::~PKSMS2writer()
{
  close();
}

//------------------------------------------------------- PKSMS2writer::create

// Create the output MS and and write static data.

Int PKSMS2writer::create(
        const String msName,
        const String observer,
        const String project,
        const String antName,
        const Vector<Double> antPosition,
        const String obsMode,
        const Float  equinox,
        const String dopplerFrame,
        const Vector<uInt> nChan,
        const Vector<uInt> nPol,
        const Vector<Bool> haveXPol,
        const Bool   haveBase)
{
  // Open a MS table.
  TableDesc pksDesc = MS::requiredTableDesc();

  cNChan.assign(nChan);
  cNPol.assign(nPol);
  cHaveXPol.assign(haveXPol);

  Int maxNPol = max(cNPol);


  // Add the non-standard CALFCTR column.
  pksDesc.addColumn(ArrayColumnDesc<Float>("CALFCTR", "Calibration factors",
              IPosition(1,maxNPol), ColumnDesc::Direct));

  // Add the optional FLOAT_DATA column.
  MS::addColumnToDesc(pksDesc, MS::FLOAT_DATA, 2);
  pksDesc.rwColumnDesc(MS::columnName(MS::FLOAT_DATA)).rwKeywordSet().
                define("UNIT", String("Jy"));
  pksDesc.rwColumnDesc(MS::columnName(MS::FLOAT_DATA)).rwKeywordSet().
                define("MEASURE_TYPE", "");

  if ((cHaveBase = haveBase)) {
    // Add the non-standard BASELIN and BASESUB columns.
    pksDesc.addColumn(ArrayColumnDesc<Float>("BASELIN", "Linear baseline fit",
                IPosition(2,2,maxNPol), ColumnDesc::Direct));
    pksDesc.addColumn(ArrayColumnDesc<Float>("BASESUB", "Baseline subtracted",
                IPosition(2,9,maxNPol), ColumnDesc::Direct));
  }

  // Add the optional DATA column if cross-polarizations are to be recorded.
  if (ntrue(cHaveXPol)) {
    // Add the non-standard XCALFCTR column.
    pksDesc.addColumn(ScalarColumnDesc<Complex>("XCALFCTR",
                "Cross-polarization calibration factor"));

    MS::addColumnToDesc(pksDesc, MS::DATA, 2);
    pksDesc.rwColumnDesc(MS::columnName(MS::DATA)).rwKeywordSet().
                define("UNIT", "Jy");
    pksDesc.rwColumnDesc(MS::columnName(MS::DATA)).rwKeywordSet().
                define("MEASURE_TYPE", "");
  }

  // Define hypercube for the float data (without coordinates).
  pksDesc.defineHypercolumn("TiledData", 3,
                stringToVector(MS::columnName(MS::FLOAT_DATA)));

  SetupNewTable newtab(msName, pksDesc, Table::New);

  // Set Incremental Storage Manager as the default.
  IncrementalStMan incrStMan("ISMData");
  newtab.bindAll(incrStMan, True);

  // Use TiledShapeStMan for the FLOAT_DATA hypercube with tile size 16 kiB.
  TiledShapeStMan tiledStMan("TiledData", IPosition(3,1,128,32));
  newtab.bindColumn(MS::columnName(MS::FLOAT_DATA), tiledStMan);

  // Use Standard Storage Manager to handle columns that change for each row.
  StandardStMan stdStMan;
  newtab.bindColumn(MS::columnName(MS::SCAN_NUMBER), stdStMan);
  newtab.bindColumn(MS::columnName(MS::TIME), stdStMan);
  newtab.bindColumn(MS::columnName(MS::SIGMA), stdStMan);
  if (maxNPol > 2) {
    newtab.bindColumn(MS::columnName(MS::DATA), stdStMan);
  }

  // Create the measurementset.
  cPKSMS = new MeasurementSet(newtab, 0);

  // Create subtables.
  TableDesc antennaDesc = MSAntenna::requiredTableDesc();
  SetupNewTable antennaSetup(cPKSMS->antennaTableName(), antennaDesc,
                Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::ANTENNA),
                Table(antennaSetup));

  TableDesc dataDescDesc = MSDataDescription::requiredTableDesc();
  SetupNewTable dataDescSetup(cPKSMS->dataDescriptionTableName(), dataDescDesc,
                Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::DATA_DESCRIPTION),
                Table(dataDescSetup));

  TableDesc dopplerDesc = MSDoppler::requiredTableDesc();
  SetupNewTable dopplerSetup(cPKSMS->dopplerTableName(), dopplerDesc,
                Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::DOPPLER),
                Table(dopplerSetup));

  TableDesc feedDesc = MSFeed::requiredTableDesc();
  MSFeed::addColumnToDesc(feedDesc, MSFeedEnums::FOCUS_LENGTH);
  SetupNewTable feedSetup(cPKSMS->feedTableName(), feedDesc, Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::FEED),
                Table(feedSetup));

  TableDesc fieldDesc = MSField::requiredTableDesc();
  SetupNewTable fieldSetup(cPKSMS->fieldTableName(), fieldDesc, Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::FIELD),
                Table(fieldSetup));

  TableDesc flagCmdDesc = MSFlagCmd::requiredTableDesc();
  SetupNewTable flagCmdSetup(cPKSMS->flagCmdTableName(), flagCmdDesc,
                Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::FLAG_CMD),
                Table(flagCmdSetup));

  TableDesc historyDesc = MSHistory::requiredTableDesc();
  SetupNewTable historySetup(cPKSMS->historyTableName(), historyDesc,
                Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::HISTORY),
                Table(historySetup));

  TableDesc observationDesc = MSObservation::requiredTableDesc();
  SetupNewTable observationSetup(cPKSMS->observationTableName(),
                observationDesc, Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::OBSERVATION),
                Table(observationSetup));

  TableDesc pointingDesc = MSPointing::requiredTableDesc();
  SetupNewTable pointingSetup(cPKSMS->pointingTableName(), pointingDesc,
                Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::POINTING),
                Table(pointingSetup));

  TableDesc polarizationDesc = MSPolarization::requiredTableDesc();
  SetupNewTable polarizationSetup(cPKSMS->polarizationTableName(),
                polarizationDesc, Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::POLARIZATION),
                Table(polarizationSetup));

  TableDesc processorDesc = MSProcessor::requiredTableDesc();
  SetupNewTable processorSetup(cPKSMS->processorTableName(), processorDesc,
                Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::PROCESSOR),
                Table(processorSetup));

  TableDesc sourceDesc = MSSource::requiredTableDesc();
  MSSource::addColumnToDesc(sourceDesc, MSSourceEnums::TRANSITION, 1);
  MSSource::addColumnToDesc(sourceDesc, MSSourceEnums::REST_FREQUENCY,
                1);
  MSSource::addColumnToDesc(sourceDesc, MSSourceEnums::SYSVEL, 1);
  SetupNewTable sourceSetup(cPKSMS->sourceTableName(), sourceDesc,
                Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::SOURCE),
                Table(sourceSetup));

  TableDesc spectralWindowDesc = MSSpectralWindow::requiredTableDesc();
  MSSpectralWindow::addColumnToDesc(spectralWindowDesc,
                MSSpectralWindowEnums::DOPPLER_ID);
  SetupNewTable spectralWindowSetup(cPKSMS->spectralWindowTableName(),
                spectralWindowDesc, Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::SPECTRAL_WINDOW),
                Table(spectralWindowSetup));

  TableDesc stateDesc = MSState::requiredTableDesc();
  SetupNewTable stateSetup(cPKSMS->stateTableName(), stateDesc, Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::STATE),
                Table(stateSetup));

  TableDesc sysCalDesc = MSSysCal::requiredTableDesc();
  MSSysCal::addColumnToDesc(sysCalDesc, MSSysCalEnums::TCAL, 1);
  MSSysCal::addColumnToDesc(sysCalDesc, MSSysCalEnums::TSYS, 1);
  SetupNewTable sysCalSetup(cPKSMS->sysCalTableName(), sysCalDesc,
                Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::SYSCAL),
                Table(sysCalSetup));

  TableDesc weatherDesc = MSWeather::requiredTableDesc();
  MSWeather::addColumnToDesc(weatherDesc, MSWeatherEnums::PRESSURE);
  MSWeather::addColumnToDesc(weatherDesc, MSWeatherEnums::REL_HUMIDITY);
  MSWeather::addColumnToDesc(weatherDesc, MSWeatherEnums::TEMPERATURE);
  SetupNewTable weatherSetup(cPKSMS->weatherTableName(), weatherDesc,
                Table::New);
  cPKSMS->rwKeywordSet().defineTable(MS::keywordName(MS::WEATHER),
                Table(weatherSetup));

  cPKSMS->initRefs();

  // Measurementset subtables.
  cAntenna         = cPKSMS->antenna();
  cDataDescription = cPKSMS->dataDescription();
  cDoppler         = cPKSMS->doppler();
  cFeed            = cPKSMS->feed();
  cField           = cPKSMS->field();
  cFlagCmd         = cPKSMS->flagCmd();
  cHistory         = cPKSMS->history();
  cObservation     = cPKSMS->observation();
  cPointing        = cPKSMS->pointing();
  cPolarization    = cPKSMS->polarization();
  cProcessor       = cPKSMS->processor();
  cSource          = cPKSMS->source();
  cSpectralWindow  = cPKSMS->spectralWindow();
  cState           = cPKSMS->state();
  cSysCal          = cPKSMS->sysCal();
  cWeather         = cPKSMS->weather();

  // Measurementset table columns;
  cMSCols           = new MSColumns(*cPKSMS);
  cAntennaCols      = new MSAntennaColumns(cAntenna);
  cDataDescCols     = new MSDataDescColumns(cDataDescription);
  cDopplerCols      = new MSDopplerColumns(cDoppler);
  cFeedCols         = new MSFeedColumns(cFeed);
  cFieldCols        = new MSFieldColumns(cField);
  cFlagCmdCols      = new MSFlagCmdColumns(cFlagCmd);
  cHistoryCols      = new MSHistoryColumns(cHistory);
  cObservationCols  = new MSObservationColumns(cObservation);
  cPointingCols     = new MSPointingColumns(cPointing);
  cPolarizationCols = new MSPolarizationColumns(cPolarization);
  cProcessorCols    = new MSProcessorColumns(cProcessor);
  cSourceCols       = new MSSourceColumns(cSource);
  cSpWindowCols     = new MSSpWindowColumns(cSpectralWindow);
  cStateCols        = new MSStateColumns(cState);
  cSysCalCols       = new MSSysCalColumns(cSysCal);
  cWeatherCols      = new MSWeatherColumns(cWeather);

  cCalFctrCol  = new ArrayColumn<Float>(*cPKSMS, "CALFCTR");
  if (cHaveBase) {
    cBaseLinCol = new ArrayColumn<Float>(*cPKSMS, "BASELIN");
    cBaseSubCol = new ArrayColumn<Float>(*cPKSMS, "BASESUB");
  }
  if (ntrue(cHaveXPol)) {
    cXCalFctrCol = new ScalarColumn<Complex>(*cPKSMS, "XCALFCTR");
  }


  // Define Measure references.
  Vector<String> flagCat(1, "BAD");
  cMSCols->sigma().rwKeywordSet().define("UNIT", "K");
  cMSCols->flagCategory().rwKeywordSet().define("CATEGORY", flagCat);

  String dirref;
  if (equinox == 1950.0f) {
    dirref = "B1950";
  } else {
    dirref = "J2000";
  }

  cFieldCols->delayDir().rwKeywordSet().asrwRecord("MEASINFO").
                 define("Ref", dirref);
  cFieldCols->phaseDir().rwKeywordSet().asrwRecord("MEASINFO").
                 define("Ref", dirref);
  cFieldCols->referenceDir().rwKeywordSet().asrwRecord("MEASINFO").
                 define("Ref", dirref);

  cPointingCols->direction().rwKeywordSet().asrwRecord("MEASINFO").
                 define("Ref", dirref);
  cPointingCols->target().rwKeywordSet().asrwRecord("MEASINFO").
                 define("Ref", dirref);

  cSourceCols->direction().rwKeywordSet().asrwRecord("MEASINFO").
                 define("Ref", dirref);
  cSourceCols->restFrequency().rwKeywordSet().asrwRecord("MEASINFO").
                 define("Ref", "REST");

  // Translate Doppler frame name.
  if (dopplerFrame == "TOPOCENT") {
    MFrequency::getType(cDopplerFrame, "TOPO");
  } else if (dopplerFrame == "GEOCENTR") {
    MFrequency::getType(cDopplerFrame, "GEO");
  } else if (dopplerFrame == "BARYCENT") {
    MFrequency::getType(cDopplerFrame, "BARY");
  } else if (dopplerFrame == "GALACTOC") {
    MFrequency::getType(cDopplerFrame, "GALACTO");
  } else if (dopplerFrame == "LOCALGRP") {
    MFrequency::getType(cDopplerFrame, "LGROUP");
  } else if (dopplerFrame == "CMBDIPOL") {
    MFrequency::getType(cDopplerFrame, "CMB");
  } else if (dopplerFrame == "SOURCE") {
    MFrequency::getType(cDopplerFrame, "REST");
  }


  // Store static data.
  addAntennaEntry(antName, antPosition);
  addDopplerEntry();
  addFeedEntry();
  addObservationEntry(observer, project);
  addProcessorEntry();

  return 0;
}

//-------------------------------------------------------- PKSMS2writer::write

// Write the next data record.

Int PKSMS2writer::write(
        const Int             scanNo,
        const Int             cycleNo,
        const Double          mjd,
        const Double          interval,
        const String          fieldName,
        const String          srcName,
        const Vector<Double>  srcDir,
        const Vector<Double>  srcPM,
        const Double          srcVel,
        const String          obsMode,
        const Int             IFno,
        const Double          refFreq,
        const Double          bandwidth,
        const Double          freqInc,
        const Double          restFreq,
        const Vector<Float>   tcal,
        const String          tcalTime,
        const Float           azimuth,
        const Float           elevation,
        const Float           parAngle,
        const Float           focusAxi,
        const Float           focusTan,
        const Float           focusRot,
        const Float           temperature,
        const Float           pressure,
        const Float           humidity,
        const Float           windSpeed,
        const Float           windAz,
        const Int             refBeam,
        const Int             beamNo,
        const Vector<Double>  direction,
        const Vector<Double>  scanRate,
        const Vector<Float>   tsys,
        const Vector<Float>   sigma,
        const Vector<Float>   calFctr,
        const Matrix<Float>   baseLin,
        const Matrix<Float>   baseSub,
        const Matrix<Float>   &spectra,
        const Matrix<uChar>   &flagged,
        const Complex         xCalFctr,
        const Vector<Complex> &xPol)
{
  // Extend the time range in the OBSERVATION subtable.
  Vector<Double> timerange(2);
  cObservationCols->timeRange().get(0, timerange);
  Double time = mjd*86400.0;
  if (timerange(0) == 0.0) {
    timerange(0) = time;
  }
  timerange(1) = time;
  cObservationCols->timeRange().put(0, timerange);

  Int iIF = IFno - 1;
  Int nChan = cNChan(iIF);
  Int nPol  = cNPol(iIF);

  // IFno is the 1-relative row number in the DATA_DESCRIPTION,
  // SPECTRAL_WINDOW, and POLARIZATION subtables.
  if (Int(cDataDescription.nrow()) < IFno) {
    // Add a new entry to each subtable.
    addDataDescriptionEntry(IFno);
    addSpectralWindowEntry(IFno, nChan, refFreq, bandwidth, freqInc);
    addPolarizationEntry(IFno, nPol);
  }

  // Find or add the source to the SOURCE subtable.
  Int srcId = addSourceEntry(srcName, srcDir, srcPM, restFreq, srcVel);

  // Find or add the obsMode to the STATE subtable.
  Int stateId = addStateEntry(obsMode);

  // FIELD subtable.
  Int fieldId = addFieldEntry(fieldName, time, direction, scanRate, srcId);

  // POINTING subtable.
  addPointingEntry(time, interval, fieldName, direction, scanRate);

  // SYSCAL subtable.
  addSysCalEntry(beamNo, iIF, time, interval, tcal, tsys);

  // Handle weather information.
  ROScalarColumn<Double> wTime(cWeather, "TIME");
  Int nWeather = wTime.nrow();
  if (nWeather == 0 || time > wTime(nWeather-1)) {
    addWeatherEntry(time, interval, pressure, humidity, temperature);
  }


  // Extend the main table.
  cPKSMS->addRow();
  Int irow = cPKSMS->nrow() - 1;

  // Keys.
  cMSCols->time().put(irow, time);
  cMSCols->antenna1().put(irow, 0);
  cMSCols->antenna2().put(irow, 0);
  cMSCols->feed1().put(irow, beamNo-1);
  cMSCols->feed2().put(irow, beamNo-1);
  cMSCols->dataDescId().put(irow, iIF);
  cMSCols->processorId().put(irow, 0);
  cMSCols->fieldId().put(irow, fieldId);

  // Non-key attributes.
  cMSCols->interval().put(irow, interval);
  cMSCols->exposure().put(irow, interval);
  cMSCols->timeCentroid().put(irow, time);
  cMSCols->scanNumber().put(irow, scanNo);
  cMSCols->arrayId().put(irow, 0);
  cMSCols->observationId().put(irow, 0);
  cMSCols->stateId().put(irow, stateId);

  Vector<Double> uvw(3, 0.0);
  cMSCols->uvw().put(irow, uvw);

  // Baseline fit parameters.
  if (cHaveBase) {
    cBaseLinCol->put(irow, baseLin);

    if (baseSub.nrow() == 9) {
      cBaseSubCol->put(irow, baseSub);

    } else {
      Matrix<Float> tmp(9, 2, 0.0f);
      for (Int ipol = 0; ipol < nPol; ipol++) {
        for (uInt j = 0; j < baseSub.nrow(); j++) {
          tmp(j,ipol) = baseSub(j,ipol);
        }
      }
      cBaseSubCol->put(irow, tmp);
    }
  }

  // Transpose spectra.
  Matrix<Float> tmpData(nPol, nChan);
  Matrix<Bool>  tmpFlag(nPol, nChan);
  for (Int ipol = 0; ipol < nPol; ipol++) {
    for (Int ichan = 0; ichan < nChan; ichan++) {
      tmpData(ipol,ichan) = spectra(ichan,ipol);
      tmpFlag(ipol,ichan) = flagged(ichan,ipol);
    }
  }

  cCalFctrCol->put(irow, calFctr);
  cMSCols->floatData().put(irow, tmpData);
  cMSCols->flag().put(irow, tmpFlag);

  // Cross-polarization spectra.
  if (cHaveXPol(iIF)) {
    cXCalFctrCol->put(irow, xCalFctr);
    cMSCols->data().put(irow, xPol);
  }

  cMSCols->sigma().put(irow, sigma);

  Vector<Float> weight(1, 1.0f);
  cMSCols->weight().put(irow, weight);

  // Flag information.
  Cube<Bool> flags(nPol, nChan, 1, False);
  cMSCols->flag().put(irow, flags.xyPlane(0));
  cMSCols->flagCategory().put(irow, flags);
  cMSCols->flagRow().put(irow, False);

  return 0;
}

//-------------------------------------------------------- PKSMS2writer::close

// Close the measurementset, flushing all associated tables.

void PKSMS2writer::close()
{
  // Delete table column accessors.
  delete cMSCols;
  delete cAntennaCols;
  delete cDataDescCols;
  delete cDopplerCols;
  delete cFeedCols;
  delete cFieldCols;
  delete cFlagCmdCols;
  delete cHistoryCols;
  delete cObservationCols;
  delete cPointingCols;
  delete cPolarizationCols;
  delete cProcessorCols;
  delete cSourceCols;
  delete cSpWindowCols;
  delete cStateCols;
  delete cSysCalCols;
  delete cWeatherCols;

  delete cCalFctrCol;
  if (cHaveBase) {
    delete cBaseLinCol;
    delete cBaseSubCol;
  }
  if (ntrue(cHaveXPol)) {
    delete cXCalFctrCol;
  }

  // Release all subtables.
  cAntenna         = MSAntenna();
  cDataDescription = MSDataDescription();
  cDoppler         = MSDoppler();
  cFeed            = MSFeed();
  cField           = MSField();
  cFlagCmd         = MSFlagCmd();
  cHistory         = MSHistory();
  cObservation     = MSObservation();
  cPointing        = MSPointing();
  cPolarization    = MSPolarization();
  cProcessor       = MSProcessor();
  cSource          = MSSource();
  cSpectralWindow  = MSSpectralWindow();
  cState           = MSState();
  cSysCal          = MSSysCal();
  cWeather         = MSWeather();

  // Release the main table.
  delete cPKSMS;
}

//---------------------------------------------- PKSMS2writer::addAntennaEntry

// Add an entry to the ANTENNA subtable.

Int PKSMS2writer::addAntennaEntry(
        const String antName,
        const Vector<Double> &antPosition)
{
  // Extend the ANTENNA subtable.
  cAntenna.addRow();
  Int n = cAntenna.nrow() - 1;

  // Data.
  cAntennaCols->name().put(n, antName);
  cAntennaCols->station().put(n, "ATNF_PARKES");
  cAntennaCols->type().put(n, "GROUND-BASED");
  cAntennaCols->mount().put(n, "ALT-AZ");
  cAntennaCols->position().put(n, antPosition);
  Vector<Double> antOffset(3, 0.0);
  cAntennaCols->offset().put(n, antOffset);
  cAntennaCols->dishDiameter().put(n, 64.0);

  // Flags.
  cAntennaCols->flagRow().put(n, False);

  return n;
}

//-------------------------------------- PKSMS2writer::addDataDescriptionEntry

// Add an entry to the DATA_DESCRIPTION subtable.

Int PKSMS2writer::addDataDescriptionEntry(
        const Int IFno)
{
  // Extend the DATA_DESCRIPTION subtable.
  while (Int(cDataDescription.nrow()) < IFno) {
    cDataDescription.addRow();
  }
  Int n = IFno - 1;

  // Data.
  cDataDescCols->spectralWindowId().put(n, n);
  cDataDescCols->polarizationId().put(n, n);

  // Flags.
  cDataDescCols->flagRow().put(n, False);

  return n;
}

//---------------------------------------------- PKSMS2writer::addDopplerEntry

// Add an entry to the DOPPLER subtable.

Int PKSMS2writer::addDopplerEntry()
{
  // Extend the DOPPLER subtable.
  cDoppler.addRow();
  Int n = cDoppler.nrow() - 1;

  // Keys.
  cDopplerCols->dopplerId().put(n, n);
  cDopplerCols->sourceId().put(n, 0);

  // Data.
  cDopplerCols->transitionId().put(n, 0);

  return n;
}

//------------------------------------------------- PKSMS2writer::addFeedEntry

// Add an entry to the FEED subtable.

Int PKSMS2writer::addFeedEntry()
{
  Int n = cFeed.nrow() - 1;
  for (Int iBeam = 0; iBeam < 13; iBeam++) {
    // Extend the FEED subtable.
    cFeed.addRow();
    n++;

    // Keys.
    cFeedCols->antennaId().put(n, cAntenna.nrow()-1);
    cFeedCols->feedId().put(n, iBeam);
    cFeedCols->spectralWindowId().put(n, -1);
    cFeedCols->time().put(n, 0.0);
    cFeedCols->interval().put(n, -1.0);

    // Data description.
    cFeedCols->numReceptors().put(n, 2);

    // Data.
    cFeedCols->beamId().put(n, -1);

    Matrix<Double> beamOffset(2, 2, 0.0);
    cFeedCols->beamOffset().put(n, beamOffset);

    cFeedCols->focusLength().put(n, 26.0);

    Vector<String> polarizationType(2);
    polarizationType(0) = "X";
    polarizationType(1) = "Y";
    cFeedCols->polarizationType().put(n, polarizationType);

    Matrix<Complex> polResponse(2, 2, Complex(0.0));
    for (Int i = 0; i < 2; i++) {
      polResponse(i,i) = Complex(1.0, 0.0);
    }
    cFeedCols->polResponse().put(n, polResponse);

    Vector<Double> position(3, 0.0);
    cFeedCols->position().put(n, position);

    Vector<Double> receptorAngle(2, C::pi_4);
    receptorAngle(1) += C::pi_2;
    cFeedCols->receptorAngle().put(n, receptorAngle);
  }

  return n;
}

//------------------------------------------------ PKSMS2writer::addFieldEntry

// Add an entry to the FIELD subtable.

Int PKSMS2writer::addFieldEntry(
        const String fieldName,
        const Double time,
        const Vector<Double> direction,
        const Vector<Double> scanRate,
        const Int srcId)
{
  // Extend the FIELD subtable.
  cField.addRow();
  Int n = cField.nrow() - 1;

  // Data.
  cFieldCols->name().put(n, fieldName);
  cFieldCols->code().put(n, "DRIFT");
  cFieldCols->time().put(n, time);

  Matrix<Double> track(2, 2);
  track.column(0) = direction;
  track.column(1) = scanRate;
  cFieldCols->numPoly().put(n, 1);
  cFieldCols->delayDir().put(n, track);
  cFieldCols->phaseDir().put(n, track);
  cFieldCols->referenceDir().put(n, track);
  cFieldCols->sourceId().put(n, srcId);

  // Flags.
  cFieldCols->flagRow().put(n, False);

  return n;
}

//------------------------------------------ PKSMS2writer::addObservationEntry

// Add an entry to the OBSERVATION subtable.

Int PKSMS2writer::addObservationEntry(
        const String observer,
        const String project)
{
  // Extend the OBSERVATION subtable.
  cObservation.addRow();
  Int n = cObservation.nrow() - 1;

  // Data.
  cObservationCols->telescopeName().put(n, "Parkes");
  Vector<Double> timerange(2, 0.0);
  cObservationCols->timeRange().put(n, timerange);
  cObservationCols->observer().put(n, observer);
  Vector<String> log(1, "none");
  cObservationCols->log().put(n, log);
  cObservationCols->scheduleType().put(n, "ATNF");
  Vector<String> schedule(1, "Not available");
  cObservationCols->schedule().put(n, schedule);
  cObservationCols->project().put(n, project);
  cObservationCols->releaseDate().put(n, 0.0);

  // Flags.
  cObservationCols->flagRow().put(n, False);

  return n;
}

//--------------------------------------------- PKSMS2writer::addPointingEntry

// Add an entry to the POINTING subtable.  This compulsory subtable simply
// duplicates information in the FIELD subtable.

Int PKSMS2writer::addPointingEntry(
        const Double time,
        const Double interval,
        const String fieldName,
        const Vector<Double> direction,
        const Vector<Double> scanRate)
{
  // Extend the POINTING subtable.
  cPointing.addRow();
  Int n = cPointing.nrow() - 1;

  // Keys.
  cPointingCols->antennaId().put(n, 0);
  cPointingCols->time().put(n, time);
  cPointingCols->interval().put(n, interval);

  // Data.
  cPointingCols->name().put(n, fieldName);
  cPointingCols->numPoly().put(n, 1);
  cPointingCols->timeOrigin().put(n, time);

  Matrix<Double> track(2, 2);
  track.column(0) = direction;
  track.column(1) = scanRate;
  cPointingCols->direction().put(n, track);
  cPointingCols->target().put(n, track);
  cPointingCols->tracking().put(n, True);

  return n;
}

//----------------------------------------- PKSMS2writer::addPolarizationEntry

// Add an entry to the POLARIZATION subtable.

Int PKSMS2writer::addPolarizationEntry(
        const Int IFno,
        const Int nPol)
{
  // Extend the POLARIZATION subtable.
  while (Int(cPolarization.nrow()) < IFno) {
    cPolarization.addRow();
  }
  Int n = IFno - 1;

  // Data description.
  cPolarizationCols->numCorr().put(n, nPol);

  // Data.
  Vector<Int> corrType(2);
  corrType(0) = Stokes::XX;
  corrType(1) = Stokes::YY;
  cPolarizationCols->corrType().put(n, corrType);

  Matrix<Int> corrProduct(2,2,1);
  if (nPol == 2) {
    corrProduct(1,0) = 0;
    corrProduct(0,1) = 0;
  }
  cPolarizationCols->corrProduct().put(n, corrProduct);

  // Flags.
  cPolarizationCols->flagRow().put(n, False);

  return n;
}


//-------------------------------------------- PKSMS2writer::addProcessorEntry

// Add an entry to the PROCESSOR subtable.

Int PKSMS2writer::addProcessorEntry()
{
  // Extend the PROCESSOR subtable.
  cProcessor.addRow();
  Int n = cProcessor.nrow() - 1;

  // Data.
  cProcessorCols->type().put(n, "SPECTROMETER");
  cProcessorCols->subType().put(n, "MULTIBEAM");
  cProcessorCols->typeId().put(n, -1);
  cProcessorCols->modeId().put(n, -1);

  // Flags.
  cProcessorCols->flagRow().put(n, False);

  return n;
}

//----------------------------------------------- PKSMS2writer::addSourceEntry

// Add an entry to the SOURCE subtable.

Int PKSMS2writer::addSourceEntry(
        const String name,
        const Vector<Double> direction,
        const Vector<Double> properMotion,
        const Double restFreq,
        const Double radialVelocity)
{
  // Look for an entry in the SOURCE subtable.
  ROScalarColumn<String> sources(cSource, "NAME");
  Int n;
  Int nSrc = sources.nrow();
  for (n = 0; n < nSrc; n++) {
    if (sources(n) == name) {
      break;
    }
  }

  if (n == nSrc) {
    // Not found, add a new entry to the SOURCE subtable.
    cSource.addRow();

    // Keys.
    cSourceCols->sourceId().put(n, n);
    cSourceCols->time().put(n, 0.0);
    cSourceCols->interval().put(n, -1.0);
    cSourceCols->spectralWindowId().put(n, -1);

    // Data description.
    cSourceCols->numLines().put(n, 1);

    // Data.
    cSourceCols->name().put(n, name);
    cSourceCols->calibrationGroup().put(n, 0);
    cSourceCols->code().put(n, "");
    cSourceCols->direction().put(n, direction);
//  Vector<Double> position(3, 0.0);
//  cSourceCols->position().put(n, position);
    cSourceCols->properMotion().put(n, properMotion);
    Vector<Double> restFrequency(1, restFreq);
    cSourceCols->restFrequency().put(n, restFrequency);
    Vector<Double> sysvel(1, radialVelocity);
    cSourceCols->sysvel().put(n, sysvel);
  }

  return n;
}

//--------------------------------------- PKSMS2writer::addSpectralWindowEntry

// Add an entry to the SPECTRAL_WINDOW subtable.

Int PKSMS2writer::addSpectralWindowEntry(
        const Int IFno,
        const Int nChan,
        const Double refFreq,
        const Double bandwidth,
        const Double freqInc)
{
  // Extend the SPECTRAL_WINDOW subtable.
  while (Int(cSpectralWindow.nrow()) < IFno) {
    cSpectralWindow.addRow();
  }
  Int n = IFno - 1;

  // Data description.
  cSpWindowCols->numChan().put(n, nChan);

  // Data.
  cSpWindowCols->name().put(n, "L-band");
  cSpWindowCols->refFrequency().put(n, refFreq);

  // 0-relative reference channel number.
  Double refChan = nChan / 2;
  Vector<Double> freqs(nChan);
  for (Int i = 0; i < nChan; i++) {
    freqs(i) = refFreq + (i - refChan)*freqInc;
  }
  cSpWindowCols->chanFreq().put(n, freqs);

  Vector<Double> chanWidths(nChan, freqInc);
  cSpWindowCols->chanWidth().put(n, chanWidths);

  cSpWindowCols->measFreqRef().put(n, cDopplerFrame);
  cSpWindowCols->effectiveBW().put(n, chanWidths);

  Vector<Double> resolution(nChan, fabs(freqInc));
  cSpWindowCols->resolution().put(n, resolution);

  cSpWindowCols->totalBandwidth().put(n, bandwidth);
  cSpWindowCols->netSideband().put(n, 0);
  cSpWindowCols->ifConvChain().put(n, -1);
  cSpWindowCols->freqGroup().put(n, 0);
  cSpWindowCols->freqGroupName().put(n, " ");
  cSpWindowCols->dopplerId().put(n, 0);

  // Flags.
  cSpWindowCols->flagRow().put(n, False);

  return n;
}

//------------------------------------------------ PKSMS2writer::addStateEntry

// Add an entry to the STATE subtable.

Int PKSMS2writer::addStateEntry(
        const String obsMode)
{
  // Look for an entry in the STATE subtable.
  for (uInt n = 0; n < cStateCols->nrow(); n++) {
    if (cStateCols->obsMode()(n) == obsMode) {
      return n;
    }
  }

  // Not found, extend the STATE subtable.
  cState.addRow();
  uInt n = cStateCols->nrow() - 1;

  // Data.
  if (obsMode.contains("RF")) {
    cStateCols->sig().put(n, False);
    cStateCols->ref().put(n, True);
  } else if (!obsMode.contains("PA")) {
    // Signal and reference are both false for "paddle" data.
    cStateCols->sig().put(n, True);
    cStateCols->ref().put(n, False);
  }

  cStateCols->load().put(n, 0.0);
  cStateCols->cal().put(n, 0.0);
  cStateCols->subScan().put(n, 0);
  cStateCols->obsMode().put(n, obsMode);

  // Flags.
  cStateCols->flagRow().put(n, False);

  return n;
}

//----------------------------------------------- PKSMS2writer::addSysCalEntry

// Add an entry to the SYSCAL subtable.

Int PKSMS2writer::addSysCalEntry(
        const Int beamNo,
        const Int spWinId,
        const Double time,
        const Double interval,
        const Vector<Float> tcal,
        const Vector<Float> tsys)
{
  // Extend the SYSCAL subtable.
  cSysCal.addRow();
  Int n = cSysCal.nrow() - 1;

  // Keys.
  cSysCalCols->antennaId().put(n, 0);
  cSysCalCols->feedId().put(n, beamNo-1);
  cSysCalCols->spectralWindowId().put(n, spWinId);
  cSysCalCols->time().put(n, time);
  cSysCalCols->interval().put(n, interval);

  // Data.
  cSysCalCols->tcal().put(n, tcal);
  cSysCalCols->tsys().put(n, tsys);

  return n;
}

//---------------------------------------------- PKSMS2writer::addWeatherEntry

// Add an entry to the WEATHER subtable.

Int PKSMS2writer::addWeatherEntry(
        const Double time,
        const Double interval,
        const Double pressure,
        const Double relHumidity,
        const Double temperature)
{
  // Extend the WEATHER subtable.
  cWeather.addRow();
  Int n = cWeather.nrow() - 1;

  // Keys.
  cWeatherCols->antennaId().put(n, 0);
  cWeatherCols->time().put(n, time);
  cWeatherCols->interval().put(n, interval);

  // Data.
  cWeatherCols->pressure().put(n, pressure);
  cWeatherCols->relHumidity().put(n, relHumidity);
  cWeatherCols->temperature().put(n, temperature);

  return n;
}
