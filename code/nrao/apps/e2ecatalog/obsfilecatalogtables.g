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
#   $Id: obsfilecatalogtables.g,v 19.0 2003/07/16 03:44:38 aips2adm Exp $
#
#----------------------------------------------------------------------------

pragma include once;

include 'table.g'

# 
obsfilecatalogtables := function(name='OBSCATALOG', nrows=0) {

  private := [=];
  public  := [=];

#
# Generic write-a-row function: This could be made faster by using tablerow
# or by caching column updates
#
  private.writerow := function(rec, type) {
    wider private;
    private.tables[type].addrows(1);
    rownr := private.tables[type].nrows();
    for (field in field_names(rec)) {
      private.tables[type].putcell(field, rownr, rec[field]);
    }
    return rownr;
  }

  private.obsfiles := function() {
    td:=tablecreatedesc(tablecreatescalarcoldesc('PROJECT_CODE', 'AB123', maxlen=8), 
			tablecreatescalarcoldesc('OBSERVER_ID', 100), 
			tablecreatescalarcoldesc('OBSERVER', 'UNKNOWN', maxlen=36),
			tablecreatescalarcoldesc('STARTTIME', 4e9), 
                        tablecreatescalarcoldesc('STOPTIME', 4e9),
			tablecreatescalarcoldesc('DIRECTORY', 'UNKNOWN', maxlen=48),
			tablecreatescalarcoldesc('FILENAME', '123A456.OBS', maxlen=20));
    return td;
  }

  public.addobsfile := function(project_code, observer_id, observer, starttime,
                                stoptime, directory, filename) {
    wider private, public;
    rec := [PROJECT_CODE=project_code, OBSERVER_ID=observer_id, 
            OBSERVER=observer, STARTTIME=starttime, STOPTIME=stoptime,
            DIRECTORY=directory, FILENAME=filename];
    type:='obsfiles';
    return private.writerow(rec, type);
  }
#
# Now create the tables if they don't exist already
#
  for (field in "obsfiles") {
    tablename := spaste(name, '.', field);
    if(!tableexists(tablename)) {
      tab := table(tablename, private[field](), nrows, ack=F);
      if(!is_table(tab)) {
	return throw('Failed to create subtable ', subname, origin='obsfilecatalogserver.create');
      }
      tab.close();
    }
  }
#
# Now re-open for read/write
#
  private.tables := [=];
  private.tables['obsfiles'] := table(name, ack=F, readonly=F);
  for (field in "obsfiles") {
    tablename := spaste(name, '.', field);
    private.tables[field] := table(tablename, ack=F, readonly=F);
  }
#
# Cross add keywords pointing to all tables for convenience when browsing
#
#  for (field in "archive observation antenna datadesc subarray") {
#    for (otable in "archive observation antenna datadesc subarray") {
#      tablename := spaste(name, '.', otable);
#      private.tables[field].putkeyword(to_upper(otable), tablename);
#    }
#  }
#
# Type identification for toolmanager, etc.
#
  public.type := function() {
    return "obsfilecatalogtables";
  }
#
# Done function
#
  public.done := function() {
    wider private, public;
#
# Close all tables
#
    for (field in "obsfiles") {
      private.tables[field].close();
    }
    return T;
  }

  return ref public;
}


