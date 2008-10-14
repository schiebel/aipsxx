# imcatalogserver: Define and manipulate image catalogs
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
#   $Id: imcatalogtables.g,v 19.0 2003/07/16 03:44:36 aips2adm Exp $
#
#----------------------------------------------------------------------------
#
pragma include once;

include 'table.g'

# 
imcatalogtables := function(name='IMCATALOG', nrows=0) {

   private := [=];
   public  := [=];

#
# Generic write-a-row function: This could be made faster by using tablerow
# or by caching column updates
#
   private.writerow := function(rec, type) {
      wider private;  

#    print "rec = ", rec;

      tblrow := tablerow(private.tabl);

      last_row := private.tabl.getkeyword('last_row');
      new_row  := last_row + 1;
#
#     putkeyword is fairly slow
#
      private.tabl.putkeyword('last_row', as_integer(new_row));
#
#     table.nrows is quite slow, I should make my own nrows somewhere
#     even a table keyword read/write is faster than .nrows
#
      nrows := private.tabl.getkeyword('nrows');
#      nrows    := private.tabl.nrows();
#
      if (new_row >= nrows) {
         private.tabl.addrows(1000);
         nrows := nrows + 1000;
         private.tabl.putkeyword("nrows", as_integer(nrows));
         note('added 1000 rows to image table');
      }

      tblrow.put(rownr=new_row, value=rec, matchingfields=T);
#
      tblrow.close();
#    rownr := private.tabl.nrows();
      private.tabl.close();
      return nrows;
   }

   private.image := function() {
      td:=tablecreatedesc(
         tablecreatescalarcoldesc('PROJECT_CODE', 'UNKNOWN', maxlen=8),
         tablecreatescalarcoldesc('FIELD_ID',     'UNKNOWN', maxlen=24),
         tablecreatescalarcoldesc('TELESCOPE',    'UNKNOWN', maxlen=12),
         tablecreatescalarcoldesc('IMAGE_TYPE',   'UNKNOWN', maxlen=12),
         tablecreatescalarcoldesc('SOURCE_TYPE',  'UNKNOWN', maxlen=12),
         tablecreatescalarcoldesc('OBS_DATE',     as_double(1)),
         tablecreatescalarcoldesc('CREATE_DATE',  as_double(1)),
         tablecreatescalarcoldesc('EXPOSURE',     as_float(1)),
         tablecreatearraycoldesc ('PIXEL_RANGE',  as_float(1),1,[3]),
         tablecreatescalarcoldesc('IMAGE_UNITS',  'Jy', maxlen=12),
         tablecreatearraycoldesc ('FIELD_SIZE',   as_float(1),1,[4]),
         tablecreatearraycoldesc ('CENTER_DIR',   as_double(1),1,[2]),
         tablecreatearraycoldesc ('PIXEL_INCR',   as_float(1),1,[2]),
         tablecreatearraycoldesc ('RESTORE_BEAM', as_float(1),1,[3]),
         tablecreatescalarcoldesc('POLARIZATION', 'UNKNOWN', maxlen=12),
         tablecreatearraycoldesc ('SPECTRAL',     as_float(1),1,[4]),
         tablecreatescalarcoldesc('IMAGE_FILE', 'NONE', maxlen=32),
         tablecreatescalarcoldesc('PLOT_FILE',  'NONE', maxlen=32),
         tablecreatescalarcoldesc('MODEL_FILE', 'NONE', maxlen=32),
         tablecreatescalarcoldesc('DIRECTORY',  'NONE', maxlen=64));
#
      return td;
   }

   public.addimage := function(project_code, field_id, telescope, image_type,
                              source_type, obs_date, create_date, exposure,
                              pixel_range, image_units, 
                              field_size, center_dir, pixel_incr,
                              restore_beam, polarization, spectral,
                              image_file, plot_file,
                              model_file, directory) {  
      wider private, public;
      rec := [PROJECT_CODE=as_string(project_code), FIELD_ID=as_string(field_id), 
            TELESCOPE=as_string(telescope),
            IMAGE_TYPE=as_string(image_type), SOURCE_TYPE=as_string(source_type), 
            OBS_DATE=as_double(obs_date), CREATE_DATE=as_double(create_date),
            EXPOSURE=as_float(exposure), PIXEL_RANGE=as_float(pixel_range), 
            IMAGE_UNITS=as_string(image_units), FIELD_SIZE=as_float(field_size),
            CENTER_DIR=as_double(center_dir), PIXEL_INCR=as_float(pixel_incr), 
            RESTORE_BEAM=as_float(restore_beam),
            POLARIZATION=as_string(polarization), SPECTRAL=as_float(spectral), 
            IMAGE_FILE=as_string(image_file), PLOT_FILE=as_string(plot_file),
            MODEL_FILE=as_string(model_file), DIRECTORY=as_string(directory)];

      type:='image';
      return private.writerow(rec, type);
   }
#
# Now create the table if it doesn't exist already
#
   tablename := spaste(name, '.', 'image');
#
   if(!tableexists(tablename)) {
      note('Create new table : ', tablename, origin='imagecatalog.imcatalogtables');
      tabl := table(tablename, private['image'](), nrows, ack=F);
      if(!is_table(tabl)) {
         return throw('Failed to create table : ', tablename, origin='imcatalogserver.create');
      }

      keywrd_rec := [
         OBS_DATE=[QuantumUnits = ['d'], MEASINFO = [type='epoch', Ref='UTC']],
         CREATE_DATE=[QuantumUnits = ['d'], MEASINFO = [type='epoch', Ref='UTC']],
         EXPOSURE=[QuantumUnits=['s']], 
         FIELD_SIZE=[QuantumUnits=['pixels']],
         CENTER_DIR=[QuantumUnits=['rad', 'rad'], MEASINFO = [type='direction', Ref='J2000']], 
         PIXEL_INCR=[QuantumUnits=['rad', 'rad']], 
         RESTORE_BEAM=[QuantumUnits=['arcsec','arcsec','deg']]];
#
#        print "keywrd_rec = ", keywrd_rec;
#
      for (key_field in field_names(keywrd_rec)) {
         kw := keywrd_rec[key_field];
         tabl.putcolkeywords(columnname=key_field, value=keywrd_rec[key_field]);
      }
         tabl.putkeyword("last_row",as_integer(0));
         tabl.putkeyword("nrows", as_integer(1000));
         tabl.addrows(1000);
         tabl.close();
         note('table.addrows 1000 rows ot image table');
   }
#
# Now re-open for read/write
#
   private.tabl := table(tablename, ack=F, readonly=F);
   if(!is_table(private.tabl)) {
      return throw('Failed to open table : ', tablename, origin='imcatalogserver.create');
   }
#
# Type identification for toolmanager, etc.
#
   public.type := function() {
      return "imcatalogtables";
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
      return T;
   }

   return ref public;
}


