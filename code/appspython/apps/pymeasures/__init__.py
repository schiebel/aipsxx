# __init__.py: Top level .py file for python measures interface
# Copyright (C) 2006
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
# $Id: __init__.py,v 1.1 2006/09/28 05:55:00 mmarquar Exp $

from _pymeasures import measures as _measures
from pyquanta import *

def is_measure( v):
    if isinstance(v, dict) and v.has_key("type"):
        return True
    return False

class measures(_measures):
    def __init__(self):
        _measures.__init__(self)
        self.dq = quanta()

    
    def direction(self, rf='', v0='0..', v1='90..', off=False):
        loc = { 'type': 'direction' , 'refer':  rf}
        loc['m0'] = self.dq.unit(v0)
        loc['m1'] = self.dq.unit(v1)
        if is_measure(off):
            if not off['type'] == "direction":
                raise TypeError('Illegal offset type specified.')
        return self.measure(loc, rf, off)

    def measure(self, v, rf, off=False):
        if not off: off = {}
        return _measures.measure(self, v, rf, off)
        
    def position(self, rf='', v0='0..', v1='90..', v2='0m', off=False):
        loc = { 'type': 'position' , 'refer':  rf}
        loc['m0'] = self.dq.unit(v0)
        loc['m1'] = self.dq.unit(v1)
        loc['m2'] = self.dq.unit(v2)
        if is_measure(off):
            if not off['type'] == "position":
                raise TypeError('Illegal offset type specified.')
        return self.measure(loc, rf, off)

    def epoch(self, rf='', v0='0.0d', off=False):
        loc = { 'type': 'epoch' , 'refer':  rf}
        loc['m0'] = self.dq.quantity(v0);
        if is_measure(off):
            if not off['type'] == "epoch":
                raise TypeError('Illegal offset type specified.')        
        return self.measure(loc, rf, off);

    def frequency(self, rf='', v0='0Hz', off=False):
        loc = { 'type': "frequency",
                'refer': rf,
                'm0': self.dq.quantity(v0) }
        if is_measure(off):
            if not off['type'] == "frequency":
                raise TypeError('Illegal offset type specified.')        
        return self.measure(loc, rf, off);

    def doppler(self, rf='', v0='0', off=False):
        loc = { 'type': "doppler",
                'refer': rf,
                'm0': self.dq.quantity(v0) }
        if is_measure(off):
            if not off['type'] == "doppler":
                raise TypeError('Illegal offset type specified.')        
        return self.measure(loc, rf, off);

    def radialvelocity(self, rf='', v0='0m/s', off=False):
         loc = { 'type': "radialvelocity",
                'refer': rf,
                'm0': self.dq.quantity(v0) }
         if is_measure(off):
             if not off['type'] == "radialvelocity":
                 raise TypeError('Illegal offset type specified.')
         return self.measure(loc, rf, off);

    def baseline(self, rf='', v0='0..', v1='', v2='', off=False):
        
        loc = { 'type': "baseline", 'refer': rf }
        loc['m0'] = self.dq.unit(v0)
        loc['m1'] = self.dq.unit(v1)
        loc['m2'] = self.dq.unit(v2)
        if is_measure(off):
            if not off['type'] == "doppler":
                raise TypeError('Illegal offset type specified.')
        return self.measure(loc, rf, off);

    def uvw(self, rf='', v0='0..', v1='', v2='', off=False):
        loc = { 'type': "uvw", 'refer': rf }
        loc['m0'] = self.dq.unit(v0)
        loc['m1'] = self.dq.unit(v1)
        loc['m2'] = self.dq.unit(v2)
        if is_measure(off):
            if not off['type'] == "uvw":
                raise TypeError('Illegal offset type specified.')
        return self.measure(loc, rf, off);
       
    def earthmagnetic(self, rf='', v0='0G', v1='0..', v2='90..', off=False):
        loc = { 'type': "earthmagnetic", 'refer': rf }
        loc['m0'] = self.dq.unit(v0)
        loc['m1'] = self.dq.unit(v1)
        loc['m2'] = self.dq.unit(v2)
        if is_measure(off):
            if not off['type'] == "earthmagnetic":
                raise TypeError('Illegal offset type specified.')
        return self.measure(loc, rf, off);
       

    def tofrequency(self, rf, v0, rfq):
        if is_measure(rfq) and rfq['type'] == 'frequency':
            rfq = rfq['m0']
        if is_measure(v0) and  v0['type'] == 'doppler' \
               and  is_quantity(rfq) \
               and  self.dq.compare(rfq, self.dq.quantity(1.,'Hz')):
            return self.doptofreq(v0,rf, rfq)
        else:
            raise TypeError('Illegal Doppler or rest frequency specified')

    def torestfrequency(self, v0, d0):
        if is_measure(v0) and  v0['type'] == 'frequency' \
               and is_measure(d0) and d0['type'] == 'doppler':
            return self.torest(v0, d0);
        else:
            raise TypeError('Illegal Doppler or rest frequency specified')
       

    def todoppler(self, rf, v0, rfq=False):
        if is_measure(rfq) and rfq['type'] == 'frequency':
            rfq = rfq['m0']
        if is_measure(v0):
            if v0['type'] == 'radialvelocity':
                return self.todop(v0, dq.quantity(1.,'Hz'))
            elif v0['type'] == 'frequency' and  is_quantity(rfq) and \
                 self.dq.compare(rfq, dq.quantity(1.,'Hz')):
                return self.todop(v0, rfq)
            else:
                raise TypeError('Illegal Doppler or rest frequency specified')
        else:
            raise TypeError('Illegal Frequency specified')
                
    def toradialvelocity(self, rf, v0):
        if is_measure(v0) and v0['type'] == 'doppler':
            return self.doptorv(rv, v0)
        else:
            raise TypeError('Illegal Doppler specified')

    def touvw(self, v):
        if is_measure(v) and v['type'] == 'baseline':
           return _measures.uvw(self, v)
        else:
            raise TypeError('Illegal Baseline specified')

    def expand(self, v):
        if not is_measure(v) and \
               (v['type'] == 'baseline' or  v['type'] == 'uvw' or \
                v['type'] == 'position'): 
            raise TypeError("Can only expand baselines, positions, or uvw")
        v['type'] = "uvw"
        v['refer'] = "J2000"
        return _measures.expand(self, v)
        
    def asbaseline(self, pos):
        if not is_measure(pos) or (pos['type'] != 'position' and \
                                   pos['type'] != 'baseline'):
            raise TypeError('Non-position type for asbaseline input');
        if pos['type'] == 'position':
            loc = self.measure(pos, 'itrf');
            loc['type'] = 'baseline';
            return self.measure(loc, 'j2000');
        else:
            raise RuntimeError('Cannot convert baseline')
                
    def get_value(self, v):
        if  not is_measure(v):
            raise TypeError('Incorrect input type for get_value()')
        import re
        rx = re.compile("m\d+")
        out = []
        for key in v.keys():
            if re.match(rx, key):
                out.append(v.get(key))
        return out
    
    #alias
    def listcodes(self, ms):
        return self.alltyp(ms)
    
    
