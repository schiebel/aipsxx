//# aipsrc.h: DO for accessing aipsrc settings
//# Copyright (C) 1996,1997,1998,1999,2001
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
//# $Id: aipsrc.cc,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#include <../misc/aipsrc.h>
#include <casa/System/Aipsrc.h>
#include <casa/Arrays/Vector.h>
#include <casa/Quanta/Unit.h>
#include <tasking/Glish.h>
#include <casa/System/AipsrcValue.h>
#include <casa/System/AppInfo.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/Parameter.h>

#include <casa/namespace.h>
aipsrc::aipsrc() {;}

aipsrc::aipsrc(const aipsrc &other) : ApplicationObject(other) {;}

aipsrc &aipsrc::operator=(const aipsrc &) {
  return *this;
}

aipsrc::~aipsrc() {;}

Bool aipsrc::find(String &value, const String &keyword, Bool usehome) {
  if (usehome) {
    return Aipsrc::find(value, keyword);
  } else {
    return Aipsrc::findNoHome(value, keyword);
  };
}

void aipsrc::init() {
  Aipsrc::reRead();
}

// DO name
String aipsrc::className() const {
  return "aipsrc";
}

// Available methods
Vector<String> aipsrc::methods() const {
  Vector<String> names(15);
  names(0) = "find";			// find a value
  names(1) = "init";			// reread aipsrc values
  names(2) = "aipsroot";		// get AIPSROOT
  names(3) = "aipsarch";
  names(4) = "aipssite";
  names(5) = "aipshost";
  names(6) = "aipshome";		// get ~/aips++ or user.aipsdir
  names(7) = "tzoffset";		// local time offset in h
  names(8) = "findbool";		// find a bool value
  names(9) = "finddef";			// find with default
  names(10)= "findlist";		// find from list
  names(11)= "findxfloat";		// find a floating value with units
  names(12)= "findxint";		// find an integer
  names(13)= "findfloat";		// find a floating value
  names(14)= "findint";			// find an integer

  return names;
}

Vector<String> aipsrc::noTraceMethods() const {
  Vector<String> names(15);
  names(0) = "find";
  names(1) = "init";
  names(2) = "aipsroot";		// get AIPSROOT
  names(3) = "aipsarch";
  names(4) = "aipssite";
  names(5) = "aipshost";
  names(6) = "aipshome";
  names(7) = "tzoffset";
  names(8) = "findbool";		
  names(9) = "finddef";
  names(10)= "findlist";
  names(11)= "findxfloat";
  names(12)= "findxint";
  names(13)= "findfloat";
  names(14)= "findint";	

  return names;
}

MethodResult aipsrc::runMethod(uInt which, 
			       ParameterSet &inputRecord,
			       Bool runMethod) {
  static String returnvalString = "returnval";
  static String valueString = "value";
  static String keywordString = "keyword";
  static String usehomeString = "usehome";
  static String defString = "def";
  static String undefString = "undef";
  static String unresString = "unres";

  switch(which) {
    
    // find
  case 0: {
    Parameter<Bool> returnval(inputRecord, returnvalString,
			      ParameterSet::Out);
    Parameter<String> value(inputRecord, valueString,
			    ParameterSet::Out);
    Parameter<String> keyword(inputRecord, keywordString,
			      ParameterSet::In);
    Parameter<Bool> usehome(inputRecord, usehomeString,
			    ParameterSet::In);
    if (runMethod) 
      returnval() = find(value(), keyword(), usehome());
  }
  break;

  // init
  case 1: {
    if (runMethod) init();
  }
  break;

  // aipsroot
  case 2: {
    Parameter<String> returnval(inputRecord, returnvalString,
				ParameterSet::Out);
    if (runMethod) 
      returnval() = Aipsrc::aipsRoot();
  }
  break;
  
  // aipsarch
  case 3: {
    Parameter<String> returnval(inputRecord, returnvalString,
				ParameterSet::Out);
    if (runMethod) 
      returnval() = Aipsrc::aipsArch();
  }
  break;

  // aipssite
  case 4: {
    Parameter<String> returnval(inputRecord, returnvalString,
				ParameterSet::Out);
    if (runMethod) 
      returnval() = Aipsrc::aipsSite();
  }
  break;

  // aipshost
  case 5: {
    Parameter<String> returnval(inputRecord, returnvalString,
				ParameterSet::Out);
    if (runMethod) 
      returnval() = Aipsrc::aipsHost();
  }
  break;

  // aipshome
  case 6: {
    Parameter<String> returnval(inputRecord, returnvalString,
				ParameterSet::Out);
    if (runMethod) 
      returnval() = Aipsrc::aipsHome();
  }
  break;

  // tzoffset
  case 7: {
    Parameter<Double> returnval(inputRecord, returnvalString,
				ParameterSet::Out);
    if (runMethod) 
      returnval() = 24. * AppInfo::timeZone();
  }
  break;
    
    // findbool
  case 8: {
    Parameter<Bool> returnval(inputRecord, returnvalString,
			      ParameterSet::Out);
    Parameter<Bool> value(inputRecord, valueString,
			  ParameterSet::Out);
    Parameter<String> keyword(inputRecord, keywordString,
			      ParameterSet::In);
    Parameter<Bool> def(inputRecord, defString,
			ParameterSet::In);
    if (runMethod) 
      returnval() = AipsrcValue<Bool>::find(value(), keyword(), def());
  }
  break;

  // finddef
  case 9: {
    Parameter<Bool> returnval(inputRecord, returnvalString,
                              ParameterSet::Out);
    Parameter<String> value(inputRecord, valueString,
			    ParameterSet::Out);
    Parameter<String> keyword(inputRecord, keywordString,
                              ParameterSet::In);
    Parameter<String> def(inputRecord, defString,
			  ParameterSet::In);
    Parameter<Bool> usehome(inputRecord, usehomeString,
			    ParameterSet::In);
    if (runMethod) {
      if (usehome())
	returnval() = Aipsrc::find(value(), keyword(), def());
      else
	returnval() = Aipsrc::findNoHome(value(), keyword(), def());
    };
  }
  break;

  // findlist
  case 10: {
    Parameter<Bool> returnval(inputRecord, returnvalString,
			     ParameterSet::Out);
    Parameter<Int> value(inputRecord, valueString,
			 ParameterSet::Out);
    Parameter<String> keyword(inputRecord, keywordString,
                              ParameterSet::In);
    Parameter<String> def(inputRecord, defString,
			  ParameterSet::In);
    Parameter<GlishArray> unres(inputRecord, unresString,
				ParameterSet::In);
    if (runMethod) {
      Int nelem = unres().nelements();
      if (nelem > 0) {
	Vector<String> vlist(nelem);
	String x;
	for (Int j=0; j<nelem; j++) {
	  if (unres().get(x,j))
	    vlist(j) = x;
	  else
	    vlist(j) = " ";
	};
	uInt ix;
	if (Aipsrc::find(ix, keyword(), vlist, def())) {
	  value() = ix+1;
	  returnval() = True;
	} else {
	  value() = ix+1;
	  returnval() = False;
	};
      } else {
	returnval() = False;
      };
    };
  }
  break;

  // findxfloat
  case 11: {
    Parameter<Bool> returnval(inputRecord, returnvalString,
			     ParameterSet::Out);
    Parameter<Double> value(inputRecord, valueString,
			    ParameterSet::Out);
    Parameter<String> keyword(inputRecord, keywordString,
                              ParameterSet::In);
    Parameter<Double> def(inputRecord, defString,
			  ParameterSet::In);
    Parameter<String> undef(inputRecord, undefString,
			    ParameterSet::In);
    Parameter<String> unres(inputRecord, unresString,
			    ParameterSet::In);
    if (runMethod)
      returnval() = AipsrcValue<Double>::find(value(), keyword(), Unit(undef()),
					      Unit(unres()), def());
  }
  break;

  // findxint
  case 12: {
    Parameter<Bool> returnval(inputRecord, returnvalString,
			     ParameterSet::Out);
    Parameter<Int> value(inputRecord, valueString,
			    ParameterSet::Out);
    Parameter<String> keyword(inputRecord, keywordString,
                              ParameterSet::In);
    Parameter<Int> def(inputRecord, defString,
		       ParameterSet::In);
    Parameter<String> undef(inputRecord, undefString,
			    ParameterSet::In);
    Parameter<String> unres(inputRecord, unresString,
			    ParameterSet::In);
    if (runMethod)
      returnval() = AipsrcValue<Int>::find(value(), keyword(), Unit(undef()),
					   Unit(unres()), def());
  }
  break;

  // findfloat
  case 13: {
    Parameter<Bool> returnval(inputRecord, returnvalString,
			     ParameterSet::Out);
    Parameter<Double> value(inputRecord, valueString,
			    ParameterSet::Out);
    Parameter<String> keyword(inputRecord, keywordString,
                              ParameterSet::In);
    Parameter<Double> def(inputRecord, defString,
			  ParameterSet::In);
    if (runMethod)
      returnval() = AipsrcValue<Double>::find(value(), keyword(), def());
  }
  break;

  // findint
  case 14: {
    Parameter<Bool> returnval(inputRecord, returnvalString,
			     ParameterSet::Out);
    Parameter<Int> value(inputRecord, valueString,
			 ParameterSet::Out);
    Parameter<String> keyword(inputRecord, keywordString,
                              ParameterSet::In);
    Parameter<Int> def(inputRecord, defString,
		       ParameterSet::In);
    if (runMethod)
      returnval() = AipsrcValue<Int>::find(value(), keyword(), def());
  }
  break;

  default: {
    return error("Unknown method");
  }
  break;

  };
  return ok();
}
