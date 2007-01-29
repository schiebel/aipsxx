# cscatalog_meta.g: Standard meta information for cscatalog
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
#   $Id: cscatalog_meta.g,v 19.0 2003/07/16 06:10:48 aips2adm Exp $
#

pragma include once;

include 'types.g';

types.class('cscatalog').includefile("cscatalog.g");

# Constructors
types.method('ctor_cscatalog');

# Methods

types.method('querydirection').
    direction('direction', dir='in').
    quantity('sr', '1deg', dir='in').
    choice('catalog', "NVSS FIRST WENSS").
    quantity('fluxrange', '0Jy').
    tool('return', 'mycomplist', dir='inout');

types.method('queryimage').
    image('im').
    choice('catalog', "NVSS FIRST WENSS").
    quantity('fluxrange', '0Jy').
    tool('return', 'mycomplist', dir='inout');
