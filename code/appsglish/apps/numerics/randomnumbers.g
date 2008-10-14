# randomnumbers.g: The Glish side of the randomnumbers distributed object
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001
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
#   $Id: randomnumbers.g,v 19.2 2004/08/25 01:45:33 cvsmgr Exp $
#

pragma include once

include 'unset.g';

const randomnumbers := function(host='', forcenewserver=F) {
  private := [=];
  public := [=];

  include 'servers.g';
  private.agent := defaultservers.activate('numerics', host, forcenewserver);
  private.id := defaultservers.create(private.agent, 'randomnumbers');

  private.binomialRec := [_method='binomial', 
			  _sequence=private.id._sequence];
  const public.binomial := function(number=1, probability=0.5, shape=1) {
    wider private;
    private.binomialRec.number := number;
    private.binomialRec.probability := probability;
    private.binomialRec.shape := shape;
    return defaultservers.run(private.agent, private.binomialRec);
  }

  private.discreteuniformRec := [_method='discreteuniform', 
				 _sequence=private.id._sequence];
  const public.discreteuniform := function(low=-1, high=1, shape=1) {
    wider private;
    private.discreteuniformRec.low := low;
    private.discreteuniformRec.high := high;
    private.discreteuniformRec.shape := shape;
    return defaultservers.run(private.agent, private.discreteuniformRec);
  }

  private.erlangRec := [_method='erlang', _sequence=private.id._sequence];
  const public.erlang := function(mean=1.0, variance=1.0, shape=1) {
    wider private;
    private.erlangRec.mean := mean;
    private.erlangRec.variance := variance;
    private.erlangRec.shape := shape;
    return defaultservers.run(private.agent, private.erlangRec);
  }

  private.geometricRec := [_method='geometric', 
			   _sequence=private.id._sequence];
  const public.geometric := function(probability=0.5, shape=1) {
    wider private;
    private.geometricRec.probability := probability;
    private.geometricRec.shape := shape;
    return defaultservers.run(private.agent, private.geometricRec);
  }

  private.hypergeometricRec := [_method='hypergeometric', 
				_sequence=private.id._sequence];
  const public.hypergeometric := function(mean=0.5, variance=1.0, shape=1) {
    wider private;
    private.hypergeometricRec.mean := mean;
    private.hypergeometricRec.variance := variance;
    private.hypergeometricRec.shape := shape;
    return defaultservers.run(private.agent, private.hypergeometricRec);
  }

  private.normalRec := [_method='normal', _sequence=private.id._sequence];
  const public.normal := function(mean=0.0, variance=1.0, shape=1) {
    wider private;
    private.normalRec.mean := mean;
    private.normalRec.variance := variance;
    private.normalRec.shape := shape;
    return defaultservers.run(private.agent, private.normalRec);
  }

  private.lognormalRec := [_method='lognormal',
			   _sequence=private.id._sequence];
  const public.lognormal := function(mean=1.0, variance=1.0, shape=1) {
    wider private;
    private.lognormalRec.mean := mean;
    private.lognormalRec.variance := variance;
    private.lognormalRec.shape := shape;
    return defaultservers.run(private.agent, private.lognormalRec);
  }

  private.negativeexponentialRec := [_method='negativeexponential',
				     _sequence=private.id._sequence];
  const public.negativeexponential := function(mean=1.0, shape=1) {
    wider private;
    private.negativeexponentialRec.mean := mean;
    private.negativeexponentialRec.shape := shape;
    return defaultservers.run(private.agent, private.negativeexponentialRec);
  }

  private.poissonRec := [_method='poisson', _sequence=private.id._sequence];
  const public.poisson := function(mean=1.0, shape=1) {
    wider private;
    private.poissonRec.mean := mean;
    private.poissonRec.shape := shape;
    return defaultservers.run(private.agent, private.poissonRec);
  }

  private.uniformRec := [_method='uniform', _sequence=private.id._sequence];
  const public.uniform := function(low=-1.0, high=1.0, shape=1) {
    wider private;
    private.uniformRec.low := low;
    private.uniformRec.high := high;
    private.uniformRec.shape := shape;
    return defaultservers.run(private.agent, private.uniformRec);
  }

  private.weibullRec := [_method='weibull', _sequence=private.id._sequence];
  const public.weibull := function(alpha=1, beta=1, shape=1) {
    wider private;
    private.weibullRec.alpha := alpha;
    private.weibullRec.beta := beta;
    private.weibullRec.shape := shape;
    return defaultservers.run(private.agent, private.weibullRec);
  }

  private.reseedRec := [_method='reseed', _sequence=private.id._sequence];
  const public.reseed := function(seed=unset) {
    wider private;
    if (is_unset(seed)) {
      private.reseedRec.seed := random();
    } else {
      private.reseedRec.seed := seed;
    }
    return defaultservers.run(private.agent, private.reseedRec);
  }

  const public.type := function() {return 'randomnumbers';}

  const public.id := function() {
    wider private;
    return private.id.objectid;
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
# enable plugins
  include 'plugins.g';
  plugins.attach('randomnumbers', public);
  
# reset the generator to a known state
  public.reseed(0);

  return ref public;
} #randomnumbers constructor

const randomnumbersdemo := function() {
  include 'drandomnumbers.g';
  include 'pgplotter.g';
  drandomnumbersplotter := pgplotter();
  drandomnumbersplotter.subp(4,3);
  demo := drandomnumbers(drandomnumbersplotter);
  demo.normal(1.5, 9);
  demo.poisson(2.2);
  demo.uniform(-1.65, 4.5);
  demo.discreteuniform(-2, 4);
  demo.binomial(10, .3);
  demo.geometric(.6);
  demo.hypergeometric(2, 5);
  demo.erlang(4, 8);
  demo.lognormal(5, 12);
  demo.negativeexponential(3);
  demo.weibull(1.5, 8);
  demo.example();
  demo.done();
  return T;
}

const randomnumberstest := function() {
  include 'trandomnumbers.g';
  return trandomnumbers();
}
