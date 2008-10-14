//# GTkAnnotations.cc : GlishTk implementation of Annotations
//# Copyright (C) 1998,1999,2000,2001,2002
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
//# $Id: 


#include <casa/aips.h>
#include <tasking/Glish/GlishValue.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <display/DisplayShapes/Annotations.h>

#include "GTkAnnotations.h"
#include "GTkPixelCanvas.h"
#include "GTkPSPixelCanvas.h"
#include "GTkPanelDisplay.h"
#include "gDisplay.h"

#include <casa/Utilities/DataType.h>


namespace casa {
GTkAnnotations::GTkAnnotations(ProxyStore *s, GTkPanelDisplay* panelDisp, 
			       const Display::KeySym &mouse,
			       const casa::Bool& useEH) : 
  GTkDisplayProxy(s),
  Annotations(panelDisp->panelDisplay(), mouse, useEH),
  itsIsValid(0)
  {

    if (!panelDisp) { // || !panelDisp->Self()) {
      throw(AipsError("The Panel Display given to the Annotator "
		      "was invalid"));
    }
    if (!panelDisp->Self() && useEH) {
      throw(AipsError("The Panel Display given to the Annotator "
		      "was invalid (it had no window and event handlers"
		      " were requested."));
    }
    
    agent_ID = "<graphic:annotations>";

    //    procs.Insert("cshape",
    //	 new TkDisplayProc(this, &GTkAnnotations::cshape));
    procs.Insert("newshape", 
		 new TkDisplayProc(this, &GTkAnnotations::newshape));
    procs.Insert("createshape", 
		 new TkDisplayProc(this, &GTkAnnotations::createshape));
    procs.Insert("listshapes", 
		 new TkDisplayProc(this, &GTkAnnotations::listshapes));
    procs.Insert("availableshapes", 
		 new TkDisplayProc(this, &GTkAnnotations::availableshapes));
    procs.Insert("whichshape", 
		 new TkDisplayProc(this, &GTkAnnotations::whichshape));
    procs.Insert("deleteshape", 
		 new TkDisplayProc(this, &GTkAnnotations::deleteshape));
    procs.Insert("getalloptions", 
		 new TkDisplayProc(this, &GTkAnnotations::getalloptions));
    procs.Insert("reverttopix",
		 new TkDisplayProc(this, &GTkAnnotations::reverttopix));
    procs.Insert("reverttofrac",
		 new TkDisplayProc(this, &GTkAnnotations::reverttofrac));
    procs.Insert("locktowc",
		 new TkDisplayProc(this, &GTkAnnotations::locktowc));
    procs.Insert("setalloptions", 
		 new TkDisplayProc(this, &GTkAnnotations::setalloptions));
    procs.Insert("getshapeoptions", 
		 new TkDisplayProc(this, &GTkAnnotations::getshapeoptions));
    procs.Insert("setshapeoptions", 
		 new TkDisplayProc(this, &GTkAnnotations::setshapeoptions));
    procs.Insert("addlockedtocurrent", 
		 new TkDisplayProc(this, &GTkAnnotations::addlockedtocurrent));
    procs.Insert("removelockedfromcurrent", 
		 new TkDisplayProc(this, 
				   &GTkAnnotations::removelockedfromcurrent));
    procs.Insert("setkey",
		 new TkDisplayProc(this, &GTkAnnotations::setkey));
    procs.Insert("cancel", 
		 new TkDisplayProc(this, &GTkAnnotations::cancel));
    procs.Insert("disable", 
		 new TkDisplayProc(this,&GTkAnnotations::w_disable));
    
    procs.Insert("enable", new TkDisplayProc(this, &GTkAnnotations::w_enable));
    
    itsIsValid = 1;
  }

extern "C" void GTkAnnotations_Create(ProxyStore *global_store, Value *args) {
  try {
    GTkAnnotations* anot = 0;
    if (args->Length() != 3) {
      global_store->Error("incorrect number of  arguments to annotations "
			  "agent constructor");
      return;
    }

    if (args->Type() != TYPE_RECORD) {
      global_store->Error("bad argument type");
      return;
    } 

    recordptr rptr = args->RecordPtr(0);
    int c= 0;
    const char* key;
    
    const Value* panDisp = rptr->NthEntry(c++, key);
    Int mousePointer = rptr->NthEntry(c++, key)->IntVal();
    casa::Bool useEH = rptr->NthEntry(c++, key)->BoolVal();

    Display::KeySym mouse = static_cast<Display::KeySym>(mousePointer);
    TkProxy* agent = (TkProxy* )(global_store->GetProxy(panDisp));
    
    if (agent && !strcmp(agent->AgentID(), 
			 "<graphic:paneldisplay>")) {
      anot = new GTkAnnotations(global_store, (GTkPanelDisplay*) agent, 
				mouse, useEH);
    } else if (agent && !strcmp(agent->AgentID(), 
				"<non-graphic:paneldisplay>")) {
      anot = new GTkAnnotations(global_store, (GTkPanelDisplay*) agent, 
				mouse, False);
    } else {
      Unref(args);
      global_store->Error("Bad argument for PanelDisplay agent passed to "
			  "GTkAnnotations");
      return;
    }
    
    if (!anot || !anot->IsValid()) {
      Value *err = anot ? anot->GetError() :0;
      if (err) {
	global_store->Error(err); 
      } else {
	global_store->Error("Annotations creation failed for unknown reasons");
      }
      
    } else anot->SendCtor("newtk");
    
  } catch (const AipsError &x) {
    String message = String ("Annotations agent creation failed:\n") 
      + x.getMesg();
    global_store->Error(message.chars());
  }
}

GTkAnnotations::~GTkAnnotations() {
}

int GTkAnnotations::IsValid() const {
  return itsIsValid;
}

char *GTkAnnotations::w_disable(Value *args) {
  static LogOrigin origin("GTkAnnotations", "w_disable");

  try {
    Annotations::disable();
  } catch (const AipsError &x) {
    postError(origin, x);
  }
  
  return "";
}

char *GTkAnnotations::w_enable(Value *args) {
  static LogOrigin origin("GTkAnnotations", "w_enable");

  try {
    Annotations::enable();
  } catch (const AipsError &x) {
    postError(origin, x);
  }


  return "";
}

/*
char *GTkAnnotations::cshape(Value *args) {
  
  Record shapeOptions(Annotations::cshape()) ;
  GlishRecord grec; grec.fromRecord(shapeOptions);
  Value *retval = new Value(*(grec.value()));
  
  if (ReplyPending()) {
    Reply(retval);
  } else {
    PostTkEvent("cshape", retval);
  } 
  return "";
}
*/

char *GTkAnnotations::addlockedtocurrent(Value *args) {
static LogOrigin origin("GTkDisplayData", "addlockedtocurrent");

  try {

    Str error;
    if (args->Length() != 1) {
      postError(origin, "Bad number of addlockedtocurrent - specify "
		"only shape id / number", 
		LogMessage::WARN);
      return "";
    }
    if (!args->IsNumeric()) {
      postError(origin, "Bad type of arg to addlockedtocurrent - specify "
		"shape id / number", 
		LogMessage::WARN);
      return "";
    }
    Int toDelete(args->IntVal(1,error));    
    if (!error.chars()) {
      Annotations::addLockedToCurrent(uInt(toDelete));
    }
    
  } catch (const AipsError &x) {
    postError(origin, x);
  } 

  return "";
}

char *GTkAnnotations::removelockedfromcurrent(Value *args) {
static LogOrigin origin("GTkDisplayData", "removelockedfromcurrent");

  try {

    Str error;
    if (args->Length() != 1) {
      postError(origin, "Bad number of removelockedfromcurrent - specify "
		"only shape id / number", 
		LogMessage::WARN);
      return "";
    }
    if (!args->IsNumeric()) {
      postError(origin, "Bad type of arg to removelockedfromcurrent - "
		"specify shape id / number", 
		LogMessage::WARN);
      return "";
    }
    Int toDelete(args->IntVal(1,error));    
    if (!error.chars()) {
      Annotations::removeLockedFromCurrent(uInt(toDelete));
    }

  } catch (const AipsError &x) {
    postError(origin, x);
  } 

  return "";
}

char *GTkAnnotations::reverttopix(Value *args) {

 static LogOrigin origin("GTkDisplayData", "reverttopix");

  try {

    Str error;
    if (args->Length() != 1) {
      postError(origin, "Bad number of args to reverttopix - specify "
		"only shape id / number", 
		LogMessage::WARN);
      return "";
    }
    if (!args->IsNumeric()) {
      postError(origin, "Bad type of arg to reverttopix - specify "
		"shape id / number", 
		LogMessage::WARN);
      return "";
    }
    Int toRev(args->IntVal(1,error));    
    if (!error.chars()) {
      if (!Annotations::revertToPix(toRev)) {
	
	postError(origin, "Trouble reverting requested shape - Check shape "
		  "number was correct"
		  ,LogMessage::WARN);
      }
    }
    
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  
  return "";
}

char *GTkAnnotations::reverttofrac(Value *args) {
 static LogOrigin origin("GTkDisplayData", "reverttofrac");

  try {

    Str error;
    if (args->Length() != 1) {
      postError(origin, "Bad number of args to reverttofrac - specify "
		"only shape id / number", 
		LogMessage::WARN);
      return "";
    }
    if (!args->IsNumeric()) {
      postError(origin, "Bad type of arg to reverttofrac - specify "
		"shape id / number", 
		LogMessage::WARN);
      return "";
    }
    Int toRev(args->IntVal(1,error));    
    if (!error.chars()) {
      if (!Annotations::revertToFrac(toRev)) {
	
	postError(origin, "Trouble reverting requested shape - Check shape "
		  "number was correct"
		  ,LogMessage::WARN);
      }
    }
    
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  
  return "";
}

char *GTkAnnotations::locktowc(Value *args) {

  static LogOrigin origin("GTkDisplayData", "locktowc");

  try {

    Str error;
    if (args->Length() != 1) {
      postError(origin, "Bad number of args to locktowc - specify "
		"only shape id / number", 
		LogMessage::WARN);
      return "";
    }
    if (!args->IsNumeric()) {
      postError(origin, "Bad type of arg to locktowc - specify "
		"shape id / number", 
		LogMessage::WARN);
      return "";
    }
    Int toLock(args->IntVal(1,error));    
    if (!error.chars()) {
      if (!Annotations::lockToWC(toLock)) {
	
	postError(origin, "Trouble locking requested shape - Check shape "
		  "number was correct and valid world co-ords available"
		  ,LogMessage::WARN);

      }
    } else {

      postError(origin, "Bad argument in call to lockToWC"
		,LogMessage::WARN);
      
    }
    
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  
  return "";
}

char *GTkAnnotations::deleteshape(Value *args) {
  
  static LogOrigin origin("GTkDisplayData", "deleteshape");

  try {

    Str error;
    if (args->Length() != 1) {
      postError(origin, "Bad number of args to delete shape - specify "
		"only shape id / number", 
		LogMessage::WARN);
      return "";
    }
    if (!args->IsNumeric()) {
      postError(origin, "Bad type of arg to delete shape - specify "
		"shape id / number", 
		LogMessage::WARN);
      return "";
    }
    Int toDelete(args->IntVal(1,error));    
    if (!error.chars()) {
      if (!Annotations::deleteShape(uInt(toDelete))) {

	postError(origin, "Trouble deleting requested shape - Check shape "
		  "number was correct"
		  ,LogMessage::WARN);
      }
    }
    
  } catch (const AipsError &x) {
    postError(origin, x);
  } 

  return "";
}


char *GTkAnnotations::whichshape(Value *args) {
  static LogOrigin origin("GTkAnnotations", "whichshape");
  try {
    Int active(Annotations::activeShape());
    
    Value *retval = new Value(active);

    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("whichshape", retval);
    } 

    delete retval;

  } catch (const AipsError &x) {
    postError(origin, x);
  }
  return "";
}

char *GTkAnnotations::cancel(Value *args) {
  static LogOrigin origin("GTkAnnotations", "cancel");
  try {
    Annotations::cancelShapes();
  } catch (const AipsError &x) {
    postError(origin, x);
  }
  return "";
}

char *GTkAnnotations::listshapes(Value *args) {
  static LogOrigin origin("GTkAnnotations", "listshapes");
  try {
    Record summary(Annotations::shapesSummary());
    GlishRecord glishSummary;

    glishSummary.fromRecord(summary);

    Value *retval = new Value(*(glishSummary.value()));

    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("listshapes", retval);
    } 
  } catch (const AipsError &x) {
    postError(origin, x);
  }
  return "";
}

char *GTkAnnotations::availableshapes(Value *args) {
  static LogOrigin origin("GTkAnnotations", "availableshapes");
  try {
    Record shapes(Annotations::availableShapes());

    GlishRecord grec;
    grec.fromRecord(shapes);

    Value *retval = new Value(*(grec.value()));
    
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("availableshapes", retval);
    } 
  } catch (const AipsError &x) {
    postError(origin, x);
  } return "";

}

char *GTkAnnotations::getalloptions(Value *args) {
  static LogOrigin origin("GTkAnnotations", "getalloptions");
  try {
    Record getAllOptions(Annotations::getAllOptions());
    
    GlishRecord grec; grec.fromRecord(getAllOptions);
    Value *retval = new Value(*(grec.value()));
    
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("getalloptions", retval);
    } 
    
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  
  
  return "";
}

char *GTkAnnotations::setalloptions(Value *args) {
  static LogOrigin origin("GTkAnnotations", "setalloptions");

  GlishValue val(args);
  
  if (val.type() != GlishValue::RECORD) {
    postError(origin, "Argument to \"setalloptions\" was not a record", 
	      LogMessage::WARN);
    return "";
  }
  
  try {
    
    Record rec;
    GlishRecord grec(args);
    grec.toRecord(rec);
    
    try {
      Annotations::setAllOptions(rec);
    } catch (const AipsError &x) {
      postError(origin, x.getMesg() ,LogMessage::WARN);
    }
    
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkAnnotations::setkey(Value *args) {
  static LogOrigin origin("GTkAnnotations", "setkey");

   try {
    
    Str error;
    if (args->Length() != 1) {
      postError(origin, "Bad number of args to set the key symbol", 
		LogMessage::WARN);
      return "";
    }
    if (!args->IsNumeric()) {
      postError(origin, "Bad type of arg to set key symbol", 
		LogMessage::WARN);
      return "";
    }
    Int newKey(args->IntVal(1,error));     
    if (!error.chars()) {
      Display::KeySym symbol = static_cast<Display::KeySym>(newKey);
      Annotations::setKey(symbol);
    } 
  } catch (const AipsError &x) {
    postError(origin, x);
  } 

  return "";
}

char *GTkAnnotations::getshapeoptions(Value *args) {
  static LogOrigin origin("GTkAnnotations", "getshapeoptions");

  try {
    Str error;
    
    if (args->Length() != 1) {
      postError(origin, "Bad number of args to delete shape - specify "
		"only shape id / number", 
		LogMessage::WARN);
      return "";
    }
    
    if (!args->IsNumeric()) {
      postError(origin, "Bad type of arg to delete shape - specify shape "
		"id / number", 
		LogMessage::WARN);
      return "";
    }

    Int toGet(args->IntVal(1,error));    

    if (!error.chars()) {
      Record shapeOptions(Annotations::getShapeOptions(uInt(toGet)));
      
      GlishRecord grec; grec.fromRecord(shapeOptions);
      Value *retval = new Value(*(grec.value()));
      
      if (ReplyPending()) {
	Reply(retval);
      } else {
	PostTkEvent("getshapeoptions", retval);
      } 
      
    } else postError(origin, "Error extracting argument value", 
		     LogMessage::WARN);

  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";

}

char *GTkAnnotations::setshapeoptions(Value *args) {
  static LogOrigin origin("GTkAnnotations", "setshapeoptions");

  try {

    if (args->Length() != 2) {

      postError(origin, "Bad number of args to setshapeoptions - specify "
		"shape id / number and new settings", 
		LogMessage::WARN);
      return "";
    }

      Record rec;
      GlishRecord grec(args);
      grec.toRecord(rec);
      

      Record settings(rec.subRecord(1));

      try {
	Annotations::setShapeOptions(rec.asInt(0), settings);
      } catch (const AipsError &x) {
	postError(origin, x.getMesg() ,LogMessage::WARN);
      }

  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}


char *GTkAnnotations::createshape(Value *args) {
  static LogOrigin origin("GTkAnnotations", "createshape");
  try {
    GlishValue val(args);

    if (val.type() != GlishValue::RECORD) {
      postError(origin, "Argument to \"createshape\" was not a record", 
		LogMessage::WARN);
      return "";
    }
    
    GlishRecord grec(val);
    Record rec;
    grec.toRecord(rec);

    // All strings to lower. 
    for(uInt i=0; i<rec.nfields() ;i++) {
      String name = rec.name(i);
      String lowerName(name); lowerName.downcase();

      rec.renameField(lowerName, i);
      
      if (rec.type(i) == TpString && 
	  rec.name(i) != "text") {
	String mixed = rec.asString(i);
	mixed.downcase();
	rec.define(i, mixed);
      }
    }

    Annotations::createShape(rec);
    
  } catch (const AipsError &x) {
    postError(origin, x);
  }
  
  return "";
}

void GTkAnnotations::annotEvent(const String& event) {
  
  Record test;
  test.define("desc", event);
  GlishRecord grec;
  grec.fromRecord(test);
  Value* tester = new Value(*(grec.value()));
  PostTkEvent("annotevent", tester);
  
}





char *GTkAnnotations::newshape(Value *args) {

  static LogOrigin origin("GTkAnnotations", "newshape");

  try {
    
    GlishValue val(args);
    
    if (val.type() != GlishValue::RECORD) {
      postError(origin, "Argument to \"newshape\" was not a record", 
		LogMessage::WARN);
      return "";
    }

    GlishRecord grec(val);
    Record rec;
    grec.toRecord(rec);

    // All strings to lower. (
    for(uInt i=0; i<rec.nfields() ;i++) {
      String name = rec.name(i);
      String lowerName(name); lowerName.downcase();


      rec.renameField(lowerName, i);
      
      if (rec.type(i) == TpString && 
	  rec.name(i) != "label") {
	String mixed = rec.asString(i);
	mixed.downcase();
	rec.define(i, mixed);
      }
    }

    Annotations::newShape(rec);

  } catch (const AipsError &x) {
    postError(origin, x);
  }
  return "";
}

void GTkAnnotations::postEvent(const String& name, const GlishRecord& rec) {
  Value* retval = new Value(*(rec.value()));
  PostTkEvent(name.c_str(),retval);
  delete retval;
}



}



