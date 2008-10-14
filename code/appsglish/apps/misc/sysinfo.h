//# sysinfo.h: Miscellaneous info for AIPS++
//# Copyright (C) 1996,2001
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
//# $Id: sysinfo.h,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_SYSINFO_H
#define APPSGLISH_SYSINFO_H

#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>

#include <casa/namespace.h>
// <summary>
// </summary>

// <use visibility=local>   or   <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
//   <li> SomeOtherClass
//   <li> some concept
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <templating arg=T>
//    <li>
//    <li>
// </templating>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>

class sysinfo : public ApplicationObject
{
public:
    sysinfo();
    sysinfo(const sysinfo &other);
    sysinfo &operator=(const sysinfo &other);
    ~sysinfo();

    static Int numcpu();
    static Int memory();
    // Can't be static because the log messages calls id()
    void version(Int &majorv, Int &minorv, Int &patch, String &date,
		 String &info, String &formatted, Bool dolog) const;

    // From $AIPSPATH.
    // <group>
    static String root();
    static String arch();
    static String site();
    static String host();
    // </group>

    virtual String className() const;
    virtual Vector<String> methods() const;
    virtual Vector<String> noTraceMethods() const;
    virtual MethodResult runMethod(uInt which, 
                                   ParameterSet &inputRecord,
                                   Bool runMethod);
};

#endif


