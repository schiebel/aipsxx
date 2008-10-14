// NTDMSFiller.cc: implementation of NTD MS filler
//
//  Copyright (C) 2005, 2006
//# Associated Universities, Inc. Washington DC, USA.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
//
//
//////////////////////////////////////////////////////////////////////
#include "NTDMSFiller.h"

using namespace casa;

// Methods of NTDMSFiller classes
// The constructor
NTDMSFiller::NTDMSFiller(const String& name_, const String& observerName_,
			 const String& projectCode_,
			 const Bool stopFringes_) :
  itsName(name_),
  itsObserverName(observerName_),
  itsProjectCode(projectCode_),
  itsFillerVersion("NTD MS filler 0.1"),
  itsFirstScan(True),
  itsMSMainRow(0),
  itsDataShapes(0),
  itsNTDCoordinates(),
  itsNCat(3),
  itsStopFringes(stopFringes_)
 {
   itsMS = 0;
   itsNumAntenna = 0;
   itsScanNumber         = 0;

   Int status = 0;
   status = createMS(itsName);

}

// The destructor
NTDMSFiller::~NTDMSFiller() {
}

int NTDMSFiller::createMS(const String aName) {

  // FLAG CATEGORY stuff.
  Vector<String>  cat(itsNCat);
  cat(0) = "FLAG_CMD";
  cat(1) = "ORIGINAL";
  cat(2) = "USER";


  try {
    cout << "Creating measurement set = "<< aName << endl;

    // Get the MS main default table description
    TableDesc td = MS::requiredTableDesc();
    //cout << "createMS TableDesc\n";

    // Add the DATA column
    MS::addColumnToDesc(td, MS::DATA,2);
    //td.rwColumnDesc(MS::columnName(MS::DATA)).rwKeywordSet().define("UNIT", "Jy");


    // Add the various DATA columns

    String colData = MS::columnName(MS::DATA);

    // Using hypercubes with the current parameters slows down filling
    // by an order of magnitude. To make it worthwhile, we'd have to fill
    // in chunks. For the moment, turn it off.
    Bool useHyper=False;
    if(useHyper) {
      
      // Setup hypercolumns for the data/flag/flag_category/sigma & weight columns.
      const Vector<String> coordCols(0);
      const Vector<String> idCols(0);
      
      td.defineHypercolumn("TiledData", 3, stringToVector(colData),
			   coordCols, idCols);
      
      td.defineHypercolumn("TiledFlag", 3,
			   stringToVector(MS::columnName(MS::FLAG)));
      
      td.defineHypercolumn("TiledWeight", 2,
			   stringToVector(MS::columnName(MS::WEIGHT)));
      
      td.defineHypercolumn("TiledSigma", 2,
			   stringToVector(MS::columnName(MS::SIGMA)));
      
      td.defineHypercolumn("TiledUVW", 2,
			   stringToVector(MS::columnName(MS::UVW)));
      
      td.defineHypercolumn("TiledFlagCategory", 4,
			   stringToVector(MS::columnName(MS::FLAG_CATEGORY)));
    }

    SetupNewTable newTab(aName, td, Table::New);

    // Choose the Tile size per column to be ~ 4096K
    const Int nTileCorr = 1;
    const Int nTileChan = 1024;
    const Int tileSizeKBytes = 4096;
    Int nTileRow;

    // Create an incremental storage manager
    IncrementalStMan incrStMan;

    // By default all the columns are bound to the Inc Stman
    newTab.bindAll(incrStMan);    

    // Define storage managers for special columns

    if(useHyper) {
      // DATA hypercolumn
      nTileRow = (tileSizeKBytes * 1024 / (2 * 4 * nTileCorr * nTileChan));
      IPosition dataTileShape(3, nTileCorr, nTileChan, nTileRow);
      
      TiledShapeStMan dataStMan("TiledData", dataTileShape);
      newTab.bindColumn(colData, dataStMan);
      
      // WEIGHT and SIGMA hypercolumn
      nTileRow = (tileSizeKBytes * 1024 / (4 * nTileCorr));
      IPosition weightTileShape(2, nTileCorr, nTileRow);

      TiledShapeStMan weightStMan("TiledWeight", weightTileShape);
      newTab.bindColumn(MS::columnName(MS::WEIGHT), weightStMan);

      TiledShapeStMan sigmaStMan("TiledSigma", weightTileShape);
      newTab.bindColumn(MS::columnName(MS::SIGMA), sigmaStMan);
      
      // UVW hyperColumn
      nTileRow = (tileSizeKBytes * 1024 / (8 * 3));
      IPosition uvwTileShape(2, 3, nTileRow);
      TiledColumnStMan uvwStMan("TiledUVW", uvwTileShape);
      newTab.bindColumn(MS::columnName(MS::UVW), uvwStMan);
      
      // FLAG hyperColumn
      nTileRow = (tileSizeKBytes * 1024 / (nTileCorr * nTileChan));
      IPosition flagTileShape(3, nTileCorr, nTileChan, nTileRow);
      TiledShapeStMan flagStMan("TiledFlag", flagTileShape);
      newTab.bindColumn(MS::columnName(MS::FLAG), flagStMan);
      
      // FLAG CATEGORY hypercolumn
      nTileRow = (tileSizeKBytes * 1024 / (nTileCorr * nTileChan * itsNCat));
      IPosition flagCategoryTileShape(4, nTileCorr, nTileChan,
				      itsNCat, nTileRow);
      TiledShapeStMan flagCategoryStMan("TiledFlagCategory",
					flagCategoryTileShape);
      newTab.bindColumn(MS::columnName(MS::FLAG_CATEGORY),
			flagCategoryStMan);
    }

  // And finally create the Measurement Set and get access
  // to its columns
    //Table::TableOption openOption = Table::New;
    //itsMS = new MeasurementSet(newTab, openOption);
    itsMS = new casa::MeasurementSet(newTab, 0, False);
    if (! itsMS) {
      return False;
    }
  }
  catch (AipsError& x) {
    cout << "Exception : " << x.getMesg() << endl;
  }

  itsMSCol = new casa::MSMainColumns(*itsMS);


  // Create all subtables and their possible extra columns.
  // Antenna
  // We can fill this in since it will never change :)
  {
    SetupNewTable tabSetup(itsMS->antennaTableName(),
			   MSAntenna::requiredTableDesc(),
			   Table::New);
    itsMS->rwKeywordSet().defineTable(MS::keywordName(MS::ANTENNA),
				      Table(tabSetup));
  }
  // Data description
  {
    SetupNewTable tabSetup(itsMS->dataDescriptionTableName(),
			   MSDataDescription::requiredTableDesc(),
			   Table::New);
    itsMS->rwKeywordSet().defineTable(MS::keywordName(MS::DATA_DESCRIPTION),
				      Table(tabSetup));
  }
  // Feed
  {
    TableDesc td = MSFeed::requiredTableDesc();
 
    SetupNewTable tabSetup(itsMS->feedTableName(),
			   MSFeed::requiredTableDesc(), Table::New);
    MSFeed::addColumnToDesc (td, MSFeed::FOCUS_LENGTH);
    itsMS->rwKeywordSet().defineTable(MS::keywordName(MS::FEED),
				      Table(tabSetup));
  }
  // Flag
  {
    SetupNewTable tabSetup(itsMS->flagCmdTableName(),
			   MSFlagCmd::requiredTableDesc(),
			   Table::New);
    itsMS->rwKeywordSet().defineTable(MS::keywordName(MS::FLAG_CMD),
				      Table(tabSetup));
  }
  // Field
  {
    SetupNewTable tabSetup(itsMS->fieldTableName(),
			   MSField::requiredTableDesc(),
			   Table::New);
    itsMS->rwKeywordSet().defineTable(MS::keywordName(MS::FIELD),
				      Table(tabSetup));
  }
  // History
  {
    SetupNewTable tabSetup(itsMS->historyTableName(),
			   MSHistory::requiredTableDesc(),
			   Table::New);
    itsMS->rwKeywordSet().defineTable(MS::keywordName(MS::HISTORY),
				      Table(tabSetup));
  }
  // Observation
  {
    SetupNewTable tabSetup(itsMS->observationTableName(),
			   MSObservation::requiredTableDesc(),
			   Table::New);
    itsMS->rwKeywordSet().defineTable(MS::keywordName(MS::OBSERVATION),
				      Table(tabSetup));
  }
  // Pointing
  {
    TableDesc td = MSPointing::requiredTableDesc();
    MSPointing::addColumnToDesc (td, MSPointing::POINTING_OFFSET);
    MSPointing::addColumnToDesc (td, MSPointing::ENCODER);
    MSPointing::addColumnToDesc (td, MSPointing::ON_SOURCE);
    SetupNewTable tabSetup(itsMS->pointingTableName(), td, Table::New);
    itsMS->rwKeywordSet().defineTable(MS::keywordName(MS::POINTING),
				      Table(tabSetup));
  }
  // Polarization
  {
    TableDesc td = MSPolarization::requiredTableDesc();
    SetupNewTable tabSetup(itsMS->polarizationTableName(),
			   td, Table::New);
    itsMS->rwKeywordSet().defineTable(MS::keywordName(MS::POLARIZATION),
				      Table(tabSetup));
  }
  // Processor
  {
    SetupNewTable tabSetup(itsMS->processorTableName(),
			   MSProcessor::requiredTableDesc(),
			   Table::New);
    itsMS->rwKeywordSet().defineTable(MS::keywordName(MS::PROCESSOR),
				      Table(tabSetup));
  }
  // Source
  {
    TableDesc td = MSSource::requiredTableDesc();
    MSSource::addColumnToDesc (td, MSSource::POSITION);
    MSSource::addColumnToDesc (td, MSSource::TRANSITION);
    MSSource::addColumnToDesc (td, MSSource::REST_FREQUENCY);
    MSSource::addColumnToDesc (td, MSSource::SYSVEL);
    SetupNewTable tabSetup(itsMS->sourceTableName(),
			   td, Table::New);
    itsMS->rwKeywordSet().defineTable(MS::keywordName(MS::SOURCE),
				      Table(tabSetup));
  }
  // Spectral Window
  {
    TableDesc td = MSSpectralWindow::requiredTableDesc();
    SetupNewTable tabSetup(itsMS->spectralWindowTableName(),
			   td, Table::New);
    itsMS->rwKeywordSet().defineTable(MS::keywordName(MS::SPECTRAL_WINDOW),
				      Table(tabSetup));
  }
  // State
  {
    SetupNewTable tabSetup(itsMS->stateTableName(),
			   MSState::requiredTableDesc(),
			   Table::New);
    itsMS->rwKeywordSet().defineTable(MS::keywordName(MS::STATE),
				      Table(tabSetup));
  }
  // Syscal
  {
    TableDesc td = MSSysCal::requiredTableDesc();
    SetupNewTable tabSetup(itsMS->sysCalTableName(), td, Table::New);
    itsMS->rwKeywordSet().defineTable(MS::keywordName(MS::SYSCAL),
				      Table(tabSetup));
  }
  // Weather
  {
    TableDesc td = MSWeather::requiredTableDesc();
    MSWeather::addColumnToDesc (td, MSWeather::H2O);
    MSWeather::addColumnToDesc (td, MSWeather::IONOS_ELECTRON);
    MSWeather::addColumnToDesc (td, MSWeather::PRESSURE);
    MSWeather::addColumnToDesc (td, MSWeather::REL_HUMIDITY);
    MSWeather::addColumnToDesc (td, MSWeather::TEMPERATURE);
    MSWeather::addColumnToDesc (td, MSWeather::DEW_POINT);
    MSWeather::addColumnToDesc (td, MSWeather::WIND_DIRECTION);
    MSWeather::addColumnToDesc (td, MSWeather::WIND_SPEED);
    SetupNewTable tabSetup(itsMS->weatherTableName(), td, Table::New);
    itsMS->rwKeywordSet().defineTable(MS::keywordName(MS::WEATHER),
				      Table(tabSetup));   
  }

  itsMS->initRefs();

  // Now fill in standard stuff
  {
    MSPolarization mspol = itsMS -> polarization();
    MSPolarizationColumns mspolCol(mspol);
    mspol.addRow();

    mspolCol.numCorr().put(0, 1);
    Vector<Int> corrType(1);
    Matrix<Int> corrProduct(2,1);
    corrType(0) = Stokes::type("XX");
    corrProduct(0, 0) = 0;
    corrProduct(1, 0) = 0;
    mspolCol.corrType().put(0,corrType);
    mspolCol.corrProduct().put(0, corrProduct);
    mspol.flush(True);
    itsPolID=0;
  }
  {
    MSAntenna msant = itsMS -> antenna();
    MSAntennaColumns msantCol(msant);
    
    uInt crow = msant.nrow();
    
    msant.addRow(2);

    msantCol.name().put(crow, String("East"));
    msantCol.name().put(crow+1, String("West"));

    msantCol.station().put(crow, String("NTD East Google"));
    msantCol.station().put(crow+1, String("NTD West Google"));

    msantCol.type().put(crow, String("GROUND-BASED"));
    msantCol.type().put(crow+1, String("GROUND-BASED"));

    msantCol.mount().put(crow, String("EQUATORIAL"));
    msantCol.mount().put(crow+1, String("EQUATORIAL"));

    msantCol.positionMeas().put(crow, itsNTDCoordinates.getEast());
    msantCol.positionMeas().put(crow+1, itsNTDCoordinates.getWest());

    Vector<Double>  antOffset(3);
    antOffset=0.0;
    msantCol.offset().put(crow, antOffset);
    msantCol.offset().put(crow+1, antOffset);

    Double antDiam=13.8;
    msantCol.dishDiameter().put(crow, antDiam);
    msantCol.dishDiameter().put(crow+1, antDiam);

    msantCol.flagRow().put(crow, False);
    msantCol.flagRow().put(crow+1, False);
    
    msant.flush(True);
  }
  {
    uInt crow;
    MSProcessor msproc = itsMS -> processor();
    MSProcessorColumns msprocCol(msproc);
    
    crow = msproc.nrow();
    msproc.addRow();
    
    msprocCol.type().put(crow, String("CORRELATOR"));
    msprocCol.subType().put(crow, String("NTD Beamformer/correlator 1.0"));
    msprocCol.typeId().put(crow, 0);
    msprocCol.modeId().put(crow, 0);
    msprocCol.flagRow().put(crow, False);

    msproc.flush();
  }
  {
    Path tmpPath(aName);
    Path tmpPath1(tmpPath);
    
    String expanded = tmpPath1.expandedName();
    Path tmpPath2(expanded);
    const String absolute = tmpPath2.absoluteName();
    itsMSPath = absolute;
  }

  return True;
}

const char** NTDMSFiller::getPolCombinations(int numCorr) {
  static const char* p1[] = {"XX", 0};
  static const char* p2[] = {"XX", "YY", 0};
  static const char* p4[] = {"XX", "XY", "YX", "YY", 0};

  if (numCorr == 1) {
    return p1;
  }
  else if (numCorr == 2) {
    return p2;
  }
  else {
    return p4;
  } 
}

Bool NTDMSFiller::readData(NTDDataSource& ds) {

  MEpoch epoch=ds.getEpoch();
  Double timeMJD=86400.0*epoch.getValue().get();

  int nFeeds = 1;
  int nRows = 1 * nFeeds;
  
  Vector<Double> time(IPosition(1, nRows), timeMJD);
  Vector<Int>    antenna1(IPosition(1, nRows), 0);
  Vector<Int>    antenna2(IPosition(1, nRows), 1);
  Vector<Int>    feed1(IPosition(1, nRows), 0);
  Vector<Int>    feed2(IPosition(1, nRows), 0);
  Vector<Int>    dataDescriptionId(IPosition(1, nRows), itsSpWinID);
  Vector<Double> exposure(IPosition(1, nRows), 1.0);
  Vector<Double> timeCentroid(IPosition(1, nRows), timeMJD);
  Vector<Int>    processorId(IPosition(1, nRows), 0);
  Vector<Int>    fieldId(IPosition(1, nRows), itsFieldID);
  Vector<Int>    stateId(IPosition(1, nRows), 0);

  Vector<Double> interval(IPosition(1, nRows), 1.0);
  Vector<Int>    scanNumber(IPosition(1, nRows), 0);
  Vector<Int>    arrayId(IPosition(1, nRows), 0);
  Vector<Int>    observationId(IPosition(1, nRows), 0);
  
  try {
    
    itsMSMainRow=itsMS->nrow();
    Slicer slicer(IPosition(1,itsMSMainRow),
		  IPosition(1, (itsMSMainRow+nRows-1)),
		  Slicer::endIsLast);
    itsMS->addRow(nRows);
    itsMSCol->time().putColumnRange(slicer, time);
    itsMSCol->antenna1().putColumnRange(slicer, antenna1);
    itsMSCol->antenna2().putColumnRange(slicer, antenna2);
    itsMSCol->feed1().putColumnRange(slicer, feed1);
    itsMSCol->feed2().putColumnRange(slicer, feed2);
    itsMSCol->dataDescId().putColumnRange(slicer, dataDescriptionId);
    itsMSCol->processorId().putColumnRange(slicer, processorId);
    itsMSCol->fieldId().putColumnRange(slicer, fieldId);
    itsMSCol->interval().putColumnRange(slicer, interval);
    itsMSCol->exposure().putColumnRange(slicer, exposure);
    itsMSCol->timeCentroid().putColumnRange(slicer, timeCentroid);
    itsMSCol->scanNumber().putColumnRange(slicer, scanNumber);
    itsMSCol->arrayId().putColumnRange(slicer, arrayId);
    itsMSCol->observationId().putColumnRange(slicer, observationId);
    itsMSCol->stateId().putColumnRange(slicer, stateId);
    
    int numCorr = 1;
    int numChan = 1024;
    Vector<Double> uvw(3, 0.0);
    Vector<Float> sigma(numCorr, 1.0);
    Vector<Float> weight(numCorr, 1.0);
    Matrix<Complex> data(ds.getData());
    
    // All the columns that could not be written in one shot are now
    // filled row by row.
    Muvw muvw;
    MDirection source(ds.getSource());
    muvw=itsNTDCoordinates.calcUVW(epoch, source);
    Vector<Double> freq(ds.getFrequency());
    Matrix<Complex> cData(data.copy());
    if(itsStopFringes) stopFringes(muvw, freq, cData);
    Matrix<Bool> flag(IPosition(2, numCorr, numChan), False);
    Cube<Bool> flagCat(IPosition(3, numCorr, numChan, itsNCat), False);
    for (unsigned int cRow = itsMSMainRow;
	 cRow < itsMSMainRow+nRows; cRow++) {
      itsMSCol->uvw().put(cRow, muvw.getValue().getValue());
      itsMSCol->data().put(cRow, cData);
      itsMSCol->sigma().put(cRow, sigma);
      itsMSCol->weight().put(cRow, weight);
      itsMSCol->flag().put(cRow, flag);
      itsMSCol->flagCategory().put(cRow, flagCat);
    }
  }
  catch (AipsError& x) {
    cout << "\nException : " << x.getMesg() << endl;
  }
  
  // Flush
  itsMS->flush();   
  return True;
}

// Add a record in the table DataDescription
Int NTDMSFiller::addDataDescription(Int spectral_window_id_,
				    Int polarization_id_) {
  uInt crow;
  MSDataDescription msdd = itsMS -> dataDescription();
  MSDataDescColumns msddCol(msdd);
  ROMSDataDescColumns romsddCol(msdd);

  crow = msdd.nrow();
  msdd.addRow();
    
  msddCol.spectralWindowId().put(crow, spectral_window_id_);
  msddCol.polarizationId().put(crow, polarization_id_);
  msddCol.flagRow().put(crow, False);
    
  msdd.flush();
    
  return crow;
}

// Test if the file corresponding to the given path exists.
// Returns : 3 if it exists and is writable.
//           2 if it does not exists and is writable.
//           1 if it exists and is non writable.
//           0 if it does not exist and is non writable.
int NTDMSFiller::exists( char *path) {

  int existFlag;
  int writableFlag;

  const String s(path);
  Path tmpPath(s);
  Path tmpPath1(tmpPath);

  String expanded = tmpPath1.expandedName();
  Path tmpPath2(expanded);
  const String absolute = tmpPath2.absoluteName();
  Path tmpPath3(absolute);
  const String dirname = tmpPath3.dirName();

  existFlag = File(absolute).exists()?1:0;
  
  if (existFlag) {
    writableFlag = Table::isWritable(absolute);
  }
  else {
    writableFlag = File(dirname).isWritable();
  }
  return existFlag + 2*writableFlag;
}


// msPath() -
// Returns the absolute name of the measurement set
//
String NTDMSFiller::msPath() {
  return itsMSPath;
}

// Add a record in the table FEED
void NTDMSFiller::addFeed(int      spectral_window_id_) {

  int crow;
  MSFeed msfeed = itsMS -> feed();
  MSFeedColumns msfeedCol(msfeed);
  // Now we can put the values in a new row.
  uInt num_receptors_=1;
  Matrix<Double>   beamOffset(2, num_receptors_, 0.0);
  Matrix<Complex>  polResponse(num_receptors_, num_receptors_,
			       Complex(1.0, 0.0));
  Vector<Double>   position(3, 0.0);
  Vector<Double>   receptorAngle(num_receptors_, 0.0);
  Vector<String>   polarizationType(num_receptors_, "X");
  
  for (uInt antenna_id_=0;antenna_id_<2;antenna_id_++) {
    
    crow = msfeed.nrow();
    
    msfeed.addRow();
    msfeedCol.antennaId().put(crow, antenna_id_);
    msfeedCol.feedId().put(crow, 0);
    msfeedCol.spectralWindowId().put(crow, spectral_window_id_);
    msfeedCol.time().put(crow, 0.0);
    msfeedCol.interval().put(crow,1e30);
    msfeedCol.numReceptors().put(crow, num_receptors_);
    msfeedCol.beamId().put(crow, -1);
    msfeedCol.beamOffset().put(crow, beamOffset);
    msfeedCol.polarizationType().put(crow, polarizationType);
    msfeedCol.polResponse().put(crow, polResponse);
    msfeedCol.position().put(crow, position);
    msfeedCol.receptorAngle().put(crow, receptorAngle);
  }
    
  msfeed.flush();
}
	     

// Adds a field record in the TABLE
uInt NTDMSFiller::addField(String name_,
			   String code_,
			   MEpoch epoch_,
			   MDirection dir_) {
  uInt crow;

  Vector<MDirection> dirs(1, dir_);

  MSField msfield = itsMS -> field();
  MSFieldColumns msfieldCol(msfield);

  crow = msfield.nrow();
  msfield.addRow();

  msfieldCol.name().put(crow, name_);
  msfieldCol.code().put(crow, code_);
  msfieldCol.time().put(crow, epoch_.getValue().get());
  msfieldCol.numPoly().put(crow, 0);
  msfieldCol.delayDirMeasCol().put(crow, dirs);
  msfieldCol.phaseDirMeasCol().put(crow, dirs);
  msfieldCol.referenceDirMeasCol().put(crow, dirs);
  msfieldCol.sourceId().put(crow, -1);
  msfieldCol.flagRow().put(crow, False);
  msfield.flush();

  return crow;
}
	       

// Add a record in the table FLAG_CMD;
void NTDMSFiller::addFlagCmd(double    time_,
			    double    interval_,
			    const char      *type_,
			    const char      *reason_,
			    int       level_,
			    int       severity_,
			    int       applied_,
			    const char      *command_) {
  uInt crow;
  MSFlagCmd msflagcmd = itsMS -> flagCmd();
  MSFlagCmdColumns msflagcmdCol(msflagcmd);

  crow = msflagcmd.nrow();
  
  msflagcmd.addRow();
  msflagcmdCol.time().put(crow, time_);
  msflagcmdCol.interval().put(crow, interval_);
  msflagcmdCol.type().put(crow, "FLAG");
  msflagcmdCol.reason().put(crow, "DUMMY");
  msflagcmdCol.level().put(crow, 0);
  msflagcmdCol.severity().put(crow, 0);
  msflagcmdCol.applied().put(crow, 0);
  msflagcmdCol.command().put(crow, "");
  
  msflagcmd.flush(True);
}
			  
// Add a record in the table HISTORY
void NTDMSFiller::addHistory( double time_,
			     int    observation_id_,
			     const char   *message_,
			     const char   *priority_,
			     const char   *origin_,
			     int    object_id_,
			     const char   *application_,
			     const char   *cli_command_,
			     const char   *app_parms_ ) {
  uInt crow;
  MSHistory mshistory = itsMS -> history();
  MSHistoryColumns mshistoryCol(mshistory);

  Vector<String> cliCommand(1);
  Vector<String> appParms(1);
  cliCommand = cli_command_;
  appParms = app_parms_;

  crow = mshistory.nrow();

  mshistory.addRow();
  
  mshistoryCol.time().put(crow, time_);
  mshistoryCol.observationId().put(crow, observation_id_-1);
  mshistoryCol.message().put(crow, message_);
  mshistoryCol.priority().put(crow, priority_);
  mshistoryCol.origin().put(crow, origin_);
  mshistoryCol.objectId().put(crow, object_id_);
  mshistoryCol.application().put(crow, String(application_));
  mshistoryCol.cliCommand().put(crow, cliCommand);
  mshistoryCol.appParams().put(crow, appParms);
  
  mshistory.flush(True);
}
	     
// Adds a single observation record in the table OBSERVATION
void NTDMSFiller::addObservation(double startTime_,
				const char   *observer_,
				const char   *log_,
				const char   *schedule_type_,
				const char   *schedule_,
				const char   *project_,
				double release_date_) {

  uInt crow;
  MSObservation msobs = itsMS -> observation();
  MSObservationColumns msobsCol(msobs);
  
  Vector<String> log(1);
  log(0) = log_;
  Vector<String> corrSchedule(1);
  corrSchedule(0) = schedule_type_;
  Vector<String> schedule(1);
  schedule(0) = schedule_;
  Vector<Double> timeRange(2);
  
  timeRange(0) = startTime_;
  timeRange(1) = startTime_;

  // Fill the columns
  crow = msobs.nrow();

  msobs.addRow();

  msobsCol.telescopeName().put(crow, String("NTD"));
  msobsCol.timeRange().put(crow, timeRange);
  msobsCol.observer().put(crow, String(observer_));
  msobsCol.log().put(crow, log);
  msobsCol.scheduleType().put(crow, corrSchedule(0));
  msobsCol.schedule().put(crow, schedule);
  msobsCol.project().put(crow, String(project_));
  msobsCol.releaseDate().put(crow, release_date_);
  msobsCol.flagRow().put(crow, False);
  msobs.flush();

}


// Adds a record in the table POINTING
void NTDMSFiller::addPointing(int     antenna_id_,
			     double  time_,
			     double  interval_,
			     const char    *name_,
			     double  direction_[2],
			     double  target_[2],
			     double  pointing_offset_[2],
			     double  encoder_[2],
			     int     tracking_) {
  
  int crow;
  Matrix<Double>  direction(2,1);
  Matrix<Double>  target(2,1);



  cout << "addPointing: entering" << endl;
  MSPointing mspointing = itsMS -> pointing();
  cout << "addPointing: mspointing handled" << endl;

  MSPointingColumns mspointingCol(mspointing);
  cout << "addPointing: mspointingColumns handled" << endl;

  crow = mspointing.nrow();

  mspointing.addRow();
  cout << "addPointing: addRow " << endl;

  mspointingCol.antennaId().put(crow, antenna_id_);
  mspointingCol.time().put(crow, time_);
  mspointingCol.interval().put(crow, interval_);
  mspointingCol.name().put(crow, String(name_));
  mspointingCol.numPoly().put(crow, 0);

  direction(0,0) = direction_[0];
  direction(1,0) = direction_[1];
  target(0,0) = target_[0];
  target(1,0) = target_[1];
 
  mspointingCol.direction().put(crow, direction);
  mspointingCol.target().put(crow, target);

  if (pointing_offset_) {
    Matrix<Double>  pointingOffset(2,1);  
    pointingOffset(0,0) = pointing_offset_[0];
    pointingOffset(1,0) = pointing_offset_[1];
    mspointingCol.pointingOffset().put(crow, pointingOffset);
  }

  if (encoder_) {
    Vector<Double>  encoder(2);
    encoder(0) = encoder_[0];
    encoder(1) = encoder_[1];
    mspointingCol.encoder().put(crow,encoder);
  }

  mspointingCol.tracking().put(crow, ((tracking_)?True:False));
  
  mspointing.flush();

  cout << "addPointing: exiting" << endl;
}
		 
// Adds a record in the table Polarization
int NTDMSFiller::addPolarization(int num_corr_,
				int corr_type_[],
				int corr_product_[]) {
  uInt crow;
  int  i;
  Vector<Int>  corrType(num_corr_);
  Matrix<Int>  corrProduct(2, num_corr_);

  MSPolarization mspolar = itsMS -> polarization();
  MSPolarizationColumns mspolarCol(mspolar);

  const char** p=getPolCombinations(num_corr_);


  crow = mspolar.nrow();
  mspolar.addRow();

  mspolarCol.numCorr().put(crow, num_corr_);
  for (i=0; i < num_corr_; i++) {
    corrType(i) = Stokes::type(p[i]);
    corrProduct(0, i) = Stokes::receptor1(Stokes::type(p[i]));
    corrProduct(1, i) = Stokes::receptor2(Stokes::type(p[i]));
  }
  mspolarCol.corrType().put(crow,corrType);
  mspolarCol.corrProduct().put(crow, corrProduct);

  mspolar.flush();
  return crow;
}


// Adds a single state record in the table STATE in such a way that there is no repeated row.
// Returns the index of row added or found with these values. 
int NTDMSFiller::addUniqueState(Bool sig_,
			       Bool ref_,
			       double cal_,
			       double load_,
			       int sub_scan_,
			       const char* obs_mode_,
			       Bool flag_row_) {
  MSState msstate = itsMS -> state();
  MSStateColumns msstateCol(msstate);
  uInt crow = msstate.nrow();
  
  for (uInt i = 0; i < crow; i++) {
    if ((msstateCol.sig()(i) == sig_) &&
	(msstateCol.ref()(i) == ref_) &&
	(msstateCol.cal()(i) == cal_) &&
	(msstateCol.load()(i) == load_) && 
	(msstateCol.subScan()(i) == sub_scan_) &&
	(msstateCol.obsMode()(i).compare(obs_mode_) == 0) &&
	(msstateCol.flagRow()(i) == flag_row_)) {
      return i;
    }
  }

  // If we reach this point then a new must be added.
  msstate.addRow();
  msstateCol.sig().put(crow, sig_);
  msstateCol.ref().put(crow, ref_);
  msstateCol.cal().put(crow, cal_);
  msstateCol.load().put(crow, load_);
  msstateCol.subScan().put(crow, sub_scan_);
  msstateCol.obsMode().put(crow, String(obs_mode_));
  msstateCol.flagRow().put(crow, flag_row_);
  
  return crow;
}

// Add a record in the table SOURCE
void NTDMSFiller::addSource(int    source_id_,
			   double time_,
			   double interval_,
			   int    spectral_window_id_,
			   int    num_lines_,
			   const char   *name_,
			   int    calibration_group_,
			   const char   *code_,
			   double direction_[2],
			   double position_[3],
			   double proper_motion_[2],
			   const char   *transition_[],
			   double rest_frequency_[],
			   double sysvel_[]){
  MSSource mssource = itsMS -> source();
  MSSourceColumns mssourceCol(mssource);

  Vector<Double>    direction(2);
  Vector<Double>    position(3);
  Vector<Double>    properMotion(2);
  Vector<String>    transition(num_lines_);
  Vector<Double>    restFrequency(num_lines_);
  Vector<Double>    sysvel(num_lines_);
  

  // Add a new row.
  int crow = mssource.nrow();
  mssource.addRow();

  // Prepare data to be inserted.
  direction(0) = direction_[0];
  direction(1) = direction_[1];

  position(0) = position_[0];
  position(1) = position_[1];
  position(2) = position_[2];
  
  properMotion(0) = proper_motion_[0];
  properMotion(1) = proper_motion_[1];

  for (int i=0; i<num_lines_; i++) {
    transition(i) = String("dummy");
    restFrequency(i) = rest_frequency_[i];
    sysvel(i) = sysvel_[i];
  }

  // Fill the new row
  mssourceCol.sourceId().put(crow,source_id_);
  mssourceCol.time().put(crow,time_);
  mssourceCol.time().put(crow,0.0);
  mssourceCol.interval().put(crow,interval_);
  mssourceCol.spectralWindowId().put(crow,spectral_window_id_);
  mssourceCol.numLines().put(crow,num_lines_);
  mssourceCol.name().put(crow,String(name_));
  mssourceCol.calibrationGroup().put(crow,calibration_group_);
  mssourceCol.code().put(crow,String(code_));
  mssourceCol.direction().put(crow,direction);
  mssourceCol.position().put(crow,position);
  mssourceCol.properMotion().put(crow,properMotion);
  mssourceCol.transition().put(crow,transition);
  mssourceCol.restFrequency().put(crow,restFrequency);
  mssourceCol.sysvel().put(crow,sysvel);
  
  mssource.flush();
}

// Add a  record  in the table SPECTRAL_WINDOW
int NTDMSFiller::addSpectralWindow(const String& name, const Vector<Double>& freq) {
  
  MSSpectralWindow msspwin = itsMS -> spectralWindow();
  MSSpWindowColumns msspwinCol(msspwin);

  uInt num_chan_=freq.nelements();

  Double ref_frequency_=freq(0);

  Vector<Double> chanWidth(num_chan_, 24e3);
  Vector<Double> effectiveBW(num_chan_, 24e3);
  Vector<Double> resolution(num_chan_, 24e3);
  uInt crow;
  
  crow = msspwin.nrow();
  msspwin.addRow();
  
  msspwinCol.numChan().put(crow, num_chan_);
  msspwinCol.name().put(crow, name);
  msspwinCol.refFrequency().put(crow, ref_frequency_);

  msspwinCol.chanFreq().put(crow, freq);
  msspwinCol.chanWidth().put(crow, chanWidth);
  msspwinCol.effectiveBW().put(crow, effectiveBW);
  msspwinCol.resolution().put(crow, resolution);
  msspwinCol.measFreqRef().put(crow, MFrequency::TOPO);
  msspwinCol.totalBandwidth().put(crow, 24e6);
  msspwinCol.netSideband().put(crow, 1);
  msspwinCol.ifConvChain().put(crow, 0);
  msspwinCol.freqGroup().put(crow, 0);
  msspwinCol.freqGroupName().put(crow, String(""));
  msspwinCol.flagRow().put(crow, False);

  msspwin.flush();
  return crow;
}


// Adds a single state record in the table STATE
void NTDMSFiller::addState(Bool   sig_,
			  Bool   ref_,
			  double cal_,
			  double load_,
			  int    sub_scan_,
			  const char   *obs_mode_) {
  uInt crow;
  MSState msstate = itsMS -> state();
  MSStateColumns msstateCol(msstate);

  crow = msstate.nrow();
  msstate.addRow();

  msstateCol.sig().put(crow, sig_);
  msstateCol.ref().put(crow, ref_);
  msstateCol.cal().put(crow, cal_);
  msstateCol.load().put(crow, load_);
  msstateCol.subScan().put(crow, sub_scan_);
  msstateCol.obsMode().put(crow, String(obs_mode_));
  msstateCol.flagRow().put(crow, False);
  msstate.flush();

}


// Adds a  record weather in the table WEATHER
void NTDMSFiller::addWeather(int antenna_id_,
			    double time_,
			    double interval_,
			    float h2o_,
			    float rms_h2o_,
			    float rms_h2o_flag_,
			    float pressure_,
			    float rel_humidity_,
			    float temperature_,
			    float dew_point_,
			    float wind_direction_,
			    float wind_speed_) {

  cout << "Entering addWeather" << endl;
  MSWeather msweather = itsMS -> weather();
  MSWeatherColumns msweatherCol(msweather);

  cout << "Handling msweatherCol" << endl;
  int crow;

  crow = msweather.nrow();

  msweather.addRow();
  
  msweatherCol.antennaId().put(crow, antenna_id_-1);
  msweatherCol.interval().put(crow, interval_);
  msweatherCol.time().put(crow, time_);

  msweatherCol.H2O().put(crow, h2o_);
  msweatherCol.pressure().put(crow, pressure_);
  msweatherCol.relHumidity().put(crow, rel_humidity_);
  msweatherCol.temperature().put(crow, temperature_);
  msweatherCol.dewPoint().put(crow, dew_point_);
  msweatherCol.windDirection().put(crow, wind_direction_);
  msweatherCol.windSpeed().put(crow, wind_speed_);

  msweather.flush();
  cout << "Exiting addWeather" << endl;
}

void NTDMSFiller::end(double time_) {
  itsMS->flush(True);
  itsMS = 0;
  cout << "Exiting from end" << endl;
}

Bool NTDMSFiller::stopFringes(const Muvw& muvw,
			      const Vector<Double>& freq,
			      Matrix<Complex>& data) {
  Double delay=muvw.getValue()(2);
  for(uInt i=0;i<1024;i++) {
    Double phase=-2.0*C::pi*freq(i)*delay/C::c;
    data(0,i)*=Complex(cos(phase), sin(phase));
  }
  return True;
}

Bool NTDMSFiller::fill(NTDDataSource& ds) {
  Time timeObs;
  Time timeNow;
  
  timeNow.now();
  addHistory(timeNow.seconds(),
	     0,
	     "Started filling",
	     "NORMAL",
	     itsObserverName.chars(),
	     0,
	     itsFillerVersion.chars(),
	     "",
	     "");
  
  Bool first=True;
  while(ds.more()) {
    if(ds.sourceChanged()) {
      cout << "Source change" << endl;
      itsFieldID=addField(String("UNKNOWN"),
			  String("NTDTEST"),
			  ds.getEpoch(),
			  ds.getSource());
    }
    
    if(ds.freqChanged()) {
      cout << "Frequency change" << endl;
      itsSpWinID=addSpectralWindow("LBand", ds.getFrequency());
      itsDDID=addDataDescription(itsSpWinID, itsPolID);
      addFeed(itsSpWinID);
    }

    if(readData(ds)) {
      timeNow.now();
      if(first) {
	cout << "Adding observation table rows" << endl;
	addObservation(timeObs.seconds(),
		       itsObserverName.chars(),
		       "",
		       "",
		       "",
		       itsProjectCode.chars(),
		       0.0);
	first=False;
      }
    }
  }
  if(first) return False;

  timeNow.now();
  addHistory(timeNow.seconds(),
	     0,
	     "Finished filling",
	     "NORMAL",
	     itsObserverName.chars(),
	     0,
	     itsFillerVersion.chars(),
	     "",
	     "");
  return True;
}
