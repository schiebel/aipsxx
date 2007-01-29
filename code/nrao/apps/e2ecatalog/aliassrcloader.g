# aliassrcloader : loads jsource/alias pair into ALIASLIST table
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

aliassrcloader := function(directory='/users/jbenson/aips2data', srcfile='none', tablename='ALIASLIST') {
#
# Include all the good stuff
#  
   include 'table.g';
   include 'quanta.g';
   include 'measures.g';
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
		   origin='aliassrcloader');
   }
#
#
   private.filename := infile;
   private.maxants := 100;
   private.tablename := tablename;
#
#
#
   note('Input file name  = ', private.filename, origin='aliaslistloader');
   note('Table name       = ', private.tablename, origin='aliaslistloader');
#
#
#----------------------------------------------------------------------------
#
# Public function that writes an AIPS++ table containing the VLA/VLBA
# Calibrator Source Table
#
   public.write := function() {
    
      wider private;
#
# Make a server to handle mscatalog interactions
#
      mscs := F;
      include 'aliassrctable.g';
      mscs := aliassrctable(private.tablename);
      note('Adding alias names to AIPS++ table, table name = ', 
           private.tablename, origin='aliassrcloader.writetable');

      if(is_fail(mscs)) {
         return throw('Failed to open aliassrctable server ', mscs::result,
		                 origin='aliassrcloader');
      }
#
# Finally add jsource_id, alias_id pair
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
         private.jsource_id     := spaste(split(linevec[1]));
         private.alias_id       := spaste(split(linevec[2]));
#
# We will write out a source row in alissrclist table for the current row
#
		   result := mscs.addalias(private.jsource_id, private.alias_id);
         if(is_fail(result)) {
	         return throw('Failed to write row to aliaslist table ', 
                          result::message, origin='aliassrcloader');
         }
      }
#
#  print "stop loading tables : ",  shell('date');
  print "read and copied nsrcs = ", nsrcs;
#
# end of row loop
#--------------------------------------------------------------------------------
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
    return "aliassrcloader";
  }


  public.done := function() {
    return T;
  }

  return ref public;
}
# End of aliassrclistloader function 
#----------------------------------------------------------------------------
#



