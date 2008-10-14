//# QtDisplayPanel.cc: Qt implementation of viewer display Widget.
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
//# $Id: QtDisplayPanel.cc,v 1.7 2006/09/13 19:41:47 hye Exp $

#include <casa/BasicSL/String.h>
#include <display/QtViewer/QtViewerBase.qo.h>
#include <display/QtViewer/QtDisplayPanel.qo.h>
#include <display/QtViewer/QtDisplayData.qo.h>
#include <display/DisplayDatas/DisplayData.h>
#include <display/DisplayEvents/PCITFiddler.h>
#include <display/DisplayEvents/MWCRTZoomer.h>
#include <display/DisplayEvents/MWCPTRegion.h>
#include <display/DisplayEvents/MWCPolylineTool.h>
#include <display/DisplayEvents/MWCCrosshairTool.h>
#include <display/DisplayEvents/MWCPannerTool.h>
#include <display/Display/AttributeBuffer.h>
#include <display/QtViewer/QtMouseToolState.qo.h>


namespace casa { //# NAMESPACE CASA - BEGIN


QtDisplayPanel::QtDisplayPanel(QtViewerBase* v, QWidget *parent) : 
		QWidget(parent),

		v_(v),
		pd_(0), pc_(0),
		qdds_(),
		zoom_(0), panner_(0), crosshair_(0), rtregion_(0),
		ptregion_(0), polyline_(0),  snsFidd_(0), bncFidd_(0),
		mouseToolNames_(),
		cmap_("Hot Metal 1"),
		modeZ_(True),
		zLen_(1), bLen_(1),
		zIndex_(0), bIndex_(0),
		zStart_(0), zEnd_(1), zStep_(1),
		bStart_(0), bEnd_(1), bStep_(1),
		animRate_(4), minRate_(1), maxRate_(50), animating_(0)  {
    
  setWindowTitle("Viewer Display Panel");
  
  //pc_  = new QtPixelCanvas(this);
  pc_ = new QtPixelCanvas();
    
  // QDP's own widget just contains the pc_.
  
  QVBoxLayout *layout = new QVBoxLayout;
  layout->addWidget(pc_);
  setLayout(layout);
  
  pd_ = new PanelDisplay(pc_,1,1);	// (default is 3 by 2...)
 
  // Increase margins...
  AttributeBuffer margins;
  margins.add("leftMarginSpacePG", 12);
  margins.add("bottomMarginSpacePG", 9);
  pd_->setAttributes(margins);

  
  setupMouseTools_();
 
  
  
  connect( v_, SIGNAL(ddCreated(QtDisplayData*)),
                 SLOT(ddCreated_(QtDisplayData*)) );
  
  connect( v_, SIGNAL(ddRemoved(QtDisplayData*)),
                 SLOT(ddRemoved_(QtDisplayData*)) );

  
  // Connect detailed to general registration change signal.
  
  connect(this, SIGNAL(oldDDRegistered(QtDisplayData*)),
                SIGNAL(registrationChange()));
  
  connect(this, SIGNAL(oldDDUnregistered(QtDisplayData*)),
                SIGNAL(registrationChange()));
  
  connect(this, SIGNAL(newRegisteredDD(QtDisplayData*)),
                SIGNAL(registrationChange()));
  
  connect(this, SIGNAL(newUnegisteredDD(QtDisplayData*)),
                SIGNAL(registrationChange()));
  
  connect(this, SIGNAL(RegisteredDDRemoved(QtDisplayData*)),
                SIGNAL(registrationChange()));
  
  connect(this, SIGNAL(UnregisteredDDRemoved(QtDisplayData*)),
                SIGNAL(registrationChange()));
  
  connect(this, SIGNAL(allDDsRegistered()),   SIGNAL(registrationChange()));
  
  connect(this, SIGNAL(allDDsUnregistered()), SIGNAL(registrationChange()));


  // Animation
  
  connect(&tmr_, SIGNAL(timeout()),  SLOT(playStep_()));
  setRate(animRate_);

  // pc_->setFocus();	// (Needed?)

}


QtDisplayPanel::~QtDisplayPanel() { 
  unregisterAll();
  delete pd_; delete pc_;
  delete zoom_; delete panner_; delete crosshair_; delete rtregion_;
  delete ptregion_; delete polyline_; delete snsFidd_; delete bncFidd_;  }


  
void QtDisplayPanel::setupMouseTools_() {
 
  using namespace QtMouseToolNames;	// (See QtMouseToolState.qo.h)
  
  mouseToolNames_.resize(8);
  mouseToolNames_[0] = ZOOM;
  mouseToolNames_[1] = PAN;
  mouseToolNames_[2] = SHIFTSLOPE;
  mouseToolNames_[3] = BRIGHTCONTRAST;
  mouseToolNames_[4] = POSITION;
  mouseToolNames_[5] = RECTANGLE;
  mouseToolNames_[6] = POLYGON;
  mouseToolNames_[7] = POLYLINE;
	// The canonical text-names of the mouse tools on this panel.
	// These happen to be in QtMouseToolNames::toolIndex order,
	// but that is not a requirement.  This order is returned by
	// mouseToolNames() as a suggestion for the order on a gui which
	// would operate the mouse tools on this type of panel.


  // Create the actual mouse tools.
  
  zoom_      = new MWCRTZoomer;       pd_->addTool(ZOOM, zoom_);
  panner_    = new MWCPannerTool;     pd_->addTool(PAN, panner_);
  crosshair_ = new MWCCrosshairTool;  pd_->addTool(POSITION, crosshair_);
  rtregion_  = new QtRTRegion(pd_);   pd_->addTool(RECTANGLE, rtregion_);
  ptregion_  = new MWCPTRegion;       pd_->addTool(POLYGON, ptregion_);
  polyline_  = new MWCPolylineTool;   pd_->addTool(POLYLINE, polyline_);
  
  snsFidd_ = new PCITFiddler(pc_, PCITFiddler::StretchAndShift,
				  Display::K_None);
  bncFidd_ = new PCITFiddler(pc_, PCITFiddler::BrightnessAndContrast,
                                  Display::K_None);
	// NB: The above two 'colormap fiddling tools' are 'PCTools';
	// they should really share a common (DisplayTool) base with the
	// others (which are MWCTools), but do not, at present.
	// PCTools are attached to the PixelCanvas and treat it as a
	// whole, whereas MWCTools are attached to the PanelDisplay
	// and are sensitive to the individual WC they're operating
	// over within the PC.

  
  connect( rtregion_, SIGNAL(rectangleRegionReady(Record)),
		      SIGNAL(rectangleRegionReady(Record)) );
  
  QtMouseToolState* mBtns = v_->mouseBtns();
	// Central storage for current active mouse button of each tool.
  
  connect( mBtns, SIGNAL(mouseBtnChg(String, Int)),
                    SLOT(chgMouseBtn_(String, Int)) );
    
  mBtns->emitBtns();  }
	// (Causes mBtns to communicate current mouse button settings
	//  to the actual mouse tools (above), via the connection above).  



  
// PROTECTED SLOTS -- connected by this object itself.  
    

void QtDisplayPanel::chgMouseBtn_(String tool, Int button) {
  // Command to set/change the button currently assigned to a mouse tool.
  // The central place for this information is QtMouseToolState, which
  // invokes this routine.  This sets the active button onto the internal
  // (non-Qt) display library tool.
  //
  // button              Corresp. internal library value
  // ---------------     -------------------------------
  // 0:  <no button>     Display::K_None  
  // 1:  LeftButton      Display::K_Pointer_Button1
  // 2:  MidButton       Display::K_Pointer_Button2
  // 3:  RightButton     Display::K_Pointer_Button3
  
  if(button<0 || button>=4) return;	// (safety; shouldn't happen). 
  
  static const Display::KeySym dlBtns[4] = {
    Display::K_None, 
    Display::K_Pointer_Button1,
    Display::K_Pointer_Button2,
    Display::K_Pointer_Button3 };
  
  Display::KeySym dlbtn=dlBtns[button];
  
  using namespace QtMouseToolNames;	// (See QtMouseToolState.qo.h).
  
  if      (tool == SHIFTSLOPE)     snsFidd_->setKey(dlbtn);
  else if (tool == BRIGHTCONTRAST) bncFidd_->setKey(dlbtn);
  else                             pd_->setToolKey(tool, dlbtn);  }

 
   
void QtDisplayPanel::ddCreated_(QtDisplayData* qdd) {
  // DP actions to take when viewer signals new DD creation.
  
  // (logic to decide whether to register dd goes here...).
  // (else emit newUnregisteredDD(qdd);)
  
  registerDD_(qdd);
  emit newRegisteredDD(qdd);  }



void QtDisplayPanel::ddRemoved_(QtDisplayData* qdd) {
  // DP actions to take when viewer signals DD removal.
  
  // (logic to decide whether to register dd goes here...).
  // (else emit newUnregisteredDD(qdd);)
  
  if(isRegistered(qdd)) {
    unregisterDD_(qdd);
    emit RegisteredDDRemoved(qdd);  }
  else emit UnregisteredDDRemoved(qdd);  }




// REGISTRATION METHODS

  
void QtDisplayPanel::registerDD(QtDisplayData* qdd) {
  // Called externally (by gui, e.g.) to register pre-existing DDs.

  if(!isUnregistered(qdd)) return;  //  Nothing to do.
  registerDD_(qdd);
  emit oldDDRegistered(qdd);  }


void QtDisplayPanel::registerDD_(QtDisplayData* qdd) {
  // Internal method, called by public register method above,
  // or in reaction to new DD creation (ddCreated_() slot).
  // Precondition: isUnregistered(qdd) should be True before this is called.
  
  ListIter<QtDisplayData*> qdds(qdds_);
  qdds.toEnd();
  qdds.addRight(qdd);
  
  DisplayData* dd = qdd->dd();
    
  dd->setColormap(&cmap_, 1.0);		// (replace with qdd call).
	//# (also, most certainly doesn't belong here...)
    
  pd_->hold();
  
  Int preferredZIndex;
  Bool ddHasPreferredZIndex = dd->zIndexHint(preferredZIndex);
	// (preferredZIndex is recorded prior to adding DD to underlying
	// pd_, for obscure reasons: sometimes a frame setting may be
	// used from another Panel where dd is registered).

  
  pd_->addDisplayData(*dd);
	// Maintain registration relation between the
	// wrapped classes.
  

  // Reset animator in accordance with new set of registered DDs
  // (This code comes mostly from GTkPD::add()).

  Record animrec;

  if(pd_->isCSmaster(dd) && ddHasPreferredZIndex) {
    // New dd has become CS master: pass along its opinions
    // on animator frame number setting, if any.
    animrec.define("zindex", preferredZIndex);  }

  // Blink index or length may also change when DD added.

  if(pd_->isBlinkDD(dd)) {
    animrec.define("blength", pd_->bLength());
    animrec.define("bindex",  pd_->bIndex());  }

        
  setAnimator_(animrec);

  
  connect( qdd, SIGNAL(optionsChanged(Record)),
                  SLOT(setAnimatorOptions_(Record)) );
	// (Allows dd to change animator settings itself, e.g.,
	// after a user-requested change to its animation axis).


/*	//#dk~  old setanim code -- can be discarded.
 
  //#dk (animator reset: needs revision.  See glish/Gtk versions.
  //#dk  Probably belongs in reaction to reg. change signals). 
  
  Int len = pd_->zLength();
  setZlen_(len);
  
  Int pos = (len+1)/2;		//#dk  (bogus: demo only).
  goToZ(pos);
*/ 
 
    
  pd_->release();  }
  


  
void QtDisplayPanel::unregisterDD(QtDisplayData* qdd) {
  // Called externally (by gui, e.g.) to unregister pre-existing DDs.
  
  if(!isRegistered(qdd)) return;  //  Nothing to do.
  unregisterDD_(qdd);
  emit oldDDUnregistered(qdd);  }
  

void QtDisplayPanel::unregisterDD_(QtDisplayData* qdd) {
  for(ListIter<QtDisplayData*> qdds(qdds_); !qdds.atEnd(); qdds++) {
    if(qdd == qdds.getRight()) {
      qdds.removeRight();
      DisplayData* dd = qdd->dd();
      
      pd_->hold();
      
      
      pd_->removeDisplayData(*dd);

      
      // Signal animator to reset number of (Z) frames according to
      // remaining DDs.  Current frame should remain unchanged if
      // still in range.  Blink index or length may also change when
      // DD is removed.  (This code comes mostly from GTkPD::remove()).
      
      Record animrec;

      if(pd_->isBlinkDD(dd)) {
        animrec.define("blength", pd_->bLength());
        animrec.define("bindex",  pd_->bIndex());  }

      setAnimator_(animrec);

      // Ignore further animation change-request signals from dd,
      // since it is no longer registered.
      disconnect( qdd, SIGNAL(optionsChanged(Record)),
                  this,  SLOT(setAnimatorOptions_(Record)) );  


            
      pd_->release();
      
      break;  }  }  }




void QtDisplayPanel::registerAll() {
  // Called externally (by gui, e.g.) to register all DDs created
  // by user through QtViewer.
  
  List<QtDisplayData*> unregdDDs(unregisteredDDs());
  if(unregdDDs.len()==0) return;
  
  pd_->hold();
  
  for(ListIter<QtDisplayData*> udds(unregdDDs); !udds.atEnd(); udds++) {
    QtDisplayData* dd = udds.getRight();
    registerDD_(dd);  }

  emit allDDsRegistered();  
    //# do animator resetting, ala GTkPD
      
  pd_->release();  }

Record QtDisplayPanel::getOptions(){
    //cout << "QtDisplayPanel::getOptions()" << endl;
    Record rec;
    if (pd_ != 0) rec = pd_->getOptions();
    return rec;
}

void QtDisplayPanel::setOptions(Record rec){
    //cout << "QtDisplayPanel::setOptions() " << endl;
    if(pd_==0)
        return;

    hold();
    Record chgdOpts;
    try
    {
        pd_->setOptions(rec, chgdOpts);
        pc_->refresh();
    }
    catch (...)
    {
        //cout << "error, quitely do nothing!" << endl;
    }
    release();

    if(chgdOpts.nfields()!=0)
        emit optionsChanged(chgdOpts);
}


void QtDisplayPanel::unregisterAll() {
  // Called externally (by gui, e.g.) to unregister all DDs.
  List<QtDisplayData*> regdDDs(registeredDDs());
  if(regdDDs.len()==0) return;
  
  pd_->hold();
  
  for(ListIter<QtDisplayData*> rdds(regdDDs); !rdds.atEnd(); rdds++) {
    QtDisplayData* dd = rdds.getRight();
    unregisterDD_(dd);  }

  emit allDDsUnregistered();  
    //# do animator resetting, ala GTkPD.
      
  pd_->release();  }

  

Bool QtDisplayPanel::isRegistered(QtDisplayData* qdd) {
  for(ListIter<QtDisplayData*> qdds(qdds_); !qdds.atEnd(); qdds++) {
    if(qdd == qdds.getRight()) return True;  }
  return False;  }
    
Bool QtDisplayPanel::isUnregistered(QtDisplayData* qdd) {
  return !isRegistered(qdd) && v_->ddExists(qdd);  }



List<QtDisplayData*> QtDisplayPanel::unregisteredDDs() {
  // retrieve an (ordered) list of DDs (created on QtViewer) which
  // are _not_ currently registered.
  
  List<QtDisplayData*> unregdDDs(v_->dds());
  
  for(ListIter<QtDisplayData*> udds(unregdDDs); !udds.atEnd(); ) {
    if(isRegistered(udds.getRight())) udds.removeRight();
    else udds++;  }
  
  return unregdDDs;  }



  
// ANIMATION METHODS/SLOTS

void QtDisplayPanel::setAnimatorOptions_(Record opts) {
  if(opts.isDefined("setanimator") && 
     opts.dataType ("setanimator")==TpRecord) {
     
    Record sarec = opts.asRecord("setanimator");
    
    setAnimator_(sarec);  }  }


void QtDisplayPanel::setAnimator_(Record sarec) {
  // sarec can contain "zindex", "zlength" (cube mode settings),
  // "bindex" and/or "blength" fields (blink mode settings).
  // Either may be updated, regardless of current animator mode.
  //
  // The current zlength value (polled from DDs) is always
  // [re]set onto the animator during this call, even when it
  // does not appear explicitly in sarec.  setAnimator_ can simply
  // be called with an empty sarec (and often is) when the number of
  // animation frames has changed.  (However, blink mode settings are
  // specified explicitly if they need to be changed).
  
   
  // Z-MODE ("Normal") SETTINGS
  
  Int len = pd_->zLength();
	// pd_->zLength() polls the active DDs' nelements(), taking their
	// maximum.
  
  if(len<1) len=1;
	// (Even an empty display panel is considered to have animation
	// length 1 in the Qt version of the animator).
  
  if(sarec.isDefined("zlength") && sarec.dataType("zlength")==TpInt) {
    len = max(len, sarec.asInt("zlength"));  }
	// (This statement shouldn't be necessary; the previous ones
	// should suffice.  Probably best if DDs don't send an explicit
	// "zlength" field, and just implement nelements() properly
	// instead; that gets polled in the prior statement.  This was
	// inserted just in case ScrollingRasterDD might need it).


  setZlen_(len);
  
  // If the old frame number is now out of new range, reset it to zero
  // (otherwise, leave it alone).  However, if a new one was suggested
  // in the Record, use that instead.
  Int frm = zIndex();
  if(frm >= nZFrames()) frm = 0;
  if(sarec.isDefined("zindex") && sarec.dataType("zindex")==TpInt) {
    frm = sarec.asInt("zindex");  }

    
  goToZ_(frm);


    
  // B-MODE ("Blink") SETTINGS
  
  if(sarec.isDefined("blength") && sarec.dataType("blength")==TpInt) {
    setBlen_(sarec.asInt("blength"));  }
  
  if(sarec.isDefined("bindex") && sarec.dataType("bindex")==TpInt) {
    goToB_(sarec.asInt("bindex"));  }
  

        
  emit animatorChange();  }




void QtDisplayPanel::setZlen_(Int len) {
  // Only used by setAnimator_ at present, in turn resulting from
  // DD signals or DD registration activity.  setAnimator_() normally
  // determines this animation length by polling active DDs.
  // Caller still needs to signal animatorChange, and assure that
  // zIndex_ is in range (best to use goToZ_ for that).
  
  len = max(1, len);
  if(len==zLen_) return;
  
  stop_();
  
  zLen_=len;
  
  zStart_=0;	 // Change in total number of frames always
  zEnd_=zLen_;	 // resets 'playback range' to 'all frames'....
  zStep_=1;
  
  //#dk~ emit animatorChange();		//#dk No: caller should do this
    
}
 

void QtDisplayPanel::setBlen_(Int len) {
  len = max(1, len);
  if(len==bLen_) return;
  
  stop_();
  
  bLen_=len;
  
  bStart_=0;
  bEnd_=bLen_;
  bStep_=1;  }
  


  
void QtDisplayPanel::goToZ(int frm) {
  // Connected from text box and slider; also usable by scripts.
  stop_();
  goToZ_(frm);
  emit animatorChange();  }


  
void QtDisplayPanel::goToZ_(Int frm) {
  // Internal part: doesn't send signals, but does set the restrictions
  // (which requests refresh).

  frm = max(0, min(nZFrames()-1,  frm));
	// Assure value is in range, if caller didn't do this himself.
  
  zStart_ = min(zStart_, frm);	// Calling this 'automatically' expands
  zEnd_ =   max(zEnd_, frm+1);	// animation limits to include selected frame.
  
  zIndex_ = frm;
  
  AttributeBuffer zInd, zIncr;
  zInd.set("zIndex", zIndex_); 
  
  zIncr.set("zIndex", modeZ()? 1:0);
        // Set the 'multipanel increment':
	// In blink mode all 'panels' (WCs) of the DisplayPanel display
	// the same plane (of various images) -- in normal mode, multiple
	// panels display successive planes (of the same image).
	// NB: 'step()' does not refer to this increment between panels
	// (which is fixed, here), but to the number of planes moved
	// (by _all_ panels) when an animation (tapedeck) step occurs.

  pd_->setLinearRestrictions(zInd, zIncr);  }
	// (I think we want to do this regardless of previous
	// zIndex_: new canvases, init, etc. (?))
    

 

         
void QtDisplayPanel::goToB(int frm) {
  // Connected from text box, or usable by scripts.
  
  //#dk  (Blink mode not fully supported yet.  Need to complete setMode()
  //     implementation and enable radio button interface that calls it).
  
  stop_();
  goToB_(frm);
  emit animatorChange();  }
 
  

void QtDisplayPanel::goToB_(Int frm) {
  
  frm = max(0, min(nBFrames()-1, frm));
	// Assure within range.  If changing number of frames also,
	// do that first.
  
  bStart_ = min(bStart_, frm);
  bEnd_ =   max(bEnd_, frm+1);
  
  bIndex_ = frm;	// blink state is always maintained.  However,...

  if(!modeZ()) {	// ...actual blink restriction is set onto
			// canvases only during blink mode.
    AttributeBuffer bInd, bIncr;
    bInd.set("bIndex", bIndex_); 
    bIncr.set("bIndex", 1);
    pd_->setLinearRestrictions(bInd, bIncr);  }  }
 

         

void QtDisplayPanel::setMode(bool modez) {
  // True: "Normal" ("Z") mode.  False: "Blink" ("B") mode.
  // (NB: small 'b' bool for a reason -- see declataion of goTo(int)).

  stop_();
  
  if(modeZ_!=modez) {	// (already there otherwise).
    
    modeZ_ = modez;
  
    pd_->hold();
  
    goToZ_(zIndex());	// (Sets proper multi-panel zIndex increment
			//  in accordance with new mode, primarily).
  
    if(mode()=="Blink")  goToB_(bIndex());
		// (Sets 'Blink restrictions').    
    else  pd_->removeRestriction("bIndex");
		// (Removes them -- they shouldn't exist in "Normal" mode).

    pd_->release();  }
  
  
  emit animatorChange();  }



void QtDisplayPanel::prev_() { 
  Int newframe = frame() - step();
  if(newframe<startFrame()) newframe = lastFrame();
  goTo_(newframe);
  emit animatorChange();  }

void QtDisplayPanel::next_() {
  Int newframe = frame() + step();
  if(newframe>lastFrame()) newframe = startFrame();
  goTo_(newframe);
  emit animatorChange();  }


//#dk Limiting animation range not really supported yet.
//    (Remember, these should call goToX_(), if necessary
//     to put current frame within new range).
void QtDisplayPanel::setEndZFrame(Int frm) {  }
void QtDisplayPanel::setEndBFrame(Int frm) {  }



void QtDisplayPanel::revPlay() { 
  animating_ = -1;
  tmr_.start();
  emit animatorChange();  }

void QtDisplayPanel::stop() { stop_();  emit animatorChange();  }

void QtDisplayPanel::stop_() { animating_ = 0; tmr_.stop();  }


void QtDisplayPanel::fwdPlay() {
  animating_ = 1;
  tmr_.start();
  emit animatorChange();  }

void QtDisplayPanel::setRate(int rate) {
  animRate_ = max(minRate(), min(maxRate(),  rate  ));
  tmr_.setInterval(1000/animRate_);
  emit animatorChange();  }
  
   
//#dk~ old code -- can be discarded.
/*
void QtDisplayPanel::goToZ(int frm) {
  if(frm < 1 || frm > max(1, zLen_)) return;
  Int zindex = frm-1;	// (frm # is 0-based, internal zIndex_ 0-based).
  AttributeBuffer zInd, zIncr;
  zInd.set("zIndex", zindex); zIncr.set("zIndex", 1);
  pd_->setLinearRestrictions(zInd, zIncr);
  
  if(zindex!=zIndex_) {
    
    zIndex_=zindex;

    //#dk~ emit newZFrame(zIndex_+1);
    //#dk~ if(modeZ_) emit newFrame(zIndex_+1);
    emit animatorChange();  }  
*/    





} //# NAMESPACE CASA - END
