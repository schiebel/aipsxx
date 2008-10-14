# datafilter.g: Simple filtering of data arrays
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
#   $Id: datafilter.g,v 1.4 2004/08/25 01:43:14 cvsmgr Exp $
#

pragma include once
include 'note.g'

datafilter := subsequence ()
{

# Private data

   its:=[=]


### Private functions

   const its.done  := function () 
   {
      wider its;
#
      val its := F;
      val self := F;
#
      return T;
   }

### Public functions

   const self.done := function ()
   {
      wider its;
#
      return its.done();
   }

###
  const self.filter := function (data, width=5, method='mean', progress=unset)
  {
     include 'statistics.g';
#
     width := as_integer(width);
     if(width==1) return data;
     if (width < 1) { 
        return throw ('width parameter must be a positive integer',
                       origin='datafilter.filter');
     }
#
     n := length(data);
     if (n < width) return data;
     if (!(is_numeric(data) && !is_boolean(data)) ) {
        return throw ('data variable must be of numeric type',
                       origin='datafilter.filter');
     }
#
     mthd := to_upper(as_string(method));
     if (mthd!='MEAN' && mthd!='MEDIAN') {
        return throw ('Illegal method', origin='datafilter.filter');
     }
#
     newData := array(0.0, n);
     for (i in 1:n) {
       imin := max(1, (i-width));
       imax := min(n, (i+width));
#
       if(mthd=='MEDIAN') {
         newData[i] := median(data[imin:imax]);
       } else if (mthd=='MEAN') {
         newData[i] := mean(data[imin:imax]);
       }
#
       if (!is_unset(as_integer(progress))) {
          if(i%progress==1) {
            s := spaste (i, ' of ', n, ':', data[i], '->', newData[i]);
            note (s, origin='datafilter.filter', priority='NORMAL');
          }
       }
     }
     return newData;
  }

###
   const self.medianclip := function (data, width=5, clip=5, progress=unset)
   {
      clip := as_float(clip);
      if (clip < 0.0) {
         return throw ('Clip variable must be positive',
                       origin='datafilter.medianclip');
      }

# Compute median filtered data

      y2 := self.filter (data, width, 'median', progress);
      if (is_fail(y2)) fail;

# Compute abs diff from median

      y3 := abs (data - y2);

# Compute median filter of abs diff

      y4 := self.filter (y3, width, 'median', progress);
      if (is_fail(y4)) fail;

# Return mask; use <= because of problems when the median value is the same
# as the input data and the abs diff is zero

      m := (y3 <= clip*y4);                        # T is good, F is bad
      return m;
   }
}
