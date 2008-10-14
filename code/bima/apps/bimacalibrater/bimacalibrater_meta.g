# bimacalibrater_meta.g: Standard meta information for bimacalibrater
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
#

pragma include once

include 'types.g'

types.class('bimacalibrater').includefile('bimacalibrater.g');

# Constructors
types.method('ctor_bimacalibrater').vector_string('targets',[' ']).
    vector_string('phcals',[' ']).
    vector_string('pbcals',[' ']).
    vector_string('fcals',[' ']).
    vector_string('targetnames',unset,allowunset=T).
    vector_string('phcalnames',unset,allowunset=T).
    vector_string('pbcalnames',unset,allowunset=T).
    vector_string('fcalnames',unset,allowunset=T);

# Methods
types.method('bimacalibrater.getsourcenames').vector_string('roles',[' ']).
    vector_string('return');

types.method('bimacalibrater.setjy').vector_string('sources','phcals').
    integer('fieldid',-1).integer('spwid',-1).vector_double('fluxdensity',-1);


types.method('bimacalibrater.setdata').vector_string('sources','phcals').
    choice('mode', 'none', options=['none', 'channel', 'velocity']).
    integer('nchan', 1).integer('start', 1).integer('step', 1).
    quantity('mstart', '0km/s').quantity('mstep', '0km/s').
    vector_float('uvrange', 0).vector_string('sourcenames',[' ']).
    taql('msselect', '', options='Measurement Set');

types.method('bimacalibrater.setsolve').vector_string('sources','phcals').
    choice('type','G',options=['T', 'G', 'GDelayRateSB', 'D', 'B']).
    float('t',0.0).float('preavg',0.0).
    boolean('phaseonly', F).integer('refant',-1).
    table('table','').boolean('append',F);

types.method('bimacalibrater.solve').vector_string('sources','phcals');

types.method('bimacalibrater.fit').table('table',unset,allowunset=T);

types.method('bimacalibrater.transfer').table('outtable','').
    table('intable','').vector_integer('spwmap').
    vector_string('calibratees','targets').boolean('forcecopy',T);

types.method('bimacalibrater.setapply').vector_string('sources','targets').
    choice('type','G',options=['T', 'G', 'D', 'B']).float('t',0.0).
    table('table',unset,options='Calibration').
    taql('select','', options='Calibration');

types.method('bimacalibrater.addtargets').vector_string('mss',[' ']).
    vector_string('names',unset,allowunset=T);

types.method('bimacalibrater.correct').vector_string('sources','targets');

types.method('bimacalibrater.close').vector_string('sources',[' ']);




types.method('bimacalibrater.plotcal').vector_string('sources',[' ']).
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
    string('psfile','');

types.method('bimacalibrater.summary');

# still to come
#
#types.method('bimacalibrater.fluxscale').
#    table('tablein', '', options='Calibration').
#    table('tableout', '', options='Calibration').
#    vector_string('reference', ['']).
#    vector_string('transfer', ['']);






