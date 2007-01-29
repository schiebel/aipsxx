//# DataParKeywords.cc: Implementation of DataParKeywords.h
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
//# $Id: DataParKeywords.cc,v 19.2 2004/08/25 05:48:50 gvandiep Exp $
//----------------------------------------------------------------------------

#include <alma/MeasurementSets/DataParKeywords.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Quanta/MVEpoch.h>
#include <measures/Measures/MeasConvert.h>
#include <fits/FITS/FITSDateUtil.h>

//----------------------------------------------------------------------------

DataParKeywords::DataParKeywords(ConstFitsKeywordList& kwl) :
  itsTelescopeName(""),
  itsScanNum(0),
  itsObsNum(0),
  itsDateISO(""),
  itsTimeSys(""),
  itsDate(),
  itsObsMode(""),
  itsProjectId(""),
  itsNAnt(0),
  itsNBaseBand(0),
  itsNChan(0),
  itsNReceptors(0),
  itsNPolznCorr(0),
  itsNSideBand(0),
  itsNCorrTable(0),
  itsNAutoTable(0),
  itsDopVel(),
  itsSiteLong(0),
  itsSiteLat(0),
  itsSiteElev(0),
  itsSitePosition(),
  itsSourceName(""),
  itsCalCode(""),
  itsRA(0),
  itsDEC(0),
  itsEquinox(0),
  itsSourceDirection(),
  itsCalMode("")
{
// Construct from a FITS keyword list
// Input:
//    kwl            ConstFitsKeywordList&      Input FITS keyword list
// Output to private data:
//    itsTelescopeName   String          Telescope name
//    itsScanNum         Int             Scan number
//    itsObsNum          Int             Observation number
//    itsDateISO         String          FITS observing date in ISO format
//    itsTimeSys         String          FITS time system (e.g. TAI, UTC etc)
//    itsDate            MEpoch          Observing date as Measure
//    itsObsMode         String          Observing mode
//    itsProjectId       String          Project id.
//    itsNAnt            Int             Number of antennas
//    itsNBaseBand       Int             Number of basebands
//    itsNChan           Int             Number of channels
//    itsNReceptors      Int             Number of polarization receptors
//    itsNPolznCorr      Int             Number of polarization correlations
//    itsNSideBand       Int             Number of side bands
//    itsNCorrTable      Int             Number of FITS cross-corr. data tables
//    itsNAutoTable      Int             Number of FITS auto-corr. data tables
//    itsDopVel          MRadialVelocity Doppler vel. for CORRDATA freq. axes
//    itsSiteLong        Double          Site longitude (deg)
//    itsSiteLat         Double          Site latitude (deg)
//    itsSiteElev        Double          Site elevation (m)
//    itsRA              Double          Right ascension (deg) at ME
//    itsDEC             Double          Declination (deg) at ME
//    itsEquinox         Float           Mean equinox (y) (ME)
//    itsSitePosition    MPosition       Site position
//    itsSourceName      String          Source name
//    itsCalCode         String          Calibration code
//    itsSourceDirection MDirection      Source position
//    itsCalMode         String          Calibration mode
//
  // Translate the input FITS keyword list
  const FitsKeyword* kw;

  // Iterate through, extracting relevant keywords
  kwl.first();

  while ((kw = kwl.next())) {

    String kwname = kw->name();

    // Case keyword name of:
    //
    // TELESCOP
    if (kwname == "TELESCOP") {
      itsTelescopeName = kw->asString();

      // SCAN-NUM
    } else if (kwname == "SCAN-NUM") {
      itsScanNum = kw->asInt();

      // OBS-NUM
    } else if (kwname == "OBS-NUM") {
      itsObsNum = kw->asInt();

      // DATE-OBS
    } else if (kwname == "DATE-OBS") {
      itsDateISO = kw->asString();

      // TIMESYS
    } else if (kwname == "TIMESYS") {
      itsTimeSys = kw->asString();

      // Create MEpoch from FITS date in ISO format
      MVTime mvTime;
      MEpoch::Types epochType;
      FITSDateUtil::fromFITS(mvTime, epochType, itsDateISO, itsTimeSys);
      MVEpoch mvEpoch(mvTime);
      MEpoch::Ref epochRef(epochType);
      itsDate.set(mvEpoch, epochRef);

      // OBSMODE
    } else if (kwname == "OBSMODE") {
      itsObsMode = kw->asString();

      // PROJID
    } else if (kwname == "PROJID") {
      itsProjectId = kw->asString();

      // NO_ANT
    } else if (kwname == "NO_ANT") {
      itsNAnt = kw->asInt();

      // NO_BAND
    } else if (kwname == "NO_BAND") {
      itsNBaseBand = kw->asInt();

      // NO_CHAN
    } else if (kwname == "NO_CHAN") {
      itsNChan = kw->asInt();

      // NO_POL
    } else if (kwname == "NO_POL") {
      itsNReceptors = kw->asInt();

      // NO_STK
    } else if (kwname == "NO_STK") {
      itsNPolznCorr = kw->asInt();

      // NO_SIDE
    } else if (kwname == "NO_SIDE") {
      itsNSideBand = kw->asInt();

      // NO_CORR
    } else if (kwname == "NO_CORR") {
      itsNCorrTable = kw->asInt();

      // NO_AUTO
    } else if (kwname == "NO_AUTO") {
      itsNAutoTable = kw->asInt();

      // VFRAME
    } else if (kwname == "VFRAME") {
      itsDopVel = MRadialVelocity(Quantity(kw->asDouble(),"m/s"), 
				  MRadialVelocity::LSRK);

      // SITELONG or OBS-LONG
    } else if (kwname == "SITELONG" || kwname == "OBS-LONG") {
      itsSiteLong = kw->asDouble();

      // SITELAT or OBS-LAT
    } else if (kwname == "SITELAT" || kwname == "OBS-LAT") {
      itsSiteLat = kw->asDouble();

      // SITEELEV or OBS-ELEV
    } else if (kwname == "SITEELEV" || kwname == "OBS-ELEV") {
      itsSiteElev = kw->asDouble();

      // Create site position as Measure
      Quantity elevation(itsSiteElev, "m");
      Quantity longitude(itsSiteLong, "deg");
      Quantity latitude(itsSiteLat, "deg");
      MVPosition mvPosition(elevation, longitude, latitude);

      // Force site position to ITRF, as will be assumed elsewhere
      MPosition mPos = MPosition::Convert(MPosition(mvPosition,MPosition::WGS84),
					  MPosition::Ref(MPosition::ITRF))();
      // ITRF is default MPosRef
      itsSitePosition.set(mPos.getValue());

      // SOURCE
    } else if (kwname == "SOURCE") {
      itsSourceName = kw->asString();
      
      // CALCODE
    } else if (kwname == "CALCODE") {
      itsCalCode = kw->asString();

      // RA
    } else if (kwname == "RA") {
      itsRA = kw->asDouble();

      // DEC
    } else if (kwname == "DEC") {
      itsDEC = kw->asDouble();

      // EQUINOX
    } else if (kwname == "EQUINOX") {
      itsEquinox = kw->asFloat();

      // Create source position as Measure
      Quantity ra(itsRA, "deg");
      Quantity dec(itsDEC, "deg");
      MVDirection mvPos(ra, dec);
      MDirection::Ref dirRef(MDirection::J2000);
      if (itsEquinox == 1950) dirRef.set(MDirection::B1950);
      itsSourceDirection.set(mvPos, dirRef);

      // CALMODE
    } else if (kwname == "CALMODE") {
      itsCalMode = kw->asString();
    };
  };
};

//----------------------------------------------------------------------------
