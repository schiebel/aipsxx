# mscatalogsql: Define and manipulate ms catalogs
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
#   $Id: mscatalogsql.g,v 19.0 2003/07/16 03:44:35 aips2adm Exp $
#
#----------------------------------------------------------------------------

pragma include once;

include 'table.g'

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

mscatalogsql := function(name='MSCATALOG', nrows=0) {

  private := [=];
  public  := [=];

  public.addarchive := function(project_code, observer, observer_id, starttime, stoptime,
				telescope, telescope_config, arch_format, data_type, qual,
				arch_file_id, arch_file, arch_file_date) {
# observer_id not written
    wider private, public;
    arch_dir:='';
    format := 'insert into arch_files\n(project_code,observer,starttime,stoptime,telescope,telescope_config,arch_format,data_type,qual,arch_file_id,arch_dir,arch_file,arch_date)\nvalues\n(\'%s\',\'%s\',\'%s\',\'%s\',\'%s\',\'%s\',\'%s\',\'%s\',%d,%d,\'%s\',\'%s\',\'%s\');\n';
    starttime:=as_string(starttime);
    stoptime:=as_string(stoptime);
    return fprintf(private.fout, format, project_code, observer, starttime, stoptime,
		   telescope, telescope_config, arch_format, data_type, qual,
		   arch_file_id, arch_dir, arch_file, arch_file_date);
  }

  public.addobservation := function(project_code, obs_type, starttime, stoptime, source_id,
				    source_type, calib_type, ra2000, dec2000, frame,
				    subarray_id, data_desc_id, arch_file_id, exposure, interval, uv_min, uv_max, qual=0) {
    wider private, public;
    format:='insert into observations\n(project_code,obs_type,starttime,stoptime,source_id,source_type,calib_type,ra2000,dec2000,frame,subarray_id,data_desc_id,arch_file_id,exposure,int_time,uv_min,uv_max,qual)\nvalues\n(\'%s\',\'%s\',%12.5f,%12.5f,\'%s\',\'%s\',\'%s\',%18.14f,%18.14f,\'%s\',%d,%d,%d,%10.5f,%10.5f,%12.5e,%12.5e,%d);\n';
#    starttime:=as_string(starttime);
#    stoptime:=as_string(stoptime);
    return fprintf(private.fout, format, project_code, obs_type, starttime, stoptime, source_id,
	    source_type, calib_type, ra2000, dec2000, frame,
	    subarray_id, data_desc_id, arch_file_id, exposure, interval, uv_min, uv_max, qual=0);
  }
  public.addantenna := function(project_code, arch_file_id, antenna_id, name, station, mount,
				dish_diameter, antenna_type, axis_off, frame) {
    wider private, public;
    format:='insert into antennas\n(project_code,arch_file_id,antenna_id,name,station,mount,diameter,type,axis_off,frame)\nvalues\n(\'%s\',%d,%d,\'%s\',\'%s\',\'%s\',%7.2f,\'%s\',%9.5f,\'%s\');\n';
    return fprintf(private.fout, format, project_code, arch_file_id, antenna_id, name, station, mount,
	    dish_diameter, antenna_type, axis_off, frame);
  }

  public.adddatadesc := function(project_code, arch_file_id, data_desc_id, if_band, receiver_id,
				if_ref_freq, pol, sub_chan_id, sub_ref_freq, sub_bandw,
				sub_net_sideband, sub_num_chans, row_entry_time, qual=0) {
    wider private, public;
    format:='insert into datadesc\n(project_code,data_desc_id,arch_file_id,IF_band,rcvr_id,IF_ref_freq,pol1,pol2,pol3,pol4,sb_chan_id,sb_ref_freq,sb_bandw,sb_net_sideband,sb_num_chans,row_entry_time,qual)\nvalues\n(\'%s\',%d,%d,\'%s\',%d,%20.14e,%d,%d,%d,%d,%d,%20.14e,%16.8e,%d,%d,\'%s\',%d);\n';
    return fprintf(private.fout, format, project_code, data_desc_id, arch_file_id,
            if_band,
	    receiver_id, if_ref_freq, pol[1], pol[2], pol[3], pol[4],
	    sub_chan_id, sub_ref_freq, sub_bandw,
	    sub_net_sideband, sub_num_chans, row_entry_time, qual=0);
  }
  public.addsubarray := function(project_code, starttime, stoptime, subarray_id, antenna_id) {
    wider private, public;
    format:='insert into subarray\n(project_code,starttime,stoptime,subarray_id,antenna_id)\nvalues\n(\'%s\',\'%s\',\'%s\',%d,%d);\n';
    print format;
    return fprintf(private.fout, format, project_code, starttime, stoptime, subarray_id, antenna_id);
  }

  private.outsql     := spaste(name,'.sql');
  note('Output SQL file name = ', private.outsql, origin='mscatalog');
  private.fout := open (spaste('>', private.outsql));
  if(is_fail(private.fout)) return throw('Could not open ', private.outsql,
				 ' for writing:  ', private.fout::message);
#
# Type identification for toolmanager, etc.
#
  public.type := function() {
    return "mscatalogsql";
  }
#
# Done function
#
  public.done := function() {
    wider private, public;
    private.fout := F;
    return T;
  }

  return ref public;
}

