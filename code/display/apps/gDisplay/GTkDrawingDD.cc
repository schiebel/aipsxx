//# GTkDrawingDD.cc: GlishTk interface to the DrawingDisplayData class
//# Copyright (C) 1999,2000,2001,2002
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
//# $Id: GTkDrawingDD.cc,v 19.4 2005/06/15 18:09:12 cvsmgr Exp $

#include <casa/aips.h>
#include <tasking/Glish/GlishValue.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Arrays/IPosition.h>
#include <display/DisplayDatas/DrawingDisplayData.h>
#include "GTkDrawingDD.h"
#include "gDisplay.h"

namespace casa {

GTkDrawingDD::GTkDrawingDD(ProxyStore *s) :
  GTkDisplayProxy(s, 0),
  DrawingDisplayData(),
  itsIsValid(0) {

  agent_ID = "<non-graphic:drawingdisplaydata>";

  procs.Insert("add", new TkDisplayProc(this, &GTkDrawingDD::add));
  procs.Insert("delete", new TkDisplayProc(this, &GTkDrawingDD::remove));
  procs.Insert("remove", new TkDisplayProc(this, &GTkDrawingDD::remove));

  procs.Insert("description", 
	       new TkDisplayProc(this, &GTkDrawingDD::w_description));
  procs.Insert("setdescription", 
	       new TkDisplayProc(this, &GTkDrawingDD::setdescription));

  itsIsValid = 1;
}

extern "C" void GTkDrawingDD_Create(ProxyStore *global_store, Value *args) {
  try {
    // a handle for the agent we will build
    GTkDrawingDD *ret;

    // check for number of arguments
    if (args->Length() != 0) {
      global_store->Error("too many arguments to drawingdisplaydata agent");
      return;
    }

    // make the agent
    ret = new GTkDrawingDD(global_store);

    if (!ret || !ret->IsValid()) {
      Value *err = ret ? ret->GetError() : 0;
      if (err) {
	global_store->Error(err);
      } else {
	global_store->Error("drawingdisplaydata agent creation failed for "
			    "unknown reason/s");
      }
    } else {
      ret->SendCtor("newtk");
    }
  } catch (const AipsError &x) {
    String message = 
      String("drawingdisplaydata agent creation failed for internal "
	     "reason: ") + x.getMesg();
    global_store->Error(message.chars());
  } 
}

GTkDrawingDD::~GTkDrawingDD() {
}

int GTkDrawingDD::IsValid() const {
  return itsIsValid;
}

char *GTkDrawingDD::add(Value *args) {
  static LogOrigin origin("GTkDrawingDD", "add");
  try {
    if (args->Type() != TYPE_RECORD) {
      postError(origin, "Argument to \"drawingdisplaydata->add\" was not "
		"a record", LogMessage::WARN);
      return "";
    }
    GlishValue val(args);
    GlishRecord grec = val;
    Record rec;
    grec.toRecord(rec);
    addObject(rec);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkDrawingDD::remove(Value *args) {
  static LogOrigin origin("GTkDrawingDD", "remove");
  try {
    if (args->Length() > 1) {
      postError(origin, "Too many arguments to \"drawingdisplaydata->remove\" "
		"(must be one)", LogMessage::WARN);
      return "";
    }
    Value *idargs = args;
    if (!idargs->IsNumeric()) {
      postError(origin, "Argument to \"drawingdisplaydata->remove\" was not "
		"an integer", LogMessage::WARN);
      return "";
    }
    int is_copy;
    int idvec[1];
    idargs->CoerceToIntArray(is_copy, 1, idvec);
    removeObject(idvec[0]);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkDrawingDD::w_description(Value *args) {
  static LogOrigin origin("GTkDrawingDD", "description");
  try {
    if (args->Length() > 1) {
      postError(origin, "Too many arguments to \"drawingdisplaydata->"
		"description\" (must be one)", LogMessage::WARN);
      return "";
    }
    Value *idargs = args;
    if (!idargs->IsNumeric()) {
      postError(origin, "Argument to \"drawingdisplaydata->description\" "
		"was not an integer", LogMessage::WARN);
      return "";
    }
    int is_copy;
    int idvec[1];
    idargs->CoerceToIntArray(is_copy, 1, idvec);
    Int objectID = idvec[0];
    Record rec = description(objectID);
    GlishRecord grec;
    grec.fromRecord(rec);
    Value *retval = new Value(*(grec.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("description", retval);
    }
    // delete retval;
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkDrawingDD::setdescription(Value *args) {
  static LogOrigin origin("GTkDrawingDD", "setdescription");
  try {
    GlishValue val(args);
    if (val.type() != GlishValue::RECORD) {
      postError(origin, "Argument to \"drawingdisplaydata->"
		"setdescription\" was not a record", LogMessage::WARN);
      return "";
    }
    GlishRecord grec(val);
    Record rec;
    grec.toRecord(rec);
    if (!rec.isDefined("id")) {
      postError(origin, "Argument to \"drawingdisplaydata->"
		"setdescription lacks an \"id\" field", LogMessage::WARN);
      return "";
    }
    Int objectID;
    rec.get("id", objectID);
    setDescription(objectID, rec);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

void GTkDrawingDD::doubleClick(const Int objectID) {
  static LogOrigin origin("GTkDrawingDD", "doubleClick");
  try {
    GlishRecord rec;
    rec.add("id", GlishArray(objectID));
    Value *retval = new Value(*(rec.value()));
    if (ReplyPending()) {
      // shouldn't be the case, but just in case...
      Reply(retval);
    } else {
      PostTkEvent("objectready", retval);
    }
    // mayby Reply and PostTkEvent actually delete retval for me...
    // delete retval;
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
}

}
