//#---------------------------------------------------------------------------
//# FFTfilter.cc: Class to smooth spectra using FFT.
//#---------------------------------------------------------------------------
//# Copyright (C) 1994-2003
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
//# $Id: FFTfilter.cc,v 19.4 2004/11/30 17:50:10 ddebonis Exp $
//#---------------------------------------------------------------------------

#include <FFTfilter.h>

#include <casa/Arrays/ArrayMath.h>
#include <casa/BasicSL/Constants.h>
#include <casa/BasicMath/Math.h>

#include <casa/namespace.h>

//------------------------------------------------------- FFTfilter::FFTfilter

FFTfilter::FFTfilter(const FFTfilterType filterType)
{
  setFilter(filterType);
}

//------------------------------------------------------ FFTfilter::~FFTfilter

FFTfilter::~FFTfilter()
{
}

//------------------------------------------------------- FFTfilter::setFilter

void FFTfilter::setFilter(const FFTfilterType filterType)
{
  cFilterType = filterType;
  cLength = 0;
  cFilterVector.resize(0);
}

//-------------------------------------------------------- FFTfilter::doFilter

Bool FFTfilter::doFilter(Vector<Float> &spectrum)
{
  Int length = spectrum.nelements();
  if (length == 0) {
    return False;
  }

  if (length != cLength) {
    if (!makeFilterVector(length)) {
      return False;
    }
  }

  Vector<Complex> cResult;
  cFilterServer.fft(cResult, spectrum);
  cResult *= cFilterVector;
  cFilterServer.fft(spectrum, cResult);

  return True;
}

//------------------------------------------------ FFTfilter::makeFilterVector

Bool FFTfilter::makeFilterVector(const Int length)
{
  Float  amp;
  Double alpha, lambda;

  if (length < 2) {
    return False;
  }

  cLength = length;
  Int filterLength = length/2 + 1;
  cFilterVector.resize(filterLength);

  switch (cFilterType) {
    default:
    case FFTfilter::TUKEY25:
    case FFTfilter::HANNING:
      Int i0;
      if (cFilterType == FFTfilter::HANNING) {
        i0 = 0;
      } else {
        cFilterVector = Complex(1.0f,0.0f);
        i0 = Int(0.75*filterLength);
      }

      if (filterLength-1-i0 < 1) {
        return False;
      }

      alpha = C::pi/(filterLength-1-i0);
      for (Int i = i0; i < filterLength; i++) {
        amp = (cos(alpha*(i-i0)) + 1.0) / 2.0;
        cFilterVector(i) = Complex(amp, 0.0f);
      }

      break;

    case FFTfilter::POL5:
      alpha = 1.0/(filterLength-1);
      for (Int i = 0; i < filterLength; i++) {
        lambda = alpha*i;
        amp = 1.0 - lambda*lambda*lambda*lambda*lambda;
        cFilterVector(i) = Complex(amp, 0.0f);
      }

      break;
  }

  cFilterServer.resize(IPosition(1, filterLength));

  return True;
}
