//# QtMouseToolState.cc: constants and [global] mouse-button state
//# for the qtviewer 'mouse-tools' used by its display panel[s].
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
//# $Id: QtMouseToolState.cc,v 1.1 2006/08/11 22:18:39 dking Exp $


#include <display/QtViewer/QtMouseToolState.qo.h>

namespace casa { //# NAMESPACE CASA - BEGIN

namespace QtMouseToolNames {

  const String ZOOM = "zoom";
  const String PAN = "pan";
  const String SHIFTSLOPE = "shiftslope";
  const String BRIGHTCONTRAST = "brightcontrast";
  const String POSITION =  "position";
  const String RECTANGLE = "rectangle";
  const String POLYGON = "polygon";
  const String POLYLINE = "polyline";
  const String MULTICROSSHAIR = "multicrosshair";
  const String ANNOTATIONS = "annotations";

  
  //# the final elements stand for "none" (or "invalid");
  
  const String tools[] = { ZOOM, PAN, SHIFTSLOPE, BRIGHTCONTRAST, POSITION,
    RECTANGLE, POLYGON, POLYLINE, MULTICROSSHAIR, ANNOTATIONS, "" };

  const String longnames[] = { "Zooming", "Panning",
    "Colormap fiddling - shift/slope",
    "Colormap fiddling - brightness/contrast",
    "Positioning", "Rectangle drawing", "Polygon drawing",
    "Polyline drawing", "Multipanel crosshair", "Annotations",  "" };
    
  const String iconnames[] = { "magnifyb", "handb", "arrowcrossb",
   "brightcontrastb", "crosshairb", "rectregionb", "polyregionb",
   "polylineb",  "mpcrosshairb", "dontuseb",  "" };
    
  const String helptexts[] = {
    "Use the assigned mouse button to drag out a rectangle."
    "\nUsehandles to resize."
    "\nDouble click inside rectangle-> zoom in"
    "\nDouble click outside rectangle -> zoom out"
    "\n<Esc> to cancel",
     
    "Drag tool using the assigned mouse button.",
     
    "Drag tool using the assigned mouse button.",
     
    "Drag tool using the assigned mouse button.",
     
    "Click assigned mouse button to drop cursor at that position."
    "\nDouble click inside to execute."
    "\n<Esc> to cancel",
     
    "Use the assigned mouse button to drag out a rectangle."
    "\nUsehandles to resize.\nDouble click inside to execute."
    "\n<Esc> to cancel",
     
    "Place polygon points by clicking the assigned mouse button."
    "\nDoubleclick on last point to finish polygon."
    "\nUse handles to resize."
    "\nDouble click insideto execute."
    "\n<Esc> to cancel",
     
    "Place polyline points by clicking the assigned mouse button."
    "\nDoubleclick on last point to finish the polyline."
    "\nUse handles to rearrange points."
    "\n<Esc> to cancel",
       
    "Select a shape to draw and then click / drag on screen to place it."
    "\nSelect \"more\" to show more options"
    "\n<Esc> to cancel",

         
     ""  };

}  // namespace QtMouseToolNames




Int QtMouseToolState::mousebtns[] =  { 1, 0, 2, 0, 0, 3, 0, 0, 0, 0,  0 };


void QtMouseToolState::chgMouseBtn(String tool, Int mousebtn) {
  
  // Request reassignment of a given mouse button to a tool.
  // NB: this is where guis, etc. should request a button change, so that
  // all stay on same page (not directly to tool or displaypanel, e.g.).
  
  using namespace QtMouseToolNames;
	// Constants (nTools, tool names, etc.) used by Qt mouse tools.
  
  if(mousebtn<0 || mousebtn>3) return;	// (Invalid mouse button).
  
  Int ti = toolIndex(tool);
  if(ti==nTools) return;		// (Invalid tool).
  
  Int oldti = 0;	// tool formerly assigned to requested mouse btn.
  while(oldti<nTools && mousebtn!=mousebtns[oldti]) oldti++;
  if(ti==oldti) return;			// (already where we want to be).
  
  //Int oldbtn = mousebtns[ti];	// button requested tool used to have.
  
  mousebtns[ti] = mousebtn;			// Make the change,
  emit mouseBtnChg(tool, mousebtn);		// broadcast it.
  
  if(oldti!=nTools) {		// (Should be true, if using 'hye style').
    
    //mousebtns[oldti] = oldbtn;
    // Swap with tool that used to have the desired button ('hye style').
    
    mousebtns[oldti] = 0;	// (older glish viewer style: just unset it).
    
    emit mouseBtnChg(toolName(oldti), mousebtns[oldti]);  }  }
				// broadcast that change too.
    


void QtMouseToolState::emitBtns() {
  // Request signalling of the current mouse button setting for every
  // type of tool.  Call this if you want to assure that all objects are
  // up-to-date on mouse button settings.
  
  using namespace QtMouseToolNames;
	// Constants (nTools, tool names, etc.) used by Qt mouse tools
  
  for(Int i=0; i<nTools; i++) emit mouseBtnChg(tools[i], mousebtns[i]);  }

  
  

} //# NAMESPACE CASA - END
