# displaytext.g: Maintain an editable list of text.
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: displaytext.g,v 19.2 2004/08/25 01:58:45 cvsmgr Exp $
#

pragma include once

#           If frame is left off, create our own top level frame.
# object := display_single_column_text(frame, widgetset) 
#
#    object.write(message)
#    object.done()

include 'widgetserver.g';

const display_single_column_text := function(parent_frame = F, widgetset=dws) {
  if (!widgetset.have_gui()) {
    fail 'display_single_column_text: No GUI (set DISPLAY?)';
  }

  public := [=];
  private := [=];

  widgetset.tk_hold();	  
  if (is_boolean(parent_frame)) {
    private.gui := widgetset.frame(title = 'write text');
  } else {
    private.gui := parent_frame;
  }
      
  private.gui.topframe := 
    widgetset.frame( private.gui, side='left', expand='both');
  private.gui.topframe.text := 
    widgetset.text(private.gui.topframe, relief='sunken', wrap='none',
		   disabled=T);
  
  private.gui.topframe.vsb := widgetset.scrollbar(private.gui.topframe);
  private.gui.bottomframe := widgetset.frame(private.gui, side='right',
					     borderwidth=0);
  private.gui.bottomframe.pad := widgetset.frame(private.gui.bottomframe,
						 expand='none', width=23,
						 height=23, relief='groove');
  private.gui.bottomframe.hsb := widgetset.scrollbar(private.gui.bottomframe, 
						     orient='horizontal');
  widgetset.tk_release();	  

  private.whenevers := [];
  whenever (private.gui.topframe.vsb)->scroll,
    (private.gui.bottomframe.hsb)->scroll do {
      (private.gui.topframe.text)->view($value);
  } private.whenevers[length(private.whenevers)+1] := last_whenever_executed();
  
  whenever private.gui.topframe.text->yscroll do {
      private.gui.topframe.vsb->view($value);
  } private.whenevers[length(private.whenevers)+1] := last_whenever_executed();

  whenever private.gui.topframe.text->xscroll do {
      private.gui.bottomframe.hsb->view($value);
  } private.whenevers[length(private.whenevers)+1] := last_whenever_executed();
  
  whenever private.gui->killed do {
    public.done();
  } private.whenevers[length(private.whenevers)+1] := last_whenever_executed();

  const public.write := function(message) {
    wider private;
    private.gui.topframe.text->insert(message, 'end');
    private.gui.topframe.text->see('end');
  }

  const public.done := function() {
    wider private, public;
    deactivate private.whenevers;
    val private := F;
    val public := F;
    return T;
  }
  
  return ref public;
}

#           If frame is left off, create our own top level frame.
#           ncol         = The number of text columns to display
#           widths       = How wide to make the columns, 25 if omitted
#                          <0 means fixed width, otherwise it can expand.
#           height       = Height (nr of lines)
#           background   = Background of text panes
#           colors       = Colors to display the text in, 'black' if omitted
#           hfcolors     = Tagged foreground color of each column
#           configbg     = Record with background color tags to be configured
#                          fieldname is tag name; value is background color
#           rowseeend    = See the end of a row in each column (not used yet)
#           parent_frame = What to embed ourselves in. A top level frame is
#                          created if none is provided.
#           title        = Title of frame
# object := display_multi_column_text(ncol,widths,height,background,
#                                     colors,hfcolors,
#                                     configbg,rowseeend,frame,title) 
#
#           Write 'message' onto objects display. It should not have a
#           trailing new line since one will be provided. If countnl
#           is F, it is assumed that the messages already line up an
#           no further processing will be performed.
#    object.write(message,countnl=T,highlight=F)
#

const display_multi_column_text := function(ncol, widths=40, height=8,
					    background='xing',
					    colors=F, hfcolors='',
					    configbg=[=], rowseeend=F,
					    parent_frame=F, title=F,
					    widgetset=dws) {
  if (!widgetset.have_gui()) {
    fail 'display_multi_column_text: No GUI (set DISPLAY?)';
  }
  
  if (!is_numeric(widths) || is_boolean(widths)) {
    fail "column widths must be a numeric value";
  }

  if (length(widths) < ncol) {
    start := length(widths) + 1;
    widths[start:ncol] := 40;
  }
  
  private := [=];
  private.ncol := ncol;
  private.autoscroll := T;           # Autoscrolling to the end?
  private.whenevers := [];
  public := [=];
  
  widgetset.tk_hold();	  
  if (is_boolean(parent_frame)) {
    if (is_boolean(title)) {
      title := paste('write text (', as_string(ncol), ' columns)');
    }
    private.gui := widgetset.frame(side='left', title=title);
  } else {
    private.gui := parent_frame;
  }
  
  private.gui.txtcol := [=];
  # Set up the text boxes and vertical scroll bar
  for (i in [1:private.ncol]) {
    expand := 'both';
    width := abs(widths[i]);
    if (widths[i] < 0) expand := 'y';
    private.gui.txtcol[i] := widgetset.frame(private.gui, expand=expand);
    
    color := 'black';         # default to this
    if (length(colors) >= i && is_string(colors) && colors[i] != '') {
      color := colors[i];
    }
    private.gui.txtcol[i].text := 
      widgetset.text(private.gui.txtcol[i], wrap='none', width=width,
		     height=height, foreground=color, background=background,
		     disabled=T);
    if (len(configbg) > 0) {
      fnm := field_names(configbg);
      for (j in 1:len(configbg)) {
 	if (length(hfcolors) >= i  &&  hfcolors[i] != '') {
 	  private.gui.txtcol[i].text->config(fnm[j], background=configbg[j],
					     foreground=hfcolors[i]);
 	} else {
 	  private.gui.txtcol[i].text->config(fnm[j], background=configbg[j]);
 	}
      }
    }
#     private.t[i].rowseeend := F;
#    if (length(rowseeend) >= i) {
#       private.t[i].rowseeend := rowseeend[i];
#    }
  }
  private.gui.vsbcol := widgetset.frame(private.gui, side='top', expand='y',
				   borderwidth=0);
  private.gui.vsbcol.vsb := widgetset.scrollbar(private.gui.vsbcol);
  private.gui.vsbcol.pad := widgetset.frame(private.gui.vsbcol,
					    expand='none', width=23,
					    height=23, relief='groove');

  private.gui.control_text := 1
  whenever private.gui.vsbcol.vsb->scroll do {
    private.gui.txtcol[private.gui.control_text].text->view($value);
  } private.whenevers[length(private.whenevers)+1] := last_whenever_executed();

  for ( i in 1:private.ncol ) {
    private.gui.txtcol[i].text.me := i
    whenever  private.gui.txtcol[i].text->yscroll do {
      if ( private.gui.control_text == $agent.me ) {
        private.gui.vsbcol.vsb->view($value);
        for ( j in 1:private.ncol ) {
          if ( private.gui.txtcol[j].text.me != $agent.me )
            private.gui.txtcol[j].text->view( spaste('yview moveto ',$value[1]) );
        }
      }
    } private.whenevers[length(private.whenevers)+1]:=last_whenever_executed();

    private.gui.txtcol[i].text->bind( '<Enter>', 'enter' )
    whenever  private.gui.txtcol[i].text->enter do {
      private.gui.control_text := $agent.me
    } private.whenevers[length(private.whenevers)+1]:=last_whenever_executed();
  }

  const private.handlehsb := function (whichcol, makesb) {
    wider private;
    private.gui.txtcol[whichcol].hassb := makesb;
    if (!makesb) {
      private.gui.txtcol[whichcol].sbf2->unmap();
    } else {
      private.gui.txtcol[whichcol].sbf2->map();
    }
  }
  
  for (i in 1:private.ncol) {
    # I need to put a frame inside a frame here so that when the inner
    # frame is unmapped the outer frame "holds" the space on the
    # screen.
    private.gui.txtcol[i].sbf1 := 
      widgetset.frame(private.gui.txtcol[i], expand='x', borderwidth=0, 
		      width=1, height=23);
    private.gui.txtcol[i].sbf2 := 
      widgetset.frame(private.gui.txtcol[i].sbf1, expand='x', borderwidth=0,
		      width=1, height=23);
    private.gui.txtcol[i].sbf2.hsb := 
      widgetset.scrollbar(private.gui.txtcol[i].sbf2, orient='horizontal');
    # Small fixed columns do not need a scrollbar (since a scrollbar
    # is at least 5 characters wide). 
    private.handlehsb(i, widths[i] < -4  ||  widths[i] > 0);

    private.gui.txtcol[i].sbf2.hsb.mate := ref private.gui.txtcol[i].text;
    whenever private.gui.txtcol[i].sbf2.hsb->scroll do {
      $agent.mate->view($value);
#		    if ($agent.mate.rowseeend) {
#		        $agent.mate.rowseeend := F;
#		    }
    } private.whenevers[length(private.whenevers)+1]:=last_whenever_executed();
    private.gui.txtcol[i].text.mate := ref private.gui.txtcol[i].sbf2.hsb;
    whenever private.gui.txtcol[i].text->xscroll do {
      $agent.mate->view($value);
#	            if ($agent.rowseeend) {
#		        $agent.rowseeend := F;
#	            }
    } private.whenevers[length(private.whenevers)+1]:=last_whenever_executed();
  }
  
  widgetset.tk_release();	  

  whenever private.gui->killed do {
    public.done();
  } private.whenevers[length(private.whenevers)+1] := last_whenever_executed();

  const public.write := function(messages, countnl=T, highlight='') {
    wider private;
    if (length(messages) > private.ncol) {
      fail "Too many messages provided";
    }
    for (i in [1:length(messages)]) { 
      if (highlight == '') {
 	private.gui.txtcol[i].text->insert(messages[i], 'end');
      } else {
 	private.gui.txtcol[i].text->insert(messages[i], 'end', highlight);
      }
    }
    maxnewlines := 0;
    if (countnl) {
      numbernewlines[1:private.ncol] := 0;
      for (i in [1:length(messages)]) { 
 	# Count how many lines are in the current message so we can
 	# synchronize
 	numbernewlines[i] := messages[i] ~ m/\n/g;
      }
      # Synchronize vertical positions
      maxnewlines := max(numbernewlines);
      for (i in 1:private.ncol) {
 	for (j in [numbernewlines[i]:maxnewlines]) {
 	  if (highlight == '') {
 	    private.gui.txtcol[i].text->insert('\n', 'end');
 	  } else {
 	    private.gui.txtcol[i].text->insert('\n', 'end', highlight);
 	  }
 	}
      }
    }
    if (private.autoscroll) {
      public.seeend();
    }
  }
  
  const public.setautoscroll := function(autoscroll) {
    wider private;
    private.autoscroll := autoscroll;
  }
  
  const public.setcolumnview := function(whichcol, pos) {
    if (whichcol <= 0 || whichcol > private.ncol) {
      fail 'Illegal column number';
    }
    private.gui.txtcol[whichcol].text->see(pos);
  }
  
  const public.setheight := function(height) {
    for (i in [1:private.ncol]) {
      private.gui.txtcol[i].text->height(height);
    }
  }
  
  const public.setcolumnwidth := function(whichcol, width) {
    if (whichcol <= 0 || whichcol > private.ncol) {
      fail 'Illegal column number';
    }
    private.handlehsb (whichcol, width>4);
    private.gui.txtcol[whichcol].text->width(width);
  }
  
  const public.contents := function(whichcol) {
    wider private;
    if (whichcol <= 0 || whichcol > private.ncol) {
      fail 'Illegal column number';
    }
    results := private.gui.txtcol[whichcol].text->get('start', 'end');
    return results;
  }
  
  const public.seeend := function() {
    for (i in [1:private.ncol]) {
      private.gui.txtcol[i].text->see('end');
    }
  }
  
  const public.done := function() {
    wider private, public;
    deactivate private.whenevers;
    val private := F;
    val public := F;
    return T;
  }
  
  return ref public;
}

const display_multi_column_text_demo := function() {
  d := display_multi_column_text(3, widths=[-3, 10],
				 colors="red blue",
				 title = "demo/test");
  if (is_fail(d)) fail;
  for (i in [1:200]) {
    d.write([as_string(i), 'Now this message is overly long', 'ho hum']);
  }
  i +:= 1;
  d.write([as_string(i), 'This is a\nmulti-row\nmessage',
	   'This is a very long message that you should be able to scroll']);
  i +:= 1;
  d.write([as_string(i), 'ho hum', 'make sure you can scroll vertically']);
  return T;
}

const display_multi_column_text_test := display_multi_column_text_demo;
