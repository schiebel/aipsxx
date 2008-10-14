//# FITSDefaultValues.h: Static functions to set appropriate default values
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
//# $Id: FITSDefaultValues.h,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_FITSDEFAULTVALUES_H
#define APPSGLISH_FITSDEFAULTVALUES_H

#include <casa/aips.h>
#include <fits/FITS/fits.h>

#include <casa/namespace.h>
// <summary>
// Static functions to set appropriate default values
// </summary>

// <use visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <etymology>
// These are static functions which set default values appropriate for a FITS table.
// </etymology>
//
// <synopsis>
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// It was useful to put these in a central location.  Especially for use in 
// FITSStandardWriter - which is templated.
// </motivation>
//
// <todo asof="2000/10/17">
//   <li> This would probably be useful outside of SDFITS creation.
//   <li> Better default values for Complex and DComplex.
// </todo>

class FITSDefaultValues
{
public:
    static void set(Bool *field) {*field = False;}
    static void set(uChar *field) {*field = '\0';}
    static void set(Short *field) {*field = -1;}
    static void set(Int *field) {*field = -1;}
    static void set(Float *field) {FitsFPUtil::setNaN(*field);}
    static void set(Double *field) {FitsFPUtil::setNaN(*field);}
    //# not sure what the best default value is here
    static void set(Complex *field) {*field = 0.0;}
    static void set(DComplex *field) {*field = 0.0;}
    static void set(String *field) {*field = "";}
private:
};

#endif
