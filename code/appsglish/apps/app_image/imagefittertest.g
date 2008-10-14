# imagefittertest.g: test imagefitter.g
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
#   $Id: imagefittertest.g,v 19.3 2004/11/24 00:10:52 nkilleen Exp $
#
include 'imagefitter.g'
include 'note.g'
include 'serverexists.g'
include 'os.g'
include 'quanta.g';

pragma include once



imagefitterservertest := function(which=unset)
{
   if (!serverexists('dos', 'os', dos)) {
      return throw('The os server "dos" is either not running or not valid',
                    origin='imagefittertest.g');
   }
   if (!serverexists('dq', 'quanta', dq)) {
      return throw('The quanta server "dq" is either not running or not valid',
                    origin='imagefittertest.g');
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
       note(...,origin='imagefittertest()');
    }

###
    const its.stop := function(...) 
    { 
	note(paste(...) ,priority='SEVERE', origin='imagefittertest()')
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
          if (is_fail(ok)) {
              return its.stop('Cleanup of ', dir, ' fails!');
           }
       }
       return T;
    }

###
   const its.compareComponentList := function (ref errmsg, cl0, cl1, tol=0.005, dotype=T)
   {
      n0 := cl0.length();
      n1 := cl1.length();
      if (n0 != n1) {
         val errmsg := 'Number of components differ';
         return F;
      }
#
      for (i in 1:n0) {
         f0 := cl0.getfluxvalue(i);
         f1 := cl1.getfluxvalue(i);
         d := abs(f1 - f0);
         t := tol * f0;
         if (!all(d<=t)) {
            val errmsg := 'Component fluxes differ';
            return F;
         }
#
         shp0 := cl0.getshape(i);
         shp1 := cl1.getshape(i);
         type0 := cl0.shapetype(i);
         type1 := cl1.shapetype(i);
         if (dotype && type0!=type1) {
            val errmsg := 'Component types differ';
            return F;
         }
#
         dir0 := cl0.getrefdir(i);
         dir1 := cl1.getrefdir(i);
#
         v0 := dm.getvalue(dir0);
         v1 := dm.getvalue(dir1);
#
         d := abs(dq.convert(v1[1],v0[1].unit).value  - v0[1].value);
         t := tol * abs(v0[1].value);
         if (d > t) {
            val errmsg := 'Longitudes differ';
            return F;
         }
#
         d := abs(dq.convert(v1[2],v0[2].unit).value  - v0[2].value);
         t := tol * abs(v0[2].value);
         if (d > t) {
            val errmsg := 'Latitudes differ';
            return F;
         }
#
         if (dotype && (type0=='Gaussian' || type1=='Disk')) {
            q0 := shp0.majoraxis;
            q1 := shp1.majoraxis;
            d := abs(dq.convert(q1,q0.unit).value  - q0.value);
            t := tol * q0.value;            
            if (d > t) {
               val errmsg := 'Major axes differ';
               return F;
            }
#
            q0 := shp0.minoraxis;
            q1 := shp1.minoraxis;
            d := abs(dq.convert(q1,q0.unit).value  - q0.value);
            t := tol * q0.value;            
            if (d > t) {
               val errmsg := 'Minor axes differ';
               return F;
            }
#
            q0 := shp0.positionangle;
            q1 := shp1.positionangle;
            d := abs(dq.convert(q1,q0.unit).value  - q0.value);
            t := tol * q0.value;            
            if (d > t) {
               val errmsg := 'Position angles differ';
               return F;
            }
         }
      }
#
      return T;
   }


###
   const its.gaussian := function(flux, major, minor, pa, dir=unset)
   {
      cl := emptycomponentlist(log=F);
      cl.simulate(1,log=F);
      cl.setshape(which=1, type='Gaussian', majoraxis=major, 
                  minoraxis=minor, positionangle=pa, log=F);
      flux2 := [flux, 0, 0, 0];
      cl.setflux(which=1, value=flux2, unit='Jy', 
                 polarization='Stokes', log=F);
      if (is_unset(dir)) {
         dir := dm.direction('J2000', dq.quantity(0,'rad'), dq.quantity(0,'rad'));
      }
      values := dm.getvalue(dir);
      cl.setrefdir(which=1, ra=values[1].value, raunit=values[1].unit, 
                   dec=values[2].value, decunit=values[2].unit, log=F);
      return cl;
   }


###

   const its.tests.test1 := function()
   {

# Make the directory

      const testdir := 'imagefittertest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make image 
#
      imname := paste(testdir,'/','imagefromshape.image',sep='')
      imshape := [128,128,1];
      myim := imagefromshape(imname, imshape);
      if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 1 failed');
      }
#
# Add units and restoring beam 
#
      ok := myim.setbrightnessunit('Jy/beam');
      if (is_fail(ok)) fail;
      ok := myim.setrestoringbeam(major='5arcmin', minor='2.5arcmin', pa='60deg', log=F);
      if (is_fail(ok)) fail;
#
# Add model
#
      qmaj := dq.quantity(10, 'arcmin');
      qmin := dq.quantity(5, 'arcmin');
      qpa := dq.quantity(45.0,'deg');
      flux := 100.0;
      cl0 := its.gaussian(flux, qmaj, qmin, qpa);
      if (is_fail(myim.modify(cl0, subtract=F))) fail;
      local stats;
      if (is_fail(myim.stats(statsout=stats, list=F))) fail;
      diff := abs(stats.flux-flux)/flux;
      if (diff > 0.001) {
         return its.stop('model image 1 has wrong values');         
      }
      ok := myim.done();
      if (is_fail(ok)) {
         return its.stop('Done failed (1)');
      }

# Make fitter.  Can't test very much  as it's interactive

      f := imagefitter(imname);
      if (is_fail(f)) {
         return its.stop('Failed to make fitter');
      }

# Test type

      if (f.type() != 'imagefitter') {
         return its.stop('Fitter has wrong type');
      }

# Get regions (none)

      regions := f.regions();
      if (is_fail(regions)) {
         return its.stop('Failed to recover regions');
      }
      if (length(regions) != 0) {
         return its.stop('Number of recovered regions is wrong');
      }

# Get componentlist (none)

      cl := f.componentlist();
      if (is_fail(cl)) {
         return its.stop('Failed to recover componentlist');
      }
      if (length(cl)  != 0) {
         return its.stop('Number of recovered components is wrong');
      }

# Cleanup

      if (is_fail(f.done())) {
         return its.stop('Fitter.done failed');
      }
#
      return its.cleanup(testdir);
   }




#####################################################################
#
# Get on with it
#
    if (!have_gui()) {
       note ('No GUI available', origin='imagefittertest.g');
       return F;
    }
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
             return throw(msg2, origin='imagefittertest.g');
          } else if (!ok) {
             return throw(msg, origin='imagefittertest.g');
          }
       }
    }
#
    return T;
}
