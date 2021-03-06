//# tRecordGram.cc: Test program for the expression grammar on a table
//# Copyright (C) 2004
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
//# $Id: tRecordGramTable.cc,v 19.3 2004/12/07 21:12:11 wyoung Exp $

#include <tables/Tables/RecordGram.h>
#include <tables/Tables/ExprNode.h>
#include <tables/Tables/Table.h>
#include <casa/System/Aipsrc.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Utilities/Assert.h>
#include <casa/iostream.h>

#include <casa/namespace.h>

// <summary>
// Test program for the expression grammar on a table.
// </summary>

// This program tests the class RecordGram to do expressions on a table.


void doIt (const String& str)
{
  String root = Aipsrc::aipsRoot();
  String name = root + "/data/demo/Tables/tTable_2.data_v0";
  Table tab(name);
  TableExprNode expr = RecordGram::parse (tab, str);
  cout << str << ": ";
  if (expr.isScalar()) {
    switch (expr.getColumnDataType()) {
    case TpBool:
      cout << expr.getColumnBool();
      break;
    case TpUChar:
      cout << expr.getColumnuChar();
      break;
    case TpShort:
      cout << expr.getColumnShort();
      break;
    case TpUShort:
      cout << expr.getColumnuShort();
      break;
    case TpInt:
      cout << expr.getColumnInt();
      break;
    case TpUInt:
      cout << expr.getColumnuInt();
      break;
    case TpFloat:
      cout << expr.getColumnFloat();
      break;
    case TpDouble:
      cout << expr.getColumnDouble();
      break;
    case TpComplex:
      cout << expr.getColumnComplex();
      break;
    case TpDComplex:
      cout << expr.getColumnDComplex();
      break;
    case TpString:
      cout << expr.getColumnString();
      break;
    default:
      cout << "Unknown expression scalar type " << expr.getColumnDataType();
    }
    cout << endl;
  } else {
    for (uInt i=0; i<tab.nrow(); i++) {
      cout << "  row " << i << ":" << endl;
      switch (expr.dataType()) {
      case TpBool:
	{
	  Array<Bool> arr;
	  expr.get (i, arr);
	  cout << arr;
	  break;
	}
      case TpDouble:
	{
	  Array<Double> arr;
	  expr.get (i, arr);
	  cout << arr;
	  break;
	}
      case TpDComplex:
	{
	  Array<DComplex> arr;
	  expr.get (i, arr);
	  cout << arr;
	  break;
	}
      case TpString:
	{
	  Array<String> arr;
	  expr.get (i, arr);
	  cout << arr;
	  break;
	}
      default:
	cout << "Unknown expression array type " << expr.dataType();
      }
    }
  }
}

// Ask and execute command till empty string is given.
void docomm()
{
  char comm[1025];
  while (True) {
    cout << "Table command (q=quit): ";
    cin.getline (comm, 1024);
    String str(comm);
    if (str.empty()  ||  str == "q") 
      break;
    try {
      doIt (str);
    } catch (AipsError& x) {
      cout << x.getMesg() << endl;
    } 
  }
}

int main (int argc, const char* argv[])
{
  if (argc < 2) {
    docomm();
    exit(0);
  }
  try {
    doIt(argv[1]);
  } catch (AipsError x) {
    cout << "Unexpected exception: " << x.getMesg() << endl;
    exit(1);
  } catch (...) {
    cout << "Unexpected unknown exception" << endl;
    exit(1);
  }
  exit(0);
}
