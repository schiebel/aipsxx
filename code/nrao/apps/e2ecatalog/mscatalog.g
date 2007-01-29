# mscatalog: Define and manipulate ms catalogs
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
#   $Id: mscatalog.g,v 19.0 2003/07/16 03:44:33 aips2adm Exp $
#
#----------------------------------------------------------------------------

pragma include once;

#
# 

mscatalog := function(msname, archfilename='unavailable', catalogname='MSCATALOG',
                      datatype='UNKNOWN') {
#
#  Include all the good stuff
#  
   include 'table.g';
   include 'quanta.g';
   include 'measures.g';
   include 'e2efuncs.g';
#
#
   if (!tableexists(msname)) {
      return throw(paste('table ', msname, 'does not exist'),
                         origin='mscatalog.g');
   }
#
#  Define private data and public functions
#  
   private := [=];
   public  := [=];
#
   private.msname := msname;
   private.archfilename := archfilename;
   private.maxants := 100;
   private.catalogname := catalogname;
   private.data_type := datatype;
#
#  Now we gather information from the ms. We do this on construction
#  so that the user can write either sql or a table after construction
#
   note('Input MS file name   = ', private.msname, origin='mscatalog');
#
#  Internally we work by keeping mappings in GLish records. Once these
#  are set up, one can then use a simple loop over the record fields to
#  process the information.
#
#  Map our names to subtable names
#
   private.tablenames := [table='',
                          anttable='/ANTENNA',
                          fltable ='/FIELD',
                          swtable ='/SPECTRAL_WINDOW',
                          poltable='/POLARIZATION',
                          obtable ='/OBSERVATION',
                          datadesc='/DATA_DESCRIPTION',
                          hstable ='/HISTORY'];
#
#  Define mappings between columns and private fields
#
   private.mappings := [=];
   private.nrows := [=];
#
#  Get columns from the MAIN table
#
   private.mappings['table'] := [time='TIME',
                                 scan_num='SCAN_NUMBER',
                                 field_id='FIELD_ID',
                                 data_id='DATA_DESC_ID',
                                 subarray='ARRAY_ID',
                                 avg_int='INTERVAL',
                                 ant1='ANTENNA1',
                                 ant2='ANTENNA2',
                                 uvw='UVW'];
#
#  Get columns from the ANTENNAS table
#
   private.mappings['anttable'] := [ant_name='NAME',
                                    station='STATION',
                                    ant_type='TYPE',
                                    mount='MOUNT',
                                    ant_xyz='POSITION',
                                    axis_off='OFFSET',
                                    dish_diam='DISH_DIAMETER'];
#
#  Get columns from the OBSERVATIONS table
#
   private.mappings['obtable'] := [project='PROJECT',
                                   time_range='TIME_RANGE',
                                   tele_name='TELESCOPE_NAME',
                                   observer='OBSERVER'];
#
#  Get columns from the DATA_DESCRIPTION table
#
   private.mappings['datadesc'] := [polar_id='POLARIZATION_ID',
                                    spect_id='SPECTRAL_WINDOW_ID'];
#
#  This next line must be wrong: we should not be accessing
#  NRAO-only columns.
#
#   if (private.tele_name == 'GBT') private.mappings['prvr_id']:='NRAO_GBT_RECEIVER_ID';
#
#  Get columns from the SPECTRAL_WINDOWS table
#
    private.mappings['swtable'] := [net_side='NET_SIDEBAND',
                                    num_chan='NUM_CHAN',
                                    tot_bandw='TOTAL_BANDWIDTH',
                                    ref_freq='REF_FREQUENCY',
                                    chan_wide='CHAN_WIDTH'];
#
#  Get columns from the POLARIZATION table
#
#  corr_type is an array dimensioned [element, row]
#
   private.mappings['poltable'] := [corr_type='CORR_TYPE'];
#
#  Get columns from the FIELD table
#
   private.mappings['fltable'] := [source_id='NAME',
                                   calcode='CODE',
                                   direct='PHASE_DIR'];
#
#  Get columns from the HISTORY table
#
   private.mappings['hstable'] := [origin='ORIGIN'];
#
#  Now that all the mappings are in place, we can simply open all the
#  tables and get the corresponding columns
#
#  Check to see if all tables exist
#
   for (field in field_names(private.tablenames)) {
      tname := spaste(private.msname, private.tablenames[field]);
      if (!tableexists(tname)) {
         return throw('table ', tname, ' does not exist', origin='mscatalog');
      }
   }
#
#  Now get required columns from the tables
#
   for (field in field_names(private.mappings)) {
      tname := spaste(private.msname, private.tablenames[field]);
      private[field] := table(tname, readonly=F, ack=F);
      private.nrows[field] := private[field].nrows();
      colnames := private[field].colnames();
#      print "table, nrows = ", spaste(field), private.nrows[field];

      for (col in field_names(private.mappings[field])) {
         colname := private.mappings[field][col];
         if (!any(colname==colnames)) {
            return throw('Column ', colname,
                         ' does not exist in subtable ', tname,
                         origin='mscatalog');
         }
         private[col] := private[field].getcol(colname);
      }
   }
#   print "finished loading columns";
#
#  Fixer upper
#
   private.vec_pol   := len(private.corr_type);
   private.npts_pol  := private.vec_pol[1];
   private.nrows['pol'] := 1;
   if (shape(private.vec_pol) > 1)
      private.nrows['pol'] := private.vec_pol[2];
#
#  Get seconds from 1-Jan-1970 0:0:0, calculate seconds from 1-Jan-2000
#
   private.from2000 := as_integer(floor(time() - 946728000));
#
#----------------------------------------------------------------------------
#
#  Utility function to return a vector of indices where a change occurs
#
   private.indexchanges := function(x) {
      n:=length(x);
      if (n>1) {
         previous:=x;
         previous[2:n]:=x[1:(n-1)];
         previous[1]-:=1;
         indices:=1:n;
         return indices[x!=previous];
      }
      else {
         return [1];
      }
   }
#
#----------------------------------------------------------------------------
#
#  Now for a bit of sundry initialization
#
   private.arch_file_date := as_double(53000.0);
   private.catalog_date   := as_double(53000.0);
#
#  Get the last modified date/time from the ms file.
#
   sh_cmd  := paste("ls -lt --full-time | grep ", msname);
   linebuf := paste(shell(sh_cmd));

   linevec := split(linebuf);
   datestr := spaste(linevec[8],linevec[7],linevec[10]);
   timestr := spaste(linevec[9]);
   private.arch_file_date := mjdObsTime(datestr, timestr);
#
   private.catalog_date := mjdTimeNow();
#  print "MJD now = ", private.catalog_date;

   private.ant_count := array(0,private.maxants);
   private.desc_id   := array(0,private.maxants);
#
   private.last_mjd_time := private.time[1]/(24.0*3600.0);
   private.last_field_id := private.field_id[1];
   private.ref_mjd       := floor(private.last_mjd_time);
   private.last_mjd_time := private.ref_mjd;
#
   tu_1    := dq.quantity(private.ref_mjd, 'd');
   private.timstr1 := dq.time(tu_1, form="dmy");
#
   private.ms_start := private.time_range[1]/(24.0*3600.0) + 0.00001;
   private.ms_stop  := private.time_range[2]/(24.0*3600.0) + 0.00001;
#
#  Measurement Sets that were constructed from FITS files generated by 
#  classical AIPS do not have the project column in the observations
#  table set. Copy observer into project. Observer carries the project
#  name in the FITS file.
#
   if (strlen(private.observer)<= 0) private.observer:= paste('UNKNOWN');
   if (strlen(private.project) <= 0) private.project := paste(private.observer);
   private.segment := paste(' ');
   private.observer_id:=100;
#
   private.corr_mode := spaste(' ');
   private.project := spaste(clipstr(private.project, 16));
   private.observer := spaste(clipstr(private.observer, 8));
   private.tele_name := spaste(clipstr(private.tele_name, 10));
   private.observer := spaste(clipstr(private.observer, 8));
   note("Project, observer, telescope = ", private.project, ', ', 
        private.observer, private.tele_name, origin="mscatalog");
#
#  Now determine the archive format
#
   private.arch_format := paste('VLA Exp');
   if (private.tele_name == 'GBT')
      private.arch_format := paste('FITS-GBT');
   if (private.tele_name == 'NRAO_GBT')
      private.arch_format := paste('FITS-GBT');
   if (private.tele_name == 'VLBA')
      private.arch_format := paste('FITS-IDI');
   if (private.tele_name == 'VLA' && private.nrows['hstable'] > 1)
      private.arch_format := paste('AIPS-FITS');
   private.tele_config := 'UNKNOWN';
#
#  End general purpose initialization ..
#----------------------------------------------------------------------------
#
#  Public function that writes SQL statements or AIPS++ tables containing 
#  the mscatalog info
#
   public.write := function(what='tables') {
    
      wider private;
#
#  Make a server to handle mscatalog interactions
#
      mscs := F;
      if (what=='tables') {
         include 'mscatalogtables.g';
         mscs := mscatalogtables(private.catalogname);
         note('Adding archive info to AIPS++ tables, catalog name = ', 
              private.catalogname, origin='mscatalog.writetable');
      }
      else if (what=='sql'){
         include 'mscatalogsql.g';
         mscs := mscatalogsql(private.catalogname);

         note('Adding archive info to rdbms SQL, SQL script file = ', 
              spaste(private.catalogname, '.sql'), origin='mscatalog.writetable');
      }

      if (is_fail(mscs)) {
         return throw('Failed to open mscatalog server ', mscs::result,
                     origin='mscatalog');
      }
#
#  Now add archive information
#
      print "archive row = ",private.project,'.',
                                private.ms_start, private.ms_stop,
                                private.tele_name,'.', private.tele_config, 
                                private.arch_format;
      result := mscs.addarchive(private.project, private.segment, 
                                private.ms_start, private.ms_stop,
                                private.tele_name, private.tele_config, 
                                private.arch_format, private.data_type,
                                private.subarray[1], 
                                private.from2000, private.archfilename, 
                                private.arch_file_date, private.catalog_date);
      if (is_fail(result)) {
         return throw('Failed to write row to archive table', result::message, 
                      origin='mscatalog');
      }
#
#  Now load data_desc catalog table into a temporary table
#
      ipol := array(0, 4);
      temp_ipol := array(256,4);
      for (i in 1:private.npts_pol) {
         ipol[i] := private.corr_type[i,1];
      }
      for (i in 1:private.nrows['datadesc']) {
         idesc  := i;
         ispect := private.spect_id[idesc] + 1;
         ircvr  := -1;
         temp_project[i]  := paste(private.project);
         temp_segment[i]  := paste(private.segment);
         temp_from2000[i] := private.from2000;
         temp_idesc[i]    := idesc;
         temp_if_band[i]  := paste('??');
         temp_ircvr[i]    := ircvr;
         temp_if_ref[i]   := private.ref_freq[ispect];
         temp_ipol1[i]    := ipol[1];
         temp_ipol2[i]    := ipol[2];
         temp_ipol3[i]    := ipol[3];
         temp_ipol4[i]    := ipol[4];
         temp_ispect[i]   := ispect;
         temp_sub_ref[i]  := private.ref_freq[ispect];
         temp_sub_bw[i]   := private.tot_bandw[ispect];
         temp_sub_side[i] := private.net_side[ispect];
         temp_sub_nchn[i] := private.num_chan[ispect];
      }
#
#  Now add antenna information
#
      for (i in 1:private.nrows['anttable']) {
         ant_id := 0;
         ant_id := private.ant_name[i];
         result := mscs.addantenna(private.project, private.segment,
                                   private.from2000, i,
                                   private.ant_name[i], private.station[i],
                                   private.mount[i],
                                   private.dish_diam[i],private.ant_type[i],
                                   private.axis_off[3,i],'frame');
         if (is_fail(result)) {
             return throw('Failed to write row to antenna table ', 
                       result::message, origin='mscatalog');
         }
      }
#
#  Finally add observation information:
#
#
#  Find scan boundaries and only look at those
#
   private.scanbounds:=private.indexchanges(private.scan_num);
   private.last_scan_num::print.precision := 4;
#
#
#  Using private.scanbounds,  find scan boundaries and write a meta-data row.
#
      mjd_time := private.time[1]/(24.0*3600.0);
      private.last_mjd_time  := mjd_time;
      private.first_mjd_time := mjd_time;
      private.last_scan_num  := private.scan_num[1];
      scan_field_id  := private.field_id[1];
#
      ra2000  := as_double(0.0);
      dec2000 := as_double(0.0); 
      twopi   := as_double(2.0*pi);
#
#  First and last row numbers for a scan in the MS main table.
#
      scan_first_row := 1;
      scan_last_row  := private.scan_num[1];
#
#  loop steps on each row number when a scan number changes.
      last_row := 1;
      idesc := private.from2000;
      n_data_ids := 0;
      n_saved_ids := 0;
#    print "shape of private.data_id = ", shape(private.data_id);
#
      all_data_ids := array(-1,64,256);
      chk_data_ids := array(-1,256);
#--------------------------------------------------------------------------------
# Begin scan loop here.
# Each value of irow is the row number of the first row of a new scan
#
      nscans := len(private.scanbounds);
      nobs_rows := 0;
      scan_number := 0;
      print "nscans in MS = ", nscans;
      for (i in [1:nscans]) {
         irow := private.scanbounds[i];
         if (irow == 1 || i == 1)  continue;
         scan_first_row := private.scanbounds[i-1];
         scan_last_row  := private.scanbounds[i] - 1;
         scan_number    := i - 1;
#
         mjd_time := private.time[irow]/(24.0*3600.0);
         private.first_mjd_time := private.time[scan_first_row]/(24.0*3600.0);
         private.last_mjd_time  := private.time[scan_last_row]/(24.0*3600.0);
         scan_field_id          := private.field_id[scan_first_row] + 1;
#       print "scan, source, (id), first_row, last_row = ", scan_number, private.source_id[scan_field_id], scan_field_id, scan_first_row, scan_last_row;
#
# We will write out a scan row in  catalog table for the previous scan
#
         tu_1    := dq.quantity(private.first_mjd_time, 'd');
         tu_2    := dq.quantity(private.last_mjd_time, 'd');
         private.timstr1 := dq.time (tu_1, form="mjd");
         private.timstr2 := dq.time (tu_2, form="mjd");
#
         mjad    := private.ref_mjd;
#
         time_on_src := (private.last_mjd_time-private.first_mjd_time)*86400.0
                      + 0.01;
#
         uv_min := 1.0e+9;
         uv_max := 0.0;
         n_uvs  := 0;
         first_row_time := private.time[scan_first_row];
         for (jj in scan_first_row:scan_last_row) {
            if (first_row_time != private.time[jj]) break;
            if (private.uvw[1,jj] == 0.0 || private.uvw[2,jj] == 0.0)
               continue;
            uv_amp := sqrt(private.uvw[1,jj]*private.uvw[1,jj] +
                                  private.uvw[2,jj]*private.uvw[2,jj]);
            if (uv_amp > uv_max)
               uv_max := uv_amp;
            if (uv_amp < uv_min)
               uv_min := uv_amp;
            n_uvs := n_uvs + 1;
         }
         if (n_uvs == 0) {
            uv_min := 0.0;
            uv_max := 0.0;
         }
#         print "uv_range = ", uv_min, uv_max;
#
# Get a list of data_desc_id's present in this scan.
#
         scan_data_ids := unique(private.data_id[scan_first_row:scan_last_row]);
         n_ids := len(scan_data_ids); 
#       print "scan data_desc_ids = ", n_ids,  scan_data_ids;
         iexists := -1;
         if (n_saved_ids > 0) {
            for (jj in [1:n_saved_ids]) {
#              print "in exists", jj;
               n := all_data_ids[jj,1];
               if (n != n_ids) continue;
               for (k in [1:n]) {
                  chk_data_ids[k] := all_data_ids[jj,k+1];
               }
#              print n, chk_data_ids[1:n],"..", scan_data_ids[1:n_ids];
               if (chk_data_ids[1:n] == scan_data_ids[1:n]) {
#                 print "bingo";
                  iexists := 1;
                  break;
               }
            }
         }
         if (iexists == -1) {
#          print "in not exists";
            n_saved_ids := n_saved_ids + 1;
            all_data_ids[n_saved_ids,1] := n_ids;
            for (ii in [1:n_ids]) {
               all_data_ids[n_saved_ids,ii+1] := scan_data_ids[ii];
            }
            idesc := idesc + 1;
#
#          print "n_ids = ", n_ids;
#
#         change the data_desc_id values in the temporary table
#
#           print "temp_idesc = ", temp_idesc;
            for (ii in 1:private.nrows['datadesc'])    {
               for (jj in [1:n_ids]) {
                  if (scan_data_ids[jj]+1 == temp_idesc[ii])
                     temp_idesc[ii] := idesc;
                }
            }
#           print "temp_idesc = ", temp_idesc;
#           print "all_data_ids = ", all_data_ids[n_saved_ids,1:6];

         }
#
#      print "row range, n_data_id, data_ids = ", last_row,irow,n_data_id,
#             scan_data_id[1],scan_data_id[2],scan_data_id[3];
# 
# Write into the Glish catalog table
#
         obs_type := paste("TRACK");
         source_type := paste("STAR");
         frame_type := paste("ICRF");
         qual := -1;
#
         ra2000  := private.direct[1,1,scan_field_id];
         dec2000 := private.direct[2,1,scan_field_id];
#
# Convert ra2000 to radians that range over 0 to 2pi. This is for the
# sake of queries that encompass an ra range.
#
         if (ra2000 < 0.0) ra2000 := ra2000 + twopi;
#
         phase_dir[1] := ra2000;
         phase_dir[2] := dec2000;
#    
#        print "obs row = ", i, private.project, private.first_mjd_time,
#                           private.source_id[scan_field_id];
#
         result := mscs.addobservation(private.project, private.segment, 
                                       obs_type,
                                       private.first_mjd_time, 
                                       private.last_mjd_time,
                                       private.source_id[scan_field_id],
                                       source_type,
                                       private.calcode[scan_field_id],
                                       private.corr_mode,
                                       phase_dir, frame_type,
                                       private.subarray[scan_first_row],
                                       idesc, private.from2000,
                                       time_on_src, 
                                       private.avg_int[scan_first_row],
                                       uv_min, uv_max);
         if (is_fail(result)) {
            return throw('Failed to write row to obs table ', result::message,
                         origin='mscatalog');
         }
         nobs_rows := nobs_rows + 1;
#
# reset variables to the new scan values
#
         private.first_mjd_time := private.last_mjd_time;
         private.last_mjd_time  := mjd_time;
         private.last_scan_num  := private.scan_num[irow];
         private.last_field_id  := private.field_id[irow];
         private.nvis := 0;
         last_row     := irow;
#
         for (j in 1:private.maxants) {
            private.ant_count[j] := 0;
            private.desc_id[j]   := 0;
         }
#
         a1 := private.ant1[irow] + 1;
         a2 := private.ant2[irow] + 1;
         private.ant_count[a1] := 1;
         private.ant_count[a2] := 1;
         d1 := private.data_id[irow] + 1;
         private.desc_id[d1] := 1;
         private.last_mjd_time := mjd_time;
      }
#
# end of scan loop
#--------------------------------------------------------------------------------
#
      nrows := private.nrows['table'];

      scan_first_row := private.scanbounds[nscans];
      scan_last_row  := nrows;
      scan_number    := scan_number + 1;
#
      private.first_mjd_time := private.time[scan_first_row]/(24.0*3600.0);
      private.last_mjd_time  := private.time[scan_last_row]/(24.0*3600.0);
      scan_field_id          := private.field_id[scan_first_row] + 1;
#     print "scan, source, first_row, last_row = ", scan_number, private.source_id[scan_field_id], scan_first_row, scan_last_row;
#
# We will write out a scan row in  catalog table for the previous scan
#
      tu_1    := dq.quantity(private.first_mjd_time, 'd');
      tu_2    := dq.quantity(private.last_mjd_time, 'd');
      private.timstr1 := dq.time (tu_1, form="mjd");
      private.timstr2 := dq.time (tu_2, form="mjd");

      time_on_src := (private.last_mjd_time-private.first_mjd_time)*86400.0
                   + 0.01;

      uv_min := 1.0e+9;
      uv_max := 0.0;
      n_uvs  := 0;
      first_row_time := private.time[scan_first_row];
      for (jj in scan_first_row:scan_last_row) {
         if (first_row_time != private.time[jj]) break;
         if (private.uvw[1,jj] == 0.0 || private.uvw[2,jj] == 0.0)
            continue;
         uv_amp := sqrt(private.uvw[1,jj]*private.uvw[1,jj] +
                               private.uvw[2,jj]*private.uvw[2,jj]);
         if (uv_amp > uv_max)
            uv_max := uv_amp;
         if (uv_amp < uv_min)
            uv_min := uv_amp;
         n_uvs := n_uvs + 1;
      }
      if (n_uvs == 0) {
         uv_min := 0.0;
         uv_max := 0.0;
      }
#
# Get a list of data_desc_id's present in this scan.
#
      scan_data_ids := unique(private.data_id[scan_first_row:scan_last_row]);
      n_ids := len(scan_data_ids); 
#       print "scan data_desc_ids = ", n_ids,  scan_data_ids;
      iexists := -1;
      if (n_saved_ids > 0) {
         for (jj in [1:n_saved_ids]) {
#            print "in exists", jj;
            n := all_data_ids[jj,1];
            if (n != n_ids) continue;
            for (k in [1:n]) {
               chk_data_ids[k] := all_data_ids[jj,k+1];
            }
#            print n, chk_data_ids[1:n],"..", scan_data_ids[1:n_ids];
            if (chk_data_ids[1:n] == scan_data_ids[1:n]) {
               iexists := 1;
                break;
            }
         }
      }
      if (iexists == -1) {
#          print "in not exists";
         n_saved_ids := n_saved_ids + 1;
         all_data_ids[n_saved_ids,1] := n_ids;
         for (ii in [1:n_ids]) {
            all_data_ids[n_saved_ids,ii+1] := scan_data_ids[ii];
         }
         idesc := idesc + 1;
#
#          print "n_ids = ", n_ids;
#
#         change the data_desc_id values in the temporary table
#
#          print "temp_idesc = ", temp_idesc;
         for (ii in 1:private.nrows['datadesc'])    {
            for (jj in [1:n_ids]) {
               if (scan_data_ids[jj]+1 == temp_idesc[ii])
                  temp_idesc[ii] := idesc;
            }
         }
#          print "temp_idesc = ", temp_idesc;
#          print "all_data_ids = ", all_data_ids[n_saved_ids,1:6];

      }
#
      obs_type := paste("TRACK");
      source_type := paste("STAR");
      frame_type := paste("ICRF");
      qual := -1;
#
      ra2000  := private.direct[1,1,scan_field_id];
      dec2000 := private.direct[2,1,scan_field_id];
#
# Convert ra2000 to radians that range over 0 to 2pi. This is for the
# sake of queries that encompass an ra range.
#
      if (ra2000 < 0.0) ra2000 := ra2000 + twopi;
#
      phase_dir[1] := ra2000;
      phase_dir[2] := dec2000;
# 
# Don't forget the last scan in the MS. Have to pick it up here.
#
     result := mscs.addobservation(private.project,  private.segment, 
                                   obs_type,
                                   private.first_mjd_time, 
                                   private.last_mjd_time,
                                   private.source_id[scan_field_id],
                                   source_type,
                                   private.calcode[scan_field_id],
                                   private.corr_mode,
                                   phase_dir,
                                   frame_type,
                                   private.subarray[scan_first_row],
                                   idesc, private.from2000,
                                   time_on_src, 
                                   private.avg_int[scan_first_row],
                                   uv_min, uv_max);
      if (is_fail(result)) {
         return throw('Failed to write row to obs table ', result::message, 
                      origin='mscatalog');
      }
      nobs_rows := nobs_rows + 1;

      for (i in 1:private.nrows['datadesc']) {
         ipol[1] := temp_ipol1[i];
         ipol[2] := temp_ipol2[i];
         ipol[3] := temp_ipol3[i];
         ipol[4] := temp_ipol4[i];
         result := mscs.adddatadesc(temp_project[i], temp_segment[i], 
                                    temp_from2000[i], temp_idesc[i], 
                                    temp_if_band[i], temp_ircvr[i],
                                    temp_if_ref[i], ipol, temp_ispect[i],
                                    temp_sub_ref[i], temp_sub_bw[i],
                                    temp_sub_side[i], temp_sub_nchn[i]);
         if (is_fail(result)) {
            return throw('Failed to write row to datadesc table ', 
                         result::message, origin='mscatalog');
         }
      }

#
# Everything is now written
#
      note('Added nrows = ',nobs_rows,
           ' to AIPS++ Observation catalog table, catalog name = ', 
           private.catalogname, origin='mscatalog.writetable');
#
      mscs.done();

      return T;
   }
#
# End of public.write function
#----------------------------------------------------------------------------
#
#  Public function to fill the SCAN_NUMBER column
#
   public.makeindex := function() {
      wider private;
#
      scan_num:=private.table.getcol('SCAN_NUMBER');
      field_id:=private.table.getcol('FIELD_ID');
      data_id :=private.table.getcol('DATA_DESC_ID');
      subarray:=private.table.getcol('ARRAY_ID');
#
      nrows := len(scan_num);
#
      last_scan_num :=  1;
      last_field_id := field_id[1];
      last_data_id  := data_id[1];
      last_subarray := subarray[1];
#
      irow := 1;
      note("Making index, nrows = ", nrows, origin='mscatalog.makeindex');
      note('Row ', irow, ' new scan number : ', last_scan_num, 
           origin='mscatalog.makeindex');

      for (irow in 1:nrows) {
         if (last_field_id != field_id[irow] ||
            last_subarray != subarray[irow]) {
            last_scan_num := last_scan_num + 1;
            last_field_id := field_id[irow];
            last_data_id  := data_id[irow];
            last_subarray := subarray[irow];
            note('Row ', irow, ' new scan number : ', last_scan_num, 
                 origin='mscatalog.makeindex');
         }
         scan_num[irow] := last_scan_num;
      }
      ok := private.table.putcol ('SCAN_NUMBER', scan_num);
#
      return T;
   }
#
#----------------------------------------------------------------------------
#
# Type identification for toolmanager, etc.
#
   public.type := function() {
      return "mscatalogserver";
   }


   public.done := function() {
      return T;
   }

   return ref public;
}
# End of mscatalog function 
#----------------------------------------------------------------------------
#
tmscatalog := function() {
   include 'table.g';
   if (!tableexists('3C273XC1.ms')) {
      include 'imager.g';
      imagermaketestms();
   }
   msc:=mscatalog('3C273XC1.ms');
   msc.makeindex();
   msc.write('tables');
   msc.done();
}



