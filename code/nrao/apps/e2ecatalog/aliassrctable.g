# aliassrctable : creates and writes rows into ALIASLIST table 
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
#
pragma include once;

include 'table.g'

# 
aliassrctable := function(name='ALIASLIST', nrows=0) {

   private := [=];
   public  := [=];

#
# Generic write-a-row function: This could be made faster by using tablerow
# or by caching column updates
#
   private.writerow := function(rec, type) {
      wider private;  

#    print "write type, rec = ", type, rec;

      last_row := private.tabl.getkeyword('last_row');
      new_row  := last_row + 1;
      nrows    := private.tabl.getkeyword('nrows');

      if (new_row > nrows) {
         private.tabl.addrows(1000);
         nrows := nrows + 1000;
         private.tabl.putkeyword("nrows",  as_integer(nrows));
         note('table.addrows 1000 rows to aliassrclist table');
      }

      private.tblrow.put(rownr=new_row, value=rec, matchingfields=F);
      private.tabl.putkeyword('last_row', as_integer(new_row));
      return new_row;
   }

   private.aliassrclist := function() {
      td:=tablecreatedesc( 
         tablecreatescalarcoldesc('JSOURCE_ID',   'UNKNOWN', maxlen=12),
         tablecreatescalarcoldesc('ALIAS_ID',     'UNKNOWN', maxlen=12));
#
      return td;
   }

   public.addalias := function(jsource_id, alias_id) {
      wider private, public;
      rec := [JSOURCE_ID=as_string(jsource_id), ALIAS_ID=as_string(alias_id)];

      type:='aliassrclist';
      return private.writerow(rec, type);
   }
#
# Now create the table if it doesn't exist already
#
   tablename := spaste(name, '.', 'master');
#
   if(!tableexists(tablename)) {
      note('Create new table : ', tablename, origin='aliassrcloader.aliassrctables');
      tabl := table(tablename, private['aliassrclist'](), nrows, ack=F);
      if(!is_table(tabl)) {
         return throw('Failed to create table : ', tablename, 
                       origin='aliassrcloader.create');
      }

      tabl.putkeyword("last_row",as_integer(0));
      tabl.putkeyword("nrows", as_integer(1000));
      tabl.addrows(1000);
      tabl.close();
      note('table.addrows 1000 rows to aliassrclist table');
   }
#
# Now re-open for read/write
#
   private.tabl := table(tablename, ack=F, readonly=F);
   if(!is_table(private.tabl)) {
      return throw('Failed to open table : ', tablename, origin='imcatalogserver.create');
   }
   private.tblrow := tablerow(private.tabl);
# 
# Type identification for toolmanager, etc.
#
   public.type := function() {
      return "aliassrctable";
   }
#
# Done function
#
   public.done := function() {
      wider private, public;
#
# Close all tables
#
      private.tabl.close();
      private.tblrow.close();
      return T;
   }

   return ref public;
}


