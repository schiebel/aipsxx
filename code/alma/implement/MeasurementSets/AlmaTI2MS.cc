//# Almati2ms.cc: Implementation of AlmaTI2MS.h
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
//# $Id: AlmaTI2MS.cc,v 19.5 2004/08/25 05:48:50 gvandiep Exp $
//----------------------------------------------------------------------------

#include <alma/MeasurementSets/AlmaTI2MS.h>

#include <casa/Utilities/Regex.h>
#include <casa/Utilities/Assert.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayUtil.h>
#include <casa/Arrays/MaskedArray.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Logging/LogIO.h>
#include <casa/OS/File.h>
#include <casa/OS/Directory.h>
#include <casa/Exceptions/Error.h>

#include <tables/Tables/ArrayColumn.h>
#include <tables/Tables/ScalarColumn.h>
#include <tables/Tables/ArrColDesc.h>
#include <tables/Tables/ScaColDesc.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/IncrementalStMan.h>
#include <tables/Tables/StandardStMan.h>
#include <tables/Tables/TiledShapeStMan.h>
#include <tables/Tables/TiledCellStMan.h>
#include <tables/Tables/TiledColumnStMan.h>
#include <tables/Tables/CompressComplex.h>
#include <tables/Tables/CompressFloat.h>

#include <casa/IO/TapeIO.h>
#include <fits/FITS/BinTable.h>

#include <ms/MeasurementSets/MSColumns.h>
#include <ms/MeasurementSets/MSAntennaIndex.h>
#include <ms/MeasurementSets/MSFeedIndex.h>
#include <ms/MeasurementSets/MSFieldIndex.h>
#include <ms/MeasurementSets/MSSourceIndex.h>
#include <ms/MeasurementSets/MSSpWindowIndex.h>
#include <ms/MeasurementSets/MSPolIndex.h>
#include <ms/MeasurementSets/MSDataDescIndex.h>
#include <ms/MeasurementSets/MSObsIndex.h>

//----------------------------------------------------------------------------

AlmaTI2MS::AlmaTI2MS(const Path& tapeDevice, const String& msOut, 
		     const Bool& overWrite) :
  itsDataSource(""),
  itsDeviceType(FITS::Tape9),
  itsMSOut(""),
  itsMS(0),
  itsMSExists(False),
  itsOverWrite(False),
  itsMSCompress(True),
  itsCombineBaseBand(True),
  itsSelectedFiles(0),
  itsAllFilesSelected(True),
  itsObsModeSelection(),
  itsChanZeroSelection(NONE),
  itsDataParKeywords(NULL),
  itsSkipToNextDataPar(False),
  itsTelescope(""), 
  itsOrigin(""), 
  itsCreator(""),
  itsComment(""),
  itsCurrFieldId(-1),
  itsCurrSourceId(-1),
  itsCurrSourceRow(-1),
  itsCurrObsId(-1),
  itsCalibrTsys(),
  itsCorrDataKeyw(),
  itsCorrDataPending(False),
  itsAntennaIds(0),
  itsAntennaIdMap(0),
  itsFeedIdMap(0), spwIdPrinted(1, False),
  datapar_p(NULL)
{
// Construct from a tape device and output MS file name
// Input:
//    tapeDevice           const String&      Tape device name
//    msOut                const String&      Output MS name
//    overWrite            const Bool&        True if existing MS is to 
//                                            be overwritten
// Output to private data:
//    itsDataSource        String             Tape name or input file name
//    itsDeviceType        FITS::DeviceType   FITS device type (disk or tape)
//    itsMSOut             String             Output MS name
//    itsMS                MeasurementSet*    Pointer to output MS
//    itsMSExists          Bool               True if output MS already exists
//    itsOverWrite         Bool               True if existing MS is to 
//                                            be overwritten
//    itsMSCompress        Bool               True if output MS is to be 
//                                            written in compressed format
//    itsCombineBaseBand   Bool               True if basebands are to be
//                                            concatenated (as one spw id.)
//    itsSelectedFiles     Vector<Int>        Input file numbers selected
//    itsAllFilesSelected  Bool               True if all files selected
//    itsObsModeSelection  Vector<String>     Selected obs. modes
//    itsChanZeroSelection chanZeroSelection  Channel zero selection
//    itsDataParKeywords   DataParKeywords*   Ptr to current DATAPAR keywords
//    itsSkipToNextDataPar Bool               Flag to skip to next DATAPAR 
//    itsTelescope         String             Telescope name
//    itsOrigin            String             FITS file origin
//    itsCreator           String             FITS file creator
//    itsComment           String             FITS file comment
//    itsCurrFieldId       Int                Current FIELD_ID
//    itsCurrSourceId      Int                Current SOURCE_ID
//    itsCurrSourceRow     Int                Current SOURCE sub-table row no.
//    itsCurrObsId         Int                Current OBSERVATION_ID
//    itsCalibrTsys        Cube<Float>        Tsys values from CALIBR table
//    itsCorrDataKeyw      PtrBlock<CorrDataKeywords*> Index to keywords of the
//                                                     last set of CORRDATA 
//                                                     tables read
//    itsCorrDataPending   Bool               True if CORRDATA tables have
//                                            been read, and await processing
//    itsAntennaIds        Vector<Int>        Antenna id.'s per FITS row in
//                                            the CALIBR sub-table
//    itsAntennaIdMap      SimOrdMap<Int,Int> Map of current ALMATI antenna 
//                                            id.'s to their MS antenna id.'s
//    itsFeedIdMap         SimOrdMap<Int,Int> Map of current ALMATI antenna 
//                                            id.'s to their MS feed id.'s
//
  init(tapeDevice.absoluteName(), FITS::Tape9, msOut, overWrite);
//
};

//----------------------------------------------------------------------------

AlmaTI2MS::AlmaTI2MS(const String& inFile, const String& msOut, 
		     const Bool& overWrite) :
  itsDataSource(""),
  itsDeviceType(FITS::Disk),
  itsMSOut(""),
  itsMS(0),
  itsMSExists(False),
  itsOverWrite(False),
  itsMSCompress(True),
  itsCombineBaseBand(True),
  itsSelectedFiles(0),
  itsAllFilesSelected(True),
  itsObsModeSelection(),
  itsChanZeroSelection(NONE),
  itsDataParKeywords(NULL),
  itsSkipToNextDataPar(False),
  itsTelescope(""), 
  itsOrigin(""), 
  itsCreator(""),
  itsComment(""),
  itsCurrFieldId(-1),
  itsCurrSourceId(-1),
  itsCurrSourceRow(-1),
  itsCurrObsId(-1),
  itsCalibrTsys(),
  itsCorrDataKeyw(),
  itsCorrDataPending(False),
  itsAntennaIds(0),
  itsAntennaIdMap(0),
  itsFeedIdMap(0), spwIdPrinted(1, False),
  datapar_p(NULL)
{
// Construct from an input FITS-IDI file name and an output MS file name
// Input:
//    inFile               const String&      Input FITS-IDI file name
//    msOut                const String&      Output MS name
//    overWrite            const Bool&        True if existing MS is to 
//                                            be overwritten
// Output to private data:
//    itsDataSource        String             Tape name or input file name
//    itsDeviceType        FITS::DeviceType   FITS device type (disk or tape)
//    itsMSOut             String             Output MS name
//    itsMS                MeasurementSet*    Pointer to output MS
//    itsMSExists          Bool               True if output MS already exists
//    itsOverWrite         Bool               True if existing MS is to 
//                                            be overwritten
//    itsMSCompress        Bool               True if output MS is to be 
//                                            written in compressed format
//    itsCombineBaseBand   Bool               True if basebands are to be
//                                            concatenated (as one spw id.)
//    itsSelectedFiles     Vector<Int>        Input file numbers selected
//    itsAllFilesSelected  Bool               True if all files selected
//    itsObsModeSelection  Vector<String>     Selected obs. modes
//    itsChanZeroSelection chanZeroSelection  Channel zero selection
//    itsDataParKeywords   DataParKeywords*   Ptr to current DATAPAR keywords
//    itsSkipToNextDataPar Bool               Flag to skip to next DATAPAR 
//    itsTelescope         String             Telescope name
//    itsOrigin            String             FITS file origin
//    itsCreator           String             FITS file creator
//    itsComment           String             FITS file comment
//    itsCurrFieldId       Int                Current FIELD_ID
//    itsCurrSourceId      Int                Current SOURCE_ID
//    itsCurrSourceRow     Int                Current SOURCE sub-table row no.
//    itsCurrObsId         Int                Current OBSERVATION_ID
//    itsCalibrTsys        Cube<Float>        Tsys values from CALIBR table
//    itsCorrDataKeyw      PtrBlock<CorrDataKeywords*> Index to keywords of the
//                                                     last set of CORRDATA 
//                                                     tables read
//    itsCorrDataPending   Bool               True if CORRDATA tables have
//                                            been read, and await processing
//    itsAntennaIds        Vector<Int>        Antenna id.'s per FITS row in
//                                            the CALIBR sub-table
//    itsAntennaIdMap      SimOrdMap<Int,Int> Map of current ALMATI antenna 
//                                            id.'s to their MS antenna id.'s
//    itsFeedIdMap         SimOrdMap<Int,Int> Map of current ALMATI antenna 
//                                            id.'s to their MS feed id.'s
//
  init(inFile, FITS::Disk, msOut, overWrite);
//
};

//----------------------------------------------------------------------------

AlmaTI2MS::~AlmaTI2MS()
{
// Default desctructor
// Output to private data:
//    itsMS                MeasurementSet*    Pointer to output MS
//    itsDataParKeywords   DataParKeywords*   Pointer to DATAPAR keywords
//
  if (itsMS) {
    itsMS->flush();
    delete(itsMS);
  };
  /*
  if (itsDataParKeywords) {
    delete(itsDataParKeywords);
  };
  */
  
  // Remove all remaining scratch files in the current working directory
  Vector<String> scratchType(3);
  scratchType(0) = "datapar-scratch*";
  scratchType(1) = "calibr-scratch*";
  scratchType(2) = "corrdata-scratch*";

  Directory dir;
  // Loop over the scratch file types
  for (Int type=0; type < 3; type++) {
    Vector<String> fileList = dir.find(Regex::fromPattern(scratchType(type)));
    // Delete all scratch files of this type
    for (uInt k=0; k < fileList.nelements(); k++) {
      if (Table::canDeleteTable(fileList(k))) Table::deleteTable(fileList(k));
    };
  };
  

  itsAntennaIds.resize();
  itsSelectedFiles.resize();


};

//----------------------------------------------------------------------------

void AlmaTI2MS::setOptions(Bool compress, Bool combineBaseBand)
{
// Set general options (MS compression and baseband concatentation)
// Input:
//    compress             Bool               True if output MS to be
//                                            written in compressed format
//    combineBaseBand      Bool               True if basebands are to be
//                                            concatenated (as one spw id.)
// Output to private data:
//    itsMSCompress        Bool               MS compression flag
//    itsCombineBaseBand   Bool               Concatenate baseband flag
//
  itsMSCompress = compress;
  itsCombineBaseBand = combineBaseBand;
};

//----------------------------------------------------------------------------

void AlmaTI2MS::selectFiles(const Vector<Int>& files)
{
// Select input tape files by number (1-relative)
// Input:
//    files                const Vector<Int>  List of selected file numbers
// Output to private data:
//    itsSelectedFiles     Vector<Int>        Input file numbers selected
//    itsAllFilesSelected  Bool               True if all files selected
//
  itsSelectedFiles.resize(files.nelements());
  itsSelectedFiles = files;
  if (itsSelectedFiles.nelements() > 0) {
    itsAllFilesSelected = False;
  };
};

//----------------------------------------------------------------------------

void AlmaTI2MS::select(const Vector<String>& obsMode, const String& chanZero)
{
// General data selection
// Input:
//    obsMode       const Vector<String>     Obs. modes selected (as specified
//                                           in the DATAPAR table)
//    chanZero      const String&            Channel zero selection ("NONE", 
//                                           "TIME_SAMPLED", or "TIME_AVG")
// Output to private data:
//    itsChanZeroSelection  chanZeroSelect   Channel zero selection: (NONE, 
//                                           TIME_SAMPLED, TIME_AVG)
//
  // Observing modes
  itsObsModeSelection.resize(0);
  for (uInt i = 0; i < obsMode.nelements(); i++) {
    // Ignore null or empty strings
    if (!(obsMode(i).empty() || (obsMode(i).length()==obsMode(i).freq(' ')))) {
      uInt n = itsObsModeSelection.nelements();
      itsObsModeSelection.resize(n+1, True);
      itsObsModeSelection(n) = obsMode(i);
      itsObsModeSelection(n).upcase();
    };
  };

  // Channel-zero
  String matchStr = chanZero;
  matchStr.upcase();
  if (matchStr.contains("NONE")) {
    itsChanZeroSelection = NONE;
  } else if (matchStr.contains("TIME") && matchStr.contains("SAMPLED")) {
    itsChanZeroSelection = TIME_SAMPLED;
  } else if (matchStr.contains("TIME") && matchStr.contains("AVG")) {
    itsChanZeroSelection = TIME_AVG;
  } else {
    itsChanZeroSelection = NONE;
  };
};

//----------------------------------------------------------------------------

Bool AlmaTI2MS::fill()
{
// Convert the FITS-IDI data to MS format
//
  LogIO os(LogOrigin("AlmaTI2MS", "fill()", WHERE));
  
  // Delete the MS if it already exits and overwrite selected
  if (itsMSExists && itsOverWrite) {
    Table::deleteTable(itsMSOut);
  };

  // Create a new MS or attach to the existing MS
  if (!itsMSExists || itsOverWrite) {
    createOutputMS();
  } else {
    itsMS = new MeasurementSet(itsMSOut, Table::Update);
  };

  //
  // Tape input: loop over all selected input files
  //
  Bool atEnd = False;
  if (itsDeviceType == FITS::Tape9) {
    Int fileIndex = 0;
    Int currentFile = 1;
    Int fileno = currentFile;

    while (!atEnd) {
      // Skip to next file selected
      if (itsAllFilesSelected) {
	fileno = currentFile;
      } else {
	atEnd = (static_cast<uInt>(fileIndex) 
		 >= itsSelectedFiles.nelements()-1);
	if (!atEnd) fileno = itsSelectedFiles(fileIndex);
      };

      if (!atEnd) {
	// Advance tape if necessary
	Int nskip = fileno - currentFile;
	if (nskip > 0) {
	  TapeIO tapeDev(itsDataSource);
	  tapeDev.skip(nskip);
	  currentFile = currentFile + nskip;
	};

	// Read and process the selected input file
	readFITSFile(atEnd);

	// Increment file counter
	currentFile = currentFile + 1;
      };
    }; 
      
    //
    // Disk input:
    //
  } else if (itsDeviceType == FITS::Disk) {
    readFITSFile(atEnd);
  };
  return True;
};

//----------------------------------------------------------------------------

MeasurementSet AlmaTI2MS::emptyMS(const Path& tableName, const Bool compress,
				  const Bool overwrite)
{
  AlwaysAssert(tableName.isValid(), AipsError);
  AlwaysAssert(File(tableName.dirName()).isWritable(), AipsError);

  // Add all the required columns
  TableDesc msDesc = MeasurementSet::requiredTableDesc();

  // Set up hypercolumns for all columns which would benefit from tiling;
  // These include DATA, WEIGHT, WEIGHT_SPECTURM, SIGMA, UVW, 
  // FLAG, FLAG_CATEGORY, ALMA_PHAS_CORR, ALMA_NO_PHAS_CORR and
  // ALMA_PHAS_CORR_FLAG_ROW
  const Vector<String> coordCols(0);
  const Vector<String> idCols(0);

  // First add the DATA column (which is an optional column);
  // then define the DATA hypercolumn (optionally compressed)
  MeasurementSet::addColumnToDesc(msDesc, MeasurementSet::DATA, 2);
  String colData = MS::columnName(MS::DATA);
  if (compress) {
    msDesc.addColumn(ArrayColumnDesc<Int>(colData+"_COMPRESSED",
					  "DATA compressed", 2));
    msDesc.defineHypercolumn("TiledDataComp", 3, 
			     stringToVector(colData+"_COMPRESSED"),
			     coordCols, idCols);
    msDesc.addColumn(ScalarColumnDesc<Float>(colData+"_SCALE"));
    msDesc.addColumn(ScalarColumnDesc<Float>(colData+"_OFFSET"));
  } else {			       
    msDesc.defineHypercolumn("TiledData", 3, stringToVector(colData),
			     coordCols, idCols);
  }

  // First add the WEIGHT_SPECTRUM column (which is an optional
  // column), then define the WEIGHT_SPECTRUM hypercolumn
  // (optionally compressed)
  MeasurementSet::addColumnToDesc(msDesc, MeasurementSet::WEIGHT_SPECTRUM, 2);
  String colWeightSpectrum = MS::columnName(MS::WEIGHT_SPECTRUM);
  if (compress) {
    msDesc.addColumn(ArrayColumnDesc<Short>(colWeightSpectrum+"_COMPRESSED",
					    "WEIGHT_SPECTRUM compressed", 2));
    msDesc.defineHypercolumn("TiledWeightSpectrumComp", 3, 
			     stringToVector(colWeightSpectrum+"_COMPRESSED"),
			     coordCols, idCols);
    msDesc.addColumn(ScalarColumnDesc<Float>(colWeightSpectrum+"_SCALE"));
    msDesc.addColumn(ScalarColumnDesc<Float>(colWeightSpectrum+"_OFFSET"));
  } else {			       
    msDesc.defineHypercolumn("TiledWeightSpectrum", 3, 
			     stringToVector(colWeightSpectrum),
			     coordCols, idCols);
  }

  // WEIGHT hypercolumn
  msDesc.defineHypercolumn("TiledWeight", 2, 
			   stringToVector(MS::columnName(MS::WEIGHT)));

  // SIGMA hypercolumn
  msDesc.defineHypercolumn("TiledSigma", 2, 
			   stringToVector(MS::columnName(MS::SIGMA)));

  // UVW hypercolumn
  msDesc.defineHypercolumn("TiledUVW", 2, 
			   stringToVector(MS::columnName(MS::UVW)));

  // FLAG hypercolumn
  msDesc.defineHypercolumn("TiledFlag", 3,
			   stringToVector(MS::columnName(MS::FLAG)));

  // FLAG_CATEGORY hypercolumn
  msDesc.defineHypercolumn("TiledFlagCategory", 4, 
			   stringToVector(MS::columnName(MS::FLAG_CATEGORY)));


  // Add non-standard ALMA columns for real-time phase-corrected
  // or uncorrected data (using on-site radiometic corrections in
  // the case of IRAM Plateau du Bure)
  //
  // ALMA_PHAS_CORR hypercolumn
  String colPhasCorr = "ALMA_PHAS_CORR";
  msDesc.addColumn(ArrayColumnDesc<Complex>(colPhasCorr, 
					    "Phase-corrected data", 2));
  if (compress) {
    msDesc.addColumn(ArrayColumnDesc<Int>(colPhasCorr+"_COMPRESSED",
					  "ALMA_PHAS_CORR compressed", 2));
    msDesc.defineHypercolumn("TiledPhasCorrComp", 3, 
			     stringToVector(colPhasCorr+"_COMPRESSED"),
			     coordCols, idCols);
    msDesc.addColumn(ScalarColumnDesc<Float>(colPhasCorr+"_SCALE"));
    msDesc.addColumn(ScalarColumnDesc<Float>(colPhasCorr+"_OFFSET"));
  } else {			       
    msDesc.defineHypercolumn("TiledPhasCorr", 3, 
			     stringToVector(colPhasCorr), coordCols, idCols);
  };

  // ALMA_NO_PHAS_CORR hypercolumn
  String colNoPhasCorr = "ALMA_NO_PHAS_CORR";
  msDesc.addColumn(ArrayColumnDesc<Complex>(colNoPhasCorr, 
					    "Phase-uncorrected data", 2));
  if (compress) {
    msDesc.addColumn(ArrayColumnDesc<Int>(colNoPhasCorr+"_COMPRESSED",
					  "ALMA_NO_PHAS_CORR compressed", 2));
    msDesc.defineHypercolumn("TiledNoPhasCorrComp", 3, 
			     stringToVector(colNoPhasCorr+"_COMPRESSED"),
			     coordCols, idCols);
    msDesc.addColumn(ScalarColumnDesc<Float>(colNoPhasCorr+"_SCALE"));
    msDesc.addColumn(ScalarColumnDesc<Float>(colNoPhasCorr+"_OFFSET"));
  } else {			       
    msDesc.defineHypercolumn("TiledNoPhasCorr", 3, 
			     stringToVector(colNoPhasCorr), coordCols, idCols);
  };

  // ALMA_PHAS_CORR_FLAG_ROW
  String colPhasCorrFlagRow = "ALMA_PHAS_CORR_FLAG_ROW";
  msDesc.addColumn(ScalarColumnDesc<Bool>(colPhasCorrFlagRow, 
					  "Phase-corrected data present ?"));

  // Set up the MeasurementSet
  Table::TableOption option = Table::NewNoReplace;
  if (overwrite) option = Table::New;
  SetupNewTable newMS(tableName.originalName(), msDesc, option);

  // Bind storage managers to each column; use variable-shaped
  // tiling for the hypercolumns.
  // 
  // Choose the tile size per column to be ~4096k overall
  const Int nTileCorr = 1;
  const Int nTileChan = 1024;
  const Int tileSizeKBytes = 4096;
  Int nTileRow;

  // DATA hypercolumn (optionally compressed)
  nTileRow = (tileSizeKBytes * 1024 / (2 * 4 * nTileCorr * nTileChan));
  IPosition dataTileShape(3, nTileCorr, nTileChan, nTileRow);

  if (compress) {
    // Place DATA scale and offset under StandardStMan control
    StandardStMan dataScaleStMan("DataScaleOffsetStMan");
    newMS.bindColumn(colData+"_SCALE", dataScaleStMan);
    newMS.bindColumn(colData+"_OFFSET", dataScaleStMan);

    // Tile the scaled DATA
    TiledShapeStMan dataCompStMan("TiledDataComp", dataTileShape);
    newMS.bindColumn(colData+"_COMPRESSED", dataCompStMan);
    
    // Bind the DATA column to a compression engine
    CompressComplex compDataEngine(colData, colData+"_COMPRESSED",
				   colData+"_SCALE", colData+"_OFFSET", True);
    newMS.bindColumn(colData, compDataEngine);

  } else {
    // Tile the DATA column in uncompressed form
    TiledShapeStMan dataStMan("TiledData", dataTileShape);
    newMS.bindColumn(colData, dataStMan);
  };

  // WEIGHT_SPECTRUM hypercolumn (optionally compressed)
  nTileRow = (tileSizeKBytes * 1024 / (2 * 4 * nTileCorr * nTileChan));
  IPosition weightSpectrumTileShape(3, nTileCorr, nTileChan, nTileRow);
  colWeightSpectrum = MS::columnName(MS::WEIGHT_SPECTRUM);

  if (compress) {
    // Place WEIGHT_SPECTRUM scale and offset under StandardStMan control
    StandardStMan weightSpectrumScaleStMan("WeightScaleOffsetStMan");
    newMS.bindColumn(colWeightSpectrum+"_SCALE", weightSpectrumScaleStMan);
    newMS.bindColumn(colWeightSpectrum+"_OFFSET", weightSpectrumScaleStMan);

    // Tile the scaled DATA
    TiledShapeStMan weightSpectrumCompStMan("TiledWeightSpectrumComp", 
					    weightSpectrumTileShape);
    
    // Bind the WEIGHT_SPECTRUM column to a compression engine
    CompressFloat compDataEngine(colWeightSpectrum, 
				 colWeightSpectrum+"_COMPRESSED",
				 colWeightSpectrum+"_SCALE", 
				 colWeightSpectrum+"_OFFSET", True);
    newMS.bindColumn(colWeightSpectrum, compDataEngine);

  } else {
    // Tile the WEIGHT_SPECTRUM column in uncompressed form
    TiledShapeStMan weightSpectrumStMan("TiledWeightSpectrum", 
					weightSpectrumTileShape);
    newMS.bindColumn(colWeightSpectrum, weightSpectrumStMan);
  };

  // WEIGHT and SIGMA hypercolumns
  nTileRow = (tileSizeKBytes * 1024 / (4 * nTileCorr));
  IPosition weightTileShape(2, nTileCorr, nTileRow);
  TiledShapeStMan weightStMan("TiledWeight", weightTileShape);
  newMS.bindColumn(MS::columnName(MS::WEIGHT), weightStMan);
  TiledShapeStMan sigmaStMan("TiledSigma", weightTileShape);
  newMS.bindColumn(MS::columnName(MS::SIGMA), sigmaStMan);

  // UVW hypercolumn
  nTileRow = (tileSizeKBytes * 1024 / (8 * 3));
  IPosition uvwTileShape(2, 3, nTileRow);
  TiledColumnStMan uvwStMan("TiledUVW", uvwTileShape);
  newMS.bindColumn(MS::columnName(MS::UVW), uvwStMan);

  // FLAG hypercolumn
  nTileRow = (tileSizeKBytes * 1024 / (nTileCorr * nTileChan));
  IPosition flagTileShape(3, nTileCorr, nTileChan, nTileRow);
  TiledShapeStMan flagStMan("TiledFlag", flagTileShape);
  newMS.bindColumn(MS::columnName(MS::FLAG), flagStMan);

  // FLAG_CATEGORY hypercolumn
  const uInt nCat = 6; // Number of Flag categories
  nTileRow = (tileSizeKBytes * 1024 / (nTileCorr * nTileChan * nCat));
  IPosition flagCategoryTileShape(4, nTileCorr, nTileChan, nCat, nTileRow);
  TiledShapeStMan flagCategoryStMan("TiledFlagCategory", 
				    flagCategoryTileShape);
  newMS.bindColumn(MS::columnName(MS::FLAG_CATEGORY), flagCategoryStMan);

  // ALMA_PHAS_CORR hypercolumn (optionally compressed)
  nTileRow = (tileSizeKBytes * 1024 / (2 * 4 * nTileCorr * nTileChan));
  IPosition phasCorrTileShape(3, nTileCorr, nTileChan, nTileRow);

  if (compress) {
    // Place ALMA_PHAS_CORR scale and offset under StandardStMan control
    StandardStMan phasCorrScaleStMan("PhasCorrScaleOffsetStMan");
    newMS.bindColumn(colPhasCorr+"_SCALE", phasCorrScaleStMan);
    newMS.bindColumn(colPhasCorr+"_OFFSET", phasCorrScaleStMan);

    // Tile the scaled ALMA_PHAS_CORR data
    TiledShapeStMan phasCorrCompStMan("TiledPhasCorrComp", phasCorrTileShape);
    newMS.bindColumn(colPhasCorr+"_COMPRESSED", phasCorrCompStMan);
    
    // Bind the ALMA_PHAS_CORR column to a compression engine
    CompressComplex compPhasCorrEngine(colPhasCorr, colPhasCorr+"_COMPRESSED",
				       colPhasCorr+"_SCALE", 
				       colPhasCorr+"_OFFSET", True);
    newMS.bindColumn(colPhasCorr, compPhasCorrEngine);

  } else {
    // Tile the ALMA_PHAS_CORR column in uncompressed form
    TiledShapeStMan phasCorrStMan("TiledPhasCorr", phasCorrTileShape);
    newMS.bindColumn(colPhasCorr, phasCorrStMan);
  };

  // ALMA_NO_PHAS_CORR hypercolumn (optionally compressed)
  nTileRow = (tileSizeKBytes * 1024 / (2 * 4 * nTileCorr * nTileChan));
  IPosition noPhasCorrTileShape(3, nTileCorr, nTileChan, nTileRow);

  if (compress) {
    // Place ALMA_NO_PHAS_CORR scale and offset under StandardStMan control
    StandardStMan noPhasCorrScaleStMan("NoPhasCorrScaleOffsetStMan");
    newMS.bindColumn(colNoPhasCorr+"_SCALE", noPhasCorrScaleStMan);
    newMS.bindColumn(colNoPhasCorr+"_OFFSET", noPhasCorrScaleStMan);

    // Tile the scaled ALMA_NO_PHAS_CORR data
    TiledShapeStMan noPhasCorrCompStMan("TiledNoPhasCorrComp", 
					noPhasCorrTileShape);
    newMS.bindColumn(colNoPhasCorr+"_COMPRESSED", noPhasCorrCompStMan);
    
    // Bind the ALMA_NO_PHAS_CORR column to a compression engine
    CompressComplex compPhasCorrEngine(colNoPhasCorr, 
				       colNoPhasCorr+"_COMPRESSED",
				       colNoPhasCorr+"_SCALE", 
				       colNoPhasCorr+"_OFFSET", True);
    newMS.bindColumn(colNoPhasCorr, compPhasCorrEngine);

  } else {
    // Tile the ALMA_NO_PHAS_CORR column in uncompressed form
    TiledShapeStMan noPhasCorrStMan("TiledNoPhasCorr", noPhasCorrTileShape);
    newMS.bindColumn(colNoPhasCorr, noPhasCorrStMan);
  };

  // Use the incremental storage manager for columns where the data 
  // is likely to be the same for more than four rows at a time.
  {
    IncrementalStMan incrMan("Incremental data manager");
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::ANTENNA1), incrMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::ARRAY_ID), incrMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::DATA_DESC_ID), incrMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::EXPOSURE), incrMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::FEED1), incrMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::FEED2), incrMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::FIELD_ID), incrMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::FLAG_ROW), incrMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::INTERVAL), incrMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::OBSERVATION_ID), incrMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::PROCESSOR_ID), incrMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::SCAN_NUMBER), incrMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::STATE_ID), incrMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::TIME), incrMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::TIME_CENTROID), incrMan);
    newMS.bindColumn(colPhasCorrFlagRow, incrMan);
  }

  // Finally create the MeasurementSet.
  MeasurementSet ms(newMS);
  
  { // Set the TableInfo
    TableInfo& info(ms.tableInfo());
    info.setType(TableInfo::type(TableInfo::MEASUREMENTSET));
    info.setSubType(String("ALMA-TI"));
    info.readmeAddLine
      ("This is a MeasurementSet Table holding measurements from the ALMA");
    info.readmeAddLine("test interferometer");
  }

  // Create the required subtables.
  ms.createDefaultSubtables(option);

  // Add the optional sub-tables
  //
  // SOURCE (include optional line transition columns)
  TableDesc sourceTD = MSSource::requiredTableDesc();
  MSSource::addColumnToDesc(sourceTD, MSSource::TRANSITION);
  MSSource::addColumnToDesc(sourceTD, MSSource::REST_FREQUENCY);
  MSSource::addColumnToDesc(sourceTD, MSSource::SYSVEL);
  SetupNewTable sourceSetup(ms.sourceTableName(), sourceTD, option);
  ms.rwKeywordSet().defineTable(MS::keywordName(MS::SOURCE),
				Table(sourceSetup, 0));

  // Update the sub-table references
  ms.initRefs();

  // Adjust the Measure references to ones used by the VLA.
  {
    MSColumns msc(ms);
    msc.setEpochRef(MEpoch::IAT);
    msc.setDirectionRef(MDirection::J2000);
    msc.uvwMeas().setDescRefCode(Muvw::J2000);
    msc.antenna().setPositionRef(MPosition::ITRF);
    msc.antenna().setOffsetRef(MPosition::ITRF);
    { // Put the right values into the CATEGORY keyword
      Vector<String> categories(nCat);
      categories(0) = "ONLINE_1";
      categories(1) = "ONLINE_2";
      categories(2) = "ONLINE_4";
      categories(3) = "ONLINE_8";
      categories(4) = "SHADOW";
      categories(5) = "FLAG_CMD";
      msc.setFlagCategories(categories);
    }
  }
  return ms;
}

//----------------------------------------------------------------------------

void AlmaTI2MS::fitsErrorHandler(const char* errMessg, 
				 FITSError::ErrorLevel level) 
{
// FITS error handler which ignores those FITS compliance issues
// in the ALMA-TI format which are of no signficance for ALMA-TI
// data files in practice.
// Input:
//    errMessg    const char*             Error message posted by FITS classes
//    level       FITSError::ErrorLevel   Error severity level
//
  String strMessg(errMessg);

  // Primary Group HDU is missing PCOUNT, and NAXIS=2 (though null dimensions)
  Bool ignore = (strMessg.contains("Missing required PCOUNT keyword") ||
		 strMessg.contains("Error computing size of data"));
  if (!ignore) {
    // Else call the default FITS error handler
    FITSError::defaultHandler(errMessg, level);
  };
}

//----------------------------------------------------------------------------

void AlmaTI2MS::init(const String& dataSource, 
		     const FITS::FitsDevice& deviceType, const String& msOut,
		     const Bool& overWrite) 
{
// Initialization (called by all constructors)
// Input:
//    dataSource    const String&            Input file name or tape device
//    deviceType    const FITS::FitsDevice   FITS device type (tape or disk)
//    msOut         const String&            Output MS name
//    overWrite     const Bool&              True if existing MS is to 
//                                           be overwritten
// Output to private data:
//    itsDataSource        String             Tape name or input file name
//    itsDeviceType        FITS::DeviceType   FITS device type (disk or tape)
//    itsMSOut             String             Output MS name
//    itsMS                MeasurementSet*    Pointer to output MS
//    itsMSExists          Bool               True if output MS already exists
//    itsOverWrite         Bool               True if existing MS is to 
//                                            be overwritten
//    itsSelectedFiles     Vector<Int>        Input file numbers selected
//    itsAllFilesSelected  Bool               True if all files selected
//
  LogIO os(LogOrigin("AlmaTI2MS", "init()", WHERE));
  
  // Check for valid FITS-IDI data source
  Path sourcePath(dataSource);
  if (!sourcePath.isValid() || !File(sourcePath).exists() || 
      !File(sourcePath).isReadable()) {
    os << LogIO::SEVERE << "FITS-IDI data source is not readable"
       << LogIO::EXCEPTION;
  };

  itsDataSource = sourcePath.absoluteName();
  itsDeviceType = deviceType;

  // Check for valid output MS specification
  Path msPath(msOut);
  itsMSExists = File(msPath).exists();

  if (itsMSExists && !File(msPath).isWritable()) {
    os << LogIO::SEVERE << "Output MS is not writable" << LogIO::EXCEPTION;
  };

  if (!itsMSExists && !File(msPath).canCreate()) {
    os << LogIO::SEVERE << "Output MS cannot be created" << LogIO::EXCEPTION;
  };
  itsMSOut = msOut;
  itsOverWrite = overWrite;

  // Set remaining default parameters
  itsAllFilesSelected = True;
};

//----------------------------------------------------------------------------

void AlmaTI2MS::readFITSFile(Bool& atEnd)
{
// Read and process the current FITS-IDI input file (on tape or disk)
// Output:
//    atEnd                Bool               True if at EOF
//
  LogIO os(LogOrigin("AlmaTI2MS", "readFITSFile()", WHERE));
  atEnd = False;

  // Define an ALMA-TI FITS error handler
  void (*errorHandler) (const char*, FITSError::ErrorLevel);
  errorHandler = &fitsErrorHandler;

  // Construct a FitsInput object
  FitsInput infits(itsDataSource.c_str(), itsDeviceType, 10, errorHandler);
  if (infits.err() != FitsIO::OK) {
    os << LogIO::SEVERE << "Error reading FITS input" << LogIO::EXCEPTION;
  };

  // Regular expression for trailing blanks
  Regex trailing(" *$");

  // Vector of sub-table names
  Vector<String> subTableName;
  Int subTableNr = -1;
  Table maintab;
  
  // Loop over all HDU in the FITS-IDI file
  while (!infits.eof()) {

    // Skip reported FITS errors (see FITS error handler)
    if (infits.err() !=FitsIO::OK) {
      infits.read_sp();

    // Case FITS HDU type of:
    //
    // Special record:
    } else if (infits.rectype() == FITS::SpecialRecord) {
      os << LogIO::WARN << "Skipping FITS special record" << LogIO::POST;
      infits.read_sp();

    // Primary header
    } else if (infits.hdutype() == FITS::PrimaryGroupHDU) {
      os << LogIO::NORMAL << "Processing primary HDU" << LogIO::POST;
      readPrimaryHeader(infits);

    // Binary table HDU
    } else if (infits.hdutype() == FITS::BinaryTableHDU) {

      // Process the FITS-IDI input from the position of this binary table
      BinaryTable bintab(infits);
      String hduName = bintab.extname();
      hduName = hduName.before(trailing);

      //      os << LogIO::NORMAL << "Processing extent of type: " << hduName
      //	 << LogIO::POST;

      // Case ALMA-TI binary table name of:
      //
      // DATAPAR-ALMATI
      if (hduName == "DATAPAR-ALMATI") {

	readDataParTable(bintab);

	// MONITOR-ALMATI
      } else if (hduName == "MONITOR-ALMATI") {
	bintab.skip();
 
	// CALIBR-ALMATI
      } else if (hduName == "CALIBR-ALMATI") {
	if (itsSkipToNextDataPar) {
	  bintab.skip();
	} else {
	  readCalibrTable(bintab);
	};

	// CORRDATA-ALMATI
      } else if (hduName == "CORRDATA-ALMATI") {
	if (itsSkipToNextDataPar) {
	  bintab.skip();
	} else {
	  readCorrDataTable(bintab);
	};

	// AUTODATA-ALMATI
      } else if (hduName == "AUTODATA-ALMATI") {

	bintab.skip();

	// HOLODATA-ALMATI
      } else if (hduName == "HOLODATA-ALMATI") {
	bintab.skip();

	// UNRECOGNIZED BINARY TABLE
      } else {
	bintab.skip();
      };


      //      String tableName = itsMSOut;
      //      if (hduName != "") {
      //	if (hduName != "UV_DATA") {
      //	  tableName = tableName + "_tmp/" + hduName;
      //	  subTableNr++;
      //	  subTableName.resize(subTableNr+1, True);
      //	  subTableName(subTableNr) = hduName;
      //	};

      // Unrecognized HDU
    } else {
      // Skip this record
      infits.read_sp();
    };

    // Report any FITS input errors
    //    if (infits.err() != FitsIO::OK) {
    //      os << LogIO::SEVERE << "Error reading FITS input"  
    //	 << " - infits.err() = " << infits.err() << LogIO::EXCEPTION;
    //    };
  }; // end while
};
  
//----------------------------------------------------------------------------

void AlmaTI2MS::createOutputMS()
{
// Create a new, empty output MS
//
  LogIO os(LogOrigin("AlmaTI2MS", "createOutputMS()", WHERE));

  Path tableName(itsMSOut);
  itsMS = new MeasurementSet(emptyMS(tableName, itsMSCompress, itsOverWrite));
  return;
};

//----------------------------------------------------------------------------

void AlmaTI2MS::readPrimaryHeader(FitsInput& infits)
{
// Read and process the primary header
// Input:
//    infits               FitsInput&         FITS input
//
  LogIO os(LogOrigin("AlmaTI2MS", "readPrimaryHeader()", WHERE));
  
  HeaderDataUnit* hdu;
  if (infits.datatype() == FITS::SHORT) {
    hdu = new PrimaryGroup<Short>(infits);
  } else if (infits.datatype() == FITS::LONG) {
    hdu = new PrimaryGroup<FitsLong>(infits);
  } else if (infits.datatype() == FITS::FLOAT) {
    hdu = new PrimaryGroup<Float>(infits);
  } else {
    throw(AipsError("FITS primary group HDU has unrecognized data type"));
  }; 
   
  // Extract the FITS keywords
  ConstFitsKeywordList& kwl = hdu->kwlist();

  // Translate the input FITS keyword list
  const FitsKeyword* kw;
  kwl.first();
  while ((kw = kwl.next())) {
    String kwname = kw->name();

    // Case keyword name of:
    //
    // TELESCOP
    if (kwname == "TELESCOP") {
      itsTelescope = kw->asString();

      // ORIGIN
    } else if (kwname == "ORIGIN") {
      itsOrigin = kw->asString();

      // CREATOR
    } else if (kwname == "CREATOR") {
      itsCreator = kw->asString();

      // COMMENT
    } else if (kwname == "CREATOR") {
      itsComment = kw->asString();
    };
  };

  if (hdu) delete(hdu); 
};

//----------------------------------------------------------------------------

void AlmaTI2MS::readDataParTable(BinaryTable& bintab)
{
// Read and process the DATAPAR-ALMATI binary table
// Input:
//    bintab             BinaryTable&         FITS binary table at
//                                            current FitsInput position
// Input from private data:
//    itsCorrDataPending Bool                 True if CORRDATA tables have
//                                            been read and await processing
//
  LogIO os(LogOrigin("AlmaTI2MS", "readDataParTable()", WHERE));

  // Process any pending CORRDATA tables already read
  if (itsCorrDataPending) {
    processCorrData();
  };

  // Reset the keyword index for the next set of CORRDATA tables
  if (itsCorrDataKeyw.nelements() > 0) {
    itsCorrDataKeyw.resize(0, True, False);
  };

  // Process the DATAPAR-ALMATI FITS keywords
  if (itsDataParKeywords) delete(itsDataParKeywords);
  itsDataParKeywords = new DataParKeywords(bintab.kwlist());

  // Skip if obsvering mode not selected
  Bool filter = (itsObsModeSelection.nelements() > 0);
  for (uInt i = 0; i < itsObsModeSelection.nelements(); i++) {
    if (itsDataParKeywords->obsMode().contains(itsObsModeSelection(i))) {
      filter = False;
    };
  };

  if (filter) {
    itsSkipToNextDataPar = True;
  } else {
    itsSkipToNextDataPar = False;
    // Match or add a SOURCE_ID 
    itsCurrSourceId = matchOrAddSourceId(itsDataParKeywords->sourceName(),
					 itsDataParKeywords->calCode(),
					 itsDataParKeywords->date(),
					 itsDataParKeywords->sourceDirection(),
					 itsCurrSourceRow);

    // Match or add a FIELD_ID 
    itsCurrFieldId = matchOrAddFieldId(itsDataParKeywords->sourceName(),
				       itsDataParKeywords->calCode(),
				       itsDataParKeywords->date(),
				       itsDataParKeywords->sourceDirection(),
				       itsCurrSourceId);
    // Match or add an OBSERVATION_ID
    itsCurrObsId = matchOrAddObsId(itsDataParKeywords->projectId());
  };

  // Convert the binary table extension to an AIPS++ Table
  //  String tablename = "datapar-scratch";
  //  Table tab = bintab.fullTable(tablename, Table::New);
  if(datapar_p) delete datapar_p;
  datapar_p = new Table(bintab.fullTable());

  
  return;
}
  
//----------------------------------------------------------------------------

void AlmaTI2MS::readCalibrTable(BinaryTable& bintab)
{
// Read and process the CALIBR-ALMATI binary table
// Input:
//    bintab            BinaryTable&         FITS binary table at
//                                           current FitsInput position
//
  LogIO os(LogOrigin("AlmaTI2MS", "readCalibrTable()", WHERE));

  // No useful information in the CALIBR-ALMATI keywords

  // Convert the binary table extension to an AIPS++ Table
  String tablename = "calibr-scratch";
  Table tab = bintab.fullTable(tablename, Table::New);

  // Reset the mapping of ALMATI antenna numbers to their 
  // associated MS antenna id.'s and feed id.'s.
  itsAntennaIdMap.clear();
  itsFeedIdMap.clear();

  // Reset the CALIBR-ALMATI Tsys values per antenna and baseband
  uInt nAnt = itsDataParKeywords->nAnt();
  uInt nReceptors = itsDataParKeywords->nReceptors();
  uInt nBaseBand = itsDataParKeywords->nBaseBand();
  itsCalibrTsys.resize(IPosition(3, nAnt, nReceptors, nBaseBand));
  itsCalibrTsys = 0;
  
  // Column accessors for ANTENNA-ALMATI binary table data
  ScalarColumn<Int> antennid(tab, "ANTENNID");
  ScalarColumn<Int> statioid(tab, "STATIOID");
  ArrayColumn<Double> stabxyz(tab, "STABXYZ");
  ScalarColumn<Float> staxof(tab, "STAXOF");
  ScalarColumn<String> polty(tab, "POLTY");
  ScalarColumn<Float> pola(tab, "POLA");
  ArrayColumn<Float> tsys(tab, "TSYS");

  // Match or add an ANTENNA table entry for each row, and
  // extract the Tsys information per antenna and baseband
  itsAntennaIds.resize(antennid.nrow());
  Int antennaId, feedId;
  for (uInt fitsRow=0; fitsRow<antennid.nrow(); fitsRow++) {

    antennaId = matchOrAddAntennaId(antennid(fitsRow), statioid(fitsRow), 
				    stabxyz(fitsRow), staxof(fitsRow));

    // Match or add a FEED_ID for this antenna id.
    Int feedRow;
    Vector<String> poltyVec(1, polty(fitsRow));
    Vector<Float> polaVec(1, pola(fitsRow));
    feedId = matchOrAddFeedId(antennaId, poltyVec, polaVec, 
			      itsDataParKeywords->date(), feedRow);

    // Add an entry to the antenna id. and feed id. mappings
    // (from ALMATI to the MS).
    itsAntennaIds(fitsRow) = antennid(fitsRow);
    itsAntennaIdMap.define(antennid(fitsRow), antennaId);
    itsFeedIdMap.define(antennid(fitsRow), feedId);
    
    // Extract the Tsys information 
    Vector<Float> tsysPerRecepBand;
    tsys.get(fitsRow, tsysPerRecepBand);
    Int fitsIndx;
    for (uInt receptor=0; receptor < nReceptors; receptor++) {
      for (uInt baseband=0; baseband < nBaseBand; baseband++) {
	// Compute the index in the FITS array
	fitsIndx = baseband * nReceptors + receptor;
	itsCalibrTsys(fitsRow, receptor, baseband) = 
	  tsysPerRecepBand(fitsIndx);
      };
    };
  };
  return;
}
  
//----------------------------------------------------------------------------

void AlmaTI2MS::readCorrDataTable(BinaryTable& bintab)
{
// Read and process the CORRDATA-ALMATI binary table
// Input:
//    bintab            BinaryTable&         FITS binary table at
//                                           current FitsInput position
//
  LogIO os(LogOrigin("AlmaTI2MS", "readCorrDataTable()", WHERE));

  // Indicate that we have read CORRDATA data
  itsCorrDataPending = True;

  // Process and store the CORRDATA-ALMATI FITS keywords in an index
  // of CORRDATA keywords. All CORRDATA tables are read and converted 
  // to AIPS++ scratch tables, named by sequence nnumber so that 
  // frequency information can we analyzed for the set as a whole 
  // if baseband concatenation is requested. This also allows the
  // option of writing TIME-BASELINE-SPW_ID sorted data for
  // greater efficiency. The indexed CORRDATA tables are processed 
  // in readDataParTable() at the point when the next DATAPAR-ALMATI 
  // table is read.
  Int nIndex = itsCorrDataKeyw.nelements();
  itsCorrDataKeyw.resize(nIndex+1);
  itsCorrDataKeyw[nIndex] = new CorrDataKeywords(bintab.kwlist());
  if(corrDataTables.nelements() >= (nIndex+1)){
    for (uInt ko=(nIndex); ko < corrDataTables.nelements(); ++ko){
      if(corrDataTables[ko]) delete corrDataTables[ko];

    }

  }
  corrDataTables.resize(nIndex+1);

  // Convert the FITS binary table extension to an AIPS++ scratch table,
  // named to include the CORRDATA index number
  //  String tablename = "corrdata-scratch-"+ String::toString(nIndex);
  //  Table tab = bintab.fullTable(tablename, Table::New);
  //  tab.flush();
  corrDataTables[nIndex] = new Table(bintab.fullTable());

  return;
}
  
//----------------------------------------------------------------------------

void AlmaTI2MS::processCorrData()
{
// Process CORRDATA already read and indexed
//
  LogIO os(LogOrigin("AlmaTI2MS", "processCorrData()", WHERE));

  // Check for a valid index of CORRDATA tables already read
  uInt nCorrDataTabs = itsCorrDataKeyw.nelements();

  if (nCorrDataTabs > 0) {
    // Open the last DATAPAR-ALMATI table and attach column accessors
    //    Table datapar("datapar-scratch");
    Int nRowDataPar = datapar_p->nrow();
    ROScalarColumn<Int> integnumDataPar(*datapar_p, "INTEGNUM");
    ROScalarColumn<Float> integtimDataPar(*datapar_p, "INTEGTIM");
    ROScalarColumn<Double> mjdDataPar(*datapar_p, "MJD");
    ROArrayColumn<Double> uuvvwwDataPar(*datapar_p, "UUVVWW");
    ROArrayColumn<Int> flagDataPar(*datapar_p, "FLAG");
    ROArrayColumn<Bool> corrDataPar(*datapar_p, "CORR");
    ROArrayColumn<Float> totpowerDataPar(*datapar_p, "TOTPOWER");


    // Mark those DATAPAR rows which have the longest integration time,
    // and therefore represent time averaged data
    Vector<Bool> timeAvgRow(nRowDataPar, False);
    Float minIntegration = min(integtimDataPar.getColumn());
    Float maxIntegration = max(integtimDataPar.getColumn());
    if (maxIntegration != minIntegration) {
      for (Int row=0; row<nRowDataPar; row++) {
	if (integtimDataPar(row) == maxIntegration) timeAvgRow(row) = True;
      };
    };

    // Open all associated indexed CORRDATA tables previously
    // read, attach separate column accessors to each table and
    // generate a list of row numbers (for subsequent table 
    // match operations). Also, maintain a list of matching
    // spectral window id.'s, polarization id.'s and 
    // data desc. id.'s for each CORRDATA table [LSB,USB].
    //    PtrBlock<Table*> corrDataTables(nCorrDataTabs, NULL);
    PtrBlock<ROScalarColumn<Int>*> integnumCorrData(nCorrDataTabs, NULL);
    PtrBlock<ROScalarColumn<Int>*> startantCorrData(nCorrDataTabs, NULL);
    PtrBlock<ROScalarColumn<Int>*> endantCorrData(nCorrDataTabs, NULL);
    PtrBlock<ROArrayColumn<Float>*> datausb1CorrData(nCorrDataTabs, NULL);
    PtrBlock<ROArrayColumn<Float>*> datalsb1CorrData(nCorrDataTabs, NULL);
    // Row numbers for each CORRDATA table
    PtrBlock<Vector<Int>*> rownoCorrData(nCorrDataTabs);
    // Matching spectral window id.'s for each CORRDATA table for (LSB,USB)
    IPosition matchShape(2, nCorrDataTabs, 2);
    Matrix<Int> matchingSpwIdCorrData(matchShape, -1);
    // Matching polarization id.'s for each CORRDATA table for (LSB,USB)
    Matrix<Int> matchingPolznIdCorrData(matchShape, -1);
    // Matching data desc. id.'s for each CORRDATA table for (LSB,USB)
    Matrix<Int> matchingDataDescIdCorrData(matchShape, -1);

    for (uInt tabNum=0; tabNum < nCorrDataTabs; tabNum++) {
      // Open each CORRDATA table
      //corrDataTables[tabNum] = 
      //	new Table("corrdata-scratch-"+String::toString(tabNum));

      // Attach column accessors
      integnumCorrData[tabNum] = new 
	ROScalarColumn<Int>(*corrDataTables[tabNum], "INTEGNUM");
      startantCorrData[tabNum] = new
	ROScalarColumn<Int>(*corrDataTables[tabNum], "STARTANT");
      endantCorrData[tabNum] = new
	ROScalarColumn<Int>(*corrDataTables[tabNum], "ENDANT");
      datausb1CorrData[tabNum] = new
	ROArrayColumn<Float>(*corrDataTables[tabNum], "DATAUSB1");
      datalsb1CorrData[tabNum] = new
	ROArrayColumn<Float>(*corrDataTables[tabNum], "DATALSB1");

      // Generate row numbers
      uInt nRows = corrDataTables[tabNum]->nrow();
      rownoCorrData[tabNum] = new Vector<Int>(nRows);
      indgen(*rownoCorrData[tabNum]);
    };



    // Create a columns accessor for the MS MAIN table
    MSMainColumns msMainCol(*itsMS);
    // Create colum accessors for non-standard columns individually
    ArrayColumn<Complex> noPhasCorrCol(*itsMS, "ALMA_NO_PHAS_CORR");
    ArrayColumn<Complex> phasCorrCol(*itsMS, "ALMA_PHAS_CORR");
    ScalarColumn<Bool> phasCorrFlagRowCol(*itsMS, "ALMA_PHAS_CORR_FLAG_ROW");

    // Loop over each integration point in the DATAPAR table
    for (Int dataParRow=0; dataParRow < nRowDataPar; dataParRow++) {
      // Read the DATAPAR table CORR entry for this row (which
      // contains flags for associated CORRDATA tables).
      Vector<Bool> validCorrData;
      corrDataPar.get(dataParRow, validCorrData);
      
      // Loop over each indexed CORRDATA table
      for (uInt tabNum=0; tabNum < nCorrDataTabs; tabNum++) {

	// Check DATAPAR table CORR entry for this row to
	// see if there are associated data in this CORRDATA table
	Bool filter = (!validCorrData(itsCorrDataKeyw[tabNum]->tableId()-1));

	if (!filter) {
	  // Check channel-zero selection mode: either filter all 
	  // channel-zero data (NONE), or accept only fully 
	  // time-sampled channel-zero data (TIME_SAMPLED),
	  // or only those channel-zero data already averaged in 
	  // time (TIME_AVG)
	  Bool chanZero = (itsCorrDataKeyw[tabNum]->nChan() == 1);

	  switch (itsChanZeroSelection) {
	  case NONE: {
	    filter = chanZero;
	  };
	  break;
	  case TIME_SAMPLED: {
	    filter = (chanZero && timeAvgRow(dataParRow));
	  };
	  break;
	  case TIME_AVG: {
	    filter = (chanZero && !timeAvgRow(dataParRow));
	  };
	  break;
	  };
	};


	if (!filter)  {

	  // Find the matching rows in this CORRDATA table for 
	  // the current DATAPAR integration point
	  LogicalArray maskArray = (integnumCorrData[tabNum]->getColumn() ==
				    integnumDataPar.asInt(dataParRow));
	  MaskedArray<Int> maskRowNo(*rownoCorrData[tabNum], maskArray);
	  Vector<Int> matchingCorrDataRows = maskRowNo.getCompressedArray();

	  // Loop over the matching CORRDATA rows
	  uInt nMatchCorrData = matchingCorrDataRows.nelements();

	  if (nMatchCorrData > 0) {
	    for (uInt corrDataRowIndx=0; corrDataRowIndx < nMatchCorrData; 
		 corrDataRowIndx++) {
	      // Set the current matching CORRDATA table row
	      Int corrDataRow = matchingCorrDataRows(corrDataRowIndx);

	      // Useful types for sideband iteration
	      CorrDataKeywords::sideBand LSB = CorrDataKeywords::LSB;
	      CorrDataKeywords::sideBand USB = CorrDataKeywords::USB;
	      CorrDataKeywords::line A = CorrDataKeywords::A;

	      // Loop over sideband [LSB,USB]
	      for (Int sideBandIndx=0; sideBandIndx < 2; sideBandIndx++) {
		// Set sideband enum
		CorrDataKeywords::sideBand sideBand = sideBandIndx == 0 ?
		  LSB : USB;

		// Check if this sideband is present in the CORRDATA table
		if (itsCorrDataKeyw[tabNum]->isSideBandPresent(sideBand)) {
		  
		  // Find the matching spectral window id. (if not
		  // already matched previously)
		  if (matchingSpwIdCorrData(tabNum,sideBandIndx) < 0) {
		    Int numChan = itsCorrDataKeyw[tabNum]->nChan();
		    MVFrequency channelWidth = itsCorrDataKeyw[tabNum]->
		      chanWidth(sideBand);
		    Vector<MVFrequency> vecChanWidth(numChan, channelWidth);
		    
		    // Match the LSRK frequency axis in preference (if
		    // it can be constructed), over the topocentric axis
		    Vector<MFrequency> freqAxis;
		    if (!itsCorrDataKeyw[tabNum]->
			chanFreqLSRK(sideBand, itsDataParKeywords->dopVel(),
				     freqAxis)) {
		      freqAxis = itsCorrDataKeyw[tabNum]->chanFreq(sideBand);
		    };

		    // Tolerance (in Hz) to match spw. id.'s
		    Double tol = 1e6;
		    matchingSpwIdCorrData(tabNum,sideBandIndx) = 
		      matchOrAddSpwId(freqAxis, vecChanWidth, tol, sideBand, 
				      itsCorrDataKeyw[tabNum]->lineName(A));

		    
		    Int spwPrt = matchingSpwIdCorrData(tabNum,sideBandIndx);
		    if (spwPrt >= spwIdPrinted.nelements()) {
		      spwIdPrinted.resize(spwPrt+1, True);
		      spwIdPrinted(spwPrt) = False;
		    }

		    if (!spwIdPrinted(spwPrt)) {
		      
		      /*                    os.output().precision(12);
		    os << "===== spwId = " << spwPrt << "============= " 
		       << itsDataParKeywords->sourceName() << " ===== "
		       << LogIO::POST;
		    os << LogIO::NORMAL << "baseBandNo = " << 
		      itsCorrDataKeyw[tabNum]->baseBandNo() 
		       << ", nChan = " 
		       << itsCorrDataKeyw[tabNum]->nChan() 
		       << ", sideBand = " << sideBand << LogIO::POST;
		    os << LogIO::NORMAL << "ref chan = " 
		       << itsCorrDataKeyw[tabNum]->refChan(sideBand) 
		       << LogIO::POST;
		    os << LogIO::NORMAL << "ref freq = ";
		    itsCorrDataKeyw[tabNum]->
		      refFreq(sideBand).print(os.output()); 
		    os << LogIO::POST;
		    os << LogIO::NORMAL << "chan width = ";
		    itsCorrDataKeyw[tabNum]->
		      chanWidth(sideBand).print(os.output()); 
		    os << LogIO::POST;
		    os << LogIO::NORMAL << "intermediate freq = ";
		    itsCorrDataKeyw[tabNum]->
		      intermediateFreq().print(os.output());
		    os << LogIO::POST;
		    os << LogIO::NORMAL << "LSRK ref freq_1 = ";
		    freqAxis(0).print(os.output());
		    os << ", freq_n = "; 
		    freqAxis(numChan-1).print(os.output());
		    os << LogIO::POST;

		    if (itsCorrDataKeyw[tabNum]->isVelocityPresent(sideBand)) {
		      os << LogIO::NORMAL << "vel ref chan = " 
			 << itsCorrDataKeyw[tabNum]->velRefChan(sideBand) 
			 << LogIO::POST;
		      os << LogIO::NORMAL << "ref vel = ";
		      itsCorrDataKeyw[tabNum]->
			refVel(sideBand).print(os.output()); 
		      os << LogIO::POST;
		      os << LogIO::NORMAL << "vel chan width = ";
		      itsCorrDataKeyw[tabNum]->
			chanWidthVel(sideBand).print(os.output()); 
		      os << LogIO::POST;
		      os << LogIO::NORMAL << "sys vel = ";
		      itsCorrDataKeyw[tabNum]->
			sysVel(sideBand).print(os.output());
		      os << LogIO::POST;
		      }; */
		    spwIdPrinted(spwPrt) = True; 
		    };

		  };
		  
		  // Find the matching polarization id. (if not already
		  // matched previously)
		  if (matchingPolznIdCorrData(tabNum,sideBandIndx) < 0) {
		    // Default IRAM receptor cross-products are (0,0)
		    IPosition shape(2,2,itsCorrDataKeyw[tabNum]->nPolznCorr());
		    Matrix<Int> corrProduct(shape, 0);
		    matchingPolznIdCorrData(tabNum,sideBandIndx) =
		      matchOrAddPolznId(itsCorrDataKeyw[tabNum]->
					stokesAxis(sideBand), corrProduct);
		  };

		  // Find the matching data desc. id. (if not already
		  // matched previously)
		  if (matchingDataDescIdCorrData(tabNum,sideBandIndx) < 0) {
		    Int spwId = matchingSpwIdCorrData(tabNum,sideBandIndx);
		    Int polznId = matchingPolznIdCorrData(tabNum,sideBandIndx);
		    matchingDataDescIdCorrData(tabNum,sideBandIndx) =
		      matchOrAddDataDescId(spwId, polznId);
		  };

		  // Add a new row to MS MAIN, and update each column
		  uInt newRow = itsMS->nrow();
		  itsMS->addRow();
		  
		  // TIME and TIME_CENTROID5
		  MVEpoch timeVal(mjdDataPar.asdouble(dataParRow));
		  MEpoch time(timeVal.getTime("s"), MEpoch::UTC);
		  msMainCol.timeMeas().put(newRow, time);
		  msMainCol.timeCentroidMeas().put(newRow, time);

		  // INTERVAL and EXPOSURE
		  MVEpoch interval =
		    Quantity(integtimDataPar.asfloat(dataParRow), "s");
		  msMainCol.intervalQuant().put(newRow, interval.getTime());
		  msMainCol.exposureQuant().put(newRow, interval.getTime());

		  // ANTENNA1 and ANTENNA2
		  // Map from ALMATI antenna id. to the associated MS values
		  Int almatiAnt1 = 
		    startantCorrData[tabNum]->asInt(corrDataRow);
		  // Reconcile different numbering in CALIBR and CORRDATA. 
		  // The start and end antenna numbers used here are
		  // 1-based FITS row numbers in CALIBR rather than 
		  // CALIBR::ANTENNID numbers.
		  Int antenna1 = itsAntennaIdMap(itsAntennaIds(almatiAnt1-1));
		  Int almatiAnt2 = 
		    endantCorrData[tabNum]->asInt(corrDataRow);
		  // Reconcile different numbering in CALIBR and CORRDATA. 
		  // The start and end antenna numbers used here are 
		  // 1-based FITS row numbers in CALIBR rather than 
		  // CALIBR::ANTENNID numbers.
		  Int antenna2 = itsAntennaIdMap(itsAntennaIds(almatiAnt2-1));

		  // Enforce ascending antenna id.'s for each baseline
		  Bool flipBaseline = (antenna1 > antenna2);
		  if (flipBaseline) {
		    // Swap antenna1 and antenna2
		    Int temp = antenna1;
		    antenna1 = antenna2;
		    antenna2 = temp;
		    // Swap almatiAnt1 and almatiAnt2
		    temp = almatiAnt1;
		    almatiAnt1 = almatiAnt2;
		    almatiAnt2 = temp;
		  };
		  msMainCol.antenna1().put(newRow, antenna1);
		  msMainCol.antenna2().put(newRow, antenna2);

		  // FEED1 and FEED2
		  // Map from ALMATI antenna id. to the associated MS value
		  Int feed1 = itsFeedIdMap(almatiAnt1);
		  msMainCol.feed1().put(newRow, feed1);
		  Int feed2 = itsFeedIdMap(almatiAnt2);
		  msMainCol.feed2().put(newRow, feed2);

		  // DATA_DESC_ID
		  Int dataDescId = matchingDataDescIdCorrData(tabNum,
							      sideBandIndx);
		  msMainCol.dataDescId().put(newRow, dataDescId);

		  // PROCESSOR_ID
		  msMainCol.processorId().put(newRow, -1);

		  // FIELD_ID
		  msMainCol.fieldId().put(newRow, itsCurrFieldId);

		  // SCAN_NUMBER
		  Int scanNumber = itsDataParKeywords->scanNum();
		  msMainCol.scanNumber().put(newRow, scanNumber);

		  // ARRAY_ID
		  msMainCol.arrayId().put(newRow, 0);

		  // OBSERVATION_ID
		  msMainCol.observationId().put(newRow, itsCurrObsId);

		  // STATE_ID
		  msMainCol.stateId().put(newRow, -1);

		  // UVW
		  Vector<Double> uvwPerAnt;
		  uuvvwwDataPar.get(dataParRow, uvwPerAnt);
		  Vector<Double> uvw(3);
		  for (uInt i=0; i < 3; i++) {
		    // Compute index in the FITS array
		    Int indx1 = (almatiAnt1 - 1) * 3 + i;
		    Int indx2 = (almatiAnt2 - 1) * 3 + i;
		    // Form baseline UVW as (antenna 1 - antenna 2)
		    uvw(i) = uvwPerAnt(indx2) - uvwPerAnt(indx1);
		  };

		  msMainCol.uvw().put(newRow, uvw);

		  // ALMA_NO_PHAS_CORR and DATA
		  //
		  // First, determine the sqrt(Tsys_1 * Tsys_2)
		  // scaling factor applicable to all ALMATI data
		  Int baseBandNo = itsCorrDataKeyw[tabNum]->baseBandNo();
		  Int nBaseBand = itsDataParKeywords->nBaseBand();
		  Float tsys1 = itsCalibrTsys(almatiAnt1-1,0,baseBandNo-1);
		  Float tsys2 = itsCalibrTsys(almatiAnt2-1,0,baseBandNo-1);
		  Float scaleFactor = 1.0;
		  if (tsys1 * tsys2 > 0) {
		    scaleFactor = sqrt(tsys1 * tsys2);
		  };

		  //
		  // Extract the phase-uncorrected data from 
		  // the CORRDATA arrays DATAUSB1 or DATALSB1
		  Int nChan = itsCorrDataKeyw[tabNum]->nChan();
		  Int nCorr = itsCorrDataKeyw[tabNum]->nPolznCorr();
		  IPosition dataShape(2, nCorr, nChan);
		  Int jcorr = 0;
		  Int fitsIndx = 0;
		  Int fitsIncr = 2;
		  // Extract the FITS data array in this CORRDATA row
		  Vector<Float> fitsData;
		  if (sideBand == LSB) {
		    datalsb1CorrData[tabNum]->get(corrDataRow, fitsData, True);
		  } else if (sideBand == USB) {
		    datausb1CorrData[tabNum]->get(corrDataRow, fitsData, True);
		  };

		  Matrix<Complex> noPhasCorrData(dataShape);
		  // Conjugate the data if the baseline has been flipped
		  Float conjFactor = 1.0;
		  if (flipBaseline) {
		    conjFactor = -1.0;
		  };
		  for (Int jchan=0; jchan < nChan; jchan++) {
		    noPhasCorrData(jcorr,jchan)= scaleFactor * 
		      Complex(fitsData(fitsIndx), 
			      conjFactor * fitsData(fitsIndx+1));
		    fitsIndx = fitsIndx + fitsIncr;
		  };
		  noPhasCorrCol.setShape(newRow, dataShape);
		  noPhasCorrCol.put(newRow, noPhasCorrData);
		  
		  // ALMA_PHAS_CORR
		  if (itsCorrDataKeyw[tabNum]->isPhasCorrPresent(sideBand)) {
		    Matrix<Complex> phasCorrData(dataShape);
		    for (Int jchan=0; jchan < nChan; jchan++) {
		      phasCorrData(jcorr,jchan)= scaleFactor * 
			Complex(fitsData(fitsIndx), 
				conjFactor * fitsData(fitsIndx+1));
		      fitsIndx = fitsIndx + fitsIncr;
		    };
		    phasCorrCol.setShape(newRow, dataShape);
		    phasCorrCol.put(newRow, phasCorrData);
		    phasCorrFlagRowCol.put(newRow, False);

		    // Initialize the DATA column with the phase-corrected data
		    msMainCol.data().setShape(newRow, dataShape);
		    msMainCol.data().put(newRow, phasCorrData);

		  } else {
		    // No phase-corrected data present
		    Complex cZero(0,0);
		    Matrix<Complex> emptyData(dataShape, cZero);
		    phasCorrCol.put(newRow, emptyData);
		    phasCorrFlagRowCol.put(newRow, True);

		    // Initialize the DATA column with the phase-corrected data
		    msMainCol.data().setShape(newRow, dataShape);
		    msMainCol.data().put(newRow, emptyData);
		  };

		  // SIGMA, WEIGHT and WEIGHT_SPECTRUM
		  // Use Tsys, integration time and bandwidth weighting
		  Vector<Float> totPowerPerBandAnt;
		  totpowerDataPar.get(dataParRow, totPowerPerBandAnt);
		  // Compure indices into the FITS array for ant. 1 & 2
		  // Get total power for antenna 1 & 2
		  Int indx1 = (almatiAnt1-1) * nBaseBand + baseBandNo - 1;
		  //		  Float tsys1 = totPowerPerBandAnt(indx1);
		  Int indx2 = (almatiAnt2-1) * nBaseBand + baseBandNo - 1;
		  //		  Float tsys2 = totPowerPerBandAnt(indx2);
		  // Compute sigma squared
		  Double bwHz = abs(itsCorrDataKeyw[tabNum]->
		    chanWidth(sideBand).get("Hz").getValue());
		  Double timeSec = interval.getTime("s").getValue();
		  Float sigmaSqr = (tsys1 * tsys2) / (bwHz * timeSec);
		  sigmaSqr = (sigmaSqr > 0) ? sigmaSqr : 1.0;
		  
		  // Set SIGMA
		  Vector<Float> sigma(nCorr, sqrt(sigmaSqr));
		  msMainCol.sigma().put(newRow, sigma);

		  // Use 1/sigma^2 weights for WEIGHT
		  Vector<Float> weight(nCorr, 1.0/(sigmaSqr*nChan));
		  msMainCol.weight().put(newRow, weight);

		  // Use 1/sigma^2 weights for WEIGHT_SPECTRUM
		  Matrix<Float> weightSpectrum(dataShape, 1.0/sigmaSqr);
		  msMainCol.weightSpectrum().put(newRow, weightSpectrum);
		  
		  // FLAG and FLAG_ROW
		  Matrix<Bool> flag(dataShape, False);
		  Bool flagRow = True;

		  // Examine the DATAPAR flags for this integration point
		  Vector<Int> flagPerPolBandAnt;
		  flagDataPar.get(dataParRow, flagPerPolBandAnt);
		  // Set the flag array accordingly
		  for (Int corr = 0; corr < nCorr; corr++) {
		    for (Int chan = 0; chan < nChan; chan++) {
		      // Compute the index in the FITS array for ant. 1 & 2

		      // Note [9/02]: error in ALMA-TI writer discovered
		      // discovered (no intrinsic sub-band index in practice)
		      // Following two lines are a temporary patch
                      // Start patch: 9/02
		      //indx1 = (almatiAnt1-1) * nCorr + corr;
		      //indx2 = (almatiAnt2-1) * nCorr + corr;
		      //Patched bypassed at request of Dominique
		      // Re-enable indx1, indx2 computation when patch removed
		      indx1 = (almatiAnt1-1) * nCorr * nBaseBand +
		       	(baseBandNo-1) * nCorr + corr;
		      indx2 = (almatiAnt2-1) * nCorr * nBaseBand + 
			(baseBandNo-1) * nCorr + corr;
                      // End patch: 9/02

		      flag(corr,chan) = (flagPerPolBandAnt(indx1) ||
					 flagPerPolBandAnt(indx2));
		      if (!flag(corr,chan)) flagRow = False;
		    };
		  };
		  msMainCol.flag().put(newRow, flag);
		  msMainCol.flagRow().put(newRow, flagRow);
		};
	      };
	    };
	  };
	};
      };
    };

    // Explicitly close all column accessors and CORRDATA tables
    for (uInt tabNum=0; tabNum < nCorrDataTabs; tabNum++) {
      if (integnumCorrData[tabNum]) delete(integnumCorrData[tabNum]);
      if (startantCorrData[tabNum]) delete(startantCorrData[tabNum]);
      if (endantCorrData[tabNum]) delete(endantCorrData[tabNum]);
      if (datausb1CorrData[tabNum]) delete(datausb1CorrData[tabNum]);
      if (datalsb1CorrData[tabNum]) delete(datalsb1CorrData[tabNum]);
      if (corrDataTables[tabNum]) {
	delete(corrDataTables[tabNum]); 
	corrDataTables[tabNum]=0;
      }
    };
  };
      
  // Mark all CORRDATA as having been processed
  itsCorrDataPending = False;
    
  return;
}
  
//----------------------------------------------------------------------------

Int AlmaTI2MS::matchOrAddFieldId(const String& fieldName, 
				 const String& calCode, const MEpoch& date,
				 const MDirection& fieldDirection,
				 const Int& sourceId)
{
// Match an existing field id. or add a new field id.
// Input:
//    fieldName            const String&           Field name
//    calCode              const String&           Calibration code
//    date                 const MEpoch&           Observing date
//    fieldDirection       const MDirection&       Field direction
//    sourceId             const Int&              Source id.
// Output:
//    matchOrAddFieldId    Int                     Existing or new field id.
//
  LogIO os(LogOrigin("AlmaTI2MS", "matchOrAddFieldId()", WHERE));

  // Initialization
  Int retval;

  // Check for a matching field name
  Vector<Int> fieldIds;
  Bool found;
  {
    MSFieldIndex fieldIndex(itsMS->field());
    fieldIds = fieldIndex.matchFieldName(fieldName);
    found = (fieldIds.nelements() > 0);
  }
  
  if (found) {
    // Matching field id. found
    retval = fieldIds(0);
  } else {
    // Append a new field id to the FIELD table
    MSFieldColumns fieldCol(itsMS->field());
    uInt newRow = fieldCol.nrow();
    itsMS->field().addRow(1);
    fieldCol.name().put(newRow, fieldName);
    fieldCol.code().put(newRow, calCode);
    fieldCol.timeMeas().put(newRow, date);
    fieldCol.numPoly().put(newRow, 0);
    Vector<MDirection> polyDir(1, fieldDirection);
    fieldCol.delayDirMeasCol().put(newRow, polyDir);
    fieldCol.phaseDirMeasCol().put(newRow, polyDir);
    fieldCol.referenceDirMeasCol().put(newRow, polyDir);
    fieldCol.sourceId().put(newRow, sourceId);
    if (!fieldCol.ephemerisId().isNull()) {
      fieldCol.ephemerisId().put(newRow, -1);
    };
    fieldCol.flagRow().put(newRow, False);
    retval = newRow;
  };

  return retval;
}
  
//----------------------------------------------------------------------------

Int AlmaTI2MS::matchOrAddSourceId(const String& sourceName, 
				  const String& calCode, const MEpoch& date,
				  const MDirection& sourceDirection,
				  Int& row)
{
// Match an existing source id. or add a new source id.
// Input:
//    sourceName           const String&           Source name
//    calCode              const String&           Calibration code
//    date                 const MEpoch&           Observing date
//    sourceDirection      const MDirection&       Source direction
// Output:
//    row                  Int&                    Row number
//    matchOrAddSourceId   Int                     Existing or new source id.
//
  LogIO os(LogOrigin("AlmaTI2MS", "matchOrAddSourceId()", WHERE));

  // Initialization
  Int retval;

  // Check for a matching source name
  Vector<Int> sourceIds;
  Bool found;
  {
    MSSourceIndex sourceIndex(itsMS->source());
    sourceIds = sourceIndex.matchSourceName(sourceName);
    found = (sourceIds.nelements() > 0);
  }
  
  if (found) {
    // Matching source id. found
    retval = sourceIds(0);
    row = retval;
  } else {
    // Find the next free source id.
    MSSourceColumns sourceCol(itsMS->source());
    Int nextSourceId = sourceCol.sourceId().nrow() > 0 ?
      nextSourceId = max(sourceCol.sourceId().getColumn()) + 1 : 0;

    // Append a new source id to the SOURCE table
    uInt newRow = sourceCol.nrow();
    itsMS->source().addRow(1);

    // Fill the new row added to the SOURCE sub-table
    sourceCol.sourceId().put(newRow, nextSourceId);
    sourceCol.timeMeas().put(newRow, date);
    sourceCol.interval().put(newRow, 0);
    sourceCol.spectralWindowId().put(newRow, -1);
    sourceCol.name().put(newRow, sourceName);
    sourceCol.calibrationGroup().put(newRow, 0);
    sourceCol.code().put(newRow, calCode);
    sourceCol.directionMeas().put(newRow, sourceDirection);

    row = newRow;
    retval = nextSourceId;
  };

  return retval;
}

//----------------------------------------------------------------------------

Int AlmaTI2MS::matchOrAddAntennaId(const Int& nameId, const Int& stationId,
				   const Vector<Double>& position,
				   const Float& offset) 
{
// Match an existing antenna id. or add a new antenna id.
// Input:
//    nameId               const Int&              Antenna number
//    stationId            const Int&              Station number
//    position             const Vector<Double>&   Station coordinates
//    offset               const Float&            Axis offset
// Output:
//    matchOrAddAntennaId  Int                     Existing or new antenna id.
//
  LogIO os(LogOrigin("AlmaTI2MS", "matchOrAddAntennaId()", WHERE));

  // Initialization
  Int retval;

  // Convert numerical id.'s to alphanumeric form
  String name = String::toString(nameId);
  String station = String::toString(stationId);

  // Check for a matching (antenna, station) name pair
  Vector<Int> antIds;
  Bool found;
  {
    MSAntennaIndex antIndex(itsMS->antenna());
    antIds = antIndex.matchAntennaNameAndStation(name, station);
    found = (antIds.nelements() > 0);
  }
  
  if (found) {
    // Matching antenna id. found
    retval = antIds(0);
  } else {
    // Append a new antenna id. to the ANTENNA table
    MSAntennaColumns antCol(itsMS->antenna());
    uInt newRow = antCol.nrow();
    itsMS->antenna().addRow(1);

    // Rotate local ant pos by Long, and add array center position
    //  Ref position IS ITRF (GeoCentric)
    MPosition refPosGC(itsDataParKeywords->sitePosition());
    //  Ref position XYZ (m)
    Vector<Double> refPosXYZ(refPosGC.getValue().getValue());
    //  Rotation given by Longitude
    Double siteLong(itsDataParKeywords->sitePosition().getAngle("rad").getValue()(0));
    Matrix<Double> posRot(Rot3D(2,siteLong));
    //  Rotate input position
    Vector<Double> xyz(position);
    xyz=product(posRot,xyz);
    //  Add refPos
    xyz+=refPosXYZ;

    // Fill new antenna id. entry
    antCol.name().put(newRow, name);
    antCol.station().put(newRow, station);
    antCol.type().put(newRow, "GROUND-BASED");
    antCol.mount().put(newRow, "ALT-AZ");
    antCol.position().put(newRow, xyz);
    Vector<Double> offsetVec(3, offset);
    antCol.offset().put(newRow, offsetVec);
    // Plateau de Bure antennas are 15m alt-az mount
    Quantity diameter(15, "m");
    antCol.dishDiameterQuant().put(newRow, diameter);
    antCol.flagRow().put(newRow, False);

    retval = newRow;
  };

  return retval;
}

//----------------------------------------------------------------------------

Int AlmaTI2MS::matchOrAddFeedId(const Int& antennaId, 
				const Vector<String>& polznType,
				const Vector<Float>& receptorAngle, 
				const MEpoch& date, Int& row)
{
// Match an existing feed id. or add a new feed id.
// Input:
//    antennaId            const Int&              Antenna id.
//    polznType            const Vector<String>&   Receptor polarization type
//    receptorAngle        const Vector<Float>&    Receptor angle (deg)
//    date                 const MEpoch&           Observing date
// Output:
//    row                  Int&                    Row number
//    matchOrAddFeedId     Int                     Existing or new feed id.
//
  LogIO os(LogOrigin("AlmaTI2MS", "matchOrAddFeedId()", WHERE));

  // Initialization
  Int retval;

  // Check for a matching feed id. for this antenna id.
  Vector<Int> feedRows, feedIds;
  Bool found;
  MSFeedIndex feedIndex(itsMS->feed());
  // Match receptor angle to within one deg
  Float tol = 1.0;
  feedIds = feedIndex.matchFeedPolznAndAngle(antennaId, polznType,
					     receptorAngle, tol, feedRows);
  found = (feedRows.nelements() > 0);

  if (found) {
    // Matching feed id. found
    row = feedRows(0);
    retval = feedIds(0);

  } else {
    MSFeedColumns feedCol(itsMS->feed());
    // Find next feed id. to use for this antenna id.
    feedIds = feedIndex.matchAntennaId(antennaId, feedRows);
    Int nextFeedId = feedIds.nelements() > 0 ? max(feedIds)+1 : 0;

    // Append a new feed id. to the FEED table for this antenna
    uInt newRow = feedCol.nrow();
    itsMS->feed().addRow(1);

    // Fill new feed id. entry for this antenna
    feedCol.antennaId().put(newRow, antennaId);
    feedCol.feedId().put(newRow, nextFeedId);
    feedCol.spectralWindowId().put(newRow, -1);
    feedCol.timeMeas().put(newRow, date);
    feedCol.interval().put(newRow, 0);
    Int nReceptors = min (polznType.nelements(), receptorAngle.nelements());
    feedCol.numReceptors().put(newRow, nReceptors);
    feedCol.beamId().put(newRow, -1);
    Array<Double> nullOffset(IPosition(2,nReceptors,nReceptors), 
			     static_cast<Double>(0));
    feedCol.beamOffset().put(newRow, nullOffset);
    feedCol.polarizationType().put(newRow, polznType);
    Array<Complex> unitResponse(IPosition(2,nReceptors,nReceptors), 
				static_cast<Complex>(0));
    for (Int i=0; i < nReceptors; i++) {
      unitResponse(IPosition(2,i,i)) = 1.0;
    };
    feedCol.polResponse().put(newRow, unitResponse);
    Vector<Double> nullPosition(3, 0);
    feedCol.position().put(newRow, nullPosition);
    Vector<Quantity> rowAngle(nReceptors);
    for (Int i=0; i<nReceptors; i++) {
      rowAngle(i) = Quantity(receptorAngle(i), "deg");
    };
    feedCol.receptorAngleQuant().put(newRow, rowAngle);

    row = newRow;
    retval = nextFeedId;
  };

  return retval;
}

//----------------------------------------------------------------------------

Int AlmaTI2MS::matchOrAddSpwId(const Vector<MFrequency>& chanFreq,
			       const Vector<MVFrequency>& chanWidth,
			       const Double& tol, const Int& sideBand, 
			       const String& freqGrpName)
{
// Match an existing spectral window id. or add a new spectral window id.
// Input:
//    chanFreq         const Vector<MFrequency>&   Channel frequencies
//    chanWidth        const Vector<MVFrequency>&  Channel frequency width
//    tol              const Double&               Tolerance for frequency
//                                                 comparisons
//    sideBand         const Int&                  Sideband
//    freqGrpName      const String&               Frequency group name
// Output:
//    matchOrAddSpwId  Int                         Existing or new spw id.
//
  LogIO os(LogOrigin("AlmaTI2MS", "matchOrAddSpwId()", WHERE));

  // Initialization
  Int retval;

  // Check for a matching spectral window id.
  Vector<Int> spwIds;
  Bool found;
  {
    MSSpWindowIndex spwIndex(itsMS->spectralWindow());
    spwIds = spwIndex.matchFreq(chanFreq, chanWidth, tol);
    found = (spwIds.nelements() > 0);
  };

  if (found) {
    // Matching spectral window id. found
    retval = spwIds(0);
  } else {
    // Append a new spectral window id. to the SPECTRAL_WINDOW table
    MSSpWindowColumns spwCol(itsMS->spectralWindow());
    uInt newRow = spwCol.nrow();
    itsMS->spectralWindow().addRow(1);

    // Fill new spectral window id. entry
    uInt nChan = chanFreq.nelements();
    spwCol.numChan().put(newRow, nChan);
    spwCol.name().put(newRow, String::toString(newRow));
    // Use mid-point as reference
    uInt midPoint = nChan / 2;
    spwCol.refFrequencyMeas().put(newRow, chanFreq(midPoint));
    spwCol.chanFreqMeas().put(newRow, chanFreq);
    Vector<Quantity> quantChanWidth(nChan);
    for (uInt chan=0; chan<nChan; chan++) {
      quantChanWidth(chan) = chanWidth(chan).get();
    };
    spwCol.chanWidthQuant().put(newRow, quantChanWidth);
    spwCol.effectiveBWQuant().put(newRow, quantChanWidth);
    spwCol.resolutionQuant().put(newRow, quantChanWidth);
    Quantity totalBW(0, "Hz");
    for (uInt chan=0; chan<nChan; chan++) {
      totalBW += abs(chanWidth(chan));
    };
    spwCol.totalBandwidthQuant().put(newRow, totalBW);
    spwCol.netSideband().put(newRow, sideBand);
    String freqGroup;
    Int freqGroupNo, ifConvNo;
    if (chanFreq(midPoint).get("GHz").getValue() > 150) {
      ifConvNo = 0;
      if (sideBand <= 0) {
	freqGroup = "1mm-LSB";
	freqGroupNo = 0;
      } else {
	freqGroup = "1mm-USB";
	freqGroupNo = 1;
      };
    } else {
      ifConvNo = 1;
      if (sideBand <= 0) {
	freqGroup = "3mm-LSB";
	freqGroupNo = 2;
      } else {
	freqGroup = "3mm-USB";
	freqGroupNo = 3;
      };
    };
    spwCol.ifConvChain().put(newRow, ifConvNo);
    spwCol.freqGroup().put(newRow, freqGroupNo);
    spwCol.freqGroupName().put(newRow, freqGroup);
    spwCol.flagRow().put(newRow, False);

    retval = newRow;
  };

  return retval;
}

//----------------------------------------------------------------------------

Int AlmaTI2MS::matchOrAddPolznId(const Vector<Int>& corrType,
				 const Matrix<Int>& corrProduct)
{
// Match an existing polarization id. or add a new polarization id.
// Input:
//    corrType           const Vector<Iny>&    Polarization correlations in
//                                             Stokes.h enum form
//    corrProduct        const Matrix<Int>&    Receptor cross products
// Output:
//    matchOrAddPolznId  Int                   Existing or new polarization id.
//
  LogIO os(LogOrigin("AlmaTI2MS", "matchOrAddPolznId()", WHERE));

  // Initialization
  Int retval;

  // Check for a matching polarization id.
  Vector<Int> polznIds;
  Bool found;
  {
    MSPolarizationIndex polznIndex(itsMS->polarization());
    polznIds = polznIndex.matchCorrTypeAndProduct(corrType, corrProduct);
    found = (polznIds.nelements() > 0);
  };

  if (found) {
    // Matching polarization id. found
    retval = polznIds(0);
  } else {
    // Append a new polarization id. to the POLARIZATION table
    MSPolarizationColumns polznCol(itsMS->polarization());
    uInt newRow = polznCol.nrow();
    itsMS->polarization().addRow(1);

    // Fill the new polarization id. entry
    Int numCorr = min(corrType.nelements(), corrProduct.ncolumn());
    polznCol.numCorr().put(newRow, numCorr);
    polznCol.corrType().put(newRow, corrType);
    polznCol.corrProduct().put(newRow, corrProduct);
    polznCol.flagRow().put(newRow, False);

    retval = newRow;
  };
  return retval;
}

//----------------------------------------------------------------------------

Int AlmaTI2MS::matchOrAddDataDescId(const Int& spwId, const Int& polznId)
{
// Match an existing data desc. id. or add a new data desc. id.
// Input:
//    spwId                 const Int&         Spectral window id. 
//    polznId               const Int&         Polarization id.
// Output:
//    matchOrAddDataDescId  Int                Existing or new data desc. id.
//
  LogIO os(LogOrigin("AlmaTI2MS", "matchOrAddDataDescId()", WHERE));

  // Initialization
  Int retval;

  // Check for a matching data desc. id.
  Vector<Int> dataDescIds;
  Bool found;
  {
    MSDataDescIndex dataDescIndex(itsMS->dataDescription());
    dataDescIds = dataDescIndex.matchSpwIdAndPolznId(spwId, polznId);
    found = (dataDescIds.nelements() > 0);
  };

  if (found) {
    // Matching data desc. id. found
    retval = dataDescIds(0);
  } else {
    // Append a new data desc. id. to the DATA_DESCRIPTION table
    MSDataDescColumns dataDescCol(itsMS->dataDescription());
    uInt newRow = dataDescCol.nrow();
    itsMS->dataDescription().addRow(1);

    // Fill the new data desc. id. entry
    dataDescCol.spectralWindowId().put(newRow, spwId);
    dataDescCol.polarizationId().put(newRow, polznId);
    dataDescCol.flagRow().put(newRow, False);

    retval = newRow;
  };
  return retval;
}

//----------------------------------------------------------------------------

Int AlmaTI2MS::matchOrAddObsId(const String& projectCode)
{
// Match an existing observation id. or add a new observation id.
// Input:
//    projectCode        const String&      Project code
// Output:
//    matchOrAddObsId    Int                Existing or new observation id.
//
  LogIO os(LogOrigin("AlmaTI2MS", "matchOrAddObsId()", WHERE));

  // Initialization
  Int retval;

  // Check for a matching observation id.
  Vector<Int> obsIds;
  Bool found;
  {
    MSObservationIndex obsIndex(itsMS->observation());
    obsIds = obsIndex.matchProjectCode(projectCode);
    found = (obsIds.nelements() > 0);
  };

  if (found) {
    // Matching data desc. id. found
    retval = obsIds(0);
  } else {
    // Append a new observation id. to the OBSERVATION sub-table
    MSObservationColumns obsCol(itsMS->observation());
    uInt newRow = obsCol.nrow();

    itsMS->observation().addRow(1);
    obsCol.telescopeName().put(newRow, "IRAM_PDB");
    obsCol.timeRangeMeas().put(newRow, Vector<MEpoch>(2));
    obsCol.observer().put(newRow, "");
    obsCol.log().put(newRow, Vector<String>(1,""));
    obsCol.scheduleType().put(newRow, "");
    obsCol.schedule().put(newRow, Vector<String>(1,""));
    obsCol.project().put(newRow, projectCode);
    obsCol.releaseDateMeas().put(newRow, MEpoch());
    obsCol.flagRow().put(newRow, False);
    retval = newRow;
  };
  return retval;
}

//----------------------------------------------------------------------------
