//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,1998
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
//# $Id: ParameterImpl5.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ParameterImpl.h>
#include <tasking/Tasking/ForeignParameterAccessor.h>
#include <tasking/Tasking/ForeignArrayParameterAccessor.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MFrequency.h>
#include <measures/Measures/MDoppler.h>
#include <measures/Measures/MRadialVelocity.h>
#include <measures/Measures/MBaseline.h>
#include <measures/Measures/Muvw.h>
#include <measures/Measures/MEarthMagnetic.h>

namespace casa { //# NAMESPACE CASA - BEGIN

ParameterAccessor<MeasureHolder> * makeAccessor(MeasureHolder *,
						const String &name,
						ParameterSet::Direction direction,
						GlishRecord *values) {
  return new ForeignParameterAccessor<MeasureHolder>(name,
						     direction, values);
}

const String & typeName(MeasureHolder *) {
  static String name = "MeasureHolder";
  return name;
}

ParameterAccessor<Vector<MeasureHolder> > 
*makeAccessor(Vector<MeasureHolder> *,
	      const String &name,
	      ParameterSet::Direction direction,
	      GlishRecord *values) {
  return new ForeignVectorParameterAccessor<MeasureHolder>(name,
							   direction, values);
}

const String & typeName(Vector<MeasureHolder> *) {
  static String name = "Vector<MeasureHolder>";
  return name;
}

ParameterAccessor<Array<MeasureHolder> > 
*makeAccessor(Array<MeasureHolder> *,
	      const String &name,
	      ParameterSet::Direction direction,
	      GlishRecord *values) {
  return new ForeignArrayParameterAccessor<MeasureHolder>(name,
							  direction, values);
}

const String & typeName(Array<MeasureHolder> *) {
  static String name = "Array<MeasureHolder>";
  return name;
}

#define MAKE_STRING(x) # x
#define DEFINE_MEASURE_TYPE(Type) \
ParameterAccessor<Type> *makeAccessor( \
                    Type *, \
		    const String &name, \
		    ParameterSet::Direction direction, \
		    GlishRecord *values) \
{ \
    return new ForeignNSParameterAccessor<Type>(name, direction, values); \
} \
 \
const String &typeName(Type *) \
{  \
    static String name = MAKE_STRING(Type); \
    return name; \
}

DEFINE_MEASURE_TYPE(MEpoch);
DEFINE_MEASURE_TYPE(MDirection);
DEFINE_MEASURE_TYPE(MPosition);
DEFINE_MEASURE_TYPE(MFrequency);
DEFINE_MEASURE_TYPE(MDoppler);
DEFINE_MEASURE_TYPE(MBaseline);
DEFINE_MEASURE_TYPE(Muvw);
DEFINE_MEASURE_TYPE(MEarthMagnetic);
DEFINE_MEASURE_TYPE(MRadialVelocity);

#undef MAKE_STRING
#undef DEFINE_MEASURE_TYPE

} //# NAMESPACE CASA - END

