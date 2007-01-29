//# Unset.cc: Defines and tests for Unset records
//# Copyright (C) 1996,1999
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
//#
//# $Id: Unset.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/Unset.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishRecord.h>
#include <casa/BasicSL/String.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Test for the unset record
Bool Unset::isUnset(const GlishRecord& record)
{
  // Seems kind of long-winded 
  static String iamunset("i_am_unset");
  if(record.exists(iamunset)) {
    GlishValue candidate=record.get(iamunset);
    if(candidate.type()==GlishValue::ARRAY) {
      GlishArray val=candidate;
      if (val.nelements()== 1&&
	  val.elementType()== GlishArray::STRING) {
	String candidateString;
        val.get(candidateString);
        if(candidateString==iamunset) {
	  return True;
	}
      }
    }
  }
  return False;
};

// Make an unset record
GlishRecord Unset::unsetRecord()
{
  static String iamunset("i_am_unset");
  GlishRecord record;
  record.add(iamunset, iamunset);
  return record;
};

} //# NAMESPACE CASA - END

