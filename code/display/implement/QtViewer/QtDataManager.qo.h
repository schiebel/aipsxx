//# QtDataManager.qo.h: Qt implementation of viewer data manager widget.
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
//# $Id: QtDataManager.qo.h,v 1.3 2006/08/11 22:16:05 dking Exp $

#ifndef QTDATAMANAGER_H_
#define QTDATAMANAGER_H_

#include <casa/aips.h>
#include <casa/BasicSL/String.h>

#include <graphics/X11/X_enter.h>
#  include <QDir>
#  include <QColor>
#  include <QHash>
#  include <QWidget>
   //#dk Be careful to put *.ui.h within X_enter/exit bracket too,
   //#   because they'll have Qt includes.
   //#   E.g. <QApplication> needs the X11 definition of 'Display'
#  include <display/QtViewer/QtDataManager.ui.h>
#include <graphics/X11/X_exit.h>

 
namespace casa { //# NAMESPACE CASA - BEGIN

class QtViewer;


class QtDataManager : public QWidget, private Ui::QtDataManager {
   
   Q_OBJECT

 public:
  
  QtDataManager(QtViewer* viewer=0, const char* name=0,
		QWidget* parent=0 );
  ~QtDataManager();
  

 signals:
 
  void tableReadErrorSignal(String msg);
  

 protected:

  QString getDataName(int ddtp);
  void showDisplayButtons(int);
  void hideDisplayButtons();
  QColor getDirColor(int);
  void buildDirTree();
  void updateDirectory(const QString);
  QString fileType(const QString pathName);

  enum DATATYPE {Unknown, Image, Measurement, Catalog, Table};
  enum DISPLAYTYPE {RasterImage, ContourMap, VectorMap, MarkerMap,
		     SkyCatalog};

  QHash<QString, int> dataType_;
  QHash<QString, int> uiDataType_;
  QHash<QString, int> displayType_;
  QHash<QString, int> uiDisplayType_;
 
 
 protected slots:
  
  void createButtonClicked();
  void showTools(bool show);
  void doubleClickItem();
  void clickItem(QTreeWidgetItem* item);
  void changeItemSelection();
  void returnPressed();

 
 private:
  
  QWidget *parent_;
  QtViewer* viewer_;
  QDir dir_;  
  
};

} //# NAMESPACE CASA - END

#endif
