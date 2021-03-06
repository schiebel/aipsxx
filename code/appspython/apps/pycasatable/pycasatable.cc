//# pycasatable.cc: python module for AIPS++ table system
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
//# $Id: pycasatable.cc,v 1.4 2006/09/20 02:38:41 gvandiep Exp $

#include "pycasatable.h"

#include <appspython/Converters/PycExcp.h>
#include <appspython/Converters/PycBasicData.h>
#include <appspython/Converters/PycValueHolder.h>
#include <appspython/Converters/PycRecord.h>
#include <appspython/Converters/PycArray.h>
#include <tables/Tables/TableProxy.h>

#include <boost/python.hpp>

BOOST_PYTHON_MODULE(_pycasatable)
{
  casa::appspython::register_convert_excp();
  casa::appspython::register_convert_casa_string();
  casa::appspython::register_convert_casa_vector<casa::String>();
  casa::appspython::register_convert_casa_vector<casa::Int>();
  casa::appspython::register_convert_casa_iposition();
  casa::appspython::register_convert_casa_valueholder();
  casa::appspython::register_convert_casa_record();
  casa::appspython::register_convert_std_vector<casa::TableProxy>();

  casa::appspython::pytable();
  casa::appspython::pytablerow();
  casa::appspython::pytableiter();
  casa::appspython::pytableindex();
}
