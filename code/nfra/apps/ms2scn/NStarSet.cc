//# NStarSet.cc: class for the standard beginning of any standard Set Header
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
//# $Id: NStarSet.cc,v 19.2 2004/08/25 05:49:25 gvandiep Exp $

#include <NStarSet.h>
#include <casa/BasicSL/String.h>
#include <casa/fstream.h>


// Constructor NStarSet
NStarSet::NStarSet()
: itsAddress(0)
{
    itsSet.LINK[0]=0;
    itsSet.LINK[1]=0;
    itsSet.LEN=sizeof(itsSet);
    itsSet.VER=4;
    itsSet.SETN=0;
}

// Destructor NStar Set
NStarSet::~NStarSet()
{
    ;
}

// set LINK
void NStarSet::setLINK(const Vector<Int>& aLink)
{
    itsSet.LINK[0] = aLink(0);
    itsSet.LINK[1] = aLink(1);
}
 
// get LINK
Vector<Int> NStarSet::getLINK()
{
    Vector<Int> tmp(2);
    tmp(0)=itsSet.LINK[0];
    tmp(1)=itsSet.LINK[1];
    return tmp;
}

// get Set Number
Int NStarSet::getSetNumber()
{
    return itsSet.SETN;
}

// set Set Number
void NStarSet::setSetNumber(Int aNumber)
{
    itsSet.SETN = aNumber;
}

// get SetHeader address
uInt NStarSet::getAddress()
{
    return itsAddress;
}

// Write SSH in File
Bool NStarSet::write(ofstream& aFile)
{
    if (itsAddress) {
	aFile.seekp (itsAddress,ios::beg);
    } else {
	aFile.seekp (0,ios::end);		// from end
	itsAddress = aFile.tellp();
    }
    aFile.write ((char*)(&itsSet),sizeof(itsSet));
    doWrite (aFile);
    return True;
}
