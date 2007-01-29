//# tSimulator.cc:  tSimulator tests the simulator class.
//# Copyright (C) 2000,2003,2004
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
//# $Id: pSimulator.cc,v 1.2 2005/06/16 17:26:37 ddebonis Exp $

//# Includes
#include <casa/fstream.h>	// includes <fstream> and <iostream>
#include <casa/Arrays/Vector.h>
#include <casa/Quanta/Quantum.h>
#include <measures/Measures.h>
#include <measures/Measures/MeasTable.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <casa/System/Aipsrc.h>
#include <tasking/Tasking/Index.h>
#include <casa/BasicSL/String.h>
#include <tasking/Glish/GlishRecord.h>
#include "../../../appsglish/apps/app_image/DOimage.h"
#include "../../../appsglish/apps/imager/DOimager.h"
#include "../../../appsglish/apps/simulator/DOsimulator.h"

#include <casa/namespace.h>

int readSTN(const char * stnfile,
	     Vector<double>& xx,
	     Vector<double>& yy,
	     Vector<double>& zz,
	     Vector<float>& diam) {

	using namespace casa;

	ifstream infile(stnfile);
	if (! infile) {
		cerr << "Unable to open file:" << stnfile << endl;
		return -1;
	}

	int nstations;
	if (! (infile >> nstations)) {
		cout << "Error reading number of stations (Line 1)" << endl;
		return -1;
	}

	double ignoreNum;
	if (! (infile >> ignoreNum >> ignoreNum >> ignoreNum)) {
		cout << "Error reading input file! (Lines 2-3)" << endl;
		return -1;
	}

	xx.resize(nstations);
	yy.resize(nstations);
	zz.resize(nstations);
	diam.resize(nstations);

	char ignoreChar;
	int i=0;
	while (infile >> ignoreChar && infile >> xx[i] && infile >> yy[i] &&
			infile >> zz[i] && infile >> diam[i]) {
		i++;
	}
	if (i != nstations) {
		cout << "Error reading input file!"
		     << endl;
		return -1;
	}

	return 0;
}

int main() {
	using namespace casa;
	
	simulator defaultsim;

	Quantity integrationTime(1,"s");
	Quantity gapTime(1,"s");
	Bool useHourAngle(True);
	Quantity startTime(1,"s");
	Quantity stopTime(882,"s");
	// dm.epoch('iat','2001/01/01');
	// [type=epoch, refer=TAI, m0=[value=51910, unit=d]]
	MEpoch::Ref tmref(MEpoch::TAI);
	MEpoch refTime(Quantity(51910.0,"d"),tmref);
	defaultsim.settimes(integrationTime,gapTime,useHourAngle,
			startTime,stopTime,refTime);
	
	String sourceName("M31SIM");
	// dm.direction('j2000', '0h0m0.0', '-45.00.00.00');
	// [type=direction, refer=J2000, m1=[value=-0.785398163, unit=rad],
	// m0=[unit=rad, value=0]]
	MDirection sourceDirection(Quantity(0.0,"deg"),Quantity(-45.0,"deg"),
			MDirection::Ref(MDirection::J2000));
	Int intsPerPointing(1);
	Int mosPointingsX(21);
	Int mosPointingsY(21);
	Float mosSpacing(1.0);
	Quantity distance;	
	defaultsim.setfield((uInt)1,sourceName,sourceDirection,intsPerPointing,
			mosPointingsX,mosPointingsY,mosSpacing,distance);

	String telname("ALMA");
	Vector<double> x, y, z;
	Vector<float> dishDiameter;
	if (readSTN("ALMA.E.STN", x, y, z, dishDiameter) < 0) exit(-1);
	int size=x.nelements();
	Vector<String> mount(size,"alt-az");
	Vector<String> antName(size);
	Vector<String> tmpS(size,"");
	for (int i=0; i< size; i++) {
		antName[i]="ALMA"+(tmpS[i]).toString(Int(i+1));
	}
	String coordsystem("local");
	// dm.observatory('alma');
	// [type=position, refer=WGS84, m2=[value=5056.8, unit=m],
	// m1=[unit=rad, value=-0.401825164], m0=[unit=rad, value=-1.1825466]]
	// MPosition referenceLocation(Quantity(5056.8,"m"),
	//		       Quantity(-0.401825164,"rad"), 
	//		       Quantity(-1.1825466,"rad"),
	//		       MPosition::WGS84);
	MPosition referenceLocation;
	if (! MeasTable::Observatory(referenceLocation, "alma")) {
		cout << "alma not in MeasTable" << endl;
		exit(-1);
	}	
	defaultsim.setconfig(telname,x,y,z,dishDiameter,mount,
			antName,coordsystem,referenceLocation);

	uInt rowID(1);
	String spwName("F00");
	Quantity freq(130,"GHz");
	Quantity deltafreq(1,"MHz");
	Quantity freqresolution(1,"MHz");
	Int nchannels(1);
	String stokes("RR LL");
	defaultsim.setspwindow(rowID,spwName,freq,deltafreq,
			freqresolution,nchannels,stokes);

	String newMSName("MYNEWSIM.ms");
	Double shadowFraction(0.001);
	Quantity elevationLimit(8.0,"deg");
	Float autocorrwt(0.0);
	// creates MYNEWSIM.ms tables (subdirectory)
	defaultsim.create(newMSName, shadowFraction,
			elevationLimit,autocorrwt);
	defaultsim.close();

	String imagefile("m31.image");
	String fitsfile(Aipsrc::aipsRoot()+"/data/demo/M31.model.fits");
	Index whichhdu(0); //0 for C++; 1 for Glish ???
       	Bool zeroblanks(False);
       	Bool overwrite(True); //GUI needed to ask overwrite permission
	//myimg1:=imagefromfits(outfile=modfile,infile=modfilefits);
	image myimg1(imagefile,fitsfile,whichhdu,zeroblanks,overwrite);
	Vector<Int> imgshape;
	imgshape=myimg1.shape();
	Int imsize;
	imsize=imgshape[0];
	//arr1:=myimg1.getchunk();
	Array<Float> pixels;
	Array<Bool> pixelMask;
	Vector<Index> blc;
	Vector<Index> trc;
	Vector<Int> inc;
	Vector<Index> axes;
	Bool listBoundingBox(False);
	Bool dropDegenerateAxes(False);
	Bool getMask(False);
	myimg1.getchunk(pixels,pixelMask,blc,trc,inc,axes,listBoundingBox,
			dropDegenerateAxes,getMask);
	//myimg1.done();
	myimg1.close();
	
	//myimager := imager(msname);
	MeasurementSet msname(newMSName,Table::Update);
	Bool compress(False);
	imager myimager(msname,compress);
	String mode("none");
	Vector<Int> nchan(1);
	Vector<Int> start(1);
	Vector<Int> step(1);
	MRadialVelocity mStart(Quantity(0,"km/s"));
	MRadialVelocity mStep(Quantity(0,"km/s"));
	Vector<Int> spectralwindowids(1);
	spectralwindowids[0]=0;
	Vector<Int> fieldid(1000);
	for(Int i=0; i < 1000; i++) fieldid[i]=i+1;
	String msSelect(" "); //space has significance
	myimager.setdata(mode,nchan,start,step,mStart,mStep,
			spectralwindowids,fieldid,msSelect);

	Int nx=imsize;
	Int ny=imsize;
	Quantity cellx(0.6,"arcsec");
	Quantity celly(0.6,"arcsec");
	String stokesI("I");
	Bool doShift(True);
	MDirection phaseCenter=sourceDirection;
	Quantity shiftx(0,"arcsec");
	Quantity shifty(0,"arcsec");
	String modeI("mfs");
	Int inchan = nchan[0];
	Int istart = start[0];
	Int istep = step[0];
	//MRadialVelocity mStart;
	//MRadialVelocity mStep;
	//Vector<Int> spectralwindowidsI;
	Int fieldidI(0);
	Int facets(1);
	distance=Quantity(0,"m");
	myimager.setimage(nx,ny,cellx,celly,stokesI,doShift,phaseCenter,
			shiftx,shifty,modeI,inchan,istart,istep,mStart,
			mStep,spectralwindowids,fieldidI,facets,distance);
	String simmodel("m31.model");
	myimager.make(simmodel); // SEVERE error if fieldidI <- 1
	myimager.close();

	//myimg2:=image(simmodel);
	image myimg2(simmodel);
	GlishRecord statsout;
	Vector<Index> axes2;
	GlishRecord regionRecord;
	String mask;
	Vector<String> plotstats(2);
	plotstats[0]="mean";
	plotstats[1]="sigma";
	Vector<Float> includepix;
	Vector<Float> excludepix;
	Bool list(True);
	String pgdevice;
	Int nx2(1);
	Int ny2(1);
	Bool forceNewStorageImage(False);
	Bool forceStorageOnDisk(False);
	Bool robust(False);
	Bool verbose(True);
	myimg2.statistics(statsout,axes2,regionRecord,mask,plotstats,
			includepix,excludepix,list,pgdevice,nx2,
			ny2,forceNewStorageImage,forceStorageOnDisk,
			robust,verbose);
	//Array<Float> pixels;
	//Vector<Index> blc;
	//Vector<Int> inc;
	//Bool listBoundingBox(False);
	Bool replicate(False);
	myimg2.putchunk(pixels,blc,inc,listBoundingBox,replicate);
	GlishRecord header;
	String velocityType("radio");
	//Bool list(True);
	Bool pixelOrder(True);
	cout << myimg2.summary(header,velocityType,list,pixelOrder) << endl;
	myimg2.statistics(statsout,axes2,regionRecord,mask,plotstats,
			includepix,excludepix,list,pgdevice,nx2,
			ny2,forceNewStorageImage,forceStorageOnDisk,
			robust,verbose);
	myimg2.close();
	cout << "Made model image with correct coordinates" << endl;
	cout << "Read in the MS again and predict from this new image" << endl;

//	MeasurementSet msname("MYNEWSIM.ms",Table::Update);
	simulator mysim(msname);

	//Vector<String> imagename(1);
	//imagename(0) = "m31.model";
	//String compList = "";
	Vector<String> modelImage(1);
	modelImage[0]=simmodel;
	String compList("");
	Bool incremental(False);
	mysim.predict(modelImage,compList,incremental);
	mysim.close();
	return 0;
}
