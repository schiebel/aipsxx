//# Plot1dSelection.h: a simple class for describing data subsets
//# Copyright (C) 1999,2000
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
//# $Id: Plot1dSelection.h,v 19.5 2004/11/30 17:50:25 ddebonis Exp $

#ifndef GRAPHICS_PLOT1DSELECTION_H
#define GRAPHICS_PLOT1DSELECTION_H

#include <casa/aips.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//#---------------------------------------------------------------------------

//   <summary>
//   A simple class for describing data subsets for Plot1d
//   </summary>

class Plot1dSelection {
public:
  Plot1dSelection (): x0_ (0.0), y0_ (0.0), x1_ (0.0), y1_ (0.0) {;}
  Plot1dSelection (Double x0, Double y0, Double x1, Double y1):
      x0_ (x0), y0_ (y0), x1_ (x1), y1_ (y1) {;}
    // rely upon the compiler for copy ctor, dtor, assignment operator
  Double x0 () {return x0_;}
  Double y0 () {return y0_;}
  Double x1 () {return x1_;}
  Double y1 () {return y1_;}

private:
  Double x0_, y0_, x1_, y1_;
};
//#---------------------------------------------------------------------------


} //# NAMESPACE CASA - END

#endif
