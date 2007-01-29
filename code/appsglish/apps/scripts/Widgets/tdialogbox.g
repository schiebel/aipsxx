# tdialogbox.g: test dialogbox.g
# Copyright (C) 1996,1997,1998,1999
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
#   $Id: tdialogbox.g,v 19.2 2004/08/25 02:21:22 cvsmgr Exp $

include 'widgetserver.g'
include 'measures.g'
include 'quanta.g'

d1 := dws.dialogbox(type='entry', value='entry'); print d1;
d2 := dws.dialogbox(type='file', value='file'); print d2;
d3 := dws.dialogbox(type='string', value='string'); print d3;
d4 := dws.dialogbox(type='boolean', value=F); print d4;
d5 := dws.dialogbox(type='measure', value=dm.direction('j2000','30deg','40deg')); print d5;
d6 := dws.dialogbox(type='quantity', value=dq.quantity(1,'arcsec')); print d6;
d7 := dws.dialogbox(type='record', value=[a=1,b=2]); print d7;
d8 := dws.dialogbox(type='region', value=drm.box()); print d8.torecord();
d9 := dws.dialogbox(type='scalar', value=1.2); print d9;
d10 := dws.dialogbox(type='untyped', value=12); print d10;
