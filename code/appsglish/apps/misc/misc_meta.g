# misc_meta.g: Meta info for Misc commands
#
#   Copyright (C) 1996,1997,1998,1999,2002
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
#   $Id: misc_meta.g,v 19.1 2004/08/25 01:34:41 cvsmgr Exp $
#

pragma include once;
 
include "types.g";
  
types.class('misc').includefile('misc.g');

types.method('escapespecial').string('astring').string('return');
types.method('shellcmd').string('command').boolean('log',T).vector_string('return');
types.method('stripleadingblanks').string('string').string('return');
types.method('striptrailingblanks').string('string').string('return');
types.method('patternmatch').string('pattern').string('strings').string('return');
types.method('fileexists').file('file').string('opt', '-s').boolean('return');
types.method('dir').directory('directoryname','.').vector_string('return');
types.method('thisdir').directory('directoryname','.').directory('return');
types.method('parentdir').directory('directoryname','.').directory('return');
types.method('filetype').file('filename').string('return');
types.method('fields').record('rec').boolean('return');
types.method('initspinner').double('interval',1.0);
types.method('killspinner');
types.method('timetostring').double('timevalue', 'time()').
    string('form', 'ymd local').
    string('return');
