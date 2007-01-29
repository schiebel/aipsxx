//# aipsrc.h: DO for accessing aipsrc settings
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
//# $Id: aipsrc.h,v 19.5 2006/12/22 04:49:30 gvandiep Exp $

#ifndef APPSGLISH_AIPSRC_H
#define APPSGLISH_AIPSRC_H

#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class String;
} //# NAMESPACE CASA - END


// <summary>
// DO for accessing aipsrc settings
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class=Tasking>Tasking</linkto>
//   <li> <linkto class=Aipsrc>Aipsrc</linkto>
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// This class is the connection between the Glish aipsrc server, and the
// Aipsrc - AipsrcData classes.
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <thrown>
//    <li> AipsError if AIPSPATH or HOME is not defined
// </thrown>
//
// <todo asof="1997/09/16">
//   <li> Check for feasable extensions
// </todo>

class aipsrc : public ApplicationObject {
public:
  aipsrc();
  aipsrc(const aipsrc &other);
  aipsrc &operator=(const aipsrc &);
  ~aipsrc();
  
  static Bool find(String &value, const String &keyword, Bool usehome);
  static void init();

  // Methods needed by the Tasking system.
  // <group>
  virtual String className() const;
  virtual Vector<String> methods() const;
  virtual Vector<String> noTraceMethods() const;
  virtual MethodResult runMethod(uInt which, 
				 ParameterSet &inputRecord,
				 Bool runMethod);
  // </group>
};

#endif


