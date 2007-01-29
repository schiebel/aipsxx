# ttoolmanager.g: Test the tool manager
#
#   Copyright (C) 1998
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
#   $Id: ttoolmanager.g,v 19.2 2004/08/25 02:06:34 cvsmgr Exp $
#

pragma include once;

include 'toolmanager.g';

assert := function (what, test) {
  if((is_boolean(test)&&!test)||!is_boolean(test)) {
    note(what, ' failed');
    return 1;
  }
  else {
    note(what, ' passed');
    return 0;
  }
}


toolmanagertest := function() {

  # Define a tool that we will use to test the toolmanager
  const foo := function() {
    public := [=];
    public.type := function() {return 'foo'};
    public.gui := function() {
      f:=frame(title='foo.gui');
      b:=button(f, 'Press here to continue');
      await b->press;
      note('foo.gui() finished');
      f:=F;
      public:=F;
      return T;
    };
    public.another := function() {
      print "foo.another";
      return T;
    };
    public.anothercli := function() {
      print "foo.anothercli";
      return T;
    };
    public.anothergui := function() {
      f:=frame(title='foo.anothergui');
      b:=button(f, 'Press here to continue');
      await b->press;
      note('foo.anothergui() finished');
      f:=F;
      public:=F;
      return T;
    }
    return ref public;    
  }

  # Now test all functions in turn
  ok := assert('findtools', tm.findtools());
  result:=tm.tools();
  failed := assert('tools', is_record(result)&&(length(field_names(result))>0));
  testtool:=split(result)[1];
  global types;
  types.class('foo').method('ctor_foo');
  global myfoo := foo();
  failed +:= assert('istool', tm.istool('myfoo'));
  failed +:= assert('tooltype', is_string(tm.tooltype('myfoo')));
  failed +:= assert('istooltype', tm.istooltype('foo'));
  failed +:= assert('istooltype', !tm.istooltype('myfoo'));
  failed +:= assert('istoolfunction', tm.istoolfunction('myfoo.another'));
  failed +:= assert('registertool', tm.registertool('myfoo', '-'));
  failed +:= assert('settoolstatus', tm.settoolstatus('myfoo', 'Running'));
  failed +:= assert('settoolstatus', tm.settoolstatus('myfoo', 'Idle'));
  failed +:= assert('toolinfo', is_record(tm.toolinfo('myfoo')));
  failed +:= assert('isregistered', tm.isregistered('myfoo'));
  failed +:= assert('show', tm.show('myfoo'));
  failed +:= assert('show', tm.show('myfoo.another'));
  failed +:= assert('show', tm.show('myfoo.another', prefergui=F));
  failed +:= assert('unregistertool', tm.unregistertool('myfoo'));
  global anotherfoo := foo();
  failed +:= assert('registertool', tm.registertool('anotherfoo', '-'));
  failed +:= assert('deletetool', tm.deletetool('anotherfoo'));

  return failed;
}
