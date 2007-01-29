//# PKSMultiBeamDD.h: Base class for Parkes Multibeam DisplayData objects
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003,2004
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
//# $Id: PKSMultiBeamDD.h,v 19.8 2005/06/18 21:19:15 ddebonis Exp $
//
#ifndef TRIALDISPLAY_PKSMULTIBEAMDD_H
#define TRIALDISPLAY_PKSMULTIBEAMDD_H

#include <display/DisplayDatas/PrincipalAxesDD.h>
#include <images/Images/ImageInterface.h>
#include <casa/Arrays/Array.h>
#include <lattices/Lattices/Lattice.h>
#include <lattices/Lattices/MaskedLattice.h>
#include <lattices/Lattices/LatticeStatistics.h>
#include <lattices/Lattices/SubLattice.h>
#include <lattices/Lattices/LatticeConcat.h>

#include <casa/Containers/Record.h>

#include <display/DisplayDatas/ScrollingRasterDD.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// Base class for Parkes Multibeam DisplayData objects
// </summary>

class ScrollingRasterDM;

class PKSMultiBeamDD : public ScrollingRasterDD {

public:
  PKSMultiBeamDD(uInt scanNo = 100);
  virtual ~PKSMultiBeamDD();
  
  virtual void updateLattice(const Record &);
  virtual void updateLattice(Array<Float> &arr, CoordinateSystem &csys) {
    ScrollingRasterDD::updateLattice(arr, csys);
  }
    
  virtual String className() { 
    return String("PKSMultiBeamDD"); 
  }

protected:
  friend class ScrollingRasterDM;
  
  virtual void initLattice(const Record &);
  
  virtual String showValue(const Vector<Double> &world);
  virtual const Unit dataUnit();

  // (Required) copy constructor.
  PKSMultiBeamDD(const PKSMultiBeamDD &other);

  // (Required) copy assignment.
  void operator=(const PKSMultiBeamDD &other);

private:  

};


} //# NAMESPACE CASA - END

#ifndef AIPS_NO_TEMPLATE_SRC
#include <display/DisplayDatas/PKSMultiBeamDD.cc>
#endif //# AIPS_NO_TEMPLATE_SRC
#endif

