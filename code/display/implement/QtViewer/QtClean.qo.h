//# QtClean.qo.h:  Prototype QObject for interactive clean.
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
//# $Id: QtClean.qo.h,v 1.1 2006/08/11 22:18:39 dking Exp $

#ifndef QTCLEAN_H
#define QTCLEAN_H

#include <casa/aips.h>
#include <casa/BasicSL/String.h>
#include <casa/Containers/Record.h>
#include <display/QtViewer/QtApp.h>
#include <casa/Arrays/Vector.h>


#include <graphics/X11/X_enter.h>
#  include <QObject>
#include <graphics/X11/X_exit.h>


namespace casa {

class QtViewer;
class QtDisplayPanelGui;
class QtDisplayPanel;
class QtDisplayData;


// <synopsis>
// Demo class to encapsulate 'serial' running of qtviewer into callable
// methods of a class; this example also applies it to the task of
// interactive selection of CLEAN boxes.
// </synopsis>
class QtClean: public QObject, public QtApp {

  Q_OBJECT	//# Allows slot/signal definition.  Must only occur in
		//# implement/.../*.h files; also, makefile must include
		//# name of this file in 'mocs' section.
  
 
 public: 
 
  QtClean(String imgname="");
  
  ~QtClean();
  
  // prototype: the CleanBoxes type will probably change
  typedef Vector<String> CleanBoxes;
 
  // returns True if it was able to find and display the image.
  virtual Bool loadImage(String imgname);
  
  virtual Bool imageLoaded() { return imagedd_!=0;  }
  
  // start viewer display; return when viewer windows are closed.
  // Return value indicates event loop (exec) return status..
  virtual Int go();
  
  virtual CleanBoxes cleanBoxes() { return boxes_;  }
  
 
 
 public slots: 
 
  // delete old dd (and clean boxes), if any.
  virtual void clearImage();

  // delete accumulated clean boxes, if any.
  virtual void clearCleanBoxes() { boxes_.resize(0);  }
  
  
 
 protected slots:
 
  // Connected to the rectangle region mouse tools new rectangle signal.
  // Accumulates [/ displays] selected boxes.
  virtual void newRectangle_(Record rectRegion);
  
 
 protected:
    
  String imgname_;
  CleanBoxes boxes_;	// accumulated clean boxes.
  
  QtViewer* v_;
  QtDisplayPanelGui* dpg_;
  QtDisplayPanel* dp_;
  QtDisplayData* imagedd_;
  
  QtDisplayData* maskdd_;	// later: to display clean region.
  

};


} //# NAMESPACE CASA - END

#endif


