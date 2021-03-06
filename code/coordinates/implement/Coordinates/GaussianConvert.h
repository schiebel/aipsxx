//# GaussianConvert.h: Class to convert units of Gaussians from pixel to world 
//# Copyright (C) 1997,1998,1999,2000
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
//# $Id: GaussianConvert.h,v 19.4 2004/11/30 17:50:22 ddebonis Exp $

#ifndef COORDINATES_GAUSSIANCONVERT_H
#define COORDINATES_GAUSSIANCONVERT_H

//# Includes
#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <coordinates/Coordinates/CoordinateSystem.h>

namespace casa { //# NAMESPACE CASA - BEGIN

template<class T> class Quantum;


// <summary>
// Converts Gaussian parameters between pixel and world
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class=></linkto>
// </prerequisite>

// <synopsis> 
// Converts Gaussian parameters between world and pixel. 
// In the pixel coordinate system ([0,0] in center of image)
// the position angle is positive +y to -x. This is consistent
// with Gaussian2D.  In the world coordinate system the pa
// is positive N through E
// </synopsis> 

// <example>
// <srcblock>
// </srcblock>
// </example>

// <todo asof="1998/12/11">
// Position angle signs require more thinking in aips++
// </todo>

class GaussianConvert
{
public:

    // Default constructor
    GaussianConvert ();

    // Constructor.  You specify which world axes (must be length 2)
    // of the coordinate system are the relevant ones for
    // your gaussian (x then y)
    GaussianConvert (const CoordinateSystem& cSys, 
                     const Vector<uInt>& worldAxes);

    // Destructor
   ~GaussianConvert ();

    // Copy constructor.  Uses copy semantics.
    GaussianConvert(const GaussianConvert& other);
 
    // Assignment operator. Uses copy semantics.
    GaussianConvert& operator=(const GaussianConvert& other);

    // (Re)set the coordinate system 
    void setCoordinateSystem (const CoordinateSystem& cSys);

    // Re(set) the world axes 
    void setWorldAxes (const Vector<uInt>& worldAxes);

    // Convert Gaussian parameters from pixels to world.  Returns
    // False if it fails with an error message recoverable with
    // function errorMessage.  If you set the units of the output
    // axis quanta they will be honoured, otherwise they will come out
    // in the axis units of the coordinate system.  For the output position angle,
    // if the output units are not set, the units of the input position angle
    // will be used.
    Bool toWorld(Quantum<Double>& majorAxisOut, Quantum<Double>& minorAxisOut,
                 Quantum<Double>& positionAngleOut, Double majorAxisIn,
                 Double minorAxisIn, const Quantum<Double>& positionAngleIn);

    // Convert Gaussian parameters from world to pixel.  Returns
    // False if it fails with an error message recoverable with
    // function errorMessage. For the output position angle,
    // if the output units are not set, the units of the input position angle
    // will be used.
    Bool toPixel(Double& majorAxisOut, Double& minorAxisOut,
                 Quantum<Double>& positionAngleOut, const Quantum<Double>& majorAxisIn,
                 const Quantum<Double>& minorAxisIn, const Quantum<Double>& positionAngleIn);

    // Convert location
    // <group>
    Bool toPixel(Vector<Double>& pixel,
                 const Vector<Quantum<Double> >& world);
    Bool toWorld(Vector<Quantum<Double> >& world,
                 const Vector<Double>& pixel);
    // </group>

    // Deconvolve the parameters of a source Gaussian from a beam Gaussian 
    // to give a model Gaussian.  The return is True if the model appears
    // to be a point source and the output model will be set to
    // the parameters of the beam.  If the units of the model are not given,
    // they will be set to the units of the source.
    static Bool deconvolve(Quantum<Double>& majorAxisModel, 
                           Quantum<Double>& minorAxisModel,
                           Quantum<Double>& positionAngleModel, 
                           const Quantum<Double>& majorAxisSource,
                           const Quantum<Double>& minorAxisSource,
                           const Quantum<Double>& positionAngleSource,
                           const Quantum<Double>& majorAxisBeam,
                           const Quantum<Double>& minorAxisBeam,
                           const Quantum<Double>& positionAngleBeam);

    // Recover error messages from the conversion functions
    String errorMessage() const {return itsErrorMessage;}


private:

   CoordinateSystem itsCSys;
   Vector<uInt> itsWorldAxes;
   String itsErrorMessage;
   Bool itsValid;

   void convertAxes (Double& minorAxisOut, Double& majorAxisOut,
                     Quantum<Double>& positionAngleOut,
                     Double minorAxisIn, Double majorAxisIn,
                     const Quantum<Double>& positionAngleIn,
                     const CoordinateSystem& cSys,
                     String dir);

   void checkCoordinateSystem();

   void checkWorldAxes();

   Double positionAngleRange(Double pa);

};


} //# NAMESPACE CASA - END

#endif
