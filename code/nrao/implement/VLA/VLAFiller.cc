//# VLAFiller.cc: 
//# Copyright (C) 1999,2000,2001,2002,2003
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
//# $Id: VLAFiller.cc,v 19.20 2005/05/30 17:31:48 gli Exp $

#include <nrao/VLA/VLAFiller.h>
#include <nrao/VLA/VLAADA.h>
#include <nrao/VLA/VLACDA.h>
#include <nrao/VLA/VLARCA.h>
#include <nrao/VLA/VLASDA.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/Cube.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Slice.h>
#include <casa/Arrays/Vector.h>
#include <casa/Containers/RecordFieldId.h>
#include <casa/Exceptions/Error.h>
#include <casa/Logging/LogFilter.h>
#include <casa/Logging/LogMessage.h>
#include <casa/Logging/LogOrigin.h>
#include <casa/Logging/LogSink.h>
#include <casa/BasicSL/Complex.h>
#include <ms/MeasurementSets/MSAntenna.h>
#include <ms/MeasurementSets/MSAntennaColumns.h>
#include <ms/MeasurementSets/MSDataDescColumns.h>
#include <ms/MeasurementSets/MSDataDescription.h>
#include <ms/MeasurementSets/MSFeed.h>
#include <ms/MeasurementSets/MSFeedColumns.h>
#include <ms/MeasurementSets/MSField.h>
#include <ms/MeasurementSets/MSFieldColumns.h>
#include <ms/MeasurementSets/MSFieldIndex.h>
#include <ms/MeasurementSets/MSObsColumns.h>
#include <ms/MeasurementSets/MSObservation.h>
#include <ms/MeasurementSets/MSPolColumns.h>
#include <ms/MeasurementSets/MSPolarization.h>
#include <ms/MeasurementSets/MSSpWindowColumns.h>
#include <ms/MeasurementSets/MSSpectralWindow.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MDoppler.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MeasRef.h>
#include <measures/Measures/MeasTable.h>
#include <casa/OS/File.h>
#include <casa/OS/Path.h>
#include <casa/Quanta/MVAngle.h>
#include <casa/Quanta/MVBaseline.h>
#include <casa/Quanta/MVDirection.h>
#include <casa/Quanta/MVDoppler.h>
#include <casa/Quanta/MVEpoch.h>
#include <casa/Quanta/MVFrequency.h>
#include <casa/Quanta/MVPosition.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Quanta/MVuvw.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Quanta/Unit.h>
#include <measures/TableMeasures/ArrayMeasColumn.h>
#include <measures/TableMeasures/ScalarMeasColumn.h>
#include <tables/Tables/ArrayColumn.h>
#include <tables/Tables/IncrementalStMan.h>
#include <tables/Tables/TiledColumnStMan.h>
#include <tables/Tables/RefRows.h>
#include <tables/Tables/ScaColDesc.h>
#include <tables/Tables/ScalarColumn.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/StandardStMan.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/TableInfo.h>
#include <tables/Tables/TableRecord.h>
#include <tables/Tables/TiledDataStMan.h>
#include <casa/Utilities/Assert.h>
#include <casa/Utilities/DataType.h>
#include <casa/BasicSL/String.h>
#include <casa/sstream.h>
#include <casa/iomanip.h>

#include <tables/Tables/ExprNode.h>



const uInt maxCDA(VLAEnum::CDA3+1);
const uInt maxIF(VLAEnum::IFD+1);
const uInt nCat = 6; // Number of Flag categories
const uInt maxSubarrays = 5; // The maximum number of subarrays;
const String sigmaCol = "sigmaHyperColumn";
const String dataCol = "dataHyperColumn";
const String flagCol = "flagHyperColumn";
//New addition
const String modDataCol = "modDataHyperColumn";
const String corrDataCol = "corrDataHyperColumn";
const String chanFlagCol = "flagChanHyperColumn";
//====
const String imagingWeightCol = "imagingWeightHyperColumn";
const RecordFieldId sigmaTileId("SIGMA_HYPERCUBE_ID");
const RecordFieldId dataTileId("DATA_HYPERCUBE_ID");
const RecordFieldId flagTileId("FLAG_CATEGORY_HYPERCUBE_ID");
const RecordFieldId imagingWeightTileId("IMAGING_WEIGHT_HYPERCUBE_ID");
//=====new addition
const RecordFieldId modDataTileId("MODEL_DATA_HYPERCUBE_ID");
const RecordFieldId corrDataTileId("CORR_DATA_HYPERCUBE_ID");
const RecordFieldId chanFlagTileId("FLAG_HYPERCUBE_ID");
//=====  
const Quantum<Double> dirTol(10.0, "mas"); // Tolerance on matching fields
const Quantum<Double> posTol(1, "m");     // Tolerance on matching antennas
const Double ns2m = QC::c.getValue("m/ns");

// The following struct is just ways of bundling up a bunch of arguments to
// functions to avoid having too many in the function interface.
struct IterationStatus {
  uInt nVLARecords;
  uInt nRows;
  uInt nAnt;
  Block<Block<uInt> > lastAnt;
  uInt nSpw;
  Block<Block<Int> > lastSpw;
  uInt nPol;
  Block<Block<Int> > lastPol;
  uInt nFld;
  Block<Int> lastFld;
  String lastProject;
  String lastObsMode;
};
 
VLAFiller::VLAFiller(MeasurementSet& output, VLALogicalRecord& input, Double freqTolerance ):
  MSColumns(output),
  itsRecord(input),
  itsInputFilters(),
  itsMS(output),
  itsFrame(),
  //theirFrames(0, MeasFrame()),
  itsMSDirType(MDirection::castType(field().referenceDirMeasCol().getMeasRef().getType())),
  itsDirType(MDirection::N_Types),
  itsDirCtr(),
  itsAzElCtr(),
  itsUvwCtr(),
  itsFreqCtr(),
  itsBlCtr(),
  itsFldId(maxSubarrays, -1),
  itsAntId(),
  itsSpId(maxCDA, -1),
  itsPolId(0),
  itsDataId(maxSubarrays),
  itsNewScan(True),
  itsScan(maxSubarrays, 0),
  itsProject(),
  itsLog(),
  itsDataAcc(),
  itsTileId(),
  itsSigmaAcc(),
  itsFlagAcc(),
  itsImagingWeightAcc(),
  itsModDataAcc(),
  itsCorrDataAcc(),
  itsChanFlagAcc(),
  itsDataShapes(0),
  itsFreqTolerance(freqTolerance)
{
  AlwaysAssert(itsMS.tableInfo().subType() == "VLA", AipsError);
  itsDataAcc = TiledDataStManAccessor(itsMS, dataCol);
  itsModDataAcc=TiledDataStManAccessor(itsMS,modDataCol);
  itsCorrDataAcc=TiledDataStManAccessor(itsMS,corrDataCol);
  itsChanFlagAcc=TiledDataStManAccessor(itsMS,chanFlagCol);
  itsSigmaAcc = TiledDataStManAccessor(itsMS, sigmaCol);
  itsFlagAcc = TiledDataStManAccessor(itsMS, flagCol);
  itsImagingWeightAcc = TiledDataStManAccessor(itsMS, imagingWeightCol);
  const uInt nShapes = itsDataAcc.nhypercubes();
  itsDataShapes.resize(nShapes);
  for (uInt s = 0; s < nShapes; s++) {
    itsDataShapes[s] = itsDataAcc.getHypercubeShape(s).getFirst(2);
  }

  // Deduce what the last scan was from the LAST_SCAN keyword in the SCAN
  // column. The alternative would be to read all the data in this column!
  // Note that the scan number is now per subarray.
  if (nrow() != 0) {
    const RecordFieldId key("LAST_SCAN");
    const TableRecord& keywords = scanNumber().keywordSet();
    DebugAssert(keywords.isDefined(key.fieldName()), AipsError);
    if (keywords.dataType(key) == TpInt) { // Old ms (v16 or earlier)
      itsScan[0] = keywords.asInt(key);
    } else if (keywords.dataType(key) == TpArrayInt) {
      DebugAssert(keywords.shape(key) == IPosition(1, maxSubarrays),AipsError);
      const Vector<Int> lastscans(keywords.asArrayInt(key));
      lastscans.toBlock(itsScan);
    }
  }

  // Check if the frame has been initialised. If not then initialise it with a
  // position, epoch & direction measure. The direction and time values (but
  // not types) will be updated in the fillOne function. The position should
  // never be changed.
  itsFrame.set(MDirection(MVDirection(), itsMSDirType));
  itsFrame.set(MEpoch(MVEpoch(), timeMeas().getMeasRef()));
  MPosition vlaCentre;
  AlwaysAssert(MeasTable::Observatory(vlaCentre, "VLA"), AipsError);
  itsFrame.set(vlaCentre);

  // For the AzEl converter, we only need AzEl
  itsAzElCtr.setOut(MeasRef<MDirection>(MDirection::AZEL, itsFrame));

  // For the direction and uvw converter the output type is fixed.
  itsDirCtr.setOut(MeasRef<MDirection>(itsMSDirType, itsFrame));
  itsUvwCtr.setOut(MeasRef<Muvw>(Muvw::fromDirType(itsMSDirType), itsFrame));
  // For the frequency converter the input type is fixed.
  itsFreqCtr.setModel(MFrequency(MVFrequency(), 
				 MFrequency::Ref(MFrequency::TOPO, itsFrame)));
  // For the baseline converter both the input and output frames are known.
  itsBlCtr.set(MBaseline(MVBaseline(), 
			 MBaseline::Ref(MBaseline::HADEC, itsFrame)),
	       MBaseline::ITRF);
}

VLAFiller::~VLAFiller()
{
}

void VLAFiller::setFilter(const VLAFilterSet& filter){
  itsInputFilters = filter;
}

void VLAFiller::fill(Int verbose){
  itsLog.origin(LogOrigin("VLAFiller", "fill"));
  IterationStatus counts;
  counts.nVLARecords = 0;
  counts.nRows = nrow();
  counts.nAnt = antenna().nrow();
  counts.lastAnt.resize(maxSubarrays);
  counts.nSpw = spectralWindow().nrow();
  counts.lastSpw = Block<Block<Int> >(maxSubarrays, Block<Int>(2, -1));
  counts.nPol = polarization().nrow();
  counts.lastPol = Block<Block<Int> >(maxSubarrays, Block<Int>(2, -1));;
  counts.nFld = field().nrow();
  counts.lastFld.resize(maxSubarrays);
  counts.lastFld = -1;
  counts.lastProject = "";
  counts.lastObsMode = "";
  const uInt initialRow = nrow();
#if defined(AIPS_DEBUG)
  const LogFilter saved(LogMessage::DEBUGGING);
  if (verbose > 0) LogSink::globalSink().filter(saved);
#endif
  AipsError error;
  try {
    while (fillOne()) {
      counts.nVLARecords++;
      if (nrow() != counts.nRows) {
	if (verbose > 0 && 
	    counts.nVLARecords%verbose == 0) {
	  logCurrentRecord(counts);
	}
	logChanges(counts);
      }
      counts.nRows = nrow();
    }
  } catch (AipsError x) {
    itsLog << LogIO::SEVERE 
	   << "An error occurred. The error message is:" << endl
	   << "'" << x.getMesg() << "'" << endl
	   << "Perhaps you ran out of disk space or "
	   << "are using a flaky tape (drive)." << endl
           << "Trying to write a valid measurement set with" << endl
           << "as much data as possible." << LogIO::POST;
    error = x;
  }
  // Now fixup the observation subtable (only if new data has been added).
  if ((nrow() - initialRow) > 0) {
    MSObservation& msObs = itsMS.observation();
    const uInt newRow = msObs.nrow();
    msObs.addRow();
    MSObservationColumns& obsCols = observation();
    obsCols.telescopeName().put(newRow, "VLA");
    const String unavailable = "unavailable";
    const String unknown = "unknown";
    const Vector<String> unavailableVec(1, unavailable);
    obsCols.observer().put(newRow, unavailable);
    obsCols.log().put(newRow, unavailableVec);
    obsCols.scheduleType().put(newRow, unknown);
    obsCols.schedule().put(newRow, unavailableVec);
    obsCols.project().put(newRow, itsProject);
    obsCols.flagRow().put(newRow, False);
    Vector<MEpoch> obsTimeRange(2);
    obsTimeRange(0) = timeMeas()(initialRow);
    const uInt finalRow = nrow() - 1;
    obsTimeRange(1) = timeMeas()(finalRow);
    obsCols.timeRangeMeas().put(newRow, obsTimeRange);
    MVEpoch releaseDate = obsTimeRange(1).getValue();
    releaseDate += MVEpoch(Quantum<Double>(1.5, "a"));
    obsTimeRange(1).set(releaseDate);
    obsCols.releaseDateMeas().put(newRow, obsTimeRange(1));
    ostringstream oos;

  } else {
    if (nrow() == 0) {
      itsLog << "No data in the measurement set\n";
    } else {
      itsLog << "No data appended to the measurement set\n";
    }
    if (counts.nVLARecords == 0) {
      itsLog << LogIO::SEVERE << "Your input may not be in VLA archive format" 
	     << LogIO::POST;
    } else {
      itsLog << "There may be a problem with your data selection criteria" 
	     << LogIO::WARN << LogIO::POST;
    }
  }

 
  if (verbose >=  0) {
    summarise();
  }

  scanNumber().rwKeywordSet().define(RecordFieldId("LAST_SCAN"), 
				     Vector<Int>(itsScan));

  {
    MSSpWindowColumns msSpW(itsMS.spectralWindow());
    Int nSpw=itsMS.spectralWindow().nrow();
    if(nSpw==0) nSpw=1;
    Matrix<Int> selection(2,nSpw);
    selection.row(0)=0; //start
    selection.row(1)=msSpW.numChan().getColumn(); 
    ArrayColumn<Complex> mcd(itsMS,"MODEL_DATA");
    mcd.rwKeywordSet().define("CHANNEL_SELECTION",selection);
  }

#if defined(AIPS_DEBUG)
  LogSink::globalSink().filter(saved);
#endif
  if (error.getMesg().length() > 0) throw(error);
}

Bool VLAFiller::fillOne() { 
  if (!itsRecord.read()) return False;
  if (!itsInputFilters.passThru(itsRecord)) return True;

  const VLARCA& rca = itsRecord.RCA();
  const VLASDA& sda = itsRecord.SDA();
  
  // Check if the revision number is supported.
  if (rca.revision() < 23) {
    itsLog << LogIO::WARN
 	   << "This function has not been tested on VLA archive data "
 	   << "with revisions less " << endl
 	   << "than 23 & the data in this record has a revision level of " 
 	   << rca.revision() << endl
 	   << "It is very likely that the correlation data will be scaled "
 	   << "incorrectly"
 	   << LogIO::POST;
  }
  const uInt subArray = sda.subArray() - 1;
  { // Keep track of which projects have been copied.
    const String thisProject = sda.obsId();
    if (!itsProject.contains(thisProject)) {
      if (itsProject.length() != 0) itsProject += String(" ");
      itsProject += thisProject;
    }
  }
  { // set the observing time. Do this now as it may be needed to convert the
    // field directions from the observed direction type to the direction type
    // used in the MS.
    const MVEpoch obsTime(rca.obsDay(),
			  Quantum<Double>(sda.obsTime(), "s").getValue("d"));
    //    cerr << MVTime(obsTime.getTime()).string(MVTime::YMD) << endl;
    itsFrame.resetEpoch(obsTime);
  }

  { // Workout the field ID.
    const MVDirection fieldDirVal(sda.sourceDir());
    const MDirection::Types fieldDirRef(sda.epoch());
    // Need to convert the direction to the same type as the MS. Otherwise the
    // match will fail.
    MDirection fieldDir(fieldDirVal, fieldDirRef);
    if (fieldDirRef != itsMSDirType) { // need to do a conversion
      if (fieldDirRef == itsDirType) { // no need to setup the converter
	fieldDir = itsDirCtr(fieldDirVal);
      } else {
	itsDirCtr.setModel(fieldDir);
	itsDirType = fieldDirRef;
	fieldDir = itsDirCtr();
	// at the same time the UVW converter should be initialised
 	itsUvwCtr.setModel(Muvw(MVuvw(), Muvw::fromDirType(fieldDirRef)));
      }
    }

    // Determine if field already exists in FIELD subtable
    Bool fldMatch=False;

    // First match on name (maybe multiple name matches with diff directions?):
    //   (this is a clumsy way--and inefficient for large FIELD tables--to 
    //    include name matching, should have andName option in matchDirection)
    MSField& msFld=itsMS.field();
    MSFieldIndex MSFldIdx(msFld);
    Vector<Int> fldNameMatches = MSFldIdx.matchFieldName(sda.sourceName());
    Int nfNM;
    fldNameMatches.shape(nfNM);
    // found at least one name match, verify/discern from direction matching
    Int ifNM=0;
    if (nfNM > 0) {
      while (ifNM < nfNM && !fldMatch) {
	fldMatch = (fldNameMatches(ifNM)==field().matchDirection(fieldDir, fieldDir, fieldDir, dirTol,
								 fldNameMatches(ifNM)));
	if (!fldMatch) ifNM++;
      }
    }
    	    
    Int thisfldId;
    if (fldMatch) {
      // found match:
      thisfldId=fldNameMatches(ifNM);
    } else {
      // found no match, adding a row:
      addSource(fieldDir);
      thisfldId=addField(fieldDir);
    }

    if (thisfldId != itsFldId[subArray]) {
      itsFrame.resetDirection(fieldDir.getValue());
      itsNewScan = True;
      itsFldId[subArray] = thisfldId;
    }
  }

  const uInt nAnt = rca.nAntennas();
// Cache the uvw coordinates of each antenna. For holography mode,
// these are the az, el offsets.
  Block<Double> antUvw(3*nAnt);
  {
    uInt elem = 0;
    Vector<Double> convertedUvw(3);
    Double u, v, w;
    const Bool doConversion = (itsMSDirType == sda.epoch()) ? False : True;
    for (uInt a = 0; a < nAnt; a++) {
      const VLAADA& ada = itsRecord.ADA(a);
      u = ada.u();
      v = ada.v();
      w = ada.w();
      if (doConversion) {
	convertedUvw = itsUvwCtr(MVuvw(u, v, w)).getValue().getValue();
	u = convertedUvw(0);
	v = convertedUvw(1);
	w = convertedUvw(2);
      }
      antUvw[elem] = u; elem++;
      antUvw[elem] = v; elem++;
      antUvw[elem] = w; elem++;
    }
  }

  Block<Bool> shadowed(nAnt, False);
  Bool badData = False;
  { // find out if any antennae are shadowed
    uInt a1Idx = 0;
    for (uInt a1 = 0; a1 < nAnt; a1++) {
      uInt a2Idx = (a1+1)*3;
      for (uInt a2 = a1+1; a2 < nAnt; a2++) {
	Double u = antUvw[a1Idx] - antUvw[a2Idx]; a2Idx++;
	Double v = antUvw[a1Idx+1] - antUvw[a2Idx]; a2Idx++;
	if (u*u + v*v < 625) {
	  badData = True;
	  Double w = antUvw[a1Idx+2] - antUvw[a2Idx];
	  if (w > 0) {
	    shadowed[a2] = True;
	  } else {
	    shadowed[a1] = True;
	  }
 	}
	a2Idx++;
      }
      a1Idx += 3;
    }
  }

  // Workout the antenna ID
  if (itsAntId.nelements() != nAnt) {
    itsAntId.resize(nAnt);
    itsAntId = -1;
  }
  {
    DebugAssert(itsFrame.position() != 0, AipsError);
    DebugAssert(MPosition::castType
		(itsFrame.position()->getRefPtr()->getType()) == 
		MPosition::ITRF, AipsError);
    const MVPosition vlaCentrePos = 
      dynamic_cast<const MPosition*>(itsFrame.position())->getValue();

    for (uInt a = 0; a < nAnt; a++) {
      const VLAADA& ada = itsRecord.ADA(a);
      // Need to do the conversion from bx, by, bz (which is the HADEC frame)
      // to the ITRF frame prior to adding the reference position.
      // However, bx,by,bz differ from HADEC by handedness, thus
      // negate the y-component so ant positions come out right-side-out:
      // (perhaps HADEC is not the right thing to use)
      const MVBaseline thisBl(ada.bx(), -ada.by(), ada.bz());
      MVPosition thisAnt = itsBlCtr(thisBl).getValue();
      thisAnt += vlaCentrePos;
      const MPosition thisPos(thisAnt, MPosition::ITRF);
      itsAntId[a] = antenna().matchAntenna(ada.antName(), thisPos, posTol,
					   itsAntId[a]);
      if (itsAntId[a] < 0) {
	itsAntId[a] = addAntenna(thisPos, a);
	addFeed(itsAntId[a]);
	itsNewScan = True;
      }
    }
  }

  
  // For holography data, add the pointing data which is to be
  // found in the u,v parts of the ADA
  // Is this Holography data? If so, the UVWs are actually the
  // pointing offsets - U = Az, V = El
  Bool isHolo=(itsRecord.SDA().obsMode()=="H ");
  if(isHolo) {

    // We store AzEl in the pointing table. We only need to do this
    // when the table is empty
    MSPointingColumns& pointingCol = pointing();
    if(pointingCol.nrow()==0) {
      pointingCol.directionMeasCol().setDescRefCode(MDirection::AZEL);
    }

    const MVDirection fieldDirVal(itsRecord.SDA().sourceDir());
    const MDirection::Types fieldDirRef(itsRecord.SDA().epoch());
    MDirection fieldDir(fieldDirVal, fieldDirRef);

    // For the actual direction, we put (Az,El) = (0,0). For the
    // target, we put the actual Ra, Dec. The uv data (in ns!) is
    // really the pointing offset in radians.
    for (uInt a = 0; a < nAnt; a++) {
      if(itsAntId[a]>-1) {
	const VLAADA& ada = itsRecord.ADA(a);
	MDirection thisDir(MVDirection(0.0, 0.0), MDirection::AZEL);
	thisDir.shift(-ada.u()/ns2m, ada.v()/ns2m, True);
	addPointing(thisDir, fieldDir, itsAntId[a]);
      }
    }
  }

  // Now create a bunch of blocks that are necessary for reindexing the data
  // from different correlator blocks into the appropriate rows of the MS.
  Block<Block<VLAEnum::CDA> > CDAId; // Maps the local spectral ID to CDA's
                                     // ie., CDAId[0:nSpID][0:nCDA] = whichCDA
  Block<Block<uInt> > polId(maxCDA); // contains the polarisation index for 
                                     // each CDA
                                     // ie., polId[0:4][0:nPols] = polIdx;

  Block<Block<uInt> > polTypes(maxCDA);
  Block<Block<uInt> > polNewOrder;
  Vector<Bool> rotStokesOrder;


  for (uInt c = 0; c < maxCDA; c++) {
    const VLACDA& cda = itsRecord.CDA(c);
    if (!cda.isValid()) {
      itsSpId[c] = -1;
    } else {
      const VLAEnum::CDA thisCDA = VLAEnum::CDA(c);
      // Firstly, determine the spectral characteristics of the
      // data in the current CDA
      const uInt nChan = sda.nChannels(thisCDA);
      const Unit hz("Hz");
      const Double chanWidth = sda.channelWidth(thisCDA);
      const Quantum<Double> bandwidth(nChan*chanWidth, hz);
      // The tolerance is set at 1/4 of a channel. It is not set smaller
      // because when Doppler tracking is used the total bandwidth, when
      // converted to the rest type, will be slightly different from the
      // topocentric value. // above is the original comments.
		// We reset the default tolerance for frequency to be the value of the
		// channel width and also give user the ability to pass in a tolerance
		// for frequency into vlafillerfromdisk(). For dataset G192 we need a 
		// tolerance of 6 times of the channe width. For dataset NGC7538, one
		// has to give a tolerance as larger as 60 times its channel width ( 60000000Hz ).
      
		if( itsFreqTolerance == 0.0 ) itsFreqTolerance = chanWidth;
		const Quantum<Double> tolerance( itsFreqTolerance, hz);
      // Determine the reference frequency.
      MFrequency refFreq;
      {
 	if (sda.dopplerTracking(thisCDA)) {
	  const MDoppler dop(Quantity(sda.radialVelocity(thisCDA), "m/s"),
			     sda.dopplerDefn(thisCDA));
	  refFreq =
	    MFrequency::fromDoppler(dop,
	 			    MVFrequency(sda.restFrequency(thisCDA)), 
	 			    sda.restFrame(thisCDA));
	} else {
	  refFreq = MFrequency(MVFrequency(sda.obsFrequency(thisCDA)),
			       MFrequency::TOPO);
	}
      }
      // The local spectral Id is the value that is either zero or one and
      // depends on which IF the data in the CDA came from. Be aware that data
      // from IF B may have a local spectral Id value of either zero or one,
      // depending on whether IF A is also being used.
      uInt localSpId;
      // See if there is a matching row.
      {
	const uInt nSpId = CDAId.nelements();
 	const uInt ifChain = sda.electronicPath(thisCDA);
	// set MeasFrame to MeasRef of MFrequency, which is need when converting MFrequency
	// a different frame. 
	// refFreq.getRef().set( itsFrame );
	// no, ScalarMeasColumn<M>put() will not accept this! so instead, we do
   // Find the channel frequencies and pass the first one to matchSpw().
	Vector<Double> chanFreqs(nChan);
   indgen(chanFreqs, sda.edgeFrequency( thisCDA )+0.5*chanWidth, chanWidth);
	const MFrequency::Types itsFreqType = MFrequency::castType(refFreq.getRef().getType());
	if (itsFreqType != MFrequency::TOPO) { 
    // have to convert the channel frequencies from topocentric to the specifed
    // frequency type.
	    MFrequency::Convert freqCnvtr;
	    freqCnvtr.setModel( MFrequency(MVFrequency(), MFrequency::Ref( MFrequency::TOPO, itsFrame )) );
	    freqCnvtr.setOut( itsFreqType );
       Double freqInHzCnvtrd = freqCnvtr(chanFreqs(0)).getValue().getValue();
		 chanFreqs( 0 ) = freqInHzCnvtrd;
    }
   MFrequency chanFreq1 = MFrequency( MVFrequency( chanFreqs( 0 ) ), itsFreqType );
	// now call the matchSpw() method:
 	itsSpId[c] = spectralWindow().matchSpw(refFreq, chanFreq1, itsFrame, doppler(), source(), nChan, bandwidth,
					       ifChain, tolerance, itsSpId[c]);
 	if (itsSpId[c] < 0) {
	  // add an entry to Dopper subtable before addSpectralWindow! Also make sure addSouce is called before this!
	  uInt dopplerId = addDoppler( thisCDA );
  	  itsSpId[c] = addSpectralWindow(thisCDA, refFreq, nChan,
  					 bandwidth.getValue(hz), ifChain);
	  localSpId = nSpId;
 	} else {
	  localSpId = 0;
	  while (localSpId < nSpId && 
		 CDAId[localSpId].nelements() > 0 && 
		 itsSpId[CDAId[localSpId][0]] != itsSpId[c]) {
	    localSpId++;
	  }
	}
	if (localSpId == nSpId) {
	  CDAId.resize(nSpId + 1);
	}
      }
      // Put this CDA into its spot the indexing blocks.
      const uInt nCDA = CDAId[localSpId].nelements();
      CDAId[localSpId].resize(nCDA + 1);
      CDAId[localSpId][nCDA] = thisCDA;
      uInt polIdx = 0;
      if (nCDA != 0) { // Here is a tricky section for you. 
	               // The debugging statements should help
  	const Block<uInt>& prevPolId =  polId[CDAId[localSpId][nCDA-1]];
  	polIdx = prevPolId[prevPolId.nelements()-1] + 1;

#if defined(AIPS_DEBUG)
	itsLog << LogIO::DEBUGGING;
   	itsLog << "CDA's containing this spectral ID: [";
 	for (uInt c = 0; c < CDAId[localSpId].nelements(); c++) {
 	  itsLog << static_cast<Int>(CDAId[localSpId][c])
		 << ((c+1 < CDAId[localSpId].nelements()) ? ", " : "]\n");
 	}
   	itsLog << "The previous CDA containing this spectral ID: " 
  	       << static_cast<Int>(CDAId[localSpId][nCDA-1]) << endl;
    	itsLog << "The polarisation map of this CDA: [" ;
	{
	  const uInt w = CDAId[localSpId][nCDA-1];
	  for (uInt c = 0; c < polId[w].nelements(); c++) {
	    itsLog << polId[w][c]
		   << ((c+1 < polId[w].nelements()) ? ", " : "]\n");
	  }
	}
   	itsLog << "The last element of the polarisation map: " 
  	       << prevPolId.nelements()-1 << endl;
   	itsLog << "The next polarisation starts at index: " 
  	       <<  polIdx << endl;
	itsLog << LogIO::POST << LogIO::NORMAL;
#endif
      }
      const uInt nPols = sda.npol(thisCDA);
      polId[c].resize(nPols);
      for (uInt p = 0; p < nPols; p++) {
  	polId[c][p] = p + polIdx;
      }
    }
  }
  const uInt nSpId = CDAId.nelements();
  if (nSpId == 0) {
    // This can occur if there is a single antenna subarray doing VLBI. This
    // antenna may not be connected to the VLA correlator and hence the
    // auto-correlation cannot be calculated. In this case all the CDA's are
    // invalid and there is no data to add to the main table of the MS.
    DebugAssert(nAnt == 1, AipsError);
    return True; 
  }

  // Check if the transfer switch is only set on some antennas. If so warn
  // the user that the polarisation may be misslabeled
  {
    const Stokes::StokesTypes ant0Pol = itsRecord.ADA(0).ifPol(VLAEnum::IFA);
    for (uInt a = 1; a < nAnt; a++) {
      if (itsRecord.ADA(a).ifPol(VLAEnum::IFA) != ant0Pol) {
 	itsLog << LogIO::WARN
 	       << "The IF transfer switch for antenna " 
 	       << itsRecord.ADA(a).antName()
	       << " is different from the setting for antenna " 
	       << itsRecord.ADA(0).antName() << "." << endl
	       << "Correlations involving this antenna may have "
	       << "incorrect polarisation labelling." 
	       << LogIO::POST;
      }
    }
  }

  // Now sort out the polarisation subtable
  if (nSpId != itsPolId.nelements()) {
    itsPolId.resize(nSpId, True);
    itsPolId = -1;
  }
  polTypes.resize(nSpId);
  polNewOrder.resize(nSpId);
  rotStokesOrder.resize(nSpId);
  rotStokesOrder.set(False);
  for (uInt s = 0; s < nSpId; s++) {
    const Block<VLAEnum::CDA>& usedCDAs = CDAId[s];
    const uInt nCda = usedCDAs.nelements();
    uInt nPol = 0;
    for (uInt i = 0; i < nCda; i++) {
      nPol += polId[usedCDAs[i]].nelements();
    }
    
    Vector<Stokes::StokesTypes> allPols(nPol);
    uInt p = 0;
    for (uInt i = 0; i < nCda; i++) {
      Vector<Stokes::StokesTypes> pol(itsRecord.polarisations(usedCDAs[i]));
      for (uInt j = 0; j < pol.nelements(); j++, p++) {
 	allPols(p) = pol(j);
      }
    }
    polTypes[s].resize(allPols.nelements());
    polNewOrder[s].resize(allPols.nelements());
    
    Bool standard=True;
    for (uInt i=0; i < allPols.nelements(); ++i){
      polTypes[s][i]=static_cast<uInt> (allPols[i]);
      polNewOrder[s][i]=i;
      if( (allPols[i] > Stokes::LL) || (allPols[i] < Stokes::RR)){
	standard=False;
      }
    }
    //Now if the 4-stokes are not in RR RL LR LL order....make sure it is
    if((allPols.nelements() == 4) && standard ){
      if(allPols[0] != Stokes::RR){
	rotStokesOrder[s]=True;
	polNewOrder[s][0]=polIndexer(allPols[0]);
      }
      if(allPols[1] != Stokes::RL){
	rotStokesOrder[s]=True;
	polNewOrder[s][1]=polIndexer(allPols[1]);
      }	
      if(allPols[2] != Stokes::LR){
	rotStokesOrder[s]=True;
	polNewOrder[s][2]=polIndexer(allPols[2]);
      }
      if(allPols[3] != Stokes::LL){
	rotStokesOrder[s]=True;
	polNewOrder[s][3]=polIndexer(allPols[3]);
      }

      allPols[0]=Stokes::RR; 
      allPols[1]=Stokes::RL;
      allPols[2]=Stokes::LR; 
      allPols[3]=Stokes::LL;
    }
    itsPolId[s] = polarization().match(allPols, itsPolId[s]);
    if (itsPolId[s] < 0) {
      itsPolId[s] = addPolarization(allPols);
    }
  }

  // Keep these values handy, as they are needed in lots of places
  Block<uInt> nChannels(nSpId);
  Block<uInt> nProducts(nSpId);
  for (uInt s = 0; s < nSpId; s++) {
    nProducts[s] = polarization().numCorr()(itsPolId[s]);
    nChannels[s] = spectralWindow().numChan()(itsSpId[CDAId[s][0]]);
  }

  Block<Int>& thisDataId = itsDataId[subArray];
  // Now sort out the data description subtable
  if (nSpId != thisDataId.nelements()) {
    thisDataId.resize(nSpId, True);
    thisDataId = -1;
  }
  for (uInt s = 0; s < nSpId; s++) {
    const uInt spwId = itsSpId[CDAId[s][0]];
    Int newId = dataDescription().match(spwId, itsPolId[s], thisDataId[s]);
    if (newId < 0) {
      newId = addDataDescription(spwId, static_cast<uInt>(itsPolId[s]));
      // this is a good place to add a hypercube as a new row in the Data
      // Description subtable may specify a different data shape
      addHypercubes(nProducts[s], nChannels[s]);
    }
    if (newId != thisDataId[s]) {
      thisDataId[s] = newId;
      itsNewScan = True;
    }
  }



# if defined(AIPS_DEBUG)
  itsLog << LogIO::DEBUGGING;
  itsLog << CDAId.nelements() << " spectral ID's in this record "
	 << "(correlator mode '" << VLAEnum::name(sda. correlatorMode()) 
	 << "')" << endl;
  for (uInt s = 0; s < CDAId.nelements(); s++) {
    itsLog << "  Id: " << itsSpId[CDAId[s][0]] << " is in CDA's [";
    for (uInt i = 0; i < CDAId[s].nelements(); i++) {
      itsLog << static_cast<Int>(CDAId[s][i])+1
	     << ((i+1 < CDAId[s].nelements()) ? ", " : "]\n");
    }
    for (uInt cda = 0; cda < CDAId[s].nelements(); cda++) {
      itsLog << "    CDA: " << static_cast<Int>(CDAId[s][cda]) + 1 
	     << " contains " << polId[CDAId[s][cda]].nelements() 
	     << " polarisations [";
      for (uInt i = 0; i < polId[CDAId[s][cda]].nelements(); i++) {
	itsLog << polId[CDAId[s][cda]][i]
	       << ((i+1 < polId[CDAId[s][cda]].nelements()) ? ", " : "] (");
      }
      Vector<Stokes::StokesTypes> pol(itsRecord.polarisations(CDAId[s][cda]));
      for (uInt i = 0; i < pol.nelements(); i++) {
	itsLog << Stokes::name(pol(i))
	       << ((i+1 < pol.nelements()) ? ", " : ")\n");
      }
    }
  }
  itsLog << LogIO::POST << LogIO::NORMAL;
#endif
  // decide if this is a new scan
  if (itsNewScan) {
    itsNewScan = False;
    Int nextScan = itsScan[0];
    for (uInt i = 1; i < maxSubarrays; i++) {
      nextScan = max(nextScan, itsScan[i]);
    }
    itsScan[subArray] = nextScan + 1;
    // flush any data to disk. This gives the user the opportunity to examine
    // the MS while it is being filled. Doing it more frequently than once per
    // scan starts to eat into the performance when filling from disk.
    itsMS.flush(); 
  }
  // add empty rows
  const uInt nCorr = (nAnt*(nAnt-1))/2;
  uInt row = itsMS.nrow();
  const uInt rowsPerSpId = nCorr+nAnt;
  const uInt newRows = rowsPerSpId*nSpId;
  itsMS.addRow(newRows);
  extendHypercubes(nProducts, nChannels, rowsPerSpId);
  // Some variables needed in assorted places from now on.
  Vector<Int> vecInt(newRows);
  const Double intTime = sda.intTime();
  { // fill the columns where all the rows are identical and independent of the
    // data description id
    const RefRows rows(row, row+newRows-1);
    vecInt = itsScan[subArray];
    scanNumber().putColumnCells(rows, vecInt);
    vecInt = itsFldId[subArray];
    fieldId().putColumnCells(rows, vecInt);
    vecInt = subArray;
    arrayId().putColumnCells(rows, vecInt);
    vecInt = itsMS.observation().nrow();
    observationId().putColumnCells(rows, vecInt);
    vecInt = 0;
    feed1().putColumnCells(rows, vecInt);
    feed2().putColumnCells(rows, vecInt);
    vecInt = -1;
    stateId().putColumnCells(rows, vecInt);
    processorId().putColumnCells(rows, vecInt);
    Vector<Double> vecDbl(newRows, intTime);
    exposure().putColumnCells(rows, vecDbl);
    interval().putColumnCells(rows, vecDbl);
    const MEpoch* mep = dynamic_cast<const MEpoch*>(itsFrame.epoch());
    AlwaysAssert( mep != 0, AipsError);
    vecDbl = mep->getValue().getTime("s").getValue();
    time().putColumnCells(rows, vecDbl);
    timeCentroid().putColumnCells(rows, vecDbl);
  }

  // Construct a bunch of variables that will be used inside the data writing
  // loop
  Vector<Double> blUvw(3);
  Matrix<Complex> cData(nProducts[0], nChannels[0]);
  Matrix<Complex> modData(nProducts[0], nChannels[0]);
  Matrix<Complex> onePol;
  Matrix<Bool> flags(nProducts[0], nChannels[0]);
  Vector<Float> weights(nProducts[0]), sigmas(nProducts[0]);
  Cube<Bool> flagLevels(nProducts[0], nChannels[0], nCat);
  VLAEnum::CDA cda;
  vecInt.resize(rowsPerSpId);

  for (uInt s = 0; s < nSpId; s++) {
    const Block<VLAEnum::CDA>& usedCDAs = CDAId[s];
    const uInt nCDA = usedCDAs.nelements();
    DebugAssert(nCDA > 0, AipsError);
    const uInt nChan = nChannels[s];
    const uInt nPol = nProducts[s];
    const Double channelWidth = itsRecord.SDA().channelWidth(usedCDAs[0]);
    const Double bandwidth = channelWidth * nChan;
    
    // fill the columns where all the rows are identical and dependent on the
    // data description id
    {
      const RefRows rows(row, row+rowsPerSpId-1);
      vecInt = thisDataId[s];
      dataDescId().putColumnCells(rows, vecInt);
    }
    
    // cache the online IF flags and nominal sensitivity of each antenna. It
    // simplifies having to do it for each baseline later on.
    Block<Matrix<VLAEnum::IF> > whichIF(nCDA);
    Cube<Bool> antFlagLevels(maxIF, nAnt, 4, False);
    Matrix<Bool> antFlag(maxIF, nAnt, False);
    Matrix<Float> sens(maxIF, nAnt);
    { // First work ouk out which IF's are used by this spectral id.
      Block<Bool> usedIFs(maxIF, False);
      for (uInt c = 0; c < nCDA; c++) {
	const Matrix<VLAEnum::IF>& curIF = 
	  whichIF[c] = sda.ifUsage(usedCDAs[c]);
	const uInt nCorr = curIF.ncolumn();
	for (uInt p = 0; p < nCorr; p++) {
	  usedIFs[curIF(0, p)] = usedIFs[curIF(1, p)] = True;
	}
      }
      // For each antenna find the IF flags and sensitivity
      for (uInt a = 0; a < nAnt; a++) { // set the flag to True if data is Bad
	const VLAADA& ada = itsRecord.ADA(a);
	for (uInt i = 0; i < maxIF; i++) {
	  if (usedIFs[i]) {
	    const VLAEnum::IF thisIF = static_cast<VLAEnum::IF>(i);
	    const Float ns = ada.nominalSensitivity(thisIF);
	    sens(i, a) = (ns > 0.0f) ? ns : C::flt_epsilon; 
	    const uInt status = ada.ifStatus(thisIF);
	    if (status > 0) badData = True;
	    if ((status&0x01) != 0) antFlagLevels(i, a, 0) = True;
	    if ((status&0x02) != 0) antFlagLevels(i, a, 1) = True;
	    if ((status&0x04) != 0) antFlag(i, a)=antFlagLevels(i, a, 2)=True;
	    if ((status&0x08) != 0) antFlag(i, a)=antFlagLevels(i, a, 3)=True;
	    if(!isHolo) {
	      antFlag(i, a) |= shadowed[a];
	    }
	  }
	}
      }
    }
    
    cData.resize(nPol, nChan);
    modData.resize(nPol, nChan);
    if(nPol==4){
      modData.row(0).set(1);
      modData.row(3).set(1);
      modData.row(1).set(0);
      modData.row(2).set(0); 
    }
    else{
      modData.set(1);
    }
    weights.resize(nPol); 
    sigmas.resize(nPol); 
    flags.resize(nPol, nChan); 
    flagLevels.resize(nPol, nChan, nCat); 
    if (!badData) {
      flags = False;
      flagLevels = False;
    }
    if (nChan != 1 && nPol != 1 ) onePol.resize(1, nChan);
    const Slice allChan(0, nChan);

    // Fill in the correlations
    uInt b = 0;
    for (uInt a1 = 0; a1 < nAnt; a1++) {
      for (uInt a2 = a1; a2 < nAnt; a2++) {
 	const Bool crossCorr = (a1 == a2) ? False : True;
 	for (uInt c = 0; c < nCDA; c++) {
 	  cda = usedCDAs[c];
 	  if (nChan == 1 || nPol == 1) {
 	    if (crossCorr) {
 	      itsRecord.CDA(cda).crossCorr(b).data(cData);
 	    } else {
	      itsRecord.CDA(cda).autoCorr(a1).data(cData);
 	    }
	    if(nPol==4 && rotStokesOrder[s]){
              Vector<Complex> olddata(4);
	      olddata=cData.column(0);
	      for (uInt kk=0; kk < 4; ++kk){
		cData.column(0)(polNewOrder[s][kk])=olddata[kk];
	      } 
	    }
 	  } else {
 	    DebugAssert(polId[cda].nelements() == 1, AipsError);
 	    if (crossCorr) {
	      itsRecord.CDA(cda).crossCorr(b).data(onePol);
 	    } else {
 	      itsRecord.CDA(cda).autoCorr(a1).data(onePol);
 	    } 
	    const Slice curPol(polNewOrder[s][polId[cda][0]], 1);
 	    cData(curPol, allChan) = onePol;
 	  }
	  const Matrix<VLAEnum::IF>& curIF = whichIF[c];
	  if (nChan == 1) { // Continuum
	    DebugAssert(curIF.ncolumn() == 4, AipsError);
	    DebugAssert(polId[cda][0] == 0, AipsError);
	    for (uInt p = 0; p < 4; p++) {
	      const VLAEnum::IF if0 = curIF(0, p);
	      const VLAEnum::IF if1 = curIF(1, p);
	      const Double w = intTime/(sens(if0, a1) * sens(if1, a2)) 
		* .12/10000.;
	      // The fudge factor of .12/10000 is to make the VLA filler
	      // consistent with AIPS. It is discussed in the .help file.
	      weights(p) = w * bandwidth;
	      sigmas(p) = 1.0/ sqrt(w * channelWidth);
	      if (badData) {
		flags(p, 0) = antFlag(if0, a1) || antFlag(if1, a2);
		for (uInt l = 0; l < 4; l++) {
		  flagLevels(p, 0, l) = 
		    antFlagLevels(if0, a1, l) || antFlagLevels(if1, a2, l);
		}
		// Don't flag holography data for apparent shadowing
		// since we don't actually know if the data is
		// shadowed
		if(isHolo) {
		  flagLevels(p, 0, 4) = False;
		}
		else {
		  flagLevels(p, 0, 4) = shadowed[a1] || shadowed[a2];
		}
		flagLevels(p, 0, 5) = False;
	      }
	    }
	  } else {// spectral line
	    DebugAssert(curIF.ncolumn() == 1, AipsError);
	    const VLAEnum::IF if0 = curIF(0, 0);
	    const VLAEnum::IF if1 = curIF(1, 0);
	    const uInt startPol = polId[cda][0];
	      const Double w = intTime/(sens(if0, a1) * sens(if1, a2)) 
		* .12/10000.;
	    // The fudge factor of .12/10000 is to make the VLA filler
	    // consitant with AIPS. It is discussed in the .help file.
	    weights(startPol) = w * bandwidth;
	    sigmas(startPol) = 1.0/sqrt(w * channelWidth);
	    if (badData) {
	      const Slice curPol(startPol, 1);
	      flags(curPol, allChan) = antFlag(if0, a1) || antFlag(if1, a2);
	      for (uInt l = 0; l < 4; l++) {
		flagLevels(curPol, allChan, l) = 
		  antFlagLevels(if0, a1, l) || antFlagLevels(if1, a2, l);
	      }
	      if(isHolo) {
		flagLevels(curPol, allChan, 4) = False;
	      }
	      else {
		flagLevels(curPol, allChan, 4) = shadowed[a1] || shadowed[a2];
	      }
	      flagLevels(curPol, allChan, 5) = False;
	    }
	  }
	}
	weight().put(row, weights);
	sigma().put(row, sigmas);
 	flag().put(row, flags);
	flagCategory().put(row, flagLevels);
	if (badData) {
 	  flagRow().put(row, allEQ(flags, True));
	} else {
 	  flagRow().put(row, False);
	}
	// Some aips++ tools, in particular calibrator, require that the index
	// in ANTENNA1 be less than or equal to the index in the ANTENNA2
	// column. To accommodate this they are swapped here.
	uInt ant1 = a1;
	uInt ant2 = a2;
	if (itsAntId[a1] > itsAntId[a2]) {
	  cData = conj(cData);
	  ant1 = a2;
	  ant2 = a1;
	}  
	data().put(row, cData);
	correctedData().put(row,cData);
	modelData().put(row, modData);
	Vector<Float> imagingWgt(nChan, weights(0)/nChan);
	imagingWeight().put(row, imagingWgt);
 	uInt a1Index = ant1*3, a2Index = ant2*3;
	if(isHolo) {
	  blUvw=0.0;
	}
	else {
	  blUvw(0) = antUvw[a1Index] - antUvw[a2Index]; a1Index++; a2Index++;
	  blUvw(1) = antUvw[a1Index] - antUvw[a2Index]; a1Index++; a2Index++;
	  blUvw(2) = antUvw[a1Index] - antUvw[a2Index];
	}
	uvw().put(row, blUvw);
	antenna1().put(row, itsAntId[ant1]);
	antenna2().put(row, itsAntId[ant2]);
	row++;
	if (crossCorr) b++;
      }
    }
  }
  return True;
}

MeasurementSet VLAFiller::
getMS(const Path& tableName, const Bool overwrite) {
  if (overwrite == False && File(tableName).exists()) {
    return openMS(tableName);
  } else {
    return emptyMS(tableName, overwrite);
  }
}

MeasurementSet VLAFiller::
emptyMS(const Path& tableName, const Bool overwrite) {
  AlwaysAssert(tableName.isValid(), AipsError);
  AlwaysAssert(File(tableName.dirName()).isWritable(), AipsError);

  // Add all the required columns
  TableDesc msDesc = MeasurementSet::requiredTableDesc();
  // Add the data column (as it is an an optional one)
  MeasurementSet::addColumnToDesc(msDesc, MeasurementSet::DATA, 2);
  //Scratch columns
  MeasurementSet::addColumnToDesc(msDesc, MeasurementSet::MODEL_DATA, 2);
  MeasurementSet::addColumnToDesc(msDesc, MeasurementSet::CORRECTED_DATA, 2);
  MeasurementSet::addColumnToDesc(msDesc, MeasurementSet::IMAGING_WEIGHT, 1);

  // Add the tiled id column indices
  msDesc.addColumn(ScalarColumnDesc<Int>(dataTileId.fieldName(),
				     "Index for Data tiling"));
  msDesc.addColumn(ScalarColumnDesc<Int>(sigmaTileId.fieldName(),
				     "Index for Sigma tiling"));
  msDesc.addColumn(ScalarColumnDesc<Int>(flagTileId.fieldName(),
				     "Index for Flag Category tiling"));
  
  msDesc.addColumn(ScalarColumnDesc<Int>(imagingWeightTileId.fieldName(),
					 "Index for imaging weight  tiling"));

  msDesc.addColumn(ScalarColumnDesc<Int>(modDataTileId.fieldName(),
				     "Index for Model Data tiling"));
  msDesc.addColumn(ScalarColumnDesc<Int>(corrDataTileId.fieldName(),
				     "Index for Corrected Data tiling"));
  msDesc.addColumn(ScalarColumnDesc<Int>(chanFlagTileId.fieldName(),
				     "Index for Flag  tiling"));

  // setup hypercolumns for the data/flag/flag_catagory/sigma & weight columns.
  {
    Vector<String> dataCols(1);
    dataCols(0) = MeasurementSet::columnName(MeasurementSet::DATA);
    const Vector<String> coordCols(0);
    const Vector<String> idCols(1, dataTileId.fieldName());
    msDesc.defineHypercolumn(dataCol, 3, dataCols, coordCols, idCols);
  }
  {
    Vector<String> dataCols(1);
    dataCols(0) = MeasurementSet::columnName(MeasurementSet::MODEL_DATA);
    const Vector<String> coordCols(0);
    const Vector<String> idCols(1, modDataTileId.fieldName());
    msDesc.defineHypercolumn(modDataCol, 3, dataCols, coordCols, idCols);
  }
  {
    Vector<String> dataCols(1);
    dataCols(0) = MeasurementSet::columnName(MeasurementSet::CORRECTED_DATA);
    const Vector<String> coordCols(0);
    const Vector<String> idCols(1, corrDataTileId.fieldName());
    msDesc.defineHypercolumn(corrDataCol, 3, dataCols, coordCols, idCols);
  }
  {
    Vector<String> dataCols(1);
    dataCols(0) = MeasurementSet::columnName(MeasurementSet::FLAG);
    const Vector<String> coordCols(0);
    const Vector<String> idCols(1, chanFlagTileId.fieldName());
    msDesc.defineHypercolumn(chanFlagCol, 3, dataCols, coordCols, idCols);
  }
  {
    Vector<String> dataCols(2);
    dataCols(0) = MeasurementSet::columnName(MeasurementSet::SIGMA);
    dataCols(1) = MeasurementSet::columnName(MeasurementSet::WEIGHT);
    const Vector<String> coordCols(0);
    const Vector<String> idCols(1, sigmaTileId.fieldName());
    msDesc.defineHypercolumn(sigmaCol, 2, dataCols, coordCols, idCols);
  }
  {
    const Vector<String> dataCols
      (1, MeasurementSet::columnName(MeasurementSet::FLAG_CATEGORY));
    const Vector<String> coordCols(0);
    const Vector<String> idCols(1, flagTileId.fieldName());
    msDesc.defineHypercolumn(flagCol, 4, dataCols, coordCols, idCols);
  }
  
  {
    const Vector<String> dataCols
      (1, MeasurementSet::columnName(MeasurementSet::IMAGING_WEIGHT));
    const Vector<String> coordCols(0);
    const Vector<String> idCols(1, imagingWeightTileId.fieldName());
    msDesc.defineHypercolumn(imagingWeightCol, 2, dataCols, coordCols, idCols);
  }
  
  Table::TableOption option = Table::NewNoReplace;
  if (overwrite) option = Table::New;
  SetupNewTable newMS(tableName.originalName(), msDesc, option);

  // setup storage managers. Use the incremental storage manager for
  // columns where the data is likely to be the same for more than four
  // rows at a time.
  {
    IncrementalStMan incrMan("Incremental data manager");
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::ARRAY_ID), incrMan);
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
  }
  // These columns contain the bulk of the data so save them in a tiled way
  {
    TiledDataStMan dataMan(dataCol);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::DATA), dataMan);
    newMS.bindColumn(dataTileId.fieldName(), dataMan);
  }
  {
    TiledDataStMan dataMan(modDataCol);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::MODEL_DATA), dataMan);
    newMS.bindColumn(modDataTileId.fieldName(), dataMan);
  }
  {
    TiledDataStMan dataMan(corrDataCol);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::CORRECTED_DATA), dataMan);
    newMS.bindColumn(corrDataTileId.fieldName(), dataMan);
  }
  {
    TiledDataStMan dataMan(chanFlagCol);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::FLAG), dataMan);
    newMS.bindColumn(chanFlagTileId.fieldName(), dataMan);
  }
  {
    TiledDataStMan dataMan(sigmaCol);
    newMS.bindColumn(MeasurementSet::
 		     columnName(MeasurementSet::SIGMA), dataMan);
    newMS.bindColumn(MeasurementSet::
 		     columnName(MeasurementSet::WEIGHT), dataMan);
    newMS.bindColumn(sigmaTileId.fieldName(), dataMan);
  }
  
  {
    TiledDataStMan dataMan(imagingWeightCol);

    newMS.bindColumn(MeasurementSet::
 		     columnName(MeasurementSet::IMAGING_WEIGHT), dataMan);

    newMS.bindColumn(imagingWeightTileId.fieldName(), dataMan);
  }
  
  {
    TiledDataStMan dataMan(flagCol);
    newMS.bindColumn(MeasurementSet::
   		     columnName(MeasurementSet::FLAG_CATEGORY), dataMan);
    newMS.bindColumn(flagTileId.fieldName(), dataMan);
  }

  {
    TiledColumnStMan tiledStUVW("TiledUVW",IPosition(2,3,378));
    newMS.bindColumn(MS::columnName(MS::UVW),tiledStUVW);
  }
  // The standard storage manager is the default manager but by default it only
  // creates a bucket for every 32 rows. Thats too small for the columns in the
  // main table of a measurement set. So I'll explicitly bind these columns
  // here with a bucket size of (351+27)*128 bytes
  {
    StandardStMan stMan("Standard data manager", 32768);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::ANTENNA1), stMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::ANTENNA2), stMan);
    newMS.bindColumn(MeasurementSet::
		     columnName(MeasurementSet::DATA_DESC_ID), stMan);
  }

  // Finally create the MeasurementSet.
  MeasurementSet ms(newMS);
  
  { // Set the TableInfo
    TableInfo& info(ms.tableInfo());
    info.setType(TableInfo::type(TableInfo::MEASUREMENTSET));
    info.setSubType(String("VLA"));
    info.readmeAddLine
      ("This is a MeasurementSet Table holding measurements from the VLA");
    info.readmeAddLine("radio synthesis array (operated by NRAO)");
  }
  {//Create the SOURCE subtable

    TableDesc sourceTD=MSSource::requiredTableDesc();
    MSSource::addColumnToDesc(sourceTD, MSSource::REST_FREQUENCY);
    MSSource::addColumnToDesc(sourceTD, MSSource::SYSVEL);
    MSSource::addColumnToDesc(sourceTD, MSSource::TRANSITION);
    SetupNewTable sourceSetup(ms.sourceTableName(),sourceTD,option);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::SOURCE),
				  Table(sourceSetup,0));
  }
  // create  the required subtables.
  ms.createDefaultSubtables(option);
  //
  { // add optional column to SPECTRAL_WINDOW. Added by GYL
      ms.spectralWindow().addColumn(
            ScalarColumnDesc<Int>(
                MSSpectralWindow::columnName(MSSpectralWindow::DOPPLER_ID),
                MSSpectralWindow::columnStandardComment(
                    MSSpectralWindow::DOPPLER_ID)));
  
  }
  {  // Create the DOPPLER subtable. Added by GYL
    TableDesc dopplerTD=MSDoppler::requiredTableDesc();
    //MSDoppler::addColumnToDesc(dopplerTD, MSDoppler::VELDEF);
    SetupNewTable dopplerSetup(ms.dopplerTableName(),dopplerTD,option);
    ms.rwKeywordSet().defineTable(MS::keywordName(MS::DOPPLER),
				  Table(dopplerSetup,0));
  }

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

MeasurementSet VLAFiller::
openMS(const Path& tableName, const Bool readonly) {
  const String& msName = tableName.absoluteName();
  if (!Table::isReadable(msName)) {
    throw(AipsError(String("VLAFiller::openMS(...) - cannot read ") + msName +
 		    String(" because it does not exist or is not a table.")));
  }
  if (!readonly && !Table::isWritable(msName)) {
    throw(AipsError(String("VLAFiller::openMS(...) - cannot write to ") + 
 		    msName + "."));
  }
  {
    const TableInfo info = Table::tableInfo(msName);
    if (info.type() != TableInfo::type(TableInfo::MEASUREMENTSET)) {
      throw(AipsError(String("VLAFiller::openMS(...) - the table ") + 
 		      msName + String(" is not a measurement set.")));
    }
    if (info.subType() != "VLA") {
      throw(AipsError(String("VLAFiller::openMS(...) - the table ") + 
 		      msName + String(" is not a VLA measurement set.")));
    }
    {
      const Table t(msName);
      const TableRecord& keys = t.keywordSet();
      const String versionString("MS_VERSION");
      const RecordFieldId versionKey(versionString);
      if (!keys.isDefined(versionString) || 
	  keys.dataType(versionKey) != TpFloat || 
	  !near(keys.asFloat(versionKey), 2.0f)) {
	throw(AipsError(String("VLAFiller::openMS(...) - the table ") + 
			msName + 
			String(" is not a version 2 measurement set.")));
      }
    }
  }
  const Table::TableOption openOption = readonly ? Table::Old : Table::Update;
  return MeasurementSet(msName, openOption);
}

void VLAFiller::logCurrentRecord(IterationStatus& counts) {
  if (itsRecord.isValid()) {
    const uInt curRow = nrow();
    const MEpoch obsTime = timeMeas()(curRow-1);
    itsLog << "Record " << counts.nVLARecords 
	   << " was observed at "
	   << MVTime(obsTime.getValue().getTime()).string(MVTime::YMD)
	   << " and has " << curRow - counts.nRows 
	   << " rows of data" << LogIO::POST;
  }
}

void VLAFiller::logChanges(IterationStatus& counts) {
  {
    const String& curProject = itsRecord.SDA().obsId();
    if (counts.lastProject != curProject) {
      counts.lastProject = curProject;
      itsLog << "Project changed to " << curProject << LogIO::POST;
    }
  }
  {
    const String& curObsMode = itsRecord.SDA().obsMode();
    if (counts.lastObsMode != curObsMode) {
      counts.lastObsMode = curObsMode;
      itsLog << "ObsMode changed to " << itsRecord.SDA().obsModeFull()
	     << LogIO::POST;
    }
  }
  const Int subArray = arrayId()(nrow() - 1);
  {
    const ROMSAntennaColumns& ant = antenna();
    const uInt nAnt = itsRecord.RCA().nAntennas();
    Bool changed = (nAnt != counts.lastAnt[subArray].nelements());
    {
      Int a = nAnt;
      while (!changed && a > 0) {
	a--;
	changed = (itsAntId[a] != static_cast<Int>(counts.lastAnt[subArray][a]));
      }
    }
    if (changed) {
      itsLog << "Array configuration";
      itsLog << " for sub-array " << subArray + 1;
      if (counts.lastAnt[subArray].nelements() != 0) itsLog << " changed";
      const uInt lastRow = nrow() - 1;
      const MEpoch obsTime = timeMeas()(lastRow);
      itsLog << " at " 
	     << MVTime(obsTime.getValue().getTime()).string(MVTime::YMD)
 	     << " (" << obsTime.getRefString() << ")"
	     << LogIO::POST;
      counts.lastAnt[subArray].resize(nAnt, True);
      for (uInt i = 0; i < nAnt; i++) {
	const uInt a = static_cast<uInt>(itsAntId[i]);
	itsLog << "Station: " << ant.station()(a)
	       << " \tAntenna: " << ant.name()(a);
// 	if (counts.lastAnt[subArray][i] != a) {
// 	  itsLog << " \tNEW";
// 	}
	counts.lastAnt[subArray][i] = a;
	itsLog << LogIO::POST;
      }
    }
    itsLog << LogIO::POST;
  }
  {
    const ROMSDataDescColumns& dd = dataDescription();
    const ROMSSpWindowColumns& spw = spectralWindow();
    const ROMSPolarizationColumns& pol = polarization();
    const Block<Int>& thisDataId = itsDataId[subArray];
    Block<Int>& lastSpw = counts.lastSpw[subArray];
    Block<Int>& lastPol = counts.lastPol[subArray];
    for (uInt d = 0; d < lastSpw.nelements(); d++) {
      if (d < thisDataId.nelements()) {
	const Int curDD = thisDataId[d];
	const Int curSpw = dd.spectralWindowId()(curDD);
	if (lastSpw[d] != curSpw) {
	  lastSpw[d] = curSpw;
	  itsLog << "Spectral window for IF#" 
		 << spw.ifConvChain()(curSpw) + 1
		 << " (on sub-array " << subArray + 1 << ")"
		 << " changed to "
		 << spw.name()(curSpw);
	  const MEpoch obsTime = timeMeas()(nrow()-1);
	  itsLog << " at " 
		 << MVTime(obsTime.getValue().getTime()).string(MVTime::YMD)
		 << " (" << obsTime.getRefString() << ")";
	  if (counts.nSpw != spw.nrow() &&
	      static_cast<uInt>(curSpw) >= counts.nSpw) {
	    counts.nSpw =  curSpw + 1;
	    itsLog << " NEW";
	  }
	  itsLog << LogIO::POST;
	}
	const Int curPol = dd.polarizationId()(curDD);
	if (lastPol[d] != curPol) {
	  lastPol[d] = curPol;
	  itsLog << "Polarization setup for IF#" 
		 << spw.ifConvChain()(curSpw) + 1
		 << " (on sub-array " << subArray + 1 << ")"
		 << " changed to ";
	  const Vector<Int> corr = pol.corrType()(curPol);
	  const Int nCorr = corr.nelements();
	  for (Int c = 0; c < nCorr - 1; c++) {
	    itsLog << Stokes::name(Stokes::type(corr(c))) << ", ";
	  }
	  itsLog << Stokes::name(Stokes::type(corr(nCorr-1)));
	  const MEpoch obsTime = timeMeas()(nrow()-1);
	  itsLog << " at " 
		 << MVTime(obsTime.getValue().getTime()).string(MVTime::YMD)
		 << " (" << obsTime.getRefString() << ")";
	  if (counts.nPol != pol.nrow() &&
	      static_cast<uInt>(curPol) >= counts.nPol) {
	    counts.nPol =  curPol + 1;
	    itsLog << " NEW";
	  }
	  itsLog << LogIO::POST;
	}
      } else {
	lastSpw[d] = -1;
	lastPol[d] = -1;
      }
    }
  }
  {
    const ROMSFieldColumns& fld = field();
    const Int thisFld = itsFldId[subArray];
    if (counts.lastFld[subArray] != thisFld) {
      counts.lastFld[subArray] = thisFld;
      itsLog << "Field changed to ";
      { 
	const String& fldName = fld.name()(thisFld);
 	if (fldName.length() > 0) {
	  itsLog << fldName;
	} else {
	  Array<MDirection> amd;
	  const Unit rad("rad");
	  fld.referenceDirMeasCol().get(thisFld, amd, True);
	  const MDirection& md = amd(IPosition(amd.ndim(), 0));
	  const MVDirection& mdv = md.getValue();
	  const MVTime ra(mdv.getLong(rad));
	  const MVAngle dec(mdv.getLat(rad));
	  itsLog << "(" << ra.string(MVTime::TIME, 6) << ", " 
		 << dec.string(MVTime::ANGLE, 6) << ")";
	  itsLog << " " << md.getRefString();
	}
      }
      const uInt lastRow = nrow() - 1;
      const MEpoch obsTime = timeMeas()(lastRow);
      itsLog << " (on sub-array " << subArray+1 << ") at " 
	     << MVTime(obsTime.getValue().getTime()).string(MVTime::YMD)
	     << " (" << obsTime.getRefString() << ")";
      if (counts.nFld != fld.nrow() && 
	  static_cast<uInt>(thisFld) >= counts.nFld) {
	counts.nFld = fld.nrow();
	itsLog << " NEW";
      }
      itsLog << LogIO::POST;
    }
  }
}


void VLAFiller::summarise() {
  itsLog << LogIO::NORMAL;
  itsLog << "Finished filling the measurement set." << endl;
  itsLog << "The measurement set contains " << nrow() << " rows." << endl;
  itsLog << "The antenna sub-table contains " 
      << antenna().nrow() << " entries" << endl;
  itsLog << "The field sub-table contains " 
      << field().nrow() << " entries" << endl;
  itsLog << "The spectral window sub-table contains " 
      << spectralWindow().nrow() << " entries" << endl;
  itsLog << "The polarization sub-table contains " 
      << polarization().nrow() << " entries" << endl;
  itsLog << "The pointing sub-table contains " 
      << pointing().nrow() << " entries" << endl;
  itsLog << LogIO::POST;
}

uInt VLAFiller::addAntenna(const MPosition& antPos, uInt whichAnt) {
  MSAntennaColumns& ant = antenna();
  const uInt newRow = ant.nrow();
  itsMS.antenna().addRow(1);

  ant.name().put(newRow, String::toString(itsRecord.ADA(whichAnt).antId()));
  
  ant.station().put(newRow, itsRecord.ADA(whichAnt).padName());
  ant.type().put(newRow, "GROUND-BASED");
  ant.mount().put(newRow, "ALT-AZ");
  ant.positionMeas().put(newRow, antPos);
  ant.offset().put(newRow, Vector<Double>(3, 0.0));
  ant.dishDiameter().put(newRow, 25.0);
  ant.flagRow().put(newRow, False);
  return newRow;
}


uInt VLAFiller::addPointing(const MDirection& antDir,
			    const MDirection& fieldDir,
			    uInt whichAnt) {
  MSPointingColumns& pointingCol = pointing();
  const uInt newRow = pointingCol.nrow();
  itsMS.pointing().addRow(1);

  pointingCol.antennaId().put(newRow, itsRecord.ADA(whichAnt).antId());
  const MEpoch* mepPtr = dynamic_cast<const MEpoch*>(itsFrame.epoch());
  pointingCol.timeMeas().put(newRow, *mepPtr);
  pointingCol.numPoly().put(newRow, 0);
  pointingCol.timeOriginMeas().put(newRow, itsFrame.epoch());
  pointingCol.interval().put(newRow, itsRecord.SDA().intTime());
  Array<MDirection> bDir(IPosition(1,1));
  bDir(IPosition(1,0))=antDir;
  pointingCol.directionMeasCol().put(newRow, bDir);
  bDir(IPosition(1,0))=fieldDir;
  pointingCol.targetMeasCol().put(newRow, bDir);
  pointingCol.tracking().put(newRow, True);
  return newRow;
}

void VLAFiller::addFeed(uInt whichAnt) {
  MSFeedColumns& fd = feed();
  const uInt newRow = fd.nrow();
  itsMS.feed().addRow(1);

  fd.antennaId().put(newRow, whichAnt);
  fd.feedId().put(newRow, 0);
  fd.spectralWindowId().put(newRow, -1);
  fd.time().put(newRow, 0.0);
  fd.interval().put(newRow, 0.0);
  fd.numReceptors().put(newRow, 2);
  fd.beamId().put(newRow, -1);
  
  fd.beamOffset().put(newRow, Matrix<Double>(2,2, 0.0) );
  {
    Vector<String> pt(2);
    pt(0) = "R"; pt(1) = "L";
    fd.polarizationType().put(newRow, pt);
  }
  {
    Matrix<Complex> resp(2, 2, Complex(0.0f, 0.0f));
    resp.diagonal() = Complex(1.0f, 0.0f);
    fd.polResponse().put(newRow, resp);
  }
  fd.position().put(newRow, Vector<Double>(3, 0.0));
  fd.receptorAngle().put(newRow, Vector<Double>(2, 0.0));
}

uInt VLAFiller::addField(const MDirection& dir) {
  MSFieldColumns& fld = field();
  const uInt newRow = fld.nrow();
  itsMS.field().addRow(1);
  fld.name().put(newRow, itsRecord.SDA().sourceName());
  fld.code().put(newRow, itsRecord.SDA().calCode());
  const MEpoch* mepPtr = dynamic_cast<const MEpoch*>(itsFrame.epoch());
  fld.timeMeas().put(newRow, *mepPtr);
  fld.numPoly().put(newRow, 0);
  {
    Vector<MDirection> aDir(1, dir);
    fld.delayDirMeasCol().put(newRow, aDir);
    fld.phaseDirMeasCol().put(newRow, aDir);
    fld.referenceDirMeasCol().put(newRow, aDir);
  }
  fld.sourceId().put(newRow, newRow);
  if (!fld.ephemerisId().isNull()) {
    fld.ephemerisId().put(newRow, -1);
  }
  fld.flagRow().put(newRow, False);
  return newRow;
}

uInt VLAFiller::addDoppler( const VLAEnum::CDA cda ) {
  const VLASDA& sda = itsRecord.SDA();
  MSDopplerColumns& dopc = doppler();
  const uInt newRow = dopc.nrow();
  itsMS.doppler().addRow(1);  
  dopc.dopplerId().put(newRow, newRow );
  // find the source_id
  MSSourceColumns& srcc = source();
  const uInt source_id = srcc.nrow() - 1;
  dopc.sourceId().put(newRow, source_id );
  // transition column in SOURCE subtable is not filled. So here we fill TRANSITION_ID with -1.
  dopc.transitionId().put(newRow, -1);
  if (sda.dopplerTracking( cda )) {
	  const MDoppler dop(Quantity(1.0*sda.radialVelocity( cda ), "m/s"), sda.dopplerDefn( cda ));
	  dopc.velDefMeas().put(newRow, dop );
  }else {
     dopc.velDefMeas().put(newRow, MDoppler(Quantity(0.0,"m/s"),MDoppler::RADIO));
  }
  
  return newRow;
}

uInt VLAFiller::addSpectralWindow(const VLAEnum::CDA cda,
				  const MFrequency& refFreq,
				  const uInt nChan,
				  const Double bandwidth,
				  const uInt ifChain) {
  MSSpWindowColumns& spw = spectralWindow();
  const uInt newRow = spw.nrow();
  itsMS.spectralWindow().addRow(1);
  //cout.precision(8);
  spw.refFrequencyMeas().put(newRow, refFreq);
  spw.numChan().put(newRow, nChan);
  spw.ifConvChain().put(newRow, ifChain);
  // write doppler_id to spectral_window
  MSDopplerColumns& dopc = doppler();
  const uInt doppler_id = dopc.nrow() - 1;
  spw.dopplerId().put( newRow, doppler_id );
  
  const VLASDA& sda = itsRecord.SDA();
  const Double chanWidth = sda.channelWidth(cda);
  const MFrequency::Types itsFreqType = 
    MFrequency::castType(refFreq.getRef().getType());

  Vector<Double> chanFreq(nChan);
  indgen(chanFreq, sda.edgeFrequency(cda)+0.5*chanWidth, chanWidth);
  Vector<Double> chanWidths(nChan, chanWidth);
  if (itsFreqType != MFrequency::TOPO) { 
    // have to convert the channel frequencies from topocentric to the specifed
    // frequency type.
    itsFreqCtr.setOut(itsFreqType);
    Vector<Double> chanValInHz(1);
    MVFrequency  chanVal;
    for (uInt c = 0; c < nChan; c++) {
      chanValInHz = chanFreq(c);
      chanVal.putVector(chanValInHz);
      chanFreq(c) = itsFreqCtr(chanVal).getValue().getValue();
    }
    // To calculate the channel widths I just need to convert the topocentric
    // channel width!
    chanValInHz = chanWidth;
    chanVal.putVector(chanValInHz);
    chanWidths = itsFreqCtr(chanVal).getValue().getValue();
  }
  spw.chanFreq().put(newRow, chanFreq);
  spw.chanWidth().put(newRow, chanWidths);
  spw.effectiveBW().put(newRow, chanWidths);

  spw.flagRow().put(newRow, False);
  {
    Quantum<Double> qChanWidth(chanWidth, "Hz");
    if (chanWidth < 1E6) {
      qChanWidth.convert("kHz");
    } else {
      qChanWidth.convert("MHz");
    }
    Quantum<Double> qRefFreq(refFreq.get("GHz"));
    if (qRefFreq.getValue() < 1) {
      qRefFreq.convert("MHz");
    }
    ostringstream str;
    str << nChan
	<< "*" << setprecision(3) << qChanWidth
	<< " channels @ " << qRefFreq 
	<< " (" << refFreq.getRefString() << ")";
    spw.name().put(newRow, String(str));
  }
  if (sda.smoothed() || nChan == 1) {
    spw.resolution().put(newRow, chanWidths);
  } else {
    // The static cast is for a possible SGI compiler bug.  The compiler seems
    // unable to figure out that chanWidths is an Array
    spw.resolution().put(newRow, 
			 static_cast<Array<Double> >(chanWidths) * 
			 static_cast<Double>(1.21));
  }
  
  spw.totalBandwidth().put(newRow, sum(chanWidths));
  spw.netSideband().put(newRow, 1);
  // 
  static uInt curMSRows = 0;
  Int freqGroupId = 1;
  if (nrow() == curMSRows) {
    if (newRow > 0) {
      freqGroupId = spw.freqGroup()(newRow-1);
    }
  } else {
    freqGroupId = max(spw.freqGroup().getColumn()) + 1;
  }
  spw.freqGroup().put(newRow, freqGroupId);
  spw.freqGroupName().put(newRow, "Group " + String::toString(freqGroupId));
  curMSRows = nrow();
  return newRow;

}

uInt VLAFiller::addPolarization(const Vector<Stokes::StokesTypes>& polTypes) {
  MSPolarizationColumns& pol = polarization();
  const uInt newRow = pol.nrow();
  itsMS.polarization().addRow(1);
  const uInt nCorr = polTypes.nelements();
  pol.numCorr().put(newRow, nCorr);
  Vector<Int> polInt(nCorr);
  Matrix<Int> polProd(2, nCorr);
  for (uInt p = 0; p < nCorr; p++) {
    polInt(p) = polTypes(p);
    switch (polTypes(p)) {
    case Stokes::RR:
      polProd(0, p) = 0;
      polProd(1, p) = 0;
      break;
    case Stokes::RL:
      polProd(0, p) = 0;
      polProd(1, p) = 1;
      break;
    case Stokes::LR:
      polProd(0, p) = 1;
      polProd(1, p) = 0;
      break;
    case Stokes::LL:
      polProd(0, p) = 1;
      polProd(1, p) = 1;
      break;
    default:
      throw(AipsError("VLAFiller::addPolarization - Bad polarisation value"));
    }
  }
  pol.corrType().put(newRow, polInt);
  pol.corrProduct().put(newRow, polProd);
  pol.flagRow().put(newRow, False);
  return newRow;
}

uInt VLAFiller::addDataDescription(uInt spwId, uInt polId) {
  MSDataDescColumns& dd = dataDescription();
  const uInt newRow = dd.nrow();
  itsMS.dataDescription().addRow(1);
  dd.spectralWindowId().put(newRow, spwId);
  dd.polarizationId().put(newRow, polId);
  if (!dd.lagId().isNull()) {
    dd.lagId().put(newRow, -1);
  }
  return newRow;
}


uInt VLAFiller::addSource(const MDirection& dir ){

  MSSourceColumns& src = source();
  const uInt newRow = src.nrow();
  itsMS.source().addRow(1);
  const VLASDA& sda = itsRecord.SDA();
  src.name().put(newRow, sda.sourceName());
  src.sourceId().put( newRow, newRow ); // added by GYL
  src.spectralWindowId().put(newRow, -1);
  const MEpoch* mepPtr = dynamic_cast<const MEpoch*>(itsFrame.epoch());
  src.timeMeas().put(newRow, *mepPtr);
  src.code().put(newRow, sda.calCode());
  src.directionMeas().put(newRow, dir);
  MPosition obsPos;
  MeasTable::Observatory(obsPos, "VLA");
  MeasFrame frame(*mepPtr, obsPos, dir);
  Vector<MFrequency> restFreq;
  uInt validRest=0;
  for (uInt c = 0; c < maxCDA; c++) {
    const VLACDA& cda = itsRecord.CDA(c);
    if (cda.isValid()) {
      const VLAEnum::CDA thisCDA = VLAEnum::CDA(c);
      // check if it has a valid frame...some old data come without one !
      // Who said bad documentation is better than none ...aargh !
      if(sda.restFrame(thisCDA) < MFrequency::N_Types){
	++validRest;
	restFreq.resize(validRest, True);
	MFrequency::Convert tolsr(sda.restFrame(thisCDA), 
				  MFrequency::Ref(MFrequency::LSRK, frame));
	restFreq(validRest-1)=tolsr(sda.restFrequency(thisCDA));
      }
    }
  }
  src.numLines().put(newRow, validRest);
  src.restFrequencyMeas().put(newRow, restFreq);
  return newRow;

}

void  VLAFiller::extendHypercubes(const Block<uInt>& nPol,
				  const Block<uInt>& nChan, uInt rows) {
  const uInt nSpId = nChan.nelements();
  DebugAssert(nPol.nelements() == nSpId, AipsError);
  for (uInt s = 0; s < nSpId; s++) {
    {
      itsTileId.define(sigmaTileId, static_cast<Int>(nPol[s]));
      itsSigmaAcc.extendHypercube(rows, itsTileId);
      itsTileId.removeField(sigmaTileId);
    }
    {
      itsTileId.define(dataTileId, static_cast<Int>(10*nChan[s] + nPol[s]));
      itsDataAcc.extendHypercube(rows, itsTileId);
      itsTileId.removeField(dataTileId);
    }
    {
      itsTileId.define(modDataTileId, static_cast<Int>(10*nChan[s] + nPol[s]));
      itsModDataAcc.extendHypercube(rows, itsTileId);
      itsTileId.removeField(modDataTileId);
    }
    {
      itsTileId.define(corrDataTileId, static_cast<Int>(10*nChan[s] + nPol[s]));      itsCorrDataAcc.extendHypercube(rows, itsTileId);
      itsTileId.removeField(corrDataTileId);
    }
    
    {
      itsTileId.define(chanFlagTileId, static_cast<Int>(10*nChan[s] + nPol[s]));      itsChanFlagAcc.extendHypercube(rows, itsTileId);
      itsTileId.removeField(chanFlagTileId);
    }
    {
      itsTileId.define(flagTileId, static_cast<Int>(10*nChan[s] + nPol[s]));
      itsFlagAcc.extendHypercube(rows, itsTileId);
      itsTileId.removeField(flagTileId);
    }
    {
      itsTileId.define(imagingWeightTileId, static_cast<Int>(10*nChan[s]));
      itsImagingWeightAcc.extendHypercube(rows, itsTileId);
      itsTileId.removeField(imagingWeightTileId);
    }
  }
}

void  VLAFiller::addHypercubes(uInt nPol, uInt nChan) {
  DebugAssert(nChan > 0 && nChan <= 4096, AipsError);
  DebugAssert(nPol > 0 && nPol <= 4, AipsError);
  Bool addDataCube = True;
  Bool addSigmaCube = True;
  Bool addImagingWeightCube=True;
  uInt s = itsDataShapes.nelements();
  while (addDataCube && s > 0) {
    s--;
    const IPosition& curShape = itsDataShapes[s];
    if (curShape(0) == static_cast<Int>(nPol)) {
      addSigmaCube = False;
    }
    if (curShape(0) == static_cast<Int>(nPol) && 
	curShape(1) == static_cast<Int>(nChan)) {
      addDataCube = False;
    }
    if (curShape(1) == static_cast<Int>(nChan)) {
      addImagingWeightCube = False;
    }
    
    DebugAssert(addDataCube || !addSigmaCube, AipsError);
  }

  if (addDataCube) {
    if (addSigmaCube) {
      itsTileId.define(sigmaTileId, static_cast<Int>(nPol));
      //      uInt rowTiles = 378*128/nPol;
      //Now using a row tile length of 378...need to make this
      // dynamic if there is no autocorr...
      uInt rowTiles=378;
      if (rowTiles < 378) rowTiles = 378;
      itsSigmaAcc.addHypercube(IPosition(2, nPol, 0), 
			       IPosition(2, nPol, rowTiles),
			       itsTileId);
    }
    
    //  if (addImagingWeightCube)
    {
      itsTileId.define(imagingWeightTileId, static_cast<Int>(10*nChan));
      const uInt chanTiles = (nChan+7)/8;
      //      uInt rowTiles = 378*128/chanTiles;
      uInt rowTiles=378;
      if (rowTiles < 378) rowTiles = 378;
      itsImagingWeightAcc.addHypercube(IPosition(2, nChan, 0), 
			       IPosition(2, chanTiles, rowTiles),
			       itsTileId);
      itsTileId.removeField(imagingWeightTileId);
    }
    
    itsTileId.define(dataTileId, static_cast<Int>(10*nChan + nPol));
    const uInt chanTiles = (nChan+7)/8;
    //    uInt rowTiles = 378*128/nPol/chanTiles;
    uInt rowTiles=378;
    if (rowTiles < 378) rowTiles = 378;
    itsDataAcc.addHypercube(IPosition(3, nPol, nChan, 0), 
			    IPosition(3, nPol, chanTiles, rowTiles),
			    itsTileId);

    itsTileId.removeField(dataTileId);
 
    itsTileId.define(modDataTileId, static_cast<Int>(10*nChan + nPol));
    itsModDataAcc.addHypercube(IPosition(3, nPol, nChan, 0), 
			       IPosition(3, nPol, chanTiles, rowTiles),
			       itsTileId);
    itsTileId.removeField(modDataTileId);

    itsTileId.define(corrDataTileId, static_cast<Int>(10*nChan + nPol));
    itsCorrDataAcc.addHypercube(IPosition(3, nPol, nChan, 0), 
			       IPosition(3, nPol, chanTiles, rowTiles),
			       itsTileId);
    itsTileId.removeField(corrDataTileId);
    itsTileId.define(chanFlagTileId, static_cast<Int>(10*nChan + nPol));
    itsChanFlagAcc.addHypercube(IPosition(3, nPol, nChan, 0), 
			       IPosition(3, nPol, chanTiles, rowTiles),
			       itsTileId);
    itsTileId.removeField(chanFlagTileId);

    itsTileId.define(flagTileId, static_cast<Int>(10*nChan + nPol));
    itsFlagAcc.addHypercube(IPosition(4, nPol, nChan, nCat, 0), 
  			    IPosition(4, nPol, chanTiles, nCat, rowTiles),
  			    itsTileId);
    itsTileId.removeField(flagTileId);
    const uInt nCubes = itsDataShapes.nelements();
    itsDataShapes.resize(nCubes + 1);
    itsDataShapes[nCubes] = IPosition(2, nPol, nChan);
  }
}

Int VLAFiller::polIndexer(Stokes::StokesTypes& stokes){
  if (stokes == Stokes::RR)
    return 0;
  else if (stokes == Stokes::RL)
    return 1;
  else if (stokes == Stokes::LR)
    return 2;
  else if (stokes == Stokes::LL)
    return 3;
  else 
    return -1;
} 
// Local Variables:
// compile-command: "gmake VLAFiller; cd ../../apps/vlafiller; gmake OPTLIB=1"
// End: 
