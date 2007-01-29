//# GTkSlicePD.cc: GlishTk implementation of the SlicePD
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
//# $Id: GTkSlicePD.cc,v 19.4 2005/06/15 18:09:13 cvsmgr Exp $

#include <casa/aips.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>
#include <tasking/Glish/GlishArray.h>
#include <display/Display/Attribute.h>
#include <display/DisplayDatas/DisplayData.h>
#include <display/Display/PanelDisplay.h>
#include <display/Display/SlicePanelDisplay.h>
#include <display/Display/PixelCanvas.h>
#include <display/Display/WorldCanvas.h>
#include "GTkPixelCanvas.h"
#include "GTkSlicePD.h"
#include "GTkDisplayData.h"
#include "GTkDrawingDD.h"
#include "GTkMWCRTZoomer.h"
#include "GTkMWCRTRegion.h"
#include "GTkMWCPTRegion.h"
#include "GTkMWCCTPositioner.h"
#include "GTkMWCPanner.h"
#include "gDisplay.h"

namespace casa {

GTkSlicePD::GTkSlicePD(ProxyStore* s, GTkPixelCanvas* gtkpc) :
  GTkDisplayProxy(s),
  itsPixelCanvas(0),
  itsSlicePD(0),
  itsTrackingState(True),
  itsIsValid(0) {
  // check that the provided pixelcanvas is valid
  if (!gtkpc || !gtkpc->Self()) {
    throw(AipsError("The PixelCanvas given to the slicepd was invalid"));
  }

  // attach ourselves to the window
  self = gtkpc->Self();

  // set the type of agent
  agent_ID = "<graphic:slicepd>";

  // store the internal pixelcanvas ptr
  itsPixelCanvas = gtkpc;
  // construct and initialise the requested SlicePD
  itsSlicePD = new SlicePanelDisplay(itsPixelCanvas);
  
  installTools();
  // install widget commands
  procs.Insert("status", 
	       new TkDisplayProc(this, &GTkSlicePD::status));
  procs.Insert("hold", 
	       new TkDisplayProc(this, &GTkSlicePD::hold));
  procs.Insert("release", 
	       new TkDisplayProc(this, &GTkSlicePD::release));
  procs.Insert("add", 
  	       new TkDisplayProc(this, &GTkSlicePD::add));
  procs.Insert("remove", 
  	       new TkDisplayProc(this, &GTkSlicePD::remove));
  procs.Insert("getoptions",
	       new TkDisplayProc(this, &GTkSlicePD::getoptions));
  procs.Insert("setoptions",
	       new TkDisplayProc(this, &GTkSlicePD::setoptions));
  procs.Insert("unzoom",
	       new TkDisplayProc(this, &GTkSlicePD::unzoom));
  procs.Insert("setzoom",
	       new TkDisplayProc(this, &GTkSlicePD::setzoom));
  procs.Insert("disabletools",
	       new TkDisplayProc(this, &GTkSlicePD::disabletools));
  procs.Insert("enabletools",
	       new TkDisplayProc(this, &GTkSlicePD::enabletools));
  procs.Insert("settoolkey",
	       new TkDisplayProc(this, &GTkSlicePD::settoolkey));
  procs.Insert("precompute",
	       new TkDisplayProc(this, &GTkSlicePD::precompute));
}

extern "C" void GTkSlicePD_Create(ProxyStore* global_store, Value* args) {
  try {
    // a handle for the agent we will build
    GTkSlicePD* ret;
    // check for number of arguments
    if (args->Length() < 1) {
      global_store->Error("too few arguments to slicepd agent");
      return;
    }
    // fetch arguments
    if (!args->IsAgentRecord()) {
      global_store->Error("bad parent argument to slicepd agent");
      return;
    }
    // make the agent
    TkProxy* agent = (TkProxy* )(global_store->GetProxy(args));
    if (agent && !strcmp(agent->AgentID(), "<graphic:pixelcanvas>")) {
      ret = new GTkSlicePD(global_store, (GTkPixelCanvas* )agent);
    } else {
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
  } catch (const AipsError &x) {
    String message =
      String("paneldisplay agent creation failed for internal reason: ") +
      x.getMesg();
    global_store->Error(message.chars());
  } 
}

GTkSlicePD::~GTkSlicePD() {  
  if (itsSlicePD) {
    delete itsSlicePD;
  }
}
void GTkSlicePD::installTools() {
  // Tool pointers are cleaned up by the PanelDisplay destructors
  itsSlicePD->getPanelDisplay("xy")->addTool("zoomer",
					     new GTkMWCRTZoomer(this));
  itsSlicePD->getPanelDisplay("zy")->addTool("zoomer",
					     new GTkMWCRTZoomer(this));
  itsSlicePD->getPanelDisplay("xz")->addTool("zoomer",
					     new GTkMWCRTZoomer(this));
  itsSlicePD->getPanelDisplay("xy")->addTool("panner",new GTkMWCPanner(this));
  itsSlicePD->getPanelDisplay("zy")->addTool("panner",new GTkMWCPanner(this));
  itsSlicePD->getPanelDisplay("xz")->addTool("panner",new GTkMWCPanner(this));

  itsSlicePD->getPanelDisplay("xy")->addTool("rectangle",
					     new GTkMWCRTRegion(this));
  itsSlicePD->getPanelDisplay("zy")->addTool("rectangle",
					     new GTkMWCRTRegion(this));
  itsSlicePD->getPanelDisplay("xz")->addTool("rectangle",
					     new GTkMWCRTRegion(this));

  itsSlicePD->getPanelDisplay("xy")->addTool("polygon",
					     new GTkMWCPTRegion(this));
  itsSlicePD->getPanelDisplay("zy")->addTool("polygon",
					     new GTkMWCPTRegion(this));
  itsSlicePD->getPanelDisplay("xz")->addTool("polygon",
					     new GTkMWCPTRegion(this));

  itsSlicePD->getPanelDisplay("xy")->addTool("positioner",
					     new GTkMWCCTPositioner(this));
  itsSlicePD->getPanelDisplay("zy")->addTool("positioner",
					     new GTkMWCCTPositioner(this));
  itsSlicePD->getPanelDisplay("xz")->addTool("positioner",
					     new GTkMWCCTPositioner(this));

}
int GTkSlicePD::IsValid() const {
  if (!strcmp(AgentID(), "<graphic:slicepd>")) {
    return (self != 0);
  } else {
    return itsIsValid;
  }
}

void GTkSlicePD::replyIfPending(const casa::Bool& value) {
  GTkDisplayProxy::replyIfPending(value);
}

char* GTkSlicePD::hold(Value* ) {
  static LogOrigin origin("GTkSlicePD", "hold");
  installGTkLogSink();
  try {
    itsSlicePD->hold();
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char* GTkSlicePD::release(Value* ) {
  static LogOrigin origin("GTkSlicePD", "release");
  installGTkLogSink();
  try {
    itsSlicePD->release();
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char* GTkSlicePD::add(Value* args) {
  static LogOrigin origin("GTkSlicePD", "add");
  installGTkLogSink();
  try {
    if (args->Type() != TYPE_RECORD) {
      postError(origin, "Argument to \"SlicePD->add\" was not "
		"a record", LogMessage::WARN);
      installNullLogSink();
      return "";
    }
    Ref(args);
    recordptr rptr = args->RecordPtr(0);
    int c = 0;
    const char *key;
    const Value *ddagent1 = rptr->NthEntry(c++, key);
    const Value *ddagent2 = rptr->NthEntry(c++, key);
    const Value *ddagent3 = rptr->NthEntry(c, key);
    
    TkProxy* ddproxy1 = (TkProxy* )(global_store->GetProxy(ddagent1));
    TkProxy* ddproxy2 = (TkProxy* )(global_store->GetProxy(ddagent2));
    TkProxy* ddproxy3 = (TkProxy* )(global_store->GetProxy(ddagent3));
    
    // check it is a non-graphic:displaydata
    if (ddproxy1 && 
	!strcmp(ddproxy1->AgentID(), "<non-graphic:displaydata>")) {
      DisplayData* dd = ((GTkDisplayData* )ddproxy1)->displayData();
      // stuff that we might do elsewhere
      Attribute xAtt("xaxisname", String("x-as"));
      Attribute yAtt("yaxisname", String("y-as"));
      dd->setRestriction(xAtt);
      dd->setRestriction(yAtt);
      itsSlicePD->getPanelDisplay("xy")->setRestriction(xAtt);
      itsSlicePD->getPanelDisplay("xy")->setRestriction(yAtt);
      // end stuff that we might do elsewhere
      itsSlicePD->getPanelDisplay("xy")->addDisplayData(*dd);
    } else if (ddproxy1 && !strcmp(ddproxy1->AgentID(), 
				"<non-graphic:drawingdisplaydata>")) {
      DisplayData* dd = ((GTkDrawingDD* )ddproxy1)->displayData();
      itsSlicePD->getPanelDisplay("xy")->addDisplayData(*dd);
    } else {
      Unref(args);
      postError(origin, "Argument 1 to \"SlicePD->add\" was not "
		"a displaydata agent", LogMessage::WARN);
      installNullLogSink();
      return "";
    }
    if (ddproxy2 && 
	!strcmp(ddproxy2->AgentID(), "<non-graphic:displaydata>")) {
      DisplayData* dd = ((GTkDisplayData* )ddproxy2)->displayData();
      // stuff that we might do elsewhere
      Attribute xAtt("xaxisname", String("x-as"));
      Attribute yAtt("yaxisname", String("y-as"));
      dd->setRestriction(xAtt);
      dd->setRestriction(yAtt);
      itsSlicePD->getPanelDisplay("zy")->setRestriction(xAtt);
      itsSlicePD->getPanelDisplay("zy")->setRestriction(yAtt);
      // end stuff that we might do elsewhere
      itsSlicePD->getPanelDisplay("zy")->addDisplayData(*dd);
    } else if (ddproxy2 && !strcmp(ddproxy2->AgentID(), 
				"<non-graphic:drawingdisplaydata>")) {
      DisplayData* dd = ((GTkDrawingDD* )ddproxy2)->displayData();
      itsSlicePD->getPanelDisplay("xy")->addDisplayData(*dd);
    } else {
      Unref(args);
      postError(origin, "Argument 2 to \"SlicePD->add\" was not "
		"a displaydata agent", LogMessage::WARN);
      installNullLogSink();
      return "";
    }
    if (ddproxy3 && 
	!strcmp(ddproxy3->AgentID(), "<non-graphic:displaydata>")) {
      DisplayData* dd = ((GTkDisplayData* )ddproxy3)->displayData();
      // stuff that we might do elsewhere
      Attribute xAtt("xaxisname", String("x-as"));
      Attribute yAtt("yaxisname", String("y-as"));
      dd->setRestriction(xAtt);
      dd->setRestriction(yAtt);
      itsSlicePD->getPanelDisplay("xz")->setRestriction(xAtt);
      itsSlicePD->getPanelDisplay("xz")->setRestriction(yAtt);
      // end stuff that we might do elsewhere
      itsSlicePD->getPanelDisplay("xz")->addDisplayData(*dd);
    } else if (ddproxy3 && !strcmp(ddproxy3->AgentID(), 
				"<non-graphic:drawingdisplaydata>")) {
      DisplayData* dd = ((GTkDrawingDD* )ddproxy3)->displayData();
      itsSlicePD->getPanelDisplay("xz")->addDisplayData(*dd);
    } else {
      Unref(args);
      postError(origin, "Argument 3 to \"SlicePD->add\" was not "
		"a displaydata agent", LogMessage::WARN);
      installNullLogSink();
      return "";
    }
    Unref(args);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
} 

char* GTkSlicePD::remove(Value* args) {
  static LogOrigin origin("GTkSlicePD", "remove");
  try {
    if (args->Type() != TYPE_RECORD) {
      postError(origin, "Argument to \"SlicePD->remove\" was not "
		"a record", LogMessage::WARN);
      return "";
    }
    Ref(args);
    recordptr rptr = args->RecordPtr(0);
    int c = 0;
    const char *key;
    const Value *ddagent1 = rptr->NthEntry(c++, key);
    const Value *ddagent2 = rptr->NthEntry(c++, key);
    const Value *ddagent3 = rptr->NthEntry(c, key);
    
    TkProxy* ddproxy1 = (TkProxy* )(global_store->GetProxy(ddagent1));
    TkProxy* ddproxy2 = (TkProxy* )(global_store->GetProxy(ddagent2));
    TkProxy* ddproxy3 = (TkProxy* )(global_store->GetProxy(ddagent3));
    // check it is a non-graphic:displaydata
    if (ddproxy1 && 
	!strcmp(ddproxy1->AgentID(), "<non-graphic:displaydata>")) {

      DisplayData* dd = ((GTkDisplayData* )ddproxy1)->displayData();
      itsSlicePD->getPanelDisplay("xy")->removeDisplayData(*dd);
    } else if (ddproxy1 && !strcmp(ddproxy1->AgentID(), 
				"<non-graphic:drawingdisplaydata>")) {
      DisplayData* dd = ((GTkDrawingDD* )ddproxy1)->displayData();
      itsSlicePD->getPanelDisplay("xy")->removeDisplayData(*dd);
    } else {
      Unref(args);
      postError(origin, "Argument 1 to \"SlicePD->remove\" was not "
		"an agent", LogMessage::WARN);
      return "";
    }
    if (ddproxy2 && 
	!strcmp(ddproxy2->AgentID(), "<non-graphic:displaydata>")) {

      DisplayData* dd = ((GTkDisplayData* )ddproxy2)->displayData();
      itsSlicePD->getPanelDisplay("zy")->removeDisplayData(*dd);
    } else if (ddproxy2 && !strcmp(ddproxy1->AgentID(), 
				"<non-graphic:drawingdisplaydata>")) {
      DisplayData* dd = ((GTkDrawingDD* )ddproxy2)->displayData();
      itsSlicePD->getPanelDisplay("zy")->removeDisplayData(*dd);
    } else {
      Unref(args);
      postError(origin, "Argument 2 to \"SlicePD->remove\" was not "
		"an agent", LogMessage::WARN);
      return "";
    }
    if (ddproxy3 && 
	!strcmp(ddproxy3->AgentID(), "<non-graphic:displaydata>")) {

      DisplayData* dd = ((GTkDisplayData* )ddproxy3)->displayData();
      itsSlicePD->getPanelDisplay("xz")->removeDisplayData(*dd);
    } else if (ddproxy3 && !strcmp(ddproxy3->AgentID(), 
				"<non-graphic:drawingdisplaydata>")) {
      DisplayData* dd = ((GTkDrawingDD* )ddproxy3)->displayData();
      itsSlicePD->getPanelDisplay("xz")->removeDisplayData(*dd);
    } else {
      Unref(args);
      postError(origin, "Argument 3 to \"SlicePD->remove\" was not "
		"an agent", LogMessage::WARN);
      return "";
    }
    Unref(args);
  } catch (const AipsError &x) {
    postError(origin, x);
  }  
  replyIfPending();
  installNullLogSink();
  return "";
} 

char* GTkSlicePD::getoptions(Value* args) {
  static LogOrigin origin("GTkSlicePD", "getoptions");
  try {
    Record rec = itsSlicePD->getOptions();
    GlishRecord grec;
    grec.fromRecord(rec);
    Value* retval = new Value(*(grec.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("options", retval);
    }    
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
} 

char* GTkSlicePD::setoptions(Value* args) {
  static LogOrigin origin("GTkSlicePD", "setoptions");
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
    refreshRequired = (itsSlicePD->setOptions(rec, outputOptions) ||
		       refreshRequired);
    if (refreshRequired && itsPixelCanvas->refreshAllowed()) {
      itsPixelCanvas->refresh();
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  return "";
}

char* GTkSlicePD::disabletools(Value* ) {
  static LogOrigin origin("GTkSlicePD", "disabletools");
  try {
    itsSlicePD->disableTools();
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char* GTkSlicePD::enabletools(Value* ) {
  static LogOrigin origin("GTkSlicePD", "enabletools");
  try {
    itsSlicePD->enableTools();
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkSlicePD::settoolkey(Value *args) {
  static LogOrigin origin("GTkWorldCanvas", "settoolkey");
  try {
    // check for number of arguments
    if ((args->Length() != 2) || (args->Type() != TYPE_RECORD)) {
      postError(origin, "Argument to \"SlicePD->settoolkey\" was not "
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
    itsSlicePD->setToolKey(toolname,(Display::KeySym)catchkey);
    Unref(args);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char *GTkSlicePD::setzoom(Value *args) {
  static LogOrigin origin("GTkSlicePD", "setzoom");
  installGTkLogSink();
  try {
    // check for number of arguments
    if ((args->Length() != 4) || (args->Type() != TYPE_RECORD)) {
      postError(origin, "Argument to \"SlicePD->setzoom\" was not "
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
    //itsZoomer->zoom(blc,trc);
    Unref(args);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char* GTkSlicePD::unzoom(Value* ) {
  static LogOrigin origin("GTkSlicePD", "unzoom");
  try {
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkSlicePD::status(Value *) {
  static LogOrigin origin("GTkSlicePD", "status");
  installGTkLogSink();
  try {
    GlishRecord grec;
    Record rec;
    // basic parameters
    itsSlicePD->activePanelDisplay()->getGeometry(rec);
    grec.fromRecord(rec);
#ifndef AIPS_64B
    grec.add("paneldisplayid",  Int(itsSlicePD));
#else
    Long dummy = Long(itsSlicePD);
    Int *dummy2 = (Int *)&dummy;
    grec.add("paneldisplayid", dummy2);
#endif
    //

    // linear and world coordinate system
    itsSlicePD->activePanelDisplay()->myWCLI->toStart();
    uInt i = 0;
    Vector<Int> tmpVec(itsSlicePD->activePanelDisplay()->myWCLI->len());

    while (!itsSlicePD->activePanelDisplay()->myWCLI->atEnd()) {
      WorldCanvas* wc = itsSlicePD->activePanelDisplay()->myWCLI->getRight();
#ifndef AIPS_64B      
      tmpVec(i) = (Int)wc;
      Long dummy = (Long)wc;
      Int dummy2 = static_cast<Int>(dummy);
      tmpVec(i) = dummy2;
#endif
      i++;
      (*(itsSlicePD->activePanelDisplay()->myWCLI))++;
    }
    grec.add("worldcanvasid",GlishArray(tmpVec));
    itsSlicePD->activePanelDisplay()->myWCLI->toStart();
    while (!itsSlicePD->activePanelDisplay()->myWCLI->atEnd()) {
      WorldCanvas* wc = itsSlicePD->activePanelDisplay()->myWCLI->getRight();
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
      
      Vector<String> units = itsSlicePD->activePanelDisplay()->wcHolder(wc)->worldAxisUnits();
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
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}
char* GTkSlicePD::precompute(Value* ) {
  static LogOrigin origin("GTkSlicePD", "precompute");
  try {
    itsSlicePD->precompute();
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}


void GTkSlicePD::operator()(const WCMotionEvent &) {
}

void GTkSlicePD::postEvent(const String& name, const GlishRecord& rec) {
  Value* retval = new Value(*(rec.value()));
  PostTkEvent(name.c_str(),retval);
  delete retval;
}

}
