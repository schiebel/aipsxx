# image_convert.gp: StorageManager conversion for AIPS++ image class
#
#   Copyright (C) 1996,1997,1999,2000,2001
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
#   $Id: image_convert.gp,v 19.2 2005/05/24 08:11:29 cvsmgr Exp $
#

pragma include once

include 'types.g';
include 'note.g';
include 'os.g';
include 'table.g';
include 'unset.g';

image_convert := [=];
image_convert.init := function()
{
    types.class('image').group('Utility').method('image.convertsm').
       string('outfile', allowunset=T, default=unset).
       boolean('overwrite', T);

    return T;
}


image_convert.attach := function(ref public)
{

###
    const public.convertsm := function (outfile=unset, overwrite=T)
#
# Convert logtable storage manager from 'StandardStMan' to 'StManAipsIO'
# Anything after release1.3 uses StandardStMan which cannot be read
# by release1.3 and earlier.  This function converts an image made
# after release1.3 to something readable by all releases.
# 
    {
       if (!public.is_persistent()) {
          note('This is not a disk-based image, so there is nothing to do',
               origin='image.convertsm', priority='WARN');
          return T;
       }
#
# If outfile is unset, logtable is updated in-situ
#
       infile := public.name(strippath=F);
       if (is_unset(outfile)) {
#
# logtable is first copied
#
          logout := spaste(infile, '/logtable2');
       } else {
#
# Copy image
#
          ok := dos.copy(infile, as_string(outfile), 
                         overwrite=overwrite);
          if (is_fail(ok)) {
             if (overwrite) dos.remove(outfile);
             fail;
          }
# 
# Remove target logtable
#
          logout := spaste(outfile, '/logtable');
          ok := dos.remove(logout);
          if (is_fail(ok)) {
             dos.remove(outfile);
             fail;
          }
       }
#
# Find storage manager names and set new output SM name
#
       login := spaste(public.name(strippath=F), '/logtable');   
       tin := table(login, readonly=T, ack=F);
       if (is_fail(tin)) fail;
       tdesc := tin.getdesc();
       for (i in 1:len(tdesc)) {
          if (tdesc[i].dataManagerType == 'StandardStMan') {
              tdesc[i].dataManagerType := 'StManAipsIO';
           }
           if (tdesc[i].dataManagerGroup == 'StandardStMan') {
               tdesc[i].dataManagerGroup := 'StManAipsIO';
           }
       }
       nrows := tin.nrows();
#
# Copy logtable
#
       tout := table(logout, tdesc, nrows, ack=F);
       if (is_fail(tout)) fail;
       if (nrows > 0) {
           trowin := tablerow (tin);
           trowout := tablerow (tout);
           for (i in 1:nrows) {
              trowout.put (i, trowin.get (i));
           }
       }
       tin.done();
       tout.done();
#
# If converting in-situ, remove original logtable
# and copy new 
#
       if (is_unset(outfile)) {
          ok := dos.remove(login);
          if (is_fail(ok)) {
             ok := dos.remove(logout);
             fail;
          }
          public.unlock();
          ok := dos.move(logout, login, T)
          if (is_fail(ok)) fail;
       }
       return T;
    }

###
    return T;
}

const image_convert := const image_convert;
