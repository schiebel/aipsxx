//# DOfftserver.cc:  
//# Copyright (C) 1996,1997,1998,2000,2001
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
//# $Id: DOfftserver.cc,v 19.6 2005/11/07 21:17:04 wyoung Exp $

//# Includes

#include <appsglish/numerics/DOfftserver.h>

#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayPosIter.h>
#include <casa/Arrays/Vector.h>
#include <casa/Exceptions/Error.h>
#include <scimath/Mathematics/Convolver.h>
#include <casa/BasicSL/Complex.h>
#include <scimath/Mathematics/FFTServer.h>
#include <casa/BasicSL/Constants.h>
#include <casa/BasicSL/Complex.h>
#include <casa/Utilities/Assert.h>

#include <lattices/Lattices/LatticeFFT.h>
#include <lattices/Lattices/ArrayLattice.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/Parameter.h>

#include <casa/Logging.h>

#include <casa/namespace.h>
fftserver::fftserver()
{
  // Nothing
}

fftserver::fftserver(const fftserver &)
{
  // Nothing
}

fftserver &fftserver::operator=(const fftserver &)
{
  return *this;
}

fftserver::~fftserver()
{
  // Nothing
}

void fftserver::complexfft(Array<Complex> &a, Int dir)
{
  Bool forwardTransform = False;
  if (dir > 0)
    forwardTransform = True;
  FFTServer<Float, Complex> server(a.shape(), FFTEnums::COMPLEX);
  server.fft(a, forwardTransform);
}

Array<Complex> fftserver::
mfft(const Array<Complex> & a, const Vector<Bool> & axes, Bool forward) {
  Array<Complex> retVal(a.copy());
  //  cout << "Input Array:" << retVal << endl;
  // I convert to a Lattice because the routines for FFT'ing along selected
  // axes are not yet available in the FFTServer class.
  ArrayLattice<Complex> lat(retVal);
  LatticeFFT::cfft(lat, axes, forward);
  //  cout << "Output Array:" << retVal << endl;
  return retVal;
}

Array<Complex> fftserver::realtocomplexfft(const Array<Float>& a)
{
  Array<Complex> carr(a.shape());
  convertArray(carr, a);
  //    cout << "arr  : " << arr << endl;
  // cout << "carr : " << carr << endl;
  complexfft(carr, 1);
  // cout << "FFT of carr : " << carr << endl;
  return carr;
}

Array<Float> 
fftserver::convolve(const Array<Float> &a, const Array<Float> &b)
{
  Array<Float> result;

  const Array<Float> *psf = 0;
  const Array<Float> *model = 0;

  // It probably doesn't matter, but call the array with the fewest
  // elements the PSF.
  if (a.nelements() < b.nelements()) {
    psf = &a;
    model = &b;
  } else {
    psf = &b;
    model = &a;
  }

  Convolver<Float> conv(*psf, model->shape());
  conv.linearConv(result, *model);

  return result;
}

Array<Float>
fftserver::crosscorr(const Array<Float> &a, const Array<Float> &b)
{

  static LogOrigin OR("fftserver", "crosscorr(const Array<Float> &a, "
		      "const Array<Float> &b)", WHERE);
  static LogMessage msg;
  msg.message("Note: crosscorr does a circular, not a linear, correlation").
    line(__LINE__);
  LogSink::postGlobally(msg);

  // compute the FTs
  FFTServer<Float, Complex> server(a.shape());
  Array<Complex> temp1;
  server.fft(temp1, a);
  Array<Complex> temp2;
  server.fft(temp2, b);

  // multiply temp1 by conj of temp2
  temp1 *= conj(temp2);

  // inverse FT and return
  Array<Float> retVal(a.shape());
  server.fft(retVal, temp1);
  return retVal;
}
    
Array<Float> 
fftserver::autocorr(const Array<Float> &a)
{
  // compute the FT
  FFTServer<Float, Complex> server(a.shape());
  Array<Complex> temp;
  server.fft(temp, a);

    // multiply temp by conj of temp
  temp *= conj(temp);

  // inverse FT and return
  Array<Float> retVal(a.shape());
  server.fft(retVal, temp);
  return retVal;
}

Array<Float>
fftserver::shift(const Array<Float> & a, const Vector<Float> & shiftIn)
{
  const IPosition shape = a.shape();
  AlwaysAssert(shape.product() != 0, AipsError);
  const uInt ndim = shape.nelements();
  AlwaysAssert(shiftIn.nelements() == ndim, AipsError);
  FFTServer<Float, Complex> server(shape);
  Array<Complex> spectrum;
  server.fft0(spectrum, a); 
  Vector<Float> shift(shiftIn.copy());
  const Complex mTwoPiI(0.0, - C::_2pi);
  Vector<Float> products(ndim);
  uInt i;
  for (i = 0; i < ndim; i++)
    products(i) = shift(i) / Float(shape(i));

  Float partialSum;
  ArrayPositionIterator iter(spectrum.shape(), 0);
  while (!iter.pastEnd()) {
    partialSum = 1.0f;
    for (i = 0; i < ndim; i++) {
      // inefficient, since partial sum doesn't change that often
      partialSum += products(i) * iter.pos()(i);
    }
    spectrum(iter.pos()) *= exp(mTwoPiI * partialSum);
    iter.next();
  }
  Array<Float> retVal(a.shape());
  server.fft0(retVal, spectrum);
  return retVal;
}


String fftserver::className() const
{
  return String("fftserver");
}

Vector<String> fftserver::methods() const
{
  Vector<String> names(NUM_METHODS);
  names(COMPLEXFFT) = "complexfft";
  names(REALTOCOMPLEXFFT) = "realtocomplexfft";
  names(CONVOLVE) = "convolve";
  names(CROSSCORR) = "crosscorr";
  names(AUTOCORR) = "autocorr";
  names(SHIFT) = "shift";
  names(MFFT) = "mfft";
  return names;
}

Vector<String> fftserver::noTraceMethods() const
{
  return methods();
}

MethodResult fftserver::runMethod(uInt which, 
				  ParameterSet &inputRecord,
				  Bool runMethod)
{
  static String aString("a");
  static String dirString("dir");
  static String bString("b");
  static String shiftString("shift");
  static String returnvalString("returnval");
  static String forwardString("forward");
  static String axesString("axes");
  
  switch(which) {
  case COMPLEXFFT: {
    Parameter< Array<Complex> > a(inputRecord, aString,
				  ParameterSet::InOut);
    Parameter< Int > dir(inputRecord, dirString,
			 ParameterSet::In);
    if (runMethod) {
      complexfft(a(), dir());
    }
  }
  break;
  case REALTOCOMPLEXFFT: {
    Parameter< Array<Float> > a(inputRecord, aString,
				ParameterSet::In);
    Parameter< Array<Complex> > returnval(inputRecord, returnvalString,
					  ParameterSet::Out);
    if (runMethod) {
      returnval() = realtocomplexfft(a());
    }
  }
  break;
  case CONVOLVE: {
    Parameter< Array<Float> > a(inputRecord, aString,
				ParameterSet::In);
    Parameter< Array<Float> > b(inputRecord, bString,
				ParameterSet::In);
    Parameter< Array<Float> > returnval(inputRecord, returnvalString,
					ParameterSet::Out);
    if (runMethod) {
      returnval() = convolve(a(), b());
    }
  }
  break;
  case CROSSCORR: {
    Parameter< Array<Float> > a(inputRecord, aString,
				ParameterSet::In);
    Parameter< Array<Float> > b(inputRecord, bString,
				ParameterSet::In);
    Parameter< Array<Float> > returnval(inputRecord, returnvalString,
					ParameterSet::Out);
    if (runMethod) {
      returnval() = crosscorr(a(), b());
    }
  }
  break;
  case AUTOCORR: {
    Parameter< Array<Float> > a(inputRecord, aString,
				ParameterSet::In);
    Parameter< Array<Float> > returnval(inputRecord, returnvalString,
					ParameterSet::Out);
    if (runMethod) {
      returnval() = autocorr(a());
    }
  }
  break;
  case SHIFT: {
    Parameter< Array<Float> > a(inputRecord, aString,
				ParameterSet::In);
    Parameter< Vector<Float> > shift(inputRecord, shiftString,
				     ParameterSet::In);
    Parameter< Array<Float> > returnval(inputRecord, returnvalString,
					ParameterSet::Out);
    if (runMethod) {
      returnval() = fftserver::shift(a(), shift());
    }
  }
  break;
  case MFFT: {
    const Parameter<Array<Complex> > a(inputRecord, aString,
				       ParameterSet::In);
    const Parameter<Vector<Bool> > axes(inputRecord, axesString, 
					ParameterSet::In);
    const Parameter<Bool> forward(inputRecord, forwardString, 
				  ParameterSet::In);
    Parameter<Array<Complex> > returnval(inputRecord, returnvalString,
					 ParameterSet::Out);
    if (runMethod) {
      returnval() = mfft(a(), axes(), forward());
    }
  }
  break;
  default:
    return error("No such method");
  }

  return ok();
}
// Local Variables: 
// compile-command: "gmake DOfftserver"
// End: 
