//# gDisplay.cc: infrastructure connection to glish for display library
//# Copyright (C) 1998,1999,2000,2001,2002
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
//# $Id: gDisplay.cc,v 19.5 2005/06/15 18:09:13 cvsmgr Exp $

#include <casa/aips.h>

#include <tasking/Glish/GlishValue.h>
#include "GTkPixelCanvas.h"
#include "GTkPSPixelCanvas.h"
#include "GTkPanelDisplay.h"
#include "GTkSlicePD.h"
#include "GTkMWCAnimator.h"
#include "GTkDisplayData.h"
#include "GTkDrawingDD.h"
#include "GTkColormap.h"
#include "GTkInformation.h"
#include "GTkAnnotations.h"

#include "Glish/glish.h"
#include "gDisplay.h"
// The following aips/*.h did produce errors. Should be fixed at some stage
//  #if 0
//  #include <casa/string.h>
//  #include <casa/stdlib.h>
//  #include <casa/iostream.h>
//  #else
//  #include <string.h>
//  #include <stdlib.h>
//  #include <iostream.h>
//  #endif

#include <casa/namespace.h>
extern "C" {
  int Gdisplay_Init(Tcl_Interp *);
  void GTkPixelCanvas_Create(ProxyStore *, Value *);
  int TclTkPixelCanvas_Init(Tcl_Interp *);
  void GTkDisplayData_Create(ProxyStore *, Value *);
  void GTkColormap_Create(ProxyStore *, Value *);
  void GTkPSPixelCanvas_Create(ProxyStore *, Value *);
  void GTkDrawingDD_Create(ProxyStore *, Value *);
  void GTkPanelDisplay_Create(ProxyStore *, Value *);
  void GTkInformation_Create(ProxyStore *, Value *);
  void GTkMWCAnimator_Create(ProxyStore *, Value *);
  void GTkSlicePD_Create(ProxyStore *, Value *);
  void GTkAnnotations_Create(ProxyStore *, Value *);
}

Value *casa::TkDisplayProc::operator()(Tcl_Interp *tcl, Tk_Window s, Value *arg) {
  char *val = 0;
  if (pixelcanvasproc && agent) {
    val = (((GTkPixelCanvas*)agent)->*pixelcanvasproc)(arg);
  } else if (displaydataproc && agent) {
    val = (((GTkDisplayData*)agent)->*displaydataproc)(arg);
  } else if (colormapproc && agent) {
    val = (((GTkColormap*)agent)->*colormapproc)(arg);
  } else if (pspixelcanvasproc && agent) {
    val = (((GTkPSPixelCanvas*)agent)->*pspixelcanvasproc)(arg);
  } else if (drawingddproc && agent) {
    val = (((GTkDrawingDD*)agent)->*drawingddproc)(arg);
  } else if (paneldisplayproc && agent) {
    val = (((GTkPanelDisplay*)agent)->*paneldisplayproc)(arg);
  } else if (informationproc && agent) {
    val = (((GTkInformation*)agent)->*informationproc)(arg);
  } else if (mwcanimatorproc && agent) {
    val = (((GTkMWCAnimator*)agent)->*mwcanimatorproc)(arg);
  } else if (slicepdproc && agent) {
    val = (((GTkSlicePD*)agent)->*slicepdproc)(arg);
  } else if (annotationsproc && agent) {
    val = (((GTkAnnotations*)agent)->*annotationsproc)(arg);
  } else {
    return TkProc::operator()(tcl, s, arg);
  }  

  if (val != (void*)TCL_ERROR) {
    if (convert && val) {
      return (*convert)(val);
    } else {
      return new Value(glish_true);
    }
  } else {
    return new Value(glish_false);
  }
}

extern "C" {
#if defined(__APPLE__)
  extern void (*late_binding_pgplot_driver_1)(int *, float *, int *, char *, 
					      int *, int);
  extern void (*late_binding_pgplot_driver_2)(int *, float *, int *, char *, 
					      int *, int);
  extern void (*late_binding_pgplot_driver_3)(int *, float *, int *, char *, 
					      int *, int);
  extern void wcdriv_(int *, float *, int *, char *, int *, int);
#else
  extern void (*display_library_pgplot_driver)(int *, float *, int *, char *, 
					       int *, int *, int);
  extern void wcdriv_(int *, float *, int *, char *,
		      int *, int *, int);
#endif
}

extern "C" int Gdisplay_Init(Tcl_Interp *tcl) {

  // (dk note 8/04): So... why can't you find any references to this
  // vital initialization routine anywhere in the project, either in
  // C++ or in glish?... (spoiler below). 
  
  // The name is created by a TclTk convention when gDisplay.so is dynamically
  // loaded (a tk_load invocation within gdisplay.g), Tcl/Tk drops the .so,
  // capitalizes the first letter, lowercases the rest, adds '_Init', and
  // then tries to call a routine with the resulting name.

  // (There should at least have been a comment about this, guys...).

  //
  // Setup the world canvas PGPLOT driver
  //
#if defined(__APPLE__)
  if ( ! late_binding_pgplot_driver_1 )
    late_binding_pgplot_driver_1 = wcdriv_;
  else if ( ! late_binding_pgplot_driver_2 )
    late_binding_pgplot_driver_2 = wcdriv_;
  else if ( ! late_binding_pgplot_driver_3 )
    late_binding_pgplot_driver_3 = wcdriv_;
  else
    fprintf( stderr, "gDisplay error: no free late-binding PGPLOT driver slots\n" );
#else
  display_library_pgplot_driver = wcdriv_;
#endif

  //
  // if PGPLOT_BUFFER is set to TRUE it causes grief, "unsetenv()"
  // isn't available everywhere, but this seems to work...
  //
  putenv("PGPLOT_BUFFER=");

  // prepare pixelcanvas agent
  TclTkPixelCanvas_Init(tcl);

  TkProxy::Register("pixelcanvas", GTkPixelCanvas_Create);

  // prepare other agents
  TkProxy::Register("displaydata", GTkDisplayData_Create);
  TkProxy::Register("colormap", GTkColormap_Create);
  TkProxy::Register("pspixelcanvas", GTkPSPixelCanvas_Create);
  TkProxy::Register("drawingdisplaydata", GTkDrawingDD_Create);
  TkProxy::Register("paneldisplay", GTkPanelDisplay_Create);
  TkProxy::Register("information", GTkInformation_Create);
  TkProxy::Register("mwcanimator", GTkMWCAnimator_Create);
  TkProxy::Register("slicepd", GTkSlicePD_Create);
  TkProxy::Register("annotations", GTkAnnotations_Create);

  return TCL_OK;
}




