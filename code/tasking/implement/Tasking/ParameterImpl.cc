//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,1998,1999,2001,2003
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
//# $Id: ParameterImpl.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ParameterImpl.h>
#include <tasking/Tasking/ScalarParameterAccessor.h>
#include <tasking/Tasking/ArrayParameterAccessor.h>
#include <tasking/Tasking/IndexParameterAccessor.h>
#include <tasking/Tasking/GlishValueParameterAccessor.h>
#include <tasking/Tasking/ObjectIDParameterAccessor.h>
#include <casa/Utilities/DataType.h>

#include <casa/sstream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

#define DEFINE_SCALAR_TYPE(Type) \
ParameterAccessor<Type> *makeAccessor( \
                    Type *, \
		    const String &name, \
		    ParameterSet::Direction direction, \
		    GlishRecord *values) \
{ \
    return new ScalarParameterAccessor<Type>(name, direction, values); \
} \
 \
const String &typeName(Type *dummy) \
{  \
    static String name; \
    if (name.length() == 0) { \
        DataType type = whatType(dummy); \
	ostringstream os; \
	os << type; \
	name = String(os); \
    } \
    return name; \
}

DEFINE_SCALAR_TYPE(Bool);
DEFINE_SCALAR_TYPE(Int);
DEFINE_SCALAR_TYPE(Float);
DEFINE_SCALAR_TYPE(Double);
DEFINE_SCALAR_TYPE(Complex);
DEFINE_SCALAR_TYPE(DComplex);
DEFINE_SCALAR_TYPE(String);

#define DEFINE_ARRAY_TYPE(ElType) \
ParameterAccessor< Array< ElType > > *makeAccessor( \
                    Array< ElType > *, \
		    const String &name, \
		    ParameterSet::Direction direction, \
		    GlishRecord *values) \
{ \
    return new ArrayParameterAccessor<ElType>(name, direction, values); \
} \
 \
const String &typeName(Array< ElType > *dummy) \
{  \
    static String name; \
    if (name.length() == 0) { \
        DataType type = whatType(dummy); \
	ostringstream os; \
	os << type; \
	name = String(os); \
    } \
    return name; \
}

DEFINE_ARRAY_TYPE(Bool);
DEFINE_ARRAY_TYPE(Int);
DEFINE_ARRAY_TYPE(Float);
DEFINE_ARRAY_TYPE(Double);
DEFINE_ARRAY_TYPE(Complex);
DEFINE_ARRAY_TYPE(DComplex);
DEFINE_ARRAY_TYPE(String);

#define DEFINE_VECTOR_TYPE(ElType) \
ParameterAccessor< Vector< ElType > > *makeAccessor( \
                    Vector< ElType > *, \
		    const String &name, \
		    ParameterSet::Direction direction, \
		    GlishRecord *values) \
{ \
    return new VectorParameterAccessor<ElType>(name, direction, values); \
} \
 \
const String &typeName(Vector< ElType > *) \
{  \
    static String name; \
    if (name.length() == 0) { \
	name = String("Vector") + "<"; \
        DataType type = whatType(static_cast<ElType *>(0)); \
	ostringstream os; \
	os << type; \
	name += String(os) + ">"; \
    } \
    return name; \
}

DEFINE_VECTOR_TYPE(Bool);
DEFINE_VECTOR_TYPE(Int);
DEFINE_VECTOR_TYPE(Float);
DEFINE_VECTOR_TYPE(Double);
DEFINE_VECTOR_TYPE(Complex);
DEFINE_VECTOR_TYPE(DComplex);
DEFINE_VECTOR_TYPE(String);

ParameterAccessor<Index> *makeAccessor(Index *,
				       const String &name,
				       ParameterSet::Direction direction,
				       GlishRecord *values)
{
    return new IndexParameterAccessor(name, direction, values);
}

const String &typeName(Index *)
{
    static String name = "Index";
    return name;
}

ParameterAccessor< Vector<Index> > *makeAccessor( Vector<Index>  *,
				       const String &name,
				       ParameterSet::Direction direction,
				       GlishRecord *values)
{
    return  new IndexVectorParameterAccessor(name, direction, values);
}

const String &typeName( Vector<Index> *)
{
    static String name = "Vector<Index>";
    return name;
}

const String &typeName(GlishValue *)
{
    static String name = "GlishValue";
    return name;
}

ParameterAccessor<GlishArray> *makeAccessor(GlishArray *,
				       const String &name,
				       ParameterSet::Direction direction,
				       GlishRecord *values)
{
    return new GlishArrayParameterAccessor(name, direction, values);
}

const String &typeName(GlishArray *)
{
    static String name = "GlishArray";
    return name;
}

ParameterAccessor<GlishRecord> *makeAccessor(GlishRecord *,
				       const String &name,
				       ParameterSet::Direction direction,
				       GlishRecord *values)
{
    return new GlishRecordParameterAccessor(name, direction, values);
}

const String &typeName(GlishRecord *)
{
    static String name = "GlishRecord";
    return name;
}

ParameterAccessor<ObjectID> *makeAccessor(ObjectID *,
				       const String &name,
				       ParameterSet::Direction direction,
				       GlishRecord *values)
{
    return new ObjectIDParameterAccessor(name, direction, values);
}

const String &typeName(ObjectID *)
{
    static String name = "ObjectID";
    return name;
}


} //# NAMESPACE CASA - END

