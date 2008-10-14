//# QtViewer.cc: Qt implementation of main viewer supervisory object
//#		 -- Gui level.
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
//# $Id: QtViewer.cc,v 1.5 2006/06/22 18:39:13 dking Exp $

#include <display/QtViewer/QtViewer.qo.h>
#include <display/QtViewer/QtDataManager.qo.h>
#include <display/QtViewer/QtDataOptionsPanel.qo.h>

extern int qInitResources_QtViewer();

namespace casa { //# NAMESPACE CASA - BEGIN


QtViewer::QtViewer() : QtViewerBase(), qdm_(0), qdo_(0) {
  qInitResources_QtViewer();
	// Makes QtViewer icons, etc. available via Qt resource system.
	//
	// You would normally use this macro for the purpose instead:  
	//
	//   Q_INIT_RESOURCE(QtViewer);
	//
	// It translates as:
	//
	//   extern int qInitResources_QtViewer();
	//   qInitResources_QtViewer();
	//
	// It doesn't work here because it makes the linker looks for
	//   casa::qInitResources_QtViewer()     :-)   dk

  
  //qdo_ = new QtDataOptionsPanel(this);
}


QtViewer::~QtViewer() {
  if(qdm_!=0) delete qdm_;
  if(qdo_!=0) delete qdo_;  }
  
  
  
void QtViewer::showDataManager() {
  if(qdm_==0) qdm_ = new QtDataManager(this);
  qdm_->showNormal();
  qdm_->raise();  }

void QtViewer::hideDataManager() {
  if(qdm_==0) return;
  qdm_->hide();  }

    
void QtViewer::showDataOptionsPanel() {
  if(qdo_==0) qdo_ = new QtDataOptionsPanel(this);
  if(qdo_!=0) {  // (should be True, barring exceptions above).
    qdo_->showNormal();
    qdo_->raise();  }  }

  
  


} //# NAMESPACE CASA - END
