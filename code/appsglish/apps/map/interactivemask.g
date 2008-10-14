# interactivemask : a interactive tool to make mask using the viewer
# Copyright (C) 1999,2000,2001,2002,2003
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
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: interactivemask.g,v 19.3 2004/08/25 01:24:45 cvsmgr Exp $


include 'image.g'
include 'viewer.g'
include 'note.g'

interactivemask := function(refimage='', mask=''){
 public:=[=];
 self:=[=]; 



 self.maskstartnumber:=0
 self.addrem:=1;
 self.image:=refimage;
 self.mask:=mask;
 if(self.image==''){
   note('A valid image name has to be given', priority='WARN');
 }
 if(self.mask==''){
   self.mask:=spaste(self.image,'.mask');
 }

 
 
 if(!dos.fileexists(self.mask)){
   myim:=image(self.image);
   arraymask:=array(as_float(0),myim.shape()[1],myim.shape()[2],
		    myim.shape()[3], myim.shape()[4] );
   csys:=myim.coordsys();
   myim.done();
   myim:=imagefromarray(outfile=self.mask, pixels=arraymask, csys=csys);
   myim.done();
   
 }


  public.start := function(){
 
    wider self, public;
    self.returnval:=0;
    self.mydv:=viewer();
    self.mywid:=self.mydv.widgetset();
    self.f1:=self.mywid.frame();
    f3:=self.mywid.frame(self.f1, side='left', height=1, expand='x');
    self.allchan:=self.mywid.button(f3, 'All channels', type='check');
    self.allchan->state(F);
    f2:=self.mywid.frame(self.f1, side='left', height=1, expand='x');
    self.addreg:=self.mywid.button(f3, 'Add regions', type='check');
    self.addreg->state(T);
    self.remreg:=self.mywid.button(f3, 'Remove regions', type='check');
    self.remreg->state(F);
    self.refresh:=self.mywid.button(f3, 'Refresh mask', type='action');
    self.doom:=self.mywid.button(f2, 'DONE with masking', type='dismiss'); 
    self.continue:=self.mywid.button(f2, 'No more mask changes', 
				     type='dismiss');
    self.stop:=self.mywid.button(f2, 'STOP', type='halt');
    self.disable();
    self.mydpp:=self.mydv.newdisplaypanel(parent=self.f1, hasgui=T, widgetset=self.mywid)

    self.mydv.hold();
     self.myddimage:=self.mydv.loaddata(self.image, drawtype='raster');
     self.myddmask:=self.mydv.loaddata(self.mask, drawtype='contour');
     self.opt:=self.myddmask.getoptions();
     self.opt.levels:=[1];
     self.myddmask.setoptions(self.opt);
     self.mydpp.register(self.myddimage);
     self.mydpp.register(self.myddmask);
    self.mydv.release();
     self.enable();
      self.myregions:=[=]

      self.localcounter:=0                    
     whenever self.mydpp->pseudoregion do {
       print 'region selected', $value.pixel;
       localval:=$value;
       self.localcounter:=self.localcounter+1;
       if(self.allchan->state()){
	 self.intersect[self.localcounter]:=F;
       }
       else{
	 self.intersect[self.localcounter]:=T;
       }    

       self.addremflag[self.localcounter]:=self.addrem;
       self.myregions[self.localcounter]:=localval;      
     } 
     whenever self.doom->press do {        
       self.returnval:=1;
       public.done();
     }
     whenever self.continue->press do { 
       self.returnval:=2;
       public.done();
     }
     whenever self.stop->press do { 
       self.returnval:=3;
       public.done();
     }
     whenever self.refresh->press do {
       self.disable();
       self.mydpp.unregister(self.myddmask);  
       self.myddmask.done(); 
       self.refreshmask();
       self.myddmask:=self.mydv.loaddata(self.mask, drawtype='contour');
       self.myddmask.setoptions(self.opt);
       self.mydpp.register(self.myddmask); 
       self.localcounter:=0;
       self.enable();
     }

     whenever self.addreg->press do {
        self.addrem:=1 ;
	self.addreg->state(T);
	self.remreg->state(F);
     }
     whenever self.remreg->press do {
        self.addrem:=-1 ;
	self.addreg->state(F);
	self.remreg->state(T);
     }

    while( is_record(self) && !self.returnval){

      timer.wait(5);
    }

  }



##### local function to refresh mask

self.refreshmask:= function(){
   wider self, public;
 

   im := image(self.mask); 
     if(self.localcounter >0){
       for(k1 in 1:self.localcounter){
        tempregion:=drm.pseudotoworldregion(im, 
                    self.myregions[k1], self.opt, self.intersect[k1])
        if(self.addremflag[k1]>0){ 
           im.set(region=tempregion, pixels=1.0)
        }
        else{
           im.set(region=tempregion, pixels=0.0)
        }

       } 
      }

      im.done();
  }
 self.wait := function() {
   while(T){

     timer.wait(5);
   }

 }


 self.disable := function(){

   self.addreg->disable();
   self.remreg->disable();
   self.refresh->disable();
   self.doom->disable(); 
   self.continue->disable();
   self.stop->disable();
   self.mywid.busy(self.f1);
   
 }
 self.enable := function(){

   self.addreg->enable();
   self.remreg->enable();
   self.refresh->enable();
   self.doom->enable(); 
   self.continue->enable();
   self.stop->enable();
   self.mywid.notbusy(self.f1);

 }


#### public function 

  public.done := function() {
    wider self, public;
    self.mydpp.done();
#    self.mydv.done();
    self.f1->unmap();
    self.refreshmask();
    returnval:= self.returnval;
    self.wait:=F
    self := F;
    val public := returnval;
  }

return ref public ;
 
}












