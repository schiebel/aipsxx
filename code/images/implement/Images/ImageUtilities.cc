//# ImageUtilities.cc:  Helper class for accessing images
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
//# $Id: ImageUtilities.cc,v 19.7 2005/03/16 15:02:18 gvandiep Exp $
//

#include <images/Images/ImageUtilities.h>
#include <images/Images/ImageOpener.h>

#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayMath.h>
#include <coordinates/Coordinates/CoordinateUtil.h>
#include <coordinates/Coordinates/CoordinateSystem.h>
#include <coordinates/Coordinates/DirectionCoordinate.h>
#include <coordinates/Coordinates/StokesCoordinate.h>
#include <coordinates/Coordinates/LinearCoordinate.h>
#include <coordinates/Coordinates/TabularCoordinate.h>
#include <components/ComponentModels/ComponentType.h>
#include <components/ComponentModels/SkyComponent.h>
#include <components/ComponentModels/GaussianShape.h>
#include <images/Images/ImageInfo.h>
#include <images/Images/PagedImage.h>
#include <images/Images/RegionHandler.h>
#include <images/Images/ImageRegion.h>
#include <images/Images/SubImage.h>
#include <images/Images/TempImage.h>
#include <lattices/Lattices/LCRegion.h>
#include <lattices/Lattices/LatticeIterator.h>
#include <lattices/Lattices/SubLattice.h>
#include <casa/Logging/LogIO.h>
#include <measures/Measures/Stokes.h>
#include <casa/Quanta/MVAngle.h>
#include <casa/Quanta/Unit.h>
#include <casa/Quanta/Quantum.h>
#include <casa/OS/File.h>
#include <tables/LogTables/NewFile.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/LinearSearch.h>
#include <casa/Utilities/PtrHolder.h>
#include <casa/iostream.h>



namespace casa { //# NAMESPACE CASA - BEGIN


void ImageUtilities::openImage (ImageInterface<Float>*& pImage,
                                const String& fileName, LogIO& os)
{
   if (fileName.empty()) {
      os << "The image filename is empty" << LogIO::EXCEPTION;   
   }
   File file(fileName);
   if (!file.exists()) {
      os << "File '" << fileName << "' does not exist" << LogIO::EXCEPTION;
   }
   LatticeBase* lattPtr = ImageOpener::openImage (fileName);
   if (lattPtr == 0) {
     os << "Image " << fileName << " cannot be opened; its type is unknown"
	<< LogIO::EXCEPTION;
   } 
   pImage = dynamic_cast<ImageInterface<Float>*>(lattPtr);
   if (pImage == 0) {
      os << "Unrecognized image data type, "
	    "presently only Float images are supported" 
         << LogIO::EXCEPTION;
   }
}

void ImageUtilities::openImage (PtrHolder<ImageInterface<Float> >& image,
                                const String& fileName, LogIO& os)
{
   ImageInterface<Float>* p = 0;
   ImageUtilities::openImage(p, fileName, os);
   image.set(p);
}


Bool ImageUtilities::pixToWorld (Vector<String>& sWorld,
                                 CoordinateSystem& cSysIn,
                                 const Int& pixelAxis,
                                 const Vector<Int>& cursorAxes,
                                 const IPosition& blc,
                                 const IPosition& trc,
                                 const Vector<Double>& pixels,
                                 const Int& prec)
//
// This function converts pixel coordinates to world coordinates.
// You specify pixel coordinates for only  one axis, the pixel axis,
// and you specify a Vector of pixels for conversion.   For the
// other pixel axes,  if a pixel axis is found in the CursorAxes
// vector, its pixel coordinate is set to the average pixel coordinate
// in the specified region ((blc(i)+trc(i))/2), otherwise it
// is set to the reference pixel. The Vector of world coordinates
// for the pixel axis is returned as formatted Strings.  If for some
// reason it can't make the conversion, a string is returned as "?"
// 
// Inputs
//   cSysIn        The CoordinateSystem associated with the image
//   pixelAxis     The pixel axis whose coordinates we are interested in.
//   cursorAxes    If any of the pixel axes, i, in the image are found this
//                 vector, assign their pixel coordinate to 
//                 (blc(i) + trc(i)) / 2  otherwise they get the 
//                 reference pixel
//   blc,trc       The region of the image being accessed. The average
//                 pixel coordinate in this region is used for the axes
//                 found in CursorAxes.  These must be of the same 
//                 dimension as the no. of pixel axes in teh 
//                 CoordinateSystem
//   pixels        Vector of pixel coordinates (0 rel) to transform
//                 for the pixel axis of interest. 
//   prec          Precision to format scientific output
// Outputs
//   sWorld        Vector of formatted strings of world coordinates
//                 for the pixel axis
//
{

// CHeck blc,trc

   if (blc.nelements()!=cSysIn.nPixelAxes() || trc.nelements()!=cSysIn.nPixelAxes()) return False;

// Create pixel and world vectors for all pixel axes. Initialize pixel values
// to reference pixel, but if an axis is a cursor axis (whose coordinate is
// essentially being averaged) set the pixel to the mean pixel.

   Vector<Double> pix(cSysIn.nPixelAxes());
   Vector<Double> world(cSysIn.nPixelAxes());
   pix = cSysIn.referencePixel(); 
   Bool found;
   uInt i;
   for (i=0; i<pix.nelements(); i++) {
     if (linearSearch(found, cursorAxes, Int(i), cursorAxes.nelements()) != -1) {
        pix(i) = Double(blc(i) + trc(i)) / 2.0;
     }
   }
         
            
// Find the world axis for this pixel axis 
            
   const Int worldAxis = cSysIn.pixelAxisToWorldAxis(pixelAxis);

          
// Convert to world and format 

   String formatUnits;
   const uInt n1 = pixels.nelements();
   sWorld.resize(n1);

// Loop over list of pixel coordinates and convert to world
         
   for (i=0; i<n1; i++) {
      pix(pixelAxis) = pixels(i);
      if (cSysIn.toWorld(world,pix)) {
         sWorld(i) = cSysIn.format(formatUnits, Coordinate::DEFAULT, world(pixelAxis), 
                                   worldAxis, True, True, prec);
      } else {
         sWorld(i) = "?";
      }
   }

   return True;
}




String ImageUtilities::shortAxisName (const String& axisName)
//
// Look for "Right Ascension", "Declination", "Velocity",
// and "Frequency" in an axis string name and return "RA", 
// "Dec", "Vel", "Freq", respectively
// if these are found.  Anything else is returned as is.
// This will go away when I do something in the Coordinates
// classes to return long, short and FITS names
//
{
   String temp = axisName;
   temp.upcase();
   if (temp.contains("RIGHT ASCENSION")) {
     temp = "RA";
   } else if (temp.contains("DECLINATION")) {
     temp = "Dec";
   } else if (temp.contains("VELOCITY")) {
     temp = "Vel";
   } else if (temp.contains("FREQUENCY")) {
     temp = "Freq";
   } else {
     temp = axisName;
   }
   return temp;
}


SkyComponent ImageUtilities::encodeSkyComponent(LogIO& os, Double& facToJy,
                                                const ImageInfo& ii,
                                                const CoordinateSystem& cSys,
                                                const Unit& brightnessUnit,
                                                ComponentType::Shape type,
                                                const Vector<Double>& parameters,
                                                Stokes::StokesTypes stokes,
                                                Bool xIsLong)
// Input:
//   pars(0) = FLux     image units  (e.g. peak flux in Jy/beam)
//   pars(1) = x cen    abs pix
//   pars(2) = y cen    abs pix
//   pars(3) = major    pix
//   pars(4) = minor    pix
//   pars(5) = pa radians (pos +x -> +y)
//
{
   SkyComponent sky;
  
// Account for the fact that 'x' could be longitude or latitude.  Urk.

   Vector<Double> pars = parameters.copy();
   if (!xIsLong) {
      Double tmp = pars(0);
      pars(0) = pars(1);
      pars(1) = tmp;
//
      Double pa0 = pars(5);
      MVAngle pa(pa0 + C::pi_2);
      pa();                         // +/- pi
      pars(5) = pa.radian();
   }
//
   Vector<Quantum<Double> > beam = ii.restoringBeam();
   sky.fromPixel(facToJy, pars, brightnessUnit, beam, cSys, type, stokes);
   return sky;
} 


Vector<Double> ImageUtilities::decodeSkyComponent (const SkyComponent& sky,
                                                   const ImageInfo& ii,
                                                   const CoordinateSystem& cSys,
                                                   const Unit& brightnessUnit,
                                                   Stokes::StokesTypes stokes,
                                                   Bool xIsLong)
//
// The decomposition of the SkyComponent gives things as longitide 
// and latitude.  But it is possible that the x and y axes of the 
// pixel array are lat/long rather than long/lat if the CoordinateSystem 
// has been reordered.  So we have to take this into account.
//
// Output:
//   pars(0) = FLux     image units  (e.g. peak flux in Jy/beam)
//   pars(1) = x cen    abs pix
//   pars(2) = y cen    abs pix
//   pars(3) = major    pix
//   pars(4) = minor    pix
//   pars(5) = pa radians (pos +x -> +y)
//
{
   Vector<Quantum<Double> > beam = ii.restoringBeam();

// pars(1,2) = longitude, latitude centre

   Vector<Double> pars = sky.toPixel (brightnessUnit, beam, cSys, stokes).copy();

// Now account for the fact that 'x' (horizontally displayed axis) could be
// longitude or latitude.  Urk.
  
   Double pa0 = pars(5);
   if (!xIsLong) {
      Double tmp = pars(0);
      pars(0) = pars(1);
      pars(1) = tmp;
//   
      MVAngle pa(pa0 - C::pi_2);
      pa();                         // +/- pi
      pa0 = pa.radian();
   }
   pars(5) = pa0;
//
   return pars;
}



void ImageUtilities::worldWidthsToPixel (LogIO& os,
                                         Vector<Double>& dParameters,
                                         const Vector<Quantum<Double> >& wParameters,
                                         const CoordinateSystem& cSys,
                                         const IPosition& pixelAxes,
                                         Bool doRef)
//
// world parameters: x, y, major, minor, pa
// pixel parameters: major, minor, pa (rad)
//
{
   if (pixelAxes.nelements()!=2) {
      os << "You must give two pixel axes" << LogIO::EXCEPTION;
   }
   if (wParameters.nelements()!=5) {
      os << "The world parameters vector must be of length 5" << LogIO::EXCEPTION;
   }
//
   dParameters.resize(3);
   Int c0, c1, axisInCoordinate0, axisInCoordinate1;
   cSys.findPixelAxis(c0, axisInCoordinate0, pixelAxes(0));
   cSys.findPixelAxis(c1, axisInCoordinate1, pixelAxes(1));
      
// Find units
   
   String majorUnit = wParameters(2).getFullUnit().getName();
   String minorUnit = wParameters(3).getFullUnit().getName();
        
// This saves me trying to handle mixed pixel/world units which is a pain for coupled coordinates
    
   if ( (majorUnit==String("pix") && minorUnit!=String("pix"))  ||
        (majorUnit!=String("pix") && minorUnit==String("pix")) ) {
         os << "If pixel units are used, both major and minor axes must have pixel units" << LogIO::EXCEPTION;
   }
         
// Some checks
      
   Coordinate::Type type0 = cSys.type(c0);
   Coordinate::Type type1 = cSys.type(c1);
   if (type0 != type1) {
      if (majorUnit!=String("pix") || minorUnit!=String("pix")) {
         os << "The coordinate types for the convolution axes are different" << endl;
         os << "Therefore the units of the major and minor axes of " << endl;
         os << "the convolution kernel widths must both be pixels" << LogIO::EXCEPTION;
      }
   }
   if (type0==Coordinate::DIRECTION && type1==Coordinate::DIRECTION &&  c0!=c1) {
      os << "The given axes do not come from the same Direction coordinate" << endl;
      os << "This situation requires further code development" << LogIO::EXCEPTION;
   }
   if (type0==Coordinate::STOKES || type1==Coordinate::STOKES) {
         os << "Cannot convolve Stokes axes" << LogIO::EXCEPTION;
   }
      
// Deal with pixel units separately.    Both are in pixels if either is in pixels.

   if (majorUnit==String("pix")) {
      dParameters(0) = max(wParameters(2).getValue(), wParameters(3).getValue());
      dParameters(1) = min(wParameters(2).getValue(), wParameters(3).getValue());
// 
      if (type0==Coordinate::DIRECTION && type1==Coordinate::DIRECTION) {
         const DirectionCoordinate& dCoord = cSys.directionCoordinate (c0);

// Use GaussianShape to get the position angle right. Use the specified
// direction or the reference direction

         MDirection world;
         if (doRef) {
            dCoord.toWorld(world, dCoord.referencePixel());
         } else {
            world = MDirection(wParameters(0), wParameters(1), dCoord.directionType());
         }
//
         Quantum<Double> tmpMaj(1.0, Unit("arcsec"));
         GaussianShape gaussShape(world, tmpMaj, dParameters(1)/dParameters(0), 
                                  wParameters(4));                              // pa is N->E
         Vector<Double> pars = gaussShape.toPixel (dCoord);
         dParameters(2) = pars(4);                                              // pa: +x -> +y
       } else {
      
// Some 'mixed' plane; the pa is already +x -> +y
   
         dParameters(2) = wParameters(4).getValue(Unit("rad"));                  // pa
       }
       return;
   }

// Continue on if non-pixel units

   if (type0==Coordinate::DIRECTION && type1==Coordinate::DIRECTION) {
      
// Check units are angular
      
      Unit rad(String("rad"));
      if (!wParameters(2).check(rad.getValue())) {
         os << "The units of the major axis must be angular" << LogIO::EXCEPTION;
      }
      if (!wParameters(3).check(rad.getValue())) {
         os << "The units of the minor axis must be angular" << LogIO::EXCEPTION;
      }
                                   
// Make a Gaussian shape to convert to pixels at specified location
  
      const DirectionCoordinate& dCoord = cSys.directionCoordinate (c0);
// 
      MDirection world;
      if (doRef) {
         dCoord.toWorld(world, dCoord.referencePixel());
      } else {
         world = MDirection(wParameters(0), wParameters(1), dCoord.directionType());
      }
      GaussianShape gaussShape(world, wParameters(2), wParameters(3), wParameters(4));
      Vector<Double> pars = gaussShape.toPixel (dCoord);
      dParameters(0) = pars(2);
      dParameters(1) = pars(3);
      dParameters(2) = pars(4);      // radians; +x -> +y
   } else {

// The only other coordinates currently available are non-coupled
// ones and linear except for Tabular, which can be non-regular.
// Urk.
    
// Find major and minor axes in pixels

      dParameters(0) = worldWidthToPixel (os, dParameters(2), wParameters(2), 
                                          cSys, pixelAxes);
      dParameters(1) = worldWidthToPixel (os, dParameters(2), wParameters(3), 
                                          cSys, pixelAxes);
      dParameters(2) = wParameters(4).getValue(Unit("rad"));                // radians; +x -> +y
   }

// Make sure major > minor

   Double tmp = dParameters(0);
   dParameters(0) = max(tmp, dParameters(1));
   dParameters(1) = min(tmp, dParameters(1));
}   



Bool ImageUtilities::pixelWidthsToWorld (LogIO& os, 
                                         Vector<Quantum<Double> >& wParameters,
                                         const Vector<Double>& pParameters,
                                         const CoordinateSystem& cSys, 
                                         const IPosition& pixelAxes, 
                                         Bool doRef)
//
// pixel parameters: x, y, major, minor, pa (rad)
// world parameters: major, minor, pa
//
{
   if (pixelAxes.nelements()!=2) {
      os << "You must give two pixel axes" << LogIO::EXCEPTION;
   }
   if (pParameters.nelements()!=5) {
      os << "The parameters vector must be of length 5" << LogIO::EXCEPTION;
   }
//
   Int c0, axis0, c1, axis1;
   cSys.findPixelAxis(c0, axis0, pixelAxes(0));
   cSys.findPixelAxis(c1, axis1, pixelAxes(1));
   Bool flipped = False;
   if (cSys.type(c1)==Coordinate::DIRECTION  && cSys.type(c0)==Coordinate::DIRECTION) {
      if (c0==c1) {
         flipped = skyPixelWidthsToWorld(os, wParameters, cSys, pParameters, pixelAxes, doRef);
      } else {
         os << "Cannot yet handle axes from different DirectionCoordinates" << LogIO::EXCEPTION;
      }
   } else {
      wParameters.resize(3);

// Major/minor 

      Quantum<Double> q0 = pixelWidthToWorld (os, pParameters(4), pParameters(2),
                                              cSys, pixelAxes);
      Quantum<Double> q1 = pixelWidthToWorld (os, pParameters(4), pParameters(3),
                                              cSys, pixelAxes);
//
      if (q0.getValue() < q1.getValue(q0.getFullUnit())) {
         flipped = True;
         wParameters(0) = q1;
         wParameters(1) = q0;
      } else {
         wParameters(0) = q0;
         wParameters(1) = q1;
      }

// Position angle; radians; +x -> +y

      wParameters(2).setValue(pParameters(4));
      wParameters(2).setUnit(Unit("rad"));
   }
   return flipped;
}  
   


Bool ImageUtilities::skyPixelWidthsToWorld (LogIO& os, 
                                            Vector<Quantum<Double> >& wParameters,
                                            const CoordinateSystem& cSys, 
                                            const Vector<Double>& pParameters,
                                            const IPosition& pixelAxes, Bool doRef)
//
// pixel parameters: x, y, major, minor, pa (rad)
// world parameters: major, minor, pa
//
{

// What coordinates are these axes ?

   Int c0, c1, axisInCoordinate0, axisInCoordinate1;
   cSys.findPixelAxis(c0, axisInCoordinate0, pixelAxes(0));
   cSys.findPixelAxis(c1, axisInCoordinate1, pixelAxes(1));   
                                 
// See what sort of coordinates we have. Make sure it is called
// only for the Sky.  More development needed otherwise.
                                 
   Coordinate::Type type0 = cSys.type(c0);
   Coordinate::Type type1 = cSys.type(c1);
   if (type0!=Coordinate::DIRECTION || type1!=Coordinate::DIRECTION) {
      os << "Can only be called for axes holding the sky" << LogIO::EXCEPTION;
   }
   if (c0!=c1) {
      os << "The given axes do not come from the same Direction coordinate" << endl;
      os << "This situation requires further code development" << LogIO::EXCEPTION;
   }
      
// Is the 'x' (first axis) the Longitude or Latitude ?
          
   Vector<Int> dirPixelAxes = cSys.pixelAxes(c0);
   Bool xIsLong = dirPixelAxes(0)==pixelAxes(0) && dirPixelAxes(1)==pixelAxes(1);
   uInt whereIsX = 0;
   uInt whereIsY = 1;
   if (!xIsLong) {
      whereIsX = 1;
      whereIsY = 0;
   }
   
// Encode a pretend GaussianShape from these values as a means     
// of converting to world.         

   const DirectionCoordinate& dCoord = cSys.directionCoordinate(c0);
   GaussianShape gaussShape;
   Vector<Double> cParameters(pParameters.copy());
//
   if (doRef) {
      cParameters(0) = dCoord.referencePixel()(whereIsX);     // x centre
      cParameters(1) = dCoord.referencePixel()(whereIsY);     // y centre
   } else {
      if (xIsLong) {
         cParameters(0) = pParameters(0);
         cParameters(1) = pParameters(1);
      } else {
         cParameters(0) = pParameters(1);
         cParameters(1) = pParameters(0);
      }
   }
//  
   Bool flipped = gaussShape.fromPixel (cParameters, dCoord);
   wParameters.resize(3);
   wParameters(0) = gaussShape.majorAxis();
   wParameters(1) = gaussShape.minorAxis();
   wParameters(2) = gaussShape.positionAngle();
//
   return flipped;
}  
   
   

// Private

Double ImageUtilities::worldWidthToPixel (LogIO& os, Double positionAngle, 
                                          const Quantum<Double>& length,
                                          const CoordinateSystem& cSys,
                                          const IPosition& pixelAxes)
{
// 
   Int worldAxis0 = cSys.pixelAxisToWorldAxis(pixelAxes(0));
   Int worldAxis1 = cSys.pixelAxisToWorldAxis(pixelAxes(1));

// Units of the axes must be consistent for now.
// I will be able to relax this criterion when I get the time

   Vector<String> units = cSys.worldAxisUnits();
   Unit unit0(units(worldAxis0));
   Unit unit1(units(worldAxis1));
   if (unit0 != unit1) {
      os << "Units of the two axes must be conformant" << LogIO::EXCEPTION;
   }
   Unit unit(unit0);

// Check units are ok

   if (!length.check(unit.getValue())) {
      ostringstream oss;
      oss << "The units of the world length (" << length.getFullUnit().getName()
          << ") are not consistent with those of Coordinate System ("
          << unit.getName() << ")";
      String s(oss);
      os << s << LogIO::EXCEPTION;
   }
//
   Double w0 = cos(positionAngle) * length.getValue(unit);
   Double w1 = sin(positionAngle) * length.getValue(unit);

// Find pixel coordinate of tip of axis  relative to reference pixel

   Vector<Double> world = cSys.referenceValue().copy();
   world(worldAxis0) += w0;
   world(worldAxis1) += w1;
// 
   Vector<Double> pixel;
   if (!cSys.toPixel (pixel, world)) {
      os << cSys.errorMessage() << LogIO::EXCEPTION;
   }
//  
   Double lengthInPixels = hypot(pixel(pixelAxes(0)), pixel(pixelAxes(1)));
   return lengthInPixels;
}


Quantum<Double> ImageUtilities::pixelWidthToWorld (LogIO& os, 
                                                   Double positionAngle, 
                                                   Double length,
                                                   const CoordinateSystem& cSys2,
                                                   const IPosition& pixelAxes)
{
   CoordinateSystem cSys(cSys2);
   Int worldAxis0 = cSys.pixelAxisToWorldAxis(pixelAxes(0));
   Int worldAxis1 = cSys.pixelAxisToWorldAxis(pixelAxes(1));

// Units of the axes must be consistent for now.
// I will be able to relax this criterion when I get the time

   Vector<String> units = cSys.worldAxisUnits().copy();
   Unit unit0(units(worldAxis0));
   Unit unit1(units(worldAxis1));
   if (unit0 != unit1) {
      os << "Units of the axes must be conformant" << LogIO::EXCEPTION;
   }

// Set units to be the same for both axes
 
   units(worldAxis1) = units(worldAxis0);
   if (!cSys.setWorldAxisUnits(units)) {
      os << cSys.errorMessage() << LogIO::EXCEPTION;
   } 
// 
   Double p0 = cos(positionAngle) * length;
   Double p1 = sin(positionAngle) * length;

// Find world coordinate of tip of length relative to reference pixel

   Vector<Double> pixel= cSys.referencePixel().copy();
   pixel(pixelAxes(0)) += p0;
   pixel(pixelAxes(1)) += p1;
// 
   Vector<Double> world;
   if (!cSys.toWorld(world, pixel)) {
      os << cSys.errorMessage() << LogIO::EXCEPTION;
   }
//  
   Double lengthInWorld = hypot(world(worldAxis0), world(worldAxis1));
   Quantum<Double> q(lengthInWorld, Unit(units(worldAxis0)));
//
   return q;
}


void ImageUtilities::addDegenerateAxes (LogIO& os, 
                                        PtrHolder<ImageInterface<Float> >& outImage,
                                        ImageInterface<Float>& inImage,
                                        const String& outFile, Bool direction,
                                        Bool spectral, const String& stokes,
                                        Bool linear, Bool tabular, Bool overwrite)
{
// Verify output file
      
   if (!overwrite && !outFile.empty()) {
      NewFile validfile;
      String errmsg;
      if (!validfile.valueOK(outFile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
      }
   }
//
   IPosition shape = inImage.shape();
   CoordinateSystem cSys = inImage.coordinates();
   IPosition keepAxes = IPosition::makeAxisPath(shape.nelements());
   Int afterCoord;
   uInt nExtra = 1;
//
   Bool didSomething = False;
   if (direction) {
      afterCoord = -1;

      Int iC = cSys.findCoordinate(Coordinate::DIRECTION, afterCoord);
      if (iC<0) {
         CoordinateUtil::addDirAxes(cSys);
         nExtra = 2;
         didSomething = True;
      } else {
         os << "Image already contains a DirectionCoordinate" << LogIO::EXCEPTION;
      }
   }
//
   if (spectral) {
      afterCoord = -1;
      Int iC = cSys.findCoordinate(Coordinate::SPECTRAL, afterCoord);
      if (iC<0) {
         CoordinateUtil::addFreqAxis(cSys);
         didSomething = True;
      } else {
         os << "Image already contains a SpectralCoordinate" << LogIO::EXCEPTION;
      }
   }
//
   if (!stokes.empty()) {
      afterCoord = -1;
      Int iC = cSys.findCoordinate(Coordinate::STOKES, afterCoord);
      if (iC<0) {
         Vector<Int> which(1);
         String tmp = upcase(stokes);
         which(0) = Stokes::type(tmp);
         StokesCoordinate sc(which);
         cSys.addCoordinate(sc);
//
         didSomething = True;
      } else {
         os << "Image already contains a StokesCoordinate" << LogIO::EXCEPTION;
      }
   }
   if (linear) {
      afterCoord = -1;
      Int iC = cSys.findCoordinate(Coordinate::LINEAR, afterCoord);
      if (iC<0) {
         Vector<String> names(1);
         Vector<String> units(1);
         Vector<Double> refVal(1);
         Vector<Double> refPix(1);
         Vector<Double> incr(1);
         names(0) = "Axis1";
         units(0) = "km";
         refVal(0) = 0.0;
         refPix(0) = 0.0;
         incr(0) = 1.0;
         Matrix<Double> pc(1,1);
         pc.set(0.0);
         pc.diagonal() = 1.0;
         LinearCoordinate lc(names, units, refVal, incr, pc, refPix);
         cSys.addCoordinate(lc);
//  
         didSomething = True;
      } else {
         os << "Image already contains a LinearCoordinate" << LogIO::EXCEPTION;
      }
   }
//
   if (tabular) {
      afterCoord = -1;
      Int iC = cSys.findCoordinate(Coordinate::TABULAR, afterCoord);
      if (iC<0) {
         TabularCoordinate tc;
         cSys.addCoordinate(tc);
//  
         didSomething = True;
      } else {
         os << "Image already contains a TabularCoordinate" << LogIO::EXCEPTION;
      }
   }
//
   if (didSomething) {
      uInt n = shape.nelements();
      shape.resize(n+nExtra,True);
      for (uInt i=0; i<nExtra; i++) {
         shape(n+i) = 1;
      }
   } else {
      os << "No degenerate axes specified" << LogIO::EXCEPTION;
   }
//       
   if (outFile.empty()) {
      os << LogIO::NORMAL << "Creating (temp)image of shape "
         << shape << LogIO::POST;
      outImage.set(new TempImage<Float>(shape, cSys));
   } else {
      os << LogIO::NORMAL << "Creating image '" << outFile << "' of shape "
         << shape << LogIO::POST;
      outImage.set(new PagedImage<Float>(shape, cSys, outFile));
   }   
   ImageInterface<Float>* pOutImage = outImage.ptr();
         
// Generate output masks
         
   Vector<String> maskNames = inImage.regionNames(RegionHandler::Masks);
   const uInt nMasks = maskNames.nelements();
   if (nMasks > 0) { 
      for (uInt i=0; i<nMasks; i++) {
         pOutImage->makeMask(maskNames(i), True, False, True);
      }
   }
   pOutImage->setDefaultMask(inImage.getDefaultMask());

// Generate SubImage to copy the data into
   
   AxesSpecifier axesSpecifier(keepAxes);
   SubImage<Float> subImage(*pOutImage, True, axesSpecifier);

// Copy masks (directly, can't do via SubImage)
      
   if (nMasks > 0) {
      for (uInt i=0; i<nMasks; i++) {
         ImageUtilities::copyMask(*pOutImage, inImage, maskNames(i), maskNames(i),
                                  axesSpecifier);  
      }  
   }
   
// Copy data
    
   subImage.copyData(inImage);
 
// Copy miscellaneous
   
   ImageUtilities::copyMiscellaneous(*pOutImage, inImage);
}



void ImageUtilities::copyMask (ImageInterface<Float>& out,
                               const ImageInterface<Float>& in,
                               const String& maskOut, const String& maskIn,
                               const AxesSpecifier outSpec)
//
// Because you can't write to the mask of a SubImage, we pass
// in an AxesSpecifier to be applied to the output mask.
// In this way the dimensionality of in and out can be made
// the same.
//
{     
// Get masks
   
   ImageRegion iRIn = in.getRegion(maskIn, RegionHandler::Masks);
   const LCRegion& regionIn = iRIn.asMask();

   ImageRegion iROut = out.getRegion(maskOut, RegionHandler::Masks);
   LCRegion& regionOut = iROut.asMask();
   SubLattice<Bool> subRegionOut(regionOut, True, outSpec);
         
// Copy
               
   LatticeIterator<Bool> maskIter(subRegionOut);
   for (maskIter.reset(); !maskIter.atEnd(); maskIter++) {
      subRegionOut.putSlice(regionIn.getSlice(maskIter.position(),
                            maskIter.cursorShape()),  maskIter.position());
   }   
}  


} //# NAMESPACE CASA - END
