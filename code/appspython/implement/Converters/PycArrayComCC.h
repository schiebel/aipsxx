//# PycArrayCom.h: Common code to convert an Array to/from a Python array
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
//# $Id: PycArrayComCC.h,v 1.3 2006/11/20 23:58:17 gvandiep Exp $


  Bool PycArrayCheck (PyObject* obj_ptr)
  {
    if (!PyArray_API) {
      if (!isImported()) return False;
      loadAPI();
    }
    return PyArray_Check (obj_ptr);
  }

  Bool isImported()
  {
    using namespace boost::python;
    PyObject* mods = PySys_GetObject("modules");
    dict d =  extract<dict>(mods)();
    return d.has_key(PYC_USE_PYARRAY);
  }

  void loadAPI()
  {
    if (!PyArray_API) {
      import_array();
      if (!PyArray_API) {
	throw AipsError ("PycArray: failed to load the "PYC_USE_PYARRAY
			 " API");
      }
    }
  }


  template <typename T> struct TypeConvTraits {
    typedef T     casa_type;
    typedef void* python_type;
    static PyArray_TYPES pyType()
      { throw AipsError ("PycArray: unknown casa type"); }
  };
  template <> struct TypeConvTraits<casa::Bool> {
    typedef casa::Bool casa_type;
    typedef ::Bool     python_type;
    static PyArray_TYPES pyType() { return NPY_BOOL; }
  };
  template <> struct TypeConvTraits<casa::uChar> {
    typedef casa::uChar  casa_type;
    typedef ::UInt16     python_type;    // Note: numarray uInt8 is Bool
    static PyArray_TYPES pyType() { return NPY_USHORT; }
  };
  template <> struct TypeConvTraits<casa::Short> {
    typedef casa::Short casa_type;
    typedef ::Int16     python_type;
    static PyArray_TYPES pyType() { return NPY_SHORT; }
  };
  template <> struct TypeConvTraits<casa::uShort> {
    typedef casa::uShort casa_type;
    typedef ::UInt16     python_type;
    static PyArray_TYPES pyType() { return NPY_USHORT; }
  };
  template <> struct TypeConvTraits<casa::Int> {
    typedef casa::Int casa_type;
    typedef ::Int32   python_type;
    static PyArray_TYPES pyType() { return NPY_INT; }
  };
  template <> struct TypeConvTraits<casa::uInt> {
    typedef casa::uInt casa_type;
    typedef ::UInt32   python_type;
    static PyArray_TYPES pyType() { return NPY_UINT; }
  };
  template <> struct TypeConvTraits<casa::Long> {
    typedef casa::Long casa_type;
    typedef ::Long     python_type;
    static PyArray_TYPES pyType() { return NPY_LONG; }
  };
  template <> struct TypeConvTraits<casa::Float> {
    typedef casa::Float casa_type;
    typedef ::Float32   python_type;
    static PyArray_TYPES pyType() { return NPY_FLOAT; }
  };
  template <> struct TypeConvTraits<casa::Double> {
    typedef casa::Double casa_type;
    typedef ::Float64    python_type;
    static PyArray_TYPES pyType() { return NPY_DOUBLE; }
  };
  template <> struct TypeConvTraits<casa::Complex> {
    typedef casa::Complex casa_type;
    typedef ::Complex32   python_type;
    static PyArray_TYPES pyType() { return NPY_CFLOAT; }
  };
  template <> struct TypeConvTraits<casa::DComplex> {
    typedef casa::DComplex casa_type;
    typedef ::Complex64    python_type;
    static PyArray_TYPES pyType() { return NPY_CDOUBLE; }
  };
  template <> struct TypeConvTraits<casa::String> {
    typedef casa::String casa_type;
    typedef ::PyObject*  python_type;
    static PyArray_TYPES pyType() { return NPY_OBJECT; }
  };
  // This one is only used to convert numpy BYTE and SBYTE to casa short.
  // There is no back conversion, so an exception is thrown.
  template <> struct TypeConvTraits<casa::Char> {
    typedef casa::Char   casa_type;
    typedef ::Int8       python_type;
    static PyArray_TYPES pyType()
      { throw AipsError ("PycArray: unknown casa type"); }
  };


  template <typename T>
  void ArrayCopy<T>::toPy (void* to, const T* from, uInt nr)
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
  template <typename T>
  void  ArrayCopy<T>::fromPy (T* to, const void* from, uInt nr)
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
  template <typename T>
  Array<T> ArrayCopy<T>::toArray (const IPosition& shape,
				  void* data, bool copy)
  {
    // If the python array was contiguous, etc., we can directly use
    // its data because the Array use is only temporary.
    // However, if a copy of the Python array was made in PycArray.cc,
    // we cannot do that because the Python copy is out of scope when
    // the Array object gets used.
    if (!copy) {
      if (sizeof(T) == sizeof(typename TypeConvTraits<T>::python_type)) {
	return Array<T> (shape, static_cast<T*>(data), SHARE);
      }
    }
    Array<T> arr(shape);
    fromPy (arr.data(), data, arr.size());
    return arr;
  }


  void ArrayCopy<Complex>::toPy (void* to, const Complex* from, uInt nr)
  {
    if (sizeof(Complex) != sizeof(TypeConvTraits<Complex>::python_type)) {
      throw AipsError("PycArray: size of Complex data type mismatches");
    }
    ::memcpy (to, from, nr*sizeof(Complex));
  }
  void ArrayCopy<Complex>::fromPy (Complex* to, const void* from, uInt nr)
  {
    if (sizeof(Complex) != sizeof(TypeConvTraits<Complex>::python_type)) {
      throw AipsError("PycArray: size of Complex data type mismatches");
    }
    ::memcpy (to, from, nr*sizeof(Complex));
  }
  Array<Complex> ArrayCopy<Complex>::toArray (const IPosition& shape,
					      void* data, bool copy)
  {
    if (!copy) {
      if (sizeof(Complex) == sizeof(TypeConvTraits<Complex>::python_type)) {
	return Array<Complex> (shape, static_cast<Complex*>(data), SHARE);
      }
    }
    Array<Complex> arr(shape);
    fromPy (arr.data(), data, arr.size());
    return arr;
  }


  void ArrayCopy<DComplex>::toPy (void* to, const DComplex* from, uInt nr)
  {
    if (sizeof(DComplex) != sizeof(TypeConvTraits<DComplex>::python_type)) {
      throw AipsError("PycArray: size of DComplex data type mismatches");
    }
    ::memcpy (to, from, nr*sizeof(DComplex));
  }
  void ArrayCopy<DComplex>::fromPy (DComplex* to, const void* from, uInt nr)
  {
    if (sizeof(DComplex) != sizeof(TypeConvTraits<DComplex>::python_type)) {
      throw AipsError("PycArray: size of DComplex data type mismatches");
    }
    ::memcpy (to, from, nr*sizeof(DComplex));
  }
  Array<DComplex> ArrayCopy<DComplex>::toArray (const IPosition& shape,
						void* data, bool copy)
  {
    if (!copy) {
      if (sizeof(DComplex) == sizeof(TypeConvTraits<DComplex>::python_type)) {
	return Array<DComplex> (shape, static_cast<DComplex*>(data), SHARE);
      }
    }
    Array<DComplex> arr(shape);
    fromPy (arr.data(), data, arr.size());
    return arr;
  }


  void ArrayCopy<String>::toPy (void* to, const String* from, uInt nr)
  {
    PyObject** dst = static_cast<PyObject**>(to);
    for (uInt i=0; i<nr; i++) {
      dst[i] = PyString_FromString(from[i].chars());
    }
  }
  void ArrayCopy<String>::fromPy (String* to, const void* from, uInt nr)
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
  Array<String> ArrayCopy<String>::toArray (const IPosition& shape,
					    void* data, bool)
  {
    Array<String> arr(shape);
    fromPy (arr.data(), data, arr.size());
    return arr;
  }

  template <typename T>
  boost::python::object makePyArrayObject (casa::Array<T> const& arr)
  {
    // Load the API if needed.
    if (!PyArray_API) loadAPI();
    // Swap axes, because AIPS++ has row minor and Python row major order.
    // A Python array needs at least 1 dimension, otherwise it's a scalar.
    int nd = arr.ndim();
    IPosition newshp(1, 0);
    if (nd == 0) {
      nd = 1;
    } else {
      newshp.resize (nd);
      const IPosition& shp = arr.shape();
      for (int i=0; i<nd; i++) {
	newshp[i] = shp[nd-i-1];
      }
    }
    // Create the array from the shape.
    PyArrayObject* po = (PyArrayObject*)PyArray_FromDims
      (nd, const_cast<Int*>(newshp.storage()), TypeConvTraits<T>::pyType());
    if (po == 0) {
      throw AipsError ("PycArray: failed to allocate python array-object");
    }
    // Copy the data to numarray.
    if (arr.size() > 0) {
      casa::Bool deleteIt;
      const T* src = arr.getStorage(deleteIt);
      ArrayCopy<T>::toPy (po->data, src, arr.size());
      arr.freeStorage(src, deleteIt);
    }
    // Return the python array.
    return boost::python::object(boost::python::handle<>((PyObject*)po));
  }


  ValueHolder makeArray (PyObject* obj_ptr, Bool copyData)
  {
    if (! PycArrayCheck(obj_ptr)) {
      throw AipsError ("PycArray: python object is not an array");
    }
    PyArrayObject* po = (PyArrayObject*)obj_ptr;
    boost::python::object obj;
    bool docopy = copyData;               // copy data if wanted or needed
    if (! PyArray_ISCONTIGUOUS(po)
	||  ! PyArray_ISALIGNED(po)
	||  PyArray_ISBYTESWAPPED(po)) {
      boost::python::handle<> py_hdl(obj_ptr);
      boost::python::object py_obj(py_hdl);
      // incr refcount, because ~object decrements it
      boost::python::incref(obj_ptr);
      obj = py_obj.attr("copy")();
      po = (PyArrayObject*)(obj.ptr());
      docopy = true;
    }
    // Swap axes, because AIPS++ has row minor and Python row major order.
    // A scalar is treated as a vector with length 1.
    int nd = po->nd;
    IPosition shp(1, 1);
    if (nd > 0) {
      shp.resize (nd);
      for (int i=0; i<nd; i++) {
	shp[i] = po->dimensions[nd-i-1];
      }
    }
    // Assert array is contiguous now.
    // If the array is empty, numarray still sees it as non-contiguous.
    if (shp.product() > 0) {
      AlwaysAssert (PyArray_ISCONTIGUOUS(po)
		    &&  PyArray_ISALIGNED(po)
		    &&  !PyArray_ISBYTESWAPPED(po), AipsError);
    }
    // Create the correct array.
    switch (po->descr->type_num) {
    case NPY_BOOL:
      return ValueHolder (ArrayCopy<Bool>::toArray(shp, po->data, docopy));
    case NPY_SHORT:
      return ValueHolder (ArrayCopy<Short>::toArray(shp, po->data, docopy));
    case NPY_USHORT:
      return ValueHolder (ArrayCopy<uShort>::toArray(shp, po->data, docopy));
    case NPY_INT:
      return ValueHolder (ArrayCopy<Int>::toArray(shp, po->data, docopy));
    case NPY_UINT:
      return ValueHolder (ArrayCopy<uInt>::toArray(shp, po->data, docopy));
    case NPY_FLOAT:
      return ValueHolder (ArrayCopy<Float>::toArray(shp, po->data, docopy));
    case NPY_DOUBLE:
      return ValueHolder (ArrayCopy<Double>::toArray(shp, po->data, docopy));
    case NPY_CFLOAT:
      return ValueHolder (ArrayCopy<Complex>::toArray(shp, po->data, docopy));
    case NPY_CDOUBLE:
      return ValueHolder (ArrayCopy<DComplex>::toArray(shp, po->data, docopy));
    case NPY_OBJECT:
      return ValueHolder (ArrayCopy<String>::toArray(shp, po->data, docopy));
    default:
      // NPY_INT and LONG are the same on 32-bit machines, so LONG
      // cannot be used in the switch (compiler complains).
      // Similarly for BYTE and SBYTE which can equal to BOOL in numarray.
      // Similarly for STRING which exists for numpy and is set to
      // INT for numarray.
      if (po->descr->type_num == NPY_LONG) {
	if (sizeof(Long) != sizeof(Int)) docopy = False;
	Array<Long> arr = ArrayCopy<Long>::toArray(shp, po->data, docopy);
	if (sizeof(Long) == sizeof(Int)) {
	  return ValueHolder((Array<Int>&)arr);
	}
	Array<Int> res(arr.shape());
	convertArray (res, arr);
	return ValueHolder(res);
      } else if (po->descr->type_num == NPY_BYTE) {
	Array<Char> arr = ArrayCopy<Char>::toArray(shp, po->data, False);
	Array<Short> res(arr.shape());
	convertArray (res, arr);
	return ValueHolder(res);
      } else if (po->descr->type_num == NPY_UBYTE) {
	// Copy using Char, because uChar is mapped to Short in the Traits.
	Array<Char> arr = ArrayCopy<Char>::toArray(shp, po->data, False);
	Array<Short> res(arr.shape());
	convertArray (res, (const Array<uChar>&)arr);
	return ValueHolder(res);
      } else if (po->descr->type_num == NPY_STRING) {
	int slen = 0;
	if (nd > 0) {
	  slen = po->strides[nd-1];
	}
	return ValueHolder (ArrayCopyStr_toArray(shp, po->data, slen));
      }
      break;
    }
    throw AipsError ("PycArray: unknown python array data type");
  } 


  // Instantiate the various templates.
  template struct ArrayCopy<Bool>;
  template struct ArrayCopy<Char>;
  template struct ArrayCopy<uChar>;
  template struct ArrayCopy<Short>;
  template struct ArrayCopy<uShort>;
  template struct ArrayCopy<Int>;
  template struct ArrayCopy<uInt>;
  template struct ArrayCopy<Long>;
  template struct ArrayCopy<Float>;
  template struct ArrayCopy<Double>;

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
