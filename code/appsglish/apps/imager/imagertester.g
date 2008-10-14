# imagertester: test tool for imager
# Copyright (C) 2002,2003
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: imagertester.g,v 19.1 2004/08/25 01:20:30 cvsmgr Exp $

# Include guard
pragma include once
 
# Include files

include 'imager.g'
include 'imagerpositiontest.g'
include 'plugins.g';

const _define_imagertester := function() {

  private := [=];
  public := [=];
  

#### SINGLE FIELD TEST typical centimetric imaging

  public.runtests := function(testname='all'){

    if (testname == 'all'){
      testname:=['sftest', 'mftest', 'wftest', 'spectraltest', 'memtest', 
		'nnlstest','utiltest']
    }

    if(testname=='lite'){
       testname := ['sftest', 'utiltest']
    }

    if(testname=='beta'){
       testname := ['sftest', 'mftest', 'wftest', 'spectraltest', 'memtest', 
		    'nnlstest','utiltest']
    }

    for (tests in testname){
      if(tests=='sftest') mylog:=private.sftest();
      if(tests=='mftest') mylog:=private.mftest();
      if(tests=='wftest') mylog:=private.wftest();
      if(tests=='spectraltest') mylog:=private.spectraltest();
      if(tests=='memtest') mylog:=private.memtest();
      if(tests=='nnlstest') mylog:=private.nnlstest();
      if(tests=='utiltest') private.utiltest();

    }


    
    ok:=T
    x := open(spaste("< ", mylog));
      while ( line := read(x) ){
	myword:=split(line);
	if(myword[1]=='%%ERROR'){
	  note(line, priority='SEVERE');
	  ok:=F;
	}
	else{
	  note(line);
	}
      }
    if(!ok)  throw('Imagertest fails!')
    return ok;
  }

  private.sftest := function(){
    
    testdir:='IMAGERSFTEST';
    mytest:=imagerpositiontest('IMAGERSFTEST');
    mytest.makedefaultsimulator(frequency='8GHz', arrayscale=0.5);
    mytest.makedefaultcl('IMAGERSFTEST/true.cl', frequency='8GHz', 
			 nsources=5, minsep=20);
    mytest.makems();
    for (algo in ['hogbom', 'clark', 'multiscale']){
      testname:=spaste('IMAGER SINGLE FIELD ',algo);
      mytest.setcleanparms(algorithm=algo, niter=200);
      imagename:=spaste('IMAGERSFTEST/CLEAN',algo);
      clname:=spaste('IMAGERSFTEST/found.cl',algo);
      mytest.makeimage(imagename=imagename)  ;
      mytest.findsource(numsources=5, imagename=spaste(imagename,'.restored'), 
			clname=clname);
      result:=mytest.sourcecompare(clname, 'IMAGERSFTEST/true.cl');
      myim:=image(spaste(imagename,'.residual'));
      myim.statistics(statreg);
      myim.done();
      extrainfo:=spaste("Residual: Max ",as_string(statreg.max), " Min ", 
			as_string(statreg.min), " Rms ", 
			as_string(statreg.rms)); 
      logname:= mytest.logresult(spaste(testname,' NO SHIFT'), result, 
				 testdir, extrainfo);
########   
      mytest.setcleanmask('comps');
      imagename:=spaste('IMAGERSFTEST/CLEAN_masked',algo);
      clname:=spaste('IMAGERSFTEST/found_masked.cl',algo);
      mytest.makeimage(imagename=imagename);
      mytest.findsource(numsources=5, 
			imagename=spaste(imagename,'.restored'), 
			clname=clname);
      result:=mytest.sourcecompare(clname, 'IMAGERSFTEST/true.cl');
      myim:=image(spaste(imagename,'.residual'));
      myim.statistics(statreg);
      myim.done();
      extrainfo:=spaste("Residual: Max ",as_string(statreg.max), " Min ", 
			as_string(statreg.min), " Rms ", 
			as_string(statreg.rms)) ;
      logname:=mytest.logresult(spaste(testname,' MASKED'), result, testdir, 
				extrainfo);
######
      mytest.setcleanmask('all');	   
      imagedir:=mytest.getcenterposition();
      imagedir.m0:=dq.add(imagedir.m0, '5arcsec'); 
      imagedir.m1:=dq.add(imagedir.m1, '10arcsec');

      imagename:=spaste('IMAGERSFTEST/CLEAN_shift',algo);
      clname:=spaste('IMAGERSFTEST/found_shift.cl',algo);
      mytest.setimagingparms(doshift=T, phasecenter=imagedir);
      mytest.makeimage(imagename=imagename) ;
      mytest.findsource(numsources=5, 
			imagename=spaste(imagename,'.restored'), 
			clname=clname);
      result:=mytest.sourcecompare( clname, 
				   'IMAGERSFTEST/true.cl');
      myim:=image(spaste(imagename,'.residual'));
      myim.statistics(statreg);
      myim.done();
      extrainfo:=spaste("Residual: Max ",as_string(statreg.max), " Min ", 
			as_string(statreg.min), " Rms ", 
			as_string(statreg.rms)) ;
      logname:=mytest.logresult(spaste(testname,' WITH SHIFT'), result, 
		       testdir, extrainfo);
    }
    return logname;
  }

private.wftest := function(){

  testdir:='IMAGERWFTEST';
  mytest:=imagerpositiontest('IMAGERWFTEST');
  mytest.setsimparms(frequency='74MHz', source_spread=1.0, nsources=10);
  mytest.makedefaultsimulator(frequency='74MHz', arrayscale=2.0);
  mytest.makedefaultcl('IMAGERWFTEST/true.cl', frequency='74MHz', nsources=10,
		       minsep=40);
  mytest.settolerance(2.0);
  mytest.makems();
  mytest.setimagingparms(facets=5);
  for (algo in ['wfclark', 'wfhogbom']){
    testname:=spaste('IMAGER  WIDE FIELD ',algo);
    mytest.setcleanparms(algorithm=algo, niter=300);
    imagename:=spaste('IMAGERWFTEST/CLEAN',algo);
    clname:=spaste('IMAGERWFTEST/found.cl',algo);
    mytest.makeimage(imagename=imagename)  ;
    mytest.findsource(numsources=10, imagename=spaste(imagename,'.restored'), 
		      clname=clname);
    result:=mytest.sourcecompare(clname, 'IMAGERWFTEST/true.cl');
    myim:=image(spaste(imagename,'.residual'));
    myim.statistics(statreg);
    myim.done();
    extrainfo:=spaste('Residual: Max ',as_string(statreg.max), ' Min ', 
		      as_string(statreg.min), ' Rms ', 
		      as_string(statreg.rms)) ;
    logname:=mytest.logresult(spaste(testname,' NO SHIFT'), result, testdir, 
			      extrainfo);
########   
    mytest.setcleanmask('comps');
    imagename:=spaste('IMAGERWFTEST/CLEAN_masked',algo);
    clname:=spaste('IMAGERWFTEST/found_masked.cl',algo);
    mytest.makeimage(imagename=imagename);
    mytest.findsource(numsources=10, 
		      imagename=spaste(imagename,'.restored'), 
		      clname=clname);
    result:=mytest.sourcecompare(clname, 'IMAGERWFTEST/true.cl');
    myim:=image(spaste(imagename,'.residual'));
    myim.statistics(statreg);
    myim.done();
    extrainfo:=spaste('Residual: Max ',as_string(statreg.max), ' Min ', 
		      as_string(statreg.min), ' Rms ', 
		      as_string(statreg.rms)) ;
    logname:=mytest.logresult(spaste(testname,' MASKED'), result, testdir, 
			      extrainfo);

######
    mytest.setcleanmask('all');	   
    imagedir:=mytest.getcenterposition();
    imagedir.m0:=dq.add(imagedir.m0, '5arcsec') ;
    imagedir.m1:=dq.add(imagedir.m1, '10arcsec');

    imagename:=spaste('IMAGERWFTEST/CLEAN_shift',algo);
    clname:=spaste('IMAGERWFTEST/found_shift.cl',algo);
    mytest.setimagingparms(doshift=T, phasecenter=imagedir);
    mytest.makeimage(imagename=imagename) ;
    mytest.findsource(numsources=10, 
		      imagename=spaste(imagename,'.restored'), 
		      clname=clname);
    result:=mytest.sourcecompare( clname, 
				 'IMAGERWFTEST/true.cl');
    myim:=image(spaste(imagename,'.residual'));
    myim.statistics(statreg);
    myim.done();
    extrainfo:=spaste('Residual: Max ',as_string(statreg.max), ' Min ', 
		      as_string(statreg.min), ' Rms ', 
		      as_string(statreg.rms)) ;
    logname:=mytest.logresult(spaste(testname,' WITH SHIFT'), result, testdir, 
		     extrainfo);
  
  }
  return logname;
}

private.mftest := function(){

  testdir:='IMAGERMFTEST';
  mytest:=imagerpositiontest('IMAGERMFTEST');
  mytest.setsimparms(frequency='1.4GHz', source_spread=0.8, nfields=4, 
		     nsources=5);
  mytest.makedefaultsimulator(frequency='1.4GHz', arrayscale=1.0);
  mytest.makedefaultcl('IMAGERMFTEST/true.cl', frequency='1.4GHz', nsources=5,
		       minsep=20);
  mytest.makems();
  for (algo in ['mfclark', 'mfhogbom', 'mfmultiscale']){

    testname:=spaste('IMAGER  MULTI FIELD ',algo);
    mytest.setcleanparms(algorithm=algo, niter=200);
    imagename:=spaste('IMAGERMFTEST/CLEAN',algo);
    clname:=spaste('IMAGERMFTEST/found.cl',algo);
    mytest.makeimage(imagename=imagename) ; 
    mytest.findsource(numsources=5, imagename=spaste(imagename,'.restored'), 
		      clname=clname);
    result:=mytest.sourcecompare(clname, 'IMAGERMFTEST/true.cl');
    myim:=image(spaste(imagename,'.residual'));
    myim.statistics(statreg);
    myim.done();
    extrainfo:=spaste('Residual: Max ',as_string(statreg.max), ' Min ', 
		      as_string(statreg.min), ' Rms ', 
		      as_string(statreg.rms)) ;
    logname:=mytest.logresult(spaste(testname,' NO SHIFT'), result, testdir, 
		     extrainfo);   
########   
    mytest.setcleanmask('comps');
    imagename:=spaste('IMAGERMFTEST/CLEAN_masked',algo);
    clname:=spaste('IMAGERMFTEST/found_masked.cl',algo);
    mytest.makeimage(imagename=imagename);
    mytest.findsource(numsources=5, 
		      imagename=spaste(imagename,'.restored'), 
		      clname=clname);
    result:=mytest.sourcecompare(clname, 'IMAGERMFTEST/true.cl');
    myim:=image(spaste(imagename,'.residual'));
    myim.statistics(statreg);
    myim.done();
    extrainfo:=spaste('Residual: Max= ',as_string(statreg.max), ' Min ', 
		      as_string(statreg.min), ' Rms ', 
		      as_string(statreg.rms)) ;
    logname:=mytest.logresult(spaste(testname,' MASKED '), result, testdir,
			      extrainfo);
######
  }
  return logname;
}

private.spectraltest := function(){

 testdir:='IMAGERSPECTRALTEST';
 mytest:=imagerpositiontest('IMAGERSPECTRALTEST');
 mytest.setsimparms(frequency='8GHz', nchan=8, nsources=5);
 mytest.makedefaultsimulator(frequency='8GHz', arrayscale=0.5);

 mytest.makedefaultcl('IMAGERSPECTRALTEST/true.cl', frequency='8GHz', 
		      nsources=5, minsep=20);
 mytest.makems();
 for (algo in ['hogbom', 'clark']){
   testname:=spaste('IMAGER SPECTRAL ',algo);
   mytest.setcleanparms(algorithm=algo, niter=200);
   imagename:=spaste('IMAGERSPECTRALTEST/CLEAN',algo);
   clname:=spaste('IMAGERSPECTRALTEST/found.cl',algo);
   mytest.setimagingparms(mode='channel', nchan=8);
   mytest.makeimage(imagename=imagename)  ;
   mytest.findsource(numsources=5, imagename=spaste(imagename,'.restored'), 
		     clname=clname);
   result:=mytest.sourcecompare(clname, 'IMAGERSPECTRALTEST/true.cl');
   myim:=image(spaste(imagename,'.residual'));
   myim.statistics(statreg);
   myim.done();
   extrainfo:=spaste("Residual: Max ",as_string(statreg.max), " Min ", 
		     as_string(statreg.min), " Rms ", as_string(statreg.rms)) ;
   logname:=mytest.logresult(testname, result, testdir, extrainfo);


 }
 return logname;
}

private.memtest :=function(){
   testdir:='IMAGERMEMTEST';
   mytest:=imagerpositiontest('IMAGERMEMTEST');
   mytest.makedefaultsimulator(frequency='8GHz', arrayscale=0.5);
   mytest.makedefaultcl('IMAGERMEMTEST/true.cl', frequency='8GHz', 
			nsources=5, minsep=20);
   mytest.makems();
   mytest.setdeconvolutionfunction('mem');
   testname:=spaste('IMAGER MEM TEST ');
   imagename:=spaste('IMAGERMEMTEST/MEM');
   clname:=spaste('IMAGERMEMTEST/found.cl');
   mytest.setmemparms(algorithm='entropy', sigma='0.1Jy');
   mytest.makeimage(imagename=imagename)  ;
   mytest.findsource(numsources=5, imagename=spaste(imagename,'.restored'), 
		     clname=clname);
   result:=mytest.sourcecompare(clname, 'IMAGERMEMTEST/true.cl');
   myim:=image(spaste(imagename,'.residual'));
   myim.statistics(statreg);
   myim.done();
   extrainfo:=spaste("Residual: Max ",as_string(statreg.max), " Min ", 
		     as_string(statreg.min), " Rms ", 
		     as_string(statreg.rms)); 
   logname:=mytest.logresult(spaste(testname,''), result, testdir, 
		    extrainfo);
   
   return logname;

}

private.nnlstest := function(){
    testdir:='IMAGERNNLSTEST';
    mytest:=imagerpositiontest('IMAGERNNLSTEST');
    mytest.makedefaultsimulator(frequency='8GHz', arrayscale=0.5);
    mytest.makedefaultcl('IMAGERNNLSTEST/true.cl', frequency='8GHz', 
			 nsources=1, minsep=20);
    mytest.makems();
    mytest.setdeconvolutionfunction('nnls');

    testname:=spaste('IMAGER NNLS TEST ');
    imagename:=spaste('IMAGERNNLSTEST/NNLS');
    clname:=spaste('IMAGERNNLSTEST/found.cl');
    mytest.setcleanmask('comps');
    mytest.makeimage(imagename=imagename)  ;
    mytest.findsource(numsources=1, imagename=spaste(imagename,'.restored'), 
			clname=clname);
    result:=mytest.sourcecompare(clname, 'IMAGERNNLSTEST/true.cl');
    myim:=image(spaste(imagename,'.residual'));
    myim.statistics(statreg);
    myim.done();
    extrainfo:=spaste("Residual: Max ",as_string(statreg.max), " Min ", 
		      as_string(statreg.min), " Rms ", 
		      as_string(statreg.rms)); 
    logname:=mytest.logresult(spaste(testname,''), result, testdir, 
		     extrainfo);
    return logname;

}


private.utiltest := function(){

  wider public, private;
  testdir := 'IMAGERUTILTEST/';
  note('Cleaning up directory ', testdir);
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); }
  ok := shell(paste("mkdir", testdir));
  if (ok::status) { throw("mkdir", testdir, "fails!") }
  
  ntest := 0;
  results := [=];
  msfile:=spaste(testdir, '3C273XC1.ms');
  imagermaketestms(msfile);
  myimager:=imager(filename=msfile);
  ok :=myimager.setimage(nx=256, ny=256, cellx="0.7arcsec" ,
			 celly="0.7arcsec" , stokes="IV" , doshift=F,
			 nchan=1, 
			 start=1, step=1,
			 mstart="0km/s" , mstep="0km/s" , spwid=1, 
			 fieldid=1, facets=1);


  nametest := 'plotsummary';
  note('### Test imager.plotsummary ###');
    ntest +:=1;
  ok :=myimager.plotsummary();
  private.checkresult(ok, ntest, nametest, results);
  nametest := 'plotuv';
  note('### Test imager.plotuv ###');
  
    for (rotate in [T, F]) {
      ntest +:=1;
      ok :=myimager.plotuv(rotate=rotate);
      private.checkresult(ok, ntest, nametest, results);
    }
  
  nametest := 'plotvis';
  note('### Test imager.plotvis ###');
    
    for (type in ['all', 'observed', 'model', 'corrected', 'residual']) {
      ntest +:=1;
      ok :=myimager.plotvis(type="all" , increment=1);
      private.checkresult(ok, ntest, nametest, results);
    }
  nametest := 'fitpsf';
  note('### Test imager.fitpsf ###');
  
    ntest +:=1;
  bmaj := F;
  bmin := F;
  bpa := F;
  ok :=myimager.fitpsf(psf='', bmaj=bmaj , bmin=bmin , bpa=bpa);
  ok := ok && dq.check(bmaj);
  ok := ok && dq.check(bmin);
  ok := ok && dq.check(bpa);
  private.checkresult(ok, ntest, nametest, results);
  nametest := 'makeimage';
  note('### Test imager.makeimage ###');
  

    for (type in ['observed', 'model', 'corrected', 'residual', 'psf']) {
      ntest +:=1;
      ok :=myimager.makeimage(type , image=spaste(testdir, spaste("3C273XC1.", type)) ,
			      compleximage=spaste(testdir, spaste("3C273XC1.c", type)) );
      ok := ok && tableexists(spaste(testdir, spaste("3C273XC1.", type)));
      ok := ok && tableexists(spaste(testdir, spaste("3C273XC1.c", type)));
      private.checkresult(ok, ntest, nametest, results);
  }

  nametest := 'sensitivity';
  note('### Test imager.sensitivity ###');
  
    ntest +:=1;
  pointsource:="0Jy";
  relative:=-1.0;
  sumweights:=-1.0;
  ok :=myimager.sensitivity(pointsource="0Jy" , relative=relative,
			    sumweights=sumweights);
  ok := ok && dq.check(pointsource);
  ok := ok && (relative > 0.9999999);
  ok := ok && (sumweights > 0.0);
  private.checkresult(ok, ntest, nametest, results);
  nametest := 'clipvis';
  note('### Test imager.clipvis ###');
  
  ntest +:=1;
  ok :=myimager.clipvis(threshold='100mJy');
  private.checkresult(ok, ntest, nametest, results);
  myimager.done();
  nfailed := 0;
  for (result in results) {
    if(result!='') {
      nfailed+:=1;
      note(result);
    }
  }
}

### Done function
  const public.done := function(){
    wider private, public;
    private := F;
    public  := F;
    return T;
  }

  const public.cleanup := function(){

    listdir := ['IMAGERSFTEST', 'IMAGERMFTEST', 'IMAGERWFTEST', 
		'IMAGERSPECTRALTEST', 'IMAGERMEMTEST', 'IMAGERUTILTEST', 
		'IMAGERNNLSTEST'];
    for (mydir in listdir){

      if(dos.fileexists(mydir))
	shell(paste("rm -fr ", mydir));

    }		  


  }


private.checkresult := function(ok, ntest, nametest, ref results) {

    results[ntest] := '';

    if(is_fail(ok)) {
      results[ntest] := paste("Test", ntest, " on ", nametest, "failed ", ok::message);
    }
    else if(is_boolean(ok)) {
      if(!ok) results[ntest] := paste("Test", ntest, " on ", nametest, "failed ", ok::message);
    }
    else {
      results[ntest] := paste("Test", ntest, " on ", nametest, "returned", ok);
    }
  }

  plugins.attach('imagertester', public);
  return ref public;


} # _define_imagertester()





const imagertester := function() {
#   
   return ref _define_imagertester();
} 

