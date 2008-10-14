//# QtDisplayPanelGui.qo.h: Qt implementation of main viewer display window.
//# with surrounding Gui functionality
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
//# $Id: QtDisplayPanelGui.qo.h,v 1.6 2006/09/22 21:36:52 hye Exp $

#ifndef QTDISPLAYPANELGUI_H
#define QTDISPLAYPANELGUI_H

#include <casa/aips.h>
#include <display/QtViewer/QtDisplayPanel.qo.h>

#include <graphics/X11/X_enter.h>
#  include <QtCore>
#  include <QtGui>
   //#dk Be careful to put *.ui.h within X_enter/exit bracket too,
   //#   because they'll have Qt includes.
   //#   E.g. <QApplication> needs the X11 definition of 'Display'
#  include <display/QtViewer/QtAnimatorGui.ui.h>
#include <graphics/X11/X_exit.h>


namespace casa { //# NAMESPACE CASA - BEGIN

class String;
class QtViewer;
class QtViewerPrintGui;
class QtMouseToolBar;
class QtCanvasManager;
class QtAnnotatorGui;

class QtDisplayPanelGui : public QMainWindow,
		          protected Ui::QtAnimatorGui {

  Q_OBJECT	//# Allows slot/signal definition.  Must only occur in
		//# implement/.../*.h files; also, makefile must include
		//# name of this file in 'mocs' section.

 public:
  
  QtDisplayPanelGui(QtViewer* v, QWidget* parent=0);
  ~QtDisplayPanelGui();
  
  // access to graphics panel 'base'....
  QtDisplayPanel* displayPanel() { return qdp_;  }
  
 
 public slots:
 
  // Show/hide print dialog
  //<group>
  virtual void showPrintManager();
  virtual void hidePrintManager();
  //</group>
 
  virtual void showCanvasManager();
  virtual void hideCanvasManager();

  virtual void showAnnotatorPanel();
  virtual void hideAnnotatorPanel();
 
 protected slots:
 
  //# purely internal slots
 
  virtual void toggleAnimExtras_();
  virtual void setAnimExtrasVisibility_();  
  
  //# slots reacting to signals from the basic QtDisplayPanel.
  //# protected, connected by this object itself.
  
  // Respond to QDP::registrationChange() signal
  virtual void ddRegChange_() { updateDDMenus_();  }

  // Respond to registration/close menu clicks.
  //<group>
  virtual void ddRegClicked_();  
  virtual void ddUnregClicked_();  
  virtual void ddCloseClicked_();  
  //</group>
 
  // Reflect animator state [changes] in gui.
  virtual void updateAnimUi_();
  
   
   
    
 protected:
    
  virtual void updateDDMenus_(Bool doCloseMenu = True);
 
   
  QtViewer* v_;		 	//# (Same viewer as qdp_'s)
  QtDisplayPanel* qdp_;  	//# Central Widget this window operates.
  QtViewerPrintGui* qpm_;	//# Print dialog for this display panel.
  QtCanvasManager* qcm_; 
  QtAnnotatorGui* qap_;
  
  //# GUI LAYOUT  

  QMenu *dpMenu_, *ddMenu_, *ddRegMenu_, *ddCloseMenu_, *tlMenu_;
  
  QAction *dpNewAct_, *printAct_, *dpOptsAct_, *dpCloseAct_, *dpQuitAct_,
	  *ddOpenAct_, *ddAdjAct_, *ddRegAct_, *ddCloseAct_, *anotAct_;
  
  QToolBar* mainToolBar_;
  QToolButton *ddRegBtn_, *ddCloseBtn_;

  QtMouseToolBar* mouseToolBar_;
  
  QDockWidget*  animDockWidget_;
  QWidget*      animWidget_;  // Ui::QtAnimatorGui populates this.
  
  QToolBar*     bottomToolBar_;
  QWidget*      bottomWidget_;
  QVBoxLayout*  bottomLayout_;
  
  QSignalMapper *regMapper_, *closeMapper_;
     
 private:
  
  QtDisplayPanelGui() {  }		// (not intended for use)  
  
    
};



} //# NAMESPACE CASA - END

#endif
