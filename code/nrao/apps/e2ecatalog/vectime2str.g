# vectime2str.g : render internal representations into human readable string
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
#   $Id: vectime2str.g,v 19.0 2003/07/16 03:44:40 aips2adm Exp $
#
#----------------------------------------------------------------------------
#
pragma include once

include 'tables.g';
include 'quanta.g';

vectime2str := function(vecdata) {

  ndatarows := length(vecdata);

  dq.setformat('dtime', 'utc');

  vecmeas    := dq.quantity(vecdata, 'd');
  vecdisplay := dq.form.dtime(vecmeas, showform=T); 

  return vecdisplay;
}
vecra2str := function(center_dir) {

  ndatarows := length(center_dir)/2;
#  print "nrarows = ", ndatarows;

  dq.setformat('long', 'hms');

  for (i in 1:ndatarows) {
     vecdata[i] := center_dir[1,i];
  }

  vecmeas   := dq.quantity(vecdata, 'rad');
  vecdisplay := dq.form.long(vecmeas, showform=T); 

  return vecdisplay;
}
vecdec2str := function(center_dir) {

  ndatarows := length(center_dir)/2;
#  print "ndecrows = ", ndatarows;

  dq.setformat('lat', 'dms');

  for (i in 1:ndatarows) {
     vecdata[i] := center_dir[2,i];
  }

  vecmeas   := dq.quantity(vecdata, 'rad');
  vecdisplay := dq.form.lat(vecmeas, showform=T); 

  return vecdisplay;
}
