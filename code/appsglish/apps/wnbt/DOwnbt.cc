//# DOwnbt.cc:  This class gives Glish to wnb test connection
//# Copyright (C) 2000,2001,2004
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
//# $Id: DOwnbt.cc,v 19.8 2005/11/07 21:17:04 wyoung Exp $

//# Includes

#include <appsglish/wnbt/DOwnbt.h>
#include <images/Wnbt/ComponentUpdate.h>
#include <measures/Measures/MeasureHolder.h>
#include <casa/Quanta/QuantumHolder.h>
#include <tasking/Glish.h>
#include <casa/Logging.h>
#include <casa/Exceptions/Error.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Logging/LogIO.h>
#include <casa/Containers/Block.h>
#include <scimath/Fitting/LSQaips.h>
#include <casa/Utilities/COWPtr.h>
#include <images/Images/PagedImage.h>
#include <images/Images/ImageSummary.h>
#include <components/ComponentModels/ComponentList.h>
#include <casa/BasicMath/Math.h>
#include <casa/OS/Path.h>

#include <casa/namespace.h>
// Constructors
wnbt::wnbt() : imptr_p(0) {;}

wnbt::wnbt(const wnbt &other) :
  ApplicationObject(other), imptr_p(0), cupptr_p(0) {;}

wnbt &wnbt::operator=(const wnbt &) {
  return *this;
}

// Destructor
wnbt::~wnbt() {
  delete imptr_p; imptr_p = 0;
}

// Wnbt actions
Int wnbt::find(Array<Double> &rsa, Double mapLim, Bool afind) {
  // Assume Matrix
  Matrix<Double> rs;
  rs.reference(rsa);
  Int N(rs.shape()(0));
  // Assume only positive
  Double asign(1.0);
  // Fitting data
  Double mat[3][3];
  LSQaips fit(6);
  Vector<Double> gel(6);
  uInt rank;
  Vector<Double> sol(6);
  // Input local array
  uInt nx(imptr_p->shape()(0));
  uInt ny(imptr_p->shape()(1));
  ///  const IPosition inSlice(4, nx, 1, 1, 1);
  IPosition inSlice(imptr_p->shape());
  inSlice = 1;
  inSlice(0) = nx;
  Block<COWPtr<Array<Float> > > inPtr(3);
  Matrix<Bool> inDone(3,nx);
  inDone = False;
  for (uInt i=0; i<3; i++) {
    inPtr[i] = COWPtr<Array<Float> >
      (new Array<Float>(inSlice.nonDegenerate()));
  };
  Int inp(0);
  Bool isRef;
  ///  IPosition start(4,0);
  IPosition start(imptr_p->shape());
  start = 0;
  // Read first line
  isRef = imptr_p->getSlice(inPtr[inp], Slicer(start, inSlice), True);
  start(1) += 1;
  // Read 2nd line
  isRef = imptr_p->getSlice(inPtr[inp+1], Slicer(start, inSlice), True);
  start(1) += 1;
  // Result
  rs = 0.0;
  // Do all remaining lines
  for (uInt i=2; i<ny; i++) {
    inp++; inp %= 3;
    isRef = imptr_p->getSlice(inPtr[(inp+1)%3],
			      Slicer(start, inSlice), True);
    for (uInt i0=0; i0<nx; i0++) inDone((inp+1)%3, i0) = False;
    start(1) += 1;
    // All points
    for (uInt j=1; j<nx-1; j++) {
      if (inDone(inp, j)) continue;          // point already used
      Double x(inPtr[inp].ref()(IPosition(1, j)));
      if (afind) {                            // find pos/neg
	asign = (x<0) ? -1.0 : 1.0;
	x = abs(x);
      };
      if (x<0.8*mapLim*abs(rs(0,0)) ||
	  x<0.8*abs(rs(N-1,0))) continue;      // too small
      // Make local data field
      Bool xt(False);
      for (Int i0=-1; i0<2; i0++) {
	for (Int i1=-1; i1<2; i1++) {
	  if (inDone((inp+i0+3)%3, j+i1)) {    // already used
	    xt = True;
	    break;
	  };
	  mat[i0+1][i1+1] = inPtr[(inp+i0+3)%3].ref()(IPosition(1, j+i1));
	  mat[i0+1][i1+1] *= asign;            // make abs
	};
	if (xt) break;
      };
      if (xt) continue;
      // test if a local peak
      if (x<=abs(mat[0][1]) ||
	  x<=abs(mat[2][1]) ||
	  x<=abs(mat[1][0]) ||
	  x<=abs(mat[1][2])) continue;
      // Solve general ellipsoid
      fit.set(6);
      for (Int i0=-1; i0<2; i0++) {
	for (Int i1=-1; i1<2; i1++) {
	  gel(0)= 1;
	  gel(1) = i0;
	  gel(2) = i1;
	  gel(3) = i0*i0;
	  gel(4) = i1*i1;
	  gel(5) = i0*i1;
	  fit.makeNorm(gel.data(), 1.0 - 0.5*(abs(i1)+abs(i0)) +
		       0.25*abs(i0*i1),
		       mat[i0+1][i1+1]);
	};
      };
      if (!fit.invert(rank)) continue;         // Cannot solve
      fit.solve(sol);
      // Find max
      Double r1(sol(5)*sol(5) - 4*sol(3)*sol(4));   // dx
      if (r1 == 0) continue;                   // forget
      Double r0((2*sol(2)*sol(3) - sol(1)*sol(5))/r1);  // dy
      r1 = (2*sol(1)*sol(4) - sol(2)*sol(5))/r1;
      if (abs(r0)>1 || abs(r1)>1) continue;    // too far away from peak
      // Amplitude
      sol(0) += sol(1)*r0 + sol(2)*r1 + sol(3)*r0*r0 +
	sol(4)*r1*r1 + sol(5)*r0*r1;
      x = sol(0);
      if (afind) {
	x = abs(x);
	sol(0) = asign*sol(0);
      };
      if (x<mapLim*abs(rs(0,0))) continue;   // too small
      for (Int k=0; k<N; k++) {
	if (x>=rs(k,0)) {
	  for (Int l=N-1; l>k; l--) {
	    for (uInt i0=0; i0<3; i0++) rs(l,i0) = rs(l-1,i0);
	  };
	  rs(k,0) = sol(0);
	  rs(k,1) = i+r1-1;
	  rs(k,2) = j+r0;
	  for (Int l=-1; l<2; l++) {
	    for (Int m=-1; m<2; m++) {
	      inDone((inp+l+3)%3, j+m) = True;
	    };
	  };
	  break;
	};
      };
    };
  };
  // Find the number filled
  Int M(0);
  Double x = mapLim*abs(rs(0,0));
  for (Int i=0; i<N; i++) {
    if (abs(rs(i,0)) < x || rs(i,0) == 0) break;
    M++;
  };
  return M;
}

// DO name
String wnbt::className() const {
  return "wnbt";
}

// Available methods
Vector<String> wnbt::methods() const {
  Vector<String> tmp(9);
  tmp(0)=  "imageph";			// print image header
  tmp(1)=  "imageel";			// get an element
  tmp(2)=  "imageop";			// open image
  tmp(3)=  "imagecl";			// close image
  tmp(4)=  "imagefd";			// find sources
  tmp(5)=  "compdef";			// define update class
  tmp(6)=  "compmak";                   // make update equations
  tmp(7)=  "compsol";                   // solve update equations
  tmp(8)=  "comprem";                   // remove update class

  return tmp;
}

// Untraced methods
Vector<String> wnbt::noTraceMethods() const {
  return methods();
}

// Execute methods
MethodResult wnbt::runMethod(uInt which,
			     ParameterSet &parameters,
			     Bool runMethod) {
  
  static String returnvalName = "returnval";
  static String valName  = "val";
  static String argName  = "arg";
  static String formName = "form";
  static String form2Name= "form2";
  
  String err;
  
  switch (which) {
    
    // imageph
  case 0: {
    Parameter<String> returnval(parameters, returnvalName,
				ParameterSet::Out);
    if (runMethod) {
      if (!imptr_p) return error("No image opened");
      ImageSummary<Float> imsum(*imptr_p);
      LogIO os;
      imsum.list(os);
      returnval() = imsum.name();
    };
  }
  break;
  
  // imageel
  case 1: {
    Parameter<Vector<Int> > arg(parameters, argName,
				ParameterSet::In);
    Parameter<Double> returnval(parameters, returnvalName,
				ParameterSet::Out);
    if (runMethod) {
      if (!imptr_p) return error("No image opened");
      returnval() = imptr_p->getAt(IPosition(arg()));
    };
  }
  break;
  
  // imageop
  case 2: {
    Parameter<String> val(parameters, valName,
			  ParameterSet::In);
    Parameter<String> returnval(parameters, returnvalName,
				ParameterSet::Out);
    if (runMethod) {
      delete imptr_p; imptr_p = 0;
      imptr_p = new PagedImage<Float>(val());
      if (imptr_p) {
	ImageSummary<Float> imsum(*imptr_p);
	returnval() = imsum.name();
      } else {
	return error("Cannot open image");
      };
    };
  }
  break;
  
  // imagecl
  case 3: {
    Parameter<Bool> returnval(parameters, returnvalName,
			      ParameterSet::Out);
    if (runMethod) {
      delete imptr_p; imptr_p = 0;
      returnval() = True;
    };
  }
  break;
  
  // imagefd
  case 4: {
    Parameter<Int> val(parameters, valName,
		       ParameterSet::In);
    Parameter<Double> form(parameters, formName,
			   ParameterSet::In);
    Parameter<Bool> form2(parameters, form2Name,
			  ParameterSet::In);
    Parameter<Array<Double> > returnval(parameters, returnvalName,
					ParameterSet::Out);
    if (runMethod) {
      if (!imptr_p) return error("No image opened");
      returnval().resize();
      Array<Double> rs(IPosition(2, val(), 3));
      Int M = find(rs, form(), form2());
      returnval().resize(IPosition(2,M,3));
      for (uInt i=0; i<3; i++) {
	for (Int j=0; j<M; j++) {
	  IPosition ip(2,j,i);
	  returnval()(ip) = rs(ip);
	};
      };
    };
  }
  break;
  
  // compdef
  case 5: {
    Parameter<String> val(parameters, valName,
			  ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName,
			      ParameterSet::Out);
    if (runMethod) {
      delete cupptr_p; cupptr_p = 0;
      cupptr_p = new ComponentUpdate(ComponentList(Path(val()), True));
      if (!cupptr_p) return error("No component update object");
      returnval() = True;
    };
  }
  break;
  
  // compmak
  case 6: {
    Parameter<Array<DComplex> > val(parameters, valName,
				    ParameterSet::In);
    Parameter<Vector<DComplex> > arg(parameters, argName,
				     ParameterSet::In);
    if (runMethod) {
      if (!cupptr_p) return error("No component update object");
      cupptr_p->makeEquations(val(), arg());
    };
  }
  break;
  
  // compsol
  case 7: {
    Parameter<Array<Double> > val(parameters, valName,
				  ParameterSet::InOut);
    Parameter<Array<Double> > arg(parameters, argName,
				   ParameterSet::InOut);
    Parameter<Bool> returnval(parameters, returnvalName,
			      ParameterSet::Out);
    if (runMethod) {
      if (!cupptr_p) return error("No component update object");
      returnval() = cupptr_p->solve(static_cast<Matrix<Double> &>(val()),
				    static_cast<Matrix<Double> &>(arg()));
    };
  }
  break;
  
  // compref
  case 8: {
    Parameter<Bool> returnval(parameters, returnvalName,
			      ParameterSet::Out);
    if (runMethod) {
      delete cupptr_p; cupptr_p = 0;
      returnval() = True;
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




