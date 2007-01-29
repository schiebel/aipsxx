//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1998,2000
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
//# $Id: IndexParameterAccessor.h,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#ifndef TASKING_INDEXPARAMETERACCESSOR_H
#define TASKING_INDEXPARAMETERACCESSOR_H

#include <casa/aips.h>
#include <tasking/Tasking/ParameterAccessor.h>
#include <tasking/Tasking/Index.h>
#include <casa/Arrays/Vector.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// Facilitates access to Index parameters by AIPS++ ApplicationObjects
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


class IndexParameterAccessor : public ParameterAccessor<Index>
{
public:
    IndexParameterAccessor(const String &name, 
			    ParameterSet::Direction direction,
			    GlishRecord *values);
    ~IndexParameterAccessor();

    // We need to attach it to the worker as well.
    virtual void attach(GlishRecord *values);
    virtual Bool fromRecord(String &error);
    virtual Bool toRecord(String &error) const;
private:
    ParameterAccessor<Int> *worker_p;
    IndexParameterAccessor();
};

// <summary>
// Facilitates access to Index Vector parameters by AIPS++ ApplicationObjects
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

class IndexVectorParameterAccessor : public ParameterAccessor< Vector<Index> >
{
public:
    IndexVectorParameterAccessor(const String &name, 
			 ParameterSet::Direction direction,
			 GlishRecord *values);
    ~IndexVectorParameterAccessor();

    // We need to attach it to the worker as well.
    virtual void attach(GlishRecord *values);
    virtual Bool fromRecord(String &error);
    virtual Bool toRecord(String &error) const;
private:
    ParameterAccessor< Vector<Int> > *worker_p;
    IndexVectorParameterAccessor();
};


} //# NAMESPACE CASA - END

#endif
