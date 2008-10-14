# Copyright (C) 1999,2000,2001
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#

include "image.g";
include "measures.g";
include "note.g";
include "misc.g"


automask := function(modelimage="first.image", cutlevel="0Jy", width=[10,10], mfield=T){

global level, modim;

 
#symbol_set("level", dq.convert(cutlevel,'Jy').value);
level:=dq.convert(cutlevel,'Jy').value
print level

k := 1; 
for (k in 1:(length(modelimage))){
#  symbol_set("modim", modelimage[k])
modim:=modelimage[k];
  print modim
  oprstring:=spaste('((ceil(sign((',as_string(modim),')-(',as_string(level),'))+0.2))/2.0)');
   shell("rm -rf mask.image");
#  im := imagecalc('mask.image', '((ceil(sign(($modim)-($level))+0.2))/2.0)');
   im:=imagecalc('mask.image',oprstring);

 if(mfield==T){
  blc:=[1, 1];
  trc:=[im.shape()[1], im.shape()[2]];
 }
 else {
   blc:=[im.shape()[1]/4+1, im.shape()[2]/4+1];
   trc:=[(3*im.shape()[1])/4,(3*im.shape()[2])/4];
 }
  print blc, trc
  box1:=drm.box(blc=blc, trc=trc);
  im1:=im.sepconvolve('mask.image.sepcon',region=box1, axes=[1, 2], types='gauss gauss', widths=width)
  im.done();
  shell("rm -rf mask.image");
  maskimage:=paste(modelimage[k],".mask",sep='')
  im1.statistics(mystats);
  if(mystats.max > 5*mystats.sigma){
    newval := 5*mystats.sigma;
  }
  else{
    print 'Trouble peak of convolved image is less that 5 rms';
    newval := 3*mystats.sigma;
  }
  oprstring:=spaste('ceil(sign(mask.image.sepcon-',as_string(newval),')+0.2)/2');
#  im:=imagecalc(maskimage,'ceil(sign(mask.image.sepcon-newval)+0.2)/2')
   im:=imagecalc(maskimage, oprstring);
  im1.done()
  shell("rm -rf mask.image.sepcon");
#  im:=image(maskimage);
  arr1:=array(0.0, im.shape()[1], width[2]);
  im.putchunk(pixels=arr1, blc=[1, im.shape()[2]-width[2]]);
  arr2:=array(0.0, width[1], im.shape()[2]);
  im.putchunk(pixels=arr2, blc=[im.shape()[1]-width[1], 1]); 
  im.view();
  im.close()
  im.done;
}

#symbol_delete("modim");
#symbol_delete("level");

}


