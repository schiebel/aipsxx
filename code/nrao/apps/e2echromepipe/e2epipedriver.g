# e2epipedriver.g:
#
# Time-stamp: <2002-04-05 02:20:59 bwaters>

# Copyright (C) 2002
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

pragma include once;
pragma shared user;

include 'e2equery.g';

pipe:=client('e2echromepipe', 7003);

e2eq := e2equery();
whenever pipe->cgi do {
  html :=  e2eq.perform_query($value, spaste(environ.E2EROOT, '/archive/catalogs/VLA/SUMCATALOG'));
  pipe->xml(html);
}

whenever system->exit do {
  print "Killing e2echromepipe";
  pipe := F;
}

