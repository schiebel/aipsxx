# os_meta.g: Meta info for Os commands
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: os_meta.g,v 19.1 2004/08/25 01:35:06 cvsmgr Exp $
#

pragma include once;
 
include "types.g";
  
types.class('os').includefile('os.g');

types.method('ctor_os');

types.method('isvalidpathname').
    vector_string('pathname').
    vector_boolean('return');
types.method('fileexists').
    vector_string('file').
    boolean('follow').
    vector_boolean('return');
types.method('dir').
    directory('directoryname', '.').
    string('pattern', '').
    string('types', '').
    boolean('all', F).
    boolean('follow', T).
    vector_string('return');
types.method('ls').
    vector_string('dir', '.').
    boolean('return');
types.method('mkdir').
    vector_string('directoryname', '.').
    boolean('makeparent', F).
    boolean('return');
types.method('dirname').
    vector_string('pathname', '.').
    vector_string('return');
types.method('basename').
    vector_string('pathname', '.').
    vector_string('return');
types.method('filetype').
    vector_string('filename').
    boolean('follow', T).
    vector_string('return');
types.method('size').
    vector_string('pathname').
    boolean('follow', T).
    vector_float('return');
types.method('freespace').
    vector_string('pathname').
    boolean('follow', T).
    vector_float('return');
types.method('copy').
    file('source').
    file('target').
    boolean('overwrite', F).
    boolean('follow', T).
    boolean('return');
types.method('move').
    file('source').
    file('target').
    boolean('overwrite', F).
    boolean('follow', T).
    boolean('return');
types.method('remove').
    vector_string('pathname').
    boolean('recursive', T).
    boolean('mustexist', F).
    boolean('follow', T).
    boolean('return');
types.method('edit').
    string('file').
    string('editor', 'emacs');
types.method('lockinfo').
    string('tablename').
    vector_integer('return');
types.method('showtableuse').
    string('tablename').
    boolean('return');
types.method('mail').
    string('message').
    string('recipient').
    boolean('sender', F).
    string('subject', '').
    string('cc', '').
    string('bcc', '').
    boolean('return');
types.method('done').
    boolean('return');
