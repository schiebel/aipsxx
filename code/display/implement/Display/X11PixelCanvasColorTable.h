//# X11PixelCanvasColorTable.h: color table provision for X11 devices
//# Copyright (C) 1993,1994,1995,1996,1997,1998,1999,2000,2001
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
//# $Id: X11PixelCanvasColorTable.h,v 19.7 2006/12/22 23:31:15 dking Exp $

#ifndef TRIALDISPLAY_X11PIXELCANVASCOLORTABLE_H
#define TRIALDISPLAY_X11PIXELCANVASCOLORTABLE_H

#include <graphics/X11/X_enter.h>
#if !defined(AIPS_SOLARIS)
#include <X11/Xdefs.h>
#else
typedef int Bool;
#include <X11/Xlib.h>
#endif
#include <X11/Xutil.h>
#include <graphics/X11/X_exit.h>

#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <display/Display/DisplayEnums.h>
#include <display/Display/PixelCanvasColorTable.h>

#include <graphics/X11/X11Util.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// Colormap entry for the virtual colormap.
// </summary>
//

class VColorTableEntry {
  public:
	VColorTableEntry();

	void operator=(const VColorTableEntry &);

	// Store/get the values.
	void put(const float red, const float green, const float blue)
	{	red_ = red; green_ = green; blue_ = blue;
	}

	void get(float &red, float &green, float &blue)const
	{	red = red_; green = green_; blue = blue_;
	}

	uInt	getIndex()const{return index_;}
	void	setIndex(const uInt i){index_ = i;}

	uLong getPixel()const{return pixel_;}
	void setPixel(const unsigned long p){pixel_ = p;}

	friend ostream &operator<<(ostream &s, const VColorTableEntry &x);

  private:
	uInt	index_;		// Index into map for this entry.
	uLong	pixel_;	// Real index or color value.
	float	red_, green_, blue_; // Color component values. (0..1).
};

// <summary>
// Implementation of PixelCanvasColorTable for X11 devices.
// </summary>
//
// <prerequisite>
// <li> <linkto class="PixelCanvasColorTable">PixelCanvasColorTable</linkto>
// <li> How to get the X Screen pointer.
// <li> Basic understanding of X Windows color resource limitations
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// The class represents the abstract notion of a colortable - a normally fixed-size
// set of colorcells to be further divided among
// <linkto class="Colormap">Colormap</linkto>s if used in Index mode or to be used
// to create an RGB or HSV color cube for use in multichannel color.  The constructors take a
// wide variety of parameters and construct a colortable using those parameters in the
// context of the available hardware.  The class then figures out the best way to 
// implement that using the capabilities of the X library. 
//
// <note>This class is <em>only</em> used at construction time.  It should
// <b>never</b> be accessed directly any time after that.  All access must
// go through the PixelCanvas or one of its derived classes. </note>
//
// The parameters specify the mode (Index, RGB, HSV), a strategy for allocating
// colors, a strategy for sharing resources, and extra parameters as needed for
// the color allocation strategy.  This level of specification
// completely abstracts away the management and ideosyncrasies of those X constructs
// that most people would just as well not know about.  I've found that in
// using this system it is easy to experiment with the color allocation without
// changing well-behaved application code.
//
// X11 is quite a hairy system.  The typical programmer has to know many details
// of their own system and about the X library, such as visuals, depths, and so
// on.  He has to know what constraints the X library imposes, what visuals can
// be used and how.  The X learning curve is way too high for someone who just wants
// to piece together a simple program.  Then, if the program is supposed to be broadly
// used, it has to be written to recognize and use different hardware configurations.
// 
// The purpose of this class is to provide a model for handling color which is 
// built using high-level concepts to be passed as an argument to an X11PixelCanvas
// as shown in the following example, which creates two canvases, the first builds an
// X11PixelCanvasColorTable configured as an RGB color cube using 67% of the available
// colors on the System X Colormap, and the second shares the hardware X Colormap the 
// first one used and builds another X11PixelCanvsColorTable configured for Index
// mode.
//
// <srcblock>
// // Display X11 implementation is Screen based, NOT Display based.  The Display
// // can be obtained from the screen.
// Screen * screen = DefaultScreenOfDisplay(X11DefaultDisplay());
//
// X11PixelCanvasColorTable pcctbl1(screen, Display::RGB, Display::Percent, Display::System, 67.0);
// X11PixelCanvasColorTable pcctbl2(screen, Display::Index, Display::Percent, pcctbl1, 100.0);
// </srcblock>
//
// If you run your program and discover that you maybe don't care about flashing with
// other programs, but you don't want flashing within your own, simply replace
// the "Display::System" above with "Display::New".  Display::New in the 4th position tells the
// constructor to create a new hardware colormap (See constructors below for
// complete information).  Pcctbl 2 has already been told to use whatever
// map pcctbl1 is using, so they will share that table.
//
// <srcblock>
// X11PixelCanvasColorTable pcctbl1(screen, Display::RGB, Display::Percent, Display::New, 67.0);
// X11PixelCanvasColorTable pcctbl2(screen, Display::Index, Display::Percent, pcctbl1, 100.0);
// </srcblock>
//
// Now suppose you've got this great image you want to see, and you don't care about
// flashing between your to maps.  You just want the map #1 to be the best RGB map
// it can be.  And you have a special Colormap that contains 128 table entries.
// So switch strategies from percent available to best, and remove the
// extra parameter, and allocate both from new maps.
//
// <srcblock>
// X11PixelCanvasColorTable pcctbl1(screen, Display::RGB, Display::Best, Display::New);
// X11PixelCanvasColorTable pcctbl2(screen, Display::Index, Display::Custom, Display::New, 128);
// </srcblock>
//
// You can see that this is a simple way of piecing together hardware colormap
// arrangements according to your needs.  5 basic strategies, 3 color configurations,
// control over colortable sharing, and control over "flashing" make
// this quite a flexible system.  Its simplicity means that it is easy to change the
// underlying color allocation arrangement.  The design of the library encourages
// the construction of applications that can work with just about any color configuration.
//
// The Display library handles the allocation and deletion of shared resources
// behind the scenes in the <linkto class="X11ResourceManager">X11ResourceManager
// </linkto> class.  
//
// Once constructed, a pointer to the 
// <linkto class="X11PixelCanvasColorTable">X11PixelCanvasColorTable</linkto>
// is sent to the constructor of a
// <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
// and provides all the color handling functionality.
//
// The <linkto class="X11PixelCanvasColorTable">X11PixelCanvasColorTable</linkto>
// can be shared by several <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>es
// if desired.  This arrangement would provide several windows whose colors were
// liked together. 
//
// Another arrangement is more than one X11PixelCanvasColorTable
// on a the same X11 hardware colormap.  This is done by passing an
// existing X11PixelCanvasColorTable in the refmap, or 3rd parameter
// of the constructor.  This gives you independent, smaller colormaps
// without flashing. 
//
// The PixelCanvasColorTable is distinguished from the <linkto class = "Colormap">
// Colormap</linkto> by its functionality.  There is one and only one
// PixelCanvasColorTable for each PixelCanvas.  It controls the <em>allocation</em>
// of containers for colors. 
//
// If the map is in Display::Index mode, you can install one or more
// <linkto class = "Colormap">Colormaps</linkto> that control banks
// of colors in the X11PixelCanvasColorTable because Colormaps define the <em>colors</em>
// that go into the containers of a PixelCanvasColorTable.
//
// If the map is in Display::RGB or Display::HSV mode, the PixelCanvases that use it
// can map multichannel color arrays into a single color index array using mapToColor3
// functions.
//
// The levels of colormaps from an application programmer's perspective are as follows:
// <ul>
// <li>Lowest:  (Built-in) Installable X System Colormaps (usually 1, 13 avail on SGI systems)
//
// <li>Medium:  (Display Library) X11PixelCanvasColorTable (Static allocation of a portion of
//                                            the above using X calls, but can force resize to
//                                            allow for changing resource availability.)
//
// <li>Highest: (Display Library) <linkto class="Colormap">Colormap</linkto>
//  (Dynamic allocation of a ColorTable)
// </ul>
//
// One common way of building X applications is to try to get some range of color allocation
// from the system colormap, then fall back to using a private map if that fails.  This multiple
// attempt method can be implemented using the library in combination with catching exceptions:
//
// <srcblock>
// // returns 0 if can allocate anything.
// X11PixelCanvasColorTable * pickXPCCT()
// {
//   X11PixelCanvasColorTable * xpcct = 0;
//   try {
//      // first try - get some number between 40 and 64 colors
//      // using the system colormap
//      xpcct = new X11PixelCanvasColorTable(screen,
//                                           Display::Index,
//                                           Display::MinMax,
//                                           Display::System,
//                                           40,64);
//      } catch (AipsError x) {
//      xpcct = 0;
//      }
//
//   if (xpcct) return;
//
//    try {
//      // second try - get 64 from a private map
//      xpcct = new X11PixelCanvasColorTable(screen,
//                                            Display::Index,
//                                            Display::Custom,
//                                            Display::New,
//                                            64);
//      } catch (AipsError x) {
//      xpcct = 0;
//      }
//
//   return xpcct;
// }
// </srcblock>
//
//
// If in Display::Index mode, the application program can get information about active 
// Colormaps using the PixelCanvas interface.  Code to refresh the display often needs
// to know the size of the colortables,
// which could change between refreshes, to correctly map values to [0,size-1] and
// on to colorIndices using <linkto class="PixelCanvas">PixelCanvas</linkto>'s
// mapToColor functions.
//
// If in Display::RGB or Display::HSV mode, the application can get color cube size
// information if necessary, but should instead send normalized arrays to mapToColor3
// functions.
// </synopsis>
//
// <motivation>
// Wanted to be able harness the power and flexibility of the X Color Resources
// in a simple way and minimize the knowledge of X required to use this
// power and flexibility. 
// </motivation>
//
// <example>
// See the test directory
// </example>
//
// <todo>
// <li> Implement RGB resize.
// <li> handle forcing a particular depth (via options?)
// </todo>
//

class X11PixelCanvasColorTable : public PixelCanvasColorTable
{
public:

  // Thought about having a Motif-style varargs constructor, but this interface
  // is much cleaner from the perspective of application code.  So I favor making
  // lots of constructors to make the code more readable, and this gives you tighter
  // compile-time checking.

  // Default constructor uses default INDEX mode and DEFAULT colormap on DEFAULT visual.
  // equiv to (DefaultScreenOfDisplay(DefaultDisplay), IL_INDEX, IL_DEFAULT, IL_SYSTEM);
  X11PixelCanvasColorTable();

  // Dtor
  ~X11PixelCanvasColorTable();

  // All of these constructors have 4 required parameters
  // <ol>
  // <li> screen - pointer to X11 screen structure
  // <li> mapType
  // <ul>
  // <li> Display::Index - make map to be accessed by index (standard colormap)
  // <li> Display::RGB   - make an RGB map
  // <li> Display::HSV   - make an HSV map
  // </ul>
  // <li> strategy
  // <ul>
  // <li> Display::Best - make the best map possible using reference map
  // <li> Display::Default - make the default map on the reference
  // <li> Display::MinMax - make a map that satisfies range of parameter requirements
  // <li> Display::Custom - make a customized map
  // <li> Display::Percent - make a map that uses a percent of available resources
  // </ul>
  // <li> refMap
  // <ul>
  // <li> Display::System - use the system's map
  // <li> Display::New - make a new map 
  // <li> &ltvariable&gt - use the same map that another X11PixelCanvasColorTable is using.
  // </ul>
  // </ol>
  //
  // Additional parameters may be required according to combination of variables:
  // <ul>
  // <li> for Display::Index:
  // <ul>
  // <li> Display::MinMax requires two additional uInt params for min and max colors
  // <li> Display::Custom requires one additional uInt param for # of cells to alloc
  // <li> Display::Percent requires one additional uInt or Float param for % alloc
  // </ul>
  // <li> for Display::RGB:
  // <ul>
  // <li> Display::MinMax requires six uInt parms for min R,G,B and max R,G,B resolution
  // <li> Display::Custom requires three uInt parms for resolution in R,G,B
  // <li> Display::Percent requires one additional uInt or Float param for % alloc
  // </ul>
  // <li> for Display::HSV:
  // <ul>
  // <li> Display::MinMax requires six uInt parms for min H,S,V and max H,S,V resolution
  // <li> Display::Custom requires three uInt parms for resolution in H,S,V
  // <li> Display::Percent requires one additional uInt or Float param for % alloc
  // </ul>
  // </ul>
  //
  // <note role="tip">If you use hard-coded numbers for uInts or Floats, be sure to
  // let the compiler know it is unsigned (e.g., "(uInt)32" or "32U", not "32").  Numbers
  // are normally treated as signed.</note>
  //
  // An exception is thrown if the combination of parameters is invalid or if
  // the requested map cannot be created due to limited resources.  A good strategy
  // is to make several constructor requests, starting with the constraints you
  // need using successive relaxation, until the constructor does not throw an
  // exception.
  //
  // Most applications use the MinMax strategy because of its tolerance.
  //
  // <group>
  X11PixelCanvasColorTable(Screen * screen, Display::ColorModel mapType, Display::Strategy strategy,
			 Display::SpecialMap refMap);
  X11PixelCanvasColorTable(Screen * screen, Display::ColorModel mapType, Display::Strategy strategy,
			 const X11PixelCanvasColorTable & refMap);
  X11PixelCanvasColorTable(Screen * screen, Display::ColorModel mapType, Display::Strategy strategy,
			 Display::SpecialMap refMap, uInt parm);
  X11PixelCanvasColorTable(Screen * screen, Display::ColorModel mapType, Display::Strategy strategy,
			 const X11PixelCanvasColorTable & refMap, uInt parm);
  X11PixelCanvasColorTable(Screen * screen, Display::ColorModel mapType, Display::Strategy strategy,
			 Display::SpecialMap refMap, Float perecent);
  X11PixelCanvasColorTable(Screen * screen, Display::ColorModel mapType, Display::Strategy strategy,
			 const X11PixelCanvasColorTable & refMap, Float percent);
  X11PixelCanvasColorTable(Screen * screen, Display::ColorModel mapType, Display::Strategy strategy,
			 Display::SpecialMap refMap, uInt minCells, uInt maxCells);
  X11PixelCanvasColorTable(Screen * screen, Display::ColorModel mapType, Display::Strategy strategy,
			 const X11PixelCanvasColorTable & refMap, uInt minCells, uInt maxCells);
  X11PixelCanvasColorTable(Screen * screen, Display::ColorModel mapType, Display::Strategy strategy,
			 Display::SpecialMap refMap, uInt n1, uInt n2, uInt n3);
  X11PixelCanvasColorTable(Screen * screen, Display::ColorModel mapType, Display::Strategy strategy,
			 const X11PixelCanvasColorTable & refMap, uInt n1, uInt n2, uInt n3);
  X11PixelCanvasColorTable(Screen * screen, Display::ColorModel mapType, Display::Strategy strategy,
			 Display::SpecialMap refMap, uInt min1, uInt min2, uInt min3,
			 uInt max1, uInt max2, uInt max3);
  X11PixelCanvasColorTable(Screen * screen, Display::ColorModel mapType, Display::Strategy strategy,
			 const X11PixelCanvasColorTable & refMap, uInt min1, uInt min2,
			 uInt min3, uInt max1, uInt max2, uInt max3);
  // </group>


  // Additional constructors for use when an X colormap has already
  // been allocated.  Only the strategies Display::Percent and 
  // Display::MinMax are provided at present.
  // <group>
  X11PixelCanvasColorTable(Screen * screen, Display::ColorModel mapType, 
			   Display::Strategy strategy,
			   XColormap useXCmap,
			   Visual *useVisual,
			   uInt parm);
  X11PixelCanvasColorTable(Screen * screen, Display::ColorModel mapType, 
			   Display::Strategy strategy,
			   XColormap useXCmap,
			   Visual *useVisual,
			   uInt minCells, uInt maxCells);
  X11PixelCanvasColorTable(Screen * screen, Display::ColorModel mapType, 
			   Display::Strategy strategy,
			   XColormap useXCmap,
			   Visual *useVisual,
			   uInt min1, uInt min2, uInt min3,
			   uInt max1, uInt max2, uInt max3);
  // </group>

  // Get a PseudoColor Visual and map based on mapRef enum
  void setPCVisualXCmap(Display::SpecialMap mapRef);

  // use an existing map
  void setPCVisualXCmap(XColormap useXCmap, Visual *useVisual);

  // allocate cells for colormaps
  Bool allocCells(uInt nCells);

  // deallocate cells for colormaps
  Bool deallocCells();

  // Functions to choose a visual.
  // <group>
  Visual * bestRGBVisual();
  Visual * bestRWRGBVisual();
  // </group>

  // Functions to build for Index colorModels
  // <group>
  void buildMapIndexBest();
  void buildMapIndexDefault();
  void buildMapIndexMinMax(uInt minCells, uInt maxCells);
  void buildMapIndexCustom(uInt nCells);
  void buildMapIndexPercent(Float percent);
  // </group>

  // (Multichannel Color)
  // Merge separate channel data into an output image.
  // This function maps floating values between 0 and 1
  // into a output image suitable for PixelCanvas::drawImage().

  // Allocate the best color cube given the map
  Bool allocColorCube();
  // Allocate a color cube of a specific size
  Bool allocColorCube(uInt n1, uInt n2, uInt n3);
  // Allocate a color cube within the ranges of sizes
  Bool allocColorCubeMinMax(uInt n1min, uInt n2min, uInt n3min,
			    uInt n1max, uInt n2max, uInt n3max);
  // Copy color cube info from the mapRef
  void copyColorCube(const X11PixelCanvasColorTable & mapRef);
  // Fill a color cube with an RGB spectrum
  void fillColorCubeRGB();
  // Fill a color cube with an HSV spectrum
  void fillColorCubeHSV();

  // Convenience function
  void buildMaxHSV();

  // Merge separate channel data into an output image.
  // This function maps floating values between 0 and 1
  // into a output image suitable for PixelCanvas::drawImage().
  // <group>
  void mapToColor3(Array<uLong> & out,
		   const Array<Float> & chan1in,
		   const Array<Float> & chan2in,
		   const Array<Float> & chan3in);
  void mapToColor3(Array<uLong> & out,
		   const Array<Double> & chan1in,
		   const Array<Double> & chan2in,
		   const Array<Double> & chan3in);
  // </group>

  // This one maps values between 0 and the integer
  // maximum value for each channel into a single
  // output image suitable for PixelCanvas::drawImage().
  // <group>
  void mapToColor3(Array<uLong> & out,
		   const Array<uShort> & chan1in,
		   const Array<uShort> & chan2in,
		   const Array<uShort> & chan3in);
  void mapToColor3(Array<uLong> & out,
		   const Array<uInt> & chan1in,
		   const Array<uInt> & chan2in,
		   const Array<uInt> & chan3in);
  // </group>  

  // (Multichannel Color)
  // Transform arrays from the passed color model into
  // the colormodel of the XPCCT.
  // Does nothing if colorModel is Display::Index.
  // It is assumed that input arrays are in the range of [0,1]
  Bool colorSpaceMap(Display::ColorModel, 
		     const Array<Float> & chan1in, 
		     const Array<Float> & chan2in, 
		     const Array<Float> & chan3in, 
		     Array<Float> & chan1out, 
		     Array<Float> & chan2out, 
		     Array<Float> & chan3out);  

  // Functions for RGB mode
  // <group>
  // Build the best map you can on mapRef's colormap
  void buildMapRGBBest(const X11PixelCanvasColorTable & mapRef);
  void buildMapRGBBest(Display::SpecialMap mapRef);
  void buildMapRGBDefault(const X11PixelCanvasColorTable & mapRef);
  void buildMapRGBDefault(Display::SpecialMap mapRef);
  void buildMapRGBMinMax(const X11PixelCanvasColorTable & mapRef,
			 uInt minReds, uInt minGreens, uInt minBlues,
			 uInt maxReds, uInt maxGreens, uInt maxBlues);
  void buildMapRGBMinMax(Display::SpecialMap mapRef,
			 uInt minReds, uInt minGreens, uInt minBlues,
			 uInt maxReds, uInt maxGreens, uInt maxBlues);
  void buildMapRGBCustom(const X11PixelCanvasColorTable & mapRef,
			 uInt nReds, uInt nGreens, uInt nBlues);
  void buildMapRGBCustom(Display::SpecialMap mapRef,
			 uInt nReds, uInt nGreens, uInt nBlues);
  void buildMapRGBPercent(const X11PixelCanvasColorTable & mapRef,
			 Float percent);
  void buildMapRGBPercent(Display::SpecialMap mapRef,
			  Float percent);
  // </group>

  // Functions for HSV mode
  // <group>
  void buildMapHSVBest(const X11PixelCanvasColorTable & mapRef);
  void buildMapHSVBest(Display::SpecialMap mapRef);
  void buildMapHSVDefault(const X11PixelCanvasColorTable & mapRef);
  void buildMapHSVDefault(Display::SpecialMap mapRef);
  void buildMapHSVMinMax(const X11PixelCanvasColorTable & mapRef,
			 uInt minHues, uInt minSats, uInt minVals,
			 uInt maxHues, uInt maxSats, uInt maxVals);
  void buildMapHSVMinMax(uInt minHues, uInt minSats, uInt minVals,
			 uInt maxHues, uInt maxSats, uInt maxVals);
  void buildMapHSVCustom(const X11PixelCanvasColorTable & mapRef,
			 uInt nHues, uInt nSats, uInt nVals);
  void buildMapHSVCustom(uInt nHues, uInt nSats, uInt nVals);
  void buildMapHSVPercent(const X11PixelCanvasColorTable & mapRef,
			 Float percent);
  void buildMapHSVPercent(Display::SpecialMap mapRef,
			  Float percent);
  // </group>

  // map [0,N-1] into colorpixels, where N is the current colormap size
  // The values are returned as unsigned integers in their respective 
  // array.  
  // <note role="tip">The choice of what type to use should be guided by
  // the number of graphics bitplanes available.  For most systems with
  // 8-bit color, uChar is optimal.  Some systems with 12 bits per pixel
  // with an alpha channel may require using the uLong. </note>
  //
  // <note role="warning">uChar type may not have enough bits
  // to hold the pixel index on some high-end graphics systems </note>
  // <note role="warning">uShort type may not have enough bits
  // to hold the pixel index on some high-end graphics systems </note>
  // <group>
  void mapToColor(const Colormap * map, Array<uChar> & outArray, 
		  const Array<uChar> & inArray, Bool rangeCheck = True) const;
  void mapToColor(const Colormap * map, Array<uShort> & outArray, 
		  const Array<uShort> & inArray, Bool rangeCheck = True) const;
  void mapToColor(const Colormap * map, Array<uInt> & outArray, 
		  const Array<uInt> & inArray, Bool rangeCheck = True) const;
  void mapToColor(const Colormap * map, Array<uLong> & outArray, 
		  const Array<uLong> & inArray, Bool rangeCheck = True) const;
  // </group>

  // same as above except the matrix is operated on in place.  Only unsigned
  // values make sense here.  I don't really know what to include here.  Maybe
  // ask the code cop.
  // <group>
  void mapToColor(const Colormap * map, Array<uChar> & inOutArray, 
		  Bool rangeCheck = True) const;
  void mapToColor(const Colormap * map, Array<uShort> & inOutArray, 
		  Bool rangeCheck = True) const;
  void mapToColor(const Colormap * map, Array<uInt> & inOutArray, 
		  Bool rangeCheck = True) const;
  void mapToColor(const Colormap * map, Array<uLong> & inOutArray, 
		  Bool rangeCheck = True) const;
  // </group>
  
  // print details of class to ostream
  friend ostream & operator << (ostream & os, const X11PixelCanvasColorTable & pcc);

  // Is the hardware colormap resizeable?  ie. is it write-only?
  virtual Bool staticSize() 
    { return (readOnly_ && decomposedIndex_); }

  // resize the map if allowed.  Returns True if resize was accepted
  // <group>
  Bool resize(uInt newSize);
  Bool resize(uInt nReds, uInt nGreens, uInt nBlues);
  // </group>

  // Install colors into the color table.  Offset is zero-based.  Colors
  // are installed into the PixelCanvasColorTable until the Arrays run out
  // or until the end of the colortable is reached.  This only has an
  // effect if the ColorModel is Index.  Values are clamped to [0.0,1.0].
  Bool installRGBColors(const Vector<Float> & r, const Vector<Float> & g, 
			const Vector<Float> & b, uInt offset = 0);

  // Return the best index for the RGB values given
  // in INDEX mode, this means an exact match unless we cannot resize to 
  //   accomodate XAllocColorCell if required.
  // in RGB mode, this means map to index according to makeup of the map
  // in HSV mode, this means convert to HSV and call HSV2Index()
  uInt RGB2Index(float r, float g, float b);

  // Return the best index for the HSV values given
  // in INDEX mode, convert to RGB and call RGB2Index
  // in RGB mode, convert to RGB and call RGB2Index()
  // in HSV mode, map to index according to makeup of the map
  uInt HSV2Index(float h, float s, float v);

  // Return the total number of RW colors currently in use.
  uInt nColors() const;

  // Return the number of colors per component in the map.  Throws
  // an exception if this is not an HSV or RGB ColorTable.
  virtual void nColors(uInt &n1, uInt &n2, uInt &n3) const;

  // Return the depth in bits of the colors
  uInt depth() const;
  
  // Return the number of colors that are still unallocated
  uInt nSpareColors() const;

  // Return pointer to display that is being used
  ::XDisplay * display() const;
  // Return pointer to screen that is being used
  Screen * screen() const;
  // Return pointer to visual that is being used
  Visual * visual() const;
  // Return XID of X "virtual colormap" being used
  XColormap xcmap() const;
  
  // Return True if the table is in colorIndex mode
  Bool indexMode() const { return (colorModel_ == Display::Index); }
  // Return True if the table is in RGB mode
  Bool rgbMode() const { return (colorModel_ == Display::RGB); }
  // Return True if the table is in HSV mode
  Bool hsvMode() const { return (colorModel_ == Display::HSV); }

  // Return True if the colortable can be resized.
  Bool rigid() const { return rigid_; }

  // Return the color model for multichannel color
  Display::ColorModel colorModel() const { return colorModel_; }
  Bool readOnly()const{return readOnly_;}
  Bool decomposedIndex()const{return decomposedIndex_;}
  // Return the number of currently unallocated cells that can be allocated RW.
  uInt QueryColorsAvailable(const Bool contig)const;
  virtual uInt QueryHWColorsAvailable(const Bool contig)const;
  // Convert a virtual index to a physical pixel.
  Bool virtualToPhysical(const unsigned long vindex,
			  unsigned long &pindex)const;
  // Store an RGB value at virtual index.
  void storeVColor(const uInt vindex,
		   const float r, const float g, const float b);
private:

  // Return the log power 2 of n and return True if n is
  // a power of two.  Otherwise return false.
  Bool isPow2(uInt n, uInt & log2n);

  // (Multi-Channel) Return the index given r,g,b values
  uInt tripletIndex(float r, float g, float b);

  // (Multi-Channel)
  void setupColorCube(uLong n1, uLong n2, uLong n3,
		      uLong n1m, uLong n2m, uLong n3m);
  // (Multi-Channel)
  void setupStandardMapping(const XStandardColormap * mapInfo);

  // A pointer to the XDisplay 
  ::XDisplay * display_;
  // A pointer the the X Screen
  Screen * screen_;
  // A pointer to the X Visual
  Visual * visual_;
  // A pointer to the XColormap (X Hardward colormap)
  XColormap xcmap_;

  // (Valid Always) number of bits of depth
  uInt depth_;
  // (Valid Always) number of total colors available for RW.
  uInt nColors_;
  // (Valid only when implementation uses a PseudoColor or a
  // StaticColor visual).  Table of color indices available.
  uLong * colors_;	// converts pixel index into vcmap index. Always valid.
  uShort vcmapLength_;	// Length of virtual colormap.
				// (& HW map if it exists)
  VColorTableEntry *vcmap_;
  // (Valid Always)
  // True if the table may not be resized, such as when a
  // standard XColormap is used.  Generally this is set to True
  // unless the visual is PseudoColor/StaticColor and the color
  // model is Display::Index.
  Bool rigid_;
  ////////////////////////////////////////////////////////////////
  // True if the colormap is read only.
  Bool	readOnly_;
  // True if TrueColor or DirectColor.
  Bool  decomposedIndex_;
  void checkVisual(Visual *v=0);
  // Write an RGB value to hardware colormap at physical index.
  // (Called by storeVColor()).
  virtual void storeColor(const uLong pindex,
		   const float r, const float g, const float b);
  // Shift counts, masks, and max values used to build pixels for
  // decomposed index colormaps.
  unsigned short red_shift_, green_shift_, blue_shift_;
  unsigned short red_max_, green_max_, blue_max_;
  unsigned long red_mask_, green_mask_, blue_mask_;
  // Convert from integer HSV components to RGB pixel components.
  void HSV2RGB(const uLong H, const uLong S, const uLong V,
	       uLong &R, uLong &G, uLong &B);

  ////////////////////////////////////////////////////////////////
  // (Valid only for multi-channel color modes (RGB, HSV, etc))
  // If true, then the color cube's sides are powers of two,
  // making indexing possible with shift/add using the values of
  // <nBits1_, nBits2_, nBits3_>.  If not true, indexing
  // using <n1_,n2_,n3_> and multiplication is required. 
  Bool pow2Mapping_;

  // (Valid Always)
  // The colormodel that this X11PixelCanvasColorTable has been 
  // configured as.
  Display::ColorModel colorModel_;

  // (Valid only for multi-channel color modes (RGB, HSV, etc))
  // Represents the first cell used for the color cube.
  // baseColor_ is zero for PseudoColor/StaticColor implementations
  // because they use a table.
  uLong baseColor_;

  // (Valid only for multi-channel color modes (RGB, HSV, etc))
  // Specifies the color resolution for each side of the
  // color cube.
  // index = n1Mult_*R + n2Mult_*G + n3Mult_*B for RGB in
  // the range of <[0,n1_-1],[0,n2_-1],[0,n3_-1]>
  // <group>
  uInt n1_;
  uInt n2_;
  uInt n3_;

  uInt n1Mult_;
  uInt n2Mult_;
  uInt n3Mult_;
  // </group>

  // (Valid only for multi-channel color modes (RGB, HSV, etc))
  // and when pow2Mapping is true.
  // index = (R << n1Shift_) | (G << n2Shift_) | (B << n3Shift_)
  // for RGB the range of <[0,n1_-1],[0,n2_-1],[0,n3_-1]>
  // <group>
  uInt n1Bits_;
  uInt n2Bits_;
  uInt n3Bits_;

  uInt n1Shift_;
  uInt n2Shift_;
  uInt n3Shift_;
  // </group>
};


} //# NAMESPACE CASA - END

#endif
