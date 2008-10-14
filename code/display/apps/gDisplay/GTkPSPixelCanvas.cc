//# GTkPSPixelCanvas.cc: GlishTk wrapper for a PSPixelCanvas object
//# Copyright (C) 1999,2000,2002
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
//# $Id: GTkPSPixelCanvas.cc,v 19.4 2005/06/15 18:09:13 cvsmgr Exp $

#include <casa/aips.h>
#include <tasking/Glish/GlishValue.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Arrays/IPosition.h>
#include <display/Display/PSDriver.h>
#include <display/Display/PSPixelCanvasColorTable.h>
#include <display/Display/PSPixelCanvas.h>
#include <display/Display/ColormapDefinition.h>

#include "GTkPSPixelCanvas.h"
#include "gDisplay.h"

namespace casa {

GTkPSPixelCanvas::GTkPSPixelCanvas(ProxyStore *s, const String &filename,
				   const String &media, const casa::Bool &landscape,
				   const Float &aspect, const Int &dpi,
				   const Float &zoom, const casa::Bool &eps,
				   const Value *colors,
				   const String& maptype) :
  GTkDisplayProxy(s, 0),
  itsPSDriver(0),
  itsPSPixelCanvas(0),
  itsIsValid(0) {

  // set the type of agent
  agent_ID = "<non-graphic:pspixelcanvas>";

  PSDriver::Layout medialayout;
  if (eps) {
    if (landscape) {
      medialayout = PSDriver::EPS_LANDSCAPE;
    } else {
      medialayout = PSDriver::EPS_PORTRAIT;
    }
  } else {
    if (landscape) {
      medialayout = PSDriver::LANDSCAPE;
    } else {
      medialayout = PSDriver::PORTRAIT;
    }
  }

  const PSDriver::PageInfo *p = PSDriver::lookupPageInfo(media.c_str());
  if (!p) {
    throw(AipsError("Unknown media: " + media));
  }
  PSDriver::MediaSize mediaformat = p->media;

  Float pagewidth = p->width;
  Float pageheight = p->height;
  if (landscape) {
    pagewidth = p->height;
    pageheight = p->width;
  }
  Float pagelrmarg = p->lrmargin;
  Float pagetbmarg = p->tbmargin;
  if (landscape) {
    pagelrmarg = p->tbmargin;
    pagetbmarg = p->lrmargin;
  }
  PSDriver::Dimension pagedim = p->dimension;

  Float pdrawwidth = pagewidth - 2 * pagelrmarg;
  Float pdrawheight = pageheight - 2 * pagetbmarg;
  Float pdrawaspect = pdrawheight / pdrawwidth; // assume PORTRAIT!
  Float useaspect = aspect;
  //cerr << "pdrawwidth x pdrawheight = " << pdrawwidth << " x " 
  //     << pdrawheight << endl;
  //cerr << "pdrawaspect = " << pdrawaspect << endl;
  //cerr << "useaspect = " << useaspect << endl;
  if (useaspect < pdrawaspect) { // drawing is "short and wide" cf. page
    pdrawheight = pdrawwidth * useaspect;
  } else { // drawing is "tall and skinny" cf. page
    pdrawwidth = pdrawheight / useaspect;
  }

  //cerr << "pdrawwidth x pdrawheight = " << pdrawwidth << " x " 
  //     << pdrawheight << endl;
  
  if ((0.0 < zoom) && (zoom < 1.0)) {
    pdrawwidth *= zoom;
    pdrawheight *= zoom;
  }

  Float x0 = pagewidth;
  Float y0 = pageheight;
  if (landscape) {
    x0 = pageheight;
    y0 = pagewidth;
  }
  Float x1 = (pagewidth - pdrawwidth) / 2.0;
  Float y1 = (pageheight - pdrawheight) / 2.0;
  if (landscape) {
    x1 = (pageheight - pdrawheight) / 2.0;
    y1 = (pagewidth - pdrawwidth) / 2.0;
  }

  //cerr << "x0, y0 = " << x0 << ", " << y0 << endl;
  //cerr << "x1, y1 = " << x1 << ", " << y1 << endl;

  itsPSDriver = new PSDriver(filename, mediaformat, pagedim, 
			     x0, y0, x1, y1, medialayout);
  itsPSPCColorTable = new PSPixelCanvasColorTable(itsPSDriver);
  itsPSPixelCanvas = new PSPixelCanvas(itsPSDriver, itsPSPCColorTable);
  itsPSPixelCanvas->setResolution(dpi, dpi, PSDriver::INCHES);

  // determine colormodel based on string argument
  Display::ColorModel colormodel = Display::Index;
  if (maptype == "index") {
    colormodel = Display::Index;
  } else if (maptype == "rgb") {
    colormodel = Display::RGB;
  } else if (maptype == "hsv") {
    colormodel = Display::HSV;
  } else {
    throw(AipsError("Unknown maptype given to the pixelcanvas"));
  }
  itsPSPCColorTable->setColorModel(colormodel);

  // determine color allocation
  Int col[3];
  if ((colormodel == Display::Index) && (colors->Length() == 1)) {
    int is_copy;
    colors->CoerceToIntArray(is_copy, 1, col);
    itsPSPCColorTable->resize(col[0]);
  } else if (((colormodel == Display::RGB) || (colormodel == Display::HSV)) 
	     && (colors->Length() >= 1)) {
    int is_copy;
    colors->CoerceToIntArray(is_copy, 3, col);
    itsPSPCColorTable->resize(col[0], col[1], col[2]);
  } else {
    throw(AipsError("An inconsistent combination of colors and maptype "
		    "was given to the pspixelcanvas"));
  }

  procs.Insert("status",
	       new TkDisplayProc(this, &GTkPSPixelCanvas::status));
  
  itsIsValid = 1;
}

extern "C" void GTkPSPixelCanvas_Create(ProxyStore *global_store, Value *args) {
  try {
    // a handle for the agent we will build
    GTkPSPixelCanvas *ret;

    // check for number of arguments
    if (args->Length() != 9) {
      global_store->Error("too few or too many arguments to pspixelcanvas "
			  "agent");
      return;
    }

    // fetch arguments
    if (args->Type() != TYPE_RECORD) {
      global_store->Error("argument to pspixelcanvas was not a record");
      return;
    }
    Ref(args);
    recordptr rptr = args->RecordPtr(0);
    int c = 0;
    const char *key;
    String filename(rptr->NthEntry(c++, key)->StringVal());
    String media(rptr->NthEntry(c++, key)->StringVal());
    Bool landscape(rptr->NthEntry(c++, key)->BoolVal());
    Float aspect(rptr->NthEntry(c++, key)->FloatVal());
    Int dpi(rptr->NthEntry(c++, key)->IntVal());
    Float zoom(rptr->NthEntry(c++, key)->FloatVal());
    Bool eps(rptr->NthEntry(c++, key)->BoolVal());
    Value *colors(rptr->NthEntry(c++, key));
    String maptype(rptr->NthEntry(c++, key)->StringVal());

    // make the agent
    ret = new GTkPSPixelCanvas(global_store, filename, media, landscape,
			       aspect, dpi, zoom, eps, colors, maptype);
    if (!ret || !ret->IsValid()) {
      Value *err = 0;
      if (ret) {
	err = ret->GetError();
      }
      if (err) {
	global_store->Error(err);
      } else {
	global_store->Error("pspixelcanvas agent creation failed for "
			    "unknown reason/s");
      }
    } else {
      ret->SendCtor("newtk");
    }
  } catch (const AipsError &x) {
    String message = 
      String("pspixelcanvas agent creation failed for internal reason: ") +
      x.getMesg();
    global_store->Error(message.chars());
  } 
}

GTkPSPixelCanvas::~GTkPSPixelCanvas() {
  if (itsPSPixelCanvas) {
    delete itsPSPixelCanvas;
  }

  if (itsPSPCColorTable) {
    delete itsPSPCColorTable;
  }
  if (itsPSDriver) {
    delete itsPSDriver;
  }

}

int GTkPSPixelCanvas::IsValid() const {
  return itsIsValid;
}

PixelCanvas *GTkPSPixelCanvas::pixelCanvas() const {
  return itsPSPixelCanvas;
}

char *GTkPSPixelCanvas::status(Value *) {
  GlishRecord rec;

  PixelCanvasColorTable *pcctbl = itsPSPixelCanvas->pcctbl();

  // basic parameters
  rec.add("width", GlishArray(Int(itsPSPixelCanvas->width())));
  rec.add("height", GlishArray(Int(itsPSPixelCanvas->height())));
  rec.add("depth", GlishArray(Int(itsPSPixelCanvas->depth())));
  switch (pcctbl->colorModel()) {
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

  rec.add("colortablesize", GlishArray(Int(pcctbl->nColors())));
  rec.add("maxcolortablesize", GlishArray(Int(pcctbl->nColors() +
					      pcctbl->nSpareColors())));

  if (pcctbl->colorModel() == Display::Index) {
    ColormapDefinition cmapdef;
    rec.add("builtincolormaps", GlishArray(cmapdef.builtinColormapNames()));
    ColormapManager cmm = pcctbl->colormapManager();
    GlishRecord trec;
    Vector<String> names(cmm.nMaps());
    Vector<Int> sizes(cmm.nMaps());
    for (uInt i = 0; i < cmm.nMaps(); i++) {
      const Colormap *cmap = cmm.getMap(i);
      names(i) = cmap->name();
      sizes(i) = pcctbl->getColormapSize(cmap);
    }
    trec.add("names", names);
    trec.add("sizes", sizes);
    rec.add("registeredcolormaps", trec);
  } else {
  }

  Value *retval = new Value(*(rec.value()));
  if (ReplyPending()) {
    Reply(retval);
  } else {
    PostTkEvent("status", retval);
  }
  delete retval;
  return "";
}

}
