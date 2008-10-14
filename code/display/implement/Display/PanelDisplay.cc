//# PanelDisplay.cc: Provision of panelled displays for data
//# Copyright (C) 2000,2001,2003
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
//# $Id: PanelDisplay.cc,v 19.8 2006/06/20 21:16:18 hye Exp $

#include <casa/aips.h>
#include <casa/Exceptions.h>
#include <casa/Containers/Record.h>
#include <display/Display/Attribute.h>
#include <display/Display/AttributeBuffer.h>
#include <display/Display/PixelCanvas.h>
#include <display/Display/WorldCanvas.h>
#include <display/Display/WorldCanvasHolder.h>
#include <display/Display/PanelDisplay.h>
#include <display/DisplayEvents/MultiWCTool.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Constructor.
PanelDisplay::PanelDisplay(PixelCanvas* pixelcanvas, 
			   const Int nx, const Int ny,
			   const Float xOrigin, const Float yOrigin, 
			   const Float xSize, const Float ySize,
			   const Float dx, const Float dy,
			   const PanelDisplay::FillOrder order) :
  MultiWCHolder(),
  myWCLI(0),
  itsPixelCanvas(pixelcanvas),
  itsGeometrySet(False),
  itsWCLI(0),
  itsWCHLI(0),
  itsMWCTools(static_cast<MultiWCTool* >(0), uInt(10)) {
  myWCLI = new ConstListIter<WorldCanvas* >(itsWCList);
  itsWCLI = new ListIter<WorldCanvas* >(itsWCList);
  itsWCHLI = new ListIter<WorldCanvasHolder* >(itsWCHList);
  itslpgm = 10;
  itsrpgm = 4;
  itstpgm = 4;
  itsbpgm = 7;
  setGeometry(nx, ny, xOrigin, yOrigin, xSize, ySize, dx, dy, order);
}

// Destructor.
PanelDisplay::~PanelDisplay() {
  unSetupGeometry();
  // cleanup Tools
  for (uInt i=0; i < itsMWCTools.ndefined(); i++) {
    String key =  itsMWCTools.getKey(i);
    removeTool(key);
  }
  itsMWCTools.clear();
  if (itsWCLI) {
    delete itsWCLI;
  }
  if (itsWCHLI) {
    delete itsWCHLI;
  }
  if (myWCLI) {
    delete myWCLI;
  }
}

void PanelDisplay::setAttributes(AttributeBuffer& at) {
  itsWCLI->toStart();
  while (!itsWCLI->atEnd()) {
    WorldCanvas* wc = itsWCLI->getRight();
    wc->setAttributes(at);
    (*itsWCLI)++;
  }
}

void PanelDisplay::getAttributeValue(const String& name, Int& newValue) const {
  itsWCLI->toStart();
  while (!itsWCLI->atEnd()) {
    WorldCanvas* wc = itsWCLI->getRight();
    wc->getAttributeValue(name, newValue);
    //get only the fisrt one - they should all be the same (for now)
    itsWCLI->toEnd();
  }
}

// Option handling functions.
void PanelDisplay::setDefaultOptions() {
  String attString;
  AttributeBuffer attBuffer;
  attString = "leftMarginSpacePG";
  attBuffer.add(attString, itslpgm);
  attString = "rightMarginSpacePG";
  attBuffer.add(attString, itsrpgm);
  attString = "bottomMarginSpacePG";
  attBuffer.add(attString, itsbpgm);
  attString = "topMarginSpacePG";
  attBuffer.add(attString, itstpgm);
  setAttributes(attBuffer);

}

Record PanelDisplay::getOptions() const {
  Record rec;
  String attString;
  Int temp;
  
  Record leftmarginspacepg;
  leftmarginspacepg.define("dlformat", "leftmarginspacepg");
  leftmarginspacepg.define("listname", "Left margin space (PG chars)");
  leftmarginspacepg.define("ptype", "intrange");
  leftmarginspacepg.define("pmin", 0);
  leftmarginspacepg.define("pmax", 20);
  leftmarginspacepg.define("default", itslpgm);
  attString = "leftMarginSpacePG";
  getAttributeValue(attString, temp);
  leftmarginspacepg.define("value", temp);
  leftmarginspacepg.define("allowunset", False);
  leftmarginspacepg.define("context", "Margins");
  rec.defineRecord("leftmarginspacepg", leftmarginspacepg);

  Record bottommarginspacepg;
  bottommarginspacepg.define("dlformat", "bottommarginspacepg");
  bottommarginspacepg.define("listname", "Bottom margin space (PG chars)");
  bottommarginspacepg.define("ptype", "intrange");
  bottommarginspacepg.define("pmin", 0);
  bottommarginspacepg.define("pmax", 20);
  bottommarginspacepg.define("default", itsbpgm);
  attString = "bottomMarginSpacePG";
  getAttributeValue(attString, temp);
  bottommarginspacepg.define("value", temp);
  bottommarginspacepg.define("allowunset", False);
  bottommarginspacepg.define("context", "Margins");
  rec.defineRecord("bottommarginspacepg", bottommarginspacepg);

  Record rightmarginspacepg;
  rightmarginspacepg.define("dlformat", "rightmarginspacepg");
  rightmarginspacepg.define("listname", "Right margin space (PG chars)");
  rightmarginspacepg.define("ptype", "intrange");
  rightmarginspacepg.define("pmin", 0);
  rightmarginspacepg.define("pmax", 20);
  rightmarginspacepg.define("default", itsrpgm);
  attString = "rightMarginSpacePG";
  getAttributeValue(attString, temp);
  rightmarginspacepg.define("value", temp);
  rightmarginspacepg.define("allowunset", False);
  rightmarginspacepg.define("context", "Margins");
  rec.defineRecord("rightmarginspacepg", rightmarginspacepg);

  Record topmarginspacepg;
  topmarginspacepg.define("dlformat", "topmarginspacepg");
  topmarginspacepg.define("listname", "Top margin space (PG chars)");
  topmarginspacepg.define("ptype", "intrange");
  topmarginspacepg.define("pmin", 0);
  topmarginspacepg.define("pmax", 20);
  topmarginspacepg.define("default", itstpgm);
  attString = "topMarginSpacePG";
  getAttributeValue(attString, temp);
  topmarginspacepg.define("value", temp);
  topmarginspacepg.define("allowunset", False);
  topmarginspacepg.define("context", "Margins");
  rec.defineRecord("topmarginspacepg", topmarginspacepg);

  Record nxpanels;
  nxpanels.define("dlformat", "nxpanels");
  nxpanels.define("listname", "Number of panels in x");
  nxpanels.define("ptype", "intrange");
  nxpanels.define("pmin", Int(1));
  nxpanels.define("pmax", Int(5));
  nxpanels.define("default", Int(1));
  nxpanels.define("value", itsNX);
  nxpanels.define("allowunset", False);
  nxpanels.define("context", "Number_of_panels");
  rec.defineRecord("nxpanels", nxpanels);
  
  Record nypanels;
  nypanels.define("dlformat", "nypanels");
  nypanels.define("listname", "Number of panels in y");
  nypanels.define("ptype", "intrange");
  nypanels.define("pmin", Int(1));
  nypanels.define("pmax", Int(5));
  nypanels.define("default", Int(1));
  nypanels.define("value", itsNY);
  nypanels.define("allowunset", False);
  nypanels.define("context", "Number_of_panels");
  rec.defineRecord("nypanels", nypanels);

  Record xspacing;
  xspacing.define("dlformat", "xspacing");
  xspacing.define("listname", "X-Spacing of Panels");
  xspacing.define("ptype", "floatrange");
  xspacing.define("pmin", 0.0);
  xspacing.define("pmax", 0.49);
  xspacing.define("default", Float(0.0));
  xspacing.define("value", itsDX);
  xspacing.define("allowunset", False);
  xspacing.define("context", "Number_of_panels");
  rec.defineRecord("xspacing", xspacing);

  Record yspacing;
  yspacing.define("dlformat", "yspacing");
  yspacing.define("listname", "Y-Spacing of Panels");
  yspacing.define("ptype", "floatrange");
  yspacing.define("pmin", 0.0);
  yspacing.define("pmax", 0.49);
  yspacing.define("default", Float(0.0));
  yspacing.define("value", itsDY);
  yspacing.define("allowunset", False);
  yspacing.define("context", "Number_of_panels");
  rec.defineRecord("yspacing", yspacing);

  return rec;

}

Bool PanelDisplay::setOptions(const Record& rec, Record& ) {
  Bool ret = False, localchange = False;
  Bool error;

  String attString;
  AttributeBuffer attBuffer;

  Bool geometrychange = False;
  geometrychange = geometrychange || 
    readOptionRecord(itsNX, error, rec,  "nxpanels");
  geometrychange = geometrychange || 
    readOptionRecord(itsNY, error, rec,  "nypanels");
  geometrychange = geometrychange || 
    readOptionRecord(itsDX, error, rec,  "xspacing");
  geometrychange = geometrychange || 
    readOptionRecord(itsDY, error, rec,  "yspacing");

  if (geometrychange) {
    setGeometry(itsNX,itsNY,itsXOrigin,itsYOrigin,
		itsXSize,itsYSize,itsDX,itsDY,itsOrder);
    attString = "leftMarginSpacePG";
    attBuffer.add(attString, itslpgm);
    attString = "rightMarginSpacePG";
    attBuffer.add(attString, itsrpgm);
    attString = "bottomMarginSpacePG";
    attBuffer.add(attString, itsbpgm);
    attString = "topMarginSpacePG";
    attBuffer.add(attString, itstpgm);
    setAttributes(attBuffer);    
    localchange = True;
  } else {
  // set distributed options
    attString = "leftMarginSpacePG";
    localchange = readOptionRecord(itslpgm, error, rec, "leftmarginspacepg") 
      || localchange;
    attBuffer.add(attString, itslpgm);
    
    attString = "rightMarginSpacePG";
    localchange = readOptionRecord(itsrpgm, error, rec, "rightmarginspacepg")
      || localchange;
    attBuffer.add(attString, itsrpgm);
    
    attString = "bottomMarginSpacePG";
    localchange = readOptionRecord(itsbpgm, error, rec, "bottommarginspacepg")
      || localchange;
    attBuffer.add(attString, itsbpgm);
    
    attString = "topMarginSpacePG";
    localchange = readOptionRecord(itstpgm, error, rec, "topmarginspacepg")
      || localchange;
    attBuffer.add(attString, itstpgm);
    setAttributes(attBuffer);
  }
  ret = ret || localchange;
  return ret;
}

void PanelDisplay::getGeometry(Int& nx, Int& ny, Float& xOrigin, 
			       Float& yOrigin, Float& xSize, Float& ySize,
			       Float& dx, Float& dy, 
			       PanelDisplay::FillOrder& order) const {
  nx = itsNX;
  ny = itsNY;
  xOrigin = itsXOrigin;
  yOrigin = itsYOrigin;
  xSize = itsXSize;
  ySize = itsYSize;
  dx = itsDX;
  dy = itsDY;
  order = itsOrder;
}

void PanelDisplay::getGeometry(RecordInterface& rec) const {
  rec.define("nxpanels", itsNX);
  rec.define("nypanels", itsNY);
  rec.define("xorigin", itsXOrigin);
  rec.define("yorigin", itsYOrigin);
  rec.define("xsize", itsXSize);
  rec.define("ysize", itsYSize);
  rec.define("xspacing", itsDX);
  rec.define("yspacing", itsDY);
}


void PanelDisplay::setGeometry(const RecordInterface& rec) {
  if (rec.isDefined("nxpanels") && rec.isDefined("nypanels") &&
      rec.isDefined("xorigin") && rec.isDefined("yorigin") &&
      rec.isDefined("xsize") && rec.isDefined("ysize") &&
      rec.isDefined("xspacing") && rec.isDefined("yspacing")) {

    Int nx,ny;
    Float xOrigin,yOrigin, xSize,ySize, dx,dy;

    rec.get("nxpanels", nx);     rec.get("nypanels", ny);
    rec.get("xorigin", xOrigin); rec.get("yorigin", yOrigin);
    rec.get("xsize", xSize);     rec.get("ysize", ySize);
    rec.get("xspacing", dx);     rec.get("yspacing", dy);

    setGeometry(nx,ny, xOrigin,yOrigin, xSize,ySize, dx,dy, itsOrder);

  } else {
    throw(AipsError("In PanelDisplay, the geometry description record "
		    "was missing one or more fields"));
  }
}


void PanelDisplay::setGeometry(const Int nx, const Int ny,
			       const Float xOrigin, const Float yOrigin,
			       const Float xSize, const Float ySize,
			       const Float dx, const Float dy,
			       const PanelDisplay::FillOrder order) {
  if ((nx < 1) || (ny < 1)) {
    throw(AipsError("In PanelDisplay, the number of panels in each direction "
		    "must be at least one"));
  }
  itsNX = nx;
  itsNY = ny;
  itsXOrigin = xOrigin;
  itsYOrigin = yOrigin;
  itsXSize = xSize;
  itsYSize = ySize;
  itsDX = dx;
  itsDY = dy;
  itsOrder = order;

  // Clear our part of the PC.

  Int pw=pixelCanvas()->width(), ph=pixelCanvas()->height();
  itsPixelCanvas->setDrawBuffer(Display::FrontAndBackBuffer);
  itsPixelCanvas->clear( Int(itsXOrigin*pw +.5),
			 Int(itsYOrigin*ph +.5),
			 Int((itsXOrigin+itsXSize)*pw +.5) - 1,
			 Int((itsYOrigin+itsYSize)*ph +.5) - 1 );
	// (above are the (new) screen pixel extents of the PD on the PC).
  itsPixelCanvas->setDrawBuffer(Display::BackBuffer);

  //hold();

  updateTools(True,False);	// (remove them temporarily).


  Float xPanelSize = (itsXSize - static_cast<Float>(itsNX - 1) * itsDX) /
    static_cast<Float>(itsNX);
  Float yPanelSize = (itsYSize - static_cast<Float>(itsNY - 1) * itsDY) /
    static_cast<Float>(itsNY);

  itsWCHLI->toStart();
  itsWCLI->toStart();

  // Prepare to synchornize zoom windows and CS master of any new WCs with
  // existing ones.

  AttributeBuffer zoomwindow;
  
  WorldCanvas* wc0 = 0;
  WorldCanvasHolder* wch0 = 0;
  
  Bool oldWCexists=(!itsWCLI->atEnd());
  if(oldWCexists) {
  
    wc0 = itsWCLI->getRight();
    wch0 = itsWCHLI->getRight();

    Vector<Double> zoomBlc(2), zoomTrc(2);
    zoomBlc[0]=wc0->linXMin(); zoomBlc[1]=wc0->linYMin();
    zoomTrc[0]=wc0->linXMax(); zoomTrc[1]=wc0->linYMax();

    zoomwindow.add("manualZoomBlc", zoomBlc);
    zoomwindow.add("manualZoomTrc", zoomTrc);
  }


  Float y = itsYOrigin + itsYSize - yPanelSize;
  for (Int i = 0; i < itsNY; i++) {
    Float x = itsXOrigin;
    for (Int j = 0; j < itsNX; j++) {

      if(itsWCLI->atEnd()) {

        // out of WC[H]s--create new ones

        WorldCanvas* wc = new WorldCanvas(itsPixelCanvas,
					  x,y, xPanelSize,yPanelSize);
        WorldCanvasHolder* wch = new WorldCanvasHolder(wc);
        
	itsWCLI->addRight(wc);
        itsWCHLI->addRight(wch);
	
	// (To be fixed): _two identical WCH lists_ are maintained
	// (an oversight, no doubt).
	// The statement above adds to the one on this level; the
	// statement below adds to the base-level (MWCH) list. (dk 12/04)
	
        addWCHolder(*wch);	// (this one loads the DDs too).
	
	if(oldWCexists) {
	  wch->syncCSmaster(wch0);
		// Use same CS master dd on new WC[H]s as on the other ones.
		// This also makes sure the new CS master (if any) sets
		// initial WC coordinate state.
		
	  wc->setAttributes(zoomwindow);
		// The new WC will duplicate the zoom window of
		// the others on its first refresh.
	}
      } else {

        // just recycle / reposition old ones.

        WorldCanvas* wc = itsWCLI->getRight();
	wc->setWorldCanvasPosition(x,y, xPanelSize,yPanelSize);
      }

      (*itsWCLI)++;
      (*itsWCHLI)++;
      x += xPanelSize + itsDX;
    }
    y -= yPanelSize + itsDY;
  }

  // remove any leftover WC{H}s

  while (!itsWCHLI->atEnd()) {
    WorldCanvasHolder* wch = itsWCHLI->getRight();
    removeWCHolder(*wch);
    itsWCHLI->removeRight();
    delete wch;wch=0;
  }
  while (!itsWCLI->atEnd()) {
    WorldCanvas* wc = itsWCLI->getRight();
    itsWCLI->removeRight();
    delete wc;wc=0;
  }

  updateTools(False,True);	// (restore mouse tools).
  setDefaultOptions();
  itsGeometrySet = True;

  // can't refresh before realize is called, this would be called in
  // the 'initialize' process of X -> commented out.
  //itsPixelCanvas->refresh();

  //release();
}


void PanelDisplay::unSetupGeometry() {
  if (!itsGeometrySet) {
    return;
  }
  updateTools(True,False);
  // 1. remove the WorldCanvasHolders
  itsWCHLI->toStart();
  while (!itsWCHLI->atEnd()) {
    WorldCanvasHolder* wch = itsWCHLI->getRight();
    removeWCHolder(*wch);
    itsWCHLI->removeRight();
    delete wch;wch=0;
    // don't increment iterator - removeRight() has that effect!
  }
  // 2. delete WorldCanvases.
  itsWCLI->toStart();
  while (!itsWCLI->atEnd()) {
    WorldCanvas* wc = itsWCLI->getRight();
    itsWCLI->removeRight();
    delete wc;wc=0;
    // don't increment iterator - removeRight() has that effect!
  }
  itsGeometrySet = False;
  // we have remove WorldCanvases from the PixelCanvas, so we should
  // refresh the entire PixelCanvas.

  //itsPixelCanvas->refresh();
}

WorldCanvasHolder* PanelDisplay::wcHolder(WorldCanvas* wcanvas) const {
  itsWCHLI->toStart();
  while (!itsWCHLI->atEnd()) {
    WorldCanvasHolder* wch = itsWCHLI->getRight();
    if (wch->worldCanvas() == wcanvas) {
      return wch;
    }
    (*itsWCHLI)++;
  }
  return 0;
}
  
Bool PanelDisplay::isCSmaster(const DisplayData *dd) const {
  // Is the specified DisplayData the one in charge of coordinate
  // state of the Panel's WCs?
  ConstListIter<WorldCanvasHolder*> wchs(itsWCHList);
  return !wchs.atEnd() && wchs.getRight()->isCSmaster(dd);
}
  

Bool PanelDisplay::hasTools() {
  if (itsMWCTools.ndefined() > 0) {
    return True;
  } else {
    return False;
  }
}


void PanelDisplay::updateTools(Bool remove, Bool add) {
  if (itsMWCTools.ndefined() == 0) {
    return;
  }
  for (uInt i=0; i < itsMWCTools.ndefined(); i++) {
    MultiWCTool* tool = itsMWCTools.getVal(i);
    if (remove) {
      tool->removeWorldCanvases(this);
    }
    if (add) {
      tool->addWorldCanvases(this);
    }
  }
}

void PanelDisplay::disableTools() {
   for (uInt i=0; i < itsMWCTools.ndefined(); i++) {
    MultiWCTool* tool = itsMWCTools.getVal(i);
    tool->disable();
   }
}

void PanelDisplay::enableTools() {
   for (uInt i=0; i < itsMWCTools.ndefined(); i++) {
    MultiWCTool* tool = itsMWCTools.getVal(i);
    tool->enable();
   }
}

void PanelDisplay::enableTool(const String& toolname) {
  for (uInt i=0; i < itsMWCTools.ndefined(); i++) {
    if (itsMWCTools.getKey(i) == toolname) {
      itsMWCTools.getVal(i)->enable();
      break;
    }
  }
}

void PanelDisplay::disableTool(const String& toolname) {
  for (uInt i=0; i < itsMWCTools.ndefined(); i++) {
    if (itsMWCTools.getKey(i) == toolname) {
      itsMWCTools.getVal(i)->disable();
      break;
    }
  }
}

void PanelDisplay::setToolKey(const String& toolname,
			      const Display::KeySym& keysym) {
  for (uInt i=0; i < itsMWCTools.ndefined(); i++) {
    if (itsMWCTools.getKey(i) == toolname) {
      itsMWCTools.getVal(i)->setKey(keysym);
      break;
    }
  }
}

void PanelDisplay::addTool(const String& key, MultiWCTool* value) {
  if (!itsMWCTools.isDefined(key)) {
    itsMWCTools.define(key, value);
    value->addWorldCanvases(this);
  }
}

void PanelDisplay::removeTool(const String& key) {
  MultiWCTool* tool = *itsMWCTools.isDefined(key);
  if (tool) {
    itsMWCTools(key)->removeWorldCanvases(this);
    delete tool;
  }
}

} //# NAMESPACE CASA - END

