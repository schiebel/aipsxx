//# ionosphere.cc: Server for ionosphere-related distributed objects
//# Copyright (C) 1996,1998,2000
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
//# $Id: ionosphere.cc,v 19.5 2005/11/07 21:17:04 wyoung Exp $

#include <tasking/Tasking.h>
#include <appsglish/ionosphere/DOionosphere.h>
#include <appsglish/ionosphere/DOrinex.h>

#include <casa/namespace.h>
int main(int argc, char **argv)
{
    ObjectController controller(argc, argv);
    controller.addMaker(String("ionosphere"), new StandardObjectFactory<ionosphere> );
    controller.addMaker(String("rinex"), new StandardObjectFactory<rinex> );
    controller.loop();
    return 0;
}

