//# imageFactory.h: this defines imageFactory.h
//# Copyright (C) 1996,1997,1999,2000
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
//# $Id: coordsysFactory.h,v 19.4 2004/11/30 17:50:06 ddebonis Exp $


#ifndef APPSGLISH_COORDSYSFACTORY_H
#define APPSGLISH_COORDSYSFACTORY_H


#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <casa/namespace.h>

namespace casa { //# NAMESPACE CASA - BEGIN
class String;
} //# NAMESPACE CASA - END


// <summary> 
//  This is the factory which makes an object of the coordsys DO
// </summary>

// <use visibility=local>   or   <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
// </prerequisite>
//
// <etymology>
//  This is the factory for the image DO
// </etymology>
//
// <synopsis>
// The factory works out which constructor of the image DO to call when
// invoked from Glish (which doesn't have constrcutors)
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// There are no constructors in Glish.  Some means must be found
// to invoke C++ constructors (all of name "image" in this case) from Glish.
// The factory does that.
// </motivation>
//
// <thrown>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
// </todo>


class coordsysFactory : public ApplicationObjectFactory
{
// Make the image object
    virtual MethodResult make(ApplicationObject *&newObject,
			      const String &whichConstructor,
			      ParameterSet &inputRecord,
			      Bool runConstructor);
};


#endif

