//# NStarSetHeader.cc : class for access to Newstar Set Header
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
//# $Id: NStarSetHeader.cc,v 19.1 2004/08/25 05:49:25 gvandiep Exp $

#include <NStarSetHeader.h>
#include <casa/fstream.h>


// Fill NStar Set Header
NStarSetHeader::NStarSetHeader()
: itsIfrTable(0)
{
    itsHdr.BEC=0;
    itsHdr.PTS=0;
    itsHdr.VNR=0;
    itsHdr.CHAN=0;
    itsHdr.PLN=0;
    itsHdr.RA=0.;
    itsHdr.DEC=0.;
    itsHdr.RAE=0.;
    itsHdr.DECE=0.;
    itsHdr.HAB=0.;
    itsHdr.HAI=0.;
    itsHdr.SCN=0;
    itsHdr.OEP=0.;
    itsHdr.EPO=0.;
    itsHdr.FRQ=0.;
    itsHdr.FRQE=0.;
    itsHdr.UBAND=0.;
    itsHdr.HAV=0;
    itsHdr.NIFR=0;
    itsHdr.IFRP=0;
    itsHdr.NFD=0;
    itsHdr.FDP=0;
    itsHdr.NOH=0;
    itsHdr.OHP=0;
    itsHdr.NSC=0;
    itsHdr.SCP=0;
    itsHdr.NSH=0;
    itsHdr.SHP=0;
    itsHdr.SCNP=0;
    itsHdr.SCNL=0;
    itsHdr.PHI=0.;
    itsHdr.FRQ0=0.;
    itsHdr.FRQV=0.;
    itsHdr.FRQC=0.;
    itsHdr.VEL=0.;
    itsHdr.VELC=0;
    itsHdr.MJD=0.;
    itsHdr.UTST=1.00274;
    itsHdr.INST=0;
    itsHdr.VELR=0.;
    itsHdr.WFAC=0.;
    itsHdr.DIPC=0;
    itsHdr.ACORM=0;
    itsHdr.IFHP=0;
    itsHdr.IFHL=0;
    for (Int j=0; j<14; j++)
      {
	itsHdr.RTP[j]=0.;
      }
    for (Int i=0; i<2 ; i++)
      {
	itsHdr.OBS[i]=0;
	itsHdr.REDNS[i]=0.;
	itsHdr.REDNSY[i]=0.;
	itsHdr.ALGNS[i]=0.;
	itsHdr.ALGNSY[i]=0.;
	itsHdr.OTHNS[i]=0.;
	itsHdr.OTHNSY[i]=0.;
	itsHdr.MDL[i]=0;
	itsHdr.MDD[i]=0;
	itsHdr.SHFT[i]=0.;
	itsHdr.ASHFT[i]=0.;
	itsHdr.DSHFT[i]=0.;
	itsHdr.DLDM[i]=0.;
	for (Int j=0; j<14; j++)
	  {
	    itsHdr.POLC[j][i]=0.;
	    itsHdr.POLCY[j][i]=0.;
	  }
      }
}

NStarSetHeader::~NStarSetHeader()
{
}

void NStarSetHeader::setScan(uLong pos, uInt size)
{
    itsHdr.SCNP = uInt(pos);
    itsHdr.SCNL = size;
}

// Set the IFR-table for this set
void NStarSetHeader::setIfrTable(NStarIfrTable* aTable)
{
    itsIfrTable=aTable;
}

// Write STH in File

void NStarSetHeader::doWrite(ofstream& aFile)
{
    uLong tPos=aFile.tellp();
    aFile.write((char*)(&itsHdr),sizeof(itsHdr));
    if (itsIfrTable) {
       itsHdr.IFRP=itsIfrTable->getAddress(aFile);
    }
    aFile.seekp(tPos, ios::beg);
    aFile.write((char*)(&itsHdr),sizeof(itsHdr));
}

// set BACKEND CONFIGURATION
void NStarSetHeader::setBEC(Short aBec)
{
    itsHdr.BEC=aBec;
}

// get BACKEND CONFIGURATION
Short NStarSetHeader::getBEC()
{
    return itsHdr.BEC;
}

// set POINTING SET #
void NStarSetHeader::setPTS(Short aPts)
{
    itsHdr.PTS=aPts;
}

// get POINTING SET #
Short NStarSetHeader::getPTS()
{
    return itsHdr.PTS;
}

// set OBS # (=VOLG+CYCLUS*65536)
void NStarSetHeader::setVNR(Int aVnr)
{
    itsHdr.VNR=aVnr;
}

// get OBS # (=VOLG+CYCLUS*65536)
Int NStarSetHeader::getVNR()
{
    return itsHdr.VNR;
}

// set BAND NUMBER
void NStarSetHeader::setCHAN(Short aChan)
{
    itsHdr.CHAN=aChan;
}

// get BAND NUMBER
Short NStarSetHeader::getCHAN()
{
    return itsHdr.CHAN;
}

// set # OF POLARISATIONS
void NStarSetHeader::setPLN(Short aPln)
{
    itsHdr.PLN=aPln;
}

// get # OF POLARISATIONS
Short NStarSetHeader::getPLN()
{
    return itsHdr.PLN;
}

// set FIELDNAME
void NStarSetHeader::setFIELD(const Char* aField)
{
    memset(itsHdr.FIELD,' ',12);
    strncpy(itsHdr.FIELD,aField,strlen(aField));
}

// get FIELDNAME
Char* NStarSetHeader::getFIELD()
{
    return itsHdr.FIELD;
}

// set OBS RA (CIRCLES)
void NStarSetHeader::setRA(Double aRa)
{
    itsHdr.RA=aRa;
}

// get OBS RA (CIRCLES)
Double NStarSetHeader::getRA()
{
    return itsHdr.RA;
}

// set OBS DEC
void NStarSetHeader::setDEC(Double aDec)
{
    itsHdr.DEC=aDec;
}

// get OBS DEC
Double NStarSetHeader::getDEC()
{
    return itsHdr.DEC;
}

// set EPOCH RA
void NStarSetHeader::setRAE(Double aRae)
{
    itsHdr.RAE=aRae;
}

// get EPOCH RA
Double NStarSetHeader::getRAE()
{
    return itsHdr.RAE;
}

// set EPOCH DEC
void NStarSetHeader::setDECE(Double aDece)
{
    itsHdr.DECE=aDece;
}

// get EPOCH DEC
Double NStarSetHeader::getDECE()
{
    return itsHdr.DECE;
}

// set FIRST HA APP.
void NStarSetHeader::setHAB(Float aHab)
{
    itsHdr.HAB=aHab;
}

// get FIRST HA APP.
Float NStarSetHeader::getHAB()
{
    return itsHdr.HAB;
}

// set HA INCREMENT
void NStarSetHeader::setHAI(Float aHai)
{
    itsHdr.HAI=aHai;
}

// get HA INCREMENT
Float NStarSetHeader::getHAI()
{
    return itsHdr.HAI;
}

// set # OF SCANS
void NStarSetHeader::setSCN(Int aScn)
{
    itsHdr.SCN=aScn;
}

// get # OF SCANS
Int NStarSetHeader::getSCN()
{
    return itsHdr.SCN;
}

// set OBS. EPOCH (E.G. 1980.12)
void NStarSetHeader::setOEP(Float aOep)
{
    itsHdr.OEP=aOep;
}

// get OBS. EPOCH (E.G. 1980.12)
Float NStarSetHeader::getOEP()
{
    return itsHdr.OEP;
}

// set EPOCH (E.G. 2000.0)
void NStarSetHeader::setEPO(Float aEpo)
{
    itsHdr.EPO=aEpo;
}

// get EPOCH (E.G. 2000.0)
Float NStarSetHeader::getEPO()
{
    return itsHdr.EPO;
}

// set APP. FREQUENCY
void NStarSetHeader::setFRQ(Double aFrq)
{
    itsHdr.FRQ=aFrq;
}

// get APP. FREQUENCY
Double NStarSetHeader::getFRQ()
{
    return itsHdr.FRQ;
}

// set LSR FREQUENCY
void NStarSetHeader::setFRQE(Double aFrqe)
{
    itsHdr.FRQE=aFrqe;
}

// get LSR FREQUENCY
Double NStarSetHeader::getFRQE()
{
    return itsHdr.FRQE;
}

// set BANDWIDTH (MHZ)
void NStarSetHeader::setUBAND(Float aUband)
{
    itsHdr.UBAND=aUband;
}

// get BANDWIDTH (MHZ)
Float NStarSetHeader::getUBAND()
{
    return itsHdr.UBAND;
}

// set AVERAGING HA (CIRCLES)
void NStarSetHeader::setHAV(Float aHav)
{
    itsHdr.HAV=aHav;
}

// get AVERAGING HA (CIRCLES)
Float NStarSetHeader::getHAV()
{
    return itsHdr.HAV;
}

// set OBS. DAY/YEAR
void NStarSetHeader::setOBS(const Vector<Short>& aObs)
{
    itsHdr.OBS[0]=aObs(0);
    itsHdr.OBS[1]=aObs(1);
}

// get OBS. DAY/YEAR
Vector<Short> NStarSetHeader::getOBS()
{
    Vector<Short> tmp(2);
    tmp(0)=itsHdr.OBS[0];
    tmp(1)=itsHdr.OBS[1];
    return tmp;
}

// set TEL. POSITIONS
void NStarSetHeader::setRTP(const Vector<Float>& aRtp)
{
    for (Int i=0; i<14; i++)
	{
	    itsHdr.RTP[i]=aRtp(i);
	}
}

// get TEL. POSITIONS
Vector<Float> NStarSetHeader::getRTP()
{
    Vector<Float> tmp(14);
    for (Int i=0; i<14; i++)
	{
	    tmp(i)=itsHdr.RTP[i];
	}
    return tmp;
}

// set # OF IFRS
void NStarSetHeader::setNIFR(Int aNifr)
{
    itsHdr.NIFR=aNifr;
}

// get # OF IFRS
Int NStarSetHeader::getNIFR()
{
    return itsHdr.NIFR;
}

// set POINTER TO IFR LIST
void NStarSetHeader::setIFRP(Int aIfrp)
{
    itsHdr.IFRP=aIfrp;
}

// get POINTER TO IFR LIST
Int NStarSetHeader::getIFRP()
{
    return itsHdr.IFRP;
}

// set FD BLOCK
void NStarSetHeader::setNFD(Int aNfd)
{
    itsHdr.NFD=aNfd;
}

// get FD BLOCK
Int NStarSetHeader::getNFD()
{
    return itsHdr.NFD;
}

// set POINTER TO FD                             
void NStarSetHeader::setFDP(Int aFdp)
{
    itsHdr.FDP=aFdp;
}

// get POINTER TO FD                             
Int NStarSetHeader::getFDP()
{
    return itsHdr.FDP;
}

// set LENGTH OH
void NStarSetHeader::setNOH(Int aNoh)
{
    itsHdr.NOH=aNoh;
}

// get LENGTH OH
Int NStarSetHeader::getNOH()
{
    return itsHdr.NOH;
}

// set POINTER TO OH
void NStarSetHeader::setOHP(Int aOhp)
{
    itsHdr.OHP=aOhp;
}

// get POINTER TO OH
Int NStarSetHeader::getOHP()
{
    return itsHdr.OHP;
}

// set SC BLOCK
void NStarSetHeader::setNSC(Int aNsc)
{
    itsHdr.NSC=aNsc;
}

// get SC BLOCK
Int NStarSetHeader::getNSC()
{
    return itsHdr.NSC;
}

// set POINTER TO SC                             
void NStarSetHeader::setSCP(Int aScp)
{
    itsHdr.SCP=aScp;
}

// get POINTER TO SC                             
Int NStarSetHeader::getSCP()
{
    return itsHdr.SCP;
}

// set SH BLOCK
void NStarSetHeader::setNSH(Int aNsh)
{
    itsHdr.NSH=aNsh;
}

// get SH BLOCK
Int NStarSetHeader::getNSH()
{
    return itsHdr.NSH;
}

// set POINTER TO SH                             
void NStarSetHeader::setSHP(Int aShp)
{
    itsHdr.SHP=aShp;
}

// get POINTER TO SH                             
Int NStarSetHeader::getSHP()
{
    return itsHdr.SHP;
}

// set POINTER TO SCAN AREA
void NStarSetHeader::setSCNP(Int aScnp)
{
    itsHdr.SCNP=aScnp;
}

// get POINTER TO SCAN AREA
Int NStarSetHeader::getSCNP()
{
    return itsHdr.SCNP;
}

// set LENGTH OF SCAN
void NStarSetHeader::setSCNL(Int aScnl)
{
    itsHdr.SCNL=aScnl;
}

// get LENGTH OF SCAN
Int NStarSetHeader::getSCNL()
{
    return itsHdr.SCNL;
}

// set X REDUNDANCY NOISE (G/P)
void NStarSetHeader::setREDNS(const Vector<Float>& aRedns)
{
    itsHdr.REDNS[0]=aRedns(0);
    itsHdr.REDNS[1]=aRedns(1);
}

// get X REDUNDANCY NOISE (G/P)
Vector<Float> NStarSetHeader::getREDNS()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.REDNS[0];
    tmp(1)=itsHdr.REDNS[1];
    return tmp;
}

// set Y REDUNDANCY NOISE (G/P)
void NStarSetHeader::setREDNSY(const Vector<Float>& aRednsy)
{
    itsHdr.REDNSY[0]=aRednsy(0);
    itsHdr.REDNSY[1]=aRednsy(1);
}

// get Y REDUNDANCY NOISE (G/P)
Vector<Float> NStarSetHeader::getREDNSY()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.REDNSY[0];
    tmp(1)=itsHdr.REDNSY[1];
    return tmp;
}

// set X ALIGN NOISE
void NStarSetHeader::setALGNS(const Vector<Float>& aAlgns)
{
    itsHdr.ALGNS[0]=aAlgns(0);
    itsHdr.ALGNS[1]=aAlgns(1);
}

// get X ALIGN NOISE
Vector<Float> NStarSetHeader::getALGNS()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.ALGNS[0];
    tmp(1)=itsHdr.ALGNS[1];
    return tmp;
}

// set Y ALIGN NOISE
void NStarSetHeader::setALGNSY(const Vector<Float>& aAlgnsy)
{
    itsHdr.ALGNSY[0]=aAlgnsy(0);
    itsHdr.ALGNSY[1]=aAlgnsy(1);
}

// get Y ALIGN NOISE
Vector<Float> NStarSetHeader::getALGNSY()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.ALGNSY[0];
    tmp(1)=itsHdr.ALGNSY[1];
    return tmp;
}

// set X OTHER NOISE
void NStarSetHeader::setOTHNS(const Vector<Float>& aOthns)
{
    itsHdr.OTHNS[0]=aOthns(0);
    itsHdr.OTHNS[1]=aOthns(1);
}

// get X OTHER NOISE
Vector<Float> NStarSetHeader::getOTHNS()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.OTHNS[0];
    tmp(1)=itsHdr.OTHNS[1];
    return tmp;
}

// set Y OTHER NOISE
void NStarSetHeader::setOTHNSY(const Vector<Float>& aOthnsy)
{
    itsHdr.OTHNSY[0]=aOthnsy(0);
    itsHdr.OTHNSY[1]=aOthnsy(1);
}

// get Y OTHER NOISE
Vector<Float> NStarSetHeader::getOTHNSY()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.OTHNSY[0];
    tmp(1)=itsHdr.OTHNSY[1];
    return tmp;
}

// set POINTER TO MODEL LISTS
void NStarSetHeader::setMDL(const Vector<Int>& aMdl)
{
    itsHdr.MDL[0]=aMdl(0);
    itsHdr.MDL[1]=aMdl(1);
}

// get POINTER TO MODEL LISTS
Vector<Int> NStarSetHeader::getMDL()
{
    Vector<Int> tmp(2);
    tmp(0)=itsHdr.MDL[0];
    tmp(1)=itsHdr.MDL[1];
    return tmp;
}

// set POINTER TO MODEL DATA
void NStarSetHeader::setMDD(const Vector<Int>& aMdd)
{
    itsHdr.MDD[0]=aMdd(0);
    itsHdr.MDD[1]=aMdd(1);
}

// get POINTER TO MODEL DATA
Vector<Int> NStarSetHeader::getMDD()
{
    Vector<Int> tmp(2);
    tmp(0)=itsHdr.MDD[0];
    tmp(1)=itsHdr.MDD[1];
    return tmp;
}

// set PRECESSION ROT. ANGLE
void NStarSetHeader::setPHI(Float aPhi)
{
    itsHdr.PHI=aPhi;
}

// get PRECESSION ROT. ANGLE
Float NStarSetHeader::getPHI()
{
    return itsHdr.PHI;
}

// set X POL. CORRECTIONS
void NStarSetHeader::setPOLC(const Matrix<Float>& aPolc)
{
    for (Int i=0; i<14; i++)
	{
	    itsHdr.POLC[i][0]=aPolc(0,i);
	    itsHdr.POLC[i][1]=aPolc(1,i);
	}
}

// get X POL. CORRECTIONS
Matrix<Float> NStarSetHeader::getPOLC()
{
    Matrix<Float> tmp(2,14);
    for (Int i=0; i<14; i++)
	{
	    tmp(0,i)=itsHdr.POLC[i][0];
	    tmp(1,i)=itsHdr.POLC[i][1];
	}
    return tmp;
}

// set Y POL. CORRECTIONS
void NStarSetHeader::setPOLCY(const Matrix<Float>& aPolcy)
{
    for (Int i=0; i<14; i++)
	{
	    itsHdr.POLCY[i][0]=aPolcy(0,i);
	    itsHdr.POLCY[i][1]=aPolcy(1,i);
	}
}

// get Y POL. CORRECTIONS
Matrix<Float> NStarSetHeader::getPOLCY()
{
    Matrix<Float> tmp(2,14);
    for (Int i=0; i<14; i++)
	{
	    tmp(0,i)=itsHdr.POLCY[i][0];
	    tmp(1,i)=itsHdr.POLCY[i][1];
	}
    return tmp;
}

// set REST FREQUENCY FOR LINE
void NStarSetHeader::setFRQ0(Double aFrq0)
{
    itsHdr.FRQ0=aFrq0;
}

// get REST FREQUENCY FOR LINE
Double NStarSetHeader::getFRQ0()
{
    return itsHdr.FRQ0;
}

// set REAL FREQUENCY FOR LINE
void NStarSetHeader::setFRQV(Double aFrqv)
{
    itsHdr.FRQV=aFrqv;
}

// get REAL FREQUENCY FOR LINE
Double NStarSetHeader::getFRQV()
{
    return itsHdr.FRQV;
}

// set CENTRE FREQUENCY FOR LINE
void NStarSetHeader::setFRQC(Double aFrqc)
{
    itsHdr.FRQC=aFrqc;
}

// get CENTRE FREQUENCY FOR LINE
Double NStarSetHeader::getFRQC()
{
    return itsHdr.FRQC;
}

// set VELOCITY FOR LINE (M/S)
void NStarSetHeader::setVEL(Float aVel)
{
    itsHdr.VEL=aVel;
}

// get VELOCITY FOR LINE (M/S)
Float NStarSetHeader::getVEL()
{
    return itsHdr.VEL;
}

// set VELOCITY CODE:
void NStarSetHeader::setVELC(Int aVelc)
{
    itsHdr.VELC=aVelc;
}

// get VELOCITY CODE:
Int NStarSetHeader::getVELC()
{
    return itsHdr.VELC;
}

// set START MJD (DAYS)
void NStarSetHeader::setMJD(Double aMjd)
{
    itsHdr.MJD=aMjd;
}

// get START MJD (DAYS)
Double NStarSetHeader::getMJD()
{
    return itsHdr.MJD;
}

// set CONVERSION UT/ST DAY LENGTH
void NStarSetHeader::setUTST(Double aUtst)
{
    itsHdr.UTST=aUtst;
}

// get CONVERSION UT/ST DAY LENGTH
Double NStarSetHeader::getUTST()
{
    return itsHdr.UTST;
}

// set INSTRUMENT:
void NStarSetHeader::setINST(Int aInst)
{
    itsHdr.INST=aInst;
}

// get INSTRUMENT:
Int NStarSetHeader::getINST()
{
    return itsHdr.INST;
}

// set VELOCITY AT REF. FREQ. (FRQC)
void NStarSetHeader::setVELR(Float aVelr)
{
    itsHdr.VELR=aVelr;
}

// get VELOCITY AT REF. FREQ. (FRQC)
Float NStarSetHeader::getVELR()
{
    return itsHdr.VELR;
}

// set 1-FACTOR TO ABS. SCH WEIGHTS
void NStarSetHeader::setWFAC(Float aWfac)
{
    itsHdr.WFAC=aWfac;
}

// get 1-FACTOR TO ABS. SCH WEIGHTS
Float NStarSetHeader::getWFAC()
{
    return itsHdr.WFAC;
}

// set DE-APPLY L-M SHIFT IN ARCSEC
void NStarSetHeader::setSHFT(const Vector<Float>& aShft)
{
    itsHdr.SHFT[0]=aShft(0);
    itsHdr.SHFT[1]=aShft(1);
}

// get DE-APPLY L-M SHIFT IN ARCSEC
Vector<Float> NStarSetHeader::getSHFT()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.SHFT[0];
    tmp(1)=itsHdr.SHFT[1];
    return tmp;
}

// set APPLY SHIFT (NOWHERE SET)
void NStarSetHeader::setASHFT(const Vector<Float>& aAshft)
{
    itsHdr.ASHFT[0]=aAshft(0);
    itsHdr.ASHFT[1]=aAshft(1);
}

// get APPLY SHIFT (NOWHERE SET)
Vector<Float> NStarSetHeader::getASHFT()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.ASHFT[0];
    tmp(1)=itsHdr.ASHFT[1];
    return tmp;
}

// set DIPOLE CODE: TEL # * 4 * CODE:
void NStarSetHeader::setDIPC(Int aDipc)
{
    itsHdr.DIPC=aDipc;
}

// get DIPOLE CODE: TEL # * 4 * CODE:
Int NStarSetHeader::getDIPC()
{
    return itsHdr.DIPC;
}

// set AMPL. CORRECTION METHOD:
void NStarSetHeader::setACORM(Int aAcorm)
{
    itsHdr.ACORM=aAcorm;
}

// get AMPL. CORRECTION METHOD:
Int NStarSetHeader::getACORM()
{
    return itsHdr.ACORM;
}

// set DE-APPLY SHIFT rate (L,M IN ARCSEC PER DAY)
void NStarSetHeader::setDSHFT(const Vector<Float>& aDshft)
{
    itsHdr.DSHFT[0]=aDshft(0);
    itsHdr.DSHFT[1]=aDshft(1);
}

// get DE-APPLY SHIFT rate (L,M IN ARCSEC PER DAY)
Vector<Float> NStarSetHeader::getDSHFT()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.DSHFT[0];
    tmp(1)=itsHdr.DSHFT[1];
    return tmp;
}

// set POINTER TO Tot.Power/IF area
void NStarSetHeader::setIFHP(Int aIfhp)
{
    itsHdr.IFHP=aIfhp;
}

// get POINTER TO Tot.Power/IF area
Int NStarSetHeader::getIFHP()
{
    return itsHdr.IFHP;
}

// set LENGTH  OF Tot.Power/IF-DATA
void NStarSetHeader::setIFHL(Int aIfhl)
{
    itsHdr.IFHL=aIfhl;
}

// get LENGTH  OF Tot.Power/IF-DATA
Int NStarSetHeader::getIFHL()
{
    return itsHdr.IFHL;
}

// set offsets of source in interferometric beam measurements
void NStarSetHeader::setDLDM(const Vector<Float>& aDldm)
{
    itsHdr.DLDM[0]=aDldm(0);
    itsHdr.DLDM[1]=aDldm(1);
}

// get offsets of source in interferometric beam measurements
Vector<Float> NStarSetHeader::getDLDM()
{
    Vector<Float> tmp(2);
    tmp(0)=itsHdr.DLDM[0];
    tmp(1)=itsHdr.DLDM[1];
    return tmp;
}
