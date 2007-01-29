//# uni2sdfits.cc - convert a UniPOPS FITS to an SD-FITS file
//# Copyright (C) 1999,2000,2001,2002
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: uni2sdfits.cc,v 19.5 2004/11/30 17:50:09 ddebonis Exp $

//# Includes

#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/Vector.h>
#include <casa/Containers/Block.h>
#include <casa/BasicMath/Math.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/Regex.h>

#include <casa/Inputs/Input.h>
#include <casa/Exceptions/Error.h>
#include <casa/OS/File.h>

#include <fits/FITS/fits.h>
#include <fits/FITS/fitsio.h>
#include <fits/FITS/hdu.h>

#include <casa/iostream.h>
#include <casa/sstream.h>
#include <casa/stdlib.h>
#include <casa/stdio.h>

#include <casa/namespace.h>
// forward declarations on functions used here

void scanHDUs(FitsInput &fitsin, Block<String> &dataShapes);
void copyAndFixHDU(FitsInput &fitsin, FitsOutput &fitsout, const String &dataShape);
void modifyVColName(FitsKeywordList &kwl, const String &oldname, 
		    const String &newname);
String makeShape(const Vector<Int> &intShape);
String intToString(Int value);
void removeColumn(int colNumber, FitsKeywordList &kwl);
void incColNumber(Int startAt, Int incr, FitsKeywordList &kwl);

int main(int argc, char **argv)
{
    try {
	Input inputs(1);

	inputs.create("input",
		      "",
		      "The input UniPOPOS FITS file",
		      "String");
	inputs.create("output",
		      "",
		      "The ouput SD FITS file",
		      "String");

	inputs.readArguments(argc, argv);

	String inputFilename = inputs.getString("input");
	String outputFilename = inputs.getString("output");

	File inputFile(inputFilename);
	if (!inputFile.isReadable()) {
	    cerr << inputFilename << " is not readable - exiting" << endl;
	    return 1;
	}

	File outputFile(outputFilename);
	if (outputFile.exists()) {
	    cerr << outputFilename << " already exists - exiting" << endl;
	    return 1;
	}
	if (!outputFile.canCreate()) {
	    cerr << outputFilename << " can not be created - exiting" << endl;
	    return 1;
	}
	// open the existing file
	FitsInput *fitsinp = new FitsInput(inputFile.path().absoluteName().chars(),
					   FITS::Disk);
	AlwaysAssert(fitsinp, AipsError);
	if (fitsinp->err()) {
	    cerr << "There was a problem opening the input fits file : "
		 << inputFilename << endl;
	    cerr << "The error code was : " << fitsinp->err() << endl;
	}
	// scan all of the HDUs looking for non-const shapes
	cout << "\nScanning all HDUs looking for any non-constant DATA column shapes" << endl;
	Block<String> dataShapes(1);
	scanHDUs(*fitsinp, dataShapes);
	delete fitsinp;
	fitsinp = 0;

	// re-open the existing file
	FitsInput fitsin(inputFile.path().absoluteName().chars(),
			 FITS::Disk);
	if (fitsin.err()) {
	    cerr << "There was a problem opening the input fits file : "
		 << inputFilename << endl;
	    cerr << "The error code was : " << fitsin.err() << endl;
	}
	// open the output file
	FitsOutput fitsout(outputFile.path().absoluteName().chars(),
			   FITS::Disk);
	if (fitsout.err()) {
	    cerr << "There was a problem opening the output fits file : "
		 << outputFilename << endl;
	    cerr << "The error code was : " << fitsout.err() << endl;
	}

	// copy over the primary HDU
	cout << "Primary HDU" << endl;
	copyAndFixHDU(fitsin, fitsout, dataShapes[0]);

	// step through the remaining HDUs and and copy them one by one
	Int count = 1;
	while (!fitsin.eof()) {
	    cout << "HDU # " << count << endl;
	    copyAndFixHDU(fitsin, fitsout, dataShapes[count]);
	    count++;
	}

	cout << "done." << endl;
    } catch (AipsError x) {
	cout << "Exception: "  << x.getMesg() << endl;
	return 1;
    } 
    return 0;
}

// if dataShape has any length, use it as the shape for the DATA column
// and ignore any other shape information here - we've prescanned the HDU
// for this information so we can trust this
void copyAndFixHDU(FitsInput &fitsin, FitsOutput &fitsout, const String &dataShape)
{
    // switch on type
    if (fitsin.rectype() != FITS::HDURecord) {
	cerr << "Invalid record in input FITS file" << endl;
	exit(1);
    }

    switch (fitsin.hdutype()) {
    case FITS::PrimaryArrayHDU:
	// switch on data type
	// these could be templated
	switch (fitsin.datatype()) {
	case FITS::BYTE:
	    {
		BytePrimaryArray inpa(fitsin);
		// construct the output one from inpa's keywords
		FitsKeywordList kwl(inpa.kwlist());
		BytePrimaryArray outpa(kwl);
		outpa.write_hdr(fitsout);
		// how many elements to copy
		uInt ntocopy = inpa.nelements();
		// how many per call, this is arbitrary and possibly
		// too conservative
		uInt npercall = min(uInt(32768), ntocopy);
		unsigned char *buf;
		buf = new unsigned char(ntocopy);
		AlwaysAssert(buf, AipsError);
		while (ntocopy > 0) {
		    npercall = min(npercall, ntocopy);
		    inpa.read(npercall);
		    inpa.move(buf, npercall);
		    outpa.store(buf, npercall);
		    outpa.write(fitsout);
		    ntocopy -= npercall;
		}
		delete buf;
	    }
	    break;
	case FITS::SHORT:
	    {
		ShortPrimaryArray inpa(fitsin);
		// construct the output one from inpa's keywords
		FitsKeywordList kwl(inpa.kwlist());
		ShortPrimaryArray outpa(kwl);
		outpa.write_hdr(fitsout);
		// how many elements to copy
		uInt ntocopy = inpa.nelements();
		// how many per call, this is arbitrary and possibly
		// too conservative
		uInt npercall = min(uInt(32768), ntocopy);
		short *buf;
		buf = new short(ntocopy);
		AlwaysAssert(buf, AipsError);
		while (ntocopy > 0) {
		    npercall = min(npercall, ntocopy);
		    inpa.read(npercall);
		    inpa.move(buf, npercall);
		    outpa.store(buf, npercall);
		    outpa.write(fitsout);
		    ntocopy -= npercall;
		}
		delete buf;
	    }
	    break;
	case FITS::LONG:
	    {
		LongPrimaryArray inpa(fitsin);
		// construct the output one from inpa's keywords
		FitsKeywordList kwl(inpa.kwlist());
		LongPrimaryArray outpa(kwl);
		// how many elements to copy
		uInt ntocopy = inpa.nelements();
		// how many per call, this is arbitrary and possibly
		// too conservative
		uInt npercall = min(uInt(32768), ntocopy);
		FitsLong *buf;
		buf = new FitsLong(ntocopy);
		AlwaysAssert(buf, AipsError);
		while (ntocopy > 0) {
		    npercall = min(npercall, ntocopy);
		    inpa.read(npercall);
		    inpa.move(buf, npercall);
		    outpa.store(buf, npercall);
		    outpa.write(fitsout);
		    ntocopy -= npercall;
		}
		delete buf;
	    }
	    break;
	case FITS::FLOAT:
	    {
		FloatPrimaryArray inpa(fitsin);
		// construct the output one from inpa's keywords
		FitsKeywordList kwl(inpa.kwlist());
		FloatPrimaryArray outpa(kwl);
		outpa.write_hdr(fitsout);
		// how many elements to copy
		uInt ntocopy = inpa.nelements();
		// how many per call, this is arbitrary and possibly
		// too conservative
		uInt npercall = min(uInt(32768), ntocopy);
		float *buf;
		buf = new float(ntocopy);
		AlwaysAssert(buf, AipsError);
		while (ntocopy > 0) {
		    npercall = min(npercall, ntocopy);
		    inpa.read(npercall);
		    inpa.move(buf, npercall);
		    outpa.store(buf, npercall);
		    outpa.write(fitsout);
		    ntocopy -= npercall;
		}
		delete buf;
	    }
	    break;
	case FITS::DOUBLE:
	    {
		DoublePrimaryArray inpa(fitsin);
		// construct the output one from inpa's keywords
		FitsKeywordList kwl(inpa.kwlist());
		DoublePrimaryArray outpa(kwl);
		outpa.write_hdr(fitsout);
		// how many elements to copy
		uInt ntocopy = inpa.nelements();
		// how many per call, this is arbitrary and possibly
		// too conservative
		uInt npercall = min(uInt(32768), ntocopy);
		double *buf;
		buf = new double(ntocopy);
		AlwaysAssert(buf, AipsError);
		while (ntocopy > 0) {
		    npercall = min(npercall, ntocopy);
		    inpa.read(npercall);
		    inpa.move(buf, npercall);
		    outpa.store(buf, npercall);
		    ntocopy -= npercall;
		}
		delete buf;
	    }
	    break;
	default:
	    // this should never happen
	    cerr << "Invalid data type of primary HDU" << endl;
	    exit(1);
	    break;
	}
	break;
    case FITS::PrimaryGroupHDU:
    case FITS::ImageExtensionHDU:
    case FITS::AsciiTableHDU:
	cout << "Not implemented yet" << endl;
	break;
    case FITS::BinaryTableHDU:
	{
	    // most of this would work for AsciiTableHDU as well
	    BinaryTableExtension inbt(fitsin);
	    // construct the output one from inbt's keywords
	    FitsKeywordList kwl(inbt.kwlist());
	    FitsKeyword *extn = kwl(FITS::EXTNAME);
	    AlwaysAssert(extn, AipsError);
	    String extname(extn->asString());
	    if (extname != "UNIPOPS SNGLE DISH") {
		cerr << "Warning: this is not a UniPOPS generated FITS file ..." << endl;
		cerr << "   This conversion may not be valid." << endl;
	    }
	    *extn = "SINGLE DISH";
	    extn->comm("Converted using aips++ uni2sdfits");

	    // first, rename the problem virtual column names
	    modifyVColName(kwl, "SERIES", "DATA");
	    modifyVColName(kwl, "SPECTRUM", "DATA");
	    modifyVColName(kwl, "BANDWIDT", "BANDWID");
	    modifyVColName(kwl, "PROJECT", "PROJID");
	    modifyVColName(kwl, "VELOCITY", "VFRAME");
	    modifyVColName(kwl, "VCORR", "RVSYS");
	    modifyVColName(kwl, "TOUTSIDE", "TAMBIENT");
	    modifyVColName(kwl, "BEAMWIDT", "BMAJ");

	    // remove the NMATRIX keyword
	    if (kwl("NMATRIX")) {
		kwl.del();
		cout << "NMATRIX keyword removed" << endl;
	    }

	    // at this point, we need to possibly redo the shape
	    Bool hasTDIMColumn = dataShape.length() == 0;
	    Int tdimCol = -1;
	    Int tdimLen = 0;
	    Vector<Int> maxes;
	    Block<void *> maxisFields;
	    Vector<Int> colmap(inbt.ncols());
	    indgen(colmap);
	    if (!hasTDIMColumn) {
		// we can trust this shape, just remove any MAXIS keywords and columns
		// and make sure the TDIM kw is there on the DATA column
		// and that it has the right shape
		// search for any MAXIS keywords
		FitsKeyword *maxisKW = kwl("MAXIS");
		if (maxisKW) {
		    Int nmaxis = maxisKW->asInt();
		    // delete the MAXIS keyword
		    kwl.del();
		    cout << "MAXIS keyword removed" << endl;
		    for (uInt i=0;Int(i)<nmaxis;i++) {
			String maxisStr = "MAXIS" + intToString(i+1);
			maxisKW = kwl(maxisStr.chars());
			if (maxisKW) {
			    // delete this keyword
			    kwl.del();
			    cout << maxisStr << " keyword removed" << endl;
			}
		    }
		    Regex maxisReg("^MAXIS[0-9]?[ ]*$");
		    for (uInt i=0;Int(i)<inbt.ncols();i++) {
			String colname(inbt.ttype(i));
			if (colname.matches(maxisReg)) {
			    // and mark this column for deletion
			    colmap(i) = -1;
			} 
		    }

		    // remove any deleted columns, start from the end
		    // this doesn't move the heap at all.
		    for (Int i=(colmap.nelements()-1);i>=0;i--) {
			if (colmap(i) < 0) {
			    cout << "Removing column " << (i+1) << " : " 
				 << inbt.ttype(i) << endl;
			    removeColumn((i+1), kwl);
			}
		    }
		    // once more through colmap, to renumber things
		    Int removed=0;
		    for (uInt i=0;i<colmap.nelements();i++) {
			if (colmap(i) < 0) {
			    removed++;
			} else {
			    colmap(i) -= removed;
			}
		    }
		}
		// Ensure that the current value of the TDIM associated with
		// the DATA column has the right value
		kwl.first();
		FitsKeyword *kw = kwl.curr();
		while (kw) {
		    if (kw->isreserved() && kw->kw().name() == FITS::TTYPE) {
			String kwval(kw->asString());
			if (kwval.matches(Regex("^DATA *$"))) break;
		    }
		    kw = kwl.next();
		}
		if (!kw) {
		    cerr << "No DATA column" << endl;
		    exit(1);
		}
		Int index = kw->index();
		kwl.first();
		kw = kwl(FITS::TDIM, index);
		if (kw) {
		    // set the value
		    (*kw) = dataShape.chars();
		    cout << "keyword value set: " << kw->name() << kw->index()
			 << " = " << kw->asString() << endl;
		} else {
		    // insert the keyword, find DATA all over again
		    kwl.first();
		    kw = kwl.curr();
		    while (kw) {
			if (kw->isreserved() && kw->kw().name() == FITS::TTYPE) {
			    String kwval(kw->asString());
			    if (kwval.matches(Regex("^DATA *$"))) break;
			}
			kw = kwl.next();
		    }
		    kwl.mk(kw->index(), FITS::TDIM, dataShape.chars());
		    cout << "inserted : " << kwl.curr()->name() << kwl.curr()->index()
			 << " = " << kwl.curr()->asString() << endl;
		}
	    } else {
		// variable shaped DATA column
		// search for any MAXIS keywords
		FitsKeyword *maxisKW = kwl("MAXIS");
		if (maxisKW) {
		    maxes.resize(maxisKW->asInt());
		    maxes = 0;
		    maxisFields.resize(maxes.nelements());
		    maxisFields = static_cast<void *>(0);
		    // delete the MAXIS keyword
		    cout << "MAXIS keyword removed" << endl;
		    kwl.del();
		    for (uInt  i=0;i<maxes.nelements();i++) {
			String maxisStr = "MAXIS" + intToString(i+1);
			maxisKW = kwl(maxisStr.chars());
			if (maxisKW) {
			    maxes(i) = maxisKW->asInt();
			    // and delete this keyword, now that we have it
			    kwl.del();
			    cout << maxisStr << " keyword removed" << endl;
			}
		    }
		    Regex maxisReg("^MAXIS[0-9]?[ ]*$");
		    for (uInt i=0;Int(i)<inbt.ncols();i++) {
			String colname(inbt.ttype(i));
			if (colname.matches(maxisReg)) {
			    String axisStr = colname.from(RXint);
			    Int axisNum = atoi(axisStr.chars()) - 1;
			    maxisFields[axisNum] = (void *)(new FitsField<short>);
			    AlwaysAssert(maxisFields[axisNum], AipsError);
			    inbt.bind(i, *(FitsField<short> *)(maxisFields[axisNum]));
			    // and mark this column for deletion
			    colmap(i) = -1;
			} 
		    }

		    // remove any deleted columns, start from the end
		    // this doesn't move the heap at all.
		    for (Int i=(colmap.nelements()-1);i>=0;i--) {
			if (colmap(i) < 0) {
			    cout << "Removing column " << (i+1) << " : " 
				 << inbt.ttype(i) << endl;
			    removeColumn((i+1), kwl);
			}
		    }
		    // once more through colmap, to renumber things
		    Int removed=0;
		    for (uInt i=0;i<colmap.nelements();i++) {
			if (colmap(i) < 0) {
			    removed++;
			} else {
			    colmap(i) -= removed;
			}
		    }
		    // now add in the tdim column and bind its field
		    // we need to guess at a length
		    // Data from unipops is never more that 16384 elements long.
		    // Make that the max value along any variable shaped axes.
		    // This isn't great, but given that we can't pre-scan the 
		    // data here, its the best that can be done
		    for (uInt i=0;i<maxes.nelements();i++) {
			if (maxes(i) <= 0) maxes(i) = 16384;
		    }
		    // allow one space at end for good measure
		    tdimLen = makeShape(maxes).length() + 1;
		    // find the DATA column
		    kwl.first();
		    FitsKeyword *kw = kwl.curr();
		    while (kw) {
			if (kw->isreserved() && kw->kw().name() == FITS::TTYPE) {
			    String kwval(kw->asString());
			    if (kwval.matches(Regex("^DATA *$"))) break;
			}
			kw = kwl.next();
		    }
		    if (!kw) {
			cerr << "No DATA column" << endl;
			exit(1);
		    }
		    tdimCol = kw->index()+1;
		    // is there a TDIM kw associated with this column
		    kwl.first();
		    FitsKeyword *tdkw = kwl(FITS::TDIM, kw->index());
		    // delete it if its there, the above fn moved the
		    // pointer to this keyword, if it exists
		    if (tdkw) {
			cout << "Removing keyword : " 
			     << tdkw->kw().aname() 
			     << tdkw->index() << endl;
			kwl.del();
		    }
		      
		    // renumber anything from the new tdimCol position and up
		    incColNumber(tdimCol, 1, kwl);
		    
		    // first, find first index table keyword with index > tdimCol
		    // this assumes that the column information is sequential
		    kwl.first();
		    kw = kwl.curr();
		    Regex stdTcolReg("^T[A-Z]?.*$");
		    while (kw) {
			if (kw->isreserved() && kw->isindexed()) {
			    String kwname(kw->name());
			    if (kwname.matches(stdTcolReg) &&
				kw->index() > tdimCol) break;
			}
			kw = kwl.next();
		    }
		    if (!kw) {
			// oops, too far, back up before the END 
			kwl.prev();
		    }
		    // okay, insert the column right before this one
		    String tmp = "TDIM" + intToString(tdimCol-1);
		    kwl.mk(tdimCol, FITS::TTYPE, tmp.chars());
		    cout << "inserted : " << kwl.curr()->name() << kwl.curr()->index()
			 << " = " << kwl.curr()->asString() << endl;
		    tmp = intToString(tdimLen) + "A";
		    kwl.mk(tdimCol, FITS::TFORM, tmp.chars());
		    cout << "           " << kwl.curr()->name() << kwl.curr()->index()
			 << " = " << kwl.curr()->asString() << endl;
		    // and update NAXES and TFIELDS
		    kwl.first();
		    kw = kwl(FITS::NAXIS, 1);
		    AlwaysAssert(kw, AipsError);
		    *kw = kw->asInt() + tdimLen;
		    kw = kwl(FITS::TFIELDS);
		    AlwaysAssert(kw, AipsError);
		    *kw = kw->asInt() + 1;
		    kwl.first();
		    kw = kwl.curr();
		} 
	    }


	    BinaryTableExtension outbt(kwl);
	    outbt.write_hdr(fitsout);

	    FitsField<char> tdimField(tdimLen);
	    if (tdimCol > 0) outbt.bind((tdimCol-1), tdimField);

	    // do it one row at a time
	    for (Int i=0; i<inbt.nrows(); i++) {
		inbt.read(1);
		// get the shape of this row
		for (uInt j=0;j<maxes.nelements();j++) {
		    if (maxisFields[j]) {
			maxes(j) = (*(FitsField<short> *)(maxisFields[j]))();
		    }
		}
		// copy the columns one at a time
		outbt.set_next(1);
		for (Int j=0; j<inbt.ncols(); j++) {
		    if (colmap(j) >= 0) {
			outbt.field(colmap(j)) = inbt.field(j);
		    } 
		}
		if (tdimCol > 0) {
		    String shape = makeShape(maxes);
		    char *cptr = (char *)tdimField.data();
		    for (uInt j=0;j<shape.length();j++) {
			cptr[j] = shape.elem(j);
		    }
		    for (uInt j=shape.length();j<tdimField.nelements();j++) {
			cptr[j] = '\0';
		    }
		}
		outbt.write(fitsout);
		++inbt;
		++outbt;
	    }
	    for (uInt i=0;i<maxes.nelements();i++) {
		delete (FitsField<short> *)(maxisFields[i]);
	    }
	}
	break;
    case FITS::UnknownExtensionHDU:
    default:
	cerr << "Unknown HDU type seen in the input file." << endl;
	exit(1);
	break;
    }
}

void modifyVColName(FitsKeywordList &kwl, const String &oldname, 
		    const String &newname)
{
    kwl.first();
    FitsKeyword *curr = kwl.curr();
    while (curr) {
	if (!curr->isreserved()) {
	    String tmp(curr->name());
	    // strip off trailing blanks
	    tmp = tmp.before(Regex(" *$"));
	    if (tmp == oldname) {
		curr->name(newname.chars());
		cout << "keyword " << tmp << " renamed to " << newname << endl;
	    }
	} else {
	    if (curr->kw().name() == FITS::TTYPE) {
		String tmp(curr->asString());
		// strip off trailing blanks
		tmp = tmp.before(Regex(" *$"));
		if (tmp == oldname) {
		    (*curr) = newname.chars();
		    cout << "column " << tmp << " renamed to " << newname << endl;
		}
	    }
	}
	curr = kwl.next();
    }
}

String makeShape(const Vector<Int> &intShape) {
    ostringstream ostr;
    ostr << "(";
    if (intShape.nelements() > 0) {
	ostr << intShape(0);
    }
    for (uInt i=1;i<intShape.nelements();i++) {
	ostr << "," << intShape(i);
    }
    ostr << ")";
    String result(ostr);
    return result;
}


String intToString(Int value) {
    ostringstream ostr;
    ostr << value;
    String tmp(ostr);
    return tmp;
}

void removeColumn(int colNumber, FitsKeywordList &kwl)
{
    // column related fields are any keywords which are
    // indexed and start with T, including user defined
    // keywords
    Regex userTcolReg("^T[A-Z]?[0-9]?[ ]*$");
    Regex stdTcolReg("^T[A-Z]?.*$");
    // Find and delete those with the index == colNumber
    // remeber the number of elements in TFORM when
    // encountered
    String tform;
    kwl.first();
    FitsKeyword *kw = kwl.curr();
    while (kw) {
	String tmp(kw->name());
	if (kw->isreserved()) {
	    if (kw->isindexed() &&
		tmp.matches(stdTcolReg)) {
		if (kw->index() == colNumber) {
		    if (kw->kw().name() == FITS::TFORM) {
			tform = kw->asString();
		    }
		    // remove it
		    kwl.del();
		} 
	    } 
	} else {
	    if (tmp.matches(userTcolReg)) {
		String colNumStr = tmp.from(RXint);
		String colName = tmp.before(RXint);
		Int index = atoi(colNumStr.chars());
		if (index == colNumber) {
		    // remove it
		    kwl.del();
		} 
	    } 
	}
	kw = kwl.next();
    }

    // parse tform into a type and a number of elements
    Int nels = 1;
    const char *cptr = tform.chars();
    // skip leading blanks
    for (;*cptr == ' '; ++cptr);
    if (FITS::isa_digit(*cptr)) {
	nels = FITS::digit2bin(*cptr++);
	while (FITS::isa_digit(*cptr))
	    nels = nels * 10 * FITS::digit2bin(*cptr);
    }
    switch (*cptr) {
    case 'X':
	// convert nels to an integer number of bytes and no nothing
	{
	    Int tmp = nels/8;
	    if (tmp*8 < nels) nels++;
	}
    case 'L':
    case 'B':
    case 'A':
	// do nothing
	break;
    case 'I':
	nels *= 2; break;
    case 'J':
    case 'E':
	nels *= 4; break;
    case 'D':
    case 'C':
	nels *= 8; break;
    case 'M':
	nels *= 16; break;
    case 'P':
	if (nels != 0) nels = 8; break;
    default:
	cerr << "Unknown column data type seen for column " 
	     << colNumber << " : " << *cptr << endl;
	exit(1);
    }

    // and redice NAXIS and TFIELDS keyword values

    kwl.first();
    kw = kwl(FITS::NAXIS, 1);
    AlwaysAssert(kw, AipsError);
    *kw = kw->asInt() - nels;
    kw = kwl(FITS::TFIELDS);
    AlwaysAssert(kw, AipsError);
    *kw = kw->asInt() - 1;
    kwl.first();
    kw = kwl.curr();

    // finally renumber everything 
    incColNumber((colNumber+1), -1, kwl);
}

void incColNumber(Int startAt, Int incr, FitsKeywordList &kwl)
{
    // column related fields are any keywords which are
    // indexed and start with T, including user defined
    // keywords
    Regex userTcolReg("^T[A-Z]?[0-9]?[ ]*$");
    Regex stdTcolReg("^T[A-Z]?.*$");

    kwl.first();
    FitsKeyword *kw = kwl.curr();
    while (kw) {
	String tmp(kw->name());
	if (kw->isreserved()) {
	    if (kw->isindexed() &&
		tmp.matches(stdTcolReg)) {
		if (kw->index() >= startAt) {
		    // these must be replaced and then deleted
		    // add its replacement BEFORE it, insertions
		    // occur between the current and the next
		    // location
		    kwl.prev();
		    switch (kw->type()) {
		    case FITS::BYTE:
			kwl.mk((kw->index()+incr), kw->kw().name(),
			       kw->asBool(),
			       kw->comm());
			break;
		    case FITS::CHAR:
		    case FITS::STRING:
			kwl.mk((kw->index()+incr), kw->kw().name(),
			       kw->asString(),
			       kw->comm());
			break;
		    case FITS::LONG:
		    case FITS::SHORT:
			kwl.mk((kw->index()+incr), kw->kw().name(),
			       kw->asInt(),
			       kw->comm());
			break;
		    case FITS::DOUBLE:
			kwl.mk((kw->index()+incr), kw->kw().name(),
			       kw->asDouble(),
			       kw->comm());
			break;
		    default:
			cerr << "Unrecognized type for keyword "
			     << kw->name() << kw->index() << endl;
			exit(1);
		    }
		    // this leaves the pointer at the just inserted kw
		    // move to the next one, the one to delete
		    kwl.next();
		    kwl.del();
		    // this leaves the pointer back at the just inserted one
		    // which is where we want it.
		} 
	    } 
	} else {
	    if (tmp.matches(userTcolReg)) {
		String colNumStr = tmp.from(RXint);
		String colName = tmp.before(RXint);
		Int index = atoi(colNumStr.chars());
		if (index >= startAt) {
		    // these can simply be renamed
		    colName = colName + intToString(index + incr);
		    kw->name(colName.chars());
		} 
	    } 
	}
	kw = kwl.next();
    }
}


void scanHDUs(FitsInput &fitsin, Block<String> &dataShapes)
{
    Int count = 0;
    while (!fitsin.eof()) {
	if (count >= Int(dataShapes.nelements())) {
	    dataShapes.resize(dataShapes.nelements()*2);
	}
	// switch on type
	if (fitsin.rectype() != FITS::HDURecord) {
	    cerr << "Invalid record in input FITS file" << endl;
	    exit(1);
	}
	switch (fitsin.hdutype()) {
	case FITS::PrimaryArrayHDU:
	case FITS::PrimaryGroupHDU:
	case FITS::ImageExtensionHDU:
	case FITS::AsciiTableHDU:
	    // just skip these
	    cout << "Skipping HDU " << count << " of type : " << Int(fitsin.hdutype()) << endl;
	    fitsin.skip_hdu();
	    break;
	case FITS::BinaryTableHDU:
	    // the only one we care about
	    {
		BinaryTableExtension inbt(fitsin);
		cout << "Scanning HDU " << count << " of type : " << Int(fitsin.hdutype()) << endl;
		// construct the output one from inbt's keywords
		FitsKeywordList kwl(inbt.kwlist());
		FitsKeyword *extn = kwl(FITS::EXTNAME);
		AlwaysAssert(extn, AipsError);
		String extname(extn->asString());
		if (extname != "UNIPOPS SNGLE DISH") {
		    cerr << "Warning: this is not a UniPOPS generated FITS file ..." << endl;
		    cerr << "   This conversion may not be valid." << endl;
		}
		Vector<Int> colmap(inbt.ncols());
		indgen(colmap);
		Vector<Int> maxes;
		Block<void *> maxisFields;
		// search for any MAXIS keywords
		FitsKeyword *maxisKW = kwl("MAXIS");
		if (maxisKW) {
		    maxes.resize(maxisKW->asInt());
		    maxes = 0;
		    maxisFields.resize(maxes.nelements());
		    maxisFields = static_cast<void *>(0);
		    for (uInt  i=0;i<maxes.nelements();i++) {
			String maxisStr = "MAXIS" + intToString(i+1);
			maxisKW = kwl(maxisStr.chars());
			if (maxisKW) {
			    maxes(i) = maxisKW->asInt();
			}
		    }
		    Regex maxisReg("^MAXIS[0-9]?[ ]*$");
		    for (uInt i=0;Int(i)<inbt.ncols();i++) {
			String colname(inbt.ttype(i));
			if (colname.matches(maxisReg)) {
			    String axisStr = colname.from(RXint);
			    Int axisNum = atoi(axisStr.chars()) - 1;
			    maxisFields[axisNum] = (void *)(new FitsField<short>);
			    AlwaysAssert(maxisFields[axisNum], AipsError);
			    inbt.bind(i, *(FitsField<short> *)(maxisFields[axisNum]));
			} 
		    }
		}

		// do it one row at a time
		Bool isConst = True;
		Int i=0;
		while (isConst && i<inbt.nrows()) {
		    inbt.read(1);
		    // get the shape of this row
		    for (uInt j=0;j<maxes.nelements();j++) {
			if (maxisFields[j]) {
			    maxes(j) = (*(FitsField<short> *)(maxisFields[j]))();
			}
		    }
		    String shape = makeShape(maxes);
		    if (i==0) {
			dataShapes[count] = shape;
		    } else {
			if (dataShapes[count] != shape) {
			    // true variable shaped DATA column
			    dataShapes[count] = "";
			    isConst = False;
			}
		    }
		    i++;
		}
		// read the remaining rows - there is no skip the rest function in the FITS classes
		// I also don't understand why the thing on the left in the next line
		// has the -1 in it.  There's much I don't understand about the FITS classes.
		while (inbt.currrow() < (inbt.nrows()-1)) inbt.read(1);
		for (uInt i=0;i<maxes.nelements();i++) {
		    delete (FitsField<short> *)(maxisFields[i]);
		}
		cout << "HDU " << count << " is a BinaryTable with ";
		if (dataShapes[count].length() > 0) {
		    cout << "fixed shape DATA column with TDIM = " << dataShapes[count] << endl;
		} else {
		    cout << "variable shaped DATA column" << endl;
		}
	    }
	    break;
	default:
	    cerr << "Unknown HDU type seen in the input file." << endl;
	    exit(1);
	    break;
	}
	count++;
    }
}
