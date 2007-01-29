//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,1999,2001
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
//# $Id: vlacalflux.h,v 19.4 2004/11/30 17:50:41 ddebonis Exp $

#ifndef NRAO_VLACALFLUX_H
#define NRAO_VLACALFLUX_H

//# Forward Declarations

// <summary>
// This class defines the incoming vla flux record and a helper class for 
// translating betweem modcomp to ieee floating point.
// </summary>

// <use visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SimpleOrderedMap
//   <li> String
//   <li> Vector
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// ModcompFlux provides a way to assemble a logical record from the physical
// modcomp records and then translate the logical modcomp record into an IEEE
// floating point form.  This is similar to what we would do for a vla filler.
// 
// The "data format" is provided by something called the FluxRecord, which
// is just a padded version of the MODCOMP logical flux record into a simple
// struct.
// </synopsis>
//
// <example>
//         ModcompFlux *inputData = new ModcompFlux; // Create the helper class
//         while(!data_in->eof()){
//           FluxRecord *eh = inputData->readLogical(*data_in);
//           addFluxRecord(fluxTable, eh);
//         }
//         delete inputData;  // clean up helper class
// </example>
//
// <motivation>
// We wanted to look at the antsol flux solutions provied by the VLA on-line
// system.  The data are stored on the Modcomps at the VLA site, so we needed
// a "filler" that could read and produce an AIPS++ table, so we could futher
// investigate the how good are the antsol solutions coming from the on-line
// system.
// </motivation>
//
//
// <thrown>
//    <li> Nothing currently thrown
// </thrown>
//
// <todo asof="1996/11/22">
//   <li> The modcomp to ieee routines should be moved to a separate libarary.
//   <li> Need to handle erroneous data better.
//   <li> There are a couple of global functions in vlacalflux that could be
//        moved to ModcompFlux, may or maynot  be desirable.
// </todo>

#include <casa/aips.h>
#include <casa/iosfwd.h>
#include <casa/Containers/SimOrdMap.h>
#include <casa/BasicSL/String.h>
#include <casa/BasicSL/Complex.h>


#include <casa/namespace.h>
// Here we define a simple data structure for the modcomp logical flux
// record.

struct FluxRecord {
                      // Subarray ID
   Short   sdid;          
                      // Program ID
   Char    sdpid[7];      
                      // Source Name
   Char    sdsou[16];
                      // Epoch
   Short   sdeph;
                      // Correlator Mode
   Char    sdcrm[4];
                      // MJAD
   Int     ymjad;
                      // Flux from the observe card
   Float   flux;          
                      // These are the calculated fluxes for each IF
   Float   calflux[4];    
                      // Sky Frequency (GHz) for each IF.
   Float   sdsky[4];      
                      // IAT since midnight (radians)
   Float   sdiat;         
                      // Hour angle of the observation
   Float   ha;            
                      // Elevation of the observation
   Float   el;            
                      // Flag identify whether the IF is used for flux 
                      // calculation
   Short   goodif[4];     
                      // Time of the start of the scan.
   Float   sdsta;         
                      // Number of antennas in the flux calculation
   Short   nant;          
                      // List of antennas used in the flux calculation
   Short   alist[27];     
                      // Flux calculation for each antenna.
   Complex x[4][27];      
};


    // Helper class for turning the Modcomp physical records into IEEE records

class ModcompFlux {
   public :
        // Standard constructor, sets the pointers to 0, then intializes
        // the whole shebang.
     ModcompFlux() : logicalRecord(0), ieeeRecord(0), offsets(0) {
                     initialize();}

    ~ModcompFlux() {if(logicalRecord) delete logicalRecord;
                    if(ieeeRecord) delete ieeeRecord;
                    if(offsets) delete offsets;}

        // Reads from an istream the modcomp physical records. It assembles
        // the logical record, translates floating point numbers from
        // modcomp to IEEE and calculates the fluxes for each IF.
     FluxRecord *readLogical(istream &is){assembleLogical(is);
                                          return ieeeRecord;}
   private :
                                  // Modcomp physical record is 1kB
     Char        physRecord[1024]; 
                                  // Modcomp logical record is about 4kB
                                  // Logical record is assembled from 4
                                  // physical records.
     Char       *logicalRecord;
                                  // The IEEE version of the logical record
                                  // with calculated fluxes.
     FluxRecord *ieeeRecord;       
                                  // The offset map.  keyword is the variable
                                  // value is the offset in bytes from the
                                  // start of the logical record.
     SimpleOrderedMap<String, Int> *offsets;

                                  // News the memory setups up the offsets
                                  // map.
     void        initialize();
                                  // Turns the modcomp floating points into
                                  // IEEE
     void        convertToIEEE();
                                  //Assembles the logical record from the
                                  //physical, strips out the header bytes.
     void        assembleLogical(istream &);
};


#endif
