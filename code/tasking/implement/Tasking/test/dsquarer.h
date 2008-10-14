//# dsquarer.h: Simple demonstration program
//# Copyright (C) 1999
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
//# $Id: dsquarer.h,v 19.4 2004/11/30 17:51:12 ddebonis Exp $

#ifndef TASKING_DSQUARER_H
#define TASKING_DSQUARER_H

//# Includes

#include <casa/aips.h>
#include <tasking/Tasking.h>

#include <casa/namespace.h>
// <summary> Simple demonstration program </summary>

class squarer : public ApplicationObject
{
public:

    // Standard constructors etc. Not needed by the system, but possibly
    // useful for other C++ programmers.
    squarer();
    squarer(const squarer &other);
    squarer &operator=(const squarer &other);
    ~squarer();

    // Computational methods
    Int square(Int val) const;

    // Required methods
    virtual String className() const;
    virtual Vector<String> methods() const;
    virtual MethodResult runMethod(uInt which, 
				   ParameterSet &inputRecord,
				   Bool defineParameters);

    // Optional methods - turn off parameter reporting
    virtual Vector<String> noTraceMethods() const;
};

#endif
