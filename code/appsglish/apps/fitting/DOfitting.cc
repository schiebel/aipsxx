//# DOfitting.cc:  This class gives Glish to Fitting connection
//# Copyright (C) 1999,2000,2002,2003,2004
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
//# $Id: DOfitting.cc,v 19.12 2005/11/07 21:17:03 wyoung Exp $

//# Includes

#include <appsglish/fitting/DOfitting.h>
#include <scimath/Fitting/LSQaips.h>
#include <scimath/Fitting/LinearFitSVD.h>
#include <scimath/Fitting/NonLinearFitLM.h>
#include <scimath/Fitting/GenericL2Fit.h>
#include <scimath/Fitting/NonLinearFit.h>
#include <scimath/Functionals/FunctionHolder.h>
#include <scimath/Functionals/HyperPlane.h>
#include <casa/BasicSL/Complex.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayAccessor.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/VectorIter.h>
#include <casa/Arrays/VectorSTLIterator.h>
#include <casa/Containers/Record.h>
#include <casa/Containers/RecordFieldId.h>
#include <tasking/Glish.h>
#include <casa/Logging.h>
#include <casa/Exceptions/Error.h>

#include <casa/namespace.h>
// FitType
// Constructor
fitting::FitType::FitType() :
  fitter_p(0), fitterCX_p(0),
  n_p(0), nceq_p(0), nreal_p(0), typ_p(0),
  colfac_p(1e-8), lmfac_p(1e-3), 
  soldone_p(False), nr_p(0) {;}

fitting::FitType::~FitType() {
  delete fitter_p; fitter_p = 0;
  delete fitterCX_p; fitterCX_p = 0;
}

// Methods
void fitting::FitType::setFitter(GenericL2Fit<Double> *ptr) {
  delete fitter_p; fitter_p = 0;
  delete fitterCX_p; fitterCX_p = 0;
  fitter_p = ptr;
}

void fitting::FitType::setFitterCX(GenericL2Fit<DComplex> *ptr) {
  delete fitter_p; fitter_p = 0;
  delete fitterCX_p; fitterCX_p = 0;
  fitterCX_p = ptr;
}

GenericL2Fit<Double> *const& fitting::FitType::getFitter() const {
  return fitter_p;
}

GenericL2Fit<DComplex> *const& fitting::FitType::getFitterCX() const {
  return fitterCX_p;
}

void fitting::FitType::setStatus(Int n, Int typ,
				 Double colfac, Double lmfac) {
  n_p = n;
  typ_p = typ;
  nceq_p = (typ == 3 || typ == 11) ? 2*n_p : n_p;
  nreal_p = (typ_p != 0) ? 2*n_p : n_p;
  colfac_p = colfac;
  lmfac_p = lmfac;
}

void fitting::FitType::setSolved(Bool solved) {
  soldone_p = solved;
}

// fitting
// Constructors
fitting::fitting() :
  nFitter_p(0), list_p(0) {}

fitting::fitting(const fitting &other) : ApplicationObject(other) {;}

fitting &fitting::operator=(const fitting &) {
  return *this;
}

// Destructor
fitting::~fitting() {
  for (uInt i=0; i<nFitter_p; i++) {
    delete list_p[i]; list_p[i] = 0;
  };
  delete [] list_p;
}

// Methods

// DO name
String fitting::className() const {
  return "fitting";
}

// Available methods
Vector<String> fitting::methods() const {
  Vector<String> tmp(10);
  tmp(0) = "getid";			// get a new fitter id
  tmp(1) = "getstate";			// get the state record
  tmp(2) = "init";			// initialise one
  tmp(3) = "done";			// free resources
  tmp(4) = "reset";			// reset to start state
  tmp(5) = "set";			// set some properties
  tmp(6) = "functional";		// fit a functional
  tmp(7) = "linear";			// fit a functional (linear)
  tmp(8) = "cxfunctional";		// fit a functional (complex)
  tmp(9) = "cxlinear";			// fit a functional (complex, linear)

  return tmp;
}

// Untraced methods
Vector<String> fitting::noTraceMethods() const {
  return methods();
}

// Execute methods
MethodResult fitting::runMethod(uInt which,
				ParameterSet &parameters,
				Bool runMethod) {

  static String returnvalName = "returnval";
  static String idName    = "id";
  static String fncName   = "fnc";
  static String valName   = "val";
  static String val0Name  = "val0";
  static String val1Name  = "val1";
  static String val2Name  = "val2";
  static String arg0Name  = "arg0";
  static String arg1Name  = "arg1";
  static String arg2Name  = "arg2";
  static String arg3Name  = "arg3";
  static String arg4Name  = "arg4";
  static String arg5Name  = "arg5";
  static String arg6Name  = "arg6";
  static String arg7Name  = "arg7";
  static String arg8Name  = "arg8";

  String err;

  switch (which) {

  // getid: get a new id
  case 0: {
    Parameter<Int> returnval(parameters, returnvalName,
			     ParameterSet::Out);
    if (runMethod) {
      Int id = -1;
      while (id<0) {
	for (uInt i=0; i<nFitter_p; i++) {
	  if (!list_p[i]) {
	    id = i;
	    break;
	  };
	};
	// Make some more
	if (id<0) {
	  uInt n = nFitter_p;
	  nFitter_p++;
	  nFitter_p *= 2;
	  FitType **list = list_p;
	  list_p = new FitType *[nFitter_p];
	  for (uInt i=0; i<nFitter_p; i++) {
	    list_p[i] = 0;
	    if (i<n) list_p[i] = list[i];
	  };
	  delete [] list;
	};
      };
      list_p[id] = new fitting::FitType;
      returnval() = id;
    };
  }
  break;

  // getstate: get the state
  case 1: {
    Parameter<Int> id(parameters, idName,
		      ParameterSet::In);
    Parameter<GlishRecord> returnval(parameters, returnvalName,
				     ParameterSet::Out);
    if (runMethod) {
      GlishRecord res;
      if (list_p[id()]->getFitter()) {
	res.add(String("n"), list_p[id()]->getN());
	res.add(String("typ"), list_p[id()]->getType());
	res.add(String("colfac"), list_p[id()]->getColfac());
	res.add(String("lmfac"), list_p[id()]->getLMfac());
      };      
      returnval() = res;
    };
  }
  break;

  // init: init a fitter
  case 2: {
    Parameter<Int> id(parameters, idName,
		      ParameterSet::In);
    Parameter<Int> n(parameters, valName,
		     ParameterSet::In);
    Parameter<Int> tp(parameters, arg1Name,
		      ParameterSet::In);
    Parameter<Double> colfac(parameters, arg2Name,
			     ParameterSet::In);
    Parameter<Double> lmfac(parameters, arg3Name,
			    ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName,
			      ParameterSet::Out);
    if (runMethod) {
      if (tp() == 0) {
	if (!list_p[id()]->getFitter()) {
	  list_p[id()]->setFitter(new LinearFitSVD<Double>);
	};
	list_p[id()]->getFitter()->set(n());
	list_p[id()]->getFitter()->set(abs(colfac()), abs(lmfac()));
      } else {
	if (!list_p[id()]->getFitterCX()) {
	  list_p[id()]->setFitterCX(new LinearFitSVD<DComplex>);
	};
	list_p[id()]->getFitterCX()->set(n());
	list_p[id()]->getFitterCX()->set(abs(colfac()), abs(lmfac()));
      };
      list_p[id()]->setStatus(n(), tp(),
			      abs(colfac()), abs(lmfac()));
      list_p[id()]->setSolved(False);
      returnval() = True;
    };
  }
  break;

  // done: free resources
  case 3: {
    Parameter<Int> id(parameters, idName,
		      ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName,
			      ParameterSet::Out);
    if (runMethod) {
      if (!list_p[id()]->getFitter() && !list_p[id()]->getFitterCX()) {
	return error("Trying to undo a non-existing fitter");
      };
      list_p[id()]->setFitter(0);
      returnval() = True;
    };
  }
  break;

  // reset: reset to start state
  case 4: {
    Parameter<Int> id(parameters, idName,
		      ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName,
			      ParameterSet::Out);
    if (runMethod) {
      if (!list_p[id()]->getFitter() && !list_p[id()]->getFitterCX()) {
	return error("Trying to reset a non-existing fitter");
      };
      if (list_p[id()]->getFitter()) list_p[id()]->getFitter()->reset();
      else list_p[id()]->getFitterCX()->reset();
      list_p[id()]->setSolved(False);
      returnval() = True;
    };
  }
  break;

  // set: set some fitter properties
  case 5: {
    Parameter<Int> id(parameters, idName,
		      ParameterSet::In);
    Parameter<Int> nin(parameters, valName,
		       ParameterSet::In);
    Parameter<Int> tpin(parameters, arg1Name,
			ParameterSet::In);
    Parameter<Double> colfac(parameters, arg2Name,
			     ParameterSet::In);
    Parameter<Double> lmfac(parameters, arg3Name,
			    ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName,
			      ParameterSet::Out);
    if (runMethod) {
      if (!list_p[id()]->getFitter() && !list_p[id()]->getFitterCX()) {
	return error("Trying to set properties of non-existing fitter");
      };
      Int n = nin();
      Int tp= tpin();
      Double cf = colfac();
      Double lmf = lmfac();
      if (n == -1)  n  = list_p[id()]->getN();
      if (tp== -1)  tp = list_p[id()]->getType();
      if (cf < 0)   cf = list_p[id()]->getColfac();
      if (lmf< 0)  lmf = list_p[id()]->getLMfac();
      if (list_p[id()]->getFitter()) {
	list_p[id()]->getFitter()->set(n);
	list_p[id()]->getFitter()->set(cf, lmf);
      } else {
	list_p[id()]->getFitter()->set(n);
	list_p[id()]->getFitter()->set(cf, lmf);
      };
      list_p[id()]->setStatus(n, tp, cf, lmf);
      list_p[id()]->setSolved(False);
      returnval() = True;
    };
  }
  break;

  // functional: fit a functional (real)
  case 6: {
    Parameter<Int> id(parameters, idName,
		      ParameterSet::In);
    Parameter<GlishRecord> fnc(parameters, fncName,
                               ParameterSet::In);
    Parameter<Vector<Double> > xval(parameters, valName,
				    ParameterSet::In);
    Parameter<Vector<Double> > yval(parameters, val0Name,
				    ParameterSet::In);
    Parameter<Vector<Double> > wt(parameters, val1Name,
				  ParameterSet::In);
    Parameter<Int> mxit(parameters, val2Name,
			ParameterSet::In);
    Parameter<Int> rank(parameters, arg0Name,
			ParameterSet::Out);
    Parameter<Double> sd(parameters, arg1Name,
			 ParameterSet::Out);
    Parameter<Double> mu(parameters, arg2Name,
			 ParameterSet::Out);
    Parameter<Double> chi2(parameters, arg3Name,
			   ParameterSet::Out);
    Parameter<Vector<Double> > constr(parameters, arg4Name,
				      ParameterSet::Out);
    Parameter<Array<Double> > covar(parameters, arg5Name,
				    ParameterSet::Out);
    Parameter<Vector<Double> > err(parameters, arg6Name,
				   ParameterSet::Out);
    Parameter<GlishRecord> constraint(parameters, arg7Name,
				      ParameterSet::In);
    Parameter<Int> deficiency(parameters, arg8Name,
			      ParameterSet::Out);
    Parameter<Vector<Double> > returnval(parameters, returnvalName,
					ParameterSet::Out);
    if (runMethod) {
      String errmsg;
      NonLinearFitLM<Double> fitter;
      fitter.setMaxIter(mxit());
      fitter.asWeight(True);
      FunctionHolder<Double> fnh;
      Function<AutoDiff<Double> > *fn(0);
      Record rec;
      fnc().toRecord (rec);
      if (!fnh.getRecord(errmsg, fn, rec)) return error(errmsg);
      fitter.setFunction(*fn);
      returnval().resize();
      if (xval().nelements() != fn->ndim()*yval().nelements()) {
	return error("Functional fitter x and y lengths disagree");
      };
      constraint().toRecord(rec);	// add constraints
      for (uInt i=0; i<rec.nfields(); ++i) {
	RecordFieldId fid = i;
	if (rec.type(i) != TpRecord) {
	  return error("Illegal definition of constraint in addconstraint");
	};
	const RecordInterface &con = rec.asRecord(fid);
	if (con.isDefined(String("fnct")) && con.isDefined(String("x")) &&
	    con.isDefined(String("y")) &&
	    con.type(con.idToNumber(RecordFieldId("fnct"))) == TpRecord &&
	    con.type(con.idToNumber(RecordFieldId("x"))) == TpArrayDouble &&
	    con.type(con.idToNumber(RecordFieldId("y"))) == TpDouble) {
	  Vector<Double> x;
	  con.get(RecordFieldId("x"), x);
	  Double y;
	  con.get(RecordFieldId("y"), y);
	  HyperPlane<AutoDiff<Double> > constrFun(x.nelements());
	  fitter.addConstraint(constrFun, x, y);
	} else {
	  return error("Illegal definition of a constraint in addconstraint");
	};
      };
      IPosition ip2(2, xval().nelements(), fn->ndim());
      if (fn->ndim() > 1) ip2[0] /= fn->ndim();
      Matrix<Double> mval(ip2);
      Array<Double>::const_iterator cit = xval().begin();
      for (ArrayAccessor<Double, Axis<0> > i(mval); i!=i.end(); ++i) {
	for (uInt j=0; j<fn->ndim(); ++cit, ++j) i.index<Axis<1> >(j) = *cit;
      };
      if (wt().nelements() == 0 ||
	  (wt().nelements() == 1 && yval().nelements() != 1)) {
	returnval() = fitter.fit(mval, yval());
      } else {
	returnval() = fitter.fit(mval, yval(), wt());
      };
      rank() = fitter.getRank();
      deficiency() = fitter.getDeficiency();
      sd() = fitter.getSD();
      mu() = fitter.getWeightedSD();
      chi2() = fitter.getChi2();
      constr().resize(returnval().nelements()*fitter.getDeficiency());
      Double *conit = constr().data();
      casa::Vector<Double> ctmp(returnval().nelements());
      Double *ctit = ctmp.data();
      for (casa::uInt i=0; i<fitter.getDeficiency(); ++i) {
	ctmp = fitter.getSVDConstraint(i);
	for (uInt j=0; j<returnval().nelements(); ++j) *conit++ = ctit[j];
      };
      covar() = fitter.compuCovariance();
      err().resize();
      fitter.getErrors(err());
      list_p[id()]->setSolved(True);
    };
  }
  break;

  // linear: fit a linear functional (real)
  case 7: {
    Parameter<Int> id(parameters, idName,
		      ParameterSet::In);
    Parameter<GlishRecord> fnc(parameters, fncName,
                               ParameterSet::In);
    Parameter<Vector<Double> > xval(parameters, valName,
				    ParameterSet::In);
    Parameter<Vector<Double> > yval(parameters, val0Name,
				    ParameterSet::In);
    Parameter<Vector<Double> > wt(parameters, val1Name,
				  ParameterSet::In);
    Parameter<Int> rank(parameters, arg0Name,
			ParameterSet::Out);
    Parameter<Double> sd(parameters, arg1Name,
			 ParameterSet::Out);
    Parameter<Double> mu(parameters, arg2Name,
			 ParameterSet::Out);
    Parameter<Double> chi2(parameters, arg3Name,
			   ParameterSet::Out);
    Parameter<Vector<Double> > constr(parameters, arg4Name,
				      ParameterSet::Out);
    Parameter<Array<Double> > covar(parameters, arg5Name,
				    ParameterSet::Out);
    Parameter<Vector<Double> > err(parameters, arg6Name,
				   ParameterSet::Out);
    Parameter<GlishRecord> constraint(parameters, arg7Name,
				      ParameterSet::In);
    Parameter<Int> deficiency(parameters, arg8Name,
			      ParameterSet::Out);
    Parameter<Vector<Double> > returnval(parameters, returnvalName,
					 ParameterSet::Out);
    if (runMethod) {
      String errmsg;
      LinearFitSVD<Double> fitter;
      fitter.asWeight(True);
      FunctionHolder<Double> fnh;
      Function<AutoDiff<Double> > *fn(0);
      Record rec;
      fnc().toRecord(rec);
      if (!fnh.getRecord(errmsg, fn, rec)) return error(errmsg);
      fitter.setFunction(*fn);
      if (xval().nelements() != fn->ndim()*yval().nelements()) {
	return error("Linear fitter x and y lengths disagree");
      };
      constraint().toRecord(rec);	// add constraints
      for (uInt i=0; i<rec.nfields(); ++i) {
	RecordFieldId fid = i;
	if (rec.type(i) != TpRecord) {
	  return error("Illegal definition of constraint in addconstraint");
	};
	const RecordInterface &con = rec.asRecord(fid);
	if (con.isDefined(String("fnct")) && con.isDefined(String("x")) &&
	    con.isDefined(String("y")) &&
	    con.type(con.idToNumber(RecordFieldId("fnct"))) == TpRecord &&
	    con.type(con.idToNumber(RecordFieldId("x"))) == TpArrayDouble &&
	    con.type(con.idToNumber(RecordFieldId("y"))) == TpDouble) {
	  Vector<Double> x;
	  con.get(RecordFieldId("x"), x);
	  Double y;
	  con.get(RecordFieldId("y"), y);
	  HyperPlane<AutoDiff<Double> > constrFun(x.nelements());
	  fitter.addConstraint(constrFun, x, y);
	} else {
	  return error("Illegal definition of a constraint in addconstraint");
	};
      };
      IPosition ip2(2, xval().nelements(), fn->ndim());
      if (fn->ndim() > 1) ip2[0] /= fn->ndim();
      Matrix<Double> mval(ip2);
      Array<Double>::const_iterator cit = xval().begin();
      for (ArrayAccessor<Double, Axis<0> > i(mval); i!=i.end(); ++i) {
	for (uInt j=0; j<fn->ndim(); ++cit, ++j) i.index<Axis<1> >(j) = *cit;
      };
      if (wt().nelements() == 0 ||
	  (wt().nelements() == 1 && yval().nelements() != 1)) {
	returnval() = fitter.fit(mval, yval());
      } else {
	returnval() = fitter.fit(mval, yval(), wt());
      };
      rank() = fitter.getRank();
      deficiency() = fitter.getDeficiency();
      sd() = fitter.getSD();
      mu() = fitter.getWeightedSD();
      chi2() = fitter.getChi2();
      constr().resize(returnval().nelements()*fitter.getDeficiency());
      Double *conit = constr().data();
      casa::Vector<Double> ctmp(returnval().nelements());
      Double *ctit = ctmp.data();
      for (uInt i=0; i<fitter.getDeficiency(); ++i,
	     conit+returnval().nelements()) {
	ctmp = fitter.getSVDConstraint(i);
	for (uInt j=0; j<returnval().nelements(); ++j) *conit++ = ctit[j];
      };
      covar().resize();
      covar() = fitter.compuCovariance();
      err().resize();
      fitter.getErrors(err());
      list_p[id()]->setSolved(True);
    };
  }
  break;

  // cxfunctional: fit a functional (complex)
  case 8: {
    Parameter<Int> id(parameters, idName,
		      ParameterSet::In);
    Parameter<GlishRecord> fnc(parameters, fncName,
                               ParameterSet::In);
    Parameter<Vector<DComplex> > xval(parameters, valName,
				      ParameterSet::In);
    Parameter<Vector<DComplex> > yval(parameters, val0Name,
				      ParameterSet::In);
    Parameter<Vector<DComplex> > wt(parameters, val1Name,
				    ParameterSet::In);
    Parameter<Int> mxit(parameters, val2Name,
			ParameterSet::In);
    Parameter<Int> rank(parameters, arg0Name,
			ParameterSet::Out);
    Parameter<Double> sd(parameters, arg1Name,
			 ParameterSet::Out);
    Parameter<Double> mu(parameters, arg2Name,
			 ParameterSet::Out);
    Parameter<Double> chi2(parameters, arg3Name,
			   ParameterSet::Out);
    Parameter<Vector<Double> > constr(parameters, arg4Name,
				      ParameterSet::Out);
    Parameter<Array<DComplex> > covar(parameters, arg5Name,
				      ParameterSet::Out);
    Parameter<Vector<DComplex> > err(parameters, arg6Name,
				     ParameterSet::Out);
    Parameter<GlishRecord> constraint(parameters, arg7Name,
				      ParameterSet::In);
    Parameter<Int> deficiency(parameters, arg8Name,
			      ParameterSet::Out);
    Parameter<Vector<DComplex> > returnval(parameters, returnvalName,
					   ParameterSet::Out);
    if (runMethod) {
      String errmsg;
      NonLinearFitLM<DComplex> fitter;
      fitter.setMaxIter(mxit());
      fitter.asWeight(True);
      FunctionHolder<DComplex> fnh;
      Function<AutoDiff<DComplex> > *fn(0);
      Record rec;
      fnc().toRecord (rec);
      if (!fnh.getRecord(errmsg, fn, rec)) return error(errmsg);
      fitter.setFunction(*fn);
      returnval().resize();
      if (xval().nelements() != fn->ndim()*yval().nelements()) {
	return error("Functional fitter x and y lengths disagree");
      };
      constraint().toRecord(rec);	// add constraints
      for (uInt i=0; i<rec.nfields(); ++i) {
	RecordFieldId fid = i;
	if (rec.type(i) != TpRecord) {
	  return error("Illegal definition of constraint in addconstraint");
	};
	const RecordInterface &con = rec.asRecord(fid);
	if (con.isDefined(String("fnct")) && con.isDefined(String("x")) &&
	    con.isDefined(String("y")) &&
	    con.type(con.idToNumber(RecordFieldId("fnct"))) == TpRecord &&
	    con.type(con.idToNumber(RecordFieldId("x"))) == TpArrayDComplex &&
	    con.type(con.idToNumber(RecordFieldId("y"))) == TpDComplex) {
	  Vector<DComplex> x;
	  con.get(RecordFieldId("x"), x);
	  DComplex y;
	  con.get(RecordFieldId("y"), y);
	  HyperPlane<AutoDiff<DComplex> > constrFun(x.nelements());
	  fitter.addConstraint(constrFun, x, y);
	} else {
	  return error("Illegal definition of a constraint in addconstraint");
	};
      };
      IPosition ip2(2, xval().nelements(), fn->ndim());
      if (fn->ndim() > 1) ip2[0] /= fn->ndim();
      Matrix<DComplex> mval(ip2);
      Array<DComplex>::const_iterator cit = xval().begin();
      for (ArrayAccessor<DComplex, Axis<0> > i(mval); i!=i.end(); ++i) {
	for (uInt j=0; j<fn->ndim(); ++cit, ++j) i.index<Axis<1> >(j) = *cit;
      };
      if (wt().nelements() == 0 ||
	  (wt().nelements() == 1 && yval().nelements() != 1)) {
	returnval() = fitter.fit(mval, yval());
      } else {
	returnval() = fitter.fit(mval, yval(), wt());
      };
      rank() = fitter.getRank();
      deficiency() = fitter.getDeficiency();
      sd() = fitter.getSD();
      mu() = fitter.getWeightedSD();
      chi2() = fitter.getChi2();
      constr().resize(returnval().nelements()*fitter.getDeficiency());
      Double *conit = constr().data();
      casa::Vector<Double> ctmp(returnval().nelements());
      Double *ctit = ctmp.data();
      for (uInt i=0; i<fitter.getDeficiency(); ++i) {
	ctmp = fitter.getSVDConstraint(i);
	for (uInt j=0; j<returnval().nelements(); ++j) *conit++ = ctit[j];
      };
      fitter.getCovariance(covar());
      fitter.getErrors(err());
      list_p[id()]->setSolved(True);
    };
  }
  break;

  // cxlinear: fit a linear functional (complex)
  case 9: {
    Parameter<Int> id(parameters, idName,
		      ParameterSet::In);
    Parameter<GlishRecord> fnc(parameters, fncName,
                               ParameterSet::In);
    Parameter<Vector<DComplex> > xval(parameters, valName,
				      ParameterSet::In);
    Parameter<Vector<DComplex> > yval(parameters, val0Name,
				      ParameterSet::In);
    Parameter<Vector<DComplex> > wt(parameters, val1Name,
				    ParameterSet::In);
    Parameter<Int> rank(parameters, arg0Name,
			ParameterSet::Out);
    Parameter<Double> sd(parameters, arg1Name,
			 ParameterSet::Out);
    Parameter<Double> mu(parameters, arg2Name,
			 ParameterSet::Out);
    Parameter<Double> chi2(parameters, arg3Name,
			   ParameterSet::Out);
    Parameter<Vector<Double> > constr(parameters, arg4Name,
				      ParameterSet::Out);
    Parameter<Array<DComplex> > covar(parameters, arg5Name,
				      ParameterSet::Out);
    Parameter<Vector<DComplex> > err(parameters, arg6Name,
				     ParameterSet::Out);
    Parameter<GlishRecord> constraint(parameters, arg7Name,
				      ParameterSet::In);
    Parameter<Int> deficiency(parameters, arg8Name,
			      ParameterSet::Out);
    Parameter<Vector<DComplex> > returnval(parameters, returnvalName,
					   ParameterSet::Out);
    if (runMethod) {
      String errmsg;
      LinearFitSVD<DComplex> fitter;
      fitter.asWeight(True);
      FunctionHolder<DComplex> fnh;
      Function<AutoDiff<DComplex> > *fn(0);
      Record rec;
      fnc().toRecord(rec);
      if (!fnh.getRecord(errmsg, fn, rec)) return error(errmsg);
      fitter.setFunction(*fn);
      if (xval().nelements() != fn->ndim()*yval().nelements()) {
	return error("Linear fitter x and y lengths disagree");
      };
      constraint().toRecord(rec);	// add constraints
      for (uInt i=0; i<rec.nfields(); ++i) {
	RecordFieldId fid = i;
	if (rec.type(i) != TpRecord) {
	  return error("Illegal definition of constraint in addconstraint");
	};
	const RecordInterface &con = rec.asRecord(fid);
	if (con.isDefined(String("fnct")) && con.isDefined(String("x")) &&
	    con.isDefined(String("y")) &&
	    con.type(con.idToNumber(RecordFieldId("fnct"))) == TpRecord &&
	    con.type(con.idToNumber(RecordFieldId("x"))) == TpArrayDComplex &&
	    con.type(con.idToNumber(RecordFieldId("y"))) == TpDComplex) {
	  Vector<DComplex> x;
	  con.get(RecordFieldId("x"), x);
	  DComplex y;
	  con.get(RecordFieldId("y"), y);
	  HyperPlane<AutoDiff<DComplex> > constrFun(x.nelements());
	  ///	  fitter.addConstraint(constrFun, x, y);
	} else {
	  return error("Illegal definition of a constraint in addconstraint");
	};
      };
      IPosition ip2(2, xval().nelements(), fn->ndim());
      if (fn->ndim() > 1) ip2[0] /= fn->ndim();
      Matrix<DComplex> mval(ip2);
      Array<DComplex>::const_iterator cit = xval().begin();
      for (ArrayAccessor<DComplex, Axis<0> > i(mval); i!=i.end(); ++i) {
	for (uInt j=0; j<fn->ndim(); ++cit, ++j) i.index<Axis<1> >(j) = *cit;
      };
      if (wt().nelements() == 0 ||
	  (wt().nelements() == 1 && yval().nelements() != 1)) {
	returnval() = fitter.fit(mval, yval());
      } else {
	returnval() = fitter.fit(mval, yval(), wt());
      };
      rank() = fitter.getRank();
      deficiency() = fitter.getDeficiency();
      sd() = fitter.getSD();
      mu() = fitter.getWeightedSD();
      chi2() = fitter.getChi2();
      constr().resize(returnval().nelements()*fitter.getDeficiency());
      Double *conit = constr().data();
      casa::Vector<Double> ctmp(returnval().nelements());
      Double *ctit = ctmp.data();
      for (uInt i=0; i<fitter.getDeficiency(); ++i,
	     conit+returnval().nelements()) {
	ctmp = fitter.getSVDConstraint(i);
	for (uInt j=0; j<returnval().nelements(); ++j) *conit++ = ctit[j];
      };
      fitter.getCovariance(covar());
      fitter.getErrors(err());
      list_p[id()]->setSolved(True);
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
