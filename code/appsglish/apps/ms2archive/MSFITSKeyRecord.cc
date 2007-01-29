//# <MSFITSKeyRecord.cc>: Container class for MSFITSKeywords
//# Copyright (C) 1996,1997,1998,2000,2001,2002,2004
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
//# $Id: MSFITSKeyRecord.cc,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#include <MSFITSKeyRecord.h>
#include <casa/sstream.h>

#include <casa/namespace.h>
//
// Construct an empty list of MSFITSKeywords.
//
MSFITSKeyRecord::MSFITSKeyRecord () :
    Record(),
    itsKeyID(0)
{
    cout << "MSFITSKeyRecord: constructed" << endl;
}

//
// Destructor.
//
MSFITSKeyRecord::~MSFITSKeyRecord ()
{
    cout << "MSFITSKeyRecord: destructed" << endl;
}

//
// Add an MSFITSKeyword to the list.
//
uInt MSFITSKeyRecord::add (const MSFITSKeyword& anMSK)
{
    itsKeyID++;
    merge(anMSK.asRecord());
    return itsKeyID;
}

//
// Add an MSFITSKeyword to the list, and return the index (0-based) of
// the newley defined keyword.
//
uInt MSFITSKeyRecord::add (const String& aName,
			   const String& aValue,
			   const String& aColumnName)
{
    itsKeyID++;
    MSFITSKeyword anMSK(itsKeyID,aName,aValue,aColumnName);
    merge(anMSK.asRecord());
    return itsKeyID;
}

//
// Add the information in a TableInfo object to the MSFITSKeyRecord, 
// and return the index (0-based) of the last newly defined keyword.
//
uInt MSFITSKeyRecord::add (const TableInfo& aTableInfo)
{
    //
    // Add the "pseudo" table keywords for storing the table.info
    // content (TYPE, SUBTYPE and README).
    //
    add("TYPE",aTableInfo.type());
    add("SUBTYPE",aTableInfo.subType());
    String value = aTableInfo.readme();
    if (value.length()>68) {
	cout << "aTableInfo.readme() longer than 68, truncated to 68." << endl;
	value = value(0,68);
    }
    add("README",value);
    return itsKeyID;
}
    
//
// Add the shape for an array column to the MSFITSKeyRecord, and
// return the index (0-based) of the newly defined keyword.
//
uInt MSFITSKeyRecord::add (const IPosition& aShape, const String& columnName)
{
    ostringstream tmpbuf;
    tmpbuf << "(";
    for (uInt k=0; k<aShape.nelements(); k++) {
	tmpbuf << aShape(k);
	if (k != aShape.nelements()-1) {
	    tmpbuf << ", ";
	}
    }
    tmpbuf << ")";
    add("SHAPE",String(tmpbuf),columnName);
    return itsKeyID;
}
    








