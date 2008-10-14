//# sdaveragerDO: this defines sdaverager, which is the averager used by sdcalc
//# Copyright (C) 1996,1997,1998,2000,2001,2002
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
//# $Id: sdaveragerDO.h,v 19.5 2004/11/30 17:50:09 ddebonis Exp $

#ifndef APPSGLISH_SDAVERAGERDO_H
#define APPSGLISH_SDAVERAGERDO_H

#include <casa/aips.h>
#include <tasking/Tasking.h>

#include <casa/Arrays/Array.h>
#include <casa/Arrays/LogiMatrix.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/Complex.h>
#include <measures/Measures/MDoppler.h>
#include <measures/Measures/MFrequency.h>
#include <casa/BasicSL/String.h>
#include <scimath/Mathematics/FFTServer.h>
#include <casa/Quanta/Unit.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class sditerator;
class SDRecord;
class VelocityMachine;
} //# NAMESPACE CASA - END


// <summary>
// </summary>

// <use visibility=local>   or   <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
//   <li> SomeOtherClass
//   <li> some concept
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <templating arg=T>
//    <li>
//    <li>
// </templating>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="1998/07/13">
//   <li> Use logger instead of simple cout for errors in accumulateIterator
//   <li> Clean up use of matrix weights vs scalar weight
//   <li> Use the flag array as well
//   <li> Is double precision necessary internally?
//   <li> allow for ranges in RMS calculation
//   <li> check on units of X-axis and convert when possible
// </todo>

class sdaverager : public ApplicationObject
{
public:
    sdaverager();
    sdaverager(const sdaverager& other);
    ~sdaverager();

    sdaverager& operator=(const sdaverager& other);

    // clear the internal accumulation
    // clear() always returns True
    Bool clear();

    // set the weight state
    // current options are : NONE (weight = 1), TSYS, RMS,
    // and WEIGHT (use the weight vector in the sdrecord as is)
    // default is NONE
    Bool setweighting(const String& option);

    // return the current weight state
    String getweighting();

    // set the alignment state
    // current options are : NONE, VELOCITY, XAXIS
    // default is NONE
    Bool setalignment(const String& option);

    // return the current alignment state
    String getalignment();

    // reset rest frequency to match first rest frequence
    // in the average.  This option will be
    // ignored even when set if alignment is not VELOCITY
    Bool dorestshift(Bool torf) {rfshift_p=torf;return True;}

    // return T if the rest frequency shift is ON
    // This option is ignored if the alignment is not VELOCITY.
    Bool restshiftstate() {return rfshift_p;}
    

    // Add the data contained in this SDRecord to the ongoing
    // accumulation.  All input matrices must have the same shape
    // with alignment along the nchannels axis as give by the 
    // alignment state set through other methods.  There is no
    // check currently that the stokes axis is already aligned
    // (it is assumed that it does).  The channel spacing along
    // the frequency axis must be he same as that in the
    // ongoing accumulation.  The internal accumulated data
    // array (the result of the average call) will be resized
    // along the frequency axis as necessary to hold all of the
    // data after alignment.
    // This returns False if the channel spacing does not have the same 
    // value as in the ongoing average, or if the shape of the stokes axis
    // is not the same as that of of the ongoing average.
    Bool accumulate(const SDRecord &sdrecord);

    // accumulte an entire SDIterator using the current weight and
    // alignment state.
    // Returns False if the individual records as applied through
    // accumulate would have returned False
    Bool accumulateIterator(const ObjectID& iterid);

    // Copy the current average into the appropriate fields in the
    // sdrecord argument.  The current accumulation 
    // remains active and additional accum() calls add to the ongoing 
    // averager until the next reset is called.
    // Returns False if there is no ongoing accumulation, the calling
    // argument is left unchanged in that case.
    Bool average(SDRecord &sdrecord);

    // Stuff needed for distributing this class
    virtual String className() const {return "sdaverager";}
    virtual Vector<String> methods() const;
    virtual Vector<String> noTraceMethods() const;

    virtual MethodResult runMethod(uInt which, 
				   ParameterSet &inputRecord,
				   Bool runMethod);
private:
    //# Method enumerations
    enum Methods {CLEAR=0, SETWEIGHTING, GETWEIGHTING, SETALIGNMENT,
		  GETALIGNMENT, DORESTSHIFT, RESTSHIFTSTATE,
		  ACCUMULATE, ACCUMITERATOR,
		  AVERAGE, NUMBER_METHODS};

    //# types of possible axes
    enum AxisTypes {OTHER=0, FREQ, VELO};

    //# types of weighting
    enum WeightTypes {NOWEIGHT=0, RMS, TSYSTIME, WEIGHTVEC};

    //# types of alignment
    enum AlignTypes {NOALIGN=0, VELOCITY, XAXIS};

    Matrix<Float> accumy_p, weight_p;
    Double crpix_p, crpixOrig_p, crval_p, crvalOrig_p, cdelt_p, frest_p;
    Vector<Float> weightedtsys_p, scalarWeight_p;
    Float exposure_p, duration_p;
    String cunit_p, refframe_p, veldef_p;
    LogicalMatrix flag_p;

    //# used in accumulate 
    Vector<Float> thisScalarWeight_p;

    WeightTypes weightType_p;
    AlignTypes alignType_p;
    Bool rfshift_p;

    AxisTypes axisType_p;
    MFrequency::Types freqFrame_p;
    MDoppler::Types velocityDef_p;

    //# these are ONLY used for velocity alignment when the axis is
    //# is FREQ - vrval_p is crval_p expressed as a velocity
    //# and vdelt_p is cdelt_p expressed as a velocity around vrval_p
    Double vrval_p, vdelt_p;

    VelocityMachine *vmach_p;

    FFTServer<Float, Complex> *fftserver_p;
    Vector<Complex> ffttmp_p;
    Matrix<Float> dtmp_p;
    Bool dtmpInUse_p;
    Complex twoPiI_p;

    Unit hzUnit_p, velUnit_p;
};

#endif
