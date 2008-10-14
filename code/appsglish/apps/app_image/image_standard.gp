# image_standard.gp: Standard plugins for AIPS++ image class
#
#   Copyright (C) 1996,1997,1999,2000,2001
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
#   $Id: image_standard.gp,v 19.2 2005/05/24 08:11:56 cvsmgr Exp $
#

pragma include once

include 'types.g';
include 'note.g';

image_standard := [=];
image_standard.init := function()
{
    return T;
}

image_standard.attach := function(ref public)
{
###
    const public.type := function()
    {
       return 'image';
    }

###
    return T;
}
const image_standard := const image_standard;
