# aips2logo: Display the AIPS++ logo
#
#   Copyright (C) 1999
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
#   $Id: aips2logo.g,v 19.2 2004/08/25 02:11:10 cvsmgr Exp $
#

pragma include once;

include 'widgetserver.g';

const aips2logo := subsequence(parent, size=18, widgetset=dws) {

  private := [=];
  private.frame := widgetset.frame(parent, expand='none');
  private.canvas := widgetset.canvas(private.frame, width=size, height=size,
				    borderwidth=0);
  private.colors := ['black', 'darkblue', 'blue', 'cyan', 'lightblue',
		     'white'];

  private.lines := [=];
  inc := size/6;
  for (line in 1:6) {
    private.lines[line] :=
	private.canvas->rectangle(0,as_integer((line-1)*inc),
				  size,as_integer(line*inc),
				  fill=private.colors[line]);
  }

  # Pass on all frame events
  whenever private.canvas->* do {
    self->[$name]($value);
  }
  whenever self->* do {
    private.canvas->[$name]($value);
  }
}

const aips2logobutton := function(parent) {

  prvt := [=];
  prvt.aips2logobutton := aips2logo(parent, size=18);
  prvt.aips2logobutton->bind('<ButtonPress>', 'press');
  whenever prvt.aips2logobutton->press do {
    ok:=eval('include \'toolmanager.g\'');
    if(is_record(tm)&&has_field(tm, 'gui')&&is_function(tm.gui)) {
      tm.gui();
    }
  }
  return T;

}
const taips2logo := function() {
  f :=frame(title='AIPS++');
  return aips2logobutton(f);
}
