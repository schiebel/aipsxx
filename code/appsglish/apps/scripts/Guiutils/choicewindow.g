# choicewindow: create a standard dialog with choices
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
#   $Id: choicewindow.g,v 19.2 2004/08/25 01:58:13 cvsmgr Exp $
#
# Brian's choicewin with time out option.

pragma include once
include "guiframework.g"
const choicewindow := function(question, choices, interactive=have_gui(), timeout=150,
                         ws=dws)
{
      # Check to make sure we can do what we think we can do.
    if (!is_string(question) || !is_string(choices)) {
        fail '::choice(description,choices) : description and choices must be strings'
    }

    if (!interactive || !have_gui()) {
        return choices[1]
    }
    # Set the choices
    action := [=];
    for(choice in choices){
       action[choice] := [=];
       action[choice].text := choice;
    }
      # Make the framework
    a := guiframework('AIPS++ Please make a choice', F, F, action);
    wf := a.getworkframe();
    m := ws.message(wf, question, width=600, relief='flat');
      #
    done := F;
      # Start the timer
    timer := client("timer", 0.2);
    choiceIs := choices[1];
    #
    a.updatestatus(spaste('Time left to chose: ', timeout/5, ' s')); 
      # Loop until a choice is made or we time out.
    while(!done){
       if(a.handle::returned){
            # User made a choice
          choiceIs := a.handle::value;
          break;
       }
       await timer->ready 
       if ($name == "ready") {
	  timeout -:= 1;
	  done := timeout <= 0;
          timestring := '     ';
          if(!(timeout%5)){
             timestring := spaste('Time left to chose: ', timeout/5, ' s');
	     a.updatestatus( timestring);
          }
        }
    }
      # stop the timer
    timer->terminate();
      # Close up shop and return the option
    a.dismiss();
    return choiceIs;
}
