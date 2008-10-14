//# DOalmati2ms.h: the implementation of the almati2ms DO
//# Copyright (C) 1996,1997,1998,2000,2001,2002
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
//# $Id: DOalmati2ms.h,v 19.4 2005/02/03 19:32:38 cvsmgr Exp $

#ifndef ALMA_DOALMATI2MS_H
#define ALMA_DOALMATI2MS_H

#include <casa/aips.h>
#include <casa/Logging/LogIO.h>
#include <alma/MeasurementSets/AlmaTI2MS.h>
#include <tasking/Tasking/ApplicationObject.h>

#include <casa/namespace.h>
// <summary> Implementation of the almati2ms DO
// </summary>

// <visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> AlmaTI2MS
// </prerequisite>
//
// <etymology>
// From "ALMA", "test interferometer" and "Measurement Set".
// </etymology>
//
// <synopsis>
// This class is the interface to glish for the AlmaTI2MS class
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// Glish access to the ALMA-TI to MS tool
// </motivation>
//
// <thrown>
//    <li>
// </thrown>
//
// <todo asof="2001/06/24">
//   <li> 
// </todo>

class almati2ms: public ApplicationObject
{
public:
  // Create a almati2ms object from an ALMA-TI data source 
  // and output MS file name; the output MS can be appended to
  // or over-written
  almati2ms(const String& msfile, const String& fitsin, Bool append);

  // Destructor
  ~almati2ms();

  // Set general options (MS compression and baseband concatenation)
  void setOptions(Bool compress=True, Bool combineBaseBand=True);

  // General data selection
  void select(const Vector<String>& obsMode, const String& chanZero);

  // Fill the MS
  void fill();

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
  virtual MethodResult runMethod(uInt which, 
				 ParameterSet& inputRecord,
				 Bool runMethod);
private:
  // The default constructor is private and undefined
  almati2ms();

  // The copy constructor is private and undefined
  almati2ms(const almati2ms& other);

  // The assignment operator is private and undefined
  almati2ms& operator=(const almati2ms& other);

  // Local copy of an AlmaTI2MS object
  AlmaTI2MS* itsAlmaTI2MS;

  // Enums for each public method
  enum methods {SETOPTIONS=0,
		SELECT,
                FILL,
		NUM_METHODS};

  // This is mutable so that const functions can still send log messages.
  mutable LogIO itsLog;
};
#endif


