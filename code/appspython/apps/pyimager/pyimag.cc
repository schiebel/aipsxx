//# pyimag.cc: python module for ImagerProxy object.
//# Copyright (C) 2006
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
//#
//# $Id: pyimag.cc,v 1.1 2007/01/29 04:20:53 mmarquar Exp $

#include <synthesis/MeasurementEquations/ImagerProxy.h>
#include <appspython/Converters/PycBasicData.h>
#include <appspython/Converters/PycRecord.h>
#include <boost/python.hpp>
#include <boost/python/args.hpp>

using namespace boost::python;

namespace casa { namespace appspython {
  void pyimager()
  {
    class_<ImagerProxy> ("Imager")
      .def (init<>())
      .def (init<const String& , Bool>())
      .def ("setimage", &ImagerProxy::setimage)
      .def ("setdata", &ImagerProxy::setdata)
      .def ("setoptions", &ImagerProxy::setoptions)
      .def ("weight", &ImagerProxy::weight)
      .def ("makeimage", &ImagerProxy::makeimage)
      .def ("filter", &ImagerProxy::filter)
      .def ("setmfcontrol", &ImagerProxy::setmfcontrol)
      .def ("setscales", &ImagerProxy::setscales)
      .def ("clean", &ImagerProxy::clean)
      ;
  }
}
}
