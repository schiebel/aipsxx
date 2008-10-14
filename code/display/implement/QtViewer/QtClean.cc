//# QtClean.cc:  Prototype QObject for interactive clean.
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
//# $Id: QtClean.cc,v 1.1 2006/08/11 22:18:39 dking Exp $

#include <casa/iostream.h>

#include <display/QtViewer/QtClean.qo.h>

#include <display/QtViewer/QtViewer.qo.h>
#include <display/QtViewer/QtDisplayPanelGui.qo.h>
#include <display/QtViewer/QtDisplayData.qo.h>



namespace casa {



QtClean::QtClean(String imgname) :
 
	 QObject(), QtApp(),
	 imgname_(), boxes_(), 
	 v_(0), dpg_(0), dp_(0), imagedd_(0), maskdd_(0)  {

  v_   = new QtViewer;
  dpg_ = new QtDisplayPanelGui(v_);
  dp_  = dpg_->displayPanel();
  
  connect( dp_, SIGNAL(rectangleRegionReady(Record)),  
                  SLOT(newRectangle_(Record)) );
	// Receives rectangle regions from the mouse tool.
  
  loadImage(imgname);  }
  
  
  
QtClean::~QtClean() { 
  v_->removeAllDDs();
  //delete dpg_;	// leads to crash on exit (why?)
  			// ***THIS IS IMPORTANT TO UNDERSTAND AND FIX***...
  delete v_; 
  QtApp::destroy();	// (Is this a good idea?...)
}
  

  
Bool QtClean::loadImage(String imgname) {
  // Loads image with pathname imgname for display and clean box
  // selection (reloads even if pathname is the same as previously).
  // Returns True if it was able to find and display the image.

  // delete old dd and old clean boxes, if any.
  clearImage();
  
  if(imgname!="") {
  
    imagedd_ = v_->createDD(imgname, "image", "raster");
    
    if(imageLoaded()) {
      Record opts;
      opts.define("axislabelswitch", True);
      imagedd_->setOptions(opts);  }

    else  cerr<<endl<<v_->errMsg()<<endl<<endl;  }

  if(imageLoaded()) imgname_ = imgname;
  	// (Not sure we even need imgname_...).
  
  return imageLoaded();  }  


  
  
void QtClean::clearImage() {
  // delete old dd[s] and clean boxes, if any.
  v_->removeAllDDs(); 
  imagedd_=0;
  imgname_="";
  clearCleanBoxes();  }


    
  
Int QtClean::go() {
  // Start viewer's display event loop; returns when viewer window
  // is closed.  Return type is an example format for the clean boxes
  // selected / accumulated while the window was open.
 
  dpg_->show();
  if(!imageLoaded()) v_->showDataManager();	// (Browse for file).
  
  return QtApp::exec();  }  
 

  
  
void QtClean::newRectangle_(Record rectRegion) {
  // Slot connected to the rectangle region mouse tool's new rectangle signal.
  // Accumulates [/ displays] selected boxes.
  
  // See QtMouseTools.cc for the current format of rectRegion.
  // It is pretty much the same as the glish one at present, but
  // is not set in stone yet, and could be altered if desired.

  Record coords = rectRegion.asRecord("world");   // or "linear", "pixel"...
  Vector<Double> blc = coords.asArrayDouble("blc");
  Vector<Double> trc = coords.asArrayDouble("trc");
  Int zindex = rectRegion.asInt("zindex");
  Vector<String> units = rectRegion.asArrayString("units");
  
  ostringstream os;
  cout<<"new mouse rect: "<<flush;
  os<<"blc: "<<blc<<"  trc: "<<trc<<"  z: "
    <<zindex  /* <<"  units: "<<units */  ;
  String rect(os);
  cout<<rect<<endl;
  
  
  // Add new rectangle to set of clean boxes (example).
  
  // ***should re-create mask image/dd and display it here too,
  //    for feedback.***
  
  boxes_.resize(boxes_.nelements()+1, True);
  boxes_[boxes_.nelements()-1] = rect;


  dpg_->displayPanel()->resetRTRegion();
	// Clears mouse tool drawing.  (Maskdd should show accumulated
	// boxes instead).
  
}



} //# NAMESPACE CASA - END



