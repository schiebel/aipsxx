# componentlist_meta.g: Standard meta information for componentlist
#
#   Copyright (C) 1996,1997,1998,1999,2000,2003
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
#   $Id: componentlist_meta.g,v 19.4 2004/08/25 01:06:54 cvsmgr Exp $
#

pragma include once;

include 'types.g';
include 'unset.g';
include 'measures.g';

local componentlist_dir_types := [dm.listcodes(dm.direction()).normal, 
				  dm.listcodes(dm.direction()).extra];
local componentlist_freq_types := [dm.listcodes(dm.frequency()).normal,
                                   dm.listcodes(dm.frequency()).extra];

types.class('componentlist').includefile('componentlist.g');

types.method('ctor_emptycomponentlist');

types.method('ctor_componentlist').
  table('filename', 'default.cl').
  boolean('readonly', F);

types.method('ctor_asciitocomponentlist').
  table('filename', 'default.cl').
  file('asciifile', options='ascii').
  choice('refer', 'J2000', options="J2000 B1950 Galactic").
  choice('format', 'ST', options="Caltech FIRST NVSS ST WENSS").
  record('flux', unset, allowunset=T).
  record('spectrum', unset, allowunset=T).
  direction('direction', unset, allowunset=T).
  boolean('readonly', F);

types.method ('print').
  vector_integer('which', default=unset, allowunset=T).
  boolean('return');

types.method('replace').
  vector_integer('which', [1], allowunset=F).
  tool('list', allowunset=T, dir='in', default=unset, checkeval=T).
  vector_integer('whichones', [1], allowunset=F).
  boolean('return');

types.method('concatenate').
  tool('list', allowunset=T, dir='in', default=unset, checkeval=T).
  vector_integer('which', unset, allowunset=T).
  boolean('return');

types.method('remove').
  vector_integer('which', [1]);

types.method('purge');

types.method('recover');

types.method('length').
  integer('return');

types.method('indices').
  vector_integer('return');

types.method('sort').
  choice('criteria', 'flux', options="flux position polarization");

types.method('sample').
  direction('direction').
  quantity('pixellatsize', '1arcsec').
  quantity('pixellongsize', '1arcsec').
  quantity('frequency', '1GHz').
  vector_double('return');

types.method('rename').
  table('filename', 'default.cl');

types.method('simulate').
  integer('howmany', 1);

types.method('addcomponent').
  vector_dcomplex('flux', as_dcomplex([1,0,0,0])).
  string('fluxunit', 'Jy').
  choice('polarization', 'Stokes', options="Stokes Linear Circular").
  string('ra', '00:00:00.00').
  choice('raunit', 'time', options="time angle deg rad").
  string('dec', '90.00.00.00').
  choice('decunit', 'angle', options="time angle deg rad").
  choice('dirframe', 'j2000', options=componentlist_dir_types).
  choice('shape', 'point', options="point Gaussian disk").
  quantity('majoraxis', '2arcmin').
  quantity('minoraxis', '1arcmin').
  quantity('positionangle', '0deg').
  quantity('freq', '1.415GHz').
  choice('freqframe', 'LSRK', options=componentlist_freq_types).
  choice('spectrumtype', 'constant', options=['constant', 'spectral index']).
  vector_float('index', [1,0,0,0]).
  string('label', 'The default label');

types.method('close');

types.method('edit').
  integer('which', 1);

types.method('select').
  vector_integer('which', [1]);

types.method('deselect').
  vector_integer('which', [1]);

types.method('selected').
  vector_integer('return');

types.method('getlabel').
  integer('which', 1).
  string('return');

types.method('setlabel').
  vector_integer('which', [1]).
  string('value', 'The default label');

types.method('getfluxvalue').
  integer('which', 1).
  vector_dcomplex('return');

types.method('getfluxunit').
  integer('which', 1).
  string('return');

types.method('getfluxpol').
  integer('which', 1).
  string('return');

types.method('getfluxerror').
  integer('which', 1).
  vector_dcomplex('return');

types.method('setflux').
  vector_integer('which', [1]).
  vector_dcomplex('value', [1+0i,0+0i,0+0i,0+0i]).
  string('unit', 'Jy').
  choice('polarization', 'Stokes', options="Stokes Linear Circular").
  vector_dcomplex('error', [0+0i,0+0i,0+0i,0+0i]);

types.method('convertfluxunit').
  vector_integer('which', [1]).
  string('unit', 'Jy');

types.method('convertfluxpol').
  vector_integer('which', [1]).
  choice('polarization', 'Stokes', options="Stokes linear circular");

types.method('getrefdir').
  integer('which', 1).
  direction('return');

types.method('getrefdirra').
  integer('which', 1).
  choice('unit', 'time', options="time angle deg rad").
  integer('precision', 9).
  string('return');

types.method('getrefdirdec').
  integer('which', 1).
  choice('unit', 'angle', options="time angle deg rad").
  integer('precision', 9).
  string('return');

types.method('getrefdirframe').
  integer('which', 1).
  string('return');

types.method('setrefdir').
  vector_integer('which', [1]).
  string('ra', '00:00:00.00').
  choice('raunit', 'time', options="time angle deg rad").
  string('dec', '90.00.00.00').
  choice('decunit', 'angle', options="time angle deg rad");

types.method('setrefdirframe').
  vector_integer('which', [1]).
  choice('frame', 'j2000', options=componentlist_dir_types);

types.method('convertrefdir').
  vector_integer('which', [1]).
  choice('frame', 'j2000', options=componentlist_dir_types);

types.method('shapetype').
  integer('which', 1).string('return');

types.method('getshape').
  integer('which', 1).
  record('return');

types.method('setshape').
  vector_integer('which', [1]).
  choice('type', 'point', options="point Gaussian disk").
  quantity('majoraxis', '2arcmin').
  quantity('minoraxis', '1arcmin').
  quantity('positionangle', '0deg');

types.method('convertshape').
  vector_integer('which').
  choice('majoraxis', 'arcmin', options="arcmin arcsec mas deg rad").
  choice('minoraxis', 'arcmin', options="arcmin arcsec mas deg rad").
  choice('positionangle', 'deg', options="deg rad");

types.method('spectrumtype').
  integer('which', 1).string('return');

types.method('getspectrum').
  integer('which', 1).
  record('return');

types.method('setspectrum').
  vector_integer('which', [1]).
  choice('type', 'constant', options=['constant', 'spectral index']).
  vector_float('index', [1,0,0,0]);

types.method('getfreq').
  integer('which').
  quantity('return', '1GHz');

types.method('getfreqvalue').
  integer('which', 1).
  double('return');
  
types.method('getfrequnit').
  integer('which', 1).
  string('return');

types.method('getfreqframe').
  integer('which', 1).
  string('return');

types.method('setfreq').
  vector_integer('which', [1]).
  double('value', 1.415).
  string('unit', 'GHz');
  
types.method('setfreqframe').
  vector_integer('which', [1]).
  choice('frame', 'LSRK', options=componentlist_freq_types);

types.method('convertfrequnit').
  vector_integer('which', [1]).
  choice('unit', 'GHz', options="Hz kHz MHz GHz THz");

# Global functions

types.method('global_is_componentlist').
   tool('tool').
   boolean('return');

