//# MSToFITS.h: Class to write a MeasurementSet lossless to a FITS file
//# Copyright (C) 1996,1997,1999,2000
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
//# $Id: MSToFITS.h,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_MSTOFITS_H
#define APPSGLISH_MSTOFITS_H

#include <NFieldHandlers.h>                //# RecordFieldHandler
#include <MSFITSKeyRecord.h>

#include <casa/aips.h>
#include <tables/Tables/TableRow.h>
#include <casa/Arrays/Vector.h>
#include <fits/FITS/fitsio.h>
#include <ms/MeasurementSets/MeasurementSet.h>

#include <fits/FITS/FITSTable.h>          //# FITSTableWriter

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class MultiRecordFieldWriter;
} //# NAMESPACE CASA - END


// <summary>
// Write a MeasurementSet lossless to a FITS file.
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class=MeasurementSet>MeasurementSet</linkto>
//   <li> <linkto class=FITSTableWriter>FITSTableWriter</linkto>
// </prerequisite>

// <etymology>
// </etymology>

// <synopsis>
//
// MSToFITS is a class that enables lossless conversion from a
// WSRT-type AIPS++ MeasurementSet into a binary-table FITS file. All
// information in the MeasurementSet is transferred to the FITS file,
// so that the FITS file can be converted back into the original
// MeasurementSet.
//
// MSToFITS relies heavily on the class <linkto class=FITSTableWriter>
// FITSTableWriter </linkto>: it assumes that the preformatted FITS
// file was created by its function makeWriter(...) and does all
// further access to that file via a FITSTableWriter object. That
// object takes care of the proper translation of datatype- and
// shape-information from the AIPS++-table descriptions into FITS
// binary-table required and reserved keywords.
//
// The class has only two active public functions:
// <ul>
//
//    <li> The constructor creates an MSToFITS converter for an
//    existing MeasurementSet and a preformatted FITS file. The FITS
//    file already contains a "null" primary HDU, proper for the case
//    where all the data are in extensions.
//
//    <li> The function convert() converts the MeasurementSet table
//    for table, ending with the main table containing the measurement
//    data. Each table is "copied" into its own FITS binary table
//    extension. In principle this is a straight copy, but because of
//    the difference in format conventions between AIPS++ and FITS
//    some transformations are necessary and some (temporary)
//    restrictions must be observed:
//
//    <ul>
//
//      <li> Character string table columns are stored in fixed-size
//      fields, where the size is the maximum size found in the column.
//
//      <li> Vectors of character strings are converted to
//      comma-separated lists of strings, and are then handled as
//      string scalars.
//
//      <li> Variable-shape array columns are allowed in a limited
//      sense. The shape is then determined from the input table, but
//      an exception will be thrown if the array shape is not constant
//      over the column.
//
//      <li> The name of the AIPS++ table, and its table and column
//      keywords are transformed into FITS keywords, as described
//      below for the functions extraKeywords() and tableKeywords().
//      At present, all FITS keywords have String-type values only.
//      An exception is thrown if a value cannot be written as a String.
//
//   </ul>
//
// </ul>
//
//  </synopsis>

// <example>
// <srcblock>
// // Open the Measurementset to be converted.
// MeasurementSet ms(directoryName, Table::Old);
// // Create a FITS file with filled-in primary HDU.
// FitsOutput* fits = FITSTableWriter::makewriter(fileName);
// // Create the converter.
// MSToFITS converter(ms,fits);
// // Run the converter.
// converter.convert();
// </srcblock>
// </example>

// <motivation>
//  A new archiving format for WSRT data was sought for. We choose to
//  work with AIPS++ MeasurementSets and archive them in the form of
//  binary-table FITS files.
// </motivation>

// <todo asof="1991/12/19">

//   <li> Handle variable-shape array columns properly, using the
//   advanced FITS convention for binary tables. (??)

//   <li> Handle (arrays of) strings properly, using the advanced FITS
//   convention for binary tables. (??)

//   <li> Alleviate the restrictions on the types of AIPS++ keyword
//   values.

// </todo>

class MSToFITS
{
public:
    //
    // The only constructor is from a MeasurementSet and an already
    // opened FITS file with filled-in primary HDU.  The list of
    // subtables to be converted is deduced from the keywords in the
    // main table of the MeasurementSet.
    //
    MSToFITS (const MeasurementSet& aMeasurementSet,
	      FitsOutput* aFitsOutput);

    //
    // Destruct; nothing special for now.
    //
    ~MSToFITS ();

    //
    // Do the actual conversion to a FITS file.
    //
    Bool convert ();
    
private:
    //
    // Attributes of the converter itself:
    //
    MeasurementSet itsMS;              //# input MeasurementSet
    FitsOutput*    itsFitsOutput;      //# output FITS file
    Vector<String> itsTableName;       //# tables to be handled

    //
    // Attributes for the current table:
    //
    Record      itsExtraKeywords;   //# table-specific keywords
    uInt        itsNrOfRows;        //# nr of rows in the table
    ROTableRow  itsTableRow;
    FieldCopier itsHandler;
    RecordDesc  itsFITSDescription; //# column description
    Record      itsMaxOutLengths;   //# max string length per column
    Record      itsFITSUnits;       //# units

    //
    // Private functions to forbid copying and assignment.
    // <group name=forbid>
    //
    MSToFITS            (const MSToFITS& aMSToFITS);
    MSToFITS& operator= (const MSToFITS& aMSToFITS);    
    //
    // </group>

    //
    // Private helper function for convert() to fill the attributes
    // for the specified table.
    //
    void init (const Table& aTable,
	       const String& aTableName);

    //
    // Private helper function for convert() to determine the length
    // of a row in the table with the given description.
    //
    Int rowLength (const RecordDesc &description,
		   const Record& maxStringLengths);

    //
    // Private helper function for init(...) to assemble all values of
    // the column keywords UNIT in a record. The record fields will
    // have the names of the corresponding table columns.
    //
    Record unitRecord (const Table& aTable);

    //
    // Private helper function for init(...) to compose the extra FITS
    // keywords for the specified table. It returns the number of
    // keywords created.
    //
    // We build up the Record itsExtraKeywords containing the
    // name-value pairs of the wanted FITS keywords. There are four
    // types of keywords per table (see also further down):
    //
    //  <li> reserved FITS keywords for extension headers (EXT...),
    //  <li> FITS keywords derived from the Table keywords, and
    //  <li> FITS keywords derived from the column keywords in the
    //  Table.
    //  <li> FITS keywords derived from the storage management info.
    //
    // EXTNAME will contain the name of the AIPS++ subtable (or
    // "MAIN").  EXTVER will contain the version number from the
    // AIPS++ table keyword VERSION or will be set to zero when there
    // is no version keyword.
    //
    uInt extraKeywords (const Table& aTable,
			const String& aTableName);

    //
    // Private helper function for extraKeywords(...) to extract the
    // table keywords of the specified table and add them together in
    // a MSFITSKeyRecord.
    //
    // Each table keyword is translated into a set of two or three
    // FITS keywords:
    //
    // <li> MSKN# giving the name of the table keyword, and
    // <li> MSKV# giving the value of the table keyword as a ASCII string.
    // <li> MSKC# (optional) giving the associated column name, if any.
    // # is the MSK keyword index, a unique number for the current table.
    //
    // The VERSION table keyword is ignored here, because that is
    // taken care of in extraKeywords(...) itself.
    //
    // The UNIT column keywords are ignored here, because they are
    // taken care of in the function unitRecord(...).
    //
    // For every column data-storage information will be stored as if
    // they were given as column keywords:
    //  <li> OPTIONS = "DIRECT" if the Direct-storage flag is set
    //
    MSFITSKeyRecord tableKeywords (const Table& aTable);

    // Add the contents of a keyword to the record.
    // It can only handle string keywords (scalar or array).
    void addKeyToRecord (MSFITSKeyRecord& anMSKRecord,
			 const TableRecord& keywordSet,
			 Int index, const String& columnName);

    // Scan the table to see what kind of data is in it.
    static Record scanTable(const Table &table);
};


#endif
