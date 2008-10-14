// SKASimulator.cc server for the SKA Simulator class
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
//# $Id: skasimulator.cc,v 1.3 2005/09/19 04:19:10 mvoronko Exp $


#include <tasking/Tasking.h>
#include <DOSKASimulator.h>

// instantiate the template
#include <tasking/Tasking/ApplicationObject.cc>
template class casa::StandardObjectFactory<SKASimulator>;

int main(int argc, char **argv)
{
   casa::ObjectController controller(argc,argv);
   controller.addMaker("SKASimulator",
		  new casa::StandardObjectFactory<SKASimulator>);
   controller.loop();
   return 0;
}
