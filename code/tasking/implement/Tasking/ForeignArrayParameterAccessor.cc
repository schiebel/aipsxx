//# ForeignBaseArrayParameterAccessor.cc : Basic access an array of foreign Glish data structures
//# Copyright (C) 1998,1999,2000,2001,2003
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
//# $Id: ForeignArrayParameterAccessor.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ForeignArrayParameterAccessor.h>
#include <tasking/Tasking/ForeignParameterAccessor.h>
#include <tasking/Tasking/ParameterSet.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/IPosition.h>
#include <casa/sstream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Constructors 

template<class T>
ForeignArrayParameterAccessor<T>::
ForeignArrayParameterAccessor(const String & name, 
			      ParameterSet::Direction direction,
			      GlishRecord * values)
  : ForeignBaseArrayParameterAccessor<T>(name, direction, values) {}

//# Destructor

template<class T>
ForeignArrayParameterAccessor<T>::
~ForeignArrayParameterAccessor() {}

//# Member functions

template<class T>
Bool ForeignArrayParameterAccessor<T>::
fromRecord(String &error) {
  return ForeignBaseArrayParameterAccessor<T>::
    fromRecord(error, 0, 0,
	       &T::fromRecord,
	       &T::fromString);
}

template<class T>
Bool ForeignArrayParameterAccessor<T>::
toRecord(String &error) const {
  return ForeignBaseArrayParameterAccessor<T>::toRecord(error, 0,
							&T::toRecord,
							0,
							&T::ident);
}

template<class T>
void ForeignArrayParameterAccessor<T>::reset() {
   ForeignBaseArrayParameterAccessor<T>::reset();
}

//# Constructors 

template<class T>
ForeignVectorParameterAccessor<T>::
ForeignVectorParameterAccessor(const String & name, 
			       ParameterSet::Direction direction,
			       GlishRecord * values)
  : ForeignBaseVectorParameterAccessor<T>(name, direction, values) {}

//# Destructor

template<class T>
ForeignVectorParameterAccessor<T>::
~ForeignVectorParameterAccessor() {}

//# Member functions

template<class T>
Bool ForeignVectorParameterAccessor<T>::
fromRecord(String & error) {
  return ForeignBaseVectorParameterAccessor<T>::
    fromRecord(error, 0, 0,
	       &T::fromRecord,
	       &T::fromString);
}

template<class T>
Bool ForeignVectorParameterAccessor<T>::
toRecord(String &error) const {
  return ForeignBaseVectorParameterAccessor<T>::toRecord(error, 0,
							 &T::toRecord,
							 0,
							 &T::ident);
}

template<class T>
void ForeignVectorParameterAccessor<T>::reset() {
   ForeignBaseVectorParameterAccessor<T>::reset();
}

} //# NAMESPACE CASA - END

