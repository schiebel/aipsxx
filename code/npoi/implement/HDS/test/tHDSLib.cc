//# tHDSLib.cc:
//# Copyright (C) 1997,1998,1999,2000,2001
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
//# $Id: tHDSLib.cc,v 19.3 2004/11/30 17:50:40 ddebonis Exp $

#include <npoi/HDS/HDSLib.h>
#include <npoi/HDS/HDSLocator.h>
#include <npoi/HDS/HDSDef.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/Vector.h>
#include <casa/Exceptions/Error.h>
#include <casa/Arrays/IPosition.h>
#include <casa/BasicMath/Math.h>
#include <casa/OS/File.h>
#include <casa/OS/Path.h>
#include <casa/Utilities/Assert.h>
#include <casa/BasicSL/String.h>
#include <casa/iostream.h>
// This include file comes with HDS. It is needed to define F77_xxx_TYPE
#if defined(HAVE_HDS)
#include <f77.h>
#endif

#include <casa/namespace.h>

int main() {
  try {
#if defined(HAVE_HDS)
    { // Check a few fundamental assumptions about data types
      // Used in dat_get1d, dat_getnd
      AlwaysAssert(sizeof(Double) == sizeof(F77_DOUBLE_TYPE), AipsError);
      // Used in dat_get1r, dat_getnr
      AlwaysAssert(sizeof(Float) == sizeof(F77_REAL_TYPE), AipsError);
      // Used in dat_get1i, dat_getni
      AlwaysAssert(sizeof(Int) == sizeof(F77_INTEGER_TYPE), AipsError);
    }
    const IPosition rshape(2,10,3);
    const IPosition ishape(2,1,3);
    const IPosition lshape(3,4,1,1);
    const IPosition dshape(1,2);
    const IPosition cshape(4,2,1,2,1);
    const Double pi = 3.14159265358979323846;
    {

      // Create a default locator;
      HDSLocator loc;
      // Check that it is not valid
      AlwaysAssert(loc.isValid() == False, AipsError);

      Int status = HDSDef::SAI_OK;
      const String fileName = "tHDSLib_tmp";
      const String nodeName = "testData";
      {
 	// Test the hds_new function
 	IPosition shape(0);
 	String nodeType = "DTA";
 	HDSLib::hds_new(fileName, nodeName, nodeType, shape, loc, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	AlwaysAssert(loc.isValid() == True, AipsError);
      }
      {
 	// Test the dat_prmry function
 	Bool set = False, isPrimary;
 	HDSLib::dat_prmry(set, loc, isPrimary, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(loc.isValid() == True, AipsError);
	AlwaysAssert(set == False, AipsError);
	AlwaysAssert(isPrimary == True, AipsError);
      }
      { 
	// test the HDSLocator copy constructor and assignment operator
	// which includes various aspects of the dat_prmry, dat_annul, 
	// dat_clone and dat_valid functions in the HDSLib class.
	HDSLocator loc1(loc);
	AlwaysAssert(loc.isValid() == True, AipsError);
	AlwaysAssert(loc.isPrimary() == True, AipsError);
	AlwaysAssert(loc1.isValid() == True, AipsError);
	AlwaysAssert(loc1.isPrimary() == True, AipsError);
	HDSLib::dat_annul(loc, status);
	AlwaysAssert(loc.isValid() == False, AipsError);
	AlwaysAssert(loc1.isValid() == True, AipsError);
	AlwaysAssert(loc1.isPrimary() == True, AipsError);
	loc = loc1;
	AlwaysAssert(loc.isValid() == True, AipsError);
	AlwaysAssert(loc.isPrimary() == True, AipsError);
	AlwaysAssert(loc1.isValid() == True, AipsError);
	AlwaysAssert(loc1.isPrimary() == True, AipsError);
      }
      {
	// Test the hds_trace function
	String gFileName, gNodePath;
	Int levels;
	HDSLib::hds_trace(loc, levels, gNodePath, gFileName, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(levels == 1, AipsError);
	AlwaysAssert(gNodePath == upcase(nodeName), AipsError);
	File file(gFileName);
	AlwaysAssert(file.path().baseName() == fileName+".sdf", AipsError);
      }
      // Test the hds_state, hds_erase & hds_stop functions
      HDSDef::state currentState;
      HDSLib::hds_state(currentState, status);
      AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
      AlwaysAssert(currentState == HDSDef::ACTIVE, AipsError);

      HDSLib::hds_erase(loc, status);
      AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
      AlwaysAssert(loc.isValid() == False, AipsError);

      HDSLib::hds_stop(status);
      AlwaysAssert(status == HDSDef::SAI_OK, AipsError);

      HDSLib::hds_state(currentState, status);
      AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
      AlwaysAssert(currentState == HDSDef::INACTIVE, AipsError);
    }
    {
      HDSLocator topLoc;
      Int status = HDSDef::SAI_OK;
      const String fileName = "tHDSLib_tmp";
      const String nodeName = "testData";
      {
	// Test the hds_new function
	IPosition shape(2,4,7);
	HDSDef::Type nodeType = HDSDef::REAL;
	HDSLib::hds_new(fileName, nodeName, nodeType, shape, topLoc, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(topLoc.isValid() == True, AipsError);
      }
      {
	// test the dat_cell, dat_get0r & dat_put0r functions.
	HDSLocator cellLoc;
	IPosition which(2, 0);
 	HDSLib::dat_cell(topLoc, which, cellLoc, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	AlwaysAssert(cellLoc.isValid(), AipsError);
 	AlwaysAssert(cellLoc.isPrimary() == False, AipsError);
	Float value = 10.7;
  	HDSLib::dat_put0r(cellLoc, value, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	value = 0.0;
  	HDSLib::dat_get0r(cellLoc, value, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	AlwaysAssert(near(value, 10.7, 1E-5), AipsError);
      }
      HDSLib::hds_erase(topLoc, status);
      AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
      AlwaysAssert(topLoc.isValid() == False, AipsError);
    }
    {
      HDSLocator topLoc;
      Int status = HDSDef::SAI_OK;
      const String fileName = "tHDSLib_tmp";
      {
	// Test the hds_new function
	const String nodeName = fileName;
	const IPosition shape(0);
	const String nodeType = "DATASET";
	HDSLib::hds_new(fileName, nodeName, nodeType, shape, topLoc, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(topLoc.isValid() == True, AipsError);
      }
      {
	// test the dat_new functions
	String nodeName="REAL_ARRAY";
	HDSDef::Type nodeType=HDSDef::REAL;
	HDSLib::dat_new(topLoc, nodeName, nodeType, rshape, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	nodeName = "INTEGER_ARRAY";
	nodeType = HDSDef::INTEGER;
	HDSLib::dat_new(topLoc, nodeName, nodeType, ishape, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	nodeName = "LOGICAL_ARRAY";
	nodeType = HDSDef::LOGICAL;
	HDSLib::dat_new(topLoc, nodeName, nodeType, lshape, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	nodeName = "DOUBLE_ARRAY";
	nodeType = HDSDef::DOUBLE;
	HDSLib::dat_new(topLoc, nodeName, nodeType, dshape, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	nodeName="STRING_ARRAY";
	String stringType="_CHAR*4";
	HDSLib::dat_new(topLoc, nodeName, stringType, cshape, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	{ // test dat_find & dat_cell & dat_put0r & dat_get0r
	  nodeName="REAL_ARRAY";
	  HDSLocator arrLoc;
	  HDSLib::dat_find(topLoc, nodeName, arrLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(arrLoc.isValid() == True, AipsError);

	  HDSLocator firstCellLoc, lastCellLoc;
	  IPosition firstCell(2, 0), lastCell = rshape-1;
	  HDSLib::dat_cell(arrLoc, firstCell, firstCellLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(firstCellLoc.isValid(), AipsError);
	  AlwaysAssert(firstCellLoc.isPrimary() == False, AipsError);
	  Float value = 10.7;
	  HDSLib::dat_put0r(firstCellLoc, value, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);

	  HDSLib::dat_cell(arrLoc, lastCell, lastCellLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(lastCellLoc.isValid(), AipsError);
	  AlwaysAssert(lastCellLoc.isPrimary() == False, AipsError);
	  value = 3.1;
	  HDSLib::dat_put0r(lastCellLoc, value, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);

	  HDSLib::dat_get0r(firstCellLoc, value, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(near(value, 10.7, 1E-5), AipsError);
	  HDSLib::dat_get0r(lastCellLoc, value, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(near(value, 3.1, 1E-5), AipsError);
	}
	{ // test dat_find & dat_cell & dat_put0i & dat_get0i
	  nodeName="INTEGER_ARRAY";
	  HDSLocator intLoc;
	  HDSLib::dat_find(topLoc, nodeName, intLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(intLoc.isValid() == True, AipsError);

	  HDSLocator firstCellLoc, lastCellLoc;
	  IPosition firstCell(2, 0), lastCell = ishape-1;
	  HDSLib::dat_cell(intLoc, firstCell, firstCellLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(firstCellLoc.isValid(), AipsError);
	  AlwaysAssert(firstCellLoc.isPrimary() == False, AipsError);
	  Int ivalue = 10;
	  HDSLib::dat_put0i(firstCellLoc, ivalue, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);

	  HDSLib::dat_cell(intLoc, lastCell, lastCellLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(lastCellLoc.isValid(), AipsError);
	  AlwaysAssert(lastCellLoc.isPrimary() == False, AipsError);
	  ivalue = -3;
	  HDSLib::dat_put0i(lastCellLoc, ivalue, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);

	  HDSLib::dat_get0i(firstCellLoc, ivalue, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(ivalue == 10, AipsError);
	  HDSLib::dat_get0i(lastCellLoc, ivalue, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(ivalue == -3, AipsError);
	}
	{ // test dat_find & dat_cell & dat_put0l & dat_get0l
	  nodeName="LOGICAL_ARRAY";
	  HDSLocator arrLoc;
	  HDSLib::dat_find(topLoc, nodeName, arrLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(arrLoc.isValid() == True, AipsError);

	  HDSLocator firstCellLoc, lastCellLoc;
	  IPosition firstCell(3, 0), lastCell = lshape-1;
	  HDSLib::dat_cell(arrLoc, firstCell, firstCellLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(firstCellLoc.isValid(), AipsError);
	  AlwaysAssert(firstCellLoc.isPrimary() == False, AipsError);
	  Bool value = True;
	  HDSLib::dat_put0l(firstCellLoc, value, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);

	  HDSLib::dat_cell(arrLoc, lastCell, lastCellLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(lastCellLoc.isValid(), AipsError);
	  AlwaysAssert(lastCellLoc.isPrimary() == False, AipsError);
	  value = False;
	  HDSLib::dat_put0l(lastCellLoc, value, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);

	  HDSLib::dat_get0l(firstCellLoc, value, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(value == True, AipsError);
	  HDSLib::dat_get0l(lastCellLoc, value, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(value == False, AipsError);
	}
	{ // test dat_find & dat_cell & dat_put0d & dat_get0d
	  nodeName="DOUBLE_ARRAY";
	  HDSLocator arrLoc;
	  HDSLib::dat_find(topLoc, nodeName, arrLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(arrLoc.isValid() == True, AipsError);

	  HDSLocator firstCellLoc, lastCellLoc;
	  IPosition firstCell(1, 0), lastCell = dshape-1;
	  HDSLib::dat_cell(arrLoc, firstCell, firstCellLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(firstCellLoc.isValid(), AipsError);
	  AlwaysAssert(firstCellLoc.isPrimary() == False, AipsError);
	  Double value = pi;
	  HDSLib::dat_put0d(firstCellLoc, value, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);

	  HDSLib::dat_cell(arrLoc, lastCell, lastCellLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(lastCellLoc.isValid(), AipsError);
	  AlwaysAssert(lastCellLoc.isPrimary() == False, AipsError);
	  value = -pi;
	  HDSLib::dat_put0d(lastCellLoc, value, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);

	  HDSLib::dat_get0d(firstCellLoc, value, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(near(value, pi, 1E-15), AipsError);
	  HDSLib::dat_get0d(lastCellLoc, value, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(near(value, -pi, 1E-15), AipsError);
	}
	{ // test dat_find & dat_cell & dat_put0c & dat_get0c
	  nodeName="STRING_ARRAY";
	  HDSLocator arrLoc;
	  HDSLib::dat_find(topLoc, nodeName, arrLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(arrLoc.isValid() == True, AipsError);

 	  HDSLocator firstCellLoc, lastCellLoc;
 	  IPosition firstCell(4, 0), lastCell = cshape-1;
 	  HDSLib::dat_cell(arrLoc, firstCell, firstCellLoc, status);
 	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	  AlwaysAssert(firstCellLoc.isValid(), AipsError);
 	  AlwaysAssert(firstCellLoc.isPrimary() == False, AipsError);
 	  String value = "to";
 	  HDSLib::dat_put0c(firstCellLoc, value, status);
 	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);

 	  HDSLib::dat_cell(arrLoc, lastCell, lastCellLoc, status);
 	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	  AlwaysAssert(lastCellLoc.isValid(), AipsError);
 	  AlwaysAssert(lastCellLoc.isPrimary() == False, AipsError);
 	  value = "1234";
 	  HDSLib::dat_put0c(lastCellLoc, value, status);
 	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);

 	  HDSLib::dat_get0c(firstCellLoc, value, status);
 	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	  AlwaysAssert(value == "to", AipsError);
 	  HDSLib::dat_get0c(lastCellLoc, value, status);
 	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	  AlwaysAssert(value == "1234", AipsError);
	}
      }
      { // test the dat_new0d function
	String thisNodeName="DOUBLE_SCALAR";
	HDSLib::dat_new0d(topLoc, thisNodeName, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	HDSLocator scalarLoc;
	HDSLib::dat_find(topLoc, thisNodeName, scalarLoc, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(scalarLoc.isValid() == True, AipsError);
	const Double value = 3.14159265358979323846;
	HDSLib::dat_put0d(scalarLoc, value, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	Double hdsValue = 0.0;
	HDSLib::dat_get0d(scalarLoc, hdsValue, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(near(value, hdsValue, 1E-13), AipsError);
      }
      { // test the dat_new0i function
	String thisNodeName="INTEGER_SCALAR";
	HDSLib::dat_new0i(topLoc, thisNodeName, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	HDSLocator scalarLoc;
	HDSLib::dat_find(topLoc, thisNodeName, scalarLoc, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(scalarLoc.isValid() == True, AipsError);
	const Int value = 3;
	HDSLib::dat_put0i(scalarLoc, value, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	Int hdsValue = 0;
	HDSLib::dat_get0i(scalarLoc, hdsValue, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(value == hdsValue, AipsError);
      }
      { // test the dat_new0l function
	String thisNodeName="LOGICAL_SCALAR";
	HDSLib::dat_new0l(topLoc, thisNodeName, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	HDSLocator scalarLoc;
	HDSLib::dat_find(topLoc, thisNodeName, scalarLoc, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(scalarLoc.isValid() == True, AipsError);
	const Bool value = True;
	HDSLib::dat_put0l(scalarLoc, value, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	Bool hdsValue = False;
	HDSLib::dat_get0l(scalarLoc, hdsValue, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(value == hdsValue, AipsError);
      }
      { // test the dat_new0r function
	String thisNodeName="REAL_SCALAR";
	HDSLib::dat_new0r(topLoc, thisNodeName, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	HDSLocator scalarLoc;
	HDSLib::dat_find(topLoc, thisNodeName, scalarLoc, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(scalarLoc.isValid() == True, AipsError);
	const Float value = 3.1415;
	HDSLib::dat_put0r(scalarLoc, value, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	Float hdsValue = 0.0f;
	HDSLib::dat_get0r(scalarLoc, hdsValue, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(value == hdsValue, AipsError);
      }
      { // test the dat_new0c function
	String thisNodeName="CHAR*4_SCALAR";
	HDSLib::dat_new0c(topLoc, thisNodeName, 4, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	HDSLocator scalarLoc;
	HDSLib::dat_find(topLoc, thisNodeName, scalarLoc, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(scalarLoc.isValid() == True, AipsError);
	const String value = "abcd";
	HDSLib::dat_put0c(scalarLoc, value, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	String hdsValue = "";
	HDSLib::dat_get0c(scalarLoc, hdsValue, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	AlwaysAssert(value == hdsValue, AipsError);
      }
      { // test the dat_new1d, dat_get1d, dat_put1d, dat_size, dat_shape
	// functions
	String thisNodeName="DOUBLE_VECTOR";
	const Int length = 7;
 	HDSLib::dat_new1d(topLoc, thisNodeName, length, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	HDSLocator vecLoc;
 	HDSLib::dat_find(topLoc, thisNodeName, vecLoc, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	AlwaysAssert(vecLoc.isValid() == True, AipsError);
 	Vector<Double> values(length);
	indgen(values);
 	HDSLib::dat_put1d(vecLoc, values, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	Int hdsLength = 0;
	HDSLib::dat_size(vecLoc, hdsLength, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	AlwaysAssert(length == hdsLength, AipsError);
	IPosition hdsShape;
	HDSLib::dat_shape(vecLoc, hdsShape, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	AlwaysAssert(hdsShape.nelements() == 1, AipsError);
 	AlwaysAssert(hdsShape(0) == length, AipsError);
 	Vector<Double> hdsValues;
  	HDSLib::dat_get1d(vecLoc, hdsValues, status);
  	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
  	AlwaysAssert(allNear(values, hdsValues, 1E-13), AipsError);
      }
      { // test the dat_new1i, dat_get1i, dat_put1i functions
	String thisNodeName="INTEGER_VECTOR";
	const uInt length = 6;
 	HDSLib::dat_new1i(topLoc, thisNodeName, length, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	HDSLocator vecLoc;
 	HDSLib::dat_find(topLoc, thisNodeName, vecLoc, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	AlwaysAssert(vecLoc.isValid() == True, AipsError);
 	Vector<Int> values(length);
	indgen(values);
 	HDSLib::dat_put1i(vecLoc, values, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	Vector<Int> hdsValues;
  	HDSLib::dat_get1i(vecLoc, hdsValues, status);
  	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
  	AlwaysAssert(allEQ(values, hdsValues), AipsError);
      }
      { // test the dat_new1l, dat_get1l, dat_put1l functions
	String thisNodeName="LOGICAL_VECTOR";
	const uInt length = 2;
 	HDSLib::dat_new1l(topLoc, thisNodeName, length, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	HDSLocator vecLoc;
 	HDSLib::dat_find(topLoc, thisNodeName, vecLoc, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	AlwaysAssert(vecLoc.isValid() == True, AipsError);
 	Vector<Bool> values(length);
	values(0) = True;
	values(1) = False;
 	HDSLib::dat_put1l(vecLoc, values, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	Vector<Bool> hdsValues;
  	HDSLib::dat_get1l(vecLoc, hdsValues, status);
  	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
  	AlwaysAssert(allEQ(values, hdsValues), AipsError);
      }
      { // test the dat_new1r, dat_get1r, dat_put1r functions
	String thisNodeName="REAL_VECTOR";
	const uInt length = 3;
 	HDSLib::dat_new1r(topLoc, thisNodeName, length, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	HDSLocator vecLoc;
 	HDSLib::dat_find(topLoc, thisNodeName, vecLoc, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	AlwaysAssert(vecLoc.isValid() == True, AipsError);
 	Vector<Float> values(length);
	indgen(values);
 	HDSLib::dat_put1r(vecLoc, values, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	Vector<Float> hdsValues;
  	HDSLib::dat_get1r(vecLoc, hdsValues, status);
  	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
  	AlwaysAssert(allNear(values, hdsValues, 1E-6), AipsError);
      }
      { // test the dat_new1c, dat_get1c, dat_put1c, dat_len functions
	String thisNodeName="STRING_VECTOR";
	const Int length = 2;
	const Int stringLength = 4;
 	HDSLib::dat_new1c(topLoc, thisNodeName, stringLength, length, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	HDSLocator vecLoc;
 	HDSLib::dat_find(topLoc, thisNodeName, vecLoc, status);
 	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	AlwaysAssert(vecLoc.isValid() == True, AipsError);
	Int hdsStringLen = 0;
	HDSLib::dat_len(vecLoc, hdsStringLen, status);
  	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
  	AlwaysAssert(hdsStringLen == stringLength, AipsError);
  	Vector<String> values(length);
	values(0) = "abcd";
	values(1) = "123";
  	HDSLib::dat_put1c(vecLoc, values, status);
  	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
  	Vector<String> hdsValues;
   	HDSLib::dat_get1c(vecLoc, hdsValues, status);
   	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
   	AlwaysAssert(allEQ(values, hdsValues), AipsError);
      }
      { // test the hds_show function. As far as I can see these functions do
 	// not produce any output so I do not know what they actually do!
	HDSLib::hds_show(HDSDef::DATA, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	HDSLib::hds_show(HDSDef::FILES, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	HDSLib::hds_show(HDSDef::LOCATORS, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
      }
    }
    {
      const String fileName = "tHDSLib_tmp";
      Int status = HDSDef::SAI_OK;
      HDSLocator topLoc;
      { // test the hds_open function
	HDSLib::hds_open(fileName, HDSDef::UPDATE, topLoc, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(topLoc.isValid() == True, AipsError);
	AlwaysAssert(topLoc.isPrimary() == True, AipsError);
      }
      { // test the dat_struc function
	Bool isAstruc = False;
	HDSLib::dat_struc(topLoc, isAstruc, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(isAstruc == True, AipsError);
      }
      const String topNodeName = upcase(fileName);
      { // test the dat_name function
	String name="";
	HDSLib::dat_name(topLoc, name, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(name.matches(topNodeName), AipsError);
      }
      const String topNodeType = "DATASET";
      { // test the dat_type function
	String type="";
	HDSLib::dat_type(topLoc, type, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(type.matches(topNodeType), AipsError);
      }
      const Int ntopComponents = 15;
      { // test the dat_ncomp function
	Int nComp = 0;
	HDSLib::dat_ncomp(topLoc, nComp, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(nComp == ntopComponents, AipsError);
      }
      { // test the dat_index and alternate dat_type functions
	HDSLocator nodeLoc;
	String name = "";
	HDSDef::Type type = HDSDef::STRUCTURE;
	Bool isAstruc = True;
	for (Int i = 1; i <= ntopComponents; i++) {
	  HDSLib::dat_index(topLoc, i, nodeLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(nodeLoc.isValid() == True, AipsError);
	  HDSLib::dat_name(nodeLoc, name, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(name.contains("_ARRAY") ||
		       name.contains("_SCALAR") ||
		       name.contains("VECTOR"), AipsError);
	  HDSLib::dat_type(nodeLoc, type, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(type != HDSDef::STRUCTURE, AipsError);
	  HDSLib::dat_struc(nodeLoc, isAstruc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(isAstruc == False, AipsError);
// 	  String structureName = "STRUCTURE";
//  	  if (!isAstruc) structureName = "PRIMITIVE";
// 	  cout << "Name:" << name << "\tType:" << HDSDef::name(type)
// 	       << "\t(" << structureName << ")" << endl;
 	}
	// test the dat_paren function
	HDSLocator parentLoc;
	HDSLib::dat_paren(nodeLoc, parentLoc, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(parentLoc.isValid() == True, AipsError);
	HDSLib::dat_name(parentLoc, name, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(name.matches(topNodeName), AipsError);
	// test the dat_there function
	Bool exists = False;
	HDSLib::dat_there(parentLoc, String("REAL_ARRAY"), exists, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(exists == True, AipsError);
	// test the dat_state function
	Bool isDefined = False;
	HDSLib::dat_state(nodeLoc, isDefined, status);
	AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	AlwaysAssert(isDefined == True, AipsError);
	{ // test the dat_getnr function
	  HDSLocator arrLoc;
	  const String arrName = "REAL_ARRAY";
	  HDSLib::dat_find(topLoc, arrName, arrLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(arrLoc.isValid() == True, AipsError);
	  Array<Float> arr;
	  HDSLib::dat_getnr(arrLoc, arr, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(arr.shape().isEqual(rshape), AipsError);
	  AlwaysAssert(near(arr(rshape*0), 10.7, 1E-5), AipsError);
	  AlwaysAssert(near(arr(rshape-1), 3.1, 1E-5), AipsError);
	}
	{ // test the dat_getnd function
	  HDSLocator arrLoc;
	  const String arrName = "DOUBLE_ARRAY";
	  HDSLib::dat_find(topLoc, arrName, arrLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(arrLoc.isValid() == True, AipsError);
	  Array<Double> arr;
	  HDSLib::dat_getnd(arrLoc, arr, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(arr.shape().isEqual(dshape), AipsError);
	  AlwaysAssert(near(arr(dshape*0), pi, 1E-15), AipsError);
	  AlwaysAssert(near(arr(dshape-1), -pi, 1E-15), AipsError);
	}
	{ // test the dat_getni function
	  HDSLocator arrLoc;
	  const String arrName = "INTEGER_ARRAY";
	  HDSLib::dat_find(topLoc, arrName, arrLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(arrLoc.isValid() == True, AipsError);
	  Array<Int> arr;
 	  HDSLib::dat_getni(arrLoc, arr, status);
 	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
 	  AlwaysAssert(arr.shape().isEqual(ishape), AipsError);
 	  AlwaysAssert(arr(ishape*0) == 10, AipsError);
 	  AlwaysAssert(arr(ishape-1) == -3, AipsError);
	}
	{ // test the dat_getnl function
	  HDSLocator arrLoc;
	  const String arrName = "LOGICAL_ARRAY";
	  HDSLib::dat_find(topLoc, arrName, arrLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(arrLoc.isValid() == True, AipsError);
	  Array<Bool> arr;
  	  HDSLib::dat_getnl(arrLoc, arr, status);
  	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
  	  AlwaysAssert(arr.shape().isEqual(lshape), AipsError);
   	  AlwaysAssert(arr(lshape*0) == True, AipsError);
   	  AlwaysAssert(arr(lshape-1) == False, AipsError);
	}
	{ // test the dat_getnc function
	  HDSLocator arrLoc;
	  const String arrName = "STRING_ARRAY";
	  HDSLib::dat_find(topLoc, arrName, arrLoc, status);
	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
	  AlwaysAssert(arrLoc.isValid() == True, AipsError);
	  Array<String> arr;
   	  HDSLib::dat_getnc(arrLoc, arr, status);
   	  AlwaysAssert(status == HDSDef::SAI_OK, AipsError);
   	  AlwaysAssert(arr.shape().isEqual(cshape), AipsError);
    	  AlwaysAssert(arr(cshape*0) == "to", AipsError);
    	  AlwaysAssert(arr(cshape-1) == "1234", AipsError);
	}
      }
    }
#endif
  }
  catch (AipsError x) {
    cerr << x.getMesg() << endl;
    cout << "FAIL" << endl;
    return 1;
  } 
  cout << "OK" << endl;
  return 0;
}
// Local Variables: 
// compile-command: "gmake OPTLIB=1 tHDSLib"
// End: 
