//# DOapputli.cc: Implementation of DOapputil.h
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
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: 
//----------------------------------------------------------------------------

#include <appsglish/apputil/DOapputil.h>
#include <casa/Utilities/Assert.h>

#include <casa/namespace.h>
//----------------------------------------------------------------------------

apputil::apputil() : itsAppUtil(0)
{
// Default constructor
// Output to private data:
//    itsAppUtil   AppUtil*           Application utility object
//
}

//----------------------------------------------------------------------------

apputil::apputil (const GlishRecord& meta) : itsAppUtil(0)
{
// Constructor using Tasking meta information as input
// Inputs:
//    meta         GlishRecord        Input meta information
// Output to private data:
//    itsAppUtil   AppUtil*           Application utility object
//
   // Create the AppUtil object
   itsAppUtil = new AppUtil (meta);
   AlwaysAssert (itsAppUtil, AipsError);
};

//----------------------------------------------------------------------------

apputil::~apputil()
{
// Destructor
//
   // Delete pointers if they already exist
   if (itsAppUtil) {
      delete itsAppUtil;
   };
};

//----------------------------------------------------------------------------

String apputil::className() const
{
// Return class name for aips++ DO system
// Outputs:
//    className    String    Class name
//
   return "apputil";
};

//----------------------------------------------------------------------------

Vector <String> apputil::methods() const
{
// Return class methods names for aips++ DO system
// Outputs:
//    methods    Vector<String>   apputil method names
//
   Vector <String> method(3);
   Int i = 0;
   method(i++) = "format";
   method(i++) = "readcmd";
   method(i++) = "parse";
//
   return method;
};

//----------------------------------------------------------------------------

Vector <String> apputil::noTraceMethods() const
{
// Methods for which automatic logging by the aips++ DO system is
// not required.
// Outputs:
//    noTraceMethods    Vector<String>   apputil method names for no logging
//
   Vector <String> method(3);
   Int i = 0;
   method(i++) = "format";
   method(i++) = "readcmd";
   method(i++) = "parse";
//
   return method;
};
//----------------------------------------------------------------------------

MethodResult apputilFactory::make (ApplicationObject*& newObject,
   const String& whichConstructor, ParameterSet& inpRec,
   Bool runConstructor)
{
// Mechanism to allow non-standard constructors for the apputil
// class as an aips++ DO
// Inputs:
//    whichConstructor    String            Constructor name
//    inpRec              ParameterSet      Input parameter set
//    runConstructor      Book              Execute constructor ?
// Outputs:
//    newObject           ApplicationObject Constructed object ref.
//
   // Intialization
   MethodResult retval;
   newObject = 0;

   // Case (constructor_type) of:
   // "apputil":
   if (whichConstructor == "apputil") {
      Parameter <GlishRecord> gmeta (inpRec, "meta", ParameterSet::In);
      if (runConstructor) {
         newObject = new apputil (gmeta());
       }
    } else {
      retval = String ("Unknown constructor ") + whichConstructor;
    };

   if (retval.ok() && runConstructor && !newObject) {
      retval = "Memory allocation error";
    };
   return retval;
 };
         
//----------------------------------------------------------------------------

MethodResult apputil::runMethod (uInt which, ParameterSet& inpRec, 
   Bool runMethod)
{
// Mechanism to allow execution of class methods from the 
// aips++ DO system.
// Inputs:
//    which        uInt               Selected method
//    inpRec       ParameterSet       Associated input parameters
//    runMethod    Book               Execute method ?
//
   // Case method number of:
   switch (which) {

      case 0: {
         // format
	Parameter <String> method (inpRec, "method", ParameterSet::In);
         Parameter <GlishRecord> parms (inpRec, "parms", ParameterSet::In);
         Parameter <Int> width (inpRec, "width", ParameterSet::In);
         Parameter <Int> gap (inpRec, "gap", ParameterSet::In);
         Parameter <Vector<String> > returnval (inpRec, "returnval", 
            ParameterSet::Out);
         if (runMethod) {
            returnval() = itsAppUtil->format (method(), parms(), width(), 
               gap());
          };
       }
       break;

      case 1: {
         // readcmd
         Parameter <String> returnval (inpRec, "returnval", ParameterSet::Out);
	 if (runMethod) {
	    returnval() = itsAppUtil->readcmd();
          };
       }
       break;

      case 2: {
         // parse
         Parameter <GlishRecord> parms (inpRec, "parms", ParameterSet::In);
         Parameter <String> cmd (inpRec, "cmd", ParameterSet::In);
	 Parameter <Vector<String> > returnval (inpRec, "returnval",
            ParameterSet::Out);
         if (runMethod) {
	    returnval() = itsAppUtil->parse (parms(), cmd());
          };
       }
       break;

      default: 
         return error ("No such method");
    };
   return ok();
 };

//----------------------------------------------------------------------------







