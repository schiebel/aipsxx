# scripter.g: Scripter tool for logging commands to a file
# Copyright (C) 1998,1999,2000
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: scripter.g,v 19.2 2004/08/25 02:04:03 cvsmgr Exp $

pragma include once

include "note.g";
include "widgetserver.g";

   #scripter is a tool for logging commands to a record or more commonly to a 
   # file.  There are options  to specify the log-file name and whether to
   # run the command or just "log" it for running at a later time.
   #
scripter := function(logfile=F, run=F, guititle='Scripter gui (AIPS++)',
		     widgetset=dws){
   public := [=];
   private := [=];

   private.widgetset := widgetset;

   private.count := 0;          # Command count in buffer
   private.commands := [=];      # record of commands
   private.run := run;          # flag to indicate whether to run the command
   private.sg := F;

      # Initialize the logfile

   private.initlogfile := function(logfile){
      wider private;
      if(is_boolean(logfile)){
         private.logfile := spaste('scripter.log_', system.pid);
      } else if(is_string(logfile)) {
         private.logfile := logfile;
      } else {
         fail('Unable to specify logfile');
      }
   }

   
      # Log the command to a record

   public.log := function(command, run=F, guilog=T){
      wider private;
      if(!is_string(command)){
         fail('scripter.log: command must be a string or an array of strings');
      }
      for(i in 1:len(command)){
         private.count +:= 1;
         private.commands[as_string(private.count)] := command[i];
         if(is_agent(private.sg) && guilog){
            private.sg.addcommand(command[i]);
         }
         if(run){
            eval(command[i]);
         }
      }
   }

   public.run := function(rows) {
     for(i in rows) {
       print private.commands[as_string(i)], ":", eval(private.commands[as_string(i)]);
     }
   }

   public.getlogfile := function() {
     wider private;
     return private.logfile;
   }

   public.save := function(filename=F){
      wider private;
      if(is_boolean(filename))
         filename := private.logfile;
      if(!is_string(filename)){
         fail('scripter.save: file name must be a string');
      }  
      f := open(paste(">", filename));
      if(!is_fail(f)){
         for(i in 1:len(private.commands)){
            fprintf(f, '%s\n', private.commands[as_string(i)]);
         }
      } else {
         fail(paste('scripter.save: can\'t save to file', filename));
      }
      private.logfile := filename;
   }

   public.getcommands := function(){wider private;
                                    return private.commands;}

   public.reset := function(){wider private;
                              private.count := 0;
                              private.commands := [=];}

   public.load := function(filename, append=F, run=F){
      wider public;
      wider private;
      if(!is_string(filename)){
         fail('scripter.load: filename must be a string');
      }  
      if(!is_boolean(append)){
         fail('scripter.load: append must be a boolean');
      }  
      if(!append){
         public.reset();
      }
      f := open(paste("<", filename));
      if(!is_fail(f)){
         while(line := read(f)){
            public.log(line, run);
         }
      } else {
         fail(paste('scripter.load: can\'t read file', filename));
      }
   }

   public.type := function() {return 'scripter';}

   public.show := function(){
     wider public;
     wider private;
     if(have_gui()) {
       include 'scriptergui.g';
       if(!is_agent(private.sg)){
          private.sg := scriptergui(public, title=guititle,
				    widgetset=private.widgetset);
          private.sg.commands(private.commands);
       } else {
          private.sg.map();
       }
     }
     else {
       for(i in 1:len(private.commands)){
	 print private.commands[as_string(i)];
       }
     }
   }

   private.initlogfile(logfile);

   public.gui := public.show;

   public.done := function() {
     wider private, public;

     if(have_gui()) {
       if(has_field(private, 'sg')&&is_agent(private.sg)) {
         private.sg.done();
       }
     }
     private := F;
     public := F;
     return T;
   }

   return ref public;
}

const defaultscripter := scripter('aips++.script.g');
const ds := ref defaultscripter;

note('defaultscripter (ds) ready', priority='NORMAL', origin='scripter');
