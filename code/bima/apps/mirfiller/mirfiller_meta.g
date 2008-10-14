# mirfiller_meta.g:  the metadata for driving mirfiller via the tool manager
# Copyright (C) 2001
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
# $Id: mirfiller_meta.g,v 19.0 2003/07/16 03:35:49 aips2adm Exp $

# include guard
pragma include once
 
include 'types.g';                      # Required

#
# Name the include file that defines the tool
types.class('mirfiller').includefile('mirfiller.g');

# Constructor
types.method('ctor_mirfiller').
    file('mirfile', options='Miriad Vis', help='the input Miriad dataset').
    boolean('preview', help='scan through input dataset for summary').
    choice('defpass', 'default', 
           help=paste('default selection type; controls what gets passed',
                      'when a selection is not specified'),
           options=['default', 'rawbima', 'calbima', 'all', 'none']);

# Methods

types.method('getoptions').
    record('return', help='the current options returned in a record');

types.method('setoptions').
    integer('scanlim', default=unset, allowunset=T, 
            help='the time gap limit for a "scan" in minutes').
    integer('obslim', default=unset, allowunset=T, 
            help='the time gap limit for an "observation" in hours').
    integer('tilesize', default=unset, allowunset=T, 
            help='the size of output tile in number of channels').
    boolean('verbose', default=unset, allowunset=T, 
            help='if true, write extra messages').
    boolean('reset', default=F, 
            help='if true, reset previous values to default');

types.method('select').
    choice('defpass', 'default', allowunset=T, 
           help=paste('default selection type; controls what gets passed',
                      'when a selection is not specified'),
           options=['default', 'rawbima', 'calbima', 'all', 'none']).
    vector_integer('splwin', default=[], allowunset=T, 
                   help='spectral line window ids').
    vector_integer('winav', default=[], allowunset=T, 
                   help='window average ids').
    choice('sbandav', 'default', allowunset=T, 
           help='sideband average selection',
           options=['default', 'lsb', 'usb', 'all', 'none']);

types.method('fill').
    ms('msfile', help='output measurement set').
    boolean('verbose', default=F, help='report progress to logger').
    boolean('async', default=F, help='run asynchronously');

types.method('summary').
    record('header', '[=]', dir='out', 
           help='summary information returned here').
    boolean('verbose', T, help='print summary information to logger').
    boolean('preview', T, help='scan through entire dataset if necessary');

types.method('global_miriadtoms').
    ms('msfile', help='output measurement set').
    file('mirfile', options='Miriad Vis', help='the input Miriad dataset').
    choice('defpass', 'default', 
           help=paste('window selection type; controls which windows get',
		      'passed to the output dataset'),
           options=['default', 'rawbima', 'calbima', 'all', 'none']).
    boolean('verbose', default=F, help='report progress to logger');
