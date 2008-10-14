# messageline.g: a TK widget to display and log one-line messages.
# Copyright (C) 1998,1999,2000,2001
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
#   $Id: messageline.g,v 19.2 2004/08/25 02:16:34 cvsmgr Exp $

pragma include once;

include 'note.g';
include 'widgetserver.g';

# The messageline subsequence.  It behaves very much like and entry
# widget except that it does not respond to the following events:
#  get, delete, insert, show, and disabled.
# This means that you can attach a scrollbar to this widget as you
# would a regular entry widget.
# Entry widget was choosen here over the message widget so that
# scrollbars could be used and so that selection could be exported.

const messageline := subsequence(ref parent, width=30,
				 justify='left',
				 font='', relief='sunken', borderwidth=2,
				 foreground='black',
				 background='lightgrey', 
				 exportselection=T,
				 hlp='Messages of interest will appear here.', 
				 messagenote=note, widgetset=dws)
{
    private := [=];

    # make sure we can do something with messagenote
    private.note := messagenote;

    # keep track of the whenevers for deactivation via done
    private.whenevers := [];
    private.pushwhenever := function() {
	wider private;
	private.whenevers[len(private.whenevers) + 1] := last_whenever_executed();
    }

    private.entryWidget := widgetset.entry (parent, width=width,
					    justify=justify,
					    font=font, relief=relief,
					    borderwidth=borderwidth,
					    foreground=foreground,
					    background=background, 
					    exportselection=exportselection);
    private.entryWidget->disabled (T);

    widgetset.popuphelp(private.entryWidget,hlp=hlp);

    private.clear := function() {
	wider private;
	private.entryWidget->delete('start', 'end');
    } 

    private.postIt := function(msg) {
	wider private;
	private.clear();
	private.entryWidget->insert(msg);
    }

    private.postAndForward := function(msg) {
	wider private;
	msg := as_string(msg);
	private.postIt(msg);
	if (is_function(private.note)) private.note(msg);
    }

    # and now the event handling
    # many events are simply forwarded to the entry widget
    whenever self->["background bind borderwidth exportselection font foreground justify relief view width"] do {
	wider private;
	private.entryWidget->[$name]($value);
    } private.pushwhenever();

    # anything coming from the entry widget is re-emitted
    # this is OK here since the only bi-directional event is get and
    # that event is not being forwarded to it should never be produced here
    whenever private.entryWidget->* do {
	wider self;
	self->[$name]($value);
    } private.pushwhenever();

    # the event special to this widget
    # post a message
    whenever self->post do {
	wider private;
	private.postAndForward($value);
    } private.pushwhenever();

    # post without forwarding to note
    whenever self->postnoforward do {
	wider private;
	private.postIt($value);
    } private.pushwhenever();

    whenever self->clear do {
	wider private;
	private.clear();
    } private.pushwhenever();

    # and the done function
    self.done := function() {
	wider private, self;
	# just this copy of note
	private.note := F;
	# deactivate all of the whenevers
	deactivate private.whenevers;
	# Remove the popuphelp. This also deletes the widget.
	widgetset.popupremove(private.entryWidget);
	# delete everything else.
	val private := F;
	val self := F;
	return T;
    }
} 


# a simple test script for messageline

const tmessageline := function (widgetset=dws)
{
    include 'sh.g';
    result := [=];
    result.f := widgetset.frame (title='test messageline()');
    result.ml := widgetset.messageline(result.f, width=20);
    # attach a scrollbar
    result.sb := widgetset.scrollbar(result.f, orient='horizontal');
    whenever result.ml->xscroll do
	result.sb->view($value);
    whenever result.sb->scroll do
	result.ml->view($value);
    result.ml->post('post event should forward to note');
    result.ml->postnoforward('postnoforward event does not forward to note');
    result.ml->post('about to clear....');
    dsh.command('sleep 2');
    result.ml->clear();

    return ref result;
} 

