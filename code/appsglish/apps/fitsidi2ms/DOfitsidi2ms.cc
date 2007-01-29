//# DOfitsidi2ms.cc: this implements the fitsidi2ms DO
//# Copyright (C) 1996,1997,1998,1999,2000,2001
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
//# $Id: DOfitsidi2ms.cc,v 19.8 2005/11/07 21:17:03 wyoung Exp $

#include <appsglish/fitsidi2ms/DOfitsidi2ms.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/ObjectController.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterSet.h>
#include <casa/Exceptions/Error.h>
#include <casa/Logging/LogOrigin.h>
#include <casa/Utilities/Assert.h>
#include <casa/BasicSL/String.h>

#include <casa/namespace.h>
fitsidi2ms::fitsidi2ms(const String& msfile, const String& fitsin)
{
// Construct from an output MS file name and input FITS-IDI data source

  itsLog << LogOrigin("fitsidi2ms", "fitsidi2ms");
  try {
    Bool overWrite = True;
    itsMSFitsIDI = new MSFitsIDI(fitsin, msfile, overWrite);
  }
  catch (AipsError x) {
    itsLog << LogIO::SEVERE << "Failed to create a FITS-IDI converter" 
	   << LogIO::POST;
    throw;
  }
}

void fitsidi2ms::fill() 
{
// Fill the output MS
// 
  // Invoke the fillMS() method
  itsLog << "Filling data to the output MS" << LogIO::POST;
  itsMSFitsIDI->fillMS();
}

String fitsidi2ms::className() const {
  return "fitsidi2ms";
}

Vector<String> fitsidi2ms::methods() const {
  Vector<String> method(NUM_METHODS);
  method(FILL) = "fill";
  return method;
}

Vector<String> fitsidi2ms::noTraceMethods() const {
  return methods();
}

MethodResult fitsidi2ms::runMethod(uInt which, ParameterSet& inputRecord,
				   Bool runMethod) {
  itsLog << LogOrigin("fitsidi2ms", "runMethod");
  static String returnvalString = "returnval";
  
  switch (which) {
  case FILL: {
    if (runMethod) {
      fill();
    }
  }
  break;
  default:
    return error("No such method");
  };

  return ok();
}

