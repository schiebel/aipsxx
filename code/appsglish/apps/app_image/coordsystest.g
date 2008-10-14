# coordsysservertest.g: test coordsys.g
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
#   $Id: coordsystest.g,v 19.7 2005/05/13 07:00:06 nkilleen Exp $
#
include 'coordsys.g'
include 'measures.g';
include 'quanta.g';
include 'note.g'
include 'os.g'
include 'serverexists.g'

pragma include once


coordsysservertest := function (which=unset)
{
   if (!serverexists('dos', 'os', dos)) {
      return throw('The os server "dos" is either not running or not valid',
                    origin='coordsysservertest.g');
   }
   if (!serverexists('dm', 'measures', dm)) {
      return throw('The measures server "dm" is either not running or not valid',
                    origin='coordsysservertest.g');
   }
   if (!serverexists('dq', 'quanta', dq)) {
      return throw('The quanta server "dq" is either not running or not valid',
                    origin='coordsysservertest.g');
   }
#
   global dowait;
   olddowait := dowait;
   dowait := T;
   its := [=];
   its.tests := [=];

###
   const its.info := function(...) 
   { 
      note(...,origin='coordsysservertest()');
   }

###
   const its.stop := function(...) 
   { 
      note(paste(...) ,priority='SEVERE', origin='coordsysservertest()')
      global dowait
      dowait := olddowait
      return F
   }
###
   const its.cleanup := function(dir)
   {
       if (dos.fileexists(file=dir, follow=T)) {
          its.info('Cleaning up directory ', dir);
          ok := dos.remove(pathname=dir, recursive=T, follow=T);
          if (is_fail(ok)) fail;
      }
      return T;
   }


   const its.tests.test1 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 1 - coordsys, type, done, id, ncoordinates');
      its.info('       - coordinatetype, axiscoordinatetypes, summary');
      its.info('       - is_coordsys, coordsystools');
#
      its.info('');
      its.info ('Testing coordsys constructor');
      its.info('');
      cs := coordsys();
      if (is_fail(cs)) {
         return its.stop('coordsys constructor 1 failed');
      }
      if (!is_coordsys(cs)) fail 'is_coordsys 1 failed';
#
      if (cs.ncoordinates()!=0) fail 'ncoordinates 1 failed';
      if (cs.type()!='coordsys') fail 'type 1 failed';
#
      id := cs.id();
      if (is_fail(id)) fail 'id 1 failed'
      ok := is_record(id) && has_field(id, 'sequence') && has_field(id, 'pid') &&
             has_field(id, 'time') && has_field(id, 'host') &&
             has_field(id, 'agentid');
      if (!ok) fail ' id record has wrong fields';
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(direction=T);
      if (is_fail(cs)) fail 'coordsys constructor 2 failed';
      if (!is_coordsys(cs)) fail 'is_coordsys 2 failed';
      if (cs.ncoordinates()!=1) fail 'ncoordinates 2 failed';
      if (cs.coordinatetype(1)!='Direction') fail 'coordinatetype 1 failed'
      t1 := cs.axiscoordinatetypes(T);
      t2 := cs.axiscoordinatetypes(F);
      ok := t1[1]=='Direction' && t1[2]=='Direction' &&
            t2[1]=='Direction' && t2[2]=='Direction';
      if (!ok) fail 'axiscoordinatetypes 1 failed'
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(spectral=T);
      if (is_fail(cs)) fail 'coordsys constructor 3 failed';
      if (!is_coordsys(cs)) fail 'is_coordsys 3 failed';
      if (cs.ncoordinates()!=1) fail 'ncoordinates 3 failed';
      if (cs.coordinatetype(1)!='Spectral') fail 'coordinatetype 2 failed'
      t1 := cs.axiscoordinatetypes(T);
      t2 := cs.axiscoordinatetypes(F);
      ok := t1[1]=='Spectral' && t2[1]=='Spectral';
      if (!ok) fail 'axiscoordinatetypes 2 failed'
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(stokes="I Q U V");
      if (is_fail(cs)) fail 'coordsys constructor 4 failed';
      if (!is_coordsys(cs)) fail 'is_coordsys 4 failed';
      if (cs.ncoordinates()!=1) fail 'ncoordinates 4 failed';
      if (cs.coordinatetype(1)!='Stokes') fail 'coordinatetype 3 failed'
      t1 := cs.axiscoordinatetypes(T);
      t2 := cs.axiscoordinatetypes(F);
      ok := t1[1]=='Stokes' && t2[1]=='Stokes';
      if (!ok) fail 'axiscoordinatetypes 3 failed'
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(linear=3);
      if (is_fail(cs)) fail 'coordsys constructor 5 failed';
      if (!is_coordsys(cs)) fail 'is_coordsys 5 failed;'
      if (cs.ncoordinates()!=1) fail 'ncoordinates 5 failed';
      if (cs.coordinatetype(1)!='Linear') fail 'coordinatetype 4 failed'
      t1 := cs.axiscoordinatetypes(T);
      t2 := cs.axiscoordinatetypes(F);
      ok := t1[1]=='Linear' && t2[1]=='Linear';
      if (!ok) fail 'axiscoordinatetypes 4 failed'
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(tabular=T);
      if (is_fail(cs)) fail 'coordsys constructor 6 failed';
      if (!is_coordsys(cs)) fail 'is_coordsys 6 failed';
      if (cs.ncoordinates()!=1) fail 'ncoordinates 6 failed';
      if (cs.coordinatetype(1)!='Tabular') fail 'coordinatetype 6 failed'
      t1 := cs.axiscoordinatetypes(T);
      t2 := cs.axiscoordinatetypes(F);
      ok := t1[1]=='Tabular' && t2[1]=='Tabular';
      if (!ok) fail 'axiscoordinatetypes 5 failed'
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(direction=T, spectral=T, stokes="I Q U V", linear=1, tabular=T);
      if (is_fail(cs)) fail 'coordsys constructor 7 failed';
      if (!is_coordsys(cs)) fail 'is_coordsys 7 failed';
      if (cs.ncoordinates()!=5) fail 'ncoordinates 7 failed';
      if (cs.coordinatetype(1)!='Direction' &&
          cs.coordinatetype(2)!='Stokes' &&
          cs.coordinatetype(3)!='Spectral' &&
          cs.coordinatetype(4)!='Linear' &&
          cs.coordinatetype(5)!='Tabular') fail 'coordinatetype 5 failed'
      t := cs.coordinatetype();
      if (is_fail(t)) fail;
      if (t[1]!='Direction' && t[2]!='Stokes' && 
          t[3]!='Spectral' && t[4]!='Linear' &&
          t[5]!='Tabular') fail 'coordinatetype 6 failed'
#
      t1 := cs.axiscoordinatetypes(T);
      t2 := cs.axiscoordinatetypes(F);
      ok := t1[1]=='Direction' && t1[2]=='Direction' &&
            t1[3]=='Stokes' && t1[4]=='Spectral' &&
            t1[5]=='Linear' && t1[6]=='Tabular' &&
            t2[1]=='Direction' && t2[2]=='Direction' &&
            t2[3]=='Stokes' && t2[4]=='Spectral' &&
            t2[5]=='Linear' && t2[6]=='Tabular';
      if (!ok) fail 'axiscoordinatetypes 7 failed'
#
      if (is_fail(cs.summary())) fail;
      if (is_fail(cs.summary(doppler='optical'))) fail;
      if (is_fail(cs.summary(doppler='radio'))) fail;
#
      if (is_fail(cs.done())) fail;
#
      global cs1 := coordsys();
      global cs2 := coordsys();
      l := coordsystools();
      ok := length(l)==2 &&  l[1]=='cs1' && l[2]=='cs2';
      if (!ok) {
         fail 'coordsystools failed'
      }
      if (is_fail(cs1.done())) fail;
      if (is_fail(cs2.done())) fail;
      
###
     return T;
   }

   const its.tests.test2 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 2 - referencecode, setreferencecode')
      its.info('         restfrequency, setrestfrequency');
      its.info('         projection, setprojection');
#
# Frequency. Does not test reference value conversion
# is correct
#
      its.info('');
      its.info ('Testing referencecode');
      its.info('');
      cs := coordsys(direction=T, spectral=T);
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';
#
      d := dm.frequency('LSRK');
      if (is_fail(d)) fail;
      list := dm.listcodes(d);
      if (is_fail(list)) fail;
#     
      for (i in list.normal) {
         if (i!='REST') {
            ok := cs.setreferencecode(type='spectral', value=i, adjust=T);
            if (is_fail(ok)) fail;
            if (cs.referencecode(type='spectral')!=i) {
               msg := spaste ('failed to recover spectral reference code ', i);
               fail msg;
            }
         }
      }
#
# Direction. Does not test reference value conversion
# is correct
#
      d := dm.direction('J2000');
      if (is_fail(d)) fail;
      list := dm.listcodes(d);
      if (is_fail(list)) fail;
#     
      for (i in list.normal) {
         bad := i~m/AZEL/;
         if (!bad) {
            ok := cs.setreferencecode(type='direction', value=i, adjust=F);
            if (is_fail(ok)) fail;
            if (cs.referencecode(type='direction')!=i) {
               msg := spaste ('failed to recover direction reference code ', i);
               fail msg;
            }
         }
      }
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(direction=T, spectral=T, linear=1);
      if (is_fail(cs)) fail 'coordsys constructor 2 failed';
      ok := cs.setreferencecode(type='direction', value='B1950');
      if (is_fail(ok)) fail;
      ok := cs.setreferencecode(type='spectral', value='BARY');
      if (is_fail(ok)) fail;
#
      c := cs.referencecode();
      ok := length(c)==3 && c[1]=='B1950' && c[2]=='BARY' && c[3]=='';
      if (!ok) fail 'referencecode 3 failed'
#
      ok := cs.setreferencecode(value='doggies');
      if (!is_fail(ok)) fail 'setreferencecode unexpectedly did not fail'
#
# projection
#
      its.info('');
      its.info ('Testing projection');
      its.info('');
      ok := cs.setprojection('SIN', [1.0,2.0]);
      if (is_fail(ok)) fail;
      p := cs.projection();
      if (is_fail(p)) fail;
      ok := p.type=='SIN' && length(p.parameters==2) &&
            p.parameters[1]==1.0 && p.parameters[2]==2.0;
      if (!ok) fail 'setprojection/projection 1 reflection failed'
#
      p := cs.projection('all');
      if (length(p)!=25) fail 'projection 1 failed'
      for (i in p) {
        n := cs.projection(i);
        if (is_fail(n)) fail;
      }
#
      ok := cs.setprojection('fish');
      if (!is_fail(ok)) fail 'setprojection 1 unexpectedly did not fail';
#
# restfrequency
#
      its.info('');
      its.info ('Testing restfrequency');
      its.info('');
      rf1 := dq.quantity('1.2GHz');
      if (is_fail(rf1)) fail;
      ok := cs.setrestfrequency(rf1);
      if (is_fail(ok)) fail;
      rf2 := cs.restfrequency();
      if (is_fail(rf2)) fail;
      rf2 := dq.convert(rf2,rf1.unit);
      ok := abs(dq.getvalue(rf1)-dq.getvalue(rf2))<1.0e-6 && 
                dq.getunit(rf1)==dq.getunit(rf2);
      if (!ok) fail 'setrestfrequency/restfrequency 1 reflection failed';
#
      unit := dq.getunit(cs.restfrequency());
      if (is_fail(unit)) fail;
      rf1 := 2.0;
      ok := cs.setrestfrequency(rf1);
      if (is_fail(ok)) fail;
      rf2 := cs.restfrequency();
      if (is_fail(rf2)) fail;
      rf1 := dq.unit(rf1, unit);
      if (is_fail(rf1)) fail;
      ok := abs(dq.getvalue(rf1)-dq.getvalue(rf2))<1.0e-6 && 
                dq.getunit(rf1)==dq.getunit(rf2);
      if (!ok) fail 'setrestfrequency/restfrequency 2 reflection failed';
#
      rf1 := dq.quantity([1e9, 2e9], 'Hz');
      ok := cs.setrestfrequency(value=rf1, which=2, append=F);    # Select second freq
      rf2 := dq.convert(cs.restfrequency(),dq.getunit(rf1));
      v1 := dq.getvalue(rf1);
      v2 := dq.getvalue(rf2);
      ok := abs(v1[1]-v2[2]<1e-6) &&
            abs(v1[2]-v2[1]<1e-6) &&
            dq.getunit(rf1)==dq.getunit(rf2);
      if (!ok) fail 'setrestfrequency/restfrequency 3 reflection failed';
#
      rf1 := dq.quantity('1kg');
      ok := cs.setrestfrequency(rf1);
      if (!is_fail(ok)) fail 'setrestfrequency 3 unexpectedly did not fail'
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(direction=T, spectral=F);
      rf := cs.restfrequency();
      if (!is_fail(rf)) fail 'restfrequency unexpectedly did not fail'     
#
      rf1 := dq.quantity('1GHz');
      ok := cs.setrestfrequency(rf1);
      if (!is_fail(ok)) fail 'setrestfrequency 4 unexpectedly did not fail'
#
      if (is_fail(cs.done())) fail;
#

###
     return T;
   }


###
   const its.tests.test3 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 3 - torecord, fromrecord, copy');
#
      cs := coordsys(direction=T, spectral=T, stokes="I Q U V",
                     linear=3);
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';
#
      r := cs.torecord();
      if (is_fail(r)) fail 'torecord 1 failed';
      ok := is_record(r) && has_field(r,'direction0') &&
            has_field(r,'stokes1') && has_field(r,'spectral2') &&
            has_field(r,'linear3');
      if (!ok) fail 'torecord did not produce valid record';
#
      cs2 := coordsys(direction=F, spectral=F, stokes="", linear=0);
      if (is_fail(cs2)) fail 'coordsys constructor 2 failed';
      ok := cs2.fromrecord(r);
      if (is_fail(ok)) fail 'fromrecord 1 failed';  
      if (!is_coordsys(cs2)) {
         fail 'fromrecord 1 did not produce a coordsys tool'
      }
#
      if (is_fail(cs.done())) fail;
      if (is_fail(cs2.done())) fail;
#
      cs := coordsys(direction=T);
      if (is_fail(cs)) fail 'coordsys constructor 3 failed';
      cs2 := cs.copy();
      if (is_fail(cs2)) fail;
      ok := cs.done();
      if (ok==F && cs2==F) fail 'copy was a reference !';
      if (is_fail(cs2.done())) fail;     

###
     return T;
   }


###
   const its.tests.test4 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 4 - setepoch, epoch, setobserver, observer');
      its.info('         settelescope, telescope, setparentname, parentname');
#
      cs := coordsys(direction=T);
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';
#
# Epoch
#
      its.info('');
      its.info ('Testing epoch');
      its.info('');
      epoch1 := dm.epoch('UTC', 'today');
      ok := cs.setepoch(epoch1);
      if (is_fail(ok)) fail;
      epoch2 := cs.epoch();
#
      ok := abs(dm.getvalue(epoch1)[1].value-dm.getvalue(epoch2)[1].value)<1.0e-6 &&
            dm.getvalue(epoch1)[1].unit == dm.getvalue(epoch2)[1].unit &&
            dm.gettype(epoch1) == dm.gettype(epoch2) && 
            dm.getref(epoch1) == dm.getref(epoch2);
      if (!ok) {
         fail 'setepoch/epoch reflection failed'
      }
#
# Observer
#
      its.info('');
      its.info ('Testing observer');
      its.info('');
      obs1 := 'Biggles';
      ok := cs.setobserver(obs1);
      if (is_fail(ok)) fail;
      obs2 := cs.observer();
#
      ok := obs1==obs2;
      if (!ok) {
         fail 'setobserver/observer reflection failed'
      }
#
# Telescope
#
      its.info('');
      its.info ('Testing telescope');
      its.info('');
      tel1 := 'VLA';
      ok := cs.settelescope(tel1);
      if (is_fail(ok)) fail;
      tel2 := cs.telescope();
#
      ok := tel1==tel2;
      if (!ok) {
         fail 'settelescope/telescope reflection failed'
      }
      pos := cs.telescope(T);
      if (!is_measure(pos)) fail 'telescope 1 failed';
#
# Parent name
#
      its.info('');
      its.info ('Testing parentname');
      its.info('');
      pn1 := 'Biggles.image';
      ok := cs.setparentname(pn1);
      if (is_fail(ok)) fail;
      pn2 := cs.parentname();
#
      ok := pn1==pn2;
      if (!ok) {
         fail 'setparentname/parentname reflection failed'
      }
#
      if (is_fail(cs.done())) fail;
#

###
     return T;
   }

###
   const its.tests.test5 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 5 - setnames, names, setunits, units');
      its.info('         setreferencepixel, referencepixel');
      its.info('         setreferencevalue, referencevalue');
      its.info('         setincrement, increment');
      its.info('         setlineartransform, lineartransform');
      its.info('         setstokes, stokes');
#
      cs := coordsys(direction=T, spectral=T);
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';
#
# Names
#
      its.info('');
      its.info ('Testing names');
      its.info('');
      val1 := "a b c";
      ok := cs.setnames(value=val1);
      if (is_fail(ok)) fail;
      val2 := cs.names();
#
      ok := val1==val2;
      if (!ok) fail 'setnames/names reflection 1 failed'
#
      val2 := cs.names('spec')
      ok := val2[1]==val1[3];
      if (!ok) fail 'names 1 failed'
#
      val1 := 'fish';
      ok := cs.setnames(type='spec', value=val1);
      if (is_fail(ok)) fail;
      val2 := cs.names('spec');
      ok := val2[1]==val1[1];
      if (!ok) fail 'setnames/names reflection 2 failed'
      if (is_fail(cs.done())) fail;
#
# Units
#
      its.info('');
      its.info ('Testing units');
      its.info('');
      cs := coordsys(direction=T, spectral=T);
      if (is_fail(cs)) fail 'coordsys constructor 2 failed';
      val1 := "deg rad GHz";
      ok := cs.setunits(value=val1);
      if (is_fail(ok)) fail;
      val2 := cs.units();
#
      ok := val1==val2;
      if (!ok) fail 'setunits/units 1 reflection failed'
#
      ok := cs.setunits(value="Hz Hz Hz");
      if (!is_fail(ok)) fail 'setunits 2 unexpectedly did not fail'
      ok := cs.setunits(value="m");
      if (!is_fail(ok)) fail 'setunits 3 unexpectedly did not fail'
#
      val1 := "deg rad GHz";
      ok := cs.setunits(value=val1);
      if (is_fail(ok)) fail;
      val2 := cs.units('spec');
      ok := val2[1]==val1[3];
      if (!ok) fail 'units 1 failed';
#
      val1 := 'kHz';
      ok := cs.setunits(type='spec', value=val1);
      if (is_fail(ok)) fail;
      val2 := cs.units('spec');
      ok := val2[1]==val1[1];
      if (!ok) fail 'setunits/units reflection 2 failed'
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(direction=T, linear=2);
      if (is_fail(cs)) fail 'coordsys constructor 2b failed';
      val1 := "Hz kHz";
      ok := cs.setunits(type='linear', value=val1, overwrite=T)
      if (is_fail(ok)) fail;
      val2 := cs.units()
      ok := val1[1]==val2[3] && val1[2]==val2[4];
      if (!ok) fail 'setunits overwrite test failed';
      if (is_fail(cs.done())) fail;   
#
# Reference pixel
#
      its.info('');
      its.info ('Testing referencepixel');
      its.info('');
      cs := coordsys(direction=T, spectral=T);
      if (is_fail(cs)) fail 'coordsys constructor 3 failed';
      val1 := [1,2,3];
      ok := cs.setreferencepixel(value=val1);
      if (is_fail(ok)) fail;
      val2 := cs.referencepixel();
#
      ok := abs(val1-val2)<1.0e-6;
      if (!ok) {
         fail 'setreferencepixel/referencepixel reflection failed'
      }
#
      val2 := cs.referencepixel('dir')
      if (is_fail(val2)) fail;
      ok := abs(val2[1]-val1[1])<1.0e-6 && abs(val2[2]-val1[2])<1.0e-6;
      if (!ok) fail 'referencepixel 1 failed'
      val2 := cs.referencepixel('spec')
      if (is_fail(val2)) fail;
      ok := abs(val2[1]-val1[3])<1.0e-6;
      if (!ok) fail 'referencepixel 2 failed'
#
      val1 := [0,0]
      ok := cs.setreferencepixel (type='dir', value=val1);
      val2 := cs.referencepixel('dir');
      ok := abs(val2[1]-val1[1])<1e-6 && abs(val2[2]-val1[2])<1e-6;
      if (!ok) fail 'setreferencepixel 3 failed'
#
      ok := cs.setreferencepixel (type='lin', value=[0,0]);
      if (!is_fail(ok)) fail 'setreferencepixel 1 unexpectedly did not fail';
      ok := cs.referencepixel('lin');
      if (!is_fail(ok)) fail 'setreferencepixel 2 unexpectedly did not fail'
      if (is_fail(cs.done())) fail;
#
# linear transform
#
      its.info('');
      its.info ('Testing lineartransform');
      its.info('');
      cs := coordsys(direction=T, spectral=T, stokes='IQ', tabular=T, linear=3)
      if (is_fail(cs)) fail 'coordsys constructor 3b failed';
#
      val1 := array(0,2,2);
      val1[1,1] := 2.0;
      val1[2,2] := 3.0;
      type := 'direction';
      ok := cs.setlineartransform(value=val1, type=type);
      if (is_fail(ok)) fail;
      val2 := cs.lineartransform(type=type);
#
      ok := all(abs(val1-val2)<1.0e-6);
      if (!ok) {
         fail 'direction setlineartransform/lineartransform reflection failed'
      }
##
      val1 := array(2,1,1);
      type := 'spectral';
      ok := cs.setlineartransform(value=val1, type=type);
      if (is_fail(ok)) fail;
      val2 := cs.lineartransform(type=type);
#
      ok := all(abs(val1-val2)<1.0e-6);
      if (!ok) {
         fail 'spectral setlineartransform/lineartransform reflection failed'
      }
##
      val1 := array(2,1,1);
      type := 'stokes';
      ok := cs.setlineartransform(value=val1, type=type);
      if (is_fail(ok)) fail;
      val2 := cs.lineartransform(type=type);       # Does not set ; returns T
#
      ok := all(abs(val1-val2)<1.0e-6);
      if (ok) {
         fail 'stokes setlineartransform/lineartransform reflection failed'
      }
##
      val1 := array(4,1,1);
      type := 'tabular';
      ok := cs.setlineartransform(value=val1, type=type);
      if (is_fail(ok)) fail;
      val2 := cs.lineartransform(type=type);
#
      ok := all(abs(val1-val2)<1.0e-6);
      if (!ok) {
         fail 'tabular setlineartransform/lineartransform reflection failed'
      }
##
      val1 := array(0,3,3);
      val1[1,1] := 2.0;
      val1[2,2] := 3.0;      
      val1[3,3] := 4.0;
      type := 'linear';
      ok := cs.setlineartransform(value=val1, type=type);
      if (is_fail(ok)) fail;
      val2 := cs.lineartransform(type=type);
#
      ok := all(abs(val1-val2)<1.0e-6);
      if (!ok) {
         fail 'direction setlineartransform/lineartransform reflection failed'
      }
      if (is_fail(cs.done())) fail;
#
# Reference value
#
      its.info('');
      its.info ('Testing referencevalue');
      its.info('');
      cs := coordsys(direction=T);
      if (is_fail(cs)) fail 'coordsys constructor 4 failed';
      ok := cs.setunits(value="rad rad");
      if (is_fail(ok)) fail;
      val1 := cs.referencevalue(format='q');
      val1[1] := dq.quantity('0.01rad');
      val1[2] := dq.quantity('-0.01rad');
      ok := cs.setreferencevalue(value=val1);
      if (is_fail(ok)) fail;
      val2 := cs.referencevalue(format='q');
      if (is_fail(val2)) fail;
#
      ok := abs(val1[1].value-val2[1].value)<1e-6 &&
            abs(val1[2].value-val2[2].value)<1e-6 &&
            val1[1].unit==val2[1].unit &&
            val1[2].unit==val2[2].unit;
      if (!ok) {
         fail 'setreferencevalue/referencevalue 1 reflection failed'
      }
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(direction=T);
      if (is_fail(cs)) fail 'coordsys constructor 5 failed';
      units := cs.units();
      if (is_fail(units)) fail;
      val1 := [1.0,2.0];
      ok := cs.setreferencevalue(value=val1);
      if (is_fail(ok)) fail;
      val2 := cs.referencevalue(format='q');
      if (is_fail(val2)) fail;
      ok := abs(val1[1]-val2[1].value)<1e-6 &&
            abs(val1[2]-val2[2].value)<1e-6 &&
            units[1]==val2[1].unit &&
            units[2]==val2[2].unit;
      if (!ok) fail 'setreferencevalue/referencevalue 2 reflection failed'
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(spectral=T);
      if (is_fail(cs)) fail 'coordsys constructor 6 failed';
      ok := cs.setreferencevalue (value='i like doggies');
      if (!is_fail(ok)) fail 'setreferencevalue unexpectedly did not fail'
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(direction=T, spectral=T);
      if (is_fail(cs)) fail 'coordsys constructor 7 failed';
      val1 := cs.referencevalue(format='q');
      if (is_fail(val1)) fail;
      val2 := cs.referencevalue(type='spec', format='q');
      if (is_fail(val2)) fail;
      ok := abs(val1[3].value-val2.value)<1e-6 &&
            val1[3].unit==val2.unit;
      if (!ok) fail 'referencevalue 1 failed'
#
      val1 := [-10];
      ok := cs.setreferencevalue(type='spec', value=val1);
      if (is_fail(ok)) fail;
      val2 := cs.referencevalue(type='spec', format='n');
      if (is_fail(val2)) fail;
      ok := abs(val1[1]-val2[1])<1e-6;
      if (!ok) fail 'setreferencevalue 1 failed'
#
      val1 := cs.referencevalue(format='n')
      if (is_fail(val1)) fail;
      val2 := cs.referencevalue(type='spec', format='n');
      if (is_fail(val2)) fail;
      ok := abs(val1[3]-val2[1])<1e-6;
      if (!ok) fail 'referencevalue 2 failed'
      if (is_fail(cs.done())) fail;
#
# increment
#
      its.info('');
      its.info ('Testing increment');
      its.info('');
      cs := coordsys(direction=T);
      if (is_fail(cs)) fail 'coordsys constructor 7 failed';
      ok := cs.setunits(value="rad rad");
      if (is_fail(ok)) fail;
      val1 := cs.increment(format='q');
      val1[1] := dq.quantity('0.01rad');
      val1[2] := dq.quantity('-0.01rad');
      ok := cs.setincrement(value=val1);
      if (is_fail(ok)) fail;
      val2 := cs.increment(format='q');
      if (is_fail(val2)) fail;
#
      ok := abs(val1[1].value-val2[1].value)<1e-6 &&
            abs(val1[2].value-val2[2].value)<1e-6 &&
            val1[1].unit==val2[1].unit &&
            val1[2].unit==val2[2].unit;
      if (!ok) {
         fail 'setincrement/increment 1 reflection failed'
      }
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(direction=T);
      if (is_fail(cs)) fail 'coordsys constructor 8 failed';
      units := cs.units();
      if (is_fail(units)) fail;
      val1 := [1.0,2.0];
      ok := cs.setincrement(value=val1);
      if (is_fail(ok)) fail;
      val2 := cs.increment(format='q');
      if (is_fail(val2)) fail;
      ok := abs(val1[1]-val2[1].value)<1e-6 &&
            abs(val1[2]-val2[2].value)<1e-6 &&
            units[1]==val2[1].unit &&
            units[2]==val2[2].unit;
      if (!ok) {
         fail 'setincrement/increment 2 reflection failed'
      }
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(spectral=T);
      if (is_fail(cs)) fail 'coordsys constructor 9 failed';
      ok := cs.setincrement(value='i like doggies');
      if (!is_fail(ok)) fail 'setincrement 1 unexpectedly did not fail'
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(direction=T, spectral=T);
      if (is_fail(cs)) fail 'coordsys constructor 10 failed';
      val1 := [1.0, 2.0, 3.0];
      ok := cs.setincrement(value=val1);
      if (is_fail(ok)) fail;
      val2 := cs.increment(format='n', type='dir');
      ok := abs(val2[1]-val1[1])<1e-6 && abs(val2[2]-val1[2])<1e-6;
      if (!ok) fail 'setincrement/increment 3 reflection failed'
      val2 := cs.increment(type='spe',format='n');
      ok := abs(val2[1]-val1[3])<1e-6;
      if (!ok) fail 'setincrement/increment 4 reflection failed'
      val2 := cs.increment(type='lin', format='q');
      if (!is_fail(val2)) fail 'increment 2 unexpectedly did not fail'
#
      val1 := [-10];
      ok := cs.setincrement(type='spec', value=val1);
      if (is_fail(ok)) fail;
      val2 := cs.increment(type='spec', format='n');
      if (is_fail(val2)) fail;
      ok := abs(val1[1]-val2[1])<1e-6;
      if (!ok) fail 'setincrement/increment 5 reflection failed'
      if (is_fail(cs.done())) fail; 
#
# Stokes
#
      cs := coordsys(stokes="I RL");
      if (is_fail(cs)) fail;
      stokes := cs.stokes();
      if (is_fail(stokes)) fail;
      if (stokes[1]!='I' && stokes[2]!='RL') {
         fail 'stokes 1  recovered wrong values'
      }
      ok := cs.setstokes("XX V");
      if (is_fail(ok)) fail;
      stokes := cs.stokes();
      if (is_fail(stokes)) fail;
      if (stokes[1]!='XX' && stokes[2]!='V') {
         fail 'stokes 2 recovered wrong values'
      }
      if (is_fail(cs.done())) fail; 
#
      cs := coordsys(direction=T)
      if (is_fail(cs)) fail;
      stokes := cs.stokes();
      if (!is_fail(stokes)) fail 'stokes 2 unexpectedly did not fail';
      ok := cs.setstokes("I V")
      if (!is_fail(ok)) fail 'setstokes 2 unexpectedly did not fail';
#
      if (is_fail(cs.done())) fail;       
#

###
     return T;
   }


###
   const its.tests.test6 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 6 - findcoordinate, findaxis');
#
      cs := coordsys()
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';

# findcoordinate
      
      local pa, wa;
      ok := cs.findcoordinate(pa, wa, 'fish', 1);
      if (!is_fail(ok)) {
         return its.stop('findcoordinate 1 unexpectedly did not fail');
      }
      ok := cs.findcoordinate(pa, wa, 'dir', 20);
      if (ok) {
         return its.stop('findcoordinate 2 unexpectedly did not fail');
      }
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(direction=T, stokes="I V", spectral=T, linear=2);
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';

      ok := cs.findcoordinate(pa,wa,'dir',1);
      if (is_fail(ok) || !ok) {
         return its.stop('findcoordinate 3 failed');
      }
      if (!all(pa==[1,2])) {
         return its.stop('find 3 pixel axes are wrong');
      }
      if (!all(wa==[1,2])) {
         return its.stop('find 3 world axes are wrong');
      }
# 
      ok := cs.findcoordinate(pa,wa,'stokes',1);
      if (is_fail(ok) || !ok) {
         return its.stop('findcoordinate 4 failed');
      }
      if (!all(pa==[3])) {
         return its.stop('findcoordinate 4 pixel axes are wrong');
      }
      if (!all(wa==[3])) {
         return its.stop('findcoordinate 4 world axes are wrong');
      }
#
      ok := cs.findcoordinate(pa,wa,'spectral',1);
      if (is_fail(ok) || !ok) {
         return its.stop('findcoordinate 5 failed');
      }
      if (!all(pa==[4])) {  
         return its.stop('findcoordinate 5 pixel axes are wrong');
      }
      if (!all(wa==[4])) {  
         return its.stop('findcoordinate 5 world axes are wrong');
      }
#
#
      ok := cs.findcoordinate(pa,wa,'linear',1);
      if (is_fail(ok) || !ok) {
         return its.stop('findcoordinate 6 failed');
      }
      if (!all(pa==[5,6])) {  
         return its.stop('findcoordinate 6 pixel axes are wrong');
      }
      if (!all(wa==[5,6])) {  
         return its.stop('findcoordinate 6 world axes are wrong');
      }
#
      if (is_fail(cs.done())) fail;

# findaxis

      cs := coordsys(direction=T, linear=2);
      local coord, axisincoord;
#
      ok := cs.findaxis(coord, axisincoord, T, 1);
      if (is_fail(ok)) fail;
      if (coord!=1 || axisincoord!=1) {
         return its.stop('findaxis 1 values are wrong');
      }
#
      ok := cs.findaxis(coord, axisincoord, T, 2);
      if (is_fail(ok)) fail;
      if (coord!=1 || axisincoord!=2) {
         return its.stop('findaxis 2 values are wrong');
      }
#
      ok := cs.findaxis(coord, axisincoord, T, 3);
      if (is_fail(ok)) fail;
      if (coord!=2 || axisincoord!=1) {
         return its.stop('findaxis 3 values are wrong');
      }
#
      ok := cs.findaxis(coord, axisincoord, T, 4);
      if (is_fail(ok)) fail;
      if (coord!=2 || axisincoord!=2) {
         return its.stop('findaxis 4 values are wrong');
      }
#
      ok := cs.findaxis(coord, axisincoord, T, 4);
      if (!ok) {
         return its.stop('findaxis 5 unexpectedly found the axis');
      }
#
      if (is_fail(cs.done())) fail;

###
     return T;
   }



###
   const its.tests.test7 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 7 - toworld, toworldmany, topixel, topixelmany');
#
      cs := coordsys(direction=T, spectral=T, stokes="I V", linear=2);
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';
#
      its.info('');
      its.info('Testing toworld');
      its.info('');
#
      rp := cs.referencepixel();
      if (is_fail(rp)) fail;
      rv := cs.referencevalue(format='n');
      if (is_fail(rv)) fail;
      d := abs(cs.toworld(value=rp, format='n') - rv);
      if (!all(d<1e-6)) fail 'toworld 1 gives wrong values';
#
      d := cs.toworld(value=rp, format='q')
      u := cs.units();
      if (is_fail(u)) fail;
#
      if (length(d)!=length(rv)) fail 'toworld 2 gives wrong number of quantities';
      for (i in 1:length(d)) {
         if (abs(d[i].value-rv[i])>1e-6) fail 'toworld 2 gives wrong values';
         if (d[i].unit != u[i]) fail 'toworld 2 gives wrong units';
      }
# 
      q := cs.toworld(value=rp, format='q');
      if (is_fail(q)) fail;
      m := cs.toworld(value=rp, format='m');
      if (is_fail(m)) fail;
      ok := has_field(m, 'direction') && has_field(m, 'spectral') &&
            has_field(m.spectral, 'frequency') &&
            has_field(m.spectral, 'opticalvelocity') &&
            has_field(m.spectral, 'radiovelocity') &&
            has_field(m.spectral, 'betavelocity') &&
            has_field(m, 'stokes') && has_field(m, 'linear');
      if (!ok) fail 'toworld 3 gives wrong fields';
      d := m.direction;
      f := m.spectral.frequency;
      l := m.linear;
      s := m.stokes;
#
      v := dm.getvalue(d);
      q[1] := dq.convert(q[1], v[1].unit);
      q[2] := dq.convert(q[2], v[2].unit);
      ok := abs(v[1].value-q[1].value)<1e-6 &&
            abs(v[2].value-q[2].value)<1e-6 &&      
            v[1].unit==q[1].unit &&
            v[2].unit==q[2].unit;
      if (!ok) fail 'toworld 3 gives wrong direction values';
#
      v := dm.getvalue(f);
      q[4] := dq.convert(q[4], v[1].unit);
      ok := abs(v[1].value-q[4].value)<1e-6 && v[1].unit==q[4].unit;
      if (!ok) fail 'toworld 3 gives wrong frequency values';
#
      q[5] := dq.convert(q[5], l[1].unit);
      q[6] := dq.convert(q[6], l[2].unit);
      ok := abs(l[1].value-q[5].value)<1e-6 &&
            abs(l[2].value-q[6].value)<1e-6 &&      
            l[1].unit==q[5].unit &&
            l[2].unit==q[6].unit;
      if (!ok) fail 'toworld 3 gives wrong linear values';
#
# toworldmany - any is as good as any other
#
      p := cs.referencepixel();
      w := cs.referencevalue();
      rIn := array(0, length(p), 10);
      for (i in 1:10) {
         rIn[,i] := p;
      }
      rOut := cs.toworldmany(rIn);
      if (is_fail(rOut)) fail;
      for (i in 1:10) {f
         w2 := rOut[,i];
         d := w2 - w;
         if (!all(d<1e-6)) fail 'toworldmany 1 gives wrong values';
      }
#
# topixel
#
      its.info('');
      its.info('Testing topixel');
      its.info('');
#
      tol := 1.0e-6;
      rp := cs.referencepixel();
      if (is_fail(rp)) fail;
      rv := cs.referencevalue(format='n');
      if (is_fail(rv)) fail;
      p := cs.topixel(value=rv);
      if (is_fail(p)) fail;
      d := abs(p-rp);
      if (!all(d<tol)) fail 'topixel 1 gives wrong values';
#
      for (format in "n q m s nqms") {
        p := rp + 1.0;
        w := cs.toworld(value=p, format=format);
        if (is_fail(w)) fail;
#
        p2 := cs.topixel(value=w);
        if (is_fail(p2)) fail;
        d := abs(p - p2);
        if (!all(d<tol)) {
           s := spaste('toworld/topixel reflection failed for format "', format, '"');
           fail s;
        }
      }
#
# topixelmany - any is as good as any other
#
      n := 10;
      p := cs.referencepixel();
      w := cs.toworld(p, 'n');
      rIn := array(0, length(w), n);
      for (i in 1:n) {
        rIn[,i] := w;
      }
      r2 := cs.topixelmany(rIn);
      if (is_fail(r2)) fail;
      for (i in 1:n) {
         d := abs(p - r2[,i]);
         if (!all(d<1e-6)) fail 'topixelmany 1 gives wrong values';
      }
#
      if (is_fail(cs.done())) fail;
###
     return T;
   }

###
   const its.tests.test8 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 8 - naxes, axesmap');
#
      its.info('');
      its.info('Testing naxes');
      its.info('');
      cs := coordsys();
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';
      n := cs.naxes();
      if (is_fail(n)) fail 'naxes 1 failed';
      if (cs.naxes()!=0) fail 'naxes 1 gave wrong result'
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(direction=T, spectral=T, stokes="I V", linear=2);
      if (is_fail(cs)) fail 'coordsys constructor 2 failed';
      n := cs.naxes();
      if (is_fail(n)) fail 'naxes 2 failed';
      if (cs.naxes()!=6) fail 'naxes 2 gave wrong result'
#
      its.info('');
      its.info('Testing axesmap');
      its.info('');
#
# Since I have no way to reorder the world and pixel axes
# from Glish, all I can do is check the maps are the
# same presently
#
      toworld := cs.axesmap(toworld=T)
      if (is_fail(toworld)) fail;
      topixel := cs.axesmap(toworld=F)
      if (is_fail(topixel)) fail;
#
      idx := 1:length(cs.referencepixel());
      if (!all(toworld==idx)) fail 'toworld map is wrong';
      if (!all(topixel==idx)) fail 'topixel map is wrong';
#
      if (is_fail(cs.done())) fail;

###
     return T;
   }


###
   const its.tests.test9 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 9 - reorder');
#
      its.info('');
      its.info('Testing reorder');
      its.info('');
      cs := coordsys(direction=T, spectral=T, stokes='I V', linear=1);
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';
      order := [4,3,2,1];
      ok := cs.reorder(order)
      if (is_fail(ok)) fail 'reorder 1 failed';
      ok := cs.coordinatetype(1)=='Linear' &&
            cs.coordinatetype(2)=='Spectral' &&
            cs.coordinatetype(3)=='Stokes' &&
            cs.coordinatetype(4)=='Direction';
      if (!ok) fail 'reorder reordered incorrectly';
#
      ok := cs.reorder([1,2]);
      if (!is_fail(ok)) fail 'reorder 2 unexpectedly did not fail';
#      
      ok := cs.reorder([1,2,3,10]);
      if (!is_fail(ok)) fail 'reorder 3 unexpectedly did not fail';
#
      if (is_fail(cs.done())) fail;

###
     return T;
   }


###
   const its.tests.test10 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 10 - frequencytovelocity, velocitytofrequency');
#
      cs := coordsys(spectral=T);
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';
#
      its.info('');
      its.info('Testing frequencytovelocity');
      its.info('');

# Set rest freq to reference freq

      rv := cs.referencevalue(format='n');
      if (is_fail(rv)) fail;
      restFreq := rv[1];
      ok := cs.setrestfrequency(restFreq);
      if (is_fail(ok)) fail;

# Find radio velocity increment

      df := cs.increment(format='n');
      c := dq.constants('c').value;              #m/s
      drv := -c * df / rv[1] / 1000.0;           #km/s
#
      freq := rv[1];
      freqUnit := cs.units();    
      vel := cs.frequencytovelocity(value=freq, frequnit=freqUnit,
                                    doppler='radio', velunit='km/s')
      if (abs(vel[1]) > 1e-6) {
         fail 'frequencytovelocity 1 got wrong values';
      }
      freq2 := cs.velocitytofrequency(value=vel, frequnit=freqUnit,
                                      doppler='optical', velunit='km/s')
      if (abs(freq2[1]-freq[1]) > 1e-6) {
         fail 'velocitytofrequency 1 got wrong values';
      }
##
      vel := cs.frequencytovelocity(value=freq, frequnit=freqUnit,
                                    doppler='optical', velunit='km/s')
      if (abs(vel[1]) > 1e-6) {
         fail 'frequencytovelocity 2 got wrong values';
      }
#
      freq2 := cs.velocitytofrequency(value=vel, frequnit=freqUnit,
                                      doppler='optical', velunit='km/s')
      if (abs(freq2[1]-freq[1]) > 1e-6) {
         fail 'velocitytofrequency 2 got wrong values';
      }
##
      rp := cs.referencepixel();
      if (is_fail(rp)) fail;
      freq := cs.toworld (value=rp[1]+1, format='n');
      vel := cs.frequencytovelocity(value=freq, frequnit=freqUnit,
                                    doppler='radio', velunit='m/s')
      d := abs(vel[1] - (1000.0*drv));
      if (d > 1e-6) {
         fail 'frequencytovelocity 3 got wrong values';
      }
      freq2 := cs.velocitytofrequency(value=vel, frequnit=freqUnit,
                                      doppler='radio', velunit='m/s')
      if (abs(freq2[1]-freq[1]) > 1e-6) {
         fail 'velocitytofrequency 3 got wrong values';
      }
##
      freq := [rv[1], freq];
      vel := cs.frequencytovelocity(value=freq, frequnit=freqUnit,
                                    doppler='radio', velunit='m/s')
      if (length(vel)!=2) {
         fail 'frequencytovelocity 4 returned wrong length vector'
      }
      d1 := abs(vel[1] - 0.0);
      d2 := abs(vel[2] - (1000.0*drv));
      if (d1>1e-6 || d2>1e-6) {
         fail 'frequencytovelocity 4 got wrong values';
      }
      freq2 := cs.velocitytofrequency(value=vel, frequnit=freqUnit,
                                      doppler='radio', velunit='m/s');
      d1 := abs(freq[1] - freq2[1]);
      d2 := abs(freq[2] - freq2[2]);
      if (d1>1e-6 || d2>1e-6) {
         fail 'velocitytofrequency 4 got wrong values';
      }

# Forced errors

      vel := cs.frequencytovelocity(value=rv[1], frequnit='Jy',
                                    doppler='radio', velunit='km/s')
      if (!is_fail(vel)) {
         fail 'frequencytovelocity 5 unexpectedly did not fail'
      }
      freq := cs.velocitytofrequency(value=rv[1], frequnit='Jy',
                                     doppler='radio', velunit='km/s')
      if (!is_fail(freq)) {
         fail 'velocitytofrequency 5 unexpectedly did not fail'
      }
##
      vel := cs.frequencytovelocity(value=rv[1], frequnit='GHz',
                                    doppler='radio', velunit='doggies')
      if (!is_fail(vel)) {
         fail 'frequencytovelocity 6 unexpectedly did not fail'
      }
      freq := cs.velocitytofrequency(value=rv[1], frequnit='GHz',
                                     doppler='radio', velunit='doggies')
      if (!is_fail(freq)) {
         fail 'velocitytofrequency 6 unexpectedly did not fail'
      }
#
      if (is_fail(cs.done())) fail;
#
      cs := coordsys(direction=T, spectral=F);
      if (is_fail(cs)) fail 'coordsys constructor 2 failed';
      vel := cs.frequencytovelocity(value=[1.0], frequnit='Hz',
                                    doppler='radio', velunit='km/s')
      if (!is_fail(vel)) {
         fail 'frequencytovelocity 7 unexpectedly did not fail'
      }
      if (is_fail(cs.done())) fail;

###
     return T;
   }


###
   const its.tests.test11 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 11 - setreferencelocation');
#
      cs := coordsys(linear=2, spectral=T);
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';
#
      p := [1.0, 1.0, 1.0];
      ok := cs.setreferencepixel(value=p);
      if (is_fail(ok)) fail;
      rp := cs.referencepixel();
      if (is_fail(rp)) fail;
      if (rp!=p) fail 'setreferencepixel/referencepixel reflection failed'
#
      shp := [101,101,10];
      inc := cs.increment(format='n')
      if (is_fail(inc)) fail;
      w := cs.toworld([1,1,1], 'n');
      if (is_fail(w)) fail;
      w +:= inc;
      p := ((shp-1)/2.0) + 1;
#
      ok := cs.setreferencelocation (pixel=p, world=w, mask=[T,T,T])
      if (is_fail(ok)) fail;
#
      rp := cs.referencepixel()
      if (is_fail(rp)) fail;
      rv := cs.referencevalue(format='n')
      if (is_fail(rv)) fail;
#
      ok := abs(rv[1]-w[1])<1e-6 && abs(rv[2]-w[2])<1e-6 &&
            abs(rv[3]-w[3])<1e-6;
      if (!ok) fail 'setreferencelocation recovered wrong reference value';
#
      ok := abs(rp[1]-p[1])<1e-6 && abs(rp[2]-p[2])<1e-6 &&
            abs(rp[3]-p[3])<1e-6;
      if (!ok) fail 'setreferencelocation recovered wrong reference pixel';
#
      if (is_fail(cs.done())) fail; 
#

###
     return T;
   }

###
   const its.tests.test12 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 12 - toabs, torel, toabsmany, torelmany');
#
      cs := coordsys(direction=T, spectral=T, stokes="I V LL", linear=2);
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';
#
      its.info('');
      its.info('Testing torel/toabs on pixel coordinates');
      its.info('');
#
      p := cs.referencepixel() + 1;
      if (is_fail(p)) fail;
      p2 := cs.torel(p);
      if (is_fail(p2)) fail;
      p3 := cs.toabs(p2);
      if (is_fail(p3)) fail;
      d := abs(p3 - p);
      if (any(d>1e-6)) fail 'torel/toabs pixel reflection test 1 failed';
#
      its.info('');
      its.info('Testing torel/toabs on world coordinates');
      its.info('');
#
      p := cs.referencepixel() + 1;
      if (is_fail(p)) fail;
#
      for (f in "n q s") {
         w := cs.toworld(p, format=f);
         if (is_fail(w)) fail;
#
         w2 := cs.torel(w);
         if (is_fail(w2)) fail;
         w3 := cs.toabs(w2);
         if (is_fail(w3)) fail;
#
         p2 := cs.topixel(w3);
         if (is_fail(p2)) fail;
         d := abs(p2 - p);
         if (any(d>1e-6)) {
            s := spaste('torel/toabs world reflection test 1 failed for format "', 
                        f, '"');
            fail s;
         }
      }
#
      p := cs.referencepixel();
      if (is_fail(p)) fail;
      p2 := cs.toabs(p);
      if (!is_fail(p2)) fail 'toabs 1 unexpectedly did not fail';   
#
      p2 := cs.torel(p)
      if (is_fail(p2)) fail;
      p3 := cs.torel(p2);
      if (!is_fail(p3)) fail 'torel 1 unexpectedly did not fail';   
#
      w := cs.referencevalue();
      if (is_fail(w)) fail;
      w2 := cs.toabs(w);
      if (!is_fail(w2)) fail 'toabs 2 unexpectedly did not fail';   
#
      w2 := cs.torel(w);
      if (is_fail(w2)) fail;
      w3 := cs.torel(w2);
      if (!is_fail(w3)) fail 'torel 2 unexpectedly did not fail';   
#
# toabsmany, torelmany
#
      its.info('');
      its.info('Testing toabsmany/torelmany');
      its.info('');
      p := cs.referencepixel();
      w := cs.toworld(p, 'n');
      n := 5;
      pp := array(0.0, length(p), n);
      ww := array(0.0, length(w), n);
      for (i in 1:n) {
        pp[,i] := p;
        ww[,i] := w;
      }
#
      relpix := cs.torelmany(pp, F);
      if (is_fail(relpix)) fail;
      abspix := cs.toabsmany(relpix, F);
      if (is_fail(abspix)) fail;
#
      relworld := cs.torelmany(ww, T);
      if (is_fail(relworld)) fail;
      absworld := cs.toabsmany(relworld, T);
      if (is_fail(absworld)) fail;
#
      for (i in 1:n) {
         d := abs(p - abspix[,i]);
         if (!all(d<1e-6)) fail 'toabsmany/torelmany gives wrong values for pixels';
#
         d := abs(w - absworld[,i]);
         if (!all(d<1e-6)) fail 'toabsmany/torelmany gives wrong values for world';
      }
#
      if (is_fail(cs.done())) fail;

###
     return T;
   }

###
   const its.tests.test13 := function()
   {
      its.info('');
      its.info('');
      its.info('Test 13 - convert, convertmany');
#
      cs := coordsys(direction=T, spectral=T, stokes="I V LL", linear=2);
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';
      tol := 1.0e-6;
      n := cs.naxes();

####################
# abs pix to abs pix
      absin := array(T, n);
      unitsin := array('pix', n);
      coordin := cs.referencepixel() + 2;    # MAke sure in range of stokes
      absout := array(T, n);
      unitsout := array('pix', n);
      dopplerin := 'radio';
      dopplerout := 'radio';
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
      d := abs(p-coordin);
      if (!all(d<tol)) fail 'convert 1 gives wrong values';

# abs pix to rel pix

      absout := array(F, n);
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      p2 := cs.torel(coordin, F);
      if (is_fail(p2)) fail;
      d := abs(p-p2);
      if (!all(d<tol)) fail 'convert 2 gives wrong values';

# rel pix to abs pix

      absin := array(F, n);
      coordin := cs.torel(cs.referencepixel()+2,F);
      if (is_fail(coordin)) fail;
      absout := array(T, n);
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      p2 := cs.referencepixel() + 2;
      if (is_fail(p2)) fail;
      d := abs(p-p2);
      if (!all(d<tol)) fail 'convert 3 gives wrong values';

#######################
# abs pix to abs world

      absin := array(T, n);
      coordin := cs.referencepixel()+2;
      if (is_fail(coordin)) fail;
      unitsin := array('pix', n);
      absout := array(T, n);
      unitsout := cs.units();
      if (is_fail(unitsout)) fail;
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      p2 := cs.referencepixel() + 2;
      if (is_fail(p2)) fail;
      w := cs.toworld(p2);
      if (is_fail(w)) fail;
      d := abs(p-w);
      if (!all(d<tol)) fail 'convert 4 gives wrong values';

# abs pix to rel world

      absin := array(T, n);
      coordin := cs.referencepixel()+2;
      if (is_fail(coordin)) fail;
      unitsin := array('pix', n);
      absout := array(F, n);
      unitsout := cs.units();
      if (is_fail(unitsout)) fail;
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      p2 := cs.referencepixel() + 2;
      if (is_fail(p2)) fail;
      w := cs.torel(cs.toworld(p2),T);
      if (is_fail(w)) fail;
      d := abs(p-w);
      if (!all(d<tol)) fail 'convert 5 gives wrong values';

# rel pix to abs world

      absin := array(F, n);
      coordin := cs.torel(cs.referencepixel()+2,F);
      if (is_fail(coordin)) fail;
      unitsin := array('pix', n);
      absout := array(T, n);
      unitsout := cs.units();
      if (is_fail(unitsout)) fail;
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      p2 := cs.referencepixel()+2;
      if (is_fail(p2)) fail;
      w := cs.toworld(p2);
      if (is_fail(w)) fail;
      d := abs(p-w);
      if (!all(d<tol)) fail 'convert 6 gives wrong values';

# rel pix to rel world

      absin := array(F, n);
      coordin := cs.torel(cs.referencepixel()+2,F);
      if (is_fail(coordin)) fail;
      unitsin := array('pix', n);
      absout := array(F, n);
      unitsout := cs.units();
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      p2 := cs.referencepixel()+2;
      if (is_fail(p2)) fail;
      w := cs.torel(cs.toworld(p2),T);
      if (is_fail(w)) fail;
      d := abs(p-w);
      if (!all(d<tol)) fail 'convert 7 gives wrong values';

#######################
# abs world to abs pix 

      absin := array(T, n);
      coordin := cs.toworld(cs.referencepixel()+2);
      if (is_fail(coordin)) fail;
      unitsin := cs.units();
      if (is_fail(unitsout)) fail;
      absout := array(T, n);
      unitsout := array('pix', n);
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      p2 := cs.referencepixel() + 2;
      if (is_fail(p2)) fail;
      d := abs(p-p2);
      if (!all(d<tol)) fail 'convert 8 gives wrong values';

# abs world to rel pix

      absin := array(T, n);
      coordin := cs.toworld(cs.referencepixel()+2);
      if (is_fail(coordin)) fail;
      unitsin := cs.units();
      if (is_fail(unitsin)) fail;
      unitsout := array('pix', n);
      absout := array(F, n);
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      p2 := cs.torel(cs.referencepixel()+2,F);
      if (is_fail(p2)) fail;
      d := abs(p-p2);
      if (!all(d<tol)) fail 'convert 9 gives wrong values';

# rel world to abs pix

      absin := array(F, n);
      coordin := cs.torel(cs.toworld(cs.referencepixel()+2),T);
      if (is_fail(coordin)) fail;
      unitsin := cs.units();
      if (is_fail(unitsin)) fail;
      absout := array(T, n);
      unitsout := array('pix', n);
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      p2 := cs.referencepixel()+2;
      if (is_fail(p2)) fail;
      d := abs(p-p2);
      if (!all(d<tol)) fail 'convert 10 gives wrong values';

# rel world to rel pix

      absin := array(F, n);
      coordin := cs.torel(cs.toworld(cs.referencepixel()+2),T);
      if (is_fail(coordin)) fail;
      unitsin := cs.units();
      absout := array(F, n);
      unitsout := array('pix', n);
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      p2 := cs.torel(cs.referencepixel()+2,F);
      if (is_fail(p2)) fail;
      d := abs(p-p2);
      if (!all(d<tol)) fail 'convert 11 gives wrong values';

# velocity

      local pa, wa;
      ok := cs.findcoordinate(pa, wa, 'spectral');
      if (is_fail(ok)) fail;
#
      sAxis := pa[1];
      dopplerin := 'radio';
      dopplerout := 'optical';
      vRefIn := cs.frequencytovelocity(value=cs.referencevalue()[sAxis],
                                       doppler=dopplerin, 
                                       velunit='km/s');
      if (is_fail(vRefIn)) fail;
      vRefOut := cs.frequencytovelocity(value=cs.referencevalue()[sAxis],
                                        doppler=dopplerout, 
                                        velunit='km/s');
      if (is_fail(vRefOut)) fail;

# absvel to absvel

      absin := array(T, n);
      p := cs.referencepixel() + 2;
      if (is_fail(p)) fail;
      coordin := cs.toworld(p);
      if (is_fail(coordin)) fail;
      unitsin := cs.units();
      if (is_fail(unitsin)) fail;
      absout := array(T, n);
      unitsout := cs.units();
      if (is_fail(unitsout)) fail;
#
      w := coordin[sAxis];
      vIn := cs.frequencytovelocity(value=w, doppler=dopplerin, 
                                    velunit='km/s');
      if (is_fail(vIn)) fail;
      vOut := cs.frequencytovelocity(value=w, doppler=dopplerout,
                                     velunit='km/s');
      if (is_fail(vOut)) fail;
#
      coordin[sAxis] := vIn;
      unitsin[sAxis] := 'km/s';
      unitsout[sAxis] := 'km/s';
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      d := abs(p[sAxis]-vOut);
      if (!all(d<tol)) fail 'convert 12 gives wrong values';

# absvel to relvel

      p := cs.referencepixel() + 2;
      if (is_fail(p)) fail;
      coordin := cs.toworld(p);
      if (is_fail(coordin)) fail;
#
      w := coordin[sAxis];
      vIn := cs.frequencytovelocity(value=w, doppler=dopplerin, 
                                    velunit='km/s');
      if (is_fail(vIn)) fail;
      vOut := cs.frequencytovelocity(value=w, doppler=dopplerout,
                                     velunit='km/s');
      if (is_fail(vOut)) fail;
      vOut -:= vRefOut;
#
      coordin[sAxis] := vIn;
      absin[sAxis] := T;
      absout[sAxis] := F;
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      d := abs(p[sAxis]-vOut);
      if (!all(d<tol)) fail 'convert 13 gives wrong values';

# absvel to absworld

      p := cs.referencepixel() + 2;
      if (is_fail(p)) fail;
      coordin := cs.toworld(p);
      if (is_fail(coordin)) fail;
#
      w := coordin[sAxis];
      vIn := cs.frequencytovelocity(value=w, doppler=dopplerin, 
                                    velunit='km/s');
      if (is_fail(vIn)) fail;
#
      coordin[sAxis] := vIn;
      absin[sAxis] := T;
      absout[sAxis] := T;
      unitsout := cs.units();
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      w := cs.toworld(cs.referencepixel()+2);
      if (is_fail(w)) fail;
      d := abs(p[sAxis]-w[sAxis]);
      if (!all(d<tol)) fail 'convert 14 gives wrong values';

# absvel to relworld

      p := cs.referencepixel() + 2;
      if (is_fail(p)) fail;
      coordin := cs.toworld(p);
      if (is_fail(coordin)) fail;
#
      w := coordin[sAxis];
      vIn := cs.frequencytovelocity(value=w, doppler=dopplerin, 
                                    velunit='km/s');
      if (is_fail(vIn)) fail;
#
      coordin[sAxis] := vIn;
      absin[sAxis] := T;
      absout[sAxis] := F;
      unitsout := cs.units();
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      w := cs.torel(cs.toworld(cs.referencepixel()+2),T);
      if (is_fail(w)) fail;
      d := abs(p[sAxis]-w[sAxis]);
      if (!all(d<tol)) fail 'convert 15 gives wrong values';

# absvel to abspix

      p := cs.referencepixel() + 2;
      if (is_fail(p)) fail;
      coordin := cs.toworld(p);
      if (is_fail(coordin)) fail;
#
      w := coordin[sAxis];
      vIn := cs.frequencytovelocity(value=w, doppler=dopplerin, 
                                    velunit='km/s');
      if (is_fail(vIn)) fail;
#
      coordin[sAxis] := vIn;
      absin[sAxis] := T;
      absout[sAxis] := T;
      unitsout[sAxis] := 'pix';
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      p2 := cs.referencepixel()+2;
      if (is_fail(p2)) fail;
      d := abs(p[sAxis]-p2[sAxis]);
      if (!all(d<tol)) fail 'convert 16 gives wrong values';

# absvel to relpix

      p := cs.referencepixel() + 2;
      if (is_fail(p)) fail;
      coordin := cs.toworld(p);
      if (is_fail(coordin)) fail;
#
      w := coordin[sAxis];
      vIn := cs.frequencytovelocity(value=w, doppler=dopplerin, 
                                    velunit='km/s');
      if (is_fail(vIn)) fail;
#
      coordin[sAxis] := vIn;
      absin[sAxis] := T;
      absout[sAxis] := F;
      unitsout[sAxis] := 'pix';
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      p2  := cs.torel(cs.referencepixel()+2,F);
      if (is_fail(p2)) fail;
      d := abs(p[sAxis]-p2[sAxis]);
      if (!all(d<tol)) fail 'convert 17 gives wrong values';

# relvel to absvel

      p := cs.referencepixel() + 2;
      if (is_fail(p)) fail;
      coordin := cs.toworld(p);
      if (is_fail(coordin)) fail;
#
      w := coordin[sAxis];
      vIn := cs.frequencytovelocity(value=w, doppler=dopplerin, 
                                    velunit='km/s');
      if (is_fail(vIn)) fail;
      vIn -:= vRefIn;
      vOut := cs.frequencytovelocity(value=w, doppler=dopplerout,
                                     velunit='km/s');
      if (is_fail(vOut)) fail;
#
      coordin[sAxis] := vIn;
      absin[sAxis] := F;
      absout[sAxis] := T;
      unitsin[sAxis] := 'km/s';
      unitsout[sAxis] := 'km/s';
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      d := abs(p[sAxis]-vOut);
      if (!all(d<tol)) fail 'convert 18 gives wrong values';

# absworld to absvel 

      p := cs.referencepixel() + 2;
      if (is_fail(p)) fail;
      coordin := cs.toworld(p);
      if (is_fail(coordin)) fail;
      vOut := cs.frequencytovelocity(value=coordin[sAxis], 
                                     doppler=dopplerout,
                                     velunit='km/s');
      if (is_fail(vOut)) fail;
#
      absin[sAxis] := T;
      absout[sAxis] := T;
      unitsin := cs.units();
      unitsout[sAxis] := 'km/s';
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      d := abs(p[sAxis]-vOut);
      if (!all(d<tol)) fail 'convert 19 gives wrong values';

# relworld to absvel

      p := cs.referencepixel() + 2;
      if (is_fail(p)) fail;
      w := cs.toworld(p);
      if (is_fail(w)) fail;
      coordin := cs.torel(w,T);
      if (is_fail(coordin)) fail;
      vOut := cs.frequencytovelocity(value=w[sAxis], 
                                     doppler=dopplerout,
                                     velunit='km/s');
      if (is_fail(vOut)) fail;
#
      absin[sAxis] := F;
      absout[sAxis] := T;
      unitsin := cs.units();
      unitsout[sAxis] := 'km/s';
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      d := abs(p[sAxis]-vOut);
      if (!all(d<tol)) fail 'convert 20 gives wrong values';

# abspix to absvel 

      p := cs.referencepixel() + 2;
      if (is_fail(p)) fail;
      w := cs.toworld(p);
      if (is_fail(w)) fail;
      vOut := cs.frequencytovelocity(value=w[sAxis], 
                                     doppler=dopplerout,
                                     velunit='km/s');
      if (is_fail(vOut)) fail;
#
      coordin := w;
      coordin[sAxis] := p[sAxis];
      absin[sAxis] := T;
      absout[sAxis] := T;
      unitsin[sAxis] := 'pix';
      unitsout[sAxis] := 'km/s';
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      d := abs(p[sAxis]-vOut);
      if (!all(d<tol)) fail 'convert 21 gives wrong values';

# relpix to absvel 

      p := cs.referencepixel() + 2;
      if (is_fail(p)) fail;
      w := cs.toworld(p);
      if (is_fail(w)) fail;
      vOut := cs.frequencytovelocity(value=w[sAxis], 
                                     doppler=dopplerout,
                                     velunit='km/s');
      if (is_fail(vOut)) fail;
#
      p := cs.torel(p,F);
      coordin[sAxis] := p[sAxis];
      absin[sAxis] := F;
      absout[sAxis] := T;
      unitsin[sAxis] := 'pix';
      unitsout[sAxis] := 'km/s';
#
      p := cs.convert(coordin, absin, dopplerin, unitsin,
                      absout, dopplerout, unitsout);
      if (is_fail(p)) fail;
#
      d := abs(p[sAxis]-vOut);
      if (!all(d<tol)) fail 'convert 22 gives wrong values';
      cs.done()

# mixed

      cs := coordsys(direction=T, spectral=T, linear=1)
      if (is_fail(cs)) fail;
      absPix := cs.referencepixel() + 4;
      if (is_fail(absPix)) fail;
      relPix := cs.torel(absPix, F);
      if (is_fail(relPix)) fail;
      absWorld := cs.toworld(absPix);
      if (is_fail(absWorld)) fail;
      relWorld := cs.torel(absWorld, T);
      if (is_fail(relWorld)) fail;
      n := cs.naxes();      

# convertmany.  any test is as good as any other

      coordin := cs.referencepixel();
      if (is_fail(coordin)) fail;
      absin := array(T, n);
      unitsin := array('pix', n);
      dopplerin := 'radio';
      absout := array(T, n);
      unitsout := cs.units();
      if (is_fail(unitsout)) fail;
      dopplerout := 'radio';
#
      coordout := cs.convert(coordin, absin, dopplerin, unitsin,
                             absout, dopplerout, unitsout);
      if (is_fail(coordout)) fail;
#
      rIn := array(0, length(coordin), 10);
      for (i in 1:10) {
         rIn[,i] := coordin;
      }
      rOut := cs.convertmany (rIn, absin, dopplerin, unitsin,
                              absout, dopplerout, unitsout);
      if (is_fail(rOut)) fail;
      for (i in 1:10) {
         coordout2 := rOut[,i];
         d := coordout2 - coordout;
         if (!all(d<tol)) fail 'convertmany gives wrong values';
      }
#
      return T;
   }

###
   const its.tests.test14 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 14 - setspectral');
#
      its.info('');
      its.info('Testing setspectral');
      its.info('');
#
      cs := coordsys(direction=T);
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';
      ok := cs.setspectral(refcode='lsrk');
      if (!is_fail(ok)) {
         fail ('setspectral 1 unexpectedly did not fail');
      }
      cs.done();
#
      cs := coordsys(spectral=T);
#
      rc := 'LSRK';
      ok := cs.setspectral(refcode=rc);
      if (is_fail(ok)) fail;
      if (cs.referencecode('spectral') != rc) {
         fail 'setspectral/reference code test fails';
      }
#
      rf := dq.quantity('1.0GHz');
      ok := cs.setspectral(restfreq=rf);
      if (is_fail(ok)) fail;
      rf2 := cs.restfrequency();
      if (is_fail(rf2)) fail;
      rf3 := dq.convert(rf2, 'GHz');
      if (is_fail(rf3)) fail;
      if (dq.getvalue(rf3)[1] != 1.0) {
         fail 'setspectral/restfrequency test fails';
      }
#
      fd := [1, 1.5, 2, 2.5, 3];
      fq := dq.quantity(fd, 'GHz');
      ok := cs.setspectral(frequencies=fq);
      if (is_fail(ok)) fail;
#
      doppler := 'optical';
      vunit := 'km/s';
      vd := cs.frequencytovelocity(fd, 'GHz', doppler, vunit);
      vq := dq.quantity(vd, vunit);
      ok := cs.setspectral(velocities=vq, doppler=doppler);
      if (is_fail(ok)) fail;
#
      fd2 := cs.velocitytofrequency(vd, 'GHz', doppler, vunit);
      d := abs(fd2 - fd);
      tol := 1e-6;
      if (!all(d<tol)) fail 'setspectral/freq/vel consistency test failed'
#
      if (is_fail(cs.done())) fail;
   }


###
   const its.tests.test15 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 15 - settabular');
#
      its.info('');
      its.info('Testing settabular');
      its.info('');
#
      cs := coordsys(direction=T);
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';
      ok := cs.settabular(pixel=[1,2], world=[1,2]);
      if (!is_fail(ok)) {
         fail ('settabular 1 unexpectedley did not fail');
      }
      cs.done();
#
      cs := coordsys(tabular=T);
#
      p := [1, 2, 3, 4, 5]
      w := [10, 20, 30, 40, 50];
      ok := cs.settabular(pixel=p, world=w)
      if (is_fail(ok)) fail;
#      
      rv := cs.referencevalue();
      if (is_fail(rv)) fail;
      if (rv[1] != w[1])  fail 'settabular test 1 failed (refval)';
#
      rp := cs.referencepixel();
      if (is_fail(rp)) fail;
      if (rp[1] != p[1])  fail 'settabular test 1 failed (refpix)';
#
      ok := cs.settabular(pixel=[1,2,3], world=[10,20])
      if (!is_fail(ok)) fail 'settabular test 2 unexpectedly did not fail';
#
      ok := cs.settabular(pixel=[1,2], world=[1,10,20])
      if (!is_fail(ok)) fail 'settabular test 3 unexpectedly did not fail';
#
      ok := cs.settabular(pixel=[1,2,3], world=[1,10,20])
      if (is_fail(ok)) fail 'settabular test 4 failed';
      ok := cs.settabular(pixel=[1,2,3,4]);
      if (!is_fail(ok)) fail 'settabular test 5 unexpectedly did not fail';
      ok := cs.settabular(world=[1,2,3,4]);
      if (!is_fail(ok)) fail 'settabular test 6 unexpectedly did not fail';
#
      if (is_fail(cs.done())) fail;
   }



###
   const its.tests.test16 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 16 - addcoordinate');
#
      its.info('');
      its.info('Testing addcoordinate');
      its.info('');
#
      cs := coordsys();
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';
#
      ok := cs.addcoordinate(direction=T, spectral=T, linear=2, tabular=T, stokes="I V");
      if (is_fail(ok)) {
         fail ('addcoordinate failed');
      }
#
      n := cs.ncoordinates();
      if (n != 5) {
         fail ('addcoordinate gave wrong number of coordinates');
      }

# We don't know what order they will be in. This is annoying.

      types := cs.coordinatetype();
      hasDir := F;
      hasSpec := F;
      hasLin := F;
      hasTab := F;
      hasStokes := F;
      for (i in 1:n) {
        if (types[i]=='Direction') {
           hasDir := T;
        } else if (types[i]=='Spectral') {
           hasSpec := T;
        } else if (types[i]=='Linear') {
           hasLin := T;
        } else if (types[i]=='Tabular') {
           hasTab := T;
        } else if (types[i]=='Stokes') {
           hasStokes := T;
        }      
     }
#
     ok := hasDir && hasSpec && hasLin && hasTab && hasStokes;
     if (!ok) {
        fail 'addcoordinate did not add correct types';
     }     
#
      cs.done();
#
   }

###
   const its.tests.test17 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 17 - toworld, topixel with reference conversion');
#
      cs := coordsys(direction=T, spectral=T);
      if (is_fail(cs)) fail;
#
      v := cs.units();
      v[1] := 'rad';
      v[2] := 'rad';
      v[3] := 'Hz';
      ok := cs.setunits(v);
      if (is_fail(ok)) fail;
# 
      cs.setrestfrequency(1.420405752E9);
#
      ok := cs.setreferencecode(value='J2000', type='direction', adjust=F);
      if (is_fail(ok)) fail;   
      ok := cs.setreferencecode(value='LSRK', type='spectral', adjust=F);
      if (is_fail(ok)) fail;   
#
      v := cs.referencevalue();
      v[1] := 0.0;
      v[2] := -0.5;
      v[3] := 1.4e9;
      ok := cs.setreferencevalue(v);
      if (is_fail(ok)) fail;
#
      v := cs.referencepixel();
      v[1] := 101;
      v[2] := 121;
      v[3] := 10.5;
      ok := cs.setreferencepixel(v);
      if (is_fail(ok)) fail;
#
      v := cs.increment();
      v[1] := -1.0e-6;
      v[2] :=  2.0e-6;
      v[3] :=  4.0e6;
      ok := cs.setincrement(v);
      if (is_fail(ok)) fail;
#
      v := cs.units();
      v[1] := 'deg';
      v[2] := 'deg';
      ok := cs.setunits(v);
      if (is_fail(ok)) fail;

      ok := cs.setconversiontype(direction='GALACTIC', spectral='BARY');
      if (is_fail(ok)) fail;   
      local d,s;
      d := cs.conversiontype(type='direction')
      if (is_fail(d)) fail;   
      s := cs.conversiontype(type='spectral')
      if (is_fail(s)) fail;   
      if (d != 'GALACTIC' || s != 'BARY') {
         fail 'setconversiontype consistency test failed';
      }
#
      p := cs.referencepixel() + 10.0;
      if (is_fail(p)) fail;
      w := cs.toworld(value=p, format='n');
      if (is_fail(w)) fail;
      p2 := cs.topixel(value=w);
      if (is_fail(p2)) fail;
#
# Need to look into why i need such a large tolerance
#
      d := abs(p2 - p);
      tol := 1e-3;
      if (!all(d<tol)) fail 'failed consistency test 1'

###
     return T;
   }


###
   const its.tests.test18 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 18 - setdirection');
#
      its.info('');
      its.info('Testing setdirection');
      its.info('');
#
      cs := coordsys(direction=T);
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';

# Test 1

      refcode := 'GALACTIC';
      proj := 'CAR';
      projpar := [];
      refpix := 1.1 * cs.referencepixel();
      refval := 1.1 * cs.referencevalue(format='n');
      xform := array(0.0, 2, 2); 
      xform[1,1] := 1.0;
      xform[2,2] := 1.0;
      ok := cs.setdirection (refcode=refcode,
                             proj=proj, projpar=projpar,
                             refpix=refpix, refval=refval,
                             xform=xform);
      if (is_fail(ok)) fail;
#
      if (proj != cs.projection().type) {
         fail 'Projection was not updated';
      }
      if (length(projpar) > 0) {
         if (projpar != cs.projection().parameters) {
            fail 'Projection parameters were not updated';
         }
      }
      if (refpix != cs.referencepixel()) {
         fail 'Reference pixel was not updated';
      }
      if (refval != cs.referencevalue(format='n')) {
         fail 'Reference value was not updated';
      }

# Test 2

      refcode := 'J2000';
      proj := 'SIN';
      projpar := [0,0];
      refval := "20.0deg -33deg";
      refval2 := [20,-33];
      ok := cs.setdirection (refcode=refcode,
                             proj=proj, projpar=projpar,
                             refval=refval);
      if (is_fail(ok)) fail;
#
      if (proj != cs.projection().type) {
         fail 'Projection was not updated';
      }
      if (length(projpar) > 0) {
         if (projpar != cs.projection().parameters) {
            fail 'Projection parameters were not updated';
         }
      }
      ok := cs.setunits (value="deg deg");
      if (refval2 != cs.referencevalue(format='n')) {
         fail 'Reference value was not updated';
      }
#
      if (is_fail(cs.done())) fail;
   }

###
   const its.tests.test19 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 19 - replace');
#
      its.info('');
      its.info('Testing replace');
      its.info('');
#
      cs := coordsys(direction=T, linear=1);
      if (is_fail(cs)) fail 'coordsys constructor 1 failed';
#
      cs2 := coordsys(linear=1);
      if (is_fail(cs2)) fail 'coordsys constructor 2 failed';
#
      ok := cs.replace(cs2, whichin=1, whichout=1);
      if (!is_fail(ok)) {
         fail 'replace 1 unexpectedly did not fail';
      }
      ok := cs2.done();
#
      cs2 := coordsys(spectral=T);
      ok := cs.replace(cs2, whichin=1, whichout=2);
      if (is_fail(ok)) fail;
      if (cs.coordinatetype(2) != 'Spectral') {
         fail 'Replace 1 did not set correct coordinate type';
      }
#
      ok := cs2.done();
      ok := cs.done();


}

#####################################################################
#
# Get on with it
#
#
    note ('', priority='WARN', origin='coordsysservertest.g');
    note ('These tests include forced errors.  If the logger GUI is active ',
          priority='WARN', origin='coordsysservertest.g');
    note ('you should expect to see Red Boxes Of Death (RBOD) with many errors',
          priority='WARN', origin='coordsysservertest.g');
    note ('If the test finally returns T, then it has succeeded\n\n',
          priority='WARN', origin='coordsysservertest.g');
    note ('', priority='WARN', origin='coordsysservertest.g');

    fn := field_names(its.tests);
    const ntests := length(fn);
    if (is_unset(which)) which := [1:ntests];
    if (length(which)==1) which := [which];
#
    fn2 := fn[which];
    for (i in fn2) {
       if (has_field(its.tests, i)) {
          if (is_fail(its.tests[i]())) fail;
       } else {
          fail 'test does not exist'
       }
    }
#    
    return T;
}
