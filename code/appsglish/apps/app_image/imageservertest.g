# imageservertest.g: test image.g
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003,2004
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
#   $Id: imageservertest.g,v 19.16 2004/08/25 01:00:05 cvsmgr Exp $
#
include 'image.g'
include 'note.g'
include 'serverexists.g'
include 'os.g'
include 'regionmanager.g'
include 'measures.g';
include 'quanta.g';

pragma include once


const imageserverdemo := function()
{
   if (!serverexists('dos', 'os', dos)) {
      return throw('The os server "dos" is either not running or not valid',
                    origin='imageserverdemo.g');
   }
   if (!serverexists('dm', 'measures', dm)) {
      return throw('The measures server "dm" is either not running or not valid',
                    origin='imageserverdemo.g');
   }
   if (!serverexists('dq', 'quanta', dq)) {
      return throw('The quanta server "dq" is either not running or not valid',
                    origin='imageserverdemo.g');
   }
#
# Cleanup
#
   dir := 'demoimage_temp';
   if (dos.fileexists(file=dir, follow=T)) {
      ok := dos.remove(pathname=dir, recursive=T, follow=T);
      if (is_fail(ok)) {
         return throw(spaste('Cleanup of ', dir, ' fails!'),
                      origin='imageserverdemo.g');
      }
   }
#
# Make directory
#
    if (is_fail(dos.mkdir(dir))) {
         return throw(spaste('Failed to make directory ', dir),
                      origin='imageserverdemo.g');
    }
#
# Manufacture some data   
#
    nx := 10; ny := 20; nz := 5;
    data := array(0, nx, ny, nz);
    file := spaste(dir, '/demoimage.image');
    im := imagefromarray(file, data);
    note('Created image=', im.name(), origin='imageserverdemo');
    for (i in [1:nz]) {
        slice := im.getchunk(blc=[1,1,i], trc=[nx,ny,i], list=F);
        slice[,,] := i
        ok := im.putchunk(pixels=slice, blc=[1,1,i], list=F);
        if (is_fail(ok)) fail;
        note('Set plane ', i, ' to ', i, origin='imageserverdemo()')
    }
    ok := im.statistics(axes=[1,2],async=F)
    if (is_fail(ok)) fail;
#
    file := spaste(dir, '/DEMOIMAGE.FITS');
    ok := im.tofits(file);
    if (is_fail(ok)) fail;
    im.close();
    note('Created fits file=', file, origin='imageserverdemo');
    return T;
}




imageservertest := function(which=unset, size=[32,32,8])
{
   if (!serverexists('dos', 'os', dos)) {
      return throw('The os server "dos" is either not running or not valid',
                    origin='imageservertest.g');
   }
   if (!serverexists('drm', 'regionmanager', drm)) {
      return throw('The regionmanager server "drm" is either not running or not valid',
                    origin='imageservertest.g');
   }
   if (!serverexists('dq', 'quanta', dq)) {
      return throw('The quanta server "dq" is either not running or not valid',
                    origin='imageservertest.g');
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
       note(...,origin='imageservertest()');
    }

###
    const its.stop := function(...) 
    { 
	note(paste(...) ,priority='SEVERE', origin='imageservertest()')
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
   its.deconvolveTest := function (myim, majIn, minIn, paIn, iTest)
   {
     smaj := spaste (majIn, 'arcsec');
     smin := spaste (minIn, 'arcsec');
     spa  := spaste (paIn, 'deg');
#
     ok := myim.setrestoringbeam(major=smaj, minor=smin, pa=spa, log=F);
     if (is_fail(ok)) fail;
     beam := myim.restoringbeam();
     if (is_fail(beam)) fail;
#
# Very simple test. Align major axis of source with beam.
#
     cl := emptycomponentlist(log=F);
     if (is_fail(cl)) fail;
     cl.simulate(1);
#
     major := dq.quantity(1.5*majIn, 'arcsec');
     minor := dq.quantity(1.5*minIn, 'arcsec');
     pa := dq.quantity(spa);
     cl.setshape(which=1, type='Gaussian', majoraxis=major, 
                 minoraxis=minor, positionangle=pa, log=F);
#
     cs := myim.coordsys();
     refval := cs.referencevalue(type='dir', format='q');
     cl.setrefdir(which=1, ra=refval[1].value, raunit=refval[1].unit,
                  dec=refval[2].value, decunit=refval[2].unit, log=F);
#
     cl2 := myim.deconvolvecomponentlist(cl);
     if (is_fail(cl2)) {
        return its.stop ('deconvolvecomponentlist 1 failed');
     }
     shape := cl2.getshape(1);
#
     majin := major.value;
     minin := minor.value;
     pain := dq.convert(pa,'deg').value;
     majout := shape.majoraxis.value;
     minout := shape.minoraxis.value;
     paout := dq.convert(shape.positionangle,'deg').value;
     bmaj := beam.major.value;
     bmin := beam.minor.value;     
#
     e1 := sqrt(majin*majin - bmaj*bmaj);
     d1 := abs(e1 - majout);
     e2 := sqrt(minin*minin - bmin*bmin);
     d2 := abs(e2 - minout);
#
     t1 := its.zeroToPi (paout);
     t2 := its.zeroToPi (pain);
     d3 := abs(t1-t2);
     if (d1>1e-5 || d2>1e-5 || d3>1e-5) {
        msg := spaste ('deconvolvecomponentlist ', iTest, ' gave wrong results');
        fail msg;
     }
#
     if (is_fail(cl.done())) fail;
     if (is_fail(cl2.done())) fail;
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
   const its.gaussianarray := function (nx, ny, height, major, minor, pa)
   {
      pa := 0;
      x := array(0.0,nx,ny);
      xc := ((nx - 1)/2) + 1;
      yc := ((ny - 1)/2) + 1;
      centre := [xc, yc];
      fwhm := [major, minor];
#
      for (j in 1:ny) {
         for (i in 1:nx) {
            x[i,j] := its.gaussianfunctional(i, j, 1.0, centre, fwhm, pa);
         }
      }
      return x;
   }


###
   const its.gaussianfunctional := function (x, y, height, center, fwhm, pa)
   {
      x -:= center[1];
      y -:= center[2];
#
      pa -:= pi/2;
      cpa := cos(pa);
      spa := sin(pa);
      if (cpa != 1) {
	tmp := x;
	x :=  cpa*tmp + spa*y;
	y := -spa*tmp + cpa*y;
      }
#
      width := fwhm / sqrt(ln(16));
      if (width[1] != 1) x /:= width[1];
      if (width[2] != 1) y /:= width[2];
#   
      x *:= x;
      y *:= y;
#
      return height * exp(-(x+y));
   }


###
   const its.doneAllImageTypes := function (rec)
   {
      names := field_names(rec);
      for (type in names) {
        ok := rec[type].tool.done();
        if (is_fail(ok)) fail;
      }
      return T;
   }


###
   const its.makeAllImageTypes := function (imshape=[10,10], root, data=unset,
                                            includereadonly=T)
   {
      rec := [=];

# PagedImage

      imname := spaste(root, '1');
      rec.pi := [=]
      if (is_unset(data)) {
         rec.pi.tool := imagefromshape(imname, shape=imshape);    
      } else {
         rec.pi.tool := imagefromarray(imname, pixels=data);
      }
      if (is_fail(rec.pi.tool)) fail;
      rec.pi.type := 'PagedImage';

# FITSImage

      if (includereadonly) {
        fitsname := spaste(imname, '.fits');
        ok := rec['pi'].tool.tofits(fitsname);
        if (is_fail(ok)) fail;
        rec.fi := [=];
        rec.fi.tool := image(fitsname);
        if (is_fail(rec.fi.tool)) fail;
        rec.fi.type := 'FITSImage';
      }

# Virtual: SubImage (make it from another PagedImage so there
# are no locking problems)

      local t;
      if (includereadonly) {
        imname := spaste(root, '2');
        if (is_unset(data)) {
           t := imagefromshape(imname, shape=imshape);
        } else {
           t := imagefromarray(imname, pixels=data);
        }
        if (is_fail(t)) fail;
        if (is_fail(t.done())) fail;
        rec.si := [=];
        rec.si.tool := imagefromimage(infile=imname);   
        if (is_fail(rec.si.tool)) fail;
        rec.si.type := 'SubImage';
     }


# Virtual: TempImage 

      rec.ti := [=];
      if (is_unset(data)) {
         rec.ti.tool := imagefromshape(shape=imshape);
      } else {
         rec.ti.tool := imagefromarray(pixels=data);
      }
      if (is_fail(rec.ti.tool)) fail;
      rec.ti.type := 'TempImage';

# Virtual: ImageExpr (make it from another PagedImage so there
# are no locking problems)

      if (includereadonly) {
        imname := spaste(root, '3');
        if (is_unset(data)) {
           t := imagefromshape(imname, shape=imshape);
        } else {
           t := imagefromarray(imname, pixels=data);
        }
        if (is_fail(t)) fail;
        if (is_fail(t.done())) fail;
        expr := spaste('"', imname, '"');
        rec.ie := [=];
        rec.ie.tool := imagecalc(pixels=expr);
        if (is_fail(rec.ie.tool)) fail;
        rec.ie.type := 'ImageExpr';
      }

# Virtual: ImageConcat (make it from another PagedImage so there
# are no locking problems)

      if (includereadonly) {
        imname1 := spaste(root, '4');
        if (is_unset(data)) {
           t := imagefromshape(imname1, shape=imshape);
        } else {
           t := imagefromarray(imname1, pixels=data);
        }
        if (is_fail(t)) fail;
        if (is_fail(t.done())) fail;
#
        imname2 := spaste(root, '5');
        if (is_unset(data)) {
           t := imagefromshape(imname2, shape=imshape);
        } else {
           t := imagefromarray(imname2, pixels=data)
        }
        if (is_fail(t)) fail;
        if (is_fail(t.done())) fail;
#
        files := [imname1, imname2];
        rec.ic := [=];
        rec.ic.tool := imageconcat(infiles=files, axis=1, relax=T, tempclose=F);
        if (is_fail(rec.ic.tool)) fail;
        rec.ic.type := 'ImageConcat';
      }
#
      return rec;
   }


###
    const its.make_data := function(imshape)
#
# 3D only
#
    {
       data := array(0, imshape[1], imshape[2], imshape[3])
       for (i in 1:(imshape[1])) {
           for (j in 1:(imshape[2])) {
   	    data[i,j,] := 1:imshape[3] + j*imshape[1] + i
          }
       }
       return data;
    }

###
   const its.pick := function (imshape, data, inc)
#
# 3D only
#
   {
      idxx := seq(1,imshape[1],inc[1]);
      idxy := seq(1,imshape[2],inc[2]);
      idxz := seq(1,imshape[3],inc[3]);
      data2 := array(0,length(idxx),length(idxy),length(idxz));
      kk := 1;
      for (k in idxz) {
         jj := 1;
         for (j in idxy) {
            ii := 1;
            for (i in idxx) {
               data2[ii,jj,kk] := data[i, j, k];
               ii +:= 1;
            }
            jj +:= 1;
         }
         kk +:= 1;
      }
      return data2;
   }

###
   const its.fitsreflect := function (imagefile, fitsfile, do16=F)
#
# imagefile can be file name or image object
# 
   {
      myim := imagefile;
      opened := F;
      if (!is_image(imagefile)) {
         myim := image(imagefile);
         if (is_fail(myim)) {
            return its.stop('fitsreflect: image constructor failed');
         }
         opened := T;
      }
      mi := myim.miscinfo();
      mi.hello := 'hello';
      mi.world := 'world';      
      ok := myim.setmiscinfo(mi);
      if (is_fail(ok)) {
         return throw('setmiscinfo failed', origin='fitsreflect');
      }
      myim.sethistory("A B C D");
      history := myim.history(F,F);
#
      local m1, p1;
      ok := myim.getregion(p1, m1);
      if (is_fail(ok)) {
        return throw('getregion 1 failed', origin='fitsreflect');
      }
      imshape := myim.shape();
      m0 := m1;
      m1[1,1,1] := F;
      m1[imshape[1]-1,imshape[2]-1,imshape[3]-1] := F;
      ok := myim.putregion(pixelmask=m1);
      if (is_fail(ok)) {
        return throw('putregion 1 failed', origin='fitsreflect');
      }
#
      bitpix := -32;
      if (do16) bitpix := 16;
      ok := myim.tofits(outfile=fitsfile, bitpix=bitpix);
      if (is_fail(ok)) {
        return throw('tofits failed', origin='fitsreflect');
      }
#
      testdir := dos.dirname(fitsfile);
      imname2 := paste(testdir,'/','fitsreflect.image',sep='')
      myim2 := imagefromfits(outfile=imname2, infile=fitsfile);
      if (is_fail(ok)) {
        return throw('imagefromfits failed', origin='fitsreflect');
      }
      ok := myim.getregion(p1, m1);
      if (is_fail(ok)) {
        return throw('getregion 2 failed', origin='fitsreflect');
      }
      local m2,p2;
      ok := myim2.getregion(p2, m2);
      if (is_fail(ok)) {
        return its.stop('fitsreflect: getregion 3 failed');
      }
#
      if (!all(m2==m1)) {
         return throw('Some mask values have changed in FITS reflection', origin='fitsreflect');
      }
#
      d := p2-p1;
      d := d[m1==T];
      if (! all((abs(d) < 0.0001))) {
         return throw('Some values have changed in FITS reflection', origin='fitsreflect');
      }
      ok := myim.putregion(pixelmask=m0);
      if (is_fail(ok)) {
        return throw('putregion 2 failed', origin='fitsreflect');
      }
#
      mi := myim2.miscinfo();
      if (mi.hello != 'hello' || mi.world != 'world') {
	return throw('miscinfo changed after fits', origin='fitsreflect');
      }
#
      history2 := myim2.history(F,F);
      if (!all(history==history2)) {
	return throw('history changed after fits', origin='fitsreflect');
      }
#
      ok := myim2.done();
      if (is_fail(ok)) {
         return throw('done 1 failed', origin='fitsreflect');
      }
      if (opened) {
         ok := myim.done();
         if (is_fail(ok)) {
            return throw('done 2 failed', origin='fitsreflect');
         }
      }
#
      ok := dos.remove(pathname=fitsfile, recursive=T, follow=T);
      if (is_fail(ok)) {
         return throw('fits file deletion failed', origin='fitsreflect');
      }
      ok := dos.remove(pathname=imname2, recursive=T, follow=T);
      if (is_fail(ok)) {
         return throw('image file deletion failed', origin='fitsreflect');
      }
      return T;
   }


###
   const its.coordcheck := function (im1, axes, testdir)
   {
      local rec1, rec2;
      ok := im1.summary(rec1, list=F);
      if (is_fail(ok)) {
         return throw('summary 1 failed', origin='coordcheck');
      }
      imname := paste(testdir,'/','coordcheck.image',sep='');      
      cs2 := im1.coordsys(axes);
      if (is_fail(cs2)) {
         return throw('coordsys 1 failed', origin='coordcheck');
      }
      shape2 := im1.shape()[axes];
      im2 := imagefromshape(imname, shape2, cs2);
      if (is_fail(im2)) {
         return throw('imagefromshape 1 failed', origin='coordcheck');      
      }
      ok := im2.summary(rec2, list=F);
      if (is_fail(ok)) {
         return throw('summary 2 failed', origin='coordcheck');
      }
#
      if (has_field(rec1, 'axisnames')  && has_field(rec2, 'axisnames')) {
         if (!all(rec1.axisnames[axes]==rec2.axisnames)) return F;
      } else {
         return F;
      }
#
      if (has_field(rec1, 'refpix')  && has_field(rec2, 'refpix')) {
         if (!all(rec1.refpix[axes]==rec2.refpix)) return F;
      } else {
         return F;
      }
#
      if (has_field(rec1, 'refval')  && has_field(rec2, 'refval')) {
         if (!all(rec1.refval[axes]==rec2.refval)) return F;
      } else {
         return F;
      }
#
      if (has_field(rec1, 'incr')  && has_field(rec2, 'incr')) {
         if (!all(rec1.incr[axes]==rec2.incr)) return F;
      } else {
         return F;
      }
#
      if (has_field(rec1, 'axisunits')  && has_field(rec2, 'axisunits')) {
         if (!all(rec1.axisunits[axes]==rec2.axisunits)) return F;
      } else {
         return F;
      }
      if (is_fail(im2.delete(done=T))) fail;
      if (is_fail(cs2.done())) fail;
      return T;
   }


###
   its.zeroToPi := function (x)
   {
      n := as_integer(x / 180.0);
      rem := x - n*180.0;
#
      if (rem < 0) rem +:= 180.0;
      return rem;
   }


###
   const its.tests.test1 := function(imshape)
#
# Test everything a bit
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 1 - general');
#
    const testdir := 'imagetest_temp'
    if (!its.cleanup(testdir)) return F;

# Make the directory

    if (is_fail(dos.mkdir(testdir))) {
       return its.stop('mkdir', testdir, 'fails!');
    }
#
# Make some data
#
    its.info('Manufacturing data cube shaped ', imshape)
    data := its.make_data(imshape);
    its.info('z = 1:',imshape[3],' + y * ', imshape[1], ' + x')
    const manname := paste(testdir,'/','manufactured.im',sep='')
    its.info('Turning glish array into image named ', manname)
    man := imagefromarray(manname, data)
    if (is_fail(man)) {
	return its.stop('imagefromarray constructor 1 fails')
    }
#   
    its.info('Trying close');
    ok := man.close();
    if (is_fail(ok)) {
       return its.stop('Close failed');
    }
    its.info('');
#
    its.info('Trying open')
    ok := man.open(manname) 
    if (is_fail(ok)) {
       return its.stop('Open failed');
    }
    its.info('');
#
    its.info('Trying rename');
    manname2 := paste(testdir,'/','manufactured.im_rename',sep='')
    ok := man.rename(manname2);
    if (is_fail(ok)) {
       return its.stop('Rename of', manname, ' to ', manname2, 'fails');
    }
    its.info('');
#
    its.info('Trying delete');
    ok := man.delete(done=T);
    if (is_fail(ok)) {
       return its.stop('Delete of ', mannam2, 'fails');
    }
    its.info('');
#
    its.info('Remake the image');
    man := imagefromarray(manname, data)
    if (is_fail(man)) {
	return its.stop('imagefromarray constructor fails');
    }
    ok := man.done();
    if (is_fail(ok)) {
       return its.stop('Done 1 fails')
    }
#
    its.info('Trying image(...)');
    man := image(manname);
    if (is_fail(man)) {
       return its.stop('image constructor 1 failed');
    }
    its.info('');

    # verify the shape
    its.info('Verifying shape');
    if (!all(man.shape() == imshape)) {
	return its.stop('Shape of image is wrong:', as_string(man.shape()))
    }
    its.info('');

    # verify the name
    its.info('Verifying name'); 
    fullname := dos.fullname(manname);
    if (man.name(strippath=F) != fullname) {
	return its.stop('The name is wrong: ', man.name())
    }
    its.info('');

    # verify bounding box of default region
    its.info('Verifying default bounding box'); 
    local start, end;
    const myrm := regionmanager();
    bb := man.boundingbox(myrm.box());
    actualStart := man.shape(); actualStart := 1;
    actualEnd := man.shape();
    if (bb.blc!=actualStart || bb.trc!=actualEnd) {
       msg := spaste('The default bounding box ', bb.blc, bb.trc,
                     ' is wrong');
       return its.stop(msg);
    }
    its.info('');

    # Summarise the image
    its.info('Summarize image'); 
    local header
    ok := man.summary(header)
    its.info('');

    # Do statistics
    its.info('Find statistics');
    local stuff;
    ok := man.statistics(stuff);
    if (is_fail(ok)) fail;
    its.info('');

    # Do histograms
    its.info('Find histograms');
    ok := man.histograms(stuff);
    if (is_fail(ok)) fail;
    its.info('');

    # Find coordinates
    its.info('Verify coordinates');
    refPix := header.refpix;
    world := man.toworld(refPix, 'n')
    pixel := man.topixel(world)
    if (refPix != pixel) {
	return its.stop('Coordinate reflection failed');
    }
    its.info('');

    # Fish out coordinates as measures
    its.info('Get coordinates as measures');
    rec := man.coordmeasures(pixel)
    its.info('');

    # Fish out CoordinateSYStem
    its.info('Get CoordinateSystem');
    cs := man.coordsys();
    if (is_fail(cs)) {
       return its.stop('Coordinate recovery failed');
    }       
    ok := cs.done();
    if (is_fail(ok)) fail;

    # Get/put region (mask is T at present)
    its.info('Verify get/putregion');
    trc := imshape;
    trc[3] := 1;
    r := myrm.box([1,1,1], trc);
    local pixels, pixels2, pixels3, mask, mask2, mask3;
    ok := man.getregion(pixels=pixels, pixelmask=mask, region=r, list=F, dropdeg=F);
    if (is_fail(ok)) {
       return its.stop('getregion 1 failed');
    }       
    pixels2 := pixels;  
    mask2 := mask;
    pixels2[1,1,1] := -10;
    pixels2[imshape[1],imshape[2],1] := -10;
    ok := man.putregion(pixels=pixels2, pixelmask=mask2, region=r);
    if (is_fail(ok)) {
       return its.stop('putregion 1 failed');
    }       
    ok := man.getregion(pixels=pixels3, pixelmask=mask3, region=r, dropdeg=F);
    if (is_fail(ok)) {
       return its.stop('getregion 2 failed');
    }       
    if (pixels3 != pixels2 || mask3 != mask2) {
       return its.stop ('get/putregion reflection failed');
    }
    ok := man.putregion(pixels=pixels, pixelmask=mask, region=r);
    if (is_fail(ok)) {
       return its.stop('putregion 2 failed');
    }       
    its.info('');

    # Subimage
    its.info('Subimage');
    trc := imshape;
    trc[3] := 1;
    r := myrm.box([1,1,1], trc);
    local pixels, pixels2, mask, mask2;
    ok := man.getregion(pixels=pixels, pixelmask=mask, region=r, dropdeg=F);
    if (is_fail(ok)) {
       return its.stop('getregion 3 failed');
    }       
    if (is_fail(man)) fail;
    man3 := man.subimage(region=r)
    if (is_fail(man3)) {
       return its.stop('subimage 1 failed');
    }
    ok := man3.getregion(pixels=pixels2, pixelmask=mask2, region=drm.box(), dropdeg=F);
    if (is_fail(ok)) {
       return its.stop('getregion 4 failed');
    }       
    if (pixels!=pixels2 || mask!=mask2) {
       return its.stop('SubImage got wrong results');
    }
    ok := man3.done();
    if (is_fail(ok)) {
       return its.stop('Done 2 fails')
    }

    # Do moments
    its.info('Find moments');
    ok := man.moments(axis=3);
    if (is_fail(ok)) fail;
    ok.done();
    its.info('');

    # Do Hanning
    its.info('Hanning smooth');
    man3 := man.hanning(axis=3, drop=F);
    if (is_fail(man3)) {
       return its.stop('Hanning fails')
    }
    ok := man3.done();
    if (is_fail(ok)) {
       return its.stop('Done 3 fails')
    }
    its.info('');

    # Do insert
    its.info('Insert');
    padshape := imshape + [2,2,2];
    man3 := imagefromshape(shape=padshape);
    ok := man3.insert(infile=man.name(F), locate=[3,3,3])
    if (is_fail(ok)) {
       return its.stop('insert 1 fails')
    }
    ok := man3.done();
    if (is_fail(ok)) {
       return its.stop('Done 4 fails')
    }
    its.info('');

    
    # Read the data in various directions
    its.info('Starting read/compare tests....')
    its.info('XY plane by XY plane')
    t := time()
    for (i in 1:imshape[3]) {
	data2 := man.getchunk(blc=[1,1,i], 
                              trc=[imshape[1],imshape[2],i], 
                              list=F);
	if (length(data2) != imshape[1]*imshape[2]) {
	    return its.stop('Not enough data read')
	}
	data2 -:= data[,,i]
	data2 := abs(data2)
    }    
    rate := imshape[1]*imshape[2]*imshape[3]/(time() - t)/1.0e+6
    rate::print.precision := 3
    its.info('            OK (', rate, 'M pix/s)')

    its.info('XZ plane by XZ plane')
    t := time()
    for (i in 1:imshape[2]) {
        data2 := man.getchunk(blc=[1,i,1],
                              trc=[imshape[1],i,imshape[3]],
                              list=F);
	if (length(data2) != imshape[1]*imshape[3]) {
	    return its.stop('Not enough data read')
	}
	data2 -:= data[,i,]
	data2 := abs(data2)
	if (! all((data2 < 0.0001))) {
	     return its.stop('Some values have changed, max deviation=',
		max(data2))
        }
    }    
    rate := imshape[1]*imshape[2]*imshape[3]/(time() - t)/1.0e+6
    rate::print.precision := 3
    its.info('            OK (', rate, 'M pix/s)')

    its.info('X row by X row')
    t := time()
    for (j in 1:imshape[3]) {
        for (i in 1:imshape[2]) {
            data2 := man.getchunk(blc=[1,i,j],
                                  trc=[imshape[1],i,j],
                                  list=F);
	    if (length(data2) != imshape[1]) {
	        return its.stop('Not enough data read')
	    }
	    data2 -:= data[,i,j]
	    data2 := abs(data2)
	    if (! all((data2 < 0.0001))) {
	          return its.stop('Some values have changed, max deviation=',
		    max(data2))
            }
        }
    }    
    rate := imshape[1]*imshape[2]*imshape[3]/(time() - t)/1.0e+6
    rate::print.precision := 3
    its.info('            OK (', rate, 'M pix/s)')

    its.info('Z row by Z row')
    t := time()
    for (j in 1:imshape[2]) {
        for (i in 1:imshape[1]) {
	    data2 := man.getchunk(blc=[i,j,1], 
                                  trc=[i,j,imshape[3]],
                                  list=F);
	    if (length(data2) != imshape[3]) {
	        return its.stop('Not enough data read')
	    }
	    data2 -:= data[i,j,]
	    data2 := abs(data2)
	    if (! all((data2 < 0.0001))) {
	          return its.stop('Some values have changed, max deviation=',
		    max(data2))
            }
        }
    }    
    rate := imshape[1]*imshape[2]*imshape[3]/(time() - t)/1.0e+6
    rate::print.precision := 3
    its.info('            OK (', rate, 'M pix/s)')
    its.info('Check get/set miscinfo')
    mi := [hello='world', foo='bar', answer=42]
    ok := man.setmiscinfo(mi)
    if (!ok) {return its.stop('Error in setmiscinfo')}
    mi := man.miscinfo()
    if (length(mi) != 3 || mi.hello != 'world' || mi.foo != 'bar' ||
	mi.answer != 42) {
	return its.stop('Error in miscinfo ', as_string(mi))
    }

    its.info('Reflect file through fits and look for changes in data values and miscinfo')
    mannamefits := paste(manname,'.fits',sep='')
    ok := its.fitsreflect (man, mannamefits);
    if (is_fail(ok)) fail;

    # close
    ok := man.done(); 
    if (is_fail(ok)) {
       return its.stop('Done 5 fails')
    }
#
    return its.cleanup(testdir);
   }


   const its.tests.test2 := function()
#
# Test  constructors
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 2 - imagefromshape constructor');
#
      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
     imname := paste(testdir,'/','imagefromshape.image',sep='')
     myim := [=];
     myim := imagefromshape(shape='fish');
     if (!is_fail(myim)) {
        return its.stop('imagefromshape constructor 1 unexpectedly did not fail');
     }
     myim := [=];
     myim := imagefromshape(outfile=[10,20], shape=[10,20]);
     if (!is_fail(myim)) {
        return its.stop('imagefromshape constructor 2 unexpectedly did not fail');
     }
     myim := [=];
     myim := imagefromshape(outfile=imname, shape=[10,20]);
     if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 3 failed');
     }
     local pixels, mask;
     myim.getregion(pixels, mask);
     if (! all(pixels==0.0)) {
        return its.stop('imagefromshape constructor 3 pixels are not all zero');
     }
     if (! all(mask==T)) {
        return its.stop('imagefromshape constructor 3 mask is not all T');
     }
     csys := myim.coordsys();
     if (is_fail(csys)) {
        return its.stop('coordsys 1 failed');
     }
     ok := myim.delete(done=T);
     if (is_fail(ok)) {
        return its.stop('Delete 1 of', imname, ' failed');
     }
#
     myim := imagefromshape(shape=[10,20], csys='xyz');
     if (!is_fail(myim)) {
        return its.stop('imagefromshape constructor 4 unexpectedly did not fail');
     }
     myim := imagefromshape(shape=[10,20], csys=csys);
     if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 5 failed');
     }
     csysRec := csys.torecord();
     csys2 := myim.coordsys();
     if (is_fail(csys2)) {
        return its.stop('coordsys 2 failed');
     }
     csys2Rec := csys2.torecord();
     if (!all(field_names(csysRec)==field_names(csys2Rec))) {
        return its.stop('coordinates from imagefromshape 5 are wrong');
     }     
     ok := myim.done();
     if (is_fail(ok)) fail;
     if (is_fail(csys.done())) fail;
     if (is_fail(csys2.done())) fail;
#
# Try a few different shapes to test out the standard coordinate
# system making of CoordinateUtil
#
     myim := imagefromshape(shape=[10])
     if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 6 failed');
     }
     ok := myim.done();
     if (is_fail(ok)) fail;
     myim := imagefromshape(shape=[10,20])
     if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 7 failed');
     }
     ok := myim.done();
     if (is_fail(ok)) fail;
     myim := imagefromshape(shape=[10,20,4])
     if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 8 failed');
     }
     ok := myim.done();
     if (is_fail(ok)) fail;
     myim := imagefromshape(shape=[10,20,4,16])
     if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 9 failed');
     }
     ok := myim.done();
     if (is_fail(ok)) fail;
     myim := imagefromshape(shape=[10,20,16,4])
     if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 10 failed');
     }
     ok := myim.done();
     if (is_fail(ok)) fail;
     myim := imagefromshape(shape=[10,20,16])
     if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 11 failed');
     }
     ok := myim.done();
     if (is_fail(ok)) fail;
     myim := imagefromshape(shape=[10,20,16,4,5,6])
     if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 12 failed');
     }
     ok := myim.done();
     if (is_fail(ok)) fail;

###
     return its.cleanup(testdir);
   }


   const its.tests.test3 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 3 - imagefromarray constructor');
#
      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make some data
#
     imshape := [10,20,30];
     data := its.make_data(imshape);
#
     imname := paste(testdir,'/','imagefromarray.image',sep='')
     myim := [=];
     myim := imagefromarray(outfile=[10,20], pixels=data);
     if (!is_fail(myim)) {
        return its.stop('imagefromarray constructor 1 unexpectedly did not fail');
     }
     myim := [=];
     myim := imagefromarray(outfile=imname, pixels=data);
     if (is_fail(myim)) {
        return its.stop('imagefromarray constructor 2 failed');
     }
     pixels := []; mask := [];
     myim.getregion(pixels, mask);
     data2 := pixels - data;
     if (! all(data2<0.0001)) {
        return its.stop('imagefromarray 2 pixels have the wrong value');
     }
     if (! all(mask==T)) {
        return its.stop('imagefromarray 2 mask is not all T');
     }
     csys := myim.coordsys();
     if (is_fail(csys)) {
        return its.stop('coordinates 1 failed');
     }
     ok := myim.delete(done=T);
     if (is_fail(ok)) {
        return its.stop('Delete 1 of ', imname, ' failed');
     }
#
     myim := imagefromarray(outfile=imname, pixels=data, csys='xyz');
     if (!is_fail(myim)) {
        return its.stop('imagefromarray constructor 3 unexpectedly did not fail');
     }
     myim := imagefromarray(pixels=data, csys=csys);
     if (is_fail(myim)) {
        return its.stop('imagefromarray constructor 4 failed');
     }
     csysRec := csys.torecord();
     csys2 := myim.coordsys();
     if (is_fail(csys2)) {
        return its.stop('coordinates 2 failed');
     }
     csys2Rec := csys2.torecord();
     if (!all(field_names(csysRec)==field_names(csys2Rec))) {
        return its.stop('coordinates from imagefromarray 4 are wrong');
     }     
     ok := myim.done();
     if (is_fail(ok)) fail;
     if (is_fail(csys.done())) fail;
     if (is_fail(csys2.done())) fail;

###
     return its.cleanup(testdir);
   }


   const its.tests.test4 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 4 - image constructor');
#
      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Test native aips++ image

      imname := paste(testdir,'/','image.image',sep='')
      myim := [=];
      myim := image(infile='_doggies');
      if (!is_fail(myim)) {
         return its.stop('image constructor 1 unexpectedly did not fail');
      }
      myim := [=];
      myim := imagefromshape(outfile=imname, shape=[10,20]);
      if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 1 failed');
      }
      myim.done();
      myim := image(infile=imname);
      if (is_fail(myim)) {
         return its.stop('image constructor 2 failed');
      }
      pixels := []; mask := [];
      myim.getregion(pixels, mask);
      if (! all(pixels==0.0)) {
         return its.stop('pixels (1) are not all zero');
      }
      if (! all(mask==T)) {
        return its.stop('mask (1) is not all T');
      }
#
      fitsname := paste(testdir,'/','image.fits',sep='')
      ok := myim.tofits(fitsname);
      if (is_fail(ok)) fail;
#
      ok := myim.delete(done=T);
      if (is_fail(ok)) {
         return its.stop('Failed to delete ', imname);
      }

# Test FITS image

      myim := image(fitsname);
      if (is_fail(myim)) {
         return its.stop('image constructor 3 failed');
      }
#
      pixels := []; mask := [];
      ok := myim.getregion(pixels, mask);
      if (is_fail(ok)) fail;
      if (!all(pixels==0.0)) {
         return its.stop('pixels (2) are not all zero');
      }
      if (! all(mask==T)) {
        return its.stop('mask (2) is not all T');
      }
      if (is_fail(myim.done())) fail;

###
      return its.cleanup(testdir);
   }

   const its.tests.test5 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 5 - imagefromimage constructor');
#
      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Test imagefromimage constructor
#
      its.info('');
      imname := paste(testdir,'/','imagefromshape.image',sep='')
      imname2 := paste(testdir,'/','imagefromimage.image',sep='')
#
      myim := imagefromimage(outfile=imname2, infile='_doggies');
      if (!is_fail(myim)) {
         return its.stop('imagefromimage constructor 1 unexpectedly did not fail');
      }
      myim := [=];
      myim := imagefromimage(outfile=imname2, infile='_doggies', region='doggies');
      if (!is_fail(myim)) {
         return its.stop('imagefromimage constructor 2 unexpectedly did not fail');
      }
#
      myim := [=];
      myim := imagefromshape(outfile=imname, shape=[20,40]);
      if (is_fail(myim)) {
         return its.stop('imagefromshape constructor 1 failed');
      }
      pixels := []; mask := [];
      region1 := drm.quarter();
      ok := myim.getregion(pixels, mask, region=region1);
      if (is_fail(ok)) {
         return its.stop('getregion 1 failed');
      }
      ok := myim.done();
      if (is_fail(ok)) {
         return its.stop('done 1 failed');
      }
#
      myim := [=];
      myim := imagefromimage(outfile=imname2, infile=imname);
      if (is_fail(myim)) {
         return its.stop('imagefromimage constructor 3 failed');
      }
      myim.delete(done=T);
      myim := [=];
      myim := imagefromimage(infile=imname, region=region1);
      if (is_fail(myim)) {
         return its.stop('imagefromimage constructor 4 failed');
      }
      bb := myim.boundingbox();
      shape := myim.shape();
      shape2 := bb.trc - bb.blc + 1;
      if (!all(shape==shape2)) {
          return its.stop ('Output image has wrong shape'); 
      }   
      local pixels2, mask2;
      myim.getregion(pixels2, mask2);
      if (!all(pixels==pixels2)) {
         return its.stop('The data values are wrong in the imagefromimage');
      }
      if (!all(mask==mask2)) {
         return its.stop('The mask values are wrong in the imagefromimage');
      }
      if (is_fail(myim.done())) fail;
###
     return its.cleanup(testdir);
   }

   const its.tests.test6 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 6 - imagefromfits constructor');
#
      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
     its.info('Testing imagefromfits constructor');
     imname := paste(testdir,'/','imagefromshape.image',sep='');
     imname2 := paste(testdir,'/','image.fits',sep='');
     imname3 := paste(testdir,'/','imagefromfits.image',sep='');
#
# imagefromfits
#
     myim := [=];
     myim := imagefromfits(outfile=imname3, infile='_doggies');
     if (!is_fail(myim)) {
        return its.stop('imagefromfits constructor 1 unexpectedly did not fail');
     }
     myim := [=];
     myim := imagefromshape(outfile=imname, shape=[10,20]);
     if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 1 failed');
     }
     ok := myim.tofits(outfile=imname2);
     if (is_fail(ok)) {
        return its.stop('tofits failed');
     }
     ok := myim.done();
     if (is_fail(ok)) fail;
#
     myim := imagefromfits(outfile=imname3, infile=imname2, whichhdu=23);
     if (!is_fail(myim)) {
        return its.stop('imagefromfits constructor 2 unexpectedly did not fail');
     }
#
     myim := [=];
     myim := imagefromfits(outfile=imname3, infile=imname2, whichhdu=1);
     if (is_fail(myim)) {
        return its.stop('imagefromfits constructor 3 failed');
     }
     pixels := []; mask := [];
     ok := myim.getregion(pixels, mask);
     if (is_fail(ok)) fail;
     if (! all(pixels==0.0)) {
        return its.stop('imagefromfits constructor 3 pixels are not all zero');
     }
     if (! all(mask==T)) {
        return its.stop('imagefromfits constructor 3 mask is not all T');
     }
     myim.delete(done=T);
#
     myim := [=];
     myim := imagefromfits(infile=imname2, whichhdu=1);
     if (is_fail(myim)) {
        return its.stop('imagefromfits constructor 4 failed');
     }
     pixels := []; mask := [];
     ok := myim.getregion(pixels, mask);
     if (is_fail(ok)) fail;
     if (! all(pixels==0.0)) {
        return its.stop('imagefromfits constructor 3 pixels are not all zero');
     }
     if (! all(mask==T)) {
        return its.stop('imagefromfits constructor 3 mask is not all T');
     }
     if (is_fail(myim.done())) fail;

###
     return its.cleanup(testdir);
   }


###
   const its.tests.test7 := function()
#
# Test  constructors
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 7 - imageconcat constructor');
#
      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
     imname := paste(testdir,'/','imagefromshapeconcat.image',sep='');
     imname2 := paste(testdir,'/','imageconcat.image',sep='');
#
     myim := imageconcat(outfile=imname2, infiles='_doggies');
     if (!is_fail(myim)) {
        return its.stop('imageconcat constructor 1 unexpectedly did not fail');
     }
     myim := imagefromshape(outfile=imname, shape=[10,20]);
     if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 1 failed');
     }
     shape := myim.shape();
     myim.done();
#
     infiles := "";
     infiles[1] := imname;
     infiles[2] := imname;
     infiles[3] := imname;
     shapex := shape;
     shapex[1] := 3*shape[1];
     shapey := shape;
     shapey[2] := 3*shape[2];
     myim := imageconcat(outfile=imname2, infiles=infiles, axis=30, relax=T);
     if (!is_fail(myim)) {
        return its.stop('imageconcat constructor 2 unexpectedly did not fail');
     }
     myim := imageconcat(outfile=imname2, infiles=infiles, axis=2, relax=F);
     if (!is_fail(myim)) {
        return its.stop('imageconcat constructor 3 unexpectedly did not fail');
     }
     myim := imageconcat(outfile=imname2, infiles=infiles, axis=2, relax=T);
     if (is_fail(myim)) {
        return its.stop('imageconcat constructor 4 failed');
     }
     shape := myim.shape();
     if (!all(shape==shapey)) {
        return its.stop('imageconcat image has wrong shape');
     }
     ok := myim.delete(done=T);
     if (is_fail(ok)) fail;
     myim := imageconcat(infiles=infiles, axis=1, relax=T);
     if (is_fail(myim)) {
        return its.stop('imageconcat constructor 5 failed');
     }
     shape := myim.shape();
     if (!all(shape==shapex)) {
        return its.stop('imageconcat image has wrong shape');
     }
     if (is_fail(myim.done())) fail;

###
     return its.cleanup(testdir);
   }

   const its.tests.test8 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 8 - imagecalc constructor');
#
      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
     imname := paste(testdir,'/','imagefromarray1.image',sep='');
     imname2 := paste(testdir,'/','imagefromshape2.image',sep='');
     imname3 := paste(testdir,'/','imagecalc.image',sep='');
     imshape := [10,20,5];
     data := its.make_data(imshape);
#
     myim := [=];
     myim := imagecalc(outfile=imname3, pixels='i_like_doggies');
     if (!is_fail(myim)) {
        return its.stop('imagecalc constructor 1 unexpectedly did not fail');
     }
     myim := [=];
     myim := imagefromarray(outfile=imname, pixels=data);
     if (is_fail(myim)) {
        return its.stop('imagefromarray constructor 1 failed');
     }
     local stats;
     ok := myim.statistics(stats, force=T, list=F);
     if (is_fail(ok)) fail;
     myim.done();
#
     myim := [=];
     myim := imagefromshape(outfile=imname2, shape=2*imshape);
     if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 1 failed');
     }
     myim.done();
#
     ex := spaste(imname, '+', imname2);
     myim := imagecalc(outfile=imname3, pixels=ex);
     if (!is_fail(myim)) {
        return its.stop('imagecalc constructor 2 unexpectedly did not fail');
     }
#
# Need the double quotes because of / in expression
#
     ex := spaste('"', imname, '"', '+', '"', imname, '"');
     myim := imagecalc(outfile=imname3, pixels=ex);
     if (is_fail(myim)) {
        return its.stop('imagecalc constructor 3 failed');
     }
     local stats2;
     ok := myim.statistics(stats2, force=T, list=F);
     if (is_fail(ok)) fail;
     if (stats2.max != 2*(stats.max)) {
        return its.stop('imagecalc 3 image has wrong data values');
     }
     if (stats2.min != 2*(stats.min)) {
        return its.stop('imagecalc 3 image has wrong data values');
     }
     if (is_fail(myim.delete(done=T))) fail;

###
     return its.cleanup(testdir);
   }

   const its.tests.test9 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 9 - readonly imagecalc constructors');
#
      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
     imname := paste(testdir,'/','imagefromarray1.image',sep='');
     imname2 := paste(testdir,'/','imagefromshape2.image',sep='');
     imshape := [10,20,5];
     data := its.make_data(imshape);
#
     myim := [=];
     myim := imagecalc(pixels='i_like_doggies');
     if (!is_fail(myim)) {
        return its.stop('expr constructor 1 unexpectedly did not fail');
     }
     myim := imagefromarray(outfile=imname, pixels=data);
     if (is_fail(myim)) {
        return its.stop('imagefromarray constructor 1 failed');
     }
     local stats;
     ok := myim.statistics(stats, force=T, list=F);
     if (is_fail(ok)) {
        return its.stop('statistics 1 failed');
     }
     ok := myim.done();
     if (is_fail(ok)) {
        return its.stop('done 1 failed');
     }
     myim := imagefromshape(outfile=imname2, shape=2*imshape);
     if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 1 failed');
     }
     ok := myim.done();
     if (is_fail(ok)) {
        return its.stop('done 2 failed');
     }
#
     ex := spaste('"', imname, '"', '+', '"', imname2, '"');
     myim := imagecalc(pixels=ex);
     if (!is_fail(myim)) {
        return its.stop('expr constructor 2 unexpectedly did not fail');
     }
#
     ex := spaste('"', imname, '"', '+', '"', imname, '"');
     myim := imagecalc(pixels=ex);
     if (is_fail(myim)) {
        return its.stop('expr constructor 3 failed');
     }
     local stats2;
     ok := myim.statistics(stats2, force=T, list=F);
     if (is_fail(ok)) {
        return its.stop('statistics 2 failed');
     }
     if (stats2.max != 2*(stats.max)) {
        return its.stop('expr image has wrong data values');
     }
     if (stats2.min != 2*(stats.min)) {
        return its.stop('imagecalc image has wrong data values');
     }
     ok := myim.done();
     if (is_fail(ok)) {
        return its.stop('done 3 failed');
     }
###
     return its.cleanup(testdir);
   }





   const its.tests.test10 := function()
#
# Test methods
#   is_image, imagetools, imagedones
#   open, close, done, type, id
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 10 - is_image, imagetools, imagedones, done, close, open');
      its.info('Test 10 - isopen, type, id, lock, unlock, haslock');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Make two images

     imname1 := paste(testdir,'/','imagefromshape.image',sep='')
     shape1 := [10,20];
     global myim1_test10_ := imagefromshape(outfile=imname1, shape=shape1);
     if (is_fail(myim1_test10_)) {
        return its.stop('imagefromshape constructor 1 failed');
     }
     imname2 := paste(testdir,'/','imagefromshape.image2',sep='')
     shape2 := [10,20];
     global myim2_test10_ := imagefromshape(outfile=imname2, shape=shape2);
     if (is_fail(myim2_test10_)) {
        return its.stop('imagefromshape constructor 2 failed');
     }
#
     its.info('');
     its.info('Testing is_image');
     if (!is_image(myim1_test10_) || !is_image(myim2_test10_)) {
        return its.stop('Global function is_image failed');
     }
#
     its.info('');
     its.info('Testing imagetools');
     itools := imagetools();
#
# There might be other global image tools out there
#
     nimages := length(itools);
     if (nimages>1) {
        ok := T; found1 := F; found2 := F;
        for (i in 1:nimages) {
          if (itools[i]=='myim1_test10_') {
            if (found1) {
               ok := F;
            } else {
               found1 := T;
            }
          } else if (itools[i]=='myim2_test10_') {
            if (found2) {
               ok := F;
            } else {
               found2 := T;
            }
          }
        }
        if (!ok || !found1 || !found2) {
           return its.stop('Global function imagetools failed');
        }
     } else {
        return its.stop('Global function imagetools failed');
     }
#
     its.info('');
     its.info('Testing done/imagedones');
     ok := imagedones("myim1_test10_ myim2_test10_")
     if (is_fail(ok)) {
        return its.stop('imagedones failed');
     }
     if (myim1_test10_!=F || myim2_test10_!=F) {
        return its.stop('imagedones did not completely destroy image tools');
     }

# Test shape/close/open

    its.info('');
    its.info('Testing close');
    myim := image(imname1);
    shape := myim.shape();
    if (!all(shape==shape1)) {
        return its.stop('image has wrong shape');
    }
    ok := myim.close();
    if (is_fail(ok)) {
       return its.stop('Close fails');
    }
    if (myim.isopen()) {
       return its.stop('isopen 1 fails');
    }
    ok := myim.shape();
    if (!is_fail(ok)) {
       return its.stop('Closed image is unexpectedly viable');
    }
#
    its.info('');
    its.info('Testing open');
    ok := myim.open(imname2);
    if (is_fail(ok)) {
       return its.stop('Open fails');
    }
    if (!myim.isopen()) {
       return its.stop('isopen 2 fails');
    }
    shape := myim.shape();
    if (!all(shape==shape2)) {
        return its.stop('image has wrong shape');
    }
#
    its.info('');
    its.info('Testing type');
    if (myim.type()!='image') {
        return its.stop('image has wrong type');
    }
#
    its.info('');
    its.info('Testing id');
    id := myim.id();
    if (is_fail(id)) {
        return its.stop('id failed');
    }
    ok := is_record(id) && has_field(id, 'sequence') && has_field(id, 'pid') &&
          has_field(id, 'time') && has_field(id, 'host') &&
          has_field(id, 'agentid');
    if (!ok) {
        return its.stop('id record has wrong fields');
    }
#
    ok := myim.done();
    if (is_fail(ok)) {
       return its.stop('Done 2 failed');
    }

#
    myim := image(imname1);
    ok := myim.open(imname2);
    if (is_fail(ok)) {
       return its.stop('Open on already open image failed');
    }
#
# We cant test locking properly without two glish processes
# trying to access the same image.  So all we can do is
# see that the functions run and test that haslock
# gives the right answers
#
    its.info('');
    its.info('Testing locking');
    ok := myim.lock(T, nattempts=0);
    if (is_fail(ok)) {
       return its.stop('Lock failed (1)');
    }
    ok := myim.haslock();
    if (is_fail(ok)) {
       return its.stop('haslock failed (1)');
    }
    if (ok[1]!=T || ok[2]!=T) {
       return its.stop('haslock returns wrong values (1)');
    }
#
    ok := myim.unlock();
    if (is_fail(ok)) {
       return its.stop('Unlock failed (1)');
    }
    ok := myim.haslock();
    if (is_fail(ok)) {
       return its.stop('haslock failed (2)');
    }
    if (ok[1]!=F || ok[2]!=F) {
       return its.stop('haslock returns wrong values (2)');
    }
#
    ok := myim.lock(F, nattempts=0);
    if (is_fail(ok)) {
       return its.stop('Lock failed (2)');
    }
    ok := myim.haslock();
    if (is_fail(ok)) {
       return its.stop('haslock failed (3)');
    }
    if (ok[1]!=T || ok[2]!=F) {
       return its.stop('haslock returns wrong values (3)');
    }
#
    ok := myim.done();
    if (is_fail(ok)) {
       return its.stop('Done 3 failed');
    }

###
     return its.cleanup(testdir);
   }



   const its.tests.test11 := function()
#
# Test methods
#   coordsys, setcoordsys, shape, name, rename, delete, persistent
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 11 - coordsys, setcoordsys, shape, name, rename, delete, persistent');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Make three images

      imname1 := paste(testdir,'/','imagefromshape.image1',sep='')
      shape1 := [10,20];
      myim := imagefromshape(outfile=imname1, shape=shape1);
      if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 1 failed');
      }
#
      imname2 := paste(testdir,'/','imagefromshape.image2',sep='')
      shape2 := [5,10];
      myim2 := imagefromshape(outfile=imname2, shape=shape2);
      if (is_fail(myim2)) {
        return its.stop('imagefromshape constructor 2 failed');
      }
      ok := myim2.done();
      if (is_fail(ok)) {
         return its.stop('Done 2 fails');
      }


# coordsys

      its.info('');
      its.info('Testing coordsys');
      cs := myim.coordsys();
      if (is_fail(cs)) {
         return its.stop('coordsys 1 failed');
      }
      if (!is_coordsys(cs)) {
         return its.stop('coordinates are not valid (1)');
      }
      ok := its.coordcheck(myim, [1,2], testdir);
      if (is_fail(ok)) {
         return its.stop('coordinates subset selection 1 failed');
      }
      ok := its.coordcheck(myim, [1], testdir);
      if (is_fail(ok)) {
         return its.stop('coordinates subset selection 1 failed');
      }
      ok := its.coordcheck(myim, [2], testdir);
      if (is_fail(ok)) {
         return its.stop('coordinates subset selection 1 failed');
      }
      if (is_fail(cs.done())) fail;

# setcoordsys

      its.info('');
      its.info('Testing setcoordsys');
      cs := myim.coordsys();
      if (is_fail(cs)) {
         return its.stop('coordsys 2 failed');
      }
#
      incr := 2.0*cs.increment (format='n');
      if (is_fail(incr)) fail;
      refval := cs.referencevalue(format='n') + 0.01;
      if (is_fail(refval)) fail;
      refpix := cs.referencepixel() + 10.0;
      if (is_fail(refpix)) fail;
      ok := cs.setincrement (value=incr);
      if (is_fail(ok)) fail;
      ok := cs.setreferencevalue(value=refval);
      if (is_fail(ok)) fail;
      ok := cs.setreferencepixel(value=refpix);      
      if (is_fail(ok)) fail;
#
      ok := myim.setcoordsys (cs);
      if (is_fail(ok)) {
         return its.stop('setcoordsys 1 failed');
      }
      if (is_fail(cs.done())) fail;
      cs2 := myim.coordsys();
      if (!all(incr==cs2.increment(format='n'))) {
         return its.stop('coordsys/setcoordsys  reflection fails increment test');
      }
      if (!all(refval==cs2.referencevalue(format='n'))) {
         return its.stop('coordsys/setcoordsys  reflection fails ref val test');
      }
      if (!all(refpix==cs2.referencepixel())) {
         return its.stop('coordsys/setcoordsys  reflection fails ref pix test');
      }
      if (is_fail(cs2.done())) fail;            
#
      cs := coordsys(direction=F, spectral=F, stokes="", linear=0);
      if (is_fail(cs)) fail;
      ok := myim.setcoordsys (cs);
      if (!is_fail(ok)) {
         return its.stop('setcoordsys 3 unexpectedly did not fail');
      }
      if (is_fail(cs.done())) fail;
      cs := 'doggies'
      ok := myim.setcoordsys (cs);
      if (!is_fail(ok)) {
         return its.stop('setcoordsys 4 unexpectedly did not fail');
      }
# shape

      its.info('');
      its.info('Testing shape');
      if (!all(myim.shape()==shape1)) {
         return its.stop('Shape fails');
      }

# Name

      its.info('');
      its.info('Testing name');
      absoluteName := dos.fullname(imname1);
      if (is_fail(absoluteName)) fail;
      if (myim.name(strippath=F) != absoluteName) {
  	return its.stop('The absolute name is wrong');
      }
      baseName := 'imagefromshape.image1';
      if (myim.name(strippath=T) != baseName) {
  	return its.stop('The base name is wrong');
      }

# Rename

      its.info('');
      its.info('Testing rename');
      imname4 := paste(testdir,'/','imagefromshape.image4',sep='')
      ok := myim.rename(imname4, overwrite=F);
      if (is_fail(ok)) {
         return its.stop('Rename 1 fails');
      }
      absoluteName := dos.fullname(imname4);
      if (is_fail(absoluteName)) fail;
      if (myim.name(strippath=F) != absoluteName) {
  	return its.stop('The name has not been renamed correctly');
      }
#
      ok := myim.rename(imname2, overwrite=F);
      if (!is_fail(ok)) {
         return its.stop('Rename unexpectedly did not fail');
      }
      ok := myim.rename(imname2, overwrite=T);
      if (is_fail(ok)) {
         return its.stop('Rename 2 fails');
      }

# Delete

      its.info('');
      its.info('Testing delete');
      ok := myim.delete(done=T);
      if (is_fail(ok)) {
         return its.stop('Done 3 fails');
      }
      if (myim!=F) {
         return its.stop('Done did not completely destroy image tool');
      }
#
      myim := imagefromshape(imname1, shape1);
      if (is_fail(myim)) {
         return its.stop('imagefromshape constructor 3 fails');
      }
      ok := myim.delete(done=F);
      if (is_fail(ok)) {
         return its.stop('Delete fails');
      }
      if (is_boolean(myim) && myim==F) {
         return its.stop('Delete erroneously destroyed the image tool');
      }
      ok := myim.done();
      if (is_fail(ok)) {
         return its.stop('Done 4 fails');
      }

# persistent

      its.info('');
      its.info('Testing ispersistent');
      imname4 := paste(testdir,'/','imagefromshape.image4',sep='')
      shape4 := [10,10];
      myim4 := imagefromshape(outfile=imname4, shape=shape4);
      if (is_fail(myim4)) {
        return its.stop('imagefromshape constructor 4 failed');
      }
#
      if (!myim4.ispersistent()) {
         return its.stop('Persistent test 1 fails');
      }
      ok := myim4.done();
      if (is_fail(ok)) {
         return its.stop('Done 5 fails');
      }
      ex := spaste('"', imname4, '"', '+', '"', imname4, '"');
      myim4 := imagecalc(pixels=ex);
      if (is_fail(myim4)) {
         return its.stop('imagecalc constructor fails');
      }
      if (myim4.ispersistent()) {
         return its.stop('Persistent test 2 fails');
      }
      ok := myim4.done();
      if (is_fail(ok)) {
         return its.stop('Done 6 fails');
      }


###
     return its.cleanup(testdir);
   }




   const its.tests.test12 := function()
#
# Test methods
#   getchunk, putchunk
#   pixelvalue
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 12 - getchunk, putchunk, pixelvalue');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make images of all the wondrous flavours that we have
#
      root := paste(testdir, '/', 'testimage', sep='')
      imshape := [12,24,20];
      const data := its.make_data(imshape);
      images := its.makeAllImageTypes(imshape, root, data, F);
      if (is_fail(images)) fail;
#
# Loop over all image types
#
      types := field_names(images);
      for (type in types) {
         its.info('');
         its.info('Testing Image type ', images[type].type);
         myim := images[type].tool;
#
# Get some chunks !
#

        its.info('');
        its.info('Testing getchunk');
        pixels := myim.getchunk(list=T);
        if (is_fail(pixels)) {
           return its.stop('getchunk 1 failed');
        }
        if (pixels::shape != imshape) {
           return its.stop('getchunk 1 recovers wrong array shape');
        }
        if (!all((pixels-data < 0.0001))) {
            return its.stop('getchunk 1 recovers wrong pixel values=');
        }
#
        inc := [1,2,5];
        pixels := myim.getchunk(inc=inc);
        if (is_fail(pixels)) {
           return its.stop('getchunk 2 failed');
        }
        if (pixels::shape != imshape/[1,2,5]) {
           return its.stop('getchunk 2 recovers wrong array shape');
        }
        data2 := its.pick(imshape, data, inc);
        if (!all((pixels-data2 < 0.0001))) {
            return its.stop('getchunk 2 recovers wrong pixel values=');
        }
#
        blc := [2,3,4];
        trc := [5,6,7];
        shape2 := trc - blc + [1,1,1];
        pixels := myim.getchunk(blc=blc, trc=trc, inc=[1,1,1]);
        if (is_fail(pixels)) {
           return its.stop('getchunk 3 failed');
        }
        if (pixels::shape != shape2) {
           return its.stop('getchunk 3 recovers wrong array shape');
        }
        data2 := data[blc[1]:trc[1], blc[2]:trc[2], blc[3]:trc[3]];
        if (!all((pixels-data2 < 0.0001))) {
            return its.stop('getchunk 3 recovers wrong pixel values=');
        }
#
        blc := [-10,-10,-10];      
        pixels := myim.getchunk(blc=blc);
        if (is_fail(pixels)) {
           return its.stop('getchunk 4 failed');
        }
        if (pixels::shape != imshape) {
           return its.stop('getchunk 4 recovers wrong array shape');
        }
#
        trc := [10000,10000,10000];
        pixels := myim.getchunk(trc=trc);
        if (is_fail(pixels)) {
           return its.stop('getchunk 5 failed');
        }
        if (pixels::shape != imshape) {
           return its.stop('getchunk 5 recovers wrong array shape');
        }
#
        blc := [5,6,7];
        trc := [1,2,3];
        pixels := myim.getchunk(blc=blc,trc=trc);
        if (is_fail(pixels)) {
           return its.stop('getchunk 6 failed');
        }
       if (pixels::shape != imshape) {
           return its.stop('getchunk 6 recovers wrong array shape');
        }
#
        inc := [100,100,100]
        pixels := myim.getchunk(inc=100);
        if (is_fail(pixels)) {
          return its.stop('getchunk 7 failed');
        }
        if (pixels::shape != imshape) {
           return its.stop('getchunk 7 recovers wrong array shape');
        }
#
        pixels := myim.getchunk (axes=[1,2], dropdeg=T)
        if (shape(pixels) != imshape[3]) {
           return its.stop('getchunk 8 recovers wrong array shape');
        }
#
        pixels := myim.getchunk (axes=[2,3], dropdeg=T)
        if (shape(pixels) != imshape[1]) {
           return its.stop('getchunk 9 recovers wrong array shape');
        }
#
        pixels := myim.getchunk (axes=[1], dropdeg=T)
        if (!all(shape(pixels)==imshape[2:3])) {
           return its.stop('getchunk 10 recovers wrong array shape');
        }
#
# Now some putchunking
#
        its.info('');
        its.info('Testing putchunk');
        pixels := myim.getchunk();
        if (is_fail(pixels)) {
           return its.stop('getchunk 8 failed');
        }
        data2 := data;
        data2[data2>=-10000] := 100;
        ok := myim.putchunk(pixels=data2, list=T);
        if (is_fail(ok)) {
           return its.stop('putchunk 1 failed');
        }
        pixels := myim.getchunk();
        if (is_fail(pixels)) {
           return its.stop('getchunk 9 failed');
        }
        if (!all((pixels-data2 < 0.0001))) {
            return its.stop('getchunk 10 recovers wrong pixel values=');
        }
#
        inc := [2,1,5];
        data2 := as_float(array(0,imshape[1]/inc[1], imshape[2]/inc[2], imshape[3]/inc[3]));
        ok := myim.putchunk(pixels=data2, inc=inc);
        if (is_fail(ok)) {
           return its.stop('putchunk 2 failed');
        }
        pixels := myim.getchunk(inc=inc);
        if (is_fail(pixels)) {
           return its.stop('getchunk 9 failed');
        }
        if (!all((pixels-data2 < 0.0001))) {
            return its.stop('getchunk 10 recovers wrong pixel values=');
        }
        pixels2 := myim.getchunk();
        if (is_fail(pixels2)) {
           return its.stop('getchunk 11 failed');
        }
        data2 := its.pick(imshape, pixels2, inc);
        if (!all((data2-pixels < 0.0001))) {
            return its.stop('getchunk 11 recovers wrong pixel values=');
        }
        pixels := F; pixels2 := F; data2 := F;
#
        pixels := myim.getchunk();
        if (is_fail(pixels)) {
           return its.stop('getchunk 12 failed');
        }
        ok := myim.putchunk(pixels=pixels, blc=[3,4,5]);
        if (!is_fail(ok)) {
           return its.stop('putchunk 3 unexpectedly did not fail');
        }
        ok := myim.putchunk(pixels=pixels, inc=[3,4,5]);
        if (!is_fail(ok)) {
           return its.stop('putchunk 4 unexpectedly did not fail');
        }
#
        pixels[pixels>=-10000] := 100;
        ok := myim.putchunk(pixels=pixels);
        if (is_fail(ok)) {
           return its.stop('putchunk 5 failed');
        }
        pixels := as_float(array(0,imshape[1], imshape[2]));
        ok := myim.putchunk(pixels=pixels);
        if (is_fail(ok)) {
           return its.stop('putchunk 6 failed');
        }
        pixels2 := myim.getchunk();
        if (!all(pixels2[,,1]==0)) {
           return its.stop('getchunk 13 recovered wrong pixel values');
        }
        if (!all(pixels2[,,2]==100)) {
           return its.stop('getchunk 14 recovered wrong pixel values');
        }
#
# Test replication in putchunk
#
        ok := myim.set(pixels=0.0)
        if (is_fail(ok)) {
           return its.stop('set 1 fails');
        }
#
        p := array(10.0, imshape[1], imshape[2]);   # Adds degenerate axis
        ok := myim.putchunk(p, replicate=T);
        if (is_fail(ok)) {
           return its.stop('putchunk 8 fails');
        }
        p2 := myim.getchunk();
        if (is_fail(p2)) {
           return its.stop('getchunk 16 fails');
        }
        if (!all(p2[,,]==10.0)) {
           return its.stop('putchunk 8 put wrong values');
        }
#
        p := array(10.0, imshape[1], imshape[2], 1);
        ok := myim.putchunk(p, replicate=T);
        if (is_fail(ok)) {
           return its.stop('putchunk 9 fails');
        }
        p2 := myim.getchunk();
        if (is_fail(p2)) {
           return its.stop('getchunk 17 fails');
        }
        if (!all(p2[,,]==10)) {
           return its.stop('putchunk 9 put wrong values');
        }
#
# Now pixelvalue
#
        its.info('');
        its.info('Testing pixelvalue');
        pixels2[,,] := 0.0; 
        pixels2[1,1,1] := 1.0;
        ok := myim.putchunk(pixels=pixels2);
        if (is_fail(ok)) {f  
           return its.stop('putchunk 7 failed');
        }
        ok := myim.setbrightnessunit('Jy/beam');
        if (is_fail(ok)) {
           return its.stop('setbrightnessunit 1 failed');
        }       
#
        r := myim.pixelvalue([1,1,1])
        ok := r.value.value==1.0 && r.value.unit=='Jy/beam' &&
              r.mask==T && r.pixel==[1,1,1];
        if (!ok) {
           return its.stop('pixelvalue 1 recovered wrong values');
        }       
#
        r := myim.pixelvalue([0,0,0])
        ok := is_unset(r);
        if (!ok) {
           return its.stop('pixelvalue 2 recovered wrong values');
        }       
        r := myim.pixelvalue(myim.shape()+1);
        ok := is_unset(r);
        if (!ok) {
           return its.stop('pixelvalue 3 recovered wrong values');
        }       
#
        r := myim.pixelvalue([2,2,2,100])
        ok := r.value.value==0.0 && r.value.unit=='Jy/beam' &&
              r.mask==T && r.pixel==[2,2,2];
        if (!ok) {
           return its.stop('pixelvalue 4 recovered wrong values');
        }       
#
        ok := myim.done();      
        if (is_fail(ok)) {
           return its.stop('Done 1 fails');
        }
    }

###
      return its.cleanup(testdir);
   }


   const its.tests.test13 := function()
#
# Test methods
#   getregion, putregion, set, replacemaskedpixels
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 13 - getregion, putregion, set, replacemaskedpixels');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make images of all the wondrous flavours that we have
#
      root := paste(testdir, '/', 'testimage', sep='')
      imshape := [10,20,30];
      images := its.makeAllImageTypes(imshape, root, includereadonly=T);
      if (is_fail(images)) fail;
#
# Loop over all image types
#
      types := field_names(images);
      for (type in types) {
         its.info(''):
         its.info('Testing Image type ', images[type].type);
         myim := images[type].tool;
         imshape := myim.shape();                      # Reassign as one of the image types is ImageConcat
#
# Get some regions !
#
        its.info('');
        its.info('Testing getregion');
        local pixels, mask;
        r1 := drm.box();
        ok := myim.getregion(pixels, mask, region=r1, list=T);
        if (is_fail(ok)) {
           return its.stop('getregion 1 failed');
        }
        bb := myim.boundingbox(r1);
        if (pixels::shape != bb.regionShape) {
           return its.stop('getregion 1 recovers wrong array shape');
        }
        if (!all((pixels < 0.0001))) {
            return its.stop('getregion 1 recovers wrong pixel values=');
        }
        if (!all(mask==T)) {
            return its.stop('getregion 1 recovers wrong mask values=');
        }
#
        csys := myim.coordsys();
        ok := drm.setcoordinates(csys);
        if (is_fail(ok)) {
           return its.stop('Failed to set coordinate system in regionmanager 1');
        }
        if (is_fail(csys.done())) fail;
        blc := dq.quantity([2,4,6], 'pix');
        if (is_fail(blc)) fail;
        trc := dq.quantity([8,10,12], 'pix');
        if (is_fail(trc)) fail;
        r1 := drm.wbox(blc=blc, trc=trc);
        if (is_fail(r1)) {
           return its.stop('Failed to make region r1');
        }
        r2 := drm.wpolygon(x=dq.quantity([5,6,7,8], 'pix'),
                           y=dq.quantity([5,5,10,7.5], 'pix'),
                           pixelaxes=[1,2]);
        if (is_fail(r2)) {
           return its.stop('Failed to make region r2');
        }
        r3 := drm.union(r1,r2);
        if (is_fail(r3)) {
           return its.stop('Failed to make region r3');
        }
        ok := myim.getregion(pixels, mask, r3);
        if (is_fail(ok)) {
           return its.stop('getregion 2 failed');
        }
        bb := myim.boundingbox(r3);
        if (pixels::shape != bb.regionShape) {
           return its.stop('getregion 2 recovers wrong array shape');
        }
        if (!all((pixels < 0.0001))) {
            return its.stop('getregion 2 recovers wrong pixel values=');
        }
#
        ok := myim.getregion (pixels, mask, axes=[1,2], dropdeg=T)
        if (is_fail(ok)) fail;
        if (shape(pixels) != imshape[3] || shape(mask) != imshape[3]) {
           return its.stop('getregion 3 recovers wrong array shape');
        }
#
        ok := myim.getregion (pixels, mask, axes=[2,3], dropdeg=T)
        if (is_fail(ok)) fail;
        if (shape(pixels) != imshape[1] || shape(mask) != imshape[1]) {
           return its.stop('getregion 4 recovers wrong array shape');
        }
#
        ok := myim.getregion (pixels, mask, axes=[1], dropdeg=T)
        if (is_fail(ok)) fail;
        if (!all(shape(pixels)==imshape[2:3]) || !all(shape(mask)==imshape[2:3])) {
           return its.stop('getregion 5 recovers wrong array shape');
        }
#
        ok := myim.getregion (pixels=pixels);
        if (is_fail(ok)) fail;
#
        ok := myim.getregion (pixelmask=mask);
        if (is_fail(ok)) fail;
#
        if (is_fail(myim.done())) fail;
      }
#
      ok := its.cleanup(testdir);
      if (is_fail(ok)) fail;
#
# Putregions
#
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
      imshape := [10,20,30];
      images := its.makeAllImageTypes(imshape, root, includereadonly=F);
      if (is_fail(images)) fail;
#
# Loop over all image types
#
      types := field_names(images);
      for (type in types) {
         its.info('');
         its.info('Testing Image type ', images[type].type);
         myim := images[type].tool;
         imshape := myim.shape();                      # Reassign as one of the image types is ImageConcat
#
        its.info('');  
        its.info('Testing putregion');
        local pixels, mask;
        ok := myim.getregion(pixels, mask, r3);
        if (is_fail(ok)) fail;
        ok := myim.putregion(pixelmask=mask, region=r3);
        if (is_fail(ok)) {
          return its.stop('putregion 1 failed');
        }
        local pixels2, mask2;
        ok := myim.getregion(pixels2, mask2, r3);
        if (is_fail(ok)) {
           return its.stop('getregion 6 failed');
        }
        if (!all(mask2==mask)) {
           return its.stop('getregion 6 recovered wrong mask');
        }
#
        r1 := drm.box(trc=[1000]);
        ok := myim.getregion(pixels, mask, r1);
        if (is_fail(ok)) {
           return its.stop('getregion 7 failed');
        }
#
        r1 := drm.box(trc=[1000]);
        ok := myim.putregion(pixels, mask, r1);
        if (is_fail(ok)) {
           return its.stop('putregion 2 failed');
        }
#
        ok := myim.putregion();
        if (!is_fail(ok)) {
           return its.stop('putregion 3 unexpectedly did not fail');
        }
        pixels := array(0,2,3,4,5);
        ok := myim.putregion(pixels=pixels);
        if (!is_fail(ok)) {
           return its.stop('putregion 4 unexpectedly did not fail');
        }
        mask := array(F,2,3,4,5);
        ok := myim.putregion(pixelmask=mask);
        if (!is_fail(ok)) {
           return its.stop('putregion 5 unexpectedly did not fail');
        }
        pixels := array(0,100,100,100);
        ok := myim.putregion(pixels=pixels);
        if (!is_fail(ok)) {
           return its.stop('putregion 6 unexpectedly did not fail');
        }
#
        ok := myim.getregion(pixels, mask);
        if (is_fail(ok)) {
           return its.stop('getregion 8 failed');
        }
        sh := myim.shape();
        pixels[1:sh[1], 1:sh[2], 1:sh[3]] := 1.0;
        mask[1:sh[1], 1:sh[2], 1:sh[3]] := T;
        mask[1,1,1] := F;
        ok := myim.putregion(pixels=pixels, pixelmask=mask, usemask=F);
        if (is_fail(ok)) {
           return its.stop('putregion 7 failed');
        }
        ok := myim.getregion(pixels, mask);
        if (is_fail(ok)) {
           return its.stop('getregion 9 failed');
        }
        tmp := pixels - 1.0;
        if (!all(tmp<0.0001)) {
           return its.stop('getregion 9 recovers wrong pixel values');
        }
        if (mask[1,1,1]==T) {
           return its.stop('getregion 9 recovers wrong mask values (1)');
        }
        tmp := mask[2:sh[1], 2:sh[2], 2:sh[3]];
        if (!all(tmp==T)) {
           return its.stop('getregion 9 recovers wrong mask values (2)');
        }
#
        pixels[1:sh[1], 1:sh[2], 1:sh[3]] := 10.0;
        ok := myim.putregion(pixels=pixels, usemask=T);
        if (is_fail(ok)) {
           return its.stop('putregion 8 failed');
        }
        ok := myim.getregion(pixels, mask);
        if (is_fail(ok)) {
           return its.stop('getregion 10 failed');
        }
        if ((pixels[1,1,1]-1.0)>0.0001) {
           return its.stop('getregion 10 recovers wrong pixel values (1)');
        }
        tmp := pixels[2:sh[1], 2:sh[2], 2:sh[3]] - 1.0;
        if (!all(tmp>0.0001)) {
           return its.stop('getregion 10 recovers wrong pixel values (2)');
        }
#
        pixels[1:sh[1], 1:sh[2], 1:sh[3]] := 10.0;
        mask[1:sh[1], 1:sh[2], 1:sh[3]] := T;
        ok := myim.putregion(pixels=pixels, pixelmask=mask, usemask=F);
        if (is_fail(ok)) {
           return its.stop('putregion 9 failed');
        }
        pixels := array(0.0, sh[1], sh[2]);
        ok := myim.putregion(pixels=pixels, usemask=F);    # Pad with degenerate axes
        if (is_fail(ok)) {
           return its.stop('putregion 10 failed');
        }
        ok := myim.getregion(pixels, mask);
        if (is_fail(ok)) {
           return its.stop('getregion 11 failed');
        }
        tmp := pixels[1:sh[1], 1:sh[2], 1];
        if (!all(tmp < 0.0001)) {
           return its.stop('getregion 11 recovers wrong pixel values (1)');
        }
        tmp := pixels[1:sh[1], 1:sh[2], 2:sh[3]] - 10.0;
        if (!all(tmp < 0.0001)) {
           return its.stop('getregion 11 recovers wrong pixel values (2)');
        }
#
        pixels := array(as_float(0.0), sh[1], sh[2], sh[3]);
        mask := array(T, sh[1], sh[2], sh[3]);
        mask[1,1,1] := F;
        ok := myim.putregion(pixels=pixels, pixelmask=mask, usemask=F);
        if (is_fail(ok)) {
           return its.stop('putregion 11 failed');
        }
        pixels := array(0.0, sh[1], sh[2]);
        ok := myim.putregion(pixels=pixels, usemask=T);    # Pad with degenerate axes
        if (is_fail(ok)) {
           return its.stop('putregion 12 failed');
        }
        ok := myim.getregion(pixels, mask);
        if (is_fail(ok)) {
           return its.stop('getregion 12 failed');
        }
        if ((pixels[1,1,1]-10.0)>0.0001) {
           return its.stop('getregion 12 recovers wrong pixel values (1)');
        }
        tmp := pixels[2:sh[1], 2:sh[2], 1];
        if (!all(tmp < 0.0001)) {
           return its.stop('getregion 12 recovers wrong pixel values (1)');
        }
        tmp := pixels[1:sh[1], 1:sh[2], 2:sh[3]] - 10.0;
        if (!all(tmp < 0.0001)) {
           return its.stop('getregion 12 recovers wrong pixel values (2)');
        }
#
# Test replication
#
        ok := myim.set(pixels=0.0, pixelmask=F);
        if (is_fail(ok)) {
           return its.stop('set 1 fails');
        }
#
        p := array(10.0, imshape[1], imshape[2]);   # Adds degenerate axis
        m := array(T, imshape[1], imshape[2]);   # Adds degenerate axis
        ok := myim.putregion(pixels=p, pixelmask=m, usemask=F, replicate=T);
        if (is_fail(ok)) {
           return its.stop('putregion 13 fails');
        }
        local m2,p2;
        ok := myim.getregion(p2, m2);
        if (is_fail(ok)) {
           return its.stop('getregion 13 fails');
        }
        if (!all(p2[,,]==10.0)) {
           return its.stop('putregion 13 put wrong values');
        }
#
        ok := myim.set(pixels=0.0, pixelmask=F);
        if (is_fail(ok)) {
           return its.stop('set 1 fails');
        }
#
        p := array(10.0, imshape[1], imshape[2], 1);
        m := array(T, imshape[1], imshape[2], 1); 
        ok := myim.putregion(pixels=p, pixelmask=m, usemask=F, replicate=T);
        if (is_fail(ok)) {
           return its.stop('putregion 14 fails');
        }
        ok := myim.getregion(p2, m2);
        if (is_fail(ok)) {
           return its.stop('getregion 14 fails');
        }
        if (!all(p2[,,]==10)) {
           return its.stop('putregion 14 put wrong values');
        }
#
# set
#
        its.info('');  
        its.info('Testing set');
#
        ok := myim.set(pixels='doggies');
        if (!is_fail(ok)) {
           return its.stop('set 1 unexpectedly did not fail');
        }
        ok := myim.set(pixelmask='doggies');
        if (!is_fail(ok)) {
           return its.stop('set 2 unexpectedly did not fail');
        }
        ok := myim.set();
        if (!is_fail(ok)) {
           return its.stop('set 3 unexpectedly did not fail');
        }
        ok := myim.set(region='doggies');
        if (!is_fail(ok)) {
           return its.stop('set 4 unexpectedly did not fail');
        }
        ok := myim.set(pixels='imname');
        if (!is_fail(ok)) {
           return its.stop('set 5 unexpectedly did not fail');
        }
#
        ok := myim.set(pixels=1.0);
        if (is_fail(ok)) {
           return its.stop('set 6 failed');
        }
        ok := myim.getregion(pixels, mask);
        if (is_fail(ok)) {
           return its.stop('getregion 6 failed');
        }
        if (!all( (pixels-1) < 0.0001 )) {
            return its.stop('getregion 6 recovers wrong pixel values');
        }
#
        ok := myim.set(pixels='1.0');
        if (is_fail(ok)) {
           return its.stop('set 7 failed');
        }
        ok := myim.getregion(pixels, mask);
        if (is_fail(ok)) {
           return its.stop('getregion 7 failed');
        }
        if (!all((pixels-1) < 0.0001)) {
            return its.stop('getregion 7 recovers wrong pixel values');
        }
#
        pixels[1,1,1] := -100;
        ok := myim.putregion(pixels=pixels);
        if (is_fail(ok)) {
           return its.stop('putregion 7 failed');
        }
        imname := spaste(testdir, '/subimage.test');
        myim2 := myim.subimage(imname);
        if (is_fail(myim2)) fail;
        expr := spaste('min("', imname, '")');
        ok := myim.set(pixels=expr);
        if (is_fail(ok)) {
           return its.stop('set 8 failed');
        }
        ok := myim.getregion(pixels, mask);
        if (is_fail(ok)) {
           return its.stop('getregion 8 failed');
        }
        if (!all((pixels+100) < 0.0001)) {
            return its.stop('getregion 8 recovers wrong pixel values');
        }
        if (is_fail(myim2.delete(T))) fail;

#
        ok := myim.set(pixelmask=F);
        if (is_fail(ok)) {
           return its.stop('set 9 failed');
        }
        ok := myim.getregion(pixels, mask);
        if (is_fail(ok)) {
           return its.stop('getregion 9 failed');
        }
        if (!all(mask==F)) {
            return its.stop('getregion 9 recovers wrong mask values');
        }
#
        ok := myim.set(pixels=1.0);
        if (is_fail(ok)) {
           return its.stop('set 10 failed');
        }
        blc := [1,1,5];
        trc := [3,4,10];
        r1 := drm.box(blc, trc);
        ok := myim.set(pixels=0.0, pixelmask=T, region=r1);
        if (is_fail(ok)) {
           return its.stop('set 11 failed');
        }
        ok := myim.getregion(pixels, mask);
        if (is_fail(ok)) {
           return its.stop('getregion 10 failed');
        }
        blc2 := trc + 1; 
        if (!all( (pixels[blc[1]:trc[1],blc[2]:trc[2],blc[3]:trc[3]]<0.0001) ) ||
            !all( (pixels[blc2[1]:imshape[1],blc2[2]:imshape[2],blc2[3]:imshape[3]]-1)<0.0001))
        {
            return its.stop('getregion 10 recovers wrong pixel values');
        }
        ok1 := all(mask[blc[1]:trc[1],blc[2]:trc[2],blc[3]:trc[3]]==T);
        ok2 := all(mask[blc2[1]:imshape[1],blc2[2]:imshape[2],blc2[3]:imshape[3]]==F);
        if (!ok1 || !ok2) {
           return its.stop('getregion 10 recovers wrong mask values');
        }
#
        global __global_setimage := ref myim;
        ok := myim.set(pixels='min($__global_setimage)');
        if (is_fail(ok)) {
           return its.stop('set 11 failed');
        }
#
# replacemaskedpixels
#
        its.info('');
        its.info('Testing replacemaskedpixels');
        ok := myim.set(pixels=0.0, pixelmask=T)
        if (is_fail(ok)) {
           return its.stop('set 12 failed');
        }
        ok := myim.getregion(pixels, mask);
        if (is_fail(ok)) {
           return its.stop('getregion 11 failed');
        }
        ys := imshape[2] - 3;
        ye := imshape[2];
        mask[1:2,ys:ye,] := F;
        ok := myim.putregion(pixelmask=mask);
        if (is_fail(ok)) {
           return its.stop('putregion 8 failed');
        }
# 
        ok := myim.replacemaskedpixels(pixels=T);
        if (!is_fail(ok)) {
           return its.stop('replacemaskedpixels 1 unexpectedly did not fail');
        }
        ok := myim.replacemaskedpixels(makemaskgood='doggies');
        if (!is_fail(ok)) {
           return its.stop('replacemaskedpixels 2 unexpectedly did not fail');
        }
#
        value := -1.0;
        ok := myim.replacemaskedpixels(pixels=value);
        if (is_fail(ok)) {
           return its.stop('replacemaskedpixels 3 failed');
        }
        ok := myim.getregion(pixels, mask2);
        if (is_fail(ok)) {
           return its.stop('getregion 12 failed');
        }
        tmp := pixels[1:2,ys:ye,] - value;
        if (!all(tmp<0.0001)) {
           return its.stop('getregion 12 recovered wrong pixel values');
        }
        tmp := pixels[3:imshape[1], 1:(ys-1),];
        if (!all(tmp<0.0001)) {
           return its.stop('getregion 12 recovered wrong pixel values');
        }
        if (!all(mask==mask2)) {
           return its.stop('getregion 12 recovered wrong mask');
        }
#
        global __global_replaceimage := ref myim;
        value := 10.0;
        ex1 := 'max($__global_replaceimage)+10';
        ok := myim.replacemaskedpixels(pixels=ex1);
        if (is_fail(ok)) {
           return its.stop('replacemaskedpixels 4 failed');
        }
        ok := myim.getregion(pixels, mask2);
        if (is_fail(ok)) {
           return its.stop('getregion 13 failed');
        }
        tmp := pixels[1:2,ys:ye,] - value;
        if (!all(tmp<0.0001)) {
           return its.stop('getregion 13 recovered wrong pixel values');
        }
        tmp := pixels[3:imshape[1], 1:(ys-1),];
        if (!all(tmp<0.0001)) {
           return its.stop('getregion 13 recovered wrong pixel values');
        }
        if (!all(mask==mask2)) {
           return its.stop('getregion 13 recovered wrong mask');
        }
#
        ok := myim.set(pixels=1.0, pixelmask=T);
        if (is_fail(ok)) {
           return its.stop('set 12 failed');
        }
        ok := myim.getregion(pixels, mask);
        if (is_fail(ok)) {
           return its.stop('getregion 15 failed');
        }
        mask[1,1,1] := F; 
        mask[imshape[1],imshape[2],imshape[3]] := F;
        ok := myim.putregion(pixelmask=mask);
        if (is_fail(ok)) {
           return its.stop('putregion 9 failed');
        }
#
        imname2 := paste(testdir,'/','imagefromshape.image3',sep='')
        myim2 := imagefromshape(outfile=imname2, shape=imshape);
        if (is_fail(myim2)) {
          return its.stop('imagefromshape constructor 2 failed');
        }
        ok := myim2.set(pixels=2.0);
        if (is_fail(ok)) {
           return its.stop('set 13 failed');
        }
        ex1 := spaste('"', imname2, '"');
        ok := myim.replacemaskedpixels(pixels=ex1);
        if (is_fail(ok)) {
           return its.stop('replacemaskedpixels 6 failed');
        }
        ok := myim.getregion(pixels, mask2);
        if (is_fail(ok)) {
           return its.stop('getregion 16 failed');
        }
        if (pixels[1,1,1]!=2 || pixels[imshape[1],imshape[2],imshape[3]]!=2) {
           return its.stop('getregion 16a recovered wrong pixel values');
        }
        if (!all(pixels[2:(imshape[1]-1), 2:(imshape[2]-1),2:(imshape[3]-1)]==1.0)) {
           return its.stop('getregion 16b recovered wrong pixel values');
        }
#
        ok := myim.done();      
        if (is_fail(ok)) {
           return its.stop('Done 2 fails');
        }
        ok := myim2.delete(T);      
        if (is_fail(ok)) {
           return its.stop('Done 3 fails');
        }
      }

###
      return its.cleanup(testdir);
   }



   const its.tests.test14 := function()
#
# Test methods
#   tofits
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 14 - FITS conversion');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Make image

      imshape := [12,24,20];
      myim := imagefromshape(shape=imshape);
      if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 1 failed');
      }
#
      fitsname1 := paste(testdir,'/','fits.image1',sep='')
      ok := its.fitsreflect (myim, fitsname1);
      if (is_fail(ok)) fail;
      ok := its.fitsreflect (myim, fitsname1, do16=T);
      if (is_fail(ok)) fail;
#
      ok := myim.tofits(outfile=fitsname1, region=drm.box());
      if (is_fail(ok)) {
        return its.stop('tofits 1 failed');
      }
#
      fitsname2 := paste(testdir,'/','fits.image2',sep='')
      r1 := drm.box(trc=[10000]);
      ok := myim.tofits(outfile=fitsname2, region=r1);
      if (is_fail(ok)) {
        return its.stop('tofits 2 failed');
      }
#
# Not useful because there is no spectral axis and I can't make one !
#
      fitsname3 := paste(testdir,'/','fits.image3',sep='')
      ok := myim.tofits(outfile=fitsname3, optical=F, velocity=F);
      if (is_fail(ok)) {
        return its.stop('tofits 3 failed');
      }
      ok := myim.done();      
      if (is_fail(ok)) {
         return its.stop('Done 1 fails');
      }

###
      return its.cleanup(testdir);
   }


   const its.tests.test15 := function()
#
# Test methods
#   boundingbox, {set}restoringbeam, coordmeasures, topixel, toworld
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 15 - boundingbox, {set}restoringbeam')
      its.info('          coordmeasures, topixel, toworld');

# Make the directory

      testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make images of all the wondrous flavours that we have
#   
      root := paste(testdir, '/', 'testimage', sep='')
      imshape := [12,24,20];
      images := its.makeAllImageTypes(imshape, root, includereadonly=T);
      if (is_fail(images)) fail;
#
# Loop over all image types
#
      types := field_names(images);
      for (type in types) {
         its.info('');
         its.info('Testing Image type ', images[type].type);
         myim := images[type].tool;
         imshape := myim.shape();
#
         its.info('');
         its.info('Testing boundingbox');
         its.info('');
         bb := myim.boundingbox();
         if (is_fail(bb)) {
           return its.stop('boundingbox 1 failed');
         }
         ok := has_field(bb, 'blc') && has_field(bb,'trc') &&
               has_field(bb,'inc') && has_field(bb,'bbShape') &&
               has_field(bb,'regionShape') && has_field(bb,'imageShape');
         if (!ok) { 
            return its.stop('boundingbox record 1 has invalid fields');
         }
         if (!all(bb.blc==[1,1,1]) ||
             !all(bb.trc==imshape) ||
             !all(bb.inc==[1,1,1]) ||
             !all(bb.bbShape==imshape) ||
             !all(bb.regionShape==imshape) ||
             !all(bb.imageShape==imshape)) {
            return its.stop('boundingbox record 1 values are invalid');
         }
#
         blc := [2,3,4];
         trc := [5,8,15];
         inc := [1,2,3];
#
         trc2 := [5,7,13];    # Account for stride
         rShape := [4,3,4];
         r1 := drm.box(blc=blc, trc=trc, inc=inc);
         bb := myim.boundingbox(region=r1);
         if (is_fail(bb)) {
           return its.stop('boundingbox 2 failed');
         }
         if (!all(bb.blc==blc) ||
             !all(bb.trc==trc2) ||
             !all(bb.inc==inc) ||
             !all(bb.bbShape==(trc2-blc+1)) ||
             !all(bb.regionShape==rShape) ||
             !all(bb.imageShape==imshape)) {
            return its.stop('boundingbox record 2 values are invalid');
         }
#
         trc := [100,100,100];
         r1 := drm.box(trc=trc);
         bb := myim.boundingbox(region=r1);
         if (is_fail(bb)) {
           return its.stop('boundingbox 4 failed');
         }
         if (!all(bb.blc==[1,1,1]) ||
             !all(bb.trc==imshape) ||
             !all(bb.inc==[1,1,1]) ||
             !all(bb.bbShape==imshape) ||
             !all(bb.regionShape==imshape) ||
             !all(bb.imageShape==imshape)) {
            return its.stop('boundingbox record 4 values are invalid');
         }
#
         trc := [10,20,30,40,50,60];
         r1 := drm.box(trc=trc);
         bb := myim.boundingbox(region=r1);
         if (!is_fail(bb)) {
           return its.stop('boundingbox 5 unexpectedly did not fail');
         }
#
# {set}restoringbeam
#
         its.info('');
         its.info('Testing {set}restoringbeam');
         its.info('');
         ok := myim.setrestoringbeam(delete=T, log=F);
         if (is_fail(ok)) fail;
         rb := myim.restoringbeam();
         if (length(rb)!=0) fail 'restoring beam was not deleted';
#
         ok := myim.setrestoringbeam (major=10, minor=5, pa=30, log=F);
         if (is_fail(ok)) fail;
         rb := myim.restoringbeam();
         if (is_fail(rb)) fail;
         ok := rb.major.value==10 && rb.minor.value==5 && rb.positionangle.value==30 &&
               rb.major.unit=='arcsec' && rb.minor.unit=='arcsec' && rb.positionangle.unit=='deg';
         if (!ok) fail 'restoringbeam/setrestoringbeam failed reflection test 1';
#
         ok := myim.setrestoringbeam (major=dq.unit(15,'deg'), 
                                      minor=dq.unit(12,'deg'),
                                      pa=dq.unit('.1rad'), log=F);
         if (is_fail(ok)) fail;
         rb := myim.restoringbeam();
         if (is_fail(rb)) fail;
         ok := rb.major.value==15 && rb.minor.value==12 && rb.positionangle.value==.1 &&
               rb.major.unit=='deg' && rb.minor.unit=='deg' && rb.positionangle.unit=='rad';
         if (!ok) fail 'restoringbeam/setrestoringbeam failed reflection test 2';
#
         ok := myim.setrestoringbeam (major=3, minor=2, pa=0.02, log=F);
         if (is_fail(ok)) fail;
         rb := myim.restoringbeam();
         if (is_fail(rb)) fail;
         ok := rb.major.value==3 && rb.minor.value==2 && rb.positionangle.value==.02 &&
               rb.major.unit=='deg' && rb.minor.unit=='deg' && rb.positionangle.unit=='rad';
         if (!ok) fail 'restoringbeam/setrestoringbeam failed reflection test 3';
#
         rb2 := myim.restoringbeam();
         if (is_fail(rb2)) fail;
         rb2.major.value := 10.0;
         ok := myim.setrestoringbeam(beam=rb2, log=F);
         if (is_fail(ok)) fail;      
         rb := myim.restoringbeam();
         if (is_fail(rb)) fail;
         ok := rb.major.value==rb2.major.value && rb.major.unit==rb2.major.unit &&
               rb.minor.value==rb2.minor.value && rb.minor.unit==rb2.minor.unit &&
               rb.positionangle.value==rb2.positionangle.value && 
               rb.positionangle.unit==rb2.positionangle.unit;
         if (!ok) fail 'restoringbeam/setrestoringbeam failed reflection test 4';
#
         ok := myim.setrestoringbeam(delete=T, log=F);
         if (is_fail(ok)) fail;
         rb := myim.restoringbeam();
         if (length(rb)!=0) fail 'restoring beam was not deleted';
#
         if (is_fail(myim.done())) fail;
      }
      ok := its.cleanup(testdir);
      if (is_fail(ok)) fail;
#
# Make image with all coordinate types
#
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
      imname := paste(testdir,'/','imagefromshape.image2',sep='')
      imshape := [10,10,4,10,10];
      myim := imagefromshape(outfile=imname, shape=imshape);
      if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 2 failed');
      }
#
# Coordmeasures.  Just a wrapper for coordsys where testing more thorough
#
      its.info('');
      its.info('Testing coordmeasures');
      its.info('');
      cs := myim.coordsys();
      if (is_fail(cs)) fail;
      rp := cs.referencepixel();
      if (is_fail(rp)) fail;
      if (is_fail(cs.done())) fail;
      w := myim.coordmeasures(rp);
      if (is_fail(w)) {
         return its.stop('coordmeasures failed');
      }
      ok := has_field(w, 'direction') && has_field(w, 'spectral') &&
            has_field(w, 'stokes') && has_field(w, 'linear');
      if (!ok) {
         return its.stop('coordmeasures record has wrong fields');
      }
#
# topixel/toworld are just Coordsys wrappers which tests more thoroughly
#
      its.info('');
      its.info('Testing topixel/toworld');
      its.info('');
      w := myim.toworld(rp, 'nqms');
      if (is_fail(w)) fail;
      p := myim.topixel(w);
      if (is_fail(p)) fail;
#
      ok := myim.done();
      if (is_fail(ok)) {
         return its.stop('Done 2 fails');
      }


###
      return its.cleanup(testdir);
   }

   const its.tests.test16 := function()
#
# Test methods
#   summary, maskhandler
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 16 - summary, maskhandler');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make images of all the wondrous flavours that we have
#   
      root := paste(testdir, '/', 'testimage', sep='')
      imshape := [12,24,20];
      images := its.makeAllImageTypes(imshape, root, includereadonly=T);
      if (is_fail(images)) fail;
#   
# Loop over all image types
#
      its.info('');
      its.info('Testing summary');
      types := field_names(images);
      for (type in types) {
         its.info('');
         its.info('Testing Image type ', images[type].type);
         myim := images[type].tool;
         imshape := myim.shape()
#
# Summary
#
         local header;
         ok := myim.summary(header, list=F);
         if (is_fail(ok)) fail;
         nfields := 13;
         if (!has_field(header, 'ndim') ||
             !has_field(header, 'shape') ||
             !has_field(header, 'tileshape') ||
             !has_field(header, 'axisnames') ||
             !has_field(header, 'refpix') ||
             !has_field(header, 'refval') ||
             !has_field(header, 'incr') ||
             !has_field(header, 'axisunits') ||
             !has_field(header, 'unit') ||
             !has_field(header, 'imagetype') ||
             !has_field(header, 'hasmask') ||
             !has_field(header, 'defaultmask') ||
             !has_field(header, 'masks')) {
            return its.stop('summary record is invalid');
         }
         if (has_field(header, 'restoringbeam')) nfields +:= 1;
         if (length(field_names(header))!=nfields) {
            return its.stop('summary record has the wrong number of fields');
         }
#
         if (is_fail(myim.done())) fail;
      }
      ok := its.cleanup(testdir);
      if (is_fail(ok)) fail;
# 
# Masks
#
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
      imshape := [12,24,20];
      images := its.makeAllImageTypes(imshape, root, includereadonly=F);
      if (is_fail(images)) fail;
#   
# Loop over all image types
#
      its.info('');
      its.info('Testing maskhandler');
      local pixels, mask;
      types := field_names(images);
      for (type in types) {
         its.info('');
         its.info('Testing Image type ', images[type].type);
         myim := images[type].tool;
         imshape := myim.shape()
#
         myim2 := imagefromshape(shape=imshape);
         if (is_fail(myim2)) {
           return its.stop('imagefromshape constructor 2 failed');
         }
#
         ok := myim.getregion(pixels, mask);
         if (is_fail(ok)) {
            return its.stop('getregion 1 failed');
         }
#
         ok := myim.putregion(pixels, mask);
         if (is_fail(ok)) {
            return its.stop('putregion 1a failed');
         }
         ok := myim2.putregion(pixels, mask);
         if (is_fail(ok)) {
            return its.stop('putregion 1b failed');
         }
#
         names := myim.maskhandler('get');
         if (is_fail(names)) {
            return its.stop('maskhandler 1a failed');
         }
         if (length(names)!=1) {
            return its.stop('maskhandler 1a unexpectedly recovered more than 1 mask');
         }
         names := myim2.maskhandler('get');
         if (is_fail(names)) {
            return its.stop('maskhandler 1b failed');
         }
         if (length(names)!=1) {
            return its.stop('maskhandler 1b unexpectedly recovered more than 1 mask');
         }
#
         ok := myim.maskhandler('set', name=names);
         if (is_fail(ok)) {
            return its.stop('maskhandler 2a failed');
         }
         ok := myim2.maskhandler('set', name=names);
         if (is_fail(ok)) {
            return its.stop('maskhandler 2b failed');
         }
#
         defname := myim.maskhandler('default');
         if (is_fail(defname)) {
            return its.stop('maskhandler 3a failed');
         }
         if (names!=defname) {
            return its.stop('maskhandler 3a did not recover the default mask name');
         }
         defname := myim2.maskhandler('default');
         if (is_fail(defname)) {
            return its.stop('maskhandler 3b failed');
         }
         if (names!=defname) {
            return its.stop('maskhandler 3b did not recover the default mask name');
         }
#
         names := [names, 'fish'];
         ok := myim.maskhandler('rename', names);
         if (is_fail(ok)) {
            return its.stop('maskhandler 4a failed');
         }
         ok := myim2.maskhandler('rename', names);
         if (is_fail(ok)) {
            return its.stop('maskhandler 4b failed');
         }
#
         names := myim.maskhandler('get');
         if (is_fail(names)) {
            return its.stop('maskhandler 5a failed');
         }
         if (length(names)!=1) {
            return its.stop('maskhandler 5a unexpectedly recovered more than 1 mask');
         }
         if (names!='fish') {
            return its.stop('maskhandler 5a did not recover the correct mask name');
         }
         names := myim2.maskhandler('get');
         if (is_fail(names)) {
            return its.stop('maskhandler 5b failed');
         }
         if (length(names)!=1) {
            return its.stop('maskhandler 5b unexpectedly recovered more than 1 mask');
         }
         if (names!='fish') {
            return its.stop('maskhandler 5b did not recover the correct mask name');
         }
#
         names := ['fish', 'mask1'];
         ok := myim.maskhandler('copy', names);
         if (is_fail(ok)) {
            return its.stop('maskhandler 6a failed');
         }
         ok := myim2.maskhandler('copy', names);
         if (is_fail(ok)) {
            return its.stop('maskhandler 6b failed');
         }
#
         names := myim.maskhandler('get');
         if (is_fail(names)) {
            return its.stop('maskhandler 7a failed');
         }
         if (length(names)!=2) {
            return its.stop('maskhandler 7a unexpectedly recovered more than 2 mask');
         }
         if (names[1] !='fish' || names[2]!='mask1') {
            return its.stop('maskhandler 7a did not recover the correct mask names');
         }
         names := myim2.maskhandler('get');
         if (is_fail(names)) {
            return its.stop('maskhandler 7b failed');
         }
         if (length(names)!=2) {
            return its.stop('maskhandler 7b unexpectedly recovered more than 2 mask');
         }
         if (names[1] !='fish' || names[2]!='mask1') {
            return its.stop('maskhandler 7b did not recover the correct mask names');
         }
#
         ok := myim.maskhandler('set', 'mask1');
         if (is_fail(ok)) {
            return its.stop('maskhandler 8b failed');
         }
         ok := myim2.maskhandler('set', 'mask1');
         if (is_fail(ok)) {
            return its.stop('maskhandler 8b failed');
         }
#
         defname := myim.maskhandler('default');
         if (is_fail(defname)) {
            return its.stop('maskhandler 9a failed');
         }
         if (defname !='mask1') {
            return its.stop('maskhandler 9a did not recover the correct default mask name');
         }
         defname := myim2.maskhandler('default');
         if (is_fail(defname)) {
            return its.stop('maskhandler 9b failed');
         }
         if (defname !='mask1') {
            return its.stop('maskhandler 9b did not recover the correct default mask name');
         }
#
         names := myim.maskhandler('get');
         if (is_fail(names)) {
            return its.stop('maskhandler 10a failed');
         }
         names := myim2.maskhandler('get');
         if (is_fail(names)) {
            return its.stop('maskhandler 10b failed');
         }
#
         ok := myim.maskhandler('delete', names);
         if (is_fail(ok)) {
            return its.stop('maskhandler 11a failed');
         }
         ok := myim2.maskhandler('delete', names);
         if (is_fail(ok)) {
            return its.stop('maskhandler 11b failed');
         }
#
         names := myim.maskhandler('get');
         if (is_fail(names)) {
            return its.stop('maskhandler 12a failed');
         }
         if (length(names)!=0) {
            its.return('maskhandler 12a failed to delete the masks');
         }
         names := myim2.maskhandler('get');
         if (is_fail(names)) {
            return its.stop('maskhandler 12b failed');
         }
         if (length(names)!=0) {
            its.return('maskhandler 12b failed to delete the masks');
         }
         if (is_fail(myim2.done())) fail;
#
         ok := myim.done();
      }

###
      return its.cleanup(testdir);
   }


   const its.tests.test17 := function()
#
# Test methods
#   subimage, insert
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 17 - subimage, insert');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Make image

     imname := paste(testdir,'/','imagefromshape.image1',sep='')
     imshape := [10,20,6];
     myim := [=];
     myim := imagefromshape(outfile=imname, shape=imshape);
     if (is_fail(myim)) {
       return its.stop('imagefromshape constructor 1 failed');
     }
#
# Subimage
#
     its.info('');
     its.info('Testing subimage function');
     imname2 := paste(testdir,'/','subimage.image',sep='')
     local pixels, mask;
     ok := myim.getregion(pixels, mask);
     if (is_fail(ok)) {
        return its.stop('getregion 1 failed');
     }
     mask[imshape[1]/2,imshape[2]/2,imshape[3]/2] := F;
     ok := myim.putregion(pixelmask=mask);
     if (is_fail(ok)) {
        return its.stop('putregion 1 failed');
     }
#
     dowait := F;
     myim2 := myim.subimage(outfile=imname2, region='doggies');
     if (!is_fail(myim2)) {
        return its.stop('subimage 1 unexpectedly did not fail');
     }
#
     r1 := drm.quarter();
     myim2 := myim.subimage(outfile=imname2, region=r1);
     if (is_fail(myim2)) {
        return its.stop('subimage 2 failed');
     }
#
     bb := myim.boundingbox(region=r1);
     shape := bb.regionShape;
     shape2 := myim2.shape();
     if (!all(shape==shape2)) {
         return its.stop ('Output subimage has wrong shape'); 
     }   
#
     ok := myim.getregion(pixels, mask, region=r1);
     if (is_fail(ok)) {
        return its.stop('getregion 2 failed');
     }
     local pixels2, mask2;
     ok := myim2.getregion(pixels2, mask2);
     if (is_fail(ok)) {
        return its.stop('getregion 3 failed');
     }
     if (!all(pixels==pixels2)) {
         return its.stop('The data values are wrong in the subimage');
     }
     if (!all(mask==mask2)) {
         return its.stop('The mask values are wrong in the subimage');
     }
     ok := myim2.delete(done=T);
     if (is_fail(ok)) {
        return its.stop('Failed to delete', imname2);
     }
     ok := myim.done();
     if (is_fail(ok)) {
        return its.stop('Done 1 failed');
     }
#
# Insert
#
     its.info('');
     its.info('Testing insert function');
     imname := paste(testdir,'/','imagefromshape.image',sep='')
     a := array(1,10,20);
     myim := [=];
     myim := imagefromarray(outfile=imname, pixels=a);
     if (is_fail(myim)) {
       return its.stop('imagefromarray constructor 2 failed');
     }
#
     ok := myim.insert(region='fish');
     if (!is_fail(ok)) {
       return its.stop('insert 1 unexpectedly did not fail')
     }
#
     pixels := myim.getchunk();
     if (is_fail(pixels)) {
       return its.stop('getchunk 1 failed')
     }
#
     padshape := myim.shape() + [2,2];
     padname := paste(testdir,'/','insert.image',sep='')
     myim2 := imagefromshape(shape=padshape);
     if (is_fail(myim2)) fail;
#
     ok := myim2.insert(infile=myim.name(F), locate=[1,1,1])
     if (is_fail(ok)) fail;
     pixels2 := myim2.getchunk();
     if (is_fail(pixels2)) {
       return its.stop('getchunk 2 failed')
     }
     pixels3 := pixels2[1:(padshape[1]-2), 1:(padshape[2]-2)];
     if (!all(pixels3==1.0)) {
       return its.stop('inserted image pixels have wrong value (1)')
     }
#
     myim2.set(0.0);
     ok := myim2.insert(infile=myim.name(F));            # Placed symmetrically
     if (is_fail(ok)) fail;
     pixels2 := myim2.getchunk();
     if (is_fail(pixels2)) fail;
     if (pixels2[1,1]!=0.0) {
       return its.stop('inserted image pixels have wrong value (3)')
     }
     if (!all(pixels2[2:(padshape[1]-1),2:(padshape[2]-1)]==1.0)) {
       return its.stop('inserted image pixels have wrong value (2)')
     }
     if (is_fail(myim2.done())) fail;
#
     ok := myim.done();
     if (is_fail(ok)) {
        return its.stop('Done 3 failed');
     }

###
      return its.cleanup(testdir);
   }

   const its.tests.test18 := function()
#
# Test methods
#   hanning
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 18 - hanning');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Make image

     imname := paste(testdir,'/','imagefromshape.image',sep='')
     imshape := [10,20];
     myim := [=];
     myim := imagefromshape(outfile=imname, shape=imshape);
     if (is_fail(myim)) {
       return its.stop('imagefromshape constructor 1 failed');
     }
     pixels := myim.getchunk();
     if (is_fail(pixels)) {
       return its.stop('getchunk 1 failed')
     }
     pixels[pixels>-10000] := 1;
     ok := myim.putchunk(pixels);
     if (is_fail(ok)) {
       return its.stop('putchunk 1 failed')
     }
#
     myim2 := myim.hanning(region='fish');     
     if (!is_fail(myim2)) {
       return its.stop('hanning 1 unexpectedly did not fail')
     }
     myim2 := myim.hanning(axis=20);
     if (!is_fail(myim2)) {
       return its.stop('hanning 2 unexpectedly did not fail')
     }
     myim2 := myim.hanning(drop='fish');
     if (!is_fail(myim2)) {
       return its.stop('hanning 3 unexpectedly did not fail')
     }
     myim2 := myim.hanning(outfile=[1,2,3]);
     if (!is_fail(myim2)) {
       return its.stop('hanning 4 unexpectedly did not fail')
     }
#
     hanname := paste(testdir,'/','hanning.image',sep='')
     myim2 := myim.hanning(outfile=hanname, axis=1, drop=F);
     if (is_fail(myim2)) {
       fail;
       return its.stop('hanning 5 failed');
     }
     if (!all(myim2.shape()==myim.shape())) {
        return its.stop('Output image has wrong shape (1)');
     }
     pixels2 := myim2.getchunk();
     if (is_fail(pixels2)) {
       return its.stop('getchunk 2 failed')
     }
     if (!all(pixels2==1)) {
       return its.stop('hanning image pixels have wrong value (1)')
     }
     ok := myim2.delete(done=T);
     if (is_fail(ok)) {
        return its.stop('Failed to delete', hanname);
     }
#
     myim2 := myim.hanning(outfile=hanname, axis=1, drop=T);
     if (is_fail(myim2)) {
       return its.stop('hanning 6 failed');
     }
     shape2 := [myim.shape()[1]/2-1,myim.shape()[2]];
     if (!all(myim2.shape()==shape2)) {
        return its.stop('Output image has wrong shape (2)');
     }
     pixels2 := myim2.getchunk();
     if (is_fail(pixels2)) {
       return its.stop('getchunk 3 failed')
     }
     if (!all(pixels2==1)) {
       return its.stop('Hanning image pixels have wrong value (2)')
     }
     ok := myim2.delete(done=T);
     if (is_fail(ok)) {
        return its.stop('Failed to delete', hanname);
     }
#
     local mask;
     ok := myim.getregion(pixels, mask);
     if (is_fail(ok)) {
       return its.stop('getregion 1 failed')
     }
     mask[1,1] := F;
     mask[2,1] := F;
     mask[3,1] := F;
     mask[4,1] := F;
     ok := myim.putregion(pixelmask=mask);
     if (is_fail(ok)) {
       return its.stop('putregion 1 failed')
     }
     myim2 := myim.hanning(outfile=hanname, axis=1, drop=F);
     if (is_fail(myim2)) {
       return its.stop('hanning 7 failed');
     }
     local mask2;
     ok := myim2.getregion(pixels2, mask2);
     if (is_fail(ok)) {
       return its.stop('getregion 2 failed')
     }
     ok := mask2[1,1]==F && mask2[2,1]==F && mask2[3,1]==F && mask2[4,1]==F;
     if (!ok) {
       return its.stop('Hanning image mask is wrong (1)')
     }
     ok := pixels2[1,1]==0 && pixels2[2,1]==0 && pixels2[3,1]==0 && pixels2[4,1]==0.25;
     if (!ok) {
       return its.stop('Hanning image pixels have wrong value (3)')
     }
     ok := myim2.done();
     if (is_fail(ok)) {
        return its.stop('Done 1 failed');
     }
#
     ok := myim.done();
     if (is_fail(ok)) {
        return its.stop('Done 2 failed');
     }

###

      return its.cleanup(testdir);
   }

   const its.tests.test19 := function()
#
# Test methods
#   convolve
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 19 - convolve');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Make image

     imname := paste(testdir,'/','imagefromshape.image',sep='')
     imshape := [10,10];
     myim := [=];
     myim := imagefromshape(outfile=imname, shape=imshape);
     if (is_fail(myim)) {
       return its.stop('imagefromshape constructor 1 failed');
     }
     pixels := myim.getchunk();
     if (is_fail(pixels)) {
       return its.stop('getchunk 1 failed')
     }
     pixels[pixels>-10000] := 1;
     ok := myim.putchunk(pixels);
     if (is_fail(ok)) {
       return its.stop('putchunk 1 failed')
     }
#
     myim2 := myim.convolve(region='fish');     
     if (!is_fail(myim2)) {
       return its.stop('convolve 1 unexpectedly did not fail')
     }
     kernel := array(0,2,4,6,8);
     myim2 := myim.convolve(kernel=kernel);
     if (!is_fail(myim2)) {
       return its.stop('convolve 3 unexpectedly did not fail')
     }
     myim2 := myim.convolve(outfile=[1,2,3]);
     if (!is_fail(myim2)) {
       return its.stop('convolve 4 unexpectedly did not fail')
     }
#
     outname := paste(testdir,'/','convolve.image',sep='')
     kernel := array(0.0,3,3);
     kernel[2,2] := 1;                   # Delta function
#
     myim2 := myim.convolve(outfile=outname, kernel=kernel);
     if (is_fail(myim2)) {
       return its.stop('convolve 5 failed');
     }
     if (!all(myim2.shape()==myim.shape())) {
        return its.stop('Output image has wrong shape (1)');
     }
     pixels2 := myim2.getchunk();
     if (is_fail(pixels2)) {
       return its.stop('getchunk 2 failed')
     }
     if (!all((abs(pixels2-pixels) < 0.0001))) {
       return its.stop('convolve image pixels have wrong value (1)')
     }
     ok := myim2.delete(done=T);
     if (is_fail(ok)) {
        return its.stop('Failed to delete', outname);
     }
#
     kernelname := paste(testdir,'/','convolve.kernel',sep='')
     kernelimage := imagefromarray(outfile=kernelname, pixels=kernel);
     kernelimage.done();
     myim2 := myim.convolve(outfile=outname, kernel=kernelname);
     if (is_fail(myim2)) {
       return its.stop('convolve 5b failed');
     }
     if (!all(myim2.shape()==myim.shape())) {
        return its.stop('Output image has wrong shape (1)');
     }
     pixels2 := myim2.getchunk();
     if (is_fail(pixels2)) {
       return its.stop('getchunk 2b failed')
     }
     if (!all((abs(pixels2-pixels) < 0.0001))) {
       return its.stop('convolve image pixels have wrong value (1b)')
     }
     ok := myim2.delete(done=T);
     if (is_fail(ok)) {
        return its.stop('Failed to delete', outname);
     }
#
     r1 := drm.box([1,1], [9,9]);
     myim2 := myim.convolve(outfile=outname, kernel=kernel, region=r1);
     if (is_fail(myim2)) {
       return its.stop('convolve 6 failed');
     }
     if (!all(myim2.shape()==[9,9])) {
        return its.stop('Output image has wrong shape (2)');
     }
     pixels2 := myim2.getchunk();
     if (is_fail(pixels2)) {
       return its.stop('getchunk 3 failed')
     }
     local mask;
     ok := myim.getregion(pixels, mask, region=r1);
     if (is_fail(ok)) {
       return its.stop('getregion 3 failed')
     }
     if (!all((abs(pixels2-pixels) < 0.0001))) {
       return its.stop('convolve image pixels have wrong value (2)')
     }
     ok := myim2.delete(done=T);
     if (is_fail(ok)) {
        return its.stop('Failed to delete', outname);
     }
#
     local mask;
     ok := myim.getregion(pixels, mask);
     if (is_fail(ok)) {
       return its.stop('getregion 1 failed')
     }
     mask[1,1] := F;
     mask[2,1] := F;
     mask[1,2] := F;
     mask[2,2] := F;
     ok := myim.putregion(pixelmask=mask);
     if (is_fail(ok)) {
       return its.stop('putregion 1 failed')
     }
     myim2 := myim.convolve(outfile=outname, kernel=kernel);
     if (is_fail(myim2)) {
       return its.stop('convolve 7 failed');
     }
     local mask2;
     ok := myim2.getregion(pixels2, mask2);
     if (is_fail(ok)) {
       return its.stop('getregion 2 failed')
     }
     ok := mask2[1,1]==F && mask2[2,1]==F && mask2[1,2]==F && mask2[2,2]==F;
     if (!ok) {
       return its.stop('convolved image mask is wrong (1)')
     }
     ok := abs(pixels2[1,1])<0.0001 && abs(pixels2[2,1])<0.0001 && abs(pixels2[1,2])<0.0001 &&
           abs(pixels2[2,2])<0.0001 && abs(pixels2[3,3]-1.0)<0.0001;
     if (!ok) {
       return its.stop('convolved image pixels have wrong value (3)')
     }
     ok := myim2.done();
     if (is_fail(ok)) {
        return its.stop('Done 1 failed');
     }
#
     ok := myim.done();
     if (is_fail(ok)) {
        return its.stop('Done 2 failed');
     }
###

      return its.cleanup(testdir);
   }


   const its.tests.test20 := function()
#
# Test methods
#   sepconvolve
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 20 - sepconvolve');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Make image

     imname := paste(testdir,'/','imagefromshape.image',sep='')
     imshape := [128,128];
     centre := imshape/2;
     myim := [=];
     myim := imagefromshape(outfile=imname, shape=imshape);
     if (is_fail(myim)) {
       return its.stop('imagefromshape constructor 1 failed');
     }
     pixels := myim.getchunk();
     if (is_fail(pixels)) {
       return its.stop('getchunk 1 failed')
     }
     pixels[centre] := 1;
     pixels[centre[1]-1, centre[2]-1] := 1;
     pixels[centre[1]-1, centre[2]+1] := 1;
     pixels[centre[1]+1, centre[2]+1] := 1;
     pixels[centre[1]+1, centre[2]+1] := 1;
#
     ok := myim.putchunk(pixels);
     if (is_fail(ok)) {
       return its.stop('putchunk 1 failed')
     }
#
     myim2 := myim.sepconvolve(region='fish');     
     if (!is_fail(myim2)) {
       return its.stop('sepconvolve 1 unexpectedly did not fail')
     }
     myim2 := myim.sepconvolve(types="doggies", widths=[1], axes=[1]);
     if (!is_fail(myim2)) {
       return its.stop('sepconvolve 2 unexpectedly did not fail')
     }
     myim2 := myim.sepconvolve(types="gauss gauss gauss gauss",
                               widths=[5,5,5,5], axes=[1,2,3,4]);
     if (!is_fail(myim2)) {
       return its.stop('sepconvolve 3 unexpectedly did not fail')
     }
     myim2 := myim.sepconvolve(types="gauss gauss", widths=[1], axes=[1,2]);
     if (!is_fail(myim2)) {
       return its.stop('sepconvolve 4 unexpectedly did not fail')
     }
     myim2 := myim.sepconvolve(outfile=[1,2,3]);
     if (!is_fail(myim2)) {
       return its.stop('sepconvolve 5 unexpectedly did not fail')
     }
#
     outname2 := paste(testdir,'/','sepconvolve.image',sep='')
     myim2 := myim.sepconvolve(outfile=outname2, axes=[1,2], 
                               types="gauss box", widths=[3,3]);
     if (is_fail(myim2)) {
       return its.stop('sepconvolve 6 failed');
     }
     ok := myim2.delete(done=T);
     if (is_fail(ok)) {
        return its.stop('Failed to delete', outname2);
     }
#
     outname2 := paste(testdir,'/','sepconvolve.image',sep='')
     myim2 := myim.sepconvolve(outfile=outname2, axes=[1,2], 
                               types="hann gauss", widths=[3,10]);
     if (is_fail(myim2)) fail;
     ok := myim2.delete(done=T);
     if (is_fail(ok)) {
        return its.stop('Failed to delete', outname2);
     }
#
     myim2 := myim.sepconvolve(outfile=outname2, axes=[1,2], 
                               types="gauss gauss", widths=[5,5]);
     if (is_fail(myim2)) fail;
     local stats1, stats2;
     ok := myim.statistics(statsout=stats1, list=F);     
     if (is_fail(ok)) fail;
     ok := myim2.statistics(statsout=stats2, list=F);
     if (is_fail(ok)) fail;
#     if (!(abs((stats1.sum)-(stats2.sum))<0.0001)) {
#        return its.stop('Convolution did not preserve flux (1)');
#     }
     ok := myim2.delete(done=T);
     if (is_fail(ok)) {
        return its.stop('Failed to delete', outname2);
     }
#
     cen := imshape/2;
     blc := cen - [10,10]; trc := cen + [10,10];
     r1 := drm.box(blc, trc);
     myim2 := myim.sepconvolve(outfile=outname2, axes=[1], 
                               types="hann", widths=[3], region=r1);
     if (is_fail(myim2)) fail;
     if (!all(myim2.shape()==(trc-blc+[1,1]))) {
        return its.stop('Output image has wrong shape (2)');
     }
     pixels2 := myim2.getchunk();
     if (is_fail(pixels2)) {
       return its.stop('getchunk 3 failed')
     }
#     if (!(abs(sum(pixels)-sum(pixels2))<0.0001)) {
#        return its.stop('Convolution did not preserve flux (2)');
#     }
     ok := myim2.delete(done=T);
     if (is_fail(ok)) {
        return its.stop('Failed to delete', outname2);
     }
#
     local mask;
     ok := myim.getregion(pixels, mask);
     if (is_fail(ok)) fail;
     mask[1,1] := F;
     mask[2,1] := F;
     mask[1,2] := F;
     mask[2,2] := F;
     ok := myim.putregion(pixels=pixels, pixelmask=mask);
     if (is_fail(ok)) {
       return its.stop('putregion 1 failed')
     }
     myim2 := myim.sepconvolve(outfile=outname2, types="gauss",
                               widths=[10], axes=[1]);
     if (is_fail(myim2)) {
       return its.stop('sepconvolve 8 failed');
     }
     local mask2;
     ok := myim2.getregion(pixels2, mask2);
     if (is_fail(ok)) {
       return its.stop('getregion 2 failed')
     }
     ok := mask2[1,1]==F && mask2[2,1]==F && mask2[1,2]==F && mask2[2,2]==F;
     if (!ok) {
       return its.stop('convolved image mask is wrong (1)')
     }
     ok := myim2.done();
     if (is_fail(ok)) {
        return its.stop('Done 1 failed');
     }
#
# Some more tests just on the widths interface.
#
     myim2 := myim.sepconvolve(widths=[10,10], axes=[1,2]);
     if (is_fail(myim2)) return its.stop ('sepconvolve 9 failed');
     if (is_fail(myim2.done())) fail;
#
     myim2 := myim.sepconvolve(widths="10 10", axes=[1,2]);
     if (is_fail(myim2)) return its.stop ('sepconvolve 10 failed');
     if (is_fail(myim2.done())) fail;
#
     myim2 := myim.sepconvolve(widths="0.01rad 10pix", axes=[1,2]);
     if (is_fail(myim2)) return its.stop ('sepconvolve 11 failed');
     if (is_fail(myim2.done())) fail;
#
     myim2 := myim.sepconvolve(widths="20 10pix", axes=[1,2]);
     if (is_fail(myim2)) return its.stop ('sepconvolve 12 failed');
     if (is_fail(myim2.done())) fail;
#
     myim2 := myim.sepconvolve(widths='10 10', axes=[1,2]);
     if (is_fail(myim2)) {
       return its.stop ('sepconvolve 13 failed');
     }
     if (is_fail(myim2.done())) fail;
#
     widths := dq.quantity("0.01rad 0.02rad");
     myim2 := myim.sepconvolve(widths=widths, axes=[1,2]);
     if (is_fail(myim2)) return its.stop ('sepconvolve 14 failed');
     if (is_fail(myim2.done())) fail;
#
     ok := myim.done();
     if (is_fail(ok)) {
        return its.stop('Done 2 failed');
     }
###

      return its.cleanup(testdir);
   }


   const its.tests.test21 := function()
#
# Test methods
#   lel
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 21 - LEL');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Define some arrays to be stored in the test images.
# Define 2 local symbols to hold the results.
# Delete the image files in case they are still present.

      a1 := array(1:96, 8,12);
      a2 := a1 + 100;
      local mask, pixels, names;

# Create 2 images.
# Keep the first one in a global symbol (with a strange name),
# so it can be used in a LEL expression with the $-notation.

      imname1 := paste(testdir,'/','im.1',sep='')      
      global global_iet_im1 := imagefromarray(imname1, a1);
      if (is_fail(global_iet_im1)) {
         return its.stop('imagefromarray failed (1)');
      }
      imname2 := paste(testdir,'/','im.2',sep='')      
      im2 := imagefromarray(imname2, a2);
      if (is_fail(im2)) {
         ok := global_iet_im1.done();
         return its.stop('imagefromarray failed (2)');
      }
      ok := im2.done();
      if (is_fail(ok)) {
         return its.stop('done failed (1)');
      }

# Form a simple expression and check if the result is correct.

      ex := spaste('"', imname1, '" + "', imname2, '"');
      global global_iet_ex1 := imagecalc(pixels=ex);
      if (is_fail(global_iet_ex1)) {
  	ok := global_iet_im1.done();
        return its.stop('expr failed (1)');
      }
      pixels := global_iet_ex1.getchunk();
      if (! all(pixels == a1+a2)) {
  	ok := global_iet_im1.done();
	ok := global_iet_ex1.done();
	return its.stop('expr values are wrong (1)');
      }

# Now form and check an expression using the $-notation.
# The mask should be all true (in fact, there is no mask).

      ex2 := imagecalc(pixels='$global_iet_ex1 - $global_iet_im1');
      ok := global_iet_ex1.done();
      if (is_fail(ok)) {
         return its.stop('done failed (2)');
      }
      if (is_fail(ex2)) {
	ok := global_iet_im1.done();
        return its.stop('expr failed (2)');
      }
      ok := ex2.getregion(pixels, mask);
      if (is_fail(ok)) {
         return its.stop('getregion failed (1)');
      }
      ok := ex2.done();
      if (! all(pixels == a2)) {
	ok := global_iet_im1.done();
	return its.stop('expr values are wrong (2)');
      }
      if (! all(mask)) {
	ok := global_iet_im1.done();
	return its.stop('expr mask is wrong (1)');
      }

# Define a region as a global symbol.
# Use it in an expression using the $-notation.
# The mask should be all true (in fact, there is no mask).

      global global_iet_reg1 := drm.quarter();
      ex3 := imagecalc(pixels='$global_iet_im1[$global_iet_reg1]');
      if (is_fail(ex3)) {
	ok := global_iet_im1.done();
        return its.stop('expr failed (3)');
      }
      ok := ex3.getregion(pixels, mask);
##    ex3.maskhandler ("get", names);
      ok := ex3.done();
      if (! all(pixels == a1[3:6,4:9])) {
  	ok := global_iet_im1.done();
	return its.stop('expr values are wrong (3)');
      }
      if (! all(mask)) {
	ok := global_iet_im1.done();
	return its.stop('expr mask is wrong (2)');
      }
##    if (len(names) != 0) {
##	global_iet_im1.done();
##	fail ("imageexprtest: there is a mask in '$im1[$reg1]'");
##    }

# Close the first image.
# Note that after im4.done te image server might be closed because
# there are no active objects anymore.

      imname4 := paste(testdir,'/','im.4',sep='');
      ex := spaste('"', imname1, '"[', '"', imname1, '"%2==0]');
      im4 := imagecalc (imname4, ex);
      if (is_fail(im4)) {
         return its.stop('imagecalc failed (1)');
      }
      ok := im4.getregion(pixels, mask);
      ok := im4.maskhandler ("get", names);
      ok := im4.done();
      if (! all(pixels == a1)) {
	ok := global_iet_im1.done();
	return its.stop('imagecalc values are wrong (1)');
      }
      if (! all(mask == (a1%2==0))) {
	ok := global_iet_im1.done();
	return its.stop('imagecalc mask is wrong (1)');
      }
      if (len(names) != 1) {
	ok := global_iet_im1.done();
	return its.stop('imagecalc has too many masks (1)');
      }

# Move the image to test if its mask table can still be found
# and if the default mask was set.

      imname5:= paste(testdir,'/','im.5',sep='');
      ok := dos.move (imname4, imname5);
      ex := spaste('"', imname5, '"');
      ex3 := imagecalc(pixels=ex);
      if (is_fail(ex3)) {
	ok := global_iet_im1.done();
	return its.stop('expr  failed (4)');
      }
      ok := ex3.getregion(pixels, mask);
      ok := ex3.done();
      if (! all(pixels == a1)) {
	ok := global_iet_im1.done();
	return its.stop ('expr values are wrong (4)');
      }
      if (! all(mask == (a1%2==0))) {
	ok := global_iet_im1.done();
	return its.stop('expr mask is wrong (3)');
      }

# Now issue some incorrect expressions.

      ex := spaste('"', imname1, '"+', '"im..2"');
      ex4 := imagecalc(pixels=ex);
      if (! is_fail(ex4)) {
	ok := ex4.close();
	ok := global_iet_im1.done();
	return its.stop('expr unexpectedly did not fail (5)');
      }
      ex := spaste('"', imname2, '" - max("', imname1, 
                   '", "', imname2, '", "', imname1, '")');
      ex4 := imagecalc(pixels=ex);
      if (! is_fail(ex4)) {
	ex4.close();
	global_iet_im1.done();
	return its.stop('expr unexpectedly did not fail (5)');
      }

# Close last open image.
# Remove the image files created.
# Note that im.4 has been moved into im.1.

      ok := global_iet_im1.done();
      ok := dos.remove (imname1, T, F);
      ok := dos.remove (imname2, T, F);

# Check if we can create im.1 and im.2 again.
# If an image was left open, that will fail.

      im1 := imagefromarray(imname1, a1);
      if (is_fail(im1)) {
	return its.stop ('Image', imname1, ' was still open');
      }
      im2 := imagefromarray(imname2, a2);
      if (is_fail(im2)) {
	ok := im1.done();
	return its.stop ('Image', imname2, ' was still open');
      }
      ok := im1.done();
      ok := im2.done();
      ok := dos.remove (imname1, T, F);
      ok := dos.remove (imname2, T, F);

###
      return its.cleanup(testdir);

  }

   const its.tests.test22 := function()
#
# Test methods
#   statistics
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 22 - statistics');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Make image

     pixels := array(0.0, 10, 20);
     pixels[1,1] := -100;
     pixels[10,20] := 100;
     imname := paste(testdir,'/','imagefromarray.image',sep='')
     myim := imagefromarray(outfile=imname, pixels=pixels);
     if (is_fail(myim)) {
       return its.stop('imagefromarray constructor 1 failed');
     }
#
     ok := myim.statistics(axes=[10,20]);
     if (!is_fail(ok)) {
        return its.stop('Statistics unexpectedly did not fail (1)');
     }
     ok := myim.statistics(includepix=[-100,100], excludepix=[-100,100]);
     if (!is_fail(ok)) {
        return its.stop('Statistics unexpectedly did not fail (2)');
     }
#
     local stats;
     ok := myim.statistics(statsout=stats, list=F);
     if (is_fail(ok)) {
        return its.stop('Statistics failed (1)');
     }
     ok := has_field(stats,'npts') && has_field(stats, 'sum') && 
           has_field(stats,'sumsq') && 
           has_field(stats,'min') &&
           has_field(stats,'max') && has_field(stats,'mean') &&
           has_field(stats,'sigma') && has_field(stats,'rms');
     if (!ok) {
        return its.stop('Statistics record does not have the correct fields');
     }
     ok := stats.npts==prod(myim.shape()) &&
           stats.sum==0.0 && stats.sumsq==2e4 &&
           stats.min==-100.0 && stats.max==100.0 &&
           stats.mean==0.0;
     if (!ok) {
        return its.stop('Statistics values are wrong (1)');
     }
##
     blc := [1,1]; trc := [5,5];
     r1 := drm.box(blc=blc, trc=trc);
     ok := myim.statistics(statsout=stats, list=F, region=r1);
     if (is_fail(ok)) {
        return its.stop('Statistics failed (2)');
     }
     ok := stats.npts==prod(trc-blc+1) &&
           stats.sum==-100.0 && stats.sumsq==10000.0 &&
           stats.min==-100.0 && stats.max==0.0 &&
           stats.mean==(-100/stats.npts);
     if (!ok) {
        return its.stop('Statistics values are wrong (2)');
     }
##
     ok := myim.statistics(statsout=stats, list=F, axes=[1]);
     if (is_fail(ok)) {
        return its.stop('Statistics failed (3)');
     }
     imshape := myim.shape();
     ok := length(stats.npts)==imshape[2] &&
           length(stats.sum)==imshape[2] &&
           length(stats.sumsq)==imshape[2] &&
           length(stats.min)==imshape[2] &&
           length(stats.max)==imshape[2] &&
           length(stats.mean)==imshape[2];
     if (!ok) {
        return its.stop('Statistics record fields are wrong length (1)');
     }
     ok := all(stats.npts==10) &&
           stats.sum[1]==-100 && stats.sum[imshape[2]]==100 &&
           all(stats.sum[2:(imshape[2]-1)]==0) &&
           stats.sumsq[1]==10000 && stats.sumsq[imshape[2]]==10000 &&
           all(stats.sumsq[2:(imshape[2]-1)]==0) &&
           stats.min[1]==-100 && all(stats.min[2:imshape[2]]==0) &&
           stats.max[imshape[2]]==100 && all(stats.max[1:(imshape[2]-1)]==0) &&
           stats.mean[1]==-10 && stats.mean[imshape[2]]==10 &&
           all(stats.mean[2:(imshape[2]-1)]==0);
     if (!ok) {
        return its.stop('Statistics values are wrong (3)');
     }
##
     ok := myim.statistics(statsout=stats, list=F, includepix=[-5,5]);
     if (is_fail(ok)) {
        return its.stop('Statistics failed (4)');
     }
     ok := stats.npts==(prod(imshape)-2) &&
           stats.sum==0.0 && stats.sumsq==0.0 &&
           stats.min==0.0 && stats.max==0.0 &&
           stats.mean==0.0;
     if (!ok) {
        return its.stop('Statistics values are wrong (4)');
     }
#
     ok := myim.statistics(statsout=stats, list=F, excludepix=[-5,5]);
     if (is_fail(ok)) {
        return its.stop('Statistics failed (4)');
     }
     ok := stats.npts==2 &&
           stats.sum==0.0 && stats.sumsq==20000.0 &&
           stats.min==-100.0 && stats.max==100.0 &&
           stats.mean==0.0;
     if (!ok) {
        return its.stop('Statistics values are wrong (5)');
     }
##
     ok := myim.statistics(list=F, disk=T, force=T);
     if (is_fail(ok)) {
        return its.stop('Statistics failed (5)');
     }
     ok := myim.statistics(list=F, disk=F, force=T);
     if (is_fail(ok)) {
        return its.stop('Statistics failed (6)');
     }
#
     ok := myim.done();
     if (is_fail(ok)) {
        return its.stop('Done failed (1)');
     }
     return its.cleanup(testdir);
   }
    

   const its.tests.test23 := function()
#
# Test methods
#   histograms
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 23 - histograms');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Make image

     imshape := [5,10];
     pixels := array(0.0, imshape[1], imshape[2]);
     pixels[1,1] := -100;
     pixels[imshape[1],imshape[2]] := 100;
     imname := paste(testdir,'/','imagefromarray.image',sep='')
     myim := imagefromarray(outfile=imname, pixels=pixels);
     if (is_fail(myim)) {
       return its.stop('imagefromarray constructor 1 failed');
     }
#
     ok := myim.histograms(axes=[10,20]);
     if (!is_fail(ok)) {
        return its.stop('Histograms unexpectedly did not fail (1)');
     }
#
     local hists;
     nbins := 25;
     idx := nbins/2+1;
#
     ok := myim.histograms(histout=hists, list=F, nbins=nbins);
     if (is_fail(ok)) {
        return its.stop('Histograms failed (1)');
     }
     ok := has_field(hists,'values') && has_field(hists, 'counts');
     if (!ok) {
        return its.stop('Histograms record does not have the correct fields');
     }
     ok := length(hists.values)==nbins &&
           shape(hists.counts)==[nbins];
     if (!ok) {
        return its.stop('Histograms value arrays have the wrong shape (1)');
     }
     ok := hists.counts[1]==1 && hists.counts[nbins]==1 && 
           hists.counts[idx]==(prod(imshape)-2);
##
     blc := [1,1]; trc := [5,5];
     r1 := drm.box(blc=blc, trc=trc);
     ok := myim.histograms(histout=hists, nbins=nbins, list=F, region=r1);
     if (is_fail(ok)) {
        return its.stop('Histograms failed (2)');
     }
     ok := hists.counts[1]==1 && hists.counts[nbins]==(prod((trc-blc+1))-1);
     if (!ok) {
        return its.stop('Histograms values are wrong (2)');
     }
##
     for (j in 1:imshape[2]) {
        pixels[1,j] := -100*j;
        pixels[imshape[1],j] := 100*j
     }
     ok := myim.putchunk(pixels);
     if (is_fail(ok)) {
        its.stop('putchunk failed (1)');
     }
     ok := myim.histograms(histout=hists, nbins=nbins, list=F, axes=[1]);
     if (is_fail(ok)) {
        return its.stop('Histograms failed (3)');
     }
     ok := shape(hists.values)==[nbins,imshape[2]] &&
           shape(hists.counts)==[nbins,imshape[2]];
     if (!ok) {
        return its.stop('Histograms value arrays have the wrong shape (2)');
     }
     for (j in 1:imshape[2]) {
        ok := hists.counts[1,j]==1 && hists.counts[nbins,j]==1 && 
              hists.counts[idx]==(imshape[1]-2);
        if (!ok) {
           return its.stop('Histograms values are wrong (3)');
        }
     }
##
     ok := myim.histograms(histout=hists, list=F, includepix=[-5,5], nbins=25);
     if (is_fail(ok)) {
        return its.stop('Histograms failed (4)');
     }
     ok := hists.counts[idx]==(prod(imshape)-(imshape[2]+imshape[2])) &&
           all(hists.counts[1:(idx-1)]==0) &&
           all(hists.counts[(idx+1):nbins]==0);
     if (!ok) {
        return its.stop('Histograms values are wrong (4)');
     }
#
     ok := myim.histograms(list=F, disk=T, force=T);
     if (is_fail(ok)) {
        return its.stop('histograms failed (4)');
     }
     ok := myim.histograms(list=F, disk=F, force=T);
     if (is_fail(ok)) {
        return its.stop('histograms failed (5)');
     }
     ok := myim.histograms(list=F, gauss=T, cumu=T, log=T);
     if (is_fail(ok)) {
        return its.stop('histograms failed (6)');
     }
#
     ok := myim.done();
     if (is_fail(ok)) {
        return its.stop('Done failed (1)');
     }
     return its.cleanup(testdir);
   }
    


   const its.tests.test24 := function()
#
# Test methods
#   moments
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 24 - moments');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Make image

     imshape := [50,100];
     pixels := array(0.0, imshape[1], imshape[2]);
     imname := paste(testdir,'/','imagefromarray.image',sep='')
     myim := imagefromarray(outfile=imname, pixels=pixels);
     if (is_fail(myim)) fail;
#
     ok := myim.moments(axis=1, moments=[22]);
     if (!is_fail(ok)) {
        return its.stop('moments unexpectedly did not fail (1)');
     }
     ok := myim.moments(axis=100);
     if (!is_fail(ok)) {
        return its.stop('moments unexpectedly did not fail (2)');
     }
     ok := myim.moments(method='doggies');
     if (!is_fail(ok)) {
        return its.stop('moments unexpectedly did not fail (3)');
     }
     ok := myim.moments(smoothaxes=[10,20]);
     if (!is_fail(ok)) {
        return its.stop('moments unexpectedly did not fail (4)');
     }
     ok := myim.moments(smoothaxes=[10,20], smoothtypes="gauss gauss", smoothwidths=[10,10]);
     if (!is_fail(ok)) {
        return its.stop('moments unexpectedly did not fail (5)');
     }
     ok := myim.moments(smoothaxes=[1,2], smoothtypes="fish gauss", smoothwidths=[10,10]);
     if (!is_fail(ok)) {
        return its.stop('moments unexpectedly did not fail (6)');
     }
     ok := myim.moments(smoothaxes=[1,2], smoothtypes="gauss gauss", smoothwidths=[-100,10]);
     if (!is_fail(ok)) {
        return its.stop('moments unexpectedly did not fail (7)');
     }
     ok := myim.moments(includepix=[-100,100], excludepix=[-100,100]);
     if (!is_fail(ok)) {
        return its.stop('moments unexpectedly did not fail (8)');
     }
#
     base1 := paste(testdir,'/','base1',sep='')
     base2 := paste(testdir,'/','base2',sep='')
     im2 := myim.moments(outfile=base1, axis=1);
     if (is_fail(im2)) fail;
     ok := im2.done();
     im2 := myim.moments(outfile=base2, axis=2);
     if (is_fail(ok)) fail;
     ok := im2.done();
#
     base3 := paste(testdir,'/','base3',sep='');
     im2 := myim.moments(outfile=base3, axis=1, moments=[-1:3,5:11])
     if (is_fail(im2)) fail;
     ok := im2.done();
#
     base4 := paste(testdir,'/','base4',sep='')
     pixels := myim.getchunk();
     pixels[1,1] := 10;
     ok := myim.putchunk(pixels);
     if (is_fail(ok)) fail;
     im2 := myim.moments(outfile=base4, axis=1, moments=[-1],             # Average
                        smoothaxes=[1,2], smoothtypes="gauss box",
                        smoothwidths=[5,10], includepix=[-100,100]);
     if (is_fail(im2)) fail;
     pixels2 := im2.getchunk();
     v := 10.0 / imshape[1];
     if (abs(pixels2[1]-v)>0.00001) {
        return its.stop('Moment pixel values are wrong');
     }
#
     ok := myim.done();
     if (is_fail(ok)) fail;
     ok := im2.done();
     if (is_fail(ok)) fail;
     return its.cleanup(testdir);
   }


   const its.tests.test25 := function()
#
# Test methods
#   modify and fitsky
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 25 - modify, fitsky');

# Make the directory

      const testdir := 'imagetest_temp'
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
# Pretty hard to test properly.  Add model
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
#
# Subtract it again
#
      if (is_fail(myim.modify(cl0, subtract=T))) fail;
      local stats;
      if (is_fail(myim.stats(statsout=stats, list=F))) fail;
      p := myim.getchunk();
      if (!all(abs(p)<1e-6)) {
         return its.stop('model image 2 has wrong values');         
      }
#
# Now add the model for fitting
#
      if (is_fail(myim.modify(cl0, subtract=F))) fail;
#
      local converged, r, m;
      cl1 := myim.fitsky(r, m, converged, deconvolve=F, region=drm.quarter());
      if (is_fail(cl1)) {
         return its.stop('fitsky 1 failed');
      }
      if (!converged) {
         return its.stop('fitsky 1 did not converge');
      }
      ok := all(m==T);
      if (!ok) {
         return its.stop('recovered mask 1 is wrong');
      }
      local errmsg;
      if (!its.compareComponentList(errmsg,cl0,cl1)) {
         return its.stop(spaste('fitsky 1 ',errmsg));
      }
#
# Have another go with previous output as model
#
      cl2 := myim.fitsky(r, m, converged, estimate=cl1, deconvolve=F, region=drm.quarter());
      if (is_fail(cl2)) {
         return its.stop('fitsky 2 failed');
      }
      if (!converged) {
         return its.stop('fitsky 2 did not converge');
      }
      ok := all(m==T);
      if (!ok) {
         return its.stop('recovered mask 2 is wrong');
      }
      if (!its.compareComponentList(errmsg,cl0,cl2)) {
         return its.stop(spaste('fitsky 2 ',errmsg));
      }
#
      ok := myim.done();
      if (is_fail(ok)) {
         return its.stop('Done failed (1)');
      }
#
      return its.cleanup(testdir);
   }


   const its.tests.test26 := function()
#
# Test methods
#   fft
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 26 - fft');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Open test image (has sky coordinates)

      aipspath := split(environ.AIPSPATH)[1];
      testname := spaste(aipspath, '/data/demo/Images/test_image');
      testim := image(testname);
      if (is_fail(testim)) {
         return its.stop('image constructor failed');
      }
      testshape := testim.shape();
      if (length(testshape)!=3) {
         return its.stop('testimage has unexpected shaped');
      }
#
# FFT sky 
#
      rname := paste(testdir,'/','real', sep='');
      iname := paste(testdir,'/','imag', sep='');
      aname := paste(testdir,'/','amp', sep='');
      pname := paste(testdir,'/','phase', sep='');
      ok := testim.fft(real=rname, imag=iname, phase=pname, amp=aname);
      if (is_fail(ok)) {
         return its.stop('skyfft failed');
      }
#
      im1 := image(rname);
      if (is_fail(im1)) {
         return its.stop('Failed to open real image (1)');
      }
      im2 := image(iname);
      if (is_fail(im2)) {
         return its.stop('Failed to open imaginary image (1)');
      }
      im3 := image(aname);
      if (is_fail(im3)) {
         return its.stop('Failed to open amplitude image (1)');
      }
      im4 := image(pname);
      if (is_fail(im4)) {
         return its.stop('Failed to open phase image (1)');
      }
#
      trc := testim.shape();
      trc[3] := 1;
      a1 := im1.getchunk(trc=trc);
      a2 := im2.getchunk(trc=trc);
      a3 := im3.getchunk(trc=trc);
      a4 := im4.getchunk(trc=trc);
#
      include 'fftserver.g'
      fft := fftserver();
      p := testim.getchunk(trc=trc);
      c := fft.realtocomplexfft(p);
      b1 := real(c);
      b2 := imag(c);
      b3 := abs(c);
      b4 := arg(c);
#
      diff := abs(a1-b1);
      if (!all(diff<1e-6)) {
         return its.stop('real values incorrect (1)');
      }
      diff := abs(a2-b2);
      if (!all(diff<1e-6)) {
         return its.stop('imaginary values incorrect (1)');
      }
      diff := abs(a3-b3);
      if (!all(diff<1e-5)) {
         return its.stop('amplitude values incorrect (1)');
      }
      diff := abs(a4-b4);
      if (!all(diff<1e-6)) {
         return its.stop('phase values incorrect (1)');
      }
#
      ok :=im1.delete(T) && im2.delete(T) && im3.delete(T) && im4.delete(T);
      if (is_fail(ok)) {
         return its.stop('Done 1 failed');
      }
#
# FFT whole image
#
      ndim := length(testim.shape());
      axes := 1:ndim;
      ok := testim.fft(real=rname, imag=iname, phase=pname, amp=aname, axes=axes);
      if (is_fail(ok)) {
         return its.stop('whole image fft failed');
      }
#
      im1 := image(rname);
      if (is_fail(im1)) {
         return its.stop('Failed to open real image (2)');
      }
      im2 := image(iname);
      if (is_fail(im2)) {
         return its.stop('Failed to open imaginary image (2)');
      }
      im3 := image(aname);
      if (is_fail(im3)) {
         return its.stop('Failed to open amplitude image (2)');
      }
      im4 := image(pname);
      if (is_fail(im4)) {
         return its.stop('Failed to open phase image (2)');
      }
#
      a1 := im1.getchunk();
      a2 := im2.getchunk();
      a3 := im3.getchunk();
      a4 := im4.getchunk();
#
      include 'fftserver.g'
      fft := fftserver();
      p := testim.getchunk()
      c := fft.realtocomplexfft(p);
      b1 := real(c);
      b2 := imag(c);
      b3 := abs(c);
      b4 := arg(c);
#
      diff := abs(a1-b1);
      if (!all(diff<1e-6)) {
         return its.stop('real values incorrect (2)');
      }
      diff := abs(a2-b2);
      if (!all(diff<1e-6)) {
         return its.stop('imaginary values incorrect (2)');
      }
      diff := abs(a3-b3);
      if (!all(diff<2e-5)) {
         return its.stop('amplitude values incorrect (2)');
      }
      diff := abs(a4-b4);
      if (!all(diff<1e-6)) {
         return its.stop('phase values incorrect (2)');
      }
#
      ok := testim.done() && im1.done() && im2.done() && im3.done() && im4.done();
      if (is_fail(ok)) {
         return its.stop('Done 2 failed');
      }
#
      return its.cleanup(testdir);
   }


   const its.tests.test27 := function()
#
# Test methods
#   regrid
#
# Not very extensive
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 27 - regrid');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Make RA/DEC/Spectral image

      imname := paste(testdir,'/','imagefromshape.image1',sep='')
      imshape := [32,32,32];
      myim := imagefromshape(imname, imshape);
      if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 1 failed');
      }
      if (is_fail(myim.set(1.0))) fail;
#
# Forced failures
#
      myim2 := myim.regrid(axes=[20]);
      if (!is_fail(myim2)) {
         return its.stop('regrid 1 unexpectedly did not fail');
      }
      myim2 := myim.regrid(shape=[10,20,30,40]);
      if (!is_fail(myim2)) {
         return its.stop('regrid 2 unexpectedly did not fail');
      }
      myim2 := myim.regrid(csys='fish');
      if (!is_fail(myim2)) {
         return its.stop('regrid 3 unexpectedly did not fail');
      }
      myim2 := myim.regrid(method='doggies');
      if (!is_fail(myim2)) {
         return its.stop('regrid 4 unexpectedly did not fail');
      }
#
# Regrid it to itself (all axes)
#
      iDone := 1;
#      for (method in "near linear cubic") {
      for (method in "cubic") {
         myim2 := myim.regrid(method=method);
         if (is_fail(myim2)) fail;
         p := myim2.getchunk([3,3],imshape-3);
         if (!all( abs(p-1)<1e-3)) {
            t := spaste('Regridded values are wrong (1), method=', method);
            return its.stop(t);
         }      
         ok := myim2.done();
         if (is_fail(ok)) {
            t := spaste('Done failed (', iDone, ')');
            return its.stop(t);
         }
         iDone := iDone + 1;
      }
#
#      for (method in "cubic linear near") {
      for (method in "cubic") {
         myim2 := myim.regrid(method=method, axes=[1,2]);
         if (is_fail(myim2)) fail;
         p := myim2.getchunk([3,3],imshape-3);
         if (!all( abs(p-1)<1e-3)) {
            t := spaste('Regridded values are wrong (2), method=', method);
            return its.stop(t);
         }      
         ok := myim2.done();
         if (is_fail(ok)) {
            t := spaste('Done failed (', iDone, ')');
            return its.stop(t);
         }
         iDone := iDone + 1;
      }
#
#      for (method in "near linear cubic") {
      for (method in "cubic") {
         myim2 := myim.regrid(method=method, axes=[3]);
         if (is_fail(myim2)) fail;
         p := myim2.getchunk([3,3],imshape-3);
         if (!all( abs(p-1)<1e-3)) {
            t := spaste('Regridded values are wrong (3), method=', method);
            return its.stop(t);
         }      
         ok := myim2.done();
         if (is_fail(ok)) {
            t := spaste('Done failed (', iDone, ')');
            return its.stop(t);
         }
         iDone := iDone + 1;
      }
#
      ok := myim.done();
      if (is_fail(ok)) {
         t := spaste('Done failed (', iDone, ')');
         return its.stop(t);
      }
      iDone := iDone + 1;
#
      return its.cleanup(testdir);
   }

   const its.tests.test28 := function()
#
# Test methods
#   convolve2d
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 28 - convolve2d');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Make sky image

     nx := 128; ny := 128;
     imshape := [nx,ny];
     centre := imshape/2;
     myim := imagefromshape(shape=imshape);
     if (is_fail(myim)) return its.stop('imagefromshape constructor 1 failed');
     cs := myim.coordsys();
     cs.setincrement(value="-1arcsec 1arcsec");
     ok := myim.setcoordsys(cs);
     if (is_fail(ok)) return its.stop ('Failed to set coordsys 1');
     cs.done();
#
# These tests don't test the pixel values, just units and interface
# Whack a gaussian in and set restoring beam to its shape
#
     gausspixels := its.gaussianarray (nx, ny, 1.0, 20.0, 10.0, 0.0);
     ok := myim.putchunk(gausspixels);
     if (is_fail(ok)) return its.stop('putchunk 1 failed')
     ok := myim.setrestoringbeam(major='20arcsec', minor='10arcsec', pa=0.0, log=F);
     if (is_fail(ok)) return its.stop('setrestoringbeam 1 failed')
     ok := myim.setbrightnessunit('Jy/beam');
     if (is_fail(ok)) return its.stop('setbrightnessunits 1 failed')
#
# First test a Jy/beam convolution
#
     r := drm.quarter()
     myim2 := myim.convolve2d (major='20arcsec', minor='10arcsec', pa=0);
     if (is_fail(myim2)) return its.stop('convolve2d 1 failed')
     bUnit := myim2.brightnessunit();
     if (bUnit!='Jy/beam') return its.stop ('convolve2d 1 set wrong brightness unit');
     major := sqrt(400 + 400);
     minor := sqrt(100 + 100);
     rb := myim2.restoringbeam();
     d1 := abs(rb.major.value - major);
     d2 := abs(rb.minor.value - minor);
     d3 := abs(rb.positionangle.value - 0.0);
     if (d3 > 1e-5) d3 := abs(rb.positionangle.value - 180.0);
     if (d1 >1e-5 || d2>1e-5 || d3>1e-5) {
        return its.stop ('convolve2d 1 set wrong restoring beam');
     }
     if (is_fail(myim2.done())) return its.stop ('done 1 failed');
#
# Now set values in pixels (increment=1arcsec)
#
     ok := myim.putchunk(gausspixels);
     if (is_fail(ok)) return its.stop('putchunk 2 failed')
     ok := myim.setrestoringbeam(major='20arcsec', minor='10arcsec', pa=0.0, log=F);
     if (is_fail(ok)) return its.stop('setrestoringbeam 2 failed')
     ok := myim.setbrightnessunit('Jy/beam');
     if (is_fail(ok)) return its.stop('setbrightnessunits 2 failed')
#
     myim2 := myim.convolve2d (major=20, minor=10, pa=0, region=r);
     if (is_fail(myim2)) return its.stop('convolve2d 2 failed')
     bUnit := myim2.brightnessunit();
     if (bUnit!='Jy/beam') return its.stop ('convolve2d 2 set wrong brightness unit');
     major := sqrt(20*20 + 20*20);
     minor := sqrt(10*10 + 10*10);
     rb := myim2.restoringbeam();
     d1 := abs(rb.major.value - major);
     d2 := abs(rb.minor.value - minor);
     d3 := abs(rb.positionangle.value - 0.0);
     if (d3 > 1e-5) d3 := abs(rb.positionangle.value - 180.0);
     if (d1 >1e-5 || d2>1e-5 || d3>1e-5) {
        return its.stop ('convolve2d 2 set wrong restoring beam');
     }
     if (is_fail(myim2.done())) return its.stop ('done 2 failed');
#
# Now test a Jy/pixel convolution
#
     ok := myim.set(0.0);
     if (is_fail(ok)) return its.stop ('set 1 failed');
     pixels := myim.getchunk();
     if (is_fail(pixels)) return its.stop ('getchunk 1 failed');
     pixels[as_integer(nx/2),as_integer(ny/2)] := 1.0;
     ok := myim.putchunk(pixels);
     if (is_fail(ok)) return its.stop ('putchunk 3 failed');
     ok := myim.setrestoringbeam(delete=T, log=F);
     if (is_fail(ok)) return its.stop('setrestoringbeam 3 failed')
     ok := myim.setbrightnessunit('Jy/pixel');
     if (is_fail(ok)) return its.stop('setbrightnessunits 3 failed')
#
     myim2 := myim.convolve2d (major='20arcsec', minor='10arcsec', pa='20deg', region=r);
     if (is_fail(myim2)) return its.stop('convolve2d 3 failed')
     bUnit := myim2.brightnessunit();
     if (bUnit!='Jy/beam') return its.stop ('convolve2d 3 set wrong brightness unit');
     major := 20;
     minor := 10;
     rb := myim2.restoringbeam();
     d1 := abs(rb.major.value - major);
     d2 := abs(rb.minor.value - minor);
     q := dq.convert(rb.positionangle,'deg');
     if (is_fail(q)) fail;
     d3 := abs(dq.getvalue(q) - 20.0);
     if (d1 >1e-5 || d2>1e-5 || d3>1e-5) {
        return its.stop ('convolve2d 3 set wrong restoring beam');
     }
     if (is_fail(myim2.done())) return its.stop ('done 3 failed');
#
# Now test axes other than the sky
#
     cs := coordsys(linear=2);
     ok := cs.setunits(value="km km", overwrite=T);
     if (is_fail(ok)) fail;
     ok := myim.setcoordsys(cs);
     if (is_fail(ok)) return its.stop ('Failed to set coordsys 2');
     cs.done();
     ok := myim.set(0.0);
     if (is_fail(ok)) return its.stop ('set 2 failed');
     pixels := myim.getchunk();
     if (is_fail(pixels)) return its.stop ('getchunk 2 failed');
     pixels[as_integer(nx/2),as_integer(ny/2)] := 1.0;
     ok := myim.putchunk(pixels);
     if (is_fail(ok)) return its.stop ('putchunk 4 failed');
     ok := myim.setrestoringbeam(delete=T, log=F);
     if (is_fail(ok)) return its.stop('setrestoringbeam 3 failed')
     ok := myim.setbrightnessunit('kg');
     if (is_fail(ok)) return its.stop('setbrightnessunits 4 failed')
#
     myim2 := myim.convolve2d (major='20km', minor='10km', pa='20deg', region=r);
     if (is_fail(myim2)) return its.stop('convolve2d 4 failed')
     if (is_fail(myim2.done())) return its.stop ('done 4 failed');
     if (is_fail(myim.done())) return its.stop('done 5 failed');
#
# Now try a mixed axis convolution
#
     cs := coordsys(direction=T, linear=1);
     nz := 32;
     imshape := [nx,ny,nz];
     centre := imshape/2;
     myim := imagefromshape(shape=imshape, csys=cs);
     if (is_fail(myim)) return its.stop('imagefromshape constructor 2 failed');
     if (is_fail(cs.done())) return its.stop ('done 6 failed');
#
     myim2 := myim.convolve2d (major=20, minor=10, axes=[1,3]);
     if (is_fail(myim2)) return its.stop('convolve2d 5 failed')
     if (is_fail(myim2.done())) return its.stop ('done 7 failed');
     if (is_fail(myim.done())) return its.stop('done 8 failed');
#
# Now do some non autoscaling
#
     imshape := [nx,ny];
     centre := imshape/2;
     myim := imagefromshape(shape=imshape);
     if (is_fail(myim)) return its.stop('imagefromshape constructor 3 failed');
     cs := myim.coordsys();
     cs.setincrement(value="-1arcsec 1arcsec");
     ok := myim.setcoordsys(cs);
     if (is_fail(ok)) return its.stop ('Failed to set coordsys 3');
     if (is_fail(cs.done())) return its.stop('done 10 failed');
#
     pixels := myim.getchunk();
     if (is_fail(pixels)) return its.stop ('getchunk 3 failed');
     pixels[as_integer(nx/2),as_integer(ny/2)] := 1.0;
     ok := myim.putchunk(pixels);
     if (is_fail(ok)) return its.stop ('putchunk 5 failed');
     ok := myim.setbrightnessunit('Jy/pixel');
     if (is_fail(ok)) return its.stop('setbrightnessunits 5 failed')
#
# Convolution kernel has peak 1.0*scale
#
     myim2 := myim.convolve2d (scale=2.0, major='20arcsec', minor='10arcsec');
     if (is_fail(myim2)) return its.stop('convolve2d 6 failed')
     local stats;
     ok := myim2.statistics(stats, list=F);
     if (is_fail(ok)) fail;
     maxVal := stats.max;
     d1 := abs(maxVal - 2.0);
     if (d1>1e-5) return its.stop ('convolve2d 6 got scaling wrong');
     if (is_fail(myim2.done())) return its.stop ('done 11 failed');
     if (is_fail(myim.done())) return its.stop('done 12 failed');
#
# Now some forced errors
#
     imshape := [nx,ny,nz];
     centre := imshape/2;
     myim := imagefromshape(shape=imshape);
     if (is_fail(myim)) return its.stop('imagefromshape constructor 4 failed');
#
     myim2 := myim.convolve2d (major='1km', minor='20arcsec', axes=[1,2]);
     if (!is_fail(myim2)) return its.stop ('Forced failure 1 did not occur');
#
     myim2 := myim.convolve2d (major='10arcsec', minor='10Hz', axes=[1,3]);
     if (!is_fail(myim2)) return its.stop ('Forced failure 2 did not occur');
#
     myim2 := myim.convolve2d (major='10pix', minor='10arcsec', axes=[1,2]);
     if (!is_fail(myim2)) return its.stop ('Forced failure 3 did not occur');
     if (is_fail(myim.done())) return its.stop('done 14 failed');

###
      return its.cleanup(testdir);
   }


   const its.tests.test29 := function()
#
# Test methods
#   deconvolvecomponentlist
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 29 - deconvolvecomponentlist');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Make sky image

     nx := 128; ny := 128;
     imshape := [nx,ny];
     centre := imshape/2;
     myim := imagefromshape(shape=imshape);
     if (is_fail(myim)) return its.stop('imagefromshape constructor 1 failed');
     ok := myim.summary()
#
     ok := its.deconvolveTest (myim, 20.0, 10.0, 0.0, 1);
     if (is_fail(ok)) fail;
#
     ok := its.deconvolveTest (myim, 20.0, 10.0, 45.0, 2);
     if (is_fail(ok)) fail;
#
     ok := its.deconvolveTest (myim, 20.0, 10.0, -20.0, 3);
     if (is_fail(ok)) fail;
#
     if (is_fail(myim.done())) return its.stop ('done 1 failed');

###
      return its.cleanup(testdir);
   }


###
   const its.tests.test30 := function()
#
# Test methods
#   findsources, maxfit
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 30 - findsources, maxfit');
#
# Make image 
#
      imshape := [128,128,1];
      myim := imagefromshape(shape=imshape);
      if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 1 failed');
      }
#
# Add units and restoring beam   
#
      ok := myim.setbrightnessunit('Jy/beam');
      if (is_fail(ok)) fail;
#
      qmaj := dq.quantity(5.00000000001, 'arcmin');
      qmin := dq.quantity(5.0, 'arcmin');
      qpa := dq.quantity(0.0,'deg');
      ok := myim.setrestoringbeam(major=qmaj, minor=qmin, pa=qpa, log=F);
      if (is_fail(ok)) fail;
#
# Add four gaussians
#
      cs := myim.coordsys();
      if (is_fail(cs)) fail;
# 
      rp := cs.referencepixel();
      p1 := [-30.0,-30.0,0.0] + rp;
      d1 := cs.toworld(p1, 'm').direction;
      if (is_fail(d1)) fail;
#
      p2 := [-30.0, 30.0,0.0] + rp;
      d2 := cs.toworld(p2, 'm').direction;
      if (is_fail(d2)) fail;
#
      p3 := [ 30.0, 30.0,0.0] + rp;
      d3 := cs.toworld(p3, 'm').direction;
      if (is_fail(d3)) fail;
#
      p4 := [ 30.0, -30.0,0.0] + rp;
      d4 := cs.toworld(p4, 'm').direction;
      if (is_fail(d4)) fail;
#
      f1 := 100.0;
      cl1 := its.gaussian(f1, qmaj, qmin, qpa, dir=d1);
      if (is_fail(cl1)) fail;
      cl1Point := emptycomponentlist(log=F);
      cl1Point.simulate(1);
      ok := cl1Point.setflux(1, cl1.getfluxvalue(1));
      if (is_fail(ok)) fail;
      ok := cl1Point.setshape(1, 'point', log=F);
      if (is_fail(ok)) fail;
      rd := cl1.getrefdir(1);
      ok := cl1Point.setrefdir(1, 
                               dm.getvalue(rd)[1].value,
                               dm.getvalue(rd)[1].unit,
                               dm.getvalue(rd)[2].value,
                               dm.getvalue(rd)[2].unit, log=F);
      if (is_fail(ok)) fail;
#
      f2 := 80.0;
      cl2 := its.gaussian(f2, qmaj, qmin, qpa, dir=d2);
      if (is_fail(cl2)) fail;
#
      f3 := 60.0;
      cl3 := its.gaussian(f3, qmaj, qmin, qpa, dir=d3);
      if (is_fail(cl3)) fail;
#
      f4 := 40.0;
      cl4 := its.gaussian(f4, qmaj, qmin, qpa, dir=d4);
      if (is_fail(cl4)) fail;
#
      clIn := emptycomponentlist(log=F);
      clIn.concatenate(cl1, log=F);
      clIn.concatenate(cl2, log=F);
      clIn.concatenate(cl3, log=F);
      clIn.concatenate(cl4, log=F);
      cl1.done();
      cl2.done();
      cl3.done();
      cl4.done();
#
      if (is_fail(myim.modify(clIn, subtract=F))) fail;

# Now find them

      clOut := myim.findsources(10, cutoff=0.3);
      if (is_fail(clOut)) fail;
      local errmsg;
      if (!its.compareComponentList(errmsg,clIn,clOut,dotype=F)) {
         return its.stop(spaste('findsources 1', errmsg));
      }
#
# Now try and find just first 3 sources
#
      clOut := myim.findsources(10, cutoff=0.5);
      if (is_fail(clOut)) fail;
      clIn2 := emptycomponentlist(log=F);
      clIn2.concatenate (clIn, [1,2,3], log=F);
      if (!its.compareComponentList(errmsg,clIn2,clOut,dotype=F)) {
         return its.stop(spaste('findsources 2', errmsg));
      }
#
      if (is_fail(clIn.done())) fail;
      if (is_fail(clIn2.done())) fail;
      if (is_fail(clOut.done())) fail;

# Maxfit
   
      clOut := myim.maxfit();
      if (!its.compareComponentList(errmsg,cl1Point,clOut,dotype=F)) {
         return its.stop(spaste('maxfit', errmsg));
      }
      if (is_fail(cl1Point.done())) fail;
      if (is_fail(clOut.done())) fail;
#
      ok := myim.done();
      if (is_fail(ok)) {
         return its.stop('Done failed (1)');
      }
      ok := cs.done();
      if (is_fail(ok)) {
         return its.stop('Done failed (2)');
      }
#
      return T;
   }


###
   const its.tests.test31 := function()
#
# Test methods
#   adddegaxes
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 31 - adddegaxes');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make RA/DEC image 
#
      imname := paste(testdir,'/','imagefromshape.image',sep='')
      imshape := [10,10];
      myim := imagefromshape(imname, imshape);
      if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 1 failed');
      }
#
      myim2 := myim.adddegaxes(direction=T);
      if (!is_fail(myim2)) return its.stop ('Unexpectedly (1) did not fail')
#
      myim2 := myim.adddegaxes(spectral=T);
      if (is_fail(myim2)) fail;
      s := myim2.shape();
      s2 := [imshape,1];
      if (s!=s2) return its.stop('shape (1) is wrong');
      cs := myim2.coordsys();
      types := cs.axiscoordinatetypes();
      if (types[3] != 'Spectral') return its.stop('Wrong (1) degenerate axis type')
      if (is_fail(cs.done())) fail;
      if (is_fail(myim2.done())) fail;
#
      myim2 := myim.adddegaxes(stokes='i');
      if (is_fail(myim2)) fail;
      s := myim2.shape();
      s2 := [imshape,1];
      if (s!=s2) return its.stop('shape (2) is wrong');
      cs := myim2.coordsys();
      types := cs.axiscoordinatetypes();
      if (types[3] != 'Stokes') return its.stop('Wrong (2) degenerate axis type')
      if (is_fail(cs.done())) fail;
      if (is_fail(myim2.done())) fail;
#
      myim2 := myim.adddegaxes(linear=T);
      if (is_fail(myim2)) fail;
      s := myim2.shape();
      s2 := [imshape,1];
      if (s!=s2) return its.stop('shape (3) is wrong');
      cs := myim2.coordsys();
      types := cs.axiscoordinatetypes();
      if (types[3] != 'Linear') return its.stop('Wrong (3) degenerate axis type')
      if (is_fail(cs.done())) fail;
      if (is_fail(myim2.done())) fail;
#
      myim2 := myim.adddegaxes(tabular=T);
      if (is_fail(myim2)) fail;
      s := myim2.shape();
      s2 := [imshape,1];
      if (s!=s2) return its.stop('shape (4) is wrong');
      cs := myim2.coordsys();
      types := cs.axiscoordinatetypes();
      if (types[3] != 'Tabular') return its.stop('Wrong (4) degenerate axis type')
      if (is_fail(cs.done())) fail;
      if (is_fail(myim2.done())) fail;
#
      if (is_fail(myim.done())) fail;
#
# Make Spectral image 
#
      cs := coordsys(spectral=T);
      if (is_fail(cs)) fail; 
      imname := paste(testdir,'/','imagefromshape2.image',sep='')
      imshape := [10];
      myim := imagefromshape(imname, imshape, csys=cs);
      if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 2 failed');
      }
#
      myim2 := myim.adddegaxes(direction=T);
      if (is_fail(myim2)) fail;
      s := myim2.shape();
      s2 := [imshape,1,1];
      if (s!=s2) return its.stop('shape (4) is wrong');
      cs := myim2.coordsys();
      types := cs.axiscoordinatetypes();
      if (types[2] != 'Direction' || types[3] != 'Direction') {
         return its.stop('Wrong (4) degenerate axis type')
      }
      if (is_fail(cs.done())) fail;
      if (is_fail(myim2.done())) fail;
#
      if (is_fail(myim.done())) fail;
      return its.cleanup(testdir);
   }



###
   const its.tests.test32 := function()
#
# Test methods
#   addnoise
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 32 - addnoise');
#
# Make tempimage 
#
      imshape := [512,512];
      myim := imagefromshape(shape=imshape);
      if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 1 failed');
      }
      n := prod(imshape);

# Add noisesesesese

      n1 := "binomial discreteuniform erlang geometric hypergeometric";
      n2 := "normal lognormal negativeexponential poisson uniform weibull";
      noises := [n1, n2];
#
      rec := [=];
      rec.binomial.pars := [1, 0.5];
#
      rec.discreteuniform.pars := [-100, 100];
      rec.discreteuniform.mean := 0.5 * (rec.discreteuniform.pars[2] + rec.discreteuniform.pars[1]);
#
      rec.erlang.pars := [1,1];
      rec.erlang.mean := rec.erlang.pars[1];
      rec.erlang.var := rec.erlang.pars[2];
#
      rec.geometric.pars := [0.5];
      rec.geometric.mean := rec.geometric.pars[1];
#
      rec.hypergeometric.pars := [0.5, 0.5];
      rec.hypergeometric.mean := rec.hypergeometric.pars[1];
      rec.hypergeometric.var := rec.hypergeometric.pars[2];
#
      rec.normal.pars := [0, 1];
      rec.normal.mean := rec.normal.pars[1];
      rec.normal.var := rec.normal.pars[2];
#
      rec.lognormal.pars := [1, 1];
      rec.lognormal.mean := rec.lognormal.pars[1];
      rec.lognormal.var := rec.lognormal.pars[2];
#
      rec.negativeexponential.pars := [1];
      rec.negativeexponential.mean := rec.negativeexponential.pars[1];
#
      rec.poisson.pars := [1];
      rec.poisson.mean := rec.poisson.pars[1];
#
      rec.uniform.pars := [-1, 1];
      rec.uniform.mean := 0.5 * (rec.uniform.pars[2] + rec.uniform.pars[1]);
#
      rec.weibull.pars := [0.5, 1];
#
      local stats;
      for (n in noises) {
         ok := myim.addnoise(zero=T, type=n, pars=rec[n].pars);
         if (is_fail(ok)) fail;
#
         ok := myim.statistics (stats, list=F);
         if (is_fail(ok)) fail;
         errMean := stats.sigma / sqrt(stats.npts);
         sig := stats.sigma;
#
         if (has_field(rec[n], 'mean')) {
            d := abs(stats.mean - rec[n].mean);
            if (d > errMean) {
               s := spaste ('Mean wrong for distribution ', n);
#               fail s;
            }
         }
#
         if (has_field(rec[n], 'var')) {
            d := abs(sig*sig - rec[n].var);
#            if (d > errMean) {               # What is the error in the variance ???
#               s := spaste ('Variance wrong for distribution ', n);
#               fail s;
#            }
         }
      }
#
      if (is_fail(myim.done())) fail;
      return T;
   }


###
   const its.tests.test33 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 33 - {set}miscinfo, {set}history, {set}brightnessunit')
      its.info('        - {set}restoringbeam, convertflux');
      its.info('           with many Image types');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
# Make images of all the wondrous flavours that we have
#
      root := paste(testdir, '/', 'testimage', sep='')
      imshape := [10,10];
      rec := its.makeAllImageTypes(imshape, root);
#
      mii := [=];
      mii.x := 'x';
      mii.y := 'y';
#
      bui := 'Jy/beam'
      hii := "I like doggies";
#
      rbi := [=];
      rbi.major := dq.quantity('10arcsec');
      rbi.minor := dq.quantity('5arcsec');
      rbi.positionangle := dq.quantity('30deg');
#
      names := field_names(rec);
      for (type in names) {
        its.info('Testing Image type ', rec[type].type);
#
        myim := rec[type].tool;
        ok := myim.sethistory(hii);
        if (is_fail(ok)) fail;
        hio := myim.history(list=F, browse=F);
        if (is_fail(hio)) fail;
        if (length(hii)!=length(hio)) {
           fail 'History length does not relfect'
        }
        for (i in 1:length(hii)) {
          if (hii[i]!=hio[i]) {
             fail 'History fields do not reflect'
          }
        }
#
        ok := myim.setmiscinfo(mii);
        if (is_fail(ok)) fail;
        mio := myim.miscinfo();
        if (is_fail(mio)) fail;
        for (f in field_names(mii)) {
           if (has_field(mio, f)) {
              if (mii[f] != mio[f]) {
                 fail 'miscinfo field values do not reflect';
              }
           } else {
              fail 'miscinfo fields  do not reflect';
           }              
        }
#
        ok := myim.setrestoringbeam(beam=rbi, log=F);
        if (is_fail(ok)) fail;
        rbo := myim.restoringbeam();      
        if (is_fail(rbo)) fail;
        for (f in field_names(rbi)) {
           if (has_field(rbo, f)) {
              if (dq.getvalue(rbi[f]) != dq.getvalue(rbo[f])) {
                 fail 'restoring beam values do not reflect';
              }
              if (dq.getunit(rbi[f]) != dq.getunit(rbo[f])) {
                 fail 'restoring beam units do not reflect';
              }
           } else {
              fail 'restoring beam fields do not reflect';
           }              
        }
#  
        ok := myim.setbrightnessunit(bui);
        if (is_fail(ok)) fail;
        buo := myim.brightnessunit();      
        if (is_fail(buo)) fail;
        if (bui != buo) {
           fail 'brightness units do not reflect'
        }        

# Test convert flux.  
        ok := myim.setrestoringbeam(beam=rbi, log=F);
        if (is_fail(ok)) fail;
        ok := myim.setbrightnessunit('Jy/beam');

# FIrst a point source

        for (type in "gauss disk") {
           peakFlux := dq.quantity(1.0, 'mJy/beam');
           major := rbi[1];
           minor := rbi[2];
           integralFlux := myim.convertflux(value=peakFlux, major=major, 
                                            minor=minor, topeak=F, type=type);
           if (is_fail(integralFlux)) fail;
           peakFlux2 := myim.convertflux(value=integralFlux, major=major, 
                                          minor=minor, topeak=T, type=type);
           if (is_fail(peakFlux2)) fail;
#
           d := abs(dq.getvalue(peakFlux)) - abs(1000.0*dq.getvalue(integralFlux));
           if (d > 1e-5) {
              fail 'Point source flux conversion reflection 1 failed'
           }
           d := abs(dq.getvalue(peakFlux)) - abs(1000.0*dq.getvalue(peakFlux2));
           if (d > 1e-5) {
              fail 'Point source flux conversion reflection 2 failed'
           }

# Now an extended source

           peakFlux := dq.quantity(1.0, 'mJy/beam');
           major := dq.quantity("30arcsec");
           minor := dq.quantity("20arcsec");
           integralFlux := myim.convertflux(value=peakFlux, major=major, 
                                            minor=minor, topeak=F, type=type);
           if (is_fail(integralFlux)) fail;
           peakFlux2 := myim.convertflux(value=integralFlux, major=major, 
                                          minor=minor, topeak=T);
           if (is_fail(peakFlux2)) fail;
#
           d := abs(dq.getvalue(peakFlux)) - abs(1000.0*dq.getvalue(integralFlux));
           if (d > 1e-5) {
              fail 'Extended source flux conversion reflection 1 failed'
           }
           d := abs(dq.getvalue(peakFlux)) - abs(1000.0*dq.getvalue(peakFlux2));
           if (d > 1e-5) {
              fail 'Extended source flux conversion reflection 2 failed'
           }
         }
      }
#
      ok := its.doneAllImageTypes(rec);
      if (is_fail(ok)) fail;
#
      return its.cleanup(testdir);
   }


###
   const its.tests.test34 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 34 - imagefromascii constructor and toascii');
#
      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
     its.info('Testing toascii');
     its.info('');
     shape := [2,4,6];
     n := prod(shape);
     pixels := as_float(array(1:n, n));
     pixels::shape := shape;
#
     imname := paste(testdir,'/','imagefromarray.image',sep='');
     myim := imagefromarray(pixels=pixels);
     if (is_fail(myim)) fail;
#
     filename := paste(testdir,'/','imagefromarray.ascii',sep='');
     ok := myim.toascii(outfile=filename);
     if (is_fail(ok)) fail;
#
     its.info('Testing imagefromascii');
     its.info('')
     myim2 := imagefromascii(infile=filename, shape=shape);
     if (is_fail(myim2)) fail;
     pixels2 := myim2.getchunk();
     if (is_fail(pixels2)) fail;
#
     diff := abs(pixels-pixels2);
     if (!all(diff<0.0001)) {
        return its.stop('imagefromascii reflection failed');
     }
#
     if (is_fail(myim.done())) fail;
     if (is_fail(myim2.done())) fail;

###
     return its.cleanup(testdir);
   }


###
   const its.tests.test35 := function()
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 35 - fitpolynomial');
#
      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;

# Make the directory

      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
#
     its.info('Testing fitpolynomial');
     its.info('');
     shape := [32,32,128];
#
     imname := paste(testdir,'/','imagefromshape.image',sep='');
     myim := imagefromshape(shape=shape);
     if (is_fail(myim)) fail;
     ok := myim.set(pixels='1.0')
     if (is_fail(ok)) fail;
#
     residname := paste(testdir,'/','imagefromshape.resid',sep='');
     fitname := paste(testdir,'/','imagefromshape.fit',sep='');
#
     resid := myim.fitpolynomial (residfile=residname, fitfile=fitname, order=0, axis=3);
     if (is_fail(ok)) fail;
#
     pixels := abs(resid.getchunk());
     if (is_fail(pixels)) fail;
#
     if (!all(pixels<0.00001)) {
        return its.stop('fitpolynomial got the wrong results');
     }
#
     if (is_fail(myim.done())) fail;
     if (is_fail(resid.done())) fail;

###
     return its.cleanup(testdir);
   }



###
   const its.tests.test36 := function()
#
# Test methods
#   twopointcorrelation
#
# Not very extensive
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 36 - twopointcorrelation');

# Make RA/DEC/Spectral image

      imshape := [5,10,20];
      myim := imagefromshape(shape=imshape);
      if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 1 failed');
      }
      if (is_fail(myim.set(1.0))) fail;
#
# Forced failures
#
      myim2 := myim.twopointcorrelation(axes=[20]);
      if (!is_fail(myim2)) {
         return its.stop('twopointcorrelation 1 unexpectedly did not fail');
      }
#
      myim2 := myim.twopointcorrelation(method='fish');
      if (!is_fail(myim2)) {
         return its.stop('twopointcorrelation 2 unexpectedly did not fail');
      }
#
      myim2 := myim.twopointcorrelation(region='fish');
      if (!is_fail(myim2)) {
         return its.stop('twopointcorrelation 3 unexpectedly did not fail');
      }
#
      myim2 := myim.twopointcorrelation(mask='fish');
      if (!is_fail(myim2)) {
         return its.stop('twopointcorrelation 4 unexpectedly did not fail');
      }
#
# Some simple tests.  Doing it in Glish is way too slow, so
# just run tests, no value validation
#
      myim2 := myim.twopointcorrelation ();
      if (is_fail(myim2)) {
         return its.stop('twopointcorrelation 5 failed');
      }
      ok := myim2.done();
      if (is_fail(ok)) fail;
#
      myim2 := myim.twopointcorrelation (axes=[1,2])
      if (is_fail(myim2)) {
         return its.stop('twopointcorrelation 6 failed');
      }
      ok := myim2.done();
      if (is_fail(ok)) fail;
#
      ok := myim.done();
      if (is_fail(ok)) fail;

# Make another image only with Linear coordinates

      imshape := [5,10,20];
      myim := imagefromshape(shape=imshape, linear=T);
      if (is_fail(myim)) {
        return its.stop('imagefromshape constructor 1 failed');
      }
#
      myim2 := myim.twopointcorrelation (axes=[1,3])
      if (is_fail(myim2)) {
         return its.stop('twopointcorrelation 7 failed');
      }
      ok := myim2.done();
      if (is_fail(ok)) fail;
#
      myim2 := myim.twopointcorrelation (axes=[2,3])
      if (is_fail(myim2)) {
         return its.stop('twopointcorrelation 8 failed');
      }
#
      ok := myim2.done();
      if (is_fail(ok)) fail;
#
      ok := myim.done();
      if (is_fail(ok)) fail;
#
      return T;
   }


###
   const its.tests.test37 := function()
#
# Test methods
#   continuumsub
#
# Not very extensive.  Remove this when this function goes elsewhere.
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 37 - continuumsub');

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }
      lineOut := spaste (testdir, '/line.im');      
      contOut := spaste (testdir, '/cont.im');

# Make image with Stokes and Spectral axis

      cs := coordsys(spectral=T, stokes='I');
      if (is_fail(cs)) fail;
#
      d := array(1:100, 1, 100);
      myim := imagefromarray(pixels=d, csys=cs);
      if (is_fail(myim)) {
        return its.stop('imagefromarray constructor 1 failed');
      }
      if (is_fail(cs.done())) fail;
#
# Forced failures
#
      myim2 := myim.continuumsub(lineOut, contOut, region='fish', overwrite=T);
      if (!is_fail(myim2)) {
         return its.stop('continuumsub 1 unexpectedly did not fail');
      }
#
      myim2 := myim.continuumsub(lineOut, contOut, channels='rats', overwrite=T);
      if (!is_fail(myim2)) {
         return its.stop('continuumsub 2 unexpectedly did not fail');
      }
#
      myim2 := myim.continuumsub(lineOut, contOut, pol='DOGGIES', overwrite=T);
      if (!is_fail(myim2)) {
         return its.stop('continuumsub 3 unexpectedly did not fail');
      }
#
      myim2 := myim.continuumsub(lineOut, contOut, fitorder=-2, overwrite=T);
      if (!is_fail(myim2)) {
         return its.stop('continuumsub 4 unexpectedly did not fail');
      }
#
# Some simple run tests.  
#
      myim2 := myim.continuumsub (lineOut, contOut, overwrite=T);
      if (is_fail(myim2)) {
         return its.stop('continuumsub 5 failed');
      }
      ok := myim2.done();
      if (is_fail(ok)) fail;
#
      return its.cleanup(testdir);
   }

###
   const its.tests.test38 := function()
#
# Test methods
#   rebin
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 38 - rebin');

# Make images

      shp2 := [20,40];
      d2 := array(1.0, shp2[1], shp2[2]);
#
      myim2 := imagefromarray(pixels=d2);
      if (is_fail(myim2)) {
        return its.stop('imagefromarray constructor 1 failed');
      }
#
# Forced failures
#
      myim2b := myim2.rebin(bin=[-100,2]);
      if (!is_fail(myim2b)) {
         return its.stop('rebin 1 unexpectedly did not fail');
      }
#
# Some simple run tests.  
#
      myim2b := myim2.rebin(bin=[2,2])
      if (is_fail(myim2b)) {
         return its.stop('rebin 2 failed');
      }
      p := myim2b.getchunk();
      if (!all(p==1.0)) {
         return its.stop('rebin 2 gives wrong values');
      }
#
      ok := myim2.done();
      if (is_fail(ok)) fail;
      ok := myim2b.done();
      if (is_fail(ok)) fail;
#
      return T;
   }

###
   const its.tests.test39 := function()
#
# Test methods
#   fitprofile
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 39 - fitprofile');

# Make data

      include 'functionals.g'
      fs := functionals();
      if (is_fail(fs)) fail;
#
      shp := 64;
      g := fs.gaussian1d(1, shp/2, shp/8);
      if (is_fail(g)) fail;  
#
      x := 1:shp;
      y := g.f(x);
      if (is_fail(y)) fail;  

# Make image

      myim := imagefromarray(pixels=y);
      if (is_fail(myim)) {
        return its.stop('imagefromarray constructor 1 failed');
      }
#
# Simple run test
#
      local values, resid;
      est := [=];
      est.xunit := 'pix';
      est := myim.fitprofile(values, resid, axis=1, ngauss=1, estimate=est, fit=F);
      if (is_fail(est)) {
         return its.stop('fitprofile 1 failed');
      }
#
      fit := myim.fitprofile(values, resid, axis=1, estimate=est, fit=T);
      if (is_fail(fit)) {
         return its.stop('fitprofile 2 failed');
      }
#
      tol := 1e-4;
      diff := abs(y-values);
      if (!all(diff<tol)) {
         return its.stop('fitprofile gives wrong values');
      }      
#
      ok := myim.done();
      if (is_fail(ok)) fail;
      ok := fs.done();
      if (is_fail(ok)) fail;
      ok := g.done();
      if (is_fail(ok)) fail;
#
      return T;
   }

###
   const its.tests.test40 := function()
#
# Test methods
#   momentsgui, sepconvolvegui, maskhandlergui, view
#
   {
      its.info('');
      its.info('');
      its.info('');
      its.info('Test 40 - GUIS: momentsgui, sepconvolvegui, maskhandlergui, view');
      if (!have_gui()) {
         its.info ('No GUI available, cannot test GUI methods');
         return T;
      }

# Make the directory

      const testdir := 'imagetest_temp'
      if (!its.cleanup(testdir)) return F;
      if (is_fail(dos.mkdir(testdir))) {
         return its.stop('mkdir', testdir, 'fails!');
      }

# Make image

     imshape := [100,100];
     pixels := array(0.0, imshape[1], imshape[2]);
     for (j in 40:60) {
        for (i in 40:60) {
           if (i>=45 && j>=45 && i<=55 && j<=55) {
              pixels[i,j] := 10;
           } else {
              pixels[i,j] := 5;
           }
        }
     }
     imname := paste(testdir,'/','imagefromarray1.image',sep='')
     myim := imagefromarray(outfile=imname, pixels=pixels);
     if (is_fail(myim)) {
       return its.stop('imagefromarray constructor 1 failed');
     }
# 
     its.info('');
     its.info('Testing function view');
     ok := myim.view(raster=T, contour=T);
     if (is_fail(ok)) {
        return its.stop('view failed');
     }
#
     its.info('');
     its.info('Testing maskhandlerguiview');
     ok := myim.maskhandlergui();
     if (is_fail(ok)) {
        return its.stop('maskhandlergui failed');
     }
#
     its.info('');
     its.info('Testing momentsgui');
     ok := myim.momentsgui();
     if (is_fail(ok)) {
        return its.stop('momentsgui failed');
     }
#
     its.info('');
     its.info('Testing sepconvolvegui');
     ok := myim.sepconvolvegui();
     if (is_fail(ok)) {
        return its.stop('sepconvolvegui failed');
     }
# 
     ok := myim.done();
     if (is_fail(ok)) {
        return its.stop('Done failed (1)');
     }
#
     return its.cleanup(testdir);
   }

#####################################################################
#
# Get on with it
#
    local imshape;
    if (is_unset(size)) {
	imshape := [32,32,16];
    } else {
       if (! is_numeric(size) || any(size < 1) || length(size)!=3) {
          note(spaste('Illegal shape: ', as_string(size)) ,
               priority='WARN', origin='imagetest()');
          imshape := [32,32,16];
          note(spaste('Using size=', imshape),
               priority='WARN', origin='imagetest()');
       } else {
          imshape := size;
       }
    }
#
    note ('', priority='WARN', origin='imageservertest.g');
    note ('These tests include forced errors.  If the logger GUI is active ',
          priority='WARN', origin='imageservertest.g');
    note ('you should expect to see Red Boxes Of Death (RBOD) with many errors',
          priority='WARN', origin='imageservertest.g');
    note ('If the test finally returns T, then it has succeeded\n\n',
          priority='WARN', origin='imageservertest.g');
    note ('', priority='WARN', origin='imageservertest.g');
#
    fn := field_names(its.tests);
    const ntests := length(fn);
    if (is_unset(which)) which := [1:ntests];
    if (length(which)==1) which := [which];
#
    fn2 := fn[which];
    for (i in fn2) {
       msg := spaste('Failed ', i);
       if (i=='test1') {
          ok := its.tests.test1(imshape);
          if (is_fail(ok)) {
             msg2 := spaste ('Failed ', i, ' with ', ok::message);
             return throw(msg2, origin='imageservertest.g');
          } else if (!ok) {
             return throw(msg, origin='imageservertest.g');
          }
       } else {
          if (has_field(its.tests, i)) {
             ok := its.tests[i]();
             if (is_fail(ok)) {
                msg2 := spaste ('Failed ', i, ' with ', ok::message);
                return throw(msg2, origin='imageservertest.g');
             } else if (!ok) {
                return throw(msg, origin='imageservertest.g');
             }
          }
       }
    }
#
    return T;
}

