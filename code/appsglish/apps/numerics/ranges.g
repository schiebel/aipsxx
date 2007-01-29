# ranges.g: handles (collapses and expands) vector ranges for SDCalc.
#------------------------------------------------------------------------------
#
#   Copyright (C) 1996,1997,2002
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
#          Internet email: aips2request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: ranges.g,v 19.2 2004/08/25 01:45:48 cvsmgr Exp $
#
#------------------------------------------------------------------------------
#
# Closure for handling (collapsing and expanding) vectors to/from Bob's
# SDIterator range-specification format.
#
# Example:
#
# Input range:		[3 2 1 2 5 6 10 8 5]
# Collapsed range:	"[1,3] [5,6] 8 10"
# Re-epanded range:	[1 2 3 5 6 8 10]
#
# As you can see, there is information loss due to the "squashing" of
# duplicate entries.  If this worries you then don't use this closure!
#
# TODO: There isn't much error-checking here yet, and some of the
# functions are quite unforgiving on their inputs.
#
# Overall ATM I'd call this whole thing a definite kludge....

pragma include once

  const ranges := function ()
  {
    self := [=];
    public := [=];

    self.collapse := function (vectorRange) {
	returnString := '';
	inBrackets := F;

	for (i in 1:(len(vectorRange)-1)) {
	    if (vectorRange[i] == (vectorRange[i+1] - 1)) {
		if (inBrackets) {
		    next;
		} else {
		    returnString := spaste (returnString, ' [', vectorRange[i], ',');
		    inBrackets := T;
		}
	    } else {
		if (inBrackets) {
		    returnString := spaste (returnString, vectorRange[i], '] ');
		    inBrackets := F;
		} else {
		    returnString := spaste (returnString, ' ', vectorRange[i]);
		}
	    }
	}
	# handle the last point
	if (inBrackets) {
	    # the test of v[len-1] == v[len] has already happened and must have been true
	    returnString := spaste(returnString, vectorRange[len(vectorRange)], ']');
	} else {
	    # all by itself
	    returnString := spaste(returnString, ' ', vectorRange[len(vectorRange)]);
	}
	return paste (split (returnString)); # Prettify.
    }

    public.collapse := function (Range) {
      if (is_string (Range)) {
	splitString := split (Range, ' [],');
	# Cleaner way?
	# make sure that there is at least a zero-length range
	vectorRange := as_integer([]);
	for (i in ind(splitString)) {
	  vectorRange[i] := as_integer (splitString[i]);
	}
      } else {
	vectorRange := Range;
      }
      return self.collapse (unique (vectorRange));
    }

    public.expand := function (stringRange) {
      returnVec := [];
      workingString := split (stringRange);

      for (i in 1:len (workingString)) {
	stringSegment := split (split (workingString[i], '[],'));

	if (len (stringSegment) == 1) {
	  returnVec := [returnVec, as_integer (stringSegment[1])];
	} else {		# Should always be 2.
	  returnVec := [returnVec, seq (as_integer (stringSegment[1]),
					as_integer (stringSegment[2]))];
	}
      }
      return returnVec;
    }

#    public.debug := ref self;
    return ref public;
  }
