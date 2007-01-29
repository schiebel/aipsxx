//# Copyright (C) 1996,1997,1998,1999,2000,2001,2004
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
//# $Id: mdl2csm.cc,v 19.4 2004/11/30 17:50:39 ddebonis Exp $

#include <casa/sstream.h>
#include <casa/fstream.h>
#include <casa/aips.h>
#include <casa/BasicSL/String.h>
#include <components/ComponentModels/ComponentList.h>
#include <components/ComponentModels/SkyComponent.h>
#include <components/ComponentModels/ComponentShape.h>
#include <components/ComponentModels/ComponentType.h>
#include <components/ComponentModels/Flux.h>
#include <casa/Inputs/Input.h>
#include <casa/Arrays/Vector.h>
#include <measures/Measures.h>
#include <measures/Measures/MDirection.h>
#include <casa/OS/Path.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Quanta/MVDirection.h>

#include <casa/namespace.h>
int main(int argc, char *argv[])
{
    try {
	Input inputs(1);    

	inputs.version("$Id: mdl2csm.cc,v 19.4 2004/11/30 17:50:39 ddebonis Exp $");
	inputs.create("in");
	inputs.create("out", "csmTable");
	inputs.readArguments(argc, argv);

	const String filename = inputs.getString("in");
	const String csmTableName = inputs.getString("out");
	ifstream mdlfile;
	mdlfile.open(filename.chars(), ios::in);
	if (!mdlfile) {
	    cerr << "cannot open \"" << filename << "\" for reading.\n";
	    exit(1);
	}

	uInt epoch; 	    	    // MDirection::Ref
	Double dec, ra;     	    // position
	Double stokesI; 	    // component of flux
	Double aSecRA;	    	    // arc seconds relative to ra
	Double aSecDec;	    	    // arc seconds relative to dec;
	Double Q;	    	    // component of flux
	Double U;	    	    // component of flux
	Double V;	    	    // componet of flux

        // read the input file line by line.
	const Int buflen = 128;
	char buf[buflen];
	
	// first line contains epoch type and RA/DEC
	if (mdlfile.getline(buf, buflen)) {
	    istringstream(buf) >> epoch >> ra >> dec;
	} else {
	    cerr << "error reading file \"" << filename << "\"\n";
	    exit(1);
	}

	MDirection pos((MVDirection(Quantity(ra,"deg"),
				    Quantity(dec, "deg"))));
	if (epoch == 1950) {
	    pos.set(MDirection::Ref(MDirection::B1950));
	} else if (epoch == 2000) {
	    pos.set(MDirection::Ref(MDirection::J2000));
	} else {
	    cerr << "unknown direction reference: \"" << epoch << "\"\n";
	    exit(1);
	}

	Vector<Double> flux(4);
	ComponentList csm;

	while (mdlfile.getline(buf, buflen)) {
	    istringstream(buf) >> stokesI >> aSecRA >> aSecDec >> 
		Q >> U >> V;

	    pos.set(MVDirection(Quantity(ra + (aSecRA/3600.), "deg"),
	   	    		Quantity(dec + (aSecDec/3600.), "deg")));
	    flux(0) = stokesI;
	    flux(1) = Q * flux(0) / 100;
	    flux(2) = U * flux(0) / 100;
	    flux(3) = V * flux(0) / 100;

    	    SkyComponent skyC(ComponentType::POINT);
	    skyC.shape().setRefDirection(pos);
	    skyC.flux().setValue(flux);
	    skyC.flux().setUnit("WU");
	    csm.add(skyC);
	}

	// This names the table.  The destructor creates and fills it.
	csm.rename(Path(csmTableName));

    } catch (AipsError x) {
         cerr << "aipserror: error " << x.getMesg() << endl;
         return 1;
    }     
}
