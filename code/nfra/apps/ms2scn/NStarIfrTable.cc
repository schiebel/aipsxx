//# NstarIfrTable.cc : class for access to Newstar IFR Table
//# Copyright (C) 1997,1998,2001,2002
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: NStarIfrTable.cc,v 19.2 2004/08/25 05:49:25 gvandiep Exp $

#include <casa/BasicSL/String.h>
#include <NStarIfrTable.h>
#include <casa/fstream.h>


// Constructor NStar IFR Tabel
NStarIfrTable::NStarIfrTable():itsAddress(0)
{
}

// Destructor NStar IFR TAble
NStarIfrTable::~NStarIfrTable()
{
}

// get Table address
uInt NStarIfrTable::getAddress()
{
    return itsAddress;
}

// write a File and return getAddress
uInt NStarIfrTable::getAddress(ofstream& aFile)
{
    if (!getAddress())
	{				// Not yet written
	    write(aFile);		// So write it now
	}
    return getAddress();
}

// Fill the interferometer codes
void NStarIfrTable::setIfrCodes(uInt nIfr, Int aValue)
{
    itsData[nIfr]=aValue;
}

// Write IFR-table in File
Bool NStarIfrTable::write(ofstream& aFile)
{
    if (itsAddress) {
	aFile.seekp(itsAddress,ios::beg);
    } else {
	aFile.seekp(0,ios::end);		// from end
	itsAddress=aFile.tellp();
    }
    aFile.write((char*)(&itsData),sizeof(itsData));
    return True;
}
