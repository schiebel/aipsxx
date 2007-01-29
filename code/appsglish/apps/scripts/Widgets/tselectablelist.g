# tselectablelist.g: test script for selectablelist.g widget
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
#   $Id: tselectablelist.g,v 19.2 2004/08/25 02:21:57 cvsmgr Exp $
#
include 'widgetserver.g'

#
f := frame();
list := [=];
list[1] := "lab1 lab2 lab3 lab444444 lab5 lab6";
list[2] := "lab1 lab2 lab3 lab4 lab5 lab6 lab7 lab8 lab9";
idx := 1;
s1 := dws.selectablelist(f,lead=f,list=list[idx], label='Fixedlabel', updatelabel=F, width=-1);
s2 := dws.selectablelist(f,lead=f,list=list[idx], label='Autolabel', updatelabel=T, width=-1);
s3 := dws.selectablelist(f,lead=f,list=list[idx], label='Autolabel', updatelabel=T, width=-1, nbreak=4);

whenever s1->select do {
  print 'value1 = ', $value
}
whenever s2->select do {
  print 'value2 = ', $value
}
#
b0 := button(f, 'disable')
whenever b0->press do {
   s1.disabled(T);
   s2.disabled(T);
   s3.disabled(T);
}
b1 := button(f, 'enable')
whenever b1->press do {
   s1.disabled(F);
   s2.disabled(F);
   s3.disabled(F);
}
b3 := button(f,'Replace')
whenever b3->press do {
   if (idx==1) {
      idx := 2;
   } else {
      idx := 1;
   }
   s1.replace(lead=f, list=list[idx], label='Fixedlabel', updatelabel=F, width=-1);
   s2.replace(lead=f, list=list[idx], label='Autolabel', updatelabel=T, width=-1);
   s3.replace(lead=f, list=list[idx], label='Autolabel', updatelabel=T, width=-1);
}
b4 := button(f, 'done')
whenever b4->press do {
   s1.done();
   s2.done();
   s3.done();
   val f := F;
}

