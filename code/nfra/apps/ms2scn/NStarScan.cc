//# NStarScan.cc : class for access to Newstar Scans
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
//# $Id: NStarScan.cc,v 19.1 2004/08/25 05:49:25 gvandiep Exp $


#include <NStarScan.h>
#include <casa/OS/RegularFile.h>
#include <casa/fstream.h>


// Constructor NStar Scans
NStarScan::NStarScan()
{
    itsHdr.HA=0.;
    itsHdr.MAX=0.;
    itsHdr.SCAL=0.;
    itsHdr.BITS=0;
    itsHdr.CLKC=0.;
    itsHdr.ACLKC=0.;
    itsHdr.IREF=0.;
    itsHdr.EXT=0.;
    itsHdr.REFR=0.;
    itsHdr.FARAD=0.;
    itsHdr.IFRAC=0;
    itsHdr.IFRMC=0;
    itsHdr.AEXT=0.;
    itsHdr.AREFR=0.;
    itsHdr.AFARAD=0.;
    itsHdr.AIFRAC=0;
    itsHdr.AIFRMC=0;
    itsHdr.PANG=0.;
    itsHdr.AIREF=0.;
    itsHdr.AOTHUSED=0;
    for (Int i=0; i<2 ; i++)
      {
	itsHdr.REDNS[i]=0.;
	itsHdr.REDNSY[i]=0.;
	itsHdr.ALGNS[i]=0.;
	itsHdr.ALGNSY[i]=0.;
	itsHdr.OTHNS[i]=0.;
	itsHdr.OTHNSY[i]=0.;
	for (Int j=0; j<14; j++)
	  {
	    itsHdr.REDC[j][i]=0.;
	    itsHdr.REDCY[j][i]=0.;
	    itsHdr.ALGC[j][i]=0.;
	    itsHdr.ALGCY[j][i]=0.;
	    itsHdr.OTHC[j][i]=0.;
	    itsHdr.OTHCY[j][i]=0.;
	    itsHdr.AOTHC[j][i]=0.;
	    itsHdr.AOTHCY[j][i]=0.;
	  }
      }
}

// Destructor NStar Scan
NStarScan::~NStarScan()
{}

// Get size of NStarScan struct
uInt NStarScan::getSize() const
{
    return sizeof(itsHdr);
}

// Write Scan Header and data in File
uLong NStarScan::write(const Short* anArray, uInt nrval, ofstream& aFile)
{
    uLong pos = aFile.tellp();
    aFile.write((char*)(&itsHdr),sizeof(itsHdr));
    aFile.write((char*)anArray,nrval*sizeof(Short));
    return pos;
}

// set APP. HA (CIRCLES)
void NStarScan::setHA(Float aHa)
{
    itsHdr.HA=aHa;
}

// get APP. HA (CIRCLES)
Float NStarScan::getHA()
{
    return itsHdr.HA;
}

// set COS/SIN MAX (W.U.)
void NStarScan::setMAX(Float aMax)
{
    itsHdr.MAX=aMax;
}

// get COS/SIN MAX (W.U.)
Float NStarScan::getMAX()
{
    return itsHdr.MAX;
}

// set COS/SIN SCALE MULTIPLIER - 1
void NStarScan::setSCAL(Float aScal)
{
    itsHdr.SCAL=aScal;
}

// get COS/SIN SCALE MULTIPLIER - 1
Float NStarScan::getSCAL()
{
    return itsHdr.SCAL;
}

// set REDUNDANCY NOISE (W.U., G/P)
void NStarScan::setREDNS(const Vector<Float>& aRedns)
{
    itsHdr.REDNS[0]=aRedns(0);
    itsHdr.REDNS[1]=aRedns(1);
}

// get REDUNDANCY NOISE (W.U., G/P)
Vector<Float> NStarScan::getREDNS()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.REDNS[0];
    tmp(1)=itsHdr.REDNS[1];
    return tmp;
}

// set REDUNDANCY NOISE (W.U., G/P)
void NStarScan::setREDNSY(const Vector<Float>& aRednsy)
{
    itsHdr.REDNSY[0]=aRednsy(0);
    itsHdr.REDNSY[1]=aRednsy(1);
}

// get REDUNDANCY NOISE (W.U., G/P)
Vector<Float> NStarScan::getREDNSY()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.REDNSY[0];
    tmp(1)=itsHdr.REDNSY[1];
    return tmp;
}

// set ALIGN NOISE (W.U., G/P)
void NStarScan::setALGNS(const Vector<Float>& aAlgns)
{
    itsHdr.ALGNS[0]=aAlgns(0);
    itsHdr.ALGNS[1]=aAlgns(1);
}

// get ALIGN NOISE (W.U., G/P)
Vector<Float> NStarScan::getALGNS()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.ALGNS[0];
    tmp(1)=itsHdr.ALGNS[1];
    return tmp;
}

// set ALIGN NOISE (W.U., G/P)
void NStarScan::setALGNSY(const Vector<Float>& aAlgnsy)
{
    itsHdr.ALGNSY[0]=aAlgnsy(0);
    itsHdr.ALGNSY[1]=aAlgnsy(1);
}

// get ALIGN NOISE (W.U., G/P)
Vector<Float> NStarScan::getALGNSY()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.ALGNSY[0];
    tmp(1)=itsHdr.ALGNSY[1];
    return tmp;
}

// set OTHER NOISE (W.U. G/P)
void NStarScan::setOTHNS(const Vector<Float>& aOthns)
{
    itsHdr.OTHNS[0]=aOthns(0);
    itsHdr.OTHNS[1]=aOthns(1);
}

// get OTHER NOISE (W.U. G/P)
Vector<Float> NStarScan::getOTHNS()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.OTHNS[0];
    tmp(1)=itsHdr.OTHNS[1];
    return tmp;
}

// set OTHER NOISE (W.U. G/P)
void NStarScan::setOTHNSY(const Vector<Float>& aOthnsy)
{
    itsHdr.OTHNSY[0]=aOthnsy(0);
    itsHdr.OTHNSY[1]=aOthnsy(1);
}

// get OTHER NOISE (W.U. G/P)
Vector<Float> NStarScan::getOTHNSY()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.OTHNSY[0];
    tmp(1)=itsHdr.OTHNSY[1];
    return tmp;
}

// set GENERAL BITS (8-15: flag bits)
void NStarScan::setBITS(Int aBits)
{
    itsHdr.BITS=aBits;
}

// get GENERAL BITS (8-15: flag bits)
Int NStarScan::getBITS()
{
    return itsHdr.BITS;
}

// set CLOCK CORRECTION (sec)
void NStarScan::setCLKC(Float aClkc)
{
    itsHdr.CLKC=aClkc;
}

// get CLOCK CORRECTION (sec)
Float NStarScan::getCLKC()
{
    return itsHdr.CLKC;
}

// set APPL. CLOCK CORRECTION (sec)
void NStarScan::setACLKC(Float aAclkc)
{
    itsHdr.ACLKC=aAclkc;
}

// get APPL. CLOCK CORRECTION (sec)
Float NStarScan::getACLKC()
{
    return itsHdr.ACLKC;
}

// set IONOS. REFRACT. (CIRCLES/km)
void NStarScan::setIREF(Float aIref)
{
    itsHdr.IREF=aIref;
}

// get IONOS. REFRACT. (CIRCLES/km)
Float NStarScan::getIREF()
{
    return itsHdr.IREF;
}

// set EXTINCTION FACTOR -1
void NStarScan::setEXT(Float aExt)
{
    itsHdr.EXT=aExt;
}

// get EXTINCTION FACTOR -1
Float NStarScan::getEXT()
{
    return itsHdr.EXT;
}

// set REFRACTION (MU-1)
void NStarScan::setREFR(Float aRefr)
{
    itsHdr.REFR=aRefr;
}

// get REFRACTION (MU-1)
Float NStarScan::getREFR()
{
    return itsHdr.REFR;
}

// set FARADAY ROTATION (RADIANS)
void NStarScan::setFARAD(Float aFarad)
{
    itsHdr.FARAD=aFarad;
}

// get FARADAY ROTATION (RADIANS)
Float NStarScan::getFARAD()
{
    return itsHdr.FARAD;
}

// set X REDUNDANCY CORRECTION
void NStarScan::setREDC(const Matrix<Float>& aRedc)
{
    for (int i=0; i<14; i++)
	{
	    itsHdr.REDC[i][0]=aRedc(0,i);
	    itsHdr.REDC[i][1]=aRedc(1,i);
	}
}

// get X REDUNDANCY CORRECTION
Matrix<Float> NStarScan::getREDC()
{
    Matrix<Float> tmp(2,14);
    for (int i=0; i<14; i++)
	{
	    tmp(0,i)=itsHdr.REDC[i][0];
	    tmp(1,i)=itsHdr.REDC[i][1];
	}
    return tmp;
}

// set Y REDUNDANCY CORRECTION
void NStarScan::setREDCY(const Matrix<Float>& aRedcy)
{
    for (int i=0; i<14; i++)
	{
	    itsHdr.REDCY[i][0]=aRedcy(0,i);
	    itsHdr.REDCY[i][1]=aRedcy(1,i);
	}
}

// get Y REDUNDANCY CORRECTION
Matrix<Float> NStarScan::getREDCY()
{
    Matrix<Float> tmp(2,14);
    for (int i=0; i<14; i++)
	{
	    tmp(0,i)=itsHdr.REDCY[i][0];
	    tmp(1,i)=itsHdr.REDCY[i][1];
	}
    return tmp;
}

// set X ALIGN CORRECTION (LOG)
void NStarScan::setALGC(const Matrix<Float>& aAlgc)
{
    for (int i=0; i<14; i++)
	{
	    itsHdr.ALGC[i][0]=aAlgc(0,i);
	    itsHdr.ALGC[i][1]=aAlgc(1,i);
	}
}

// get X ALIGN CORRECTION (LOG)
Matrix<Float> NStarScan::getALGC()
{
    Matrix<Float> tmp(2,14);
    for (int i=0; i<14; i++)
	{
	    tmp(0,i)=itsHdr.ALGC[i][0];
	    tmp(1,i)=itsHdr.ALGC[i][1];
	}
    return tmp;
}

// set Y ALIGN CORRECTION (LOG)
void NStarScan::setALGCY(const Matrix<Float>& aAlgcy)
{
    for (int i=0; i<14; i++)
	{
	    itsHdr.ALGCY[i][0]=aAlgcy(0,i);
	    itsHdr.ALGCY[i][1]=aAlgcy(1,i);
	}
}

// get Y ALIGN CORRECTION (LOG)
Matrix<Float> NStarScan::getALGCY()
{
    Matrix<Float> tmp(2,14);
    for (int i=0; i<14; i++)
	{
	    tmp(0,i)=itsHdr.ALGCY[i][0];
	    tmp(1,i)=itsHdr.ALGCY[i][1];
	}
    return tmp;
}

// set X OTHER CORRECTION (LOG)
void NStarScan::setOTHC(const Matrix<Float>& aOthc)
{
    for (int i=0; i<14; i++)
	{
	    itsHdr.OTHC[i][0]=aOthc(0,i);
	    itsHdr.OTHC[i][1]=aOthc(1,i);
	}
}

// get X OTHER CORRECTION (LOG)
Matrix<Float> NStarScan::getOTHC()
{
    Matrix<Float> tmp(2,14);
    for (int i=0; i<14; i++)
	{
	    tmp(0,i)=itsHdr.OTHC[i][0];
	    tmp(1,i)=itsHdr.OTHC[i][1];
	}
    return tmp;
}

// set Y OTHER CORRECTION (LOG)
void NStarScan::setOTHCY(const Matrix<Float>& aOthcy)
{
    for (int i=0; i<14; i++)
	{
	    itsHdr.OTHCY[i][0]=aOthcy(0,i);
	    itsHdr.OTHCY[i][1]=aOthcy(1,i);
	}
}

// get Y OTHER CORRECTION (LOG)
Matrix<Float> NStarScan::getOTHCY()
{
    Matrix<Float> tmp(2,14);
    for (int i=0; i<14; i++)
	{
	    tmp(0,i)=itsHdr.OTHCY[i][0];
	    tmp(1,i)=itsHdr.OTHCY[i][1];
	}
    return tmp;
}

// set POINTER TO ADD IFR CORRECTIONS
void NStarScan::setIFRAC(Int aIfrac)
{
    itsHdr.IFRAC=aIfrac;
}

// get POINTER TO ADD IFR CORRECTIONS
Int NStarScan::getIFRAC()
{
    return itsHdr.IFRAC;
}

// set POINTER TO MUL. IFR CORRNS
void NStarScan::setIFRMC(Int aIfrmc)
{
    itsHdr.IFRMC=aIfrmc;
}

// get POINTER TO MUL. IFR CORRNS
Int NStarScan::getIFRMC()
{
    return itsHdr.IFRMC;
}

// set APPLIED EXTINCTION FACTOR -1
void NStarScan::setAEXT(Float aAext)
{
    itsHdr.AEXT=aAext;
}

// get APPLIED EXTINCTION FACTOR -1
Float NStarScan::getAEXT()
{
    return itsHdr.AEXT;
}

// set APPLIED REFRACTION (MU-1)
void NStarScan::setAREFR(Float aArefr)
{
    itsHdr.AREFR=aArefr;
}

// get APPLIED REFRACTION (MU-1)
Float NStarScan::getAREFR()
{
    return itsHdr.AREFR;
}

// set APPLIED FARADAY rotation
void NStarScan::setAFARAD(Float aAfarad)
{
    itsHdr.AFARAD=aAfarad;
}

// get APPLIED FARADAY rotation
Float NStarScan::getAFARAD()
{
    return itsHdr.AFARAD;
}

// set X APPLIED OTHER CORRECTION
void NStarScan::setAOTHC(const Matrix<Float>& aAothc)
{
    for (int i=0; i<14; i++)
	{
	    itsHdr.AOTHC[i][0]=aAothc(0,i);
	    itsHdr.AOTHC[i][1]=aAothc(1,i);
	}
}

// get X APPLIED OTHER CORRECTION
Matrix<Float> NStarScan::getAOTHC()
{
    Matrix<Float> tmp(2,14);
    for (int i=0; i<14; i++)
	{
	    tmp(0,i)=itsHdr.AOTHC[i][0];
	    tmp(1,i)=itsHdr.AOTHC[i][1];
	}
    return tmp;
}

// set Y APPLIED OTHER CORRECTION
void NStarScan::setAOTHCY(const Matrix<Float>& aAothcy)
{
    for (int i=0; i<14; i++)
	{
	    itsHdr.AOTHCY[i][0]=aAothcy(0,i);
	    itsHdr.AOTHCY[i][1]=aAothcy(1,i);
	}
}

// get Y APPLIED OTHER CORRECTION
Matrix<Float> NStarScan::getAOTHCY()
{
    Matrix<Float> tmp(2,14);
    for (int i=0; i<14; i++)
	{
	    tmp(0,i)=itsHdr.AOTHCY[i][0];
	    tmp(1,i)=itsHdr.AOTHCY[i][1];
	}
    return tmp;
}

// set PTR TO APPL. ADD IFR CORRN
void NStarScan::setAIFRAC(Int aAifrac)
{
    itsHdr.AIFRAC=aAifrac;
}

// get PTR TO APPL. ADD IFR CORRN
Int NStarScan::getAIFRAC()
{
    return itsHdr.AIFRAC;
}

// set PTR TO APPL. MUL IFR CORRN
void NStarScan::setAIFRMC(Int aAifrmc)
{
    itsHdr.AIFRMC=aAifrmc;
}

// get PTR TO APPL. MUL IFR CORRN
Int NStarScan::getAIFRMC()
{
    return itsHdr.AIFRMC;
}

// set PARALL. ANGLE (CIRCLES)
void NStarScan::setPANG(Float aPang)
{
    itsHdr.PANG=aPang;
}

// get PARALL. ANGLE (CIRCLES)
Float NStarScan::getPANG()
{
    return itsHdr.PANG;
}

// set APPLIED IONOSPH.. REFRCTN
void NStarScan::setAIREF(Float aAiref)
{
    itsHdr.AIREF=aAiref;
}

// get APPLIED IONOSPH.. REFRCTN
Float NStarScan::getAIREF()
{
    return itsHdr.AIREF;
}

// set 1 = AOTH DE-APPLIED
void NStarScan::setAOTHUSED(Int aAothused)
{
    itsHdr.AOTHUSED=aAothused;
}

// get 1 = AOTH DE-APPLIED
Int NStarScan::getAOTHUSED()
{
    return itsHdr.AOTHUSED;
}
