# dish_evalwin.g: The DISH evaluation window
#------------------------------------------------------------------------------
#   Copyright (C) 1997,1998,1999,2000
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
#    $Id: dish_evalwin.g,v 19.1 2004/08/25 01:08:39 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include 'widgetserver.g';

#------------------------------------------------------------------------------
const evalwindow := function (title='',columns=60, rows=20)
{
  private := [=];
  public := [=];

  #---------------------------------------------------------------------------
  menubar := function (parentFrame) {
    private := [=];
    public := [=];
    private.frame := dws.frame (parentFrame,expand='x',side='left', relief='raised',
			     borderwidth=1);
    private.fileMenu :=  dws.button (private.frame,'File', type='menu');
    public.fileOpenButton   := dws.button (private.fileMenu, text='Open...',
					   disabled=T);
    public.fileInsertButton := dws.button (private.fileMenu, text='Insert...',
					   disabled=T);
    public.fileSaveButton   := dws.button (private.fileMenu, text='Save',
					   disabled=T);
    public.fileSaveAsButton := dws.button (private.fileMenu, text='Save As...',
					   disabled=T);
    public.dismissButton  := dws.button (private.fileMenu, text='Dimsiss');

    public.evalContentsButton := dws.button (private.frame,text='Eval Contents');
    public.evalRegionButton := dws.button (private.frame,text='Eval Region',
					   disabled=T);

    private.middleSpacer := dws.frame (private.frame,width=30,height=10,borderwidth=0);
    private.rightSide := dws.frame (private.frame,side='right',height=10,borderwidth=0);
    private.helpMenu :=dws. button (private.rightSide,text='Help', 
				 disabled=T);
    public.workaround := ref private;  #otherwise private.* are deleted when
    #                                # this function goes out of scope
    return ref public;
    }# nested closure object 'menubar'
    #-------------------------------------------------------------------------

  private.parentFrame := dws.frame (title=title,borderwidth=0);
  private.menubar := dws.menubar (private.parentFrame);
  public.dismissButton := ref private.menubar.dismissButton;

   # expose some of the menu buttons so that the client code -- probably some 
   # application -- can manage any coordination it needs, and call back
   # to this closure object as needed.

  private.topFrame := dws.frame (private.parentFrame, side='left', borderwidth=0);
  private.textWidget := dws.text (private.topFrame, wrap='none',
			       width=columns,height=rows);
  private.verticalScrollbar := dws.scrollbar (private.topFrame);
  private.bottomFrame := dws.frame (private.parentFrame,side='right',borderwidth=0,
				 expand='x',borderwidth=0);
  private.cornerPad := dws.frame (private.bottomFrame,expand='none',width=23,height=23);
  private.horizontalScrollbar := dws.scrollbar (private.bottomFrame,orient='horizontal');
  
  whenever private.verticalScrollbar->scroll, private.horizontalScrollbar->scroll do {
    private.textWidget->view ($value);
    }

  whenever private.textWidget->yscroll do {
    private.verticalScrollbar->view ($value);
    }

  whenever private.textWidget->xscroll do {
    private.horizontalScrollbar->view ($value);
    }


  private.eval_contents := function () {
    wider private; 
    contents := private.textWidget->get ('start','end');
    #print 'contents of buffer: ', contents
    junk := eval (contents)
    #print 'result of eval ', junk
    }

  public.contents := function () {
    wider private; 
    contents := private.textWidget->get ('start','end');
    return contents;
    }

  public.clear := function () {
    wider private;
    private.textWidget->delete ('start','end');
    }

  public.destroy := function () {
    wider private;
    private.parentFrame := F;
    }

  whenever public.dismissButton->press do public.destroy ();
  whenever private.menubar.evalContentsButton->press do private.eval_contents ();

#  public.debug := ref private;

  return ref public;

}# trace_window
#--------------------------------------------------------------------------------
test_ew := function ()
{
  ew := evalwindow ('test evalbuffer.g');

  return ref ew;

}
#--------------------------------------------------------------------------------
# ew:= test_ew ();
# 
# 
# 
# get_text := function (lineNumber) 
# {   
#    for (i in 0:10) {
#      location := spaste (lineNumber,'.',i);
#      result := ew.debug.textWidget->get (location); 
#      msg := spaste ('location: ', location, ': ', result, ' type: ',
#                     full_type_name (result));
#      print msg;
#      };
# }
# 
# get_char := function (line,column)
# {
#   legalArguments := is_integer (line) && is_integer (column);
#   if (!legalArguments) return F;
# 
#   locationString := spaste (line,'.',column)
#   result := ew.debug.textWidget->get (locationString);
#   if (strlen (result) == 1)
#     return result
#   else
#     return F;
# 
# }
# 
# get_line := function (lineNumber)
# {
#   columnNumber := 0;
#   lineAsString := '';
# 
#   #print 'about to enter while loop:', lineNumber, columnNumber;
#  
#   while (is_string (c := get_char (lineNumber, columnNumber))) {
#     #print 'just called get_char', lineNumber, columnNumber;
#     lineAsString := spaste (lineAsString, c);
#     columnNumber +:= 1;
#     }
#   return lineAsString;
# 
# }
