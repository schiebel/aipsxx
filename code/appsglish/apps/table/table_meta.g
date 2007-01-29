# table_meta.g: Standard meta information for table
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
#   $Id: table_meta.g,v 19.9 2006/11/10 01:26:06 gvandiep Exp $
#

pragma include once;

include 'types.g';

types.class('table').includefile('table.g');

types.method('ctor_table').
    table('tablename').
    record('tabledesc',unset).
    integer('nrow',0).
    boolean('readonly',T).
    choice('lockoptions', 'default',
	   options=['default','auto','autonoread','user','usernoread',
		    'permanent','permanentwait']).
    boolean('ack',T).
    record('dminfo',[=]).
    choice('endian', 'aipsrc', options=['aipsrc','local','big','little']).
    boolean('memorytable',F);
types.method('ctor_tablefromascii').
    table('tablename').
    file('asciifile', options='ascii').
    file('headerfile','', options='ascii').
    boolean('autoheader', F).
    vector_integer('autoshape', []).
    string('sep', ' ').
    string('commentmarker', '').
    integer('firstline', 1).
    integer('lastline', -1).
    vector_string('columnnames', "").
    vector_string('datatypes', "").
    boolean('readonly',T).
    choice('lockoptions', 'default',
	   options=['default','auto','autonoread','user','usernoread',
		    'permanent','permanentwait']).
    boolean('ack',T);
types.method('ctor_tablefromfits').
    table('tablename').
    file('fitsfile', options='FITS').
    integer('whichhdu', 1).
    choice('storage', 'standard', options=['standard', 'incremental']).
    choice('convention', options=['sdfits', 'none']).
    boolean('readonly',T).
    choice('lockoptions', 'default',
	   options=['default','auto','autonoread','user','usernoread',
		    'permanent','permanentwait']).
    boolean('ack',T);
types.method('toascii').
    file('asciifile', options='ascii').
    file('headerfile','', options='ascii').
    string('columns', '').
    string('sep', ' ');
types.method('query').
    string('query', '').
    string('name', '').
    string('sortlist', '').
    string('columns', '').
    string('style', '').
    tool('return', dir='out');
types.method('calc').
    string('expr').
    string('style', '').
    record('return', dir='out');
types.method('selectrows').
    vector_integer('rownrs').
    string('name', '').
    tool('return', dir='out');
types.method('browse');
types.method('flush').
    boolean('recursive',F).
    boolean('return', dir='out');
types.method('resync').
    boolean('return', dir='out');
types.method('close').
    boolean('return', dir='out');
types.method('copy').
    table('newtablename').
    boolean('deep',F).
    boolean('valuecopy',F).
    record('dminfo',[=]).
    choice('endian', 'aipsrc', options=['aipsrc','local','big','little']).
    boolean('memorytable',F).
    boolean('returnobject',F).
    boolean('copynorows',F).
    tool('return', dir='out');
types.method('copyrows').
    record('outtable').
    integer('startrowin',1).
    integer('startrowout',-1).
    integer('nrow',-1).
    boolean('return', dir='out');
types.method('done').
    boolean('return', dir='out');
types.method('iswritable').
    boolean('return', dir='out');
types.method('endianformat').
    string('return', dir='out');
types.method('lock').
    boolean('write',T).
    integer('nattempts',0).
    boolean('return', dir='out');
types.method('unlock').
    boolean('return', dir='out');
types.method('datachanged').
    boolean('return', dir='out');
types.method('haslock').
    boolean('write',T).
    boolean('return', dir='out');
types.method('lockoptions').
    record('return', dir='out');
types.method('ismultiused').
    boolean('checksubtables',F).
    boolean('return', dir='out');
types.method('name').
    table('return', dir='out');
types.method('info').
    record('return', dir='out');
types.method('putinfo').
    record('value').
    boolean('return', dir='out');
types.method('addreadmeline').
    string('value').
    boolean('return', dir='out');
types.method('summary').
    boolean('recurse',F).
    boolean('return', dir='out');
types.method('setmaxcachesize').
    string('columnname').
    integer('nbytes').
    boolean('return', dir='out');
types.method('rownumbers').
    tool('tab').
    vector_integer('return', dir='out');
types.method('colnames').
    vector_string('return', dir='out');
types.method('isscalarcol').
    string('columnname').
    boolean('return', dir='out');
types.method('isvarcol').
    string('columnname').
    boolean('return', dir='out');
types.method('coldatatype').
    string('columnname').
    string('return', dir='out');
types.method('colarraytype').
    string('columnname').
    string('return', dir='out');
types.method('ncols').
    integer('return', dir='out'); 
types.method('nrows').
    integer('return', dir='out');
types.method('addrows').
    integer('nrow',1).
    boolean('return', dir='out');
types.method('removerows').
    integer('rownrs').
    boolean('return', dir='out');
types.method('addcols').
    record('desc').
    record('dminfo').
    boolean('return', dir='out');
types.method('renamecol').
    string('oldname').
    string('newname').
    boolean('return', dir='out');
types.method('removecols').
    vector_string('columnnames').
    boolean('return', dir='out');
types.method('iscelldefined').
    string('columnname').
    integer('rownr').
    boolean('return', dir='out');
types.method('getcell').
    string('columnname').
    integer('rownr').
    untyped('return', dir='out');
types.method('getcellslice').
    string('columnname').
    integer('rownr').
    vector_integer('blc').
    vector_integer('trc').
    vector_integer('inc').
    untyped('return', dir='out');
types.method('getcol').
    string('columnname').
    integer('startrow',1).
    integer('nrow', -1).
    integer('rowincr',1).
    untyped('return', dir='out');
types.method('getvarcol').
    string('columnname').
    integer('startrow',1).
    integer('nrow', -1).
    integer('rowincr',1).
    record('return', dir='out');
types.method('getcolslice').
    string('columnname').
    vector_integer('blc').
    vector_integer('trc').
    vector_integer('inc').
    integer('startrow', 1).
    integer('nrow',-1).
    integer('rowincr',1).
    untyped('return', dir='out');
types.method('putcell').
    string('columnname').
    vector_integer('rownr').
    untyped('value').
    boolean('return', dir='out');
types.method('putcellslice').
    string('columnname').
    integer('rownr').
    vector_integer('blc').
    vector_integer('trc').
    vector_integer('inc').
    untyped('value').
    boolean('return', dir='out');
types.method('putcol').
    string('columnname').
    integer('startrow',1).
    integer('nrow', -1).
    integer('rowincr',1).
    untyped('value').
    boolean('return', dir='out');
types.method('putvarcol').
    string('columnname').
    integer('startrow',1).
    integer('nrow', -1).
    integer('rowincr',1).
    record('value').
    boolean('return', dir='out');
types.method('putcolslice').
    string('columnname').
    integer('rownr').
    vector_integer('blc').
    vector_integer('trc').
    vector_integer('inc').
    integer('startrow', 1).
    integer('row',-1).
    integer('rowincr',1).
    untyped('value').
    boolean('return', dir='out');
types.method('getcolshapestring').
    string('columnname').
    integer('startrow', 1).
    integer('nrow',-1).
    integer('rowincr',1).
    string('return', dir='out');
types.method('getkeyword').
    string('keyword').
    untyped('return', dir='out');
types.method('getkeywords').
    record('return', dir='out');
types.method('getcolkeyword').
    string('columnname').
    string('keyword').
    untyped('return', dir='out');
types.method('getcolkeywords').
    string('columnname').
    record('return', dir='out');
types.method('putkeyword').
    string('keyword').
    untyped('value').
    boolean('makesubrecord', F).
    boolean('return', dir='out');
types.method('putkeywords').
    record('value').
    boolean('return', dir='out');
types.method('putcolkeyword').
    string('columnname').
    string('keyword').
    untyped('value').
    boolean('makesubrecord', F).
    boolean('return', dir='out');
types.method('putcolkeywords').
    string('columnname').
    untyped('value').
    boolean('return', dir='out');
types.method('removekeyword').
    string('keyword').
    boolean('return', dir='out');
types.method('removecolkeyword').
    string('columnname').
    string('keyword').
    boolean('return', dir='out');
types.method('keywordnames').
    vector_string('return', dir='out');
types.method('colkeywordnames').
    string('columnname').
    vector_string('return', dir='out');
types.method('fieldnames').
    string('keyword','').
    vector_string('return', dir='out');
types.method('colfieldnames').
    string('columnname').
    string('keyword','').
    vector_string('return', dir='out');
types.method('getdminfo').
    record('return', dir='out');
types.method('getdesc').
    boolean('actual',T).
    record('return', dir='out');
types.method('getcoldesc').
    string('columnname').
    record('return', dir='out');


types.method('global_tablecreatescalarcoldesc').
    string('columnname').
    untyped('value').
    string('datamanagertype','').
    string('datamanagergroup','').
    integer('options',0).
    integer('maxlen',0).
    string('comment','').
    record('return', dir='out');
types.method('global_tablecreatearraycoldesc').
    string('columnname').
    untyped('value').
    integer('ndim',0).
    vector_integer('shape').
    string('datamanagertype','').
    string('datamanagergroup','').
    integer('options',0).
    integer('maxlen',0).
    string('comment','').
    record('return', dir='out');
types.method('global_tablecreatedesc').
    record('columndesc1').
    record('return', dir='out');
types.method('global_tabledefinehypercolumn').
    record('tabdesc', dir='inout').
    string('name').
    integer('ndim').
    vector_string('datacolumns').
    vector_string('coordcolumns', unset, allowunset=T).
    vector_string('idcolumns', unset, allowunset=T).
    boolean('return', dir='out');
types.method('global_tablecommand').
    string('comm').
    string('style', '').
    boolean('return', dir='out');
types.method('global_tabledelete').
    table('tablename').
    boolean('checksubtables',T).
    boolean('ack',T).
    boolean('return', dir='out');
types.method('global_tablecloseall').
    boolean('return', dir='out');
types.method('global_tablerename').
    table('tablename').
    table('newtablename').
    boolean('return', dir='out');
types.method('global_tablecopy').
    table('tablename').
    table('newtablename').
    boolean('deep',F).
    boolean('return', dir='out');
types.method('global_tableinfo').
    table('tablename').
    boolean('return', dir='out');
types.method('global_tableexists').
    table('tablename').
    boolean('return', dir='out');
types.method('global_tableiswritable').
    table('tablename').
    boolean('return', dir='out');
types.method('global_tableopentables').
    vector_string('return', dir='out');



types.class('tablecolumn').includefile('table.g');

types.method('ctor_tablecolumn').
    tool('tab', dir='in').
    string('column');
types.method('close').
    boolean('return', dir='out');
types.method('done').
    boolean('return', dir='out');
types.method('table').
    tool('return', dir='out');
types.method('name').
    string('return', dir='out');
types.method('isscalar').
    boolean('return', dir='out');
types.method('isvar').
    boolean('return', dir='out');
types.method('datatype').
    string('return', dir='out');
types.method('arraytype').
    string('return', dir='out');
types.method('nrows').
    integer('return', dir='out');
types.method('iscelldefined').
    integer('rownr').
    boolean('return', dir='out');
types.method('getcell').
    integer('rownr').
    untyped('return', dir='out');
types.method('getcellslice').
    integer('rownr').
    vector_integer('blc').
    vector_integer('trc').
    vector_integer('inc').
    untyped('return', dir='out');
types.method('getcol').
    integer('startrow',1).
    integer('nrow', -1).
    integer('rowincr',1).
    untyped('return', dir='out');
types.method('getvarcol').
    integer('startrow',1).
    integer('nrow', -1).
    integer('rowincr',1).
    record('return', dir='out');
types.method('getcolslice').
    vector_integer('blc').
    vector_integer('trc').
    vector_integer('inc').
    integer('startrow', 1).
    integer('nrow',-1).
    integer('rowincr',1).
    untyped('return', dir='out');
types.method('putcell').
    vector_integer('rownr').
    untyped('value').
    boolean('return', dir='out');
types.method('putcellslice').
    integer('rownr').
    vector_integer('blc').
    vector_integer('trc').
    vector_integer('inc').
    untyped('value').
    boolean('return', dir='out');
types.method('putcol').
    integer('startrow',1).
    integer('nrow', -1).
    integer('rowincr',1).
    untyped('value').
    boolean('return', dir='out');
types.method('putvarcol').
    integer('startrow',1).
    integer('nrow', -1).
    integer('rowincr',1).
    record('value').
    boolean('return', dir='out');
types.method('putcolslice').
    integer('rownr').
    vector_integer('blc').
    vector_integer('trc').
    vector_integer('inc').
    integer('startrow', 1).
    integer('row',-1).
    integer('rowincr',1).
    untyped('value').
    boolean('return', dir='out');
types.method('getshapestring').
    integer('startrow', 1).
    integer('nrow',-1).
    integer('rowincr',1).
    string('return', dir='out');
types.method('getkeyword').
    string('keyword').
    untyped('return', dir='out');
types.method('getkeywords').
    record('return', dir='out');
types.method('putkeyword').
    string('keyword').
    untyped('value').
    boolean('makesubrecord', F).
    boolean('return', dir='out');
types.method('putkeywords').
    record('value').
    boolean('return', dir='out');
types.method('removekeyword').
    string('keyword').
    boolean('return', dir='out');
types.method('keywordnames').
    vector_string('return', dir='out');
types.method('fieldnames').
    string('keyword','').
    vector_string('return', dir='out');
types.method('getdesc').
    boolean('actual',T).
    record('return', dir='out');
types.method('makeiter').
    string('order','').
    boolean('sort',T).
    tool('return', dir='out');
types.method('makeindex').
    boolean('sort',T).
    tool('return', dir='out');



types.class('tablerow').includefile('table.g');

types.method('ctor_tablerow').
    tool('tab', dir='in').
    vector_string('columns',unset).
    boolean('exclude',F);
types.method('set').
    tool('tab', dir='in').
    vector_string('columns',unset).
    boolean('exclude',F);
types.method('get').
    integer('rownr').
    record('return', dir='out');
types.method('put').
    integer('rownr').
    record('value').
    boolean('matchingfields',T).
    boolean('return', dir='out');
types.method('close').
    boolean('return', dir='out');
types.method('done').
    boolean('return', dir='out');



types.class('tableiterator').includefile('table.g');

types.method('ctor_tableiterator').
    tool('tab', dir='in').
    vector_string('columns').
    string('order','').
    boolean('sort',T);
types.method('table').
    tool('return', dir='out');
types.method('reset').
    boolean('return', dir='out');
types.method('next').
    boolean('return', dir='out');
types.method('terminate').
    boolean('return', dir='out');
types.method('close').
    boolean('return', dir='out');
types.method('done').
    boolean('return', dir='out');



types.class('tableindex').includefile('table.g');

types.method('ctor_tableindex').
    tool('tab', dir='in').
    vector_string('columns').
    boolean('sort',T);
types.method('set').
    tool('tab', dir='in').
    vector_string('columns').
    boolean('sort',T);
types.method('isunique').
    boolean('return', dir='out');
types.method('setchanged').
    vector_string('columns', as_string([])).
    boolean('return', dir='out');
types.method('rownr').
    record('key').
    integer('return', dir='out');
types.method('rownrs').
    record('key').
    record('upperkey', unset).
    boolean('lowerincl', T).
    boolean('upperincl', T).
    vector_integer('return', dir='out');
types.method('close').
    boolean('return', dir='out');
types.method('done').
    boolean('return', dir='out');
