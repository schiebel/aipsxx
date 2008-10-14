//#---------------------------------------------------------------------------
//# RPolyFit.h: Robust polynomial fitting.
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
//# $Id: RPolyFit.h,v 19.8 2005/07/06 07:58:48 mcalabre Exp $
//#---------------------------------------------------------------------------

#ifndef ATNF_RPOLYFIT_H
#define ATNF_RPOLYFIT_H

#include <casa/aips.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>


#include <casa/namespace.h>
template<class T> class RPolyFit {
public:
  // Constructor.
  RPolyFit(const uInt maxCoeff,
           const Vector<T> &x);

  ~RPolyFit();

  String &errMsg();

  Bool fit(Matrix<T> &y,
           Matrix<T> &coeff,
           const uInt  nIter = 3,
           const Float xDev  = 2.0f,
           const Bool  resetMask = True,
           const Bool  fitFirst  = True);

  void setMask(const Vector<Bool> &mask);
  void getMask(Vector<Bool> &mask);

private:
  uInt cMaxCoeff, cNX, cNXpow;
  Vector<Bool> cMask, cXMask;
  String cErrMsg;

  Double *cXpow;
  Double *cXsum;
  Double *cMaskedXsum;
  Double *cMaskedYsum;
  Double *cDesign;

  uInt *cMxL;
  uInt *cLxM;
  Double *cRowMax;
  Double *cLU;

  Bool polyfit(Matrix<T> &y, Matrix<T> &coeff);
  Int lufact(const Int nCoeff);
};

#endif /* ATNF_RPOLYFIT_H */
