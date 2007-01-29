# memoryassay.g: Assay of memory
#
#   Copyright (C) 1996,1997,1998,1999,2001
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
#          Postal address: AIPS++/ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: memoryassay.g,v 19.2 2004/08/25 02:09:21 cvsmgr Exp $
#

pragma include once;
include 'note.g'

memoryassay := function(verbose=F) {
  names := symbol_names();
  memory := [];
  j:=0;
  for (i in 1:length(names)) {
    name:=names[i];
    list[i] := name;
    nameSize := eval(spaste('sizeof(',name,')'));
    if (is_fail(nameSize)) {
	errmsg := spaste('The Glish variable ', name, ' is a fail type. ',
			'This probably means that there was an unexpected problem ',
			'in one of the Glish scripts included so far.  This denotes ',
			'a severe problem with the local installation which may ',
			'prevent any use.  Please contact your local AIPS++ support person');
	print errmsg;
	nameSize := 0;
    }
    memory[i] := nameSize;
  }
  list:=sort_pair(memory, list);
  memory:=sort(memory);
  if(verbose) {
    for (i in 1:length(list)) {
      print list[i], memory[i];
    }
  }
  note('Total memory used in Glish variables = ', sum(memory), ' bytes');
  return T;
}

