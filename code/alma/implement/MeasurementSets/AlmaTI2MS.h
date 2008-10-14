//# AlmaTI2MS.h: Convert ALMA-TI data to MS format
//# Copyright (C) 1996,1997,1998,1999,2001,2002
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
//# Correspondence concerning AIPS++ should be adressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#
//# $Id: AlmaTI2MS.h,v 19.7 2004/11/30 17:50:06 ddebonis Exp $

#ifndef ALMA_ALMATI2MS_H
#define ALMA_ALMATI2MS_H

#include <casa/aips.h>
#include <casa/OS/Path.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Cube.h>
#include <casa/Containers/Block.h>
#include <casa/Containers/SimOrdMap.h>
#include <fits/FITS/fits.h>
#include <fits/FITS/fitsio.h>
#include <fits/FITS/BinTable.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MFrequency.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <alma/MeasurementSets/DataParKeywords.h>
#include <alma/MeasurementSets/CorrDataKeywords.h>

#include <casa/namespace.h>
// <summary> 
// AlmaTI2MS: Convert ALMA-TI data to MS format
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="" demos="">

// <prerequisite>
//   <li> <linkto class="MeasurementSet">MeasurementSet</linkto> module
// </prerequisite>
//
// <etymology>
// From "ALMA", "test interferometer" and "Measurement Set"
// </etymology>
//
// <synopsis>
// The AlmaTI2MS class converts ALMA-TI data, on tape or disk,
// to MeasurementSet (MS) format.
// </etymology>
//
// <example>
// <srcblock>
// </srcblock>
// </example>
//
// <motivation>
// Encapsulate all ALMA-TI to MS conversion capabilities.
// </motivation>
//
// <todo asof="01/03/15">
// (i) General input filtering.
// (ii) Convert all sub-tables
// </todo>

class AlmaTI2MS
{
 public:
  // Construct from a tape device name and MS output file name
  AlmaTI2MS(const Path& tapeDevice, const String& msOut, 
	    const Bool& overWrite);

  // Construct from an input file name and an MS output file name
  AlmaTI2MS(const String& inFile, const String& msOut, const Bool& overWrite);

  // Destructor
  ~AlmaTI2MS();
  
  // Set general options (MS compression and baseband concatenation)
  void setOptions(Bool compress=True, Bool combineBaseBand=True);

  // Set which files are selected (1-rel; for tape-based data)
  void selectFiles(const Vector<Int>& files);

  // General data selection: observation mode and channel-zero selection
  void select(const Vector<String>& obsMode, const String& chanZero);

  // Convert the ALMA-TI data to MS format
  Bool fill();

  // Construct an empty MeasurementSet with the supplied table name,
  // with or without compression enabled. Throw an exception (AipsError) 
  // if the specified Table already exists unless the overwrite argument 
  // is set to True. 
  static MeasurementSet emptyMS(const Path& tableName, 
				const Bool compress=True,
 				const Bool overwrite=False);


  // A FITS error handler which will ignore those FITS compliance
  // issues in the ALMA-TI format which have no significant
  // impact in practice.
  static void fitsErrorHandler(const char*, FITSError::ErrorLevel);

 protected:
  // Initialization (called by all constructors)
  void init(const String& dataSource, const FITS::FitsDevice& deviceType,
	    const String& msOut, const Bool& overWrite);

  // Read and process a ALMA-TI file
  void readFITSFile(Bool& atEnd);

  // Create a new, empty output MS
  void createOutputMS();

 private:
  // Data source and device type
  String itsDataSource;
  FITS::FitsDevice itsDeviceType;

  // MS, status and write options
  String itsMSOut;
  MeasurementSet* itsMS;
  Bool itsMSExists, itsOverWrite;

  // General options (MS compression and baseband concatenation)
  Bool itsMSCompress, itsCombineBaseBand;

  // Selected file numbers (1-relative)
  Vector<Int> itsSelectedFiles;
  Bool itsAllFilesSelected;

  // General data selection:
  // Observing mode:
  Vector<String> itsObsModeSelection;

  // Channel-zero:
  enum chanZeroSelection {
    // No channel-zero data
    NONE = 0,
    // Time-sampled (1s) channel-zero data
    TIME_SAMPLED = 1,
    // Time-averaged channel-zero data
    TIME_AVG = 2};

  chanZeroSelection itsChanZeroSelection;

  // Current FITS data:
  //
  // DATAPAR-ALMATI keywords
  DataParKeywords* itsDataParKeywords;

  // Flag to skip to next DATAPAR-ALMATI table
  Bool itsSkipToNextDataPar;

  // Primary header keywords
  String itsTelescope, itsOrigin, itsCreator, itsComment;

  // Current field id.
  Int itsCurrFieldId;

  // Current source id. and associated SOURCE sub-table row
  Int itsCurrSourceId, itsCurrSourceRow;

  // Current observation id.
  Int itsCurrObsId;

  // Tsys values from the CALIBR-ALMATI table
  Cube<Float> itsCalibrTsys;

  // Index to the FITS keywords of the last set of CORRDATA-ALMATI tables read
  PtrBlock<CorrDataKeywords*> itsCorrDataKeyw;

  // Flag true if CORRDATA tables read awaiting processing
  Bool itsCorrDataPending;

  // Current mapping between the ALMATI antenna numbers
  // and the associated MS antenna id. and feed id. 
  Vector<Int> itsAntennaIds;
  SimpleOrderedMap<Int,Int> itsAntennaIdMap;
  SimpleOrderedMap<Int,Int> itsFeedIdMap;

  // Read and process the primary header extension
  void readPrimaryHeader(FitsInput& infits);

  // Read and process a DATAPAR-ALMATI binary table extension
  void readDataParTable(BinaryTable& bintab);

  // Read and process a MONITOR-ALMATI binary table extension 
  void readMonitorTable(BinaryTable& bintab) {};

  // Read and process a CALIBR-ALMATI binary table extension 
  void readCalibrTable(BinaryTable& bintab);

  // Read a CORRDATA-ALMATI binary table extension 
  void readCorrDataTable(BinaryTable& bintab);

  // Process pending CORRDATA-ALMATI data
  void processCorrData();

  // Read and process an AUTODATA-ALMATI binary table extension 
  void readAutoDataTable(BinaryTable& bintab) {};

  // Read and process a HOLODATA-ALMATI binary table extension
  void readHoloDataTable(BinaryTable& bintab) {};

  // Match an existing field id. or add a new field id.
  Int matchOrAddFieldId(const String& fieldName, 
			const String& calCode, const MEpoch& date,
			const MDirection& fieldDirection, const Int& sourceId);

  // Match an existing source id. or add a new source id.
  Int matchOrAddSourceId(const String& sourceName, 
			 const String& calCode, const MEpoch& date,
			 const MDirection& sourceDirection,
			 Int& row);

  // Match an existing antenna id. or add a new antenna id.
  Int matchOrAddAntennaId(const Int& nameId, const Int& stationId,
			  const Vector<Double>& position, const Float& offset);

  // Match an existing feed id. or add a new feed id.
  Int matchOrAddFeedId(const Int& antennaId, const Vector<String>& polznType,
		       const Vector<Float>& receptorAngle, const MEpoch& date,
		       Int& row);

  // Match an existing spectral window id. or add a new spectral window id.
  Int matchOrAddSpwId(const Vector<MFrequency>& chanFreq,
		      const Vector<MVFrequency>& chanWidth, const Double& tol,
		      const Int& sideBand, const String& freqGrpName);

  // Match an existing polarization id. or add a new polarization id.
  Int matchOrAddPolznId(const Vector<Int>& corrType,
			const Matrix<Int>& corrProduct);

  // Match an existing data desc. id. or add a new data desc. id.
  Int matchOrAddDataDescId(const Int& spwId, const Int& polznId);

  // Match an existing observation id. or add a new observation id.
  Int matchOrAddObsId(const String& projectCode);

  // Temporary private variable (debugging only)
  Vector<Bool> spwIdPrinted;

  //Variables for memory based tables
  Table* datapar_p;
  PtrBlock<Table*> corrDataTables;

};

#endif
