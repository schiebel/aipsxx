//# Measure.cc: Physical quantities within reference frame
//# Copyright (C) 1995,1996,1997,1998,1999,2000,2001
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
//# $Id: Measure.cc,v 19.4 2004/11/30 17:50:34 ddebonis Exp $

//# Includes
#include <measures/Measures/Measure.h>
#include <casa/Utilities/MUString.h>
#include <casa/iostream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Constants

//# Constructors

//# Destructor
Measure::~Measure() {}

//# Operators

//# Member functions
uInt Measure::giveMe(const String &in, Int N_name, 
		     const String tname[]) {
  return MUString::minimaxNC(in, N_name, tname);
}

const String *const Measure::allTypes(Int &nall, Int &nextra,
				      const uInt *&typ) const {
  static const Int N_name  = 0;
  static const Int N_extra = 0;
  static const String *tname = 0;
  static const uInt *oname = 0;

  nall   = N_name;
  nextra = N_extra;
  typ    = oname;
  return tname;
}

Bool Measure::isModel() const {
  return False;
}

//# Global functions
std::ostream &operator<<(std::ostream &os, const Measure &meas) {
  meas.print(os);
  return os;
}

} //# NAMESPACE CASA - END

