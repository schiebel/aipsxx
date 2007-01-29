//# DOcomponentlist.h: A simplified class for manipulating groups of components
//# Copyright (C) 1997,1998,1999,2000,2003
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
//# $Id: DOcomponentlist.h,v 19.7 2004/11/30 17:50:07 ddebonis Exp $

#ifndef APPSGLISH_DOCOMPONENTLIST_H
#define APPSGLISH_DOCOMPONENTLIST_H

#include <casa/aips.h>
#include <components/ComponentModels/ComponentList.h>
#include <components/ComponentModels/ComponentType.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <casa/BasicSL/Complexfwd.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class Index;
class MDirection;
class MFrequency;
class MVAngle;
class MethodResult;
class ObjectID;
class ParameterSet;
class SkyComponent;
class String;
class GlishRecord;
template <class T> class Vector;
} //# NAMESPACE CASA - END


// <summary>A simplified class for manipulating groups of components</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class="SkyCompBase">SkyCompBase</linkto>
//   <li> <linkto class="ComponentList">ComponentList</linkto>
// </prerequisite>
//
// <etymology>
// The name MUST have the 'DO' prefix as this class is derived from
// ApplicationObject, and hence is classified as a distributed object. For the
// same reason the rest of its name must be in lower case. This class is a
// simplified version of the ComponentList class.
// </etymology>
//
// <synopsis>
// This class is a container that allows many SkyComponents to be grouped
// together and manipulated as a group. In this respect this class is identical
// to the <linkto class="ComponentList">ComponentList</linkto> class. The user
// is encouraged to read the synopsis of that class for a general description
// of the capabilities of this class.
//
// This class is differs from the ComponentList class in the following ways:
// <ul>
// <li> All components are indexed starting at one. This means the first
//      component in this class is obtained by <src>component(1)</src> rather
//      than <src>component(0)</src> in the ComponentList class.
// <li> Copies of the components, rather than references, are returned to the
//      user. This means that this class needs a replace function whereas
//      ComponentList does not.
// <li> Components that have been removed from the list are stored in a
//      temporary place. In the ComponentList class once they are deleted they
//      are gone.
// <li> This class is derived from ApplicationObject and follows the AIPS++
//      conventions for "distributed objects". Hence the fuunctions in this
//      class can be made accessible from glish. 
// <li> This class can generate simulated components and add them to the list.
// </ul>
//
// There is a one-to-one correspondence between the functions in the glish
// componentlist object (see the AIPS++ User Reference manual) and functions in
// this class. This is make simplify the porting from glish to C++ of a glish
// script using the componentlist distributed object.
// </synopsis>
//
// <example>
// These examples are coded in the tDOcomponentlist.h file.
// <h4>Example 1:</h4>
// In this example a ComponentList object is created and used to calculate the
// ...
// <srcblock>
// </srcblock>
// </example>
//
// <motivation> 
// This class was written to make the componentlist classes usable from glish
// </motivation>
//
// <thrown>
// <li> AipsError - If an internal inconsistancy is detected, when compiled in 
// debug mode only.
// </thrown>
//
// <todo asof="1998/05/22">
//   <li> Nothing I hope. But I expect users will disagree.
// </todo>

namespace casa {
class componentlist: public ApplicationObject
{
public:
  // Construct a componentlist with no components
  componentlist();

  // Read a componentlist from an existing table. By default the Table is
  // opened read-write. It is recommended that you create a const componentlist
  // if you open the Table read-only. This will insure that you can determine
  // at compile time that you are using functions which do not modify the
  // list. This prevents a runtime exception for being thrown.
  componentlist(const String& filename, const Bool& readonly=False);

  // The copy constructor uses reference semantics
  componentlist(const componentlist& other);

  // The destructor saves the list to disk if it has a name A name can be
  // assigned using the rename member function or specified at construction
  // time.
  virtual ~componentlist();

  // The assignment operator uses reference semantics
  componentlist& operator=(const componentlist& other);
  
  // Add a SkyComponent to the end of the componentlist. The list length is
  // increased by one when using this function.
  void add(SkyComponent component);

  // returns a copy of the specified element in the list.
  SkyComponent component(const Index& which) const;

  // Replace the specified components with the ones in the supplied list.
  void replace(const Vector<Index>& which, const ObjectID& list,
	       const Vector<Index>& whichones);

  // Copy the specified components from the specified componentlist to the end
  // of the current componentlist.
  void concatenate(const ObjectID& list, const Vector<Index>& which);

  // Remove the specified SkyComponents from the componentlist. After removing
  // a component all the components with an indices greater than this one will
  // be reduced. For example in a five element list removing elements [1,3,5]
  // will result in a two element list, now indexed as elements one and two,
  // containing what was previously the second and fourth components. which is
  // a vector than contains indices that MUST be greater than zero and less
  // than or equal to the number of components in the list, as the first
  // component is at which=1. Components are not completely deleted from the
  // list until the purge function is called.
  void remove(const Vector<Index>& which);

  // Permanently remove all the components from the list that have been deleted
  // using the remove function.
  void purge();

  // Replace all the components removed from the list. This cannot replace
  // components that have been removed before the list was last purged.
  void recover();

  // returns the number of elements in the list.
  Int length() const;

  // returns a Vector whose length is the number of elements in the list, and
  // contents are from 1 to the list length. If the list contains no elements
  // the an empty Vector is returned.
  Vector<Index> indices() const;

  // Sort the components in the list using the given criteria. The
  // criteria string is identical to those in the ComponentList::Sort
  // enumerator but the string matching is case insensitive.
  // <thrown>
  // <li> AipsError - If the string cannot be converted into a known criteria
  // </thrown>
  void sort(const String& criteria); 

  // Returns True if all the specified components are physically plausable. See
  // the  isPhysical function in the 
  // <linkto class="SkyCompBase">SkyCompBase</linkto> class 
  // for a precise definition of what this means.
  Bool is_physical(const Vector<Index>& which) const;

  // Return the flux (in Jy) of the component in a pixel of specified size at
  // the specified frequency & direction, . The Vector contains all the
  // polarizations (Stokes I,Q,U,V) of the radiation and will be of length
  // 4. The pixel size is assumed to be square.
  Vector<Double> sample(const MDirection& sampleDir, 
			const MVAngle& pixelLatSize, 
			const MVAngle& pixelLongSize, 
			const MFrequency& centerFreq) const;

  // Make the componentlist persistant by supplying a filename. If the
  // componentlist is already associated with a Table then the Table will be
  // renamed. Hence this function cannot be used with componentlist's that are
  // opened readonly. If a file with the specified filename already exists then
  // a AipsError will be thrown.
  void rename(const String& newName);

  // If the current componentlist is associated with a Table then write the
  // list to disk and close the Table. After executation of this function the
  // componentlist always contains no elements and is not associated with any
  // Table. It is as if the default constructor had just been called. If the
  // current list is not associated with a Table then its contents are lost.
  void close();

  // select the specified component. Throws an exception (AipsError) if the
  // index is out of range, ie. index > length().
  void select(const Vector<Index>& which);

  // deselect the specified component. Throws an exception (AipsError) if the
  // index is out of range, ie. index > length().
  void deselect(const Vector<Index>& which);

  // Returns a Vector indicating which components are selected.
  Vector<Index> selected() const;

  // get the label of the specified component
  String getlabel(const Index& which) const;

  // set the label of the specified components
  void setlabel(const Vector<Index>& which, const String& label);

  // get the flux values of the specified component
  Vector<DComplex> getfluxvalue(const Index& which) const;

  // get the flux unit of the specified component
  String getfluxunit(const Index& which) const;

  // get the polarisation of the flux of the specified component
  String getfluxpol(const Index& which) const;

  // get the errors in the flux of the specified component
  Vector<DComplex> getfluxerror(const Index& which) const;

  // set the flux on the specified components to the specified values with the
  // specified units and polarisation representation.
  void setflux(const Vector<Index>& which,
	       const Vector<DComplex>& values,
	       const String& unitString, const String& polString,
	       const Vector<DComplex>& errors);
  
  // convert the flux on the specified components to the specified units
  void convertfluxunit(const Vector<Index>& which,
		       const String& unitString);
  
  // convert the flux on the specified components to the specified 
  // polarisation representation
  void convertfluxpol(const Vector<Index>& which,
		      const String& polString);
  
  // Return the reference direction of the specified component
  MDirection getrefdir(const Index& which) const;

  // get the RA or dec of the reference direction as a string. The units and
  // precision can be specified. Valid units are any angular units (eg., "rad",
  // "deg") or "time" or "angle". For the latter two the returned string will
  // be HH:MM:SS.sss or +DDD.MM.SS.sss respectively. Parsing of the unit string
  // is case insensitive. The precision is the number of significant digits in
  // the returned value. For time and angle units a precision of two returns
  // only the degrees or hours, four adds the minutes and six includes the
  // integral seconds. Note that RA and Dec really mean the latitude or
  // longitude if the reference is something other than J2000 or B1950.
  String getrefdirra(const Index& which, 
		     const String& unit, const Int prec) const;
  String getrefdirdec(const Index& which,
		      const String& unit, const Int prec) const;

  // return as an uppercase string the reference frame of the current
  // reference direction for the specified component.
  String getrefdirframe(const Index& which) const;

  // set the reference direction of the specified components to the specified
  // value. The units must be either, "time", "angle" or an angular unit (eg.,
  // "rad" or "deg"). If the units are "time" or "angle" then the ra/dec string
  // will be parsed (for special characters like ":" or .) to generate the
  // angular unit. Otherwise the ra/dec string will be treated as a floating
  // point number in the units specified by the corresponding unit string. The
  // parsing of all strings is case insensitive.
  void setrefdir(const Vector<Index>& which,
 		 const String& raval, const String& raunit, 
 		 const String& decval, const String& decunit);

  // set the reference direction frame, of the specified components, to the
  // specified value. No conversions are performed.
  void setrefdirframe(const Vector<Index>& which,
 		      const String& frame);
  
  // convert the reference direction frame, of the specified components, to the
  // specified value.
  void convertrefdir(const Vector<Index>& which,
		     const String& frame);

  // get the shape used by the specified component.
  String shapetype(const Index& which);

  // get the shape part of the component. The returned record may be empty (for
  // a point shape) or contain fields (typically majoraxis, minoraxis and
  // positionangle) that depend on the shape.
  GlishRecord getshape(const Index& which) const;

  // get the errors in the shape part of the component. The returned record may
  // be empty (for a point shape) or contain fields (typically majoraxis,
  // minoraxis and positionangle) that represent the errors in the shape
  // parameters.
  GlishRecord getshapeerror(const Index& which) const;

  // change the shape used by the specified components. The parameters for the
  // shape are contained in the parameters record. Only the fields appropriate
  // to the specified shape are used, other fields are ignored. Does not change
  // the shape if the newType string cannot be translated into a valid shape.
  void setshape(const Vector<Index>& which, const String& newType,
		const GlishRecord& parameters);

  // change the units used by the shape parameters in the specified
  // components. The parameters for the shape are contained in the parameters
  // record and are identical to those used in the setshape function. Only the
  // fields appropriate shape of the specified components are used, other
  // fields are ignored. The specified units must have the same dimensions as
  // the ones currently in use for the specified parameter.
  void convertshape(const Vector<Index>& which,
		    const GlishRecord& parameters);

  // get the spectral model used by the specified component.
  String spectrumtype(const Index& which);

  // get the spectrum part of the component. The returned record always
  // contains a type field (as a string), a frequency field (a frequency
  // measure) and may contain other fields depending on the spectral model.
  GlishRecord getspectrum(const Index& which) const;

  // Return the reference frequency of the specified component
  MFrequency getfreq(const Index& which) const;

  // get the value, unit or reference frame of the reference frequency. The
  // frame is always returned as an uppercase string.
  // <group>
  Double getfreqvalue(const Index& which) const;
  String getfrequnit(const Index& which) const;
  String getfreqframe(const Index& which) const;
  // </group>

  // set the reference frequency of the specified components to the specified
  // value and unit. The units must have the same dimensions as the "Hz".
  void setfreq(const Vector<Index>& which,
	       const Double& value, const String& unit);

  // set the reference direction frame, of the specified components, to the
  // specified value. No conversions are performed.
  void setfreqframe(const Vector<Index>& which,
		    const String& frame);
  
  // convert the reference frequency value to the specified unit.
  void convertfrequnit(const Vector<Index>& which,
		       const String& unit);

  //# convert the reference frequency value to the specified reference frame.
  //# void convertreffreqframe(const Vector<Index>& which,
  //# 	                       const String& frame);

  // change the spectrum used by the specified components. The parameters for
  // the spectrum are contained in the parameters record. Only the fields
  // appropriate to the specified spectrum are used, other fields are
  // ignored. Does not change the spectrum if the newType string cannot be
  // translated into a valid spectral type or if there is any other error.
  void setspectrum(const Vector<Index>& which, const String& newType,
		   const GlishRecord& parameters);
  
  // change the units used by the spectrum parameters in the specified
  // components. The parameters for the spectrum are contained in the
  // parameters record and are identical to those used in the setspectrum
  // function. Only the fields appropriate to the spectrum model of the
  // specified components are used, other fields are ignored. The specified
  // units must have the same dimensions as the ones currently in use for the
  // specified parameter.
  void convertspectrum(const Vector<Index>& which,
		       const GlishRecord& parameters);

  // Add the specified number of components to the list. All the components
  // will be Point components with a flux of 1 Jy in I only, at the J2000 North
  // pole The spectrum is constant. This behaviour will probably change so that
  // all the simulated components are different.
  // <thrown>
  // <li> AipsError - If the number of components to be added is negative.
  // </thrown>
  void simulate(const Int howMany);
  
  // Function which checks the internal data of this class for consistant
  // values. Returns True if everything is fine otherwise returns False.
  Bool DOok() const;

  // return the name of this object type the distributed object system.
  // This function is required as part of the DO system
  virtual String className() const;

  // the returned vector contains the names of all the methods which may be
  // used via the distributed object system.
  // This function is required as part of the DO system
  virtual Vector<String> methods() const;

  // the returned vector contains the names of all the methods which are to
  // trivial to warrent automatic logging.
  // This function is required as part of the DO system
  virtual Vector<String> noTraceMethods() const;

  // Run the specified method. This is the function used by the distributed
  // object system to invoke any of the specified member functions in thios
  // class.
  // This function is required as part of the DO system
  virtual MethodResult runMethod(uInt which, ParameterSet& parameters, 
				 Bool runMethod);
private:
  //# private function to check the flux string
  ComponentType::Polarisation checkFluxPol(const String& polString);
  //# private function to format the angle
  String formatAngle(const Double angle, 
		     const String& unit, const Int prec) const;
  //# private function to check the index is in bounds
  Int checkIndex(const Index& which, const String& function) const;
  //# private function to check all the indicies are in bounds
  Vector<Int> checkIndicies(const Vector<Index>& which,
			    const String& function,
			    const String& message) const;

  enum methods {ADD=0, COMPONENT, REPLACE, CONCATENATE, REMOVE, 
		PURGE, RECOVER,
		LENGTH, INDICES, SORT, 
		SAMPLE, IS_PHYSICAL, 
		RENAME, CLOSE, 
		SELECT, DESELECT, SELECTED, 
		GETFLUXVALUE, GETFLUXUNIT, GETFLUXPOL, GETFLUXERROR, SETFLUX,
		CONVERTFLUXUNIT, CONVERTFLUXPOL, 
		SIMULATE, 
		GETREFDIR, GETREFDIRRA, GETREFDIRDEC, GETREFDIRFRAME,
		SETREFDIR, SETREFDIRFRAME, CONVERTREFDIR, 
		SHAPETYPE, SPECTRUMTYPE,
		GETLABEL, SETLABEL, 
		SETSHAPE, SETSPECTRUM, 
		GETSHAPE, GETSHAPEERROR, CONVERTSHAPE,
		GETSPECTRUM, CONVERTSPECTRUM,
		GETFREQ, GETFREQVALUE, GETFREQUNIT, GETFREQFRAME,
		SETFREQ, SETFREQFRAME, CONVERTFREQUNIT,
		NUM_METHODS};

  ComponentList itsList;
  ComponentList itsBin;
};
}
#endif
