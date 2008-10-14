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
//# $Id: GlishValueParameterAccessor.h,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#ifndef TASKING_GLISHVALUEPARAMETERACCESSOR_H
#define TASKING_GLISHVALUEPARAMETERACCESSOR_H

#include <casa/aips.h>
#include <tasking/Tasking/ParameterAccessor.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// Facilitates access to Glish value parameters by AIPS++ ApplicationObjects
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


class GlishValueParameterAccessor : public ParameterAccessor<GlishValue>
{
public:
    GlishValueParameterAccessor(const String &name, 
			    ParameterSet::Direction direction,
			    GlishRecord *values);
    ~GlishValueParameterAccessor();

    virtual Bool fromRecord(String &error);
    virtual Bool toRecord(String &error) const;
private:
    GlishValueParameterAccessor();
};

// <summary>
// Facilitates access to Glish array parameters by AIPS++ ApplicationObjects
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

class GlishArrayParameterAccessor : public ParameterAccessor<GlishArray>
{
public:
    GlishArrayParameterAccessor(const String &name, 
			    ParameterSet::Direction direction,
			    GlishRecord *values);
    ~GlishArrayParameterAccessor();

    virtual Bool fromRecord(String &error);
    virtual Bool toRecord(String &error) const;
private:
    GlishArrayParameterAccessor();
};

// <summary>
// Facilitates access to Glish record parameters by AIPS++ ApplicationObjects
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

class GlishRecordParameterAccessor : public ParameterAccessor<GlishRecord>
{
public:
    GlishRecordParameterAccessor(const String &name, 
			    ParameterSet::Direction direction,
			    GlishRecord *values);
    ~GlishRecordParameterAccessor();

    virtual Bool fromRecord(String &error);
    virtual Bool toRecord(String &error) const;
private:
    GlishRecordParameterAccessor();
};


} //# NAMESPACE CASA - END

#endif
