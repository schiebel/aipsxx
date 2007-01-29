//# MSFITSKeyword.cc: A keyword-like object used by ms2fits and fits2ms.
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
//# $Id: MSFITSKeyword.cc,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#include <MSFITSKeyword.h>
#include <casa/sstream.h>

#include <casa/namespace.h>
// Construct an MSFITSKeyword explicitly.
MSFITSKeyword::MSFITSKeyword (uInt anId,
			      const String& aName,
			      const String& aValue,
			      const String& aColumn) :
    itsId    (anId),
    itsName  (aName),
    itsValue (aValue),
    itsColumn(aColumn)
{}


// Construct an MSFITSKeyword from a Table keyword.
///MSFITSKeyword::MSFITSKeyword ()
///{}

// Construct an MSFITSKeyword from a TableColumn keyword.
///MSFITSKeyword::MSFITSKeyword ()
///{}

// Construct an MSFITSKeyword from a set of FITS keywords.
///MSFITSKeyword::MSFITSKeyword ()
///{}

// Copy constructor (full copy semantics).
MSFITSKeyword::MSFITSKeyword (const MSFITSKeyword& that) :
    itsId     (that.itsId),
    itsName   (that.itsName),
    itsValue  (that.itsValue),
    itsColumn (that.itsColumn)
{}

// Assignment.
MSFITSKeyword& MSFITSKeyword::operator= (const MSFITSKeyword& that)
{
    if (this != &that) {
	itsId     = that.itsId;
	itsName   = that.itsName;
	itsValue  = that.itsValue;
	itsColumn = that.itsColumn;
    }
    return *this;
}

MSFITSKeyword::~MSFITSKeyword()
{
    // empty
}

// Show the keyword attributes in a String.
String MSFITSKeyword::asString() const
{
    ostringstream buffer;
    buffer << "MSFITSKeyword with id = " << itsId
	   << ", name = " << itsName
	   << ", value = " << itsValue
	   << ", column = " << itsColumn;
    return buffer.str();
}

Record MSFITSKeyword::asRecord() const
{
    //
    // Start with an empty record.
    //
    Record aRecord;

    //
    // Convert the id to a String.
    //
    ostringstream buffer;
    buffer << itsId;
    String postfix(buffer.str());

    //
    // Compose the record field names.
    //
    String aName  ("MSKN"+postfix);
    String aValue ("MSKV"+postfix);

    //
    // Add two or three fields to the record.
    //
    aRecord.define(aName,itsName);
    aRecord.define(aValue,itsValue);
    if (isColumnKeyword()) {
	String aColumn("MSKC"+postfix);
	aRecord.define(aColumn,itsColumn);
    }
    return aRecord;
}

void MSFITSKeyword::append(Record& aRecord)
{
    aRecord.merge(asRecord());
}



