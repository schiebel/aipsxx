//# QtDisplayPanel.qo.h: Qt implementation of viewer display Widget.
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
//# $Id: QtDisplayPanel.qo.h,v 1.6 2006/09/27 15:11:22 hye Exp $

#ifndef QTDISPLAYPANEL_H
#define QTDISPLAYPANEL_H

#include <casa/aips.h>
#include <display/Display/Colormap.h>
#include <casa/Containers/List.h>
#include <display/QtViewer/QtPixelCanvas.qo.h>
#include <display/QtViewer/QtMouseTools.qo.h>
#include <display/Display/PanelDisplay.h>

#include <graphics/X11/X_enter.h>
#  include <QtCore>
#  include <QtGui>
#  include <QTimer>
#include <graphics/X11/X_exit.h>


namespace casa { //# NAMESPACE CASA - BEGIN


class String;
class QtViewerBase;
class QtDisplayData;
class DisplayData;
class PCITFiddler;
class MWCRTZoomer;
class MWCCrosshairTool;
class MWCPannerTool;
class MWCPolylineTool;
class MWCPTRegion;



class QtDisplayPanel : public QWidget {

  Q_OBJECT	//# Allows slot/signal definition.  Must only occur in
		//# implement/.../*.h files; also, makefile must include
		//# name of this file in 'mocs' section.

 public:
  
  QtDisplayPanel(QtViewerBase* v, QWidget* parent=0);
  ~QtDisplayPanel();
  
  // True if DD is on our list.  (It may _not_ be on viewer's list
  // any longer, in particular when reacting to ddRemoved signal).
  virtual Bool isRegistered(QtDisplayData*);
  
  // True only if DD is not on our registered List,
  // but _is_ on QtViewer's list.
  virtual Bool isUnregistered(QtDisplayData*);
  
  // retrieve an (ordered) list of currently-registered DDs.
  // (This is a copy, not a reference).
  List<QtDisplayData*> registeredDDs() { return qdds_;  }
  
  // retrieve an (ordered) list of QtViewer's created DDs which
  // are _not_ currently registered.
  List<QtDisplayData*> unregisteredDDs();
  
  QtViewerBase* viewer() { return v_;  }
 
  // Return a QPixmap* with a copy of currently-displayed widget contents.
  // Caller is responsible for deleting.
  virtual QPixmap* contents() { return pc_->contents();  }
  virtual PanelDisplay *panelDisplay() { return pd_;  }

  // hold and release of refresh.
  //<group>
  virtual void hold()    { pd_->hold();     }
  virtual void release() { pd_->release();  }
  //</group>
   
  // Return names of resident mouse tools (order is a suggestion
  // for order in gui).
  virtual Vector<String> mouseToolNames() { return mouseToolNames_;  }
 

  
  //# animation
 
  //# ( Updates to user interface will likely need only these:
  //#   modeZ() (or mode()),
  //#   nFrames(), frame(),
  //#   startFrame(), lastFrame(), step(),
  //#   animRate(), minRate(), maxRate(), animating()  ).
  
  virtual Bool modeZ()  { return modeZ_;  }
  virtual String mode() { return modeZ()?  "Normal" : "Blink";  }
  
  virtual Int nFrames()  { return modeZ()?  nZFrames() : nBFrames();  }
  virtual Int nZFrames() { return zLen_;  }
  virtual Int nBFrames() { return bLen_;  }
  
  virtual Int frame()  { return index();  }
  virtual Int index()  { return modeZ()?  zIndex() : bIndex();  }
  virtual Int zIndex() { return zIndex_;  }
  virtual Int bIndex() { return bIndex_;  }
  
  virtual Int startFrame()  { return modeZ()?  zStart() : bStart();  }
  virtual Int zStart() { return zStart_;  }
  virtual Int bStart() { return bStart_;  }
  
  virtual Int lastFrame() { return endFrame()-1;  }
  virtual Int endFrame()  { return modeZ()?  zEnd() : bEnd();  }
  virtual Int zEnd() { return zEnd_;  }
  virtual Int bEnd() { return bEnd_;  }
	//# NB: frame() <  endFrame()  (<--used internally)
	//# but frame() <= lastFrame() (<--shown in ui)

  virtual Int step()  { return modeZ()?  zStep() : bStep();  }
  virtual Int zStep() { return zStep_;  }
  virtual Int bStep() { return bStep_;  }
  
  virtual Int animRate()  { return animRate_;  }
  virtual Int minRate()   { return minRate_;  }
  virtual Int maxRate()   { return maxRate_;  }
  virtual Int animating() { return animating_;  }
 
  virtual Record getOptions();    
 public slots:
  virtual void setOptions(Record opts);
 
  // Register / unregister [all] DDs created by user through QtViewer.
  //<group>
  virtual void registerDD(QtDisplayData*);
  virtual void unregisterDD(QtDisplayData*);
  virtual void unregisterAll();
  virtual void registerAll();
  //</group>

  
  //# animation
   
  virtual void setMode(bool modez);
  virtual void setMode(String mode) { setMode(downcase(mode)=="normal");  }

  virtual void toStart() { goTo(startFrame());  }
  virtual void toEnd()   { goTo(lastFrame());  }
  virtual void revStep() { stop_(); prev_();  }
  virtual void fwdStep() { stop_(); next_();  }
  virtual void revPlay();
  virtual void stop();		// slots corresp. to tapedeck buttons.
  virtual void fwdPlay();
  virtual void setRate(int rate);

    
  virtual void goTo(int frm) { if(modeZ()) goToZ(frm); else goToB(frm);  }
	//# Note: connected to std Qt signal which takes 'int'.
	//# As of Qt4.1.3, declaring goTo(Int frm) will no longer
	//# do (which is a bit of a pain...).  (Actually, though,
	//# it is very unclear to me that having casa Ints, Floats,
	//# et. al. buys us anything at all...).
  virtual void goToZ(int frm);
  virtual void goToB(int frm);
  

  virtual void setLastFrame(Int frm) { return setEndFrame(frm+1);  }
  virtual void setEndFrame(Int frm)  { 
    if(modeZ()) setEndZFrame(frm); else setEndBFrame(frm);  }
  virtual void setEndZFrame(Int frm);
  virtual void setEndBFrame(Int frm);

  
  virtual void emitAnimState() { emit animatorChange();  }
  
  //# mouse tools
  
  // (Will remove mouse-tool's own visual feedback from screen;
  // usually called after rectangular selection has been processed).
  virtual void resetRTRegion() { rtregion_->reset();  }
   


     
 signals:

  // signals from animator.
  //<group>
  void animatorChange();

  //#dk~ (these detailed signals are unneeded and should probably
  //#dk~  be removed, using above signal exclusively instead;
  //#dk~  fortunately, updating entire animator gui when any
  //#dk~  animator change occurs is plenty fast, it turns out.   :-).
  //#dk~ 
  //#dk~ void newZlen(Int len);
  //#dk~ void newBlen(Int len);
  //#dk~ void newLen(Int len);
  //#dk~ 
  //#dk~ void newZFrame(Int frm);
  //#dk~ void newBFrame(Int frm);
  //#dk~ void newFrame(Int frm);
  //#dk~ ...
  
  //</group>
  
  
  // signals from registration methods.
  //<group>
  
  //#dk (These signals are the ones most suitable for the regMenu and
  //#dk  other parts of the gui to react to...).
  void oldDDRegistered(QtDisplayData*);		//# reg. status change
  void oldDDUnregistered(QtDisplayData*);	//# on pre-existing DDs.
  void newRegisteredDD(QtDisplayData*);		//# new DD creation, with
  void newUnegisteredDD(QtDisplayData*);	//# new reg. status.
  void RegisteredDDRemoved(QtDisplayData*);	//# DD removal from viewer,
  void UnregisteredDDRemoved(QtDisplayData*);	//# with former reg. status.
  void allDDsRegistered();	//# (may be emitted _instead_ of
  void allDDsUnregistered();	//#  oldDD[Un]registered, above).
  
  void registrationChange();	//# Any of above occurred; usually
				//# simplest just to connect to this one.
  //</group>
  
  
  // signals from mouse tools.
  //<group>
  void rectangleRegionReady(Record rectRegion);
  //</group>



  void optionsChanged(Record chgOpt); 
 protected slots:
  
  //# I.e., only this class creates the connections to these,
  //# (though the signals _may_ come from outside...).
 
  //# Protected counterparts to public slots/routines generally are 
  //# 'workhorse' parts of the public routines.  They do the indicated
  //# task, but without assuring consistency with other state/interface,
  //# or sending signals for that purpose.  Those jobs are left to the
  //# public parts, mostly.
  
  
  //# registration
   
  // reacts to similar-named signals from QtViewer
  // <group>
  virtual void ddCreated_(QtDisplayData*);
  virtual void ddRemoved_(QtDisplayData*);
  // </group>
  
  
  //# animation
   
  virtual void setAnimatorOptions_(Record opts);
  virtual void setAnimator_(Record sarec);
  
  virtual void setLen_(Int len) {	//# (probably unneeded).
    if(modeZ()) setZlen_(len);
    else        setBlen_(len);  }
  virtual void setZlen_(Int len);
  virtual void setBlen_(Int len);
  
  virtual void stop_();
  virtual void goTo_(Int frm) { if(modeZ()) goToZ_(frm); else goToB_(frm);  }
  virtual void goToZ_(Int frm);
  virtual void goToB_(Int frm);
  
  virtual void playStep_() {
    if(animating_<0) prev_(); else if(animating_>0) next_();  } 
  virtual void prev_();	//# (Like fwdStep, revStep, but these don't stop
  virtual void next_();	//#  the animation; they are _used_ by animation)
  
  
  
  //# mouse tools
   
  // Connected to QtMouseToolState::mouseBtnChg() signal: changes
  // button assignment for a mouse tool.
  virtual void chgMouseBtn_(String tool, Int button);

 
 
 protected:
  
  // Called during construction.
  virtual void setupMouseTools_();
  
  // The workhorse part of [un]registering; these do not send the
  // highest-level signals.
  // Called internally when the DD is new or being removed, or from
  // corresponding public methods.
  // <group>
  void registerDD_(QtDisplayData* qdd);
  void unregisterDD_(QtDisplayData* qdd);
  void registerAll_();
  void unregisterAll_();
  // </group>

 
  
 
 private:
  
  QtDisplayPanel() {  }		// (not intended for use)  
  
    
  
  //# DATA
    
    
 protected:
 
  QtViewerBase* v_;
  
  PanelDisplay* pd_;
  
  QtPixelCanvas* pc_;	//# QtDisplayPanel is basically just enhanced
			//# state and functional interface on top of
			//# this PixelCanvas.  Its own QWidget
			//# is just a container for the PC's.
  
  List<QtDisplayData*> qdds_;
  
  MWCRTZoomer* zoom_;
  MWCPannerTool* panner_;
  MWCCrosshairTool* crosshair_;
  QtRTRegion* rtregion_;
  MWCPTRegion* ptregion_;
  MWCPolylineTool* polyline_;
  PCITFiddler* snsFidd_;
  PCITFiddler* bncFidd_;
  
  Vector<String> mouseToolNames_;
  
  QTimer tmr_;
  
  Colormap cmap_;
  
  
  //# animation state
  
  Bool modeZ_;			//# True (default) == normal mode; else blink.
  Int zLen_, bLen_;		//# total number of frames for each mode.
  Int zIndex_, bIndex_;		//# current frame (0-based).
  
  //# Start_, End_ , Step_ are current user-desired anim. limits;
  //# 0 <= Start_ <= Index_ < End_ <=Len_   and  1 <= Step_ <= Len_.
  Int zStart_, zEnd_, zStep_;
  Int bStart_, bEnd_, bStep_;
  
  Int animRate_;  		//# frames / sec. for play.
  Int minRate_, maxRate_;	//# limits to above:
				//# 1 <= minRate_ <= animRate_ <= maxRate_.
  Int animating_;		//# -1: reverse play  0: stopped  1: fwd. play
  
};



} //# NAMESPACE CASA - END

#endif
