//#---------------------------------------------------------------------------
//# Monitor.h: Buffers and averages data for Parkes Multibeam data display.
//#---------------------------------------------------------------------------
//# Copyright (C) 1998-2006
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but
//# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
//# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//# License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: Monitor.h,v 19.9 2006/05/19 04:42:15 mcalabre Exp $
//----------------------------------------------------------------------------
// Original: Taisheng Ye, restructured by Tom Oosterloo.
//----------------------------------------------------------------------------

#ifndef ATNF_MONITOR_H
#define ATNF_MONITOR_H

#include <casa/aips.h>
#include <casa/Arrays/Cube.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Slice.h>
#include <casa/Arrays/Vector.h>
#include <tasking/Glish/GlishEvent.h>
#include <tasking/Glish/GlishValue.h>


#include <casa/namespace.h>
class Monitor {
  public :
    Monitor();
    Bool defaultHandler(GlishSysEvent &event);
    Bool initHandler(GlishSysEvent &event);
    Bool newdataHandler(GlishSysEvent &event, uInt &nRec);
    Bool flushHandler(GlishSysEvent &event);

  private :
    // Control parameters.
    Bool cDoFreq, cDoHanning, cDoTime, cFlagBlank, cSumSpec;
    Int  cBuffLen, cChanEnd, cChanSkip, cChanStart, cMaxSpec, cNBeam,
         cNChanIn, cNIF, cNPol;
    enum {POL_NONE, POL_A, POL_B, POL_AVG, POL_DIF} cPols1, cPols2;
    enum {IF_NONE, IF_1, IF_2, IF_BOTH, IF_LEN} cIFs1, cIFs2;
    enum {NONE, MEAN, MEDIAN, MAXIMUM, RMS} cTimeMode;

    // Work variables.
    Bool   cBeamSw, cInitialized, cSimulIF, cWantIF1, cWantIF2;
    Int    cCount, cEmit, cIndx, cIntNo, cPrevIntNo;
    Float  cBlank;
    Double cIntTime;
    String cIFid1, cIFid2, cObstype;

    Vector<Bool>   cIFparms;
    Vector<Double> cFreqInc, cHdrFreq, cRefFreq;

    Vector<Bool>   cBeamMask;
    Vector<uInt>   cIFseq;
    Vector<Int>    cSpecRefbeam;
    Matrix<Int>    cSpecBeam;
    Matrix<Double> cSpecDec, cSpecRa, cSpecTime;
    Cube<Float>    cSpecData1, cSpecData2;

    Int            cChanSep, cIFboth, cNChanSel;
    Matrix<Int>    cFirstInChan, cFirstOutChan, cLength;

    // Helper functions.
    Bool   scrollBufferFull() ;
    void   sendScrollBuffer(GlishSysEventSource *glishBus);
    Bool   makeScrollMap(Int ifCode, Int polCode, Cube<Float> &map,
                         Double &datTime, Vector<Int> &datBeam,
                         Vector<Double> &datRa, Vector<Double> &datDec);
    Bool   copyRowToMap(Int iBeam, Int ifCode, Int polCode, Double &datTime,
                        Double &datRa, Double &datDec, Cube<Float> &map);
    Bool   getSpectrum(Int ibuff, Int beamNo, Int ifCode, Int polCode,
                       Vector<Float> &spectrum);
    void   getChannel(Int ibuff, Int channel, Int iBeam, Int ifCode,
                      Int polCode, Vector<Float> &buff);
    Int    scrollIndex(Int ibuff);
};

#endif
