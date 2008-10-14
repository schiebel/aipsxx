//# QtPixelCanvas.cc: Qt implementation of PixelCanvas.
//# Copyright (C) 2005
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
//# $Id: QtPixelCanvas.cc,v 1.6 2006/09/27 15:11:22 hye Exp $

#include <casa/aips.h>
#include <casa/iomanip.h>
#include <casa/namespace.h>
#include <casa/Arrays/Vector.h>
#include <display/Display/Colormap.h> //tmp
#include <casa/Arrays/ArrayMath.h>
#include <display/DisplayCanvas/WCLinearScaleHandler.h>
#include <display/DisplayCanvas/WCPowerScaleHandler.h>
#include <display/Display/AttributeBuffer.h>
#include <display/DisplayShapes/DSMarker.h>

#include <display/QtViewer/QtPixelCanvas.qo.h>

#include <graphics/X11/X_enter.h>
#  include <qnamespace.h>
#  include <QString>
#  include <QCursor>
#  include <QMouseEvent>
#include <graphics/X11/X_exit.h>

QtPixelCanvas::QtPixelCanvas(QWidget *parent) :
	  QWidget(parent),
	  PixelCanvas(),
	  frontBuffer_(0),
	  backBuffer_(0),
	  p_(), pw_(),
	  drawList_(0),
	  drawListNo_(0),
	  drawlists_(0),
	  itsDeviceForegroundColor("white"),
	  itsDeviceBackgroundColor("black"),
	  itsPen(QColor("white")),
	  clipRect_(0,0,1,1),
	  clipEnabled_(False) {

// off -- never seems to work w/o great flicker...	//#dk
//  QWidget::setAttribute(Qt::WA_PaintOnScreen);
//        // (see paintEvent() comments...).
  
  setCursor(QCursor(Qt::CrossCursor));
  setMouseTracking(true);
  setFocusPolicy(Qt::WheelFocus);	// allows kbd events.
  setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
  
  itspcctbl = new QtPCColorTable();
  itspcctbl->addResizeCallback((PixelCanvasColorTableResizeCB)
			        colorTableResizeCB, this);
  
  //Colormap cmap("Greyscale 1");
  //PixelCanvas::setColormap(&cmap);
  //PixelCanvas::registerColormap(&cmap);
  
  setMinimumSize(100, 100);
	// (Could be made less, if useful...)
  
  frontBuffer_ = new QPixmap(QWidget::size());
  backBuffer_  = new QPixmap(QWidget::size());
  
  setDrawBuffer(Display::BackBuffer);	// to begin.
  
  p_begin_();
  
  //p_.setBackground(QColor("dark green"));//#dk (exp.)
  // Does _not_ work here alone (across p_begin_())
  
  refresh();  }


  
QtPixelCanvas::~QtPixelCanvas() {
  deleteLists();	// clear drawList cache
  p_end_();
  delete itspcctbl;
  delete frontBuffer_;
  delete backBuffer_;  }





// Method implementations for PixelCanvas interface.


// REFRESH CYCLE METHODS.  NB: Refresh handlers use the PC drawing
// methods, but they should not be calling the methods immediately below
// (rather the reverse).
// We should not be in drawlist Compile mode when these are called
// (if we are, that mode is abruptly terminated).

  

void QtPixelCanvas::refresh(const Display::RefreshReason &reason,
			    const Bool&) {
  // In the context of this method (only), 'BackCopiedToFront'
  // does _not_ mean the backBuffer has _already_ been copied, it means
  // _copy_ back to front (but omit redrawing the back first), then call the
  // frontBuffer refresh handlers.  For other 'RefreshReasons', the 
  // back buffer is also redrawn initially, before being copied to front.
  // (This should probably be the base class implementation, and should
  // not be overridden....  Also, the 'ClearPriorToColorChange' reason
  // should probably be scrapped).
  //
  // Current (and probably eternal) usage is that DDs draw on the
  // back buffer (only), and mouse tools on the front buffer only.
  // Front buffer drawing should be unelaborate and fast.
  
  if (reason == Display::ClearPriorToColorChange) return;
		// obsolete, no-op now...
  
  Display::RefreshReason r = reason; 
  
  if(r == Display::ColormapChange) r = Display::ColorTableChange;
	// These two 'reasons' have been consolidated.  'ColorTableChange'
	// refresh (colormap fiddling) may lead to more a efficient redraw
	// (see ColorIndexedImage_).
  
  endList();		// safety: should not be compiling a drawlist here.
  
  if(r != Display::BackCopiedToFront) {
    setDrawBuffer(Display::BackBuffer);
    clear();
    callRefreshEventHandlers(r);  }

  copyBackBufferToFrontBuffer();
  setDrawBuffer(Display::FrontBuffer);
  callRefreshEventHandlers(Display::BackCopiedToFront);
  
  //#dk update();	// Assures that the front buffer contents is
			// (eventually) copied to the widget itself.
  //#dk (will need this instead (and elsewhere too... grr..)  
  repaint();
  
}
  

  
void QtPixelCanvas::colorTableResizeCB(PixelCanvasColorTable*, uInt,
                                       QtPixelCanvas* qtpc,
                                       Display::RefreshReason reason) {
  
  qtpc->refresh(reason);  }





// Versions of p_.begin(currentPaintDevice_()) and p_.end() ,that just
// put p_ in desired state, without complaining if it was already there.
// (In general, p_ will be active (on the current PaintDevice) between
// calls to QtPixelCanvas methods...).
  
void QtPixelCanvas::p_end_() { 
//if(p_.isActive())cerr<<"pend      dev:"<<p_.device()<<endl;	//#diag
  if(p_.isActive()) p_.end();  }
  

void QtPixelCanvas::p_begin_() { 
  
  if(p_.isActive() && p_.device()==currentPaintDevice_()) return;
	// Already there.  NB: doc claim that !isActive() => device()==0
	// is demonstrably false....

  p_end_();
//cerr<<"pbeg cdev:"<<currentPaintDevice_()<<endl;	//#diag
  p_.begin(currentPaintDevice_());
   
  //#dk: What 'graphics context' (known in Qt as 'painter state' [really]
  // needs to be restored here?  (Pen, Brush, Bkgd, ClipRegion, Font...)
  // Ans: I think all (or, must set before relevant draw methods...); 
  // here are a couple lines from qpainter.cpp -- begin() method:
  //
  //    // Ensure fresh painter state
  //    d->state->init(d->state->painter);
  

  // needed after begins,  for clear to work...
  p_.setBackground(QColor("darkgreen"));	//#diag
  //p_.setBackground(QColor(itsDeviceBackgroundColor.chars()));
  // ^^^ (the one to use for real)
  
  //p_.setBackground(QColor("dark green"));	//#diag
  //p_.setBackground(QColor("steel blue"));	//#diag
  
  //p_.setBackgroundMode(Qt::OpaqueMode);
  //#diag (later experiment -- no effect)
  
  if(clipEnabled_) p_.setClipRect(clipRect_);
	// Restore clip rectangle.  May be needed across paint device
	// change, e.g. when drawing single WC on multi-WC PC, as DDs
	// create and then draw drawlists(?)

}
  
  
void QtPixelCanvas::copyBackBufferToFrontBuffer() {
  endList();		// safety: should not be compiling a drawlist here.
  p_end_();	// Begin special use of p_ on specific buffer.
  
  p_.begin(frontBuffer_);
  p_.drawPixmap(0, 0, *backBuffer_);
  p_.end();
  
  p_begin_();	// return to drawing on current buffer with p_.
  update();  }		// assure the widget gets the latest front buffer.

  
  
void QtPixelCanvas::copyFrontBufferToBackBuffer() {
  endList();		// safety: should not be compiling a drawlist here.
  p_end_();		// Begin special use of p_ on specific buffer.
  
  p_.begin(backBuffer_);
  p_.drawPixmap(0, 0, *frontBuffer_);
  p_.end();
  
  p_begin_();  }	// return to drawing on current buffer with p_.

  
  
void QtPixelCanvas::swapBuffers() {
  // (unused, I believe...)
  
  endList();		// safety: should not be compiling a drawlist here.
  p_end_();		// Begin special use of p_ on specific buffers.
  
  QPixmap tmp(frontBuffer_->size());
  
  p_.begin(&tmp);
  p_.drawPixmap(0, 0, *frontBuffer_);	// frontbuf --> tmp
  p_.end();
  
  p_.begin(frontBuffer_);
  p_.drawPixmap(0, 0, *backBuffer_);	// backbuf --> frontbuf
  p_.end();
  
  p_.begin(backBuffer_);
  p_.drawPixmap(0, 0, tmp);		// tmp --> backbuf
  p_.end();
  
  p_begin_();		// return to drawing on current buffer with p_.
  update();  }		// assure the widget gets the latest front buffer.




void QtPixelCanvas::copyBackBufferToFrontBuffer(Int x1, Int y1,
						Int x2, Int y2) {

  endList();		// safety: should not be compiling a drawlist here.
  p_end_();		// Begin special use of p_ on specific buffer.
  
  Int qx,qy,w,h;  qFromPC_(x1,y1,x2,y2, qx,qy,w,h);
		// PC-to-Qt pixel coordinate translation.
  
  p_.begin(frontBuffer_);  
  p_.drawPixmap(qx,qy, *backBuffer_, qx,qy,w,h);
  p_.end();
  
  p_begin_();		// return to drawing on current buffer with p_.
  update();  }		// assure the widget gets the latest front buffer.



void QtPixelCanvas::copyFrontBufferToBackBuffer(Int x1, Int y1,
						Int x2, Int y2) {
  // (unused, I believe...)
  
  endList();		// safety: should not be compiling a drawlist here.
  p_end_();		// Begin special use of p_ on specific buffer.
  
  Int qx,qy,w,h;  qFromPC_(x1,y1,x2,y2, qx,qy,w,h);
		// PC-to-Qt pixel coordinate translation.
  
  p_.begin(backBuffer_);  
  p_.drawPixmap(qx,qy, *frontBuffer_, qx,qy,w,h);
  p_.end();
  
  p_begin_();  }	// return to drawing on current buffer with p_.


  
void QtPixelCanvas::swapBuffers(Int x1, Int y1, Int x2, Int y2) {
  // (unused, I believe...)

  endList();		// safety: should not be compiling a drawlist here.
  p_end_();		// Begin special use of p_ on specific buffers.
  
  Int qx,qy,w,h;  qFromPC_(x1,y1,x2,y2, qx,qy,w,h);
		// PC-to-Qt pixel coordinate translation.

  QPixmap tmp(w,h);  
  
  p_.begin(&tmp);  
  p_.drawPixmap(0,0,  *frontBuffer_, qx,qy,  w,h);	// frontbuf --> tmp
  p_.end();
  
  p_.begin(frontBuffer_);  
  p_.drawPixmap(qx,qy, *backBuffer_, qx,qy,  w,h);	// backbuf --> frontbuf
  p_.end();
  
  p_.begin(backBuffer_);
  p_.drawPixmap(qx,qy, tmp);				// tmp --> backbuf
  p_.end();
  
  p_begin_();		// return to drawing on current buffer with p_.
  update();  }		// assure the widget gets the latest front buffer.

  
  
  
// DRAWING METHODS.
  

  
void QtPixelCanvas::clear() {
  if(inDrawMode_()) clearBuffer_();
  else { p_end_(); p_begin_();  }
		// Tho' undocumented, this clears QPictures...
  update();  }
  

void QtPixelCanvas::clear(Int x1, Int y1, Int x2, Int y2) {
  p_.eraseRect(qrect_(x1,y1,x2,y2));
  update();  }


  
    
void QtPixelCanvas::drawImage(const Matrix<uInt> &data, Int xs, Int ys) {

  Int w = data.nrow();
  Int h = data.ncolumn();

  QImage im(w, h, QImage::Format_ARGB32);
  
  for (int y=0; y<h; y++) {
    QRgb* p = (QRgb*)im.scanLine(h-1 - y);
		// Invert image lines too (flip top to bottom).
    
    for (int x=0; x<w; x++) *p++ = data(x,y);  }
		// set image pixels.

          
  p_.drawImage(xs, q_(ys + im.height()-1), im);
  
  //cerr<<"w:"<<w<<" h:"<<h<<" x:"<<xs<<" y:"<<ys<<" qy:"<<	//#diag
  //q_(ys + im.height()-1)<<endl;	//#diag
  //cerr<<" drawBuf:"<<drawBuffer()<<endl;	//#diag
  
  update();  }

void QtPixelCanvas::drawImage(const Matrix<Float> &data, Int xs, Int ys)
{
    //cout << "QtPixelCanvas::drawImage- Float" << endl;
    Int w = data.nrow();
    Int h = data.ncolumn();

    QImage im(w, h, QImage::Format_ARGB32);

    for (int y=0; y<h; y++)
    {
        QRgb* p = (QRgb*)im.scanLine(h-1 - y);
        for (int x=0; x<w; x++)
        {
            *p++ = (QRgb)data(x,y);
        }
    }
    p_.drawImage(xs, q_(ys + im.height()-1), im);
    update();
}

void QtPixelCanvas::drawImage(const Int &xs, const Int &ys, 
   const Matrix<uInt> &data, const Matrix<Bool> &mask)
{
    //cout << "QtPixelCanvas::drawImage- Int" << endl;
    Int w = data.nrow();
    Int h = data.ncolumn();

    QImage im(w, h, QImage::Format_ARGB32);

    for (int y=0; y<h; y++)
    {
        QRgb* p = (QRgb*)im.scanLine(h-1 - y);
        for (int x=0; x<w; x++)
        {
            *p++ = data(x,y);
        }
    }
    p_.drawImage(xs, q_(ys + im.height()-1), im);
    update();
}


void QtPixelCanvas::drawLine(Int x1, Int y1, Int x2, Int y2) {
  p_.setPen(itsPen);
  p_.drawLine(x1, q_(y1),  x2, q_(y2));
  update();  
}


void QtPixelCanvas::drawMarker(const Float& x1, const Float& y1,
  			  const Display::Marker& marker, 
			  const Int& pixelHeight) {
    //cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
    //DSMarker dsMarker(x1, y1, marker, pixelHeight);
    //dsMarker.draw(this);
};

void QtPixelCanvas::drawMarker(const Double& x1, const Double& y1,
  			  const Display::Marker& marker, 
			  const Int& pixelHeight) {
    cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
    DSMarker dsMarker(x1, y1, marker, pixelHeight);
    dsMarker.draw(this);
};

void QtPixelCanvas::drawMarker(const Int& x1, const Int& y1,
  			  const Display::Marker& marker, 
			  const Int& pixelHeight) {
    //cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
    DSMarker dsMarker(x1, y1, marker, pixelHeight);
    dsMarker.draw(this);
};

void QtPixelCanvas::drawLines(const Matrix<Float> &verts) {
  //#dk (critical method for pgplot...)
  
  p_.setPen(itsPen);
  
  Int nlines = verts.nrow()/2;
  QVector<QLine> lines(nlines);
  
  for (Int i=0; i<nlines; i++) {
    lines[i] = QLine(Int(verts(2*i,  0)+0.5), q_(Int(verts(2*i,  1)+0.5)),
		     Int(verts(2*i+1,0)+0.5), q_(Int(verts(2*i+1,1)+0.5)));  }
  
  p_.drawLines(lines);
  
  update();  }


  
void QtPixelCanvas::drawRectangle(Int x1, Int y1, Int x2, Int y2) {
  
  p_.setPen(itsPen);
// cerr << "drawRect i" << endl;		//#diag hi-vol
  
  p_.drawRect(qrect_(x1,y1,x2,y2));
  
  update();  }


  
void QtPixelCanvas::drawFilledRectangle(Int x1, Int y1, Int x2, Int y2) {
  
  p_.setPen(itsPen);
  p_.setBrush(itsPen.color());
  
  p_.drawRect(qrect_(x1,y1,x2,y2));
  
  p_.setBrush(QBrush());	// (Reset brush -- not persistent in PC)
  
  update();  }

  
  
void QtPixelCanvas::drawEllipse(const Float &cx, const Float &cy,
			       const Float &smajor, const Float &sminor,
			       const Float &pangle, Bool outline) {
  //#dk  needed by MWCCrshr, PC::drawMarkers (<--NB: already in terms of
  //     other draw methds -- see rqmts. there); also DDDellipse & DSEllipse.
  
  p_.setPen(itsPen);
  if(!outline) p_.setBrush(itsPen.color());	// (Sets it to fill ellipse).

  //#dk  TO DO: final check that this transformation is correct....
  
  p_.rotate(-pangle);	// ..or  p_.rotate(qreal(-pangle));  ?...
  p_.drawEllipse(QRectF(cx-smajor, q_(cy)-sminor,  2.f*smajor, 2.f*sminor));
		// (top-left corner, dimensions, of bounding rectangle). 
  
  p_.setMatrix(QMatrix());  // (resets painter's 2-D rotation matrix).
  if(!outline) p_.setBrush(QBrush());
	// (Reset brush -- not persistent in PC)
  
}


  
  

// GRAPHICS CONTEXT


void QtPixelCanvas::setDeviceForegroundColor(const String colorname) {
  if (colorname != "foreground" && colorname != "background") 
    itsDeviceForegroundColor = colorname;  }

String QtPixelCanvas::deviceForegroundColor() const {
  return itsDeviceForegroundColor;  }

void QtPixelCanvas::setDeviceBackgroundColor(const String colorname) {
//#dk why not implemented?
}

String QtPixelCanvas::deviceBackgroundColor() const {
  return itsDeviceBackgroundColor;
}

void QtPixelCanvas::setColor(const String &colorname) {

//#dk Original -- not correct
/*
  String colour;
  if (colorname == "foreground") colour = deviceForegroundColor();
  else if (colorname == "background") colour = deviceBackgroundColor();
  else colour = colorname;
if(colour=="white") colour="blue";	//#diag
//#diag  This has no effect--this routine probably doesn't
//#diag  either--fix.
				   
  QColor col(colour.chars());
  
  // Original -- not correct  (dk)
  ////(obs) QWidget::setPaletteForegroundColor(col);
  //// dk replaced per doc instructions by following:
  //QPalette p;		// ( better(?): QPalette p(palette()); )
  //p.setColor(foregroundRole(), col);
  //setPalette(p);

cerr<<"setColor: "<<colorname<<" "<<colour<<endl;	//#diag
*/

  Float r,g,b;
  if(!getColorComponents(colorname, r,g,b)) return;
  setRGBColor(r,g,b);  }

  
void QtPixelCanvas::setRGBColor(Float r, Float g, Float b) {
  itsPen.setColor(QColor(clrByte_(r), clrByte_(g), clrByte_(b)));  }


// Clip window

void QtPixelCanvas::setClipWindow(Int x1, Int y1, Int x2, Int y2) {
  
  clipRect_ = qrect_(x1,y1,x2,y2);
  if(clipEnabled_) p_.setClipRect(clipRect_);  }


Bool QtPixelCanvas::enable(Display::Option option) {
  if(option!=Display::ClipWindow) return False;
  if(clipEnabled_) return True;	//Already there.
  
  clipEnabled_ = True;
  p_.setClipRect(clipRect_);
  
  return True;  }
  

Bool QtPixelCanvas::disable(Display::Option option) {
  if(option!=Display::ClipWindow) return False;
  
  clipEnabled_ = False;
  p_.setClipping(False);
  
  return True;  }




  
// INFORMATIONAL METHODS


void QtPixelCanvas::pixelDensity(Float &xdpi, Float &ydpi) const {
  xdpi = Float(QPaintDevice::logicalDpiX());
  ydpi = Float(QPaintDevice::logicalDpiY());  }


Bool QtPixelCanvas::getColorComponents(const String &colorname, 
				      Float &r, Float &g, Float &b) {
  String color;
  if (colorname == "foreground") color = deviceForegroundColor();
  else if (colorname == "background") color = deviceBackgroundColor();
  else color = colorname;
  
  if(colorname=="green") {
    r=0.; g=1.; b=0.;		// Kludge to keep "green" consistent with X11
    return True;  }		// rgb.txt database.  Qt 4.0 no longer uses
				// rgb.txt, but the W3C standard for color 
				// names ( www.w3.org/TR/SVG/types.html ).
  
  QColor col(color.chars());
  if(!col.isValid()) return False;
  
  r = (col.red()  +.5)/256.;
  g = (col.green()+.5)/256.;
  b = (col.blue() +.5)/256.;
	// (The 256 byte values are mapped onto equal-length intervals of
	// [0., 1.]; the real values returned are the centers of those
	// intervals.  Thus, float components returned here are never
	// exactly 0. or 1.; they're the best estimators nevertheless,
	// actually....  They also invert back to the correct/original
	// bytes, including 0 and 255 -- see clrByte_()).

//cerr << colorname << ": " << r << "," << g <<"," << b << endl;  //#diag
  return True;  }


  
   
   
  
// DRAWLIST CACHING.
// Drawlists are implemented with QPictures.
  
Bool QtPixelCanvas::supportsLists()  { return True;  }

Bool QtPixelCanvas::validList(uInt list) { 
  return drawlists_.isDefined(list);  }
  

uInt QtPixelCanvas::newList() { 
  endList();			// (safety in case old list left open --
				// we'll open a new one).
  p_end_();
  setDrawMode(Display::Compile);	// Enter drawlist compile mode.
  drawList_ = new QPicture;
  p_begin_();				// begin painting on drawlist.
  
  for(drawListNo_=0; validList(drawListNo_); drawListNo_++);
		// Find first unused drawlist number.
  drawlists_.define(drawListNo_, drawList_);
	// Save new drawlist in the cache.
  return drawListNo_;  }
  


void QtPixelCanvas::endList() {
  if(inDrawMode_()) return;	// Already there.
  
  p_end_();			// Close painter on current drawlist.
  setDrawMode(Display::Draw);
  p_begin_();			// Re-open it on current Pixmap buffer.
  
  if(drawList_->isNull()) deleteList(drawListNo_);  }
		// Don't bother retaining the list if nothing was drawn.

  
void QtPixelCanvas::drawList(uInt list) {

  if(!inDrawMode_() && list==drawListNo_) endList();
	// Safety: user no doubt intended to close list before drawing it.
  
  if(!validList(list)) return;
  QPicture* dl = static_cast<QPicture*>(drawlists_(list));
  if(dl==0) return;	// (shouldn't happen).
  
  p_.drawPicture(0,0, *dl);  }

  
void QtPixelCanvas::deleteList(uInt list) {
  if(!validList(list)) return;
  QPicture* dl = static_cast<QPicture*>(drawlists_(list));
  delete dl;
  drawlists_.remove(list);  }

  
void QtPixelCanvas::deleteLists() {
  for (uInt i=0; i<drawlists_.ndefined(); i++) {
    QPicture* dl = static_cast<QPicture*>(drawlists_.getVal(i));
    delete dl;  }
  drawlists_.clear();  }







// method/slot implementations for QWIDGET (not PixelCanvas) INTERFACE.
// (To do(?): derive from QWidget in a separate class, and own that object,
// rather than deriving from QWidget here, so that the Widget is not exposed).
// (But: doing that would make using QPC as a 'child Widget' a pain...).


void QtPixelCanvas::resizeEvent(QResizeEvent* e) {
//cerr << "resizeEvent" << endl;		//#diag
  
  endList();		// safety: should not be compiling a drawlist here.
  p_end_();
  
  delete frontBuffer_;  frontBuffer_ = new QPixmap(QWidget::size());
  delete backBuffer_;   backBuffer_  = new QPixmap(QWidget::size());
	// (Only way to resize QPixmaps in Qt4...)
//cerr<<"rsz b:"<<backBuffer_<<" f:"<<frontBuffer_<<
//" hw:"<<frontBuffer_->height()<<" "<<frontBuffer_->width()<<endl;  //#diag

  p_begin_();
  
  refresh(Display::PixelCoordinateChange);  }

  

void QtPixelCanvas::paintEvent(QPaintEvent* e) {
  // It was thought best to retain Malte's use essentially of 'triple
  // buffering' (backBuffer and frontBuffer Pixmaps, _plus_ the widget itself),
  // and to use this actual Qt paintEvent only to 'bitBlt' the pre-drawn
  // canvas (despite slight efficiency penalties), especially in light of
  // Qt4's rule of 'widget painting only during a paint event'.  That
  // wouldn't jibe well with PixelCanvas's own design, if we had tried to
  // implement PC draw commands by painting directly onto the widget,
  // because it is too late to propagate such a requirement onto PixelCanvas
  // users, which draw whenever they want (or actually, as currently
  // organized, within various types of calls to various types of refresh
  // handlers (backBuffer drawers, frontbuffer drawers, WC refresh
  // handlers,...)).
  //
  // This means that Qt's own 'automatic Widget doubleBuffering' (the reason
  // for its new paint rule) is more hindrance than help, and is turned
  // off too (via QWidget::setAttribute(Qt::WA_PaintOnScreen) in the
  // constructor).  [later note: no, that causes flicker (why?).  Are we
  // now therefore quadruple-buffering?....]
  //
  // To review current usage: DDs draw on the backBuffer, which is then
  // copied to the front, then mouse tools draw on the front.  During
  // mouse tool use, the (more-time-consuming) DD redrawing is skipped
  // by simply recopying the old back buffer to the front.  The interface 
  // is far too prone to misuse, and needs revision (e.g. don't allow/force
  // buffer mgmt external to PC, and get the ludicrous 'RefreshReasons'
  // unmuddled and really working right), but is receiving little revision
  // now during Qt migration (dk 8/05).
 
//static Int i=0;	//#diag
//cerr<<"pnt "<<i++<<" hw:"<<height()<<" "<<width()<<" buf hw:"<<  //#diag
//frontBuffer_->height()<<" "<<frontBuffer_->width()<<endl;   //#diag HI-VOL.
  
  p_end_();
	// Although begin() and end() are poorly documented in Qt,
	// my suspicion is that this is necessary to assure that all
	// the drawing p_ is supposed to have 'done' to the front buffer
	// Pixmap has actually been 'flushed' and completed on it...
	// Confirmed advisable at Qt conference (Gunnar Sletta--paint dsgnr).


  pw_.begin(this);
//pw_.setBackground(QColor("green"));	//#diag (exp.)
//#dk doesn't seem necessary--one in ctor sticks thru close-open.

  pw_.drawPixmap(0,0,*frontBuffer_);
//  pw_.drawPixmap(0,0,*backBuffer_);	//#diag (exp.)
  pw_.end();
  
  p_begin_();  }		// reopen the painter used for draw commands.


  
     
  
uInt QtPixelCanvas::dlKeyMods_(Qt::KeyboardModifiers qmods) {
  // Helper routine to translate Qt KeyboardModifiers 
  // to Display Library KeyModifier mask (which is more like XEvent 'state').
  
  uInt kmods = 0u;
    
  if(qmods & Qt::ShiftModifier)   kmods |= Display::KM_Shift;
  if(qmods & Qt::ControlModifier) kmods |= Display::KM_Ctrl;
  if(qmods & Qt::AltModifier)     kmods |= Display::KM_Alt;
  
  return kmods;  }


uInt QtPixelCanvas::dlKeyMods_(QMouseEvent* e) {
  // Helper routine to translate Qt MouseButtons and KeyboardModifiers 
  // to Display Library KeyModifier mask (which is more like XEvent 'state').
  
  uInt kmods = dlKeyMods_(e->modifiers());
  
  Qt::MouseButtons qbtns = e->buttons();
    
  if(qbtns & Qt::LeftButton)   kmods |= Display::KM_Pointer_Button_1;
  if(qbtns & Qt::MidButton)    kmods |= Display::KM_Pointer_Button_2;
  if(qbtns & Qt::RightButton)  kmods |= Display::KM_Pointer_Button_3;

  return kmods;  }

  
  
void QtPixelCanvas::mouseMoveEvent(QMouseEvent* e ) {
  callMotionEventHandlers(e->x(), q_(e->y()), dlKeyMods_(e));  }
  
     
  
void QtPixelCanvas::mouseReleaseEvent(QMouseEvent* e ) {
  Int x = e->x(),  y = q_(e->y());
   
  uInt kmods = dlKeyMods_(e);
  
  Qt::MouseButton qbtn = e->button();
  Display::KeySym ksym = Display::K_None;
  
  // NB: dlKeyMods_() returns mouse button state after release, excluding qbtn,
  // but kmods must deliver state _before_ release in the PCPositionEvent.
  
  if        (qbtn==Qt::LeftButton) {
    ksym   = Display::K_Pointer_Button1; 
    kmods |= Display::KM_Pointer_Button_1;  }
  
  else if  (qbtn==Qt::MidButton) {
    ksym   = Display::K_Pointer_Button2; 
    kmods |= Display::KM_Pointer_Button_2;  }
  
  else if  (qbtn==Qt::RightButton) {
    ksym   = Display::K_Pointer_Button3; 
    kmods |= Display::KM_Pointer_Button_3;  }
          
  callPositionEventHandlers(ksym, False, x,y, kmods);  }

  

  
void QtPixelCanvas::mousePressEvent(QMouseEvent* e ) {
  Int x = e->x(),  y = q_(e->y());
   
  uInt kmods = dlKeyMods_(e);
  
  Qt::MouseButton qbtn = e->button();
  Display::KeySym ksym = Display::K_None;
  
  // NB: dlKeyMods_() returns mouse button state after press, including qbtn,
  // but kmods must deliver state _before_ press in the PCPositionEvent.
  
  if         (qbtn==Qt::LeftButton) {
    ksym   =  Display::K_Pointer_Button1; 
    kmods &= ~Display::KM_Pointer_Button_1;  }
  
  else if   (qbtn==Qt::MidButton) {
    ksym   =  Display::K_Pointer_Button2; 
    kmods &= ~Display::KM_Pointer_Button_2;  }
  
  else if   (qbtn==Qt::RightButton) {
    ksym   =  Display::K_Pointer_Button3; 
    kmods &= ~Display::KM_Pointer_Button_3;  }
          
  callPositionEventHandlers(ksym, True, x,y, kmods);  }
  

    
void QtPixelCanvas::keyPressEvent (QKeyEvent* e ) {
  
  Int qkey = e->key();
  
  Display::KeySym ksym = Display::K_None;
//cerr<<"KeyPress qkey:"<<qkey<<endl;	//#diag
  
  // This is just a start; needs extensive translation table(s).
  
  if     (qkey==Qt::Key_Escape) ksym = Display::K_Escape;
  else if(qkey==Qt::Key_Space)  ksym = Display::K_space;
  else if(qkey==Qt::Key_L)      ksym = Display::K_l;
  
  else { e->ignore(); return;  }
  
  uInt kmods = dlKeyMods_(e->modifiers());
//cerr<<"         ksym:"<<ksym<<" kmods:"<<kmods<<endl;	//#diag

  // Mouse position is not part of Qt kbd events, but it can be retrieved...
  
  QPoint posn = mapFromGlobal(QCursor::pos());
  Int x = posn.x(),  y = q_(posn.y());

//cerr<<"         ksym:"<<ksym<<" kmods:"<<kmods<<
//" x,y:"<<x<<" "<<y<<endl;	//#diag
  
  callPositionEventHandlers(ksym, True, x,y, kmods);  }

  


  
  
  
//###########################
//# is this anything?....
//###########################



Float QtPixelCanvas::getLineWidth() const { return 1.;  }

Display::LineStyle QtPixelCanvas::getLineStyle() const {
  return Display::LSSolid;  }

Display::CapStyle QtPixelCanvas::getCapStyle() const {
  return Display::CSNotLast;  }

Display::JoinStyle QtPixelCanvas::getJoinStyle() const {
  return Display::JSMiter;  }

Display::FillStyle QtPixelCanvas::getFillStyle() const {
  return Display::FSSolid;  }

Display::FillRule QtPixelCanvas::getFillRule() const {
  return Display::FREvenOdd;  }

Display::ArcMode QtPixelCanvas::getArcMode() const {
  return Display::AMChord;  }

void QtPixelCanvas::setColorModel(Display::ColorModel colorModel) {
  // fill in
}

Bool QtPixelCanvas::refreshActive() const { return False;  }

Bool QtPixelCanvas::refreshAllowed() const { return True;  }

void QtPixelCanvas::drawPoint(Int x1, Int y1) {
  cerr << "drawPoint i" << endl;	//#diag -- not seen so far
}

void QtPixelCanvas::drawPoint(Float x1, Float y1) {
  cerr << "drawPoint f" << endl;	//#diag -- not seen so far
}

void QtPixelCanvas::drawPoint(Double x1, Double y1) {
  cerr << "drawPoint d" << endl;	//#diag -- not seen so far
}

void QtPixelCanvas::drawPoints(const Matrix<Int> &verts) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
}

void QtPixelCanvas::drawPoints(const Matrix<Float> &verts) {  
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
}

void QtPixelCanvas::drawPoints(const Matrix<Double> &verts) { 
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
}

void QtPixelCanvas::drawPoints(const Vector<Int> &x1, 
			       const Vector<Int> &y1) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
}

void QtPixelCanvas::drawPoints(const Vector<Float> &x1,
			       const Vector<Float> &y1) {  
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
}

void QtPixelCanvas::drawPoints(const Vector<Double> &x1,
			       const Vector<Double> &y1) { 
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
}

void QtPixelCanvas::drawLine(Float x1, Float y1, Float x2, Float y2) {
  cerr << "drawLine called f" << endl;	//#diag -- not seen so far
  //fill
}

void QtPixelCanvas::drawLine(Double x1, Double y1, Double x2, Double y2) {  
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
}


void QtPixelCanvas::drawLines(const Matrix<Int> &verts) {
  cerr << "drawLines called i" << endl;	//#diag -- not seen so far
}

void QtPixelCanvas::drawLines(const Matrix<Double> &verts) {
  cerr << "drawLine called d" << endl;	//#diag -- not seen so far
}

void QtPixelCanvas::drawLines(const Vector<Int> &x1, const Vector<Int> &y1, 
			     const Vector<Int> &x2, const Vector<Int> &y2) {  
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
}

void QtPixelCanvas::drawLines(const Vector<Float> &x1, const Vector<Float> &y1, 
			      const Vector<Float> &x2, 
			      const Vector<Float> &y2) { 
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
 }

void QtPixelCanvas::drawLines(const Vector<Double> &x1, const Vector<Double> &y1, 
			      const Vector<Double> &x2, 
			      const Vector<Double> &y2) { 
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
 }

void QtPixelCanvas::drawPolyline(const Vector<Int> &x1, 
				const Vector<Int> &y1) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  // not used
}

void QtPixelCanvas::drawPolyline(const Vector<Float> &x1, 
				const Vector<Float> &y1) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  //not used
}

void QtPixelCanvas::drawPolyline(const Vector<Double> &x1, 
				const Vector<Double> &y1) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  //not used
}

void QtPixelCanvas::drawPolyline(const Matrix<Int> &verts) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  // fill
}

void QtPixelCanvas::drawPolyline(const Matrix<Float> &verts) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  // fill
}

void QtPixelCanvas::drawPolyline(const Matrix<Double> &verts) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
}

void QtPixelCanvas::drawPolygon(const Vector<Int> &x1,
			       const Vector<Int> &y1) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  //fill
}
void QtPixelCanvas::drawPolygon(const Vector<Float> &x1, 
			       const Vector<Float> &y1) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  //fill
}

void QtPixelCanvas::drawPolygon(const Vector<Double> &x1, 
			       const Vector<Double> &y1) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
}

void QtPixelCanvas::drawPolygon(const Matrix<Int> &verts) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  //fill
}

void QtPixelCanvas::drawPolygon(const Matrix<Float> &verts) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  //fill
}

void QtPixelCanvas::drawPolygon(const Matrix<Double> &verts) { 
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
 }

void QtPixelCanvas::drawFilledPolygon(const Vector<Int> &x1,
				     const Vector<Int> &y1) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  //fill
}
void QtPixelCanvas::drawFilledPolygon(const Vector<Float> &x1, 
				     const Vector<Float> &y1) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
}

void QtPixelCanvas::drawFilledPolygon(const Vector<Double> &x1, 
					 const Vector<Double> &y1) {  }

void QtPixelCanvas::drawRectangle(Float x1, Float y1, Float x2, Float y2) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
}

void QtPixelCanvas::drawRectangle(Double x1, Double y1,
				 Double x2, Double y2) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
}

void QtPixelCanvas::drawFilledRectangle(Float x1, Float y1,
				       Float x2, Float y2) {
  //maybe
}

void QtPixelCanvas::drawFilledRectangle(Double x1, Double y1, 
					   Double x2, Double y2) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  // not used
}

void QtPixelCanvas::drawColoredLines(const Vector<Int> &x1, 
				    const Vector<Int> &y1, 
				    const Vector<Int> &x2, 
				    const Vector<Int> &y2, 
				    const Vector<uInt> &colors) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  // not used
}

void QtPixelCanvas::drawColoredLines(const Vector<Float> &x1, 
				    const Vector<Float> &y1, 
				    const Vector<Float> &x2, 
				    const Vector<Float> &y2, 
				    const Vector<uInt> &colors) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  // not used
}

void QtPixelCanvas::drawColoredLines(const Vector<Double> &x1, 
				    const Vector<Double> &y1, 
				    const Vector<Double> &x2, 
				    const Vector<Double> &y2, 
				    const Vector<uInt> &colors) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  // not used
}

void QtPixelCanvas::setDrawFunction(Display::DrawFunction function) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  }

void QtPixelCanvas::setForeground(uLong color) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  // not used
}

void QtPixelCanvas::setBackground(uLong color) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  // not used
}

void QtPixelCanvas::setLineWidth(Float width) {  
   itsPen.setWidthF(width);
}

void QtPixelCanvas::setLineStyle(Display::LineStyle style) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  }

void QtPixelCanvas::setCapStyle(Display::CapStyle style) { 
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
 }

void QtPixelCanvas::setJoinStyle(Display::JoinStyle style) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  }

void QtPixelCanvas::setFillStyle(Display::FillStyle style) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  }

void QtPixelCanvas::setFillRule(Display::FillRule rule) { 
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
 }

void QtPixelCanvas::setArcMode(Display::ArcMode mode) { 
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
 }

Display::DrawFunction QtPixelCanvas::getDrawFunction() const {
  return Display::DFCopy;  }

uLong QtPixelCanvas::getForeground() const { return 0;  }

uLong QtPixelCanvas::getBackground() const { return 0;  }

void QtPixelCanvas::setImageCacheStrategy(Display::ImageCacheStrategy) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  }

  // X specific


Display::ImageCacheStrategy QtPixelCanvas::imageCacheStrategy() const {
  return Display::ServerAlways;  }


void QtPixelCanvas::flush() {  }


//#dk I _think_ we can no-op these and clear using deviceBackground...
void QtPixelCanvas::setClearColor(uInt colorIndex) {
//cerr<<"void QtPixelCanvas::setClearColor(uInt colorIndex)"<<endl;  //#diag
}
void QtPixelCanvas::setClearColor(const String &colorname) {
  //cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  //This function is called when register data. 
  }
void QtPixelCanvas::setClearColor(float r, float g, float b) {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  }
uInt QtPixelCanvas::clearColor() const {
//cerr << "uInt QtPixelCanvas::clearColor()" <<  endl;	//#diag
  return 0;  }
void QtPixelCanvas::getClearColor(float &r, float &g, float &b) const { 
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
 }



void QtPixelCanvas::setColor(uInt colorIndex) { 
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
 }

uInt QtPixelCanvas::color() const { return 0;  }

void QtPixelCanvas::getColor(float &r, float &g, float &b) const {
  cout << "WYSISWYN " << __FILE__ << " " << __LINE__ << endl;
  }

Bool QtPixelCanvas::getColor(Int x, Int y, uInt &color) {
  return False;  }

Bool QtPixelCanvas::getRGBColor(Int x, Int y, float &r, float &g, float &b) {
  return False;  }

Bool QtPixelCanvas::getHSVColor(Int x, Int y, float &h, float &s, float &v) {
  return False;  }

Bool QtPixelCanvas::resizeColorTable(uInt newSize) {
  return False;  }

Bool QtPixelCanvas::resizeColorTable(uInt nReds, uInt nGreens, uInt nBlues) {
  return False;  }
  


/*	//#diag   other trials...

QColor gr(Qt::green);cerr<<gr.red()<<"*"<<gr.green()<<"*"<<gr.blue()<<endl;//#diag
QColor gr("green");cerr<<gr.red()<<"*"<<gr.green()<<"*"<<gr.blue()<<endl;//#diag
//not same(!)  "green" is darker (0,128,0)  Qt::green is (0,255,0)

*/


