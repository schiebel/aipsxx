//# numerics.cc: sets up servers for numerics DOs
//# Copyright (C) 1999,2001
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
//# $Id: numerics.cc,v 19.5 2005/11/07 21:17:04 wyoung Exp $

#include <casa/aips.h>
#include <appsglish/numerics/DOfftserver.h>
#include <appsglish/numerics/DOinterpolate1d.h>
#include <appsglish/numerics/DOpolyfitter.h>
#include <appsglish/numerics/DOrandomnumbers.h>
#include <appsglish/numerics/DOsinusoidfitter.h>
#include <appsglish/numerics/DOchebyshev.h>
#include <appsglish/numerics/DObutterworthbp.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <tasking/Tasking/ObjectController.h>

#include <casa/namespace.h>
int main(int argc, char **argv)
{
  ObjectController controller(argc, argv, 0, 0);
  
  controller.addMaker("fftserver", new StandardObjectFactory<fftserver>);
  controller.addMaker("polyfitter", new StandardObjectFactory<polyfitter>);
  controller.addMaker("interpolate1d",
		      new StandardObjectFactory<interpolate1d>);
  controller.addMaker("randomnumbers",
		      new StandardObjectFactory<randomnumbers>);
  controller.addMaker("sinusoidfitter",
		      new StandardObjectFactory<sinusoidfitter>);
  controller.addMaker("chebyshev", new StandardObjectFactory<chebyshev>);
  controller.addMaker("butterworthbp", 
		      new StandardObjectFactory<butterworthbp>);
  controller.loop();
  return 0;
}
