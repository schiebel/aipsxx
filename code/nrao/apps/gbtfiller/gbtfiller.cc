//# gbtfiller.cc: fill and GBT backend Table for a specific project
//# Copyright (C) 1995,1997,1999,2000,2001
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
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
//#
//# $Id: gbtfiller.cc,v 19.3 2004/11/30 17:50:40 ddebonis Exp $

//# Includes

#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <casa/Exceptions/Error.h>
#include <casa/Arrays/Slice.h>
#include <tasking/Glish.h>
#include <casa/OS/Timer.h>
#include <tables/Tables/Table.h>
#include <casa/iostream.h>

#include <GBTFillerInputs.h>
#include <GBTFillerState.h>

#include <casa/namespace.h>

Bool serverLoop(GlishSysEventSource* eventStream, String& error);

void fillit(GBTFillerState &, GlishSysEventSource *);

int main (int argc, char **argv) {
    Timer timer;
    GlishSysEventSource eventStream(argc, argv);

    String error = "";
    Bool result = True;

    try {
	if (eventStream.hasInterpreter()) {
	    result = serverLoop(&eventStream, error);
	} else {
	    GBTFillerState state(argc, argv);
	    if (state.inputs().ok()) fillit(state, 0);
	    else 
		cerr << state.inputs().errorMsg() << endl;
	}
    } catch (AipsError x) {
	error = x.getMesg();
	result = False;
    } 

    if (result == False) {
	if (eventStream.hasInterpreter()) {
	    eventStream.postEvent("failed",error);
	} else {
	    cerr << error << endl;
	}
	timer.show("ABORTED:");
	return(1);
    }

    timer.show("Ends Successfully");
    return(0);
}

Bool serverLoop(GlishSysEventSource *eventStream, String &error)
{
    GlishSysEvent event;

    while (eventStream && eventStream->connected()) {
	event = eventStream->nextGlishEvent();  // Get an event - blocks
	if (event.type() == "help") {
	    String msg = String("GBTFiller is waiting for inputs\n") +
		String("It will respond to these events at this time :\n") +
		    String("\tfill - start filling using the inputs record sent with this event\n") +
			String("\tshutdown - the filler will exit");
	    eventStream->postEvent("help_result", msg);
	} else if (event.type() == "fill") {
	    Timer timer;
	    GBTFillerState state(event.val(), eventStream);
	    if (state.inputs().ok()) fillit(state, eventStream);
	    else 
		eventStream->postEvent("error", state.inputs().errorMsg());
	    GlishRecord resultRecord;
	    resultRecord.add("cpu",timer.all());
	    resultRecord.add("real",timer.real());
	    eventStream->postEvent("fill_result",resultRecord);
	} else if (event.type() == "update") {
	    eventStream->postEvent("update_result","not filling - update ignored.");
	} else if (event.type() == "queryState") {
	    eventStream->postEvent("state","suspended");
	} else if (event.type() == "terminate" ||
		   event.type() == "shutdown") {
	    eventStream->postEvent("shutdown_result","exiting.");
	    eventStream = static_cast<GlishSysEventSource *>(0);
	} else {
	    error = String("Unknown event : ") + event.type();
	    eventStream->postEvent("error", error);
	}
    }
    return True;
}

void fillit(GBTFillerState &state, GlishSysEventSource *eventStream)
{
    // first, fill until end reached as specified in initial "fill" event
    state.fillit();
    // issue initial fill_result event
    if (eventStream && eventStream->connected() && !state.endOfTimeRange()) {
	eventStream->postEvent("fill_result","OK");
    }

    // now, wait for "update" or "suspend" events
    GlishSysEvent event;
    // we need to not block here so that the currently opened table
    // can be unlocked as needed.
    Int defaultTimeout = 5000;
    Bool gotevent;
    Int thisTimeout;
    Int idletime = 0;
    while (eventStream && eventStream->connected() && !state.endOfTimeRange()) {
	if (Table::nAutoLocks()) thisTimeout = defaultTimeout;
	else thisTimeout = -1;
	gotevent = eventStream->nextGlishEvent(event, thisTimeout);
	if (gotevent) {
	  if (event.type() == "help") {
	    String msg = String("gbtfiller is waiting for one of the following:\n") +
	      String("\tupdate - resume filling if new data in initial range is found.\n") +
	      String("\tsuspend - go back to standby mode for new fill event.") +
	      String("\tshutdown - gbtfiller will exit.");
	    eventStream->postEvent("help_result", msg);
	  } else if (event.type() == "update") {
	    state.update();
	    state.fillit();
	    eventStream->postEvent("update_result","OK");
	  } else if (event.type() == "fill") {
	    eventStream->postEvent("fill_result","use suspend before fill.");
	  } else if (event.type() == "queryState") {
	    eventStream->postEvent("state","paused");	
	  } else if (event.type() == "suspend") {
	    break;
	  } else if (event.type() == "terminate" || event.type() == "shutdown") {
	    eventStream->postEvent("shutdown_result","exiting.");
	    eventStream = static_cast<GlishSysEventSource *>(0);
	  } else {
	    String error = String("Unknown event : ") + event.type();
	    eventStream->postEvent("error", error);
	  }
	    idletime = 0;
	} else {
	    idletime += thisTimeout;
	    if (idletime > 10*defaultTimeout) {
		// just relinquish everything, clearly we aren't doing much
		Table::relinquishAutoLocks(True);
	    } else {
		Table::relinquishAutoLocks(False);
	    }
	}
    }    
}
