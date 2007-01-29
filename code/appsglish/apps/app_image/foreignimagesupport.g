# foreignimagesupport.g: Convert foreign images to aips++ via FITS
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
#   $Id: 
#

pragma include once
#
include 'image.g'
include 'os.g'
include 'unset.g'
#
const imagefromforeign := function (outfile=unset, infile, format='miriad', overwrite=F)
{
   if (!is_string(infile)) {
      return throw ('Infile must be a string', origin='imagefromforeign');
   }
   if (!serverexists('dos', 'os', dos)) {
      return throw('The os server "dos" is not running',
                    origin='imagefromforeign');
   }
#
   fitsfile := '___temporaryfile.fits';
   pckg := to_upper(format);
   local exe, command;
   if (pckg=='MIRIAD') {
      exe := '$MIRBIN/fits';
      command := spaste('$MIRBIN/fits op=xyout in=', infile, ' out=', fitsfile);
   } else if (pckg=='GIPSY') {
      exe := '$gip_exe/nhermes';
      command := spaste('$gip_exe/nhermes "wfits inset=', infile, ' fitsfile=',fitsfile, '"');
   } else {
      msg := spaste('Files of type ', format, ' are currently not supported');
      return throw(msg, origin='imagefromimage');
   }
#
# Convert to fits
#
   if (!dos.fileexists(exe)) {
      msg := spaste('The ', format, ' fits executable cannot be located at ', exe);
      return throw(msg, origin='imagefromforeign.g');
   }
#
   if (dos.fileexists(fitsfile)) {
      ok := dos.remove(fitsfile, T);
      if (is_fail(ok)) fail;
   }
#
   msg := spaste('Converting ', format, ' file to temporary FITS file');
   note (msg, priority='NORMAL', origin='imagefromforeign');
   ok := shell(command);
   if (!dos.fileexists(fitsfile)) {
      return throw('Failed to create FITS file', origin='imagefromforeign');
   }
#
# Convert to aips++
#
   note ('Converting temporary FITS file to aips++ image', priority='NORMAL',
         origin='imagefromforeign');
   im := imagefromfits(outfile=outfile, infile=fitsfile, overwrite=overwrite);
   if (is_fail(im)) fail;
#
# Delete FITS file
#
   if (dos.fileexists(fitsfile)) {
      ok := dos.remove(fitsfile, T);
      if (is_fail(ok)) {
         msg := spaste('Failed to delete temporary FITS file ', fitsfile);
         note (msg, priority='WARN', origin='imagefromforeign');
      }
   }
#
# Return tool
#
   return im;
}
