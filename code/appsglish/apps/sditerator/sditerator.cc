//# sditerator.cc: DO server for sditerator related DOs
//# Copyright (C) 1996,1997,1999,2000,2001
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
//# $Id: sditerator.cc,v 19.3 2004/11/30 17:50:09 ddebonis Exp $
 
#include <sditeratorDO.h>
#include <sdaveragerDO.h>
#include <tasking/Tasking.h>

#include <casa/OS/Timer.h>

#include <casa/iostream.h>

#include <casa/namespace.h>
int main(int argc, char **argv)
{
  ObjectController controller(argc, argv);
  String sditname = "sditerator";
  controller.addMaker(sditname, new sditeratorFactory);
  String sdavgname = "sdaverager";
  controller.addMaker(sdavgname, new StandardObjectFactory<sdaverager>);
  controller.loop();
  return 0;
}
