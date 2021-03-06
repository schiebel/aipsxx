//# tArrayIO3.cc: This program tests the ArrayIO istream extract  functions
//# Copyright (C) 1993,1994,1995,1996,1997,1999,2000,2002,2003
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
//# $Id: tArrayIO3.cc,v 19.5 2004/11/30 17:50:14 ddebonis Exp $

//# Includes
#include <casa/Exceptions/Error.h>
#include <casa/Arrays/ArrayIO.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Cube.h>
#include <casa/BasicSL/String.h>
#include <casa/Quanta/Quantum.h>
#include <casa/sstream.h>


#include <casa/namespace.h>
// This test program tests the ArrayIO istream extract functions.
// It reads from stdin (the test version from tArraIO3.in) and prints
// the result.

int main (int argc)
{
    try {
	Array<Double> a;
	Matrix<Double> m;
	Array<Quantity> q;
	Array<String> as;
	cout << "Input Array [1 2 3 4 5 6] " << endl;
	cout << "--------------------------------------" << endl;
	cin >> a;
	cout << a << endl;
	cout << "Input Array {[2 3]}[1 2 3 4 5 6] " << endl;
	cout << "--------------------------------------" << endl;
	cin >> a;
	cout << a << endl;
	cout << "Input Array {t[2 3]}[1 2 3 4 5 6] " << endl;
	cout << "--------------------------------------" << endl;
	cin >> a;
	cout << a << endl;
	cout << "Input Matrix [1 2 3 4 5 6] " << endl;
	cout << "--------------------------------------" << endl;
	cin >> (m);
	cout << (m) << endl;
	cout << "Input Matrix {[2 3]}[1 2 3 4 5 6] " << endl;
	cout << "--------------------------------------" << endl;
	cin >> (m);
	cout << (m) << endl;
	cout << "Input Vector [1s 5.4Jy 92pc/a ] " << endl;
	cout << "--------------------------------------" << endl;
	cin >> q;
	cout << q << endl;
	cout << "Input Array [x,y,x] " << endl;
	cout << "--------------------------------------" << endl;
	cin >> as;
	cout << as << endl;
	istringstream ins("[x, y]");
	cout << "Input Array [x, y] " << endl;
	cout << "--------------------------------------" << endl;
	ins >> as;
	cout << as << endl;
    } catch (AipsError x) {
	cout << "\nCaught an exception: " << x.getMesg() << endl;
        return 1;
    } 
    cout << "end" << endl;
    return 0;                       // successfully executed
}
