# imagecatalog : writes a row into image catalog table for one image file
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
#   $Id: imagecatalog.g,v 19.0 2003/07/16 03:44:35 aips2adm Exp $
#
#----------------------------------------------------------------------------
#
# Retrieves meta-data from an AIPS++ Image Files and writes out
# rows into an AIPS++/Glish catalog table
#
# Notes : missing information 
#
#         project_code,
#         field_id,
#         image-type,
#         start obs, stop obs, exposure
#
#    information not filled in 
#         telescope   (except GBT images),
#         observer,   
#         obsdate,
#         restoring beam (for GBT images),
#         image pixel units (for GBT images),
#
# To be implemented :
#
#   - transmit axis information retrieved from the image file to
#     imcatalogtables.g for column keywords,
#   - fix up the polarizaion description
#
#============================================================================
#
pragma include once;
#
imagecatalog := function(directory='none', imname, catalogname='IMCATALOG') {
#
   include 'image.g';
   include 'coordsys.g';
#
# Define private data and public functions
#  
   private := [=];
   public  := [=];
#
   if (!tableexists(imname)) {
      return throw(paste('image file', imname, 'does not exist'),
		             origin='imagecatalog.g');
   }
#
   private.catalogname := catalogname;
#
# Input Image file name :
#
   imfilename := paste(imname);
#
   print "Input IM file name   = ", imfilename;
   plotfilename := paste("plotfile.gif");
   modelfilename := paste("NONE");
   file_directory := paste(directory);
#
# Construct image and coordsys tools
#
   im        := image(imfilename);
   cs        := im.coordsys();
#
   exposure  := 0.0;
   arch_file_id := 0;
   field_id  := paste('UNKNOWN');
   image_type:= paste('UNKNOWN');
   source_type := paste('UNKNOWN');
#
   cstelescope := cs.telescope();
   csobserver  := cs.observer();
   telescope := paste(cstelescope);
   project   := paste(csobserver);
   obsdaterec := cs.epoch();
   obsdate   := obsdaterec.m0.value;
   obsdate   := as_double(obsdaterec.m0.value);
#
# In the next version of this thing I've got to check and possibly
# convert the units on the axes. Fixed units in the catalog table..
#
   image_shape := im.shape();
   image_units := paste(im.brightnessunit());
#
   image_restore := im.restoringbeam();
   restore_maj  := image_restore.major.value;
   restore_min  := image_restore.minor.value;
   restore_unit := image_restore.major.unit;
   restore_pa   := image_restore.positionangle.value;
   restore_pa_u := image_restore.positionangle.unit;
#
   restore_beam[1] := as_float(restore_maj);
   restore_beam[2] := as_float(restore_min);
   restore_beam[3] := as_float(restore_pa);
#
# calculate some image statistics for the catalog
#
   im.statistics(statsout=imstats,list=F,verbose=F);
#
   pixel_range[1] := as_float(imstats.max);
   pixel_range[2] := as_float(imstats.min);
   pixel_range[3] := as_float(imstats.rms);
#
# now use the coordsys tool for the rest 
#
# get the number of axes in the image
#
   naxes := cs.naxes();
   if (naxes <= 0) {
      return throw(paste('image : ', imname, 'reports no axes'),
		             origin='imagecatalog.g');
   }
#
# we expect four axes : direction[2], spectral, stokes
#
   if (!cs.findcoordinate (pdir, wdir, 'direction')) {
      return throw(paste('image : ', imname, 'reports no direction axes'),
		             origin='imagecatalog.g');
   }
   if (!cs.findcoordinate (pspect, wspect, 'spectral')) {
      return throw(paste('image : ', imname, 'reports no spectral axis'),
		             origin='imagecatalog.g');
   }
   if (!cs.findcoordinate (pstokes, wstokes, 'stokes')) {
      return throw(paste('image : ', imname, 'reports no stokes axis'),
		             origin='imagecatalog.g');
   }

   ref_pixels := cs.referencepixel();
   ref_values := cs.referencevalue();
   pix_incr   := cs.increment();
   pix_units  := cs.units();

   pc_crpix_x := ref_pixels[pdir[1]];
   pc_crpix_y := ref_pixels[pdir[2]];
   pc_x       := ref_values[pdir[1]];
   pc_y       := ref_values[pdir[2]];
   pc_units   := pix_units[pdir[1]];
   pc_x_delt  := pix_incr[pdir[1]];
   pc_y_delt  := pix_incr[pdir[2]];
#
   center_dir[1]   := as_double(pc_x);
   center_dir[2]   := as_double(pc_y);
#
   pixel_incr[1]  := as_float(pix_incr[pdir[1]]);
   pixel_incr[2]  := as_float(pix_incr[pdir[2]]);
#
   field_size[1] := as_float(image_shape[1]);
   field_size[2] := as_float(image_shape[2]);
   field_size[3] := as_float(pc_crpix_x);
   field_size[4] := as_float(pc_crpix_y);
#
   polarization := paste(cs.stokes());
#
   spectral[1] := as_float(image_shape[pspect]);
   spectral[2] := as_float(ref_pixels[pspect]);
   spectral[3] := as_float(ref_values[pspect]);
   spectral[4] := as_float(pix_incr[pspect]);
#
#
#----------------------------------------------------------------------------
#
# Make a server to handle imagecatalog interactions
#
   imcs := F;
   include 'imcatalogtables.g';
   imcs := imcatalogtables(private.catalogname);
#    note('Adding image info to AIPS++ tables, table = ', 
#           private.catalogname, ' file = ', imfilename, 
#           origin='imagecatalog.writetable');
#
   if (is_fail(imcs)) {
      return throw('Failed to open image catalog server ', imcs::result,
		             origin='imagecatalog');
   }
#
# Now add a row to the image catalog table.
#
   result := imcs.addimage(project, field_id, telescope, image_type,
                           source_type, obsdate, obsdate, exposure,
                           pixel_range, image_units, field_size, 
                           center_dir, pixel_incr,
                           restore_beam, polarization, spectral, 
                           imfilename, plotfilename,
                           modelfilename, file_directory);
#
   if (is_fail(result)) {
      return throw('Failed to write row to image catalog. ', result::message, 
                   origin='imagecatalog');
}
#
   imcs.done();
   im.done();
   cs.done();
#
   return T;
};


