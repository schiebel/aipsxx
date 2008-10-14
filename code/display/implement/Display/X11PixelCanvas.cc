//# X11PixelCanvas.cc: Class defining PixelCanvas for X Windows
//# Copyright (C) 1995,1996,1997,1998,1999,2000,2001,2002,2003
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
//# $Id: X11PixelCanvas.cc,v 19.4 2005/06/15 17:56:44 cvsmgr Exp $

#include <casa/iostream.h>


#include <X11/Xatom.h>
#include <graphics/X11/X_enter.h>
#include <X11/keysym.h>
#include <Xm/Frame.h>
#include <Xm/Form.h>
#include <Xm/DrawingA.h>
extern "C" { 
#include <X11/xpm.h>
}
#include <graphics/X11/X_exit.h>


#include <casa/aips.h>
#include <casa/Logging/LogIO.h>
#include <scimath/Mathematics.h>
#include <casa/math.h>
#include <casa/string.h>
#include <display/Display/X11PixelCanvas.h>
#include <display/Display/X11PCLimits.h>
#include <display/Display/X11PCDLClear.h>
#include <display/Display/X11PCDLClearRegion.h>
#include <display/Display/X11PCDLDisable.h>
#include <display/Display/X11PCDLEnable.h>
#include <display/Display/X11PCDLFilledRectangle.h>
#include <display/Display/X11PCDLGraphicsContext.h>
#include <display/Display/X11PCDLLine.h>
#include <display/Display/X11PCDLLoadIdentity.h>
#include <display/Display/X11PCDLMaskedImage.h>
#include <display/Display/X11PCDLMaskedPixmap.h>
#include <display/Display/X11PCDLPixmap.h>
#include <display/Display/X11PCDLPoint.h>
#include <display/Display/X11PCDLPopMatrix.h>
#include <display/Display/X11PCDLPushMatrix.h>
#include <display/Display/X11PCDLSetClearColor.h>
#include <display/Display/X11PCDLSetClipWin.h>
#include <display/Display/X11PCDLText.h>
#include <display/Display/X11PCDLTranslate.h>

namespace casa { //# NAMESPACE CASA - BEGIN

template <class T>
void X11PixelCanvas_drawImage(X11PixelCanvas * xpc,
			      const Matrix<T> &data,
			      Int xoffset, Int yoffset);
template <class T>
void X11PixelCanvas_drawImage(X11PixelCanvas * xpc,
			      const Matrix<T> &data,
			      Int xoffset, Int yoffset,
			      uInt xzoom, uInt yzoom);

void X11PixelCanvas_drawImage(X11PixelCanvas *xpc,
			      const Matrix<uInt> &data,
			      const Matrix<Bool> &mask,
			      const Int &x, const Int &y);

void X11PixelCanvas_drawImage(X11PixelCanvas *xpc,
			      const Matrix<uInt> &data,
			      const Int &x, const Int &y,
			      const Display::ColorComponent &component);

template <class T>
void X11PixelCanvas_drawPoints(X11PixelCanvas * xpc, const Matrix<T> &verts);

template <class T>
void X11PixelCanvas_drawPoints(X11PixelCanvas * xpc, const Vector<T> &x1,
			       const Vector<T> &y1);

template <class T>
void X11PixelCanvas_drawLines(X11PixelCanvas * xpc,
			      const Vector<T> &x1, const Vector<T> &y1,
			      const Vector<T> &x2, const Vector<T> &y2);
template <class T>
void X11PixelCanvas_drawLines(X11PixelCanvas * xpc, const Matrix<T> &verts);
			      
template <class T>
void X11PixelCanvas_drawPolyline(X11PixelCanvas * xpc,
				 const Vector<T> &x1, const Vector<T> &y1);

template <class T>
void X11PixelCanvas_drawPolyline(X11PixelCanvas * xpc, const Matrix<T> &verts);

template <class T>
void X11PixelCanvas_drawFilledPolygon(X11PixelCanvas * xpc, 
				      const Vector<T> &x1,
				      const Vector<T> &y1);

template <class T>
void X11PixelCanvas_drawColoredPoints(X11PixelCanvas * xpc,
				      const Vector<T> &x1, const Vector<T> &y1,
				      const Vector<uInt> &colors);
template <class T>
void X11PixelCanvas_drawColoredLines(X11PixelCanvas * xpc,
				     const Vector<T> &x1, const Vector<T> &y1,
				     const Vector<T> &x2, const Vector<T> &y2,
				     const Vector<uInt> &colors);

X11PixelCanvas::X11PixelCanvas() :
  display_(0),
  visual_(0),
  screen_(0),
  width_(0),
  height_(0),
  depth_(0),
  xpcctbl_(0),
  havePixmap_(False),
  currentList_(0),
  currentDLCount_(0),
  displayList_(16, (PtrBlock<X11PCDisplayListObject*>*)0),
  listCount_(16, 0u),
  tPtr_(0),
  xTranslations_(32, 0),
  yTranslations_(32, 0),
  exposeHandlerFirstTime_(True),
  clearColor_(0),
  itsDeviceForegroundColor("white"),
  itsDeviceBackgroundColor("black"),
  clipWindowOption_(False),
  clipX1_(0),
  clipY1_(0),
  clipX2_(200),
  clipY2_(150),
  requestBuffer_(0),
  //imageCacheStrategy_(Display::ClientAlways),
  imageCacheStrategy_(Display::ServerAlways),
  serverPixmapMemoryLimit_(1048576*4),
  serverPixmapMemoryUsed_(0),
  itsComponentsInitialised(False) {

  // X Protocol guarantees this minimum
  requestBuffer_ = (void *) new char[X11Limits::RequestBufferSize];

}

X11PixelCanvas::X11PixelCanvas(Widget parent, X11PixelCanvasColorTable * xpcctbl, 
			       uInt width, uInt height)
  //  : parent_(parent),
  : PixelCanvas((PixelCanvasColorTable *) xpcctbl),
    display_(XtDisplay(parent)),
    visual_(xpcctbl->visual()),
    screen_(XtScreen(parent)),
    width_(0),
    height_(0),
    depth_(xpcctbl->depth()),
    xpcctbl_(xpcctbl),
    havePixmap_(False),
    currentList_(0),
    currentDLCount_(0),
    displayList_(16, (PtrBlock<X11PCDisplayListObject*>*)0),
    listCount_(16, 0u),
    tPtr_(0),
    xTranslations_(32, 0),
    yTranslations_(32, 0),
    exposeHandlerFirstTime_(True),
    parent_(parent),
    clearColor_(0),
    itsDeviceForegroundColor("white"),
    itsDeviceBackgroundColor("black"),
    clipWindowOption_(False),
    clipX1_(0),
    clipY1_(0),
    clipX2_(width-1),
    clipY2_(height-1),
    requestBuffer_(0),
    //imageCacheStrategy_(Display::ClientAlways),
    imageCacheStrategy_(Display::ServerAlways),
    serverPixmapMemoryLimit_(1048576*4),
    serverPixmapMemoryUsed_(0),
  itsComponentsInitialised(False)
{
  form_ = XtVaCreateManagedWidget("form",
				  xmFormWidgetClass, parent_,
				  XmNleftAttachment, XmATTACH_FORM,
				  XmNrightAttachment, XmATTACH_FORM,
				  XmNtopAttachment, XmATTACH_FORM,
				  XmNbottomAttachment, XmATTACH_FORM,
				  NULL);

  drawArea_ = XtVaCreateManagedWidget("X11Display",
				      xmDrawingAreaWidgetClass,
				      form_,
				      XmNleftAttachment, XmATTACH_FORM,
				      XmNrightAttachment, XmATTACH_FORM,
				      XmNtopAttachment, XmATTACH_FORM,
				      XmNbottomAttachment, XmATTACH_FORM,
				      XmNwidth, width,
				      XmNheight, height,
				      // XmNdepth, depth_,
				      // XmNscreen, screen_,
				      XmNcolormap, xpcctbl_->xcmap(),
				      // XmNforeground, fgpixel,
				      // XmNbackground, bgpixel,
				      // XtNvisual, visual_,
				      NULL);

  XtManageChild(form_);

  // X Protocol guarantees this minimum
  requestBuffer_ = (void *) new char[X11Limits::RequestBufferSize];

  // Button and Mouse Event Handler
  XtAddEventHandler (drawArea_,
		     ButtonPressMask | ButtonReleaseMask 
		     | KeyPressMask | KeyReleaseMask | PointerMotionMask
		     | ExposureMask | StructureNotifyMask,
		     False,
		     (XtEventHandler) X11PixelCanvas::handleEventsEH,
		     this);

  // Colortable resize callback
  xpcctbl->addResizeCallback
    ((PixelCanvasColorTableResizeCB) colorTableResizeCB, this);

  if (pcctbl()->colorModel() == Display::Index)
    setColormap(pcctbl()->defaultColormap());
}

Bool X11PixelCanvas::drawToPixmap() const
{
  Bool retval = ((drawBuffer() == Display::DefaultBuffer 
			|| drawBuffer() == Display::BackBuffer
			|| drawBuffer() == Display::FrontAndBackBuffer)
		       &&havePixmap_);
  return retval;
}
Bool X11PixelCanvas::drawToWindow() const
{
  Bool retval = (((drawBuffer() == Display::DefaultBuffer)
			&& (refreshActive() == False))
		       || drawBuffer() == Display::FrontBuffer
		       || drawBuffer() == Display::FrontAndBackBuffer);
  return retval;
}

// Event enabling - [ ] Leave always enabled for now

void X11PixelCanvas::enableMotionEvents() {} 
void X11PixelCanvas::disableMotionEvents() {}
void X11PixelCanvas::enablePositionEvents() {}
void X11PixelCanvas::disablePositionEvents() {}

//-----------------------------------------------------
//
// Colortable handling
//
//-----------------------------------------------------

void X11PixelCanvas::colorTableResizeCB(PixelCanvasColorTable *, uInt,
					X11PixelCanvas * xpc,
					Display::RefreshReason reason) {
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
    Display::DrawBuffer buf = xpc->drawBuffer();
    if (buf == Display::FrontBuffer) {
      xpc->setDrawBuffer(Display::FrontAndBackBuffer);
    }
    //xpc->setDrawBuffer(Display::FrontAndBackBuffer);
    //xpc->clear();
    xpc->setDrawBuffer(buf);
  } else if (reason != Display::ColormapChange) {
    xpc->callRefreshEventHandlers(reason);
    if (xpc->drawBuffer() == Display::DefaultBuffer) {
      xpc->copyBackBufferToFrontBuffer();
    }
  }
}

Bool X11PixelCanvas::resizeColorTable(uInt newSize)
{
  return xpcctbl_->resize(newSize);
}

Bool X11PixelCanvas::resizeColorTable(uInt nReds, uInt nGreens, uInt nBlues)
{
  return xpcctbl_->resize(nReds, nGreens, nBlues);
}

//-----------------------------------------------------
//
// Maintenance and Window Management
//
//-----------------------------------------------------

void X11PixelCanvas::exposeCB(Widget , X11PixelCanvas *, XtPointer) {
#if 0
  // NOT USED
  XmDrawingAreaCallbackStruct * cb = (XmDrawingAreaCallbackStruct *) callData;
  
  if (cb->reason == XmCR_EXPOSE) {
    xpc->exposeHandler_();
  }
#endif
}

Bool X11PixelCanvas::resize_()
{
  Bool resized = False;

  // first check if we have a new window size
  Dimension w,h;
  XtVaGetValues(drawArea_, XmNwidth, &w, XmNheight, &h, NULL);

  AlwaysAssert((w > 0) && (h > 0), AipsError);

  Int dh;

  // if so, do the resize callbacks
  if (w != width_ || h != height_)
    {
      dh = h - height_;
      
      width_ = w;  
      height_ = h;
      
      if (havePixmap_) XFreePixmap(display_, pixmap_);
      pixmap_ = XCreatePixmap(display_, 
			      drawWindow_,
			      width_,
			      height_,
			      depth_);
      havePixmap_ = True;
      
      // initially commented out to fix animation/resize displayList
      // bug, but that's fixed now.  So now it's commented out because
      // it's simply not used here for the bulk of DDs.
      //translateAllLists(0, -dh);

      resized = True;
    }

  return resized;
}

void X11PixelCanvas::exposeHandler_() {

  if (exposeHandlerFirstTime_) {
    exposeHandlerFirstTime_ = False;
    drawWindow_ = XtWindow(drawArea_);

    // install Colormap for this Window
    Widget top = X11TopLevelWidget(drawArea_);
    Widget wl[2];
    wl[0] = drawArea_;
    wl[1] = top;
    XtSetWMColormapWindows(top, wl, 2);

    gc_ = XCreateGC(display_, drawWindow_, 0, 0);

    setClearColor(XBlackPixelOfScreen(screen()));
  }
    
  Bool sizeChanged = resize_();

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

void X11PixelCanvas::refresh(const Display::RefreshReason &reason,
			     const Bool &explicitrequest)
{
  if (explicitrequest && (reason != Display::BackCopiedToFront)) {
    setDrawBuffer(Display::BackBuffer);
    clear();
  }
  callRefreshEventHandlers(reason);
  if (explicitrequest && (reason != Display::BackCopiedToFront)) {
    copyBackBufferToFrontBuffer();
    setDrawBuffer(Display::FrontBuffer);
    callRefreshEventHandlers(Display::BackCopiedToFront);
  }
}

Bool X11PixelCanvas::resize(uInt reqXSize, uInt reqYSize, Bool doCallbacks)
{
  XtVaSetValues(form_, XmNwidth, reqXSize, XmNheight, reqYSize, NULL);

  Bool ok = resize_();

  if (doCallbacks) refresh();
  return ok;
}

void X11PixelCanvas::clear()
{

  if(exposeHandlerFirstTime_) return;
	// ..because of (brain-damaged) design that makes most methods crash
	// until exposeHandler_ has been called (to initialize gc_)....
	// Should be fixed properly everywhere when time permits... (dk)

  if (drawMode() == Display::Draw)
    {
      if (drawToPixmap()) {
	uInt c = color();
	setColor(clearColor());
	XFillRectangle(display_, pixmap_, gc_, 0, 0, width(), height());
	setColor(c);
      }
      if (drawToWindow()) {
	uInt c = color();
	setColor(clearColor());
	XFillRectangle(display_, drawWindow_, gc_, 0, 0, width(), height());
	setColor(c);
      }
    }
  else
    {
      appendToDisplayList(new X11PCDLClear(this));
    }
}

void X11PixelCanvas::clear(Int x1, Int y1, Int x2, Int y2)
{
  if(exposeHandlerFirstTime_) return;
  uInt w = x2 - x1 +1;
  uInt h = y2 - y1 +1;
  Int y = height_ - y2 - 1;
  if (drawMode() == Display::Draw)
    {
      //uInt c = color();
      //setColor(clearColor());
      if (drawToPixmap()) {
	uInt c = color();
	setColor(clearColor());
	XFillRectangle(display_, pixmap_, gc_, 
		       x1 + xTranslation(),
		       y + yTranslation(),
		       w, h);
	setColor(c);
      }
      if (drawToWindow()) {
	uInt c = color();
	setColor(clearColor());
	XFillRectangle(display_, drawWindow_, gc_, 
		       x1 + xTranslation(),
		       y + yTranslation(),
		       w, h);
	setColor(c);
      }
      //setColor(c);
    }
  else
    {
      appendToDisplayList
	(new X11PCDLClearRegion
	 (this, x1, y, w, h));
    }  
}

//
//  Buffer management
//

void X11PixelCanvas::setDrawBuffer(Display::DrawBuffer buf)
{
  // Maybe cache drawToPixmap() and drawToWindow() inlines???
  PixelCanvas::setDrawBuffer_(buf);
}

void X11PixelCanvas::copyBackBufferToFrontBuffer()
{
  XCopyArea(display_, pixmap_, drawWindow_, gc_, 0, 0, width_, height_, 0, 0); 
}

void X11PixelCanvas::copyFrontBufferToBackBuffer()
{
  XCopyArea(display_, drawWindow_, pixmap_, gc_, 0, 0, width_, height_, 0, 0);
}

void X11PixelCanvas::swapBuffers()
{
  // expensive, but works
  Pixmap tmpPixmap = XCreatePixmap(display_, drawWindow_, width_, height_, depth_);
  XCopyArea(display_, pixmap_, tmpPixmap, gc_, 0, 0, width_, height_, 0, 0);
  XCopyArea(display_, drawWindow_, pixmap_, gc_, 0, 0, width_, height_, 0, 0);
  XCopyArea(display_, tmpPixmap, drawWindow_, gc_, 0, 0, width_, height_, 0, 0);
  XFreePixmap(display_, tmpPixmap);
}

void X11PixelCanvas::copyBackBufferToFrontBuffer(Int x1, Int y1, Int x2, Int y2)
{
  uInt w = x2-x1+1;
  uInt h = y2-y1+1;
  Int y = height_ - y2 - 1;
  XCopyArea(display_, pixmap_, drawWindow_, gc_, x1, y, w, h, x1, y);
}

void X11PixelCanvas::copyFrontBufferToBackBuffer(Int x1, Int y1, Int x2, Int y2)
{
  uInt w = x2-x1+1;
  uInt h = y2-y1+1;
  Int y = height_ - y2 - 1;
  XCopyArea(display_, drawWindow_, pixmap_, gc_, x1, y, w, h, x1, y);
}

void X11PixelCanvas::swapBuffers(Int x1, Int y1, Int x2, Int y2)
{
  uInt w = x2-x1+1;
  uInt h = y2-y1+1;
  Int y = height_ - y2 - 1;

  // expensive, but works
  Pixmap tmpPixmap = XCreatePixmap(display_, drawWindow_, width_, height_, depth_);
  XCopyArea(display_, pixmap_, tmpPixmap, gc_, x1, y, w, h, x1, y);
  XCopyArea(display_, drawWindow_, pixmap_, gc_, x1, y, w, h, x1, y);
  XCopyArea(display_, tmpPixmap, drawWindow_, gc_, x1, y, w, h, x1, y);
  XFreePixmap(display_, tmpPixmap);
}


//
//  COLOR MANAGEMENT
//


void X11PixelCanvas::setClearColor(const String &colorname) {
  String lcolor(colorname.chars());
  if (colorname == "foreground") {
    lcolor = deviceForegroundColor();
  } else if (colorname == "background") {
    lcolor = deviceBackgroundColor();
  }
  XColor c;
  if (XParseColor(display_, xpcctbl_->xcmap(), lcolor.chars(), &c)) {
    float r = (float) (c.red / 65535.0);
    float g = (float) (c.green / 65535.0);
    float b = (float) (c.blue / 65535.0);
    setClearColor(r,g,b);
  } else {
    throw(AipsError("attempt to set clear color to undefined color"));
  }
}

void X11PixelCanvas::setClearColor(float r, float g, float b)
{
  setClearColor(xpcctbl_->RGB2Index(r,g,b));
}

void X11PixelCanvas::setClearColor(uInt colorIndex)
{
  if (drawMode() == Display::Draw)
    {
      clearColor_ = colorIndex;
    }
  else
    {
      appendToDisplayList(new X11PCDLSetClearColor(this, colorIndex));
    }
}

uInt X11PixelCanvas::clearColor() const
{
  return clearColor_;
}

void X11PixelCanvas::getClearColor(float &r, float &g, float &b) const
{
  XColor c;
  c.pixel = clearColor();
  XQueryColor(display_, xcmap(), &c);
  r = c.red/65535.0;
  g = c.green/65535.0;
  b = c.blue/65535.0;
}

void X11PixelCanvas::setDeviceForegroundColor(const String colorname) {
  itsDeviceForegroundColor = colorname;
}

void X11PixelCanvas::setDeviceBackgroundColor(const String colorname) {
  itsDeviceBackgroundColor = colorname;
}

void X11PixelCanvas::pixelDensity(Float &xdpi, Float &ydpi) const {
  // assume a 21-inch monitor at 1152x900 - this should be 
  // fixed in the future to be cleverer, but it really can't
  // do much else than assume...
  xdpi = Float(80.0);
  ydpi = Float(80.0);
}

void X11PixelCanvas::setColor(const String &colorname) {
  /*
  String lcolor(colorname.chars());
  if (colorname == "foreground") {
    lcolor = deviceForegroundColor();
  } else if (colorname == "background") {
    lcolor = deviceBackgroundColor();
  }
  XColor c;
  if (XParseColor(display_, xpcctbl_->xcmap(), lcolor.chars(), &c)) {
    float r = (float) (c.red / 65535.0);
    float g = (float) (c.green / 65535.0);
    float b = (float) (c.blue / 65535.0);
  */
  Float r, g, b;
  if (getColorComponents(colorname, r, g, b)) {
    setRGBColor(r,g,b);
  } else {
    throw(AipsError("attempt to set color to an unknown name"));
  }
}

void X11PixelCanvas::setColor(float c1, float c2, float c3)
{
  switch(colorModel())
    {
    case Display::Index:
      // won't get here
      break;
    case Display::RGB:
      setRGBColor(c1,c2,c3);
      break;
    case Display::HSV:
      setHSVColor(c1,c2,c3);
      break;
    }
}

void X11PixelCanvas::setRGBColor(float r, float g, float b)
{
  setColor(xpcctbl_->RGB2Index(r,g,b));
}

void X11PixelCanvas::setHSVColor(float h, float s, float v)
{
  setColor(xpcctbl_->HSV2Index(h,s,v));
}

Bool X11PixelCanvas::getColorComponents(const String &colorname, Float &r,
					Float &g, Float &b) {
  String lcolor(colorname.chars());
  if (colorname == "foreground") {
    lcolor = deviceForegroundColor();
  } else if (colorname == "background") {
    lcolor = deviceBackgroundColor();
  }
  XColor c;
  if (XParseColor(display_, xpcctbl_->xcmap(), lcolor.chars(), &c)) {
    r = (float) (c.red / 65535.0);
    g = (float) (c.green / 65535.0);
    b = (float) (c.blue / 65535.0);
    return True;
  } 
  return False;
}

void X11PixelCanvas::setColor(uInt color) 
{ 
  XGCValues v;
  v.foreground = color;
  if (drawMode() == Display::Compile)
    appendToDisplayList(new X11PCDLGraphicsContext(v, GCForeground));
  else
    XChangeGC(display_, gc_, GCForeground, &v);
}

uInt X11PixelCanvas::color() const
{
  XGCValues v;
  XGetGCValues(display_, gc_, GCForeground, &v);
  return (uInt) v.foreground;
}

void X11PixelCanvas::getColor(float &r, float &g, float &b) const
{
  XColor c;
  c.pixel = color();
  XQueryColor(display_, xcmap(), &c);
  r = c.red/65535.0;
  g = c.green/65535.0;
  b = c.blue/65535.0;
}

//-----------------------------------------------------
// 
//  X Event Handling
//
//-----------------------------------------------------

void X11PixelCanvas::handleEventsEH(Widget w, X11PixelCanvas *xpc,
				    XEvent *ev, Boolean *) {
  xpc->handleEvents(w,ev);
}

void X11PixelCanvas::handleEvents(Widget, XEvent *ev) {
  switch(ev->type)
    {
    case MotionNotify:
      callMotionEventHandlers(ev->xmotion.x, 
			      height_ - 1 - ev->xmotion.y, 
			      ev->xmotion.state);
      break;
    case ButtonPress:
    case ButtonRelease:
      {
	Display::KeySym ks = Display::K_Pointer_Button1;
	switch(ev->xbutton.button)
	  {
	  case Button1: ks = Display::K_Pointer_Button1; break;
	  case Button2: ks = Display::K_Pointer_Button2; break;
	  case Button3: ks = Display::K_Pointer_Button3; break;
	  case Button4: ks = Display::K_Pointer_Button4; break;
	  case Button5: ks = Display::K_Pointer_Button5; break;
	  }
	
	callPositionEventHandlers(ks,
				  (ev->type == ButtonPress ? True : False),
				  ev->xbutton.x,
				  height_ - 1 - ev->xbutton.y,
				  ev->xbutton.state);
      }
      break;
    case KeyPress:
    case KeyRelease:
      {
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

	uLong keysym = XKeycodeToKeysym(display_, keycode, index);
	if (keysym == 0)
	  keysym = XKeycodeToKeysym(display_, keycode, 0);

#ifdef XK_KP_Home
#ifdef XK_KP_Delete
	// Handle numlock.  Some HP's may not have these keysyms defined and
	// hence could not generate a keysym to trigger this numlock test.
	if ((state & 0x0010) && (keysym >= XK_KP_Home) && (keysym <= XK_KP_Delete))
	  {
	    keysym = XKeycodeToKeysym(display_, keycode, 1);
	  }
#endif
#endif

	callPositionEventHandlers((Display::KeySym) keysym,
				  keystate,
				  ev->xkey.x,
				  height_ - 1 - ev->xkey.y,
				  ev->xkey.state);
      }
      break;

      // these next two case statements are used together
      // to generate updates when the window resizes.

    case ConfigureNotify:
      // Force configure notify to issue the refresh
      // because expose will not if the window is made smaller.
      if ((uInt)ev->xconfigure.width < width_ ||
	  (uInt)ev->xconfigure.height < height_)
	exposeHandler_();
      break;

    case Expose:
      // Use simple procedure of stripping all-but-last expose
      // events and updating the whole window.
      if (ev->xexpose.count == 0)
	exposeHandler_();
      break;

    default:
      break;
    }
}


//-----------------------------------------------------
// 
//  X11PixelCanvas Event Handling
//
//-----------------------------------------------------

void X11PixelCanvas::positionEventCB(Widget, X11PixelCanvas *, XtPointer) {
  cout << "X11PixelCanvas::positionEventCB" << endl;
}

//-----------------------------------------------------
//
//  Translation control
//
//

void X11PixelCanvas::pushMatrix()
{
  if (drawMode() == Display::Draw)
    {
      if (tPtr_ > xTranslations_.nelements() - 1)
	throw(AipsError("X11PixelCanvas - Matrix stack overflow!"));
      
      tPtr_++;
      
      xTranslations_[tPtr_] = xTranslations_[tPtr_-1];
      yTranslations_[tPtr_] = yTranslations_[tPtr_-1];
    }
  else
    appendToDisplayList(new X11PCDLPushMatrix(this));
}

void X11PixelCanvas::popMatrix()
{
  if (drawMode() == Display::Draw)
    {
      if (tPtr_ == 0)
	throw(AipsError("X11PixelCanvas - Matrix stack underflow!"));
      
      tPtr_--;
    }
  else
    appendToDisplayList(new X11PCDLPopMatrix(this));
}

void X11PixelCanvas::loadIdentity()
{
  if (drawMode() == Display::Draw)
    {
      xTranslations_[tPtr_] = 0;
      yTranslations_[tPtr_] = 0;
    }
  else
    appendToDisplayList(new X11PCDLLoadIdentity(this));
}

void X11PixelCanvas::translate(Int xt, Int yt)
{
  if (drawMode() == Display::Draw)
    {
      xTranslations_[tPtr_] += xt;
      yTranslations_[tPtr_] += yt;
    }
  else
    appendToDisplayList(new X11PCDLTranslate(this, xt, yt));
}

void X11PixelCanvas::getTranslation(Int &xt, Int &yt) const
{
  xt = xTranslations_[tPtr_];
  yt = yTranslations_[tPtr_];
}

Int X11PixelCanvas::xTranslation() const { return xTranslations_[tPtr_]; }
Int X11PixelCanvas::yTranslation() const { return yTranslations_[tPtr_]; }

//-----------------------------------------------------
//
//  ClipWindow control
//
//
void X11PixelCanvas::setClipWindow(Int x1, Int y1, Int x2, Int y2)
{
  if (drawMode() == Display::Compile)
    {
      appendToDisplayList(new X11PCDLSetClipWin(this,x1,y1,x2,y2));
    }
  else
    {
      clipX1_ = x1;
      clipY1_ = y1;
      clipX2_ = x2;
      clipY2_ = y2;

      XRectangle clipWindow;

      clipWindow.width = (uShort) abs(clipX1_ - clipX2_) + 1;
      clipWindow.height = (uShort) abs(clipY1_ - clipY2_) + 1;
      clipWindow.x = (Short) min(clipX1_, clipX2_);
      clipWindow.y = (Short) min(height() - 1 - clipY1_, height() - 1 - clipY2_);

      if (clipWindowOption_ == True) {
	XSetClipRectangles(display_, gc_, 0, 0,
			   &clipWindow, 1, YXBanded);
      }
    }
}
void X11PixelCanvas::getClipWindow(Int &x1, Int &y1, Int &x2, Int &y2)
{
  x1 = clipX1_;
  y1 = clipY1_;
  x2 = clipX2_;
  y2 = clipY2_;
}

//-----------------------------------------------------
//
//  Options
//
Bool X11PixelCanvas::enable(Display::Option option)
{
  if (drawMode() == Display::Compile)
    {
      appendToDisplayList(new X11PCDLEnable(this, option));
    }
  else
    {
      switch (option)
	{
	case Display::ClipWindow: 
	  {
	    clipWindowOption_ = True;
	    XRectangle clipWindow;

	    clipWindow.width = (uShort) abs(clipX1_ - clipX2_) + 1;
	    clipWindow.height = (uShort) abs(clipY1_ - clipY2_) + 1;
	    clipWindow.x = (Short) min(clipX1_, clipX2_);
	    clipWindow.y = (Short) min(height() - 1 - clipY1_, 
				       height() - 1 - clipY2_);
	    
	    XSetClipRectangles(display_, gc_, 0, 0,
			       &clipWindow, 1, YXBanded);

	    return True;
	  }
	}
    }
  return False;
}

Bool X11PixelCanvas::disable(Display::Option option)
{
  if (drawMode() == Display::Compile)
    {
      appendToDisplayList(new X11PCDLDisable(this, option));
    }
  else
    switch(option)
      {
      case Display::ClipWindow:
	clipWindowOption_ = False;
	XSetClipMask(display_, gc_, None);
	return True;
      }
  return False;
}

// return to indicate whether pixmaps or XImages are being
// used for image caching.
Bool X11PixelCanvas::usePixmapImages() const
{
  switch (imageCacheStrategy_)
    {
    case Display::ClientAlways:
      return False;
      break;
    case Display::ServerAlways:
      return True;
      break;
    case Display::ServerMemoryThreshold:
      {
	if (serverPixmapMemoryUsed_ > serverPixmapMemoryLimit_)
	  return False;
	else
	  return True;
	break;
      }     
    }
  return True;
}

// write an X Pixmap (xpm) file of the current pixmap
Bool X11PixelCanvas::writeXPixmap(const String &filename) {
  char *fname = new char[strlen(filename.chars()) + 1];
  strcpy(fname, filename.chars());
  XpmAttributes atts;
  atts.valuemask = XpmColormap;
  atts.colormap = xpcctbl_->xcmap();
  XpmWriteFileFromPixmap(display_, fname, pixmap(), 0, &atts);
  return True;
}


//-----------------------------------------------------
//
//  X11 Text and Font handling
//

Bool X11PixelCanvas::setFont(const String &fontname)
{
  // strategy is to try to load the new font.  If successful,
  // switch to the new font (put it into the GC).  Else do
  // nothing.

  XFontStruct * fontInfo = XLoadQueryFont(display_, fontname.chars());
  if (!fontInfo) return False;

  // so new font was loaded, now put into GC
  XGCValues v;
  v.font = fontInfo->fid;

  if (drawMode() == Display::Compile)
    appendToDisplayList(new X11PCDLGraphicsContext(v, GCFont));
  else
    XChangeGC(display_, gc_, GCFont, &v);

  // ok, we're done I think
  return True;
}

Bool X11PixelCanvas::setFont(const String& fontname, const Int fontsize) {
  
  // This needs to be changed. It relies on the exitance of aliases.
  String fontAndSize = fontname;
  fontAndSize += fontAndSize.toString(fontsize);
  return setFont(fontAndSize);
  //

}


Int X11PixelCanvas::textHeight(const String& text) {

  XFontStruct * fontInfo = XQueryFont(display_, XGContextFromGC(gc_));
  uInt textHeightPixels = fontInfo->ascent + fontInfo->descent;
  return Int(textHeightPixels);
}

Int X11PixelCanvas::textWidth(const String& text) {
  XFontStruct * fontInfo = XQueryFont(display_, XGContextFromGC(gc_));
  uInt textWidthPixels = XTextWidth(fontInfo, text.chars(), text.length());
  
  return Int(textWidthPixels);
}

void X11PixelCanvas::drawText(Int xoffset, Int yoffset, const String &text, 
			      Display::TextAlign alignment)
{
  
  XFontStruct * fontInfo = XQueryFont(display_, XGContextFromGC(gc_));

  // setup the call to X11's XDrawString
  uInt textWidthPixels = XTextWidth(fontInfo, text.chars(), text.length());
  uInt textHeightPixels = fontInfo->ascent + fontInfo->descent;

  Int xbase = xoffset;
  Int ybase = yoffset + fontInfo->descent; 
  Int x = 0, y = 0;

  switch (alignment)
    {
    case Display::AlignCenter:
      x = xbase - textWidthPixels/2;
      y = height_ - (ybase - textHeightPixels/2);
      break;
    case Display::AlignLeft:
      x = xbase;
      y = height_ - (ybase - textHeightPixels/2);
      break;
    case Display::AlignRight:
      x = xbase - textWidthPixels;
      y = height_ - (ybase - textHeightPixels/2);
      break;
    case Display::AlignTop:
      x = xbase - textWidthPixels/2;
      y = height_ - (ybase - textHeightPixels);
      break;
    case Display::AlignTopLeft:
      x = xbase;
      y = height_ - (ybase - textHeightPixels);
      break;
    case Display::AlignTopRight:
      x = xbase - textWidthPixels;
      y = height_ - (ybase - textHeightPixels);
      break;
    case Display::AlignBottom:
      x = xbase - textWidthPixels/2;
      y = height_ - (ybase);
      break;
    case Display::AlignBottomLeft:
      x = xbase;
      y = height_ - (ybase);
      break;
    case Display::AlignBottomRight:
      x = xbase - textWidthPixels;
      y = height_ - (ybase);
      break;
    } 

  int xp = x + xTranslation();
  int yp = y - yTranslation();

  if (drawMode() == Display::Draw)
    {
      if (drawToPixmap())
	XDrawString(display_, pixmap_, gc_, xp, yp, text.chars(), 
		    text.length());
      if (drawToWindow())
	XDrawString(display_, drawWindow_, gc_, xp, yp, text.chars(), 
		    text.length());
    }
  else
    appendToDisplayList(new X11PCDLText(xp, yp, text.chars(), text.length()));
}

void X11PixelCanvas::drawText(Int xoffset, Int yoffset, const String &text, 
			      const Float& angle,
			      Display::TextAlign alignment) {

  // Firstly, check for sillyness
  if (angle == 0) {
    drawText(xoffset, yoffset, text, alignment);
    return;
  }

  XFontStruct * fontInfo = XQueryFont(display_, XGContextFromGC(gc_));
  Int descent(fontInfo->descent);
  
  // Obtain the current font and then change its pixelsize field so that
  // it contains a matrix corresponding to the rotated transform we want

  // Determine its XLFD
  String fontName;
  unsigned long aFontName;
  XGetFontProperty(fontInfo, XA_FONT, &aFontName);
  fontName = XGetAtomName(display_, aFontName);

  // Save a copy so we can leav the font how we found it  later.
  String unRotatedFont(fontName);

  String fontComponents[14];

  //Strip the leading '-' so that split doesn't get confused and put a blank
  //instead of the first one. ( XLFD has a leading '-' )
  fontName.erase(0,1);
  Int pixelSize = 12;
  if (split(fontName, fontComponents, 14, '-') <=0 )
    throw(AipsError("Couldn't determine font info in order to rotate text"));
  
  if (fontComponents[6].firstchar() == '[') {
    // Something has gone wrong! We can't handle a matrix transform in the
    // pixel size field.
    String within[4];
    fontComponents[6].erase(0,1);
    split(fontComponents[6], within, 4, ' ');

    pixelSize = Int(atoi(within[0].chars()));
    // Now save it
    unRotatedFont.clear();

    for (uInt i=0 ; i<14 ; i++) {
      unRotatedFont += '-';
      if (i == 6) 
	unRotatedFont += unRotatedFont.toString(pixelSize);
      else if (i == 7)
	unRotatedFont += '*';
      else 
	unRotatedFont += fontComponents[i];
    }
    
  } else 
    pixelSize = atoi(fontComponents[6].chars());
  
  /*
    Commented out section: It is to calculate the matrix for rotated point
    size based on the pixel size. It was thought that this may help
    rotated text look better, but didn't. 
  */

  // Bool scalePoint = False;

  //  DPI
  // if (fontComponents[8] == "*" || fontComponents[8] == "0" ||
  //     fontComponents[9] == "*" || fontComponents[9] == "0")
  //   scalePoint = False;       
  //   // We can't scale point size since we don't know DPI

  //Int dpiX = 0;
  //Int dpiY = 0;
  //if (scalePoint) {
  //  dpiX = atoi(fontComponents[8].chars());
  //  dpiY = atoi(fontComponents[9].chars());
  //  cerr << "DPI X : " << dpiX << endl;
  //  cerr << "DPI Y : " << dpiY << endl;
  //}

  // Generate the matrix
  char buf [256];
  //char pointBuf [256];
  Float radAngle = angle * (C::pi / 180);

  sprintf (buf, "[%g %g %g %g]",
           cos(radAngle) * pixelSize,
	   sin(radAngle) * pixelSize,
           -sin(radAngle) * pixelSize,
	   cos(radAngle) * pixelSize);
  
  //if (scalePoint) {
  //  Float sx(dpiX / 72.27);
  //  Float sy(dpiY / 72.27);
  //
  //  sprintf (pointBuf, "[%g %g %g %g]",
  //	     (cos(radAngle) * pixelSize) / sx,   // x1
  //	     (sin(radAngle) * pixelSize) / sx,   // x2
  //	     (-sin(radAngle) * pixelSize) / sy,  // x3
  //	     (cos(radAngle) * pixelSize) / sy);  // x4
  //}
  

  for (int i = 0; buf [i]; i++) {
    if (buf [i] == '-')
      buf [i] = '~';
    //if (scalePoint && pointBuf[i] == '-')
    // pointBuf[i] = '~';
  }
  
  // Now rebuild the fontName, with the matrix in place of the size
  // and also kill off the point size attrib, so that doesn't mess things
  // up.
  fontName.clear();
  for (uInt i=0 ; i<14 ; i++) {
    fontName += '-';
    if (i == 6) 
      fontName += buf;
    else if (i == 7)
    //if (scalePoint) fontName += pointBuf;
    //else 
      fontName += '*';
    else 
      fontName += fontComponents[i];
  }
  
  // Now load the font, then do all the normal stuff
  if (!setFont(fontName)) {
    //cerr << "Couldn't set font name to allow rotated text!" << endl;
    if (!setFont(unRotatedFont)) 
      cerr << "Couldn't set font at all." << endl;
    // it to the unRotated font either!!" << endl;
    //else cerr << "... so I set it to the unrotated version, and that worked" 
    //      << endl;
  }

  // setup the call to X11's XDrawString
  uInt textWidthPixels = XTextWidth(fontInfo, text.chars(), text.length());
  uInt textHeightPixels = fontInfo->ascent + fontInfo->descent;

  // Do the same as non - rotated; calculate the starting position
  Int xbase = xoffset;
  Int ybase = yoffset + descent;

  Int x = 0, y = 0;
  
  switch (alignment)
    {
    case Display::AlignCenter:
      x = xbase - textWidthPixels/2;
      y = height_ - (ybase - textHeightPixels/2);
      break;
    case Display::AlignLeft:
      x = xbase;
      y = height_ - (ybase - textHeightPixels/2);
      break;
    case Display::AlignRight:
      x = xbase - textWidthPixels;
      y = height_ - (ybase - textHeightPixels/2);
      break;
    case Display::AlignTop:
      x = xbase - textWidthPixels/2;
      y = height_ - (ybase - textHeightPixels);
      break;
    case Display::AlignTopLeft:
      x = xbase;
      y = height_ - (ybase - textHeightPixels);
      break;
    case Display::AlignTopRight:
      x = xbase - textWidthPixels;
      y = height_ - (ybase - textHeightPixels);
      break;
    case Display::AlignBottom:
      x = xbase - textWidthPixels/2;
      y = height_ - (ybase);
      break;
    case Display::AlignBottomLeft:
      x = xbase;
      y = height_ - (ybase);
      break;
    case Display::AlignBottomRight:
      x = xbase - textWidthPixels;
      y = height_ - (ybase);
      break;
    }

  // We should now be aligned for the case. Now if we rotate the 
  // caluclated pointpoint about the provided point we should be ok
  
  int xp = x + xTranslation();
  int yp = y - yTranslation();
  
  Double sinangle = sin(angle *  (C::pi / 180));
  Double cosangle = cos(angle *  (C::pi / 180));
  Double negsin = sin(-angle *  (C::pi / 180));
  Double negcos = cos(-angle *  (C::pi / 180));

  Float movedX = xp - xbase;  
  Float movedY = yp - (height_ - ybase);
  
  xp = Int((movedX * negcos) - (movedY * negsin));
  yp = Int((movedX * negsin) + (movedY * negcos));

  xp += xbase;
  yp += (height_ - ybase);
  
  Double width = 0;
  
  const char* str = text.chars();

  for(uInt i=0 ; i< text.length() ; i++) {

    if (drawMode() == Display::Draw)
      {
	if (drawToPixmap())
	  XDrawString(display_, pixmap_, gc_, xp + (Int(width * cosangle)), 
		      yp - (Int(width*sinangle)), 
		      & str [i], 1);
	if (drawToWindow())
	  XDrawString(display_, drawWindow_, gc_,xp + (Int(width * cosangle)), 
		      yp - (Int(width*sinangle)), 
		      & str [i], 1);
      }
    else
      appendToDisplayList(new X11PCDLText(xp + (Int(width * cosangle)), 
					  yp - (Int(width*sinangle)), 
					  & str [i], 1));

    width += XTextWidth(fontInfo, & str [i], 1);
    
  }
  // Set the font back to how it was
  setFont(unRotatedFont);
}

//
// drawImage
//
void X11PixelCanvas::drawImage(const Matrix<uInt> &data, 
			       Int xoffset, Int yoffset) {
  X11PixelCanvas_drawImage(this, data, xoffset, yoffset);
}
void X11PixelCanvas::drawImage(const Matrix<Int> &data, 
			       Int xoffset, Int yoffset) {
  X11PixelCanvas_drawImage(this, data, xoffset, yoffset);
}
void X11PixelCanvas::drawImage(const Matrix<uLong> &data, 
			       Int xoffset, Int yoffset) {
  X11PixelCanvas_drawImage(this, data, xoffset, yoffset);
}
void X11PixelCanvas::drawImage(const Matrix<Float> &data, 
			       Int xoffset, Int yoffset) {
  X11PixelCanvas_drawImage(this, data, xoffset, yoffset);
}
void X11PixelCanvas::drawImage(const Matrix<Double> &data, 
			       Int xoffset, Int yoffset) {
  X11PixelCanvas_drawImage(this, data, xoffset, yoffset);
}

// drawImage with mask.
void X11PixelCanvas::drawImage(const Int &x, const Int &y,
			       const Matrix<uInt> &data,
			       const Matrix<Bool> &mask) {
  //X11PixelCanvas_drawImage(this, data, x, y);
  X11PixelCanvas_drawImage(this, data, mask, x, y);
  /*
  // dimensions
  uInt nx = data.nrow();
  uInt ny = data.ncolumn();
  uInt ximXSize = nx;
  uInt ximYSize = ny;

  // compute minimum size of required XImage and build it
  Int rt = (width() - (x + nx));
  if (rt < 0) {
    rt = 0;
  }
  ximXSize = width() - ((x > 0) ? x : 0) - rt;
  rt = (height() - (y + ny)); 
  if (rt < 0) {
    rt = 0;
  }
  ximYSize = height() - ((y > 0) ? y : 0) - rt;

  // image not visible, quit
  if ((ximXSize == 0) || (ximYSize == 0)) {
    return;
  }

  // want smarter allocation, may not need 4x, may need more for
  // machines with more than 8 bits per pixel.
  uLong *ximData = new uLong[ximXSize*ximYSize];
  XImage *xim = XCreateImage(display(), visual(), depth(), ZPixmap, 0,
			     (char *) ximData, ximXSize, ximYSize,
			     BitmapPad(display()), 0);
  
  // and an XImage for the mask
  uLong *ximaskData = new uLong[ximXSize * ximYSize];
  XImage *ximask = XCreateImage(display(), visual(), 1,	ZPixmap, 0,
				(char *) ximaskData, ximXSize, ximYSize,
				BitmapPad(display()), 0);
  
  // Compute dataXIndex, dataYIndex
  uInt dataXIndex = (x < 0) ? -x : 0;
  uInt dataYIndex = (y < 0) ? -y : 0;
  
  // Fill the XImage with data.  c is cell
  uInt dxc = dataXIndex;
  uInt dyc = dataYIndex;
  for (uInt iy = ximYSize; iy > 0;) {
    iy--;
    dxc = dataXIndex;
    for (uInt ix = 0; ix < ximXSize; ix++, dxc++) {
      XPutPixel(xim, ix, iy, (unsigned long) (data(dxc,dyc)));
      if (mask(dxc, dyc)) {
	XPutPixel(ximask, ix, iy, 1);
      } else {
	XPutPixel(ximask, ix, iy, 0);
      }
    }
    dyc++;
  }
  
  // paste the image on the offscreen pixmap
  uInt outputXoffset = (x > 0) ? x : 0;
  uInt outputYoffset = (y > 0) ? y : 0;

  // need a local graphics context so that we don't offset the 
  // image twice because of clipmasks for example...
  XGCValues values;
  unsigned long valuemask = 0;
  GC localGC = XCreateGC(display(), drawWindow(),
			 valuemask, &values);
  valuemask = GCFunction | GCPlaneMask | GCForeground | GCBackground | 
    GCLineWidth | GCLineStyle | GCCapStyle | GCJoinStyle | 
    GCFillStyle | GCFillRule | GCArcMode | GCTile |
    GCStipple | GCTileStipXOrigin | GCTileStipYOrigin | GCFont | 
    GCSubwindowMode | GCGraphicsExposures | GCDashOffset | GCDashList;
  XCopyGC(display(), gc(), valuemask, localGC);
  
  if (drawMode() == Display::Compile) {
    if (usePixmapImages()) {
      // create pixmap and paint the image into it
      Pixmap pm = XCreatePixmap(display(), drawWindow(), 
				ximXSize, ximYSize, depth());
      XPutImage(display(), pm, localGC, xim, 0, 0,
		0,0, ximXSize, ximYSize);

      // create mask pixmap and paint mask into it
      Pixmap pmask = XCreatePixmap(display(), drawWindow(),
				   ximXSize, ximYSize, 1);
      XPutImage(display(), pmask, localGC, ximask, 0, 0, 0, 0,
		ximXSize, ximYSize);
      
      // append the pixmap onto the display
      cerr << "masking might work in pixmap appendToDisplayList" << endl;
      appendToDisplayList(new X11PCDLMaskedPixmap(display(), pm, pmask,
					    ximXSize, ximYSize,
					    outputXoffset,
					    height() - ximYSize -
					    outputYoffset));
       
      // Destroy the XImage
      delete [] ximData;
      xim->data = 0;
      XDestroyImage(xim);
      ximask->data = 0;
      XDestroyImage(ximask);
      XFreeGC(display(), localGC);
    } else {
      cerr << "masking might work in ximage appendToDisplayList" << endl;
      appendToDisplayList(new X11PCDLMaskedImage(xim, ximask,
						 outputXoffset,
						 height() - ximYSize - 
						 outputYoffset));
     }
  } else {
    if (drawToPixmap()) {
      cerr << "masking might work in drawToPixmap" << endl;
      Pixmap pmask = XCreatePixmap(display(), pixmap(),
				   ximXSize, ximYSize, 1);
      XPutImage(display(), pmask, localGC, ximask, 0, 0, 0, 0,
		ximXSize, ximYSize);
      XSetClipOrigin(display(), localGC, outputXoffset + xTranslation(),
		     height() - ximYSize - outputYoffset - yTranslation());
      XSetClipMask(display(), localGC, pmask);
      XPutImage(display(), pixmap(), localGC, xim, 0, 0, 
		outputXoffset + xTranslation(), 
		height() - ximYSize - outputYoffset - 
		yTranslation(), ximXSize, ximYSize);
      XSetClipMask(display(), localGC, None);
    }
    if (drawToWindow()) {
      cerr << "masking might work in drawToWindow" << endl;
      Pixmap pmask = XCreatePixmap(display(), drawWindow(),
				   ximXSize, ximYSize, 1);
      XPutImage(display(), pmask, localGC, ximask, 0, 0, 0, 0,
		ximXSize, ximYSize);
      XSetClipOrigin(display(), localGC, outputXoffset + xTranslation(),
		     height() - ximYSize - outputYoffset - yTranslation());
      XSetClipMask(display(), localGC, pmask);
      XPutImage(display(), drawWindow(), localGC, xim, 0, 0, 
		outputXoffset + xTranslation(), 
		height() - ximYSize - outputYoffset - 
		yTranslation(), ximXSize, ximYSize);
      XSetClipMask(display(), localGC, None);
    }
    delete [] ximData;
    xim->data = 0;
    XDestroyImage(xim);
    ximask->data = 0;
    XDestroyImage(ximask);
    XFreeGC(display(), localGC);
  }
  delete [] ximaskData;
  */
}

//
// drawImage (zoom version)
//
void X11PixelCanvas::drawImage(const Matrix<uInt> &data, Int xoffset, 
			       Int yoffset, uInt xzoom, uInt yzoom) {
  X11PixelCanvas_drawImage(this, data, xoffset, yoffset, xzoom, yzoom);
}
void X11PixelCanvas::drawImage(const Matrix<Int> &data, Int xoffset, 
			       Int yoffset, uInt xzoom, uInt yzoom) {
  X11PixelCanvas_drawImage(this, data, xoffset, yoffset, xzoom, yzoom);
}
void X11PixelCanvas::drawImage(const Matrix<uLong> &data, Int xoffset, 
			       Int yoffset, uInt xzoom, uInt yzoom) {
  X11PixelCanvas_drawImage(this, data, xoffset, yoffset, xzoom, yzoom);
}
void X11PixelCanvas::drawImage(const Matrix<Float> &data, Int xoffset, 
			       Int yoffset, uInt xzoom, uInt yzoom) {
  X11PixelCanvas_drawImage(this, data, xoffset, yoffset, xzoom, yzoom);
}
void X11PixelCanvas::drawImage(const Matrix<Double> &data, Int xoffset, 
			       Int yoffset, uInt xzoom, uInt yzoom) {
  X11PixelCanvas_drawImage(this, data, xoffset, yoffset, xzoom, yzoom);
}

// draw a component of a multi-channel image
void X11PixelCanvas::drawImage(const Matrix<uInt> &data, 
			       const Int &x, const Int &y,
			       const Display::ColorComponent &colorcomponent) {
  X11PixelCanvas_drawImage(this, data, x, y, colorcomponent);
}

void X11PixelCanvas::initialiseComponents(const Int &x, const Int &y,
					  const IPosition &shape) {
  itsBufferedComponent1.resize(shape);
  itsBufferedComponent2.resize(shape);
  itsBufferedComponent3.resize(shape);
  itsBufferedComponent1 = 0;
  if (pcctbl()->colorModel() == Display::RGB) {
    itsBufferedComponent2 = 0;
    itsBufferedComponent3 = 0;
  } else if (pcctbl()->colorModel() == Display::HSV) {
    uInt n1, n2, n3;
    pcctbl()->nColors(n1, n2, n3);
    itsBufferedComponent2 = n2 - 1;
    itsBufferedComponent3 = n3 - 1;
  }
  itsBufferedComponentX = x;
  itsBufferedComponentY = y;
  itsComponentsInitialised = True;
}

void X11PixelCanvas::bufferComponent(const Matrix<uInt> &data,
				     const Int &x, const Int &y,
				     const Display::ColorComponent 
				     &colorcomponent) {
  if ((pcctbl()->colorModel() != Display::RGB) &&
      (pcctbl()->colorModel() != Display::HSV)) {
    // LOG A MESSAGE HERE...
    LogIO os;
    os << LogIO::WARN << LogOrigin("X11PixelCanvas", "bufferComponent", WHERE)
       << "Attempt to buffer a multi-channel component on a PixelCanvas "
       << "that is neither RGB or HSV-based failed" << LogIO::POST;
    return;
  }
  if (!componentsInitialised()) {
    initialiseComponents(x, y, data.shape());
  } else if ((x != itsBufferedComponentX) ||
	     (y != itsBufferedComponentY) ||
	     (data.shape() != itsBufferedComponent1.shape())) {
    //cerr << "***WARNING -> reinitialising component buffers" << endl;
    initialiseComponents(x, y, data.shape());
  }
  //uInt n1, n2, n3;
  //pcctbl()->nColors(n1, n2, n3);
  switch (colorcomponent) {
  case Display::Red:
  case Display::Hue: 
    {
      itsBufferedComponent1 = data;
    }
    break;
  case Display::Green:
  case Display::Saturation:
    {
      itsBufferedComponent2 = data;
    }
    break;
  case Display::Blue:
  case Display::Value:
    {
      itsBufferedComponent3 = data;
    }
    break;
  default:
    {
      throw(AipsError("Unknown Component type in X11PixelCanvas::"
		      "bufferComponent"));
    }
  }
}

void X11PixelCanvas::flushComponentBuffers() {
  if (!componentsInitialised()) {
    return;
  }
  if ((itsBufferedComponent1.shape() != itsBufferedComponent2.shape()) ||
      (itsBufferedComponent1.shape() != itsBufferedComponent3.shape())) {
    throw(AipsError("Component buffers in X11PixelCanvas have become "
		    "non-conformant!"));
  }
  Matrix<uLong> colorImage(itsBufferedComponent1.shape());
  mapToColor3(colorImage, itsBufferedComponent1,
	      itsBufferedComponent2, itsBufferedComponent3);
  drawImage(colorImage, itsBufferedComponentX, itsBufferedComponentY);
  initialiseComponents(0, 0, IPosition(2, 0, 0));
  itsComponentsInitialised = False;
}
  
//
// drawPoint
//
void X11PixelCanvas::drawPoint(Int x1, Int y1) { 
  if (drawMode() == Display::Compile) {
    appendToDisplayList(new X11PCDLPoint((Short) x1, 
					 height_ - 1 - (Short) y1));
  } else {
    if (drawToPixmap())
      XDrawPoint(display_, pixmap_, gc_, 
		 (Short) x1 + xTranslation(), 
		 height_ - 1 - (Short) y1 - yTranslation()); 
    if (drawToWindow())
      XDrawPoint(display_, drawWindow_, gc_, 
		 (Short) x1 + xTranslation(), 
		 height_ - 1 - (Short) y1 - yTranslation()); 
  }
}

void X11PixelCanvas::drawPoint(Float x1, Float y1) { 
  if (drawMode() == Display::Compile) {
    appendToDisplayList(new X11PCDLPoint(Short(x1+0.5), 
					 height_ - 1 - Short(y1+0.5)));
  } else {
    if (drawToPixmap())
      XDrawPoint(display_, pixmap_, gc_, 
		 (Short) x1 + xTranslation(), 
		 height_ - 1 - Short(y1+0.5) - yTranslation()); 
    if (drawToWindow())
      XDrawPoint(display_, drawWindow_, gc_, 
		 (Short) x1 + xTranslation(), 
		 height_ - 1 - Short(y1+0.5) - yTranslation()); 
  }
}

void X11PixelCanvas::drawPoint(Double x1, Double y1) { 
  if (drawMode() == Display::Compile) {
    appendToDisplayList(new X11PCDLPoint(Short(x1+0.5), 
					 height_ - 1 - Short(y1+0.5)));
  } else {
    if (drawToPixmap())
      XDrawPoint(display_, pixmap_, gc_, 
		 Short(x1+0.5) + xTranslation(), 
		 height_ - 1 - Short(y1+0.5) - yTranslation()); 
    if (drawToWindow())
      XDrawPoint(display_, drawWindow_, gc_, 
		 Short(x1+0.5) + xTranslation(), 
		 height_ - 1 - Short(y1+0.5) - yTranslation()); 
  }
}

//
// drawPoints (Vector version)
//
void X11PixelCanvas::drawPoints(const Vector<Int> &x1, 
				const Vector<Int> &y1) {
  X11PixelCanvas_drawPoints(this, x1, y1); 
}
void X11PixelCanvas::drawPoints(const Vector<Float> &x1, 
				const Vector<Float> &y1) {
  X11PixelCanvas_drawPoints(this, x1, y1); 
}
void X11PixelCanvas::drawPoints(const Vector<Double> &x1, 
				const Vector<Double> &y1) {
  X11PixelCanvas_drawPoints(this, x1, y1);
}

//
// drawPoints (Matrix version)
//
void X11PixelCanvas::drawPoints(const Matrix<Int> &verts) { 
  X11PixelCanvas_drawPoints(this, verts);
}
void X11PixelCanvas::drawPoints(const Matrix<Float> &verts) {
  X11PixelCanvas_drawPoints(this, verts); 
}
void X11PixelCanvas::drawPoints(const Matrix<Double> &verts) {
  X11PixelCanvas_drawPoints(this, verts); 
}

//
// drawLine
//
void X11PixelCanvas::drawLine(Int x1, Int y1, Int x2, Int y2) { 
  if (drawMode() == Display::Compile) {
    appendToDisplayList(new X11PCDLLine((Short) x1, height_ - 1 - (Short) y1, 
					(Short) x2, height_ - 1 - (Short)y2));
  } else {
    if (drawToPixmap()) {
      XDrawLine(display_, pixmap_, gc_, (Short) x1 + xTranslation(), 
		height_ - 1 - (Short) y1 - yTranslation(), 
		(Short) x2 + xTranslation(), 
		height_ - 1 - (Short) y2 - yTranslation()); 
    }
    if (drawToWindow()) {
      XDrawLine(display_, drawWindow_, gc_, (Short) x1 + xTranslation(), 
		height_ - 1 - (Short) y1 - yTranslation(), 
		(Short) x2 + xTranslation(), 
		height_ - 1 - (Short) y2 - yTranslation()); 
    }
  }
}

void X11PixelCanvas::drawLine(Float x1, Float y1, Float x2, Float y2) { 
  if (drawMode() == Display::Compile) {
    appendToDisplayList(new X11PCDLLine(Short(x1+0.5), 
					height_ - 1 - Short(y1+0.5), 
					Short(x2+0.5),
					height_ - 1 - Short(y2+0.5)));
  } else {
    if (drawToPixmap()) {
      XDrawLine(display_, pixmap_, gc_, Short(x1+0.5) + xTranslation(), 
		height_ - 1 - Short(y1+0.5) - yTranslation(), 
		Short(x2+0.5) + xTranslation(), 
		height_ - 1 - Short(y2+0.5) - yTranslation()); 
    }
    if (drawToWindow()) {
      XDrawLine(display_, drawWindow_, gc_, Short(x1+0.5) + xTranslation(), 
		height_ - 1 - Short(y1+0.5) - yTranslation(), 
		Short(x2+0.5) + xTranslation(), 
		height_ - 1 - Short(y2+0.5) - yTranslation()); 
    }
  }
}

void X11PixelCanvas::drawLine(Double x1, Double y1, Double x2, Double y2) { 
  if (drawMode() == Display::Compile) {
    appendToDisplayList(new X11PCDLLine(Short(x1+0.5), 
					height_ - 1 - Short(y1+0.5), 
					Short(x2+0.5),
					height_ - 1 - Short(y2+0.5)));
  } else {
    if (drawToPixmap()) {
      XDrawLine(display_, pixmap_, gc_, Short(x1+0.5) + xTranslation(), 
		height_ - 1 - Short(y1+0.5) - yTranslation(), 
		Short(x2+0.5) + xTranslation(), 
		height_ - 1 - Short(y2+0.5) - yTranslation()); 
    }
    if (drawToWindow()) {
      XDrawLine(display_, drawWindow_, gc_, Short(x1+0.5) + xTranslation(), 
		height_ - 1 - Short(y1+0.5) - yTranslation(), 
		Short(x2+0.5) + xTranslation(), 
		height_ - 1 - Short(y2+0.5) - yTranslation()); 
    }
  }
}

//
// drawLines (Vector version)
//
void X11PixelCanvas::drawLines(const Vector<Int> &x1, const Vector<Int> &y1,
			       const Vector<Int> &x2, 
			       const Vector<Int> &y2) {
  X11PixelCanvas_drawLines(this, x1, y1, x2, y2);
}
void X11PixelCanvas::drawLines(const Vector<Float> &x1, 
			       const Vector<Float> &y1,
			       const Vector<Float> &x2, 
			       const Vector<Float> &y2) {
  X11PixelCanvas_drawLines(this, x1, y1, x2, y2);
}
void X11PixelCanvas::drawLines(const Vector<Double> &x1, 
			       const Vector<Double> &y1,
			       const Vector<Double> &x2, 
			       const Vector<Double> &y2) {
  X11PixelCanvas_drawLines(this, x1, y1, x2, y2); 
}

//
// drawLines (Matrix version)
//
void X11PixelCanvas::drawLines(const Matrix<Int> &verts) {
  X11PixelCanvas_drawLines(this, verts);
}
void X11PixelCanvas::drawLines(const Matrix<Float> &verts) {
  X11PixelCanvas_drawLines(this, verts);
}
void X11PixelCanvas::drawLines(const Matrix<Double> &verts) {
  X11PixelCanvas_drawLines(this, verts);
}

// 
// drawPolyline (Vector version)
//
void X11PixelCanvas::drawPolyline(const Vector<Int> &x1, 
				  const Vector<Int> &y1) {
  X11PixelCanvas_drawPolyline(this, x1, y1);
}
void X11PixelCanvas::drawPolyline(const Vector<Float> &x1, 
				  const Vector<Float> &y1) {
  X11PixelCanvas_drawPolyline(this, x1, y1);
}
void X11PixelCanvas::drawPolyline(const Vector<Double> &x1, 
				  const Vector<Double> &y1) {
  X11PixelCanvas_drawPolyline(this, x1, y1);
}

//
// drawPolyline (Matrix version)
//
void X11PixelCanvas::drawPolyline(const Matrix<Int> &verts) {
  X11PixelCanvas_drawPolyline(this, verts);
}
void X11PixelCanvas::drawPolyline(const Matrix<Float> &verts) {
  X11PixelCanvas_drawPolyline(this, verts); 
}
void X11PixelCanvas::drawPolyline(const Matrix<Double> &verts) {
  X11PixelCanvas_drawPolyline(this, verts);
}

//
// drawPolygon (Vector version)
//
#define X11PC_DRAWPOLYGON(Type) \
  uInt n = x1.nelements(); \
  if (n == y1.nelements()) { \
    if ((x1(0) != x1(n - 1)) || (y1(0) != y1(n - 1))) { \
      Vector<Type> x, y; \
      x = x1; \
      y = y1; \
      x.resize(n + 1, True); \
      y.resize(n + 1, True); \
      x(n) = x1(0); \
      y(n) = y1(0); \
      drawPolyline(x, y); \
    } else { \
      drawPolyline(x1, y1); \
    } \
  }

void X11PixelCanvas::drawPolygon(const Vector<Int> &x1, 
				 const Vector<Int> &y1) {
  X11PC_DRAWPOLYGON(Int);
}
void X11PixelCanvas::drawPolygon(const Vector<Float> &x1, 
				 const Vector<Float> &y1) {
  X11PC_DRAWPOLYGON(Float);
}
void X11PixelCanvas::drawPolygon(const Vector<Double> &x1, 
				 const Vector<Double> &y1) {
  X11PC_DRAWPOLYGON(Double);
}

//
// drawPolygon (Matrix version)
//
void X11PixelCanvas::drawPolygon(const Matrix<Int> &verts) {
  drawPolyline(verts); 
  uInt n=verts.nrow()-1; 
  drawLine(verts(n,0), verts(n,1), verts(0,0), verts(0,1));
}

void X11PixelCanvas::drawPolygon(const Matrix<Float> &verts) {
  drawPolyline(verts); 
  uInt n=verts.nrow()-1; 
  drawLine(verts(n,0), verts(n,1), verts(0,0), verts(0,1)); 
}

void X11PixelCanvas::drawPolygon(const Matrix<Double> &verts) {
  drawPolyline(verts); 
  uInt n=verts.nrow()-1; 
  drawLine(verts(n,0), verts(n,1), verts(0,0), verts(0,1)); 
}

//
// drawFilledPolygon
//
void X11PixelCanvas::drawFilledPolygon(const Vector<Int> &x1, 
				       const Vector<Int> &y1) {
  X11PixelCanvas_drawFilledPolygon(this, x1, y1);
}
void X11PixelCanvas::drawFilledPolygon(const Vector<Float> &x1, 
				       const Vector<Float> &y1) {
  X11PixelCanvas_drawFilledPolygon(this, x1, y1);
}
void X11PixelCanvas::drawFilledPolygon(const Vector<Double> &x1, 
				       const Vector<Double> &y1) {
  X11PixelCanvas_drawFilledPolygon(this, x1, y1);
}

//
// drawRectangle
//
void X11PixelCanvas::drawRectangle(Int x1, Int y1, Int x2, Int y2) {
  Vector<Int> x(4), y(4);
  x(0) = x(3) = x1;
  x(1) = x(2) = x2;
  y(0) = y(1) = y1;
  y(2) = y(3) = y2;
  drawPolygon(x,y);
}

void X11PixelCanvas::drawRectangle(Float x1, Float y1, Float x2, Float y2) {
  Vector<Float> x(4), y(4);
  x(0) = x(3) = x1;
  x(1) = x(2) = x2;
  y(0) = y(1) = y1;
  y(2) = y(3) = y2;
  drawPolygon(x,y);
}

void X11PixelCanvas::drawRectangle(Double x1, Double y1, Double x2, 
				   Double y2) {
  Vector<Double> x(4), y(4);
  x(0) = x(3) = x1;
  x(1) = x(2) = x2;
  y(0) = y(1) = y1;
  y(2) = y(3) = y2;
  drawPolygon(x,y);
}

//
// drawFilledRectangle
//
void X11PixelCanvas::drawFilledRectangle(Int x1, Int y1, Int x2, Int y2) {
  Vector<Int> x(4), y(4);
  x(0) = x(3) = x1;
  x(1) = x(2) = x2;
  y(0) = y(1) = y1;
  y(2) = y(3) = y2;
  drawFilledPolygon(x,y); 
}

void X11PixelCanvas::drawFilledRectangle(Float x1, Float y1, Float x2, 
					 Float y2) {
  Vector<Float> x(4), y(4);
  x(0) = x(3) = x1;
  x(1) = x(2) = x2;
  y(0) = y(1) = y1;
  y(2) = y(3) = y2;
  drawFilledPolygon(x,y);
}

void X11PixelCanvas::drawFilledRectangle(Double x1, Double y1, Double x2, 
					 Double y2) {
  Vector<Double> x(4), y(4);
  x(0) = x(3) = x1;
  x(1) = x(2) = x2;
  y(0) = y(1) = y1;
  y(2) = y(3) = y2;
  drawFilledPolygon(x,y);
}

//
// drawColoredPoints
//
void X11PixelCanvas::drawColoredPoints(const Vector<Int> &x1, 
				       const Vector<Int> &y1, 
				       const Vector<uInt> &colors) {
  X11PixelCanvas_drawColoredPoints(this, x1, y1, colors);
}
void X11PixelCanvas::drawColoredPoints(const Vector<Float> &x1, 
				       const Vector<Float> &y1, 
				       const Vector<uInt> &colors) {
  X11PixelCanvas_drawColoredPoints(this, x1, y1, colors);
}

void X11PixelCanvas::drawColoredPoints(const Vector<Double> &x1, 
				       const Vector<Double> &y1, 
				       const Vector<uInt> &colors) {
  X11PixelCanvas_drawColoredPoints(this, x1, y1, colors);
}

void X11PixelCanvas::drawColoredPoints(const Matrix<Int> &xy,
                                       const Vector<uInt> &colors)   
{
   PixelCanvas::drawColoredPoints(xy, colors);
}

void X11PixelCanvas::drawColoredPoints(const Matrix<Float> &xy,
                                       const Vector<uInt> &colors)
{
   PixelCanvas::drawColoredPoints(xy, colors);
}

void X11PixelCanvas::drawColoredPoints(const Matrix<Double> &xy,
                                 const Vector<uInt> &colors)
{  
   PixelCanvas::drawColoredPoints(xy, colors);
}
  


//
// drawColoredLines
//
void X11PixelCanvas::drawColoredLines(const Vector<Int> &x1, 
				      const Vector<Int> &y1, 
				      const Vector<Int> &x2, 
				      const Vector<Int> &y2, 
				      const Vector<uInt> &colors) {
  X11PixelCanvas_drawColoredLines(this, x1, y1, x2, y2, colors);
}
void X11PixelCanvas::drawColoredLines(const Vector<Float> &x1, 
				      const Vector<Float> &y1, 
				      const Vector<Float> &x2, 
				      const Vector<Float> &y2, 
				      const Vector<uInt> &colors) {
  X11PixelCanvas_drawColoredLines(this, x1, y1, x2, y2, colors);
}
void X11PixelCanvas::drawColoredLines(const Vector<Double> &x1, 
				      const Vector<Double> &y1, 
				      const Vector<Double> &x2, 
				      const Vector<Double> &y2, 
				      const Vector<uInt> &colors) {
  X11PixelCanvas_drawColoredLines(this, x1, y1, x2, y2, colors);
}



} //# NAMESPACE CASA - END

