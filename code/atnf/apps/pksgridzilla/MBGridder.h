//----------------------------------------------------------------------------
// MBGridder.h: grid single-dish data and write out as a FITS cube.
//----------------------------------------------------------------------------
//# Copyright (C) 1994-2004
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//# License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: MBGridder.h,v 19.12 2005/05/27 08:06:48 mcalabre Exp $
//#---------------------------------------------------------------------------
//# MBGridder reads Parkes multibeam or other single dish spectral line data
//# from a collection of input data files and grids them into a FITS image
//# cube.
//#
//# A robust median gridding algorithm is provided (among others) so immunity
//# to bad data is high (if the sky is sufficiently oversampled).
//#
//# To avoid excessive memory usage the output may be split over multiple
//# FITS files.
//#---------------------------------------------------------------------------

#ifndef ATNF_MBGRIDDER_H
#define ATNF_MBGRIDDER_H

#include <casa/aips.h>
#include <casa/Arrays/Cube.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>

#include <fitsio.h>


#include <casa/namespace.h>
class SourceParm {
  public:
    SourceParm() {nSrc = 0;}

    // Simulation source parameters.
    uInt nSrc;
    Vector<Double> dLng, dLat, flux, width;
    Vector<Int> startChan, endChan;
};

class MBGridder {
  public:
    // Dummy constructor.
    MBGridder ();

    // Constructor.
    MBGridder (
        const String polMode,
        const Vector<String> inFiles,
        const String projection,
        const Vector<Double> pv,
        const String coordSys,
        const Bool   refPoint,
        const Double refLng,
        const Double refLat,
        const Double lonpole,
        const Double latpole,
        const Bool   autoSize,
        const Bool   intRefPix,
        const Double centreLng,
        const Double centreLat,
        const Int    mapWidth,
        const Int    mapHeight,
        const Float  pixelWidth,
        const Float  pixelHeight,
        const Float  beamFWHM,
        const Float  cutoffRadius,
        const String FITSfilename,
        const Int    noSpec,
        const Matrix<Float> &celCrd,
        const Vector<Bool>  &nightFlag,
        const String countsType);

    // Destructor.
    ~MBGridder();

    // Set or reset interpolation parameters.
    void setInterp(
        const String statistic,
        const Float  clipFraction,
        const Bool   tsysWeight,
        const Int    beamWeight,
        const Bool   beamNormal,
        const String kernelType,
        const Float  kernelFWHM,
        const Float  blankLevel);

    // Set FITS spectral axis keywords and add simulation sources.
    Bool setSpectra(
        const Int chanOffset,
        const Int    NAXIS3,
        const Double CRPIX3,
        const Double CDELT3,
        const Double CRVAL3,
        const String CTYPE3,
        const Double restFreq,
        const String specSys,
        Cube<Float> &specData,
        const SourceParm& sources);

    // Construct continuum and spectral index maps from baseline data.
    Bool formCont(const Cube<Float>   &contData,
                  const Matrix<Float> &tsysData);

    // Construct maps of the baseline polynomial coefficients.
    Bool formBase(const Cube<Float>   &baseData,
                  const Matrix<Float> &tsysData);

    // Construct a spectral data cube.
    Bool formCube(const Matrix<Float> &tsysData,
                  const Bool   doShort,
                  const String passCode);

  private:
    // These do much of the dirty work for the constructor.
    void findMapCentre(Double &centreLng, Double &centreLat);
    String Sexagesimal(Double angle, Int precision, Bool doTime = False);
    void findMapSize(void);
    void mapCelCrd(void);
    void findNumStack(const String countsType);
    Bool formCounts(const Matrix<Int> &specCount,
                    const Matrix<Int> &nightSpec,
                    const String &countsType,
                    const Matrix<Float> &beamRSS);

    // These do the much of the dirty work for the gridding functions.
    Bool FITSheader(fitsfile *outFile,
                    const Int  FITStype,
                    const Bool doShort);
    void formRow   (const Matrix<Float> &data,
                    const Matrix<Float> &tsys,
                    const uInt j,
                    float *mapRow);
    void buildStack(const Matrix<Float> &data,
                    const Matrix<Float> &tsys,
                    const uInt j,
                    Vector<Int>   &specCount,
                    Vector<Float> &beamSum,
                    Vector<Float> &beamRSS);

    //------------------------------------------------------------------------
    // Data.
    //------------------------------------------------------------------------
    Double cRestFreq;
    String cSpecSys;
    String cPolMode;
    Vector<String> cInFiles;
    String cStatistic;
    Float  cClipFraction;
    Bool   cTsysWeight;
    Int    cBeamWeight;
    Float  cBeamFWHM;
    Bool   cBeamNormal;
    String cKernelType;
    Float  cKernelFWHM;
    Float  cCutoffRadius;
    Float  cBlankLevel;
    String cFITSfilename;
    SourceParm cSources;

    uInt           cNoSpec;
    Vector<Float>  cSpcLng;
    Vector<Float>  cSpcLat;
    Matrix<uShort> cSpcPixSpan;
    Vector<uInt>   cSpcIdx;
    Matrix<uInt>   cSpcRowSpan;
    Vector<Bool>   cNightFlag;

    // FITS header information.
    uInt   cNAXIS1, cNAXIS2, cNAXIS3;
    Float  cBlankVal;
    Int    cBLANK;

    String cCTYPE1, cCTYPE2, cCTYPE3;
    Double cCRPIX1, cCRPIX2, cCRPIX3;
    Double cCDELT1, cCDELT2, cCDELT3;
    Double cCRVAL1, cCRVAL2, cCRVAL3;
    Double cLONPOLE, cLATPOLE;
    Vector<Double>  cPV;
    Int cPVn;

    // Celestial longitude and latitude at each pixel in the output map.
    Cube<Float> cMapCelCrd;

    // Data array.
    Int cChanOffset;
    Cube<Float> cData;

    // Data values at each pixel in a single row of a map plane.
    Matrix<Float> cDataStack;
    Matrix<Float> cWgt;

    enum {UNDEFINED,
          WGTMED,
          MEDIAN,
          MEAN,
          SUM,
          RSS,
          RMS,
          QUARTILE,
          NSPECTRA,
          WEIGHT,
          BEAMSUM,
          BEAMRSS} cStatisticId;

    enum {TOPHAT,
          GAUSSIAN} cKernelId;

    // Intermediate calculations for the gridding.
    Float cBW, cGW, cTW;
    Float cXYZCutoffSqr;
};
#endif /* ATNF_MBGRIDDER_H */
