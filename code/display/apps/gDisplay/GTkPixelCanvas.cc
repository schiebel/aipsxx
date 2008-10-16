//# GTkPixelCanvas.cc: GlishTk implementation of the PixelCanvas
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
//# $Id: GTkPixelCanvas.cc,v 19.5 2005/06/15 18:09:13 cvsmgr Exp $

#include <casa/aips.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishRecord.h>
#include <casa/Containers/Record.h>
#include <casa/System/Aipsrc.h>
#include <display/DisplayEvents/PCITFiddler.h>
#include <display/Display/ColormapDefinition.h>

#include "GTkColormap.h"
#include "GTkPixelCanvas.h"
#include "Glish/Reporter.h"
#include "gDisplay.h"

namespace casa {

#define InvalidArg( num )						\
	{								\
	global_store->Error( "invalid type for argument " #num );	\
	return;								\
	}

#define InvalidNumberOfArgs( num )					\
	{								\
	global_store->Error( "invalid number of arguments, " #num " expected" );\
	return;								\
	}

#define SETINIT								\
	if ( args->Type() != TYPE_RECORD )				\
		{							\
		global_store->Error("bad value");			\
		return;							\
		}							\
									\
	Ref( args );							\
	recordptr rptr = args->RecordPtr(0);				\
	int c = 0;							\
	const char *key;

#define SETVAL(var,condition)						\
	const Value *var      = rptr->NthEntry( c++, key );		\
	if ( ! ( condition) )						\
		InvalidArg(c-1);

#define SETDIM(var)							\
	SETVAL(var##_v_, var##_v_ ->Type() == TYPE_STRING &&		\
				var##_v_ ->Length() > 0   ||		\
				var##_v_ ->IsNumeric() )		\
	char var##_char_[30];						\
	charptr var = 0;						\
	if ( var##_v_ ->Type() == TYPE_STRING )				\
		var = ( var##_v_ ->StringPtr(0) )[0];			\
	else								\
		{							\
		sprintf(var##_char_,"%d", var##_v_ ->IntVal());		\
		var = var##_char_;					\
		}

#define SETSTR(var)							\
	SETVAL(var##_v_, var##_v_ ->Type() == TYPE_STRING &&		\
				var##_v_ ->Length() > 0 )		\
	charptr var = ( var##_v_ ->StringPtr(0) )[0];

#define CREATE_RETURN						\
	if ( ! ret || ! ret->IsValid() )			\
		{						\
		Value *err = ret->GetError();			\
		if ( err )					\
			{					\
			global_store->Error( err );		\
			Unref( err );				\
			}					\
		else						\
			global_store->Error( "tk widget creation failed" ); \
		}						\
	else							\
		ret->SendCtor("newtk");				\
								\
	SETDONE

#define SETDONE Unref(args);

GTkPixelCanvas::GTkPixelCanvas(ProxyStore *s, TkFrame *frame_, charptr width, 
			       charptr height, charptr relief, 
			       charptr borderwidth, charptr,
			       charptr, charptr, 
			       charptr background, charptr fill, 
			       const Value *mincolors, 
			       const Value *maxcolors, charptr maptype) :
  GTkDisplayProxy(s),
  fill_(0),
  holdcount_(0),
  refreshheld_(False),
  itsTestPattern(0),
  logging_(True) {

  frame = frame_;
  char *argv[18];

  // check frame exists, and has a window
  Tk_Window frameSelf = 0;
  if (!frame || !(frameSelf = frame->Self())) {
    throw(AipsError("The parent frame given to the pixelcanvas was invalid"));
  }

  // determine colormodel based on string argument
  Display::ColorModel colormodel = Display::Index;
  if (!strcmp(maptype, "index")) {
    colormodel = Display::Index;
  } else if (!strcmp(maptype, "rgb")) {
    colormodel = Display::RGB;
  } else if (!strcmp(maptype, "hsv")) {
    colormodel = Display::HSV;
  } else {
    throw(AipsError("Unknown maptype given to the pixelcanvas"));
  }

  // pull out min, max colors into useable array
  Int mincol[3], maxcol[3];
  if ((colormodel == Display::Index) && (mincolors->Length() == 1) &&
      (maxcolors->Length() == 1)) {
    int is_copy;
    mincolors->CoerceToIntArray(is_copy, 1, mincol);
    maxcolors->CoerceToIntArray(is_copy, 1, maxcol);
    itsInitialMaximumColors = maxcol[0];
  } else if (((colormodel == Display::RGB) || (colormodel == Display::HSV))
	     && (mincolors->Length() >= 1) && (maxcolors->Length() >=1)) {
    int is_copy;
    mincolors->CoerceToIntArray(is_copy, 3, mincol);
    maxcolors->CoerceToIntArray(is_copy, 3, maxcol);
  } else {
    throw(AipsError("An inconsistent combination of mincolors, maxcolors "
		    "and maptype was given to the pixelcanvas"));
  }
  String colorscheme;
  Aipsrc::find(colorscheme, "viewer.colorscheme", "screen");
  if (colorscheme == String("paper")) {
    itsOptionsPaperColors = True;
    setDeviceBackgroundColor("white");
    setDeviceForegroundColor("black");
  } else {
    itsOptionsPaperColors = False;
  }

  // attempt to build colortable, bail out if it fails
  if (!initColorTable(frameSelf, colormodel, mincol, maxcol)) {
    throw(AipsError("The pixelcanvas color request could not be satisfied"));
  }

  // prepare arguments for getting Tcl to configure the widget
  int c = 0;
  argv[c++] = "pixelcanvas";
  const char *itsname = NewName(frame->Self());
  argv[c] = new char[strlen(itsname) + 1];
  strcpy(argv[c++], itsname);
  argv[c++] = "-width";
  argv[c++] = (char*) width;
  argv[c++] = "-height";
  argv[c++] = (char*) height;
  argv[c++] = "-borderwidth";
  argv[c++] = (char*) borderwidth;
  argv[c++] = "-background";
  argv[c++] = (char*) background;
  argv[c++] = "-relief";
  argv[c++] = (char*) relief;

  // request Tcl to set things up
  tcl_ArgEval(this, c, argv);
  
  // get the Tk_Window handle
  self = Tk_NameToWindow(tcl, argv[1], root);

  if (!self) {
    throw(AipsError("The pixelcanvas could not be created because of a "
		    "Tcl error"));
  }

  agent_ID = "<graphic:pixelcanvas>";

  if (fill && fill[0] && strcmp(fill, "none")) {
    fill_ = strdup(fill);
  }
  
  frame->AddElement(this);
  frame->Pack();

  initCanvas();
  setClearColor((char *)background);
  
  // add event handlers
  Tk_CreateEventHandler(self,
			KeyPressMask | KeyReleaseMask |
			ButtonPressMask | ButtonReleaseMask |
			PointerMotionMask |
			ExposureMask | 
			VisibilityChangeMask |
			StructureNotifyMask,
			HandleWidgetEvent, ClientData(this));

  Tk_DefineCursor(self, Tk_GetCursor(tcl, self, "crosshair"));

  // insert procedures to deal with widget events:
  procs.Insert("status", 
	       new TkDisplayProc(this, &GTkPixelCanvas::w_status));
  procs.Insert("testpattern",
	       new TkDisplayProc(this, &GTkPixelCanvas::w_testpattern));
  procs.Insert("colortablesize",
	       new TkDisplayProc(this, &GTkPixelCanvas::w_colortablesize));
  procs.Insert("registercolormap",
	       new TkDisplayProc(this, &GTkPixelCanvas::w_registercolormap));
  procs.Insert("unregistercolormap",
	       new TkDisplayProc(this, &GTkPixelCanvas::w_unregistercolormap));
  procs.Insert("replacecolormap",
	       new TkDisplayProc(this, &GTkPixelCanvas::w_replacecolormap));
  procs.Insert("standardfiddler",
	       new TkDisplayProc(this, &GTkPixelCanvas::w_standardfiddler));
  procs.Insert("mapfiddler",
	       new TkDisplayProc(this, &GTkPixelCanvas::w_mapfiddler));

  procs.Insert("hold",
	       new TkDisplayProc(this, &GTkPixelCanvas::w_hold));
  procs.Insert("release",
	       new TkDisplayProc(this, &GTkPixelCanvas::w_release));

  procs.Insert("getoptions",
	       new TkDisplayProc(this, &GTkPixelCanvas::w_getoptions));
  procs.Insert("setoptions",
	       new TkDisplayProc(this, &GTkPixelCanvas::w_setoptions));

  procs.Insert("writexpm",
	       new TkDisplayProc(this, &GTkPixelCanvas::w_writexpixmap));
}

GTkPixelCanvas::~GTkPixelCanvas() {
  delete itsMapFiddler;itsMapFiddler=0;
  delete itsStdFiddler;itsStdFiddler=0;
  
  if (!exposeHandlerFirstTime_) {
    // we have exposed at least once, so free the graphics context
    XFreeGC(display_, gc_);
  }
  
  // this might have been made in a resize...
  if (havePixmap_) {
    Tk_FreePixmap(display_, pixmap_);
  }

  // stop event catching...
  Tk_DeleteEventHandler(self,
			KeyPressMask | KeyReleaseMask |
			ButtonPressMask | ButtonReleaseMask |
			PointerMotionMask |
			ExposureMask | 
			VisibilityChangeMask |
			StructureNotifyMask,
			HandleWidgetEvent, ClientData(this));

  // this definitely was made!
  pcctbl()->removeResizeCallback(ColorTableResizeCB, this);
  delete xpcctbl_;xpcctbl_=0;
  // finally, unregister ourselves from the gtk store...
  if (frame) {
    frame->RemoveElement(this);
    frame->Pack();
  }
  UnMap();

  if (fill_) {
    free_memory(fill_);
  }

}

extern "C" void GTkPixelCanvas_Create(ProxyStore *global_store, Value *args) {
  try {
    // a handle for the widget we will build
    GTkPixelCanvas *ret;
  
    // check for correct number of arguments
    if (args->Length() != 13) {
      global_store->Error("incorrect number of arguments to pixelcanvas");
      return;
    }

    // fetch arguments
    SETINIT
    SETVAL(parent, parent->IsAgentRecord())
    SETDIM(width)
    SETDIM(height)
    SETSTR(relief)
    SETDIM(borderwidth)
    SETDIM(padx)
    SETDIM(pady)
    SETSTR(foreground)
    SETSTR(background)
    SETSTR(fill)
    SETVAL(mincolors, mincolors->IsNumeric())
    SETVAL(maxcolors, maxcolors->IsNumeric())
    SETSTR(maptype)

    // make the agent
    TkProxy *agent = (TkProxy *)(global_store->GetProxy(parent));
    if (agent && !strcmp(agent->AgentID(), "<graphic:frame>")) {
      ret = new GTkPixelCanvas(global_store, (TkFrame *)agent, width, height,
			       relief, borderwidth, padx, pady,
			       foreground, background, fill, 
			       mincolors, maxcolors, maptype);
    } else {
      SETDONE
	global_store->Error("bad parent argument to pixelcanvas");
      return;
    }

    if (!ret || !ret->IsValid()) {
      Value *err = ret->GetError();
      if (err) {
	global_store->Error(err);
	Unref(err);
      } else {
	global_store->Error("pixelcanvas agent creation failed for "
			    "internal (unknown) reasons");
      }
    } else {
      ret->SendCtor("newtk");
    }
    Unref(args);
  } catch (const AipsError &x) {
    String message = 
      String("pixelcanvas agent creation failed:\n") +
      x.getMesg();
    global_store->Error(message.chars());
  } 
}

const char **GTkPixelCanvas::PackInstruction() {
  static char *ret[5];
  int c = 0;
  if (fill_) {
    ret[c++] = "-fill";
    ret[c++] = fill_;
    if (!strcmp(fill_, "both") ||
	!strcmp(fill_, frame->Expand()) ||
	frame->NumChildren() == 1 &&
	!strcmp(fill_, "y")) {
      ret[c++] = "-expand";
      ret[c++] = "true";
    } else {
      ret[c++] = "-expand";
      ret[c++] = "false";
    }
    ret[c++] = 0;
    return (const char **)ret;
  } else {
    return 0;
  }
}

int GTkPixelCanvas::CanExpand() const {
  if (fill_ && (!strcmp(fill_, "both")) ||
      !strcmp(fill_, frame->Expand()) ||
      frame->NumChildren() == 1 && !strcmp(fill_, "y")) {
    return 1;
  } else {
    return 0;
  }
}

char *GTkPixelCanvas::w_status(Value *) {
  static LogOrigin origin("GTkPixelCanvas", "w_status");
  installGTkLogSink();
  try {
    GlishRecord rec;
    // basic parameters
    rec.add("width", GlishArray(Int(width_)));
    rec.add("height", GlishArray(Int(height_)));
    rec.add("depth", GlishArray(Int(depth_)));
    switch(pcctbl()->colorModel()) {
    case Display::RGB:
      rec.add("maptype", "rgb");
      break;
    case Display::HSV:
      rec.add("maptype", "hsv");
      break;
    default:
      rec.add("maptype", "index");
      break;
    }
    
    // pixel density (dots per inch)
    Float xdpi, ydpi;
    pixelDensity(xdpi, ydpi);
    rec.add("xdpi", GlishArray(Float(xdpi)));
    rec.add("ydpi", GlishArray(Float(ydpi)));
    
    // color info
    rec.add("colortablesize", GlishArray(Int(pcctbl()->nColors())));
    rec.add("maxcolortablesize", GlishArray(Int(pcctbl()->nColors() + 
						pcctbl()->nSpareColors())));
    if (pcctbl()->colorModel() == Display::Index) {
      ColormapDefinition cmapdef;
      rec.add("builtincolormaps", GlishArray(cmapdef.builtinColormapNames()));
      ColormapManager cmm = pcctbl()->colormapManager();
      GlishRecord trec;
      Vector<String> names(cmm.nMaps());
      Vector<Int> sizes(cmm.nMaps());
      for (uInt i = 0; i < cmm.nMaps(); i++) {
	const Colormap *cmap = cmm.getMap(i);
	names(i) = cmap->name();
	sizes(i) = pcctbl()->getColormapSize(cmap);
      }
      trec.add("names", names);
      trec.add("sizes", sizes);
      rec.add("registeredcolormaps", trec);
    } else {
      Vector<Int> col(3);
      uInt n1, n2, n3;
      xpcctbl_->nColors(n1, n2, n3);
      col(0) = (Int)n1;
      col(1) = (Int)n2;
      col(2) = (Int)n3;
      rec.add("colorcubesize", GlishArray(col));
    }
    
    Value *retval = new Value(*(rec.value()));
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

char *GTkPixelCanvas::w_testpattern(Value *args) {
  static LogOrigin origin("GTkPixelCanvas", "w_testpattern");
  installGTkLogSink();
  try {
    if ((args->Length() != 0) && (args->Length() != 1)) {
      postError(origin, "Argument to \"pixelcanvas->testpattern\" was more "
		"than one argument", LogMessage::WARN);
      return "";
    }

    if (args->Length() == 1) {
      if ((args->Type() == TYPE_BOOL) || (args->Type() == TYPE_INT)) {
	if (args->BoolVal() && !itsTestPattern) {
	  // set testpattern on
	  itsTestPattern = new PCTestPattern;
	  addRefreshEventHandler(*itsTestPattern);
	  refresh();
	} else if (!args->BoolVal() && itsTestPattern) {
	  // set testpattern off
	  removeRefreshEventHandler(*itsTestPattern);
	  refresh();
	  delete itsTestPattern;
	  itsTestPattern = 0;
	}    
      } else {
	postError(origin, "Argument to \"pixelcanvas->testpattern\" was "
		  "not a boolean", LogMessage::WARN);
	return "";
      }
    }
    
    if (ReplyPending()) {
      Value *tkv;
      if (itsTestPattern) {
	tkv = new Value(glish_true);
      } else {
	tkv = new Value(glish_false);
      }
      Reply(tkv);
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}
 
char *GTkPixelCanvas::w_colortablesize(Value *args) {
  static LogOrigin origin("GTkPixelCanvas", "w_colortablesize");
  installGTkLogSink();
  try {
    if (args->Length() > 3) {
      postError(origin, "Too many arguments to \"pixelcanvas->"
		"colortablesize\" (must be 3 or less)", LogMessage::WARN);
      return "";
    }

    if (args->Length() > 0) {
      Value *ncolors = args;
      if (ncolors->IsNumeric() && (ncolors->Length() >= 1)) {
	if ((pcctbl()->colorModel() == Display::Index) &&
	    (ncolors->Length() == 1)) {
	  int is_copy;
	  int col[3];
	  ncolors->CoerceToIntArray(is_copy, 1, col);
	  pcctbl()->resize(col[0]);
	} else if ((pcctbl()->colorModel() == Display::RGB) ||
		   (pcctbl()->colorModel() == Display::HSV)) {
	  int is_copy;
	  int col[3];
	  ncolors->CoerceToIntArray(is_copy, 3, col);
	  pcctbl()->resize(col[0], col[1], col[2]);
	} else {
	  postError(origin, "Unexpected colormodel discovered in "
		    "\"pixelcanvas->colortablesize\"", LogMessage::WARN);
	  return "";
	}
      } else {
	postError(origin, "Argument/s to \"pixelcanvas->colortablesize\" "
		  "were not integers", LogMessage::WARN);
	return "";
      }
    }
    
    if (ReplyPending()) {
      Value *tkv;
      if (pcctbl()->colorModel() == Display::Index) {
	tkv = new Value(Int(pcctbl()->nColors()));
      } else {
	int col[3];
	uInt n1, n2, n3;
	xpcctbl_->nColors(n1, n2, n3);
	col[0] = (int)n1;
	col[1] = (int)n2;
	col[2] = (int)n3;
	tkv = new Value(col, 3);
      }
      Reply(tkv);
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char *GTkPixelCanvas::w_standardfiddler(Value *args) {
  static LogOrigin origin("GTkPixelCanvas", "standardfiddler");
  installGTkLogSink();
  try {
    if (!itsStdFiddler) {
      return "";
    }
    if ((args->Type() != TYPE_INT) || (args->Length() != 1)) {
      postError(origin, "Argument to \"pixelcanvas->standardfiddler\" was not "
		"an integer", LogMessage::WARN);
      return "";
    }
    Ref(args);
    int catchkey = (args->IntPtr(0))[0];
    itsStdFiddler->setKey((Display::KeySym)catchkey);
    Unref(args);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char *GTkPixelCanvas::w_mapfiddler(Value *args) {
  static LogOrigin origin("GTkPixelCanvas", "mapfiddler");
  installGTkLogSink();
  try {
    if (!itsMapFiddler) {
      return "";
    }
    if ((args->Type() != TYPE_INT) || (args->Length() != 1)) {
      postError(origin, "Argument to \"pixelcanvas->mapfiddler\" was not "
		"an integer", LogMessage::WARN);
      return "";
    }
    Ref(args);
    int catchkey = (args->IntPtr(0))[0];
    itsMapFiddler->setKey((Display::KeySym)catchkey);
    Unref(args);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
} 


char *GTkPixelCanvas::w_registercolormap(Value *args) {
  static LogOrigin origin("GTkPixelCanvas", "w_registercolormap");
  installGTkLogSink();
  try {
    if (!args->IsAgentRecord()) {
      postError(origin, "Number of arguments to \"pixelcanvas->"
		"registercolormap\" was not equal to 1", LogMessage::WARN);
      return "";
    }

    TkProxy *agent = (TkProxy *)(global_store->GetProxy(args));
    if (agent && !strcmp(agent->AgentID(), "<non-graphic:colormap>")) {
      Colormap *cmap = ((GTkColormap *)agent)->colormap();
      registerColormap(cmap);
    } else {
      postError(origin, "Unexpected argument type to \"pixelcanvas->"
		"registercolormap\"", LogMessage::WARN);
      return "";
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char *GTkPixelCanvas::w_unregistercolormap(Value *args) {
  static LogOrigin origin("GTkPixelCanvas", "w_unregistercolormap");
  installGTkLogSink();
  try {
    if (!args->IsAgentRecord()) {
      postError(origin, "Number of arguments to \"pixelcanvas->"
		"unregistercolormap\" was not equal to 1", LogMessage::WARN);
      return "";
    }
    
    TkProxy *agent = (TkProxy *)(global_store->GetProxy(args));
    if (agent && !strcmp(agent->AgentID(), "<non-graphic:colormap>")) {
      Colormap *cmap = ((GTkColormap *)agent)->colormap();
      unregisterColormap(cmap);
    } else {
      postError(origin, "Unexpected argument type to \"pixelcanvas->"
		"unregistercolormap\"", LogMessage::WARN);
      return "";
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char *GTkPixelCanvas::w_replacecolormap(Value *args) {
  static LogOrigin origin("GTkPixelCanvas", "w_replacecolormap");
  installGTkLogSink();
  try {
    if (args->Length() != 2) {
      postError(origin, "Number of arguments to \"pixelcanvas->"
		"replacecolormap\" was not equal to 2", LogMessage::WARN);
      return "";
    }

    // load the arguments
    recordptr rptr = args->RecordPtr(0);
    int c = 0;
    const char *key;
    Value *newcmapValue = rptr->NthEntry(c++, key);
    if (!newcmapValue->IsAgentRecord()) {
      postError(origin, "Unexpected 1st argument type to \"pixelcanvas->"
		"replacecolormap\"", LogMessage::WARN);
      return "";
    }
    Value *oldcmapValue = rptr->NthEntry(c++, key);
    if (!oldcmapValue->IsAgentRecord()) {
      postError(origin, "Unexpected 2nd argument type to \"pixelcanvas->"
		"replacecolormap\"", LogMessage::WARN);
      return "";
    }

    Colormap *newcmap = 0, *oldcmap = 0;
    TkProxy *agent = 0;

    agent = (TkProxy *)(global_store->GetProxy(newcmapValue));
    if (!agent || strcmp(agent->AgentID(), "<non-graphic:colormap>")) {
      postError(origin, "1st argument to \"pixelcanvas->replacecolormap\" "
		"was not a Colormap", LogMessage::WARN);
      return "";
    } else {
      newcmap = ((GTkColormap *)agent)->colormap();
    }
    agent = (TkProxy *)(global_store->GetProxy(oldcmapValue));
    if (!agent || strcmp(agent->AgentID(), "<non-graphic:colormap>")) {
      postError(origin, "2nd argument to \"pixelcanvas->replacecolormap\" "
		"was not a Colormap", LogMessage::WARN);
      return "";
    } else {
      oldcmap = ((GTkColormap *)agent)->colormap();
    }

    registerColormap(newcmap, oldcmap);

  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char *GTkPixelCanvas::w_hold(Value *) {
  holdcount_++;
  replyIfPending();
  installNullLogSink();
  return "";
}

char *GTkPixelCanvas::w_release(Value *) {
  static LogOrigin origin("GTkPixelCanvas", "w_release");
  installGTkLogSink();
  try {
    holdcount_--;
    if (holdcount_ <= 0) {
      holdcount_ = 0;
      if (refreshheld_) {
	refresh(heldreason_);
      }
      refreshheld_ = False;
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

void GTkPixelCanvas::fillColorTableSizeRecord(Record &rec) const {
  Int maxtblsize = pcctbl()->nColors() + pcctbl()->nSpareColors() - 1;
  if (pcctbl()->colorModel() == Display::Index) {
    Record colortablesize;
    colortablesize.define("dlformat", "colortablesize");
    colortablesize.define("listname", "Number of colors");
    colortablesize.define("ptype", "intrange");
    colortablesize.define("pmin", Int(2));
    colortablesize.define("pmax", maxtblsize);
    colortablesize.define("default", maxtblsize);
    colortablesize.define("value", Int(pcctbl()->nColors()));
    colortablesize.define("allowunset", False);
    rec.defineRecord("colortablesize", colortablesize);
  } else if (pcctbl()->colorModel() == Display::RGB) {
    if (pcctbl()->staticSize()) {
      return;
    }
    
    uInt nred, ngreen, nblue;
    pcctbl()->nColors(nred, ngreen, nblue);

    Record colorcuberedaxislength;
    colorcuberedaxislength.define("dlformat", "colorcuberedaxislength");
    colorcuberedaxislength.define("listname", "Color cube red axis length");
    colorcuberedaxislength.define("ptype", "intrange");
    colorcuberedaxislength.define("pmin", Int(1));
    colorcuberedaxislength.define("pmax", Int(Float(maxtblsize) / 
					      Float(ngreen * nblue)));
    colorcuberedaxislength.define("default", Int(4));
    colorcuberedaxislength.define("value", Int(nred));
    colorcuberedaxislength.define("allowunset", False);
    rec.defineRecord("colorcuberedaxislength", colorcuberedaxislength);
    
    Record colorcubegreenaxislength;
    colorcubegreenaxislength.define("dlformat", "colorcubegreenaxislength");
    colorcubegreenaxislength.define("listname", 
				    "Color cube green axis length");
    colorcubegreenaxislength.define("ptype", "intrange");
    colorcubegreenaxislength.define("pmin", Int(1));
    colorcubegreenaxislength.define("pmax", Int(Float(maxtblsize) / 
						Float(nred * nblue)));
    colorcubegreenaxislength.define("default", Int(4));
    colorcubegreenaxislength.define("value", Int(ngreen));
    colorcubegreenaxislength.define("allowunset", False);
    rec.defineRecord("colorcubegreenaxislength", colorcubegreenaxislength);
    
    Record colorcubeblueaxislength;
    colorcubeblueaxislength.define("dlformat", "colorcubeblueaxislength");
    colorcubeblueaxislength.define("listname", 
				   "Color cube blue axis length");
    colorcubeblueaxislength.define("ptype", "intrange");
    colorcubeblueaxislength.define("pmin", Int(1));
    colorcubeblueaxislength.define("pmax", Int(Float(maxtblsize) / 
					       Float(nred * ngreen)));
    colorcubeblueaxislength.define("default", Int(4));
    colorcubeblueaxislength.define("value", Int(nblue));
    colorcubeblueaxislength.define("allowunset", False);
    rec.defineRecord("colorcubeblueaxislength", colorcubeblueaxislength);
  } else if (pcctbl()->colorModel() == Display::HSV) {
    if (pcctbl()->staticSize()) {
      return;
    }
    uInt nhue, nsaturation, nvalue;
    pcctbl()->nColors(nhue, nsaturation, nvalue);
    
    Record colorcubehueaxislength;
    colorcubehueaxislength.define("dlformat", "colorcubehueaxislength");
    colorcubehueaxislength.define("listname", "Color cube hue axis length");
    colorcubehueaxislength.define("ptype", "intrange");
    colorcubehueaxislength.define("pmin", Int(1));
    colorcubehueaxislength.define("pmax", Int(Float(maxtblsize) / 
					      Float(nsaturation * nvalue)));
    colorcubehueaxislength.define("default", Int(4));
    colorcubehueaxislength.define("value", Int(nhue));
    colorcubehueaxislength.define("allowunset", False);
    rec.defineRecord("colorcubehueaxislength", colorcubehueaxislength);
    
    Record colorcubesaturationaxislength;
    colorcubesaturationaxislength.define("dlformat", 
					 "colorcubesaturationaxislength");
    colorcubesaturationaxislength.define("listname", "Color cube " 
					 "saturation axis length");
    colorcubesaturationaxislength.define("ptype", "intrange");
    colorcubesaturationaxislength.define("pmin", Int(1));
    colorcubesaturationaxislength.define("pmax", Int(Float(maxtblsize) / 
						     Float(nhue * nvalue)));
    colorcubesaturationaxislength.define("default", Int(4));
    colorcubesaturationaxislength.define("value", Int(nsaturation));
    colorcubesaturationaxislength.define("allowunset", False);
    rec.defineRecord("colorcubesaturationaxislength", 
		     colorcubesaturationaxislength);
    
    Record colorcubevalueaxislength;
    colorcubevalueaxislength.define("dlformat", "colorcubevalueaxislength");
    colorcubevalueaxislength.define("listname", 
				    "Color cube value axis length");
    colorcubevalueaxislength.define("ptype", "intrange");
    colorcubevalueaxislength.define("pmin", Int(1));
    colorcubevalueaxislength.define("pmax", Int(Float(maxtblsize) / 
						Float(nhue * nsaturation)));
    colorcubevalueaxislength.define("default", Int(4));
    colorcubevalueaxislength.define("value", Int(nvalue));
    colorcubevalueaxislength.define("allowunset", False);
    rec.defineRecord("colorcubevalueaxislength", colorcubevalueaxislength);
  }
}
 
char *GTkPixelCanvas::w_getoptions(Value *) {
  static LogOrigin origin("GTkPixelCanvas", "w_getoptions");
  installGTkLogSink();
  try {
    Record rec;

    fillColorTableSizeRecord(rec);

    Record papercolors;
    papercolors.define("dlformat", "papercolors");
    papercolors.define("listname", "Use paper colors?");
    papercolors.define("ptype", "boolean");

    String colorscheme;
    Aipsrc::find(colorscheme, "viewer.colorscheme", "screen");
    if (colorscheme == String("paper")) {
      papercolors.define("default", True);
    } else {
      papercolors.define("default", False);
    }

    papercolors.define("value", itsOptionsPaperColors);
    papercolors.define("allowunset", False);
    rec.defineRecord("papercolors", papercolors);

    GlishRecord grec;
    grec.fromRecord(rec);
    Value *retval = new Value(*(grec.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("options", retval);
    }
    // (was commented)
    //delete retval;
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char *GTkPixelCanvas::w_setoptions(Value *args) {
  static LogOrigin origin("GTkPixelCanvas", "w_setoptions");
  installGTkLogSink();
  try {
    GlishValue val(args);
    if (val.type() != GlishValue::RECORD) {
      postError(origin, "Argument to \"pixelcanvas->setoptions\" was not "
		"a record", LogMessage::WARN);
      return "";
    }
    GlishRecord grec(val);
    Record rec, recOut;
    grec.toRecord(rec);

    Int nc0(-1);
    Int nc1(-1), nc2(-1), nc3(-1);

    casa::Bool changed, error;
    casa::Bool ncolchanged = False;
    if (pcctbl()->colorModel() == Display::Index) {
      Int tblsize = pcctbl()->nColors();
      changed = readOptionRecord(tblsize, error, rec, "colortablesize");
      if (changed) {
	ncolchanged = True;
	nc0 = tblsize;
      }      
    } else if (pcctbl()->colorModel() == Display::RGB) {
      uInt nr, ng, nb;
      pcctbl()->nColors(nr, ng, nb);
      Int nred(nr), ngreen(ng), nblue(nb);
      casa::Bool lchange = False;
      lchange = (readOptionRecord(nred, error, rec, 
					"colorcuberedaxislength") || lchange);
      lchange = (readOptionRecord(ngreen, error, rec, 
					"colorcubegreenaxislength") || 
		       lchange);
      lchange = (readOptionRecord(nblue, error, rec, 
					"colorcubeblueaxislength") || lchange);
      if (lchange) {
	ncolchanged = True;
	nc1 = nred;
	nc2 = ngreen;
	nc3 = nblue;
      } 
    } else if (pcctbl()->colorModel() == Display::HSV) {
      uInt nh, ns, nv;
      pcctbl()->nColors(nh, ns, nv);
      Int nhue(nh), nsaturation(ns), nvalue(nv);
      casa::Bool lchange = False;
      lchange = (readOptionRecord(nhue, error, rec, 
					"colorcubehueaxislength") || lchange);
      lchange = (readOptionRecord(nsaturation, error, rec, 
					"colorcubesaturationaxislength") || 
		       lchange);
      lchange = (readOptionRecord(nvalue, error, rec, 
					"colorcubevalueaxislength") ||
		       lchange);
      if (lchange) {
	ncolchanged = True;
	nc1 = nhue;
	nc2 = nsaturation;
	nc3 = nvalue;
      }
    }

    changed = readOptionRecord(itsOptionsPaperColors, error, rec,
			       "papercolors");
    if (changed) {
      if (itsOptionsPaperColors) {
	setDeviceBackgroundColor("white");
	setDeviceForegroundColor("black");
      } else {
	setDeviceBackgroundColor("black");
	setDeviceForegroundColor("white");
      }
      setClearColor(deviceBackgroundColor());
      refresh();
    }
    if (nc0 > -1) {
      pcctbl()->resize(nc0);
    } else if ((nc1 > -1) && (nc2 > -1) && (nc3 > -1)) {
      pcctbl()->resize(nc1, nc2, nc3);
    }
    if (ncolchanged) {
      fillColorTableSizeRecord(recOut);
    }
    if (recOut.nfields() > 0) {
      grec.fromRecord(recOut);
      Value *retval = new Value(*(grec.value()));
      if (ReplyPending()) {
	Reply(retval);
      } else {
	PostTkEvent("contextoptions", retval);
      }
      //delete retval;
    } 

    replyIfPending();

  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char *GTkPixelCanvas::w_writexpixmap(Value *args) {
  static LogOrigin origin("GTkPixelCanvas", "writexpixmap");
  installGTkLogSink();
  try {
    if ((args->Type() != TYPE_STRING) || (args->Length() != 1)) {
      postError(origin, "Argument to \"pixelcanvas->writebitmap\" was not "
		"a single string", LogMessage::WARN);
      return "";
    }
    Ref(args);
    String filename = args->StringVal();
    writeXPixmap(filename);
    Unref(args);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}



void GTkPixelCanvas::HandleWidgetEvent(ClientData data, XEvent *ev) {

 static LogOrigin origin("GTkPixelCanvas", "HandleWidgetEvent");
 GTkPixelCanvas *v = (GTkPixelCanvas *)data;
 try {

  // check window exists:
  if (!v->windowExists()) {
    return;
  }

  switch (ev->type) {
  case ConfigureNotify:
    if (ev->xconfigure.width  < Int(v->width()) ||
    	ev->xconfigure.height < Int(v->height()) ) {
      v->exposeHandler_();
    }
    break;

  case MapNotify:
    v->callRefreshEventHandlers(Display::UserCommand);
    break;

  case Expose:
    if (ev->xexpose.count == 0) {
      v->exposeHandler_();
    }
    break;
    
  case KeyPress:
  case KeyRelease:
    {
      casa::Bool keystate = (ev->type == KeyPress ? True : False);
      uInt state = ev->xkey.state;
      uInt keycode = ev->xkey.keycode;
      Int index = 0;
      if (state & ShiftMask) index = 1;
      else if (state & ControlMask) index = ControlMapIndex;
      else if (state & LockMask) index = LockMapIndex;
      else if (state & Mod1Mask) index = Mod1MapIndex;
      else if (state & Mod2Mask) index = Mod2MapIndex;
      else if (state & Mod3Mask) index = Mod3MapIndex;
      else if (state & Mod4Mask) index = Mod4MapIndex;
      else if (state & Mod5Mask) index = Mod5MapIndex;
      
      uLong keysym = XKeycodeToKeysym(v->display(), keycode, index);
      if (keysym == 0) {
        keysym = XKeycodeToKeysym(v->display(), keycode, 0);
      }
      
#ifdef XK_KP_Home
#ifdef XK_KP_Delete
      // Handle numlock.  Some HP's may not have these keysyms defined and
      // hence could not generate a keysym to trigger this numlock test.
      if ((state & 0x0010) && (keysym >= XK_KP_Home) && 
	  (keysym <= XK_KP_Delete)) {
	keysym = XKeycodeToKeysym(v->display(), keycode, 1);
      }
#endif
#endif
      
      v->callPositionEventHandlers((Display::KeySym) keysym,
                                   keystate,
                                   ev->xkey.x,
                                   v->height() - 1 - ev->xkey.y,
                                   ev->xkey.state);
    }
    break;
      
  case ButtonPress:
  case ButtonRelease:
    {
      Display::KeySym ks = Display::K_Pointer_Button1;
      switch (ev->xbutton.button) {
      case Button1: ks = Display::K_Pointer_Button1; break;
      case Button2: ks = Display::K_Pointer_Button2; break;
      case Button3: ks = Display::K_Pointer_Button3; break;
      case Button4: ks = Display::K_Pointer_Button4; break;
      case Button5: ks = Display::K_Pointer_Button5; break;
      }
      v->callPositionEventHandlers(ks,
                                   (ev->type == ButtonPress ? True : False),
                                   ev->xbutton.x,
                                   v->height() - 1 - ev->xbutton.y,
                                   ev->xbutton.state);
    }
    break;
 
  case MotionNotify:
    v->callMotionEventHandlers(ev->xmotion.x,
                               v->height() - 1 - ev->xmotion.y,
                               ev->xmotion.state);
    break;

  default:
    ;
  }

 }	// try
 catch (const AipsError &x)  { v->postError(origin, x);  } 

}

void GTkPixelCanvas::ColorTableResizeCB(PixelCanvasColorTable *,
					uInt, void *ClientData,
					Display::RefreshReason reason) {
  GTkPixelCanvas *xpc = (GTkPixelCanvas *)ClientData;
  if (!xpc->refreshAllowed()) {
    return;
  }

  if ((reason == Display::ColormapChange) && 
      (xpc->visual_->c_class != PseudoColor) &&
      (xpc->visual_->c_class != StaticColor)) {
    reason = Display::ColorTableChange;
  }

  /*
  if ((reason == Display::ClearPriorToColorChange) &&
      ((xpc->visual_->c_class == PseudoColor) ||
       (xpc->visual_->c_class == StaticColor))) {
  */
  if (reason == Display::ClearPriorToColorChange) {
    //Display::DrawBuffer buf = xpc->drawBuffer();
    //xpc->setDrawBuffer(Display::FrontAndBackBuffer);
    //xpc->clear();
    //xpc->setDrawBuffer(buf);
  } else if (reason != Display::ColormapChange) {
    //xpc->refresh(reason);
    xpc->callRefreshEventHandlers(reason);
    if (xpc->drawBuffer() == Display::DefaultBuffer) {
      xpc->copyBackBufferToFrontBuffer();
    }
  } 
}

void GTkPixelCanvas::exposeHandler_(Display::RefreshReason reason) {

  if (exposeHandlerFirstTime_) {
    exposeHandlerFirstTime_ = False;
    drawWindow_ = Tk_WindowId(self);

    gc_ = XCreateGC(display_, Tk_WindowId(self), 0, 0);
    
    setClearColor(XBlackPixelOfScreen(screen()));
  }

  casa::Bool sizeChanged = resize_();

  if (sizeChanged) {
    setDrawBuffer(Display::FrontAndBackBuffer);
    clear();
    setDrawBuffer(Display::BackBuffer);
    callRefreshEventHandlers(Display::PixelCoordinateChange);
  }

  copyBackBufferToFrontBuffer();
  setDrawBuffer(Display::FrontBuffer);
  callRefreshEventHandlers(Display::BackCopiedToFront);
}
 
casa::Bool GTkPixelCanvas::resize_() {
  casa::Bool resized = False;

  Int w = Tk_Width(self);
  Int h = Tk_Height(self);
  AlwaysAssert((w > 0) && (h > 0), AipsError);
  uInt dh;
  if ((uInt)w != width_ || (uInt)h != height_) {
    dh = h - height_;
    width_ = w;
    height_ = h;

    if (havePixmap_) {
      Tk_FreePixmap(display_, pixmap_);
    }
    // create new pixmap_ for drawing into:
    pixmap_ = Tk_GetPixmap(display_, Tk_WindowId(self),
			   width_, height_, depth_);
    havePixmap_ = True;
    
    resized = True;
  }

  return resized;
}

void GTkPixelCanvas::refresh(const Display::RefreshReason &reason,
			     const casa::Bool &explicitrequest) {
  if (!refreshAllowed()) {
    return;
  }
  clear();
  if (holdcount_) {
    if (!refreshheld_) {
      refreshheld_ = True;
      heldreason_ = reason;
    }
  } else {
    X11PixelCanvas::refresh(reason, explicitrequest);
  }
}

void GTkPixelCanvas::initCanvas() {

  setImageCacheStrategy(Display::ServerAlways);

  itsStdFiddler = new PCITFiddler(this, PCITFiddler::StretchAndShift,
				  Display::K_Pointer_Button2);
  itsMapFiddler = new PCITFiddler(this, PCITFiddler::BrightnessAndContrast,
				  Display::K_None);
}

//  SimpleOrderedMap<uLong, X11PixelCanvasColorTable *>
//    GTkPixelCanvas::itsXPCCTsIndex((X11PixelCanvasColorTable *)NULL);
//  SimpleOrderedMap<uLong, X11PixelCanvasColorTable *>
//    GTkPixelCanvas::itsXPCCTsRGB((X11PixelCanvasColorTable *)NULL);
//  SimpleOrderedMap<uLong, X11PixelCanvasColorTable *>
//    GTkPixelCanvas::itsXPCCTsHSV((X11PixelCanvasColorTable *)NULL);
casa::Bool GTkPixelCanvas::initColorTable(Tk_Window fself, 
				    Display::ColorModel colormodel,
				    Int *mincolors, Int *maxcolors) {
  XVisualInfo vinfo = X11VisualInfoFromVisual(Tk_Display(fself),
					      Tk_Visual(fself));
  int vclass = vinfo.c_class;
  if ((vclass != PseudoColor) && (vclass != TrueColor)) {
    throw(AipsError("A PseudoColor or TrueColor visual could not be "
		    "acquired."));
  }
  
  casa::Bool madeNewTable = False;
  //X11PixelCanvasColorTable *pctbl = 0;
  if (colormodel == Display::Index) {    
    //      if (!itsXPCCTsIndex.isDefined(uLong(Tk_Colormap(fself)))) {
    //        pctbl = new X11PixelCanvasColorTable(Tk_Screen(fself),
    //  					   Display::Index,
    //  					   Display::MinMax,
    //  					   Tk_Colormap(fself),
    //  					   Tk_Visual(fself),
    //  					   mincolors[0], maxcolors[0]);
    //        madeNewTable = True;
    //        itsXPCCTsIndex.define(uLong(Tk_Colormap(fself)), pctbl);
    //        xpcctbl_ = pctbl;
    //      } else {
    //        xpcctbl_ = itsXPCCTsIndex(uLong(Tk_Colormap(fself)));
    //      }
    xpcctbl_ = new X11PixelCanvasColorTable(Tk_Screen(fself),
					    Display::Index,
					    Display::MinMax,
					    Tk_Colormap(fself),
					    Tk_Visual(fself),
					    mincolors[0], maxcolors[0]);
  } else if (colormodel == Display::RGB) {
    //      if (!itsXPCCTsRGB.isDefined(uLong(Tk_Colormap(fself)))) {
    //        pctbl = new X11PixelCanvasColorTable(Tk_Screen(fself),
    //  					   colormodel,
    //  					   Display::MinMax,
    //  					   Tk_Colormap(fself),
    //  					   Tk_Visual(fself),
    //  					   mincolors[0], mincolors[1],
    //  					   mincolors[2], maxcolors[0],
    //  					   maxcolors[1], maxcolors[2]);
    //        madeNewTable = True;
    //        itsXPCCTsRGB.define(uLong(Tk_Colormap(fself)), pctbl);
    //        xpcctbl_ = pctbl;
    //      } else {
    //        xpcctbl_ = itsXPCCTsRGB(uLong(Tk_Colormap(fself)));
    //      }    
    xpcctbl_ = new X11PixelCanvasColorTable(Tk_Screen(fself),
					    colormodel,
					    Display::MinMax,
					    Tk_Colormap(fself),
					    Tk_Visual(fself),
					    mincolors[0], mincolors[1],
					    mincolors[2], maxcolors[0],
					    maxcolors[1], maxcolors[2]);
    
  } else if (colormodel == Display::HSV) {
    //      if (!itsXPCCTsHSV.isDefined(uLong(Tk_Colormap(fself)))) {
    //        pctbl = new X11PixelCanvasColorTable(Tk_Screen(fself),
    //  					   colormodel,
    //  					   Display::MinMax,
    //  					   Tk_Colormap(fself),
    //  					   Tk_Visual(fself),
    //  					   mincolors[0], mincolors[1],
    //  					   mincolors[2], maxcolors[0],
    //  					   maxcolors[1], maxcolors[2]);
    //        madeNewTable = True;
    //        itsXPCCTsHSV.define(uLong(Tk_Colormap(fself)), pctbl);
    //        xpcctbl_ = pctbl;
    //      } else {
    //        xpcctbl_ = itsXPCCTsHSV(uLong(Tk_Colormap(fself)));
    //      }
    xpcctbl_ = new X11PixelCanvasColorTable(Tk_Screen(fself),
					    colormodel,
					    Display::MinMax,
					    Tk_Colormap(fself),
					    Tk_Visual(fself),
					    mincolors[0], mincolors[1],
					    mincolors[2], maxcolors[0],
					    maxcolors[1], maxcolors[2]);
  }
  // at the moment we always create a new ColorTable for a new PixelCanvas
  madeNewTable = True;
  // we got to here, so we've got a ColorTable ready for use
  display_ = Tk_Display(fself);
  visual_ = Tk_Visual(fself);
  screen_ = Tk_Screen(fself);
  depth_ = xpcctbl_->depth();
  xpcctbl_->addResizeCallback(ColorTableResizeCB, this);  
  if (pcctbl()->colorModel() == Display::Index) {
    if (madeNewTable) {
      // better register the default colormap
      pcctbl()->registerColormap(pcctbl()->defaultColormap());
      setColormap(pcctbl()->defaultColormap());
      defaultColormapActive_ = True;
    } else {
      // better determine if the default colormap is active
      ColormapManager cmm = pcctbl()->colormapManager();
      if ((cmm.nMaps() == 1) && (cmm.getMap(0) == 
				 pcctbl()->defaultColormap())) {
	defaultColormapActive_ = True;
      } else {
	defaultColormapActive_ = False;
      }
      setColormap((Colormap *)(cmm.getMap(0)));
    }
  }
  return True;
}

}
