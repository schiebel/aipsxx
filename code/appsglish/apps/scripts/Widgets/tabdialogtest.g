 # tabdialogtest.g: test tabdialog.g widget
# for the image Distributed Object
# Copyright (C) 1996,1997,1998,1999,2000,2001
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
#
# $Id: tabdialogtest.g,v 19.3 2005/04/14 21:19:12 dking Exp $

pragma include once;
include 'widgetserver.g'
include 'tabdialog.g'

const tabdialogwidgettest := function (widgetset=dws)
{
#
# Set up three tabs
#
   widgetset.tk_hold();
   f0 := widgetset.frame(side='top');
   f0->unmap();
   widgetset.tk_release();
   t:=tabdialog(f0, colmax=3, widgetset=widgetset);
   if (is_fail(t)) fail;
   state := -1;
#
   ft := t.dialogframe()
   frames := [=];
   for (i in 1:3) {
      fn := spaste(i);
#
      frames[fn] := widgetset.frame(ft);
      frames[fn]->unmap();
      txt := spaste('tabcontents',fn);
      frames[fn].b := widgetset.button(frames[fn], txt);
#
      txt := spaste('tab', fn);
      t.add(frames[fn], txt);
   }
   f0->map();
#
# Do some things with them
#
   f1 := widgetset.frame(f0, side='left');
#
   f1.b00 := widgetset.button(f1, 'Which');
   whenever f1.b00->press do {
      print t.which();
   }

   f1.b0 :=  widgetset.button(f1, 'Replace');
   whenever f1.b0->press do {
      n := length(frames);
      if (state==-1) {
         for (i in 1:n) {
            fn := spaste(n-i+1);
            tn := spaste('tab',i);
            if(t.available(tn)) t.replace(frames[fn], tn);
         }
      } else {
         for (i in 1:n) {
            fn := spaste(i);
            tn := spaste('tab',i);
            if(t.available(tn)) t.replace(frames[fn], tn);
         }
      }
      state *:= -1;
   }
#
   f1.b2 :=  widgetset.button(f1, 'Add');
   whenever f1.b2->press do {
      n := length(frames) + 1;
      fn := spaste(n);
#
      frames[fn] :=  widgetset.frame(ft);
      frames[fn]->unmap();
      txt := spaste('tabcontents',fn);
      frames[fn].b :=  widgetset.button(frames[fn], txt);
#
      txt := spaste('tab', fn);
      t.add(frames[fn], txt);
      if (n==1) t.front('tab1');
}
   f1.b4 := widgetset.button(f1, 'Delete');
   whenever f1.b4->press do {
     t.delete(t.which().name);
   }
#
   f1.b1 :=  widgetset.button(f1, 'Delete-all');
   whenever f1.b1->press do {
      t.deleteall();
      frames := [=];
   }
#
   f1.b3 :=  widgetset.button(f1, 'Done');
   whenever f1.b3->press do {
      t.done();
      val f0 := F;
   }
#
   return T;
}
