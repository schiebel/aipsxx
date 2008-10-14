# ms2matlab.g: convert an MS to a file readable for matlab
#
#   Copyright (C) 1999
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
#   $Id: ms2matlab.g,v 19.0 2003/07/16 03:39:26 aips2adm Exp $
#
#----------------------------------------------------------------------------

# This scripts converts an MS to an ASCII file readable for matlab.
# It was created for Amir Leshem at Delft University.
#
# It is possible to select a single polarization (default is 1)
# and one or more channels (default is all channels).
# If selection on antenna or baseline is needed, it should be done
# previously using the table.query command.
#
# The first line in the output contains the selected polarisation
# and channels.
# The second line contains the dimensionality of the output as
# [nantennas nantennas nchannels ntimes].
# The following lines consist of nantennas complex numbers (as 0+0i)
# separated by a blank. The line is enclosed in square brackets.
# The number of such lines is nantennas*nchannels*ntimes.
# Note that for a baseline antenna-i,antenna-j the complex conjugate
# is also filled in as antenna-j,antenna-i.


pragma include once

include "table.g"
include "os.g"
include "progress.g"

const ms2matlab := function (ms, outname='matlab.out', polnr=1,
			     channels=[], column="DATA", select=F)
{
  print 'Convert MS',ms,'to matlab file',outname;
  t := table (ms);
  if (is_fail(t)) fail;
  # Apply selection string when given.
  if (is_string(select)) {
    print spaste("select string '", select, "' will be applied");
    t1 := t.query (select);
    t.close();
    if (is_fail(t1)) fail;
    t := t1;
  }
  # Find and check the highest antenna number.
  # If too high, skip those.
  maxant := max(max(t.getcol("ANTENNA1")), max(t.getcol("ANTENNA2")));
  if (maxant > 13) {
    print "Found antenna numbers > 13; they will be skipped";
    if (! is_string(select)) {
      select := 'ANTENNA1<=13 && ANTENNA2<=13';
    } else {
      select := spaste('(', select, ') && (ANTENNA1<=13 && ANTENNA2<=13)');
    }
    t1 := t.query (select);
    t.close();
    if (is_fail(t1)) fail;
    t := t1;
  }
  # Sort uniquely on TIME to get number of times.
  # This is faster than using unique(t1.getcol('TIME')).
  t1 := t.query (sortlist='noduplicates TIME');
  nrtim := t1.nrows();
  # Get number of polarisations and channels by looking at shape of first row.
  # Check if the given selections are correct.
  shp := shape(t.getcell(column, 1));
  nchan := shp[2];
  print "Found", shp[1], "polarizations,", nchan, "channels,", nrtim, "times";
      
  # An empty vector means all channels.
  if (len(channels) == 0) {
    print '  selected polnr',polnr,'and all channels';
    channels := 1:nchan;
  } else {
    print '  selected polnr',polnr,'and channels',channels;
    if (any(channels > nchan)) {
      t.close();
      fail 'A specified channel is higher than the number of channels';
    }
  }
  if (len(polnr) > 1) {
    t.close();
    fail 'Only one polarization can be selected';
  }
  if (polnr > shp[1]) {
    t.close();
    fail 'Polnr is higher than number of polarizations'
  }
  # Determine the minimum and maximum channel to read as little as possible.
  minchan := min(channels);
  maxchan := max(channels);
  nchan := len(channels);
  # Iterate through the table in order of time.
  # Setup a progress bar.
  print 'Writing the output file ...';
  iter := tableiterator (t, "TIME");
  nriter := 0;
  prgss := progress(0, nrtim, 'ms -> matlab');
  # Create the file in a separate scope, so it is closed at the end of it.
  # Create a temporary file first; later it is processed to the file proper.
  {
    file := open(spaste('> ',outname,'-tmp'));
    write (file, spaste('ms = ', dos.fullname(ms)));
    write (file, spaste('select = ', select));
    write (file, spaste('polnr = ', polnr));
    write (file, spaste('channels = ', channels));
    write (file, [14, 14, nchan, nrtim]);
    # Make channels relative to minimum (since we start reading there).
    channels -:= minchan-1;
  
    while (iter.next()) {
      # Read the polarisation and channels as needed.
      data := iter.table().getcolslice (column, [polnr,minchan],
					[polnr,maxchan]);
      ant1 := iter.table().getcol ("ANTENNA1") + 1;
      ant2 := iter.table().getcol ("ANTENNA2") + 1;
      nrow := length(ant1);
      out := array(as_complex(0+0i), 14, 14);
      out::print.precision := 7;
      inxa1:=array([ant1,ant2],nrow,2);
      inxa2:=array([ant2,ant1],nrow,2);
      for (i in channels) {
        out[inxa1] := data[1,i,];
        out[inxa2] := conj(data[1,i,]);
        for (j in 1:14) {
	  write (file, out[,j]);
        }
      }
      nriter +:= 1;
      prgss.update (nriter);
    }
  }
  t.close();

  if (nriter != nrtim) {
    fail "error in ms2matlab: nriter != nrtim";
  }
  # Glish sometimes outputs 0 as +-0, so replace all +- by -.
  print 'Finalizing the output file ...'
  shell (spaste('sed s/+-/-/g ',outname,'-tmp',' > ',outname,
		'; rm ',outname,'-tmp'));
  return T;
}
