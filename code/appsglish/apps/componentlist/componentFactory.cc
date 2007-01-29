//# componentFactory.cc:
//# Copyright (C) 1997,1998,1999,2001
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
//# $Id: componentFactory.cc,v 19.5 2005/11/07 21:17:03 wyoung Exp $

#include <../componentlist/componentFactory.h>
#include <casa/BasicSL/String.h>
#include <tables/Tables/Table.h>
#include <appsglish/componentlist/DOcomponentlist.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/ParameterSet.h>
#include <tasking/Tasking/Parameter.h>

#include <casa/namespace.h>
MethodResult componentFactory::make(ApplicationObject* & newObject,
				    const String & whichConstructor,
				    ParameterSet & parameters,
				    Bool makeObject) {
  MethodResult returnValue;
  newObject = 0;

  if (whichConstructor == "emptycomponentlist") {
    if (makeObject)
      newObject = new ::componentlist;
  } 
  else if (whichConstructor == "readcomponentlist") {
    Parameter<String> filename(parameters, "filename", ParameterSet::In);
    Parameter<Bool> readonly(parameters, "readonly", ParameterSet::In);
    if (makeObject) {
      const String& file = filename();
      if (!Table::isReadable(file)) {
	const String errorMsg = "The specified componentlist table (" + file + 
	  ") is unreadable.\n" + 
	  "Perhaps it does not exist.\n" + 
	  "Cannot create the componentlist tool";
	return MethodResult(errorMsg);
      }
      const Bool ro =  readonly();
      if (ro == False && !Table::isWritable(file)) {
	const String errorMsg = "The specified componentlist table (" + file + 
	  ") is not writable.\n" + 
	  "Perhaps the file permissions are incorrect.\n" +
	  "Cannot create the componentlist tool";
	return MethodResult(errorMsg);
      }
      newObject = new ::componentlist(file, ro);
    }
  } 
  else {
    returnValue = String("'") + whichConstructor + 
      String("' is an unknown constructor");
  }
  
  if (returnValue.ok() == True && makeObject == True && newObject == 0)
    returnValue = "Insufficient memory to make a componentlist object";

  return returnValue;
};

// Local Variables: 
// compile-command: "gmake OPTLIB=1 componentFactory.o"
// End: 
