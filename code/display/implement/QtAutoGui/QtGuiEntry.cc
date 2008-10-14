//# QtGuiEntry.cc: Individual interface elements for general-purpose
//#                Qt options widget (QtAutoGui).
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
//#

#include <casa/iostream.h>
#include "QtGuiEntry.qo.h"
#include "QtAutoGui.qo.h"

#include <graphics/X11/X_enter.h>
#  include <QtCore> 
#  include <QtGui>
#include <graphics/X11/X_exit.h>

namespace casa { //# NAMESPACE CASA - BEGIN


extern QString clipBoard;



// ///////////////////// QtSliderBase ///////////////////////////////////


void QtSliderBase::constructBase(QDomElement& ele,  QSlider* slider,
				 QLabel* nameLabel, QToolButton* menuBtn) {
  // Derived class should call this within its constructor, after it
  // has a valid QSlider, name QLabel and menu QToolButton (usually,
  // after calling setUi()), passing them down in parameters below.

  slider_   = slider;
  nameLabel_= nameLabel;	// Relevant Qt widgets.
  menuBtn_  = menuBtn;		// derived class creates these.
  
  itemName = ele.tagName();
	// ("dlformat" -- widget name for internal identification
	//  and communication -- this won't change).
	
  slider_->setPageStep(1);	// (singleStep is already 1 by default).
  
  floatrng_ = ele.attribute("ptype") == "floatrange";
	// Whether widget should emit float or integer values.
  
  QMenu*   mn      = new QMenu;  
  QAction* origAct = new QAction("Original", this);
  mn->addAction(origAct);
  menuBtn_->setMenu(mn);
  connect(menuBtn_, SIGNAL(clicked()),  menuBtn_, SLOT(showMenu()) );

  connect(slider_, SIGNAL(valueChanged(int)),     SLOT(slChg(int)) );
  connect(origAct, SIGNAL(activated()),           SLOT(setOriginal()));

  // Store main state.
 
  dVal_ = dMin_ = dMax_ = 0.;  dIncr0_ = 1.;
	// Default values in case nothing else is provided in ele.

  reSet(ele);	// validate and set main internal state,
  		// according to options record.
  
  origVal_=dVal_;  }
	// Save 'original' value, for restore via 'original' menu.
  
  
void QtSliderBase::reSet(QDomElement& ele) {
  // set up main internal state and external appearance of this widget,
  // according to options record (passed as a QDomElement).  For sliders,
  // this includes value, min, max, slider increment, label and help
  // text.  In ele, these will be the attributes "value", "pmin", "pmax",
  // "presolution", "listname" and "help", respectively.
  // State not specified in ele is left unchanged (if possible).
  // But whether passed or defaulted, numeric state (min, value, max, incr)
  // must be self-consistent; it will be altered to make it so if not.
  //
  // This method just sets the widget's state and appearance, _without_
  // triggering signals caught by this class, nor the class's output
  // signal (itemValueChanged).  It is intended to sync this interface
  // with library internal state (not vice versa).

  QString attr;
  attr = ele.attribute("listname");
  if(!attr.isNull()) nameLabel_->setText(attr);
  attr = ele.attribute("help");
  if(!attr.isNull()) nameLabel_->setToolTip(attr);
	// Widget label and help, as the gui user should see it.
  
  // fetch main numeric state from ele, if it exists there.
  getAttr(ele, "value",       dVal_);
  getAttr(ele, "pmin",        dMin_);
  getAttr(ele, "pmax",        dMax_);
  getAttr(ele, "presolution", dIncr0_);
   
  // Assure validity/robustness of that state (will do nothing
  // in most cases, given well-behaved input from ele).
  if(dIncr0_ <  0.) dIncr0_ = -dIncr0_;
  if(dIncr0_ == 0.) dIncr0_ = 1.;
  if(dMin_ > dMax_) { Double tmp=dMin_; dMin_=dMax_; dMax_=tmp;  }
  if(dMin_ > dVal_) dMin_ = dVal_;
  if(dMax_ < dVal_) dMax_ = dVal_; 

   
  adjSlIncr();	// Adjust integer slider range (slMax_) and the increment
		// that each unit on slider represents (dIncr_).
  updateText();		// Set initial values onto value entry/label
  updateSlider();  }	// and slider.
  

  
QString QtSliderBase::toText(Double val) {
  //cerr<<"2txt:dv:"<<val<<" num(v):**"<<		//#diag
  //QString::number(val).toStdString()<<endl;		//#diag
  if(!floatrng_) return QString::number(round(val));
  if(fabs(val/dIncr_) < 1e-4) return "0";
  return QString::number(val);  }

  
Double QtSliderBase::toNumber(QString text, bool* ok) {
  if(floatrng_) { 
    text.toFloat(ok);		// (Validate for Float range,
    return text.toDouble();  }	// but retain Double accuracy).
  return Double(text.toInt(ok));  }

  
void QtSliderBase::adjSlIncr() {
  // Adjusts integer slider range (slMax_) and the increment each
  // unit on the slider represents (dIncr_), according to latest
  // increment and range request (dIncr0_,  dMin_, dMax_).
  dIncr_ = dIncr0_;
  while((slMax_ = ceil((dMax_-dMin_)/dIncr_)) > INT_MAX) dIncr_*=10.;  
	//# (Assures increment is not too small for integer range).

  if (abs(dMax_-dMin_) < 1){
     while((slMax_ = ceil((dMax_-dMin_)/dIncr_)) < 10) dIncr_/=10.;
  }
}


void QtSliderBase::updateSlider() {
  // Sets slider to latest range and value (without
  // triggering slider signals or slChg slot below). 
  Bool restore = slider_->blockSignals(True);	// Prevent signal recursion.
   slider_->setMinimum(0);			// (Always at this value).
   slider_->setMaximum(Int(slMax_));
   slider_->setSliderPosition(sliderVal(dVal_));
  slider_->blockSignals(restore);  }	// signals (presumably) back on.
    
  
void QtSliderBase::emitVal() {
  // emit current value -- this is the widget's main output.
  emit itemValueChanged(itemName, textVal(),    QtAutoGui::Set, True);  }

 
void QtSliderBase::updateAndEmit(Double dval) {
  // Sets the new value (which should already be validated), 
  // updates user interface accordingly, (without retriggering any
  // internal slots), and emits the new value.
    dVal_ = dval;		// Accept new value.
    updateText();		// 'Normalize' text version on ui.
    updateSlider();		// update slider.
    emitVal();  }		// Send out new value.


void QtSliderBase::setOriginal() {
  // Triggered when 'revert-to-original' is selected from 'wrench' menu.
  
  // In this version, slider limits cannot be changed via 'Original'.
  Double dval = min(dMax_, max(dMin_, origVal_));
  
  if(dval!=dVal_) updateAndEmit(dval);  }
  
  
  
void QtSliderBase::getAttr(const QDomElement& ele,
			   QString attnm, Double& val) {
  // Fetch numeric value of attribute of ele named attnm, into val. 
  // Does nothing if attr doesn't exist or is not valid numerically.
  Bool ok;  Double d;
  QString strval = ele.attribute(attnm);
  if(strval.isNull()) return; 
  d = toNumber(strval, &ok);
  
  if(ok) val = d;  }
  

  
// ///////////////////// QtSliderEditor ///////////////////////////////////
  
QtSliderEditor::QtSliderEditor(QDomElement& ele, QWidget *parent) 
	      : QtSliderBase(parent) {
  setupUi(this);		// Creates ui widgets such as slider.
  constructBase(ele, slider, nameLabel, tool);	// sets up base class.
  radioButton->hide();	//#dk
  connect(lineEdit, SIGNAL(editingFinished()),  SLOT(edited()) );  }


void QtSliderEditor::textChg(QString strval)  {
  
  // Validate and normalize strval, update interface accordingly,
  // emit value change signal, as necessary.
  
  Bool ok;
  Double dval = toNumber(strval, &ok);

  if(!ok) {
    updateText();	// Resets text box to last valid value.
    emit errMsg("Invalid numeric input -- please re-enter.");
    return;  }
  
  if(dval==dVal_) { 
    updateText();	// No value change: renormalize text, but no
    return;  }		// need for signals or other adjustments.

  if     (dval<dMin_) { dMin_=dval; adjSlIncr();  }
  else if(dval>dMax_) { dMax_=dval; adjSlIncr();  }
	// Re-adjust integer slider range according to
	// new external range, if it has expanded.
  
  // Accept new value.  Update interface accordingly,
  // and emit the new value.
  
  updateAndEmit(dval);  }



// /////////////////////// QtSliderLabel ///////////////////////////////////

QtSliderLabel::QtSliderLabel(QDomElement& ele, QWidget *parent) 
	     : QtSliderBase(parent) {
  setupUi(this);		    // Creates ui widgets such as slider.
  radioButton->hide();	//#dk
  constructBase(ele, slider, nameLabel, tool);  }  // sets up base class.

  
void QtSliderLabel::updateText() {
  // Sets value label to (normalized) current value.
  // indents to keep numeric label over slider button.
  
  Int indent = 0,  width = posLabel->width();
  if(dMax_>dMin_) {
    indent = round( width * (dVal_-dMin_)/(dMax_-dMin_) );  }
  
  posLabel->setText(textVal());
  
  if(2*indent <= width) {      
    posLabel->setAlignment(Qt::AlignLeft);
    posLabel->setIndent(indent);  }   
  else {
    posLabel->setAlignment(Qt::AlignRight);      
    posLabel->setIndent((width - indent));  }
      
  posLabel->repaint();  }	// (for less delay in following slider).


  

//////////////////// QtMinMaxEditor ////////////////////////////////////////

QtMinMaxEditor::QtMinMaxEditor(QWidget *parent) :
        QWidget(parent), blockSignal(false)
{
    setupUi(this);
    radioButton->hide();	//#dk
}

QtMinMaxEditor::QtMinMaxEditor(QDomElement &ele, QWidget *parent)
              : QWidget(parent)
{

    setupUi(this);
    radioButton->hide();	//#dk
    itemName = ele.tagName();
    connect(lineEdit, SIGNAL(editingFinished()), this, SLOT(display2()));
    //connect(lineEdit, SIGNAL(textChanged(QString)),
    //        this, SLOT(display2(QString)) );
    connect(hist, SIGNAL(clicked()), this, SLOT(setHistogram()) );
    connect(tool, SIGNAL(clicked()), tool, SLOT(showMenu()) );
    
    hist->hide();	//#dk -- until this button does something...


    //#dk double d2 = ele.attribute("pmax").toDouble();
    //#dk double d1 = ele.attribute("pmin").toDouble();


    lineEdit->setText(ele.attribute("value"));
    nameLabel->setText(ele.attribute("listname", "noname"));
    nameLabel->setToolTip(ele.attribute("help"));
    QMenu *mn = new QMenu;
    QAction *origAct = new QAction("Original", this);
    connect(origAct, SIGNAL(activated()), this, SLOT(setOriginal()));
    mn->addAction(origAct);
    QAction *dfltAct = new QAction("default", this);
    connect(dfltAct, SIGNAL(activated()), this, SLOT(setDefault()));
    mn->addAction(dfltAct);
    QAction *copyAct = new QAction("Copy", this);
    connect(copyAct, SIGNAL(activated()), this, SLOT(setCopy()));
    mn->addAction(copyAct);
    QAction *pasteAct = new QAction("Paste", this);
    connect(pasteAct, SIGNAL(activated()), this, SLOT(setPaste()));
    mn->addAction(origAct);
    mn->addAction(dfltAct);
    mn->addAction(copyAct);
    mn->addAction(pasteAct);
    tool->setMenu(mn);
    //std::cout << "create slider editor item" << std::endl;
}

void QtMinMaxEditor::reSet(QString value)
{
    //#dk cout << "--reset " << itemName.toStdString()
    //#dk << "=" << value.toStdString() << endl;
    repaint();
}

void QtMinMaxEditor::display2(int v1)
{  }

void QtMinMaxEditor::display2()
{
    QString value = lineEdit->text();
    //cout << "mimmaxhist value=" << value.toStdString() << endl;
    display2(value);
}

void QtMinMaxEditor::display2(QString value)
{
    if (!validate(value))
        return;
}

bool QtMinMaxEditor::validate(QString value)
{
    // cout << "mimmaxhist value=" << value.toStdString() << endl;

    bool ok1, ok2;
    QString str = value.replace(QString("["), "");
    str.replace(QString("]"), QString(""));
    QStringList list = str.split(",");
    if (list.size() != 2)
    {
        labelOk->setPixmap(QPixmap(QString::fromUtf8(":/icons/cross.xbm")));
        return false;
    }
    double d1 = list[0].toDouble(&ok1) ;
    double d2 = list[1].toDouble(&ok2);

    if (ok1 == true && ok2 == true && d1 < d2)
    {
        //cout << "mimmaxhist d2=" << d2 <<  " d1=" << d1 << endl;
        lineEdit->setText("[" + QString::number(d1) + ", "
                          + QString::number(d2) + "]");
        emit  itemValueChanged(itemName, lineEdit->text(),
                               QtAutoGui::Set, radioButton->isChecked());
        labelOk->setPixmap(QPixmap(":/icons/tick.xbm"));
        return true;
    }
    else
        labelOk->setPixmap(QPixmap(QString::fromUtf8(":/icons/cross.xbm")));
    return false;
}

void QtMinMaxEditor::setOriginal()
{
    emit  itemValueChanged(itemName, lineEdit->text(), QtAutoGui::Original,
                           radioButton->isChecked());
}

void QtMinMaxEditor::setDefault()
{
    emit  itemValueChanged(itemName, lineEdit->text(), QtAutoGui::Default,
                           radioButton->isChecked());
}

void QtMinMaxEditor::setCopy()
{
    clipBoard =  lineEdit->text();
}

void QtMinMaxEditor::setPaste()
{
    if(validate(clipBoard))
    {
        display2(clipBoard);
    }
}

void QtMinMaxEditor::setHistogram()
{
    emit  itemValueChanged(itemName, "Show histogram plot", QtAutoGui::Command,
                           radioButton->isChecked());
}

QtMinMaxEditor::~QtMinMaxEditor()
{  }


///////////////////////// QtLineEditor /////////////////////////////////////

QtLineEditor::QtLineEditor(QWidget *parent) :
        QWidget(parent), blockSignal(false)
{
    setupUi(this);
    radioButton->hide();	//#dk
}

QtLineEditor::QtLineEditor(QDomElement &ele, QWidget *parent)
            : QWidget(parent)
{
    setupUi(this);
    radioButton->hide();	//#dk
    itemName = ele.tagName();
    //connect(lineEdit, SIGNAL(textChanged(QString)),
    //                this,SLOT(display2(QString)));
    connect(lineEdit, SIGNAL(editingFinished()),
            this, SLOT(editingFinished()) );
    connect(tool, SIGNAL(clicked()), tool, SLOT(showMenu()) );
    lineEdit->setText(ele.attribute("value"));
    ptype = ele.attribute("ptype");
    nameLabel->setText(ele.attribute("listname", "noname"));
    nameLabel->setToolTip(ele.attribute("help"));
    QMenu *mn = new QMenu;
    QAction *origAct = new QAction("Original", this);
    connect(origAct, SIGNAL(activated()), this, SLOT(setOriginal()));
    mn->addAction(origAct);
    QAction *dfltAct = new QAction("default", this);
    connect(dfltAct, SIGNAL(activated()), this, SLOT(setDefault()));
    mn->addAction(dfltAct);
    QAction *copyAct = new QAction("Copy", this);
    connect(copyAct, SIGNAL(activated()), this, SLOT(setCopy()));
    mn->addAction(copyAct);
    QAction *pasteAct = new QAction("Paste", this);
    connect(pasteAct, SIGNAL(activated()), this, SLOT(setPaste()));
    mn->addAction(origAct);
    mn->addAction(dfltAct);
    mn->addAction(copyAct);
    mn->addAction(pasteAct);
    tool->setMenu(mn);
}

void QtLineEditor::reSet(QString value)
{
    blockSignal = true;
    //#dk cout << "--reset " << itemName.toStdString()
    //#dk << "=" << value.toStdString() << endl;
    repaint();
    blockSignal = false;
}

void QtLineEditor::display2(QString value)
{
   //#dk static int displayCount = 1;
   //#dk cout << "displayCount=" << (displayCount++) << endl;
    //cout << "lineEdit=" << value.toStdString() << endl;
    if (!validate(value))
        return;
   	
    if (!blockSignal)
    emit  itemValueChanged(itemName, lineEdit->text(), QtAutoGui::Set,
                           radioButton->isChecked());
   			   
}

void QtLineEditor::editingFinished()
{
   //#dk  static int finCount = 1;
   //#dk cout << "finCount=" << (finCount++) << endl;
    //cout << "lineEdit=" << lineEdit->text().toStdString()
    //        << (lineEdit->text().isNull() ? "Null" : "not Null") <<  endl;
    
    if (!validate(lineEdit->text()))
        return;
    emit  itemValueChanged(itemName, lineEdit->text(), QtAutoGui::Set,
                           radioButton->isChecked());
}

bool QtLineEditor::validate(QString value)
{
   //#dk static int valiCount = 1;
   //#dk cout << "validCount=" << (valiCount++) << endl;
    if (value.isNull())
    {
        labelOk->setPixmap(QPixmap(QString::fromUtf8(":/icons/cross.xbm")));
        return false;
    }

    if (ptype == "array")
    {
        bool ok = true;
        //cout << "contain both=" << (bool)(value.contains(QRegExp("\\[")) &&
	// value.contains(QRegExp("\\]"))) << endl;
        if (value.count() == 0)
            ok = false;
        if ((value.contains('[') && value.contains(']')) ||
                (!value.contains('[') && !value.contains(']')))
            value.remove('[').remove(']');
        else
             ok = false;

        //if (!(value.contains('(') && value.contains(')')) ||
        //   (!value.contains('(') && !value.contains(')')))
        //     value.remove('(').remove(')');
        //else
        //     ok = false;

        if (!ok)
        {
            labelOk->setPixmap(QPixmap(QString::fromUtf8(":/icons/cross.xbm")));
            return false;
        }

        QStringList poptList;
        poptList = value.split(QRegExp("\\D+"), QString::SkipEmptyParts);

        labelOk->setPixmap(QPixmap(":/icons/tick.xbm"));
        for (int i = 0; i < poptList.size(); i++)
        {
            QString opt = poptList.at(i).simplified();
            opt.toDouble(&ok);
            if (ok == false)
            {
                labelOk->setPixmap(QPixmap(QString::fromUtf8(
                                               ":icons/cross.xbm")));
                return false;
            }
        }
	
        QString modified = "[";
        for (int i = 0; i < poptList.size(); i++)
        {
            modified += ", " + poptList.at(i);
        }
        modified += "]";
        modified.replace("[, ", "[");
        lineEdit->setText(modified);

        return true ;
    }

    return true;
}

void QtLineEditor::setOriginal()
{
    emit  itemValueChanged(itemName, lineEdit->text(), QtAutoGui::Original,
                           radioButton->isChecked());
}

void QtLineEditor::setDefault()
{
    emit  itemValueChanged(itemName, lineEdit->text(), QtAutoGui::Default,
                           radioButton->isChecked());
}

void QtLineEditor::setCopy()
{
    clipBoard =  lineEdit->text();
}

void QtLineEditor::setPaste()
{
    if(validate(clipBoard))
    {
        display2(clipBoard);
    }
}

QtLineEditor::~QtLineEditor()
{  }


/////////////////////// QtCombo ////////////////////////////////////////////

QtCombo::QtCombo(QWidget *parent)
        : QWidget(parent), blockSignal(false)
{
    setupUi(this);
    radioButton->hide();	//#dk
}

QtCombo::QtCombo(QDomElement &ele, QWidget *parent) :
        QWidget(parent)
{
    setupUi(this);
    radioButton->hide();	//#dk
    itemName = ele.tagName();
    connect(combo, SIGNAL(activated(int)), this, SLOT(display2(int)) );
    connect(tool, SIGNAL(clicked()), tool, SLOT(showMenu()) );
    QString popt = ele.attribute("popt");
    QStringList poptList = popt.remove('[').remove(']').split(",");
    QString current = ele.attribute("default", "None").simplified();
    
    /* //#dk
    if (!ele.attribute("dependency_list").isNull())
    {
        radioButton->setChecked(false);
        radioButton->setCheckable(false);
        radioButton->hide();
    }
    */ //#dk

    for (int i = 0; i < poptList.size(); i++)
    {
        QString optItem = poptList.at(i).simplified();
        combo->addItem(optItem);
        if (current == optItem)
            combo->setCurrentIndex(i);
    }
    nameLabel->setText(ele.attribute("listname", "noname"));
    nameLabel->setToolTip(ele.attribute("help"));
    QMenu *mn = new QMenu;
    QAction *origAct = new QAction("Original", this);
    connect(origAct, SIGNAL(activated()), this, SLOT(setOriginal()));
    mn->addAction(origAct);
    QAction *dfltAct = new QAction("default", this);
    connect(dfltAct, SIGNAL(activated()), this, SLOT(setDefault()));
    mn->addAction(dfltAct);
    QAction *copyAct = new QAction("Copy", this);
    connect(copyAct, SIGNAL(activated()), this, SLOT(setCopy()));
    mn->addAction(copyAct);
    QAction *pasteAct = new QAction("Paste", this);
    connect(pasteAct, SIGNAL(activated()), this, SLOT(setPaste()));
    mn->addAction(origAct);
    mn->addAction(dfltAct);
    mn->addAction(copyAct);
    mn->addAction(pasteAct);
    tool->setMenu(mn);
}

void QtCombo::reSet(QString value)
{
    for (int i = 0; i < combo->count(); i++)
    {
        if (combo->itemText(i) == value)
        {
            combo->setCurrentIndex(i);
            //#dk cout << "--reset " << itemName.toStdString()
            //#dk << "=" << value.toStdString() << endl;
            break;
        }
    }
    repaint();
}

void QtCombo::display2(int value)
{
    emit  itemValueChanged(itemName, combo->currentText(), QtAutoGui::Set,
                           radioButton->isChecked());
}

void QtCombo::setOriginal()
{
    emit  itemValueChanged(itemName, combo->currentText(), QtAutoGui::Original,
                           radioButton->isChecked());
}

void QtCombo::setDefault()
{
    emit  itemValueChanged(itemName, combo->currentText(), QtAutoGui::Default,
                           radioButton->isChecked());
}

void QtCombo::setCopy()
{
    clipBoard =  combo->currentText();
}

void QtCombo::setPaste()
{
    //combo should never accept paste
}

QtCombo::~QtCombo()
{}


////////////////////////////// QtBoolean ///////////////////////////////////

QtBool::QtBool(QWidget *parent)
        : QWidget(parent), blockSignal(false)
{
    setupUi(this);
    radioButton->hide();	//#dk
}

QtBool::QtBool(QDomElement &ele, QWidget *parent) :
        QWidget(parent)
{
    setupUi(this);
    radioButton->hide();	//#dk
    itemName = ele.tagName();
    connect(combo, SIGNAL(activated(int)), this, SLOT(display2(int)) );
    connect(tool, SIGNAL(clicked()), tool, SLOT(showMenu()) );
    combo->addItem("false");
    combo->addItem("true");
    combo->setCurrentIndex(1);
    if (ele.attribute("default") == "0")
    {
        combo->setCurrentIndex(0);
    }
    nameLabel->setText(ele.attribute("listname", "noname"));
    nameLabel->setToolTip(ele.attribute("help"));
    QMenu *mn = new QMenu;
    QAction *origAct = new QAction("Original", this);
    connect(origAct, SIGNAL(activated()), this, SLOT(setOriginal()));
    mn->addAction(origAct);
    QAction *dfltAct = new QAction("default", this);
    connect(dfltAct, SIGNAL(activated()), this, SLOT(setDefault()));
    mn->addAction(dfltAct);
    QAction *copyAct = new QAction("Copy", this);
    connect(copyAct, SIGNAL(activated()), this, SLOT(setCopy()));
    mn->addAction(copyAct);
    QAction *pasteAct = new QAction("Paste", this);
    connect(pasteAct, SIGNAL(activated()), this, SLOT(setPaste()));
    mn->addAction(origAct);
    mn->addAction(dfltAct);
    mn->addAction(copyAct);
    mn->addAction(pasteAct);
    tool->setMenu(mn);
}

void QtBool::reSet(QString value)
{
    //#dk cout << "--reset " << itemName.toStdString()
    //#dk << "=" << value.toStdString() << endl;
    repaint();
}

void QtBool::display2(int value)
{
    QString val = (combo->currentText() == "false") ? "0" : "1";
    emit  itemValueChanged(itemName, val, QtAutoGui::Set,
                           radioButton->isChecked());
}

void QtBool::setOriginal()
{
    QString val = (combo->currentText() == "false") ? "0" : "1";
    emit  itemValueChanged(itemName, val, QtAutoGui::Original,
                           radioButton->isChecked());
}

void QtBool::setDefault()
{
    QString val = (combo->currentText() == "false") ? "0" : "1";
    emit  itemValueChanged(itemName, val, QtAutoGui::Default,
                           radioButton->isChecked());
}

void QtBool::setCopy()
{
    clipBoard =  combo->currentText();
}

void QtBool::setPaste()
{
    //combo should never accept paste
}

QtBool::~QtBool()
{}


////////////////////////////// QtCheck /////////////////////////////////////

QtCheck::QtCheck(QWidget *parent)
        : QWidget(parent), blockSignal(false)
{
    setupUi(this);
    radioButton->hide();	//#dk
}

QtCheck::QtCheck(QDomElement &ele, QWidget *parent) :
        QWidget(parent)
{
    setupUi(this);
    radioButton->hide();	//#dk
    itemName = ele.tagName();
    connect(tool, SIGNAL(clicked()), tool, SLOT(showMenu()) );
    popt = ele.attribute("popt");
    optValue = ele.attribute("value");

    QStringList poptList = popt.remove('[').remove(']').split(",");

    for (int i = 0; i < poptList.size(); i++)
    {
        QString opt = poptList.at(i).simplified();
        QCheckBox *check = new QCheckBox(this);
        check->setObjectName(opt);
        check->setMinimumSize(QSize(100, 0));
        check->setText(opt);
        if (optValue.contains(opt))
            check->setCheckState(Qt::Checked);
        else
            check->setCheckState(Qt::Unchecked);
        gridLayout->addWidget(check, i / 2, i %2, 1, 1);
        connect(check, SIGNAL(stateChanged(int)), this, SLOT(display2(int)) );
    }
    nameLabel->setText(ele.attribute("listname", "noname"));
    nameLabel->setToolTip(ele.attribute("help"));
    QMenu *mn = new QMenu;
    QAction *origAct = new QAction("Original", this);
    connect(origAct, SIGNAL(activated()), this, SLOT(setOriginal()));
    mn->addAction(origAct);
    QAction *dfltAct = new QAction("default", this);
    connect(dfltAct, SIGNAL(activated()), this, SLOT(setDefault()));
    mn->addAction(dfltAct);
    QAction *copyAct = new QAction("Copy", this);
    connect(copyAct, SIGNAL(activated()), this, SLOT(setCopy()));
    mn->addAction(copyAct);
    QAction *pasteAct = new QAction("Paste", this);
    connect(pasteAct, SIGNAL(activated()), this, SLOT(setPaste()));
    mn->addAction(origAct);
    mn->addAction(dfltAct);
    mn->addAction(copyAct);
    mn->addAction(pasteAct);
    tool->setMenu(mn);
}

void QtCheck::reSet(QString value)
{
    //#dk cout << "--reset " << itemName.toStdString()
    //#dk << "=" << value.toStdString() << endl;
    repaint();
}

void QtCheck::display2(int value)
{
    QCheckBox* button = dynamic_cast<QCheckBox*>(sender());
    //if(button!=0) cout << "checkbox="  <<  button->text().toStdString()
    //                   << " state=" << button->checkState() << endl;
    if(optValue.contains(button->text()))
    {
        optValue = optValue.remove(button->text() + ", ")
                   .remove(", " + button->text())
                   .remove(button->text());
    }
    else
    {
        if (optValue.count() > 0)
            optValue += ", ";
        optValue += button->text();
    }
    //cout << "optValue: " << optValue.toStdString() << endl;
    emit  itemValueChanged(itemName,  "[" + optValue + "]", QtAutoGui::Set,
                           radioButton->isChecked());
}

void QtCheck::setOriginal()
{
    emit  itemValueChanged(itemName, optValue, QtAutoGui::Original,
                           radioButton->isChecked());
}

void QtCheck::setDefault()
{
    emit  itemValueChanged(itemName, optValue, QtAutoGui::Original,
                           radioButton->isChecked());
}

void QtCheck::setCopy()
{
    //std::cout << "set copy" << std::endl;
}

void QtCheck::setPaste()
{
    //std::cout << "set paste" << std::endl;
}

QtCheck::~QtCheck()
{}


//////////////////////// QtPushButton //////////////////////////////////////

QtPushButton::QtPushButton(QWidget *parent) :
        QWidget(parent), blockSignal(false)
{
    setupUi(this);
}

QtPushButton::QtPushButton(QDomElement &ele, QWidget *parent)
            : QWidget(parent)
{
    setupUi(this);
    itemName = ele.tagName();
    connect(pushButton, SIGNAL(clicked()), this, SLOT(display2()) );
    QString txt = ele.attribute("text");
    pushButton->setText(txt);
    nameLabel->setText(ele.attribute("listname", "noname"));
    nameLabel->setToolTip(ele.attribute("help"));
}

void QtPushButton::reSet(QString value)
{
    //#dk cout << "--reset " << itemName.toStdString()
    //#dk << "=" << value.toStdString() << endl;
    repaint();
}

void QtPushButton::display2()
{
    emit  itemValueChanged(itemName, "1", /*pushButton->text(),*/
                           QtAutoGui::Command, true);
}

QtPushButton::~QtPushButton()
{}


////////////////////////////// QtAdjustmentTop /////////////////////////////

QtAdjustmentTop::QtAdjustmentTop(QtAutoGui *parent, QString name)
        :/* QWidget(parent),*/ parent(parent), blockSignal(false)
{
    setupUi(this);
    applyButton->setToolTip("Apply the whole set of display options");
    connect(applyButton, SIGNAL(clicked()), this, SLOT(apply()) );
    saveButton->setToolTip("Save the display options to a file");
    connect(saveButton, SIGNAL(clicked()), this, SLOT(save()) );
    restoreButton->setToolTip("Load the display options from a file");
    connect(restoreButton, SIGNAL(clicked()), this, SLOT(load()) );
    connect(dismissButton, SIGNAL(clicked()), this, SLOT(close()) );
    connect(tool, SIGNAL(clicked()), tool, SLOT(showMenu()) );
    connect(dataName, SIGNAL(textChanged(QString)),
            this, SLOT(dataNameChanged(QString)) );
    dataName->setText(name);
    dataName->setToolTip("enter the file name of the display options");
    QMenu *mn = new QMenu;
    QAction *origAct = new QAction("Original", this);
    connect(origAct, SIGNAL(activated()), this, SLOT(setOriginal()));
    origAct->setToolTip("Reset the display data to the saved values");
    mn->addAction(origAct);
    QAction *dfltAct = new QAction("default", this);
    connect(dfltAct, SIGNAL(activated()), this, SLOT(setDefault()));
    dfltAct->setToolTip("Reset the display data to the default values");
    mn->addAction(dfltAct);
    QAction *memoryAct = new QAction("Memorize", this);
    memoryAct->setToolTip("Save current settings in memory");
    connect(memoryAct, SIGNAL(activated()), this, SLOT(setMemory()));
    mn->addAction(memoryAct);
    QAction *clearAct = new QAction("Clear", this);
    connect(clearAct, SIGNAL(activated()), this, SLOT(setClear()));
    //mn->addAction(clearAct);
    QAction *copyAct = new QAction("Copy", this);
    connect(copyAct, SIGNAL(activated()), this, SLOT(setCopy()));
    //mn->addAction(copyAct);
    QAction *pasteAct = new QAction("Paste", this);
    connect(pasteAct, SIGNAL(activated()), this, SLOT(setPaste()));
    //mn->addAction(pasteAct);
    tool->setMenu(mn);
}

void QtAdjustmentTop::dataNameChanged(QString value)
{
    dataName->setText(value);
    if (value.size() > 0)
        parent->setFileName(value);
    //std::cout << "set data name: " << value.toStdString() << std::endl;
}

void QtAdjustmentTop::setOriginal()
{
    //if you just want to set fileName to original
    dataName->setText(parent->fileName());
    //or if you want to set the whole thing to original
    parent->setOriginal();
}

void QtAdjustmentTop::setDefault()
{
    dataName->setText(parent->fileName());
    parent->setDefault();
}
void QtAdjustmentTop::setMemory()
{
    dataName->setText(parent->fileName());
    parent->setMemory();
}

void QtAdjustmentTop::setCopy()
{
    clipBoard =  dataName->text();
}

void QtAdjustmentTop::setPaste()
{
    dataName->setText(clipBoard);
}

void QtAdjustmentTop::setClear()
{
    dataName->setText("");
    clipBoard = "";
}

void QtAdjustmentTop::apply()
{
    parent->apply();
}

void QtAdjustmentTop::save()
{
    parent->save();
}

void QtAdjustmentTop::load()
{
    parent->load();
}

void QtAdjustmentTop::close()
{
    parent->dismiss();
}

void QtAdjustmentTop::restore()
{
    parent->restore();
}

void QtAdjustmentTop::hideDismiss()
{
    dismissButton->hide();
}		//#dk

QtAdjustmentTop::~QtAdjustmentTop()
{}


///////////////////////// QtRegionEditor////////////////////////////////////

QtRegionEditor::QtRegionEditor(QWidget *parent) :
        QWidget(parent), blockSignal(false)
{
    setupUi(this);
    radioButton->hide();	//#dk
}

QtRegionEditor::QtRegionEditor(QDomElement &ele, QWidget *parent)
              : QWidget(parent)
{
    setupUi(this);
    radioButton->hide();	//#dk
    itemName = ele.tagName();
    //connect(lineEdit, SIGNAL(textChanged(QString)),
    //                this,SLOT(display2(QString)));
    connect(lineEdit, SIGNAL(editingFinished()),
            this, SLOT(editingFinished()) );
    connect(tool, SIGNAL(clicked()), tool, SLOT(showMenu()) );
    QString value = ele.attribute("value");

    if (value.isNull() && ele.attribute("datatype") == "Bool")
    {
        QDomElement el1 = ele.firstChildElement();
        QString v;
        if (!el1.isNull())
        {
            v = el1.attribute("i_am_unset");
            if (!v.isNull())
            {
                value = "<unset>";
            }
        }
    }
    else
    {
        //#dk cout << " value=" << value.toStdString() << endl;
    }
    ele.setAttribute("i_am_unset", "i_am_unset");
    lineEdit->setText(value);
    iamunset = "I_am_unset";
    ptype = ele.attribute("ptype");
    nameLabel->setText(ele.attribute("listname", "noname"));
    nameLabel->setToolTip(ele.attribute("help"));
    QMenu *mn = new QMenu;
    QAction *fromImgAct = new QAction("fromImage", this);
    connect(fromImgAct, SIGNAL(activated()), this, SLOT(fromImg()));
    mn->addAction(fromImgAct);
    QAction *createAct = new QAction("Create", this);
    connect(createAct, SIGNAL(activated()), this, SLOT(createRegion()));
    mn->addAction(createAct);
    QAction *unsetAct = new QAction("Unset", this);
    connect(unsetAct, SIGNAL(activated()), this, SLOT(unset()));
    mn->addAction(unsetAct);
    QAction *origAct = new QAction("Original", this);
    connect(origAct, SIGNAL(activated()), this, SLOT(setOriginal()));
    mn->addAction(origAct);
    QAction *dfltAct = new QAction("default", this);
    connect(dfltAct, SIGNAL(activated()), this, SLOT(setDefault()));
    mn->addAction(dfltAct);
    QAction *copyAct = new QAction("Copy", this);
    connect(copyAct, SIGNAL(activated()), this, SLOT(setCopy()));
    mn->addAction(copyAct);
    QAction *pasteAct = new QAction("Paste", this);
    connect(pasteAct, SIGNAL(activated()), this, SLOT(setPaste()));
    mn->addAction(origAct);
    mn->addAction(dfltAct);
    mn->addAction(copyAct);
    mn->addAction(pasteAct);
    tool->setMenu(mn);
}

void QtRegionEditor::reSet(QString value)
{
    //#dk cout << "--reset " << itemName.toStdString()
    //#dk << "=" << value.toStdString() << endl;
    repaint();
}

void QtRegionEditor::display2(QString value)
{
    //cout << "regionEdit=" << value.toStdString() << endl;
    if (!validate(value))
        return;

    emit  itemValueChanged(itemName, lineEdit->text(), QtAutoGui::Set,
                           radioButton->isChecked());
}

void QtRegionEditor::editingFinished()
{
    //cout << "regionEdit=" << regionEdit->text().toStdString()
    //        << (regionEdit->text().isNull() ? "Null" : "not Null") << endl;
    if (!validate(lineEdit->text()))
        return;

    emit  itemValueChanged(itemName, lineEdit->text(), QtAutoGui::Set,
                           radioButton->isChecked());
}

bool QtRegionEditor::validate(QString value)
{
    if (value.isNull())
    {
        labelOk->setPixmap(QPixmap(QString::fromUtf8(":/icons/cross.xbm")));
        return false;
    }
    if (ptype == "region")
    {
        if (value.contains(QRegExp("\\[.+\\]")) == 0)
        {
            labelOk->setPixmap(QPixmap(QString::fromUtf8(":/icons/cross.xbm")));
            return false;
        }
        QStringList poptList = value.remove('[').remove(']').split(",");
        bool ok = true;
        labelOk->setPixmap(QPixmap(":/icons/tick.xbm"));
        for (int i = 0; i < poptList.size(); i++)
        {
            QString opt = poptList.at(i).simplified();
            ok = false;
            if (ok == false)
            {
                labelOk->setPixmap(QPixmap(QString::fromUtf8(
                                               ":icons/cross.xbm")));
                return false;
            }
        }
        return ok;
    }
    return true;
}

void QtRegionEditor::setOriginal()
{
    emit  itemValueChanged(itemName, lineEdit->text(), QtAutoGui::Original,
                           radioButton->isChecked());
}

void QtRegionEditor::setDefault()
{
    emit  itemValueChanged(itemName, lineEdit->text(), QtAutoGui::Default,
                           radioButton->isChecked());
}

void QtRegionEditor::fromImg()
{
    emit  itemValueChanged(itemName, lineEdit->text(), QtAutoGui::Command,
                           radioButton->isChecked());
}

void QtRegionEditor::createRegion()
{
    emit  itemValueChanged(itemName, lineEdit->text(), QtAutoGui::Command,
                           radioButton->isChecked());
}

void QtRegionEditor::unset()
{
    lineEdit->setText("<unset>");
    labelOk->setPixmap(QPixmap(":/icons/tick.xbm"));
}

void QtRegionEditor::setCopy()
{
    clipBoard =  lineEdit->text();
}

void QtRegionEditor::setPaste()
{
    if(validate(clipBoard))
    {
        display2(clipBoard);
    }
}

QtRegionEditor::~QtRegionEditor()
{  }


} //# NAMESPACE CASA - END
