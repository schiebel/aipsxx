// DOSKASimulator distributed object to simulate AIPS++ datasets
//                for simple models and do some experiments related
//                to SKA design

//# Copyright (C) 1999,2000
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: DOSKASimulator.h,v 1.3 2005/09/19 04:19:10 mvoronko Exp $


#include <casa/aips.h>
#include <tasking/Tasking.h>
#include <casa/Arrays/Vector.h>
#include "ImplSKASimulator.h"

class SKASimulator : public casa::ApplicationObject,
                     protected ImplSKASimulator
{
public:
   SKASimulator();
   
   // obligatory methods
   virtual casa::String className() const;
   virtual casa::Vector<casa::String> methods() const;      
   virtual casa::MethodResult runMethod(casa::uInt which,
      casa::ParameterSet &parameters, casa::Bool runMethod);
   // to avoid logging simple functions
   virtual casa::Vector<casa::String> noTraceMethods() const;
};
