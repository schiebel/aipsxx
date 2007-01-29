//# GTkColormap.cc: GlishTk implementation of the Colormap class
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
//# $Id: GTkColormap.cc,v 19.4 2005/06/15 18:09:12 cvsmgr Exp $

#include <casa/aips.h>
#include <tasking/Glish/GlishValue.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Arrays/IPosition.h>
#include "GTkPixelCanvas.h"
#include <display/Display/Colormap.h>
#include <display/DisplayDatas/LatticeAsRaster.h>
#include "GTkColormap.h"

#include "Glish/Reporter.h"
#include "gDisplay.h"

namespace casa {
GTkColormap::GTkColormap(ProxyStore *s, String name) :
  GTkDisplayProxy(s, 0),
  itsColormap(0),
  itsName(name),
  itsIsValid(0) {

  // set the type of agent
  agent_ID = "<non-graphic:colormap>";
  
  // construct the requested Colormap
  itsColormap = new Colormap(itsName);
  
  // install widget commands
  procs.Insert("setshift", new TkDisplayProc(this, &GTkColormap::setshift));
  procs.Insert("getshift", new TkDisplayProc(this, &GTkColormap::getshift));
  procs.Insert("setslope", new TkDisplayProc(this, &GTkColormap::setslope));
  procs.Insert("getslope", new TkDisplayProc(this, &GTkColormap::getslope));
  procs.Insert("setbrightness", new TkDisplayProc
	       (this, &GTkColormap::setbrightness));
  procs.Insert("getbrightness", new TkDisplayProc
	       (this, &GTkColormap::getbrightness));
  procs.Insert("setcontrast", new TkDisplayProc
	       (this, &GTkColormap::setcontrast));
  procs.Insert("getcontrast", new TkDisplayProc
	       (this, &GTkColormap::getcontrast));
  procs.Insert("setinvertflags", new TkDisplayProc
	       (this, &GTkColormap::setinvertflags));
  procs.Insert("getinvertflags", new TkDisplayProc
	       (this, &GTkColormap::getinvertflags));

  procs.Insert("getoptions", 
	       new TkDisplayProc(this, &GTkColormap::getoptions));
  procs.Insert("setoptions",
	       new TkDisplayProc(this, &GTkColormap::setoptions));

  itsIsValid = 1;
}

extern "C" void GTkColormap_Create(ProxyStore *global_store, Value *args) {
  try {
    // a handle for the agent we will build
    GTkColormap *ret;
    
    // check for number of arguments
    if (args->Length() != 1) {
      global_store->Error("too few arguments to colormap agent");
      return;
    }
    
    // fetch arguments
    if (args->Type() != TYPE_RECORD) {
      global_store->Error("bad argument type to colormap agent");
      return;
    }
    recordptr rptr = args->RecordPtr(0);
    int c = 0;
    const char *key;
    char *name = rptr->NthEntry(c++, key)->StringVal();
    
    // make the agent
    ret = new GTkColormap(global_store, name);
    
    if (!ret || !ret->IsValid()) {
      Value *err = ret ? ret->GetError() : 0;
      if (err) {
	global_store->Error(err);
      } else {
	global_store->Error("colormap agent creation failed for "
			    "unknown reason");
      }
    } else {
      ret->SendCtor("newtk");
    }
  } catch (const AipsError &x) {
    String message = 
      String("colormap agent creation failed:\n") + x.getMesg();
    global_store->Error(message.chars());
  } 
}

GTkColormap::~GTkColormap() {
  if (itsColormap) {
    delete itsColormap;
  }
}

int GTkColormap::IsValid() const {
  return itsIsValid;
}

char *GTkColormap::setshift(Value *args) {
  static LogOrigin origin("GTkColormap", "setshift");
  try {
    throw(AipsError("GTkColormap::setshift no longer available"));
    /*
    GlishValue val(args);
    if (val.type() != GlishValue::ARRAY) {
      postError(origin, "Argument to \"colormap->setshift\" was not "
		"a scalar", LogMessage::WARN);
      return "";
    }
    GlishArray tmp(val);
    Float shift;
    tmp.get(shift);
    itsColormap->setShift(shift);    
    */
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkColormap::getshift(Value *) {
  static LogOrigin origin("GTkColormap", "getshift");
  try {
    throw(AipsError("GTkColormap::getshift no longer available"));
    /*
    GlishArray val(itsColormap->getShift());
    Value *retval = new Value(*(val.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("shift", retval);
    } 
    */ 
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkColormap::setslope(Value *args) {
  static LogOrigin origin("GTkColormap", "setslope");
  try {
    throw(AipsError("GTkColormap::setslope no longer available"));
    /*
    GlishValue val(args);
    if (val.type() != GlishValue::ARRAY) {
      postError(origin, "Argument to \"colormap->setslope\" was not "
		"a scalar", LogMessage::WARN);
      return "";
    }
    GlishArray tmp(val);
    Float slope;
    tmp.get(slope);
    itsColormap->setSlope(slope);    
    */
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkColormap::getslope(Value *) {
  static LogOrigin origin("GTkColormap", "getslope");
  try {
    throw(AipsError("GTkColormap::getslope no longer available"));
    /*
    GlishArray val(itsColormap->getSlope());
    Value *retval = new Value(*(val.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("slope", retval);
    }  
    */
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkColormap::setbrightness(Value *args) {
  static LogOrigin origin("GTkColormap", "setbrightness");
  try {
    GlishValue val(args);
    if (val.type() != GlishValue::ARRAY) {
      postError(origin, "Argument to \"colormap->setbrightness\" was not "
		"a scalar", LogMessage::WARN);
      return "";
    }
    GlishArray tmp(val);
    Float brightness;
    tmp.get(brightness);
    itsColormap->setBrightness(brightness);    
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkColormap::getbrightness(Value *) {
  static LogOrigin origin("GTkColormap", "getbrightness");
  try {
    GlishArray val(itsColormap->getBrightness());
    Value *retval = new Value(*(val.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("brightness", retval);
    }  
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkColormap::setcontrast(Value *args) {
  static LogOrigin origin("GTkColormap", "setcontrast");
  try {
    GlishValue val(args);
    if (val.type() != GlishValue::ARRAY) {
      postError(origin, "Argument to \"colormap->setcontrast\" was not "
		"a scalar", LogMessage::WARN);
      return "";
    }
    GlishArray tmp(val);
    Float contrast;
    tmp.get(contrast);
    itsColormap->setContrast(contrast);    
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkColormap::getcontrast(Value *) {
  static LogOrigin origin("GTkColormap", "getcontrast");
  try {
    GlishArray val(itsColormap->getContrast());
    Value *retval = new Value(*(val.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("contrast", retval);
    }  
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkColormap::setinvertflags(Value *args) {
  static LogOrigin origin("GTkColormap", "setinvertflags");
  try {
    GlishValue val(args);
    if (val.type() != GlishValue::ARRAY) {
      postError(origin, "Argument to \"colormap->setinvertflags\" was not "
		"a scalar or an array", LogMessage::WARN);
      return "";
    }
    GlishArray tmp(val);
    Vector<casa::Bool> flags(3);
    tmp.get(flags);
    itsColormap->setInvertFlags(flags(0), flags(1), flags(2));
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkColormap::getinvertflags(Value *) {
  static LogOrigin origin("GTkColormap", "getinvertflags");
  try {
    Vector<casa::Bool> vec(3);
    itsColormap->getInvertFlags(vec(0), vec(1), vec(2));
    GlishArray val(vec);
    Value *retval = new Value(*(val.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("invertflags", retval);
    }  
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkColormap::getoptions(Value *) {
  static LogOrigin origin("GTkColormap", "getoptions");
  try {
    Record rec;

    Record brightness;
    brightness.define("dlformat", "brightness");
    brightness.define("listname", "Brightness");
    brightness.define("ptype", "floatrange");
    brightness.define("pmin", Float(0.0));
    brightness.define("pmax", Float(1.0));
    brightness.define("default", Float(0.5));
    brightness.define("value", itsColormap->getBrightness());
    brightness.define("allowunset", False);
    rec.defineRecord("brightness", brightness);

    Record contrast;
    contrast.define("dlformat", "contrast");
    contrast.define("listname", "Contrast");
    contrast.define("ptype", "floatrange");
    contrast.define("pmin", Float(0.0));
    contrast.define("pmax", Float(1.0));
    contrast.define("default", Float(0.5));
    contrast.define("value", itsColormap->getContrast());
    contrast.define("allowunset", False);
    rec.defineRecord("contrast", contrast);

    casa::Bool ired, igreen, iblue;
    itsColormap->getInvertFlags(ired, igreen, iblue);
    
    Record invertred;
    invertred.define("dlformat", "invertred");
    invertred.define("listname", "Invert red component?");
    invertred.define("ptype", "boolean");
    invertred.define("default", False);
    invertred.define("value", ired);
    invertred.define("allowunset", False);
    rec.defineRecord("invertred", invertred);

    Record invertgreen;
    invertgreen.define("dlformat", "invertgreen");
    invertgreen.define("listname", "Invert green component?");
    invertgreen.define("ptype", "boolean");
    invertgreen.define("default", False);
    invertgreen.define("value", igreen);
    invertgreen.define("allowunset", False);
    rec.defineRecord("invertgreen", invertgreen);

    Record invertblue;
    invertblue.define("dlformat", "invertblue");
    invertblue.define("listname", "Invert blue component?");
    invertblue.define("ptype", "boolean");
    invertblue.define("default", False);
    invertblue.define("value", iblue);
    invertblue.define("allowunset", False);
    rec.defineRecord("invertblue", invertblue);

    GlishRecord grec;
    grec.fromRecord(rec);
    Value *retval = new Value(*(grec.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("options", retval);
    }
    delete retval;

  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkColormap::setoptions(Value *args) {
  static LogOrigin origin("GTkColormap", "setoptions");
  try {
    GlishValue val(args);
    if (val.type() != GlishValue::RECORD) {
      postError(origin, "Argument to \"colormap->setoptions\" was not "
		"a record", LogMessage::WARN);
      return "";
    }
    GlishRecord grec(val);
    Record rec, recOut;
    grec.toRecord(rec);

    casa::Bool ichange = False, error;
    
    Float brightness = itsColormap->getBrightness();
    casa::Bool cbrightness = readOptionRecord(brightness, error, rec, "brightness");
    Float contrast = itsColormap->getContrast();
    casa::Bool ccontrast = readOptionRecord(contrast, error, rec, "contrast");

    casa::Bool ired, igreen, iblue;
    itsColormap->getInvertFlags(ired, igreen, iblue);
    
    ichange = (readOptionRecord(ired, error, rec, "invertred") ||
		     ichange);
    ichange = (readOptionRecord(igreen, error, rec, "invertgreen") ||
		     ichange);
    ichange = (readOptionRecord(iblue, error, rec, "invertblue") ||
		     ichange);
    
    if (cbrightness) {
      itsColormap->setBrightness(brightness, !(ccontrast || ichange));
    }
    if (ccontrast) {
      itsColormap->setContrast(contrast, !ichange);
    }
    if (ichange) {
      itsColormap->setInvertFlags(ired, igreen, iblue, True);
    }

  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}
}
