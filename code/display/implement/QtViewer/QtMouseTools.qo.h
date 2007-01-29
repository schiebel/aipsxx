//# QtMouseTools.qo.h: Qt versions of display library mouse tools.
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
//# $Id: QtMouseTools.qo.h,v 1.1 2006/08/11 22:18:39 dking Exp $


#ifndef QTMOUSETOOLS_H
#define QTMOUSETOOL_H

#include <casa/aips.h>
#include <display/DisplayEvents/MWCRTRegion.h>
#include <display/Display/PanelDisplay.h>
#include <casa/Containers/Record.h>

#include <graphics/X11/X_enter.h>
#  include <QObject>
#include <graphics/X11/X_exit.h>

namespace casa {



// <synopsis>
// Nothing yet: it may prove useful for Qt-signal-emitting mouse tools
// (which are MWCTools or possibly PCTools) to have a common base.
// </synopsis>
class QtMouseTool: public QObject {

  Q_OBJECT	//# Allows slot/signal definition.  Must only occur in
		//# implement/.../*.h files; also, makefile must include
		//# name of this file in 'mocs' section.
  
 public: 
 
  QtMouseTool() : QObject() {  }
  ~QtMouseTool() {  }

}; 




// <synopsis>
// QtRTRegion is the Rectangle Region mouse tool that sends a signal
// when a new rectangle is ready.
// </synopsis>
class QtRTRegion: public QtMouseTool, public MWCRTRegion {
  
  Q_OBJECT	//# Allows slot/signal definition.  Must only occur in
		//# implement/.../*.h files; also, makefile must include
		//# name of this file in 'mocs' section.

 public: 
 
  QtRTRegion(PanelDisplay* pd) : QtMouseTool(), MWCRTRegion(), pd_(pd) {  }
  
  ~QtRTRegion() {  }
  
 signals:
 
  void rectangleRegionReady(Record rectRegion);

 protected:
  
  // Signals rectangleRegionReady with an appropriate Record, when
  // called by base class in response to user selection with the mouse.
  virtual void regionReady();
  
  PanelDisplay* pd_;	// (Kludge... zIndex inaccessible from WC...)

};




} //# NAMESPACE CASA - END

#endif

