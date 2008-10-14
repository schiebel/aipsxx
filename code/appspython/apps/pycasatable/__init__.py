# __init__.py: Top level .py file for python table interface
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
# $Id: __init__.py,v 1.4 2006/09/20 02:38:41 gvandiep Exp $

try:
    import numpy.core as NUM
except ImportError:
    try:
        import numarray as NUM
    except ImportError:
        raise ImportError("You need to have numpy or numarray installed")

from table import table
from table import tablecommand
from tableiter import tableiter
from tableindex import tableindex
from tablecolumn import tablecolumn
from _pycasatable import tablerow
from tableutil import *

def welcome():
    return """Welcome to pycasatable - the AIPS++ table interface

Type commands() to get a list of all available commands."""
