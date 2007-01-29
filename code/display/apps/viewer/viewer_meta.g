# viewer_meta.g: Meta information for AIPS++ data viewer tool
# Copyright (C) 1999,2001,2003
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
# $Id: viewer_meta.g,v 19.1 2005/06/15 18:10:56 cvsmgr Exp $

pragma include once;

include 'types.g';

types.class('viewer').includefile('viewer.g');

# constructor
types.method('ctor_viewer').
    string('title', 'viewer').
    boolean('deleteatexit', T);

# gui
types.method('viewer.gui').
    boolean('datamanager', T).
    boolean('displaypanel', T);

# Global functions
types.method('global_is_viewer').
   untyped('tool', allowunset=F).
   boolean('return', help='A Glish boolean');


