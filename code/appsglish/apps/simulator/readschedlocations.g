# readschedlocations: Read the SCHED locations file into an AIPS++ table
#
#   Copyright (C) 2004
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
#   $Id: readschedlocations.g,v 1.2 2004/08/25 01:52:23 cvsmgr Exp $
#
# Read the locations file from the VLBI Sched program into an AIPS++ table
# This is only done occasionally since the processed table should be checked
# into the AIPS++ table system.
#
# There is no loss of information in this conversion.
#
# The format of the locations file is:

#!   Locations file for SCHED 
#!   Generated from the VLBA correlator data base on Mon Sept 15, 2003
#! 
#!   The stations file should contain DBNAME with the same name as below. 
#! 
#
#        DBCODE=AP  DBNAME=ALGOPARK  AXISTYPE='altz'  AXISOFF=  0.0073
#    X=   918034.7550 Y= -4346132.2730 Z=  4561971.1737 
#    DXDT= -0.01537 DYDT= -0.00498 DZDT=  0.00169 EPOCH=50449 
#    FRAME='USNO - Ref Frame 1998-6, Eubanks June 1998'
#/
#
include 'table.g';
readschedlocations:=function(tablename, locationfile) {

  f:=open(spaste('< ', locationfile));
  if(is_fail(f)) fail;

  cd1:=tablecreatescalarcoldesc("DBCODE", "AP");
  cd2:=tablecreatescalarcoldesc("DBNAME", "ALGOPARK");
  cd3:=tablecreatescalarcoldesc("AXISTYPE", "altz");
  cd4:=tablecreatescalarcoldesc("AXISOFF",   0.00730);
  cd5:=tablecreatescalarcoldesc("X",    918034.7550);
  cd6:=tablecreatescalarcoldesc("Y",  -4346132.2730);
  cd7:=tablecreatescalarcoldesc("Z",   4561971.1737 );
  cd8:=tablecreatescalarcoldesc("DXDT",  -0.01537);
  cd9:=tablecreatescalarcoldesc("DYDT",  -0.00498);
  cd10:=tablecreatescalarcoldesc("DZDT",   0.00169);
  cd11:=tablecreatescalarcoldesc("EPOCH", 50449);
  cd12:=tablecreatescalarcoldesc("FRAME", "USNO - Ref Frame 1998-6, Eubanks June 1998");
  td:=tablecreatedesc(cd1, cd2, cd3, cd4, cd5, cd6, cd7, cd8, cd9, cd10, cd11, cd12);
  t:=table(tablename, tabledesc=td, nrow=0);

  processline:=function(line) {
    rec:=[=];
    while(line~m/  /) line~:=s/  / /g;
    # Split into characters
    chars:=split(line, '');
    loceq:=1;
    locspace:=1;
    # This is such a drag to do in glish...
    while(loceq<len(chars)) {
      while(loceq<len(chars)&&chars[loceq]!='=') loceq+:=1;
      if(chars[loceq]=='=') {
	name:=spaste(chars[locspace:(loceq-1)]);
	value:='ERROR';
	while(name~m/^ /) name~:=s/^ //g;
	while(name~m/ $/) name~:=s/ $//g;
	locspace:=loceq;
	inquotes:=F;
	while((locspace<=len(chars))&&((chars[locspace]!=' ')||inquotes)) {
	  if(chars[locspace]=='\'') inquotes:=!inquotes;
	  locspace+:=1;
	}
	if(locspace<=len(chars)) {
	  value:=spaste(chars[(loceq+1):locspace]);
	  while(value~m/^ /) value~:=s/^ //g;
	  while(value~m/ $/) value~:=s/ $//g;
	}
	else {
	  value:=spaste(chars[(loceq+1):len(chars)]);
	  while(value~m/^ /) value~:=s/^ //g;
	  while(value~m/ $/) value~:=s/ $//g;
	}
	if(name=='DBCODE') {
          value~:=s/\'//g;
          value~:=s/\'//g;
	  rec[name]:=value;
	}
	else if(name=='DBNAME') {
          value~:=s/\'//g;
          value~:=s/\'//g;
	  rec[name]:=value;
	}
	else if(name=='AXISTYPE') {
          value~:=s/\'//g;
          value~:=s/\'//g;
	  rec[name]:=value;
	}
	else if(name=='AXISOFF') {
	  rec[name]:=as_double(value);
	}
	else if(name=='X') {
	  rec[name]:=as_double(value);
	}
	else if(name=='Y') {
	  rec[name]:=as_double(value);
	}
	else if(name=='Z') {
	  rec[name]:=as_double(value);
	}
	else if(name=='DXDT') {
	  rec[name]:=as_double(value);
	}
	else if(name=='DYDT') {
	  rec[name]:=as_double(value);
	}
	else if(name=='DZDT') {
	  rec[name]:=as_double(value);
	}
	else if(name=='EPOCH') {
	  rec[name]:=as_double(value);
	}
	else if(name=='FRAME') {
          value~:=s/\'//g;
          value~:=s/\'//g;
	  rec[name]:=value;
	}
	else {
	  print "Unknown name", name
	}
	loceq:=locspace+1;
      }
      else {
	return rec;
      }
    }
    return rec;
  }

  readoneline:=function(f) {
    entireline:='';
    line:=read(f);
    while(line~m/^!/) {
      line:=read(f);
    }
    while(!(line~m!^/!)) {
      line~:=s/\n//g;
      entireline:=spaste(entireline, line);
      line:=read(f);
      while((len(line)>0)&&(line~m/^!/)) {
	line:=read(f);
      }
      if(len(line)==0) break;
    }
    while(entireline~m/= /) entireline~:=s/= /=/g;
    return entireline;
  }

  lineno:=0;
  # Put info in second lines into the readme
  line:=read(f);
  line:=read(f);
  line~:=s/!//g;
  t.addreadmeline(line);
  oneline:=readoneline(f);
  while(oneline!='') {
    lineno+:=1;
    rec:=processline(oneline);
    t.addrows(1);
    for (field in field_names(rec)) {
      t.putcell(field, lineno, rec[field]);
    }
    oneline:=readoneline(f);
  }
  t.summary();
  t.done();
  f:=F;
}

tabledelete('sched_locations.table');
readschedlocations('sched_locations.table', 'sched_locations.dat');
