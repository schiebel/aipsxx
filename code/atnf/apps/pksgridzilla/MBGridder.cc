//----------------------------------------------------------------------------
// MBGridder.cc: Grid single-dish data and write out as a FITS cube
//----------------------------------------------------------------------------
//# Copyright (C) 1994-2006
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
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#
//# $Id: MBGridder.cc,v 19.26 2006/07/19 07:39:17 mcalabre Exp $
//----------------------------------------------------------------------------

#include <string.h>

// AIPS++ includes.
#include <casa/iostream.h>
#include <casa/stdio.h>
#include <casa/sstream.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/MaskedArray.h>
#include <casa/Arrays/MaskArrMath.h>
#include <casa/Arrays/Slice.h>
#include <casa/BasicMath/Math.h>
#include <casa/BasicSL/Constants.h>
#include <casa/Exceptions/Error.h>
#include <casa/OS/Time.h>
#include <casa/Utilities/GenSort.h>

#include <fitsio.h>
#include <wcslib/wcs.h>

// Parkes includes.
#include <atnf/pks/pksmb_support.h>
#include <atnf/pks/pks_maths.h>

#include <MBGridder.h>

#include <casa/namespace.h>

// Range of values in spectral cubes (Jy/beam).
#define SM_VALMIN -8.0
#define SM_VALMAX 32.0

// Degrees to/from radian.
Float D2R = C::pi / 180.0;
Float R2D = 180.0 / C::pi;

//------------------------------------------------------- MBGridder::MBGridder

// Dummy constructor.
MBGridder::MBGridder() {};

//------------------------------------------------------- MBGridder::MBGridder

// Constructor for single-dish gridder.

MBGridder::MBGridder (
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
  const String countsType)
    : cInFiles(inFiles),
      cBeamFWHM(beamFWHM),
      cFITSfilename(FITSfilename),
      cNoSpec(noSpec),
      cNightFlag(nightFlag)
{
  // Magic blank value in output images.
  cBlankVal = -9.99999e36;

  // Polarization mode.
  cPolMode = upcase(polMode);

  // Celestial coordinates of the spectra (in degrees for now).
  cSpcLng = celCrd.column(0);
  cSpcLat = celCrd.column(1);

  // Coordinate type.
  if (coordSys == "EQUATORIAL") {
    cCTYPE1 = "RA---";
    cCTYPE2 = "DEC--";
  } else if (coordSys == "GALACTIC") {
    // Galactic coordinates.
    cCTYPE1 = "GLON-";
    cCTYPE2 = "GLAT-";
  } else if (coordSys == "FEED-PLANE") {
    // Feed-plane coordinates.
    cCTYPE1 = "FLON-";
    cCTYPE2 = "FLAT-";
  }

  if (projection == "NCP") {
    cCTYPE1 += "SIN";
    cCTYPE2 += "SIN";

    cPVn = 2;
    cPV.resize(3);
    cPV(0) = 0.0;
    cPV(1) = 0.0;
    cPV(2) = 1.0 / tan(refLat * D2R);

  } else {
    cCTYPE1 += projection;
    cCTYPE2 += projection;

    cPVn = 0;
    if (String("AIR CEA BON").contains(projection)) {
      cPVn = 1;
    } else if (String("AZP SIN CYP COP COE COD COO").contains(projection)) {
      cPVn = 2;
    } else if (projection == "SZP") {
      cPVn = 3;
    } else if (projection == "ZPN") {
      cPVn = 19;
    }

    cPV.resize(cPVn+1);
    for (Int ipv = 0; ipv <= cPVn; ipv++) {
      cPV(ipv) = pv(ipv);
    }
  }


  // Coordinate reference value.
  if (refPoint) {
    cCRVAL1 = refLng;
    cCRVAL2 = refLat;

  } else if (!autoSize) {
    cCRVAL1 = centreLng;
    cCRVAL2 = centreLat;

  } else {
    findMapCentre(cCRVAL1, cCRVAL2);

    logMessage("Mid position of available spectra: " +
                Sexagesimal(cCRVAL1, 0, coordSys == "EQUATORIAL") + ", " +
                Sexagesimal(cCRVAL2, 1));
  }

  if (cCRVAL1 < 0.0 || cCRVAL1 > 360.0) {
    ostringstream buffer;
    buffer << "MBGridder::MBGridder: Invalid reference longitude: "
           << cCRVAL1;
    logError(buffer);
    throw(AipsError("Invalid reference longitude."));
  }

  if (cCRVAL2 < -90.0 || cCRVAL2 > 90.0)  {
    ostringstream buffer;
    buffer << "MBGridder::MBGridder: Invalid reference latitude: "
           << cCRVAL2;
    logError(buffer);
    throw(AipsError("Invalid reference latitude."));
  }

  cLONPOLE = lonpole;
  cLATPOLE = latpole;


  // Coordinate increments.
  if (pixelWidth <= 0.0) {
    throw(AipsError("The pixel size should not be zero!!!"));
  }

  // Convert arcmin to degrees.
  cCDELT1 = -pixelWidth  / 60.0;
  cCDELT2 =  pixelHeight / 60.0;

  if (cCDELT2 == 0.0) {
    cCDELT2 = -cCDELT1;
  }

  // Compute intermediaries for the gridding calculations.
  Float fwhm = (cBeamFWHM / 60.0f) * D2R;
  cBW = log(0.5) / (fwhm * fwhm / 4.0);

  // Convert cutoff radius from arcmin to deg.
  cCutoffRadius = abs(cutoffRadius / 60.0f);


  // Determine map plane FITS header cards.
  if (autoSize) {
    // Deduce it ourselves.
    findMapSize();

  } else {
    // Map size.
    if (mapWidth <= 0 && mapHeight <= 0) {
      throw(AipsError("The map dimension must be greater than zero."));

    } else if (mapWidth <= 0) {
      cNAXIS1 = mapHeight;
      cNAXIS2 = mapHeight;

    } else if (mapHeight <= 0) {
      cNAXIS1 = mapWidth;
      cNAXIS2 = mapWidth;

    } else {
      cNAXIS1 = mapWidth;
      cNAXIS2 = mapHeight;
    }

    // Compute the reference pixel coordinate.
    struct celprm cel;
    celini(&cel);

    cel.ref[0] = cCRVAL1;
    cel.ref[1] = cCRVAL2;
    cel.ref[2] = cLONPOLE;
    cel.ref[3] = cLATPOLE;

    strcpy(cel.prj.code, cCTYPE1(5,3).chars());
    for (Int ipv = 0; ipv <= cPVn; ipv++) {
      cel.prj.pv[ipv] = cPV(ipv);
    }

    int stat;
    double phi, theta, x, y;
    cels2x(&cel, 1, 1, 1, 1, &centreLng, &centreLat, &phi, &theta, &x, &y,
      &stat);

    if (intRefPix) {
      cCRPIX1 = anint(-x/cCDELT1) + Double(cNAXIS1/2 + 1);
      cCRPIX2 = anint(-y/cCDELT2) + Double(cNAXIS2/2 + 1);
    } else {
      cCRPIX1 = -x/cCDELT1 + Double(cNAXIS1/2 + 1);
      cCRPIX2 = -y/cCDELT2 + Double(cNAXIS2/2 + 1);
    }
  }

  ostringstream buffer;
  buffer << "Map size: " << cNAXIS1 << " x " << cNAXIS2
         << ",  reference pixel: (" << cCRPIX1 << ", " << cCRPIX2
         << ").";
  logMessage(buffer);


  // Compute celestial longitude and latitude for each pixel.
  logMessage("Computing celestial coordinates for each pixel.");
  mapCelCrd();


  // Convert to radians for distance calculations.
  cSpcLng *= D2R;
  cSpcLat *= D2R;
  cCutoffRadius *= D2R;

  // Square of the Cartesian-XYZ cutoff radius.
  cXYZCutoffSqr = 2.0f * sin(cCutoffRadius / 2.0f);
  cXYZCutoffSqr *= cXYZCutoffSqr;

  // Resize stack arrays.
  logMessage("");
  logMessage("Generating indexes and determining stack sizes...");
  findNumStack(countsType);

  // Signal that the interpolation parameters have not been set.
  cStatisticId = UNDEFINED;
}

//--------------------------------------------------- MBGridder::findMapCentre

// Determine the reference point of the map projection.

void MBGridder::findMapCentre(
  Double &centreLng,
  Double &centreLat)
{
  Float lng;

  // cSpcLng ranges from 0 to 360 for longitude.
  Float minLng = min(cSpcLng);
  Float maxLng = max(cSpcLng);

  Float diffLng = maxLng - minLng;
  if (diffLng > 180.0) {
    // Looks like longitude cycles through zero.
    maxLng = -999.0;
    minLng =  999.0;

    for (uInt iSpec = 0; iSpec < cNoSpec; iSpec++) {
      lng = cSpcLng(iSpec);
      if (lng > 180.0 && lng < minLng) {
        minLng = lng;
      }
      if (lng < 180.0 && lng > maxLng) {
        maxLng = lng;
      }
    }

    diffLng = (maxLng + 360.0) - minLng;
  }

  centreLng = minLng + diffLng/2.0;
  if (centreLng > 360.0) {
    centreLng -= 360.0;
  }


  Float minLat = min(cSpcLat);
  Float maxLat = max(cSpcLat);
  centreLat = (minLat + maxLat)/2.0;
}

//----------------------------------------------------- MBGridder::Sexagesimal

// Convert an angle in degrees to sexagesimal format.

String MBGridder::Sexagesimal(
   Double angle,
   Int p,
   Bool doTime)
{
  Int deg, min, sec, dsec;

  if (doTime) {
    angle /= 15.0;
    p++;
  }

  Double tmp = abs(angle);

  deg = int(tmp);
  tmp = (tmp - deg)*60.0;

  min = int(tmp);
  tmp = (tmp - min)*60.0;

  sec = int(tmp);
  tmp = (tmp - sec)*pow(10.0, Double(p));

  dsec = int(tmp);

  if (sec == 60.0) {
    min += 1;
    sec = 0;
  }

  if (min == 60) {
    deg += 1;
    min = 0;
  }

  if (angle < 0.0) deg = -deg;

  char sexa[20];
  if (p == 0) {
    sprintf (sexa,"%3.2d:%2.2d:%2.2d",deg, min, sec);
  } else {
    sprintf (sexa,"%3.2d:%2.2d:%2.2d.%*.*d",deg, min, sec, p, p, dsec);
  }

  return String(sexa);
}

//----------------------------------------------------- MBGridder::findMapSize

// Determine the map size.

void MBGridder::findMapSize(void)
{
  struct celprm cel;
  celini(&cel);

  cel.ref[0] = cCRVAL1;
  cel.ref[1] = cCRVAL2;
  cel.ref[2] = cLONPOLE;
  cel.ref[3] = cLATPOLE;

  strcpy(cel.prj.code, cCTYPE1(5,3).chars());
  for (Int ipv = 0; ipv <= cPVn; ipv++) {
    cel.prj.pv[ipv] = cPV(ipv);
  }

  // Find the range in X and Y.
  Double xmin =  C::flt_max;
  Double xmax = -C::flt_max;
  Double ymin =  C::flt_max;
  Double ymax = -C::flt_max;

  double phi, theta, x, y;
  for (uInt iSpec = 0; iSpec < cNoSpec; iSpec++) {
    int    stat;
    double lng = cSpcLng(iSpec);
    double lat = cSpcLat(iSpec);

    if (cels2x(&cel, 1, 1, 1, 1, &lng, &lat, &phi, &theta, &x, &y, &stat)) {
      continue;
    }

    if (x < xmin) xmin = x;
    if (x > xmax) xmax = x;
    if (y < ymin) ymin = y;
    if (y > ymax) ymax = y;
  }

  // Allow for the smoothing radius.
  xmin -= cCutoffRadius;
  xmax += cCutoffRadius;
  ymin -= cCutoffRadius;
  ymax += cCutoffRadius;

  // Recall that the x-axis is inverted (cCDELT1 < 0).
  Int imin = Int(xmax/cCDELT1);
  Int imax = Int(xmin/cCDELT1);
  if (Float(imin) > xmax/cCDELT1) imin--;
  if (Float(imax) < xmin/cCDELT1) imax++;

  Int jmin = Int(ymin/cCDELT2);
  Int jmax = Int(ymax/cCDELT2);
  if (Float(jmin) > ymin/cCDELT2) jmin--;
  if (Float(jmax) < ymax/cCDELT2) jmax++;

  cNAXIS1 = imax - imin + 1;
  cNAXIS2 = jmax - jmin + 1;

  // Ensure cubes are at least 3 x 3...
  if (cNAXIS1 < 3) {
    cNAXIS1 = 3;
  }
  if (cNAXIS2 < 3) {
    cNAXIS2 = 3;
  }

  // ...and no greater than 4096 x 4096.
  if (cNAXIS1 > 4096) {
    cNAXIS1 = 4096;
  }
  if (cNAXIS2 > 4096) {
    cNAXIS2 = 4096;
  }

  // Reference pixel.
  cCRPIX1 = Float(-imin+1);
  cCRPIX2 = Float(-jmin+1);
}

//------------------------------------------------------- MBGridder::mapCelCrd

// Compute Celestial longitude and latitude for each pixel.

void MBGridder::mapCelCrd(void)
{
  struct wcsprm wcs;
  wcs.flag = -1;
  wcsini(1, 2, &wcs);

  wcs.crpix[0] = cCRPIX1;
  wcs.crpix[1] = cCRPIX2;

  double *pcij = wcs.pc;
  *(pcij++) = 1.0;
  *(pcij++) = 0.0;
  *(pcij++) = 0.0;
  *(pcij++) = 1.0;

  wcs.cdelt[0] = cCDELT1;
  wcs.cdelt[1] = cCDELT2;

  strcpy(wcs.ctype[0], cCTYPE1.chars());
  strcpy(wcs.ctype[1], cCTYPE2.chars());

  wcs.crval[0] = cCRVAL1;
  wcs.crval[1] = cCRVAL2;

  wcs.lonpole = cLONPOLE;
  wcs.latpole = cLATPOLE;

  wcs.npv = cPVn + 1;
  for (Int ipv = 0; ipv <= cPVn; ipv++) {
    wcs.pv[ipv].i = 2;
    wcs.pv[ipv].m = ipv;
    wcs.pv[ipv].value = cPV(ipv);
  }

  cMapCelCrd.resize(2, cNAXIS1, cNAXIS2);

  int    stat;
  double imgcrd[2], phi, pixcrd[2], theta, world[2];
  for (uInt i = 0; i < cNAXIS1; i++) {
    for (uInt j = 0; j < cNAXIS2; j++) {
      pixcrd[0] = i + 1;
      pixcrd[1] = j + 1;

      if (wcsp2s(&wcs, 1, 2, pixcrd, imgcrd, &phi, &theta, world, &stat)) {
        // Flag it by setting the longitude to a NaN and set the latitude to a
        // large number for sorting in findNumStack().
        cMapCelCrd(0,i,j) = floatNaN();
        cMapCelCrd(1,i,j) = 1e99f;
      } else {
        cMapCelCrd(0,i,j) = world[0] * D2R;
        cMapCelCrd(1,i,j) = world[1] * D2R;
      }
    }
  }

  // Reset LONPOLE and LATPOLE.
  cLONPOLE = wcs.cel.ref[2];
  cLATPOLE = wcs.cel.ref[3];
}

//---------------------------------------------------- MBGridder::findNumStack

// Find the pixel in the map plane with the maximum number of spectra and
// resize stack arrays appropriately.
//
// In a brute-force implementation the total number of distance tests required
// between each pixel and each spectrum would be NAXIS1 * NAXIS2 * noSpec,
// which can be extremely large.  This routine uses latitude-sorting to reduce
// the number as much as possible.  Longitude tests are not used because of
// the difficulties caused by its cyclic nature.
//
// The original version of this routine used the Euclidean distance in the
// plane of projection, (x,y).  This is a fair approximation for pixels close
// to the reference point of the projection, provided also that the projection
// is conformal at the reference point.  However, it is not valid in the
// general case.  This version performs the distance test on the sphere via
// the Euclidean distance in Cartesian (x,y,z) coordinates.

void MBGridder::findNumStack(
  const String countsType)

{
  // Index the spectra coordinates in order of increasing latitude.
  cSpcIdx.resize(cNoSpec);
  GenSortIndirect<Float>::sort(cSpcIdx, cSpcLat);

  Vector<Float> spcLng(cNoSpec);
  Vector<Float> spcLat(cNoSpec);
  for (uInt iSpec = 0; iSpec < cNoSpec; iSpec++) {
    uInt iSpcIdx = cSpcIdx(iSpec);

    spcLng(iSpec) = cSpcLng(iSpcIdx);
    spcLat(iSpec) = cSpcLat(iSpcIdx);
  }

  Vector<Float> spcX = cos(spcLat) * sin(spcLng);
  Vector<Float> spcY = cos(spcLat) * cos(spcLng);
  Vector<Float> spcZ = sin(spcLat);

  // Range of latitudes in the spectra.
  Float minSpcLat = spcLat(0) - cCutoffRadius;
  Float maxSpcLat = spcLat(cNoSpec-1) + cCutoffRadius;

  // Get pointers to Vector storage.
  Bool delSpcLat = False;
  Bool delSpcX   = False;
  Bool delSpcY   = False;
  Bool delSpcZ   = False;

  const Float *spcLatStor = spcLat.getStorage(delSpcLat);
  const Float *spcXStor   = spcX.getStorage(delSpcX);
  const Float *spcYStor   = spcY.getStorage(delSpcY);
  const Float *spcZStor   = spcZ.getStorage(delSpcZ);

  // Range of 0-relative pixel coordinates each spectrum contributes to.
  cSpcPixSpan.resize(4,cNoSpec);
  cSpcPixSpan.row(0) = USHRT_MAX;
  cSpcPixSpan.row(1) = 0;
  cSpcPixSpan.row(2) = USHRT_MAX;
  cSpcPixSpan.row(3) = 0;


  // Total number of spectra at each pixel, and the nighttime subset.
  Matrix<Int> specCount(cNAXIS1, cNAXIS2, 0);
  Matrix<Int> nightSpec(cNAXIS1, cNAXIS2, 0);
  Matrix<Float> beamSSQ(cNAXIS1, cNAXIS2, 0.0f);

  Int nPol = (cPolMode == "A" || cPolMode == "B") ? 1 : 2;
  Int maxSpecCount = 0;
  for (uInt j = 0; j < cNAXIS2; j++) {
    // Index this map row in order of increasing latitude.
    Vector<uInt> rowLatIdx(cNAXIS1);
    GenSortIndirect<Float>::sort(rowLatIdx, cMapCelCrd.xyPlane(j).row(1));

    // Range of latitudes in this row.
    Float minRowLat = cMapCelCrd(1,rowLatIdx(0),j);
    Float maxRowLat = cMapCelCrd(1,rowLatIdx(cNAXIS1-1),j);
    if (maxRowLat < minSpcLat) continue;
    if (minRowLat > maxSpcLat) continue;

    uInt iSpcMin = 0;
    for (uInt i = 0; i < cNAXIS1; i++) {
      uInt iRowIdx = rowLatIdx(i);
      Float mapLng = cMapCelCrd(0,iRowIdx,j);
      if (isNaN(mapLng)) {
        continue;
      }

      Float mapLat = cMapCelCrd(1,iRowIdx,j);
      if (mapLat < minSpcLat) continue;
      if (mapLat > maxSpcLat) break;

      Float mapX = cos(mapLat) * sin(mapLng);
      Float mapY = cos(mapLat) * cos(mapLng);
      Float mapZ = sin(mapLat);
      Float minMapLat = mapLat - cCutoffRadius;
      Float maxMapLat = mapLat + cCutoffRadius;

      const Float *spcLatP = spcLatStor + iSpcMin;
      const Float *spcXP   = spcXStor   + iSpcMin;
      const Float *spcYP   = spcYStor   + iSpcMin;
      const Float *spcZP   = spcZStor   + iSpcMin;

      for (uInt iSpec = iSpcMin; iSpec < cNoSpec; iSpec++) {
        Float spcLat = *(spcLatP++);
        if (spcLat < minMapLat) {
          iSpcMin = iSpec;

          spcXP++;
          spcYP++;
          spcZP++;

          continue;

        } else if (spcLat > maxMapLat) {
          break;
        }

        Float dX = *(spcXP++) - mapX;
        Float dY = *(spcYP++) - mapY;
        Float dZ = *(spcZP++) - mapZ;
        Float xyzDistSqr = dX*dX + dY*dY + dZ*dZ;

        if (xyzDistSqr <= cXYZCutoffSqr) {
          // This spectrum is close enough to the pixel.
          uInt iSpcIdx = cSpcIdx(iSpec);

          if (iRowIdx < cSpcPixSpan(0,iSpcIdx)) {
            cSpcPixSpan(0,iSpcIdx) = iRowIdx;
          }

          if (iRowIdx > cSpcPixSpan(1,iSpcIdx)) {
            cSpcPixSpan(1,iSpcIdx) = iRowIdx;
          }

          if (j < cSpcPixSpan(2,iSpcIdx)) {
            cSpcPixSpan(2,iSpcIdx) = j;
          }

          if (j > cSpcPixSpan(3,iSpcIdx)) {
            cSpcPixSpan(3,iSpcIdx) = j;
          }

          // Spectra counts, total and nighttime.
          specCount(iRowIdx,j) += nPol;

          if (cNightFlag(iSpcIdx)) {
            nightSpec(iRowIdx,j)++;
          }

          // Beam weighting.
          Float arcDist  = 2.0f*asin(sqrt(xyzDistSqr)/2.0f);
          Float arcDist2 = arcDist * arcDist;
          Float beamFct  = exp(cBW*arcDist2);
          beamSSQ(iRowIdx,j) += nPol*beamFct*beamFct;
        }
      }

      if (maxSpecCount < specCount(iRowIdx,j)) {
        maxSpecCount = specCount(iRowIdx,j);
      }
    }
  }

  spcLat.freeStorage(spcLatStor, delSpcLat);
  spcX.freeStorage(spcXStor, delSpcX);
  spcY.freeStorage(spcYStor, delSpcY);
  spcZ.freeStorage(spcZStor, delSpcZ);

  if (maxSpecCount == 0) {
    logMessage("No spectra were found within the specified region.");
    throw(AipsError("No valid data for the specified region."));
  }


  // Index the spectra in order of increasing row number.
  GenSortIndirect<uShort>::sort(cSpcIdx, cSpcPixSpan.row(2));

  // cSpcRowSpan records the range of spectra that contribute to each row.
  cSpcRowSpan.resize(2,cNAXIS2);
  cSpcRowSpan.row(0) = USHRT_MAX;
  cSpcRowSpan.row(1) = 0;

  Int nSpec = 0;
  for (uInt iSpec = 0; iSpec < cNoSpec; iSpec++) {
    uInt iSpcIdx = cSpcIdx(iSpec);
    for (uInt j = cSpcPixSpan(2,iSpcIdx); j <= cSpcPixSpan(3,iSpcIdx); j++) {
      if (iSpec < cSpcRowSpan(0,j)) cSpcRowSpan(0,j) = iSpec;
      if (iSpec > cSpcRowSpan(1,j)) cSpcRowSpan(1,j) = iSpec;
    }

    // Count the number of spectra that contribute to the map.
    if (cSpcPixSpan(0,iSpec) <= cSpcPixSpan(1,iSpec)) nSpec++;
  }

  ostringstream buffer;
  buffer << "A total of " << nPol << " * " << nSpec
         << " spectra were found within the map boundary.";
  logMessage(buffer);

  buffer.str("");
  buffer << "Maximum number of spectra for any one pixel: "
         << nPol << " * " << maxSpecCount/nPol;
  logMessage(buffer);

  Int nStack = maxSpecCount;
  if (cPolMode == "A+B" || cPolMode == "A-B") {
     // Polarization pairs already averaged in the input data.
     nStack /= 2;
  }

  // Write spectra (or scan) counts cube and beam sensitivity map.
  formCounts(specCount, nightSpec, countsType, beamSSQ);

  cDataStack.resize(cNAXIS1, nStack);
  cWgt.resize(cNAXIS1, nStack);
}

//------------------------------------------------------ MBGridder::formCounts

// Write a 3-plane cube with the total number of spectra or scans per pixel in
// the first plane, the number of these occurring at nighttime in the second
// plane, and the number during daytime in the third plane.

Bool MBGridder::formCounts(
  const Matrix<Int> &specCount,
  const Matrix<Int> &nightSpec,
  const String &countsType,
  const Matrix<Float> &beamRSS)

{
  char errmsg[80];
  int status = 0;

  logMessage("");
  logMessage("Forming " + countsType + " counts...");

  fitsfile *countFile;
  String countName = cFITSfilename + "." + countsType + "counts.fits";
  remove(countName.chars());
  if (fits_create_file(&countFile, countName.chars(), &status)) {
    logError("MBGridder::formCounts: Could not open file for writing: " +
             countName);
    while (fits_read_errmsg(errmsg)) logError(errmsg);
    return False;
  }

  long naxes[] = {cNAXIS1, cNAXIS2, 3};
  if (fits_create_img(countFile, SHORT_IMG, 3, naxes, &status)) {
    logError("MBGridder::formCounts: Error constructing FITS primary array.");
    while (fits_read_errmsg(errmsg)) logError(errmsg);
    return False;
  }

  // Spectra or scan counts?
  Int FITStype = 2;
  Bool doScan = (countsType == "scan");
  if (doScan) FITStype++;
  FITSheader(countFile, FITStype, True);

  // Build and write the cube plane by plane to minimise memory usage.
  logMessage("Writing " + countName);
  short row[cNAXIS1];
  long  fpixel = 1;
  for (Int iChan = 0; iChan < 3; iChan++) {
    for (uInt j = 0; j < cNAXIS2; j++)  {
      for (uInt i = 0; i < cNAXIS1; i++) {
        if (iChan == 0) {
          row[i] = specCount(i,j);
        } else if (iChan == 1) {
          row[i] = nightSpec(i,j);
        } else {
          row[i] = specCount(i,j) - nightSpec(i,j);
        }

        if (doScan) row[i] /= 2;
      }

      if (fits_write_img(countFile, TSHORT, fpixel, cNAXIS1, row, &status)) {
        while (fits_read_errmsg(errmsg)) logError(errmsg);
        return False;
      }

      fpixel += cNAXIS1;
    }
  }

  fits_close_file(countFile, &status);


  // Write out the beam sensitivity map.
  logMessage("Forming beam sensitivity map...");

  fitsfile *beamFile;
  String beamName = cFITSfilename + ".beamRSS.fits";
  remove(beamName.chars());
  if (fits_create_file(&beamFile, beamName.chars(), &status)) {
    logError("MBGridder::formCounts: Could not open file for writing: " +
             beamName);
    while (fits_read_errmsg(errmsg)) logError(errmsg);
    return False;
  }

  if (fits_create_img(beamFile, FLOAT_IMG, 2, naxes, &status)) {
    logError("MBGridder::formCounts: Error constructing FITS primary array.");
    while (fits_read_errmsg(errmsg)) logError(errmsg);
    return False;
  }

  FITSheader(beamFile, -3, False);
  logMessage("Writing " + beamName);
  float frow[cNAXIS1];
  fpixel = 1;
  for (uInt j = 0; j < cNAXIS2; j++)  {
    for (uInt i = 0; i < cNAXIS1; i++) {
      frow[i] = sqrt(beamRSS(i,j));
    }

    if (fits_write_img(beamFile, TFLOAT, fpixel, cNAXIS1, frow, &status)) {
      while (fits_read_errmsg(errmsg)) logError(errmsg);
      return False;
    }

    fpixel += cNAXIS1;
  }

  fits_close_file(beamFile, &status);
  logMessage("");

  return True;
}

//------------------------------------------------------ MBGridder::~MBGridder

MBGridder::~MBGridder()
{
}

//------------------------------------------------------- MBGridder::setInterp

// Set or reset interpolation parameters.

void MBGridder::setInterp(
  const String statistic,
  const Float  clipFraction,
  const Bool   tsysWeight,
  const Int    beamWeight,
  const Bool   beamNormal,
  const String kernelType,
  const Float  kernelFWHM,
  const Float  blankLevel)

{
  cStatistic    = statistic;
  cClipFraction = clipFraction;
  cTsysWeight   = tsysWeight;
  cBeamWeight   = beamWeight;
  cBeamNormal   = beamNormal;
  cKernelType   = kernelType;
  cKernelFWHM   = kernelFWHM;
  cBlankLevel   = blankLevel;

  // Translate statistic to integer code for efficiency.
  cStatistic.upcase();
  if (cStatistic == "WGTMED") {
    cStatisticId = WGTMED;
  } else if (cStatistic == "MEDIAN") {
    cStatisticId = MEDIAN;
  } else if (cStatistic == "MEAN") {
    cStatisticId = MEAN;
  } else if (cStatistic == "SUM") {
    cStatisticId = SUM;
  } else if (cStatistic == "RSS") {
    cStatisticId = RSS;
  } else if (cStatistic == "RMS") {
    cStatisticId = RMS;
  } else if (cStatistic == "QUARTILE") {
    cStatisticId = QUARTILE;

  } else {
    if (cStatistic == "NSPECTRA") {
      cStatisticId = NSPECTRA;
    } else if (cStatistic == "WEIGHT") {
      cStatisticId = WEIGHT;
    } else if (cStatistic == "BEAMSUM") {
      cStatisticId = BEAMSUM;
    } else if (cStatistic == "BEAMRSS") {
      cStatisticId = BEAMRSS;
    }

    cBlankLevel = 0.0f;
  }

  // Translate kernel type to integer code for efficiency.
  cKernelType.upcase();
  if (cKernelType == "TOP-HAT") {
    cKernelId = TOPHAT;
  } else if (cKernelType == "GAUSSIAN") {
    cKernelId = GAUSSIAN;
  } else {
    cKernelId = TOPHAT;
  }

  // Kernel size parameters.
  Float fwhm = (cKernelFWHM / 60.0f) * D2R;
  cTW = fwhm * fwhm / 4.0f;
  cGW = log(0.5f) / cTW;
}

//------------------------------------------------------ MBGridder::setSpectra

// Set FITS spectral axis keywords and add simulation sources; specData may be
// modified on return with simulation sources added.

Bool MBGridder::setSpectra(
  const Int chanOffset,
  const Int    NAXIS3,
  const Double CRPIX3,
  const Double CDELT3,
  const Double CRVAL3,
  const String CTYPE3,
  const Double restFreq,
  const String specSys,
  Cube<Float> &specData,
  const SourceParm &sources)

{
  cChanOffset = chanOffset;

  // FITS spectral axis keywords.
  cNAXIS3 = NAXIS3;
  cCRPIX3 = Float(CRPIX3);
  cCDELT3 = CDELT3;
  cCRVAL3 = CRVAL3;
  cCTYPE3 = CTYPE3;

  // Line rest frequency, Hz.
  cRestFreq = restFreq;
  cSpecSys  = specSys;

  // Create a reference to the spectral data for later use.
  cData.reference(specData);
  uInt nPol = cData.nrow();

  // Simulation sources.
  cSources = sources;
  if (cSources.nSrc) {
    // Add fake sources.
    for (uInt iSpec = 0; iSpec < cNoSpec; iSpec++) {
      Float lng = cSpcLng(iSpec);
      Float lat = cSpcLat(iSpec);

      for (uInt iChan = 0; iChan < cNAXIS3; iChan++)   {

        Int realchan = cChanOffset + 1 + iChan;

        for (uInt isrc = 0; isrc < cSources.nSrc; isrc++) {
          if (cSources.startChan(isrc) <= realchan &&
              cSources.endChan(isrc)   >= realchan) {

            Float srcLng = (cCRVAL1 + cSources.dLng(isrc) / 60.0f /
                                           cos(cCRVAL2*D2R)) * D2R;
            Float srcLat = (cCRVAL2 + cSources.dLat(isrc) / 60.0f) * D2R;
            Float arcDist = acos(sin(lat)*sin(srcLat) +
                              cos(lng - srcLng)*cos(lat)*cos(srcLat));

            // Convert to arcmin.
            arcDist *= 60.0f*R2D;

            Float simFlux = cSources.flux(isrc) * exp(log(0.5f) * 4.0f *
                              arcDist * arcDist / (cBeamFWHM*cBeamFWHM +
                              cSources.width(isrc)*cSources.width(isrc)));

            if (!isNaN(cData(0,iSpec,iChan))) {
              cData(0,iSpec,iChan) += simFlux;
            }

            if (nPol == 2 && !isNaN(cData(1,iSpec,iChan))) {
              // Aggregate polarizations, A&B.
              cData(1,iSpec,iChan) += simFlux;
            }
          }
        }
      }
    }
  }

  return True;
}

//-------------------------------------------------------- MBGridder::formCont

// Form the continuum map from continuum data.

Bool MBGridder::formCont(
  const Cube<Float> &contData,
  const Matrix<Float> &tsysData)
{
  char errmsg[80];
  int  status = 0;

  logMessage("Gridding continuum data...");

  if (cStatisticId == UNDEFINED) {
    logError("MBGridder::formCont: interpolation parameters not defined.");
    return False;
  }

  // Continuum map.
  fitsfile *contFile;
  String contName = cFITSfilename + "_" + cStatistic + ".continuum.fits";
  remove(contName.chars());
  if (fits_create_file(&contFile, contName.chars(), &status)) {
    logError("MBGridder::formCont: Could not open file for writing: " +
             contName);
    while (fits_read_errmsg(errmsg)) logError(errmsg);
    return False;
  }

  long naxes[] = {cNAXIS1, cNAXIS2};
  if (fits_create_img(contFile, FLOAT_IMG, 2, naxes, &status)) {
    logError("MBGridder::formCont: Error constructing FITS primary array.");
    while (fits_read_errmsg(errmsg)) logError(errmsg);
    return False;
  }

  FITSheader(contFile, -1, False);

  // Form the continuum map.
  float image[cNAXIS2][cNAXIS1];
  for (uInt j = 0; j < cNAXIS2; j++) {
    formRow(contData.xyPlane(0), tsysData, j, image[j]);
  }

  Matrix<Float> contPlane(IPosition(2,cNAXIS1,cNAXIS2), (Float *)image,
                  SHARE);

  // Mask of non-blank values.
  Matrix<Bool> notBlank(cNAXIS1, cNAXIS2);
  for (uInt j = 0; j < cNAXIS2; j++) {
    for (uInt i = 0; i < cNAXIS1; i++) {
      notBlank(i,j) = (contPlane(i,j) != cBlankVal);
    }
  }

  // Determine the RMS noise level.
  Float meanVal, rmsVal;

  Matrix<Bool> clipMask(cNAXIS1, cNAXIS2);
  clipMask = notBlank;
  Int count = ntrue(clipMask);
  for (Int iter = 1; iter <= 3; iter++) {
    // Discard points outside 3x RMS.
    if (count > 1) {
      meanVal = mean(contPlane(clipMask));
      rmsVal  = stddev(contPlane(clipMask));

      clipMask = notBlank && (abs(contPlane - meanVal) < iter*rmsVal);
      count = ntrue(clipMask);

    } else {
      logError("MBGridder::formCont: Continuum plane contains no baselevel "
               "data.");
      rmsVal = 0.0f;
      break;
    }
  }

  if (count > 1) {
    meanVal = mean(contPlane(clipMask));
    rmsVal = stddev(contPlane(clipMask));
  }

  char *hisCard = new char[73];
  if (rmsVal == 0.0f) {
    sprintf(hisCard, "Noise level of continuum map: (indeterminate)");
  } else {
    sprintf(hisCard, "Noise level of continuum map: %d mJy (RMS)",
      Int(1000.0f*rmsVal + 0.5f));
  }
  fits_write_history(contFile, hisCard, &status);
  logMessage(hisCard);

  // Write it out.
  logMessage("Writing " + contName);
  if (fits_write_imgnull(contFile, TFLOAT, 1, cNAXIS1*cNAXIS2, image,
        &cBlankVal, &status)) {
    while (fits_read_errmsg(errmsg)) logError(errmsg);
    return False;
  }
  fits_close_file(contFile, &status);


  // Spectral index map.
  fitsfile *spidxFile;
  String spidxName = cFITSfilename + "_" + cStatistic + ".spect_idx.fits";
  remove(spidxName.chars());
  if (fits_create_file(&spidxFile, spidxName.chars(), &status)) {
    logError("MBGridder::formCont: Could not open file for writing: " +
             spidxName);
    while (fits_read_errmsg(errmsg)) logError(errmsg);
    return False;
  }

  if (fits_create_img(spidxFile, FLOAT_IMG, 2, naxes, &status)) {
    logError("MBGridder::formCont: Error constructing FITS primary array.");
    while (fits_read_errmsg(errmsg)) logError(errmsg);
    return False;
  }

  FITSheader(spidxFile, -2, False);

  // Clipping level.
  if (rmsVal == 0.0f) {
    sprintf(hisCard, "Clipping level for spectral index map: 0.0 "
      "(negatives clipped)");
  } else {
    sprintf(hisCard, "Clipping level for spectral index map: 3 x %d mJy "
      "(RMS)", Int(1000.0f*rmsVal + 0.5f));
  }
  fits_write_history(spidxFile, hisCard, &status);
  logMessage(hisCard);

  // Form the spectral index map and write it out row by row.
  logMessage("Writing " + spidxName);
  for (uInt j = 0; j < cNAXIS2; j++) {
    formRow(contData.xyPlane(1), tsysData, j, image[j]);

    for (uInt i = 0; i < cNAXIS1; i++) {
      // Apply clipping.
      if (!notBlank(i,j) || contPlane(i,j) < meanVal + 3.0f*rmsVal) {
        // Blank it.
        image[j][i] = cBlankVal;
      }
    }
  }

  if (fits_write_imgnull(spidxFile, TFLOAT, 1, cNAXIS1*cNAXIS2, image,
         &cBlankVal, &status)) {
    while (fits_read_errmsg(errmsg)) logError(errmsg);
    return False;
  }
  fits_close_file(spidxFile, &status);

  delete [] hisCard;

  return True;
}

//-------------------------------------------------------- MBGridder::formBase

// Construct baseline polynomial coefficients data cube.

Bool MBGridder::formBase(
  const Cube<Float> &baseData,
  const Matrix<Float> &tsysData)

{
  char errmsg[80];
  int  status = 0;

  logMessage("Gridding baseline polynomial coefficients...");

  if (cStatisticId == UNDEFINED) {
    logError("MBGridder::formBase: interpolation parameters not defined.");
    return False;
  }

  fitsfile *baseFile;
  String baseName = cFITSfilename + "_" + cStatistic + ".base_coeff.fits";
  remove(baseName.chars());
  if (fits_create_file(&baseFile, baseName.chars(), &status)) {
    logError("MBGridder::formBase: Could not open file for writing: " +
             baseName);
    while (fits_read_errmsg(errmsg)) logError(errmsg);
    return False;
  }

  long naxes[] = {cNAXIS1, cNAXIS2, 9};
  if (fits_create_img(baseFile, FLOAT_IMG, 3, naxes, &status)) {
    logError("MBGridder::formBase: Error constructing FITS primary array.");
    while (fits_read_errmsg(errmsg)) logError(errmsg);
    return False;
  }

  FITSheader(baseFile, 4, False);

  // Form the continuum map.
  float image[cNAXIS2][cNAXIS1];
  for (uInt j = 0; j < cNAXIS2; j++) {
    formRow(baseData.xyPlane(0), tsysData, j, image[j]);
  }

  Matrix<Float> basePlane(IPosition(2,cNAXIS1,cNAXIS2), (Float *)image,
                  SHARE);

  // Mask of non-blank values.
  Matrix<Bool> notBlank(cNAXIS1, cNAXIS2);
  for (uInt j = 0; j < cNAXIS2; j++) {
    for (uInt i = 0; i < cNAXIS1; i++) {
      notBlank(i,j) = (basePlane(i,j) != cBlankVal);
    }
  }

  // Determine the RMS noise level.
  Float meanVal, rmsVal;

  Matrix<Bool> clipMask(cNAXIS1, cNAXIS2);
  clipMask = notBlank;
  Int count = ntrue(clipMask);
  for (Int iter = 1; iter <= 3; iter++) {
    // Discard points outside 3x RMS.
    if (count > 1) {
      meanVal = mean(basePlane(clipMask));
      rmsVal  = stddev(basePlane(clipMask));

      clipMask = notBlank && (abs(basePlane - meanVal) < iter*rmsVal);
      count = ntrue(clipMask);

    } else {
      logError("MBGridder::formBase: Continuum plane contains no baselevel "
               "data.");
      rmsVal = 0.0f;
      break;
    }
  }

  if (count > 1) {
    meanVal = mean(basePlane(clipMask));
    rmsVal  = stddev(basePlane(clipMask));
  }

  char *hisCard = new char[73];
  if (rmsVal == 0.0f) {
    sprintf(hisCard, "Noise level of continuum map: (indeterminate)");
  } else {
    sprintf(hisCard, "Noise level of continuum map: %d mJy (RMS)",
      Int(1000.0f*rmsVal + 0.5f));
  }
  fits_write_history(baseFile, hisCard, &status);
  logMessage(hisCard);

  if (rmsVal == 0.0f) {
    sprintf(hisCard, "Clipping level for coefficient maps: 0.0 "
      "(negatives clipped)");
  } else {
    sprintf(hisCard, "Clipping level for coefficient maps: 3 x %d mJy (RMS)",
      Int(1000.0f*rmsVal + 0.5f));
  }
  fits_write_history(baseFile, hisCard, &status);
  logMessage(hisCard);

  // Write it out.
  logMessage("Writing " + baseName);
  if (fits_write_imgnull(baseFile, TFLOAT, 1, cNAXIS1*cNAXIS2, image,
        &cBlankVal, &status)) {
    while (fits_read_errmsg(errmsg)) logError(errmsg);
    return False;
  }


  // One row in one plane of the cube.
  Vector<Float> baseRow(cNAXIS1);

  // Build and write the cube plane by plane.
  int fpixel = 1;
  for (uInt iCoeff = 1; iCoeff < 9; iCoeff++) {
    // Form the map for this coefficient and write it out row by row.
    for (uInt j = 0; j < cNAXIS2; j++) {
      formRow(baseData.xyPlane(iCoeff), tsysData, j, image[j]);

      for (uInt i = 0; i < cNAXIS1; i++) {
        // Apply clipping.
        if (!(notBlank(i,j) && basePlane(i,j) > meanVal + 3.0f*rmsVal)) {
          // Blank it.
          image[j][i] = cBlankVal;
        }
      }

    }

    if (fits_write_imgnull(baseFile, TFLOAT, fpixel, cNAXIS1*cNAXIS2, image,
          &cBlankVal, &status)) {
      while (fits_read_errmsg(errmsg)) logError(errmsg);
      return False;
    }

    fpixel += cNAXIS1*cNAXIS2;
  }

  fits_close_file(baseFile, &status);

  return True;
}

//-------------------------------------------------------- MBGridder::formCube

// Form the spectral data cube.

Bool MBGridder::formCube(
  const Matrix<Float> &tsysData,
  const Bool   doShort,
  const String passCode)
{
  char errmsg[80];
  int  status = 0;

  logMessage("Gridding spectral data...");

  if (cStatisticId == UNDEFINED) {
    logError("MBGridder::formCube: interpolation parameters not defined.");
    return False;
  }

  fitsfile *cubeFile;
  String cubeName = cFITSfilename + "_" + cStatistic + passCode + ".fits";
  remove(cubeName.chars());
  if (fits_create_file(&cubeFile, cubeName.chars(), &status)) {
    logError("MBGridder::formCube: Could not open file for writing: " +
             cubeName);
    while (fits_read_errmsg(errmsg)) logError(errmsg);
    return False;
  }

  int  bitpix = doShort ? SHORT_IMG : FLOAT_IMG;
  long naxes[] = {cNAXIS1, cNAXIS2, cNAXIS3};
  if (fits_create_img(cubeFile, bitpix, 3, naxes, &status)) {
    logError("MBGridder::formCube: Error constructing FITS primary array.");
    while (fits_read_errmsg(errmsg)) logError(errmsg);
    return False;
  }

  Int FITStype = 1;
  if (cStatisticId == NSPECTRA ||
      cStatisticId == WEIGHT   ||
      cStatisticId == BEAMSUM  ||
      cStatisticId == BEAMRSS) {
    FITStype = 0;
  }

  FITSheader(cubeFile, FITStype, doShort);

  // Build and write the cube plane by plane.
  logMessage("Writing " + cubeName);
  Time msgtime;

  float row[cNAXIS1];
  long  fpixel = 1;
  for (uInt iChan = 0; iChan < cNAXIS3; iChan++) {
    if (msgtime.age() > 10.0) {
      ostringstream buffer;
      buffer << " channel " << cChanOffset + 1 + iChan<< "...";
      logMessage(buffer);
      msgtime.now();
    }

    // Form and write out the map for this channel row by row.
    for (uInt j = 0; j < cNAXIS2; j++) {
      formRow(cData.xyPlane(iChan), tsysData, j, row);

      if (doShort) {
        for (float *rowp = row; rowp < row+cNAXIS1; rowp++) {
          if (*rowp != cBlankVal) {
            if (*rowp < SM_VALMIN) {
              *rowp = SM_VALMIN;
            } else if (*rowp > SM_VALMAX) {
              *rowp = SM_VALMAX;
            }
          }
        }
      }

      if (fits_write_imgnull(cubeFile, TFLOAT, fpixel, cNAXIS1, row,
            &cBlankVal, &status)) {
        while (fits_read_errmsg(errmsg)) logError(errmsg);
        return False;
      }

      fpixel += cNAXIS1;
    }
  }

  fits_close_file(cubeFile, &status);
  logMessage(" ... and finish OK.");

  return True;
}

//------------------------------------------------------ MBGridder::FITSheader

// Constructs and returns FITS primary array header for various types of
// output data.

namespace casa {
  extern const int aips_major_version, aips_minor_version, aips_patch_version;
  extern const char* aips_version_date;
}

Bool MBGridder::FITSheader(
  fitsfile *outFile,
  const Int  FITStype,
  const Bool doShort)
{
  int status = 0;

  if (doShort) {
    fits_modify_comment(outFile, "BITPIX",
      "16-bit two's complement (short integer) data", &status);
  } else {
    fits_modify_comment(outFile, "BITPIX",
      "IEEE (big-endian) 32-bit floating point data", &status);
  }

  if (doShort) {
    if (FITStype == 2 || FITStype == 3) {
      fits_update_key_fixdbl(outFile, "BSCALE", 1.0, 1,
        "Count is unscaled integer data value", &status);
      fits_update_key_fixdbl(outFile, "BZERO",  0.0, 1, 0, &status);

    } else {
      /* Short integer data range from -32767 to +32767. */
      double bscale = (SM_VALMAX - SM_VALMIN) / 65534.0;
      double bzero  = (SM_VALMIN + SM_VALMAX) / 2.0;

      fits_update_key(outFile, TDOUBLE, "BSCALE", &bscale,
        "Flux density = integer * BSCALE + BZERO", &status);
      fits_update_key(outFile, TDOUBLE, "BZERO", &bzero, 0, &status);
    }

    int blank = -32768;
    fits_update_key(outFile, TINT, "BLANK", &blank,
      "Integer representation of blank value", &status);
  }

  if (FITStype == -3) {
    fits_update_key_str(outFile, "BUNIT", "Beam sensitivity",
      "Pixel value is sqrt sum of beam response", &status);
  } else if (FITStype == -2) {
    fits_update_key_str(outFile, "BUNIT", "Spectral index",
      "Pixel value is spectral index", &status);
  } else if (abs(FITStype) == 1) {
    fits_update_key_str(outFile, "BUNIT", "Jy/beam",
      "Pixel value is flux density", &status);
  } else if (FITStype == 2) {
    fits_update_key_str(outFile, "BUNIT", "Spectra",
      "Pixel value is the number of spectra", &status);
  } else if (FITStype == 3) {
    fits_update_key_str(outFile, "BUNIT", "Scans",
      "Pixel value is the number of scans", &status);
  } else if (FITStype == 4) {
    fits_update_key_str(outFile, "BUNIT", "Jy/beam/MHz**n",
      "Pixel value is polynomial baseline coefficient", &status);
  }

  char chars[16];
  strcpy(chars, cCTYPE1.chars());
  fits_update_key(outFile, TSTRING, "CTYPE1", &chars,   0, &status);
  fits_update_key(outFile, TDOUBLE, "CRPIX1", &cCRPIX1, 0, &status);
  fits_update_key(outFile, TDOUBLE, "CDELT1", &cCDELT1, 0, &status);
  fits_update_key(outFile, TDOUBLE, "CRVAL1", &cCRVAL1, 0, &status);

  strcpy(chars, cCTYPE2.chars());
  fits_update_key(outFile, TSTRING, "CTYPE2", &chars,   0, &status);
  fits_update_key(outFile, TDOUBLE, "CRPIX2", &cCRPIX2, 0, &status);
  fits_update_key(outFile, TDOUBLE, "CDELT2", &cCDELT2, 0, &status);
  fits_update_key(outFile, TDOUBLE, "CRVAL2", &cCRVAL2, 0, &status);

  fits_update_key(outFile, TDOUBLE, "LONPOLE", &cLONPOLE,
    "Native longitude of celestial pole", &status);
  fits_update_key(outFile, TDOUBLE, "LATPOLE", &cLATPOLE,
    "Native latitude  of celestial pole", &status);

  for (Int ipv = (cPVn == 19)?0:1; ipv <= cPVn; ipv++) {
    char pvi_m[8], comment[32];
    sprintf(pvi_m, "PV2_%d", ipv);
    sprintf(comment, "Projection parameter %d", ipv);
    fits_update_key(outFile, TDOUBLE, pvi_m, &cPV(ipv), comment, &status);
  }

  if (cCTYPE1(0,4) == "RA--") {
    fits_update_key_str(outFile, "RADESYS", "FK5",
      "Equatorial coordinate system", &status);
    fits_update_key_fixdbl(outFile, "EQUINOX", 2000.0, 1,
      "Equinox of equatorial coordinates", &status);
  }

  // Third axis is of varying type.
  if (FITStype == 0 || FITStype == 1) {
    strcpy(chars, cCTYPE3.chars());
    fits_update_key(outFile, TSTRING,  "CTYPE3", &chars,   0, &status);
    fits_update_key(outFile, TDOUBLE,  "CRPIX3", &cCRPIX3, 0, &status);
    fits_update_key(outFile, TDOUBLE,  "CDELT3", &cCDELT3, 0, &status);
    fits_update_key(outFile, TDOUBLE,  "CRVAL3", &cCRVAL3, 0, &status);

    if (cSpecSys == " ") {
      // AIPS-convention.
      fits_update_key(outFile, TDOUBLE, "RESTFREQ", &cRestFreq,
        "[Hz] Line rest frequency", &status);

    } else {
      fits_update_key(outFile, TDOUBLE, "RESTFRQ", &cRestFreq,
        "[Hz] Line rest frequency", &status);

      strcpy(chars, cSpecSys.chars());
      fits_update_key(outFile, TSTRING, "SPECSYS", &chars,
        "Doppler reference frame (transformed)", &status);

      // Observations done from the surface of the Earth.
      strcpy(chars, "TOPOCENT");
      fits_update_key(outFile, TSTRING, "SSYSOBS", &chars,
        "Doppler reference frame of observation", &status);
    }

  } else if (FITStype == 2 || FITStype == 3) {
    fits_update_key_str(outFile, "CTYPE3", "Count type",
      "1: total count, 2: nighttime, 3: daytime", &status);
    fits_update_key_fixdbl(outFile, "CRPIX3", 0.0, 1, 0, &status);
    fits_update_key_fixdbl(outFile, "CDELT3", 1.0, 1, 0, &status);
    fits_update_key_fixdbl(outFile, "CRVAL3", 0.0, 1, 0, &status);

  } else if (FITStype == 4) {
    fits_update_key_str(outFile, "CTYPE3", "Coeff",
      "Polynomial baseline coefficient", &status);
    fits_update_key_fixdbl(outFile, "CRPIX3", 1.0, 1, 0, &status);
    fits_update_key_fixdbl(outFile, "CDELT3", 1.0, 1, 0, &status);
    fits_update_key_fixdbl(outFile, "CRVAL3", 0.0, 1, 0, &status);
  }

  fits_update_key_fixdbl(outFile, "BMAJ", cBeamFWHM/60.0, 5,
    "[deg] Beam major axis", &status);
  fits_update_key_fixdbl(outFile, "BMIN", cBeamFWHM/60.0, 5,
    "[deg] Beam minor axis", &status);
  fits_update_key_fixdbl(outFile, "BPA", 0.0, 1,
    "[deg] Beam position angle", &status);

  // History items.
  char *hisCard = new char[73];

  if (FITStype == -3) {
    fits_write_history(outFile, "Single-dish beam sensitivity map", &status);

  } else if (FITStype == -2) {
    fits_write_history(outFile, "Single-dish spectral index map", &status);

  } else if (FITStype == -1) {
    fits_write_history(outFile, "Single-dish continuum map", &status);

  } else if (FITStype == 0) {
    fits_write_history(outFile, "Single-dish weight cube", &status);

  } else if (FITStype == 1) {
    fits_write_history(outFile, "Single-dish data cube", &status);

  } else if (FITStype == 2 || FITStype == 3) {
    if (FITStype == 2) {
      fits_write_history(outFile, "Single-dish spectra count cube:", &status);
    } else if (FITStype == 3) {
      fits_write_history(outFile, "Single-dish scan count cube:", &status);
    }
    fits_write_history(outFile, "   1st plane is total count", &status);
    fits_write_history(outFile, "   2nd plane is nighttime count", &status);
    fits_write_history(outFile, "   3rd plane is daytime count", &status);

  } else if (FITStype == 4) {
    fits_write_history(outFile, "Single-dish baseline coefficient cube",
      &status);
    fits_write_history(outFile,
      "   Linear and higher degree coefficients are", &status);
    fits_write_history(outFile,
      "   normalized by the constant (zeroth-degree) term", &status);
  }

  // Date and time stamp.
  Time t;
  char dow[7][4] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
  sprintf(hisCard, "Formed on %s %4d/%2.2d/%2.2d %2.2d:%2.2d:%2.2d GMT by "
          "\"pksgridzilla\" which was",
          dow[t.dayOfWeek()-1], t.year(), t.month(), t.dayOfMonth(),
          t.hours(), t.minutes(), t.seconds());
  fits_write_history(outFile, hisCard, &status);

  sprintf(hisCard, "compiled on %s %s (local time) within", __DATE__,
          __TIME__);
  fits_write_history(outFile, hisCard, &status);

  // Version information.
  sprintf(hisCard, "AIPS++ version %2.2d.%3.3d.%2.2d dated %s.",
          aips_major_version, aips_minor_version, aips_patch_version,
          aips_version_date);
  fits_write_history(outFile, hisCard, &status);

  // Polarization mode.
  if (cPolMode == "A&B") {
    fits_write_history(outFile, "Polarization mode: A and B aggregated",
      &status);
  } else if (cPolMode == "A+B") {
    fits_write_history(outFile, "Polarization mode: (A+B)/2", &status);
  } else if (cPolMode == "A") {
    fits_write_history(outFile, "Polarization mode: A only", &status);
  } else if (cPolMode == "B") {
    fits_write_history(outFile, "Polarization mode: B only", &status);
  } else if (cPolMode == "A-B") {
    fits_write_history(outFile, "Polarization mode: (A-B)/2", &status);
  }

  // Gridding parameters.
  fits_write_history(outFile, "Gridding parameters:", &status);
  fits_write_history(outFile, ("   Method: " + cStatistic).chars(), &status);

  sprintf(hisCard, "   Clip fraction: %.3f", cClipFraction);
  fits_write_history(outFile, hisCard, &status);

  if (cTsysWeight) {
    fits_write_history(outFile, "   Tsys weighting: applied", &status);
  } else {
    fits_write_history(outFile, "   Tsys weighting: omitted", &status);
  }

  sprintf(hisCard, "   Beam weight order: %d", cBeamWeight);
  fits_write_history(outFile, hisCard, &status);

  sprintf(hisCard, "   Beam FWHM: %.3f arcmin", cBeamFWHM);
  fits_write_history(outFile, hisCard, &status);

  if (cBeamNormal) {
    fits_write_history(outFile, "   Beam normalization: applied", &status);
  } else {
    fits_write_history(outFile, "   Beam normalization: omitted", &status);
  }

  fits_write_history(outFile,
    ("   Smoothing kernel type: " + cKernelType).chars(), &status);

  sprintf(hisCard, "   Kernel FWHM: %.3f arcmin", cKernelFWHM);
  fits_write_history(outFile, hisCard, &status);

  sprintf(hisCard, "   Cutoff radius: %.3f arcmin", cCutoffRadius*R2D*60.0f);
  fits_write_history(outFile, hisCard, &status);

  sprintf(hisCard, "   Beam RSS cutoff: %.3f", cBlankLevel);
  fits_write_history(outFile, hisCard, &status);



  // Input data sets.
  fits_write_history(outFile, "Input data sets:", &status);

  for (uInt cnt = 0; cnt < cInFiles.nelements(); cnt++) {
    if (strlen(cInFiles(cnt).chars()) > 0) {
      const Char *inChars = cInFiles(cnt).chars();

      // Find where the file specification starts.
      const Char *inFile = inChars + strlen(inChars) - 1;
      while (inFile >= inChars && *inFile != '/') {
        inFile--;
      }
      inFile++;

      // Exclude the directory specification.
      sprintf(hisCard, "   %.69s", inFile);
      fits_write_history(outFile, hisCard, &status);
    }
  }

  // Record simulation sources if they exist.
  if (cSources.nSrc) {
    sprintf(hisCard, "DATA CONTAINS FAKE SOURCES");
    fits_write_history(outFile, hisCard, &status);

    sprintf(hisCard, "Sources:");
    fits_write_history(outFile, hisCard, &status);

    sprintf(hisCard, "   dLng(')  dLat(')  Flux(Jy)  FWHM(')  Channels");
    fits_write_history(outFile, hisCard, &status);

    for (uInt i = 0; i < cSources.nSrc; i++) {
      sprintf(hisCard, "   %+7.3f  %+7.3f  %7.4f    %4.1f   %4d-%d",
              cSources.dLng(i), cSources.dLat(i), cSources.flux(i),
              cSources.width(i), cSources.startChan(i), cSources.endChan(i));
      fits_write_history(outFile, hisCard, &status);
    }
  }

  // Original FITS filename.
  char fileChars[80];
  fits_file_name(outFile, fileChars, &status);

  // Find where the file specification starts.
  const Char *outName = fileChars + strlen(fileChars) - 1;
  while (outName >= fileChars && *outName != '/') {
    outName--;
  }
  outName++;

  Int outLen = strlen(outName);
  if (outLen < 48) {
    sprintf(hisCard, "Original FITS filename \"%s\".", outName);
    fits_write_history(outFile, hisCard, &status);
  } else {
    sprintf(hisCard, "Original FITS filename -");
    fits_write_history(outFile, hisCard, &status);

    if (outLen < 68) {
      sprintf(hisCard, "   \"%s\".", outName);
    } else {
      sprintf(hisCard, "%.72s", outName);
    }
    fits_write_history(outFile, hisCard, &status);
  }

  delete [] hisCard;

  return True;
}

//--------------------------------------------------------- MBGridder::formRow

// For each pixel in a row of the map plane find the required statistic of the
// stack elements.

void MBGridder::formRow(
  const Matrix<Float> &data,
  const Matrix<Float> &tsys,
  const uInt j,
  float *mapRow)
{
  // Averaging statistics.
  Bool averaging = (cStatisticId == WGTMED  ||
                    cStatisticId == MEDIAN  ||
                    cStatisticId == MEAN    ||
                    cStatisticId == SUM     ||
                    cStatisticId == RSS);

  Float tVal;

  // Build the stack for this row of the map plane.
  Vector<Int>   specCount(cNAXIS1);
  Vector<Float> beamSum(cNAXIS1), beamRSS(cNAXIS1);
  buildStack(data, tsys, j, specCount, beamSum, beamRSS);

  for (uInt i = 0; i < cNAXIS1; i++) {
    Int nStack = specCount(i);

    if (cStatisticId == NSPECTRA) {
      // Stack size.
      tVal = nStack;

    } else if (nStack == 0) {
      // No data for this pixel.
      tVal = cBlankVal;

    } else if (cStatisticId == WEIGHT) {
      // Sum of weights.
      Slice stackLen(0,nStack);
      tVal = sum(cWgt(i,stackLen));

    } else if (cStatisticId == BEAMSUM) {
      // Sum of beam weights.
      tVal = beamSum(i);

    } else if (cStatisticId == BEAMRSS) {
      // Root sum of squares of beam weights.
      tVal = beamRSS(i);

    } else if (beamRSS(i) < cBlankLevel) {
      // Not enough good data for this pixel.
      tVal = cBlankVal;

    } else if (nStack == 1) {
      if (averaging) {
        if (cWgt(i,0) == 0.0) {
          tVal = cBlankVal;
        } else {
          tVal = cDataStack(i,0);
        }

      } else {
        // Can't compute scatter from one datum.
        tVal = cBlankVal;
      }

    } else {
      Slice stackLen(0,nStack);
      Vector<Float> newStack = cDataStack(i,stackLen).nonDegenerate();
      Vector<Float> wgt = cWgt(i,stackLen).nonDegenerate();

      // Apply median-based clipping if requested.
      if (cClipFraction > 0.0 &&
          cStatisticId != WGTMED  &&
          cStatisticId != MEDIAN) {
        Float med = median(newStack, False, True);
        Vector<Float> resid = abs(newStack - med);

        Vector<uInt> sortindex(nStack);
        GenSortIndirect<Float>::sort(sortindex, resid);

        Int nGood = Int((1.0 - cClipFraction)*nStack + 0.5);
        Vector<Float> goodData(nGood), goodWgt(nGood);
        for (Int k = 0; k < nGood; k++) {
          goodData(k) = newStack(sortindex(k));
          goodWgt(k) = wgt(sortindex(k));
        }

        newStack.resize(nGood);
        wgt.resize(nGood);
        for (Int k = 0; k < nGood; k++) {
          newStack(k) = goodData(k);
          wgt(k) = goodWgt(k);
        }

        nStack = nGood;
      }

      // Compute the required statistic.
      if (sum(wgt) == 0.0) {
        tVal = cBlankVal;

      } else if (averaging) {
        if (cStatisticId == WGTMED) {
          // Weighted median.
          tVal = median(newStack, wgt);

        } else if (cStatisticId == MEDIAN) {
          // Median of weighted values.
          tVal = median(wgt*newStack, False, True) /
                 median(wgt, False, True);

        } else if (cStatisticId == MEAN) {
          // Weighted mean.
          tVal = sum(wgt*newStack) / sum(wgt);

        } else if (cStatisticId == SUM) {
          // Weighted sum.
          tVal = sum(wgt*newStack);

        } else if (cStatisticId == RSS) {
          // Weighted root sum of squares.
          tVal = sqrt(sum(square(wgt*newStack)));

        } else {
          // Shouldn't happen.
          tVal = cBlankVal;
        }

      } else {
        if (nStack < 2) {
          tVal = cBlankVal;
        } else {
          if (cStatisticId == RMS) {
            // Weighted rms deviation.
            newStack -= sum(wgt*newStack) / sum(wgt);
            tVal = sqrt(sum(wgt*square(newStack)) / sum(wgt));

          } else if (cStatisticId == QUARTILE) {
            // Weighted inter-quartile range.
            newStack -= median(newStack, wgt);
            tVal = median(abs(newStack), wgt);

          } else {
            // Shouldn't happen.
            tVal = cBlankVal;
          }
        }
      }
    }

    mapRow[i] = tVal;
  }
}

//------------------------------------------------------ MBGridder::buildStack

// Accumulate the stack for the specified row of the map plane.

void MBGridder::buildStack(
  const Matrix<Float> &data,
  const Matrix<Float> &tsys,
  const uInt j,
  Vector<Int>   &specCount,
  Vector<Float> &beamSum,
  Vector<Float> &beamRSS)

{
  Float beamWgt   = 1.0f;
  Float beamNorm  = 1.0f;
  Float smoothWgt = 1.0f;
  Float tsysWgt   = 1.0f;

  // Get pointers to Matrix storage.
  Bool delSpcPixSpan = False;
  const uShort *spcPixSpanP = cSpcPixSpan.getStorage(delSpcPixSpan);

  // Number of polarizations.
  uInt nPol = data.nrow();

  beamSum = 0.0f;
  beamRSS = 0.0f;

  specCount = 0;
  for (uInt iSpec = cSpcRowSpan(0,j); iSpec <= cSpcRowSpan(1,j); iSpec++) {
    uInt iSpcIdx = cSpcIdx(iSpec);

    uInt offset = 4*iSpcIdx;
    uInt i1 = *(spcPixSpanP + offset++);
    uInt i2 = *(spcPixSpanP + offset++);
    if (i1 > i2) continue;

    uInt j1 = *(spcPixSpanP + offset++);
    uInt j2 = *(spcPixSpanP + offset);
    if (j < j1 || j > j2) continue;

    Float spcLng = cSpcLng(iSpcIdx);
    Float spcLat = cSpcLat(iSpcIdx);
    Float spcX = cos(spcLat) * sin(spcLng);
    Float spcY = cos(spcLat) * cos(spcLng);
    Float spcZ = sin(spcLat);

    for (uInt i = i1; i <= i2; i++) {
      Double mapLng = cMapCelCrd(0,i,j);
      if (isNaN(mapLng)) {
        continue;
      }

      Double mapLat = cMapCelCrd(1,i,j);
      Float mapX = cos(mapLat) * sin(mapLng);
      Float mapY = cos(mapLat) * cos(mapLng);
      Float mapZ = sin(mapLat);

      Float dX = spcX - mapX;
      Float dY = spcY - mapY;
      Float dZ = spcZ - mapZ;
      Float xyzDistSqr = dX*dX + dY*dY + dZ*dZ;

      if (xyzDistSqr <= cXYZCutoffSqr) {
        // This pixel is close enough to the spectrum.
        Float arcDist = 2.0f*asin(sqrt(xyzDistSqr)/2.0f);
        Float arcDist2 = arcDist * arcDist;

        // Beam weighting.
        Float beamFct = exp(cBW*arcDist2);
        if (cBeamWeight == 1) {
          beamWgt = beamFct;
        } else if (cBeamWeight == 2) {
          beamWgt = beamFct * beamFct;
        } else if (cBeamWeight == 3) {
          beamWgt = beamFct * beamFct * beamFct;
        }

        // Beam normalization.
        if (cBeamNormal) {
          beamNorm = 1.0f / beamFct;
        }

        // Smoothing kernel weighting.
        if (cKernelId == TOPHAT) {
          smoothWgt = (arcDist2 <= cTW) ? 1.0f : 0.0f;
        } else if (cKernelId == GAUSSIAN) {
          smoothWgt = exp(cGW*arcDist2);
        }

        for (uInt iPol = 0; iPol < nPol; iPol++) {
          if (isNaN(data(iPol,iSpcIdx))) {
            continue;
          }

          cDataStack(i,specCount(i)) = data(iPol,iSpcIdx) * beamNorm;

          // Tsys weighting.
          if (cTsysWeight) {
            tsysWgt = 1.0 / tsys(iPol,iSpcIdx);
          }

          // Total weighting.
          cWgt(i,specCount(i)) = tsysWgt * beamWgt * smoothWgt;

          // Beam weighting statistics.
          beamSum(i) += beamFct;
          beamRSS(i) += beamFct*beamFct;

          specCount(i)++;
        }
      }
    }
  }

  beamRSS = sqrt(beamRSS);

  cSpcPixSpan.freeStorage(spcPixSpanP, delSpcPixSpan);
}
