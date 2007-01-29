//# X11PCColorTable.cc: implementation of ColorTable for X11PixelCanvas
//# Copyright (C) 1993,1994,1995,1996,1998,1999,2000,2001,2002
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
//#$Id: X11PCColorTable.cc,v 19.5 2005/06/15 17:56:36 cvsmgr Exp $

#include <casa/Logging/LogIO.h>
#include <display/Display/ColorConversion.h>
#include <display/Display/ColorDistribution.h>
#include <graphics/X11/X11Util.h>
#include <display/Display/X11ResourceManager.h>
#include <display/Display/X11PixelCanvasColorTable.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/VectorIter.h>
#include <casa/BasicMath/Math.h>
#include <casa/iostream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// couldn't get the thing to compile with inlines.  Maybe had
// other probs.  Will try to put them back later.
uInt X11PixelCanvasColorTable::nColors() const { return nColors_; }
uInt X11PixelCanvasColorTable::depth() const { return depth_; }
uInt X11PixelCanvasColorTable::nSpareColors() const {
	return QueryColorsAvailable(False); }
XDisplay * X11PixelCanvasColorTable::display() const { return display_; }
Screen * X11PixelCanvasColorTable::screen() const { return screen_; }
Visual * X11PixelCanvasColorTable::visual() const { return visual_; }
XColormap X11PixelCanvasColorTable::xcmap() const { return xcmap_; }

// Return the number of colors per component in the map.
void X11PixelCanvasColorTable::nColors(uInt &n1, uInt &n2, uInt &n3) const {
  if ((colorModel_ == Display::RGB) || (colorModel_ == Display::HSV))
  {	if( decomposedIndex())			// Use actual HW value.
	{	n1 = red_max_+1;
		n2 = green_max_+1;
		n3 = blue_max_+1;
		return;
	}
	else				// Use values computed from colormap.
	{	n1 = n1_;
		n2 = n2_;
		n3 = n3_;
		return;
	}
  } else {
    throw(AipsError("Cannot count component colors in non-HSV/RGB "
		    "PixelCanvasColorTable"));
  }
}

// #define X11PixelCanvasColormapInitList ...

// Count the # of trailing 0 bits in a #. (Amount needed to shift a value).
static inline unsigned short shiftcount(const unsigned long v)
{ unsigned int mask = 1;
  const short nbits = sizeof(v)*8;
  register int i;
	for(i=0; i<nbits; i++,mask += mask)
		if(mask&v)
			break;
	return i;
}

// Length of virtual color table to use when dealing with RO colormaps.
// The size is chosen to match PostScript capabilities.
static const uInt VIRTUAL_CMAP_SIZE = 4096;

// Initialize info for virtual colormap decomposed index handling.
void X11PixelCanvasColorTable::checkVisual(Visual *visual)
{
	if(visual == 0)
		visual = visual_;
	else
		visual_ = visual;

	switch( visual->c_class) {
	case StaticGray:
		readOnly_ = True;
		decomposedIndex_ = False;
		break;
	case GrayScale:
		readOnly_ = False;
		decomposedIndex_ = False;
		break;
	case StaticColor:
		readOnly_ = True;
		decomposedIndex_ = False;
		break;
	case TrueColor:
		readOnly_ = True;
		decomposedIndex_ = True;
		break;
	case DirectColor:
		readOnly_ = False;
		decomposedIndex_ = True;
		break;
	case PseudoColor:
	default:
		readOnly_ = False;
		decomposedIndex_ = False;
		break;
	}
	// Initialize the virtual colormap. Possibly not the best place to
	// do it, but I don't have a better place yet.
	if(colors_ == static_cast<uLong *>(0))
	{ uInt len;
		if(!readOnly_)
			len = visual->map_entries;
		else
			len = VIRTUAL_CMAP_SIZE;

		colors_ = new uLong[len];
		vcmap_ = new VColorTableEntry[len];
		vcmapLength_ = len;
		// Set initial defaults.
		for(uInt i =0; i< len; i++)
		{	colors_[i] = i;
			vcmap_[i].setPixel(i);
			vcmap_[i].setIndex(i); // To go from pixel/rgb to vIndex.
		}
	}

	// Initialize TC pixel mask, shift & max values.
	if(decomposedIndex_)
	{	red_mask_ = visual->red_mask;
		red_shift_ = shiftcount(red_mask_);
		if(red_shift_ > 0)
			red_max_ = (int)(red_mask_ >> red_shift_);
		else
			red_max_ = (int)red_mask_;

		green_mask_ = visual->green_mask;
		green_shift_ = shiftcount(green_mask_);
		if(green_shift_ > 0)
			green_max_ = (int)(green_mask_ >> green_shift_);
		else
			green_max_ = (int)green_mask_;

		blue_mask_ = visual->blue_mask;
		blue_shift_ = shiftcount(blue_mask_);
		if(blue_shift_ > 0)
			blue_max_ = (int)(blue_mask_ >> blue_shift_);
		else
			blue_max_ = (int)blue_mask_;
	}
	else
	{	red_shift_ = green_shift_ = blue_shift_ = 0;
		red_max_ = green_max_ = blue_max_ = 0;
		red_mask_ = green_mask_ = blue_mask_ = 0;
	}
}

//
//  Get a PseudoColor Visual and map based on mapRef enum
//
void X11PixelCanvasColorTable::setPCVisualXCmap(Display::SpecialMap mapRef)
{
  if (mapRef == Display::New)
    {
      visual_ = X11BestVisual(screen_, PseudoColor);
      if (!visual_)
	throw(AipsError("setPCVisualXCmap - Did not get a PseudoColor visual"));
      xcmap_ = XCreateColormap(display_, RootWindowOfScreen(screen_), visual_, AllocNone);
      X11ResourceManager::refColormap(screen_, xcmap_);
    }
  else if (mapRef == Display::System)
    {
      // visual_ = X11DefaultVisual(screen_, PseudoColor);
      visual_ = DefaultVisualOfScreen(screen_);
      if (!visual_)
	throw(AipsError("setPCVisualXCmap Did not get a PseudoColor visual"));
      xcmap_ = DefaultColormapOfScreen(screen_);
    }
   checkVisual();
}

void X11PixelCanvasColorTable::setPCVisualXCmap(XColormap useXCmap,
						Visual *useVisual) {
  visual_ = useVisual;
  xcmap_ = useXCmap;
  checkVisual();
}

Bool X11PixelCanvasColorTable::installRGBColors(const Vector<Float> & r, 
					 const Vector<Float> & g,
					 const Vector<Float> & b,
					 uInt offset)
{
  if (offset + r.nelements() > nColors_)
    throw(AipsError("X11PixelCanvasColorTable::installRGBColors: offset + vector length > nColors in"));

  for (uInt i = 0; i < r.nelements(); i++)
    {
      storeVColor(i+offset, r(i), g(i), b(i));
    }
  return True;
}

Bool X11PixelCanvasColorTable::resize(uInt newSize) {
  uInt oldSize = nColors();

  // For now, if we're doing anything other than Display::Index return false
//  if (colorModel_ != Display::Index) return False;

  // If the new size is smaller, we will always succede.  If the new size
  // is bigger, we may not have the space we require
  if (newSize > oldSize) {

    uInt availColors = QueryColorsAvailable(True);
    if (availColors < newSize - oldSize) {
      LogIO os;
      os << LogIO::WARN << LogOrigin("X11PixelCanvasColorTable",
				     "resize", WHERE)
	 << "There were not enough colors to satisfy the resize request"
	 << LogIO::POST;
      return False;
    }
  }

  // Ok now we can try a reallocation using the current map.  It may
  // still fail if someone else alloc'd cells between the calls to
  // X11QueryColorsAvailable() and the allocCells() below.
  doResizeCallbacks(Display::ClearPriorToColorChange);
  deallocCells();

  // Realloc using Custom
  Bool ok = allocCells(newSize);
  if (ok)
    {
      colormapManager().redistributeColormaps();
      return True;
    }

  // Uh oh.  Someone alloc'ed cells during that short time.  Try to 
  // get our old size back and recover.
  ok = allocCells(oldSize);
  if (ok)
    {
      LogIO os;
      os << LogIO::WARN << LogOrigin("X11PixelCanvasColorTable", "resize",
				    WHERE)
	 << "Could not allocate enough colors to satisfy the resize,\n"
	 << "number of colors returned to " << oldSize
	 << LogIO::POST;
      colormapManager().redistributeColormaps();
      return False;
    }

  // If we get here, we were unable to restore the old size, so
  // throw an exception.
  throw(AipsError("Color cells have been lost - unsupported situation"));

  return False;  // to stop compiler warning
}

Bool X11PixelCanvasColorTable::resize(uInt n1, uInt n2, uInt n3)
{
  // correct for zero entries if present
  if (n1 == 0) n1 = 1;
  if (n2 == 0) n2 = 1;
  if (n3 == 0) n3 = 1;

  // Return True immediately if no change needed
  if (n1_ == n1 && n2_ == n2 & n3_ == n3) return True;

  // Test to see if there is a change in the number of colors needed.  Resize
  // if that is so.
  if (n1*n2*n3 != n1_*n2_*n3_)
    {
      // Fail if rigid
      if (rigid_) 
	{
	  // This X11PixelCanvasColorTable cannot be resized
	  return False;
	}

      uInt n1o = n1_;
      uInt n2o = n2_;
      uInt n3o = n3_;

      n1_ = n1;
      n2_ = n2;
      n3_ = n3;

      doResizeCallbacks(Display::ClearPriorToColorChange);
      // resize to suit
      deallocCells();

      // Try to allocate space for the new cube
      if (!allocColorCube(n1, n2, n3))
	{
	  // failed, fallback to original
	  n1_ = n1o;
	  n2_ = n2o;
	  n3_ = n3o;

	  if (!allocColorCube(n1o, n2o, n3o))
	    {
	      // failed to recover
	      throw(AipsError("X11PixelCanvasColorTable::buildMapRGBBest(xpcct):\n"
			      "could not allocate color cube on passed colormap"));
	    }
	}
    }
  else
    {
      // don't need to realloc cells
      n1_ = n1;
      n2_ = n2;
      n3_ = n3;
    }

  setupColorCube(n1_, n2_, n3_, 1, n1_, n1_*n2_);

  switch(colorModel_)
    {
    case Display::RGB: fillColorCubeRGB(); break;
    case Display::HSV: fillColorCubeHSV(); break;
    case Display::Index: 
      // won't get here
      break;
    }
  
  doResizeCallbacks();
  return True;
}

// 1
X11PixelCanvasColorTable::X11PixelCanvasColorTable(Screen * screen,
					       Display::ColorModel colorModel,
					       Display::Strategy strategy,
					       Display::SpecialMap mapRef)
  : display_(DisplayOfScreen(screen)),
    screen_(screen),
    visual_(0),
    xcmap_(0),
    depth_(0),
    nColors_(0),
    colors_(0),
    rigid_(False),
    pow2Mapping_(False),
    colorModel_(colorModel),
    n1_(0),
    n2_(0),
    n3_(0),
    n1Bits_(0),
    n2Bits_(0),
    n3Bits_(0)
{

  if (strategy != Display::Best && strategy != Display::Default)
    {
      // Selected strategy must have arguments, using default map instead
      strategy = Display::Default;
    }
  
  switch(colorModel_)
    {
    case Display::Index:
      setPCVisualXCmap(mapRef);
      
      // now have display_, screen_, visual_, xcmap_
      // call function to build map according to strategy
      if (strategy == Display::Best) 
	buildMapIndexBest();
      else
	buildMapIndexDefault();
      break;
    case Display::RGB:
      if (strategy == Display::Best) 
	buildMapRGBBest(mapRef);
      else
	buildMapRGBDefault(mapRef);
      break;
    case Display::HSV:
      setPCVisualXCmap(mapRef);
      if (strategy == Display::Best)
	buildMapHSVBest(mapRef);
      else
	buildMapHSVDefault(mapRef);
      break;
    }
  depth_ = X11DepthOfVisual(display_, visual_);
}

// 2
X11PixelCanvasColorTable::X11PixelCanvasColorTable(Screen * screen,
				     Display::ColorModel colorModel,
				     Display::Strategy strategy,
				     const X11PixelCanvasColorTable & ref)
  : display_(DisplayOfScreen(screen)),
    screen_(screen),
    visual_(0),
    xcmap_(0),
    depth_(0),
    nColors_(0),
    colors_(0),
    rigid_(False),
    pow2Mapping_(False),
    colorModel_(colorModel),
    n1_(0),
    n2_(0),
    n3_(0),
    n1Bits_(0),
    n2Bits_(0),
    n3Bits_(0)
{

  if (strategy != Display::Best && strategy != Display::Default)
    {
      // Strategy must have arguments, using default map instead
      strategy = Display::Default;
    }

  visual_ = ref.visual();
  xcmap_ = ref.xcmap();
  checkVisual();
  X11ResourceManager::refColormap(screen_, xcmap_);
 
  switch(colorModel_)
    {
    case Display::Index:
      // now have display_, screen_, visual_, xcmap_
      // call function to build map according to strategy
      if (strategy == Display::Best) 
	buildMapIndexBest();
      else
	buildMapIndexDefault();
      
      break;
    case Display::RGB:
      if (strategy == Display::Best)
	buildMapRGBBest(ref);
      else
	buildMapRGBDefault(ref);
      break;
	
    case Display::HSV:
      if (strategy == Display::Best)
	buildMapHSVBest(ref);
      else
	buildMapHSVDefault(ref);
      break;
    }
  depth_ = X11DepthOfVisual(display_, visual_);
}

// 3
X11PixelCanvasColorTable::X11PixelCanvasColorTable(Screen * screen,
					       Display::ColorModel colorModel,
					       Display::Strategy strategy,
					       Display::SpecialMap mapRef,
					       uInt parm)
  : display_(DisplayOfScreen(screen)),
    screen_(screen),
    visual_(0),
    xcmap_(0),
    depth_(0),
    nColors_(0),
    colors_(0),
    rigid_(False),
    pow2Mapping_(False),
    colorModel_(colorModel),
    n1_(0),
    n2_(0),
    n3_(0),
    n1Bits_(0),
    n2Bits_(0),
    n3Bits_(0)
{
  if ((colorModel == Display::Index && (strategy != Display::Custom && strategy != Display::Percent))
      || (colorModel != Display::Index && strategy != Display::Percent))
    throw(AipsError("ctor3: Invalid constructor parameter combination"));

  switch(colorModel_)
    {
    case Display::Index:
      setPCVisualXCmap(mapRef);
	
      if (strategy == Display::Custom)
	buildMapIndexCustom(parm);
      else
	buildMapIndexPercent((float) parm);
      break;
    case Display::RGB:
      buildMapRGBPercent(mapRef, (float) parm);
      break;
    case Display::HSV:
      setPCVisualXCmap(mapRef);
      buildMapHSVPercent(mapRef, (float) parm);
      break;
    }
  depth_ = X11DepthOfVisual(display_, visual_);
}

// 4
X11PixelCanvasColorTable::X11PixelCanvasColorTable(Screen * screen,
					       Display::ColorModel colorModel,
					       Display::Strategy strategy,
					       const X11PixelCanvasColorTable & ref,
					       uInt parm)
  : display_(DisplayOfScreen(screen)),
    screen_(screen),
    visual_(0),
    xcmap_(0),
    depth_(0),
    nColors_(0),
    colors_(0),
    rigid_(False),
    pow2Mapping_(False),
    colorModel_(colorModel),
    n1_(0),
    n2_(0),
    n3_(0),
    n1Bits_(0),
    n2Bits_(0),
    n3Bits_(0)
{
  if ((colorModel == Display::Index && (strategy != Display::Custom || strategy != Display::Percent))
      || (colorModel != Display::Index && strategy != Display::Percent))
    throw(AipsError("ctor 4: Invalid constructor parameter combination"));

  visual_ = ref.visual();
  xcmap_ = ref.xcmap();
  checkVisual();
  X11ResourceManager::refColormap(screen_, xcmap_);

  switch(colorModel_)
    {
    case Display::Index:
      if (strategy == Display::Custom)
	buildMapIndexCustom(parm);
      else
	buildMapIndexPercent((float) parm);
      break;
    case Display::RGB:
      buildMapRGBPercent(ref, (float) parm);
      break;
    case Display::HSV:
      buildMapHSVPercent(ref, (float) parm);
      break;
    }
  depth_ = X11DepthOfVisual(display_, visual_);
}

// 5
X11PixelCanvasColorTable::X11PixelCanvasColorTable(Screen * screen,
					       Display::ColorModel colorModel,
					       Display::Strategy strategy,
					       Display::SpecialMap mapRef,
					       Float percent)
  : display_(DisplayOfScreen(screen)),
    screen_(screen),
    visual_(0),
    xcmap_(0),
    depth_(0),
    nColors_(0),
    colors_(0),
    rigid_(False),
    pow2Mapping_(False),
    colorModel_(colorModel),
    n1_(0),
    n2_(0),
    n3_(0),
    n1Bits_(0),
    n2Bits_(0),
    n3Bits_(0)
{
  if (strategy != Display::Percent)
    throw(AipsError("ctor5:Invalid constructor parameter combination"));

  switch(colorModel_)
    {
    case Display::Index:
      setPCVisualXCmap(mapRef);
      buildMapIndexPercent(percent);
      break;
    case Display::RGB:
      buildMapRGBPercent(mapRef, percent);
      break;
    case Display::HSV:
      setPCVisualXCmap(mapRef);
      buildMapHSVPercent(mapRef, percent);
      break;
    }
  depth_ = X11DepthOfVisual(display_, visual_);
}

// 6
X11PixelCanvasColorTable::X11PixelCanvasColorTable(Screen * screen,
					       Display::ColorModel colorModel,
					       Display::Strategy strategy,
					       const X11PixelCanvasColorTable & ref,
					       Float percent)
  : display_(DisplayOfScreen(screen)),
    screen_(screen),
    visual_(0),
    xcmap_(0),
    depth_(0),
    nColors_(0),
    colors_(0),
    rigid_(False),
    pow2Mapping_(False),
    colorModel_(colorModel),
    n1_(0),
    n2_(0),
    n3_(0),
    n1Bits_(0),
    n2Bits_(0),
    n3Bits_(0)
{
  if (strategy != Display::Percent)
    throw(AipsError("ctor6: Invalid constructor parameter combination"));

  visual_ = ref.visual();
  xcmap_ = ref.xcmap();
  checkVisual();
  X11ResourceManager::refColormap(screen_, xcmap_);

  switch(colorModel_)
    {
    case Display::Index:
      buildMapIndexPercent(percent);
      break;
    case Display::RGB:
      buildMapRGBPercent(ref, percent);
      break;
    case Display::HSV:
      buildMapHSVPercent(ref, percent);
      break;
    }
  depth_ = X11DepthOfVisual(display_, visual_);
}

// 7
X11PixelCanvasColorTable::X11PixelCanvasColorTable(Screen * screen,
					       Display::ColorModel colorModel,
					       Display::Strategy strategy,
					       Display::SpecialMap mapRef,
					       uInt minCells,
					       uInt maxCells)
  : display_(DisplayOfScreen(screen)),
    screen_(screen),
    visual_(0),
    xcmap_(0),
    depth_(0),
    nColors_(0),
    colors_(0),
    rigid_(False),
    pow2Mapping_(False),
    colorModel_(colorModel),
    n1_(0),
    n2_(0),
    n3_(0),
    n1Bits_(0),
    n2Bits_(0),
    n3Bits_(0)
{
  if (strategy != Display::MinMax)
    throw(AipsError("ctor7: Invalid constructor parameter combination"));

  switch(colorModel_)
    {
    case Display::Index:
      setPCVisualXCmap(mapRef);
      buildMapIndexMinMax(minCells, maxCells);
      break;
    case Display::RGB:
    case Display::HSV:
      throw(AipsError("ctor7: Invalid constructor parameter combination"));
      break;
    }
  depth_ = X11DepthOfVisual(display_, visual_);
}

// 8
X11PixelCanvasColorTable::X11PixelCanvasColorTable(Screen * screen,
					       Display::ColorModel colorModel,
					       Display::Strategy strategy,
					       const X11PixelCanvasColorTable & ref,
					       uInt minCells,
					       uInt maxCells)
  : display_(DisplayOfScreen(screen)),
    screen_(screen),
    visual_(0),
    xcmap_(0),
    depth_(0),
    nColors_(0),
    colors_(0),
    rigid_(False),
    pow2Mapping_(False),
    colorModel_(colorModel),
    n1_(0),
    n2_(0),
    n3_(0),
    n1Bits_(0),
    n2Bits_(0),
    n3Bits_(0)
{
  if (strategy != Display::MinMax)
    throw(AipsError("ctor8: Invalid constructor parameter combination"));

  visual_ = ref.visual();
  xcmap_ = ref.xcmap();
  checkVisual();
  X11ResourceManager::refColormap(screen_, xcmap_);

  switch(colorModel_)
    {
    case Display::Index:
      buildMapIndexMinMax(minCells, maxCells);
      break;
    case Display::RGB:
      buildMapRGBMinMax(ref, minCells, minCells, minCells, maxCells, maxCells, maxCells);
      break;
    case Display::HSV:
      buildMapHSVMinMax(ref, minCells, minCells, minCells, maxCells, maxCells, maxCells);
      break;
    }
  depth_ = X11DepthOfVisual(display_, visual_);
}
  
// 9
X11PixelCanvasColorTable::X11PixelCanvasColorTable(Screen * screen,
					       Display::ColorModel colorModel,
					       Display::Strategy strategy,
					       Display::SpecialMap refMap,
					       uInt n1,
					       uInt n2,
					       uInt n3)
  : display_(DisplayOfScreen(screen)),
    screen_(screen),
    visual_(0),
    xcmap_(0),
    depth_(0),
    nColors_(0),
    colors_(0),
    rigid_(False),
    pow2Mapping_(False),
    colorModel_(colorModel),
    n1_(0),
    n2_(0),
    n3_(0),
    n1Bits_(0),
    n2Bits_(0),
    n3Bits_(0)
{
  if (strategy != Display::Custom)
    throw(AipsError("ctor9: Invalid constructor parameter combination"));

  switch(colorModel_)
    {
    case Display::Index:
      throw(AipsError("ctor9: Invalid constructor parameter combination"));
      break;
    case Display::RGB:
      buildMapRGBCustom(refMap, n1,n2,n3);
      break;
    case Display::HSV:
      setPCVisualXCmap(refMap);
      buildMapHSVCustom(n1,n2,n3);
      break;
    }
  depth_ = X11DepthOfVisual(display_, visual_);
}

// 10
X11PixelCanvasColorTable::X11PixelCanvasColorTable(Screen * screen,
					       Display::ColorModel colorModel,
					       Display::Strategy strategy,
					       const X11PixelCanvasColorTable & ref,
					       uInt n1,
					       uInt n2,
					       uInt n3)
  : display_(DisplayOfScreen(screen)),
    screen_(screen),
    visual_(0),
    xcmap_(0),
    depth_(0),
    nColors_(0),
    colors_(0),
    rigid_(False),
    pow2Mapping_(False),
    colorModel_(colorModel),
    n1_(0),
    n2_(0),
    n3_(0),
    n1Bits_(0),
    n2Bits_(0),
    n3Bits_(0)
{  
  if (strategy != Display::Custom)
    throw(AipsError("ctor10: Invalid constructor parameter combination"));

  visual_ = ref.visual();
  xcmap_ = ref.xcmap();
  checkVisual();
  X11ResourceManager::refColormap(screen_, xcmap_);

  switch(colorModel_)
    {
    case Display::Index:
      throw(AipsError("ctor10: Invalid constructor parameter combination"));
      break;
    case Display::RGB:
      buildMapRGBCustom(ref, n1,n2,n3);
      break;
    case Display::HSV:
      buildMapHSVCustom(ref, n1,n2,n3);
      break;
    }
  depth_ = X11DepthOfVisual(display_, visual_);
}

// 11
X11PixelCanvasColorTable::X11PixelCanvasColorTable(Screen * screen,
					       Display::ColorModel colorModel,
					       Display::Strategy strategy,
					       Display::SpecialMap refMap,
					       uInt l1, uInt l2, uInt l3,
					       uInt h1, uInt h2, uInt h3)
  : display_(DisplayOfScreen(screen)),
    screen_(screen),
    visual_(0),
    xcmap_(0),
    depth_(0),
    nColors_(0),
    colors_(0),
    rigid_(False),
    pow2Mapping_(False),
    colorModel_(colorModel),
    n1_(0),
    n2_(0),
    n3_(0),
    n1Bits_(0),
    n2Bits_(0),
    n3Bits_(0)
{
  if (strategy != Display::MinMax)
    throw(AipsError("ctor11: Invalid constructor parameter combination"));

  switch(colorModel_)
    {
    case Display::Index:
      throw(AipsError("ctor11: Invalid constructor parameter combination"));
      break;
    case Display::RGB:
      visual_ = 0;
      buildMapRGBMinMax(refMap, l1,l2,l3,h1,h2,h3);
      checkVisual();
      break;
    case Display::HSV:
      setPCVisualXCmap(refMap);
      buildMapHSVMinMax(l1,l2,l3,h1,h2,h3);
      break;
    }
  depth_ = X11DepthOfVisual(display_, visual_);
  checkVisual();
}
		
// 12
X11PixelCanvasColorTable::X11PixelCanvasColorTable(Screen * screen,
					       Display::ColorModel colorModel,
					       Display::Strategy strategy,
					       const X11PixelCanvasColorTable & ref,
					       uInt l1, uInt l2, uInt l3,
					       uInt h1, uInt h2, uInt h3)
  : display_(DisplayOfScreen(screen)),
    screen_(screen),
    visual_(0),
    xcmap_(0),
    depth_(0),
    nColors_(0),
    colors_(0),
    rigid_(False),
    pow2Mapping_(False),
    colorModel_(colorModel),
    n1_(0),
    n2_(0),
    n3_(0),
    n1Bits_(0),
    n2Bits_(0),
    n3Bits_(0)
{
  if (strategy != Display::MinMax)
    throw(AipsError("ctor12: Invalid constructor parameter combination"));

  visual_ = ref.visual();
  xcmap_ = ref.xcmap();
  checkVisual();

  X11ResourceManager::refColormap(screen_, xcmap_);

  switch(colorModel_)
    {
    case Display::Index:
      throw(AipsError("ctor12: Invalid constructor parameter combination"));
      break;
    case Display::RGB:
      buildMapRGBMinMax(ref,l1,l2,l3,h1,h2,h3);
      break;
    case Display::HSV:
      buildMapHSVMinMax(ref,l1,l2,l3,h1,h2,h3);
      break;
    }

  depth_ = X11DepthOfVisual(display_, visual_);
}

// 13
X11PixelCanvasColorTable::X11PixelCanvasColorTable(Screen * screen,
					       Display::ColorModel colorModel,
					       Display::Strategy strategy,
					       XColormap useXCmap,
					       Visual *useVisual,
					       uInt parm)
  : display_(DisplayOfScreen(screen)),
    screen_(screen),
    visual_(0),
    xcmap_(0),
    depth_(0),
    nColors_(0),
    colors_(0),
    rigid_(False),
    pow2Mapping_(False),
    colorModel_(colorModel),
    n1_(0),
    n2_(0),
    n3_(0),
    n1Bits_(0),
    n2Bits_(0),
    n3Bits_(0)
{
  if ((colorModel == Display::Index && (strategy != Display::Custom && strategy != Display::Percent))
      || (colorModel != Display::Index && strategy != Display::Percent))
    throw(AipsError("ctor13: Invalid constructor parameter combination"));

  setPCVisualXCmap(useXCmap, useVisual);
  switch(colorModel_)
    {
    case Display::Index:
      if (strategy == Display::Custom)
	buildMapIndexCustom(parm);
      else
	buildMapIndexPercent((float) parm);
      break;
    case Display::RGB:
      buildMapRGBPercent(Display::Shared, (float) parm);
      break;
    case Display::HSV:
      buildMapHSVPercent(Display::Shared, (float) parm);
      break;
    }
  depth_ = X11DepthOfVisual(display_, visual_);
  checkVisual();
}

// 14
X11PixelCanvasColorTable::X11PixelCanvasColorTable(Screen * screen, 
					       Display::ColorModel colorModel, 
					       Display::Strategy strategy,
					       XColormap useXCmap,
					       Visual *useVisual,
					       uInt minCells, 
					       uInt maxCells)
  : display_(DisplayOfScreen(screen)),
    screen_(screen),
    visual_(0),
    xcmap_(0),
    depth_(0),
    nColors_(0),
    colors_(0),
    rigid_(False),
    pow2Mapping_(False),
    colorModel_(colorModel),
    n1_(0),
    n2_(0),
    n3_(0),
    n1Bits_(0),
    n2Bits_(0),
    n3Bits_(0)
{
  if (strategy != Display::MinMax)
    throw(AipsError("ctor14: Invalid constructor parameter combination"));

  setPCVisualXCmap(useXCmap, useVisual);
  switch(colorModel_)
    {
    case Display::Index:
      buildMapIndexMinMax(minCells, maxCells);
      break;
    case Display::RGB:
    case Display::HSV:
      throw(AipsError("ctor14: Invalid constructor parameter combination"));
      break;
    }
  depth_ = X11DepthOfVisual(display_, visual_);
  checkVisual();
}

// 15
X11PixelCanvasColorTable::X11PixelCanvasColorTable(Screen * screen,
					       Display::ColorModel colorModel,
					       Display::Strategy strategy,
					       XColormap useXCmap,
					       Visual *useVisual,
					       uInt l1, uInt l2, uInt l3,
					       uInt h1, uInt h2, uInt h3)
  : display_(DisplayOfScreen(screen)),
    screen_(screen),
    visual_(0),
    xcmap_(0),
    depth_(0),
    nColors_(0),
    colors_(0),
    rigid_(False),
    pow2Mapping_(False),
    colorModel_(colorModel),
    n1_(0),
    n2_(0),
    n3_(0),
    n1Bits_(0),
    n2Bits_(0),
    n3Bits_(0)
{
  if (strategy != Display::MinMax)
    throw(AipsError("ctor15: Invalid constructor parameter combination"));

  setPCVisualXCmap(useXCmap, useVisual);
  switch(colorModel_)
    {
    case Display::Index:
      throw(AipsError("ctor15: Invalid constructor parameter combination"));
      break;
    case Display::RGB:
      //visual_ = 0;
      buildMapRGBMinMax(Display::Shared, l1,l2,l3,h1,h2,h3);
      break;
    case Display::HSV:
      buildMapHSVMinMax(l1,l2,l3,h1,h2,h3);
      break;
    }
  depth_ = X11DepthOfVisual(display_, visual_);
  checkVisual();
}

X11PixelCanvasColorTable::~X11PixelCanvasColorTable()
{
  deallocCells();
  X11ResourceManager::unrefColormap(screen_, xcmap_);
}

//---------------------------------------------------------------------------------------
//
//  Index Colormaps
//
//---------------------------------------------------------------------------------------

// Deallocate color cells. Really do it if we're using a HW map. Fake it
// for RO maps.
Bool X11PixelCanvasColorTable::deallocCells()
{
  if( !readOnly() && (nColors_ > 0))
    {
      XFreeColors(display_, xcmap_, colors_, nColors_, (uLong) 0);
    }
  nColors_ = 0;
  return True;
}

// Allocate RW color cells from colormap. For read only maps, we're faking
// so request always succeeds as long as the request is within range.
// On entry, it is assumed no RW colors are currently allocated.
// If the request fails, nColors_ will be set to 0.
// colors_ is assumed to have been allocated during initialization.
Bool X11PixelCanvasColorTable::allocCells(uInt nCells)
{
  Bool ok;

  if(nCells == 0) 	// Assume max colormap length if 0. (Probably only done
	nCells = vcmapLength_; // using RO color maps so we have to succeed).

  if(readOnly_)
  {	if(nCells <= vcmapLength_)
	{
		ok = True;
	}
	else
		ok = False;
  }
  else
  { uLong *colors = new uLong[nCells];
    uLong planeMask[1];

	ok = (XAllocColorCells(display_, xcmap_, 1, planeMask, 0,
				     colors, nCells) > 0);
	if(ok)
	{	// Initialize mapping array (colors_)
		for(uLong i = 0; i< nCells; i++)
		{ uLong indx = colors[i];
			colors_[i] = indx;
			vcmap_[indx].setIndex(i);
		}
	}

	delete [] colors;
  }


  if(ok)
      nColors_ = nCells;
  else
	nColors_ = 0;

  return ok;
}

//---------------------------------------------------------------------------------------

void X11PixelCanvasColorTable::buildMapIndexBest()
{
  Bool ok = False;
  while (!ok)
    {

     if( readOnly_ )
	ok = allocCells(0);	// Allocate everything.
     else
     { uInt nCells = QueryColorsAvailable(True);
      ok = allocCells(nCells);
     }  
    }
}				 

void X11PixelCanvasColorTable::buildMapIndexDefault()
{
  buildMapIndexMinMax(10, 60);
}

void X11PixelCanvasColorTable::buildMapIndexMinMax(uInt minCells, uInt maxCells)
{
  Bool ok = False;

  while(!ok)
    {
      uInt nCells = QueryColorsAvailable(True);
      if (nCells < minCells)
	throw(AipsError("not enough colors remaining in hardware colormap"));     
      if (nCells > maxCells) nCells = maxCells;
      ok = allocCells(nCells);
    }
}

void X11PixelCanvasColorTable::buildMapIndexCustom(uInt reqCells)
{
  Bool ok = False;

  while (!ok)
    {
      uInt nCells = QueryColorsAvailable(True);
      if (nCells < reqCells)
	throw(AipsError("Unable to allocate requested number of cells"));
      ok = allocCells(reqCells);
    }
}
	
void X11PixelCanvasColorTable::buildMapIndexPercent(Float percent)
{
  Bool ok = False;
  while (!ok)
    {
      uInt totalCells = QueryColorsAvailable(True);
      uInt nCells = (uInt)(totalCells * percent / 100.0);
      if (nCells < 4)
	throw(AipsError("Too few colors remaining to provide display"));
      ok = allocCells(nCells);
    }
}

//----------------------------------------------------------------------------------
//
//  Multi-Channel support functions
//
//----------------------------------------------------------------------------------
Bool X11PixelCanvasColorTable::isPow2(uInt n, uInt & log2n)
{
  if (n == 0) 
    { log2n = 0; return True; }
  for (uInt r = 0; r < 31; r++)
    if (n - (1 << r) == 0) 
      { log2n = r; return True; }
  return False;
}

Bool X11PixelCanvasColorTable::allocColorCube()
{
  // Try to make a colour cube with remaining colors in xcmap_
  Bool ok = False;
  uInt nr,ng,nb;
  while (!ok)
    {
      uInt nCells = QueryColorsAvailable(True);
      if (!getRGBDistribution(nCells, False, nr, ng, nb))
	throw(AipsError("X11PixelCanvasColorTable::allocColorCube(xpcct) -\n"
			"Can't allocate color cube in shared colortable."));
      uInt nAlloc = nr*ng*nb;
      ok = allocCells(nAlloc);
    }

  setupColorCube(nr, ng, nb, 1, nr, nr*ng);
  return ok;
}

Bool X11PixelCanvasColorTable::allocColorCube(uInt n1, uInt n2, uInt n3)
{
  uInt nCells = QueryColorsAvailable(True);
  uInt nAlloc = n1*n2*n3;
  if (nCells < (n1*n2*n3))
    return False;

  if (!allocCells(nAlloc))
    return False;

  setupColorCube(n1,n2,n3,1,n1,n1*n2);
  
  return True;  
}

Bool X11PixelCanvasColorTable::allocColorCubeMinMax(uInt n1min, uInt n2min, uInt n3min,
						    uInt n1max, uInt n2max, uInt n3max)
{
  Bool ok = False;

  uInt n1 = n1max;
  uInt n2 = n2max;
  uInt n3 = n3max;
  
  Bool c1,c2,c3;
  
  ok = allocColorCube(n1,n2,n3);
  while (!ok)
    {
      if (n1 == n1min && n2 == n2min && n3 == n3min)
	return False;
      
      // pick component to decrement
      c1 = (n1 > n1min);
      c2 = (n2 > n2min);
      c3 = (n3 > n3min);
      
      if (c3 && c2) 
	if (n3 >= n2) c2 = False; else c3 = False;
      if (c3 && c1)
	if (n3 >= n1) c1 = False; else c3 = False;
      if (c2 && c1)
	if (n2 >= n1) c1 = False; else c2 = False;
      
      if (c1) n1--;
      if (c2) n2--;
      if (c3) n3--;
      
      ok = allocColorCube(n1,n2,n3);
    }
  return ok;
}

void X11PixelCanvasColorTable::copyColorCube(const X11PixelCanvasColorTable & mapRef)
{
  pow2Mapping_ = mapRef.pow2Mapping_;
  baseColor_ = mapRef.baseColor_;
  n1_ = mapRef.n1_;
  n2_ = mapRef.n2_;
  n3_ = mapRef.n3_;
  n1Mult_ = mapRef.n1Mult_;
  n2Mult_ = mapRef.n2Mult_;
  n3Mult_ = mapRef.n3Mult_;
  n1Bits_ = mapRef.n1Bits_;
  n2Bits_ = mapRef.n2Bits_;
  n3Bits_ = mapRef.n3Bits_;
  n1Shift_ = mapRef.n1Shift_;
  n2Shift_ = mapRef.n2Shift_;
  n3Shift_ = mapRef.n3Shift_;
  X11ResourceManager::refColormap(screen_, xcmap_);
}

// assumes color cube has been setup
void X11PixelCanvasColorTable::fillColorCubeRGB()
{
  for (uInt b = 0; b < n3_; b++)
    for (uInt g = 0; g < n2_; g++)
      for (uInt r = 0; r < n1_; r++)
	{
	  uInt colorCubeIndex;
	  if (pow2Mapping_)
	    colorCubeIndex = (r << n1Shift_) | (g << n2Shift_) | (b << n3Shift_);
	  else
	    colorCubeIndex = n1Mult_*r + n2Mult_*g + n3Mult_*b;

	  float red, green, blue;

	  red = (n1_>1) ? ((float)r / (n1_-1)) : 0.0;
	  green = (n2_>1) ? ((float)g / (n2_-1)) : 0.0;
	  blue = (n3_>1) ? ((float)b / (n3_-1)) : 0.0;
	  storeVColor(colorCubeIndex, red, green, blue);
	}
}

void X11PixelCanvasColorTable::storeVColor(const uInt vindex,
		const float r, const float g, const float b)
{
	if(vindex >= nColors_){
	    throw(AipsError("X11PixelCanvasColorTable::storeVColor: bad index"));
	} else { 
                uLong pindex = colors_[vindex];
		vcmap_[pindex].put(r, g, b);
		storeColor(pindex, r, g, b);
	}
}

static inline unsigned long floatToComponent(const float v,
				const unsigned short max, const short shift,
				const unsigned long mask)
{ unsigned long p = (((unsigned long) (v*max))<< shift) & mask;
	return p;
}

// Write an RGB color value to HW colormap if it's RW. For decomposed index
// colormaps, the pixel representation of (r/g/b) is generated.
void X11PixelCanvasColorTable::storeColor(const uLong pindex,
		const float r, const float g, const float b)
{
	// pindex is the index into the virtual colormap. For PseudoColor
	// colormaps, this is also the pixel value. For decomposedIndexes
	// ( TrueColor & DirectColor), it is necessary to generate the
	// pixel value.
	uLong pixel = pindex;
	if(decomposedIndex())
	{ unsigned long ri, gi, bi;
		ri = floatToComponent(r,
			red_max_, red_shift_, red_mask_);
		gi = floatToComponent(g,
			green_max_, green_shift_, green_mask_);
		bi = floatToComponent(b,
			blue_max_, blue_shift_, blue_mask_);
		pixel = ri | bi | gi;
		vcmap_[pindex].setPixel(pixel);
	}

	if(!readOnly_)
	{ XColor xc;
	  const float	scl =  65535.;
		xc.pixel = pixel;
		xc.red = (uShort)(r*scl);
		xc.green = (uShort)(g*scl);
		xc.blue = (uShort)(b*scl);
		xc.flags = DoRed | DoGreen | DoBlue;
		XStoreColor(display_, xcmap_, &xc);
	}
}

void X11PixelCanvasColorTable::fillColorCubeHSV()
{
  for (uInt v = 0; v < n3_; v++)
    for (uInt s = 0; s < n2_; s++)
      for (uInt h = 0; h < n1_; h++)
	{
	  uInt colorCubeIndex;
	  if (pow2Mapping_)
	    colorCubeIndex = (h << n1Shift_) | (s << n2Shift_) | (v << n3Shift_);
	  else
	    colorCubeIndex = n1Mult_*h + n2Mult_*s + n3Mult_*v;

	  Float hf = (n1_>1) ? ((Float) h) / (n1_-1) : 0.0;
	  Float sf = (n2_>1) ? ((Float) s) / (n2_-1) : 1.0;
	  Float vf = (n3_>1) ? ((Float) v) / (n3_-1) : 1.0;

	  Float r,g,b;
	  hsvToRgb(hf,sf,vf,r,g,b);

	  storeVColor(colorCubeIndex, r, g, b);
	}
}

void X11PixelCanvasColorTable::setupColorCube(uLong n1,
					      uLong n2,
					      uLong n3,
					      uLong n1mult,
					      uLong n2mult,
					      uLong n3mult)
{
  uInt log2n1, log2n2, log2n3;
  uInt log2n1mult, log2n2mult, log2n3mult;
  
  pow2Mapping_ = (isPow2(n1, log2n1)
			&& isPow2(n2, log2n2) 
			&& isPow2(n3, log2n3) 
			&& isPow2(n1mult, log2n1mult)
			&& isPow2(n2mult, log2n2mult)
			&& isPow2(n3mult, log2n3mult));

  n1_ = n1;
  n2_ = n2;
  n3_ = n3;
  n1Mult_ = n1mult;
  n2Mult_ = n2mult;
  n3Mult_ = n3mult;

  if (pow2Mapping_)
    {
      n1Bits_ = log2n1;
      n2Bits_ = log2n2;
      n3Bits_ = log2n3;
      n1Shift_ = log2n1mult;
      n2Shift_ = log2n2mult;
      n3Shift_ = log2n3mult;
    }

  // If HW color cells have already been allocated some may never get
  // deallocated.
  uInt newnColors = n1_*n2_*n3_;
  if(!readOnly() && (newnColors < nColors_))
  {    LogIO os;
      os << LogIO::WARN << LogOrigin("X11PixelCanvasColorTable:",
				     "setupColorCube", WHERE)
	 << "Losing " << nColors_ - n1_*n2_*n3_ << " colors from HW map"
	 << LogIO::POST;
  }

  nColors_ = n1_*n2_*n3_;
}

//????????????????
// To do.
uInt X11PixelCanvasColorTable::tripletIndex(float x, float y, float z)
{
  if (colorModel_ == Display::Index)
    throw(AipsError("Should not get to tripletIndex unless in rgb or hsv mode"));

  uInt xi = (uInt) (x * n1_);  if (xi >= n1_) xi = n1_-1;
  uInt yi = (uInt) (y * n2_);  if (yi >= n2_) yi = n2_-1;
  uInt zi = (uInt) (z * n3_);  if (zi >= n3_) zi = n3_-1;

  uInt colorCubeIndex;

  if (pow2Mapping_)
    colorCubeIndex = (xi << n1Shift_) | (yi << n2Shift_) | (zi << n3Shift_);
  else
    colorCubeIndex = n1Mult_*xi + n2Mult_*yi + n3Mult_*zi;

  // tripletMapping could be implemented with a PC or SC visual
  if (visual_->c_class == PseudoColor || visual_->c_class == StaticColor)
    return colors_[colorCubeIndex];
  else
    return baseColor_ + colorCubeIndex;
}

// Converts data between 
// Inputs:  Three Float arrays representing each of the three channels
//          representing color triples in the range of <0,0,0> to <1,1,1>
//          Color model of inputs
// Outputs: float arrays representing values from <0,0,0> to <1,1,1> in
//          the outputColorModel_ associated with the X11PCColorTable
Bool X11PixelCanvasColorTable::colorSpaceMap(Display::ColorModel inputColorModel,
					     const Array<Float> & chan1in,
					     const Array<Float> & chan2in,
					     const Array<Float> & chan3in,
					     Array<Float> & chan1out,
					     Array<Float> & chan2out,
					     Array<Float> & chan3out)
{
  Bool ok = False;

  // [ ] CONFORM TEST

  switch(inputColorModel)
    {
    case Display::RGB:
      switch(colorModel_)
	{
	case Display::RGB: 
	  chan1out = chan1in;
	  chan2out = chan2in;
	  chan3out = chan3in;
	  ok = True;
	  break;
	case Display::HSV:
	  rgbToHsv(chan1in, chan2in, chan3in, 
		   chan1out, chan2out, chan3out);
	  ok = True;
	  break;
	case Display::Index:
	  // won't get here
	  break;
	}
      break;
    case Display::HSV:
      switch(colorModel_)
	{ 
	case Display::RGB:
	  hsvToRgb(chan1in, chan2in, chan3in, 
		   chan1out, chan2out, chan3out);
	  ok = True;
	  break;
	case Display::HSV:
	  chan1out = chan1in;
	  chan2out = chan2in;
	  chan3out = chan3in;
	  ok = True;
	  break;
	case Display::Index:
	  // won't get here
	  break;
	}
      break;
    case Display::Index:
      // won't get here
      break;
    }
  return ok;
}


// map [0-1] float data to <[0-(n1_-1)], [0-(n2_-1)], [0-(n3_-1)]>
void X11PixelCanvasColorTable::mapToColor3(Array<uLong> & outImage,
					   const Array<Float> & chan1in,
					   const Array<Float> & chan2in,
					   const Array<Float> & chan3in)
{
  if (colorModel_ == Display::Index)
    throw(AipsError("Should not get to X11PixelCanvasColorTable::mapToColor3 in Index mode"));

  Bool ch1Del;
  const Float * ch1p = chan1in.getStorage(ch1Del);
  Bool ch2Del;
  const Float * ch2p = chan2in.getStorage(ch2Del);
  Bool ch3Del;
  const Float * ch3p = chan3in.getStorage(ch3Del);

  Bool outDel;
  uLong * outp = outImage.getStorage(outDel);

  uLong * endp = outp + outImage.nelements();
  
  const Float * ch1q = ch1p;
  const Float * ch2q = ch2p;
  const Float * ch3q = ch3p;

  uLong * outq = outp;

  uLong t1, t2, t3;

  if (pow2Mapping_)
    {
      if (visual_->c_class == PseudoColor || visual_->c_class == StaticColor)
	{
	  while (outq < endp)
	    {
	      // Use shifts/adds to get color index, use table lookup to get 
	      // pixel value.
	      t1 = (uLong)((*ch1q++)*n1_); if (t1 >= n1_) t1 = n1_-1;
	      t2 = (uLong)((*ch2q++)*n2_); if (t2 >= n2_) t2 = n2_-1;
	      t3 = (uLong)((*ch3q++)*n3_); if (t3 >= n3_) t3 = n3_-1;
	      *outq++ = colors_[(t1 << n1Shift_) | (t2 << n2Shift_) | (t3 << n3Shift_)];
	    }
	}
      else
	{
	  if(colorModel_ == Display::RGB)
	    while (outq < endp)
	    {
	      uLong red = (uLong)(*ch1q++ * red_max_);
		if(red > red_max_) red = red_max_;
		red = (red << red_shift_)&red_mask_;
	      uLong green = (uLong)(*ch2q++ * green_max_);
		if(green > green_max_) green = green_max_;
		green = (green << green_shift_)&green_mask_;
	      uLong blue = (uLong)(*ch3q++ * blue_max_);
		if(blue > blue_max_) blue = blue_max_;
		blue = (blue << blue_shift_)&blue_mask_;
	      uLong pixel = red | green | blue;
		*outq++ = pixel;
	    }
	  else	// HSV
		while (outq < endp)
	 	{ Float r, g, b;
			// Convert HSV -> RGB.
			hsvToRgb(*ch1q++, *ch2q++, *ch3q++, r, g, b);
			uLong Red = (uLong)(r*red_max_);
			uLong red = (Red << red_shift_)&red_mask_;
			uLong Green = (uLong)(g*green_max_);
			uLong green =
				(Green << green_shift_)&green_mask_;
			uLong Blue = (uLong)(b*blue_max_);
			uLong blue = (Blue << blue_shift_)&blue_mask_;
			uLong pixel = red | green | blue;
			*outq++ =  pixel;
		}
	}
    }
  else
    {
      if (visual_->c_class == PseudoColor || visual_->c_class == StaticColor)
	{
	  while (outq < endp)
	    {
	      // Cube not aligned to bitplane boundaries, so have to
	      // multiply/and add to get color index, use table lookup to get 
	      // pixel value.
	      t1 = (uLong)((*ch1q++)*n1_); if (t1 >= n1_) t1 = n1_-1;
	      t2 = (uLong)((*ch2q++)*n2_); if (t2 >= n2_) t2 = n2_-1;
	      t3 = (uLong)((*ch3q++)*n3_); if (t3 >= n3_) t3 = n3_-1;
	      *outq++ = colors_[t1*n1Mult_ + t2*n2Mult_ + t3*n3Mult_];
	    }
	}
      else
	{
	  if(colorModel_ == Display::RGB)
	    while (outq < endp)
	    {
	      uLong red = (uLong)(*ch1q++ * red_max_);
		if(red > red_max_) red = red_max_;
		red = (red << red_shift_)&red_mask_;
	      uLong green = (uLong)(*ch2q++ * green_max_);
		if(green > green_max_) green = green_max_;
		green = (green << green_shift_)&green_mask_;
	      uLong blue = (uLong)(*ch3q++ * blue_max_);
		if(blue > blue_max_) blue = blue_max_;
		blue = (blue << blue_shift_)&blue_mask_;
	      uLong pixel = red | green | blue;
		*outq++ = pixel;
	    }
	  else	// HSV
		while (outq < endp)
	 	{ Float r, g, b;
			// Convert HSV -> RGB.
			hsvToRgb(*ch1q++, *ch2q++, *ch3q++, r, g, b);
			uLong Red = (uLong)(r*red_max_);
			uLong red = (Red << red_shift_)&red_mask_;
			uLong Green = (uLong)(g*green_max_);
			uLong green =
				(Green << green_shift_)&green_mask_;
			uLong Blue = (uLong)(b*blue_max_);
			uLong blue = (Blue << blue_shift_)&blue_mask_;
			uLong pixel = red | green | blue;
			*outq++ =  pixel;
		}
	}
    }


  chan1in.freeStorage(ch1p, ch1Del);
  chan2in.freeStorage(ch2p, ch2Del);
  chan3in.freeStorage(ch3p, ch3Del);

  outImage.putStorage(outp, outDel);
}

// map [0-1] float data to <[0-(n1_-1)], [0-(n2_-1)], [0-(n3_-1)]>
void X11PixelCanvasColorTable::mapToColor3(Array<uLong> & outImage,
					   const Array<Double> & chan1in,
					   const Array<Double> & chan2in,
					   const Array<Double> & chan3in)
{
  if (colorModel_ == Display::Index)
    throw(AipsError("Should not get to X11PixelCanvasColorTable::mapToColor3 in Index mode"));

  Bool ch1Del;
  const Double * ch1p = chan1in.getStorage(ch1Del);
  Bool ch2Del;
  const Double * ch2p = chan2in.getStorage(ch2Del);
  Bool ch3Del;
  const Double * ch3p = chan3in.getStorage(ch3Del);

  Bool outDel;
  uLong * outp = outImage.getStorage(outDel);

  uLong * endp = outp + outImage.nelements();
  
  const Double * ch1q = ch1p;
  const Double * ch2q = ch2p;
  const Double * ch3q = ch3p;

  uLong * outq = outp;

  uLong t1, t2, t3;

  if (pow2Mapping_)
    {
      if (visual_->c_class == PseudoColor || visual_->c_class == StaticColor)
	{
	  while (outq < endp)
	    {
	      // Use shifts/adds to get color index, use table lookup to get 
	      // pixel value.
	      t1 = (uLong)((*ch1q++)*n1_); if (t1 >= n1_) t1 = n1_-1;
	      t2 = (uLong)((*ch2q++)*n2_); if (t2 >= n2_) t2 = n2_-1;
	      t3 = (uLong)((*ch3q++)*n3_); if (t3 >= n3_) t3 = n3_-1;
	      *outq++ = colors_[(t1 << n1Shift_) | (t2 << n2Shift_) | (t3 << n3Shift_)];
	    }
	}
      else
	{
	  if(colorModel_ == Display::RGB)
	    while (outq < endp)
	    {
	      uLong red = (uLong)(*ch1q++ * red_max_);
		if(red > red_max_) red = red_max_;
		red = (red << red_shift_)&red_mask_;
	      uLong green = (uLong)(*ch2q++ * green_max_);
		if(green > green_max_) green = green_max_;
		green = (green << green_shift_)&green_mask_;
	      uLong blue = (uLong)(*ch3q++ * blue_max_);
		if(blue > blue_max_) blue = blue_max_;
		blue = (blue << blue_shift_)&blue_mask_;
	      uLong pixel = red | green | blue;
		*outq++ = pixel;
	    }
	   else	// HSV
		while (outq < endp)
	 	{ Float r, g, b;
			// Convert HSV -> RGB.
			hsvToRgb(*ch1q++, *ch2q++, *ch3q++, r, g, b);
			uLong Red = (uLong)(r*red_max_);
			uLong red = (Red << red_shift_)&red_mask_;
			uLong Green = (uLong)(g*green_max_);
			uLong green = (Green << green_shift_)&green_mask_;
			uLong Blue = (uLong)(b*blue_max_);
			uLong blue = (Blue << blue_shift_)&blue_mask_;
			uLong pixel = red | green | blue;
			*outq++ =  pixel;
		}
	}
    }
  else
    {
      if (visual_->c_class == PseudoColor || visual_->c_class == StaticColor)
	{
	  while (outq < endp)
	    {
	      // Cube not aligned to bitplane boundaries, so have to
	      // multiply/and add to get color index, use table lookup to get 
	      // pixel value.
	      t1 = (uLong)((*ch1q++)*n1_); if (t1 >= n1_) t1 = n1_-1;
	      t2 = (uLong)((*ch2q++)*n2_); if (t2 >= n2_) t2 = n2_-1;
	      t3 = (uLong)((*ch3q++)*n3_); if (t3 >= n3_) t3 = n3_-1;
	      *outq++ = colors_[t1*n1Mult_ + t2*n2Mult_ + t3*n3Mult_];
	    }
	}
      else
	{
	  if(colorModel_ == Display::RGB)
	    while (outq < endp)
	    {
	      uLong red = (uLong)(*ch1q++ * red_max_);
		if(red > red_max_) red = red_max_;
		red = (red << red_shift_)&red_mask_;
	      uLong green = (uLong)(*ch2q++ * green_max_);
		if(green > green_max_) green = green_max_;
		green = (green << green_shift_)&green_mask_;
	      uLong blue = (uLong)(*ch3q++ * blue_max_);
		if(blue > blue_max_) blue = blue_max_;
		blue = (blue << blue_shift_)&blue_mask_;
	      uLong pixel = red | green | blue;
		*outq++ = pixel;
	    }
	  else	// HSV
		while (outq < endp)
	 	{ Float r, g, b;
			// Convert HSV -> RGB.
			hsvToRgb(*ch1q++, *ch2q++, *ch3q++, r, g, b);
			uLong Red = (uLong)(r*red_max_);
			uLong red = (Red << red_shift_)&red_mask_;
			uLong Green = (uLong)(g*green_max_);
			uLong green = (Green << green_shift_)&green_mask_;
			uLong Blue = (uLong)(b*blue_max_);
			uLong blue = (Blue << blue_shift_)&blue_mask_;
			uLong pixel = red | green | blue;
			*outq++ =  pixel;
		}
	}
    }

  chan1in.freeStorage(ch1p, ch1Del);
  chan2in.freeStorage(ch2p, ch2Del);
  chan3in.freeStorage(ch3p, ch3Del);

  outImage.putStorage(outp, outDel);
}

// merge separate channels into an output image.  It is assumed the
// values in the channel images are within the ranges per channel
void X11PixelCanvasColorTable::mapToColor3(Array<uLong> & outImage,
					   const Array<uShort> & chan1in,
					   const Array<uShort> & chan2in,
					   const Array<uShort> & chan3in)
{
  if (colorModel_ == Display::Index)
    throw(AipsError("Should not get to X11PixelCanvasColorTable::mapToColor3 in Index mode"));

  Bool ch1Del;
  const uShort * ch1p = chan1in.getStorage(ch1Del);
  Bool ch2Del;
  const uShort * ch2p = chan2in.getStorage(ch2Del);
  Bool ch3Del;
  const uShort * ch3p = chan3in.getStorage(ch3Del);

  Bool outDel;
  uLong * outp = outImage.getStorage(outDel);

  uLong * endp = outp + outImage.nelements();
  
  const uShort * ch1q = ch1p;
  const uShort * ch2q = ch2p;
  const uShort * ch3q = ch3p;

  uLong * outq = outp;

  if (pow2Mapping_)
    {
      if (visual_->c_class == PseudoColor || visual_->c_class == StaticColor)
	{
	  while (outq < endp)
	    {
	      *outq++ = colors_[((*ch1q++) << n1Shift_) | ((*ch2q++) << n2Shift_) | ((*ch3q++) << n3Shift_)];
	    }
	}
      else
	{
	  if(colorModel_ == Display::RGB)
	    while (outq < endp)
	    {
	      uLong red = (*ch1q++ << red_shift_)&red_mask_;
	      uLong green = (*ch2q++ << green_shift_)&green_mask_;
	      uLong blue = (*ch3q++ << blue_shift_)&blue_mask_;
	      uLong pixel = red | green | blue;
	      *outq++ =  pixel;
	    }
	  else	// HSV
		while (outq < endp)
	 	{ uLong r, g, b;
			// Convert HSV -> RGB.
			HSV2RGB((uLong)*ch1q++, (uLong)*ch2q++, (uLong)*ch3q++,
				r, g, b);
			uLong red = (r << red_shift_)&red_mask_;
			uLong green = (g << green_shift_)&green_mask_;
			uLong blue = (b << blue_shift_)&blue_mask_;
			uLong pixel = red | green | blue;
			*outq++ =  pixel;
		}
	}
    }
  else
    {
      if (visual_->c_class == PseudoColor || visual_->c_class == StaticColor)
	{
	  while (outq < endp)
	    {
	      *outq++ = colors_[(*ch1q++)*n1Mult_ + (*ch2q++)*n2Mult_ + (*ch3q++)*n3Mult_];
	    }
	}
      else
	{
	  if(colorModel_ == Display::RGB)
	    while (outq < endp)
	    {
	      uLong red = (*ch1q++ << red_shift_)&red_mask_;
	      uLong green = (*ch2q++ << green_shift_)&green_mask_;
	      uLong blue = (*ch3q++ << blue_shift_)&blue_mask_;
	      uLong pixel = red | green | blue;
	      *outq++ =  pixel;
	    }
	  else	// HSV
		while (outq < endp)
	 	{ uLong r, g, b;
			// Convert HSV -> RGB.
			HSV2RGB((uLong)*ch1q++, (uLong)*ch2q++, (uLong)*ch3q++,
				r, g, b);
			uLong red = (r << red_shift_)&red_mask_;
			uLong green = (g << green_shift_)&green_mask_;
			uLong blue = (b << blue_shift_)&blue_mask_;
			uLong pixel = red | green | blue;
			*outq++ =  pixel;
		}
	}
    }

  chan1in.freeStorage(ch1p, ch1Del);
  chan2in.freeStorage(ch2p, ch2Del);
  chan3in.freeStorage(ch3p, ch3Del);

  outImage.putStorage(outp, outDel);
}

void
X11PixelCanvasColorTable::HSV2RGB(const uLong H, const uLong S, const uLong V,
				  uLong &R, uLong &G, uLong &B)
{ float h, s, v, r, g, b;
	// Convert to floats in range of [0..1].
	h = ((float)H)/red_max_;
	s = ((float)S)/green_max_;
	v = ((float)V)/blue_max_;
	hsvToRgb(h, s, v, r, g, b);
	R = (uLong)(r*red_max_);
	G = (uLong)(g*green_max_);
	B = (uLong)(b*blue_max_);
}

// merge separate channels into an output image.  It is assumed the
// values in the channel images are within the ranges per channel
void X11PixelCanvasColorTable::mapToColor3(Array<uLong> & outImage,
					   const Array<uInt> & chan1in,
					   const Array<uInt> & chan2in,
					   const Array<uInt> & chan3in)
{
  if (colorModel_ == Display::Index)
    throw(AipsError("Should not get to X11PixelCanvasColorTable::mapToColor3 in Index mode"));

  Bool ch1Del;
  const uInt * ch1p = chan1in.getStorage(ch1Del);
  Bool ch2Del;
  const uInt * ch2p = chan2in.getStorage(ch2Del);
  Bool ch3Del;
  const uInt * ch3p = chan3in.getStorage(ch3Del);

  Bool outDel;
  uLong * outp = outImage.getStorage(outDel);

  uLong * endp = outp + outImage.nelements();
  
  const uInt * ch1q = ch1p;
  const uInt * ch2q = ch2p;
  const uInt * ch3q = ch3p;

  uLong * outq = outp;

  if (pow2Mapping_)
    {
      if( !decomposedIndex())
	{
	  while (outq < endp)
	    {
	      *outq++ = colors_[((*ch1q++) << n1Shift_) | ((*ch2q++) << n2Shift_) | ((*ch3q++) << n3Shift_)];
	    }
	}
      else	// TrueColor, DirectColor.
	{
	  if(colorModel_ == Display::RGB)
		while (outq < endp)
	 	{
			uLong red = (*ch1q++ << red_shift_)&red_mask_;
			uLong green = (*ch2q++ << green_shift_)&green_mask_;
			uLong blue = (*ch3q++ << blue_shift_)&blue_mask_;
			uLong pixel = red | green | blue;
			*outq++ =  pixel;
		}
	 else	// HSV
		while (outq < endp)
	 	{ uLong r, g, b;
			// Convert HSV -> RGB.
			HSV2RGB((uLong)*ch1q++, (uLong)*ch2q++, (uLong)*ch3q++,
				r, g, b);
			uLong red = (r << red_shift_)&red_mask_;
			uLong green = (g << green_shift_)&green_mask_;
			uLong blue = (b << blue_shift_)&blue_mask_;
			uLong pixel = red | green | blue;
			*outq++ =  pixel;
		}
	}
    }
  else
    {
      if (visual_->c_class == PseudoColor || visual_->c_class == StaticColor)
	{
	  while (outq < endp)
	    {
	      *outq++ = colors_[(*ch1q++)*n1Mult_ + (*ch2q++)*n2Mult_ + (*ch3q++)*n3Mult_];
	    }
	}
      else
	{
	  if(colorModel_ == Display::RGB)
		while (outq < endp)
		{
			uLong red = (*ch1q++ << red_shift_)&red_mask_;
			uLong green = (*ch2q++ << green_shift_)&green_mask_;
			uLong blue = (*ch3q++ << blue_shift_)&blue_mask_;
			uLong pixel = red | green | blue;
			*outq++ =  pixel;
		}
	  else	// HSV
		while (outq < endp)
	 	{ uLong r, g, b;
			// Convert HSV -> RGB.
			HSV2RGB((uLong)*ch1q++, (uLong)*ch2q++, (uLong)*ch3q++,
				r, g, b);
			uLong red = (r << red_shift_)&red_mask_;
			uLong green = (g << green_shift_)&green_mask_;
			uLong blue = (b << blue_shift_)&blue_mask_;
			uLong pixel = red | green | blue;
			*outq++ =  pixel;
		}
	}
    }

  chan1in.freeStorage(ch1p, ch1Del);
  chan2in.freeStorage(ch2p, ch2Del);
  chan3in.freeStorage(ch3p, ch3Del);

  outImage.putStorage(outp, outDel);
}

void X11PixelCanvasColorTable::setupStandardMapping(const XStandardColormap * mapInfo)
{
  setupColorCube(mapInfo->red_max+1,
		 mapInfo->green_max+1,
		 mapInfo->blue_max+1,
		 mapInfo->red_mult,
		 mapInfo->green_mult,
		 mapInfo->blue_mult);
  baseColor_ = mapInfo->base_pixel;
  xcmap_ = mapInfo->colormap;
}

//----------------------------------------------------------------------------------
//
//  RGB maps
//
//  All these functions also need the mapRef to interpret/set the visual correctly
//
//----------------------------------------------------------------------------------

Visual * X11PixelCanvasColorTable::bestRGBVisual()
{
  Visual * v = 0;

  Visual * tcv = X11BestVisual(screen_, TrueColor);
  Visual * dcv = X11BestVisual(screen_, DirectColor);
  Visual * pcv = X11BestVisual(screen_, PseudoColor);
  Visual * scv = X11BestVisual(screen_, StaticColor);
  
  uInt tcd = X11DepthOfVisual(display_, tcv);
  uInt dcd = X11DepthOfVisual(display_, dcv);
  uInt pcd = X11DepthOfVisual(display_, pcv);
  uInt scd = X11DepthOfVisual(display_, scv);
  
  uInt bestDepth = max(max(tcd, dcd), max(pcd, scd));
  
  if (tcd == bestDepth) v = tcv;
  else if (dcd == bestDepth) v = dcv;
  else if (pcd == bestDepth) v = pcv;
  else if (scd == bestDepth) v = scv;

  return v;
}

Visual * X11PixelCanvasColorTable::bestRWRGBVisual()
{
  Visual * v;

  Visual * dcv = X11BestVisual(screen_, DirectColor);
  Visual * pcv = X11BestVisual(screen_, PseudoColor);

  uInt dcd = X11DepthOfVisual(display_, dcv);
  uInt pcd = X11DepthOfVisual(display_, pcv);

  if (pcd >= dcd) v = pcv; else v = dcv;

  return v;
}

void X11PixelCanvasColorTable::buildMapRGBBest(const X11PixelCanvasColorTable & mapRef)
{
  if (mapRef.colorModel() == Display::RGB)
    {
      // share the allocation, copy the fields, ref the map
      copyColorCube(mapRef);
    }
  else
    {
      // Try to make a colour cube with remaining of mapRef's colors, ref the map
      if (!allocColorCube())
	throw(AipsError("X11PixelCanvasColorTable::buildMapRGBBest(xpcct):\n"
			"could not allocate color cube on passed colormap"));
      X11ResourceManager::refColormap(screen_, xcmap_);
      fillColorCubeRGB();
    }
}

void X11PixelCanvasColorTable::buildMapRGBBest(Display::SpecialMap mapRef)
{
  rigid_ = True;
  if (mapRef == Display::New)
    {
      // If NEW map, we are allowed to try to use whatever visual
      // and colormap we can. 
      visual_ = bestRGBVisual();

      if (!visual_) throw(AipsError("X11PixelCanvasColorTable::buildMapRGBBest: Can't get visual for RGB Map"));

      XStandardColormap * mip = 0;
      if (!X11InitializeStandardColormap(screen_, visual_, XA_RGB_BEST_MAP, &mip))
	throw(AipsError("X11PixelCanvasColorTable::buildMapRGBBest: Can't build XAtom XA_RGB_BEST_MAP Map"));

      // xcmap_ set here
      setupStandardMapping(mip);
      X11ResourceManager::refColormap(screen_, xcmap_);
    }
  else if (mapRef == Display::System) 
    {
      visual_ = DefaultVisualOfScreen(screen_);
      if (!visual_)
	throw(AipsError("X11PixelCanvasColorTable::buildMapRGBBest: default visual not available"));

      xcmap_ = DefaultColormapOfScreen(screen_);
      if (!allocColorCube())
	throw(AipsError("X11PixelCanvasColorTable::buildMapRGBBest(xpcct):\n"
			"could not allocate color cube on passed colormap"));
      X11ResourceManager::refColormap(screen_, xcmap_);
      fillColorCubeRGB();
    }
  else if (mapRef == Display::Shared) 
    {
      X11ResourceManager::refColormap(screen_, xcmap_);
      fillColorCubeRGB();
    }
}

void X11PixelCanvasColorTable::buildMapRGBDefault(const X11PixelCanvasColorTable & mapRef)
{
  if (mapRef.colorModel() == Display::RGB)
    {
      copyColorCube(mapRef);
    }
  else
    {
      // Try a standard cube first
	//????????????????????????????????????????????????????????????????
	// Why is this 6/6/6 and not dependent on the # of available colors?
      Bool ok = allocColorCube(6,6,6);
      if (!ok) 
	// Fails, take the best it can
	ok = allocColorCube();
      if (!ok)
	throw(AipsError("X11PixelCanvasColorTable::buildMapRGBDefault(ref):\n"
			"could not allocate color cube on passed colormap"));
	
      X11ResourceManager::refColormap(screen_, xcmap_);
      fillColorCubeRGB();
    }
}

void X11PixelCanvasColorTable::buildMapRGBDefault(Display::SpecialMap mapRef)
{
  if (mapRef == Display::New)
    {
      // If NEW map, we are allowed to try to use whatever visual
      // and colormap we can.  Sort visuals by depth, then by
      // preference (DC, TC, PC, SC)
      visual_ = bestRGBVisual();
      if (!visual_) throw(AipsError("X11PixelCanvasColorTable::buildMapRGBDefault: Can't get visual for RGB Map"));
      checkVisual();

      Atom propMap = XA_RGB_DEFAULT_MAP;
      if (visual_->c_class == TrueColor) propMap = XA_RGB_BEST_MAP;

      XStandardColormap * mip = NULL;
      if (!X11InitializeStandardColormap(screen_, visual_, propMap, &mip))
	throw(AipsError("X11PixelCanvasColorTable::buildMapRGBDefault: Can't build default RGB Map"));
      
      setupStandardMapping(mip);
    }
  else // mapRef is Display::System
    {
      if (!allocColorCube())
	throw(AipsError("X11PixelCanvasColorTable::buildMapRGBDefault(ref):\n"
			"could not allocate color cube on passed colormap"));
      X11ResourceManager::refColormap(screen_, xcmap_);
      fillColorCubeRGB();
    }
}

void X11PixelCanvasColorTable::buildMapRGBMinMax(const X11PixelCanvasColorTable & mapRef,
						 uInt minR, uInt minG, uInt minB,
						 uInt maxR, uInt maxG, uInt maxB)
{
  if (mapRef.colorModel() == Display::RGB)
    {
      if (minR <= mapRef.n1_ && mapRef.n1_ <= maxR &&
	  minG <= mapRef.n2_ && mapRef.n2_ <= maxG &&
	  minB <= mapRef.n3_ && mapRef.n3_ <= maxB)
	copyColorCube(mapRef);
      else
	{
	  if (!allocColorCubeMinMax(minR, minG, minB, maxR, maxG, maxB))
	    throw(AipsError("X11PixelCanvasColorTable::buildMapRGBMinMax(ref):\n"
			    "Failed to satisfy request"));
	  X11ResourceManager::refColormap(screen_, xcmap_);
	  fillColorCubeRGB();
	}
    }
  else // Index or HSV
    {
      if (!allocColorCubeMinMax(minR, minG, minB, maxR, maxG, maxB))
	throw(AipsError("X11PixelCanvasColorTable::buildMapRGBMinMax(ref):\n"
			"Failed to satisfy request"));
      X11ResourceManager::refColormap(screen_, xcmap_);
      fillColorCubeRGB();
    }
}

void X11PixelCanvasColorTable::buildMapRGBMinMax(Display::SpecialMap mapRef,
						 uInt minR, uInt minG, uInt minB,
						 uInt maxR, uInt maxG, uInt maxB)
{
  if (mapRef == Display::New)
    {
      visual_ = bestRGBVisual();
      checkVisual();

      // Try to set up a standard map
      XStandardColormap * mip = NULL;
      if (!X11InitializeStandardColormap(screen_, visual_, XA_RGB_BEST_MAP, &mip))
	throw(AipsError("X11PixelCanvasColorTable::buildMapRGBMinMax: Can't build XAtom XA_RGB_BEST_MAP Map"));
      
      if (minR <= mip->red_max+1 && mip->red_max+1 <= maxR &&
	  minG <= mip->green_max+1 && mip->green_max+1 <= maxG &&
	  minB <= mip->blue_max+1 && mip->blue_max+1 <= maxB)
	{
	  setupStandardMapping(mip);
	}
      else
	{
	  visual_ = bestRWRGBVisual();
	  checkVisual();
	  if (!visual_)
	    throw(AipsError("X11PixelCanvasColorTable::buildMapRGBMinMax: \n"
			    "Can't get a visual."));
	  xcmap_ = XCreateColormap(display_, RootWindowOfScreen(screen_), visual_, AllocNone);
	  if (!allocColorCubeMinMax(minR, minG, minB, maxR, maxG, maxB))
	    throw(AipsError("X11PixelCanvasColorTable::buildMapRGBMinMax: \n"
			    "Can't allocate the available colors"));
	  X11ResourceManager::refColormap(screen_, xcmap_);
	  fillColorCubeRGB();
	}
    }
  else if (mapRef == Display::System) 
    {
      visual_ = DefaultVisualOfScreen(screen_);
      checkVisual();
      xcmap_ = DefaultColormapOfScreen(screen_);
      if (!allocColorCubeMinMax(minR, minG, minB, maxR, maxG, maxB))
	throw(AipsError("X11PixelCanvasColorTable::buildMapRGBMinMax: \n"
			"Can't allocate the available colors"));
      X11ResourceManager::refColormap(screen_, xcmap_);
      fillColorCubeRGB();
    }
  else if (mapRef == Display::Shared) {
    if (!allocColorCubeMinMax(minR, minG, minB, maxR, maxG, maxB))
      throw(AipsError("X11PixelCanvasColorTable::buildMapRGBMinMax: \n"
		      "Can't allocate the available colors"));
    //X11ResourceManager::refColormap(screen_, xcmap_);
    fillColorCubeRGB();
  }
}

void X11PixelCanvasColorTable::buildMapRGBCustom(const X11PixelCanvasColorTable & mapRef,
						 uInt nR, uInt nG, uInt nB)
{
  if (mapRef.colorModel() == Display::RGB)
    {
      if (nR == mapRef.n1_ && nG == mapRef.n2_ && nB == mapRef.n3_)
	copyColorCube(mapRef);
      else
	{
	  if (!allocColorCube(nR, nG, nB))
	    throw(AipsError("X11PixelCanvasColorTable::buildMapRGBCustom(ref):\n"
			    "Failed to satisfy request"));
	  X11ResourceManager::refColormap(screen_, xcmap_);
	  fillColorCubeRGB();
	}
    }
  else
    {
      if (!allocColorCube(nR, nG, nB))
	throw(AipsError("X11PixelCanvasColorTable::buildMapRGBCustom(ref):\n"
			"Failed to satisfy request"));
      X11ResourceManager::refColormap(screen_, xcmap_);
      fillColorCubeRGB();
    }
}
void X11PixelCanvasColorTable::buildMapRGBCustom(Display::SpecialMap mapRef,
						 uInt nR, uInt nG, uInt nB)
{
  if (mapRef == Display::New)
    {
      visual_ = bestRGBVisual();
      checkVisual();

      XStandardColormap * mip = NULL;
      if (!X11InitializeStandardColormap(screen_, visual_, XA_RGB_BEST_MAP, &mip))
	throw(AipsError("X11PixelCanvasColorTable::buildMapRGBCustom: \n"
			"Can't build XAtom XA_RGB_BEST_MAP Map"));

      if (nR == mip->red_max+1 && nG == mip->green_max+1 && nB == mip->blue_max+1)
	setupStandardMapping(mip);
      else
	{
	  visual_ = bestRWRGBVisual();
	  if (!visual_)
	    throw(AipsError("X11PixelCanvasColorTable::buildMapRGBCustom: \n"
			    "Can't get a visual."));
	  checkVisual();
	  xcmap_ = XCreateColormap(display_, RootWindowOfScreen(screen_), visual_, AllocNone);
	  if (!allocColorCube(nR, nG, nB))
	    throw(AipsError("X11PixelCanvasColorTable::buildMapRGBCustom: \n"
			    "Can't allocate the available colors"));
	  X11ResourceManager::refColormap(screen_, xcmap_);
	  fillColorCubeRGB();
	}
    }
  else // mapRef == Display::System
    {
      visual_ = DefaultVisualOfScreen(screen_);
      checkVisual();
      xcmap_ = DefaultColormapOfScreen(screen_);
      if (!allocColorCube(nR, nG, nB))
	throw(AipsError("X11PixelCanvasColorTable::buildMapRGBCustom: \n"
			"Can't allocate the available colors"));
      X11ResourceManager::refColormap(screen_, xcmap_);
      fillColorCubeRGB();
    }
}

void X11PixelCanvasColorTable::buildMapRGBPercent(const X11PixelCanvasColorTable & mapRef,
						  Float percent)
{
  if (percent >= 100) 
    { buildMapRGBBest(mapRef); return; }

  uInt nCells = QueryColorsAvailable(True);
  uInt nToAlloc = (uInt)(percent * 0.01 * nCells);
  uInt n1, n2, n3;
  getRGBDistribution(nToAlloc, False, n1, n2, n3);
  if (!allocColorCube(n1, n2, n3))
    throw(AipsError("X11PixelCanvasColorTable::buildMapRGBPercent: \n"
		    "Can't allocate the requested colors"));
  X11ResourceManager::refColormap(screen_, xcmap_);
  fillColorCubeRGB();
}

// Choose colormap and allocate RW colormap cells for 'RGB'.
void X11PixelCanvasColorTable::buildMapRGBPercent(Display::SpecialMap mapRef,
						  Float percent)
{
  if (percent >= 100) 
    { buildMapRGBBest(mapRef); return; }

  if (mapRef == Display::New)
    {
      visual_ = X11BestVisual(screen_, PseudoColor);
      xcmap_ = XCreateColormap(display_, RootWindowOfScreen(screen_), visual_, AllocNone);
    }
  else if (mapRef == Display::System)
    {
      visual_ = DefaultVisualOfScreen(screen_);
      xcmap_ = DefaultColormapOfScreen(screen_);
    }
  else if (mapRef == Display::Shared) {
    // nothing !
  }

  checkVisual();
  uInt n1, n2, n3;
  uInt nCells = QueryColorsAvailable(True);
  uInt nToAlloc = (uInt)(percent * 0.01 * nCells);
  getRGBDistribution(nToAlloc, False, n1, n2, n3);

  if (!allocColorCube(n1, n2, n3))
    throw(AipsError("X11PixelCanvasColorTable::buildMapRGBPercent: \n"
		    "Can't allocate the requested colors"));
  X11ResourceManager::refColormap(screen_, xcmap_);
  fillColorCubeRGB();
}


//--------------------------------------------------------------------------------------
//
//  HSV Colormaps
//
//  X11 has no HSV mapping support, so have to do it yourself.
//  I wanted to create XA_HSV_BEST_MAP and XA_HSV_DEFAULT_MAP properties
//  so multiple clients could share the definition, but I don't think that
//  is really necessary.
//
//  If you have TrueColor or DirectColor visuals available that have significantly
//  more bits than your PseudoColor visual, you should use RGB colormodel here at the table
//  level and HSV at the PixelCanvas level for best results.
//
//  Before HSV funcs are called, visual_ and xcmap_ have been set and ref'd.
//
//--------------------------------------------------------------------------------------

void X11PixelCanvasColorTable::buildMaxHSV()
{
  // Build the best HSV map on the preset xcmap_
  if (visual_->c_class != PseudoColor)
    throw(AipsError("PseudoColor visual required for HSV colortable map."));

  uInt nCells = QueryColorsAvailable(True);
  uInt n1, n2, n3;
  getRGBDistribution(nCells, False, n1, n2, n3);
  if (!allocColorCube(n1, n2, n3))
    throw(AipsError("X11PixelCanvasColorTable::buildMapRGBPercent: \n"
		    "Can't allocate the requested colors"));
  fillColorCubeHSV();
}

void X11PixelCanvasColorTable::buildMapHSVBest(const X11PixelCanvasColorTable & mapRef)
{
  if (mapRef.colorModel() == Display::HSV)
    {
      copyColorCube(mapRef);
    }
  else
    {
      if (!allocColorCube())
	throw(AipsError("X11PixelCanvasColorTable::buildMapHSVBest(xpcct):\n"
			"could not allocate color cube on passed colormap"));
      fillColorCubeHSV();
    }
}
void X11PixelCanvasColorTable::buildMapHSVBest(Display::SpecialMap )
{
  buildMaxHSV();
}

void X11PixelCanvasColorTable::buildMapHSVDefault(const X11PixelCanvasColorTable & mapRef)
{
  if (mapRef.colorModel() == Display::HSV)
    {
      copyColorCube(mapRef);
    }
  else
    {
      // Try a standard cube first
      Bool ok = allocColorCube(6,6,6);
      if (!ok) 
	// Fails, take the best it can
	ok = allocColorCube();
      if (!ok)
	throw(AipsError("X11PixelCanvasColorTable::buildMapHSVDefault(ref):\n"
			"could not allocate color cube on passed colormap"));
      
      fillColorCubeHSV();
    }
}

void X11PixelCanvasColorTable::buildMapHSVDefault(Display::SpecialMap )
{
  buildMaxHSV();
}

void X11PixelCanvasColorTable::buildMapHSVMinMax(const X11PixelCanvasColorTable & mapRef,
						 uInt minH, uInt minS, uInt minV,
						 uInt maxH, uInt maxS, uInt maxV)
{
  if (mapRef.colorModel() == Display::HSV)
    {
      if (minH <= mapRef.n1_ && mapRef.n1_ <= maxH &&
	  minS <= mapRef.n2_ && mapRef.n2_ <= maxS &&
	  minV <= mapRef.n3_ && mapRef.n3_ <= maxV)
	copyColorCube(mapRef);
      else
	{
	  if (!allocColorCubeMinMax(minH, minS, minV, maxH, maxS, maxV))
	    throw(AipsError("X11PixelCanvasColorTable::buildMapRGBMinMax(ref):\n"
			    "Failed to satisfy request"));
	  fillColorCubeHSV();
	}
    }
  else // Index or RGB
    {
      if (!allocColorCubeMinMax(minH, minS, minV, maxH, maxS, maxV))
	throw(AipsError("X11PixelCanvasColorTable::buildMapRGBMinMax(ref):\n"
			"Failed to satisfy request"));
      fillColorCubeHSV();
    }
}

void X11PixelCanvasColorTable::buildMapHSVMinMax(uInt minH, uInt minS, 
						 uInt minV,
						 uInt maxH, uInt maxS, 
						 uInt maxV)
{
  if (!allocColorCubeMinMax(minH, minS, minV, maxH, maxS, maxV))
    throw(AipsError("X11PixelCanvasColorTable::buildMapHSVMinMax: \n"
		    "Can't allocate the available colors"));
  fillColorCubeHSV();
}

void X11PixelCanvasColorTable::buildMapHSVCustom(const X11PixelCanvasColorTable & mapRef,
						 uInt nH, uInt nS, uInt nV)
{
  if (mapRef.colorModel() == Display::HSV)
    {
      if (nH == mapRef.n1_ && nS == mapRef.n2_ && nV == mapRef.n3_)
	copyColorCube(mapRef);
      else
	{
	  if (!allocColorCube(nH, nS, nV))
	    throw(AipsError("X11PixelCanvasColorTable::buildMapRGBCustom(ref):\n"
			    "Failed to satisfy request"));
	  fillColorCubeHSV();
	}
    }
  else
    {
      if (!allocColorCube(nH, nS, nV))
	throw(AipsError("X11PixelCanvasColorTable::buildMapRGBCustom(ref):\n"
			"Failed to satisfy request"));
      fillColorCubeHSV();
    }
}

void X11PixelCanvasColorTable::buildMapHSVCustom(uInt nH, uInt nS, uInt nV)
{
  if (!allocColorCube(nH, nS, nV))
    throw(AipsError("X11PixelCanvasColorTable::buildMapRGBCustom(ref):\n"
		    "Failed to satisfy request"));
  fillColorCubeHSV();
}
 
void X11PixelCanvasColorTable::buildMapHSVPercent(const X11PixelCanvasColorTable & mapRef,
						  Float percent)
{
  if (percent >= 100) 
    { buildMapHSVBest(mapRef); return; }

  uInt nCells = QueryColorsAvailable(True);
  uInt nToAlloc = (uInt)(percent * 0.01 * nCells);
  uInt n1, n2, n3;
  getRGBDistribution(nToAlloc, False, n1, n2, n3);
  if (!allocColorCube(n1, n2, n3))
    throw(AipsError("X11PixelCanvasColorTable::buildMapRGBPercent: \n"
		    "Can't allocate the requested colors"));
  fillColorCubeHSV();
}

void X11PixelCanvasColorTable::buildMapHSVPercent(Display::SpecialMap mapRef,
						  Float percent)
{
  if (percent >= 100) 
    { buildMapHSVBest(mapRef); return; }
  
  uInt nCells = QueryColorsAvailable(True);
  uInt nToAlloc = (uInt)(percent * 0.01 * nCells);
  uInt n1, n2, n3;
  getRGBDistribution(nToAlloc, False, n1, n2, n3);
  if (!allocColorCube(n1, n2, n3))
    throw(AipsError("X11PixelCanvasColorTable::buildMapRGBPercent: \n"
		    "Can't allocate the requested colors"));
  fillColorCubeHSV();
}

//-------------------------------------------------------------------------------------

uInt X11PixelCanvasColorTable::RGB2Index(float r, float g, float b)
{
  /*
  if (colorModel_ == Display::RGB)
    {
      return tripletIndex(r,g,b);
    }

  else if (colorModel_ == Display::Index)
  */
    {
      // convert to unsigned short values
      uShort rs = (uShort) (65535.0*r);
      uShort gs = (uShort) (65535.0*g);
      uShort bs = (uShort) (65535.0*b);

      // X11RM::allocColor will resize one of its colormaps if it can
      // to free a cell to be allocated read-only
      return X11ResourceManager::allocColor(this,rs,gs,bs);
    }
    /* 
  else if (colorModel_ == Display::HSV)
    {
      float h,s,v;
      rgbToHsv(r,g,b,h,s,v);
      return tripletIndex(h,s,v);
    }
    */
  return 0;
}

uInt X11PixelCanvasColorTable::HSV2Index(float h, float s, float v)
{
  if (colorModel_ == Display::HSV)
    {
      return tripletIndex(h,s,v);
    }
  else if (colorModel_ == Display::Index)
    {
      float r,g,b;
      hsvToRgb(h,s,v,r,g,b);

      // convert to unsigned short values
      uShort rs = (uShort) (65535.0*r);
      uShort gs = (uShort) (65535.0*g);
      uShort bs = (uShort) (65535.0*b);

      // X11RM::allocColor may resize one of its colormaps if it can
      // to free a cell to be allocated read-only
      return X11ResourceManager::allocColor(this,rs,gs,bs);
    }
  else if (colorModel_ == Display::RGB)
    {
      float r,g,b;
      hsvToRgb(h,s,v,r,g,b);
      return tripletIndex(r,g,b);
    }
  return 0;
}


//-------------------------------------------------------------------------------------

ostream & operator << (ostream & os, const X11PixelCanvasColorTable & pcc)
{
  os << "--------------------- X11PixelCanvasColorTable -----------------\n";
  //os << "Display  : " << pcc.display_ << endl;
  //os << "Screen   : " << pcc.screen_ << endl;
  os << "Visual   : " << pcc.visual_ << endl;
  os << "XColormap : " << pcc.xcmap_ << endl;
  os << "Depth    : " << pcc.depth_ << endl;
  os << "nColors  : " << pcc.nColors_ << endl;
  os << "Rigid    : " << (pcc.rigid_ ? "Yes" : "No") << endl;
  
  os << "color model      : " << pcc.colorModel_ << endl;
  os << "pow2Mapping      : " << pcc.pow2Mapping_ << endl;
  os << "baseColor        : " << pcc.baseColor_ << endl;
  os << "Color Cube -" << endl;    
  os << "  resolution    : <" << pcc.n1_ << "," << pcc.n2_ << "," << pcc.n3_ << ">\n";
  os << "  multipliers   : <" << pcc.n1Mult_ << "," << pcc.n2Mult_ << "," << pcc.n3Mult_ << ">\n";
  os << "  bits          : <" << pcc.n1Bits_ << "," << pcc.n2Bits_ << "," << pcc.n3Bits_ << ">\n";
  os << "  shift         : <" << pcc.n1Shift_ << "," << pcc.n2Shift_ << "," << pcc.n3Shift_ << ">\n";
  os << "------------------- END X11PixelCanvasColorTable ---------------\n";
  return os;
}



#if 0
template <class T>
static void X11PixelCanvasColorTable_mapToColor(uLong * table,
						uInt tableSize,
						uInt mapOffset,
						Array<T> & outArray,
						const Array<T> & inArray,
						Bool rangeCheck)
{
  IPosition shape = inArray.shape();
  outArray.resize(shape);

  ReadOnlyVectorIterator<uChar> vi(inArray);
  VectorIterator<uChar> vo(outArray);

  uInt n = vi.vector().nelements();
  uChar val;

  if (rangeCheck) {
      uInt maxc = tableSize-1;
      while (!vi.pastEnd()) {
	  for (uInt i = 0; i < n; i++) {
	      val = vi.vector()(i);
	      vo.vector()(i) = table[(val <= 0) ? 0 : (val >= maxc) ? maxc : val]; }
	  vi.next(); }}
  else {
      while (!vi.pastEnd()) {
	  for (uInt i = 0; i < n; i++) {
	      vo.vector()(i) = table[vi.vector()(i)]; }
	  vi.next(); }}
}
#endif

//
// I had problems getting the above templated mapToColor to compile with gnu.  I had
// two basic mapToColor functions, one has two array parameters, the
// other has one.  gnu compiler would instantiate the mapToColor with
// just the one array parameter just fine.  When it got to the one with
// two arrays, it would fail with the error shown below.
// 
// templates file
// 1010 trialdisplay/Display/X11PixelCanvasColorTable.cc template void X11PixelCanvasColorTable_mapToColor(uLong *, uInt, uInt, Array<uChar> &, Bool)
// 1020 trialdisplay/Display/X11PixelCanvasColorTable.cc template void X11PixelCanvasColorTable_mapToColor(uLong *, uInt, uInt, Array<uChar> &, const Array<uChar> &, Bool)
// Updating dependencies for X11PixelCanvasColorTable_1010.cc

// /usr/local/gnu/bin/g++ -D__cplusplus -DAIPS_NONAMESPACE -DAIPS_SOLARIS   -DAIPS_DEBUG  -I/home/avior/jpixton/aips++/code/include -I/home/avior/jpixton/aips++/sun4sol_gnu -I/appl/aips++/aips++/code/include -I/usr/dt/include -I/usr/openwin/include -c -g -fno-for-scope -fno-implicit-templates  -o /home/avior/jpixton/aips++/sun4sol_gnu/libdbg/X11PixelCanvasColorTable_1010.o X11PixelCanvasColorTable_1010.cc;

// Updating dependencies for X11PixelCanvasColorTable_1020.cc

// /usr/local/gnu/bin/g++ -D__cplusplus -DAIPS_NONAMESPACE -DAIPS_SOLARIS   -DAIPS_DEBUG  -I/home/avior/jpixton/aips++/code/include -I/home/avior/jpixton/aips++/sun4sol_gnu -I/appl/aips++/aips++/code/include -I/usr/dt/include -I/usr/openwin/include -c -g -fno-for-scope -fno-implicit-templates  -o /home/avior/jpixton/aips++/sun4sol_gnu/libdbg/X11PixelCanvasColorTable_1020.o X11PixelCanvasColorTable_1020.cc;
// X11PixelCanvasColorTable_1020.cc:3: sorry, not implemented: use of `enumeral_type' in template type unification
// gmake[1]: [/home/avior/jpixton/aips++/sun4sol_gnu/libdbg/X11PixelCanvasColorTable_1020.o] Error 1 (ignored)

//
// if you truly can't use an enum in a template type, why did 1010
// compile???
//
// John Pixton
//
// So template was expanded into four functions for uChar,uShort,uInt,uLong types.
//

void X11PixelCanvasColorTable::mapToColor(const Colormap * map, 
					  Array<uChar> & outArray,
					  const Array<uChar> & inArray,
					  Bool rangeCheck) const
{
  Bool inDel;
  const uChar * inp = inArray.getStorage(inDel);

  uInt offset = getColormapOffset(map);
  uInt cmapsize = getColormapSize(map);
  uChar maxc   = offset + cmapsize - 1;

  Bool outDel;
  uChar * outp = outArray.getStorage(outDel);
  uChar * endp = outp + outArray.nelements();

  const uChar * inq = inp;
  uChar * outq = outp;

  if (rangeCheck)
    {    while( outq < endp)
	 { uLong pIndex, vIndex;

		vIndex = (*inq >= cmapsize) ? maxc : offset + *inq;
		if(virtualToPhysical(vIndex, pIndex))
			*outq++ = (uChar)pIndex;
		else
			*outq++ = 0;	// Shouldn't happen.
		inq++;
	}
    }
  else
    {    while( outq < endp)
	 { uLong pIndex, vIndex;

		vIndex = offset + *inq++;
		virtualToPhysical(vIndex, pIndex);
		*outq++ = (uChar)pIndex;
	}
    }

  inArray.freeStorage(inp, inDel);
  outArray.putStorage(outp, outDel);
}

void X11PixelCanvasColorTable::mapToColor(const Colormap * map, 
					  Array<uShort> & outArray,
					  const Array<uShort> & inArray,
					  Bool rangeCheck) const
{
  Bool inDel;
  const uShort * inp = inArray.getStorage(inDel);

  uInt offset = getColormapOffset(map);
  uInt cmapsize = getColormapSize(map);
  uShort maxc   = offset + cmapsize - 1;

  Bool outDel;
  uShort * outp = outArray.getStorage(outDel);
  uShort * endp = outp + outArray.nelements();

  const uShort * inq = inp;
  uShort * outq = outp;

  if (rangeCheck)
    {    while( outq < endp)
	 { uLong pIndex, vIndex;

		vIndex = (*inq >= cmapsize) ? maxc : offset + *inq;
		if(virtualToPhysical(vIndex, pIndex))
			*outq++ = (uShort)pIndex;
		else
			*outq++ = 0;	// Shouldn't happen.
		inq++;
	}
   }
  else
    {    while( outq < endp)
	 { uLong pIndex, vIndex;

		vIndex = offset + *inq++;
		virtualToPhysical(vIndex, pIndex);
		*outq++ = (uShort)pIndex;
	}
    }

  inArray.freeStorage(inp, inDel);
  outArray.putStorage(outp, outDel);
}

void X11PixelCanvasColorTable::mapToColor(const Colormap * map, 
					  Array<uInt> & outArray,
					  const Array<uInt> & inArray,
					  Bool rangeCheck) const
{
  Bool inDel;
  const uInt * inp = inArray.getStorage(inDel);

  Bool outDel;
  uInt * outp = outArray.getStorage(outDel);
  uInt * endp = outp + outArray.nelements();

  uInt offset = getColormapOffset(map);
  uInt cmapsize = getColormapSize(map);
  uInt maxc   = offset + cmapsize - 1;

  const uInt * inq = inp;
  uInt * outq = outp;

  if (rangeCheck)
    {    while( outq < endp)
	 { uLong pIndex, vIndex;

		vIndex = (*inq >= cmapsize) ? maxc : offset + *inq;
		if(virtualToPhysical(vIndex, pIndex))
			*outq++ = (uInt)pIndex;
		else
			*outq++ = 0;	// Shouldn't happen.
		inq++;
	}
    }
  else
    {    while( outq < endp)
	 { uLong pIndex, vIndex;

		vIndex = offset + *inq++;
		virtualToPhysical(vIndex, pIndex);
		*outq++ = (uInt)pIndex;
	}
    }

  inArray.freeStorage(inp, inDel);
  outArray.putStorage(outp, outDel);
}

void X11PixelCanvasColorTable::mapToColor(const Colormap * map, 
					  Array<uLong> & outArray,
					  const Array<uLong> & inArray,
					  Bool rangeCheck) const
{
  Bool inDel;
  const uLong * inp = inArray.getStorage(inDel);

  uInt offset = getColormapOffset(map);
  uInt cmapsize = getColormapSize(map);
  uLong maxc   = offset + cmapsize - 1;

  Bool outDel;
  uLong * outp = outArray.getStorage(outDel);
  uLong * endp = outp + outArray.nelements();

  const uLong * inq = inp;
  uLong * outq = outp;

  if (rangeCheck)
    {    while( outq < endp)
	 { uLong pIndex, vIndex;

		vIndex = (*inq >= cmapsize) ? maxc : offset + *inq;
		if(virtualToPhysical(vIndex, pIndex))
			*outq++ = pIndex;
		else
			*outq++ = 0;	// Shouldn't happen.
		inq++;
	}
    }
  else
    {    while( outq < endp)
	 { uLong pIndex, vIndex;

		vIndex = offset + *inq++;
		virtualToPhysical(vIndex, pIndex);
		*outq++ = pIndex;
	}
    }

  inArray.freeStorage(inp, inDel);
  outArray.putStorage(outp, outDel);
}

template <class T>
void X11PixelCanvasColorTable_mapToColor(uLong * table,
					 uInt tableSize,
					 uInt mapOffset,
					 Array<T> & inOutArray,
					 Bool rangeCheck);

void X11PixelCanvasColorTable::mapToColor(const Colormap * map,
					  Array<uChar> & inOutArray,
					  Bool rangeCheck) const
{
  X11PixelCanvasColorTable_mapToColor(colors_, nColors_, getColormapOffset(map),
				      inOutArray, rangeCheck);
}
void X11PixelCanvasColorTable::mapToColor(const Colormap * map,
					  Array<uShort> & inOutArray,
					  Bool rangeCheck) const
{
  X11PixelCanvasColorTable_mapToColor(colors_, nColors_, getColormapOffset(map),
				      inOutArray, rangeCheck);
}
void X11PixelCanvasColorTable::mapToColor(const Colormap * map,
					  Array<uInt> & inOutArray,
					  Bool rangeCheck) const 
{
  X11PixelCanvasColorTable_mapToColor(colors_, nColors_, getColormapOffset(map),
				      inOutArray, rangeCheck);
}
void X11PixelCanvasColorTable::mapToColor(const Colormap * map,
					  Array<uLong> & inOutArray,
					  Bool rangeCheck) const
{
  X11PixelCanvasColorTable_mapToColor(colors_, nColors_, getColormapOffset(map),
				      inOutArray, rangeCheck);
}

VColorTableEntry::VColorTableEntry()
{	red_ = green_ = blue_ = 0.0;
	index_ = 0;
	pixel_ = 0;
}

void VColorTableEntry::operator=(const VColorTableEntry &e)
{
	index_ = e.index_;
	pixel_ = e.pixel_;
	red_ = e.red_;
	green_ = e.green_;
	blue_ = e.blue_;
}

ostream &operator<<(ostream &s, const VColorTableEntry &e)
{
	s << " Index = " << e.getIndex();
	s << " Pixel = " << e.getPixel();
	float r, g, b;
	e.get(r, g, b);
	s << " RGB = " << r << "/" << g << "/" << b;
	return s;
}

// # of colors that can still be allocated RW.
uInt X11PixelCanvasColorTable::QueryColorsAvailable(const Bool contig)const
{
	if(readOnly())
		return (uInt)vcmapLength_ - nColors_;
	else
		return QueryHWColorsAvailable(contig);
}

uInt X11PixelCanvasColorTable::QueryHWColorsAvailable(const Bool contig)const
{
	return X11QueryColorsAvailable(display_, xcmap_, contig);
}

// Convert a virtual index to a physical pixel. Valid range is 0 to nColors_ -1.
// Returns False if vindex is out of range. Otherwise, True.
Bool X11PixelCanvasColorTable::virtualToPhysical(const uLong vindex,
			  			 uLong &pindex)const
{
	if(vindex >= nColors_)
		return False;
	else
	{ int index = colors_[vindex];
			pindex = vcmap_[index].getPixel();
		return True;
	}
}

} //# NAMESPACE CASA - END

