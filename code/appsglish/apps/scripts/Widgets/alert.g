# alert.g: Alert the user
# Copyright (C) 1996,1997,1998,1999
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
# $Id: alert.g,v 19.2 2004/08/25 02:11:15 cvsmgr Exp $


pragma include once
    
include 'widgetserver.g';
include 'timer.g'

# Embed somewhere in a frame to get the attention of a user
# 

alert := function(parent, beep='\a', label='ALERT', delay=0.25, persist=0,
		  foreground='red', background='white', widgetset=dws) {

  private := [=];
  private.beep := beep;
  private.delay := delay;
  private.persist := persist;
  private.foreground := foreground;
  private.background := background;
  private.label := label;
  private.parent := parent;

  private.die := function(interval=0, name='') {
    wider private;
    private.cf->unmap();
  }
  private.flashoff := function(interval=0, name='') {
    wider private;
    private.c->background(private.background);
    private.c->foreground(private.foreground);
    printf(private.beep);
    if(private.persist>0) scanid := timer.execute(private.die, private.persist, oneshot=T);
  }
  private.flashon := function(interval=0, name='') {
    wider private;
    private.c->background(private.foreground);
    private.c->foreground(private.background);
    printf(private.beep);
    scanid := timer.execute(private.flashoff, private.delay, oneshot=T);
  }
  private.cf := widgetset.frame(private.parent,side='left',borderwidth=0);
  private.c := widgetset.canvas(private.cf, region=[-50,-50,50,50], borderwidth=0,
				relief='flat', height=100, width=100);
  private.poly := private.c->poly(20,-40,40,-20,40,20,20,40,-20,40,-40,
				  20,-40,-20,-20,-40,fill=private.foreground,tag='stop');
  private.edge := private.c->line(20,-40,40,-20,40,20,20,40,-20,40,-40,20,-40,-20,
				  -20,-40,20,-40,fill=private.background,width='5',tag='stop');
  private.word := private.c->text(0,0,text=private.label,fill=private.background,tag='stop');
  scanid := timer.execute(private.flashon, private.delay, oneshot=T);
  return T;
}
