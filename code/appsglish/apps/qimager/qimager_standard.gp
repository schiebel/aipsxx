# qimager_standard.gp: Standard plugins for AIPS++ qimager class
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
#   $Id: qimager_standard.gp,v 1.2 2004/08/25 01:48:37 cvsmgr Exp $
#

pragma include once

include 'qimager.g'
include 'calibrater.g'
include 'images.g';
include 'types.g';
include 'note.g';

qimager_standard := [=];
qimager_standard.init := function()
{
  types.class('qimager').group('calibrate').method('qimager.selfcal').group().
      tool('caltool', 'mycalibrater').
      image('model', '').
      table('complist', '');

  return T;
}

qimager_standard.attach := function(ref public)
{
    public.selfcal:=function(caltool, model='', complist='') {
      if(public.ft(model=model, complist=complist)&&
	 caltool.solve() && caltool.correct())
      {
        note('Selfcalibration done: CORRECTED DATA column updated');
        return T;
      }
      else {
        note('Selfcalibration failed');
        return F;
      }
    }

    public.type := function() {
	return 'qimager';
    }

    return T;
}

const qimager_standard := const qimager_standard;
