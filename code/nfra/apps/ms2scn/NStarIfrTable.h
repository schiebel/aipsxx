//# NstarIfrTable.h : class for access to Newstar IFR Table
//# Copyright (C) 1997,1998,2001
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
//# $Id: NStarIfrTable.h,v 19.3 2004/11/30 17:50:39 ddebonis Exp $

#ifndef NFRA_NSTARIFRTABLE_H
#define NFRA_NSTARIFRTABLE_H
 

//# Includes
#include <casa/aips.h>
#include <casa/iosfwd.h>
#include <casa/namespace.h>

// # of telescopes
const Int STHTEL = 16;
// Max. # of interferometers
const Int STHIFR = STHTEL*(STHTEL+1)/2;


class NStarIfrTable
{
public:

    // Constructor NStar Set
    NStarIfrTable();

    // Destructor NStar Set
    ~NStarIfrTable ();

    // get Table address
    uInt getAddress();

    // write a File and return getAddress
    uInt getAddress(std::ofstream& aFile);

    // Fill the interferometer codes
    void setIfrCodes(uInt nIfr, Int aValue);

    // Write GFH in File
    Bool write(std::ofstream& aFile);

private:

    // Table address
    uInt itsAddress;

    // Interferometer codes
    Short itsData[STHIFR];

};


#endif
