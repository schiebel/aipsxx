# imageprofilefitter_meta.g: Standard meta information for imageprofilefitter
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001
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
#   $Id: imageprofilefitter_meta.g,v 19.2 2004/08/25 00:59:07 cvsmgr Exp $
#


pragma include once;

include 'types.g';

types.class('imageprofilefitter').includefile('imageprofilefitter.g');

# Constructors.
# Don't include widgetset and parent frame arguments
#
types.method('imageprofilefitter.ctor_imageprofilefitter').
      image('infile', dir='in', allowunset=F).
      image('infile2', default=unset, dir='in', allowunset=T).
      integer('axis', default=unset, dir='in', allowunset=T).
      record('plotter', default=unset, dir='in', allowunset=T).
      boolean('showimage', default=T, dir='in', allowunset=F);

types.method('imageprofilefitter.getestimate').
    record('return');

types.method('imageprofilefitter.getfit').
    record('return');

types.method('imageprofilefitter.getstore').
    record('return');

types.method('imageprofilefitter.gui');

types.method('imageprofilefitter.setimage').
    image('infile', dir='in', allowunset=F).
    image('infile2', default=unset, dir='in', allowunset=T);

types.method('imageprofilefitter.type').
    string('return');






