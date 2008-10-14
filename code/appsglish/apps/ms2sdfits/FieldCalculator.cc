//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,1999,2000,2001,2002
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
//# $Id: FieldCalculator.cc,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#include <FieldCalculator.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Vector.h>
#include <coordinates/Coordinates.h>
#include <fits/FITS/fits.h>
#include <fits/FITS/FITSDateUtil.h>
#include <casa/Logging/LogIO.h>
#include <casa/BasicSL/Constants.h>
#include <casa/BasicMath/Math.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MeasurementSets/MSColumns.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MDoppler.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MFrequency.h>
#include <measures/Measures/VelocityMachine.h>
#include <casa/OS/Time.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Quanta/Unit.h>
#include <tables/Tables/TableDesc.h>
#include <casa/Utilities/Assert.h>

#include <casa/namespace.h>
FieldCalculator::FieldCalculator(MSReader &reader)
    : itsReader_p(&reader), itsCols_p(0),
      itsCrval(4), itsCrpix(4), itsCdelt(4), itsCtype(4), itsCunit(4),
      itsMainRow(-1), itsSyscalRow(-1), itsSourceRow(-1), itsSpwRow(-1),
      itsPointRow(-1), itsPolRow(-1), itsHasExtraTime(False), itsHasTsysCol(False),
      itsHasTsysFlagCol(False), itsHasTrxCol(False), itsHasTrxFlagCol(False),
      itsHasTcalCol(False), itsHasTcalFlagCol(False), itsHasRestfreqCol(False)
{
    init();
}

FieldCalculator::FieldCalculator(const FieldCalculator &other)
    : itsReader_p(other.itsReader_p), itsCols_p(0), 
      itsCrval(4), itsCrpix(4), itsCdelt(4), itsCtype(4), itsCunit(4),
      itsMainRow(-1), itsSyscalRow(-1), itsSourceRow(-1), itsSpwRow(-1),
      itsPointRow(-1), itsPolRow(-1), itsHasExtraTime(False), itsHasTsysCol(False),
      itsHasTsysFlagCol(False), itsHasTrxCol(False), itsHasTrxFlagCol(False),
      itsHasTcalCol(False), itsHasTcalFlagCol(False), itsHasRestfreqCol(False)
{
    init();
}

FieldCalculator &FieldCalculator::operator=(const FieldCalculator &other)
{
    if (&other != this) {
	cleanup();
	itsReader_p = other.itsReader_p;
	init();
    }
    return *this;
}

FieldCalculator::~FieldCalculator()
{ cleanup();}

void FieldCalculator::setInternals()
{
    // get the row numbers
    itsMainRow = itsReader_p->rowNumber("MAIN");
    itsSyscalRow = itsReader_p->rowNumber("SYSCAL");
    itsSourceRow = itsReader_p->rowNumber("SOURCE");
    itsSpwRow = itsReader_p->rowNumber("SPECTRAL_WINDOW");
    itsPointRow = itsReader_p->rowNumber("POINTING");
    itsPolRow = itsReader_p->rowNumber("POLARIZATION");

    // TIME
    
    MEpoch dateTime;
    if (itsMainRow >= 0) {
	dateTime = itsCols_p->timeMeas()(itsMainRow);
	// currently we throw away the timesys, but that needs to stop in case
	// a non UTC time is encountered here
	String timesys;
	FITSDateUtil::toFITS(itsDMY, timesys, MVTime(dateTime.getValue()), MEpoch::Types(dateTime.getRef().getType()),
			     FITSDateUtil::NEW_DATEONLY, 0);
	
	// seconds since 0h on dateTime - assumes this is in UT
	itsTime = dateTime.getValue().getDayFraction()*MVEpoch::secInDay;
	// add on any extra time as necessary
	if (itsHasExtraTime) {
	    // assumes that this is already in seconds
	    itsTime += itsCols_p->timeExtraPrec()(itsMainRow);
	}
    } else {
	FitsFPUtil::setNaN(itsTime);
	itsDMY = "01-01-1900";
    }

    // average temps
    if (itsSyscalRow >= 0 &&
	(itsHasTsysCol && (!itsHasTsysFlagCol || itsCols_p->sysCal().tsysFlag()(itsSyscalRow) == False))) {
	itsAvgTsys = mean(itsCols_p->sysCal().tsys()(itsSyscalRow));
    } else {
	FitsFPUtil::setNaN(itsAvgTsys);
    }

    if (itsSyscalRow >= 0 &&
	(itsHasTcalCol && (!itsHasTcalFlagCol || itsCols_p->sysCal().tcalFlag()(itsSyscalRow) == False))) {
	itsAvgTcal = mean(itsCols_p->sysCal().tcal()(itsSyscalRow));
    } else {
	FitsFPUtil::setNaN(itsAvgTcal);
    }

    if (itsSyscalRow >= 0 &&
	(itsHasTrxCol && (!itsHasTrxFlagCol || itsCols_p->sysCal().trxFlag()(itsSyscalRow) == False))) {
	itsAvgTrx = mean(itsCols_p->sysCal().trx()(itsSyscalRow));
    } else {
	FitsFPUtil::setNaN(itsAvgTrx);
    }

    // rest frequency comes from the SOURCE table - use the first one when NUM_LINES>1
    if (itsSourceRow >= 0 && itsHasRestfreqCol) {
	Vector<Double> restFreqs(itsCols_p->source().restFrequency()(itsSourceRow));
	if (restFreqs.nelements() > 0) {
	    itsRestfreq = restFreqs(0);
	} else {
	    FitsFPUtil::setNaN(itsRestfreq);
	}
    } else {
	FitsFPUtil::setNaN(itsRestfreq);
    }

    //  FREQ axis uses the SPECTRAL_WINDOW table
    if (itsSpwRow >= 0) {
	// get the mean spectral resolution
	itsFreqres = mean(itsCols_p->spectralWindow().resolution()(itsSpwRow));

	// axis descriptors
	Vector<Double> chanFreq = itsCols_p->spectralWindow().chanFreq()(itsSpwRow);
	if (chanFreq.nelements() > 0) {
	    MFrequency freqMeas = itsCols_p->spectralWindow().chanFreqMeas()(itsSpwRow)(IPosition(1,0));
	    String freqRef = freqMeas.getRefString();
	    // translate that into something appropriate for FITS
	    if (freqRef == "REST") freqRef = "-SOU";
	    else if (freqRef == "LSRD") freqRef = "-LSR";
	    else if (freqRef == "LSRK") freqRef = "-LSD";
	    else if (freqRef == "BARY") freqRef = "-HEL";
	    else if (freqRef == "GEO") freqRef = "-GEO";
	    else if (freqRef == "TOPO") freqRef = "-OBS";
	    else if (freqRef == "GALACTO") freqRef = "-GAL";
	    else freqRef = "";

	    itsCtype(0) = "FREQ" + freqRef;
	    itsVeldef = "RADI" + freqRef;
	    itsCrpix(0) = 1.0;
	    itsCrval(0) = chanFreq(0);
	    if (chanFreq.nelements() > 1) {
		// is cdelt constant (chanFreq linear)
		itsCdelt(0) = chanFreq(1)-chanFreq(0);
		Bool isLinear = True;
		// the default tolerance for doubles is 1e-13, which doesn't work
		// if the channel spacing is a very small fraction of the
		// rest frequency.
		Double tol = 1e-13;
		if (!isNaN(itsRestfreq) && itsRestfreq > 0.0) {
		    tol *= abs(itsRestfreq/itsCdelt(0));
		}
		for (uInt i=2;i<chanFreq.nelements();i++) {
		    if (!near(itsCdelt(0), (chanFreq(i)-chanFreq(i-1)),tol)) {
			isLinear = False;
			break;
		    }
		}
		if (!isLinear) {
		    // perhaps this frequency corresponds to something which is linear 
		    // in velocity - i.e. an OPTICAL velocity definition
		    // do we have a non-zero, non-NaN rest frequency?
		    if (!isNaN(itsRestfreq) && itsRestfreq > 0.0) {
			MFrequency::Ref fr(freqMeas.getRef());
			MDoppler::Ref vr(MDoppler::OPTICAL);
			Unit fu = "Hz";
			Unit vu = "m/s";
			MVFrequency rfrq(Quantity(itsRestfreq, "Hz"));
			VelocityMachine vmach(fr, fu, rfrq, vr, vu);
			Vector<Double> vels(vmach.makeVelocity(chanFreq).getValue());
			// is this linear
			isLinear = True;
			Double tmpCdelt = vels(1) - vels(0);
			for (uInt i=2;i<vels.nelements();i++) {
			    if (!near(tmpCdelt, (vels(i)-vels(i-1)),tol)) {
				isLinear = False;
				break;
			    }
			}
			if (isLinear) {
			    itsCtype(0) = "VELO" + freqRef;
			    itsVeldef = "OPTI" + freqRef;
			    itsCdelt(0) = tmpCdelt;
			    itsCrpix(0) = 1.0;
			    itsCrval(0) = vels(0);
			}
		    }
		}
		if (!isLinear) {
		    // this means we couldn't linearize it.  Use the center channel values
		    // and issue a warning
		    itsCrpix(0) = (chanFreq.nelements()%2) ? 
			Int(Double(chanFreq.nelements())/2.0+0.5) : Int(Double(chanFreq.nelements())/2.0);
		    Int upper = Int(itsCrpix(0) + 0.5);
		    Int lower = upper-1;
		    if (lower < 0) {
			lower = 0;
			upper = 1;
		    } else if (upper >= Int(chanFreq.nelements())) {
			upper = chanFreq.nelements()-1;
			lower = upper - 1;
		    }
		    itsCdelt(0) = chanFreq(upper) - chanFreq(lower);
		    itsCrval(0) = chanFreq(upper) - (upper-itsCrpix(0))*itsCdelt(0);
		    LogIO os;
		    os << LogIO::WARN
		       << LogOrigin("FieldCalculator","setInternals()", WHERE)
		       << "Unable to linearize the frequency-like axis for MS row " << (itsMainRow+1)
		       << ". Using values near channel " << itsCrpix(0)
		       << LogIO::POST;;
		}
	    } else {
		itsCdelt(0) = 1.0;
	    }
	} else {
	    itsCrval(0) = 1.0;
	    itsCdelt(0) = 1.0;
	    itsCrpix(0) = 1.0;
	    itsCtype(0) = "FREQ";
	}
    }

    // STOKES axis uses the POLARIZATION table
    if (itsPolRow >= 0) {
	Vector<Int> corrTypeVec(itsCols_p->polarization().corrType()(itsPolRow));
	if (corrTypeVec.nelements() > 0) {
	    itsCrval(1) = Stokes::FITSValue(Stokes::StokesTypes(corrTypeVec(0)));
	    if (corrTypeVec.nelements() > 1) {
		itsCdelt(1) = Stokes::FITSValue(Stokes::StokesTypes(corrTypeVec(1))) - itsCrval(1);
	    } else {
		itsCdelt(1) = 1.0;
	    }
	} else {
	    itsCrval(1) = Stokes::FITSValue(Stokes::I);
	    itsCdelt(1) = 1.0;
	}
    }

    // POSITION axis uses the POINTING table
    if (itsPointRow >= 0) {
	// ignore the polynomial for now - this needs to be handled correctly
	MDirection dir(itsCols_p->pointing().directionMeas(itsPointRow));

	// default values
	Bool xIsRaLike = True;
	itsCtype(2) = "RA";
	itsCtype(3) = "DEC";
	itsRadecsys = "FK5";
	itsEquinox = MVTime(dateTime.getValue()).get("yr").getValue();
	// set those that don't use the default values;
	switch (dir.getRef().getType()) {
	case MDirection::J2000:
	    itsEquinox = 2000.0;
	    break;
	case MDirection::B1950:
	    itsEquinox = 1950.0;
	    itsRadecsys = "FK4";
	    break;
	case MDirection::APP:
	    itsRadecsys = "GAPPT";
	    break;
	case MDirection::GALACTIC:
	    itsCtype(2) = "GLON";
	    itsCtype(3) = "GLAT";
	    xIsRaLike = False;
	    itsRadecsys = "";
	case MDirection::HADEC:
	    itsCtype(2) = "HA";
	    itsRadecsys = "";
	    xIsRaLike = False;
	case MDirection::AZEL:
	    itsCtype(2) = "AZ";
	    itsCtype(3) = "EL";
	    itsRadecsys = "";
	    xIsRaLike = False;
	default:
	    {
		// a reference code we don't know how to handle
		LogIO os;
		os << LogIO::WARN
		   << LogOrigin("FieldCalculator","setInternals()", WHERE)
		   << "Unable to translate " << dir.getRefString()
		   << " to something appropriate for SDFITS, defaulting to J2000 RA and DEC" 
		   << LogIO::POST;;
	    }
	    break;
	}

	// get the value of dir (in radians) and convert to degrees
	Vector<Double> degDir = dir.getValue().get() / C::degree;
	itsCrval(2) = degDir(0);
	itsCrval(3) = degDir(1);

	if (xIsRaLike) itsCdelt(2) = -1;
	else itsCdelt(2) = 1;
    } else {
	// default pointing values
	itsCtype(2) = "RA";
	itsCtype(3) = "DEC";
	itsRadecsys = "FK5";
	itsEquinox = MVTime(dateTime.getValue()).get("yr").getValue();
	itsCrval(2) = 0.0;
	itsCrval(3) = 0.0;
	itsCdelt(2) = -1.0;
    }
}

Float FieldCalculator::averageTemp(FieldCalculator::TempType which)
{
    Float result;
    set();
    switch (which) {
    case TCAL: result = itsAvgTcal; break;
    case TRX: result = itsAvgTrx; break;
    case TSYS: result = itsAvgTsys; break;
    default:
	// this should never happen
	throw(AipsError("Unexpected error in FieldCalculator::averageTemp - please report this."));
	break;
    }
    return result;
}

void FieldCalculator::init()
{
    // this only works so long as reader isn't deleted.  In the long run it would
    // be better if MSReader had some way of cloning access to the same shared
    // reader.

    itsCols_p = new ROMSColumns(itsReader_p->ms());
    AlwaysAssert(itsCols_p, AipsError);

    // see if various columns exist
    itsHasExtraTime = !itsCols_p->timeExtraPrec().isNull();
    itsHasTsysCol = !itsCols_p->sysCal().tsys().isNull();
    itsHasTrxCol = !itsCols_p->sysCal().trx().isNull();
    itsHasTcalCol = !itsCols_p->sysCal().tcal().isNull();
    itsHasTsysFlagCol = !itsCols_p->sysCal().tsysFlag().isNull();
    itsHasTrxFlagCol = !itsCols_p->sysCal().trxFlag().isNull();
    itsHasTcalFlagCol = !itsCols_p->sysCal().tcalFlag().isNull();
    itsHasRestfreqCol = !itsCols_p->source().restFrequency().isNull();

    // most axes have crpix = 1.0
    itsCrpix = 1.0;

    // axes units are fixed
    itsCunit(0) = "Hz";
    itsCunit(1) = "";
    itsCunit(2) = "deg";
    itsCunit(3) = "deg";

    // the type of the STOKES axis is fixed
    itsCtype(1) = "STOKES";

    // 2nd position axis always increases
    itsCdelt(3) = 1;
}

void FieldCalculator::cleanup()
{
    // itsReader_p was not created here, don't delete it
    itsReader_p = 0;

    delete itsCols_p; 
    itsCols_p = 0;

    itsCrval = itsCrpix = itsCdelt = 0.0;
    itsCtype = itsCunit = "";

    itsMainRow = itsSyscalRow = itsSourceRow = itsSpwRow = itsPointRow = itsPolRow = -1;

    itsHasExtraTime = itsHasTsysCol = itsHasTsysFlagCol = itsHasTrxCol = itsHasTrxFlagCol = 
	itsHasTcalCol = itsHasTcalFlagCol = itsHasRestfreqCol = False;

    itsDMY = "";
    itsRadecsys = "";
    itsTime = itsFreqres = itsRestfreq =itsEquinox = 0.0;
    itsAvgTsys = itsAvgTcal = itsAvgTrx = 0.0;
}
