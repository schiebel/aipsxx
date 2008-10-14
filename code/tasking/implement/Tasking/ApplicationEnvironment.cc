//# ApplicationEnvironment.cc: this defines ApplicationEnvironment
//# Copyright (C) 1996,1997,2000,2001,2002
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
//# $Id: ApplicationEnvironment.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ApplicationEnvironment.h>
#include <tasking/Tasking/ObjectController.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>
#include <casa/System/Aipsrc.h>

#include <casa/Logging/LogIO.h>
#include <casa/Logging/LogSink.h>

#include <casa/Utilities/Assert.h>

#include <casa/stdlib.h>

namespace casa { //# NAMESPACE CASA - BEGIN

ObjectController *ApplicationEnvironment::the_controller_p = 0;


Bool ApplicationEnvironment::isInteractive()
{
    return True;
}

Bool ApplicationEnvironment::stop()
{
  ObjectController* controller = objectController();
  if (isInteractive() == True && controller != 0) {
    return controller->stop();
  } else {
    return False;
  }
}

Bool ApplicationEnvironment::hasGUI()
{
  ObjectController* controller = objectController();
  if (isInteractive() == True && controller != 0) {
    return controller->hasGUI();
  } else {
    return False;
  }
}

String ApplicationEnvironment::choice(const String &descriptiveText,
				      const Vector<String> &choices)
{
  LogIO log(LogOrigin("ApplicationEnvironment",
		      "choice(const String &descriptiveText,"
		      "const Vector<String> &choices)", WHERE));

    String retval;
    if (choices.nelements() > 0) {
	ObjectController *controller = objectController();
	if (isInteractive()==False || controller==0) {
	    retval = choices(0);
	} else {
	    retval = controller->choice(descriptiveText, choices);
	}
    }

    log << WHERE << LogIO::NORMAL << "Got choice " << retval <<
      " for question " << descriptiveText << LogIO::POST;

    return retval;
}

Bool ApplicationEnvironment::view(String &table)
{
  LogIO log(LogOrigin("ApplicationEnvironment",
		      "view(String &table)", WHERE));

    Bool retval;
    ObjectController *controller = objectController();
    if (isInteractive()==False || controller==0) {
      retval = False;
    } else {
      retval = controller->view(table);
    }

    return retval;
}

Int ApplicationEnvironment::makeProgressDisplay(Double min, Double max, 
					const String &title, const String &subtitle,
					const String &minlabel, const String &maxlabel, 
					Bool estimateTime)
{
    if (!isInteractive()) {
	return -1;
    }
    ObjectController *controller = objectController();
    if (controller == 0) {
	return -1;
    }

    return controller->makeProgressDisplay(min, max, title, subtitle,
					   minlabel, maxlabel, estimateTime);
}

void ApplicationEnvironment::updateProgressDisplay(Int id, Double value)
{
    if (!isInteractive() || id <= 0) {
	return;
    }
    ObjectController *controller = objectController();
    if (controller == 0) {
	return;
    }

    controller->updateProgressDisplay(id, value);
}

} //# NAMESPACE CASA - END

