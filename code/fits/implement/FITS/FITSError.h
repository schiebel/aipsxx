//# FITSError.h: default FITS error handling function, typdef, and enumeration
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
//#
//# $Id: FITSError.h,v 19.5 2004/11/30 17:50:23 ddebonis Exp $

#ifndef FITS_FITSERROR_H
#define FITS_FITSERROR_H

//#! Includes go here
#include <casa/aips.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// default FITS error handling function, typdef, and enumeration
// </summary>

// <use visibility=export>

// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="" demos="">
// </reviewed>

// <synopsis>
// FITSError contains the enumeration specifying the possible error
// message levels.  It also contains the default error handling function
// for the FITS classes. 
// </synopsis>
//
// <example>
// This example shows how one could set up an error handler
// which does what the FITS classes originally did - just
// send the error message to cout without any indication as
// to the severity of the error message.
// <srcblock>
// void coutErrHandler(const char *errMessage, FITSError::ErrorLevel)
// {  cout << errMessage << endl; }
// 
// FitsInput fin("myFile", FITS::Disk, 10, coutErrHandler);
// </srcblock>
// Any error messages generated by fin will be sent to cout.
// Error handlers for the HDUs would need to be indicated in
// their constructors.  For example:
// <srcblock>
// PrimaryArray<Float> pa(fin, coutErrHandler);
// </srcblock>
// The default error handler is FITSError::defaultHandler which
// sends the error message to the global log sink at the
// severity implied by ErrorLevel.
//
// The error handler only handles the error messages.  It is up to
// the programmer to check for the error status of classes like
// FitsInput.
// </example>
//
// <motivation>
// Originally, FITS error message were simply sent to an ostream.  In
// order to have these error messages go to the AIPS++ logger by default,
// this class was added.  This was made a separate class because both
// BlockIo and FITS need to use this class.  The anticipated replacements 
// for the current FITS classes use a somewhat similar scheme.
// </motivation>

class FITSError
{
public:

    // WARN means that the FITS file is still usable - this generally
    //      happens when parsing the HDU and some minor, recoverable
    //      violation of the FITS rules is detected.
    // SEVERE means that a fatal error has occurred and the FITS file
    //     can not be properly processed.
    enum ErrorLevel { WARN, SEVERE };

    // The default error handler.  The errMessage is posted to
    // the global log sink at the severity implied by ErrorLevel.
    // It is assumed that errMessage is null terminated.
    static void defaultHandler(const char *errMessage, ErrorLevel severity);
};

// <summary>
// Define a typedef for the handler function signature for convenience.
// </summary>

// <use visibility=export>
// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="" demos="">
// </reviewed>

typedef void (*FITSErrorHandler) (const char* errMessage, 
				  FITSError::ErrorLevel severity);

 

} //# NAMESPACE CASA - END

#endif


