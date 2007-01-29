//# ParameterImp6.cc: this defines ParameterImpl for FunctionHolder
//# Copyright (C) 2002
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
//# $Id: ParameterImpl6.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ParameterImpl.h>
#include <tasking/Tasking/ForeignParameterAccessor.h>
namespace casa { //# NAMESPACE CASA - BEGIN

///#include <tasking/Tasking/ForeignArrayParameterAccessor.h>

ParameterAccessor<FunctionHolder<Double> >
*makeAccessor(FunctionHolder<Double> *, const String &name,
	      ParameterSet::Direction direction,
	      GlishRecord *values) {
  return new ForeignParameterAccessor<FunctionHolder<Double> >
    (name, direction, values);
}

const String & typeName(FunctionHolder<Double> *) {
  static String name = "FunctionHolder<Double>";
  return name;
}

ParameterAccessor<FunctionHolder<DComplex> >
*makeAccessor(FunctionHolder<DComplex> *, const String &name,
	      ParameterSet::Direction direction,
	      GlishRecord *values) {
  return new ForeignParameterAccessor<FunctionHolder<DComplex> >
    (name, direction, values);
}

const String & typeName(FunctionHolder<DComplex> *) {
  static String name = "FunctionHolder<DComplex>";
  return name;
}

} //# NAMESPACE CASA - END

