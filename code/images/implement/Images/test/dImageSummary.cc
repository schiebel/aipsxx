//# imhead.cc: List image header
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2003
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
//# $Id: dImageSummary.cc,v 19.5 2005/03/17 08:23:14 gvandiep Exp $
//
#include <casa/aips.h>
#include <casa/System/Aipsrc.h>
#include <casa/Exceptions/Error.h>
#include <casa/Inputs/Input.h>
#include <casa/Logging.h>
#include <casa/Utilities/DataType.h>
#include <casa/BasicSL/String.h>
#include <images/Images/ImageUtilities.h>
#include <images/Images/ImageOpener.h>
#include <images/Images/ImageSummary.h>
#include <images/Images/PagedImage.h>
#include <images/Images/FITSImage.h>
#include <images/Images/MIRIADImage.h>
#include <measures/Measures/MDoppler.h>

#include <casa/namespace.h>

int main (int argc, char **argv)
{
try {

   Input inputs(1);
   inputs.version ("$Revision: 19.5 $");

   String root = Aipsrc::aipsRoot();
   String name = root + "/data/demo/Images/test_image";
   inputs.create("in", name, "Input image name?");
   inputs.create("type", "RADIO","Velocity type ?");
   inputs.readArguments(argc, argv);
   const String in = inputs.getString("in");
   const String velocityType = inputs.getString("type");


// Open image, construct helper class object and list header

   if (in.empty()) {
      cout << "You must specify the image file name" << endl;
      return 1;
   }

   LogOrigin lor("imhead", "main()", WHERE);
   LogIO os(lor);

// Parse velocity type

   MDoppler::Types doppler;
   Bool ok = MDoppler::getType(doppler, velocityType);
   if (!ok) {
     os << "Invalid velocity type, using RADIO" << endl;
     doppler = MDoppler::RADIO;
   }     
//
   ImageOpener::ImageTypes imageType = ImageOpener::imageType(in);
   if (imageType==ImageOpener::AIPSPP) {
      DataType pixelType = imagePixelType(in);
      if (pixelType==TpFloat) {    
         PagedImage<Float> im(in);
         ImageSummary<Float> header(im);
         header.list(os, doppler);
      } else {
         os << "Float images only" << LogIO::EXCEPTION;
      }
   } else if (imageType==ImageOpener::FITS) {
      FITSImage im(in);
      ImageSummary<Float> header(im);
      header.list(os, doppler);
   } else if (imageType==ImageOpener::MIRIAD) {  
      MIRIADImage im(in);
      ImageSummary<Float> header(im);
      header.list(os, doppler);
   } else {
     os << "Unrecognized image type" << LogIO::EXCEPTION;
   }


  } catch (AipsError x) {
     cerr << "aipserror: error " << x.getMesg() << endl;
     return 1;
  } 

return 0;
}
