//# X11PCGraphicsContext.cc: context query/set for X11PixelCanvas
//# Copyright (C) 1994,1995,1996,1997,1998,1999,2000
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
//# $Id: X11PCGraphicsContext.cc,v 19.3 2005/06/15 17:56:43 cvsmgr Exp $

#include <display/Display/X11PixelCanvas.h>
#include <display/Display/X11PCDLGraphicsContext.h>

namespace casa { //# NAMESPACE CASA - BEGIN

void X11PixelCanvas::setDrawFunction(Display::DrawFunction drawFunction)
{
  XGCValues v;
  switch(drawFunction)
    {
    case Display::DFCopy: v.function = GXcopy; break;
    case Display::DFCopyInverted: v.function = GXcopyInverted; break;
    case Display::DFClear: v.function = GXclear; break;
    case Display::DFSet: v.function = GXset; break;
    case Display::DFInvert: v.function = GXinvert; break;
    case Display::DFNoop: v.function = GXnoop; break;
    case Display::DFXor: v.function = GXxor; break;
    case Display::DFEquiv: v.function = GXequiv; break;
    case Display::DFAnd: v.function = GXand; break;
    case Display::DFNand: v.function = GXnand; break;
    case Display::DFAndReverse: v.function = GXandReverse; break;
    case Display::DFAndInverted: v.function = GXandInverted; break;
    case Display::DFOr: v.function = GXor; break;
    case Display::DFNor: v.function = GXnor; break;
    case Display::DFOrReverse: v.function = GXorReverse; break;
    case Display::DFOrInverted: v.function = GXorInverted; break;
    }

  if (drawMode() == Display::Compile)
    appendToDisplayList(new X11PCDLGraphicsContext(v, GCFunction));
  else
    XChangeGC(display_, gc_, GCFunction, &v);
}

void X11PixelCanvas::setForeground(uLong color)
{
  XGCValues v;
  v.foreground = color;
  if (drawMode() == Display::Compile)
    appendToDisplayList(new X11PCDLGraphicsContext(v, GCForeground));
  else
    XChangeGC(display_, gc_, GCForeground, &v);
}

void X11PixelCanvas::setBackground(uLong color)
{
  XGCValues v;
  v.foreground = color;
  if (drawMode() == Display::Compile)
    appendToDisplayList(new X11PCDLGraphicsContext(v, GCBackground));
  else
    XChangeGC(display_, gc_, GCBackground, &v);
}

/*
void X11PixelCanvas::setLineWidth(uInt width)
{
  XGCValues v;
  v.line_width = width;
  // HACK - X doesn't draw connections properly for line width 1 -
  // otherwise it seems to be identical to line width 0, so let's
  // force that:
  if (v.line_width == 1) {
    v.line_width = 0;
  }
  if (drawMode() == Display::Compile)
    appendToDisplayList(new X11PCDLGraphicsContext(v, GCLineWidth));
  else
    XChangeGC(display_, gc_, GCLineWidth, &v);
}
*/

void X11PixelCanvas::setLineWidth(Float width)
{
  // round for X - it only takes integer line widths
  uInt iwidth = uInt(width + 0.5);
  XGCValues v;
  v.line_width = iwidth;
  // HACK - X doesn't draw connections properly for line width 1 -
  // otherwise it seems to be identical to line width 0, so let's
  // force that:
  if (v.line_width == 1) {
    v.line_width = 0;
  }
  if (drawMode() == Display::Compile)
    appendToDisplayList(new X11PCDLGraphicsContext(v, GCLineWidth));
  else
    XChangeGC(display_, gc_, GCLineWidth, &v);
}



void X11PixelCanvas::setLineStyle(Display::LineStyle style)
{
  XGCValues v;
  switch (style)
    {
    case Display::LSSolid:        v.line_style = LineSolid;      break;
    case Display::LSDashed:       v.line_style = LineOnOffDash;  break;
    case Display::LSDoubleDashed: v.line_style = LineDoubleDash; break;
    }
  if (drawMode() == Display::Compile)
    appendToDisplayList(new X11PCDLGraphicsContext(v, GCLineStyle));
  else
    XChangeGC(display_, gc_, GCLineStyle, &v);
}

void X11PixelCanvas::setCapStyle(Display::CapStyle style)
{
  XGCValues v;
  switch (style)
    {
    case Display::CSNotLast:    v.cap_style = CapNotLast;    break;
    case Display::CSButt:       v.cap_style = CapButt;       break;
    case Display::CSRound:      v.cap_style = CapRound;      break;
    case Display::CSProjecting: v.cap_style = CapProjecting; break;
    }
  if (drawMode() == Display::Compile)
    appendToDisplayList(new X11PCDLGraphicsContext(v, GCCapStyle));
  else
    XChangeGC(display_, gc_, GCCapStyle, &v);
}

void X11PixelCanvas::setJoinStyle(Display::JoinStyle style)
{
  XGCValues v;
  switch (style)
    {
    case Display::JSMiter:      v.join_style = JoinMiter;  break;
    case Display::JSRound:      v.join_style = JoinRound;  break;
    case Display::JSBevel:      v.join_style = JoinBevel;  break;
    }
  if (drawMode() == Display::Compile)
    appendToDisplayList(new X11PCDLGraphicsContext(v, GCJoinStyle));
  else
    XChangeGC(display_, gc_, GCJoinStyle, &v);
}

void X11PixelCanvas::setFillStyle(Display::FillStyle style)
{
  XGCValues v;
  switch (style)
    {
    case Display::FSSolid:          v.fill_style = FillSolid; break;
    case Display::FSTiled:          v.fill_style = FillTiled; break;
    case Display::FSStippled:       v.fill_style = FillStippled; break;
    case Display::FSOpaqueStippled: v.fill_style = FillOpaqueStippled; break;
    }
  if (drawMode() == Display::Compile)
    appendToDisplayList(new X11PCDLGraphicsContext(v, GCFillStyle));
  else
    XChangeGC(display_, gc_, GCFillStyle, &v);
}

void X11PixelCanvas::setFillRule(Display::FillRule rule)
{
  XGCValues v;
  switch (rule)
    {
    case Display::FREvenOdd:  v.fill_rule = EvenOddRule; break;
    case Display::FRWinding:  v.fill_rule = WindingRule; break;
    }
  if (drawMode() == Display::Compile)
    appendToDisplayList(new X11PCDLGraphicsContext(v, GCFillRule));
  else
    XChangeGC(display_, gc_, GCFillRule, &v);
}

void X11PixelCanvas::setArcMode(Display::ArcMode mode)
{
  XGCValues v;
  switch (mode)
    {
    case Display::AMChord:   v.arc_mode = ArcChord; break;
    case Display::AMPieSlice: v.arc_mode = ArcPieSlice; break;
    }
  if (drawMode() == Display::Compile)
    appendToDisplayList(new X11PCDLGraphicsContext(v, GCArcMode));
  else
    XChangeGC(display_, gc_, GCArcMode, &v);
}


Display::DrawFunction X11PixelCanvas::getDrawFunction() const
{
  XGCValues v;
  XGetGCValues(display_, gc_, GCFunction, &v);

  switch(v.function)
    {
    case GXcopy: return Display::DFCopy;
    case GXcopyInverted: return Display::DFCopyInverted;
    case GXclear: return Display::DFClear;
    case GXset: return Display::DFSet;
    case GXinvert: return Display::DFInvert;
    case GXnoop: return Display::DFNoop;
    case GXxor: return Display::DFXor;
    case GXequiv: return Display::DFEquiv;
    case GXand: return Display::DFAnd;
    case GXnand: return Display::DFNand;
    case GXandReverse: return Display::DFAndReverse;
    case GXandInverted: return Display::DFAndInverted;
    case GXor: return Display::DFOr;
    case GXnor: return Display::DFNor;
    case GXorReverse: return Display::DFOrReverse;
    case GXorInverted: return Display::DFOrInverted;
    }
  return Display::DFCopy;
}

uLong X11PixelCanvas::getForeground() const
{
  XGCValues v;
  XGetGCValues(display_, gc_, GCForeground, &v);
  return v.foreground;
}

uLong X11PixelCanvas::getBackground() const
{
  XGCValues v;
  XGetGCValues(display_, gc_, GCBackground, &v);
  return v.background;
}

/*
uInt X11PixelCanvas::getLineWidth() const
{
  XGCValues v;
  XGetGCValues(display_, gc_, GCLineWidth, &v);
  return v.line_width;
}
*/

Float X11PixelCanvas::getLineWidth() const
{
  XGCValues v;
  XGetGCValues(display_, gc_, GCLineWidth, &v);
  // this actually returns what is used, not the line width
  // that was set, which was Float...
  return Float(v.line_width);
}

Display::LineStyle X11PixelCanvas::getLineStyle() const
{
  XGCValues v;
  XGetGCValues(display_, gc_, GCLineStyle, &v);
  switch(v.line_style)
    {
    case LineSolid: return Display::LSSolid;
    case LineOnOffDash: return Display::LSDashed;
    case LineDoubleDash: return Display::LSDoubleDashed;
    }
  return Display::LSSolid;
}

Display::CapStyle X11PixelCanvas::getCapStyle() const
{
  XGCValues v;
  XGetGCValues(display_, gc_, GCCapStyle, &v);
  switch(v.cap_style)
    {
    case CapNotLast: return Display::CSNotLast;
    case CapButt: return Display::CSButt;
    case CapRound: return Display::CSRound;
    case CapProjecting: return Display::CSProjecting;
    }
  return Display::CSNotLast;
}

Display::JoinStyle X11PixelCanvas::getJoinStyle() const
{
  XGCValues v;
  XGetGCValues(display_, gc_, GCJoinStyle, &v);
  switch(v.join_style)
    {
    case JoinMiter: return Display::JSMiter;
    case JoinRound: return Display::JSRound;
    case JoinBevel: return Display::JSBevel;
    }
  return Display::JSMiter;
}

Display::FillStyle X11PixelCanvas::getFillStyle() const
{
  XGCValues v;
  XGetGCValues(display_, gc_, GCFillStyle, &v);
  switch(v.fill_style)
    {
    case FillSolid: return Display::FSSolid;
    case FillTiled: return Display::FSTiled;
    case FillStippled: return Display::FSStippled;
    case FillOpaqueStippled: return Display::FSOpaqueStippled;
    }
  return Display::FSSolid;
}

Display::FillRule X11PixelCanvas::getFillRule() const
{
  XGCValues v;
  XGetGCValues(display_, gc_, GCFillRule, &v);
  switch(v.fill_rule)
    {
    case EvenOddRule: return Display::FREvenOdd;
    case WindingRule: return Display::FRWinding;
    }
  return Display::FREvenOdd;
}

Display::ArcMode X11PixelCanvas::getArcMode() const
{
  XGCValues v;
  XGetGCValues(display_, gc_, GCArcMode, &v);
  switch(v.arc_mode)
    {
    case ArcChord: return Display::AMChord;
    case ArcPieSlice: return Display::AMPieSlice;
    }
  return Display::AMChord;
}



} //# NAMESPACE CASA - END

