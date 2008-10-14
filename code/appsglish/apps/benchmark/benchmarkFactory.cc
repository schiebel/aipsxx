//# benchmarkFactory.cc: implementation of benchmarkFactory.h
//# Copyright (C) 1997,1998,1999,2001,2002
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
//# $Id: benchmarkFactory.cc,v 19.4 2005/11/07 21:17:03 wyoung Exp $

#include <../benchmark/benchmarkFactory.h>
#include <appsglish/benchmark/DObenchmark.h>

#include <casa/namespace.h>
MethodResult benchmarkFactory::make (ApplicationObject*& newObject,
				     const String& whichConstructor, 
				     ParameterSet& inpRec,
				     Bool runConstructor)
{
// Mechanism to allow general constructors for the benchmark
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
   // "benchmark":
   if (whichConstructor == "benchmark") {
      if (runConstructor) {
         newObject = new benchmark();
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

