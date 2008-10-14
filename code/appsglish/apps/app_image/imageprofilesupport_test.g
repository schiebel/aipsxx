# imageprofilesupport_test.g: test imageprofilesupport.g
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: imageprofilesupport_test.g,v 19.4 2004/11/24 00:17:52 nkilleen Exp $
#
include 'image.g'
include 'coordsys.g'
include 'imageprofilesupport.g'
include 'note.g'
include 'serverexists.g'
include 'os.g'
include 'regionmanager.g'
pragma include once


imageprofilesupport_test := function(which=unset, destroy=T)
{
   if (!serverexists('dos', 'os', dos)) {
      return throw('The os server "dos" is either not running or not valid',
                    origin='imageprofilesupporttest.g');
   }
   if (!serverexists('drm', 'regionmanager', drm)) {
      return throw('The regionmanager server "drm" is either not running or not valid',
                    origin='imageprofilesupporttest.g');
   }
   if (!serverexists('dq', 'quanta', dq)) {
      return throw('The quanta server "dq" is either not running or not valid',
                    origin='imageprofilesupporttest.g');
   }
#
    its := [=];
    its.p := [=];
    its.tests := [=];

###
   const its.tests.test1 := function()
#
# makeabcissa/makeordinate interface
#
   {
      wider its;
      note ('Test 1 - makeabcissa/makeordinate',
             origin='imageprofilesupport_test.test1');
#
      csys := coordsys(spectral=T, direction=T)
      if (is_fail(csys)) fail;
      ok := csys.setreferencecode('BARY', type='spectral')
      if (is_fail(ok)) fail; 
#
      n := 20000
      shp := [1,1,n];
      profileaxis := 3;
#
      im := imagefromshape(shape=shp, csys=csys);
      if (is_fail(im)) fail;
      data := array(1:shp[profileaxis], 1, 1, shp[profileaxis]);
      ok := im.putchunk(data);
      if (is_fail(ok)) fail;
#
      idx := length(its.p) + 1;
      its.p[idx] := imageprofilesupport(csys=csys, shp=shp, multiabcissa=F, widgetset=dws);
      if (is_fail(its.p[idx])) fail;
#
      ok := its.p[idx].setprofileaxis(profileaxis);
      if (is_fail(ok)) fail;
      ok := its.p[idx].makeplotter();
      if (is_fail(ok)) fail;
      ok := its.p[idx].makemenus();
      if (is_fail(ok)) fail;
#
      pos := [1,1,1];    
      ok := its.p[idx].makeabcissa(pixel=pos);
      if (is_fail(ok)) fail;
      ok := its.p[idx].makeordinate(im=im);
      if (is_fail(ok)) fail;
      ok := its.p[idx].hasprofile() && its.p[idx].hasplotter() &&
            its.p[idx].nprofiles()==1 && its.p[idx].npoints()==shp[profileaxis];
      if (!ok) {
         return throw ('State of tool is wrong', 
                        origin='imageprofilesupport_test.test1');
      }
#
      ok := its.p[idx].plot()
      if (is_fail(ok)) fail;
#
      ok := csys.done();
      if (destroy) ok := its.p[idx].done();
#
      return T;
  }

###
   const its.tests.test2 := function()
#
# makeabcissa/setordinate interface
#
   {
      wider its;
      note ('Test 2 - makeabcissa/setordinate', 
            origin='imageprofilesupport_test.test2');
#
      csys := coordsys(spectral=T, direction=T);
      if (is_fail(csys)) fail;
#
      shp := [1,1,1024];
      profileaxis := 3;
#
      idx := length(its.p) + 1;
      its.p[idx] := imageprofilesupport(csys=csys, shp=shp, multiabcissa=F, widgetset=dws);
      if (is_fail(its.p[idx])) fail;
#
      ok := its.p[idx].setprofileaxis(profileaxis);
      if (is_fail(ok)) fail;
      ok := its.p[idx].makeplotter();
      if (is_fail(ok)) fail;
      ok := its.p[idx].makemenus();
      if (is_fail(ok)) fail;
#
      ok := csys.setreferencecode('BARY', type='spectral')
      if (is_fail(ok)) fail; 
      ok := its.p[idx].setcoordinatesystem(csys, shp);
      if (is_fail(ok)) fail; 
#
      pos := [1,1,1];    
      ok := its.p[idx].makeabcissa(pixel=pos);
      if (is_fail(ok)) fail;
#
      data := 1:shp[profileaxis];
      ok := its.p[idx].setordinate(data=data);
      if (is_fail(ok)) fail;
      ok := its.p[idx].plot()
      if (is_fail(ok)) fail;
#
      ok := its.p[idx].hasprofile() && its.p[idx].hasplotter() &&
            its.p[idx].nprofiles()==1 && its.p[idx].npoints()==shp[profileaxis];
      if (!ok) {
         return throw ('State of tool is wrong', 
                        origin='imageprofilesupport_test.test2');
      }
#
      ok := csys.done();
      if (destroy) ok := its.p[idx].done();
#
      return T;
  }


###
   const its.tests.test3 := function()
#
# setprofile interface
#
   {
      wider its;
      note ('Test 3 - setprofile', 
            origin='imageprofilesupport_test.test3');
#
      csys := coordsys(spectral=T, direction=T);
      if (is_fail(csys)) fail;
#
      shp := [1,1,128];
      profileaxis := 3;
#
      idx := length(its.p) + 1;
      its.p[idx] := imageprofilesupport(csys=csys, shp=shp, multiabcissa=T, widgetset=dws);
      if (is_fail(its.p[idx])) fail;
#
      ok := its.p[idx].setprofileaxis(profileaxis);
      if (is_fail(ok)) fail;
      ok := its.p[idx].makeplotter();
      if (is_fail(ok)) fail;
      ok := its.p[idx].makemenus();
      if (is_fail(ok)) fail;

# Profile 1 with abcissa specified as absolute pixels

      n2 := [];
      n := as_integer(shp[profileaxis]/4);
      n2[1] := n;
      abc := 1:n;
      ord := as_double(1:n) / n;
      ok := its.p[idx].setprofile(abcissa=abc, ordinate=ord, unit='pix', ci=7, ls=1);
      if (is_fail(ok)) fail;

# Profile 2 with abcissa specified as MHz

      absPix := (n+1):(2*n);
      n2[2] := length(absPix);
      cin := array(0.0, 3, n2[2]);              # n2 conversions, each of length 3
      cin[profileaxis,] := absPix;
      unitsOut := csys.units();
      unitsOut[profileaxis] := 'MHz';
      cout := csys.convertmany (coordin=cin, absin=[T,T,T], unitsin="pix pix pix", 
                                absout=[T,T,T], unitsout=unitsOut);
      abc := cout[profileaxis,];
      ok := its.p[idx].setprofile(abcissa=abc, ordinate=ord, unit='MHz', ci=8, ls=2)
      if (is_fail(ok)) fail;

# Profile 3 with abcissa specified as m/s and mask

      absPix := (2*n+1):(3*n);
      n2[3] := length(absPix);
      cin := array(0.0, 3, n2[3]);              # n2 conversions, each of length 3
      cin[profileaxis,] := absPix;
      unitsOut[profileaxis] := 'm/s';
      cout := csys.convertmany (coordin=cin, absin=[T,T,T], unitsin="pix pix pix", 
                                absout=[T,T,T], unitsout=unitsOut, 
                                dopplerin='radio', dopplerout='radio');
      abc := cout[profileaxis,];
      mask := array(T,n2[3]);
      c := as_integer(n2[3]/2);
      o := as_integer(n2[3]/8);
      mask[(c-o):(c+o)] := F;
      ok := its.p[idx].setprofile(abcissa=abc, ordinate=ord, mask=mask, 
                         unit='m/s', doppler='radio', ci=9, ls=3)
      if (is_fail(ok)) fail;
#
      ok := its.p[idx].setordinateunit ('Jy/beam');
      ok := its.p[idx].plot()
      if (is_fail(ok)) fail;
#
      ok := its.p[idx].hasprofile() && its.p[idx].hasplotter() && 
            its.p[idx].nprofiles()==3 && its.p[idx].npoints(1)==n2[1] &&
            its.p[idx].npoints(2)==n2[2] && its.p[idx].npoints(3)==n2[3];
           
      if (!ok) {
         return throw ('State of tool is wrong', 
                        origin='imageprofilesupport_test.test3');
      }
#
      ok := csys.done();
      if (destroy) ok := its.p[idx].done();
#
      return T;
  }


#####################################################################
#
# Get on with it
#
    if (!have_gui()) {
       note ('No GUI available', priority='WARN', origin='imageprofilesupport_test.g');
       return F;
    }
#
    note ('', priority='WARN', origin='imageprofilesupport_test.g');
    note ('These tests include forced errors.  If the logger GUI is active ',
          priority='WARN', origin='imageprofilesupport_test.g');
    note ('you should expect to see Red Boxes Of Death (RBOD) with many errors',
          priority='WARN', origin='imageprofilesupport_test.g');
    note ('If the test finally returns T, then it has succeeded\n\n',
          priority='WARN', origin='imageprofilesupport_test.g');
    note ('', priority='WARN', origin='imageprofilesupport_test.g');
#
    fn := field_names(its.tests);
    const ntests := length(fn);
    if (is_unset(which)) which := [1:ntests];
    if (length(which)==1) which := [which];
#
    fn2 := fn[which];
    for (i in fn2) {
       msg := spaste('Failed ', i);
       if (has_field(its.tests, i)) {
          ok := its.tests[i]();
          if (is_fail(ok)) {
             msg2 := spaste ('Failed ', i, ' with ', ok::message);
             return throw(msg2, origin='imageprofilesupport_test.g');
          } else if (!ok) {
             return throw(msg, origin='imageprofilesupport_test.g');
          }
       }
    }
#
    return T;
}
