# e2estandards: e2e standards for processing projects end to end
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
#   $Id: e2estandards.g,v 19.0 2003/07/16 03:44:54 aips2adm Exp $
#

pragma include once;

e2estandards := function() {

  include 'quanta.g';

  public := [=];
  private := [=];
  
#
# Truncate a floating point number to significant digits
#
  private.sigdigits := function(x, digits=2) {
    if(x==0) return x;
    ex:=log(abs(x))
    v:=floor(10^(ex-floor(ex)+digits-1)+0.5)/10^(-floor(ex)+digits-1);
    if(x>0) {
      return v;
    }
    else {
      return -v;
    }  
  }

  private.baselines := [=];

  private.baselines['VLA']  := [A='35km', B='10km', C='3.3km', D='1km'];
  private.baselines['VLBA'] := [STD='8800km'];
  private.baselines['GBT']  := [STD='100m'];

  private.baseline := function(telescope='VLA', config='A') {
    wider private, public;
    if(!is_record(private.baselines[telescope])) {
      return throw('No information for telescope ', telescope);
    }
    if(!has_field(private.baselines[telescope], config)) {
      return throw('No information for configuration ', config,
    		   ' of telescope ', telescope);
    }
    return private.baselines[telescope][config];
  }
#
# Image parameters
#
  public.imageparameters := function(frequency='1.4GHz', telescope='VLA',
				      config='A') {
    wider private, public;
    c := dq.constants('c');
    b := private.baseline(telescope, config);
    if(is_fail(b)) return b;
    pix := 1024;
    facets := 1;
    cell := '1arcsec';
    alg := 'clark';
    cellq := dq.convert(dq.mul(dq.div(dq.div(c, frequency), b), '0.25rad'), 'arcsec');
    cell := spaste(private.sigdigits(cellq.value), 'arcsec');
# For low frequencies, image entire field of view
    if(dq.convert(frequency, 'GHz').value<2.0) {
      pix := [D=256, C=768, B=2400, A=8000];
      wave := 0.3/dq.convert(frequency, 'GHz').value;
      fac := [D=1,
	      C=max(1, as_integer(3.0*0.3/wave)), 
	      B=max(1, as_integer(10.0*0.3/wave)), 
	      A=max(1, as_integer(30.0*0.3/wave))]
      alg := [D='clark', C='wfclark', B='wfclark', A='wfclark'];
    }
    else {
# For high frequencies, image at most 1024 pixels
      pix := [D=256, C=768, B=1024, A=1024];
      fac := [D=1, C=1, B=1, A=1];
      alg := [D='clark', C='clark', B='clark', A='clark'];
    }
    return [pixels=pix[config], cell=cell, facets=fac[config], algorithm=alg[config]];
  }
#
# Guess as to whether MFS is required
#
  public.usemfs := function(frequency='1.4GHz', telescope='VLA',
			    config='A', nchan) {
    wider private, public;
    if(telescope=='VLA') {
      if(max(nchan)>8) return F;
    }
    else {
      if(max(nchan)>1) return F;
    }
    return T;
  }
#
# Atmospheric phase time
#
  public.selfcalparameters := function(frequency='1.4GHz', telescope='VLA',
				       config='A') {
    wider private, public;
    c := dq.constants('c');
    b := private.baseline(telescope, config);
    if(is_fail(b)) return b;


    frequency := dq.convert(frequency, 'GHz');
    t := '10s';
    if(frequency.value>1.0) {
      # Guess at tropospheric scaling
      t:= dq.mul(dq.mul('60s', dq.div('35km', b)),
      		 dq.div('1GHz', frequency));
      # This should scale!
    }
    else {
      # Guess at ionospheric scaling
      t:= dq.mul(dq.mul('60s', dq.div('35km', b)),
      		 dq.div(frequency, '1GHz'));
      # This should scale!
    }
    t.value :=private.sigdigits(t.value);
    times:=spaste(t.value, 's');
    threshold:='2mJy';
    return [tsol=times, threshold=threshold];
  }

  public.bands := function(frequency='1.4GHz') {
    f := dq.convert(frequency, 'GHz').value;
    if((f>0.048) && (f <0.096 )) {
      return '4'
    }
    if((f>0.298) && (f <0.345)) {
      return 'P'
    }
    if((f>1.15) && (f<1.75 )) {
      return 'L'
    }
    if((f>4.2) && (f<5.1)) {
      return 'C'
    }
    if((f>6.8) && (f<9.6)) {
      return 'X'
    }
    if((f> 13.5) && (f<16.3)) {
      return 'U'
    }
    if((f> 20.8) && (f<25.8)) {
      return 'K'
    }
    if((f> 38.0) && (f<51.0)) {
      return 'Q'
    }
    return throw('Frequency ', frequency, ' does not line in a designated band');
  }

  public.frequencyrange := function(band='L') {
    if(band=='4') {
      return [fmin='0.048GHz', 
	      fmax='0.096GHz'];
    }
    if(band=='P') {
      return [fmin='0.298GHz', 
	      fmax='0.345GHz'];
    }
    if(band=='L') {
      return [fmin='1.15GHz', 
	      fmax='1.75GHz'];
    }
    if(band=='C') {
      return [fmin='4.2GHz', 
	      fmax='5.1GHz'];
    }
    if(band=='X') {
      return [fmin='6.8GHz', 
	      fmax='9.6GHz'];
    }
    if(band=='U') {
      return [fmin='13.5GHz', 
	      fmax='16.3GHz'];
    }
    if(band=='K') {
      return [fmin='20.8GHz', 
	      fmax='25.8GHz'];
    }
    if(band=='Q') {
      return [fmin='38.0GHz', 
	      fmax='51.0GHz'];
    }
    return throw('Band ', band, ' is unknown');
  }

  public.fluxcalibrators := function(telescope='VLA') {
    wider private;
    
    fluxsources := '';

    if(telescope=='VLA') {
      fluxsources := "1331+305 1328+307 3C286 3C48 0134+329 0137+331 3C147 0538+498 0542+498 3C138 0518+165 0521+166 1934-638 3C295 1409_524 1411+522";
    }
    return fluxsources;
  }

  public.type := function() {
    return "e2estandards";
  }

  public.done := function() {
    wider private, public;
    return T;
  }
  return ref public;
}

e2estandardstest := function() {
  e2es := e2estandards();
  telescope:="VLA"
  frequency:="0.327GHz 1.4GHz 5GHz 8GHz 14GHz 22GHz 43GHz";
  config := "A B C D";
  note('Imaging');
  for (freq in frequency) {
    note ('  Frequency ', freq);
    for (cnf in config) {
      note('    Configuration ', cnf, ' ', e2es.imageparameters(telescope=telescope, frequency=freq,
							      config=cnf));      
    }
  }
  note('Self-calibration');
  for (freq in frequency) {
    note ('  Frequency ', freq);
    for (cnf in config) {
      note('    Configuration ', cnf, ' ', e2es.selfcalparameters(telescope=telescope, frequency=freq,
								config=cnf));
    }
  }
  return T;
}
