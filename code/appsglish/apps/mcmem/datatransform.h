//# datatransform.h: Converting between image and data space
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
//# $Id: datatransform.h,v 19.7 2006/01/17 11:25:58 gvandiep Exp $

#ifndef APPSGLISH_DATATRANSFORM_H
#define APPSGLISH_DATATRANSFORM_H

#include <stdio.h>
#include <string>
#include <casa/aips.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/Array.h>

#include <scimath/Mathematics/Convolver.h>

#include <iostream>
#include <fstream>
#include <math.h>

#include <casa/namespace.h>
using std::string;

template<class T> class datatransform 
{
	public:
		datatransform();
		datatransform(Int pparam);
		~datatransform();
	
		Int set_psf(Array<T> &inpsf,Int indim);

		Int image_to_data(Array<T> &inarray,
				  Array<T> &outarray);
		Int data_to_image(Array<T> &inarray,
				  Array<T> &outarray);
	
	private:
		
		Convolver<T> conv;
		T area;
		T *stg;
		Bool del;
		IPosition inpshp,shp;
		Int dim;
};


#endif
