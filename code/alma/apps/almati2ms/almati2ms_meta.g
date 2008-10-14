# almati2ms_meta.g: Standard meta information for almati2ms
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: almati2ms_meta.g,v 19.1 2004/01/02 23:06:55 kgolap Exp $
#

pragma include once;

include 'types.g';

types.class('almati2ms').includefile("almati2ms.g");

# Constructors
types.method('ctor_almati2ms').
    ms('msfile').
    fits('fitsin').
    boolean('append', T).
    string('host', '', help='hostname on which to run almati2ms').
    boolean('forcenewserver', T, help='Force creation of a new server');

# Methods

types.group('basic').method('setoptions').
    boolean('compress', F).
    boolean('combinebaseband', F);

types.group('basic').method('select').
    string('obsmode', 'CORR').
    choice('chanzero', 'TIME_AVG', options=['NONE','TIME_SAMPLED','TIME_AVG']);

types.group('basic').method('fill');

# Global functions

types.method('global_almatifiller').
    ms('msfile').
    directory('fitsdir', '.').
    string('pattern').
    boolean('append', T).
    boolean('compress', F).
    boolean('combinebaseband', F).
    string('obsmode', 'CORR').
    choice('chanzero', 'TIME_AVG', options=['NONE','TIME_SAMPLED','TIME_AVG']).
    boolean('dophcor', F);
