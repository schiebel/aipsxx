# infowindow: create and display a standard information window 
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.public.dismiss := function()
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
#   $Id: infowindow.g,v 19.2 2004/08/25 01:59:32 cvsmgr Exp $
#
# Info dialog

pragma include once
include "guiframework.g"

infowindow := subsequence( sometext='Your slogan here.',
                        title='Infomation Window',
                        selfdestruct=F, timeout=150, ws=dws)
{   
#
      # Only an acknowledgement button needed
    action := [=];
    action.dismiss.text := 'OK';
    action.dismiss.type := 'dismiss';
#
    tk_hold();
    a := guiframework(title, F, F, action);
    
    a.wf := a.getworkframe();
       # If we've got a whole lot of text in our message display it on
       # a text screen
    if(strlen(sometext) > 200){
       pf := ws.frame(a.wf, side='top');
       tf := ws.frame(pf, side='left', borderwidth=0);
       t := ws.text(tf, text=sometext, width=80, height=10);
       vsb := ws.scrollbar(tf);
       bf := ws.frame(pf, side='right', borderwidth=0, expand='x');
       pad := ws.frame(bf, expand='none', width=23, height=23, relief='groove');
       hsb := ws.scrollbar(bf, orient='horizontal');
       whenever vsb->scroll, hsb->scroll do
           t->view($value);
       whenever t->yscroll do
          vsb->view($value);
       whenever t->xscroll do
          hsb->view($value);
    } else {
       a.wf.m := ws.message(a.wf, text=sometext, width=600, relief='flat');
    }
    tk_release();
       #If we have selfdestruction set then start the timer 
    if(selfdestruct){
       done := F;
       timer := client("timer", 0.2);
       cleanup := function(){
          wider timer;
          wider a;
          timer->terminate();
          a.dismiss();
       }
       a.addactionhandler('dismiss', cleanup);
    #
       a.updatestatus(spaste('Window display for: ', timeout/5, ' s')); 
    #
       if(a.handle::returned){
          print "Clean up"
          choiceIs := a.handle::value;
          timer->terminate();
          a.dismiss();
          # done := T;
          break;
       }
       whenever timer->ready do {
           if($name == "ready") {
	     timeout -:= 1;
	     done := timeout <= 0;
             timestring := '     ';
             if(!(timeout%5)){
                timestring := spaste('Window displays for: ', timeout/5, ' s');
	        a.updatestatus( timestring);
             }
           }
           if(done){
             timer->terminate();
             a.dismiss();
           }
       }
    } else {
       a.addactionhandler('dismiss', a.dismiss);
    }
}
