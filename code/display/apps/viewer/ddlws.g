# viewer.g: AIPS++ Display library widget server
# Copyright (C) 1999,2000,2001
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

include 'gdisplay.g';
include 'widgetserver.g';
# create a gtk client for the display library
const ddlgtk := init_glishtk();
# load the pgplot and gdisplay modules into this new client
tmp := load_gpgplot(ddlgtk);
tmp := load_gdisplay(ddlgtk);
# add in the icon path
aipspath := split(environ.AIPSPATH)
libexec := spaste(aipspath[1], '/', aipspath[2], '/libexec');
tmp := ['.', spaste(libexec, '/icons')];
ddlgtk.tk_iconpath(tmp);
# create a new widgetserver using this gtk client
const ddlws := widgetserver(whichgtk=ddlgtk);
