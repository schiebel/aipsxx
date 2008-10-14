//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997
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
//# $Id: NFieldHandlers.cc,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#include <NFieldHandlers.h>
#include <NFITSFieldFillers.h>

#include <casa/BasicSL/String.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Utilities/Assert.h>

#include <casa/Containers/RecordFieldWriter.h>

#include <casa/namespace.h>
FieldCopier::FieldCopier() 
{
    // Nothing;
}

FieldCopier::~FieldCopier() 
{
    // Nothing;
}

void FieldCopier::clear() 
{
    itsFields.resize(0);
}

void FieldCopier::setupFieldHandling(
    RecordDesc&            outFields, 
    RecordInterface&       outLengths,
    RecordInterface&       outUnits,
    const RecordDesc&      inFields,
    const RecordInterface& inLengths,
    const RecordInterface& inUnits)
{
    //
    // Get the number of input fields and resize the name vector
    // accordingly.
    //
    uInt nrOfFields = inFields.nfields();
    itsFields.resize(nrOfFields);
    
    //
    // Loop through all input fields, and "copy" them to the output
    // record.
    //
    for (uInt i=0; i<nrOfFields; i++) {

	String   fieldName = inFields.name(i);
	DataType fieldType = inFields.type(i);

	//
	// Add the name of the field to the list of fields
	// to be copied. The name must be unique.
	//
	AlwaysAssert(outFields.fieldNumber(fieldName) < 0, AipsError);
	itsFields(i) = fieldName;

	//
	// Add a field to the outFields record description.  Copy the
	// field name, and in principle copy the type and for arrays
	// the shape of the input field.
	//
	// An array of strings will be converted into a scalar string.
	// The shape of an array is taken from the inLength record or
	// straight from the input field description.
	//
	if (isArray(fieldType)) {
	    if (fieldType == TpArrayString) {
		outFields.addField(fieldName, TpString);
	    } else {
		if (inLengths.isDefined(fieldName)) {
		    Vector<Int> shape;
		    inLengths.get(fieldName, shape);
		    outFields.addField(fieldName, fieldType, IPosition(shape));
		} else {
		    outFields.addField(fieldName, fieldType, inFields.shape(i));
		}
	    }
	} else {
	    outFields.addField(fieldName, fieldType);
	}

	//
	// For variable-length fields, add an entry to the
	// outLengths record, containing the name of the output
	// field and its size.
	//
	if (inLengths.isDefined(fieldName)) {
	    //
	    // Get the index number of the inLength field with the
	    // given name, and make sure that that field exists.
	    //
	    Int fieldNum = inLengths.description().fieldNumber(fieldName);
	    AlwaysAssert(fieldNum >=0, AipsError);
	    //
	    // Get the type of the inLength field with that index
	    // number, and make sure that is an (array of) integer(s).
	    //
	    DataType type = inLengths.description().type(fieldNum);
	    AlwaysAssert(type==TpArrayInt || type==TpInt, AipsError);
	    //
	    if (type == TpInt) {
		Int length;
		inLengths.get(fieldNum, length);
		outLengths.define(fieldName, length);
	    } else {
		Vector<Int> shape;
		inLengths.get(fieldNum, shape);
		outLengths.define(fieldName, shape);
	    }
	}

	//
	// If the input field has a unit defined, add it to the
	// outUnits record.
	//
	if (inUnits.isDefined(fieldName)) {
	    outUnits.define(fieldName, inUnits.asString(fieldName));
	}
    }
}

void FieldCopier::setupCopiers(
    MultiRecordFieldWriter& copier,
    RecordInterface&        outRecord,
    const RecordInterface&  inRecord)
{
    RecordDesc outDesc = outRecord.description();
    //
    // Loop by name through the list of fields to be copied.
    //
    for (uInt i=0; i<itsFields.nelements(); i++) {
	String fieldName = itsFields(i);

	Int fieldnum = outDesc.fieldNumber(fieldName);
	AlwaysAssert(fieldnum >= 0, AipsError);

	DataType outType = outDesc.type(fieldnum);
	DataType inType = inRecord.dataType(fieldName);

	//
	// Create the proper RecordFieldWriter for each field.
	//
	RecordFieldWriter* fptr = 0;
	if (inType == TpArrayString) {
	    AlwaysAssert(outType == TpString, AipsError);
	    fptr = new FITSStringArrayTypeWriter(
		outRecord, fieldName, inRecord, fieldName);
	} else {
	    switch (outType) {
	    case TpBool:
		fptr = new RecordFieldCopier<Bool,Bool>(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    case TpUChar:
		fptr = new RecordFieldCopier<uChar,uChar>(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    case TpShort:
		fptr = new RecordFieldCopier<Short,Short>(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    case TpInt:
		fptr = new RecordFieldCopier<Int,Int>(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    case TpFloat:
		fptr = new RecordFieldCopier<Float,Float>(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    case TpDouble:
		fptr = new RecordFieldCopier<Double,Double>(
		    outRecord, fieldName,inRecord, fieldName);
		break;
	    case TpComplex:
		fptr = new RecordFieldCopier<Complex,Complex>(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    case TpDComplex:
		fptr = new RecordFieldCopier<DComplex,DComplex>(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    case TpString:
		fptr = new RecordFieldCopier<String,String>(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    case TpArrayBool:
		fptr = new RecordFieldCopier<Array<Bool>,Array<Bool> >(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    case TpArrayUChar:
		fptr = new RecordFieldCopier<Array<uChar>,Array<uChar> >(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    case TpArrayShort:
		fptr = new RecordFieldCopier<Array<Short>,Array<Short> >(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    case TpArrayInt:
		fptr = new RecordFieldCopier<Array<Int>,Array<Int> >(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    case TpArrayFloat:
		fptr = new RecordFieldCopier<Array<Float>,Array<Float> >(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    case TpArrayDouble:
		fptr = new RecordFieldCopier<Array<Double>,Array<Double> >(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    case TpArrayComplex:
		fptr = new RecordFieldCopier<Array<Complex>,Array<Complex> >(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    case TpArrayDComplex:
		fptr = new RecordFieldCopier<Array<DComplex>,Array<DComplex> >(
		    outRecord, fieldName, inRecord, fieldName);
		break;
	    default:
		throw(AipsError("unhandled type"));
	    }
	}
	AlwaysAssert(fptr, AipsError);
	//
	// Add that writer to the MultiRecordFieldWriter.
	//
	copier.addWriter(fptr);
    }
}

