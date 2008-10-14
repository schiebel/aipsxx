//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,1999,2000,2001
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
//# $Id: FieldHandlers.cc,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#include <casa/BasicSL/String.h>
#include <FieldHandlers.h>
#include <casa/Containers/RecordFieldWriter.h>
#include <FITSFieldFillers.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Utilities/Assert.h>
#include <ms/MeasurementSets/MSReader.h>

#include <casa/namespace.h>
RecordFieldHandler::~RecordFieldHandler()
{
    // Nothing
}

HandleSpecialMainSDFITSFields::HandleSpecialMainSDFITSFields(
					     const FieldCalculator &calc)
    : calc_p(calc)
{
    // Nothing
}

// the inputLengths, inputUnits, and inputTdims parameters are not used by this class
// outputTdims is also not used.
void 
HandleSpecialMainSDFITSFields::setupFieldHandling(RecordDesc &outputFields, 
						  RecordInterface &outputLengths,
						  RecordInterface &outputUnits,
						  RecordInterface &,
						  const RecordDesc &inputFields,
						  const RecordInterface &,
						  const RecordInterface &,
						  const RecordInterface &,
						  Vector<Bool> &handledInputFields)
{
    // all of these are in the MAIN table and the MSReader always points at a
    // valid MAIN table row so no need to check it in this class.

    // TIME
    String name = MS::columnName(MS::TIME);
    Int whichField = inputFields.fieldNumber(name);
    AlwaysAssert(whichField >=0, AipsError);
    outputFields.addField(name, TpDouble);
    outputFields.setComment(outputFields.fieldNumber(name),
			    "UT time of day; UT seconds from 0h UT");
    outputUnits.define(name, "s");
    handledInputFields(whichField) = True;

    // DATE-OBS
    name = "DATE-OBS";
    outputFields.addField(name, TpString);
    outputLengths.define(name, Int(String("yyyy-mm-dd").length()));
    
    // EXPOSURE
    name = MS::columnName(MS::EXPOSURE);
    whichField = inputFields.fieldNumber(name);
    AlwaysAssert(whichField >=0, AipsError);
    handledInputFields(whichField) = True;
    outputFields.addField(name, TpDouble); // Want Double->Float? eventually?
    outputFields.setComment(outputFields.fieldNumber(name),
			    "Effective integration time in seconds");
    outputUnits.define(name, "s");
    
    
    // SCAN_NUMBER -> SCAN
    name = MS::columnName(MS::SCAN_NUMBER);
    whichField = inputFields.fieldNumber(name);
    AlwaysAssert(whichField >=0, AipsError);
    handledInputFields(whichField) = True;
    outputFields.addField("SCAN", TpFloat);
    outputFields.setComment(outputFields.fieldNumber("SCAN"),
			    "Scan number");
}

// Must work by name in case the field numbers have been rearranged
void HandleSpecialMainSDFITSFields::setupCopiers(MultiRecordFieldWriter &copier,
						 RecordInterface &outRecord,
						 const RecordInterface &inRecord)
{
    copier.addWriter(new FITSTimeWriter(calc_p, outRecord,
					MS::columnName(MS::TIME)));
    copier.addWriter(new FITSDateObsWriter(calc_p, outRecord,
					   "DATE-OBS"));
    String name = MS::columnName(MS::EXPOSURE);
    copier.addWriter(new RecordFieldCopier<Double,Double>(outRecord, name, 
							  inRecord, name));
    
    copier.addWriter(new RecordFieldCopier<float, Int>(outRecord, "SCAN",
						       inRecord, MS::columnName(MS::SCAN_NUMBER)));
}

HandleSpecialSysCalSDFITSFields::HandleSpecialSysCalSDFITSFields(const FieldCalculator &calc)
    : calc_p(calc)
{
    // Nothing
}


// the second parameter, outputLengths, is not used by this class
// the parameter outputTdims and inputTdims are not used by this class
void HandleSpecialSysCalSDFITSFields::setupFieldHandling(RecordDesc &outputFields, 
							 RecordInterface &,
							 RecordInterface &outputUnits,
							 RecordInterface &,
							 const RecordDesc &inputFields,
							 const RecordInterface &inputLengths,
							 const RecordInterface &inputUnits,
							 const RecordInterface &,
							 Vector<Bool> &handledInputFields)
{
    // TSYS et al
    {
	// TSYS, TCAL and TRX are optional in input
	// TSYS is required in output
	// find out what is there in input
	String tcalName = MSSysCal::columnName(MSSysCal::TCAL);
	String tsysName = MSSysCal::columnName(MSSysCal::TSYS);
	String trxName = MSSysCal::columnName(MSSysCal::TRX);
	Int tcalId, tsysId, trxId;
	tcalId = inputFields.fieldNumber(tcalName);
	tsysId = inputFields.fieldNumber(tsysName);
	trxId = inputFields.fieldNumber(trxName);
	uInt tCount = 0;
	if (tcalId >= 0) tCount++;
	// this one is for tsys, which is required on output
	tCount++;
	if (trxId >= 0) tCount++;
	names_p.resize(tCount);
	Vector<Int> ids(tCount);
	tCount = 0;
	if (tcalId >= 0) {
	    names_p(tCount) = tcalName;
	    ids(tCount) = tcalId;
	    tCount++;
	}
	// tsys is required on output
	names_p(tCount) = tsysName;
	ids(tCount) = tsysId;
	tCount++;

	if (trxId >= 0) {
	    names_p(tCount) = trxName;
	    ids(tCount) = trxId;
	    tCount++;
	}	
	for (uInt i=0; i<names_p.nelements(); i++) {
	    String name = names_p(i);
	    Int id = ids(i);
	    outputFields.addField(name, TpFloat);
	    if (id >= 0) {
		Vector<Int> tempshape;
		inputLengths.get(name, tempshape);
		// IF we only have one T*, just write it, otherwise we'll
		// also write out SYSCAL_T*
		if (product(abs(tempshape)) == 1) {
		    handledInputFields(id) = True;
		}
		if (inputUnits.isDefined(name)) 
		    outputUnits.define(name, inputUnits.asString(name));
		// Should add the comments
	    } else {
		// this can only happen for TSYS
		outputUnits.define(name, "K");
	    }
	}
    }
}

// the third argument, inRecord, is not used by this class
void 
HandleSpecialSysCalSDFITSFields::setupCopiers(MultiRecordFieldWriter &copier,
					      RecordInterface &outRecord,
					      const RecordInterface &)
{
    // TSYS et al
    {
	for (uInt i=0; i<names_p.nelements(); i++) {
	    FieldCalculator::TempType which;
	    if (names_p(i) == MSSysCal::columnName(MSSysCal::TCAL)) {
		which = FieldCalculator::TCAL;
	    } else if (names_p(i) == MSSysCal::columnName(MSSysCal::TRX)) {
		which = FieldCalculator::TRX;
	    } else {
		which = FieldCalculator::TSYS;
	    }
	    copier.addWriter(new FITSAverageTempWriter(calc_p,
						       which,
						       outRecord,
						       names_p(i)));
	}
    }
}


HandleSpecialSpectralWindowSDFITSFields::HandleSpecialSpectralWindowSDFITSFields(const FieldCalculator &calc) 
    : calc_p(calc) {}

// the inputLengths, inputTdims, outputLengths and outputTdims parameters are not used by this class
void 
HandleSpecialSpectralWindowSDFITSFields::setupFieldHandling(RecordDesc &outputFields, 
							    RecordInterface &,
							    RecordInterface &outputUnits,
							    RecordInterface &,
							    const RecordDesc &inputFields,
							    const RecordInterface &,
							    const RecordInterface &inputUnits,
							    const RecordInterface &,
							    Vector<Bool> &handledInputFields)
{
    // FREQUENCY related
    {
	String inname = MSSpectralWindow::columnName(MSSpectralWindow::TOTAL_BANDWIDTH);
	Int which = inputFields.fieldNumber(inname);
	AlwaysAssert(which >= 0, AipsError);
	handledInputFields(which) = True;
	outputFields.addField("BANDWID", TpDouble);
	if (inputUnits.isDefined(inname)) 
	    outputUnits.define("BANDWID", inputUnits.asString(inname));
	
	inname = MSSpectralWindow::columnName(MSSpectralWindow::RESOLUTION);
	which = inputFields.fieldNumber(inname);
	handledInputFields(which) = True;
	outputFields.addField("FREQRES", TpDouble);
	if (inputUnits.isDefined(inname)) 
	    outputUnits.define("FREQRES", inputUnits.asString(inname));
    }
}

// Must work by name in case the field numbers have been rearranged
void 
HandleSpecialSpectralWindowSDFITSFields::setupCopiers(MultiRecordFieldWriter &copier,
						      RecordInterface &outRecord,
						      const RecordInterface &inRecord)
{
    // FREQUENCY related
    {
	String inname = MSSpectralWindow::columnName(MSSpectralWindow::TOTAL_BANDWIDTH);
	String outname = "BANDWID";
	copier.addWriter(new FITSScalarWriter<Double,Double>(calc_p.reader(), "SPECTRAL_WINDOW",
							     outRecord, outname,
							     inRecord, inname));
	copier.addWriter(new FITSFreqresWriter(calc_p, outRecord, 
					       "FREQRES"));
    }
}

HandleSpecialSourceSDFITSFields::HandleSpecialSourceSDFITSFields(const FieldCalculator &calc) 
    : calc_p(calc) {}

// the inputUnits parameter is not used by this class
// the intputTdims and outputTdims parameters are not used by this class
void 
HandleSpecialSourceSDFITSFields::setupFieldHandling(RecordDesc &outputFields, 
						    RecordInterface &outputLengths,
						    RecordInterface &outputUnits,
						    RecordInterface &,
						    const RecordDesc &inputFields,
						    const RecordInterface &inputLengths,
						    const RecordInterface &inputUnits,
						    const RecordInterface &,
						    Vector<Bool> &handledInputFields)
{
    // SOURCE/NAME -> OBJECT
    String name =   MSSource::columnName(MSSource::NAME);
    Int whichField = inputFields.fieldNumber(name);
    AlwaysAssert(whichField >= 0, AipsError);
    outputFields.addField("OBJECT", TpString);
    handledInputFields(whichField) = True;
    if (inputLengths.isDefined(name)) {
	Int size;
	inputLengths.get(name, size);
	outputLengths.define("OBJECT", size);
    }

    // REST_FREQUENCY is optional
    name = MSSource::columnName(MSSource::REST_FREQUENCY);
    if (inputFields.fieldNumber(name) >= 0) {
	// don't mark this as handled, since there may be more than one REST_FREQUENCY
	outputFields.addField("RESTFREQ", TpDouble);
	if (inputUnits.isDefined(name))
	    outputUnits.define("RESTFREQ", inputUnits.asString(name));
    }
}

void 
HandleSpecialSourceSDFITSFields::setupCopiers(MultiRecordFieldWriter &copier,
					      RecordInterface &outRecord,
					      const RecordInterface &inRecord)
{
    // SOURCE/NAME -> OBJECT
    copier.addWriter(new FITSScalarWriter<String,String>(calc_p.reader(), "SOURCE",
							 outRecord, "OBJECT",
							 inRecord,
							 MSSource::columnName(MSSource::NAME)));
    // RESTFREQ is optional, may not be there
    if (outRecord.isDefined("RESTFREQ")) {
	copier.addWriter(new FITSRestfreqWriter(calc_p, outRecord, "RESTFREQ"));
    }
}

HandleSpecialObservationSDFITSFields::HandleSpecialObservationSDFITSFields(const FieldCalculator &calc) 
    : calc_p(calc) {}

// the outputUnits and inputUnits parameters are not used by this class
// the outputTdims and inputTdims parameters are not used by this class
void 
HandleSpecialObservationSDFITSFields::setupFieldHandling(RecordDesc &outputFields, 
							 RecordInterface &outputLengths,
							 RecordInterface &,
							 RecordInterface &,
							 const RecordDesc &inputFields,
							 const RecordInterface &inputLengths,
							 const RecordInterface &,
							 const RecordInterface &,
							 Vector<Bool> &handledInputFields)
{
    // TELESCOPE_NAME -> TELESCOP
    String name =   MSObservation::columnName(MSObservation::TELESCOPE_NAME);
    Int whichField = inputFields.fieldNumber(name);
    AlwaysAssert(whichField >= 0, AipsError);
    outputFields.addField("TELESCOP", TpString);
    handledInputFields(whichField) = True;
    if (inputLengths.isDefined(name)) {
	Int size;
	inputLengths.get(name, size);
	outputLengths.define("TELESCOP", size);
    }
    
    // OBSERVATION/OBSERVER -> OBSERVER
    name =   MSObservation::columnName(MSObservation::OBSERVER);
    whichField = inputFields.fieldNumber(name);
    AlwaysAssert(whichField >= 0, AipsError);
    outputFields.addField("OBSERVER", TpString);
    handledInputFields(whichField) = True;
    if (inputLengths.isDefined(name)) {
	Int size;
	inputLengths.get(name, size);
	outputLengths.define("OBSERVER", size);
    }
    // OBSERVATION/PROJECT -> PROJID
    name =   MSObservation::columnName(MSObservation::PROJECT);
    whichField = inputFields.fieldNumber(name);
    AlwaysAssert(whichField >= 0, AipsError);
    outputFields.addField("PROJID", TpString);
    handledInputFields(whichField) = True;
    if (inputLengths.isDefined(name)) {
	Int size;
	inputLengths.get(name, size);
	outputLengths.define("PROJID", size);
    }
}

void 
HandleSpecialObservationSDFITSFields::setupCopiers(MultiRecordFieldWriter &copier,
						   RecordInterface &outRecord,
						   const RecordInterface &inRecord)
{
    // TELESCOPE_NAME -> TELESCOP
    copier.addWriter(new FITSScalarWriter<String,String>(calc_p.reader(), "OBSERVATION",
							 outRecord, "TELESCOP",
							 inRecord,
							 MSObservation::columnName(MSObservation::TELESCOPE_NAME)));
    
    // OBSERVATION/OBSERVER -> OBSERVER
    copier.addWriter(new FITSScalarWriter<String,String>(calc_p.reader(), "OBSERVATION",
							 outRecord, "OBSERVER",
							 inRecord,
							 MSObservation::columnName(MSObservation::OBSERVER)));
    // OBSERVATION/PROJECT -> PROJID
    copier.addWriter(new FITSScalarWriter<String,String>(calc_p.reader(), "OBSERVATION",
							 outRecord, "PROJID",
							 inRecord,
							 MSObservation::columnName(MSObservation::PROJECT)));
}

HandleRecordFieldsByBlocking::HandleRecordFieldsByBlocking(const Vector<String> blockThese)
    : block_these_p(blockThese.copy()) {}

// the following parameters are not used by this class:
//    outputFields, outputLengths, outputUnits, outputTdims, inputLengths, inputUnits, inputTdims
void HandleRecordFieldsByBlocking::setupFieldHandling(RecordDesc &, RecordInterface &, RecordInterface &,
						      RecordInterface &, const RecordDesc &inputFields,
						      const RecordInterface &, const RecordInterface &,
						      const RecordInterface &, Vector<Bool> &handledInputFields)
{
    Int nfields = inputFields.nfields();
    AlwaysAssertExit(Int(handledInputFields.nelements()) == nfields);
    uInt nblockers = block_these_p.nelements();
    for (uInt i=0; i<nblockers; i++) {
	Int where = inputFields.fieldNumber(block_these_p(i));
	if (where >= 0) {
	    AlwaysAssert(where < nfields, AipsError);
	    handledInputFields(where) = True;
	}
    }
}

// nothing to be done here, no parameters to pass
void 
HandleRecordFieldsByBlocking::setupCopiers(MultiRecordFieldWriter &,
					   RecordInterface &,
					   const RecordInterface &)
{
}

HandleRecordFieldsByCopying::HandleRecordFieldsByCopying(const String &tableName,
							 MSReader &reader) 
    : itsPrefix(tableName+"_"), itsTableName(tableName), itsReader(&reader)
{}

void 
HandleRecordFieldsByCopying::setupFieldHandling(RecordDesc &outputFields, 
						RecordInterface &outputLengths,
						RecordInterface &outputUnits,
						RecordInterface &outputTdims,
						const RecordDesc &inputFields,
						const RecordInterface &inputLengths,
						const RecordInterface &inputUnits,
						const RecordInterface &inputTdims,
						Vector<Bool> &isHandledInputFields)
{
    uInt nfields = inputFields.nfields();
    AlwaysAssert(nfields == isHandledInputFields.nelements(),  AipsError);
    for (uInt i=0; i<nfields; i++) {
	// quadratic - would be more efficient to resize less often
	DataType type = inputFields.type(i);
	if (! isHandledInputFields(i)) {
	    isHandledInputFields(i) = True;
	    uInt which = itsFields.nelements();
	    itsFields.resize(which+1,True);
	    String inname = inputFields.name(i);
	    String outname = itsPrefix + inname;
	    itsFields(which) = inname;
	    AlwaysAssert(outputFields.fieldNumber(outname) < 0, AipsError);
	    if (isArray(type)) {
		if (type == TpArrayString) {
		    outputFields.addField(outname, TpString);
		    if (inputLengths.isDefined(inname)) {
			Int fieldNum = inputLengths.description().fieldNumber(inname);
			AlwaysAssert(fieldNum >=0, AipsError);
			DataType type = inputLengths.description().type(fieldNum);
			AlwaysAssert(type==TpArrayInt || type==TpInt, AipsError);
			if (type == TpInt) {
			    Int length;
			    inputLengths.get(fieldNum, length);
			    outputLengths.define(outname, length);
			} else {
			    Vector<Int> shape;
			    inputLengths.get(fieldNum, shape);
			    outputLengths.define(outname, shape);
			}
		    }			
		} else {
		    if (inputLengths.isDefined(inname)) {
			Vector<Int> shape;
			inputLengths.get(inname, shape);
			// variable shaped?
			if (anyLT(shape, 0)) {
			    AlwaysAssert(inputTdims.fieldNumber(inname)>=0, AipsError);
			    outputFields.addField(outname, type);
			    outputLengths.define(outname, abs(product(shape)));
			    outputTdims.define(outname, inputTdims.asString(inname));
			} else {
			    // fixed shape
			    outputFields.addField(outname, type, IPosition(shape));
			}
		    } else {
			outputFields.addField(outname, type, inputFields.shape(i));
		    }
		}
	    } else {
		outputFields.addField(outname, type);
	    }
	    if (inputUnits.isDefined(inname)) {
		outputUnits.define(outname, inputUnits.asString(inname));
	    }
	}
    }
}

void 
HandleRecordFieldsByCopying::setupCopiers(MultiRecordFieldWriter &copier,
					  RecordInterface &outRecord,
					  const RecordInterface &inRecord)
{
    RecordDesc outdesc = outRecord.description();
    for (uInt i=0; i<itsFields.nelements(); i++) {
	String inname = itsFields(i);
	String outname = itsPrefix + inname;
	Int fieldnum = outdesc.fieldNumber(outname);
	AlwaysAssert(fieldnum >= 0, AipsError);
	DataType type = outdesc.type(fieldnum);
	DataType intype = inRecord.dataType(inname);
	RecordFieldWriter *fptr = 0;

	if (intype == TpArrayString) {
	    AlwaysAssert(type == TpString, AipsError);
	    fptr = new FITSStringArrayTypeWriter(*itsReader, itsTableName, outRecord, outname, inRecord, inname);
	} else {
	    switch (type) {
	    case TpBool:
		fptr = new FITSScalarWriter<Bool,Bool>(*itsReader, itsTableName, 
						       outRecord, outname, inRecord, inname);
		break;
	    case TpUChar:
		fptr = new FITSScalarWriter<uChar,uChar>(*itsReader, itsTableName, 
							 outRecord, outname, inRecord, inname);
		break;
	    case TpShort:
		fptr = new FITSScalarWriter<Short,Short>(*itsReader, itsTableName, 
							 outRecord, outname, inRecord, inname);
		break;
	    case TpInt:
		fptr = new FITSScalarWriter<Int,Int>(*itsReader, itsTableName, 
						     outRecord, outname, inRecord, inname);
		break;
	    case TpFloat:
		fptr = new FITSScalarWriter<Float,Float>(*itsReader, itsTableName, 
							 outRecord, outname, inRecord, inname);
		break;
	    case TpDouble:
		fptr = new FITSScalarWriter<Double,Double>(*itsReader, itsTableName, 
							   outRecord, outname, inRecord, inname);
		break;
	    case TpComplex:
		fptr = new FITSScalarWriter<Complex,Complex>(*itsReader, itsTableName, 
							     outRecord, outname, 
							      inRecord, inname);
		break;
	    case TpDComplex:
		fptr = new FITSScalarWriter<DComplex,DComplex>(*itsReader, itsTableName, 
							       outRecord, outname, 
								inRecord, inname);
		break;
	    case TpString:
		fptr = new FITSScalarWriter<String,String>(*itsReader, itsTableName, 
							   outRecord, outname, inRecord, inname);
		break;
	    case TpArrayBool:
		fptr = new FITSArrayWriter<Bool,Bool>(*itsReader, itsTableName, 
						      outRecord, outname, 
						      inRecord, inname);
		break;
	    case TpArrayUChar:
		fptr = new FITSArrayWriter<uChar, uChar>(*itsReader, itsTableName, 
							 outRecord, outname, 
							 inRecord, inname);
		break;
	    case TpArrayShort:
		fptr = new FITSArrayWriter<Short, Short>(*itsReader, itsTableName, 
							 outRecord, outname,
							 inRecord, inname);
		break;
	    case TpArrayInt:
		fptr = new FITSArrayWriter<Int, Int>(*itsReader, itsTableName, 
						     outRecord, outname,
						     inRecord, inname);
		break;
	    case TpArrayFloat:
		fptr = new FITSArrayWriter<Float, Float>(*itsReader, itsTableName, 
							 outRecord, outname, 
							 inRecord, inname);
		break;
	    case TpArrayDouble:
		fptr = new FITSArrayWriter<Double, Double>(*itsReader, itsTableName, 
							   outRecord, outname, 
							   inRecord, inname);
		break;
	    case TpArrayComplex:
		fptr = new FITSArrayWriter<Complex, Complex>(*itsReader, itsTableName, 
							     outRecord, outname,
							     inRecord, inname);
		break;
	    case TpArrayDComplex:
		fptr = new FITSArrayWriter<DComplex, DComplex>(*itsReader, itsTableName, 
							       outRecord, outname, 
							       inRecord, inname);
		break;
	    default:
		throw(AipsError("unhandled type"));
	    }
	}
	AlwaysAssert(fptr, AipsError);
	copier.addWriter(fptr);
    }
}
