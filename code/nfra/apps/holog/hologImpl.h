//# hologImpl.h: Functionality for the holog Distributed Object
//# Copyright (C) 1998,2000,2002,2003
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
//# $Id: hologImpl.h,v 19.4 2004/11/30 17:50:39 ddebonis Exp $

#ifndef NFRA_HOLOGIMPL_H
#define NFRA_HOLOGIMPL_H


//# Includes
#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <scimath/Mathematics/AutoDiff.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MeasurementSets/MSColumns.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Cube.h>
#include <casa/BasicSL/Complex.h>
#include <casa/BasicSL/String.h>
#include <tasking/Glish/GlishRecord.h>


#include <casa/namespace.h>
// <summary> 
// Functionality for the holog Distributed Object.
// </summary>

// <use visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class=MeasurementSet>MeasurementSet</linkto>
//   <li> <linkto class=FFTServer>FFTServer</linkto>
//   <li> <linkto class=LinearFitSVD>LinearFitSVD</linkto>
//   <li> <linkto class=GlishRecrd>GlishRecord</linkto>
//   <li> Theory about holographic observations.
// </prerequisite>

// <etymology>
// holog is a shorthand for holographic techniques. The term was
// widely used in the WSRT environment.
// </etymology>

// <synopsis>
// Class holog offers the services needed for reducing holographic
// observations to measures the power and surface of the mirror of
// a radiotelescope. It is based on the old holog program used in
// Westerbork written in Fortran by Hans van Someren Greve and Teun Grit.
// <p>
// The functions in it are the services offered by this DO to the
// glish world.
// </synopsis>

// <example>
// </example>

// <motivation>
// The Westerbork holog program is HP1000 specific and can not be
// used anymore.
// </motivation>

//# <todo asof="yyyy/mm/dd">
//#   <li> start discussion of this possible extension
//# </todo>


class holog : public ApplicationObject
{
public:
    // Define the states of the holog reduction.
    enum State {
        Constructed,
	Initialized,
	StepFound,
	DataSummed,
	DataGridded,
	DataRotated,
	FFTDone,
	Normalized,
	Solved
    };

// "holog" ctor from the name of a MeasurementSet, the required spectral
// window, channel, and polarisation.
// If <src>spwid<0</src> all spwid 0 will be taken.
// If <src>channel<0</src>, channel 0 will be taken.
// If polnrs is empty or first element is negative, the XX and (if available)
// YY polarisation will be taken.
    holog (const String& msName, Int spwid, Int channel,
	   const Vector<Int>& polnrs);

// Destructor.
    ~holog();

// Initialize the process by sorting the given measurementset
// on antenna and time resulting in itsRowIndex.
// It generates an index (itsAntIndex) telling where each baseline
// starts in the measurementset. A negative value indicates that
// no such baseline is available.
    void init (Bool applyTRX);

// Scan the POINTING subtable and find which antennas are at
// a fixed position and which are stepping in a grid. It also finds
// the step size in RA (corrected for cos(DEC)) and DEC and the number
// of steps.
    void findSteps (Double posCrit, Double stepTolerance);

// Create a summary of the observation (name, position, step sizes, etc.).
    GlishRecord getSummary();

// Give all position information vectors and matrices.
// It is merly a debugging tool, although itsAntIndex can be very useful
// to find out which stepping/reference baselines are available.
    GlishRecord getPos();

// Summate the data for the given stepping and reference antenna.
// An exception is thrown if such a baseline does not exist.
// It applies a correction with the average amplitude for the time
// the stepping telescope was on source.
    GlishRecord sumData (Int stepAntenna, Int refAntenna);

// Clear the grid data.
// This step is needed before adding a sumData result for another
// stepping antenna.
    void clearGridData();

// Add the last summated data to the gridded data.
// An exception is thrown if the stepping antenna of the summated data
// differs from the stepping antenna of the gridded data.
// It returns a bit of information about the gridding process.
// When <src>returnArrays</src> is True, much more information is
// returned for debugging purposes.
    GlishRecord gridData (Bool returnArrays);

// Get the gridded data.
    GlishRecord getGridData();

// Correct the gridded data for rotation of the mirror for a telescope
// like the WSRT.
    void rotateGridData (Double rotDistance);

// Do an FFT with the given size of the gridded data.
// The mirror diameter and simulated frequency are needed for
// later steps. When <src>simFreq==0</src>, the actual frequency is used.
    void fft (Int size, Float diameter, Float simFreq);

// Refine the FFT result by doing an FFT back to the original domain,
// inserting zeroes for all points outside the mirror and FFT-ing again.
    GlishRecord refineFFT();

// Get the result of the latest FFT or refineFFT.
    GlishRecord getFFTData();

// Convert the result of the FFT to amplitude and phase.
// The phases are set to zero for the points where the amplitude is
// less than <src>amplCrit</src> % of the maximum amplitude.
    GlishRecord normalize (Float amplCrit);

// Determine the number of phase jumps.
    GlishRecord getPhaseJumps();

// Get the amplitude and phase.
    GlishRecord getAmplPhase();

// Find the surface errors.
// First it corrects the phases for a pointing error by solving
// for the slope of the phases by means of a least squares fit.
    GlishRecord solve (Float focalLength);

// Get the solution (power and surface).
    GlishRecord getSolution();

// Stuff needed for distributing this class
    // <group>
    virtual String className() const;
    virtual Vector<String> methods() const;
    virtual Vector<String> noTraceMethods() const;
    // </group>

// If your object has more than one method
    virtual MethodResult runMethod (uInt which, 
				    ParameterSet& inputRecord,
				    Bool runMethod);

private:

    // Forbid copy constructor (not needed).
    holog (const holog& other);

    // Forbid assignment (not needed).
    holog& operator= (const holog& other);

    // Make the step for RA or DEC.
    void makeStep (Double& stepSize, Int& nsteps,  Matrix<Int>& gridInx,
		   const Matrix<Double>& posDiff, Double stepTolerance);

    // Fill the TRX matrix from the SYSCAL table.
    void fillTRX();

    // Correct the data for the TRX values of given antennas.
    void correctTRX (Cube<Complex>& data, Int ant1, Int ant2);

    // Convert integer to string. 
    static String toString (const String& prefix, uInt value);

    // Functions for the least squares fitter.
    static AutoDiff<Double> fitFunc1 (const Vector<AutoDiff<Double> >&);
    static AutoDiff<Double> fitFuncx (const Vector<AutoDiff<Double> >&);
    static AutoDiff<Double> fitFuncy (const Vector<AutoDiff<Double> >&);
    static AutoDiff<Double> fitFuncxx (const Vector<AutoDiff<Double> >&);
    static AutoDiff<Double> fitFuncyy (const Vector<AutoDiff<Double> >&);
    static AutoDiff<Double> fitFuncxy (const Vector<AutoDiff<Double> >&);

    // Prints an error message if the image DO is detached and returns True.
    Bool detached() const;

    //# The variables needed. Standard units are used.
    //# (positions in radians; lengths in meters; freq in Hz).
    MeasurementSet   itsMS;
    ROMSColumns*     itsMSColumns;
    State            itsState;
    Int              itsSpwid;
    Int              itsChannel;
    Vector<Int>      itsPolnrs;
    Bool             itsPolX;             //# is an X polarization given?
    Double           itsRA;
    Double           itsDEC;
    String           itsFieldName;
    String           itsDate;
    Double           itsFreq;
    Vector<Bool>     itsAntStepping;      //# True = antenna is stepping
    Vector<Double>   itsTimes;            //# All unique times in measurementset
    Vector<uInt>     itsRowIndex;         //# sort order ant1,ant2,time
    Matrix<Int>      itsAntIndex;         //# start of (ant1,ant2) in rowindex
    Matrix<Int>      itsAntTimeOnOff;     //# 1=offpos, 0=onpos, -1=invalid
    //# The following arrays have shape (ntim,nant).
    Matrix<Double>   itsAntTimeRaDiff;    //# RA-offset from field pos.
    Matrix<Double>   itsAntTimeDecDiff;   //# DEC-offset from field pos.
    Matrix<Int>      itsRaGridPos;        //# RA-grid element number
    Matrix<Int>      itsDecGridPos;       //# DEC-grid element number
    Matrix<Complex>  itsTrx;              //# SysCal correction factor
    Double           itsRaStep;           //# RA step (corrected for cos(dec))
    Double           itsDecStep;          //# DEC step
    Int              itsRaNsteps;         //# nr of grid elements
    Int              itsDecNsteps;
    //# The following variables are counters for summing
    //# the wanted polarisations in a given baseline.
    //# The length of the vectors is the number of rows.
    Int              itsSumStepAnt;       //# stepping antenna of this sum
    Int              itsSumRefAnt;        //# reference antenna of this sum
    Vector<Float>    itsSumCos;           //# the summed cosine per time
    Vector<Float>    itsSumSin;           //# the summed sine per time
    Vector<Bool>     itsFlags;            //# data flags (True is invalid)
    Float            itsAmplSum;          //# the summed amplitude of all
    Int              itsAmplCount;        //# pixels in the sum.
    //# The following variables are used for the gridding (before and
    //# after possible rotation).
    //# The same of the grid is (itsRaNsteps, itsDecNsteps).
    Int              itsGridDataStepAnt;  //# stepping antenna of last grid
    Vector<Int>      itsGridDataRefAnt;   //# empty is itsGridData is cleared
    Matrix<Complex>  itsGridData;         //# the gridded data
    Float            itsGridAmplSum;      //# the sum of all elements
    Int              itsGridAmplCount;
    //# The following variables are used to hold the result of the FFT's
    //# and the conversion to amplitude (power), phase and surface error.
    //# The size of the matrices is the FFT size.
    Matrix<Complex>  itsFFTData;          //# FFT result (also when refined)
    Float            itsDx;               //# aperture step in west-east
    Float            itsDy;               //# aperture step in north-south
    Float            itsRadsq;            //# Square of mirror radius
    Float            itsSimFreq;          //# Simulated frequency
    Matrix<Float>    itsAmpl;             //# Power
    Matrix<Float>    itsPhase;            //# Phase (also when corrected)
    Matrix<Float>    itsErrors;           //# Surface errors
};



class hologFactory : public ApplicationObjectFactory
{
    virtual MethodResult make (ApplicationObject*& newObject,
			       const String& whichConstructor,
			       ParameterSet& inputRecord,
			       Bool runConstructor);
};



#endif
