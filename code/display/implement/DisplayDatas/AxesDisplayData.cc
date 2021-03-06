//# AxesDisplayData.cc: axis labelling for registering on WorldCanvasHolders
//# Copyright (C) 1999,2000,2001,2002,2003,2004
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
//# $Id: AxesDisplayData.cc,v 19.7 2005/09/07 21:51:10 dking Exp $

#include <casa/aips.h>
#include <casa/Exceptions.h>
#include <casa/Arrays/Vector.h>
#include <casa/Containers/Record.h>
#include <display/DisplayEvents/WCRefreshEvent.h>
#include <display/Display/WorldCanvas.h>
#include <display/Display/WorldCanvasHolder.h>
#include <display/DisplayDatas/AxesDisplayData.h>
#include <display/DisplayDatas/AxesDisplayMethod.h>
#include <casa/System/AipsrcValue.h>


namespace casa { //# NAMESPACE CASA - BEGIN

AxesDisplayData::AxesDisplayData() :
  PassiveCachingDD() {

  Vector<String> vstring;

  // "Basic" context
  itsParamTitleText = new DParameterString("titletext", "Title", "", "", "",
		"Axis_Drawing_and_Labels");
  itsParamXAxisText = new DParameterString("xaxistext", "X-axis", "",
		"<axis name>", "<axis name>", "Axis_Drawing_and_Labels");
  itsParamYAxisText = new DParameterString("yaxistext", "Y-axis", "",
		"<axis name>", "<axis name>", "Axis_Drawing_and_Labels");
  vstring.resize(3);
  vstring(0) = "None";
  vstring(1) = "Tick marks";
  vstring(2) = "Full grid";
  itsParamXGridType = new DParameterChoice("xgridtype", "X grid type", "",
		vstring, vstring(1), vstring(1), "Axis_Drawing_and_Labels");
  itsParamYGridType = new DParameterChoice("ygridtype", "Y grid type", "",
		vstring, vstring(1), vstring(1), "Axis_Drawing_and_Labels");

  // "Colors" context
  itsParamTitleColor =  new DParameterColorChoice("titlecolor",
			"Title color", "", "Axis_Drawing_and_Labels");
  itsParamXAxisColor =  new DParameterColorChoice("xaxiscolor",
			"'X' axis color", "", "Axis_Drawing_and_Labels");
  itsParamYAxisColor = new DParameterColorChoice("yaxiscolor",
			"'Y' axis color", "", "Axis_Drawing_and_Labels");
  itsParamOutlineColor = new DParameterColorChoice("outlinecolor",
			"Outline color", "", "Axis_Drawing_and_Labels");

  // "Styles" context
  vstring.resize(4);
  vstring(0) = "normal";
  vstring(1) = "roman";
  vstring(2) = "italic";
  vstring(3) = "script";
  itsParamCharacterFont
    = new DParameterChoice("labelcharfont", "Character font",
			   "", vstring, vstring(0), vstring(0), 
			   "Axis_Drawing_and_Labels");


  Float defaultChrSz;
  AipsrcValue<Float>::find(defaultChrSz,"display.axislabels.charsize", 1.2f);
  itsParamCharacterSize
    = new DParameterRange<Float>("labelcharsize", "Character size",
				 "", 0.0, 4.0, 0.05,
				 defaultChrSz, defaultChrSz,
				 "Axis_Drawing_and_Labels");
  Float defaultLnWid;
  AipsrcValue<Float>::find(defaultLnWid,"display.axislabels.linewidth", 1.4f);
  itsParamLineWidth
    = new DParameterRange<Float>("labellinewidth", "Line width",
				 "", 0.0, 5.0, 0.10,
				 defaultLnWid, defaultLnWid,
				 "Axis_Drawing_and_Labels");
  
}

AxesDisplayData::~AxesDisplayData() {
  // "Basic" context
  if (itsParamTitleText) {
    delete itsParamTitleText;
  }
  if (itsParamXAxisText) {
    delete itsParamXAxisText;
  }
  if (itsParamYAxisText) {
    delete itsParamYAxisText;
  }
  if (itsParamXGridType) {
    delete itsParamXGridType;
  }
  if (itsParamYGridType) {
    delete itsParamYGridType;
  }
  // "Colors" context
  if (itsParamTitleColor) {
    delete itsParamTitleColor;
  }
  if (itsParamXAxisColor) {
    delete itsParamXAxisColor;
  }
  if (itsParamYAxisColor) {
    delete itsParamYAxisColor;
  }
  if (itsParamOutlineColor) {
    delete itsParamOutlineColor;
  }
  // "Styles" context
  if (itsParamCharacterFont) {
    delete itsParamCharacterFont;
  }
  if (itsParamCharacterSize) {
    delete itsParamCharacterSize;
  }
  if (itsParamLineWidth) {
    delete itsParamLineWidth;
  }
}

void AxesDisplayData::setDefaultOptions() {
  PassiveCachingDD::setDefaultOptions();
}

Bool AxesDisplayData::setOptions(Record &rec, Record &recOut) {
  Bool ret = PassiveCachingDD::setOptions(rec, recOut);

  Bool localchange = False;
  
  // "Basic" context
  localchange = (itsParamTitleText->fromRecord(rec) || localchange);
  localchange = (itsParamXAxisText->fromRecord(rec) || localchange);
  localchange = (itsParamYAxisText->fromRecord(rec) || localchange);
  localchange = (itsParamXGridType->fromRecord(rec) || localchange);
  localchange = (itsParamYGridType->fromRecord(rec) || localchange);
  // "Colors" context
  localchange = (itsParamTitleColor->fromRecord(rec) || localchange);
  localchange = (itsParamXAxisColor->fromRecord(rec) || localchange);
  localchange = (itsParamYAxisColor->fromRecord(rec) || localchange);
  localchange = (itsParamOutlineColor->fromRecord(rec) || localchange);
  // "Styles" context
  localchange = (itsParamCharacterFont->fromRecord(rec) || localchange);
  localchange = (itsParamCharacterSize->fromRecord(rec) || localchange);
  localchange = (itsParamLineWidth->fromRecord(rec) || localchange);

  return (ret || localchange);
}

Record AxesDisplayData::getOptions() {
  Record rec = PassiveCachingDD::getOptions(); 

  // "Basic" context
  itsParamTitleText->toRecord(rec);
  itsParamXAxisText->toRecord(rec);
  itsParamYAxisText->toRecord(rec);
  itsParamXGridType->toRecord(rec);
  itsParamYGridType->toRecord(rec);
  // "Colors" context
  itsParamTitleColor->toRecord(rec);
  itsParamXAxisColor->toRecord(rec);
  itsParamYAxisColor->toRecord(rec);
  itsParamOutlineColor->toRecord(rec);
  // "Styles" context
  itsParamCharacterFont->toRecord(rec);
  itsParamCharacterSize->toRecord(rec);
  itsParamLineWidth->toRecord(rec);
  return rec;
}

CachingDisplayMethod *AxesDisplayData::newDisplayMethod(
    WorldCanvas *worldCanvas,
    AttributeBuffer *wchAttributes,
    AttributeBuffer *ddAttributes,
    CachingDisplayData *dd) {
  return new AxesDisplayMethod(worldCanvas, wchAttributes, ddAttributes, dd);
}

AttributeBuffer AxesDisplayData::optionsAsAttributes() {
  AttributeBuffer buffer = PassiveCachingDD::optionsAsAttributes();
  // "Basic" context
  buffer.set(itsParamTitleText->name(), itsParamTitleText->value());
  buffer.set(itsParamXAxisText->name(), itsParamXAxisText->value());
  buffer.set(itsParamYAxisText->name(), itsParamYAxisText->value());
  buffer.set(itsParamXGridType->name(), itsParamXGridType->value());
  buffer.set(itsParamYGridType->name(), itsParamYGridType->value());
  // "Colors" context
  buffer.set(itsParamTitleColor->name(), itsParamTitleColor->value());
  buffer.set(itsParamXAxisColor->name(), itsParamXAxisColor->value());
  buffer.set(itsParamYAxisColor->name(), itsParamYAxisColor->value());
  buffer.set(itsParamOutlineColor->name(), itsParamOutlineColor->value());
  // "Styles" context
  buffer.set(itsParamCharacterFont->name(), itsParamCharacterFont->value());
  buffer.set(itsParamCharacterSize->name(), itsParamCharacterSize->value());
  buffer.set(itsParamLineWidth->name(), itsParamLineWidth->value());
  return buffer;
}

String AxesDisplayData::xAxisText(const WorldCanvas* wc) const {
  String txt = itsParamXAxisText->value();
  if (txt=="<axis name>") {
    txt = "";
    if (wc!=0) {
      const CoordinateSystem& wccs = wc->coordinateSystem();
      if (&wccs!=0) {
        txt = wccs.worldAxisNames()[0];
        String u = wccs.worldAxisUnits()[0];
        if (!u.empty() && u!=String("")) {
           txt = txt + "(" + u + ")";
        }
      }
    }
  }
  return txt; 
}

String AxesDisplayData::yAxisText(const WorldCanvas* wc) const {
  String txt = itsParamYAxisText->value();
  if (txt=="<axis name>") {
    txt = "";
    if (wc!=0) {
      const CoordinateSystem& wccs = wc->coordinateSystem();
      if (&wccs!=0) {
        txt = wccs.worldAxisNames()[1];
        String u = wccs.worldAxisUnits()[1];
        if (!u.empty() && u!=String("")) {
           txt = txt + "(" + u + ")";
        }
      }
    }
  }
  return txt;  
}



AxesDisplayData::AxesDisplayData(const AxesDisplayData &) {
}

void AxesDisplayData::operator=(const AxesDisplayData &) {
}




} //# NAMESPACE CASA - END

