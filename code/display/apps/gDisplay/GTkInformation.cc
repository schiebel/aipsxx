//# GTkInformation.cc: provides information to Glish about the display
//# Copyright (C) 2000,2002
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
//# $Id: GTkInformation.cc,v 19.4 2005/06/15 18:09:12 cvsmgr Exp $

#include <casa/aips.h>
#include <tasking/Glish/GlishValue.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <display/Display/ColormapDefinition.h>
#include "GTkInformation.h"
#include "Glish/Reporter.h"
#include "gDisplay.h"

namespace casa {

GTkInformation::GTkInformation(ProxyStore *s) :
  GTkDisplayProxy(s, 0),
  itsIsValid(0) {

  // set the type of agent
  agent_ID = "<non-graphic:information>";
  
  // install widget commands
  procs.Insert("colormapnames", 
	       new TkDisplayProc(this, &GTkInformation::colormapnames));

  // set private state to say we are valid
  itsIsValid = 1;
}

extern "C" void GTkInformation_Create(ProxyStore *global_store, Value *args) {
  try {
    // a handle for the agent we will build
    GTkInformation *ret;
    
    // could insert code to look at arguments, but right now we
    // just ignore any if given.

    // make the agent
    ret = new GTkInformation(global_store);
    
    if (!ret || !ret->IsValid()) {
      Value *err = ret ? ret->GetError() : 0;
      if (err) {
	global_store->Error(err);
      } else {
	global_store->Error("information agent creation failed for "
			    "unknown reason");
      }
    } else {
      ret->SendCtor("newtk");
    }
  } catch (const AipsError &x) {
    String message = 
      String("information agent creation failed:\n") + x.getMesg();
    global_store->Error(message.chars());
  } 
}

GTkInformation::~GTkInformation() {
}

int GTkInformation::IsValid() const {
  return itsIsValid;
}

char *GTkInformation::colormapnames(Value *args) {
  static LogOrigin origin("GTkInformation", "setshift");
  try {
    GlishArray val(ColormapDefinition::builtinColormapNames());
    Value *retval = new Value(*(val.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("colormapnames", retval);
    }
    delete retval;
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

}
