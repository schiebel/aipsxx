# statistics.g: Various statistical functions
# Copyright (C) 1996,1997,1998,1999,2001
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
# $Id: statistics.g,v 19.2 2004/08/25 01:46:08 cvsmgr Exp $

pragma include once

const mean := function(...)
{
    return sum(...)/sum(len(...));
}

const moments := function(highest_moment, ..., assumed_mean = [=])
{
    retval := [=];
    if (highest_moment >= 0) {
        retval.n := sum(length(...));
    }
    if (highest_moment >= 1) {
	if (! is_numeric(assumed_mean)) {
	    retval.mean := mean(...);
	} else {
	    retval.mean := assumed_mean;
	    retval.note := 'The mean was supplied - it has not been calculated'
	}
    }
    varsum := skewsum := kurtsum := 0;
    if (highest_moment >= 2) {
	for (i in 1:num_args(...)) {
	    diffs := nth_arg(i, ...) -retval.mean;
	    tmp := diffs;
            tmp *:= diffs;
	    varsum +:= sum(tmp);
	    if (highest_moment >= 3) {
	        tmp *:= diffs;
		skewsum +:= sum(tmp);
		if (highest_moment >= 4) {
	            tmp *:= diffs;
		    kurtsum +:= sum(tmp);
		}
	    }
	}
	retval.variance := varsum/(retval.n - 1);
	retval.stddev := sqrt(retval.variance);
	if (highest_moment >= 3) 
	    retval.skew := skewsum/(retval.n * retval.stddev^3);
	if (highest_moment >= 4) 
	    retval.kurtosis := kurtsum/(retval.n * retval.variance^2) - 3;
    }

    return retval;
}

const variance := function(..., assumed_mean = [=])
{
    return moments(2, ..., assumed_mean=assumed_mean).variance;
}

const stddev := function(..., assumed_mean = [=])
{
    return moments(2, ..., assumed_mean=assumed_mean).stddev;
}

const skew := function(..., assumed_mean = [=])
{
    return moments(3, ..., assumed_mean=assumed_mean).skew;
}

const kurtosis := function(..., assumed_mean = [=])
{
    return moments(4, ..., assumed_mean=assumed_mean).kurtosis;
}

# Median will be slow when is_sorted is F and data is sorted or nearly sorted
# until the glish "sort" function becomes more efficient.
const median := function(data, is_sorted=F)
{
    if (! is_sorted) data := sort(data);

    is_odd := (length(data) % 2 == 1);
    n2p1 := as_integer(length(data) / 2) + 1;
    if (is_odd) {
	return data[n2p1];
    } else {
	return 0.5*(data[n2p1] + data[n2p1 - 1]);
    }
}

# Only look where the mask is "T"
const range_with_mask := function(data, mask)
{
  ok := eval('include \'note.g\''); if (is_fail(ok)) fail;
  note('The function range_with_mask(data, mask) will be removed before the\n',
       'first release of AIPS++. Please use range(data[mask]) instead.',
       priority='WARN', origin='statistics.g');
  return range(data[mask==T]);
}

const max_with_mask := function(data, mask)
{
  ok := eval('include \'note.g\''); if (is_fail(ok)) fail;
  note('The function max_with_mask(data, mask) will be removed before the\n',
       'first release of AIPS++. Please use max(data[mask]) instead.',
       priority='WARN', origin='statistics.g');
  return max(data[mask]);
}

const min_with_mask := function(data, mask)
{
  ok := eval('include \'note.g\''); if (is_fail(ok)) fail;
  note('The function min_with_mask(data, mask) will be removed before the\n',
       'first release of AIPS++. Please use min(data[mask]) instead.',
       priority='WARN', origin='statistics.g');
  return min(data[mask]);
}

const range_with_location := function(data, ref min_location, ref max_location,
	mask=[=])
{
    # Multipass unfortunately, but seems to be reasonably fast anyway
    if (is_numeric(mask)) {
        r := range(data[mask]);
    } else {
        r := range(data);
    }
    val min_location := ((1:len(data))[data==r[1]])[1];
    val max_location := ((1:len(data))[data==r[2]])[1];
    return r;
}

const max_with_location := function(data, ref max_location, mask=[=])
{
    # Multipass unfortunately, but seems to be reasonably fast anyway
    if (is_numeric(mask) ) {
        r := range(data[mask]);
    } else {
        r := range(data);
    }
    val max_location := ((1:len(data))[data==r[2]])[1];
    return r[2];
}

const min_with_location := function(data, ref min_location, mask=[=])
{
    # Multipass unfortunately, but seems to be reasonably fast anyway
    if (is_numeric(mask) ) {
        r := range(data[mask]);
    } else {
        r := range(data);
    }
    val min_location := ((1:len(data))[data==r[1]])[1];
    return r[1];
}
