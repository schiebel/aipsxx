# calibrater_meta.g: Standard meta information for calibrater
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
#   $Id: calibrater_meta.g,v 19.2 2004/08/25 01:04:59 cvsmgr Exp $
#

pragma include once

include 'types.g'

types.class('calibrater').includefile('calibrater.g');

# Constructors
types.method('ctor_calibrater').
ms('filename').
boolean('compress', T);

# Methods
types.method('calibrater.close');

types.method('calibrater.setapply').
    choice('type',options=[' ','B', 'G', 'D', 'P', 'T']).
    float('t',0.0).
    table('table',' ',options='Calibration').
    taql('select','', options='Calibration').
    boolean('unset',F, allowunset=T);

types.method('calibrater.setsolve').
    choice('type',options=['B', 'G', 'GDelayRateSB', 'D', 'T']).
    float('t',0.0).float('preavg',0.0).
    boolean('phaseonly', F).integer('refant',-1).
    string('table','').boolean('append',F).
    boolean('unset',F, allowunset=T);

types.method('calibrater.state');

types.method('calibrater.reset').
    boolean('apply', T).
    boolean('solve', T);

types.method('calibrater.initcalset').
    boolean('calset', T);

types.method('calibrater.setdata').
    choice('mode', 'none', options=['none', 'channel', 'velocity']).
    integer('nchan', 1).
    integer('start', 1).
    integer('step', 1).
    quantity('mstart', '0km/s').
    quantity('mstep', '0km/s').
    vector_float('uvrange', 0).
    taql('msselect', '', options='Measurement Set');

types.method('calibrater.solve');

types.method('calibrater.correct');

types.method('calibrater.plotcal').
    choice('plottype', 'AMP', options=['AMP', '1/AMP','PHASE', 'RLPHASE', 
                                       'XYPHASE',
                                       'RI', 'DAMP', 'DPHASE', 'DRI', 
                                       'FIT', 'FITWGT', 'TOTALFIT']).
    table('tablename', '', options='Calibration').
    vector_integer('antennas', []).
    vector_integer('fields', []).
    integer('polarization', 1).
    vector_integer('spwids', []).
    integer('timeslot',1).
    boolean('multiplot',F).
    integer('nx',1).
    integer('ny',1).
    file('psfile', '');

types.method('calibrater.fluxscale').
    table('tablein', '', options='Calibration').
    table('tableout', '', options='Calibration').
    vector_string('reference', [' ']).
    vector_string('transfer', [' ']);

types.method('calibrater.posangcal').
    table('tablein', '', options='Calibration').
    table('tableout', '', options='Calibration').
    vector_float('posangcor', []);

types.method('calibrater.calave').
    table('tablein', '', options='Calibration').
    table('tableout', '', options='Calibration').
    vector_integer('fldsin',[]).
    vector_integer('spwsin',[]).
    vector_integer('fldsout',[]).
    integer('spwout',1).
    float('t',-1.0).
    boolean('append',F).
    choice('mode','RI',options=['RI','AP']);

types.method('calibrater.linpolcor').
    table('tablein', '', options='Calibration').
    table('tableout', '', options='Calibration').
    vector_string('fields', [' ']);






