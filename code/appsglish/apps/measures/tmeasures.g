# tmeasures.g: Test the measures object
# Copyright (C) 1998,2000
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: tmeasures.g,v 19.2 2004/08/25 01:30:12 cvsmgr Exp $
#
pragma include once

# Stop gui logging and measures gui etc
system.use_gui := F;
{
  local s_have_gui := have_gui;
  func have_gui( ) system.use_gui && s_have_gui();
}
global_use_gui := 0;	
include "measures.g";
#
##defaultservers.trace(T)
##defaultservers.suspend(T)
#
# Test function
#
const tmeasures := function() {
#
# final result
#
  result := T;
#
# Some aid functions
#
# quantity test
#
  qtst := function(a0, a1, txt='', prec=1e-12) {
    wider result;
    if (abs(dq.canon(a0).value - dq.canon(a1).value) > prec ||
	dq.canon(a0).unit != dq.canon(a1).unit) {
      print paste('tmeasures error for',txt,'--',a0,':',a1);
      result := F;
    };
  }
#
# value test
#
  vtst := function(a0, a1, txt='', prec=1e-12) {
    wider result;
    if (abs(a0-a1) > prec) {
      print paste('tmeasures error for',txt,'--',a0,':',a1);
      result := F;
    };
  }
#
# string test
#
  stst := function(a0, a1, txt='') {
    wider result;
    if (a0 != a1) {
      print paste('tmeasures error for',txt,'--',a0,':',a1);
      result := F;
    };
  }
#
# true test
#
  ttst := function(a0, txt='') {
    wider result;
    if (!a0) {
      print paste('tmeasures error for',txt,'--',a0);
      result := F;
    };
  }
#
# fail test
#
  fltst := function(a0, txt='') {
    wider result;
    if (is_fail(a0)) {
      print paste('tmeasures error for',txt,'--',a0);
      result := F;
    };
  }
#
# false test
#
  ftst := function(a0, txt='') {
    wider result;
    if (a0) {
      print paste('tmeasures error for',txt,'--',a0);
      result := F;
    };
  }
#
# Test routines
#
  ftst(is_quantity(5), 'is_quantity');
  a := dq.quantity('5km/s');
  b := dq.quantity(5,'km/s');
  c := dq.quantity(5000,'m/s');
  d := dq.quantity('0.5rad');
  ttst(is_quantity(a), 'is_quantity');
  qtst(a,b,'quantity');
  qtst(a,c,'quantity');
  stst(a.unit,b.unit,'quantity');
  qtst(a,dq.unit('0.005Mm/s'),'unit');
#
  e := dm.epoch('utc','1997/12/23/15:00');
  ftst(is_measure(a),'is_measure');
  ttst(is_measure(e),'is_measure');
  qtst(e.m0,dq.unit('50805.625d'),'epoch');
#
  dq.setformat('prec',10);
  vtst(dq.getformat('prec'),10,'setformat');
  dq.setformat('long','+deg');
  stst(dq.getformat('long'),'+deg','setformat');
#
  vtst(dq.convert(a,'mm').value,5000000,'convert');
  vtst(dq.canonical(a).value,5000,'canonical');
  stst(dq.canon(a).unit,'m.s-1','canon');
  ttst(dq.define('xunit','5Jy'),'define');
  qtst(dq.unit('3xunit'),dq.unit('15Jy'),'define');
#
  vtst(length(split(dq.map('pre'))),65,'map');
  stst(dq.angle(d,8),'+028.38.52.40','angle');
  stst(dq.time(e.m0,8,form="ymd day"),'Tue-1997/12/23/15:00:00.00','time');
  ttst(dq.fits(),'fits');
#
  qtst(dq.neg(a),dq.unit('-5km/s'),'neg');
  qtst(dq.add(a,c),dq.unit('10km/s'),'add');
  qtst(dq.mul(a,c),dq.unit('25km2.s-2'),'mul');
  qtst(dq.sub(a,dq.mul('0.5',a)),dq.unit('2.5km/s'),'sub');
  qtst(dq.div(a,c),dq.unit('1'),'div');
  qtst(dq.norm(dq.unit('330deg')),dq.unit('-30deg'),'norm');
  qtst(dq.norm(dq.unit('330deg'),0),dq.unit('330deg'),'norm');
  qtst(dq.sin(d),dq.unit(sin(0.5)),'sin');
  qtst(dq.cos(d),dq.unit(cos(0.5)),'cos');
  qtst(dq.tan(d),dq.unit(tan(0.5)),'tan');
  qtst(dq.atan(dq.unit(0.5)),dq.unit(atan(0.5),'rad'),'atan');
  qtst(dq.asin(dq.unit(0.5)),dq.unit(asin(0.5),'rad'),'asin');
  qtst(dq.acos(dq.unit(0.5)),dq.unit(acos(0.5),'rad'),'acos');
  qtst(dq.atan2(dq.unit(0.5),dq.unit(0.6)),dq.unit(atan(0.5/0.6),'rad'),'atan2');
  qtst(dq.abs(dq.unit('-5km/s')),a,'abs');
  qtst(dq.ceil('-4.1m'),dq.unit('-4m'),'ceil');
  qtst(dq.floor('-4.1m'),dq.unit('-5m'),'floor');
  ttst(dq.compare(a,c),'compare');
  ftst(dq.compare(a,d),'compare');
  ttst(dq.check('Jy/Ms'),'check');
  ftst(dq.check('xxJy/xs'),'check');
  qtst(dq.pow(a,3),dq.unit('125km3.s-3'),'pow');
#
  fltst(dm.observatory('atca'),'observatory');
  ob := dm.observatory('atca');
  ttst(is_measure(ob),'observatory');
  ob := dm.measure(ob,'itrf');
  if (is_measure(ob)) {
##    qtst(ob.ev0,dq.unit('-4750915.837m'),'observatory',prec=0.5);
##    qtst(ob.ev1,dq.unit('2792906.182m'),'observatory',prec=0.5);
##    qtst(ob.ev2,dq.unit('-3200483.747m'),'observatory',prec=0.5);
  };
  stst(split(dm.obslist())[1],'ATCA','obslist');
  qtst(dq.constants('pi'),dq.unit(pi),'constants');
###  stst(dm.myupc('abC4d'),'ABC4D','myupc');
###  stst(dm.mydownc('abC4d'),'abc4d','mydownc');
#
  e0 := dm.epoch('utc','50805.625d');
  ttst(is_measure(e0),'epoch');
  qtst(dm.measure(e0,'iat').m0,dq.add(e0.m0,'31s'),'measure');
#
  ttst(dm.doframe(e0),'doframe');
  ttst(dm.showframe(),'showframe');
  ftst(dm.gui(),'gui');
  ttst(dq.errorgui('Correct'),'errorgui');
  ftst(dm.epochgui(),'epochgui');
  ftst(dm.positiongui(),'positiongui');
  ftst(dm.directiongui(),'directiongui');
  ftst(dm.frequencygui(),'frequencygui');
  ftst(dm.dopplergui(),'dopplergui');
  ftst(dm.radialvelocitygui(),'radialvelocitygui');
  ttst(is_measure(dm.direction('jup')),'direction');
#
  d0 := dm.direction('jup');
  d0 := dm.measure(d0,'j20');
  ttst(is_measure(d0),'direction');
  if (is_measure(d0)) {
    qtst(d0.m0,dq.unit('-0.6410274987rad'),'direction',prec=1e-8);
    qtst(d0.m1,dq.unit('-0.2697987142rad'),'direction',prec=1e-8);
  };
#
  p0 := dm.position('itrf','-4750915.837m','2792906.182m','-3200483.747m');
  ttst(is_measure(p0),'position');
  p0 := dm.measure(p0,'itrf');
  if (is_measure(p0)) {
##    qtst(p0.ev0,dq.unit('-4750915.837m'),'position',prec=1e-8);
##    qtst(p0.ev1,dq.unit('2792906.182m'),'position',prec=1e-8);
##    qtst(p0.ev2,dq.unit('-3200483.747m'),'position',prec=1e-8);
  };
#
  qtst(dq.toangle(d),d,'toangle');
  qtst(dq.totime(d),dq.unit(0.5/pi/2,'1.d'),'totime');
#
# End test function
#
  return result;
}
#
# Execute test function
#
##exit !tmeasures();
#
