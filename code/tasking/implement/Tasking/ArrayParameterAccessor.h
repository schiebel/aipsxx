//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,2000
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
//# $Id: ArrayParameterAccessor.h,v 19.6 2005/06/18 21:19:18 ddebonis Exp $

#ifndef TASKING_ARRAYPARAMETERACCESSOR_H
#define TASKING_ARRAYPARAMETERACCESSOR_H

#include <casa/aips.h>
#include <tasking/Tasking/ParameterAccessor.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Vector.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// Facilitates access to array parameters by AIPS++ ApplicationObjects
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


// T is the pixel type
template<class T> class ArrayParameterAccessor : 
    public ParameterAccessor< Array<T> >
{
public:
    ArrayParameterAccessor(const String &name, 
			   ParameterSet::Direction direction,
			   GlishRecord *values);

    virtual Bool fromRecord(String &error);
    virtual Bool toRecord(String &error) const;
    virtual void reset();
private:
    ArrayParameterAccessor();

    //# Make template-independent parent members known
public:
    using ParameterAccessor< Array<T> >::name;
    using ParameterAccessor< Array<T> >::operator();
protected:
    using ParameterAccessor< Array<T> >::values_p;
    using ParameterAccessor< Array<T> >::value_p;
};

// <summary>
// Facilitates access to vector parameters by AIPS++ ApplicationObjects
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

template<class T> class VectorParameterAccessor : 
    public ParameterAccessor< Vector<T> >
{
public:
    VectorParameterAccessor(const String &name, 
			    ParameterSet::Direction direction,
			    GlishRecord *values);

    virtual Bool fromRecord(String &error);
    virtual Bool toRecord(String &error) const;
    virtual void reset();
private:
    VectorParameterAccessor();

    //# Make template-independent parent members known
public:
    using ParameterAccessor< Vector<T> >::name;
    using ParameterAccessor< Vector<T> >::operator();
protected:
    using ParameterAccessor< Vector<T> >::values_p;
    using ParameterAccessor< Vector<T> >::value_p;
};


} //# NAMESPACE CASA - END

#ifndef AIPS_NO_TEMPLATE_SRC
#include <tasking/Tasking/ArrayParameterAccessor.cc>
#endif //# AIPS_NO_TEMPLATE_SRC
#endif
