# inputsmanager_meta.g: Meta info for inputsmanager
#
#   Copyright (C) 1996,1997,1998,1999
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
#   $Id: inputsmanager_meta.g,v 19.2 2004/08/25 02:03:02 cvsmgr Exp $
#

pragma include once;
 
include "types.g";
  
types.class('inputsmanager').includefile('inputsmanager.g');

types.method('savevalues').string('type').string('method').
    record('values', [=]).string('keyword', 'lastsave');
types.method('getvalues').string('type').string('method').
    string('keyword', 'lastsave').record('return', [=]);
types.method('save').string('keyword', 'lastsave');
types.method('get').string('keyword', 'lastsave');
types.method('delete').integer('rows');
types.method('deletetable');
types.method('show').boolean('verbose', F);
types.method('list').record('return');



