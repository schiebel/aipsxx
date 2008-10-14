//# ForeignArrayParameterAccessor: Access an array of foreign Glish data structures
//# Copyright (C) 1998,2000,2003
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
//#
//# $Id: ForeignArrayParameterAccessor.h,v 19.6 2005/06/18 21:19:18 ddebonis Exp $

#ifndef TASKING_FOREIGNARRAYPARAMETERACCESSOR_H
#define TASKING_FOREIGNARRAYPARAMETERACCESSOR_H

#include <casa/aips.h>
#include <tasking/Tasking/ParameterAccessor.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Vector.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class GlishRecord;
class RecordInterface;
class ParameterSet;
class String;

// <summary> 
// Base class for access to Glish data structure Arrays 
// </summary>
// <synopsis>
// See ForeignParameterAccessor
// </synopsis>

template<class T> class ForeignBaseArrayParameterAccessor 
: public ParameterAccessor<Array<T> > {
 public:
  //# Typdefs for non-standard record access
  // <group>
  typedef Bool (*PACFR)(String &, T &, const GlishRecord &);
  typedef Bool (*PACST)(String &, T &, const String &);
  typedef Bool (*PACTO)(String &, GlishRecord &, const T&);
  typedef Bool (T::*FRGR)(String &, const RecordInterface &);
  typedef Bool (T::*FRST)(String &, const String &);
  typedef Bool (T::*TOGR)(String &, RecordInterface &) const;
  typedef const String & (*ID)(const T &);
  typedef const String & (T::*IDGR)() const;
  // </group>
  //# Constructors
  // Constructor
  ForeignBaseArrayParameterAccessor(const String & name,
			       ParameterSet::Direction direction,
			       GlishRecord * values);
  //# Destructor
  // Destructor
  ~ForeignBaseArrayParameterAccessor();
  
  //# Member functions
  // Convert a Glish record to a C++ structure array or vector
  Bool fromRecord(String & error, PACFR from, PACST frst,
		  FRGR fromGR, FRST fromST, Bool isvector=False);
  // Convert a C++ structure to a Glish Record
  Bool toRecord(String & error, PACTO to, TOGR toGR, ID idfr, IDGR idGR) const;
  // Reset size on action
  virtual void reset();
 private:
  //# Constructors
  // Default constructor (not implemented)
  ForeignBaseArrayParameterAccessor();

  //# Make template-independent parent members known
public:
  using ParameterAccessor< Array<T> >::name;
  using ParameterAccessor< Array<T> >::operator();
protected:
  using ParameterAccessor< Array<T> >::values_p;
  using ParameterAccessor< Array<T> >::value_p;
};

// <summary> 
// Base class for access to Glish data structure Vectors 
// </summary>
// <synopsis>
// See ForeignParameterAccessor
// </synopsis>

template<class T> class ForeignBaseVectorParameterAccessor 
: public ParameterAccessor<Vector<T> > {
 public:
  //# Typdefs for non-standard record access
  // <group>
  typedef Bool (*PACFR)(String &, T &, const GlishRecord &);
  typedef Bool (*PACST)(String &, T &, const String &);
  typedef Bool (*PACTO)(String &, GlishRecord &, const T&);
  typedef Bool (T::*FRGR)(String &, const RecordInterface &);
  typedef Bool (T::*FRST)(String &, const String &);
  typedef Bool (T::*TOGR)(String &, RecordInterface &) const;
  typedef const String & (*ID)(const T &);
  typedef const String & (T::*IDGR)() const;
  // </group>
  //# Constructors
  // Constructor
  ForeignBaseVectorParameterAccessor(const String & name,
			       ParameterSet::Direction direction,
			       GlishRecord * values);
  //# Destructor
  // Destructor
  ~ForeignBaseVectorParameterAccessor();
  
  //# Member functions
  // Convert a Glish record to a C++ structure
  Bool fromRecord(String & error, PACFR from, PACST frst,
		  FRGR fromGR, FRST fromST);
  // Convert a C++ structure to a Glish Record
  Bool toRecord(String & error, PACTO to, TOGR toGR, ID idfr, IDGR idGR) const;
  // Reset size on action
  virtual void reset();
 private:
  //# Constructors
  // Default constructor (not implemented)
  ForeignBaseVectorParameterAccessor();

  //# Make template-independent parent members known
public:
  using ParameterAccessor< Vector<T> >::name;
  using ParameterAccessor< Vector<T> >::operator();
protected:
  using ParameterAccessor< Vector<T> >::values_p;
  using ParameterAccessor< Vector<T> >::value_p;
};

// <summary>  
// Access an array of foreign Glish data structures 
// </summary>

// <use visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
//   <li> SomeOtherClass
//   <li> some concept
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// This class makes it possible to transfer Arrays (and Vectors) between
// Glish and C++, using the standard Parameter<> structure. Its use is
// explained in ForeignParameterAccessor.h.
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <templating arg=T>
//    <li>
//    <li>
// </templating>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>


template<class T> class ForeignArrayParameterAccessor 
: public ForeignBaseArrayParameterAccessor<T> {
 public:
  //# Constructors
  // Constructor
  ForeignArrayParameterAccessor(const String & name,
				ParameterSet::Direction direction,
				GlishRecord * values);

  //# Destructor
  // Destructor
  ~ForeignArrayParameterAccessor();
  
  //# Member functions
  // Convert a Glish record to an Array of C++ structures
  virtual Bool fromRecord(String &error);
  // Convert an Array of C++ structures to a Glish Record
  virtual Bool toRecord(String &error) const;
  // Reset size on action
  virtual void reset();
 private:
  ForeignArrayParameterAccessor();

  //# Make template-independent parent members known
public:
  using ForeignBaseArrayParameterAccessor<T>::name;
  using ForeignBaseArrayParameterAccessor<T>::operator();
protected:
  using ForeignBaseArrayParameterAccessor<T>::values_p;
  using ForeignBaseArrayParameterAccessor<T>::value_p;
};

// <summary> 
// Base class for access to Foreign vectors
// </summary>
// <synopsis>
// See ForeignParameterAccessor
// </synopsis>

template<class T> class ForeignVectorParameterAccessor 
: public ForeignBaseVectorParameterAccessor<T> {
 public:
  //# Constructors
  // Constructor
  ForeignVectorParameterAccessor(const String & name,
				 ParameterSet::Direction direction,
				 GlishRecord * values);

  //# Destructor
  // Destructor
  ~ForeignVectorParameterAccessor();
  
  //# Member functions
  // Convert a Glish record to a Vector of C++ structures
  virtual Bool fromRecord(String &error);
  // Convert a Vector of C++ structures to a Glish Record
  virtual Bool toRecord(String &error) const;
  // Reset size on action
  virtual void reset();
 private:
  //# Constructors
  // Default constructor (not implemented)
  ForeignVectorParameterAccessor();

  //# Make template-independent parent members known
public:
  using ForeignBaseVectorParameterAccessor<T>::name;
  using ForeignBaseVectorParameterAccessor<T>::operator();
protected:
  using ForeignBaseVectorParameterAccessor<T>::values_p;
  using ForeignBaseVectorParameterAccessor<T>::value_p;
};

// <summary>  
// Access an array of non-standard Glish data structures 
// </summary>

// <use visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
//   <li> SomeOtherClass
//   <li> some concept
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// This class makes it possible to transfer Arrays (and Vectors) between
// Glish and C++, using the standard Parameter<> structure. Its use is
// explained in ForeignParameterAccessor.h.
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <templating arg=T>
//    <li>
//    <li>
// </templating>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>


template<class T> class ForeignNSArrayParameterAccessor 
: public ForeignBaseArrayParameterAccessor<T> {
 public:
  //# Constructors
  // Constructor
  ForeignNSArrayParameterAccessor(const String & name,
				  ParameterSet::Direction direction,
				  GlishRecord * values);

  //# Destructor
  // Destructor
  ~ForeignNSArrayParameterAccessor();
  
  //# Member functions
  // Convert a Glish record to an Array of C++ structures
  virtual Bool fromRecord(String & error);
  // Convert an Array of C++ structures to a Glish Record
  virtual Bool toRecord(String & error) const;
  // Reset size on action
  virtual void reset();
 private:
  ForeignNSArrayParameterAccessor();

  //# Make template-independent parent members known
public:
  using ForeignBaseArrayParameterAccessor<T>::name;
  using ForeignBaseArrayParameterAccessor<T>::operator();
protected:
  using ForeignBaseArrayParameterAccessor<T>::values_p;
  using ForeignBaseArrayParameterAccessor<T>::value_p;
};

// <summary>  
// Access a vector of non-standard Glish data structures 
// </summary>

// <use visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
//   <li> SomeOtherClass
//   <li> some concept
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// This class makes it possible to transfer Arrays (and Vectors) between
// Glish and C++, using the standard Parameter<> structure. Its use is
// explained in ForeignParameterAccessor.h.
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <templating arg=T>
//    <li>
//    <li>
// </templating>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>


template<class T> class ForeignNSVectorParameterAccessor 
: public ForeignBaseVectorParameterAccessor<T> {
 public:
  //# Constructors
  // Constructor
  ForeignNSVectorParameterAccessor(const String & name,
				   ParameterSet::Direction direction,
				   GlishRecord * values);

  //# Destructor
  // Destructor
  ~ForeignNSVectorParameterAccessor();
  
  //# Member functions
  // Convert a Glish record to a Vector of C++ structures
  virtual Bool fromRecord(String & error);
  // Convert a Vector of C++ structures to a Glish Record
  virtual Bool toRecord(String & error) const;
  // Reset size on action
  virtual void reset();
 private:
  //# Constructors
  // Default constructor (not implemented)
  ForeignNSVectorParameterAccessor();

  //# Make template-independent parent members known
public:
  using ForeignBaseVectorParameterAccessor<T>::name;
  using ForeignBaseVectorParameterAccessor<T>::operator();
protected:
  using ForeignBaseVectorParameterAccessor<T>::values_p;
  using ForeignBaseVectorParameterAccessor<T>::value_p;
};


} //# NAMESPACE CASA - END

#ifndef AIPS_NO_TEMPLATE_SRC
#include <tasking/Tasking/ForeignArrayParameterAccessor.cc>
#endif //# AIPS_NO_TEMPLATE_SRC
#endif
