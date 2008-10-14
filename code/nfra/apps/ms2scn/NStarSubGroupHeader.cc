//# NStarSubGroupHeader.cc : class for access to Newstar Sub-Group Header
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
//# $Id: NStarSubGroupHeader.cc,v 19.1 2004/08/25 05:49:25 gvandiep Exp $

#include <NStarSubGroupHeader.h>
#include <casa/fstream.h>
#include <casa/string.h>            // for memset


// Constructor NStar Sub-Group-Header
NStarSubGroupHeader::NStarSubGroupHeader()
{
    itsHdr.LINK[0] = 0;
    itsHdr.LINK[1] = 0;
    itsHdr.GROUPN.GROUPN  = 0;
    itsHdr.LINKG.LINKG[0] = 0;
    itsHdr.LINKG.LINKG[1] = 0;
    itsHdr.LINKGN.LINKGN  = 0;
    itsHdr.HEADH.HEADH    = 0;
    itsHdr.DATAP.DATAP    = 0;
    for (uInt i=0; i<8; i++) {
	itsHdr.FGROUP.FGROUP[i] = 0;
    }
    memset(itsHdr.SGH__0000,' ',16);
}

// Destructor NStar Sub-Group-Header
NStarSubGroupHeader::~NStarSubGroupHeader()
{}

// get LINKG offset
Int NStarSubGroupHeader::getOffsetLINKG() const
{
    return (char*)(&itsHdr.LINKG) - (char*)(&itsHdr);
}


Int NStarSubGroupHeader::write (Int offset, ofstream& file,
				Int ngroup, Int groupnr,
				Int nchild, Int parent, Int setptr,
				Int cumNchild, Int restNgroup,
				const Int* groupId, Int level)
{
    Int next = offset + sizeof(itsHdr);
    // Fill next pointer. Last one points to parent.
    if (groupnr == ngroup-1) {
	itsHdr.LINK[0] = parent;
    } else {
	itsHdr.LINK[0] = next;
    }
    // Fill previous pointer. First one points back to parent.
    if (groupnr == 0) {
	itsHdr.LINK[1] = parent;
    } else {
	itsHdr.LINK[1] = offset - sizeof(itsHdr);
    }
    itsHdr.GROUPN.GROUPN = groupnr;
    // When the data set pointer is negative, there are children.
    // The children are written after all groups at this level
    // and after the children of the previous groups at this level.
    if (setptr < 0) {
	itsHdr.LINKG.LINKG[0] = offset + (restNgroup - groupnr + cumNchild)
	                                 * sizeof(itsHdr);
	itsHdr.LINKG.LINKG[1] = itsHdr.LINKG.LINKG[0]
	                        + (nchild-1) * sizeof(itsHdr);
	itsHdr.LINKGN.LINKGN  = nchild;
	itsHdr.DATAP.DATAP    = 0;
    } else {
	itsHdr.LINKG.LINKG[0] = offset + getOffsetLINKG();    // empty queue
	itsHdr.LINKG.LINKG[1] = itsHdr.LINKG.LINKG[0];
	itsHdr.LINKGN.LINKGN  = 0;
	itsHdr.DATAP.DATAP    = setptr;
    }
    itsHdr.HEADH.HEADH = parent;
    Int i;
    for (i=0; i<8; i++) {
	itsHdr.FGROUP.FGROUP[i] = -1;
    }
    for (i=0; i<=level; i++) {
	itsHdr.FGROUP.FGROUP[i] = groupId[i];
    }
    file.write ((char*)(&itsHdr), sizeof(itsHdr));
    return next;
}
