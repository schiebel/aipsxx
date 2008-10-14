
// -----------------------------------------------------------------------------

/*

StatToolbox.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++/Cuttlefish

Description:
------------
This file contains the include information for the StatToolbox.cc file.

Modification history:
---------------------
1999 Mar 06 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_STATTOOLBOX_H
#define NPOI_STATTOOLBOX_H


// Includes

extern "C" {
  #include <stdlib.h>               // Standard Library
  #include <math.h>                 // Math
}

#include <casa/aips.h>              // aips++
#include <casa/Exceptions/Error.h>  // aips++ Error classes
#include <casa/BasicSL/String.h>  // aips++ String class
#include <casa/Arrays/Matrix.h>     // aips++ Matrix class
#include <casa/Arrays/Vector.h>     // aips++ Vector class

#include <npoi/GDC/ConstantDefs.h>  // Constant definitions
#include <npoi/HDS/GeneralStatus.h> // General status


#include <casa/namespace.h>
// Class definition

class StatToolbox : public ConstantDefs, public GeneralStatus {

  public:

    static Double max( const Vector<Double>* const poData,
        const Vector<Double>* const poDataErr = NULL );
    static Double max( const Matrix<Double>* const poData,
        const Matrix<Double>* const poDataErr = NULL );

    static Double mean( const Vector<Double>* const poData,
        const Vector<Double>* const poDataErr = NULL );
    static Double mean( const Matrix<Double>* const poData,
        const Matrix<Double>* const poDataErr = NULL );

    static Double meanerr( const Vector<Double>* const poData,
        const Vector<Double>* const poDataErr = NULL );
    static Double meanerr( const Matrix<Double>* const poData,
        const Matrix<Double>* const poDataErr = NULL );

    static Double median( const Vector<Double>* const poData );

    static Double min( const Vector<Double>* const poData,
        const Vector<Double>* const poDataErr = NULL );
    static Double min( const Matrix<Double>* const poData,
        const Matrix<Double>* const poDataErr = NULL );

    static Double rand01( void );

    static Double randgauss( const Double dMu = 0.0,
        const Double dSigma = 1.0 );

    static Double rchi2( const Vector<Double>* const poData,
        const Vector<Double>* const poDataErr );

    static void sort( const Vector<Int>& oSortKey, Vector<Bool>& oData );
    static void sort( const Vector<Int>& oSortKey, Vector<Int>& oData );
    static void sort( const Vector<Int>& oSortKey, Vector<Double>& oData );
    static void sort( const Vector<Int>& oSortKey, Vector<String>& oData );
    static void sort( const Vector<Int>& oSortKey, Matrix<Bool>& oData );
    static void sort( const Vector<Int>& oSortKey, Matrix<Double>& oData );

    static Vector<Int> sortkey( const Vector<Int>& oData );
    static Vector<Int> sortkey( const Vector<Double>& oData );

    static Double stddev( const Vector<Double>* const poData,
        const Vector<Double>* const poDataErr = NULL );
    static Double stddev( const Matrix<Double>* const poData,
        const Matrix<Double>* const poDataErr = NULL );

    static Double variance( const Vector<Double>* const poData,
        const Vector<Double>* const poDataErr = NULL );
    static Double variance( const Matrix<Double>* const poData,
        const Matrix<Double>* const poDataErr = NULL );
  
  private:
  
    static void __swap( uInt* const puiValue1, uInt* const puiValue2 );
  
};


// #endif (Include file?)

#endif // __STATTOOLBOX_H
