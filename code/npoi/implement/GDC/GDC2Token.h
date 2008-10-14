//#GDC2Token.h is part of the GDC server
//#Copyright (C) 2000,2001
//#United States Naval Observatory; Washington, DC; USA.
//#
//#This library is free software; you can redistribute it and/or modify it
//#under the terms of the GNU Library General Public License as published by
//#the Free Software Foundation; either version 2 of the License, or (at your
//#option) any later version.
//#
//#This library is designed for use only in AIPS++ (National Radio Astronomy
//#Observatory; Charlottesville, VA; USA) in the hope that it will be useful, but
//#WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//#FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//#License for more details.
//#
//#You should have received a copy of the GNU Library General Public License
//#along with this library; if not, write to the Free Software Foundation,
//#Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//#Correspondence concerning the GDC server should be addressed as follows:
//#       Internet email: nme@nofs.navy.mil
//#       Postal address: Dr. Nicholas Elias
//#                       United States Naval Observatory
//#                       Navy Prototype Optical Interferometer
//#                       P.O. Box 1149
//#                       Flagstaff, AZ 86002-1149 USA
//#
//#Correspondence concerning AIPS++ should be addressed as follows:
//#       Internet email: aips2-request@nrao.edu.
//#       Postal address: AIPS++ Project Office
//#                       National Radio Astronomy Observatory
//#                       520 Edgemont Road
//#                       Charlottesville, VA 22903-2475 USA
//#
//# $Id: GDC2Token.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

GDC2Token.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the include information for the GDC2Token.cc file.

Modification history:
---------------------
2000 Apr 26 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_GDC2TOKEN_H
#define NPOI_GDC2TOKEN_H


// Includes

extern "C" {
  #include <stdio.h>                              // Standard I/O
  #include <stdlib.h>                             // Standard library
  #include <string.h>                             // String
  #include <cpgplot.h>                            // PGPLOT (C wrappers)
}

#include <casa/aips.h>                            // aips++
#include <tasking/Tasking/ApplicationEnvironment.h> // aips++ App...Env... class
#include <tasking/Tasking/ApplicationObject.h>      // aips++ App...Object class
#include <casa/Exceptions/Error.h>                // aips++ Error classes
#include <casa/Arrays/Matrix.h>                   // aips++ Matrix class
#include <tasking/Tasking/MethodResult.h>           // aips++ MethodResult class
#include <tasking/Tasking/Parameter.h>              // aips++ Parameter class
#include <tasking/Tasking/ParameterSet.h>           // aips++ ParameterSet class
#include <casa/Utilities/Regex.h>                 // aips++ Regex class
#include <casa/BasicSL/String.h>                // aips++ String class
#include <tasking/Tasking.h>                        // aips++ tasking
#include <casa/Arrays/Vector.h>                   // aips++ Vector class
#include <scimath/Functionals/ScalarSampledFunctional.h> // aips++ S..S..F class
#include <scimath/Functionals/Interpolate1D.h>       // aips++ Interp..1D class

#include <npoi/HDS/GeneralStatus.h>               // GeneralStatus

#include <npoi/GDC/StatToolbox.h>                 // Statistics toolbox

#include <casa/namespace.h>
// <summary>A class for manipulating 2-dimensional tokenized data</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos=""></reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
// GDC2Token{ } is a class designed for the manipulation of 2-dimensional
// tokenized data (x, y, xerr, yerr, token, flag, column).  Manipulation means
// any of the following: plotting, flagging, interpolation, statistics.
// </synopsis>

// <example>
// <src>GDC2Token.cc</src>
// <srcblock>{}</srcblock>
// </example>

// <todo asof="2000/07/08">
// <LI></LI>
// </todo>

// Class definition

class GDC2Token : public GeneralStatus, public ApplicationObject {

  public:

    // Create a GDC2Token{ } object.
    GDC2Token( void );
    GDC2Token( const Vector<Double>& oXIn, const Matrix<Double>& oYIn,
        const Vector<Double>& oXErrIn, const Matrix<Double>& oYErrIn,
        const Vector<String>& oTokenIn, const Vector<String>& oColumnIn,
        const Matrix<Bool>& oFlagIn, const String& oTokenTypeIn,
        const String& oColumnTypeIn, const Bool& bHMSIn = False );
    GDC2Token( String& oFileIn, const String& oTokenTypeIn = "",
        const String& oColumnTypeIn = "", const Bool& bHMSIn = False );
    GDC2Token( const ObjectID& oObjectIDIn, Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, Vector<String>& oColumnIn,
        const Bool& bKeepIn );
    GDC2Token( const GDC2Token& oGDC2TokenIn );
    
    // Destructor.
    virtual ~GDC2Token( void );

    // Return the ASCII file name.
    String fileASCII( void ) const;

    // Get the check-arguments boolean.
    Bool getArgCheck( void ) const;

    // Set the check-arguments boolean.
    void setArgCheck( const Bool& bArgCheckIn = True );

    // Dump the data to an ASCII file.
    void dumpASCII( String& oFileIn, Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, Vector<String>& oColumnIn,
        const Bool& bKeepIn ) const;

    // Clone the object.
    GDC2Token* clone( Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, Vector<String>& oColumnIn,
        const Bool& bKeepIn ) const;

    // Return the length.
    uInt length( Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        Vector<String>& oColumnIn, const Bool& bKeepIn ) const;

    // Return the x values.
    Vector<Double> x( Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, Vector<String>& oColumnIn,
        const Bool& bKeepIn ) const;

    // Return the old x values.
    Vector<Double> xOld( void ) const;

    // Return the y values.
    Matrix<Double> y( Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, Vector<String>& oColumnIn,
        const Bool& bKeepIn, const Bool& bOrigIn ) const;

    // Return the x errors.
    Vector<Double> xErr( Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, Vector<String>& oColumnIn,
        const Bool& bKeepIn ) const;

    // Return the old x errors.
    Vector<Double> xErrOld( void ) const;

    // Return the y errors.
    Matrix<Double> yErr( Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, Vector<String>& oColumnIn,
        const Bool& bKeepIn, const Bool& bOrigIn ) const;

    // Return the x-error boolean.
    Bool xError( void ) const;

    // Return the y-error boolean.
    Bool yError( void ) const;

    // Return the tokens.
    Vector<String> token( Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, Vector<String>& oColumnIn,
        const Bool& bKeepIn ) const;

    // Return the token type.
    String tokenType( void ) const;

    // Return the list of unique tokens.
    Vector<String> tokenList( void ) const;

    // Return the column type.
    String columnType( void ) const;

    // Return the list of unique columns.
    Vector<String> columnList( void ) const;
    
    // Return the column number.
    uInt columnNumber( String& oColumnIn ) const;
    Vector<Int> columnNumber( Vector<String>& oColumnIn ) const;

    // Return the flags.
    Matrix<Bool> flag( Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, Vector<String>& oColumnIn,
        const Bool& bOrigIn ) const;

    // Return the interpolation booleans.
    Matrix<Bool> interp( Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, Vector<String>& oColumnIn ) const;

    // Return the indices.
    Vector<Int> index( Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, const uInt& uiColumnIn,
        const Bool& bKeepIn ) const;
    Vector<Int> index( Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, Vector<Int>& oColumnIn,
        const Bool& bKeepIn ) const;
    Vector<Int> index( Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, Vector<String>& oColumnIn,
        const Bool& bKeepIn ) const;

    // Return the maximum x value.
    Double xMax( const Bool& bPlotIn = False ) const;
    Double xMax( Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        Vector<String>& oColumnIn, const Bool& bKeepIn,
        const Bool& bPlotIn ) const;

    // Return the minimum x value.
    Double xMin( const Bool& bPlotIn = False ) const;
    Double xMin( Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        Vector<String>& oColumnIn, const Bool& bKeepIn,
        const Bool& bPlotIn ) const;

    // Return the maximum y value.
    Double yMax( const Bool& bPlotIn = False ) const;
    Double yMax( Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        Vector<String>& oColumnIn, const Bool& bKeepIn,
        const Bool& bPlotIn ) const;

    // Return the minimum y value.
    Double yMin( const Bool& bPlotIn = False ) const;
    Double yMin( Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        Vector<String>& oColumnIn, const Bool& bKeepIn,
        const Bool& bPlotIn ) const;

    // Return the maximum x error.
    Double xErrMax( void ) const;
    Double xErrMax( Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        Vector<String>& oColumnIn, const Bool& bKeepIn ) const;

    // Return the minimum x error.
    Double xErrMin( void ) const;
    Double xErrMin( Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        Vector<String>& oColumnIn, const Bool& bKeepIn ) const;

    // Return the maximum y error.
    Double yErrMax( void ) const;
    Double yErrMax( Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        Vector<String>& oColumnIn, const Bool& bKeepIn ) const;

    // Return the minimum y error.
    Double yErrMin( void ) const;
    Double yErrMin( Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        Vector<String>& oColumnIn, const Bool& bKeepIn ) const;

    // Return the flagged data indices.
    Vector<Int> flagged( Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, String& oColumnIn ) const;

    // Return the interpolated data indices.
    Vector<Int> interpolated( Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, String& oColumnIn ) const;

    // Return the y mean value.
    Double mean( Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        Vector<String>& oColumnIn, const Bool& bKeepIn,
        const Bool& bWeightIn ) const;

    // Return the y mean error.
    Double meanErr( Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        Vector<String>& oColumnIn, const Bool& bKeepIn,
        const Bool& bWeightIn ) const;

    // Return the y standard deviation.
    Double stdDev( Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        Vector<String>& oColumnIn, const Bool& bKeepIn,
        const Bool& bWeightIn ) const;

    // Return the y variance.
    Double variance( Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        Vector<String>& oColumnIn, const Bool& bKeepIn,
        const Bool& bWeightIn ) const;

    // Flag the data according to the x values.
    void setFlagX( Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        Vector<String>& oColumnIn, const Bool& bFlagValueIn );

    // Flag the data according to the x-y values.
    void setFlagXY( Double& dXMinIn, Double& dXMaxIn, Double& dYMinIn,
        Double& dYMaxIn, Vector<String>& oTokenIn, Vector<String>& oColumnIn,
        const Bool& bFlagValueIn );

    // Undo the histories from the most recent event.
    void undoHistory( void );
   
    // Reset the histories.
    void resetHistory( void );
   
    // Get the flag-history vectors.
    void history( Vector<Int>* *poHistoryEventIn,
        Vector<Int>* *poHistoryIndexIn, Vector<Int>* *poHistoryColumnIn,
        Vector<Bool>* *poHistoryFlagIn, Vector<Bool>* *poHistoryInterpIn,
        Vector<Double>* *poHistoryYIn, Vector<Double>* *poHistoryYErrIn ) const;

    // Get the number of events in the history.
    uInt numEvent( void ) const;

    // Create a PostScript plot with the present plot parameters.
    void postScript( String& oFileIn, const String& oDeviceIn,
        const Bool& bTrans, const Vector<Int>& oCI );

    // Plot data to a PGPLOT device.
    void plot( const Int& iQIDIn, const Vector<Int>& oCI );

    // Get the minimum plotted x value.
    Double getXMin( const Bool& bDefault = False ) const;

    // Get the maximum plotted x value.
    Double getXMax( const Bool& bDefault = False ) const;

    // Get the minimum plotted y value.
    Double getYMin( const Bool& bDefault = False ) const;

    // Get the maximum plotted y value.
    Double getYMax( const Bool& bDefault = False ) const;

    // Zoom for the PGPLOT device.
    void zoomx( Double& dXMinIn, Double& dXMaxIn );
    void zoomy( Double& dYMinIn, Double& dYMaxIn );
    void zoomxy( Double& dXMinIn, Double& dXMaxIn, Double& dYMinIn,
        Double& dYMaxIn );

    // Zoom to full size for the PGPLOT device.
    void fullSize( void );

    // Return the plotted tokens.
    Vector<String> getToken( void ) const;

    // Return the plotted column IDs for a given token.
    Vector<String> getColumn( String& oTokenIn ) const;
   
    // Set the plotted tokens and column IDs.
    void setTokenColumn( Vector<String>& oTokenIn, Vector<String>& oColumnIn );
   
    // Set the plotted tokens and column IDs to the default (all).
    void setTokenColumnDefault( void );

    // Add the plotted tokens and column IDs.
    void addTokenColumn( Vector<String>& oTokenIn, Vector<String>& oColumnIn );

    // Remove the plotted tokens and column IDs.
    void removeTokenColumn( Vector<String>& oTokenIn,
        Vector<String>& oColumnIn );

    // Get the flagging boolean.
    Bool getFlag( void ) const;
   
    // Set the flagging boolean.
    void setFlag( const Bool& bFlagIn );

    // Get the plot-color boolean.
    Bool getColor( void ) const;
   
    // Set the plot-color boolean.
    void setColor( const Bool& bColorIn );
   
    // Get the plot-line boolean.
    Bool getLine( void ) const;

    // Set the plot-line boolean.
    void setLine( const Bool& bLineIn );

    // Get the keep-flag boolean.
    Bool getKeep( void ) const;

    // Set the keep-flag boolean.
    void setKeep( const Bool& bKeepIn );

    // Get the x-axis label.
    String getXLabel( const Bool& bDefaultIn = False ) const;

    // Set the x-axis label.
    void setXLabel( void );
    void setXLabel( const String& oXLabelIn );

    // Set the default x-axis label.
    void setXLabelDefault( const String& oXLabelIn );

    // Get the y-axis label.
    String getYLabel( const Bool& bDefaultIn = False ) const;

    // Set the y-axis label.
    void setYLabel( void );
    void setYLabel( const String& oYLabelIn );

    // Set the default y-axis label.
    void setYLabelDefault( const String& oYLabelIn );

    // Get the title label.
    String getTitle( const Bool& bDefaultIn = False ) const;

    // Set the title label.
    void setTitle( void );
    void setTitle( const String& oTitleIn );

    // Set the default title label.
    void setTitleDefault( const String& oTitleIn );

    // Get the HH:MM:SS boolean.
    Bool hms( void ) const;

    // Get the old HH:MM:SS boolean.
    Bool hmsOld( void ) const;

    // Return the GDC2Token{ } version.
    virtual String version( void ) const;

    // Return the glish tool name (must be "gdc2token").
    virtual String tool( void ) const;

    // Check the column IDs.
    Bool checkColumn( Vector<Int>& oColumnIn ) const;
    Bool checkColumn( Vector<String>& oColumnIn ) const;

    // Check the tokens.
    Bool checkToken( Vector<String>& oTokenIn ) const;

    // Check the x values.
    Bool checkX( Double& dXMinIn, Double& dXMaxIn ) const;

    // Check the y values.
    Bool checkY( Double& dYMinIn, Double& dYMaxIn ) const;

    // Change the present x vector (and associated x-plot values), x-error
    // vector, and x-axis label with new versions.
    virtual void changeX( const Vector<Double>& oXIn,
        const Vector<Double>& oXErrIn, const String& oXLabelIn,
        const Bool& bHMSIn = False );

    // Reset the present x vector (and associated x-plot values), x-error
    // vector, and x-axis label to their old versions.
    virtual void resetX( void );
    
    // Return the class name.
    virtual String className( void ) const;

    // Return the list of GDC1Token{ } methods.
    virtual Vector<String> methods( void ) const;

    // Return the list of GDC1Token{ } methods where no trace is printed.
    virtual Vector<String> noTraceMethods( void ) const;

    // The GDC server uses this method to pass arguments to GDC1Token{ }
    // methods and run them.
    virtual MethodResult runMethod( uInt uiMethod, ParameterSet& oParameters,
        Bool bRunMethod );

  protected:

    static const uInt LENGTH_MAX = 1000;

    String* poFileASCII;

    String* poXLabelDefaultOld;
    String* poXLabelOld;

    void initialize( const Vector<Double>& oXIn, const Matrix<Double>& oYIn,
        const Vector<Double>& oXErrIn, const Matrix<Double>& oYErrIn,
        const Vector<String>& oTokenIn, const Vector<String>& oColumnIn,
        const Matrix<Bool>& oFlagIn, const String& oTokenTypeIn,
        const String& oColumnTypeIn );

    virtual void initializePlotAttrib( const Bool& bHMSIn,
        const String& oXLabelIn, const String& oYLabelIn,
        const String& oTitleIn, const String& oXLabelDefaultIn,
        const String& oYLabelDefaultIn, const String& oTitleDefaultIn );

private:
  MethodResult runMethod1( uInt uiMethod, ParameterSet& oParameters,
			   Bool bRunMethod );
  MethodResult runMethod2( uInt uiMethod, ParameterSet& oParameters,
			   Bool bRunMethod );

    Bool bArgCheck;

    Vector<Double>* poX;
    Vector<Double>* poXOld;  

    Matrix<Double>* poYOrig;
    Matrix<Double>* poY;

    Vector<Double>* poXErr;
    Vector<Double>* poXErrOld;

    Matrix<Double>* poYErrOrig;
    Matrix<Double>* poYErr;

    Vector<String>* poToken;

    Matrix<Bool>* poFlagOrig;
    Matrix<Bool>* poFlag;
    
    String* poTokenType;
    String* poColumnType;
    
    Bool bHMSOld;
    Bool bHMS;
    
    Bool bXError;
    Bool bYError;
    
    Vector<String>* poTokenList;
    Vector<String>* poColumnList;
    
    Vector<Int>* poHistoryEvent;
    Vector<Int>* poHistoryIndex;
    Vector<Int>* poHistoryColumn;
    Vector<Bool>* poHistoryFlag;
    Vector<Bool>* poHistoryInterp;
    Vector<Double>* poHistoryY;
    Vector<Double>* poHistoryYErr;
    
    Matrix<Bool>* poInterp;

    Double dXMinDefault;
    Double dXMaxDefault;

    Double dYMinDefault;
    Double dYMaxDefault;
    
    Double dXMinPlot;
    Double dXMaxPlot;
    
    Double dYMinPlot;
    Double dYMaxPlot;
    
    Vector<String>* poTokenPlot;
    Vector<String>* *aoColumnPlot;
    
    Bool bFlag;
    Bool bColor;
    Bool bLine;
    Bool bKeep;
    
    String* poXLabelDefault;
    String* poYLabelDefault;
    String* poTitleDefault;
    
    String* poXLabel;
    String* poYLabel;
    String* poTitle;

    void loadASCII( String& oFileIn, Vector<Double>& oXOut,
        Matrix<Double>& oYOut, Vector<Double>& oXErrOut,
        Matrix<Double>& oYErrOut, Vector<String>& oTokenOut,
        Vector<String>& oColumnOut, Matrix<Bool>& oFlagOut );

    void plotPoints( const Vector<Int>* const poIndexIn, const uInt& uiColumn,
        const Int& iCIIn ) const;
    void plotLine( const Vector<Int>* const poIndexIn, const uInt& uiColumn,
        const Int& iCIIn ) const;

};


// #endif (Include file?)

#endif // __GDC2TOKEN_H
