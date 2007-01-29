//# ForeignBaseArrayParameterAccessor.cc : Access an array of foreign Glish data structures
//# Copyright (C) 1998,2000,2001,2003
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
//# $Id: ForeignBaseArrayParameterAccessor.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ForeignArrayParameterAccessor.h>
#include <tasking/Tasking/ForeignParameterAccessor.h>
#include <tasking/Tasking/ParameterSet.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>
#include <casa/Containers/Record.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/IPosition.h>
#include <casa/sstream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Constructors 

template<class T>
ForeignBaseArrayParameterAccessor<T>::
ForeignBaseArrayParameterAccessor(const String & name, 
				  ParameterSet::Direction direction,
				  GlishRecord * values)
  : ParameterAccessor<Array<T> >(name, direction, values,
				 new Array<T>) {}

//# Destructor

template<class T>
ForeignBaseArrayParameterAccessor<T>::
~ForeignBaseArrayParameterAccessor() {}

//# Member functions

template<class T>
Bool ForeignBaseArrayParameterAccessor<T>::fromRecord(String &error,
	   Bool (*from)(String &, T &, const GlishRecord &),
	   Bool (*frst)(String &, T &, const String &),
	   Bool (T::*fromGR)(String &, const RecordInterface &),
	   Bool (T::*fromST)(String &, const String &), Bool isvector) {
  GlishValue val = values_p->get(name());
  Bool shapeExist;
  IPosition shap;
  uInt nelem;
  if (!ForeignParameterAccessorArray(error, shapeExist, shap, nelem,
				     val, name())) return False;
  if (isvector && shap.nelements() != 1) {
    error +=  String("Parameter ") + name() + ": input must be 1-dim array";
    return False;
  }

  // Reset the array to correct size.

  this->operator()().resize(IPosition(1,0));
  this->operator()().resize(shap);
  
  if (val.type() == GlishValue::ARRAY) {
    GlishArray record = val;
    Array<String> x;
    record.get(x, True);
    Vector<String> y(x.reform(IPosition(1, x.nelements())));
    for (uInt i=0; i < nelem; i++) {
      if (!frst) {
	if (!((*this)()(toIPositionInArray(i, shap)).*
	    fromST)(error, y(i))) return False;
      } else {
	if (!frst(error, (*this)()(toIPositionInArray(i, shap)),
		  y(i))) return False;
      }
    }
  } else {
    GlishRecord grecord = val;
    if (nelem>0 && !shapeExist) {
      if (!from) {
	Record record;
	grecord.toRecord (record);
	if (!((*this)()(IPosition(1,0)).*fromGR)(error, record)) return False;
      } else {
	if (!from(error, (*this)()(IPosition(1,0)), grecord)) return False;
      }
      return True;
    }
//
    GlishValue x;
    GlishRecord y;
    for (uInt i=0; i < nelem; i++) {
      x = grecord.get(i);
      if (x.type() != GlishValue::RECORD) {
	error +=  String("Parameter ") + name() + " element must be a record";
	return False;
      };
      y = x;
      if (!from) {
	Record record;
	y.toRecord (record);
	if (!((*this)()(toIPositionInArray(i, shap)).*fromGR)(error, record)) return False;
      } else {
	if (!from(error, (*this)()(toIPositionInArray(i, shap)),y)) return False;
      }
    }
  }
  return True;
}

template<class T>
Bool ForeignBaseArrayParameterAccessor<T>::
toRecord(String &error,
	 Bool (*to)(String &, GlishRecord &, const T&),
	 Bool (T::*toGR)(String &, RecordInterface &) const,
	 const String &(*idfr)(const T &),
	 const String &(T::*idGR)() const) const {
  GlishRecord grecord;
  Int nelem = (*this)().nelements();
  GlishRecord rtmp;
  IPosition shap = (*this)().shape();
  if (nelem == 1) {
    if (!to) {
      Record record;
      if (!((*this)()(toIPositionInArray(0, shap)).*
	  toGR)(error, record)) return False;
      grecord.fromRecord (record);
    } else {
      if (!to(error, grecord, (*this)()(toIPositionInArray(0, shap)))) return False;
    };
  } else {
    for (Int i=0; i < nelem; i++) {
      if (!to) {
	Record record;
	if (!((*this)()(toIPositionInArray(i, shap)).*
	    toGR)(error, record)) return False;
	rtmp.fromRecord (record);
      } else {
	if (!to(error, rtmp, (*this)()(toIPositionInArray(i, shap)))) return False;
      };
      ostringstream oss;
      oss << "__*" << i;
      grecord.add(String(oss), rtmp);
    };
    ForeignParameterAccessorAddShape(grecord, shap);
  };
  String xid = (!idfr) ? ((T().*idGR)()) :
    idfr(T());
  ForeignParameterAccessorAddId(grecord, xid);
  values_p->add(name(), grecord);
  return True;
}

template<class T>
void ForeignBaseArrayParameterAccessor<T>::reset() {
  if (value_p) operator()().resize(IPosition(1,0));
}

//# Constructors 

template<class T>
ForeignBaseVectorParameterAccessor<T>::
ForeignBaseVectorParameterAccessor(const String & name, 
				   ParameterSet::Direction direction,
				   GlishRecord * values)
  : ParameterAccessor<Vector<T> >(name, direction, values,
				  new Vector<T>) {}

//# Destructor

template<class T>
ForeignBaseVectorParameterAccessor<T>::
~ForeignBaseVectorParameterAccessor() {}

//# Member functions

template<class T>
Bool ForeignBaseVectorParameterAccessor<T>::
fromRecord(String & error,
	   Bool (*from)(String &, T &, const GlishRecord &),
	   Bool (*frst)(String &, T &, const String &),
	   Bool (T::*fromGR)(String &, const RecordInterface &),
	   Bool (T::*fromST)(String &, const String &)) {
  return ((ForeignBaseArrayParameterAccessor<T> *)this)->
    fromRecord(error, from, frst, fromGR, fromST, True);
}

template<class T>
Bool ForeignBaseVectorParameterAccessor<T>::
toRecord(String &error,
	 Bool (*to)(String &, GlishRecord &, const T&),
	 Bool (T::*toGR)(String &, RecordInterface &) const,
	 const String &(*idfr)(const T &),
	 const String &(T::*idGR)() const) const {
  return ((ForeignBaseArrayParameterAccessor<T> *)this)->
    toRecord(error, to, toGR, idfr, idGR);
}

template<class T>
void ForeignBaseVectorParameterAccessor<T>::reset() {
  ((ForeignBaseArrayParameterAccessor<T> *)this)->reset();
}

} //# NAMESPACE CASA - END

