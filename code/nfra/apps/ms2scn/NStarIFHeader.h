//# NStarIFHeader.h : class for access to Newstar IF Header
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
//# $Id: NStarIFHeader.h,v 19.3 2004/11/30 17:50:39 ddebonis Exp $

#ifndef NFRA_NSTARIFHEADER_H
#define NFRA_NSTARIFHEADER_H
 

//# Includes
#include <casa/aips.h>
#include <casa/Arrays/Matrix.h>
#include <NStarScan.h>
#include <casa/iosfwd.h>
#include <casa/namespace.h>

class NStarIFHeader
{
public:

  // Constructor NStar IF Header
  NStarIFHeader();
  
  // Destructor NStar IF Header
  ~NStarIFHeader();
  
  //set BAND NUMBER
  void setCHAN(Short aChan);
  
  // get BAND NUMBER
  Short getCHAN();
  
  // set PRINCIPLE GAIN CORRECTIONMETHOD
  void setGCODE(Short aGCODE);
  
  // get PRINCIPLE GAIN CORRECTIONMETHOD
  Short getGCODE();
  
  // set ACTUAL GAIN CORRECTION METHOD
  void setGNCAL(const Matrix<Short>& aGNCAL);
  
  // get ACTUAL GAIN CORRECTION METHOD
  Matrix<Short> getGNCAL();
  
  // set CONSTANT SYSTEM TEMPERATURE
  void setTSYSI(const Matrix<Float>& aTSYSI);
  
  // get CONSTANT SYSTEM TEMPERATURE
  Matrix<Float> getTSYSI();
  
  // set CONSTANT RECEIVER GAIN
  void setRGAINI(const Matrix<Float>& aRGAINI);
  
  // get CONSTANT RECEIVER GAIN
  Matrix<Float> getRGAINI();
  
  // set CONSTANT NOISE TEMPERATURE
  void setTNOISEI(const Matrix<Float>& aNOISEI);
  
  // get CONSTANT NOISE TEMPERATURE
  Matrix<Float> getTNOISEI();
  
  // set TOTAL POWER INTEGRATIONTIME
  void setTPINT(Int aTPINT);
  
  // get TOTAL POWER INTEGRATIONTIME
  Int getTPINT();
  
  // set FIRST HA APP.
  void setHAB(Float aHAB);
  
  // get FIRST HA APP.
  Float getHAB();
  
  // set HA INCREMENT
  void setHAI(Float aHAI);
  
  // get HA INCREMENT
  Float getHAI();
  
  // set #TOTAL POWER SCANS
  void setNTP(Int aNTP);
  
  // get #TOTAL POWER SCANS
  Int getNTP();
  
  // set #IF GAIN/PHASE SCANS
  void setNIF(Int aNIF);
  
  // get #IF GAIN/PHASE SCANS
  Int getNIF();
  
  // set HAB FROM IFBLOCK
  void setIFHAB(Float anIFHAB);
  
  // get HAB FROM IFBLOCK
  Float getIFHAB();
  
  // Write IFHeader
  Bool write(std::ofstream& aFile);

  // get FilePtr
  Int getAddress();

  // set FilePtr
  void setAddress(Int anAddress);

  // return the size of the header struct
  Int getIFHSize();

private:

  Int itsAddress;

  struct NStarIFH {
    // BAND NUMBER
    Short CHAN;                              
    // PRINCIPAL GAIN CORRECTION METHOD
    Short GCODE;                              
    // ACTUAL GAIN CORRECTION METHOD
    Short GNCAL[14][2];                                
    // RESERVED
    Char IFH__0001[4];                     
    // CONSTANT SYSTEM TEMPERATURE
    Float TSYSI[14][2];                             
    // RESERVED
    Char IFH__0002[16];                     
    // CONSTANT RECEIVER GAIN
    Float RGAINI[14][2];                              
    // RESERVED
    Char IFH__0003[16];                     
    // CONSTANT NOISE TEMPERATURE
    Float TNOISEI[14][2];                         
    // RESERVED
    Char IFH__0004[16];                     
    // TOTAL POWER INTEGRATION TIME
    Int TPINT;                              
    // FIRST HA. APP.
    Float HAB;                       
    // HA. INCREMENT
    Float HAI;                             
    // # OF TOTAL POWER SCANS
    Int NTP;                            
    // # OF PHASE GAIN SCANS
    Int NIF;                              
    // HAB FOR IH BLOCK
    Float IFHAB;
    // RESERVED
    Char IFH__0005[40];                     
  } itsHdr;
};


#endif
