//# QtDataOptionsPanel.cc: Qt implementation DD options adjustment window
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
//# $Id: QtDataOptionsPanel.cc,v 1.4 2006/08/30 20:16:07 dking Exp $

#include <casa/BasicSL/String.h>
#include <display/QtViewer/QtDataOptionsPanel.qo.h>
#include <display/QtViewer/QtViewer.qo.h>
#include <display/QtViewer/QtDisplayDataGui.qo.h>


namespace casa { //# NAMESPACE CASA - BEGIN


QtDataOptionsPanel::QtDataOptionsPanel(QtViewer* v, QWidget* parent) :
		    QWidget(parent), v_(v)  {
    
  setWindowTitle("Viewer Data Options Panel");
  
  setupUi(this);  
    
  //#dk tabs_->setFixedWidth(585);
  //#dk tabs_->setMinimumHeight(600);
  //setMinimumWidth(570);		//#dk
  //setMinimumHeight(600);	//#dk
  // setMinimumWidth(200);			//#dk
  // setMinimumHeight(200);		//#dk
  tabs_->setMinimumWidth(350);	//#dk
  tabs_->setMinimumHeight(150);	//#dk
  //#dk with auto-app:    resize(595, 705);		//#dk
  // resize(510, 705);			//#dk
  resize(525, 705);			//#dk
  
  //if(tabs_->layout()==0) new QVBoxLayout(tabs_);	//#dk
  //cerr<<"CDO:tabs->lay:"<<tabs_->layout()<<endl;	//#diag
  //tabs_->layout()->setSizeConstraint(QLayout::SetFixedSize);	//#dk
	// does no good because you cant add tabs_'s children to the layout).
  
  // if(layout()!=0) layout()->setSizeConstraint(QLayout::SetFixedSize); //#dk
  
  
  while(tabs_->count()>0) tabs_->removeTab(0);
	// (Qt designer insists on putting some tabs in my
	// TabWidget, whether I want them there yet or not...).
  
  List<QtDisplayData*> ddlist(v->dds());
  for (ListIter<QtDisplayData*> qdds(ddlist); !qdds.atEnd(); qdds++) {
    createDDTab_(qdds.getRight());  }
	// These are the tabs I _really_ want....
  
  
  connect( v_, SIGNAL(ddCreated(QtDisplayData*)),
		 SLOT(createDDTab_(QtDisplayData*)) );
  
  connect( v_, SIGNAL(ddRemoved(QtDisplayData*)),
		 SLOT(removeDDTab_(QtDisplayData*)) );  }


QtDataOptionsPanel::~QtDataOptionsPanel() { }
	// (elaboration probably unnecessary because of Qt parenting...)


// Slots for QDD creation/destruction.

void QtDataOptionsPanel::createDDTab_(QtDisplayData* qdd) {
  
  QtDisplayDataGui* qddg = new QtDisplayDataGui(qdd);

  //cerr<<"QDO:crT:nT:"<<tabs_->count()<<" nm:"<<qdd->nameChrs();  //#diag

  //cerr<<"QDO:crTb:tbs.szHnt:"<<tabs_->sizeHint().width()<<","
  //<<tabs_->sizeHint().height()<<endl;	//#diag

  QScrollArea* sca = new QScrollArea;
  sca->setWidget(qddg);
  
  tabs_->addTab(sca, qdd->nameChrs());

  tabs_->setTabToolTip(tabs_->indexOf(sca), qdd->nameChrs());
  tabs_->show();  }


  
void QtDataOptionsPanel::removeDDTab_(QtDisplayData* qdd) {
  
  for(Int i=0; i<tabs_->count(); i++) {
  
    if(tabs_->tabText(i) == qdd->nameChrs()) {
    
      QScrollArea* sca = dynamic_cast<QScrollArea*>(tabs_->widget(i));
      
      tabs_->removeTab(i);	// (NB: does not delete sca).
    
      if(sca!=0) delete static_cast<QtDisplayDataGui*>(sca->widget());
	// This may be unnecessary, since sca is the parent, but I want
	// to assure that the QDDG is fully deleted (~QWigdet is not
	// virtual... hmm...).
    
      delete sca;
    
      break;  }  }  }


//void QtDataOptionsPanel::paintEvent ( QPaintEvent * event ) {
//  resize(sizeHint());  }
	//#dk hye-type trick (a very suspect action for a paintEvent....
	//#dk I have seen it cause some (but not infinite) recursion).

void QtDataOptionsPanel::resizeEvent (QResizeEvent* ev) {	//#diag
//  cerr<<"DOPrsz x:"<<ev->size().width()<<" y:"<<ev->size().height()<<endl;
}				//#diag -- to show size.



} //# NAMESPACE CASA - END




// w/o scroll

/*  

void QtDataOptionsPanel::createDDTab_(QtDisplayData* qdd) {
  
  QtDisplayDataGui* qddg = new QtDisplayDataGui(qdd);

//cerr<<"QDO:crT:nT:"<<tabs_->count()<<" nm:"<<qdd->nameChrs();	//#diag
cerr<<"QDO:crTb:tbs.szHnt:"<<tabs_->sizeHint().width()<<","
<<tabs_->sizeHint().height()<<endl;	//#diag
  
  tabs_->addTab(qddg, qdd->nameChrs());

//cerr<<" ind:"<<tabs_->indexOf(qddg)<<" qddg:"<<qddg<<	//#diag
//" widg:"<<tabs_->widget(tabs_->indexOf(qddg))<<endl;	//#diag
cerr<<"                   "<<tabs_->sizeHint().width()<<","
<<tabs_->sizeHint().height()<<endl;	//#diag
cerr<<"             outer:"<<sizeHint().width()<<","
<<sizeHint().height()<<endl;	//#diag
  
  tabs_->setTabToolTip(tabs_->indexOf(qddg), qdd->nameChrs());
  tabs_->show();  }

  
void QtDataOptionsPanel::removeDDTab_(QtDisplayData* qdd) {
  for(Int i=0; i<tabs_->count(); i++) {
    if(tabs_->tabText(i)==qdd->nameChrs()) {
      //QtDisplayDataGui* qddg = dynamic_cast<QtDisplayDataGui*>
      QtDisplayDataGui* qddg = static_cast<QtDisplayDataGui*>
			       (tabs_->widget(i));
//cerr<<"QDOrmTb qddg:"<< qddg<<" i:"<<i<<" widg:"<<tabs_->widget(i)<<
//endl;	//#diag
      tabs_->removeTab(i);
      if(qddg!=0) delete qddg;
      break;  }  }  }
*/



// original hye -- from his qtv  main 


/* 
  
  if(qdd!=0) {
 
    //old-style (?)
    //QtAdjustment adjust(qdd);
    //adjust.show(); 

    
    // naked
    QtAutoGui* tl2 = new QtAutoGui(qdd->getOptions());
    tl2->show();
     
    // tab only
    QtAutoGui* qddg = new QtAutoGui(qdd->getOptions());
    QTabWidget *tabs_ = new QTabWidget;
    tabs_->setFixedWidth(585);
    tabs_->setMinimumHeight(800);
    tabs_->setTabPosition(QTabWidget::North);
    tabs_->addTab(qddg, QString::fromStdString(filename));  
    tabs_->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Expanding); 
    tabs_->show();
    
    //scroll + tab
    QtAutoGui* tl = new QtAutoGui(qdd->getOptions());    
    QScrollArea*   scrollArea = new QScrollArea;
    //scrollArea->setBackgroundRole(QPalette::Light);
    scrollArea->setWidget((QWidget*)tl);
    scrollArea->setWidgetResizable(True);	//#dk
    QTabWidget *tab = new QTabWidget;
//    tab->setFixedWidth(605);
//    tab->setMinimumHeight(450);
    tab->setMinimumWidth(205);	//#dk
    tab->setMinimumHeight(250);	//#dk
    tab->setTabPosition(QTabWidget::North);
    tab->addTab(scrollArea, QString::fromStdString(filename));  
    tab->show();
   
   
//* /    
  
    // tab only
    QtAutoGui* qddg = new QtAutoGui(qdd->getOptions());
    QTabWidget *tabs_ = new QTabWidget;
    tabs_->setTabPosition(QTabWidget::North);
    tabs_->addTab(qddg, QString::fromStdString(filename));  
    //QVBoxLayout* lo = new QVBoxLayout;	//#dk
    //lo->addWidget(qddg);
    //tabs_->setLayout(lo);
    qddg->setSizePolicy( QSizePolicy::Fixed, 
    	QSizePolicy::Expanding);	//#dk
    //#dk qddg->setSizePolicy(QSizePolicy::Fixed, 
    //#dk 		     QSizePolicy::Fixed); 	//#dk
    tabs_->setFixedWidth(585);
    tabs_->setMinimumHeight(600);
    //#dk tabs_->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Expanding); 
    //#dk tabs_->setSizePolicy(QSizePolicy::MinimumExpanding, 
    //#dk 		QSizePolicy::MinimumExpanding); 	//#dk
    //tabs_->setSizePolicy(QSizePolicy::Fixed, 
    //		       QSizePolicy::Fixed); 	//#dk
    
    tabs_->show();
    
  }
 
*/

