# componentlist_ascii.g: convert ascii files into a componentlist
# Copyright (C) 2001
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
# $Id: componentlist_ascii.gp,v 19.2 2005/05/24 08:13:23 cvsmgr Exp $

pragma include once
  
include "componentlist.g";

componentlist_ascii := [=];
const componentlist_ascii.attach := function(ref public) {
  private := [=];
#
# NVSS (NRAO VLA Sky Survey) http://www.cv.nrao.edu/nvss/ 
#
#   RA(2000)  Dec(2000) Dist(") Flux  Major Minor  PA  Res P_Flux P_ang  Field    X_pix  Y_pix
# h  m    s    d  m   s   Ori     mJy   "     "     deg       mJy  deg
#23 51 21.80 +00 13 37.4  7814    3.8 <71.7 <41.1           -0.28       C2344P00   70.28  567.49
#       0.27         6.7   -84    0.6                        0.70
#23 51 26.14 +00 06  9.4  7715    6.3 <55.6 <36.3           -0.16       C2344P00   65.93  537.62
  public.fromnvss := function(filename, refer='J2000', log=T) {
    file := open(paste("<", filename));
    if (is_fail(file)) fail;
    const initialLen := public.length(); if (!is_numeric(initialLen)) fail;
    foundFirstLine := F;
    numericRegex := m/^[0-9]+$/;
    while (line := split(read(file), '')) {
      while (len(line) > 1 & 
	     !foundFirstLine & 
	     !all(line[1:2] ~ numericRegex)) {
	line := split(read(file), '');
      }
      if (len(line) >= 70) {
	foundFirstLine := T;
	ok := public.simulate(1, log=F); if (is_fail(ok)) fail;
	c := public.length(); if (!is_numeric(c)) fail;
	ok := public.setlabel(c, paste(line, sep=''), log=F);
	if (is_fail(ok)) fail;
	if (line[7] == ' ') line[7] := '0';
	ra := paste(line[1], line[2], ':', 
		    line[4], line[5], ':', 
		    line[7], line[8], line[9], line[10], line[11], sep='');
	if (line[20] == ' ') line[20] := '0';
	dec := paste(line[13], line[14], line[15], '.', 
		     line[17], line[18], '.', 
		     line[20], line[21], line[22], line[23], sep='');
	ok := public.setrefdir(c, ra, 'time', dec, 'angle', log=F);
	if (is_fail(ok)) fail;
	ok := public.setrefdirframe(c, refer, log=F);
	if (is_fail(ok)) fail;
	majVal := as_double(paste(line[37:42], sep='') ~ s/<//);
	minVal := as_double(paste(line[43:48], sep='') ~ s/<//);
	paVal := as_double(paste(line[49:54], sep=''));
	if (majVal < minVal) {
	  tempVal := majVal;
	  majVal := minVal;
	  minVal := tempVal;
	  paVal +:= 90;
	}
	ok := public.setshape(c, 'Gaussian', paste(majVal, 'arcsec', sep=''), 
			      paste(minVal, 'arcsec', sep=''), 
			      paste(paVal, 'deg', sep=''), log=F); 
	if (is_fail(ok)) fail;
	Iflux := as_double(paste(line[30:36], sep=''));
	Pflux := as_double(paste(line[58:64], sep=''));
	PAngle := as_double(paste(line[65:70], sep='')) * pi / 180.0;
	local factor := tan(2 * PAngle);
	Uflux := 0.0;
	Qflux := Pflux;
	if (factor != 0.0) {
	  Uflux := Pflux/sqrt(1 + (1/factor)^2);
	  Qflux := Uflux / factor;
	}
	ok := public.setflux(c, [Iflux, Qflux, Uflux, 0.0], 'mJy', log=F);
	if (is_fail(ok)) fail;
	ok := public.setfreq(c, 1.4, 'GHz', log=F); if (is_fail(ok)) fail;
	if (log) {
	  ok := public.print(c); if (is_fail(ok)) fail;
	}
# Skip the error parameters line
	line := split(read(file), '');
      } else {
	if (foundFirstLine) {
	  note('Skipped the line printed below as it is too short\n', 
	       paste(line, sep=''), origin='componentlist.fromnvss');
	}
      }
    }
    line := F;
    file := F;
    const finalLen := public.length(); if (!is_numeric(finalLen)) fail;
    note('Added ', finalLen - initialLen, ' components to the list ',
	 'from the ascii file ', filename,
	 origin='componentlist.fromnvss');
    note('Error estimates are not used.', 
	 priority='WARN', origin='componentlist.fromnvss');
    return T;
  }

#
# WENSS (Westerbork Northern Sky Survey) http://www.strw.leidenuniv.nl/~dpf/wenss/
#
# Dist. Name            Right Asc.   Decl.      T F Peak Int. Minor Major PA  Noise Frame
# __________________________________________________________________________________________
# 
# 000000000111111111122222222223333333333444444444455555555556666666666777777777788888888889
# 123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
# 324   WNB2357.0+2945  23 59 37.64  30 02 23.8 S   150  190  107   68    0    4.1  WN30000H
# 350   WNB2357.2+2938  23 59 47.12  29 54 51.8 S   38   46   0     0     0    4.2  WN30000H
# 1036  WNB2358.3+2931   0 00 57.26  29 47 55.4 S   339  338  0     0     0    4.3  WN30000H
# 203   WNB2039.5+4149  20 41 18.17  41 59 55.8 E * 312  537741050  715   91   16.6 WN40312H
# 4     WNB0433.9+2934   4 37 04.34  29 40 20.8 E * 1488815106114   52    168  14.4 WN30069H
  public.fromwenss := function(filename, refer='J2000', log=T) {
    file := open(paste("<", filename));
    if (is_fail(file)) fail;
    const initialLen := public.length(); if (!is_numeric(initialLen)) fail;
    foundFirstLine := F;
    skippedMultiple := F;
    while (line := split(read(file), '')) {
      while (len(line) > 9 & 
	     !foundFirstLine & 
	     !(line[7] == 'W' & line[8] == 'N' & line[9] == 'B')) {
	line := split(read(file), '');
      }
      if (len(line) >= 90 & line[47] != 'M') {
	foundFirstLine := T;
	b1 := paste(line[7:20], sep='');
	b2 := paste(array(' ', 25), sep='');
	b3 := paste(line[21:45], sep='');
	b5 := paste(line[46:50], sep='');
	b7 := paste(line[51:55], sep='');
	b9 := paste(line[56:60], sep='');
	b11 := paste(line[61:64], sep='');
	b12 := paste(line[66:70], sep='');
	b13 := paste(line[73:76], sep='');
	b14 := paste(line[78:90], sep='');
	ml := paste(b1, b2, b3, ' ', b5, ' ', b7, '   ', 
		    b9, '  ', b11, b12, b13, b14, sep='');
	ok := private.readwenssline(split(ml, ''), refer, log);
	
      } else {
	if (len(line) < 90) {
	  if (foundFirstLine) {
	    note('Skipped the line printed below as it is too short\n', 
		 paste(line, sep=''), origin='componentlist.fromnvss');
	  }
	} else {
	  skippedMultiple := T;
	}
      }
    }
    line := F;
    file := F;
    const finalLen := public.length(); if (!is_numeric(finalLen)) fail;
    note('Added ', finalLen - initialLen, ' components to the list ',
	 'from the ascii file ', filename,
	 origin='componentlist.fromnvss');
    if (skippedMultiple) {
      note('Using individual (C) components ',
	   'in preference to the merged (M) components',
	   priority='WARN', origin='componentlist.fromnvss');
    }
    return T;
  }

#
# WENSS (Westerbork Northern Sky Survey) http://www.strw.leidenuniv.nl/~dpf/wenss/
#
# Name            Position (B1950)        Position (J2000)         Fl   S       SI      b-M  b-m PA  nse  frame
# ---------------+-----------------------+------------------------+----+-------+-------+----+---+---+----+---------
# WNB0000.0+7435   0  0  0.70  74 35 56.2   0  2 35.87  74 52 38.1  S       105     109    0   0   0  3.7 WNH75_000
# WNB0000.0+6325   0  0  0.83  63 25 24.0   0  2 35.36  63 42  5.9  S       115     131   69  53  32  4.6 WNH65_000
# WNB0000.0+6737   0  0  1.27  67 37 43.3   0  2 35.97  67 54 25.3  S        54      29    0   0   0  3.7 WNH65_000
# WNB0000.0+3821   0  0  1.28  38 21 35.8   0  2 35.34  38 38 17.9  S        49      43    0   0   0  3.2 WNH40_000
  public.fromwensscat := function(filename, log=T) {
    file := open(paste("<", filename));
    if (is_fail(file)) fail;
    const initialLen := public.length(); if (!is_numeric(initialLen)) fail;
    foundFirstLine := F;
    skippedMultiple := F;
    while (line := split(read(file), '')) {
      while (len(line) > 3 & 
	     !foundFirstLine & 
	     !(line[1] == 'W' & line[2] == 'N' & line[3] == 'B')) {
	line := split(read(file), '');
      }
      if (len(line) >= 90 & line[47] != 'M') {
	foundFirstLine := T;
	private.readwenssline(line, 'J2000', log);
      } else {
	if (len(line) < 90) {
	  if (foundFirstLine) {
	    note('Skipped the line printed below as it is too short\n', 
		 paste(line, sep=''), origin='componentlist.fromnvss');
	  }
	} else {
	  skippedMultiple := T;
	}
      }
    }
    line := F;
    file := F;
    const finalLen := public.length(); if (!is_numeric(finalLen)) fail;
    note('Added ', finalLen - initialLen, ' components to the list ',
	 'from the ascii file ', filename,
	 origin='componentlist.fromnvss');
    if (skippedMultiple) {
      note('Using individual (C) components ',
	   'in preference to the merged (M) components',
	   priority='WARN', origin='componentlist.fromnvss');
    }
    return T;
  }

  private.readwenssline := function(line, refer, log) { 
    ok := public.simulate(1, log=F); if (is_fail(ok)) fail;
    c := public.length(); if (!is_numeric(c)) fail;
    ok := public.setlabel(c, paste(line, sep=''), log=F);
    if (is_fail(ok)) fail;
    if (line[42] == ' ') line[42] := '0';
    if (line[45] == ' ') line[45] := '0';
    if (line[48] == ' ') line[48] := '0';
    ra := paste(line[42], line[43], ':', 
		line[45], line[46], ':', 
		line[48], line[49], line[50], line[51], line[52], sep='');
    if (line[55] == ' ') line[55] := '0';
    if (line[58] == ' ') line[58] := '0';
    if (line[61] == ' ') line[61] := '0';
    dec := paste(line[55], line[56], '.', 
		 line[58], line[59], '.', 
		 line[61], line[62], line[63], line[64], sep='');
    ok := public.setrefdir(c, ra, 'time', dec, 'angle', log=F);
    if (is_fail(ok)) fail;
    ok := public.setrefdirframe(c, refer, log=F);
    if (is_fail(ok)) fail;
    majVal := as_double(paste(line[87:90], sep=''));
    minVal := as_double(paste(line[92:94], sep=''));
    paVal := as_double(paste(line[96:98], sep=''));
    if (majVal == 0 & minVal == 0 & paVal == 0) {
      ok := public.setshape(c, 'Point', log=F);
    } else {
      ok := public.setshape(c, 'Gaussian', paste(majVal, 'arcsec', sep=''), 
			    paste(minVal, 'arcsec', sep=''), 
			    paste(paVal, 'deg', sep=''), log=F); 
    }
    if (is_fail(ok)) fail;
    Iflux := as_double(paste(line[79:85], sep=''));
    ok := public.setflux(c, [Iflux, 0.0, 0.0, 0.0], 'mJy', log=F);
    if (is_fail(ok)) fail;
    ok := public.setfreq(c, 327, 'MHz', log=F); if (is_fail(ok)) fail;
    if (log) {
      ok := public.print(c); if (is_fail(ok)) fail;
    }
  }

  return T;
}
