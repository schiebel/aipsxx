//# NStarScan.h : class for access to Newstar Scans
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
//# $Id: NStarScan.h,v 19.3 2004/11/30 17:50:39 ddebonis Exp $

#ifndef NFRA_NSTARSCAN_H
#define NFRA_NSTARSCAN_H
 

//# Includes
#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/iosfwd.h>
#include <casa/namespace.h>

class NStarScan
{
public:

    // Constructor NStar Scan
    NStarScan();

    // Destructor NStar Scan
    ~NStarScan();

    // Get size of NStarScan struct
    uInt getSize() const;

    // Write SCH and its data in File.
    // Return its position.
    uLong write(const Short* data, uInt nrval, std::ofstream& aFile);

    // set APP. HA (CIRCLES)
    void setHA(Float aHa);

    // get APP. HA (CIRCLES)
    Float getHA();

    // set COS/SIN MAX (W.U.)
    void setMAX(Float aMax);

    // get COS/SIN MAX (W.U.)
    Float getMAX();

    // set COS/SIN SCALE MULTIPLIER - 1
    void setSCAL(Float aScal);

    // get COS/SIN SCALE MULTIPLIER - 1
    Float getSCAL();

    // set REDUNDANCY NOISE (W.U., G/P)
    void setREDNS(const Vector<Float>& aRedns);

    // get REDUNDANCY NOISE (W.U., G/P)
    Vector<Float> getREDNS();

    // set REDUNDANCY NOISE (W.U., G/P)
    void setREDNSY(const Vector<Float>& aRednsy);

    // get REDUNDANCY NOISE (W.U., G/P)
    Vector<Float> getREDNSY();

    // set ALIGN NOISE (W.U., G/P)
    void setALGNS(const Vector<Float>& aAlgns);

    // get ALIGN NOISE (W.U., G/P)
    Vector<Float> getALGNS();
    
    // set ALIGN NOISE (W.U., G/P)
    void setALGNSY(const Vector<Float>& aAlgnsy);
    
    // get ALIGN NOISE (W.U., G/P)
    Vector<Float> getALGNSY();
    
    // set OTHER NOISE (W.U. G/P)
    void setOTHNS(const Vector<Float>& aOthns);
    
    // get OTHER NOISE (W.U. G/P)
    Vector<Float> getOTHNS();
    
    // set OTHER NOISE (W.U. G/P)
    void setOTHNSY(const Vector<Float>& aOthnsy);
    
    // get OTHER NOISE (W.U. G/P)
    Vector<Float> getOTHNSY();
    
    // set GENERAL BITS (8-15: flag bits)
    void setBITS(Int aBits);
    
    // get GENERAL BITS (8-15: flag bits)
    Int getBITS();
    
    // set CLOCK CORRECTION (sec)
    void setCLKC(Float aClkc);
    
    // get CLOCK CORRECTION (sec)
    Float getCLKC();
    
    // set APPL. CLOCK CORRECTION (sec)
    void setACLKC(Float aAclkc);
    
    // get APPL. CLOCK CORRECTION (sec)
    Float getACLKC();
    
    // set IONOS. REFRACT. (CIRCLES/km)
    void setIREF(Float aIref);
    
    // get IONOS. REFRACT. (CIRCLES/km)
    Float getIREF();
    
    // set EXTINCTION FACTOR -1
    void setEXT(Float aExt);
    
    // get EXTINCTION FACTOR -1
    Float getEXT();
    
    // set REFRACTION (MU-1)
    void setREFR(Float aRefr);
    
    // get REFRACTION (MU-1)
    Float getREFR();
    
    // set FARADAY ROTATION (RADIANS)
    void setFARAD(Float aFarad);
    
    // get FARADAY ROTATION (RADIANS)
    Float getFARAD();
    
    // set X REDUNDANCY CORRECTION
    void setREDC(const Matrix<Float>& aRedc);
    
    // get X REDUNDANCY CORRECTION
    Matrix<Float> getREDC();
    
    // set Y REDUNDANCY CORRECTION
    void setREDCY(const Matrix<Float>& aRedcy);
    
    // get Y REDUNDANCY CORRECTION
    Matrix<Float> getREDCY();
    
    // set X ALIGN CORRECTION (LOG)
    void setALGC(const Matrix<Float>& aAlgc);
    
    // get X ALIGN CORRECTION (LOG)
    Matrix<Float> getALGC();
    
    // set Y ALIGN CORRECTION (LOG)
    void setALGCY(const Matrix<Float>& aAlgcy);
    
    // get Y ALIGN CORRECTION (LOG)
    Matrix<Float> getALGCY();
    
    // set X OTHER CORRECTION (LOG)
    void setOTHC(const Matrix<Float>& aOthc);
    
    // get X OTHER CORRECTION (LOG)
    Matrix<Float> getOTHC();
    
    // set Y OTHER CORRECTION (LOG)
    void setOTHCY(const Matrix<Float>& aOthcy);
    
    // get Y OTHER CORRECTION (LOG)
    Matrix<Float> getOTHCY();
    
    // set POINTER TO ADD IFR CORRECTIONS
    void setIFRAC(Int aIfrac);
    
    // get POINTER TO ADD IFR CORRECTIONS
    Int getIFRAC();
    
    // set POINTER TO MUL. IFR CORRNS
    void setIFRMC(Int aIfrmc);
    
    // get POINTER TO MUL. IFR CORRNS
    Int getIFRMC();
    
    // set APPLIED EXTINCTION FACTOR -1
    void setAEXT(Float aAext);
    
    // get APPLIED EXTINCTION FACTOR -1
    Float getAEXT();
    
    // set APPLIED REFRACTION (MU-1)
    void setAREFR(Float aArefr);
    
    // get APPLIED REFRACTION (MU-1)
    Float getAREFR();
    
    // set APPLIED FARADAY rotation
    void setAFARAD(Float aAfarad);
    
    // get APPLIED FARADAY rotation
    Float getAFARAD();
    
    // set X APPLIED OTHER CORRECTION
    void setAOTHC(const Matrix<Float>& aAothc);
    
    // get X APPLIED OTHER CORRECTION
    Matrix<Float> getAOTHC();
    
    // set Y APPLIED OTHER CORRECTION
    void setAOTHCY(const Matrix<Float>& aAothcy);
    
    // get Y APPLIED OTHER CORRECTION
    Matrix<Float> getAOTHCY();
    
    // set PTR TO APPL. ADD IFR CORRN
    void setAIFRAC(Int aAifrac);
    
    // get PTR TO APPL. ADD IFR CORRN
    Int getAIFRAC();
    
    // set PTR TO APPL. MUL IFR CORRN
    void setAIFRMC(Int aAifrmc);
    
    // get PTR TO APPL. MUL IFR CORRN
    Int getAIFRMC();
    
    // set PARALL. ANGLE (CIRCLES)
    void setPANG(Float aPang);
    
    // get PARALL. ANGLE (CIRCLES)
    Float getPANG();
    
    // set APPLIED IONOSPH.. REFRCTN
    void setAIREF(Float aAiref);
    
    // get APPLIED IONOSPH.. REFRCTN
    Float getAIREF();
    
    // set 1 = AOTH DE-APPLIED
    void setAOTHUSED(Int aAothused);
    
    // get 1 = AOTH DE-APPLIED
    Int getAOTHUSED();

private:

    struct SCH {
	// APP. HA (CIRCLES)
	Float HA;
	// COS/SIN MAX (W.U.)
	Float MAX;
	// COS/SIN SCALE MULTIPLIER - 1
	Float SCAL;
	// REDUNDANCY NOISE (W.U., G/P)
	Float REDNS[2];
	// REDUNDANCY NOISE (W.U., G/P)
	Float REDNSY[2];
	// ALIGN NOISE (W.U., G/P)
	Float ALGNS[2];
	// ALIGN NOISE (W.U., G/P)
	Float ALGNSY[2];
	// OTHER NOISE (W.U. G/P)
	Float OTHNS[2];
	// OTHER NOISE (W.U. G/P)
	Float OTHNSY[2];
	// GENERAL BITS (8-15: flag bits)
	Int BITS;
	// CLOCK CORRECTION (sec)
	Float CLKC;
	// APPL. CLOCK CORRECTION (sec)
	Float ACLKC;
	// IONOS. REFRACT. (CIRCLES/km)
	Float IREF;
	// EXTINCTION FACTOR -1
	Float EXT;
	// REFRACTION (MU-1)
	Float REFR;
	// FARADAY ROTATION (RADIANS)
	Float FARAD;
	// X REDUNDANCY CORRECTION
	Float REDC[14][2];
	// Y REDUNDANCY CORRECTION
	Float REDCY[14][2];
	// X ALIGN CORRECTION (LOG)
	Float ALGC[14][2];
	// Y ALIGN CORRECTION (LOG)
	Float ALGCY[14][2];
	// X OTHER CORRECTION (LOG)
	Float OTHC[14][2];
	// Y OTHER CORRECTION (LOG)
	Float OTHCY[14][2];
	// POINTER TO ADD IFR CORRECTIONS
	Int IFRAC;
	// POINTER TO MUL. IFR CORRNS
	Int IFRMC;
	// APPLIED EXTINCTION FACTOR -1
	Float AEXT;
	// APPLIED REFRACTION (MU-1)
	Float AREFR;
	// APPLIED FARADAY rotation
	Float AFARAD;
	// X APPLIED OTHER CORRECTION
	Float AOTHC[14][2];
	// Y APPLIED OTHER CORRECTION
	Float AOTHCY[14][2];
	// PTR TO APPL. ADD IFR CORRN
	Int AIFRAC;
	// PTR TO APPL. MUL IFR CORRN
	Int AIFRMC;
	// PARALL. ANGLE (CIRCLES)
	Float PANG;
	// APPLIED IONOSPH.. REFRCTN
	Float AIREF;
	// 1 = AOTH DE-APPLIED
	Int AOTHUSED;
    } itsHdr;

};


#endif
