//# GTkGWCAnimator.cc: GlishTk implementation of the GWCAnimator
//# Copyright (C) 2000,2001,2002,2003
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
//# $Id: GTkMWCAnimator.cc,v 19.5 2005/06/15 18:09:12 cvsmgr Exp $

#include <casa/aips.h>
#include <tasking/Glish/GlishValue.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Arrays/IPosition.h>
#include <display/DisplayEvents/MWCAnimator.h>
#include <display/Display/PanelDisplay.h>
#include "GTkPanelDisplay.h"
#include "GTkMWCAnimator.h"
#include "Glish/Reporter.h"
#include "gDisplay.h"

namespace casa {

GTkMWCAnimator::GTkMWCAnimator(ProxyStore *s) :
  GTkDisplayProxy(s, 0),
  itsMWCAnimator(0),
  itsIsValid(0) {

  agent_ID = "<non-graphic:MWCAnimator>";

  itsMWCAnimator = new MWCAnimator;
  
  procs.Insert("add", new TkDisplayProc(this, &GTkMWCAnimator::add));
  procs.Insert("remove", new TkDisplayProc(this, &GTkMWCAnimator::remove));
  procs.Insert("setlinearrestriction",
	       new TkDisplayProc(this, &GTkMWCAnimator::setlinearrestriction));
  procs.Insert("removerestriction",
	       new TkDisplayProc(this, &GTkMWCAnimator::removerestriction));

  itsIsValid = 1;
}

extern "C" void GTkMWCAnimator_Create(ProxyStore *global_store, Value *args) {
  try {
    // a handle for the agent we will build
    GTkMWCAnimator *ret;

    // check for number of arguments
    if (args->Length() != 0) {
      global_store->Error("too many arguments to MWCAnimator agent");
      return;
    }

    // make the agent
    ret = new GTkMWCAnimator(global_store);

    if (!ret || !ret->IsValid()) {
      Value *err = ret ? ret->GetError() : 0;
      if (err) {
	global_store->Error(err);
      } else {
	global_store->Error("MWCAnimator agent creation failed for "
			    "unknown reason/s");
      }
    } else {
      ret->SendCtor("newtk");
    }
  } catch (const AipsError &x) {
    String message = 
      String("MWCAnimator agent creation failed for internal reason: ") +
      x.getMesg();
    global_store->Error(message.chars());
  } 
}

GTkMWCAnimator::~GTkMWCAnimator() {
  if (itsMWCAnimator) {
    delete itsMWCAnimator;
  }
}

int GTkMWCAnimator::IsValid() const {
  return itsIsValid;
}

char *GTkMWCAnimator::add(Value *args) {
  static LogOrigin origin("GTkMWCAnimator", "add");
  try {
    if (args->Type() != TYPE_RECORD) {
      postError(origin, "Argument to \"animator->add\" was not "
		"a record", LogMessage::WARN);
      return "";
    }

    GlishValue val(args);
    GlishRecord rec = val;
    GlishRecord nrec;
    nrec.add(rec.name(0), rec.get(0));
    TkProxy *agent = (TkProxy *)(global_store->GetProxy(rec.value()));
  
    // check it is a [non-]graphic:paneldisplay
    if (agent && (!strcmp(agent->AgentID(), "<graphic:paneldisplay>") ||
		  !strcmp(agent->AgentID(), "<non-graphic:paneldisplay>"))) {
      PanelDisplay *pd = ((GTkPanelDisplay *)agent)->panelDisplay();
      itsMWCAnimator->addMWCHolder(*pd);
    } else {
      postError(origin, "Argument to \"animator->add\" was not "
		"a paneldisplay agent", LogMessage::WARN);
      return "";
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkMWCAnimator::remove(Value *args) {
  static LogOrigin origin("GTkMWCAnimator", "remove");
  try {
    if (args->Type() != TYPE_RECORD) {
      postError(origin, "Argument to \"animator->remove\" was not "
		"a record", LogMessage::WARN);
      return "";
    }

    GlishValue val(args);
    GlishRecord rec = val;
    GlishRecord nrec;
    nrec.add(rec.name(0), rec.get(0));
    TkProxy *agent = (TkProxy *)(global_store->GetProxy(rec.value()));
  
    // check it is a [non-]graphic:paneldisplay
    if (agent && (!strcmp(agent->AgentID(), "<graphic:paneldisplay>") ||
		  !strcmp(agent->AgentID(), "<non-graphic:paneldisplay>"))) {
      PanelDisplay *pd = ((GTkPanelDisplay *)agent)->panelDisplay();
      itsMWCAnimator->removeMWCHolder(*pd);
    } else {
      postError(origin, "Argument to \"animator->remove\" was not "
		"a paneldisplay agent", LogMessage::WARN);
      return "";
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkMWCAnimator::setlinearrestriction(Value *args) {
  static LogOrigin origin("GTkMWCAnimator", "setlinearrestriction");
  try {
    GlishValue val(args);
    if (val.type() != GlishValue::RECORD) {
      postError(origin, "Argument to \"animator->setlinearrestriction\" "
		"was not a record", LogMessage::WARN);
      return "";
    }
    GlishRecord grec(args);
    Record rec;
    grec.toRecord(rec);
    itsMWCAnimator->setLinearRestriction(rec);
    if (!ReplyPending()) {
      Value *retval = new Value(True);
      PostTkEvent("idle", retval);
      delete retval;
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkMWCAnimator::removerestriction(Value *args) {
  static LogOrigin origin("GTkMWCAnimator", "removerestriction");
  try {
    if ((args->Type() != TYPE_STRING) || (args->Length() != 1)) {
      postError(origin, "Argument to \"animator->removerestriction\" "
		"was not a single string", LogMessage::WARN);
    }
    Ref(args);
    String name = args->StringVal();

    itsMWCAnimator->removeRestriction(name);

    if (!ReplyPending()) {
      Value *retval = new Value(True);
      PostTkEvent("idle", retval);
      delete retval;
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  }
  return "";
}

}
