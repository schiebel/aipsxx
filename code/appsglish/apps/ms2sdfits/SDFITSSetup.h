//# SDFITSSetup.h: SDFITSSetup holds and initializes the things that ms2sdfits needs
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
//# $Id: SDFITSSetup.h,v 19.5 2004/11/30 17:50:09 ddebonis Exp $

#ifndef APPSGLISH_SDFITSSETUP_H
#define APPSGLISH_SDFITSSETUP_H

#include <casa/aips.h>
#include <casa/Containers/RecordDesc.h>
#include <casa/Containers/Record.h>
#include <casa/Containers/Block.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class RecordInterface;
class Table;
class MeasurementSet;
class MSReader;
class FITSTableWriter;
class MultiRecordFieldWriter;
class RecordFieldHandler;
class FieldCalculator;
} //# NAMESPACE CASA - END


// <summary>
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// SDFITSSetup is a class which holds all together all the data and
// operations which operate on the data which are necessary to convert
// a Single Dish AIPS++ MeasurementSet into a SDFITS file.
//
// The goal of this class is to make it relatively straightforward to
// incrementally change the set of fields which are handled without affecting
// the rest of the code. Roughly speaking the class is set-up as follows:
// <ul>
//    <li> A set of columns that we're unilaterally uninterested in copying
//         over is created for each subtable (setup_blockers()). Generally
//         these are interferometry related columns (e.g., UVW).
//    <li> Every remaining field is marked as unhandled (isField[table] = False).
//    <li> For the remaining (handled) fields, the maximum string lengths
//         and shape of array columns is determined with MSReader::scanTable.
//         At present an exception will be thrown if array columns are not
//         constant shaped.
//    <li> The "special" table field handlers are setup for the sub-tables.
//         A field handler is a class that handles the copying of fields from
//         an input record to an output record. A handler marks (by setting a
//         boolean) which fields it handles, the idea being that each input field
//         will be considered by more and more general handlers until one is
//         found to handle it.
//         The special handler copies fields in a way that is particular to a 
//         certain sub-table. 
//    <li> A particularly nasty problem is that some output columns depend on
//         more than one MS sub-table. In particular, columns dealing with
//         the data column coordinates. They are setup in a somewhat ad-hoc way
//         in initCoupledSubtables()
//    <li> Then the field handlers for each sub table are set up. Fields are
//         handled "specially", by blocking, or by copying (with the subtable
//         name and an underscore prepended).
// </ul>
// Once all the handlers are setup, you merely step through the main table
// row by row, copying all the fields through the use of a MultiRecordFieldWriter
// that the field handlers set up.
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//

class SDFITSSetup
{
public:
    // initialize things using the MS name as the input MS and FITSName as
    // the name of the output file.
    SDFITSSetup(const String &msName, const String &FITSName);

    ~SDFITSSetup();

    // the reader - steps through the MS being converted.  Any access to
    // that MS can be done through the reader.
    MSReader &reader() const {return *itsReader;}

    // the copier - copies fields from the reader to the output FITS records.
    MultiRecordFieldWriter &copier() {return *itsCopier;}

    // The writer - this actually generates each row of the FITS table using 
    // the output FITS records which are filled by copier.
    FITSTableWriter &writer() {return *itsWriter;}
    
private:
    // The reader - points to a specific row and corresponding subrows of the MS
    MSReader *itsReader;

    // Output (FITS) description
    RecordDesc itsFITSDescription;
    // Ouput (FITS) units
    Record itsFITSUnits;
    // This will hold the size of the largest string in the various string 
    // columns in the output (FITS) file.
    Record itsMaxOutLengths;
    // This will hold the sample TDIMS to be used in setting TDIM column
    // widths for variable shaped array columns
    Record itsFITSTdims;

    // This will actually write the FITS file.
    FITSTableWriter *itsWriter;

    // This is used in many places - just one, though, so that work
    // isn't done twice
    FieldCalculator *itsCalc;
    
    // This copies fields from input (MS) records to output (FITS) records.
    // Exactly how this is accomplished depends on the details of how the
    // individual field copiers are defined (i.e. they are polymorphic).
    MultiRecordFieldWriter *itsCopier;
    
    // the tables being handled
    Vector<String> itsNames;

    // the prefixes to use for the trivially handled columns in those tables
    Vector<String> itsPrefixes;

    // Per-table maximum string lengths and shapes of array columns, i.e.
    // everything except non-String scalar fields will have an entry. 
    PtrBlock<Record *> itsMaxLengths;
   
    // Per-table template TDIM strings - indicates largest TDIM string needed
    // for variable-shaped columns
    PtrBlock<Record *> itsTdims;

    // These are used for special (unique to a particular type of sub-table)
    // field handlers.
    PtrBlock<RecordFieldHandler *> itsSpecialHandlers;

    // These are used for "ordinary" field copying, e.g. straight-through copying.
    // These are really PtrBlock<PtrBlock<RecordFieldHandler *> *> but they are
    // done this way to avoid extra templates
    PtrBlock<void *> itsHandlers;

    // True if some columns is handled.
    PtrBlock<Vector<Bool> *> itsIsHandled;

    // Names of the columns we do not want to pass through.
    PtrBlock<Vector<String> *> itsBlockedColumns;

    // indexes into the above for the possible table types, we only need
    // these for blocked or special handlers to figure out stuff. Add them
    // as needed.  They are set in setupTableIdxs().
    Int itsMainIdx, itsAntenna1Idx, itsAntenna2Idx, itsFieldIdx, itsObservationIdx,
	itsSourceIdx, itsSpecWinIdx, itsSyscal1Idx, itsSyscal2Idx, itsFeed1Idx, itsFeed2Idx,
	itsWeather1Idx, itsWeather2Idx, itsPointing1Idx, itsPointing2Idx, itsDataDescIdx,
	itsDopplerIdx, itsFlagCmdIdx, itsFreqOffsetIdx;
	

    const RecordInterface &getRecord(uInt whichTable);
    const RecordInterface &getUnitRecord(uInt whichTable);
    const Table &getTable(uInt whichTable);
    void setup_blockers();
    void setup_special_handlers();
    void initCoupledSubtables();
    void createCoupledSubtables();
    void init(uInt forWhichTable);
    void create(uInt forWhichTable);
    void setupTableIdxs();
    // scan the table and report information on the sizes of each column
    // tdims are defined for array columns having more than 1 dimension
    // and for variable shaped columns of any dimension.  For variable
    // shaped columns, the content of tdim is the largest string necessary
    // to hold any of the possible TDIM values for that column.
    // For all other columns, tdim for that column will be an empty string.
    // The tdims Record is reset to have zero fields at the start of
    // this function so it must be a variable record and any prior
    // contents of tdims will be lost.  The shapes reported in the return
    // record are scalar Ints for scalar and Array<String> columns and
    // they are Vector<Ints> for all other Array columns.  For variable
    // shaped array columns, the values of the vector for that column will
    // contain all negative values. The absolute value of that field is
    // the largest product for any of the shapes of that column (i.e. the
    // FITS column to hold it must be at least that wide).
    Record scanTable(const Table &tab, Record &tdims);
};

#endif


