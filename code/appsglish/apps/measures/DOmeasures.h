//# DOmeasures.h: This class gives Glish to Measures connection
//# Copyright (C) 1996,1997,1998,2000,2002
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: DOmeasures.h,v 19.6 2006/08/31 23:39:50 gvandiep Exp $

#ifndef APPSGLISH_DOMEASURES_H
#define APPSGLISH_DOMEASURES_H

//# Includes

#include <casa/aips.h>
#include <tasking/Tasking.h>
#include <measures/Measures/Measure.h>
#include <measures/Measures/MeasFrame.h>

#include <casa/namespace.h>
//# Forward declarations
namespace casa { //# NAMESPACE CASA - BEGIN
class String;
class MeasureHolder;
class MeasComet;
class GlishRecord;
} //# NAMESPACE CASA - END


// <summary> This class gives Glish to Measures connection</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto module=Tasking>Tasking</linkto>
//   <li> <linkto module=Measures>Measures</linkto>
// </prerequisite>

// <etymology>
// Distributed Object and measures
// </etymology>

// <synopsis>
// The class makes the connection between the
// <linkto module=Measures>Measures</linkto> module and the Glish
// distributed object system. It provides a series of Glish callable
// methods. See Aips++ Note 197 for details. <br>
// The parameter interface between Glish and the distributed objects
// knows about Measures, and can convert them. Operations supported
// are all the conversion and testing related ones; both in CLI and a
// GUI related methods.
// <note role=caution>
// The class name is <em>measures</em>, the file name <em>DOmeasures</em>,
// with the actual distributed object in <em>measures.cc, measures.g</em>
// </note>
// </synopsis>

// <example>
// For an example of the class use, see the <src>measures.g</src> application.
// </example>

// <motivation>
// To provide a direct user interface between the user and 
// <linkto module=Measures>Measures</linkto> related calculations and
// conversions; including coordinate and time conversions.
// </motivation>

// <todo asof="1998/08/19">
//  <li> Change to/fromRecord conversions after new Parameter interface
// </todo>

class measures : public ApplicationObject {

public:
  //# Standard constructors/destructors

  measures();
  measures(const measures &other);
  measures &operator=(const measures &other);
  ~measures();

  // Create and get a Frame
  MeasFrame &getFrame();

  // Do a frame fill with a measure
  Bool doframe(const MeasureHolder &in);
  // Do a frame fill with a table name (e.g. comet)
  Bool doframe(const String &in);

  // Convert measure
  Bool measure(String &error, MeasureHolder &out,
	       const MeasureHolder &in, const String &outref,
	       const GlishRecord &off);

  // Create uvw from baseline
  Bool toUvw(String &error, MeasureHolder &out,
	     Vector<Double> &xyz, Vector<Double> &dot,
	     const MeasureHolder &in);

  // Expand vector to baselines
  Bool expand(String &error, MeasureHolder &out,
	      Vector<Double> &xyz,
	      const MeasureHolder &in);
 
  // Required Tasking methods
  // <group>
  virtual String className() const;
  virtual Vector<String> methods() const;
  virtual MethodResult runMethod(uInt which,
				 ParameterSet &parameters,
				 Bool runMethod);
  // </group>

  // Stop tracing
  virtual Vector<String> noTraceMethods() const;

private:
  //# Member functions

  // Get measure type (or "none") from an input measure
  static void getMeasureType(String &out, const GlishRecord &in);

  //# Data
  // The globally used MeasFrame for this DO
  MeasFrame frame_p;
  // The current comet class
  MeasComet *pcomet_p;
};

#endif
