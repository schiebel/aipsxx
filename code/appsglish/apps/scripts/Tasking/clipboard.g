# clipboard.g: Maintain an clipboard
#
#   Copyright (C) 1998,1999,2000
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
#   $Id: clipboard.g,v 19.2 2004/08/25 02:02:17 cvsmgr Exp $
#

pragma include once;

include 'note.g';
include 'popupselectmenu.g';

clipboard := function() {
  
  public := [=];
  private := [=];
  private.record := [=];

  # Just paste a value
  const public.paste := function() {
    wider private;
    return private.record;
  }

  # Copy
  const public.copy := function(record) {
    wider private;
    private.record := record;
    return T;
  }

  const public.type := function() {return 'clipboard';}

  return ref public;
}

# Make a singleton
const dcb := clipboard();
note('defaultclipboard (dcb) ready', priority='NORMAL', origin='clipboard');


