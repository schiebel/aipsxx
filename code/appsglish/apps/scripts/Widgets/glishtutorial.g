# glishtutorial.g: a glish convenience script for the Glish tutorial
# Copyright (C) 1996,1997,1998,1999,2000
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
# $Id: glishtutorial.g,v 19.2 2004/08/25 02:14:20 cvsmgr Exp $

pragma include once

include "table.g"
include "pgplotter.g"
include "utility.g"
include "note.g"

maket1 := function(dir_name=F) {

  if(!is_string(dir_name)) {
    aipsroot:=sysinfo().root();
    dir_name:=spaste(aipsroot, '/code/trial/data/glishtutorial');
  }
  if(is_defined('t1') && has_field(t1,"delete")) t1.delete();
  if(tableexists('t1')) tabledelete('t1');

  note('Begin constructing table t1 from GBT data files');
  global t1:=table(spaste(dir_name,'/t1'));
  if(is_fail(t1)) fail;
  return T;

}

maket7 := function(dir_name=F) {

  if(!is_string(dir_name)) {
    aipsroot:=sysinfo().root();
    dir_name:=spaste(aipsroot, '/code/trial/data/glishtutorial');
  }
  if(is_defined('t7') && has_field(t7,"delete")) t7.delete();
  if(tableexists('t7')) tabledelete('t7');

  note('Begin constructing table t7 from GBT data files');
  global t7:=table(spaste(dir_name,'/t7'));
  if(is_fail(t7)) fail;
  return T;

}

plotscan := function (tab, scan_no, receiver=1)
{
  data := tab.getcol("DATA");
  scan := tab.getcol("SCAN");
  rcvr := tab.getcol("RECEIVER_ID");
  mask := (scan == scan_no & rcvr == (receiver - 1));
  scan_data := data [mask];
  if (len (scan_data) == 0) {
    fail paste("No data found for scan", scan_no, "Receiver", receiver);
  }
  return tp.ploty (data [mask], paste ("Scan", scan_no, "Receiver", receiver));

}

if(maket1()) note('table object t1 ready for use');
if(maket7()) note('table object t7 ready for use');
