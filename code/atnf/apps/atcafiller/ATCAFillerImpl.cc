//# ATCAFiller.cc: ATCA filler - reads rpfits, creates MeasurementSet
//# Copyright (C) 2004
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
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
//# $Id: ATCAFillerImpl.cc,v 1.11 2006/08/03 02:09:14 mwiering Exp $


#include <sstream>
#include <casa/stdio.h>
//
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Cube.h>
#include <casa/Arrays/MaskedArray.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayUtil.h>
#include <casa/BasicSL/Constants.h>
#include <scimath/Mathematics/FFTServer.h>
#include <measures/Measures/Stokes.h>
#include <measures/TableMeasures/TableQuantumDesc.h>


#include <casa/Logging.h>
#include <casa/Logging/LogIO.h>
#include <casa/Logging/LogSink.h>
#include <casa/Logging/LogMessage.h>

#include <casa/OS/Directory.h>
#include <casa/OS/DirectoryIterator.h>
#include <casa/OS/RegularFile.h>
#include <tables/Tables.h>
#include <tables/Tables/CompressComplex.h>
#include <tables/Tables/CompressFloat.h>
#include <casa/BasicSL/String.h>
#include <ATCAFiller.h>
#include <RPFITS.h>
#include <casa/Quanta/MVTime.h>
#include <ms/MeasurementSets/MSTileLayout.h>
#include <ms/MeasurementSets/MSSourceIndex.h>

Int myround(Double x) { return Int(floor(x+0.5));}

ATCAFiller::ATCAFiller(const String& msName,
		       const Vector<String>& rpfitsFiles,
		       const Vector<String>& options,
		       Float shadow,
		       Bool online):

options_p(options),
appendMode_p(False),
storedHeader_p(False),
skipScan_p(False),
skipData_p(False),
firstHeader_p(False),
listHeader_p(False),
fileSize_p(0),
onLine_p(online),
birdie_p(False),
reweight_p(False),
noxycorr_p(False),
obsType_p(0),
shadow_p(shadow),
autoFlag_p(True),
flagScanType_p(False),
flagCount_p(NFLAG,0)
{
  Int opt;

  LogOrigin orig("ATCAFiller", "ATCAFiller()", WHERE);
  os_p = LogIO(orig);  
  
  rpfitsFiles_p = Directory::shellExpand(rpfitsFiles, False);
  if (rpfitsFiles_p.nelements() > 0) {
     os_p << LogIO::NORMAL << "Expanded file names are : " << endl;
     for (uInt i=0; i<rpfitsFiles_p.nelements(); i++) {
       if (rpfitsFiles_p(i).empty()) {
          os_p << "Input file number " << i+1 << " is empty" << LogIO::EXCEPTION;
       }
//
       os_p << rpfitsFiles_p(i) << endl;
     }
  } else {
     os_p << "Input file names vector is empty" << LogIO::EXCEPTION;
  }
  if (options_p.nelements()==1) {
    Regex separator(" |,");
    Vector<String> opts=stringToVector(options_p(0),separator);
    if (opts.nelements()>1) options_p.reference(opts);
  }

  Bool compress=False;
  for (opt=0; opt<Int(options_p.nelements()); opt++) {
    if (downcase(options_p(opt)) == "birdie") {
      birdie_p = True;
    }
    if (downcase(options_p(opt)) == "reweight") {
      reweight_p = True;
    }
    if (downcase(options_p(opt)) == "noxycorr") {
      noxycorr_p = True;
    }
    if (downcase(options_p(opt)) == "compress") {
      compress = True;
    }
    if (downcase(options_p(opt)) == "fastmosaic") {
      obsType_p=1;
    }
    if (downcase(options_p(opt)) == "noautoflag") {
      autoFlag_p=False;
    }
    if (downcase(options_p(opt)) == "hires") {
      hires_p=True;
    }
  }
  if (shadow_p<0) shadow_p=0;
//
  atms_p = makeTable(msName,online,compress);
  msc_p = new MSColumns(atms_p);
  msScanInfo_p = atms_p.keywordSet().asTable("ATCA_SCAN_INFO");

  String comp;
  if (compress) comp="Comp";
  dataAccessor_p = TiledDataStManAccessor(atms_p,"TiledData"+comp);
  sigmaAccessor_p = TiledDataStManAccessor(atms_p,"TiledSigma");
  flagAccessor_p = TiledDataStManAccessor(atms_p,"TiledFlag");
  flagCatAccessor_p = TiledDataStManAccessor(atms_p,"TiledFlagCategory");


  if (online) {
    modelDataAccessor_p = TiledDataStManAccessor(atms_p, "TiledData-model"+comp);
    corrDataAccessor_p = TiledDataStManAccessor(atms_p,
        "TiledData-corrected"+comp);
    imWtAccessor_p =  TiledDataStManAccessor(atms_p, "TiledImagingWeight"+comp);
    os_p << LogIO::NORMAL << "ATCAFiller On-line mode enabled"<<LogIO::POST;
  }

  prev_fieldId_p = -1;
  lastWeatherUT_p=0;
  errCount_p=0;

  init();
}


ATCAFiller::~ATCAFiller() 
{
  delete msc_p;
}

TableDesc ATCAFiller::atcaTableDesc(Bool online, Bool compress)
{
  TableDesc td = MS::requiredTableDesc();
  // add the data column
  MS::addColumnToDesc(td,MS::DATA,2);
  // and its unit
  td.rwColumnDesc(MS::columnName(MS::DATA)).rwKeywordSet().define("UNIT","Jy");
  if (compress) {
    String col = MS::columnName(MS::DATA);
    td.addColumn(ArrayColumnDesc<Int>(col+"_COMPRESSED",
          "observed data compressed",2));
    td.addColumn(ScalarColumnDesc<Float>(col+"_SCALE"));
    td.addColumn(ScalarColumnDesc<Float>(col+"_OFFSET"));
  }
      
  // add ATCA specific columns here..
  MS::addColumnToDesc(td,MS::PULSAR_BIN);

  td.addColumn(ScalarColumnDesc<Int>("ATCA_SYSCAL_ID_ANT1",
				     "Index into SysCal table for Antenna1"));
  td.addColumn(ScalarColumnDesc<Int>("ATCA_SYSCAL_ID_ANT2",
				     "Index into SysCal table for Antenna2"));
  // the tiled column indices
  td.addColumn(ScalarColumnDesc<Int>("DATA_HYPERCUBE_ID",
				     "Index for Data Tiling"));
  td.addColumn(ScalarColumnDesc<Int>("SIGMA_HYPERCUBE_ID",
				     "Index for Sigma Tiling"));
  td.addColumn(ScalarColumnDesc<Int>("FLAG_HYPERCUBE_ID",
				     "Index for Flag Tiling"));
  td.addColumn(ScalarColumnDesc<Int>("FLAG_CATEGORY_HYPERCUBE_ID",
				     "Index for Flag Category Tiling"));

  if (online) {
    td.addColumn(ArrayColumnDesc<Complex>("MODEL_DATA","model data",2));
    td.addColumn(ScalarColumnDesc<Int>("MODEL_HYPERCUBE_ID","tile index"));
    td.addColumn(ArrayColumnDesc<Complex>("CORRECTED_DATA","corrected data",2));
    td.addColumn(ScalarColumnDesc<Int>("CORRECTED_HYPERCUBE_ID","tile index"));
    td.addColumn(ArrayColumnDesc<Float>("IMAGING_WEIGHT","imaging weight",1));
    td.addColumn(ScalarColumnDesc<Int>("IMAGING_WT_HYPERCUBE_ID","tile index"));
    if (compress) {
      String col="MODEL_DATA";
      td.addColumn(ArrayColumnDesc<Int>(col+"_COMPRESSED",
          "model data compressed",2));
      td.addColumn(ScalarColumnDesc<Float>(col+"_SCALE"));
      td.addColumn(ScalarColumnDesc<Float>(col+"_OFFSET"));
      col = "CORRECTED_DATA";
      td.addColumn(ArrayColumnDesc<Int>(col+"_COMPRESSED",
          "corrected data compressed",2));
      td.addColumn(ScalarColumnDesc<Float>(col+"_SCALE"));
      td.addColumn(ScalarColumnDesc<Float>(col+"_OFFSET"));
      col = "IMAGING_WEIGHT";
      td.addColumn(ArrayColumnDesc<Short>(col+"_COMPRESSED",
          "imaging weight compressed",1));
      td.addColumn(ScalarColumnDesc<Float>(col+"_SCALE"));
      td.addColumn(ScalarColumnDesc<Float>(col+"_OFFSET"));
    }
  }

  return td;
}

MeasurementSet ATCAFiller::makeTable(const String& tableName, Bool online,
      Bool compress)
{
  // make the MeasurementSet Table
  TableDesc atDesc = atcaTableDesc(online,compress);

  String colData = MS::columnName(MS::DATA);
  String comp1,comp2;
  if (compress) { comp1="Comp"; comp2="_COMPRESSED";}
  
  // define tiled hypercube for the data 
  Vector<String> coordColNames(0); //# don't use coord columns
  atDesc.defineHypercolumn("TiledData"+comp1,3,
			   stringToVector(colData+comp2),
			   coordColNames,
			   stringToVector("DATA_HYPERCUBE_ID"));
  atDesc.defineHypercolumn("TiledSigma",2,
			   stringToVector(MS::columnName(MS::SIGMA)),
			   coordColNames,
			   stringToVector("SIGMA_HYPERCUBE_ID"));
  atDesc.defineHypercolumn("TiledFlag",3,
			   stringToVector(MS::columnName(MS::FLAG)),
			   coordColNames,
			   stringToVector("FLAG_HYPERCUBE_ID"));
  atDesc.defineHypercolumn("TiledFlagCategory",4,
			   stringToVector(MS::columnName(MS::FLAG_CATEGORY)),
			   coordColNames,
			   stringToVector("FLAG_CATEGORY_HYPERCUBE_ID"));
  
  if (online) {
    
    atDesc.defineHypercolumn("TiledData-model"+comp1,3,
			     stringToVector("MODEL_DATA"+comp2),coordColNames,
			     stringToVector("MODEL_HYPERCUBE_ID"));
    
    
    atDesc.defineHypercolumn("TiledData-corrected"+comp1,3,
			     stringToVector("CORRECTED_DATA"+comp2),coordColNames,
			     stringToVector("CORRECTED_HYPERCUBE_ID"));
    
    
    atDesc.defineHypercolumn("TiledImagingWeight"+comp1,2,
			     stringToVector("IMAGING_WEIGHT"+comp2),
			     coordColNames,
			     stringToVector("IMAGING_WT_HYPERCUBE_ID")); 
  }
  
  SetupNewTable newtab(tableName, atDesc, Table::New);  
  
  // Set the default Storage Manager to be the incremental one
  IncrementalStMan incrStMan ("IncrementalData");
  newtab.bindAll(incrStMan, True);
  // Make an exception for fast varying data
  StandardStMan stStMan ("StandardData");
  newtab.bindColumn(MS::columnName(MS::UVW),stStMan);
  newtab.bindColumn(MS::columnName(MS::ANTENNA2),stStMan);
  newtab.bindColumn("ATCA_SYSCAL_ID_ANT2",stStMan);
  if (compress) {
    newtab.bindColumn(colData+"_SCALE",stStMan);
    newtab.bindColumn(colData+"_OFFSET",stStMan);
  }
  
    
  TiledDataStMan tiledStMan1("TiledData"+comp1);
  // Bind the DATA & FLAG column to the tiled stman
  newtab.bindColumn(MS::columnName(MS::DATA)+comp2,tiledStMan1);
  newtab.bindColumn("DATA_HYPERCUBE_ID",tiledStMan1);
  if (compress) {;
    CompressComplex ccData(colData,colData+"_COMPRESSED",
      colData+"_SCALE",colData+"_OFFSET", True);
    newtab.bindColumn(MS::columnName(MS::DATA),ccData);
  }
  
  TiledDataStMan tiledStMan2("TiledSigma");
  // Bind the SIGMA column to its own tiled stman
  newtab.bindColumn(MS::columnName(MS::SIGMA),tiledStMan2);
  newtab.bindColumn("SIGMA_HYPERCUBE_ID",tiledStMan2);

  TiledDataStMan tiledStMan3("TiledFlag");
  // Bind the FLAG column to its own tiled stman
  newtab.bindColumn(MS::columnName(MS::FLAG),tiledStMan3);
  newtab.bindColumn("FLAG_HYPERCUBE_ID",tiledStMan3);

  TiledDataStMan tiledStMan3c("TiledFlagCategory");
  // Bind the FLAG_CATEGORY column to its own tiled stman
  newtab.bindColumn(MS::columnName(MS::FLAG_CATEGORY),tiledStMan3c);
  newtab.bindColumn("FLAG_CATEGORY_HYPERCUBE_ID",tiledStMan3c);


  if (online) {

    TiledDataStMan tiledStMan4("TiledData-model");
    newtab.bindColumn(MS::columnName(MS::MODEL_DATA)+comp2,tiledStMan4);
    newtab.bindColumn("MODEL_HYPERCUBE_ID",tiledStMan4);
    
    TiledDataStMan tiledStMan5("TiledData-corrected");
    newtab.bindColumn(MS::columnName(MS::CORRECTED_DATA)+comp2,tiledStMan5);
    newtab.bindColumn("CORRECTED_HYPERCUBE_ID",tiledStMan5);
    
    TiledDataStMan tiledStMan6("TiledImagingWeight");
    newtab.bindColumn(MS::columnName(MS::IMAGING_WEIGHT)+comp2,tiledStMan6);
    newtab.bindColumn("IMAGING_WT_HYPERCUBE_ID",tiledStMan6);
    if (compress) {
      String col="MODEL_DATA";
      CompressComplex ccModelData(col,col+"_COMPRESSED",
        col+"_SCALE",col+"_OFFSET", True);
      newtab.bindColumn(col,ccModelData);
      col="CORRECTED_DATA";
      CompressComplex ccCorrectedData(col,col+"_COMPRESSED",
        col+"_SCALE",col+"_OFFSET", True);
      newtab.bindColumn(col,ccCorrectedData);
      col="IMAGING_WEIGHT";
      CompressFloat ccImagingWeight(col,col+"_COMPRESSED",
        col+"_SCALE",col+"_OFFSET", True);
      newtab.bindColumn(col,ccImagingWeight);      
    }
  }


  // create the table (with 0 rows)
  MeasurementSet ms(newtab, 0);
  // create the subtables
  makeSubTables(ms, Table::New);
  
  return ms;
}

void ATCAFiller::makeSubTables(MS& ms, Table::TableOption option)
{
  // This routine is modeled after MS::makeDummySubtables
  // we make new tables with 0 rows
  Int nrow=0;

  // Set up the subtables for the ATCA MS

  // Antenna
  TableDesc antTD=MSAntenna::requiredTableDesc();
  MSAntenna::addColumnToDesc(antTD, MSAntenna::PHASED_ARRAY_ID);
  MSAntenna::addColumnToDesc(antTD, MSAntenna::ORBIT_ID);
  SetupNewTable antennaSetup(ms.antennaTableName(),antTD,option);
  ms.rwKeywordSet().defineTable(MS::keywordName(MS::ANTENNA), 
				Table(antennaSetup,nrow));

  // Data descr
  TableDesc datadescTD=MSDataDescription::requiredTableDesc();
  SetupNewTable datadescSetup(ms.dataDescriptionTableName(),datadescTD,option);
  ms.rwKeywordSet().defineTable(MS::keywordName(MS::DATA_DESCRIPTION), 
				Table(datadescSetup,nrow));

  // Feed
  TableDesc feedTD=MSFeed::requiredTableDesc();
  MSFeed::addColumnToDesc(feedTD, MSFeed::PHASED_FEED_ID);
  SetupNewTable feedSetup(ms.feedTableName(),feedTD,option);
  ms.rwKeywordSet().defineTable(MS::keywordName(MS::FEED), 
				Table(feedSetup,nrow));

  // Field
  TableDesc fieldTD=MSField::requiredTableDesc();
  SetupNewTable fieldSetup(ms.fieldTableName(),fieldTD,option);
  ms.rwKeywordSet().defineTable(MS::keywordName(MS::FIELD), 
				Table(fieldSetup,nrow));

  // Flag_cmd
  TableDesc flagcmdTD=MSFlagCmd::requiredTableDesc();
  SetupNewTable flagcmdSetup(ms.flagCmdTableName(),flagcmdTD,option);
  ms.rwKeywordSet().defineTable(MS::keywordName(MS::FLAG_CMD), 
				Table(flagcmdSetup,nrow));


  // Observation
  TableDesc obsTD=MSObservation::requiredTableDesc();
  SetupNewTable observationSetup(ms.observationTableName(),obsTD,option);
  ms.rwKeywordSet().defineTable(MS::keywordName(MS::OBSERVATION), 
				Table(observationSetup,nrow));

  // History
  TableDesc historyTD=MSHistory::requiredTableDesc();
  SetupNewTable historySetup(ms.historyTableName(),historyTD,option);
  ms.rwKeywordSet().defineTable(MS::keywordName(MS::HISTORY), 
				Table(historySetup,nrow));

  // Pointing
  TableDesc pointingTD=MSPointing::requiredTableDesc();
  MSPointing::addColumnToDesc(pointingTD, MSPointing::POINTING_OFFSET);
  SetupNewTable pointingSetup(ms.pointingTableName(),pointingTD,option);
  // Pointing table can be large, set some sensible defaults for storageMgrs
  IncrementalStMan ismPointing ("ISMPointing");
  StandardStMan ssmPointing("SSMPointing",32768);
  pointingSetup.bindAll(ismPointing,True);
  pointingSetup.bindColumn(MSPointing::columnName(MSPointing::ANTENNA_ID),
			   ssmPointing);
  ms.rwKeywordSet().defineTable(MS::keywordName(MS::POINTING), 
				Table(pointingSetup,nrow));

  // Polarization
  TableDesc polTD=MSPolarization::requiredTableDesc();
  SetupNewTable polSetup(ms.polarizationTableName(),polTD,option);
  ms.rwKeywordSet().defineTable(MS::keywordName(MS::POLARIZATION), 
				Table(polSetup,nrow));

  // Processor
  TableDesc processorTD=MSProcessor::requiredTableDesc();
  SetupNewTable processorSetup(ms.processorTableName(),processorTD,option);
  ms.rwKeywordSet().defineTable(MS::keywordName(MS::PROCESSOR), 
				Table(processorSetup,nrow));

  // Source
  TableDesc sourceTD=MSSource::requiredTableDesc();
  MSSource::addColumnToDesc(sourceTD, MSSource::SYSVEL);
  MSSource::addColumnToDesc(sourceTD, MSSource::NUM_LINES);
  MSSource::addColumnToDesc(sourceTD, MSSource::TRANSITION);
  MSSource::addColumnToDesc(sourceTD, MSSource::REST_FREQUENCY);
  
  SetupNewTable sourceSetup(ms.sourceTableName(),sourceTD,option);
  ms.rwKeywordSet().defineTable(MS::keywordName(MS::SOURCE),
				Table(sourceSetup,nrow));
  

  // SpectralWindow
  TableDesc spwTD=MSSpectralWindow::requiredTableDesc();
  spwTD.addColumn(ScalarColumnDesc<Int>("ATCA_SAMPLER_BITS",
					"Number of bits used for sampling"));
  SetupNewTable spectralWindowSetup(ms.spectralWindowTableName(),spwTD,option);
  ms.rwKeywordSet().defineTable(MS::keywordName(MS::SPECTRAL_WINDOW),  
				Table(spectralWindowSetup,nrow));

  // State
  TableDesc stateTD=MSState::requiredTableDesc();
  SetupNewTable stateSetup(ms.stateTableName(),stateTD,option);
  ms.rwKeywordSet().defineTable(MS::keywordName(MS::STATE),
				Table(stateSetup,nrow));

  // SysCal
  TableDesc sysCalTD=MSSysCal::requiredTableDesc();
  sysCalTD.addColumn(ArrayColumnDesc<Float>
		     ("ATCA_SAMP_STATS_NEG",
		      "Sampler statistics, negative level",
		      IPosition(1,2),ColumnDesc::Direct));
  sysCalTD.addColumn(ArrayColumnDesc<Float>
		     ("ATCA_SAMP_STATS_ZERO",
		      "Sampler statistics, zero level",
		      IPosition(1,2),ColumnDesc::Direct));
  sysCalTD.addColumn(ArrayColumnDesc<Float>
		     ("ATCA_SAMP_STATS_POS",
		      "Sampler statistics, positive level",
		      IPosition(1,2),ColumnDesc::Direct));
  sysCalTD.addColumn(ScalarColumnDesc<Float>
		     ("ATCA_XY_AMPLITUDE",
		      "Noise source cross correlation amplitude"));
  sysCalTD.addColumn(ScalarColumnDesc<Float>
		     ("ATCA_TRACK_ERR_MAX",
		      "Max tracking error over non blanked cycle"));
  TableQuantumDesc tqd1(sysCalTD,"ATCA_TRACK_ERR_MAX",Unit("arcsec"));
  tqd1.write(sysCalTD);
  sysCalTD.addColumn(ScalarColumnDesc<Float>
		     ("ATCA_TRACK_ERR_RMS",
		      "RMS tracking error over non blanked cycle"));
  TableQuantumDesc tqd2(sysCalTD,"ATCA_TRACK_ERR_RMS",Unit("arcsec"));
  tqd2.write(sysCalTD);
 
  MSSysCal::addColumnToDesc(sysCalTD, MSSysCal::TSYS,
			       IPosition(1, 2), ColumnDesc::Direct);
  MSSysCal::addColumnToDesc(sysCalTD, MSSysCal::TCAL,
			       IPosition(1, 2), ColumnDesc::Direct);
  MSSysCal::addColumnToDesc(sysCalTD, MSSysCal::TRX,
			       IPosition(1, 2),ColumnDesc::Direct);
  MSSysCal::addColumnToDesc(sysCalTD, MSSysCal::TSYS_FLAG);
  MSSysCal::addColumnToDesc(sysCalTD, MSSysCal::PHASE_DIFF);
  MSSysCal::addColumnToDesc(sysCalTD, MSSysCal::PHASE_DIFF_FLAG);
  MSSysCal::addColumnToDesc(sysCalTD, MSSysCal::TCAL_FLAG);
  MSSysCal::addColumnToDesc(sysCalTD, MSSysCal::TRX_FLAG);

  sysCalTD.defineHypercolumn("TiledSysCal",2,stringToVector
			     (MSSysCal::columnName(MSSysCal::TSYS)+","+
			      "ATCA_SAMP_STATS_NEG,ATCA_SAMP_STATS_ZERO,"+
			      "ATCA_SAMP_STATS_POS"));
  SetupNewTable sysCalSetup(ms.sysCalTableName(),sysCalTD,option);
  IncrementalStMan incStMan;
  sysCalSetup.bindAll(incStMan);
  TiledColumnStMan tiledStManSysCal("TiledSysCal",IPosition(2,2,1024));
  
  sysCalSetup.bindColumn(MSSysCal::columnName(MSSysCal::TSYS),tiledStManSysCal);
  
  sysCalSetup.bindColumn("ATCA_SAMP_STATS_NEG",tiledStManSysCal);
  sysCalSetup.bindColumn("ATCA_SAMP_STATS_ZERO",tiledStManSysCal);
  sysCalSetup.bindColumn("ATCA_SAMP_STATS_POS",tiledStManSysCal);
  ms.rwKeywordSet().defineTable(ms.keywordName(MS::SYSCAL), 
				Table(sysCalSetup,nrow));

  // Weather
  TableDesc weatherTD=MSWeather::requiredTableDesc();
  MSWeather::addColumnToDesc(weatherTD,MSWeather::PRESSURE);
  MSWeather::addColumnToDesc(weatherTD,MSWeather::REL_HUMIDITY);
  MSWeather::addColumnToDesc(weatherTD,MSWeather::TEMPERATURE);
  MSWeather::addColumnToDesc(weatherTD,MSWeather::WIND_DIRECTION);
  MSWeather::addColumnToDesc(weatherTD,MSWeather::WIND_SPEED);
  MSWeather::addColumnToDesc(weatherTD,MSWeather::PRESSURE_FLAG);
  MSWeather::addColumnToDesc(weatherTD,MSWeather::REL_HUMIDITY_FLAG);
  MSWeather::addColumnToDesc(weatherTD,MSWeather::TEMPERATURE_FLAG);
  MSWeather::addColumnToDesc(weatherTD,MSWeather::WIND_DIRECTION_FLAG);
  MSWeather::addColumnToDesc(weatherTD,MSWeather::WIND_SPEED_FLAG);
  weatherTD.addColumn(ScalarColumnDesc<Float>
		     ("ATCA_RAIN_GAUGE",
		      "Rain since 10am local time"));
  TableQuantumDesc tqds0(weatherTD,"ATCA_RAIN_GAUGE",Unit("mm"));
  tqds0.write(weatherTD);
  weatherTD.addColumn(ScalarColumnDesc<Float>
		     ("ATCA_SEEMON_PHASE",
		      "Seeing monitor raw phase at 22GHz"));
  TableQuantumDesc tqds1(weatherTD,"ATCA_SEEMON_PHASE",Unit("rad"));
  tqds1.write(weatherTD);
  weatherTD.addColumn(ScalarColumnDesc<Float>
		     ("ATCA_SEEMON_RMS",
		      "Seeing monitor RMS phase"));
  TableQuantumDesc tqds2(weatherTD,"ATCA_SEEMON_RMS",Unit("mm"));
  tqds2.write(weatherTD);
  weatherTD.addColumn(ScalarColumnDesc<Bool>
		     ("ATCA_SEEMON_FLAG",
		      "Seeing monitor flag"));
  SetupNewTable weatherSetup(ms.weatherTableName(),weatherTD,option);
  ms.rwKeywordSet().defineTable(ms.keywordName(MS::WEATHER), 
				Table(weatherSetup,nrow));

  // ATCA_SCAN_INFO
  TableDesc atsiTD;
  atsiTD.addColumn(ScalarColumnDesc<Int>("ANTENNA_ID",
                                         "Antenna Id"));
  atsiTD.addColumn(ScalarColumnDesc<Int>("SCAN_ID",
                                         "Scan number from main table"));
  atsiTD.addColumn(ScalarColumnDesc<Int>("SPECTRAL_WINDOW_ID",
                                         "Spectral window Id"));
  atsiTD.addColumn(ArrayColumnDesc<Int>("FINE_ATTENUATOR",
					"Fine Attenuator setting A,B",
                                         IPosition(1,2),ColumnDesc::Direct));
  atsiTD.addColumn(ArrayColumnDesc<Int>("COARSE_ATTENUATOR",
					"COARSE Attenuator setting A,B",
                                         IPosition(1,2),ColumnDesc::Direct));
  atsiTD.addColumn(ArrayColumnDesc<Int>("MM_ATTENUATOR",
					"mm Attenuator setting A,B",
                                         IPosition(1,2),ColumnDesc::Direct));
  atsiTD.addColumn(ArrayColumnDesc<Float>("SUBREFLECTOR",
			          "Subreflector position(center,edge/tilt)",
                                         IPosition(1,2),ColumnDesc::Direct));
  TableQuantumDesc tqd3(atsiTD,"SUBREFLECTOR",Unit("m"));
  tqd3.write(atsiTD);
  atsiTD.addColumn(ScalarColumnDesc<String>("CORR_CONFIG",
					    "Correlator configuration"));
  atsiTD.addColumn(ScalarColumnDesc<String>("SCAN_TYPE",
					    "Scan type"));
  atsiTD.addColumn(ScalarColumnDesc<String>("COORD_TYPE",
					    "CAOBS Coordinate type"));
  atsiTD.addColumn(ScalarColumnDesc<String>("POINTING_INFO",
					    "Pointing info - details of last point scan"));
  atsiTD.addColumn(ScalarColumnDesc<Bool>("LINE_MODE",
					 "Line Mode: True=spectrum, False=mfs"));
  atsiTD.addColumn(ScalarColumnDesc<Int>("CACAL_CNT",
                                         "Online calibration counter"));
  
  SetupNewTable scanInfoSetup(ms.tableName()+"/ATCA_SCAN_INFO",atsiTD,option);
  IncrementalStMan incSIStMan("ISMScanInfo");
  StandardStMan stdSIStMan("SSMScanInfo",32768);
  scanInfoSetup.bindAll(incSIStMan);
  scanInfoSetup.bindColumn("ANTENNA_ID",stdSIStMan);
  ms.rwKeywordSet().defineTable("ATCA_SCAN_INFO",  
				Table(scanInfoSetup,nrow));

  // update the references to the subtable keywords
  //  cout << "ms table keywords: ";
  //  for (Int i=0; i<ms.keywordSet().nfields(); i++)
  //    cout << ms.keywordSet().name(i) << " ";
  //  cout << endl;
  ms.initRefs();

  // Some items we don't store at present:
  // SC table (System Calibration info)
  // scTd.addColumn(ScalarColumnDesc<Float>("ParalAngle","deg"));
  //
  // SH table (Scan Header info)
  // shTd.addColumn(ScalarColumnDesc<String>("Instrument"));   // strlen=16
  // shTd.addColumn(ScalarColumnDesc<String>("DateObserved")); // strlen=8
  // shTd.addColumn(ScalarColumnDesc<String>("DateWritten"));  // strlen=8
  // shTd.addColumn(ScalarColumnDesc<String>("DateSystem"));   // strlen=8
  // shTd.addColumn(ScalarColumnDesc<String>("Cal"));          // strlen=16
  // shTd.addColumn(ScalarColumnDesc<Double>("UTC-TAI"));
  // shTd.addColumn(ArrayColumnDesc<Double>("CParams","",IPosition(1,12),
  //					       ColumnDesc::Direct));
  // shTd.addColumn(ScalarColumnDesc<Double>("DJMRefP"));
  // shTd.addColumn(ScalarColumnDesc<Double>("DJMRefT"));
  // shTd.addColumn(ScalarColumnDesc<Int>("Defeat"));
  // shTd.addColumn(ScalarColumnDesc<Int>("NominalIntTime"));
  // shTd.addColumn(ArrayColumnDesc<Double>("ArrayXYZ","",IPosition(1,3),
  //					       ColumnDesc::Direct));

}


void ATCAFiller::init()
{
  //Initialize selection
  scanRange(0, 0);
  freqRange(0.0,1.e30);
  freqChain(0);
  Vector<String> fieldNames(0);
  fields(fieldNames);

  // optional columns 

  // scanheader table columns
  // cObserver.attach(scanHeaderTable,"Observer");
  // cInstrument.attach(scanHeaderTable,"Instrument");
  // cDateObserved.attach(scanHeaderTable,"DateObserved");
  // cDateWritten.attach(scanHeaderTable,"DateWritten");
  // cDateSystem.attach(scanHeaderTable,"DateSystem");
  // cSHCal.attach(scanHeaderTable,"Cal");
  // cUTC_TAI.attach(scanHeaderTable,"UTC-TAI");
  // cSHCParams.attach(scanHeaderTable,"CParams");
  // cSHDJMRefP.attach(scanHeaderTable,"DJMRefP");
  // cSHDJMRefT.attach(scanHeaderTable,"DJMRefT");
  // cSHDefeat.attach(scanHeaderTable,"Defeat");
  // cSHIntTime.attach(scanHeaderTable,"NominalIntTime");
  // cArrayXYZ.attach(scanHeaderTable,"ArrayXYZ");
  
  // extra ID columns in main table
  colSysCalIdAnt1.attach(atms_p,"ATCA_SYSCAL_ID_ANT1");
  colSysCalIdAnt2.attach(atms_p,"ATCA_SYSCAL_ID_ANT2");

  // extra spectralWindow table columns
  colSamplerBits.attach(atms_p.spectralWindow(),"ATCA_SAMPLER_BITS");

  // extra syscal table columns
  colSamplerStatsNeg.attach(atms_p.sysCal(),"ATCA_SAMP_STATS_NEG");
  colSamplerStatsZero.attach(atms_p.sysCal(),"ATCA_SAMP_STATS_ZERO");
  colSamplerStatsPos.attach(atms_p.sysCal(),"ATCA_SAMP_STATS_POS");
  // cParAngle.attach(sysCalTable,"ParalAngle");
  colXYAmplitude.attach(atms_p.sysCal(),"ATCA_XY_AMPLITUDE");
  colTrackErrMax.attach(atms_p.sysCal(),"ATCA_TRACK_ERR_MAX");
  colTrackErrRMS.attach(atms_p.sysCal(),"ATCA_TRACK_ERR_RMS");
  
  // ScanInfo table columns
  Table sit(atms_p.keywordSet().asTable("ATCA_SCAN_INFO"));
  colScanInfoAntId.attach(sit,"ANTENNA_ID");
  colScanInfoScanId.attach(sit,"SCAN_ID");
  colScanInfoSpWId.attach(sit,"SPECTRAL_WINDOW_ID");
  colScanInfoCacal.attach(sit,"CACAL_CNT");
  colScanInfoFine.attach(sit,"FINE_ATTENUATOR");
  colScanInfoCoarse.attach(sit,"COARSE_ATTENUATOR");
  colScanInfommAtt.attach(sit,"MM_ATTENUATOR");
  colScanInfoSubreflector.attach(sit,"SUBREFLECTOR");
  colScanInfoCorrConfig.attach(sit,"CORR_CONFIG");
  colScanInfoScanType.attach(sit,"SCAN_TYPE");
  colScanInfoCoordType.attach(sit,"COORD_TYPE");
  colScanInfoPointInfo.attach(sit,"POINTING_INFO");
  colScanInfoLineMode.attach(sit,"LINE_MODE");

  // Extra weather table columns
  colWeatherRainGauge.attach(atms_p.weather(),"ATCA_RAIN_GAUGE");
  colWeatherSeeMonPhase.attach(atms_p.weather(),"ATCA_SEEMON_PHASE");
  colWeatherSeeMonRMS.attach(atms_p.weather(),"ATCA_SEEMON_RMS");
  colWeatherSeeMonFlag.attach(atms_p.weather(),"ATCA_SEEMON_FLAG");
 
  nScan_p=nSpW_p=nField_p=scanNo_p=0;
  gotAN_p=False;
}

// list the current scan and return the current day in mjd
void ATCAFiller::listScan(Double & mjd, Int scan, Double ut)
{
  // Convert observation date to mjd 
    Int day,month,year;
    sscanf(names_.datobs,"%4d-%2d-%2d",&year,&month,&day);
    MVTime mjd_date(year,month,(Double)day);
    mjd=mjd_date.second();
    mjd_date=MVTime((mjd_date.second()+ut)/C::day);
    os_p << LogIO::NORMAL << "Scan #   : "<< scan << endl;
    os_p << LogIO::NORMAL << "Object   : "<< String(names_.object,16) << endl;
    os_p << LogIO::NORMAL << "Date     : "<< mjd_date.string(MVTime::YMD) 
	 << LogIO::POST;
}


String ATCAFiller::fill() {

  if (!appendMode_p) {
    firstHeader_p = True;
    skipScan_p=False;
    skipData_p=False;

    nScan_p=1; // we've seen the 1st header
    scanNo_p=-1; // make zero based for storage in MS

    Int fileno;
    Int offset=0;
    if (onLine_p) offset=1;

    for (fileno=0; fileno<Int(rpfitsFiles_p.nelements())-offset; fileno++) {
      listHeader_p = True;
      currentFile_p = rpfitsFiles_p(fileno);
      fill1(currentFile_p);
    }

    if (onLine_p) {
      currentFile_p = rpfitsFiles_p(fileno);
      appendMode_p = True;
      listHeader_p = True;
      fill1(currentFile_p);
    }

    os_p << LogIO::DEBUGGING << "FillFeed" << LogIO::POST;
    fillFeedTable();

    fillObservationTable();

    fillMeasureReferences();
    os_p << LogIO::DEBUGGING << "#spectral windows " << nSpW_p << LogIO::POST;


  } else { // appendMode
    if (!eof_p) { 
      fill1(currentFile_p);
    } else {

      RegularFile rFile(currentFile_p);
      uInt newSize = rFile.size();
      os_p << LogIO::NORMAL << "new file size " << newSize << LogIO::POST;
      
      if ( newSize != fileSize_p) {
	fill1(currentFile_p);
      } else {
	
	Int jstat=1; // close file
	rpfitsin_(&jstat, vis, weight, &baseline, &ut, &u, &v, &w, 
		  &flg, &bin, &if_no, &sourceno);  
	
	os_p << LogIO::NORMAL << "Look for next file ..." << LogIO::POST;
	
	Regex separator("/");
	Vector<String> elts=stringToVector(currentFile_p,separator);
	String rpfitsDir_p = "";
	if (elts.nelements()>1) {
	  Int m = elts.nelements() - 1;
	  for (Int n=0; n < m; n++) {
	    rpfitsDir_p = rpfitsDir_p + elts(n) + "/";
	  }
	}
	os_p << LogIO::DEBUGGING << "RPFITSDIR : " << rpfitsDir_p << LogIO::POST;

	Directory dir(rpfitsDir_p);
	Regex regexp(".*\\.[cxv]+[0-9]+");
	
	DirectoryIterator dirIter(dir, regexp);
	
	String entry;
	Bool found = False;
	while (!dirIter.pastEnd()) {
	  entry = rpfitsDir_p+dirIter.name();
	  os_p << LogIO::DEBUGGING << " file: "<< entry << LogIO::POST;
	  if (found) break;
	  if (entry == currentFile_p) found = True;
	  dirIter++;
	}
	
	os_p << LogIO::NORMAL << " new file: "<< entry << LogIO::POST;
	
	if (entry == currentFile_p) {
	  os_p << LogIO::NORMAL << " No new file..."<< LogIO::POST;
	} else {
	  String oldstr = String(currentFile_p.at(1, currentFile_p.length()));
	  os_p << LogIO::DEBUGGING << " oldstr... "<< oldstr << LogIO::POST;
	  String newstr = String(entry.at(1, entry.length()));
	  os_p << LogIO::DEBUGGING << " newstr... "<< newstr << LogIO::POST;
	  
	  if (oldstr.after(Regex(".*\\.")) != newstr.after(Regex(".*\\."))) {
	    os_p << LogIO::NORMAL << " Project changed..."<< LogIO::POST;
	  } else {
	    currentFile_p = entry;
	    listHeader_p = True;
	    fill1(currentFile_p);
	  }
	}
      }
    }
  }

  // flag the last integration for shadowing
  if (shadow_p>0) shadow(0,True);

  // make sure the channel selection keyword is set correctly
  if (onLine_p) {
    MSSpWindowColumns msSpW(atms_p.spectralWindow());
    Matrix<Int> selection(2,nSpW_p);
    
    // fill in default selection
    selection.row(0)=0; //start
    selection.row(1)=msSpW.numChan().getColumn(); 
    ArrayColumn<Complex> mcd(atms_p,"MODEL_DATA");
    mcd.rwKeywordSet().define("CHANNEL_SELECTION",selection);


    return currentFile_p+" "+sources_p;
    //    return currentFile_p+" "+String(names_.object,16);

  } else {
    // flush the table and unlock it
    // NOTE: this still keeps a reference to the table which causes problems
    // when the ms do calls close (it wants to write to the table)
    flush();
    unlock();

    return "";
  }
}


Bool ATCAFiller::fill1(const String& rpfitsFile)
{
  Int jstat;  
  Regex trailing(" *$"); // trailing blanks

  String file = rpfitsFile;
  if (listHeader_p == True) {
    os_p << LogIO::NORMAL <<"Reading file "<<file<< LogIO::POST;
    strcpy(names_.file,file.chars());
    jstat=-2; // open rpfits file and read first header
    param_.ncard=-1; // collect cards into card array
    rpfitsin_(&jstat, vis, weight, &baseline, &ut, &u, &v, &w, &flg, &bin,
	      &if_no, &sourceno);  
    if (jstat==-1) {
      os_p << LogIO::SEVERE << " Error opening RPFits file: "<<file
	   << LogIO::POST;
      return False;
    }
  }
  // Otherwise we enter fill1 for the second time with the same file name

    // prepare to read data blocks, rpfitsin will tell us if
    // there is a header to be read instead
    jstat=0; 
    
    Double lastUT=0,lastUT2=0;
    Int lastScanNo=-1,lastIF=-1;
    flagCount_p=0;
    while (jstat==0) {
      rpfitsin_(&jstat, vis, weight, &baseline, &ut, &u, &v, &w, &flg, &bin,
		&if_no, &sourceno);

      switch(jstat) {
      case -1: // read failed
	os_p << LogIO::WARN << 
	  "rpfitsin: read failed, retrying"<< LogIO::POST;
	jstat=0;
	break;
      case 0: // found data: store header (incl Tables) and data
	if (listHeader_p) { listScan(mjd0_p,nScan_p,ut); listHeader_p=False;}

	// do we want this scan?
	if (skipScan_p || nScan_p<firstScan_p || 
	    (lastScan_p>0 && nScan_p>lastScan_p)) 
	  skipScan_p=True;
	else {
	  // if_no and sourceno are not (always) set properly
	  //   for syscal records
	  if (baseline==-1) {if_no=1; sourceno=1;} 

	  // check if ifchain could be selected and if_no valid
	  if (!if_.if_found|| ifChain_p>if_.n_if|| if_no>if_.n_if) 
	    skipScan_p=True;  // assume not wanted or ^  garbled data
	  else {
	    // check if we want this field
            if (lastUT!=ut) {
	      String field=String(names_.object,16).before(trailing);
	      if (fieldSelection_p.nelements()>0 && 
		  !(anyEQ(fieldSelection_p,field))) {
	        skipScan_p=True;
	      }
            }
	    if (!skipScan_p) {
	      if_no--; // go from 1-based to 0-based indexing (f2c)
	      sourceno--; // same here
	      // skip unselected or garbled data
	      skipData_p=Bool(if_no<0 || !selected(if_no) || sourceno<0);
	    }
	  }
	}
	if (!skipScan_p && !skipData_p && firstHeader_p && anten_.nant>0) {
	  nAnt_p=anten_.nant;
	  Int NChan=if_.if_nfreq[if_no];
	  Int NPol=if_.if_nstok[if_no];
	  firstHeader_p=False;
	  os_p << LogIO::NORMAL << " First data/header has NAnt="<<nAnt_p<<
	    ", NChan="<<NChan<<", NPol="<<NPol<< LogIO::POST;
	} 
	if (!skipScan_p && !skipData_p) {
	  if (anten_.nant>0 && anten_.nant!=nAnt_p) {
	    os_p << LogIO::WARN << "#antennas changed from "<< nAnt_p <<
	      " to "<<anten_.nant<<", skipping scan"<< LogIO::POST;
	    skipScan_p=True;
	  }
	}
	if (!skipScan_p && !skipData_p && !storedHeader_p) {
	  storeHeader();
	  scanNo_p++; 
	  storedHeader_p=True;
	}
	if (!skipScan_p) {
	  if (baseline==-1) {
	    // we want at least some of the syscal data for this scan
	    storeSysCal();
	  }
	  else if (!skipData_p) {
            if (lastUT2!=ut || lastIF!=if_no){
              checkSpW(if_no); // we need to check these every integration to
	      if (lastUT2!=ut) checkField();// cope with freq. switching and mosaicing
              lastUT2=ut;
              lastIF=if_no;
            }          
            storeData();
	  }
	}
	skipData_p=False;
	break;
      case 1:
	if (skipScan_p || scanNo_p==lastScanNo) {
           os_p << LogIO::NORMAL << "Scan "<<nScan_p <<" skipped"<<LogIO::POST;
	} else {
	  os_p << LogIO::NORMAL << "Scan "<<nScan_p <<" stored"<< LogIO::POST;
        }
        lastScanNo=scanNo_p;
	nScan_p++;
        errCount_p=0;
	os_p << LogIO::DEBUGGING << "Read new header "<< LogIO::POST;
	jstat=-1;
        param_.ncard=-1;
	rpfitsin_(&jstat, vis, weight, &baseline, &ut, &u, &v, &w, 
		  &flg, &bin, &if_no, &sourceno);  
	jstat=0;
	
	listScan(mjd0_p,nScan_p,ut);
	storedHeader_p=False;
	skipScan_p=False;
	eof_p = False;
	if (!onLine_p || !appendMode_p) break;
	// suppress this break to return after each end of scan
	// (actually each beginning of a new scan) in on line mode

      case 3:
	if (jstat == 3) {  // because of the break suppression in case 1
 	  if (!skipScan_p && !skipData_p && !storedHeader_p) {
	    storeHeader(); // store sole header at end of file
	    scanNo_p++;    // to capture last commands & log messages
	    storedHeader_p=True;
	  }
	  os_p << LogIO::NORMAL << "End of File" << LogIO::POST;
	  eof_p = True;
	  nScan_p++; // increment for next scan
          // print flagging stats for last scan
          if (flagCount_p(COUNT)>0) {
            Vector<Float> perc(NFLAG);
            for (Int i=0; i<NFLAG; i++) perc(i)=0.1*((1000*flagCount_p(i))/flagCount_p(COUNT));
            os_p<< LogIO::NORMAL <<"Number of rows selected  : "<<flagCount_p(COUNT)<<endl; 
            os_p<< LogIO::NORMAL <<"Flagged                  : "<<perc(FLAG)<<"%"<<endl; 
            os_p<< LogIO::NORMAL <<"  Antenna off source     : "<<perc(ONLINE)<<"%"<<endl; 
            os_p<< LogIO::NORMAL <<"  ScanType (Point/Paddle): "<<perc(SCANTYPE)<<"%"<<endl; 
            os_p<< LogIO::NORMAL <<"  Bad Sampler stats      : "<<perc(SYSCAL)<<"%"<<endl; 
            os_p<< LogIO::NORMAL <<"  Antenna shadowed       : "<<perc(SHADOW)<<"%"<<LogIO::POST; 
          }
	}
	
	if (appendMode_p) {
	  // after bumping one time at the end of the file or after the
	  // first scan

	  RegularFile rFile(file);
	  fileSize_p = rFile.size();

	  os_p << LogIO::NORMAL << "old file size " << fileSize_p 
	       << " Waiting ..." << LogIO::POST;

	  flush();
	  unlock();

	} else {
	  jstat=1; // close file
	  rpfitsin_(&jstat, vis, weight, &baseline, &ut, &u, &v, &w, 
		    &flg, &bin, &if_no, &sourceno);  
	}
	jstat=1; // exit loop
	break;
      case 4:
	os_p << LogIO::WARN 
	     << "rpfitsin: found FG Table, ignoring it"
	     << LogIO::POST;
	jstat=0;
	break;
      case 5:
	// jstat == 5 is usually record padding at the end of an integration.
	// just continue on loading..
	jstat=0;
	break;
      default:
	os_p << LogIO::WARN << "unknown rpfitsin return value: "
	     <<jstat<< LogIO::POST;
	jstat=0;
      }
      lastUT=ut;
    }



  // uncomment this if things take unexpectedly long
  // dataAccessor_p.showCacheStatistics(cout);
  // sigmaAccessor_p.showCacheStatistics(cout);
  return True;
}




void ATCAFiller::fillMeasureReferences() 
{
  String key("MEASURE_REFERENCE");
  msc_p->time().rwKeywordSet().define(key,"UTC");
  msc_p->uvw().rwKeywordSet().define(key,"J2000");
  msc_p->antenna().position().rwKeywordSet().define(key,"ITRF");
  msc_p->feed().time().rwKeywordSet().define(key,"UTC");
  msc_p->field().time().rwKeywordSet().define(key,"UTC");
  msc_p->field().delayDir().rwKeywordSet().define(key,"J2000");
  msc_p->field().phaseDir().rwKeywordSet().define(key,"J2000");
  msc_p->field().referenceDir().rwKeywordSet().define(key,"J2000");
  msc_p->source().time().rwKeywordSet().define(key,"UTC");
  msc_p->source().direction().rwKeywordSet().define(key,"J2000");
  msc_p->history().time().rwKeywordSet().define(key,"UTC");
  msc_p->spectralWindow().chanFreq().rwKeywordSet().define(key,"TOPO");
  msc_p->spectralWindow().refFrequency().rwKeywordSet().define(key,"TOPO");
  
  MFrequency::Types tp;
  MFrequency::getType(tp, msc_p->spectralWindow().refFrequency().keywordSet().asString("MEASURE_REFERENCE"));
  Int meas_freq_ref = tp;
  msc_p->spectralWindow().measFreqRef().fillColumn(meas_freq_ref);
  msc_p->sysCal().time().rwKeywordSet().define(key,"UTC");
  msc_p->weather().time().rwKeywordSet().define(key,"UTC");
  msc_p->pointing().direction().rwKeywordSet().define(key,"J2000");
  msc_p->pointing().pointingOffset().rwKeywordSet().define(key,"AZEL");
}

ATCAFiller & ATCAFiller::scanRange(Int first, Int last)
{
  firstScan_p=first; 
  lastScan_p=max(0,last);
  return *this;
}

ATCAFiller & ATCAFiller::freqRange(Double low, Double high)
{ 
  lowFreq_p=low;
  highFreq_p=high;
  return *this;
}

ATCAFiller & ATCAFiller::freqChain(Int chain)
{ 
  ifChain_p=min(chain,Int(MaxNSimulFreq));
  return *this;
}

ATCAFiller & ATCAFiller::fields(const Vector<String>& fieldList)
{
  fieldSelection_p=fieldList;
  return *this;
}

ATCAFiller & ATCAFiller::bandwidth1(Int bandwidth1)
{ 
  bandWidth1_p=0;
  for (Int bw=2; bw<=256; bw*=2) {
    if(bw==bandwidth1) {
      bandWidth1_p=bw;
      break;
    }
  }
  return *this;
}

ATCAFiller & ATCAFiller::numchan1(Int numchan1)
{ 
  numChan1_p=0;
  for (Int nchan=32; nchan<=16384; nchan*=2) {
    if((numchan1==nchan) || (numchan1==(nchan+1))) {
      numChan1_p=nchan+1;
      break;
    }
  }  
  return *this;
}

void ATCAFiller::storeHeader() {
  //  Bool skip=False;
  Regex trailing(" *$"); // trailing blanks

  // First check antenna Table and store any new stations encountered
  if (!gotAN_p && anten_.nant>0) {
    if (anten_.an_found) {
      gotAN_p=True;
      
      for (Int i=0; i<nAnt_p; i++) {
	Int ant=Int(anten_.ant_num[i]); // 1-based !
	if (ant!=i+1) { 
	  os_p << LogIO::SEVERE 
	       << "AN table corrupt, will try next one"
	       << LogIO::POST;
	  gotAN_p=False;
	  break;
	}
	atms_p.antenna().addRow();
	Int n=atms_p.antenna().nrow()-1;

        String instrument = String(names_.instrument,16).before(trailing);
	String station(&names_.sta[i*8],8);
	os_p << LogIO::NORMAL <<"Antenna  : "<< station << " ";
	Vector<Double> xyz(3); 
	xyz(0)=doubles_.x[i];xyz(1)=doubles_.y[i];xyz(2)=doubles_.z[i];
	os_p << " position:"<<xyz << endl;
        if (instrument=="ATCA") {
          String antName;
          // construct antenna name
          ostringstream ostr; ostr << "CA0" <<i+1;
          String str = ostr.str();
          msc_p->antenna().name().put(n,str);
  	  msc_p->antenna().station().put(n,atcaPosToStation(xyz));         
        } else {
  	  msc_p->antenna().station().put(n,station.before(trailing));
  	  msc_p->antenna().name().put(n,station.before(trailing));
        }  
	msc_p->antenna().orbitId().put(n,-1);
	msc_p->antenna().phasedArrayId().put(n,-1);
	msc_p->antenna().dishDiameter().put(n,22.0);
	msc_p->antenna().type().put(n, "GROUND-BASED");

	if (anten_.ant_mount[i]==0) {
	  msc_p->antenna().mount().put(n,"alt-az");
	}
	else {
	  msc_p->antenna().mount().put(n,"bizarre");
	}
	msc_p->antenna().position().put(n,xyz);
	Vector<Double> offset(3); offset=0.; 
	// todo: figure out coordinate system of offset
	offset(0)=doubles_.axis_offset[i];
	msc_p->antenna().offset().put(n,offset);
	// todo: values below may have to be stored elsewhere
	//Vector<String> ft(2);
	//ft(0)=String(&names_.feed_type[i*4],2);
	//ft(1)=String(&names_.feed_type[i*4+2],2);
	//		cFeedType.put(n,ft);
	//Vector<Double> pa(2);
	//pa(0)=doubles_.feed_pa[i*2];pa(1)=doubles_.feed_pa[i*2+1];
	// cFeedPA.put(n,pa);
	//Matrix<Double> feedcal(1,1);//feedcal :split out on if and pol?
	//feedcal(0,0)=0.0;
	// cFeedCal.put(n,feedcal);
      }
      os_p.post();
    } else {
       os_p << LogIO::SEVERE << 
	 "No AN Table found before start of data!"<< LogIO::POST;
    }
  }

  // Check if current if_no already in SpW Table, add it if not.
  checkSpW(if_no);
  
  // Check if current Observation info already stored, add it if not
  checkObservation();
  
  // Store the ATCA header cards
  storeATCAHeader();

  // Check if we've seen current source before, if not add to table
  checkField();
}

void ATCAFiller::storeATCAHeader() {
  uInt ncard = abs(param_.ncard);
  //cout<<" #cards = "<<ncard<<endl;
  String cards = String(names_.card,ncard*80);
  const Int nTypes = 10;
  Block<String> types(nTypes);
  types[0]=  "OBSLOG";
  types[1] = "ATTEN";
  types[2] = "SUBREFL";
  types[3] = "CORR_CFG";
  types[4] = "SCANTYPE";
  types[5] = "COORDTYP";
  types[6] = "LINEMODE";
  types[7] = "CACALCNT";
  types[8] = "POINTCOR";
  types[9] = "POINTINF";
  String obsLog = "";
  String config = "none";
  const Int nIF = if_.n_if;
  const Int nAnt = anten_.nant;
  Cube<Int> fine(2,nIF,nAnt),coarse(2,nIF,6);
  Matrix<Int> mmAtt(nIF,nAnt);
  Vector<Float> subrPos(nAnt,0),subrTilt(nAnt,0);
  Matrix<Float> pointCorr(2,nAnt,0);
  newPointingCorr_p=False;
  flagScanType_p=False;
  String scanType,coordType,pointInfo;
  Vector<Bool> lineMode(nIF);
  Int cacalCnt=0;
  const Regex trailing(" *$"); // trailing blanks
  Bool foundAny = False;
  String::size_type pos=cards.find("PNTCENTR");
  if (pos==String::npos) return;
  uInt iFirst=pos/80;
  for (uInt i=iFirst; i<ncard; i++) {
    // extract card
    String card = cards.substr(i*80,80);
    // read antenna number (if present)
    Int ant = 0;
    pos=card.find("CA0");
    if (pos!=String::npos) istringstream(card.substr(pos+2,2))>> ant;
    ant-=1; // zero based indexing
    if (ant>=nAnt) ant = -1;
    for (Int j=0; j<nTypes; j++) {
      if (card.find(types[j])==0) {
        foundAny=True;
        //cout << "Found card :"<<types[j]<<", ant="<<ant<<endl;
        switch (j) {
        case 0: obsLog+=card.substr(8,72).before(trailing);
                obsLog+="\n";
                break;
        case 1: { //ATTEN
                  uInt pos=card.find("FINE=");
                  if (pos!=String::npos && ant>=0) {
                    for (Int k=0; k<nIF; k++) {
                      istringstream(card.substr(pos+5+k*2,1))>>fine(0,k,ant);
                      istringstream(card.substr(pos+6+k*2,1))>>fine(1,k,ant);
                    }
                  }
                  pos=card.find("COARSE=");
                  if (pos!=String::npos && ant>=0) {
                    for (Int k=0; k<nIF; k++) {
                     istringstream(card.substr(pos+7+k*2,1))>>coarse(0,k,ant);
                      istringstream(card.substr(pos+8+k*2,1))>>coarse(1,k,ant);
                    }
                  }
                  pos=card.find("MM=");
                  if (pos!=String::npos && ant>=0) {
                    istringstream(card.substr(pos+3,2))>>mmAtt(0,ant);
                    istringstream(card.substr(pos+6,2))>>mmAtt(1,ant);
                  }
                }
                break;
        case 2: { //SUBREFL
                  uInt pos=card.find("POS=");
                  if (pos!=String::npos && ant>=0) {
                    istringstream(card.substr(pos+4,6))>>subrPos(ant);
                  }
                  pos=card.find("TILT=");
                  if (pos!=String::npos && ant>=0) {
                    istringstream(card.substr(pos+5,6))>>subrTilt(ant);
                  }
                }
                break;
        case 3: {// CORR_CFG
                  uInt pos=card.find("=");
                  if (pos!=String::npos) {
                    config=card.substr(pos+3,80-pos-3).before(trailing);
                  }
                }
                break;
        case 4: {// SCANTYPE
                   uInt pos=card.find("=");
                   if (pos!=String::npos) {
                     scanType=card.substr(pos+2,80-pos-3).before(trailing);
                   }
                   if (scanType=="PADDLE"||scanType=="POINT"||scanType=="XPOINT"
                       ||scanType=="EARLY") {
                     flagScanType_p=True;
                   }
                }
                break;
        case 5: {// COORDTYP
                  uInt pos=card.find("=");
                  if (pos!=String::npos) {
                    coordType=card.substr(pos+2,80-pos-3).before(trailing);
                  }
                }
                break;
        case 6: {// LINEMODE
                  uInt pos=card.find("=");
                  if (pos!=String::npos) {
                    lineMode(0)=(card[pos+2]=='T');
                    if (nIF>1) lineMode(1)=(card[pos+4]=='T');
                  }
                }
                break;
        case 7: {// CACALCNT
                  uInt pos=card.find("=");
                  if (pos!=String::npos) {
                    istringstream(card.substr(pos+1,7))>>cacalCnt;
                  }
                }
                break;
        case 8: {// POINTCOR
                  uInt pos=card.find("Az=");
                  if (pos!=String::npos && ant>=0) {
                    istringstream(card.substr(pos+3,6))>>pointCorr(0,ant);
                    newPointingCorr_p=True;
                  }
                  pos=card.find("El=");
                  if (pos!=String::npos && ant>=0) {
                    istringstream(card.substr(pos+3,6))>>pointCorr(1,ant);
                    newPointingCorr_p=True;
                  }
                }
                break;
        case 9: {// POINTINF
                  pointInfo = card.substr(9).before(trailing);
                }
                break;
        default:
                cerr << "Missing SCAN_INFO card type in switch statement"<<endl;
        }
        //cout <<" Match: cardname = "<<types[j]<<" : "<<card<<endl;
      }
    }
  }
  if (!foundAny) return;
  Vector<String> tmp;
  if (msc_p->observation().log().isDefined(obsId_p)) {
    tmp=msc_p->observation().log()(obsId_p);
  }
  if (tmp.nelements()==0) tmp.resize(1);
  Int index=tmp.nelements()-1;
  tmp(index)+=obsLog;
  msc_p->observation().log().put(obsId_p,tmp);
  if ((nAnt*nIF)==0) return;

  // find out spectral window index of IFs
  Vector<Int> spwId(nIF,-1);
  if (if_no>=0) spwId(if_no)=spWId_p;
  //cout <<" if_no="<<if_no<<", spwid="<<spWId_p<<", nIF="<<nIF<<endl;
  if (nIF>1) {
    for (Int ifNum=0; ifNum<nIF; ifNum++) {
      if (ifNum!=if_no) {
        if (selected(ifNum)) spwId(ifNum)=checkSpW(ifNum);
      }
    }
  }
  // reset to original spW
  if (if_no>0) checkSpW(if_no);
  
  Int row=msScanInfo_p.nrow();
  msScanInfo_p.addRow(nAnt*nIF);
  colScanInfoScanId.put(row,scanNo_p+1);
  colScanInfoCacal.put(row,cacalCnt);
  colScanInfoCorrConfig.put(row,config);
  colScanInfoScanType.put(row,scanType);
  colScanInfoCoordType.put(row,coordType);
  colScanInfoPointInfo.put(row,pointInfo);
  if (newPointingCorr_p) { 
    pointingCorr_p.reference(pointCorr);
  } else {
    pointingCorr_p.resize(0,0);
  }
     
  Vector<Int> f(2),c(2),m(2);
  Vector<Float> sr(2);
  for (Int i=0; i<nIF; i++) {
    colScanInfoSpWId.put(row,spwId(i));
    colScanInfoLineMode.put(row,lineMode(i));
    for (Int ant=0; ant<nAnt; ant++) {
      colScanInfoAntId.put(row,ant);
      f(0)=fine(0,i,ant); f(1)=fine(1,i,ant);
      c(0)=coarse(0,i,ant); c(1)=coarse(1,i,ant);
      m(0)=mmAtt(0,ant); m(1)=mmAtt(1,ant);
      colScanInfoFine.put(row,f);
      colScanInfoCoarse.put(row,c);
      colScanInfommAtt.put(row,m);
      sr(0)=subrPos(ant)/1000.0; sr(1)=subrTilt(ant)/1000.; // convert to meter
      colScanInfoSubreflector.put(row,sr);
      row++;
    }
  }
}

String ATCAFiller::atcaPosToStation(Vector<Double>& xyz) {
  String station("NONE");
  // determine station from xyz position
  // Use W106 as reference
  Double x106 = -4751615.0l;
  Double y106 = 2791719.246l;
  Double z106 = -3200483.747l;
  Double incr = 6000.0l/392;
  Bool north = (xyz(2)-z106)>1.0;
  Bool east = (xyz(0)-x106)<1.0;
  Int n = Int(floor(0.5l+
                    sqrt((xyz(0)-x106)*(xyz(0)-x106)+
                         (xyz(1)-y106)*(xyz(1)-y106)+
                         (xyz(2)-z106)*(xyz(2)-z106))/incr));
  Bool invalid = (n>392);
  if (!invalid) {
    if (north) {
      ostringstream ostr; ostr << "N"<<n;
      station = ostr.str();
    } else {
      if (east) n = 106 -n; else n += 106;
      ostringstream ostr; ostr << "W"<<n;
      station = ostr.str();  
    }
  }   
  return station;
}

Int ATCAFiller::checkSpW(Int ifNumber,Bool log) {
  // Check if current if_no already in SpW Table
  // Add it if not, set SpWId_p index for our SpW Table
  // NOTE we should use ddId instead of SpWid everywhere, for now
  // we create one SpWId per ddId so they always match, this may result
  // in duplicate spw rows if only the pol info changed..
  Regex trailing(" *$"); // trailing blanks
  if (if_.if_found) {
    spWId_p=-1;
    for (Int i=0; i<nSpW_p; i++) {
      Double freq = msc_p->spectralWindow().refFrequency()(i);
      Double bw = msc_p->spectralWindow().totalBandwidth()(i);
      Int nchan = msc_p->spectralWindow().numChan()(i);
      Int polId = msc_p->dataDescription().polarizationId()(i);
      Int npol = msc_p->polarization().numCorr()(polId);
      // compare freq and bw, cope with case where birdie option has reduced bw
      if (doubles_.if_freq[ifNumber]==freq &&
	  doubles_.if_bw[ifNumber]>=bw && doubles_.if_bw[ifNumber]<2*bw &&
          (if_.if_nfreq[ifNumber] == nchan || (nchan<33 &&
           if_.if_nfreq[ifNumber]==33)) && 
          if_.if_nstok[ifNumber]==npol) {
	spWId_p=i; 
	break;
      }
    }
    if (spWId_p<0) { // i.e. not found
      spWId_p=nSpW_p++;
      atms_p.spectralWindow().addRow();
      Int n=atms_p.spectralWindow().nrow()-1;
      Double refFreq=doubles_.if_freq[ifNumber];
      msc_p->spectralWindow().refFrequency().put(n,refFreq);
      // no doppler tracking

      Int nchan = if_.if_nfreq[ifNumber];
      Int npol =if_.if_nstok[ifNumber];

      if (log) os_p << LogIO::NORMAL<< 
	"IF "<< ifNumber+1 << 
	"     : Frequency = "<< refFreq/1.e6 << " MHz" <<
	", bandwidth = " << doubles_.if_bw[ifNumber]/1.e6 << "MHz" << 
	", #channels = "<< nchan << LogIO::POST;

      Double refChan=doubles_.if_ref[ifNumber]-1; // make zero based
      Double chanSpac = doubles_.if_bw[ifNumber]/max(1,nchan-1);
      Int inversion=if_.if_invert[ifNumber];
      msc_p->spectralWindow().netSideband().put(n,inversion);
      chanSpac*=inversion;
      Double chanBW = abs(chanSpac);
      if (nchan==33) chanBW=chanBW*1.6;  // roughly
      if (nchan==65) chanBW=chanBW*1.3;  // guess
          
      // do birdie check here - reduce number of channels we will store
      // for 33 channel data (drop half the channels + edge) and fix
      // spw description  
      if (birdie_p && nchan == 33) {
         Int bchan = birdChan(refFreq/1.e9, (Int)refChan, chanSpac/1.e9);
         Int edge = 3 + (bchan+1)%2;
         nchan = (nchan - 2*edge + 1)/2;
         chanSpac*=2;
         refChan = (refChan - edge)/2;
      }    
      Vector<Double> chanFreq(nchan), resolution(nchan);
      for (Int ichan=0; ichan<nchan; ichan++)
	chanFreq(ichan)=refFreq+(ichan-refChan)*chanSpac;
      msc_p->spectralWindow().chanFreq().put(n,chanFreq);
      resolution=chanBW;
      msc_p->spectralWindow().resolution().put(n,resolution);
      msc_p->spectralWindow().chanWidth().put(n, resolution);
      msc_p->spectralWindow().effectiveBW().put(n, resolution);
      msc_p->spectralWindow().totalBandwidth().put(n,
          (nchan<33 ? abs(nchan*chanSpac) : doubles_.if_bw[ifNumber]));
      msc_p->spectralWindow().numChan().put(n,nchan);

      Vector<Int> corrType(npol);
      Matrix<Int> corrProduct(2,npol); corrProduct=0;
      if (log) os_p << LogIO::NORMAL << "         : Polarizations ";
      for (Int i=0; i<npol; i++) {
	Stokes::StokesTypes stokesEnum;
	corrType(i) = stokesEnum = Stokes::type
	  (String(&names_.if_cstok[i*2+ifNumber*Max_IF],2).before(trailing));
	if (i>0) os_p << " , ";
	if (log) os_p << String(&names_.if_cstok[i*2+ifNumber*Max_IF],2).before(trailing)
	     << " - " << Int(stokesEnum);
	if (stokesEnum != Stokes::Undefined) {
	  corrProduct(0,i)=Stokes::receptor1(stokesEnum);
	  corrProduct(1,i)=Stokes::receptor2(stokesEnum);
	}
      }
      if (log) os_p << LogIO::POST;

      // try to find matching pol row
      Int nPolRow = atms_p.polarization().nrow();
      Int polRow = -1;
      for (Int i = 0; i< nPolRow; i++) {
        if (  msc_p->polarization().numCorr()(i)== Int(if_.if_nstok[ifNumber])) {
          if (allEQ(msc_p->polarization().corrType()(i),corrType)) {
            polRow=i;
            break;
          }
        }
      }
      // add new pol id if needed
      if (polRow==-1) {
        atms_p.polarization().addRow();
        polRow = nPolRow;
        msc_p->polarization().numCorr().put(polRow,Int(if_.if_nstok[ifNumber]));
        msc_p->polarization().corrType().put(polRow,corrType);
        msc_p->polarization().corrProduct().put(polRow,corrProduct);
        msc_p->polarization().flagRow().put(polRow, False);
      }         
      atms_p.dataDescription().addRow();
      msc_p->dataDescription().spectralWindowId().put(n, spWId_p);
      msc_p->dataDescription().polarizationId().put(n, polRow);
      msc_p->dataDescription().flagRow().put(n, False);

      msc_p->spectralWindow().ifConvChain().put(n,Int(if_.if_chain[ifNumber])-1);
      colSamplerBits.put(n,Int(if_.if_sampl[ifNumber]));

      // set up the TiledStorageManagers
      Record values1, values2, values3, values3c;
      values1.define("DATA_HYPERCUBE_ID",spWId_p);
      values2.define("SIGMA_HYPERCUBE_ID",spWId_p);
      values3.define("FLAG_HYPERCUBE_ID",spWId_p);
      values3c.define("FLAG_CATEGORY_HYPERCUBE_ID",spWId_p);

      Record values4; values4.define("MODEL_HYPERCUBE_ID",spWId_p);
      Record values5; values5.define("CORRECTED_HYPERCUBE_ID",spWId_p);
      Record values6; values6.define("IMAGING_WT_HYPERCUBE_ID",spWId_p);

      Int nChan=msc_p->spectralWindow().numChan()(spWId_p);
      Int nCorr=msc_p->polarization().numCorr()(polRow);
      Int nCat=3;

      // Choose an appropriate tileshape
      IPosition dataShape(2,nCorr,nChan);
      IPosition tileShape = MSTileLayout::tileShape(dataShape,obsType_p,"ATCA");
      dataAccessor_p.addHypercube(IPosition(3,nCorr,nChan,0),
				 tileShape,values1);
      sigmaAccessor_p.addHypercube(IPosition(2,nCorr,0),
				   IPosition(2,tileShape(0),tileShape(2)),
				   values2);
      flagAccessor_p.addHypercube(IPosition(3,nCorr,nChan,0),
				  tileShape,values3);
      flagCatAccessor_p.addHypercube(IPosition(4,nCorr,nChan,nCat,0),
				     IPosition(4,tileShape(0),tileShape(1),
                                               1,tileShape(2)),values3c);

      if (onLine_p) {
	modelDataAccessor_p.addHypercube(IPosition(3,nCorr,nChan,0),
				         tileShape,values4);
	corrDataAccessor_p.addHypercube(IPosition(3,nCorr,nChan,0),
				        tileShape,values5);
	imWtAccessor_p.addHypercube(IPosition(2,nChan,0),
				    IPosition(2,tileShape(0),tileShape(2)),
				    values6);
	
      }
    }
  }
  return spWId_p;
}


void ATCAFiller::checkObservation() {
  const Regex trailing(" *$"); // trailing blanks
  // Check if current observer already in OBSERVATION table
  String observer;
  obsId_p=-1;
  for (uInt i=0; i<atms_p.observation().nrow(); i++) {
    msc_p->observation().observer().get(i,observer);
    if (String(names_.rp_observer,16).before(trailing)==observer) {
      obsId_p=i;
      break;
    }
  }
  if (obsId_p<0) {
    // not found, so add it
    atms_p.observation().addRow();
    obsId_p=atms_p.observation().nrow()-1;
    msc_p->observation().observer().put(obsId_p,
				     String(names_.rp_observer,16).before(trailing));
    // decode project from rpfits file name..
    String project=rpfitsFiles_p(0).after(Regex(".*\\."));
    if (project.contains(";")) project=project.before(";");
    msc_p->observation().project().put(obsId_p,project);
  }
}

void ATCAFiller::checkField() {
  // Check if current source already in Field Table
  // Add it if not, set fieldId_p index for our Field Table
  // For now, we have 1 source per field, we may handle mosaicing differently
  // at some point.
  const Regex trailing(" *$"); // trailing blanks
  //0.1 arcsec tolerance for positional coincidence
  const Double PosTol=0.1*C::arcsec; 

  if (su_.su_found) {
    fieldId_p=-1;
    Bool seenSource = False;
    Int numPol;
    String name;
    String su_name=String(&names_.su_name[sourceno*16],16).before(trailing);
    for (Int i=0; i<nField_p; i++) {
      msc_p->field().name().get(i,name);
      msc_p->field().numPoly().get(i,numPol);

      if (su_name==name) {
	IPosition shape(2, 2, numPol+1);
	Matrix<Double> phaseDir(shape);
	msc_p->field().phaseDir().get(i,phaseDir);
	if (abs(phaseDir(0, 0)-doubles_.su_ra[sourceno])<PosTol) { 
	  if (abs(phaseDir(1, 0)-doubles_.su_dec[sourceno])<PosTol) {
	    fieldId_p=i; // found it!
            // now check if we've seen this field for this spectral window
            Vector<Int> sourceIdCol = msc_p->source().sourceId().getColumn();
            Vector<Int> spwIdCol = msc_p->source().spectralWindowId().getColumn();
            Vector<Int> spwids = spwIdCol(sourceIdCol==i).getCompressedArray();
            seenSource = (spwids.nelements()>0) && anyEQ(spwids,spWId_p);
            // Use indexed access to the SOURCE sub-table - TOO SLOW! MHW
           // MSSourceIndex sourceIndex (atms_p.source());
           // sourceIndex.sourceId() = i;
           // sourceIndex.spectralWindowId() = spWId_p;
           // Vector<uInt> rows = sourceIndex.getRowNumbers();
           // if (rows.nelements()>0) seenSource = True;
	    break;
	  }
	}
      }
    }
	
    if (fieldId_p<0 || !seenSource) { // i.e. not found, or not at this spwid
      String src = String(&names_.su_name[sourceno*16],16);

      nsources_p++;
      sources_p = src;

      Double epoch=mjd0_p+Double(proper_.pm_epoch);
      IPosition shape(2, 2, 2);
      Matrix<Double> dir(shape);
      // convert proper motions from s & " per year to rad/s
      const Double arcsecPerYear=C::arcsec/(365.25*C::day);
      dir(0, 0)=doubles_.su_ra[sourceno]; 
      dir(1, 0)=doubles_.su_dec[sourceno];
      dir(0, 1)=proper_.pm_ra*15.*arcsecPerYear; // (15"/s)
      dir(1, 1)=proper_.pm_dec*arcsecPerYear;
 
      if (fieldId_p<0) {
        os_p << LogIO::DEBUGGING << "Found field:" << src << LogIO::POST;
        fieldId_p=nField_p++;
        atms_p.field().addRow();
        Int nf=atms_p.field().nrow()-1;
        // for now we have 1 field/source
        msc_p->field().sourceId().put(nf,fieldId_p); 
        msc_p->field().name().put(nf,src.before(trailing));

        msc_p->field().phaseDir().put(nf,dir);
        msc_p->field().delayDir().put(nf,dir);
        msc_p->field().referenceDir().put(nf, dir);
        msc_p->field().numPoly().put(nf, 1);
        msc_p->field().time().put(nf,epoch);
        msc_p->field().code().put(nf,String(&names_.su_cal[sourceno*16],
				      16).before(trailing));
      }
      dir(0, 0)=doubles_.su_pra[sourceno]; 
      dir(1, 0)=doubles_.su_pdec[sourceno];
      Vector<Double> srcdir(2);
      srcdir(0)=doubles_.su_ra[sourceno]; 
      srcdir(1)=doubles_.su_dec[sourceno];
      atms_p.source().addRow();
      Int ns=atms_p.source().nrow()-1;
      msc_p->source().sourceId().put(ns,fieldId_p);
      msc_p->source().name().put(ns,src.before(trailing));
      msc_p->source().direction().put(ns,srcdir);
      Vector<Double> rate(2);
      rate(0)=proper_.pm_ra*15.*arcsecPerYear; // (15"/s)
      rate(1)=proper_.pm_dec*arcsecPerYear;
      msc_p->source().properMotion().put(ns,rate);
      msc_p->source().time().put(ns,epoch);
      msc_p->source().interval().put(ns,DBL_MAX);
      // assume source is at infinity, specify as zero
      //Vector<Double> pos(3); pos=0.;
      //msc_p->source().position().put(ns,pos);
      
      //suRow["VelRefFrame"].put(Int(spect_.ivelref));
      // need to specify reference frame for velocity as well
      // vel1 may be velocity at channel 1 instead of ref freq..
      
      msc_p->source().spectralWindowId().put(ns,spWId_p);
      Vector<Double> sysv(1),restFreq(1);
      Vector<String> transition(1);
      sysv = Double(doubles_.vel1);
      msc_p->source().sysvel().put(ns, sysv);
      msc_p->source().numLines().put(ns,1);
      restFreq(0) = Double(doubles_.rfreq);
      if (restFreq(0)<1.0) {
        // fill in an appropriate default
        Double freq = msc_p->spectralWindow().refFrequency()(spWId_p);
        Double bw = msc_p->spectralWindow().totalBandwidth()(spWId_p);
        if ( freq>1200.e6 && freq< 1450.e6 && bw <64.e6) {
          restFreq(0)= 1420.4e6;
          transition(0)="HI";
        } else {
          restFreq(0) = freq;
          transition(0) = "";
        }            
      }
      msc_p->source().transition().put(ns,transition);
      msc_p->source().restFrequency().put(ns,restFreq);
      
      // dummy fill 
      msc_p->source().calibrationGroup().put(ns,-1);
    }

    if (fieldId_p != prev_fieldId_p || newPointingCorr_p) {
      prev_fieldId_p = fieldId_p;
      Double epoch=mjd0_p+Double(proper_.pm_epoch);
      Int np=atms_p.pointing().nrow();
      IPosition shape(2, 2, 2);
      Matrix<Double> pointingDir(shape,0.0);
      pointingDir(0, 0)=doubles_.su_pra[sourceno]; 
      pointingDir(1, 0)=doubles_.su_pdec[sourceno];
      Matrix<Double> pointingOffset(shape,0.0);
      for (Int i=0; i<nAnt_p; i++) {
	atms_p.pointing().addRow();
	msc_p->pointing().antennaId().put(np+i, i+1);
        if (newPointingCorr_p) {
          pointingOffset(0, 0)=pointingCorr_p(0,i)*C::arcsec;
          pointingOffset(1, 0)=pointingCorr_p(0,i)*C::arcsec;
        }    
	if (i==0) { // ISM storage
	  msc_p->pointing().time().put(np,epoch);
	  msc_p->pointing().interval().put(np,DBL_MAX);
	  msc_p->pointing().numPoly().put(np, 1);
	  msc_p->pointing().direction().put(np,pointingDir);
          msc_p->pointing().pointingOffset().put(np,pointingOffset);
	} else {
          if (newPointingCorr_p) {
            msc_p->pointing().pointingOffset().put(np,pointingOffset);
          }
        }           
      }
    }
  }
}


void ATCAFiller::storeSysCal() 
{
  // RPFITS SysCal table layout:
  // sc_cal(q,if,ant)
  // q=0 : ant
  //   1 : if
  //   2 : XYPhase (deg)
  //   3 : tsysX (sqrt(tsys*10))
  //   4 : tsysY
  //  5-7: samp-stats X
  //  8-10:samp-stats Y
  //  11 : Parallactic Angle (deg)
  //  12 : Flag
  //  13 : XYAmp (Jy)
  //  15: Tracking error Max (arcsec)
  //  16: Tracking error RMS (arcsec)
  Int last_if_no=-2; // if_no can come out to be -1 if syscal rec is blank
  Bool skip=False;
  sourceno=sc_.sc_srcno-1; // 0-based source number for this syscal record
  Int scq=sc_.sc_q, scif=sc_.sc_if;
  for (Int i=0; i<scif; i++) {
    for (Int ant=0; ant<sc_.sc_ant; ant++) {
      if (Int(sc_.sc_cal[scq*(i+scif*ant)+0])==0) {
        // special syscal record with antenna==0
        // field 7-12 contain weather data
        if (sc_.sc_ut!=lastWeatherUT_p) {
          lastWeatherUT_p = sc_.sc_ut;
//          cout <<"Found weather data: is="<<i<<" ant="<<ant<<", time="<< sc_.sc_ut<<
//              ", temp="<<sc_.sc_cal[scq*(i+scif*ant)+1]<<
//              ", press="<<sc_.sc_cal[scq*(i+scif*ant)+2]<<
//              ", hum="<<sc_.sc_cal[scq*(i+scif*ant)+3]<<
//              ", windspeed="<<sc_.sc_cal[scq*(i+scif*ant)+4]<<
//              ", winddir="<<sc_.sc_cal[scq*(i+scif*ant)+5]<<
//              ", weatherflag="<<sc_.sc_cal[scq*(i+scif*ant)+6]<<
//              ", rain="<<sc_.sc_cal[scq*(i+scif*ant)+7]<<
//              ", seemon phase="<<sc_.sc_cal[scq*(i+scif*ant)+8]<<
//              ", seemon rms="<<sc_.sc_cal[scq*(i+scif*ant)+9]<<
//              ", seemon flag="<<sc_.sc_cal[scq*(i+scif*ant)+10]<< endl;
          
          Int nAnt = max(1,sc_.sc_ant-1);
          Int row=atms_p.weather().nrow();
          atms_p.weather().addRow(nAnt);
          Double time=mjd0_p+Double(sc_.sc_ut);
          for (Int iAnt=0; iAnt<nAnt; iAnt++,row++) {
            msc_p->weather().antennaId().put(row,iAnt);
            msc_p->weather().time().put(row,time);
            msc_p->weather().interval().put(row,Double(param_.intbase));
            msc_p->weather().temperature().put(row,  
                Double(sc_.sc_cal[scq*(i+scif*ant)+1]));
            msc_p->weather().pressure().put(row,    
                Double(sc_.sc_cal[scq*(i+scif*ant)+2])*100.0); // mBar to Pa
            msc_p->weather().relHumidity().put(row,  
                Double(sc_.sc_cal[scq*(i+scif*ant)+3]));
            msc_p->weather().windSpeed().put(row,   
                Double(sc_.sc_cal[scq*(i+scif*ant)+4])/3.6); // km/s to m/s
            msc_p->weather().windDirection().put(row,
                Double(sc_.sc_cal[scq*(i+scif*ant)+5])*C::pi/180.0); // deg to rad
            msc_p->weather().temperatureFlag().put(row,  Bool(sc_.sc_cal[scq*(i+scif*ant)+6]));
            msc_p->weather().pressureFlag().put(row,     Bool(sc_.sc_cal[scq*(i+scif*ant)+6]));
            msc_p->weather().relHumidityFlag().put(row,  Bool(sc_.sc_cal[scq*(i+scif*ant)+6]));
            msc_p->weather().windSpeedFlag().put(row,    Bool(sc_.sc_cal[scq*(i+scif*ant)+6]));
            msc_p->weather().windDirectionFlag().put(row,Bool(sc_.sc_cal[scq*(i+scif*ant)+6]));
            colWeatherRainGauge.put(row,  Float(sc_.sc_cal[scq*(i+scif*ant)+7]));
            colWeatherSeeMonPhase.put(row,  Float(sc_.sc_cal[scq*(i+scif*ant)+8]));
            colWeatherSeeMonRMS.put(row,  Float(sc_.sc_cal[scq*(i+scif*ant)+9])/1000);
            colWeatherSeeMonFlag.put(row,  Bool(sc_.sc_cal[scq*(i+scif*ant)+10]));
          }
        }
        continue;
      }
      if_no=Int(sc_.sc_cal[scq*(i+scif*ant)+1])-1; // make 0-based
      if (if_no!=last_if_no) { // check if we want this one
	last_if_no=if_no; 
	skip=Bool(if_no<0 || !selected(if_no));
	if (!skip) {
          checkSpW(if_no); // sets spWId_p corresponding to this if_no
          checkField(); // sets fieldId_p
        }
      }
      if (!skip) {
	atms_p.sysCal().addRow();
	Int n=atms_p.sysCal().nrow()-1;
	Double time=mjd0_p+Double(sc_.sc_ut);
	msc_p->sysCal().time().put(n,time);
	msc_p->sysCal().antennaId()
	  .put(n,Int(sc_.sc_cal[scq*(i+scif*ant)+0]-1)); // make 0-based
	msc_p->sysCal().feedId().put(n,0);
	msc_p->sysCal().interval().put(n,Double(param_.intbase));
	msc_p->sysCal().spectralWindowId().put(n,spWId_p);

	msc_p->sysCal().phaseDiff().put(n,sc_.sc_cal[scq*(i+scif*ant)+2]);

	Vector<Float> tSys(2);
	// convert from sqrt(tsys*10) to true tsys
	tSys(0)=square(sc_.sc_cal[scq*(i+scif*ant)+3])/10.;
	tSys(1)=square(sc_.sc_cal[scq*(i+scif*ant)+4])/10.;

	msc_p->sysCal().tsys().put(n,tSys);

	Vector<Float> ssneg(2),sszero(2),sspos(2);
	for (Int j=0; j<2; j++) {
	  ssneg(j)=sc_.sc_cal[scq*(i+scif*ant)+5+j*3];
	  sszero(j)=sc_.sc_cal[scq*(i+scif*ant)+6+j*3];
	  sspos(j)=sc_.sc_cal[scq*(i+scif*ant)+7+j*3];
	}
	colSamplerStatsNeg.put(n,ssneg);
	colSamplerStatsZero.put(n,sszero);
	colSamplerStatsPos.put(n,sspos);
	//cParAngle.put(n,sc_.sc_cal[scq*(i+scif*ant)+11]);
	msc_p->sysCal().phaseDiffFlag().
	  put(n,(sc_.sc_cal[scq*(i+scif*ant)+12]!=0));
	msc_p->sysCal().tsysFlag().
	  put(n,(sc_.sc_cal[scq*(i+scif*ant)+12]!=0));
	colXYAmplitude.put(n,sc_.sc_cal[scq*(i+scif*ant)+13]);
	msc_p->sysCal().tcalFlag().put(n,True);
	msc_p->sysCal().trxFlag().put(n,True);
        // tracking error max = sc_.sc_cal[scq*(i+scif*ant)+14]
        // tracking error rms = sc_.sc_cal[scq*(i+scif*ant)+15]
//        cout << "Tracking error ut="<<sc_.sc_ut<<", ant="<<
//            Int(sc_.sc_cal[scq*(i+scif*ant)+0])<< " max="<<
//            Double(sc_.sc_cal[scq*(i+scif*ant)+14])<<", rms="<<
//            Double(sc_.sc_cal[scq*(i+scif*ant)+15])<<endl;
        colTrackErrMax.put(n,Float(sc_.sc_cal[scq*(i+scif*ant)+14]));
        colTrackErrRMS.put(n,Float(sc_.sc_cal[scq*(i+scif*ant)+15]));
      }
    }
  }
}

void ATCAFiller::reweight()
{
  Int npol =if_.if_nstok[if_no];
  Int nfreq=33;
  Int n=2*nfreq-2;
  FFTServer<Float, Complex> server;

  Vector<Complex> cscr(33);
  Vector<Float>   rscr(64);

  static Float wts[64]={ 1.000000,    
   1.028847, 1.0526778, 1.0711329, 1.083963, 1.0909837, 1.0921189,    
   1.0873495, 1.0767593, 1.0605253, 1.0389025, 1.0122122,
   0.9808576, 0.9453095, 0.9060848, 0.8637353, 0.8188493,    
   0.7720414, 0.7239398, 0.6751758, 0.6263670, 0.5781130,    
   0.5310048, 0.4856412, 0.4426092, 0.4025391, 0.3661798,    
   0.3346139, 0.3096083, 0.2951138, 0.3024814, 0.6209788, 1.000000,    
   0.6209788, 0.3024814, 0.2951138, 0.3096083, 0.3346139,    
   0.3661798, 0.4025391, 0.4426092, 0.4856412, 0.5310048,    
   0.5781130, 0.6263670, 0.6751758, 0.7239398, 0.7720414,    
   0.8188493, 0.8637353, 0.9060848, 0.9453095, 0.9808576,    
   1.0122122, 1.0389025, 1.0605253, 1.0767593, 1.0873495, 1.0921189,    
   1.0909837, 1.083963, 1.0711329, 1.0526778, 1.028847 };

  for (Int p=0; p<npol; p++) {
    for (Int i=0; i<nfreq; i++)
      cscr(i) = Complex(vis[0+2*(p+i*npol)],vis[1+2*(p+i*npol)]);
    server.fft0(rscr, cscr);
    for (Int i=0; i<n; i++) rscr(i) = rscr(i)*wts[i];
    server.fft0(cscr, rscr);
    for (Int i=0; i<nfreq; i++) {
      vis[0+2*(p+i*npol)] = real(cscr(i));
      vis[1+2*(p+i*npol)] = imag(cscr(i));
    }
  }
}

Int ATCAFiller::birdChan(Double refFreq, Int refChan, Double chanSpac)
{
  Double flo = 0.128* myround(refFreq/0.128);
  Int chan = refChan + myround((flo - refFreq)/chanSpac);
  if(chan <= 0) {
    //    os_p << LogIO::NORMAL << "CHAN " << chan << "  ";
    chan = chan + myround(0.128/fabs(chanSpac));
  }
  //os_p << LogIO::NORMAL << "birdie channel = " << chan << " refFreq="<<refFreq << " flo="<<flo <<"\n";
  return chan;
}

void ATCAFiller::storeData()
{
  atms_p.addRow();
  
  const RecordFieldId rfid1("DATA_HYPERCUBE_ID");
  const RecordFieldId rfid2("SIGMA_HYPERCUBE_ID");
  const RecordFieldId rfid3("FLAG_HYPERCUBE_ID");
  const RecordFieldId rfid3c("FLAG_CATEGORY_HYPERCUBE_ID");
  Record values1, values2, values3, values3c;
  values1.define(rfid1,spWId_p);
  values2.define(rfid2,spWId_p);
  values3.define(rfid3,spWId_p);
  values3c.define(rfid3c,spWId_p);

  dataAccessor_p.extendHypercube(1,values1);
  sigmaAccessor_p.extendHypercube(1,values2);
  flagAccessor_p.extendHypercube(1,values3);
  flagCatAccessor_p.extendHypercube(1,values3c);

  Record values4, values5, values6; 
  if (onLine_p) {
    values4.define("MODEL_HYPERCUBE_ID",spWId_p);
    values5.define("CORRECTED_HYPERCUBE_ID",spWId_p);
    values6.define("IMAGING_WT_HYPERCUBE_ID",spWId_p);
  
    modelDataAccessor_p.extendHypercube(1,values4);
    corrDataAccessor_p.extendHypercube(1,values5);
    imWtAccessor_p.extendHypercube(1,values6);
  }

  Int n=atms_p.nrow()-1;
  if (n==0) gotSysCalId_p=False;
    
  Int npol =if_.if_nstok[if_no];
  Int nfreq=if_.if_nfreq[if_no];
  Regex trailing(" *$"); // trailing blanks
  String instrument = String(names_.instrument,16).before(trailing);
  Bool atca = (instrument=="ATCA");
  Bool atlba = (instrument=="ATLBA");
  
  // fill in the easy items
  // make antenna numbers 0-based
  Int ant1=Int(baseline)/256-1, ant2=Int(baseline)%256-1;
  msc_p->antenna1().put(n,ant1);  
  msc_p->antenna2().put(n,ant2);
  Bool flagData=flg;
  if (flagData) { flagCount_p(ONLINE)++;}
  if (autoFlag_p && flagScanType_p) { flagData=True; flagCount_p(SCANTYPE)++;}
  Double exposure=Double(param_.intbase);
  // averaging = number of integration periods averaged by correlator: 1,2 or 3
  Int averaging = 1;
  if (param_.intime>0) averaging = Int(exposure/param_.intime)+1; 
  Double interval = averaging*Double(param_.intime);
  // check for old data with intbase set to zero
  Double blank=51.e-3; // standard 51 ms blank time at end of integration
  if (exposure<0.001) exposure = interval-blank;
  if (interval==0.0) interval = exposure;
  
  // Is binning mode active?
  Int nBin = Int(floor(param_.intime/exposure+0.01));
  if (nBin<4) nBin=1; // short exposure due to long hold period.. 
  msc_p->dataDescId().put(n, spWId_p);
  if (ut!=lastUT_p) { // the ISM columns that don't change within integration
    msc_p->arrayId().put(n,0);
    msc_p->exposure().put(n,exposure);
    msc_p->feed1().put(n,0);
    msc_p->feed2().put(n,0);
    msc_p->fieldId().put(n,fieldId_p);
    msc_p->interval().put(n,interval);
    msc_p->observationId().put(n,obsId_p);
    msc_p->processorId().put(n,-1);
    msc_p->scanNumber().put(n,scanNo_p);
    Double mjd=mjd0_p+ut;
    // try to figure out what the midpoint of the integration interval was
    if (nBin>1 || !atca) {
      msc_p->time().put(n,mjd);
    } else {
      msc_p->time().put(n,floor((mjd+exposure/2+blank*(averaging+1)/2
			      -interval/2)*1000+0.5)/1000);
    }    
    // time centroid is the centroid of the exposure window
    // it is the time used for the uvw & phase calculation 
    // [note that cacor corrects uvw for change in centroid from caobs value
    // due to blank, hold and averaging, but not binning]
    msc_p->timeCentroid().put(n,mjd);
  } 
  Int pulsarBin = max(0,bin-1);// make zero-based (but catch unset value) 
  msc_p->pulsarBin().put(n,pulsarBin); 
  if (hires_p && nBin>1) {
    // in hires mode we adjust timeCentroid to match the bin centers, but
    // uvw's still refer to center of interval (now given by time column)
    // Time column will still be in time order, but TimeCentroid is not.
    Double midTime = msc_p->time()(n);
    msc_p->timeCentroid().put(n,midTime+(pulsarBin-nBin/2+0.5)*exposure/averaging);
  }
  Vector<Double> uvw(3); uvw(0)=u; uvw(1)=v; uvw(2)=w;
  msc_p->uvw().put(n,uvw);

  // use exposure time as weight
  Vector<Float> Weight(npol); Weight=exposure;
  msc_p->weight().put(n,Weight); 
  //#  Vector<Float> weightSpectrum(nfreq); weightSpectrum=exposure;
  //#  msc_p->weightSpectrum().put(n,weightSpectrum);
  
  // Find the indices into the sysCal table for this row
  if (!gotSysCalId_p || ut!=lastUT_p || spWId_p!=lastSpWId_p) {
    lastUT_p=ut;
    lastSpWId_p=spWId_p;
    // we need to get the new syscal info
    // search backwards from last syscal row
    Bool done=False;
    Int nsc=atms_p.sysCal().nrow();
    //# os_p << LogIO::NORMAL << " Current number of syscal rows="<<nsc<<LogIO::POST;
    sysCalId_p.resize(nAnt_p); sysCalId_p=-1;
    // search backwards, as it should be a recent entry
    for (Int i=nsc-1; (i>=0 && !done); i--) {
      if (nearAbs(msc_p->sysCal().time()(i),mjd0_p+ut,0.5) && 
	  msc_p->sysCal().spectralWindowId()(i)==spWId_p) {
	Int ant=msc_p->sysCal().antennaId()(i);
	if (ant>=0 && ant<nAnt_p) { //valid antenna
	  sysCalId_p(ant)=i;
	  done=(!(anyEQ(sysCalId_p,-1)));
	}
      }
    }
    if (!done && atca) {
      errCount_p++;
      if (errCount_p<3) os_p << LogIO::WARN <<"Warning: some syscal info is missing"<< LogIO::POST;
    }
  }
  // set a sysCalId in the main table to point to
  // the sysCal subtable row - missing points get a -1
  colSysCalIdAnt1.put(n,sysCalId_p(ant1));
  colSysCalIdAnt2.put(n,sysCalId_p(ant2));
  
  // Check for bad sampler stats now that we've found the syscal data
  if (!flagData && autoFlag_p && (!atlba && samplerFlag(n))) {
    flagData=True; flagCount_p(SYSCAL)++;
  }
  flagCount_p(COUNT)++;
  if (flagData) flagCount_p(FLAG)++;
  msc_p->flagRow().put(n,flagData);
    

  // flags and data
  const Int nCat = 3; // three initial categories
  // define the categories
  Vector<String> cat(nCat);
  cat(0)="FLAG_CMD";
  cat(1)="ORIGINAL"; 
  cat(2)="USER"; 
  msc_p->flagCategory().rwKeywordSet().define("CATEGORY",cat);

  // Gibbs reweighting
  if (nfreq == 33) {
    if (reweight_p) reweight();
  }

  // do birdie check here - reduce number of channels we will store
  // for 33 channel data (drop half the channels + edge) 
  Double refFreq=doubles_.if_freq[if_no];
  Double refChan=doubles_.if_ref[if_no]-1; // make zero based
  Double chanSpac = doubles_.if_bw[if_no]/max(1,nfreq-1);
  Int inversion=if_.if_invert[if_no];
  chanSpac*=inversion;
  Int bchan = -1;
  Int edge = 0;
  if (birdie_p) {
    bchan = birdChan(refFreq/1.e9, (Int)refChan, chanSpac/1.e9);
    if (nfreq == 33) {  // ATCA continuum mode - flag edge + every other channel
     edge = 3 + (bchan+1)%2;
     nfreq = (nfreq - 2*edge + 1)/2;
     chanSpac*=2;
     refChan = (refChan - edge)/2;
     bchan = (bchan -edge)/2;
    } 
  }
  Bool band12mm = (refFreq>13.e9 && refFreq<28.e9);
  //Bool band3mm  = (refFreq>75.e9);
      
  Matrix<Complex> VIS(npol,nfreq);
  Cube<Bool> flagCat(npol,nfreq,nCat,False);  
  Matrix<Bool> flags= flagCat.xyPlane(1); // references flagCat's storage
  
  
  if (birdie_p) {
    if (bchan >= 0 && bchan < nfreq) {
      for (Int i=0; i<npol; i++) {
        flags(i, bchan) = True;       
      }
    }
  }
  
  
  // Some corrections as specified by Bob Sault(2000/09/07):
  //Conjugate all data if the IF_INVERT switch is negative
  //Negate the XY and YX correlations (both real and imag parts) for all
  // except 12mm observations.
  //The xyphase measurement should also be multiplied by the IF_INVERT switch
  //sign. The xyphase measurement is the phase of a correlation. So to
  //correct the data with the xyphase measurement, you will want to multiply
  //by gains whose phase has the opposite sign to the measurements.
  //Note any Gibbs reweighting needs to be done before any xyphase correction
  //is done.

  if (inversion>0 && edge==0) {// no inversion and not discarding any data
      // get the data with takeStorage in one go:
      VIS.takeStorage(IPosition(2,npol,nfreq),(Complex*)&vis[0]);
  } else {
    // correct for inversion - conjugate data; skip birdie channels
    for (Int j=0; j<nfreq; j++) {
      Int k = (edge>0 ? (2*j+edge) : j);
      for (Int i=0; i<npol; i++) 
        VIS(i,j)=Complex(vis[0+2*(i+k*npol)],inversion*vis[1+2*(i+k*npol)]);
    }
  }
    
  // correct for xy phase - multiply y correlation with opposite of xyphase
  Complex gain1 = (sysCalId_p(ant1)!=-1 && 
		   !msc_p->sysCal().phaseDiffFlag()(sysCalId_p(ant1)) ?
		   exp(Complex(0,1)*msc_p->sysCal().phaseDiff()(sysCalId_p(ant1))*inversion):
		   Complex(1,0));
  // negate xyphase for second antenna since the correlation product uses conjugate for ant2
  Complex gain2 = (sysCalId_p(ant2)!=-1 && 
		   !msc_p->sysCal().phaseDiffFlag()(sysCalId_p(ant1)) ?
		   exp(-Complex(0,1)*msc_p->sysCal().phaseDiff()(sysCalId_p(ant2))*inversion):
		   Complex(1,0));
  Int polId = msc_p->dataDescription().polarizationId()(spWId_p);
  Vector<Int> corrType = msc_p->polarization().corrType()(polId);
  if (noxycorr_p) { gain1=gain2=1; }
  // "-" because XY and YX corr need to be negated, except for 12mm
  if (!band12mm) { gain1=-gain1; gain2=-gain2;}
  for (Int i=0; i<npol; i++) {
    switch (corrType(i)) {
    case Stokes::XX : 
      break;
    case Stokes::XY : 
      {
	Vector<Complex> tmp(VIS.row(i));
	tmp*=gain2; 
      }
    break;
    case Stokes::YX :
      {
        Vector<Complex> tmp(VIS.row(i));
	tmp*=gain1;
      }
    break;
    case Stokes::YY :
      {
        Vector<Complex> tmp(VIS.row(i));
	tmp*=(gain1*gain2);
      }
    break;
    default:
      break;
    }
  }

  msc_p->data().put(n,VIS);

  msc_p->flag().put(n,flags);
  msc_p->flagCategory().put(n,flagCat);
  
  // now calculate the sigma for this row
  //
  Vector<Double> chnbw;  
  msc_p->spectralWindow().resolution().get(spWId_p,chnbw);
  Vector<Float> tsys1,tsys2;
  //#  os_p << LogIO::NORMAL << "Looking up syscal info at rows: "<<sysCalId_p(ant1)<<" and "<<
  //#  sysCalId_p(ant2)<< LogIO::POST;

  if (sysCalId_p(ant1)!=-1 && !msc_p->sysCal().tsysFlag()(sysCalId_p(ant1))) 
    msc_p->sysCal().tsys().get(sysCalId_p(ant1),tsys1);
  else { tsys1.resize(nAnt_p); tsys1=50.;}
  if (sysCalId_p(ant2)!=-1 && !msc_p->sysCal().tsysFlag()(sysCalId_p(ant2)))
    msc_p->sysCal().tsys().get(sysCalId_p(ant2),tsys2);
  else { tsys2.resize(nAnt_p); tsys2=50.;}
  Vector<Float> sigma(npol); sigma=0.;
  Matrix<Int> corrProduct(2,npol);
  msc_p->polarization().corrProduct().get(polId,corrProduct);

  // sigma=sqrt(Tx1*Tx2)/sqrt(chnbw*intTime)*JyPerK;
  Float JyPerK=10.; // guess for ATCA dishes at 3-20cm
  Float factor=sqrt(chnbw(0)*exposure)/JyPerK;
  for (Int pol=0; pol<npol; pol++) {
    Float tsysAv=tsys1(corrProduct(0,pol))*tsys2(corrProduct(1,pol));
    if (tsysAv>=0 && factor>0 ) sigma(pol)=sqrt(tsysAv)/factor;
  }
  msc_p->sigma().put(n,sigma);

  // determine shadowing & flag data with shadowed antennas
  if (shadow_p>0) shadow(n);
  
}

void ATCAFiller::fillFeedTable() {
  // At present there is always only a single feed per antenna (at any
  // given spectralwindow).
  Int nAnt=atms_p.antenna().nrow();
  //  Int nSpW=atms_p.spectralWindow().nrow();
  // Only X and Y receptors available
  Vector<String> rec_type(2); rec_type(0)="X"; rec_type(1)="Y";
  Matrix<Complex> polResponse(2,2); 
  polResponse=0.; polResponse(0,0)=polResponse(1,1)=1.;
  Matrix<Double> offset(2,2); offset=0.;
  Vector<Double> position(3); position=0.;
  // X feed is at 45 degrees, Y at 135 degrees
  Vector<Double> receptorAngle(2); 
  receptorAngle(0)=45*C::degree;
  receptorAngle(1)=135*C::degree;

  // fill the feed table
  Int row=-1;
  // in principle we should have a separate entry for each SpectralWindow
  // but at present all this is 'dummy' filled
  //  for (Int spw=0; spw<nSpW; spw++) {
  for (Int ant=0; ant<nAnt; ant++) {
    atms_p.feed().addRow(); row++;
    msc_p->feed().antennaId().put(row,ant);
    msc_p->feed().beamId().put(row,-1);
    msc_p->feed().feedId().put(row,0);
    msc_p->feed().interval().put(row,DBL_MAX);
    msc_p->feed().phasedFeedId().put(row,-1);
    msc_p->feed().spectralWindowId().put(row,-1);  //spw);
    msc_p->feed().time().put(row,0.);
    msc_p->feed().numReceptors().put(row,2);
    msc_p->feed().beamOffset().put(row,offset);
    msc_p->feed().polarizationType().put(row,rec_type);
    msc_p->feed().polResponse().put(row,polResponse);
    msc_p->feed().position().put(row,position);
    msc_p->feed().receptorAngle().put(row,receptorAngle);
  }
  //  }
}
 
void ATCAFiller::fillObservationTable() 
{
  Vector<Double> tim = msc_p->time().getColumn();
  Vector<Int> obsid = msc_p->observationId().getColumn();
  Int startInd;
  Int endInd;

  Int nObs=atms_p.observation().nrow();

  Vector<Double> vt(2);
  for (Int obs=0; obs<nObs; obs++) {
    // fill time range
    startInd = 0;
    endInd = atms_p.nrow()-1;
    for (uInt i=0; i<atms_p.nrow(); i++) {
      if (obsid(i) == obs) { startInd = i; break; }
    }
    for (uInt i=startInd; i<atms_p.nrow(); i++) {
      if (obsid(i) > obs) { endInd = i-1; break; }
    }
    vt(0) = tim(startInd);
    vt(1) = tim(endInd);
    msc_p->observation().timeRange().put(obs, vt);
    msc_p->observation().releaseDate().put(obs,vt(1)+18*30.5*86400);
    // telescope name
    msc_p->observation().telescopeName().put(obs, "ATCA");
  }
}

void ATCAFiller::flush()
{
  atms_p.flush();
  atms_p.antenna().flush();
  atms_p.dataDescription().flush();
  atms_p.feed().flush();
  atms_p.field().flush();
  atms_p.observation().flush();
  atms_p.history().flush();
  atms_p.pointing().flush();
  atms_p.polarization().flush();
  atms_p.source().flush();
  atms_p.spectralWindow().flush();
  atms_p.sysCal().flush();
  atms_p.weather().flush();
}

void ATCAFiller::unlock()
{
  atms_p.unlock();
  atms_p.antenna().unlock();
  atms_p.dataDescription().unlock();
  atms_p.feed().unlock();
  atms_p.field().unlock();
  atms_p.observation().unlock();
  atms_p.history().unlock();
  atms_p.pointing().unlock();
  atms_p.polarization().unlock();
  atms_p.source().unlock();
  atms_p.spectralWindow().unlock();
  atms_p.sysCal().unlock();
  atms_p.weather().unlock();
}

Bool ATCAFiller::selected(Int ifNum)
{
  Bool select=True;
  // check if we want this ifchain
  if (ifChain_p>0 && ifChain_p!=if_.if_chain[ifNum]) 
    select=False;
  else {
    // check if we want this frequency
    if (lowFreq_p>0 && (doubles_.if_freq[ifNum]-lowFreq_p)<0) 
      select=False;
    else {
      if (highFreq_p>0 && (highFreq_p-doubles_.if_freq[ifNum])<0) 
	select=False;
      else {
        // check if we want this bandwidth on the first IF
        if (bandWidth1_p>0 && 
        (bandWidth1_p != myround(doubles_.if_bw[ifNum]/1.e6))) 
          select=False;
        else {
          // check if we want this number of channels on the first IF
          if (numChan1_p>0 && numChan1_p != if_.if_nfreq[ifNum])
            select=False;
        }
      }
    }
  }
  return select;
}

void ATCAFiller::shadow(Int row, Bool last)
{
  // 1. collect together all rows with the same time
  // 2. determine which antennas are shadowed
  // 3. flag all baselines involving a shadowed antenna 

  if (last || msc_p->time()(row)!=prevTime_p) {
    // flag previous rows if needed
    if (nRowCache_p>0) {
      Vector<Bool> flag(nAnt_p); flag=False;
      Vector<Double> uvw;
      for (Int i=0; i< nRowCache_p; i++) {
	Int k=rowCache_p[i];
	// check for shadowing: projected baseline < shadow diameter
	uvw = msc_p->uvw()(k);
        Bool shadowed = (uvw(0)*uvw(0)+uvw(1)*uvw(1)<shadow_p*shadow_p);
	if (shadowed) {
	  // w term decides which antenna is being shadowed
	  if (uvw(2)>0) {
	    flag(msc_p->antenna2()(k))=True;
	    //	    cout << " Shadowed: antenna2="<<msc_p->antenna2()(k)<<" for row "
	    //		 <<k<<" time="<< msc_p->timeMeas()(k) <<endl;
	  } else {
	    flag(msc_p->antenna1()(k))=True;
	    //	    cout << " Shadowed: antenna1="<<msc_p->antenna1()(k)<<" for row "
	    //		 <<k<<" time="<<msc_p->timeMeas()(k) <<endl;
	  }
	}
      }
      // now flag rows with shadowed antennas
      for (Int i=0; i< nRowCache_p; i++) {
	Int k=rowCache_p[i];
	Int ant1 = msc_p->antenna1()(k);
	Int ant2 = msc_p->antenna2()(k);
	if (flag(ant1) || flag(ant2)) {
          flagCount_p(SHADOW)++;
          msc_p->flagRow().put(k,True);
        }
      }
    }
    // reinitialize
    if (!last) {
      nRowCache_p=0;
      prevTime_p=msc_p->time()(row);
    }
  }
  if (!last) {
    if (Int(rowCache_p.nelements())<=nRowCache_p) {
      rowCache_p.resize(2*(nRowCache_p+1),True);
    }
    rowCache_p[nRowCache_p++]=row;
  }
}

Bool ATCAFiller::samplerFlag(Int row, Double posNegTolerance, 
			     Double zeroTolerance) {
  // check the sampler stats for the current row, return False if data needs to
  // be flagged

  const Float posNegRef = 17.3;
  const Float zeroRef =50.0;
  Vector<Int> rows(2);
  rows(0) = colSysCalIdAnt1(row);
  rows(1) = colSysCalIdAnt2(row);
  Bool flag = rows(0)<0 || rows(1)<0;
  for (Int i=0; (!flag && i<2); i++) {
    Vector<Float> neg = colSamplerStatsNeg(rows(i));
    Vector<Float> pos = colSamplerStatsPos(rows(i));
    Vector<Float> zero = colSamplerStatsZero(rows(i));
    flag |=(abs(neg(0)-posNegRef)>posNegTolerance) ||
           (abs(neg(1)-posNegRef)>posNegTolerance) ||
           (abs(pos(0)-posNegRef)>posNegTolerance) ||
           (abs(pos(1)-posNegRef)>posNegTolerance) ||
           (abs(zero(0)-zeroRef)>zeroTolerance) ||
           (abs(zero(1)-zeroRef)>zeroTolerance);
  }
  return flag;
}
