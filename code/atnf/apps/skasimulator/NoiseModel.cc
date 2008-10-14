// NoiseModel: random number generator in the AIPS++ framework
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
//# $Id: NoiseModel.cc,v 1.3 2005/09/19 04:19:10 mvoronko Exp $


#include "NoiseModel.h"
#include <cmath>
using namespace std;
using namespace casa;

// RandomGenerator

RandomGenerator::~RandomGenerator() {};

// Uniform01Generator -> uniform distribution (0,1)

Uniform01Generator::Uniform01Generator(casa::uLong seed) throw() : Sn(seed)
{
 if (!seed) Sn=rand();
 operator()();
}

Double Uniform01Generator::operator()() const throw(casa::AipsError)
{
 Sn=(casa::uLong)fmod(16807.0*Sn,2147483647.0);
 return (casa::Double)Sn/2147483647;
}

// UniformGenerator -> uniform distribution (min,max)
UniformGenerator::UniformGenerator(casa::Double imin, casa::Double imax,
                  casa::uLong seed) throw() : Uniform01Generator(seed),
		             min(imin), max(imax) {}

Double UniformGenerator::operator()() const throw(casa::AipsError)
{
 return min+(max-min)*Uniform01Generator::operator()();
}

// Gaussian distribution (mean,dispersion)

GaussianGenerator::GaussianGenerator(casa::Double imean, casa::Double idisp,
                                     casa::uLong seed) throw() :
			     Uniform01Generator(seed),
		             mean(imean), dispersion(idisp) {}

Double GaussianGenerator::operator()() const throw(casa::AipsError)
{
 casa::Double uniform1=Uniform01Generator::operator()();
 casa::Double uniform2=Uniform01Generator::operator()();
 return mean+sin(2.*M_PI*uniform1)*sqrt(-2*log(uniform2)*dispersion);
}

void GaussianGenerator::setDispersion(casa::Double idisp) throw()
{
  dispersion=idisp;
}
