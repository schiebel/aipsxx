//# mcmemFactory.h : framework for multiple constructors
//#
//# mcmem class to compute MEM solutions + monte carlo methods 
//#
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
//# $Id: mcmemFactory.h,v 19.6 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_MCMEMFACTORY_H
#define APPSGLISH_MCMEMFACTORY_H

#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class String;
class ParameterSet;
class MethodResult;
} //# NAMESPACE CASA - END

class mcmemFactory: public ApplicationObjectFactory
{
  virtual MethodResult make(ApplicationObject* & newObject,
			    const String & whichConstructor,
			    ParameterSet & parameters,
			    Bool runConstructor);
};

#endif
