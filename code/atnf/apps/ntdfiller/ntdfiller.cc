//# ntdfiller - Fills NTD data to a MeasurementSet
//# Copyright (C) 2005,2006
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
//# $Id: ntdfiller.cc,v 1.4 2006/01/27 02:59:12 tcornwel Exp $

//# Includes

#include "NTDMSFiller.h"
#include "RealNTDDataSource.h"
#include "SimulatedNTDDataSource.h"

#include <casa/Inputs/Input.h>
#include <casa/Exceptions/Error.h>
#include <casa/OS/File.h>
#include <casa/OS/Time.h> 
#include <tables/Tables.h>

#include <casa/iostream.h>
#include <casa/stdio.h>

const String fillerVersion="NTD MeasurementSet filler version 0.1";

#include <casa/namespace.h>
int main(int argc, char **argv)
{
    try {

      cout << fillerVersion << endl;

	Input inputs(1);


	inputs.create("input",
		      "",
		      "The input file",
		      "String");

	inputs.create("ms",
		      "ntd.ms",
		      "The output aips++ MeasurementSet name",
		      "String");

	inputs.create("observer",
		      "Colin Jacka",
		      "The observer",
		      "String");

	inputs.create("project",
		      "NTD tests",
		      "The project code",
		      "String");

	inputs.create("correlator",
		      "/dev/sda1",
		      "The device name for the correlator",
		      "String");

	inputs.create("obslog",
		      "",
		      "The observing log name",
		      "String");

	inputs.create("interval",
		      "1.0",
		      "Integration interval (s)",
		      "Double");

	inputs.create("integrations",
		      "10",
		      "Number of integration interval",
		      "Integer");

	inputs.create("simulate",
		      "yes",
		      "Simulate data (yes or no)",
		      "String");

	inputs.create("delay",
		      "1",
		      "Delay error (m)",
		      "Double");

	inputs.create("stopfringes",
		      "yes",
		      "Stop fringes (yes or no)",
		      "String");

	inputs.readArguments(argc, argv);

	String inputFilename = inputs.getString("input");
	String msFilename = inputs.getString("ms");
	String observerName = inputs.getString("observer");
	String projectCode = inputs.getString("project");
	String corrDevice = inputs.getString("correlator");
	String obsLog = inputs.getString("obslog");
	Double interval = inputs.getDouble("interval");
	String simulate = inputs.getString("simulate");
	Int integrations = inputs.getInt("integrations");
	Quantity delayError=Quantity(inputs.getDouble("delay"), "m");
	simulate.downcase();
	String stopfringes = inputs.getString("stopfringes");

	// Create an MS
	NTDDataSource* ds=0;
        if(simulate.matches("no")) {
	  cout << "Attaching to real data sources " << endl;
          cout << "Correlator device " << corrDevice << endl;
          cout << "Observation log " << obsLog << endl;
	  ds = new RealNTDDataSource(corrDevice, obsLog, interval);
	}
	else {
	  cout << "Attaching to simulated data sources " << endl;
	  ds = new SimulatedNTDDataSource(interval, integrations,
					  delayError);
	}
	cout << "Type ^C to terminate filling" << endl;

        NTDMSFiller filler(msFilename, observerName, projectCode,
			   stopfringes.matches("yes"));

	filler.fill(*ds);

	cout << "Finished" << endl;
    } catch (AipsError x) {
	cout << "Exception: " << x.getMesg() << endl;
	return 1;
    } 
    return 0;
}
