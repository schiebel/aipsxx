# fftserver.g: The Glish side of the fftserver object
#
#   Copyright (C) 1996,1997,1998,1999,2001
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
#   $Id: fftserver.g,v 19.2 2004/08/25 01:43:29 cvsmgr Exp $
#
pragma include once

include "servers.g";
include "note.g"

# server := fftserver()
# fftserverdemo()
# fftservertest()
#        fftserver.complexfft(a,dir)
#      b:= fftserver.realtocomplexfft(a)
#      c:= fftserver.convolve(a,b)
#      c:= fftserver.crosscorr(a,b)
#      b:= fftserver.autocorr(a)
#      b:= fftserver.shift(a,shift)

const fftserver := function(host='', forcenewserver=F) {

  private := [=];
  public := [=];
	
  private.agent := defaultservers.activate("numerics", host, forcenewserver);
  private.id := defaultservers.create(private.agent, "fftserver");

  private.complexfftRec := [_method="complexfft", 
			    _sequence=private.id._sequence];
  public.complexfft := function(ref a, dir) {
    wider private;
    private.complexfftRec.a := a;
    private.complexfftRec.dir := dir;
    returnval := defaultservers.run(private.agent, private.complexfftRec);
    val a := private.complexfftRec.a;
    private.complexfftRec.a := 0; # might be large
    return returnval;
  }

  private.realtocomplexfftRec := [_method="realtocomplexfft", 
				  _sequence=private.id._sequence];
  public.realtocomplexfft := function(a) {
    wider private;
    private.realtocomplexfftRec.a := a;
    return defaultservers.run(private.agent, private.realtocomplexfftRec);
  }

  private.convolveRec := [_method="convolve", _sequence=private.id._sequence];
  public.convolve := function(a,b) {
    wider private
      private.convolveRec.a := a;
    private.convolveRec.b := b;
    return defaultservers.run(private.agent, private.convolveRec);
  }

  private.crosscorrRec := [_method="crosscorr",
			   _sequence=private.id._sequence];
  public.crosscorr := function(a,b) {
    wider private;
    private.crosscorrRec.a := a;
    private.crosscorrRec.b := b;
    return defaultservers.run(private.agent, private.crosscorrRec);
  }

  private.autocorrRec := [_method="autocorr", _sequence=private.id._sequence];
  public.autocorr := function(a) {
    wider private;
    private.autocorrRec.a := a;
    return defaultservers.run(private.agent, private.autocorrRec);
  }

  private.shiftRec := [_method="shift", _sequence=private.id._sequence];
  public.shift := function(a,shift) {
    wider private;
    private.shiftRec.a := a;
    private.shiftRec.shift := shift;
    return defaultservers.run(private.agent, private.shiftRec);
  }

  private.mfftRec := [_method="mfft", 
		      _sequence=private.id._sequence];
  public.mfft := function(a, axes, forward=T) {
    if (!is_numeric(a)) {
      note('The input array must be numeric!',
	   priority='SEVERE', 
	   origin='fftserver::mfft');
      fail 'The input array must be numeric!';
    }
    if (len(a::shape) != len(axes)) {
      note('The number of dimensions on the input array does not match ',
	   '\nthe length of the axes vector', priority='SEVERE', 
	   origin='fftserver::mfft');
      fail 'The dimensions of the input array and elements on the axes vector do not match';
    }
    if (!is_boolean(axes)) {
      note('Converting the axes vector elements to booleans',
	   priority='WARN', 
	   origin='fftserver::mfft');
    }
    if (!is_boolean(forward)) {
      note('Converting the forward argument to a boolean',
	   priority='WARN', 
	   origin='fftserver::mfft');
    }
    wider private;
    private.mfftRec.a := as_complex(a);
    private.mfftRec.axes := as_boolean(axes);
    private.mfftRec.forward := as_boolean(forward);
    return defaultservers.run(private.agent, private.mfftRec);
  }

  const public.done  := function() {
    wider public, private;
    ok := defaultservers.done(private.agent, private.id.objectid);
    if (ok) {
      val private := F;
      val public := F;
    }
    return ok;
  }

  public.type := function() {return 'fftserver';}

  return public;
} # fftserver constructor

const fftserverdemo := function() {
  # Make the server
  server := fftserver();
    
    # complexfft()
  a[1:8] := 1+0i;
  dir := 1;
  pre := a;
  server.complexfft(a, dir);
  note('complexfft of \ta(in)=', pre, '\n\t\tdir=', dir, '\n\t\ta(out)=', a,
       origin='fftserverdemo');
  dir := -1;
  pre := a;
  server.complexfft(a, dir);
  note('complexfft of \ta(in)=', pre, '\n\t\tdir=', dir, '\n\t\ta(out)=', a,
       origin='fftserverdemo');

  # realtocomplexfft()
  a[1:8] := 0; a[5] := 8;
  b := server.realtocomplexfft(a);
  note('realtocomplexfft of \ta(in)=', a, '\n\t\t\t\tb=', b,
       origin='fftserverdemo');

  # convolve()
  a := rep(0,8); a[5] := 8;
  b := [0.25, 0.5, 1, 0.5, 0.25];
  c := server.convolve(a,b);
  note('c := convolve(a,b)\n\ta=', a, '\n\tb=', b, '\n\tc=', c, 
       origin='fftserverdemo');

  # crosscorr()
  a := rep(0,8); a[1] := 1;
  b := [1:8];
  c := server.crosscorr(a,b);
  note('c := crosscor(a,b)\n\ta=', a, '\n\tb=', b, '\n\tc=', c,
       origin='fftserverdemo');
  # autocorr()
  a := [0,0,0,1,2,1,0,0];
  b := server.autocorr(a);
  note('b := autocorr(a)\n\ta=', a, '\n\tb=', b, origin='fftserverdemo()');

  # shift()
  a := [0,0,0,0,1,0,0,0];
  shift := -2;
  b := server.shift(a, shift);
  note('b := shift(a,shift)\n\ta=', a, '\n\tshift=', shift, '\n\tb=', b,
       origin='fftserverdemo');

  # mfft()
  a := array(0,3,3);
  a[2,2] := 1;
  note('mfft of a(in) =\t', a[1:3,1], '\n\t\t', a[1:3,2], '\n\t\t', a[3,1:3],
       origin='fftserverdemo');
  axes := [F,T];
  note('along axes =\t', axes, origin='fftserverdemo');
  b := server.mfft(a, axes);
  note('b := mfft(a,axes) = \t', b[1:3,1], 
       '\n\t\t\t', b[1:3,2],'\n\t\t\t', b[1:3,3],
       origin='fftserverdemo');

  # done()
  server.done();
  return T
}

const fftservertest := function() {
  note('Just running fftserverdemo() - we should have a real test',
       origin='fftservertest');
  return fftserverdemo();
}
