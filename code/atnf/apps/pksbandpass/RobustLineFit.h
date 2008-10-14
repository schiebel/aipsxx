//#---------------------------------------------------------------------------
//# RobustLineFit.h: a class for robust fitting of straight lines to data
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
//# $Id: RobustLineFit.h,v 19.4 2004/11/30 17:50:10 ddebonis Exp $
//#---------------------------------------------------------------------------

#ifndef ATNF_ROBUSTLINEFIT_H
#define ATNF_ROBUSTLINEFIT_H

#include <casa/aips.h>
#include <casa/Arrays/Vector.h>

#include <casa/namespace.h>
// <summary>
// A class for robustly fitting straight lines to ordinary x-y data.
// </summary>

// <use visibility = export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
// </prerequisite>

// <etymology>
// A robust statistic is one which is insensitive to arbitrary displacements
// of up to a certain fraction of a given distribution.
// </etymology>

// <synopsis>
// The RobustLineFit class should be used to fit straight lines to data when
// the ordinary least squares class (LinearFitSVD) is not adequate for this
// purpose.  This may occur when a single dish spectra has a relatively
// straight, but "tilted" baseline, and a dominant galaxy profile or spectral
// feature of magnitude several times the noise.  In this case, the least
// squares solution (L2 norm) will result in a diminished flux measurement for
// the feature, whereas the robust fit (L1 norm) should accurately reflect the
// true flux measurement.
//
// For a set of data points <code>(x_i, y_i)</code>, the coefficients of the
// line <code>y = a*x + b</code> are determined such that the L1 norm,
// </code>sum_i abs(y_i - (a * x_i + b))</code>, is minimised.
//
// As shown in "Fitting a Line by Minimizing Absolute Deviation", in Numerical
// Recipes in C by Press et al., <code>b = median(y_i - a*x_i)</code> and
// <code>a</code> is chosen to minimize the goodness-of-fit measure obtained
// by summing the <code>x_i</code> for which <code>y_i</code> is above the
// line, and subtracting <code>x_i</code> for which <code>y_i</code> is below
// the line.
// </synopsis>

// <example>
// <srcblock>
// Vector<Float> x(NPOINTS);
// Vector<Float> y(NPOINTS);
// ...
// RobustLineFit1D<Float> fitter(0.001);
// fitter.fit(x, y);
// cout << fitter.a() << " " << fitter.b() << endl;
// </srcblock>

// <motivation>
// The Parkes southern sky survey will rely on fully automated data reduction.
// This class was developed to provide a rapid, low order robust fitting
// routine, in contrast to most robust fitting routines, which are time
// consuming and complex.
// </motivation>

// <todo asof="1996/03/01">
// </todo>

template<class T> class RobustLineFit {
public:
  // Constructor allows the tolerance level to be specified.
  RobustLineFit(const T eps = 0.001);

  ~RobustLineFit();

  // Perform the fit to the data in vectors <code>x</code> and <code>y</code>.
  // The two vectors must have equal lengths.
  void fit(const Vector<T> &x, const Vector<T> &y);

  // Get the coefficients for the robust fit.
  // <group>
  T a() {return aL1;};
  T b() {return bL1;};
  // </group>

  // Get the mean absolute deviation between the fitted line and the data
  // points.
  T dev() {return dL1;};

  // Get the coefficients for the least squares fit, determined as initial
  // guesses for the robust fit.
  // <group>
  T aLeastSquares() {return aL2;};
  T bLeastSquares() {return bL2;};
  // </group>

  // Get the root mean squared deviation between the least squares fit and
  // the data points.
  T devLeastSquares() {return dL2;};

private:
  T aL1, aL2, bL1, bL2, dL1, dL2, tol;

  // Internal routines.
  // <group>
  T aggL1dev(const T &a, const Vector<T> &x, const Vector<T> &y);
  T kpart(T *array, uInt nelem, uInt kth);
  // </group>
};

#endif
