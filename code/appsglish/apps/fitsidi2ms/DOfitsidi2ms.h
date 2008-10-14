//# DOfitsidi2ms.h: the implementation of the fitsidi2ms DO
//# Copyright (C) 1996,1997,1998,2000,2001
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
//# $Id: DOfitsidi2ms.h,v 19.6 2005/05/23 08:54:53 gvandiep Exp $

#ifndef APPSGLISH_DOFITSIDI2MS_H
#define APPSGLISH_DOFITSIDI2MS_H

#include <casa/aips.h>
#include <msfits/MSFits/MSFitsIDI.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <casa/Logging/LogIO.h>

#include <casa/namespace.h>
// <summary> Implementation of the fitsidi2ms DO
// </summary>

// <visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> MSFitsIDI
// </prerequisite>
//
// <etymology>
// From "FITS", "interferometry data interchange" and "Measurement Set".
// </etymology>
//
// <synopsis>
// This class is the interface to glish for the MSFitsIDI class
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// Glish access to the FITS-IDI to MS tool
// </motivation>
//
// <thrown>
//    <li>
// </thrown>
//
// <todo asof="2001/06/24">
//   <li> 
// </todo>

class fitsidi2ms: public ApplicationObject
{
public:
  // Create a fitsidi2ms object from a FITS-IDI data source 
  // and output MS file name
  fitsidi2ms(const String& msfile, const String& fitsin);

  // Null destructor
  ~fitsidi2ms() {};

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
  fitsidi2ms();

  // The copy constructor is private and undefined
  fitsidi2ms(const fitsidi2ms& other);

  // The assignment operator is private and undefined
  fitsidi2ms& operator=(const fitsidi2ms& other);

  // Local copy of an MSFitsIDI object
  MSFitsIDI* itsMSFitsIDI;

  // Enums for each public method
  enum methods {FILL=0,
		NUM_METHODS};

  // This is mutable so that const functions can still send log messages.
  mutable LogIO itsLog;

};
#endif


