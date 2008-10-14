//# ConvertToSCN.cc: class for conversion from MeasurementSet to Newstar Scan File
//# Copyright (C) 1997,1998,1999,2000,2001,2002,2003,2004
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
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
//# $Id: ConvertToSCN.cc,v 19.9 2006/03/06 10:37:29 rassendo Exp $

#include <ConvertToSCN.h>
#include <SubGroupInfo.h>
#include <casa/Arrays/Cube.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/MatrixMath.h>
#include <casa/Arrays/ArrayIO.h>
#include <casa/Arrays/Slicer.h>
#include <casa/Arrays/Slice.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayUtil.h>
#include <tables/Tables/TableRecord.h>
#include <tables/Tables/ExprNode.h>
#include <tables/Tables/TiledStManAccessor.h>
#include <tables/Tables/ColumnsIndex.h>
#include <measures/TableMeasures/ScalarQuantColumn.h>
#include <casa/System/ProgressMeter.h>
#include <casa/BasicSL/Constants.h>
#include <casa/BasicMath/Math.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MeasTable.h>
#include <casa/Quanta/MVPosition.h>
#include <measures/Measures.h>
#include <casa/Containers/RecordField.h>
#include <casa/fstream.h>
#include <casa/sstream.h>

//
// When the integration time of the first sample deviates from the
// second, this is probably a 2nd, 3rd, .. part of an older
// time-sliced measurement set. DeltaHAincr = HAincr[0] -
// HAincr[1]. If this value is > 0, then the first sample must be
// forced to start _later_ such that subsequent samples start
// correctly. Note that the first sample contains more data then the
// others.
//
Double DeltaHAincr;

void RA_DEBUG(string s)
{
  cout << "!\n";
  cout << "RA-DEBUG: " << s << endl;
  cout << "!\n";
}


// Initialize ConvertToSCN
ConvertToSCN::ConvertToSCN(MeasurementSet& aMS, const Path& aFile):
itsMS(aMS),
itsSCN(SCN, aFile.absoluteName().chars()),
itsNrScans(0),
itsMsc(aMS),
itsFieldc(aMS.field()),
foundAutoCorr(False)
{
    // Determine if an X polarization is given.
    // Then we know if a single polarization is X or Y.
    // Get polarization types from the first row.
    ROMSFeedColumns feedCol(itsMS.feed());
    Vector<String> polType = feedCol.polarizationType()(0);
    itsPolX = (polType(0) == "X");
    // Get the mapping of DataDescId to SpectralWindowId;
    ROMSDataDescColumns ddCol(aMS.dataDescription());
    itsSpwidMap = ddCol.spectralWindowId().getColumn();
}

// Destructor
ConvertToSCN::~ConvertToSCN()
{}

//----------------------------------------------------------------------
// Loop over MS and get some global information
//
// Input parameters:
//  Bool applyTRX - 
//  Bool autoCorr - 
//  Int spwid - spectral window ID to be converted, 0 means 'all bands'
//
Bool ConvertToSCN::prepare (Bool applyTRX, Bool autoCorr, Int spwid)
{
  cout << "Find relevant NFRA parameters:" << endl;

  itsVolgnr = 0;
  itsMulti = 0;      // initialy no multi
  itsMosaic = 0;     // initialy no mosaic
  isDCB = False;
  isIVC = False;
  isNominal = true;  // in earlier versions, isNominal could be false
  itsRestFreq = 0;
  itsRefVel=0;
  itsVelc=0;
  itsNrScans=0;
  itsFirstChannel=0;
  itsNrChans = 0;

  //
  // Get information from NFRA_TMS_PARAMETERS table
  // If the table or any of the relevant keywords can not be found,
  // the MS cannot be processed.
  //
  if (!itsMS.keywordSet().isDefined ("NFRA_TMS_PARAMETERS")) {
  
    cout << "ERROR - No NFRA_TMS_PARAMETERS table - cannot process this MS.\n";
    return false;

  } else {

    Table tmsParm = itsMS.keywordSet().asTable ("NFRA_TMS_PARAMETERS");
    Table sel;
    ROTableColumn tc(tmsParm, "NAME");
    String tmp;
    tc.getScalar(0, tmp);

    //
    // Get instrument
    //
    String instrument;
    sel = tmsParm (tmsParm.col("NAME") == "Instrument");
    if (sel.nrow() == 0){
      cout << "WARNING - Instrument not found." << endl;
      cout << "          Assume non-mosaic Measurement Set." << endl;
      instrument = "Unknown";
    } else {
      instrument = ROScalarColumn<String>(sel, "VALUE")(0);
    }
    cout << "  Instrument = " << instrument << endl;

    //
    // Check if this instrument is supported
    //
    if (instrument == "MultiFreqDZB") {
      itsMulti = 1;
      cout << "  This is originally a multiFreq. measurements.\n    Keep your fingers crossed.\n";
    } else if (instrument == "MultiPointDZB") {
      itsMulti = 2;
      cout << "  This is originally a multiPoint. measurements.\n    Keep your fingers crossed.\n";
    } 
      
    //
    // DZBNominal and DZBWHAT may be freq/pointing mosaicing
    // Number of freq. mosaicing positions is given by FW1.Positions
    // Number of pos. mosaicing positions is given by PW1.Positions
    // Set itsMosaic:
    //    0 = No mosaicing
    //    1 = freq. mosaicing
    //    2 = pos. mosaicing
    //
    if ((instrument == "DZBNominal") || (instrument == "DZBWHAT")) {

      Int nFreq = 0;
      sel = tmsParm (tmsParm.col("NAME") == "FW1.Positions");
      if (sel.nrow() == 0){
        cout << "WARNING - cannot find FW1.Positions keyword.\n";
	cout << "          assume non-mosaicing Measurement Set." << endl;

      } else {
        String str = ROScalarColumn<String>(sel, "VALUE")(0);
        nFreq = atoi(str.chars());
        if (nFreq > 1){
          itsMosaic = 1;
          cout << "  Freq. mosaic over " << nFreq << " windows.\n";
          cout << "    Keep your fingers crossed.\n";
        }
      }

      Int nPos = 0;
      sel = tmsParm (tmsParm.col("NAME") == "PW1.Positions");
      if (sel.nrow() == 0){
        cout << "WARNING - cannot find PW1.Positions keyword.\n";
	cout << "          assume non-mosaicing Measurement Set." << endl;
	
      } else {
        String str = ROScalarColumn<String>(sel, "VALUE")(0);
        nPos = atoi(str.chars());
        if (nPos > 1){
          itsMosaic = 1;
          cout << "  Pos. mosaic over " << nPos << " fields.\n";
          cout << "    Keep your fingers crossed.\n";
        }
      }

      if ((nFreq > 1) && (nPos > 1)){
        cout << "ERROR - both frequency and position mosaicing - cannot handle this.\n";
        return false;
      }
      
    }

    //
    // Get the MS number.
    // Set itsVolgNr.
    //
    sel = tmsParm (tmsParm.col("NAME") == "PW1.Measurement");
    if (sel.nrow() == 0) {
      cout << "ERROR - PW1.Measurement not found." << endl;
      cout << "        itsVolgNr set to 0." << endl;
      itsVolgnr = 0;
    } else {
      String str = ROScalarColumn<String>(sel, "VALUE")(0);
      itsVolgnr = atoi(str.chars()) % 1000000000;
    }
    cout << "  Measurement number = " << itsVolgnr << endl;

    //
    // Get the IF type.
    // Set the isDCB, and isIVC flags:
    //
    //  Type  isDCB  isIVC
    //  ------------------
    //  DCB   True   False
    //  IVC   False  True
    //  DLB   False  False
    //  other ==> Error
    //
    sel = tmsParm (tmsParm.col("NAME") == "WSRT-IF.Type");
    if (sel.nrow() == 0) {
      cout << "ERROR - WSRT-IF.Type not found." << endl;
      return false;
    } else {
      String str = ROScalarColumn<String>(sel, "VALUE")(0);
      if (str == "DCB") {
        isDCB = True;
        isIVC = False;
        cout << "  DCB observation" << endl;
      } else if (str == "IVC" ) {
        isDCB = False;
        isIVC = True;
        cout << "  DZB-IVC observation" << endl;
      } else if (str == "DLB" ) {
        isDCB = False;
        isIVC = False;
        cout << "!!" << endl;
	cout << "!!  BEWARE - DLB measurement, don't know if this type is handled correctly." << endl;
        cout << "!!" << endl;
      } else {
        isDCB = False;
        isIVC = False;
        cout << "!!" << endl;
	cout << "!!  BEWARE - unknown IF-type:" << str << ", don't know if this type is handled correctly." << endl;
        cout << "!!" << endl;
      }
    }

    //
    // Get the integration time.
    // Set itsIntTime.
    //
    sel = tmsParm(tmsParm.col("NAME") == "DZBReadout.IntegrationTime");
    if (sel.nrow() == 0) {
      cout << "ERROR - DZBReadout.IntegrationTime not found." << endl;
      return false;
    } else {
      String str = ROScalarColumn<String>(sel, "VALUE")(0);
      itsIntTime = atoi(str.chars()) * 10;
    } 
    cout << "  Integration time = " << itsIntTime << " s" << endl;

    //
    // Get the rest frequency.
    // Set itsRestFreq.
    //
    sel = tmsParm (tmsParm.col("NAME") == "FW1.RestFrequency");
    if (sel.nrow() == 0) {
      cout << "ERROR - FW1.RestFrequency not found." << endl;
      return false;
    } else {
      String str = ROScalarColumn<String>(sel, "VALUE")(0);
      itsRestFreq = atof(str.chars());
    } 
    cout << "  RestFrequency = " << itsRestFreq << " MHz.\n";

    //
    // Get the Tracking Speed.
    // Note that in old MSses (before 23SEP2005) the keyword is
    // TrackingVeloc, and in newer MSses the keyword is TrackingSpeed<n>
    // Set itsRefVel.
    //
    sel = tmsParm (tmsParm.col("NAME") == "FW1.TrackingSpeed0");
    String KwdName = "TrackingSpeed";
    if (sel.nrow() == 0) {
      //
      // FW1.TrackingSpeed0 not found - try the old keyword ...
      //
      sel = tmsParm (tmsParm.col("NAME") == "FW1.TrackingVeloc");
      KwdName = "TrackingVeloc";
      if (sel.nrow() == 0) {
        cout << "ERROR - FW1.TrackingSpeed0 or FW1.TrackingVeloc not found." << endl;
	return false;
      }
    }
    String str = ROScalarColumn<String>(sel, "VALUE")(0);
    itsRefVel = atof(str.chars())  * 1000;
    cout << "  " << KwdName << " = " << itsRefVel << endl;

    //
    // If a non-zero tracking velocity is given, get the Velocity
    // definition and Conversion type.
    //
    // Set itsVelc:
    // VelDev ConvTy  itsVelc
    // ----------------------
    // bary   else      1
    // bary   optical   3
    // else   else      2
    // else   optical   4
    //
    if (itsRefVel != 0) {

      sel = tmsParm (tmsParm.col("NAME") == "FW1.VelocDefinition");
      if (sel.nrow() == 0) {
        cout << "ERROR - FW1.VelocDefinition not found." << endl;
        return false;
      } else {
        String str = ROScalarColumn<String>(sel, "VALUE")(0);
        if ( str  == "bary"){
          itsVelc=1; 
        } else { 
          itsVelc=2;
        }
      }

      sel = tmsParm (tmsParm.col("NAME") == "FW1.ConversionType");
      if (sel.nrow() == 0) {
        cout << "ERROR - FW1.ConversionType not found." << endl;
        return false;
      } else {
        String str = ROScalarColumn<String>(sel, "VALUE")(0);
        if ( str == "optical"){
          itsVelc+=2;
        }
      }
      cout << "  Velocity code: " << itsVelc << endl;
    }

  }
  //
  // All necessary NFRA_PARAMETERS are known and OK
  //

  //
  // Get the telescope positions.
  // Fills itsAntMap and itsTelPos:
  //  itsAntMap - integer list of antennas used.
  //  itsTelPos - list of telescope positions relative to first
  //              telescope.
  //              The position of the n-th telescope in the MS can
  //              be found as: itsTelPos[itsAntmap[n]];
  //
  // Note that the max number of telescope positions is hardcoded to 14.
  //
  fillTelPos();
  //
  //  cout << "Antenna mapping: " << itsAntMap << endl;
  //  cout << "Telescope positions " << itsTelPos << endl;
  //

  //
  // Get information on Spectral Windows.
  // Fills:
  //   itsResolution - channel resolution in Hz
  //   itsChanFreq - channel frequency in MHz
  //   itsRefFreq - midband sky frequency
  //   itsNrChans - number of channels per band
  //
  {
    cout << "Spectral window information:\n";
    ROMSSpWindowColumns spwCol(itsMS.spectralWindow());
    spwCol.resolution().getColumn(itsResolution);
    spwCol.chanFreq().getColumn(itsChanFreq);
    spwCol.refFrequency().getColumn(itsRefFreq);
    itsNrChans = spwCol.numChan()(0);

    //
    // Report to user
    //
    Int p1;
    Int p2;
    itsChanFreq.shape(p1, p2);
    cout << "  Number of bands:" << p2 << endl;
    cout << "  Nr of channels per band: " << itsNrChans << endl;
  }

  {
    cout << "Polarization information:\n";
    ROMSPolarizationColumns polCol(itsMS.polarization());
    itsNrCorrs=polCol.numCorr()(0);                        // # of polarizations
    cout << "  Number of correlations: " << itsNrCorrs << endl;
  }

  //
  // Get the various data columns into vectors.
  //  nrow - number of rows in Main table.
  //  times - TIME
  //  ifrs - ANTENNA1
  //  ant2 - ANTENNA2
  //  fields - FIELD_ID
  //  spwids - DATA_DESC_ID
  //  dataCol - DATA
  //  timeUnit - unit of time
  //
  cout << "Get data from main table ... ";

  uInt nrows=itsMS.nrow();                              // number of rows in Main table

  const ROScalarColumn<Double>& timeCol = itsMsc.time();
  Vector<Double> times = timeCol.getColumn();

  const ROScalarColumn<Int>& antenna1Col = itsMsc.antenna1();
  Vector<Int> ifrs = antenna1Col.getColumn();

  const ROScalarColumn<Int>& antenna2Col = itsMsc.antenna2();
  Vector<Int> ant2 = antenna2Col.getColumn();

  const ROScalarColumn<Int>& fieldCol = itsMsc.fieldId();
  Vector<Int> fields = fieldCol.getColumn();

  const ROScalarColumn<Int>& ddidCol = itsMsc.dataDescId();
  Vector<Int> spwids = ddidCol.getColumn();

  const ROArrayColumn<Complex>& dataCol = itsMsc.data();

  String timeUnit = itsMsc.timeQuant().getUnits();

  cout << "OK\n";

  //
  // Get antenna numbers, convertAntenna translates the index to an antenna number
  // ifrs contains the pointers into the ANTENNA table, convertAntenna
  // converts this number to a WSRT telescope number (0..14) using itsAntMap.
  // (ignoring  the fact that ::fillTelPos allows non-WSRT telescopes)
  //
  // Set itsAnt1 to those telescope numbers
  // 
  // Do the same for ant2 and set itsAnt2
  //
  // ==>> ifrs will become 256*antenna2 + antenna1 for those telescope
  // pairs that must written to the scan file. 
  //
  convertAntenna (ifrs);
  itsAnt1 = ifrs;
  convertAntenna (ant2);
  itsAnt2.reference (ant2);

  // 
  // Find all rows from the main table that must be converted.
  // For the rows that must be converted ifrs(i) is set to antenna1 + 256*antenna2,
  // otherwise ifrs(i) is set to -1.
  // Count the number of rows.
  //
  int nOK = 0;
  int nAutoCorr = 0;
  {
    cout << "Find rows that must be processed ... ";

    foundAutoCorr = False;           // becomes true when an autocorrelation is found
    
    //
    // for all rows in the main table
    //
    for (uInt i=0; i<nrows; i++) {
      
      //
      // replace index into DATA_DESCRIPTION table with index into
      // SPECTRAL_WINDOW table
      //
      spwids(i) = itsSpwidMap(spwids(i));
      
      //
      // A row is legal if;
      // - it has hte spectral dindow we want,
      // - it has WSRT telescope (0 ... 13)
      // - the interferometer pair is E-W
      // - the time positive
      //
      if ((spwid < 0  ||  spwids(i) == spwid)
          &&  ifrs(i) >= 0  &&  ifrs(i) <= 13
          &&  ant2(i) >= 0  &&  ant2(i) <= 13
          &&  ifrs(i) <= ant2(i)
          &&  times(i) > 0) {
        //
        // if this is an autocorrelation line, check if we want this
        //
        if (ifrs(i) == ant2(i)) {
	  nAutoCorr++;
          foundAutoCorr = True;        // set flag
          if (autoCorr) {
            ifrs(i) += 256*ant2(i);    // convert antennas to ifr
	    nOK++;
          } else {
            ifrs(i) = -1;              // skip autocorrelations
          }
        } else {
          ifrs(i) += 256*ant2(i);      // convert antennas to ifr
	  nOK++;
        }
      } 

      //
      // if line is not legal
      //
      else {
        if (times(i) <= 0) {
          cout << "Timestamp Zero found...." << endl;
        }
        //
        // Report the skipped line, unless the skipping is due to the
        // telescope number
	//
	if (ifrs(i) >= 0  &&  ifrs(i) <= 13 &&  ant2(i) >= 0  &&  ant2(i) <= 13){
	  cout << "WARNING - skip line " << i << " of main table.\n";
	}
        ifrs(i) = -1;                  // illegal row
      }
      
    }

    //
    // message to user
    //
    cout << "OK\n";
    cout << "  Must process " << nOK << " out of " << nrows << " lines\n";
    if (foundAutoCorr) {
      cout << "  " << nAutoCorr << " autocorrelations are found and ";
      if (autoCorr) {
        cout << "selected";
      } else {
        cout << "skipped";
      }
      cout << endl;
    }
  }

  //
  // Sort the id's in order of spectral window, time, interferometer (ifr)
  // (in SCN-file we want baselines in range long to short).
  //
  cout << "Sort data ... ";

  Bool deleteIt;
  const Int* spwidsData = spwids.getStorage (deleteIt);
  const Double* timesData = times.getStorage (deleteIt);
  const Int* ifrsData = ifrs.getStorage (deleteIt);
  const Int* fieldsData = fields.getStorage (deleteIt);

  Sort sort;
  sort.sortKey (spwidsData, TpInt);
  sort.sortKey (timesData, TpDouble);
  sort.sortKey (ifrsData, TpInt, 0, Sort::Descending);

  Vector<uInt> index;
  sort.sort (index, nrows);
  const uInt* indexData = index.getStorage(deleteIt);

  cout << "OK\n";
  //
  // From here onwards all the data must be indexed using indexData
  //

  //  
  // Create the NewStar ifr-table
  // Do this by taking the first time and picking all ifrs until the time
  // changes.
  // Hereby it is assumed that all ifr pairs are present in a series
  // of main table rows with the same time.
  //
  cout << "Create NewStar interferometer table ...";

  Double time0=timesData[indexData[0]];       // earliest datapoint
  itsNrIfrs = 0;
  uInt i=0;

  //
  // The outer loop makes sure that when a series of rows with a
  // certain time does not contains any legal ifr pairs, the next time
  // will be tried.
  // This, however, will probaly never occur.
  //
  while (itsNrIfrs == 0 && i < nrows) {

    //
    // Loop over all rows with the same time and put all legal ifr
    // pairs in the NewStar ifr table
    //
    while (i < nrows && timesData[indexData[i]] == time0) { 
      Int ifr = ifrsData[indexData[i]];       // ifrsData = ifrs = 256*ant2 + ant1
      if (ifr >= 0) {
        itsIfrTable.setIfrCodes (itsNrIfrs, ifr);
        itsNrIfrs++;
      }
      i++;                                    // next data row
    }

    //
    // If the time changes and we are not yet at the end of the table,
    // continue in the outer loop.
    //
    if (i < nrows) {
      time0=timesData[indexData[i]];
    }

  }

  //
  // Check if any interferometer pairs are found
  //
  if (itsNrIfrs == 0) {
    cout << "ERROR - no interferometers found" << endl;
    if (!autoCorr) {
      cout << "Maybe the MS contains autocorrelations only or all samples missing?" << endl;
    }
    return False;
  }
  cout << "created " << itsNrIfrs << " entries.\n";

  //
  // Determine the number of sets and scans.
  // Sets are each different spectral window, field, channel and sector.
  // A set consists of multiple times, so count number of times per set.
  // For the time being each spectral window must consist of the
  // same nr of correlations and channels (in the future it can be changed).
  //  
  // Resize the Block to a large enough size and initialize to 0.
  //
  itsNrScansPerSet.resize (nrows/itsNrIfrs);
  Int nset = -1;
  itsNrScans = 0;
  uInt nifr = 0;
  Int lastSpw = -1;
  Int lastFld = fieldsData[indexData[0]];
  Double lastTim = 0;
  Bool warningGiven = false;
  //
  // Iterate through the sorted data and start a new set when spectral
  // window or field changes or when the time jumps by another
  // interval then the integration time.
  //
  for (i=0; i<nrows; i++) {

    Double dT = 0;
    Bool newMosaic = false;

    //
    // For freq. mosaicing: if the time changes by another value that
    // the integration time, we move to a new spectral window, so we
    // must force a new set.
    //
    // If the time changes by an amount less than the integration
    // time, the first sample of a new mosaic point has less
    // integration time than requested. This will lead to incorrect HS
    // in the scan file, so exclude it.
    //
    if (itsMosaic == 1){
      if (i > 0){
	dT = timesData[indexData[i]]-timesData[indexData[i-1]];
      }
      if (dT != 0 && dT != itsIntTime ){
	newMosaic = true;                       // time has jumped -> new mosaic point
	if (dT < itsIntTime && !warningGiven){
	  cout << "\nWARNING - unequal integration times - HA may be incorrect.\n\n";
	  warningGiven = true;
	}
      }
    }

    //
    // only if this interferometer pair is requested
    //
    if (ifrsData[indexData[i]] >= 0) {

      Int spw = spwidsData[indexData[i]];       // spectral window ID
      Int fld = fieldsData[indexData[i]];       // field ID
      Double tim = timesData[indexData[i]];     // time

      //
      // If this row points to a new spectral window
      // 
      if (spw != lastSpw || newMosaic) {

	//
	// Check if the shape matches #corr and #chan.
	//
	IPosition shape = dataCol.shape (indexData[i]);
	if (shape(0) != Int(itsNrCorrs)) {
	  throw (AipsError ("ERROR - first data shape axis mismatches #corr"));
	}
	if (shape(1) != itsNrChans) {
	  throw (AipsError ("ERROR - second data shape axis mismatches #chan"));
	}

	lastSpw = spw;
	lastFld = fld+1;                        // force a new field
      }

      //
      // If this row points to a new field
      // A new field is:
      //  - really a new field
      //  - forced by a new spectral window
      //
      if (fld != lastFld) {
	nset++;                                 // new set
	itsNrScansPerSet[nset] = 0;             // counter for this set

	lastFld = fld;
	lastTim = tim+1;                        // force a new time
      }

      //
      // Each new time means a new scan.
      // A new time is:
      //  - really a new time
      //  - forced by a new field
      // A new field is:
      //  - really a new field
      //  - forced by a new spectral window
      //
      // Check if # interferometers in each set is the same.
      //
      if (tim != lastTim) {

	//
	// Before we start a new scan we must check if the # of
	// interferometers in the current one matches the # of
	// interferometers in dataset
	//
	if (nifr > 0  &&  nifr != itsNrIfrs) {
	  throw (AipsError ("Nr of interferometers is not consistent"));
	}
	itsNrScans++;                           // add a scan
	itsNrScansPerSet[nset]++;               // add scan to the set
	nifr = 1;                               // first ifr for new scan
	lastTim = tim;

      } else {
	nifr++;                                 // add interferometer to scan
      }
    }
  }
  //
  // Check for the last scan
  //
  if (nifr > 0  &&  nifr != itsNrIfrs) {
    throw (AipsError ("Nr of interferometers is not consistent (2)"));
  }

  // ?????
  //
  // Resize the Block to the correct size (force smaller).
  // number of sets is one more than the last index ...
  //
  nset++;
  itsNrScansPerSet.resize (nset, True);
  //
  // Create per scan a Block containing its row numbers in the MS.
  // That is used to determine the hourangles hereafter.
  //
  // This is not clear, lastBlock is defined and filled, but never used again.
  //
  itsScanRows.resize (itsNrScans);
  Block<Int>* lastBlock = 0;
  lastSpw = -1;
  Int j = 0;
  for (i=0; i<nrows; i++) {
    if (ifrsData[indexData[i]] >= 0) {
      Int spw = spwidsData[indexData[i]];
      Int fld = fieldsData[indexData[i]];
      Double tim = timesData[indexData[i]];
      if (spw != lastSpw  ||  fld != lastFld  ||  tim != lastTim) {
	lastBlock = &itsScanRows[j++];
	lastBlock->resize (itsNrIfrs);
	nifr = 0;
	lastSpw = spw;
	lastFld = fld;
	lastTim = tim;
      }
      (*lastBlock)[nifr] = indexData[i];
      nifr++;
    }
  }

  // Check if the scans in each set have the same time separation.
  // If not, see if inserting an extra dummy scan solves the problem.
  // It returns the common time interval in seconds.
  // Calculate the HA-interval from that.
  Double timeInterval = checkTimeIntervals (timesData, timeUnit);
  if (itsTimeInterval == 0){
    cout << "!!" << endl;
    cout << "!! BEWARE - itsTimeInterval is zero - should not happen" << endl;
    cout << "!!        - assume 60s ..." << endl;
    cout << "!!" << endl;
    itsTimeInterval = 60;
  }

  itsHAInterval = timeInterval * (366.25 / 365.25) / (24.*3600.); // days

  fillHAStart (timesData[0], timeUnit);
  
  // Fill per antenna and scan the TRX values from the SYSCAL table.
  if (applyTRX) {
    fillTrx (spwidsData, timesData);
  }
  
  return True;
}

void ConvertToSCN::fillTrx (const Int* spwidsData, const Double* timesData)
{
    cout << "Reading SYSCAL information ..." << endl;
    ROMSSysCalColumns syscal (itsMS.sysCal());
    Vector<Double> times = syscal.time().getColumn();
    Vector<Int> spwids = syscal.spectralWindowId().getColumn();
    Vector<Int> ants = syscal.antennaId().getColumn();
    convertAntenna (ants);
    Array<Float> trx = syscal.tsys().getColumn();
    uInt nrows = ants.nelements();
    // Sort the id's in order of spectral window, time
    // (in SCN-file we want baselines in range long to short).
    Bool deleteIt;
    const Int* spwidsCal = spwids.getStorage (deleteIt);
    const Double* timesCal = times.getStorage (deleteIt);
    const Int* antsCal = ants.getStorage (deleteIt);
    const Float* trxCal = trx.getStorage (deleteIt);
    AlwaysAssert (sizeof(Complex) == 2*sizeof(Float), AipsError);
    AlwaysAssert (trx.shape()(0) == 2, AipsError);
    const Complex* trxCalC = (const Complex*)trxCal;
    Sort sort;
    sort.sortKey (spwidsCal, TpInt);
    sort.sortKey (timesCal, TpDouble);
    Vector<uInt> index;
    sort.sort (index, nrows);
    const uInt* indexCal = index.getStorage(deleteIt);
    // Find per antenna and scan the TRX from the SYSCAL subtable.
    // Do this by comparing the time and spwid from each scan with
    // the (sorted) time and spwid in the SYSCAL.
    itsTrx.resize (max(ants)+1, itsNrScans);
    itsTrx = 0;
    uInt j=0;
    for (uInt i=0; i<itsNrScans; i++) {
      if (itsScanRows[i].nelements() > 0) {
        uInt row = itsScanRows[i][0];
        Bool fnd = False;
        while (!fnd && j<nrows) {
            uInt inx = indexCal[j];
            if (spwidsData[row] > spwidsCal[inx]) {
                j++;
            } else if (spwidsData[row] < spwidsCal[inx]) {
                break;
            } else if (timesData[row] > timesCal[inx]) {
                j++;
            } else if (timesData[row] < timesCal[inx]) {
                break;
            } else {
                fnd = True;
            }
        }
        if (!fnd) {
            cout << "No SYSCAL entry found for spwid=" << spwidsData[row]
                 << ", time=" << timesData[row] << endl;
        } else {
            while (fnd) {
                uInt inx = indexCal[j];
                Int tel = antsCal[inx];
                if (tel >= 0) {
                    itsTrx (tel, i) = trxCalC[inx];
                }
                j++;
                fnd =  (j<nrows  &&
                              timesCal[inx] == timesCal[indexCal[j]]);
            }
        }
      }
    }
}

Double ConvertToSCN::checkTimeIntervals (const Double* timesData,
                                         const String& timeUnit)
{
  Double interval;
  Block<uInt> newScans;
  uInt nrNew = 0;
  uInt scannr = 0;
  uInt nset = itsNrScansPerSet.nelements();

  bool WarningGiven = false;
  Double WarningValue = 0;

  Double firstValue = timesData[itsScanRows[1][0]]  - timesData[itsScanRows[0][0]];
  Double secondValue = timesData[itsScanRows[2][0]]  - timesData[itsScanRows[1][0]];

  DeltaHAincr = 0;
  if (firstValue != secondValue){
    cout << "!!" << endl;
    cout << "!! BEWARE - first integration time is not equal to second." << endl;
    cout << "!! " << firstValue << " != " << secondValue << endl;
    cout << "!! Will take the second value as leading." << endl;
    cout << "!! HA. " << endl;
    cout << "!!" << endl;
    DeltaHAincr = firstValue - secondValue;
    DeltaHAincr = DeltaHAincr / 3600.0 / 15.0;
    firstValue = secondValue;
  }

  for (uInt i=0; i<nset; i++) {
    
    uInt nrscan = itsNrScansPerSet[i];
    
    //
    // Make a histogram of the intervals.
    //
    Block<Int> histn;
    Block<Double> histv;
    uInt nrhist = 0;
    uInt rownr = itsScanRows[scannr][0];
    Double prev = timesData[rownr];
    for (uInt j=1; j<nrscan; j++) {
      rownr = itsScanRows[scannr+j][0];
      Double val = timesData[rownr];
      Double intv = val - prev;

      if (intv != firstValue && DeltaHAincr == 0){
	if (!WarningGiven || WarningValue != intv){
	  WarningGiven = true;
	  WarningValue = intv;
	  cout << "!!" << endl;
	  cout << "!! BEWARE - not all integration times are equal." << endl;
	  cout << "!! fist value: " << firstValue << endl;
	  cout << "!! found also the value: " << intv << endl;
	  cout << "!!" << endl;
	}
      }

      uInt k;
      for (k=0; k<nrhist; k++) {
	if (near(intv, histv[k], 1.0e-4)) {
	  histn[k]++;
	  break;
	}
      }
      if (k == nrhist) {
	histn.resize (nrhist+1);
	histv.resize (nrhist+1);
	histn[nrhist] = 1;
	histv[nrhist] = intv;
	nrhist++;
      }
      prev = val;
    }
    
    if (nrhist == 0) {
      interval =  60;
    } else if (nrhist == 1) {
      interval = histv[0];
    } else {
      uInt maxinx = 0;
      for (uInt j=1; j<nrhist; j++) {
	if (histn[j] > histn[maxinx]) {
	  maxinx = j;
	}
      }
      interval = histv[maxinx];
      uInt nrdiff = nrscan - histn[maxinx];
      if (interval <= 0  ||  (nrdiff > 1  &&  nrdiff > nrscan/5)) {
	cout << "Time intervals behave strangely; "
	  "more than 20% of intervals is different" << endl;
      } else {
	//	bool complained = false;
	// Loop again through all time intervals and insert
	// a dummy scan when possible.
	rownr = itsScanRows[scannr][0];
	prev = timesData[rownr];
	for (uInt j=1; j<nrscan; j++) {
	  rownr = itsScanRows[scannr+j][0];
	  Double val = timesData[itsScanRows[scannr+j][0]];
	  Double intv = val-prev;
	  Int nr = Int(intv/interval + 0.5);
	  if (! near (intv, nr*interval, 1.0e-1)) {
	    cout << "Time interval " << intv << " at row " << rownr
		 << " is not a multiple of interval "
		 << interval << " (nr=" << nr << ")" << endl;
	  }
	  for (Int k=1; k<nr; k++) {
	    MVTime time (Quantity(prev + interval*k, timeUnit));
	    newScans.resize (nrNew+1);
	    newScans[nrNew] = scannr+j;
	    nrNew++;
	    itsNrScansPerSet[i]++;
	  }
	  prev = val;
	}
      }
    }
    scannr += nrscan;
  }

  if (nrNew != 0){
    cout << "!!" << endl;
    cout << "!! BEWARE - inserting " << nrNew << " dummy scans - should not happen" << endl;
    cout << "!!" << endl;
  }

  // Now insert the new scans in itsScanRows.
  // newScans contains the scan numbers before which a dummy scan
  // has to be inserted (which is indicated by an empty Block).
  // Use a temporary Block to copy to and from.
  if (nrNew > 0) {
    uInt inxnew = 0;
    uInt last = 0;
    Block<Block<Int> > scanRows(itsNrScans+nrNew);
    for (uInt i=0; i<nrNew; i++) {
      uInt next = newScans[i];
      for (uInt j=last; j<next; j++) {
	scanRows[inxnew++] = itsScanRows[j];
      }
      scanRows[inxnew++] = Block<Int>();
      last = next;
    }
    for (uInt j=last; j<itsNrScans; j++) {
      scanRows[inxnew++] = itsScanRows[j];
    }
    itsScanRows = scanRows;
    itsNrScans += nrNew;
  }
  // Return interval found in seconds.
  MVTime t(Quantity(firstValue, timeUnit));

  itsTimeInterval = firstValue;
  return t.second();
}

void ConvertToSCN::setChannel(Int aChannel)
{
   cout << "Selected single channel " << aChannel << " out of "
        << itsNrChans <<endl;
   if (aChannel > 0  &&  aChannel <= itsNrChans) {
     itsFirstChannel = aChannel-1;
   } else {
     cout << "Invalid channel, taking channel 1 instead" << endl;
     itsFirstChannel = 1;
   }
   itsNrChans=1;
}


// Loop over the number of channels and create set-header, adding them to itsSCN
Bool ConvertToSCN::convert(Double haIncr, Double corrFactor, Bool applyTRX,
                           Bool showCache, Bool addSysCal, Bool autoCorr)
{
    cout << "HA-start:    " << (haIncr+itsHAStart)*360. << " deg" << endl;
    cout << "HA-interval: " << itsHAInterval*360*60.0 << " min" << endl;

    // Create all set headers and groups.
    const ROScalarColumn<Int>& ddidCol = itsMsc.dataDescId();
    const ROScalarColumn<Int>& fieldCol = itsMsc.fieldId();
    uInt nrsets = itsNrScansPerSet.nelements();
    cout << "Creating " << nrsets*itsNrChans << " sector headers ...";
    Int lastChannel=itsFirstChannel+itsNrChans;
    itsSCN.setSizes (nrsets*itsNrChans, nrsets*(lastChannel+1));
    {
        ProgressMeter progressMeter (0, nrsets*itsNrChans, "", "", "", "");
        uInt progress = 0;
        Int scannr = 0;
        for (uInt i=0; i<nrsets; i++) {
            // Calculate the start HA by looking at the first scan.
            Int nrscan = itsNrScansPerSet[i];
            uInt rownr = itsScanRows[scannr][0];
            scannr += nrscan;
            Int spwid = itsSpwidMap(ddidCol(rownr));
            Int fieldid = fieldCol(rownr);
            Double time (itsMsc.time()(rownr));
            Double nrt = (time-itsTimeStart) / itsTimeInterval;
            Double hast0 = haIncr + itsHAStart(fieldid) + nrt * itsHAInterval;
            NStarSetHeader* sethdr = makeSet(itsNrScansPerSet[i],
                                             hast0, fieldid);
            for (Int channel=itsFirstChannel; channel<lastChannel; channel++) {
              NStarSetHeader* chanhdr = makeChanSet(channel, spwid, *sethdr);
              SubGroupInfo group (0, spwid, fieldid,channel + 1,rownr);
              itsSCN.addSet (chanhdr, group);
              progress++;
              progressMeter.update (progress);
            }
            delete sethdr;
        }
    }
    // Add dummy subgroup info's for the channels before the first channel.
    // In that way people can use e.g. 0.0.0.1.0 to get the first channel.
    // (otherwise 0.0.0.0.0 would give the first channel).
    {
        Int scannr = 0;
        for (uInt i=0; i<nrsets; i++) {
            uInt rownr = itsScanRows[scannr][0];
            scannr += itsNrScansPerSet[i];
            Int spwid = itsSpwidMap(ddidCol(rownr));
            Int fieldid = fieldCol(rownr);
            for (Int channel=0; channel<=itsFirstChannel; channel++) {
                SubGroupInfo group (0, spwid, fieldid,channel,
                                    rownr);
                itsSCN.addGroup (group);
            }
        }
    }
    // Calculate the size of the cache needed.
    // The data is (more or less) iterated in order of
    // pol,baseline,time,channel,spwid while it is stored per row as
    // pol,channel and the rows are stored as spwid,baseline,time.
    // So make the cache size such that pol and baseline fit 
    ROTiledStManAccessor accessor(itsMS, "TiledData");
    IPosition cubeShape = accessor.hypercubeShape(0);
    IPosition tileShape = accessor.tileShape(0);
    Int nrclast = 1;
    Int nrtlast = 1;
    for (uInt i=2; i<cubeShape.nelements(); i++) {
      nrclast *= cubeShape(i);
      nrtlast *= tileShape(i);
    }
    ///    uInt nrspw = itsSpwinc.nrow();
    uInt nrbuckets = (cubeShape(0) + tileShape(0) - 1) / tileShape(0)
                   * (cubeShape(2) + tileShape(2) - 1) / tileShape(2);
    accessor.setCacheSize (0, nrbuckets);
    {
        cout << "Writing all scan data ...";
        ProgressMeter progressMeter (0, itsNrScans*itsNrChans, "", "", "", "");
        uInt progress=0;
        for (Int i=0; i<itsNrChans; i++) {
            makeScans (applyTRX, corrFactor, i, progressMeter, progress, autoCorr);
        }
    }
    if (showCache) {
        accessor.showCacheStatistics (cout);
    }

    if (addSysCal) {
      cout << "Writing all IFH data ...";
      makeSysCal();
    }

    return True;
}

// Invoke write() on itsSCN
Bool ConvertToSCN::write()
{
    itsSCN.write();
    return True;
}

// Convert the antenna-id to a telescope nr.
void ConvertToSCN::convertAntenna (Vector<Int>& ant)
{
    Bool deleteIt;
    Int* ants = ant.getStorage (deleteIt);
    Int nr = ant.nelements();
    for (Int i=0; i<nr; i++) {
        ants[i] = itsAntMap(ants[i]);
    }
    ant.putStorage (ants, deleteIt);
}

//--------------------------------------------------------------------------------
// Get telescope positions and antenna mapping.
// Fills itsAntMap and itsTelPos
//
// Number of telescopes in itsTelPos is hardcoded to 14
//
void ConvertToSCN::fillTelPos()
{
  //
  // Get antenna table and number of telescopes used
  //
  ROMSAntennaColumns antCol(itsMS.antenna());
  Int nr = antCol.name().nrow();

  //
  // initialize properties
  //
  itsAntMap.resize (nr);
  itsAntMap = -1;
  itsTelPos.resize (14);
  itsTelPos = 0;

  //
  // Get the position of the first telescope.
  //
  Vector<Double> firstPos (antCol.position()(0));

  //
  // Get telscope numbers and calculate baseline length relative to
  // first telescope.
  //
  for (Int j=0; j<nr; j++) {
    Int tel = -1;
    String name = antCol.name()(j);

    //
    // Convert telescope name RT? to a number.
    // The ? is converted from 0..9,A..Z to 0..36
    // For non-WSRT telescopes, the index in antCol as the telescope number.
    // The number is stored in itsAntMap
    //
    if (name.length() == 3  &&  name[0] == 'R'  &&  name[1] == 'T') {
      char telc = name[2];
      if (telc >= '0'  &&  telc <= '9') {
	tel = telc - '0';
      } else if (telc >= 'A'  &&  telc <= 'Z') {
	tel = 10 + telc - 'A';
      }
    } else {
      cout << "WARNING - non-WSRT telescope.";
      tel = j;
    }
    itsAntMap(j) = tel;

    //
    // Get the distance from the first telescope and store in itsTelPos
    //
    Vector<Double> antpos = antCol.position()(j);
    if (tel >= 0  &&  tel < 14) {
      Vector<Double> pos (antpos - firstPos);
      itsTelPos(tel) = norm(pos);
    } else {
      cout << "  WARNING - telescope number >= 14.\n";
      cout << "            all extra telescopes will be ignored.\n";
    }
  }
}

void ConvertToSCN::fillHAStart (Double startTime, const String& timeUnit)
{
    uInt nrfield = itsFieldc.delayDir().nrow();
    itsHAStart.resize (nrfield);
    // Get position of WSRT.
    MPosition wsrtPos;
    AlwaysAssert (MeasTable::Observatory(wsrtPos, "WSRT"), AipsError);
    // Get the start HA for each field.
    for (uInt i=0; i<nrfield; i++) {
      // Use the position in a frame
      MeasFrame frame(wsrtPos);
      // Convert time to an epoch and put in frame.
      Quantum<Double> qtime(0, timeUnit);
      qtime.setValue(startTime);
      frame.set (MEpoch(qtime, MEpoch::UTC));
      // Get the delay for the given time and convert to HADEC for the frame.
      MDirection delay = itsFieldc.delayDirMeas (i, startTime);
      MDirection out = MDirection::Convert
               (delay, MDirection::Ref (MDirection::HADEC, frame)) ();
      // Convert HA to parts of circle.
      Quantum<Vector<Double> > angles = out.getAngle();
      itsHAStart(i) = angles.getBaseValue()(0) / C::circle;
      itsHAStart(i) += DeltaHAincr;
    }
    itsTimeStart = startTime;
}


// make Set
NStarSetHeader* ConvertToSCN::makeSet(Int nrscans, Double haStart,
                                      Int fieldid)
{
    NStarSetHeader* sethdr=new NStarSetHeader;

    sethdr->setSCN(nrscans);                                // # of scans
    sethdr->setNIFR(itsNrIfrs);                                // # of interferometers
    sethdr->setHAB(haStart);                                // Hour-angle start
    sethdr->setHAI(itsHAInterval);                        // Hour-angle interval
    sethdr->setHAV(itsHAInterval);                        // Averaging HA
    sethdr->setFIELD(itsFieldc.name()(fieldid).chars());// Fieldname
    sethdr->setPLN(itsNrCorrs);                                // # of polarisations

    sethdr->setDIPC(0xaaaaaaa);                         // Assume parallel
    sethdr->setVNR(itsVolgnr);

    // Set telescope positions
    sethdr->setRTP(itsTelPos);

    // Get year and daynr. and MJD at middle of observation.
    String timeUnit = itsMsc.timeQuant().getUnits();
    const ROScalarColumn<Double>& timeCol = itsMsc.time();
    Quantum<Double> qtime(0, timeUnit);
    qtime.setValue((timeCol(0) + timeCol(itsMS.nrow()-1)) / 2);
    MVTime ttime(qtime);
    Vector<Short> obs(2);
    obs(0)=(Short) ttime.yearday();
    obs(1)=ttime.year()-1900;
    sethdr->setOBS(obs);                                // Obs. day/year
    Quantum<Double> qtime2(0, timeUnit);
    qtime2.setValue(timeCol(0));
    MVTime ttime2(qtime2);
    sethdr->setMJD(ttime2.day()+itsHAInterval*0.5);     // Start MJD (days)

    // Get RA and DEC
    MDirection mdelay = itsFieldc.delayDirMeas (fieldid);
    Quantum<Vector<Double> > qdelay = mdelay.getAngle();
    sethdr->setRAE(qdelay.getBaseValue()(0) / C::circle);       // Epoch RA
    sethdr->setDECE(qdelay.getBaseValue()(1) / C::circle);        // Epoch DEC
    if (mdelay.getRef().getType() == MDirection::B1950) {
        sethdr->setEPO(1950.);                                // Epoch 
    } else if (mdelay.getRef().getType() == MDirection::J2000) {
        sethdr->setEPO(2000.);                                // Epoch 
    } else {
      cout << endl << "WARNING - no B1950 or J2000 coordinates - continue with care" << endl;
      //        throw AipsError ("Unknown MDirection type in FIELD table DELAYDIR");
    }

    // Calculate obs. epoch, obs. RA and obs. DEC
    Float obsepoch=ttime.year()+(ttime.yearday())/365.25;
    sethdr->setOEP(obsepoch);                                // Obs. epoch 

    // Get position of WSRT.
    MPosition wsrtPos;
    AlwaysAssert (MeasTable::Observatory(wsrtPos, "WSRT"), AipsError);
    // Use this position in a frame and convert direction to apparent.
    MeasFrame frame(wsrtPos);
    Quantity epoch(sethdr->getMJD(), "d");
    frame.set (MEpoch(epoch, MEpoch::UTC));
    MDirection out = MDirection::Convert (
          mdelay,
          MDirection::Ref (MDirection::APP, frame)) ();
    Quantum<Vector<Double> > angles = out.getAngle();
    sethdr->setRA(angles.getBaseValue()(0) / C::circle);        // Apparent RA
    sethdr->setDEC(angles.getBaseValue()(1) / C::circle);        // Apparent DEC

    // Get precession/nutation rotation angle (from epoch to apparent)
    sethdr->setPHI (calcPhi (mdelay, epoch));
    
    // set pointer to Interferometer Table
    sethdr->setIfrTable(&itsIfrTable);
    return sethdr;
}

// make Set
NStarSetHeader* ConvertToSCN::makeChanSet (uInt channel, Int spwid,
                                           const NStarSetHeader& sethdr)
{
    // Make a copy of the sethdr and complete it with channel info.
    NStarSetHeader* chanhdr = new NStarSetHeader(sethdr);

    // Set center and reference frequency.
    chanhdr->setFRQ0(itsRestFreq);                      // Rest freq of line
    chanhdr->setFRQC(itsRefFreq(spwid)/1000000.);       // Ref freq
    chanhdr->setSpwid(spwid);
    if (isDCB) {
      chanhdr->setCHAN(spwid);                                // DCB band
    } else {
      chanhdr->setCHAN(channel);                        // DZB freq. channel
    }
    // Get bandwidth
    chanhdr->setUBAND(itsResolution(channel,spwid)/1000000.);
    // Get frequency
    Double frq = itsChanFreq(channel,spwid) / 1000000.;
    chanhdr->setFRQ(frq);                // App. frequency
    chanhdr->setFRQV(frq);                // Real frequency for line
    chanhdr->setFRQE(frq);                // Lsr frequency 


    // Calculate and set velocity definitions (if given)
    chanhdr->setVELC(itsVelc);
    chanhdr->setVELR(itsRefVel);
    Double vel=0;
    Double frqc=itsRefFreq(spwid)/1000000.;
    Double cl=2.997925e8;  // Speed of light in m/sec
    if (itsVelc == 1 || itsVelc == 2) {
      vel = itsRefVel * frq / frqc + cl * (frqc-frq)/frqc;
    } else if (itsVelc == 3 || itsVelc == 4) {
      vel = itsRefVel * frqc / frq + cl * (frqc-frq)/frq;
    }
    chanhdr->setVEL(vel);

    return chanhdr;
}

// Calculate the rotation angle (taken from nscclp.for in Newstar)
Double ConvertToSCN::calcPhi (const MDirection& in,
                              const Quantity& epoch)
{
    MeasFrame frame;
    frame.set (MEpoch(epoch, MEpoch::UTC));
    MDirection out1 = MDirection::Convert (in,
          MDirection::Ref (MDirection::APP, frame)) ();
    MVDirection mpole;
    MDirection pole (mpole, in.getRef());
    MDirection out2 = MDirection::Convert (pole,
          MDirection::Ref (MDirection::APP, frame)) ();
    Quantity phi = out1.getValue().positionAngle(out2.getValue(), "deg");
    return phi.getValue() / 360;
}

// make Scan
void ConvertToSCN::makeScans (Bool applyTRX, Double corrFactor, uInt chanSeqnr,
                              ProgressMeter& progressMeter, uInt& progress,
                              Bool autoCorr)
{
    uInt channel = itsFirstChannel + chanSeqnr;
    ofstream& file = itsSCN.getFile();
    // Get factor to convert from Jy to WU and to apply the correction factor.
    // Note that it is only used when writing the scale factor in the scan hdr.
    Double factor = 200*corrFactor;
    // Get all data and flags for this channel.
    Slicer slicer(Slice(0,itsNrCorrs),Slice(channel,1));
    Cube<Complex> data;
    Cube<Bool> flags;
    itsMsc.data().getColumn(slicer,data);
    itsMsc.flag().getColumn(slicer,flags);
    Bool deleteIt, deleteFl;
    Complex* cdata = data.getStorage(deleteIt);
    const Bool* flagdata = flags.getStorage(deleteFl);
    AlwaysAssert (sizeof(Complex) == 2*sizeof(float), AipsError);
    Float* fdata = (Float*)cdata;
    uInt nrp = 2*itsNrCorrs;
    uInt nsets = itsNrScansPerSet.nelements();
    uInt ndone = 0;
    uInt nrow = 0;
    for (uInt i=0; i<nsets; i++) {
        NStarSetHeader* sethdr = itsSCN.getSetHeader(i*itsNrChans + chanSeqnr);
        Double haStart = sethdr->getHAB();
        uInt nscan = itsNrScansPerSet[i];
        for (uInt j=0; j<nscan; j++) {
            NStarScan scanhdr;
            Float mymax = 0;
            Float aScal = 1;
            Short* aBuf = 0;
            if (itsScanRows[ndone].nelements() == 0) {
                // We need to insert a dummy scan.
                // Note that the first scan is never dummy, so nrow always
                // contains a valid value.
                aBuf = new Short[nrow*itsNrCorrs*3];
                Short* aBufPtr = aBuf;
                for (uInt k=0; k<nrow; k++) {
                    for (uInt p=0; p<itsNrCorrs; p++) {
                        *aBufPtr++ = 0;                          // deleted
                        *aBufPtr++ = -32768;
                        *aBufPtr++ = -32768;
                    }
                }
            } else {
                nrow = itsScanRows[ndone].nelements();
                const Int* rows = itsScanRows[ndone].storage();
                // If needed multiply all values by the TRX of the antennas
                // of the X or Y dipole.
                uInt k;
                if (applyTRX) {
                    for (k=0; k<nrow; k++) {
                        Int row = rows[k];
                        Complex trx1 = itsTrx(itsAnt1(row),ndone);
                        Complex trx2 = itsTrx(itsAnt2(row),ndone);
                        Float* ptr = fdata + nrp*row;
                        switch (itsNrCorrs) {
                        case 4:    // XX XY YX YY
                          {
                            Float factxx = 10 * sqrt (trx1.real()*trx2.real());
                            Float factxy = 10 * sqrt (trx1.real()*trx2.imag());
                            Float factyx = 10 * sqrt (trx1.imag()*trx2.real());
                            Float factyy = 10 * sqrt (trx1.imag()*trx2.imag());
                            *ptr++ *= factxx;
                            *ptr++ *= factxx;
                            *ptr++ *= factxy;
                            *ptr++ *= factxy;
                            *ptr++ *= factyx;
                            *ptr++ *= factyx;
                            *ptr++ *= factyy;
                            *ptr++ *= factyy;
                            break;
                          }
                        case 2:    // XX YY
                          {
                            Float factxx = 10 * sqrt (trx1.real()*trx2.real());
                            Float factyy = 10 * sqrt (trx1.imag()*trx2.imag());
                            *ptr++ *= factxx;
                            *ptr++ *= factxx;
                            *ptr++ *= factyy;
                            *ptr++ *= factyy;
                            break;
                          }
                        case 1:    // XX
                          {
                            Float fact;
                            if (itsPolX) {
                              fact = 10 * sqrt (trx1.real()*trx2.real());
                            } else {
                              fact = 10 * sqrt (trx1.imag()*trx2.imag());
                            }
                            *ptr++ *= fact;
                            *ptr++ *= fact;
                            break;
                          }
                        default:
                            throw (AipsError ("itsNrCorrs != 1,2,4"));
                        }
                    }
                }

                // Scale all autocorrelations down by 100.
                if (foundAutoCorr && autoCorr) {
                    for (k=0; k<nrow; k++) {
                      Int row1 = rows[k];
                      if (itsAnt1(row1)==itsAnt2(row1)) {
                        Float* ptr = fdata + nrp*row1;
                        for (uInt i=0; i<itsNrCorrs*2; i++){ 
                          *ptr++ *= 0.01;
                        }
                      }
                    }
                }
                

                // Calculate Max.
                //                mymax = abs(fdata[nrp * rows[0]]);
                //                for (k=0; k<nrow; k++) {
                //                  const Float* ptr = fdata + nrp*rows[k];
                //                  for (uInt p=0; p<nrp; p++) {
                //                    mymax = max (mymax, abs(*ptr));
                //                    ptr++;
                //                  }
                //                }
                
                // Calculate Max.
                mymax = 0; // Since using abs(data), mymax>0
                for (k=0; k<nrow; k++) {
                  const Float* ptr = fdata + nrp*rows[k];
                  const Bool* fptr = flagdata + itsNrCorrs*rows[k];
                  for (uInt p=0; p<nrp; p++) {
                    if (! *fptr) {
                      mymax = max (mymax, abs(*ptr));
                    }
                    ptr++;
                    if (p%2==1) fptr++;
                  }
                }
                // Nothing found, so all flagged; make mymax>0
                if (mymax<=0) mymax=1;
                
                // Calculate Scale-factor
		//                aScal = Float(Double(32760)/mymax);
                aScal = Float(Double(32760)/mymax * 0.9 );
                // Write data
                aBuf = new Short[nrow*itsNrCorrs*3];
                Short* aBufPtr = aBuf;
                for (k=0; k<nrow; k++) {
                    const Complex* ptr = cdata + itsNrCorrs*rows[k];
                    const Bool* fptr = flagdata + itsNrCorrs*rows[k];
                    for (uInt p=0; p<itsNrCorrs; p++) {
                        if (*fptr) {
                            *aBufPtr++ = 0;                   // deleted
                            *aBufPtr++ = -32768;
                            *aBufPtr++ = -32768;
                        } else {
                            *aBufPtr++ = 1;                   // weight
                            if (p == 2) {
                                // For YX flip sign of COS, for others SIN.
                                // Note the data is in WU, because the scale
                                // factor is setup that way.
                                *aBufPtr++ = -(Short)(ptr->real()*aScal);
                                *aBufPtr++ = (Short)(ptr->imag()*aScal);
                            } else {
                                *aBufPtr++ = (Short)(ptr->real()*aScal);
                                *aBufPtr++ = -(Short)(ptr->imag()*aScal);
                            }
                        }
                        ptr++;
                        fptr++;
                    }
                }
            }

            // Fill fields in scan header.
            scanhdr.setHA(haStart+Double(j)*itsHAInterval);        // Current HA
            scanhdr.setMAX(mymax*factor);
            scanhdr.setSCAL(factor/aScal - 1.);
            uLong pos = scanhdr.write (aBuf, nrow*itsNrCorrs*3, file);
            if (j == 0) {
                sethdr->setScan (pos, scanhdr.getSize() +
                                      nrow*itsNrCorrs*3*sizeof(Short));
            }
            delete [] aBuf;

            // Update the progress meter.
            progress++;
            progressMeter.update (progress);
            ndone++;
        }
    }
    const Complex* ccdata = cdata;
    data.freeStorage (ccdata,deleteIt);
    flags.freeStorage (flagdata,deleteFl);
}

void ConvertToSCN::fillIFH(Short aBand)
{
  Matrix<Float> dummyFloat(2,14);
  
  // reset Addresscounter
  itsIFHeader.setAddress(0);
  
  // CHAN  (SpectralWindowId+1)  but NOT for DZB Nominal
  if (isIVC) {
    aBand=aBand-1;
  }

  itsIFHeader.setCHAN(aBand);
  String anAsciiBand = String::toString(aBand);
  
  // get access to NFRA_TMS_PARAMETERS subtable
  AlwaysAssert (itsMS.keywordSet().isDefined("NFRA_TMS_PARAMETERS"),
                AipsError);
  Table tmsParm = itsMS.keywordSet().asTable("NFRA_TMS_PARAMETERS");
  // make an index for the NAME column in the NFRA_TMS_PARAMETERS subtable
  // and an accessor for the NAME field in its key area
  // make it possible to access the VALUE column
  ColumnsIndex nameIndex (tmsParm, "NAME");
  RecordFieldPtr<String> nameKey (nameIndex.accessKey(), "NAME");
  ROScalarColumn<String> valueCol(tmsParm, "VALUE");
  
  // Constant System Temperature (TSYSI)
  {
    if (isDCB) {
      *nameKey = "DCBCal-IF" + anAsciiBand + ".SystemTemp";

    } else if (isIVC) {
      if (isNominal) {
        *nameKey = "DZBCal-IF" + anAsciiBand + ".SystemTemp";
      } else {
        *nameKey = "DZB20Cal-IF" + anAsciiBand + ".SystemTemp";
      }
    } else {
      *nameKey = "DZBCalSet.SystemTemp";
    }
    Vector<uInt> rows=nameIndex.getRowNumbers();
    if (rows.nelements() > 0) {
      String str = valueCol(rows(0));
      // strip unit at end
      // fill pairs in dummy matrix
      str.gsub(" Kelvin","");
      Vector<String> vec = stringToVector(str);
      Float lo;
      if (vec.nelements() < 28) {
        cout << "Nr SystemTemp values" << vec.nelements()
             << " must be 28" << endl;
      } else {
        for (uInt i=0; i < 14; i++) {
          for (uInt j=0; j < 2; j++) {
            istringstream ifstr(vec(i*2+j).chars());
            ifstr >> lo;
            dummyFloat(j,i) = lo;
          }
        }
      }
      itsIFHeader.setTSYSI(dummyFloat);
    } else {
      if (isDCB) {
        cout << "DCBCal-IF" << aBand << ".SystemTemp not found" << endl;
      } else if (isIVC) {
        if (isNominal) {
          cout << "DZBCal-IF" << aBand << ".SystemTemp not found" << endl;
        } else {
          cout << "DZB20Cal-IF" << aBand << ".SystemTemp not found" << endl;
        }
      } else {
        cout << "DZBCalSet.SystemTemp not found" << endl;
      }
    }
  }
  
  // Constant Receiver Gain (RGAINI)
  {
    if (isDCB) {
      *nameKey = "DCBCal-IF" + anAsciiBand + ".GainFactor";
    } else if (isIVC) {
      if (isNominal) {
        *nameKey = "DZBCal-IF" + anAsciiBand + ".GainFactor";
      } else {
        *nameKey = "DZB20Cal-IF" + anAsciiBand + ".GainFactor";
      }
    } else {
      *nameKey = "DZBCalSet.GainFactor";
    }
    Vector<uInt> rows=nameIndex.getRowNumbers();
    if (rows.nelements() > 0) {
      String str = valueCol(rows(0));
      // strip value indicator at end
      // fill pairs in dummy matrix
      str.gsub(" Kelvin","");
      Vector<String> vec = stringToVector(str);
      Float lo;
      if (vec.nelements() < 28) {
        cout << "Nr GainFactor values" << vec.nelements()
             << " must be 28" << endl;
      } else {
        for (uInt i=0; i < 14; i++) {
          for (uInt j=0; j < 2; j++) {
            istringstream ifstr(vec(i*2+j).chars());
            ifstr >> lo;
            dummyFloat(j,i) = lo;
          }
        }
      }
      itsIFHeader.setRGAINI(dummyFloat);
    } else {
      if (isDCB) {
        cout << "DCBCal-IF" << aBand << ".GainFactor not found" << endl;
      } else if (isIVC) {
        if (isNominal) {
          cout << "DZBCal-IF" << aBand << ".GainFactor not found" << endl;
        } else {
          cout << "DZB20Cal-IF" << aBand << ".GainFactor not found" << endl;
        }
      } else {
        cout << "DZBCalSet.GainFactor not found" << endl;
      }
    }
  }
  
  // Constant Noise Temperature (TNOISEI)
  {
    if (isDCB) {
      *nameKey = "DCBCal-IF" + anAsciiBand + ".NoiseTemp";
    } else if (isIVC) {
      if (isNominal) {
        *nameKey = "DZBCal-IF" + anAsciiBand + ".NoiseTemp";
      } else {
        *nameKey = "DZB20Cal-IF" + anAsciiBand + ".NoiseTemp";
      }
    } else {
      *nameKey = "DZBCalSet.NoiseTemp";
    }
    Vector<uInt> rows=nameIndex.getRowNumbers();
    if (rows.nelements() > 0) {
      String str = valueCol(rows(0));
      // fill pairs in dummy matrix
      Vector<String> vec = stringToVector(str);
      Float lo;
      if (vec.nelements() < 28) {
        cout << "Nr NoiseTemp values" << vec.nelements()
             << " must be 28" << endl;
      } else {
        for (uInt i=0; i < 14; i++) {
          for (uInt j=0; j < 2; j++) {
            istringstream ifstr(vec(i*2+j).chars());
            ifstr >> lo;
            dummyFloat(j,i) = lo;
          }
        }
      }
      itsIFHeader.setTNOISEI(dummyFloat);
    } else {
      if (isDCB) {
        cout << "DCBCal-IF" << aBand << ".NoiseTemp not found" << endl;
      }else if (isIVC) {
        if (isNominal) {
          cout << "DZBCal-IF" << aBand << ".NoiseTemp not found" << endl;
        } else {
          cout << "DZB20Cal-IF" << aBand << ".NoiseTemp not found" << endl;
        }
      } else {
        cout << "DZBCalSet.NoiseTemp not found" << endl;
      }
    }
  }
}

void ConvertToSCN::prepareIFH()
{
  // Prepare the single pass fill-ins for the IFH struct
  
  // get access to NFRA.TMS.PARAMETERS subtable
  AlwaysAssert (itsMS.keywordSet().isDefined("NFRA_TMS_PARAMETERS"),
                AipsError);
  Table tmsParm = itsMS.keywordSet().asTable("NFRA_TMS_PARAMETERS");
  // make an index for the NAME column in the NFRA_TMS_PARAMETERS subtable
  // and an accessor for the NAME field in its key area
  // make it possible to access the VALUE column
  ColumnsIndex nameIndex (tmsParm, "NAME");
  RecordFieldPtr<String> nameKey (nameIndex.accessKey(), "NAME");
  ROScalarColumn<String> valueCol(tmsParm, "VALUE");
  
  // PRINCIPLE GAIN CORRECTION METHOD  (GCODE)
  
  if (isDCB) {
    *nameKey = "DCBReadout.GainCorrMethod";
    Vector<uInt> rows=nameIndex.getRowNumbers();
    if (rows.nelements() > 0) {
      String str = valueCol(rows(0));
      Short aGCode=0;
      if (str == "NS") {
        aGCode=1;
      } else if (str == "GN") {
        aGCode=2;
      } else if (str == "ST") {
        aGCode=3;
      }
      itsIFHeader.setGCODE(aGCode);
    } else {
      cout << "DCBReadout.GainCorrMethod not found." << endl;
    }
  } else {
    *nameKey = "DZBReadout.AmplitudeNorm";
    Vector<uInt> rows=nameIndex.getRowNumbers();
    if (rows.nelements() > 0) {
      String str = valueCol(rows(0));
      Short aGCode=0;
      if (str == "off") {
        aGCode=0;
      } else if (str == "TNoise") {
        aGCode=1;
      } else if (str == "ReceiverGain") {
        aGCode=2;
      } else if (str == "TSys") {
        aGCode=3;
      }
      itsIFHeader.setGCODE(aGCode);
    } else {
      cout << "DZBReadout.AmplitudeNorm not found." << endl;
    }
  }

  // Actual Gain Correction Method (GNCAL)
  // Make GNCal equal to GCode 
  { 
    Matrix<Short> gncal(2,14);
    gncal= itsIFHeader.getGCODE();
    itsIFHeader.setGNCAL(gncal);
  }

  // Total Power Integration Time  (TPINT)
  itsIFHeader.setTPINT(int(itsTimeInterval+0.5));

  // First HA App. (HAB)
  itsIFHeader.setHAB(min(itsHAStart));

  // HA Increment (HAI)
  itsIFHeader.setHAI(itsHAInterval);
  

  // # of IF/GAIN Phase Scans (NIF)
  itsIFHeader.setNIF(0);

  // HAB from IF block (IFHAB)
  itsIFHeader.setIFHAB(itsIFHeader.getHAB());
}

void ConvertToSCN::makeSysCal()
{
  // Scaling for dzb 
  Float aScale=1.;
  if (!isDCB) {
    aScale=1000;
  }

  // get reference to the file object.
  ofstream& aFile = itsSCN.getFile();

  ROMSSysCalColumns syscal (itsMS.sysCal());
  Vector<Double> times = syscal.time().getColumn();
  Vector<Int> spwids = syscal.spectralWindowId().getColumn();
  Vector<Int> ants = syscal.antennaId().getColumn();

  ROArrayColumn<Float> tpOnCol(itsMS.sysCal(),"NFRA_TPON");
  ROArrayColumn<Float> tpOffCol(itsMS.sysCal(),"NFRA_TPOFF");

  convertAntenna (ants);
  uInt nrows = ants.nelements();
  // Sort the id's in order of spectral window, time
  Bool deleteIt;
  const Int* spwidsCal = spwids.getStorage (deleteIt);
  const Double* timesCal = times.getStorage (deleteIt);
  const Int* antsCal = ants.getStorage (deleteIt);
  
  Sort sort;
  sort.sortKey (spwidsCal, TpInt);
  sort.sortKey (timesCal, TpDouble);
  Vector<uInt> index;
  sort.sort (index, nrows);
  
  // init the progressMeter
  // Update it in steps of 16 rows.
  ProgressMeter progressMeter(0, nrows, "", "", "", "");

  // Prepare the one time entries for the IFH struct
  prepareIFH();

  // Loop over all (sorted) rows. There is a row per band, antenna, time.
  Short lastBand = -1;
  Double lastTime = -1;
  Int nrtimes = 0;
  //  Vector<Float> tpon;
  //  Vector<Float> tpoff;

  Matrix<Float> tpon  = tpOnCol.getColumn();
  Matrix<Float> tpoff = tpOffCol.getColumn();
  Cube<Short> buf(2,2,14);           // on/off, pol, antenna
  for (uInt i=0; i<nrows; i++) {
    uInt inx = index(i);
    Int antId = antsCal[inx];
    // Only take data for telescopes 0..D.
    if (antId < 14) {
      Short band = spwidsCal[inx]+1;
      Double time = timesCal[inx];
      // Write the buffer when the time (or band) changes.
      if (band != lastBand  ||  time != lastTime) {
        if (lastTime >= 0) {
          aFile.write ((char*)(&(buf(0,0,0))),
                       buf.nelements() * sizeof(Short));
          nrtimes++;
        }

        // When the band changes, the current IFH header (if any)
        // has to be updated.
        // Thereafter a new one has to be created.
        if (band != lastBand) {
          if (lastBand >= 0) {
            // # of Total Power Scans (NTP)
            itsIFHeader.setNTP (nrtimes);
            itsIFHeader.write (aFile);
            // set ifh length && ptr in setheaders of correct band
            Int aSize = buf.nelements() * nrtimes * sizeof(Short) + 
                        itsIFHeader.getIFHSize();
            itsSCN.setIFHPtr (lastBand-1, itsIFHeader.getAddress(), aSize);
          }
          // initialize + write ifh
          fillIFH (band);
          itsIFHeader.write (aFile);
          lastBand = band;
          nrtimes = 0;
          lastTime = -1;
        }
        // initialize/check new timestep
        buf = 0;
        if (lastTime >= 0) {
          if (!near (time-lastTime, itsTimeInterval)) {
            cout << "Timestep " << lastTime-time << " in SYSCAL table "
                    "mismatches main timestep " << itsTimeInterval << endl;
          }
        }
        lastTime = time;
      }
      //      tpOnCol.get (inx, tpon);
      //      tpOffCol.get (inx, tpoff);
      buf(0,0,antId) = Short(tpoff(0,inx) * aScale + 0.5);
      buf(1,0,antId) = Short(tpon(0,inx)  * aScale + 0.5);
      buf(0,1,antId) = Short(tpoff(1,inx) * aScale + 0.5);
      buf(1,1,antId) = Short(tpon(1,inx)  * aScale + 0.5);
    }
    // Update the progress meter every 16 rows.
    if (i%16 == 0) {
      progressMeter.update (i);
    }
  }
  if (lastTime >= 0) {
    // write last timestamp (buf)
    aFile.write ((char*)(&(buf(0,0,0))), buf.nelements() * sizeof(Short));
    nrtimes++;
    // # of Total Power Scans (NTP)
    itsIFHeader.setNTP (nrtimes);
    itsIFHeader.write (aFile);
    // set ifh length && ptr in setheaders
    Int aSize = buf.nelements() * nrtimes * sizeof(Short) +
      itsIFHeader.getIFHSize();
    itsSCN.setIFHPtr (lastBand-1, itsIFHeader.getAddress(), aSize);
  }
}
