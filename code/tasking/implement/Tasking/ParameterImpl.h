//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,1998,2000,2002
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
//# $Id: ParameterImpl.h,v 19.7 2004/11/30 17:51:11 ddebonis Exp $

#ifndef TASKING_PARAMETERIMPL_H
#define TASKING_PARAMETERIMPL_H

#include <casa/aips.h>
#include <tasking/Tasking/ParameterSet.h>
#include <tasking/Tasking/ParameterAccessor.h>

//# Needed for various Parameter<Type>'s
#include <casa/BasicSL/Complex.h>
#include <casa/BasicSL/String.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Vector.h>
#include <images/Images/PagedImage.h>
#include <tables/Tables/Table.h>
#include <tasking/Tasking/Index.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Quanta/QuantumHolder.h>
#include <measures/Measures/MeasureHolder.h>
#include <scimath/Functionals/FunctionHolder.h>
#include <casa/System/ObjectID.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class MEpoch;
class MDirection;
class MPosition;
class MFrequency;
class MDoppler;
class MRadialVelocity;
class MBaseline;
class Muvw;
class MEarthMagnetic;
class SkyComponent;

class ParameterAccessorBase;

#define DECLARE_FOR_TYPE(Type) \
ParameterAccessor< Type > *makeAccessor( \
		    Type *dummy, \
		    const String &name, \
		    ParameterSet::Direction direction, \
		    GlishRecord *values); \
 \
const String &typeName(Type *dummy)

//# Standard scalars
DECLARE_FOR_TYPE(Bool);
DECLARE_FOR_TYPE(Int);
DECLARE_FOR_TYPE(Float);
DECLARE_FOR_TYPE(Double);
DECLARE_FOR_TYPE(Complex);
DECLARE_FOR_TYPE(DComplex);
DECLARE_FOR_TYPE(String);

//# Arrays
DECLARE_FOR_TYPE(Array<Bool>);
DECLARE_FOR_TYPE(Array<Int>);
DECLARE_FOR_TYPE(Array<Float>);
DECLARE_FOR_TYPE(Array<Double>);
DECLARE_FOR_TYPE(Array<Complex>);
DECLARE_FOR_TYPE(Array<DComplex>);
DECLARE_FOR_TYPE(Array<String>);

//# Vectors
DECLARE_FOR_TYPE(Vector<Bool>);
DECLARE_FOR_TYPE(Vector<Int>);
DECLARE_FOR_TYPE(Vector<Float>);
DECLARE_FOR_TYPE(Vector<Double>);
DECLARE_FOR_TYPE(Vector<Complex>);
DECLARE_FOR_TYPE(Vector<DComplex>);
DECLARE_FOR_TYPE(Vector<String>);

//# Other oddball types
DECLARE_FOR_TYPE(Index);
DECLARE_FOR_TYPE(Vector<Index>);
DECLARE_FOR_TYPE(GlishRecord);
DECLARE_FOR_TYPE(GlishArray);
DECLARE_FOR_TYPE(GlishValue);
DECLARE_FOR_TYPE(ObjectID);

//# Quanta
DECLARE_FOR_TYPE(QuantumHolder);
DECLARE_FOR_TYPE(Vector<QuantumHolder>);
DECLARE_FOR_TYPE(Array<QuantumHolder>);
DECLARE_FOR_TYPE(Quantum<Double>);
DECLARE_FOR_TYPE(Vector<Quantum<Double> >);
DECLARE_FOR_TYPE(Array<Quantum<Double> >);
DECLARE_FOR_TYPE(Quantum<Vector<Double> >);
DECLARE_FOR_TYPE(Quantum<Array<Double> >);

//# Measures
DECLARE_FOR_TYPE(MeasureHolder);
DECLARE_FOR_TYPE(Vector<MeasureHolder>);
DECLARE_FOR_TYPE(Array<MeasureHolder>);
DECLARE_FOR_TYPE(MEpoch);
DECLARE_FOR_TYPE(MDirection);
DECLARE_FOR_TYPE(MPosition);
DECLARE_FOR_TYPE(MFrequency);
DECLARE_FOR_TYPE(MDoppler);
DECLARE_FOR_TYPE(MRadialVelocity);
DECLARE_FOR_TYPE(MBaseline);
DECLARE_FOR_TYPE(Muvw);
DECLARE_FOR_TYPE(MEarthMagnetic);

//# Sky components
DECLARE_FOR_TYPE(SkyComponent);
DECLARE_FOR_TYPE(Vector<SkyComponent>);
DECLARE_FOR_TYPE(Array<SkyComponent>);

//# Data classes
DECLARE_FOR_TYPE(PagedImage<Float>);
DECLARE_FOR_TYPE(Table);

//# Functionals
DECLARE_FOR_TYPE(FunctionHolder<Double>);
DECLARE_FOR_TYPE(FunctionHolder<DComplex>);


} //# NAMESPACE CASA - END

#endif
