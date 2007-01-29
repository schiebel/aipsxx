# imageevaluator.g: definition of imageevaluator
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
#   $Id: imageevaluator.g,v 19.1 2004/08/25 01:51:58 cvsmgr Exp $
#

pragma include once;

include "image.g";
include "regionmanager.g";
include "coordsys.g";
include "fftserver.g";


const imageevaluator := subsequence(myimage='') {

  if (!serverexists('drm', 'regionmanager', drm)) {
    return throw('The regionmanager server "drm" is not running',
		 origin='imageevaluator.g');
  }

  private :=[=];

  private.imagename := myimage;
  private.image := image(myimage);
  if(is_fail(private.image)) fail;


  const self.type := function() {
     return 'imageevaluator';
  }

  const self.dynamicrange := function(offregion=unset) {
     wider private;
     mystats := [=];
     ok := private.image.statistics(statsout=mystats, region=offregion);
     if (is_fail(ok)) fail;
     rms := mystats.rms;

     all :=  drm.box(); 
     private.image.bb(all);
     ok := private.image.statistics(statsout=mystats, region=all);
     if (is_fail(ok)) fail;
     peak := mystats.max;
     all.done();

     dynamicrange := 0.0;
     if (rms > 0.0) {
       dynamicrange := peak/rms;
     }
     self.dr := dynamicrange;

     note ('Dynamic range of ', private.imagename, 
		  ' = ', self.dr);
     return T;
  }


  const self.fidelity := function(model='', modmin=0.001, 
			      mode='median', moment=1.0) {
    wider private;
    if (model == '') {
      return throw('A model image is required to calculate image fidelity',
		   origin='imageevaluator.g');
    }

    modimg := image(model)
    shapemodel := modimg.shape();
    shapeimage := private.image.shape();
    shapediff := sum(abs(shapemodel - shapeimage));
    if ( shapediff != 0 ) {
      return throw('model image must be the same shape as reconstructed image',
		   origin='imageevaluator.g');
    }

    arrimage := private.image.getchunk();
    if (is_fail(arrimage)) fail;
    arrmodel := modimg.getchunk();
    if (is_fail(arrmodel)) fail;

# make gaussian
#---------------------------------  get beam from image
    rb := private.image.restoringbeam();
    if (is_fail(rb)) fail;    
    if (length(rb)==0) {
       return throw('could not find beam information',
  		    origin='imageevaluator.g');
    }
    bmaj := dq.convert(rb.major, "rad" ).value;
    if (is_fail(bmaj)) fail;
    bmin := dq.convert(rb.minor, "rad" ).value;
    if (is_fail(bmin)) fail;
    bpa  := dq.convert(rb.positionangle, "rad" ).value;
    if (is_fail(bpa)) fail;
#----------------------------------
    cs := private.image.coordsys(axes=[1,2]); 
    if (is_fail(cs)) fail;
#
    delta := cs.increment(format='q');
    delta1 := dq.convert(delta[1], "rad" ).value;
    if (is_fail(delta1)) fail;
    delta2 := dq.convert(delta[2], "rad" ).value;
    if (is_fail(delta2)) fail;
#
    if (is_fail(cs.done())) fail;
#----------------------------------
    npix := as_integer( 10 * max( abs(bmaj/delta1), abs(bmaj/delta2) ) );
    npix := 2* (as_integer(npix/2+1));
    npix := max ( npix, 4);
    gaussian := array(0, npix, npix);
    cospa := cos(bpa);
    sinpa := sin(bpa);
    center := npix/2+1;
    rbmaj := ln(2.0)/(bmaj/delta1/2.0)^2;
    rbmin := ln(2.0)/(bmin/delta1/2.0)^2;
    for (ix in 1:npix) { 
      for (iy in 1:npix) { 
	u :=   cospa * (ix-center) + sinpa * (iy-center);
	v := - sinpa * (ix-center) + cospa * (iy-center);
	r := rbmaj*u^2 + rbmin*v^2;
	gaussian[ix,iy] := exp(-r);
       }
    }
# convolve with gaussian
    myfft := fftserver();
    arrmodelconv := myfft.convolve(arrmodel, gaussian);
    myfft.done();                                 
    arrmodel := F;
    gaussian := F;

    epsilon := max(modmin/1000, 0.0000001);
    arrdiff := abs(arrimage - arrmodelconv) + epsilon;
    arrimage := F;

    arrfid := arrmodelconv[ (arrmodelconv > modmin) ] / 
        arrdiff[ (arrmodelconv > modmin) ];       
    arrdiff := F;
    if (len(arrfid) <= 0) {
      return throw('no pixels left to calculate fidelity from',
		   origin='imageevaluator.g');
    }

    if (mode == 'median') {
      sortedfid := sort( arrfid );                  
      self.fid := sortedfid[ (len(sortedfid))/2 ];    
      note ('Median fidelity of ', private.imagename, ' = ', self.fid);
      sortedfid := F;
    } else if (mode == 'moment') {
      arrfid := arrfid * (arrmodelconv[ (arrmodelconv > modmin) ])^moment;
      self.fid := sum( arrfid ) / len( arrfid );
      note ('Moment ', moment,' fidelity of ', private.imagename, ' = ', self.fid);

    }
    arrfid := F;
    modimg.done();
    
    return T;
  }

  const self.done := function()
  {
    wider private, self;
    private.image.done();
    private := F;
    val self := F;
    return T;
  }

#  return ref self;


  }
# end of constructor



const  imageevaluatortest  :=  function(image='') {

  ime := imageevaluator(image);
  r := drm.box(blc="1 1 1", trc="20 20 1")
  ime.dynamicrange(r);
  
  ime.done();

  }




