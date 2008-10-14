//#---------------------------------------------------------------------------
//# FFTfilter.h: Class to smooth spectra using FFT
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
//# $Id: FFTfilter.h,v 19.5 2004/11/30 17:50:10 ddebonis Exp $
//#---------------------------------------------------------------------------
//# The FFTfilter class is used to smooth a spectrum using the FFT.  It
//# provides a Tukey 25% and Hanning filters amongst others.
//#---------------------------------------------------------------------------

#ifndef ATNF_FFTFILTER_H
#define ATNF_FFTFILTER_H

#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/Complex.h>
#include <scimath/Mathematics/FFTServer.h>

#include <casa/namespace.h>
class FFTfilter
{
  public:
    // Filter types.
    enum FFTfilterType {TUKEY25, HANNING, POL5};

    // Constructor.
    FFTfilter(const FFTfilterType filterType);

    // Destructor.
    ~FFTfilter();

    // Set or change the filter type.
    void setFilter(const FFTfilterType filterType);

    // Filter a spectrum.
    Bool doFilter(Vector<Float> &spectrum);

  private:
    Int  cLength;
    Vector<Complex> cFilterVector;
    FFTfilterType cFilterType;
    FFTServer<Float, Complex> cFilterServer;

    Bool makeFilterVector(const Int length);
};
#endif
