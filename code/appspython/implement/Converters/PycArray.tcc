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
//# $Id: PycArray.tcc,v 1.1 2006/09/18 22:51:18 gvandiep Exp $

#ifndef APPSPYTHON_PYCARRAY_TCC
#define APPSPYTHON_PYCARRAY_TCC

#include <appspython/Converters/PycArray.h>
#include <casa/Utilities/Assert.h>
#include <casa/Exceptions/Error.h>
#include <boost/python.hpp>
#include <boost/python/object.hpp>

namespace casa { namespace appspython {

  
  template <typename T>
  boost::python::object makePyArrayObject (casa::Array<T> const& arr)
  {
    importAPI();
    // Swap axes, because AIPS++ has row minor and Python row major order.
    int nd = arr.ndim();
    IPosition const& shp = arr.shape();
    IPosition        newshp(nd);
    for (int i=0; i<nd; i++) {
      newshp[i] = shp[nd-i-1];
    }
///    if (arr.size() == 0) {
///      return Py_None;
///    }
    // Create the array from the shape.
    PyArrayObject* po = (PyArrayObject*)PyArray_FromDims
      (nd, const_cast<Int*>(newshp.storage()), TypeConvTraits<T>::pyType());
    if (po == 0) {
      throw AipsError ("PycArray: failed to allocate numarray-object");
    }
    // Copy the data to numarray.
    casa::Bool deleteIt;
    const T* src = arr.getStorage(deleteIt);
    ArrayCopy<T>::toPy (po->data, src, arr.size());
    arr.freeStorage(src, deleteIt);

    // copy the strides to fix
    // array-indexing
    // numarray strides are in units of bytes,
    // casa steps are in units of 'items'
    // so must multiply the casa strides by
    // the itemsize
    ///for( unsigned int k=0; k<t.steps().nelements(); ++k )
    ///  po->strides[k] = t.steps()[k] * sizeof(typename Transform<T>::returntype);
    return boost::python::object(boost::python::handle<>((PyObject*)po));
  }

}}

#endif
