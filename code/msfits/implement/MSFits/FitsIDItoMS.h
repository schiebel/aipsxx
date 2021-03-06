//# FITSIDItoMS.h: Convert a FITS-IDI binary table to an AIPS++ Table.
//# Copyright (C) 1995,1996,2000,2001
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
//# $Id: FitsIDItoMS.h,v 19.6 2005/05/23 07:42:12 cvsmgr Exp $

#ifndef MS_FITSIDITOMS_H
#define MS_FITSIDITOMS_H

#include <fits/FITS/fits.h>
#include <casa/aips.h>
#include <fits/FITS/hdu.h>
#include <tables/Tables/Table.h> //
#include <tables/Tables/TableDesc.h> //
#include <tables/Tables/TableRecord.h> //
#include <tables/Tables/TableColumn.h> //
#include <casa/Containers/SimOrdMap.h> //
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Containers/Block.h>
#include <casa/Logging/LogIO.h>
#include <measures/Measures/MFrequency.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <casa/BasicSL/String.h> 
namespace casa { //# NAMESPACE CASA - BEGIN

class MSColumns;
class FitsInput;


// <summary> 
// FITSIDItoMS converts a FITS-IDI binary table to an AIPS++ Table.
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="">

// <prerequisite>
//# Classes you should understand before using this one.
//   <li> FitsInput
//   <li> HeaderDataUnit
//   <li> BinaryTableExtension
//   <li> Tables module
// </prerequisite>

// <etymology>

// FITSIDItoMS inherits from the FITS BinaryTableExtension class and
// its primary use is to convert such an object to an AIPS++ Table.
// This explains it's use but not its name.  A better name should be
// found.

// </etymology>

// <synopsis> 
// The class starts with an already existing FitsInput object, which
// should be set at a BinaryTableExtension HDU.  Member functions
// provide a TableDesc appropriate for the FITS data (to help in
// constructing an aips++ Table compatible with the
// BinaryTableExtension), a Table containing the current row of FITS
// data and a Table containing the next row of FITS data (which can be
// used to step through the FitsInput, copying each row using the
// RowCopier class), and a Table containin the entire FITS binary
// table from the current row to the end of the table.
// </synopsis> 

// <motivation>
// We need a way to get FITS data into aips++ Tables.
// </motivation>

// <example>
// Open a FitsInput from a disk file, if the HDU is a
// BinaryTableExtension, then instantiate a MSBinaryTable object and
// get the entire table.  A fair amount of error checking has been
// eliminated from this example.
// <srcblock>
//    FitsInput infits("myFITSFile", FITS::Disk);
//    switch (infits.hdutype()) {
//       case FITS::BinaryTableHDU:
//          MSBinaryTable bintab(infits);
//          Table tab = bintab.fullTable("myTable");
//          break;
//    }
// </srcblock>
// There would obviously be other cases to the switch to deal with any
// other HDUs (e.g. skip them via infits.skip_hdu()).  The Table
// destructor would write "myTable" to disk.
// </example>

// <todo asof="1995/04/10">
//# A List of bugs, limitations, extensions or planned refinements.
//
//   <li> It would be nice to construct this directly from the
//   BinaryTableExtension.
//
//   <li> When random access FITS becomes available, this needs to be
//   able to deal with that.
//
//   <li> A corresponding class is needed for conversion from aips++
//   Tables to FITS.
//
//   <li> Throw exceptions rather than send messages to cout : however
//   the entire FITS module behaves this way, so it should all remain
//   consistent.
//
//   <li> The following types of columns are not dealt with very well
//   or at all (Bit, Byte, 0-length columns).
//
//   <li> No attempt use any TDIM columns or keywords to shape arrays.
//
// </todo>

class FITSIDItoMS1 : public BinaryTableExtension
{
public: 

    //
    // The only constructor is from a FitsInput.
    //
  //FITSIDItoMS1(const String& msFile, const String& fitsFile);
    FITSIDItoMS1(FitsInput&);

    ~FITSIDItoMS1();

    //
    // Get the full table, using the supplied arguments to construct
    // the table.  The table will contain all data from the current
    // row to the end of the BinarTableExtension.
    //
    
    Table createTable(const String& tabName);
    Table fillTable(const String& tabName);
    Table oldfullTable(const String& tabName);
    
    /*
    // Get the full table, using the supplied arguments to construct the table.
    // The table will contain all data from the current row to the end of the
    // BinarTableExtension.If useMiriadSM is True, use the Miriad storage
    // manager for all columns, otherwise AipsIO.
    Table fullTable(const String& tabName, 
		    const Table::TableOption = Table::NewNoReplace,
		    Bool useMiriadSM = False);
    */
    //
    // Get the full table, using the supplied arguments to construct
    // the table.  The table will contain all data from the current
    // row to the end of the BinarTableExtension.
    //
    Table createMainTable(const String& tabName);
 
    //
    // Get the full table, using the supplied arguments to construct
    // the table.  The table will contain all data from the current
    // row to the end of the BinarTableExtension.
    //
    Table fillMainTable(const String& tabName);

    // Fill the Observation and ObsLog tables
    void fillObsTables();

    // Read a binary table extension of type ANTENNA and create an antenna table
    //void fillAntennaTable(BinaryTable& bt);
    void fillAntennaTable();

    // fill the Feed table with minimal info needed for synthesis processing
    void fillFeedTable();
 
    //fill the Field table
    //void fillFieldTable(Int nField);
    void fillFieldTable();

    //fill the Spectral Window table
    void fillSpectralWindowTable();

    // fix up the EPOCH MEASURE_REFERENCE keywords
    void fixEpochReferences();
  
    //update the Polarization table
    void updateTables(const String& tabName);
 
    
    //
    // Get an appropriate TableDesc (this is the same TableDesc used
    // to construct any Table objects returned by this class.
    //
    const TableDesc& getDescriptor();
    
    //
    // Return the Table keywords (this is the same TableRecord used in
    // any Table objects returned by this class.
    //
    TableRecord& getKeywords();
    
    //
    // Get a Table with a single row, the current row of the FITS
    // table.  The returned Table is a Scratch table.  The standard
    // BinaryTableExtension manipulation functions are available to
    // position the FITS input at the desired location.
    //
    const Table &thisRow();
    
    //
    // Get a Table with a single row, the next row of the FITS table.
    // The returned Table is a Scratch table.  The FITS input is
    // positioned to the next row and the values translated and
    // returned in a Table object.
    //
    const Table &nextRow();

    
    // Get the version of the archived MS. 
    Float msVersion() const
      { return itsVersion; }
    

    // Read all the data from the FITS file and create the MeasurementSet. Throws
    // an exception when it has severe trouble interpreting the FITS file.
    void readFitsFile(const String& msFile);

    //is this the first UV_DATA extension
    Bool isfirstMain(){return firstMain;}

protected:
    // Read the axis info, throws an exception if required axes are missing.
    void getAxisInfo();

    // Set up the MeasurementSet, including StorageManagers and fixed columns.
    // If useTSM is True, the Tiled Storage Manager will be used to store
    // DATA, FLAG and WEIGHT_SPECTRUM
    void setupMeasurementSet(const String& MSFileName, Bool useTSM=True, 
       Bool mainTbl=False);

    // Fill the main table from the Primary group data
    void fillMSMainTable(const String& MSFileName, Int& nField, Int& nSpW);

private:
    //
    //# Data Members
    //

    // The scratch table containing the current row
    Table itsCurRowTab;

    // The number of elements for each column of the
    // BinaryTableExtension
    Vector<Int> itsNelem;

    // For each column: is it an array?
    Vector<Bool> itsIsArray; 

    // Table keyword set
    TableRecord itsKwSet;
    
    // Table descriptor for construction
    TableDesc itsTableDesc;

    // Table info
    TableInfo itsTableInfo;

    // The MS version.
    Float itsVersion;

    
    //
    // Buffer for storing the MSK's, MS-specific FITS keywords.
    //
    uInt itsNrMSKs;
    Vector<String> itsMSKC;
    Vector<String> itsMSKN;
    Vector<String> itsMSKV;
    Vector<Bool>   itsgotMSK;
    

    FitsInput &infile_p;
    String msFile_p;
    Vector<Int> nPixel_p,corrType_p;
    Block<Int> corrIndex_p;
    Matrix<Int> corrProduct_p;
    Vector<String> coordType_p;
    Vector<Double> refVal_p, refPix_p, delta_p; 
    String array_p,object_p,timsys_p;
    //MSPrimaryGroupHolder priGroup_p;
    Double epoch_p;
    Int nAnt_p;
    Vector<Double> receptorAngle_p;
    MFrequency::Types freqsys_p;
    Double restfreq_p;
    LogIO itsLog;
    Int nIF_p;
    Double startTime_p;
    Double lastTime_p;
    MeasurementSet ms_p;
    MSColumns* msc_p;
    static Bool firstMain;

    //char *theheap_p;

    //
    //# Member Functions
    //

    // Fill in each row as needed
    void fillRow();

    // Build part of the keywords of the itsCurRowTab
    void convertKeywords();

    // Convert FITS field descriptions to TableColumn descriptions.
    void describeColumns();

    // Convert the MS-specific keywords in the FITS binary table.
    void convertMSKeywords();
};


} //# NAMESPACE CASA - END

#endif


