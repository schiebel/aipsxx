//# HDSDef.cc:
//# Copyright (C) 1997,1998,1999
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
//# $Id: HDSDef.cc,v 19.1 2004/08/25 05:49:26 gvandiep Exp $

#if defined(HAVE_HDS)
#include <npoi/HDS/HDSDef.h>
#include <casa/Utilities/Regex.h>
#include <dat_par.h>
#include <sae_par.h>

const Int HDSDef::SAI_OK = SAI__OK;
const String HDSDef::DAT_NOLOC = DAT__NOLOC;
const uInt HDSDef::DAT_SZLOC = DAT__SZLOC;
const uInt HDSDef::DAT_SZNAM = DAT__SZNAM;
const uInt HDSDef::DAT_SZTYP = DAT__SZTYP;

String HDSDef::name(HDSDef::Type nodeType) {
  String primitiveType;
  switch (nodeType) {
  case HDSDef::INTEGER:
    primitiveType = "_INTEGER"; break;
  case HDSDef::REAL:
    primitiveType = "_REAL"; break;
  case HDSDef::DOUBLE:
    primitiveType = "_DOUBLE"; break;
  case HDSDef::LOGICAL:
    primitiveType = "_LOGICAL"; break;
  case HDSDef::CHAR:
    primitiveType = "_CHAR"; break;
  case HDSDef::WORD:
    primitiveType = "_WORD"; break;
  case HDSDef::UWORD:
    primitiveType = "_UWORD"; break;
  case HDSDef::BYTE:
    primitiveType = "_BYTE"; break;
  case HDSDef::UBYTE:
    primitiveType = "_UBYTE"; break;
  default:
    primitiveType = "STRUCTURE";
  }
  return primitiveType;
}

HDSDef::Type HDSDef::type(const String & typeName) {
  const String canonicalCase = upcase(typeName);
  HDSDef::Type t;
  // Special case for _CHAR*n
  if (canonicalCase.length() > 6) {
    const Regex stringPattern(String("_CHAR\\*[1-9][0-9]*"));
    if (canonicalCase.matches(stringPattern)) return HDSDef::CHAR;
  }
  for (uInt i = 0; i < HDSDef::NUMBER_TYPES; i++) {
    t = (HDSDef::Type) i;
    if (canonicalCase.matches(HDSDef::name(t))) {
      return t;
    }
  }
  return HDSDef::STRUCTURE;
}

String HDSDef::name(HDSDef::IOMode mode) {
  String modeString;
  switch (mode) {
  case HDSDef::READ:
    modeString = "READ"; break;
  case HDSDef::WRITE:
    modeString = "WRITE"; break;
  case HDSDef::UPDATE:
    modeString = "UPDATE"; break;
  }
  return modeString;
}
#endif

// Local Variables: 
// compile-command: "gmake OPTLIB=1 HDSDef"
// End: 
