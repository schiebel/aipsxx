# calsrclisttable : creates and writes rows into VLA/VLBA cal. source table 
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
calsrclisttable := function(name='CALSRCLIST', nrows=0) {

   private := [=];
   public  := [=];

#
# Generic write-a-row function: This could be made faster by using tablerow
# or by caching column updates
#
   private.writerow := function(rec, type) {
      wider private;  

      last_row := private.tabl.getkeyword('last_row');
      new_row  := last_row + 1;
      nrows    := private.tabl.getkeyword('nrows');

      if (new_row > nrows) {
         private.tabl.addrows(1000);
         nrows := nrows + 1000;
         private.tabl.putkeyword("nrows",  as_integer(nrows));
         note('added 1000 rows to calsrclist table');
      }

      private.tblrow.put(rownr=new_row, value=rec, matchingfields=F);
      private.tabl.putkeyword('last_row', as_integer(new_row));
   
      return new_row;
   }

   private.calsrclist := function() {
      td:=tablecreatedesc( 
         tablecreatescalarcoldesc('SOURCE_ID',   'UNKNOWN', maxlen=12),
         tablecreatescalarcoldesc('EPOCH_DATE',   as_double(1)),
         tablecreatearraycoldesc ('CENTER_DIR',   as_double(1),1,[2]),
         tablecreatearraycoldesc ('DIR_ERRS',     as_double(1),1,[2]),
         tablecreatearraycoldesc ('FREQ_RANGE',   as_double(1),1,[2]),
         tablecreatearraycoldesc ('UV_RANGE',     as_float(1),1,[2]),
         tablecreatescalarcoldesc ('FLUX',         as_float(1)),
         tablecreatescalarcoldesc ('RESOLUTION',   as_float(1)),
         tablecreatescalarcoldesc ('VARIABILITY',  as_float(1)),
         tablecreatescalarcoldesc('CODE_VLA',    'NONE', maxlen=4),
         tablecreatescalarcoldesc('CODE_VLBA',   'NONE', maxlen=4),
         tablecreatescalarcoldesc('ENTRY_DATE',   as_double(1)),
         tablecreatescalarcoldesc('POS_REF',     'NONE', maxlen=100),
         tablecreatescalarcoldesc('FLUX_REF',    'NONE', maxlen=100));

      return td;
   }

   public.addsrc := function(source_id, epoch_date, center_dir, dir_errs,
                             freq_range, uv_range, flux, resolution, variability,
                             code_vla, code_vlba, entry_date, 
                             pos_ref, flux_ref) {
      wider private, public;
      rec := [SOURCE_ID=as_string(source_id), EPOCH_DATE=as_double(epoch_date),
            CENTER_DIR=as_double(center_dir), DIR_ERRS=as_double(dir_errs),
            FREQ_RANGE=as_double(freq_range), UV_RANGE=as_float(uv_range),
            FLUX=as_float(flux), RESOLUTION=as_float(resolution), 
            VARIABILITY=as_float(variability),
            CODE_VLA=as_string(code_vla), CODE_VLBA=as_string(code_vlba),
            ENTRY_DATE=as_double(entry_date),
            POS_REF=as_string(pos_ref), FLUX_REF=as_string(flux_ref)];

      type:='calsrclist';
      return private.writerow(rec, type);
   }
#
# Now create the table if it doesn't exist already
#
   tablename := spaste(name, '.', 'master');
#
   if(!tableexists(tablename)) {
      note('Create new table : ', tablename, origin='calsrclistloader.calsrclisttables');
      tabl := table(tablename, private['calsrclist'](), nrows, ack=F);
      if(!is_table(tabl)) {
         return throw('Failed to create table : ', tablename, origin='calsrclistloader.create');
      }

      keywrd_rec := [
         EPOCH_DATE=[QuantumUnits = ['d'], MEASINFO = [type='epoch', Ref='UTC']],
         CENTER_DIR=[QuantumUnits=['rad', 'rad'], MEASINFO = [type='direction', Ref='J2000']], 
         DIR_ERRS=[QuantumUnits=['arcsec', 'arcsec'], MEASINFO = [type='direction', Ref='J2000']], 
         FREQ_RANGE=[QuantumUnits=['Hz', 'Hz']],
         UV_RANGE=[QuantumUnits=['m','m'], MEASINFO = [type='uvw', Ref='ITRF']],
         ENTRY_DATE=[QuantumUnits = ['d'], MEASINFO = [type='epoch', Ref='UTC']],
         FLUX=[QuantumUnits=['Jy']]];
#
      for (key_field in field_names(keywrd_rec)) {
         kw := keywrd_rec[key_field];
         tabl.putcolkeywords(columnname=key_field, value=keywrd_rec[key_field]);
      }
         tabl.putkeyword("last_row",as_integer(0));
         tabl.putkeyword("nrows", as_integer(1000));
         tabl.addrows(1000);
         tabl.close();
         note('table.addrows 1000 rows to calsrclist table');
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
      return "calsrclisttable";
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


