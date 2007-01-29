# vlafiller_meta.g: Info used by the toolmanager to make a gui for the vlafiller
#
#   Copyright (C) 1999,2000,2001
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
#   $Id: vlafiller_meta.g,v 19.1 2005/01/07 22:55:10 kgolap Exp $
#
#----------------------------------------------------------------------------

pragma include once

include 'types.g';
include 'unset.g';

const _vlafiller_hosthelp := 
  'The computer to run this server on, unset -> localhost';
const _vlafiller_devicehelp := 
  'Unix tape device name eg., /dev/nst0 (Linux) or /dev/rmt/0ln (Solaris)';
const _vlafiller_fileshelp := 'Which tape files to read. eg., [1, 2] -> the first two files';
const _vlafiller_projecthelp := 
  'The case insensitive project name eg., ab123. unset -> all projects';
const _vlafiller_starthelp :=
  'The start of the timerange eg., 31Dec00/00:00:00.123 unset -> the start of the observation';
const _vlafiller_stophelp := 
  'The end of the timerange eg., 31-Dec-2000/23:59:59.876 unset -> the end of the observation';
const _vlafiller_centerfrequencyhelp := 
  'The centre of the frequency band eg., 1.4GHz. unset -> all frequencies.';
const _vlafiller_bandwidthhelp := 
  'The range of allowed frequencies eg., 200MHz. Only data entirely within the band is selected. unset -> all frequencies.';
const _vlafiller_sourcehelp := 
  'Case insensitive source name eg., ngc1234. unset -> all sources';
const _vlafiller_qualifierhelp :=
  'Additional qualifier on the source name eg., 1. unset -> all qualifiers';
const _vlafiller_subarrayhelp := 
  'Which subarray to use. Zero selects all subarrays';
const _vlafiller_calcodehelp := 
  'Selects calibrators with the specified code. * matches all calibrators';

types.class('vlafiller').includefile('vlafiller.g');

types.method('ctor_vlafiller').
  string('host', default=unset, allowunset=T, help=_vlafiller_hosthelp).
  boolean('forcenewserver', F);

types.method('tapeinput').
  file('device', '/dev/tape', help=_vlafiller_devicehelp).
  vector_integer('files', [1], help=_vlafiller_fileshelp);

types.method('diskinput').
  file('filename', 'default.vla');

types.method('onlineinput');

types.method('output').
  ms('msname', 'default.ms').
  boolean('overwrite', F);

types.method('selectproject').
  string('project', default=unset, allowunset=T, help=_vlafiller_projecthelp);

types.method('selecttime').
  epoch('start', default=unset, dir='in', allowunset=T, options='TAI',
	help=_vlafiller_starthelp).
  epoch('stop', default=unset, dir='in', allowunset=T, options='TAI',
	help=_vlafiller_stophelp);

types.method('selectfrequency').
  quantity('centerfrequency', default=unset, dir='in', options='freq', 
	   allowunset=T, help=_vlafiller_centerfrequencyhelp).
  quantity('bandwidth', default=unset, dir='in', options='freq',
	   allowunset=T, help=_vlafiller_bandwidthhelp);

types.method('selectband').
  choice('bandname', 'L', options="4 P L C X U K Q");

types.method('selectsource').
  string('source', default=unset, allowunset=T, help=_vlafiller_sourcehelp).
  integer('qualifier', default=unset, allowunset=T,
	  help=_vlafiller_qualifierhelp);

types.method('selectsubarray').
  choice('subarray', '0', options="0 1 2 3 4 5", help=_vlafiller_subarrayhelp);

types.method('selectcalibrator').
  choice('calcode', '*', options="* A B C T P V N Y G",
	 help=_vlafiller_calcodehelp);

types.method('fill').
  boolean('verbose', F).
  boolean('async', F);

# Global functions

types.method('global_vlafillerfromtape').
  file('device', '/dev/tape', help=_vlafiller_devicehelp).
  vector_integer('files', [1], help=_vlafiller_fileshelp).
  ms('msname', 'default.ms').
  boolean('overwrite', F).
  string('project', default=unset, allowunset=T, help=_vlafiller_projecthelp).
  epoch('start', default=unset, dir='in', allowunset=T, options='TAI',
	help=_vlafiller_starthelp).
  epoch('stop', default=unset, dir='in', allowunset=T, options='TAI',
	help=_vlafiller_stophelp).
  choice('bandname', '*', options="* 4 P L C X U K Q").
  string('source', default=unset, allowunset=T, help=_vlafiller_sourcehelp).
  boolean('verbose', F).
  boolean('async', T).
  string('host', help='The computer with the tape drive, unset -> localhost',
	 default=unset, allowunset=T);

types.method('global_vlafillerfromdisk').
  file('filename', 'default.vla').
  ms('msname', 'default.ms').
  boolean('overwrite', F).
  string('project', default=unset, allowunset=T, help=_vlafiller_projecthelp).
  epoch('start', default=unset, dir='in', allowunset=T, options='TAI',
	help=_vlafiller_starthelp).
  epoch('stop', default=unset, dir='in', allowunset=T, options='TAI',
	help=_vlafiller_stophelp).
  choice('bandname', '*', options="* 4 P L C X U K Q").
  string('source', default=unset, allowunset=T, help=_vlafiller_sourcehelp).
  boolean('verbose', F).
  boolean('async', F);

types.method('global_vlafilleroldweights').
  ms('msname', 'default.ms');

types.method('global_vlafillerdemo');

types.method('global_vlafillertest');
