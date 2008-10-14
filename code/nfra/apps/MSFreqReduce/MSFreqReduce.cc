//# MSFreqReduce: Reduce Frequency resolution
//# Copyright (C) 1998,1999,2000,2001,2002,2003
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
// It is done in such a way that the old center channel is in the
// center of a new channel. This means that we do not start at the
// beginning of the frequency axis with averaging, morover, the
// edges of the band are discarded.
//
// As an example, consider a 64 channel case that is reduced by a
// factor 10. The new center channel covers the old channels from 7
// till 56. The old center (32) is covered by the new channel that
// runs from (old) 27 till 36.
//
// In the extreme case of a reduction by a factor 25, there is only
// one new channel that runs from (old) 20 till 44
//
//# $Id: 

//# Includes

#include <ms/MeasurementSets/MSColumns.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <tables/Tables/ArrColDesc.h>
#include <tables/Tables/ArrayColumn.h>
#include <tables/Tables/ScaColDesc.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/TableRecord.h>
#include <tables/Tables/TiledColumnStMan.h>
#include <tables/Tables/StandardStMan.h>
#include <tables/Tables/RefRows.h>

#include <casa/Arrays/Cube.h>
#include <casa/Arrays/Slicer.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/BasicMath/Math.h>
#include <casa/BasicSL/Constants.h>
#include <casa/Exceptions/Error.h>
#include <casa/Inputs.h>
#include <casa/OS/File.h>
#include <casa/OS/Path.h>
#include <casa/Utilities/Assert.h>
#include <casa/iostream.h>
#include <casa/Containers/Record.h>

#include <nfra/Wsrt/NFRA_MS.h>
#include <MSFreqReduce.h>

#include <casa/namespace.h>

#define VERSION "2006-08-30RxA"

Bool RB_DEBUG;

void RB_debug(String m)
{
  if (RB_DEBUG) cerr << "DEBUG - " << m << endl;
}
void RB_debug(String m1, String m2)
{
  if (RB_DEBUG) cerr << "DEBUG - " << m1 << " - " << m2 << endl;
}
void RB_debug(String m, Int i)
{
  if (RB_DEBUG) cerr << "DEBUG - " << m << ": " << i << endl;
}
void RB_debug(String m, uInt i)
{
  if (RB_DEBUG) cerr << "DEBUG - " << m << ": " << i << endl;
}
void RB_debug(String m, Double i)
{
  if (RB_DEBUG) cerr << "DEBUG - " << m << ": " << i << endl;
}

//======================================================================
// Create the new MS
//
// Open old MS
// Get the description
// Change DATA and FLAG columns
// Create a new table
// Save as new MS
//
void createMS(FreqReduce Info)
{
  //
  // Open the old table, get the table description
  //
  Table MSin(Info.getMSin());
  TableDesc td = MSin.tableDesc();

  //
  // Remove columns from table description
  // These colums must either change or are not required anymore
  //
  td.removeColumn("DATA");
  td.removeColumn("FLAG");
  td.removeColumn("VIDEO_POINT");
  td.removeColumn("NFRA_AVERAGEDATA");

  //
  // Add DATA and FLAG colums with row dimension
  //       number_of_Polarizations by number_of_channels
  // IPosition is a table dimension
  //
  IPosition dshape(2, Info.getNrPols(), Info.getNewNrChan());
  ArrayColumnDesc<Complex> newDATA("DATA", "comment", dshape, ColumnDesc::Direct);
  ArrayColumnDesc<Bool> newFLAG("FLAG", "comment", dshape, ColumnDesc::Direct);
  td.addColumn(newDATA);
  td.addColumn(newFLAG);

  //
  // Setup a new table from the old (adopted) table descriptor
  // Bind a new data manager to the new columns
  //
  SetupNewTable newTab("tmpMS", td, Table::New);
  TiledColumnStMan dm("TiledData", dshape);
  newTab.bindColumn("DATA", dm);
  newTab.bindColumn("FLAG", dm);

  //
  // Create a new MeasurementSet
  // This one has linked sub-tables
  //
  Table tmpMS(newTab);
  tmpMS.addRow();

  //
  // Make a deep copy - this one has real subtables
  //
  tmpMS.deepCopy(Info.getMSout(), Table::New, True);

}

//======================================================================
// copy data from old to new MS
//
//----------------------------------------------------------------------
// Various functions to copy a type of column from one table to another
// Method:
// - open old column
// - get data
// - open new column
// - put data
//
void cpBool(Table Tin, Table Tout, String ColName)
{
  try{
    ROScalarColumn<Bool> colIn(Tin, ColName);
    Vector<Bool> d = colIn.getColumn();
    ScalarColumn<Bool> colOut(Tout, ColName);
    colOut.putColumn(d);
  }
  catch(AipsError x){
    cerr << "While copying column: " << ColName << endl;
    cout << "Error: "<< x.getMesg() << endl;
  }
}
void cpBoolArr(Table Tin, Table Tout, String ColName)
{
  try{
    ROArrayColumn<Bool> colIn(Tin, ColName);
    Array<Bool> d = colIn.getColumn();
    ArrayColumn<Bool> colOut(Tout, ColName);
    colOut.putColumn(d);
  }
  catch(AipsError x){
    cerr << "While copying column: " << ColName << endl;
    cout << "Error: "<< x.getMesg() << endl;
  }
}
void cpInt(Table Tin, Table Tout, String ColName)
{
  try{
    ROScalarColumn<Int> colIn(Tin, ColName);
    Vector<Int> d = colIn.getColumn();
    ScalarColumn<Int> colOut(Tout, ColName);
    colOut.putColumn(d);
  }
  catch(AipsError x){
    cerr << "While copying column: " << ColName << endl;
    cout << "Error: "<< x.getMesg() << endl;
  }
}
void cpFlt(Table Tin, Table Tout, String ColName)
{
  try{
    ROScalarColumn<Float> colIn(Tin, ColName);
    Vector<Float> d = colIn.getColumn();
    ScalarColumn<Float> colOut(Tout, ColName);
    colOut.putColumn(d);
  }
  catch(AipsError x){
    cerr << "While copying column: " << ColName << endl;
    cout << "Error: "<< x.getMesg() << endl;
  }
}
void cpFltArr(Table Tin, Table Tout, String ColName)
{
  try{
    ROArrayColumn<Float> colIn(Tin, ColName);
    Array<Float> d = colIn.getColumn();
    ArrayColumn<Float> colOut(Tout, ColName);
    colOut.putColumn(d);
  }
  catch(AipsError x){
    cerr << "While copying column: " << ColName << endl;
    cout << "Error: "<< x.getMesg() << endl;
  }
}
void cpDbl(Table Tin, Table Tout, String ColName)
{
  try{
    ROScalarColumn<Double> colIn(Tin, ColName);
    Vector<Double> d = colIn.getColumn();
    ScalarColumn<Double> colOut(Tout, ColName);
    colOut.putColumn(d);
  }
  catch(AipsError x){
    cerr << "While copying column: " << ColName << endl;
    cout << "Error: "<< x.getMesg() << endl;
  }
}
void cpStr(Table Tin, Table Tout, String ColName)
{
  try{
    ROScalarColumn<String> colIn(Tin, ColName);
    Vector<String> d = colIn.getColumn();
    ScalarColumn<String> colOut(Tout, ColName);
    colOut.putColumn(d);
  }
  catch(AipsError x){
    cerr << "While copying column: " << ColName << endl;
    cout << "Error: "<< x.getMesg() << endl;
  }
}
void cpDblArr(Table Tin, Table Tout, String ColName)
{
  try{
    ROArrayColumn<Double> colIn(Tin, ColName);
    Array<Double> d = colIn.getColumn();
    ArrayColumn<Double> colOut(Tout, ColName);
    colOut.putColumn(d);
  }
  catch(AipsError x){
    cerr << "While copying column: " << ColName << endl;
    cout << "Error: "<< x.getMesg() << endl;
  }
}
void cpCmplArr(Table Tin, Table Tout, String ColName)
{
  try{
    ROArrayColumn<Complex> colIn(Tin, ColName);
    Array<Complex> d = colIn.getColumn();
    ArrayColumn<Complex> colOut(Tout, ColName);
    colOut.putColumn(d);
  }
  catch(AipsError x){
    cerr << "While copying column: " << ColName << endl;
    cout << "Error: "<< x.getMesg() << endl;
  }
}

//----------------------------------------------------------------------
// Copy all non-changing columns from old to new
//
void cpColumns(FreqReduce Info)
{
  //
  // Open old and new tables
  // Add enough new rows to new
  //
  Table Tin(Info.getMSin());
  uInt NRin = Tin.nrow();
  Table Tout(Info.getMSout(), Table::Update);
  uInt NRout = Tout.nrow();

  try{
    Tout.addRow(NRin-NRout);
  }
  catch(AipsError x) {
    cerr << "Could not add rows" << endl;
    cout << "Error: "<< x.getMesg() << endl;
  }

  //  cpBoolArr(Tin, Tout, "FLAG_CATEGORY");

  //
  // Copy all non-chaning columns
  //

  Info.verbose(" - ANTENNA1");
  cpInt(Tin, Tout, "ANTENNA1");
  Info.verbose(" - ANTENNA2");
  cpInt(Tin, Tout, "ANTENNA2");
  Info.verbose(" - ARRAY_ID");
  cpInt(Tin, Tout, "ARRAY_ID");
  Info.verbose(" - DATA_DESC_ID");
  cpInt(Tin, Tout, "DATA_DESC_ID");
  Info.verbose(" - FEED1");
  cpInt(Tin, Tout, "FEED1");
  Info.verbose(" - FEED2");
  cpInt(Tin, Tout, "FEED2");
  Info.verbose(" - FIELD_ID");
  cpInt(Tin, Tout, "FIELD_ID");
  Info.verbose(" - OBSERVATION_ID");
  cpInt(Tin, Tout, "OBSERVATION_ID");
  Info.verbose(" - PROCESSOR_ID");
  cpInt(Tin, Tout, "PROCESSOR_ID");
  Info.verbose(" - SCAN_NUMBER");
  cpInt(Tin, Tout, "SCAN_NUMBER");
  Info.verbose(" - STATE_ID");
  cpInt(Tin, Tout, "STATE_ID");

  Info.verbose(" - WEIGHT");
  cpFltArr(Tin, Tout, "WEIGHT");

  Info.verbose(" - EXPOSURE");
  cpDbl(Tin, Tout, "EXPOSURE");
  Info.verbose(" - INTERVAL");
  cpDbl(Tin, Tout, "INTERVAL");
  Info.verbose(" - TIME");
  cpDbl(Tin, Tout, "TIME");
  Info.verbose(" - TIME_CENTROID");
  cpDbl(Tin, Tout, "TIME_CENTROID");

  Info.verbose(" - UVW");
  cpDblArr(Tin, Tout, "UVW");
  Info.verbose(" - SIGMA");
  cpFltArr(Tin, Tout, "SIGMA");
}

//======================================================================
// Process DATA and FLAG columns
//
#define CHUNK_SIZE 1000
Bool cpData(FreqReduce Info)
{
  Bool rtn = True;
  //
  // Open old and new tables, new table must be updated.
  // Get number of rows
  //
  Table Tin(Info.getMSin());
  uInt NRin = Tin.nrow();
  Table Tout(Info.getMSout(), Table::Update);

  //
  // open the old and new DATA columns
  //
  String ColName = "DATA";
  ROArrayColumn<Complex> colIn(Tin, ColName);
  ArrayColumn<Complex> colOut(Tout, ColName);

  //
  // open the old and new FLAG columns
  //
  ColName = "FLAG";
  ROArrayColumn<Bool> colOldFlag(Tin, ColName);
  ArrayColumn<Bool> colNewFlag(Tout, ColName);

  //
  // At last we are ready to do the real job - average the frequency axis
  //
  Info.verbose("Rows to process", NRin);
  Bool vb = Info.getVerbose();
  uInt NChunks = NRin / CHUNK_SIZE;
  if ((NChunks*CHUNK_SIZE) < NRin) NChunks++;

  Int row = 0;
  Info.verbose("Chunks to process", NChunks);

  uInt chunk;

  try{
    //
    // loop over all chunks
    //
    for (chunk = 0; chunk < NChunks; chunk++){
      if (vb)
	fprintf(stderr, "%d\r", chunk);

//       Bool dbg = False;
//       if (chunk > 5){
// 	cerr << "working on chunk: " << chunk << endl;
// 	dbg = True;
//       }
      //
      // get the data and flags of the chunk
      // We start from row, and get the data till maxrow
      // 
      uInt maxrow = row + CHUNK_SIZE-1;
      if (maxrow > NRin-1) maxrow = NRin-1;

//        if (dbg) cerr << "row, maxrow: " << row << ", " << maxrow << endl;

      RefRows rr(row, maxrow, 1);
      Array<Complex> vIn = colIn.getColumnCells(rr);
      Array<Complex> vOut = colOut.getColumnCells(rr);

      uInt newNChan = vOut.shape()[1];
      Array<Bool> vOldFlag = colOldFlag.getColumnCells(rr);
      Array<Bool> vNewFlag = colNewFlag.getColumnCells(rr);

      //
      // loop over the chunk for all polarizations
      //
      uInt nrow = maxrow-row;
      for (uInt r = 0; r <= nrow; r++){
        for (uInt p = 0; p < Info.getNrPols(); p++){

          //
          // The fist channel should always be FLAGged because this is
          // supposed to be tne video point.
          //
          vNewFlag(IPosition(3, p, 0, r)) = True;

          //
          // Loop over the new channels
          // calculate the average - adjust oldChannel number
          // store in the new channel
          //
          IPosition inP(3, p, 0, r);  // index to polarization p, channel 0, row r

          //
          // index of old channel
          // startFrom points to the first channel that goes into the
          // video channel, so the first channel that goes into a real
          // data point is redFct higer.
          //
          uInt oldChan = Info.ChanMap[0].getCh0() + Info.getRedFct();

          //
          // Loop over all new channels excluding the video channel
          //
          for (uInt newC = 1; newC < newNChan; newC++){

            inP(1) = oldChan;
            oldChan++;
            
            //
            // first value in average
            //
            Complex x = vIn(inP);
            Bool tf = vOldFlag(inP);
            //
            // add the correct number of values
            // Flags are ORred because True means 'do_not_use' in aips++
            //
            for (uInt d = 1; d < Info.getRedFct(); d++){
              inP(1) = oldChan;
              oldChan++;
              x += vIn(inP);
              tf |= vOldFlag(inP);
            }
            //
            // calculate the average
            //
            x /= Info.getRedFct();

            //
            // Store in new
            //
            IPosition outP(3, p, newC, r);
            vOut(outP) = x;
            vNewFlag(outP) = tf;
          }
	}
      }
      colOut.putColumnCells(rr, vOut);
      colNewFlag.putColumnCells(rr, vNewFlag);
      row += CHUNK_SIZE;
    }

  }
  catch(...){
    cerr << "FAIL when converting DATA column" << endl;
    cerr << "Chunk=" << chunk << endl;
    rtn = False;
  }
  return rtn;

}

//======================================================================
// Create new SPECTRAL_WINDOW table
//
// Just create a new table in the MS subdirectory, this will later
// automatically be the table,linked to the MS keyword because the
// name matches.
//
void createSW(FreqReduce Info)
{
  //
  // Open the old MS, old SPECTRAL_WINDOW table using the keywords
  // Get the table descriptor
  //
  Table Tin(Info.getMSin());
  TableRecord kwds = Tin.keywordSet();
  Table spwnd = kwds.asTable(kwds.fieldNumber("SPECTRAL_WINDOW"));
  TableDesc td = spwnd.tableDesc();

  //
  // Remove columns that must be changed
  //
  td.removeColumn("NUM_CHAN");
  td.removeColumn("CHAN_FREQ");
  td.removeColumn("CHAN_WIDTH");
  td.removeColumn("EFFECTIVE_BW");
  td.removeColumn("RESOLUTION");

  //
  // Create new colums and, if necessary, the column keywords
  //
  // NUM_CHAN is a scalar column
  //
  ScalarColumnDesc<Int> newNC("NUM_CHAN", "comment", ColumnDesc::Direct);

  //
  // Create shape for new array columns
  //
  IPosition dshape(1, Info.getNewNrChan());

  //
  // CHAN_FREQ needs two keywords of which 1 is a record
  //
  ArrayColumnDesc<Double> newCF("CHAN_FREQ", "comment", dshape, ColumnDesc::Direct);
  newCF.rwKeywordSet().define("QuantumUnits", "MHz");
  Record rif;
  rif.define("type", "frequency");
  rif.define("VarRefCol", "MEAS_FREQ_REF");
  newCF.rwKeywordSet().defineRecord("MEASINFO", rif);

  //
  // resolution related columns
  //
  ArrayColumnDesc<Double> newCW("CHAN_WIDTH", "comment", dshape, ColumnDesc::Direct);
  newCW.rwKeywordSet().define("QuantumUnits", "Hz");
  ArrayColumnDesc<Double> newEB("EFFECTIVE_BW", "comment", dshape, ColumnDesc::Direct);
  newEB.rwKeywordSet().define("QuantumUnits", "Hz");
  ArrayColumnDesc<Double> newRes("RESOLUTION", "comment", dshape, ColumnDesc::Direct);
  newRes.rwKeywordSet().define("QuantumUnits", "Hz");

  //
  // Add new columns to table descriptor
  //
  td.addColumn(newNC);
  td.addColumn(newCF);
  td.addColumn(newCW);
  td.addColumn(newEB);
  td.addColumn(newRes);

  //
  // Setup a new table .
  // Add the new tables to the standard table manager.
  //
  String newSW = Info.getMSout() + "/SPECTRAL_WINDOW";
  SetupNewTable tmpTab(newSW, td, Table::New);
  StandardStMan stm;
  tmpTab.bindColumn("CHAN_FREQ", stm);
  tmpTab.bindColumn("CHAN_WIDTH", stm);
  tmpTab.bindColumn("EFFECTIVE_BW", stm);
  tmpTab.bindColumn("RESOLUTION", stm);

  //
  // Create the new table
  //
  Table newTab(tmpTab, Table::Plain);

  //
  // add a row
  //
  newTab.addRow();

}

//======================================================================
// Copy old SW columns to new SW table
// Returns vector with base frequencies for new channel table
//
void copySW(FreqReduce Info)
{
  //
  // open the old SW table
  //
  Table oldMS(Info.getMSin());
  TableRecord oldKWDs = oldMS.keywordSet();
  Table oldSWTable = oldKWDs.asTable(oldKWDs.fieldNumber("SPECTRAL_WINDOW"));

  //
  // Create a vector with the frequencies of the first channels of all
  // IVCs bands
  // - oldChanFreq = Matrix with all channel frequencies
  // - rtn = Vector with the first channel frequencies
  // Use an IPosition to index the Matrix
  //
  ROArrayColumn<Double> oldChanFreqCol(oldSWTable, "CHAN_FREQ");
  Matrix<Double> oldChanFreq = oldChanFreqCol.getColumn();
  //  uInt vLen = oldChanFreq.shape()[1];
  //  Vector<Double> rtn(vLen);

  //
  // Loop over all rows = IVCs
  // Get the first frequency, store in return vector
  //
  //  IPosition idx(2, 0, 0);
  //  for (uInt i = 0; i < vLen; i++){
  //    idx[1] = i;
  //    rtn[i] = oldChanFreq(idx);
  //  }

  //
  // Open the SPECTRAL_WINDOW table of the new MS read/write
  //
  Table Tnew(Info.getMSout());
  TableRecord newKWDs = Tnew.keywordSet();
  Table TTo = newKWDs.asTable(newKWDs.fieldNumber("SPECTRAL_WINDOW"));
  TTo.reopenRW();

  //
  // Add enough new rows
  //
  uInt NRold = oldSWTable.nrow();
  uInt NRnew = TTo.nrow();

  try{
    TTo.addRow(NRold-NRnew);
  }
  catch(AipsError x) {
    cerr << "Could not add rows" << endl;
    cout << "Error: "<< x.getMesg() << endl;
  }

  //
  // Copy all data that need not be changed
  //
  cpInt(oldSWTable, TTo, "MEAS_FREQ_REF");
  cpInt(oldSWTable, TTo, "FREQ_GROUP");
  cpInt(oldSWTable, TTo, "IF_CONV_CHAIN");
  cpInt(oldSWTable, TTo, "NET_SIDEBAND");
  cpDbl(oldSWTable, TTo, "REF_FREQUENCY");
  cpBool(oldSWTable, TTo, "FLAG_ROW");
  cpStr(oldSWTable, TTo, "FREQ_GROUP_NAME");
  cpStr(oldSWTable, TTo, "NAME");
  cpDbl(oldSWTable, TTo, "TOTAL_BANDWIDTH");
  cpFlt(oldSWTable, TTo, "NFRA_RESTFREQ");
  cpStr(oldSWTable, TTo, "NFRA_MODE");
  cpStr(oldSWTable, TTo, "NFRA_VELOCDEFINITION");
  cpStr(oldSWTable, TTo, "NFRA_CONVERSIONTYPE");
  cpFlt(oldSWTable, TTo, "NFRA_TRACKINGVELOC");
  cpFlt(oldSWTable, TTo, "NFRA_DOPPLERSHIFT");
  cpFlt(oldSWTable, TTo, "NFRA_FREQSTEPSIZE");

  //  return rtn;

}

//======================================================================
// update the SPECTRAL_WINDOW table
// startFrom is the first old channel that is used in the averaging
// redFct is the number of old channels that are averaged in a new channel
// refFreq is a vector with all old first channel frequencies
//         (we need not give these, becuase we open here the old table
//         as well, however, we do not open the old table)
//
void updateSW(FreqReduce Info)
{
  //
  // open old and new SPECTRAL_WINDOW tables: TFrom, TTo
  //
  Table Told(Info.getMSin());
  TableRecord kwds = Told.keywordSet();
  Table TFrom = kwds.asTable(kwds.fieldNumber("SPECTRAL_WINDOW"));
  Table Tnew(Info.getMSout());
  kwds = Tnew.keywordSet();
  Table TTo = kwds.asTable(kwds.fieldNumber("SPECTRAL_WINDOW"));
  TTo.reopenRW();
  uInt nRow = TTo.nrow();

  //
  // Column vector data is created and accessed as follows:
  //  - create a column: ScalarColumn<'type'> col('table', 'name');
  //                 where table is the table that holds the column
  //  - Vector<'type'> v = col.getColumn();
  //  Array is similar ...

  //
  // NUM_CHAN is a vector of number_of_channels
  //
  {
    ScalarColumn<Int> colTo(TTo, "NUM_CHAN");
    Vector<Int> vTo = colTo.getColumn();
    for (uInt r = 0; r < nRow; r++)
      vTo[r] = Info.getNewNrChan();
    colTo.putColumn(vTo);
  }

  //
  // The nex columns are arrays that need a shape
  //
  IPosition dshape(2, Info.getNewNrChan(), nRow);
  {
    //
    // All resolution columns have equal values
    // Create an Array of shape dshape, initialise all values to the
    // channel width.
    //
    Array<Double> M(dshape, Info.getNewChanWidth());

    //
    // Create all columns, add the data
    // The columns are told to wich table they belong (TTo) and attach
    // their data automatically.
    //
    ArrayColumn<Double> cw(TTo, "CHAN_WIDTH");
    cw.putColumn(M);

    ArrayColumn<Double> bw(TTo, "EFFECTIVE_BW");
    bw.putColumn(M);

    ArrayColumn<Double> rs(TTo, "RESOLUTION");
    rs.putColumn(M);
  }
  
  //
  // Fill the new CHAN_FREQ column
  // - using startFrom and redFct the old channles are mapped to the new ons.
  //
  {
    String colName = "CHAN_FREQ";
    ROArrayColumn<Double> colFrom(TFrom, colName);
    Matrix<Double> mFrom = colFrom.getColumn();
    Array<Double> M(dshape);

    // oldIdx is used to index the old column
    // idx is used to index the new column
    //  - first index is channel
    //  - second index is row
    // loop over all rows
    //   loop over all new channels
    //      find the start and end old-channel frequencies
    //      average the values and put as new channel frequency
    //
    IPosition oldIdx(2, 0, 0);
    IPosition idx(2, 0, 0);
    for (uInt r = 0; r < nRow; r++){
      idx[0] = 0;               // first channel
      oldIdx[1] = r;            // point to old row
      idx[1] = r;               // point to new row
      Int i0 = Info.ChanMap[0].getCh0();       // first old channel to use
      for (uInt c = 0; c < Info.getNewNrChan(); c++){
        idx[0] = c;             // point to new channel

        //
        // get old channel frequencies and average
        //
        Double f0;
        if (i0 >= 0){
          oldIdx[0] = i0;
          f0 = mFrom(oldIdx);
        } else {
          oldIdx[0] = 0;
          f0 = mFrom(oldIdx) - i0*Info.getOldChanWidth();
        }
        //      cout << i0 << ", " << f0 << endl;
        oldIdx[0] = i0+Info.getRedFct()-1;
        Double f1 = mFrom(oldIdx);
        M(idx) = (f0 + f1)/2.0;

        i0 += Info.getRedFct();           // first old channel for next new channel
      }
    }

    //
    // Save data into column
    //
    ArrayColumn<Double> colTo(TTo, colName);
    colTo.putColumn(M);
  }

}

//----------------------------------------------------------------------
// Map old channels to new channels with a reduction factor
// The mapping will be such that the original center channel is near
// the center of a new channel.
//
void FreqReduce::redFct_mapping()
{
  //
  // Calculate the first old channels that goes into the new center
  // channel
  //
  Int m0 = oldNrChan/2 - redFct/2;
  //
  // Skip downwards until first channel
  //
  while (m0 > Int(startChan)) m0 -= redFct;
  //
  // m0 is now the first old chanel that goes into the first new channel
  // create the highest old channel:
  //
  uInt m1 = m0 + redFct - 1;

  //
  // let m1 run until the end channel
  // create Channels
  //
  while (m1 < endChan){
    //    cout << m0 << ", " << m1 << endl;
    Channel tmp(m0, m1, 0.0);
    ChanMap.push_back(tmp);
    m0 += redFct;
    m1 += redFct;
  }
  newNrChan = ChanMap.size();
  newChanWidth = oldChanWidth*redFct;

}

void FreqReduce::nchan_mapping()
{
  uInt range = endChan - startChan - 1;
  redFct = range / newNrChan;
  if (redFct == oldNrChan) redFct--;

  Int m0 = startChan - redFct;
  Int m1 = m0 + redFct - 1;
  while (m1 < Int(endChan)){
    Channel tmp(m0, m1, 0.0);
    ChanMap.push_back(tmp);
    m0 += redFct;
    m1 += redFct;
  }
  newNrChan = ChanMap.size();
  newChanWidth = oldChanWidth*redFct;
  
}

void FreqReduce::getInfo()
{
  //
  // class MFRA_MS read info from a Westerbork MS
  //
  NFRA_MS MSinfo;
  //
  // Get info from the NFRA_TMS_PARAMETERS table
  //
  MSinfo.setMethod(NFRA_MS::NFRA);
  //
  // Fill the info objects for MSname = inName
  //
  MSinfo.setInfo(MSin);

  //
  // We need info for channel width and numbers, that is inside
  // class FW (Frequency Window) - inside FreqMos (Frequency
  // Mosaic point) - inside IVC.
  //
  NFRA_FW a = MSinfo.getFWs()[0];
  NFRA_FreqMos b = a.getFreqMoss()[0];
  NFRA_IVC c = b.getIVCs()[0];

  nrPols = c.getNPol();
  oldNrChan = c.getNChan();
  startChan = 1;
  endChan = oldNrChan;
  oldChanWidth = c.getChanWidth() * MHz;
}

//======================================================================
// Main
//
int main(Int argc, char** argv)
{
  Bool rtn = True;
  FreqReduce Info;

  //
  cerr << "!" << endl;
  cerr << "!" << endl;
  cerr << "MSFreqReduce - reduce frequency axis" << endl;
  cerr << "!" << endl;
  cerr << "!" << endl;

  //
  // Must have at least one parameter
  //
  if (argc == 1){
    cout << "\nMust have some parameters, try " << argv[0] << " -h" << endl;
    exit(0);
  }

  //
  // All fatal errors are catched - we 'never' end with a segmentation fault.
  //
  try {

    //
    // enable input in no-prompt mode
    //
    Input inputs(1);

    inputs.version(VERSION);

    //
    // define the input structure
    //
    inputs.create("msin", "",
                  "Name of input MeasurementSet", "string");
    inputs.create("in", "",
                  "Name of input MeasurementSet (synonym of msin)",
                  "string");
    inputs.create("msout", "",
                  "Name of output MeasurementSet", "string");
    inputs.create("out", "",
                  "Name of output MeasurementSet (synonym of msout)",
                  "string");
    inputs.create("factor", "0", "Reduction factor", "int");
    inputs.create("width", "0", "New channel width [MHz]", "double");
    inputs.create("nchan", "0", "New number of channels", "int");
    inputs.create("start", "1", "First channel to be used", "double");
    inputs.create("end", "0", "Last channel to be used", "double");
    inputs.create("db", "0", "Debug", "int");
    inputs.create("vb", "0", "Verbose output", "int");

    //
    // Fill the input structure from the command line.
    //
    inputs.readArguments (argc, argv);

    //
    // Check if we are debugging ...
    //
    RB_DEBUG = inputs.getInt("db") == 1;
    RB_debug("on");

    //
    // Check if we must output a lot
    //
    if(inputs.getInt("vb") == 1) Info.setVerbose(True);

    //
    // Get the input MS specification
    // Commandline keywords are msin= or in=
    //
    String inName (inputs.getString("msin"));
    if (inName == "") {
      inName = inputs.getString("in");
    }
    if (inName == "") {
      throw (AipsError(" The input MS must be given"));
    }
    Info.verbose("Input data set", inName);

    //
    // Pass the input MS name to the FreqReduce object
    // This will initialise some of the properties there
    //
    Info.setMSin(inName);

    //
    // Get the output MS specification
    // Commandline keywords are msout= or out=
    //
    String outName (inputs.getString("msout"));
    if (outName == "") {
      outName = inputs.getString("out");
    }
    if (outName == "") {
      throw (AipsError(" The output MS must be given"));
    }
    Info.verbose("Output data set", outName);
    Info.setMSout(outName);

    //
    // Get start channel - i.e. the first old channels that goes into
    // an average is not before start.
    //
    Double kwdStart (inputs.getDouble("start"));
    int startCh = 1;
    if (kwdStart >= 1){
      startCh = int(kwdStart);
    } else if (kwdStart >= 0){
      startCh = int(Info.getOldNrChan() * kwdStart);
    } else {
      throw(AipsError(" start must be >= 0"));
    }
    Info.verbose("Start from channel", startCh);
    Info.setStartChan(startCh);

    //
    // get end channel
    //
    Double kwdEnd (inputs.getDouble("end"));
    Int endCh;
    if (kwdEnd == 0){
      endCh = Info.getOldNrChan();
    } else if (kwdEnd > 1){
      endCh = int(kwdEnd);
    } else if (kwdEnd > 0){
      endCh = int(Info.getOldNrChan() * kwdEnd);
    } else if (kwdEnd > -1) {
      endCh = int(Info.getOldNrChan() - Info.getOldNrChan()*kwdEnd);
    } else {
      throw(AipsError(" start must be >= -1"));
    }
    Info.verbose("Stop at channel", endCh);
    Info.setEndChan(endCh);

    //
    // Get the reduction method
    // First check if one and only one method is given
    //
    Info.setRedFct(inputs.getInt("factor"));
    Info.setNewChanWidth(inputs.getDouble("width") * MHz);
    Info.setNewNrChan(inputs.getInt("nchan"));

    if (Info.getRedFct() != 0){
      if ((Info.getNewChanWidth() != 0) || (Info.getNewNrChan() != 0)){
        throw(AipsError(" Only one of 'factor', 'width', and 'nchan' may be given"));
      }
    } else if (Info.getNewChanWidth() != 0){
      if (Info.getNewNrChan() != 0){
        throw(AipsError(" Only one of 'factor', 'width', and 'nchan' may be given"));
      }
    } else if (Info.getNewNrChan() == 0) {
        throw(AipsError(" One of 'factor', 'width', or 'nchan' must be given"));
    }

    //   Int newNrChans;
    //    Double newChanWidth;
    //    Int startFrom = 0;         // first old channel that goes into a new channel

    if(Info.getRedFct() != 0){
      Info.verbose("Use reduction factor method, factor", Info.getRedFct());
      //
      // User specified the reduction factor
      //
      Info.redFct_mapping();

    } else if (Info.getNewChanWidth() != 0){

      Info.verbose("Use channel width method, factor", Info.getNewChanWidth());
      //
      // User specified a new channel width
      //
      cout << "Beware - the channel width may not be what you specified because the\n";
      cout << "         reduction factor must be an integer number." << endl;

      Info.updateRedFct();
      Info.redFct_mapping();

    } else if (Info.getNewNrChan() != 0){

      Info.nchan_mapping();

      //      throw(AipsError(" Method nchan not activated yet"));

    }

    //
    // Basic check
    //
    if (Info.getRedFct() >= Info.getOldNrChan()){
      throw(AipsError(" factor may not be > NChan-1"));
    }

    //
    // We know what we should do now
    // Show it
    //
    Info.show();

    //
    // Create new MS, insert a new SPECTRAL_WINDOW table
    //
    Info.verbose("Create new MS");
    createMS(Info);
    RB_debug("Created new MS");

    Info.verbose("Create new SPECTRAL WINDOW table");
    createSW(Info);
    RB_debug("Created new SPECTRAL WINDOW table");

    Info.verbose("Copy SPECTRAL WINDOW Table");
    copySW(Info);
    RB_debug("Copied SPECTRAL WINDOW Table");

    Info.verbose("Update SPECTRAL WINDOW Table");
    updateSW(Info);
    RB_debug("Updated SPECTRAL WINDOW Table");

    Info.verbose("Copy MAIN table");
    cpColumns(Info);
    RB_debug("Copied MAIN table");

    Info.verbose("Update MAIN table");
    rtn = cpData(Info);
    RB_debug("Updated MAIN table");

    //
    // Cleanup
    //
    system ("rm -rf tmpMS");


  } catch (AipsError x) {
    cout << "Error: "<< x.getMesg() << endl;
    exit(1);
  } 
  
  if (rtn){
    cout << "Ended successfully" << endl;
  } else {
    cout << "Ended with error" << endl;
  }
  exit(0);
}
