//#---------------------------------------------------------------------------
//# pksmb_support.cc: Support functions for Parkes glish clients.
//#---------------------------------------------------------------------------
//# Copyright (C) 1994-2006
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
//# Original: David Barnes, February 1997
//# $Id: pksmb_support.cc,v 19.8 2006/05/19 00:02:51 mcalabre Exp $
//----------------------------------------------------------------------------

// AIPS++ includes.
#include <casa/sstream.h>
#include <casa/Arrays/Array.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishEvent.h>
#include <tasking/Glish/GlishRecord.h>
#include <casa/BasicSL/Complex.h>
#include <casa/BasicSL/String.h>

// Parkes includes.
#include <atnf/pks/pksmb_support.h>


GlishSysEventSource *g_glishStream;
GlishRecord g_msg;

//----------------------------------------------------------------- pksmbSetup

void pksmbSetup(GlishSysEventSource &glishStream, String clientName)
{
  glishStream.addTarget(shutdown_event, "shutdown");
  glishStream.setDefault(unknown_event);

  // Set up message handling.
  g_glishStream = &glishStream;
  g_msg.add("location", clientName);

  // Install client.
  glishStream.loop();
}

//------------------------------------------------------------- shutdown_event

// Handler for "shutdown" event.

Bool shutdown_event(GlishSysEvent &, void *)
{
  exit(0);

  return True;
}

//-------------------------------------------------------------- unknown_event

// Handler for "unknown" event.

Bool unknown_event(GlishSysEvent &event, void *)
{
  logWarning("WARNING: Unknown event: " + event.type());
  return True;
}

//-------------------------------------------------------------------- getParm

// Utility functions for extracting parameter values from a Glish record.

template<class T>
Bool getParm(const GlishRecord &parms,
             const String &item,
             const T &default_val,
             T &value)
{
  if (parms.exists(item)) {
    GlishArray tmp = parms.get(item);
    tmp.get(value);
    return True;
  } else {
    value = default_val;
    return False;
  }
}

template Bool getParm(const GlishRecord &parms, const String &item,
                      const Bool &default_val, Bool &value);
template Bool getParm(const GlishRecord &parms, const String &item,
                      const Int &default_val, Int &value);
template Bool getParm(const GlishRecord &parms, const String &item,
                      const Float &default_val, Float &value);
template Bool getParm(const GlishRecord &parms, const String &item,
                      const Double &default_val, Double &value);
template Bool getParm(const GlishRecord &parms, const String &item,
                      const Complex &default_val, Complex &value);
template Bool getParm(const GlishRecord &parms, const String &item,
                      const String &default_val, String &value);

template<class T>
Bool getParm(const GlishRecord &parms,
             const String &item,
             const T &default_val,
             Array<T> &value)
{
  if (parms.exists(item)) {
    GlishArray tmp = parms.get(item);
    tmp.get(value);
    return True;
  } else {
    value = default_val;
    return False;
  }
}

template Bool getParm(const GlishRecord &parms, const String &item,
                      const Bool &default_val, Array<Bool> &value);
template Bool getParm(const GlishRecord &parms, const String &item,
                      const Int &default_val, Array<Int> &value);
template Bool getParm(const GlishRecord &parms, const String &item,
                      const Float &default_val, Array<Float> &value);
template Bool getParm(const GlishRecord &parms, const String &item,
                      const Double &default_val, Array<Double> &value);
template Bool getParm(const GlishRecord &parms, const String &item,
                      const Complex &default_val, Array<Complex> &value);
template Bool getParm(const GlishRecord &parms, const String &item,
                      const String &default_val, Array<String> &value);

template<class T>
Bool getParm(const GlishRecord &parms,
             const String &item,
             const Array<T> &default_val,
             Array<T> &value)
{
  if (parms.exists(item)) {
    GlishArray tmp = parms.get(item);
    tmp.get(value);
    return True;
  } else {
    value.assign(default_val);
    return False;
  }
}

template Bool getParm(const GlishRecord &parms, const String &item,
                      const Array<Bool> &default_val, Array<Bool> &value);
template Bool getParm(const GlishRecord &parms, const String &item,
                      const Array<Int> &default_val, Array<Int> &value);
template Bool getParm(const GlishRecord &parms, const String &item,
                      const Array<Float> &default_val, Array<Float> &value);
template Bool getParm(const GlishRecord &parms, const String &item,
                      const Array<Double> &default_val, Array<Double> &value);
template Bool getParm(const GlishRecord &parms, const String &item,
                      const Array<Complex> &default_val, Array<Complex> &value);
template Bool getParm(const GlishRecord &parms, const String &item,
                      const Array<String> &default_val, Array<String> &value);

//----------------------------------------------------------------- logMessage

// Log message.

void logMessage(String msg)
{
  g_msg.add("message",  msg);
  g_msg.add("priority", "NORMAL");

  g_glishStream->postEvent("log", g_msg);
}

void logMessage(String msg, uInt val, String suffix)
{
  logMessage(msg, Int(val), suffix);
}

void logMessage(String msg, Int val, String suffix)
{
  ostringstream buf;

  buf << msg << val;
  if (suffix != "") {
    buf << suffix;
  }

  logMessage(String(buf.str()));
}

void logMessage(String msg, Double val, String suffix)
{
  ostringstream buf;

  buf << msg << val;
  if (suffix != "") {
    buf << suffix;
  }

  logMessage(String(buf.str()));
}

//----------------------------------------------------------------- logWarning

// Log warning.

void logWarning(String warn)
{
  g_msg.add("message",  warn);
  g_msg.add("priority", "WARN");

  g_glishStream->postEvent("log", g_msg);
}

//------------------------------------------------------------------- logError

// Log error.

void logError(String err)
{
  g_msg.add("message",  err);
  g_msg.add("priority", "SEVERE");

  g_glishStream->postEvent("log", g_msg);
}
