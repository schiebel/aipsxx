# iramcalibrater_meta.g: Standard meta info for iramcalibrater (clic emulator)
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
#   $Id: iramcalibrater_meta.g,v 19.0 2003/07/16 06:10:29 aips2adm Exp $
#

pragma include once;

include 'types.g';

types.class('iramcalibrater').includefile("iramcalibrater.g");

# Constructors
types.method('ctor_iramcalibrater').
  ms('msname').
  boolean('initcal',F);

# Methods


types.method('initcal');

types.method('phcor').
  boolean('trial',T);
#  choice('frqgrp', '3mm-LSB',
#	 options=['3mm','3mm-LSB', '3mm-USB']).
#  choice('plottype', 'TIME',
#	 options=['TIME', 'SCAN NUMBER', 'NONE']).

types.method('rf').
  string('fieldname', ' ').
  choice('freqgrp', '3mm-LSB',
	 options=['3mm-LSB', '3mm-USB', '1mm-LSB', '1mm-USB', '1mm']).
  boolean('visnorm', T).
  boolean('bpnorm', F).
  integer('refant',1).
  integer('gibb', 2).
  integer('drop', 5). 
  integer('degamp',6).
  integer('degphase', 12);


types.method('phase').
  string('fieldnames', [' ']).
  choice('freqgrp', '3mm-LSB',
	 options=['3mm-LSB', '3mm-USB', '1mm-LSB', '1mm-USB', '1mm']).
  integer('refant',1).
  choice('phasetransfer', 'raw', options=['raw', 'curve', 'none']).
  vector_integer('rawspw', -1).
  integer('npointaver', 10).
  quantity('phasewrap', '250deg');

types.method('flux').
  string('fieldnames', [' ']).
  string('fixed',[' ']).
  choice('freqgrp', '3mm-LSB', 
	 options=['3mm-LSB', '3mm-USB', '1mm-LSB', '1mm-USB', '1mm']).
  string('timerange',[' '], help='pairs of time e.g 04h00m00 07h00m00').
  boolean('plot', F).
  integer('gibb',2).
  integer('drop',5).
  integer('numchancont', 64, help='Number of channels in the continuum spw');

types.method('amp').
  string('fieldnames', [' ']).
  choice('freqgrp', '3mm-LSB',
	 options=['3mm-LSB', '3mm-USB', '1mm-LSB', '1mm-USB', '1mm']);

types.method('uvt').
  string('fieldname',' ').
  integer('spwid',1).
  string('filename').
  choice('option', 'new', options=['new', 'append']);

types.method('global_resample').
    string('infile', '').
    string('outfile', '');


types.method('global_shadow').
    string('msname', '').
    boolean('trial', T).
    float('minsep', 15.0);
