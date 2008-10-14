//# FITSField2Fillers.cc: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,2000,2001,2003
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
//# $Id: FITSField2Fillers.cc,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#include <casa/Arrays/ArrayIO.h>
#include <FITSFieldFillers.h>
#include <casa/Utilities/Assert.h>

#include <casa/sstream.h>

#include <casa/namespace.h>
CoordinateWriter::CoordinateWriter(RecordInterface &outRecord, FieldCalculator &calc)
    : calc_p(&calc)
{
    uInt n = calc_p->crval().nelements();
    crval_p.resize(n);
    crpix_p.resize(n);
    cdelt_p.resize(n);
    ctype_p.resize(n);
    cunit_p.resize(n);
    for (uInt i=0; i<n; i++) {
        ostringstream buffer;
	buffer << i+1;
	String num(buffer);
	String name = String("CRVAL") + num;
	crval_p[i] = new RecordFieldPtr<Double>(outRecord, String("CRVAL")+num);
	crpix_p[i] = new RecordFieldPtr<Double>(outRecord, String("CRPIX")+num);
	cdelt_p[i] = new RecordFieldPtr<Double>(outRecord, String("CDELT")+num);
	ctype_p[i] = new RecordFieldPtr<String>(outRecord, String("CTYPE")+num);
	cunit_p[i] = new RecordFieldPtr<String>(outRecord, String("CUNIT")+num);
    }
    equinox_p.attachToRecord(outRecord, String("EQUINOX"));
    radecsys_p.attachToRecord(outRecord, String("RADECSYS"));
    veldef_p.attachToRecord(outRecord, String("VELDEF"));
}

CoordinateWriter::~CoordinateWriter()
{
    uInt n = crval_p.nelements();
    for (uInt i=0; i<n; i++) {
        delete crval_p[i];
	delete crpix_p[i];
	delete cdelt_p[i];
	delete ctype_p[i];
	delete cunit_p[i];
    }
}

void CoordinateWriter::writeField()
{
    uInt n = crval_p.nelements();
    for (uInt i=0; i<n; i++) {
        *(*(crval_p[i])) = calc_p->crval()(i);
	*(*(crpix_p[i])) = calc_p->crpix()(i);
	*(*(cdelt_p[i])) = calc_p->cdelt()(i);
	*(*(ctype_p[i])) = calc_p->ctype()(i);
	*(*(cunit_p[i])) = calc_p->cunit()(i);
    }
    *equinox_p = calc_p->equinox();
    *radecsys_p = calc_p->radecsys();
    *veldef_p = calc_p->veldef();
}

FITSFreqresWriter::FITSFreqresWriter(FieldCalculator &calc, 
				     RecordInterface &outRecord,
				     const String &outField)
    : calc_p(&calc), freqres_p(outRecord, outField)
{
    // Nothing
}

void FITSFreqresWriter::writeField() 
{
    *freqres_p = calc_p->freqres();
}

FITSRestfreqWriter::FITSRestfreqWriter(FieldCalculator &calc, 
				       RecordInterface &outRecord,
				       const String &outField)
    : calc_p(&calc), restfreq_p(outRecord, outField)
{
    // Nothing
}

void FITSRestfreqWriter::writeField() 
{
    *restfreq_p = calc_p->restfreq();
}

FITSTimeWriter::FITSTimeWriter(FieldCalculator &calc, 
			       RecordInterface &outRecord,
			       const String &outField)
    : calc_p(&calc), time_p(outRecord, outField)
{
}

void FITSTimeWriter::writeField()
{
    *time_p = calc_p->timeFrom0HUTInSeconds();
}

FITSAverageTempWriter::FITSAverageTempWriter(FieldCalculator &calc,
					     FieldCalculator::TempType which,
					     RecordInterface &outRecord,
					     const String &outField)
    : calc_p(&calc), which_p(which)
{
    Int fieldnum = outRecord.description().fieldNumber(outField);
    AlwaysAssert(fieldnum >= 0, AipsError);
    ptr_p.attachToRecord(outRecord, outField);
}

void FITSAverageTempWriter::writeField()
{
    *ptr_p = calc_p->averageTemp(which_p);
}


FITSDateObsWriter::FITSDateObsWriter(FieldCalculator &calc, 
				     RecordInterface &outRecord,
				     const String &outField)
    : calc_p(&calc), time_p(outRecord, outField)
{
}

void FITSDateObsWriter::writeField()
{
    *time_p = calc_p->dmy();
}

FITSStringArrayTypeWriter::FITSStringArrayTypeWriter(MSReader &reader, const String &tableName,
						     RecordInterface &outRecord,
						     const String &outField,
						     const RecordInterface &inRecord,
						     const String &inField)
    : itsReader(&reader), tableName(tableName),
      itsInArray(inRecord, inField), itsOutString(outRecord, outField)
{
}

void FITSStringArrayTypeWriter::writeField()
{
    if (itsReader->rowNumber(tableName) >= 0) {
	// okay to use
	ostringstream str;
	str << *itsInArray;
	*itsOutString = String(str);
    } else {
	// default value
	*itsOutString = "";
    }
}

