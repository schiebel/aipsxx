//# NStarSetHeader.h : class for access to Newstar Set Header
//# Copyright (C) 1997,1998,2000,2001
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
//# $Id: NStarSetHeader.h,v 19.3 2004/11/30 17:50:39 ddebonis Exp $

#ifndef NFRA_NSTARSETHEADER_H
#define NFRA_NSTARSETHEADER_H
 

//# Includes
#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Containers/List.h>
#include <casa/Containers/ListIO.h>
#include <NStarSet.h>
#include <NStarScan.h>
#include <NStarIfrTable.h>
#include <casa/namespace.h>

class NStarSetHeader: public NStarSet
{
public:

    // Constructor NStar Set Header
    NStarSetHeader();

    // Destructor NStar Set Header
    ~NStarSetHeader();

    // Add a NStar Scan to the list
    void setScan(uLong pos, uInt size);

    // Set the IFR-table for this set
    void setIfrTable(NStarIfrTable* aTable);

    // Set the spectral window id.
    void setSpwid (uInt spwid)
        { itsSpwid = spwid; }

    // Get the spectral window id.
    uInt getSpwid() const
        { return itsSpwid; }

    // set BACKEND CONFIGURATION
    void setBEC(Short aBec);
    
    // get BACKEND CONFIGURATION
    Short getBEC();
    
    // set POINTING SET #
    void setPTS(Short aPts);
    
    // get POINTING SET #
    Short getPTS();
    
    // set OBS # (=VOLG+CYCLUS*65536)
    void setVNR(Int aVnr);
    
    // get OBS # (=VOLG+CYCLUS*65536)
    Int getVNR();
    
    // set BAND/CHANNEL NUMBER
    void setCHAN(Short aChan);
    
    // get BAND/CHANNEL NUMBER
    Short getCHAN();
    
    // set # OF POLARISATIONS
    void setPLN(Short aPln);
    
    // get # OF POLARISATIONS
    Short getPLN();
    
    // set FIELDNAME
    void setFIELD(const Char* aField);
    
    // get FIELDNAME
    Char* getFIELD();
    
    // set OBS RA (CIRCLES)
    void setRA(Double aRa);
    
    // get OBS RA (CIRCLES)
    Double getRA();
    
    // set OBS DEC
    void setDEC(Double aDec);
    
    // get OBS DEC
    Double getDEC();
    
    // set EPOCH RA
    void setRAE(Double aRae);
    
    // get EPOCH RA
    Double getRAE();
    
    // set EPOCH DEC
    void setDECE(Double aDece);
    
    // get EPOCH DEC
    Double getDECE();
    
    // set FIRST HA APP.
    void setHAB(Float aHab);
    
    // get FIRST HA APP.
    Float getHAB();
    
    // set HA INCREMENT
    void setHAI(Float aHai);
    
    // get HA INCREMENT
    Float getHAI();
    
    // set # OF SCANS
    void setSCN(Int aScn);
    
    // get # OF SCANS
    Int getSCN();
    
    // set OBS. EPOCH (E.G. 1980.12)
    void setOEP(Float aOep);
    
    // get OBS. EPOCH (E.G. 1980.12)
    Float getOEP();
    
    // set EPOCH (E.G. 2000.0)
    void setEPO(Float aEpo);
    
    // get EPOCH (E.G. 2000.0)
    Float getEPO();
    
    // set APP. FREQUENCY
    void setFRQ(Double aFrq);
    
    // get APP. FREQUENCY
    Double getFRQ();
    
    // set LSR FREQUENCY
    void setFRQE(Double aFrqe);
    
    // get LSR FREQUENCY
    Double getFRQE();
    
    // set BANDWIDTH (MHZ)
    void setUBAND(Float aUband);
    
    // get BANDWIDTH (MHZ)
    Float getUBAND();
    
    // set AVERAGING HA (CIRCLES)
    void setHAV(Float aHav);
    
    // get AVERAGING HA (CIRCLES)
    Float getHAV();
    
    // set OBS. DAY/YEAR
    void setOBS(const Vector<Short>& aObs);
    
    // get OBS. DAY/YEAR
    Vector<Short> getOBS();
    
    // set TEL. POSITIONS
    void setRTP(const Vector<Float>& aRtp);
    
    // get TEL. POSITIONS
    Vector<Float> getRTP();
    
    // set # OF IFRS
    void setNIFR(Int aNifr);
    
    // get # OF IFRS
    Int getNIFR();
    
    // set POINTER TO IFR LIST
    void setIFRP(Int aIfrp);
    
    // get POINTER TO IFR LIST
    Int getIFRP();
    
    // set FD BLOCK
    void setNFD(Int aNfd);
    
    // get FD BLOCK
    Int getNFD();
    
    // set POINTER TO FD                             
    void setFDP(Int aFdp);
    
    // get POINTER TO FD                             
    Int getFDP();
    
    // set LENGTH OH
    void setNOH(Int aNoh);
    
    // get LENGTH OH
    Int getNOH();
    
    // set POINTER TO OH
    void setOHP(Int aOhp);
    
    // get POINTER TO OH
    Int getOHP();
    
    // set SC BLOCK
    void setNSC(Int aNsc);
    
    // get SC BLOCK
    Int getNSC();
    
    // set POINTER TO SC                             
    void setSCP(Int aScp);
    
    // get POINTER TO SC                             
    Int getSCP();
    
    // set SH BLOCK
    void setNSH(Int aNsh);
    
    // get SH BLOCK
    Int getNSH();
    
    // set POINTER TO SH                             
    void setSHP(Int aShp);
    
    // get POINTER TO SH                             
    Int getSHP();
    
    // set POINTER TO SCAN AREA
    void setSCNP(Int aScnp);
    
    // get POINTER TO SCAN AREA
    Int getSCNP();
    
    // set LENGTH OF SCAN
    void setSCNL(Int aScnl);
    
    // get LENGTH OF SCAN
    Int getSCNL();
    
    // set X REDUNDANCY NOISE (G/P)
    void setREDNS(const Vector<Float>& aRedns);
    
    // get X REDUNDANCY NOISE (G/P)
    Vector<Float> getREDNS();
    
    // set Y REDUNDANCY NOISE (G/P)
    void setREDNSY(const Vector<Float>& aRednsy);
    
    // get Y REDUNDANCY NOISE (G/P)
    Vector<Float> getREDNSY();
    
    // set X ALIGN NOISE
    void setALGNS(const Vector<Float>& aAlgns);
    
    // get X ALIGN NOISE
    Vector<Float> getALGNS();
    
    // set Y ALIGN NOISE
    void setALGNSY(const Vector<Float>& aAlgnsy);
    
    // get Y ALIGN NOISE
    Vector<Float> getALGNSY();
    
    // set X OTHER NOISE
    void setOTHNS(const Vector<Float>& aOthns);
    
    // get X OTHER NOISE
    Vector<Float> getOTHNS();
    
    // set Y OTHER NOISE
    void setOTHNSY(const Vector<Float>& aOthnsy);
    
    // get Y OTHER NOISE
    Vector<Float> getOTHNSY();
    
    // set POINTER TO MODEL LISTS
    void setMDL(const Vector<Int>& aMdl);
    
    // get POINTER TO MODEL LISTS
    Vector<Int> getMDL();
    
    // set POINTER TO MODEL DATA
    void setMDD(const Vector<Int>& aMdd);
    
    // get POINTER TO MODEL DATA
    Vector<Int> getMDD();
    
    // set PRECESSION ROT. ANGLE
    void setPHI(Float aPhi);
    
    // get PRECESSION ROT. ANGLE
    Float getPHI();
    
    // set X POL. CORRECTIONS
    void setPOLC(const Matrix<Float>& aPolc);
    
    // get X POL. CORRECTIONS
    Matrix<Float> getPOLC();
    
    // set Y POL. CORRECTIONS
    void setPOLCY(const Matrix<Float>& aPolcy);
    
    // get Y POL. CORRECTIONS
    Matrix<Float> getPOLCY();
    
    // set REST FREQUENCY FOR LINE
    void setFRQ0(Double aFrq0);
    
    // get REST FREQUENCY FOR LINE
    Double getFRQ0();
    
    // set REAL FREQUENCY FOR LINE
    void setFRQV(Double aFrqv);
    
    // get REAL FREQUENCY FOR LINE
    Double getFRQV();
    
    // set CENTRE FREQUENCY FOR LINE
    void setFRQC(Double aFrqc);
    
    // get CENTRE FREQUENCY FOR LINE
    Double getFRQC();
    
    // set VELOCITY FOR LINE (M/S)
    void setVEL(Float aVel);
    
    // get VELOCITY FOR LINE (M/S)
    Float getVEL();
    
    // set VELOCITY CODE:
    void setVELC(Int aVelc);
    
    // get VELOCITY CODE:
    Int getVELC();
    
    // set START MJD (DAYS)
    void setMJD(Double aMjd);
    
    // get START MJD (DAYS)
    Double getMJD();
    
    // set CONVERSION UT/ST DAY LENGTH
    void setUTST(Double aUtst);
    
    // get CONVERSION UT/ST DAY LENGTH
    Double getUTST();
    
    // set INSTRUMENT:
    void setINST(Int aInst);
    
    // get INSTRUMENT:
    Int getINST();
    
    // set VELOCITY AT REF. FREQ. (FRQC)
    void setVELR(Float aVelr);
    
    // get VELOCITY AT REF. FREQ. (FRQC)
    Float getVELR();
    
    // set 1-FACTOR TO ABS. SCH WEIGHTS
    void setWFAC(Float aWfac);
    
    // get 1-FACTOR TO ABS. SCH WEIGHTS
    Float getWFAC();
    
    // set DE-APPLY L-M SHIFT IN ARCSEC
    void setSHFT(const Vector<Float>& aShft);
    
    // get DE-APPLY L-M SHIFT IN ARCSEC
    Vector<Float> getSHFT();
    
    // set APPLY SHIFT (NOWHERE SET)
    void setASHFT(const Vector<Float>& aAshft);
    
    // get APPLY SHIFT (NOWHERE SET)
    Vector<Float> getASHFT();
    
    // set DIPOLE CODE: TEL # * 4 * CODE:
    void setDIPC(Int aDipc);
    
    // get DIPOLE CODE: TEL # * 4 * CODE:
    Int getDIPC();
    
    // set AMPL. CORRECTION METHOD:
    void setACORM(Int aAcorm);
    
    // get AMPL. CORRECTION METHOD:
    Int getACORM();
    
    // set DE-APPLY SHIFT rate (L,M IN ARCSEC PER DAY)
    void setDSHFT(const Vector<Float>& aDshft);
    
    // get DE-APPLY SHIFT rate (L,M IN ARCSEC PER DAY)
    Vector<Float> getDSHFT();
    
    // set POINTER TO Tot.Power/IF area
    void setIFHP(Int aIfhp);
    
    // get POINTER TO Tot.Power/IF area
    Int getIFHP();
    
    // set LENGTH  OF Tot.Power/IF-DATA
    void setIFHL(Int aIfhl);
    
    // get LENGTH  OF Tot.Power/IF-DATA
    Int getIFHL();
    
    // set offsets of source in interferometric beam measurements
    void setDLDM(const Vector<Float>& aDldm);
    
    // get offsets of source in interferometric beam measurements
    Vector<Float> getDLDM();

protected:
 
    // Write STH in File
    virtual void doWrite(std::ofstream& aFile);

private:

    // Spectral window id (band number)
    uInt itsSpwid;

    // The IFR-table for this NStarIfrTable
    NStarIfrTable* itsIfrTable;

    struct NStarSTH
	{
	    // BACKEND CONFIGURATION
	    Short BEC;                              
	    // POINTING SET #
	    Short PTS;                              
	    // OBS # (=VOLG+CYCLUS*65536)
	    Int VNR;                                
	    // BAND NUMBER (DCB), CHANNEL NUMBER (DZB)
	    Short CHAN;                             
	    // # OF POLARISATIONS
	    Short PLN;                              
	    // FIELDNAME
	    Char FIELD[12];                         
	    // OBS RA (CIRCLES)
	    Double RA;                              
	    // OBS DEC
	    Double DEC;                             
	    // EPOCH RA
	    Double RAE;                             
	    // EPOCH DEC
	    Double DECE;                            
	    // FIRST HA APP.
	    Float HAB;                              
	    // HA INCREMENT
	    Float HAI;                              
	    // # OF SCANS
	    Int SCN;                                
	    // OBS. EPOCH (E.G. 1980.12)
	    Float OEP;                              
	    // EPOCH (E.G. 2000.0)
	    Float EPO;                              
	    // RESERVED
	    Float STH__0000;
	    // APP. FREQUENCY
	    Double FRQ;                             
	    // LSR FREQUENCY
	    Double FRQE;                            
	    // BANDWIDTH (MHZ)
	    Float UBAND;                             
	    // AVERAGING HA (CIRCLES)
	    Float HAV;                              
	    // OBS. DAY/YEAR
	    Short OBS[2];                           
	    // TEL. POSITIONS
	    Float RTP[14];                          
	    // # OF IFRS
	    Int NIFR;                               
	    // POINTER TO IFR LIST
	    Int IFRP;                               
	    // FD BLOCK
	    Int NFD;                                
	    // POINTER TO FD
	    Int FDP;
	    // LENGTH OH
	    Int NOH;                                
	    // POINTER TO OH
	    Int OHP;                                
	    // SC BLOCK
	    Int NSC;                                
	    // POINTER TO SC
	    Int SCP;
	    // SH BLOCK
	    Int NSH;                                
	    // POINTER TO SH
	    Int SHP;
	    // POINTER TO SCAN AREA
	    Int SCNP;                               
	    // LENGTH OF SCAN
	    Int SCNL;                               
	    // X REDUNDANCY NOISE (G/P)
	    Float REDNS[2];                         
	    // Y REDUNDANCY NOISE (G/P)
	    Float REDNSY[2];                        
	    // X ALIGN NOISE
	    Float ALGNS[2];                         
	    // Y ALIGN NOISE
	    Float ALGNSY[2];                        
	    // X OTHER NOISE
	    Float OTHNS[2];                         
	    // Y OTHER NOISE
	    Float OTHNSY[2];                        
	    // POINTER TO MODEL LISTS
	    Int MDL[2];                             
	    // POINTER TO MODEL DATA
	    Int MDD[2];                             
	    // PRECESSION ROT. ANGLE
	    Float PHI;                              
	    
	    // (G/P=orient./ellipt., radians)
	    // X POL. CORRECTIONS
	    Float POLC[14][2];
	    // Y POL. CORRECTIONS
	    Float POLCY[14][2];
	    
	    // REST FREQUENCY FOR LINE
	    Double FRQ0;                            
	    // REAL FREQUENCY FOR LINE
	    Double FRQV;                            
	    // CENTRE FREQUENCY FOR LINE
	    Double FRQC;                            
	    // VELOCITY FOR LINE (M/S)
	    Float VEL;                              
	    // VELOCITY CODE:
	    // 0= CONTINUUM
	    // 1=HELIOCENTRIC RADIO
	    // 2= LSR RADIO
	    // 3= HELIOCENTRIC OPTICAL
	    // 4= LSR OPTICAL
	    Int VELC;                               
	    // START MJD (DAYS)
	    Double MJD;                             
	    // CONVERSION UT/ST DAY LENGTH
	    Double UTST;                            
	    // INSTRUMENT:
	    // 0= WSRT
	    // 1= ATCA
	    Int INST;                               
	    // VELOCITY AT REF. FREQ. (FRQC)
	    Float VELR;                             
	    // 1-FACTOR TO ABS. SCH WEIGHTS
	    Float WFAC;
	    // DE-APPLY L-M SHIFT IN ARCSEC
	    Float SHFT[2];                          
	    // APPLY SHIFT (NOWHERE SET)
	    Float ASHFT[2];                         
	    // DIPOLE CODE: TEL # * 4 * CODE:
	    // 0     = 0 DEG (VERT) X DIPOLE
	    // 1,2,3 = 45, 90, 135 DEG
	    // STANDARD PARALLEL: 2 .........
	    // STANDARD CROSS:    2 .... 1111
	    Int DIPC;                               
	    // AMPL. CORRECTION METHOD:
	    // 0 = STANDARD
	    // 1 = CORRELATION COEFF. GIVEN
	    Int ACORM;                              
	    // DE-APPLY SHIFT rate (L,M IN ARCSEC PER DAY)
	    Float DSHFT[2];
	    // POINTER TO Tot.Power/IF area
	    Int IFHP;                               
	    // LENGTH  OF Tot.Power/IF-DATA
	    Int IFHL;                               
	    // offsets of source in interferometric beam measurements
	    Float DLDM[2];                          
	    // RESERVED
	    Char STH__0001[12];                     
  	} itsHdr;

};


#endif
