//# Foreign2ParameterAccessor.cc : Implement Quanta conversions
//# Copyright (C) 1998,1999,2003
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
//# $Id: Foreign2ParameterAccessor.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ForeignParameterAccessor.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>
#include <casa/Containers/Record.h>
#include <casa/BasicSL/String.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Arrays/Vector.h>
#include <casa/Quanta/QuantumHolder.h>

namespace casa { //# NAMESPACE CASA - BEGIN

template < >
Bool ForeignFromParameterAccessor <Quantum<Double> > (String &error,
				  Quantum<Double> &out,
				  const GlishRecord &record) {
  QuantumHolder x;
  Record rec;
  record.toRecord (rec);
  if (!x.fromRecord(error, rec)) return False;
  if (!x.isQuantumDouble()) {
    error += String("Illegal quantum type asked");
    return False;
  };
  out = x.asQuantumDouble();
  return True;
}

template < >
Bool ForeignStringParameterAccessor <Quantum<Double> > (String &error,
				    Quantum<Double> &out,
				    const String &record) {
  QuantumHolder x;
  if (!x.fromString(error, record)) return False;
  if (!x.isQuantumDouble()) {
    error += String("Illegal quantum type asked");
    return False;
  };
  out = x.asQuantumDouble();
  return True;
}

template < >
Bool ForeignToParameterAccessor <Quantum<Double> > (String &error,
				GlishRecord &record,
				const Quantum<Double> &in) {
  QuantumHolder x(in);
  Record rec;
  if (! x.toRecord(error, rec)) return False;
  record.fromRecord (rec);
  return True;
}

template < >
const String &ForeignIdParameterAccessor <Quantum<Double> > (const Quantum<Double> &) {
  QuantumHolder x;
  return x.ident();
}

template < >
Bool ForeignFromParameterAccessor <Quantum<Vector<Double> > > (String &error,
				  Quantum<Vector<Double> > &out,
				  const GlishRecord &record) {
  QuantumHolder x;
  Record rec;
  record.toRecord (rec);
  if (!x.fromRecord(error, rec)) return False;
  if (!x.isReal() && !x.isQuantumVectorDouble() && !x.isQuantumArrayDouble()) {
    error += String("Illegal quantum type asked");
    return False;
  };
  out.getValue().resize(0);
  out = x.asQuantumVectorDouble();
  return True;
}

template < >
Bool ForeignStringParameterAccessor <Quantum<Vector<Double> > > (String &error,
				    Quantum<Vector<Double> > &out,
				    const String &record) {
  QuantumHolder x;
  if (!x.fromString(error, record)) return False;
  if (!x.isReal() && !x.isQuantumVectorDouble() && !x.isQuantumArrayDouble()) {
    error += String("Illegal quantum type asked");
    return False;
  };
  out.getValue().resize(0);
  out = x.asQuantumVectorDouble();
  return True;
}

template < >
Bool ForeignToParameterAccessor <Quantum<Vector<Double> > > (String &error,
				GlishRecord &record,
				const Quantum<Vector<Double> > &in) {
  QuantumHolder x(in);
  Record rec;
  if (! x.toRecord(error, rec)) return False;
  record.fromRecord (rec);
  return True;
}

template < >
const String &ForeignIdParameterAccessor <Quantum<Vector<Double> > > (const Quantum<Vector<Double> > &) {
  QuantumHolder x;
  return x.ident();
}

template < >
Bool ForeignFromParameterAccessor <Quantum<Array<Double> > > (String &error,
				  Quantum<Array<Double> > &out,
				  const GlishRecord &record) {
  QuantumHolder x;
  Record rec;
  record.toRecord (rec);
  if (!x.fromRecord(error, rec)) return False;
  if (!x.isQuantumArrayDouble()) {
    error += String("Illegal quantum type asked");
    return False;
  };
  out.getValue().resize(IPosition());
  out = x.asQuantumArrayDouble();
  return True;
}

template < >
Bool ForeignStringParameterAccessor <Quantum<Array<Double> > > (String &error,
				    Quantum<Array<Double> > &out,
				    const String &record) {
  QuantumHolder x;
  if (!x.fromString(error, record)) return False;
  if (!x.isQuantumArrayDouble()) {
    error += String("Illegal quantum type asked");
    return False;
  };
  out.getValue().resize(IPosition());
  out = x.asQuantumArrayDouble();
  return True;
}

template < >
Bool ForeignToParameterAccessor <Quantum<Array<Double> > > (String &error,
				GlishRecord &record,
				const Quantum<Array<Double> > &in) {
  QuantumHolder x(in);
  Record rec;
  if (! x.toRecord(error, rec)) return False;
  record.fromRecord (rec);
  return True;
}

template < >
const String &ForeignIdParameterAccessor <Quantum<Array<Double> > > (const Quantum<Array<Double> > &) {
  QuantumHolder x;
  return x.ident();
}


} //# NAMESPACE CASA - END

