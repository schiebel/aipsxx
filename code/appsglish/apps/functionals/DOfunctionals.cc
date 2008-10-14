//# DOfunctionals.cc:  This class gives Glish to Quantity connection
//# Copyright (C) 2002,2003,2004
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
//# $Id: DOfunctionals.cc,v 19.7 2005/11/07 21:17:03 wyoung Exp $

//# Includes

#include <appsglish/functionals/DOfunctionals.h>
#include <scimath/Functionals/FunctionHolder.h>
#include <tasking/Glish.h>
#include <casa/Containers/Record.h>
#include <casa/Exceptions/Error.h>
#include <casa/BasicSL/Complex.h>

#include <casa/namespace.h>
// Constructors
functionals::functionals() {}

functionals::functionals(const functionals &other) :
  ApplicationObject(other) {}

functionals &functionals::operator=(const functionals &other) {
  if (False && !&other) {}; // stop warning 
  return *this;
}

// Destructor
functionals::~functionals() {;}

// DO name
String functionals::className() const {
  return "functionals";
}

// Available methods
Vector<String> functionals::methods() const {
  Vector<String> tmp(8);
  tmp(0) = "define";			// check define a new functional
  tmp(1) = "f";				// calculate function value
  tmp(2) = "fdf";			// function value and D wrt parameters
  tmp(3) = "names";			// list of names of functions known
  tmp(4) = "add";			// add to combi/compound
  tmp(5) = "fc";			// calculate function value (complex)
  tmp(6) = "fdfc";			// function value and D wrt parameters
  tmp(7) = "addc";			// add to combi/compound (complex)
  return tmp;
}

// Untraced methods
Vector<String> functionals::noTraceMethods() const {
  return methods();
}

// Execute methods
MethodResult functionals::runMethod(uInt which,
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
    Parameter<FunctionHolder<Double> > arg(parameters, argName,
					   ParameterSet::In);
    Parameter<FunctionHolder<Double> > returnval(parameters, returnvalName,
						 ParameterSet::Out);
    if (runMethod) {
      returnval() = arg();
    };
  }
  break;

  // f
  case 1: {
    Parameter<FunctionHolder<Double> > arg(parameters, argName,
					   ParameterSet::In);
    Parameter<Vector<Double> > val(parameters, valName,
				   ParameterSet::In);
    Parameter<Vector<Double> > returnval(parameters, returnvalName,
					 ParameterSet::Out);
    if (runMethod) {
      Int nd=1;
      if (arg().asFunction().ndim() != 0) nd = arg().asFunction().ndim();
      Vector<Double> out(val().nelements()/nd);
      Vector<Double> in(nd);
      for (uInt i=0; i<val().nelements()/nd; ++i) {
	for (Int j=0; j<nd; ++j) in[j] = val()[i*nd+j];
	out[i] = arg().asFunction()(in);
      };
      returnval() = out;
    };
  }
  break;

  // fdf
  case 2: {
    Parameter<GlishRecord> arg(parameters, argName,
			       ParameterSet::In);
    Parameter<Vector<Double> > val(parameters, valName,
				   ParameterSet::In);
    Parameter<Vector<Double> > returnval(parameters, returnvalName,
					 ParameterSet::Out);
    if (runMethod) {
      String errmsg;
      FunctionHolder<Double> fnh;
      Function<AutoDiff<Double> > *fn(0);
      Record rec;
      arg().toRecord(rec);
      if (!fnh.getRecord(errmsg, fn, rec)) return error(errmsg);

      Int nd=1;
      if (fn->ndim() != 0) nd = fn->ndim();
      Vector<Double> out(val().nelements()/nd *
			 (fn->nparameters()+1));
      Vector<Double> in(nd);
      for (uInt i=0; i<val().nelements()/nd; ++i) {
	for (Int j=0; j<nd; ++j) in[j] = val()[i*nd+j];
	AutoDiff<Double> res = (*fn)(in);
	out[i] = res.value();
	for (uInt k=0; k<fn->nparameters(); ++k) {
	  out[(k+1)*val().nelements()/nd+i] = res.deriv(k);
	};
      };
      returnval() = out;
    };
  }
  break;

  // names
  case 3: {
    Parameter<Vector<String> > returnval(parameters, returnvalName,
					 ParameterSet::Out);
    if (runMethod) {
      returnval().resize(0);
      FunctionHolder<Double> fnh;
      returnval() = fnh.names();
    };
  }
  break;

  // add
  case 4: {
    Parameter<FunctionHolder<Double> > arg(parameters, argName,
					   ParameterSet::In);
    Parameter<FunctionHolder<Double> > val(parameters, valName,
					   ParameterSet::In);
    Parameter<FunctionHolder<Double> > returnval(parameters, returnvalName,
						 ParameterSet::Out);
    if (runMethod) {
      if (!arg().addFunction(val().asFunction())) {
	return error("Cannot add Function");
      };
      returnval() = arg();
    };
  }
  break;

  // fc
  case 5: {
    Parameter<FunctionHolder<DComplex> > arg(parameters, argName,
					     ParameterSet::In);
    Parameter<Vector<DComplex> > val(parameters, valName,
				     ParameterSet::In);
    Parameter<Vector<DComplex> > returnval(parameters, returnvalName,
					   ParameterSet::Out);
    if (runMethod) {
      Int nd=1;
      if (arg().asFunction().ndim() != 0) nd = arg().asFunction().ndim();
      Vector<DComplex> out(val().nelements()/nd);
      Vector<DComplex> in(nd);
      for (uInt i=0; i<val().nelements()/nd; ++i) {
	for (Int j=0; j<nd; ++j) in[j] = val()[i*nd+j];
	out[i] = arg().asFunction()(in);
      };
      returnval() = out;
    };
  }
  break;
  
  // fdfc
  case 6: {
    Parameter<GlishRecord> arg(parameters, argName,
			       ParameterSet::In);
    Parameter<Vector<DComplex> > val(parameters, valName,
				     ParameterSet::In);
    Parameter<Vector<DComplex> > returnval(parameters, returnvalName,
					   ParameterSet::Out);
    if (runMethod) {
      // The next for changed Record management
      String errmsg;
      FunctionHolder<DComplex> fnh;
      Function<AutoDiff<DComplex> > *fn(0);
      Record rec;
      arg().toRecord(rec);
      if (!fnh.getRecord(errmsg, fn, rec)) return error(errmsg);

      Int nd=1;
      if (fn->ndim() != 0) nd = fn->ndim();
      Vector<DComplex> out(val().nelements()/nd *
			   (fn->nparameters()+1));
      Vector<DComplex> in(nd);
      for (uInt i=0; i<val().nelements()/nd; ++i) {
	for (Int j=0; j<nd; ++j) in[j] = val()[i*nd+j];
	AutoDiff<DComplex> res = (*fn)(in);
	out[i] = res.value();
	for (uInt k=0; k<fn->nparameters(); ++k) {
	  out[(k+1)*val().nelements()/nd+i] = res.deriv(k);
	};
      };
      returnval() = out;
    };
  }
  break;
  
  // addc
  case 7: {
    Parameter<FunctionHolder<DComplex> > arg(parameters, argName,
					     ParameterSet::In);
    Parameter<FunctionHolder<DComplex> > val(parameters, valName,
					     ParameterSet::In);
    Parameter<FunctionHolder<DComplex> > returnval(parameters, returnvalName,
						   ParameterSet::Out);
    if (runMethod) {
      if (!arg().addFunction(val().asFunction())) {
	return error("Cannot add Function");
      };
      returnval() = arg();
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
