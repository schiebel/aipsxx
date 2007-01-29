//# Foreign3ParameterAccessor.cc : Implement Measures conversions
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
//# $Id: Foreign3ParameterAccessor.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ForeignParameterAccessor.h>
#include <tasking/Glish/GlishRecord.h>
#include <casa/Containers/Record.h>
#include <casa/BasicSL/String.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MDoppler.h>
#include <measures/Measures/MFrequency.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MRadialVelocity.h>
#include <measures/Measures/MBaseline.h>
#include <measures/Measures/Muvw.h>
#include <measures/Measures/MEarthMagnetic.h>
#include <measures/Measures/MeasureHolder.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//Macro for easy addition of Measures
#define DEFINE_MEASURE_NONSTAND(TMPL, Type, Func, Res) \
template < > \
Bool ForeignFromParameterAccessor TMPL (String &error, \
				  Type &out, \
				  const GlishRecord &record) { \
  MeasureHolder x; \
  Record rec; \
  record.toRecord (rec); \
  if (!x.fromRecord(error, rec)) return False; \
  if (!x.Func()) { \
    error += String("Illegal Measure type asked"); \
    return False; \
  }; \
  out = x.Res(); \
  return True; \
} \
 \
template < > \
Bool ForeignStringParameterAccessor TMPL (String &error, \
				    Type &out, \
				    const String &record) { \
  MeasureHolder x; \
  if (!x.fromString(error, record)) return False; \
  if (!x.Func()) { \
    error += String("Illegal Measure type asked"); \
    return False; \
  }; \
  out = x.Res(); \
  return True; \
} \
 \
template < > \
Bool ForeignToParameterAccessor TMPL (String &error, \
				GlishRecord &record, \
				const Type &in) { \
  MeasureHolder x(in); \
  Record rec; \
  if (! x.toRecord(error, rec)) return False; \
  record.fromRecord (rec); \
  return True; \
}\
 \
template < > \
const String &ForeignIdParameterAccessor TMPL (const Type &) { \
  MeasureHolder x; \
  return x.ident(); \
}


DEFINE_MEASURE_NONSTAND(<MEpoch>, MEpoch, isMEpoch, asMEpoch);
DEFINE_MEASURE_NONSTAND(<MDoppler>, MDoppler, isMDoppler, asMDoppler);
DEFINE_MEASURE_NONSTAND(<MDirection>, MDirection, isMDirection, asMDirection);
DEFINE_MEASURE_NONSTAND(<MFrequency>, MFrequency, isMFrequency, asMFrequency);
DEFINE_MEASURE_NONSTAND(<MPosition>, MPosition, isMPosition, asMPosition);
DEFINE_MEASURE_NONSTAND(<MRadialVelocity>, MRadialVelocity, isMRadialVelocity, asMRadialVelocity);
DEFINE_MEASURE_NONSTAND(<MBaseline>, MBaseline, isMBaseline, asMBaseline);
DEFINE_MEASURE_NONSTAND(<Muvw>, Muvw, isMuvw, asMuvw);
DEFINE_MEASURE_NONSTAND(<MEarthMagnetic>, MEarthMagnetic, isMEarthMagnetic, asMEarthMagnetic);

} //# NAMESPACE CASA - END

