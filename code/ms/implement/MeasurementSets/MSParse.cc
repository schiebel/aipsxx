//# MSParse.cc: Classes to hold results from an ms grammar parser
//# Copyright (C) 1994,1995,1997,1998,1999,2000,2001,2003
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
//# $Id: MSParse.cc,v 19.6 2005/06/30 18:57:05 ddebonis Exp $

#include <ms/MeasurementSets/MSParse.h>
#include <casa/Exceptions/Error.h>
#include <casa/IO/AipsIO.h>
#include <casa/ostream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

const MeasurementSet* MSParse::ms_p = 0x0;

//# Default constructor.
MSParse::MSParse ()
{}

//# Constructor with given ms name.
MSParse::MSParse (const MeasurementSet* ms, const String& shorthand)
: shorthand_p (shorthand)
{
  ms_p = ms;
}

MSParse::MSParse (const MSParse& that)
: shorthand_p (that.shorthand_p)
{}

MSParse& MSParse::operator= (const MSParse& that)
{
    if (this != &that) {
        shorthand_p = that.shorthand_p;
    }
    return *this;
}

Bool MSParse::test (const String& str) const
{
    return (shorthand_p == str  ?  True : False);
}

String& MSParse::shorthand()
{
    return shorthand_p;
}

const MeasurementSet* MSParse::ms()
{
    return ms_p;
}

//# The AipsIO functions are needed for the list of MSParse, but
//# we do not support it actually.
AipsIO& operator<< (AipsIO& ios, const MSParse&)
{
    throw (AipsError ("AipsIO << MSParse& not possible"));
    return ios;
}
AipsIO& operator>> (AipsIO& ios, MSParse&)
{
    throw (AipsError ("AipsIO >> MSParse& not possible"));
    return ios;
}

} //# NAMESPACE CASA - END

