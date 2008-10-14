//# Foreign1ParameterAccessor.cc : Global functions for foreign Glish data structures
//# Copyright (C) 1998,2000
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
//#
//# $Id: Foreign1ParameterAccessor.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ForeignParameterAccessor.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Arrays/Vector.h>

namespace casa { //# NAMESPACE CASA - BEGIN

Bool ForeignParameterAccessorScalar(String &error,
				    GlishRecord &rec,
				    const GlishValue &valin,
				    const String &name) {
  GlishValue val = valin;
  if (val.type() != GlishValue::RECORD) {
    error +=  String("Parameter ") + name + " must be a record";
    return False;
  };

  if (val.attributeExists("shape")) {
    GlishArray sh(val.getAttribute("shape"));
    Vector<Int> shp;
    if (sh.get(shp, True)) {
      if (shp.nelements() > 0) {
	if (IPosition(shp).product() == 1) {
	  GlishRecord rval = val;
	  val = rval.get(0);
	  if (val.type() != GlishValue::RECORD) {
	    error +=  String("Parameter ") + name + " must be a record";
	    return False;
	  };
	} else {
	  error += String("Parameter ") + name + " has wrong shape";
	  return False;
	};
      };
    } else {
      error += String("Parameter ") + name + " has illegal shape";
      return False;
    };
  };

  rec = val;
  return True;
  
}

Bool ForeignParameterAccessorScalar(String &error,
				    String &rec,
				    const GlishValue &valin,
				    const String &name) {

  GlishArray val = valin;
  if (val.elementType() != GlishArray::STRING) {
    error +=  String("Parameter ") + name + " must be a string";
    return False;
  };

  if (val.nelements() != 1) {
    error += String("Parameter ") + name + " expected scalar string";
  };
  if (!val.get(rec)) {
    error += String("Parameter ") + name + " has illegal string";
    return False;
  };
  return True;
}

Bool ForeignParameterAccessorArray(String &error,
				   Bool &shapeExist,
				   IPosition &shap,
				   uInt &nelem,
				   const GlishValue &val,
				   const String &name) {
  Vector<Int> shp;
  shapeExist = True;
  if (val.attributeExists("shape")) {
    GlishArray sh(val.getAttribute("shape"));
    if (sh.get(shp, True)) {
      if (val.nelements() != (uInt)IPosition(shp).product()) {
	error += String("Parameter ") + name + " has non-conformant shape";
	return False;
      }
    } else {
      error += String("Parameter ") + name + " has illegal shape";
      return False;
    }
  } else {
    shapeExist = False;
    shp = Vector<Int>(1);
    if (val.type() == GlishValue::RECORD) {
       shp(0) = val.nelements();
       if (shp(0)>0) shp(0) = 1;
    } else {
      if (GlishArray(val).elementType() != GlishArray::STRING) {
	error += String("Parameter ") + name + " must be string or record";
	return False;
      };
      shp(0) = val.nelements();
    }
  }

  shap = IPosition(shp);
  nelem = shap.product();

  return True;
}

void  ForeignParameterAccessorAddShape(GlishRecord &val,
				       const IPosition &shap) {
  val.addAttribute("shape", GlishArray(shap.asVector()));
}

void  ForeignParameterAccessorAddId(GlishRecord &val,
				    const String &id) {
  if (!id.empty()) val.addAttribute("id", GlishArray(id));
}

} //# NAMESPACE CASA - END

