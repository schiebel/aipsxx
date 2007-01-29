# atcafiller_meta.g: Standard meta information for atcafiller
#
#   Copyright (C) 2001,2003
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
#   $Id: atcafiller_meta.g,v 19.1 2003/09/22 03:18:12 mwiering Exp $
#

pragma include once

include 'types.g'

types.class('atcafiller').includefile('atcafiller.g');

# Constructors
types.method('ctor_atcafiller').ms('msname').file('filenames').
    string('options').float('shadow',22.0); 
#.boolean('online',F);

# Methods
types.method('atcafiller.close');

types.method('atcafiller.fill');

types.method('atcafiller.select').
    integer('firstscan',1).integer('lastscan',9999).
    integer('freqchain',0).double('lowfreq',0.1).double('highfreq',1000.0).
    string('fields').integer('bandwidth1',0).integer('numchan1',0);




