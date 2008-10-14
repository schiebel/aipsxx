# logtable.g: make log messages persistent in a table
#
#   Copyright (C) 1996,1997,1999,2000
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: logtable.g,v 19.1 2004/08/25 01:34:11 cvsmgr Exp $
#
pragma include once

# This DO handles persistence of log messages to a table. It is not intended
# to be directly used by end users. Instead it is used by the logger class.

# Summary:
#
# log := logtable()   # attach to default, set by aipsrc variables.
#                     # Default is ~/aips++/aips++.log
# log.attach(logfile) # attach to new log table
#                     # add one or more messages to the table. Everything except
#                     # the messages may be defaulted
# log.addmessages(messages,time=[],priority="", location="", id="") 
#                     # Get the formatted versions of the log table with
#                     # entries that correspond to the logger gui. if num<0
#                     # get all the rows. If concat is True,
#                     # concatenate all the strings into one,
#                     # otherwise return String arrays
# log.getformatted(ref time='', ref priority='', ref messages='', ref location='',
#                  num=-1,expr='',concat=F)
#                     # Delete all but "keeplast" messages from the table.
#                     # If expr is given, delete all messages matching expr.
# log.purge(keeplast,expr='')
# log.nmessages()     # how many messages are in the log table
#                     # utility function to turn a time into a formatted date
#                     # string, type may be mjd, mjds, or unix. Much more is
#                     # available in the measures module.
# log.timestring(time,type)
# log.printtofile(num,filename,showcol,expr,ascommand)
#                     # print log messages to a file in /tmp and return the
#                     # filename. num<0 means all, >0 means the last "num".
#                     # Optionally it is written as commands by only writing
#                     # the message after removing leading '> ' from them.

include "servers.g";

#defaultservers.suspend(T)
#defaultservers.trace(T)

const logtable := function(host='', forcenewserver=F)
{
    public := [=];
    public::print.limit := 1;	;
    self := [=];

    self.agent := defaultservers.activate("misc", host, forcenewserver);
    self.id := defaultservers.create(self.agent, "logtable");

    self.attachRec := [_method = "attach", _sequence=self.id._sequence];
    public.attach := function(logfile)
    {
	wider self;
	self.attachRec.logfile := logfile;
        return defaultservers.run(self.agent, self.attachRec);
    }

    self.addmessagesRec := [_method="addmessages",
			    _sequence=self.id._sequence];
    public.addmessages := function(messages,time=[], priority="", location="",
				   id="")
    {
	wider self;
	self.addmessagesRec.messages := messages;
	self.addmessagesRec.time := time;
	self.addmessagesRec.priority := priority;
	self.addmessagesRec.location := location;
	self.addmessagesRec.id := id;
	return defaultservers.run(self.agent, self.addmessagesRec);
    }

    self.getformattedRec := [_method = "getformatted", 
			     _sequence=self.id._sequence];
    public.getformatted := function(ref time='', ref priority='', 
				    ref messages='', ref location='',
				    num=-1, expr='', concat=F)
    {
	wider self;
        self.getformattedRec.time := time;
        self.getformattedRec.priority := priority;
        self.getformattedRec.messages := messages;
        self.getformattedRec.location := location;
	self.getformattedRec.num := num;
	self.getformattedRec.expr := expr;
	self.getformattedRec.concat := concat;
	val result := defaultservers.run(self.agent, self.getformattedRec);
	val time := self.getformattedRec.time;
	val priority := self.getformattedRec.priority;
	val messages := self.getformattedRec.messages;
	val location := self.getformattedRec.location;
	return result;
    }

    self.purgeRec := [_method = "purge", _sequence=self.id._sequence];
    public.purge := function(keeplast, expr='')
    {
	wider self;
	self.purgeRec.keeplast := keeplast;
	self.purgeRec.expr := expr;
	return defaultservers.run(self.agent, self.purgeRec);
    }

    self.nmessagesRec := [_method = "nmessages", _sequence=self.id._sequence];
    public.nmessages := function()
    {
	wider self;
	return defaultservers.run(self.agent, self.nmessagesRec);
    }

    self.timestringRec := [_method = "timestring",
			   _sequence=self.id._sequence];
    public.timestring := function(time, type)
    {
	wider self;
	self.timestringRec.time := time;
	self.timestringRec.type := type;
	return defaultservers.run(self.agent, self.timestringRec);
    }

    self.printtofileRec := [_method = "printtofile", 
			    _sequence=self.id._sequence];
    public.printtofile := function(num, filename='', colwidth=[-1,-1,-1,-1],
				   expr='', ascommand=F)
    {
	wider self;
	self.printtofileRec.num := num;
	self.printtofileRec.filename := filename;
	self.printtofileRec.colwidth := colwidth;
	self.printtofileRec.expr := expr;
	self.printtofileRec.ascommand := ascommand;
	return defaultservers.run(self.agent, self.printtofileRec);
    }

    return public;
}
