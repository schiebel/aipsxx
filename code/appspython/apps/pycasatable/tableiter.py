# tableiter.py: Python tableiter functions
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
# $Id: tableiter.py,v 1.2 2006/09/26 04:45:01 gvandiep Exp $

# Make interface to class TableIterProxy available.
from _pycasatable import TableIter
import table

class tableiter(TableIter):
    """
        The Python interface to AIPS++ table iterators
    """

    def __init__(self, table, columns, order='', sort=True):
        st = sort;
        if isinstance(sort, bool):
            st = 'heapsort';
            if not sort:
                st = 'nosort'
        cols = columns;
        if isinstance(cols, str):
            cols= [cols] ;
        TableIter.__init__ (self, table, cols, order, st);
    
    def __iter__ (self):
        # __iter__ is needed
        return self;

    def next (self):
        # next returns a Table object, so turn that into table.
        return table.table (self._next(), _oper=3);
            
