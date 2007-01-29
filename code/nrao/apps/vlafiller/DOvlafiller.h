//# DOvlafiller.h: A class for converting VLA Archive format data to a MS
//# Copyright (C) 1999,2000,2001
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
//# $Id: DOvlafiller.h,v 19.7 2005/05/26 15:53:02 gli Exp $

#ifndef NRAO_DOVLAFILLER_H
#define NRAO_DOVLAFILLER_H

#include <casa/aips.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <casa/BasicSL/String.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <nrao/VLA/VLAFilterSet.h>
#include <nrao/VLA/VLALogicalRecord.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class MVEpoch;
class MVFrequency;
class Path;
} //# NAMESPACE CASA - END


// <summary>A class for converting VLA archive format data to a MS</summary>

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
// same reason the rest of its name must be in lower case. 
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

class vlafiller: public ApplicationObject
{
public:
  // create a vlafiller object. Nothing useful can be done until the input is
  // specified, using the diskinput, tapeinput or onlineinput functions, and
  // the output is specified, using the output functiuon.
  vlafiller( Double freqTolerance = 0.0 );

  // The copy constructor uses reference semantics
  vlafiller(const vlafiller& other);
  
  // The destructor closes the input and output files
  virtual ~vlafiller();
  
  // The assignment operator uses reference semantics
  vlafiller& operator=(const vlafiller& other);
  
  // Read the input data from the specified files on the specied tape device.
  // The first file containing astronomical data is file 1.
  Bool tapeinput(const String& device, const Vector<Int>& files);

  // Read the input data from the specified file on disk.
  Bool diskinput(const String& filename);

  // Read the input data from the online computers.
  Bool onlineinput();

  // Specify the output measurement set filename.  If the specified measurement
  // set does not exist it will be created. If it does exist it will be
  // appended to unless the overwrite flag is set to True, then it will be
  // overwritten. 
  Bool output(const String& msfile, Bool overwrite=False);

  // Only copy data that comes from the specified, case-insensitive project
  // name.
  Bool selectproject(const String& project);

  // Only copy data that was observed between the specified times. The
  // reference frame is assumed to be TAI.
  Bool selecttime(const MVEpoch& start, const MVEpoch& stop);

  // Copy any data that was observed, even partially, within the specified
  // frequency range. The frequenct reference frameis assumed to be TOPO.
  Bool selectfrequency(const MVFrequency& refFrequency,
		       const MVFrequency& bandwidth);

  // Only copy data that comes from records containing the specified,
  // case-insensitive source name and qualifier.
  Bool selectsource(const String& source, const Int qualifier);

  // Only copy data that comes from records containing the specified,
  // subarray id.
  Bool selectsubarray(const Int subarrayId);

  // Only copy data that comes from records were the calibrator code is the
  // specified one. The string must be of length one.
  // Allowed codes are [A-Z], [0-9], `*`, ' ' & '#'.
  Bool selectcalibrator(const String& calcode);

  // Copy the data from the input to the output. The source, sink and filters
  // must have been setup.  Logging on the progress of the data conversion will
  // be done unless the verbose flag is set to False.
  Bool fill(Bool verbose=True);

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

  // the returned vector contains the names of all the methods which are too
  // trivial to warrent automatic logging.
  // This function is required as part of the DO system
  virtual Vector<String> noTraceMethods() const;

  // Run the specified method. This is the function used by the distributed
  // object system to invoke any of the specified member functions in thios
  // class.
  // This function is required as part of the DO system
  virtual MethodResult runMethod(uInt which, ParameterSet & parameters, 
				 Bool runMethod);
private:
  // default constructor will not be used publicly.
  // vlafiller(); // this is ambigurious with vlafiller( Double freqTolerance=0.0);
  Bool checkName(String& errorMessage, Path& fileName);

  enum methods {TAPEINPUT=0, DISKINPUT, ONLINEINPUT, OUTPUT, FILL,
		SELECTPROJECT, SELECTTIME, SELECTFREQUENCY, SELECTSOURCE,
		SELECTSUBARRAY, SELECTCALIBRATOR,
		NUM_METHODS};

  VLALogicalRecord itsDataInput;
  VLAFilterSet itsInputFilter;
  MeasurementSet itsOutput;
  String itsSourceOfData;
  Double itsFreqTolerance;
};
  
  //-------------------------------------------------------------------
  // vlafillerFactory
  // ------------------------
  /**
   * Mechanism to allow non-standard constructors for class
   * vlafiller as an aips++ distributed object.
   */
  //-------------------------------------------------------------------
class vlafillerFactory : public ApplicationObjectFactory
{
 public:
  //-------------------------------------------------------------------
  // make()
  // ------------------------
  /**
   * Override make for non-standard constructors.
   */
  //-------------------------------------------------------------------
   virtual MethodResult make (ApplicationObject*& newObject,
      const String& whichConstructor, ParameterSet& inpRec,
      Bool runConstructor);
 };

#endif
