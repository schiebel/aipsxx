//# VLASourceFilter.cc:
//# Copyright (C) 1999,2000,2001
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
//# $Id: VLASourceFilter.cc,v 19.2 2004/08/25 05:49:30 gvandiep Exp $

#include <nrao/VLA/VLASourceFilter.h>
#include <nrao/VLA/VLALogicalRecord.h>
#include <casa/Exceptions/Error.h>
#include <casa/Logging/LogOrigin.h>
#include <casa/Logging/LogIO.h>
#include <casa/BasicMath/Math.h>
#include <casa/Utilities/Assert.h>

VLASourceFilter::VLASourceFilter()
  :itsSource(""),
   itsQual(INT_MIN)
{
  DebugAssert(ok(), AipsError);
}

VLASourceFilter::VLASourceFilter(const String& sourceName,
				 const Int sourceQual) 
  :itsSource(sourceName),
   itsQual(sourceQual)
{
  itsSource.upcase();
  DebugAssert(ok(), AipsError);
}

VLASourceFilter::VLASourceFilter(const VLASourceFilter& other) 
  :itsSource(other.itsSource),
   itsQual(other.itsQual)
{
  DebugAssert(ok(), AipsError);
}

VLASourceFilter::~VLASourceFilter() {
  DebugAssert(ok(), AipsError);
}

VLASourceFilter& VLASourceFilter::operator=(const VLASourceFilter& other) {
  if (this != &other) {
    itsSource = other.itsSource;
    itsQual = other.itsQual;
  }
  DebugAssert(ok(), AipsError);
  return *this;
}

Bool VLASourceFilter::passThru(const VLALogicalRecord& record) const {
//   cerr << "This record source name: |" << record.SDA().sourceName()
//        << "| \trequired source name: |" << itsSource << "|";
  if (!itsSource.empty() && !record.SDA().sourceName().matches(itsSource)) {
    return False;
  }
//     cerr << "source match" << endl;
//   } else {
//     cerr << " NO source match" << endl;
//   cerr << "This record source qualifier: |" << record.SDA().sourceQual()
//        << "| \trequired source qualifier: |" << itsQual << "|";
  if (itsQual != INT_MIN && itsQual != record.SDA().sourceQual()) {
//     cerr << "full match" << endl;
    return False;
  } 
  return True;
}

VLAFilter* VLASourceFilter::clone() const {
  DebugAssert(ok(), AipsError);
  VLASourceFilter* tmpPtr = new VLASourceFilter(*this);
  AlwaysAssert(tmpPtr != 0, AipsError);
  return tmpPtr;
}

Bool VLASourceFilter::ok() const {
  // The LogIO class is only constructed if an error is detected for
  // performance reasons. Both function static and file static variables
  // where considered and rejected for this purpose.
  if (!VLAFilter::ok()) return False; 
  if (itsSource.length() > 16) {
    LogIO logErr(LogOrigin("VLASourceFilter", "ok()"));
    logErr << LogIO::SEVERE 
	   << "The source name must have no more than 16 characters"
           << LogIO::POST;
    return False;
  }
  if (abs(itsQual) > SHRT_MAX && itsQual != INT_MIN) {
    LogIO logErr(LogOrigin("VLASourceFilter", "ok()"));
    logErr << LogIO::SEVERE 
	   << "The source qualifier has a bad value"
           << LogIO::POST;
    return False;
  }
  return True;
}

// Local Variables: 
// compile-command: "gmake VLASourceFilter"
// End: 
