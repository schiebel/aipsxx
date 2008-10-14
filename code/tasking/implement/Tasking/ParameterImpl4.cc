//# ParameterImpl4.cc: Defined the Quanta implementation interface
//# Copyright (C) 1998
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
//# $Id: ParameterImpl4.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ParameterImpl.h>
#include <tasking/Tasking/ForeignParameterAccessor.h>
#include <tasking/Tasking/ForeignArrayParameterAccessor.h>

namespace casa { //# NAMESPACE CASA - BEGIN

ParameterAccessor<QuantumHolder> *makeAccessor(QuantumHolder *,
					       const String &name,
					       ParameterSet::Direction direction,
					       GlishRecord *values) {
  return new ForeignParameterAccessor<QuantumHolder>(name,
						     direction, values);
}

const String & typeName(QuantumHolder *) {
  static String name = "QuantumHolder";
  return name;
}

ParameterAccessor<Vector<QuantumHolder> > 
*makeAccessor(Vector<QuantumHolder> *,
	      const String &name,
	      ParameterSet::Direction direction,
	      GlishRecord *values) {
  return new ForeignVectorParameterAccessor<QuantumHolder>(name,
							   direction, values);
}

const String & typeName(Vector<QuantumHolder> *) {
  static String name = "Vector<QuantumHolder>";
  return name;
}

ParameterAccessor<Array<QuantumHolder> > 
*makeAccessor(Array<QuantumHolder> *,
	      const String &name,
	      ParameterSet::Direction direction,
	      GlishRecord *values) {
  return new ForeignArrayParameterAccessor<QuantumHolder>(name,
							  direction, values);
}

const String & typeName(Array<QuantumHolder> *) {
  static String name = "Array<QuantumHolder>";
  return name;
}

ParameterAccessor<Quantum<Double> > *makeAccessor(Quantum<Double> *,
						  const String &name,
						  ParameterSet::Direction direction,
						  GlishRecord *values) {
  return new ForeignNSParameterAccessor<Quantum<Double> >(name,
							  direction, values);
}

const String & typeName(Quantum<Double> *) {
  static String name = "Quantum<Double>";
  return name;
}

ParameterAccessor<Vector<Quantum<Double> > >
*makeAccessor(Vector<Quantum<Double> > *,
	      const String &name,
	      ParameterSet::Direction direction,
	      GlishRecord *values) {
  return new ForeignNSVectorParameterAccessor<Quantum<Double> >(name,
							       direction, values);
}

const String & typeName(Vector<Quantum<Double> > *) {
  static String name = "Vector<Quantum<Double> >";
  return name;
}

ParameterAccessor<Array<Quantum<Double> > >
*makeAccessor(Array<Quantum<Double> > *,
	      const String &name,
	      ParameterSet::Direction direction,
	      GlishRecord *values) {
  return new ForeignNSArrayParameterAccessor<Quantum<Double> >(name,
							       direction, values);
}

const String & typeName(Array<Quantum<Double> > *) {
  static String name = "Array<Quantum<Double> >";
  return name;
}

ParameterAccessor<Quantum<Vector<Double> > > *makeAccessor(Quantum<Vector<Double> > *,
							   const String &name,
							   ParameterSet::Direction direction,
							   GlishRecord *values) {
  return new ForeignNSParameterAccessor<Quantum<Vector<Double> > >(name,
								   direction, values);
}

const String & typeName(Quantum<Vector<Double> > *) {
  static String name = "Quantum<Vector<Double> >";
  return name;
}

ParameterAccessor<Quantum<Array<Double> > > *makeAccessor(Quantum<Array<Double> > *,
							  const String &name,
							  ParameterSet::Direction direction,
							  GlishRecord *values) {
  return new ForeignNSParameterAccessor<Quantum<Array<Double> > >(name,
								  direction, values);
}

const String & typeName(Quantum<Array<Double> > *) {
  static String name = "Quantum<Array<Double> >";
  return name;
}

} //# NAMESPACE CASA - END

