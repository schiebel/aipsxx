# registration.g: Process AIPS++ registrations
#
# Copyright (C) 1999
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
# $Id: register.g,v 19.0 2003/07/16 04:40:14 aips2adm Exp $

# include guard
pragma include once
 
include 'os.g'
include 'table.g'

doRegistration := function(filename){
  priv := [=];
  priv.init := function(){
     wider priv;
     priv.register := F;
     priv.originator := F;
     priv.organization := F;
     priv.site := F;
     priv.email := F;
     priv.release := F;
     priv.os := F;
     priv.userComments := F;
     priv.moreComments := F;
     priv.registrationDB := '/export/aips++/etc/registrationDB';
  }

  priv.hasAllData := function(){
    wider priv;
    rStat := T;
    for(what in "register originator organization email release os userComments site"){
       if(priv[what] == F){
          rStat := F;
          break;
       }
    }
       # Not done reading user comments
    if(priv.moreComments)
       rStat := F;
    return rStat;
  }

  priv.createDB := function(registrationDB){
    if(tableexists(registrationDB))fail;
    col1 := tablecreatescalarcoldesc('Organization', ' ');
    col2 := tablecreatescalarcoldesc('Site', ' ');
    col3 := tablecreatescalarcoldesc('Contact', ' ');
    col4 := tablecreatescalarcoldesc('Email', ' ');
    col5 := tablecreatescalarcoldesc('Release', ' ');
    col6 := tablecreatescalarcoldesc('OS', ' ');
    col7 := tablecreatescalarcoldesc('Comments-User', ' ');
    col8 := tablecreatescalarcoldesc('Comments-AIPS++', ' ');
    td := tablecreatedesc(col1, col2, col3, col4, col5, col6, col7, col8);
    return table(registrationDB, td);
  }

  priv.updateRegistrationDB := function() {
    wider priv;
    rr := [=];
    rr.Organization := priv.organization;
    rr.Site := priv.site;
    rr.Contact := priv.originator;
    rr.Email := priv.email;
    rr.Release := priv.release;
    rr.OS := priv.os;
    rr['Comments-User'] := priv.userComments;
    if(!tableexists(priv.registrationDB)){
       priv.dbTable := priv.createDB(priv.registrationDB);
    } else {
       priv.dbTable := table(priv.registrationDB, readonly=F);
    }
    if(is_table(priv.dbTable)){
       rRow := tablerow(priv.dbTable);
       priv.dbTable.addrows(1);
       rRow.put(priv.dbTable.nrows(), rr);
    } else {
       dos.mail('Bad registration', 'wyoung@aoc.nrao.edu');
    }
  }

  priv.init();
  fp := open(paste('<', filename));
  if (is_fail(fp)){
            note (paste('Failed to open file:', filename), 'ERROR');
            fail;
  } else {
    while(line := read(fp)){
      line := line ~ s/\n//;   # Strip out all the newlines
      line := line ~ s/ *$//;  # Now remove all the trailing blanks
                               # Note the ' *' removes all the preceding blanks
      if(line ~ m/^.Category: Registration/){
                priv.register := T
      }
      if(line ~ m/^.Originator:/){
                priv.originator := line ~ s/^.Originator: *//;
      }
      if(line ~ m/^.Organization:/){
                priv.organization := line ~ s/^.Organization: *//;
      }
      if(line ~ m/^.Reply-to:/){
                priv.email := line ~ s/^.Reply-to: *//;
      }
      if(line ~ m/^.Release:/){
                priv.release := line ~ s/^.Release: *//;
      }
      if(line ~ m/^.Group:/){
                priv.site := line ~ s/^.Group: *//;
      }
      if(line ~ m/^.Environment:/){
                priv.os := line ~ s/^.Environment: *//;
      }
      if(line ~ m/^glish system:/){
                priv.moreComments := F;
      }
      if(priv.moreComments){
         priv.userComments := spaste(priv.userComments, line, '\n');
      }
      if(line ~ m/^.Description:/){
                priv.moreComments := T;
                priv.userComments := '';
      }
      if(priv.hasAllData()){
         priv.updateRegistrationDB();
         priv.init();
      }
    }
  }
}

doRegistration('/export/aips++/tmp/A2registration');
exit;

