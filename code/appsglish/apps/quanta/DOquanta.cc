//# DOquanta.cc:  This class gives Glish to Quantity connection
//# Copyright (C) 1998,2000,2001,2002,2003
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
//# $Id: DOquanta.cc,v 19.7 2005/11/07 21:17:04 wyoung Exp $

//# Includes

#include <appsglish/quanta/DOquanta.h>
#include <casa/Quanta/MVAngle.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Quanta/MVFrequency.h>
#include <casa/Quanta/MVDoppler.h>
#include <casa/Utilities/MUString.h>
#include <casa/Quanta.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/Complex.h>
#include <casa/Quanta/QLogical.h>
#include <casa/Quanta/QuantumHolder.h>
#include <casa/BasicSL/Constants.h>
#include <tasking/Glish.h>
#include <casa/Logging.h>
#include <casa/Exceptions/Error.h>
#include <casa/sstream.h>

#include <casa/namespace.h>
// Constructors
quanta::quanta() {;}

quanta::quanta(const quanta &other) : ApplicationObject(other) {;}

quanta &quanta::operator=(const quanta &other) {
  if (False && !&other) {}; // stop warning 
  return *this;
}

// Destructor
quanta::~quanta() {;}

// Make list of known units
void quanta::mapInsert(GlishRecord &out,
		       const String &type, 
		       const map<String, UnitName> &mp) {
  ostringstream osn;
  osn <<  mp.size();
  out.add(String("== ") + type + String(" =="),
	  String("== ") + type +
	  String(" ==== ") + String(osn) + String(" ===="));
  for (map<String, UnitName>::const_iterator i=mp.begin();
       i != mp.end(); ++i) {
    ostringstream oss;
    oss << i->second;
    String str = oss.str();
    out.add(type + "_" + i->first, str);
  };
}

GlishRecord quanta::mapit(const String &tp) {
  const uInt N = 5;
  GlishRecord tmp;
  String str;
  static String types[N] = {
    "all", "Prefix", "SI", "Custom", "User"};

  uInt p = MUString::minimaxNC(tp, N, types);

  if (p >= N) {
    tmp.add(String("Error"), String("Unknown mapping requested"));
  } else {
    if (p == 0 || p == 1)
      quanta::mapInsert(tmp, types[1], UnitMap::givePref());
    if (p == 0 || p == 2)
      quanta::mapInsert(tmp, types[2], UnitMap::giveSI());
    if (p == 0 || p == 3)
      quanta::mapInsert(tmp, types[3], UnitMap::giveCust());
    if (p == 0 || p == 4)
      quanta::mapInsert(tmp, types[4], UnitMap::giveUser());
  };
  return tmp;
}

// Get a constant
Quantity quanta::constants(const String &in) {
  const uInt N = 20;
  String str;
  static String types[N] = {
    "pi", "ee", "c", "G", "h", "HI", "R", "NA", "e", "mp",
    "mp_me", "mu0", "epsilon0", "k", "F", "me", "re", "a0",
    "R0", "k2"
  };
  static Quantity res[N] = {
    Quantity(C::pi,""),	Quantity(C::e,""),
    QC::c, QC::G, QC::h, QC::HI, QC::R, QC::NA, QC::e, QC::mp,
    QC::mp_me, QC::mu0, QC::epsilon0, QC::k, QC::F, QC::me, QC::re, QC::a0,
    QC::R0, QC::k2
  };
  uInt p = MUString::minimaxNC(in, N, types);
  if (p >= N ) return (Quantity(0.,""));
  return res[p];
}

Int quanta::makeFormT(const GlishArray &in) {
  // Next series of lines because get(Array<String>) did not work
  Int nelem = in.nelements();
  Vector<String> ot(nelem);
  String x;
  for (Int j=0; j<nelem; j++) {
    if (in.get(x,j)) ot(j) = x;
    else ot(j) = "NONE";
  };
  Int res = MVTime::giveMe("time");
  for (uInt i = 0; i<ot.nelements(); i++) res |= MVTime::giveMe(ot(i));
  return res;
}

Int quanta::makeFormA(const GlishArray &in) {
  Int nelem = in.nelements();
  Vector<String> ot(nelem);
  String x;
  for (Int j=0; j<nelem; j++) {
    if (in.get(x,j)) ot(j) = x;
    else ot(j) = "NONE";
  };
  Int res = MVAngle::giveMe("angle");
  for (uInt i = 0; i<ot.nelements(); i++) res |= MVAngle::giveMe(ot(i));
  return res;
}

// DO name
String quanta::className() const {
  return "quanta";
}

// Available methods
Vector<String> quanta::methods() const {
  Vector<String> tmp(24);
  tmp(0) = "define";			// define a new unit
  tmp(1) = "unit";			// generate a quantity
  tmp(2) = "map";			// list known units
  tmp(3) = "angle";			// output in angle format
  tmp(4) = "time";			// output in time format
  tmp(5) = "fits";			// define FITS related units
  tmp(6) = "norm";			// normalise angle
  tmp(7) = "compare";			// compare to units for conformance
  tmp(8) = "check";			// check if correct units
  tmp(9) = "pow";			// raise to power
  tmp(10)= "totime";			// convert angle to time
  tmp(11)= "toangle";			// convert time to angle
  tmp(12)= "constants";			// get a constant
  tmp(13)= "qfunc1";			// one argument quantity function
  tmp(14)= "qfunc2";			// two argument quantity function
  tmp(15)= "qvfunc1";			// one argument q<vector> function
  tmp(16)= "unitv";			// unit(vector)
  tmp(17)= "qvvfunc2";			// two argument q<vector> function
  tmp(18)= "quant";			// quant
  tmp(19)= "dopcv";			// doppler value conversion
  tmp(20)= "frqcv";                     // freq converter
  tmp(21)= "tfreq";                     // table freq formatter
  tmp(22)= "splitdate";			// split time into many fields
  tmp(23)= "qlogical";			// quantity compare functions
  return tmp;
}

// Untraced methods
Vector<String> quanta::noTraceMethods() const {
  return methods();
}

// Execute methods
MethodResult quanta::runMethod(uInt which,
			     ParameterSet &parameters,
			     Bool runMethod) {

  static String returnvalName = "returnval";
  static String valName  = "val";
  static String argName  = "arg";
  static String arg2Name  = "arg2";
  static String formName = "form";
  static String form2Name= "form2";

  switch (which) {

  // define
  case 0: {
    Parameter<String> arg(parameters, argName,
			   ParameterSet::In);
    Parameter<Quantity> val(parameters, valName,
			    ParameterSet::In);
    if (runMethod)
      UnitMap::putUser(arg(), UnitVal(val().getValue(),
				       val().getUnit()),
		       "Glish defined");
  }
  break;

  // unit  
  case 1: {
    Parameter<Double> val(parameters, valName,
			  ParameterSet::In);
    Parameter<String> arg(parameters, argName,
			  ParameterSet::In);
    Parameter<Quantity> returnval(parameters, returnvalName,
				  ParameterSet::Out);
    if (runMethod) returnval() = Quantity(val(), arg());
  }
  break;

  // map
  case 2: {
    Parameter<String> val(parameters, valName,
			  ParameterSet::In);
    Parameter<GlishRecord> returnval(parameters, returnvalName,
  				     ParameterSet::Out);
    if (runMethod) returnval() = quanta::mapit(val());
  }
  break;

  // angle
  case 3: {
    Parameter<Quantum<Vector<Double> > > val(parameters, valName,
					     ParameterSet::In);
    Parameter<Vector<Int> > arg2(parameters, arg2Name,
				 ParameterSet::In);
    Parameter<GlishArray> fmt(parameters, formName,
			      ParameterSet::In);
    Parameter<Int> arg(parameters, argName,
		       ParameterSet::In);
    Parameter<Bool> form2(parameters, form2Name,
			  ParameterSet::In);
    Parameter<Vector<String> > returnval(parameters, returnvalName,
					 ParameterSet::Out);
    if (runMethod) {
      Int fm = quanta::makeFormA(fmt());
      Int nelem = val().getValue().nelements();
      if (nelem > 0) {
	Int nrow = arg2()(arg2().nelements()-1);
	Int ncol = nelem/nrow;
	returnval().resize(nrow);
	Int k = 0;
	for (Int i=0; i<nrow; i++) {
	  ostringstream oss;
	  if (ncol > 1 && form2()) oss << '[';
	  for (Int j=0; j<ncol; j++) {
	    if (j>0) {
	      if (form2()) oss << ", ";
	      else oss << " ";
	    };
	    oss << MVAngle(Quantity(val().getValue()(k),
				    val().getFullUnit())).
	      string(fm, arg());
	    k++;
	  };
	  if (ncol > 1 && form2()) oss << ']';
	  returnval()(i) = oss.str();
	};
      } else {
	returnval().resize(0);
      };
    };
  }
  break;

  // time
  case 4: {
    Parameter<Quantum<Vector<Double> > > val(parameters, valName,
					     ParameterSet::In);
    Parameter<Vector<Int> > arg2(parameters, arg2Name,
				 ParameterSet::In);
    Parameter<GlishArray> fmt(parameters, formName,
			      ParameterSet::In);
    Parameter<Int> arg(parameters, argName,
		       ParameterSet::In);
    Parameter<Bool> form2(parameters, form2Name,
			  ParameterSet::In);
    Parameter<Vector<String> > returnval(parameters, returnvalName,
					 ParameterSet::Out);
    if (runMethod) {
      Int fm = quanta::makeFormT(fmt());
      Int nelem = val().getValue().nelements();
      if (nelem > 0) {
	Int nrow = arg2()(arg2().nelements()-1);
	Int ncol = nelem/nrow;
	returnval().resize(nrow);
	Int k = 0;
	for (Int i=0; i<nrow; i++) {
	  ostringstream oss;
	  if (ncol > 1 && form2()) oss << '[';
	  for (Int j=0; j<ncol; j++) {
	    if (j>0) {
	      if (form2()) oss << ", ";
	      else oss << " ";
	    };
	    oss << MVTime(Quantity(val().getValue()(k),
				   val().getFullUnit())).
	      string(fm, arg());
	    k++;
	  };
	  if (ncol > 1 && form2()) oss << ']';
	  returnval()(i) = oss.str();
	};
      } else {
	returnval().resize(0);
      };
    };
  }
  break;

  // fits
  case 5: {
    if (runMethod)
      UnitMap::addFITS();
  }
  break;

  // norm
  case 6: {
    Parameter<Quantity> val(parameters, valName,
			    ParameterSet::In);
    Parameter<Double> arg(parameters, argName,
			  ParameterSet::In);
    Parameter<Quantity> returnval(parameters, returnvalName,
				  ParameterSet::Out);
    if (runMethod) {
      returnval() = Quantity(MVAngle(val())(arg()).degree(), "deg");
    };
  }
  break;

  // compare
  case 7: {
    Parameter<Quantity> val(parameters, valName,
				  ParameterSet::In);
    Parameter<Quantity> arg(parameters, argName,
				  ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName,
				  ParameterSet::Out);
    if (runMethod) {
      returnval() = (val().getFullUnit().getValue() ==
	arg().getFullUnit().getValue());
    };
  }
  break;

  // check
  case 8: {
    Parameter<String> arg(parameters, argName,
				  ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName,
				  ParameterSet::Out);
    if (runMethod) {
      Quantity res;
      if (Quantity::read(res, arg())) {
	returnval() = True;
      } else {
	returnval() = False;
      };
    };
  }
  break;

  // pow
  case 9: {
    Parameter<Quantity> val(parameters, valName,
				  ParameterSet::In);
    Parameter<Int> arg(parameters, argName,
				  ParameterSet::In);
    Parameter<Quantity> returnval(parameters, returnvalName,
				  ParameterSet::Out);
    if (runMethod)
      returnval() = pow(val(),arg());
  }
  break;

  // totime
  case 10: {
    Parameter<Quantity> val(parameters, valName,
			    ParameterSet::In);
    Parameter<Quantity> returnval(parameters, returnvalName,
				  ParameterSet::Out);
    if (runMethod) {
      if (val().check(UnitVal::TIME)) {
	returnval() = val();
      } else {
	returnval() = MVTime(val()).get();
      };
    };
  }
  break;

  // toangle
  case 11: {
    Parameter<Quantity> val(parameters, valName,
			    ParameterSet::In);
    Parameter<Quantity> returnval(parameters, returnvalName,
				  ParameterSet::Out);
    if (runMethod) {
      if (val().check(UnitVal::ANGLE)) {
	returnval() = val();
      } else {
	returnval() = MVAngle(val()).get();
      };
    };
  }
  break;

  // constants
  case 12: {
    Parameter<String> val(parameters, valName,
			  ParameterSet::In);
    Parameter<Quantity> returnval(parameters, returnvalName,
				  ParameterSet::Out);
    if (runMethod)
      returnval() = quanta::constants(val());
  }
  break;

  // qfunc1
  case 13: {
    Parameter<Quantity> val(parameters, valName,
			    ParameterSet::In);
    Parameter<Int>	form(parameters, formName, 
			     ParameterSet::In);
    Parameter<Quantity> returnval(parameters, returnvalName,
				  ParameterSet::Out);
    if (runMethod) {
      switch (form()) {
	// sin
      case 0:
	returnval() = sin(val());
	break;
	// cos
      case 1:
	returnval() = cos(val());
	break;
	// tan
      case 2:
	returnval() = tan(val());
 	break;
	// asin
      case 3:
	returnval() = asin(val());
 	break;
	// acos
      case 4:
	returnval() = acos(val());
 	break;
	// atan
      case 5:
	returnval() = atan(val());
 	break;
	// abs
      case 6:
	returnval() = abs(val());
 	break;
	// ceil
      case 7:
	returnval() = ceil(val());
 	break;
	// floor
      case 8:
	returnval() = floor(val());
 	break;
 	// canon
      case 9:
	returnval() = val().get();
	break;
	// log
      case 10:
	returnval() = log(val());
	break;
	// log10
      case 11:
	returnval() = log10(val());
	break;
	// exp
      case 12:
	returnval() = exp(val());
	break;
	// sqrt
      case 13:
	returnval() = sqrt(val());
	break;
      default:
	return error("Unknown one argument Quantity function");
	break;
      }
    };
  }
  break;

  // qfunc2
  case 14: {
    Parameter<Quantity> val(parameters, valName,
                            ParameterSet::In);
    Parameter<Quantity> arg(parameters, argName,
			    ParameterSet::In);
    Parameter<Int>	form(parameters, formName, 
			     ParameterSet::In);
    Parameter<Quantity> returnval(parameters, returnvalName,
				  ParameterSet::Out);
    if (runMethod) {
      switch (form()) {
	// atan2
      case 0:
	returnval() = atan2(val(), arg());
	break;
	// mul
      case 1:
	returnval() = val() *  arg();
	break;
	// div
      case 2:
	returnval() = val() /  arg();
	break;
	// sub
      case 3:
	returnval() = val() -  arg();
	break;
	// add
      case 4:
	returnval() = val() +  arg();
	break;
	// convert
      case 5:
	returnval() = arg().getUnit().empty() ? val().get() : val().get(arg());
	break;
      default:
	return error("Unknown two argument Quantity function");
	break;
      }
    };
  }
  break;

  // qvfunc1
  case 15: {
    Parameter<Quantum<Vector<Double> > > val(parameters, valName,
					     ParameterSet::In);
    Parameter<Int> form(parameters, formName, 
			ParameterSet::In);
    Parameter<Quantum<Vector<Double> > > returnval(parameters, returnvalName,
						   ParameterSet::Out);
    if (runMethod) {
      switch (form()) {
	// sin
      case 0:
	returnval() = sin(val());
	break;
	// cos
      case 1:
	returnval() = cos(val());
	break;
	// tan
      case 2:
	returnval() = tan(val());
 	break;
	// asin
      case 3:
	returnval() = asin(val());
 	break;
	// acos
      case 4:
	returnval() = acos(val());
 	break;
	// atan
      case 5:
	returnval() = atan(val());
 	break;
	// abs
      case 6:
	returnval() = abs(val());
 	break;
	// ceil
      case 7:
	returnval() = ceil(val());
 	break;
	// floor
      case 8:
	returnval() = floor(val());
 	break;
 	// canon
      case 9:
	returnval() = val().get();
	break;
	// log
      case 10:
	returnval() = log(val());
	break;
	// log10
      case 11:
	returnval() = log10(val());
	break;
	// exp
      case 12:
	returnval() = exp(val());
	break;
	// sqrt
      case 13:
	returnval() = sqrt(val());
	break;
      default:
	return error("Unknown one argument Quantity function");
	break;
      }
    };
  }
  break;

  // unitv
  case 16: {
    Parameter<Array<Double> > val(parameters, valName,
				  ParameterSet::In);
    Parameter<String> arg(parameters, argName,
			  ParameterSet::In);
    Parameter<Quantum<Array<Double> > > returnval(parameters, returnvalName,
						  ParameterSet::Out);
    if (runMethod) {
      returnval().getValue().resize(IPosition());
      returnval() = Quantum<Array<Double> >(val(), arg());
    };
  }
  break;

  // qvvfunc2
  case 17: {
    Parameter<Quantum<Vector<Double> > > val(parameters, valName,
					     ParameterSet::In);
    Parameter<Quantum<Vector<Double> > > arg(parameters, argName,
					     ParameterSet::In);
    Parameter<Int> form(parameters, formName, 
			ParameterSet::In);
    Parameter<Quantum<Vector<Double> > > returnval(parameters, returnvalName,
						   ParameterSet::Out);
    if (runMethod) {
      switch (form()) {
	// atan2
      case 0:
	returnval() = atan2(val(), arg());
	break;
	// mul
      case 1:
	returnval() = val() *  arg();
	break;
	// div
      case 2:
	returnval() = val() /  arg();
	break;
	// sub
      case 3:
	returnval() = val() -  arg();
	break;
	// add
      case 4:
	returnval() = val() +  arg();
	break;
	// convert
      case 5:
	returnval() = arg().getUnit().empty() ? val().get() : val().get(arg());
	break;
      default:
	return error("Unknown two argument Quantity function");
	break;
      }
    };
  }
  break;

  // quant
  case 18: {
    Parameter<Array<QuantumHolder> > val(parameters, valName,
					 ParameterSet::In);
    Parameter<Array<QuantumHolder> > returnval(parameters, returnvalName,
					       ParameterSet::Out);
    if (runMethod) returnval() = val();
  }
  break;

  // dopcv
  case 19: {
    Parameter<Quantity> val(parameters, valName,
			    ParameterSet::In);
    Parameter<Quantity> arg(parameters, argName,
			    ParameterSet::In);
    Parameter<Quantity> returnval(parameters, returnvalName,
				  ParameterSet::Out);
    if (runMethod) {
      try {
	returnval() = MVDoppler(val()).get(arg().getFullUnit());
      } catch (AipsError (x)) {
	return error("Illegal doppler type units specified");
      } 
    };    
  }
  break;

  // frqcv
  case 20: {
    Parameter<Quantity> val(parameters, valName,
			    ParameterSet::In);
    Parameter<Quantity> arg(parameters, argName,
			    ParameterSet::In);
    Parameter<Quantity> returnval(parameters, returnvalName,
				  ParameterSet::Out);
    if (runMethod) {
      try {
	returnval() = MVFrequency(val()).get(arg().getFullUnit());
      } catch (AipsError (x)) {
	return error("Illegal frequency type units specified");
      } 
    };    
  }
  break;

  // tfreq
  case 21: {
    Parameter<Quantum<Vector<Double> > > val(parameters, valName,
					     ParameterSet::In);
    Parameter<Vector<Int> > arg(parameters, argName,
				ParameterSet::In);
    Parameter<String> form(parameters, formName,
			   ParameterSet::In);
    Parameter<Bool> form2(parameters, form2Name,
			  ParameterSet::In);
    Parameter<Vector<String> > returnval(parameters, returnvalName,
					 ParameterSet::Out);
    if (runMethod) {
      Int nelem = val().getValue().nelements();
      Vector<Double> x(val().getValue());
      Quantity y;
      Unit inun(val().getFullUnit());
      try {
	Unit outun(form());
	for (Int i=0; i<nelem; i++) {
	  y = Quantity(x(i), inun);
	  x(i)= MVFrequency(y).get(outun).getValue();
	};
      } catch (AipsError (x)) {
	return error("Illegal frequency type units specified");
      } 
      if (nelem > 0) {
	Int nrow = arg()(arg().nelements()-1);
	Int ncol = nelem/nrow;
	returnval().resize(nrow);
	Int k = 0;
	for (Int i=0; i<nrow; i++) {
	  ostringstream oss;
	  if (ncol > 1) oss << '[';
	  for (Int j=0; j<ncol; j++) {
	    if (j>0) oss << ", ";
	    oss << x(k);
	    k++;
	  };
	  if (ncol > 1) oss << ']';
	  if (form2()) oss << " " << form();
	  returnval()(i) = oss.str();
	};
      } else {
	returnval().resize(0);
      };
    };
  }
  break;

  // splitdate
  case 22: {
    Parameter<Quantity> val(parameters, valName,
			    ParameterSet::In);
    Parameter<GlishRecord> returnval(parameters, returnvalName,
				     ParameterSet::Out);
    if (runMethod) {
      MVTime x(val());
      GlishRecord tmp;
      tmp.add("mjd", x.day());
      tmp.add("year", x.year());
      tmp.add("yearday", static_cast<Int>(x.yearday()));
      tmp.add("month",static_cast<Int>(x.month())); 
      tmp.add("monthday",static_cast<Int>(x.monthday())); 
      tmp.add("week",static_cast<Int>(x.yearweek())); 
      tmp.add("weekday",static_cast<Int>(x.weekday())); 
      Double y(fmod(x.day(), 1.0));
      tmp.add("hour",static_cast<Int>(y*24.0));
      y = fmod(y*24.0, 1.0);
      tmp.add("min",static_cast<Int>(y*60.0));
      y = fmod(y*60.0, 1.0);
      tmp.add("sec",static_cast<Int>(y*60.0));
      tmp.add("s",static_cast<Double>(y*60.0));
      y = fmod(y*60.0, 1.0);
      tmp.add("msec",static_cast<Int>(y*1000.0));
      tmp.add("usec",static_cast<Int>(y*1.0e6));
      returnval() = tmp;
    };
  }
  break;

  // qlogical
  case 23: {
    Parameter<Quantity> val(parameters, valName,
			    ParameterSet::In);
    Parameter<Quantity> arg(parameters, argName,
			    ParameterSet::In);
    Parameter<Int>	form(parameters, formName, 
			     ParameterSet::In);
    Parameter<Bool> 	returnval(parameters, returnvalName,
				  ParameterSet::Out);
    if (runMethod) {
      switch (form()) {
	// le
      case 0:
	returnval() = val() <= arg();
	break;
	// lt
      case 1:
	returnval() = val() < arg();
	break;
	// eq
      case 2:
	returnval() = val() == arg();
	break;
	// ne
      case 3:
	returnval() = val() != arg();
	break;
	// gt
      case 4:
	returnval() = val() > arg();
	break;
	// ge
      case 5:
	returnval() = val() >= arg();
	break;
      default:
	return error("Unknown Quantity comparison function");
	break;
      }
    };
  }
  break;

  default: {
    return error("Unknown method");
  }
  break;

  };
  return ok();
}
