//# DOms2fromms1.cc: DO for MS2 from MS1 converter
//# Copyright (C) 2000
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
//# $Id: DOms2fromms1.cc,v 19.6 2005/11/07 21:17:04 wyoung Exp $


#include <appsglish/ms/DOms2fromms1.h>
#include <casa/Arrays/Vector.h>


#include <casa/namespace.h>
ms2fromms1::ms2fromms1 (const String& ms2, const String& ms1, Bool inPlace)
: conv_p (ms2, ms1, inPlace)
{}

ms2fromms1::~ms2fromms1() 
{}

Bool ms2fromms1::convert()
{
  return conv_p.convert();
}

String ms2fromms1::className() const
{
  return "ms2fromms1";
}

Vector<String> ms2fromms1::methods() const
{
  Vector<String> method(3);
  Int i=0;
  method(i++) = "convert";
  
  return method;
}

MethodResult ms2fromms1::runMethod (uInt which, 
				  ParameterSet &inputRecord,
				  Bool runMethod)
{
  
  static String returnvalString = "returnval";

  switch (which) {
  case 0: // convert
    {
      Parameter<String>  returnval(inputRecord, returnvalString,
				   ParameterSet::Out);
      if (runMethod) {
	returnval() = convert();
      }
    }
    break;
  }
  return ok();
}
