# make: Run the make client
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
#   $Id: make.g,v 19.2 2004/08/25 02:09:06 cvsmgr Exp $
#

pragma include once

make := function(target, makefile='makefile', args='', script='', debug=F) {

  include 'note.g';

  private := [=];
  private.args := args;
  private.makefile := makefile;
  private.commands := '';
#
#
  if(script!='') {
    private.f := open(spaste('> ', script));
    if(!is_file(private.f)) {
      return throw('Cannot open script file ', script, ' for writing');
    }
    fprintf(private.f, '# Make rule for %s\n', target);
  }

#
# Done this tool
#
  private.done := function() {
    wider private;
    private.deactivatewhenever();
    private.c := F;
    private.f:=F;
    return T;
  }
#
# Boilerplate for whenever pushing and deactivating
#
  private.whenevers := [];
  private.pushwhenever := function() {
    wider private;
    private.whenevers[len(private.whenevers) + 1] := 
        last_whenever_executed();
  }
  
  private.deactivatewhenever := function() {
    wider private;
    deactivate private.whenevers;
    private.whenevers := [];
  }

  private.newclient := function(args, makefile, debug=F) {
    wider private;
#
# First kill any old client
#
    if(has_field(private, 'c')&&is_agent(private.c)) {
      private.deactivatewhenever();
      private.c := F;
    }
# Make the make client
    if(makefile=='') {
      return throw('Need a makefile');
    }
    else {
      if(args=='') {
	private.c:=client('make_client', spaste('-f', makefile));
      }
      else {
	private.c:=client('make_client', args, spaste('-f', makefile));
      }
    }
    if(debug) {
      whenever private.c->* do {note('Make sends ', $name, ' with value ', $value)};
      private.pushwhenever();
    }
    # Catch the returns from the make client and assemble into one command
    whenever private.c->glish, private.c->shell do {
      command := '';
      if($name=="glish") {
	command := spaste(command, $value, '\n');
      }
      else {
	command := spaste(command, 'shell(\'',$value,'\');\n');
      }
      if(script!='') {
	fprintf(private.f, '%s', command);
      }
      private.commands[length(private.commands)+1] := command;
    }
    private.pushwhenever();
    whenever private.c->fail do {
      throw('Catastrophic error in make client - cannot continue');
      private.done();
    }
    private.pushwhenever();
    whenever private.c->error do {
      throw($value);
    }
    private.pushwhenever();   

# Set up AIPS ROOT directory
    include 'sysinfo.g';
    private.c->variable('AIPSROOT', sysinfo().root());
  }

#
# Now do the make
#`
  private.newclient(private.args, private.makefile, debug);
  private.glish := '';
  result := private.c->make(target);
  if(script!='') {
    fprintf(private.f, 'exit\n');
  }
  private.done();
  if(is_fail(result)) {
    return throw(result::message);
  }
  else {
    return T;
  }
}
