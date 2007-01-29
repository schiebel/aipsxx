//# gDisplay.h: infrastructure connection to glish for display library
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
//# $Id: gDisplay.h,v 19.3 2005/06/15 18:09:13 cvsmgr Exp $

#ifndef TRIALDISPLAY_GDISPLAY_H
#define TRIALDISPLAY_GDISPLAY_H

//# glish includes:
#include <Glish/glishtk.h>

//# forward so we don't have to include AIPS++!
namespace casa {
   class GTkPixelCanvas;
   class GTkDisplayData;
   class GTkColormap;
   class GTkPSPixelCanvas;
   class GTkDrawingDD;
   class GTkPanelDisplay;
   class GTkInformation;
   class GTkMWCAnimator;
   class GTkSlicePD;
   class GTkAnnotations;

class TkDisplayProc : public TkProc {
  
 public:
  
  TkDisplayProc(const char *c, TkEventProc p, TkStrToValProc cvt = 0) : 
    TkProc(c,p,cvt), 
    pixelcanvasproc(0),
    displaydataproc(0),
    colormapproc(0),
    pspixelcanvasproc(0),
    drawingddproc(0),
    paneldisplayproc(0),
    informationproc(0),
    mwcanimatorproc(0),
    slicepdproc(0),
    annotationsproc(0) 
  { }
  
  TkDisplayProc(GTkPixelCanvas *f, char *(GTkPixelCanvas::*p)(Value*), 
		TkStrToValProc cvt = 0) :
    TkProc((TkProxy *)f,cvt), 
    pixelcanvasproc(p),
    displaydataproc(0),
    colormapproc(0),
    pspixelcanvasproc(0),
    drawingddproc(0),
    paneldisplayproc(0),
    informationproc(0),
    mwcanimatorproc(0),
    slicepdproc(0),
    annotationsproc(0)   
  { }
  
  TkDisplayProc(GTkDisplayData *f, char *(GTkDisplayData::*p)(Value*), 
		TkStrToValProc cvt = 0) :
    TkProc((TkProxy *)f,cvt), 
    pixelcanvasproc(0),
    displaydataproc(p),
    colormapproc(0),
    pspixelcanvasproc(0),
    drawingddproc(0),
    paneldisplayproc(0),
    informationproc(0),
    mwcanimatorproc(0),
    slicepdproc(0),
    annotationsproc(0)   
  { }
  
  TkDisplayProc(GTkColormap *f, char *(GTkColormap::*p)(Value*), 
		TkStrToValProc cvt = 0) :
    TkProc((TkProxy *)f,cvt), 
    pixelcanvasproc(0),
    displaydataproc(0),
    colormapproc(p),
    pspixelcanvasproc(0),
    drawingddproc(0),
    paneldisplayproc(0),
    informationproc(0),
    mwcanimatorproc(0),
    slicepdproc(0),
    annotationsproc(0)   
  { }
  
  
  TkDisplayProc(GTkPSPixelCanvas *f, char *(GTkPSPixelCanvas::*p)(Value*),
		TkStrToValProc cvt = 0) :
    TkProc((TkProxy *)f,cvt),
    pixelcanvasproc(0),
    displaydataproc(0),
    colormapproc(0),
    pspixelcanvasproc(p),
    drawingddproc(0),
    paneldisplayproc(0),
    informationproc(0),
    mwcanimatorproc(0),
    slicepdproc(0),
    annotationsproc(0)   
  { }
  
  TkDisplayProc(GTkDrawingDD *f, char *(GTkDrawingDD::*p)(Value*),
		TkStrToValProc cvt = 0) :
    TkProc((TkProxy *)f,cvt),
    pixelcanvasproc(0),
    displaydataproc(0),
    colormapproc(0),
    pspixelcanvasproc(0),
    drawingddproc(p),
    paneldisplayproc(0),
    informationproc(0),
    mwcanimatorproc(0),
    slicepdproc(0),
    annotationsproc(0)   
  { }
  
  TkDisplayProc(GTkPanelDisplay *f, char *(GTkPanelDisplay::*p)(Value *),
		TkStrToValProc cvt = 0) :
    TkProc((TkProxy *)f,cvt),
    pixelcanvasproc(0),
    displaydataproc(0),
    colormapproc(0),
    pspixelcanvasproc(0),
    drawingddproc(0),
    paneldisplayproc(p),
    informationproc(0),
    mwcanimatorproc(0),
    slicepdproc(0),
    annotationsproc(0)   
  { }
  
  TkDisplayProc(GTkInformation *f, char *(GTkInformation::*p)(Value *),
		TkStrToValProc cvt = 0) :
    TkProc((TkProxy *)f,cvt),
    pixelcanvasproc(0),
    displaydataproc(0),
    colormapproc(0),
    pspixelcanvasproc(0),
    drawingddproc(0),
    paneldisplayproc(0),
    informationproc(p),
    mwcanimatorproc(0),
    slicepdproc(0),
    annotationsproc(0) 
  { }
  
  TkDisplayProc(GTkMWCAnimator *f, char *(GTkMWCAnimator::*p)(Value *),
		TkStrToValProc cvt = 0) :
    TkProc((TkProxy *)f,cvt),
    pixelcanvasproc(0),
    displaydataproc(0),
    colormapproc(0),
    pspixelcanvasproc(0),
    drawingddproc(0),
    paneldisplayproc(0),
    informationproc(0),
    mwcanimatorproc(p),
    slicepdproc(0),
    annotationsproc(0) 
  { }
  
  TkDisplayProc(GTkSlicePD *f, char *(GTkSlicePD::*p)(Value *),
		TkStrToValProc cvt = 0) :
    TkProc((TkProxy *)f,cvt),
    pixelcanvasproc(0),
    displaydataproc(0),
    colormapproc(0),
    pspixelcanvasproc(0),
    drawingddproc(0),
    paneldisplayproc(0),
    informationproc(0),
    mwcanimatorproc(0),
    slicepdproc(p),
    annotationsproc(0) 
  { }
  
  TkDisplayProc(GTkAnnotations *f, char *(GTkAnnotations::*p)(Value *),
		TkStrToValProc cvt = 0) :
    TkProc((TkProxy *)f,cvt),
    pixelcanvasproc(0),
    displaydataproc(0),
    colormapproc(0),
    pspixelcanvasproc(0),
    drawingddproc(0),
    paneldisplayproc(0),
    informationproc(0),
    mwcanimatorproc(0),
    slicepdproc(0),
    annotationsproc(p) { }
  
  
  virtual Value *operator()(Tcl_Interp*, Tk_Window s, Value *arg);
  
protected:
  
  char *(GTkPixelCanvas::*pixelcanvasproc)(Value*);
  char *(GTkDisplayData::*displaydataproc)(Value*);
  char *(GTkColormap::*colormapproc)(Value*);
  char *(GTkPSPixelCanvas::*pspixelcanvasproc)(Value*);
  char *(GTkDrawingDD::*drawingddproc)(Value*);
  char *(GTkPanelDisplay::*paneldisplayproc)(Value*);
  char *(GTkInformation::*informationproc)(Value*);
  char *(GTkMWCAnimator::*mwcanimatorproc)(Value*);
  char *(GTkSlicePD::*slicepdproc)(Value*);
  char *(GTkAnnotations::*annotationsproc)(Value*);
};

}

#endif




