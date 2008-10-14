//# GTkDisplayProxy.h: wrapper for interfacing DisplayLibrary to GlishTk
//# Copyright (C) 1999,2000
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
//# $Id: GTkDisplayProxy.h,v 19.4 2005/06/15 18:09:12 cvsmgr Exp $

#ifndef TRIALDISPLAY_GTKDISPLAYPROXY_H
#define TRIALDISPLAY_GTKDISPLAYPROXY_H

//# glish includes:
//# wrapper needed to hide Time in tk.h I think.


#include <casa/aips.h>
#include <graphics/X11/X_enter.h>
#include <Glish/glishtk.h>
#ifdef List
#undef List
#endif
#include <graphics/X11/X_exit.h>

#include <casa/Exceptions/Error.h>
#include <casa/Logging/LogIO.h>

namespace casa {
   class LogSinkInterface;

#include <casa/namespace.h>
//class GTkLogSink;

class GTkDisplayProxy : public TkProxy {

 public:

  GTkDisplayProxy(ProxyStore *s, int init_graphic = 1);

  virtual ~GTkDisplayProxy();

  // post error messages to GlishTk
  // <group>
  void postError(const LogOrigin &origin, const AipsError &error);
  void postError(const LogOrigin &origin, const String message,
		 const LogMessage::Priority priority = LogMessage::NORMAL);
  // </group>

  // install a GTkLogSink as the global LogSink
  void installGTkLogSink();
  
  // install a NullLogSink as the global LogSink
  void installNullLogSink();

 protected:

  // Turn logging and logging exceptions on or off
  // <group>
  void logging(const casa::Bool state);
  void loggingExceptions(const casa::Bool state);
  // </group>

  // Helper function: return the specified Bool value if a 
  // reply is pending.
  virtual void replyIfPending(const casa::Bool &value = True);

 private:

  // Should anything be logged?
  casa::Bool itsIsLogging;

  // Should exceptions be logged as well as causing fails?
  casa::Bool itsIsLoggingExceptions;
  
  // Emit a message to GlishTk
  void emitMessage(const String &origin, const String &message,
		   const LogMessage::Priority priority);

  // "temporary" storage for LogSinks
  LogSinkInterface *itsGTkLogSink;
  LogSinkInterface *itsNullLogSink;

};

}

#endif
