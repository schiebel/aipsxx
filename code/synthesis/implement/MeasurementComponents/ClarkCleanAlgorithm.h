//# ClarkCleanAlgorithm.h: parallel Clark CLEAN algorithm
//# Copyright (C) 1996,1997,1998,1999,2000
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
//# $Id: ClarkCleanAlgorithm.h,v 19.5 2004/11/30 17:50:47 ddebonis Exp $

#ifndef SYNTHESIS_CLARKCLEANALGORITHM_H
#define SYNTHESIS_CLARKCLEANALGORITHM_H

//# Includes
#include <casa/BasicSL/String.h>
#include <casa/Arrays/Array.h>
#include <lattices/Lattices/PagedArray.h>
#include <synthesis/Parallel/Algorithm.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class ClarkCleanAlgorithm : public Algorithm {
 public:
  // Default constructor and destructor
  ClarkCleanAlgorithm();
  ~ClarkCleanAlgorithm();

  // Get the input data and parameters from the controller
  void get();

  // Return the results to the controller
  void put();

  // Return the name of the algorithm
  String &name();

 private:
  // Local copies of the data and input parameters
  PagedArray<Float> *model_sl_p;
  Array<Float>      residual_sl;
  Array<Float>      psf_sf;
  Array<Float>      mask;
  Float        gain;
  Float        threshold;
  Int          numberIterations;
  Int          chan;
  Int          nchan;
  String       myName;
  Int cache_p;

  // Do the Clark CLEAN on the assigned data
  void task();
};


} //# NAMESPACE CASA - END

#endif






