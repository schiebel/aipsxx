//#---------------------------------------------------------------------------
//# pksmonitor: Glish client that controls a display buffer.
//#---------------------------------------------------------------------------
//# Copyright (C) 1994-2004
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but
//# WITHOUT ANY WARRANTY; without even the implied warranty of
//# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
//# Public License for more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//----------------------------------------------------------------------------
// This Glish client translates Glish events into Monitor actions. 
//
// Original: Taisheng Ye, restructured by Tom Oosterloo.
// $Id: pksmonitor.cc,v 19.6 2006/05/19 04:41:47 mcalabre Exp $
//----------------------------------------------------------------------------

// AIPS++ includes.
#include <casa/iostream.h>
#include <casa/BasicSL/String.h>
#include <casa/Exceptions/Error.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishEvent.h>

// Parkes includes.
#include <atnf/pks/pksmb_support.h>

#include <Monitor.h>


#include <casa/namespace.h>

// Glish event handlers.
Bool init_event(GlishSysEvent &event, void *);
Bool newdata_event(GlishSysEvent &event, void *);
Bool flush_event(GlishSysEvent &event, void *);


// Global variables.
String gClientName = "pksmonitor";
Monitor theMonitor;

//----------------------------------------------------------------------- main

int main(int argc, char **argv)
{
  try {
    // Set up the Glish event stream.
    GlishSysEventSource glishStream(argc, argv);
    glishStream.addTarget(init_event, "init");
    glishStream.addTarget(newdata_event, "newdata");
    glishStream.addTarget(flush_event, "flush");
    pksmbSetup(glishStream, gClientName);

  } catch (AipsError x) {
    cerr << x.getMesg() << endl;
  }

  return 0;
}

//---------------------------------------------------------------- init_event

// Handler for "init" event.

Bool init_event(GlishSysEvent &event, void *)
{
  logMessage("");
  String version = "$Revision: 19.6 $";
  String date = "$Date: 2006/05/19 04:41:47 $";

  logMessage("pksmonitor (v" + String(version.after(' ')).before(' ') +
             ", " + String(date.after(' ')).before(' ') + ") initializing.");

  Bool retVal = theMonitor.initHandler(event);

  GlishSysEventSource *glishBus = event.glishSource();
  glishBus->postEvent("initProcessed", gClientName);

  return retVal;
}

//------------------------------------------------------------- newdata_event

// Handler for "newdata" event.

Bool newdata_event(GlishSysEvent &event, void *)
{
  uInt nRec;
  Bool retVal = theMonitor.newdataHandler(event, nRec);

  GlishSysEventSource *glishBus = event.glishSource();
  glishBus->postEvent("newdataProcessed", GlishArray(Int(nRec)));

  return retVal;
}

//--------------------------------------------------------------- flush_event

// Handler for "flush" event.

Bool flush_event(GlishSysEvent &event, void *)
{
  Bool retVal = theMonitor.flushHandler(event);

  GlishSysEventSource *glishBus = event.glishSource();
  glishBus->postEvent("flushProcessed", gClientName);

  return retVal;
}
