# guicomponents.g: composite widgets for the graphical user interface
#------------------------------------------------------------------------------
#
#   Copyright (C) 1996,1997,1998,2000,2001
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
#          Internet email: aips2request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: guicomponents.g,v 19.2 2004/08/25 01:59:07 cvsmgr Exp $
#
#------------------------------------------------------------------------------

pragma include once

#------------------------------------------------------------------------------
include "gmisc.g"
#------------------------------------------------------------------------------
# objects:
#   messagebox
#   status_line
#   tracewindow
#   evalwindow
#   single_entry_dialog_box
#
# design notes:
#   presented under individual objects
#
# implementation notes:
#   presented under individual objects
#
# todo:
#   colors and fonts are hard-coded -- they should be user-customizable
#   other todo items are listed under the individual objects
#  
#------------------------------------------------------------------------------
# ACTIVE_TEXT_COLOR := 'black';
# DISABLED_TEXT_COLOR := 'gray60';

include "widgetserver.g"
include "oldcombobox.g";

# DEFAULT_BUTTON_FONT := spaste ('-adobe-courier-medium-r-normal--',12,'-*');

#----------------------------------------------------------------------------
# status_line
#
# design notes:
# -------------
# this is a very simple gui closure object, and the design can be taken
# in with one glance at the code...
#
# implementation notes
# --------------------
# nothing special
# 
# todo list
# ---------
# nothing yet
#----------------------------------------------------------------------------
const status_line := function (parentFrame, help='Status line', width=60)
{
  private := [=];
  public := [=];

  private.entryWidget := dws.entry (parentFrame, width=width);
  private.entryWidget->disabled (T);

  popuphelp(private.entryWidget,hlp=help);

  public.show := function (msg) {
    wider private, public;
    public.clear ();
    private.entryWidget->insert (msg);
    return T;
    }

  public.clear := function () {
    wider private;
    private.entryWidget->delete ('start', 'end'); 
    return T;
    }

  public.append := function (msg) {
    wider private; 
    private.entryWidget->insert (spaste (' ', msg));
    return T;
    }

  public.delete := function () {
    wider private;
    private.entryWidget := F;
    return T;
    }

  return ref public;

} # status_line
#------------------------------------------------------------------------------
test_status_line := function ()
{
  result := [=];
  result.f := dws.frame (title='test status_line ()');
  result.sl := status_line (result.f);
  result.sl.show ('added...');
  result.sl.append ('appended...');
  result.sl.append ('about to clear....');
  #shell ('sleep 2');
  #result.sl.clear ();

  return ref result;

} # test_status_line
#------------------------------------------------------------------------------
# single_entry_dialog_box
#
# design notes:
# -------------
# i needed a way to prompt the user for a function name, and this simple was
# the result.  the only thing not absolutely obvious is the use of a callback
# function.  this allows the popup to run modeless and to reliably return
# its value to just the right, known point in the calling program.
#
# implementation notes
# --------------------
# it is hard to imagine a circumstance in which a callback function is *not*
# needed, but nonetheless i made it an optional parameter to the constructor.
# perhaps if this component were generalized, and made more flexible, it 
# would be useful with a null callback function.
#
# todo list
# ---------
# - a better name? (11 dec 96, pshannon)
#------------------------------------------------------------------------------
const single_entry_dialog_box := function (prompt, callbackFunction=F)
{
  private := [=];
  public := [=];
  defaults := [=];
  
  defaults.normal_font := spaste ('-adobe-courier-medium-r-normal--',12,'-*');
  defaults.bold_font   := spaste ('-adobe-courier-bold-r-normal--',12,'-*');

  private.toplevel := frame (title=' ',side='top');
  private.topFrame := frame (private.toplevel, side='left');
  private.label := label (private.topFrame, text=prompt, fill='none',justify='right')
  private.entry := entry (private.topFrame,background='white',
                       font=defaults.normal_font);
  private.lowerFrame := frame (private.toplevel, side='left');
  private.lowerLeftFrame := frame (private.lowerFrame,expand='none',width=110);
  private.buttonFrame := frame (private.lowerFrame,side='left');
  private.okayButton := button (private.buttonFrame,text='OK');
  private.cancelButton := button (private.buttonFrame,text='Dismiss');

  whenever private.entry->return, private.okayButton->press do {
    functionName := private.entry->get ();
    if (is_function (callbackFunction)) callbackFunction (functionName);
    public.delete ();
    }

  whenever private.cancelButton->press do {
    public.delete ();
    }

  public.delete := function () {
    wider private;
    private.toplevel := F;
    }

#  public.debug := ref private;
#  return ref public;

}# single_entry_dialog_box
#----------------------------------------------------------------------------
test_single_entry_dialog_box := function (cb)
{
  db := single_entry_dialog_box ('Your name', cb);
  return ref db;
}
#----------------------------------------------------------------------------
cb := function (name) 
{
  print 'Your name is:', name;
}
#----------------------------------------------------------------------------
# messagebox
#
# design notes:
# -------------
# nothing special
#
# implementation notes
# --------------------
# the tk message widget is sized when created to a maximum number of rows
# and characters.  it always shrinks to nicely enclose the longest line 
# and number of rows it contains, as long as those sizes are less than
# the maximum values.  If the text should exceed these maximum values
# scrollbars are created so that actuall size does not exceed these values.
#
#----------------------------------------------------------------------------
const messagebox := function (msg,background='white', title = ' ', 
			      font = spaste ('-adobe-courier-medium-r-normal--',12,'-*'),
			      maxrows=5, maxcols=80, ws=dws)
{
  private := [=];
  public := [=];
  
  private.maxrows := maxrows;
  private.maxcols := maxcols;

  private.toplevel := ws.frame (title=title,side='top');
  private.topFrame := ws.frame (private.toplevel, side='top');

  # returns a record with these fiels:
  #  text := the thing to send to the text widget
  #  nrows := the number of rows in msg
  #  ncols := the max number of chars in all rows in msg
  # Each individual string in msg is a new row but we also
  # need to deal with the possibility that there may be
  # embedded newline chars in msg
  private.msgFormat := function(msg) {
      result := [=];
      result.text := paste(msg,sep='\n');
      textArray := split(result.text,'\n');
      result.nrows := len(textArray);
      result.ncols := max(strlen(textArray));
      return result
  }

  msgFormat := private.msgFormat(msg);
  private.textwidth := msgFormat.ncols;
  private.textheight := msgFormat.nrows;
  private.currwidth := min(private.textwidth, private.maxcols);
  private.currheight := min(private.textheight, private.maxrows);

  private.outerTextFrame := ws.frame(private.topFrame,borderwidth=0);
  private.textFrame := ws.frame(private.outerTextFrame, side='left',borderwidth=0);
  private.text := ws.text (private.textFrame,background=background,
			font=font,
			width=private.currwidth,
			height=private.currheight,
			wrap = 'none',
			text=msgFormat.text, relief = 'ridge');

  private.spacer := ws.frame (private.topFrame, height=10,expand='x');
  private.dismissFrame := ws.frame(private.topFrame, side='right');
  private.dismissButton := ws.button (private.dismissFrame, type='dismiss',
                                      text='Dismiss');

  private.hasHorizScrollbar := F;
  private.hasVertScrollbar := F;
  private.addVertScrollbar := function() {
      wider private;
      # make sure this only happens once
      if (private.hasVertScrollbar) return;

      private.vsb := ws.scrollbar(private.textFrame);
      whenever private.vsb->scroll do {
	  private.text->view($value);
      }
      whenever private.text->yscroll do {
	  private.vsb->view($value);
      }
      private.hasVertScrollbar := T;
  }

  private.addHorizScrollbar := function() {
      wider private;
      # make sure this only happens once
      if (private.hasHorizScrollbar) return;

      private.bf := ws.frame(private.outerTextFrame, side='right', borderwidth=0);
      private.pad := ws.frame(private.bf, expand='none', width=23, height=23, relief='grove');
      private.hsb := ws.scrollbar(private.bf, orient='horizontal');
      whenever private.hsb->scroll do {
	  private.text->view($value);
      }
      whenever private.text->xscroll do {
	  private.hsb->view($value);
      }
      private.hasHorizScrollbar := T;
  }
  
  if (private.textwidth > private.currwidth) private.addHorizScrollbar();
  if (private.textheight > private.currheight) private.addVertScrollbar();

  whenever private.dismissButton->press do {
      public.delete ();
  }

  public.delete := function () {
      # eventually this will need to keep track of and delete all
      # whenevers, when that becomes possible
      wider private;
      val private.toplevel := F;
  }

  public.text := function (msg) {
      wider private;
      msgFormat := private.msgFormat(msg);
      private.textheight := msgFormat.nrows + private.textheight;
      if (private.textheight > private.currheight) {
	  private.currheight := min(private.textheight, private.maxrows);
	  private.text->height(private.currheight);
	  if (private.currheight == private.maxrows && ! private.hasVertScrollbar) {
	      private.addVertScrollbar();
	  }
      }
      if (msgFormat.ncols > private.textwidth) {
	  private.textwidth := msgFormat.ncols;
	  if (private.textwidth > private.currwidth) {
	      private.currwidth := min(private.textwidth, private.maxcols);
	      private.text->width(private.currwidth);
	      if (private.currwidth == private.maxcols && ! private.hasHorizScrollbar) {
		  private.addHorizScrollbar();
	      }
	  }
      }
      private.text->append('\n');
      private.text->append(msgFormat.text);
  }

#  public.debug := ref private;
#  return ref public;

}# messagebox
#----------------------------------------------------------------------------
test_messagebox := function ()
{
  db := messagebox ('This is a \n test message','red');
  return ref db;

}
#----------------------------------------------------------------------------
# evalwindow.g: 
#
# design notes:
# -------------
# the goal here is to create a simple but adequate text editor from which
# code can be sent to the glish interpreter.  it is not yet clear that this
# idea will catch on, but it may.  it fits nicely into the scheme described
# in aips++ note 194, the SDCalc Programming Environment: you have a gui
# which provides a few prescribed paths through some kinds of data analysis; 
# then you want to tailor the analysis to your own work, then cobbling bits
# and pieces from the polished gui application, into your own application,
# or your extension of the orginal application.  to be able to cut, paste,
# edit and evaluate code in the current glish environment seems like the
# right thing to do.  (a similar appraoch is used in lisp machine programming, 
# and in some smalltalk evironments.)  
#
# implementation notes
# --------------------
# this makes use of the builtin glish function 'eval'.  otherwise it is
# not much more than a menubar and an otherwise unadorned text widget.
# 
#
# see also
# --------
#  - aips++ note 194
#  - the tracewindow (below)
#
# todo list
# ---------
#  - add evaluate selection -- i think that the text widget now allows you
#    to retrieve selected text (thanks darrell!) (11 dec 96, pshannon)
#----------------------------------------------------------------------------
const evalwindow := function (title='',columns=60, rows=20)
{
  private := [=];
  public := [=];
  defaults := [=];

  defaults.normal_font := spaste ('-adobe-courier-medium-r-normal--',12,'-*');
  defaults.bold_font   := spaste ('-adobe-courier-bold-r-normal--',12,'-*');

  #---------------------------------------------------------------------------
  menubar := function (parentFrame) {
    private := [=];
    public := [=];
    private.frame := frame (parentFrame,expand='x',side='left', relief='raised',
                         borderwidth=1);
    private.fileMenu :=  button (private.frame,'File', relief='flat', type='menu');
    public.fileOpenButton   := button (private.fileMenu, text='Open...',
                                       disabled=T);
    public.fileInsertButton := button (private.fileMenu, text='Insert...',
                                       disabled=T);
    public.fileSaveButton   := button (private.fileMenu, text='Save',
                                       disabled=T);
    public.fileSaveAsButton := button (private.fileMenu, text='Save As...',
                                       disabled=T);
    public.dismissButton  := button (private.fileMenu, text='Dismiss');

    public.evalContentsButton := button (private.frame,text='Eval Contents',
                                        relief='raised');
    public.evalRegionButton := button (private.frame,text='Eval Region',
                                       relief='raised',disabled=T);

    private.middleSpacer := frame (private.frame,width=30,height=10,borderwidth=0);
    private.rightSide := frame (private.frame,side='right',height=10,borderwidth=0);
    private.helpMenu := button (private.rightSide,text='Help', 
                             relief='flat', disabled=T);
    public.workaround := ref private;  #otherwise private.* are deleted when
    #                                # this function goes out of scope
    return ref public;
    }# nested closure object 'menubar'
    #-------------------------------------------------------------------------

  private.parentFrame := frame (title=title,borderwidth=0);
  private.menubar := menubar (private.parentFrame);
  public.dismissButton := ref private.menubar.dismissButton;

   # expose some of the menu buttons so that the client code -- probably some 
   # application -- can manage any coordination it needs, and call back
   # to this closure object as needed.

  private.topFrame := frame (private.parentFrame, side='left', borderwidth=0);
  private.textWidget := text (private.topFrame, relief='sunken',wrap='none',
                           background='white',width=columns,height=rows,
                           font=defaults.normal_font);
  private.verticalScrollbar := scrollbar (private.topFrame);
  private.bottomFrame := frame (private.parentFrame,side='right',borderwidth=0,
                             expand='x',borderwidth=0);
  private.cornerPad := frame (private.bottomFrame,expand='none',width=23,height=23,
                           relief='groove');
  private.horizontalScrollbar := scrollbar (private.bottomFrame,orient='horizontal');
  
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
    return T;
    }

  public.delete := function () {
    wider private;
    private.parentFrame := F;
    return T;
    }

  whenever public.dismissButton->press do public.delete ();
  whenever private.menubar.evalContentsButton->press do private.eval_contents ();

#  public.debug := ref private;

  return ref public;

}# evalwindow
#------------------------------------------------------------------------------
test_evalwindow := function ()
{
  ew := evalwindow ('test evalwindow');

  return ref ew;

}
#-------------------------------------------------------------------------------
# tracewindow
#
# design notes:
# -------------
# this object was inspired by the need for a narrow-focus gui application (sdavg.g)
# to tell the user what operations were going on behind the scenes in response to
# buttons pushed on the applications gui.  so the application is responsible for
# appending text to the tk text widget that forms the heart of this component.  but
# there is also the goal to let the user navigate down into those functions, by selecting
# them as they appear in the tracewindow, and asking for a display of their code.
# 
# please note that the text written into this tracewindow by the application happens 
# as the application runs, giving a dynamic view of what happens behind the scenes.
# the 'navigate down' capability is essentially a static view.  an alternate (and
# not mutually exclusive) approach would be to have the 'navigate down' functions also
# appear as full text, with actual parameters, as the gui runs.  this is more work
# and might not be worth the effort, at least not soon.
#
# i have a hastily-implemented design for obtaining the text of a function, given its 
# name.  it depends on a modest -- but somewhat arbitrary -- convention.
# first, that text exists as an attribute called '<function_name>::text'.  if the
# display function (see get_function_listing below) cannot find that attribute, then
# it gives up.  it is pretty easy to create that text given the glish source code.
# it could be created on-the-fly, with some nice lightweight perl script, but the
# example below was constructed by hand.
#
# implementation notes
# --------------------
# the implementaton is incomplete, for now being not much more than a simple text widget
# that an application can write to.
#
# I have altered this slightly so that if he ::text attribute is not there (as
# it generally will not be) the function is returned using the as_string()
# function.  It won't be pretty, but it will all be there.  In the long run
# I think that the ::text attribute is unwieldy and unmaintainable and that
# glish itself needs the ability to display functions "nicely" when asked. -rwg
#
# see also
# --------
#  - aips++ note 194, the SDCalc Programming Environment
#  - evalwindow (above)
#
# todo list
# ---------
#  - try to get some agreement on the importance of pushing ahead with the
#    ability to display the text of an arbitrary glish function, or perhaps
#    of an application-specific designated subset.
#-------------------------------------------------------------------------------
const tracewindow := function (title='',columns=50, rows=12)
{
  private := [=];
  public := [=];
  defaults := [=];

  defaults.normal_font := spaste ('-adobe-courier-medium-r-normal--',12,'-*');
  defaults.bold_font   := spaste ('-adobe-courier-bold-r-normal--',12,'-*');

  menubar := function (parentFrame) {
    private := [=];
    public := [=];
    private.frame := frame (parentFrame,expand='x',side='left', relief='raised',
                         borderwidth=1);
    private.fileMenu :=  button (private.frame,'File', relief='flat', type='menu');
    public.dismissButton := button (private.fileMenu, text='Dismiss');

    private.listMenu :=  button (private.frame,'View Code', relief='flat', type='menu');
      # selections don't yet work in the text widget, so disable...
    public.listSelectedFunctionButton := button (private.listMenu, 
                                                 text='Selected Function',
                                                 disabled=T);
    public.listNamedFunctionButton := button (private.listMenu, 
                                             text='Named Function...');

    private.middleSpacer := frame (private.frame,width=30,height=10,borderwidth=0);
    private.rightSide := frame (private.frame,side='right',height=10,borderwidth=0);
    private.helpMenu := button (private.rightSide,text='Help', 
                             relief='flat', disabled=T);
    public.workaround := ref private;  #otherwise private.* are deleted when
                                    # this function goes out of scope
    return ref public;
    }# nested closure object 'menubar'
    #-------------------------------------------------------------------------


  private.parentFrame := frame (title=title,borderwidth=0);
  private.menubar := menubar (private.parentFrame);
  public.dismissButton := ref private.menubar.dismissButton;


   # expose some of the menu buttons so that the client code -- probably some 
   # application -- can manage any coordination it needs, and call back
   # to this closure object as needed.

  public.listNamedFunctionButton := ref private.menubar.listNamedFunctionButton;

  private.topFrame := frame (private.parentFrame, side='left', borderwidth=0);
  private.textWidget := text (private.topFrame, relief='sunken',wrap='none',
                           background='white',width=columns,height=rows,
                           font=defaults.normal_font);
  private.verticalScrollbar := scrollbar (private.topFrame);
  private.bottomFrame := frame (private.parentFrame,side='right',borderwidth=0,
                             expand='x',borderwidth=0);
  private.cornerPad := frame (private.bottomFrame,expand='none',width=23,height=23,
                           relief='groove');
  private.horizontalScrollbar := scrollbar (private.bottomFrame,orient='horizontal');
  
  whenever private.verticalScrollbar->scroll, private.horizontalScrollbar->scroll do {
    private.textWidget->view ($value);
    }

  whenever private.textWidget->yscroll do {
    private.verticalScrollbar->view ($value);
    }

  whenever private.textWidget->xscroll do {
    private.horizontalScrollbar->view ($value);
    }

  public.append := function (newString) {
    wider private;
    private.textWidget->append (newString);
    private.textWidget->append ('\n');
    return T;
    }

  public.clear := function () {
    wider private;
    private.textWidget->delete ('start','end');
    return T;
    }

  public.delete := function () {
    wider private;
    private.parentFrame := F;
    return T;
    }
      
  private.create_function_name_dialog := function (callbackFunction) {
    wider private;
    private.dialogbox := single_entry_dialog_box ('Function', 
                                               public.listNamedFunction);
    }

  public.view_named_function := function (functionName) {
    wider private, public;
    if (!is_string (functionName)) return;
    public.append(paste(functionName,':=',get_function_listing (eval(functionName))));
    return T;
    }

  whenever public.listNamedFunctionButton->press do {
    private.dialogbox := 
       single_entry_dialog_box ('Function Name', public.view_named_function);
    }

  return ref public;

}# tracewindow
#-------------------------------------------------------------------------------
test_tracewindow := function ()
{
  tw := tracewindow ('test tracewindow.g');
  tw.append ('line one');
  tw.append ('line two 898998988888888888 888888888888888888');

  return ref tw;
}
#-------------------------------------------------------------------------------
get_function_listing := function (f) 
{
 if (!is_function (f)) return '<not a function>';
 if (!has_field (f::,'text')) return as_string(f);
 return f::text;
}
#-------------------------------------------------------------------------------
# global functions demonstrating one approach to viewing a function's text
#
# an example of how to transform a glish function into a long string, so that
# it is suitable for display in the tracewindow.  This particular example was
# done by hand, but the transformation is simple, and could be done in software
# automatically -- a perl script is one obvious candidate.  one possibility 
# would be to write a tool which had two inputs: the glish source file (something.g) 
# and a list of functions to extract and transform.
#-------------------------------------------------------------------------------
view_function_test := function (x)
{
  print 'entering view_function_test with argument', x;
  return x + 2;
}
#-------------------------------------------------------------------------------
view_function_test::text := '\
view_function_test := function (x)\n\
{\n\
  print \'entering view_function_test with argument\', x;\n\
  return x + 2;\n\
}\n\
'
#-------------------------------------------------------------------------------
#t2 := test_combobox ();
#t3 := test_status_line ();
#t4 := test_single_entry_dialog_box (cb);
#t5 := test_messagebox ();
#t6 := test_evalwindow ();
#t7 := test_tracewindow ();
#-----------------------------------------------------------------------------
