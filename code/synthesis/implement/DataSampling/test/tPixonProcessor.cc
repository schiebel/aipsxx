//# tPixonProcessor.cc:  this tests PixonProcessor
//# Copyright (C) 1996,1997,1999,2001
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
//# $Id: tPixonProcessor.cc,v 19.5 2005/09/20 07:18:54 gvandiep Exp $

#include <casa/iostream.h>
#include <casa/aips.h>
#include <synthesis/DataSampling/PixonProcessor.h>

#include <casa/namespace.h>
int main()
{
#ifdef HAVE_IDL_LIB
  cout << "Send commands to PixonProcessor" << endl;
  {
    PixonProcessor pp;
    pp.standardTest();
  }
  return 0;
#else
  std::cout << "IDL is not available" << std::endl;
  return 3;     // test is skipped
#endif
};
