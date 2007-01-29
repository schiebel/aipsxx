//# ms2sdfits.cc: This program converts a single dish MS to an SDFITS file
//# Copyright (C) 1999,2000,2001
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
//# $Id: ms2sdfits.cc,v 19.3 2004/11/30 17:50:09 ddebonis Exp $

//# Includes

#include <DOms2sdfits.h>

#include <casa/Exceptions/Error.h>
#include <tasking/Tasking.h>

#include <casa/iostream.h>

#include <casa/namespace.h>
// function to execute when no interpreter is present
Bool convert(int argc, char **argv);

int main(int argc, char **argv)
{
    // this is a kludge - ObjectController needs to be changed to
    // optionally execute a function when there is no interpreter present
    Bool hasInterpreter = (argc > 6 && 
			   String(argv[6]).matches(String("-interpreter")));
    if (hasInterpreter) {
	ObjectController controller(argc, argv);
	controller.addMaker("ms2sdfits", 
			    new StandardObjectFactory<ms2sdfits>);
	controller.loop();
    } else {
	Timer timer;
	Bool result = True;
	try {
	    result = convert(argc, argv);
	} catch (AipsError x) {
	    cerr << x.getMesg() << endl;
	    timer.show("ABORTED:");
	    result = False;
	} 
	if (!result) exit(1);

	timer.show("End Successfully:");
	exit(0);
    }
}

Bool convert(int argc, char **argv)
{
    if (argc != 3) {
	cout << "usage: ms2sdfits msname sdfitsname\n";
	return False;
    }
    
    String msName(argv[1]);
    String sdfitsName(argv[2]);
    
    ms2sdfits converter;
    return converter.convert(sdfitsName, msName);
}

