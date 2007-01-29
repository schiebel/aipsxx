//# GaussFitState.h: maintains the state of gaussfit
//# Copyright (C) 1995,1999,2001,2002
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
//# $Id: GaussFitState.h,v 19.5 2004/11/30 17:50:07 ddebonis Exp $

#ifndef APPSGLISH_GAUSSFITSTATE_H
#define APPSGLISH_GAUSSFITSTATE_H


#include <casa/aips.h>
#include <scimath/Fitting/NonLinearFitLM.h>

#include <tasking/Glish/GlishRecord.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>

#include <scimath/Functionals/CompoundFunction.h>
#include <scimath/Functionals/Gaussian1D.h>
#include <scimath/Mathematics/AutoDiff.h>

#include <tasking/Glish/GlishArray.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayMath.h>

#include <casa/namespace.h>
// <summary>
// </summary>

// <use visibility=local> 

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
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>

class GaussFitState
{
public:

    // only the default construct is requried
    GaussFitState() { clear_self(); }

    ~GaussFitState() { ; } // nothing

    // return a reference to the fitter
    NonLinearFitLM<Double> &fitter() {return fitter_p;}

    // return the parameters of the Gaussians
    const Vector<Double> &height() const { return height_p;}
    const Vector<Double> &center() const { return center_p;}
    const Vector<Double> &width() const { return width_p;}

    // the errors in the above
    const Vector<Double> &height_error() const { return hgterr_p;}
    const Vector<Double> &center_error() const { return cnterr_p;}
    const Vector<Double> &width_error() const { return widerr_p;}
    // set the parameters
    void setHeight(const Vector<Double> &h);
    void setCenter(const Vector<Double> &c);
    void setWidth(const Vector<Double> &w);

    uInt maxIter() const { return maxIter_p;}
    void setMaxIter(uInt newMaxIter) { maxIter_p = newMaxIter;}

    Float criteria() const { return criteria_p;}
    void setCriteria (Float newCriteria) { criteria_p = newCriteria;}

    // return all of the state information as a GlishRecord
    GlishRecord state() const;

    // set the state information from a GlishRecord
    void setState(const GlishRecord& rec);

    // returns True if everything is set up fine
    // the only way this will fail is with some problem with
    // the parameters
    Bool setUpFitter();

    // this extracts the state from the fitter
    void getStateFromFitter();

private:

    NonLinearFitLM<Double> fitter_p;

    // these might be considered part of the fitter, but they
    // seem more convenient this way
    Vector<Double> height_p, center_p, width_p;
    Vector<Double> hgterr_p, cnterr_p, widerr_p;

    uInt maxIter_p;
    Float criteria_p;
    

    void clear_self();

    // undefined and inacessable
    GaussFitState(const GaussFitState &other);
    GaussFitState& operator=(const GaussFitState &other);

};


#endif
