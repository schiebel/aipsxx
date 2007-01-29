//# gbtmsfiller.cc: fill a MS using the GBT FITS files, uses DOgbtmsfiller
//# Copyright (C) 1999,2000,2001,2002,2003
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
//# $Id: gbtmsfiller.cc,v 19.7 2006/07/27 21:12:46 bgarwood Exp $

//# Includes

#include <tasking/Tasking.h>
#include <casa/Inputs.h>
#include <DOgbtmsfiller.h>
#include <casa/Exceptions/Error.h>
#include <casa/iostream.h>

#include <casa/namespace.h>
// function to execute when no interpreter is present
Bool singleFill(int argc, char **argv);

int main(int argc, char **argv)
{
  try {
    // this is a kludge - ObjectController needs to be changed to
    // optionally execute a function when there is no interpreter
    // present
    Bool hasInterpreter = (argc > 6 && 
			   String(argv[6]).matches(String("-interpreter")));
    if (hasInterpreter) {
	ObjectController controller(argc, argv);
	controller.addMaker("gbtmsfiller", 
			    new StandardObjectFactory<gbtmsfiller>);
	controller.loop();
    } else {
	Timer timer;
	Bool result = True;
	try {
	    singleFill(argc, argv);
	} catch (AipsError x) {
	    cerr << x.getMesg() << endl;
	    timer.show("ABORTED:");
	    result = False;
	} 
	if (!result) exit(1);

	timer.show("End Successfully:");
	exit(0);
    }
  } catch (AipsError x) {
    cout << x.getMesg() << endl;
  }
}

Bool singleFill(int argc, char **argv)
{
    Input inputs(1);
    inputs.create("project","",
		  "The project base directory where ScanLog.fits is to be found",
		  "String");
    inputs.create("backend","any","Which backend to fill - defaults to any",
		  "String");
    inputs.create("msrootname","",
		  "The root name to give the output MS, only used when backend is set",
		  "String");
    inputs.create("msdirectory",".",
		  "The the directory where the output MSs will appear",
		  "String");
    inputs.create("mintime","0d",
		  "The minimum time for filling, e.g. 20Nov96-5h20m, or 1996-11-20T5:20, etc",
		  "String");
    inputs.create("maxtime","3000-01-01",
		  "The maximum time for filling, e.g. 20Nov96-5h20m, or 1996-11-20T5:20, etc",
		  "String");
    inputs.create("object", "*", "Object to search for, allows for wildcards",
		  "String");
    inputs.create("minscan","-1","Minimum scan number to fill, -1 implies any are valid",
		  "Integer");
    inputs.create("maxscan","-1","Maximum scan number to fill, -1 implies any are valid",
		  "Integer");
    inputs.create("fillrawpointing","False","Fill the raw pointing columns from the ANTENNA FITS file",
		  "Bool");
    inputs.create("fillrawfocus","False","Fill the raw focus columns from the ANTENNA FITS file",
		  "Bool");
    inputs.create("filllags","False","Fill the raw lags to the LAG_DATA column in the MS",
		  "Bool");
    inputs.create("vv","default","specify the vanVleck correction to use (Schwab, Old, None, Default)",
		  "String");
    inputs.create("smooth","default","specify the smoothing to use (Hanning, Hamming, None, Default)",
		  "String");
    inputs.create("usehighcal","False","Use the HIGH_CAL_TEMP instead of LOW_CAL_TEMP in the Rcvr calibration files",
		  "Bool");
    inputs.create("compresscalcols", "True", "Compress the calibration columns", "Bool");
    inputs.create("vvsize", "65", "Schwab VV table size - must be odd", "Integer");
    inputs.create("usebias", "False", "Use approx. to DC sampler bias in VV corr - Schwab only", "Bool");
    inputs.create("oneacsms", "True"," Fill multi-bank ACS to single MS", "Bool");
    inputs.create("dcbias", "0.0", "A specific dcbias to use, ignored if usebias is True - Schwab only", "Double");
    inputs.create("minbiasfactor", "-1", "A minimum amount to subtract from all lags * 0.5/65536", "Integer");
    inputs.create("fixbadlags", "False", "Fix bad ACS lags when possible", "Bool");
    inputs.create("sigmafactor", "6.0", "Spikes and bad regions when abs(data) > sigmafact*sigma", "Double");
    inputs.create("spikestart", "200", "Start searching for spikes from this lag", "Integer");
    inputs.readArguments(argc, argv);
    gbtmsfiller filler(inputs.getString("project"),
		       inputs.getString("backend"),
		       inputs.getString("msrootname"),
		       inputs.getString("msdirectory"),
		       inputs.getString("mintime"),
		       inputs.getString("maxtime"),
		       inputs.getString("object"),
		       inputs.getInt("minscan"),
		       inputs.getInt("maxscan"),
		       inputs.getBool("fillrawpointing"),
		       inputs.getBool("fillrawfocus"),
		       inputs.getBool("filllags"),
	               inputs.getString("vv"),
                       inputs.getString("smooth"),
		       inputs.getBool("usehighcal"),
		       inputs.getBool("compresscalcols"),
		       inputs.getInt("vvsize"),
		       inputs.getBool("usebias"),
		       inputs.getBool("oneacsms"),
		       inputs.getDouble("dcbias"),
		       inputs.getInt("minbiasfactor"),
		       inputs.getBool("fixbadlags"),
		       inputs.getDouble("sigmafactor"),
		       inputs.getInt("spikestart"));
    return filler.fillall();
}
