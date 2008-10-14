# JCMT utilities.
#------------------------------------------------------------------------------
#   Copyright (C) 1999,2000,2001,2002,2003
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
#
#------------------------------------------------------------------------------

#We want to define a dish tool named 'd'; check to see if we can
if (is_defined('d')) {
   if (is_const(d)) {
      print 'Cannot start uni-jr properly because you have a const variable'
      print 'named \'d\' defined.  Remove it and try again.'
      exit
   }
   else {
      print 'You currently have a variable named \'d\', which must now be'
      print 'overwritten with the dish tool of the same name.'
   }
}

#Make our dish tool
dishflag := F
include 'dish.g'
include 'toolmanager.g';
for (i in symbol_names())
   if (is_tool(eval(i)))
      if (tm.tooltype(i)=='dish' && i != '__dish__' && i != '_objpublic') {
         const d := ref eval(i)
         dishflag := T
         break
      }
if (!dishflag) const d := dish()

include 'ms.g';
include 'statistics.g';

#Create JCMT tool

const jcmt := function() {
   private := [=];
   public  := [=];

   public.fixms := function(msname) {
# fixes needed to MS
# ANTENNA MOUNT: AZ-EL -> ALT-AZ
        maintab := table(msname);
	anttab:=table(maintab.getkeyword('ANTENNA'),readonly=F);
	anttab.putcell('MOUNT',1,'ALT-AZ');
	anttab.flush();
	anttab.done();
#
	a:=table(msname,readonly=F);
	sigma:=a.getcol('SIGMA');
	sigma +:= 1;
	a.putcol('SIGMA',sigma);
	a.flush();
	a.done();
#
	ptab:=table(maintab.getkeyword('POLARIZATION'),readonly=F);
	ct:=ptab.getcol('CORR_TYPE');
	ptab.putcol('CORR_TYPE',ct);
	ptab.flush();
	ptab.done();
#
	ftab:=table(maintab.getkeyword('FEED'),readonly=F);
	pr:=ftab.getcol('POL_RESPONSE');
	pr[1]:=1+0i;
	ftab.putcol('POL_RESPONSE',pr);
	ftab.flush();
	ftab.done();
# 
	swtab:=table(maintab.getkeyword('SPECTRAL_WINDOW'),readonly=F)
	mfr:=swtab.getcell('MEAS_FREQ_REF',1);
	swtab.putcell('MEAS_FREQ_REF',1,1);
	swtab.flush();
	swtab.done();

	maintab.done();

        note(msname,' has been fixed for filler errors');
 }

 return public;

}; #end of jcmt tool constructor;

const jcmt:=jcmt();

ok:=dl.note('DISH tool is --> d');
ok:=dl.note('JCMT   tool is --> jcmt');
