# tradiobuttons.g: test radiobuttons.g
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


include 'radiobuttons.g'
include 'guientry.g'

dws.tk_hold();
f := dws.frame();
f->unmap();
dws.tk_release();
p := radiobuttons(parent=f, names="r1 r2 r3", default=2, widgetset=dws);
#
b0 := button(f,'Disable widget')
whenever b0->press do {
  p.disabled(disable=T, allbuttons=F);
}
#
b1 := button(f,'Enable widget but not specific buttons')
whenever b1->press do {
  p.disabled(disable=F, allbuttons=F);
}
#
b2 := button(f,'Enable widget and all buttons')
whenever b2->press do {
  p.disabled(disable=F, allbuttons=T);
}
#
f0 := dws.frame(f, side='left');
b2a := button(f0, 'Disable button 1');
whenever b2a->press do {
   p.disablebutton(1);
}
#
b2b := button(f0, 'Enable button 1');
whenever b2b->press do {
   p.enablebutton(1);
}
#
f1 := dws.frame(f, side='left');
b2c := button(f1, 'Disable button 2');
whenever b2c->press do {
   p.disablebutton(2);
}
#
b2d := button(f1, 'Enable button 2');
whenever b2d->press do {
   p.enablebutton(2);
}
#
f2 := dws.frame(f, side='left');
b2e := button(f2, 'Disable button 3');
whenever b2e->press do {
   p.disablebutton(3);
}
#
b2f := button(f2, 'Enable button 3');
whenever b2f->press do {
   p.enablebutton(3);
}
#
f3 := dws.frame(f, side='left');
b3 := button(f3,'Select button r1 on')
whenever b3->press do {
  p.setstate(1, T);
}
#
b4 := button(f3, 'Select button r1 off')
whenever b4->press do {
  p.setstate(1, F);
}
#
f4 := dws.frame(f, side='left');
b5 := button(f4,'Select button r2 on')
whenever b5->press do {
  p.setstate(2, T);
}
#
b6 := button(f4, 'Select button r2 off')
whenever b6->press do {
  p.setstate(2, F);
}
#
f5 := dws.frame(f, side='left');
b7 := button(f5, 'Select button r3 on')
whenever b7->press do {
  p.setstate(3, T);
}
#
b8 := button(f5, 'Select button r3 off')
whenever b8->press do {
  p.setstate(3, F);
}
#
f6 := dws.frame(f, side='left');
b9 := button(f6, 'Get value');
whenever b9->press do {
  print 'Value=', p.getvalue();
}
#
f8 := dws.frame(f, side='left');
b11 := button(f8,'Reset')
whenever b11->press do {
  p.reset();
}
#
f9 := dws.frame(f, side='left');
b12 := button(f9,'Done')
whenever b12->press do {
  p.done();
  val f := F;
}
#
f->map();
