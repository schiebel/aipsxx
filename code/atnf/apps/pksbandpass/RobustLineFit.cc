//#---------------------------------------------------------------------------
//# RobustLineFit.cc: a class for robust fitting of straight lines to data
//#---------------------------------------------------------------------------
//# Copyright (C) 1996-2003
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
//# $Id: RobustLineFit.cc,v 19.3 2004/11/30 17:50:10 ddebonis Exp $
//#---------------------------------------------------------------------------

#include <RobustLineFit.h>

#include <casa/aips.h>
#include <casa/iostream.h>
#include <casa/stdio.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayMath.h>

#include <casa/namespace.h>

//-------------------------------------------- RobustLineFit<T>::RobustLineFit

// Constructor.

template <class T>
RobustLineFit<T>::RobustLineFit(const T eps)
{
  aL1 = (T)0.0;
  bL1 = (T)0.0;
  dL1 = (T)0.0;

  aL2 = (T)0.0;
  bL2 = (T)0.0;
  dL2 = (T)0.0;

  tol = fabs(eps);
}

//------------------------------------------- RobustLineFit<T>::~RobustLineFit

// Destructor.

template <class T>
RobustLineFit<T>::~RobustLineFit(void)
{
  // Nothing.
}

//------------------------------------------------------ RobustLineFit<T>::fit

// For a set of data points (x_i, y_i), the coefficients of the line
// y = a*x + b are determined so that the L1 norm is minimised.

template <class T>
void RobustLineFit<T>::fit(
  const Vector<T> &x,
  const Vector<T> &y)
{
  T N = (T)(x.nelements());

  // Use least squares for the initial guess.
  T sx  = sum(x);
  T sy  = sum(y);
  T sxx = sum(x*x);
  T sxy = sum(x*y);
  T den = (T)1.0/(N*sxx - sx*sx);
  aL2 = (N*sxy - sx*sy)*den ;
  bL2 = (sy*sxx - sx*sxy)*den;
  dL2 = sqrt(mean(square(y - (aL2*x + bL2))));

  // First guess.
  T a1 = aL2;
  T d1 = aggL1dev(a1, x, y);

  // Second guess is made in the direction towards zero.
  T a2 = aL2;
  if (d1 > (T)0.0) {
    a2 += (T)2.0*dL2;
  } else {
    a2 -= (T)2.0*dL2;
  }
  T d2 = aggL1dev(a2, x, y);

  // Adjust initial guesses to bracket the solution.
  while (d1*d2 > (T)0.0) {
    T a = a2 + (a2 - a1);
    a1 = a2;
    d1 = d2;

    a2 = a;
    d2 = aggL1dev(a2, x, y);
  }

  // Ensure that a1 <= a2.
  if (a1 > a2) {
    T swap = a1;
    a1 = a2;
    a2 = swap;

    swap = d1;
    d1 = d2;
    d2 = swap;
  }

  // Modified regula falsi root finding.
  T da, lambda;
  while ((da = a2 - a1) > tol) {
    lambda = d1/(d1-d2);
    if (lambda < (T)0.1) {
      lambda = 0.1;
    } else if (lambda > (T)0.9) {
      lambda = 0.9;
    }

    T a = a1 + lambda*da;
    T d = aggL1dev(a, x, y);

    if (d1*d > (T)0.0) {
      a1 = a;
      d1 = d;
    } else {
      a2 = a;
      d2 = d;
    }
  }

  aL1 = (a1 + a2) * (T)0.5;
  bL1 = median(y - aL1*x, False, True);
  dL1 = mean(fabs(y - (aL1*x + bL1)));
}

//------------------------------------------------- RobustLineFit<T>::aggL1dev

// Given the linear coefficient, a, compute the goodness-of-fit of the set of
// data points (x_i, y_i) to the line y = ax + b where b = med(y_i - a*x_i).
// The goodness-of-fit measure is obtained by summing x_i for which y_i is
// above the line, and subtracting x_i for which y_i is below the line.
// Adapted from rofunc.c, "Fitting a Line by Minimizing Absolute Deviation",
// in Numerical Recipes in C by Press et al.  Racing version.

template <class T> T RobustLineFit<T>::aggL1dev(
  const T &a,
  const Vector<T> &xx,
  const Vector<T> &yy)
{
  // Copy vectors to sidestep a bug with y.freeStorage().
  Vector<T> x, y;
  x = xx;
  y = yy;

  // Compute the median value.
  Vector<T> dev = y - a*x;

  Bool deld;
  T *dp = dev.getStorage(deld);

  uInt nelem = dev.nelements();
  T b = kpart(dp, nelem, (nelem-1)/2);
  if (nelem%2 == 0) {
    b += kpart(dp+nelem/2, nelem/2, 0);
    b /= (T)2.0;
  }
  dev.putStorage(dp, deld);


  // Compute the aggregate X deviation.
  Bool delx, dely;
  const T *xp = x.getStorage(delx);
  const T *yp = y.getStorage(dely);

  T aggdev = 0.0;
  for (uInt i = 0; i < x.nelements(); i++) {
    T s = *(yp++) - (a*(*xp) + b);
    if (s > (T)0.0) {
      aggdev += *(xp++);
    } else if (s < (T)0.0) {
      aggdev -= *(xp++);
    }
  }

  x.freeStorage(xp, delx);
  y.freeStorage(yp, dely);

  return aggdev;
}

//---------------------------------------------------- RobustLineFit<T>::kpart

// Partially sort an array (using the same partitioning algorithm as used by
// quicksort) so that the element in arr[k] is in its correct place.  All
// smaller elements will be moved to arr[0:k-1] (in arbitrary order) with all
// higher elements in arr[k+1:nelem-1] (also in arbitrary order).  Adapted
// from select.c, Numerical Recipes in C by Press et al.

#define SWAP(a, b) temp = a; a = b; b = temp;

template <class T>
T RobustLineFit<T>::kpart(
  T *array,
  uInt nelem,
  uInt k)
{
  T temp;

  uInt lo = 0;
  uInt hi = nelem - 1;


  if (k == lo) {
    // Minimum is required.
    T *amin = array;
    for (T *ap = array+1; ap < array+nelem; ap++) {
      if (*ap < *amin) {
        amin = ap;
      }
    }

    SWAP(array[k], *amin);
    return array[k];
  }


  if (k == hi) {
    // Maximum is required.
    T *amax = array;
    for (T *ap = array+1; ap < array+nelem; ap++) {
      if (*ap > *amax) {
        amax = ap;
      }
    }

    SWAP(array[k], *amax);
    return array[k];
  }


  while (1) {
    if (hi <= lo+1) {
      // Active partition contains 1 or 2 elements.
      if (hi == lo+1 && array[hi] < array[lo]) {
        SWAP(array[lo], array[hi]);
      }
      return array[k];

    } else {
      // Put the left, centre, and right elements in the correct order.
      uInt mid = (lo + hi) >> 1;
      if (array[lo] > array[hi]) {
        SWAP(array[lo], array[hi]);
      }
      if (array[mid] > array[hi]) {
        SWAP(array[mid], array[hi]);
      }
      if (array[lo] > array[mid]) {
        SWAP(array[lo], array[mid])
      }

      // Choose the middle value as the partitioning element.
      T partition = array[mid];

      // Put the partitioning element out of the way in array[lo+1].
      uInt i = lo + 1;
      uInt j = hi;
      SWAP(array[mid], array[i]);

      // Apply partitioning.
      while (1) {
        do i++; while (array[i] < partition);
        do j--; while (array[j] > partition);
        if (j < i) break;
        SWAP(array[i], array[j]);
      }

      // Move the partitioning element to its correct place.
      array[lo+1] = array[j];
      array[j] = partition;

      if (j == k) {
        return array[k];
      }
      
      // Keep active the partition which contains the kth element.
      if (j > k) {
        hi = j - 1;
      } else {
        lo = i;
      }
    }
  }
}

#undef SWAP
