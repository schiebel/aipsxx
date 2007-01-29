//# sdaveragerDO.cc: this defines sdaverager, which is the sdcalc averager
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
//# $Id: sdaveragerDO.cc,v 19.8 2005/01/10 18:21:20 bgarwood Exp $

//# Includes

#include <sdaveragerDO.h>
#include <sditeratorDO.h>

#include <dish/SDIterators/SDRecord.h>

#include <tasking/Tasking.h>

#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/LogiVector.h>
#include <casa/Arrays/MaskedArray.h>
#include <casa/Arrays/MaskArrIO.h>
#include <casa/Arrays/ArrayIO.h>
#include <casa/Arrays/MaskArrMath.h>
#include <casa/Arrays/Slice.h>
#include <casa/Containers/RecordField.h>
#include <tasking/Glish/GlishRecord.h>
#include <casa/Logging/LogIO.h>
#include <casa/BasicSL/Constants.h>

#include <measures/Measures/MeasConvert.h>

#include <casa/Quanta/QuantumHolder.h>

#include <measures/Measures/VelocityMachine.h>

#include <casa/Utilities/Assert.h>
#include <casa/iostream.h>

#include <casa/namespace.h>
sdaverager::sdaverager()
    : crpix_p(0.0), crpixOrig_p(0.0), crval_p(0.0), crvalOrig_p(0.0),
      cdelt_p(0.0), frest_p(0.0), exposure_p(0.0), duration_p(0.0), 
      cunit_p(""), refframe_p(""), veldef_p(""), 
      weightType_p(NOWEIGHT), alignType_p(NOALIGN), rfshift_p(False),
      axisType_p(OTHER), freqFrame_p(MFrequency::LSR),
      velocityDef_p(MDoppler::OPTICAL), vmach_p(0),
      fftserver_p(0), dtmpInUse_p(False), twoPiI_p(0.0, -C::_2pi),
      hzUnit_p("Hz"), velUnit_p("m/s")
{ ; }

sdaverager::sdaverager(const sdaverager& other) 
    : accumy_p(other.accumy_p), weight_p(other.weight_p),
      crpix_p(other.crpix_p), crpixOrig_p(other.crpixOrig_p), 
      crval_p(other.crval_p), crvalOrig_p(other.crvalOrig_p),
      cdelt_p(other.cdelt_p), frest_p(other.frest_p), 
      weightedtsys_p(other.weightedtsys_p),
      scalarWeight_p(other.scalarWeight_p),
      exposure_p(other.exposure_p), duration_p(other.duration_p),
      cunit_p(other.cunit_p), refframe_p(other.refframe_p), veldef_p(other.veldef_p),
      flag_p(other.flag_p),
      thisScalarWeight_p(other.thisScalarWeight_p),
      weightType_p(other.weightType_p), alignType_p(other.alignType_p),
      rfshift_p(other.rfshift_p),
      axisType_p(other.axisType_p), freqFrame_p(other.freqFrame_p),
      velocityDef_p(other.velocityDef_p), vmach_p(0), fftserver_p(0),
      dtmpInUse_p(False), twoPiI_p(0.0, -C::_2pi), hzUnit_p("Hz"),
      velUnit_p("m/s")
{ ; }

sdaverager& sdaverager::operator=(const sdaverager &other)
{
    if (this != &other) {
	accumy_p.resize(other.accumy_p.shape());
	weight_p.resize(other.weight_p.shape());
	weightedtsys_p.resize(other.weightedtsys_p.nelements());
	scalarWeight_p.resize(other.scalarWeight_p.nelements());
	flag_p.resize(other.flag_p.shape());
	thisScalarWeight_p.resize(other.thisScalarWeight_p.nelements());
	accumy_p = other.accumy_p;
	weight_p = other.weight_p;
	crpix_p = other.crpix_p;
	crpixOrig_p = other.crpixOrig_p;
	crval_p = other.crval_p;
	crvalOrig_p = other.crvalOrig_p;
	cdelt_p = other.cdelt_p;
	frest_p = other.frest_p;
	weightedtsys_p = other.weightedtsys_p;
	scalarWeight_p = other.scalarWeight_p;
	exposure_p = other.exposure_p; 
	duration_p = other.duration_p;
	cunit_p = other.cunit_p;
	refframe_p = other.refframe_p;
	veldef_p = other.veldef_p;
	flag_p = other.flag_p;
	weightType_p = other.weightType_p;
	alignType_p = other.alignType_p;
	rfshift_p = other.rfshift_p; 
	axisType_p = other.axisType_p;
	freqFrame_p = other.freqFrame_p;
	velocityDef_p = other.velocityDef_p;
	// tthisScalarWeight_p does not contain any state
	// information other than its shape
	delete vmach_p;
	vmach_p = 0;

	if (other.vmach_p) {
	    vmach_p = new VelocityMachine(*other.vmach_p);
	    AlwaysAssert(vmach_p, AipsError);
	}

	delete fftserver_p;
	fftserver_p = 0;

	if (other.fftserver_p) {
	    fftserver_p = new FFTServer<Float, Complex>(*other.fftserver_p);
	    AlwaysAssert(fftserver_p, AipsError);
	}
    }
    return *this;
}

sdaverager::~sdaverager() { 
    delete vmach_p;
    vmach_p = 0;

    delete fftserver_p; 
    fftserver_p = 0;
}

Bool sdaverager::clear()
{
    crval_p = cdelt_p = crpix_p = frest_p = 0.0;
    crpixOrig_p = crvalOrig_p = 0.0;
    exposure_p = duration_p;
    cunit_p = "";
    refframe_p = "";
    veldef_p = "";
    accumy_p.resize(0,0);
    weight_p.resize(0,0);
    weightedtsys_p.resize(0);
    scalarWeight_p.resize(0);
    flag_p.resize(0,0);
    thisScalarWeight_p.resize(0);
    axisType_p = OTHER;
    freqFrame_p = MFrequency::LSR;
    velocityDef_p = MDoppler::OPTICAL;
    dtmp_p.resize(0,0);
    ffttmp_p.resize(0);
    delete fftserver_p;
    fftserver_p = 0;
    delete vmach_p;
    vmach_p = 0;
    
    return True;
}

Bool sdaverager::setweighting(const String& option) 
{
    Bool result = True;
    if (option == "WEIGHT")
	weightType_p = WEIGHTVEC;
    else if (option == "TSYS") {
	weightType_p = TSYSTIME;
    } else if (option == "RMS") {
	weightType_p = RMS;
    } else if (option == "NONE") {
	weightType_p = NOWEIGHT;
    } else {
	result = False;
    }
    return result;
}

String sdaverager::getweighting()
{
    String result;
    switch (weightType_p) {
    case RMS: result = "RMS"; break;
    case TSYSTIME: result = "TSYS"; break;
    case WEIGHTVEC: result = "WEIGHT"; break;
    default: result = "NONE"; break;
    }
    return result;
}

Bool sdaverager::setalignment(const String& option)
{
    Bool result = True;
    if (option == "VELOCITY") {
	alignType_p = VELOCITY;
    } else if (option == "XAXIS") {
	alignType_p = XAXIS;
    } else if (option == "NONE") {
	alignType_p = NOALIGN;
    } else {
	result = False;
    }
    return result;
}

String sdaverager::getalignment()
{
    String result;
    switch(alignType_p) {
    case VELOCITY: result = "VELOCITY"; break;
    case XAXIS: result = "XAXIS"; break;
    default: result = "NONE"; break;
    }
    return result;
}

Bool sdaverager::average(SDRecord &sdrecord)
{
    Bool result = False;
    if (accumy_p.nelements() != 0) {
	result = True;
	// resize the sdrecord
	sdrecord.resize(accumy_p.shape());
	if (asScalar(sdrecord.arrType()) == TpComplex) {
	    convertArray(*(sdrecord.carr()), (accumy_p/weight_p));
	} else {
	    *(sdrecord.farr()) = accumy_p / weight_p;
	}
	Vector<Float> newTsys = sqrt(weightedtsys_p/scalarWeight_p);
        for (uInt i=0; i< (*(sdrecord.tsys())).nelements(); i++) {
	  if (isNaN(newTsys[i])) newTsys[i] = floatInf();
        }
        *(sdrecord.tsys()) = newTsys;
	// reconstruct the chan_freq Quantum
	Vector<Double> freqs(accumy_p.shape()(1));
	indgen(freqs);
	freqs -= crpix_p;
	freqs *= cdelt_p;
	freqs += crval_p;
	Quantum<Vector<Double> > qfreqs(freqs,Unit(cunit_p));
	String error;
	if (!QuantumHolder(qfreqs).toRecord(error, *(sdrecord.chan_freq()))) {
	    LogIO os;
	    os << LogIO::SEVERE
	       << LogOrigin("sdaverager","average")
	       << "Unexpected problem converting frequencies to a Quantum Record : "
	       << error
	       << LogIO::POST;
	    return False;
	}

	*(sdrecord.refframe()) = refframe_p;
	*(sdrecord.veldef()) = veldef_p;
	*(sdrecord.restfrequency()) = frest_p;
	*(sdrecord.exposure()) = exposure_p;
	*(sdrecord.duration()) = duration_p;
	*(sdrecord.flag()) = flag_p;
	*(sdrecord.weight()) = weight_p;
    }
    return result;
}

Bool sdaverager::accumulate(const SDRecord &sdrecord)
{
    // make sure that the sdrecord is valid
    if (!sdrecord.isValid()) {
	LogIO os;
	os << LogIO::SEVERE
	   << LogOrigin("sdaverager","accumulate")
	   << "The input sdrecord is not a valid sdrecord."
	   << LogIO::POST;
	return False;
    }
    Matrix<Bool> flag(*(sdrecord.roflag()));
    Vector<Bool> flagRow(flag.nrow());
    Bool allFlagged = True;
    for (uInt i=0;i<flagRow.nelements();i++) {
	flagRow[i] = allEQ(flag.row(i),True);
	allFlagged = allFlagged && flagRow[i];
    }
    if (allFlagged) {
	// nothing is unflagged - nothing to add in here, just return True
	return True;
    }

    LogicalMatrix lflag = flag;

    Vector<Float> tsys(*(sdrecord.rotsys()));
    Matrix<Float> weight(*(sdrecord.roweight()));
    // turn FITS unit map on
    UnitMap::addFITS();
    // extract the chan_freq Quantum from the record and deduce the reference pixel
    // and channel spacing (assumed to be fixed here
    QuantumHolder freqsHolder;
    String errMsg;
    if (!freqsHolder.fromRecord(errMsg, *(sdrecord.rochan_freq()))) {
	LogIO os;
	os << LogIO::SEVERE
	   << LogOrigin("sdaverager","accumulate")
	   << "Unexpected problem extracting chan_freq Quantum from sdrecord : "  << errMsg
	   << LogIO::POST;
	return False;
    }
    Unit funits = freqsHolder.asQuantumVectorDouble().getFullUnit();
    Double crval = *(sdrecord.roreffrequency());
    Double f0 = freqsHolder.asQuantumVectorDouble().getValue()(0);
    Double cdelt = freqsHolder.asQuantumVectorDouble().getValue()(1) - f0;
    // if fr is zero, its not a good value to use, get value from middle of the frequency vector
    if (crval <= 0.0) {
	Int nmid = max(0,Int(freqsHolder.nelements()/2.0 + 0.5));
	crval = freqsHolder.asQuantumVectorDouble().getValue()(nmid);
    }	
    Double crpix = (crval-f0)/cdelt;
    // the above is zero-relative, but accumulate expects it to be 1-relative
    crpix++;

    String cunit = funits.getName();
    String refframe = *(sdrecord.rorefframe());
    String veldef = *(sdrecord.roveldef());
    Double restfrequency = *(sdrecord.rorestfrequency());
    Float exposure = Float(*(sdrecord.roexposure()));
    Float duration = Float(*(sdrecord.roduration()));

    // calculate scalar weight according to the given option
    
    Bool firstPass = accumy_p.nelements() == 0;

    IPosition shape = sdrecord.shape();

    if (firstPass) { 
	// do some resizing first
	accumy_p.resize(shape);
	weight_p.resize(shape);
	thisScalarWeight_p.resize(shape[0]);
	flag_p.resize(shape);
	weightedtsys_p.resize(shape[0]);
	scalarWeight_p.resize(shape[0]);
	// and set the axis types, frame, and definition info
	// frequency or velocity or other via units
	// if its not in the unit map, its an other
	if (Unit(cunit) == hzUnit_p) {
	    axisType_p = FREQ;
	} else if (Unit(cunit) == velUnit_p) {
	    axisType_p = VELO;
	} else {
	    axisType_p = OTHER;
	}
	if (axisType_p != OTHER) {
	    // convert refframe into MFrequency::Types
	    if (!MFrequency::getType(freqFrame_p, refframe) &&
		alignType_p==VELOCITY && ((rfshift_p && axisType_p == VELO) ||
			     (axisType_p == FREQ))) {
		LogIO os;
		os << LogIO::SEVERE
		   << LogOrigin("sdaverager","accumulate")
		   << "The indicated reference frame is unrecognized " << refframe
		   << "\nA known reference frame is required for a rest frequency shift when the axis is VELO"
		   << LogIO::POST;
		return False;
	    }
	    if (!MDoppler::getType(velocityDef_p, veldef)) {
		// fall back on RADIO definition if veldef can't be deciphered
		velocityDef_p = MDoppler::RADIO;
	    }
	}
    } else {	//not first pass
	// additional axis sanity checks
	if ((shape[1]*abs(cdelt -  cdelt_p)/cdelt_p >= 0.1) ||
	    tsys.nelements() != accumy_p.nrow()) {
	    LogIO os;
	    os << LogIO::SEVERE
	       << LogOrigin("sdaverager","accumulate")
	       << "The channel widths differ by too much or "
	       << "the number of data rows is not equal to the number of Tsys elements"
	       << LogIO::POST;
	    return False;
	}
	// for now, require cunit, refframe, and veldef to match previous
	if (cunit != cunit_p || refframe != refframe_p || veldef != veldef_p) {
	    LogIO os;
	    os << LogIO::SEVERE
	       << LogOrigin("sdaverager","accumulate")
	       << "The axis units, reference frame, and velocity definition must be the same for all" 
	       << " scans in the average - this data violates that rule."
	       << LogIO::POST;
	    return False;
	}
	if (alignType_p == VELOCITY) {
	    // require that the axis be a velocity or, if a frequency,
	    // that a rest frequency != NaN and > 0 has been supplied
	    if (axisType_p != VELO && 
		(isNaN(restfrequency) || restfrequency <= 0.0)) {
		LogIO os;
		os << LogIO::SEVERE
		   << LogOrigin("sdaverager","accumulate")
		   << "Velocity alignment for non-velocity axes requires a valid rest frequency"
		   << LogIO::POST;
		return False;
	    }
	    // if rest shifting has been requested, verify that the restfrequency is valid
	    if (rfshift_p && restfrequency != frest_p) {
		if (axisType_p == OTHER ||
		    (axisType_p == VELO &&
		     (isNaN(restfrequency) || restfrequency <= 0.0))) {
		    LogIO os;
		    os << LogIO::SEVERE
		       << LogOrigin("sdaverager","accumulate")
		       << "Frequency shift for velocity axes requires a valid rest frequency"
		       << LogIO::POST;
		    return False;
		}
	    }
	}
    }
	
    // make crpix 0-relative before using it
    crpix -= 1.0;

    const Matrix<Float> *data;
    if (asScalar(sdrecord.arrType()) == TpComplex) {
	data = new Matrix<Float>(real(*(sdrecord.rocarr())));
    } else {
	data = new Matrix<Float>(*(sdrecord.rofarr()));
    }

    switch (weightType_p) {
    case TSYSTIME:
	thisScalarWeight_p = exposure / (tsys * tsys);
	break;
    case RMS:
	// harvey wants this to be a calculated RMS, not from 
	// the header
	// eventually we'll want this to be done only over
	// some range, but for now, do it over all
	// weight by square of rms == variance, by row
	for (Int i=0;i<shape[0];i++) {
	    thisScalarWeight_p[i] = variance((data->row(i))(flag.row(i) == False));
	}
	break;
    case WEIGHTVEC:
	for (Int i=0;i<shape[0];i++) {
	    thisScalarWeight_p[i] = mean(weight.row(i));
	}
	break;
    default:
	thisScalarWeight_p = 1.0;
    }
    
    // watch for NaNs here
    for (uInt i=0; i<thisScalarWeight_p.nelements(); i++) {
      if (isNaN(thisScalarWeight_p[i])) thisScalarWeight_p[i] = 0.0;
    }

    if (weightType_p != WEIGHTVEC) {
	for (uInt i=0;i<weight.nrow();i++) {
	    weight.row(i) = thisScalarWeight_p[i];
	    weight.row(i)(flag.row(i)) = 0.0;
	}
    } else {
	for (uInt i=0;i<weight.nrow();i++) {
	    weight.row(i)(flag.row(i)) = 0.0;
	}
    }

    Bool ok = True;
    if (firstPass) {
	for (uInt i=0;i<accumy_p.nrow();i++) {
	    accumy_p.row(i)= (data->row(i))*weight.row(i);
	    flag_p.row(i)  = lflag.row(i);
	}
	weight_p = weight;
	scalarWeight_p = thisScalarWeight_p;
	weightedtsys_p = tsys * tsys * thisScalarWeight_p;
	for (uInt i=0;i<weightedtsys_p.nelements();i++) {
	  if (thisScalarWeight_p[i] == 0.0) weightedtsys_p[i] = 0.0;
        }
	crpix_p = crpix;
	crpixOrig_p = crpix;
	crval_p = crval;
	crvalOrig_p = crval;
	cdelt_p = cdelt;
	frest_p = restfrequency;
	exposure_p = exposure;
	duration_p = duration;
	refframe_p = refframe;
	cunit_p = cunit;
	veldef_p = veldef;
    } else {
	// determine relative shift, default is no shift
	Double rshift = 0.0;
	switch (alignType_p) {
	case VELOCITY:
	    // sanity checks were done above
	    // do any rest frequency shifting first
	    if (rfshift_p && restfrequency != frest_p) {
	    		// shift the rest frequency to align
		if (axisType_p == VELO) {
		    // shift back to frequency
		    // if no unit supplied, default to m/s
		    String loccunit = cunit;
		    if (loccunit == "") loccunit = "m/s";
		    if (!vmach_p) {
			// initialize the velocity machine which does these
			// conversions
			MFrequency::Ref fr(freqFrame_p);
			MDoppler::Ref vr(velocityDef_p);
			Unit fu("Hz");
			if (cunit_p == "") cunit_p = "m/s";
			Unit vu(cunit_p);
			MVFrequency rfrq(Quantity(frest_p, "Hz"));
			vmach_p = new VelocityMachine(fr, fu, rfrq, vr, vu);
			AlwaysAssert(vmach_p, AipsError);
		    }
		    // get the frequencies from the velocities, first setting
		    // the rest frequency to what it is for this data
		    vmach_p->set(MVFrequency(Quantity(restfrequency, "Hz")));
		    Quantity frval = (*vmach_p)(MVDoppler(Quantity(crval, loccunit)));
		    // deltas don't convert, need to get nearby ones
		    Quantity frvalPlus = (*vmach_p)(MVDoppler(Quantity(crval+cdelt, loccunit)));
		    Quantity frvalMinus = (*vmach_p)(MVDoppler(Quantity(crval-cdelt, loccunit)));
		    // and now back to velocity with the rest frequency
		    // currently in the average
		    vmach_p->set(MVFrequency(Quantity(frest_p, "Hz")));
		    crval = (*vmach_p)(frval).getValue();
		    Double crvalPlus = (*vmach_p)(frvalPlus).getValue();
		    Double crvalMinus = (*vmach_p)(frvalMinus).getValue();
		    cdelt = (crvalPlus - crvalMinus) / 2.0;
		    // need to check that cdelt isn't too much different
		    // from cdelt_p - over the width of this axis, the
		    // difference must be < 1/10 of a pixel
		    if (data->ncolumn()*abs(cdelt/cdelt_p-1) >= 0.1) {
			LogIO os;
			os << LogIO::SEVERE
			   << LogOrigin("sdaverager","accumulate")
			   << "The required rest frequency shift would produce a velocity axis"
			   << " with a significantly different channel spacing"
			   << LogIO::POST;
			ok = False;
		    }
		    cdelt = cdelt_p;
		}
		restfrequency = frest_p;
	    }
	    if (ok) {
		// now actually do the velocity alignment
		if (axisType_p != FREQ) {
		    // location of crval_p in terms of input axis
		    Double pix = (crval_p-crval)/cdelt_p + crpix;
		    // relative shift 
		    rshift = crpix_p - pix;
		} else {
		    // convert frequencies to velocities and then align
		    // default to Hz if no units supplied
		    String loccunit = cunit;
		    if (loccunit == "") loccunit = "Hz";
		    if (!vmach_p) {
			// initialize the velocity machine which does these
			// conversions
			MFrequency::Ref fr(freqFrame_p);
			MDoppler::Ref vr(velocityDef_p);
			Unit fu("Hz");
			Unit vu("m/s");
			MVFrequency rfrq(Quantity(frest_p, "Hz"));
			vmach_p = new VelocityMachine(fr, fu, rfrq, vr, vu);
			AlwaysAssert(vmach_p, AipsError);
			// this also must mean that vrval_p and crval_p have
			// not yet been set
			vrval_p = (*vmach_p)(MVFrequency(Quantity(crval_p, cunit_p))).getValue();
			Double vrvalP_p = (*vmach_p)(MVFrequency(Quantity(crval_p+cdelt_p, cunit_p))).getValue();
			Double vrvalM_p = (*vmach_p)(MVFrequency(Quantity(crval_p-cdelt_p, cunit_p))).getValue();
			vdelt_p = (vrvalP_p-vrvalM_p)/2.0;
		    }
		    vmach_p->set(MVFrequency(Quantity(restfrequency, "Hz")));
		    Double pix = (vrval_p - (*vmach_p)(MVFrequency(Quantity(crval, loccunit))).getValue()) 
			/ vdelt_p + crpix;
		    rshift = crpix_p - pix;
		}
	    }
	    break;
	case XAXIS:
	    {
		// location of crval_p in terms of input axis
		Double pix = (crval_p-crval)/cdelt_p + crpix;
		// relative shift 
		rshift = crpix_p - pix;
	    }
	    break;
	default:
	    // nothing to do here
	    break;
	}

	if (ok) {
	    // to nearest pixel
	    Int shift = Int(abs(rshift) + 0.5);
	    if (rshift < 0) shift = -shift;
	    rshift -= shift;
	    // first do the fractional shift, if necessary
	    // the cutoff of 0.01 of channel is fairly arbirary.
	    dtmpInUse_p = False;
	    if (abs(rshift) > 0.01) {
		if (!fftserver_p) {
		    fftserver_p = new FFTServer<Float, Complex>();
		    AlwaysAssert(fftserver_p, AipsError);
		}
		ffttmp_p.resize(0);
		if (dtmp_p.shape() != data->shape()) {
		    dtmp_p.resize(data->shape());
		}
		// a copy is necessary here because data is a const argument
		dtmp_p = *data;
		dtmpInUse_p = True;
		// this is lifted from fftserver::shift for the specific
		// case of shifting a single vector, I don't know if
		// all nrows could be done in one go.
		for (uInt i=0;i<dtmp_p.nrow();i++) {
		    fftserver_p->fft0(ffttmp_p, dtmp_p.row(i));
		    Float products = rshift/dtmp_p.ncolumn();
		    Float partialSum;
		    for (uInt j=0;j<ffttmp_p.nelements();j++) {
			partialSum = 1.0f + products*j;
			ffttmp_p(j) *= exp(twoPiI_p * partialSum);
		    }
		    // reference object to make the compiler happy
		    Vector<Float> dtmpRow(dtmp_p.row(i));
		    fftserver_p->fft0(dtmpRow, ffttmp_p);
		}
	    }
	    // then the whole pixel shift
	    Int acSliceStart, inSliceStart;
	    if (shift > 0) {
		acSliceStart = 0;
		inSliceStart = shift;
		// reference pixel does not move in this case
	    } else {
		acSliceStart = -shift;
		inSliceStart = 0;
		// reference pixel moves in this case
		crpix_p -= shift;
	    }
	    uInt newLength = max(acSliceStart + accumy_p.ncolumn(),
				 inSliceStart + data->ncolumn());
	    if (acSliceStart != 0 || newLength != accumy_p.ncolumn()) {
		Matrix<Float> tmpac = accumy_p;
		Matrix<Float> tmpw = weight_p;
		LogicalMatrix  tmpf = flag_p;
		accumy_p.resize(tmpac.nrow(),newLength);
		weight_p.resize(tmpw.nrow(),newLength);
		flag_p.resize(flag.nrow(),newLength);
		accumy_p = 0;
		weight_p = 0;
		flag_p = False;
		accumy_p(Slice(),Slice(acSliceStart, tmpac.ncolumn())) = tmpac;
		weight_p(Slice(),Slice(acSliceStart, tmpw.ncolumn())) = tmpw;
		flag_p(Slice(),Slice(acSliceStart, tmpf.ncolumn())) = tmpf;
	    }
	    uInt ncol, nrow;
	    ncol = nrow = 0;
	    if (dtmpInUse_p) {
		ncol = dtmp_p.ncolumn();
		nrow = dtmp_p.nrow();
	    } else {
		ncol = data->ncolumn();
		nrow = data->nrow();
	    }
	    Slice rowSlicer(inSliceStart, ncol);
	    Slice colSlicer(0,nrow);
	    // these are references
	    Matrix<Float> accumySlice(accumy_p(colSlicer, rowSlicer));
	    Matrix<Float> weightSlice(weight_p(colSlicer, rowSlicer));
	    LogicalMatrix flagSlice(flag_p(colSlicer, rowSlicer));
	
	    if (dtmpInUse_p) {
		for (uInt i=0;i<accumy_p.nrow();i++) {
		    accumySlice.row(i) = accumySlice.row(i) + dtmp_p.row(i)*weight.row(i);
		    weightSlice.row(i) = weightSlice.row(i) + weight.row(i);
		}
		dtmpInUse_p = False;
	    } else {
		for (uInt i=0;i<accumy_p.nrow();i++) {
		    accumySlice.row(i) = accumySlice.row(i) + (data->row(i))*weight.row(i);
		    weightSlice.row(i) = weightSlice.row(i) + weight.row(i);
		}
	    }

	    flagSlice = flagSlice && lflag;

	    Vector<Float> thisWeightedTsys = thisScalarWeight_p * tsys * tsys;
	    for (uInt i=0;i<thisWeightedTsys.nelements();i++) {
	      if (thisScalarWeight_p[i] == 0.0) thisWeightedTsys[i] = 0.0;
	    }
	    weightedtsys_p += thisWeightedTsys;
	    scalarWeight_p += thisScalarWeight_p;
	    // header variables
	    exposure_p += exposure;
	    duration_p += duration;
	}
    }
    delete data;
    data = 0;
    return ok;
}

Bool sdaverager::accumulateIterator(const ObjectID& iterid)
{
    ObjectController *controller = ApplicationEnvironment::objectController();
    if (controller == 0) {
	// this should never happen.
	LogIO os;
	os << LogIO::EXCEPTION
	   << LogOrigin("sdaverager","accumulateIterator")
	   << "No controller"
	   << LogIO::POST;
	return False;
    }
    ApplicationObject *obj = controller->getObject(iterid);
    if (obj == 0) {
	// this should seldom happen, when used appropriately
	LogIO os;
	os << LogIO::SEVERE
	   << LogOrigin("sdaverager","accumulateIterator")
	   << "Invalid object ID - "
	   << LogIO::POST;
	return False;
    }
    if (obj->className() != "sditerator") {
	// this should also seldom happend, when used appropriately
	LogIO os;
	os << LogIO::SEVERE
	   << LogOrigin("sdaverager","accumulateIterator")
	   << "The given object ID is not an sditerator "
	   << " but instead appears to be a " << obj->className()
	   << LogIO::POST;
	return False;
    }
    // cast obj to the appropriate type
    sditerator * iter = static_cast<sditerator *>(obj);

    // remember where we are
    Index currLoc(iter->location());
    iter->origin();
    Bool ok = (iter->length() != 0);
    Bool allUsed = True;
    while (ok) {
	allUsed = allUsed && accumulate(iter->getsdrecord());
	if (iter->more()) {
	    iter->next();
	}
	else ok = False;
    }

    // return iterator to previous location
    iter->setlocation(currLoc);
    return allUsed;
}

Vector<String> sdaverager::methods() const
{
    Vector<String> method(NUMBER_METHODS);
    method(CLEAR) = "clear";
    method(SETWEIGHTING) = "setweighting";
    method(GETWEIGHTING) = "getweighting";
    method(SETALIGNMENT) = "setalignment";
    method(GETALIGNMENT) = "getalignment";
    method(DORESTSHIFT) = "dorestshift";
    method(RESTSHIFTSTATE) = "restshiftstate";
    method(ACCUMULATE) = "accumulate";
    method(ACCUMITERATOR) = "accumiterator";
    method(AVERAGE) = "average";
    return method;
}

Vector<String> sdaverager::noTraceMethods() const
{
    return methods();
}

MethodResult sdaverager::runMethod(uInt which,
				   ParameterSet &inputRecord,
				   Bool runMethod)
{
    static String returnvalString = "returnval";

    switch (which) {
    case CLEAR:
	{
	    Parameter<Bool> returnval(inputRecord, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = clear();
	}
	break;
    case SETWEIGHTING:
	{
	    Parameter<Bool> returnval(inputRecord, returnvalString,
				      ParameterSet::Out);
	    static String optionString = "option";
	    Parameter<String> option(inputRecord, optionString,
				     ParameterSet::In);
	    if (runMethod) returnval() = setweighting(option());
	}
	break;
    case GETWEIGHTING:
	{
	    Parameter<String> returnval(inputRecord, returnvalString,
					ParameterSet::Out);
	    if (runMethod) returnval() = getweighting();
	}
	break;
    case SETALIGNMENT:
	{
	    Parameter<Bool> returnval(inputRecord, returnvalString,
				      ParameterSet::Out);
	    static String optionString = "option";
	    Parameter<String> option(inputRecord, optionString,
				     ParameterSet::In);
	    if (runMethod) returnval() = setalignment(option());
	}
	break;
    case GETALIGNMENT:
	{
	    Parameter<String> returnval(inputRecord, returnvalString,
					ParameterSet::Out);
	    if (runMethod) returnval() = getalignment();
	}
	break;
    case DORESTSHIFT:
	{
	    Parameter<Bool> returnval(inputRecord, returnvalString,
				      ParameterSet::Out);
	    static String torfString = "torf";
	    Parameter<Bool> torf(inputRecord, torfString,
				 ParameterSet::In);
	    if (runMethod) returnval() = dorestshift(torf());
	}
	break;
    case RESTSHIFTSTATE:
	{
	    Parameter<Bool> returnval(inputRecord, returnvalString,
					ParameterSet::Out);
	    if (runMethod) returnval() = restshiftstate();
	}
	break;
    case ACCUMULATE:
	{
	    Parameter<Bool> returnval(inputRecord, returnvalString,
				      ParameterSet::Out);
	    static String sdrecordString = "sdrecord";
	    Parameter<GlishRecord> glishRec(inputRecord, sdrecordString,
					    ParameterSet::In);
	    if (runMethod) {
		// first convert to a Record
		Record theRec;
		glishRec().toRecord(theRec);
		// then to an SDRecord
		SDRecord sdrecord(theRec);
		returnval() = accumulate(sdrecord);
	    }
	}
	break;
    case ACCUMITERATOR:
	{
	    Parameter<Bool> returnval(inputRecord, returnvalString,
				      ParameterSet::Out);
	    static String iteridString = "sditerator";
	    Parameter<ObjectID> iterid(inputRecord, iteridString,
				       ParameterSet::In);
	    if (runMethod) returnval() = accumulateIterator(iterid());
	}
	break;
    case AVERAGE:
	{
	    Parameter<Bool> returnval(inputRecord, returnvalString,
				      ParameterSet::Out);
	    static String sdrecordString = "sdrecord";
	    Parameter<GlishRecord> glishRec(inputRecord, sdrecordString,
					    ParameterSet::InOut);
	    if (runMethod) {
		// First convert to a Record
		Record theRec;
		glishRec().toRecord(theRec);
		// then to an SDRecord
		SDRecord sdrecord(theRec);
		returnval() = average(sdrecord);
		// convert it back to an a GlishRecord
		glishRec().fromRecord(sdrecord);
	    }
	}
	break;
    default:
	return error("No such method");
    }
    return ok();
}
