//# PycArray.h: Class to convert an Array to/from Python
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
//# $Id: PycArray.h,v 1.1 2006/09/18 04:12:04 gvandiep Exp $


#ifndef APPSPYTHON_PYCARRAY_H
#define APPSPYTHON_PYCARRAY_H

//# Includes
#include <casa/Arrays/Array.h>
#include <casa/Containers/ValueHolder.h>
#include <casa/Exceptions/Error.h>
#include <boost/python.hpp>
#include <boost/python/object.hpp>
#include <numarray/arrayobject.h>
#include <string.h>                    //# for memcpy
#include <iostream>

namespace casa { namespace appspython {


  // <summary>
  // A class to convert an Array to/from Python objects.
  // </summary>

  // <use visibility=export>
  // <reviewed reviewer="" date="" tests="">
  // </reviewed>

  // <synopsis>
  // </synopsis>

  template <typename T> struct TypeConvTraits {
    typedef T     casa_type;
    typedef void* python_type;
    static PyArray_TYPES pyType()
      { throw AipsError ("PycArray: unknown type"); }
  };
  template <> struct TypeConvTraits<Bool> {
    typedef casa::Bool casa_type;
    typedef ::Bool     python_type;
    static PyArray_TYPES pyType() { return PyArray_CHAR; }
  };
  template <> struct TypeConvTraits<uChar> {
    typedef casa::uChar  casa_type;
    typedef ::UInt16     python_type;            // Note: uInt8 is Bool
    static PyArray_TYPES pyType() { return PyArray_USHORT; }
  };
  template <> struct TypeConvTraits<Short> {
    typedef casa::Short casa_type;
    typedef ::Int16     python_type;
    static PyArray_TYPES pyType() { return PyArray_SHORT; }
  };
  template <> struct TypeConvTraits<uShort> {
    typedef casa::uShort casa_type;
    typedef ::UInt16     python_type;
    static PyArray_TYPES pyType() { return PyArray_USHORT; }
  };
  template <> struct TypeConvTraits<Int> {
    typedef casa::Int casa_type;
    typedef ::Int32   python_type;
    static PyArray_TYPES pyType() { return PyArray_INT; }
  };
  template <> struct TypeConvTraits<uInt> {
    typedef casa::uInt casa_type;
    typedef ::UInt32   python_type;
    static PyArray_TYPES pyType() { return PyArray_UINT; }
  };
  template <> struct TypeConvTraits<Long> {
    typedef casa::Long casa_type;
    typedef ::Long    python_type;
    static PyArray_TYPES pyType() { return PyArray_LONG; }
  };
  template <> struct TypeConvTraits<Float> {
    typedef casa::Float casa_type;
    typedef ::Float32   python_type;
    static PyArray_TYPES pyType() { return PyArray_FLOAT; }
  };
  template <> struct TypeConvTraits<Double> {
    typedef casa::Double casa_type;
    typedef ::Float64    python_type;
    static PyArray_TYPES pyType() { return PyArray_DOUBLE; }
  };
  template <> struct TypeConvTraits<Complex> {
    typedef casa::Complex casa_type;
    typedef ::Complex32   python_type;
    static PyArray_TYPES pyType() { return PyArray_CFLOAT; }
  };
  template <> struct TypeConvTraits<DComplex> {
    typedef casa::DComplex casa_type;
    typedef ::Complex64    python_type;
    static PyArray_TYPES pyType() { return PyArray_CDOUBLE; }
  };
  template <> struct TypeConvTraits<String> {
    typedef casa::String casa_type;
    typedef ::PyObject*  python_type;
    static PyArray_TYPES pyType() { return PyArray_OBJECT; }
  };

  template <typename T> struct ArrayCopy
  {
    static void toPy (void* to, const T* from, uInt nr)
    {
      if (sizeof(T) == sizeof(typename TypeConvTraits<T>::python_type)) {
	::memcpy (to, from, nr*sizeof(T));
      } else {
	typename TypeConvTraits<T>::python_type* dst =
	  static_cast<typename TypeConvTraits<T>::python_type*>(to);
	for (uInt i=0; i<nr; i++) {
	  dst[i] = from[i];
	}
      }
    }
    static void fromPy (T* to, const void* from, uInt nr)
    {
      if (sizeof(T) == sizeof(typename TypeConvTraits<T>::python_type)) {
	::memcpy (to, from, nr*sizeof(T));
      } else {
	const typename TypeConvTraits<T>::python_type* src =
	  static_cast<const typename TypeConvTraits<T>::python_type*>(from);
	for (uInt i=0; i<nr; i++) {
	  to[i] = src[i];
	}
      }
    }
    static Array<T> toArray (const IPosition& shape, void* data)
    {
      if (sizeof(T) == sizeof(typename TypeConvTraits<T>::python_type)) {
	return Array<T> (shape, static_cast<T*>(data), SHARE);
      }
      Array<T> arr(shape);
      fromPy (arr.data(), data, arr.size());
      return arr;
    }
  };

  template <> struct ArrayCopy<Complex>
  {
    static void toPy (void* to, const Complex* from, uInt nr)
    {
      if (sizeof(Complex) != sizeof(TypeConvTraits<Complex>::python_type)) {
	throw AipsError("PycArray: size of Complex data type mismatches");
      }
      ::memcpy (to, from, nr*sizeof(Complex));
    }
    static void fromPy (Complex* to, const void* from, uInt nr)
    {
      if (sizeof(Complex) != sizeof(TypeConvTraits<Complex>::python_type)) {
	throw AipsError("PycArray: size of Complex data type mismatches");
      }
      ::memcpy (to, from, nr*sizeof(Complex));
    }
    static Array<Complex> toArray (const IPosition& shape, void* data)
    {
      if (sizeof(Complex) == sizeof(TypeConvTraits<Complex>::python_type)) {
	return Array<Complex> (shape, static_cast<Complex*>(data), SHARE);
      }
      Array<Complex> arr(shape);
      fromPy (arr.data(), data, arr.size());
      return arr;
    }
  };

  template <> struct ArrayCopy<DComplex>
  {
    static void toPy (void* to, const DComplex* from, uInt nr)
    {
      if (sizeof(DComplex) != sizeof(TypeConvTraits<DComplex>::python_type)) {
	throw AipsError("PycArray: size of DComplex data type mismatches");
      }
      ::memcpy (to, from, nr*sizeof(DComplex));
    }
    static void fromPy (DComplex* to, const void* from, uInt nr)
    {
      if (sizeof(DComplex) != sizeof(TypeConvTraits<DComplex>::python_type)) {
	throw AipsError("PycArray: size of DComplex data type mismatches");
      }
      ::memcpy (to, from, nr*sizeof(DComplex));
    }
    static Array<DComplex> toArray (const IPosition& shape, void* data)
    {
      if (sizeof(DComplex) == sizeof(TypeConvTraits<DComplex>::python_type)) {
	return Array<DComplex> (shape, static_cast<DComplex*>(data), SHARE);
      }
      Array<DComplex> arr(shape);
      fromPy (arr.data(), data, arr.size());
      return arr;
    }
  };

  template <> struct ArrayCopy<String>
  {
    static void toPy (void* to, const String* from, uInt nr)
    {
      PyObject** dst = static_cast<PyObject**>(to);
      for (uInt i=0; i<nr; i++) {
	dst[i] = PyString_FromString(from[i].chars());
      }
    }
    static void fromPy (String* to, const void* from, uInt nr)
    {
      using namespace boost::python;
      PyObject** src = (PyObject**)from;
      for (uInt i=0; i<nr; i++) {
        handle<> py_elem_hdl(src[i]);
        object py_elem_obj(py_elem_hdl);
        extract<std::string> elem_proxy(py_elem_obj);
	to[i] = elem_proxy();
      }
    }
    static Array<String> toArray (const IPosition& shape, void* data)
    {
      Array<String> arr(shape);
      fromPy (arr.data(), data, arr.size());
      return arr;
    }
  };


  // Import the NumArray API.
  void importNumAPI();
  // Import NumArray API if not imported yet.
  inline void importAPI()
    {if (!PyArray_API) importNumAPI(); }

  // Check if the PyObject is an array object.
  Bool PycArrayCheck (PyObject* obj_ptr);

  template <typename T>
  boost::python::object makePyArrayObject (Array<T> const&);
  template <>
  boost::python::object makePyArrayObject (Array<String> const&);

  template <typename T>
  struct casa_array_to_python
  {
    static boost::python::object makeobject (Array<T> const& arr)
      { return makePyArrayObject (arr); }
    static PyObject* convert (Array<T> const& c)
    {
      return boost::python::incref(makeobject(c).ptr());
    }
  };

  struct casa_array_from_python
  {
    // Constructs an Array from a Python object.
    static ValueHolder makeArray(PyObject* obj_ptr);

    // Construct an Array<String> from a special Python dict object.
    static ValueHolder makeArrayFromDict (PyObject* obj_ptr);
  };

}}

#endif
