//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,2000,2003
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
//# $Id: FITSFieldFillers.h,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_FITSFIELDFILLERS_H
#define APPSGLISH_FITSFIELDFILLERS_H

#include <casa/aips.h>
#include <FieldCalculator.h>

#include <casa/Containers/RecordFieldWriter.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class MSReader;
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
// <todo asof="yyyy/mm/dd">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>

class CoordinateWriter : public RecordFieldWriter
{
public:
    CoordinateWriter(RecordInterface &outRecord, FieldCalculator &calc);
    ~CoordinateWriter();
    virtual void writeField();
private:
    FieldCalculator *calc_p;
    PtrBlock<RecordFieldPtr<Double> *> crval_p;
    PtrBlock<RecordFieldPtr<Double> *> crpix_p;
    PtrBlock<RecordFieldPtr<Double> *> cdelt_p;
    PtrBlock<RecordFieldPtr<String> *> ctype_p;
    PtrBlock<RecordFieldPtr<String> *> cunit_p;
    RecordFieldPtr<String> veldef_p;
    RecordFieldPtr<String> radecsys_p;
    RecordFieldPtr<Double> equinox_p;
};



class FITSFreqresWriter : public RecordFieldWriter
{
public:
    FITSFreqresWriter(FieldCalculator &calc, RecordInterface &outRecord,
		      const String &outField);
    virtual void writeField();
private:
    FieldCalculator *calc_p;
    RecordFieldPtr<Double> freqres_p;
};

class FITSRestfreqWriter : public RecordFieldWriter
{
public:
    FITSRestfreqWriter(FieldCalculator &calc, RecordInterface &outRecord,
		       const String &outField);
    virtual void writeField();
private:
    FieldCalculator *calc_p;
    RecordFieldPtr<Double> restfreq_p;
};

class FITSTimeWriter : public RecordFieldWriter
{
public:
    FITSTimeWriter(FieldCalculator &calc, RecordInterface &outRecord,
		   const String &outField);
    virtual void writeField();
private:
    // We should share calc_p among all implementations
    FieldCalculator *calc_p;
    RecordFieldPtr<Double> time_p;
};

class FITSAverageTempWriter : public RecordFieldWriter
{
public:
    FITSAverageTempWriter(FieldCalculator &calc, 
			  FieldCalculator::TempType which,
			  RecordInterface &outRecord, 
			  const String &outField);
    virtual void writeField();
private:
    FieldCalculator *calc_p;
    FieldCalculator::TempType which_p;
    RecordFieldPtr<Float> ptr_p;
};

class FITSDateObsWriter : public RecordFieldWriter
{
public:
    FITSDateObsWriter(FieldCalculator &calc, RecordInterface &outRecord,
		      const String &outField);
    virtual void writeField();
private:
    FieldCalculator *calc_p;
    RecordFieldPtr<String> time_p;
};

class FITSStringArrayTypeWriter : public RecordFieldWriter
{
public:
    FITSStringArrayTypeWriter(MSReader &reader, const String &tableName,
			      RecordInterface &outRecord, const String &outField,
			      const RecordInterface &inRecord, const String &inField);
    virtual void writeField();
private:
    MSReader *itsReader;
    String tableName;
    RORecordFieldPtr<Array<String> > itsInArray;
    RecordFieldPtr<String> itsOutString;
};

template<class outType, class inType>
class FITSScalarWriter : public RecordFieldWriter
{
public:
    FITSScalarWriter(MSReader &reader, const String &tableName,
		     RecordInterface &outRecord, const String &outField,
		     const RecordInterface &inRecord, const String &inField);
    virtual void writeField();
private:
    MSReader *itsReader;
    String tableName;
    RecordFieldPtr<outType> itsOut;
    RORecordFieldPtr<inType> itsIn;
    outType itsDefVal;
};

// outType and inType should be scalar types.

template<class outType, class inType>
class FITSArrayWriter : public RecordFieldWriter
{
public:
    FITSArrayWriter(MSReader &reader, const String &tableName,
		    RecordInterface &outRecord, const String &outField,
		    const RecordInterface &inRecord, const String &inField);
    virtual void writeField();
private:
    MSReader *itsReader;
    String tableName;
    RecordFieldPtr<Array<outType> > itsOut;
    RORecordFieldPtr<Array<inType> > itsIn;
    outType itsDefVal;
};

#endif


