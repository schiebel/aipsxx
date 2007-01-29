//# holog.cc: Server for holog-related distributed objects
//# Copyright (C) 1998
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
//# $Id: holog.cc,v 19.2 2004/11/30 17:50:39 ddebonis Exp $

#include <hologImpl.h>
#include <tasking/Tasking.h>

#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>


#include <casa/namespace.h>
int main(int argc, char **argv)
{
    ObjectController controller(argc, argv);
    String name = "holog";
    hologFactory *factory = new hologFactory;
    controller.addMaker(name, factory);
    controller.loop();
    return 0;

/*
    if (argc < 2) {
	cout << "run as:  holog msName" << endl;
	return 1;
    }
    holog h(argv[1], -1, Vector<Int>());
    h.findPos (0.0001);
    cout << h.getSummary() << endl;
    cout << h.getPositions() << endl;
    h.setStep (65);
    h.clearSumData();
    cout << h.sumData(1,2) << endl;
    h.clearGridData();
    */
}
