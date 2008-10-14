# tpixelrange.g: test pixelrange.g
#
#   Copyright (C) 1996,1997,1998,1999
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
#   $Id: 

include 'pixelrange.g'
include 'guientry.g'

dws.tk_hold();
f := dws.frame()
f->unmap();
dws.tk_release();
p := pixelrange(parent=f, min=0, max=10, widgetset=dws);
#
f0 := dws.frame(f, side='left')
b0 := button(f0, 'Disable widget')
whenever b0->press do {
  p.disabled(which=T, sliders=T);
}
#
b1 := button(f0, 'Enable widget')
whenever b1->press do {
  p.disabled(which=F, sliders=F);
}
#
f1 := dws.frame(f, side='left')
b2 := button(f1, 'Disable radioentries')
whenever b2->press do {
  p.disabled(which=T);
}
#
b3 := button(f1,'Enable radioentries')
whenever b3->press do {
  p.disabled(which=F);
}
#
f2 := dws.frame(f, side='left')
b4 := button(f2,'Disable sliders')
whenever b4->press do {
  p.disabled(sliders=T);
}
#
b5 := button(f2,'Enable sliders')
whenever b5->press do {
  p.disabled(sliders=F);
}
#
f3 := dws.frame(f, side='left')
b6 := button(f3,'Disable all button')
whenever b6->press do {
  p.disableallbutton()
}
#
 b7 := button(f3,'Enable all button')
whenever b7->press do {
  p.enableallbutton();
}
#
f4 := dws.frame(f, side='left')
b8 := button(f4, 'Get slider values');
whenever b8->press do {
  print 'Values=', p.getslidervalues();
}
#
b9 := button(f4, 'Get radio value');
whenever b9->press do {
  print 'Radio values=', p.getradiovalue();
}
#
f5 := dws.frame(f, side='left')
b10 := button(f5, 'Set new range');
whenever b10->press do {
 r := dge.array();
 whenever r->value do {
    r2 := r.get();
    p.setrange(min=r2[1], max=r2[2]);
    r.done();
 }
}
#
f6 := dws.frame(f, side='left')
b11 := button(f6, 'Select include');
whenever b11->press do {
    p.setradiovalue('include', T);
}
#
b12 := button(f6, 'Select exclude');
whenever b12->press do {
    p.setradiovalue('exclude', T);
}
#
b13 := button(f6, 'Select all');
whenever b13->press do {
    p.setradiovalue('all', T);
}
#
f7 := dws.frame(f, side='left')
b14 := button(f7, 'Done')
whenever b14->press do {
  p.done();
  val f := F;
}
#
f->map();
