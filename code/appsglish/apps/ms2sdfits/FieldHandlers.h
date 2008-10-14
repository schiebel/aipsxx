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
//# $Id: FieldHandlers.h,v 19.5 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_FIELDHANDLERS_H
#define APPSGLISH_FIELDHANDLERS_H

#include <casa/aips.h>
#include <FieldCalculator.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/Vector.h>

namespace casa { //# NAMESPACE CASA - BEGIN
class RecordDesc;
class RecordInterface;
class MultiRecordFieldWriter;
class MSReader;


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

class RecordFieldHandler
{
public:
  virtual ~RecordFieldHandler();
  virtual void setupFieldHandling(
	  RecordDesc &outputFields, 
	  RecordInterface &outputLengths,
	  RecordInterface &outputUnits,
	  RecordInterface &outputTdims,
	  const RecordDesc &inputFields,
	  const RecordInterface &inputLengths,
	  const RecordInterface &inputUnits,
	  const RecordInterface &inputTdims,
	  Vector<Bool> &handledInputFields) = 0;
    // Must work by name in case the field numbers have been rearranged
    virtual void setupCopiers(MultiRecordFieldWriter &copier,
			      RecordInterface &outRecord,
			      const RecordInterface &inRecord) = 0;
};

class HandleSpecialMainSDFITSFields : public RecordFieldHandler
{
public:
    HandleSpecialMainSDFITSFields(const FieldCalculator &calc);
    virtual void setupFieldHandling(RecordDesc &outputFields, 
				    RecordInterface &outputLengths,
				    RecordInterface &outputUnits,
				    RecordInterface &outputTdims,
				    const RecordDesc &inputFields,
				    const RecordInterface &inputLengths,
				    const RecordInterface &inputUnits,
				    const RecordInterface &inputTdims,
				    Vector<Bool> &handledInputFields);
    // Must work by name in case the field numbers have been rearranged
    virtual void setupCopiers(MultiRecordFieldWriter &copier,
			      RecordInterface &outRecord,
			      const RecordInterface &inRecord);
private:
    FieldCalculator calc_p;
};

class HandleSpecialSysCalSDFITSFields : public RecordFieldHandler
{
public:
    HandleSpecialSysCalSDFITSFields(const FieldCalculator &calc);
    virtual void setupFieldHandling(RecordDesc &outputFields, 
				    RecordInterface &outputLengths,
				    RecordInterface &outputTdims,
				    RecordInterface &outputUnits,
				    const RecordDesc &inputFields,
				    const RecordInterface &inputLengths,
				    const RecordInterface &inputUnits,
				    const RecordInterface &inputTdims,
				    Vector<Bool> &handledInputFields);
    // Must work by name in case the field numbers have been rearranged
    virtual void setupCopiers(MultiRecordFieldWriter &copier,
			      RecordInterface &outRecord,
			      const RecordInterface &inRecord);
private:
    FieldCalculator calc_p;
    Vector<String> names_p;
};

class HandleSpecialSpectralWindowSDFITSFields : public RecordFieldHandler
{
public:
    HandleSpecialSpectralWindowSDFITSFields(const FieldCalculator &calc);
    virtual void setupFieldHandling(RecordDesc &outputFields, 
				    RecordInterface &outputLengths,
				    RecordInterface &outputUnits,
				    RecordInterface &outputTdims,
				    const RecordDesc &inputFields,
				    const RecordInterface &inputLengths,
				    const RecordInterface &inputUnits,
				    const RecordInterface &inputTdims,
				    Vector<Bool> &handledInputFields);
    // Must work by name in case the field numbers have been rearranged
    virtual void setupCopiers(MultiRecordFieldWriter &copier,
			      RecordInterface &outRecord,
			      const RecordInterface &inRecord);
private:
    FieldCalculator calc_p;
};

class HandleSpecialSourceSDFITSFields : public RecordFieldHandler
{
public:
    HandleSpecialSourceSDFITSFields(const FieldCalculator &calc);
    virtual void setupFieldHandling(RecordDesc &outputFields, 
				    RecordInterface &outputLengths,
				    RecordInterface &outputUnits,
				    RecordInterface &outputTdims,
				    const RecordDesc &inputFields,
				    const RecordInterface &inputLengths,
				    const RecordInterface &inputUnits,
				    const RecordInterface &inputTdims,
				    Vector<Bool> &handledInputFields);
    // Must work by name in case the field numbers have been rearranged
    virtual void setupCopiers(MultiRecordFieldWriter &copier,
			      RecordInterface &outRecord,
			      const RecordInterface &inRecord);
private:
    FieldCalculator calc_p;
};

class HandleSpecialObservationSDFITSFields : public RecordFieldHandler
{
public:
    HandleSpecialObservationSDFITSFields(const FieldCalculator &calc);
    virtual void setupFieldHandling(RecordDesc &outputFields, 
				    RecordInterface &outputLengths,
				    RecordInterface &outputUnits,
				    RecordInterface &outputTdims,
				    const RecordDesc &inputFields,
				    const RecordInterface &inputLengths,
				    const RecordInterface &inputUnits,
				    const RecordInterface &inputTdims,
				    Vector<Bool> &handledInputFields);
    // Must work by name in case the field numbers have been rearranged
    virtual void setupCopiers(MultiRecordFieldWriter &copier,
			      RecordInterface &outRecord,
			      const RecordInterface &inRecord);
private:
    FieldCalculator calc_p;
};

class HandleRecordFieldsByBlocking : public RecordFieldHandler
{
public:
    HandleRecordFieldsByBlocking(const Vector<String> blockThese);
    virtual void setupFieldHandling(RecordDesc &outputFields, 
				    RecordInterface &outputLengths,
				    RecordInterface &outputUnits,
				    RecordInterface &outputTdims,
				    const RecordDesc &inputFields,
				    const RecordInterface &inputLengths,
				    const RecordInterface &inputUnits,
				    const RecordInterface &inputTdims,
				    Vector<Bool> &handledInputFields);
    virtual void setupCopiers(MultiRecordFieldWriter &copier,
			      RecordInterface &outRecord,
			      const RecordInterface &inRecord);
private:
    Vector<String> block_these_p;
};

class HandleRecordFieldsByCopying : public RecordFieldHandler
{
public:
    HandleRecordFieldsByCopying(const String &tableName, MSReader &reader);
    virtual void setupFieldHandling(RecordDesc &outputFields, 
				    RecordInterface &outputLengths,
				    RecordInterface &outputUnits,
				    RecordInterface &outputTdims,
				    const RecordDesc &inputFields,
				    const RecordInterface &inputLengths,
				    const RecordInterface &inputUnits,
				    const RecordInterface &inputTdims,
				    Vector<Bool> &isHandledInputFields);
    virtual void setupCopiers(MultiRecordFieldWriter &copier,
			      RecordInterface &outRecord,
			      const RecordInterface &inRecord);
private:
    Vector<String> itsFields;
    String itsPrefix, itsTableName;
    MSReader *itsReader;
};

} //# NAMESPACE CASA - END

#endif


