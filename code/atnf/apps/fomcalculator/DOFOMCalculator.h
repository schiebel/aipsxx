// DOFOMCalculator distributed object to calculate Figures Of Merit for
// a given antenna layout
//
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
//# $Id: DOFOMCalculator.h,v 1.2 2005/08/12 01:40:58 mvoronko Exp $


#include <casa/aips.h>
#include <tasking/Tasking.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/BasicSL/Complex.h>
//#include <casa/Quanta/Quantum.h>

class FOMCalculator : public casa::ApplicationObject
{
  // layout of the interferometer
  casa::Vector<casa::Double> x;     // positions of antennae
  casa::Vector<casa::Double> y;
  casa::Vector<casa::Double> z;
  casa::Vector<casa::Double> diam;  // antenna diameters
  
  // array size statistics (cached values)
  mutable casa::Double maxbaseline; // maximum baseline length
  mutable casa::Double maxnsbaseline; // maximum possible N-S baseline component
  mutable casa::Double maxewbaseline; // maximum possible E-W baseline component
  mutable casa::Double areain5km; // fraction of collecting area within 5 km from the
                            // reference position (assuming X,Y,Z are in meters)
  mutable casa::Double areain25km;  // fraction of collecting area within 25 km from the
                              // reference position
  mutable casa::Double areain150km; // fraction of collecting area within 5 km from the
                              // reference position
  mutable casa::Vector<casa::Double> area; // fraction of area vs. distance from the reference position
  mutable casa::Vector<casa::Double> distance; // ----//-----
  mutable casa::Double totalarea;    // total area in meters^2 (assuming the diameter is in metres)
  mutable casa::Double rabaseline; // Mean of the reciprocals to the baseline lengths
                                   // (important for the RFI attenuation)
  mutable casa::Bool isdone_sizestat; // true if all statistics are calculated
  // uv-statistics (cached values)
  mutable casa::Matrix<casa::Double> uvsamples;  // binned uv-coverage
  mutable casa::Matrix<casa::Complex> uvcoords; // Re=u; Im=v; for all bins
  mutable casa::Double meansamp; // mean of uvsamples
  mutable casa::Double varsamp; // variance of uvsamples
  mutable casa::Vector<casa::Double> radmean; // mean of uvsamples for each radial distance
                                  // calculated over all angular cells at given radius
  mutable casa::Vector<casa::Double> radvar; // variance of uvsamples for each radial distance
                                 // calculated over all angular cells at given radius
  mutable casa::Vector<casa::Double> angmean; // mean of uvsamples for each angular sector
                                 // calculated over all radial cells at given sector
  mutable casa::Vector<casa::Double> angvar; // variance of uvsamples for each angular sector
                                 // calculated over all radial cells at given sector
  // 
 public:
      FOMCalculator();
      
      // set layout; all further calculations will be done for this layout
      // ix,iy,iz - global positions of each antenna
      // idiam  - diameter of each antenna
      void setLayout(const casa::Vector<casa::Double> &ix, const casa::Vector<casa::Double> &iy,
                     const casa::Vector<casa::Double> &iz,
                     const casa::Vector<casa::Double> &idiam);

      // uv-plane fill statistics
      //    Input:
      // nradbox - number of radial bins 
      // nangbox - number of angular bins
      // dologscale - if true, logarithm of uv-distance is binned
      // domfs - if true, fracband is a fractional bandwith (0..1) of the
      //         experiment; multifrequency synthesis with infinite
      //          number of channels is assumed
      // dosnapshot - if true, just one visibility per baseline is generated
      //              otherwise observations lasts duration hours with
      //              infinitesimal integration time      
      // fracband - fractional bandwidth (df/f)
      // duration - duration of observations (hours)
      // declination - source declination (degrees)      
      //
      // Output: Modified mutable fields
      // uvsamples - an array with binned uvcoverage (0..nradbox-1,0..nangbox-1)
      // uvcoords  - an array with the same length containing u and v (as a complex
      //             quantity)
      // uv-statistics
      void getUVStats(casa::uInt nradbox, casa::uInt nangbox, casa::Bool dologscale,
                      casa::Bool domfs, casa::Bool dosnapshot, casa::Double fracband,
		      casa::Double duration, casa::Double declination) const throw(casa::String);

      // obligatory methods
      virtual casa::String className() const;
      virtual casa::Vector<casa::String> methods() const;      
      virtual casa::MethodResult runMethod(casa::uInt which,
	 casa::ParameterSet &parameters, casa::Bool runMethod);
      // to avoid logging simple functions
      virtual casa::Vector<casa::String> noTraceMethods() const;
	 
  protected: // supplementary functions
      // update cache with size statistics
      void calcSizeStatistics() const throw(casa::String);

      
      // reference position (core centre). The source will be
      // in transit at this location
      // getReferenceX,Y or Z return the geocetric coordinate of the core
      // default is to return the position of the first antenna in the array
      casa::Double getReferenceX() const throw(casa::String);
      casa::Double getReferenceY() const throw(casa::String);
      casa::Double getReferenceZ() const throw(casa::String);
      //
      // longitude in radians calculated using getReferenceX,Y or Z
      casa::Double getReferenceLongitude() const throw(casa::String);
      // latitude in radians calculated using getReferenceX,Y or Z
      casa::Double getReferenceLatitude() const throw(casa::String);
};
