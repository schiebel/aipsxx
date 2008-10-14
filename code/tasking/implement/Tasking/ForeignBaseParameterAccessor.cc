//# ForeignBaseParameterAccessor.cc : Class to access foreign Glish data structures
//# Copyright (C) 1998,2003
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
//# $Id: ForeignBaseParameterAccessor.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ForeignParameterAccessor.h>
#include <tasking/Tasking/ParameterSet.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>
#include <casa/Containers/Record.h>
#include <casa/BasicSL/String.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Constructors 

template<class T>
ForeignBaseParameterAccessor<T>::
ForeignBaseParameterAccessor(const String & name, 
			 ParameterSet::Direction direction,
			 GlishRecord * values)
  : ParameterAccessor<T>(name, direction, values,
			 new T) {}

//# Destructor

template<class T>
ForeignBaseParameterAccessor<T>::~ForeignBaseParameterAccessor() {}

//# Member functions

template<class T>
Bool ForeignBaseParameterAccessor<T>::
fromRecord(String & error,
	   Bool (*from)(String &, T &, const GlishRecord &),
	   Bool (*frst)(String &, T &, const String &),
	   Bool (T::*fromGR)(String &, const RecordInterface &),
	   Bool (T::*fromST)(String &, const String &)) {
  GlishValue val = values_p->get(name());
  if (val.type() == GlishValue::ARRAY) {
    String record;
    if (!ForeignParameterAccessorScalar(error, record, val, name())) return False;
    if (!frst) {
      if (!((*this)().*fromST)(error, record)) return False;
    } else {
      if (!frst(error, (*this)(), record)) return False;
    };
  } else {
    GlishRecord record;
    if (!ForeignParameterAccessorScalar(error, record, val, name())) return False;
    if (!from) {
      Record rec;
      record.toRecord (rec);
      if (!((*this)().*fromGR)(error, rec)) return False;
    } else {
      if (!from(error, (*this)(), record)) return False;
    };
  };
  return True;
}

template<class T>
Bool ForeignBaseParameterAccessor<T>::
toRecord(String &error,
	 Bool (*to)(String &, GlishRecord &, const T&),
	 Bool (T::*toGR)(String &, RecordInterface &) const,
	 const String &(*idfr)(const T &),
	 const String &(T::*idGR)() const) const {
  GlishRecord record;
  if (!to) {
    Record rec;
    if (!((*this)().*toGR)(error, rec)) return False;
    record.fromRecord (rec);
  } else {
    if (!to(error, record, (*this)())) return False;
  };
  String xid = (!idfr) ? (((*this)().*idGR)()) :
    idfr((*this)());
  ForeignParameterAccessorAddId(record, xid);
  values_p->add(name(), record);
  return True;
}

} //# NAMESPACE CASA - END

