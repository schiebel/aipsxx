//# ByteSource.cc: Class for read-only access to data in a given format
//# Copyright (C) 1996,1999,2001
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
//# $Id: ByteSource.cc,v 19.4 2004/11/30 17:50:16 ddebonis Exp $

#include <casa/IO/ByteSource.h>
#include <casa/BasicSL/String.h>
#include <casa/Exceptions/Error.h>
#include <casa/IO/TypeIO.h>

namespace casa { //# NAMESPACE CASA - BEGIN

ByteSource::ByteSource()
{}

ByteSource::ByteSource (TypeIO* typeIO, Bool takeOver)
: BaseSinkSource (typeIO, takeOver)
{    
    if (!isReadable()) {
	throw (AipsError ("ByteSource is not readable"));
    }
}

ByteSource::ByteSource (const ByteSource& source)
: BaseSinkSource (source)
{}

ByteSource& ByteSource::operator= (const ByteSource& source)
{
    BaseSinkSource::operator= (source);
    return *this;
}

ByteSource::~ByteSource()
{}


ByteSource& ByteSource::operator>> (Bool& value)
{
    itsTypeIO->read (1, &value);
    return *this;
}

ByteSource& ByteSource::operator>> (Char& value)
{
    itsTypeIO->read (1, &value);
    return *this;
}

ByteSource& ByteSource::operator>> (uChar& value)
{
    itsTypeIO->read (1, &value);
    return *this;
}

ByteSource& ByteSource::operator>> (Short& value)
{
    itsTypeIO->read (1, &value);
    return *this;
}

ByteSource& ByteSource::operator>> (uShort& value)
{
    itsTypeIO->read (1, &value);
    return *this;
}

ByteSource& ByteSource::operator>> (Int& value)
{
    itsTypeIO->read (1, &value);
    return *this;
}

ByteSource& ByteSource::operator>> (uInt& value)
{
    itsTypeIO->read (1, &value);
    return *this;
}

ByteSource& ByteSource::operator>> (Int64& value)
{
    itsTypeIO->read (1, &value);
    return *this;
}

ByteSource& ByteSource::operator>> (uInt64& value)
{
    itsTypeIO->read (1, &value);
    return *this;
}

ByteSource& ByteSource::operator>> (Float& value)
{
    itsTypeIO->read (1, &value);
    return *this;
}

ByteSource& ByteSource::operator>> (Double& value)
{
    itsTypeIO->read (1, &value);
    return *this;
}

ByteSource& ByteSource::operator>> (Complex& value)
{
    itsTypeIO->read  (1, &value);
    return *this;
}

ByteSource& ByteSource::operator>> (DComplex& value)
{
    itsTypeIO->read  (1, &value);
    return *this;
}

ByteSource& ByteSource::operator>> (String& value)
{
    itsTypeIO->read (1, &value);
    return *this;
}


void ByteSource::read (uInt nvalues, Bool* value)
{
    itsTypeIO->read (nvalues, value);
}

void ByteSource::read (uInt nvalues, Char* value)
{
    itsTypeIO->read (nvalues, value);
}

void ByteSource::read (uInt nvalues, uChar* value)
{
    itsTypeIO->read (nvalues, value);
}

void ByteSource::read (uInt nvalues, Short* value)
{
    itsTypeIO->read (nvalues, value);
}

void ByteSource::read (uInt nvalues, uShort* value)
{
    itsTypeIO->read (nvalues, value);
}

void ByteSource::read (uInt nvalues, Int* value)
{
    itsTypeIO->read (nvalues, value);
}

void ByteSource::read (uInt nvalues, uInt* value)
{
    itsTypeIO->read (nvalues, value);
}

void ByteSource::read (uInt nvalues, Int64* value)
{
    itsTypeIO->read (nvalues, value);
}

void ByteSource::read (uInt nvalues, uInt64* value)
{
    itsTypeIO->read (nvalues, value);
}

void ByteSource::read (uInt nvalues, Float* value)
{
    itsTypeIO->read (nvalues, value);
}

void ByteSource::read (uInt nvalues, Double* value)
{
    itsTypeIO->read (nvalues, value);
}

void ByteSource::read (uInt nvalues, Complex* value)
{
    itsTypeIO->read (nvalues, value);
}

void ByteSource::read (uInt nvalues, DComplex* value)
{
    itsTypeIO->read (nvalues, value);
}

void ByteSource::read (uInt nvalues, String* value)
{
    itsTypeIO->read (nvalues, value);
}

} //# NAMESPACE CASA - END

