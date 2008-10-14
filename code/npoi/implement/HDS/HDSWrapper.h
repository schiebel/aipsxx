//# HDSWrapper.h is part of Cuttlefish (NPOI data reduction package)
//# Copyright (C) 1999,2000
//# United States Naval Observatory; Washington, DC; USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is designed for use only in AIPS++ (National Radio Astronomy
//# Observatory; Charlottesville, VA; USA) in the hope that it will be useful,
//# but WITHOUT ANY WARRANTY; without even the implied warranty of 
//# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
//# See the GNU Library General Public License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning Cuttlefish should be addressed as follows:
//#        Internet email: nme@nofs.navy.mil
//#        Postal address: Dr. Nicholas Elias
//#                        United States Naval Observatory
//#                        Navy Prototype Optical Interferometer
//#                        P.O. Box 1149
//#                        Flagstaff, AZ 86002-1149 USA
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: HDSWrapper.h,v 19.2 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

HDSWrapper.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the include information for the HDSWrapper.cc file.

Modification history:
---------------------
1998 Nov 12 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_HDSWRAPPER_H
#define NPOI_HDSWRAPPER_H


// Includes

extern "C" {

  #include <ctype.h>   // Character
  #include <string.h>  // String

  #include <f77.h>     // F77
  #include <cnf.h>     // HDS C-to-FORTRAN and FORTRAN-to-C

  #include <sae_par.h> // HDS Starlink Adam

  #include <dat_par.h> // HDS data parameters
//  #include <dat_err.h> // HDS data errors

  #include <ems.h>     // HDS error prototypes
  #include <ems_par.h> // HDS error parameters

}

// CNF definitions

extern "C" {

  F77_SUBROUTINE(dat_alter)( CHARACTER( fLocator ), INTEGER( fNumDim ),
      INTEGER_ARRAY( fDim ), INTEGER( fStatus ) TRAIL( fLocator ) );

  F77_SUBROUTINE(dat_annul)( CHARACTER( fLocator ), INTEGER( fStatus )
      TRAIL( fLocator ) );

  F77_SUBROUTINE(dat_cell)( CHARACTER( fLocator ), INTEGER( fNumDim ),
      INTEGER_ARRAY( fDim ), CHARACTER( fLocatorCell ), INTEGER( fStatus )
      TRAIL( fLocator ) TRAIL( fLocatorCell ) );

  F77_SUBROUTINE(dat_clen)( CHARACTER( fLocator ), INTEGER( fCLen ),
      INTEGER( fStatus ) TRAIL( fLocator ) );

  F77_SUBROUTINE(dat_clone)( CHARACTER( fLocator ), CHARACTER( fLocatorClone ),
      INTEGER( fStatus ) TRAIL( fLocator ) TRAIL( fLocatorFind ) );

  F77_SUBROUTINE(dat_copy)( CHARACTER( fLocator ), CHARACTER( fLocatorCopy ),
      CHARACTER( fName ), INTEGER( fStatus ) TRAIL( fLocator )
      TRAIL( fLocatorCopy ) TRAIL( fName ) );

  F77_SUBROUTINE(dat_erase)( CHARACTER( fLocator ), CHARACTER( fName ),
      INTEGER( fStatus ) TRAIL( fLocator ) TRAIL( fName ) );

  F77_SUBROUTINE(dat_ermsg)( INTEGER( fStatus ), INTEGER( fLength ),
      CHARACTER( fMessage ) TRAIL( fMessage ) );

  F77_SUBROUTINE(dat_find)( CHARACTER( fLocator ), CHARACTER( fName ),
      CHARACTER( fLocatorFind ), INTEGER( fStatus ) TRAIL( fLocator )
      TRAIL( fName ) TRAIL( fLocatorFind ) );

  F77_SUBROUTINE(dat_get)( CHARACTER( fLocator ), CHARACTER( fType ),
      INTEGER( fNumDim ), INTEGER_ARRAY( fDim ), CHARACTER_ARRAY( fData ),
      INTEGER( fStatus ) TRAIL( fLocator ) TRAIL( fType ) TRAIL( fData ) );

  F77_SUBROUTINE(dat_index)( CHARACTER( fLocator ), INTEGER( fIndex ),
      CHARACTER( fLocatorIndex ), INTEGER( fStatus ) TRAIL( fLocator )
      TRAIL( fName ) );

  F77_SUBROUTINE(dat_len)( CHARACTER( fLocator ), INTEGER( fLen ),
      INTEGER( fStatus ) TRAIL( fLocator ) );

  F77_SUBROUTINE(dat_move)( CHARACTER( fLocator ), CHARACTER( fLocatorMove ),
      CHARACTER( fName ), INTEGER( fStatus ) TRAIL( fLocator )
      TRAIL( fLocatorMove ) TRAIL( fName ) );

  F77_SUBROUTINE(dat_name)( CHARACTER( fLocator ), CHARACTER( fName ),
      INTEGER( fStatus ) TRAIL( fLocator ) TRAIL( fName ) );

  F77_SUBROUTINE(dat_ncomp)( CHARACTER( fLocator ), INTEGER( fNComp ),
      INTEGER( fStatus ) TRAIL( fLocator ) );

  F77_SUBROUTINE(dat_new)( CHARACTER( fLocator ), CHARACTER( fName ),
      CHARACTER( fType ), INTEGER( fNumDim ), INTEGER_ARRAY( fDim ),
      INTEGER( fStatus ) TRAIL( fLocator ) TRAIL( fName ) TRAIL( fType ) );

  F77_SUBROUTINE(dat_prec)( CHARACTER( fLocator ), INTEGER( fPrec ),
      INTEGER( fStatus ) TRAIL( fLocator ) );

  F77_SUBROUTINE(dat_prim)( CHARACTER( fLocator ), LOGICAL( fPrim ),
      INTEGER( fStatus ) TRAIL( fLocator ) );

  F77_SUBROUTINE(dat_put)( CHARACTER( fLocator ), CHARACTER( fType ),
      INTEGER( fNumDim ), INTEGER_ARRAY( fDim ), CHARACTER_ARRAY( fData ),
      INTEGER( fStatus ) TRAIL( fLocator ) TRAIL( fType ) TRAIL( fData ) );

  F77_SUBROUTINE(dat_renam)( CHARACTER( fLocator ), CHARACTER( fName ),
      INTEGER( fStatus ) TRAIL( fLocator ) TRAIL( fName ) );

  F77_SUBROUTINE(dat_reset)( CHARACTER( fLocator ), INTEGER( fStatus )
      TRAIL( fLocator ) );

  F77_SUBROUTINE(dat_retyp)( CHARACTER( fLocator ), CHARACTER( fType ),
      INTEGER( fStatus ) TRAIL( fLocator ) TRAIL( fType ) );

  F77_SUBROUTINE(dat_shape)( CHARACTER( fLocator ), INTEGER( fNumDimTemp ),
      INTEGER( fNumDim ), INTEGER_ARRAY( fDim ), INTEGER( fStatus )
      TRAIL( fLocator ) );

  F77_SUBROUTINE(dat_size)( CHARACTER( fLocator ), INTEGER( fSize ),
      INTEGER( fStatus ) TRAIL( fLocator ) );

  F77_SUBROUTINE(dat_slice)( CHARACTER( fLocator ), INTEGER( fNumDim ),
      INTEGER_ARRAY( fDimLow ), INTEGER_ARRAY( fDimHigh ),
      CHARACTER( fLocatorSlice ), INTEGER( fStatus ) TRAIL( fLocator )
      TRAIL( fLocatorSlice ) );

  F77_SUBROUTINE(dat_state)( CHARACTER( fLocator ), LOGICAL( fState ),
      INTEGER( fStatus ) TRAIL( fLocator ) );

  F77_SUBROUTINE(dat_struc)( CHARACTER( fLocator ), LOGICAL( fStruc ),
      INTEGER( fStatus ) TRAIL( fLocator ) );

  F77_SUBROUTINE(dat_there)( CHARACTER( fLocator ), CHARACTER( fName ),
      LOGICAL( fThere ), INTEGER( fStatus ) TRAIL( fLocator ) TRAIL( fName ) );

  F77_SUBROUTINE(dat_type)( CHARACTER( fLocator ), CHARACTER( fType ),
      INTEGER( fStatus ) TRAIL( fLocator ) TRAIL( fType ) );

  F77_SUBROUTINE(dat_valid)( CHARACTER( fLocator ), LOGICAL( fValid ),
      INTEGER( fStatus ) TRAIL( fLocator ) );

  F77_SUBROUTINE(hds_copy)( CHARACTER( fLocator ), CHARACTER( fFile ),
      CHARACTER( fName ), INTEGER( fStatus ) TRAIL( fLocator ) TRAIL( fFile )
      TRAIL( fName ) );

  F77_SUBROUTINE(hds_new)( CHARACTER( fFile ), CHARACTER( fName ),
      CHARACTER( fType ), INTEGER( fNumDim ), INTEGER_ARRAY( fDim ),
      CHARACTER( fLocator ), INTEGER( fStatus ) TRAIL( fFile ) TRAIL( fName )
      TRAIL( fType ) TRAIL( fLocator ) );

  F77_SUBROUTINE(hds_open)( CHARACTER( fFile ), CHARACTER( fMode ),
      CHARACTER( fLocator ), INTEGER( fStatus ) TRAIL( fFile ) TRAIL( fMode )
      TRAIL( fLocator ) );

  F77_SUBROUTINE(hds_trace)( CHARACTER( fLocator ), INTEGER( fNumLev ),
      CHARACTER( fPath ), CHARACTER( fFile ), INTEGER( fStatus )
      TRAIL( fLocator ) TRAIL( fPath ) TRAIL( fFile ) );

}

#include <casa/namespace.h>
// <summary>A class for wrapping HDS FORTRAN library functions in generic C++</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos=""></reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
// This simple class acts as a namespace to wrap HDS FORTRAN library functions
// in generic C++ (independent of aips++).  No detailed explanation for the
// functions is given.  Check the <A href=http://star-www.rl.ac.uk/>Starlink</A>
// web site for the documentation.
// </synopsis>

// <example>
// <src>HDSWrapper.cc</src>
// <srcblock>{}</srcblock>
// </example>

// Class definition

class HDSWrapper {

  public:
  
    // C++ wrapper for FORTRAN function DAT_ALTER().
    static void dat_alter( const char* const acLocator, const int iNumDim,
        const int* const aiDim, int* const piStatus );

    // C++ wrapper for FORTRAN function DAT_ANNUL().
    static void dat_annul( char* const acLocator, int* const piStatus );

    // C++ wrapper for FORTRAN function DAT_CELL().
    static void dat_cell( const char* const acLocator, const int iNumDim,
        const int* const aiDim, char* const acLocatorCell,
	int* const piStatus );

    // C++ wrapper for FORTRAN function DAT_CLEN().
    static void dat_clen( const char* const acLocator, int* const piCLen,
        int* const piStatus );

    // C++ wrapper for FORTRAN function DAT_CLONE().
    static void dat_clone( const char* const acLocator,
        char* const acLocatorClone, int* const piStatus );
    
    // C++ wrapper for FORTRAN function DAT_COPY().
    static void dat_copy( const char* const acLocator,
        const char* const acLocatorCopy, const char* const acName,
	int* const piStatus );
    
    // C++ wrapper for FORTRAN function DAT_ERASE().
    static void dat_erase( const char* const acLocator,
        const char* const acName, int* const piStatus );

    // C++ wrapper for FORTRAN function DAT_ERMSG().
    static void dat_ermsg( const int iStatus, int* const piLength,
        char* const acMessage );
    
    // C++ wrapper for FORTRAN function DAT_FIND().
    static void dat_find( const char* const acLocator, const char* const acName,
        char* const acLocatorName, int* const piStatus );

    // C++ wrapper for FORTRAN function DAT_GET().
    static void dat_get( const char* const acLocator, const char* const acType,
        const int iNumDim, const int* const aiDim, unsigned char* (*aucData),
	int* const piStatus );

    // C++ wrapper for FORTRAN function DAT_INDEX().
    static void dat_index( const char* const acLocator, const int iIndex,
        char* const acLocatorIndex, int* const piStatus );
    
    // C++ wrapper for FORTRAN function DAT_LEN().
    static void dat_len( const char* const acLocator, int* const piLen,
        int* const piStatus );
    
    // C++ wrapper for FORTRAN function DAT_MOVE().
    static void dat_move( const char* const acLocator,
        const char* const acLocatorMove, const char* const acName,
	int* const piStatus );
    
    // C++ wrapper for FORTRAN function DAT_NAME().
    static void dat_name( const char* const acLocator, char* const acName,
        int* const piStatus );
    
    // C++ wrapper for FORTRAN function DAT_NCOMP().
    static void dat_ncomp( const char* const acLocator, int* const piNComp,
        int* const piStatus );
	
    // C++ wrapper for FORTRAN function DAT_NEW().
    static void dat_new( const char* const acLocator, const char* const acName,
        const char* const acType, const int iNumDim, const int* const aiDim,
	int* const piStatus );
    
    // C++ wrapper for FORTRAN function DAT_PREC().
    static void dat_prec( const char* const acLocator, int* const piPrec,
        int* const piStatus );
    
    // C++ wrapper for FORTRAN function DAT_PRIM().
    static void dat_prim( const char* const acLocator, bool* const pbPrim,
        int* const piStatus );

    // C++ wrapper for FORTRAN function DAT_PUT().
    static void dat_put( const char* const acLocator, const char* const acType,
        const int iNumDim, const int* const aiDim,
        const unsigned char* const aucData, int* const piStatus );

    // C++ wrapper for FORTRAN function DAT_RENAM().
    static void dat_renam( const char* const acLocator,
        const char* const acName, int* const piStatus );
	
    // C++ wrapper for FORTRAN function DAT_RESET().
    static void dat_reset( const char* const acLocator, int* const piStatus );
    
    // C++ wrapper for FORTRAN function DAT_RETYP().
    static void dat_retyp( const char* const acLocator,
        const char* const acType, int* const piStatus );
	
    // C++ wrapper for FORTRAN function DAT_SHAPE().
    static void dat_shape( const char* const acLocator, int* const piNumDim,
        int* const aiDim, int* const piStatus );
	
    // C++ wrapper for FORTRAN function DAT_SIZE().
    static void dat_size( const char* const acLocator, int* const piSize,
        int* const piStatus );

    // C++ wrapper for FORTRAN function DAT_SLICE().
    static void dat_slice( const char* const acLocator, const int iNumDim,
	const int* const aiDimLow, const int* const aiDimHigh,
	char* const acLocatorSlice, int* const piStatus );

    // C++ wrapper for FORTRAN function DAT_STATE().
    static void dat_state( const char* const acLocator, bool* const pbState,
        int* const piStatus );

    // C++ wrapper for FORTRAN function DAT_STRUC().
    static void dat_struc( const char* const acLocator, bool* const pbStruc,
        int* const piStatus );
    
    // C++ wrapper for FORTRAN function DAT_THERE().
    static void dat_there( const char* const acLocator,
        const char* const acName, bool* const pbThere, int* const piStatus );
    
    // C++ wrapper for FORTRAN function DAT_TYPE().
    static void dat_type( const char* const acLocator, char* const acType,
        int* const piStatus );

    // C++ wrapper for FORTRAN function DAT_VALID().
    static void dat_valid( const char* const acLocator, bool* const pbValid,
        int* const piStatus );

    // C++ wrapper for FORTRAN function HDS_COPY().
    static void hds_copy( const char* const acLocator, const char* const acFile,
        const char* const acName, int* const piStatus );

    // C++ wrapper for FORTRAN function HDS_NEW().
    static void hds_new( const char* const acFile, const char* const acName,
        const char* const acType, const int iNumDim, const int* const aiDim,
	char* const acLocator, int* const piStatus );
    
    // C++ wrapper for FORTRAN function HDS_OPEN().
    static void hds_open( const char* const acFile, const char* const acMode,
        char* const acLocator, int* const piStatus );

    // C++ wrapper for FORTRAN function HDS_TRACE().
    static void hds_trace( const char* const acLocator, int* const piNumLev,
        char* const acPath, char* const acFile, int* const piStatus );


  private:

    enum {    
      NUM_CHAR_MAX = 1000
    };

};


// #endif (Include file?)

#endif // __HDSWRAPPER_H
