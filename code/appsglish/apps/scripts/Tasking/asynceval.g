# asynceval: Asynchronous evaluation of evals
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
#   $Id: asynceval.g,v 19.2 2004/08/25 02:02:02 cvsmgr Exp $
#
include 'note.g';

pragma include once;

const asynceval := subsequence() {

  self.whenevers := [];

  self.running := 0;
  self.last := '';

  self.pushwhenever := function() {
    wider self;
    self.whenevers[len(self.whenevers) + 1] := last_whenever_executed();
  }

  whenever self->run do {
    command := $value;
    if(self.running>0) {
      note(paste('One or more operations still running: last operation was ',
		 self.last), priority='WARN', origin='asynceval');
    }
    self.running +:=1;
    self.last := $value;
    # servers.g related
    if(is_defined('dowait')) {
      global dowait;
      olddowait := dowait;
      dowait := T;
      result := eval($value);
      dowait := olddowait;
    }
    else {
      result := eval($value);
    }
    self.running -:=1;
    self->result(result);
  } self.pushwhenever();


  whenever self->kill do {
    self->result(self.fail());
    self.done();
  } self.pushwhenever();


  self.done := function() {
    wider self;
    deactivate self.whenevers;
    val self := F;
    return T;
  }

  self.fail := function() {
    wider self;
    fail paste('Asynceval was killed, last operation was', self.last);
  }

}
