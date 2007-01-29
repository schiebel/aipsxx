# calsrclistloader : loads VLA/VLBA calibrator sources into catalog table
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
#
#----------------------------------------------------------------------------

pragma include once;

#
# 

calsrclistloader := function(directory='/users/jbenson/aips2data', srcfile='none', tablename='CALSRCLIST') {
#
#  Include all the good stuff
#  
   include 'table.g';
   include 'quanta.g';
   include 'measures.g';
   include 'e2efuncs.g';
#
# Define private data and public functions
#  
   private := [=];
   public  := [=];
#
#
   indir  := paste(directory);
   infile := paste(srcfile);
#
   filename := spaste(indir,'/',infile);
   xfile := open (spaste('< ',filename));
#
   if (!is_file(xfile)) {
	   print "input file : ", xfile;
      return throw('Failed to open input file ', result::message,
		              origin='calsrclistloader');
   }
#
#
   private.filename := infile;
   private.maxants := 100;
   private.tablename := tablename;
#
#
#
   note('Input file name  = ', private.filename, origin='calsrclistloader');
   note('Table name       = ', private.tablename, origin='calsrclistloader');
#
#
#----------------------------------------------------------------------------
#
   private.entry_date := mjdTimeNow();
#
#
#  Public function that writes an AIPS++ table containing the VLA/VLBA
#  Calibrator Source Table
#
   public.write := function() {
    
      wider private;
#
# Make a server to handle calsrclist table interactions
#
      mscs := F;
      include 'calsrclisttable.g';
      mscs := calsrclisttable(private.tablename);
      note('Adding cal source info to AIPS++ table, table name = ', 
           private.tablename, origin='calsrclistloader.writetable');

      if(is_fail(mscs)) {
         return throw('Failed to open calsrclisttable server ', mscs::result,
		                origin='calsrclistloader');
      }
#
# Finally add observation information:
#
      ra2000  := as_double(0.0);
      dec2000 := as_double(0.0); 
      twopi   := as_double(2.0*pi);
#
#--------------------------------------------------------------------------------
# Begin loop here.
#
#    print "start loading tables : ",  shell('date');
      nsrcs := 0;
      while (linebuf := read(xfile)) {

         linevec := split(linebuf, ',');
#
         nsrcs := nsrcs + 1;

#
# Load up values into the private record.
#        
         private.source_id     := spaste(split(linevec[1]));
         mjad                  := dq.quantity(linevec[2]);
         private.epoch_date    := as_double(mjad.value);
 
         ra2000  := as_double(linevec[3]);
         dec2000 := as_double(linevec[4]);
         private.center_dir[1] := ra2000;
         private.center_dir[2] := dec2000;
         raerr  := as_double(linevec[5]);
         decerr := as_double(linevec[6]);
         private.dir_err[1]    := raerr;
         private.dir_err[2]    := decerr;

         private.freq_range[1] := as_double(linevec[7])*1.0e+6;
         private.freq_range[2] := as_double(linevec[8])*1.0e+6;
         private.uv_range[1]   := as_float(linevec[9]);
         private.uv_range[2]   := as_float(linevec[10]);

         private.flux          := as_float(linevec[11]);
         private.resolution    := as_float(linevec[12]);
         private.variability   := as_float(linevec[13]);

         private.code_vla      := spaste(linevec[14]);
         private.code_vlba     := spaste(linevec[15]);

         mjad                  := dq.quantity(linevec[16]);
         private.entry_date    := as_double(mjad.value);

         private.pos_ref       := spaste(linevec[17]);
         private.flux_ref      := spaste("unknown"); 
#
# We will write out a source row in calsrclist table for the current row
#
			result := mscs.addsrc(private.source_id, private.epoch_date,
                               private.center_dir, private.dir_err,
                               private.freq_range, private.uv_range,
                               private.flux, private.resolution,
                               private.variability,
                               private.code_vla, private.code_vlba,
                               private.entry_date,
                               private.pos_ref, private.flux_ref);
         if(is_fail(result)) {
	         return throw('Failed to write row to calsrclist table ', 
                         result::message, origin='calsrclistloader');
         }
      }
#
#  print "stop loading tables : ",  shell('date');
      print "read and copied nsrcs = ", nsrcs;

#
# end of row loop
#--------------------------------------------------------------------------------
#

#
# Everything is now written
#
      mscs.done();

      return T;
   }
#
# End of public.write function
#----------------------------------------------------------------------------
#
# Type identification for toolmanager, etc.
#
   public.type := function() {
      return "calsrclistloader";
   }


   public.done := function() {
      return T;
   }

  return ref public;
}
# End of calsrclistloader function 
#----------------------------------------------------------------------------
#



