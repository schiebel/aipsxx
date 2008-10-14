//# PycBasicData.cc: Convert casa data types to/from python
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
//# $Id: PycBasicData.h,v 1.1 2006/09/18 04:12:04 gvandiep Exp $

#ifndef APPSPYTHON_PYCBASICDATA_H
#define APPSPYTHON_PYCBASICDATA_H

#include <casa/BasicSL/String.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Arrays/Vector.h>
#include <vector>
#include <boost/python.hpp>
#include <boost/python/object.hpp>


// Define classes and functions to convert the basic data types and
// containers to and from Python.

namespace casa { namespace appspython {

  // Convert a String object to python.
  struct casa_string_to_python_str
  {
    static boost::python::object makeobject(String const& s)
      { return boost::python::object((const std::string&)s); }
    static PyObject* convert(String const& s)
      { return boost::python::incref(makeobject(s).ptr()); }
  };

  // Convert a String object from python.
  struct casa_string_from_python_str
  {
    casa_string_from_python_str()
    {
      boost::python::converter::registry::push_back(
        &convertible,
        &construct,
        boost::python::type_id<String>());
    }

    static void* convertible(PyObject* obj_ptr)
    {
      if (!PyString_Check(obj_ptr)) return 0;
      return obj_ptr;
    }

    static void construct(
      PyObject* obj_ptr,
      boost::python::converter::rvalue_from_python_stage1_data* data)
    {
      const char* value = PyString_AsString(obj_ptr);
      if (value == 0) boost::python::throw_error_already_set();
      void* storage = (
        (boost::python::converter::rvalue_from_python_storage<String>*)
          data)->storage.bytes;
      new (storage) String(value);
      data->convertible = storage;
    }
  };


  // Default operations on all containers for conversion from Python
  // container to C++ one.

  // Copied from
  // scitbx/include/scitbx/boost_python/container_conversions.h that is
  // described in the <a
  // href="http://www.boost.org/libs/python/doc/v2/faq.html">
  // Boost.Python FAQ. </a>

  // @author Ralf W. Grosse-Kunstleve <rwgk@yahoo.com> of
  // <a href="http://www.lbl.gov/">Lawrence Berkeley National Laboratory</a>
  struct default_policy
  {
    static bool check_convertibility_per_element() { return false; }

    template <typename ContainerType>
    static bool check_size(boost::type<ContainerType>, std::size_t sz)
    {
      return true;
    }

    template <typename ContainerType>
    static void assert_size(boost::type<ContainerType>, std::size_t sz) {}

    template <typename ContainerType>
    static void reserve(ContainerType& a, std::size_t sz) {}
  };

  // Operations on containers that have variable capacity for
  // conversion from Python container to C++ one.

  // Copied from
  // scitbx/include/scitbx/boost_python/container_conversions.h that is
  // described in the <a
  // href="http://www.boost.org/libs/python/doc/v2/faq.html">
  // Boost.Python FAQ. </a>

  // @author Ralf W. Grosse-Kunstleve <rwgk@yahoo.com> of
  // <a href="http://www.lbl.gov/">Lawrence Berkeley National Laboratory</a>
  struct stl_variable_capacity_policy : default_policy
  {
    template <typename ContainerType>
    static void reserve(ContainerType& a, std::size_t sz)
    {
      a.reserve(sz);
    }

    template <typename ContainerType, typename ValueType>
    static void set_value(ContainerType& a, std::size_t i, ValueType const& v)
    {
      assert(a.size() == i);
      a.push_back(v);
    }
  };

  struct casa_variable_capacity_policy : default_policy
  {
    template <typename ContainerType>
    static void reserve(ContainerType& a, std::size_t sz)
    {
      a.resize(sz);
    }

    template <typename ContainerType, typename ValueType>
    static void set_value(ContainerType& a, std::size_t i, ValueType const& v)
    {
      assert(a.nelements() > i);
      a[i] = v;
    }
  };


  // A wrapper of a conversion function to convert a STL vector to a
  // Python tuple.  This class satisfies the requirements of the
  // boost::python::to_python_converter conversion template argument.

  // Copied from
  // scitbx/include/scitbx/boost_python/container_conversions.h that is
  // described in the <a
  // href="http://www.boost.org/libs/python/doc/v2/faq.html">
  // Boost.Python FAQ. </a>

  // @author Ralf W. Grosse-Kunstleve <rwgk@yahoo.com> of 
  // <a href="http://www.lbl.gov/">Lawrence Berkeley National Laboratory</a>
  template < typename ContainerType >
  struct to_tuple
  {
    // Creates and returns a Python tuple from the elements copied
    // from a STL container. The ContainerType must be a container
    // with STL iterators defined on it.
    // It may contain any type of object supported by the
    // boost::python::object constructor.
    static boost::python::object makeobject (ContainerType const& c)
    {
      boost::python::list result;
      typename ContainerType::const_iterator i = c.begin();
      for( ; i != c.end(); ++i) {
	result.append(*i);
      }
      return boost::python::tuple(result);
    }
    static PyObject* convert (ContainerType const& c)
    {
      return boost::python::incref(makeobject(c).ptr());
    }
  };
  template <>
  struct to_tuple <std::vector <casa::String> >
  {
    typedef std::vector <casa::String> ContainerType;
    static boost::python::tuple makeobject (ContainerType const& c)
    {
      boost::python::list result;
      ContainerType::const_iterator i = c.begin();
      for( ; i != c.end(); ++i) {
	result.append((std::string const&)(*i));
      }
      return boost::python::tuple(result);
    }
    static PyObject* convert (ContainerType const& c)
    {
      return boost::python::incref(makeobject(c).ptr());
    }
  };
  template <>
  struct to_tuple <casa::Array <casa::String> >
  {
    typedef casa::Array <casa::String> ContainerType;
    static boost::python::object makeobject (ContainerType const& c)
    {
      boost::python::list result;
      ContainerType::const_iterator i = c.begin();
      for( ; i != c.end(); ++i) {
	result.append((std::string const&)(*i));
      }
      return boost::python::tuple(result);
    }
    static PyObject* convert (ContainerType const& c)
    {
      return boost::python::incref(makeobject(c).ptr());
    }
  };
  template <>
  struct to_tuple <casa::Vector <casa::String> >
  {
    typedef casa::Vector <casa::String> ContainerType;
    static boost::python::object makeobject (ContainerType const& c)
    {
      boost::python::list result;
      ContainerType::const_iterator i = c.begin();
      for( ; i != c.end(); ++i) {
	result.append((std::string const&)(*i));
      }
      return boost::python::tuple(result);
    }
    static PyObject* convert (ContainerType const& c)
    {
      return boost::python::incref(makeobject(c).ptr());
    }
  };

  // Converts an STL vector or casa Array of T objects to Python tuple. 
  // Copied from
  // scitbx/include/scitbx/boost_python/container_conversions.h that is
  // described in the <a
  // href="http://www.boost.org/libs/python/doc/v2/faq.html">
  // Boost.Python FAQ. </a>
  // @author Ralf W. Grosse-Kunstleve <rwgk@yahoo.com> of
  // <a href="http://www.lbl.gov/">Lawrence Berkeley National Laboratory</a>
  template < typename T >
  struct std_vector_to_tuple 
  {
    std_vector_to_tuple ()
    {
      boost::python::to_python_converter < std::vector < T >, 
	                        to_tuple < std::vector < T > >  > ();
    }
  };
  template < typename T >
  struct casa_array_to_tuple 
  {
    casa_array_to_tuple ()
    {
      boost::python::to_python_converter < casa::Array < T >, 
	                        to_tuple < casa::Array < T > >  > ();
    }
  };
  template < typename T >
  struct casa_vector_to_tuple 
  {
    casa_vector_to_tuple ()
    {
      boost::python::to_python_converter < casa::Vector < T >, 
	                        to_tuple < casa::Vector < T > >  > ();
    }
  };
  struct casa_iposition_to_tuple 
  {
    casa_iposition_to_tuple ()
    {
      boost::python::to_python_converter < casa::IPosition, 
	                        to_tuple < casa::IPosition >  > ();
    }
  };


  // Conversion of Python sequence to C++ container.

  // Copied from
  // scitbx/include/scitbx/boost_python/container_conversions.h that is
  // described in the <a
  // href="http://www.boost.org/libs/python/doc/v2/faq.html">
  // Boost.Python FAQ. </a>
  // @author Ralf W. Grosse-Kunstleve <rwgk@yahoo.com> of
  // <a href="http://www.lbl.gov/">Lawrence Berkeley National Laboratory</a>
  template <typename ContainerType, typename ConversionPolicy>
  struct from_python_sequence
  {
    typedef typename ContainerType::value_type container_element_type;

    from_python_sequence()
    {
      boost::python::converter::registry::push_back(
        &convertible,
        &construct,
        boost::python::type_id<ContainerType>());
    }

    // Appears to return @a obj_ptr if it is type of Python sequence
    // that can be convertible to C++ container.
    static void* convertible(PyObject* obj_ptr)
    {
      using namespace boost::python;
      using boost::python::allow_null; // works around gcc 2.96 bug
      {
        // Restriction to list, tuple, iter, xrange until
        // Boost.Python overload resolution is enhanced.
	//
	// add PySequence_Check() for numarray.
	//
	if (!(PyList_Check(obj_ptr)
	      || PyTuple_Check(obj_ptr)
	      || PyIter_Check(obj_ptr)
	      || PyRange_Check(obj_ptr)
	      || PySequence_Check(obj_ptr) )) return 0;
      }
      handle<> obj_iter(allow_null(PyObject_GetIter(obj_ptr)));
      if (!obj_iter.get()) {       // must be convertible to an iterator
        PyErr_Clear();
        return 0;
      }
      if (ConversionPolicy::check_convertibility_per_element()) {
        int obj_size = PyObject_Length(obj_ptr);
        if (obj_size < 0) {        // must be a measurable sequence
          PyErr_Clear();
          return 0;
        }
        if (!ConversionPolicy::check_size(
          boost::type<ContainerType>(), obj_size)) return 0;
        bool is_range = PyRange_Check(obj_ptr);
	int i = 0;
        for (;;i++) {
          handle<> py_elem_hdl(allow_null(PyIter_Next(obj_iter.get())));
          if (PyErr_Occurred()) {
            PyErr_Clear();
            return 0;
          }
          if (!py_elem_hdl.get()) break;         // end of iteration
          object py_elem_obj(py_elem_hdl);
          extract<container_element_type> elem_proxy(py_elem_obj);
          if (!elem_proxy.check()) return 0;
          if (is_range) break; // in a range all elements are of the same type
        }
        if (!is_range) assert(i == obj_size );
      }
      return obj_ptr;
    }

    // Constructs a C++ container from a Python sequence.
    static void construct(
      PyObject* obj_ptr,
      boost::python::converter::rvalue_from_python_stage1_data* data)
    {
      using namespace boost::python;
      using boost::python::allow_null; // works around gcc 2.96 bug
      using boost::python::converter::rvalue_from_python_storage; // dito
      using boost::python::throw_error_already_set; // dito
      int obj_size = PyObject_Length(obj_ptr);
      handle<> obj_iter(PyObject_GetIter(obj_ptr));
      void* storage = (
        (rvalue_from_python_storage<ContainerType>*)
          data)->storage.bytes;
      new (storage) ContainerType();
      data->convertible = storage;
      ContainerType& result = *((ContainerType*)storage);
      ConversionPolicy::reserve(result, obj_size);
      std::size_t i=0;
      for(;;i++) {
        handle<> py_elem_hdl(allow_null(PyIter_Next(obj_iter.get())));
        if (PyErr_Occurred()) throw_error_already_set();
        if (!py_elem_hdl.get()) break; // end of iteration
        object py_elem_obj(py_elem_hdl);
        extract<container_element_type> elem_proxy(py_elem_obj);
        ConversionPolicy::set_value(result, i, elem_proxy());
      }
      ConversionPolicy::assert_size(boost::type<ContainerType>(), i);
    }

    // Constructs a C++ container from a Python sequence.
    static ContainerType make_container(PyObject* obj_ptr)
    {
      using namespace boost::python;
      int obj_size = PyObject_Length(obj_ptr);
      handle<> obj_iter(PyObject_GetIter(obj_ptr));
      ContainerType result;
      ConversionPolicy::reserve(result, obj_size);
      std::size_t i=0;
      for(;;i++) {
        handle<> py_elem_hdl(allow_null(PyIter_Next(obj_iter.get())));
        if (PyErr_Occurred()) throw_error_already_set();
        if (!py_elem_hdl.get()) break; // end of iteration
        object py_elem_obj(py_elem_hdl);
        extract<container_element_type> elem_proxy(py_elem_obj);
        ConversionPolicy::set_value(result, i, elem_proxy());
      }
      ConversionPolicy::assert_size(boost::type<ContainerType>(), i);
      return result;
    }
  };


  // Register the String conversion.
  inline void register_convert_casa_string()
  {
    boost::python::to_python_converter<String, casa_string_to_python_str>();
    casa_string_from_python_str();
  }

  // Register the Container conversions.
  template < typename T >
  inline void register_convert_std_vector()
  {
    std_vector_to_tuple < T > ();
    from_python_sequence < std::vector < T >,
                           stl_variable_capacity_policy > ();
  }
  template < typename T >
  inline void register_convert_casa_vector()
  {
    casa_array_to_tuple < T > ();
    casa_vector_to_tuple < T > ();
    from_python_sequence < casa::Vector < T >,
                           casa_variable_capacity_policy > ();
  }
  inline void register_convert_casa_iposition()
  {
    casa_iposition_to_tuple();
    from_python_sequence < casa::IPosition,
                           casa_variable_capacity_policy > ();
  }
}}

#endif
