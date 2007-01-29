//# QtDataManager.cc: Qt implementation of viewer data manager widget.
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
//# $Id: QtDataManager.cc,v 1.6 2006/09/13 22:26:07 hye Exp $


#include <display/QtViewer/QtDataManager.qo.h>
#include <display/QtViewer/QtViewer.qo.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/TableInfo.h>
#include <casa/BasicSL/String.h>
#include <casa/OS/File.h>
#include <casa/iostream.h>
#include <casa/fstream.h>
#include <casa/Exceptions/Error.h>

#include <graphics/X11/X_enter.h>
#include <QDir>
#include <QMessageBox>
#include <QDirModel>
#include <QHash>
#include <QSettings>
#include <QTextStream>
#include <graphics/X11/X_exit.h>


namespace casa { //# NAMESPACE CASA - BEGIN



QtDataManager::QtDataManager(QtViewer* viewer,
			     const char *name,
			     QWidget *parent ) :
	       QWidget(parent),
               parent_(parent),
	       viewer_(viewer) {
  
  setWindowTitle(name);
  
  setupUi(this);
  
  toolButton_->setCheckable(true);
  toolButton_->setChecked(false);
  showTools(false);
  toolButton_->hide();	//#dk (shouldn't show until 'tools' exist).

  hideDisplayButtons();
  
  uiDataType_["Unknown"] = Unknown;
  uiDataType_["Image"] = Image;
  uiDataType_["Measurement Set"] = Measurement;
  uiDataType_["Sky Catalog"] = Catalog;
  uiDataType_["Table"] = Table;
  uiDataType_["FITS"] = Image;
  uiDataType_["Miriad Image"] = Image;
  uiDataType_["IERS"] = Catalog;
  uiDataType_["Skycatalog"] = Table;
  uiDataType_["Gipsy"] = Image;

  
  dataType_["unknown"] = Unknown;
  dataType_["image"] = Image;
  dataType_["ms"] = Measurement;
  dataType_["skycatalog"] = Catalog;
  dataType_["table"] = Table;
  
  uiDisplayType_["Raster Image"] = RasterImage;
  uiDisplayType_["Contour Map"] = ContourMap;
  uiDisplayType_["Vector Map"] = VectorMap;
  uiDisplayType_["Marker Map"] = MarkerMap;
  uiDisplayType_["Sky Catalog"] = SkyCatalog;
  
  displayType_["raster"] = RasterImage;
  displayType_["contour"] = ContourMap;
  displayType_["vector"] = VectorMap;
  displayType_["marker"] = MarkerMap;
  displayType_["skycatalog"] = SkyCatalog;
  
  leaveOpen_->setToolTip("Uncheck to close this window after "
    "data and display type selection.\n"
    "Use 'Open' button/menu on Display Panel to show it again.");
  leaveOpen_->setChecked(False);
    
  dir_.setFilter(QDir::AllDirs | //QDir::NoSymLinks |
                 QDir::Files);
  dir_.setSorting(QDir::Name);


  QSettings settings("NRAO", "casa");
  QString lastDir = settings.value("lastDir", dir_.currentPath()).toString();
  //cout << "lastDir=" << lastDir.toStdString() << endl;
  dir_.cd(lastDir);
  dirLineEdit_->setText(lastDir);
  
  buildDirTree();
  
  
  connect(rasterButton_,  SIGNAL(clicked()), SLOT(createButtonClicked()));
  connect(contourButton_, SIGNAL(clicked()), SLOT(createButtonClicked()));
  connect(vectorButton_,  SIGNAL(clicked()), SLOT(createButtonClicked()));
  connect(markerButton_,  SIGNAL(clicked()), SLOT(createButtonClicked()));
  connect(catalogButton_, SIGNAL(clicked()), SLOT(createButtonClicked()));

  //connect(registerCheck, SIGNAL(clicked()), 
  //      SLOT(registerClicked()));
  
  connect(dirLineEdit_,   SIGNAL(returnPressed()), SLOT(returnPressed()));
  
  connect(treeWidget_,    SIGNAL(itemSelectionChanged()),
			 SLOT(changeItemSelection()));
  
  connect(treeWidget_,    SIGNAL(itemClicked(QTreeWidgetItem*,int)),
			 SLOT(clickItem(QTreeWidgetItem*)));
  
  connect(treeWidget_,    SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)),
		         SLOT(doubleClickItem()));
  
  //connect(registerCheck, SIGNAL(toggled(bool)), displayGroupBox_,
  //			 SLOT(setChecked(bool)));
  
  connect(toolButton_,    SIGNAL(toggled(bool)),  SLOT(showTools(bool)));
  
  connect(toolButton_,    SIGNAL(clicked(bool)),
	  toolGroupBox_,  SLOT(setVisible(bool)));
  
}


QtDataManager::~QtDataManager(){
}


void QtDataManager::doubleClickItem(){
  //QMessageBox::warning(this, tr("QtDataManager"), tr("double"));
}


void QtDataManager::clickItem(QTreeWidgetItem* item){
  if (item) {
    if (item->text(1).compare("Directory") == 0) {
       QDir saved = dir_;
       if (dir_.cd(item->text(0))) {
         QStringList entryList = dir_.entryList();
         if (entryList.size() == 0) {
             QMessageBox::warning(this, tr("QtDataManager"),
	     tr("Could not enter the directory:\n %1").arg(dir_.path()));
             dir_ = saved;
         }
         dir_.makeAbsolute();
         QString s = dir_.cleanPath(dir_.path());         
         dirLineEdit_->setText(s);
         buildDirTree();
       }
    }
    else {

    }
  }
}


void QtDataManager::updateDirectory(QString str){
     QDir saved = dir_;
     if (dir_.cd(str)) {
       QStringList entryList = dir_.entryList();
       if (entryList.size() == 0) {
           QMessageBox::warning(this, tr("QtDataManager"),
	   tr("Could not enter the directory:\n %1").arg(dir_.path()));
           dir_ = saved;
       }
       dir_.makeAbsolute();
       dirLineEdit_->setText(dir_.path());
       buildDirTree();
     }
}


void QtDataManager::buildDirTree() {
/*
  treeWidget_->clear();
  QStringList lbl;
  lbl << "Name" << "Type";
  treeWidget_->setColumnCount(2);
  treeWidget_->setHeaderLabels(lbl);

  QTreeWidgetItem *dirItem;
  dir_.makeAbsolute();
  QStringList entryList = dir_.entryList();
  for (int i = 0; i < entryList.size(); i++) {    
    QString it = entryList.at(i);
    if (it.compare(".") > 0) {
      if (!(dir_.path().compare("//") == 0 && it.compare("..") == 0)) {      
         dirItem = new QTreeWidgetItem(treeWidget_);
         dirItem->setText(0, it);
         QString path = dir_.path() + "/" +  entryList.at(i);
         QString type = fileType(path);
         
	 //#dk if (type.compare("Table") == 0) {
         if (type=="Table") {
           
	   try {
             casa::Table tbl(path.toStdString());
             TableInfo tblinfo = tbl.tableInfo();
             
	     //#dk String info = tblinfo.type();
             //#dk for (unsigned int i = 0; i < info.length(); i++) {
             //#dk   type[i] = info[i];
	     //#dk }
	     if(tblinfo.type()!="") type = tblinfo.type().chars();
             
	   }
           catch (const AipsError& err) {
	     String filenm = it.toStdString();
	     String msg = "Error reading data table '"+filenm+"':\n  "
	                  + err.getMesg();
             //QMessageBox::warning(this, "QtDataManager", msg.chars());
             emit tableReadErrorSignal(msg);
             type = "Bad Table";
           }
           catch (...) {
	     String filenm = it.toStdString();
	     String msg = "Unknown error reading data table '"+filenm+"'.\n"
	                  "(It is likely there is something wrong"
	                  " with the table itself).";
             //QMessageBox::warning(this, "QtDataManager", msg.chars());
             emit tableReadErrorSignal(msg);
             type = "Bad Table";
           }
         }  
         dirItem->setText(1, type);   
         dirItem->setTextColor(1, getDirColor(uiDataType_[type]));
      }  
    }
  }
*/
   treeWidget_->clear();
    QStringList lbl;
    lbl << "Name" << "Type";
    treeWidget_->setColumnCount(2);
    treeWidget_->setHeaderLabels(lbl);

    QTreeWidgetItem *dirItem;
    dir_.makeAbsolute();
    QStringList entryList = dir_.entryList();
    for (int i = 0; i < entryList.size(); i++)
    {
        QString it = entryList.at(i);
        if (it.compare(".") > 0)
        {
            if (!(dir_.path().compare("//") == 0 && it.compare("..") == 0)) {
                QString path = dir_.path() + "/" +  entryList.at(i);
                QString type = fileType(path);
                //cout << "path=" << path.toStdString()
                //        << "type=" << type.toStdString() << endl
;
                if (type.compare("Unknown") == 0) {
                   //do not show it
                }
                else {
                    dirItem = new QTreeWidgetItem(treeWidget_);
                    dirItem->setText(0, it);
                    if (type.compare("Table") == 0)
                    {
                        try
                        {
                            casa::Table tbl(path.toStdString());
                            casa::TableInfo tblinfo = tbl.tableInfo();
                            casa::String info = tblinfo.type();
                            //cout << "info=" << info << endl;
                            for (unsigned int i = 0; i < info.length(); i++)
                            {
                                type[i] = info[i];
                            }
                        }
                        catch (...)
                        {
                            type = "Bad Table";
                        }
                    }
                    //else if (type.compare("Miriad Image") == 0)
                    //{
                    //    cout << "miriad" << endl;
                    //}
                    if (type.compare("IERSe") == 0)
                    {
                        type ="IERS";
                    }
                    dirItem->setText(1, type);
                    dirItem->setTextColor(1, getDirColor(uiDataType_[type]));
                }
            }
        }
    }
    QSettings settings("NRAO", "casa");
    //cout << "dir_.path()=" << dir_.path().toStdString() << endl;
    settings.setValue("lastDir", dir_.path());

}


void QtDataManager::changeItemSelection(){
  QList<QTreeWidgetItem *> lst = treeWidget_->selectedItems();
  if (!lst.empty()) {
      QTreeWidgetItem *item = (QTreeWidgetItem*)(lst.at(0));
      showDisplayButtons(uiDataType_[item->text(1)]);
      //try {
      //  
      //}
      //catch (...) {
      //  QMessageBox::warning(this, tr("QtDataManager"),  tr("fail on "));
      //}
  }
}



void QtDataManager::showDisplayButtons(int ddtp) {
  hideDisplayButtons();
  switch (ddtp) {
     case Image :
        rasterButton_->show();
        contourButton_->show();
        vectorButton_->show();
        markerButton_->show();
        break;      
     case Measurement :
        rasterButton_->show();        
        break;
     case Catalog:        
        catalogButton_->show();
        break;
  }
}


QString QtDataManager::fileType(const QString pathName) {
    QFileInfo fileInfo(pathName);
    
    QString result = "Unknown";
    if (fileInfo.isFile())
    {
        QFile file(pathName);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text))
        {
           char buf[1024];
           qint64 lineLength = file.readLine(buf, sizeof(buf));
           if (lineLength > 1000) {
             QString line(buf);
             //cout << "line=" << line.toStdString() << endl;
              if (line.remove(' ').contains("SIMPLE=T"))
              {
                  result = "FITS";
              }
           }
        }
    }
    else if (fileInfo.isDir())
    {
        QFileInfo tab(pathName + "/table.dat");
        if (tab.isFile ())
        {
            return "Table";
        }

        QFileInfo hd(pathName,  "header");
        QFileInfo imt(pathName +  "/image" );
        if (hd.isFile() && imt.exists())
       {
            return "Miriad Image";
        }
        QFileInfo vis(pathName + "/visdata" );
        if (hd.isFile() && vis.exists() )
        {
           return "Miriad Vis";
        }
        else
        {
            result = "Directory";
        }
    }
    else if (fileInfo.isSymLink())
    {
        result = "SymLink";
    }
    else if (! fileInfo.exists())
    {
        result = "Invalid";
    }
    else
    {
        result = "Unknown";
    }

  
  return result;
}


QColor QtDataManager::getDirColor(int ddtp) {
  QColor clr;
  switch (ddtp) {
     case Image:            clr = Qt::darkGreen; break;
     case Measurement:      clr = Qt::darkBlue;  break;
     case Catalog:          clr = Qt::darkMagenta;    break;
     case Table:            clr = Qt::darkCyan;  break;
     case Unknown: default: clr = Qt::black;   }
     
  return clr;
}


void QtDataManager::hideDisplayButtons(){
  rasterButton_->hide();
  contourButton_->hide();
  vectorButton_->hide();
  markerButton_->hide();
  catalogButton_->hide();
}


void QtDataManager::returnPressed(){
  QString str = dirLineEdit_->text();
  updateDirectory(str);
}



void QtDataManager::createButtonClicked() {
  String path, datatype, displaytype;
  if (treeWidget_->currentItem() == 0) return;  
  path = (dir_.path() + "/" + treeWidget_->currentItem()->text(0))
	 .toStdString();

  datatype = dataType_.key( uiDataType_[treeWidget_->currentItem()->text(1)] )
		      .toStdString();

  QPushButton* button = dynamic_cast<QPushButton*>(sender());
  if(button!=0) {
    displaytype = (displayType_.key(uiDisplayType_[button->text()]))
		  .toStdString();  }

  
  if(viewer_!=0 && datatype!="" && displaytype!="") {
    viewer_->createDD(path, datatype, displaytype);  }
  

  if(!leaveOpen_->isChecked()) close();  // (will hide dialog, for now)

}



void QtDataManager::showTools(bool show) {
   if (show) {
      //resize(QSize(537, 386).expandedTo(minimumSizeHint()));
      toolButton_->setText(QApplication::translate("QtDataManager",
						  "Hide Tools"));
   }
   else {
      //resize(QSize(537, 260).expandedTo(minimumSizeHint()));
      toolButton_->setText(QApplication::translate("QtDataManager",
						  "Show Tools"));
   }
   
   toolGroupBox_->setVisible(show);      
}


 
QString QtDataManager::getDataName(int ddtp) {
  QString str;
  switch (ddtp) {
     case Image :
        str = "Image";
        break;
     case Measurement :
        str = "Measurement Set";
        break;
     case Catalog:
        str = "Sky Catalog";
        break;
     case Table:
        str = "Table";
        break;
     case Unknown:
     default:
        str = "Directory";
   }
   return str;
}



} //# NAMESPACE CASA - END
