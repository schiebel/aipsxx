# rfigui: GUI for RFI utilities
# Copyright (C) 1999
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
# $Id: rfigui.g,v 19.0 2003/07/16 03:43:24 aips2adm Exp $

# include guard
pragma include once;

#

include 'rfi.g';

const rfigui := function(withgui=T) {
    if (withgui) {

# Define action buttons for forking to the relevant routines.

	action:=[=];
	action.rfiq.text := 'Query RFI DB';
	action.rfis.text := 'Submit RFI Data';
	action.dismiss.text := 'Exit';

#Pull up standard guiframework; use defaults for file, options, and help
#menus.
#
	global rfimain:=guiframework('GB RFI Database',T,T,action);

	rfimain.addactionhandler('dismiss', rfi.leave);
	rfimain.addactionhandler('rfiq',rfi.callrfiquery);
	rfimain.addactionhandler('rfis',rfi.callauthorize);
#

	global wf_us := rfimain.getworkframe();
#
	global sl:=status_line(wf_us);
	sl.show('Choose an action with the buttons');
#
	dm.transgui(rfimain.app.cmd.b.rfiq,'Query RFI Database');
	dm.transgui(rfimain.app.cmd.b.rfis,'Submit information to the RFI database');
#
    } 			# end withgui
}				# end function

# start it up right away
rfigui();
#
