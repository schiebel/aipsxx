//# ForeignNSArrayParameterAccessor.cc : Access an array of foreign Glish data structures
//# Copyright (C) 1998,1999,2001,2003
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
//# $Id: ForeignNSArrayParameterAccessor.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

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
ForeignNSArrayParameterAccessor<T>::
ForeignNSArrayParameterAccessor(const String & name, 
				ParameterSet::Direction direction,
				GlishRecord * values)
  : ForeignBaseArrayParameterAccessor<T>(name, direction, values) {}

//# Destructor

template<class T>
ForeignNSArrayParameterAccessor<T>::
~ForeignNSArrayParameterAccessor() {}

//# Member functions

template<class T>
Bool ForeignNSArrayParameterAccessor<T>::
fromRecord(String & error) {
  return ForeignBaseArrayParameterAccessor<T>::
    fromRecord(error,
	       ForeignFromParameterAccessor,
	       ForeignStringParameterAccessor,
	       0, 0);
}

template<class T>
Bool ForeignNSArrayParameterAccessor<T>::
toRecord(String &error) const {
  return ForeignBaseArrayParameterAccessor<T>::
    toRecord(error,
	     ForeignToParameterAccessor,
	     0,
	     ForeignIdParameterAccessor,
	     0);
}

template<class T>
void ForeignNSArrayParameterAccessor<T>::reset() {
  ForeignBaseArrayParameterAccessor<T>::reset();
}

//# Constructors 

template<class T>
ForeignNSVectorParameterAccessor<T>::
ForeignNSVectorParameterAccessor(const String & name, 
				 ParameterSet::Direction direction,
				 GlishRecord * values)
  : ForeignBaseVectorParameterAccessor<T>(name, direction, values) {}

//# Destructor

template<class T>
ForeignNSVectorParameterAccessor<T>::
~ForeignNSVectorParameterAccessor() {}

//# Member functions

template<class T>
Bool ForeignNSVectorParameterAccessor<T>::
fromRecord(String & error) {
  return ForeignBaseVectorParameterAccessor<T>::
    fromRecord(error,
	       ForeignFromParameterAccessor,
	       ForeignStringParameterAccessor,
	       0, 0);
}

template<class T>
Bool ForeignNSVectorParameterAccessor<T>::
toRecord(String &error) const {
  return ForeignBaseVectorParameterAccessor<T>::
    toRecord(error,
	     ForeignToParameterAccessor,
	     0,
	     ForeignIdParameterAccessor,
	     0);
}

template<class T>
void ForeignNSVectorParameterAccessor<T>::reset() {
  ForeignBaseVectorParameterAccessor<T>::reset();
}

} //# NAMESPACE CASA - END

