//# QtViewerBase.cc: Qt implementation of main viewer supervisory object
//#                  -- Functional level.
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
//# $Id: QtViewerBase.cc,v 1.4 2006/08/11 22:16:05 dking Exp $

#include <display/QtViewer/QtViewerBase.qo.h>
#include <display/QtViewer/QtDisplayData.qo.h>

namespace casa { //# NAMESPACE CASA - BEGIN


QtViewerBase::QtViewerBase() : qdds_(), errMsg_(), msbtns_() {
}


QtViewerBase::~QtViewerBase() {
  removeAllDDs();  }
  



QtDisplayData* QtViewerBase::createDD(String path, String dataType,
				  String displayType) {

  QtDisplayData* qdd = new QtDisplayData(path, dataType, displayType);
  
  if(qdd->isEmpty()) {
    errMsg_ = qdd->errMsg();
    emit createDDFailed(errMsg_, path, dataType, displayType);
    return 0;  }
    
  // Be sure name is unique by adding numerical suffix if necessary.
  
  String name=qdd->name();
  for(Int i=2; dd(name)!=0; i++) {
    name=qdd->name() + " <" + String::toString(i) + ">";  }
  qdd->setName(name);
  
  ListIter<QtDisplayData* > qdds(qdds_);
  qdds.toEnd();
  qdds.addRight(qdd);
  
  emit ddCreated(qdd);
  return qdd;  }

    
void QtViewerBase::removeAllDDs() {
  for(ListIter<QtDisplayData* > qdds(qdds_); !qdds.atEnd(); ) {
    QtDisplayData* qdd = qdds.getRight();
    
    qdds.removeRight();
    emit ddRemoved(qdd);
    qdd->done();
    delete qdd;  }  }
  
    

Bool QtViewerBase::removeDD(QtDisplayData* qdd) {
  for(ListIter<QtDisplayData* > qdds(qdds_); !qdds.atEnd(); qdds++) {
    if(qdd == qdds.getRight()) {
    
      qdds.removeRight();
      emit ddRemoved(qdd);
      qdd->done();
      delete qdd;
      return True;  }  }
  
  return False;  }
      

  
Bool QtViewerBase::ddExists(QtDisplayData* qdd) {
  for(ListIter<QtDisplayData* > qdds(qdds_); !qdds.atEnd(); qdds++) {
    if(qdd == qdds.getRight()) return True;  }
  return False;  }
      


QtDisplayData* QtViewerBase::dd(const String& name) {
  // retrieve DD with given name (0 if none).
  QtDisplayData* qdd;
  for(ListIter<QtDisplayData* > qdds(qdds_); !qdds.atEnd(); qdds++) {
    if( (qdd=qdds.getRight())->name() == name ) return qdd;  }
  return 0;  }
  
  


} //# NAMESPACE CASA - END
