# demonstration.g: A demonstration helper
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
#   $Id: demonstration.g,v 19.2 2004/08/25 02:07:56 cvsmgr Exp $
#

#pragma include once

include "note.g";
include "widgetserver.g";
include "aips2logo.g";

demonstration := subsequence(widgetset=dws, font='fixed',  width=80) {

  private := [=];

  private.active := F;
  private.wait := F;
  private.callback := F;
  private.timer := F;
  
  private.font := font;
  private.width := width;

  private.starttimer := function() {
    wider private;
    private.timer := client('timer');
    if (!is_agent(private.timer)) {
      return throw('timer - could not start timing client!');
    }
    
    ## Attempt some sort of restart on failure.
    whenever private.timer->fail do {
      wider private;
      throw(spaste('demonstration: The timer process has died unexpectedly. This is a serious error and\n',
		   '    should be reported as a bug, especially if it can be repeated. I am\n',
		   '    attempting to restart the executable, but registered callbacks are\n',
		   '    lost, and your session might have to be restarted.\n'));
      private.starttimer();
    }
  }

  private.initgui := function() {
    wider private;
    private.frames := [=];
    private.frames["topframe"] := widgetset.frame(title='AIPS++ demonstration', side='top');
    private.frames["message"] := widgetset.frame(private.frames["topframe"], side='left');
    private.widgets["logo"] := aips2logo(private.frames["message"], size=100);
    private.widgets["message"] := widgetset.text(private.frames["message"],
                                                 height=10,
						 font=private.font,
						 width=private.width);

    if(0) {
      private.frames["bottom"] := widgetset.frame(private.frames["topframe"], side='left');
      
      private.buttons["pause"] := widgetset.button(private.frames["bottom"], 'Pause');
      private.buttons["pause"]->disabled(F);
      private.buttons["pause"].shorthelp := 'Pause the demonstration when next possible';
      private.buttons["continue"] := widgetset.button(private.frames["bottom"], 'Continue');
      private.buttons["continue"]->disabled(T);
      private.buttons["continue"].shorthelp := 'Continue the demonstration';
      
      whenever private.buttons["pause"]->press do {
	private.wait := T;
	private.buttons["pause"]->disabled(T);
	private.buttons["continue"]->disabled(F);
	self->pause();
      }
      
      whenever private.buttons["continue"]->press do {
	private.wait := F;
	private.buttons["pause"]->disabled(F);
	private.buttons["continue"]->disabled(T);
	self->continue();
      }
    }

    return T;
  }

  self.title := function(title='AIPS++ Demonstration') {
    wider private;
    if(has_field(private, 'frames')&&has_field(private.frames['topframe'])&&
       is_agent(private.frames['topframe'])) {
      private.frames['topframe']->title(title);
    }
    return T;
  }

  # Display caption for interval sections or until the user presses
  # the continue button
  self.caption := function(message, notes='', command='', interval=10) {
    wider private;
    if(private.active) {
      # Wait for previous caption to timeout
      if(private.wait&&is_agent(private.timer)&&is_string(private.callback)) {
	await private.timer->[private.callback];
      }
      # Display this message
      private.frames["topframe"]->raise();
      private.widgets["message"]->delete('start', 'end');
      private.widgets["message"]->insert(message, 'end', tag='message');
      private.widgets["message"]->config('message', foreground='black');
      if(notes!='') {
	private.widgets["message"]->insert('\n', 'end');
	private.widgets["message"]->insert(notes, 'end', tage='notes');
	private.widgets["message"]->config('notes', foreground='blue');
      }
      # Now set up timer
      private.callback := private.timer->register(interval);
      private.wait := T;
      whenever private.timer->[private.callback] do {
	private.wait  := F;
	self->continue();
        deactivate;
      }
    }
    if(command!='') {
      eval(command);
    }
    return T;
  }

  self.enable := function() {
    wider private;
    private.active:=T;
    if(!has_field(private, 'frames')||!has_field(private.frames['topframe'])||
       !is_agent(private.frames['topframe'])) {
      private.initgui();
    }
    if(!is_agent(private.timer)) {
      private.starttimer();
    }
    return T;
  }

  self.disable := function() {
    wider private;
    private.active:=F;
    if(has_field(private, 'frames')&&has_field(private.frames['topframe'])&&
       is_agent(private.frames['topframe'])) {
      private.frames['topframe']->unmap();
    }
    return T;
  }

}

const defaultdemonstration := demonstration();
const ddemo := const defaultdemonstration;

