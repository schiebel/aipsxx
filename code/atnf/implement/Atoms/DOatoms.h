//# DOatoms.h: This class gives Glish to ACC connection
//# Copyright (C) 1999,2000,2002
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
//# $Id: DOatoms.h,v 19.3 2004/11/30 17:50:10 ddebonis Exp $

#ifndef ATNF_DOATOMS_H
#define ATNF_DOATOMS_H

//# Includes

#include <casa/aips.h>
#include <tasking/Tasking.h>
#include <atnf/Atoms/servo.hxx>

#include <casa/namespace.h>
//# Forward declarations
namespace casa { //# NAMESPACE CASA - BEGIN
class String;
class GlishRecord;
} //# NAMESPACE CASA - END


// <summary> This class gives Glish to ACC connection</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto module=Tasking>Tasking</linkto>
//   <li> <linkto class=Quantum>Quantum</linkto>
// </prerequisite>

// <etymology>
// Distributed Object and atoms
// </etymology>

// <synopsis>
// Connect an ACC to Glish for formatting etc
// </synopsis>

// <example>
// None as yet
// </example>

// <motivation>
// To provide a direct user interface between Glish and ACC monitoring
// </motivation>

// <todo asof="1998/08/19">
//  <li> Change to/fromRecord conversions after new Parameter interface
// </todo>

class atoms : public ApplicationObject {

public:
  //# Standard constructors/destructors

  atoms();
  atoms(const atoms &other);
  atoms &operator=(const atoms &other);
  ~atoms();

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
  //# Data
  // Client pointer
  //  __client *cl_p;
  CLIENT *cl_p;

  //# Member functions
  // Make a Double from hyper
  // <group>
  Double toDouble(const servoRPC_AbsTime &in) const;
  Double toDouble(const servoRPC_RelTime &in) const;
  // </group>
  // Make connection
  Bool connect(const String &server);
  // Make a pair
  Bool get(GlishRecord &out, String &err, const servoRPC_Pair &in,
		const String &un);
  // Make from datavalue
  Bool get(GlishRecord &out, String &err,
	   const servoRPC_GetNamedValueOut *in,
	   const String nam);
  // Get state
  Bool get(GlishRecord &out, String &err, const servoRPC_State &in);
  // Make from AbsTime
  Bool get(GlishRecord &out, String &err, const servoRPC_AbsTime &in);
};

#endif
