# imcatalogserver: Define and manipulate image catalogs
#
#   Copyright (C) 1995,1996,1997,1998,1999,2000,2001,2002
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
#   $Id: e2efuncs.g,v 19.0 2003/07/16 03:44:38 aips2adm Exp $
#
#----------------------------------------------------------------------------
#
pragma include once;
#
ingresTime :=function(ms_time)
{
#=============================================================================
#
# Create a date/time string that is acceptable as input to INGRES
#
# Input  : ms_time in fraction of days
#
# Output : INGRES compatible date/time string
#
#=============================================================================
#
include 'quanta.g';
#
   msq      := dq.quantity(ms_time, 'd');
   msday    := dq.time(msq, form="dmy no_time");
   mstime   := dq.time(msq, prec=6);
   msstr    := paste(msday, mstime, 'GMT');
   return msstr;
}
mjdObsTime := function(date_str, time_str)
{
#=============================================================================
#
# Returns date/time in decimal MJD (UTC). Input string formats are as
# recovered from VLA Observing Files, 2002.01.05 and 02:41:12 MST.
#
#=============================================================================
#
include 'quanta.g';
#
   fix_date := (date_str ~ s/\./\//g);
#
   fix_time := paste(time_str);
#
   fix_str := spaste(fix_date,'/',fix_time);
#
#   print "fix_str = ", fix_str;
#
   tu := dq.quantity(fix_str);
#
   mjdTime := tu.value + 7.0/24.0;
#   print tu.value, mjdTime;

   return mjdTime;
}
mjdTimeNow := function()
{
#=============================================================================
#
# Returns date/time in decimal MJD (UTC). Input string formats are as
# recovered from VLA Observing Files, 2002.01.05 and 02:41:12 MST.
#
#=============================================================================
#
include 'quanta.g';
#
   tu := dq.quantity('today');
   mjdTime := tu.value;
#
   return mjdTime;
}
mjd2day :=function(ms_time)
{
#=============================================================================
#
# Create a date string from MJD (double)
#
# Input  : ms_time in fraction of days
# Output : date string
#
#=============================================================================
#
include 'quanta.g';
#
   msq      := dq.quantity(ms_time, 'd');
   msday    := dq.time(msq, form="dmy no_time");
   msstr    := paste(msday);
   return msstr;
}
mjd2time :=function(ms_time)
{
#=============================================================================
#
# Create a time string from MJD (double)
#
# Input  : ms_time in fraction of days
# Output : time string
#
#=============================================================================
#
include 'quanta.g';
#
   msq      := dq.quantity(ms_time, 'd');
   mstime   := dq.time(msq, prec=6);
   msstr    := paste(mstime);
   return msstr;
}
ra2str := function(ra)
{
#=============================================================================
#
# Create an RA string from angle in radians (double)
#
# Input  : ra radians
# Output : ra string 
#
#=============================================================================
#
include 'quanta.g';
#
   msq      := dq.quantity(ra, 'rad');
   mstime   := dq.time(msq, prec=10);
   msstr    := paste(mstime);
   return msstr;
}
dec2str := function(dec)
{
#=============================================================================
#
# Create an DEC string from angle in radians (double)
#
# Input  : dec radians
# Output : dec string 
#
#=============================================================================
#
include 'quanta.g';
#
   msq      := dq.quantity(dec, 'rad');
   msangl   := dq.angle(msq, prec=9);
   msstr    := paste(msangl);
   return msstr;
}
pol2str := function(stokes_val)
{
#=============================================================================
#
# Returns stokes state string for emun int value
#
#=============================================================================
#
   pol[1] := paste('I');
   pol[2] := paste('Q');
   pol[3] := paste('U');
   pol[4] := paste('V');
   pol[5] := paste('RR');
   pol[6] := paste('RL');
   pol[7] := paste('LR');
   pol[8] := paste('LL');
#
   return pol[stokes_val];
}
freq_band := function(freq_val)
{
#=============================================================================
#
# Returns single character frequncy band id from frequency in MHz.
#
#=============================================================================
#
   if (freq_val >=   000.0 && freq_val <=    100.0) band_str := spaste('4');
   if (freq_val >=   100.1 && freq_val <=    700.0) band_str := spaste('P');
   if (freq_val >=   700.1 && freq_val <=   3000.0) band_str := spaste('L');
   if (freq_val >=  3000.1 && freq_val <=   7000.0) band_str := spaste('C');
   if (freq_val >=  7000.1 && freq_val <=  12000.0) band_str := spaste('X');
   if (freq_val >= 12000.1 && freq_val <=  18000.0) band_str := spaste('U');
   if (freq_val >= 18000.1 && freq_val <=  35000.0) band_str := spaste('K');
   if (freq_val >= 35000.1 && freq_val <= 100000.0) band_str := spaste('Q');
#
   return band_str;
}
bandrange := function(freq_band)
{
#=============================================================================
#
# Returns frequency range for character designated bands 
#
#=============================================================================
#
   band := split(freq_band);
   band_range := [0.0, 0.0];
   if (band == '4')      band_range := [0.0,        100.0];
   else if (band == 'P') band_range := [100.1,      700.0];
   else if (band == 'L') band_range := [700.1,     3000.0];
   else if (band == 'C') band_range := [3000.1,    7000.0];
   else if (band == 'X') band_range := [7000.1,   12000.0];
   else if (band == 'U') band_range := [12000.1,  18000.0];
   else if (band == 'K') band_range := [18000.1,  35000.0];
   else if (band == 'Q') band_range := [35000.1, 100000.0];

   return band_range;
}
clipstr := function(instr, nchar)
{
#=============================================================================
#
# Returns a string no longer than nchar characrers
#
#=============================================================================
#
#   print "clip instr : ", instr;
   nelements := length(split(instr," "));
#   print "clip nelements = ", nelements;
   if (nelements > 1) {
      inputstr := spaste(instr[1]);
   }
   else
   {
      inputstr := spaste(instr);
   }
   nlen := strlen(inputstr);
#   print "clip : ", nlen, inputstr;
   if (nlen <= nchar || nchar <= 0)
      return spaste(inputstr);
#
   strvec := split(inputstr,"");
#   print "clip : ", strvec;
   outstr := spaste("");
   for (i in 1:nchar) {
      outstr := spaste(outstr, strvec[i]);
   }
#   print "clip : ", outstr;
   return outstr;
}



