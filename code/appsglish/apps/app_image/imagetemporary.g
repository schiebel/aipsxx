# imagetemporary.g: persistent temporary image handling
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

include 'image.g'
include 'imagesupport.g'
include 'note.g'
include 'os.g'
include 'serverexists.g'
include 'unset.g'

#
# t := imagetemporary(im, directory='/tmp')
# filename := t.access()      # Creates when needed
# t.delete()
# t.done()                    # deletes and dones
#

const imagetemporary := subsequence (theImage, type='image', directory='.')
{
    if (!serverexists('dos', 'os', dos)) {
       return throw('The os server "dos" is not running',
                     origin='imagetemporarypersistent.g');
    }
    if (!serverexists('defaultimagesupport', 'imagesupport', defaultimagesupport)) {
       return throw('The imagesupport server "defaultimagesupport" is not running',
                    origin='imagetemporarypersistent.g');
    }
#
    its := [=];
    its.type := type;
    its.persistDir := '';
    its.persistFileName := '';
    its.whenever := 0;

### Private methods

###
   const its.makeName := function (directory='.')
   {
       wider its;
#
       parentdir := dos.fullname(directory);
       if (is_fail(parentdir)) fail;
#
       root := spaste(parentdir, '/', 'temp_imagedir');  
       its.persistDir := defaultimagesupport.defaultname(root);
       if (is_fail(its.persistDir)) fail;
#
       fileroot := spaste(its.persistDir, '/temp_image');
       its.persistFileName := defaultimagesupport.defaultname(fileroot);
       if (is_fail(its.persistFileName)) fail;
#
       return T;
   }

### Public methods

###
   const self.delete := function ()
   {
      ok := T;
      if (dos.fileexists(file=its.persistDir, follow=T)) {
         ok := dos.remove(pathname=its.persistDir, 
                          recursive=T, follow=T);
         if (is_fail(ok)) {
            note(ok::message, origin='imagetemporary.delete', 
                 priority='SEVERE');
         } else {
            note (spaste('Deleted ', its.persistDir), priority='NORMAL',
                  origin='imatetemporary.delete');
         }
      }
      return ok;
   }

###
   const self.done := function ()
   {
      wider its, self;
#
      deactivate its.whenever;         # If we have been 'doned' we can't call self.delete
      self.delete();
#
      val its := F;
      val self := F;
#
      return T;
   }

###
   const self.access := function ()
   {
      wider its;
#
      local makeIt := F;
      if (!dos.fileexists(its.persistDir, T)) {
         if (is_fail(dos.mkdir(its.persistDir))) {
            msg := spaste('Could not create temporary directory ', its.persistDir);
            return throw(msg, origin='imagetemporary.access');
         }
         makeIt := T;
      } else {
        if (!dos.fileexists(its.persistFileName, T)) {
           note('The temporary and persistent image seems to have disappeared; will try to recreate',
                priority='WARN', origin='imagetemporary.access');
           makeIt := T;
        }
     }
#
# Make persistent copy if desired and done its image tool
#
     if (makeIt) {
        if (its.type=='image') {
            _imagetemp := theImage.subimage(outfile=its.persistFileName);
        } else if (its.type=='FITS') {
	    _imagetemp := imagefromfits(outfile=its.persistFileName,
					infile=theImage);
        } else if (its.type=='Miriad Image') {
	    _imagetemp := imagefromforeign(outfile=its.persistFileName,
					   infile=theImage,
					   format='miriad');
        } else if (its.type=='Gipsy') {
	    _imagetemp := imagefromforeign(outfile=its.persistFileName,
					   infile=theImage,
					   format='gipsy');	    
        }
# 
        if (is_fail(_imagetemp)) fail;
        if (is_fail(_imagetemp.done())) fail;
     }    
#
# Always return aips++ image file name
#
     return its.persistFileName;
   }

# Here is the rest of the constructor

   ok := its.makeName(directory);

# Clean up tempimage on exit from Glish

   whenever system->exit do {
      self.delete()
   }
   its.whenever := last_whenever_executed()
}
