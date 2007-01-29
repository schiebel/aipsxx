//# DOapputil.h: Define the apputil DO 
//# Copyright (C) 1996,1997,2000
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

#ifndef APPSGLISH_DOAPPUTIL_H
#define APPSGLISH_DOAPPUTIL_H

#include <casa/aips.h>
#include <tasking/Tasking.h>
#include <tasking/Tasking/AppUtil.h>

#include <casa/namespace.h>
// <summary> 
// DOapputil: DO for AppUtil class; used by CLI parameter-setting shell
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="" demos="">

// <prerequisite>
//   <li> <linkto class="AppUtil">AppUtil</linkto> module
// </prerequisite>
//
// <etymology>
// The name DOapputil, reflects the packaging of class AppUtil as a DO.
// </etymology>
//
// <synopsis>
// DOapputil makes the class AppUtil available for use by the CLI
// parameter-setting shell, app.g. It binds class AppUtil to Glish,
// and contains only the aips++ DO layer.
// layer.
// </synopsis>
//
// <example>
// <srcblock>
// </srcblock>
// </example>
//
// <motivation>
// DOapputil and AppUtil are kept separate to isolate the DO layer.
// </motivation>
//
// <todo asof="98/05/19">
//
// </todo>

class apputil : public ApplicationObject
{
 public:
   // Default constructor, and destructor
   apputil();
   ~apputil();

   // Construct from an instance of the Tasking meta-information
   apputil (const GlishRecord& meta);

   // Methods required to distribute the class as an aips++ DO
   // i) return the class name
   virtual String className() const;

   // ii) return a list of class methods
   virtual Vector <String> methods() const;

   // iii) return a list of methods for which no logging is required
   virtual Vector <String> noTraceMethods() const;
   
   // iv) Execute individual methods
   virtual MethodResult runMethod (uInt which, ParameterSet& inpRec,
      Bool runMethod);

 private:

   // Pointer to the underlying AppUtil object
   AppUtil* itsAppUtil;

 };

// <summary> 
// apputilfactory: Factory for apputil
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="" demos="">

// <prerequisite>
//   <li> <linkto class="AppUtil">AppUtil</linkto> module
// </prerequisite>
//
// <etymology>
// The name DOapputil, reflects the packaging of class AppUtil as a DO.
// </etymology>
//
// <synopsis>
// DOapputil makes the class AppUtil available for use by the CLI
// parameter-setting shell, app.g. It binds class AppUtil to Glish,
// and contains only the aips++ DO layer.
// layer.
// </synopsis>
//
// <example>
// <srcblock>
// </srcblock>
// </example>
//
// <motivation>
// DOapputil and AppUtil are kept separate to isolate the DO layer.
// </motivation>
//
// <todo asof="98/05/19">
//
// </todo>

class apputilFactory : public ApplicationObjectFactory
{
 public:
   // Mechanism to allow non-standard constructors for class
   // cal as an aips++ distributed object.
   virtual MethodResult make (ApplicationObject*& newObject,
      const String& whichConstructor, ParameterSet& inpRec,
      Bool runConstructor);
 };

#endif
   
  



