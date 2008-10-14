//# QtDisplayData.qo.h: Qt DisplayData wrapper.
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
//# $Id: QtDisplayData.qo.h,v 1.5 2006/09/13 22:26:07 hye Exp $

#ifndef QTDISPLAYDATA_H
#define QTDISPLAYDATA_H

#include <casa/aips.h>
#include <casa/BasicSL/String.h>
#include <casa/Containers/Record.h>
#include <coordinates/Coordinates/CoordinateSystem.h>

#include <graphics/X11/X_enter.h>
#include <QtCore>
#include <QObject>
#include <graphics/X11/X_exit.h>


namespace casa { //# NAMESPACE CASA - BEGIN

class String;
class Record;
class DisplayData;
template <class T> class ImageInterface;




class QtDisplayData : public QObject {

  Q_OBJECT	//# Allows slot/signal definition.  Must only occur in
		//# implement/.../*.h files; also, makefile must include
		//# name of this file in 'mocs' section.

 public:
  
  QtDisplayData(String path, String dataType, String displayType);
  ~QtDisplayData();
  
  virtual String name() { return name_;  }
  virtual const char* nameChrs() { return name_.c_str();  }
  virtual void setName(const String& name) { name_ = name;  }
 
  virtual String path() { return path_;  }
  virtual String dataType() { return dataType_;  }
  virtual String displayType() { return displayType_;  }
  
  virtual String errMsg() { return errMsg_;  }
  
  // retrieve the Record of options.  This is similar to a 'Parameter Set',
  // containing option types, default values, and meta-information,
  // suitable for building a user interface for controlling the DD.
  virtual Record getOptions();
    
  // retrieve wrapped DisplayData.
  //# (should probably be private, and 'friend'ed only to QtDP, which
  //# needs it for registration purposes...).
  virtual DisplayData* dd() { return dd_;  }
  
  // Did creation of wrapped DD fail?
  virtual Bool isEmpty() { return dd_==0;  }  
  
  void getInitialAxes(Block<uInt>& axs, const IPosition& shape) ;
  
 public slots:
  
  // Apply option values to the DisplayData.  Method will
  // emit optionsChanged() if other option values, limits, etc.
  // should also change as a result.
  virtual void setOptions(Record opts);
  
  
  virtual void done();
 
 
 signals:

  // Signals changes the DD has made internally to option values, limits,
  // etc., that ui (if any) will want to reflect.  Calling setOptions()
  // to change one option value may cause this to be emitted with any other
  // options which have changed as a result.
  void optionsChanged(Record changedOptions);

  // Emitted when problems encountered (in setOptions, e.g.) 
  void qddError(String errmsg);
 
  // Emitted when options successfully set without error.
  void optionsSet();
  
  // This object will be destroyed after this signal is processed.
  // (Note: if this DD is managed in QtViewer's list, it is preferable
  // to connect to QtViewerBase::ddRemoved() instead).
  //void dying(QtDisplayData*);
  

 
 protected:
  
  // Heuristic used internally to set initial axes to display on X, Y and Z,
  // for PADDs.  shape should be that of Image/Array, and have same nelements
  // as axs.  On return, axs[0], axs[1] and (if it exists) axs[2] will be axes
  // to display initially on X, Y, and animator, respectively.
  // If you pass a CS for the image, it will give special consideration to
  // Spectral [/ Direction] axes (users expect their spectral axes on Z, e.g.)
  //# (Lifted bodily from GTkDD).
  virtual void getInitialAxes_(Block<uInt>& axs, const IPosition& shape,
			       const CoordinateSystem* cs=0);

 
 private:
  
  // Not intended for use.
  QtDisplayData() : im_(0), dd_(0) {  }

  //# data
  String path_, dataType_, displayType_;
  ImageInterface<Float>* im_;
  DisplayData* dd_;
  
  String name_;
  
  String errMsg_;
  
};


} //# NAMESPACE CASA - END


//# Allows QtDisplayData* to be stored in a QVariant; e.g., to be
//# the data associated with a QAction....  See QMetaType and
//# QVariant class doc.  QVariants are rather well-designed
//# generic value holders.
//# Note: this declaration cannot be placed within the casa namespace.
Q_DECLARE_METATYPE(casa::QtDisplayData*)


#endif
