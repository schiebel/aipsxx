//# pytable.cc: python module for QuantaProxy object.
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
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: pyq.cc,v 1.1 2006/09/27 05:46:45 mmarquar Exp $

#include <casa/Quanta/QuantaProxy.h>
#include <appspython/Converters/PycBasicData.h>
#include <appspython/Converters/PycRecord.h>
#include <boost/python.hpp>
#include <boost/python/args.hpp>

using namespace boost::python;

namespace casa { namespace appspython {
  void pyq()
  {
    class_<QuantaProxy> ("quanta")
      .def (init<>())
      .def ("define", &QuantaProxy::define)
      .def ("fits", &QuantaProxy::fits)
      .def ("constants", &QuantaProxy::constants)
      .def ("unit", &QuantaProxy::unit)
      .def ("mapit", &QuantaProxy::mapit)
      .def ("qfunc1", &QuantaProxy::qfunc1)
      .def ("qfunc2", &QuantaProxy::qfunc2)
      .def ("norm", &QuantaProxy::norm)
      .def ("compare", &QuantaProxy::compare)
      .def ("check", &QuantaProxy::check)
      .def ("pow", &QuantaProxy::pow)
      .def ("toangle", &QuantaProxy::toAngle)
      .def ("totime", &QuantaProxy::toTime)
      .def ("dopcv", &QuantaProxy::dopcv)
      .def ("frqcv", &QuantaProxy::frqcv)
      .def ("splitdate", &QuantaProxy::splitDate)
      .def ("qlogical", &QuantaProxy::qlogical)
      .def ("quant", &QuantaProxy::quant)
      .def ("time", &QuantaProxy::time)
      .def ("angle", &QuantaProxy::angle)
      .def ("tfreq", &QuantaProxy::tfreq)
        ;
  }
}}
