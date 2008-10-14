//# sdfits2ms.cc : Convert a single dish FITS file to a MeasurementSet
//# Copyright (C) 2000,2001
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
//# $Id: sdfits2ms.cc,v 19.5 2005/11/07 21:17:04 wyoung Exp $

//# Includes

#include <tasking/Tasking.h>
#include <appsglish/sdfits2ms/DOsdfits2ms.h>

#include <casa/Exceptions/Error.h>

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
	controller.addMaker("sdfits2ms", 
			    new StandardObjectFactory<sdfits2ms>);
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
    cerr << "usage: sdfits2ms fits_name ms_name\n";
    return False;
  }
  
  String sdfitsName(argv[1]);
  String msName(argv[2]);

  sdfits2ms converter;
  return converter.convert(msName, sdfitsName);
}

