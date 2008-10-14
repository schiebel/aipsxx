//# QtMouseToolState.qo.h: constants and [global] mouse-button state
//# for the qtviewer 'mouse-tools' used by its display panel[s].
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
//# $Id: QtMouseToolState.qo.h,v 1.1 2006/08/11 22:18:39 dking Exp $


#ifndef QTMOUSETOOLSTATE_H
#define QTMOUSETOOLSTATE_H

#include <casa/aips.h>
#include <casa/BasicSL/String.h>

#include <graphics/X11/X_enter.h>
#  include <QObject>
#include <graphics/X11/X_exit.h>


namespace casa { //# NAMESPACE CASA - BEGIN


class QtViewerBase;



// <synopsis>
// QtMouseToolNames holds static constants for Qt mouse tools (with
// some access methods for them).  There is an ordered list of 'mouse tool'
// types, names and reference indices for them, etc.
// </synopsis>

namespace QtMouseToolNames {

  enum { nTools = 10 };
  
  extern const String ZOOM, PAN, SHIFTSLOPE, BRIGHTCONTRAST, POSITION,
               RECTANGLE, POLYGON, POLYLINE,  MULTICROSSHAIR, ANNOTATIONS;

  //# nTools is an invalid tool index (or stands for "none") in these arrays.
  extern const String     tools[nTools+1], longnames[nTools+1],
                      iconnames[nTools+1], helptexts[nTools+1];

  // Return index of named tool within the master list.
  // (i==nTools means 'not a tool').
  inline Int toolIndex(String tool) {
    for(Int i=0;;i++) if (tools[i]==tool || i==nTools) return i;  }
		//# i==nTools means 'not a tool'.

  inline String toolName(Int toolindex) {
    if(toolindex<0 || toolindex>=nTools) return "";
    return tools[toolindex];  }

  inline String longName(String tool) { return longnames[toolIndex(tool)];  }
  inline String iconName(String tool) { return iconnames[toolIndex(tool)];  }
  inline String help(String tool)     { return helptexts[toolIndex(tool)];  }

};





// <synopsis>
// QtMouseToolState records the currently-active mouse button (if any) 
// of each type of Qt mouse tool.  There may be a QtMouseToolBar for each 
// QtDisplayPanel (and in principle each may display a different subset
// of all the possible tools, though this is not implemented yet (7/06)).
// However, each mouse button (Left, Middle, Right) may be assigned to
// at most one type of tool type, and that assignment should be the same
// on each QtMouseToolBar.
//
// To accomplish that, this class signals current button assignments
// whenever such assignments change.  All display panels and/or their mouse
// tool bars may connect to this signal to keep Toolbar button icons and the
// actual core library mouse tools (such as MWCZoomer) in sync.
//
// This button state is therefore also essentially global or static, but this
// class cannot be purely static because it must be a real QObject
// to send out such a signal.  Instead, there should be only one
// QtMouseToolState object (managed by the [one] QtViewer[Base] object),
// and all listeners should use that object for setting and responding to
// current mouse tool button state.
// </synopsis>

class QtMouseToolState : public QObject {
 

  Q_OBJECT	//# Allows slot/signal definition.  Must only occur in
		//# implement/.../*.h files; also, makefile must include
		//# name of this file in 'mocs' section.

 
 public slots:

  // Request reassignment of a given mouse button to a tool.
  // NB: _This_ is where guis, etc. should request a button change, so that
  // all stay on the same page (not directly to tool or displaypanel, e.g.).
  void chgMouseBtn(String tool, Int button);
  
  // Request signalling of the current mouse button setting for every
  // type of tool.  Call this if you want to assure that everyone's
  // up-to-date on mouse button settings.
  void emitBtns();

 
 signals:
  
  // Notification of a tool's [new] mouse button.
  void mouseBtnChg(String tool, Int button);

 
 protected:
  
  // Only QtviewerBase is intended to create/destroy
  // a [single] instance of this class.
  QtMouseToolState()  {  }
  ~QtMouseToolState() {  }
  friend class QtViewerBase;
  
 
  // The button currently assigned to the various types of mouse tool.
  //
  // mousebtns value     Corresp. internal library value
  // ---------------     -------------------------------
  // 0:  <no button>     Display::K_None  
  // 1:  LeftButton      Display::K_Pointer_Button1
  // 2:  MidButton       Display::K_Pointer_Button2
  // 3:  RightButton     Display::K_Pointer_Button3
  static Int mousebtns[QtMouseToolNames::nTools+1];
	//# Initial values; correspond to QtMouseToolNames::tools[], above.
	//# mousebtns[nTools] is an entry for an invalid tool.
	//# At most one of the above will be 1,2,3; the rest will be 0.

};

} //# NAMESPACE CASA - END

#endif
