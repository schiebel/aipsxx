//# DObutterworthbp.h  a function class that defines a Butterworth bandpass
//# Copyright (C) 2000,2001,2002
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
//#! ========================================================================
//# $Id: DObutterworthbp.h,v 19.5 2004/11/30 17:50:09 ddebonis Exp $

#ifndef APPSGLISH_DOBUTTERWORTHBP_H
#define APPSGLISH_DOBUTTERWORTHBP_H

#include <tasking/Tasking/ApplicationObject.h>
#include <scimath/Functionals/MarshButterworthBandpass.h>
#include <casa/Logging/LogIO.h>

#include <casa/namespace.h>
//# Forward Declarations
namespace casa { //# NAMESPACE CASA - BEGIN
template<class T> class Vector;


// <summary>
// class for creating and accessing Butterworth objects from Glish
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class=""></linkto>
//   <li> <linkto class=""></linkto>
// </prerequisite>
//
// <etymology>
// This class is named after Butterworth Type I polynomials 
// </etymology>
//
// <synopsis>
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// This class was created to support systematic errors in the simulator tool.  
// It can be used by Jones matrix classes to vary gains in a predictable way,
// mimicing natural processes of the atmosphere or instrumental effects.  
// </motivation>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="2001/08/22">
// </todo>
class butterworthbp : public ApplicationObject {
private:

    MarshButterworthBandpass<Double> butt;
    LogIO log_p;

    static const String modenames[];

//    void addInvokeRecord(GlishRecord &rec, const String &classname, 
//			 GlishRecord *args = NULL);
public:
    // create the DO
    butterworthbp();

    // destroy the DO
    ~butterworthbp();

//    GlishRecord marshall();
    void logSummary();

    virtual String className() const;
    virtual Vector<String> methods() const;
    virtual MethodResult runMethod(uInt which,     
                                   ParameterSet &parameters,
                                   Bool runMethod);
    virtual Vector<String> noTraceMethods() const;
};
} //# NAMESPACE CASA - END
#endif
