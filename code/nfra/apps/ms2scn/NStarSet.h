//# NStarSet.h : class for the standard beginning of any standard set header
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
//# $Id: NStarSet.h,v 19.3 2004/11/30 17:50:39 ddebonis Exp $

#ifndef NFRA_NSTARSET_H
#define NFRA_NSTARSET_H
 

//# Includes
#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <casa/iosfwd.h>
#include <casa/namespace.h>

class NStarSet
{
public:

    // Constructor NStar Set
    NStarSet();

    // Destructor NStar Set
    virtual ~NStarSet();

    // set LINK
    void setLINK(const Vector<Int>& aLink);
 
    // get Link
    Vector<Int> getLINK();

    // get Set Number
    Int getSetNumber();

    // set Set Number
    void setSetNumber(Int aNumber);

    // get SetHeader address
    uInt getAddress();

    // Write SSH in File
    Bool write(std::ofstream& aFile);

protected:
 
    // Write derived class in File
    virtual void doWrite(std::ofstream& aFile)=0;

private:

    // get SetTable address
    uInt itsAddress;

    struct NStarSSH
	{
	    // LINK SETS (MUST BE FIRST)
	    Int LINK[2];
	    // LENGTH HEADER
	    Short LEN;
	    // VERSION HEADER
	    Short VER;
	    // # OF SET
	    Int SETN;
	} itsSet;

};


#endif
