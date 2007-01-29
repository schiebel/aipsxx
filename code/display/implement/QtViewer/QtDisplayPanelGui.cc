//# QtDisplayPanelGui.cc: Qt implementation of main viewer display window.
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
//# $Id: QtDisplayPanelGui.cc,v 1.12 2006/10/10 21:59:19 dking Exp $

#include <casa/BasicSL/String.h>
#include <display/QtViewer/QtDisplayPanelGui.qo.h>
#include <display/QtViewer/QtViewerPrintGui.qo.h>
#include <display/QtViewer/QtCanvasManager.qo.h>
#include <display/QtViewer/QtAnnotatorGui.qo.h>
#include <display/QtViewer/QtDisplayData.qo.h>
#include <display/QtViewer/QtMouseToolBar.qo.h>
#include <display/QtViewer/QtViewer.qo.h>

namespace casa { //# NAMESPACE CASA - BEGIN


QtDisplayPanelGui::QtDisplayPanelGui(QtViewer* v, QWidget *parent) :
		   QMainWindow(parent),
		   v_(v), qdp_(0), qpm_(0), qcm_(0), qap_(0)  {
    
  setWindowTitle("Viewer Display Panel");
  
  qdp_ = new QtDisplayPanel(v_);
  
  setCentralWidget(qdp_);

  // qdp_->setFocus();	// (Needed?)


    
  // SURROUNDING GUI LAYOUT  

  // Create the widgets (plus a little parenting and properties)
  
  ddMenu_        = menuBar()->addMenu("&Data");
   ddOpenAct_    = ddMenu_->addAction("&Open...");
   ddRegAct_     = ddMenu_->addAction("&Register");
    ddRegMenu_   = new QMenu; ddRegAct_->setMenu(ddRegMenu_);
   ddCloseAct_   = ddMenu_->addAction("&Close");
    ddCloseMenu_ = new QMenu; ddCloseAct_->setMenu(ddCloseMenu_);
   ddAdjAct_     = ddMenu_->addAction("&Adjust...");
		   ddMenu_->addSeparator();
   printAct_     = ddMenu_->addAction("&Print...");
		   ddMenu_->addSeparator();
   dpCloseAct_   = ddMenu_->addAction("&Close Panel");
   dpQuitAct_    = ddMenu_->addAction("&Quit Viewer");

  dpMenu_        = menuBar()->addMenu("D&isplay Panel");
   dpNewAct_     = dpMenu_->addAction("&New Panel");
   dpOptsAct_    = dpMenu_->addAction("Panel &Options...");
                   dpMenu_->addAction(printAct_);
		   dpMenu_->addSeparator();
                   dpMenu_->addAction(dpCloseAct_);
  
  tlMenu_        = menuBar()->addMenu("&Tools");
   anotAct_     = tlMenu_->addAction("A&nnotations...");
  anotAct_->setEnabled(False);	//#diag  (disabled until it's working).
  
  mainToolBar_ = addToolBar("Main Toolbar");
		   mainToolBar_->addAction(ddOpenAct_);
		   mainToolBar_->addAction(ddAdjAct_);
   ddRegBtn_     = new QToolButton(mainToolBar_);
		   mainToolBar_->addWidget(ddRegBtn_);
		   ddRegBtn_->setMenu(ddRegMenu_);
   ddCloseBtn_   = new QToolButton(mainToolBar_);
		   mainToolBar_->addWidget(ddCloseBtn_);
		   ddCloseBtn_->setMenu(ddCloseMenu_);
		   mainToolBar_->addSeparator();
		   mainToolBar_->addAction(dpNewAct_);
		   mainToolBar_->addAction(dpOptsAct_);
		   mainToolBar_->addSeparator();
		   mainToolBar_->addAction(printAct_);

  
  mouseToolBar_    = new QtMouseToolBar(v_->mouseBtns(), qdp_);
		     addToolBarBreak();
		     addToolBar(/*Qt::LeftToolBarArea,*/ mouseToolBar_);

  animDockWidget_  = new QDockWidget();
                     addDockWidget(Qt::BottomDockWidgetArea, animDockWidget_,
		                   Qt::Vertical);
   animWidget_     = new QWidget;
                     animDockWidget_->setWidget(animWidget_);
  
/*   
  //bottomToolBar_   = new QToolBar("Tracking Display");
	// (Tracking was put into a dock widget instead...)
  bottomToolBar_   = new QToolBar();
		     addToolBar(Qt::BottomToolBarArea, bottomToolBar_);
   bottomWidget_   = new QWidget;
		     bottomToolBar_->addWidget(bottomWidget_);
    bottomLayout_  = new QVBoxLayout;
		     bottomWidget_->setLayout(bottomLayout_);
//*/     
  
  
  
  
  
  
  
  
   
  
  
 
  
  trkgDockWidget_  = new QDockWidget();
                     addDockWidget(Qt::BottomDockWidgetArea, trkgDockWidget_,
		                   Qt::Vertical);
   
   //trkgWidget_     = new QWidget;
   trkgWidget_     = new QGroupBox;
                     trkgDockWidget_->setWidget(trkgWidget_);
        // trkgDockWidget_->layout()->addWidget(trkgWidget_);  // <-- no!
	// dockWidget already _has_ layout, which now contains trkWidg_  
    
    trkgEdit_      = new QTextEdit(trkgWidget_);
     
     trkgLayout_   = new QVBoxLayout(trkgWidget_);
	// ..._but_: _must_ create layout for trkW_,...
                    trkgWidget_->layout()->addWidget(trkgEdit_);
	// ..._and_ explicitly add trkW's children to it
      

  // Cursor Position Tracking

  trkgDockWidget_->setAllowedAreas(Qt::BottomDockWidgetArea |
				   Qt::TopDockWidgetArea);
  
  trkgDockWidget_->setFeatures(QDockWidget::DockWidgetMovable |
  			       QDockWidget::DockWidgetFloatable);
   
  trkgDockWidget_->toggleViewAction()->setText("Position Tracking");
  



  trkgWidget_->setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Fixed); 
  
  // (trkgWidget_ as QroupBox)
  //trkgWidget_->setTitle("6503.im");	//#diag test
  //trkgWidget_->setCheckable(True);
  //trkgWidget_->setChecked(True);
  trkgWidget_->setFlat(True);
  //trkgWidget_->setAlignment(Qt::AlignHCenter);
  //trkgWidget_->setAlignment(Qt::AlignRight);
    
  //trkgLayout_->setSpacing(10);
  //trkgLayout_->setMargin(10);
  trkgLayout_->setMargin(1);
      
  QFont trkgFont;
  trkgFont.setFamily(QString::fromUtf8("Courier"));
  trkgFont.setBold(True);
  trkgEdit_->setFont(trkgFont);
    
  //trkgEdit_->setFixedSize(QSize(421, 81));
  //trkgEdit_->setMinimumSize(QSize(421, 81));
  trkgEdit_->setMinimumWidth(355);
  trkgEdit_->setFixedHeight(81);
  
  trkgEdit_->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
  trkgEdit_->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
  trkgEdit_->setLineWrapMode(QTextEdit::NoWrap);
  trkgEdit_->setReadOnly(True);
  //trkgEdit_->setAcceptRichText(False);

/* 
  trkgEdit_->      setSizePolicy(QSizePolicy::MinimumExpanding,
                                 QSizePolicy::Fixed); 
  trkgWidget_->    setSizePolicy(QSizePolicy::MinimumExpanding,
                                 QSizePolicy::Fixed); 
  trkgDockWidget_->setSizePolicy(QSizePolicy::MinimumExpanding,
                                 QSizePolicy::Fixed);
//*/

//trkgEdit_->setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum); 
//trkgWidget_->setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum); 
//trkgDockWidget_->setSizePolicy(QSizePolicy::Minimum,	  // (horizontal)
//				 QSizePolicy::Minimum);	  // (vertical)
//				 QSizePolicy::Fixed);	  // (vertical)



  
    
/* 
cerr<<"tEszH:"<<trkgEdit_->sizeHint().width()			//#diag
<<","<<trkgEdit_->sizeHint().height()<<endl;			//#diag
cerr<<"tWszH:"<<trkgWidget_->sizeHint().width()			//#diag
<<","<<trkgWidget_->sizeHint().height();			//#diag
cerr<<" mSzH:"<<trkgWidget_->minimumSizeHint().width()		//#diag
<<","<<trkgWidget_->minimumSizeHint().height();			//#diag
  
  // trkgWidget_->resize(trkgWidget_->minimumSizeHint());

cerr<<" sz:"<<trkgWidget_->size().width()			//#diag
<<","<<trkgWidget_->size().height()<<endl;			//#diag
cerr<<"tDszH:"<<trkgDockWidget_->sizeHint().width()		//#diag
<<","<<trkgDockWidget_->sizeHint().height();			//#diag
cerr<<" mSzH:"<<trkgDockWidget_->minimumSizeHint().width()	//#diag
<<","<<trkgDockWidget_->minimumSizeHint().height();		//#diag
  
  // trkgDockWidget_->resize(trkgDockWidget_->minimumSizeHint());

cerr<<" sz:"<<trkgDockWidget_->size().width()			//#diag
<<","<<trkgDockWidget_->size().height()<<endl;			//#diag
//*/  
  







  
  
  //delete trkgDockWidget_->layout();	//#diag -- experimental  (crashes)
  //new QVBoxLayout(trkgDockWidget_);	//#diag -- experimental  (crashes)
  
  
  // The rest of the parenting and layout
 
  
  Ui::QtAnimatorGui::setupUi(animWidget_);  
	// creates/inserts animator widgets.  Note that these
	// widgets (such as frameSlider_) are protected members
	// of Ui::QtAnimatorGui, accessible to this derived class.

  

   
  // The rest of the property setting 

  
  // menus / toolbars
    
  //mainToolBar_->setIconSize(QSize(22,22));
  setIconSize(QSize(22,22));
 
  mainToolBar_->setMovable(False);
  mainToolBar_->toggleViewAction()->setVisible(False);
	// (Due to Qt quirk, if we allowed the user to hide all
	// toolbars s\he couldn't get them back again!...)

  
  ddOpenAct_ ->setIcon(QIcon(":/icons/File_Open.png"));
  ddRegAct_  ->setIcon(QIcon(":/icons/DD_Register.png"));
  ddRegBtn_  ->setIcon(QIcon(":/icons/DD_Register.png"));
  ddCloseAct_->setIcon(QIcon(":/icons/File_Close.png"));
  ddCloseBtn_->setIcon(QIcon(":/icons/File_Close.png"));
  ddAdjAct_  ->setIcon(QIcon(":/icons/DD_Adjust.png"));
  dpNewAct_  ->setIcon(QIcon(":/icons/DP_New.png"));
  dpOptsAct_ ->setIcon(QIcon(":/icons/DP_Options.png"));
  printAct_  ->setIcon(QIcon(":/icons/File_Print.png"));
  dpCloseAct_->setIcon(QIcon(":/icons/File_Close.png"));
  dpQuitAct_ ->setIcon(QIcon(":/icons/File_Quit.png"));
  
  ddOpenAct_ ->setToolTip("Open Data...");
  ddRegBtn_  ->setToolTip("[Un]register Data");
  ddCloseBtn_->setToolTip("Close Data");
  ddAdjAct_  ->setToolTip("Data Display Options");
  dpNewAct_  ->setToolTip("New Display Panel");
  dpOptsAct_ ->setToolTip("Panel Display Options");
  printAct_  ->setToolTip("Print...");
  
  
  ddRegBtn_  ->setPopupMode(QToolButton::InstantPopup);
  ddRegBtn_  ->setAutoRaise(True);
  ddRegBtn_  ->setIconSize(QSize(22,22));
  
  ddCloseBtn_->setPopupMode(QToolButton::InstantPopup);
  ddCloseBtn_->setAutoRaise(True);
  ddCloseBtn_->setIconSize(QSize(22,22));
  
  //bottomToolBar_->setMovable(False);
  //bottomToolBar_->hide();
  // (disabled unless/until something for it to contain).


    
  
  
  // Animation
  
  animDockWidget_->setAllowedAreas(Qt::BottomDockWidgetArea |
				   Qt::TopDockWidgetArea);
  
  animDockWidget_->setFeatures(QDockWidget::DockWidgetMovable |
  			       QDockWidget::DockWidgetFloatable);
	// Prevents closing animator -- retain until there's a 'View'
	// menu making it obvious how to get it back....  (Such a menu also
	// appears via rt-click on toolbars, but user may not know that).
      
  //animDockWidget_setWindowTitle("Animator");
  animDockWidget_->toggleViewAction()->setText("Animator");
	// Identifies this widget in the toolbars' hide/show context menu.
	// Preferred to previous line, which also displays title on
	// the animator itself (not needed).
  
  animDockWidget_->setSizePolicy(QSizePolicy::Minimum,	  // (horizontal)
				 QSizePolicy::Minimum);	  // (vertical)
  animWidget_->setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum); 
  //#dk  For bug submission, was 'min,fixed' 4 dockWidg; notSet 4 animWidg.
  //# Main problem seems to be that dockWidget itself won't do 'fixed'
  //# correctly -- won't size down (or, sometimes, up) to contained
  //# widget's desired size (Qt task 94288, issue N93095).
  
  revTB_ ->setCheckable(True);
  stopTB_->setCheckable(True);
  playTB_->setCheckable(True);
  
  //#dk~ temporary only: no edits allowed here yet.
  frameEdit_->setReadOnly(True);
  rateEdit_ ->setReadOnly(True);
  
  
  animAuxButton_->setText("Full");
	// Puts animator initially in 'Compact' configuration.
  //animAuxButton_->setText("Compact");
	// (This would put it in 'Full' configuration).
  
  setAnimExtrasVisibility_();
	// Hides or shows extra animator widgets according to
	// the 'Compact/Full' button.
  
  animAuxButton_->setToolTip( "Press 'Full' for more animator interface.\n"
			      "Press 'Compact' to hide it." );
  // (...More animator widgets still need these help texts as well...)
  

    
  // Set interface according to the initial gui-independent animation state.
  
  updateAnimUi_();
  
  

   
  
    
  // Connections

    
  // Direct reactions to user interface.
    
  connect(ddOpenAct_, SIGNAL(triggered()),  v_, SLOT(showDataManager()));
  connect(dpOptsAct_, SIGNAL(triggered()),  SLOT(showCanvasManager()));
  connect(anotAct_,  SIGNAL(triggered()),  SLOT(showAnnotatorPanel()));
  connect(ddAdjAct_,  SIGNAL(triggered()),  v_, SLOT(showDataOptionsPanel()));
  connect(printAct_,      SIGNAL(triggered()),  SLOT(showPrintManager()));
  connect(animAuxButton_, SIGNAL(clicked()),    SLOT(toggleAnimExtras_()));
    
  
    // user interface to animator
  
  connect(frameSlider_, SIGNAL(valueChanged(int)), qdp_, SLOT(goTo(int)));
  connect(rateSlider_,  SIGNAL(valueChanged(int)), qdp_, SLOT(setRate(int)));
  connect(normalRB_,    SIGNAL(toggled(bool)),     qdp_, SLOT(setMode(bool)));
  
  connect(toStartTB_, SIGNAL(clicked()),  qdp_, SLOT(toStart()));
  connect(revStepTB_, SIGNAL(clicked()),  qdp_, SLOT(revStep()));
  connect(revTB_, SIGNAL(clicked()),      qdp_, SLOT(revPlay()));
  connect(stopTB_, SIGNAL(clicked()),     qdp_, SLOT(stop()));
  connect(playTB_, SIGNAL(clicked()),     qdp_, SLOT(fwdPlay()));
  connect(fwdStep_, SIGNAL(clicked()),    qdp_, SLOT(fwdStep()));
  connect(toEndTB_, SIGNAL(clicked()),    qdp_, SLOT(toEnd()));
    
  
  // Reaction to signals from the basic graphics panel, qdp_. 
  // (qdp_ doesn't know about, and needn't necessarily use, this gui).
  
    // From tracking
  
  connect( qdp_, SIGNAL(trackingInfo(Record)),
                   SLOT(displayTrackingData_(Record)) );
  
    
    // From animator
  
  connect( qdp_, SIGNAL(animatorChange()),  SLOT(updateAnimUi_()) );
  
    
    // From registration

  connect( qdp_, SIGNAL(registrationChange()),  SLOT(ddRegChange_()) );
  
}



QtDisplayPanelGui::~QtDisplayPanelGui() {
  if(qpm_!=0) delete qpm_;
  delete qdp_;	// (probably unnecessary because of Qt parenting...)
		// (possibly wrong, for same reason?...).
}




// Animation slots.

void QtDisplayPanelGui::updateAnimUi_() {
  // This slot monitors the QtDisplayPanel::animatorChange() signal, to
  // keep the animator user interface ('view') in sync with that 'model'
  // (QtDisplayPanel's animator state).  It assumes that the animator
  // model is in a valid state (and this routine should not emit signals
  // that would cause state-setting commands to be fed back to that model).

  // Prevent the signal-feedback recursion mentioned above.
  // (The signal used from text boxes is only emitted on user edits).
  Bool nrbSav = normalRB_->blockSignals(True),
       brbSav = blinkRB_->blockSignals(True),
       rslSav = rateSlider_->blockSignals(True),
       fslSav = frameSlider_->blockSignals(True);
  
  // Current animator state.
  Int  frm   = qdp_->frame(),       len  = qdp_->nFrames(),
       strt  = qdp_->startFrame(),  lst  = qdp_->lastFrame(),
       stp   = qdp_->step(),        rate = qdp_->animRate(),
       minr  = qdp_->minRate(),     maxr = qdp_->maxRate(),
       play  = qdp_->animating();
  Bool modez = qdp_->modeZ();
  

  frameEdit_->setText(QString::number(frm));
  nFrmsLbl_ ->setText(QString::number(len));
  
  if(modez) normalRB_->setChecked(True);
  else blinkRB_->setChecked(True);
	// NB: QRadioButton::setChecked(false)  doesn't work
	// (not what we want here anyway).
  
  rateSlider_->setMinimum(minr);
  rateSlider_->setMaximum(maxr);
  rateSlider_->setValue(rate);
  rateEdit_  ->setText(QString::number(rate));
  
  frameSlider_->setMinimum(0);
  frameSlider_->setMaximum(len-1);
  //frameSlider_->setMinimum(strt);
  //frameSlider_->setMaximum(lst);
  frameSlider_->setValue(frm);
  
  stFrmEdit_ ->setText(QString::number(strt));
  lstFrmEdit_->setText(QString::number(lst));
  stepEdit_  ->setText(QString::number(stp));
  
  
  
  // Enable interface according to number of frames.
  
  // enabled in any case:
  modeGB_->setEnabled(True);		// Blink mode
  animAuxButton_->setEnabled(True);	// 'Compact/Full' button.
  rateLbl_->setEnabled(True);		// 
  rateSlider_->setEnabled(True);	// Rate controls.
  rateEdit_->setEnabled(True);		//
  perSecLbl_->setEnabled(True);		//
  
  // Enabled only if there is more than 1 frame to animate:
  Bool multiframe = (len > 1);
  
  rateLbl_->setEnabled(multiframe);	// 
  rateSlider_->setEnabled(multiframe);	// Rate controls.
  rateEdit_->setEnabled(multiframe);	//
  perSecLbl_->setEnabled(multiframe);	//
  
  stFrmEdit_->setEnabled(multiframe);	// first and last frames.
  lstFrmEdit_->setEnabled(multiframe);	// to include in animation.
  stepEdit_->setEnabled(multiframe);	// animation step.
  toStartTB_->setEnabled(multiframe);	//
  revStepTB_->setEnabled(multiframe);	//
  revTB_->setEnabled(multiframe);	//
  stopTB_->setEnabled(multiframe);	// Tape deck controls.
  playTB_->setEnabled(multiframe);	//
  fwdStep_->setEnabled(multiframe);	//
  toEndTB_->setEnabled(multiframe);	//
  frameEdit_->setEnabled(multiframe);	// Frame number entry.
  nFrmsLbl_->setEnabled(multiframe);	// Total frames label.
  curFrmLbl_->setEnabled(multiframe);	//
  frameSlider_->setEnabled(multiframe);	// Frame number slider.
  stFrmLbl_->setEnabled(multiframe);	//
  stFrmEdit_->setEnabled(multiframe);	// first and last frames
  lstFrmLbl_->setEnabled(multiframe);	// to include in animation
  lstFrmEdit_->setEnabled(multiframe);	// and animation step.
  stepLbl_->setEnabled(multiframe);	//
  stepEdit_->setEnabled(multiframe);	//
  
  
  //#dk  (For now, always disable the following animator
  //      interface, because it is not yet fully supported).
 
  stFrmLbl_->setEnabled(False);		// 
  stFrmEdit_->setEnabled(False);	// 
  lstFrmLbl_->setEnabled(False);	// first and last frames
  lstFrmEdit_->setEnabled(False);	// to include in animation,
  stepLbl_->setEnabled(False);		// and animation step.
  stepEdit_->setEnabled(False);		// 
  
  // (These work now)  
  //modeGB_->setEnabled(False);		// Blink mode.
  //rateLbl_->setEnabled(False);	//
  //rateSlider_->setEnabled(False);	// Timed animation:
  //rateEdit_->setEnabled(False);	// rate controls,...
  //perSecLbl_->setEnabled(False);	// 
  //revTB_->setEnabled(False);		// 
  //playTB_->setEnabled(False);		// 

  
  revTB_ ->setChecked(play<0);
  stopTB_->setChecked(play==0);
  playTB_->setChecked(play>0);
  
  
  // restore signal-blocking state (unblocked, in all likelihood).
  
  normalRB_->blockSignals(nrbSav),
  blinkRB_->blockSignals(brbSav),
  rateSlider_->blockSignals(rslSav),
  frameSlider_->blockSignals(fslSav);  

}





// Public slots: may be safely operated programmatically (i.e., scripted,
// when available), or via gui actions.


void QtDisplayPanelGui::showPrintManager() {
  if(qpm_==0) qpm_ = new QtViewerPrintGui(qdp_);
  qpm_->showNormal();	// (Magic formula to bring a window up,
  qpm_->raise();  }	// normal size, whether 'closed' (hidden),
			// iconified, or merely obscured by other 
			// windows.  (Found through trial-and-error).

void QtDisplayPanelGui::hidePrintManager() {
  if(qpm_==0) return;
  qpm_->hide();  }

    
void QtDisplayPanelGui::showCanvasManager() {
  if(qcm_==0) qcm_ = new QtCanvasManager(qdp_);
  qcm_->showNormal();
  qcm_->raise();
}

void QtDisplayPanelGui::hideCanvasManager() {
  if(qcm_==0) return;
  qcm_->hide();  
}


    
void QtDisplayPanelGui::showAnnotatorPanel() {
  //if(qap_==0) qap_ = new QtAnnotatorGui(qdp_);
  //qap_->showNormal();
  //qap_->raise();
}

void QtDisplayPanelGui::hideAnnotatorPanel() {
  if(qap_==0) return;
  qap_->hide();  
}



// Other Internal slots and methods.
  
  
  
void QtDisplayPanelGui::displayTrackingData_(Record trackingRec) {
  // Display tracking data gathered by underlying panel.
  
  // cerr<<"nm:"<<trackingRec.name(0)<<			//#diag
  //       " "<<trackingRec.asString(0)<<endl;		//#diag
  if(trackingRec.nfields()>0u) {
    trkgWidget_->setTitle(   trackingRec.name(0).chars() );
    trkgEdit_->setPlainText( trackingRec.asString(0).chars() );  }  }
	// Initial try: only first-registered tracking data shown.
  

  
void QtDisplayPanelGui::toggleAnimExtras_() {
  if(animAuxButton_->text()=="Full") animAuxButton_->setText("Compact");
  else				     animAuxButton_->setText("Full");  
  setAnimExtrasVisibility_();  }

        
void QtDisplayPanelGui::setAnimExtrasVisibility_() {
  if(animAuxButton_->text()=="Full") {
    animAuxFrame_->hide(); modeGB_->hide();  }
  else {
    animAuxFrame_->show(); modeGB_->show();
    animAuxButton_->setText("Compact");  }  }

        


// Reactors to QDP registration status changes.



void QtDisplayPanelGui::updateDDMenus_(Bool doCloseMenu) {
  // Re-populates regMenu_ with actions.  If doCloseMenu is
  // True (on DD create/close), also recreates ddCloseMenu_.
  // (For now, both menus are always recreated).

  ddRegMenu_->clear();  ddCloseMenu_->clear();
  
  List<QtDisplayData*> regdDDs   = qdp_->registeredDDs();
  List<QtDisplayData*> unregdDDs = qdp_->unregisteredDDs();
  
  Bool anyRdds = regdDDs.len()>0u,   anyUdds = unregdDDs.len()>0u,
       manydds = regdDDs.len() + unregdDDs.len() > 1u; 

  QAction* action = 0;

  // The following allows slots to distinguish the dd associated with
  // triggered actions (Qt actions and signals are somewhat deficient in
  // their ability to make distinctions of this sort, imo).
  // Also note the macro at the end of QtDisplayData.qo.h, which enables
  // QtDisplayData* to be a QVariant's value.
  QVariant ddv;		// QVariant wrapper for a QtDisplayData pointer.
    
  
  // For registered DDs:...
  
  for(ListIter<QtDisplayData*> rdds(regdDDs); !rdds.atEnd(); rdds++) {
    QtDisplayData* rdd = rdds.getRight();
    
    ddv.setValue(rdd);
    
    
    // 'Unregister' menu item for dd.
    
    // Note: the explicit parenting means that the Action will
    // be deleted on the next ddRegMenu_->clear().
    
    action = new QAction(rdd->name().chars(), ddRegMenu_);
    
    action->setCheckable(True);
    action->setChecked(True);
    action->setData(ddv);	// Associate the dd with the action.
    ddRegMenu_->addAction(action);
    connect(action, SIGNAL(triggered()), SLOT(ddUnregClicked_()));

    
    // 'Close' menu item.
    
    action = new QAction( ("Close "+rdd->name()).chars(), ddCloseMenu_ );
    action->setData(ddv);
    ddCloseMenu_->addAction(action);
    connect(action, SIGNAL(triggered()), SLOT(ddCloseClicked_()));  }

  
  if(anyRdds && anyUdds) {
    ddRegMenu_->addSeparator();
    ddCloseMenu_->addSeparator();  }  

    
  // For unregistered DDs:...
  
  for(ListIter<QtDisplayData*> udds(unregdDDs); !udds.atEnd(); udds++) {
    QtDisplayData* udd = udds.getRight();
    
    ddv.setValue(udd);
    
    
    // 'Unregister' menu item.
    
    action = new QAction(udd->name().chars(), ddRegMenu_);
    action->setCheckable(True);
    action->setChecked(False);
    action->setData(ddv);
    ddRegMenu_->addAction(action);
    connect(action, SIGNAL(triggered()), SLOT(ddRegClicked_()));
    
    
    // 'Close' menu item.
    
    action = new QAction(("Close "+udd->name()).chars(), ddCloseMenu_);
    action->setData(ddv);
    ddCloseMenu_->addAction(action);
    connect(action, SIGNAL(triggered()), SLOT(ddCloseClicked_()));  }
  
  
  // '[Un]Register All' / 'Close All'  menu items.
  
  if(manydds) {
    
    ddRegMenu_->addSeparator();

    if(anyUdds) {
      action = new QAction("Register All", ddRegMenu_);
      ddRegMenu_->addAction(action);
      connect(action, SIGNAL(triggered()),  qdp_, SLOT(registerAll()));  }

    if(anyRdds) {
      action = new QAction("Unregister All", ddRegMenu_);
      ddRegMenu_->addAction(action);
      connect(action, SIGNAL(triggered()),  qdp_, SLOT(unregisterAll()));  }

    
    ddCloseMenu_->addSeparator();
    
    action = new QAction("Close All", ddCloseMenu_);
    ddCloseMenu_->addAction(action);
    connect(action, SIGNAL(triggered()),  v_, SLOT(removeAllDDs()));  }  }
    




void QtDisplayPanelGui::updateTrackBoxes_() {
  // Reacts to QDP registration change signal to change, if necessary,
  // the (ordered) set of cursor position tracking boxes.  There will
  // be a track box for each QDD in QtDisplayPanel::registeredDDs(),
  // in the same order, except that annotation-type DDs (which don't
  // provide tracking data) are eliminated.
  trkgEdit_->clear();
  trkgWidget_->setTitle("");
}
    
    
        

// Slots to respond to registration/close menu clicks.


void QtDisplayPanelGui::ddRegClicked_() {

  // Retrieve the dd associated with the signal.
  
  QAction* action = dynamic_cast<QAction*>(sender());
  if(action==0) return;		// (shouldn't happen).
  QtDisplayData* dd = action->data().value<QtDisplayData*>();
  
  qdp_->registerDD(dd);  }  


void QtDisplayPanelGui::ddUnregClicked_() {
  QAction* action = dynamic_cast<QAction*>(sender());
  if(action==0) return;		// (shouldn't happen).
  QtDisplayData* dd = action->data().value<QtDisplayData*>();
  
  qdp_->unregisterDD(dd);  }  


void QtDisplayPanelGui::ddCloseClicked_() {
  QAction* action = dynamic_cast<QAction*>(sender());
  if(action==0) return;		// (shouldn't happen).
  QtDisplayData* dd = action->data().value<QtDisplayData*>();

  v_->removeDD(dd);  }  

 

} //# NAMESPACE CASA - END

