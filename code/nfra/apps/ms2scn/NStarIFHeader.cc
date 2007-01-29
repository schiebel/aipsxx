//# NStarIFHeader.cc : class for access to Newstar IF Header
//# Copyright (C) 1997,1998,2000,2001,2002
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
//# $Id: NStarIFHeader.cc,v 19.1 2004/08/25 05:49:25 gvandiep Exp $

#include <NStarIFHeader.h>
#include <casa/fstream.h>


// Fill NStar Set Header
NStarIFHeader::NStarIFHeader()
: itsAddress(0)
{
    itsHdr.CHAN   = 0;
    itsHdr.GCODE  = 0;
    for (Int j=0; j<14; j++) {
       for (Int i=0; i<2 ; i++) {
          itsHdr.GNCAL[j][i]   = 0;
	  itsHdr.TSYSI[j][i]   = 0.;
	  itsHdr.RGAINI[j][i]  = 0.;
	  itsHdr.TNOISEI[j][i] = 0.;
       }
    }
    itsHdr.TPINT  = 0;
    itsHdr.HAB    = 0.;
    itsHdr.HAI    = 0.;
    itsHdr.NTP    = 0;
    itsHdr.NIF    = 0;
    itsHdr.IFHAB  = 0.;
}

NStarIFHeader::~NStarIFHeader()
{
}

// set BAND NUMBER
void NStarIFHeader::setCHAN(Short aChan)
{
    itsHdr.CHAN=aChan;
}

// get BAND NUMBER
Short NStarIFHeader::getCHAN()
{
    return itsHdr.CHAN;
}

// set PRINCIPLE GAIN CORR. METHOD
void NStarIFHeader::setGCODE(Short aGcode)
{
    itsHdr.GCODE=aGcode;
}

// get PRINCIPLE GAIN CORR. METHOD
Short NStarIFHeader::getGCODE()
{
    return itsHdr.GCODE;
}

// set ACTUAL GAIN CORR. METHOD
void NStarIFHeader::setGNCAL(const Matrix<Short>& aGNCAL)
{
  for (Int i=0; i<14; i++) {
    itsHdr.GNCAL[i][0] = aGNCAL(0,i);
    itsHdr.GNCAL[i][1] = aGNCAL(1,i);
  }
}

// get ACTUAL GAIN CORR. METHOD
Matrix<Short> NStarIFHeader::getGNCAL()
{
  Matrix<Short> tmp(2,14);
  for (Int i=0; i<14; i++) {
    tmp(0,i) = itsHdr.GNCAL[i][0];
    tmp(1,i) = itsHdr.GNCAL[i][1];
  }
  return tmp;
}

// set CONSTANT SYSTEM TEMP
void NStarIFHeader::setTSYSI(const Matrix<Float>& aTSYSI)
{
  for (Int i=0; i<14; i++) {
    itsHdr.TSYSI[i][0] = aTSYSI(0,i);
    itsHdr.TSYSI[i][1] = aTSYSI(1,i);
  }
}

// get CONSTANT SYSTEM TEMP
Matrix<Float> NStarIFHeader::getTSYSI()
{
  Matrix<Float> tmp(2,14);
  for (Int i=0; i<14; i++) {
    tmp(0,i) = itsHdr.TSYSI[i][0];
    tmp(1,i) = itsHdr.TSYSI[i][1];
  }
  return tmp;
}


// set CONSTANT RECEIVER GAIN
void NStarIFHeader::setRGAINI(const Matrix<Float>& aRGAINI)
{
  for (Int i=0; i<14; i++) {
    itsHdr.RGAINI[i][0] = aRGAINI(0,i);
    itsHdr.RGAINI[i][1] = aRGAINI(1,i);
  }
}

// get CONSTANT RECEIVER GAIN
Matrix<Float> NStarIFHeader::getRGAINI()
{
  Matrix<Float> tmp(2,14);
  for (Int i=0; i<14; i++) {
    tmp(0,i) = itsHdr.RGAINI[i][0];
    tmp(1,i) = itsHdr.RGAINI[i][1];
  }
  return tmp;
}


// set CONSTANT NOISE TEMP.
void NStarIFHeader::setTNOISEI(const Matrix<Float>& aTNOISEI)
{
  for (Int i=0; i<14; i++) {
    itsHdr.TNOISEI[i][0] = aTNOISEI(0,i);
    itsHdr.TNOISEI[i][1] = aTNOISEI(1,i);
  }
}

// get CONSTANT NOISE TEMP.
Matrix<Float> NStarIFHeader::getTNOISEI()
{
  Matrix<Float> tmp(2,14);
  for (Int i=0; i<14; i++) {
    tmp(0,i) = itsHdr.TNOISEI[i][0];
    tmp(1,i) = itsHdr.TNOISEI[i][1];
  }
  return tmp;
}




// set Total Power Int.Time
void NStarIFHeader::setTPINT(Int aTPInt)
{
    itsHdr.TPINT=aTPInt;
}

// get Total Power Int.Time
Int NStarIFHeader::getTPINT()
{
    return itsHdr.TPINT;
}

// set FIRST HA APP.
void NStarIFHeader::setHAB(Float aHab)
{
    itsHdr.HAB=aHab;
}

// get FIRST HA APP.
Float NStarIFHeader::getHAB()
{
    return itsHdr.HAB;
}

// set HA INCREMENT
void NStarIFHeader::setHAI(Float aHai)
{
    itsHdr.HAI=aHai;
}

// get HA INCREMENT
Float NStarIFHeader::getHAI()
{
    return itsHdr.HAI;
}

// set # OF TP SCANS
void NStarIFHeader::setNTP(Int aNTP)
{
    itsHdr.NTP=aNTP;
}

// get # OF TP SCANS
Int NStarIFHeader::getNTP()
{
    return itsHdr.NTP;
}

// set # OF IF GAIN/PHASE SCANS
void NStarIFHeader::setNIF(Int aNIF)
{
    itsHdr.NIF=aNIF;
}

// get # OF IF GAIN/PHASE SCANS
Int NStarIFHeader::getNIF()
{
    return itsHdr.NIF;
}

// set HAB from IH block
void NStarIFHeader::setIFHAB(Float anIFHAB )
{
    itsHdr.IFHAB=anIFHAB;
}

// get HAB from IH block
Float NStarIFHeader::getIFHAB()
{
    return itsHdr.IFHAB;;
}


// Write IFH in File
Bool NStarIFHeader::write(ofstream& aFile)
{
    if (itsAddress) {
	aFile.seekp (itsAddress,ios::beg);
    } else {
	aFile.seekp (0,ios::end);		// from end
	itsAddress = aFile.tellp();
    }
    aFile.write((char*)(&itsHdr),sizeof(itsHdr));
    return True;
}

Int NStarIFHeader::getAddress()
{
  return itsAddress;
}

void NStarIFHeader::setAddress(Int anAddress)
{
  itsAddress=anAddress;
}

int NStarIFHeader::getIFHSize()
{
  return sizeof(itsHdr);
}
