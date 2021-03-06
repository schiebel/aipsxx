//# Complex.cc: Implement Complex, DComplex
//# Copyright (C) 2000,2001,2002
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
//# $Id: Complex.cc,v 19.6 2004/12/20 08:22:47 gvandiep Exp $


//# Includes
#include <casa/BasicSL/Complex.h>
#include <casa/BasicMath/Math.h>
#include <casa/BasicSL/Constants.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Math functions
/// Should be in stl

#if defined(NEEDS_LOG10_COMPLEX)
DComplex log10(const DComplex &val)
{
  return DComplex(std::log(val)*C::log10e);
}

/// Should be in stl
Complex log10(const Complex &val)
{
  // Need to make log10e a Float for it to compile
  // with picky compilers
  return Complex(std::log(val)*Float(C::log10e));
}
#endif

// Near functions
// Note: max() cannot be used from Math.h until it is derived from <math>
// Note: abs() not defined in SGI
//
Bool near(const Complex &val1, const Complex &val2, Double tol)
{
  if (tol <= 0) return val1 == val2;
  if (val1 == val2) return True;
  if (std::abs(val1) == 0) return std::abs(val2) <= (1+tol)*FLT_MIN;
  else if (std::abs(val2) == 0) return std::abs(val1) <= (1+tol)*FLT_MIN;
  Float aval1(std::abs(val1)), aval2(std::abs(val2));
  return std::abs(val1-val2) <= tol * (aval1 < aval2 ? aval2 : aval1);
}

Bool near(const DComplex &val1, const DComplex &val2, Double tol)
{
  if (tol <= 0) return val1 == val2;
  if (val1 == val2) return True;
  if (std::abs(val1) == 0) return std::abs(val2) <= (1+tol)*DBL_MIN;
  else if (std::abs(val2) == 0) return std::abs(val1) <= (1+tol)*DBL_MIN;
  Double aval1(std::abs(val1)), aval2(std::abs(val2));
  return std::abs(val1-val2) <= tol * (aval1 < aval2 ? aval2 : aval1);
}

Bool nearAbs(const Complex &val1, const Complex &val2, Double tol)
{
  return std::abs(val2 - val1) <= tol;
}
Bool nearAbs(const DComplex &val1, const DComplex &val2, Double tol)
{
  return std::abs(val2 - val1) <= tol;
}

// NaN functions

Bool isNaN(const Complex &val)
{
  return isNaN(val.real()) || isNaN(val.imag());
}
Bool isNaN(const DComplex &val)
{
  return isNaN(val.real()) || isNaN(val.imag());
}
void setNaN(Complex &val)
{
  Float x; setNaN(x);
  Float y; setNaN(y);
  val = Complex(x, y);
}
void setNaN(DComplex &val)
{
  Double x; setNaN(x);
  Double y; setNaN(y);
  val = DComplex(x, y);
}

// fmod functions

DComplex fmod(const DComplex &in, const DComplex &f) {
  return DComplex(std::fmod(real(in), real(f)), imag(in)); }
Complex fmod(const Complex &in, const Complex &f) {
  return Complex(std::fmod(real(in), real(f)), imag(in)); }

// Inverse trigonometry (see Abromowitz)
DComplex atan(const DComplex &in) {
  const Double n = norm(in);
  return DComplex(0.5*std::atan(2.0*real(in)/(1.0-n)),
		  0.25*std::log((1.0+n+2*imag(in))/(1.0+n-2*imag(in))));
}
Complex atan(const Complex &in) {
  const Float n = norm(in);
  return Complex(0.5*std::atan(2.0*real(in)/(1.0-n)),
		 0.25*std::log((1.0+n+2*imag(in))/(1.0+n-2*imag(in))));
}
DComplex asin(const DComplex &in) {
  const Double n = norm(in);
  Double a = 0.5*std::sqrt(1.0+n+2*real(in));
  const Double c = 0.5*std::sqrt(1.0+n-2*real(in));
  const Double b = a-c;
  a += c;
  return DComplex(std::asin(b), std::log(a+std::sqrt(a*a-1.0)));
}
Complex asin(const Complex &in) {
  const Float n = norm(in);
  Float a = 0.5*std::sqrt(1.0+n+2*real(in));
  const Float c = 0.5*sqrt(1.0+n-2*real(in));
  const Float b = a-c;
  a += c;
  return Complex(std::asin(b), std::log(a+std::sqrt(a*a-1.0)));
}
DComplex acos(const DComplex &in) {
  const Double n = norm(in);
  Double a = 0.5*std::sqrt(1.0+n+2*real(in));
  const Double c = 0.5*std::sqrt(1.0+n-2*real(in));
  const Double b = a-c;
  a += c;
  return DComplex(std::acos(b), -std::log(a+std::sqrt(a*a-1.0)));
}
Complex acos(const Complex &in) {
  const Float n = norm(in);
  Float a = 0.5*std::sqrt(1.0+n+2*real(in));
  const Float c = 0.5*std::sqrt(1.0+n-2*real(in));
  const Float b = a-c;
  a += c;
  return Complex(std::acos(b), -std::log(a+std::sqrt(a*a-1.0)));
}
DComplex atan2(const DComplex &in, const DComplex &t2) {
  if (norm(t2) == 0) return DComplex(C::pi_2);
  const DComplex z = atan(in/t2);
  if (real(t2) > 0) return z;
  return (z + DComplex(C::pi));
}
Complex atan2(const Complex &in, const Complex &t2) {
  if (norm(t2) == 0) return Complex(C::pi_2);
  const Complex z = atan(in/t2);
  if (real(t2) > 0) return z;
  return (z + Complex(C::pi));
}
/// Temporary solutions only
DComplex erf(const DComplex &in) {
  return ::erf(in.real());
}
Complex erf(const Complex &in) {
  return ::erf(in.real());
}
DComplex erfc(const DComplex &in) {
  return ::erfc(in.real());
}
Complex erfc(const Complex &in) {
  return ::erfc(in.real());
}

} //# NAMESPACE CASA - END

// Instantiate some templates if needed.
#if !defined(AIPS_AUTO_STL)

#if defined(AIPS_SUN_NATIVE)
template std::complex<float> std::log10(const std::complex<float>&);
template std::complex<double> std::log10(const std::complex<double>&);
template std::complex<float> std::conj(const std::complex<float>&);
template std::complex<double> std::conj(const std::complex<double>&);
#endif

#if defined(AIPS_GCC3)
namespace std {
template float norm<float>(const complex<float>&);
template double norm<double>(const complex<double>&);
template float arg<float>(const complex<float>&);
template double arg<double>(const complex<double>&);
template float abs<float>(const complex<float>&);
template double abs<double>(const complex<double>&);
template complex<float> polar<float>(const float&, const float&);
template complex<double> polar<double>(const double&, const double&);
template complex<float> sqrt<float>(const complex<float>&);
template complex<double> sqrt<double>(const complex<double>&);
template complex<float> conj<float>(const complex<float>&);
template complex<double> conj<double>(const complex<double>&);
template complex<float> pow<float>(const complex<float>&, const float&);
template complex<double> pow<double>(const complex<double>&, const double&);
template complex<float> pow<float>(const complex<float>&, const complex<float>&);
template complex<double> pow<double>(const complex<double>&, const complex<double>&);
template complex<float> log<float>(const complex<float>&);
template complex<double> log<double>(const complex<double>&);
template complex<float> exp<float>(const complex<float>&);
template complex<double> exp<double>(const complex<double>&);
template complex<float> cos<float>(const complex<float>&);
template complex<double> cos<double>(const complex<double>&);
template complex<float> cosh<float>(const complex<float>&);
template complex<double> cosh<double>(const complex<double>&);
template complex<float> sin<float>(const complex<float>&);
template complex<double> sin<double>(const complex<double>&);
template complex<float> sinh<float>(const complex<float>&);
template complex<double> sinh<double>(const complex<double>&);
}
#endif

#endif
