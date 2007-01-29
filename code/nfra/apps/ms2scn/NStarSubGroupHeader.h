//# NStarSubGroupHeader.h : class for access to Newstar Sub-Hroup Header
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
//# $Id: NStarSubGroupHeader.h,v 19.3 2004/11/30 17:50:39 ddebonis Exp $

#ifndef NFRA_NSTARSUBGROUPHEADER_H
#define NFRA_NSTARSUBGROUPHEADER_H
 

//# Includes
#include <casa/aips.h>

//# Forward Declarations
#include <casa/iosfwd.h>
#include <casa/namespace.h>

class NStarSubGroupHeader
{
public:

    // Constructor NStar Sub-Group-Header
    NStarSubGroupHeader();

    // Destructor NStar Sub-Group-Header
    ~NStarSubGroupHeader();

    // Fill the SGH with the correct info and write it at the given offset.
    // It returns the offset of the next free byte in the file.
    Int write (Int offset, std::ofstream& file,
	       Int ngroup, Int groupnr,
	       Int nchild, Int parent, Int setptr,
	       Int cumNchild, Int restNgroup,
	       const Int* groupId, Int level);

    // get the offset of the LINKG field in the SGH.
    Int getOffsetLINKG() const;


private:

    struct SGH {
	// LINK SETS (MUST BE FIRST)
        Int LINK[2];
	union {
	    // # OF THIS SUB-GROUP
	    Int GROUPN;
	    Int NAME;
	} GROUPN;
	union {
	    // LINK HEAD NEXT LEVEL
	    Int LINKG[2];
	    Int LHD[2];
	} LINKG;
	union {
	    // # IN SUB-LEVEL
	    Int LINKGN;
	    Int LLEN;
	} LINKGN;
	union {
	    Int HEADH;
	    // PARENT LISTHEAD PTR
	    Int PLHD;
	} HEADH;
	union {
	    // FULL NAME OF SUBGROUP
	    Int FGROUP[8];
	    Int FNAME[8];
	} FGROUP;
	union {
	    // POINTER TO BELONGING SET HEADER
	    Int DATAP;
	    // PTR TO SECTOR HEADER
	    Int STHP;
	} DATAP;
	// RESERVED
        Char SGH__0000[16];
    } itsHdr;

};


#endif
