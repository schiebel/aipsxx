# synthesistoy.g: 
#
#   Copyright (C) 1998,1999,2000,2001,2002
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
#   $Id: synthesistoy.g,v 19.1 2004/08/25 01:54:18 cvsmgr Exp $

pragma include once;

# The following must be here to define unset
include 'unset.g';
# The following include must be here to define ddlws
include 'ddlws.g';

include 'viewer.g';

# synthesistoy is a special purpose toy program and therefore has been
# written quickly and without much attention paid to extensibility.
# Nevertheless it can probably be extended a moderate amount easily
#
# It follows simple Glish idioms that are help in writing reasonably 
# complex tools
#
#	- It is a closure with private data and functions, and public 
# functions. The 'public' variable (see below) is returned to the user
# and provides the only mechanism to interact with the closure. Thus
# private data is indeed private and can only be changed by a 'public'
# function. This idiom is widespread in AIPS++ coding of Glish 
# capabilities.
#	- Internal data is stored in sub-records of the 'private'
# data.
#	- Relatively few parameters passed in arguments. Instead much of
# the necessary parameters are available via the name private subrecords
# e.g. private.inputs contains all the input variables.
#	- Much use is made of unset.g to define variables as being unset.
#
# It works as follows:
#	- The calculation of arrays and uv coverage is done entirely
# in Glish with no use of the synthesis tools. 
#	- The fftserver tool is used to do FFTs needed for the convolution.
#	- The deconvolver tool is used for the deconvolutions. All images
# are actually stored as arrays internally. When deconvolver is invoked, 
# the arrays are converted to temporary AIPS++ images which are then
# passed to deconvolver.
#
# The GUI is set up as follows:
#	- A top level frame is created. Child frames are created as necessary
# to give the desired layout. glish/tk is a little fiddly to get right so this
# is a little more complex than one would like.
#	- A viewer tool is created. 'Display panels' are created, one per images
# to display. As needed, 'Display datas' are created from each array, and the
# display data is registered on the appropriate display panel. Redisplay is
# performed by destroying old display datas, building new ones, and registering
# those on the display panels (which are not changed).
#	- The gchooser widget is used for the display of the antenna locations.
#

synthesistoy:=function(modelname=unset, colormap='Rainbow 3', widgetset=ddlws) {

  note('Starting synthesistoy', origin='synthesistoy');

#
# Private and public holders.
#  
  private := [=];
  public  := [=];

#
# Clean up any old mess
#  
  shell('/bin/rm -rf synthesistoy_images');
  shell('mkdir synthesistoy_images');
#
# Private data holders
#
  private.images := [=];
  private.frames := [=];
  private.buttons := [=];
  private.labels := [=];
  private.tools := [=];
  private.inputs := [=];
#
# Now make the tools that we know we will need
#
  include 'fftserver.g';
  private.tools.fft := fftserver();
#
# For the guientry widgets used in the interface
#
  private.ge := widgetset.guientry();

#
# Define the inputs, both from function arguments and from
# entry widgets
#
  private.inputs.modelname := modelname;
  private.inputs.colormap := colormap;

  private.inputs.arrayshape := 'star';
  private.inputs.narms := 3;
  private.inputs.power := 1.716
  private.inputs.nants := 27;
  private.inputs.dec := '45d00m00.000s';
  private.inputs.latitude := '34d04m43.5s';
  private.inputs.harange := [-4, 4];
  private.inputs.hastep := 1.0;
  private.inputs.algorithm := 'mem';
  private.inputs.sampling := 0.5;

#
# Boilerplate code for locking buttons once something is 
# happening
#
  private.iambusy := F;
  private.lock := function() {
    wider private;
    if(!private.iambusy) {
      private.iambusy := T;
      private.frames.top->disable();
      private.frames.top->cursor('watch');
      return T;
    }
    else {
      note('Please wait until the current activity has finished',
	   origin='synthesistoy');
      return F;
    }
  }
  private.unlock := function() {
    wider private;
    private.iambusy := F;
    private.frames.top->enable();
    private.frames.top->cursor('left_ptr');
    return T;
  }
#
# Boilerplate code for remembering and subsequently deactivating
# whenevers. If you don't deactivate whenevers on exit then strange
# things can sometimes happen.
#
  private.whenevers := [=];
  private.whenevers.default := [];
#
# Call this to store the last whenever defined. You can define a
# category if needed.
#
  private.pushwhenever := function(category=unset) {
    wider private;
    if (is_unset(category)) {
      private.whenevers.default[len(private.whenevers.default) + 1] := 
        last_whenever_executed();
    } else {
      if (!has_field(private.whenevers, category)) {
        private.whenevers[category] := [];
      }
      private.whenevers[category][len(private.whenevers[category]) + 1] := 
        last_whenever_executed();
    }
  }
#
# Call this to deactivate all whenevers in a given catagory.
#
  private.deactivatewhenever := function(category=unset) {
    wider private;
    if (is_unset(category)) {
      deactivate private.whenevers.default;
      private.whenevers.default := [];
    } else {
      if (has_field(private.whenevers, category)) {
        deactivate private.whenevers[category];
        private.whenevers[category] := [];
      }
    }
  }
#
# Get the initial model into arrays
#
  private.getmodel := function() {
    wider private, public;
#
# Use M31 if no model was specified
#
    if(is_unset(private.inputs.modelname)) {
      note('No model specified - will use default M31.model.fits from data repository',
	   origin='synthesistoy');
      note('Ignore any error messages about FITS cards',
	   origin='synthesistoy');
      include 'sysinfo.g';
      sysroot := sysinfo().root();
      modelname := spaste(sysroot, '/data/demo/M31.model.fits');
      private.inputs.modelname := 'synthesistoy_images/M31.model';
      im:=imagefromfits(private.inputs.modelname, modelname, overwrite=T);
      if(is_fail(im)) return throw('Cannot open image ',
				   modelname);
      im.done();
    }
    else {
      note('Using model image ', private.inputs.modelname,
	   origin='synthesistoy');
    }
    im := image(private.inputs.modelname);
    if(is_fail(im)) return throw('Cannot open image ',
					 private.inputs.modelname);
    shape := im.shape();
    private.images.nx := 2*shape[1];
    private.images.ny := 2*shape[2];
    private.images.csys:=im.coordsys();
    coords := private.images.csys.coordinatetype(unset);
#
# We need to fix up the coordinate system for M31
#
    if(!any(coords=='spectral')) private.images.csys.addcoordinate(spectral=T);
    if(!any(coords=='stokes')) private.images.csys.addcoordinate(stokes='I');
    private.images.csys.setreferencepixel(type='direction',
				   value=[private.images.nx/2+1, private.images.ny/2+1]);
    note('Opened model image ', private.inputs.modelname, ' with shape ', shape,
	 origin='synthesistoy');
#
# Get the model and renormalize: store various versions in the private variable
#
    private.images.modelsub:=F; pmsub:=F;
    im.getregion(private.images.modelsub, pmsub);
    note('Normalized peak of model to unity', origin='synthesistoy');
    private.images.modelsub := private.images.modelsub/max(private.images.modelsub);
    im.done();
    private.images.model:=array(0.0, private.images.nx, private.images.ny);
    private.images.xsub:=(1+(private.images.nx/4)):((3*private.images.nx)/4);
    private.images.ysub:=(1+(private.images.ny/4)):((3*private.images.ny)/4);
    private.images.model[private.images.xsub, private.images.ysub]:=
	private.images.modelsub;
    private.images.dirty:=private.images.model;
    private.images.dirtysub:=private.images.modelsub;
    private.images.dirtymodel:=private.images.dirtysub;
    return T;
  }
#
# Make the required telescope array and store the answer in private.ants
#
  private.makeants := function() {
    wider private, public;
    
    note('Making antennas for array ', private.inputs.arrayshape,
	 origin='synthesistoy');

    if(private.inputs.arrayshape=='star') {
      nperarm := private.inputs.nants/private.inputs.narms;
      a     := 0:(private.inputs.nants-1)%nperarm + 1;
      r     := 0.5*(as_float(a)^private.inputs.power)/as_float(nperarm)^private.inputs.power;
      phase := pi/2+0.1+as_integer(0:(private.inputs.nants-1)/nperarm)*2.0*pi/(as_float(private.inputs.narms));
    }
    else if(private.inputs.arrayshape=='circle') {
      r     := 0.5;
      phase := ((1:private.inputs.nants)-1)*2*pi/as_float(private.inputs.nants);
    }
    else if(private.inputs.arrayshape=='randomcircle') {
      if(!has_field(private.tools, 'rn')) {
	include 'randomnumbers.g';
	private.tools.rn:=randomnumbers();
      }
      r     := 0.5;
      phase := private.tools.rn.uniform(-pi, +pi, private.inputs.nants);
    }
    else if((private.inputs.arrayshape=='random')||T) {
      if(!has_field(private.tools, 'rn')) {
	include 'randomnumbers.g';
	private.tools.rn:=randomnumbers();
      }
      r     := 0.5*sqrt(private.tools.rn.uniform(0.0, 1.0, private.inputs.nants));
      phase := private.tools.rn.uniform(-pi, +pi, private.inputs.nants);
    }
    rec := [=];
    rec.x:= r*cos(phase);
    rec.y:= r*sin(phase);
    rec.active := array(T, private.inputs.nants);
    private.ants := rec;
    return T;
  }
#
# Make the mask for this uv coverage: this is equivalent to gridding
# but done with no finesse - we simply move to the nearest point.
#  
  private.makemask := function() {
    wider private, public;

    nx := private.images.nx;
    ny := private.images.ny;
    private.images.mask := array(0.0, nx, ny);
    ha := min(private.inputs.harange);
    include 'quanta.g';
    dec := dq.convert(private.inputs.dec, 'rad').value;
    latitude := dq.convert(private.inputs.latitude, 'rad').value;
#
# Various coordinate conversions
#
# From local to Earth-centered
#
    ex := private.ants.x;
    ey := private.ants.y * cos(latitude);
    ez := private.ants.y * sin(latitude);

    cosdec := cos(dec);
    sindec := sin(dec);

    while(ha < max(private.inputs.harange)) {
      dphase := 2 * pi * (ha/24.0);
      cosd := cos(dphase);
      sind := sin(dphase);
#
# As seen from the source
#
      x  :=   ex * cosd + ey * sind;
      y  := (-ex * sind + ey * cosd) * sindec + ez * cosdec;

      for (j in (1:len(x))[private.ants.active]) {
	for (i in (1:len(x))[private.ants.active]) {
	  u := as_integer(private.inputs.sampling*(nx/2)*(x[j]-x[i]))+nx/2+1;
	  v := as_integer(private.inputs.sampling*(ny/2)*(y[j]-y[i]))+ny/2+1;
	  if((u>0)&&(u<=nx)&&(v>0)&&(v<=ny)) {
	    private.images.mask[u,v]:=1.0;
	  }
	}
      }
      ha +:= abs(private.inputs.hastep);
    }
#
# We don't want no stinking zero spacing
#
    private.images.mask[nx/2+1,ny/2+1]:=0.0;
#
# Normalize
#
    private.images.mask:=private.images.mask/sum(private.images.mask);
    return T;
  }
#
# Convert an array to an AIPS++ image
#  
  private.toimage := function(arr, imagename) {
    wider private;
    if(len(arr::shape)==2) {
      arr::shape:=[arr::shape[1], arr::shape[1], 1, 1];
    }
    if(tableexists(imagename)) tabledelete(imagename);
    im:=imagefromarray(imagename, pixels=arr, csys=private.images.csys,
		       overwrite=T);
    if(is_fail(im)) {
      print im;
      return throw('Failed to create image ', imagename, ' : ',
				 im::message);
    }
    im.done();
    return T;
  }
#
# Convert an AIPS++ image to an array
#
  private.fromimage := function(imagename) {
    wider private;
    im:=image(imagename);
    if(is_fail(im)) {
      print im;
      return throw('Failed to open image ', imagename, ' : ',
		   im::message);
    }
    pm:=F; pix:=F;
    im.getregion(pix, pm, region=drm.quarter());
    im.done();
    pix::shape:=[pix::shape[1], pix::shape[2]];
    return pix;
  }
#
# Do the deconvolution by calling the deconvolver tool
#
  private.deconv:=function(dirty, psf, omodel, algorithm='clarkclean') {
    wider private, public;
    include 'image.g';
    if(is_fail(private.toimage(dirty, 'synthesistoy_images/dirty'))) fail;
    if(is_fail(private.toimage(psf, 'synthesistoy_images/psf'))) fail;
    if(is_fail(private.toimage(omodel, 'synthesistoy_images/omodel'))) fail;
    if(tableexists('synthesistoy_images/model')) tabledelete('synthesistoy_images/model');
    include 'deconvolver.g';
    dec:=deconvolver('synthesistoy_images/dirty', 'synthesistoy_images/psf');
    dec.smooth(model='synthesistoy_images/omodel', image='synthesistoy_images/smodel',
	       normalize=F);
#
# Now call the appropriate deconvolution function
#
    if(private.inputs.algorithm=='clarkclean') {
      dec.clarkclean(model='synthesistoy_images/model', niter=10000);
    }
    else if(private.inputs.algorithm=='hogbomclean') {
      dec.clean(model='synthesistoy_images/model', niter=10000);
    }
    else if(private.inputs.algorithm=='msclean') {
      dec.setscales('uservector', uservector=[0, 3, 10, 30]);
      dec.clean(algorithm='msclean',
		model='synthesistoy_images/model', niter=300, gain=0.7);
    }
    else {
      dec.mem(model='synthesistoy_images/model', targetflux='1Jy',
	      sigma='0.001Jy',
	      niter=30);
    }
#
# Restore and return a record containing all the images
#
    dec.restore(model='synthesistoy_images/model', image='synthesistoy_images/cmodel');
    dec.done();
    rec := [=];
    rec := [model=private.fromimage('synthesistoy_images/model'),
	    cmodel=private.fromimage('synthesistoy_images/cmodel'),
	    smodel=private.fromimage('synthesistoy_images/smodel')];
    return rec;
  }
  
#
# Renormalize to the range [0,1]
#
  private.renorm := function(a) {
    maxa:=max(a); mina:=min(a);
    if(maxa==mina) return a;
    return (a-mina)/(maxa-mina);
  }
  
#
# Make a standard display panel in the frame f. We will later add the
# data to the display panel record so that the whenever can report the
# value as the cursor moves. There are better ways of doing this but this
# is quick and dirty!
#
  private.minidisplay := function(f) {
    wider private, public;
    dp := private.tools.viewer.newdisplaypanel(f, width=512, height=512);
    canvasoptions:=[rightmarginspacepg=0, leftmarginspacepg=0,
		    topmarginspacepg=0, bottommarginspacepg=0,
		    colortablesize=1024];
    dp.canvasmanager().setoptions(canvasoptions);
    finfo := widgetset.frame(f, side='top');
    tinfo := widgetset.label(finfo, '', fill='x', relief='flat',
			     width=30);
    whenever dp->motion do {
      if(!private.iambusy) {
	pix:=as_integer(as_float($value.world)+0.5);
	if(has_field(dp, 'data')) {
	  value := dp.data[pix[1], pix[2]];
	  tinfo->text(paste('Value ', value, ' at ', as_evalstr(pix)));
	}
	else {
	  tinfo->text(as_evalstr(pix));
	}
      }
    } private.pushwhenever();
    return dp;
  }
#
# Create a display data for a given array and load in on a 
# display panel, optionally renormalizing, etc. We attach
# the array to the display panel so that the cursor feedback
# can see it.
#
  private.adddd := function(ref dp, ref arr, renorm=T, color=T,
			    max=1.0, min=0.0) {
    wider private, public;
    dd := F;
    if(renorm) {
      dd := private.tools.viewer.loaddata(private.renorm(arr), 'raster');
    }
    else {
      dd := private.tools.viewer.loaddata(arr, 'raster');
    }
    if(is_fail(dd)) return throw('Failed to create display data ',
				 dd::message);
#
# Set up standard display options
#
    rasteroptions:=[pixeltreatment='bilinear', datamax=max, datamin=min];
    if(color) {
      rasteroptions.colormap:=private.inputs.colormap;
    }
    else {
      rasteroptions.colormap:='Greyscale 1';
    }
    dd.setoptions(rasteroptions);
    dp.register(dd);
    val dp.data := arr;
    return dd;
  }
# 
# Make all the changes needed when the antennas change
#
  private.refreshants := function() {
    wider private, public;
#
# Unregister existing display datas to make them invisible
#
    private.viewer.dpmask.unregister(private.viewer.ddmask);
    private.viewer.dppsf.unregister(private.viewer.ddpsf);
    private.viewer.dpdirty.unregister(private.viewer.dddirty);
    if(is_agent(private.viewer.ddmodel))
	private.viewer.dpmodel.unregister(private.viewer.ddmodel);
    if(is_agent(private.viewer.ddcmodel))
	private.viewer.dpcmodel.unregister(private.viewer.ddcmodel);
    if(is_agent(private.viewer.ddrmodel))
	private.viewer.dprmodel.unregister(private.viewer.ddrmodel);
    if(is_agent(private.viewer.ddfmodel))
	private.viewer.dpfmodel.unregister(private.viewer.ddfmodel);
#
# Calculate the uv coverage
#
    note('Calculating u,v coverage', origin='synthesistoy');
    if(is_fail(private.makemask())) {
      throw('Error in calculating u,v coverage: ', private.images.mask::message);
    }
    private.viewer.ddmask := private.adddd(private.viewer.dpmask,
					   private.images.mask, color=F);

#
# Now calculate the PSF using the fftserver. Note that we normalize
# appropriately and take the real part.
#    

    note('Calculating Point Spread Function',
	 origin='synthesistoy');
    private.images.psf:=private.images.nx*private.images.ny*complex(private.images.mask);
    private.tools.fft.complexfft(private.images.psf, dir=-1);
    if(is_fail(private.images.psf)) throw('Error in calculating psf: ',
				   private.images.psf::message);
    private.images.psf := real(private.images.psf);
    note('Max, min of PSF = ', max(private.images.psf), ', ', min(private.images.psf),
	 origin='synthesistoy');
    private.images.psfsub:=private.images.psf[private.images.xsub,private.images.ysub];
    private.viewer.ddpsf := private.adddd(private.viewer.dppsf, private.images.psfsub,
					renorm=F, max=0.1, min=-0.1, color=F);
#
# Convolve the model by the PSF to get the dirty image: since we already have 
# the FT of the PSF, we use that.
#
    note('Calculating Dirty Image', origin='synthesistoy');
    private.images.dirty:=
	private.images.nx*private.images.ny*complex(private.images.mask)*private.afft;
    private.tools.fft.complexfft(private.images.dirty, dir=-1);
    if(is_fail(private.images.dirty)) throw('Error in calculating b: ',
					    private.images.dirty::message);
    private.images.dirty:=real(private.images.dirty);
    private.images.dirtysub:=
	private.images.dirty[private.images.xsub,private.images.ysub];
    private.viewer.dddirty :=
	private.adddd(private.viewer.dpdirty, private.images.dirtysub);
    return T;
  }
# 
# Make all the changes needed after deconvolution
#
  private.refreshdeconv := function() {
    wider private, public;
#
# Unregister existing display datas to make them invisible
#
    if(is_agent(private.viewer.ddmodel))
	private.viewer.dpmodel.unregister(private.viewer.ddmodel);
    if(is_agent(private.viewer.ddcmodel))
	private.viewer.dpcmodel.unregister(private.viewer.ddcmodel);
    if(is_agent(private.viewer.ddrmodel))
	private.viewer.dprmodel.unregister(private.viewer.ddrmodel);
    if(is_agent(private.viewer.ddfmodel))
	private.viewer.dpfmodel.unregister(private.viewer.ddfmodel);
#
# Do the deconvolution
#
    note('Calculating deconvolution', origin='synthesistoy');
    result:=private.deconv(private.images.dirty, private.images.psf,
				  private.images.model);
    if(is_fail(result)) {
      throw('Error in deconvolving: ', result::message);
    }
#
# Now make the new display data and display them
#    
    private.images.dirtymodelsub :=result.model;
    private.images.bcmodelsub:=result.cmodel;
    private.images.brmodelsub:=(result.smodel-result.cmodel);
    private.images.bfmodelsub:=private.images.brmodelsub/result.smodel;
    private.images.bfmodelsub[abs(private.images.bfmodelsub)>1.0]:=0.0;
    private.images.smodelmax := max(result.smodel);
    private.images.smodelmin := min(result.smodel);
    private.images.rmodelmax := max(private.images.brmodelsub)
    private.images.rmodelmin := min(private.images.brmodelsub)
    
    private.viewer.ddmodel  := private.adddd(private.viewer.dpmodel,
					     private.images.dirtymodelsub);
    private.viewer.ddcmodel := private.adddd(private.viewer.dpcmodel,
					     private.images.bcmodelsub,
				      renorm=F,
				      max=private.images.smodelmax,
				      min=private.images.smodelmin);
    private.viewer.ddrmodel := private.adddd(private.viewer.dprmodel,
					     private.images.brmodelsub,
				      renorm=F,
				      max=private.images.rmodelmax,
				      min=private.images.rmodelmin);
    private.viewer.ddfmodel := private.adddd(private.viewer.dpfmodel,
					     private.images.bfmodelsub,
				      renorm=F, max=0.1, min=0.0);
    return T;
  }

#
# Get the inputs from the buttons: here we benefit from the consistent naming
# convention since we can do this in a loop.
#
  private.getinputs := function() {
    wider private, public;
    for (field in "arrayshape nants narms power sampling dec latitude harange hastep algorithm") {
      private.inputs[field] := private.buttons[field].get();
    }
    return T;
  }
#
# Make and populate the antenna chooser
#  
  private.makechooser := function() {
    wider private, public;
    include 'gchooser.g';
    indices := 1:len(private.ants.x);
    labels  := as_string(indices);
#
# Kill any old chooser
#
    if(is_record(private.tools.gchooser)) {
      private.deactivatewhenever('gchooser');
      private.tools.gchooser.done();
    }
    private.tools.gchooser := gchooser(private.frames.chooser,
				       labels=labels,
				       indices=indices,
				       x=private.ants.x, y=private.ants.y,
				       plottitle='Antenna locations',
				       xlabel='X (local)', ylabel='Y (local)',
				       width=300, height=300,
				       embedded=T,
				       widgetset=widgetset);
    if(is_fail(private.tools.gchooser))
	return throw('Failed to make antenna chooser ',
		     private.tools.gchooser::message);
    private.tools.gchooser.insert(indices);
    private.tools.gchooser.plot();
#
# Whenever to act on any change
#
    whenever private.tools.gchooser->values do {
      if(private.lock()) {
	valid := $value.selection;
	note('Selected antennas ', valid, origin='synthesistoy');
	private.ants.active := array(F, len(private.ants.x));
	private.ants.active[valid] := T;
	private.getinputs();
	private.refreshants();
	private.unlock();
      }
    } private.pushwhenever('gchooser');
    return T;
  }
#
# Big function to construct the entire GUI and set it up
#
  private.gui:= function() {
    wider private, public;

#
# Make top level frames
#
    widgetset.tk_hold();
    private.frames.top:=widgetset.frame(side='top',
					title='Convolution/Deconvolution demo (AIPS++)');
    private.frames.top->unmap();
    widgetset.tk_release();
    private.frames.both:=widgetset.frame(private.frames.top, side='left', relief='ridge');
    private.frames.left:=widgetset.frame(private.frames.both, side='top');
    private.frames.right:=widgetset.frame(private.frames.both, side='top');
    
    private.frames.antstop:=widgetset.frame(private.frames.left, side='top',
				      relief='ridge');
    private.frames.antsbottom:=widgetset.frame(private.frames.left, side='top',
					 relief='ridge');

#
# Use nice tabdialog for the images: this enables display of many different
# images
#
    include 'tabdialog.g';
    private.frames.images:=widgetset.frame(private.frames.right,side='top',
				     relief='ridge');
    private.tools.tabdialog:=tabdialog(private.frames.images, colmax=4, widgetset=widgetset);
    private.frames.imagestab:=private.tools.tabdialog.dialogframe();
    private.frames.control:=widgetset.frame(private.frames.images,side='left');
#
# Make the input widgets, including the antenna chooser
#
    private.frames.antinputs   := widgetset.frame(private.frames.antstop, side='top');
    private.frames.chooser     := widgetset.frame(private.frames.antstop, side='top');

    private.frames.arrayshape := widgetset.frame(private.frames.antinputs, side='left');
    private.labels.arrayshape := widgetset.label(private.frames.arrayshape, 'Array type');
    private.buttons.arrayshape := private.ge.choice(private.frames.arrayshape,
					     value=private.inputs.arrayshape,
					     default=private.inputs.arrayshape,
					     options=['random',
						      'star',
						      'circle',
						      'randomcircle']);
#
# Inputs for array generation
#
    private.frames.nants := widgetset.frame(private.frames.antinputs, side='left');
    private.labels.nants := widgetset.label(private.frames.nants, 'Number of antennas');
    private.buttons.nants := private.ge.scalar(private.frames.nants, value=private.inputs.nants, default=private.inputs.nants);
    private.labels.nants.shorthelp := 'Number of antennas in total';
    private.buttons.nants.shorthelp := private.labels.nants.shorthelp;
    private.buttons.nants.setwidth(10);
    
    private.frames.narms := widgetset.frame(private.frames.antinputs, side='left');
    private.labels.narms := widgetset.label(private.frames.narms, 'Number of arms (star only)');
    private.buttons.narms := private.ge.scalar(private.frames.narms, value=private.inputs.narms, default=private.inputs.narms);
    private.labels.narms.shorthelp := 'Number of arms (3 of Y, 5 for 5 pointed star, etc.)'
    private.buttons.narms.shorthelp := private.labels.narms.shorthelp;
    private.buttons.narms.setwidth(10);
    
    private.frames.power := widgetset.frame(private.frames.antinputs, side='left');
    private.labels.power := widgetset.label(private.frames.power, 'Power law along arms (star only)');
    private.buttons.power := private.ge.scalar(private.frames.power, value=private.inputs.power, default=private.inputs.power);
    private.labels.power.shorthelp := 'Power law for distribution of antennas along arm (radius is proportional to the antenna index along this arm raised to this power)';
    private.buttons.power.shorthelp := private.labels.power.shorthelp;
    private.buttons.power.setwidth(10);
    
#
# Inputs for uv generation
#
    private.frames.uvinputs     := widgetset.frame(private.frames.antsbottom, side='top');

    private.frames.dec := widgetset.frame(private.frames.uvinputs, side='left');
    private.labels.dec := widgetset.label(private.frames.dec, 'Source declination');
    private.buttons.dec := private.ge.quantity(private.frames.dec, value=private.inputs.dec,
					default=private.inputs.dec);
    private.buttons.dec.setwidth(10);
    private.labels.dec.shorthelp := 'Declination of source (quantity)';
    private.buttons.dec.shorthelp := private.labels.dec.shorthelp;
    
    private.frames.latitude := widgetset.frame(private.frames.uvinputs, side='left');
    private.labels.latitude := widgetset.label(private.frames.latitude, 'Telescope latitude');
    private.buttons.latitude := private.ge.quantity(private.frames.latitude, value=private.inputs.latitude, default=private.inputs.latitude);
    private.buttons.latitude.setwidth(10);
    private.labels.latitude.shorthelp := 'Latitude of telescope (quantity: default is for the VLA)';
    private.buttons.latitude.shorthelp := private.labels.latitude.shorthelp;
    
    private.frames.harange := widgetset.frame(private.frames.uvinputs, side='left');
    private.labels.harange := widgetset.label(private.frames.harange, 'Hour angle range');
    private.buttons.harange := private.ge.array(private.frames.harange, value=private.inputs.harange, default=private.inputs.harange);
    private.buttons.harange.setwidth(10);
    private.labels.harange.shorthelp := 'Range in Hour Angle to be sampled (hours)';
    private.buttons.harange.shorthelp := private.labels.harange.shorthelp;
    
    private.frames.hastep := widgetset.frame(private.frames.uvinputs, side='left');
    private.labels.hastep := widgetset.label(private.frames.hastep, 'Hour angle step');
    private.buttons.hastep := private.ge.scalar(private.frames.hastep, value=private.inputs.hastep, default=private.inputs.hastep);
    private.buttons.hastep.setwidth(10);
    private.labels.hastep.shorthelp := 'Step between integrations in Hour Angle (hours)';
    private.buttons.hastep.shorthelp := private.labels.hastep.shorthelp;
    
    private.frames.sampling := widgetset.frame(private.frames.uvinputs, side='left');
    private.labels.sampling := widgetset.label(private.frames.sampling, 'Zoom in u, v');
    private.buttons.sampling := private.ge.scalar(private.frames.sampling,
					   value=private.inputs.sampling,
					   default=private.inputs.sampling);
    private.buttons.sampling.setwidth(10);
    private.labels.sampling.shorthelp := 'The scale in u,v space: 1.0 sets the maximum baseline on the edge of the gridded plane';
    private.buttons.sampling.shorthelp := private.labels.sampling.shorthelp;
    
    private.makeants();
    private.makechooser();

    private.frames.makemask := widgetset.frame(private.frames.uvinputs, side='right');
    private.buttons.makemask := widgetset.button(private.frames.makemask,
						 'Make u,v coverage',
						 type='action');
    private.labels.makemask.shorthelp := 'Make the uv coverage for the current array design and observing parameters';
    private.buttons.makemask.shorthelp := private.labels.makemask.shorthelp;

#
# When these inputs change, update the array
#
    whenever private.buttons.arrayshape->value, private.buttons.nants->value,
	private.buttons.narms->value, private.buttons.power->value do {
      if(private.lock()) {
	note('Inputs have changed : updating array', origin='synthesistoy');
	private.getinputs();
	private.makeants();
	private.makechooser();
	private.unlock();
      }
    } private.pushwhenever();
#
# When thse inputs change, update the mask
#
    whenever private.buttons.dec->value, private.buttons.latitude->value,
	private.buttons.harange->value,  private.buttons.hastep->value, 
	    private.buttons.sampling->value, private.buttons.makemask->press do {
      if(private.lock()) {
	note('Inputs have changed : updating u,v coverage', origin='synthesistoy');
	private.getinputs();
	private.makemask();
	private.refreshants();
	private.unlock();
      }
    } private.pushwhenever();
#
# Inputs for deconvolution
#
    private.frames.algorithm := widgetset.frame(private.frames.control, side='left');
    private.labels.algorithm := widgetset.label(private.frames.algorithm, 'Deconvolution algorithm');
    private.buttons.algorithm := private.ge.choice(private.frames.algorithm, value=private.inputs.algorithm, default=private.inputs.algorithm,
					    options=['clarkclean', 'msclean', 'mem']);

    private.labels.algorithm.shorthelp := 'The deconvolution algorithm to be used to recover the source';
    private.buttons.algorithm.shorthelp := private.labels.algorithm.shorthelp;

    private.frames.before := widgetset.frame(private.frames.imagestab);
    private.frames.before->unmap();
    private.tools.tabdialog.add(private.frames.before, 'Model Image', hlp='Model image');
    private.frames.mask := widgetset.frame(private.frames.imagestab);
    private.frames.mask->unmap();
    private.tools.tabdialog.add(private.frames.mask, 'UV Sampling', hlp='Gridded u,v sampling');
    private.frames.psf := widgetset.frame(private.frames.imagestab);
    private.frames.psf->unmap();
    private.tools.tabdialog.add(private.frames.psf, 'Point Spread Function', hlp='Point Spread Function for gridded u,v data');
    private.frames.dirty := widgetset.frame(private.frames.imagestab);
    private.frames.dirty->unmap();
    private.tools.tabdialog.add(private.frames.dirty, 'Dirty image', hlp='Dirty image: inverse Fourier transform of gridded u,v data');
    private.frames.model := widgetset.frame(private.frames.imagestab);
    private.frames.model->unmap();
    private.tools.tabdialog.add(private.frames.model, 'Deconvolved image', hlp='Deconvolved image: full resolution estimate of the true sky');
    private.frames.cmodel := widgetset.frame(private.frames.imagestab);
    private.frames.cmodel->unmap();
    private.tools.tabdialog.add(private.frames.cmodel, 'Restored image', hlp='Restored image: smoothed estimate of the true sky plus residual image');
    private.frames.rmodel := widgetset.frame(private.frames.imagestab);
    private.frames.rmodel->unmap();
    private.tools.tabdialog.add(private.frames.rmodel, 'Deconvolution error', hlp='Deconvolution error: difference between smoothed original model and restored image');
    private.frames.fmodel := widgetset.frame(private.frames.imagestab);
    private.frames.fmodel->unmap();
    private.tools.tabdialog.add(private.frames.fmodel, 'Fractional error', hlp='Fractional error: Deconvolution error divided by smoothed model (truncated above 1)');
#
# Create the viewer that will control the various displays
#
    include 'viewer.g';
    private.tools.viewer:=viewer();
#
# Set up the various display panels
#
    private.viewer.dpbefore   := private.minidisplay(private.frames.before);
    private.viewer.dpmask     := private.minidisplay(private.frames.mask);
    private.viewer.dppsf      := private.minidisplay(private.frames.psf);
    private.viewer.dpdirty    := private.minidisplay(private.frames.dirty);
    private.viewer.dpmodel    := private.minidisplay(private.frames.model);
    private.viewer.dpcmodel   := private.minidisplay(private.frames.cmodel);
    private.viewer.dprmodel   := private.minidisplay(private.frames.rmodel);
    private.viewer.dpfmodel   := private.minidisplay(private.frames.fmodel);
#
# Define these so that the first time through Glish won't complain about
# defined variables
#    
    private.viewer.ddmodel:=F;
    private.viewer.ddcmodel:=F;
    private.viewer.ddrmodel:=F;
    private.viewer.ddfmodel:=F;
#
# Now make the various arrays and fill in the initial displays
#
    private.afft:=private.tools.fft.realtocomplexfft(private.images.dirty);
    private.makemask();
    private.images.psf:=private.images.nx*private.images.ny*complex(private.images.mask);
    private.tools.fft.complexfft(private.images.psf, dir=-1);
    private.images.psf := real(private.images.psf);
    note('Max, min of PSF = ', max(private.images.psf), ', ', min(private.images.psf),
	 origin='synthesistoy');
    private.images.psfsub:=private.images.psf[private.images.xsub,private.images.ysub];
    private.images.dirty:=private.images.nx*private.images.ny*complex(private.images.mask)*private.afft;
    private.tools.fft.complexfft(private.images.dirty, dir=-1);
    if(is_fail(private.images.dirty)) throw('Error in calculating b: ', private.images.dirty::message);
    private.images.dirty:=real(private.images.dirty);
    private.images.dirtysub:=private.images.dirty[private.images.xsub,private.images.ysub];
#
# Construct the display datas and display on the relevant display panel
#    
    private.viewer.ddbefore   := private.adddd(private.viewer.dpbefore,
					       private.images.modelsub);
    private.viewer.ddmask     := private.adddd(private.viewer.dpmask,
					       private.images.mask, color=F);
    private.viewer.ddpsf      := private.adddd(private.viewer.dppsf,
					       private.images.psfsub,
					       renorm=F, max=0.1, min=-0.1, color=F);
    private.viewer.dddirty    := private.adddd(private.viewer.dpdirty,
					       private.images.dirtysub);
    
#
# Update button
#
    private.frames.go := widgetset.frame(private.frames.control);
    private.buttons.go := widgetset.button(private.frames.go, 'Deconvolve', type='action');
    private.buttons.go.shorthelp := 'Deconvolve dirty image using specified algorithm';

    whenever private.buttons.go->press do {
      if(private.lock()) {
	note('Deconvolving', origin='synthesistoy');
	private.getinputs();
	private.makemask();
	private.refreshdeconv();
	private.unlock();
      }
    } private.pushwhenever();

#
# Done button
#
    private.frames.done := widgetset.frame(private.frames.control, side='right');
    private.buttons.done := widgetset.button(private.frames.done, 'Done', type='halt');
    private.buttons.done.shorthelp := 'Kill this tool and exit';
    whenever private.buttons.done->press do {
      public.done();
    } private.pushwhenever();

    widgetset.addpopuphelp(private.buttons);

    private.frames.top->map();

    indices := 1:len(private.ants.x);
    private.tools.gchooser.insert(indices);
    private.tools.gchooser.plot();

    return T;
  }
#
# Boilerplate needed for the AIPS++ tasking system
#
  public.type := function() {return "synthesistoy"};
  
#
# Clean up on exit: it's important to 'done' tools and to 
# kill frames, etc.
#
  public.done := function() {
    wider private, public;
    
    note('synthesistoy exiting', origin='synthesistoy');

    private.frames.top->unmap();

    for (tool in private.viewer) {
      if(has_field(tool, 'done')) tool.done();
    }

    for (tool in private.tools) {
      if(has_field(tool, 'done')) tool.done();
    }

    private.deactivatewhenever();
    private.deactivatewhenever('gchooser');

    for (f in private.frames) {
      if(is_agent(f)) f->unmap();
    }
    for (f in private.frames) {
      f:=F;
    }

    private := F;
    return T;
  }
#
# Cleanup nicely if the user just exits from Glish
#
  whenever system->exit do {
    public.done();
  } private.pushwhenever();
#
# Finally! We get the model and define the GUI
#
  if(is_fail(private.getmodel())) fail;

  private.gui();

#
# Return a reference to the public data so that the user can interact
# via the public functions (only done in this case).
#
  return ref public;
  
}
#
# Brain dead test
#
synthesistoytest := function() {
  st := synthesistoy();
}
