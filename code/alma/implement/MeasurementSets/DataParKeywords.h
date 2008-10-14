//# DataParKeywords.h: Convert and process DATAPAR-ALMATI FITS keywords
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
//# $Id: DataParKeywords.h,v 19.4 2004/11/30 17:50:06 ddebonis Exp $

#ifndef ALMA_DATAPARKEYWORDS_H
#define ALMA_DATAPARKEYWORDS_H

#include <casa/aips.h>
#include <fits/FITS/fits.h>
#include <fits/FITS/fitsio.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MRadialVelocity.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/Vector.h>

#include <casa/namespace.h>
// <summary> 
// DataParKeywords: process DATAPAR-ALMATI FITS keywords
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="" demos="">

// <prerequisite>
//   <li> <linkto class="AlmaTI2MS">AlmaTI2MS</linkto> module
// </prerequisite>
//
// <etymology>
// From "DATAPAR-ALMATI" and keywords
// </etymology>
//
// <synopsis>
// This class processes and holds FITS keywords from the DATAPAR-ALMATI
// binary table extension, as defined in the ALMA-TI data format. This
// is a helper class for AlmaTI2MS.
// </synopsis>
//
// <example>
// <srcblock>
// </srcblock>
// </example>
//
// <motivation>
// Encapsulate all keyword processing and access for DATAPAR-ALMATI tables
// </motivation>
//
// <todo asof="01/09/15">
// (i) 
// </todo>

class DataParKeywords
{
 public:
  // Construct from a const FITS keyword list
  DataParKeywords(ConstFitsKeywordList& kwl);

  // Destructor
  ~DataParKeywords() {};
  
  // Data accessor methods
  //
  // Telescope name
  String telescopeName() {return itsTelescopeName;};

  // Scan number
  Int scanNum() {return itsScanNum;};

  // Observation number
  Int obsNum() {return itsObsNum;}

  // Observing date
  MEpoch date() {return itsDate;};

  // Time system (e.g. TT, TAI, UTC etc)
  String timeSys() {return itsTimeSys;};

  // Observing mode
  String obsMode() {return itsObsMode;}

  // Project id
  String projectId() {return itsProjectId;}

  // Number of antennas
  Int nAnt() {return itsNAnt;};

  // Number of basebands
  Int nBaseBand() {return itsNBaseBand;};

  // Number of channels
  Int nChan() {return itsNChan;};

  // Number of polarization receptors
  Int nReceptors() {return itsNReceptors;};

  // Number of polarization correlation products
  Int nPolznCorr() {return itsNPolznCorr;};

  // Number of side bands
  Int nSideBand() {return itsNSideBand;};

  // Number of FITS cross-correlation data tables per baseband
  Int nCorrTable() {return itsNCorrTable;};

  // Number of FITS auto-correlation data tables per baseband
  Int nAutoTable() {return itsNAutoTable;};

  // Doppler velocity applicable to the frequency axes in the
  // subsequent CORRDATA-ALMATI sub-tables
  MRadialVelocity dopVel() {return itsDopVel;};

  // Site position
  MPosition sitePosition() {return itsSitePosition;};

  // Source name
  String sourceName() {return itsSourceName;};

  // Calibrator code
  String calCode() {return itsCalCode;};

  // Source position
  MDirection sourceDirection() {return itsSourceDirection;};

  // Calibration mode
  String calMode() {return itsCalMode;};

 private:
  // Default constructor is prohibited - no useful object produced
  DataParKeywords();

  // Keyword values
  //
  // Telescope name
  String itsTelescopeName;

  // Scan number
  Int itsScanNum;

  // Observation number
  Int itsObsNum;

  // FITS observing date in ISO format
  String itsDateISO;

  // FITS time system (e.g. UTC, TAI etc)
  String itsTimeSys;

  // Observation date as Measure
  MEpoch itsDate;

  // Observing mode
  String itsObsMode;

  // Project id
  String itsProjectId;

  // Number of antennas
  Int itsNAnt;

  // Number of basebands
  Int itsNBaseBand;

  // Number of channels
  Int itsNChan;

  // Number of polarization receptors
  Int itsNReceptors;

  // Number of polarization correlation products
  Int itsNPolznCorr;

  // Number of side bands
  Int itsNSideBand;

  // Number of FITS cross-correlation data tables per baseband
  Int itsNCorrTable;

  // Number of FITS auto-correlation data tables per baseband
  Int itsNAutoTable;

  // Doppler velocity applicable to the frequency axes in the
  // subsequent CORRDATA-ALMATI sub-tables
  MRadialVelocity itsDopVel;

  // Site longitude (deg), latitude (deg) and elevation (m)
  Double itsSiteLong, itsSiteLat, itsSiteElev;

  // Site position
  MPosition itsSitePosition;

  // Source name
  String itsSourceName;

  // Calibrator code
  String itsCalCode;

  // Source right ascension and declination (deg) and mean equinox (y)
  Double itsRA, itsDEC;
  Float itsEquinox;

  // Source position as Measure
  MDirection itsSourceDirection;

  // Calibration mode;
  String itsCalMode;
};

#endif
