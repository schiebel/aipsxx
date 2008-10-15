//# XTkPixelCanvas.cc: GlishTk implementation of the PixelCanvas
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
//# $Id: XTkPixelCanvas.cc,v 1.5 2006/05/31 14:10:28 gvandiep Exp $

#include <casa/aips.h>
#include <casa/System/Aipsrc.h>
#include <display/DisplayEvents/PCITFiddler.h>
#include <display/Display/ColormapDefinition.h>

#include <display/Display/XTkPixelCanvas.h>

namespace casa {

/*
XTkPixelCanvas::XTkPixelCanvas(TkFrame *frame_, charptr width, 
			       charptr height, charptr relief, 
			       charptr borderwidth, charptr,
			       charptr, charptr, 
			       charptr background, charptr fill, 
			       const Value *mincolors, 
			       const Value *maxcolors, charptr maptype) :
*/

XTkPixelCanvas::XTkPixelCanvas(Tcl_Interp* tcl, String tkPath,
			       Vector<Int> mincolors,
			       Vector<Int> maxcolors,
			       String maptype,
			       String width,  String height,
			       String relief, String borderwidth, 
			       String background) :
  tcl_(tcl),
  tkPath_(tkPath),
  tkWin_(0),
  parentWin_(0),
  rootWin_(0),
  testPattern_(0) {
  
  String::size_type pos = tkPath_.find_last_of('.');
  if(pos==String::npos) throw AipsError("XTkPC: Invalid widget pathname");
  
  parentPath_ = tkPath_.substr(0, pos);
  if(parentPath_=="") parentPath_=".";
  
  rootWin_ = Tk_MainWindow(tcl_);
  if(rootWin_==0) throw AipsError("XTkPixelCanvas: Tk not initialized");

  
  Char parentpath[parentPath_.length()+1];	// (C strings are a pain...).
  strcpy(parentpath, parentPath_.c_str());
  
  parentWin_ = Tk_NameToWindow(tcl_, parentpath, rootWin_);
  
  if(parentWin_==0) throw AipsError("Invalid parent frame for XTkPixelCanvas");

  

  // Create the custom Tk widget: invokes TkPixelCanvas constructor
  // via TkPixelCanvas::ClassCmd().
    
  evalTcl(tcl,  "pixelcanvas " + tkPath_ + " -width " + width + 
		" -height " + height + " -borderwidth " + borderwidth +
		" -background " + background + " -relief " + relief);
  
  
  Char tkpath[tkPath_.length()+1]; strcpy(tkpath, tkPath_.c_str());
  tkWin_ = Tk_NameToWindow(tcl, tkpath, rootWin_);
  if (tkWin_==0) throw AipsError("XTkPixelCanvas: Unable to create Tk widget");
  
  evalTcl(tcl, "pack " + tkPath_ + " -fill both -expand true");
  
  
  // Initialize color table for the PixelCanvas
  
  Display::ColorModel colormodel = Display::Index;
  if(maptype=="index")    colormodel = Display::Index;
  else if(maptype=="rgb") colormodel = Display::RGB;
  else if(maptype=="hsv") colormodel = Display::HSV;
  else throw(AipsError("Unknown maptype given to XTkPixelCanvas"));

  initColorTable(colormodel, mincolors, maxcolors);
  	//#dk: also initializes important X11PC-level prot'd vars:
	// (display_, visual_, screen_, and depth_...).

  String colorscheme;
  Aipsrc::find(colorscheme, "viewer.colorscheme", "screen");
  paperColors_ = (colorscheme=="paper");
  if (paperColors_) {
    setDeviceBackgroundColor("white");
    setDeviceForegroundColor("black");  }
    
  setClearColor(background);
  
  initCanvas();
  
  // add event handlers
  Tk_CreateEventHandler(tkWin_,
			KeyPressMask | KeyReleaseMask |
			ButtonPressMask | ButtonReleaseMask |
			PointerMotionMask |
			ExposureMask | 
			VisibilityChangeMask |
			StructureNotifyMask,
			HandleWidgetEvent, ClientData(this));

  
  Tk_DefineCursor(tkWin_, Tk_GetCursor(tcl, tkWin_, "crosshair"));  }



XTkPixelCanvas::~XTkPixelCanvas() {
  delete itsMapFiddler; itsMapFiddler=0;
  delete itsStdFiddler; itsStdFiddler=0;
  
  if (!exposeHandlerFirstTime_) {
    // we have exposed at least once, so free the graphics context
    XFreeGC(display_, gc_);
  }
  
  // this might have been made in a resize...
  if (havePixmap_) {
    Tk_FreePixmap(display_, pixmap_);
  }

  // stop event catching...
  Tk_DeleteEventHandler(tkWin_,
			KeyPressMask | KeyReleaseMask |
			ButtonPressMask | ButtonReleaseMask |
			PointerMotionMask |
			ExposureMask | 
			VisibilityChangeMask |
			StructureNotifyMask,
			HandleWidgetEvent, ClientData(this));

  // this definitely was made!
  pcctbl()->removeResizeCallback(ColorTableResizeCB, this);
  delete xpcctbl_; xpcctbl_=0;  }


    
Int XTkPixelCanvas::evalTcl(Tcl_Interp* tcl, const String& cmdStr) {
  // Evoke Tcl_Eval on aips++ String form of cmdStr.
  Char cmd[cmdStr.length()+1];  strcpy(cmd, cmdStr.c_str());
  return Tcl_Eval(tcl, cmd);  }
  


void XTkPixelCanvas::fillColorTableSizeRecord(Record &rec) const {
  
  if (pcctbl()->colorModel() != Display::Index) return;
  Int maxtblsize = pcctbl()->nColors() + pcctbl()->nSpareColors() - 1;
  
  Record colortablesize;
  colortablesize.define("dlformat", "colortablesize");
  colortablesize.define("listname", "Number of colors");
  colortablesize.define("ptype", "intrange");
  colortablesize.define("pmin", 2);
  colortablesize.define("pmax", maxtblsize);
  colortablesize.define("default", maxtblsize);
  colortablesize.define("value", Int(pcctbl()->nColors()));
  colortablesize.define("allowunset", False);
  rec.defineRecord("colortablesize", colortablesize);  }


void XTkPixelCanvas::HandleWidgetEvent(ClientData data, XEvent *ev) {

 XTkPixelCanvas *v = (XTkPixelCanvas *)data;
 try {

  if (!v->windowExists()) return;
	// (Don't respond if widget construction failed).


  switch (ev->type) {
  
  case ConfigureNotify:
    if (ev->xconfigure.width  < Int(v->width()) ||
    	ev->xconfigure.height < Int(v->height()) )  v->exposeHandler_();
    break;

  case MapNotify:
    v->callRefreshEventHandlers(Display::UserCommand);
    break;

  case Expose:
    if (ev->xexpose.count == 0)  v->exposeHandler_();
    break;
    
  case KeyPress:
  case KeyRelease: {
      Bool keystate = (ev->type == KeyPress ? True : False);
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
        keysym = XKeycodeToKeysym(v->display(), keycode, 0);  }
      
#ifdef XK_KP_Home
#ifdef XK_KP_Delete
      // Handle numlock.  Some HP's may not have these keysyms defined and
      // hence could not generate a keysym to trigger this numlock test.
      if ((state & 0x0010) && (keysym >= XK_KP_Home) && 
	  (keysym <= XK_KP_Delete)) {
	keysym = XKeycodeToKeysym(v->display_, keycode, 1);
      }
#endif
#endif
      
      v->callPositionEventHandlers((Display::KeySym) keysym,
                                   keystate,
                                   ev->xkey.x,
                                   v->height() - 1 - ev->xkey.y,
                                   ev->xkey.state);  }
    break;
      
  case ButtonPress:
  case ButtonRelease:  {
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
                                   ev->xbutton.state);  }
    break;
 
  case MotionNotify:
    v->callMotionEventHandlers(ev->xmotion.x,
                               v->height() - 1 - ev->xmotion.y,
                               ev->xmotion.state);
    break;

  default: ;  }  }
  
 catch (const AipsError &x)  { 
   cerr<<"***XTkPixelCanvas: "<<x.getMesg()<<"***"<<endl;  }  }
 

 
void XTkPixelCanvas::ColorTableResizeCB(PixelCanvasColorTable *,
					uInt, void *ClientData,
					Display::RefreshReason reason) {
  
  XTkPixelCanvas *xpc = (XTkPixelCanvas *)ClientData;
  
  if (!xpc->refreshAllowed()) return;
  
  if (reason == Display::ColormapChange && 
      xpc->visual_->c_class != PseudoColor &&
      xpc->visual_->c_class != StaticColor) {
    reason = Display::ColorTableChange;  }

  if (reason != Display::ColormapChange) {
    xpc->callRefreshEventHandlers(reason);
    if (xpc->drawBuffer() == Display::DefaultBuffer) {
      xpc->copyBackBufferToFrontBuffer();  }  }  }

      
      
void XTkPixelCanvas::exposeHandler_(Display::RefreshReason reason) {

  if (exposeHandlerFirstTime_) {
  
    //#dk note: I think this can be done in XTkPC c'tor -- if so, do it.
    // Failure to complete PC initialization right away may have have
    // caused certain crashes in the past....
    exposeHandlerFirstTime_ = False;
    drawWindow_ = Tk_WindowId(tkWin_);

    gc_ = XCreateGC(display_, Tk_WindowId(tkWin_), 0, 0);
    
    setClearColor(XBlackPixelOfScreen(screen()));  }

  Bool sizeChanged = resize_();

  if (sizeChanged) {
    setDrawBuffer(Display::FrontAndBackBuffer);
    clear();
    setDrawBuffer(Display::BackBuffer);
    callRefreshEventHandlers(Display::PixelCoordinateChange);
  }

  copyBackBufferToFrontBuffer();
  setDrawBuffer(Display::FrontBuffer);
  callRefreshEventHandlers(Display::BackCopiedToFront);  }
 
Bool XTkPixelCanvas::resize_() {
  Bool resized = False;

  Int w = Tk_Width(tkWin_);
  Int h = Tk_Height(tkWin_);
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
    pixmap_ = Tk_GetPixmap(display_, Tk_WindowId(tkWin_),
			   width_, height_, depth_);
    havePixmap_ = True;
    
    resized = True;
  }

  return resized;  }

  
void XTkPixelCanvas::refresh(const Display::RefreshReason &reason,
			     const Bool &explicitrequest) {
  if (!refreshAllowed())  return;
  X11PixelCanvas::refresh(reason, explicitrequest);  }

void XTkPixelCanvas::initCanvas() {

  setImageCacheStrategy(Display::ServerAlways);

  itsStdFiddler = new PCITFiddler(this, PCITFiddler::StretchAndShift,
				  Display::K_Pointer_Button2);
  itsMapFiddler = new PCITFiddler(this, PCITFiddler::BrightnessAndContrast,
				  Display::K_None);  }


void XTkPixelCanvas::initColorTable(Display::ColorModel colormodel,
				    Vector<Int> mincolors,
				    Vector<Int> maxcolors) {
  
  XVisualInfo vinfo = X11VisualInfoFromVisual(Tk_Display(parentWin_),
					      Tk_Visual(parentWin_));
  
  int vclass = vinfo.c_class;
  if ((vclass != PseudoColor) && (vclass != TrueColor)) {
    throw(AipsError("A PseudoColor or TrueColor visual could not be "
		    "acquired."));  }

		      
  if(colormodel == Display::Index &&
     mincolors.nelements()==1 && maxcolors.nelements()==1) {
    
    xpcctbl_ = new X11PixelCanvasColorTable(
		   Tk_Screen(parentWin_), colormodel, Display::MinMax,
		   Tk_Colormap(parentWin_), Tk_Visual(parentWin_),
		   mincolors[0], maxcolors[0]);  }

  
  else if( (colormodel == Display::RGB || colormodel == Display::HSV) &&
	    mincolors.nelements()==3 && maxcolors.nelements()==3 ) {
    
    xpcctbl_ = new X11PixelCanvasColorTable(
		   Tk_Screen(parentWin_), colormodel, Display::MinMax,
		   Tk_Colormap(parentWin_), Tk_Visual(parentWin_),
		   mincolors[0], mincolors[1], mincolors[2],
		   maxcolors[0], maxcolors[1], maxcolors[2]);  }


  else throw AipsError("Invalid colormodel"); 
  
     
  display_ = Tk_Display(parentWin_);
  visual_ = Tk_Visual(parentWin_);
  screen_ = Tk_Screen(parentWin_);
  depth_ = xpcctbl_->depth();
  xpcctbl_->addResizeCallback(ColorTableResizeCB, this);  
  
  if (pcctbl()->colorModel() == Display::Index) {
      // better register the default colormap
      pcctbl()->registerColormap(pcctbl()->defaultColormap());
      setColormap(pcctbl()->defaultColormap());
      defaultColormapActive_ = True;  }  }



} //# NAMESPACE CASA - END
