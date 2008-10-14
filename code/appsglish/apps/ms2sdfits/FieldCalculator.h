//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,2000
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
//# $Id: FieldCalculator.h,v 19.5 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_FIELDCALCULATOR_H
#define APPSGLISH_FIELDCALCULATOR_H

#include <casa/aips.h>

#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>
#include <ms/MeasurementSets/MSReader.h>

namespace casa { //# NAMESPACE CASA - BEGIN
class ROMSMainColumns;
class ROMSPointingColumns;
class ROMSPolarizationColumns;
class ROMSSourceColumns;
class ROMSSpWindowColumns;
class ROMSSysCalColumns;


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
// <todo asof="yyyy/mm/dd">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>

class FieldCalculator {
public:
    enum TempType {TCAL, TRX, TSYS};

    // construct one from an MSReader
    FieldCalculator(MSReader &reader);

    // construct one from another, reference semantics
    FieldCalculator(const FieldCalculator &other);

    // assignment operator, reference semantics
    FieldCalculator &operator=(const FieldCalculator &other);

    ~FieldCalculator();

    const String &dmy() {set(); return itsDMY;}
    Double timeFrom0HUTInSeconds() {set(); return itsTime;}

    Float averageTemp(TempType which);

    Double freqres() {set(); return itsFreqres;}
    
    const Vector<Double> &crval() {set(); return itsCrval;}
    const Vector<Double> &crpix() {set(); return itsCrpix;}
    const Vector<Double> &cdelt() {set(); return itsCdelt;}
    const Vector<String> &ctype() {set(); return itsCtype;}
    const Vector<String> &cunit() {set(); return itsCunit;}

    Double equinox() {return itsEquinox;}
    const String& radecsys() {return itsRadecsys;}

    Double restfreq() {set(); return itsRestfreq;}

    const String &veldef() { return itsVeldef;}

    MSReader &reader() { return *itsReader_p;}
private:
    MSReader *itsReader_p;
    ROMSColumns *itsCols_p;

    Vector<Double> itsCrval, itsCrpix, itsCdelt;
    Vector<String> itsCtype, itsCunit;

    Int itsMainRow, itsSyscalRow, itsSourceRow, itsSpwRow, itsPointRow, itsPolRow;

    Bool itsHasExtraTime, itsHasTsysCol, itsHasTsysFlagCol, itsHasTrxCol,
	itsHasTrxFlagCol, itsHasTcalCol, itsHasTcalFlagCol, itsHasRestfreqCol;

    String itsDMY, itsRadecsys, itsVeldef;
    Double itsTime, itsFreqres, itsRestfreq, itsEquinox;
    Float itsAvgTsys, itsAvgTcal, itsAvgTrx;

    Double getEquinox();
    String fitsFreqType();
    String fitsXPosType();
    String fitsYPosType();

    // calls setInternals, but only when the row numbers have changed
    void set();
    // this is what sets the values
    void setInternals();

    void init();

    void cleanup();

    // undefined and unavailable
    FieldCalculator();
};

// inline set so that its fast when it needs to be.  Assumes that if the main
// row hasn't changed that the sub-table rows are also still okay.
inline void FieldCalculator::set() {
    if (itsReader_p->rowNumber("MAIN") != itsMainRow) setInternals();
}

} //# NAMESPACE CASA - END
#endif
