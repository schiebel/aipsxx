# tvlafiller.g: demo & test for the vlafiller tool
#
#   Copyright (C) 2000,2002
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
#   $Id: tvlafiller.g,v 19.0 2003/07/16 03:39:53 aips2adm Exp $
#

pragma include once

include 'vlafiller.g';
include 'note.g';
include 'os.g';

const _vlafillerdemo := function() {
  note('Creating a measurement set called vla.ms using the demo data', 
       origin='vlafillerdemo');
  include 'sysinfo.g';
  vlafile := spaste(sysinfo().root(),
				  '/data/nrao/VLA/vlafiller_test/XH98109_1.vla');
  if(dos.fileexists(vlafile)){
     return vlafillerfromdisk('vla.ms', vlafile);
  } else {
    note('Missing VLA data file! VLA filler demo not run', priority='WARN', origin='vlafillerdemo');
    return F;
  }
}

const _vlafillertest := function() {
  note('A real test does not exist. Just running the demo', 
       origin='vlafillertest');
  return _vlafillerdemo();
}

#include 'logger.g';
#vlatapetoms('temp.ms', '/dev/tape', files=1, project='tests', overwrite=T);
#vlafiletoms('temp1.ms', 'file1.vla', project='tests', overwrite=T);
#v := vlafiller(host='pick');
#v.diskinput('file1.vla');
#v.output('temp.ms', T);
#v.selectproject('tests');
#v.fill(T, T);
#v.done();
# z := vlafillerdemo()
