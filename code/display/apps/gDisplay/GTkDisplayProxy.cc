//# GTkDisplayProxy.cc: wrapper for interfacing DisplayLibrary to GlishTk
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
//# $Id: GTkDisplayProxy.cc,v 19.3 2005/06/15 18:09:12 cvsmgr Exp $

#include <casa/aips.h>
#include <casa/Exceptions/Error.h>
#include <casa/Logging/LogIO.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Logging/LogSink.h>
#include <casa/Logging/NullLogSink.h>
#include <casa/Logging/StreamLogSink.h>
#include "GTkLogSink.h"
#include "GTkDisplayProxy.h"

namespace casa {

GTkDisplayProxy::GTkDisplayProxy(ProxyStore *s, int init_graphic) :
  TkProxy(s, init_graphic),
  itsIsLogging(True),
  itsIsLoggingExceptions(True),
  itsGTkLogSink(0),
  itsNullLogSink(0) {
}

GTkDisplayProxy::~GTkDisplayProxy() {
  if (itsNullLogSink) {
    delete itsNullLogSink;
  }
  if (itsGTkLogSink) {
    delete itsGTkLogSink;
  }
}

void GTkDisplayProxy::logging(const casa::Bool state) {
  itsIsLogging = state;
}

void GTkDisplayProxy::loggingExceptions(const casa::Bool state) {
  itsIsLoggingExceptions = state;
}

void GTkDisplayProxy::replyIfPending(const casa::Bool &value) {
  /*
  if (ReplyPending()) {
    GlishArray glishval(value);
    Value *retval = new Value(*(glishval.value()));
    Reply(retval);
    delete retval;
  }
  */
}

void GTkDisplayProxy::postError(const LogOrigin &origin,
				const AipsError &error) {
  String strori = origin.className() + String("::") + origin.functionName();
  String message = strori + " failed; " + error.getMesg();
  Error(message.chars());
  if (itsIsLoggingExceptions) {
    emitMessage(strori, message, LogMessage::SEVERE);
  }
}

void GTkDisplayProxy::postError(const LogOrigin &origin, 
				const String message,
				const LogMessage::Priority priority) {
  String strori;
  strori = origin.className() + String("::") + origin.functionName();
  emitMessage(strori, message, priority);
}

void GTkDisplayProxy::installGTkLogSink() {
  /* 
 if (!itsGTkLogSink) {
    itsGTkLogSink = new GTkLogSink(this);
  }
  LogSink::globalSink(itsGTkLogSink);
  itsGTkLogSink = 0;*/
  installNullLogSink();
}

void GTkDisplayProxy::installNullLogSink() {
  if (!itsNullLogSink) {
    itsNullLogSink = new NullLogSink;
  }
  LogSink::globalSink(itsNullLogSink);
  itsNullLogSink = 0;
}

void GTkDisplayProxy::emitMessage(const String &origin,
				  const String &message,
				  const LogMessage::Priority priority) {
  if (itsIsLogging) {
    // set priority string
    String strpri("NORMAL");
    if (priority == LogMessage::WARN) {
      strpri = "WARN";
    } else if (priority == LogMessage::SEVERE) {
      strpri = "SEVERE";
    }
    // fill up record
    GlishRecord rec;
    rec.add("message", message);
    rec.add("origin", origin);
    rec.add("priority", strpri);
    // emit message
    Value *retval = new Value(*(rec.value()));
    if (ReplyPending()) {
      Reply(retval);
    } 
    PostTkEvent("logmessage", retval);
    delete retval;
  }
}

}
