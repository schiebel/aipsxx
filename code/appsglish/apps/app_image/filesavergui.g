# filesavergui.g: GUI to get table name and type from user 
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003,2004
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
#   $Id: filesavergui.g,v 1.6 2004/08/25 00:56:36 cvsmgr Exp $
#


pragma include once
include 'note.g';
include 'widgetserver.g';



const filesavergui := subsequence (widgetset=dws)
{
   if (!have_gui()) {
      return throw('No Gui is available, possibly the  DISPLAY environment variable is not set',
                   origin='filesavergui.g');
   }
#
   its := [=];
#
   its.ws := widgetset;
   its.f0 := F;
#


### Private functions
### Public functions
    const self.gui := function ()
    {
       wider its;
       return its.f0->map();
    }

###
    const self.dismiss := function ()
    {
       wider its;
       return its.f0->unmap();
    }
 
###
    const self.done := function ()
    {
       wider its;
       wider self;
#
       its.f0 := F;
       val its := F;
       val self := F;
       return T;
    }

###
    const self.insertfilename := function (filename)
    {
       wider its;
#
       return its.f0.f0.entry->insert(filename);
    }

### Constructor

    its.ws.tk_hold();
    its.f0 := its.ws.frame(title='Save Plot Data');
    its.f0->unmap();
    its.ws.tk_release();
#
    its.f0.f0 := its.ws.frame (its.f0, side='left');
    its.f0.f0.label := its.ws.label (its.f0.f0, 'File Name');
    its.ws.popuphelp (its.f0.f0.label, 'File name for output file');
    its.f0.f0.entry := its.ws.entry (its.f0.f0);
#
    its.f0.f2 := its.ws.frame (its.f0, side='left');
    its.f0.f2.aipspp := its.ws.button (its.f0.f2, 'aips++', type='radio');
    its.ws.popuphelp (its.f0.f2.aipspp, 'Store data in an aips++ table');
    its.f0.f2.ascii := its.ws.button (its.f0.f2, 'ascii', type='radio');
    its.ws.popuphelp (its.f0.f2.ascii, 'Store data in an ascii table');
    its.f0.f2.ascii->state(T);
#
    its.f0.f2.overwrite := its.ws.button(its.f0.f2, type='check', text='Overwrite');
    its.ws.popuphelp (its.f0.f2.overwrite, 'Overwrite any existing output file');
    its.f0.f2.overwrite->state(T);
#
    its.f0.f2.dataonly := its.ws.button(its.f0.f2, type='check', text='DataOnly');
    its.ws.popuphelp (its.f0.f2.dataonly, 'Save just the data, not the estimate/fits');
    its.f0.f2.dataonly->state(F);
#
    its.f0.f1 := its.ws.frame (its.f0, side='left');
    its.f0.f1.space := its.ws.frame (its.f0.f1, side='left', height=1, expand='x')
    its.f0.f1.dismiss := its.ws.button(its.f0.f1, type='dismiss', text='Dismiss');
    its.ws.popuphelp (its.f0.f1.dismiss, 'Dismiss the GUI');
    whenever its.f0.f1.dismiss->press do {
       self.dismiss();
    }
    its.f0.f1.go := its.ws.button(its.f0.f1, type='action', text='Go');
    its.ws.popuphelp (its.f0.f1.go, 'Save the data, estimate and fit in the specified file');
    whenever its.f0.f1.go->press do {
       fn := its.f0.f0.entry->get();
       if (fn=='') {
          note ('You must enter a file name');
       } else {
          r := [=];
          r.filename := fn;
          r.ascii := its.f0.f2.ascii->state();
          r.overwrite := its.f0.f2.overwrite->state();
          r.dataonly := its.f0.f2.dataonly->state();
          self->go(r);
          self.dismiss();
       }
    }
}
