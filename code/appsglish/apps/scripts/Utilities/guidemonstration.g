# guidemonstration.g: A demonstration helper
#
#   Copyright (C) 1998,1999,2000
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
#   $Id: guidemonstration.g,v 19.2 2004/08/25 02:08:51 cvsmgr Exp $
#

#pragma include once

include "widgetserver.g";

guidemonstration := subsequence(widgetset=dws, title='AIPS++ GUI demonstration',
			     width=80) {
  
  include "note.g";
  include "aips2logo.g";
  include 'toolmanager.g';

  private := [=];
  
  private.callback := F;
  private.timer := F;
  
  private.width := width;
  
  private.frames := [=];
  private.frames["topframe"] := widgetset.frame(title=title,
						side='top');
  private.frames["message"] := widgetset.frame(private.frames["topframe"],
					       side='left');
  private.widgets["logo"] := aips2logo(private.frames["message"], size=100);
  private.widgets["message"] := widgetset.text(private.frames["message"],
					       height=10,
					       width=private.width);

  self.tool := function(message, notes='', rec=[=], event='go') {
    wider private;

    if(message=='') {
      message := paste(event, as_evalstr(rec));
    }
    # Display this message
    private.frames["topframe"]->raise();
    private.widgets["message"]->delete('start', 'end');
    private.widgets["message"]->insert(message, 'end', tag='message');
    private.widgets["message"]->config('message', foreground='red');

    if(len(rec)) {
      # Show the current inputs, etc
      if(notes!='') {
	private.widgets["message"]->insert('\n', 'end');
	private.widgets["message"]->insert(notes, 'end', tag='notes');
	private.widgets["message"]->config('notes', foreground='black');
      }
      global tm;
      returnevent := spaste(event, '_return');
      print "Sending ", event, ", waiting for ", returnevent;
      tm->[event](rec); await tm->[returnevent];
      print "Got ", returnevent;
    }
    return T;
  }
}

