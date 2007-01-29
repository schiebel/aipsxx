//# X11PixelCanvas.h: Class defining PixelCanvas for X Windows
//# Copyright (C) 1995,1996,1997,1998,1999,2000,2001,2002
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
//# $Id: X11PixelCanvas.h,v 19.7 2006/12/22 23:31:15 dking Exp $

#ifndef TRIALDISPLAY_X11PIXELCANVAS_H
#define TRIALDISPLAY_X11PIXELCANVAS_H


#include <casa/aips.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/Vector.h>
#include <display/Display/PixelCanvas.h>
#include <display/Display/DLFont.h>
#include <display/Display/X11PixelCanvasColorTable.h>
#include <display/X11PixelCanvas/X11PCDisplayListObject.h>

#include <graphics/X11/X_enter.h>
#include <X11/Intrinsic.h>
#include <X11/Xmu/Drawing.h>
#include <graphics/X11/X_exit.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// Implementation of PixelCanvas for X11 devices.
// </summary>
//
// <prerequisite>
// <li> <linkto class="PixelCanvasColorTable">PixelCanvasColorTable</linkto>
// <li> <linkto class="X11PixelCanvasColorTable">X11PixelCanvasColorTable</linkto>
// <li> <linkto class="PixelCanvas">PixelCanvas</linkto>
// <li> Knowledge of Widgets
// </prerequisite>
//
// <etymology>
// X11PixelCanvas is an implementation of a pixel canvas using
// X11 or Xlib graphics library.
// </etymology>
//
// <synopsis>
// This class implements the specification of the
// <linkto class="PixelCanvas">PixelCanvas</linkto> in terms
// of the X11 graphics system.
//
// To create a X11PixelCanvas, you need a parent Widget and
// an <linkto class="X11PixelCanvasColorTable">X11PixelCanvasColorTable</linkto>
// pointer.
//
// Once constructed, drawing functions can be used to draw on the
// canvas and carry out other miscellaneous functions.
//
// <note>The X11PixelCanvas class should <em>never</em> be used directly after it
// has been constructed.  Instead use a 
// <linkto class="PixelCanvas">PixelCanvas</linkto>
// pointer so your application
// will be more portable across different implementations of the PixelCanvas.
// </note>
//
// Positions are defined ultimately in signed integer pixel values, with
// <0,0> representing the lower left corner pixel of the window.  So for
// a canvas size of 320x240, the upper rightmost pixel is <319,239>.  
// Integers are used because it is possible to perform drag operations
// outside the window using the mouse, so negative pixel values have
// meaning.  The X11PixelCanvas operates in three different color modes: Index,
// RGB, and HSV.  Presently RGB and HSV modes has not been completed.
// For details on how to use this class, please see the
// <linkto class="PixelCanvas">PixelCanvas</linkto> instead for a detailed
// description of how to build applications with the PixelCanvas.
// 
// Now several examples follow on how to construct one or more X11PixelCanvases,
// with an explanation of the strategy involved
// and their implications.
// 
// <ol>
// <li>Example 1 - A single shared colortable:
// <srcblock>
//
// X11PixelCanvasColorTable pcct(xscreen, Display::Index, Display::Best, Display::System);
// PixelCanvas * canvas1 = new X11PixelCanvas(myParent, &pcct, 320u, 240u);
// PixelCanvas * canvas2 = new X11PixelCanvas(myParent, &pcct, 320u, 240u);
// ...
//
// </srcblock>
// This application has requested the best index map available on the system
// colormap. 
//   <ul>
//   <li>+ application's color resources are easily resized because there is
//         only one X11PixelCanvasColorTable to worry about.
//   <li>+ Will not introduce flashing (by using the system map)
//   <li>- may fail if few colors are available
//   <li>- color resources wasted if not shared across canvases.
//   </ul>
// <li>Example 2 - two colortables equally share the system X hardware colormap
//
// <srcblock>
//
// X11PixelCanvasColorTable pcct1(xscreen, Display::Index, Display::Percent, Display::System, 50);
// X11PixelCanvasColorTable pcct2(xscreen, Display::Index, Display::Best, Display::System);
// PixelCanvas * canvas1 = new X11PixelCanvas(myParent, &pcct1, 320u, 240u);
// PixelCanvas * canvas2 = new X11PixelCanvas(myParent, &pcct2, 320u, 240u);
// 
// </srcblock>
// This application creates two colortables.  The first allocates half of whatever
// colors are available in the System map, the second allocates the remaining
// half.
//   <ul>
//   <li>+ gives independent resize control over each colortable
//   <li>- may fail if no colors available
//   <li>- colors are not shared by windows even if they could be
//   </ul>
// <li>Example 3 - two colortables equally share a private X hardware colormap
//
// <srcblock>
//
// X11PixelCanvasColorTable pcct1(xscreen, Display::Index, Display::Percent, Display::New, 50);
// X11PixelCanvasColorTable pcct2(xscreen, Display::Index, Display::Best, &pcct1);
// PixelCanvas * canvas1 = new X11PixelCanvas(myParent, &pcct1, 320u, 240u);
// PixelCanvas * canvas2 = new X11PixelCanvas(myParent, &pcct2, 320u, 240u);
// 
// </srcblock>
// This application creates two colortables.  The first allocates half of the
// new X colormap, and the second one allocates the remaining half.
//   <ul>
//   <li>+ gives independent resize control over each colortable
//   <li>- may fail if no colors available
//   <li>- colors are not shared by windows even if they could be
//   </ul>
// <li>Example 4 - Private colormap for fixed-size colortable
// <srcblock>
//
// X11PixelCanvasColorTable pcct(xscreen, Display::Index, Display::Custom, Display::New, 128);
// PixelCanvas * canvas1 = new X11PixelCanvas(myParent, &pcct, 320u, 240u);
// PixelCanvas * canvas2 = new X11PixelCanvas(myParent, &pcct, 320u, 240u);
// 
// </srcblock>
// This application creates a fixed-size private colormap for its windows.
//   <ul>
//   <li>+ custom size on new map will succede
//   <li>+ canvases share colormap space
//   </ul>
//
// </ol>
//
// Graphics are drawn onto an off-screen pixmap after which the pixmap is painted
// onto the screen.  The refresh call will always update the pixmap.
// </synopsis>
//
// <motivation>
// Needed solid foundation for a PixelCanvas
// </motivation>
//
// <example>
// see the examples in the Display/test directory
// </example>
//
class X11PixelCanvas : public PixelCanvas
{
public:
  
  // Default ctor needed for derivation of Tk canvases
  X11PixelCanvas();

  X11PixelCanvas(Widget parent, X11PixelCanvasColorTable * xpcctbl,
		 uInt width, uInt height);

  // enable/disable motion/position events
  // <group>
  virtual void enableMotionEvents();
  virtual void disableMotionEvents();
  virtual void enablePositionEvents();
  virtual void disablePositionEvents();
  // </group>

  // Does this canvas support cached display lists?  The user of the
  // canvas should always check this, because undefined behaviour can
  // result when an attempt is made to use a list on a PixelCanvas
  // which does not support lists.
  virtual Bool supportsLists()
    { return True; }

  // begin caching display commands - return list ID
  virtual uInt newList();
  // end caching display commands
  virtual void endList();
  // recall cached display commands
  virtual void drawList(uInt list);
  // translate all lists
  virtual void translateAllLists(Int xt, Int yt);
  // translate the list
  virtual void translateList(uInt list, Int xt, Int yt);
  // remove list from cache
  virtual void deleteList(uInt list);
  // flush all lists from the cache
  virtual void deleteLists();
  // return True if the list exists
  virtual Bool validList(uInt list);

  // trigger refresh callbacks with the specified reason.
  virtual void refresh(const Display::RefreshReason &reason = 
		       Display::UserCommand,
		       const Bool &explicitrequest = True);

  // Fonts and text
  Int textHeight(const String& text);
  Int textWidth(const String& text);
  Bool setFont(const String & font);

  // Set font via a DLFont object
  Bool setFont(DLFont* font) {
    return setFont(font->getXValue());
  }

  Bool setFont(const String& font, const Int size);
  void drawText(Int xoffset, Int yoffset, const String & text, 
		Display::TextAlign alignment = Display::AlignCenter);
  void drawText(Int xoffset, Int yoffset, const String & text, 
		const Float& angle, 
		Display::TextAlign alignment = Display::AlignCenter);

  // Draw an array of 2D color data as a raster image for zoom = <1,1>
  // <group>
  void drawImage(const Matrix<uInt> & data, Int xoffset, Int yoffset);
  void drawImage(const Matrix<Int> & data, Int xoffset, Int yoffset);
  void drawImage(const Matrix<uLong> & data, Int xoffset, Int yoffset);
  void drawImage(const Matrix<Float> & data, Int xoffset, Int yoffset);
  void drawImage(const Matrix<Double> & data, Int xoffset, Int yoffset);
  // </group>

  // (Cacheable) Draw an array of 2D color data as a raster image,
  // taking note of the <src>Bool</src> mask.
  // <group>
  virtual void drawImage(const Int &x, const Int &y, 
			 const Matrix<uInt> &data, 
			 const Matrix<Bool> &mask);
  // </group>

  // Draw an array of 2D color data as a raster image for any positive integer zoom
  // <group>
  void drawImage(const Matrix<uInt> & data, Int xoffset, Int yoffset, 
		 uInt xzoom, uInt yzoom);
  void drawImage(const Matrix<Int> & data, Int xoffset, Int yoffset, 
		 uInt xzoom, uInt yzoom);
  void drawImage(const Matrix<uLong> & data, Int xoffset, Int yoffset, 
		 uInt xzoom, uInt yzoom);
  void drawImage(const Matrix<Float> & data, Int xoffset, Int yoffset, 
		 uInt xzoom, uInt yzoom);
  void drawImage(const Matrix<Double> & data, Int xoffset, Int yoffset, 
		 uInt xzoom, uInt yzoom);
  // </group>

  // (Cacheable) Draw a component of a multi-channel image, storing it
  // in buffers until flushComponentImages() is called.
  void drawImage(const Matrix<uInt> &data, const Int &x, const Int &y, 
		 const Display::ColorComponent &colorcomponent);

  // Initialise the channel buffers.
  void initialiseComponents(const Int &x, const Int &y, 
			    const IPosition &shape);

  // Are the channel buffers initialised?
  Bool componentsInitialised()
    { return itsComponentsInitialised; }

  // Fill one of the channel buffers.
  void bufferComponent(const Matrix<uInt> &data,
		       const Int &x, const Int &y,
		       const Display::ColorComponent &colorcomponent);

  // (NOT CACHEABLE!) Flush the component buffers.
  void flushComponentBuffers();

  // Draw a single point using current color
  // <group>
  void drawPoint(Int x1, Int y1);
  void drawPoint(Float x1, Float y1);
  void drawPoint(Double x1, Double y1);
  // </group>
  
  // Draw a bunch of points using current color
  // <group>
  void drawPoints(const Vector<Int> & x1, const Vector<Int> & y1);
  void drawPoints(const Vector<Float> & x1, const Vector<Float> & y1);
  void drawPoints(const Vector<Double> & x1, const Vector<Double> & y1);
  // </group>

  // Draw a bunch of unrelated points using current color
  // <group>
  void drawPoints(const Matrix<Int> & verts);
  void drawPoints(const Matrix<Float> & verts);
  void drawPoints(const Matrix<Double> & verts);
  // </group>
  
  // Draw a single line using current color
  // <group>
  void drawLine(Int x1, Int y1, Int x2, Int y2);
  void drawLine(Float x1, Float y1, Float x2, Float y2);
  void drawLine(Double x1, Double y1, Double x2, Double y2);
  // </group>

  // Draw a bunch of unrelated lines using current color
  // <group>
  void drawLines(const Matrix<Int> & verts);
  void drawLines(const Matrix<Float> & verts);
  void drawLines(const Matrix<Double> & verts);
  // </group>

  // Draw a bunch of unrelated lines using current color
  // <group>
  void drawLines(const Vector<Int> & x1, const Vector<Int> & y1, 
		 const Vector<Int> & x2, const Vector<Int> & y2);
  void drawLines(const Vector<Float> & x1, const Vector<Float> & y1, 
		 const Vector<Float> & x2, const Vector<Float> & y2);
  void drawLines(const Vector<Double> & x1, const Vector<Double> & y1, 
		 const Vector<Double> & x2, const Vector<Double> & y2);
  // </group>

  // Draw a N-1 connected lines from Nx2 matrix of vertices
  // <group>
  void drawPolyline(const Matrix<Int> & verts);
  void drawPolyline(const Matrix<Float> & verts);
  void drawPolyline(const Matrix<Double> & verts);
  void drawPolyline(const Matrix<Complex> & verts);
  void drawPolyline(const Matrix<DComplex> & verts);
  // </group>

  // Draw a single polyline or connected line between the points given
  // <group>
  void drawPolyline(const Vector<Int> & x1, const Vector<Int> & y1);
  void drawPolyline(const Vector<Float> & x1, const Vector<Float> & y1);
  void drawPolyline(const Vector<Double> & x1, const Vector<Double> & y1);
  // </group>

  // Draw an N-sided polygon from Nx2 matrix of vertices
  // <group>
  void drawPolygon(const Matrix<Int> & verts);
  void drawPolygon(const Matrix<Float> & verts);
  void drawPolygon(const Matrix<Double> & verts);
  // </group>

  // Draw a closed polygon
  // <group>
  void drawPolygon(const Vector<Int> & x1, const Vector<Int> & y1);
  void drawPolygon(const Vector<Float> & x1, const Vector<Float> & y1);
  void drawPolygon(const Vector<Double> & x1, const Vector<Double> & y1);
  // </group>

  // Draw and fill a closed polygon
  // <group>
  void drawFilledPolygon(const Vector<Int> & x1, const Vector<Int> & y1);
  void drawFilledPolygon(const Vector<Float> & x1, const Vector<Float> & y1);
  void drawFilledPolygon(const Vector<Double> & x1, const Vector<Double> & y1);
  // </group>

  // Draw a rectangle
  // <group>
  void drawRectangle(Int x1, Int y1, Int x2, Int y2);
  void drawRectangle(Float x1, Float y1, Float x2, Float y2);
  void drawRectangle(Double x1, Double y1, Double x2, Double y2);
  // </group>

  // Draw a filled rectangle
  // <group>
  void drawFilledRectangle(Int x1, Int y1, Int x2, Int y2);
  void drawFilledRectangle(Float x1, Float y1, Float x2, Float y2);
  void drawFilledRectangle(Double x1, Double y1, Double x2, Double y2);
  // </group>

  //  Draw a set of points, specifying a color per point to be drawn.
  //  Most efficient when points with same color are grouped into sequences.
  // <group>
  void drawColoredPoints(const Vector<Int> & x1, const Vector<Int> & y1, 
			 const Vector<uInt> & colors);
  void drawColoredPoints(const Vector<Float> & x1, const Vector<Float> & y1, 
			 const Vector<uInt> & colors);
  void drawColoredPoints(const Vector<Double> & x1, const Vector<Double> & y1,
			 const Vector<uInt> & colors);
  virtual void drawColoredPoints(const Matrix<Int> &xy,
                                 const Vector<uInt> &colors);
  virtual void drawColoredPoints(const Matrix<Float> &xy,
                                 const Vector<uInt> &colors);
  virtual void drawColoredPoints(const Matrix<Double> &xy,
                                 const Vector<uInt> &colors);
  // </group>

  // Draw a set of lines, specifying a color per line to be drawn.
  // Most efficient when lines with same color are grouped into sequences
  // <group>
  void drawColoredLines(const Vector<Int> & x1, const Vector<Int> & y1, 
			const Vector<Int> & x2, const Vector<Int> & y2, 
			const Vector<uInt> & colors);
  void drawColoredLines(const Vector<Float> & x1, const Vector<Float> & y1, 
			const Vector<Float> & x2, const Vector<Float> & y2, 
			const Vector<uInt> & colors);
  void drawColoredLines(const Vector<Double> & x1, const Vector<Double> & y1, 
			const Vector<Double> & x2, const Vector<Double> & y2,
			const Vector<uInt> & colors);
  // </group>
  
  // Graphics Attributes
  // <group>
  void setDrawFunction(Display::DrawFunction function);
  void setForeground(uLong color);
  void setBackground(uLong color);
  //void setLineWidth(uInt width);
  void setLineWidth(Float width);
  void setLineStyle(Display::LineStyle style);
  void setCapStyle(Display::CapStyle style);
  void setJoinStyle(Display::JoinStyle style);
  void setFillStyle(Display::FillStyle style);
  void setFillRule(Display::FillRule rule);
  void setArcMode(Display::ArcMode mode);
  // </group>
  
  // Get Graphics Attributes
  // <group>
  Display::DrawFunction getDrawFunction() const;
  uLong                 getForeground()   const;
  uLong                 getBackground()   const;
  //uInt                  getLineWidth()    const;
  Float                 getLineWidth()    const;
  Display::LineStyle    getLineStyle()    const;
  Display::CapStyle     getCapStyle()     const;
  Display::JoinStyle    getJoinStyle()    const;
  Display::FillStyle    getFillStyle()    const;
  Display::FillRule     getFillRule()     const;
  Display::ArcMode      getArcMode()      const;
  // </group>

  // Option control
  // <group>
  Bool enable(Display::Option option);
  Bool disable(Display::Option option);
  // </group>

  // Control the image-caching strategy
  void setImageCacheStrategy(Display::ImageCacheStrategy strategy)
  { imageCacheStrategy_ = strategy; }
  Display::ImageCacheStrategy imageCacheStrategy() const 
  { return imageCacheStrategy_; }
  Bool usePixmapImages() const;

  // ClipWindow control
  // <group>
  void setClipWindow(Int x1, Int y1, Int x2, Int y2);
  void getClipWindow(Int & x1, Int & y1, Int & x2, Int & y2);
  // </group>

  // save/restore the current translation.
  // <group>
  virtual void pushMatrix();
  virtual void popMatrix();
  // </group>
  // zero the current translation
  virtual void loadIdentity();

  // translation functions
  // <group>
  virtual void translate(Int xt, Int yt);
  virtual void getTranslation(Int & xt, Int & yt) const;
  virtual Int xTranslation() const;
  virtual Int yTranslation() const;
  // </group>

  // set the draw buffer
  void setDrawBuffer(Display::DrawBuffer buf);

  // whole buffer memory exchanges
  // <group>
  void copyBackBufferToFrontBuffer();
  void copyFrontBufferToBackBuffer();
  void swapBuffers();
  // </group>

  // partial buffer memory exchanges.  (x1,y1 are blc, x2,y2 are trc)
  // <group>
  void copyBackBufferToFrontBuffer(Int x1, Int y1, Int x2, Int y2);
  void copyFrontBufferToBackBuffer(Int x1, Int y1, Int x2, Int y2);
  void swapBuffers(Int x1, Int y1, Int x2, Int y2);
  // </group>

  // return True if refresh is allowed, default impl is True always
  virtual Bool refreshAllowed() const 
    { return (havePixmap_ && (width_ > 0) && (height_ > 0)); }

  // Clear the window using the current clear color (default black)
  virtual void clear();
  virtual void clear(Int x1, Int y1, Int x2, Int y2);

  // Cause graphics commands to be flushed to the display
  virtual void flush() { XFlush(display_); }

  // Set the color to use for clearing the display  
  // <group>
  virtual void setClearColor(uInt color);
  virtual void setClearColor(const String & color);
  virtual void setClearColor(float r, float g, float b);
  // </group>

  // Get/set the current foreground/background colors.  These colors
  // are used when the special Strings "foreground" and "background"
  // are given for a color.
  // <group>
  virtual void setDeviceForegroundColor(const String colorname);
  virtual String deviceForegroundColor() const 
    { return itsDeviceForegroundColor; }
  virtual void setDeviceBackgroundColor(const String colorname);
  virtual String deviceBackgroundColor() const
    { return itsDeviceBackgroundColor; }
  // </group>

  // return the color used for clearing the display
  // <group>
  virtual uInt clearColor() const;
  virtual void getClearColor(float & r, float & g, float & b) const;
  // </group>
  
  // Set the current color to a string recognized by XParseColor
  void setColor(const String& colorName);
  // Set the current color to a specified index
  void setColor(uInt ColorIndex);
  // Set the current color using current colorspace
  // All values must lie in the range of [0-1]
  void setColor(float c1, float c2, float c3);
  // Set the current color using rgb colorspace
  // All values must lie in the range of [0-1]
  void setRGBColor(float r, float g, float b);
  // Set the current color to an hsv colorspace
  // All values must lie in the range of [0-1]
  void setHSVColor(float h, float s, float v);

  // Get color components in range 0 to 1 without actually 
  // allocating the color.  This is needed to set up other
  // devices, for example PgPlot.
  Bool getColorComponents(const String &colorname, Float &r, Float &g,
			  Float &b);

  // Return the current color. 
  uInt color() const;
  // Return the current color as an RGB triple;
  void getColor(float & r, float & g, float & b) const;

  // Return the color at some position
  Bool getColor(int, int, uInt &) { return False; }
  // Return the RGB values of the color at some position
  Bool getRGBColor(int, int, float &, float &, float &) { return False; }

  // Event Handling
  // <group>
  static void handleEventsEH(Widget w, X11PixelCanvas * xpc,
			    XEvent * ev, Boolean *);
  void handleEvents(Widget w, XEvent * ev);
  // </group>

  // number returned depends on mode.
  //virtual Bool getPixelValue(uInt xpos, uInt ypos, Vector<uInt> &values);

  // ILColormap * makeColormap(<constraint list>);

  // handle exposure callback
  static void exposeCB(Widget , X11PixelCanvas * xpc, XtPointer callData);

  // handle position callback
  static void positionEventCB(Widget, X11PixelCanvas * xpc, XtPointer callData);

  // handle colorTable resize
  static void colorTableResizeCB(PixelCanvasColorTable * pcctbl, uInt, 
				 X11PixelCanvas * xpc, 
				 Display::RefreshReason reason);

  // resize the colortable by requesting a new number of cells
  Bool resizeColorTable(uInt newSize);

  // resize the colortable by requesting a new color cube
  Bool resizeColorTable(uInt nReds, uInt nGreens, uInt nBlues);

  // return the pixel canvas color table
  PixelCanvasColorTable * pcctbl() const { return xpcctbl_; }

  // set the pixel canvas color table
  void setPcctbl(PixelCanvasColorTable * pcctbl)
  { xpcctbl_ = (X11PixelCanvasColorTable *) pcctbl; }

  // Return the width, height, depth of the display
  // <group>
  virtual uInt width() const { return width_; }
  virtual uInt height() const { return height_; }
  virtual uInt depth() const { return depth_; }
  // </group>

  // Get the pixel density (in dots per inch [dpi]) of the PixelCanvas
  virtual void pixelDensity(Float &xdpi, Float &ydpi) const;

  // resize the PixelCanvas to a new size
  Bool resize(uInt reqXSize, uInt reqYSize, Bool doCallbacks = True);

  // Return some things peculiar to the X11 pixel canvas
  // <group>
  ::XDisplay * display() const { return display_; }
  Screen * screen() const { return screen_; }
  Visual * visual() const { return visual_; }
  Pixmap pixmap() const { return pixmap_; }
  Window drawWindow() const { return drawWindow_; }
  GC gc() const { return gc_; }
  XColormap xcmap() const { return xpcctbl_->xcmap(); }
  X11PixelCanvasColorTable * xpcctbl() const { return xpcctbl_; }
  // </group>

  // draw mode - Display::Compile (build display list) or Display::Draw (immediate mode)
  Display::DrawMode drawMode() { return PixelCanvas::drawMode(); }

  // Request buffer is used to batch requests to the X server
  void * requestBuffer() const { return requestBuffer_; }

  // Return True if drawing commands should be sent to the pixmap
  Bool drawToPixmap() const; 

  // Return True if drawing commands should be sent to the window
  virtual Bool drawToWindow() const;
  
  // Display list caching
  void appendToDisplayList(X11PCDisplayListObject * obj);

  // Write an X Pixmap (xpm) file of the current pixmap
  virtual Bool writeXPixmap(const String &filename);

protected:

  // context
  ::XDisplay * display_;
  Visual * visual_;
  Screen * screen_;
  GC gc_;
  Window drawWindow_;
 
  // keeps dimensions of offscreen pixmap here
  // <group>
  uInt width_;
  uInt height_;
  uInt depth_;
  // </group>
 
  // colortable used by this X11PixelCanvas
  X11PixelCanvasColorTable * xpcctbl_;
 
  // True if Pixmap is valid
  Bool havePixmap_;
  // off-screen pixmap
  Pixmap pixmap_;
 
  // Which list is active - valid between newList and endList
  uInt currentList_;
  // Counter for current list - valid between newList and endList calls
  uInt currentDLCount_;
  // display lists
  PtrBlock< PtrBlock <X11PCDisplayListObject *> *> displayList_;
  // number of display lists
  Block<uInt> listCount_;
 
  // Translation stack counter - max size established by constructors
  // for blocks below in X11PixelCanvas constructor initialization list
  uInt tPtr_;
 
  // translation stack
  // <group>
  Block<Int> xTranslations_;
  Block<Int> yTranslations_;
  // </group>
 
  // Flag for first time in expose callback
  Bool exposeHandlerFirstTime_;


private:

  // test for resize of the pixel canvas dimensions, returning
  // true if the size was changed.
  Bool resize_();

  // Handle the X expose event.  This is caught by the pixel canvas
  // and forwarded as a refresh event only if the pixel canvas changed
  // dimensions.  If there was no size change, the pixel canvas simply
  // copies its pixmap to the display without generating a refresh.
  void exposeHandler_();

  // Display list optimization
  // <group>
  // Strip empty dl entries and make a new list
  Bool packDisplayList(String & str,
		       PtrBlock<X11PCDisplayListObject *> * l,
		       uInt count);
  // replace sequences of line/lines with a single lines call
  Bool applyConsecutiveLineOpt(String & s, PtrBlock<X11PCDisplayListObject *> * l);
  // replace sequences of point/points with a single point call
  Bool applyConsecutivePointOpt(String & s, PtrBlock<X11PCDisplayListObject *> * l);
  // Entry point
  Bool compactDisplayList(PtrBlock<X11PCDisplayListObject *> * l, uInt & count);
  // </group>

  // Select a list id for a new display list
  uInt pickListID();

  // resize the pixmap to match the window size
  void resizePixmap();

  // parent of the drawing canvas
  Widget parent_;

  // colortable used by this X11PixelCanvas
  //X11PixelCanvasColorTable * xpcctbl_;

  // window context
  // <group>
  //XDisplay * display_;
  //Screen * screen_;
  //Visual * visual_;
  //Window drawWindow_;
  // </group>

  // 1 graphics context per window
  //GC gc_;

  // current font
  XFontStruct * fontInfo_;

  // widget whose window is the target drawable for drawing commands
  Widget form_;
  Widget drawArea_;

  // off-screen pixmap
  //Pixmap pixmap_;
  // True if Pixmap is valid
  //Bool havePixmap_;

  // Flag for first time in expose callback
  //Bool exposeHandlerFirstTime_;

  // Which list is active - valid between newList and endList
  //uInt currentList_;
  // Counter for current list - valid between newList and endList calls
  //uInt currentDLCount_;
  // display lists
  //PtrBlock< PtrBlock <X11PCDisplayListObject *> *> displayList_;
  // number of display lists
  //Block<uInt> listCount_;

  // This is the color used when the clear command is given.
  // The screen is painted with this color when that happens.
  // Presently XFillRectangle is used because XClearWindow and
  // XClearArea require a window and cannot be used with its
  // current backing-store pixmap.
  uInt clearColor_;

  // Foreground/background colors
  String itsDeviceForegroundColor, itsDeviceBackgroundColor;
  
  // Translation stack counter - max size established by constructors
  // for blocks below in X11PixelCanvas constructor initialization list
  //uInt tPtr_;

  // translation stack
  // <group>
  //Block<Int> xTranslations_;
  //Block<Int> yTranslations_;
  // </group>

  // True if clip window is enabled
  Bool clipWindowOption_;
  // coordinates of rectangular area of clip window - given in user
  // coordinates, not X coordinates.
  // <group>
  Int clipX1_;
  Int clipY1_;
  Int clipX2_;
  Int clipY2_;
  // </group>

  // Buffer for X requests
  void * requestBuffer_;

  // keeps dimensions of offscreen pixmap here
  // <group>
  //uInt width_;
  //uInt height_;
  //uInt depth_;
  // </group>

  // 
  Display::ImageCacheStrategy imageCacheStrategy_;
  uInt serverPixmapMemoryLimit_;
  uInt serverPixmapMemoryUsed_;

  // Component / multi-channel buffers etc.
  Matrix<uInt> itsBufferedComponent1;
  Matrix<uInt> itsBufferedComponent2;
  Matrix<uInt> itsBufferedComponent3;
  Int itsBufferedComponentX, itsBufferedComponentY;
  Bool itsComponentsInitialised;

};


} //# NAMESPACE CASA - END

#endif
