//# MSAntennaIndex.cc: implementation of MSAntennaIndex.h
//# Copyright (C) 2000,2001,2002
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
//# $Id: MSAntennaIndex.cc,v 19.8 2006/09/28 07:03:46 sbhatnag Exp $

#include <ms/MeasurementSets/MSAntennaIndex.h>
#include <casa/Arrays/MaskedArray.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayUtil.h>
#include <casa/Utilities/Regex.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//-------------------------------------------------------------------------

MSAntennaIndex::MSAntennaIndex(const MSAntenna& antenna)
  : msAntennaCols_p(antenna)
{ 
// Construct from an MS ANTENNA subtable
// Input:
//    antenna           const MSAntenna&           Input MSAntenna object
// Output to private data:
//    msAntennaCols_p   ROMSAntennaColumns         MSAntenna columns accessor
//    antennaIds_p      Vector<Int>                Antenna id's
//    nrows_p           Int                        Number of rows
//
  // Generate an array of antenna id's, used in later queries
  nrows_p = msAntennaCols_p.nrow();
  antennaIds_p.resize(nrows_p);
  indgen(antennaIds_p);
};

//-------------------------------------------------------------------------

Vector<Int> MSAntennaIndex::matchAntennaRegexOrPattern(const String& pattern,
						       const Bool regex)
{
// Match a regular expression or pattern to a set of antenna id's
// Input:
//    pattern            const String&            Pattern/regular expression 
//                                                for Antenna name to match
// Output:
//    matchAntennaName   Vector<Int>              Matching antenna id's
//
  Int pos=0;
  Regex reg;
  if (regex) reg=pattern;
  else       reg=reg.fromPattern(pattern);

  //  cerr << "Pattern = " << pattern << "  Regex = " << reg.regexp() << endl;
  IPosition sh(msAntennaCols_p.name().getColumn().shape());
  LogicalArray maskArray(sh,False);
  IPosition i=sh;
  for(i(0)=0;i(0)<sh(0);i(0)++)
    {
      //Int ret=(msAntennaCols_p.name().getColumn()(i).find(reg,pos));
      Int ret=(msAntennaCols_p.name().getColumn()(i).matches(reg,pos));
      //      cerr << i << " " << ret << endl;
      maskArray(i) = ( (ret>0) &&
		      !msAntennaCols_p.flagRow().getColumn()(i));
    }
  
  MaskedArray<Int> maskAntennaID(antennaIds_p,maskArray);
  return maskAntennaID.getCompressedArray();
}; 

//-------------------------------------------------------------------------

Vector<Int> MSAntennaIndex::matchAntennaName(const String& name)
{
// Match a antenna name to a set of antenna id's
// Input:
//    name               const String&            Antenna name to match
// Output:
//    matchAntennaName   Vector<Int>              Matching antenna id's
//
  if(name == "*") {
    LogicalArray maskArray = (True &&
			      !msAntennaCols_p.flagRow().getColumn());
    MaskedArray<Int> maskAntennaId(antennaIds_p, maskArray);
    return maskAntennaId.getCompressedArray();
  } else {
    LogicalArray maskArray = (msAntennaCols_p.name().getColumn()==name &&
			      !msAntennaCols_p.flagRow().getColumn());
    MaskedArray<Int> maskAntennaId(antennaIds_p, maskArray);

    return maskAntennaId.getCompressedArray();
  }
}; 

//-------------------------------------------------------------------------

Vector<Int> MSAntennaIndex::matchAntennaName(const Vector<String>& names)
{
// Match a set of antenna names to a set of antenna id's
// Input:
//    names              const Vector<String>&    Antenna names to match
// Output:
//    matchAntennaNames  Vector<Int>              Matching antenna id's
//
  Vector<Int> matchedAntennaIds;
  // Match each antenna name individually
  for (uInt fld=0; fld<names.nelements(); fld++) {
    // Add to list of antenna id's
    Vector<Int> currentMatch = matchAntennaName(names(fld));
    if (currentMatch.nelements() > 0) {
      Vector<Int> temp(matchedAntennaIds);
      matchedAntennaIds.resize(matchedAntennaIds.nelements() +
			     currentMatch.nelements(), True);
      matchedAntennaIds = concatenateArray(temp, currentMatch);
    };
  };
  return matchedAntennaIds;
};

//-------------------------------------------------------------------------

Vector<Int> MSAntennaIndex::matchAntennaStation(const String& station)
{
// Match a antenna station to a set of antenna id's
// Input:
//    station               const String&         Antenna station to match
// Output:
//    matchAntennaStation   Vector<Int>              Matching antenna id's
//
  if(station.contains('*')) {
    String subStationName = station.at(0, station.length()-1);
    Vector<String> stationNames = msAntennaCols_p.station().getColumn();
    uInt len = stationNames.nelements();
    Vector<Bool> matchstationnames(len, False);
    for(uInt j = 0; j < len; j++) {
      if(stationNames[j].contains(subStationName))
	matchstationnames(j) = True;
    }
    LogicalArray maskArray( matchstationnames && !msAntennaCols_p.flagRow().getColumn());
    MaskedArray<Int> maskAntennaId(antennaIds_p, maskArray);
    return maskAntennaId.getCompressedArray();
  }else {
    LogicalArray maskArray = (msAntennaCols_p.station().getColumn()==station &&
			      !msAntennaCols_p.flagRow().getColumn());
    MaskedArray<Int> maskAntennaId(antennaIds_p, maskArray);
    return maskAntennaId.getCompressedArray();
  }
}; 

//-------------------------------------------------------------------------

Vector<Int> MSAntennaIndex::matchAntennaNameAndStation(const String& name,
						       const String& station)
{
// Match a antenna and station name pair to a set of antenna id's
// Input:
//    name                         const String&  Antenna name to match
//    station                      const String&  Station name to match
// Output:
//    matchAntennaNameAndStation   Vector<Int>    Matching antenna id's
//
  LogicalArray maskArray = (msAntennaCols_p.name().getColumn()==name &&
			    msAntennaCols_p.station().getColumn()==station &&
			    !msAntennaCols_p.flagRow().getColumn());
  MaskedArray<Int> maskAntennaId(antennaIds_p, maskArray);
  return maskAntennaId.getCompressedArray();
}; 

//-------------------------------------------------------------------------


} //# NAMESPACE CASA - END

