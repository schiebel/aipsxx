//# <MSFITSKeyRecord.h>: Container class of MSFITSKeywords.
//# Copyright (C) 1996,1997
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
//# $Id: MSFITSKeyRecord.h,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_MSFITSKEYRECORD_H
#define APPSGLISH_MSFITSKEYRECORD_H

#include <casa/aips.h>
#include <casa/Containers/Record.h>
#include <tables/Tables/TableInfo.h>
#include <MSFITSKeyword.h>

#include <casa/namespace.h>

// <summary>
// Container class of MSFITSKeywords.
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class=MSFITSKeyword>MSFITSKeywords</linkto>
// </prerequisite>

// <etymology>
// </etymology>

// <synopsis>

// MSFITSKeyRecord is a special kind of Record, that essentially
// contains a list of MSFITSKeywords. It serves as a repository for
// those keywords that can be passed through the various conversion
// functions.

//  </synopsis>

// <example>
// <srcblock>
// </srcblock>
// </example>

// <motivation>
// Make conversions between MeasurementSets and Binary FITS files easier.
// </motivation>

// <todo asof="1998/03/09">
//   values.

// </todo>

class MSFITSKeyRecord : public Record
{
public:
    //
    // Construct an empty list of MSFITSKeywords.
    //
    MSFITSKeyRecord ();

    //
    // Destruct; nothing special for now.
    //
    ~MSFITSKeyRecord ();

    //
    // Add the given MSFITSKeyword to the list, and return the index
    // (0-based) of the newly defined keyword.
    //
    uInt add (const MSFITSKeyword& anMSK);
    
    //
    // Add an MSFITSKeyword to the list, and return the index
    // (0-based) of the newly defined keyword. An MSFITSKeyword is
    // characterized by an id, a name, a value and a column name
    // (blank if there is no column associated with the keyword).
    //
    uInt add (const String& aName,
	      const String& aValue,
	      const String& aColumnName=" ");

    //
    // Add the information in a TableInfo object to the MSFITSKeyRecord, 
    // and return the index (0-based) of the last newly defined keyword.
    //
    uInt add (const TableInfo& aTableInfo);
    
   //
   // Add the shape for an array column to the MSFITSKeyRecord, and
   // return the index (0-based) of the newly defined keyword.
   //
    uInt add (const IPosition& aShape,
	      const String& columnName);

private:
    //
    // Attributes.
    //
    uInt itsKeyID;      //# current ID for the keywords
};

#endif







