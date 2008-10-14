//# <ModuleFileName.h>:  a module for ....
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
//# $Id: Tasking.h,v 19.5 2004/11/30 17:51:10 ddebonis Exp $


#ifndef TASKING_TASKING_H
#define TASKING_TASKING_H

//# Include the "public" parts of the module
#include <tasking/Tasking/ApplicationObject.h>
#include <tasking/Tasking/ApplicationEnvironment.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/ObjectController.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterSet.h>
#include <casa/System/ProgressMeter.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <module>
//
// <summary> The classes implementing the distributed object system. </summary>
//
// <prerequisite>
//#! Modules, classes or concepts you should understand before using this
//#! module
//   <li> SomeModule
//   <li> SomeClass
//   <li> some concept (perhaps with reference)
// </prerequisite>
//

// <reviewed reviewer="" date="yyyy/mm/dd" demos="">
//#!
//#! for example:
//#!  <reviewed reviewer="Paul Shannon, pshannon@nrao.edu" date="1994/10/10" demos="dModuleName.cc, d1ModuleName.cc">
//#!  In the long term, it will probably be useful to add fooBar
//#!  and BarFoo functionality to the classes in this module...
//#!  </reviewed>
//#!
//#! (In time, the documentation extractor will be able handle reviewed
//#! attributes spread over more than one line.)
//#!
//#! See "Coding Standards and Guidelines" AIPS++ note 167 for a full
//#! explanation.
//#!
//#! It is up to the author (the programmer) to fill in these fields:
//#!     tests, demos
//#! The reviewer fills in
//#!     reviewer, date
//#!
// </reviewed>

// <etymology>
// Tasking refers to the running and controlling of tasks, processes performing
// operations.
// </etymology>
//
// <synopsis>
// This module implements the aips++ tasking system that allows glish scripts and
// user interfaces to communicate with C++ executables performing the real work.
// It includes parameter passing and status reporting classes.
// </synopsis>
//
// <example>
// see Note 186 and 197 for a detailed explanation of the tasking system.
// </example>
//
// <motivation>
//#! Insight into a module is often provided by a description of the
//#! circumstances that led to its conception and design.  Describe
//#! them here.
// </motivation>

// <todo asof="yyyy/mm/dd">
//#! A List of bugs, limitations, extensions or planned refinements.
//#! The programmer should fill in a date in the "asof" field, which
//#! will usually be the date at which the class is submitted for review.
//#! If, during the review, new "todo" items come up, then the "asof"
//#! date should be changed to the end of the review period.
//   <li> add this feature
//   <li> fix this bug
//   <li> discuss possible extension
// </todo>

// </module>


} //# NAMESPACE CASA - END

#endif
