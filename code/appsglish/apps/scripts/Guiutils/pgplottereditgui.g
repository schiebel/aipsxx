# pgplotter.g: Standalone GUI PGPLOT (etc) window.
#
#   Copyright (C) 1998,1999,2000,2001,2002
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
#   $Id: pgplottereditgui.g,v 19.2 2004/08/25 02:00:44 cvsmgr Exp $
#


pragma include once;

include 'note.g';
include 'widgetserver.g';
    
pgplottereditgui := function(plotter, widgetset=dws)
{

  include 'types.g';
  types.includemeta();

  public := [=];

  private := [=];

  private.pgplotter := plotter;

  private.widgetset := widgetset;

  private.edititem := unset;

  old := private.pgplotter.record(F);
  private.pgplotter.message('Initializing for editing....');
  private.widgetset.tk_hold();
  include 'displaylist.g';
  private.egui := [=];
  private.egui.wholeframe :=
      private.widgetset.frame(title='pgplotter editor (AIPS++)', 
			      side='top');
  private.pgplotter.displaylist().gui(private.egui.wholeframe);
  if(has_field(private.pgplotter, 'refresh')) {
    private.pgplotter.displaylist().setrefreshcallback(private.pgplotter.refresh);
    private.pgplotter.displaylist().setchangecallback(private.pgplotter.refresh);
  }
  include 'serverguibasefunction.g';
  private.egui.bf :=
      serverguibasefunction('pgplotter', 
			    parent=private.egui.wholeframe,
			    filter=private.pgplotter.canplay,
			    widgetset=widgetset);
  
  if(is_fail(private.egui.bf)) {
    private.widgetset.tk_release();
    return throw('Cannot make edit gui ', private.egui.bf::message);
  }


  private.egui.actionframe :=
      private.widgetset.frame(private.egui.wholeframe, 
			      side='left');
  private.egui.adddlbutton :=
      private.widgetset.button(private.egui.actionframe, 'Add to Drawlist');
  private.egui.addbutton.shorthelp := 'Add current function to the Drawlist';
  whenever private.egui.adddlbutton->press do {
    rec := [=];
    rec := private.egui.bf.get();
    rec._method := private.egui.bf.getmethod();
    private.pgplotter.displaylist().add(rec, T);
    private.edititem := unset;
    private.pgplotter.refresh();
  }
  whenever private.egui.bf->changenotice do {
    rec := [=];
    rec := private.egui.bf.get();
    rec._method := private.egui.bf.getmethod();
    if(is_numeric(private.edititem)&&(private.edititem>0)&&
       (private.edititem<=private.pgplotter.displaylist().ndrawlist())) {
      private.pgplotter.displaylist().set(private.edititem, rec);
    }
    private.pgplotter.refresh();
  }
  private.egui.addbutton :=
      private.widgetset.button(private.egui.actionframe, 'Add to Clipboard');
  private.egui.addbutton.shorthelp := 'Add current function to the clipboard';
  whenever private.egui.addbutton->press do {
    private.edititem := unset;
    rec := [=];
    rec := private.egui.bf.get();
    rec._method := private.egui.bf.getmethod();
    private.pgplotter.displaylist().add(rec, F);
    private.edititem := unset;
    private.pgplotter.refresh();
  }
  private.egui.dismissframe :=
      private.widgetset.frame(private.egui.actionframe, 
			      side='right');
  private.egui.dismiss :=
      private.widgetset.button(private.egui.dismissframe, 'Dismiss',
			       type='dismiss');
  
  whenever private.egui.dismiss->press do {
    private.egui.wholeframe->unmap();
  }
  whenever private.egui.wholeframe->killed do {
    private.egui.bf.done();
    private.egui.wholeframe->unmap();
    private.egui.wholeframe := F;
    private.egui := F;
  }
  # Callback when an item in the drawlist is selected
  private.egui.callback.drawlist := function(which) {
    wider private;
    private.widgetset.tk_hold();
    tmp := private.pgplotter.displaylist().get(which);
    method := tmp._method;
    private.egui.bf.front(unset, tmp._method, tmp);
    private.edititem := which;
    private.widgetset.tk_release();
  }
  # Callback when an item in the clipboard is selected
  private.egui.callback.clipboard := function(which) {
    wider private;
    private.edititem := unset;
    private.widgetset.tk_hold();
    tmp := private.pgplotter.displaylist().get(which, F);
    method := tmp._method;
    private.egui.bf.front(unset, tmp._method, tmp);
    private.widgetset.tk_release();
  }
  private.pgplotter.displaylist().setselectcallback(private.egui.callback.drawlist);
  private.pgplotter.displaylist().setselectcallback(private.egui.callback.clipboard,
						    'clipboard');
  if(has_field(private.pgplotter, 'refresh')) {
    private.pgplotter.displaylist().setrefreshcallback(private.pgplotter.refresh);
  }
  
  public.done := function() {
    wider private;
    
    # Get rid of subwindows if necessary
    for (i in "egui") {
      if (has_field(private, i) && is_record(private[i]) &&
	  has_field(private[i], 'wholeframe') && 
	  is_agent(private[i].wholeframe)) {
	private[i].wholeframe->unmap();
	private[i].wholeframe := F;
      }
    }

    val public := F;
    val private := F;
    return T;
  }

  public.map := function() {
    wider private;
    if(is_record(private)&&has_field(private, 'egui')) {
      private.egui.wholeframe->map();
    }
    return T;
  }

  if(private.pgplotter.displaylist().ndrawlist()) {
    private.egui.callback.drawlist(1);
  } else if(private.pgplotter.displaylist().nclipboard()) {
    private.egui.callback.clipboard(1);
  }
  else {
    private.egui.bf.front(unset, 'plotxy');
  }

  private.widgetset.tk_release();
  private.pgplotter.message('');
  private.pgplotter.record(old);

  return ref public;
  
}

