//# GTkDisplayData.cc: GlishTk implementation of the DisplayData
//# Copyright (C) 1999,2000,2001,2002,2003
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
//# $Id: GTkDisplayData.cc,v 19.13 2006/09/08 18:00:39 dking Exp $

#include <casa/aips.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Arrays/Array.h>
#include <casa/iostream.h>
#include <casa/iomanip.h>
#include <images/Images/PagedImage.h>
#include <images/Images/FITSImage.h>
#include <images/Images/MIRIADImage.h>
#include <images/Images/ImageUtilities.h>
#include <images/Images/ImageOpener.h>
#include <images/Images/ImageInfo.h>
#include <display/Display/AttVal.h>
#include <display/Display/WorldCanvas.h>
#include <display/Display/WorldCanvasHolder.h>
#include <display/DisplayDatas/DisplayData.h>
#include <display/DisplayDatas/LatticePADD.h>
#include <display/DisplayDatas/LatticeAsRaster.h>
#include <display/DisplayDatas/LatticeAsContour.h>
#include <display/DisplayDatas/LatticeAsVector.h>
#include <display/DisplayDatas/LatticeAsMarker.h>
#include <display/DisplayDatas/TblAsRasterDD.h>
#include <display/DisplayDatas/TblAsContourDD.h>
#include <display/DisplayDatas/TblAsXYDD.h>
#include <display/DisplayDatas/MSAsRaster.h>
#include <display/DisplayDatas/AxesDisplayData.h>
#include <display/DisplayDatas/WorldAxesDD.h>
#include <display/DisplayDatas/SkyCatOverlayDD.h>
#include <display/DisplayDatas/WedgeDD.h>
#include <display/DisplayDatas/Profile2dDD.h>

#include <display/DisplayDatas/ScrollingRasterDD.h>
#include <display/DisplayDatas/PKSMultiBeamDD.h>

#include <display/DisplayEvents/DDModEvent.h>
#include "GTkColormap.h"
#include "GTkDisplayData.h"
#include "gDisplay.h"

namespace casa {
// dk note:  This stuff really floors me....  "Why should GTkDisplayData
// _inherit_ the interface it needs, when we can do it the Rube Goldberg
// way instead?"....  (to be fixed).

void GDDPosEH::operator()(const WCPositionEvent &ev) {
  (*itsGDD)(ev);
}
void GDDMotEH::operator()(const WCMotionEvent &ev) {
  (*itsGDD)(ev);
}
void GDDDisplayEH::handleEvent(DisplayEvent &ev) {
  itsGDD->handleEvent(ev);
}




GTkDisplayData::GTkDisplayData(ProxyStore *s, String drawtype,
			       String filename, String datatype)
  : GTkDisplayProxy(s, 0),
    itsFloatImage(0),
    itsComplexImage(0),
    itsFloatArray(0),
    itsComplexArray(0),
    itsType(drawtype),
    itsPixelType(TpOther),
    itsIsValid(0) {
  // suppress AIPS++ library LogSink messages
  installNullLogSink();
  
  // simpleaxes drawtype (linear coordinate labels)
  if (!strcmp(itsType.chars(), "simpleaxes")) {
    itsDisplayData = new AxesDisplayData();
    if (!itsDisplayData) {
      throw(AipsError("Couldn't create simple pixelaxes displaydata"));
    }
    commonCtor();
    return;
  }

  // worldaxes drawtype (world axis coordinate labels)
  if (!strcmp(itsType.chars(), "worldaxes")) {
    itsDisplayData = new WorldAxesDD();
    if (!itsDisplayData) {
      throw(AipsError("Couldn't create worldaxes displaydata"));
    }
    commonCtor();
    return;
  }

  // color wedge drawtype
  if (!strcmp(itsType.chars(), "wedge")) {
    itsDisplayData = new WedgeDD();
    if (!itsDisplayData) {
      throw(AipsError("Couldn't create wedge displaydata"));
    }
    commonCtor();
    return;
  }
  
  // ProfileDD
  if (!strcmp(itsType.chars(), "profile")) {
    itsDisplayData = new Profile2dDD();
    if (!itsDisplayData) {
      throw(AipsError("Couldn't create profile displaydata"));
    }
    // create the DisplayEH for GTkDisplayData
    itsDisplayEH = new GDDDisplayEH(this);
    // add the handler to the Profile2dDD
    itsDisplayData->addDisplayEventHandler(itsDisplayEH);
    commonCtor();
    return;
  }

  // PKSMultiBeamDD
  if (!strcmp(itsType.chars(), "pksmultibeam")) {
    itsDisplayData = new PKSMultiBeamDD();
    if (!itsDisplayData) {
      throw(AipsError("Couldn't create pksmultibeam displaydata"));
    }

    commonCtor();
    return;
  }

  if (strcmp(datatype.chars(), "image")==0) {
    ImageOpener::ImageTypes iType = ImageOpener::imageType(filename);
    if (iType==ImageOpener::FITS) {

       // open the FITS image. Only Float supported.
        
       itsPixelType = TpFloat;
       itsFloatImage = new FITSImage(filename);
       if (!itsFloatImage) {
         throw(AipsError("Failed to open the FITS image"));
       }
    } else if (iType==ImageOpener::MIRIAD) {
       // open the Miriad image. Only Float supported.
        
       itsPixelType = TpFloat;
       itsFloatImage = new MIRIADImage(filename);
       if (!itsFloatImage) {
         throw(AipsError("Failed to open the Miriad image"));
       }
    } else if (iType==ImageOpener::AIPSPP) {

       // Find pixel type
       itsPixelType = imagePixelType(filename);
       AlwaysAssert(itsPixelType==TpFloat || 
		    itsPixelType==TpComplex, AipsError);

       // open the image

       if (strcmp(itsType.chars(), "vector")==0  ||
	   strcmp(itsType.chars(), "raster")==0  ||
           strcmp(itsType.chars(), "contour")==0 ||
	   strcmp(itsType.chars(), "marker")==0) {
          if (itsPixelType == TpComplex) {
	    itsComplexImage = new PagedImage<Complex>(filename, TableLock::UserNoReadLocking);
          } else {
	    itsFloatImage = new PagedImage<Float>(filename, TableLock::UserNoReadLocking);
          }
       } else {
	 if (itsPixelType != TpFloat) {
	   throw(AipsError("Image pixel type must be Float"));
	 }
	 itsFloatImage = new PagedImage<Float>(filename, TableLock::UserNoReadLocking);
       }
       if (!itsFloatImage && !itsComplexImage) {
         throw(AipsError("Failed to open the given image"));
       }
    } else {
      throw(AipsError("Native image support is presently only available for aips++, FITS & Miriad"));
    }
    
    // build the DD; bit ugly.	
    uInt ndim;
    if (itsComplexImage) {
      ndim = itsComplexImage->ndim();
    } else {
      ndim = itsFloatImage->ndim();
    }
    if (ndim < 2) {
      throw(AipsError("Image has less than two dimensions"));
    }
    
  
    IPosition shape;
    const CoordinateSystem* cs=0;
    
    if (itsComplexImage) {
      shape = itsComplexImage->shape();
      cs = &(itsComplexImage->coordinates());  }
    else {
      shape = itsFloatImage->shape();
      cs = &(itsFloatImage->coordinates());  }
    
    Block<uInt> axs(ndim);
    getInitialAxes(axs, shape, cs);
    
    IPosition fixedPos(ndim);
    fixedPos = 0;
    
    if (strcmp(itsType.chars(), "raster")==0) {
      if (itsComplexImage) {
	if (ndim == 2) {
	  itsDisplayData = (DisplayData *)
	    (new LatticeAsRaster<Complex>(itsComplexImage, 0, 1));
	} else {
	  itsDisplayData = (DisplayData *)
	    (new LatticeAsRaster<Complex>(itsComplexImage, axs[0], axs[1],
					  axs[2], fixedPos));
         }
      } else {
	if (ndim == 2) {
	  itsDisplayData = (DisplayData *)
	    (new LatticeAsRaster<Float>(itsFloatImage, 0, 1));
	} else {
	  itsDisplayData = (DisplayData *)
	       (new LatticeAsRaster<Float>(itsFloatImage, axs[0], axs[1],
	       			           axs[2], fixedPos));
	}
      }
    } else if (!strcmp(itsType.chars(), "contour")) {
      if (itsComplexImage) {
	if (ndim == 2) {
	  itsDisplayData = (DisplayData *)
	        (new LatticeAsContour<Complex>(itsComplexImage, 0, 1));
	} else {
	  itsDisplayData = (DisplayData *)
	        (new LatticeAsContour<Complex>(itsComplexImage, axs[0],
					       axs[1], axs[2], fixedPos));
	}
      } else {
	if (ndim == 2) {
	  itsDisplayData = (DisplayData *)
	    (new LatticeAsContour<Float>(itsFloatImage, 0, 1));
         } else {
	   itsDisplayData = (DisplayData *)
	        (new LatticeAsContour<Float>(itsFloatImage, axs[0], axs[1],
					     axs[2], fixedPos));
         }
      }
    } else if (!strcmp(itsType.chars(), "vector")) {
      if (itsComplexImage) {
	if (ndim == 2) {
	  itsDisplayData = (DisplayData *)
	    (new LatticeAsVector<Complex>(itsComplexImage, 0, 1));
         } else {
	   itsDisplayData = (DisplayData *)
	     (new LatticeAsVector<Complex>(itsComplexImage, axs[0], axs[1],
					   axs[2], fixedPos));
         }
      } else {
	if (ndim == 2) {
   	   itsDisplayData = (DisplayData *)
	     (new LatticeAsVector<Float>(itsFloatImage, 0, 1));
	} else {
	  itsDisplayData = (DisplayData *)
	       (new LatticeAsVector<Float>(itsFloatImage, axs[0], axs[1],
	       				   axs[2], fixedPos));
	}
      }
    } else if (!strcmp(itsType.chars(), "marker")) {
      if (itsComplexImage) {
	if (ndim == 2) {
	  itsDisplayData = (DisplayData *)
	    (new LatticeAsMarker<Complex>(itsComplexImage, 0, 1));
         } else {
	   itsDisplayData = (DisplayData *)
	     (new LatticeAsMarker<Complex>(itsComplexImage, axs[0], axs[1],
					   axs[2], fixedPos));
         }
      } else {
	if (ndim == 2) {
	  itsDisplayData = (DisplayData *)
	    (new LatticeAsMarker<Float>(itsFloatImage, 0, 1));
         } else {
	   itsDisplayData = (DisplayData *)
	       (new LatticeAsMarker<Float>(itsFloatImage, axs[0], axs[1],
	       				   axs[2], fixedPos));
         }
      }
    } else {
      throw(AipsError("Unknown displaydata type"));
    }    

    if (itsFloatImage  || itsComplexImage) {
      ImageInfo info;
      if (itsFloatImage) {
	info = itsFloatImage->imageInfo();
      } else if (itsComplexImage){
	info = itsComplexImage->imageInfo();
      }
      String error;
      if (!info.toRecord(error, itsImageInfo)) {
	throw(AipsError("Failed to convert ImageInfo to a record"));
      }
    }
    if (itsFloatImage) {
      delete itsFloatImage;
      itsFloatImage = 0;
    }
    if (itsComplexImage) {
      delete itsComplexImage;
      itsComplexImage = 0;
    }    
    commonCtor();
    return;
    
  } else if (!strcmp(datatype.chars(), "table")) {
    if (strcmp(itsType.chars(), "skycatalog")==0) {
      // skycatalog drawtype
      itsDisplayData = new SkyCatOverlayDD(filename);
      if (!itsDisplayData) {
	throw(AipsError("Couldn't create displaydata"));
      }
      commonCtor();
      return;
    } else {

      // generic Table

      if (strcmp(drawtype.chars(), "raster")==0) {
        itsDisplayData = new TblAsRasterDD(filename);
      } else if (strcmp(drawtype.chars(),"plot")==0) {
        itsDisplayData = new TblAsXYDD(filename);
      } else if (strcmp(drawtype.chars(),"contour")==0) {
        itsDisplayData = new TblAsContourDD(filename);
      }
      if (itsDisplayData==0)
        throw(AipsError("Couldn't create displaydata"));
  
      commonCtor();
      return;
    }
  } else if (datatype=="ms") {
    if (drawtype=="raster") {
      itsDisplayData = new MSAsRaster(filename);
    }
    if (itsDisplayData==0)
      throw(AipsError("Couldn't create ms displaydata with drawtype "
                      + drawtype));
    commonCtor();
    return;
  }
}

GTkDisplayData::GTkDisplayData(ProxyStore *s, String type, 
			       Array<Float> array) :
  GTkDisplayProxy(s, 0),
  itsFloatImage(0),
  itsComplexImage(0),
  itsFloatArray(0),
  itsComplexArray(0),
  itsType(type),
  itsPixelType(TpFloat),
  itsIsValid(0) {

  // suppress AIPS++ library LogSink messages
  installNullLogSink();

  uInt ndim = array.ndim();
  if (ndim < 2) {
    throw(AipsError("Array has less then two dimensions"));
  }

  itsFloatArray = new Array<Float>(array.copy());
  if (!itsFloatArray) {
    throw(AipsError("Failed to copy the given array"));
  }
  
  
  IPosition shape;
  shape = itsFloatArray->shape();
  
  Block<uInt> axs(ndim);
  getInitialAxes(axs, shape);
  
  IPosition fixedPos(ndim);
  fixedPos = 0;
  
  if (strcmp(itsType.chars(), "raster")==0) {
    if (ndim == 2) {
      itsDisplayData = 
	(new LatticeAsRaster<Float>(itsFloatArray, 0, 1));
    } else {
      itsDisplayData = 
	(new LatticeAsRaster<Float>(itsFloatArray, axs[0], axs[1], axs[2],
				    fixedPos));
    }
  } else if (strcmp(itsType.chars(), "contour")==0) {
    if (ndim == 2) {
      itsDisplayData = 
	(new LatticeAsContour<Float>(itsFloatArray, 0, 1));
    } else {
      itsDisplayData = 
	(new LatticeAsContour<Float>(itsFloatArray, axs[0], axs[1], axs[2],
				     fixedPos));
    }
  } else if (strcmp(itsType.chars(), "vector")==0) {
    if (ndim == 2) {
      itsDisplayData = 
	(new LatticeAsVector<Float>(itsFloatArray, 0, 1));
    } else {
      itsDisplayData = 
	(new LatticeAsVector<Float>(itsFloatArray, axs[0], axs[1], axs[2],
				    fixedPos));
    }
  } else if (strcmp(itsType.chars(), "marker")==0) {
    if (ndim == 2) {
      itsDisplayData = 
	(new LatticeAsMarker<Float>(itsFloatArray, 0, 1));
    } else {
      itsDisplayData = 
	(new LatticeAsMarker<Float>(itsFloatArray, axs[0], axs[1], axs[2],
				    fixedPos));
    }
  } else {
    throw(AipsError("Unknown displaydata type"));
  }

  commonCtor();
}

GTkDisplayData::GTkDisplayData(ProxyStore *s, String type, 
			       Array<Complex> array) :
  GTkDisplayProxy(s, 0),
  itsFloatImage(0),
  itsComplexImage(0),
  itsFloatArray(0),
  itsComplexArray(0),
  itsType(type),
  itsPixelType(TpComplex),
  itsIsValid(0) {

  // suppress AIPS++ library LogSink messages
  installNullLogSink();

  uInt ndim = array.ndim();
  if (ndim < 2) {
    throw(AipsError("Array has less than two dimensions"));
  }

  itsComplexArray = new Array<Complex>(array.copy());
  if (!itsComplexArray) {
    throw(AipsError("Failed to copy the given array"));
  }
  
  
  IPosition shape;
  shape = itsComplexArray->shape();
  
  Block<uInt> axs(ndim);
  getInitialAxes(axs, shape);
  
  IPosition fixedPos(ndim);
  fixedPos = 0;
  
  if (strcmp(itsType.chars(), "raster")==0) {
    if (ndim == 2) {
      itsDisplayData = new LatticeAsRaster<Complex>(itsComplexArray, 0, 1);
    } else {
      itsDisplayData = new LatticeAsRaster<Complex>(itsComplexArray, 
						    axs[0], axs[1], axs[2],
						    fixedPos);
    }
  } else if (!strcmp(itsType.chars(), "contour")) {
    if (ndim == 2) {
      itsDisplayData = new LatticeAsContour<Complex>(itsComplexArray, 0, 1);
    } else {
      itsDisplayData = new LatticeAsContour<Complex>(itsComplexArray, 
						     axs[0], axs[1], axs[2],
						     fixedPos);
    }
  } else if (!strcmp(itsType.chars(), "vector")) {
    if (ndim == 2) {
      itsDisplayData = new LatticeAsVector<Complex>(itsComplexArray, 0, 1);
    } else {
      itsDisplayData = new LatticeAsVector<Complex>(itsComplexArray, 
						    axs[0], axs[1], axs[2],
						    fixedPos);
    }
  } else {
    throw(AipsError("Unknown displaydata type"));
  }

  commonCtor();
}

void GTkDisplayData::commonCtor() {
  // fill in important details
  agent_ID = "<non-graphic:displaydata>";
  // insert procedures to deal with displaydata events:
  procs.Insert("setoptions",
	       new TkDisplayProc(this, &GTkDisplayData::setoptions));
  procs.Insert("getoptions",
	       new TkDisplayProc(this, &GTkDisplayData::getoptions));
  procs.Insert("setcolormap",
	       new TkDisplayProc(this, &GTkDisplayData::setcolormap));
  procs.Insert("removecolormap",
	       new TkDisplayProc(this, &GTkDisplayData::removecolormap));
  procs.Insert("classtype",
	       new TkDisplayProc(this, &GTkDisplayData::classtype));
  procs.Insert("dataunit",
	       new TkDisplayProc(this, &GTkDisplayData::dataunit));
  procs.Insert("pixeltype",
	       new TkDisplayProc(this, &GTkDisplayData::pixeltype));
  procs.Insert("zlength",
	       new TkDisplayProc(this, &GTkDisplayData::zlength));
  procs.Insert("getinfo",
	       new TkDisplayProc(this, &GTkDisplayData::getinfo));
  // Profile2dDD only
  procs.Insert("attach",
	       new TkDisplayProc(this, &GTkDisplayData::attach));
  procs.Insert("detach",
	       new TkDisplayProc(this, &GTkDisplayData::detach));
  procs.Insert("getdata",
	       new TkDisplayProc(this, &GTkDisplayData::getdata));
  // for PKSMultiBeamDD:
  procs.Insert("update",
               new TkDisplayProc(this, &GTkDisplayData::update));

  itsIsValid = 1;

  itsPositionEH = 0;
  itsMotionEH = 0;
  itsTrackingState = False;
  itsTrackingPosition = itsTrackingValue = "";
  if ((itsDisplayData->classType() != Display::Annotation)  &&
      (itsDisplayData->classType() != Display::CanvasAnnotation)) {
    itsTrackingState = True;
    itsPositionEH = new GDDPosEH(this);
    itsMotionEH = new GDDMotEH(this);
    itsDisplayData->addPositionEventHandler(itsPositionEH);
    itsDisplayData->addMotionEventHandler(itsMotionEH);
  }
}

extern "C" void GTkDisplayData_Create(ProxyStore *global_store, Value *args) {
  try {
    // a handle for the agent we will build
    GTkDisplayData *ret = 0;

    // check for number of arguments
    if (args->Length() != 3) {
      global_store->Error("too few arguments to displaydata agent");
      return;
    }

    // fetch arguments
    if (args->Type() != TYPE_RECORD) {
      global_store->Error("bad argument type to displaydata agent");
      return;
    }
    GlishRecord rec(args);
    GlishArray tmp(rec.get(0));
    String type;
    tmp.get(type);
    tmp = rec.get(1);
    switch(tmp.elementType()) {
    case GlishArray::STRING: {
      // we have a disk file name... (or "null" if type == "axes")
      String image;
      tmp.get(image);
      String dtype;
      tmp = rec.get(2);
      tmp.get(dtype);
      ret = new GTkDisplayData(global_store, type, image, dtype);
      break;
    }
    case GlishArray::FLOAT: {
      // we have a float array...
      Array<Float> array;
      tmp.get(array);
      ret = new GTkDisplayData(global_store, type, array);
      break;
    }
    case GlishArray::COMPLEX: {
      Array<Complex> array;
      tmp.get(array);
      ret = new GTkDisplayData(global_store, type, array);
      break;
    }
    default:
      global_store->Error("bad data given to displaydata agent");
      return;
    }
    
    if (!ret || !ret->IsValid()) {
      Value *err = ret ? ret->GetError() : 0;
      if (err) {
	global_store->Error(err);
      } else {
	global_store->Error("displaydata agent creation failed for "
			    "unknown reason(s)");
      }
    } else {
      ret->SendCtor("newtk");
    }
  } catch (const AipsError &x) {
    String message =
      String("GTkDisplayData agent creation failed; ") + x.getMesg();
    global_store->Error(message.chars());
  } 
}

GTkDisplayData::~GTkDisplayData() {
  if (itsMotionEH) {
    itsDisplayData->removeMotionEventHandler(*itsMotionEH);
    delete itsMotionEH;
  }
  if (itsPositionEH) {
    itsDisplayData->removePositionEventHandler(*itsPositionEH);
    delete itsPositionEH;
  }
  if (itsDisplayData) {
    delete itsDisplayData;
  }
  if (itsComplexArray) {
    delete itsComplexArray;
  }
  if (itsFloatArray) {
    delete itsFloatArray;
  } 
  if (itsFloatImage) {
    delete itsFloatImage;
  }
  if (itsComplexImage) {
    delete itsComplexImage;
  }
}

int GTkDisplayData::IsValid() const {
  return itsIsValid;
}

char *GTkDisplayData::getoptions(Value *) {
  static LogOrigin origin("GTkDisplayData", "getoptions");
  try {
    Record rec = itsDisplayData->getOptions();

    if ((itsDisplayData->classType() != Display::Annotation)  &&
	(itsDisplayData->classType() != Display::CanvasAnnotation)  &&
	(dynamic_cast<MSAsRaster*>(itsDisplayData) == 0) ) {
      // add in position tracking switch
      Record trackswitch;
      trackswitch.define("context", "Position_tracking");
      trackswitch.define("dlformat", "trackswitch");
      trackswitch.define("listname", "Position tracking?");
      trackswitch.define("ptype", "boolean");
      trackswitch.define("default", True);
      trackswitch.define("value", itsTrackingState);
      trackswitch.define("allowunset", False);
      trackswitch.define("autoapply", True);
      rec.defineRecord("trackswitch", trackswitch);
    }
//
    GlishRecord grec;
    grec.fromRecord(rec);
    Value *retval = new Value(*(grec.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("options", retval);
    }
    Unref(retval);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkDisplayData::setoptions(Value *args) {
  static LogOrigin origin("GTkDisplayData", "setoptions");
  try {
    GlishValue val(args);
    if (val.type() != GlishValue::RECORD) {
      throw(AipsError("argument to setoptions not a record"));
    }
    GlishRecord grec(args);
    Record rec, recOut;
    grec.toRecord(rec);
    if (itsDisplayData->setOptions(rec, recOut)) {
      itsDisplayData->refresh(True);
    }

    // parse position tracking switch
    casa::Bool error;
    readOptionRecord(itsTrackingState, error, rec, "trackswitch");

    if (recOut.nfields() > 0) {
      grec.fromRecord(recOut);
      Value *retval = new Value(*(grec.value()));
      if (ReplyPending()) {
	Reply(retval);
      } //else {
      PostTkEvent("contextoptions", retval);
      //}
      Unref(retval);
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkDisplayData::setcolormap(Value *args) {
  static LogOrigin origin("GTkDisplayData", "setcolormap");
  try {
    // check for correct number of arguments
    Int nargs = args->Length();
    if ((nargs < 1) || (nargs > 2)) {
      postError(origin, "Arguments to \"displaydata->setcolormap\" were not "
		"a colormap agent with an optional weight", LogMessage::WARN);
      return "";
    }    
    // load the arguments
    recordptr rptr = args->RecordPtr(0);
    int c = 0;
    const char *key;
    Value *colormap = rptr->NthEntry(c++, key);
    if (!colormap->IsAgentRecord()) {
      postError(origin, "First argument to \"displaydata->setcolormap\" "
		"was not a valid colormap agent", LogMessage::WARN);
      return "";
    }
    Float weight = 1.0;
    if (nargs == 2) {
      weight = rptr->NthEntry(c++, key)->FloatVal();
      if (weight <= 0.0) {
	postError(origin, "Optional second argument to "
		  "\"displaydata->setcolormap\" was an invalid weight",
		  LogMessage::WARN);
	return "";
      }
    }
    // get the agent from proxystore and use it
    TkProxy *agent = static_cast<TkProxy *>(global_store->GetProxy(colormap));
    if (agent && !strcmp(agent->AgentID(), "<non-graphic:colormap>")) {
      Colormap *cmap = (static_cast<GTkColormap*>(agent))->colormap();
      itsDisplayData->setColormap(cmap, weight);
      itsDisplayData->refresh(True);
		// User changing colormap: refresh.  This also cleans up
		// old drawlists in PADDs: they shouldn't be reused;
		// they have no record of their colormap.
    } else {
      postError(origin, "First argument to \"displaydata->setcolormap\" "
		"was not a colormap agent", LogMessage::WARN);
      return "";
    }    
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkDisplayData::removecolormap(Value *) {
  static LogOrigin origin("GTkDisplayData", "removecolormap");
  try {
    itsDisplayData->removeColormap();
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkDisplayData::zlength(Value *) {
  static LogOrigin origin("GTkDisplayData", "zlength");
  try {
    Int length = Int(itsDisplayData->nelements());
    GlishArray outarr(length);
    Value *retval = new Value(*(outarr.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("zlength", retval);
    }
    Unref(retval);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";

}

char *GTkDisplayData::classtype(Value *) {
  static LogOrigin origin("GTkDisplayData", "classtype");
  try {
    Int classtype = Int(itsDisplayData->classType());
    GlishArray outarr(classtype);
    Value *retval = new Value(*(outarr.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("classtype", retval);
    }
    Unref(retval);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkDisplayData::dataunit(Value *) {
  static LogOrigin origin("GTkDisplayData", "dataunit");
  try {
    String dunit = itsDisplayData->dataUnit().getName();
    GlishArray outarr(dunit);
    Value *retval = new Value(*(outarr.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("dataunit", retval);
    }
    Unref(retval);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkDisplayData::pixeltype(Value *) {
  static LogOrigin origin("GTkDisplayData", "pixeltype");
  try {
    ostringstream oss;
    oss << itsPixelType;
    String ptype(oss);
    GlishArray outarr(downcase(ptype));
    Value *retval = new Value(*(outarr.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("pixeltype", retval);
    }
    Unref(retval);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}
char *GTkDisplayData::getinfo(Value *) {
  static LogOrigin origin("GTkDisplayData", "getinfo");
  try {
    GlishRecord grec;
    if (itsImageInfo.isDefined("restoringbeam")) {
      grec.fromRecord(itsImageInfo);
    }
    Value *retval = new Value(*(grec.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("getinfo", retval);
    }
    Unref(retval);
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

char *GTkDisplayData::attach(Value* args) {
  static LogOrigin origin("GTkDisplayData", "attach");
  installGTkLogSink();
  Profile2dDD *tmp = dynamic_cast<Profile2dDD*>(itsDisplayData);
  if (!tmp) {
    postError(origin, "This displaydata agent does not support "
	      "the \"displaydata->attach\" method", LogMessage::WARN);  
  }  
  try {
    if (args->Type() != TYPE_RECORD) {
      postError(origin, "Argument to \"displaydata->attach\" was not "
		"a record", LogMessage::WARN);
      installNullLogSink();
      return "";
    }
    GlishValue val(args);
    GlishRecord rec = val;
    GlishRecord nrec;
    nrec.add(rec.name(0), rec.get(0));
    TkProxy* agent = static_cast<TkProxy*>(global_store->
					   GetProxy(rec.value()));
    
    // check it is a non-graphic:displaydata
    if (agent && !strcmp(agent->AgentID(), "<non-graphic:displaydata>")) {
      LatticePADisplayData<Float>* dd = 
	dynamic_cast<LatticePADisplayData<Float>*>(static_cast<GTkDisplayData*>(agent)->displayData());
      if (!dd) {
	postError(origin, "Argument to \"displaydata->attach\" does not "
		  "contain data which can be profiled", LogMessage::WARN);
      }
      if (!tmp->attachDD(dd)) {
	postError(origin, "Couldn't attach the given displaydata agent.",
		  LogMessage::WARN);
      } 
    } else {
      postError(origin, "Argument to \"displaydata->attach\" was not "
		"a displaydata agent", LogMessage::WARN);
      installNullLogSink();
      return "";
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";

}

char *GTkDisplayData::detach(Value*) {
  static LogOrigin origin("GTkDisplayData", "detach");
  installGTkLogSink();
  try {
    Profile2dDD *tmp = dynamic_cast<Profile2dDD*>(itsDisplayData);
    if (!tmp) {
      postError(origin, "This displaydata agent does not support "
		"the \"displaydata->detach\" method", LogMessage::WARN);  
    }  
    tmp->detachDD();
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  replyIfPending();
  installNullLogSink();
  return "";
}

char *GTkDisplayData::getdata(Value*) {
  static LogOrigin origin("GTkDisplayData", "getdata");
  installGTkLogSink();
  try {
    Profile2dDD *tmp = dynamic_cast<Profile2dDD*>(itsDisplayData);
    if (!tmp) {
      postError(origin, "This displaydata agent does not support "
		"the \"displaydata->getdata\" method", LogMessage::WARN);  
    }

    Record rec;
    tmp->getProfileAsRecord(rec);
    GlishRecord grec;
    grec.fromRecord(rec);
    Value *retval = new Value(*(grec.value()));
    if (ReplyPending()) {
      Reply(retval);
    } else {
      PostTkEvent("getdata", retval);
    }
  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  installNullLogSink();
  return "";
}

char *GTkDisplayData::update(Value* args) {
  static LogOrigin origin("GTkDisplayData", "update");
  if (dynamic_cast<PKSMultiBeamDD* >(itsDisplayData) == 0) {
  //if (dynamic_cast<ScrollingRasterDD* >(itsDisplayData) == 0) {
    return "";
  }
  try {
    GlishValue val(args);
    if (val.type() != GlishValue::RECORD) {
      throw(AipsError("argument to update not a record"));
    }
    GlishRecord grec(args);
    Record rec, recOut;
    grec.toRecord(rec);
    (dynamic_cast<PKSMultiBeamDD *>(itsDisplayData))->updateLattice(rec);
    itsDisplayData->refresh(True);
    if (!ReplyPending()) {
      Value *retval = new Value(True);
      PostTkEvent("imageID", retval);
      delete retval;
    }

  } catch (const AipsError &x) {
    postError(origin, x);
  } 
  return "";
}

void GTkDisplayData::operator()(const WCPositionEvent &ev) {
  static LogOrigin origin("GTkDisplayData", "operator(WCPositionEvent &)");
  try {
    if (ev.keystate()) {
      // "Space" bar toggles tracking
      if (ev.key() == Display::K_space) {
	itsTrackingState = (!itsTrackingState);

	// emit current tracking state
	Record rec;
	Record trackswitch;
	trackswitch.define("dlformat", "trackswitch");
	trackswitch.define("listname", "Position tracking?");
	trackswitch.define("ptype", "boolean");
	trackswitch.define("default", True);
	trackswitch.define("value", itsTrackingState);
	trackswitch.define("allowunset", False);
	trackswitch.define("autoapply", True);
	rec.defineRecord("trackswitch", trackswitch);
	GlishRecord grec;
	grec.fromRecord(rec);
	Value *retval = new Value(*(grec.value()));
	if (ReplyPending()) {
	  Reply(retval);
	} else {
	  PostTkEvent("localoptions", retval);
	}
	Unref(retval);
	if (itsTrackingState) {
	  postError(origin,
	  	    String("Position tracking turned on (displaydata)"));
	} else {
	  postError(origin,
	  	    String("Position tracking turned off (displaydata)"));
	}
      }

      else if (ev.key()==Display::K_l || ev.key()==Display::K_L) {

	// "L" key pressed: log the last information that was sent to
	// the tracking display.

	String withoutWhiteSpace = itsTrackingValue + itsTrackingPosition;
	withoutWhiteSpace.gsub(" ","");
	withoutWhiteSpace.gsub("\n","");
	if(withoutWhiteSpace=="") return;	// (don't log if no info).

	String logInfo = "\n" + itsTrackingValue;
		// Add initial blank line for log legibility.
	if(itsTrackingValue!="" && itsTrackingPosition!="" &&
	   itsTrackingPosition.firstchar()!='\n') logInfo += "\n";
		// Show the value on a separate line.
	logInfo += itsTrackingPosition;

        postError(origin, logInfo);
		// (This is not really an error, and is not logged as such;
		// normal logging calls are disabled in the DL at present).
      }

    }
  } catch (const AipsError &x) {
    postError(origin, x);
  }
}

void GTkDisplayData::operator()(const WCMotionEvent &ev) 
{
  static LogOrigin origin("GTkDisplayData", "operator(WCMotionEvent &ev)");
  try {

    // Don't track motion off draw area (must explicitly test this now).
    if (!ev.worldCanvas()->inDrawArea(ev.pixX(),ev.pixY()) ) {
      return;
    }

    if (!itsTrackingState || (itsType == "wedge")) return;

    GlishRecord rec;

    
    //#dk This rev. attempts to remove assumptions (or cases) regarding
    //    the size of (WC) pointers when passing them to glish.
    //    (64-bit bugfix).
    
    ostringstream os;   os << setprecision(68); 
    os << (void*)(ev.worldCanvas());	// (The WC pointer as formatted hex).
    rec.add("worldcanvasid", GlishArray(String(os)));
        

/*  //#dk  -- the old code
    
#ifdef AIPS_64B
    Int *tmp1;
    Long tmp2 = (Long)ev.worldCanvas();
    tmp1 = (Int *)&tmp2;
    rec.add("worldcanvasid", tmp1);
#else
    rec.add("worldcanvasid", Int(ev.worldCanvas()));
#endif

*/  //#dk


    itsDisplayData->conformsTo(ev.worldCanvas());
	// 'focus' DD on WC[H] of interest (including its zIndex).
	// If DD does not apply to the WC, we need to call showPosition()
	// and showValue() below anyway; the DD will then return the
	// appropriate number of blank lines to the glish tracking boxes.

    Vector<Double> world = ev.world();
    rec.add("world", GlishArray(world));
    Vector<Int> pixel(2);
    Vector<Int> linear(2);
    pixel(0) = ev.pixX();
    pixel(1) = ev.pixY();
    linear(0) = Int(ev.linX()+0.5);
    linear(1) = Int(ev.linY()+0.5);

    rec.add("pixel", GlishArray(pixel));
    rec.add("linear", GlishArray(linear));
    itsTrackingPosition = itsDisplayData->showPosition(world);
    itsTrackingValue = itsDisplayData->showValue(world);
    rec.add("formattedworld", itsTrackingPosition);
    rec.add("formattedvalue", itsTrackingValue);

    Value *retval = new Value(*(rec.value()));
    if (ReplyPending())  Reply(retval);
    else                 PostTkEvent("motion", retval);
    Unref(retval);

  } catch (const AipsError &x) {
    postError(origin, x);
  }
}

// handle DisplayDataEvents
void GTkDisplayData::handleEvent(DisplayEvent& ev) {
  static LogOrigin origin("GTkDisplayData", "handleEvent(DisplayEvent &ev)");
  DDModEvent* dev = dynamic_cast<DDModEvent*>(&ev);
  if (dev) {
    // test for Profile2dDD 
    Profile2dDD *pdd = dynamic_cast<Profile2dDD*>(dev->displayData());
    if (pdd) {
      Int* i=0;
      Value* val = new Value(i, 0); // any dummy value
      PostTkEvent("newdata", val);
      Unref(val);
    }    
    // test for other DDs...
  }
}


void GTkDisplayData::getInitialAxes(Block<uInt>& axs, const IPosition& shape,
				    const CoordinateSystem* cs) {
  // Heuristic used internally to set initial axes to display on X, Y and Z,
  // for PADDs.  shape should be that of Image/Array, and have same nelements
  // as axs.  On return, axs[0], axs[1] and (if it exists) axs[2] will be axes
  // to display initially on X, Y, and animator, respectively.
  // If you pass a CS for the image, it will give special consideration to
  // Spectral axes (users expect their Image spectral axes to be on Z).
    
  // This kludge was designed to prevent large-size axes
  // from being placed on the animator (axs[2]) while small-sized axes
  // are displayed (axs[0], axs[1]) (at least initially).  It was
  // originally a temporary bandaid to keep single-dish data from
  // clogging up the animator with many channels, in msplot.  (see
  // http://aips2.nrao.edu/mail/aips2-visualization/229).
  
  uInt ndim = axs.nelements();
  for(uInt i = 0; i<ndim; i++) axs[i] = i;
  
  if(ndim<=2) return;
  
  
  Int spaxis = -1;	// axis number of a non-degenerate
			// spectral axis (-1 if none).
  if(cs!=0) {
    
    // First, assure that a non-degenerate Spectral axis is
    // at least on the animator (if not on display).  (Added 8/06)
    
    for(uInt axno=0; axno<ndim && axno<cs->nWorldAxes(); axno++) {
      
      Int coordno, axisincoord;
      cs->findWorldAxis(coordno, axisincoord, axno);
	// (It would be convenient if more methods in CS were in
	//  terms of 'axno' rather than 'coordno', so these two
	//  lines didn't constantly have to be repeated...).

      if( cs->showType(coordno)=="Spectral" && shape(axs[axno])>1 ) {
	spaxis = axno;
	if(spaxis>2) { axs[spaxis]=2; axs[2]=spaxis;  }
				// Swap spectral axis onto animator.
	break;  }  }  }
    
    
  
  for(uInt i=0; i<3; i++) if(shape(axs[i])<=4 && axs[i]!=uInt(spaxis)) {
      
    for (uInt j=2; j<ndim; j++)  {
      if (shape(axs[j]) > 4) {
	uInt tmp = axs[i]; 
	axs[i] = axs[j]; 
	axs[j] = tmp;		// swap small axes for large.
	break;  }  }
	   
    // This part was added (7/05) to prevent degenrerate Stokes axes
    // from displacing small Frequency axes on the animator.
    // (See defect 5148   dk).

    if (shape(axs[i]) == 1) {
      for (uInt j=2; j<ndim; j++)  {
	if (shape(axs[j]) > 1) {
	  uInt tmp = axs[i]; 
	  axs[i] = axs[j]; 
	  axs[j] = tmp; 
		// swap degenerate axis for (any) non-degenerate axis.
	  break;  }  }  }  }
}
  


}
