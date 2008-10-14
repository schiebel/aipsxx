//# vlafiller.cc:  converts data from VLA Archive format to AIPS++
//# Copyright (C) 1996,1997,1998,1999,2000,2001
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
//# $Id: vla2table.cc,v 19.3 2004/11/30 17:50:40 ddebonis Exp $

#include <casa/aips.h>
#include <casa/Exceptions/Error.h>
#include <casa/Inputs/Input.h>
#include <casa/OS/File.h>
#include <casa/BasicSL/String.h>
#include <nrao/VLA/VlaAsciiSink.h>
#include <nrao/VLA/VlaFileSource.h>
#include <nrao/VLA/VlaNRealSource.h>
#include <nrao/VLA/VlaSink.h>
#include <nrao/VLA/VlaSource.h>
#include <nrao/VLA/VlaTableSink.h>
#include <nrao/VLA/VlaTapeSource.h>
#include <casa/iostream.h>
#include <signal.h>

#include <casa/namespace.h>
// First the signal handler so we can clean things ups after some one 
// ctrl-c's the process.

Bool cleanupSignaled = False;

void cleanup(Int sig)
{
   cerr << "Received signal " << sig << endl;
   cleanupSignaled = True;
   return;
}

int main(int argc, char **argv)
{
   Input cmdLine;
   cmdLine.create("tape", "False");
   cmdLine.create("file", "False");
   cmdLine.create("online", "True");
   cmdLine.create("dump", "vlaout.txt");
   cmdLine.create("table", "False");
   cmdLine.readArguments(argc, argv);
   VlaSource *vla(0);
   VlaSink   *dest(0);
   if(cmdLine.getBool("tape")){
      vla = new VlaTapeSource(cmdLine.getString("tape"));
   } else if(cmdLine.getBool("file")){
      vla = new VlaFileSource(cmdLine.getString("file"));
   } else {
      vla = new VlaNRealSource("online");
   }
   String dumpFile(cmdLine.getString("dump"));
   if(cmdLine.getBool("table")){
      String tableName(cmdLine.getString("table"));
      dest = new VlaTableSink(dumpFile, tableName);
   } else {
      if(File(dumpFile).exists()){
        dest = new VlaAsciiSink(dumpFile);
      }else{
        cerr << "Dump file not found: " << dumpFile << endl;
        dest = new VlaAsciiSink();
      }
   }
   Char *buffer = new Char[850000];

   signal(SIGINT, cleanup);
   signal(SIGHUP, cleanup);
   signal(SIGILL, cleanup);
   signal(SIGBUS, cleanup);
   signal(SIGQUIT, cleanup);
   signal(SIGABRT, cleanup);
   signal(SIGUSR1, cleanup);
   signal(SIGTSTP, cleanup);
   signal(SIGSEGV, cleanup);

   try {
   while(!cleanupSignaled && vla->next(buffer) > 0){
        Int myStat(dest->write(buffer));
           cerr << myStat << endl;
           if(myStat == -1)
              break;
   }
   } catch(AipsError ae){
        cerr << ae.getMesg() << endl;
   } 
   cerr << "Cleaning up" << endl;
   delete dest;
   delete [] buffer;
   delete vla;
   return 0;
}
// Local Variables: 
// compile-command: "gmake OPTLIB=1 vlafiller"
// End: 
