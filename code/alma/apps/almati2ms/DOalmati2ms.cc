//# DOalmati2ms.cc: this implements the almati2ms DO
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
//# $Id: DOalmati2ms.cc,v 19.6 2005/02/07 17:03:08 wyoung Exp $

#include <DOalmati2ms.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/ObjectController.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterSet.h>
#include <casa/Exceptions/Error.h>
#include <casa/Logging/LogOrigin.h>
#include <casa/Utilities/Assert.h>
#include <casa/BasicSL/String.h>

almati2ms::almati2ms(const String& msfile, const String& fitsin,
		     Bool append) 
{
// Construct from an output MS file name and input FITS-IDI data source;
// the output MS can be appended to or overwritten.

  itsLog << LogOrigin("almati2ms", "almati2ms");
  try {
    Bool overWrite = !append;
    itsAlmaTI2MS = new AlmaTI2MS(fitsin, msfile, overWrite);
  }
  catch (AipsError x) {
    itsLog << LogIO::SEVERE << "Failed to create an ALMA-TI converter" 
	   << LogIO::POST;
    throw;
  }
}

almati2ms::~almati2ms()
{
// Destructor

  itsLog << LogOrigin("almati2ms", "~almati2ms");
  try {
    if (itsAlmaTI2MS) delete(itsAlmaTI2MS);
  }
  catch (AipsError x) {
    itsLog << LogIO::SEVERE << "Error closing the ALMA-TI converter" 
	   << LogIO::POST;
    throw;
  }
}

void almati2ms::setOptions(Bool compress, Bool combineBaseBand)
{
// Set general options (MS compression and baseband concatenation)

  // Invoke the setOptions() method
  itsAlmaTI2MS->setOptions(compress, combineBaseBand);

  if (compress) {
    itsLog << "Output MS will be written in compressed format" << LogIO::POST;
  };
  if (!combineBaseBand) {
    itsLog << "Each baseband will be written as a separate spectral window"
	   << LogIO::POST;
  };
};

void almati2ms::select(const Vector<String>& obsMode, const String& chanZero)
{
// General data selection

  // Invoke the select() method
  itsAlmaTI2MS->select(obsMode, chanZero);
};

void almati2ms::fill() 
{
// Fill the output MS
//
  itsLog << LogOrigin("almati2ms", "fill");
  try {
    // Invoke the fill() method
    itsLog << "Filling data to the output MS" << LogIO::POST;
    itsAlmaTI2MS->fill();
  }
  catch (AipsError x) {
    itsLog << LogIO::SEVERE << "Error filling ALMA-TI data" << LogIO::POST;
    throw;
  };
}

String almati2ms::className() const {
  return "almati2ms";
}

Vector<String> almati2ms::methods() const {
  Vector<String> method(NUM_METHODS);
  method(SETOPTIONS) = "setoptions";
  method(SELECT) = "select";
  method(FILL) = "fill";
  return method;
}

Vector<String> almati2ms::noTraceMethods() const {
  return methods();
}

MethodResult almati2ms::runMethod(uInt which, ParameterSet& inputRecord,
				   Bool runMethod) {
  itsLog << LogOrigin("almati2ms", "runMethod");
  static String returnvalString = "returnval";
  
  switch (which) {
  case SETOPTIONS: {
    Parameter<Bool> compress(inputRecord, "compress", ParameterSet::In);
    Parameter<Bool> combineBaseBand(inputRecord, "combinebaseband",
				    ParameterSet::In);
    if (runMethod) {
      setOptions(compress(), combineBaseBand());
    }
  }
  break;

  case SELECT: {
    Parameter<Vector<String> > obsMode(inputRecord, "obsmode",
				       ParameterSet::In);
    Parameter<String> chanZero(inputRecord, "chanzero", ParameterSet::In);
    if (runMethod) {
      select(obsMode(), chanZero());
    }
  }
  break;
      
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

