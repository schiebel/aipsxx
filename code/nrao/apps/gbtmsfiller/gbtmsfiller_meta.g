# gbtmsfiller_meta.g: Standard meta information for gbtmsfiller.g
#
#   Copyright (C) 1999,2000,2001,2002,2003
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
#   $Id: gbtmsfiller_meta.g,v 19.3.10.1 2006/11/28 19:03:56 bgarwood Exp $

pragma include once

include 'types.g';

types.class('gbtmsfiller').includefile('gbtmsfiller.g');

# Constructors
types.method('ctor_gbtmsfiller');

types.method('isattached').
    boolean('return');

types.method('fillall').
    boolean('return');

types.method('fillnext').
    boolean('return');

types.method('more').
    boolean('return');

types.method('update').
    boolean('return');

types.method('status').
    record('return');

types.method('setproject').
    directory('project',default='.').
    boolean('return');

types.method('project').
    string('return');

types.method('setbackend').
    choice('backend',options=['ANY','ACS','DCR','HOLO','SP'],default='ANY').
    boolean('return');

types.method('backend').
    string('return');

types.method('setmsdirectory').
    directory('msdirectory',default='').
    boolean('return');

types.method('msdirectory').
    directory('return');

types.method('setmsrootname').
    string('msrootname',default='').
    boolean('return');

types.method('msrootname').
    string('return');

types.method('setmintime').
    string('mintime',default='0d').
    boolean('return');

types.method('mintime').
    string('return');

types.method('setmaxtime').
    string('maxtime',default='3000-01-01').
    boolean('return');

types.method('maxtime').
    string('return');

types.method('setobject').
    string('object',default='*').
    boolean('return');

types.method('object').
    string('return');

types.method('setminscan').
    integer('minscan',default=-1).
    boolean('return');

types.method('minscan').
    integer('return');

types.method('setmaxscan').
    integer('maxscan',default=-1).
    boolean('return');

types.method('maxscan').
    integer('return');

types.method('setfillrawpointing').
    boolean('fillrawpointing',default=F).
    boolean('return');

types.method('fillrawpointing').
    boolean('return');

types.method('setfillrawfocus').
    boolean('fillrawfocus',default=F).
    boolean('return');

types.method('fillrawfocus').
    boolean('return');

types.method('setfilllags').
    boolean('filllags',default=F).
    boolean('return');

types.method('filllags').
    boolean('return');

types.method('setvv').
    choice('vv',options=['default','schwab','old','none'],default='schwab').
    boolean('return');

types.method('vv').
    string('return');

types.method('setsmooth').
    choice('smooth',options=['default','hanning','hamming','none'],default='hanning').
    boolean('return');

types.method('smooth').
    string('return');

types.method('setusehighcal').
    boolean('usehighcal',default=F).
    boolean('return');

types.method('usehighcal').
    string('boolean');

types.method('setcompresscalcols').
    boolean('compresscalcols',default=T).
    boolean('return');

types.method('compresscalcols').
    boolean('return');

types.method('newms').
    boolean('return');

types.method('type').
    string('return');

types.method('setusebias').
    boolean('usebias',default=F).
    boolean('return');

types.method('usebias').
    boolean('return');

types.method('setoneacsms').
    boolean('oneacsms',default=T).
    boolean('return');

types.method('oneacsms').
    boolean('return');

types.method('setdcbias').
    double('dcbias',default=0.0).
    boolean('return');

types.method('dcbias').
    double('return');

types.method('setminbiasfactor').
    integer('dcbias',default=-1).
    boolean('return');

types.method('minbiasfactor').
    integer('return');

types.method('setfixbadlags').
    boolean('fixbadlags',default=F).
    boolean('return');

types.method('fixbadlags').
    boolean('return');

