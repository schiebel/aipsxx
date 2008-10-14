# tinputsmanager.g: Test the inputs manager
#
#   Copyright (C) 1998,1999
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
#   $Id: tinputsmanager.g,v 19.2 2004/08/25 02:05:19 cvsmgr Exp $
#

pragma include once;

include 'inputsmanager.g';

inputsmanagertest := function() {
  assert := function (what, test) {
    if(test) {
      note(what, ' passed');
    }
    else {
      note(what, ' failed');
    }
    return test;
  }

  vals1 := [x=1.45, mystring='nowt'];
  vals2 := [anotherstring='nowtmuch', iz=25];

  ok := assert('tabledelete', tabledelete('aips++values'));
  ok := assert('savevalues', im.savevalues('atool', 'function1',
					   vals1, 'default'));
  ok := assert('savevalues', im.savevalues('atool', 'function2',
					   vals2, 'default'));
  ok := assert('save', im.save('default'));
  ok := assert('get', im.get('default'));
  rec1 := im.getvalues('atool', 'function1', 'default');
  ok := assert('getvalues', is_record(rec1));
  rec2 := im.getvalues('atool', 'function2', 'default');
  ok := assert('getvalues', is_record(rec2));
  print vals1, rec1
  print vals2, rec2
  ok := assert('list', im.list());
  return ok;
}
