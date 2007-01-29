# asciifileio.g: Support to read/write ascii images
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: asciifileio.g,v 19.2 2004/08/25 00:55:46 cvsmgr Exp $
#
pragma include once
include 'note.g'
include 'misc.g'
include 'serverexists.g'
include 'unset.g'
#
const asciifileio := subsequence() 
{
   if (!serverexists('dms', 'misc', dms)) {
      return throw('The misc server "dms" is not running', 
                    origin='asciifileio.g');
   }
#
   its := [=];
#

###
   const self.fromasciifile := function (infile, shape, sep=' ', firstline=1, lastline=unset)
   {
      file := open(paste('<', as_string(infile)));
      if (is_fail(file)) fail;
#
      iline := 1;
      if (firstline > 1) {
         for (i in 1:(firstline-1)) {
           line := read(file);
           iline +:= 1;
         }
      }
#
      n := prod(shape);
      nx := shape[1];
#
      a := as_float(array(0.0,n));
      idx := 1;
      nl := 1;
      while (nl>0) {
         line := dms.striptrailingblanks(read(file));
         line2 := split(line, sep);
         nl := length(line2);
         if (nl>0) {
            if (nl != nx) {
               return throw(spaste('Length of line ', iline, ' is ', nl, ' but should be ', nx),
                            origin='arrayfromasciifile.g');
            }
#
            a[idx:(idx+nx-1)] := as_float(line2);
            idx +:= nx;
            iline +:= 1;
#
            if (!is_unset(lastline)) {
               if (iline > lastline) break;
            }
         }
      }
#

      a::shape := shape;
      return a;   
   }


###
   const self.toasciifile := function (outfile, pixels, sep=' ', format='%e', overwrite=T)
   {

# Open file for overwrite or append

      local file;
      if (overwrite) {
         file := open(paste('>', as_string(outfile)));
      } else {
         file := open(paste('>>', as_string(outfile)));
      }
      if (is_fail(file)) fail;
#
      shp := shape(pixels);
      nx := shp[1];
      n := prod(shp);
      nlines := n / nx;
      pixels::shape := n;
#
      idx := 1;
      nline := 1;
      while (nline <= nlines) {
         line := paste(sprintf(format, pixels[idx:(idx+nx-1)]), sep);
         line2 := dms.striptrailingblanks(line);
         write (file, line2);
#
         idx +:= nx;
         nline +:= 1;
      }
#
      return T;
   }

###
   const self.done := function ()
   {
      wider its, self;
      val its := F;
      val self := F;
      return T;
   }
}
