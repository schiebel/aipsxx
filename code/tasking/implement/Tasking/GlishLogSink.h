//# GlishLogSink.h: Send log messages as Glish events.
//# Copyright (C) 1996,1998,2003
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
//# $Id: GlishLogSink.h,v 19.6 2004/11/30 17:51:11 ddebonis Exp $

#ifndef TASKING_GLISHLOGSINK_H
#define TASKING_GLISHLOGSINK_H

#include <casa/aips.h>
#include <casa/Logging/LogSink.h>
#include <casa/Utilities/CountedPtr.h>
#include <tasking/Glish/GlishEvent.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// Send log messages as Glish events.
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class=LogSinkInterface>LogSinkInterface</linkto>
//   <li> General knowledge of Glish records and events.
// </prerequisite>
//
// <synopsis>
// This log sink is used to post log messages to the Glish bus. While this has
// been implemented for the use of the AIPS++ Tasking system, it is independent
// of the Tasking system. If the current process is not connected to the Glish
// bus the messages is posted to <src>cerr</src> instead.
//
// On the assumption that log messages will be sent between the process and
// the user interface fairly often, the memory use of the current process tags
// along in the record.
//
// The posted Glish event is named <src>log</src> and is a record with the
// following format:
//
//# The following is automatically generated by Microsoft Word.
// <HEAD>
// <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=windows-1252">
// <META NAME="Generator" CONTENT="Microsoft Word 97">
// <META NAME="Template" CONTENT="C:\Program Files\Microsoft Office\Office\html.dot">
// </HEAD>
// <BODY LINK="#0000ff" VLINK="#800080">
// 
// <TABLE BORDER CELLSPACING=1 BORDERCOLOR="#000000" CELLPADDING=9 WIDTH=811>
// <TR><TD WIDTH="25%" VALIGN="TOP">
// <B><P ALIGN="CENTER">Field (type)</B></TD>
// <TD WIDTH="75%" VALIGN="TOP">
// <B><P ALIGN="CENTER">Contents</B></TD>
// </TR>
// <TR><TD WIDTH="25%" VALIGN="TOP">
// <P>nessage (string)</TD>
// <TD WIDTH="75%" VALIGN="TOP">
// <P>The posted message.</TD>
// </TR>
// <TR><TD WIDTH="25%" VALIGN="TOP">
// <P>time_mjd (double)</TD>
// <TD WIDTH="75%" VALIGN="TOP">
// <P>The time the message was created, MJD in days. Does not take into account the timezone.</TD>
// </TR>
// <TR><TD WIDTH="25%" VALIGN="TOP">
// <P>time_string (string)</TD>
// <TD WIDTH="75%" VALIGN="TOP">
// <P>Formatted version of the time, <I>including</I> the timezone.</TD>
// </TR>
// <TR><TD WIDTH="25%" VALIGN="TOP">
// <P>location (string)</TD>
// <TD WIDTH="75%" VALIGN="TOP">
// <P>Source code origin of the message. May contain all of function, file, and line number. Does not contain the ObjectID.</TD>
// </TR>
// <TR><TD WIDTH="25%" VALIGN="TOP">
// <P>id (record)</TD>
// <TD WIDTH="75%" VALIGN="TOP">
// <P>ObjectID of  the message originator, in the record format defined by ObjectID::toRecord().</TD>
// </TR>
// <TR><TD WIDTH="25%" VALIGN="TOP">
// <P>_memory (double)</TD>
// <TD WIDTH="75%" VALIGN="TOP">
// <P>Memory use of this process, in MB.</TD>
// </TR>
// </TABLE>
// </BODY>
// 
// In general, you do not need to set up GlishLogSink yourself, the Tasking
// system will use it for you. However if you have a nonstandard client from
// which you wish to post log messages in the standard format on the Glish
// bus, you merely have to replace the global sink with a GlishLogSink.
//
// <example>
// If you wanted to setup a non-tasking executable to log messages in the 
// standard way to the glish bus so the log window and log table will behave
// normally for the user, you can do so as follows:
// <srcblock>
// int main(int argc, char **argv)
// {
//    CountedPtr<GlishSysEventSource> ptr(new GlishSysEventSource(argc, argv));
//    LogFilter defaultFilter;
//    LogSinkInterface *newGlobal = new GlishLogSink(defaultFilter, ptr);
//    LogSink::globalSink(newGlobal);
//    ...
//    LogIO io;
//    io << "Every good boy deserves fudge" << LogIO::POST; // goes to Glish!
//    ...
// </srcblock>
// </example>
//
// <motivation>
// Used by the tasking system to send log messages over the glish bus, where
// they are caught and displayed by the users glish session, and (also) sent
// to a client which saves them in a log table.
// </motivation>
//
// <todo asof="1998/10/30">
//   <li> Option to suppress posting messages to cerr when we are not attached
//        to a "live" glish bus?
//   <li> Move the <src>_memory</src> field to a more logical spot?
// </todo>

class GlishLogSink : public LogSinkInterface
{
public:
    // Construct the log sink with the supplied filter and
    // <linkto class=GlishSysEventSource>GlishSysEventSource</linkto>. If the
    // pointer to the event source is null, or if it becomes disconnected, log
    // messages will be posted to <src>cerr</src>.
    // <group>
    GlishLogSink(LogMessage::Priority filter, 
		 CountedPtr<GlishSysEventSource> eventSource);
    GlishLogSink(const LogFilterInterface &filter, 
		 CountedPtr<GlishSysEventSource> eventSource);
    // </group>

    // Reference semantics, i.e. after copying posted messages to either
    // <src>GlishLogSink</src> will be posted to the same Glish bus.
    // <group>
    GlishLogSink(const GlishLogSink &other);
    GlishLogSink &operator=(const GlishLogSink &other);
    // </group>
  
    // Post the message to the glish bus if we are connected to Glish,
    // otherwise post the message to cerr.
    virtual Bool postLocally(const LogMessage &message);

    // Returns the id for this class...
    static String localId( );
    // Returns the id of the LogSink in use...
    String id( ) const;

private:
    // Where the messages go
    CountedPtr<GlishSysEventSource> event_source_p;
    // Undefined and inaccessible
    GlishLogSink();
};


} //# NAMESPACE CASA - END

#endif


