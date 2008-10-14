//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,2001,2003
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
//#
//# $Id: ParameterConstraint.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ParameterConstraint.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/Assert.h>
#include <casa/sstream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

template<class T> ParameterConstraint<T>::~ParameterConstraint()
{
    // Nothing
}

template<class T> ParameterRange<T>::ParameterRange(const T &low, const T &high)
  : low_p(low), high_p(high)
{
    AlwaysAssert(low_p <= high_p, AipsError); // Alternative: swap?
}

template<class T>
Bool ParameterRange<T>::valueOK(const T &value, String &error) const
{
    Bool retval = (low_p <= value && value <= high_p);
    if (!retval) {
	ostringstream buffer;
	buffer << "Value (" << value << ") is out of range ["
	       << low_p << "," << high_p << "]";
	error = buffer;
    }
    return retval;
}

template<class T>
ParameterConstraint<T> *ParameterRange<T>::clone() const
{
    return new ParameterRange<T>(*this);
}

} //# NAMESPACE CASA - END

