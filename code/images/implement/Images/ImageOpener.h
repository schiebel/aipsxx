//# ImageOpener.h: A class with static functions to open an image of any type
//# Copyright (C) 2005
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
//# $Id: ImageOpener.h,v 19.1 2005/03/16 15:02:18 gvandiep Exp $

#ifndef IMAGES_IMAGEOPENER_H
#define IMAGES_IMAGEOPENER_H


#include <casa/aips.h>
#include <images/Images/MaskSpecifier.h>
#include <casa/Containers/SimOrdMap.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward Declarations
class LatticeBase;

// <summary>
// Definition of image types and handlers
// </summary>
//
// <use visibility=local>
//
// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>
// 
// <synopsis>
// The class contains defines the possible image types.
// It contains a registry containing functions to construct an image
// based on its type. In this way any image can be used in the image package
// without the need that the code must reside in the images package.
// </synopsis>
//
// <motivation>
// FITS and MIRIAD needed to be moved out of the images package.
// </motivation>


class ImageOpener
{
public:
// Define the possible image types.
  enum ImageTypes {
    // AIPS++
    AIPSPP,
    // FITS
    FITS,
    // Miriad
    MIRIAD,
    // Gipsy
    GIPSY,
    // Classic AIPS
    CAIPS,
    // Unknown
    UNKNOWN
   };

  // Return the type of an image with the given name.  Will throw an
  // exception if file does not exist.
  static ImageTypes imageType (const String& fileName);

  // Define the signature of a function opening an image.
  // Each basic image class (like FITSImage) must have a static open function
  // with this signature.
  // They can be registered using registerOpenImageFunction.
  // In this way a function like openImage can create any image object
  // without the need that all image classes are in the images package.
  // The LogIO object can be used for possible error reporting or logging.
  typedef LatticeBase* OpenImageFunction (const String& fileName,
					  const MaskSpecifier&);

  // Register an openImageFunction.
  static void registerOpenImageFunction (ImageTypes, OpenImageFunction*);

  // Open an image in the file/table with the given name.
  // The specified mask will be applied (default is default mask).
  // A null pointer is returned for an unknown image type.
  // Non-AIPS++ image types must have been registered to be known.
  static LatticeBase* openImage (const String& fileName,
				 const MaskSpecifier& = MaskSpecifier());

  // Open an AIPS++ paged image of any data type.
  static LatticeBase* openPagedImage (const String& fileName,
				      const MaskSpecifier& = MaskSpecifier());

private:
  // The default openImage function for an unknown image type.
  // It returns a null pointer.
  static LatticeBase* unknownImageOpen (const String& name,
					const MaskSpecifier&);

  // Mapping of the image type to an openImage function.
  static SimpleOrderedMap<ImageTypes,OpenImageFunction*> theirOpenFuncMap;
};


} //# NAMESPACE CASA - END

#endif
