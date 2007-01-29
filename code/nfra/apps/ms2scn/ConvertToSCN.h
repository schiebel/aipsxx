//# ConvertToSCN.h : class for conversion from MeasurementSet to Newstar Scan File
//# Copyright (C) 1997,1998,1999,2000,2001,2002
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
//# $Id: ConvertToSCN.h,v 19.5 2004/11/30 17:50:39 ddebonis Exp $

#if !defined(AIPS_CONVERTTOSCN_H)
#define AIPS_CONVERTTOSCN_H
 

//# Includes
#include <NStarFileType.h>
#include <NStarGeneralFileHeader.h>
#include <NStarSet.h>
#include <NStarFile.h>
#include <NStarSetHeader.h>
#include <NStarScan.h>
#include <NStarIfrTable.h>
#include <NStarIFHeader.h>
#include <casa/OS/Path.h>
#include <casa/OS/File.h>
#include <casa/BasicSL/String.h>
#include <casa/Containers/List.h>
#include <casa/Containers/ListIO.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MeasurementSets/MSColumns.h>
#include <casa/Quanta/MVAngle.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Quanta/Quantum.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MEpoch.h>

#include <casa/namespace.h>

//# Forward Declarations
namespace casa {
   class ProgressMeter;
}


class ConvertToSCN
{
public:
  
  // Constructor Convert to SCN
  ConvertToSCN(MeasurementSet& aMS, const Path& aFile);
  
  // Destructor Convert to SCN
  ~ConvertToSCN();
  
  // Loop over MS and setup some global information.
  // Only the given spectral window id will be used.
  // -1 means all spectral windows.
  Bool prepare (Bool applyTRX, Bool autoCorr, Int spwid);
  
  // Select a single channel to convert
  void setChannel(Int aChannel);
  
  // Loop over then number of bands and create set-header,
  // adding them to itsSCN.
  // Apply the given correction factor to the data.
  Bool convert (Double haIncr, Double corrFactor, Bool applyTRX,
		Bool showCache, Bool addSysCal, Bool autoCorr);
  
  // Invoke write() on itsSCN
  Bool write();
  
private:
  
  // Fill itsTrx from the TRX values in the SYSCAL subtable.
  void fillTrx (const Int* spwidsData, const Double* timesData);
  
  // Fill the telescope positions and mapping of antenna to telescope.
  void fillTelPos();
  
  // Convert the anntenna-id's in the vector to telescope-id's.
  void convertAntenna (Vector<Int>&);
  
  // Fill the fields in the Set header which are common for all
  // spectral windows and channels.
  NStarSetHeader* makeSet(Int nrscans, Double haStart, Int fieldid);
  
  // Complete the set for a given channel.
  NStarSetHeader* makeChanSet(uInt channel, Int spwid,
			      const NStarSetHeader& sethdr);
  
  // make Scan
  void makeScans(Bool applyTRX, Double corrFactor, uInt channel,
		 ProgressMeter& progressMeter, uInt& progress, Bool autoCorr);
  
  // Fill the starting HA from the starting time for all fields.
  // Use the RA/DEC of the given field.
  void fillHAStart (Double startTime, const String& timeUnit);
  
  // Calculate the rotation angle of dir to the given epoch.
  Double calcPhi (const MDirection& dir, const Quantity& epoch);
  
  // Check the time intervals and insert dummy scans if needed and possible.
  // Return the common time interval found (in seconds).
  // Set itsTimeInterval (in units used in MS).
  Double checkTimeIntervals (const Double* timesData, const String& timeUnit);
  
  // fill syscal
  void makeSysCal();
  
  // prepare IFHeader struct
  void prepareIFH();
  
  // fill rest IFHeader struct
  void fillIFH(Short aBand);
  
  // MeasurementSet
  MeasurementSet itsMS;

  // flag for multiplicity
  // 0 = no multiplicity
  // 1 = MultiFreqDZB
  // 2 = MultiPointDZB
  uInt itsMulti;

  // flag for mosaic
  //    0 = No mosaicing
  //    1 = freq. mosaicing
  //    2 = pos. mosaicing
  uInt itsMosaic;

  // integration time
  uInt itsIntTime;
  
  // The SCN file
  NStarFile itsSCN;

  // All interferometers
  NStarIfrTable itsIfrTable;
  
  // SysCal Header
  NStarIFHeader itsIFHeader;
  
  // # of interferometers
  uInt itsNrIfrs;
  
  // # of correlations
  uInt itsNrCorrs;
  
  // # of freq. channels
  Int itsNrChans;
  
  // is it a DCB observation
  Bool isDCB;

  // is it an IVC observation
  Bool isIVC;
  
  // is it a DZB Nominal observation
  Bool isNominal;
  
  // is an X polarization given?
  Bool itsPolX;
  
  // # of scans
  uInt itsNrScans;
  
  // # of scans per set
  Block<Int> itsNrScansPerSet;
  
  // The row numbers of each scan
  Block<Block<Int> > itsScanRows;
  
  // Antenna1/2 in each row.
  Vector<Int> itsAnt1;
  Vector<Int> itsAnt2;
  
  // The TRX value for each antenna/scan.
  Matrix<Complex> itsTrx;
  
  // Mapping of antenna-id to telescope.
  // itsAntMap(j) gives telescope of antenna-id j.
  IPosition itsAntMap;
  
  // Telescope positions.
  Vector<Float> itsTelPos;
  
  // Starting time and hour-angle of observation.
  // The start hour-angle is per field.
  Double itsTimeStart;            // in units as used in MS
  Vector<Double> itsHAStart;      // in circles

  // Time and hour-angle interval
  Double itsTimeInterval;         // in units as used in MS
  Double itsHAInterval;           // in circles

  Double itsRestFreq;
  Double itsRefVel;
  Int    itsVelc;
  
  // Get access to the columns of the subtables
  ROMSColumns itsMsc;
  //    ROMSAntennaColumns itsAntc;
  //    ROMSArrayColumns itsArrc;
  //    ROMSFeedColumns itsFeedc;
  ROMSFieldColumns itsFieldc;
  //    ROMSObservationColumns itsObsc;
  //    ROMSObsLogColumns itsObslogc;
  //    ROMSSpWindowColumns itsSpwinc;
  //    ROMSSysCalColumns itsSysCalc;
  //    ROMSWeatherColumns itsWeathc;
  
  // The mapping of DataDescId to SpectralWindowId.
  Vector<Int> itsSpwidMap;
  
  // The frequency info from SpectralWindow table.
  Matrix<Double> itsResolution;
  Matrix<Double> itsChanFreq;
  Vector<Double> itsRefFreq;
  
  // First channel to convert.
  Int itsFirstChannel;    
  
  // The volgnr of the observation.
  Int itsVolgnr;

  // is autoCorrelatian found ?
  Bool foundAutoCorr;

};


#endif









