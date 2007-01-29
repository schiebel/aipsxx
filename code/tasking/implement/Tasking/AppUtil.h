//# AppUtil.h: Utilities used by the CLI parameter-setting shell (app.g)
//# Copyright (C) 1996,1997
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
//# Correspondence concerning AIPS++ should be adressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#
//# $Id: 

#ifndef TASKING_APPUTIL_H
#define TASKING_APPUTIL_H

#include <casa/aips.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/Vector.h>
#include <casa/Containers/Record.h>
#include <tasking/Glish/GlishRecord.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary> 
// AppUtil: Utilities used by the CLI parameter-setting shell
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="" demos="">

// <prerequisite>
// </prerequisite>
//
// <etymology>
// From the phrase "Application Utilities".
// </etymology>
//
// <synopsis>
// This module contains utilities used by the command-line interpreter
// parameter-setting shell (app.g), that are most appropriately implemented 
// in C++. These primarily include utilities for reading input commands,
// parsing and translating input command strings into standard Glish, and
// formatting meta information and current parameter values for display.
// </synopsis>
//
// <example>
// <srcblock>
// </srcblock>
// </example>
//
// <motivation>
// The C++ utilities required by app.g are best collected in one
// associated class.
// </motivation>
//
// <todo asof="98/05/13">
// i) minimum match.
// </todo>

class AppUtil
{
 public:
   // Default constructor, and destructor
   AppUtil();
   ~AppUtil();

   // Construct from an instance of the tasking meta-information
   AppUtil (const GlishRecord& meta);

   // Copy constructor and assignment operator
   AppUtil (const AppUtil& other);
   AppUtil& operator= (const AppUtil& other);

   // Format for display
   Vector <String> format (const String& method, const GlishRecord& parms, 
      const Int& width, const Int& gap) const;

   // Read command string
   String readcmd() const;

   // Parse/translate command string into standard Glish
   Vector<String> parse (const GlishRecord& parms, const String& cmd) const;

 private:

   // Pointer to the underlying meta-information
   Record* itsMeta;

   // Function to format a string for display in a multi-line column
   Vector <String> tabulate (const String& line, const Int& colWidth) const;

   // Utility to initialize a buffer
   inline void fillBuf (Char* buffer, const Int& nlen) const;

   // Utility to add elements to a command list
   void pushCmd (Vector <String>& cmdStack, const String& newCmd) 
     const;

   // Utility to check for valid Glish variable name characters
   inline Bool validVarNameChar (const Char& inchar) const;

 };


} //# NAMESPACE CASA - END

#endif
   
  



