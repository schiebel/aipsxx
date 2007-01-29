//# MSFITSKeyword.h: A keyword-like object used by ms2fits and fits2ms.
//# Copyright (C) 1996,1997,2001,2002
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
//# $Id: MSFITSKeyword.h,v 19.5 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_MSFITSKEYWORD_H
#define APPSGLISH_MSFITSKEYWORD_H
 
//# Includes
#include <casa/aips.h>
#include <casa/BasicSL/String.h>
#include <casa/Containers/Record.h>

#include <casa/namespace.h>
// <summary>
// A keyword-like object used by ms2fits and fits2ms.
// </summary>

// <use visibility=local>

// <reviewed reviewer="" date="" tests="">
// </reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
//
// The MSFITSKeyword class has been created to simplify the
// conversions between AIPS++ MeasurementSets and MSFITS files.
//
// From the point of view of the MS, table and column keywords can be
// converted to or reconstructed from MSFITS keywords. In addition,
// various table and column properties can be encoded in the form of
// MSFITS keywords, so-called pseudo table or column keywords.
//
// In the MSFITS files, MSFITS keywords appear as indexed FITS keyword
// sets with names starting with "MSK". These sets can easily be
// converted to or constructed from MSFITS keywords.
//
// An MSFITS keyword has a unique identification number, a name, a
// String-type value, and optionally the name of an associated table
// column.
//
// </synopsis>

// <motivation>
// </motivation>

// <example>
// </example>

//# <todo asof="$DATE:$">
//# A List of bugs, limitations, extensions or planned refinements.
//# </todo>


class MSFITSKeyword
{
public:
    // Construct an MSFITSKeyword explicitly.
    MSFITSKeyword (uInt anId,
		   const String& aName,
		   const String& aValue,
		   const String& aColumn = " ");

    // Construct an MSFITSKeyword from a Table keyword.
///    MSFITSKeyword (const String& tableDescName);

    // Construct an MSFITSKeyword from a TableColumn keyword.
///    MSFITSKeyword (const String& table, const String& aColumn);

    // Construct an MSFITSKeyword from a set of FITS keywords.
///    MSFITSKeyword (const String& table, const String& aColumn);

    // Copy constructor (full copy semantics).
    MSFITSKeyword (const MSFITSKeyword& that);

    // Assignment.
    MSFITSKeyword& operator= (const MSFITSKeyword& that);

    ~MSFITSKeyword();

    // Get the id of the keyword.
    uInt id() const;

    // Get the name of the keyword.
    const String& name() const;

    // Get the value of the keyword.
    const String& value() const;

    // Get the name of the column associated with the keyword.
    const String& column() const;

    // Is this a Table column keyword?
    Bool isColumnKeyword() const;

    // Show the keyword attributes in a String.
    String asString() const;

    // Convert the keyword to a record of three fields.
    Record asRecord() const;

    // Convert and append to the specified record.
    void append(Record& aRecord);

private:
    // Identification number
    uInt   itsId;

    // Name
    String itsName;

    // Value
    String itsValue;

    // Name of associated table column (optional)
    String itsColumn;


    // Set the id of the keyword.
    void setId(uInt anId);

    // Set the name of the keyword.
    void setName(const String& aName);

    // Set the value of the keyword.
    void setValue(const String& aValue);

    // Set the name of the column associated with the keyword.
    void setColumn(const String& aColumn);

};



inline uInt MSFITSKeyword::id() const
{
    return itsId;
}

inline const String& MSFITSKeyword::name() const
{
    return itsName;
}

inline const String& MSFITSKeyword::value() const
{
    return itsValue;
}

inline const String& MSFITSKeyword::column() const
{
    return itsColumn;
}

inline Bool MSFITSKeyword::isColumnKeyword() const
{
    return  (itsColumn != " ");
}


inline void MSFITSKeyword::setId(uInt anId)
{
    itsId = anId;
}

inline void MSFITSKeyword::setName(const String& aName)
{
    itsName = aName;
}

inline void MSFITSKeyword::setValue(const String& aValue)
{
    itsValue = aValue;
}
inline void MSFITSKeyword::setColumn(const String& aColumn)
{
    itsColumn = aColumn;
}



#endif



