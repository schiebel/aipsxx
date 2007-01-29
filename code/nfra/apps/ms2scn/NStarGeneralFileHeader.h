//# NStarGeneralFileHeader.h : class for access to Newstar General File Header
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
//# $Id: NStarGeneralFileHeader.h,v 19.4 2004/11/30 17:50:39 ddebonis Exp $

#ifndef NFRA_NSTARGENERALFILEHEADER_H
#define NFRA_NSTARGENERALFILEHEADER_H
 

//# Includes
#include <casa/aips.h>
#include <casa/BasicSL/String.h>
#include <NStarFileType.h>
#include <casa/Arrays/Vector.h>
#include <casa/iosfwd.h>
#include <casa/namespace.h>


class NStarGeneralFileHeader
{
public:

    // Constructor NStar General File Header
    NStarGeneralFileHeader(NStarFileType aType, const Char* aName);

    // Destructor NStar General File Header
    ~NStarGeneralFileHeader();

    // Set DataType
    void setDATTP(Int aType);

    // Set Nodename
    void setNAME(const Char* aName);

    // set LINK
    void setLINK(const Vector<Int>& aLink, const Int aNlink);
 
    // get Link
    Vector<Int> getLINK() const;

    // set LINKG
    void setLINKG(Int aFirstLinkg, Int aLastLinkg, Int aNlinkg);

    // get the offset of the LINK field in the GFH.
    Int getOffsetLINK() const;

    // get the offset of the LINKG field in the GFH.
    Int getOffsetLINKG() const;

    // Get Type of block (e.g. .SCN)
    String getID() const;

    // Get Length Header
    Int getLEN() const;

    // Get Version
    Int getVER() const;

    // Get Creation date (dd-mmm-yyyy)
    String getCDAT() const;

    // Get Creation time (hh:mm)
    String getCTIM() const;

    // Get Revision date (dd-mmm-yyyy)
    String getRDAT() const;

    // Get Revision time (hh:mm)
    String getRTIM() const;

    // Get Revision count
    Int getRCNT() const;

    // Get Node name used
    const Char* getNAME() const;

    // Get Data type 
    Int getDATTP() const;

    // Write GFH in File
    void write(std::ofstream& aFile);

private:

    struct NStarGFH
	{
	    // Type of block (e.g. .SCN)
	    Char ID[4];
	    // Length Header
	    Int LEN;
	    // Version
	    Int VER;
	    // Creation date (dd-mmm-yyyy)
	    Char CDAT[11];
	    // Creation time (hh:mm)
	    Char CTIM[5];
	    // Revision date
	    Char RDAT[11];
	    // Revision time
	    Char RTIM[5];
	    // Revision count
	    Int RCNT;
	    // Node name used
	    Char NAME[80];
	    // Data type  (1,2=VAX, 3=Alliant, 4=Convex, 5=IEEE,
	    //             6=DEC workst., 7= SUN workst., 8=HP workstation)
	    Char DATTP;
	    // Reserved
	    Char GFH__0000[23];
	    union {
		// Link to data
		Int LINK[2];
		// absolute listhead
		Int ALHD[2];
	    } LINK;
	    union {
		// Count linkage
		Int NLINK;
		// absolute-list length
		Int ALLEN;
	    } NLINK;
	    union {
		// Secondary link
		Int LINKG[2]; 
		// (subgroup) listhead
		Int LHD[2];
	    } LINKG;
	    union {
		Int NLINKG;
		// (subgroup) list length
		Int LLEN;
	    } NLINKG;
	    // Model unique identification (not used)
	    Int IDMDL;
	    // Other id
	    Int ID1;
	    // Other id
	    Int ID2;
	    // Start user area 
	    Char USER[1];
	    Char GFH__0001[323];
	} itsHdr;
};


#endif
