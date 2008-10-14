//# DOms2fromms1.h: Definition for ms1 to ms2 converter DO
//# Copyright (C) 2000,2001,2003
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
//# $Id: DOms2fromms1.h,v 19.5 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_DOMS2FROMMS1_H
#define APPSGLISH_DOMS2FROMMS1_H

//# Includes
#include <tasking/Tasking.h>
#include <ms/MeasurementSets/MS1ToMS2Converter.h>


#include <casa/namespace.h>
// <summary>
// Definition for ms1 to ms2 converter DO
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="">
// </reviewed>

// <synopsis>
// This class defines the DO interface for the converter of MS1 to MS2.
// </synopsis>

class ms2fromms1 : public ApplicationObject
{
public :
  ms2fromms1 (const String& ms2,
	    const String& ms1,
	    Bool inPlace);
  ~ms2fromms1();
  Bool convert();

  // Stuff needed for distributing this class
  virtual String className() const;
  virtual Vector<String> methods() const;
  virtual MethodResult runMethod (uInt which, ParameterSet &inputRecord, 
				  Bool runMethod);

private :
  ms2fromms1();
  ms2fromms1 (const ms2fromms1&);
  ms2fromms1& operator= (const ms2fromms1&);

  MS1ToMS2Converter conv_p;
};


#endif
