#-----------------------------------------------------------------------------
# rpfits2ms.g: Convert an RPFITS file to MS2 format using livedatareducer.
#-----------------------------------------------------------------------------
# Copyright (C) 2001
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: rpfits2ms.g,v 19.1 2004/07/27 03:23:10 mcalabre Exp $
#-----------------------------------------------------------------------------
# This utility converts an RPFITS file to MS2 format using livedatareducer in
# batch mode.
#
# Environment:
#    AIPSPATH             AIPS++ directory hierarchy.
#    RPIN                 Name of the input RPFITS file.
#    MSOUT                Name of the output measurementset v2.
#
# Original: 2001/07/12, Mark Calabretta, ATNF
#-----------------------------------------------------------------------------
pragma include once

# Check that AIPSPATH is defined.
if (!has_field(environ, 'AIPSPATH')) {
  print 'AIPSPATH is not defined - abort!'
  exit
}

include 'livedatareducer.g'


# Input specification.
if (has_field(environ, 'RPIN')) {
  rpin := environ.RPIN
} else {
  rpin := readline(prompt='Enter the RPFITS file name: ')
}

read_dir  := rpin ~ s|(.*/)*.*$|$1|
if (read_dir == '') read_dir := '.'

read_file := rpin ~ s|.*/||
if (read_file == '') fail "No input file specified."


# Output specification.
if (has_field(environ, 'MSOUT')) {
  msout := environ.MSOUT
} else if (has_field(environ, 'RPIN')) {
  msout := environ.RPIN ~ s|\.[^.]*$|.ms2|
} else {
  msout := readline(prompt='Enter the measurementset name: ')
}

write_dir  := msout ~ s|(.*/)*.*$|$1|
if (write_dir == '') write_dir := '.'

write_file := msout ~ s|.*/||
if (write_file == '') write_file := read_file ~ s|\.[^.]*$|| ~ s|$|.ms2|


# Instantiate a livedata reducer.
ldred := reducer(writer     = T,
                 format     = 'MS2',
                 read_dir   = read_dir,
                 read_file  = read_file,
                 write_dir  = write_dir,
                 write_file = write_file)

ldred->start()
await ldred->finished

exit
