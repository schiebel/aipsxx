//# GTkPanelDisplay.cc: GlishTk implementation of the PanelDisplay
//# Copyright (C) 1999,2000,2001,2002,2003
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
//# $Id: GTkPanelDisplay.cc,v 19.10 2006/09/08 18:00:39 dking Exp $

#include <casa/aips.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>
#include <tasking/Glish/GlishArray.h>
#include <display/Display/Attribute.h>
#include <display/DisplayDatas/DisplayData.h>
#include <display/Display/PanelDisplay.h>
#include <display/Display/WorldCanvas.h>
#include <casa/iostream.h>
#include <casa/iomanip.h>
#include "GTkPanelDisplay.h"
#include "GTkPixelCanvas.h"
#include "GTkPSPixelCanvas.h"
#include "GTkDisplayData.h"
#include "GTkMWCRTZoomer.h"
#include "GTkMWCRTRegion.h"
#include "GTkMWCPTRegion.h"
#include "GTkMWCCTPositioner.h"
#include "GTkMWCPanner.h"
#include "GTkMWCPolyLine.h"
#include "GTkDrawingDD.h"
#include "gDisplay.h"

namespace casa {
GTkPanelDisplay::GTkPanelDisplay(ProxyStore* s, GTkPixelCanvas* gtkpc, 
				 const uInt nx, const uInt ny,
				 const Float xOrigin, const Float yOrigin,
				 const Float xSize, const Float ySize,
				 const Float dx, const Float dy,
				 const String foreground, 
				 const String background) :  
  GTkDisplayProxy(s),
  itsPixelCanvas(0),
  itsPanelDisplay(0),
  itsNX(nx),
  itsNY(ny),
  itsXOrigin(xOrigin),
  itsYOrigin(yOrigin),
  itsXSize(xSize),
  itsYSize(ySize),
  itsDX(dx),
  itsDY(dy),
  itsPanner(0),
  itsZoomer(0),
  itsRectRegion(0),
  itsPolyRegion(0),
  itsCrosshair(0),  
  itsPolyLine(0),  
  itsTrackingState(True),
  itsIsValid(0) {
  // check that the provided pixelcanvas is valid
  if (!gtkpc || !gtkpc->Self()) {
    throw(AipsError("The PixelCanvas given to the PanelDisplay was invalid"));
  }

  // attach ourselves to the window
  self = gtkpc->Self();

  // set the type of agent
  agent_ID = "<graphic:paneldisplay>";

  // store the internal pixelcanvas ptr
  itsPixelCanvas = gtkpc;
  // construct and initialise the requested PanelDisplay
  itsPanelDisplay = new PanelDisplay(itsPixelCanvas, itsNX, itsNY,
				     itsXOrigin, itsYOrigin,
				     itsXSize, itsYSize,
				     itsDX, itsDY);
  
  itsZoomer = new GTkMWCRTZoomer(this);
  itsPanelDisplay->addTool("zoomer",itsZoomer);
  itsRectRegion = new GTkMWCRTRegion(this);
  itsPanelDisplay->addTool("rectangle",itsRectRegion);
  itsPolyRegion = new GTkMWCPTRegion(this);
  itsPanelDisplay->addTool("polygon",itsPolyRegion);
  itsCrosshair = new GTkMWCCTPositioner(this);
  itsPanelDisplay->addTool("positioner",itsCrosshair);
  itsPanner = new GTkMWCPanner(this);
  itsPanelDisplay->addTool("panner",itsPanner);
  itsPolyLine = new GTkMWCPolyLine(this);
  itsPanelDisplay->addTool("polyline",itsPolyLine);


  installMEH();
  // install widget commands
  procs.Insert("refresh", 
	       new TkDisplayProc(this, &GTkPanelDisplay::refresh));
  procs.Insert("status", 
	       new TkDisplayProc(this, &GTkPanelDisplay::status));
  procs.Insert("hold", 
	       new TkDisplayProc(this, &GTkPanelDisplay::hold));
  procs.Insert("release", 
	       new TkDisplayProc(this, &GTkPanelDisplay::release));
  procs.Insert("add", 
  	       new TkDisplayProc(this, &GTkPanelDisplay::add));
  procs.Insert("remove", 
  	       new TkDisplayProc(this, &GTkPanelDisplay::remove));
  procs.Insert("getgeometry",
	       new TkDisplayProc(this, &GTkPanelDisplay::getgeometry));
  procs.Insert("setgeometry",
	       new TkDisplayProc(this, &GTkPanelDisplay::setgeometry));
  procs.Insert("getoptions",
	       new TkDisplayProc(this, &GTkPanelDisplay::getoptions));
  procs.Insert("setoptions",
	       new TkDisplayProc(this, &GTkPanelDisplay::setoptions));
  procs.Insert("unzoom",
	       new TkDisplayProc(this, &GTkPanelDisplay::unzoom));
  procs.Insert("setzoom",
	       new TkDisplayProc(this, &GTkPanelDisplay::setzoom));
  procs.Insert("disabletools",
	       new TkDisplayProc(this, &GTkPanelDisplay::disabletools));
  procs.Insert("enabletools",
	       new TkDisplayProc(this, &GTkPanelDisplay::enabletools));
  procs.Insert("settoolkey",
	       new TkDisplayProc(this, &GTkPanelDisplay::settoolkey));
  procs.Insert("zlength",
	       new TkDisplayProc(this, &GTkPanelDisplay::zlength));


}

GTkPanelDisplay::GTkPanelDisplay(ProxyStore* s, GTkPSPixelCanvas* gtkpspc,
				 const uInt nx, const uInt ny,
				 const Float xOrigin, const Float yOrigin,
				 const Float xSize, const Float ySize,
				 const Float dx, const Float dy,
				 const String foreground,
				 const String background) :
  GTkDisplayProxy(s, 0),
  itsPixelCanvas(0),
  itsPanelDisplay(0),
  itsNX(nx),
  itsNY(ny),
  itsXOrigin(xOrigin),
  itsYOrigin(yOrigin),
  itsXSize(xSize),
  itsYSize(ySize),
  itsDX(dx),
  itsDY(dy),  
  itsPanner(0),
  itsZoomer(0),
  itsRectRegion(0),
  itsPolyRegion(0),
  itsCrosshair(0),  
  itsPolyLine(0),  
  itsTrackingState(False),
  itsIsValid(0) {

  // check that the provided pixelcanvas is valid
  if (!gtkpspc || !gtkpspc->IsValid()) {
    throw(AipsError("An invalid pspixelcanvas was given to the worldcanvas"));
  }

  // set the type of agent
  agent_ID = "<non-graphic:paneldisplay>";

  // store the internal PixelCanvas ptr
  itsPixelCanvas = gtkpspc->pixelCanvas();
  // construct and initialise the requested PanelDisplay
  itsPanelDisplay = new PanelDisplay(itsPixelCanvas, itsNX, itsNY,
				     itsXOrigin, itsYOrigin,
				     itsXSize, itsYSize,
				     itsDX, itsDY);
  itsZoomer = new GTkMWCRTZoomer(this);
  itsPanelDisplay->addTool("zoomer",itsZoomer);
  // install widget commands
  procs.Insert("refresh", 
	       new TkDisplayProc(this, &GTkPanelDisplay::refresh));
  procs.Insert("status", 
	       new TkDisplayProc(this, &GTkPanelDisplay::status));
  procs.Insert("hold", 
	       new TkDisplayProc(this, &GTkPanelDisplay::hold));
  procs.Insert("release", 
	       new TkDisplayProc(this, &GTkPanelDisplay::release));
  procs.Insert("add", 
  	       new TkDisplayProc(this, &GTkPanelDisplay::add));
  procs.Insert("remove", 
  	       new TkDisplayProc(this, &GTkPanelDisplay::remove));
  procs.Insert("getgeometry",
	       new TkDisplayProc(this, &GTkPanelDisplay::getgeometry));
  procs.Insert("setgeometry",
	       new TkDisplayProc(this, &GTkPanelDisplay::setgeometry));
  procs.Insert("getoptions",
	       new TkDisplayProc(this, &GTkPanelDisplay::getoptions));
  procs.Insert("setoptions",
	       new TkDisplayProc(this, &GTkPanelDisplay::setoptions));
  procs.Insert("setzoom",
	       new TkDisplayProc(this, &GTkPanelDisplay::setzoom));
  procs.Insert("zlength",
	       new TkDisplayProc(this, &GTkPanelDisplay::zlength));
  itsIsValid = 1;
}

extern "C" void GTkPanelDisplay_Create(ProxyStore* global_store, Value* args) {
  try {
    // a handle for the agent we will build
    GTkPanelDisplay* ret;
    
    // check for number of arguments
    if (args->Length() != 11) {
      global_store->Error("too few arguments to paneldisplay agent");
      return;
    }

    // fetch arguments
    if (args->Type() != TYPE_RECORD) {
      global_store->Error("bad argument type to paneldisplay agent");
      return;
    }
    Ref(args);
    recordptr rptr = args->RecordPtr(0);
    int c = 0;
    const char* key;
    const Value* parent = rptr->NthEntry(c++, key);
    if (!parent->IsAgentRecord()) {
      global_store->Error("bad parent argument to paneldisplay agent");
      return;
    }
    Int nx = rptr->NthEntry(c++, key)->IntVal();
    Int ny = rptr->NthEntry(c++, key)->IntVal();
    Float xorigin = rptr->NthEntry(c++, key)->FloatVal();
    Float yorigin = rptr->NthEntry(c++, key)->FloatVal();
    Float xsize = rptr->NthEntry(c++, key)->FloatVal();
    Float ysize = rptr->NthEntry(c++, key)->FloatVal();
    Float dx = rptr->NthEntry(c++, key)->FloatVal();
    Float dy = rptr->NthEntry(c++, key)->FloatVal();
    String foreground = rptr->NthEntry(c++, key)->StringVal();
    String background = rptr->NthEntry(c++, key)->StringVal();
    
    // make the agent
    TkProxy* agent = (TkProxy* )(global_store->GetProxy(parent));
    if (agent && !strcmp(agent->AgentID(), "<graphic:pixelcanvas>")) {
      ret = new GTkPanelDisplay(global_store, (GTkPixelCanvas* )agent, 
				nx, ny, xorigin,
				yorigin, xsize, ysize, dx, dy, 
				foreground, background);
    } else if (agent && !strcmp(agent->AgentID(), 
				"<non-graphic:pspixelcanvas>")) {
      ret = new GTkPanelDisplay(global_store, (GTkPSPixelCanvas* )agent, 
				nx, ny, xorigin,
				yorigin, xsize, ysize, dx, dy,
				foreground, background);
    } else {
      Unref(args);
      global_store->Error("bad parent argument to paneldisplay agent");
      return;
    }

    if (!ret || !ret->IsValid()) {
      Value* err = ret->GetError();
      if (err) {
	global_store->Error(err);
	Unref(err);
      } else {
	global_store->Error("paneldisplay agent creation failed for "
			    "unknown reason");
      }
    } else {
      ret->SendCtor("newtk");
    }
    Unref(args);
  } catch (const AipsError &x) {
    String message =
      String("paneldisplay agent creation failed for internal reason: ") +
      x.getMesg();
    global_store->Error(message.chars());
  } 
}

GTkPanelDisplay::~GTkPanelDisplay() {  
  //only if we are using X11PixelCanvas, not if PSPixelCanvas
  if (!strcmp(AgentID(), "<graphic:paneldisplay>")) {
    removeMEH();
  }
  // MultiWCTools are automatically removed by the PanelDisplay
  // destructor
  if (itsPanelDisplay) {
    delete itsPanelDisplay;
  }
}

int GTkPanelDisplay::IsValid() const {
  if (!strcmp(AgentID(), "<graphic:paneldisplay>")) {
    return (self != 0);
  } else {
    return itsIsValid;
  }
}

void GTkPanelDisplay::replyIfPending(const casa::Bool& value) {
  GTkDisplayProxy::replyIfPending(value);
}


char* GTkPanelDisplay::refresh(Value* ) {
  static LogOrigin origin("GTkPanelDisplay", "refresh");
  installGTkLogSink();
  try {
    if (itsPixelCanvas->refreshAllowed()) {
      itsPanelDisplay->refresh();
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char* GTkPanelDisplay::hold(Value* ) {
  static LogOrigin origin("GTkPanelDisplay", "hold");
  installGTkLogSink();
  try {
    itsPanelDisplay->hold();
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char* GTkPanelDisplay::release(Value* ) {
  static LogOrigin origin("GTkPanelDisplay", "release");
  installGTkLogSink();
  try {
    itsPanelDisplay->release();
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char* GTkPanelDisplay::add(Value* args) {
  static LogOrigin origin("GTkPanelDisplay", "add");
  installGTkLogSink();
  try {
    if (args->Type() != TYPE_RECORD) {
      postError(origin, "Argument to \"paneldisplay->add\" was not "
		"a record", LogMessage::WARN);
      installNullLogSink();
      return "";
    }
    GlishValue val(args);
    GlishRecord rec = val;
    GlishRecord nrec;
    nrec.add(rec.name(0), rec.get(0));
    TkProxy* agent = static_cast<TkProxy*>(global_store->
					   GetProxy(rec.value()));
    
    // check it is a non-graphic:displaydata
    if (agent && !strcmp(agent->AgentID(), "<non-graphic:displaydata>")) {
      DisplayData* dd = (static_cast<GTkDisplayData*>(agent))->displayData();
      // stuff that we might do elsewhere
      Attribute xAtt("xaxisname", String("x-as"));
      Attribute yAtt("yaxisname", String("y-as"));
      dd->setRestriction(xAtt);
      dd->setRestriction(yAtt);
      itsPanelDisplay->setRestriction(xAtt);
      itsPanelDisplay->setRestriction(yAtt);
      // end stuff that we might do elsewhere

      Int preferredZIndex;
      casa::Bool ddHasPreferredZIndex = dd->zIndexHint(preferredZIndex);
	// (preferredZIndex is recorded prior to adding DD, for obscure
	// reasons: sometimes a setting is used from another Panel where
	// dd is registered).

      
      itsPanelDisplay->addDisplayData(*dd);

      
      // Send animator changes out to glish.  This also causes
      // zLength to be requested from the DD[s] and set onto the
      // animator (even if animrec is empty).
      
      Record animrec;

      if(itsPanelDisplay->isCSmaster(dd) && ddHasPreferredZIndex) {
	// New dd has become CS master: pass along its opinions
	// on animator frame number setting, if any.
	animrec.define("zindex", preferredZIndex);
      }

      // Blink index or length may also change when DD added.

      if(itsPanelDisplay->isBlinkDD(dd)) {
        animrec.define("blength", itsPanelDisplay->bLength());
        animrec.define("bindex", itsPanelDisplay->bIndex());
      }

      GlishRecord ganimrec;
      ganimrec.fromRecord(animrec);
      Value* setanimrec = new Value(*(ganimrec.value()));
      PostTkEvent("setanimator", setanimrec);
      Unref(setanimrec);


      
    } else if (agent && !strcmp(agent->AgentID(),
				"<non-graphic:drawingdisplaydata>")) {
      DisplayData* dd = (static_cast<GTkDrawingDD*>(agent))->displayData();
      itsPanelDisplay->addDisplayData(*dd);
    } else {
      postError(origin, "Argument to \"paneldisplay->add\" was not "
		"a displaydata agent", LogMessage::WARN);
      installNullLogSink();
      return "";
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  }
  replyIfPending();
  installNullLogSink();
  return "";
}

char* GTkPanelDisplay::remove(Value* args) {
  static LogOrigin origin("GTkPanelDisplay", "remove");
  try {
    if (args->Type() != TYPE_RECORD) {
      postError(origin, "Argument to \"paneldisplay->remove\" was not "
		"a record", LogMessage::WARN);
      return "";
    }
    GlishValue val(args);
    GlishRecord rec = val;
    GlishRecord nrec;
    nrec.add(rec.name(0), rec.get(0));
    TkProxy* agent = static_cast<TkProxy*>(global_store->
					   GetProxy(rec.value()));
    
    // check it is a non-graphic:displaydata
    if (agent && !strcmp(agent->AgentID(), "<non-graphic:displaydata>")) {
      DisplayData* dd = (static_cast<GTkDisplayData*>(agent))->displayData();

      itsPanelDisplay->removeDisplayData(*dd);

      // Signal animator to reset number of (Z) frames according to
      // remaining DDs.  (Current frame should remain unchanged if
      // still in range).
      // Blink index or length may also change when DD is removed.

      Record animrec;

      if(itsPanelDisplay->isBlinkDD(dd)) {
        animrec.define("blength", itsPanelDisplay->bLength());
        animrec.define("bindex", itsPanelDisplay->bIndex());
      }

      GlishRecord ganimrec;
      ganimrec.fromRecord(animrec);
      Value* setanimrec = new Value(*(ganimrec.value()));
      PostTkEvent("setanimator", setanimrec);
      Unref(setanimrec);

    } else if (agent && !strcmp(agent->AgentID(),
				"<non-graphic:drawingdisplaydata>")) {
      DisplayData* dd = (static_cast<GTkDrawingDD*>(agent))->displayData();
      itsPanelDisplay->removeDisplayData(*dd);
    } else {
      postError(origin, "Argument to \"paneldisplay->remove\" was not "
		"an agent record", LogMessage::WARN);
      return "";
    }

  } catch (const AipsError &x) {
    postError(origin, x);
  }  
  replyIfPending();
  installNullLogSink();
  return "";
} 

char* GTkPanelDisplay::getgeometry(Value* args) {
  static LogOrigin origin("GTkPanelDisplay", "getgeometry");
  try {
    Record rec;
    itsPanelDisplay->getGeometry(rec);
    GlishRecord grec;
    grec.fromRecord(rec);
    Value* retval = new Value(*(grec.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("geometry", retval);
    }
    Unref(retval);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
} 

char* GTkPanelDisplay::setgeometry(Value* args) {
  static LogOrigin origin("GTkPanelDisplay", "setgeometry");
  try {
    GlishValue val(args);
    if (val.type() != GlishValue::RECORD) {
      throw(AipsError("argument to setgeometry not a record"));
    }
    GlishRecord grec(args);
    Record rec;
    grec.toRecord(rec);
    removeMEH();
    itsPanelDisplay->setGeometry(rec);
    installMEH();
    if (itsPixelCanvas->refreshAllowed()) {
      itsPanelDisplay->refresh();
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}
char* GTkPanelDisplay::getoptions(Value* args) {
  static LogOrigin origin("GTkPanelDisplay", "getoptions");
  try {
    Record rec = itsPanelDisplay->getOptions();
    GlishRecord grec;
    grec.fromRecord(rec);
    Value* retval = new Value(*(grec.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("options", retval);
    }
    Unref(retval);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
} 

char* GTkPanelDisplay::setoptions(Value* args) {
  static LogOrigin origin("GTkPanelDisplay", "setoptions");
  try {
    GlishValue val(args);
    if (val.type() != GlishValue::RECORD) {
      throw(AipsError("argument to setoptions not a record"));
    }
    GlishRecord grec(args);
    Record rec;
    grec.toRecord(rec);
    casa::Bool refreshRequired = False;
    Record outputOptions;
    refreshRequired = (itsPanelDisplay->setOptions(rec, outputOptions) ||
		       refreshRequired);
    if (refreshRequired && itsPixelCanvas->refreshAllowed()) {
      itsPanelDisplay->refresh();
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  //replyIfPending();
  return "";
}

char* GTkPanelDisplay::disabletools(Value* ) {
  static LogOrigin origin("GTkPanelDisplay", "disabletools");
  try {
    itsPanelDisplay->disableTools();
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char* GTkPanelDisplay::enabletools(Value* ) {
  static LogOrigin origin("GTkPanelDisplay", "enabletools");
  try {
    itsPanelDisplay->enableTools();
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";

}

char *GTkPanelDisplay::settoolkey(Value *args) {
  static LogOrigin origin("GTkWorldCanvas", "zoomer");
  try {
    if (!itsPanelDisplay->hasTools()) {
      return "";
    }
    // check for number of arguments
    if ((args->Length() != 2) || (args->Type() != TYPE_RECORD)) {
      postError(origin, "Argument to \"paneldisplay->settoolkey\" was not "
		"a record of length 2", LogMessage::WARN);
      return "";
    }
    // fetch arguments
    Ref(args);
    recordptr rptr = args->RecordPtr(0);
    int c = 0;
    const char *key;
    String toolname = rptr->NthEntry(c++, key)->StringVal();
    Int catchkey = rptr->NthEntry(c++, key)->IntVal();
    itsPanelDisplay->setToolKey(toolname,(Display::KeySym)catchkey);
    Unref(args);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char *GTkPanelDisplay::setzoom(Value *args) {
  static LogOrigin origin("GTkPanelDisplay", "setzoom");
  installGTkLogSink();
  try {
    // check for number of arguments
    if ((args->Length() != 4) || (args->Type() != TYPE_RECORD)) {
      postError(origin, "Argument to \"paneldisplay->setzoom\" was not "
		"a record of length 4", LogMessage::WARN);
      return "";
    }
    // fetch arguments
    Ref(args);
    recordptr rptr = args->RecordPtr(0);
    int c = 0;
    const char *key;
    static Vector<Double> blc(2), trc(2);
    blc(0) = rptr->NthEntry(c++, key)->FloatVal();
    blc(1) = rptr->NthEntry(c++, key)->FloatVal();
    trc(0) = rptr->NthEntry(c++, key)->FloatVal();
    trc(1) = rptr->NthEntry(c++, key)->FloatVal();
    itsZoomer->zoom(blc,trc);
    // need to do more here!
    //if (itsPixelCanvas->refreshAllowed()) {
    //itsPixelCanvas->refresh();
    //}
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char* GTkPanelDisplay::unzoom(Value* ) {
  static LogOrigin origin("GTkPanelDisplay", "unzoom");
  try {
    itsZoomer->unzoom();
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkPanelDisplay::zlength(Value *) {
  static LogOrigin origin("GTkPanelDisplay", "zlength");
  try {
    Int length = Int(itsPanelDisplay->zLength());
    GlishArray outarr(length);
    Value *retval = new Value(*(outarr.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("zlength", retval);
    }
    Unref(retval);
  } catch (const AipsError &x) {
    postError(origin, x);
  }
  return "";

}char *GTkPanelDisplay::status(Value *) {
  static LogOrigin origin("GTkPanelDisplay", "status");
  installGTkLogSink();
  try {
    GlishRecord grec;
    Record rec;
    // basic parameters
    itsPanelDisplay->getGeometry(rec);
    grec.fromRecord(rec);
#ifndef AIPS_64B
    grec.add("paneldisplayid", Int(itsPanelDisplay));
#else
    Long dummy = (Long)itsPanelDisplay;
    Int dummy2[2];
    memcpy(dummy2, &dummy, sizeof(Long));
    grec.add("paneldisplayid", dummy2);
#endif
    //

    // linear and world coordinate system
    
    
    //#dk This rev. attempts to remove assumptions (or cases) regarding
    //    the size of (WC) pointers when passing them to glish.
    //    (64-bit bugfix).
    
    ConstListIter<WorldCanvas*>& wcs = *(itsPanelDisplay->myWCLI);
    
    Vector<String> wcHandles(wcs.len());
    uInt i=0;
    
    for (wcs.toStart(); !wcs.atEnd(); wcs++) {
      ostringstream os;   os << setprecision(68); 
      os << (void*)(wcs.getRight());	// (The WC pointer as formatted hex).
      wcHandles(i++) = String(os);  }
      
    grec.add("worldcanvasid", GlishArray(wcHandles));
    
    
    
/*  //#dk  -- the old code
    
    itsPanelDisplay->myWCLI->toStart();
    uInt i = 0;
    Vector<Int> tmpVec(itsPanelDisplay->myWCLI->len());
#ifndef AIPS_64B      
      tmpVec(i) = (Int)wc;
#else
#ifdef AIPS_GCC3
      Long dummy = (Long)wc;
     #else
      Long dummy = static_cast<Long>wc;
#endif
      Int dummy2 = static_cast<Int>(dummy);
      tmpVec(i) = dummy2;
#endif
      i++;
      (*(itsPanelDisplay->myWCLI))++;
    }
    grec.add("worldcanvasid",GlishArray(tmpVec));

*/  //#dk


    itsPanelDisplay->myWCLI->toStart();
    while (!itsPanelDisplay->myWCLI->atEnd()) {
      WorldCanvas* wc = itsPanelDisplay->myWCLI->getRight();
      Vector<Double> tvec(2), world;
      tvec(0) = wc->linXMin();
      tvec(1) = wc->linYMin();
      grec.add("linearblc", GlishArray(tvec));

      wc->linToWorld (world, tvec);
      grec.add("worldblc", GlishArray(world));

      tvec(0) = wc->linXMax();
      tvec(1) = wc->linYMax();
      grec.add("lineartrc", GlishArray(tvec));
      world.resize(0);
      wc->linToWorld (world, tvec);
      grec.add("worldtrc", GlishArray(world));
      
      Vector<String> units = itsPanelDisplay->wcHolder(wc)->worldAxisUnits();
      grec.add("axisunits", GlishArray(units));
      break;// only get first one
    }     
    // post record to glish

    Value *retval = new Value(*(grec.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("status", retval);
    }
    Unref(retval);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

void GTkPanelDisplay::operator()(const WCMotionEvent &ev) {
  static LogOrigin origin("GTkPanelDisplay", "operator(WCMotionEvent &ev)");
  installGTkLogSink();
  try {
    if (itsTrackingState) {
      itsPanelDisplay->myWCLI->toStart();
      while (!itsPanelDisplay->myWCLI->atEnd()) {
	WorldCanvas* wc = itsPanelDisplay->myWCLI->getRight();

	if (ev.worldCanvas() == wc) {
	  GlishRecord rec;
	  Vector<Double> world = ev.world();
	  rec.add("world", GlishArray(world));
	  static Vector<Int> pixel(2);
	  pixel(0) = ev.pixX();
	  pixel(1) = ev.pixY();
	  rec.add("pixel", GlishArray(pixel));
	  
	  ostringstream oss;
	  oss.setf(ios::fixed, ios::floatfield);
	  oss.precision(6);
	  String attString = "xaxisunits";
	  String unitString = "_";
	  if (wc->existsAttribute(attString)) {
	    wc->getAttributeValue(attString, unitString);
	  }
	  Quantity xq(world(0), unitString);
	  xq.print(oss);
	  attString = "yaxisunits";
	  unitString = "_";
	  if (wc->existsAttribute(attString)) {
	    wc->getAttributeValue(attString, unitString);
	  }
	  Quantity yq(world(1), unitString);
	  oss << " ";
	  yq.print(oss);
	  rec.add("formattedworld", String(oss));
	  Value *retval = new Value(*(rec.value()));
	  if (ReplyPending()) {
	    Reply(retval);
	  } else {
	    PostTkEvent("motion", retval);	    
	  }
	  Unref(retval);
	  //delete retval;retval=0
	  break;
	}
	(*(itsPanelDisplay->myWCLI))++;
      }
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
}

void GTkPanelDisplay::installMEH() {
  itsPanelDisplay->myWCLI->toStart();
  while (!itsPanelDisplay->myWCLI->atEnd()) {
    WorldCanvas* wc = itsPanelDisplay->myWCLI->getRight();  
    wc->addMotionEventHandler(*this);
    (*(itsPanelDisplay->myWCLI))++;
  }
}

void GTkPanelDisplay::removeMEH() {
  itsPanelDisplay->myWCLI->toStart();
  while (!itsPanelDisplay->myWCLI->atEnd()) {
    WorldCanvas* wc = itsPanelDisplay->myWCLI->getRight();  
    wc->removeMotionEventHandler(*this);
    (*(itsPanelDisplay->myWCLI))++;
  }
}
void GTkPanelDisplay::postEvent(const String& name, const GlishRecord& rec) {
  Value* retval = new Value(*(rec.value()));
  PostTkEvent(name.c_str(),retval);
  Unref(retval);
}

}
