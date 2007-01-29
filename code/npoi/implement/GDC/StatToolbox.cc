
// -----------------------------------------------------------------------------

/*

StatToolbox.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++/Cuttlefish

Description:
------------
This file contains the StatToolbox{ } class member functions.

Static public member functions:
-------------------------------
max (2 versions), mean (2 versions), meanerr (2 versions), min (2 versions),
rand01, randgauss, rchi2, sort (4 versions), sortkey (2 versions), stddev (2
versions), variance (2 versions).

Static private member functions:
--------------------------------
__swap.

Inherited classes (Cuttlefish):
-------------------------------
GeneralStatus.

Modification history:
---------------------
1999 Mar 06 - Nicholas Elias, USNO/NPOI
              File created with static public member functions max( ) (vector
              version) and mean( ) (vector versions).
1999 Mar 08 - Nicholas Elias, USNO/NPOI
              Static public member function min( ) (vector version) added.
1999 Mar 09 - Nicholas Elias, USNO/NPOI
              Static public member functions meanerr( ) (vector version),
              stddev( ) (vector version), and variance( ) (vector version)
              added.
1999 Mar 10 - Nicholas Elias, USNO/NPOI
              Static public member function rchi2( ) added.
1999 Mar 11 - Nicholas Elias, USNO/NPOI
              Static public member functions sort( ) and sortkey( ) added.
              Static private member function __swap( ) added.
1999 Mar 26 - Nicholas Elias, USNO/NPOI
              Static public member functions rand01( ) and randgauss( ) added.
2000 May 01 - Nicholas Elias, USNO/NPOI
              Static public member function sort( ) (Bool and String versions)
              added.
2000 May 26 - Nicholas Elias, USNO/NPOI
              Static public member functions sort( ) (Int version) and
              sortkey( ) (Int version) added.
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              Static public member functions sort( ) (Bool matrix and Double
              matrix versions added).
2001 Jan 05 - Nicholas Elias, USNO/NPOI
              Static public member functions max( ) (matrix version) and min( )
              (matrix version) added.
2001 Jan 17 - Nicholas Elias, USNO/NPOI
              Static public member functions mean( ) (matrix version),
              meanErr( ) (matrix version), stdDev( ) (matrix version), and
              variance( ) (matrix version) added.

*/

// -----------------------------------------------------------------------------

// Includes

#include "StatToolbox.h" // Statistics toolbox

// -----------------------------------------------------------------------------

/*

StatToolbox::max (vector)

Description:
------------
This static public member function finds the maximum.  Error bars may be added,
for plot limits.

Inputs:
-------
poData    - The data.
poDataErr - The data errors (default = NULL, no plot limits).

Outputs:
--------
The maximum, returned via the function value.

Modification history:
---------------------
1999 Mar 06 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Double StatToolbox::max( const Vector<Double>* const poData,
    const Vector<Double>* const poDataErr ) {

  // Declare the local variables

  uInt uiData; // The data counter

  Double dMax; // The maximum value


  // Check the inputs

  if ( poData->nelements() < 1 ) {
    throw( ermsg( "Invalid number of data", "StatToolbox", "max" ) );
  }

  if ( poDataErr != NULL ) {
    if ( poData->nelements() != poDataErr->nelements() ) {
      throw( ermsg( "Vectors have different numbers of data", "StatToolbox",
          "max" ) );
    }
  }


  // Find the maximum

  if ( poDataErr == NULL ) {

    dMax = (*poData)(0);

    for ( uiData = 1; uiData < poData->nelements(); uiData++ ) {
      if ( (*poData)(uiData) > dMax ) {
        dMax = (*poData)(uiData);
      }
    }

  } else {

    dMax = (*poData)(0) + (*poDataErr)(0);

    for ( uiData = 1; uiData < poData->nelements(); uiData++ ) {
      if ( (*poData)(uiData) + (*poDataErr)(uiData) > dMax ) {
        dMax = (*poData)(uiData) + (*poDataErr)(uiData);
      }
    }

  }


  // Return the maximum

  return( dMax );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::max (matrix)

Description:
------------
This static public member function finds the maximum.  Error bars may be added,
for plot limits.

Inputs:
-------
poData    - The data.
poDataErr - The data errors (default = NULL, no plot limits).

Outputs:
--------
The maximum, returned via the function value.

Modification history:
---------------------
2001 Jan 05 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Double StatToolbox::max( const Matrix<Double>* const poData,
    const Matrix<Double>* const poDataErr ) {

  // Declare the local variables

  uInt uiColumn; // The column counter
  uInt uiData;   // The data counter

  Double dMax;   // The maximum value


  // Check the inputs

  if ( poData->nelements() < 1 ) {
    throw( ermsg( "Invalid number of data", "StatToolbox", "max" ) );
  }

  if ( poDataErr != NULL ) {
    if ( poData->nelements() != poDataErr->nelements() ) {
      throw( ermsg( "Vectors have different numbers of data", "StatToolbox",
          "max" ) );
    }
  }


  // Find the maximum

  if ( poDataErr == NULL ) {

    dMax = (*poData)(0,0);

    for ( uiData = 0; uiData < poData->nrow(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < poData->ncolumn(); uiColumn++ ) {
        if ( (*poData)(uiData,uiColumn) > dMax ) {
          dMax = (*poData)(uiData,uiColumn);
        }
      }
    }

  } else {

    dMax = (*poData)(0,0) + (*poDataErr)(0,0);

    for ( uiData = 0; uiData < poData->nrow(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < poData->ncolumn(); uiColumn++ ) {
        if ( (*poData)(uiData,uiColumn)+(*poDataErr)(uiData,uiColumn) > dMax ) {
          dMax = (*poData)(uiData,uiColumn) + (*poDataErr)(uiData,uiColumn);
        }
      }
    }

  }


  // Return the maximum

  return( dMax );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::mean (vector)

Description:
------------
This static public member function calculates the (weighted) mean.

Inputs:
-------
poData    - The data.
poDataErr - The data errors (default = NULL, no weighted mean).

Outputs:
--------
The (weighted) mean, returned via the function value.

Modification history:
---------------------
1999 Mar 05 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Double StatToolbox::mean( const Vector<Double>* const poData,
    const Vector<Double>* const poDataErr ) {

  // Declare the local variables
 
  uInt uiData;    // The data counter

  Double dDen;    // The weighted mean denominators, if necessary
  Double dMean;   // The (weighted) mean
  Double dNum;    // The weighted mean numerators, if necessary
  Double dWeight; // The weight, if necessary
 
 
  // Check the inputs
 
  if ( poData->nelements() < 1 ) {
    throw( ermsg( "Invalid number of data", "StatToolbox", "mean" ) );
  }

  if ( poDataErr != NULL ) {
    if ( poData->nelements() != poDataErr->nelements() ) {
      throw( ermsg( "Vectors have different numbers of data", "StatToolbox",
          "mean" ) );
    }
  }


  // Calculate the (weighted) mean

  if ( poDataErr == NULL ) {

    dMean = 0.0;

    for ( uiData = 0; uiData < poData->nelements(); uiData++ ) {
      dMean += (*poData)(uiData);
    }

    dMean /= (Double) poData->nelements();

  } else {
 
    dNum = 0.0;
    dDen = 0.0;
 
    for ( uiData = 0; uiData < poData->nelements(); uiData++ ) {
      if ( (*poDataErr)(uiData) <= 0.0 ) {
        throw( ermsg( "Invalid data error(s), cannot calculate weighted mean",
            "StatToolbox", "mean" ) );
      }
      dWeight = 1.0 / ( (*poDataErr)(uiData) * (*poDataErr)(uiData) );
      dNum += dWeight * (*poData)(uiData);
      dDen += dWeight;
    }

    dMean = dNum / dDen;

  }
 
 
  // Return the (weighted) mean

  return( dMean );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::mean (matrix)

Description:
------------
This static public member function calculates the (weighted) mean.

Inputs:
-------
poData    - The data.
poDataErr - The data errors (default = NULL, no weighted mean).

Outputs:
--------
The (weighted) mean, returned via the function value.

Modification history:
---------------------
2001 Jan 17 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Double StatToolbox::mean( const Matrix<Double>* const poData,
    const Matrix<Double>* const poDataErr ) {

  // Declare the local variables
 
  uInt uiColumn;  // The column counter
  uInt uiData;    // The data counter

  Double dDen;    // The weighted mean denominators, if necessary
  Double dMean;   // The (weighted) mean
  Double dNum;    // The weighted mean numerators, if necessary
  Double dWeight; // The weight, if necessary
 
 
  // Check the inputs
 
  if ( poData->nelements() < 1 ) {
    throw( ermsg( "Invalid number of data", "StatToolbox", "mean" ) );
  }

  if ( poDataErr != NULL ) {
    if ( poData->nrow() != poDataErr->nrow() ||
         poData->ncolumn() != poDataErr->ncolumn() ) {
      throw( ermsg( "Matrices have different numbers of data", "StatToolbox",
          "mean" ) );
    }
  }


  // Calculate the (weighted) mean

  if ( poDataErr == NULL ) {

    dMean = 0.0;

    for ( uiData = 0; uiData < poData->nrow(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < poData->ncolumn(); uiColumn++ ) {
        dMean += (*poData)(uiData,uiColumn);
      }
    }

    dMean /= (Double) poData->nelements();

  } else {
 
    dNum = 0.0;
    dDen = 0.0;
 
    for ( uiData = 0; uiData < poData->nrow(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < poData->ncolumn(); uiColumn++ ) {
        if ( (*poDataErr)(uiData,uiColumn) <= 0.0 ) {
          throw( ermsg( "Invalid data error(s), cannot calculate weighted mean",
              "StatToolbox", "mean" ) );
        }
      }
      dWeight =
          1.0 / ( (*poDataErr)(uiData,uiColumn)*(*poDataErr)(uiData,uiColumn) );
      dNum += dWeight * (*poData)(uiData,uiColumn);
      dDen += dWeight;
    }

    dMean = dNum / dDen;

  }
 
 
  // Return the (weighted) mean

  return( dMean );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::meanerr (vector)

Description:
------------
This static public member function calculates the (weighted) mean error.

Inputs:
-------
poData    - The data.
poDataErr - The data errors (default = NULL, no weighted mean).

Outputs:
--------
The (weighted) mean error, returned via the function value.

Modification history:
---------------------
1999 Mar 09 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Double StatToolbox::meanerr( const Vector<Double>* const poData,
    const Vector<Double>* const poDataErr ) {

  // Declare the local variables
  
  Double dMeanErr;  // The (weighted) mean error
  Double dVariance; // The variance
 
 
  // Check the inputs
 
  if ( poData->nelements() < 2 ) {
    throw( ermsg( "Invalid number of data", "StatToolbox", "meanerr" ) );
  }

  if ( poDataErr != NULL ) {
    if ( poData->nelements() != poDataErr->nelements() ) {
      throw( ermsg( "Vectors have different numbers of data", "StatToolbox",
          "meanerr" ) );
    }
  }


  // Calculate the (weighted) mean error
  
  try {
    dVariance = variance( poData, poDataErr );
    dMeanErr = sqrt( dVariance / (Double) poData->nelements() );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "variance( ) error\n" + oAipsError.getMesg(), "StatToolbox",
        "meanerr" ) );
  }
  
  
  // Return the (weighted) mean error
  
  return( dMeanErr );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::meanerr (matrix)

Description:
------------
This static public member function calculates the (weighted) mean error.

Inputs:
-------
poData    - The data.
poDataErr - The data errors (default = NULL, no weighted mean).

Outputs:
--------
The (weighted) mean error, returned via the function value.

Modification history:
---------------------
2001 Jan 17 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Double StatToolbox::meanerr( const Matrix<Double>* const poData,
    const Matrix<Double>* const poDataErr ) {

  // Declare the local variables
  
  Double dMeanErr;  // The (weighted) mean error
  Double dVariance; // The variance
 
 
  // Check the inputs
 
  if ( poData->nelements() < 2 ) {
    throw( ermsg( "Invalid number of data", "StatToolbox", "meanerr" ) );
  }

  if ( poDataErr != NULL ) {
    if ( poData->nrow() != poDataErr->nrow() ||
         poData->ncolumn() != poDataErr->ncolumn() ) {
      throw( ermsg( "Matrices have different numbers of data", "StatToolbox",
          "meanerr" ) );
    }
  }


  // Calculate the (weighted) mean error
  
  try {
    dVariance = variance( poData, poDataErr );
    dMeanErr = sqrt( dVariance / (Double) poData->nelements() );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "variance( ) error\n" + oAipsError.getMesg(), "StatToolbox",
        "meanerr" ) );
  }
  
  
  // Return the (weighted) mean error
  
  return( dMeanErr );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::median

Description:
------------
This static public member function calculates the median.

Inputs:
-------
poData - The data.

Outputs:
--------
The median, returned via the function value.

Modification history:
---------------------
1999 Mar 11 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Double StatToolbox::median( const Vector<Double>* const poData ) {

  // Declare the local variables
  
  uInt uiElement1; // A data element
  uInt uiElement2; // A data element

  Double dMedian;  // The median
 
 
  // Check the inputs
 
  if ( poData->nelements() < 1 ) {
    throw( ermsg( "Invalid number of data", "StatToolbox", "median" ) );
  }
  
  
  // Calculate the median
  
  Vector<Int> oSortKey = Vector<Int>( sortkey( *poData ) );

  Vector<Double> oData = Vector<Double>( *poData );
  sort( oSortKey, oData );
  
  uiElement1 = ( oSortKey.nelements() - 1 ) / 2;
    
  if ( oSortKey.nelements() % 2 == 0 ) {
    uiElement2 = uiElement1 + 1;
    dMedian = 0.5 * ( (*poData)(uiElement1) + (*poData)(uiElement2) );
  } else {
    dMedian = (*poData)(uiElement1);
  }
 
 
  // Return the median

  return( dMedian );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::min (vector)

Description:
------------
This static public member function finds the minimum.  Error bars may be
subtracted, for plot limits.

Inputs:
-------
poData    - The data.
poDataErr - The data errors (default = NULL, no plot limits).

Outputs:
--------
The minimum, returned via the function value.

Modification history:
---------------------
1999 Mar 08 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Double StatToolbox::min( const Vector<Double>* const poData,
    const Vector<Double>* const poDataErr ) {

  // Declare the local variables

  uInt uiData; // The data counter

  Double dMin; // The minimum value


  // Check the inputs

  if ( poData->nelements() < 1 ) {
    throw( ermsg( "Invalid number of data", "StatToolbox", "min" ) );
  }

  if ( poDataErr != NULL ) {
    if ( poData->nelements() != poDataErr->nelements() ) {
      throw( ermsg( "Vectors have different numbers of data", "StatToolbox",
          "min" ) );
    }
  }


  // Find the minimum

  if ( poDataErr == NULL ) {

    dMin = (*poData)(0);

    for ( uiData = 1; uiData < poData->nelements(); uiData++ ) {
      if ( (*poData)(uiData) < dMin ) {
        dMin = (*poData)(uiData);
      }
    }

  } else {

    dMin = (*poData)(0) - (*poDataErr)(0);

    for ( uiData = 1; uiData < poData->nelements(); uiData++ ) {
      if ( (*poData)(uiData) - (*poDataErr)(uiData) < dMin ) {
        dMin = (*poData)(uiData) - (*poDataErr)(uiData);
      }
    }

  }


  // Return the minimum

  return( dMin );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::min (matrix)

Description:
------------
This static public member function finds the minimum.  Error bars may be
subtracted, for plot limits.

Inputs:
-------
poData    - The data.
poDataErr - The data errors (default = NULL, no plot limits).

Outputs:
--------
The minimum, returned via the function value.

Modification history:
---------------------
2001 Jan 05 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Double StatToolbox::min( const Matrix<Double>* const poData,
    const Matrix<Double>* const poDataErr ) {

  // Declare the local variables

  uInt uiColumn; // The column counter
  uInt uiData;   // The data counter

  Double dMin;   // The minimum value


  // Check the inputs

  if ( poData->nelements() < 1 ) {
    throw( ermsg( "Invalid number of data", "StatToolbox", "min" ) );
  }

  if ( poDataErr != NULL ) {
    if ( poData->nelements() != poDataErr->nelements() ) {
      throw( ermsg( "Vectors have different numbers of data", "StatToolbox",
          "min" ) );
    }
  }


  // Find the minimum

  if ( poDataErr == NULL ) {

    dMin = (*poData)(0,0);

    for ( uiData = 0; uiData < poData->nrow(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < poData->ncolumn(); uiColumn++ ) {
        if ( (*poData)(uiData,uiColumn) < dMin ) {
          dMin = (*poData)(uiData,uiColumn);
        }
      }
    }

  } else {

    dMin = (*poData)(0,0) - (*poDataErr)(0,0);

    for ( uiData = 0; uiData < poData->nrow(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < poData->ncolumn(); uiColumn++ ) {
        if ( (*poData)(uiData,uiColumn)-(*poDataErr)(uiData,uiColumn) < dMin ) {
          dMin = (*poData)(uiData,uiColumn) - (*poDataErr)(uiData,uiColumn);
        }
      }
    }

  }


  // Return the minimum

  return( dMin );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::rand01

Description:
------------
This function returns a random number between 0 and 1 subject to a uniform
distribution.

Inputs:
-------
None.

Outputs:
--------
The uniformly distributed random number, returned via the function value.

Modification history:
---------------------
1999 Mar 26 - Nicholas Elias, USNO/NPOI
              Function created.

*/

// -----------------------------------------------------------------------------

Double StatToolbox::rand01( void ) {

  // Calculate the uniformly distributed random number and return
  
  return( ( (Double) rand() ) / ( (Double) RAND_MAX ) );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::randgauss

Description:
------------
This function returns a random number subject to a Gaussian distribution.  If
both defaults are used, the Gaussian distribution becomes a standard normal
distribution.

Inputs:
-------
dMu    - The mean of the Gaussian distribution (default = 0.0).
dSigma - The standard deviation of the Gaussian distribution (default = 1.0).

Outputs:
--------
The Gaussian distributed random number, returned via the function value.

Modification history:
---------------------
1999 Mar 26 - Nicholas Elias, USNO/NPOI
              Function created.

*/

/* ------------------------------------------------------------------------- */

Double StatToolbox::randgauss( const Double dMu, const Double dSigma ) {

  // Delare the local variables

  Double dNum1 = 0.0; // The first input random number obtained from a uniform
                      // distribution
  Double dNum2 = 0.0; // The second input random number obtained from a uniform
                      // distribution
  Double dNumber;     // The Gaussian random number returned via the function
                      // value


  // Check the inputs
  
  if ( dSigma <= 0.0 ) {
    throw( ermsg( "Invalid standard deviation", "StatToolbox", "randgauss" ) );
  }


  // Obtain the first and second uniformly distributed random numbers

  while ( dNum1 <= 0.0 ) {
    dNum1 = rand01( );
  }
  
  while ( dNum2 <= 0.0 ) {
    dNum2 = rand01( );
  }


  // Calculate the Gaussian distributed random number and return

  dNumber = dMu;
  dNumber += dSigma * sqrt( -2.0 * log( dNum1 ) ) * cos( 2.0 * PI * dNum2 );

  return( dNumber );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::rchi2

Description:
------------
This static public member function calculates the reduced chi-squared for the
weighted mean.

Inputs:
-------
poData    - The data.
poDataErr - The data errors.

Outputs:
--------
The reduced chi-squared, returned via the function value.

Modification history:
---------------------
1999 Mar 10 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Double StatToolbox::rchi2( const Vector<Double>* const poData,
    const Vector<Double>* const poDataErr ) {

  // Declare the local variables
 
  uInt uiData;         // The data counter

  Double dDiff;        // The difference between an ordinate and the weighted
                       // mean
  Double dRChi2 = 0.0; // The reduced chi-squared (initialized to 0.0)
  Double dWMean;       // The weighted mean
 
 
  // Check the inputs

  if ( poData->nelements() < 2 ) {
    throw( ermsg( "Invalid number of data", "StatToolbox", "rchi2" ) );
  }

  if ( poData->nelements() != poDataErr->nelements() ) {
    throw( ermsg( "Vectors have different numbers of data", "StatToolbox",
        "rchi2" ) );
  }


  // Calculate the reduced chi-squared
  
  try {
    dWMean = mean( poData, poDataErr );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "mean( ) error\n" + oAipsError.getMesg(), "StatToolbox",
        "rchi2" ) );
  }
  
  for ( uiData = 0; uiData < poData->nelements(); uiData++ ) {
    dDiff = ( (*poData)(uiData) - dWMean ) / (*poDataErr)(uiData);
    dRChi2 += ( dDiff * dDiff );
  }
  
  dRChi2 /= (Double) poData->nelements() - 1;
  
  
  // Return the reduced chi-squared
  
  return( dRChi2 );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::sort (Bool)

Description:
------------
This static public member function returns sorted data.

Inputs:
-------
oSortKey - The sort key.
oData    - The data.

Outputs:
--------
oData - The sorted data.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

void StatToolbox::sort( const Vector<Int>& oSortKey, Vector<Bool>& oData ) {

  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Check the inputs
  
  if ( oSortKey.nelements() != oData.nelements() ) {
    throw( ermsg( "Sort-key and data vectors are not the same length",
        "StatToolbox", "sort" ) );
  }
  

  // Apply the sort key

  Vector<Bool> oDataTemp = Vector<Bool>( oData.nelements() );
  for ( uiData = 0; uiData < oSortKey.nelements(); uiData++ ) {
    oDataTemp(uiData) = oData(uiData);
  }

  for ( uiData = 0; uiData < oSortKey.nelements(); uiData++ ) {
    oData(uiData) = oDataTemp(oSortKey(uiData));
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

StatToolbox::sort (Int)

Description:
------------
This static public member function returns sorted data.

Inputs:
-------
oSortKey - The sort key.
oData    - The data.

Outputs:
--------
oData - The sorted data.

Modification history:
---------------------
2000 May 26 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

void StatToolbox::sort( const Vector<Int>& oSortKey, Vector<Int>& oData ) {

  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Check the inputs
  
  if ( oSortKey.nelements() != oData.nelements() ) {
    throw( ermsg( "Sort-key and data vectors are not the same length",
        "StatToolbox", "sort" ) );
  }
  

  // Apply the sort key

  Vector<Int> oDataTemp = Vector<Int>( oData.nelements() );
  for ( uiData = 0; uiData < oSortKey.nelements(); uiData++ ) {
    oDataTemp(uiData) = oData(uiData);
  }

  for ( uiData = 0; uiData < oSortKey.nelements(); uiData++ ) {
    oData(uiData) = oDataTemp(oSortKey(uiData));
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

StatToolbox::sort (Double)

Description:
------------
This static public member function returns the sorted data.

Inputs:
-------
oSortKey - The sort key.
oData    - The data.

Outputs:
--------
oData - The sorted data.

Modification history:
---------------------
1999 Mar 11 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

void StatToolbox::sort( const Vector<Int>& oSortKey, Vector<Double>& oData ) {

  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Check the inputs
  
  if ( oSortKey.nelements() != oData.nelements() ) {
    throw( ermsg( "Sort key and data vectors are not the same length",
        "StatToolbox", "sort" ) );
  }
  

  // Apply the sort key

  Vector<Double> oDataTemp = Vector<Double>( oData.nelements() );
  for ( uiData = 0; uiData < oSortKey.nelements(); uiData++ ) {
    oDataTemp(uiData) = oData(uiData);
  }

  for ( uiData = 0; uiData < oSortKey.nelements(); uiData++ ) {
    oData(uiData) = oDataTemp(oSortKey(uiData));
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

StatToolbox::sort (String)

Description:
------------
This static public member function returns sorted data.

Inputs:
-------
oSortKey - The sort key.
oData    - The data.

Outputs:
--------
oData - The sorted data.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

void StatToolbox::sort( const Vector<Int>& oSortKey, Vector<String>& oData ) {

  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Check the inputs
  
  if ( oSortKey.nelements() != oData.nelements() ) {
    throw( ermsg( "Sort key and data vectors are not the same length",
        "StatToolbox", "sort" ) );
  }
  

  // Apply the sort key

  Vector<String> oDataTemp = Vector<String>( oData.nelements() );
  for ( uiData = 0; uiData < oSortKey.nelements(); uiData++ ) {
    oDataTemp(uiData) = oData(uiData);
  }

  for ( uiData = 0; uiData < oSortKey.nelements(); uiData++ ) {
    oData(uiData) = oDataTemp(oSortKey(uiData));
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

StatToolbox::sort (Bool Matrix)

Description:
------------
This static public member function returns the sorted data.

Inputs:
-------
oSortKey - The sort key.
oData    - The data.

Outputs:
--------
oData - The sorted data.

Modification history:
---------------------
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

void StatToolbox::sort( const Vector<Int>& oSortKey, Matrix<Bool>& oData ) {

  // Declare the local variables
  
  uInt uiColumn; // The column counter
  uInt uiData;   // The data counter
  
  
  // Check the inputs
  
  if ( oSortKey.nelements() != oData.nrow() ) {
    throw( ermsg( "Sort key and data rows are not the same length",
        "StatToolbox", "sort" ) );
  }
  

  // Apply the sort key

  Matrix<Bool> oDataTemp = Matrix<Bool>( oData.nrow(), oData.ncolumn() );
  for ( uiData = 0; uiData < oData.nrow(); uiData++ ) {
    for ( uiColumn = 0; uiColumn < oData.ncolumn(); uiColumn++ ) {
      oDataTemp(uiData,uiColumn) = oData(uiData,uiColumn);
    }
  }

  for ( uiData = 0; uiData < oData.nrow(); uiData++ ) {
    for ( uiColumn = 0; uiColumn < oData.ncolumn(); uiColumn++ ) {
      oData(uiData,uiColumn) = oDataTemp(oSortKey(uiData),uiColumn);
    }
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

StatToolbox::sort (Double Matrix)

Description:
------------
This static public member function returns the sorted data.

Inputs:
-------
oSortKey - The sort key.
oData    - The data.

Outputs:
--------
oData - The sorted data.

Modification history:
---------------------
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

void StatToolbox::sort( const Vector<Int>& oSortKey, Matrix<Double>& oData ) {

  // Declare the local variables
  
  uInt uiColumn; // The column counter
  uInt uiData;   // The data counter
  
  
  // Check the inputs
  
  if ( oSortKey.nelements() != oData.nrow() ) {
    throw( ermsg( "Sort key and data rows are not the same length",
        "StatToolbox", "sort" ) );
  }
  

  // Apply the sort key

  Matrix<Double> oDataTemp = Matrix<Double>( oData.nrow(), oData.ncolumn() );
  for ( uiData = 0; uiData < oData.nrow(); uiData++ ) {
    for ( uiColumn = 0; uiColumn < oData.ncolumn(); uiColumn++ ) {
      oDataTemp(uiData,uiColumn) = oData(uiData,uiColumn);
    }
  }

  for ( uiData = 0; uiData < oData.nrow(); uiData++ ) {
    for ( uiColumn = 0; uiColumn < oData.ncolumn(); uiColumn++ ) {
      oData(uiData,uiColumn) = oDataTemp(oSortKey(uiData),uiColumn);
    }
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

StatToolbox::sortkey (Int)

Description:
------------
This static public member function returns the data sort key (ascending order)
using bubble sort (gack!).  I will incorporate a faster algorithm eventually.

Inputs:
-------
oData - The data.

Outputs:
--------
The sort key, returned via the function value.

Modification history:
---------------------
2000 May 26 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> StatToolbox::sortkey( const Vector<Int>& oData ) {

  // Declare the local variables
  
  uInt uiData;  // A data counter
  uInt uiData1; // A data counter
  uInt uiData2; // A data counter
  

  // Initialize the sort key
  
  Vector<Int> oSortKey = Vector<Int>( oData.nelements() );
  
  for ( uiData = 0; uiData < oSortKey.nelements(); uiData++ ) {
    oSortKey(uiData) = uiData;
  }
  

  // Perform the bubble sort
  
  for ( uiData1 = 0; uiData1 < oData.nelements(); uiData1++ ) {
    for ( uiData2 = ( uiData1 + 1 ); uiData2 < oData.nelements(); uiData2++ ) {
      if ( oData(oSortKey(uiData1)) > oData(oSortKey(uiData2)) ) {
        __swap( (uInt*) &oSortKey(uiData1), (uInt*) &oSortKey(uiData2) );
      }
    }
  }
  
  
  // Return the sort key

  return( oSortKey );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::sortkey (Double)

Description:
------------
This static public member function returns the data sort key (ascending order)
using bubble sort (gack!).  I will incorporate a faster algorithm eventually.

Inputs:
-------
oData - The data.

Outputs:
--------
The sort key, returned via the function value.

Modification history:
---------------------
1999 Mar 11 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> StatToolbox::sortkey( const Vector<Double>& oData ) {

  // Declare the local variables
  
  uInt uiData;  // A data counter
  uInt uiData1; // A data counter
  uInt uiData2; // A data counter

  // Initialize the sort key
  
  Vector<Int> oSortKey = Vector<Int>( oData.nelements() );
  
  for ( uiData = 0; uiData < oSortKey.nelements(); uiData++ ) {
    oSortKey(uiData) = uiData;
  }
  

  // Perform the bubble sort
  
  for ( uiData1 = 0; uiData1 < oData.nelements(); uiData1++ ) {
    for ( uiData2 = ( uiData1 + 1 ); uiData2 < oData.nelements(); uiData2++ ) {
      if ( oData(oSortKey(uiData1)) > oData(oSortKey(uiData2)) ) {
        __swap( (uInt*) &oSortKey(uiData1), (uInt*) &oSortKey(uiData2) );
      }
    }
  }
  
  
  // Return the sort key

  return( oSortKey );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::stddev (vector)

Description:
------------
This static public member function calculates the standard deviation using the
(weighted) mean.

Inputs:
-------
poData    - The data.
poDataErr - The data errors (default = NULL, no weighted mean).

Outputs:
--------
The standard deviation, returned via the function value.

Modification history:
---------------------
1999 Mar 09 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Double StatToolbox::stddev( const Vector<Double>* const poData,
    const Vector<Double>* const poDataErr ) {

  // Declare the local variables
  
  Double dStdDev; // The standard deviation
 
 
  // Check the inputs
 
  if ( poData->nelements() < 2 ) {
    throw( ermsg( "Invalid number of data", "StatToolbox", "stddev" ) );
  }

  if ( poDataErr != NULL ) {
    if ( poData->nelements() != poDataErr->nelements() ) {
      throw( ermsg( "Vectors have different numbers of data", "StatToolbox",
          "stddev" ) );
    }
  }


  // Calculate the standard deviation
  
  try {
    dStdDev = sqrt( variance( poData, poDataErr ) );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "variance( ) error\n" + oAipsError.getMesg(), "StatToolbox",
        "stddev" ) );
  }
  
  
  // Return the standard deviation
  
  return( dStdDev );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::stddev (matrix)

Description:
------------
This static public member function calculates the standard deviation using the
(weighted) mean.

Inputs:
-------
poData    - The data.
poDataErr - The data errors (default = NULL, no weighted mean).

Outputs:
--------
The standard deviation, returned via the function value.

Modification history:
---------------------
2001 Jan 17 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Double StatToolbox::stddev( const Matrix<Double>* const poData,
    const Matrix<Double>* const poDataErr ) {

  // Declare the local variables
  
  Double dStdDev; // The standard deviation
 
 
  // Check the inputs
 
  if ( poData->nelements() < 2 ) {
    throw( ermsg( "Invalid number of data", "StatToolbox", "stddev" ) );
  }

  if ( poDataErr != NULL ) {
    if ( poData->nrow() != poDataErr->nrow() ||
         poData->ncolumn() != poDataErr->ncolumn() ) {
      throw( ermsg( "Matrices have different numbers of data", "StatToolbox",
          "stddev" ) );
    }
  }


  // Calculate the standard deviation
  
  try {
    dStdDev = sqrt( variance( poData, poDataErr ) );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "variance( ) error\n" + oAipsError.getMesg(), "StatToolbox",
        "stddev" ) );
  }
  
  
  // Return the standard deviation
  
  return( dStdDev );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::variance (vector)

Description:
------------
This static public member function calculates the variance using the (weighted)
mean.

Inputs:
-------
poData    - The data.
poDataErr - The data errors (default = NULL, no weighted mean).

Outputs:
--------
The variance, returned via the function value.

Modification history:
---------------------
1999 Mar 09 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Double StatToolbox::variance( const Vector<Double>* const poData,
    const Vector<Double>* const poDataErr ) {

  // Declare the local variables
 
  uInt uiData;            // The data counter

  Double dDen;            // The denominator
  Double dMean;           // The (weighted) mean
  Double dNum;            // The numerator
  Double dTemp;           // A temporary value
  Double dVariance = 0.0; // The variance (initialized to 0.0)
 
 
  // Check the inputs

  if ( poData->nelements() < 2 ) {
    throw( ermsg( "Invalid number of data", "StatToolbox", "variance" ) );
  }

  if ( poDataErr != NULL ) {
    if ( poData->nelements() != poDataErr->nelements() ) {
      throw( ermsg( "Vectors have different numbers of data", "StatToolbox",
          "variance" ) );
    }
    for ( uiData = 0; uiData < poDataErr->nelements(); uiData++ ) {
      if ( (*poDataErr)(uiData) <= 0.0 ) {
        throw( ermsg( "Invalid data error(s), cannot calculate weighted mean",
            "StatToolbox", "variance" ) );
      }
    }
  }


  // Calculate the variance
  
  try {
    dMean = mean( poData, poDataErr );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "mean( ) error\n" + oAipsError.getMesg(), "StatToolbox",
        "variance" ) );
  }
  
  if ( poDataErr != NULL ) {

    dNum = 0.0;
    dDen = 0.0;
  
    for ( uiData = 0; uiData < poData->nelements(); uiData++ ) {
      dTemp = (*poData)(uiData) - dMean;
      dTemp /= ( (*poDataErr)(uiData) * (*poDataErr)(uiData) );
      dNum += ( dTemp * dTemp );
      dTemp = 1.0 / pow( (*poDataErr)(uiData), 4.0 );
      dDen += dTemp;
    }
  
    dVariance = ( dNum / dDen ) / ( 1.0 - ( 1.0 / poData->nelements() ) );
    
  } else {
  
    dVariance = 0.0;
    
    for ( uiData = 0; uiData < poData->nelements(); uiData++ ) {
      dTemp = (*poData)(uiData) - dMean;
      dVariance += ( dTemp * dTemp );
    }

    dVariance /= ( poData->nelements() - 1 );
  
  }
  
  
  // Return the variance
  
  return( dVariance );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::variance (matrix)

Description:
------------
This static public member function calculates the variance using the (weighted)
mean.

Inputs:
-------
poData    - The data.
poDataErr - The data errors (default = NULL, no weighted mean).

Outputs:
--------
The variance, returned via the function value.

Modification history:
---------------------
2001 Jan 17 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Double StatToolbox::variance( const Matrix<Double>* const poData,
    const Matrix<Double>* const poDataErr ) {

  // Declare the local variables
 
  uInt uiColumn;          // The column counter
  uInt uiData;            // The data counter

  Double dDen;            // The denominator
  Double dMean;           // The (weighted) mean
  Double dNum;            // The numerator
  Double dTemp;           // A temporary value
  Double dVariance = 0.0; // The variance (initialized to 0.0)
 
 
  // Check the inputs

  if ( poData->nelements() < 2 ) {
    throw( ermsg( "Invalid number of data", "StatToolbox", "variance" ) );
  }

  if ( poDataErr != NULL ) {
    if ( poData->nrow() != poDataErr->nrow() ||
         poData->ncolumn() != poDataErr->ncolumn() ) {
      throw( ermsg( "Matrices have different numbers of data", "StatToolbox",
          "variance" ) );
    }
    for ( uiData = 0; uiData < poDataErr->nrow(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < poDataErr->ncolumn(); uiColumn++ ) {
        if ( (*poDataErr)(uiData,uiColumn) <= 0.0 ) {
          throw( ermsg( "Invalid data error(s), cannot calculate weighted mean",
              "StatToolbox", "variance" ) );
        }
      }
    }
  }


  // Calculate the variance
  
  try {
    dMean = mean( poData, poDataErr );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "mean( ) error\n" + oAipsError.getMesg(), "StatToolbox",
        "variance" ) );
  }
  
  if ( poDataErr != NULL ) {

    dNum = 0.0;
    dDen = 0.0;
  
    for ( uiData = 0; uiData < poData->nrow(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < poData->ncolumn(); uiColumn++ ) {
        dTemp = (*poData)(uiData,uiColumn) - dMean;
        dTemp /=
            ( (*poDataErr)(uiData,uiColumn) * (*poDataErr)(uiData,uiColumn) );
        dNum += ( dTemp * dTemp );
        dTemp = 1.0 / pow( (*poDataErr)(uiData,uiColumn), 4.0 );
        dDen += dTemp;
      }
    }
  
    dVariance = ( dNum / dDen ) / ( 1.0 - ( 1.0 / poData->nelements() ) );
    
  } else {
  
    dVariance = 0.0;
    
    for ( uiData = 0; uiData < poData->nrow(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < poData->ncolumn(); uiColumn++ ) {
        dTemp = (*poData)(uiData,uiColumn) - dMean;
        dVariance += ( dTemp * dTemp );
      }
    }

    dVariance /= ( poData->nelements() - 1 );
  
  }
  
  
  // Return the variance
  
  return( dVariance );

}

// -----------------------------------------------------------------------------

/*

StatToolbox::__swap (uInt)

Description:
------------
This static private member function swaps two values.

Inputs:
-------
puiValue1 - The first value.
puiValue2 - The second value.

Outputs:
--------
None.

Modification history:
---------------------
1999 Mar 10 - Nicholas Elias, USNO/NPOI
              Static private member function created.

*/

// -----------------------------------------------------------------------------

void StatToolbox::__swap( uInt* const puiValue1, uInt* const puiValue2 ) {

  // Declare the local variables
  
  uInt uiSwap; // The temporary swap variable
  
  
  // Perform the swap and return
  
  uiSwap = *puiValue1;
  
  *puiValue1 = *puiValue2;
  *puiValue2 = uiSwap;
  
  return;

}
