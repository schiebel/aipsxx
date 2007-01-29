# e2epipelinequery: Queries for pipeline processing
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: e2ecatalogloader.g,v 19.0 2003/07/16 03:44:47 aips2adm Exp $
#

pragma include once;

e2ecatalogloader := function(catalogname='MSCATALOG') {
  
  public := [=];
  private := [=];
  
  include 'e2epipelinequery.g';
  private.pq := e2epipelinequery();

  private.load:=function(msname, filename, telescopename) {
    wider private, public;
    if(telescopename=='VLA') {
      include 'vlafiller.g';
      return vlafillerfromdisk(msname=msname, filename=filename, async=F);
    }
    else {
      return throw('Cannot yet load data from ', telescopename);
    }
  }

  public.load :=function(telescopename='VLA') {
    wider private, public;

    telescopename := 'VLA';
    private.data    := spaste('/users/e2emgr/e2e/archive/data/', telescopename, '/tapes') ~ s!//!/!g;
    if(has_field(environ, 'E2EROOT')) {
      private.data    := spaste(environ.E2EROOT, '/archive/data/', telescopename, '/tapes') ~ s!//!/!g;
    }
#
# Find all archive files now in MSCATALOG
#
    loadednames := private.pq.getallarchfiles(telescopename);
#
# Find all data files and check against loaded files
#
    include 'catalog.g';
    include 'mscatalog.g';
    dirnames := dc.list(private.data, strippath=F);
    for (dir in dirnames) {
      if(dc.whatis(dir).type=='Directory') {
	filenames := dc.list(dir, strippath=F);
	for (file in filenames) {
	  if(!any(file==loadednames)) {
	    print "Loading file", file;
	    msname := spaste(file, '.ms');
	    if(private.load(msname, file, telescopename)) mscatalog(msname, archfilename=file);
	  }
	}
      }
    }
    return T;
  }
  
  public.type := function() {
    return "e2evlaloader";
  }

  public.done := function() {
    wider private, public;
    return T;
  }

  return public;
}
