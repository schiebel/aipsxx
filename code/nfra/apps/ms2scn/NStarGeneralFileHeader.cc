//# NStarGeneralFileHeader.cc : class for access to Newstar General File Header
//# Copyright (C) 1997,1998,1999,2001,2002,2004
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
//# $Id: NStarGeneralFileHeader.cc,v 19.2 2004/08/25 05:49:25 gvandiep Exp $

#include <NStarGeneralFileHeader.h>
#include <casa/OS/Time.h>
#include <casa/Quanta/MVTime.h>
#include <casa/fstream.h>
#include <casa/sstream.h>


// Fill NStar General File Header
NStarGeneralFileHeader::NStarGeneralFileHeader(NStarFileType aType, const Char* aName)
{
    MVTime t;

    if (aType == SCN) {
	strncpy(itsHdr.ID,".SCN",4);
    } else if (aType == WMP) {
	strncpy(itsHdr.ID,".WMP",4);
    } else if (aType == MDL) {
	strncpy(itsHdr.ID,".MDL",4);
    } else if (aType == NGF) {
	strncpy(itsHdr.ID,".NGF",4);
    }
    itsHdr.LEN=sizeof(itsHdr);
    itsHdr.VER=1;

    // Convert time and date to string
    t = MVTime(Time());
    {
      ostringstream stream;
      stream << t;
      strncpy(itsHdr.CTIM,stream.str().c_str(),5);
      strncpy(itsHdr.RTIM,stream.str().c_str(),5);
    }
    {
      ostringstream stream;
      if (t.monthday() < 10) {
	stream << "0";
      }
      stream << t.monthday() << "-" << t.monthName() << "-" << t.year();
      strncpy(itsHdr.CDAT,stream.str().c_str(),11);
      strncpy(itsHdr.RDAT,stream.str().c_str(),11);
    }

    itsHdr.RCNT=1;
    memset(itsHdr.NAME,' ',80);
    strncpy(itsHdr.NAME,aName,strlen(aName));
#if defined(HPUX)
    itsHdr.DATTP=8;
#elif defined(AIPS_LINUX)
    itsHdr.DATTP=6;
#else
    itsHdr.DATTP=7;
#endif
    memset(itsHdr.GFH__0000,' ',23);
    itsHdr.LINK.LINK[0]=0;
    itsHdr.LINK.LINK[1]=0;
    itsHdr.NLINK.NLINK=0;
    itsHdr.NLINK.ALLEN=0;
    itsHdr.LINKG.LINKG[0]=itsHdr.LEN;
    itsHdr.LINKG.LINKG[1]=itsHdr.LEN;
    itsHdr.NLINKG.NLINKG=1;
    itsHdr.NLINKG.LLEN=1;
    itsHdr.IDMDL=0;
    itsHdr.ID1=0;
    itsHdr.ID2=0;
    memset(itsHdr.USER,' ',1);
    memset(itsHdr.GFH__0001,' ',323);
}

NStarGeneralFileHeader::~NStarGeneralFileHeader()
{
    ;
}


// Set DataType
void NStarGeneralFileHeader::setDATTP(Int aType)
{
    itsHdr.DATTP=(Char) aType;
}

// Set Nodename
void NStarGeneralFileHeader::setNAME(const Char* aName)
{
    memset(itsHdr.NAME,' ',80);
    strncpy(itsHdr.NAME,aName,strlen(aName));
}

// set LINK
void NStarGeneralFileHeader::setLINK(const Vector<Int>& aLink, const Int aNlink)
{
    itsHdr.LINK.LINK[0]=aLink(0);
    itsHdr.LINK.LINK[1]=aLink(1);
    itsHdr.NLINK.NLINK=aNlink;
}
 
// get LINK
Vector<Int> NStarGeneralFileHeader::getLINK() const
{
    Vector<Int> tmp(2);
    tmp(0)=itsHdr.LINK.LINK[0];
    tmp(1)=itsHdr.LINK.LINK[1];
    return tmp;
}

// set LINKG
void NStarGeneralFileHeader::setLINKG(Int aFirstLinkg, Int aLastLinkg,
				      Int aNlinkg)
{
    itsHdr.LINKG.LINKG[0]=aFirstLinkg;
    itsHdr.LINKG.LINKG[1]=aLastLinkg;
    itsHdr.NLINKG.NLINKG=aNlinkg;
}

// get LINK offset
Int NStarGeneralFileHeader::getOffsetLINK() const
{
    return (char*)(&itsHdr.LINK) - (char*)(&itsHdr);
}

// get LINKG offset
Int NStarGeneralFileHeader::getOffsetLINKG() const
{
    return (char*)(&itsHdr.LINKG) - (char*)(&itsHdr);
}


// Get Type of block (e.g. .SCN)
String NStarGeneralFileHeader::getID() const
{
    return String(itsHdr.ID,4);    
}

// Get Length Header
Int NStarGeneralFileHeader::getLEN() const
{
    return itsHdr.LEN;
}

// Get Version
Int NStarGeneralFileHeader::getVER() const
{
    return itsHdr.VER;
}

// Get Creation date (dd-mmm-yyyy)
String NStarGeneralFileHeader::getCDAT() const
{
    return String(itsHdr.CDAT,11);    
}

// Get Creation time (hh:mm)
String NStarGeneralFileHeader::getCTIM() const
{
    return String(itsHdr.CTIM,5);    
}

// Get Revision date (dd-mmm-yyyy)
String NStarGeneralFileHeader::getRDAT() const
{
    return String(itsHdr.RDAT,11);    
}

// Get Revision time (hh:mm)
String NStarGeneralFileHeader::getRTIM() const
{
    return String(itsHdr.RTIM,5);    
}

// Get Revision count
Int NStarGeneralFileHeader::getRCNT() const
{
    return itsHdr.RCNT;
}

// Get Node name used
const Char* NStarGeneralFileHeader::getNAME() const
{
    return itsHdr.NAME;
}

// Get Data type 
Int NStarGeneralFileHeader::getDATTP() const
{
    return itsHdr.DATTP;
}

// Write GFH in File
void NStarGeneralFileHeader::write(ofstream& aFile)
{
    MVTime t;
    // Convert time and date to string
    t = MVTime(Time());
    {
      ostringstream stream;
      stream << t;
      strncpy(itsHdr.RTIM,stream.str().c_str(),5);
    }
    {
      ostringstream stream;
      if (t.monthday() < 10) {
	stream << "0";
      }
      stream << t.monthday() << "-" << t.monthName() << "-" << t.year();
      strncpy(itsHdr.RDAT,stream.str().c_str(),11);
    }

    aFile.seekp(0,ios::beg);  // Always at start of file
    aFile.write((char*)(&itsHdr),sizeof(itsHdr));
}
