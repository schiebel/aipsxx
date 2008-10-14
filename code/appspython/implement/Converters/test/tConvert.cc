//# pycasatable.cc: python module for AIPS++ table system
//# Copyright (C) 2006
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
//# $Id: tConvert.cc,v 1.3 2006/09/29 02:46:59 gvandiep Exp $

#include <appspython/Converters/PycExcp.h>
#include <appspython/Converters/PycBasicData.h>
#include <appspython/Converters/PycValueHolder.h>
#include <appspython/Converters/PycRecord.h>
#include <appspython/Converters/PycArray.h>
#include <casa/Arrays/ArrayIO.h>

#include <boost/python.hpp>

using namespace boost::python;

namespace casa { namespace appspython {

  struct TConvert
  {
    TConvert() {}
    Bool  testbool (Bool in)
      {cout << "bool " << in << endl; return in;}
    Int testint (Int in)
      {cout << "Int " << in << endl; return in;}
    Double testfloat (Float in)
      {cout << "Float " << in << endl; return in;}
    DComplex testcomplex (const DComplex& in)
      {cout << "DComplex " << in << endl; return in;}
    String teststring (const String& in)
      {cout << "String " << in << endl; String out=in; return out;}
    Record testrecord (const Record& in)
      {cout << "Record " << in.nfields() << endl; return in;}
    ValueHolder testvh (const ValueHolder& in)
      {cout << "VH " << in.dataType() << endl; return in;}
    Vector<Int> testvecint (const Vector<int>& in)
      {cout << "VecInt " << in << endl; return in;}
    Vector<DComplex> testveccomplex (const Vector<DComplex>& in)
      {cout << "VecComplex " << in << endl; return in;}
    Vector<String> testvecstr (const Vector<String>& in)
      {cout << "VecStr " << in << endl; return in;}
    IPosition testipos (const IPosition& in)
      {cout << "IPos " << in << endl; return in;}
  };


  void testConvert()
  {
    class_<TConvert> ("tConvert", init<>())
      .def ("testbool",       &TConvert::testbool)
      .def ("testint",        &TConvert::testint)
      .def ("testfloat",      &TConvert::testfloat)
      .def ("testcomplex",    &TConvert::testcomplex)
      .def ("teststring",     &TConvert::teststring)
      .def ("testrecord",     &TConvert::testrecord)
      .def ("testvh",         &TConvert::testvh)
      .def ("testvecint",     &TConvert::testvecint)
      .def ("testveccomplex", &TConvert::testveccomplex)
      .def ("testvecstr",     &TConvert::testvecstr)
      .def ("testipos",       &TConvert::testipos)
      ;
  }

}}


BOOST_PYTHON_MODULE(_tConvert)
{
  casa::appspython::register_convert_excp();
  casa::appspython::register_convert_casa_string();
  casa::appspython::register_convert_casa_vector<casa::String>();
  casa::appspython::register_convert_casa_vector<casa::DComplex>();
  casa::appspython::register_convert_casa_vector<casa::Int>();
  casa::appspython::register_convert_casa_iposition();
  casa::appspython::register_convert_casa_valueholder();
  casa::appspython::register_convert_casa_record();

  casa::appspython::testConvert();
}
