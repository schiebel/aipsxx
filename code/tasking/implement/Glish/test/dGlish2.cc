//# dGlish.cc: A small demonstration program of the Glish wrapper classes
//# Copyright (C) 1994,1995,1998,2001
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
//# $Id: dGlish2.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

// Demonstration of using the AIPS++ Glish wrapper classes to interleave
// processing of Glish events. This client accepts 'short' and 'long'
// events. The 'long' event simulate a long event handling process which
// checks four times to see if other events are waiting. If there are
// other events, they are dispatched. The 'short' events are, well, short
// events which take little time to process. To try out this client, do
// something like:
//
//	- c := client('./dGlish2')
//	- c->long(); c->short(); c->long(); c->short()
//	- # wait a bit
//	- c->short()
//

#include <tasking/Glish.h>
#include <casa/iostream.h>
#include <unistd.h>

#include <casa/namespace.h>
void check_events( GlishSysEventSource &s, int count=1 ) {
    cerr << "---------- starting check #" << count << " ----------" << endl;
    while ( s.waitingEvent( ) )
	{
	GlishSysEvent e = s.nextGlishEvent();
	s.processEvent( e );
	}
    cerr << "---------- ending check #" << count << "   ----------" << endl;
}

Bool longCallback(GlishSysEvent &e, void *) {
    GlishSysEventSource *src =  (GlishSysEventSource*)e.source();
    (*src).postEvent("long_start",e.type());
    sleep(5);
    check_events( *src, 1 );
    sleep(5);
    check_events( *src, 2 );
    sleep(5);
    check_events( *src, 3 );
    sleep(5);
    check_events( *src, 4 );
    sleep(5);
    (*src).postEvent("long_end",e.type());
    return True;
}

Bool shortCallback(GlishSysEvent &e, void *) {
    GlishSysEventSource *src =  (GlishSysEventSource*)e.source();
    (*src).postEvent("short_got",e.type());
    return True;
}

Bool defaultCallback(GlishSysEvent &e, void *) {
    GlishSysEventSource *src =  (GlishSysEventSource*)e.source();
    (*src).postEvent("default_got",e.type());
    return True;
}

int main(int argc, char **argv) {

    GlishSysEventSource eventStream(argc, argv);
    GlishSysEvent event;

    eventStream.setDefault(defaultCallback);
    eventStream.addTarget(longCallback,"^[Ll][Oo][Nn][Gg]");
    eventStream.addTarget(shortCallback,"^[Ss][Hh][Oo][Rr][Tt]");

    eventStream.loop();
}
