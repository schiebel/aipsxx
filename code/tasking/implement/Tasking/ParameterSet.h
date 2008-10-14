//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1999
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
//# $Id: ParameterSet.h,v 19.5 2004/11/30 17:51:11 ddebonis Exp $

#ifndef TASKING_PARAMETERSET_H
#define TASKING_PARAMETERSET_H


//# Includes
#include <casa/aips.h>
#include <casa/Containers/SimOrdMap.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/CountedPtr.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward Declarations
class ParameterAccessorBase;
class GlishRecord;
class ParameterSetBreaker;


// <summary>
// </summary>

// <use visibility=local>   or   <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
//   <li> SomeOtherClass
//   <li> some concept
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <templating arg=T>
//    <li>
//    <li>
// </templating>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>

class ParameterSet
{
public:
    enum Direction {In, Out, InOut};
    ParameterSet();
    ~ParameterSet();

    // relatively expensive - call infrequently. non-const because it calls
    // reset on the accessors to free up storage, etc.
    const CountedPtr<GlishRecord>& parameterRecord(Bool &error,
						   String &errorMsg);
    void setParameterRecord(const GlishRecord &rec, Bool &error, 
			    String &errorMsg);
    void setParameterRecord(GlishRecord *&fromNew, Bool &error,
			    String &errorMsg);

    // Do not delete this pointer
    ParameterAccessorBase *accessor(const String &which);
    // Takes over val - do not delete it
    void setAccessor(const String &which, ParameterAccessorBase *&val);

    Bool doSetup() const;
    void doSetup(Bool newval);

    // Return a pointer to the values (used by the accessor classes).
    GlishRecord *values();

private:
    ParameterAccessorBase *accessor(Int which);
    const ParameterAccessorBase *accessor(Int which) const;

    void createOutputRecord(GlishRecord &outputRecord);

    CountedPtr<GlishRecord> values_p;
    SimpleOrderedMap<String, void *> accessors_p;
    Bool do_setup_p;

    // Implements dtor
    void clear();

    // Undefined and inaccessible
    ParameterSet(const ParameterSet &other);
    ParameterSet &operator=(const ParameterSet &other);
};


//# inlines 
inline GlishRecord *ParameterSet::values()
{
    return values_p.operator->();
}

inline ParameterAccessorBase *ParameterSet::accessor(Int which)
{
    return (ParameterAccessorBase *)accessors_p.getVal(which);
}

inline const ParameterAccessorBase *ParameterSet::accessor(Int which) const
{
    return (const ParameterAccessorBase *)accessors_p.getVal(which);
}

inline Bool ParameterSet::doSetup() const
{
    return do_setup_p;
}

inline void ParameterSet::doSetup(Bool newval)
{
    do_setup_p = newval;
}


} //# NAMESPACE CASA - END

#endif
