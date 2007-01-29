//# dsquarer.cc: Simple demonstration program
//# Copyright (C) 1996,1999
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
//# $Id: dsquarer.cc,v 19.3 2004/11/30 17:51:12 ddebonis Exp $

#include <tasking/Tasking/test/dsquarer.h>
#include <casa/Arrays.h>

#include <casa/namespace.h>
int main(int argc, char **argv)
{
    ObjectController controller(argc, argv);
    controller.addMaker("squarer", new StandardObjectFactory<squarer>);
    controller.loop();
    return 0;
}

squarer::squarer()
{
    // Nothing
}

squarer::squarer(const squarer &other)
    : ApplicationObject(other)
{
    // Nothing
}

squarer &squarer::operator=(const squarer &other)
{
    // Nothing (much)
    return *this;
}

squarer::~squarer()
{
    // Nothing
}

Int squarer::square(Int val) const
{
    return val*val;
}

String squarer::className() const
{
    return "squarer";
}

Vector<String> squarer::methods() const
{
    Vector<String> tmp(1);
    tmp(0) = "square";
    return tmp;
}

MethodResult squarer::runMethod(uInt which,
					ParameterSet &inputRecord,
					Bool runMethod)
{
  
    static String valName = "val";
    static String returnvalName = "returnval";

    switch (which) {
    case 0:
      {
	// Define or attach
	Parameter<Int> val(inputRecord, valName, ParameterSet::In);
	Parameter<Int> returnval(inputRecord, returnvalName, 
				 ParameterSet::Out);
	if (runMethod) {
	  returnval() = square(val()); // DOIT
	}
      }
    break;
    default:
	return error("Unknown method");
    }
    // If we got here, all is well.
    return ok();
}

Vector<String> squarer::noTraceMethods() const
{
    Vector<String> tmp(1);
    tmp(0) = "square";
    return tmp;
}

