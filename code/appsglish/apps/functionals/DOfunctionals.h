//# DOfunctionals.h: This class gives Glish to Functionals  connection
//# Copyright (C) 2002
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
//# $Id: DOfunctionals.h,v 19.6 2004/11/30 17:50:07 ddebonis Exp $

#ifndef APPSGLISH_DOFUNCTIONALS_H
#define APPSGLISH_DOFUNCTIONALS_H

//# Includes

#include <casa/aips.h>
#include <tasking/Tasking.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>

#include <casa/namespace.h>
//# Forward declarations

// <summary> This class gives Glish to Quantity connection</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto module=Tasking>Tasking</linkto>
//   <li> <linkto module=Functionals>Functionals</linkto>
// </prerequisite>

// <etymology>
// Distributed Object and functionals
// </etymology>

// <synopsis>
// The class makes the connection between the
// <linkto module=Functionals>Functionals</linkto> classes and the Glish
// distributed object system. It provides a series of Glish callable
// methods. See Aips++ Note 197 for details. <br>
// <note role=caution>
// The class name is <em>functionals</em>,
// the file name <em>DOfunctionals</em>,
// with the actual distributed object in <em>functionals.cc, functionals.g</em>
// </note>
// </synopsis>

// <example>
// For an example of the class use, 
// see the <src>functionals.g</src> application in the reference manual.
// </example>

// <motivation>
// To provide a direct user interface between the user and 
// <linkto module=Functionals>Functionals</linkto> related calculations.
// </motivation>

// <todo asof="2002/04/01">
//  <li> Add an expression compiler to improve glish given expressions speed
// </todo>

class functionals : public ApplicationObject {

public:
  //# Constructors/destructors
  functionals();
  functionals(const functionals &other);
  functionals &operator=(const functionals &other);
  ~functionals();
 
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

  //# Member functions

};

#endif
