//#---------------------------------------------------------------------------
//# RPolyFit.cc: Robust polynomial fitting.
//#---------------------------------------------------------------------------
//# Copyright (C) 2002-2005
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify
//# it under the terms of the GNU Library General Public License as
//# published by the Free Software Foundation; either version 2 of the
//# license, or (at your option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but
//# WITHOUT ANY WARRANTY; without even the implied warranty of
//# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//# Library General Public License for more details.
//#
//# You should have received a copy of the GNU Library General Public
//# License along with this library; if not, write to the Free Software
//# Foundation, Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: RPolyFit.cc,v 19.9 2005/07/06 08:06:17 mcalabre Exp $
//#---------------------------------------------------------------------------

#include <RPolyFit.h>

#include <casa/aips.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/MaskedArray.h>
#include <casa/Arrays/MaskArrMath.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicMath/Math.h>
#include <casa/BasicSL/String.h>

#include <casa/namespace.h>


//------------------------------------------------------ RPolyFit<T>::RPolyFit

// Constructor.

template <class T>
RPolyFit<T>::RPolyFit(
  const uInt maxCoeff,
  const Vector<T> &x)
{
  // Maximum polynomial order (number of coefficients).
  cMaxCoeff = (maxCoeff > 0) ? maxCoeff : 1;

  cNX = x.nelements();

  // Yi corresponding to a NaN value of Xi will not be corrected.
  cXMask.resize(cNX);
  cXMask = True;

  // Array to hold powers of Xi.
  cNXpow = 2*cMaxCoeff - 1;
  cXpow = new Double[cNXpow*cNX];

  // Sums of powers of Xi.
  cXsum = new Double[cNXpow];

  // Sums of powers of Xi and sums of Yi times powers of Xi with masking.
  cMaskedXsum = new Double[cNXpow];
  cMaskedYsum = new Double[cMaxCoeff];

  // Design matrix and its inverse for the polynomial fit.
  cDesign = new Double[cMaxCoeff*cMaxCoeff];

  // Work arrays for the matrix inversion.
  cMxL = new uInt[cMaxCoeff];
  cLxM = new uInt[cMaxCoeff];
  cRowMax = new Double[cMaxCoeff];


  // Initialize cXpow and cXsum.
  Double *xs = cXsum;
  for (uInt j = 0; j < cNXpow; j++) {
    *(xs++) = 0.0;
  }

  Double *xp = cXpow;
  for (uInt iX = 0; iX < cNX; iX++) {
    Double xi = x(iX);
    Double z  = 1.0;
    if (isNaN(xi)) {
      // Zero cXpow for this Xi to defeat the polynomial correction for Yi.
      xi = 0.0;
      z  = 0.0;
      cXMask(iX) = False;
    }

    xs = cXsum;
    *(xp++)  = z;
    *(xs++) += z;

    for (uInt j = 1; j < cNXpow; j++) {
      Double z = *(xp-1) * xi;
      *(xp++)  = z;
      *(xs++) += z;
    }
  }

  cMask.resize(cNX);
  cMask = cXMask;
}

//----------------------------------------------------- RPolyFit<T>::~RPolyFit

// Destructor.

template <class T>
RPolyFit<T>::~RPolyFit(void)
{
  delete [] cXpow;
  delete [] cXsum;
  delete [] cMaskedXsum;
  delete [] cMaskedYsum;
  delete [] cDesign;

  delete [] cMxL;
  delete [] cLxM;
  delete [] cRowMax;
}

//-------------------------------------------------------- RPolyFit<T>::errMsg

// Return a message describing the last error.

template <class T>
String &RPolyFit<T>::errMsg(void)
{
  return cErrMsg;
}

//----------------------------------------------------------- RPolyFit<T>::fit

// Do the adaptive polynomial fit.

template <class T>
Bool RPolyFit<T>::fit(
  Matrix<T> &y,
  Matrix<T> &coeff,
  const uInt  nIter,
  const Float xDev,
  const Bool  resetMask,
  const Bool  fitFirst)
{
  uInt nMaskNew, nMaskOld;

  coeff = 0.0;
  if (nIter < 1) {
    return True;
  }

  uInt iter = 0;
  if (resetMask) {
    // NaN Xi values form the basic mask.
    cMask = cXMask;
  }

  if ((nMaskNew = ntrue(cMask)) == 0) {
    cErrMsg = "All mask elements were False";
    return False;
  }

  if (fitFirst) {
    if (!polyfit(y, coeff)) return False;
    iter++;
  }

  Matrix<T> partCoeff(coeff.shape());
  for (; iter < nIter; iter++) {
    // Compute the median absolute deviation from the median.
    Vector<T> y0 = y.column(0);
    T med = median(y0(cMask));
    T dev = median(abs(y0(cMask) - med));

    // Discard additional discrepant points.
    cMask = (abs(y0-med) <= xDev*dev) && cMask;

    nMaskOld = nMaskNew;
    if ((nMaskNew = ntrue(cMask)) == 0) {
      cErrMsg = "All mask elements were False";
      return False;
    }

    if (iter && nMaskNew == nMaskOld) {
      // Mask didn't change.
      break;
    }

    // Fit and remove the baseline.
    if (!polyfit(y, partCoeff)) return False;
    coeff += partCoeff;
  }

  return True;
}

//------------------------------------------------------- RPolyFit<T>::setMask

// Set the fit mask.

template <class T>
void RPolyFit<T>::setMask(
  const Vector<Bool> &mask)
{
  // NaN Xi values form the basic mask.
  cMask = (cXMask && mask);
}

//------------------------------------------------------- RPolyFit<T>::getMask

// Get the fit mask as it was left after the last invokation of fit().

template <class T>
void RPolyFit<T>::getMask(
  Vector<Bool> &mask)
{
  mask = cMask;
}

//------------------------------------------------------- RPolyFit<T>::polyfit

// Compute and apply least squares polynomial fits to the columns of a matrix.
// The order of the polynomial (degree + 1) is determined by the number of
// elements of the coefficient vector supplied.

template <class T>
Bool RPolyFit<T>::polyfit(
  Matrix<T> &y,
  Matrix<T> &coeff)
{
  // Number of polynomial coefficients (order).
  uInt nCoeff = coeff.nrow();
  if (nCoeff < 1) {
    // Nothing to do.
    return True;
  }

  if (nCoeff > cMaxCoeff) {
    cErrMsg = "Number of coefficients exceeded maximum";
    return False;
  }

  if (cNX < nCoeff) {
    // The fit is under-determined.
    cErrMsg = "The fit is under-determined";
    return False;
  }

  if (y.nrow() != cNX) {
    // Non-conformant.
    cErrMsg = "Length of Y does not match X";
    return False;
  }


  // Apply masking.
  Int n = nCoeff;
  for (Int j = 0; j < 2*n-1; j++) {
    cMaskedXsum[j] = cXsum[j];
  }

  Double *xp = cXpow;
  for (uInt iX = 0; iX < cNX; iX++) {
    if (!cMask(iX)) {
      // Remove the contribution from this Xi.
      Double *xq = xp;
      for (Int j = 0; j < 2*n-1; j++) {
        cMaskedXsum[j] -= *(xq++);
      }
    }
    xp += cNXpow;
  }


  // Construct the design matrix.
  for (Int i = 0; i < n; i++) {
    for (Int j = 0; j < n; j++) {
      cDesign[n*i+j] = cMaskedXsum[i+j];
    }
  }

  // Determine the LU triangular factorization.
  if (lufact(n)) {
    cErrMsg = "Design matrix is singular";
    return False;
  }


  // Solve the polynomial for each column.
  coeff = 0.0;

  Int ncol = y.ncolumn();
  for (Int icol = 0; icol < ncol; icol++) {
    for (Int i = 0; i < n; i++) {
      cMaskedYsum[i] = 0.0;
    }

    Double *xp = cXpow;
    for (uInt iX = 0; iX < cNX; iX++) {
      if (cMask(iX)) {
        Double yi = y(iX,icol);
        Double *xq = xp;
        for (Int i = 0; i < n; i++) {
          cMaskedYsum[cLxM[i]] += *(xq++) * yi;
        }
      }
      xp += cNXpow;
    }

    // Forward substitution.
    for (Int i = 1; i < n; i++) {
      for (Int j = 0; j < i; j++) {
        cMaskedYsum[i] -= cLU[i*n+j]*cMaskedYsum[j];
      }
    }

    // Backward substitution.
    for (Int i = n-1; i >= 0; i--) {
      for (Int j = i+1; j < n; j++) {
        cMaskedYsum[i] -= cLU[i*n+j]*cMaskedYsum[j];
      }
      cMaskedYsum[i] /= cLU[i*n+i];
    }

    for (Int i = 0; i < n; i++) {
      coeff(i,icol) = cMaskedYsum[i];
    }

    // Subtract the polynomial.
    xp = cXpow;
    for (uInt iX = 0; iX < cNX; iX++) {
      Double *xq = xp;

      Double z = 0.0;
      for (Int i = 0; i < n; i++) {
        z += *(xq++)*coeff(i,icol);
      }

      y(iX,icol) -= z;

      xp += cNXpow;
    }
  }

  return True;
}

//-------------------------------------------------------- RPolyFit<T>::lufact

// LU triangular factorization with scaled partial pivoting.

template <class T>
int RPolyFit<T>::lufact(
  const Int n)
{
  Int    i, ij, ik, j, k, kj, pj;
  Int    itemp, pivot;
  Double colmax, dtemp;

  // Initialize arrays.
  for (i = 0, ij = 0; i < n; i++) {
    // Vector that records row interchanges.
    cMxL[i] = i;

    cRowMax[i] = 0.0;

    for (j = 0; j < n; j++, ij++) {
      dtemp = fabs(cDesign[ij]);
      if (dtemp > cRowMax[i]) cRowMax[i] = dtemp;
    }

    // A row of zeroes indicates a singular matrix.
    if (cRowMax[i] == 0.0) {
      return 2;
    }
  }

  // Factorize in place.
  cLU = cDesign;
  for (k = 0; k < n; k++) {
    // Decide whether to pivot.
    colmax = fabs(cLU[k*n+k]) / cRowMax[k];
    pivot = k;

    for (i = k+1; i < n; i++) {
      ik = i*n + k;
      dtemp = fabs(cLU[ik]) / cRowMax[i];
      if (dtemp > colmax) {
        colmax = dtemp;
        pivot = i;
      }
    }

    if (pivot > k) {
      // We must pivot, interchange the rows of the matrix.
      for (j = 0, pj = pivot*n, kj = k*n; j < n; j++, pj++, kj++) {
        dtemp = cLU[pj];
        cLU[pj] = cLU[kj];
        cLU[kj] = dtemp;
      }

      // Amend the vector of row maxima.
      dtemp = cRowMax[pivot];
      cRowMax[pivot] = cRowMax[k];
      cRowMax[k] = dtemp;

      // Record the interchange for later use.
      itemp = cMxL[pivot];
      cMxL[pivot] = cMxL[k];
      cMxL[k] = itemp;
    }

    // Gaussian elimination.
    for (i = k+1; i < n; i++) {
      ik = i*n + k;

      // Nothing to do if cLU[ik] is zero.
      if (cLU[ik] != 0.0) {
        // Save the scaling factor.
        cLU[ik] /= cLU[k*n+k];

        // Subtract rows.
        for (j = k+1; j < n; j++) {
          cLU[i*n+j] -= cLU[ik]*cLU[k*n+j];
        }
      }
    }
  }

  // cMxL[i] records which row of cDesign corresponds to row i of cLU.
  // cLxM[i] records which row of cLU corresponds to row i of cDesign.
  for (i = 0; i < n; i++) {
    cLxM[cMxL[i]] = i;
  }

  return 0;
}
