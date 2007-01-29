//# <MSToFITS.cc>: Class to write a MeasurementSet lossless to a FITS file
//# Copyright (C) 1996,1997,1999,2000,2001,2002,2004
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
//# $Id: MSToFITS.cc,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#include <MSToFITS.h>

#include <casa/sstream.h>

#include <casa/Arrays/ArrayMath.h>        //# indgen(..)
#include <casa/Arrays/ArrayUtil.h>        //# stringToVector(...)
#include <fits/FITS/fits.h>               //# FitsKeywordList
#include <fits/FITS/hdu.h>                //# PrimaryArray
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/TableColumn.h>
#include <measures/TableMeasures/TableMeasColumn.h>
#include <measures/TableMeasures/TableMeasDescBase.h>
#include <casa/Utilities/Assert.h>

#include <casa/Containers/RecordFieldWriter.h> //# MultiRecordFieldWriter


#include <casa/namespace.h>
//
// Constructor.
//
// Fill the attributes of the converter itself:
// MeasurementSet itsMS;              //# input MeasurementSet
// FitsOutput*    itsFitsOutput;      //# output FITS file
// Vector<String> itsTableName;       //# tables to be handled
//
MSToFITS::MSToFITS (const MeasurementSet& aMeasurementSet,
		    FitsOutput* aFitsOutput) :
    itsMS(aMeasurementSet),
    itsFitsOutput(aFitsOutput)
{
    cout << "MSToFITS construction started." << endl;
    //
    // The subtables are stored as keywords in the main table.
    //
    const TableRecord& keywordSet   = itsMS.keywordSet();
    const RecordDesc&  keywordDesc  = keywordSet.description();
    const uInt         nrOfKeywords = keywordSet.nfields();

    //
    // Use the number of keywords as the first guess of the number of
    // subtables.
    //
    itsTableName.resize(nrOfKeywords+1);

    //
    // Loop through the keywords, pick up the names of the ones that
    // describe a table, and add them to the name vector.
    //
    uInt nrOfTables = 0;
    for (uInt iKey=0; iKey<nrOfKeywords; iKey++) {
	if (keywordDesc.isTable(iKey)) {
	    itsTableName(nrOfTables) = keywordDesc.name(iKey);
	    nrOfTables++;
	}
    }

    //
    // Close the vector with the name of the main table itself and
    // resize the vector properly.
    //
    itsTableName(nrOfTables) = "MAIN";
    nrOfTables++;
    itsTableName.resize(nrOfTables,True);

    cout << endl << "  Tables to be handled: " << endl;
    cout << itsTableName << endl;
    cout << endl << "MSToFITS construction ended." << endl;
}

//
// Destructor.
//
MSToFITS::~MSToFITS ()
{
    // empty
}

//
// Do the actual conversion.
//
Bool MSToFITS::convert ()
{
    cout << "MSToFITS::convert() started." << endl;
    //
    // Loop over all tables.
    //
    for (uInt it=0; it<itsTableName.nelements(); it++) {

	const String& tableName = itsTableName(it);
	cout << endl << "  table " << tableName << ":" << endl;

	//
	// Fill the attributes for the current table:
	//
	// Record      itsExtraKeywords;   //# table-specific keywords
	// uInt        itsNrOfRows;        //# nr of rows in the table
	// ROTableRow  itsTableRow;
	// FieldCopier itsHandler;
	// RecordDesc  itsFITSDescription; //# column description
	// Record      itsMaxOutLengths;   //# max string length per column
	// Record      itsFITSUnits;       //# units
	//
	if (tableName == "MAIN") {
	    init(itsMS, tableName);
	} else {
	    init(itsMS.keywordSet().asTable(tableName), tableName);
	}

	//
	// Ignore empty tables.
	//
	const Int length = rowLength(itsFITSDescription, itsMaxOutLengths);
	if (length == 0) {
	    cout << "  The table is empty, and will be ignored." << endl;
	} else {
	    cout << "  The table has rows of " << length << " bytes." << endl;

	    //
	    // Create the writer.
	    //
	    FITSTableWriter aWriter (itsFitsOutput,
				     itsFITSDescription,
				     itsMaxOutLengths,
				     itsNrOfRows,
				     itsExtraKeywords,
				     itsFITSUnits,
				     False);
	    
	    //
	    // Create the field handlers.
	    //
	    MultiRecordFieldWriter aCopier;
	    itsHandler.setupCopiers(aCopier,
				    aWriter.row(),         //# output record
				    itsTableRow.record()); //# input record
	    
	    //
	    // Read, copy and write the rows.
	    //
	    for (uInt ir=0; ir<itsNrOfRows; ir++) {
		itsTableRow.get(ir);
		aCopier.copy();
		aWriter.write();
	    }
	}
    }
    cout << "MSToFITS::convert() ended." << endl << endl;
    return True;
}

//
// Determine itsFITSDescription, itsMaxOutLengths, itsFITSUnits.
//
void MSToFITS::init (const Table& aTable, const String& aTableName)
{
    //
    // Get a read-only table row and the number of rows, 
    //
    itsNrOfRows = aTable.nrow();
    itsTableRow = ROTableRow(aTable);

    //
    // Compose record itsExtraKeywords.
    //
    // This contains four kinds of FITS keywords:
    // - reserved FITS keywords for extension headers (EXT...),
    // - FITS keywords derived from the Table keyword,
    // - FITS keywords derived from the column keywords, and
    // - FITS keywords derived from the storage management info.
    //
    extraKeywords(aTable, aTableName);

    //
    // Fill the Records maxLengths and units, and the TableRecord
    // record.
    //
    // maxLengths contains the maximum field lengths for String-type
    // columns and the actual field shapes for array-type columns,
    // i.e.  everything except non-String scalar fields will have an
    // entry.
    //
    // Arrays of Strings are converted to scalars and handled as such.
    // The shape of array fields must be constant in a column.
    //
    Record maxLengths = scanTable(aTable);

    //
    // units contains all the unit strings for the columns that have a
    // keyword UNIT.
    //
    Record units = unitRecord(aTable);
    //
    // record is the record-view of itsTableRow.
    //
    const TableRecord& record = itsTableRow.record();

    //
    // Set up a handler that knows how to copy Table fields to FITS
    // fields.
    //
    // First clear itsHandler, itsFITSDescription, itsFITSUnits and
    // itsMaxOutLengths.
    //
    itsHandler.clear();
    itsFITSDescription = RecordDesc();
    itsFITSUnits       = Record();
    itsMaxOutLengths   = Record();

    //
    // Compose the output description for the current table.
    //
    itsHandler.setupFieldHandling(itsFITSDescription,
				  itsMaxOutLengths,
				  itsFITSUnits,
				  record.description(), 
				  maxLengths,
				  units);

    //
    // Some column properties are kept in the MS as column keywords,
    // like units and measure info. Units are stored
    // in the Record "units" by unitRecord(...) and from there in
    // Records itsFITSUnits, the others are stored in itsExtraKeywords
    // by the extraKeywords(...).
    //
    // Other column properties are kept directly in the ColumnDesc
    // itself. Some of these are transfered to the ROTableRow object
    // "record" from which setupFieldHandling(...) makes
    // itsFITSDescription, such as field name, data type and shape.
    //
    // Some column properties in the ColumnDesc are not known to the
    // ROTableRow object, such as comment and direct/indirect storage
    // mode. The storage properties are encoded as extra FITS keywords
    // in extraKeywords(...).
    //
    // The column comment can be translated into a standard FITS
    // comment attached to the FITS keyword containing the column
    // name, as follows:
    //
    for (uInt i=0; i<itsFITSDescription.nfields(); i++) {
	const String& colComment = 
	    aTable.tableDesc().columnDesc(i).comment();
	if (!colComment.empty()) {
	    itsFITSDescription.setComment(i, colComment);
	}
    }

    cout << " MSToFITS::init(...) ended." << endl;
}

//
// Assemble all values of the column keywords UNIT in a record.
//
Record MSToFITS::unitRecord (const Table& aTable)
{
    Record theUnits;
    //
    // Assemble all column names in a vector of strings.
    // Loop over all table columns.
    //
    const Vector<String>& cols(aTable.tableDesc().columnNames());
    for (uInt ic=0; ic<cols.nelements(); ic++) {
	//
	// Get the keywords for this column.
	//
	const TableRecord& keywordSet
	    = aTable.tableDesc().columnDesc(cols(ic)).keywordSet();
	//
	// Add any UNIT keyword value to theUnits record in a field
	// with the name of this column.
	//
	if (keywordSet.isDefined("UNIT")) {
	    theUnits.define(cols(ic),  keywordSet.asString("UNIT"));
	}
    }
    return theUnits;
}

Int MSToFITS::rowLength (const RecordDesc& description,
			 const Record& maxStringLengths)
{
    const uInt nfields = description.nfields();
    Int    sizeInBytes = 0;
    for (uInt ic=0; ic < nfields; ic++) {
	Int size = 1;
	switch (description.type(ic)) {
	case TpArrayBool: 
	    size = description.shape(ic).product();
	case TpBool:
	    sizeInBytes += size*1;
	    break;
	    
	case TpArrayUChar:
	    size = description.shape(ic).product();
	case TpUChar:
	    sizeInBytes += size*1;
	    break;
	    
	case TpArrayShort:
	    size = description.shape(ic).product();
	case TpShort:
	    sizeInBytes += size*2;
	    break;
	    
	case TpArrayInt:
	    size = description.shape(ic).product();
	case TpInt:
	    sizeInBytes += size*4;
	    break;
	    
	case TpArrayFloat:
	    size = description.shape(ic).product();
	case TpFloat:
	    sizeInBytes += size*4;
	    break;
	    
	case TpArrayDouble:
	    size = description.shape(ic).product();
	case TpDouble:
	    sizeInBytes += size*8;
	    break;
	    
	case TpArrayComplex:
	    size = description.shape(ic).product();
	case TpComplex:
	    sizeInBytes += size*8;
	    break;
	    
	case TpArrayDComplex:
	    size = description.shape(ic).product();
	case TpDComplex:
	    sizeInBytes += size*16;
	    break;
	    
	case TpString:
	{
	    Int stringlen = FITSTableWriter::DefaultMaxStringSize;
	    Int which = maxStringLengths.fieldNumber(description.name(ic));
	    if (which >= 0) {
		maxStringLengths.get(which, stringlen);
	    }
	    sizeInBytes += stringlen;
	}
	break;
	
	case TpArrayString:
	    throw(AipsError("Arrays of strings are not yet supported"));
	    break;
	default:
	    throw(AipsError("Invalid type"));
	}
    }
    return sizeInBytes;
}


uInt MSToFITS::extraKeywords (const Table& aTable, const String& aTableName)
{
    //
    // Start with an empty Record.
    //
    itsExtraKeywords = Record();

    //
    // Store the table name.
    //
    itsExtraKeywords.define("EXTNAME", aTableName);
    itsExtraKeywords.setComment("EXTNAME", "WSRT AIPS++ MS main or sub table");

    //
    // Store the table's version number. That is either copied from
    // the AIPS++ Table keyword MS_VERSION or set to zero in case there
    // is no version keyword.
    //
    Int version = 0;
    const TableRecord& keywordSet = aTable.keywordSet();
    if (keywordSet.isDefined("MS_VERSION")) {
        Float vers = keywordSet.asFloat("MS_VERSION");
	version = Int(100 * vers + 0.5);
    }
    itsExtraKeywords.define("EXTVER", version);
    itsExtraKeywords.setComment("EXTVER", "Version");

    //
    // Translate the AIPS++ Table keywords into FITS keywords.
    //
    const MSFITSKeyRecord& tableKeys = tableKeywords(aTable);
    itsExtraKeywords.merge(tableKeys);
    cout << "extraKeywords() ended" << endl;
    return itsExtraKeywords.nfields();
}


MSFITSKeyRecord MSToFITS::tableKeywords (const Table& aTable)
{
    //
    // Create an empty record.
    //
    MSFITSKeyRecord anMSKRecord;

    //
    // Add the "pseudo" table keywords for storing the table.info
    // content (TYPE, SUBTYPE and README).
    //
    anMSKRecord.add(aTable.tableInfo());

    //
    // Add the "pseudo" table keywords containing the size information
    // to be used for choosing the optimum storage-management scheme
    // when the MeasurementSet is reconstructed.
    //
    anMSKRecord.add("NROWS",String::toString(itsNrOfRows));

    if (itsTableRow.record().isDefined("DATA")) {
	itsTableRow.get(0);
	ostringstream valbuf2;
	valbuf2 << itsTableRow.record().shape("DATA");
	anMSKRecord.add("DATASHAPE",String(valbuf2));
    }

    //
    // Add the normal table keywords.
    //
    const TableRecord& keywordSet = aTable.keywordSet();
    const uInt       nrOfKeywords = keywordSet.nfields();
    for (uInt ik=0; ik<nrOfKeywords; ik++) {
	if (keywordSet.description().isTable(ik)) {
	    //
	    // Ignore table-type keywords; they have already been
	    // handled by the MSToFITS constructor.
	    //
	} else {
	    String name = keywordSet.name(ik);
	    if (name == "MS_VERSION") {
		//
		// Ignore a MS_VERSION keyword; it has already been
		// handled by extraKeywords().
		//
	    } else {
	        addKeyToRecord (anMSKRecord, keywordSet, ik, " ");
	    }
	}
    }

    const TableDesc& tableDesc = aTable.tableDesc();
    const uInt     nrOfColumns = tableDesc.ncolumn();

    for (uInt ic=0; ic<nrOfColumns; ic++) {
      if (aTable.isColumnStored(ic)) {
	const ColumnDesc&  columnDesc = tableDesc.columnDesc(ic);
	const String&      columnName = columnDesc.name();
	const TableRecord& keywordSet = columnDesc.keywordSet();
	uInt             nrOfKeywords = keywordSet.nfields();

	//
	// Translate the "real" column keywords.
	//
	for (uInt ik=0; ik<nrOfKeywords; ik++) {
	    const String& name = keywordSet.name(ik);
	    if (name == "MEASINFO") {
		//
		// Handle Measure reference code in a special way.
	        // The reference code is variable or fixed.
		//
	        ROTableMeasColumn tmcol (aTable, columnName);
		const TableMeasDescBase& tmdesc = tmcol.measDesc();
		String val = tmdesc.type() + '"';
		if (tmdesc.isRefCodeVariable()) {
		    val += "VarRef_" + tmdesc.refColumnName();
		} else {
		    val += "FixRef_" + tmdesc.refType(tmdesc.getRefCode());
		}
		anMSKRecord.add(name,val,columnName);
	    } else {
	        addKeyToRecord (anMSKRecord, keywordSet, ik, columnName);
	    }
	}

	//
	// Add the "pseudo" TDIM keyword for the shapes of String
	// Arrays and single-element Array fields.
	//
	// This is a temporary fix until FITS2Table2.cc does handle
	// these arrays properly by defining a proper TDIM keyword.
	//
	if (columnDesc.isArray()) {
	    if (columnDesc.dataType() == TpString) {
	        cout << " String-array column ";
	    } else {
	        cout << " array column ";
	    }
	    cout << columnName;
	    //
	    // Start with the shape from the column description.
	    //
	    IPosition ashape = columnDesc.shape();

	    //
	    // Get the actual shape of the cells. Take it from the
	    // first row.
	    //
	    if (itsNrOfRows > 0) {
		ROTableColumn rocol(aTable, ic);
		if (rocol.isDefined(0)) {
		    ashape = rocol.shape(0);
		}
	    }
	    cout << " has shape = " << ashape << endl;
	    Int nelem = ashape.product();
	    if (nelem==0 || nelem==1) {
		if (nelem==0) {
		    cout << "   (is empty)" << endl;
		    ashape.resize(1);
		    ashape(0) = 0;
		} else {
		    cout << "   (has only 1 element)" << endl;
		}
		anMSKRecord.add(ashape,columnName);
	    } else if (columnDesc.dataType() == TpString) {
		anMSKRecord.add(ashape,columnName);
	    }

	} else {
	    cout << " scalar column " << columnName << endl;
	}
	
	//
	// Add the "pseudo" column keywords for storage management.
	//
	if (columnDesc.options() & ColumnDesc::Direct == ColumnDesc::Direct) {
	    // the column has the Direct flag set
	    anMSKRecord.add("OPTIONS","DIRECT",columnName);
	}
      }
    }
    return anMSKRecord;
}


void MSToFITS::addKeyToRecord (MSFITSKeyRecord& anMSKRecord,
			       const TableRecord& keywordSet,
			       Int index, const String& columnName)
{
    String name = keywordSet.name(index);
    DataType dtype = keywordSet.type(index);
    switch (dtype) {
    case TpString:
        anMSKRecord.add (name, keywordSet.asString(index), columnName);
	break;
    case TpArrayString:
      {
	// First put the shape of the array (enclosed in []).
	Array<String> arr = keywordSet.asArrayString (index);
	const IPosition& shape = arr.shape();
	String str ("[");
	for (uInt i=0; i<shape.nelements(); i++) {
	  if (i > 0) {
	    str += ',';
	  }
	  str += String::toString(shape(i));
	}
	str += ']';
	// Put the strings separated by ".
	Bool deleteIt;
	const String* buf = arr.getStorage (deleteIt);
	for (uInt i=0; i<arr.nelements(); i++) {
	  if (i > 0) {
	    str += '"';
	  }
	  str += buf[i];
	}
	arr.freeStorage (buf, deleteIt);
        anMSKRecord.add (name, str, columnName);
        break;
      }
    default:
        throw (AipsError ("MSToFITS: only String keywords are supported"));
    }
}


Record MSToFITS::scanTable(const Table &table)
{
    Record retval;

    Vector<String> columnsToRead;
    TableDesc desc = table.tableDesc();

    uInt ncol = desc.ncolumn();
    for (uInt i=0; i<ncol; i++) {
      if (table.isColumnStored (i)) {
        uInt which = columnsToRead.nelements();
        ColumnDesc coldesc = desc[i];
	if (coldesc.isArray()) {
	    if (coldesc.dataType() == TpArrayString ||
		coldesc.dataType() == TpString) {
		// Arrays of Strings are not yet supported in our
		// FITS writer, so this is part of an attempt to deal with it
		columnsToRead.resize(which+1, True);
		columnsToRead(which) = coldesc.name();
		retval.define(coldesc.name(), Int(0));
	    } else if (coldesc.isFixedShape()) {
	        retval.define(coldesc.name(), coldesc.shape().asVector());
	    } else {
	        columnsToRead.resize(which+1, True);
		columnsToRead(which) = coldesc.name();
		Vector<Int> emptyShape;
		retval.define(coldesc.name(), emptyShape);
	    }
	  } else if (coldesc.dataType() == TpString) {
	    columnsToRead.resize(which+1, True);
	    columnsToRead(which) = coldesc.name();
	    retval.define(coldesc.name(), Int(0));
	  }
      }
    }

    ROTableRow reader(table, columnsToRead);
    uInt nrow = reader.table().nrow();

    // Figure out which fields in retval map to which columns
    // in reader.record().
    Block<Int> retvalMap(columnsToRead.nelements());
    Block<Int> readerMap(columnsToRead.nelements());
    for (uInt i=0; i<retvalMap.nelements(); i++) {
        readerMap[i] = reader.record().description().fieldNumber(
							 columnsToRead(i));
	retvalMap[i] = retval.description().fieldNumber(columnsToRead(i));
	AlwaysAssert(retvalMap[i] >= 0, AipsError);
	AlwaysAssert(readerMap[i] >= 0, AipsError);
    }

    uInt nfields = columnsToRead.nelements();
    String tmpstring;
    Array<String> tmpArrString;
    Vector<Int> tmpvec;

    for (uInt row=0; row<nrow; row++) {
        reader.get(row);
	for (uInt field=0; field < nfields; field++) {
	    DataType type = reader.record().description().type(readerMap[field]);
	    if (type == TpString) {
	        // Interested in length
	        reader.record().get(readerMap[field], tmpstring);
		Int newlength = tmpstring.length();
		// It was initialized to zero, so the following will always work.
		Int oldlength;
		retval.get(retvalMap[field], oldlength);
		if (newlength > oldlength) {
		    retval.define(retvalMap[field], newlength);
		}
	    } else if (type == TpArrayString) {
		// we're going to use the Array << operator to write this
		// to a stringstream, so, do that here 
		ostringstream ost;
		reader.record().get(readerMap[field], tmpArrString);
		ost << tmpArrString;
		uInt oldlength;
		retval.get(retvalMap[field], oldlength);
		if (ost.str().size() > oldlength) {
		    retval.define(retvalMap[field], Int(ost.str().size()));
		}
	    } else if (isArray(type)) {
	        // It's an array, Interested in shape
	        IPosition tmpshape = reader.record().shape(readerMap[field]);
		if (row == 0) {
		    retval.define(retvalMap[field], tmpshape.asVector());
		} else {
		    // Verify that the shape hasn't changed
		    retval.get(retvalMap[field], tmpvec);
		    uInt n = tmpshape.nelements();
		    if (tmpvec.nelements() != n) {
			ostringstream os;
			os << "\nscanTable(const Table& table) - "
			   << "Variable shaped column, "
			   << reader.record().description().name(readerMap[field])
			   << ", in table " << table.tableName() 
			   << " - this is not yet supported.\n";
			String errorMessage(os);
			throw(AipsError(errorMessage));
		    }
		    for (uInt i=0; i<n; i++) {
			if (tmpvec(i) != tmpshape(i)) {
			    ostringstream os;
			    os << "\nscanTable(const Table& table) - "
			       << "Variable shaped column, "
			       << reader.record().description().name(readerMap[field])
			       << ", in table " << table.tableName() 
			       << " - this is not yet supported.\n";
			    String errorMessage(os);
			    throw(AipsError(errorMessage));
			}
		    }
		}
	    }
	}
    }
    return retval;
}
