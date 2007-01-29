//# QtDisplayPanel.cc: Qt DisplayData wrapper.
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
//# $Id: QtDisplayData.cc,v 1.10 2006/10/13 23:56:03 dking Exp $

#include <display/QtViewer/QtDisplayData.qo.h>
#include <display/DisplayDatas/DisplayData.h>
#include <display/DisplayDatas/MSAsRaster.h>
#include <images/Images/ImageInterface.h>
#include <display/DisplayDatas/LatticeAsRaster.h>
#include <display/DisplayDatas/LatticeAsContour.h>
#include <display/DisplayDatas/LatticeAsVector.h>
#include <display/DisplayDatas/LatticeAsMarker.h>
#include <display/DisplayDatas/SkyCatOverlayDD.h>
#include <casa/OS/Path.h>
#include <images/Images/PagedImage.h>
#include <images/Images/FITSImage.h>
#include <images/Images/MIRIADImage.h>
#include <images/Images/ImageUtilities.h>
#include <images/Images/ImageOpener.h>
#include <images/Images/ImageInfo.h>
#include <display/Display/WorldCanvas.h>
#include <display/DisplayEvents/WCMotionEvent.h>

#include <display/QtAutoGui/QtXmlRecord.h>


#include <casa/Exceptions/Error.h>


namespace casa { //# NAMESPACE CASA - BEGIN


  QtDisplayData::QtDisplayData(String path, String dataType,
			       String displayType) : 
    path_(path),
    dataType_(dataType),
    displayType_(displayType),
    im_(0),
    dd_(0) {

    name_ = Path(path_).baseName();
    //cout << "create DisplayData " <<  name_ 
    //	 << " dataType=" << dataType_ 
    //	 << " displayType=" << displayType_ 
    //   << endl;

    if(displayType!="raster") name_ += "-"+displayType_;
    // Default; can be changed with setName()
    // (and should, if it duplicates another name).
  
    errMsg_ = "Failed to create DisplayData "+name_+" ("+dataType_+")";
  
    try {
    
      if (displayType.compare("skycatalog")==0) {
	  // skycatalog drawtype
	  dd_ = new SkyCatOverlayDD(path);
	  if (!dd_) {
	      throw(AipsError("Couldn't create displaydata"));
	  }
	  return;
      }
  
      if(dataType_=="image") {
	ImageOpener::ImageTypes iType =
	  ImageOpener::imageType(path);
	if (iType==ImageOpener::FITS) {

	    // open the FITS image. Only Float supported.
	    //itsPixelType = TpFloat;
	    //cout << "create FITS image>>>>" << endl;
	    im_ = new FITSImage(path);
	    //cout << "create FITS image<<<<" << endl;
	    //cout << "imageName=" << im_->imageType() << endl;
	    //cout << "isPaged=" << im_->isPaged() << endl;
	    //cout << "name=" << im_->name() << endl;
	}
	else if (iType==ImageOpener::MIRIAD) {
	    // open the Miriad image. Only Float supported.
	    //itsPixelType = TpFloat;
	    im_ = new MIRIADImage(path);
	}
	else {
	    im_ = new PagedImage<Float>(path_);
	}
	if (!im_)
	  return;


	uInt ndim = im_->ndim();
	IPosition fixedPos(ndim);

	IPosition shape;
	shape = im_->shape();

	Block<uInt> axs(ndim);
	getInitialAxes(axs, shape);

	fixedPos = 0;

	if(displayType_=="raster" && ndim >= 2) {
	  //cout << "displayType=raster" << endl;
	  //cout << "create raster dd>>>>" << endl;
	  errMsg_ = "";
	  if(ndim == 2) {
	    try {
               dd_ = new LatticeAsRaster<Float>(im_, 0, 1);
            }
	    catch(...) {
               errMsg_ = "Failed to create raster display data (n=2)";
	    }
	  }
	  else {
	    try {
	       dd_ = new LatticeAsRaster<Float>(im_, axs[0], 
                    axs[1], axs[2], fixedPos);
	    }
	    catch (...) {
               errMsg_ = "Failed to create raster display data";
	    }
	  }
	  //cout << "create raster dd<<<<" << endl;
	}
	else if(displayType_=="contour" && ndim >= 2) {
	  //cout << "displayType=contour" << endl;
	  errMsg_ = "";
	  if(ndim == 2) {
            try {
	       dd_ = new LatticeAsContour<Float>(im_, 0, 1);
	    }
	    catch (...) {
               errMsg_ = "Failed to create contour display data (n=2)";
            }
          }
	  else {
            try {
	      dd_ = new LatticeAsContour<Float>(im_,
	            axs[0], axs[1], axs[2],  fixedPos);
	    //dd_ = new LatticeAsContour<Float>(im_, 0, 1, 2, fixedPos);
	    //#dk  (Anyone want to tell me why this  ^^^^^^^ bug was
	    //      gratuitously introduced?...).
	    }
	    catch (...) {
               errMsg_ = "Failed to create contour display data";
            }
          }
	}
        else if (displayType_=="vector" && ndim >= 2) {
	  //cout << "displayType=vector" << endl;
	  errMsg_ = "";
	  if (ndim == 2) {
            try {
	       dd_ = new LatticeAsVector<Float>(im_, 0, 1);
	    }
	    catch (...) {
               errMsg_ = "Failed to create vector display data (n=2)";
            }
          }
	  else {
            try {
	      dd_ = new LatticeAsVector<Float>(im_, axs[0], 
                       axs[1], axs[2], fixedPos);
	    }
	    catch (...) {
               errMsg_ = "Failed to create vector display data";
            }
          }
        }
        else if (displayType_=="marker" && ndim >= 2) {
          //cout << "displayType=marker" << endl;
	  errMsg_ = "";
	  if (ndim == 2) {
            try {
		dd_ = new LatticeAsMarker<Float>(im_, 0, 1);
	    }
	    catch (...) {
               errMsg_ = "Failed to create marker display data (n=2)";
            }
          }
	  else {
            try {
		dd_ = new LatticeAsMarker<Float>(im_, axs[0], 
                      axs[1], axs[2], fixedPos);
	    }
	    catch (...) {
               errMsg_ = "Failed to create marker display data";
            }
          }
        }
        im_->unlock();
    }       // Needed (for unknown reasons) to avoid
    // blocking other users of the image file....

    else if(dataType_=="ms") {
      
      if (displayType_=="raster") {
        
	dd_ = new MSAsRaster(path_);
	errMsg_ = "";  }  }  }
 
  
  catch (const AipsError& err) { errMsg_ += "\n  " + err.getMesg();  }
    
  if(errMsg_ != "") dd_=0;
  // (failure.. Is it best to try to delete the remains, or leave
  // them hanging?  Latter course chosen here...).
  else {
    delete im_;
    im_ = 0;
  }
  
  dd_->setUIBase(0);  
	// Items are numbered from zero in qtviewer (casapy) as consistently
	// as possible (including, e.g., axis 'pixel' positions).  This call
	// is necessary after constructing DDs, to orient them away from
	// their old default 1-based (glish) behavior.
  
  //#diag cout << "display data created" << endl;

}
QtDisplayData::~QtDisplayData() { 
  // cerr<<"~QDD:"<<this<<endl;		//#diag
  done();  }

void QtDisplayData::done() { 
  if(dd_==0) return;		// (already done).
  //emit dying(this);
  delete dd_;  dd_=0;
  if(im_!=0) { delete im_; im_=0;  }  }  

    
Record QtDisplayData::getOptions() {
  // retrieve the Record of options.  This is similar to a 'Parameter Set',
  // containing option types, default values, and meta-information,
  // suitable for building a user interface for controlling the DD.
  
  if(dd_==0) return Record();  //# (safety, in case construction failed.).
  return dd_->getOptions();  }

      

void QtDisplayData::setOptions(Record opts) {
  // Apply option values to the DisplayData.  Method will
  // emit optionsChanged() if other option values, limits, etc.
  // should also change as a result.
  //cerr<<"QDD-sOpt dd:"<<dd_<<endl;	//#diag

  if(dd_==0) return;  // (safety, in case construction failed.).
  
  Record chgdOpts;
  
  try { 
    if(dd_->setOptions(opts, chgdOpts)) dd_->refresh(True);
    // Refresh canvases where dd is registered, if required
    // because of option changes (it usually is).  
    // Note: the 'True' parameter to refresh(), above, is a 
    // sneaky/kludgy part of the refresh cycle interface which
    // is easily missed.  In practice what it means now is that
    // DDs on the PrincipalAxesDD branch get their drawlist
    // cache cleared.  It has no effect (on caching or otherwise)
    // for DDs on the CachingDD branch.
    
    errMsg_ = "";		// Just lets anyone interested know that
    emit optionsSet();  }	// options were set ok.  (QtDDGui will
				// use it to clear status line, e.g.).

  catch (const casa::AipsError& err) {
    errMsg_ = err.getMesg();
    //cerr<<"qddErr:"<<errMsg_<<endl;	//#diag
    emit qddError(errMsg_);  }
  catch (...) { 
    errMsg_ = "Unknown error setting data options";
    //cerr<<"qddErr:"<<errMsg_<<endl;	//#diag
    emit qddError(errMsg_);  }


  if(chgdOpts.nfields()!=0) emit optionsChanged(chgdOpts);
  // [Other, dependent] options the dd itself changed in
  // response.  Option guis will want to monitor this and
  // change their interface accordingly.
  //
  // The 'setanimator' sub-record of chgdOpts, if any, is not
  // an option of an individual dd, but a request to reset the
  // state of the animator (number of frames, current frame or
  // 'index').  
  // (To do: This code should probably not allow explicit
  // 'zlength' or 'zindex' fields to be specified within the
  // 'setanimator' sub-record unless the dd is CS master).

} 



void QtDisplayData::getInitialAxes_(Block<uInt>& axs, const IPosition& shape,
				    const CoordinateSystem* cs) {
  // Heuristic used internally to set initial axes to display on X, Y and Z,
  // for PADDs.  (Lifted bodily from GTkDD.  Should refactor down to DD
  //  level, rather than repeat the code.  GTk layer disappearing, though).
  //
  // shape should be that of Image/Array, and have same nelements
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
  // (Lifted bodily from GTkDD.  Shame on me--should refactor down to DD
  //  level, rather than repeat the code.  GTk layer disappearing though).
  
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
	  break;  }  }  }  }  }





String QtDisplayData::trackingInfo(const WCMotionEvent& ev) {
  // Returns a String with value and position information,
  // suitable for a cursor tracking display.
  
  if(dd_==0) return "";
  
  try {
    
    if(!ev.worldCanvas()->inDrawArea( ev.pixX(), ev.pixY() )) return "";
	// Don't track motion off draw area (must explicitly test this now
	// (best for caller to test before trying to use this routine).

    dd_->conformsTo(ev.worldCanvas());
	// 'focus' DD on WC[H] of interest (including its zIndex).
	// If DD does not apply to the WC, we need to call showPosition()
	// and showValue() below anyway; the DD will then return the
	// appropriate number of blank lines.

    
    return dd_->showValue(ev.world()) + "   "
         + dd_->showPosition(ev.world());  } 
  
  
  catch (const AipsError &x) { return "";  }  }

 

  
void QtDisplayData::getInitialAxes(Block<uInt>& axs, const IPosition& shape)
{

	//#dk  (Why was this (obsolete) version just thrown in here,
	// superceding the newer (more correct) version above, without
	// eliminating it, and without any explanation whatsoever??...).
	//
	// To do: get rid of this; find out if original version has problems
	// with, e.g. FITS images, and apply an _appropriate_ correction,
	// if any is really needed....

  uInt ndim = axs.nelements();
  for(uInt i = 0; i<ndim; i++)
    axs[i] = i;
  if(ndim<=2)
    return;
  for(uInt i=0; i<3; i++)
    if(shape(axs[i]) <= 4) {
      for (uInt j=2; j<ndim; j++) {
	if (shape(axs[j]) > 4) {
	  uInt tmp = axs[i];
	  axs[i] = axs[j];
	  axs[j] = tmp;
	  // swap small axes for large.        
	  break;  
	} 
      }
      if (shape(axs[i]) == 1) {
	for (uInt j=2; j<ndim; j++) {
	  if (shape(axs[j]) > 1) {
	    uInt tmp = axs[i];
	    axs[i] = axs[j];
	    axs[j] = tmp;
	    // swap degenerate axis for (any)non-degenerate axis.
	    break;
	  }
	}
      }
    }
}

  

} //# NAMESPACE CASA - END
