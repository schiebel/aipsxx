//# GTkLogSink.cc: Send log messages out to Glish/Tk via a proxy
//# Copyright (C) 1999
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
//# $Id: GTkLogSink.cc,v 19.3 2005/06/15 18:09:12 cvsmgr Exp $

#include "GTkDisplayProxy.h"
#include "GTkLogSink.h"

namespace casa {

String GTkLogSink::localId( ) {
    return String("GTkLogSink");
}

String GTkLogSink::id( ) const {
    return String("GTkLogSink");
}

// Constructor.
GTkLogSink::GTkLogSink(GTkDisplayProxy *s) :
  itsGTkDisplayProxy(s) {
  itsMessageQueue.clear();
}

// Destructor.
GTkLogSink::~GTkLogSink() {
  itsMessageQueue.clear();
}

// Buffer a message to be written to Glish/Tk if it passes the filter.
casa::Bool GTkLogSink::postLocally(const LogMessage &message) {
  casa::Bool doPost = filter().pass(message);
  if (doPost) {
    itsMessageQueue.enqueue(message);
  }
  return doPost;
}

// Flush the buffer, ie. post all pending messages out to Glish/Tk.
void GTkLogSink::flushBuffer(const casa::Bool &send) {
  if (send) {
    LogMessage message;
    while (itsMessageQueue.nelements()) {
      itsMessageQueue.dequeue(message);
      itsGTkDisplayProxy->postError(message.origin(), message.message(),
				    message.priority());
    }
  }
  itsMessageQueue.clear();
}

}
