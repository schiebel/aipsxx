//# PycArray.cc: Class to convert an Array to/from Python
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
//# $Id: PycArray.cc,v 1.2 2006/09/22 01:02:34 gvandiep Exp $

#include <appspython/Converters/PycArray.tcc>
#include <appspython/Converters/PycBasicData.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Exceptions/Error.h>
#include <boost/python/dict.hpp>

using namespace boost::python;

namespace casa { namespace appspython {

  void importNumAPI()
  {
    // if the PyArray API not loaded, then load it.
    if( !PyArray_API ) {
      import_array();
    }
    if( PyArray_API==0 ) {
      throw AipsError ("PycArray: failed to load the Numarray API");
    }
  }

  Bool PycArrayCheck (PyObject* obj_ptr)
  {
    importAPI();
    return PyArray_Check (obj_ptr);
  }

  template <>
  boost::python::object makePyArrayObject (casa::Array<String> const& arr)
  {
    boost::python::object a = to_tuple< Array<String> >::makeobject (arr);
    if (arr.ndim() == 1) {
      return a;
    }
    boost::python::dict d;
    d.setdefault (std::string("shape"),
		  to_tuple<IPosition>::makeobject (arr.shape()));
    d.setdefault (std::string("array"), a);
    return d;
  }

  ValueHolder casa_array_from_python::makeArray (PyObject* obj_ptr)
  {
    if (! PycArrayCheck(obj_ptr)) {
      throw AipsError ("PycArray: python object is not an array");
    }
    PyArrayObject* po = (PyArrayObject*)obj_ptr;
    if (! PyArray_ISCONTIGUOUS(po)) {
      throw AipsError ("PycArray: input numarray has to be contiguous");
    }
    if (! PyArray_ISALIGNED(po)) {
      throw AipsError ("PycArray: input numarray has to be aligned");
    }
    if (PyArray_ISBYTESWAPPED(po)) {
      throw AipsError ("PycArray: input numarray cannot have swapped bytes");
    }
    // Swap axes, because AIPS++ has row minor and Python row major order.
    int nd = po->nd;
    IPosition shp(nd);
    for (int i=0; i<nd; i++) {
      shp[i] = po->dimensions[nd-i-1];
    }
    // Create the correct array.
    switch (po->descr->type_num) {
    case PyArray_CHAR:
      return ValueHolder (ArrayCopy<Bool>::toArray(shp, po->data));
    case PyArray_USHORT:
      return ValueHolder (ArrayCopy<uShort>::toArray(shp, po->data));
    case PyArray_SHORT:
      return ValueHolder (ArrayCopy<Short>::toArray(shp, po->data));
    case PyArray_INT:
      return ValueHolder (ArrayCopy<Int>::toArray(shp, po->data));
    case PyArray_UINT:
      return ValueHolder (ArrayCopy<uInt>::toArray(shp, po->data));
    case PyArray_FLOAT:
      return ValueHolder (ArrayCopy<Float>::toArray(shp, po->data));
    case PyArray_DOUBLE:
      return ValueHolder (ArrayCopy<Double>::toArray(shp, po->data));
    case PyArray_CFLOAT:
      return ValueHolder (ArrayCopy<Complex>::toArray(shp, po->data));
    case PyArray_CDOUBLE:
      return ValueHolder (ArrayCopy<DComplex>::toArray(shp, po->data));
    case PyArray_OBJECT:
      return ValueHolder (ArrayCopy<String>::toArray(shp, po->data));
    default:
      // PyArray_INT and LONG are the same on 32-bit machines, so LONG
      // cannot be used in the switch (compiler complains).
      if (po->descr->type_num == PyArray_LONG) {
	Array<Long> arr = ArrayCopy<Long>::toArray(shp, po->data);
	if (sizeof(Long) == sizeof(Int)) {
	  return ValueHolder((Array<Int>&)arr);
	}
	Array<Int> res(arr.shape());
	convertArray (res, arr);
	return ValueHolder(res);
      }
      break;
    }
    throw AipsError ("PycArray: unknown python array data type");
  } 

  ValueHolder casa_array_from_python::makeArrayFromDict (PyObject* obj_ptr)
  {
    if (! PyDict_Check(obj_ptr)) {
      throw AipsError ("PycArray: python object is not a dict");
    }
    dict d = extract<dict>(obj_ptr)();
    IPosition shp = extract<IPosition>(d.get("shape").ptr())();
    Array<String> arr = extract<Vector<String> >(d.get("array").ptr())();
    if (Int(arr.size()) != shp.product()) {
      throw AipsError("PycArray: array size mismatches the shape");
    }
    return ValueHolder(arr.reform (shp));
  } 


  template boost::python::object makePyArrayObject
    (casa::Array<Bool> const& arr);
  template boost::python::object makePyArrayObject
    (casa::Array<uChar> const& arr);
  template boost::python::object makePyArrayObject
    (casa::Array<Short> const& arr);
  template boost::python::object makePyArrayObject
    (casa::Array<uShort> const& arr);
  template boost::python::object makePyArrayObject
    (casa::Array<Int> const& arr);
  template boost::python::object makePyArrayObject
    (casa::Array<uInt> const& arr);
  template boost::python::object makePyArrayObject
    (casa::Array<Float> const& arr);
  template boost::python::object makePyArrayObject
    (casa::Array<Double> const& arr);
  template boost::python::object makePyArrayObject
    (casa::Array<Complex> const& arr);
  template boost::python::object makePyArrayObject
    (casa::Array<DComplex> const& arr);

}}

// Instantiate a casa template.
#include <casa/Arrays/ArrayMath.cc>
namespace casa {
  template void convertArray (Array<Int>&, const Array<Long>&);
}
