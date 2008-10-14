# ms_meta.g: Standard meta information for ms
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
#   $Id: ms_meta.g,v 19.5 2005/11/24 00:50:12 kgolap Exp $
#

pragma include once

include 'types.g'

types.class('ms').includefile('ms.g');

# Constructors
types.method('ms.ctor_ms').
    ms('filename').
    boolean('readonly',T).
    boolean('lock',F);
# we keep these constructor arguments hidden for now
#    string('host').boolean('forcenewserver',F);

types.method('ctor_fitstoms').
    ms('msfile').fits('fitsfile').
    boolean('readonly', T).boolean('lock',F);
#    string('host').boolean('forcenewserver',F);

types.method('ctor_sdfitstoms').
    ms('msfile').fits('fitsfile').
    boolean('readonly', T).boolean('lock',F);
#    string('host').boolean('forcenewserver',F);

# Methods
types.method('ms.tofits').fits('fitsfile').
    choice('column', ['CORRECTED','MODEL','OBSERVED']).
    vector_integer('fieldid').
    vector_integer('spwid').
    integer('start', -1).
    integer('nchan', -1).
    integer('width', -1).
    boolean('writesyscal',F).
    boolean('multisource',F).
    boolean('combinespw',F).
    boolean('writestation',F);

types.method('ms.tosdfits').fits('fitsfile');

types.method('ms.open').ms('thems').boolean('readonly',T).boolean('lock',F);

types.method('ms.close');

types.method('ms.summary').boolean('verbose', F).
    record('header', '[=]', dir='out');

types.method('ms.name').string('return');

types.method('ms.nrow').boolean('selected',F).integer('return');

types.method('ms.iswritable').boolean('return');

types.method('ms.command').ms('msfile').string('command').
    boolean('readonly', T);

types.method('ms.selectinit').integer('arrayid', 1).
    integer('spectralwindowid', 0).boolean('reset',F);

types.method('ms.range').vector_string('items',[' ']).boolean('useflags',T).
    integer('blocksize',10).record('return', '[=]', dir='out');

types.method('ms.select').record('items').boolean('return');

types.method('ms.selecttaql').string('msselect').boolean('return');

types.method('ms.getdata').vector_string('items',[' ']).boolean('ifraxis',F).
    integer('ifraxisgap',0).integer('increment',1).boolean('average',F).
    record('return', '[=]', dir='out');

types.method('ms.putdata').record('items').boolean('return');

types.method('ms.iterinit').vector_string('columns',[' ']).float('interval',0).
    integer('maxrows',0).boolean('adddefaultsortcolumns',T).boolean('return');

types.method('ms.iterorigin').boolean('return');

types.method('ms.iternext').boolean('return');

types.method('ms.iterend').boolean('return');

types.method('ms.selectchannel').integer('nchan').integer('start',1).
    integer('width',1).integer('inc',1).boolean('return');

types.method('ms.selectpolarization').vector_string('wantedpol',[' ']).
    boolean('return');

types.method('ms.createflaghistory').integer('numlevel', 2).boolean('return');

types.method('ms.saveflags').boolean('newlevel', F);

types.method('ms.restoreflags').integer('level', 0).boolean('return');

types.method('ms.flaglevel').integer('return');

types.method('ms.fillbuffer').string('item').boolean('ifraxis',F).
    boolean('return');

types.method('ms.diffbuffer').string('direction').integer('window').
    record('return', '[=]', dir='out');

types.method('ms.getbuffer').record('return', '[=]', dir='out');

types.method('ms.clipbuffer').float('pixellevel').float('timelevel').
    float('channellevel').boolean('return');

types.method('ms.setbufferflags').record('flags').boolean('return');

types.method('ms.writebufferflags').boolean('return');

types.method('ms.clearbuffer').boolean('return');

types.method('ms.lister').string('starttime').string('stoptime'); 

types.method('ms.concatenate').
      string('msfile').
      quantity('freqtol', '1Hz').
      quantity('dirtol','1marcsec');


types.method('ms.split').
      string('ouputms').
      vector_integer('fieldids', [-1]).
      vector_integer('spwids', [-1]).
      vector_integer('nchan', [-1]).
      vector_integer('start', [1]).
      vector_integer('step', [1]).
      vector_integer('antennaids', [-1]).
      vector_string('antennanames', ['']).
      quantity('timebin', '-1s').
      string('timerange','').
  choice('whichcol', 'DATA', options=['DATA', 'MODEL_DATA', 'CORRECTED_DATA']);

types.method('ms.uvlsf').
      vector_integer('fldid',[]).
      vector_integer('spwid',[]).
      vector_integer('chans',[]).
      float('solint',0.0).
      integer('fitorder',0).
      choice('mode','subtract',options=['subtract','replace','model']);

types.method('ms.ptsrc').
      vector_integer('fldid',[]).
      vector_integer('spwid',[]);

# Global functions
 
types.method('global_is_ms').
   tool('tool').
   boolean('return');

types.method('global_msfiles').
   string('files', default='.', allowunset=F).
   boolean('strippath', T, allowunset=F).
   vector_string('return', help='A Glish vector of strings');



types.method('global_mstest').
   boolean('return');



