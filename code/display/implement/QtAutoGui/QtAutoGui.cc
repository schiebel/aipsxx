//# QtAutoGui.cc: General-purpose Qt options panel widget created from
//#               an options Record.
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
//# $Id: QtAutoGui.cc,v 1.4 2006/09/25 17:51:11 hye Exp $

#include <graphics/X11/X_enter.h>
#  include <QtGui/QtGui>
#  include <QtCore/qdebug.h>
#include <graphics/X11/X_exit.h>

#include "QtAutoGui.qo.h"
#include "QtXmlRecord.h"
#include "QtGuiEntry.qo.h"
#include "QtLayout.h"

extern int qInitResources_QtAutoGui();

namespace casa { //# NAMESPACE CASA - BEGIN

QString clipBoard = "";

////////////////////////  QtAutoGui  /////////////////////////////////////////

QtAutoGui::QtAutoGui(Record rec, String dataName, String dataType, QWidget
                     *parent)
        : QWidget(parent), recordLoaded_(False), mutex()
{
    initialize();
    loadRecord(rec);
    m_file_name = dataName.chars();
    m_data_type = dataType.chars();   
    m_lockItem = "";
}

QtAutoGui::QtAutoGui(QWidget *parent)
        : QWidget(parent),
        m_file_name(""),m_data_type("Unknown"),
        recordLoaded_(False), m_lockItem("")
{
    initialize();
}


QtAutoGui::~QtAutoGui()
{
    QSettings settings;
    settings.beginGroup(QLatin1String("AdjustmentWidgetBox"));
    // settings.setValue(QLatin1String("current index"), currentIndex());
    settings.endGroup();
}


void QtAutoGui::initialize()
{

    //setFixedWidth(580);
    setObjectName(QString::fromUtf8("AutoSize"));

    //Q_INIT_RESOURCE(QtAutoGui);
    qInitResources_QtAutoGui();
	// Makes QtAutoGui icons, etc. available via Qt resource system.
	//
	// You would normally use this macro for the purpose instead:  
	//
	//   Q_INIT_RESOURCE(QtAutoGui);
	//
	// It translates as:
	//
	//   extern int qInitResources_QtAutoGui();
	//   qInitResources_QtAutoGui();
	//
	// It doesn't work here because it makes the linker looks for
	//   casa::qInitResources_AutoGui()     :-/   dk

    contents_ = new QWidget(this);

    contents_->setObjectName(QString::fromUtf8("contents_"));
    //#dk contents_->setGeometry(QRect(10, 0, 560, 2760));
    //#dk contents_->setSizePolicy( QSizePolicy::Fixed, QSizePolicy::Expanding);

    // setGeometry(QRect(10, 0, 560, 260));				//#dk
    // setSizePolicy( QSizePolicy::Fixed, QSizePolicy::Expanding);	//#dk

    // setMinimumSize(400, 800);					//#dk

    if(layout()==0)
        new QVBoxLayout(this);			//#dk
    layout()->addWidget(contents_);				//#dk
    layout()->setSizeConstraint(QLayout::SetFixedSize);		//#dk

    vboxLayout = new QVBoxLayout(contents_);
    vboxLayout->setSpacing(6);
    vboxLayout->setMargin(0);
    vboxLayout->setObjectName(QString::fromUtf8("vboxLayout"));

    // vboxLayout->setSizeConstraint(QLayout::SetFixedSize);		//#dk   
}


void QtAutoGui::loadRecord(Record rec)
{
    if(recordLoaded_)
        return;
    // loadRecord() is intended only to be called once
    // during initialization.
    QtXmlRecord xmlRecord;
    xmlRecord.recordToDom(&rec, m_doc);
    load(m_doc);
    //#dk cout << "\nRecord\n:";
    //#dk xmlRecord.printRecord(&rec);
    //#dk cout << endl;
    //scrollArea = new QScrollArea(this);
    //scrollArea->setBackgroundRole(QPalette::Light);
    //scrollArea->setWidget((QWidget*)contents_);

    //#dk resize(width(),  line->pos().y());
    update();
    recordLoaded_ = True;
}



bool QtAutoGui::load(QDomDocument &doc)
{
    //cout << "------------doc: " << doc.toString().toStdString() << endl;
    

    QDomElement root = doc.firstChildElement();
    QtAdjustmentTop *m_bottom = new QtAdjustmentTop(this,
                                m_file_name);
    m_bottom->hideDismiss();	//#dk (needs improvement, ctrl from without...)
    m_bottom->setObjectName(QString::fromUtf8("command"));
    //vboxLayout->addWidget(m_bottom);

    QDomElement cat_elt = root.firstChildElement();
    for (; !cat_elt.isNull(); cat_elt = cat_elt.nextSiblingElement())
    {

        QPushButton *button = new QPushButton(contents_);
        button->setObjectName(QString::fromUtf8("button"));
        button->setCheckable(true);
        button->setText(cat_elt.tagName().replace('_', ' '));
        button->setChecked(button->text()=="Basic Settings");
        vboxLayout->addWidget(button);

        QWidget *wgt = new QWidget();
        QVBoxLayout *vLayout = new QVBoxLayout;
        vLayout->setMargin(10);
        vLayout->setSpacing(6);
        // vLayout->setSpacing(1);	//#dk

        QDomElement widget_ele = cat_elt.firstChildElement();

        for (; !widget_ele.isNull();
                widget_ele = widget_ele.nextSiblingElement())
        {

            QString ptype = widget_ele.attribute("ptype", "noType");

            if (ptype == "intrange" || ptype == "floatrange")
            {
                if (// ele.attribute("editable") == "1" &&
                    widget_ele.attribute("provideentry") == "1")
                {
                    QtSliderEditor *item = new  QtSliderEditor(widget_ele);
                    vLayout->addWidget(item);
                    connect(item,
                            SIGNAL(itemValueChanged(
                                       QString, QString, int, bool)),
                            this,
                            SLOT(itemValueChanged(
                                     QString,QString, int, bool)));
                }

                else
                {
                    QtSliderLabel *item = new  QtSliderLabel(widget_ele);
                    vLayout->addWidget(item);
                    connect(item, SIGNAL(itemValueChanged(
                                             QString, QString, int, bool)),
                            this, SLOT(itemValueChanged(
                                           QString, QString, int, bool)));
                }
            }

            else if (ptype == "choice" || ptype == "userchoice")
            {
                QtCombo *item = new  QtCombo(widget_ele);
                vLayout->addWidget(item);
                connect(item, SIGNAL(itemValueChanged(
                                         QString, QString, int, bool)),
                        this, SLOT(itemValueChanged(
                                       QString, QString, int, bool)));
            }

            else if (ptype == "array" || ptype == "string")
            { 
	      
	      if(widget_ele.tagName() != "mask") {	//#dk
	      //#dk exclude LPADD's 'mask expression' for now -- this
	      //#dk is a more complex data type that needs more work
	      //#dk to support....  (May be fairly simple though --
	      //#dk fundamentally a text box / string, I think....
	      //#dk See LPADD.cc "mask", and vdd.g 'mask').

                QtLineEditor *item = new  QtLineEditor(widget_ele);
                vLayout->addWidget(item);
                connect(item, SIGNAL(itemValueChanged(
                                         QString, QString, int, bool)),
                        this, SLOT(itemValueChanged(
                                       QString, QString, int, bool)));
	      }	//#dk
            }

            else if (ptype == "button")
            {
                QtPushButton *item = new  QtPushButton(widget_ele);
                vLayout->addWidget(item);
                connect(item, SIGNAL(itemValueChanged(
                                         QString, QString, int, bool)),
                        this, SLOT(itemValueChanged(
                                       QString, QString, int, bool)));
            }

            else if (ptype == "boolean")
            {
                QtBool *item = new  QtBool(widget_ele);
                vLayout->addWidget(item);
                connect(item, SIGNAL(itemValueChanged(
                                         QString, QString, int, bool)),
                        this, SLOT(itemValueChanged(
                                       QString, QString, int, bool)));
            }

            else if (ptype == "minmaxhist")
            {
                QtMinMaxEditor *item = new  QtMinMaxEditor(widget_ele);
                vLayout->addWidget(item);
                connect(item, SIGNAL(itemValueChanged(
                                         QString, QString, int, bool)),
                        this, SLOT(itemValueChanged(
                                       QString, QString, int, bool)));
            }

            else if (ptype == "check")
            {
                QtCheck *item = new  QtCheck(widget_ele);
                vLayout->addWidget(item);
                connect(item, SIGNAL(itemValueChanged(
                                         QString, QString, int, bool)),
                        this, SLOT(itemValueChanged(
                                       QString, QString, int, bool)));
            }

            /* //#dk
	    //#dk exclude for now -- this is a more complex
	    //#dk data type that needs more work to support.
	    
	    else if (ptype == "region")
            {
                QtRegionEditor *item = new  QtRegionEditor(widget_ele);
                vLayout->addWidget(item);
                connect(item, SIGNAL(itemValueChanged(
                                         QString, QString, int, bool)),
                        this, SLOT(itemValueChanged(
                                       QString, QString, int, bool)));
            }
            */ //#dk

	    
	    
	    /*	//#dk  (if we don't really know what we've got,
		//#dk   don't create anything...).
            else
            {   //treat everything else as a string

                QtLineEditor *item = new  QtLineEditor(widget_ele);
                vLayout->addWidget(item);
                connect(item, SIGNAL(itemValueChanged(
                                         QString, QString, int, bool)),
                        this, SLOT(itemValueChanged(
                                       QString, QString, int, bool)));
            }
	    */	//#dk


        }

        wgt->setLayout(vLayout);
        wgt->setShown(button->isChecked());
        vboxLayout->addWidget(wgt);
        QObject::connect(button, SIGNAL(toggled(bool)),
                         wgt,    SLOT(setShown(bool)));
        QObject::connect(button, SIGNAL(clicked()), this, SLOT(adjustHeight()));

    }

    vboxLayout->addWidget(m_bottom);

    //#dk line = new QFrame(contents_);
    //#dk line->setObjectName(QString::fromUtf8("line"));
    //#dk line->setFrameShape(QFrame::HLine);

    //#dk vboxLayout->addWidget(line);

    //#dk spacerItem = new QSpacerItem(20, 40, QSizePolicy::Minimum,
    //#dk 				       QSizePolicy::Expanding);
    //#dk vboxLayout->addItem(spacerItem);

    dynamic_cast<QBoxLayout*>(layout())->addStretch(1);	//#dk

    return true;
}

void QtAutoGui::setFileName(const QString &file_name)
{
    m_file_name = file_name;
}


QString QtAutoGui::fileName() const
{
    return m_file_name;
}

void QtAutoGui::setDataType(const QString &dType)
{
    m_data_type = dType;
}


QString QtAutoGui::dataType() const
{
    return m_data_type;
}


//////////// actions on the whole auto-gui /////////////////////
bool QtAutoGui::save()
{
    if (fileName().isEmpty() &&
            QMessageBox::warning(this, "Option Panel",
                                 "You must specify a file name to \n"
                                 "save options",
                                 QMessageBox::Ok, QMessageBox::NoButton))
    {
        return false;
    }

    QString fName = fileName().append(".option");
    //#dk std::cout << "save the option to file: "
    //#dk << fName.toStdString() << std::endl;
    QFile file(fName);
    if (!file.open(QIODevice::WriteOnly))
        return false;

    QTextStream stream(&file);
    m_doc.documentElement()
    .setAttribute("display_data", fileName());
    m_doc.documentElement()
    .setAttribute("data_type", dataType());
    m_doc.save(stream, 4);

    return true;
}

bool QtAutoGui::load()
{
    //#dk std::cout << "restore options" << std::endl;
    QString name = fileName();
    if (name.isEmpty() &&
            QMessageBox::warning(this, "Option Panel",
                                 "You must specify a file name to \n"
                                 "load saved options",
                                 QMessageBox::Ok, QMessageBox::NoButton))
    {
        return false;
    }

    QFile f(name.append(".option"));
    if (!f.open(QIODevice::ReadOnly) &&
            QMessageBox::warning(this, "Option Panel",
                                 QString("Could not find saved options\n" )
                                 .append("by the name: ").append(name),
                                 QMessageBox::Ok, QMessageBox::NoButton))
    {
        return false;
    }

    QString error_msg;
    int line, col;
    QDomDocument doc;
    if (!doc.setContent(&f, &error_msg, &line, &col))
    {
        QString msg = QString("Failded to parse \"%s\": on line %d: %s")
                      .arg(name.toUtf8().constData()).arg(line)
                      .arg(error_msg.toUtf8().constData());
        QMessageBox::warning(this, "Option Panel",
                             msg,
                             QMessageBox::Ok, QMessageBox::NoButton);
        return false;
    }

    QDomElement root = doc.firstChildElement();
    if (root.nodeName() != QLatin1String("casa-Record"))
    {
        QMessageBox::warning(this,
                             "Option Panel",
                             QString("The file does not saved options\n"),
                             QMessageBox::Ok,QMessageBox::NoButton);
        return false;
    }
    
    /* //#dk  This could possibly be restored, but only when
       //#dk  attribute[s] don't match....
    
    QString dName = root.attribute("display_data", "Unknown");
    QString dType = root.attribute("data_type", "Unknown");
    if (QMessageBox::Ok != QMessageBox::warning(this,
            "Display Data Option Adjustment",
            QString("The file containes display data options\n")
            .append("originally from ").append(dName)
            .append(" of ").append(dType)
            .append(" type\n Are you sure you want to load it?"),
            QMessageBox::Ok,QMessageBox::Cancel))
        return false;
    else
    {
    */ //#dk
    
    
        delete contents_;
        initialize();
        f.reset();
        m_doc.setContent(&f, &error_msg, &line, &col);
        load(m_doc);
        contents_->show();
        adjustHeight();
        return true;

    //#dk}
    
}

void QtAutoGui::setMemory()
{
    //#dk cout << "save options" << endl;
    QDomElement ele = m_doc.firstChildElement().firstChildElement()
                      .firstChildElement();
    for (; !ele.isNull(); ele = ele.nextSiblingElement())
    {
        ele.setAttribute("saved", ele.attribute("value"));
    }
}

void QtAutoGui::setOriginal()
{
    //#dk std::cout << "set original options" << std::endl;
    QDomElement ele = m_doc.firstChildElement().firstChildElement()
                      .firstChildElement();
    for (; !ele.isNull(); ele = ele.nextSiblingElement())
    {
        ele.setAttribute("value", ele.attribute("saved"));
    }
}

void QtAutoGui::setDefault()
{
    //#dk std::cout << "set default options" << std::endl;
    QDomElement ele = m_doc.firstChildElement().firstChildElement()
                      .firstChildElement();
    for (; !ele.isNull(); ele = ele.nextSiblingElement())
    {
        ele.setAttribute("value", ele.attribute("default"));
    }
}

void QtAutoGui::apply()
{
    Record record;
    QtXmlRecord xmlRecord;
    xmlRecord.domToRecord(&m_doc, record);
    // cout<<"QAG:app(): emit sOpt..."<<flush;	//#diag
    emit setOptions(record);
    // cout<<" done"<<endl<<endl;		//#diag
}

////////////////////////////////////////////////////////////////////////////


void QtAutoGui::contextMenuEvent(QContextMenuEvent *e)
{
    e->ignore();
}

void QtAutoGui::itemValueChanged(QString name, QString value,
                                 int action, bool autoApply)
{
    //#dk static int msgCount = 1;
    //#dk std::cout << "received 4 parameters: name=" << name.toStdString()
    //#dk << " value=" << value.toStdString()
    //#dk << " action=" << action
    //#dk << " apply=" << autoApply   
    //#dk << " msgCount=" << (msgCount++)
    //#dk << std::endl;					//#diag

    //cerr<<"QAG:iValChg:"<<name.toStdString()<<" "	//#diag
    //<<value.toStdString()<<" "<<action<<endl;		//#diag

    // cout << "m_doc: " << m_doc->toString().toStdString() << endl;


    /* //#diag -- test setOptions invocation (works)  dk
    if(name.contains("color"))
    {
        //cerr<<"Si"<<endl;			//#diag
        Record rec;
        rec.define(String(name.toStdString()), String(value.toStdString()));
        emit setOptions(rec);
    }
    */ //#dk  //#diag -- test setOptions invocation  dk

    //for the records that belong to a dependency group, it  can be more
    //efficient just to validate on the options panel (here) and send valid
    //record set to the display panel.
    //for the records that belong to a dependency group, it  can be more
    //efficient just to validate on the options panel (here) and send valid
    //record set to the display panel.
    // groupEle = m_doc.firstChildElement().firstChildElement();
    //  for (; !groupEle.isNull()  && v.isNull();
    //           groupEle = groupEle.nextSiblingElement()) {
    //  QDomElement ele = groupEle.firstChildElement();
    //  for (; !ele.isNull(); ele = ele.nextSiblingElement()) {
    //    cout << " element=" << ele.tagName().toStdString() << endl;
    //    if (ele.tagName() == name) {
    //       g = ele.attribute("dependency_group");
    //       if (!g.isNull() &&
    //           ele.attribute("dependency_type", "") == "exclusive"){
    // 	       v = ele.attribute("value", "");
    //           cout << "there is a potential conflicte in the values, "
    //                    << "can adjust the group here" << endl;
    // 	        break;
    // 	     }
    // 	  }
    //     }
    //}

    
    QString g;
    QString v;
    QDomElement groupEle;

   
    groupEle = m_doc.firstChildElement().firstChildElement();
    for (; !groupEle.isNull(); groupEle = groupEle.nextSiblingElement())
    {
        QDomElement ele = groupEle.firstChildElement();
        for (; !ele.isNull(); ele = ele.nextSiblingElement())
        {
            //cout << " element=" << ele.tagName().toStdString() << endl;
            if (ele.tagName() == name)
            {
                //cout << " action on:  " << name.toStdString() << std::endl;
		 
                if (action == Set)
                {
                    //#dk std::cout << "update element ="
                    //#dk << QtXmlRecord::domToString(ele).toStdString()
                    //#dk << std::endl;
		    // cout<<"            "<<ele.tagName().toStdString()
		    //     <<" old:"<<ele.attribute("value").toStdString()
		    //     <<" new:"<<value.toStdString()<<endl;  //#diag
    
                    ele.setAttribute("value", value);
                }
                else if (action == Default)
                {
                    //#dk std::cout << "set Default for element ="
                    //#dk << QtXmlRecord::domToString(ele).toStdString()
                    //#dk << std::endl;
                    QString dflt = ele.attribute("default");
                    ele.setAttribute("value", dflt);
                }
                else if (action == Original)
                {
                    //#dk std::cout << "set Original for lement ="
                    //#dk << QtXmlRecord::domToString(ele).toStdString()
                    //#dk << std::endl;
                    QString orig = ele.attribute("saved");
                    ele.setAttribute("value", orig);
                }
                else if (action == Memorize)
                {
                    //#dk std::cout << "memorize Original for lement ="
                    //#dk << QtXmlRecord::domToString(ele).toStdString()
                    //#dk << std::endl;
                    ele.setAttribute("saved", value);
                }
                else if (action == Command)
                {
                    //#dk std::cout << "execute command for element ="
                    //#dk << QtXmlRecord::domToString(ele).toStdString()
                    //#dk << std::endl;
                    ele.setAttribute("value", value);
                }
                if (autoApply)
                {		  
                    QtXmlRecord xmlRecord;
                    Record rec;
                    xmlRecord.elementToRecord(&ele, rec);
		    //cout << " record=";
	            //xmlRecord.printRecord(&rec) ;
	            //cout << endl;		  
		    
		    // cout<<"            autoapp'g: emit sOpt..."
		    //     <<flush;			//#diag
                    emit setOptions(rec);
		    // cout<<" done"<<endl<<endl;	//#diag

		    //mutex.lock();
		    //m_lockItem = name;  
		    //cout << "lockItem=" << m_lockItem.toStdString() << endl;
		    //mutex.unlock();
                    //#dk cout << "apply item change " << std::endl;
                }
                break;
            }
        }
    }
    //cout << "finished itemValueChanged" << std::endl;
    
}


//#dk void QtAutoGui::paintEvent ( QPaintEvent * event )
//#dk {
//#dk        resize(width(),  line->pos().y());
//#dk }


void QtAutoGui::adjustHeight()
{
    //#dk        resize(width(),  line->pos().y());
    //#dk	update();
}


void QtAutoGui::restore()
{


    //#dk: To fix: This routine should never be willing to 'restore'
    // options that were not in the original getOptions record
    // (e.g. those of another type of DD).

    //#dk std::cout << "restore options" << std::endl;
    contents_->close();
    //#dk note: This does _not_ delete; it leaks.  We should very
    // probably do this instead:
    // delete contents_;

    initialize();
    load();
    contents_->show();
    adjustHeight();

}


void QtAutoGui::dismiss()
{
    close();
}


void QtAutoGui::changeOptions(Record rec)
{
    //cout <<  "received option changed signal:\n" << endl;
    //#dk static int changeOptionCount = 1;
    //#dk cout << "changeOptionCount=" << (changeOptionCount++) << endl;
    QDomDocument doc;
    QtXmlRecord xmlRecord;
    
    //#dk xmlRecord.printRecord(&rec);
    
    xmlRecord.recordToDom(&rec, doc);
    
    //#dk cout <<  "\nchange optiongs=" << doc.toString().toStdString()
    //#dk      << endl;
    
    QDomElement groupEle;
    
    /*  //#dk   
    groupEle = doc.firstChildElement().firstChildElement();
    for (; !groupEle.isNull(); groupEle = groupEle.nextSiblingElement())
    {
        QString group = groupEle.tagName();
        QDomElement ele = groupEle.firstChildElement();
        for (; !ele.isNull(); ele = ele.nextSiblingElement())
        {
	    QString name = ele.tagName();
	    if (group == "Basic_Settings" && name == "no-name") {
	        cout << "here it is===================" << endl;
		//mutex.lock();
		//cout << "lockItem.isNull()=" << m_lockItem.isNull() << endl;
		//cout << "lockItem=" << m_lockItem.toStdString() << endl;
		//mutex.unlock();
		//if (name.isNull() || name == "no-name") name = lockItem; 
	     }
	}   
    }
    */  //#dk   
    
    groupEle = doc.firstChildElement().firstChildElement();

       
    // (for each group of interface elements in the change request...)
    for (; !groupEle.isNull(); groupEle = groupEle.nextSiblingElement())
    {

        QString group = groupEle.tagName();
        QDomElement ele = groupEle.firstChildElement();
    

        // (For each interface element in the group)
        for (; !ele.isNull(); ele = ele.nextSiblingElement())
        {

            QString name = ele.tagName();
	   
            QString value = ele.attribute("value");
            //cout << "-----set element:  " << name.toStdString()
            //        << " = " << value.toStdString() << endl;

            bool eleSet = false;
            QDomElement grpEle;
            grpEle = m_doc.firstChildElement().firstChildElement();

      
            // (For each group of interface elements in the autogui)
            for (; !grpEle.isNull() && !eleSet; 
	           grpEle = grpEle.nextSiblingElement())
            {
                QString grp = grpEle.tagName();
                //cout << "grp=" << grp.toStdString()
                //        << " group=" << group.toStdString() << endl;
                if (grp !=  group)
                    continue;

        
		// (For each interface element in that group)
                QDomElement upEle = grpEle.firstChildElement();
                for (; !upEle.isNull() && !eleSet; 
		       upEle = upEle.nextSiblingElement())
                {                    
                    if (upEle.tagName() == name)
                    {
		    
		        //#dk cout << "upele name=" 
			//#dk      << upEle.tagName().toStdString() << endl;

			//#dk cout<<"ChgOpt "<<name.toStdString()<<" <- "
			//#dk     <<value.toStdString()<<endl;   //#diag


                        upEle.setAttribute("value", value);


                        //cout << "=====set element: "
                        //     << QtXmlRecord::domToString(upEle).toStdString()
                        //     << endl;
			QString ptype = upEle.attribute("ptype");
                        QList<QWidget *> widgets =
                            contents_->findChildren<QWidget*>();

        
			// (For each GuiEntry QWidget in the AutoGui)
                        for (int i = 0; i < widgets.size(); i++)
                        {
                            QWidget* pw = widgets.at(i);
                            //cout << pw->objectName().toStdString() << " ";
                            QString item;

                            if (pw->objectName() == "SliderLabelItem")
                            {
                                QtSliderLabel *sl = (QtSliderLabel*)pw;
                                if (sl->name() == name) {

				    sl->reSet(ele);

                //#dk               cout << "==reset "		//#diag
		//#dk 		    <<name.toStdString()<<"=" 
		//#dk 		    <<ele.attribute("pmin").toStdString()<<" "
		//#dk 		    <<ele.attribute("value").toStdString()<<" "
		//#dk 		    <<ele.attribute("pmax").toStdString()<<" "
		//#dk 		    <<ele.attribute("listname").toStdString()
		//#dk 		    <<" "<<endl;		//#diag

                                    break;
                                }
                            }

                            else if (pw->objectName() == "SliderEditorItem")
                            {			        
                                QtSliderEditor *sl = (QtSliderEditor*)pw;
                                if (sl->name() == name) {

				    sl->reSet(ele);

                //#dk               cout << "==reset "		//#diag
		//#dk 		    <<name.toStdString()<<"=" 
		//#dk 		    <<ele.attribute("pmin").toStdString()<<" "
		//#dk 		    <<ele.attribute("value").toStdString()<<" "
		//#dk 		    <<ele.attribute("pmax").toStdString()<<" "
		//#dk 		    <<ele.attribute("listname").toStdString()
		//#dk 		    <<" "<<endl;		//#diag

                                    break;
                                }
                            }
    
                            else if (pw->objectName() == "ComboItem"  &&
			        (ptype == "choice" || 
				 ptype == "userchoice") ) {
                                QtCombo *lbl = (QtCombo*)pw;
                                item = lbl->name();
                                if (item == name)
                                {
				    lbl->reSet(value);
                //#dk               cout << "==reset " << item.toStdString() 
		//#dk 		         << "=" << value.toStdString() << endl;
                                    break;
                                }
                            }

                            else if (pw->objectName() == "LineEditorItem")
                            {
                                QtLineEditor *lbl = (QtLineEditor*)pw;
                                item = lbl->name();
                                if (item == name)
                                {
				    lbl->reSet(value);
                //#dk               cout << "==reset " << item.toStdString() 
		//#dk 		         << "=" << value.toStdString() << endl;
                                    break;
                                }
                            }

                            else if (pw->objectName() == "PushButtonItem" )
                            {
                                QtPushButton *lbl = (QtPushButton*)pw;
                                item = lbl->name();
                                if (item == name)
                                {
				    lbl->reSet(value);
                //#dk               cout << "==reset " << item.toStdString() 
		//#dk		         << "=" << value.toStdString() << endl;
                                    break;
                                }
                            }

                            else if (pw->objectName() == "CheckItem")
                            {
                                QtCheck *lbl = (QtCheck*)pw;
                                item = lbl->name();
                                if (item == name)
                                {
				    lbl->reSet(value);
                //#dk               cout << "==reset " << item.toStdString() 
		//#dk		         << "=" << value.toStdString() << endl;
                                    break;
                                }
                            }
                            else if (pw->objectName() == "MinMaxEditorItem")
                            {
                                QtMinMaxEditor *lbl = (QtMinMaxEditor*)pw;
                                item = lbl->name();
                                if (item == name)
                                {
				    lbl->reSet(value);
                //#dk               cout << "==reset " << item.toStdString() 
		//#dk		         << "=" << value.toStdString() << endl;
                                    break;
                                }
                            }


                        }
                        eleSet = true;
                    }
                }
            }
        }
    }
}


} //# NAMESPACE CASA - END

