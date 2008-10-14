# catalog_meta.g: Meta information for AIPS++ catalog tool
# Copyright (C) 1999,2001,2002
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
#   $Id: catalog_meta.g,v 19.2 2004/08/25 01:05:34 cvsmgr Exp $

pragma include once;

include 'types.g';

types.class('catalog').includefile('catalog.g');

# constructor
types.method('ctor_catalog');

types.method('gui').
    boolean('refresh',F).
    vector_string('show_types',unset, allowunset=T).
    boolean('vscrollbarright',unset, allowunset=T).
    boolean('return');
types.method('cli').
    boolean('return');
types.method('canonicalize').
    string('file','.').
    string('return');
types.method('whatis').
    string('file','.').
    string('dir','.').
    record('return');
types.method('whatisfull').
    string('file','.').
    string('dir','.').
    record('return');
types.method('list').
    vector_string('files',".").
    vector_string('listtypes',"All").
    boolean('strippath',unset, allowunset=T).
    vector_string('return');
types.method('show').
    string('dir').
    vector_string('show_types',unset, allowunset=T).
    boolean('writestatus',T).
    boolean('return');
types.method('setmask').
    string('mask','').
    boolean('return');
types.method('getmask').
    string('return');
types.method('setconfirm').
    choice('confirm', 'yes', options=['yes', 'directory', 'no']).
    boolean('return');
types.method('getconfirm').
    boolean('return');
types.method('settablesizeoption').
    choice('tablesizeoption', 'shape', options=['no', 'bytes', 'shape']).
    boolean('return');
types.method('gettablesizeoption').
    string('return');
types.method('setalwaysshowdir').
    boolean('alwaysshowdir',T).
    boolean('return');
types.method('getalwaysshowdir').
    boolean('return');
types.method('setsortbytype').
    boolean('sortbytype',T).
    boolean('return');
types.method('getsortbytype').
    boolean('return');
types.method('refresh').
    boolean('return');
types.method('lastdirectory').
    string('return');
types.method('lastshowtypes').
    vector_string('return');
types.method('delete').
    vector_string('files').
    boolean('refreshgui', T).
    choice('confirm', unset, options=['yes', 'directory', 'no'], allowunset=T).
    boolean('return');
types.method('copy').
    string('file').
    string('newfile').
    choice('confirm', unset, options=['yes', 'directory', 'no'], allowunset=T).
    boolean('return');
types.method('rename').
    string('file').
    string('newfile').
    choice('confirm', unset, options=['yes', 'directory', 'no'], allowunset=T).
    boolean('return');
types.method('summary').
    string('file').
    boolean('return');
types.method('create').
    string('file').
    string('type','ascii').
    boolean('refreshgui', T).
    boolean('return');
types.method('edit').
    string('file').
    boolean('return');
types.method('execute').
    string('file').
    boolean('return');
types.method('view').
    string('file').
    boolean('return');
types.method('tool').
    string('file').
    boolean('return');
types.method('availabletypes').
    vector_string('return');
types.method('type').
    string('return');
types.method('done').
    boolean('return');
types.method('dismiss').
    boolean('return');
types.method('setselectcallback').
    function('fun').
    boolean('return');
types.method('selectcallback').
    function('return');

types.method('global_cat').
    string('dir').
    vector_string('show_types',unset, allowunset=T).
    boolean('writestatus',T).
    boolean('return');
types.method('global_icat').
    string('dir').
    boolean('return');
types.method('global_ccat').
    string('dir').
    boolean('return');
types.method('global_dcat').
    string('dir').
    boolean('return');
types.method('global_mscat').
    string('dir').
    boolean('return');
types.method('global_fcat').
    string('dir').
    boolean('return');
types.method('global_gcat').
    string('dir').
    boolean('return');
types.method('global_tcat').
    string('dir').
    boolean('return');
