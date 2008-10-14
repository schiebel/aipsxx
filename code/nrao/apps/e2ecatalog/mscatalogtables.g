# mscatalogserver: Define and manipulate ms catalogs
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
#   $Id: mscatalogtables.g,v 19.0 2003/07/16 03:44:34 aips2adm Exp $
#
#----------------------------------------------------------------------------

pragma include once;

include 'table.g';

# 
# Works as a server for mscatalog. All the information about the
# structure and access to the archive tables is kept here. The
# public interface is a set of function addarchive, addantenna, etc
# that write a row to the relevant table.
#
# The archive tables are either opened on construction or created
# on construction. 
#
# To-do:
#   - encapsulation of access
#

mscatalogtables := function(name='MSCATALOG', nrows=0) {

   private := [=];
   public  := [=];

#
#  Generic write-a-row function: This could be made faster by using tablerow
#  or by caching column updates
#
   private.writerow := function(rec, type) {
      wider private;

      oldway := 0;

      if (oldway == 1) {
         private.tables[type].addrows(1);
         rownr := private.tables[type].nrows();
         for (field in field_names(rec)) {
            private.tables[type].putcell(field, rownr, rec[field]);
         }
         new_row := rownr;
      }
      else {
         last_row := private.tables[type].getkeyword('last_row');
         new_row  := last_row + 1;
         nrows    := private.tables[type].getkeyword('nrows');

         if (new_row > nrows) {
            private.tables[type].addrows(1000);
            nrows := nrows + 1000;
            private.tables[type].putkeyword("nrows",  as_integer(nrows));
            print "adding 1000 rows to table : ", type;
         }

         private.tblrow[type].put(rownr=new_row, value=rec, matchingfields=T);
         private.tables[type].putkeyword('last_row', as_integer(new_row));
      }

      return new_row;
   }
    
   private.PROJECT := function() {
      td:=tablecreatedesc(tablecreatescalarcoldesc('PROJECT_CODE', 'AB123', maxlen=16), 
         tablecreatescalarcoldesc('SEGMENT',  ' ',     maxlen=4),
			tablecreatescalarcoldesc('OBSERVER', 'REBER', maxlen=24),
			tablecreatescalarcoldesc('OBSERVER_ID', 513),
			tablecreatescalarcoldesc('FIRSTTIME', as_double(53000.0100),
                          comment='Modified Julian Day'), 
			tablecreatescalarcoldesc('LASTTIME', as_double(53000.1000),
                          comment='Modified Julian Day'), 
         tablecreatescalarcoldesc('PROPRIETARY', as_double(53000.01),
                          comment='Proprietary period expires, Modified Julian Day'),
			tablecreatescalarcoldesc('TELESCOPE', 'VLA', maxlen=12),
			tablecreatescalarcoldesc('TELESCOPE_CONFIG', 'A', maxlen=8),
			tablecreatescalarcoldesc('OBS_BANDS', '', maxlen=16),
			tablecreatescalarcoldesc('TOTAL_OBS_TIME', as_float(1.0),
                          comment='Total observing time'),
			tablecreatescalarcoldesc('NUM_SEGMENTS', 1),
			tablecreatescalarcoldesc('ARCH_FILES', 1),
                        tablecreatescalarcoldesc('ROW_DATE', as_double(53010.4567)));
      return td;
   }
   private.PROJECTkeys := function(tabl) {
      keywrd_rec := [
         FIRSTTIME =[QuantumUnits=['d'],MEASINFO=[type='epoch',Ref='TAI']],
         LASTTIME  =[QuantumUnits=['d'],MEASINFO=[type='epoch',Ref='TAI']],
         PROPRIETARY =[QuantumUnits=['d'],MEASINFO=[type='epoch',Ref='TAI']]];
#
      for (key_field in field_names(keywrd_rec)) {
         kw := keywrd_rec[key_field];
         tk := tabl.putcolkeywords(columnname=key_field, value=keywrd_rec[key_field]);
      }
      return tk;
   }
   public.addproject := function(project_code, segment, observer, observer_id, 
                                 firsttime, lasttime, end_proprietary_period, 
                                 telescope, telescope_config, obs_bands,
                                 obs_time, num_segments, 
                                 arch_files,row_date) {
      wider private, public;
      rec := [PROJECT_CODE=as_string(project_code),
              SEGMENT=as_string(segment),
              OBSERVER=as_string(observer),
              OBSERVER_ID=as_integer(observer_id),
              FIRSTTIME=as_double(firsttime), LASTTIME=as_double(lasttime),
              PROPRIETARY=as_double(end_proprietary_period),
              TELESCOPE=as_string(telescope), 
              TELESCOPE_CONFIG=as_string(telescope_config),
              OBS_BANDS=as_string(obs_bands),
              TOTAL_OBS_TIME=as_float(obs_time), 
              NUM_SEGMENTS=as_integer(num_segments),
              ARCH_FILES=as_integer(arch_files), ROW_DATE=as_double(row_date)];
      type:='PROJECT';
      return private.writerow(rec, type);
   }

   private.ARCHIVE := function() {
      td:=tablecreatedesc(
         tablecreatescalarcoldesc('PROJECT_CODE', 'AB123', maxlen=16), 
         tablecreatescalarcoldesc('SEGMENT',  ' ',     maxlen=4),
         tablecreatescalarcoldesc('STARTTIME', as_double(53000.0100),
                          comment='Modified Julian Day'), 
         tablecreatescalarcoldesc('STOPTIME', as_double(53000.1000),
                          comment='Modified Julian Day'), 
         tablecreatescalarcoldesc('TELESCOPE', 'VLA', maxlen=12),
         tablecreatescalarcoldesc('TELESCOPE_CONFIG', 'A', maxlen=8),
         tablecreatescalarcoldesc('ARCH_FORMAT', 'VLAExport', maxlen=8),
         tablecreatescalarcoldesc('DATA_TYPE', 'raw', maxlen=12),
         tablecreatescalarcoldesc('SUBARRAY_ID', as_integer(1)),
         tablecreatescalarcoldesc('ARCH_FILE_ID', as_integer(123456789)),
         tablecreatescalarcoldesc('ARCH_FILE', '/home/archive/vla/TP5698', maxlen=64),
         tablecreatescalarcoldesc('ARCH_FILE_DATE', as_double(53000.1234)),
         tablecreatescalarcoldesc('CATALOG_DATE', as_double(53010.4567)));
      return td;
   }
   private.ARCHIVEkeys := function(tabl) {
      keywrd_rec := [
         STARTTIME=[QuantumUnits=['d'],MEASINFO=[type='epoch',Ref='TAI']],
         STOPTIME =[QuantumUnits=['d'],MEASINFO=[type='epoch',Ref='TAI']]];
#
      for (key_field in field_names(keywrd_rec)) {
         kw := keywrd_rec[key_field];
         tk := tabl.putcolkeywords(columnname=key_field, value=keywrd_rec[key_field]);
      }
      return tk;
   }
   public.addarchive := function(project_code, segment, starttime,
                                 stoptime, telescope, telescope_config, 
                                 arch_format, data_type, subarray_id,
                                 arch_file_id, arch_file, arch_file_date, 
                                 catalog_date) {
      wider private, public;
      rec := [PROJECT_CODE=as_string(project_code),SEGMENT=as_string(segment),
	          STARTTIME=as_double(starttime), STOPTIME=as_double(stoptime),
	          TELESCOPE=as_string(telescope), 
             TELESCOPE_CONFIG=as_string(telescope_config),
	          ARCH_FORMAT=as_string(arch_format), DATA_TYPE=as_string(data_type),
             SUBARRAY_ID=as_integer(subarray_id),
	          ARCH_FILE_ID=as_integer(arch_file_id),
             ARCH_FILE=as_string(arch_file),
	          ARCH_FILE_DATE=as_double(arch_file_date), 
             CATALOG_DATE=as_double(catalog_date)];
      type:='ARCHIVE';
      return private.writerow(rec, type);
   }

   private.OBSERVATION := function() {
      td:=tablecreatedesc(
         tablecreatescalarcoldesc('PROJECT_CODE', 'AB123', maxlen=16), 
			tablecreatescalarcoldesc('SEGMENT',  ' ', maxlen=4), 
			tablecreatescalarcoldesc('OBS_TYPE', 'STAR', maxlen=10), 
			tablecreatescalarcoldesc('STARTTIME', as_double(53000.010),
                          comment='Modified Julian Day'), 
			tablecreatescalarcoldesc('STOPTIME',  as_double(53000.200),
                          comment='Modified Julian Day'),
			tablecreatescalarcoldesc('SOURCE_ID', '3C449', maxlen=16),
			tablecreatescalarcoldesc('SOURCE_TYPE', 'mosaic', maxlen=8),
			tablecreatescalarcoldesc('CALIB_TYPE', 'flux', maxlen=8),
         tablecreatescalarcoldesc('CORR_MODE',  '?', maxlen=6),
			tablecreatearraycoldesc ('CENTER_DIR', as_double(pi),1,[2],
                          comment='Direction of field center (RA, Dec)'),
			tablecreatescalarcoldesc('FRAME', 'ICRF', maxlen=20),
			tablecreatescalarcoldesc('SUBARRAY_ID',as_integer(127)),
			tablecreatescalarcoldesc('DATA_DESC_ID',as_integer(127)),
			tablecreatescalarcoldesc('ARCH_FILE_ID', 123456789),
			tablecreatescalarcoldesc('EXPOSURE', as_float(24.0*3600.0)),
			tablecreatescalarcoldesc('INTERVAL', as_float(24.0*3600.0)),
			tablecreatescalarcoldesc('UV_MIN', as_float(1000.0)),
			tablecreatescalarcoldesc('UV_MAX', as_float(1000.0)));
      return td;
   }
   private.OBSERVATIONkeys := function(tabl) {
      keywrd_rec := [
         STARTTIME=[QuantumUnits=['d'],MEASINFO=[type='epoch',Ref='TAI']],
         STOPTIME =[QuantumUnits=['d'],MEASINFO=[type='epoch',Ref='TAI']],
         CENTER_DIR=[QuantumUnits=['rad','rad'],MEASINFO=[type='direction',
                     Ref='J2000']]];
#
      for (key_field in field_names(keywrd_rec)) {
         kw := keywrd_rec[key_field];
         tk := tabl.putcolkeywords(columnname=key_field, value=keywrd_rec[key_field]);
      }
      return tk;
   }

   public.addobservation := function(project_code, segment, 
                                     obs_type, starttime, stoptime,
                                     source_id,
                                     source_type, calib_type, corr_mode, 
                                     center_dir, frame, subarray_id, data_desc_id,
                                     arch_file_id, exposure, interval, uv_min, 
                                     uv_max) {
      wider private, public;
      rec := [PROJECT_CODE=as_string(project_code), SEGMENT=as_string(segment),
              OBS_TYPE=as_string(obs_type), 
              STARTTIME=as_double(starttime), STOPTIME=as_double(stoptime),
	           SOURCE_ID=as_string(source_id), SOURCE_TYPE=as_string(source_type), 
              CALIB_TYPE=as_string(calib_type), CORR_MODE=as_string(corr_mode),
	           CENTER_DIR=as_double(center_dir), FRAME=as_string(frame),
	           SUBARRAY_ID=as_integer(subarray_id), 
              DATA_DESC_ID=as_integer(data_desc_id), 
              ARCH_FILE_ID=as_integer(arch_file_id), 
              EXPOSURE=as_float(exposure), INTERVAL=as_float(interval),
              UV_MIN=as_float(uv_min), UV_MAX=as_float(uv_max)];
      type:='OBSERVATION';
      return private.writerow(rec, type);
   }

   private.ANTENNA := function() {
      td:=tablecreatedesc(
         tablecreatescalarcoldesc('PROJECT_CODE', 'AB123', maxlen=16), 
			tablecreatescalarcoldesc('SEGMENT', ' ', maxlen=4),
			tablecreatescalarcoldesc('ARCH_FILE_ID', as_integer(123456789)),
			tablecreatescalarcoldesc('ANTENNA_ID', as_integer(257)),
			tablecreatescalarcoldesc('NAME', 'VLA_10',maxlen=12),
			tablecreatescalarcoldesc('STATION', 'VLA:W48',maxlen=12),
			tablecreatescalarcoldesc('MOUNT', 'alt-az',maxlen=8),
			tablecreatescalarcoldesc('DISH_DIAMETER', as_float(25.0)),
			tablecreatescalarcoldesc('ANTENNA_TYPE', 'GRND',maxlen=8),
			tablecreatescalarcoldesc('AXIS_OFF', as_float(0.145)),
			tablecreatescalarcoldesc('FRAME', 'ITRF',maxlen=12));
      return td;
   }
   public.addantenna := function(project_code, segment, 
                                 arch_file_id, antenna_id, name, 
                                 station, mount, dish_diameter,
                                 antenna_type, axis_off, frame) {
      wider private, public;
      rec := [PROJECT_CODE=as_string(project_code), SEGMENT=as_string(segment), 
              ARCH_FILE_ID=as_integer(arch_file_id), 
              ANTENNA_ID=as_integer(antenna_id),
              NAME=as_string(name), STATION=as_string(station),
              MOUNT=as_string(mount), DISH_DIAMETER=as_float(dish_diameter), 
              ANTENNA_TYPE=as_string(antenna_type), AXIS_OFF=as_float(axis_off), 
              FRAME=as_string(frame)];
      type:='ANTENNA';
      return private.writerow(rec, type);
   }

   private.DATADESC := function() {
      td:=tablecreatedesc(
         tablecreatescalarcoldesc('PROJECT_CODE', 'AB123', maxlen=16), 
			tablecreatescalarcoldesc('SEGMENT', ' ', maxlen=4),
			tablecreatescalarcoldesc('ARCH_FILE_ID', as_integer(123)),
			tablecreatescalarcoldesc('DATA_DESC_ID', as_integer(123)),
			tablecreatescalarcoldesc('IF_BAND', 'C', maxlen=4),
			tablecreatescalarcoldesc('RECEIVER_ID', as_integer(127)),
			tablecreatescalarcoldesc('IF_REF_FREQ', as_double(1.0e9)),
			tablecreatearraycoldesc ('POL', 1, 1, [4]),
			tablecreatescalarcoldesc('SUB_CHAN_ID', as_integer(127)),
			tablecreatescalarcoldesc('SUB_REF_FREQ', as_double(1.0E9)),
			tablecreatescalarcoldesc('SUB_BANDW', as_double(1.0E9)),
			tablecreatescalarcoldesc('SUB_NET_SIDEBAND', as_short(1)),
			tablecreatescalarcoldesc('SUB_NUM_CHANS', as_integer(127)));
      return td;
   }

   public.adddatadesc := function(project_code, segment, arch_file_id,
                                  data_desc_id, if_band, receiver_id,
                                  if_ref_freq, pol, sub_chan_id, sub_ref_freq,
                                  sub_bandw, sub_net_sideband, sub_num_chans) {
      wider private, public;
      rec := [PROJECT_CODE=as_string(project_code), SEGMENT=as_string(segment),
              ARCH_FILE_ID=as_integer(arch_file_id),
              DATA_DESC_ID=as_integer(data_desc_id), IF_BAND=as_string(if_band),
              RECEIVER_ID=as_integer(receiver_id), IF_REF_FREQ=as_double(if_ref_freq),
              POL=as_integer(pol), 
              SUB_CHAN_ID=as_integer(sub_chan_id),
              SUB_REF_FREQ=as_double(sub_ref_freq), SUB_BANDW=as_double(sub_bandw), 
              SUB_NET_SIDEBAND=as_short(sub_net_sideband),
              SUB_NUM_CHANS=as_integer(sub_num_chans)];
      type:='DATADESC';
      return private.writerow(rec, type);
   }
   private.SUBARRAY := function() {
      td:=tablecreatedesc(
         tablecreatescalarcoldesc('PROJECT_CODE', 'AB123', maxlen=16), 
			tablecreatescalarcoldesc('SEGMENT', ' ', maxlen=4),
			tablecreatescalarcoldesc('STARTTIME', as_double(53000.010)), 
			tablecreatescalarcoldesc('STOPTIME', as_double(53000.100)), 
			tablecreatescalarcoldesc('SUBARRAY_ID', as_integer(257)),
			tablecreatescalarcoldesc('ANTENNA_ID', as_integer(257)));
      return td;
   }

   public.addsubarray := function(project_code, segment, starttime, stoptime, 
                                  subarray_id, antenna_id) {
      wider private, public;
      rec := [PROJECT_CODE=as_string(project_code), SEGMENT=as_string(segment), 
              STARTIME=as_double(starttime), STOPTIME=as_double(stoptime),
              SUBARRAY_ID=as_integer(subarray_id), ANTENNA_ID=as_integer(antenna_id)];
      type:='SUBARRAY';
      return private.writerow(rec, type);
   }
#
# Now create the tables if they don't exist already
#
# Check the main table first.
#
   for (field in "PROJECT ARCHIVE OBSERVATION ANTENNA DATADESC SUBARRAY") {
      if (field == 'PROJECT') {
         tablename := spaste(name);
      }
      else {
         tablename := spaste(name, '/', field);
      }
      if (!tableexists(tablename)) {
         tab := table(tablename, private[field](), nrows, ack=F);
         if (!is_table(tab)) {
	         return throw('Failed to create subtable ', tablename, 
                         origin='mscatalogserver.create');
         }
         if (field == "ARCHIVE" || field == " OBSERVATION" || field == "PROJECT") { 
#           print "write keys : ", field; 
            private[spaste(field,'keys')](tab);
         }
         tab.putkeyword("last_row", as_integer(0));
         tab.putkeyword("nrows", as_integer(1000));
         tab.addrows(1000);
         tab.close();
      }
   }
#
#  Now re-open for read/write
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
      private.tblrow[field] := tablerow(private.tables[field]);
   }
#
#  Cross add keywords pointing to all tables for convenience when browsing
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
# Type identification for toolmanager, etc.
#
   public.type := function() {
      return "mscatalogtables";
   }
#
# Done function
#
   public.done := function() {
      wider private, public;
#
# Close all tables
#
      for (field in "ARCHIVE OBSERVATION PROJECT ANTENNA DATADESC SUBARRAY") {
         private.tables[field].close();
         private.tblrow[field].close();
      }
      return T;
   }

   return ref public;
}


