//# LinearFitSVD.cc: Linear fit using Singular Value Decomposition.
//# Copyright (C) 1995,1999,2000,2001,2002,2004
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
//# $Id: LinearFitSVD.cc,v 19.4 2004/11/30 17:50:43 ddebonis Exp $

#include <scimath/Fitting/LinearFitSVD.h>

namespace casa { //# NAMESPACE CASA - BEGIN

template<class T>
LinearFitSVD<T>::LinearFitSVD() :
  LinearFit<T>() {
  svd_p = True;
  set(COLLINEARITY);
}

template<class T>
LinearFitSVD<T>::LinearFitSVD(const LinearFitSVD &other) :
  LinearFit<T>(other) {}

template<class T>
LinearFitSVD<T> &LinearFitSVD<T>::operator=(const LinearFitSVD &other) {
  if (this != &other) GenericL2Fit<T>::operator=(other);
  return *this;
}

template<class T>
LinearFitSVD<T>::~LinearFitSVD() {}

} //# NAMESPACE CASA - END

