//# QtViewerBase.qo.h: Qt implementation of main viewer supervisory object.
//#                 -- Functional level.
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
//# $Id: QtViewerBase.qo.h,v 1.3 2006/08/11 22:16:05 dking Exp $

#ifndef QTVIEWERBASE_H
#define QTVIEWERBASE_H

#include <casa/aips.h>
#include <casa/Containers/List.h>
#include <display/QtViewer/QtMouseToolState.qo.h>

#include <graphics/X11/X_enter.h>
#  include <QObject>
#include <graphics/X11/X_exit.h>


// <summary>
// Qt implementation of main viewer supervisory object -- Functional level.
// </summary>

// <synopsis>
// The viewer is structured with a functional layer and a gui layer.
// In principle the former can operate without the latter.  This class
// manages functional objects associated with the viewer, in particular
// the list of user-created DDs.
// </synopsis>

namespace casa { //# NAMESPACE CASA - BEGIN

class String;
class QtDisplayData;
class QtDisplayPanel;


class QtViewerBase : public QObject {

  Q_OBJECT	//# Allows slot/signal definition.  Must only occur in
		//# implement/.../*.h files; also, makefile must include
		//# name of this file in 'mocs' section.

 public:
  
  QtViewerBase();
  ~QtViewerBase();
  
  
  // Create a new QtDD from given parameters, and add to internal DD list.
  // (For now) QtViewerBase retains 'ownership' of the QtDisplayData; call
  // removeDD(qdd) to delete it.
  // Check return value for 0, or connect to the createDDFailed()
  // signal, to handle failure.
  QtDisplayData* createDD(String path, String dataType, String displayType);
   
  // Removes the QDD from the list and deletes it (if it existed -- 
  // Return value: whether qdd was in the list in the first place).
  virtual Bool removeDD(QtDisplayData* qdd);
  
  // retrieve a copy of the current DD list.
  List<QtDisplayData*> dds() { return qdds_;  }
  
  // retrieve a DD with given name (0 if none).
  QtDisplayData* dd(const String& name);
  
  // Check that a given DD is on the list.
  Bool ddExists(QtDisplayData* qdd);
  
  // Latest error (in createDD, etc.) 
  virtual String errMsg() { return errMsg_;  }
 
  virtual QtMouseToolState* mouseBtns() { return &msbtns_;  }
  
   
 public slots:
 
  virtual void removeAllDDs();
  
 
 signals:
 
  void createDDFailed(String errMsg, String path, String dataType, 
		      String displayType);
  
  // The DD now exists, and is on QtViewerBase's list.
  void ddCreated(QtDisplayData*);
  
  // The DD is no longer on QtViewerBase's list, but is not
  // destroyed until after the signal.
  void ddRemoved(QtDisplayData*);
  
 
  
 protected:
 
  List<QtDisplayData*> qdds_;
  
  String errMsg_;
  
  // This should be the only place this object is ever created....
  // Holds mouse button assignment for the mouse tools, which is to
  // be the same on all mouse toolbars / display panels.
  QtMouseToolState msbtns_;
    
};



} //# NAMESPACE CASA - END

#endif
