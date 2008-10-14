//# X11PCCacheOpt.cc: display list optimisation implementation
//# Copyright (C) 1994,1995,1996,1997,1998,1999,2000,2001
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
//# $Id: X11PCCacheOpt.cc,v 19.5 2005/06/15 17:56:36 cvsmgr Exp $

#include <casa/aips.h>
#include <display/Display/X11PixelCanvas.h>
#include <display/Display/X11PCDLLine.h>
#include <display/Display/X11PCDLLines.h>
#include <display/Display/X11PCDLPoint.h>
#include <display/Display/X11PCDLPoints.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/Regex.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// 'a' X11PCDLClear.h
// 'b' X11PCDLClearRegion.h
// 'c' X11PCDLColoredLines.h
// 'd' X11PCDLColoredPoints.h
// 'e' X11PCDLDisable.h
// 'f' X11PCDLDisplayList.h
// 'g' X11PCDLEnable.h
// 'h' X11PCDLFilledRectangle.h
// 'i' X11PCDLGraphicsContext.h
// 'j' X11PCDLImage.h
// 'k' X11PCDLLine.h
// 'l' X11PCDLLines.h
// 'm' X11PCDLLoadIdentity.h
// 'n' X11PCDLPoint.h
// 'o' X11PCDLPoints.h
// 'p' X11PCDLPolyline.h
// 'q' X11PCDLPopMatrix.h
// 'r' X11PCDLPushMatrix.h
// 's' X11PCDLRoundedRectangle.h
// 't' X11PCDLSetClearColor.h
// 'u' X11PCDLSetClipWin.h
// 'v' X11PCDLText.h
// 'w' X11PCDLTranslate.h
// ' ' NULL
//
// Optimization patterns:
//
// 1: [kl][kl]+  ==> l
// 2: [no][no]+  ==> o
// 3: cc+   ==> c
// 4: dd+   ==> d 

Bool X11PixelCanvas::packDisplayList(String &str,
				     PtrBlock<X11PCDisplayListObject *> * l,
				     uInt count) {
  uInt d = 0;
  for (uInt s = 0; s < count; s++) {
    if ((*l)[s] != 0) {
      if (d != s) {
	(*l)[d] = (*l)[s]; (*l)[s] = 0;
	str[d] = str[s]; str[s] = '0'; 
      }
      d++;
    }
  }
  str.gsub(Regex("0+"), "");
  l->resize(d, True, True);
  return True;
}

Bool X11PixelCanvas::
applyConsecutiveLineOpt(String &s, PtrBlock<X11PCDisplayListObject *> *l) {
  // want to use the string to guide the optimization process
  uInt start = 0;
  uInt len = 0;
  uInt i = 0;
  uInt count = s.length();
  while (i < count) {
    // find start of run
    if (s[i] == 'k' || s[i] == 'l') {
      start = i++;
      len = 1;
      if (i < count) {
	while ((s[i] == 'k' || s[i] == 'l')) { 
	  i++; 
	  len++; 
	  if (i >= count) {
	    break;
	  }
	}
      }
      
      if (len > 1) {
	// count total number of lines
	uInt j;
	uInt nLines = 0;
	for (j = start; j < start+len; j++) {
	  X11PCDLLines * lines;
	  X11PCDLLine * line;
	  //PCAST(lines, X11PCDLLines, (*l)[j]);
	  //PCAST(line, X11PCDLLine, (*l)[j]);
	  lines = dynamic_cast<X11PCDLLines *>((*l)[j]);
	  line = dynamic_cast<X11PCDLLine *>((*l)[j]);
	  if (lines) {
	    nLines += lines->nLines();
	  } else if (line) {
	    nLines++;
	  } else {
	    throw(AipsError("applyConsecutiveLineOpt - "
			    "internal optimization error"));
	  }
	}
	
	// build single memory area for XSegments.  This memory
	// given over to the XllPCDLLines class.
	XSegment * lines = new XSegment[nLines];
	XSegment * ptr = lines;
	for (j = start; j < start+len; j++) {
	  X11PCDLLines * lines;
	  X11PCDLLine * line;
	  //PCAST(lines, X11PCDLLines, (*l)[j]);
	  //PCAST(line, X11PCDLLine, (*l)[j]);
	  lines = dynamic_cast<X11PCDLLines *>((*l)[j]);
	  line = dynamic_cast<X11PCDLLine *>((*l)[j]);
	  if (lines) {
	    memcpy(ptr, lines->lines(), lines->nLines()*sizeof(XSegment));
	    ptr += lines->nLines();
	  } else if (line) {
	    (*ptr).x1 = line->x1();
	    (*ptr).y1 = line->y1();
	    (*ptr).x2 = line->x2();
	    (*ptr).y2 = line->y2();
	    ptr++;
	  } else {
	    throw(AipsError("applyConsecutiveLineOpt - "
			    "internal optimization error"));
	  }
	  delete (*l)[j];
	  (*l)[j] = 0;
	  s[j] = ' ';
	}
	      
	// replace first cache entry
	(*l)[start] = new X11PCDLLines(lines, nLines);
	s[start] = (*l)[start]->optType();		  
      }
    } else {
      i++;
    }
  }
  packDisplayList(s, l, count);
  return True;
}

Bool X11PixelCanvas::
applyConsecutivePointOpt(String &s, PtrBlock<X11PCDisplayListObject *> *l) {
  // want to use the string to guide the optimization process
  uInt start = 0;
  uInt len = 0;
  uInt i = 0;
  uInt count = s.length();
  while (i < count) {
    // find start of run
    if (s[i] == 'n' || s[i] == 'o') {
      start = i++;
      len = 1;
      if (i < count) {
	while ((s[i] == 'n' || s[i] == 'o')) { 
	  i++; 
	  len++; 
	  if (i >= count) {
	    break;
	  }
	}
      }
      if (len > 1) {
	uInt j;
	// count total number of points
	uInt nPoints = 0;
	for (j = start; j < start+len; j++) {
	  X11PCDLPoints * points;
	  X11PCDLPoint * point;
	  //PCAST(points, X11PCDLPoints, (*l)[j]);
	  //PCAST(point, X11PCDLPoint, (*l)[j]);
	  points = dynamic_cast<X11PCDLPoints *>((*l)[j]);
	  point = dynamic_cast<X11PCDLPoint *>((*l)[j]);
	  if (points) {
	    nPoints += points->nPoints();
	  } else if (point) {
	    nPoints++;
	  } else {
	    throw(AipsError("applyConsecutivePointOpt - "
			    "internal optimization error"));
	  }
	}
	  
	// build single memory area for XPoints
	XPoint * points = new XPoint[nPoints];
	XPoint * ptr = points;
	for (j = start; j < start+len; j++) {
	  X11PCDLPoints * points;
	  X11PCDLPoint * point;
	  //PCAST(points, X11PCDLPoints, (*l)[j]);
	  //PCAST(point, X11PCDLPoint, (*l)[j]);
	  points = dynamic_cast<X11PCDLPoints *>((*l)[j]);
	  point = dynamic_cast<X11PCDLPoint *>((*l)[j]);
	  if (points) {
	    // CHECK THIS LINE!
	    memcpy(ptr, points->points(), points->nPoints()*sizeof(XPoint));
	    ptr += points->nPoints();
	  } else if (point) {
	    (*ptr).x = point->x();
	    (*ptr).y = point->y();
	    ptr++;
	  } else {
	    throw(AipsError("applyConsecutivePointOpt - "
			    "internal optimization error"));
	  }
	  delete (*l)[j];
	  (*l)[j] = 0;
	  s[j] = ' ';
	}
	
	// replace first cache entry with the optimized list
	(*l)[start] = new X11PCDLPoints(points, nPoints, CoordModeOrigin);
	s[start] = (*l)[start]->optType();		  
      }
    } else {
      i++;
    }
  }
  packDisplayList(s, l, count);
  return True;
}

// first implementation
// Consecutive point/points get mapped to single points call
// consecutive line/lines get mapped to single lines call
Bool X11PixelCanvas::
compactDisplayList(PtrBlock<X11PCDisplayListObject *> *l, uInt &count) {
  // generate a string representation of the display list
  String s = "";
  for (uInt i = 0; i < count; i++) {
    s += (*l)[i]->optType();
  }

  // use pattern-matching on the resultant list to guide the optimization
  Bool done = False;
  while (!done) {
    done = True;
    // test for patterns and apply optimizations

    // consecutive line/lines objects
    if (s.contains(Regex("[kl][kl]+"))) {
      if (applyConsecutiveLineOpt(s, l)) {
	// optimization was performed
	done = False;
      }
    }
      
    // consecutive point/points objects
    if (s.contains(Regex("[no][no]+"))) {
      if (applyConsecutivePointOpt(s, l)) {
	// optimization was performed
	done = False;
      }
    }

    // sort lines/points  [klno]+ ==> [no]*[kl]*
  }

  return True;
}


} //# NAMESPACE CASA - END

