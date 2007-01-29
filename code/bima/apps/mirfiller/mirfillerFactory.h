//# imageFactory.h: this defines imageFactory.h
//# Copyright (C) 1996,1997,1999,2001
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
//# $Id: mirfillerFactory.h,v 19.3 2004/11/30 17:50:11 ddebonis Exp $


#ifndef BIMA_MIRFILLERFACTORY_H
#define BIMA_MIRFILLERFACTORY_H

#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class String;
} //# NAMESPACE CASA - END


// <summary> 
//  This is the factory which makes an object of the mirfiller DO
// </summary>

// <use visibility=local>   

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class="DOmirfiller">DOmirfiller</linkto>
// </prerequisite>
//
// <etymology>
// This is the factory for the mirfiller DO
// </etymology>
//
// <synopsis>
// The factory provides support for passing the input Miriad dataset name
// to the DOmirfiller constructor.  
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// There are no constructors in Glish.  Some means must be found
// to invoke C++ constructors from Glish.  The factory does that.
// </motivation>
//
// <thrown>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
// </todo>
class mirfillerFactory : public ApplicationObjectFactory {

    // Make the mirfiller object
    virtual MethodResult make(ApplicationObject *&newObject,
			      const String &whichConstructor,
			      ParameterSet &inputRecord,
			      Bool runConstructor);
};


#endif

