# trandomnumbers.g: demo & test for the randomnumbers tool
#
#   Copyright (C) 2000,2001
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
#   $Id: trandomnumbers.g,v 19.2 2004/08/25 01:46:25 cvsmgr Exp $
#
pragma include once

include 'randomnumbers.g';
include 'note.g';

const trandomnumbers := function() {
  note('Testing the random number tool', origin='randomnumberstest');
  local rnd := F;
  const ashape := [200,300,1];
  {
    local test := 'Test 1: Tool construction:\t\t';
    rnd := randomnumbers();
    if (is_fail(rnd) || is_boolean(rnd)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not create a random numbers tool');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='randomnumberstest');
  }
  {
    local test := 'Test 2: Discrete uniform distribution:\t';
    local s := rnd.discreteuniform(-9, 9);
    if (is_fail(s) || !is_numeric(s)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not get a value from the',
 		    'discrete numeric distribution');
      fail test;
    }
    if (s != -1) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not verify a scalar value from the',
 		    'discrete numeric distribution');
      fail test;
    }
    local a := rnd.discreteuniform(shape=ashape);
    if (any(shape(a) != ashape)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array shape from the',
 		    'discrete numeric distribution');
      fail test;
    }
    if (any(a < -1) | any( a > 1)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array values from the',
 		    'discrete numeric distribution');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='randomnumberstest');
  }
  {
    local test := 'Test 3: Normal distribution:\t\t';
    local s := rnd.normal(1, 2);
    if (is_fail(s) || !is_numeric(s)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not get a value from the',
 		    'normal distribution');
      fail test;
    } 
    if (abs(s - 0.130438) >  0.000002) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not verify a scalar value from the',
 		    'normal distribution');
      fail test;
    }
    local a := rnd.normal(shape=ashape);
    if (any(shape(a) != ashape)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array shape from the',
 		    'normal distribution');
      fail test;
    }
    if (sum(a)/length(a) > 0.01 | min(a) < -10 | max(a) > 10) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array values from the',
 		    'normal distribution');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='randomnumberstest');
  }
  {
    local test := 'Test 4: Binomial distribution:\t\t';
    local s := rnd.binomial(10, .1);
    if (is_fail(s) || !is_numeric(s)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not get a value from the',
 		    'binomial distribution');
      fail test;
    } 
    if (s != 0) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not verify a scalar value from the',
 		    'binomial distribution');
      fail test;
    }
    local a := rnd.binomial(shape=ashape);
    if (any(shape(a) != ashape)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array shape from the',
 		    'binomial distribution');
      fail test;
    }
    if (sum(a)/length(a) > .6 | min(a) < 0 | max(a) > 1) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array values from the',
 		    'binomial distribution');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='randomnumberstest');
  }
  {
    local test := 'Test 5: Erlang distribution:\t\t';
    local s := rnd.erlang(2, 3);
    if (is_fail(s) || !is_numeric(s)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not get a value from the',
 		    'Erlang distribution');
      fail test;
    } 
    if (abs(s - 3.96395) > 0.00002) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not verify a scalar value from the',
 		    'Erlang distribution');
      fail test;
    }
    local a := rnd.erlang(shape=ashape);
    if (any(shape(a) != ashape)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array shape from the',
 		    'Erlang distribution');
      fail test;
    }
    if (sum(a)/length(a) > 1.1 | min(a) < 0 | max(a) > 12) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array values from the',
 		    'Erlang distribution');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='randomnumberstest');
  }
  {
    local test := 'Test 6: Geometric distribution:\t\t';
    local s := rnd.geometric(0.95);
    if (is_fail(s) || !is_numeric(s)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not get a value from the',
 		    'geometric distribution');
      fail test;
    }
    if (s != 0) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not verify a scalar value from the',
 		    'geometric distribution');
      fail test;
    }
    local a := rnd.geometric(shape=ashape);
    if (any(shape(a) != ashape)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array shape from the',
 		    'geometric distribution');
      fail test;
    }
    if (sum(a)/length(a) > 1.1 | sum(a)/length(a) < 1.0 | 
	min(a) < 0 | max(a) > 17) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array values from the',
 		    'geometric distribution');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='randomnumberstest');
  }
  {
    local test := 'Test 7: Hypergeometric distribution:\t';
    local s := rnd.hypergeometric(1, 4);
    if (is_fail(s) || !is_numeric(s)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not get a value from the',
 		    'hypergeometric distribution');
      fail test;
    } 
    if (abs(s - 0.230057996) > 0.00002) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not verify a scalar value from the',
 		    'hypergeometric distribution');
      fail test;
    }
    local a := rnd.hypergeometric(shape=ashape);
    if (any(shape(a) != ashape)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array shape from the',
 		    'hypergeometric distribution');
      fail test;
    }
    if (sum(a)/length(a) > 0.6 | min(a) < 0 | max(a) > 23) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array values from the',
 		    'hypergeometric distribution');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='randomnumberstest');
  }
  {
    local test := 'Test 8: Lognormal distribution:\t\t';
    local s := rnd.lognormal(2, 4);
    if (is_fail(s) || !is_numeric(s)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not get a value from the',
 		    'lognormal distribution');
      fail test;
    } 
    if (abs(s - 3.53772221) > 0.00002) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not verify a scalar value from the',
 		    'lognormal distribution');
      fail test;
    }
    local a := rnd.lognormal(shape=ashape);
    if (any(shape(a) != ashape)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array shape from the',
 		    'lognormal distribution');
      fail test;
    }
    if (sum(a)/length(a) > 1.0 | min(a) < 0 | max(a) > 37) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array values from the',
 		    'lognormal distribution');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='randomnumberstest');
  }
  {
    local test := 'Test 9: Negative exponential distribution:';
    local s := rnd.negativeexponential(0.5);
    if (is_fail(s) || !is_numeric(s)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not get a value from the',
 		    'negative exponential distribution');
      fail test;
    }
    if (abs(s - 0.116486595) > 0.00002) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not verify a scalar value from the',
 		    'negative exponential distribution');
      fail test;
    }
    local a := rnd.negativeexponential(shape=ashape);
    if (any(shape(a) != ashape)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array shape from the',
 		    'negative exponential distribution');
      fail test;
    }
    if (sum(a)/length(a) > 1.1 | min(a) < 0 | max(a) > 11) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array values from the',
 		    'negative exponential distribution');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='randomnumberstest');
  }
  {
    local test := 'Test 10: Poisson distribution:\t\t';
    local s := rnd.poisson(13.5);
    if (is_fail(s) || !is_numeric(s)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not get a value from the',
 		    'Poisson distribution');
      fail test;
    }
    if (s != 11) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not verify a scalar value from the',
 		    'negative exponential distribution');
      fail test;
    }
    local a := rnd.negativeexponential(shape=ashape);
    if (any(shape(a) != ashape)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array shape from the',
 		    'negative exponential distribution');
      fail test;
    }
    if (sum(a)/length(a) > 1.2 | min(a) < 0 | max(a) > 13) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array values from the',
 		    'negative exponential distribution');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='randomnumberstest');
  }
  {
    local test := 'Test 11: Uniform distribution:\t\t';
    local s := rnd.uniform(0.5);
    if (is_fail(s) || !is_numeric(s)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not get a value from the',
 		    'negative exponential distribution');
      fail test;
    }
    if (abs(s - 0.955473727) > 0.00002) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not verify a scalar value from the',
 		    'negative exponential distribution');
      fail test;
    }
    local a := rnd.uniform(shape=ashape);
    if (any(shape(a) != ashape)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array shape from the',
 		    'negative exponential distribution');
      fail test;
    }
    if (sum(a)/length(a) > 0.1 | min(a) < -1 | max(a) > 1) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array values from the',
 		    'negative exponential distribution');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='randomnumberstest');
  }
  {
    local test := 'Test 12: Weibull distribution:\t\t';
    local s := rnd.weibull(0.5, 2.0);
    if (is_fail(s) || !is_numeric(s)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not get a value from the',
 		    'negative exponential distribution');
      fail test;
    }
    if (abs(s - 47.2707669) > 0.0002) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not verify a scalar value from the',
 		    'negative exponential distribution');
      fail test;
    }
    local a := rnd.weibull(shape=ashape);
    if (any(shape(a) != ashape)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array shape from the',
 		    'negative exponential distribution');
      fail test;
    }
    if (sum(a)/length(a) > 1.1 | min(a) < 0 | max(a) > 10) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nIncorrect array values from the',
 		    'negative exponential distribution');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='randomnumberstest');
  }
  {
    local test := 'Test 13: Reseeding:\t\t\t';
    local s := rnd.reseed(0);
    if (is_fail(s) || !is_boolean(s) || s == F) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not reseed the generator');
      fail test;
    }
    local sold := rnd.discreteuniform(0, 1E6, shape=10);
    local s := rnd.reseed(0);
    local snew := rnd.discreteuniform(0, 1E6, shape=10);
    if (all(sold != snew)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nReeseeding does not produce identical samples');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='randomnumberstest');
  }
  { 
    local test := 'Last 14: Tool destruction:\t\t';
    local retval := rnd.done();
    if (is_fail(retval) || !is_boolean(retval) || retval == F) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not shut the tool down');
      fail test;
    } 
    test := paste(test, '\tOK');
    note(test, origin='randomnumberstest');
  }
  return T;
}
