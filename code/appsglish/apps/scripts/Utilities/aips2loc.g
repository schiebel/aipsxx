# aips2loc: Count lines of code in aips++
# Copyright (C) 1996,1997,1998,1999
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
# $Id: aips2loc.g,v 19.2 2004/08/25 02:07:05 cvsmgr Exp $
#

pragma include once
  
aips2loc := function(file='/export/aips++/linecount/source_lines') {
  
  include 'quanta.g';

  toyears := function(yy, mm, dd) {
    return as_float(yy) +
	as_float(dq.quantity(spaste(dd,mm,yy)).value -
		 dq.quantity(spaste('1Jan', yy)).value)/365.0;
  }
  parts := split(dq.time('today', form='dmy'), '-');
  today := toyears(parts[3], parts[2], parts[1]);
      
  f:=open(paste('< ', file));
  
  line := read(f);
  loc := [=];
  loc.date := [];
  loc.size := [];
  nlines := 0;
  while(sum(strlen(line))) {
    nlines +:=1;
    parts := split(line);
    loc.date[nlines]:=toyears(parts[6], parts[2], parts[3]);
    loc.size[nlines]:=as_float(parts[7]);

    # Simple post-hoc editing
    if((nlines>1)&&(loc.size[nlines]<0.5*loc.size[nlines-1])) nlines-:=1;
    if(loc.date[nlines]>today) nlines-:=1;
    if((parts[2]==19)&&(parts[3]==Jun)&&(parts[6]==1999)) nlines-:=1;

    line := read(f);
  }
  if(nlines) {
    note ('Read ', nlines, ' lines from line count file ', file);
    
    y := sort_pair(loc.date, loc.size);
    x := sort(loc.date);

    include 'pgplotter.g';
    
    p:=pgplotter();
    p.plotxy(x, y, T, T, 'Date', 'Size (Lines of LOC)',
	     'Lines of Code in AIPS++');
    return T;
  }
  else {
    return throw('No lines read from line count file ', file);
  }

}
