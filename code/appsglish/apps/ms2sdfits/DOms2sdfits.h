//# DOms2sdfitss.h: this defines the ms2sdfits DO
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
//#
//# $Id: DOms2sdfits.h,v 19.5 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_DOMS2SDFITS_H
#define APPSGLISH_DOMS2SDFITS_H

#include <tasking/Tasking/ApplicationObject.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>

#include <casa/namespace.h>
//# Forward Declarations

// <summary>
// This is the MS to SDFITS converter distributed object (DO).
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class=ApplicationObject>ApplicationObject</linkto>
//   <li> <linkto class=MeasurementSet>MeasurementSet</linkto>
// </prerequisite>
//
// <etymology>
// This is the DO for the ms2sdfits app.
// </etymology>
//
// <synopsis>
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// The ms2sdfits converter needs to run from within Glish hence there
// needs to be a distributed object interface to the converter.
// </motivation>
//
// <todo asof="yyyy/mm/dd">
//   <li> Better error handling, especially when things go wrong.
// </todo>

class ms2sdfits: public ApplicationObject
{
public:
    // the methods
    enum Methods {CONVERT=0, NUMBER_METHODS};

    // make the converter
    ms2sdfits() {;}

    ~ms2sdfits() {;}

    // Convert the indicated MS to an SDFITS file having the indicated name.
    // At the moment, the output SDFITS file must not exist.
    // This returns False if there was an error.
    Bool convert(const String &newsdfitsname, const String &msname);

    // return the name of this object type the distributed object system.
    // This function is required as part of the DO system
    virtual String className() const {return "ms2sdfits";}

    // the returned vector contains the names of all the methods which may be
    // used via the distributed object system.
    // This function is required as part of the DO system
    virtual Vector<String> methods() const;

    // the returned vector contains the names of all the methods which are too
    // trivial to warrent automatic logging.
    // This function is required as part of the DO system
    virtual Vector<String> noTraceMethods() const;

    // Run the specified method. This is the function used by the distributed
    // object system to invoke any of the specified member functions in thios
    // class.
    // This function is required as part of the DO system
    virtual MethodResult runMethod(uInt which, ParameterSet & parameters, 
				   Bool runMethod);
private:
    // undefined and unavailable
    ms2sdfits(const ms2sdfits &other);
    ms2sdfits &operator=(const ms2sdfits &other);
};

#endif

