//# DataSampling.h: Definition for DataSampling
//# Copyright (C) 1996,1997,1998,1999,2000,2001
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
//# Correspondence concerning AIPS++ should be adressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#
//# $Id: DataSampling.h,v 19.4 2004/11/30 17:50:47 ddebonis Exp $

#ifndef SYNTHESIS_DATASAMPLING_H
#define SYNTHESIS_DATASAMPLING_H

#include <images/Images/ImageInterface.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary> Provides sampling of data for esimation algorithms
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="" demos="">

// <prerequisite>
// </prerequisite>
//
// <etymology>
// Samples Data as needed for various estimation algorithms
// </etymology>
//
// <synopsis> 
// Esimation algorithms such as the Pixon method need sampled
// and unitless versions of the data. This class is a base class
// for such sampling classes. Derived examples are for single
// dish imaging (SDDataSampling) and image deconvolution 
// (ImageDataSampling).
//
// THe calculated quantities are
// <ul>
// <li> The Data Sampling Function: the coordinates of the sampled
// points in some space
// <li> The Data: the actual data points corresponding to the 
// Data Sampling Function
// <li> The Error: the error per data point.
// <li> The Point Response Function in that space
//
// The DataSampling object is constructed with the data sources
// as arguments, and then the calculate method is used to find the
// above quantities. The estimation method may then retrieve the
// data quantities as needed.
// </synopsis> 
//
// <example>
// // Define an estimator
// PixonProcessor pp;
// 
// // Get the model image
// PagedImage<Float> modelImage(modelName);
//
// // Set up the data sampling
// VPSkyJones vp(ms, True, parAngleInc, squintType);
// SDDataSampling ds(ms, vp);
//
// // Calculating data sampling, etc.
//
// ds.calculate(modelImage);
//
// // Finding pixon solution
// pp.calculate(ds);
// </example>
//
// <motivation>
// Define an interface to allow efficient processing of chunks of 
// data
// </motivation>
//
// <todo asof="01/03/03">
// <ul> Derive more examples
// </todo>

class DataSampling  {
public:

  DataSampling();

  // Copy constructor
  DataSampling(const DataSampling &other);

  // Assignment operator
  DataSampling &operator=(const DataSampling &other);

  virtual ~DataSampling();

  const Array<Float>& getDX() const;

  const Array<Float>& getData() const;

  const Array<Float>& getSigma() const;

  const Array<Float>& getPRF() const;

  String getIDLScript() const {return IDLScript_p;};

protected:

  Array<Float> dx_p;
  Array<Float> data_p;
  Array<Float> sigma_p;
  Array<Float> prf_p;

  Int lastRow;

  String IDLScript_p;

  void ok();

};

} //# NAMESPACE CASA - END

#endif
