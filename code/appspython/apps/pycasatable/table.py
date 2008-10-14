# table.py: Python table functions
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
# $Id: table.py,v 1.6 2006/09/26 04:28:23 gvandiep Exp $

# Make interface to class TableProxy available.
from _pycasatable import Table

# A keywordset in a table can hold tables, but it is not possible to
# pass them around because a ValueHolder cannot deal with it.
# Therefore it is passed around as a string with a special prefix.
def _add_prefix (name):
    return name + 'Table: ';

def _remove_prefix (name):
    res = name;
    if (res.find ('Table: ') == 0):
        res = res.replace ('Table: ', '', 1);
    return res;

def reverse_axes (axes):
    l = [];
    for a in axes:
        l.append (a);
    l.reverse();
    return l;


# Execute a TaQL command on a table.
def tablecommand (command, tables=[]):
    tab = table(command, tables, _oper=2);
    result = tab._getcalcresult();
    # If result is empty, it was a normal TaQL command resulting in a table.
    # Otherwise it is a record containing calc values.
    if len(result) == 0:
        return tab;
    return result['values'];


class table(Table):
    """
        The Python interface to AIPS++ tables
    """

    def __init__(self, tablename, tabledesc=False, nrow=0, readonly=True,
                 lockoptions='default', ack=True, dminfo={}, endian='aipsrc',
                 memorytable=False, _oper=0, _delete=False):
        if _oper == 1:
            # This is the readascii constructor.
            tabname = _remove_prefix(tablename);
            Table.__init__ (self, tabname, tabledesc, nrow, readonly,
                            lockoptions, ack, dminfo, endian, memorytable);
            return;
        if _oper == 2:
            # This is the query constructor.
            Table.__init__ (self, tablename, tabledesc);
            return;
        if _oper == 3:
            # This is the constructor taking a Table (used by copy).
            Table.__init__ (self, tablename);
            return;
        tabname = _remove_prefix(tablename);
        lockopt = lockoptions;
        if isinstance(lockoptions, str):
            lockopt = {'option' : lockoptions};
        if not isinstance(tabledesc, dict):
            if (readonly):
                Table.__init__ (self, tabname, lockopt, 1);
                typstr = 'readonly';
            else:
                opt = 5;
                if _delete:
                    opt = 6;
                Table.__init__ (self, tabname, lockopt, opt);
                typstr = 'read/write';
            if ack:
                print 'Successful', typstr, 'open of', lockopt['option']+'-locked table', tabname+':', self.ncols(), 'columns,', self.nrows(), 'rows';
        else:
            memtype = 'plain';
            if (memorytable):
                memtype = 'memory';
            Table.__init__ (self, tabname, lockopt, endian,
                            memtype, nrow, tabledesc, dminfo);
            if ack:
                print 'Successful creation of', lockopt['option']+'-locked table', tabname+':', self.ncols(), 'columns,', self.nrows(), 'rows';


    def copy (self, newtablename, deep=False, valuecopy=False, dminfo={},
              endian='aipsrc', memorytable=False, copynorows=False):
        t = self._copy (newtablename, memorytable, deep, valuecopy,
                        endian, dminfo, copynorows);
        # copy returns a Table object, so turn that into table.
        return table(t, _oper=3);
    
    def selectrows (self, rownrs):
        t = self._selectrows (rownrs, name='');
        # selectrows returns a Table object, so turn that into table.
        return table(t, _oper=3);

    def isvarcol (self, columnname):
        desc = self.getcoldesc(columnname);
        return desc.has_key('ndim') and not desc.has_key('shape');

    def putcell (self, columnname, rownr, value):
        rnrs = rownr;
        if isinstance(rownr, int):
            rnrs = [rnrs];
        return self._putcell (columnname, rnrs, value);

    def getcellslice (self, columnname, rownr, blc, trc, inc=[]):
        return self._getcellslice (columnname, rownr,
                                   reverse_axes(blc), reverse_axes(trc),
                                   reverse_axes(inc));

    def getcolslice (self, columnname, blc, trc, inc=[],
                     startrow=0, nrow=-1, rowincr=1):
        return self._getcolslice (columnname,
                                  reverse_axes(blc), reverse_axes(trc),
                                  reverse_axes(inc),
                                  startrow, nrow, rowincr);

    def putcellslice (self, columnname, rownr, value, blc, trc, inc=[]):
        return self._putcellslice (columnname, rownr, value,
                                   reverse_axes(blc), reverse_axes(trc),
                                   reverse_axes(inc));

    def putcolslice (self, columnname, value, blc, trc, inc=[],
                     startrow=0, nrow=-1, rowincr=1):
        return self._putcolslice (columnname, value,
                                  reverse_axes(blc), reverse_axes(trc),
                                  reverse_axes(inc),
                                  startrow, nrow, rowincr);

    def getcolshapestring (self, columnname,
                           startrow=0, nrow=-1, rowincr=1):
        return self._getcolshapestring (columnname,
                                        startrow, nrow, rowincr,
                                        True);          #reverse_axes

    def keywordnames (self):
        return self._getfieldnames ('', '', -1);

    def colkeywordnames (self, columnname):
        return self._getfieldnames (columnname, '', -1);

    def fieldnames (self, keyword=''):
        if isinstance(keyword, str):
            return self._getfieldnames ('', keyword, -1);
        else:
            return self._getfieldnames ('', '', keyword);

    def colfieldnames (self, columnname, keyword=''):
        if isinstance(keyword, str):
            return self._getfieldnames (columnname, keyword, -1);
        else:
            return self._getfieldnames (columnname, '', keyword);

    def getkeyword (self, keyword):
        if isinstance(keyword, str):
            return self._getkeyword ('', keyword, -1);
        else:
            return self._getkeyword ('', '', keyword);

    def getcolkeyword (self, columnname, keyword):
        if isinstance(keyword, str):
            return self._getkeyword (columnname, keyword, -1);
        else:
            return self._getkeyword (columnname, '', keyword);

    def getkeywords (self):
        return self._getkeywords ('');

    def getcolkeywords (self, columnname):
        return self._getkeywords (columnname);

    def putkeyword (self, keyword, value, makesubrecord=False):
        val = value;
        if isinstance(val, table):
            val = _add_prefix (val.name());
        if isinstance(keyword, str):
            return self._putkeyword ('', keyword, -1, val, makesubrecord);
        else:
            return self._putkeyword ('', '', keyword, val, makesubrecord);

    def putcolkeyword (self, columnname, keyword, value, makesubrecord=False):
        if isinstance(value, table):
            value = 'Table:' + value.name;
        if isinstance(keyword, str):
            return self._putkeyword (columnname, keyword, -1,
                                      value, makesubrecord);
        else:
            return self._putkeyword (columnname, '', keyword,
                                      value, makesubrecord);

    def putkeywords (self, value):
        return self._putkeywords ('', value);

    def putcolkeywords (self, columnname, value):
        return self._putkeywords (columnname, value);

    def removekeyword (self, keyword):
        if isinstance(keyword, str):
            self._removekeyword ('', keyword, -1);
        else:
            self._removekeyword ('', '', keyword);

    def removecolkeyword (self, columnname, keyword):
        if isinstance(keyword, str):
            self._removekeyword (columnname, keyword, -1);
        else:
            self._removekeyword (columnname, '', keyword);


    def summary (self, recurse=False):
        print 'Table summary:', self.name();
        print 'Shape:', self.ncols(), 'columns by', self.nrows(), 'rows';
        print 'Info:', self.info();
        tkeys = self.getkeywords();
        if (len(tkeys) > 0):
            print 'Table keywords:', tkeys;
        columns = self.colnames();
        if (len(columns) > 0):
            print 'Columns:', columns;
            for column in columns:
                ckeys = self.getcolkeywords(column);
                if (len(ckeys) > 0):
                    print column, 'keywords:', ckeys;
        if (recurse):
            for key in tkeys.keys():
                value = tkeys[key];
                tabname = _remove_prefix (value);
                print 'Summarizing subtable:', tabname;
                lt = table(tabname);
                if (not lt.summary(recurse)):
                    break;
        return True;

    def query (self, query='', name='', sortlist='', columns=''):
        if query=='' and sortlist=='' and columns=='':
            raise ValueError('No selection done (arguments query, sortlist, and columns are empty)');
        command = 'select ';
        if columns != '':
            command += columns;
        command += ' from $1';
        if query != '':
            command += ' where ' + query;
        if sortlist != '':
               command += ' orderby ' + sortlist;
        if name != '':
            command += ' giving ' + name;
        return tablecommand(command, [self]);

    def calc (self, expr):
        return tablecommand('calc from $1 calc ' + expr, [self]);
                            
    def browse (self):
        try:
            import wxPython
        except ImportError:
            print 'wx not available'
            return
        from wxPython.wx import wxPySimpleApp
        import sys
        app = wxPySimpleApp()
        from wxtablebrowser import CasaTestFrame
        frame = CasaTestFrame(None, sys.stdout, self)
        frame.Show(True)
        app.MainLoop()

