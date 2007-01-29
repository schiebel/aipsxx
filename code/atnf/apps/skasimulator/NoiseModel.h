// NoiseModel - random number generator in the AIPS++ framework
//

#ifndef __NOISEMODEL_HPP
#define __NOISEMODEL_HPP

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
//# $Id: NoiseModel.h,v 1.3 2005/09/19 04:19:10 mvoronko Exp $


// AIPS++ stuff
#include <casa/aips.h>
#include <casa/Exceptions/Error.h>

// pure abstract class, the base class for random generators
struct RandomGenerator {
   virtual casa::Double operator()() const throw(casa::AipsError) = 0;

   virtual ~RandomGenerator(); // void destructor, to allow create
                               // destructors in derived classes
};

// uniform distribution (0,1)
class Uniform01Generator : public RandomGenerator {
   mutable casa::uLong Sn;
public:
    Uniform01Generator(casa::uLong seed = 83534) throw();
    virtual casa::Double operator()() const throw(casa::AipsError);
};



// uniform distribution (min,max)
class UniformGenerator : public Uniform01Generator {
   casa::Double min, max;
public:
    UniformGenerator(casa::Double imin = 0., casa::Double imax = 1.,
                     casa::uLong seed = 83534) throw();
    virtual casa::Double operator()() const throw(casa::AipsError);
};

// Gaussian distribution (mean,dispersion)
class GaussianGenerator : public Uniform01Generator {
   casa::Double mean,dispersion;
public:
   GaussianGenerator(casa::Double imean = 0., casa::Double idisp = 1.,
                casa::uLong seed = 83534) throw();
   virtual double operator()() const throw(casa::AipsError);   
   void setDispersion(casa::Double idisp) throw();
};

#endif // #ifndef __NOISEMODEL_HPP
