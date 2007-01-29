//# datatransform.cc: implements the datatransform class 
//#                 : convert between image and data space
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
//# $Id: datatransform.cc,v 19.3 2004/11/30 17:50:08 ddebonis Exp $


#include <datatransform.h>

#include <casa/namespace.h>

//#define DBG

/* Default Constructor */
template<class T> datatransform<T>::datatransform():
		conv()
{
	del = 1;
#ifdef DBG
	cout << "create datatransform " << endl;
#endif
}

/* constructor to be used later with diff input params */
template<class T> datatransform<T>::datatransform(Int pparam):
		conv()
{
#ifdef DBG
	cout << "begin with " << pparam << " !" << endl;
#endif
}

/* Destructor */
template<class T> datatransform<T>::~datatransform()
{
#ifdef DBG
	cout << "done !" << endl;
#endif
}


/* Set the psf for the convolver */
template<class T> Int datatransform<T>::set_psf(Array<T> &inpsf,Int indim)
{
	dim = indim;
	
	if(dim==2)
	{
		Array<T> psf;
		inpshp = inpsf.shape();
		shp = IPosition(2);
		Int sq;
		sq = (Int) sqrt((T)(inpshp[0]));
		
		shp[0]=sq; shp[1]=sq;
		
#ifdef DBG
		cout << " In set_psf : inpshp " << inpshp << endl;
		cout << " In set_psf : shp " << shp << endl;
#endif

		psf = inpsf.reform(shp);
		conv.setPsf(psf);

	}
	else conv.setPsf(inpsf);
	
	return 0;
}


/* Convert from image space to data space */
template<class T> Int datatransform<T>::image_to_data(Array<T> &inarray, Array<T> &outarray)
{
	if(dim==2)
	{
		Array<T> in,out;
		IPosition q(1),qq(2);

		in = inarray.reform(shp);
		conv.circularConv(out,in);
		outarray = out.reform(inpshp);
	}
	else conv.circularConv(outarray,inarray);
	
	return 0;
}


/* Convert from data space to image space */
template<class T> Int datatransform<T>::data_to_image(Array<T> &inarray, Array<T> &outarray)
{
	if(dim==2)
	{
		Array<T> in,out;
		IPosition q(1),qq(2);

		in = inarray.reform(shp);
		conv.circularConv(out,in);
		outarray = out.reform(inpshp);

	}
	else conv.circularConv(outarray,inarray);
	
	return 0;
}

