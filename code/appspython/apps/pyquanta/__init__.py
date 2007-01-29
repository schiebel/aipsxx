# __init__.py: Top level .py file for python quanta interface
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
# $Id: __init__.py,v 1.2 2006/09/28 06:22:11 mmarquar Exp $

from _pyquanta import quanta as _quanta

def is_quantity(v, u=None):
    if isinstance(v, dict) and v.has_key("unit") and v.has_key("value"):
        return True
    return False

class quanta(_quanta):
    def __init__(self):
        _quanta.__init__(self)

    def _makequanta(self, target, u=''):
        if is_quantity(target): return target
        elif isinstance(target, str):
            return self.quant([target])
        elif isinstance(target, list) or isinstance(target, tuple):
            if isinstance(target[-1], str):
                return self.quant(target)
            elif isinstance(target[-1], float):
                return _quanta.unit(self, target, u)
            else:
                raise ValueError("Value has to be a (list of) string or " \
                                 "(list of) double and a unit string")
        elif isinstance(target, float) and isinstance(u, str):
            return _quanta.unit(self, [target], u)
        return None

    def get_value(self, v):
         val = self._makequanta(v)
         return val['value']

    def get_unit(self, v):
         val = self._makequanta(v)
         return val['unit']

    def convert(self, v='1', out=''):
        val = self._makequanta(v)
        outval =  self._makequanta(out)
        return self.qfunc2(val, outval, 5)

    def canon(self, v):
        val = self._makequanta(v)
        if val is not None:
            return self.qfunc1(val, 9)

    def unit(self, v=1.0, name=''):
        return self._makequanta(v, name)

    quantity = unit
    
    def define(self, name, v='1'):
        _quanta.define(name, self._makequanta(v))

    def time(self, v, prec=0, form="", show=False):
        val = self._makequanta(v)
        return _quanta.time(self, val, form, prec, show)

    def angle(self, v, prec=0, form="", show=False):
        val = self._makequanta(v)
        return _quanta.angle(self, val, form, prec, show)


    def sin(self, v):
        val = self._makequanta(v)
        if val is not None:
            return self.qfunc1(val, 0)
    def cos(self, v):
        val = self._makequanta(v)
        if val is not None:
            return self.qfunc1(val, 1)
    def tan(self, v):
        val = self._makequanta(v)
        if val is not None:
            return self.qfunc1(val, 2)
    def asin(self, v):
        val = self._makequanta(v)
        if val is not None:
            return self.qfunc1(val, 3)
    def acos(self, v):
        val = self._makequanta(v)
        if val is not None:
            return self.qfunc1(val, 4)
    def atan(self, v):
        val = self._makequanta(v)
        if val is not None:
            return self.qfunc1(val, 5)
    def abs(self, v):
        val = self._makequanta(v)
        if val is not None:
            return self.qfunc1(val, 6)
    def ceil(self, v):
        val = self._makequanta(v)
        if val is not None:
            return self.qfunc1(val, 7)
    def floor(self, v):
        val = self._makequanta(v)
        if val is not None:
            return self.qfunc1(val, 8)
    def log(self, v):
        val = self._makequanta(v)
        if val is not None:
            return self.qfunc1(val, 10)
    def log10(self, v):
        val = self._makequanta(v)
        if val is not None:
            return self.qfunc1(val, 11)
    def exp(self, v):
        val = self._makequanta(v)
        if val is not None:
            return self.qfunc1(val, 12)
    def sqrt(self, v):
        val = self._makequanta(v)
        if val is not None:
            return self.qfunc1(val, 13)

    def atan2(self, v, w):
        self._makequanta(v)
        return self.qfunc2(self._makequanta(v), self._makequanta(w), 0)
    def mul(self, v, w):
        self._makequanta(v)
        return self.qfunc2(self._makequanta(v), self._makequanta(w), 1)
    def div(self, v, w):
        self._makequanta(v)
        return self.qfunc2(self._makequanta(v), self._makequanta(w), 2)
    def sub(self, v, w):
        self._makequanta(v)
        return self.qfunc2(self._makequanta(v), self._makequanta(w), 3)
    def add(self, v, w):
        self._makequanta(v)
        return self.qfunc2(self._makequanta(v), self._makequanta(w), 4)

