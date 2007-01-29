# calibrater_meta.g: Standard meta information for calibrater
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
#
#   $Id: autoflag_meta.g,v 19.5 2004/09/14 06:07:13 dguo Exp $
#

pragma include once

include 'types.g'

types.class('autoflag').includefile('autoflag.g');

# Constructors
types.method('ctor_autoflag').
  ms('msname');

# Methods
types.method('autoflag.settimemed').
  float('thr',5.0).
  integer('hw',10).
  float('rowthr',5.0).
  integer('rowhw',10).
  choice('column','DATA',options="DATA MODEL CORR").
  string('expr','ABS I').
  boolean('fignore',F);



types.method('autoflag.setnewtimemed').
  float('thr',3.0).
  choice('column','DATA',options="DATA MODEL CORR").
  string('expr','ABS RR').
  boolean('fignore',F);
  
types.method('autoflag.setfreqmed').
  float('thr',5.0).
  integer('hw',10).
  float('rowthr',5.0).
  integer('rowhw',10).
  choice('column','DATA',options="DATA MODEL CORR").
  string('expr','ABS I').
  boolean('fignore',F);

types.method('autoflag.setsprej').
  integer('ndeg',2).
  float('rowthr',5.0).
  integer('rowhw',10).
  spectralwindows('spwid',allowunset=T).
  vector_float('fq',allowunset=T).
  vector_integer('chan',allowunset=T).
  record('region',allowunset=T).
  choice('column','DATA',options="DATA MODEL CORR").
  string('expr','ABS I').
  boolean('fignore',F);
  
types.method('autoflag.setuvbin').
  float('thr',0.001).
  integer('nbins',50).
  integer('plotchan',allowunset=T).
  boolean('econoplot',F).
  choice('column','DATA',options="DATA MODEL CORR").
  string('expr','ABS I').
  boolean('fignore',F);
  
types.method('autoflag.setselect').
  spectralwindows('spwid',allowunset=T).
  vector_integer('field',allowunset=T).
  vector_float('fq',allowunset=T).
  vector_integer('chan',allowunset=T).
  vector_string('corr',allowunset=T).
  vector_integer('ant',allowunset=T).
  vector_integer('baseline',allowunset=T).
  vector_double('timerng',allowunset=T).
  boolean('autocorr',F).
  vector_double('timeslot',allowunset=T).
  float('dtime',10.0).
  record('clip',allowunset=T).
  record('flagrange',allowunset=T).
  vector_float('quack',allowunset=T).
  boolean('unflag',F);
  
types.method('autoflag.attach').
  ms('msfile');
  
types.method('autoflag.setdata').
  choice('mode', 'none', options=['other', 'channel', 'velocity']).
  vector_integer('nchan', [1]).
  vector_integer('start', [1]).
  vector_integer('step', [1]).
  quantity('mstart', '0km/s').
  quantity('mstep', '0km/s').
  vector_integer('spwid', []).
  vector_integer('fieldid', []).
  taql('msselect', '', options='Measurement Set');

types.method('autoflag.run').
  record('globparm',[=]).
  vector_integer('plotscr',allowunset=T).
  vector_integer('plotdev',allowunset=T).
  string('devfile','flagreport.ps/ps').
  boolean('reset',F).
  boolean('trial',F);
  
types.method('autoflag.summary');

types.method('autoflag.help').
  string('names',allowunset=T);

types.method('autoflag.reset').
  string('methods',allowunset=T);

types.method('autoflag.resetall');
