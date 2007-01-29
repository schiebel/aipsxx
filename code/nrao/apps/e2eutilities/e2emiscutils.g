# e2emiscutils: useful utilities for e2e imaging
# Copyright (C) 1999,2000,2001,2002
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
# $Id: e2emiscutils.g,v 19.0 2003/07/16 03:45:01 aips2adm Exp $

pragma include once;

e2emiscutils := function() {

  public := [=];
  private := [=];

  public.badarchivefiles:=function(telescope='VLA') {
    wider private, public;
    if(is_string(environ.E2EROOT)) {
      private.e2edir := spaste(environ.E2EROOT, '/');
    }
    else {
      private.e2edir := './';
    }

    private.tapes := spaste(private.e2edir, '/defects/vlafiller/') ~ s!//!/!g;
    private.dir := spaste(private.e2edir, '/archive/data/', telescope, '/tapes/') ~ s!//!/!g;

    include 'catalog.g';
    tapes := dc.list(private.tapes, strippath=T);
    archfiles := '';
    i := 0;
    for (tapedir in tapes) {
      files := dc.list(spaste(private.tapes, '/', tapedir), strippath=T);
      for (file in files) {
	i+:=1;
	archfiles[i] := spaste(private.dir, '/', tapedir, '/', file) ~ s!//!/!g;
      }
    }
    return archfiles;
  }
    
  public.debug := ref private;

  return ref public;
}
  
  
  
  
  
  
  
  
  
  
  
  
