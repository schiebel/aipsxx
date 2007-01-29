//# hdsFactory.cc:
//# Copyright (C) 1998,1999,2000
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
//# $Id: hdsFactory.cc,v 19.4 2005/06/15 13:40:17 cvsmgr Exp $
#if defined(HAVE_HDS)
#include <hdsFactory.h>
#include <casa/BasicSL/String.h>
#include <npoi/HDS/DOhdsfile.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/ParameterSet.h>
#include <tasking/Tasking/Parameter.h>

#include <casa/namespace.h>
MethodResult hdsFactory::make(ApplicationObject*& newObject,
			      const String& whichConstructor,
			      ParameterSet& parameters,
			      Bool makeObject) {
  MethodResult returnValue;
  newObject = 0;

  if (whichConstructor == "hdsfile") {
    Parameter<String> filename(parameters, "filename", ParameterSet::In);
    Parameter<Bool> readonly(parameters, "readonly", ParameterSet::In);
    if (makeObject) {
      newObject = new hdsfile(filename(), readonly());
    }
  } 
  else {
    returnValue = String("'") + whichConstructor + 
      String("' is an unknown constructor");
  }
  
  if (returnValue.ok() == True && makeObject == True && newObject == 0)
    returnValue = "Insufficient memory to make a hdsfile object";

  return returnValue;
};
#endif
// Local Variables: 
// compile-command: "gmake hdsFactory.o"
// End: 
