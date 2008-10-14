#include <casa/fstream.h>	// includes <fstream> and <iostream>
#include <casa/Arrays/Vector.h>
#include <casa/Quanta/Quantum.h>
#include <measures/Measures.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <casa/BasicSL/String.h>
#include "../../../appsglish/apps/simulator/DOsimulator.h"

#include <casa/namespace.h>
int main() {
	
	int count=1;
	
	MeasurementSet msname("sim+ALMA+SD/sim+ALMA+SD.ms",Table::Update);
	simulator mysim(msname);

	String ftmachine("both");
	Int cache(0);
	Int tile(16);
	String gridfunction("pb");
	// simulator.g has dm.position('wgs84','0m','0m','0m')
	MPosition mLocation(Quantity(0,"m"),
			Quantity(0,"rad"),
			Quantity(0,"rad"),
			MPosition::Ref(MPosition::WGS84));	
	Float padding(1.3);
	Int facets(1);
	if (! (mysim.setoptions(ftmachine,cache,tile,gridfunction,
			mLocation,padding,facets))) {
			cout << "simulator.setoptions() failed!" << endl;
	}

	// Set the voltage pattern
	Bool dovp(True);
	Bool defaultVP(False);
	String vpTable("sim+ALMA+SD/sim+ALMA+SD.vp");
	Bool doSquint(True);
	Quantity parAngleInc(360,"deg");
	if (! (mysim.setvp(dovp,defaultVP,vpTable,doSquint,parAngleInc))) {
		cout << "simulator:setvp() failed!" << endl;
	}

	Vector<String> modelImage(1,"sim+ALMA+SD/sim+ALMA+SD.model");
	String compList("");
	Bool incremental(False);
	cout << "here: " << count++ << endl;
	if (! (mysim.predict(modelImage,compList,incremental))) {
		cout << "simulator.predict() failed!" << endl;
	}
	cout << "here: " << count++ << endl;

	mysim.close();

	return 0;
}
