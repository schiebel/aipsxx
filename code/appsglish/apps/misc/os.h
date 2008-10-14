//# os.h: DO for accessing os settings
//# Copyright (C) 1996,1997,1999
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
//# $Id: os.h,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_OS_H
#define APPSGLISH_OS_H

//# Includes
#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>

#include <casa/namespace.h>
//# Forward Declarations
namespace casa { //# NAMESPACE CASA - BEGIN
class String;
} //# NAMESPACE CASA - END


// <summary>
// DO for accessing os-specific functions
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class=Tasking>Tasking</linkto>
//   <li> <linkto module=OS>OS</linkto>
// </prerequisite>

// <etymology>
// </etymology>

// <synopsis>
// This class is the connection between the Glish os server, and the
// OS module. It is meant for access to OS-specific functions, in
// particular file handling.
// </synopsis>

// <example>
// </example>

// <motivation>
// </motivation>

// <thrown>
//    <li> AipsError if AIPSPATH or HOME is not defined
// </thrown>

// <todo asof="1997/09/16">
//   <li> Check for feasable extensions
// </todo>


class os : public ApplicationObject
{
public:
  os();
  os (const os& other);
  os& operator= (const os& other);
  ~os();
  
  // Methods needed by the Tasking system.
  // <group>
  virtual String className() const;
  virtual Vector<String> methods() const;
  virtual Vector<String> noTraceMethods() const;
  virtual MethodResult runMethod (uInt which, 
				  ParameterSet& inputRecord,
				  Bool runMethod);
  // </group>
};


#endif


