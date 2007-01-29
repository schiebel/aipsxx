# ftp_meta.g: Meta info for ftp
#
#   Copyright (C) 1996,1997,1998,1999,2000
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
#   $Id: ftp_meta.g,v 19.2 2004/08/25 02:08:41 cvsmgr Exp $
#

pragma include once;
 
include "types.g";
  
types.class('ftp').includefile('ftp.g');

types.method('ctor_ftp').
    string('host', 'aips2.nrao.edu').string('user', 'anonymous').
    string('pass', unset, allowunset=T).string('dir', 'pub').
    string('command', 'ftp -n -v -i').
    string('prompt', 'ftp>').boolean('verbose', T);

types.method('connect').boolean('return');

types.method('disconnect').boolean('return');

types.method('binary').boolean('return');

types.method('ascii').boolean('return');

types.method('get').file('file');

types.method('send').file('file');

types.method('cd').string('dir');

types.method('list').boolean('return');



