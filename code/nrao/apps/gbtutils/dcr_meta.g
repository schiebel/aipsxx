# dcr meta information
# Copyright (C) 1999,2000,2001,2003
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#

# include guard
pragma include once

include 'types.g';
dcr:='';
types.class('dcr').includefile('dcr.g');

#Constructor
types.method('ctor_dcr').table('filename',unset,allowunset=F);

#Methods
types.method('listscans');
types.method('type');
types.method('done');
types.method('getGO').integer('scan');
types.method('guessmode').integer('scan');
types.method('tsys').integer('scan').integer('receiver');
types.method('gauss').double('xarray').double('yarray').double('height').double('width').double('center').boolean('plotflag',T);
types.method('plot_tsrc_time').integer('scan').integer('receiver').double('cal_value',1);
types.method('plot_focus_time').integer('scan').
    choice('param',options=['SR_XP','SR_YP','SR_ZP','SR_XT','SR_YT','SR_ZT','ANTPOSPF','PF_FOCUS','PF_ROTATION'],default='SR_XP', allowunset=F);
types.method('focusScan').integer('scan').integer('receiver',0).double('cal_value',1).
    choice('param',options=['SR_XP','SR_YP','SR_ZP','SR_XT','SR_YT','SR_ZT','ANTPOSPF','PF_FOCUS','PF_ROTATION'],default='SR_XP', allowunset=F).
    integer('order',2).boolean('archive',F);
types.method('focus').string('filename');
types.method('tip').integer('scan').integer('receiver');
types.method('point1').integer('scan').integer('receiver').integer('xaxis').double('cal_value',1).integer('basepct',10).boolean('plotflag',T);
types.method('point4').integer('scan').integer('receiver').double('cal_value',1).boolean('plotflag',T);
types.method('point2').integer('scan').integer('receiver').double('cal_value',1);
types.method('test_srp').integer('scan').integer('receiver').integer('phase');
types.method('plot_phase_time').integer('scan').integer('receiver').integer('phase');
types.method('plot_phase_ra').integer('scan').integer('receiver').integer('phase');
types.method('plot_phase_dec').integer('scan').integer('receiver').integer('phase');
types.method('plot_RA_Dec').integer('scan');
types.method('get_tant').integer('scan').integer('receiver',1).double('cal_value',1);
types.method('plot_tant_time').integer('scan').integer('receiver',1).double('cal_value',1);
types.method('plot_sidelobe').integer('scan').integer('receiver',1).integer('basepct',10).integer('bottom',-70);
types.method('plot_tant_RA').integer('scan').integer('receiver',1).double('cal_value',1);
types.method('plot_tant_Dec').integer('scan').integer('receiver',1).double('cal_value',1);
types.method('plot_gain_time').integer('scan').integer('receiver');
types.method('plot_dap_time').integer('scan').string('colName');
types.method('baselinefit').double('xarray').double('yarray').integer('ord').integer('range').boolean('plotflag',T);
types.method('getscan').integer('scan').boolean('getFocus',F);
types.method('plotscans').integer('bscan').integer('escan').integer('receiver').integer('phase');
types.method('scanSummary');
