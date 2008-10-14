# dialogbox.g: a widget to gather a simple entry from the user
# Copyright (C) 1996,1997,1998,1999,2000
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
#   $Id: dialogbox.g,v 19.2 2004/08/25 02:13:08 cvsmgr Exp $
 
pragma include once;
include 'widgetserver.g';
include 'unset.g'
include 'note.g'

const dialogbox := function (label=unset, title='Dialog box', 
                             type='entry', value=unset,
                             hlp='', helpOnLabel=T, widgetset=dws)
{
   widgetset.tk_hold();
   f0 := widgetset.frame(title=title, width=200, side='top', expand='x');
   f0->unmap();
   widgetset.tk_release();
   f0.f0 := widgetset.frame(f0, side='left', width=200, expand='x');
#
   text := label;
   defaultValue := value;
   if (type=='entry') {
      if (is_unset(label)) text := 'Enter value';
      f0.f0.l := widgetset.label(f0.f0, text=text);
      f0.f0.eb := widgetset.entry(f0.f0, fill='x');
      if (is_unset(defaultValue)) defaultValue := '';
      if (is_string(defaultValue)) f0.f0.eb->insert(defaultValue);
   } else {
     ge := widgetset.guientry();
#
      if (type=='string') {
         if (is_unset(label)) text := 'Enter string';
         f0.f0.l := widgetset.label(f0.f0, text=text);
         f0.f0.eb := ge.string(parent=f0.f0, value=defaultValue, allowunset=T);
      } else if (type=='file') {
         if (is_unset(label)) text := 'Enter file name';
         f0.f0.l := widgetset.label(f0.f0, text=text);
         f0.f0.eb := ge.file(parent=f0.f0, value=defaultValue, allowunset=T);
      } else if (type=='boolean') {
         if (is_unset(label)) text := 'Select boolean';
         f0.f0.l := widgetset.label(f0.f0, text=text);
         f0.f0.eb := ge.boolean(parent=f0.f0, value=defaultValue, allowunset=T);
      } else if (type=='measure') {
         if (is_unset(label)) text := 'Enter measure';
         f0.f0.l := widgetset.label(f0.f0, text=text);
         f0.f0.eb := ge.measure(parent=f0.f0, value=defaultValue, allowunset=T);
      } else if (type=='quantity') {
         if (is_unset(label)) text := 'Enter quantity';
         f0.f0.l := widgetset.label(f0.f0, text=text);
         f0.f0.eb := ge.quantity(parent=f0.f0, value=defaultValue, allowunset=T);
      } else if (type=='record') {
         if (is_unset(label)) text := 'Enter record';
         f0.f0.l := widgetset.label(f0.f0, text=text);
         f0.f0.eb := ge.record(parent=f0.f0, value=defaultValue, allowunset=T);
      } else if (type=='region') {
         if (is_unset(label)) text := 'Enter region';
         f0.f0.l := widgetset.label(f0.f0, text=text);
         f0.f0.eb := ge.region(parent=f0.f0, value=defaultValue, allowunset=T);
      } else if (type=='scalar') {
         if (is_unset(label)) text := 'Enter scalar';
         f0.f0.l := widgetset.label(f0.f0, text=text);
         f0.f0.eb := ge.scalar(parent=f0.f0, value=defaultValue, allowunset=T);
      } else if (type=='untyped') {
         if (is_unset(label)) text := 'Enter untyped value';
         f0.f0.l := widgetset.label(f0.f0, text=text);
         f0.f0.eb := ge.untyped(parent=f0.f0, value=defaultValue, allowunset=T);
      } else {
         msg := paste(type, ' is an invalid entry widget type');
         return throw(msg, origin='dialogbox.g');
      }
   }
   okhlp := F;
   if (strlen(hlp)>0) {
      if (helpOnLabel) {
         widgetset.popuphelp(f0.f0.l, hlp)
      } else {
         widgetset.popuphelp(f0.f0.eb, hlp);
      }
   }
#
   f0.f1 := widgetset.frame(f0, side='left', width=200);
   f0.f1.space0  := widgetset.frame(f0.f1, side='left', width=1, expand='x', height=1);
   abortValue := '__i_have_aborted';
   f0.f1.abort := widgetset.button(f0.f1, 'Abort', value=abortValue);
   f0.f1.go:= widgetset.button(f0.f1, 'Go', type='action');
   f0.f1.space1  := widgetset.frame(f0.f1, side='left', width=1, expand='x', height=1);
   f0->map();
#
   local itsValue;
   if (type=='entry') {
      await f0.f0.eb->return, f0.f1.go->press, f0.f1.abort->press;
      itsValue := f0.f0.eb->get();
   } else {
      await f0.f0.eb->value, f0.f1.go->press, f0.f1.abort->press;
      itsValue := f0.f0.eb.get();
   }
#
   if (okhlp) popupremove(f0.f0);
   f0->unmap();
   val f0 := F;
   if (is_string($value) && $value==abortValue) {
      fail;
   } else {
      return itsValue;
   }
}
