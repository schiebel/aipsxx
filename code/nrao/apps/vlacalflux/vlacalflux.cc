//# ClassFileName.cc:  this defines ClassName, which ...
//# Copyright (C) 1996,1997,1998,2000,2001,2002
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
//# $Id: vlacalflux.cc,v 19.2 2004/11/30 17:50:41 ddebonis Exp $

//# Includes

#include "vlacalflux.h"
#include <casa/iostream.h>
#include <casa/fstream.h>
 
#include <casa/namespace.h>
// The modcomp/ieee translation routines should be moved to a common library

// These two functions are adapted from the Classic AIPS routines ZRM2RL.C and
// ZDM2DL.C.
//
// They have been adapted to work on a single value at a time.  The following
// variables are left as defines, as a reminder to take care of non-network
// ordered architectures at a later date.
 
#define Z_bytflp 0
#define Z_spfrmt 1
#define Z_dpfrmt 1
 
static Float    floatFromModCompFP (const Char* startLocation)
{
    Int test;
    uInt sign, exponent, mantissa, temp;
    union u_tag {
        Float r4;
        uInt u4;
        Short u2[2];
    } what;
/*--------------------------------------------------------------------*/
                                        /* routine works IEEE, VAX F  */
                                        /* Get ModComp value.         */
    memcpy (&what, startLocation, 4);
                                        /* swap words if needed       */
    if (Z_bytflp > 1) {
        Short sitemp = what.u2[0];
        what.u2[0] = what.u2[1];
        what.u2[1] = sitemp;
    }
                                        /* Get as unsigned int.       */
    temp = what.u4;
                                        /* Mask out sign bit.         */
    sign = 0x80000000 & temp;
                                        /* If negative, 2's           */
                                        /* complement the whole word. */
    if (sign == 0x80000000) temp = (~temp) + 1;
                                        /* Correct for exponent bias. */
    switch (Z_spfrmt) {
                                        /* IEEE (bias = -130?).       */
    case 1:
        test = ((0x7fc00000 & temp) >> 22) - 130;
        break;
                                        /* VAX F (bias = -128).       */
    case 2:
        test = ((0x7fc00000 & temp) >> 22) - 128;
        break;
    }
 
    exponent = test << 23;
    mantissa = (0x001fffff & temp) << 2;
    what.u4 = sign | exponent | mantissa;
                                        /* Overflow.                  */
    if (test > 255)
        what.u4 = ~0x0;
                                        /* Underflow.                 */
    else if (test < 1)
        what.u4 = 0;
                                        /* Store result.              */
    return what.r4;
}
 
// this function is commented out to eliminate a compiler warning
// about it being defined but not used
// 
// static Double   doubleFromModCompDP (const Char* startLocation)
// {
//     Int test;
//     uInt sign, exponent, mantissa, temp, templo, bits, xsign;
//     union u_tag {
//         Double r8;
//         uInt u4[2];
//         Short u2[4];
//     } what;
// /*--------------------------------------------------------------------*/
//                                         /* routine works IEEE, VAX G  */
//                                         /* Get ModComp value.         */
//     memcpy (&what, startLocation, 8);
//                                         /* swap words if needed       */
//     if (Z_bytflp > 1) {
//         Short sitemp = what.u2[0];
//         what.u2[0] = what.u2[1];
//         what.u2[1] = sitemp;
//         sitemp = what.u2[2];
//         what.u2[2] = what.u2[3];
//         what.u2[3] = sitemp;
//     }
//                                         /* Get hi as unsigned int.    */
//     temp = what.u4[0];
//                                         /* Mask out sign bit.         */
//     xsign = 0x80000000;
//     sign = xsign & temp;
//                                         /* If negative, 2's           */
//                                         /* complement the whole word. */
//     if (sign != 0) {
//         templo = what.u4[1];
//         what.u4[1] = ~templo + 1;
//         temp = (~temp);
//                                         /* If msb of lo word are      */
//                                         /* unchanged, add 1 to high   */
//                                         /* word.                      */
//         if ((templo & 0x80000000) == (what.u4[1] & 0x80000000))
//             temp = temp + 1;
//     }
//                                         /* Correct for exponent bias  */
//                                         /* and trap for 0.            */
//     switch (Z_dpfrmt) {
 
//     case 1:
//                                         /* IEEE (bias = 766?).        */
//         test = ((0x7fc00000 & temp) >> 22) + 766;
//         if (test == 766) test = 0;
//         break;
 
//     case 3:
//                                         /* VAX G (bias = 768).        */
//         test = ((0x7fc00000 & temp) >> 22) + 768;
//         if (test == 768) test = 0;
//         break;
//     }
 
//     exponent = test << 20;
//     mantissa = (0x001fffff & temp);
//                                         /* Move lsb to next word.     */
//     bits = (mantissa & 0x1) << 31;
//                                         /* Shift high mantissa.       */
//     mantissa = mantissa >> 1;
//                                         /* Shift low mantissa.        */
//     what.u4[1] = what.u4[1] >> 1;
//                                         /* Lsb from hi word.          */
//     what.u4[1] = what.u4[1] | bits;
//     what.u4[0] = sign | exponent | mantissa;
//     if (Z_bytflp > 1) {
//         Short sitemp = what.u2[0];
//         what.u2[0] = what.u2[2];
//         what.u2[2] = sitemp;
//         sitemp = what.u2[1];
//         what.u2[1] = what.u2[3];
//         what.u2[3] = sitemp;
//     }
//                                         /* Store result.              */
//     return what.r8;
// }
//                                         /* swap words if needed       */

//Here's were the vlacalflux code really starts.

   //Initialize the class, new the memory assign the offsets

void ModcompFlux::initialize(){
   offsets = new SimpleOrderedMap<String, Int>(0);
   SimpleOrderedMap<String, Int> &fluxRecordOffsets = *offsets;
   fluxRecordOffsets("sdid") = 0;
   fluxRecordOffsets("sdpid") = 2;
   fluxRecordOffsets("sdsou") = 8;
   fluxRecordOffsets("sdeph") = 24;
   fluxRecordOffsets("sdcrm") = 26;
   fluxRecordOffsets("ymjad") = 30;
   fluxRecordOffsets("flux") = 34;
   fluxRecordOffsets("sdsky") = 38;
   fluxRecordOffsets("sdiat") = 54;
   fluxRecordOffsets("ha") = 58;
   fluxRecordOffsets("el") = 62;
   fluxRecordOffsets("goodif") = 66;
   fluxRecordOffsets("sdsta") = 74;
   fluxRecordOffsets("nant") = 78;
   fluxRecordOffsets("alist") = 80;
   fluxRecordOffsets("x") = 134;
   logicalRecord = new Char[4*256];
   ieeeRecord = new FluxRecord;
   return;
}

// assembles the logical record from the physical ones.

void ModcompFlux::assembleLogical(istream &inStream)
{  uInt i(0);
   while(i<4){         // Physical records come in blocks of 4, last record
                       // is null padded.
      inStream.read(physRecord, 256);
      memcpy(logicalRecord+(i*252), physRecord+4, 252);//strip the byte headers
      i++;
   }
   convertToIEEE(); //convert from modcomp to ieee floating point.
   return;
}


// do the floating point conversions.

void ModcompFlux::convertToIEEE()
{
   SimpleOrderedMap<String, Int> &fluxRecordOffsets = *offsets;
   memcpy(&ieeeRecord->sdid, logicalRecord +fluxRecordOffsets("sdid"), 2);
   if(ieeeRecord->sdid > 0 && ieeeRecord->sdid < 4){
      memcpy(ieeeRecord->sdpid, logicalRecord + fluxRecordOffsets("sdpid"), 6);
      *(ieeeRecord->sdpid+6) = '\0';
      memcpy(ieeeRecord->sdsou, logicalRecord + fluxRecordOffsets("sdsou"),16);
      *(ieeeRecord->sdsou+15) = '\0';
      memcpy(&ieeeRecord->sdeph, logicalRecord + fluxRecordOffsets("sdeph"),2);
      memcpy(ieeeRecord->sdcrm, logicalRecord + fluxRecordOffsets("sdcrm"), 4);
      *(ieeeRecord->sdcrm+3) = '\0';
      memcpy(&ieeeRecord->ymjad, logicalRecord + fluxRecordOffsets("ymjad"),4);
      ieeeRecord->flux = floatFromModCompFP(logicalRecord +
                                            fluxRecordOffsets("flux"));
      {
       for(int i=0;i<4;i++){
         ieeeRecord->calflux[i] = ieeeRecord->flux;
         ieeeRecord->sdsky[i] = floatFromModCompFP(logicalRecord +
                                 fluxRecordOffsets("sdsky") + i*4);
       }
      }
      ieeeRecord->sdiat = floatFromModCompFP(logicalRecord +
                                              fluxRecordOffsets("sdiat"));
      ieeeRecord->ha = floatFromModCompFP(logicalRecord +
                                           fluxRecordOffsets("ha"));
      ieeeRecord->el = floatFromModCompFP(logicalRecord +
                                          fluxRecordOffsets("el"));
      memcpy(ieeeRecord->goodif, logicalRecord +
                                 fluxRecordOffsets("goodif"), 8);
      {
        //
        //On the MODCOMP 0 is true anything is false
        //
        for(int i=0;i<4;i++){
           if(!ieeeRecord->goodif[i])
              ieeeRecord->goodif[i] = True;
           else
              ieeeRecord->goodif[i] = False;
        }
      }
      ieeeRecord->sdsta = floatFromModCompFP(logicalRecord +
                                             fluxRecordOffsets("sdsta"));
      memcpy(&ieeeRecord->nant, logicalRecord + fluxRecordOffsets("nant"), 2);
      {
       for(int i=0;i<ieeeRecord->nant;i++){
          memcpy(&ieeeRecord->alist[i], logicalRecord +
                                        fluxRecordOffsets("alist") + 2*i, 2);
       }
      }

// Here's where we do the calibrator flux calculation
   
      {
          //
          //Antennas vary more quickly than IFs  so it's all the complex
          //fluxes for a given antenna for a given IF, then we do the next
          //antenna.
          //
       for(int j=0;j<4;j++){
          uInt antCount(0);
          ieeeRecord->calflux[j] = 0.0;
          if(ieeeRecord->goodif[j]){
             for(int i=0;i<ieeeRecord->nant;i++){
                ieeeRecord->x[j][i] = 
                  Complex( floatFromModCompFP(logicalRecord +
                                fluxRecordOffsets("x") + j*27*8 + 8*i),
                           floatFromModCompFP(logicalRecord +
                                fluxRecordOffsets("x") + j*27*8 + 8*i+ 4));
                if(abs(ieeeRecord->x[j][i]) > 0.001){
                   ieeeRecord->calflux[j] += abs(ieeeRecord->x[j][i]);
                   antCount++;
                }
             }
             if(antCount > 0)
                ieeeRecord->calflux[j] /= antCount;
             antCount=0;
          }
       }
      }
   }
   return;
}

// Now the global functions, Maybe they should be member functions of
// ModcompFlux???

#include <tables/Tables/TableDesc.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/ScaColDesc.h>
#include <tables/Tables/ArrColDesc.h>
#include <tables/Tables/TableRow.h>
#include <tables/Tables/StManAipsIO.h>
#include <casa/Containers/RecordField.h>
#include <casa/Arrays/Vector.h>

Table *createFluxTable(const String &tableName)
{
   TableDesc td("fluxTableDesc", "1", TableDesc::Scratch);
   td.comment() = "VLA Calibrater Flux Table";
   td.addColumn(ScalarColumnDesc<Int>("subarray", "Subarray"));
   td.addColumn(ScalarColumnDesc<String>("progid", "Program ID"));
   td.addColumn(ScalarColumnDesc<String>("source", "Source Name"));
   td.addColumn(ScalarColumnDesc<Short>("epoch", "Epoch"));
   td.addColumn(ScalarColumnDesc<String>("correlator_mode",
                                         "Correlator Mode"));
   td.addColumn(ScalarColumnDesc<Int>("mjad", "Modifie Julian IAT Day"));
   td.addColumn(ScalarColumnDesc<Float>("flux", "Flux from card"));
   td.addColumn(ArrayColumnDesc<Float>("calflux", "Calculated Flux "));
   td.addColumn(ArrayColumnDesc<Float>("skyfreq", "Sky Frequency"));
   td.addColumn(ScalarColumnDesc<Float>("iat", "IAT"));
   td.addColumn(ScalarColumnDesc<Float>("ha", "Hour Angle"));
   td.addColumn(ScalarColumnDesc<Float>("el", "Elevation"));
   td.addColumn(ArrayColumnDesc<Short>("goodif", "Good IFs", 0));
   td.addColumn(ScalarColumnDesc<Float>("sdsta", "Start time of scan"));
   td.addColumn(ScalarColumnDesc<Short>("nant", "Number of Antennas"));
   td.addColumn(ArrayColumnDesc<Short>("alist", "Antennas in Subarray"));
   td.addColumn(ArrayColumnDesc<Complex>("flux_ifa", "Flux for IF A"));
   td.addColumn(ArrayColumnDesc<Complex>("flux_ifb", "Flux for IF B"));
   td.addColumn(ArrayColumnDesc<Complex>("flux_ifc", "Flux for IF C"));
   td.addColumn(ArrayColumnDesc<Complex>("flux_ifd", "Flux for IF D"));
   SetupNewTable newtab(tableName, td, Table::New);
   StManAipsIO stman;
   newtab.bindAll(stman);
   return new Table(newtab);
}


void addFluxRecord(Table *fluxTable, FluxRecord *fluxRecord)
{
   fluxTable->addRow();
   uInt nrows = fluxTable->nrow();
   TableRow tr(*fluxTable);

   RecordFieldPtr<Int>             subarray(tr.record(), "subarray");
   RecordFieldPtr<String>          progid(tr.record(), "progid");
   RecordFieldPtr<String>          source(tr.record(), "source");
   RecordFieldPtr<Short>           epoch(tr.record(), "epoch");
   RecordFieldPtr<String>          correlator_mode(tr.record(),
                                                   "correlator_mode");
   RecordFieldPtr<Int>             mjad(tr.record(), "mjad");
   RecordFieldPtr<Float>           flux(tr.record(), "flux");
   RecordFieldPtr<Array<Float> >   calflux(tr.record(), "calflux");
   RecordFieldPtr<Array<Float> >  skyfreq(tr.record(), "skyfreq");
   RecordFieldPtr<Float>          iat(tr.record(), "iat");
   RecordFieldPtr<Float>          ha(tr.record(), "ha");
   RecordFieldPtr<Float>           el(tr.record(), "el");
   RecordFieldPtr<Array<Short>  > goodif(tr.record(), "goodif");
   RecordFieldPtr<Float>           sdsta(tr.record(), "sdsta");
   RecordFieldPtr<Short>           nant(tr.record(), "nant");
   RecordFieldPtr<Array<Short>  >  alist(tr.record(), "alist");
   RecordFieldPtr<Array<Complex> > flux_ifa(tr.record(), "flux_ifa");
   RecordFieldPtr<Array<Complex> > flux_ifb(tr.record(), "flux_ifb");
   RecordFieldPtr<Array<Complex> > flux_ifc(tr.record(), "flux_ifc");
   RecordFieldPtr<Array<Complex> > flux_ifd(tr.record(), "flux_ifd");

// Assign the data

   *subarray = fluxRecord->sdid;
   *progid = fluxRecord->sdpid;
   *source = fluxRecord->sdsou;
   *epoch = fluxRecord->sdeph;
   *correlator_mode = fluxRecord->sdcrm;
   *mjad = fluxRecord->ymjad;
   *flux = fluxRecord->flux;
   calflux.define(Vector<Float>(IPosition(1,4), fluxRecord->calflux));
   skyfreq.define(Vector<Float>(IPosition(1,4), fluxRecord->sdsky));
   *iat = fluxRecord->sdiat;
   *ha = fluxRecord->ha;
   *el = fluxRecord->el;
   goodif.define(Vector<Short>(IPosition(1,4),fluxRecord->goodif));
   *sdsta = fluxRecord->sdsta;
   *nant = fluxRecord->nant;
   alist.define(Vector<Short>(IPosition(1,fluxRecord->nant),
                              fluxRecord->alist));
   flux_ifa.define(Vector<Complex>(IPosition(1,fluxRecord->nant),
                                   fluxRecord->x[0]));
   flux_ifb.define(Vector<Complex>(IPosition(1,fluxRecord->nant),
                                   fluxRecord->x[1]));
   flux_ifc.define(Vector<Complex>(IPosition(1,fluxRecord->nant),
                                   fluxRecord->x[2]));
   flux_ifd.define(Vector<Complex>(IPosition(1,fluxRecord->nant),
                                   fluxRecord->x[3]));
   tr.put(nrows-1);  //Update the data in the table
   return;
}

// Here's the main routine for driving the flux filler

#include <casa/OS/Directory.h>

#include <casa/namespace.h>
int main(Int argc, Char **argv)
{  istream *data_in(0);   // define an istream pointer for reading data
   Table *fluxTable(0);
   if(argc > 1){
      Directory outTable(argv[1]);   // First argument is always the table
      if(outTable.exists()){
         fluxTable = new Table(argv[1], Table::Update);
      } else {
         fluxTable = createFluxTable(argv[1]);
      }
      ifstream file_in(argv[2]);     // Second argument is the input file name
      if(file_in){
         data_in = &file_in;         // Read from a file
      } else {
         data_in = &cin;             // read from standar in
      }
      if(data_in){
         ModcompFlux *inputData = new ModcompFlux; // Create the helper class
            // keep reading data until we run out.
         while(!data_in->eof()){
           FluxRecord *eh = inputData->readLogical(*data_in);
           addFluxRecord(fluxTable, eh);
               //  Too lazy to use logging.
           cerr << "Made logical record. " << eh->sdid << " Time stamp " << eh->sdiat << " program id: " << eh->sdpid << endl;
         }
         delete inputData;  // clean up helper class
         cerr << "All done" << endl;
      }
      delete fluxTable;  // close out the table
  
   } else {
      cerr << "Please specify the table to store data." << endl;
   }

   return(0);
}
