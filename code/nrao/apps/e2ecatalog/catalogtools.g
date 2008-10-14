# catalogtools: Define a set of tools to manage archive catalog tables
#
#   Copyright (C) 1995,1996,1997,1998,1999,2000,2001,2002
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
#   $Id: catalogtools.g,v 19.0 2003/07/16 03:44:39 aips2adm Exp $
#
#----------------------------------------------------------------------------

pragma include once;

#
include 'mscatalogtables.g';
include 'e2equery.g';
include 'e2efuncs.g';
include 'vectime2str.g';
# 
cataloghelp := function()
{
      print "----------------------------------------------------------------------------------";
   print " ";
   print "deleteproject(project_code='none',catalogname='MSCATALOG',deleterows=F)";
   print " ";
   print "....deletes all rows in all catalog tables associated with a specified project";
   print " ";
   print " ";
   print "deletetimerange(startdate='1-jan-1990',stopdate='1-jan-2000',catalogname='MSCATALOG',deleterows=F)";
   print " ";
   print "....deletes all rows in all catalog tables for all projects within a specified time range";
   print " ";
   print "redundantrows(project_code='none',tablename='datadesc',catalogname='MSCATALOG')";
   print " ";
   print "....returns a count of redundant rows in a specified table for a project";
   print " ";
   print "countprojectrows(project_code='all',catalogname='MSCATALOG')";
   print " ";
   print "....returns row count for observation, datadesc and archive tables";
   print " ";
   print "listprojectrows(project_code='all',catalogname='MSCATALOG')";
   print " ";
   print "....writes file e2edb_query.html listing each observation row";
   print " ";
   print "projectsummary(project_code='none',catalogtable='MSCATALOG')";
   print " ";
   print "....writes file e2edb_project_summary.html, simple project summary";
   print " ";
   print "listarchivefiles(startdate='1-jan-1990',stopdate='1-jan-2000',catalogname='MSCATALOG')";
   print " ";
   print "....writes file e2edb_archives.html listing all archive files in catalog";
   print " ";
   print "listprojects(startdate='1-jan-1990',stopdate='1-jan-2000',obs_bands='all',config='all',catalogname='MSCATALOG')";
   print " ";
   print "....writes file e2edb_projects.html listing all projects in catalog";
   print " ";
   print "fixprojecttable(project_code='all',catalogname='MSCATALOG')";
   print " ";
   print "....apply fixes to the project table, I modify this to suit my purposes when needed";
   print " ";
   print "fiximagetable(project_code='all',catalogname='IMCATALOG')";
   print " ";
   print "....apply fixes to the image table, I modify this to suit my purposes when needed";
   print " ";
      print "----------------------------------------------------------------------------------";

}
deleteproject := function(project_code='none', catalogname='MSCATALOG',deleterows=F) {

#
# Include all the good stuff
#  
  include 'table.g';
  include 'quanta.g';
  include 'measures.g';
#
#
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  private.obsname  := spaste(catalogname,'/OBSERVATION');
  private.archname := spaste(catalogname,'/ARCHIVE');
  private.descname := spaste(catalogname,'/DATADESC');
  private.antsname := spaste(catalogname,'/ANTENNA');
#
  if(!tableexists(private.obsname)) {
    return throw(paste('table ', private.obsname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.archname)) {
    return throw(paste('table ', private.archname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.descname)) {
    return throw(paste('table ', private.descname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.antsname)) {
    return throw(paste('table ', private.antsname, 'does not exist'),
		 origin='catalogtools.g');
  }
#
# Open the tables 
#
  tblobs  := table(tablename=private.obsname, readonly=F); 
  tblarch := table(tablename=private.archname, readonly=F); 
  tbldesc := table(tablename=private.descname, readonly=F); 
  tblants := table(tablename=private.antsname, readonly=F); 
#
# Get a sub-table that contains the queried rows from the observation table
#
  obs_command := paste("PROJECT_CODE == '");
  obs_command := spaste(obs_command,project_code,"'");
#  print "obs_command = ", obs_command;
#
#  print "shape tblobs   = ", shape(tblobs);
  tblobs_q := tblobs.query(obs_command);
  nobs := 0;
  if (shape(tblobs_q) > 0) {
     nobs := tblobs_q.nrows();
  }
  print "selected rows to delete -  observation table : ", nobs;  
#
  all_desc_ids := tblobs_q.getcol('DATA_DESC_ID');
  desc_ids := unique(all_desc_ids);
  n_descrows := len(desc_ids);
#  print "desc_id = ", desc_ids;
  desc_command := paste("DATA_DESC_ID in [");
  desc_command := paste(desc_command,desc_ids[1]);
  if (n_descrows > 1) {
     for (j in [2:n_descrows]) {
         desc_command := spaste(desc_command,",",desc_ids[j]);
     }
  }
  desc_command := spaste(desc_command,"]");
#  print "desc_command = ", desc_command;
  tbldesc_q := tbldesc.query(desc_command);
  ndesc := 0;
  if (shape(tbldesc_q) > 0) {
     ndesc := tbldesc_q.nrows();
  }
  print "selected rows to delete - datadesc table : ", ndesc;  
#
  all_arch_ids := tblobs_q.getcol('ARCH_FILE_ID');
  arch_ids := unique(all_arch_ids);
#  print "arch_ids = ", arch_ids,".";
  arch_command := paste("ARCH_FILE_ID in [");
  n_archrows := len(arch_ids);
  arch_command := paste(arch_command,arch_ids[1]);
  if (n_archrows > 1) {
     for (j in [2:n_archrows]) {
         arch_command := spaste(arch_command,",",arch_ids[j]);
     }
  }
  arch_command := spaste(arch_command,"]");
#  print "arch_command = ", arch_command;
  tblarch_q := tblarch.query(arch_command);
  narch := 0;
  if (shape(tblarch_q) > 0) {
     narch := tblarch_q.nrows();
  }
  print "selected rows to delete - archive table : ", narch;  
#
  if (deleterows && (nobs > 0 || narch > 0 || ndesc > 0)) {
     if (nobs > 0) {
        if (tblobs.removerows(tblobs_q.rownumbers()))
           print "successfully removed ",nobs," observation table rows";
     }
     if (ndesc > 0) {
        if (tbldesc.removerows(tbldesc_q.rownumbers()))
           print "successfully removed ",ndesc," datadesc table rows";
     }
     if (narch > 0) {     
        if (tblarch.removerows(tblarch_q.rownumbers()))
           print "successfully removed ",narch," archive table rows";
      }
  }
  if (!deleterows) print "*** no rows have been deleted, function arg deleterows = F";
}
#----------------------------------------------------------------------------
#
compresstable := function(tablename='none', catalogname='MSCATALOG',deleterows=F) {

#
# Include all the good stuff
#  
  include 'table.g';
#
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  if (tablename == 'PROJECT') {
     private.tablename := spaste(catalogname);
  }
  else {
     private.tablename := spaste(catalogname,'/',tablename);
  }
#
  if(!tableexists(private.tablename)) {
    return throw(paste('table ', private.tablename, 'does not exist'),
		 origin='catalogtools.g');
  }
#
# Open the table 
#
  tbl := table(tablename=private.tablename, readonly=F); 
  proj_command := paste("PROJECT_CODE == ''");
  tbl_q := tbl.query(proj_command);
  nblanks := 0;
  if (shape(tbl_q) > 0) {
     nblanks := tbl_q.nrows();
  }
  print "blank rows to delete = ", nblanks;
  if (deleterows && nblanks > 0) {
     if (tbl.removerows(tbl_q.rownumbers()))
         print "successfully removed ",nblanks,private.tablename," table rows";
      }
  nrows := tbl.nrows();
  tbl.putkeyword("nrows", as_integer(nrows));
  tbl.putkeyword("last_row", as_integer(nrows));
}
#----------------------------------------------------------------------------
#
deletetimerange := function(startdate='1-jan-1990',stopdate='1-jan-2000', catalogname='MSCATALOG',deleterows=F) {

#
# Include all the good stuff
#  
  include 'table.g';
  include 'quanta.g';
  include 'measures.g';
#
#
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  private.projname := spaste(catalogname);
  private.obsname  := spaste(catalogname,'/OBSERVATION');
  private.archname := spaste(catalogname,'/ARCHIVE');
  private.descname := spaste(catalogname,'/DATADESC');
  private.antsname := spaste(catalogname,'/ANTENNA');
#
  if(!tableexists(private.projname)) {
    return throw(paste('table ', private.projname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.obsname)) {
    return throw(paste('table ', private.obsname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.archname)) {
    return throw(paste('table ', private.archname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.descname)) {
    return throw(paste('table ', private.descname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.antsname)) {
    return throw(paste('table ', private.antsname, 'does not exist'),
		 origin='catalogtools.g');
  }
#
# Open the tables 
#
  start_mjd := dq.quantity(startdate,'d');
  stop_mjd  := dq.quantity(stopdate,'d');
#
  tblproj := table(tablename=private.projname, readonly=F); 
  tblobs  := table(tablename=private.obsname, readonly=F); 
  tblarch := table(tablename=private.archname, readonly=F); 
  tbldesc := table(tablename=private.descname, readonly=F); 
  tblants := table(tablename=private.antsname, readonly=F); 
#
# Get a sub-table that contains the queried rows from the observation table
#
  obs_command := paste("STARTTIME >= ",start_mjd.value," and STARTTIME <= ",
                        stop_mjd.value," or STOPTIME >= ",start_mjd.value, 
                        " and ", "STOPTIME <= ", stop_mjd.value);
#  print "obs_command = ", obs_command;
#
#  print "shape tblobs   = ", shape(tblobs);
  tblobs_q := tblobs.query(obs_command);
  nobs := 0;
  if (shape(tblobs_q) > 0) {
     nobs := tblobs_q.nrows();
  }
  print "selected rows to delete -  observation table : ", nobs;  
#
  proj_command := paste("FIRSTTIME >= ",start_mjd.value," and FIRSTTIME <= ",
                        stop_mjd.value," or LASTTIME >= ",start_mjd.value, 
                        " and ", "LASTTIME <= ", stop_mjd.value);
#  print "proj_command = ", proj_command;
  tblproj_q := tblproj.query(proj_command);
  nproj := 0;
  if (shape(tblproj_q) > 0) {
     nproj := tblproj_q.nrows();
  }
  print "selected rows to delete - project table : ", nproj;  
#
  all_desc_ids := tblobs_q.getcol('DATA_DESC_ID');
  desc_ids := unique(all_desc_ids);
  n_descrows := len(desc_ids);
#  print "desc_id = ", desc_ids;
  desc_command := paste("DATA_DESC_ID in [");
  desc_command := paste(desc_command,desc_ids[1]);
  if (n_descrows > 1) {
     for (j in [2:n_descrows]) {
         desc_command := spaste(desc_command,",",desc_ids[j]);
     }
  }
  desc_command := spaste(desc_command,"]");
#  print "desc_command = ", desc_command;
  tbldesc_q := tbldesc.query(desc_command);
  ndesc := 0;
  if (shape(tbldesc_q) > 0) {
     ndesc := tbldesc_q.nrows();
  }
  print "selected rows to delete - datadesc table : ", ndesc;  
#
  all_arch_ids := tblobs_q.getcol('ARCH_FILE_ID');
  arch_ids := unique(all_arch_ids);
#  print "arch_ids = ", arch_ids,".";
  arch_command := paste("ARCH_FILE_ID in [");
  n_archrows := len(arch_ids);
  arch_command := paste(arch_command,arch_ids[1]);
  if (n_archrows > 1) {
     for (j in [2:n_archrows]) {
         arch_command := spaste(arch_command,",",arch_ids[j]);
     }
  }
  arch_command := spaste(arch_command,"]");
#  print "arch_command = ", arch_command;
  tblarch_q := tblarch.query(arch_command);
  narch := 0;
  if (shape(tblarch_q) > 0) {
     narch := tblarch_q.nrows();
  }
  print "selected rows to delete - archive table : ", narch;  
#
  if (deleterows && (nobs > 0 || narch > 0 || ndesc > 0 || nproj > 0)) {
     if (nproj > 0) {
        if (tblproj.removerows(tblproj_q.rownumbers()))
           print "successfully removed ",nproj," project table rows";
     }
     if (nobs > 0) {
        if (tblobs.removerows(tblobs_q.rownumbers()))
           print "successfully removed ",nobs," observation table rows";
     }
     if (ndesc > 0) {
        if (tbldesc.removerows(tbldesc_q.rownumbers()))
           print "successfully removed ",ndesc," datadesc table rows";
     }
     if (narch > 0) {     
        if (tblarch.removerows(tblarch_q.rownumbers()))
           print "successfully removed ",narch," archive table rows";
      }
  }
  if (!deleterows) print "*** no rows have been deleted, function arg deleterows = F";
}
#
#----------------------------------------------------------------------------
#
redundantrows := function(project_code='none', tablename='DATADESC', catalogname='MSCATALOG') {
#
# Include all the good stuff
#  
  include 'table.g';
#
#
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  private.tablename  := spaste(catalogname,'/',tablename);
#
  if(!tableexists(private.tablename)) {
    return throw(paste('table ', private.tablename, 'does not exist'),
		 origin='catalogtools.g');
  }
#
# Open the tables
#
  tbl  := table(tablename=private.tablename, readonly=T);
# 
  tbl_command := spaste("PROJECT_CODE == '",project_code,"'");
#
  tbl_q := tbl.query(tbl_command);
  ndesc := tbl_q.nrows();
  print "nrows for project ",project_code," : ", ndesc;
#
  chan_id   := tbl_q.getcol('SUB_CHAN_ID');
  ref_freq  := tbl_q.getcol('SUB_REF_FREQ');
  bandw     := tbl_q.getcol('SUB_BANDW');
  net_sb    := tbl_q.getcol('SUB_NET_SIDEBAND');
  n_chans   := tbl_q.getcol('SUB_NUM_CHANS');
#
  nredundant := 0;
  for (i in [1:ndesc-1]) {
      k := i + 1;     
      for (j in [k:ndesc]) {
          if (chan_id[i] != chan_id[j]) {
              continue;
          }
          if (ref_freq[i] == ref_freq[j] &&
              bandw[i]    == bandw[j] &&
              net_sb[i]   == net_sb[j] &&
              n_chans[i]  == n_chans[j]) {
              nredundant := nredundant + 1;
          }
      }
  }

  print "redundant rows found : ", nredundant;
}
#
#----------------------------------------------------------------------------
#
countprojectrows := function(project_code='all', catalogname='MSCATALOG') {
#
# Include all the good stuff
#  
  include 'table.g';
#
#
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  private.obsname  := spaste(catalogname,'/OBSERVATION');
  private.archname := spaste(catalogname,'/ARCHIVE');
  private.descname := spaste(catalogname,'/DATADESC');
  private.antsname := spaste(catalogname,'/ANTENNA');
#
  if(!tableexists(private.obsname)) {
    return throw(paste('table ', private.obsname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.archname)) {
    return throw(paste('table ', private.archname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.descname)) {
    return throw(paste('table ', private.descname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.antsname)) {
    return throw(paste('table ', private.antsname, 'does not exist'),
		 origin='catalogtools.g')
  }
#
# Open the tables 
#
  tblobs  := table(tablename=private.obsname, readonly=T); 
  tblarch := table(tablename=private.archname, readonly=T); 
  tbldesc := table(tablename=private.descname, readonly=T); 
  tblants := table(tablename=private.antsname, readonly=T); 
#
# get a vector of all unique project codes in the archive table.
#
  if (project_code == "all") {
     projects := unique(tblarch.getcol('PROJECT_CODE'));
     nprojs := length(projects);
  }
  else {
    projects[1] := spaste(project_code);
    nprojs      := 1;
  }
  for (i in [1:nprojs]) {
      nobs := 0;
      narch := 0;
      ndesc := 0;
      nsub := 0;
      tbl_command := spaste("PROJECT_CODE == '",projects[i],"'");
#     print "tbl_command : ", tbl_command;
#
      tblobs_q  := tblobs.query(tbl_command);
      nobs      := tblobs_q.nrows();
      tbldesc_q := tbldesc.query(tbl_command);
      ndesc     := tbldesc_q.nrows();
      tblarch_q := tblarch.query(tbl_command);
      narch     := tblarch_q.nrows();

      proj_str := paste(projects[i]);
      print sprintf("project : %-8s  arch, obs, datadesc : %5d %5d %5d \n",
                     proj_str, narch, nobs, ndesc);
     
  }
  tblobs.done();
  tblarch.done();
  tbldesc.done();

}
#
#----------------------------------------------------------------------------
#
listprojectrows := function(project_code='all', catalogname='MSCATALOG') {
#
# Include all the good stuff
#  
  include 'table.g';
#
#
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  private.obsname  := spaste(catalogname,'/OBSERVATION');
  private.archname := spaste(catalogname,'/ARCHIVE');
  private.descname := spaste(catalogname,'/DATADESC');
  private.antsname := spaste(catalogname,'/ANTENNA');
#
  if(!tableexists(private.obsname)) {
    return throw(paste('table ', private.obsname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.archname)) {
    return throw(paste('table ', private.archname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.descname)) {
    return throw(paste('table ', private.descname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.antsname)) {
    return throw(paste('table ', private.antsname, 'does not exist'),
		 origin='catalogtools.g');
  }
#
  obs_query := spaste("PROJECT_CODE == pattern('",paste(project_code),"')");
#
  e2equerytables(obstbl_query=obs_query,catalogname=catalogname);
}
#
#----------------------------------------------------------------------------
#
projectsummary := function(project_code='none', catalogname='MSCATALOG') {
#
# Include all the good stuff
#  
  include 'table.g';
#
#
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  func nlpaste(...) paste(...,sep='\n');
#
  private.projname := spaste(catalogname);
  private.obsname  := spaste(catalogname,'/OBSERVATION');
  private.archname := spaste(catalogname,'/ARCHIVE');
  private.descname := spaste(catalogname,'/DATADESC');
  private.antsname := spaste(catalogname,'/ANTENNA');
#
  if(!tableexists(private.projname)) {
    return throw(paste('table ', private.projname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.obsname)) {
    return throw(paste('table ', private.obsname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.archname)) {
    return throw(paste('table ', private.archname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.descname)) {
    return throw(paste('table ', private.descname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.antsname)) {
    return throw(paste('table ', private.antsname, 'does not exist'),
		 origin='catalogtools.g');
  }
#
# Open the tables 
#
  tblproj := table(tablename=private.projname, readonly=T); 
  tblobs  := table(tablename=private.obsname,  readonly=T); 
  tblarch := table(tablename=private.archname, readonly=T); 
  tbldesc := table(tablename=private.descname, readonly=T); 
  tblants := table(tablename=private.antsname, readonly=T); 
#
# get a vector of all unique project codes in the archive table.
#
  if (project_code == "none") {
     print "ERROR: a project_code was not specified in the function args";
     return F;
  }
  projects := spaste(project_code);
  nprojs   := 1;
#
# write out the html header stuff, etc.
#
  html := paste("");
#
  html := nlpaste(html,sprintf("<HEAD>"));
  html := nlpaste(html,sprintf("<TITLE>E2E ARCHIVE DB PROJECT SUMMARY</TITLE></HEAD>"));
  html := nlpaste(html,sprintf("<BODY BGCOLOR=#ffffff TEXT=#000000 LINK=#00009c VLINK=#cc0f0f>"));
  html := nlpaste(html,sprintf("<CENTER><H1>NRAO Data Archive - Project Summary -(%s)</H1></CENTER><p>",projects));
  html := nlpaste(html,sprintf("<pre><b>Archive Catalog : %s </b></pre>",catalogname));
      nobs := 0;
      narch := 0;
      ndesc := 0;
      nsub := 0;
      nsrcs := 0;

      tbl_command := spaste("PROJECT_CODE == '",projects,"'");
#
      tblproj_q := tblproj.query(tbl_command);
      proj_rows := tblproj_q.rownumbers();
      nproj     := tblproj_q.nrows();
      tblobs_q  := tblobs.query(tbl_command);
      obs_rows  := tblobs_q.rownumbers();
      nobs      := tblobs_q.nrows();
      tbldesc_q := tbldesc.query(tbl_command);
      desc_rows := tbldesc_q.rownumbers();
      ndesc     := tbldesc_q.nrows();

      obs_freqs := (tbldesc_q.getcol('IF_REF_FREQ'));
      obs_bws   := (tbldesc_q.getcol('SUB_BANDW'));
      spect_chns := (tbldesc_q.getcol('SUB_NUM_CHANS'));
      polar      := tbldesc_q.getcol('POL');

      tblarch_q := tblarch.query(tbl_command);
      arch_rows := tblarch_q.rownumbers();
      narch     := tblarch_q.nrows();

      src_list  := unique(tblobs_q.getcol('SOURCE_ID'));
      nsrcs     := length(src_list);
      print projects, ": nobs, nsrcs, ndesc = ", nobs, nsrcs, ndesc;

      nredun := 0;
      ndesc1 := ndesc - 1;
      if (ndesc1 > 1) {
          for (j in [1:ndesc1]) {
              jstrt := j + 1;
              for (jj in [jstrt:ndesc]) {
                  if (obs_freqs[jj] != -1.0 &&
                      obs_freqs[jj] == obs_freqs[j] &&
                      obs_bws[jj] == obs_bws[j] &&
                      spect_chns[jj] == spect_chns[j]) {
                     obs_freqs[jj] := -1.0;
                     obs_bws[jj]  := -1.0;
                     spect_chns[jj] := -1;
                     nredun := nredun + 1;
                  }
              }
          }
      }

      src_pos := array(0,2,nsrcs);
      for (j in [1:nsrcs]) {
          tbl_command := spaste("SOURCE_ID == '",src_list[j],"'");
          src_q  := tblobs_q.query(tbl_command)
          temp_pos := src_q.getcell('CENTER_DIR',1);
          src_pos[1,j] := temp_pos[1];
          src_pos[2,j] := temp_pos[2];
      }

      html := nlpaste(html, sprintf("<hr>"));
      if (narch <= 0 || nobs <= 0 || ndesc <= 0) {
         print "ERROR : no rows found for project_code = ", projects;
         return F;
      }
      html := nlpaste(html, "<TABLE>");
      html := nlpaste(html, sprintf("<TR><TD width=150><b> project   <TD><b>: <TD><b>%-12s <TD width=150><b>  observer name <TD><b>: <TD><b>%s</b></TR>",
                     tblproj_q.getcell('PROJECT_CODE',1),
                     tblproj_q.getcell('OBSERVER', 1)));

      telescopes  := unique(tblproj_q.getcol('TELESCOPE'));
      tele_config := unique(tblproj_q.getcol('TELESCOPE_CONFIG'));

      html := nlpaste(html, sprintf("<TR><TD><b> telescope <TD><b>: <TD><b>%s           <TD><b>telescope_config <TD><b>: <TD><b>%s </b></TR>",
                     telescopes, tele_config));

      html := nlpaste(html, sprintf("<TR><TD><b> observing bands <TD><b>: <TD><b>%s </b></TR></TABLE>",
                     unique(tbldesc_q.getcol('IF_BAND'))));

      first_obs_time := tblproj_q.getcell('FIRSTTIME',1);
      last_obs_time  := tblproj_q.getcell('LASTTIME',1);

      sum_exposure   := sum(tblobs_q.getcol('EXPOSURE'))/3600.0;
       
      startvec := tblobs_q.getcol('STARTTIME');
      stopvec  := tblobs_q.getcol('STOPTIME');
      sort_pair(startvec, stopvec);
      nsegments := 1;
      segment_intrvl := 60.0 / 1440.0;
      for (i in [2:nobs]) {
          if ((startvec[i] - stopvec[i-1]) >= segment_intrvl) nsegments := nsegments + 1;
      }

      html := nlpaste(html, sprintf("<TABLE><TR><TD width=150><b> time range <TD><b>: <TD><b>%s - %s</b></TR>", 
                      ingresTime(first_obs_time), ingresTime(last_obs_time)));
      html := nlpaste(html, sprintf("<TR><TD><b> total time on <br>source (hrs) <TD><b>: <TD><b>%8.4f </b></TR>", 
                                    sum_exposure));
      html := nlpaste(html, sprintf("<TR><TD><b> project segments <TD><b>: <TD><b>%3d</b></TR></TABLE>", nsegments));
     
      html := nlpaste(html,sprintf("<hr><p>"));
      html := nlpaste(html,sprintf("<pre><b> number of observing scans  : %-5d</b>", nobs));
      html := nlpaste(html,sprintf("<b> number of archived files   : %-5d</b>", narch));

      for (j in [1:narch]) {
          html := nlpaste(html,sprintf("<b> ... archive file : %-12s</b>",
             tblarch_q.getcell('ARCH_FILE',j)));
      } 

      html := nlpaste(html,sprintf("<p><b> number of spectral windows : %-5d</b>", ndesc));
      for (j in [1:ndesc]) {
          if (obs_freqs[j] != -1) {
             html := nlpaste(html,sprintf("<b> ... obs_freq, bandwidth : %10.4f %10.4f (MHz) nspect : %d  polar = %d</b>",
                  obs_freqs[j]/1.0e6, obs_bws[j]/1.0e6, spect_chns[j], polar[1,j]));
          }
      }

      html := nlpaste(html,sprintf("<p><b> number of sources          : %-5d</b>", nsrcs));
      for (j in [1:nsrcs]) {
          html := nlpaste(html,sprintf("<b> ... source_id : %-3d %-12s %s  %s  J2000</b>", 
                  j, src_list[j], ra2str(src_pos[1,j]), dec2str(src_pos[2,j])));
      }
      html := nlpaste(html,sprintf("<hr><p>"));

   tblproj.done();
   tblobs.done();
   tblarch.done();
   tbldesc.done();
   tblants.done();

   return paste(html);
}
#
#----------------------------------------------------------------------------
#
listarchivefiles := function(startdate='1-jan-1990',stopdate='1-jan-2010', catalogname='MSCATALOG') {
#
# Include all the good stuff
#  
  include 'table.g';
  include 'quanta.g';
#
#
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  private.obsname  := spaste(catalogname,'/OBSERVATION');
  private.archname := spaste(catalogname,'/ARCHIVE');
  private.descname := spaste(catalogname,'/DATADESC');
  private.antsname := spaste(catalogname,'/ANTENNA');
#
  if(!tableexists(private.obsname)) {
    return throw(paste('table ', private.obsname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.archname)) {
    return throw(paste('table ', private.archname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.descname)) {
    return throw(paste('table ', private.descname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.antsname)) {
    return throw(paste('table ', private.antsname, 'does not exist'),
		 origin='catalogtools.g');
  }
#
  start_mjd := dq.quantity(startdate,'d');
  stop_mjd  := dq.quantity(stopdate,'d');
#
# Open the tables 
#
  tblobs  := table(tablename=private.obsname,  readonly=T); 
  tblarch := table(tablename=private.archname, readonly=T); 
  tbldesc := table(tablename=private.descname, readonly=T); 
  tblants := table(tablename=private.antsname, readonly=T); 
#
# TaQL query selecting rows from archive file table
#
  arch_command := paste("STARTTIME >= ",start_mjd.value," and STARTTIME <= ",
                         stop_mjd.value," or STOPTIME >= ",start_mjd.value, 
                         " and ", "STOPTIME <= ", stop_mjd.value);
#  print "arch_command : ", arch_command;
  tblarch_q := tblarch.query(arch_command);
  narch := tblarch_q.nrows();
#
  htmlfile := spaste('> e2edb_archives.html');
  fout := open(htmlfile);
  print "Writing ", narch," rows to file : e2edb_projects.html";
#
# write out the html header stuff, etc.
#
  fprintf(fout,"<HEAD>");write(fout);
  fprintf(fout,"<TITLE>E2E ARCHIVE DB PROJECT LIST</TITLE></HEAD>");write(fout);
  fprintf(fout,"<BODY BGCOLOR=#ffffff TEXT=#000000 LINK=#00009c VLINK=#cc0f0f>");write(fout);
  fprintf(fout,"<H1>E2E Archive DB Project List</H1><p>");write(fout);
  fprintf(fout,"<pre><b>Archive Catalog : %s </b></pre>",catalogname);write(fout);
  fprintf(fout,"<pre><b>Start Date : %s    Stop Date : %s </b></pre>",startdate,stopdate);write(fout);
  hdr_str:=paste("<p><hr><p><pre>Program........Archive File Start.........Archive File Stop......Observer........Archive File<p>"); fprintf(fout,"%s",hdr_str);write(fout);

  for (i in [1:narch]) {
      start := dq.quantity(tblarch_q.getcell('STARTTIME',i),'d');
      start_str := ingresTime(start.value);
      stop  := dq.quantity(tblarch_q.getcell('STOPTIME',i),'d');
      stop_str := ingresTime(stop.value);
#      print sprintf("%-12s %s - %s %-16s %s\n",
#            tblarch_q.getcell('PROJECT_CODE',i), start_str, stop_str,
#            tblarch_q.getcell('OBSERVER',i), tblarch_q.getcell('ARCH_FILE',i));
      fprintf(fout,"<a href=\"/vlabd/VLA00001.html\">%-12s %s - %s %-16s %s</a>",
            tblarch_q.getcell('PROJECT_CODE',i), start_str, stop_str,
            tblarch_q.getcell('OBSERVER',i), tblarch_q.getcell('ARCH_FILE',i));
      write(fout);
  }
}
#
#----------------------------------------------------------------------------
#
listprojects := function(startdate='1-jan-1990',stopdate='1-jan-2010', obs_bands='all',config='all',observer='all',catalogname='MSCATALOG') {
#  
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  private.projname := spaste(catalogname);
#
  if(!tableexists(private.projname)) {
    return throw(paste('table ', private.projname, 'does not exist'),
		 origin='catalogtools.g');
  }
#
  start_mjd := dq.quantity(startdate,'d');
  stop_mjd  := dq.quantity(stopdate,'d');
#
# Open the tables 
#
  tblproj := table(tablename=private.projname,  readonly=T); 
#
# TaQL query selecting rows from archive file table
#
  proj_command := paste("(FIRSTTIME >= ",start_mjd.value," and FIRSTTIME <= ",
                         stop_mjd.value," or LASTTIME >= ",start_mjd.value, 
                         " and ", "LASTTIME <= ", stop_mjd.value,")");
  if (obs_bands != 'all') {
     band_q := paste("and OBS_BANDS == pattern('*");
     band_q := spaste(band_q,obs_bands,"*')");
     proj_command := paste(proj_command, band_q);
  }
  if (config != 'all') {
     config_q := paste("and TELESCOPE_CONFIG == pattern('*");
     config_q := spaste(config_q,config,"*')");
     proj_command := paste(proj_command, config_q);
  }
  if (observer != 'all') {
     observ_q := paste("and OBSERVER == pattern('*");
     observ_q := spaste(observ_q,observer,"*')");
     proj_command := paste(proj_command, observ_q);
  }
#  print "proj_command : ", proj_command;
  tblproj_q := tblproj.query(proj_command);

  nprojs    := tblproj_q.nrows();

  if (nprojs <= 0) {
     print "NO rows found that satisfy the input query.";
     return T;
  }
#
  htmlfile := spaste('> e2edb_projects.html');
  fout := open(htmlfile);

  print "Writing ", nprojs," rows to file : e2edb_projects.html";
#
# write out the html header stuff, etc.
#
  fprintf(fout,"<HEAD>");write(fout);
  fprintf(fout,"<TITLE>E2E ARCHIVE DB PROJECT LIST</TITLE></HEAD>");write(fout);
  fprintf(fout,"<BODY BGCOLOR=#ffffff TEXT=#000000 LINK=#00009c VLINK=#cc0f0f>");write(fout);
  fprintf(fout,"<H1>E2E Archive DB Project List</H1><p>");write(fout);
  fprintf(fout,"<pre><b>Archive Catalog : %s </b></pre>",catalogname);write(fout);
  fprintf(fout,"<pre><b>Start Date : %s    Stop Date : %s </b></pre>",startdate,stopdate);write(fout);
  fprintf(fout,"<pre><b>Observing Bands  : %s </b></pre>", obs_bands);write(fout);
  fprintf(fout,"<pre><b>Telescope Config : %s </b></pre>", config);write(fout);
  fprintf(fout,"<pre><b>N Rows Found : %d </b></pre>", nprojs);write(fout);
  hdr_str:=paste("<p><hr><p><pre>Project......Project First Time.....Project Last Time....Obs Bands......Telescope....Observer...Archive Files<p>"); fprintf(fout,"%s",hdr_str);write(fout);
#
  vecstart := tblproj_q.getcol('FIRSTTIME');
  vecstop  := tblproj_q.getcol('LASTTIME');
#
  startdisplay := vectime2str(vecstart);
  stopdisplay  := vectime2str(vecstop);
#
  for (i in [1:nprojs]) {
#
      project := paste(tblproj_q.getcell('PROJECT_CODE',i));

      start_str := startdisplay[i];
      stop_str  := stopdisplay[i];
#
#      fprintf(fout,"<a href=\"summaries/%s.html\">%-12s %s - %s %-16s %5s:%-6s %-16s %d</a>",     paste(project),
#            project, start_str, stop_str, tblproj_q.getcell('OBS_BANDS',i),
#            tblproj_q.getcell('TELESCOPE',i), tblproj_q.getcell('TELESCOPE_CONFIG',i),
#            tblproj_q.getcell('OBSERVER',i), tblproj_q.getcell('ARCH_FILES',i));

      fprintf(fout,"%-12s %12.5f - %12.5f %-16s %5s:%-6s %-16s %d\n",  
            project, vecstart[i], vecstop[i], tblproj_q.getcell('OBS_BANDS',i),
            tblproj_q.getcell('TELESCOPE',i), tblproj_q.getcell('TELESCOPE_CONFIG',i),
            tblproj_q.getcell('OBSERVER',i), tblproj_q.getcell('ARCH_FILES',i));
      write(fout);
  }
  return T;
}
#
#----------------------------------------------------------------------------
#
fillprojecttableOLD := function(project_code='all', catalogname='MSCATALOG') {
#
# Include all the good stuff
#  
  include 'table.g';
#
#
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  private.obsname  := spaste(catalogname,'/OBSERVATION');
  private.archname := spaste(catalogname,'/ARCHIVE');
  private.descname := spaste(catalogname,'/DATADESC');
  private.antsname := spaste(catalogname,'/ANTENNA');
#
  if(!tableexists(private.obsname)) {
    return throw(paste('table ', private.obsname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.archname)) {
    return throw(paste('table ', private.archname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.descname)) {
    return throw(paste('table ', private.descname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.antsname)) {
    return throw(paste('table ', private.antsname, 'does not exist'),
		 origin='catalogtools.g');
  }
#
# Make a server to handle mscatalog interactions
#
  mscs := F;
  mscs := mscatalogtables(catalogname);
  note('Adding archive info to AIPS++ tables, table name = ', 
        spaste(catalogname), origin='catalog_tools');

  if(is_fail(mscs)) {
     return throw('Failed to open mscatalog server ', mscs::result,
		   origin='catalog_tools');
  }

#
# Open the tables 
#
  tblobs  := table(tablename=private.obsname,  readonly=T); 
  tblarch := table(tablename=private.archname, readonly=T); 
  tbldesc := table(tablename=private.descname, readonly=T); 
  tblants := table(tablename=private.antsname, readonly=T); 
#
# get a vector of all unique project codes in the archive table.
#
  if (project_code == "none") {
     print "ERROR: a project_code was not specified in the function args";
     return F;
  }
  if (project_code == 'all') {
#
     projects := unique(tblarch.getcol('PROJECT_CODE'));
     nprojs   := length(projects);
  }
  else {
     projects := spaste(project_code);
     nprojs   := 1;
  }
#
  print "nprojects = ", nprojs;

  for (i in 1:nprojs) {
      segment := paste(" ");
      nobs := 0;
      narch := 0;
      ndesc := 0;
      nsub := 0;
      tbl_command := spaste("PROJECT_CODE == '",projects[i],"'");
#      print "tbl_command : ", tbl_command;
#
      tblobs_q  := tblobs.query(tbl_command);
      obs_rows  := tblobs_q.rownumbers();
      nobs      := tblobs_q.nrows();
      tbldesc_q := tbldesc.query(tbl_command);
      desc_rows := tbldesc_q.rownumbers();
      ndesc     := tbldesc_q.nrows();
      tblarch_q := tblarch.query(tbl_command);
      arch_rows := tblarch_q.rownumbers();
      narch     := tblarch_q.nrows();

#      print "----------------------------------------------------------------------";
#      print sprintf(" catalog : %s\n", catalogname);
      if (narch <= 0 || nobs <= 0 || ndesc <= 0) {
         print "ERROR : no rows found for project_code = ", projects[i];
         continue;
      }

      project     := tblarch_q.getcell('PROJECT_CODE',1);
      observer    := tblarch_q.getcell('OBSERVER', 1);
      observer_id := tblarch_q.getcell('OBSERVER_ID', 1);

#      print sprintf(" project : %-12s   observer name : %s   observer id : %d\n",
#                      project, observer, observer_id);


      telescopes  := unique(tblarch_q.getcol('TELESCOPE'));
      tele_config := unique(tblarch_q.getcol('TELESCOPE_CONFIG'));

#      print sprintf(" telescope : %s    telescope_config : %s \n",
#                     telescopes, tele_config);

      first_obs_time := min(tblarch_q.getcol('STARTTIME'));
      last_obs_time  := max(tblarch_q.getcol('STOPTIME'));

      row_entry_date := mjdTimeNow();

      sum_exposure   := sum(tblobs_q.getcol('EXPOSURE'))/3600.0;
       
      startvec := tblobs_q.getcol('STARTTIME');
      stopvec  := tblobs_q.getcol('STOPTIME');
      sort_pair(startvec, stopvec);
      nsegments := 1;
      segment_intrvl := 60.0 / 1440.0;
      if (nobs >= 2) {
         for (i in [2:nobs]) {
             if ((startvec[i] - stopvec[i-1]) >= segment_intrvl) nsegments := nsegments + 1;
         }
      }
#       print sprintf(" obs time range : %s - %s\n", ingresTime(first_obs_time), ingresTime(last_obs_time));
#      print sprintf(" total on source time(hrs) : %8.4f \n", sum_exposure);
#      print " number of segments : ", nsegments, " (for off project interval = ", 
#            segment_intrvl * 24.0," hrs)";
     
#      print "----------------------------------------------------------------------";
#      print sprintf(" number of observing scans .: %-5d\n", nobs);
#      print sprintf(" number of archived files ..: %-5d\n", narch);
#      print sprintf(" number of spectral windows : %-5d\n", ndesc);
#      print sprintf(" number of sources .........: %-5d\n", length(unique(tblobs_q.getcol('SOURCE_ID'))));

#      print "----------------------------------------------------------------------";

#
      result := mscs.addproject(project, segment, 
                              observer, observer_id,
			      first_obs_time, last_obs_time,
			      telescopes, tele_config, 
			      sum_exposure, nsegments,
			      narch, row_entry_date);
      if(is_fail(result)) {
         return throw('Failed to write row to project ', result::message, origin='catalog_tools');
          }

  }
  tblobs.done();
  tblarch.done();
  tbldesc.done();
}
#
#----------------------------------------------------------------------------
#
fillprojecttable := function(project_code='all', catalogname='MSCATALOG') {
#
# Include all the good stuff
#  
  include 'table.g';
#
#
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  private.obsname  := spaste(catalogname,'/OBSERVATION');
  private.archname := spaste(catalogname,'/ARCHIVE');
  private.descname := spaste(catalogname,'/DATADESC');
  private.antsname := spaste(catalogname,'/ANTENNA');
#
  if(!tableexists(private.obsname)) {
    return throw(paste('table ', private.obsname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.archname)) {
    return throw(paste('table ', private.archname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.descname)) {
    return throw(paste('table ', private.descname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.antsname)) {
    return throw(paste('table ', private.antsname, 'does not exist'),
		 origin='catalogtools.g');
  }
#
# Make a server to handle mscatalog interactions
#
  mscs := F;
  mscs := mscatalogtables(catalogname);
  note('Adding archive info to AIPS++ tables, table name = ', 
        spaste(catalogname), origin='catalog_tools');

  if(is_fail(mscs)) {
     return throw('Failed to open mscatalog server ', mscs::result,
		   origin='catalog_tools');
  }

#
# Open the tables 
#
  tblobs  := table(tablename=private.obsname,  readonly=T); 
  tblarch := table(tablename=private.archname, readonly=T); 
  tbldesc := table(tablename=private.descname, readonly=T); 
  tblants := table(tablename=private.antsname, readonly=T); 
#
# get a vector of all unique project codes in the archive table.
#
  if (project_code == "none") {
     print "ERROR: a project_code was not specified in the function args";
     return F;
  }
  if (project_code == 'all') {
#
     projects := unique(tblarch.getcol('PROJECT_CODE'));
     nprojs   := length(projects);
  }
  else {
     projects := spaste(project_code);
     nprojs   := 1;
  }
#
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Index the tables here..
#
indxobs  := tableindex(tblobs, 'PROJECT_CODE');
indxdesc := tableindex(tbldesc,'PROJECT_CODE');
indxarch := tableindex(tblarch,'PROJECT_CODE');
#
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
  print "nprojects = ", nprojs;

  obs_bands := paste("?");
  segment := paste(" ");
  tbl_rec := [=];
  for (i in 1:nprojs) {
      nobs := 0;
      narch := 0;
      ndesc := 0;
      nsub := 0;
#      tbl_command := spaste("[PROJECT_CODE = '",projects[i],"']");
      tbl_rec := [PROJECT_CODE = projects[i]];
#      print "tbl_rec : ", tbl_rec;
#
      obs_rows  := indxobs.rownrs(tbl_rec);
      nobs      := length(obs_rows);
      desc_rows := indxdesc.rownrs(tbl_rec);
      ndesc     := length(desc_rows);
      arch_rows := indxarch.rownrs(tbl_rec);
      narch     := length(arch_rows);

#      print "----------------------------------------------------------------------";
#      print sprintf(" catalog : %s\n", catalogname);
#      print "nobs, ndesc, narch = ", nobs, ndesc, narch;
      if (narch <= 0 || nobs <= 0 || ndesc <= 0) {
         print "ERROR : no rows found for project_code = ", projects[i];
         continue;
      }

      project     := tblarch.getcell('PROJECT_CODE',arch_rows[1]);
      observer    := tblarch.getcell('OBSERVER', arch_rows[1]);
      observer_id := tblarch.getcell('OBSERVER_ID', arch_rows[1]);

#      print sprintf(" project : %-12s   observer name : %s   observer id : %d\n",
#                      project, observer, observer_id);


#      telescopes  := unique(tblarch_q.getcol('TELESCOPE'));
#      tele_config := unique(tblarch_q.getcol('TELESCOPE_CONFIG'));

      telescopes   := tblarch.getcell('TELESCOPE', arch_rows[1]);
      tele_config  := tblarch.getcell('TELESCOPE_CONFIG', arch_rows[1]);

#      print sprintf(" telescope : %s    telescope_config : %s \n",
#                     telescopes, tele_config);

      tblarch_q := tblarch.selectrows(arch_rows);
      startavec := tblarch_q.getcol('STARTTIME');
      stopavec  := tblarch_q.getcol('STOPTIME');

      first_obs_time := min(startavec);
      last_obs_time  := max(stopavec);

      end_proprietary_period := last_obs_time + 540.0;

#       print sprintf(" obs time range : %s - %s\n", ingresTime(first_obs_time), ingresTime(last_obs_time));

      row_entry_date := mjdTimeNow();

      tblobs_q := tblobs.selectrows(obs_rows);
      sumvec   := tblobs_q.getcol('EXPOSURE');
      startvec := tblobs_q.getcol('STARTTIME');
      stopvec  := tblobs_q.getcol('STOPTIME');

      sum_exposure   := sum(sumvec)/3600.0;
       
#      sort_pair(startvec, stopvec);
      nsegments := 1;
      segment_intrvl := 60.0 / 1440.0;

      if (nobs >= 2) {
         for (i in [2:nobs]) {
             if ((startvec[i] - stopvec[i-1]) >= segment_intrvl) nsegments := nsegments + 1;
         }
      }
#      print sprintf(" total on source time(hrs) : %8.4f \n", sum_exposure);
#      print " number of segments : ", nsegments, " (for off project interval = ", 
#            segment_intrvl * 24.0," hrs)";

#      print "----------------------------------------------------------------------";
#      print sprintf(" number of observing scans .: %-5d\n", nobs);
#      print sprintf(" number of archived files ..: %-5d\n", narch);
#      print sprintf(" number of spectral windows : %-5d\n", ndesc);
#      print sprintf(" number of sources .........: %-5d\n", length(unique(tblobs_q.getcol('SOURCE_ID'))));

#      print "----------------------------------------------------------------------";

#
      result := mscs.addproject(project, segment, 
                              observer, observer_id,
			      first_obs_time, last_obs_time,
                              end_proprietary_period,
			      telescopes, tele_config, obs_bands, 
			      sum_exposure, nsegments,
			      narch, row_entry_date);
      if(is_fail(result)) {
         return throw('Failed to write row to project ', result::message, origin='catalog_tools');
      }

      tblobs_q.done();
      tblarch_q.done();
  }
  tblobs.done();
  tblarch.done();
  tbldesc.done();
}
#
#----------------------------------------------------------------------------
#
fixprojecttable := function(project_code='all', catalogname='MSCATALOG') {
#
# Fix of the day; fix the incorrect project start times in the project table.
#
# Include all the good stuff
#  
  include 'table.g';
#
#
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  private.projname := spaste(catalogname);
  private.obsname  := spaste(catalogname,'/OBSERVATION');
  private.archname := spaste(catalogname,'/ARCHIVE');
  private.descname := spaste(catalogname,'/DATADESC');
  private.antsname := spaste(catalogname,'/ANTENNA');
#
  if(!tableexists(private.projname)) {
    return throw(paste('table ', private.projname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.obsname)) {
    return throw(paste('table ', private.obsname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.archname)) {
    return throw(paste('table ', private.archname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.descname)) {
    return throw(paste('table ', private.descname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.antsname)) {
    return throw(paste('table ', private.antsname, 'does not exist'),
		 origin='catalogtools.g');
  }
#
# Make a server to handle mscatalog interactions
#
  mscs := F;
  mscs := mscatalogtables(catalogname);
  note('Adding archive info to AIPS++ tables, table name = ', 
        spaste(catalogname), origin='catalogtools');

 if(is_fail(mscs)) {
     return throw('Failed to open mscatalog server ', mscs::result,
		   origin='catalog_tools');
  }

#
# Open the tables 
#
  tblproj := table(tablename=private.projname, readonly=F);
  tblobs  := table(tablename=private.obsname,  readonly=T); 
  tblarch := table(tablename=private.archname, readonly=T); 
  tbldesc := table(tablename=private.descname, readonly=T); 
  tblants := table(tablename=private.antsname, readonly=T); 
#
  nprojs  := tblproj.nrows();
#
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Index the tables here..
#
indxobs  := tableindex(tblobs, 'PROJECT_CODE');
indxdesc := tableindex(tbldesc,'PROJECT_CODE');
indxarch := tableindex(tblarch,'PROJECT_CODE');
#
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
  print "nprojects = ", nprojs;

  segment := paste(" ");
  tbl_rec := [=];
  for (i in 1:nprojs) {
      nobs := 0;
      narch := 0;
      ndesc := 0;
      nsub := 0;

      project := tblproj.getcell('PROJECT_CODE', i);
      tbl_rec := [PROJECT_CODE = project];
      print "tbl_rec : ", tbl_rec;
#
      obs_rows  := indxobs.rownrs(tbl_rec);
      nobs      := length(obs_rows);
      desc_rows := indxdesc.rownrs(tbl_rec);
      ndesc     := length(desc_rows);
      arch_rows := indxarch.rownrs(tbl_rec);
      narch     := length(arch_rows);

      if (narch <= 0 || nobs <= 0 || ndesc <= 0) {
         print "ERROR : no rows found for project_code = ", projects[i];
         continue;
      }

      tblobs_q := tblobs.selectrows(obs_rows);
      sumvec   := tblobs_q.getcol('EXPOSURE');
      startvec := tblobs_q.getcol('STARTTIME');
      stopvec  := tblobs_q.getcol('STOPTIME');

      first_obs_time := min(startvec);
      last_obs_time  := max(stopvec);

      tblproj.putcell('FIRSTTIME', i, first_obs_time);

      tblobs_q.done();
  }
  tblproj.done();
  tblobs.done();
  tblarch.done();
  tbldesc.done();
}
#----------------------------------------------------------------------------
#
fixprojectbands := function(project_code='all', catalogname='MSCATALOG') {
#
# Fix of the day; load all observing bands found in the datadesc table for
# a selected project_code into the project table.
#
# Include all the good stuff
#  
  include 'table.g';
#
#
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  private.projname := spaste(catalogname);
  private.obsname  := spaste(catalogname,'/OBSERVATION');
  private.archname := spaste(catalogname,'/ARCHIVE');
  private.descname := spaste(catalogname,'/DATADESC');
  private.antsname := spaste(catalogname,'/ANTENNA');
#
  if(!tableexists(private.projname)) {
    return throw(paste('table ', private.projname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.obsname)) {
    return throw(paste('table ', private.obsname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.archname)) {
    return throw(paste('table ', private.archname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.descname)) {
    return throw(paste('table ', private.descname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.antsname)) {
    return throw(paste('table ', private.antsname, 'does not exist'),
		 origin='catalogtools.g');
  }
#
# Open the tables 
#
  tblproj := table(tablename=private.projname, readonly=F);
  tblobs  := table(tablename=private.obsname,  readonly=T); 
  tblarch := table(tablename=private.archname, readonly=T); 
  tbldesc := table(tablename=private.descname, readonly=T); 
  tblants := table(tablename=private.antsname, readonly=T); 
#
  nprojs  := tblproj.nrows();
#
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Index the tables here..
#
indxobs  := tableindex(tblobs, 'PROJECT_CODE');
indxdesc := tableindex(tbldesc,'PROJECT_CODE');
indxarch := tableindex(tblarch,'PROJECT_CODE');
#
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
  print "nprojects = ", nprojs;

  segment := paste(" ");
  tbl_rec := [=];
  for (i in 1:nprojs) {
      nobs := 0;
      narch := 0;
      ndesc := 0;
      nsub := 0;

      project := tblproj.getcell('PROJECT_CODE', i);
      tbl_rec := [PROJECT_CODE = project];
#
      desc_rows := indxdesc.rownrs(tbl_rec);
      ndesc     := length(desc_rows);


      if (ndesc <= 0) {
         print "ERROR : no datadesc rows found for project_code = ", projects[i];
         continue;
      }

      tbldesc_q := tbldesc.selectrows(desc_rows);
      obs_bands := unique(tbldesc_q.getcol('IF_BAND'));

#      print "tbl_rec, nrows, obs_bands : ", tbl_rec, ndesc, obs_bands;

      tblproj.putcell('OBS_BANDS', i, paste(obs_bands));

      tbldesc_q.done();
  }
  tblproj.done();
  tblobs.done();
  tblarch.done();
  tbldesc.done();
}
#----------------------------------------------------------------------------
#
makesummaryfiles := function(startproject='none',onlyproject='none',
                             catalogname='MSCATALOG') {
#
# Include all the good stuff
#  
  include 'table.g';
#
#  
  private := [=];
  public  := [=];
#
  private.projname := spaste(catalogname);
#
  if(!tableexists(private.projname)) {
    return throw(paste('table ', private.projname, 'does not exist'),
		 origin='catalogtools.g');
  }
#
# Open the tables 
#
  tblproj := table(tablename=private.projname, readonly=T); 
#
# get a vector of all unique project codes in the project table.
#
  projects := tblproj.getcol('PROJECT_CODE');
  nprojs   := length(projects);
#
  istart := 0;
  if (startproject != 'none') {
     istart := 1;
  }
  print "nprojs = ", nprojs;
  for (i in 1:nprojs) {
      project_name := spaste(projects[i]);
      if (istart == 1) {
         if (startproject != project_name) {
            print "Skipping project : ", project_name;
            continue;
         }
         istart := 0;
      } 
      filename := spaste("summaries/tmp/proj_",project_name,".html");
   
      html := projectsummary(project_code=project_name,catalogname=catalogname);
#
      htmlfile := paste('>', filename);
      fout := open(htmlfile);
      write(fout, html);
      print "Writing project summary for ", project_name," to file : ",filename;

#     sh_command := paste("mv e2edb_project_summary.html ",filename);     
#     shell(sh_command);
  }
  return T;
}
#----------------------------------------------------------------------------
#
fixtablekeywords := function(name='MSCATALOG') {
#
  include 'table.g';
#
#  
  private := [=];
  public  := [=];
#
  private.tables := [=];
  for (field in "ARCHIVE OBSERVATION PROJECT ANTENNA DATADESC SUBARRAY") {
    if (field == 'PROJECT') {
       tablename := spaste(name);
    }
    else {
       tablename := spaste(name, '/', field);
    }
    private.tables[field] := table(tablename, ack=F, readonly=F);
    private.tables[field].removekeyword(to_upper(field));
  }
#
# Cross add keywords pointing to all tables for convenience when browsing
#
  for (field in    "ARCHIVE OBSERVATION PROJECT ANTENNA DATADESC SUBARRAY") {
    for (otable in "ARCHIVE OBSERVATION PROJECT ANTENNA DATADESC SUBARRAY") {
       if (field == otable) continue;
       if (otable == 'PROJECT') {
          tablename := spaste(name);
       }
       else {
          tablename := spaste(name, '/', otable);
       }
#       print "in table, otable,  keyword :", field, otable, tablename; 
       private.tables[field].putkeyword(to_upper(otable), tablename);
    }
  }
#
# Close all tables
#
  for (field in "ARCHIVE OBSERVATION PROJECT ANTENNA DATADESC SUBARRAY") {
     private.tables[field].close();
  }

  return T;
}
#----------------------------------------------------------------------------
#
toupperproject := function(project_code='all', catalogname='MSCATALOG',deleterows=F) {

#
# Include all the good stuff
#  
  include 'table.g';
#
#
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  private.project  := spaste(catalogname);
  private.obsname  := spaste(catalogname,'/OBSERVATION');
  private.archname := spaste(catalogname,'/ARCHIVE');
  private.descname := spaste(catalogname,'/DATADESC');
  private.antsname := spaste(catalogname,'/ANTENNA');
#
  if(!tableexists(private.obsname)) {
    return throw(paste('table ', private.obsname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.archname)) {
    return throw(paste('table ', private.archname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.descname)) {
    return throw(paste('table ', private.descname, 'does not exist'),
		 origin='catalogtools.g');
  }
  if(!tableexists(private.antsname)) {
    return throw(paste('table ', private.antsname, 'does not exist'),
		 origin='catalogtools.g');
  }
#
# Open the tables 
#
  tblproj := table(tablename=private.project, readonly=F);
  tblobs  := table(tablename=private.obsname, readonly=F); 
  tblarch := table(tablename=private.archname, readonly=F); 
  tbldesc := table(tablename=private.descname, readonly=F); 
  tblants := table(tablename=private.antsname, readonly=F); 
#
  nproj := tblproj.nrows();
  nobs  := tblobs.nrows();
  narch := tblarch.nrows();
  ndesc := tbldesc.nrows();
  nants := tblants.nrows();
#
  tbl_command := spaste("PROJECT_CODE == '",project_name,"'");
#  
  if (project_name == 'all') {
     tblprojcol := tblproj.getcol('PROJECT_CODE');

  }
  else {
     tblproj_q := tblproj.query(tbl_command);
     tblprojcol := tblproj_q.getcol('PROJECT_CODE');
  }
  
}
#----------------------------------------------------------------------------
#
fiximagetable := function(project_code='none', catalogname='IMCATALOG', delim='X') {

#
# Include all the good stuff
#  
  include 'table.g';
#
#
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  private.imname  := spaste(catalogname,'.image');
#
  if(!tableexists(private.imname)) {
    print "table doesnot exist : ", private.imname;
    return throw(paste('table ', private.imname, 'does not exist'),
		 origin='catalogtools.g');
  }
#
# Open the tables 
#
  tblim  := table(tablename=private.imname, readonly=F); 
#
# Get a sub-table that contains the queried rows from the image table
#
  im_command := paste("PROJECT_CODE == '");
  im_command := spaste(im_command,project_code,"'");
#
  print "im_command : ", im_command;
  print "shape tblim   = ", shape(tblim);
  tblim_q := tblim.query(im_command);
  nim := 0;
  if (shape(tblim_q) > 0) {
     nim := tblim_q.nrows();
  }
  print "selected rows to modify -  image table : ", nim;  

  nfixed := 0;
  for (i in 1:nim) {
    filename := tblim_q.getcell('IMAGE_FILE',i);
    srcname  := split(filename, spaste(delim));
    if (shape(srcname) <= 1) continue;

    nfixed := nfixed + 1;
    plotfile := spaste(srcname[1],".gif");
    tblim_q.putcell('PLOT_FILE',i,paste(plotfile));
    tblim_q.putcell('FIELD_ID',i, paste(srcname[1]));
    tblim_q.putcell('SOURCE_TYPE',i,paste("calibrator"));
    tblim_q.putcell('IMAGE_TYPE',i,paste("AIPS-FITS"));
 }
 print "fixed nrows in table : ", nfixed;
}
#----------------------------------------------------------------------------
#
imagesummary := function(project_code='none', catalogname='IMCATALOG') {

#
# Include all the good stuff
#  
  include 'table.g';
#
#
# Define private data and public functions
#  
  private := [=];
  public  := [=];
#
  const arcsecrad := 1.0 / 4.848136811095e-06;

  func nlpaste(...) paste(...,sep='\n');
#
  private.imname  := spaste(catalogname);
#
  if(!tableexists(private.imname)) {
    print "table doesnot exist : ", private.imname;
    return throw(paste('table ', private.imname, 'does not exist'),
		 origin='catalogtools.g');
  }
#
# Open the tables 
#
  tblim  := table(tablename=private.imname, readonly=T); 

#
# Get a sub-table that contains the queried rows from the image table
#
  im_command := paste("PROJECT_CODE == '");
  im_command := spaste(im_command,project_code,"'");
#
  print "im_command : ", im_command;
  print "shape tblim   = ", shape(tblim);
  tblim_q := tblim.query(im_command);
  nim := 0;
  if (shape(tblim_q) > 0) {
     nim := tblim_q.nrows();
  }
  for (i in 1:nim) {

      spect_window := tblim_q.getcell('SPECTRAL',i);
      band_str := freq_band(spect_window[3]*1.0e-6);
      project := spaste(tblim_q.getcell('PROJECT_CODE',i));
      field_id := spaste(tblim_q.getcell('FIELD_ID',i));
      start := dq.quantity(tblim_q.getcell('OBS_DATE',i),'d');
      start_str := ingresTime(start.value);
      temp_pos := tblim_q.getcell('CENTER_DIR',i);
      pixel_size   := tblim_q.getcell('FIELD_SIZE',i);
      pixel_incr   := tblim_q.getcell('PIXEL_INCR',i); 
      restore_beam := tblim_q.getcell('RESTORE_BEAM',i);
      pixel_range  := tblim_q.getcell('PIXEL_RANGE',i);
      field_size[1] := pixel_size[1]*pixel_incr[1]*arcsecrad;            
      field_size[2] := pixel_size[2]*pixel_incr[2]*arcsecrad;      

      #
      # write out the html header stuff, etc.
      #
      html := paste("");
      #
      html := nlpaste(html,sprintf("<HEAD>"));
      html := nlpaste(html,sprintf("<TITLE>E2E ARCHIVE DB IMAGE SUMMARY</TITLE></HEAD>"));
      html := nlpaste(html,sprintf("<BODY BGCOLOR=#ffffff TEXT=#000000 LINK=#00009c VLINK=#cc0f0f>"));
      html := nlpaste(html,sprintf("<CENTER><H1>NRAO Data Archive - Image Summary (%-s)</H1></CENTER><hr>", field_id));

      html := nlpaste(html, sprintf("<TABLE><TR><TD width=140><b>  Project .... <TD><b>: <TD><b>%-12s </b></TD></TR>",
                      project));

      html := nlpaste(html, sprintf("<TR><TD><b>  Field_ID  <TD><b>: <TD><b>%-12s </b></TD></TR>",
                     field_id));

      html := nlpaste(html, sprintf("<TR><TD><b> Telescope  <TD><b>: <TD><b>%s </b></TD></TR>",
                     tblim_q.getcell('TELESCOPE',i)));

      html := nlpaste(html, sprintf("<TR><TD><b>  Obs_Band  <TD><b>: <TD><b>%s </b></TD></TR>",
                     band_str));

      html := nlpaste(html, sprintf("<TR><TD><b>  Obs_Date  <TD><b>: <TD><b>%s </b></TD></TR>",
                      start_str));

      html := nlpaste(html, sprintf("<TR><TD><b>  Image_Type  <TD><b>: <TD><b>%s </b></TD></TR>",
                     tblim_q.getcell('IMAGE_TYPE',i)));

      html := nlpaste(html, sprintf("<TR><TD><b>  Source_Type <TD><b>: <TD><b>%s </b></TD></TR>",
                     tblim_q.getcell('SOURCE_TYPE',i)));

      html := nlpaste(html, sprintf("<TR><TD><b>  Exposure  <TD><b>: <TD><b>%f </b></TD></TR></TABLE>",
                      tblim_q.getcell('EXPOSURE',i)));
 
      html := nlpaste(html, sprintf("<p><hr>"));

      html := nlpaste(html, sprintf("<TABLE><TR><TD width=140><b>Obs_Freq    <TD><b>: <TD><b>%f (MHz)</b></TD></TR>",
                      spect_window[3]*1.0e-6));

      html := nlpaste(html, sprintf("<TR><TD><b>Band_Width  <TD><b>: <TD><b>%f (MHz)</b></TR>",
                      spect_window[4]*1.0e-6));

      html := nlpaste(html, sprintf("<TR><TD><b>Spect_Chans <TD><b>: <TD><b>%d</b></TR>",
                      as_integer(spect_window[1])));

      html := nlpaste(html, sprintf("<TR><TD><b>Polarization <TD><b>: <TD><b>%s</b></TR></TABLE>",
                      tblim_q.getcell('POLARIZATION',i)));

      html := nlpaste(html, sprintf("<p><hr>"));

      html := nlpaste(html, sprintf("<TABLE><TR><TD width=140><b>Field Center <TD><b>: <TD><b>%s  %s  (J2000) at pixels : %7.2f %7.2f </b></TD></TR>",
                       ra2str(temp_pos[1]), dec2str(temp_pos[2]),
                       pixel_size[3], pixel_size[4]));


      html := nlpaste(html, sprintf("<TR><TD><b>Field Size  <TD><b>: <TD><b>%f x %f (arcsec), pixels : %d x %d</b></TD></TR>",
                       field_size[1], field_size[2], 
                       pixel_size[1], pixel_size[2]));

      html := nlpaste(html, sprintf("<TR><TD><b>Pixel Increment <TD><b>: <TD><b>%12.4e x %12.4e (arcsec)</b></TD></TR>",
                       pixel_incr[1]*arcsecrad, pixel_incr[2]*arcsecrad));

      html := nlpaste(html, sprintf("<TR><TD><b>Restoring Beam <TD><b>: <TD><b>%f x %f (arcsec), pa = %f (deg)</b></TD></TR>",
                       restore_beam[1], restore_beam[2], restore_beam[3]));

      html := nlpaste(html, sprintf("<TR><TD><b>Image Intensity <TD><b>: <TD><b>max = %f, min = %f, rms = %f (%s)</b></TD></TR></TABLE>",
                       pixel_range[1], pixel_range[2], pixel_range[3],
                       tblim_q.getcell('IMAGE_UNITS',i)));

      html := nlpaste(html, sprintf("<p><hr>"));
       
      html := nlpaste(html,sprintf("<TABLE><TR><TD width=140><b>Archive Catalog <TD><b>: <TD><b>%s </b></TD></TR>",catalogname));

      html := nlpaste(html, sprintf("<TR><TD><b>Directory <TD><b>: <TD><b>%s</b></TD></TR>",
                      tblim_q.getcell('DIRECTORY',i)));

      html := nlpaste(html, sprintf("<TR><TD><b>Image_File <TD><b>: <TD><b>%s</b></TD></TR>",
                      tblim_q.getcell('IMAGE_FILE',i)));

      html := nlpaste(html, sprintf("<TR><TD><b>Plot_File <TD><b>: <TD><b>%s</b></TD></TR>",
                      tblim_q.getcell('PLOT_FILE',i)));

      html := nlpaste(html, sprintf("<TR><TD><b>Model_File <TD><b>: <TD><b>%s</TD></TR></TABLE></b>",
                      tblim_q.getcell('MODEL_FILE',i)));


      filename := spaste("summaries/tmp/im_",project,"_",field_id,band_str,".html");
      htmlfile := paste('>', filename);
      fout := open(htmlfile);
      write(fout, html);
      print "Writing image summary for ", project," to file : ",filename;

 }
 return T;
}

