//# qtviewer.cc:  main program for standalone Qt viewer
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
//# $Id: qtviewer.cc,v 1.5 2006/08/11 22:21:20 dking Exp $

#include <casa/aips.h>
#include <casa/iostream.h>
#include <casa/Inputs/Input.h>
#include <casa/BasicSL/String.h>
#include <casa/Containers/Record.h>
#include <casa/Exceptions/Error.h>
#include <display/Display/StandAloneDisplayApp.h>
	// (Configures pgplot for stand-alone Display Library apps).

#include <display/QtViewer/QtDisplayData.qo.h>
#include <display/QtViewer/QtDisplayPanelGui.qo.h>
#include <display/QtViewer/QtViewer.qo.h>
#include <display/QtViewer/QtApp.h>

/*
#include <graphics/X11/X_enter.h>
#include   <QApplication>
#include <graphics/X11/X_exit.h>
*/


#include <casa/namespace.h>


int main( int argc, char **argv ) {
 
 try {
  
  QApplication* qapp = QtApp::init(argc, argv); 
  
  QtViewer* v = new QtViewer;
  
  QtDisplayPanelGui* dpg = new QtDisplayPanelGui(v);
    
//String	   filename    = "/users/dking/a2d/6503.im",
  String	   filename    = "",
		   datatype    = "image",      
		   displaytype = "raster";
  
  if(qapp->argc()>1) filename    = qapp->argv()[1];
  if(qapp->argc()>2) datatype    = qapp->argv()[2];
  if(qapp->argc()>3) displaytype = qapp->argv()[3];
  
  QtDisplayData* qdd = 0;
      
  if(filename!="") {
  
    qdd = v->createDD(filename, datatype, displaytype);
  
    if(qdd!=0) {
      Record opts;
      opts.define("axislabelswitch", True);
      // opts.define("plotoutlinecolor",String("green"));
      qdd->setOptions(opts);  }
  
    else  cerr << v->errMsg() << endl;  }
    
      
  dpg->show();
  
  v->showDataManager();
  
  //v->showDataOptionsPanel();
  

  Int stat = QtApp::exec();
  
  //delete dpg;		// leads to crash on exit (why?)
  			// ***THIS IS IMPORTANT TO UNDERSTAND AND FIX***...
  
  delete v;
  QtApp::destroy();	// (probably unnecessary -- Is this a good idea?...)
  
  // cerr<<"Normal exit -- status: "<<stat<<endl;	//#diag
  
  return stat;  }
  

    
 catch (const casa::AipsError& err) { cerr<<"**"<<err.getMesg()<<endl;  }
 catch (...) { cerr<<"**non-AipsError exception**"<<endl;  }

}

