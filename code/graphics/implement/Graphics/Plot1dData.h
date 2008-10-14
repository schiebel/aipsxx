//# Plot1dData.h: 
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
//#---------------------------------------------------------------------------
//# $Id: Plot1dData.h,v 19.5 2004/11/30 17:50:25 ddebonis Exp $
//#---------------------------------------------------------------------------
// <todo asof="1995/06/06">
//    <li> The assignment operator and copy ctor create fresh copies
//         of all of the vector member data.  This is required -- because
//         the vectors may have been transient in the client -- but
//         very wasteful -- reference counting makes much more sense.
// </todo>
//#---------------------------------------------------------------------------
#ifndef GRAPHICS_PLOT1DDATA_H
#define GRAPHICS_PLOT1DDATA_H
//#---------------------------------------------------------------------------
#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// #include <graphics/Graphics/Plot1d.h>
//#---------------------------------------------------------------------------

//   <summary>
//   1-d vector plotting class for Plot1d
//   </summary>

//   <synopsis>
//   Plotting class for Plot1d, using specifications from Plot1d and
//   Plot1dSelection
//   </synopsis>

class Plot1dData {
public:
  enum AssociatedYAxis {NoAxis, Y1Axis, Y2Axis};

  Plot1dData ();
  Plot1dData (const Vector <Double> &x, const Vector <Double> &y, 
	      const String &name, Int id, AssociatedYAxis whichYAxis);

  Plot1dData (const Plot1dData &other);
  const Plot1dData& operator = (const Plot1dData &other);

  Bool ok () const;
  const String &name ()  const { return name_; }
  const Int number ()    const { return id_; }
  const Int id ()        const { return id_; }
  Vector <Double> & x () const { return *x_; }
  Vector <Double> & y () const { return *y_; } 

  void setWhichYAxis(AssociatedYAxis axis) { whichYAxis_ = axis; }
  AssociatedYAxis whichYAxis() const { return whichYAxis_; }

  ~Plot1dData ();

private:

  Vector <Double> *x_;
  Vector <Double> *y_;
  String name_;
  Int id_;
  AssociatedYAxis whichYAxis_;
};
//#---------------------------------------------------------------------------

} //# NAMESPACE CASA - END

#endif

