//# LatticeAsContour.cc: Class to display lattice objects as contoured images
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
//# $Id: LatticeAsContour.cc,v 19.7 2005/06/15 18:00:40 cvsmgr Exp $

#include <casa/aips.h>
#include <casa/System/Aipsrc.h>
#include <casa/System/AipsrcValue.h>
#include <casa/Arrays/Array.h>
#include <casa/Containers/Record.h>
#include <lattices/Lattices/Lattice.h>
#include <images/Images/ImageInterface.h>
#include <display/DisplayDatas/LatticePADMContour.h>
#include <display/DisplayDatas/LatticeAsContour.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// >2d array-based ctor
template <class T>
LatticeAsContour<T>::LatticeAsContour(Array<T> *array, const uInt xAxis,
				      const uInt yAxis, const uInt mAxis,
				      const IPosition fixedPos) :
  LatticePADisplayData<T>(array, xAxis, yAxis, mAxis, fixedPos) {
  setupElements();
  setDefaultOptions();
}

// 2d array-based ctor
template <class T>
LatticeAsContour<T>::LatticeAsContour(Array<T> *array, const uInt xAxis,
				      const uInt yAxis) :
  LatticePADisplayData<T>(array, xAxis, yAxis) {
  setupElements();
  setDefaultOptions();
}

// >2d image-based ctor
template <class T>
LatticeAsContour<T>::LatticeAsContour(ImageInterface<T> *image,
				      const uInt xAxis, const uInt yAxis,
				      const uInt mAxis,
				      const IPosition fixedPos) :
  LatticePADisplayData<T>(image, xAxis, yAxis, mAxis, fixedPos) {
  setupElements();
  setDefaultOptions();
}

// 2d image-based ctor
template <class T>
LatticeAsContour<T>::LatticeAsContour(ImageInterface<T> *image,
				      const uInt xAxis, const uInt yAxis) :
  LatticePADisplayData<T>(image, xAxis, yAxis) {
  setupElements();
  setDefaultOptions();
}

template <class T>
LatticeAsContour<T>::~LatticeAsContour() {
  for (uInt i = 0; i < nelements(); i++) {
    delete ((LatticePADMContour<T> *)DDelement[i]);
  }
}

// Oke, here we setup the elements using LatticePADMContour
template <class T>
void LatticeAsContour<T>::setupElements() {

  for (uInt i=0; i<nelements(); i++) if(DDelement[i]!=0) {
    delete static_cast<LatticePADMContour<T>*>(DDelement[i]);
    DDelement[i]=0;  }
				// Delete old DMs, if any.

  IPosition fixedPos = fixedPosition();
  Vector<Int> dispAxes = displayAxes();
  if (nPixelAxes > 2) {
    setNumImages(dataShape()(dispAxes(2)));
    DDelement.resize(nelements());
    for (uInt index = 0; index < nelements(); index++) {
      fixedPos(dispAxes(2)) = index;
      DDelement[index] = (LatticePADisplayMethod<T> *)new
	LatticePADMContour<T>(dispAxes(0), dispAxes(1), dispAxes(2),
			      fixedPos, this);
    }
  } else {
    setNumImages(1);
    DDelement.resize(nelements());
    DDelement[0] = (LatticePADisplayMethod<T> *)new
      LatticePADMContour<T>(dispAxes(0), dispAxes(1), this);
  }
  PrincipalAxesDD::setupElements();
}

template <class T>
void LatticeAsContour<T>::setDefaultOptions() {
  LatticePADisplayData<T>::setDefaultOptions();
  Record rec, recOut;
  rec.define("resample", "bilinear");
  LatticePADisplayData<T>::setOptions(rec, recOut);
  getMinAndMax();
//
  itsLevels.resize(5);
  itsLevels(0) = 1.0; itsLevels(1) = 2.0; itsLevels(2) = 3.0;
  itsLevels(3) = 4.0; itsLevels(4) = 5.0;
  itsScale = 0.18 * datamax;
  itsType = "abs";
  AipsrcValue<Float>::find(itsLine,"display.contour.linewidth",0.5f);  
  itsDashNeg = True;
  itsDashPos = False;
  Aipsrc::find(itsColor,"display.contour.color","foreground");  
}

template <class T>
Bool LatticeAsContour<T>::setOptions(Record &rec, Record &recOut) {
  Bool ret = LatticePADisplayData<T>::setOptions(rec, recOut);

  Bool localchange = False;
  Bool error;

  localchange = (readOptionRecord(itsScale, error, rec, "scale") ||
		       localchange);
  localchange = (readOptionRecord(itsType, error, rec, "type") ||
		       localchange);
  localchange = (readOptionRecord(itsLine, error, rec, "line") ||
		       localchange);
  localchange = (readOptionRecord(itsDashNeg, error, rec, "dashneg") ||
		       localchange);
  localchange = (readOptionRecord(itsDashPos, error, rec, "dashpos") ||
		       localchange);
  localchange = (readOptionRecord(itsColor, error, rec, "color") ||
		       localchange);

  if (rec.isDefined("levels")) {
    DataType dtype = rec.dataType("levels");
    Vector<Float> newlevels;
//
    if ((dtype == TpArrayFloat) || (dtype == TpArrayDouble) ||
	(dtype == TpArrayInt) ||
	(dtype == TpFloat) || (dtype == TpDouble) || (dtype == TpInt)) {

       switch (dtype) {
      case TpFloat:
      case TpArrayFloat: {
	Vector<Float> temp;
	rec.get("levels", temp);
	newlevels.resize(temp.nelements());
	for (uInt i = 0; i < newlevels.nelements(); i++) {
	  newlevels(i) = temp(i);
	}
	break; }
      case TpDouble:
      case TpArrayDouble: {
	Vector<Double> temp;
	rec.get("levels", temp);
	newlevels.resize(temp.nelements());
	for (uInt i = 0; i < newlevels.nelements(); i++) {
	  newlevels(i) = temp(i);
	}
	break; }
      case TpInt:
      case TpArrayInt: {
	Vector<Int> temp;
	rec.get("levels", temp);
	newlevels.resize(temp.nelements());
	for (uInt i = 0; i < newlevels.nelements(); i++) {
	  newlevels(i) = temp(i);
	}
	break; }
      default:
	// not possible!
	break;
      }
//
      Bool diff = (newlevels.nelements() != itsLevels.nelements());
      if (!diff) {
	for (uInt i = 0; i < newlevels.nelements(); i++) {
	  diff = (newlevels(i) != itsLevels(i));
	  if (diff) break;
	}
      }
      if (diff) {
	itsLevels.resize(newlevels.nelements());
	for (uInt i = 0; i < newlevels.nelements(); i++) {
	  itsLevels(i) = newlevels(i);
	}
	ret = True;
      }
    } else {
        // error
    }
  }

  // must come last - this forces ret to be True or False:
  if (rec.isDefined("refresh") && (rec.dataType("refresh") == TpBool)) {
    rec.get("refresh", ret);
  }

  ret = (ret || localchange);
  
  return ret;
}

template <class T>
Record LatticeAsContour<T>::getOptions() {
  Record rec = LatticePADisplayData<T>::getOptions();

  Record levels;
  levels.define("dlformat", "levels");
  levels.define("listname", "Contour levels");
  levels.define("ptype", "array");
  Vector<Float> vlevels(5);
  vlevels(0) = 1.0; vlevels(1) = 2.0; vlevels(2) = 3.0;
  vlevels(3) = 4.0; vlevels(4) = 5.0;
  levels.define("default", vlevels);
  levels.define("value", itsLevels);
  levels.define("allowunset", False);
  rec.defineRecord("levels", levels);

  Record scale;
  scale.define("dlformat", "scale");
  scale.define("listname", "Contour scale factor");
  scale.define("ptype", "scalar");
  scale.define("default", 0.18);
  scale.define("value", itsScale);
  scale.define("allowunset", False);
  rec.defineRecord("scale", scale);

  Record type;
  type.define("dlformat", "type");
  type.define("listname", "Level type");
  type.define("ptype", "choice");
  Vector<String> vtype(2);
  vtype(0) = "frac"; 
  vtype(1) = "abs";
  type.define("popt", vtype);
  type.define("default", "abs");
  type.define("value", itsType);
  type.define("allowunset", False);
  rec.defineRecord("type", type);

  Record line;
  line.define("dlformat", "line");
  line.define("listname", "Line width");
  line.define("ptype", "floatrange");
  line.define("pmin", Float(0.0));
  line.define("pmax", Float(5.0));
  line.define("presolution", Float(0.1));
  line.define("default", Float(0.5));
  line.define("value", itsLine);
  line.define("allowunset", False);
  rec.defineRecord("line", line);

  Record dashNeg;
  dashNeg.define("dlformat", "dashneg");
  dashNeg.define("listname", "Dash negative contours?");
  dashNeg.define("ptype", "boolean");
  dashNeg.define("default", True);
  dashNeg.define("value", itsDashNeg);
  dashNeg.define("allowunset", False);
  rec.defineRecord("dashneg", dashNeg);

  Record dashPos;
  dashPos.define("dlformat", "dashpos");
  dashPos.define("listname", "Dash positive contours?");
  dashPos.define("ptype", "boolean");
  dashPos.define("default", False);
  dashPos.define("value", itsDashPos);
  dashPos.define("allowunset", False);
  rec.defineRecord("dashpos", dashPos);

  Record color;
  color.define("dlformat", "color");
  color.define("listname", "Line color");
  color.define("ptype", "userchoice");
  Vector<String> vcolor(8);
  vcolor(0) = "foreground"; vcolor(1) = "background";
  vcolor(2) = "black"; vcolor(3) = "white";
  vcolor(4) = "red"; vcolor(5) = "green";
  vcolor(6) = "blue"; vcolor(7) = "yellow";
  color.define("popt", vcolor);
  color.define("default", "foreground");
  color.define("value", itsColor);
  color.define("allowunset", False);
  rec.defineRecord("color", color);

  return rec;
}

} //# NAMESPACE CASA - END

