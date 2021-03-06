//# Quantum.cc: class to manipulate physical, dimensioned quantities
//# Copyright (C) 1994,1995,1996,1997,1998,1999,2000,2001,2003,2004
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
//# $Id: Quantum.cc,v 19.5 2004/11/30 17:50:18 ddebonis Exp $

//# Includes
#include <casa/BasicSL/Complex.h>
#include <casa/BasicSL/Constants.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Cube.h>
#include <casa/Exceptions/Error.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Utilities/MUString.h>
#include <casa/Quanta/MVAngle.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Utilities/Register.h>
#include <casa/Utilities/Regex.h>
#include <casa/sstream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

template <class Qtype>
Quantum<Qtype>::Quantum() :
    QBase() { qVal = Qtype();}

template <class Qtype>
Quantum<Qtype>::Quantum(const Quantum<Qtype> &other) :
    QBase(other), qVal(other.qVal) {}

template <class Qtype>
Quantum<Qtype>::Quantum(const Qtype &factor) : QBase(),
    qVal(factor) {}

template <class Qtype>
Quantum<Qtype>::Quantum(const Qtype &factor, const Unit &s) :
  QBase(s),
  qVal(factor) {}

template <class Qtype>
Quantum<Qtype>::Quantum(const Qtype &factor, const QBase &other) :
  QBase(other),
  qVal(factor) {}

template <class Qtype>
Quantum<Qtype>::~Quantum() {}

//# Quantum operators

template <class Qtype>
Quantum<Qtype> &Quantum<Qtype>::operator=(const Quantum<Qtype> &other) {
    if (this != &other) {
      qVal=other.qVal;
      qUnit=other.qUnit;
    }
    return *this;
}

template <class Qtype>
const Quantum<Qtype> &Quantum<Qtype>::operator+() const{
    return *this;
}

template <class Qtype>
Quantum<Qtype> Quantum<Qtype>::operator-() const{
    Quantum<Qtype> loc;
    loc.qVal = -qVal;
    loc.qUnit = qUnit;
    return loc;
}

template <class Qtype>
Quantum<Qtype> &Quantum<Qtype>::operator+=(const Quantum<Qtype> &other) {
    if (qUnit.getValue() != other.qUnit.getValue()) {
	throw (AipsError("Quantum::operator+ unequal units '" +
			 qUnit.getName() + ", '" + 
			 other.qUnit.getName() + "'"));
    } else {
        Qtype tmp = other.getValue(qUnit);
	qVal += (tmp);
    }
    return *this;
}

template <class Qtype>
Quantum<Qtype> &Quantum<Qtype>::operator+=(const Qtype &other) {
    qVal += other;
    return *this;
}

template <class Qtype>
Quantum<Qtype> &Quantum<Qtype>::operator-=(const Quantum<Qtype> &other) {
    if (qUnit.getValue() != other.qUnit.getValue()) {
	throw (AipsError("Quantum::operator- unequal units '" +
			 qUnit.getName() + ", '" + 
			 other.qUnit.getName() + "'"));
    } else {
        Qtype tmp = other.getValue(qUnit);
	qVal -= (tmp);
    }
    return *this;
}

template <class Qtype>
Quantum<Qtype> &Quantum<Qtype>::operator-=(const Qtype &other) {
    qVal -= (other);
    return *this;
}

template <class Qtype>
Quantum<Qtype> &Quantum<Qtype>::operator*=(const Quantum<Qtype> &other) {
    qVal *= (other.qVal); 
    if (!(other.qUnit.getName().empty())) {
	if (qUnit.getName().empty()) {
	    qUnit = other.qUnit;
	} else {
	    qUnit = Unit(qUnit.getName() + ("." + other.qUnit.getName()));
	}
    }
    return *this;
}

template <class Qtype>
Quantum<Qtype> &Quantum<Qtype>::operator*=(const Qtype &other) {
    qVal *= (other);
    return *this;
}

template <class Qtype>
Quantum<Qtype> &Quantum<Qtype>::operator/=(const Quantum<Qtype> &other) {
    qVal /= (other.qVal);
    if (!(other.qUnit.getName().empty())) {
	if (qUnit.getName().empty()) {
	    qUnit = Unit(String("(") + other.qUnit.getName() +
			 String(")-1"));
	} else {
	    qUnit = Unit(qUnit.getName() +
			 ("/(" + other.qUnit.getName() + ")"));
	}
    }
    return *this;
}

template <class Qtype>
Quantum<Qtype> &Quantum<Qtype>::operator/=(const Qtype &other) {
    qVal /= (other);
    return *this;
}

template <class Qtype>
Quantum<Qtype> Quantum<Qtype>::operator+(const Quantum<Qtype> &other) const{
    Quantum<Qtype> loc; loc = *this;
    loc += other;
    return loc;
}

template <class Qtype>
Quantum<Qtype> Quantum<Qtype>::operator-(const Quantum<Qtype> &other) const{
    Quantum<Qtype> loc; loc = *this;
    loc -= other;
    return loc;
}

template <class Qtype>
Quantum<Qtype> Quantum<Qtype>::operator*(const Quantum<Qtype> &other) const{
    Quantum<Qtype> loc; loc = *this; 
    loc *= other;
    return loc;
}

template <class Qtype>
Quantum<Qtype> Quantum<Qtype>::operator/(const Quantum<Qtype> &other) const{
    Quantum<Qtype> loc; loc = *this;
    loc /= other;
    return loc;
}

template <class Qtype>
void  Quantum<Qtype>::print(ostream &os) const {
    os << qVal << " " << qUnit.getName();
}

//# Quantum general member functions

template <class Qtype>
const Qtype &Quantum<Qtype>::getValue() const {
    return qVal;
}

template <class Qtype>
Qtype & Quantum<Qtype>::getValue() {
  return qVal;
}

template <class Qtype>
Qtype Quantum<Qtype>::getValue(const Unit &other) const {
    Double d1 = other.getValue().getFac() /
	qUnit.getValue().getFac();	// SUN native overloading problems
    if (qUnit.getValue() == UnitVal::ANGLE) {
      if (other.getValue() == UnitVal::TIME)
	d1 *= C::circle/C::day;
    } else if (qUnit.getValue() == UnitVal::TIME) {
      if (other.getValue() == UnitVal::ANGLE)
	d1 *= C::day/C::circle;
    };
    return (Qtype)(qVal/d1);
}

template <class Qtype>
Qtype Quantum<Qtype>::getBaseValue() const {
    return (Qtype)(qVal * qUnit.getValue().getFac());
}

template <class Qtype>
const Unit &Quantum<Qtype>::getFullUnit() const {
    return qUnit;
}

template <class Qtype>
void Quantum<Qtype>::scale(const Qtype &factor) {
    qVal *= (factor);
}

template <class Qtype>
void Quantum<Qtype>::setValue(const Qtype &val) {
    qVal = val;
}

template <class Qtype>
Bool Quantum<Qtype>::read(Quantity &res, MUString &in) {
  Double val0 = 0.0;
  String unit = "";
  res = Quantity();
  UnitVal uv;
  in.push();
  if (!in.eos()) {
    if (MVAngle::read(res, in) || MVTime::read(res, in)) {
      val0 = res.getValue();
      unit = res.getUnit();
    } else {
      val0 = in.getDouble();
      unit = in.get();
      // Check if valid unit specified
      if (!UnitVal::check(unit, uv)) {
	in.pop(); return False;
      };
    };
  };
  //
  // The next statement is necessary once the read return arg is templated
  //  Qtype tmp = (Qtype)((res.getValue()) + val0)
  res.setValue(val0);
  res.setUnit(unit);
  in.unpush(); return True; 
}

template <class Qtype>
Bool Quantum<Qtype>::read(Quantity &res, const String &in) {
  static Regex ex("^[[:space:][:punct:]]*[[:digit:]]");
  static Regex ex2("[tT][oO][dD][aA][yY]");
  static Regex ex3("[nN][oO][wW]");
  MUString tmp(in);
  // The next construct is to cater for an unexplained error in
  // the Linux egcs stream input library; and an even more funny one in sgi
  ///  if (!in.empty() && (in[0] == 'n' || in[0] == 'N' || in[0] == 'y' ||
  ///		      in[0] == 'Y')) {
  if (!in.empty() && !in.contains(ex2) && !in.contains(ex3) &&
      !in.contains(ex)) {
    tmp = MUString(String("0.0") + in);		// Pointed non-const String
  };
  return Quantum<Qtype>::read(res, tmp);
}

template <class Qtype>
Bool Quantum<Qtype>::check(const UnitVal &uv) const {
    return ( (qUnit.getValue() == uv) ? True : False); 
}

template <class Qtype>
void Quantum<Qtype>::assure(const UnitVal &uv) const {
    if (qUnit.getValue() != uv) {
	throw(AipsError("Quantum::assure non-conforming unit type '" +
			getUnit() + "'"));
    }
}

template <class Qtype>
void Quantum<Qtype>::convert() {
    this->convert(Unit());
}

template <class Qtype>
void Quantum<Qtype>::convert(const Unit &s) {
    if (qUnit.getValue() == s.getValue()) {
      // To suppress some warnings, next statement not used
      //	qVal *= (qUnit.getValue().getFac()/s.getValue().getFac());
      qVal = (Qtype) (qVal * 
		      (qUnit.getValue().getFac()/s.getValue().getFac()));
      qUnit = s;
    } else {
      if (qUnit.getValue() == UnitVal::ANGLE && 
	  s.getValue() == UnitVal::TIME) {
	qVal = (Qtype) (qVal *
			(qUnit.getValue().getFac()/s.getValue().getFac()) *
			C::day/C::circle);
	qUnit = s;
      } else if (qUnit.getValue() == UnitVal::TIME &&
		 s.getValue() == UnitVal::ANGLE) {
	qVal = (Qtype) (qVal *
			(qUnit.getValue().getFac()/s.getValue().getFac()) *
			C::circle/C::day);
	qUnit = s;
      } else {
	qUnit.setValue(qUnit.getValue() / s.getValue());
	ostringstream oss;
	oss << qUnit.getValue().getDim();
	// Suppress (gcc) warnings:
	qVal = (Qtype) (qVal * qUnit.getValue().getFac());
	if (s.empty()) {
	  qUnit = String(oss);
	} else {
	  qUnit = Unit(s.getName() + '.' + String(oss).after(0));
	};
      };
    };
}

template <class Qtype>
void Quantum<Qtype>::convert(const Quantum<Qtype> &other) {
    this->convert(other.qUnit);
}

template <class Qtype>
Quantum<Qtype> Quantum<Qtype>::get() const {
    return get(Unit());
}

template <class Qtype>
Quantum<Qtype> Quantum<Qtype>::get(const Unit &s) const {
    Quantum<Qtype> res = *this;
    res.convert(s); return res;
}

template <class Qtype>
Quantum<Qtype> Quantum<Qtype>::get(const Quantum<Qtype> &other) const{
    return get(other.qUnit);
}

template <class Qtype>
QBase *Quantum<Qtype>::clone() const {
  return (new Quantum<Qtype>(*this));
}

template <class Qtype>
uInt Quantum<Qtype>::type() const {
  return Register(static_cast<Quantum<Qtype> *>(0));
}

template <class Qtype>
uInt Quantum<Qtype>::myType() {
  return Register(static_cast<Quantum<Qtype> *>(0));
}


} //# NAMESPACE CASA - END

