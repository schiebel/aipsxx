# coordsys_meta.g: Standard meta information for coordsys.g
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
#   $Id: coordsys_meta.g,v 19.6 2004/08/25 00:56:16 cvsmgr Exp $

pragma include once
include 'types.g';
include 'measures.g'

types.class('coordsys').includefile('coordsys.g');

# Constructors
types.method('ctor_coordsys').
    boolean('direction', default=F, allowunset=F).
    boolean('spectral', default=F, allowunset=F).
    check('stokes', options="I Q U V XX YY XY YX RR LL RL LR", allowunset=F).
    integer('linear', 0, allowunset=F).
    boolean('tabular', default=F, allowunset=F);

# Functions

# Group 'Utility'

types.group('Utility').method('coordsys.axesmap').
    boolean('toworld', T, allowunset=F).
    vector_integer('return');

# This allows multiple coordinates of the same type which are not well supported
#types.method('addcoordinate').
#    boolean('direction', default=F, allowunset=F).
#    boolean('spectral', default=F, allowunset=F).
#    check('stokes', options="I Q U V XX YY XY YX RR LL RL LR", allowunset=F).
#    integer('linear', 0, allowunset=F).
#    boolean('tabular', default=F, allowunset=F);

types.method('coordsys.axiscoordinatetypes').
    boolean('world', T, allowunset=F).
    vector_string('return');

types.method('coordsys.coordinatetype').
    integer('which', allowunset=T, default=unset).
    vector_string('return');

types.method('coordsys.copy').
    tool('return', 'mycoordsys', dir='inout');

types.method('coordsys.findaxis').
    integer('axis', 1, allowunset=F).
    boolean('world', T, allowunset=F).
    integer('coordinate', dir='out').
    integer('axisincoordinate', dir='out').
    boolean('return');

types.method('coordsys.findcoordinate').
    choice('type', options="direction stokes spectral linear tabular", allowunset=F).
    integer('which', 1, allowunset=F).
    vector_integer('pixel', dir='out').
    vector_integer('world', dir='out').
    boolean('return');

types.method('coordsys.fromrecord').
    record('record', dir='in', checkeval=T);

types.method('coordsys.naxes').
    boolean('world', T, allowunset=F).
    integer('return');

types.method('coordsys.ncoordinates').
    integer('return');

types.method('coordsys.reorder').
    vector_integer('order', allowunset=F);

types.method('coordsys.replace').
   coordinates('csys', allowunset=F, dir='in',
               help='Coordinate System (a Coordsys tool)').
    integer('whichin', allowunset=F).
    integer('whichout', allowunset=F);

# There is other args (list) and return type, but not useful from Toolmanager
# so leave default here
types.method('coordsys.summary').
    choice('doppler', options=['radio','optical'], allowunset=F);
types.method('coordsys.torecord').
    record('return');


# Group 'Conversion'

types.group('Conversion').method('coordsys.convert').
    vector_double('coordin', allowunset=F).
    vector_boolean('absin', allowunset=T, default=unset).
    measurecodes('dopplerin', default='radio', options='doppler', allowunset=F).
    string('unitsin', allowunset=T, default=unset).
    vector_boolean('absout', allowunset=T, default=unset).
    measurecodes('dopplerout', default='radio', options='doppler', allowunset=F).
    string('unitsout', allowunset=T, default=unset).
    vector_integer('shape', allowunset=T, default=unset).
    vector_double('return');

types.method('coordsys.toabs').
    untyped('value', default=unset, allowunset=T).
    boolean('isworld', allowunset=T, default=unset).
    untyped('return');

types.method('coordsys.topixel').
    untyped('value', default=unset, allowunset=T).
    vector_double('return');

types.method('coordsys.torel').
    untyped('value', default=unset, allowunset=T).
    boolean('isworld', allowunset=T, default=unset).
    untyped('return');

types.method('coordsys.toworld').
    vector_double('value', default=unset, allowunset=T).
    check('format', 'n', options="n q m s", allowunset=F,
           help='Numeric, Quantity String vector or Measures format').
    untyped('return');

types.method('coordsys.convertmany').
    vector_double('coordin', allowunset=F).
    vector_boolean('absin', allowunset=T, default=unset).
    measurecodes('dopplerin', default='radio', options='doppler', allowunset=F).
    string('unitsin', allowunset=T, default=unset).
    vector_boolean('absout', allowunset=T, default=unset).
    measurecodes('dopplerout', default='radio', options='doppler', allowunset=F).
    string('unitsout', allowunset=T, default=unset).
    vector_integer('shape', allowunset=T, default=unset).
    vector_double('return');

types.method('coordsys.toabsmany').
    vector_double('value', default=unset, allowunset=T).
    boolean('isworld', allowunset=T, default=unset).
    vector_double('return');

types.method('coordsys.topixelmany').
    vector_double('value', default=unset, allowunset=T).
    vector_double('return');

types.method('coordsys.torelmany').
    vector_double('value', default=unset, allowunset=T).
    boolean('isworld', allowunset=T, default=unset).
    vector_double('return');

types.method('coordsys.toworldmany').
    vector_double('value', default=unset, allowunset=T).
    vector_double('return');

types.method('coordsys.frequencytovelocity').
    vector_double('value', allowunset=F).
    string('frequnit', default=unset, allowunset=T,
           help='Default takes intrinsic unit in Coordinate System').
    measurecodes('doppler', default='radio', options='doppler', allowunset=F).
    string('velunit', default='km/s', allowunset=F).
    vector_double('return');

types.method('coordsys.frequencytofrequency').
    vector_double('value', allowunset=F).
    string('frequnit', default=unset, allowunset=T,
           help='Default takes intrinsic unit in Coordinate System').
    quantity('velocity', default='0km/s', allowunset=F).
    measurecodes('doppler', default='radio', options='doppler', allowunset=F).
    vector_double('return');

types.method('coordsys.velocitytofrequency').
    vector_double('value', allowunset=F).
    string('frequnit', default=unset, allowunset=T,
           help='Default takes intrinsic unit in Coordinate System').
    measurecodes('doppler', default='radio', options='doppler', allowunset=F).
    string('velunit', default='km/s', allowunset=F).
    vector_double('return');

types.method('coordsys.setconversiontype').
    measurecodes('direction', default='J2000', options='direction', allowunset=F).
    measurecodes('spectral', default='LSRK', options='frequency', allowunset=F);

types.method('coordsys.conversiontype').
    choice('type', options=['direction', 'spectral'], allowunset=F).
    string('return');

# Group 'get/set'

types.group('Get-Set').method('coordsys.epoch').
    measure('return');

types.method('coordsys.increment').
    check('format', 'n', options="n q s", allowunset=F,
           help='Numeric, Quantity or String vector format').
    choice('type', allowunset=T, default=unset,
           options="direction spectral stokes linear tabular").
    untyped('return');

types.method('coordsys.lineartransform').
    choice('type', allowunset=T, default=unset,
           options="direction spectral stokes linear tabular").
    vector_integer('return');

types.method('coordsys.names').
    choice('type', allowunset=T, default=unset,
           options="direction spectral stokes linear tabular").
    vector_string('return');

types.method('coordsys.observer').
    string('return');

#types.method('coordsys.parentname').
#    string('return');

hlp := spaste('Type of projection \n',
              'If unset the actual projection and parameters are returned\n',
              'If  \'all\'   a list of all possible projection codes is returned\n',
              'For a specific projection type code the number of parameters\n',
              '  it requires is returned');
types.method('coordsys.projection').
    string('type', allowunset=T, default=unset, help=hlp).
    untyped('return');

types.method('coordsys.referencecode').
    choice('type', allowunset=T, default=unset,
           options="direction spectral stokes linear tabular").
    boolean('list', default=F).
    untyped('return');

types.method('coordsys.referencepixel').
    choice('type', allowunset=T, default=unset,
           options="direction spectral stokes linear tabular").
    vector_integer('return');

types.method('coordsys.referencevalue').
    check('format', 'n', options="n q m s", allowunset=F,
           help='Numeric, Quantity, String vector or Measures format').
    choice('type', allowunset=T, default=unset, 
           options="direction spectral stokes linear tabular").
    untyped('return');

types.method('coordsys.restfrequency').
    quantity('return', default='0Hz');

types.method('coordsys.setepoch').
    measure('value');

types.method('coordsys.setincrement').
    untyped('value').
    choice('type', allowunset=T, default=unset, 
           options="direction spectral stokes linear tabular");

types.method('coordsys.setlineartransform').
    vector_double('value').
    choice('type', allowunset=T, default=unset, 
           options="direction spectral stokes linear tabular");

types.method('coordsys.setnames').
    string('value').
    choice('type', allowunset=T, default=unset, 
           options="direction spectral stokes linear tabular");

types.method('coordsys.setobserver').
    string('value');

#types.method('coordsys.setparentname').
#    string('value');

types.method('coordsys.setprojection').
    choice('type', 
           options="AZP TAN SIN STG ARC ZPN ZEA AIR CYP CAR MER CEA COP COD COE COO BON PCO GLS PAR AIT MOL CSC QSC TSC").
    vector_double('parameters', default=[]);

types.method('coordsys.setreferencecode').
    string('value').
    choice('type', options="direction spectral").
    boolean('adjust', T);

types.method('coordsys.setreferencelocation').
    vector_integer('pixel', default=unset, allowunset=T).
    untyped('world', default=unset, allowunset=T).    
    vector_boolean('mask', default=unset, allowunset=T);

types.method('coordsys.setreferencepixel').
    vector_double('value').
    choice('type', allowunset=T, default=unset, 
           options="direction spectral stokes linear tabular");

types.method('coordsys.setreferencevalue').
    untyped('value').
    choice('type', allowunset=T, default=unset, 
           options="direction spectral stokes linear tabular");

types.method('coordsys.setrestfrequency').
    quantity('value', default='0.0GHz', options='freq').
    integer('which', default=1, allowunset=F).
    boolean('append', default=F, allowunset=F);

types.method('coordsys.setdirection').
    measurecodes('refcode', default=unset, options='frequency', allowunset=T).
    string('proj', default=unset, allowunset=T).
    vector_double('projpar', default=unset, allowunset=T).
    vector_double('refpix', default=unset, allowunset=T).
    vector_double('refval', default=unset, allowunset=T).
    vector_double('incr', default=unset, allowunset=T).
    vector_double('xform', default=unset, allowunset=T).
    vector_double('poles', default=unset, allowunset=T);

types.method('coordsys.setspectral').
    measurecodes('refcode', default=unset, options='frequency', allowunset=T).
    quantity('restfreq', default=unset, options='freq', allowunset=T).
    quantity('frequencies', default=unset, options='freq', allowunset=T).
    measurecodes('doppler', default=unset, options='vel', allowunset=T);
#    quantity('velocities', default=unset, options='vel', allowunset=T);

types.method('coordsys.setstokes').
    check('stokes', options="I Q U V XX YY XY YX RR LL RL LR", allowunset=F);

types.method('coordsys.settabular').
    vector_double('pixel', default=unset, allowunset=T).
    vector_double('world', default=unset, allowunset=T).
    integer('which',default=1, allowunset=F);

types.method('coordsys.settelescope').
    string('value', default='');

types.method('coordsys.setunits').
    string('value').
    string('type', allowunset=T, default=unset).
    boolean('overwrite', F);

types.method('coordsys.stokes').
    vector_string('return');

types.method('coordsys.telescope').
    boolean('measure', F).
    untyped('return');

types.method('coordsys.units').
    string('type', allowunset=T, default=unset).
    vector_string('return');


# Global functions

types.method('global_is_coordsys').
   untyped('thing').
   boolean('return');

types.method('global_coordsystools').
   vector_string('return');
#   string('return');

types.method('global_coordsystest').
   integer('which', allowunset=T, default=unset).
   boolean('return');

