# printer_meta.g: Meta info for printer
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
#   $Id: printer_meta.g,v 19.2 2004/08/25 02:03:47 cvsmgr Exp $
#

pragma include once;
 
include "types.g";
  
types.class('printer').includefile('printer.g');

types.method('ctor_printer').string('printername').choice('mode', ['p', 'l', '80', '72']).
    choice('paper', ['l', 'A4', 'A3']).boolean('display', F);

types.method('reinit').choice('mode', ['p', 'l', '80', '72']).
    choice('paper', ['l', 'A4', 'A3']).boolean('display', F);
types.method('print').file('files');
types.method('printvalues').untyped('values').boolean('needcr', T).boolean('usegui', F);
types.method('gui').file('files').boolean('landscape', F);


