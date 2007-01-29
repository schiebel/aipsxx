//# GTkLogSink.h: buffer and send log messages out to Glish/Tk from a proxy
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
//# $Id: GTkLogSink.h,v 19.6 2005/06/15 18:09:12 cvsmgr Exp $

#ifndef TRIALDISPLAY_GTKLOGSINK_H
#define TRIALDISPLAY_GTKLOGSINK_H

#include <casa/aips.h>
#include <casa/Logging/LogSinkInterface.h>

#if defined(Queue)
#undef Queue
#endif
#include <casa/Containers/Queue.h>

namespace casa {

class GTkDisplayProxy;

// <summary>
// Buffer and send log messages out to Glish/Tk from a proxy.
// </summary>
//
// <use visibility=local>
//
// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>
//
// <prerequisite>
// <li> <linkto class=LogSinkInterface>LogSinkInterface</linkto>
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// <src>GTkLogSink</src> is a straightforward <linkto
// class=LogSinkInterface>LogSinkInterface</linkto> which sends its
// messages to Glish/Tk via the proxy which is given at construction
// time.
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <todo asof="yyyy/mm/dd">
// </todo>

class GTkLogSink : public LogSinkInterface {

 public:

  // Constructor needs the place to send the messages.
  GTkLogSink(GTkDisplayProxy *s);

  // Destructor.
  ~GTkLogSink();

  // Buffer a <src>message</src> to be written to Glish/Tk if it
  // passes the filter.
  virtual casa::Bool postLocally(const LogMessage &message);
  
  // Flush the buffer, ie. post all buffered messages out to Glish/Tk.
  virtual void flushBuffer(const casa::Bool &send = True);

  // Flush, over-ridden from base class.
  virtual void flush(casa::Bool global=True) 
    { flushBuffer(); }

  // Returns the id for this class...
  static String localId( );
  // Returns the id of the LogSink in use...
  String id( ) const;

private:

  // Store the proxy to use for emitting messages here.
  GTkDisplayProxy *itsGTkDisplayProxy;

  // Store the queued messages here.
  Queue<LogMessage> itsMessageQueue;

};

}
#endif
