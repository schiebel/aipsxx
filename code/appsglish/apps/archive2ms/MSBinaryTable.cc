//# MSBinaryTable.cc: Convert a FITS binary table to an AIPS++ Table.
//# Copyright (C) 1994,1995,1996,1997,1998,1999,2000,2001,2002,2004
//# Associated Universities, Inc. Washington DC, USA.
//# 
//# This program is free software; you can redistribute it and/or modify
//# it under the terms of the GNU General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or
//# (at your option) any later version.
//# 
//# This program is distributed in the hope that it will be useful,
//# but WITHOUT ANY WARRANTY; without even the implied warranty of
//# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//# GNU General Public License for more details.
//# 
//# You should have received a copy of the GNU General Public License
//# along with this program; if not, write to the Free Software
//# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
//# 
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: MSBinaryTable.cc,v 19.4 2004/11/30 17:50:06 ddebonis Exp $

#include <MSBinaryTable.h>
#include <fits/FITS/fits.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MeasurementSets/MSTableImpl.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/ArrColDesc.h>
#include <tables/Tables/ScaColDesc.h>
#include <tables/Tables/TableRecord.h>
#include <tables/Tables/ArrayColumn.h>
#include <tables/Tables/ScalarColumn.h>
#include <tables/Tables/ColumnDesc.h>
#include <tables/Tables/StManAipsIO.h>
#include <tables/Tables/StandardStMan.h>
#include <tables/Tables/IncrementalStMan.h>
#include <tables/Tables/TiledShapeStMan.h>
#include <tables/Tables/RowCopier.h>
#include <casa/Containers/Record.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayUtil.h>
#include <casa/Arrays/ArrayIO.h>
#include <casa/OS/File.h>
#include <casa/Utilities/Assert.h>
#include <casa/Utilities/Regex.h>
#include <casa/sstream.h>
#include <casa/stdio.h>

#include <casa/namespace.h>
//	
// Constructor
//
MSBinaryTable::MSBinaryTable(FitsInput& fitsin, const String& compress,
			     const String& tmpdir)
: BinaryTableExtension(fitsin),
  itsTableInfo(),
  itsVersion  (0),
  itsNrMSKs   (10),
  itsMSKC     (itsNrMSKs," "),
  itsMSKN     (itsNrMSKs," "),
  itsMSKV     (itsNrMSKs," "),
  itsgotMSK   (itsNrMSKs,False),
  itsCompress (compress)
{
    //
    // Get some things to remember.
    //
    Int nfield = tfields();      // nr of fields in the FITS table
    itsNelem.resize(nfield);     // nrs of elements per field
    itsNelem = 0;
    itsIsArray.resize(nfield);   // array flags per field
    itsIsArray = False;          // assume scalar-type

    //
    // Step 0: The mandatory and reserved FITS keywords have been read
    // and put into the data members by the BinaryTableExtension
    // constructor.
    //
    // Step 1: Now read the rest of the FITS keywords and put them
    // into the itsMSK... buffers (the ones with names like MSK*,
    // i.e. the MS-specific keywords) and into TableRecord itsKwSet
    // (the rest of the FITS keywords and EXTVER).
    //
    convertKeywords();

    // 
    // Step 1a: Read the table.info from the MSK table keywords TYPE,
    // SUBTYPE and README, and clear the relevant MSK buffer entries.
    //
    for (uInt ikey=0; ikey<itsNrMSKs; ikey++) {
	if (itsgotMSK(ikey) && itsMSKC(ikey)==" ") {
	    //
	    // This is a table keyword.
	    //
	    if (itsMSKN(ikey) == "TYPE") {
		itsTableInfo.setType(itsMSKV(ikey));
///		cout << "found MSK TYPE    = " << itsMSKV(ikey) << endl;
	    } else if (itsMSKN(ikey) == "SUBTYPE") {
		itsTableInfo.setSubType(itsMSKV(ikey));
///		cout << "found MSK SUBTYPE = " << itsMSKV(ikey) << endl;
	    } else if (itsMSKN(ikey) == "README") {
		itsTableInfo.readmeAddLine(itsMSKV(ikey));
///		cout << "found MSK README  = " << itsMSKV(ikey) << endl;
	    }
	    itsgotMSK(ikey) = False;
	}
    }

    //
    // Step 2: Convert the FITS field descriptions stored in the data
    // members, into TableColumn descriptions (part of itsTableDesc).
    // Also interpret the storage options contained in the MSKs (keys
    // UNIT, MEASINFO, SHAPE and OPTIONS) and clear the relevant MSK buffer
    // entries.
    //
    describeColumns();

    //
    // Step 3: Convert the rest of the MSKs. The column-type keywords
    // are added to the TableColumn description and the table-type
    // ones are added to itsKwSet.
    //
    convertMSKeywords();

    //
    // Step 3a: Move the table keywords from itsKwSet to itsTableDesc
    // and clean out itsKwSet.
    //
    itsTableDesc.rwKeywordSet().merge(itsKwSet,RecordInterface::RenameDuplicates);
    RecordDesc emptyDesc;
    itsKwSet.restructure(emptyDesc);

    //
    // Step 4: Create a single-row scratch table, with the table
    // description just built. It will hold the "current" row and is
    // therefore called itsCurRowTab.
    //
    TableDesc* tdesc;
    if (itsCompress == "decompress") {
      tdesc = new TableDesc(tableDescDecompress (itsTableDesc, "MAIN", False));
    } else {
      tdesc = new TableDesc(itsTableDesc);
    }
    String tmpname =
      File::newUniqueName(tmpdir, "ms2archive_tmptab").originalName();
    SetupNewTable newtab(tmpname, *tdesc, Table::Scratch);
    delete tdesc;
    StManAipsIO stman;
    newtab.bindAll (stman);
    MSTableImpl::setupCompression(newtab);
    itsCurRowTab = Table(newtab, TableLock::PermanentLocking, 1);

    //
    // Fill the one row of itsCurRowTab.
    //
    if (nrows() > 0) {
	//
	// Read the first row of the FITS table into memory.
	//
	read(1);
	//
	// Fill the single row in itsCurRowTab from memory.
	//
	fillRow();
    }
}

void MSBinaryTable::fillRow()
{
    //
    // Loop over each field.
    //
    for (Int icol=0; icol<tfields(); icol++) {
	//		and switch on the FITS type
	TableColumn tabcol(itsCurRowTab, itsTableDesc[icol].name());
	switch (field(icol).fieldtype()) {
	    
	case FITS::LOGICAL:
	{
	    FitsField<FitsLogical> thisfield = *(FitsField<FitsLogical>* )&field(icol);
	    Vector<Bool> vec(itsNelem(icol));
	    for (Int ie=0; ie<itsNelem(icol); ie++) {
		vec(ie) = thisfield(ie);
	    }
	    if (itsIsArray(icol)) {
		ArrayColumn<Bool> arrcol(tabcol);
		arrcol.put(0,vec.reform(tabcol.shapeColumn()));
	    } else if (itsNelem(icol) == 1) {
		tabcol.putScalar(0,vec(0));
	    }
	}
	break;
	
	case FITS::BIT:
	{
	    FitsField<FitsBit> thisfield = *(FitsField<FitsBit>* )&field(icol);
	    Vector<Bool> vec(itsNelem(icol));
	    for (uInt ie=0; ie<field(icol).nelements(); ie++) {
		vec(ie) = (int(thisfield(ie)));
	    }
	    if (itsIsArray(icol)) {
		ArrayColumn<Bool> arrcol(tabcol);
		arrcol.put(0,vec.reform(tabcol.shapeColumn()));
	    } else if (itsNelem(icol) == 1) {
		tabcol.putScalar(0,vec(0));
	    }
	}
	break;
	
	case FITS::BYTE:
	{
	    FitsField<unsigned char> thisfield = *(FitsField<unsigned char>* )&field(icol);
	    Vector<uChar> vec(itsNelem(icol));
	    for (Int ie=0; ie<itsNelem(icol); ie++) {
		vec(ie) = thisfield(ie);
	    }
	    if (itsIsArray(icol)) {
		ArrayColumn<uChar> arrcol(tabcol);
		arrcol.put(0,vec.reform(tabcol.shapeColumn()));
	    } else if (itsNelem(icol) == 1) {
		tabcol.putScalar(0,vec(0));
	    }
	}
	break;

	case FITS::CHAR:
	case FITS::STRING:
	{
	    FitsField<char> thisfield = *(FitsField<char>* )&field(icol);
	    char* cptr = (char* )thisfield.data();
	    uInt length = thisfield.nelements();
	    if (itsIsArray(icol)) {
		//
		// Decode the string into a vector of strings.
		// Using whitespac,etc. as separator.
		//
		IPosition shp (tabcol.shapeColumn());
		uInt nr = shp.product();
		istringstream istr(std::string(cptr,length));
		Vector<String> vec;
		istr >> vec;
		ArrayColumn<String> arrcol(tabcol);
		if (vec.nelements() != nr) {
		    //
		    // Whitespace is too much; use newspace as separator.
		    // First look for the true end (remove trailing blanks).
		    // Remove leading and trailing [] if there.
		    //
		    while (length > 0 && 
			   (cptr[length-1] == '\0' || cptr[length-1] == ' ')) {
			length--;
		    }
		    if (length>1 && cptr[0] == '['  &&  cptr[length-1] == ']') {
			cptr++;
			length -= 2;
		    }
		    String str = String(cptr,length);
		    Vector<String> strvec = stringToVector (str, '\n');
		    vec.reference (strvec);
		    if (vec.nelements() != nr) {
			cerr << "**Error: " << vec.nelements()
			     << " values expected for column "
			     << tabcol.columnDesc().name()
			     << ", found " << nr << endl;
			vec.resize (nr, True);
		    }
		}
		arrcol.put(0,vec.reform(shp));
	    } else {
		//
		// Look for the true end (remove trailing blanks).
		//
		while (length > 0 && 
		       (cptr[length-1] == '\0' || cptr[length-1] == ' ')) {
		    length--;
		}
		String str = String(cptr,length);
		tabcol.putScalar(0,str);
	    }
	}
	break;

	case FITS::SHORT:
	{
	    FitsField<short> thisfield = *(FitsField<short>* )&field(icol);
	    Vector<Short> vec(itsNelem(icol));
	    for (Int ie=0; ie<itsNelem(icol); ie++) {
		vec(ie) = thisfield(ie);
	    }
	    if (itsIsArray(icol)) {
		ArrayColumn<Short> arrcol(tabcol);
		arrcol.put(0,vec.reform(tabcol.shapeColumn()));
	    } else if (itsNelem(icol) == 1) {
		tabcol.putScalar(0,vec(0));
	    }
	}
	break;

	case FITS::LONG:
	{
	    FitsField<FitsLong> thisfield = * (FitsField<FitsLong>* )&field(icol);
	    Vector<Int> vec(itsNelem(icol));
	    for (Int ie=0; ie<itsNelem(icol); ie++) {
		vec(ie) = (Int )thisfield(ie);
	    }
	    if (itsIsArray(icol)) {
		ArrayColumn<Int> arrcol(tabcol);
		arrcol.put(0,vec.reform(tabcol.shapeColumn()));
	    } else if (itsNelem(icol) == 1) {
		tabcol.putScalar(0,vec(0));
	    }
	}
	break;

	case FITS::FLOAT:
	{
	    FitsField<float> thisfield = *(FitsField<float>* )&field(icol);
	    Vector<Float> vec(itsNelem(icol));
	    for (Int ie=0; ie<itsNelem(icol); ie++) {
		vec(ie) = thisfield(ie);
	    }
	    if (itsIsArray(icol)) {
		ArrayColumn<Float> arrcol(tabcol);
		arrcol.put(0,vec.reform(tabcol.shapeColumn()));

	    } else if (itsNelem(icol) == 1) {
		tabcol.putScalar(0,vec(0));
	    }
	}
	break;

	case FITS::DOUBLE:
	{
	    FitsField<double> thisfield = *(FitsField<double>* )&field(icol);
	    Vector<Double> vec(itsNelem(icol));
	    for (Int ie=0; ie<itsNelem(icol); ie++) {
		vec(ie) = thisfield(ie);
	    }
	    if (itsIsArray(icol)) {
		ArrayColumn<Double> arrcol(tabcol);
		arrcol.put(0,vec.reform(tabcol.shapeColumn()));
	    } else if (itsNelem(icol) == 1) {
		tabcol.putScalar(0,vec(0));
	    }
	}
	break;

	case FITS::COMPLEX:
	{
	    FitsField<Complex> thisfield = *(FitsField<Complex>* )&field(icol);
	    Vector<Complex> vec(itsNelem(icol));
	    for (Int ie=0; ie<itsNelem(icol); ie++) {
		vec(ie) = thisfield(ie);
	    }
	    if (itsIsArray(icol)) {
		ArrayColumn<Complex> arrcol(tabcol);
		arrcol.put(0,vec.reform(tabcol.shapeColumn()));
	    } else if (itsNelem(icol) == 1) {
		tabcol.putScalar(0,vec(0));
	    }
	}
	break;

	case FITS::DCOMPLEX:
	{
	    FitsField<DComplex> thisfield = *(FitsField<DComplex>* )&field(icol);
	    Vector<DComplex> vec(itsNelem(icol));
	    for (Int ie=0; ie<itsNelem(icol); ie++) {
		vec(ie) = thisfield(ie);
	    }
	    if (itsIsArray(icol)) {
		ArrayColumn<DComplex> arrcol(tabcol);
		arrcol.put(0,vec.reform(tabcol.shapeColumn()));
	    } else if (itsNelem(icol) == 1) {
		tabcol.putScalar(0,vec(0));
	    }
	}
	break;

	case FITS::ICOMPLEX:
	{
	    FitsField<IComplex> thisfield = *(FitsField<IComplex> *)&field(icol);
	    Vector<DComplex> vec(itsNelem(icol));
	    for (Int ie=0; ie<itsNelem(icol); ie++) {
	        const IComplex& val = thisfield(ie);
		vec(ie) = DComplex (val.real(), val.imag());
	    }
	    if (itsIsArray(icol)) {
		ArrayColumn<DComplex> arrcol(tabcol);
		arrcol.put(0,vec.reform(tabcol.shapeColumn()));
	    } else if (itsNelem(icol) == 1) {
		tabcol.putScalar(0,vec(0));
	    }
	}
	break;

	default:
	    // VADESC or NOVALUE (which shouldn't occur here
	    cerr << "Error: unrecognized table data type for field "
		 << icol << endl;
	    cerr << "That should not have happened" << endl;
	    continue;
	}			// end of loop over switch
    }			// end of loop over fields
    
    //
    // Loop over all virtual columns if necessary.
    //
    if (itsKwSet.nfields() > 0) {
	for (uInt icol=0; icol<itsKwSet.nfields(); icol++) {
	    TableColumn tabcol(itsCurRowTab, itsKwSet.name(icol));
	    switch (itsKwSet.type(icol)) {
	    case TpBool:
		tabcol.putScalar(0,itsKwSet.asBool(icol));
		break;
	    case TpUChar:
		tabcol.putScalar(0,itsKwSet.asuChar(icol));
		break;
	    case TpShort:
		tabcol.putScalar(0,itsKwSet.asShort(icol));
		break;
	    case TpInt:
		tabcol.putScalar(0,itsKwSet.asInt(icol));
		break;
	    case TpUInt:
		tabcol.putScalar(0,itsKwSet.asuInt(icol));
		break;
	    case TpFloat:
		tabcol.putScalar(0,itsKwSet.asfloat(icol));
		break;
	    case TpDouble:
		tabcol.putScalar(0,itsKwSet.asdouble(icol));
		break;
	    case TpComplex:
		tabcol.putScalar(0,itsKwSet.asComplex(icol));
		break;
	    case TpDComplex:
		tabcol.putScalar(0,itsKwSet.asDComplex(icol));
		break;
	    case TpString:
		tabcol.putScalar(0,itsKwSet.asString(icol));
		break;
	    default:
		throw(AipsError("Impossible virtual column type"));
		break;
	    }
	}
    }
}

//	The destructor

MSBinaryTable::~MSBinaryTable()
{
    // empty
}

Table MSBinaryTable::fullTable(const String& tabname)
{
    //
    // Find the extension name, thus the table type.
    //
    Regex trailing(" *$"); // trailing blanks
    String extname(MSBinaryTable::extname());
    extname = extname.before(trailing);
    //
    // Prepare for the creation of a new table with the name requested
    // and with the same table description as itsCurRowTab.
    // Adjust the table description for (un)compression.
    //
    TableDesc* tdesc;
    if (itsCompress == "compress") {
      tdesc = new TableDesc(tableDescCompress (itsTableDesc, extname));
    } else if (itsCompress == "decompress") {
      tdesc = new TableDesc(tableDescDecompress (itsTableDesc,
						 extname, True));
    } else {
      tdesc = new TableDesc(tableDescDecompress (itsTableDesc,
						 extname, False));
    }
    SetupNewTable newtab(tabname, *tdesc, Table::NewNoReplace);
    Int nRows = nrows();
    StandardStMan stanStMan ("SSMData", -nRows);
    newtab.bindAll (stanStMan);
    //
    // For the main MS table, we'd better work with incremental and
    // tiled storage managers.
    //
    if (extname == "MAIN") {
        //
        // Find the tile shape for the data.
        //
        IPosition datashape;
	if (tdesc->isColumn ("DATA")) {
	    datashape = tdesc->columnDesc("DATA").shape();
	} else {
	    datashape = tdesc->columnDesc("DATA_COMPRESSED").shape();
	}
	Int nChanPerTile = (datashape(1) + 7) / 8;
        Int nRowsPerTile = 16384/(datashape(0)*nChanPerTile);
        Int nTilesInRow = (nRows+nRowsPerTile-1)/nRowsPerTile;
        nRowsPerTile = (nRows+nTilesInRow-1)/nTilesInRow;
	IPosition tileShape (3,datashape(0),nChanPerTile,nRowsPerTile);
	cout << "**tileShape=" << tileShape << endl;
	//
	// Create the storage managers.
	// The StandardStMan will contain about 1024 rows per bucket.
	//
	IncrementalStMan incrStMan ("ISMData");
	TiledShapeStMan  tiledStMan("TiledData", tileShape);
	//
	// Bind almost all columns to the incrStMan.
	// ANTENNA{1,2}, DATA_DESC_ID, and UVW are bound to the
	// StandardStMan.
	// DATA and FLAG are bound to the tiledStMan.
	//
	newtab.bindAll (incrStMan, True);
	//
	newtab.bindColumn(MS::columnName(MS::ANTENNA1),stanStMan);
	newtab.bindColumn(MS::columnName(MS::ANTENNA2),stanStMan);
	newtab.bindColumn(MS::columnName(MS::UVW),stanStMan);
	if (tdesc->isColumn (MS::columnName(MS::VIDEO_POINT))) {
	    newtab.bindColumn(MS::columnName(MS::VIDEO_POINT),stanStMan);
	}
	if (tdesc->isColumn ("NFRA_AVERAGE_DATA")) {
	    newtab.bindColumn("NFRA_AVERAGE_DATA",stanStMan);
	}
	newtab.bindColumn(MS::columnName(MS::DATA),tiledStMan);
	newtab.bindColumn(MS::columnName(MS::FLAG),tiledStMan);
	Bool hasS = tdesc->isColumn(MS::columnName(MS::SIGMA_SPECTRUM));
	Bool hasW = tdesc->isColumn(MS::columnName(MS::WEIGHT_SPECTRUM));
	if (hasW) {
	  hasW = 
	    tdesc->columnDesc(MS::columnName(MS::WEIGHT_SPECTRUM)).ndim() == 2;
	}
	if (hasS || hasW) {
	    TiledShapeStMan tiledWS ("TiledWS", tileShape);
	    if (hasS) {
	        newtab.bindColumn(MS::columnName(MS::SIGMA_SPECTRUM),tiledWS);
	    }
	    if (hasW) {
	      newtab.bindColumn(MS::columnName(MS::WEIGHT_SPECTRUM),tiledWS);
	    }
	}
	// Bind SCALE and OFFSET of compressed columns also to StandardStMan.
	Regex cmprRegex ("_COMPRESSED$");
	for (uInt i=0; i<tdesc->ncolumn(); i++) {
	    const ColumnDesc& cd = tdesc->columnDesc(i);
	    String name = cd.name();
	    name = name.before (cmprRegex);
	    if (name != cd.name()
	    &&  tdesc->isColumn(name + "_SCALE")
	    &&  tdesc->isColumn(name + "_OFFSET")) {
	        newtab.bindColumn (name + "_SCALE", stanStMan);
	        newtab.bindColumn (name + "_OFFSET", stanStMan);
	    }
	}
	// Do the possible creation of compress engines.
	MSTableImpl::setupCompression (newtab);
    }
    delete tdesc;

    //
    // Create an empty table with the proper number of rows.
    //
    Table full(newtab,nrows());

    //
    // Create a row copier that will repeatedly copy the current row
    // in the single-row table itsCurRowTab to the full-size table.
    //
    RowCopier rowcop(full, itsCurRowTab);

    //
    // Loop over all rows remaining.
    //
    for (Int outrow = 0, infitsrow = currrow();
	 infitsrow < nrows(); 
	 outrow++, infitsrow++) {
	//
	// Copy the 0-th row from itsCurRowTab to the outrow-th row in
	// the full-sized table.
	//
	rowcop.copy(outrow, 0);
	//
	// Read the next input row, but don't read past the end of the
	// table.
	//
	if ((infitsrow+1) < nrows()) {
	    //
	    // Read the next row.
	    //
	    read(1);
	    //
	    // Write it in itsCurRowTab.
	    //
	    fillRow();
	}
    }

    //
    // Construct the table.info.
    //
    TableInfo& info = full.tableInfo();
    info = itsTableInfo;

    return full;
}

TableRecord& MSBinaryTable::getKeywords()
{
    return itsCurRowTab.rwKeywordSet();
}

const Table& MSBinaryTable::thisRow()
{
    return (itsCurRowTab);
}

const Table& MSBinaryTable::nextRow()
{
    //
    // Here, its user beware in reading past end of table i.e. just
    // the same way FITS works.
    //
    read(1);
    fillRow();
    return (itsCurRowTab);
}

//
// Convert part of the keywords in the FITS binary table extension
// header to a TableRecord (itsKwSet). MS-specific keywords, MSK...,
// are only scanned and buffered. They will be converted by
// convertMSKeywords().
//
void MSBinaryTable::convertKeywords()
{
    ConstFitsKeywordList& kwl = kwlist();
    kwl.first();
    const FitsKeyword* kw;
    Regex trailing(" *$"); // trailing blanks
    String kwname;
    
    //
    // Buffer for storing the MSK's, MS-specific FITS keywords.
    //
    uInt iMSK = 0; 

    //
    // Loop through the FITS keyword list.
    //
    while ((kw = kwl.next())) {
	
	if (!kw->isreserved()) {
	    //
	    // Non-reserved keyword:
	    //
	    
	    //
	    // Get the name of the keyword.
	    // -- At present (1998, March 11) non-reserved FITS
	    // keywords are not recognised as indexed. The index is
	    // just considered part of the name. --
	    //
	    kwname = kw->name();
///	    cout << "doing keyword " << kwname << endl;
	    //
            // If the name already occurs in itsKwSet, issue a warning
            // and overwrite the old keyword.
	    //
	    if (itsKwSet.isDefined(kwname)) {
		cout << "Duplicate keyword name : " << kwname
		     << " most recent occurrance takes precedence" << endl;
		itsKwSet.removeField(kwname);
	    }
	    
	    //
	    // Buffer the MS-specific keywords.
	    //
	    if (kwname(0,3)=="MSK") {
		iMSK = atoi(kwname.after(3).chars());
		if (iMSK > 0) {
		    if (iMSK > itsNrMSKs) {
			// Extend the MSK buffers with 10 elements.
			itsNrMSKs += 10;
			itsMSKC.resize(itsNrMSKs,True);
			itsMSKN.resize(itsNrMSKs,True);
			itsMSKV.resize(itsNrMSKs,True);
			itsgotMSK.resize(itsNrMSKs,True);
			for (uInt ikey=iMSK-1; ikey<itsNrMSKs; ikey++) {
			    itsgotMSK(ikey) = False;
			}
		    }
		    itsgotMSK(iMSK-1) = True;
		    //
		    // String values shorter than 8 characters are
		    // padded with blanks. Remove those.
		    //
		    String val = kw->asString();
		    val = val.before(trailing);
		    if (kwname(3,1)=="C") {
			itsMSKC(iMSK-1) = val;
		    } else if (kwname(3,1)=="N") {
			itsMSKN(iMSK-1) = val;
		    } else if (kwname(3,1)=="V") {
			itsMSKV(iMSK-1) = val;
		    } else {
			cout << "MSBinaryTable found unknown MSK keyword: "
			     << kwname << ". It will be ignored" << endl;
		    }
		} else {
		    cout << "MSBinaryTable found unknown MSK keyword: "
			 << kwname << ". It will be ignored" << endl;
		}
	    } else {

		// Add a keyword of the proper type to the keyword
		// list.
		//
		switch (kw->type()) {
		case FITS::NOVALUE: itsKwSet.define(kwname,"");
		    // NOVALUE fields become string keywords with an emtpy string.
		    cout << "FITS::NOVALUE found" << endl;
		    break;
		case FITS::LOGICAL: itsKwSet.define(kwname, kw->asBool()); 
		    break;
		case FITS::CHAR: itsKwSet.define(kwname, kw->asString());
		    break;
		case FITS::STRING: itsKwSet.define(kwname, kw->asString());
		    break;
		case FITS::LONG: itsKwSet.define(kwname, kw->asInt());
		    break;
		case FITS::FLOAT: itsKwSet.define(kwname, kw->asFloat());
		    break;
		case FITS::DOUBLE: itsKwSet.define(kwname, kw->asDouble());
		    break;
		case FITS::COMPLEX: itsKwSet.define(kwname, kw->asComplex());
		    break;
		default:
		    cerr << "Error: unrecognized table data type for keyword "
			 << kwname << " type = " << kw->type() << endl;
		    cerr << "That should not have happened" << endl;
		    continue;
		}
		
		//
		// Add any comment in.
		//
		itsKwSet.setComment(kwname, kw->comm());
	    }           

	} else {
	    //
	    // Reserved keywords are handled elsewhere.
	    //
	}	  	// end of if(!kw->isreserved())
    }			// end of loop over kw list

    //
    // Handle the version keyword; make it a table keyword. The
    // MS_VERSION should be defined in a proper MSFITS file (written by
    // ms2fits), but if it is not, the version will get the value
    // FITS::minInt.
    //
    itsVersion = extver() / 100.0;
    String hduName = extname();
    hduName = hduName.before(trailing);
    if (hduName == "MAIN") {
      itsKwSet.define("MS_VERSION", itsVersion);
///   cout << "defined table keyword MS_VERSION = " << itsVersion << endl;
    }
}

//
// Convert FITS field descriptions to TableColumn descriptions. Also
// take into account the storage options specified in the MSK's.
//
void MSBinaryTable::describeColumns()
{
    Int defaultOption = ColumnDesc::FixedShape;
    Int option = defaultOption;
    //
    // Loop over the fields in the FITS table.
    //
    Regex trailing(" *$"); // trailing blanks
    Int nfield = tfields();    // nr of fields in the FITS table
    ConstFitsKeywordList& kwl = kwlist();
    for (Int icol=0; icol<nfield; icol++) {
	itsNelem(icol) = field(icol).nelements();
	
	//
	// Get the name of the field. (Names shorter than 8 characters
	// are padded with blanks. Remove those.)
	//
	String colname(ttype(icol));
	colname = colname.before(trailing);
///	cout << "Doing field " << icol << " with name " << colname << endl;

	//
	// Check if the name exists.
	//
	if (itsTableDesc.isColumn(colname)) {
	    //
	    // Yes, as a column name.  Append the column number to
	    // this name.
	    //
	    ostringstream newname;
	    newname << colname << "." << icol;
	    //
	    // str gives the space to cptr, icol must be deleted.
	    //
	    colname = newname.str();
	    //
	    // Issue a warning.
	    //
	    cout << "Duplicate column name : " << ttype(icol)
		 << " this occurance will be named " << colname << endl;

	} else if (itsTableDesc.keywordSet().isDefined(colname)) {
	    //
	    // Yes, as a keyword name.  Rename the offending keyword;
	    // the column name takes precedence!
	    //
	    String newname = colname + "-keyword";
///	    cout << "Duplicate name (keyword&  column) : " << ttype(icol)
///		 << " keyword will be renamed " << newname << endl;
	    itsTableDesc.rwKeywordSet().renameField(newname, colname);
	}
	
	//
	// Get a shorthand Bool for array versus scalar.  
	//
	Bool isString = False;
	Bool isSHAPEd = False;
	String SHAPEstr = "()";
	cout << colname << " is";
	if (field(icol).fieldtype() == FITS::CHAR
	    || field(icol).fieldtype() == FITS::STRING) {
	    isString = True;
	    cout << " a String-type column";
	    //
	    // See whether MSK SHAPE is defined. If so: array.
	    //
	    for (uInt ikey=0; ikey<itsNrMSKs; ikey++) {
		if (itsgotMSK(ikey) && (itsMSKC(ikey)==colname)) {
		    if (itsMSKN(ikey) == "SHAPE") {
			isSHAPEd = True;
			SHAPEstr = itsMSKV(ikey);
			itsIsArray(icol) = True;
			cout << " (Array)";
			itsgotMSK(ikey) = False;
		    }
		}
	    }

	} else if (itsNelem(icol) > 1) {
	    // multi-element vector or other array
	    itsIsArray(icol) = True;
	    cout << " a multi-element non-String-type Array column";

	} else {
	    cout << " a non-String-type column";
	    //
	    // See whether MSK SHAPE is defined. If so: array.
	    //
	    for (uInt ikey=0; ikey<itsNrMSKs; ikey++) {
		if (itsgotMSK(ikey) && (itsMSKC(ikey)==colname)) {
		    if (itsMSKN(ikey) == "SHAPE") {
			SHAPEstr = itsMSKV(ikey);
			itsIsArray(icol) = True;
			isSHAPEd = True;
			cout << " (0/1 element Vector)";
			itsgotMSK(ikey) = False;
		    }
		}
	    }
	}
	cout << endl;

	//
	// Get the shape vector for arrays.
	//
	Int ndim = 1;
	IPosition shape(ndim);

	if (itsIsArray(icol)) {
	    //
	    // Array-type columns must get a shape defined. For
	    // matrices and higher-dimension arrays the shape is read
	    // from the FITS keyword TDIM, but for vectors it must be
	    // derived from the repeat count in the FITS keyword TFORM.
	    //
	    String dimstr(tdim(icol));
	    String formstr(tform(icol));
	    if (dimstr(0,1)=="(") {
		//
		// TDIM key given as a string (dim1,dim2,...). Decode
		// the substring inside the parentheses. Again,
		// strings shorter than 8 characters were padded with
		// blanks; remove those.
		// 
		dimstr = dimstr.before(trailing);
		dimstr = dimstr(1,dimstr.length()-2);
		Vector<String> dimvec(stringToVector(dimstr));
		ndim = dimvec.nelements();
		shape.resize(ndim);
		for (Int id=0; id<ndim; id++) {
		    shape(id) = atoi(dimvec(id).chars());
		}
		cout << "   shape = " << shape << endl;

	    } else if (isSHAPEd) {
		//
		// Vector of strings or degenerated vector.  Use the
		// substring inside the parentheses as shape.
		//
		dimstr = SHAPEstr(1,SHAPEstr.length()-2);
		shape(0) = atoi(dimstr.chars());
		cout << "   shape = " << shape << endl;

	    } else {
		//
		// This must be a normal Vector. Derive its length
		// from the repeat count in the FITS key TFORM. Again,
		// strings shorter than 8 characters were padded with
		// blanks; remove those.
		//
		formstr = formstr.before(trailing);
		formstr = formstr(0,formstr.length()-1);
		shape(0) = atoi(formstr.chars());
		cout << "    shape = " << shape << endl;
	    }
	    //
	    // Set the option for the column description. Use the
	    // value of MSK OPTIONS if that is defined for this
	    // column. Otherwise set the default option.
	    //
	    option = defaultOption;
	    for (uInt ikey=0; ikey<itsNrMSKs; ikey++) {
		if (itsgotMSK(ikey) && (itsMSKC(ikey)==colname)) {
		    if (itsMSKN(ikey) == "OPTIONS") {
			if (itsMSKV(ikey) == "DIRECT") {
			    option = ColumnDesc::Direct;
///			    cout << "found MSK OPTIONS = DIRECT for "
///				 << colname << endl;
			} else {
			    cout << "Invalid MSK OPTIONS = "
				 << itsMSKV(ikey) << " is ignored." << endl;
			}
			itsgotMSK(ikey) = False;
		    }
		}
	    }

	} else {
///	    cout << colname << " is a scalar" << endl;

	}
		
	//
	// Add a column to the table descriptor.
	//
	
	//
        // Switch on the type of column.
	//
	switch (field(icol).fieldtype()) {
	    
	case FITS::BIT:
	    // BIT stored as LOGICAL.
	    
	case FITS::LOGICAL:
	    if (itsIsArray(icol)) {
		itsTableDesc.addColumn(ArrayColumnDesc<Bool>
				       (colname,"",shape,option));
	    } else {
		itsTableDesc.addColumn(ScalarColumnDesc<Bool>(colname,""));
	    }
	    break;
	    
	case FITS::BYTE:
	    // BYTE stored as uChar.
	    if (itsIsArray(icol)) {
		itsTableDesc.addColumn(ArrayColumnDesc<uChar>
				       (colname,"",shape,option));
	    } else {
		itsTableDesc.addColumn(ScalarColumnDesc<uChar>(colname,""));
	    }
	    break;
	    
	case FITS::SHORT:
	    if (itsIsArray(icol)) {
		itsTableDesc.addColumn(ArrayColumnDesc<Short>
				       (colname,"",shape,option));
	    } else {
		itsTableDesc.addColumn(ScalarColumnDesc<Short>(colname,""));
	    }
	    break;
	    
	case FITS::LONG:
	    if (itsIsArray(icol)) {
		itsTableDesc.addColumn(ArrayColumnDesc<Int>
				       (colname,"",shape,option));
	    } else {
		itsTableDesc.addColumn(ScalarColumnDesc<Int>(colname,""));
	    }
	    break;
	    
	case FITS::CHAR: 
	case FITS::STRING:
	    // was: A CHAR and STRING type is always a string, never an array.
	    if (itsIsArray(icol)) {
		itsTableDesc.addColumn(ArrayColumnDesc<String>
				       (colname,"",shape,option));
	    } else {
		itsTableDesc.addColumn(ScalarColumnDesc<String>(colname,""));
	    }
	    break;
	    
	case FITS::FLOAT:
	    if (itsIsArray(icol)) {
		itsTableDesc.addColumn(ArrayColumnDesc<Float>
				       (colname,"",shape,option));
	    } else {
		itsTableDesc.addColumn(ScalarColumnDesc<Float>(colname,""));
	    }
	    break;
	    
	case FITS::DOUBLE:
	    if (itsIsArray(icol)) {
		itsTableDesc.addColumn(ArrayColumnDesc<Double>
				       (colname,"",shape,option));
	    } else {
		itsTableDesc.addColumn(ScalarColumnDesc<Double>(colname,""));
	    }
	    break;
	    
	case FITS::COMPLEX:
	    if (itsIsArray(icol)) {
		itsTableDesc.addColumn(ArrayColumnDesc<Complex>
				       (colname,"",shape,option));
	    } else {
		itsTableDesc.addColumn(ScalarColumnDesc<Complex>(colname,""));
	    }
	    break;
	    
	case FITS::ICOMPLEX:
	    // ICOMPLEX is promoted to DCOMPLEX so no precision is lost.
	    
	case FITS::DCOMPLEX:
	    if (itsIsArray(icol)) {
		itsTableDesc.addColumn(ArrayColumnDesc<DComplex>
				       (colname,"",shape,option));
	    } else {
		itsTableDesc.addColumn(ScalarColumnDesc<DComplex>(colname,""));
	    }
	    break;
	    
	default:
	    // VADESC or NOVALUE should not happen in a table.
	    cerr << "Error: column " << icol
		 << " has untranslatable type " << field(icol).fieldtype()
		 << " This should NEVER happen " << endl;
	    continue;
	}		// end of switch on FITS type
	
	//
	// Set the comment string if appropriate.  (I don't really
	// understand, why it must be icol+1, but only that way the
	// comments are associated with the proper column names.)
	//
	if (kwl(FITS::TTYPE, icol+1)) {
///	    cout << "icol    = " << icol << endl;
///	    cout << "colname = " << colname << endl;
///	    cout << "comment = " << kwl(FITS::TTYPE,icol+1)->comm() << endl;
	    itsTableDesc.rwColumnDesc(colname).comment() =
                                         kwl(FITS::TTYPE,icol+1)->comm();
	}

	//
	// Attach associated information.
	//
	// Units. Again, strings shorter than 8 characters were padded
	// with blanks; remove those.
	//
	TableRecord& keys = itsTableDesc.rwColumnDesc(colname).rwKeywordSet();
	String unitstr(tunit(icol));
	unitstr = unitstr.before(trailing);
	if (! unitstr.empty()) {
	  keys.define("UNIT", unitstr);
	}

	//
	// Attach QuantumUnits and MEASINFO.
	//
	for (uInt ikey=0; ikey<itsNrMSKs; ikey++) {
	  if (itsgotMSK(ikey) && (itsMSKC(ikey)==colname)) {
	    if (itsMSKN(ikey) == "QuantumUnits") {
	      keys.define ("QuantumUnits", toStringArray(itsMSKV(ikey)));
	      itsgotMSK(ikey) = False;
	    } else if (itsMSKN(ikey) == "MEASINFO") {
	      TableRecord measrec;
	      String str = itsMSKV(ikey);
	      Int pos = str.index('"');
	      Bool err = pos < 0;
	      if (!err) {
		String type = str.before(pos);
		measrec.define ("type", downcase(type));
		String ref = str.after(pos);
		if (ref.length() < 8) {
		  err = False;
		} else {
		  String reftp = ref.before(6);
		  ref = ref.after(6);
		  if (reftp == "FixRef") {
		    measrec.define ("Ref", ref);
		  } else {
		    measrec.define ("VarRefCol", ref);
		  }
		}
	      }
	      if (err) {
		cerr << "Error: column " << icol
		     << " has untranslatable MEASINFO " << str << endl
		     << " This should NEVER happen " << endl;
	      } else {
		keys.defineRecord ("MEASINFO", measrec);
		itsgotMSK(ikey) = False;
	      }
	    }
	  }
	}
    }	//		end of loop over columns

    //
    // For a MeasurementSet main table we will work with tiled storage
    // managers. Define the hypercolumns needed.
    //
    String extname(MSBinaryTable::extname());
    extname = extname.before(trailing);
    if (extname == "MAIN") {
	//
	// Define the tiled hypercube for the data and flag columns.
	//
        String nameSuffix;
	if (! itsTableDesc.isColumn (MS::columnName(MS::DATA))) {
	    nameSuffix = "_COMPRESSED";
	}
	itsTableDesc.defineHypercolumn(
	    "TiledData",3,
	    stringToVector(MS::columnName(MS::DATA) + nameSuffix + "," +
			   MS::columnName(MS::FLAG)));
	//
	// Define tiled hypercube for SIGMA_SPECTRUM and/or WEIGHT_SPECTRUM.
	// 
	uInt nrs = (itsTableDesc.isColumn(MS::columnName(MS::SIGMA_SPECTRUM))
		    ? 1 : 0);
	uInt nrw = (itsTableDesc.isColumn(MS::columnName(MS::WEIGHT_SPECTRUM))
		    ? 1 : 0);
	if (nrs+nrw > 0) {
	    Vector<String> vec(nrs+nrw);
	    if (nrs > 0) {
	      vec(0) = MS::columnName(MS::SIGMA_SPECTRUM);
	    }
	    if (nrw > 0) {
	      vec(nrs) = MS::columnName(MS::WEIGHT_SPECTRUM);
	    }
	    itsTableDesc.defineHypercolumn ("TiledWS", 3, vec);
	}
    }
}


//
// Convert the MS-specific keywords in the FITS binary table extension
// header to a TableRecord (itsKwSet).
//
void MSBinaryTable::convertMSKeywords()
{
    for (uInt ikey=0; ikey<itsNrMSKs; ikey++) {
	if (itsgotMSK(ikey)) {
	    if (itsMSKC(ikey) == " ") {
		//
		// Convert to a table keyword.
		//
///		cout << "defining table keyword " << itsMSKN(ikey) << endl;
	        defineKeyword (itsKwSet, itsMSKN(ikey), itsMSKV(ikey));
	    } else {
		//
		// Convert to a column keyword.
		//
///		cout << "defining column keyword " << itsMSKC(ikey)
///		     << "." << itsMSKN(ikey) << endl;
	        defineKeyword
                     (itsTableDesc.rwColumnDesc(itsMSKC(ikey)).rwKeywordSet(),
		      itsMSKN(ikey), itsMSKV(ikey));
	    }
	}
    }
}


void MSBinaryTable::defineKeyword (TableRecord& record,
				   const String& name,
				   const String& value)
{
  if (value.length() > 0  &&  value[0] == '[') {
    record.define (name, toStringArray(value));
  } else {
    record.define (name, value);
  }
}


TableDesc MSBinaryTable::tableDescCompress (const TableDesc& tdesc,
					    const String& extname)
{
  TableDesc tdout (tdesc);
  Vector<String> cols = stringToVector ("FLOAT_DATA,DATA,LAG_DATA,"
					"MODEL_DATA,COMPRESSED_DATA,"
					"SIGMA_SPECTRUM,WEIGHT_SPECTRUM");
  if (extname == "MAIN") {
    for (uInt i=0; i<cols.nelements(); i++) {
      if (tdesc.isColumn (cols(i))) {
	MSTableImpl::addColumnCompression (tdout, cols(i), True, "");
      } else if (tdesc.isColumn (cols(i) + "_COMPRESSED")) {
	addDecompressedColumn (tdout, cols(i),
			       tdesc[cols(i) + "_COMPRESSED"],
			       False);
      }
    }
  }
  return tdout;
}

TableDesc MSBinaryTable::tableDescDecompress (const TableDesc& tdesc,
					      const String& extname,
					      Bool decompress)
{
  TableDesc tdout (tdesc);
  if (extname == "MAIN") {
    Regex cmprRegex ("_COMPRESSED$");
    for (uInt i=0; i<tdesc.ncolumn(); i++) {
      const ColumnDesc& cd = tdesc[i];
      String name = cd.name();
      name = name.before (cmprRegex);
      if (name != cd.name()) {
	addDecompressedColumn (tdout, name, cd, decompress);
      }
    }
  }
  return tdout;
}

void MSBinaryTable::addDecompressedColumn (TableDesc& tdout,
					   const String& name,
					   const ColumnDesc& cd,
					   Bool decompress)
{
  Bool flag = False;
  if (tdout.isColumn(name + "_SCALE")  &&  tdout.isColumn(name + "_OFFSET")) {
    Int dtype = cd.trueDataType();
    if (dtype == TpArrayInt) {
      tdout.addColumn (ArrayColumnDesc<Complex> (name,
						 "",
						 cd.dataManagerType(),
						 cd.dataManagerGroup(),
						 cd.ndim(),
						 cd.options()));
      flag = True;
    } else if (dtype == TpArrayShort) {
      tdout.addColumn (ArrayColumnDesc<Float> (name,
					       "",
					       cd.dataManagerType(),
					       cd.dataManagerGroup(),
					       cd.ndim(),
					       cd.options()));
      flag = True;
    }
  }
  if (flag) {
    if (cd.shape().nelements() > 0) {
      ColumnDesc& cdesc = tdout.rwColumnDesc (name);
      cdesc.setShape (cd.shape());
    }
    tdout.removeColumn (cd.name());
    tdout.removeColumn (name + "_SCALE");
    tdout.removeColumn (name + "_OFFSET");
    if (!decompress) {
      MSTableImpl::addColumnCompression (tdout, name, True, "");
    } else {
      SimpleOrderedMap<String,String> old2new("");
      old2new.define (cd.name(), name);
      tdout.adjustHypercolumns (old2new, True);
    }
  }
}


Array<String> MSBinaryTable::toStringArray (const String& value) const
{
  // The string is written by MSToFITS as:
  // [shape]val1"val2"..."valn
  if (value.length() > 1  &&  value[0] == '[') {
    // First get the shape.
    String val = value;
    val = val.after(0);
    Int pos = val.index(']');
    if (pos >= 0) {
      Vector<String> shpstr = stringToVector (val.before(pos), ',');
      IPosition shape(shpstr.nelements());
      for (uInt i=0; i<shpstr.nelements(); i++) {
	istringstream istr(shpstr(i));
	istr >> shape(i);
      }
      // Now get all values.
      // Its number should match the shape.
      Vector<String> valstr = stringToVector (val.after(pos), '"');
      if (Int(valstr.nelements()) == shape.product()) {
	return valstr.reform (shape);
      }
    }
  }
  cerr << "Could not interpret string array value: " << value << endl;
  return Array<String>();
}
