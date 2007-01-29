# tExtendOptionMenu.g: test script for extendoptionmenu.g widget
#
#   Copyright (C) 1996,1997,1998,1999,2000
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
#
include 'widgetserver.g'
include 'timer.g'
#
const doit := function(ref error, m, labels)
{
   nLabels := length(labels);
#
   if (m.getlabels()!=labels) {
      val error := 'getlabels failed';
      return F;
   }
#
   if (m.getlabel()!=labels[1]) {
      val error := 'getlabel failed';
      return F;
   }
#
#
   if (m.getindex()!=1) {
      val error := 'getindex failed';
      return F;
   }
#
   if (m.findlabel(labels[nLabels]) != nLabels) {
      val error := 'findlabel failed';
      return F;
   }
#
   m.selectindex(nLabels);
   if (m.getlabel() != labels[nLabels]) {
      val error := 'selectindex failed';
      return F;
   }
#
   m.selectlabel(labels[nLabels]);
   if (m.getlabel() != labels[nLabels]) {
      val error := 'selectlabel failed';
      return F;
   }
#
   m.selectindex(3);
   m.selectindex(2);
   if (m.getpreviousindex() != 3) {
      val error := 'getpreviousindex failed';
      return F;
   }
   return T;
}
#
#
#
f := dws.frame();
labels := "lab1 lab2 lab3"
m1 := dws.extendoptionmenu(f, labels, 'Flatmenu')
m2 := dws.extendoptionmenu(f, labels, 'Listbox', nbreak=1)
whenever m1->select do {
   print 'm1: selection made, value=', $value
}
whenever m1->replaced do {
   print 'm1: replacement done'
}
whenever m2->select do {
   print 'm2: selection made, value=', $value
}
whenever m2->replaced do {
   print 'm2: replacement done'
}
#
print 'disable, wait 2 seconds, enable'
m1.disabled(T);
m2.disabled(T);
timer.wait(2);
m1.disabled(F);
m2.disabled(F);
print ' '
#
print 'foreground red, wait 2 seconds, foreground black'
m1.setforeground('red');
m2.setforeground('red');
timer.wait(2);
m1.setforeground('black');
m2.setforeground('black');
print ' '
#
print 'background red, wait 2 seconds, background grey'
m1.setbackground('red');
m2.setbackground('red');
timer.wait(2);
m1.setbackground('lightgrey');
m2.setbackground('lightgrey');
print ' '
#
print 'test basic menu'
if (!doit(error, m1, labels)) {
  print 'm1 failed because', error
  fail;
}
print 'test basic menu'
if (!doit(error, m2, labels)) {
  print 'm2 failed because', error
  fail;
}
#
print ' '
print 'test extended menu'
labels2 := "lab4 lab5";
m1.extend(labels2);
m1.selectindex(1);
if (!doit(error, m1, [labels,labels2])) {
  print 'm1 failed because', error
  fail;
}
m2.extend(labels2);
m2.selectindex(1);
if (!doit(error, m2, [labels,labels2])) {
  print 'm2 failed because', error
  fail;
}
#
print ' '
print 'test replace menu'
labels3 := "x y z";
m1.replace (labels3);
m1.selectindex(1);
if (!doit(error, m1, labels3)) {f
  print 'm1 failed because', error
  fail;
}
m2.replace (labels3);
m2.selectindex(1);
if (!doit(error, m2, labels3)) {
  print 'm2 failed because', error
  fail;
}
#
print 'ok'
