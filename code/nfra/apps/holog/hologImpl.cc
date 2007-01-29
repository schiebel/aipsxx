//# hologImpl.cc: Functionality for the holog Distributed Object
//# Copyright (C) 1998,1999,2000,2001,2002
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
//# $Id: hologImpl.cc,v 19.3 2004/11/30 17:50:39 ddebonis Exp $


#include <hologImpl.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/MethodResult.h>
#include <ms/MeasurementSets/MSColumns.h>
#include <ms/MeasurementSets/MSFieldColumns.h>
#include <ms/MeasurementSets/MSFeedColumns.h>
#include <ms/MeasurementSets/MSSysCalColumns.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/ScaColDesc.h>
#include <tables/Tables/ArrColDesc.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/TableRecord.h>
#include <tables/Tables/ArrayColumn.h>
#include <tables/Tables/ExprNode.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/Slice.h>
#include <casa/Arrays/Slicer.h>
#include <scimath/Mathematics/FFTServer.h>
#include <casa/BasicSL/Constants.h>
#include <scimath/Fitting/LinearFitSVD.h>
#include <scimath/Functionals/CombiFunction.h>
#include <scimath/Functionals/FunctionWrapper.h>
#include <casa/Quanta/Unit.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Quanta/MVTime.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Utilities/GenSort.h>
#include <casa/Utilities/Assert.h>
#include <casa/Exceptions/Error.h>
#include <casa/iostream.h>
#include <casa/stdio.h>

#include <casa/namespace.h>
holog::holog (const String& msName, Int spwid, Int channel,
	      const Vector<Int>& polnrs)
: itsMSColumns (0),
  itsState     (Constructed)
{
    // First select the bands needed.
    Table tab(msName);
    if (spwid < 0) {
        spwid = 0;
    }
    itsSpwid = spwid;
    //// NEW:    Table seltab = tab(tab.col("DATA_DESC_ID") == spwid);
    Table seltab = tab(tab.col("SPECTRAL_WINDOW_ID") == spwid);
    // Use original table if selection is the same.
    if (seltab.nrow() == tab.nrow()) {
      seltab = tab;
    }
    itsMS = MeasurementSet(seltab);
  
    itsMSColumns = new ROMSColumns (itsMS);
//    LogIO os(LogOrigin("holog",
//                       "holog(const String& msName "
//  		                 , id(), WHERE));
    // Get data shape from the first row.
    IPosition shape = itsMSColumns->data().shape(0);
    // Check if channel is valid. Default channel is first one.
    if (channel < 0) {
	itsChannel = 0;
    } else {
	AlwaysAssert (channel<shape(1), AipsError);
	itsChannel = channel;
    }
    // Default polarization is first and last one (XX and YY).
    // The default is used when no or a negative polarization is given.
    if (polnrs.nelements() == 0  ||  polnrs(0) < 0) {
	if (shape(0) == 1) {
	    itsPolnrs.resize (1);
	    itsPolnrs(0) = 0;
	} else {
	    itsPolnrs.resize (2);
	    itsPolnrs(0) = 0;
	    itsPolnrs(1) = shape(0)-1;
	}
    } else {
	// Check if polarizations are valid and unique (i.e. ascending).
	for (uInt i=0; i<polnrs.nelements(); i++) {
	    AlwaysAssert (polnrs(i)>=0  &&  polnrs(i)<shape(0), AipsError);
	    if (i > 0) {
		// Assure a polnr is not given twice.
		AlwaysAssert (polnrs(i) > polnrs(i-1), AipsError);
	    }
	}
	itsPolnrs.resize (polnrs.nelements());
	itsPolnrs = polnrs;
    }
    // Determine if an X polarization is given.
    // Then we know if a single polarization is X or Y.
    // Get polarization types from the first row.
    ROMSFeedColumns feedc(itsMS.feed());
    Vector<String> polType = feedc.polarizationType()(0);
    itsPolX = (polType(0) == "X");
}

holog::~holog()
{
    delete itsMSColumns;
}


void holog::init (Bool applyTRX)
{
    // Get field id of center and its RA, DEC, and name.
    // The last row in the FIELD table contains that field.
    ROMSFieldColumns fieldc (itsMS.field());
    Int fieldid = itsMS.field().nrow() - 1;
    String ref = fieldc.delayDir().keywordSet().asString("MEASURE_REFERENCE");
    Unit fieldUnit = fieldc.delayDir().keywordSet().asString("UNIT");
    Double fieldFactor = (fieldUnit.getValue()/Unit("rad").getValue()).getFac();
    Vector<Double> fieldPos (fieldc.delayDir()(fieldid));
    fieldPos *= fieldFactor;
    itsRA = fieldPos(0);
    itsDEC = fieldPos(1);
    itsFieldName = fieldc.name()(0);

    // Find channel frequency.
    ROMSSpWindowColumns spwidc (itsMS.spectralWindow());
    Vector<Double> freqs = spwidc.chanFreq()(itsSpwid);
    itsFreq = freqs(itsChannel);

    // The nr of antennas is the highest possible antenna.
    Vector<Int> ant1;
    Vector<Int> ant2;
    itsMSColumns->antenna1().getColumn (ant1);
    itsMSColumns->antenna2().getColumn (ant2);
    uInt nrant = 1 + max (max(ant1), max(ant2));
    itsAntIndex.resize (nrant, nrant);
    itsAntIndex = -1;
    itsAntStepping.resize (nrant);
    itsAntStepping = False;

    // Read all times from the MS (resize vector if needed).
    itsMSColumns->time().getColumn (itsTimes, True);

    // Sort on antennas and time.
    Bool deleteIt;
    Sort sort;
    const Int* ant1Data = ant1.getStorage(deleteIt);
    AlwaysAssert (!deleteIt, AipsError);
    sort.sortKey (ant1Data, TpInt);
    const Int* ant2Data = ant2.getStorage(deleteIt);
    AlwaysAssert (!deleteIt, AipsError);
    sort.sortKey (ant2Data, TpInt);
    sort.sortKey (itsTimes.getStorage(deleteIt), TpDouble);
    AlwaysAssert (!deleteIt, AipsError);
    uInt nrval = ant1.nelements();
    sort.sort (itsRowIndex, nrval);

    // Sort the times uniquely to get all different times.
    uInt nrtim = GenSort<Double>::sort (itsTimes, Sort::Ascending,
					Sort::HeapSort | Sort::NoDuplicates);
    itsTimes.resize (nrtim, True);

    // Convert the first time to a string to get the date.
    // Take the unit (default is s) into account.
    String timeUnit;
    timeUnit = "s";
    if (itsMSColumns->time().keywordSet().isDefined("UNIT")) {
	timeUnit = itsMSColumns->time().keywordSet().asString("UNIT");
    }
    MVTime date = Quantity(itsTimes(0), timeUnit);
    itsDate = date.string (MVTime::DMY);
    itsDate = itsDate.before(11);

    // Determine where each antenna pair starts.
    // Ensure that each antenna pair has equal number of times.
    const uInt* inx = itsRowIndex.getStorage (deleteIt);
    AlwaysAssert (!deleteIt, AipsError);
    Int lastAnt1 = ant1Data[inx[0]] - 1;
    Int lastAnt2 = 0;
    uInt nrt = 0;
    for (uInt i=0; i<nrval; i++) {
	if (lastAnt1 != ant1Data[inx[i]]  ||  lastAnt2 != ant2Data[inx[i]]) {
	    if (nrt != 0  &&  nrt != nrtim) {
		throw (AipsError ("Unequal number of times in baselines"));
	    }
	    lastAnt1 = ant1Data[inx[i]];
	    lastAnt2 = ant2Data[inx[i]];
	    itsAntIndex(lastAnt1, lastAnt2) = i;
	    nrt = 0;
	}
	nrt++;
    }
    if (nrt != nrtim) {
	throw (AipsError ("Unequal number of times in baselines"));
    }

    // Fill the TRX table if needed.
    itsTrx.resize (0,0);
    if (applyTRX) {
        fillTRX();
    }

    // Set state to initialized.
    itsState = Initialized;
}

void holog::fillTRX()
{
    // Exit immediately if there is no SYSCAL table.
    if (! itsMS.keywordSet().isDefined ("SYSCAL")) {
        return;
    }
    Table tab(itsMS.sysCal());
    Table seltab = tab((tab.col("SPECTRAL_WINDOW_ID") == itsSpwid));
    if (seltab.nrow() == tab.nrow()) {
        seltab = tab;
    }
    // Also exit if spwid not found in SYSCAL table.
    if (seltab.nrow() == 0) {
        return;
    }
    ROMSSysCalColumns syscal ((MSSysCal(seltab)));
    Vector<Double> times = syscal.time().getColumn();
    Vector<Int> ants = syscal.antennaId().getColumn();
    Array<Float> trx = syscal.tsys().getColumn();
    // Sort the id's in order of time.
    Bool deleteIt;
    const Double* timesCal = times.getStorage (deleteIt);
    const Int* antsCal = ants.getStorage (deleteIt);
    const Float* trxCal = trx.getStorage (deleteIt);
    AlwaysAssert (sizeof(Complex) == 2*sizeof(Float), AipsError);
    AlwaysAssert (trx.shape()(0) == 2, AipsError);
    const Complex* trxCalC = (const Complex*)trxCal;
    Vector<uInt> index;
    uInt nrrow = GenSortIndirect<Double>::sort (index, times, Sort::Ascending,
						Sort::HeapSort);
    const uInt* indexCal = index.getStorage(deleteIt);
    // Find per antenna and scan the TRX from the SYSCAL subtable.
    // Do this by comparing the time from each scan with
    // the (sorted) time in the SYSCAL.
    const Double* timesData = itsTimes.getStorage (deleteIt);
    uInt nrtim = itsTimes.nelements();
    itsTrx.resize (max(ants)+1, nrtim);
    itsTrx = 1;
    uInt j=0;
    for (uInt i=0; i<nrtim; i++) {
	Bool fnd = False;
	while (!fnd && j<nrrow) {
	    uInt inx = indexCal[j];
	    if (timesData[i] > timesCal[inx]) {
		j++;
	    } else if (timesData[i] < timesCal[inx]) {
		break;
	    } else {
		fnd = True;
	    }
	}
	if (!fnd) {
	    cerr << "No SYSCAL entry found for spwid=" << itsSpwid
		 << ", time=" << timesData[i] << endl;
	} else {
	    while (fnd) {
		uInt inx = indexCal[j];
		Int tel = antsCal[inx];
		if (tel >= 0) {
		    itsTrx (tel, i) = float(10) * trxCalC[inx];
		}
		j++;
		fnd =  (j<nrrow  &&
			      timesCal[inx] == timesCal[indexCal[j]]);
	    }
	}
    }
}

void holog::findSteps (Double posTolerance, Double stepTolerance)
{
    uInt i,j;
    if (itsState < Initialized) {
	throw (AipsError ("init has to be done as the first step"));
    }

    // Get reference of field position.
    ROMSFieldColumns fieldc (itsMS.field());
    String ref = fieldc.delayDir().keywordSet().asString("MEASURE_REFERENCE");

    // Now get the pointing information from the POINTING subtable.
    Vector<Double> times;
    Vector<Int> ants;
    Matrix<Double> poss;
    Vector<Bool> onPos;
    String timeUnit;
    timeUnit = "s";
    AlwaysAssert (itsMS.keywordSet().isDefined ("POINTING"), AipsError);
    Table pointing = itsMS.keywordSet().asTable ("POINTING");
    ROScalarColumn<Double> timeCol (pointing, "TIME");
    ROScalarColumn<Int> antCol (pointing, "ANTENNA_ID");
    ROArrayColumn<Double> posCol (pointing, "POSITION");
    ROScalarColumn<Bool> onPosCol (pointing, "ON_POSITION");
    Unit pointUnit = posCol.keywordSet().asString("UNIT");
    Double pointFactor = (pointUnit.getValue()/Unit("rad").getValue()).getFac();
    if (posCol.keywordSet().asString("MEASURE_REFERENCE") != ref) {
	throw (AipsError ("MEASURE_REFERENCE of directions in FIELD"
			  " and POINTING subtable mismatch"));
    }
    times = timeCol.getColumn();
    ants = antCol.getColumn();
    poss = posCol.getColumn() * pointFactor;
    onPos = onPosCol.getColumn();
    if (timeCol.keywordSet().isDefined("UNIT")) {
	timeUnit = timeCol.keywordSet().asString("UNIT");
    }
    // Sort the times from this subtable in ascending order.
    Vector<uInt> rownrs;
    GenSortIndirect<Double>::sort (rownrs, times);

    // Find for each time if an antenna was stepping.
    // 0 = on position; 1 = off position; -1 = unspecified
    // If off position, find its position difference.
    uInt nrant = itsAntStepping.nelements();
    uInt nrtim = itsTimes.nelements();
    itsAntTimeOnOff.resize (nrtim, nrant);
    itsAntTimeOnOff = -1;
    itsAntTimeRaDiff.resize (nrtim, nrant);
    itsAntTimeRaDiff = 0;
    itsAntTimeDecDiff.resize (nrtim, nrant);
    itsAntTimeDecDiff = 0;
    itsAntStepping.resize (nrant);
    itsAntStepping = False;
    uInt timeIndex = 0;
    Double lastTim = times(rownrs(0)) - 1;
    uInt n = times.nelements();
    for (i=0; i<n; i++) {
	j = rownrs(i);
	if (times(j) != lastTim) {
	    lastTim = times(j);
	    Bool fnd = False;
	    while (timeIndex < nrtim) {
		if (near (lastTim, itsTimes(timeIndex))) {
		    fnd = True;
		    break;
		} else if (lastTim < itsTimes(timeIndex)) {
		    break;
		}
		timeIndex++;
	    }
	    if (!fnd) {
		throw (AipsError ("holog: time in POINTING subtable not "
				  "found in main table"));
	    }
	}
	uInt ant = ants(j);
	if (! onPos(j)) {
	    itsAntTimeOnOff(timeIndex, ant) = 1;
	    itsAntStepping(ant) = True;
	    itsAntTimeRaDiff(timeIndex, ant)  = poss(0,j) - itsRA;
	    itsAntTimeDecDiff(timeIndex, ant) = poss(1,j) - itsDEC;
	} else {
	    itsAntTimeOnOff(timeIndex, ant) = 0;
	    itsAntTimeRaDiff(timeIndex, ant) = 0;
	    itsAntTimeDecDiff(timeIndex, ant) = 0;
	}
    }

    // Fill the unspecified positions with the previous one.
    // The start one is 0.
    for (j=0; j<nrant; j++) {
	Double lastRaDiff  = 0;
	Double lastDecDiff = 0;
	Int lastOnOff = 0;
	for (i=0; i<nrtim; i++) {
	    if (itsAntTimeOnOff(i,j) < 0) {
		itsAntTimeRaDiff(i,j)  = lastRaDiff;
		itsAntTimeDecDiff(i,j) = lastDecDiff;
		itsAntTimeOnOff(i,j)   = lastOnOff;
	    } else {
		lastRaDiff  = itsAntTimeRaDiff(i,j);
		lastDecDiff = itsAntTimeDecDiff(i,j);
		lastOnOff   = itsAntTimeOnOff(i,j);
	    }
	}
    }

    // If the position in the next interval differs too much from this one,
    // the telescope was moving, thus the data at this time is invalid.
    // Take cos(DEC) into account for the RA.
    Double cosdec = cos(itsDEC);
    Double posCritDEC = posTolerance;
    Double posCritRA = posCritDEC / cosdec;
    for (j=0; j<nrant; j++) {
	for (i=0; i<nrtim-1; i++) {
	    Double raDiff = itsAntTimeRaDiff(i+1,j) - itsAntTimeRaDiff(i,j);
	    Double decDiff = itsAntTimeDecDiff(i+1,j) - itsAntTimeDecDiff(i,j);
	    if (abs(raDiff) > posCritRA
	    ||  abs(decDiff) > posCritDEC) {
		itsAntTimeOnOff(i,j) = -1;
	    }
	}
    }

    // Now find out the steps in RA and DEC.
    makeStep (itsRaStep, itsRaNsteps, itsRaGridPos,
	      itsAntTimeRaDiff, stepTolerance/cosdec);
    itsRaStep *= cosdec;
    ////    itsRaStep = 0.131/180*C::pi;
    makeStep (itsDecStep, itsDecNsteps, itsDecGridPos,
	      itsAntTimeDecDiff, stepTolerance);
    ////    itsDecStep = 0.131/180*C::pi;

    // Now set all ref/ref and step/step combinations to invalid.
    for (i=0; i<nrant; i++) {
	Bool stepping = itsAntStepping(i);
	for (j=i; j<nrant; j++) {
	    if (stepping == itsAntStepping(j)) {
		itsAntIndex(i,j) = -1;
		itsAntIndex(j,i) = -1;
	    }
	}
    }

    // Initialize griddata array.
    clearGridData();
    // Set state to steps found.
    itsState = StepFound;
}

void holog::makeStep (Double& stepSize, Int& nsteps, Matrix<Int>& gridInx,
		      const Matrix<Double>& posDiff, Double stepTolerance)
{
    // Sort the position differences
    Vector<uInt> inx;
    uInt nrp = GenSortIndirect<Double>::sort (inx, posDiff, Sort::Ascending,
					      Sort::HeapSort);
    gridInx.resize (posDiff.shape());
    Bool deleteItPos, deleteItInx, deleteItOnOff;
    const Double* posData = posDiff.getStorage (deleteItPos);
    Int* inxData = gridInx.getStorage (deleteItInx);
    const Int* onoffData = itsAntTimeOnOff.getStorage (deleteItOnOff);
    uInt nr = 0;
    Double firstPos = 0;
    Double sum = 0;
    Double sumnr = 0;
    Double last = 0;
    Bool first = True;
    for (uInt i=0; i<nrp; i++) {
	Int j = inx(i);
	if (onoffData[j] >= 0) {
	    if (first) {
		last = posData[j];
		sum = last;
		sumnr = 1;
		first = False;
	    } else {
		Double step = posData[j] - last;
		if (step > stepTolerance) {
		    if (firstPos == 0) {
			firstPos = sum/sumnr;
		    }
		    last = posData[j];
		    sum = last;
		    sumnr = 1;
		    nr++;
		} else {
		    sum += posData[j];
		    sumnr++;
		}
	    }
	    inxData[j] = nr;                   // gridpoint
	}
    }
    posDiff.freeStorage (posData, deleteItPos);
    gridInx.putStorage (inxData, deleteItInx);
    itsAntTimeOnOff.freeStorage (onoffData, deleteItOnOff);
    Double lastPos = sum/sumnr;
    stepSize = (lastPos-firstPos) / nr;
    nsteps = nr+1;
}

GlishRecord holog::getSummary()
{
    uInt i,j;
    if (itsState < StepFound) {
	throw (AipsError ("findsteps has to be done as the first step"));
    }
    // Count the number of good reference and stepping points per antenna.
    uInt na = itsAntStepping.nelements();
    Block<Int> nref(na, 0);
    Block<Int> nstep(na, 0);
    uInt nt = itsTimes.nelements();
    for (j=0; j<na; j++) {
	for (i=0; i<nt; i++) {
	    if (itsAntTimeOnOff(i,j) == 0) {
		nref[j]++;
	    } else if (itsAntTimeOnOff(i,j) == 1) {
		nstep[j]++;
	    }
	}
    }
    GlishRecord rec;
    for (i=0; i<na; i++) {
	if (itsAntStepping(i)) {
	    GlishRecord step;
	    step.add ("antenna", Int(i));
	    step.add ("nref", nref[i]);
	    step.add ("nstep", nstep[i]);
	    step.add ("bad", Int(nt)-nref[i]-nstep[i]);
	    rec.add (toString("ant",i), step);
	}
    }
    rec.add ("ntimes", Int(nt));
    rec.add ("antennas", itsAntStepping);
    rec.add ("rastep", itsRaStep);
    rec.add ("decstep", itsDecStep);
    rec.add ("ransteps", itsRaNsteps);
    rec.add ("decnsteps", itsDecNsteps);
    rec.add ("ra", itsRA);
    rec.add ("dec", itsDEC);
    rec.add ("freq", itsFreq);
    rec.add ("fieldname", itsFieldName);
    rec.add ("date", itsDate);
    rec.add ("spwid", itsSpwid);
    rec.add ("channel", itsChannel);
    rec.add ("polnrs", itsPolnrs);
    rec.add ("applytrx", itsTrx.nelements() != 0);
    return rec;
}

GlishRecord holog::getPos()
{
    if (itsState < StepFound) {
	throw (AipsError ("findsteps has to be done as the first step"));
    }
    GlishRecord rec;
    rec.add ("times", itsTimes);
    rec.add ("raoffsets", itsAntTimeRaDiff);
    rec.add ("decoffsets", itsAntTimeDecDiff);
    rec.add ("onoff", itsAntTimeOnOff);
    rec.add ("antindex", itsAntIndex);
    return rec;
}

void holog::clearGridData()
{
    itsGridData.resize (itsRaNsteps, itsDecNsteps);
    itsGridData = 0;
    itsGridAmplSum = 0;
    itsGridAmplCount = 0;
    itsGridDataStepAnt = -1;
    itsGridDataRefAnt.resize (0);
}

// Correct and sum the data for all polarizations for the given antennas.
GlishRecord holog::sumData (Int stepAntenna, Int refAntenna)
{
    if (itsState < StepFound) {
	throw (AipsError ("findsteps has to be done as the first steps"));
    }

    uInt i;
    Int nrant = itsAntStepping.nelements();
    Int sign = 1;
    Int index = -1;
    if (stepAntenna >= 0  &&  stepAntenna < nrant
    &&  refAntenna >= 0  &&  refAntenna < nrant) {
	index = itsAntIndex (stepAntenna, refAntenna);
    }
    if (index < 0) {
        index = itsAntIndex (refAntenna, stepAntenna);
	if (index < 0) {
	    throw (AipsError ("No such pair of stepping/reference antenna"));
	}
	sign = -1;
    }
    itsSumStepAnt = stepAntenna;
    itsSumRefAnt = refAntenna;

    // Now read the data and flags for the requested antenna.
    uInt nrval = itsTimes.nelements();
    Vector<uInt> rownrs = itsRowIndex (Slice(index, nrval));
    MeasurementSet subMS(itsMS(rownrs));
    ROMSColumns subMSCol (subMS);
    Cube<Complex> data = subMSCol.data().getColumn
	                        (Slicer(IPosition(2,0,itsChannel),
					IPosition(2,Slicer::MimicSource,1)));
    Cube<Bool> flags = subMSCol.flag().getColumn
	                        (Slicer(IPosition(2,0,itsChannel),
					IPosition(2,Slicer::MimicSource,1)));
    // Correct the data with the TRX values.
    if (itsTrx.nelements() > 0) {
        correctTRX (data, stepAntenna, refAntenna);
    }
    
    // Add it to the summation buffer.
    // A correction per polarization will be determined.
    itsSumCos.resize (nrval);
    itsSumSin.resize (nrval);
    itsSumCos = 0;
    itsSumSin = 0;

    // Create a GlishRecord to get the correction factors back.
    GlishRecord rec;

    // Determine correction factor per polarization by summing
    // the cosine/sine when the antenna was on position.
    itsFlags.resize (nrval);
    itsFlags = False;
    itsAmplSum = 0;
    itsAmplCount = 0;
    uInt nrpol = itsPolnrs.nelements();
    for (i=0; i<nrpol; i++) {
	Double cosfact = 0;
	Double sinfact = 0;
	Double npts = 0;
	Double ampl = 1;
	uInt polnr = itsPolnrs(i);
	for (uInt j=0; j<nrval; j++) {
	    if (itsAntTimeOnOff(j, stepAntenna) < 0
	    ||  flags(polnr, 0, j)) {
		itsFlags(j) = True;
	    } else if (itsAntTimeOnOff(j, stepAntenna) == 0) {
		cosfact += data(polnr, 0, j).real();
		sinfact += data(polnr, 0, j).imag();
		npts++;
	    }
	}
	sinfact *= sign;
	if (npts > 0) {
	    ampl = sqrt (cosfact*cosfact + sinfact*sinfact);
	    cosfact /= ampl;
	    sinfact /= ampl;
	    for (uInt j=0; j<nrval; j++) {
		if (itsAntTimeOnOff(j, stepAntenna) >= 0) {
		    if (! itsFlags(j)) {
		      const Complex& dp = data(polnr, 0, j);
		      if (dp == Complex(0., 0.)) {
			itsFlags(j) = True;
		      } else {
			itsSumCos(j) += cosfact*dp.real() + sinfact*dp.imag();
			itsSumSin(j) += cosfact*dp.imag() - sinfact*dp.real();
                      }
		    }
		}
	    }
	} else {
	    for (uInt j=0; j<nrval; j++) {
		if (itsAntTimeOnOff(j, stepAntenna) >= 0) {
		    if (! itsFlags(j)) {
		      const Complex& dp = data(polnr, 0, j);
		      if (dp == Complex(0., 0.)) {
			itsFlags(j) = True;
		      } else {
			itsSumCos(j) += dp.real();
			itsSumSin(j) += dp.imag();
                      }
		    }
		}
	    }
	}

	itsAmplSum += ampl;
	itsAmplCount++;
	GlishRecord subrec;
	subrec.add ("pol", itsPolnrs(i));
	subrec.add ("npts", npts);
	subrec.add ("sumampl", ampl);
	subrec.add ("cosfact", cosfact);
	subrec.add ("sinfact", sinfact);
	rec.add (toString("pol",i), subrec);
    }

    // Average over the polarizations.
    if (nrpol > 1) {
	itsSumCos /= Float(nrpol);
	itsSumSin /= Float(nrpol);
    }

    itsState = DataSummed;
    return rec;
}

void holog::correctTRX (Cube<Complex>& data, Int ant1, Int ant2)
{
    const IPosition& shape = data.shape();
    Int nrcorr = shape(0);
    Int nrchan = shape(1);
    Int nrtim = shape(2);
    AlwaysAssert (ant1 < itsTrx.shape()(0), AipsError);
    AlwaysAssert (ant2 < itsTrx.shape()(0), AipsError);
    AlwaysAssert (nrtim == itsTrx.shape()(1), AipsError);
    Bool deleteIt;
    Complex* dataPtr = data.getStorage (deleteIt);
    Float* ptr = (Float*)dataPtr;
    for (Int i=0; i<nrtim; i++) {
        Complex trx1 = itsTrx(ant1,i);
	Complex trx2 = itsTrx(ant2,i);
	switch (nrcorr) {
	case 4:    // XX XY YX YY
	  {
	    Float factxx = sqrt (trx1.real()*trx2.real());
	    Float factxy = sqrt (trx1.real()*trx2.imag());
	    Float factyx = sqrt (trx1.imag()*trx2.real());
	    Float factyy = sqrt (trx1.imag()*trx2.imag());
	    for (Int j=0; j<nrchan; j++) {
	        *ptr++ *= factxx;
		*ptr++ *= factxx;
		*ptr++ *= factxy;
		*ptr++ *= factxy;
		*ptr++ *= factyx;
		*ptr++ *= factyx;
		*ptr++ *= factyy;
		*ptr++ *= factyy;
	    }
	    break;
	  }
	case 2:    // XX YY
	  {
	    Float factxx = sqrt (trx1.real()*trx2.real());
	    Float factyy = sqrt (trx1.imag()*trx2.imag());
	    for (Int j=0; j<nrchan; j++) {
	        *ptr++ *= factxx;
		*ptr++ *= factxx;
		*ptr++ *= factyy;
		*ptr++ *= factyy;
	    }
	    break;
	  }
	case 1:    // XX
	  {
	    Float fact;
	    if (itsPolX) {
	      fact = sqrt (trx1.real()*trx2.real());
	    } else {
	      fact = sqrt (trx1.imag()*trx2.imag());
	    }
	    for (Int j=0; j<nrchan; j++) {
	        *ptr++ *= fact;
		*ptr++ *= fact;
	    }
	    break;
	  }
	default:
	  throw (AipsError ("itsNrCorrs != 1,2,4"));
	}
    }
    data.putStorage (dataPtr, deleteIt);
}


GlishRecord holog::gridData (Bool returnArrays)
{
    if (itsState < StepFound) {
	throw (AipsError ("findsteps has to be done as the first steps"));
    }
    Int i,j;
    if (itsSumStepAnt != itsGridDataStepAnt) {
	if (itsGridDataRefAnt.nelements() > 0) {
	    throw (AipsError ("do cleargriddata before gridding another "
			      "stepping antenna"));
	}
    }
    itsGridDataStepAnt = itsSumStepAnt;
    Int nant = itsGridDataRefAnt.nelements();
    itsGridDataRefAnt.resize (nant+1, True);
    itsGridDataRefAnt(nant) = itsSumRefAnt;

    itsGridAmplSum += itsAmplSum;
    itsGridAmplCount += itsAmplCount;

    Matrix<Double> an (itsRaNsteps, itsDecNsteps);
    Matrix<Double> dn (itsRaNsteps, itsDecNsteps);
    Matrix<Double> andn (itsRaNsteps, itsDecNsteps);
    Matrix<Double> dn2 (itsRaNsteps, itsDecNsteps);
    Matrix<Double> cnan (itsRaNsteps, itsDecNsteps);
    Matrix<Double> snan (itsRaNsteps, itsDecNsteps);
    Matrix<Int> n (itsRaNsteps, itsDecNsteps);
    an = 0;
    dn = 0;
    andn = 0;
    dn2 = 0;
    cnan = 0;
    snan = 0;
    n = 0;

    // Loop through all elements in the sum buffer and add them to the
    // correct grid point (if not flagged off).
    Int nrval = itsTimes.nelements();
    Double stdec = -(itsDecNsteps-1)/2 * itsDecStep;
    for (i=0; i<nrval; i++) {
	if (! itsFlags(i)) {
	    Int inxra = itsRaGridPos(i,itsGridDataStepAnt);
	    Int inxdec = itsDecGridPos(i,itsGridDataStepAnt);
	    n(inxra, inxdec)++;
	    Double cosval = itsSumCos(i);
	    Double sinval = itsSumSin(i);
	    Double ampl = sqrt(cosval*cosval + sinval*sinval);
	    an(inxra,inxdec) += ampl;
	    cnan(inxra,inxdec) += cosval/ampl;
	    snan(inxra,inxdec) += sinval/ampl;
	    Int ant = itsGridDataStepAnt;
	    Double dec = itsAntTimeDecDiff(i,ant);
	    if (i < nrval-1) {
		dec = (dec + itsAntTimeDecDiff(i+1,ant)) / 2;
	    }
	    Double dist = stdec + inxdec*itsDecStep;
	    dn(inxra,inxdec) += dist;
	    dn2(inxra,inxdec) += dist*dist;
	    andn(inxra,inxdec) += ampl*dist;
	}
    }
    for (j=0; j<itsDecNsteps; j++) {
	for (i=0; i<itsRaNsteps; i++) {
	    Double cosval = 0;
	    Double sinval = 0;
	    if (n(i,j) > 0) {
		Double a0;
		Double factor = n(i,j) * dn2(i,j) - dn(i,j) * dn(i,j);
		if (abs(factor) < 0.001) {
		    a0 = an(i,j) / n(i,j);
		} else {
		    a0 = (an(i,j) * dn2(i,j) - andn(i,j) * dn(i,j)) / factor;
		}
	        cosval = a0 * cnan(i,j) / n(i,j);
		sinval = a0 * snan(i,j) / n(i,j);
	    }
	    // Add the new values and average correctly.
	    cosval += nant*itsGridData(i,j).real();
	    sinval += nant*itsGridData(i,j).imag();
	    ///	    itsGridData(i,j).real() = cosval / (nant+1);
	    ///	    itsGridData(i,j).imag() = sinval / (nant+1);
	    itsGridData(i,j) = Complex(cosval / (nant+1), sinval / (nant+1));
	}
    }

    itsState = DataGridded;
    GlishRecord rec;
    rec.add ("centerampl", abs(itsGridData(itsRaNsteps/2, itsDecNsteps/2)));
    if (returnArrays) {
	rec.add ("n",n);
	rec.add ("an",an);
	rec.add ("andn",andn);
	rec.add ("dn",dn);
	rec.add ("dn2",dn2);
	rec.add ("cnan",cnan);
	rec.add ("snan",snan);
	rec.add ("sumcos", itsSumCos);
	rec.add ("sumsin", itsSumSin);
	rec.add ("rapos", itsRaGridPos);
	rec.add ("decpos", itsDecGridPos);
    }
    return rec;
}

GlishRecord holog::getGridData()
{
    GlishRecord rec;
    rec.add ("fieldname", itsFieldName);
    rec.add ("date", itsDate);
    rec.add ("stepant", itsGridDataStepAnt);
    rec.add ("refant", itsGridDataRefAnt);
    rec.add ("griddata", itsGridData);
    rec.add ("amplsum", itsGridAmplSum);
    rec.add ("amplcount", itsGridAmplCount);
    return rec;
}

void holog::rotateGridData (Double rotDistance)
{
    if (itsState < DataGridded) {
	throw (AipsError ("griddata has to be done before rotategriddata"));
    }
    Int nant = itsGridDataRefAnt.nelements();
    if (nant == 0) {
	throw (AipsError ("function griddata should be executed first"));
    }
    Double stdec = - itsDecStep * ((itsDecNsteps-1) / 2);
    Double factor = 2 * C::pi * (itsFreq / C::c) * rotDistance;
    for (Int j=0; j<itsDecNsteps; j++) {
	Double stra = - itsRaStep * ((itsRaNsteps-1) / 2);
	for (Int i=0; i<itsRaNsteps; i++) {
	    Double rotangle = sqrt(stra*stra + stdec*stdec);
	    Double dphase = factor * (1 - cos(rotangle));
	    Double cosph = cos(dphase);
	    Double sinph = sin(dphase);
	    Complex& data = itsGridData(i,j);
	    Float cosdt = cosph*data.real() + sinph*data.imag();
	    Float sindt = cosph*data.imag() + sinph*data.real();
	    data = Complex(cosdt, sindt);
	    stra += itsRaStep;
	}
	stdec += itsDecStep;
    }

    itsState = DataRotated;
}

void holog::fft (Int size, Float diameter, Float simFreq)
{
    if (itsState < DataGridded) {
	throw (AipsError ("(rotate)griddata has to be done before fft"));
    }
    AlwaysAssert (size>itsRaNsteps && size>itsDecNsteps, AipsError);
    FFTServer<Float,Complex> fft;
    itsFFTData.resize (size, size);
    itsFFTData = 0;
    itsSimFreq = simFreq;
    if (itsSimFreq <= 0) {
	itsSimFreq = itsFreq;
    }

    // Determine squared radius and distance in x and y.
    const IPosition& shape = itsFFTData.shape();
    itsDx = C::c / itsRaStep / itsFreq;       // aperture size west-east
    itsDy = C::c / itsDecStep/ itsFreq;       // aperture size north-south
    itsDx /= shape(0);
    itsDy /= shape(1);
    itsRadsq = diameter/2 * diameter/2;

    Int stra = (size-itsRaNsteps+1)/2;
    Int stdec = (size-itsDecNsteps+1)/2;
    itsFFTData(IPosition(2, stra, stdec),
	       IPosition(2, stra+itsRaNsteps-1,
			 stdec+itsDecNsteps-1)) = itsGridData;
    fft.fft (itsFFTData, False);

    // Set state to FFT done.
    itsState = FFTDone;
}

GlishRecord holog::refineFFT()
{
    if (itsState < FFTDone) {
	throw (AipsError ("fft has to be done before refinefft"));
    }

    // Get amplitude of center element.
    Float amplCenter = abs (itsGridData(itsRaNsteps/2, itsDecNsteps/2));
    const IPosition& shape = itsFFTData.shape();
    Int centerx = shape(0) / 2;
    Int centery = shape(1) / 2;

    // Set elements outside mirror to 0.
    // Do a forward FFT to get original (more or less) back.
    for (Int j=0; j<shape(1); j++) {
	Float disy = (j-centery) * itsDy;
	for (Int i=0; i<shape(0); i++) {
	    Float disx = (i-centerx) * itsDx;
	    if (disx*disx + disy*disy > itsRadsq) { 
		itsFFTData(i,j) = 0;
	    }
	}
    }
    FFTServer<Float,Complex> fft;
    fft.fft (itsFFTData, True);

    // Get amplitude of center element to return to user.
    Float ampl = abs (itsFFTData(centerx, centery));

    // Put gridded data back and do reverse transform.
    Int stra = (shape(0)-itsRaNsteps+1)/2;
    Int stdec = (shape(1)-itsDecNsteps+1)/2;
    itsFFTData(IPosition(2, stra, stdec),
	       IPosition(2, stra+itsRaNsteps-1,
			 stdec+itsDecNsteps-1)) = itsGridData;
    fft.fft (itsFFTData, False);
    
    GlishRecord rec;
    rec.add ("centerampl", ampl);
    rec.add ("gain", ampl/amplCenter);
    return rec;
}

GlishRecord holog::getFFTData()
{
    GlishRecord rec;
    rec.add ("fieldname", itsFieldName);
    rec.add ("date", itsDate);
    rec.add ("stepant", itsGridDataStepAnt);
    rec.add ("refant", itsGridDataRefAnt);
    rec.add ("fftdata", itsFFTData);
    return rec;
}

GlishRecord holog::normalize (Float amplCrit)
{
    Int i,j;
    if (itsState < FFTDone) {
	throw (AipsError ("fft has to be done before normalize"));
    }
    
    const IPosition& shape = itsFFTData.shape();
    Int centerx = shape(0) / 2;
    Int centery = shape(1) / 2;

    // Set elements outside mirror to 0.
    // Convert cos/sin to ampl/phase for the elements on mirror.
    Float factor = itsFFTData.nelements() / itsGridAmplSum * itsGridAmplCount;
    Int noutside = 0;
    Float maxAmpl = 0;
    Float minAmpl = 0;
    itsAmpl.resize (shape);
    itsPhase.resize (shape);
    for (j=0; j<shape(1); j++) {
	Float disy = (j-centery) * itsDy;
	for (i=0; i<shape(0); i++) {
	    Float disx = (i-centerx) * itsDx;
	    if (disx*disx + disy*disy > itsRadsq) { 
		itsAmpl(i,j) = 0;
		itsPhase(i,j) = 0;
		noutside++;
	    } else {
		Float ampl = factor * abs(itsFFTData(i,j));
		if (maxAmpl == 0  ||  ampl < minAmpl) {
		    minAmpl = ampl;
		}
		if (ampl > maxAmpl) {
		    maxAmpl = ampl;
		}
		itsAmpl(i,j) = ampl;
		itsPhase(i,j) = arg(itsFFTData(i,j));
            }
	}
    }

    Float threshold = amplCrit * maxAmpl;
    Int nbelow = 0;
    for (j=0; j<shape(1); j++) {
	for (i=0; i<shape(0); i++) {
	    if (itsAmpl(i,j) < threshold) {
		itsPhase(i,j) = 0;
		nbelow++;
	    }
	}
    }

    GlishRecord rec;
    rec.add ("fieldname", itsFieldName);
    rec.add ("date", itsDate);
    rec.add ("stepant", itsGridDataStepAnt);
    rec.add ("refant", itsGridDataRefAnt);
    rec.add ("diameter", 2*sqrt(itsRadsq));
    rec.add ("simfreq", itsSimFreq);
    rec.add ("dx", itsDx);
    rec.add ("dy", itsDy);
    rec.add ("amplsum", itsGridAmplSum);
    rec.add ("amplcount", itsGridAmplCount);
    rec.add ("factor", factor);
    rec.add ("noutside", noutside);
    rec.add ("minampl", minAmpl);
    rec.add ("maxampl", maxAmpl);
    rec.add ("nbelow", nbelow-noutside);

    itsState = Normalized;
    return rec;
}

GlishRecord holog::getPhaseJumps()
{
    if (itsState < Normalized) {
	throw (AipsError ("normalize has to be done before phasejumps"));
    }
    
    const IPosition& shape = itsPhase.shape();
    Float prev = 0;
    Int njump = 0;
    for (Int j=0; j<shape(1); j++) {
	for (Int i=0; i<shape(0); i++) {
	    Int inx = i;
	    if (j%2 != 0) {
		inx = shape(0) - i;
	    }
	    Float phase = itsPhase(i,j);
	    if (phase != 0) {
		Float step = phase - prev;
		if (step > C::pi) {
		    njump++;
		}
		prev = phase;
	    }
	}
    }	    
    GlishRecord rec;
    rec.add ("njump", njump);
    return rec;
}

GlishRecord holog::getAmplPhase()
{
    GlishRecord rec;
    rec.add ("fieldname", itsFieldName);
    rec.add ("date", itsDate);
    rec.add ("stepant", itsGridDataStepAnt);
    rec.add ("refant", itsGridDataRefAnt);
    rec.add ("ampl", itsAmpl);
    rec.add ("phase", itsPhase);
    return rec;
}

GlishRecord holog::solve (Float focalLength)
{
    Int i,j;
    if (itsState != Normalized) {
	throw (AipsError ("solve can only be done after normalize"));
    }

    // Correct for a pointing error.
    // In the future focus errors can also be found by adding
    // quadratic terms p3*x^2 and p4*y^2.
    // Start with filling the phase vector.
    const IPosition& shape = itsPhase.shape();
    Vector<Double> phase(itsPhase.nelements());
    Int centerx = shape(0) / 2;
    Int centery = shape(1) / 2;
    Int nr = 0;
    const Float threshold = 0.000001;
    // Take all points with sufficient phase.
    for (j=0; j<shape(1); j++) {
	for (i=0; i<shape(0); i++) {
	    if (abs(itsPhase(i,j)) > threshold) {
		phase(nr) = itsPhase(i,j);
		nr++;
	    }
	}
    }
    phase.resize (nr, True);

    // Now fill the matrix with x and y.
    Matrix<Double> x(nr, 2);
    Int n = 0;
    for (j=0; j<shape(1); j++) {
	Double disy = (j-centery) * itsDy;
	for (i=0; i<shape(0); i++) {
	    if (abs(itsPhase(i,j)) > threshold) {
		Double disx = (i-centerx) * itsDx;
		x(n, 0) = disx;
		x(n, 1) = disy;
		n++;
	    }
	}
    }
    AlwaysAssert (nr==n, AipsError);

    // The fitted function has the form: 
    // p0 + p1*x + p2*y + p3*x^2 + p4*y^2 + p5*x*y
    // We use sigma=1.
    Vector<Double> sigma(nr);
    sigma = 1;

    // Convert C++ functions to Functionals
    FunctionWrapper<AutoDiff<Double> > f1(fitFunc1, 2);
    FunctionWrapper<AutoDiff<Double> > fx(fitFuncx, 2);
    FunctionWrapper<AutoDiff<Double> > fy(fitFuncy, 2);
    FunctionWrapper<AutoDiff<Double> > fxx(fitFuncxx, 2);
    FunctionWrapper<AutoDiff<Double> > fyy(fitFuncyy, 2);
    FunctionWrapper<AutoDiff<Double> > fxy(fitFuncxy, 2);

    // form linear combination of functions
    // f(x,y) = a0 + a1*x+ a2*y + a3*x*x + a4*y*y + a5*x*y
    CombiFunction<AutoDiff<Double> > combination;
    combination.addFunction (f1);
    combination.addFunction (fx);
    combination.addFunction (fy);
//    combination.addFunction (fxx);          // forget quadratic for now
//    combination.addFunction (fyy);
//    combination.addFunction (fxy);

    // Now fit using SVD and the given function combination.
    LinearFitSVD<Double> fitter;
    fitter.setFunction (combination);
    Vector<Double> params = fitter.fit (x, phase, sigma);

    Vector<Double> par (params.copy());
//    par(0) = 0.85704682/180*C::pi;
//    par(1) = 0.34177771/180*C::pi;
//    par(2) = -0.30498689/180*C::pi;
    
    // Now correct the phases.
    for (j=0; j<shape(1); j++) {
	Double disy = (j-centery) * itsDy;
	for (i=0; i<shape(0); i++) {
	    if (itsPhase(i,j) != 0) {
		Double disx = (i-centerx) * itsDx;
		itsPhase(i,j) -= par(0) - par(1)*disx - par(2)*disy;
	    }
	}
    }

    // Find the surface errors.
    // The formula is:
    //     factor = sqrt (1 + (x*x + y*y) / (4*focal*focal))
    //     E(i,j) = c / (4*pi*freq) * factor * phase(i,j)
    // where E(i,j) gives the surface error in meters.
    itsErrors.resize (shape);
    itsErrors = 0;
    Float sum = 0;
    Float sum2 = 0;
    Int nrms = 0;
    Float focalconst = 4*focalLength*focalLength;
    Float const1 = C::c / (4 * C::pi * itsSimFreq);
    for (j=0; j<shape(1); j++) {
	Double disy = (j-centery) * itsDy;
	for (i=0; i<shape(0); i++) {
	    Double disx = (i-centerx) * itsDx;
	    Float dist = disx*disx + disy*disy;
	    Float factor = 1 + dist / focalconst;
	    Float error = itsPhase(i,j) * const1 * sqrt(factor);
	    itsErrors(i,j) = error;
	    if (dist < itsRadsq) {
		Float ampl = itsAmpl(i,j);
		sum += ampl;
		sum2 += ampl * error * error;
		nrms++;
	    }
	}
    }

    // Calculate RMS of surface errors and the gain-loss-factor.
    Float rms = sqrt(sum2 / (sum - sum/nrms));
    Float gainloss = rms / const1;
    gainloss = exp (-gainloss*gainloss);

    // Return the parameters.
    GlishRecord rec;
    rec.add ("fieldname", itsFieldName);
    rec.add ("date", itsDate);
    rec.add ("p", params);
    rec.add ("nfitpoints", nr);
    rec.add ("rms", rms);
    rec.add ("gainloss", gainloss);
    rec.add ("nrms", nrms);

    itsState = Solved;
    return rec;
}

AutoDiff<Double> holog::fitFunc1 (const Vector<AutoDiff<Double> >&) {
  return 1; }
AutoDiff<Double> holog::fitFuncx (const Vector<AutoDiff<Double> >& x) {
  return x(0);}
AutoDiff<Double> holog::fitFuncy (const Vector<AutoDiff<Double> >& x) {
  return x(1);}
AutoDiff<Double> holog::fitFuncxx (const Vector<AutoDiff<Double> >& x) {
  return x(0)*x(0);}  
AutoDiff<Double> holog::fitFuncyy (const Vector<AutoDiff<Double> >& x) {
  return x(1)*x(1);}
AutoDiff<Double> holog::fitFuncxy (const Vector<AutoDiff<Double> >& x) {
  return x(0)*x(1);}

GlishRecord holog::getSolution()
{
    if (itsState < Normalized) {
	throw (AipsError ("solve has to be done before getsolution"));
    }
    GlishRecord rec;
    rec.add ("fieldname", itsFieldName);
    rec.add ("date", itsDate);
    rec.add ("stepant", itsGridDataStepAnt);
    rec.add ("refant", itsGridDataRefAnt);
    rec.add ("errors", itsErrors);
    rec.add ("power", itsAmpl);
    return rec;
}

/*
GlishRecord::correctPhase()
{
    
}
*/

// Public methods needed to run DO

String holog::className() const
{
    return "holog";
}

Vector<String> holog::methods() const
{
    Vector<String> method(18);
    method(0) = "init";
    method(1) = "getsummary";
    method(2) = "getpos";
    method(3) = "findsteps";
    method(4) = "cleargriddata";
    method(5) = "setnsteps";
    method(6) = "sumdata";
    method(7) = "griddata";
    method(8) = "rotategriddata";
    method(9) = "getgriddata";
    method(10) = "fft";
    method(11) = "refinefft";
    method(12) = "getfftdata";
    method(13) = "normalize";
    method(14) = "getphasejumps";
    method(15) = "getap";
    method(16) = "solve";
    method(17) = "getsolution";
    return method;
}

Vector<String> holog::noTraceMethods() const
{
    return methods();
}

MethodResult holog::runMethod (uInt which, 
			       ParameterSet& inputRecord,
			       Bool runMethod)
{
    switch (which) {
    case 0: // initialize
    {
	Parameter<Bool> applytrx(inputRecord, "applytrx", ParameterSet::In);
	if (runMethod) {
	    init (applytrx());
	}
    }
    break;
    case 1: // get summary
    {
	Parameter<GlishRecord> returnval (inputRecord, "returnval",
					  ParameterSet::Out);
	if (runMethod) {
	    returnval() = getSummary();
	}
    }
    break;
    case 2: // get positions
    {
	Parameter<GlishRecord> returnval (inputRecord, "returnval",
					  ParameterSet::Out);
	if (runMethod) {
	    returnval() = getPos();
	}
    }
    break;
    case 3: // find the steps in RA and DEC
    {
	Parameter<Float> postol(inputRecord, "postolerance", ParameterSet::In);
	Parameter<Float> steptol(inputRecord, "steptolerance",ParameterSet::In);
	Double postold = postol() / Double(180) * C::pi;
	Double steptold = steptol() / Double(180) * C::pi;
	if (runMethod) {
	    findSteps (postold, steptold);
	}
    }
    break;
    case 4: // clear the griddata buffer
    {
	if (runMethod) {
	    clearGridData();
	}
    }
    break;
    case 5: // set the number of steps (not supported)
//    {
//	Parameter<Int> nstep(inputRecord, "nsteps", ParameterSet::In);
//	if (runMethod) {
//	    setStep (nstep());
//	}
//    }
    break;
    case 6: // sum the data
    {
	Parameter<Int> stepAnt(inputRecord, "stepant", ParameterSet::In);
	Parameter<Int> refAnt(inputRecord, "refant", ParameterSet::In);
	Parameter<GlishRecord> returnval (inputRecord, "returnval",
					  ParameterSet::Out);
	if (runMethod) {
	    returnval() = sumData (stepAnt(), refAnt());
	}
    }
    break;
    case 7: // grid the data
    {
	Parameter<Bool> arrays(inputRecord, "returnarrays", ParameterSet::In);
	Parameter<GlishRecord> returnval (inputRecord, "returnval",
					  ParameterSet::Out);
	if (runMethod) {
	    returnval() = gridData (arrays());
	}
    }
    break;
    case 8: // rotate the gridded data
    {
	Parameter<Float> rotdist(inputRecord, "rotdistance", ParameterSet::In);
	if (runMethod) {
	    rotateGridData (rotdist());
	}
    }
    break;
    case 9: // get the gridded data
    {
	Parameter<GlishRecord> returnval (inputRecord, "returnval",
					  ParameterSet::Out);
	if (runMethod) {
	    returnval() = getGridData();
	}
    }
    break;
    case 10: // fft the data
    {
	Parameter<Int> size(inputRecord, "size", ParameterSet::In);
	Parameter<Float> diameter(inputRecord, "diameter", ParameterSet::In);
	Parameter<Float> simFreq(inputRecord, "simfreq", ParameterSet::In);
	if (runMethod) {
	    fft (size(), diameter(), simFreq());
	}
    }
    break;
    case 11: // refine the fft
    {
	Parameter<GlishRecord> returnval (inputRecord, "returnval",
					  ParameterSet::Out);
	if (runMethod) {
	    returnval() = refineFFT();
	}
    }
    break;
    case 12: // get the fft data
    {
	Parameter<GlishRecord> returnval (inputRecord, "returnval",
					  ParameterSet::Out);
	if (runMethod) {
	    returnval() = getFFTData();
	}
    }
    break;
    case 13: // normalize
    {
	Parameter<Float> amplCrit (inputRecord, "amplcrit", ParameterSet::In);
	Parameter<GlishRecord> returnval (inputRecord, "returnval",
					  ParameterSet::Out);
	if (runMethod) {
	    returnval() = normalize (amplCrit());
	}
    }
    break;
    case 14: // get the phase jumps
    {
	Parameter<GlishRecord> returnval (inputRecord, "returnval",
					  ParameterSet::Out);
	if (runMethod) {
	    returnval() = getPhaseJumps();
	}
    }
    break;
    case 15: // get the ampl/phase
    {
	Parameter<GlishRecord> returnval (inputRecord, "returnval",
					  ParameterSet::Out);
	if (runMethod) {
	    returnval() = getAmplPhase();
	}
    }
    break;
    case 16: // solve the surface errors
    {
	Parameter<Float> focalLength (inputRecord, "focallength",
				      ParameterSet::In);
	Parameter<GlishRecord> returnval (inputRecord, "returnval",
					  ParameterSet::Out);
	if (runMethod) {
	    returnval() = solve (focalLength());
	}
    }
    break;
    case 17: // get the solution
    {
	Parameter<GlishRecord> returnval (inputRecord, "returnval",
					  ParameterSet::Out);
	if (runMethod) {
	    returnval() = getSolution();
	}
    }
    break;
    default:
	return error ("No such method");
    }
    return ok();
}


MethodResult hologFactory::make (ApplicationObject*& newObject,
				 const String& whichConstructor,
				 ParameterSet& inputRecord,
				 Bool runConstructor)
{
    MethodResult retval;
    newObject = 0;
    
    if (whichConstructor == "holog") {
	Parameter<String> msName (inputRecord,
				  "msname",
				  ParameterSet::In);
	Parameter<Int> spwid (inputRecord,
			      "spwid",
			      ParameterSet::In);
	Parameter<Int> channel (inputRecord,
				"channel",
				ParameterSet::In);
	Parameter<Array<Int> > polnrs (inputRecord,
				       "polnrs",
				       ParameterSet::In);
	if (runConstructor) {
	    newObject = new holog(msName(), spwid(), channel(), polnrs());
	}
    } else {
	retval = String("Unknown constructor ") + whichConstructor;
    }

    if (retval.ok() && runConstructor && !newObject) {
	retval = "Memory allocation error";
    }
    return retval;
}

String holog::toString (const String& prefix, uInt value)
{
    char strc[16];
    sprintf (strc, "%i", value);
    return prefix + strc;
}
