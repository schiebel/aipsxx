# interpolate1d.g: The glish side of the interpolate1d distributed object
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
#   $Id: interpolate1d.g,v 19.2 2004/08/25 01:44:22 cvsmgr Exp $
#
pragma include once
  
include "servers.g";
include "note.g";
# server := interpolate1d()
# interpolate1ddemo()
# interpolate1dtest()
#    ok := interpolate1d.initialize(x,y,method=linear)
#    ok := interpolate1d.setmethod(method)
#     y := interpolate1d.interpolate(x)
#

const interpolate1d := function(host='', forcenewserver=F) {
  private := [=];
  public := [=];

  private.agent := defaultservers.activate("numerics", host, forcenewserver);
  private.id := defaultservers.create(private.agent, "interpolate1d");

  private.interpolateRec := [_method="interpolate",
			     _sequence=private.id._sequence];
  public.interpolate := function(x) {
    wider private;
    private.interpolateRec.x := x;
    return defaultservers.run(private.agent, private.interpolateRec);
  }

  private.initializeRec := [_method="initialize",
			    _sequence=private.id._sequence];
  public.initialize := function(x,y,method='linear') {
    wider private;
    private.initializeRec.x := x;
    private.initializeRec.y := y;
    private.initializeRec.method := method;
    return defaultservers.run(private.agent, private.initializeRec);
  }

  private.setmethodRec := [_method="setmethod",
			   _sequence=private.id._sequence];
  public.setmethod := function(method='linear') {
    wider private;
    private.setmethodRec.method := method;
    return defaultservers.run(private.agent, private.setmethodRec);
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
  
  public.type := function() {return 'interpolate1d';}

  return public;
} #interpolate1d constructor

const interpolate1ddemo := function() {
  interp := interpolate1d();

  x := [1:10];
  y := x;
  method := 'nearest_neighbor';

  ok := interp.initialize(x, y, method);
  note( 'ok := interp.initialize(x, y, method)',
       '\n\tok=', ok, ' (output) (did the initialize succeed)',
       '\n\tx=', x, '(input)',
       '\n\ty=', y, '(input)',
       '\n\tmethod=', method, '(input)',
       origin='interpolate1ddemo()');

  x +:= 0.5;
  result := interp.interpolate(x);
  note('result := interp.interpolate(x)',
       '\n\tx=', x, '(input) (shifted by +0.5)',
       '\n\tresult=', result, '(output)',
       origin='interpolate1ddemo()');

  interp.setmethod('linear'); result := interp.interpolate(x);
  note('interp.setmethod(\'linear\'); result := interp.interpolate(x)',
       '\n\tx=', x, '(input) (shifted by +0.5)',
       '\n\tresult=', result, '(output)',
       origin='interpolate1ddemo()');

  interp.setmethod('cubic'); result := interp.interpolate(x);
  note('interp.setmethod(\'cubic\'); result := interp.interpolate(x)',
       '\n\tx=', x, '(input) (shifted by +0.5)',
       '\n\tresult=', result, '(output)',
       origin='interpolate1ddemo()');

  interp.setmethod('spline'); result := interp.interpolate(x);
  note('interp.setmethod(\'spline\'); result := interp.interpolate(x)',
       '\n\tx=', x, '(input) (shifted by +0.5)',
       '\n\tresult=', result, '(output)',
       origin='interpolate1ddemo()');

  return T;
}

const interpolate1dtest := function() {
  note('Just running interpolate1ddemo() - we should have a real test',
       origin='interpolate1dtest()');
  return interpolate1ddemo();
}

