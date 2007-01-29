//# MerlinEnum.cc:
//# Copyright (C) 1999,2000
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
//# $Id: MerlinEnum.cc,v 19.2 2004/08/25 05:49:26 gvandiep Exp $

//#include <nrao/VLA/VLAEnum.h>
#include <nral/JBO/MerlinEnum.h>
#include <casa/BasicSL/String.h>

String MerlinEnum::name(MerlinEnum::CorrMode modeEnum) {
  switch (modeEnum) {
  case MerlinEnum::CONTINUUM: 
    return " ";
  case MerlinEnum::A: 
    return "1A";
  case MerlinEnum::B: 
    return "1B";
  case MerlinEnum::C: 
    return "1C";
  case MerlinEnum::D: 
    return "1D";
  case MerlinEnum::AB: 
    return "2AB";
  case MerlinEnum::AC: 
    return "2AC";
  case MerlinEnum::AD: 
    return "2AD";
  case MerlinEnum::BC: 
    return "2BC";
  case MerlinEnum::BD: 
    return "2BD";
  case MerlinEnum::CD: 
    return "2CD";
  case MerlinEnum::ABCD: 
    return "4";
  case MerlinEnum::PA: 
    return "PA";
  case MerlinEnum::PB: 
    return "PB";
  default:
    return "Unknown correlator mode";
  };
}

MerlinEnum::CorrMode MerlinEnum::corrMode(const String& modeString) {
  String canonicalCase(modeString);
  canonicalCase.upcase();
  MerlinEnum::CorrMode m;
  for (uInt i = 0; i < NUMBER_MODES; i++) {
    m = MerlinEnum::CorrMode(i);
    if (canonicalCase.matches(MerlinEnum::name(m))) {
      return m;
    }
  }
  return MerlinEnum::UNKNOWN_MODE;
}

// Local Variables: 
// compile-command: "gmake MerlinEnum"
// End: 
