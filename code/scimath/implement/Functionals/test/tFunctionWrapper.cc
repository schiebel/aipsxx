//# tFunctionWrapper.cc: Test function wrappers
//# Copyright (C) 2001,2002
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: tFunctionWrapper.cc,v 19.4 2004/11/30 17:50:45 ddebonis Exp $

#include <scimath/Functionals/FunctionWrapper.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayIO.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/ArrayMath.h>
#include <scimath/Functionals/CombiFunction.h>
#include <casa/BasicMath/Math.h>
#include <casa/Utilities/Assert.h>

#include <casa/iostream.h>

#include <casa/namespace.h>
// Some C++ functions
static Double func0(const Vector<Double> &) {return 1;};            // 1
static Double func1(const Vector<Double> &x) {return x(0);};         // x
static Double func2(const Vector<Double> &x) {return sin(x(1));};    // sin(y)
static Double func3(const Vector<Double> &x) {return x(0)*x(0);};    // x^2
/*static void myfnc(Vector<Double> &y, const Double x) {
  y(0) = 1;
  for (uInt i=1; i<y.nelements(); i++) y(i) = y(i-1)*x; };
*/

int main() {
//************ test one ****************
  {    
    // Convert C++ functions to Functionals
    FunctionWrapper<Double> Func0(func0,2);
    FunctionWrapper<Double> Func1(func1,2);
    FunctionWrapper<Double> Func2(func2,2);
    FunctionWrapper<Double> Func3(func3,2);
    
    CombiFunction<Double> combination;
    
    // form linear combination of functions
    // f(x,y) = a0 + a1*x+ a2*sin(y) + a3*x*x
    Vector<Double> z0(2);
    z0[0] = 2; z0[1] = 3;
    combination.addFunction(Func0);
    combination.addFunction(Func1);
    combination.addFunction(Func2);
    combination.addFunction(Func3);
    
    // Now use this combination to generate some fake data
    combination[0] = 4;
    combination[1] = 5;
    combination[2] = 6;
    combination[3] = 0.2;
    
    cout << "******* test one *************" << endl;
    cout << "Combination: " << endl;
    cout << 4+5*z0[0]+6*sin(z0[1])+0.2*z0[0]*z0[0] << ", " <<
      combination(z0) << endl;
    AlwaysAssertExit(near(4+5*z0[0]+6*sin(z0[1])+0.2*z0[0]*z0[0],
			  combination(z0)));

  }
  cout << "OK" << endl;
  return 0;
}
