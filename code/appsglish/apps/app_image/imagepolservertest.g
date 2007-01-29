# imagepolservertest.g: test imagepol.g
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
#   $Id: imagepolservertest.g,v 19.2 2004/08/25 00:58:52 cvsmgr Exp $
#
include 'imagepol.g'
include 'image.g'
include 'note.g'
include 'serverexists.g'
include 'randomnumbers.g';
include 'statistics.g';
include 'os.g'

pragma include once

imagepolservertest := function(which=unset)
{
   if (!serverexists('dos', 'os', dos)) {
      return throw('The os server "dos" is either not running or not valid',
                    origin='imagepolservertest.g');
   }
#
    global dowait;
    olddowait := dowait;
    dowait := T;
    its := [=];
    its.tests := [=];
    its.random := randomnumbers();
    if (is_fail(its.random)) fail;

###
    const its.info := function(...) 
    { 
       note(...,origin='imagepolservertest()');
    }

###
    const its.stop := function(...) 
    { 
        global dowait;
        dowait := olddowait;
	return throw(paste(...), origin='imagepolservertest()');
    }
###
    const its.cleanup := function(dir)
    {
       if (dos.fileexists(file=dir, follow=T)) {
          its.info('Cleaning up directory ', dir);
          ok := dos.remove(pathname=dir, recursive=T, follow=T);
          if (is_fail(ok)) {
              return its.stop('Cleanup of ', dir, ' fails!');
           }
       }
       return T;
    }

###
   const its.addnoise := function(ref data, sigma)
   {
      wider its;
      noise := its.random.normal(0.0, sigma*sigma, shape(data));
      if (is_fail(noise)) fail;
      val data +:= noise;
      return T;
   }

###
    const its.make_data := function(imshape, stokes)
#
# 3D only
#
    {
       if (imshape[3]>4) fail;
       if (imshape[3]!=length(stokes)) fail;
#
       data := array(0, imshape[1], imshape[2], imshape[3])
       for (k in 1:(imshape[3])) {
          data[,,k] := stokes[k];
       }
       return data;
    }

###
   const its.tests.test1 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 1 - Constructor, is_imagepol, done, id and summary');
#
      const testdir := 'imagepoltest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make RA/DEC only
#
     imname := paste(testdir,'/','imagefromshape.image',sep='');
     myim := imagefromshape(imname, [10,10]);
     if (is_fail(myim)) fail;
#
     p := imagepol(imname);
     if (!is_fail(p)) {
        return its.stop('Constructor 1 unexpectedly did not fail');
     }
     if (is_fail(myim.delete(T))) fail;
#
# RA/DEC/I
#
     myim := imagefromshape(imname, [10,10,1]);
     if (is_fail(myim)) fail;
     p := imagepol(imname);
     if (!is_fail(p)) {
        return its.stop('Constructor 2 unexpectedly did not fail');
     }
     if (is_fail(myim.delete(T))) fail;
#
# RA/DEC/IQ
#
     myim := imagefromshape(imname, [10,10,2]);
     if (is_fail(myim)) fail;
     p := imagepol(imname);
     if (!is_fail(p)) {
        return its.stop('Constructor 3 unexpectedly did not fail');
     }
     if (is_fail(myim.delete(T))) fail;
#
# RA/DEC/IQU
#
     myim := imagefromshape(imname, [10,10,3]);
     if (is_fail(myim)) fail;
     p := imagepol(imname);
     if (is_fail(p)) {
        return its.stop('Constructor 4 failed');
     }
     if (is_fail(p.done())) fail;
     if (is_fail(myim.delete(T))) fail;
#
# RA/DEC/IQUV
#
     myim := imagefromshape(imname, [10,10,4]);
     if (is_fail(myim)) fail;
     p := imagepol(imname);
     if (is_fail(p)) {
        return its.stop('Constructor 5 failed');
     }
     if (is_fail(p.done())) fail;
#
# Test tool constructor
#
     p := imagepol(myim);
     if (is_fail(p)) {
        return its.stop('Constructor 6 failed');
     }
     if (is_fail(myim.done())) fail;
#
# imagepol
#
     if (!is_imagepol(p)) return its.stop ('is_imagepol 1 failed');
     if (is_imagepol([10,20])) return its.stop ('is_imagepol 2 failed');
#
# Utility functions
#
     id := p.id();
     if (is_fail(id)) fail;
     ok := has_field(id,'sequence') && has_field(id, 'pid') &&
           has_field(id, 'time') && has_field(id, 'host') &&
           has_field(id, 'agentid');
     if (!ok) {
        return its.stop('id function record is incorrect');
     }
#
     ok := p.summary();
     if (is_fail(ok)) fail;
#
     if (is_fail(p.done())) fail;

#
     return its.cleanup(testdir);

   }



###
   const its.tests.test2 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 2 - stokesi, stokesq, stokesu, stokesv, stokes');
#
      const testdir := 'imagepoltest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make some data
#
      shape := [10,10,4];
      stokes := [14,2,3,4];
      data := its.make_data(shape, stokes);
      if (is_fail(data)) fail;
#
# Make image - RA/DEC/IQUV
#
     imname := paste(testdir,'/','imagefromarray.image',sep='')
     myim := imagefromarray(imname, data);
     if (is_fail(myim)) fail;
     if (is_fail(myim.done())) fail;
#
# Make polarimetry server
#
     p := imagepol(imname);
     if (is_fail(p)) fail;
#
# Get Stokes images
#
     s := p.stokesi();
     if (is_fail(s)) fail;
     pixels := s.getchunk();
     if (!all(pixels-stokes[1] < 0.0001)) {
        return its.stop('Stokes I values are wrong');
     }
     if (is_fail(s.done())) fail;
#
     s := p.stokesq();
     if (is_fail(s)) fail;
     pixels := s.getchunk();
     if (!all(pixels-stokes[2] < 0.0001)) {
        return its.stop('Stokes I values are wrong');
     }
     if (is_fail(s.done())) fail;
#
     s := p.stokesu();
     if (is_fail(s)) fail;
     if (!all(pixels-stokes[3] < 0.0001)) {
        return its.stop('Stokes I values are wrong');
     }
     if (is_fail(s.done())) fail;
#
     s := p.stokesv();    
     if (is_fail(s)) fail;
     if (!all(pixels-stokes[4] < 0.0001)) {
        return its.stop('Stokes I values are wrong');
     }
     if (is_fail(s.done())) fail;
#
     ss := "i q u v";
     for (i in 1:4) {
        s := p.stokes(ss[i]);
        if (is_fail(s)) fail;
        if (!all(pixels-stokes[i] < 0.0001)) {
           msg := spaste('Stokes', ss[i], ' values are wrong');
           return its.stop(msg);
        }
        if (is_fail(s.done())) fail;
     }
     s := p.stokes('fish');
     if (!is_fail(s)) {
        return its.stop('Function stokes unexpectedly did not fail');
     }        
#
     if (is_fail(p.done())) fail;
#
     return its.cleanup(testdir);
   }


###
   const its.tests.test3 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 3 - linpolint, linpolposang, totpolint');
#
      const testdir := 'imagepoltest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make some data
#
      shape := [256,256,4];
      stokes := [14,2,3,4];
      data := its.make_data(shape, stokes);
      sigma := 0.01 * as_float(stokes[2]);
      ok := its.addnoise(data, sigma);
      if (is_fail(ok)) fail;
#
# Make image - RA/DEC/IQUV
#
     imname := paste(testdir,'/','imagefromarray.image',sep='')
     myim := imagefromarray(imname, data);
     if (is_fail(myim)) fail;
     if (is_fail(myim.done())) fail;
#
# Make polarimetry server
#
     p := imagepol(imname);
     if (is_fail(p)) fail;
#
# Linearly polarized intensity
#
     pp := sqrt(stokes[2]^2 + stokes[3]^2 + sigma^2);
     s := p.linpolint(debias=F);
     if (is_fail(s)) fail;
     pixels := s.getchunk();
     d := abs(mean(pixels)-pp) / pp;
     if (d > 0.01) {
        return its.stop('Linearly polarized intensity values are wrong');
     }
     if (is_fail(s.done())) fail;
#
     pp := sqrt(stokes[2]^2 + stokes[3]^2 - sigma^2);
     s := p.linpolint(debias=T, clip=10.0);
     if (is_fail(s)) fail;
     pixels := s.getchunk();
     d := abs(mean(pixels)-pp) / pp;
     if (d > 0.01) {
        return its.stop('Debiased linearly polarized intensity values (1) are wrong');
     }
     if (is_fail(s.done())) fail;
#
     s := p.linpolint(debias=T, clip=10.0, sigma=sigma);
     if (is_fail(s)) fail;
     pixels := s.getchunk();
     d := abs(mean(pixels)-pp) / pp;
     if (d > 0.01) {
        return its.stop('Debiased linearly polarized intensity values (2) are wrong');
     }
     if (is_fail(s.done())) fail;
#
# Linearly polarized position angle
# No atan2 in Glish
#     pp := 180.0 / 2 * atan2(stokes[3], stokes[2]) / pi;
#
     pp := 28.15497;
     s := p.linpolposang();
     if (is_fail(s)) fail;
     pixels := s.getchunk();
     d := abs(mean(pixels)-pp) / pp;
     if (d > 0.01) {
        return its.stop('Linearly polarized position angles are wrong');
     }
     if (is_fail(s.done())) fail;
#
#
# Total polarized intensity
#
     pp := sqrt(stokes[2]^2 + stokes[3]^2 + stokes[4]^2 + sigma^2);
     s := p.totpolint(debias=F);
     if (is_fail(s)) fail;
     pixels := s.getchunk();
     d := abs(mean(pixels)-pp) / pp;
     if (d > 0.01) {
        return its.stop('Total polarized intensity values are wrong');
     }
     if (is_fail(s.done())) fail;
#
     pp := sqrt(stokes[2]^2 + stokes[3]^2 + stokes[4]^2 - sigma^2);
     s := p.totpolint(debias=T, clip=10.0);
     if (is_fail(s)) fail;
     pixels := s.getchunk();
     d := abs(mean(pixels)-pp) / pp;
     if (d > 0.01) {
        return its.stop('Debiased total polarized intensity values (1) are wrong');
     }
     if (is_fail(s.done())) fail;
#
     s := p.totpolint(debias=T, clip=10.0, sigma=sigma);
     if (is_fail(s)) fail;
     pixels := s.getchunk();
     d := abs(mean(pixels)-pp) / pp;
     if (d > 0.01) {
        return its.stop('Debiased total polarized intensity values (2) are wrong');
     }
     if (is_fail(s.done())) fail;
#
     if (is_fail(p.done())) fail;
#
     return its.cleanup(testdir);
   }


###
   const its.tests.test4 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 4 - fraclinpol, fractotpol');
#
      const testdir := 'imagepoltest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make some data
#
      shape := [256,256,4];
      stokes := [14,2,3,4];
      data := its.make_data(shape, stokes);
      sigma := 0.01 * as_float(stokes[2]);
      its.addnoise(data, sigma);
#
      if (is_fail(data)) fail;
#
# Make image - RA/DEC/IQUV
#
     imname := paste(testdir,'/','imagefromarray.image',sep='')
     myim := imagefromarray(imname, data);
     if (is_fail(myim)) fail;
     if (is_fail(myim.done())) fail;
#
# Make polarimetry server
#
     p := imagepol(imname);
     if (is_fail(p)) fail;
#
# Fractional linear polarization
#
     pp := sqrt(stokes[2]^2 + stokes[3]^2 + sigma^2) / stokes[1];
     s := p.fraclinpol(debias=F);
     if (is_fail(s)) fail;
     pixels := s.getchunk();
     d := abs(mean(pixels)-pp) / pp;
     if (d > 0.01) {
        return its.stop('Fractional linear polarization values are wrong');
     }
     if (is_fail(s.done())) fail;
#
     pp := sqrt(stokes[2]^2 + stokes[3]^2 - sigma^2) / stokes[1];
     s := p.fraclinpol(debias=T, clip=10.0);
     if (is_fail(s)) fail;
     pixels := s.getchunk();
     d := abs(mean(pixels)-pp) / pp;
     if (d > 0.01) {
        return its.stop('Debiased fractional linear polarization values (1) are wrong');
     }
     if (is_fail(s.done())) fail;
#
     s := p.fraclinpol(debias=T, clip=10.0, sigma=sigma);
     if (is_fail(s)) fail;
     pixels := s.getchunk();
     d := abs(mean(pixels)-pp) / pp;
     if (d > 0.01) {
        return its.stop('Debiased fractional linear polarization values (2) are wrong');
     }
     if (is_fail(s.done())) fail;
#
# Fractional total polarization
#
     pp := sqrt(stokes[2]^2 + stokes[3]^2 + stokes[4]^2 + sigma^2) / stokes[1];
     s := p.fractotpol(debias=F);
     if (is_fail(s)) fail;
     pixels := s.getchunk();
     d := abs(mean(pixels)-pp) / pp;
     if (d > 0.01) {
        return its.stop('Fractional total polarization values are wrong');
     }
     if (is_fail(s.done())) fail;
#
     pp := sqrt(stokes[2]^2 + stokes[3]^2 + stokes[4]^2 - sigma^2) / stokes[1];
     s := p.fractotpol(debias=T, clip=10.0);
     if (is_fail(s)) fail;
     pixels := s.getchunk();
     d := abs(mean(pixels)-pp) / pp;
     if (d > 0.01) {
        return its.stop('Debiased fractional total polarization values (1) are wrong');
     }
     if (is_fail(s.done())) fail;
#
     s := p.fractotpol(debias=T, clip=10.0, sigma=sigma);
     if (is_fail(s)) fail;
     pixels := s.getchunk();
     d := abs(mean(pixels)-pp) / pp;
     if (d > 0.01) {
        return its.stop('Debiased fractional total polarization values (2) are wrong');
     }
     if (is_fail(s.done())) fail;
#
     if (is_fail(p.done())) fail;
#
     return its.cleanup(testdir);
   }


###
   const its.tests.test5 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 5 - pol');
#
      const testdir := 'imagepoltest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make some data
#
      shape := [256,256,4];
      stokes := [14,2,3,4];
      data := its.make_data(shape, stokes);
      sigma := 0.01 * as_float(stokes[2]);
      its.addnoise(data, sigma);
#
      if (is_fail(data)) fail;
#
# Make image - RA/DEC/IQUV
#
     imname := paste(testdir,'/','imagefromarray.image',sep='')
     myim := imagefromarray(imname, data);
     if (is_fail(myim)) fail;
     if (is_fail(myim.done())) fail;
#
# Make polarimetry server
#
     p := imagepol(imname);
     if (is_fail(p)) fail;
#
# We just test that each function runs, not its results, as this
# just packages previously tested functions
#
     which := "lpi tpi lppa flp ftp";
     for (i in which) {
        s := p.pol(i, debias=F);
        if (is_fail(s)) fail;
        if (is_fail(s.done())) fail;
#
        s := p.pol(i, debias=T, clip=10.0);
        if (is_fail(s)) fail;
        if (is_fail(s.done())) fail;
#
        s := p.pol(i, debias=T, clip=10.0, sigma=sigma);
        if (is_fail(s)) fail;
        if (is_fail(s.done())) fail;
     }
     s := p.pol('fish');
     if (!is_fail(s)) {
        return its.stop('Function pol unexpectedly did not fail');
     }        
#
     if (is_fail(p.done())) fail;
     return its.cleanup(testdir);
   }


###
   const its.tests.test6 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 6 - sigmalinpolint, sigmalinpolposang, sigmatotpolint');
#
      const testdir := 'imagepoltest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make some data
#
      shape := [256,256,4];
      stokes := [14,2,3,4];
      data := its.make_data(shape, stokes);
      sigma := 0.01 * as_float(stokes[2]);
      its.addnoise(data, sigma);
#
      if (is_fail(data)) fail;
#
# Make image - RA/DEC/IQUV
#
     imname := paste(testdir,'/','imagefromarray.image',sep='')
     myim := imagefromarray(imname, data);
     if (is_fail(myim)) fail;
     if (is_fail(myim.done())) fail;
#
# Make polarimetry server
#
     p := imagepol(imname);
     if (is_fail(p)) fail;
#
# Error in linearly polarized intensity
#
     s := p.sigmalinpolint(clip=10.0);
     if (is_fail(s)) fail;
     d := abs(s-sigma)/sigma;
     if (d>0.01) {
        return its.stop('Sigma for linearly polarized intensity (1) is wrong');
     }
#
     s := p.sigmalinpolint(clip=10.0, sigma=sigma);
     if (is_fail(s)) fail;
     d := abs(s-sigma)/sigma;
     if (d > 0.01) {
        return its.stop('Sigma for linearly polarized intensity (2) is wrong');
     }
#
# Error in linearly polarized position angle
#
     s := p.sigmalinpolposang(clip=10.0);
     if (is_fail(s)) fail;
     data := s.getchunk();
     if (is_fail(s.done())) fail;
     lpi := sqrt(stokes[2]^2 + stokes[3]^2);
     s2 := 180.0 * sigma / lpi / 2.0 / pi;
     if (! (abs((mean(data)-s2)/s2) < 0.01)) {
        return its.stop('Sigma for linearly polarized position angle (1) is wrong');
     }
#
     s := p.sigmalinpolposang(clip=10.0, sigma=sigma);
     if (is_fail(s)) fail;
     data := s.getchunk();
     if (is_fail(s.done())) fail;
     lpi := sqrt(stokes[2]^2 + stokes[3]^2);
     s2 := 180.0 * sigma / lpi / 2.0 / pi;
     d := abs(mean(data)-s2)/s2;
     if (d > 0.01) {
        return its.stop('Sigma for linearly polarized position angle (2) is wrong');
     }
#
# Error in total linearly polarized intensity
#
     s := p.sigmatotpolint(clip=10.0);
     if (is_fail(s)) fail;
     d := abs(s-sigma)/sigma;
     if (d > 0.01) {
        return its.stop('Sigma for total polarized intensity (1) is wrong');
     }
#
     s := p.sigmatotpolint(clip=10.0, sigma=sigma);
     if (is_fail(s)) fail;
     d := abs(s-sigma)/sigma;
     if (d > 0.01) {
        return its.stop('Sigma for total polarized intensity (2) is wrong');
     }
#
# Cleanup
#
     if (is_fail(p.done())) fail;
     return its.cleanup(testdir);
   }


###
   const its.tests.test7 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 7 - sigma, sigmastokesi, sigmastokesq, sigmastokesu, sigmastokesv, sigmastokes');
#
      const testdir := 'imagepoltest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make some data
#
      shape := [256,256,4];
      stokes := [14,2,3,4];
      data := its.make_data(shape, stokes);
      sigma := 0.01 * as_float(stokes[2]);
      its.addnoise(data, sigma);
#
      if (is_fail(data)) fail;
#
# Make image - RA/DEC/IQUV
#
     imname := paste(testdir,'/','imagefromarray.image',sep='')
     myim := imagefromarray(imname, data);
     if (is_fail(myim)) fail;
     if (is_fail(myim.done())) fail;
#
# Make polarimetry server
#
     p := imagepol(imname);
     if (is_fail(p)) fail;
#
# Best guess at thermal noise
#
     s := p.sigma(clip=100.0);
     if (is_fail(s)) fail;
     d := abs(s-sigma)/sigma;
     if (d > 0.01) {
        return its.stop('Sigma is wrong');
     }
#
# Error in stokes I, Q, U, V
#
     s := p.sigmastokesi(clip=100.0);
     if (is_fail(s)) fail;
     d := abs(s-sigma)/sigma;
     if (d > 0.01) {
        return its.stop('Sigma for Stokes I is wrong');
     }
#
     s := p.sigmastokesq(clip=100.0);
     if (is_fail(s)) fail;
     if (! (abs(s-sigma) < 0.001)) {
        return its.stop('Sigma for Stokes Q is wrong');
     }
#
     s := p.sigmastokesu(clip=100.0);
     if (is_fail(s)) fail;
     d := abs(s-sigma)/sigma;
     if (d > 0.01) {
        return its.stop('Sigma for Stokes U is wrong');
     }
     s := p.sigmastokesv(clip=100.0);
     if (is_fail(s)) fail;
     d := abs(s-sigma)/sigma;
     if (d > 0.01) {
        return its.stop('Sigma for Stokes V is wrong');
     }
#
     which := "I Q U V";
     for (i in which) {
        s := p.sigmastokes(which=i, clip=100.0);
        if (is_fail(s)) fail;
     }
     s := p.sigmastokes(which='fish');
     if (!is_fail(s)) {
        return its.stop('Function sigmastokes unexpectedly did not fail');
     }        
#
# Cleanup
#
     if (is_fail(p.done())) fail;
     return its.cleanup(testdir);
   }


###
   const its.tests.test8 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 8 - sigmafraclinpol, sigmafractotpol');
#
      const testdir := 'imagepoltest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make some data
#
      shape := [256,256,4];
      stokes := [14,2,3,4];
      data := its.make_data(shape, stokes);
      sigma := 0.01 * as_float(stokes[2]);
      its.addnoise(data, sigma);
#
      if (is_fail(data)) fail;
#
# Make image - RA/DEC/IQUV
#
     imname := paste(testdir,'/','imagefromarray.image',sep='')
     myim := imagefromarray(imname, data);
     if (is_fail(myim)) fail;
     if (is_fail(myim.done())) fail;
#
# Make polarimetry server
#
     p := imagepol(imname);
     if (is_fail(p)) fail;
#
# Error in fractional linearly polarized intensity
#
     s := p.sigmafraclinpol(clip=10.0);
     if (is_fail(s)) fail;
     data := s.getchunk();
     if (is_fail(s.done())) fail;
     pi := sqrt(stokes[2]^2 + stokes[3]^2);
     m := pi / stokes[1];
     s2 := m * sqrt( (sigma/pi)^2 + (sigma/stokes[1])^2);
     d := abs(mean(data)-s2)/s2;
     if (d > 0.01) {
        return its.stop('Sigma for fractional linear polarization (1) is wrong');
     }
#
     s := p.sigmafraclinpol(clip=10.0, sigma=sigma);
     if (is_fail(s)) fail;
     data := s.getchunk();
     if (is_fail(s.done())) fail;
     pi := sqrt(stokes[2]^2 + stokes[3]^2);
     m := pi / stokes[1];
     s2 := m * sqrt( (sigma/pi)^2 + (sigma/stokes[1])^2);
     d := abs(mean(data)-s2)/s2;
     if (d > 0.01) {
        return its.stop('Sigma for fractional linear polarization (2) is wrong');
     }
#
# Error in fractional total polarized intensity
#
     s := p.sigmafractotpol(clip=10.0);
     if (is_fail(s)) fail;
     data := s.getchunk();
     if (is_fail(s.done())) fail;
     pi := sqrt(stokes[2]^2 + stokes[3]^2 + stokes[4]^2);
     m := pi / stokes[1];
     s2 := m * sqrt( (sigma/pi)^2 + (sigma/stokes[1])^2);
     d := abs(mean(data)-s2)/s2;
     if (d > 0.01) {
        return its.stop('Sigma for fractional total polarization (1) is wrong');
     }
#
     s := p.sigmafractotpol(clip=10.0, sigma=sigma);
     if (is_fail(s)) fail;
     data := s.getchunk();
     if (is_fail(s.done())) fail;
     pi := sqrt(stokes[2]^2 + stokes[3]^2 + stokes[4]^2);
     m := pi / stokes[1];
     s2 := m * sqrt( (sigma/pi)^2 + (sigma/stokes[1])^2);
     d := abs(mean(data)-s2)/s2;
     if (d > 0.01) {
        return its.stop('Sigma for fractional total polarization (2) is wrong');
     }
#
# Cleanup
#
     if (is_fail(p.done())) fail;
     return its.cleanup(testdir);
   }

###
   const its.tests.test9 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 9 - imagepoltestimage, rotationmeasure');
#
      const testdir := 'imagepoltest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make polarimetry server
#
     outfile := paste(testdir,'/','imagepoltestimage.image',sep='')
     rm := 200.0;
     pa0 := 10.0;
     sigma := 0.001;
     nf := 32;
     f0 := 1.4e9;
     bw  := 128.0e6;
     p := imagepoltestimage (outfile=outfile, rm=rm, pa0=pa0, sigma=sigma, 
                             nx=32, ny=32, nf=nf, f0=f0, bw=bw);
     if (is_fail(p)) fail;
#
# Rotation Measure
#
     rmmax := rm + 100.0;
     maxpaerr := 100000.0;
     rmfg := 0.0;
     rmname := paste(testdir,'/','rm.image',sep='')
     rmename := paste(testdir,'/','rme.image',sep='')
     pa0name := paste(testdir,'/','pa0.image',sep='')
     pa0ename := paste(testdir,'/','pa0e.image',sep='')
     ok := p.rotationmeasure(rm=rmname, pa0=pa0name,
                             rmerr=rmename, pa0err=pa0ename,
                             sigma=sigma, rmfg=rmfg,
                             rmmax=rmmax, maxpaerr=maxpaerr);
    if (is_fail(ok)) fail;
#
# CHeck results
#
    rmim := image(rmname);
    rmeim := image(rmename);
    pa0im := image(pa0name);
    pa0eim := image(pa0ename);
#
    err := mean(rmeim.getchunk());
    diff := mean(rmim.getchunk()) - rm;
    if (abs(diff) > 3*err) {
       return its.stop('Recovered RM is wrong');
    }
#
    err := mean(pa0eim.getchunk());
    diff := mean(pa0im.getchunk()) - pa0;
    if (abs(diff) > 3*err) {
       return its.stop('Recovered Position Angle at zero frequency is wrong');
    }
#
# Cleanup
#
     if (is_fail(p.done())) fail;
     if (is_fail(rmim.done())) fail;
     if (is_fail(rmeim.done())) fail;
     if (is_fail(pa0im.done())) fail;
     if (is_fail(pa0eim.done())) fail;
#
     return its.cleanup(testdir);
   }



###
   const its.tests.test10 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 10 - fourierrotationmeasure');
#
      const testdir := 'imagepoltest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make polarimetry server
#
     outfile := paste(testdir,'/','imagepoltestimage.image',sep='')
     rm := 1.0e6;
     pa0 := 0.0;
     sigma := 0.0001;
     nf := 512;
     f0 := 1.4e9;
     bw := 15.625e3 * nf;
     p := imagepoltestimage (outfile=outfile, rm=rm, pa0=pa0, sigma=sigma, 
                             nx=1, ny=1, nf=nf, f0=f0, bw=bw);
     if (is_fail(p)) fail;
#
# Rotation Measure
#
     ampname := paste(testdir,'/','amp.image',sep='')
     ok := p.fourierrotationmeasure(amp=ampname);
     if (is_fail(ok)) fail;
#
# Check results
#
    ampim := image(ampname);
    local srec;
    ok := ampim.summary(header=srec,list=F);
    rminc := srec.incr[4];
    rmrefpix := srec.refpix[4];
    idx := as_integer((rm + rminc/2) / rminc + rmrefpix);
    y := ampim.getchunk();
    local loc
    max_with_location(y, loc);
    if (idx != loc) {
       return its.stop('Peak of RM spectrum is in wrong channel');
    }
#
# Cleanup
#
     if (is_fail(p.done())) fail;
     if (is_fail(ampim.done())) fail;
#
     return its.cleanup(testdir);
   }


###
   const its.tests.test11 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 11 - complexlinpol, complexfraclinpol, makecomplex');
#
      const testdir := 'imagepoltest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make some data
#
      shape := [2,2,4];
      stokes := [14,2,3,4];
      data := its.make_data(shape, stokes);
#
# Make image - RA/DEC/IQUV
#
     imname := paste(testdir,'/','imagefromarray.image',sep='')
     myim := imagefromarray(imname, data);
     if (is_fail(myim)) fail;
     if (is_fail(myim.done())) fail;
#
# Make polarimetry server
#
     p := imagepol(imname);
     if (is_fail(p)) fail;
#
# Complex linear polarization
#
     s := paste(testdir,'/','complexpol.image',sep='')
     ok := p.complexlinpol(s)
     if (is_fail(ok)) fail;
#
     expr := spaste('real("', s, '")');
     rim := imagecalc(pixels=expr);
     if (is_fail(rim)) fail;
     qpixels := rim.getchunk();
     if (is_fail(qpixels)) fail;
     if (is_fail(rim.done())) fail;
     d := abs(mean(qpixels)-stokes[2]);
     if (d > 0.001) {
        return its.stop('Complex linear polarization (1) values (Q) are wrong');
     }
#
     expr := spaste('imag("', s, '")');
     iim := imagecalc(pixels=expr);
     if (is_fail(iim)) fail;
     upixels := iim.getchunk();
     if (is_fail(upixels)) fail;
     if (is_fail(iim.done())) fail;
     d := abs(mean(upixels)-stokes[3]);
     if (d > 0.001) {
        return its.stop('Complex linear polarization (1) values (U) are wrong');
     }
#
# Complex fractional polarization
#
     s := paste(testdir,'/','complexfracpol.image',sep='')
     ok := p.complexfraclinpol(s)
     if (is_fail(ok)) fail;
#
     expr := spaste('real("', s, '")');
     rim := imagecalc(pixels=expr);
     if (is_fail(rim)) fail;
     qpixels := rim.getchunk();
     if (is_fail(qpixels)) fail;
     if (is_fail(rim.done())) fail;
     d := abs(mean(qpixels)-(stokes[2]/stokes[1]));
     if (d > 0.001) {
        return its.stop('Complex fractional polarization (1) values (Q) are wrong');
     }
#
     expr := spaste('imag("', s, '")');
     iim := imagecalc(pixels=expr);
     if (is_fail(iim)) fail;
     upixels := iim.getchunk();
     if (is_fail(upixels)) fail;
     if (is_fail(iim.done())) fail;
     d := abs(mean(upixels)-(stokes[3]/stokes[1]));
     if (d > 0.001) {
        return its.stop('Complex fractional polarization (1) values (U) are wrong');
     }
#
# Makecomplex
#
     q := p.stokesq();
     qs := paste(testdir,'/','q.image',sep='')
     q2 := q.subimage(qs);
     if (is_fail(q.done())) fail;
     if (is_fail(q2.done())) fail;
#
     u := p.stokesu();
     us := paste(testdir,'/','u.image',sep='')
     u2 := u.subimage(us);
     if (is_fail(u.done())) fail;
     if (is_fail(u2.done())) fail;
#
     lpi := p.linpolint();
     lpis := paste(testdir,'/','lpi.image',sep='')
     lpi2 := lpi.subimage(lpis);
     if (is_fail(lpi.done())) fail;
     if (is_fail(lpi2.done())) fail;
#
     lppa := p.linpolposang();
     lppas := paste(testdir,'/','lppa.image',sep='')
     lppa2 := lppa.subimage(lppas);
     if (is_fail(lppa.done())) fail;
     if (is_fail(lppa2.done())) fail;
#
     s := paste(testdir,'/','cplx1.image',sep='')
     p.makecomplex(s, real=qs, imag=us)
#
     expr := spaste('real("', s, '")');
     rim := imagecalc(pixels=expr);
     if (is_fail(rim)) fail;
     rpixels := rim.getchunk();
     if (is_fail(rpixels)) fail;
     if (is_fail(rim.done())) fail;
     d := abs(mean(rpixels)-(stokes[2]));
     if (d > 0.001) {
        return its.stop('Complex linear polarization (2) values (Q) are wrong');
     }
#
     expr := spaste('imag("', s, '")');
     iim := imagecalc(pixels=expr);
     if (is_fail(iim)) fail;
     ipixels := iim.getchunk();
     if (is_fail(ipixels)) fail;
     if (is_fail(iim.done())) fail;
     d := abs(mean(ipixels)-(stokes[3]));
     if (d > 0.001) {
        return its.stop('Complex linear polarization (2) values (U) are wrong');
     }
#
     s := paste(testdir,'/','cplx2.image',sep='')
     p.makecomplex(s, amp=lpis, phase=lppas)
#
     expr := spaste('real("', s, '")');
     rim := imagecalc(pixels=expr);
     if (is_fail(rim)) fail;
     rpixels := rim.getchunk();
     if (is_fail(rpixels)) fail;
     if (is_fail(rim.done())) fail;
     d := abs(mean(rpixels)-(stokes[2]));
     if (d > 0.001) {
        return its.stop('Complex linear polarization (3) values (Q) are wrong');
     }
#
     expr := spaste('imag("', s, '")');
     iim := imagecalc(pixels=expr);
     if (is_fail(iim)) fail;
     ipixels := iim.getchunk();
     if (is_fail(ipixels)) fail;
     if (is_fail(iim.done())) fail;
     d := abs(mean(ipixels)-(stokes[3]));
     if (d > 0.001) {
        return its.stop('Complex linear polarization (3) values (U) are wrong');
     }
#
     if (is_fail(p.done())) fail;
     return its.cleanup(testdir);
   }



###
   const its.tests.test12 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 12 - depolratio, sigmadepolratio');
#
      const testdir := 'imagepoltest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make some data
#
      shape := [256,256,4];
#
      stokes1 := [14,2,3,0.2];
      data1 := its.make_data(shape, stokes1);
      sigma1 := 0.01 * as_float(stokes1[2]);
      its.addnoise(data1, sigma1);
      if (is_fail(data1)) fail;
#
      stokes2 := [13,1.5,2.8,0.1];
      data2 := its.make_data(shape, stokes2);
      sigma2 := 0.01 * as_float(stokes2[2]);
      its.addnoise(data2, sigma2);
      if (is_fail(data2)) fail;
#
# Make images - RA/DEC/IQUV
#
     imname1 := paste(testdir,'/','imagefromarray.image1',sep='')
     myim1 := imagefromarray(imname1, data1);
     if (is_fail(myim1)) fail;
     if (is_fail(myim1.done())) fail;
#
     imname2 := paste(testdir,'/','imagefromarray.image2',sep='')
     myim2 := imagefromarray(imname2, data2);
     if (is_fail(myim2)) fail;
     if (is_fail(myim2.done())) fail;
#
# Make polarimetry server
#
     p := imagepol(imname1);
     if (is_fail(p)) fail;
#
# Depolarization ratio 
#
     i1 := stokes1[1];
     i2 := stokes1[1];
     ei1 := sigma1;
     ei2 := sigma2;
#
     p1 := sqrt(stokes1[2]^2 + stokes1[3]^2)
     p2 := sqrt(stokes2[2]^2 + stokes2[3]^2)
     ep1 := sigma1;
     ep2 := sigma2;
#
     m1 := p1 / stokes1[1];
     m2 := p2 / stokes2[1];
     em1 := m1 * sqrt( (ep1*ep1/p1/p1) + (ei1*ei1/i1/i1));
     em2 := m2 * sqrt( (ep2*ep2/p2/p2) + (ei2*ei2/i2/i2));
#
     dd := m1 / m2;
     edd := dd * sqrt( (em1*em1/m1/m1) + (em2*em2/m2/m2) );
#
     depol := p.depolratio(infile=imname2, debias=F);   # Use file name
     if (is_fail(depol)) fail;
     pixels := depol.getchunk();
     diff := abs(mean(pixels)-dd) / dd;
     if (diff > 0.01) {
        return its.stop('Depolarization ratio values are wrong');
     }
     if (is_fail(depol.done())) fail;
#
     myim2 := image(imname2);
     if (is_fail(myim2)) fail;
     depol := p.depolratio(infile=myim2, debias=F);      # Use Image tool
     if (is_fail(depol)) fail;
     pixels := depol.getchunk();
     diff := abs(mean(pixels)-dd) / dd;
     if (diff > 0.01) {
        return its.stop('Depolarization ratio values are wrong');
     }
     if (is_fail(myim2.done())) fail;
     if (is_fail(depol.done())) fail;
#
# Error in depolarization ratio
#
     edepol := p.sigmadepolratio(infile=imname2, debias=F);   # Use file name
     if (is_fail(edepol)) fail;
     pixels := edepol.getchunk();
     diff := abs(mean(pixels)-edd) / edd;
     if (diff > 0.01) {
        return its.stop('Depolarization ratio error values are wrong');
     }
     if (is_fail(edepol.done())) fail;

#
     if (is_fail(p.done())) fail;
     return its.cleanup(testdir);
   }





#####################################################################
#
# Get on with it
#
    note ('', priority='WARN', origin='imagepolservertest.g');
    note ('These tests include forced errors.  If the logger GUI is active ',
          priority='WARN', origin='imagepolservertest.g');
    note ('you should expect to see Red Boxes Of Death (RBOD) with many errors',
          priority='WARN', origin='imagepolservertest.g');
    note ('If the test finally returns T, then it has succeeded\n\n',
          priority='WARN', origin='imagepolservertest.g');
    note ('', priority='WARN', origin='imagepolservertest.g');
#
    fn := field_names(its.tests);
    const ntests := length(fn);
    if (is_unset(which)) which := [1:ntests];
    if (length(which)==1) which := [which];
#
    fn2 := fn[which];
    for (i in fn2) {
       if (has_field(its.tests, i)) {
          if (is_fail(its.tests[i]())) fail;
       }
    }
#
    return T;
}
