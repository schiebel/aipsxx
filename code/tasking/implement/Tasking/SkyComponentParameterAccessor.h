//# SkyComponentParameterAccessor.h
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
//# $Id: SkyComponentParameterAccessor.h,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#ifndef TASKING_SKYCOMPONENTPARAMETERACCESSOR_H
#define TASKING_SKYCOMPONENTPARAMETERACCESSOR_H

#include <casa/aips.h>
#include <tasking/Tasking/ParameterAccessor.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class SkyComponent;
class GlishRecord;
class ParameterSet;
class String;

// <summary></summary>

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


class SkyComponentParameterAccessor 
  :public ParameterAccessor<SkyComponent>
{
public:
  SkyComponentParameterAccessor(const String & name,
				ParameterSet::Direction direction,
				GlishRecord * values);
  ~SkyComponentParameterAccessor();
  
  virtual Bool fromRecord(String & error);
  virtual Bool toRecord(String & error) const;
private:
  SkyComponentParameterAccessor();
};


} //# NAMESPACE CASA - END

#endif

