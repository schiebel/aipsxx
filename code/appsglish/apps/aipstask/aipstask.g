#   Copyright (C) 1997,1998,1999
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
#   $Id: aipstask.g,v 19.1 2004/08/25 00:54:46 cvsmgr Exp $
#
# aipstask an interface to old style aips tasks

pragma include once

include "misc.g"
include "inputframe.g"       #Needed for creating the "GUI"

# Object aipstask -- provides a GUI for classic AIPS
#  All the start up parameters should be settable via aipsrc variables
#
# aips.id
# aips.printer
# aips.source
# aips.inputversion
# aips.system
# aips.data

# aipstask -- Constructor
# aipstask.task -- interface to an aips "task"
# aipstask.croak -- removes the client, only useful for debugging???
#

aipstask := function(aipsid, tv='none', printer='none', aipssrc='/AIPS/15APR97', taskname='none', inputversion='D', aipssystem='/wotan/AIPS', aipsdata='/wotan/AIPS')
{
   public := [=];
   self   := [=];
   self.client:=F;
   self.taskname := taskname;
   self.client::Died:=T;
   self.id := aipsid;
   self.inputVersion := inputversion;
   self.systemdir := spaste(aipssystem, '/DA00');  # Location of the aips
                                                   # system files
   self.datadir := spaste(aipsdata, '/DA01');      # Location of the TS file


     # Make the client

   const self.makeclient := function(clInit="aipstask") {
      this:=client(clInit);
      whenever this->fail          do 
      {
        this::Died      :=T;
      }
      whenever this->terminate          do 
      {
        this::Died      :=T;
      }
     return ref this;
   }
 
     # Start the aipstask client

   const self.startaips := function() {
      wider self;
      if(is_boolean(self.client)||self.client::Died) {
         self.client := self.makeclient();
      }
      return T;
   }

   #const public.croak := function()
   #{
   #   wider self;
   #   send self.client->terminate();
   #   self.client::Died := T;
   #   return;
   #}

   # Read the popsdat.hlp file and load in the pops variables

   self.readpopsdata := function(){
      wider self;
      popsfile := spaste(aipssrc, '/HELP/POPSDAT.HLP');
      semicolon := as_byte(';')
      buff := dms.readfile(popsfile);
      self.pops := [=];
      proc_defadv := F;
      for(i in 1:len(buff)){
         byte_buff := as_byte(buff[i]);
         buff_len := len(byte_buff);
         notcomment := T;

            #Set some input flags used to help parse the popsdat file

         if(byte_buff[1] == as_byte('C')  && byte_buff[2] == as_byte('-'))
            notcomment := F;
         if(byte_buff[1] == as_byte('*'))
            notcomment := F;
         if(len(byte_buff) >= 6 && as_string(byte_buff[1:6]) == 'FINISH' && proc_defadv)
            break;  # Nothing needed beyond this point

         if(len(byte_buff) >= 4 && as_string(byte_buff[1:4]) == 'QUIT')
            proc_defadv := T;  #Set a flag that we are defining pops adverbs

            # Parse the line

         if(byte_buff[1] != semicolon && notcomment){
            var := dms.strip_trailing_blanks(as_string(byte_buff[1:8]));
            if(proc_defadv){  # Here we parse the pop proc adverbs
               if(len(byte_buff) > 4){
                  if(var == 'SCALAR') {
                      procvars := split(as_string(byte_buff[11:len(byte_buff)]), ' ,');
                      for(adv in procvars){
                         self.pops[adv] := [=];
                         self.pops[adv].type := 'float';
                         self.pops[adv].array := F;
                      }
                  } else if(as_string(byte_buff[1:6]) == 'STRING') {
                      procvars := split(as_string(byte_buff[11:len(byte_buff)]), ' ,');
                      los := as_integer(as_string(byte_buff[8:10]));
                      for(adv in procvars){
                         self.pops[adv] := [=];
                         self.pops[adv].type := 'string';
                         self.pops[adv].array := F;
                         self.pops[adv].hint := los;
                      }
                  } else if(var == 'ARRAY') {
                      procvars := split(as_string(byte_buff[11:len(byte_buff)]), ' ,()');
                      j:=1;
                      while(j < len(procvars)){
                         adv := procvars[j];
                         self.pops[adv] := [=];
                         self.pops[adv].type := 'float';
                         self.pops[adv].array := as_integer(procvars[j+1]);
                         if((j+2) <= len(procvars) && as_integer(procvars[j+2]) > 0){
                            self.pops[adv].array :=
                                          as_integer([procvars[j+1], procvars[j+2]]);
                            j := j+1;
                         }
                         j := j+2;
                      }
                  }
               }
               next;  # We've setup the pop[var] stuff so grab the next line
            }

              #  Here we disect the line

            self.pops[var] := [=];
            self.pops[var].type := as_integer(as_string(byte_buff[16:18]));
            self.pops[var].array := F;
            if(self.pops[var].type == 1){
               if(buff_len > 30){
                  self.pops[var].type := 'float';
                  if(buff_len < 44){
                    self.pops[var].def  :=
                   dms.strip_trailing_blanks(as_string(byte_buff[30:buff_len]));
                  } else {
                    self.pops[var].def  :=
                      dms.strip_trailing_blanks(as_string(byte_buff[30:44]));
                  }
               }
            } else {
               if(buff_len > 23)
                  self.pops[var].ndim :=
                                 as_integer(as_string(byte_buff[20:23]));
               if(self.pops[var].type == 2){
                  self.pops[var].type := 'float';
                  if(self.pops[var].ndim == 1){
                     self.pops[var].array := as_integer(as_string(byte_buff[29:35]))
                  } else {
                     self.pops[var].array :=
                              [as_integer(as_string(byte_buff[29:35])),
                               as_integer(as_string(byte_buff[37:43]))];
                  }
               }
               if(self.pops[var].type == 7){
                  self.pops[var].hint := as_integer(as_string(byte_buff[29:35]))
                  self.pops[var].type := 'string';
                  if(self.pops[var].ndim > 1)
                     self.pops[var].array := as_integer(as_string(byte_buff[37:43]));
               }
            }
         }
      }
   }

     #  the business end of aips task, read the task help file, then construct
     #  a "GUI" for it.

   public.task := function(taskname){
      wider self;
      self.taskname := taskname;
      self.vars := self.readhelpfile(taskname);
      self.readtsfile();
      self.taskgui();
   }
      # Parse the aips task help file

   self.readhelpfile := function(taskname){
      wider self;
      vars := [=];
      helpfile := spaste(aipssrc, '/HELP/', taskname, '.HLP');
      buff := dms.readfile(helpfile);     # Read the file into memory

        # Lots of setup variables to set

      getvars := T;
      explain := F;
      vars.title := F;
      vars.data := [=];
      pass := 0;
      blanks := as_byte('        ');
      blank := as_byte(' ');
      semicolon := as_byte(';')
      questionmark := as_byte('?')
      hypen := as_byte('-')
      vars.explain := [=];
      vars.explain.Explain := F;
      aipsHelp := 'Aips Help';
      vars.explain[aipsHelp] := F;
      vars.helplines := 0;          # Number of extra help lines

         # OK do the parsing of the help line here

      for(i in 1:len(buff)){
         byte_buff := as_byte(buff[i]);
         if(byte_buff[1] != semicolon){
            if(byte_buff[1:8] !=  blanks && getvars && byte_buff[10] != questionmark){
               if(pass == 1)
                  vars.title := buff[i];
               pass := pass + 1;
               if(byte_buff[1] == hypen){
                  getvars := F;
               }
                  # Assign all the various info bits from the help file

               if(getvars && pass > 2){
                  varname :=
                      dms.strip_trailing_blanks(as_string(byte_buff[1:8]));
                  vars.data[varname].label := varname;
                  vars.data[varname].type := 'string';
                  if(has_field(self.pops, varname)){
                     if(has_field(self.pops[varname], 'hint'))
                        vars.data[varname].hint := self.pops[varname].hint;
                     if(has_field(self.pops[varname], 'type'))
                        vars.data[varname].type := self.pops[varname].type;
                     if(has_field(self.pops[varname], 'array')){
                        vars.data[varname].array := self.pops[varname].array;
                     }
                     if(has_field(self.pops[varname], 'def'))
                        vars.data[varname].default := self.pops[varname].def;
                  } else {
                     print 'POPSDAT.HLP missing ', varname;
                  }
                  if(any(byte_buff[11:22] != blank)){
                     if(!has_field(vars.data[varname], 'range'))
                        vars.data[varname].range := [=];
                     vars.data[varname].range.min := as_float(as_string(byte_buff[11:22]));
                  }
                  if(any(byte_buff[23:34] != blank)){
                     if(!has_field(vars.data[varname], 'range'))
                        vars.data[varname].range := [=];
                     vars.data[varname].range.max := as_float(as_string(byte_buff[23:34]));
                  }
                  if(len(byte_buff) > 35){
                     vars.data[varname].help := [=];
                     vars.data[varname].help.text :=
                          as_string(byte_buff[36:len(byte_buff)]);
                  }
               }
            } else {
                if(getvars && len(byte_buff) > 35 && byte_buff[10] != questionmark){
                   vars.data[varname].help.text :=
                     paste(vars.data[varname].help.text,
                           as_string(byte_buff[36:len(byte_buff)]), sep='\n');
                   vars.helplines := vars.helplines + 1;
                } else if(!getvars){
                  if(byte_buff == hypen){
                      aipsHelp := 'Explain';
                      print 'Help read';
                  }
                  if(is_boolean(vars.explain[aipsHelp])){
                      vars.explain[aipsHelp] := [=];
                      vars.explain[aipsHelp].help := [=];
                      vars.explain[aipsHelp].help.text := buff[i];
                      if(aipsHelp == 'Explain'){
                         for(j in i+1:len(buff)){
                            vars.explain[aipsHelp].help.text :=
                                   paste(vars.explain[aipsHelp].help.text,
                                         buff[j], sep='\n');
                         }
                         break;
                      }
                   } else {
                      vars.explain[aipsHelp].help.text :=
                                   paste(vars.explain[aipsHelp].help.text,
                                         buff[i], sep='\n');
                   }
                }
            }
            
         }
      }
      return ref vars;
   }

      # Here we read the AIPS TS file to get the last values used to run the
      # task.

   self.readtsfile := function(){
      wider self;
      args.file := self.tsfile;
      args.datamembers := self.vars.data;
      args.datanorder := field_names(self.vars.data);  #AIPS is order dependent
      args.task := self.taskname;                      #the aips++ client isn't
      if(is_fail(self.startaips())) fail;
      self.client->read_ts_file(args);
      await self.client->read_ts_file_result;
      self.data := $value;
      return;
   }

      # Having scaned the GUI we update the data in the AIPS TS file

   self.sendpops := function(data){
      wider self;
      args.task := self.taskname;
      args.datamembers := self.vars.data;
      args.data := [=];
      for(argdata in field_names(data)){
         args.data[argdata] := data[argdata];
         args.data[argdata]:: := [=];
      }
      args.datanorder := field_names(self.vars.data);
      args.task := self.taskname;
      if(is_fail(self.startaips())) fail;
      self.client->send_pops(args);
      await self.client->send_pops_result;
      return $value;
   }
      # here we create a "GUI" for the aips task.

   self.taskgui := function(){
      wider self;
         # go callback handles what we do when we press GO!	

      self.vars.actions.go := [=];
      self.vars.actions.go.label := 'Go';

         # interface with aips goes here

      self.vars.actions.go.function := function(data){wider self;
                                                      self.sendpops(data);}

         # Create the windows here

      fgf := gui.inputform(self.vars, title=self.vars::title, helpdisplay=T, someid=self.taskname)

         # Set the values to the last ones used.
      fgf.setinput(self.data);
      return
   }

      # convert the aipsid into an exented hex number base 36
   if(is_fail(self.startaips())) fail;
   self.client->get_ehex_id(self.id);
   await self.client->get_ehex_id_result;
   self.ehexid := $value;

     # Done twice cause fileexists can't handle the ; !!!!

   self.tsfile := spaste(self.datadir, '/TS', self.inputVersion, self.ehexid,'000.', self.ehexid, ';');
   tsfile := spaste(self.datadir, '/TS', self.inputVersion, self.ehexid,'000.', self.ehexid, '\\;');
   if(!dms.fileexists(tsfile)) fail;  # This maynot make sense.

      # Read the pops data from POPSDAT.HLP
   self.readpopsdata();

      # Keep me in scope
   return ref public;
}
