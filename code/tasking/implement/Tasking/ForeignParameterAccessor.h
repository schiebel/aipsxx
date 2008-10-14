//# ForeignParameterAccessor: Class to access foreign Glish data structures
//# Copyright (C) 1998,2000,2002,2003
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
//# $Id: ForeignParameterAccessor.h,v 19.6 2005/06/18 21:19:18 ddebonis Exp $

#ifndef TASKING_FOREIGNPARAMETERACCESSOR_H
#define TASKING_FOREIGNPARAMETERACCESSOR_H

#include <casa/aips.h>
#include <tasking/Tasking/ParameterAccessor.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class RecordInterface;
class GlishRecord;
class GlishValue;
class ParameterSet;
class IPosition;
class String;

//# For template specializations.
template <class T> class Quantum;
template <class T> class Vector;
template <class T> class Array;
class MEpoch;
class MDoppler;
class MDirection;
class MFrequency;
class MPosition;
class MRadialVelocity;
class MBaseline;
class Muvw;
class MEarthMagnetic;

// <summary> Base class to access Glish data structures </summary>

// <use visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// See ForeignParameterAccessor
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


template<class T> class ForeignBaseParameterAccessor 
: public ParameterAccessor<T> {
 public:
  //# Typdefs for non-standard record access
  // <group>
  typedef Bool (*PACFR)(String &, T &, const GlishRecord &);
  typedef Bool (*PACST)(String &, T &, const String &);
  typedef Bool (*PACTO)(String &, GlishRecord &, const T &);
  typedef Bool (T::*FRGR)(String &, const RecordInterface &);
  typedef Bool (T::*FRST)(String &, const String &);
  typedef Bool (T::*TOGR)(String &, RecordInterface &) const;
  typedef const String & (*ID)(const T &);
  typedef const String & (T::*IDGR)() const;
  // </group>
  //# Constructors
  // Constructor
  ForeignBaseParameterAccessor(const String & name,
			       ParameterSet::Direction direction,
			       GlishRecord * values);
  //# Destructor
  // Destructor
  ~ForeignBaseParameterAccessor();
  
  //# Member functions
  // Convert a Glish record to a C++ structure
  Bool fromRecord(String & error, PACFR from, PACST frst,
		  FRGR fromGR, FRST fromST);
  // Convert a C++ structure to a Glish Record
  Bool toRecord(String & error, PACTO to, TOGR toGR, ID idfr, IDGR idGR) const;
 private:
  //# Constructors
  // Default constructor (not implemented)
  ForeignBaseParameterAccessor();

  //# Make template-independent parent members known
public:
  using ParameterAccessor<T>::name;
  using ParameterAccessor<T>::operator();
protected:
  using ParameterAccessor<T>::values_p;
  using ParameterAccessor<T>::value_p;
};

// <summary> Class to access foreign Glish data structures </summary>

// <use visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// This class connects the Tasking Parameter system for non-Glish standard
// datatype structures. Examples are Quantities, Measures and SkyComponents.
// All of these have a record representation in Glish, and a Data structure in
// C++.
//
// The system (see ForeignArrayParameterAccess.h) can also handle Vectors
// and Arrays of these structures.
//
// To include a new structure in the Tasking system, the following steps are
// necessary:
// <ul>
// <li>	The Glishrecord must, in general, have an ::id attribute to identify
//	the structure type (e.g. meas, quant, comp) (at the moment not
//	essential, but could become so in future)
// <li> If the GlishRecord represents an Array (or Vector) of data records,
//	it must contain a ::shape attribute
// <li> Include the declaration of your structure in ParameterImpl.h
// <li> Define the parameter accessor for your type in ParameterImplN.cc
//	(N to get separate object modules to prevent unnecessary bloat)
// <li> Add the appropiate Parameter<src><></src> templates
// <li> Add the appropiate ParameterAccessor<src><></src> templates
// <li> If the to/fromRecord() methods can be called directly:<br>
//	Add the appropiate ForeignParameterAccessor<src><></src> templates, and, if
//	necessary, the ForeignArrayParameterAccessor<src><></src> and
//	ForeignVectorParameterAccessor<src><></src> templates
// <li> If the to/fromRecord() methods cannot be called directly:<br>
//	Add the appropiate ForeignNSParameterAccessor<src><></src> templates, and, if
//	necessary, the ForeignNSArrayParameterAccessor<src><></src> and
//	ForeignNSVectorParameterAccessor<src><></src> templates<br>
//	and: Add the to/fromRecord/fromString implementation in 
//	ForeignNParameterAccessor.cc
//	(see Foreign2ParameterAccessor for an example)
// </ul>
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


template<class T> class ForeignParameterAccessor 
: public ForeignBaseParameterAccessor<T> {
 public:
 //# Constructors
  // Constructor
  ForeignParameterAccessor(const String & name,
			   ParameterSet::Direction direction,
			   GlishRecord * values);
  //# Destructor
  // Destructor
  ~ForeignParameterAccessor();
  
  //# Member functions
  // Convert a Glish record to a C++ structure
  virtual Bool fromRecord(String & error);
  // Convert a C++ structure to a Glish Record
  virtual Bool toRecord(String & error) const;
 private:
  //# Constructors
  // Default constructor (not implemented)
  ForeignParameterAccessor();

  //# Make template-independent parent members known
public:
  using ForeignBaseParameterAccessor<T>::name;
  using ForeignBaseParameterAccessor<T>::operator();
protected:
  using ForeignBaseParameterAccessor<T>::values_p;
  using ForeignBaseParameterAccessor<T>::value_p;
};

// <summary> Class to access non-standard foreign Glish data structures </summary>

// <use visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// See ForeignParameterAccessor
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


template<class T> class ForeignNSParameterAccessor 
: public ForeignBaseParameterAccessor<T> {
 public:
  //# Constructors
  // Constructor
  ForeignNSParameterAccessor(const String & name,
			     ParameterSet::Direction direction,
			     GlishRecord * values);
  //# Destructor
  // Destructor
  ~ForeignNSParameterAccessor();
  
  //# Member functions
  // Convert a Glish record to a C++ structure
  virtual Bool fromRecord(String & error);
  // Convert a C++ structure to a Glish Record
  virtual Bool toRecord(String & error) const;
 private:
  //# Constructors
  // Default constructor (not implemented)
  ForeignNSParameterAccessor();

  //# Make template-independent parent members known
public:
  using ForeignBaseParameterAccessor<T>::name;
  using ForeignBaseParameterAccessor<T>::operator();
protected:
  using ForeignBaseParameterAccessor<T>::values_p;
  using ForeignBaseParameterAccessor<T>::value_p;
};

//# Global functions
// <summary> Global non-templated functions </summary>
// <synopsis>
// These functions are non-templated, and used in the templated classes.
// They are implemented in Foreign1ParameterAccessor.cc
// </synopsis>
// <group name=Shape>
// Get a scalar record in rec, and test shape. Input name for error
// purposes. Input val is a record. If it has a shape defining 1
// element, the element is used.
// <group>
Bool ForeignParameterAccessorScalar(String &error,
				    GlishRecord &rec,
				    const GlishValue &val,
				    const String &name);
Bool ForeignParameterAccessorScalar(String &error,
				    String &rec,
				    const GlishValue &val,
				    const String &name);
// </group>
// Get the array information of a record (val)
Bool ForeignParameterAccessorArray(String &error,
				   Bool &shapeExist,
				   IPosition &shape,
				   uInt &nelem,
				   const GlishValue &val,
				   const String &name);
// Add the shape attribute
void  ForeignParameterAccessorAddShape(GlishRecord &val,
				       const IPosition &shap);
// Add the id attribute
void  ForeignParameterAccessorAddId(GlishRecord &val,
				    const String &id);
// </group>

// <summary> Global templated interface </summary>
// <synopsis>
// These functions provide the to/from implementations
// Specializations are implemented in ForeignNParameterAccessor.h (N > 1)
// </synopsis>
// <group name=Record>
// Convert to or from a record; from a String; get ID
template <class T>
Bool ForeignFromParameterAccessor(String &error,
				  T &out,
				  const GlishRecord &record);
template <class T>
Bool ForeignStringParameterAccessor(String &error,
				    T &out,
				    const String &record);
template <class T>
Bool ForeignToParameterAccessor(String &error,
				GlishRecord &record,
				const T &in);

template <class T>
const String &ForeignIdParameterAccessor(const T &in);

// </group>


//# Declare all specializations using a macro.
#define DECLARE_FOREIGNPAR_SPEC(T) \
template <> \
Bool ForeignFromParameterAccessor(String &error, \
				  T &out, \
				  const GlishRecord &record); \
template <> \
Bool ForeignStringParameterAccessor(String &error, \
				    T &out, \
				    const String &record); \
template <> \
Bool ForeignToParameterAccessor(String &error, \
				GlishRecord &record, \
				const T &in); \
template <> \
const String &ForeignIdParameterAccessor(const T &);

DECLARE_FOREIGNPAR_SPEC(String);
DECLARE_FOREIGNPAR_SPEC(Quantum<Double>);
DECLARE_FOREIGNPAR_SPEC(Quantum<Vector<Double> >);
DECLARE_FOREIGNPAR_SPEC(Quantum<Array<Double> >);
DECLARE_FOREIGNPAR_SPEC(MEpoch);
DECLARE_FOREIGNPAR_SPEC(MDoppler);
DECLARE_FOREIGNPAR_SPEC(MDirection);
DECLARE_FOREIGNPAR_SPEC(MFrequency);
DECLARE_FOREIGNPAR_SPEC(MPosition);
DECLARE_FOREIGNPAR_SPEC(MRadialVelocity);
DECLARE_FOREIGNPAR_SPEC(MBaseline);
DECLARE_FOREIGNPAR_SPEC(Muvw);
DECLARE_FOREIGNPAR_SPEC(MEarthMagnetic);


} //# NAMESPACE CASA - END

#ifndef AIPS_NO_TEMPLATE_SRC
#include <tasking/Tasking/ForeignParameterAccessor.cc>
#include <tasking/Tasking/Foreign2ParameterAccessor.cc>
#include <tasking/Tasking/Foreign3ParameterAccessor.cc>
#endif //# AIPS_NO_TEMPLATE_SRC
#endif
