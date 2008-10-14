//# PGPlot1dDataAttr.h: attribute storage class for PGPlot1d
//# Copyright (C) 1993,1994,1995,1999,2003
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
//# $Id: PGPlot1dDataAttr.h,v 19.4 2004/11/30 17:50:25 ddebonis Exp $

#ifndef GRAPHICS_PGPLOT1DDATAATTR_H
#define GRAPHICS_PGPLOT1DDATAATTR_H

//# Includes
#include <casa/aips.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//  <summary>
//  PGPlot1d helper class that stores attributes for a single data set
//  </summary>

//  <use visibility=>

//  <reviewed reveiwer="" date="" test="" demos=""

//  <etymology>
//  PGPlot1dDataAttr comes from PGPlot1d + Data + Attribute.  Attribute was
//  shortened for convenience.
//  </etymology>

//  <synopsis>
//  
//  PGPlot1dDataAttr is used as a container for attributes.  PGPlot1d keeps
//  track of its own attributes for each dataset, and this class facilitates
//  this list of attributes.
//
//  </synopsis>
//
//  <thrown>
//    No exceptions are thrown
//  </thrown>
//
//  <example>
//    No example given.
//  </example>
//

class PGPlot1dDataAttr
{
public:

  PGPlot1dDataAttr(Int id);

  enum DataStyle { DS_LINES, DS_POINTS, DS_LINESPOINTS, DS_HISTOGRAM };
  enum LineStyle { LS_NONE=0, LS_SOLID=1, LS_DASHED=2, LS_DOT_DASH=3,
    LS_DOTTED=4, LS_DASH_3DOT=5 };
  enum PointStyle { PS_NONE=32, PS_DOT=1, PS_BOX=0, PS_TRIANGLE=7, 
    PS_DIAMOND=11, PS_STAR=12, PS_VLINE=509,
    PS_HLINE=258, PS_CROSS=2, PS_CIRCLE=23,
    PS_SQUARE=6 };

  // public access to vars below
  void setLineStyle(LineStyle ls) { lineStyle_ = ls; setLineStyleCode(); }
  LineStyle lineStyle() const { return lineStyle_; }
  
  void setLineWidth(uInt width)    { lineWidth_ = width; }
  uInt lineWidth() const      { return lineWidth_;  }
  
  void setLineColor(uInt index)    { lineColor_ = index; }
  uInt lineColor() const      { return lineColor_;  }
  
  void setPointStyle(PointStyle ls) { pointStyle_ = ls; setPointStyleCode(); }
  PointStyle getPointStyle() const { return pointStyle_; }
  
  void setPointSize(uInt size)    { pointSize_ = (Float) size; }
  Float pointSize() const      
    { return (pointStyle_ == PS_DOT) ? pointSize_ : pointSize_/5.0;  }
  
  void setPointColor(uInt index)    { pointColor_ = index; }
  uInt pointColor() const      { return pointColor_;  }
  
  uInt lineStyleCode() const   { return lineStyleCode_; }
  uInt pointStyleCode() const  { return pointStyleCode_; }
  
  void setLineStyleCode() { lineStyleCode_ = (Int) lineStyle_; } 
  void setPointStyleCode() { pointStyleCode_ = (Int) pointStyle_; }
  
  Int id() const { return id_; }

  void setDataStyle(DataStyle ds) { dataStyle_ = ds; }
  DataStyle dataStyle() const { return dataStyle_; }

  void setIndex(Int ndx) { index_ = ndx; }
  Int index() const { return index_; }

private:

  // Holds style index for PGPlot
  Int index_;

  Int id_;

  // dataStyle is the manner in which the data is to be interpreted.
  DataStyle  dataStyle_;

  // lineStyle is the enum presented to interface which describes how
  // the line is to be drawn (dotted, dashed, etc)
  LineStyle  lineStyle_;
  // lineStyleCode_ is a code number used for PGPLOT's pgsls function.
  // The code values are assigned in the enumerator definition.
  Int lineStyleCode_;

  // This is the line width in units of 1/200 inch
  uInt lineWidth_;

  // The lineColor is an integer index to be sent to PGPlot's drawing
  uInt lineColor_;

  // PointStyle is the enum presented to the interface which describes
  // how points are to be drawn.
  PointStyle  pointStyle_;

  // PointStyleCode_ is a code number used for PGPLOT's pgsps function.
  // The code values are assigned in the enumerator definition.
  Int pointStyleCode_;

  // Point size in units of 1/200 inch
  Float pointSize_;

  // point color - an integer index
  uInt pointColor_;
};


} //# NAMESPACE CASA - END

#endif
