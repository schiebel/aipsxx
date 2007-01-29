# printer.g: Access to printing
# Copyright (C) 1996,1997,1998,1999,2000,2002
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
# $Id: printer.g,v 19.2 2004/08/25 02:03:37 cvsmgr Exp $

pragma include once;

# prn := printer(printername, mode, paper, display, note, printcommand)
#        prn.reinit(printername, mode, paper, display) [ADD printcommand?]
#        prn.print(files,remove)
#        prn.gui(files,remove,landscape)
#        prn.printvalues(values, needcr, usegui)

include "guiframework.g";
include "infowindow.g";
include "note.g";
include "os.g";
include "misc.g";
include "aipsrc.g";
include "widgetserver.g"

printer := function (printername=F, mode='p', paper=F, display=F,
		     printernote=note, printcommand='pri',
		     widgetserver=dws)
{
  self := [=];
  public := [=];

  self.note := printernote;
  self.print_command := printcommand;
  self.ghostview := 'ghostview';

  assign := function (ref out, from) {val out := from;}

  public.done := function ()
  {
     wider self;
     wider public;
     val self := F;
     val public := F;
     return T;
  }

  public.reinit := function (printername=F, mode='p', paper=F, display=F)
  {
    wider self;

    drc.init();			# in case the user defines a printer later

    if (is_string (printername)) {
      assign (self.printer_name, printername);
    } else {
      # aipsrc code goes here
      if (has_field (environ, "PRINTER")) {
	assign (self.printer_name, environ.PRINTER);
      } else if (drc.find (self.printer_name, "printer.default")) {
	# Nothing - assigned as a side-effect
      } else {
	self.printer_name := 'NO_PRINTER_SET';
      }
    }
    if (!is_string (mode) || (mode != 'p' && mode != 'l' && mode != '80' &&
			      mode != '72')) {
      self.note ('Mode must be l,p,80 or 72', origin='printer::print');
      fail 'Mode must be l,p,80 or 72';
    }
    self.mode := mode;

    if (is_string (paper)) {
      if (paper != 'l' && paper != '3' && paper != '4') {
        if (paper != 'US Letter' && paper != 'A4' && paper != 'A3') {
          self.note ('Paper must be l,3,4 (or US Letter, A4, A3)',
		     origin='printer::print');
          fail 'Paper must be l,3,4 (or US Letter, A4, A3)';
        }
      }
      self.paper := paper;
    } else {
      if (! drc.find (self.paper, "printer.paper")) {
	self.paper := 'l';
      }
    }
    if (self.paper == 'A4'  ||  self.paper == '4') {
      self.paper := '4';
    } else if (self.paper == 'A3'  ||  self.paper == '3') {
      self.paper := '3';
    } else {
      self.paper := 'l';
    }

    if (! is_boolean (display)) {
      self.note ('Display must be boolean', origin='printer::print');
      fail 'Display must be boolean';
    }
    self.display := display;

    return T;
  }

  assign (ok, public.reinit (printername, mode, paper, display));

  public.print := function (files, remove=F)
  {
    wider self;

    # remove has been removed for safty sake.
    remove := F;

    if (! is_string (files)) {
      self.note ('files is not a string',origin='printer::print');
      fail 'files is not a string';
    }
    print_command := self.print_command;
    print_command[2] := '-m';
    print_command[3] := self.mode;
    print_command[4] := '-p';
    print_command[5] := self.paper;
    print_command[6] := '-P';

    if (self.display) {
      print_command[7] := self.ghostview;
    } else {
      print_command[7] := self.printer_name;
    }
    note := paste('Printing (command=', print_command,')');
    # If necessary remove the files after printing them.
    delcommand := '; rm -fr ';

    for (i in 1:length (files)) {
      if (! dos.fileexists (files[i])) {
	self.note (paste (files[i],'does not exist'), priority='SEVERE', 
		   origin='printer::print');
      } else {
	assign (note, paste(note, '\n\t', files[i]));
	print_command[length (print_command)+1] := files[i];
	assign (delcommand, paste(delcommand, files[i]));
      }
    }
    if (length (print_command) > 7) {
      # No longer allow removing of files, too dangerous
      #if (remove) {
#	assign (note, paste(note, '\nDeleting files after spooling'));
#	assign (print_command, paste(print_command, delcommand));
#      }
      self.prtagent := shell (print_command, async=T);
      if (is_fail(self.prtagent)) fail;
    } else {
      assign (note, paste('No valid files!!'));
    }
    self.note (note, origin='printer::print');

    return T;
  }

  self.busy := function(isbusy = T) {
    wider self;
    if (isbusy) {
      self.wholeframe->cursor('watch');
      self.wholeframe->disable();
    } else {
      self.wholeframe->cursor('left_ptr');
      self.wholeframe->enable();
    }
  }

  self.printfunction := function ()
  {
    wider self;
    wider public;

    self.files := self.filesentry->get ();
    self.printer_name := self.printerentry->get ();

    if (length (self.files) == 0 || (length (self.files)==1 &&
				     self.files[1] == '')) {
      self.note ('Not printing any files', origin='printer::gui');
      a := infowindow ('No files to print', 'AIPS++ Printer Control');
    } else {

      self.busy(T);
      public.print (self.files, self.remove);
      self.busy(F);
      self.gf.dismiss ();
    }
  }

  public.gui := function (files="", remove=F, landscape=F)
  {
    wider self;

    files := as_string (files);
    self.files := files;
    self.remove := remove;

    if (landscape) {
      self.mode := 'l';
    }
    if (!have_gui ()) {
      self.note ('Does not appear to be connected to a windowing system',
		 priority='SEVERE', origin='printer::gui');
      fail 'Does not appear to be connected to a windowing system';
    }

    ### buffer
    tk_hold();

    # set the help menu
    helpmenu := [=];
    helpmenu::useWidget := T;
    helpmenu.print := [=];
    helpmenu.print.text := 'Printing';
    helpmenu.print.action := 'Refman:misc.printer';
    # set the action buttons
    actions := [=];
    actions.print := [=];
    actions.print.text := 'Print';
    actions.print.type := 'action';
    actions.dismiss := [=];
    actions.dismiss.text := 'Dismiss';
    actions.dismiss.type := 'dismiss';
    # top frame
    self.gf := guiframework ('AIPS++ Printer control', F, helpmenu, actions);
    self.gf.addactionhandler ('dismiss', self.gf.dismiss);
    self.gf.addactionhandler ('print', self.printfunction);
    # Get the workframe and do everything else the same.
    self.wholeframe := self.gf.getworkframe ();
    #
    self.filesframe := widgetserver.frame (self.wholeframe, side='left');
    self.fileslabel := widgetserver.label (self.filesframe, 'Files:',width=20);
    self.filesentry := widgetserver.entry (self.filesframe);

    if (length (files) > 0) {
      self.filesentry->insert (files);
      self.filesentry->disabled (T);
    } else {
      whenever self.filesentry->return do {
	self.files := $value;
      }
    }
    # Note the remove option has been removed to protect the innocent
    # Remove
    #self.removeframe := widgetserver.frame (self.wholeframe, side='left');
    #self.removelabel := widgetserver.label (self.removeframe, 'Remove after printing:',
			       #width=20);
    #self.removebutton := widgetserver.button (self.removeframe, 'Yes',
					      #type='check', relief='flat');
    #self.removebutton->state (self.remove);
#
    #whenever self.removebutton->press do {
      #self.remove := $agent->state ();
    #}
    # printer
    self.printerframe := widgetserver.frame (self.wholeframe, side='left');
    self.printerlabel := widgetserver.label (self.printerframe, 'Printer:',width=20);
    self.ghostviewbutton := widgetserver.button (self.printerframe, 'Ghostview',
						 type='radio', relief='flat');
    self.printerbutton := widgetserver.button (self.printerframe, 'Printer',
					       type='radio', relief='flat');
    self.printerentry := widgetserver.entry (self.printerframe);
    self.printerentry->insert (self.printer_name);

    if (self.display) {
      self.ghostviewbutton->state (T);
      self.printerentry->disabled (T);
    } else {
      self.printerbutton->state (T);
      self.printerentry->disabled (F);
    }
    whenever self.ghostviewbutton->press do {
      self.printerentry->disabled (T);
      self.display := T;
    }
    whenever self.printerbutton->press do {
      self.printerentry->disabled (F);
      self.display := F;
    }
    self.orientframe := widgetserver.frame (self.wholeframe, side='left');
    self.orientlabel := widgetserver.label (self.orientframe, 'Orientation:',width=20);
    self.orientmenu :=
	widgetserver.optionmenu (self.orientframe,
				 ['Portrait', 'Landscape', '2-Up'],
				 ['Portrait', 'Landscape', '2-Up'],
				 ['p', 'l', '80']);
    self.orientmenu.selectvalue (self.mode);
						
    whenever self.orientmenu->select do {
      self.mode := self.orientmenu.getvalue();
    }

    self.paperframe := widgetserver.frame (self.orientframe, side='left');
    self.paperlabel := widgetserver.label (self.paperframe, 'Paper:',width=20);
    self.papermenu :=
	widgetserver.optionmenu (self.paperframe,
				 ['US Letter', 'A4', 'A3'],
				 ['US Letter', 'A4', 'A3'],
				 ['l', '4', '3']);
    self.papermenu.selectvalue (self.paper);
						
    whenever self.papermenu->select do {
      self.paper := self.papermenu.getvalue();
    }

    tk_release();
    return T;
  }

  public.printvalues := function (values, needcr=T, usegui=F)
  {
    assign (filename, spaste ('/tmp/aips_print.', system.pid));
    assign (fd, dms.fopen(filename, 'w'));

    for (i in 1:length (values)) {
      if (needcr) {
	assign (n, dms.fprintf (fd, '%s\n', as_string (values[i])));
      } else {
	assign (n, dms.fprintf(fd, '%s', as_string(values[i])));
      }
      if (n < 0) {
	self.note ('fprintf fails', priority='SEVERE', origin='printer::printvalues');
	fail 'fprintf fails';
      }
    }
    dms.fclose (fd);

    if (usegui) {
      return public.gui (filename, remove=T);
    } else {
      return public.print (filename, remove=T);
    }
  }

  public.type := function() {
    return 'printer';
  }

  return ref public;
}
