#include	"stdio.h"			/* <stdio.h> */
#include	"stddef.h"			/* <stddef.h> */
#include	"time.h"			/* <time.h> */
/*#include	"gipsyc.h" */			/* GIPSY definitions */

#if	defined(__sysv__)

#include	<sys/time.h>

#elif	defined(__bsd__)

#define		ftime	FTIME

#include	<sys/timeb.h>			/* from system */

#undef		ftime

extern	void	ftime( struct timeb * );	/* this is the funtion */

#else

#endif

void	timer( double *cpu_time ,		/* cpu timer */
	       double *real_time ,		/* real timer */
	       int  *mode )			/* the mode */
{
   clock_t	tc;				/* clock time */
   double	ct;				/* cpu time in seconds */
   double	rt;				/* real time in seconds */
#if	defined(__sysv__)
   struct timeval 	Tp;
   struct timezone	Tzp;
#elif	defined(__bsd__)
   struct timeb tr;				/* struct from ftime */
#else
#endif
   tc = clock( );				/* get clock time */
   ct = (double)(tc) / (double)CLOCKS_PER_SEC;	/* to seconds */
#if	defined(__sysv__)
   gettimeofday( &Tp, &Tzp );			/* get timeofday */
   rt = (double) Tp.tv_sec + 0.000001 * (double) Tp.tv_usec;
#elif	defined(__bsd__)
   ftime( &tr );				/* get real time */
   rt = (double) tr.time + 0.001 * (double) tr.millitm;	/* in seconds */
#else
#endif
   if (*mode) {					/* calculate difference */
      (*cpu_time)  = ct - (*cpu_time);		/* cpu time */
      (*real_time) = rt - (*real_time);		/* real time */
   } else {
      (*cpu_time)  = ct;			/* set cpu time */
      (*real_time) = rt;			/* set real time */
   }
}





#include "ASDM2MSFiller.h"

using namespace casa;

// Methods of timeMgr class.
timeMgr::timeMgr() {
  index = -1;
  startTime = 0.0;
}

timeMgr::timeMgr(int i, double t) {
  index = i;
  startTime = t;
}

void   timeMgr::setIndex(int i) { index = i;}
void   timeMgr::setStartTime(double t) {startTime = t;}
int    timeMgr::getIndex() {return index;}
double timeMgr::getStartTime() {return startTime;}

// Methods of ddMgr class.
ddMgr::ddMgr() {
  int i;
  for (i=0; i<100; i++) {
    numCorr[i]  = 0;
    numChan[i]  = 0;
    dd[i].polId = -1;
    dd[i].swId  = -1;
  }
}

int ddMgr::setNumCorr(int i, int numCorr) {
  if ((i < 0) || (i > 100) || (numCorr <= 0)) {
    return -1;
  }
  else {
    this->numCorr[i] = numCorr;
    return numCorr;
  }
}


int ddMgr::setNumChan(int i, int numChan) {
  if ((i < 0) || (i >= 100) || (numChan <= 0)) {
    return -1;
  }
  else {
    this->numChan[i] = numChan;
    return numChan;
  }
}


int ddMgr::getNumCorr(int i) {
  if ((i<0) || (i >= 100)) {
    return -1;
  }
  else 
    return numCorr[this->dd[i].polId];
}


int ddMgr::getNumChan(int i) {
  if ((i<0) || (i >= 100)) {
    return -1;
  }
  else 
    return numChan[this->dd[i].swId];
}


int ddMgr::setDD(int i, int polId, int swId) {
  if ((i<0) || (i >= 100) ||
      (polId < 0) || (polId >= 100) ||
      (swId  < 0) || (swId  >= 100)) {
    return -1;
  }
  else {
    dd[i].polId = polId;
    dd[i].swId  = swId;
    return i;
  }
}
      
int ddMgr::getPolId(int i) {
  if ((i<0) || (i >= 100)) {
    return -1;
  }
  else {
    return dd[i].polId;
  }
}


int ddMgr::getSwId(int i) {
  if ((i<0) || (i >= 100)) {
    return -1;
  }
  else {
    return dd[i].swId;
  }
}

// Methods of ASDM2MSFiller classe.
// The constructor
ASDM2MSFiller::ASDM2MSFiller(const char    *name_,
		       double        creation_time_,
		       Bool          withRadioMeters_,
		       Bool          complexData):
  itsFeedTimeMgr(0),
  itsFieldTimeMgr(0),
  itsObservationTimeMgr(0),
  itsPointingTimeMgr(0),
  //itsSourceTimeMgr(timeMgr()),
  itsSourceTimeMgr(0),
  itsSyscalTimeMgr(0),
  itsWeatherTimeMgr(0),

  itsWithRadioMeters(withRadioMeters_),
  itsFirstScan(True),
  itsMSMainRow(0),
  itsDataShapes(0),
  itsNCat(3)
 {
  int status;

  itsName = name_;
  itsCreationTime = creation_time_;
   
  itsMS = 0;

  itsNumAntenna = 0;
  itsObservationTimeMgr = new timeMgr[1]; 
  itsScanNumber         = 0;

  status = createMS(itsName, complexData);

}

// The destructor
ASDM2MSFiller::~ASDM2MSFiller() {
}

int ASDM2MSFiller::createMS(const char* msName, Bool complexData) {

  String aName;
  aName = String(msName);

  // FLAG CATEGORY stuff.
  Vector<String>  cat(itsNCat);
  cat(0) = "FLAG_CMD";
  cat(1) = "ORIGINAL";
  cat(2) = "USER";


  try {
    //cout << "Entering createMS : measurement set = "<< aName <<"\n";

    // Get the MS main default table description
    TableDesc td = MS::requiredTableDesc();
    //cout << "createMS TableDesc\n";

    if (complexData) {
      // Add the DATA column
      MS::addColumnToDesc(td, MS::DATA,2);
      //td.rwColumnDesc(MS::columnName(MS::DATA)).rwKeywordSet().define("UNIT", "Jy");
    }
    else {
      // Add the FLOAT_DATA column
      MS::addColumnToDesc(td, MS::FLOAT_DATA,2);
    }

  
    // Add MODEL_DATA, CORRECTED_DATA and IMAGING_WEIGHT columns
    MS::addColumnToDesc(td, MS::MODEL_DATA,2);
    MS::addColumnToDesc(td, MS::CORRECTED_DATA,2);
    MS::addColumnToDesc(td, MS::IMAGING_WEIGHT,1);


    // Setup hypercolumns for the data/flag/flag_category/sigma & weight columns, model_data, corrected_data and imaging_weight.
    const Vector<String> coordCols(0);
    const Vector<String> idCols(0);
    
    String colData;
    String colFloatData;

    if (complexData) {
      colData = MS::columnName(MS::DATA);
      td.defineHypercolumn("TiledData", 3, stringToVector(colData),
			   coordCols, idCols);
    }
    else {
      colFloatData = MS::columnName(MS::FLOAT_DATA);
      td.defineHypercolumn("TiledFloatData", 3, stringToVector(colFloatData),
			   coordCols, idCols);
    }

    //cout << "defined float data Hypercolumn" << endl;


    String colModelData = MS::columnName(MS::MODEL_DATA);
    td.defineHypercolumn("TiledModelData", 3, stringToVector(colModelData),
			 coordCols, idCols);
    //cout << "defined model data Hypercolumn" << endl;

    String colCorrData = MS::columnName(MS::CORRECTED_DATA);
    td.defineHypercolumn("TiledCorrectedData", 3,
			 stringToVector(colCorrData),
			 coordCols, idCols);
    //cout << "defined corrected data Hypercolumn" << endl;

    String colImWgt = MS::columnName(MS::IMAGING_WEIGHT);
    td.defineHypercolumn("TiledImWgt", 2,
			 stringToVector(colImWgt),
			 coordCols, idCols);
    //cout << "defined imaging weight Hypercolumn" << endl;

    

    td.defineHypercolumn("TiledFlag", 3,
			 stringToVector(MS::columnName(MS::FLAG)));
    //cout << "defined flag Hypercolumn" << endl;


    td.defineHypercolumn("TiledWeight", 2,
			 stringToVector(MS::columnName(MS::WEIGHT)));
    //cout << "defined Weight Hypercolumn" << endl;

    td.defineHypercolumn("TiledSigma", 2,
			 stringToVector(MS::columnName(MS::SIGMA)));
    //cout << "defined Sigma Hypercolumn" << endl;


    td.defineHypercolumn("TiledUVW", 2,
			 stringToVector(MS::columnName(MS::UVW)));
    //cout << "defined UVW Hypercolumn" << endl;

    
    td.defineHypercolumn("TiledFlagCategory", 4,
			 stringToVector(MS::columnName(MS::FLAG_CATEGORY)));
    //cout << "defined Flag Category Hypercolumn" << endl;

    if (itsWithRadioMeters) {
      // ALMA_PHAS_COOR hypercolumn
      String colPhaseCorr = "ALMA_PHAS_CORR";
      td.addColumn(ArrayColumnDesc<Complex>(colPhaseCorr,
					    "Phase-corrected data",
					    2));
      td.defineHypercolumn("TiledPhaseCorr",
			   3,
			   stringToVector(colPhaseCorr),
			   coordCols,
			   idCols);

      // ALMA_NO_PHAS_COOR hypercolumn
      String colNoPhaseCorr = "ALMA_NO_PHAS_CORR";
      td.addColumn(ArrayColumnDesc<Complex>(colNoPhaseCorr,
					    "Phase-uncorrected data",
					    2));
      td.defineHypercolumn("TiledNoPhaseCorr",
			   3,
			   stringToVector(colNoPhaseCorr),
			   coordCols,
			   idCols);

      // ALMA_PHAS_CORR_FLAG_ROW
      String colPhaseCorrFlagRow = "ALMA_PHAS_CORR_FLAG_ROW";
      td.addColumn(ScalarColumnDesc<Bool>(colPhaseCorrFlagRow,
					  "Phase-corrected data present?"));
    }
    

    SetupNewTable newTab(aName, td, Table::New);

    //cout << "createMS SetupNewTable\n";
    
    // Choose the Tile size per column to be ~ 4096K
    const Int nTileCorr = 1;
    const Int nTileChan = 1024;
    const Int tileSizeKBytes = 4096;
    Int nTileRow;

    // Create an incremental storage manager
    IncrementalStMan      incrStMan;

    // By default all the columns are bound to the Inc Stman
    newTab.bindAll(incrStMan);    

    // Define storage managers for special columns

    // ANTENNA2 
    StandardStMan antenna2StMan("Antenna2 Standard Storage Manager", 32768);
    newTab.bindColumn(MS::columnName(MS::ANTENNA2), antenna2StMan);

    // DATA_DESC_ID 
    StandardStMan dataDescriptionStMan("DataDescID Standard Storage Manager", 32768);
    newTab.bindColumn(MS::columnName(MS::DATA_DESC_ID), dataDescriptionStMan);
    
    
    if (complexData) {
      // DATA hypercolumn
      nTileRow = (tileSizeKBytes * 1024 / (2 * 4 * nTileCorr * nTileChan));
      IPosition dataTileShape(3, nTileCorr, nTileChan, nTileRow);

      TiledShapeStMan dataStMan("TiledData", dataTileShape);
      newTab.bindColumn(colData, dataStMan);
    }
    else {
      // FLOAT_DATA hypercolumn
      nTileRow = (tileSizeKBytes * 1024 / (2 * 4 * nTileCorr * nTileChan));
      IPosition floatDataTileShape(3, nTileCorr, nTileChan, nTileRow);

      TiledShapeStMan floatDataStMan("TiledFloatData", floatDataTileShape);
      newTab.bindColumn(colFloatData, floatDataStMan);
    }

    // MODEL DATA hypercolumn
    nTileRow = (tileSizeKBytes * 1024 / (2 * 4 * nTileCorr * nTileChan));
    IPosition modelDataTileShape(3, nTileCorr, nTileChan, nTileRow);

    TiledShapeStMan modelDataStMan("TiledModelData", modelDataTileShape);
    newTab.bindColumn(MS::columnName(MS::MODEL_DATA), modelDataStMan);

    // CORRECTED DATA hypercolumn
    nTileRow = (tileSizeKBytes * 1024 / (2 * 4 * nTileCorr * nTileChan));
    IPosition corrDataTileShape(3, nTileCorr, nTileChan, nTileRow);

    TiledShapeStMan corrDataStMan("TiledCorrectedData", corrDataTileShape);
    newTab.bindColumn(MS::columnName(MS::CORRECTED_DATA), corrDataStMan);

    // IMAGING WEIGHT hypercolumn
    nTileRow = (tileSizeKBytes * 1024 / (4 * nTileChan));
    IPosition imWgtTileShape(2, nTileChan, nTileRow);

    TiledShapeStMan imWgtStMan("TiledImWgt", imWgtTileShape);
    newTab.bindColumn(MS::columnName(MS::IMAGING_WEIGHT), imWgtStMan);

    
    // WEIGHT and SIGMA hypercolumn
#if 0
    nTileRow = (tileSizeKBytes * 1024 / (4 * nTileCorr));
    IPosition weightTileShape(2, nTileCorr, nTileRow);
    TiledShapeStMan weightStMan("TiledWeight", weightTileShape);
    newTab.bindColumn(MS::columnName(MS::WEIGHT), weightStMan);
    TiledShapeStMan sigmaStMan("TiledSigma", weightTileShape);
    newTab.bindColumn(MS::columnName(MS::SIGMA), sigmaStMan);
#else
    StandardStMan weightStMan("StandardStManWeight");
    newTab.bindColumn(MS::columnName(MS::WEIGHT), weightStMan);
    StandardStMan sigmaStMan("StandardStManSigma");
    newTab.bindColumn(MS::columnName(MS::SIGMA), sigmaStMan);

#endif
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

    //cout << "createMS bindAll\n";

    //cout << "createMS DATA, FLAG, UVW, WEIGHT and SIGMA bound to their storage managers\n";

  

  // And finally create the Measurement Set and get access
  // to its columns
    //Table::TableOption openOption = Table::New;
    //itsMS = new MeasurementSet(newTab, openOption);
    itsMS = new casa::MeasurementSet(newTab, 0, False);
    //cout << "createMS MeasurementSet, adress=" << (int) itsMS << endl;
    if (! itsMS) {
      return False;
    }
    //cout << "Measurement Set just created, main table nrow=" << itsMS->nrow()<< endl;
  
  }
  catch (AipsError& x) {
    cout << "Exception : " << x.getMesg() << endl;
  }

  itsMSCol = new casa::MSMainColumns(*itsMS);


  // Create all subtables and their possible extra columns.
  // Antenna
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
    MSSpectralWindow::addColumnToDesc (td, MSSpectralWindow::ASSOC_SPW_ID);
    MSSpectralWindow::addColumnToDesc (td, MSSpectralWindow::ASSOC_NATURE);
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


  //cout << "\n";
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

const char** ASDM2MSFiller::getPolCombinations(int numCorr) {
  static const char* p1[] = {"RR", 0};
  static const char* p2[] = {"RR", "LL", 0};
  static const char* p4[] = {"RR", "LR", "RL", "LL", 0};

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
// Insert records in the table ANTENNA
int ASDM2MSFiller::addAntenna( const char   *name_,
			    const char   *station_,
			    double lx_,
			    double ly_,
			    double lz_,
			    double offset_x_,
			    double offset_y_,
			    double offset_z_,
			    float  dish_diam_) {

  uInt crow;
  //itsNumAntenna = num_antenna_;
  itsNumAntenna++;

  // cout << "addAntenna : entering \n";

  MSAntenna msant = itsMS -> antenna();
  MSAntennaColumns msantCol(msant);

  // cout << "addAntenna : loop over antennas \n";
  crow = msant.nrow();

  Vector<Double>  antXYZ(3);
  Vector<Double>  antOffset(3);
  msant.addRow();
  msantCol.name().put(crow, String(name_));
  msantCol.station().put(crow, String(station_));
  msantCol.type().put(crow, String("GROUND-BASED"));
  msantCol.mount().put(crow, String("ALT-AZ"));

  antXYZ(0) = lx_;
  antXYZ(1) = ly_;
  antXYZ(2) = lz_;
  msantCol.position().put(crow, antXYZ);
  
  antOffset(0) = offset_x_;
  antOffset(1) = offset_y_;
  antOffset(2) = offset_z_;
  
  msantCol.offset().put(crow, antOffset);
  msantCol.dishDiameter().put(crow, dish_diam_);
  msantCol.flagRow().put(crow, False);
  
  msant.flush(True);
  // cout << "addAntenna : table flushed \n";
  // cout << "addAntenna : exiting \n";
  // cout << "\n";
  return crow-1;
}

void ASDM2MSFiller::addData (bool                      complexData,
			  double                    time_,
			  vector<int>               &antennaId1_,
			  vector<int>               &antennaId2_,
			  vector<int>               &feedId1_,
			  vector<int>               &feedId2_,
			  vector<int>               &dataDescId_,
			  int                       processorId_,
			  int                       fieldId_,
			  double                    interval_,
			  vector<double>            &exposure_,
			  vector<double>            &timeCentroid_,
			  int                       scanNumber_,
			  int                       arrayId_,
			  int                       observationId_,
			  vector<int>               &stateId_,
			  vector<double*>           &uvw_,
			  vector<vector<int> >      &dataShape_,
			  vector<float *>           &data_,
			  vector<unsigned int>      &flag_) {

  //  cout << "Entering addData" << endl;
  int nBaselines = antennaId1_.size();
  
  double *uvw__     = new double[3*nBaselines];
  Bool *flag_row__  = new Bool[nBaselines];

  for (int i = 0; i < nBaselines; i++) {
    uvw__[3*i]                 = uvw_.at(i)[0];
    uvw__[3*i+1]               = uvw_.at(i)[1];
    uvw__[3*i+2]               = uvw_.at(i)[2];
    flag_row__[i]              = flag_.at(i)==0?true:false;
  }

  Vector<Double> time(IPosition(1, nBaselines), time_);
  Vector<Int>    antenna1(IPosition(1, nBaselines), &antennaId1_.at(0), SHARE);
  Vector<Int>    antenna2(IPosition(1, nBaselines), &antennaId2_.at(0), SHARE);
  Vector<Int>    feed1(IPosition(1, nBaselines), &feedId1_.at(0) , SHARE);
  Vector<Int>    feed2(IPosition(1, nBaselines), &feedId2_.at(0), SHARE);
  Vector<Int>    dataDescriptionId(IPosition(1, nBaselines), &dataDescId_.at(0), SHARE);
  Vector<Double> exposure(IPosition(1, nBaselines), &exposure_.at(0), SHARE);
  Vector<Double> timeCentroid(IPosition(1, nBaselines), &timeCentroid_.at(0), SHARE);
  Vector<Int>    processorId(IPosition(1, nBaselines), processorId_);
  Vector<Int>    fieldId(IPosition(1, nBaselines),fieldId_);
  Vector<Int>    stateId(IPosition(1, nBaselines), &stateId_.at(0), SHARE);
  Vector<Double> interval(IPosition(1, nBaselines), interval_);
  Vector<Int>    scanNumber(IPosition(1, nBaselines), scanNumber_);
  Vector<Int>    arrayId(IPosition(1, nBaselines), arrayId_);
  Vector<Int>    observationId(IPosition(1, nBaselines), observationId_);
  Vector<Bool>   flagRow(IPosition(1, nBaselines), flag_row__, SHARE);
  Matrix<Double> uvw(IPosition(2, 3, nBaselines), uvw__, SHARE);

  
  // UVW takes its contents directly from the argument uvw_.
  // Matrix<Double> uvw(IPosition(2, 3, nBaselines), uvw_, SHARE);
  
  // The data column will be constructed row after row.
  // The sigma               "
  // The weight              "
  // The flag                "
  
  try {
    
    // Define  a slicer to write blocks of values in each column of the main table.
    Slicer slicer(IPosition(1,itsMSMainRow),
		  IPosition(1, (itsMSMainRow+nBaselines-1)),
		  Slicer::endIsLast);
    
    // Let's create nBaseLines empty rows into the main table.
    itsMS->addRow(nBaselines);
    
    
    //cout << "Adding blocks of rows" << endl;
    // Now it's time to write all these Arrays into the relevant columns.
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
    itsMSCol->uvw().putColumnRange(slicer, uvw);
    itsMSCol->flagRow().putColumnRange(slicer, flagRow);

       
    // All the columns that could not be written in one shot are now filled row by row.
    Matrix<Complex> data;
    Matrix<Float>   float_data;
    Matrix<Bool>    flag;

    int cRow0 = 0;
    for (unsigned int cRow = itsMSMainRow; cRow < itsMSMainRow+nBaselines; cRow++) {      
      int numCorr = dataShape_.at(cRow0).at(0);
      int numChan = dataShape_.at(cRow0).at(1);

      Vector<float>   ones(IPosition(1, numChan), 1.0);

      if (complexData) {
	// Complex data.
	data.takeStorage(IPosition(2, numCorr, numChan), (Complex *)(data_.at(cRow0)), SHARE);
	itsMSCol->data().put(cRow, data);
	;
      }
      else {
	// Float data.
	float_data.takeStorage(IPosition(2, numCorr, numChan), data_.at(cRow0), SHARE);
	itsMSCol->floatData().put(cRow, float_data);
	;
      }

      // Sigma and Weight set to arrays of 1.0
      itsMSCol->sigma().put(cRow, ones);
      itsMSCol->weight().put(cRow, ones);

      // The flag cell (an array) is put at false.
      itsMSCol->flag().put(cRow, Matrix<Bool>(IPosition(2, numCorr, numChan), false));

      
      cRow0++;
    }
    
    // Don't forget to increment itsMSMainRow.
    itsMSMainRow += nBaselines;
  }
  catch (AipsError& x) {
    cout << "\nException : " << x.getMesg() << endl;
  }
  
  // Flush
  // itsMS->flush();   
  //cout << "Exiting addData" << endl;

  delete[] uvw__;
  delete[] flag_row__;
}


void ASDM2MSFiller::addData(double time_,
			 double interval_,
			 double exposure_,
			 double time_centroid_,
			 int    nb_antenna_feed_,
			 int    antenna_id_[],
			 int    feed_id_[],
			 int    data_desc_id_,
			 int    field_id_,
			 double uvw_[],
			 float  vis_r_[],
			 float  vis_i_[],
			 float  sigma_[],
			 float  weight_[],
			 const char   flag_[]) {
  int  i, j, k, l;

  double cpu_time  = 0.0, ct;
  double real_time = 0.0, rt;
  double overall_cpu_time = 0.0;
  double overall_real_time = 0.0;
  int    mode;

  // Start a chrono to measure the overall time spent into the method.
  mode = 0; timer(&overall_cpu_time, &overall_real_time, &mode); 
 
  int numCorr = itsDDMgr.getNumCorr(data_desc_id_);
  int numChan = itsDDMgr.getNumChan(data_desc_id_);

  uInt nBaseLines = nb_antenna_feed_ * (nb_antenna_feed_ - 1) / 2;

  if (numCorr <= 0 || numChan <= 0) {
    cout << "\naddData : numCorr = " << numCorr
	 << " , numChan = " << numChan
	 << ". They should be both > 0\n";
      return;
  }


  // Create Vector and Matrix properly dimensionned in order to fill the main table
  // with blocks of values (i.e. using putColumnRange).

  try {

    if (nb_antenna_feed_ < 0) {
      return;
    }


    // DATA can't take their contents directly from arguments from arguments because :
    // 1) real and imaginary values are passed in different arrays
    // 2) values have to be re-ordered.
    // Then we have to loop over all baselines to build data.
    // Let's use this loop to build other arrays like Antenna1, Antenna2 etc...
    Vector<Double> time(IPosition(1, nBaseLines), time_);
    Vector<Int>    antenna1(IPosition(1, nBaseLines));
    Vector<Int>    antenna2(IPosition(1, nBaseLines));
    Vector<Int>    feed1(IPosition(1, nBaseLines));
    Vector<Int>    feed2(IPosition(1, nBaseLines));
    Vector<Int>    dataDescriptionId(IPosition(1, nBaseLines), (data_desc_id_));
    Vector<Int>    processorId(IPosition(1, nBaseLines), -1);
    Vector<Int>    fieldId(IPosition(1, nBaseLines), (field_id_));
    Vector<Double> interval(IPosition(1, nBaseLines), interval_);
    Vector<Double> exposure(IPosition(1, nBaseLines), exposure_);
    Vector<Double> timeCentroid(IPosition(1, nBaseLines), time_centroid_);
    Vector<Int>    scanNumber(IPosition(1, nBaseLines), itsScanNumber);
    Vector<Int>    arrayId(IPosition(1, nBaseLines), -1);
    //    Vector<Int>    observationId(IPosition(1, nBaseLines), itsObservationTimeMgr[0].getIndex());
    Vector<Int>    observationId(IPosition(1, nBaseLines), -1);
    Vector<Int>    stateId(IPosition(1, nBaseLines), -1);

    // UVW takes its contents directly from the argument uvw_.
    Matrix<Double> uvw(IPosition(2, 3, nBaseLines), uvw_, SHARE);
        
    Cube<Complex>  data(IPosition(3, numCorr, numChan, nBaseLines));
    Cube<Complex>  modelData(IPosition(3, numCorr, numChan, nBaseLines));
    Cube<Complex>  correctedData(IPosition(3, numCorr, numChan, nBaseLines));

    // SIGMA, WEIGHT can take their contents directly from the argument sigma_,
    // weight_ .
    Matrix<Float>   sigma(IPosition(2, numCorr, nBaseLines), sigma_, SHARE);
    Matrix<Float>   weight(IPosition(2, numCorr, nBaseLines), weight_, SHARE);

    // FLAG. Their contents can't be taken directly from the flag_ argument
    // since each flag_ 's value contains a flag common to all channels and polarizations.

    // For the moment let's put False in each flag's element.
    Cube<Bool>      flag(IPosition(3, numCorr, numChan, nBaseLines), False);

    // FLAGCAT. For the moment, all flagcat's elements are set to False.
    Array<Bool>     flagCat(IPosition(4, numCorr, numChan, itsNCat, nBaseLines), False);

    // FLAGROW. Should take its values from the contents of the flag_ parameters,
    // for the moment all its elements are set to False.
    Vector<Bool>    flagRow(IPosition(1, nBaseLines), False);
    
    // Imaging Weight. For the moment all its elements values are set to 1.0
    Array<Double>   imagingWeight(IPosition(2, numChan, nBaseLines), 1.0);  

    // Now it's time to fill all arrays whose elements are defined by looping
    // over the baselines.
    int iBaseLine = 0;
    for (i=0; i < (nb_antenna_feed_ - 1); i++) {
      for (j=i+1; j < nb_antenna_feed_; j++) {
	antenna1(iBaseLine) = antenna_id_[i];
	antenna2(iBaseLine) = antenna_id_[j];
	feed1(iBaseLine)    = feed_id_[i];   
	feed2(iBaseLine)    = feed_id_[j];   

	// Prepare the Data, Model Data and Corrected Data vectors
	int visPtr    = 0;

	for (k = 0; k < numChan; k++) 
	  for (l = 0; l < numCorr; l++) {
	    visPtr = nBaseLines * numChan * l +  nBaseLines * k + iBaseLine; 
	    modelData(l, k, iBaseLine) =
	      correctedData(l,k, iBaseLine) =
	      data(l, k, iBaseLine) = Complex(vis_r_[visPtr], vis_i_[visPtr]);
	  }
	iBaseLine++;
      }
    }
    

    // Define  a slicer to write blocks of values in each column of the main table.
    Slicer slicer(IPosition(1,itsMSMainRow),
		  IPosition(1, (itsMSMainRow+nBaseLines-1)),
		  Slicer::endIsLast);

    // Start a chrono to measure the time spent writing into the main table.
    mode = 0; timer(&cpu_time, &real_time, &mode); 

    // Let's create nBaseLines empty rows into the main table.
    itsMS->addRow(nBaseLines);

    // Now it's time to write all these arrays into the relevant tables
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
    itsMSCol->uvw().putColumnRange(slicer, uvw);
    itsMSCol->data().putColumnRange(slicer, data);
    itsMSCol->sigma().putColumnRange(slicer, sigma);
    itsMSCol->weight().putColumnRange(slicer, weight);
    itsMSCol->flag().putColumnRange(slicer, flag);
    itsMSCol->flagCategory().putColumnRange(slicer, flagCat);
    itsMSCol->flagRow().putColumnRange(slicer, flagRow);

    itsMSCol->modelData().putColumnRange(slicer, modelData);
    itsMSCol->correctedData().putColumnRange(slicer, correctedData);
    //itsMSCol->imagingWeight().putColumnRange(slicer, imagingWeight)

    // Increment the number of rows
    itsMSMainRow += nBaseLines;
  }
  catch (AipsError& x) {
    cout << "\nException : " << x.getMesg() << endl;
  }

  mode = 0; timer(&ct, &rt, &mode);
  // Increment scan number
  itsScanNumber++;

  // Flush

  //itsMS->flush();
  // Stop the chrono when we have finished to write into the main table.
  mode = 1; timer(&cpu_time, &real_time, &mode); 

  // Stop the chrono to measure the overall time spent into the method.
  mode = 1; timer(&overall_cpu_time, &overall_real_time, &mode);
  /*
  cout << "addData : time spent in writing to tables : cpu =" << cpu_time <<", real =" << real_time << endl;
  cout << "addData : time spent in the method: cpu =" << overall_cpu_time <<", real =" << overall_real_time << endl;
  */
}




void ASDM2MSFiller::addRCData(double time_,
			   double interval_,
			   double exposure_,
			   double time_centroid_,
			   int    nb_antenna_feed_,
			   int    antenna_id_[],
			   int    feed_id_[],
			   int    data_desc_id_,
			   int    field_id_,
			   double uvw_[],
			   float  rvis_r_[],
			   float  rvis_i_[],
			   float  cvis_r_[],
			   float  cvis_i_[],
			   float  sigma_[],
			   float  weight_[],
			   const char   flag_[]) {
  int  i, j, k, l;

  int    visPtr = 0;
  int    uvwPtr = 0;
  int    sigPtr = 0;
  int    weiPtr = 0;

  
  int numCorr = itsDDMgr.getNumCorr(data_desc_id_);
  int numChan = itsDDMgr.getNumChan(data_desc_id_);
  uInt nBaseLines = nb_antenna_feed_ * (nb_antenna_feed_ - 1) / 2;

  if (numCorr <= 0 || numChan <= 0) {
    cout << "\naddRCData : numCorr = " << numCorr
	 << " , numChan = " << numChan
	 << ". They should be both > 0\n";
      return;
  }

  Vector<Double>  uvw(IPosition(1,3));
  Matrix<Complex> rdata(IPosition(2, numCorr, numChan));
  Matrix<Complex> cdata(IPosition(2, numCorr, numChan));
  Matrix<Complex> modelData(IPosition(2, numCorr, numChan));
  Matrix<Complex> correctedData(IPosition(2, numCorr, numChan));
  Vector<Float>   imagingWeight(IPosition(1,numChan));
  Vector<Float>   sigma(IPosition(1,numCorr));
  Vector<Float>   weight(IPosition(1,numCorr));
  Matrix<Bool>    flag(IPosition(2, numCorr, numChan));
  Cube<Bool>      flagCat(numCorr, numChan, itsNCat, False);


  // Create column accessors for non-standard columns individually
  ArrayColumn<Complex> noPhaseCorrCol(*itsMS, "ALMA_NO_PHAS_CORR");
  ArrayColumn<Complex> phaseCorrCol(*itsMS, "ALMA_PHAS_CORR");
  ScalarColumn<Bool> phaseCorrFlagRowCol(*itsMS, "ALMA_PHAS_CORR_FLAG_ROW");


  int iBaseLine = 0;

  try {
    
    if (nb_antenna_feed_ < 0) {
      return;
    }
    
    //cout << "\naddData : numCorr = "<< numCorr << ", numChan=" << numChan << "\n";  
    //cout << "\nShape of data & flag " << rdata.shape().asVector();
    
    for (i=0; i < (nb_antenna_feed_ - 1); i++) {
      for (j=i+1; j < nb_antenna_feed_; j++) {

	itsMS->addRow();


	// Prepare the FLAG matrix
	//flag = (flag_[iBaseLine])?True:False;
	flag = False;

	// Prepare the UVW vector
	uvw(0) = uvw_[uvwPtr++];
	uvw(1) = uvw_[uvwPtr++];
	uvw(2) = uvw_[uvwPtr++];
	
	
	// Prepare the Data, Model Data and Corrected Data vectors
	for (k = 0; k < numChan; k++) 
	  for (l = 0; l < numCorr; l++) {
	    visPtr = nBaseLines * numChan * l +  nBaseLines * k + iBaseLine; 
	    modelData(l, k) =
	      correctedData(l,k) =
	      cdata(l, k) = Complex(cvis_r_[visPtr], cvis_i_[visPtr]);
	    rdata(l, k) = Complex(rvis_r_[visPtr], rvis_i_[visPtr]);
	  }
	iBaseLine++;
	
	// Prepare the Sigma vector
	for (l = 0; l < numCorr; l++) {
	  sigma(l) = sigma_[sigPtr++];
	}
	
	// Prepare the Weight vector
	for (l = 0; l < numCorr; l++) {
	  weight(l) = weight_[weiPtr++];
	}
	
	// Prepare the Imaging Weight vector
	for (l = 0; l < numChan; l++) {
	  imagingWeight(l) = 1.0;
	}

	// Write columns
	itsMSCol->time().put(itsMSMainRow, time_);
	itsMSCol->antenna1().put(itsMSMainRow, antenna_id_[i]-1);
	itsMSCol->antenna2().put(itsMSMainRow, antenna_id_[j]-1);
	itsMSCol->feed1().put(itsMSMainRow, feed_id_[i]-1);
	itsMSCol->feed2().put(itsMSMainRow, feed_id_[j]-1);
       
	/*
	  itsMSCol->feed1().put(itsMSMainRow, i);
	  itsMSCol->feed2().put(itsMSMainRow, j);
	*/
	
	itsMSCol->dataDescId().put(itsMSMainRow, data_desc_id_-1);
	itsMSCol->processorId().put(itsMSMainRow, -1);
	itsMSCol->fieldId().put(itsMSMainRow, field_id_-1);
	itsMSCol->interval().put(itsMSMainRow, interval_);
	itsMSCol->exposure().put(itsMSMainRow, exposure_);
	itsMSCol->timeCentroid().put(itsMSMainRow, time_centroid_);
	itsMSCol->scanNumber().put(itsMSMainRow, itsScanNumber);
	itsMSCol->arrayId().put(itsMSMainRow, -1);
	itsMSCol->observationId().put(itsMSMainRow, itsObservationTimeMgr[0].getIndex());
	itsMSCol->stateId().put(itsMSMainRow, -1);
	itsMSCol->uvw().put(itsMSMainRow, uvw);
	itsMSCol->data().put(itsMSMainRow, cdata);

	noPhaseCorrCol.setShape(itsMSMainRow, IPosition(2, numCorr, numChan));
	noPhaseCorrCol.put(itsMSMainRow, rdata);
	phaseCorrCol.setShape(itsMSMainRow, IPosition(2, numCorr, numChan));
	phaseCorrCol.put(itsMSMainRow, cdata);
	phaseCorrFlagRowCol.put(itsMSMainRow, False);
	
	itsMSCol->sigma().put(itsMSMainRow, sigma);
	itsMSCol->weight().put(itsMSMainRow, weight);
	itsMSCol->flag().put(itsMSMainRow, flag);
	itsMSCol->flagCategory().put(itsMSMainRow, flagCat);
	itsMSCol->flagRow().put(itsMSMainRow, False);

	itsMSCol->modelData().put(itsMSMainRow, modelData);
	itsMSCol->correctedData().put(itsMSMainRow, correctedData);
	itsMSCol->imagingWeight().put(itsMSMainRow, imagingWeight);
	
	// Increment row number
	itsMSMainRow++;
      }
    }
  }
  catch (AipsError& x) {
    cout << "\nException : " << x.getMesg() << endl;
  }

  // Increment scan number
  itsScanNumber++;

  // Flush
  itsMS->flush();
  cout << "\n";
}


// Add a record in the table DataDescription
int  ASDM2MSFiller::addDataDescription(int spectral_window_id_,
				    int polarization_id_) {
  uInt crow;
  MSDataDescription msdd = itsMS -> dataDescription();
  MSDataDescColumns msddCol(msdd);

  crow = msdd.nrow();
  msdd.addRow();
    
  msddCol.spectralWindowId().put(crow, spectral_window_id_);
  msddCol.polarizationId().put(crow, polarization_id_);
  msddCol.flagRow().put(crow, False);
    
  return crow;
}

// Add a record in the table DataDescription
int  ASDM2MSFiller::addUniqueDataDescription( int spectral_window_id_,
					   int polarization_id_ ) {
  uInt crow;
  MSDataDescription msdd = itsMS -> dataDescription();
  MSDataDescColumns msddCol(msdd);

  crow   = msdd.nrow();
  uInt i;
  for ( i = 0;
	i < crow
	  &&  ( msddCol.spectralWindowId()(i) != spectral_window_id_ ||
		msddCol.polarizationId()(i)   != polarization_id_ ) ; 
	i++ );
  
  if (i < crow) return i;

  itsDDMgr.setDD(crow, polarization_id_, spectral_window_id_);
  msdd.addRow();
    
  msddCol.spectralWindowId().put(crow, spectral_window_id_);
  msddCol.polarizationId().put(crow, polarization_id_);
  msddCol.flagRow().put(crow, False);
    
  return crow;
}

// Test if the file corresponding to the given path exists.
// Returns : 3 if it exists and is writable.
//           2 if it does not exists and is writable.
//           1 if it exists and is non writable.
//           0 if it does not exist and is non writable.
int ASDM2MSFiller::exists( char *path) {

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
String ASDM2MSFiller::msPath() {
  return itsMSPath;
}

// Add a record in the table FEED
void ASDM2MSFiller::addFeed(int      antenna_id_,
			 int      feed_id_,
			 int      spectral_window_id_,
			 double   time_,
			 double   interval_,
			 int      num_receptors_,
			 int      beam_id_,
			 double   beam_offset_[],
			 const char     *pol_type_,
			 double   polarization_responseR_[],
			 double   polarization_responseI_[],
			 double   position_[3],
			 double   feed_angle_[]) {
  

  int crow;
  int  i, j, k;
  MSFeed msfeed = itsMS -> feed();
  MSFeedColumns msfeedCol(msfeed);

  //cout << "\nEntering addFeed";

  // Now we can put the values in a new row.
  Matrix<Double>   beamOffset(2, num_receptors_);
  Matrix<Complex>  polResponse(num_receptors_, num_receptors_);
  Vector<Double>   position(3);
  Vector<Double>   receptorAngle(num_receptors_);
  Vector<String>   polarizationType(num_receptors_);

  for (i=0; i<num_receptors_; i++) {
    beamOffset(0, i) = beam_offset_[2*i];
    beamOffset(1, i) = beam_offset_[2*i+1];
  }

  k = 0;
  for (j=0; j<num_receptors_; j++) {
    for(i=0; i<num_receptors_; i++) {
      polResponse(i, j) = Complex(polarization_responseR_[k],
				  polarization_responseI_[k]);
      k++;
    }
  }

  for (i=0; i<3; i++) {
    position(i) = position_[i];
  }

  for (i=0; i<num_receptors_; i++) {
    polarizationType(i) = String(pol_type_[i]);
    receptorAngle(i) = feed_angle_[i];
  }

  crow = msfeed.nrow();

  //cout << "\naddFeed : time="  << time_;
  msfeed.addRow();
  msfeedCol.antennaId().put(crow, antenna_id_);
  msfeedCol.feedId().put(crow, feed_id_);
  msfeedCol.spectralWindowId().put(crow, spectral_window_id_);
  msfeedCol.time().put(crow,time_);
  msfeedCol.interval().put(crow,interval_);
  msfeedCol.numReceptors().put(crow, num_receptors_);
  msfeedCol.beamId().put(crow, -1);
  msfeedCol.beamOffset().put(crow, beamOffset);
  msfeedCol.polarizationType().put(crow, polarizationType);
  msfeedCol.polResponse().put(crow, polResponse);
  msfeedCol.position().put(crow, position);
  msfeedCol.receptorAngle().put(crow, receptorAngle); 

  msfeed.flush();
  // cout << "\n Exiting addFeed";
}
	     

// Adds a field record in the TABLE
void ASDM2MSFiller::addField( const char   *name_,
			   const char   *code_,
			   double time_,
			   double delay_dir_[2],
			   double phase_dir_[2],
			   double reference_dir_[2],
			   int    source_id_) {
  uInt crow;
  // cout << "\naddField : entering";
  Matrix<Double>  delayDir(2,1);
  Matrix<Double>  referenceDir(2,1);
  Matrix<Double>  phaseDir(2,1);

  delayDir(0,0) = delay_dir_[0];
  delayDir(1,0) = delay_dir_[1];

  phaseDir(0,0) = phase_dir_[0];
  phaseDir(1,0) = phase_dir_[1];

  referenceDir(0,0) = reference_dir_[0];
  referenceDir(1,0) = reference_dir_[1];

  MSField msfield = itsMS -> field();
  MSFieldColumns msfieldCol(msfield);

  crow = msfield.nrow();
  msfield.addRow();

  msfieldCol.name().put(crow, String(name_));
  msfieldCol.code().put(crow, String(code_));
  msfieldCol.time().put(crow, time_);
  msfieldCol.numPoly().put(crow, 0);
  msfieldCol.delayDir().put(crow, delayDir);
  msfieldCol.phaseDir().put(crow, phaseDir);
  msfieldCol.referenceDir().put(crow, referenceDir);
  msfieldCol.sourceId().put(crow, source_id_);
  /*
  msfieldCol.sourceId().put(crow, -1);
  */
  msfieldCol.flagRow().put(crow, False);
  // cout << "\naddField : exiting";
  msfield.flush();
  // cout << "\n";
}
	       

// Add a record in the table FLAG_CMD;
void ASDM2MSFiller::addFlagCmd(double    time_,
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
  // cout << "\n";
}
			  
// Add a record in the table HISTORY
void ASDM2MSFiller::addHistory( double time_,
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
  // cout << "\n";
}
	     
// Adds a single observation record in the table OBSERVATION
void ASDM2MSFiller::addObservation(const char   *telescopeName_,
				double startTime_,
				double endTime_,
				const char   *observer_,
				const char   **log_,
				const char   *schedule_type_,
				const char   **schedule_,
				const char   *project_,
				double release_date_) {

  uInt crow;
  MSObservation msobs = itsMS -> observation();
  MSObservationColumns msobsCol(msobs);
  
  // cout << "\n addObservation: entering";
  // Build the log vector.
  Vector<String> log(1);
  int nLog = 0;  
  if (log_) {
     while (log_[nLog++]); nLog--; log.resize(nLog);
     for (int i = 0; i < nLog; i++) log(i) = log_[i];    
  }
  else
    log(0) =  "" ;


  // Build the schedule vector
  Vector<String> schedule(1);
  int nSchedule = 0;
  if (schedule_) {
    while (schedule_[nSchedule++]); nSchedule--; schedule.resize(nSchedule);
    for (int i = 0; i < nSchedule; i++) schedule(i) = schedule_[i];
  }
  else
    schedule(0) = "";

  Vector<Double> timeRange(2);
  
  timeRange(0) = startTime_;
  timeRange(1) = endTime_;

  // Fill the columns
  crow = msobs.nrow();
  /*
  itsObservationTimeMgr[0].setIndex(crow);
  */
  msobs.addRow();

  msobsCol.telescopeName().put(crow, String(telescopeName_));
  msobsCol.timeRange().put(crow, timeRange);
  msobsCol.observer().put(crow, String(observer_));
  msobsCol.log().put(crow, log);
  msobsCol.scheduleType().put(crow, schedule_type_);
  msobsCol.schedule().put(crow, schedule);
  msobsCol.project().put(crow, String(project_));
  msobsCol.releaseDate().put(crow, release_date_);
  msobsCol.flagRow().put(crow, False);
  msobs.flush();

  // cout << "\n addObservation: exiting";
  // cout << "\n";
}


// Adds a record in the table POINTING
void ASDM2MSFiller::addPointing(int     antenna_id_,
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



  //cout << "\n addPointing: entering";
  MSPointing mspointing = itsMS -> pointing();
  //cout << "\n addPointing: mspointing handled";

  MSPointingColumns mspointingCol(mspointing);
  //cout << "\n addPointing: mspointingColumns handled";

  crow = mspointing.nrow();

  // Keep the index in POINTING for this antenna for future time management.
  /*
  itsPointingTimeMgr[antenna_id_-1].setIndex(crow);
  itsPointingTimeMgr[antenna_id_-1].setStartTime(time_);
  */

  mspointing.addRow();
  //  cout << "\n addPointing: addRow ";

  mspointingCol.antennaId().put(crow, antenna_id_);
  //cout << "\n addPointing: antennaId ";
  mspointingCol.time().put(crow, time_);
  //cout << "\n addPointing: time ";
  mspointingCol.interval().put(crow, interval_);
  //cout << "\n addPointing: interval ";
  mspointingCol.name().put(crow, String(name_));
  //cout << "\n addPointing: name ";
  mspointingCol.numPoly().put(crow, 0);
  //cout << "\n addPointing: numPoly ";

  direction(0,0) = direction_[0];
  direction(1,0) = direction_[1];
  //cout << "\nDirection :" << direction(0,0) << "," << direction(1,0);
  target(0,0) = target_[0];
  target(1,0) = target_[1];
  //cout << "\nTarget :" << target(0,0) << "," << target(1,0);
 
  mspointingCol.direction().put(crow, direction);
  //cout << "\n addPointing: direction ";
  mspointingCol.target().put(crow, target);
  //cout << "\n addPointing: target ";

  if (pointing_offset_) {
    Matrix<Double>  pointingOffset(2,1);  
    pointingOffset(0,0) = pointing_offset_[0];
    pointingOffset(1,0) = pointing_offset_[1];
    mspointingCol.pointingOffset().put(crow, pointingOffset);
  }
  //cout << "\n addPointing: pointingOffset ";

  if (encoder_) {
    Vector<Double>  encoder(2);
    encoder(0) = encoder_[0];
    encoder(1) = encoder_[1];
    mspointingCol.encoder().put(crow,encoder);
  }

  mspointingCol.tracking().put(crow, ((tracking_)?True:False));
  
  mspointing.flush();

//   cout << "\n addPointing: exiting";
//   cout << "\n";
}
		 
// Adds a record in the table Polarization
int ASDM2MSFiller::addPolarization(int num_corr_,
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
  itsDDMgr.setNumCorr(crow, num_corr_);
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
  // cout << "\n";
  return crow;
}


int ASDM2MSFiller::addUniquePolarization(int num_corr_,
				      int corr_type_[],
				      int corr_product_[]) {
  uInt crow;
  int  i;
  Vector<Int>  corrType(IPosition(1, num_corr_), corr_type_, SHARE);
  Matrix<Int>  corrProduct(2, num_corr_);
  MSPolarization mspolar = itsMS -> polarization();
  MSPolarizationColumns mspolarCol(mspolar);

  crow = mspolar.nrow();

  /*
   * Look for an existing polarization
   */
  for (uInt i = 0; i < crow; i++) {
    if (mspolarCol.numCorr()(i) != num_corr_ ) continue;
    
    Vector<Int> _corrType = mspolarCol.corrType()(i);
    Int j;
    for ( j = 0 ; j < num_corr_ && ( _corrType(j) != (corrType(j) - 4) ) ; j++ ) {
      cout << _corrType(j) << " <-> " << corrType(j) << endl;
    }

    if ( j < num_corr_ ) {
      return i;
    }
  }

  /*
   * This polarization configuration has not been found
   * let's create a new row.
   */
  mspolar.addRow();
  mspolarCol.numCorr().put(crow, num_corr_);

  const char** p=getPolCombinations(num_corr_);
  for (i=0; i < num_corr_; i++) {
    corrType(i) = Stokes::type(p[i]);
    corrProduct(0, i) = Stokes::receptor1(Stokes::type(p[i]));
    corrProduct(1, i) = Stokes::receptor2(Stokes::type(p[i]));
  }
  mspolarCol.corrType().put(crow,corrType);
  mspolarCol.corrProduct().put(crow, corrProduct);

  // cout << "\n";
  return crow;
}


// Adds a record in the table PROCESSOR
void ASDM2MSFiller::addProcessor(const char *type_,
			      const char *sub_type_,
			      int  type_id_,
			      int  mode_id_) {
  uInt crow;
  MSProcessor msproc = itsMS -> processor();
  MSProcessorColumns msprocCol(msproc);

  crow = msproc.nrow();
  msproc.addRow();

  msprocCol.type().put(crow, String(type_));
  msprocCol.subType().put(crow, String(sub_type_));
  msprocCol.typeId().put(crow, type_id_);
  msprocCol.modeId().put(crow, mode_id_);
  
  msprocCol.flagRow().put(crow, False);

  msproc.flush();
  // cout << "\n";
}


// Adds a single state record in the table STATE in such a way that there is no repeated row.
// Returns the index of row added or found with these values. 
int ASDM2MSFiller::addUniqueState(Bool sig_,
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
void ASDM2MSFiller::addSource(int    source_id_,
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

      
  // Add a new row.
  int crow = mssource.nrow();
  mssource.addRow();

  Vector<Double> direction(2);
  direction(0) = direction_[0];
  direction(1) = direction_[1];

  Vector<Double> position(3);
  if (position_) {
  position(0) = position_[0];
  position(1) = position_[1];
  position(2) = position_[2];
  }
  
  Vector<Double>    properMotion(2);
  properMotion(0) = proper_motion_[0];
  properMotion(1) = proper_motion_[1];

  Vector<String>    transition(1);
  int numTransition = 0;
  while ( transition_ && transition_[numTransition++] ) ;
  if (numTransition > 0) {
    numTransition--;
    transition.resize( numTransition );
    for ( int i = 0; i < numTransition; i++ ) transition(i) = transition_[i]; 
  }
  else
    transition(0) = "";

  Vector<Double>    restFrequency(num_lines_);
  if ( rest_frequency_ ) {
    for (int i=0; i<num_lines_; i++) {
      restFrequency(i) = rest_frequency_[i];
    }
  }
  
  Vector<Double>    sysvel(num_lines_);
  if ( sysvel_ ) {
    for (int i=0; i<num_lines_; i++) {
      sysvel(i) = sysvel_[i];
    }
  }

  // Fill the new row
  mssourceCol.sourceId().put(crow,source_id_);
  mssourceCol.time().put(crow,time_);
  mssourceCol.interval().put(crow,interval_);
  mssourceCol.spectralWindowId().put(crow,spectral_window_id_);
  mssourceCol.numLines().put(crow,num_lines_);
  mssourceCol.name().put(crow,String(name_));
  mssourceCol.calibrationGroup().put(crow,calibration_group_);
  mssourceCol.code().put(crow,String(code_));
  mssourceCol.direction().put(crow,direction);
  if (position_) mssourceCol.position().put(crow,position);
  mssourceCol.properMotion().put(crow,properMotion);
  if ( transition_) mssourceCol.transition().put(crow,transition);
  if ( rest_frequency_ ) mssourceCol.restFrequency().put(crow,restFrequency);
  if ( sysvel_ ) mssourceCol.sysvel().put(crow,sysvel);
  
}

// Add a  record  in the table SPECTRAL_WINDOW
int ASDM2MSFiller::addSpectralWindow(int    num_chan_,
				  const char   *name_,
				  double ref_frequency_,
				  double chan_freq_[],
				  double chan_width_[],
				  int    meas_freq_ref_,
				  double effective_bw_[],
				  double resolution_[],
				  double total_bandwidth_,
				  int    net_side_band_,
				  int    if_conv_chain_,
				  int    freq_group_,
				  const char   *freq_group_name_,
				  int    num_assoc_,
				  int    assoc_spw_id_[],
				  char** assoc_nature_) {
  int i;

  MSSpectralWindow msspwin = itsMS -> spectralWindow();
  MSSpWindowColumns msspwinCol(msspwin);

  Vector<Double> chanFreq(num_chan_);
  Vector<Double> chanWidth(num_chan_);
  Vector<Double> effectiveBW(num_chan_);
  Vector<Double> resolution(num_chan_);
  uInt crow;
  
  crow = msspwin.nrow();
  itsDDMgr.setNumChan(crow, num_chan_);
  msspwin.addRow();
  
  msspwinCol.numChan().put(crow, num_chan_);
  msspwinCol.name().put(crow, String(name_));
  msspwinCol.refFrequency().put(crow, ref_frequency_);
  
  for (i=0; i<num_chan_; i++) {
    chanFreq(i)    = chan_freq_[i];
    chanWidth(i)   = chan_width_[i];
    effectiveBW(i) = effective_bw_[i];
    resolution(i)  = resolution_[i];
  }

  msspwinCol.chanFreq().put(crow, chanFreq);
  msspwinCol.chanWidth().put(crow, chanWidth);
  msspwinCol.effectiveBW().put(crow, effectiveBW);
  msspwinCol.resolution().put(crow, resolution);
  msspwinCol.measFreqRef().put(crow, meas_freq_ref_);
  msspwinCol.totalBandwidth().put(crow, total_bandwidth_);
  msspwinCol.netSideband().put(crow, net_side_band_);
  msspwinCol.ifConvChain().put(crow, if_conv_chain_);
  msspwinCol.freqGroup().put(crow, freq_group_);
  msspwinCol.freqGroupName().put(crow, String(freq_group_name_));
  /*
   * Put assoc informations if any.
   */
  if ( num_assoc_ && assoc_spw_id_ ) {
    msspwinCol.assocSpwId().put(crow, Vector<Int>(IPosition(1, num_assoc_), assoc_spw_id_, SHARE));
  }

  if ( assoc_nature_ ) {
    int numAssocNature = 0;
    Vector<String> assocNature(1);
    while (assoc_nature_[numAssocNature++]); numAssocNature--; assocNature.resize(numAssocNature);
    for (int iAssocNature = 0; iAssocNature < numAssocNature; iAssocNature++) assocNature(iAssocNature) = assoc_nature_[iAssocNature];
    msspwinCol.assocNature().put(crow, assocNature);
  }

  msspwinCol.flagRow().put(crow, False);

  msspwin.flush();
  // cout << "\n";
  return crow;
}


// Adds a single state record in the table STATE
void ASDM2MSFiller::addState(Bool   sig_,
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

  // cout << "\n";
}


// Adds a  record weather in the table WEATHER
void ASDM2MSFiller::addWeather(int antenna_id_,
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

  // cout << "\nEntering addWeather";
  MSWeather msweather = itsMS -> weather();
  MSWeatherColumns msweatherCol(msweather);

  // cout << "\nHandling msweatherCol";
  int crow;

  // If necessary update TIME and INTERVAL.
#if 0
  if ((crow = itsWeatherTimeMgr[antenna_id_-1].getIndex()) != -1) {
    float start = itsWeatherTimeMgr[antenna_id_-1].getStartTime();
    double midpoint = (time_ + start)/2;
    double interval = time_ - start;
    msweatherCol.time().put(crow, midpoint);
    msweatherCol.interval().put(crow, interval);
  }
#endif

  crow = msweather.nrow();

  // Keep the index in WEATHER for this antenna for future time management.
  /*
  itsWeatherTimeMgr[antenna_id_-1].setIndex(crow);
  itsWeatherTimeMgr[antenna_id_-1].setStartTime(time_);
  */
  msweather.addRow();
  
  // cout << "\nAdding a row";
  msweatherCol.antennaId().put(crow, antenna_id_-1);
  msweatherCol.interval().put(crow, interval_);
  msweatherCol.time().put(crow, time_);
#if 1
  msweatherCol.H2O().put(crow, h2o_);
  msweatherCol.pressure().put(crow, pressure_);
  msweatherCol.relHumidity().put(crow, rel_humidity_);
  msweatherCol.temperature().put(crow, temperature_);
  msweatherCol.dewPoint().put(crow, dew_point_);
  msweatherCol.windDirection().put(crow, wind_direction_);
  msweatherCol.windSpeed().put(crow, wind_speed_);
#endif
  msweather.flush();
  // cout << "\nExiting addWeather";
  // cout << "\n";
}

void ASDM2MSFiller::end(double time_) {

#if 0  
  int antenna_id;
  int crow;


  time_ = time_ + 1.0; /* To force a non null interval */

  MSFeedColumns msfeedCol(itsMS->feed());
  MSPointingColumns mspointingCol(itsMS->pointing());
  MSObservationColumns msobsCol(itsMS->observation());

  // Update time in FEED table. this is commented for now
  // Code below is not correct
  
  //cout << "\nEntering end";
  //cout << "\n";
  for (antenna_id = 0; antenna_id < itsNumAntenna; antenna_id++) {
    if ((crow = itsFeedTimeMgr[antenna_id].getIndex()) != -1) {
      double start = itsFeedTimeMgr[antenna_id].getStartTime();
      double midpoint = (time_ + start)/2;
      double interval = time_ - start;
      msfeedCol.time().put(crow, midpoint);
      msfeedCol.interval().put(crow, interval);
      /*
      cout << "\nFeed time update midpoint = "
	   << midpoint
	   << ", interval = "
	   << interval;
      */
    }
  }
  itsMS->feed().flush();


  // Update time in POINTING table
  // cout << "\nUpdating time in POINTING table";
    for (antenna_id = 0; antenna_id < itsNumAntenna; antenna_id++) {
      if ((crow = itsPointingTimeMgr[antenna_id].getIndex()) != -1) {
	double start = itsPointingTimeMgr[antenna_id].getStartTime();
	double midpoint = (time_ + start)/2;
	double interval = time_ - start;
	mspointingCol.time().put(crow, midpoint);
	mspointingCol.interval().put(crow, interval);
      }
    }
    itsMS->pointing().flush();
    

  // Update time in OBSERVATION table
  // cout << "\nUpdating time in OBSERVATION table";
  if ((crow = itsObservationTimeMgr[0].getIndex()) != -1) {
    double start =  itsObservationTimeMgr[0].getStartTime();
    double stop  =  time_;
    Vector<Double> timeRange(2);
    timeRange(0) = start;
    timeRange(1) = stop;
    msobsCol.timeRange().put(crow, timeRange);
  };
  itsMS->observation().flush();
#endif
  itsMS->flush(True);
  itsMS = 0;
  //cout << "\nExiting from end";
  //cout << "\n";
}

