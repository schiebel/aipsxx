# imagepol_meta.g: Standard meta information for imagepol.g
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
#   $Id: imagepol_meta.g,v 19.2 2004/08/25 00:58:47 cvsmgr Exp $

pragma include once

include 'types.g';

types.class('imagepol').includefile('imagepol.g');

# Constructors
types.method('ctor_imagepol').
    image('infile', allowunset=F);

types.method('ctor_imagepoltestimage').
        file('outfile', default='imagepol.iquv', allowunset=F).
        vector_float('rm', default=unset, allowunset=T).
        float('pa0', default=0.0, allowunset=F).
        float('sigma', default=0.01, allowunset=F).
        integer('nx', default=32, allowunset=F).
        integer('ny', default=32, allowunset=F).
        integer('nf', default=32, allowunset=F).
        float('f0', default=1.4e9, allowunset=F).
        float('bw', default=128.0e6, allowunset=F);


# Tool functions

#
# Group 'Polarization'
#
sighelp := spaste('Standard deviation of thermal noise\n',
                  'If unset determined automatically from \n',
                  'data with outliers clipped as specified by \n',
                  'clip argument');

types.group('Polarization').method('imagepol.complexlinpol').
       file('outfile', default='linpol.complex', allowunset=F, dir='in');

types.method('imagepol.complexfraclinpol').
       file('outfile', default='fraclinpol.complex', allowunset=F, dir='in');

types.method('imagepol.depolratio').
       image('infile', allowunset=F).
       boolean('debias', default=F, allowunset=F).
       float('clip', default=10.0, allowunset=F).
       float('sigma', default=unset, allowunset=T, help=sighelp).
       file('outfile', default=unset, allowunset=T).
       tool('return', 'depolratio', dir='inout');

types.method('imagepol.fraclinpol').
       boolean('debias', default=F, allowunset=F).
       float('clip', default=10.0, allowunset=F).
       float('sigma', default=unset, allowunset=T, help=sighelp).
       file('outfile', default=unset, allowunset=T).
       tool('return', 'fraclinpol', dir='inout');

types.method('imagepol.fractotpol').
       boolean('debias', default=F, allowunset=F).
       float('clip', default=10.0, allowunset=F).
       float('sigma', default=unset, allowunset=T, help=sighelp).
       file('outfile', default=unset, allowunset=T).
       tool('return', 'fractotpol', dir='inout');

types.method('imagepol.linpolint').
       boolean('debias', default=F, allowunset=F).
       float('clip', default=10.0, allowunset=F).
       float('sigma', default=unset, allowunset=T, help=sighelp).
       file('outfile', default=unset, allowunset=T).
       tool('return', 'linpolint', dir='inout');

types.method('imagepol.linpolposang').
       file('outfile', default=unset, allowunset=T).
       tool('return', 'linpolposang', dir='inout');

types.method('imagepol.pol').
       choice('which', options=['LinearlyPolarizedIntensity', 
                                'TotalPolarizedIntensity',
                                'LinearlyPolarizedPositionAngle', 
                                'FractionalLinearPolarization',
                                'FractionalTotalPolarization'],
              allowunset=F).
       boolean('debias', default=F, allowunset=F).
       float('clip', default=10.0, allowunset=F).
       float('sigma', default=unset, allowunset=T, help=sighelp).
       file('outfile', default=unset, allowunset=T).
       tool('return', 'pol', dir='inout');

types.method('imagepol.totpolint').
       boolean('debias', default=F, allowunset=F).
       float('clip', default=10.0, allowunset=F).
       float('sigma', default=unset, allowunset=T, help=sighelp).
       file('outfile', default=unset, allowunset=T).
       tool('return', 'totpolint', dir='inout');

types.method('imagepol.sigma').
       float('clip', default=10, allowunset=F).
       float('return', dir='out');

types.method('imagepol.sigmadepolratio').
       image('infile', allowunset=F).
       boolean('debias', default=F, allowunset=F).
       float('clip', default=10.0, allowunset=F).
       float('sigma', default=unset, allowunset=T, help=sighelp).
       file('outfile', default=unset, allowunset=T).
       tool('return', 'sigmadepolratio', dir='inout');

types.method('imagepol.sigmafraclinpol').
       float('clip', default=10, allowunset=F).
       float('sigma', default=unset, allowunset=T, help=sighelp).
       file('outfile', default=unset, allowunset=T).
       tool('return', 'sigmafraclinpol', dir='inout');

types.method('imagepol.sigmafractotpol').
       float('clip', default=10, allowunset=F).
       float('sigma', default=unset, allowunset=T, help=sighelp).
       file('outfile', default=unset, allowunset=T).
       tool('return', 'sigmafractotpol', dir='inout');

types.method('imagepol.sigmalinpolint').
       float('clip', default=10, allowunset=F).
       float('sigma', default=unset, allowunset=T, help=sighelp).
       float('return', dir='out');

types.method('imagepol.sigmalinpolposang').
       float('clip', default=10, allowunset=F).
       float('sigma', default=unset, allowunset=T, help=sighelp).
       file('outfile', default=unset, allowunset=T).
       tool('return', 'sigmalinpolposang', dir='inout');

types.method('imagepol.sigmatotpolint').
       float('clip', default=10, allowunset=F).
       float('sigma',default=unset,allowunset=T, help=sighelp).
       float('return', dir='out');

# 
# Group 'Rotation Measure'
#
types.group('Rotation Measure').method('imagepol.fourierrotationmeasure').
       boolean('zerolag0', default=F, allowunset=F).
       file('complex', allowunset=T, default=unset).
       file('amp', allowunset=T, default=unset).
       file('pa',allowunset=T,default=unset).
       file('real',allowunset=T,default=unset).
       file('imag',allowunset=T,default=unset);

rmmaxhlp := spaste('Maximum RM to solve for. Important to set\n',
                   'If unset, no effective maximum is applied');
types.method('imagepol.rotationmeasure').
       float('sigma', default=unset, allowunset=T).
       float('rmfg', default=0, allowunset=F).
       float('rmmax', default=unset, allowunset=T, help=rmmaxhlp).
       float('maxpaerr', default=unset, allowunset=T).
       string('plotter', default=unset, allowunset=T).
       integer('nx', default=5).
       integer('ny', default=5).
       file('rm',default=unset,allowunset=T,dir='in').
       file('rmerr', default=unset, allowunset=T).
       file('pa0', default=unset, allowunset=T).
       file('pa0err', default=unset, allowunset=T).
       file('nturns',default=unset,allowunset=T).
       file('chisq', default=unset, allowunset=T);
#
# Group 'Stokes'
#
types.group('Stokes').method('imagepol.stokes').
       choice('which', options="I Q U V", allowunset=F).
       file('outfile', default=unset, allowunset=T).
       tool('return', 'stokes', dir='inout');

types.method('imagepol.stokesi').
       file('outfile', default=unset, allowunset=T).
       tool('return', 'stokesi', dir='inout');

types.method('imagepol.stokesq').
       file('outfile', default=unset, allowunset=T).
       tool('return', 'stokesq', dir='inout');

types.method('imagepol.stokesu').
       file('outfile', default=unset, allowunset=T).
       tool('return', 'stokesu', dir='inout');

types.method('imagepol.stokesv').
       file('outfile', default=unset, allowunset=T).
       tool('return', 'stokesv', dir='inout');

types.method('imagepol.sigmastokes').
       choice('which', options="I Q U V", allowunset=F).
       float('clip', default=10, allowunset=F).
       float('return', dir='out');

types.method('imagepol.sigmastokesi').
       float('clip', default=10, allowunset=F).
       float('return', dir='out');

types.method('imagepol.sigmastokesq').
       float('clip', default=10, allowunset=F).
       float('return', dir='out');

types.method('imagepol.sigmastokesu').
       float('clip', default=10, allowunset=F).
       float('return', dir='out');

types.method('imagepol.sigmastokesv').
       float('clip', default=10, allowunset=F).
       float('return', dir='out');
# 
# Group 'Inquiry'
#
types.group('Inquiry').method('imagepol.summary');

# 
# Group 'Utility'
#
types.group('Utility').method('imagepol.makecomplex').
       string('outfile', default='complex.image', allowunset=F, dir='in').
       file('real', allowunset=T, default=unset, dir='in').
       file('imag', allowunset=T, default=unset, dir='in').
       file('amp', allowunset=T, default=unset, dir='in').
       file('phase', allowunset=T, default=unset, dir='in');

# Globals

types.method('global_is_imagepol').
   untyped('thing'). 
   boolean('return');

types.method('global_imagepoltest').
   vector_integer('which', default=unset, allowunset=T);

