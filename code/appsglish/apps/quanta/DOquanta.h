//# DOquanta.h: This class gives Glish to Quantity connection
//# Copyright (C) 1998,2002,2003
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
//# $Id: DOquanta.h,v 19.6 2004/11/30 17:50:09 ddebonis Exp $

#ifndef APPSGLISH_DOQUANTA_H
#define APPSGLISH_DOQUANTA_H

//# Includes

#include <casa/aips.h>
#include <tasking/Tasking.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Quanta/UnitName.h>
#include <casa/stdmap.h>

#include <casa/namespace.h>
//# Forward declarations
namespace casa { //# NAMESPACE CASA - BEGIN
class String;
class GlishRecord;
} //# NAMESPACE CASA - END


// <summary> This class gives Glish to Quantity connection</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto module=Tasking>Tasking</linkto>
//   <li> <linkto class=Quantum>Quantum</linkto>
// </prerequisite>

// <etymology>
// Distributed Object and quanta
// </etymology>

// <synopsis>
// The class makes the connection between <linkto class=Unit>Units</linkto>
// and <linkto class=Quantum>Quantity</linkto> classes and the Glish
// distributed object system. It provides a series of Glish callable
// methods. See Aips++ Note 197 for details. <br>
// The parameter interface between Glish and the distributed objects
// knows about Quantities, and can convert them. Operations supported
// are mathematical (+-*/), comparison and conversion related;
// both in CLI and a GUI related methods.
// <note role=caution>
// The class name is <em>quanta</em>, the file name <em>DOquanta</em>,
// with the actual distributed object in <em>quanta.cc, quanta.g</em>
// </note>
// </synopsis>

// <example>
// For an example of the class use, see the <src>quanta.g</src> application.
// </example>

// <motivation>
// To provide a direct user interface between the user and 
// <linkto module=Quanta>Quanta</linkto> related calculations and
// conversions.
// </motivation>

// <todo asof="1998/08/19">
//  <li> Change to/fromRecord conversions after new Parameter interface
// </todo>

class quanta : public ApplicationObject {

public:
  //# Standard constructors/destructors

  quanta();
  quanta(const quanta &other);
  quanta &operator=(const quanta &other);
  ~quanta();

  // List known units
  static GlishRecord mapit(const String &tp);

  // Give a constant named by the string
  static Quantity constants(const String &in);

  // Make time format from String array
  static Int makeFormT(const GlishArray &in);

  // Make angle format from String array
  static Int makeFormA(const GlishArray &in);
 
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
  // Add a unit name entry to table
  static void mapInsert(GlishRecord &out,
			const String &type, 
			const map<String, UnitName> &mp);

};

#endif
