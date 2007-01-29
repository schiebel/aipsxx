# mosaicwizard.g: Make images from AIPS++ MeasurementSets the easy way
#
#   Copyright (C) 1996,1997,1998,1999,2000,2002
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
#   $Id: mosaicwizard.g,v 19.1 2004/08/25 01:20:50 cvsmgr Exp $
#

pragma include once   

include 'image.g';
include 'ms.g';
include 'table.g';
include 'note.g';
include 'widgetserver.g';
include 'imager.g';
include 'measures.g';
include 'os.g';
include 'wizard.g';
include 'viewer.g';

const 
mosaicwizardquickimage := subsequence(msname, widgetset=ddlws) {

  private := [=];

  private.widgetset := widgetset;

  private.whenevers := [=];
  private.pushwhenever := function() {
    wider private;
    private.whenevers[len(private.whenevers) + 1] := last_whenever_executed();
  }

  for (field in "wavelength maxbaseline antennadiameter cell targetflux scales") {
    private[field] := unset;
  }
  private.weighting := 'uniform';
  private.algorithm := 'mfmultiscale';
    private.mode := 'mfs'; 
  private.cyclefactor := 1.5;
  private.cyclespeedup := 100.0;
  private.fieldids := [1];
  private.nnscales := 4;
  private.scalemethod := 'nscales';
  private.uservector := [0, 3, 6];
  private.scale := 0.25;
  private.gain := 0.7;
  private.niter := 1000;
  private.doshift := F;
  private.phasecenter := dm.direction('j2000', '0deg', '0deg');
  private.deltax := dq.quantity(0.01, 'rad');  # x field of view
  private.deltay := dq.quantity(0.01, 'rad');  # y field of view
  private.delta  := dq.quantity(0.01, 'rad');  # what we are using (square), fov
  private.newdelta  := unset;
  private.double := 2.0;        # for small mosaics, need to double image size  
  private.mypg := F;
  private.constrainflux := F;
  private.priorimage := '';
  private.sigma := dq.quantity(0.001, 'Jy');
  private.targetflux := dq.quantity(1, 'Jy');
  private.displayprogress := T;
  private.supernyquist := 3.0;  # basically, cells per beam.
  private.nchannels := 1;	# for data
  private.maxnchannels := 1;	# for data
  private.startchannel := 1;	# for data
  private.stepchannel  := 1;	# for data
  private.imgnchannels := 1;	# for image
  private.imgstartchannel := 1;	# for image
  private.imgstepchannel  := 1;	# for image

# Useful output routines
const info := function(...) { note(...,origin='quickimage') }
const stop := function(...) { 
    return throw(paste(...) ,origin='quickimage')
  }
const gint := function(x) {
   if (x > 0) {
      return as_integer(x);
   } else if (x == 0) {
      return 0;
   } else {
      return (as_integer(x) - 1 );
   }
 }
const nint := function(x) {
      return (gint(x+0.5) );
 }

# helps format a number so we get cell sizes like 3.45 arcsec
const nicenumber := function(x, ndec=3) {
	sign := x / abs(x)
	x := abs(x);
	n := ndec -1 - gint(log(x));
	nn := 10^n;
	return ( sign * nint( x * nn ) / nn );
 }


# Ensure that the number of pixels is composite i.e. a power of
# 2, 3, and 5
const composite := function (target) {
    i:=1;
    comp:=array(0, 12*9*7);
    for (i2 in 1:12) {
      for (i3 in 0:8) {
        for (i5 in 0:6) {
          comp[i]:=2^i2 * 3^i3 * 5^i5
          i+:=1;
        }
      }
    }

    comp:=sort(comp);
    for (i in 1:(12*9*7)) {
      if(comp[i]>=target) return comp[i];
    }
    return target;
  }
# Does the MS exist?
  if(!tableexists(msname)) {
    stop ('MeasurementSet ', msname, ' does not exist');
  }

  # Create imager object
  private.ms:=msname;
  private.imager:=imager(msname);

  whenever self->kill do {
    private.imager.close();
    private.imager.done();
    deactivate;
  } private.pushwhenever;

  private.parametersset := F;
  private.memparametersset := F;
  private.mscparametersset := F;

const private.getvalues:=function(label='lastsave') {
    wider private;
    include 'inputsmanager.g';
    values := inputs.getvalues('mosaicwizard', 'mosaicwizard', label);
    if(is_record(values)) {
      for (field in "scale weighting niter algorithm") {
        if(has_field(values, field)) private[field] := values[field];
      }
    }
    return T;
  }

const private.checkimaginginputs:=function() {
    wider private;
    for (field in "scale weighting niter algorithm displayprogress") {
      if(is_unset(private[field])) {
        return throw(paste(field, 'is <unset>'));
      }
      if(is_fail(private[field])) {
        return throw(paste(field, 'is incorrect: ', private[field]::message));
      }
    }
    return T;
  }

const private.checkchannelinputs:=function() {
	for (field in "maxnchannels nchannels startchannel stepchannel imgnchannels imgstartchannel imgstepchannel") {
	  if(is_unset(private[field])) {
            return throw(paste(field, 'is <unset>'));
          }
	}
	if (((private.startchannel + private.stepchannel*(private.nchannels-1)) 
	    > private.maxnchannels) || (private.startchannel >  private.maxnchannels)) {
  	     return throw(paste('Data Channels run past the max: ', private.maxnchannels));
	}
	if (((private.startchannel + private.stepchannel*(private.nchannels-1)) 
	    < 1) || (private.startchannel<1)) {
  	     return throw(paste('Data Channels run below channel1'));
	}
	if (((private.imgstartchannel + private.imgstepchannel*(private.imgnchannels-1)) 
	    > private.maxnchannels) || (private.imgstartchannel >  private.maxnchannels)) {
  	     return throw(paste('Image Channels run past the max: ', private.maxnchannels));
	}
	if (((private.imgstartchannel + private.imgstepchannel*(private.imgnchannels-1)) 
	    < 1)  || (private.imgstartchannel<1))  {
  	     return throw(paste('Image Channels run below 1'));
	}
	return T;
}



const private.checkmeminputs:=function() {
    wider private;
    if (is_unset(private.priorimage)) {
	private.priorimage := '';
    }
    for (field in "targetflux constrainflux sigma") {
      if(is_unset(private[field])) {
        return throw(paste(field, 'is <unset>'));
      }
      if(is_fail(private[field])) {
        return throw(paste(field, 'is incorrect: ', private[field]::message));
      }
    }
    return T;
  }


const private.checkmscinputs:=function() {
    wider private;
    for (field in "scalemethod nnscales uservector") {
      if(is_unset(private[field])) {
        return throw(paste(field, 'is <unset>'));
      }
      if(is_fail(private[field])) {
        return throw(paste(field, 'is incorrect: ', private[field]::message));
      }
    }
    return T;
  }


const self.algorithm  := function () {
    wider private;
	return private.algorithm;
}


# phasecenter is a direction measure, length is a quantity (fov)
const self.updateparms := function (phasecenter=[=], length=[=]) {
   wider private;
   private.phasecenter := phasecenter;
   # don't permit updateparms to EXPAND the field of view beyond what calcdelta()
   # mandates
   if (dq.convert(length, 'deg').value < dq.convert(private.deltax, 'deg').value ||
       dq.convert(length, 'deg').value < dq.convert(private.deltay, 'deg').value) {
      private.newdelta := length;
   }
   return T;
}

const self.getdelta := function() {
	if (is_unset(private.newdelta)) {
		return ( private.delta );
	} else {
		return ( private.newdelta );
	}
}



const self.setimagingdefaults  := function (parent=F) {
    wider private;

    if(!has_field(private, 'fieldids')) private.fieldids := [1];
    if(!has_field(private, 'imagefieldid')) private.imagefieldid := 1;
    if(!has_field(private, 'ddid')) private.ddid := [1];      # data decsriptor id
    if(!has_field(private, 'spwid')) private.spwid := [1];      # spectral window for image
    if(!has_field(private, 'scale')) private.scale := 0.25;

    if(!is_agent(parent)) {
      parent := private.widgetset.frame(title='Imaging parameters for mosaicwizard');
    }

    private.widgets.parameters := [=];

#    private.getvalues();

#    private.widgets.parameters.cell :=
#	[dlformat='cell',
#	 listname='Cell size',
#         help='Cell size to use in calculating number of pixels',
#	 allowunset=T,
#	 ptype='quantity',
#	 default='1arcsec',
#	 value=private.cell];

    private.widgets.parameters.scale :=
	[dlformat='scale',
	 listname='(u,v) scaling parameter',
         help='Only image this inner fraction of the (u,v) plane',
	 ptype='scalar',
	 default='0.25',
	 value=private.scale];

    private.widgets.parameters.weighting :=
	[dlformat='weighting',
	 listname='Visibility weighting',
         help='Form of visibility weighting to be used',
	 ptype='choice',
	 popt="uniform natural",
	 default='uniform',
	 value=private.weighting];

    private.widgets.parameters.niter :=
	[dlformat='niter',
	 listname='Number of clean or mem iterations',
         help='Number of clean of mem iterations to use',
	 ptype='scalar',
	 default=1000,
	 value=private.niter];

    private.widgets.parameters.algorithm :=
	[dlformat='algorithm',
	 listname='Type of deconvolution',
         help='Type of deconvolution algorithm to use',
	 ptype='choice',
	 popt="mfclark mfhogbom mfmultiscale mfemptiness mfentropy",
	 default="mfmultiscale",
	 value=private.algorithm];

     private.widgets.parameters.mode :=
	[dlformat='mode',
	 listname='mode of imaging',
         help='which to make spectral channel images or mfs continuum',
	 ptype='choice',
	 popt="mfs channel",
	 default="mfs",
	 value=private.mode];
    private.widgets.parameters.displayprogress :=
	[dlformat='displayprogress',
	 listname='Display progress?',
         help='Pop up a plotter window and show algorithm progress',
	 ptype='boolean',
	 default='T',
	 value=private.displayprogress];

    
    private.widgetset.tk_hold();
    private.widgets.autogui :=
	autogui(toplevel=parent,
		title='Imaging parameters for mosaicwizard',
		params=private.widgets.parameters,
		autoapply=F, relief='flat', widgetset=private.widgetset);

    if(!is_agent(private.widgets.autogui)) {
      return throw(paste('Failure to construct autogui: ', private.widgets.autogui::message));
    }

    private.bottomleftframe := private.widgetset.frame(parent, side='left', expand='x');
    private.applybutton := private.widgetset.button(private.bottomleftframe, 'Apply',
					    type='action')
    private.savebutton := private.widgetset.button(private.bottomleftframe, 'Save');
    private.savebutton.shorthelp :=
	'Save inputs for current method to the specified area';
    private.getbutton := private.widgetset.button(private.bottomleftframe, 'Restore');
    private.getbutton.shorthelp :=
	'Restore inputs for current method from the specified area';
    private.dge := private.widgetset.guientry();
    private.inputsname := private.dge.string(private.bottomleftframe, 'lastsave');
    parent->cursor('left_ptr');
    parent->enable();
    private.widgetset.tk_release();
    
    # Save button
    whenever private.savebutton->press do {
      label :=  private.inputsname.get();
      if(label!='') {
	values := private.widgets.autogui.get();
	if(is_record(values)) {
	  include 'inputsmanager.g';
	  note(paste('Saving inputs to ', label));
	  inputs.savevalues('mosaicwizard', 'mosaicwizard', values, label, dosave=T);
	}
      }
    } private.pushwhenever;
    
    whenever private.getbutton->press do {
      label :=  private.inputsname.get();
      if(label!='') private.getvalues(label);
    } private.pushwhenever;

    await private.applybutton->press;
    values := private.widgets.autogui.get();
    include 'inputsmanager.g';
    inputs.savevalues('mosaicwizard', 'mosaicwizard', values, 'lastsave', dosave=T);

    private.scale := values.scale;
    private.weighting := values.weighting;
    private.niter := values.niter;
    private.algorithm := values.algorithm;
    private.mode := values.mode;
    private.displayprogress := values.displayprogress;

    self.setparameters();

    private.widgets.autogui.done();

    parent->unmap();

    return private.checkimaginginputs();
}


const self.setchannels  := function (parent=F, maxnchannels=1) {
    wider private;

    private.maxnchannels := maxnchannels;
    if(!has_field(private, 'nchannels')) private.nchannels := 1;
    if(!has_field(private, 'startchannel')) private.startchannel := 1;
    if(!has_field(private, 'stepchannel')) private.stepchannel := 1;
    if(!has_field(private, 'imgnchannels')) private.imgnchannels := 1;
    if(!has_field(private, 'imgstartchannel')) private.imgstartchannel := 1;
    if(!has_field(private, 'imgstepchannel')) private.imgstepchannel := 1;

    if(!is_agent(parent)) {
      parent := private.widgetset.frame(title='Specify Channels for Imaging');
    }
    private.widgets.parameters := [=];

    private.widgets.parameters.nchannels :=
	[dlformat='nchannels',
	 listname=paste('n data channels (max=', private.maxnchannels,')'),
         help='Select the number of data channels to image',
	 ptype='scalar',
	 default='1',
	 value=private.nchannels];

    private.widgets.parameters.startchannel :=
	[dlformat='startchannel',
	 listname=paste('start data channel (max=', private.maxnchannels,')'),
         help='Select first data channel to image',
	 ptype='scalar',
	 default='1',
	 value=private.startchannel];

    private.widgets.parameters.stepchannel :=
	[dlformat='stepchannel',
	 listname='step data channel',
         help='Select the number of data channels to step',
	 ptype='scalar',
	 default='1',
	 value=private.stepchannel];
    
    private.widgets.parameters.imgnchannels :=
	[dlformat='imgnchannels',
	 listname=paste('n image channels (max=', private.maxnchannels,')'),
         help='Select the number of channels in the image',
	 ptype='scalar',
	 default='1',
	 value=private.imgnchannels];

    private.widgets.parameters.imgstartchannel :=
	[dlformat='imgstartchannel',
	 listname=paste('start image channel (max=', private.maxnchannels,')'),
         help='Select first channel in the image',
	 ptype='scalar',
	 default='1',
	 value=private.imgstartchannel];

    private.widgets.parameters.imgstepchannel :=
	[dlformat='imgstepchannel',
	 listname='step image channel',
         help='Select the number of image channels to step',
	 ptype='scalar',
	 default='1',
	 value=private.imgstepchannel];

    private.widgetset.tk_hold();
    private.widgets.autogui :=
	autogui(toplevel=parent,
		title='Channel selection for mosaicwizard',
		params=private.widgets.parameters,
		autoapply=F, relief='flat', widgetset=private.widgetset);

    if(!is_agent(private.widgets.autogui)) {
      return throw(paste('Failure to construct autogui: ', private.widgets.autogui::message));
    }

    private.bottomleftframe := private.widgetset.frame(parent, side='left', expand='x');
    private.applybutton := private.widgetset.button(private.bottomleftframe, 'Apply',
					    type='action')
    private.savebutton := private.widgetset.button(private.bottomleftframe, 'Save');
    private.savebutton.shorthelp :=
	'Save inputs for current method to the specified area';
    private.getbutton := private.widgetset.button(private.bottomleftframe, 'Restore');
    private.getbutton.shorthelp :=
	'Restore inputs for current method from the specified area';
    private.dge := private.widgetset.guientry();
    private.inputsname := private.dge.string(private.bottomleftframe, 'lastsave');
    parent->cursor('left_ptr');
    parent->enable();
    private.widgetset.tk_release();
    
    # Save button
    whenever private.savebutton->press do {
      label :=  private.inputsname.get();
      if(label!='') {
	values := private.widgets.autogui.get();
	if(is_record(values)) {
	  include 'inputsmanager.g';
	  note(paste('Saving inputs to ', label));
	  inputs.savevalues('mosaicwizard', 'mosaicwizard', values, label, dosave=T);
	}
      }
    } private.pushwhenever;
    
    whenever private.getbutton->press do {
      label :=  private.inputsname.get();
      if(label!='') private.getvalues(label);
    } private.pushwhenever;

    await private.applybutton->press;
    values := private.widgets.autogui.get();
    include 'inputsmanager.g';
    inputs.savevalues('mosaicwizard', 'mosaicwizard', values, 'lastsave', dosave=T);

    private.nchannels := values.nchannels;
    private.startchannel := values.startchannel;
    private.stepchannel := values.stepchannel;
    private.imgnchannels := values.imgnchannels;
    private.imgstartchannel := values.imgstartchannel;
    private.imgstepchannel := values.imgstepchannel;

    private.widgets.autogui.done();

    parent->unmap();

    return private.checkchannelinputs();
}


const self.setmemdefaults  := function (parent=F) {
    wider private;

    if(!has_field(private, 'targetflux')) private.targetflux :=  dq.quantity(1.0, 'Jy');
    if(!has_field(private, 'constrainflux')) private.constrainflux := F;
#    if(!has_field(private, 'priorimage')) private.priorimage := '';
    if(!has_field(private, 'sigma')) private.sigma := dq.quantity(0.001, 'Jy');

    if(!is_agent(parent)) {
      parent := private.widgetset.frame(title='Mem control for mosaicwizard');
    }

    private.widgets.parameters := [=];

    private.widgets.parameters.targetflux :=
	[dlformat='targetflux',
	 listname='target flux',
         help='The starting flux for the MEM image (estimated from vis otherwise)',
	 ptype='quantity',
	 default='1.0Jy',
	 value=private.targetflux];

    private.widgets.parameters.constrainflux :=
	[dlformat='constrainflux',
	 listname='Constrain image flux to starting flux',
         help='Constrain image flux to starting flux',
	 ptype='boolean',
	 default='F',
	 value=private.constrainflux];

    private.widgets.parameters.priorimage :=
	[dlformat='priorimage',
	 listname='MEM prior image and Initial image',
         help='MEM biases the model to this prior',
	 ptype='string',
	 default='',
	 value=private.priorimage];

    private.widgets.parameters.sigma :=
	[dlformat='sigma',
	 listname='Image plane sigma',
         help='Image plane noise for MEM',
	 ptype='quantity',
	 default='0.001Jy',
	 value=private.sigma];
    
    private.widgetset.tk_hold();
    private.widgets.autogui :=
	autogui(toplevel=parent,
		title='Control parameters for mosaicwizard',
		params=private.widgets.parameters,
		autoapply=F, relief='flat', widgetset=private.widgetset);

    if(!is_agent(private.widgets.autogui)) {
      return throw(paste('Failure to construct autogui: ', private.widgets.autogui::message));
    }

    private.bottomleftframe := private.widgetset.frame(parent, side='left', expand='x');
    private.applybutton := private.widgetset.button(private.bottomleftframe, 'Apply',
					    type='action')
    private.savebutton := private.widgetset.button(private.bottomleftframe, 'Save');
    private.savebutton.shorthelp :=
	'Save inputs for current method to the specified area';
    private.getbutton := private.widgetset.button(private.bottomleftframe, 'Restore');
    private.getbutton.shorthelp :=
	'Restore inputs for current method from the specified area';
    private.dge := private.widgetset.guientry();
    private.inputsname := private.dge.string(private.bottomleftframe, 'lastsave');
    parent->cursor('left_ptr');
    parent->enable();
    private.widgetset.tk_release();
    
    # Save button
    whenever private.savebutton->press do {
      label :=  private.inputsname.get();
      if(label!='') {
	values := private.widgets.autogui.get();
	if(is_record(values)) {
	  include 'inputsmanager.g';
	  note(paste('Saving inputs to ', label));
	  inputs.savevalues('mosaicwizard', 'mosaicwizard', values, label, dosave=T);
	}
      }
    } private.pushwhenever;
    
    whenever private.getbutton->press do {
      label :=  private.inputsname.get();
      if(label!='') private.getvalues(label);
    } private.pushwhenever;

    await private.applybutton->press;
    values := private.widgets.autogui.get();
    include 'inputsmanager.g';
    inputs.savevalues('mosaicwizard', 'mosaicwizard', values, 'lastsave', dosave=T);

    private.targetflux := values.targetflux;
    private.constrainflux := values.constrainflux;
    private.priorimage := values.priorimage;
    private.sigma := values.sigma;

#    self.setmemparameters();    this doesn't do the right thing
#                                in getting the targetflux

    private.widgets.autogui.done();

    parent->unmap();

    return private.checkmeminputs();

}





const self.setmscdefaults  := function (parent=F) {
    wider private;

    if(!has_field(private, 'scalemethod')) private.scalemethod :=  'nscales';
    if(!has_field(private, 'nnscales')) private.nnscales := 4;
    if(!has_field(private, 'scales')) private.uservector := [0, 3, 6];

    if(!is_agent(parent)) {
      parent := private.widgetset.frame(title='Mem control for mosaicwizard');
    }

    private.widgets.parameters := [=];

    private.widgets.parameters.scalemethod :=
	[dlformat='scalemethod',
	 listname='method for setting scales',
         help='automatically set nscales, or supply a uservector?',
	 ptype='choice',
	 popt="nscales uservector",
	 default="nscales",
	 value=private.scalemethod];

    private.widgets.parameters.nnscales :=
	[dlformat='nnscales',
	 listname='how many scales?',
         help='number of scales for Multi Scale Clean',
	 ptype='scalar',
	 default='4',
	 value=private.nnscales];

    private.widgets.parameters.uservector :=
	[dlformat='uservector',
	 listname='vector of scale sizes', 
         help='supply a vector of scale sizes for Multi-Scale Clean',
	 ptype='vector',
	 default=[0,3,10],
	 value=private.uservector];
    
    private.widgetset.tk_hold();
    private.widgets.autogui :=
	autogui(toplevel=parent,
		title='Multi-Scale Clean Control parameters for mosaicwizard',
		params=private.widgets.parameters,
		autoapply=F, relief='flat', widgetset=private.widgetset);

    if(!is_agent(private.widgets.autogui)) {
      return throw(paste('Failure to construct autogui: ', private.widgets.autogui::message));
    }

    private.bottomleftframe := private.widgetset.frame(parent, side='left', expand='x');
    private.applybutton := private.widgetset.button(private.bottomleftframe, 'Apply',
					    type='action')
    private.savebutton := private.widgetset.button(private.bottomleftframe, 'Save');
    private.savebutton.shorthelp :=
	'Save inputs for current method to the specified area';
    private.getbutton := private.widgetset.button(private.bottomleftframe, 'Restore');
    private.getbutton.shorthelp :=
	'Restore inputs for current method from the specified area';
    private.dge := private.widgetset.guientry();
    private.inputsname := private.dge.string(private.bottomleftframe, 'lastsave');
    parent->cursor('left_ptr');
    parent->enable();
    private.widgetset.tk_release();
    
    # Save button
    whenever private.savebutton->press do {
      label :=  private.inputsname.get();
      if(label!='') {
	values := private.widgets.autogui.get();
	if(is_record(values)) {
	  include 'inputsmanager.g';
	  note(paste('Saving inputs to ', label));
	  inputs.savevalues('mosaicwizard', 'mosaicwizard', values, label, dosave=T);
	}
      }
    } private.pushwhenever;
    
    whenever private.getbutton->press do {
      label :=  private.inputsname.get();
      if(label!='') private.getvalues(label);
    } private.pushwhenever;

    await private.applybutton->press;
    values := private.widgets.autogui.get();
    include 'inputsmanager.g';
    inputs.savevalues('mosaicwizard', 'mosaicwizard', values, 'lastsave', dosave=T);

    private.scalemethod := values.scalemethod;
    private.nnscales := values.nnscales;
    private.uservector := values.uservector;

    self.setmscparameters();

    private.widgets.autogui.done();

    parent->unmap();

    return private.checkmscinputs();
  }


const self.setddid:=function(ddid) {
    wider private;
    if(is_integer(ddid)) {
      private.ddid:=ddid;
      private.spwid := self.getspwid( private.ms, private.ddid );
    }
    return T;
  }

const self.getspwid := function( msname, ddid ) {
  ddtab := table(spaste(msname, "/DATA_DESCRIPTION"));
  if(!is_table(ddtab)) fail 'Cannot open DATA_DESCRIPTION table';
  spwid := ddtab.getcol("SPECTRAL_WINDOW_ID");
  ddtab.done()
  selectedspwid := spwid[ddid] + 1;
  return selectedspwid;
}

const self.setfieldid:=function(fieldids) {
    wider private;
    if(is_integer(fieldids)) {
      private.fieldids:=fieldids;
    }
    return T;
  }

# get and show the fields
const self.showfields := function () {
    wider private;

    private.mypg := pgplotter();

    fieldtable := table( spaste(private.ms, '/FIELD'), ack=F);
    if(!is_table(fieldtable)) fail 'Cannot open FIELD table';
    fielddir := fieldtable.getcol('PHASE_DIR');
    pointingepoch := fieldtable.getcolkeyword('PHASE_DIR', 'MEASINFO').Ref;
    fieldtable.done();

    nfields := shape(fielddir)[3];
    fieldid := [1:nfields]
    x := [1:nfields];
    y := [1:nfields];

    rad2deg := 180/pi;
    rad2hours := rad2deg/15.0;
    for (i in [1:nfields]) {
      x[i] := fielddir[1,, i] * rad2hours;
      y[i] := fielddir[2,, i] * rad2deg;
    }
    flag := 0 * x;


    self.plotfields( x, y, flag, fieldid );

    note('Select fields: left click to include a pointing');
    note('Or, to remove a few pointings, just right click');
    note('middle click to stop');

    cursor := private.mypg.curs();
    while (cursor.ch != 'D') {
      dist2 := (x - cursor.x/3600)^2 + (y - cursor.y/3600.0)^2;
      i := sort_pair ( dist2, fieldid )[1];
      if (cursor.ch == 'A') {
	flag[i] := 1;
	note(paste('Including field', i));
      } else if (cursor.ch == 'X') {
	flag[i] := -1;
	note(paste('Excluding field', i));
      } else if (cursor.ch != 'D') {
	note(paste('Signal was not recognized as a mouse click'));
      }
      self.plotfields( x, y, flag, fieldid );
      cursor := private.mypg.curs();
    }

    fmax := max(flag);
    fmin := min(flag);
    if (fmax > 0 && fmin == 0) {
      private.fieldids := fieldid[ flag>0 ];
    } else if (fmax == 0 && fmin < 0) {
      private.fieldids := fieldid[ flag==0 ];
    } else if (fmax == 0 && fmin == 0) {
      private.fieldids := fieldid;
    } else {
      note('Chosen field IDs is confused, as you have both explicitly selected and');
      note('explicitly deselected some fields.  Please try the selection again!');
      private.mypg.done();
      return 'REPEAT';
    }

    xx := x[ private.fieldids ]/rad2hours;
    yy := y[ private.fieldids ]/rad2deg;
    dxx := ( max(xx) - min(xx) );
    axx := ( max(xx) + min(xx) )/2;

    dyy := ( max(yy) - min(yy) ) * cos(axx) ;
    ayy := ( max(yy) + min(yy) )/2;

    private.deltax := dq.quantity(dxx, 'rad');
    private.deltay := dq.quantity(dyy, 'rad');
    private.phasecenter := dm.direction(pointingepoch,
		       	[value=axx, unit='rad'],
			[value=ayy, unit='rad']);
    private.doshift := T;
    private.mypg.done();
    return T;
  }



# plot the fields:  flag can be -1 (red) 0 (white) or 1 (green)
# Note: x is in Hours, y is in Degrees
const  self.plotfields := function (x, y, flag, fieldid) {
    wider private;
	

    nfields := len(x);
    fmax := max (flag);
    fmin := min (flag);
    #  x0, y0 are only used to determine min and max for viewport
    #  (ie, so flagged outliers will not show up in the plot)
    x0 := [];
    y0 := [];
    if (fmax > 0 && fmin == 0) {  
# just take flag > 0   Ooops, this doesn't work,
# take all of them!
#      x0 := x[ flag > 0 ]
#      y0 := y[ flag > 0 ]
       x0 := x;
       y0 := y;
    } else if (fmax == 0 && fmin < 0) {
# just delete flag < 0
      x0 := x[ flag >= 0 ];
      y0 := y[ flag >= 0 ];
    } else if (fmax == 0 && fmin == 0) {
      x0 := x;
      y0 := y;
    } else {
      note ('State of plotfields flags is confused; taking all non-negatives');
      x0 := x[ flag >= 0 ];
      y0 := y[ flag >= 0 ];
    }
    xmin := min(x0);
    xmax := max(x0);
    ymin := min(y0);
    ymax := max(y0);
    dx := (xmax - xmin);
    dy := ymax - ymin;
    if (dx > 20) {
      note('Need to recode mosaicwizard to deal with RA=0 crossover');
    }
    if (dx == 0 && dy == 0) {
      dx := 1;
      dy := 1;
    }
    if (dx == 0) {
      dx := dy;
    }
    if (dy == 0) {
      dy := dx;
    }
    xmin -:= dx/8;
    xmax +:= dx/8;
    ymin -:= dy/8;
    ymax +:= dy/8;

    rad2deg := 180/pi;
    yaverad := (ymax + ymin)/2 / rad2deg;
    dy := (ymax - ymin)
    dx := (xmax - xmin)*15* cos(yaverad);
    a1 := 0.15;
    a9 := 0.85
    a91 := a9 - a1;
    if (dx > dy) {
      xleft := a1;
      xright := a9;
      ybot := a1 + a91 * ( 1 - dy/dx ) / 2;
      ytop := a9 - a91 * ( 1 - dy/dx ) / 2;
    } else {
      ybot := a1;
      ytop := a9;
      xleft := a1 + a91 * ( 1 - dx/dy ) / 2;
      xright := a9 - a91 * ( 1 - dx/dy ) / 2;
    }

    private.mypg.page();
#    private.mypg.save();
    private.mypg.sch(size=0.7);
    private.mypg.svp(xleft=xleft, xright=xright, ybot=ybot, ytop=ytop);
    # convert to seconds:
    xmin2 := xmin * 3600;
    xmax2 := xmax * 3600;
    ymin2 := ymin * 3600;
    ymax2 := ymax * 3600;
    x2 := x * 3600;
    y2 := y * 3600;
    private.mypg.swin(x1=xmax2, x2=xmin2, y1=ymin2, y2=ymax2);
    private.mypg.tbox(xopt='BCSTNZH', xtick=0, nxsub=0, yopt='BCSTNZD', ytick=0, nysub=0);
    private.mypg.lab(xlbl='RA', ylbl='DEC', toplbl='Fields Observed');
    if (nfields < 20)  {
      private.mypg.sch(size=1.3);
    } else if (nfields < 50) {
      private.mypg.sch(size=1.0);
    }
    for (i in [1:nfields]) {
      if (flag[i] == 0) {
	private.mypg.sci(1);
      } else if (flag[i] < 0) {
	private.mypg.sci(2);
      } else if (flag[i] > 0) {
	private.mypg.sci(3);
      }
      private.mypg.ptxt(x=x2[i], y=y2[i], angle=0, fjust=0.5, text=fieldid[i]);
    }
    private.mypg.sci(1);

    return T;
  }




# Get the antenna diameter in meters
const self.getantennadiameter := function() {
    wider private;
    if(is_unset(private.antennadiameter)) {
      at:=table(spaste(private.ms, '/ANTENNA'), ack=F);
      if(!is_table(at)) fail 'Cannot open ANTENNA table';
      ad:=at.getcol('DISH_DIAMETER');
      private.antennadiameter:=min(ad);
      private.antennadiameter := dq.quantity(min(ad), 'm');
      at.close();
    }
    info('   Antenna diameter = ', private.antennadiameter.value, 'meters');
    return T;
  }

# Get the wavelength for the spectral window
const self.getwavelength := function() {
    wider private;
    if(is_unset(private.wavelength)) {
      dt:=table(spaste(private.ms, '/DATA_DESCRIPTION'), ack=F);
      if(!is_table(dt)) fail 'Cannot open DATA_DESCRIPTION table';
      spid:=dt.getcol('SPECTRAL_WINDOW_ID');

      st:=table(spaste(private.ms, '/SPECTRAL_WINDOW'), ack=F);
      if(!is_table(st)) fail 'Cannot open SPECTRAL_WINDOW table';
      freq:=st.getcol('REF_FREQUENCY');
      st.close();

      private.wavelength:=dq.quantity((3.0E8/freq[spid[(min(private.ddid))]+1]), 'm')
    }
    info('   Wavelength = ', private.wavelength.value, ' meters');
    return T;
  }

# Get the maximum baseline in meters
const self.getmaxbaseline := function() {
    wider private;
    if(is_unset(private.maxbaseline)) {
      t:=table(spaste(private.ms), ack=F);
      if(!is_table(t)) fail 'Cannot open MeasurementSet';
      uvw:=t.getcol('UVW');
      private.maxbaseline:=dq.quantity(max(sqrt(uvw[1,]*uvw[1,]+uvw[2,]*uvw[2,])), 'm');
      t.close();
    }
    info('   Maximum baseline = ', private.maxbaseline.value, ' meters');
    return T;
  }





# Find the field of view required to image the whole primary
# beam and cell size 
# Note that since we keep changing the cell size, the number of pixels in the
# image is NOT fundamental; rather, we keep the FOV, full resolution cell size, 
# and the scaling factor; the image size gets calculated from all that!

const self.calcdelta := function() {
    wider private;

      private.cell := dq.quantity(dq.convert(private.wavelength, 'm').value/
				  ( private.supernyquist*
				  dq.convert(private.maxbaseline, 'm').value),'rad');
      sigfigs := 3;
      private.cell := dq.quantity( nicenumber(dq.convert(private.cell, 'arcsec').value, sigfigs), 'arcsec');

      # this is the margin required around each pointing (due to the PB):
      # essentially Half Width to Zero Intensity, about the same as FWHM
      pbhalfwidth := dq.quantity((dq.convert(private.wavelength, 'm').value / 
              dq.convert(private.antennadiameter, 'm').value), 'rad');

      # important fact: private.deltax, private.deltay, are the distance across the image to
      # extreme pointing centers;
      # BUT delta (and mydeltax, mydeltay) include the PB margin on both sides of deltax, deltay
      if (is_unset(private.deltax)) fail 'Have not specified the field of view';
      mydeltax := dq.add( private.deltax, dq.mul(pbhalfwidth, 2) );
      mydeltay := dq.add( private.deltay, dq.mul(pbhalfwidth, 2) );
      if (mydeltax.value > mydeltay.value) {
          private.delta :=  mydeltax;
      } else {
          private.delta :=  mydeltay;
      }

      # we need to double the image size if it is single pointing
      # but if its lots of pointings, we don't need to double it
      # because of the primary beam
      self.redefinedouble();

      # calculate the full resolution image size
      x := dq.convert(private.delta, 'rad').value / dq.convert(private.cell, 'rad').value;
      pixels := composite(as_integer(private.double*(x)));
      if(pixels<64) pixels:=64;


    info('Without masking, the full resolution image will have'); 
    info(pixels, ' pixels and ',  private.cell.value, ' arcsec cells');
    return T;
  }

# private.double may need to be redefined, based on 
# how self.getdelta() changes (ie, if you have a large mosaic -- which doesn't
# require doubling, and then zoom in to image just a small bright region, then you
# really do need image double for the PSF. 
const self.redefinedouble := function() {
      wider private;

      # number of pixels across the PB:    2 * lambda / D   / cellsize
      myscale := private.scale;
      mycell := dq.div(private.cell, myscale);
      pbfwzerointensity := dq.quantity((2 * dq.convert(private.wavelength, 'm').value / 
              dq.convert(private.antennadiameter, 'm').value), 'rad')
      pixelsacrossbeam := (dq.div( dq.convert( pbfwzerointensity, 'rad'),  
				    dq.convert( mycell, 'rad') )).value;
      pixelsacrossregion := (dq.div(dq.convert(self.getdelta(), 'rad'),
				    dq.convert( mycell, 'rad') )).value;
      if (pixelsacrossregion < pixelsacrossbeam) {
	  private.double := 2.0;
      } else if (pixelsacrossregion > (2*pixelsacrossbeam)) {
	  private.double := 1.05;
      } else {
	  private.double := 2*pixelsacrossbeam / pixelsacrossregion;
      }
      return T;
}

# Get all the parameters
const self.setparameters := function() {
    wider private;
    info('The parameters used are:');
    self.getantennadiameter();
    self.getwavelength();
    self.getmaxbaseline();
    self.calcdelta();
    private.parametersset := T;
    return private.parametersset;
  }


# Get all the MEM parameters
const self.setmemparameters := function() {
    wider private;
    info('The MEM parameters used are:');
    fudge := 1;
    if (!private.constrainflux) fudge := 10;
    self.gettargetflux(fudge);
    private.memparametersset := T;
    return private.memparametersset;
  }


# Get all the MEM parameters
const self.setmscparameters := function() {
    wider private;
    info('The MSC parameters used are:');
    info('    scalemethod = ', private.scalemethod);
    if (private.scalemethod == 'nscales') {
       info('    nscales = ', private.nnscales);
    } else {
       info('    uservector = ', private.uservector);
    }

    private.mscparametersset := T;
    return private.mscparametersset;
  }



# Estimate total flux in the image via visibility info
# Strategy: for each field, find the max vis amp;
# sum up for all fields, divide by 2.4 (if nfields > 2)
# Then, divide by "fudge" to permit the algorithm more
# leverage
const self.gettargetflux := function(fudge=10) {
    wider private;

    if (is_unset(private.ms)) fail 'No ms set in gettargetflux';
    if (is_unset(private.fieldids)) fail 'No fieldids set in gettargetflux';
    if (is_unset(private.ddid)) fail 'No spwid/pol set in gettargetflux';
    tab := table(private.ms, ack=F);

    flag0 := tab.getcol('FLAG')
    data0 := tab.getcol('DATA')
    field0 := tab.getcol('FIELD_ID')
    window0 := tab.getcol('DATA_DESC_ID')
    flag1 := flag0[1,,] || flag0[4,,]
    data1 := ( data0[1,, !flag1] + data0[4,, !flag1] )/2.0;
    field1 := field0[ !flag1 ];
    window1 := window0[ !flag1 ];
    tab.done();
    asum := 0.0;
    nsum := 0;
    for (f in private.fieldids) {
      data2 := data1[ field1==f ];
      window2 := window1[ field1==f ];
      data3 := data2[ window2==private.ddid ];
      asum +:= max(abs(data3));
      nsum +:= 1;
    }
    if (nsum > 2) asum /:= 2.4;
    if (is_double(asum) || is_float(asum)) {
      # divide by fudge to give the algorithm some teeth!
      private.targetflux := dq.quantity(asum/fudge, 'Jy');   
      info('        Estimated flux = ', asum, ' Jy');
      info('        Targetflux = ', private.targetflux.value, ' Jy');
      return T
    } else {
      fail 'Did not succefully estimate total mosaic flux';
    }
  }


#  this assumes we have a quantity in a record
#  return a quantity as a string (with quotes around it even!)
# - qq := dq.quantity(10, "arcmin");
# - answer := myevalstr(qq);
# - print answer;
# '10arcmin' 
const myevalstr := function(it=[=]) {
	answer := spaste( '\'', it.value, it.unit,  '\'');
	return answer;
}

# this one prints out a vector in form that can be input to glish again
# [1,2,3,4] instead of the normal [1 2 3 4] if you just print the vector
const myvecstr := function(it=[]) {
	if (len(it) == 0) {
	   return;
        } else if (len(it) == 1) {
	   return spaste('[', it[1], ']');
	} else {
	   answer := spaste('[', it[1]);
	   for (i in [2:len(it)]) {
		answer := spaste(answer, ',', it[i]);
	   }
	   answer := spaste(answer, ']');
	   return answer;
	}
}


# Clip an image so the min value is minval
const clipimage := function(imgname='', minval=0.0) {
	myimg := image(imgname)
	calcstring := spaste('iif(', imgname, ' > ', minval, ',', imgname, ',',minval, ')' );
	myimg.calc(calcstring);
	myimg.done();
	return T;
}


# Make in look like template, return as out
const makeitlooklike := function(outname='', inname='', template='', debug=F) {
  if (inname == outname) {
    note(paste('Trying to regrid onto the same image ', inname,
	'; no action taken'));
    return T;
  } else {
    imgin := image(inname);
    imgtemplate   := image(template);
    csys := imgtemplate.coordsys();
    imgnew   := imgin.regrid(outfile=outname, csys=csys,
              shape=imgtemplate.shape(), axes=[1,2]);

    ok := imgnew.done();
    ok := imgtemplate.done();
    ok := imgin.done();
    ok := csys.done();
    if (debug) {
      print (paste('Regridded ', inname, ' to size of ', outname));
      ok := note (paste('Regridded ', inname, ' to size of ', outname));
    }
    return T;
  }
}


const self.incrementscale := function() {
        wider private;
        private.scale := min( 2*private.scale, 1.0 );
        return T;
}

#  careful, there are no safety fixes here on what "alg" can be!
const self.suggestalgorithm := function(alg='mfclark') {
	wider private;
	private.algorithm := alg;
	return T;
}


# return value of the scale
const self.getscale := function() {
	return private.scale;
}


# Deconvolve an image. If scale is < 1 then only the inner fraction
# of the uv plane is imaged
#
# Write a more detailed description
#
# This returns in a string the code that was executed (roughly)
const self.deconvolveimage := function(name='image', previous='', mask='',
				    threshold=dq.quantity(0, 'Jy'),
				    ref writecode, ref restored, ref model) {
    wider private;
#
# Note that previous and mask will be regridded to the proper size
#
    private.cyclespeedup := private.niter/5;
    if (previous == '') {
        sln := 1;
    } else {
        sln := -1;
    }
    writecode('myimager.setmfcontrol(cyclespeedup=', private.cyclespeedup,
		', cyclefactor=',private.cyclefactor,
		', stoplargenegatives=',sln,
		', scaletype=\'SAULT\'',
		')');
    private.imager.setmfcontrol(cyclespeedup=private.cyclespeedup,
				cyclefactor=private.cyclefactor,
				stoplargenegatives=sln, scaletype="SAULT");

    myscale := private.scale;
    if(!private.parametersset) self.setparameters();

    val model:=spaste(name, '.scale', myscale, '.', private.algorithm);
    val restored:=spaste(model, '.restored');
    if(dos.fileexists(model)&&!tabledelete(model)) {
        return throw('Cannot delete existing model image');
    }
    if(dos.fileexists(restored)&&!tabledelete(restored)) {
        return throw('Cannot delete existing restored image');
    }
    sigfigs := 3;
    cell := dq.quantity( nicenumber(dq.convert(private.cell, 'arcsec').value/myscale, sigfigs), 'arcsec');

    self.redefinedouble();
    pixels0 := private.double * dq.convert(self.getdelta(), 'deg').value / 
	dq.convert(cell, 'deg').value;
    pixels:=max(128, composite(as_integer(pixels0)));

note(paste('This stage we will produce an image with npixels = ', pixels));
note(paste('and cell size = ',cell));

    if (len(private.ddid) == 1) {
         selectstring := spaste('DATA_DESC_ID == ', private.ddid[1]-1);
    } else {
         selectstring := spaste('DATA_DESC_ID in [', private.ddid[1]-1 );
         for (i in [2:len(private.ddid)]) {
	   selectstring := spaste(selectstring, ',', private.ddid[i]-1);
         }
         selectstring := spaste(selectstring, ']');
    }

    writecode('myimager.setdata(fieldid=', myvecstr(private.fieldids), 
		', msselect=\'',selectstring,'\'',
		',mode=\'channel\'',
		',nchan=',private.nchannels,
		',start=',private.startchannel,
		',step=',private.stepchannel,
		',async=F)');
    private.imager.setdata(fieldid=private.fieldids, msselect=selectstring, 
		mode='channel', nchan=private.nchannels,
		start=private.startchannel, step=private.stepchannel, async=F);

    if(private.doshift) {
        writecode('phasecenter:=dm.direction(', as_evalstr(private.phasecenter.refer), ',', 
			as_evalstr(private.phasecenter.m0),',', as_evalstr(private.phasecenter.m1), ')');
	writecode('myimager.setimage(nx=', pixels,', ny=',pixels,
		  ', cellx=', myevalstr(cell), ', celly=', myevalstr(cell),
		  ', phasecenter=phasecenter, doshift=', private.doshift,
		  ', stokes=\'I\', spwid=',private.spwid,
                  ', fieldid=', private.imagefieldid,
		  ',nchan=',private.imgnchannels,
		  ',start=',private.imgstartchannel,
		  ',step=',private.imgstepchannel,
		  ',mode=',private.mode,
		  ')');
	private.imager.setimage(nx=pixels, ny=pixels,
				cellx=cell, celly=cell,
				phasecenter=private.phasecenter, doshift=private.doshift,
				stokes='I', spwid=private.spwid, fieldid=private.imagefieldid,
				nchan=private.imgnchannels, start=private.imgstartchannel,
				step=private.imgstepchannel, mode=private.mode);
    } else {
	writecode('myimager.setimage(nx=', pixels,', ny=',pixels,
		  ', cellx=', myevalstr(cell), ', celly=', myevalstr(cell),
		  ', stokes=\'I\', spwid=', spwid, ', fieldid=',private.imagefieldid,
		  ',nchan=',private.imgnchannels,
		  ',start=',private.imgstartchannel,
		  ',step=',private.imgstepchannel,
		  ',mode=',private.mode,
		  ')');
	private.imager.setimage(nx=pixels, ny=pixels,
			     cellx=cell, celly=cell,
			     stokes='I', spwid=private.spwid, fieldid=private.imagefieldid,
			     nchan=private.imgnchannels, start=private.imgstartchannel,
			     step=private.imgstepchannel, mode=private.mode);
    }
    writecode('myimager.setoptions(padding=1.5)');
    private.imager.setoptions(padding=1.5);
    writecode('myimager.weight(type=', as_evalstr(private.weighting),', async=F)');
    private.imager.weight(type=private.weighting, async=F);
    writecode( 'myimager.uvrange(uvmin=0, uvmax=',
		   private.maxbaseline.value*myscale/private.wavelength.value, ', async=F)');

    private.imager.uvrange(uvmin=0, 
			  uvmax=private.maxbaseline.value*myscale/private.wavelength.value,
			   async=F);
    if (myscale < 1.0) {
       filter := dq.mul(cell, 2.5);
       writecode( 'myimager.filter(bmaj=',myevalstr(filter), ', bmin=', myevalstr(filter),')');
       private.imager.filter(bmaj=filter, bmin=filter);
    }
    
    writecode('myimager.setvp(dovp=T, usedefaultvp=T)');
    private.imager.setvp(dovp=T, usedefaultvp=T);
    writecode( 'myimager.summary()');
    private.imager.summary();

# regrid some images to the appropriate size
    memzero:=0.000001;
    newpriorimage := '';
    mymask := '';
    {
      if (tableexists('template.123')) { tabledelete('template.123'); }
      private.imager.make('template.123');
      if (mask != '') {
	mymask := spaste(model, '.scaledmask');
        if(dos.fileexists(mymask)&&!tabledelete(mymask)) {
           return throw(paste('Cannot delete existing mask image ',mymask));
        }
	makeitlooklike( mymask, mask, 'template.123');
      }
      if (previous != '' && private.algorithm != 'mfentropy' ) {
	makeitlooklike( model, previous, 'template.123');
        clipimage(model, 0.0);
        note(paste('### Regridding the previous model ', model, ' for initial model at higher resolution'));
        note('### (ie, expect lower residuals next time, and the deconvolved flux reported will just be');
	note('### an increment over the previous model -- and hence will be much smaller)');
      }
      if ((!is_unset(private.priorimage) && private.priorimage != '' ) && 
        (private.algorithm == 'mfentropy' || private.algorithm == 'mfemptiness') ) {
	if (!tableexists(private.priorimage)) {
	   note(paste('### Prior image ',private.priorimage, 'does not exist'));
	   newpriorimage := '';
        } else {
	   newpriorimage := spaste(private.priorimage, '.regridded'); 
	   makeitlooklike( newpriorimage, private.priorimage, 'template.123');
	   myimg := image(model)
	   calcstring := spaste('iif(', model, ' > 0.0, ', model, ', 0.0)' );
	   myimg.calc(calcstring);
	   myimg.done();
	   clipimage(newpriorimage, memzero);
        }
      }
      if ((is_unset(private.priorimage) || private.priorimage == '') && 
        (previous != '' && private.algorithm == 'mfentropy') ) {
# use the previous as a priorimage
        note(paste('Regridding the previous model ', model, ' for MEM prior at higher resolution'));
	newpriorimage := spaste(previous, '.regriddedprior'); 
	makeitlooklike( newpriorimage, previous, 'template.123');
        clipimage(newpriorimage, memzero);
      }
      if (tableexists('template.123')) { tabledelete('template.123'); }
    }  # done regridding

    if (private.algorithm == 'mfentropy' || private.algorithm == 'mfemptiness') {
      info(paste('Using', private.algorithm, 'to deconvolve image ', model));  
      tflux := private.targetflux;

      writecode('private.imager.mem(algorithm=', as_evalstr(private.algorithm), 
		', model=',as_evalstr(model), 
		', sigma=', as_evalstr(private.sigma),
		', niter=',private.niter,  
		', targetflux=', as_evalstr(tflux),
		', constrainflux=F, prior=', as_evalstr(newpriorimage), 
# doesnt work		', mask=', as_evalstr(mymask),
		', image=', as_evalstr(restored),
		', displayprogress=', private.displayprogress, 
		', async=F)');
      return  private.imager.mem(algorithm=private.algorithm, model=model, sigma=private.sigma,
				 niter=private.niter,  targetflux=tflux,
				 constrainflux=F, prior=newpriorimage, 
# doesnt work			 mask=mymask, 
				 image=restored, 
				 displayprogress=private.displayprogress, async=F);
    } else {
      gain := 0.1;
      if (private.algorithm == 'mfmultiscale') gain := 0.5;
      info('Cleaning image ', model);
      writecode('myimager.setscales(scalemethod=', as_evalstr(private.scalemethod), 
		', nscales=', private.nnscales,
		', uservector=', myvecstr(private.uservector), ')');
      private.imager.setscales(scalemethod=private.scalemethod, 
			       nscales=private.nnscales,
			       uservector=private.uservector);
      writecode('myimager.clean(algorithm=',as_evalstr(private.algorithm), 
		', model=',as_evalstr(model),
		', mask=', as_evalstr(mymask),
		', image=', as_evalstr(restored),
		', threshold=', as_evalstr(threshold), 
		', niter=', private.niter, 
		', gain=', gain,
		', displayprogress=',private.displayprogress, 
		',async=F)');
      return  private.imager.clean(algorithm=private.algorithm, model=model, 
				mask=mymask, image=restored, 
				threshold=threshold, niter=private.niter, 
				gain=gain, displayprogress=private.displayprogress, 
				async=F);
    }
}

const self.done := function() {
    wider private;
    if(has_field(private, 'whenevers')) deactivate private.whenevers;
    if(has_field(private, 'imager')&&has_field(private.imager, 'done')) {
      private.imager.close();
      private.imager.done();
    }
    return T;
  }


}

const strippath := function( name ) {
    if (is_string(name)) {
      tempname := name  ~ s@/@ @g
      tempname =~s/\s+/$$/g
      return (tempname[len(tempname)]);
    } else {
	return F;
    }
}   


mosaicwizard := function(writetoscripter=T, widgetset=ddlws)
{
    note('Starting mosaicwizard');

    private := [=];
    private.widgetset := widgetset;

    w := wizard('mosaicwizard', writetoscripter=writetoscripter, needviewer=T,
		widgetset=private.widgetset);

    if(is_fail(w)) {
      return throw(paste('Failed to create wizard', w::message));
    }
    w.writecode('# script written by mosaicwizard.g');
    w.writecode('include \'imager.g\'');

    private.stopnow := F;
    private.region := unset;

    private.whenevers := [=];
    private.pushwhenever := function() {
      wider private;
      private.whenevers[len(private.whenevers) + 1] := last_whenever_executed();
    }

    private.font     := '-*-courier-medium-r-normal--12-*';
    private.boldfont := '-*-courier-bold-r-normal--12-*';
    
    ##### Step 1 - get a valid MS and an initial image
    w.writestep('1. Select an AIPS++ MeasurementSet or UVFITS file');

    w.writeinfo(
' Mosaicwizard is an experimental code which will guide you through the ',
' process of making a mosaic image in AIPS++.  The scripting capabilities ',
' are currently incomplete, and we need to improve the way the mfentropy and ',
' mfemptiness algorithms are handled.',
' You must first select the input UV',
' data set to work with. You may start either from a UVFITS file, or from an',
' already formed AIPS++ MeasurementSet.  The default action is to use the',
' standard mosaicing test MeasurementSet (a 7-pointing 8GHz VLA observation of',
' CAS-A in VLA D-configuration).');

    private.widgetset.tk_hold();
    private.wholeworkframe := w.workframe(new=T, side='top');

    private.fileframe := private.widgetset.frame(private.wholeworkframe, side='left');
    private.filelabel := private.widgetset.label(private.fileframe,
					 'Measurement Set or FITS file');
    private.dge := private.widgetset.guientry();
    private.fileentry := private.dge.file(private.fileframe, value=unset,
					  default=unset, allowunset=T,
					  types=['Measurement Set']);


    private.widgetset.tk_release();

    fileok := F;
    while (!fileok) {
        w.enable();
        if (!w.waitfornext()) {
            w.done();
            return F; # Cancelled or some such
        }
	name := private.fileentry.get();
        w.disable();
        # Attempt to validate the file name.
        if(is_unset(name)) {
          name := 'mosaicwizard.ms';
	  private.fileentry.insert('mosaicwizard.ms');
	  w.writecode('imagermaketestmfms(\'mosaicwizard.ms\')');
	  w.writeerror('');
	  w.disable();
	  imagermaketestmfms('mosaicwizard.ms');
	  w.enable();
	}
	else if (name=='') {
	  w.writeerror('You must specify a file')
	  continue;
	}
        # Is it a table?
        if (tableexists(name)) {
            inputms := ms(name);
            if (!is_record(inputms)) {
                w.writeerror('Not a MeasurementSet!');
            } else {
                fileok := T;
            }
        } else {
            # Maybe it's a FITS file - try converting it to a MS
            if (!is_asciifile(name, bytes=2879)) {
                w.writeerror('MS Not a FITS file!');
                continue;
            }
            f := open(spaste('< ',name));
            header := read(f, num=2880, what='c');
            # Make sure it has SIMPLE=T
            ok := header ~ m/^SIMPLE *= *T/;
            if (!ok) {
                w.writeerror('MS Not a FITS file - no SIMPLE = T!');
                continue;
            }
            # Make sure it appears to be random groups
            ok := header ~ m/.*NAXIS1 *= *0/;
            if (!ok) {
                w.writeerror('Not a UVFITS file - NAXIS1 != 0!');
                continue;
            }

            out := spaste(name, '.ms');
            # Eliminate any .fits or .fts type extensions
            out ~:= s/\.fi*ts//g;
            out ~:= s/\.FI*TS//g;
            w.writecode( 'inputms := fitstoms(',as_evalstr(out),',',
			as_evalstr(name),')');
            inputms := fitstoms(out, name);
            if (!is_record(inputms)) {
                w.writeerror('MS FITS conversion failed!');
            } else {
                fileok := T;
            }
            # Now ensure that the ms name is set correctly
	    w.writecode( 'inputms.close()');
            name := out;
        }
        if (fileok) {
            # Make sure it indeed appears to be a MS.
            if (!tableexists(inputms.name()) || 
                !tableexists(spaste(inputms.name(), '/SPECTRAL_WINDOW'))) {
                w.writeerror('Not a MeasurementSet (no SPECTRAL_WINDOW table)');
                fileok := F;
            }
        }
    }

    w.enable();
    w.writeerror('');

    # Clear ourself, output of this section is inputms
    msname := inputms.name();
    inputms.close(); #### N.B., we close inputms. Use msname from here on out.
    inputms.done();
    titlename := strippath( name );



    ##### Step 2 - get a valid MS and an initial image
    w.writestep('2. Provide an initial model (optional)');

    w.writeinfo(
' Mosaicwizard\'s philosophy: it\'s fast to clean compact structure',
' but its slow to clean extended structure.  SO: we clean',
' image structure when it is still small by starting at low resolution',
' where the extended structure is fewer pixels across.  We use',
' the low resolution image as a starting model for higher resolution mosaics;',
' then we only have to deconvolve the details the low res model missed.',
' Similarly, you have the option to provide a starting model image, in Jy/pixel units.');

    private.widgetset.tk_hold();
    private.wholeworkframe := w.workframe(new=T, side='top');

    private.fileframe := private.widgetset.frame(private.wholeworkframe, side='left');
    private.filelabel := private.widgetset.label(private.fileframe,
					 'Optional Initial Model Image');
    private.dge := private.widgetset.guientry();
    private.fileentry := private.dge.file(private.fileframe, value=unset,
					  default=unset, allowunset=T,
					  types=['Image']);

    private.widgetset.tk_release();

#  now handle the preliminary image

    previousname := '';
    maskname := '';
    fileok := F;
    if (!w.waitfornext() ){
          w.done();
          return F; # Cancelled or some such
      }
    startingname := private.fileentry.get();
    if (!is_unset(startingname)) {
    while (!fileok) {
      if (!is_unset(startingname) && startingname != '') {
	 if (tableexists(startingname)) {
	    previousname := strippath( startingname );
            img := image(previousname);
            if (is_fail(img)) {
                w.writeerror(paste('File ',previousname,' is not an image'));
            } else {
	       if (img.bu() != 'Jy/pixel') {
                  w.writeerror(paste('Image does not have Jy/pixel brightness units'));
                  fileok := F;
               } else {
		  fileok := T;  #  we've got a good image for a starting model
                  note(paste('### Using initial starting model: ', previousname));
	       }
	    }
            img.done();
         } else {
            w.writeerror('Invalid image file name');
         }
      } else {
	fileok := T ;  #  we don't want a starting model
      }

      if (!fileok) {  # read it again!
        if (!w.waitfornext() ){
          w.done();
          return F; # Cancelled or some such
        }
        w.enable();
        startingname := private.fileentry.get();
        w.disable();
      }
    }
    }
    w.enable();
    w.writeerror('');


    ##### Step 3 - Select data

    private.widgetset.tk_hold();
    w.writestep(paste('3. Selection of spectral window from ', titlename));
    w.writeinfo('Select which spectral window you want to image.');
    private.filelabel := F; 
    private.fileentry.done();
    private.fileframe := F; 
    private.wholeworkframe := F;
    private.wholeworkframe := w.workframe(new=T);

    w.disable();

    ddtable := table(spaste(name, '/DATA_DESCRIPTION'), ack=F);
    if(!is_table(ddtable)) fail 'Cannot open DATA_DESCRIPTION table';
    polid := ddtable.getcol('POLARIZATION_ID');
    spwid := ddtable.getcol('SPECTRAL_WINDOW_ID');
    numdatadescriptors := len(polid);
    ddtable.close()

    sptable := table(spaste(name, '/SPECTRAL_WINDOW'), ack=F);
    if(!is_table(sptable)) fail 'Cannot open SPECTRAL_WINDOW table';
    freqghz := sptable.getcol('REF_FREQUENCY')/1.0e+9;
    resolution := sptable.getcol('RESOLUTION');
    sptable.close()

    poltable := table(spaste(name, '/POLARIZATION'), ack=F);
    if(!is_table(poltable)) fail 'Cannot open POLARIZATION table';
    numcorr := poltable.getcol('NUM_CORR');
    poltable.close()

    nchannels := [1:numdatadescriptors] * 0.0 + 1;
    subframe := [=];
    for (i in 1:numdatadescriptors) {
	pindex := (polid[i])+1;
	spindex :=(spwid[i])+1;
        subframe[i] := private.widgetset.frame(private.wholeworkframe, side='left',
				       expand='x');
        subframe[i].button :=
	    private.widgetset.button(subframe[i],spaste('Spectral Window ',i),
                                     type='check');
	if (i==1) {
           subframe[i].button->state(T);
	} else {
           subframe[i].button->state(F);
	}
        subframe[i].desc := private.widgetset.text(subframe[i], height=2, width=40,
					   disabled=T,
					   font=private.font);
        if(len(shape(resolution))==2) {
	  numchan := len(resolution[,spindex]);
          nchannels[i] := numchan;
	  string := spaste(numchan, ' ');
	  if (numchan == 1) {
            string := spaste(string, 'channel, ');
	  } else {
            string := spaste(string, 'channels, ');
	  }
	}
	else {
          string := 'Spectral shape unknown, '
	}
        if(is_numeric(numcorr)) {
	  numpol := numcorr[pindex];
	  string := spaste(string, numpol);
	  if (numpol == 1) {
            string := spaste(string, ' polarization, ');
	  } else {
            string := spaste(string, ' polarizations, ');
	  }
	}
	else {
	  string := spaste(string, 'Polarizations unknown, ');
	}

        if(is_numeric(freqghz)) {
	  string := spaste(string, 'ref frequency=', freqghz[spindex], 'GHz, width=');
	  if(len(shape(resolution))==2) {
	    res := sum(resolution[,spindex]);
	    if (res > 1.0e+9) {
	      string := spaste(string, res / 1.0e+9, 'GHz');
	    } else if (res > 1.0e+6) {
	      string := spaste(string, res / 1.0e+6, 'MHz');
	    } else if (res > 1.0e+3) {
	      string := spaste(string, res / 1.0e+3, 'kHz');
	    } else {
	      string := spaste(string, res / 1.0, 'Hz');
	    }
	  }
	  else {
            string := spaste(string, 'Bandwidth unknown');
	  }
	}
	else {
	  string := spaste(string, 'Frequencies unknown.');
	}
                         
        subframe[i].desc->insert(string, 'start');
    }
    private.widgetset.tk_release();
    w.enable();

    done := F;
    ddids := array(F, numdatadescriptors);
    possibleddids := 1:numdatadescriptors;
    while (!done) {
        if (!w.waitfornext()) {
            w.done();
            return F;
        }
        ddids := array(F, numdatadescriptors);
        for (i in 1:numdatadescriptors) {
            ddids[i] := subframe[i].button->state();
        }
        done := any(ddids);
        if (!done) {
            w.writeerror('You must select some data!');
        }
    }
    
    subframe := F;

    qi := mosaicwizardquickimage(msname, widgetset=private.widgetset);
    qi.setddid(possibleddids[ddids]);

    ##### Step 3a - Select Channels

    nlines := 0
    maxnchannels := 1;
    for (idd in 1:numdatadescriptors) {
       if (ddids[idd]) {
         numchan := nchannels[idd];
         if (numchan > 1) nlines := nlines + 1;
         maxnchannels := max(maxnchannels, numchan);
       }
    }

    if (nlines > 1) {
      w.writeerror('I\'m confused!  Only one line spectral window, please!');
    } else if (nlines ==1) {
  
      private.widgetset.tk_hold();
      w.writestep('3a. Spectral line data: set channels');
      w.writeinfo('Specify the channels you want to image');
      private.filelabel := F; 
      private.fileframe := F; 
      private.wholeworkframe := F;
      private.wholeworkframe := w.workframe(new=T);
  
      w.disable();
  
      subframe := [=];
      private.widgetset.tk_release();

      confused := 0;
      while (is_fail(qi.setchannels(private.wholeworkframe, maxnchannels))) {
          confused := confused + 1;
          if (confused >= 3) {
             deactivate private.whenevers;
             qi.done();
             w.done();
	  }
          return F;
          w.message('Channel settings were invalid, please try again!');
      }

      w.enable();
      w.message('Please press Next to continue');
      if (!w.waitfornext()) {
         deactivate private.whenevers;
         qi.done();
         w.done();
         return F;
      }
    } 
  

    ##### Step 4 - field ids
    private.widgetset.tk_hold();
    w.writestep(paste('4. Selection of fields from ', titlename));
    w.writeinfo(
	'There are three modes to select which fields you want to image:   ',
	' 1. To select ALL pointings, just exit by clicking the MIDDLE mouse button',
	' 2. If there are just a few fields you wish to LEAVE IN, click on those',
	' fields with the LEFT mouse button.  To exit selection, MIDDLE click.',
	' 3. If there are just a few fields you wish to REJECT, click on those',
	' fields with the RIGHT mouse button.  To exit selection, MIDDLE click.');
    w.disable();
    private.wholeworkframe := F;
    private.wholeworkframe := w.workframe(new=T);

    private.widgetset.tk_release();
    w.enable();

    successful := F;

    w.message('Starting imager...');
    w.writecode('myimager:=imager(', as_evalstr(msname), ')');

    w.message('Middle click to exit selection...');
    dorepeat := qi.showfields();
    while (dorepeat == 'REPEAT') {
    w.writeinfo(
	'You have confused me!  Don\'t click both the LEFT and the RIGHT buttons!',
	'  RIGHT clicks to REJECT (all others accepted) or LEFT clicks to LEAVE IN',
	'  MIDDLE click to exit. '
	);
	 dorepeat:=qi.showfields();
    }

#    print 'required enhancement: make nice print out of accepted fields';

    imgname:=spaste(titlename, '.MOSAIC', '.spw',
		      as_string(possibleddids[ddids]));

    imgname~:=s/ //g;
    imgname~:=s/\[//g;
    imgname~:=s/\]//g;

    # Clear ourself, output of this section is ddids (array (T/F)) of spectral
    # window selections. We pass this onto quickimage when we create it.
    w.writeerror('');

    round := 0
    step := 4;
    while (qi.getscale() < 1.0) {
       round := round + 1;
       step := step + 1;
       ##### Step 5 - Set imaging parameters
       private.widgetset.tk_hold();
       stepstring := spaste(step, '. Set deconvolution parameters');
       w.writestep(stepstring);
       if (round == 1) { 
           w.writeinfo('Next we will make a low resolution mosaic of the selected fields. ',
   		'First you will be given the opportunity to change the imaging parameters. ',
   		'The (u,v) scaling parameter determines the resolution. ',
   		'We will use this low resolution image as a model for higher ',
		'resolution imaging in future stages.  We stop when the scaling is 1. ',
   		'Press the Apply button when you have finished setting parameter.');
       } else {
           w.writeinfo('Next we will make an intermediate resolution mosaic of the selected fields. ',
   		'Again, you can change the imaging parameters. ',
   		'The (u,v) scaling parameter determines the resolution, and by default, ',
 		'will be double its value in the previous stage of deconvolution. ',
   		'We will use this intermediate resolution image as a model for higher ',
		'resolution imaging in the next stage.  (We stop when the scaling is 1.) ',
   		'Press the Apply button when you have finished setting parameter.');
          qi.incrementscale();  
       }
#       if (round == 2) {
#   	   qi.suggestalgorithm('mfclark');
#       }
 
       w.disable();
       subframe := F;
   
       private.wholeworkframe := F;
       private.wholeworkframe := w.workframe(new=T);
       private.widgetset.tk_release();
       w.message('Please set imaging parameters and press the Apply button');
   
       if(is_fail(qi.setimagingdefaults(private.wholeworkframe))) fail;
       w.enable();
   
       w.message('Please press Next to continue');
       if (!w.waitfornext()) {
         deactivate private.whenevers;
         qi.done();
         w.done();
         return F;
       }
   
       algorithm := qi.algorithm();
       if (algorithm == "mfentropy" ||algorithm == "mfemptiness" )  {
   
         ##### Step 5a - Set MEM parameters
         private.widgetset.tk_hold();
         stepstring := spaste(step, 'a. Set MEM parameters');
         w.writestep(stepstring);
	 if (algorithm == "mfentropy") {
                w.writeinfo('MEM will benefit from additional parameters.  ',
   		'Press the Apply button when you have finished setting parameters.');
         } else {
                w.writeinfo('Maximum Emptiness will benefit from additional parameters. ',
   		'Press the Apply button when you have finished setting parameters.');
         }
         w.disable();
         subframe := F;
   
         private.wholeworkframe := F;
         private.wholeworkframe := w.workframe(new=T);
         private.widgetset.tk_release();
         w.message('Please set imaging parameters and press the Apply button');
   
         if(is_fail(qi.setmemdefaults(private.wholeworkframe))) fail;
         w.enable();
   
         w.message('Please press Next to continue');
         if (!w.waitfornext()) {
           deactivate private.whenevers;
           qi.done();
           w.done();
           return F;
         }
       }  else if (algorithm == "mfmultiscale") {
   
         ##### Step 5a - Set Multi-Scale Clean parameters
         private.widgetset.tk_hold();
         stepstring := spaste(step, 'a. Set Multi-Scale Clean parameters');
         w.writestep(stepstring);
         w.writeinfo('Multi-Scale Clean will benefit from additional parameters.  ',
   		'Press the Apply button when you have finished setting parameters.');
         w.disable();
         subframe := F;
   
         private.wholeworkframe := F;
         private.wholeworkframe := w.workframe(new=T);
         private.widgetset.tk_release();
         w.message('Please set imaging parameters and press the Apply button');
         if(is_fail(qi.setmscdefaults(private.wholeworkframe))) fail;
         w.enable();
   
         w.message('Please press Next to continue');
         if (!w.waitfornext()) {
           deactivate private.whenevers;
           qi.done();
           w.done();
           return F;
         }
       }
   
   
       step := step + 1;
       if (qi.getscale() < 1.0) {

          ##### Step 6 - Initial inspection
          private.widgetset.tk_hold();
          if (round == 1) {
             w.writestep( spaste(step, '. Initial imaging and display') );
             w.writeinfo('We are currently making a low resolution mosaic. ',
                'When the viewer displays the resulting image, please ',
      		'select a region to be the area imaged in the next step. To select ',
      		'a region, right-click at the left display border on either the R-box ',
      		'or R-polygon. To make a box region, right click and drag the outline. ',
      		'To make a polygon, right click on the vertices. Once the region is ',
      		'complete, double-right-click within the region.  (It may take a few ',
		'tries before the mask region has been confirmed below.)');
          } else {
             w.writestep( spaste(step, '. Intermediate imaging and display') );
             if (algorithm == "mfentropy" ||algorithm == "mfemptiness" )  {
                w.writeinfo('We are currently making a higher resolution mosaic. ',
                'When the viewer displays the resulting image, please ',
      		'select a region to be the area imaged in the next step. PLEASE NOTE ',
		'that mfentropy and mfemptiness algorithms don\'t yet use the mask ',
		'image or the previous image as a model');
             } else {
                w.writeinfo('We are currently making a higher resolution mosaic. ',
                'When the viewer displays the resulting image, please ',
      		'select a region to be the area imaged in the next step. To select ',
      		'a region, right-click at the left display border on either the R-box ',
      		'or R-polygon. To make a box region, right click and drag the outline. ',
      		'To make a polygon, right click on the vertices. Once the region is ',
      		'complete, double-right-click within the region.  (It may take a few ',
		'tries before the mask region has been confirmed below.)');
             }
          }
      
          w.disable();
          private.wholeworkframe := F;
          private.wholeworkframe := w.workframe(new=T);
          private.widgetset.tk_release();
      
          if (round==1) {
              w.message('Imaging and deconvolving low resolution mosaic...');
          } else {      
              w.message('Imaging and deconvolving intermediate resolution mosaic...');
          }

          # default: do a 1/4 (ie, 1/16 the pixels) resolution scaling
          # maximum baseline. Arbitrarily use 1000 iterations
          # to clear away brightest sources
      
          restored:=''; model:='';
          result := qi.deconvolveimage(name=imgname,  
      				previous=previousname, 
				mask=maskname,
      				writecode=w.writecode,
      			        restored=restored, model=model);
          previousname := model;
          if(is_fail(result)) {
            deactivate private.whenevers;
            qi.done();
            w.done();
            return throw(paste('imager failed to create restored image', restored, result::message));
          }
          w.message(spaste('Stage ', round, ' of mosaicing has finished'));

          if(!tableexists(restored)) {
            deactivate private.whenevers;
            qi.done();
            w.done();
            return throw(paste('imager failed to create restored image', restored));
          }
      
          # Now display the image
          w.writecode('include \'image.g\'');
          myim := image(restored);
          w.writecode('myim:=image(',as_evalstr(restored),')');
          if(!is_image(myim)) {
            qi.done();
            w.done();
            return throw(paste('Failed to open image ', restored));
          }
          
          maskname := '';
          w.message('Displaying image. Use Adjust button to control display');
          result := myim.view(parent=private.wholeworkframe, raster=T, widgetset=private.widgetset);
          if(is_boolean(result)&&result) {
            w.message('Please define a rectangular or polygonal region to be cleaned at higher resolution');
            whenever myim->region do {
               w.message('Received region definition from the viewer');
               private.region := $value.region;
               if(is_region(private.region)) {
      	          maskname := spaste(restored, '.mask');
                  if(dos.fileexists(maskname)&&!tabledelete(maskname)) {
                     return throw(paste('Cannot delete existing mask image', maskname));
                  }
      	          dc.copy(restored, maskname);
      	          local pixels, pixelmask;
      	          mymask := image(maskname);
      	          mymask.set(pixels=0.0);
      	          mymask.getregion(pixels, pixelmask, private.region);
      	          pixels[pixelmask] := 1.0;
   	          mymask.putregion(pixels=pixels, region=private.region);
	          mymask.done();
                  w.message('Mask has been created: proceed by pressing Next');
               } else {
                  w.message('Region is invalid: please try again');
               }
            } private.pushwhenever();
          } else  if(is_fail(result)) {
             w.message('Failed to start viewer: ', result::message, ' proceeding');
          }  else if (!result || !is_boolean(result) ){
             w.message('Failed to start viewer, proceeding');
          }
          w.enable();
          w.message(paste('Current image is ',restored));
          if (!w.waitfornext()) {
            deactivate private.whenevers;
            if(is_image(myim)) {
      	      myim.close();
      	      myim.done();
            }
            qi.done();
            w.done();
            note('mosaicwizard cancelled', origin='mosaicwizard');
            return F;
          }
   
          csys := myim.coordsys();
          incr := csys.increment(format='q');
          ok := csys.done();
#
          mycellx := dq.abs(incr[1]);
          mycelly := dq.abs(incr[2]);
          mylength := dq.mul( mycellx, 64 );  # default length
          # If we have a valid region then find the bounding box
          if(is_region(private.region)) {
            bb := myim.boundingbox(region=private.region);
            if(!is_fail(bb)) {
              xmin := bb.blc[1];
              ymin := bb.blc[2];
              xmax := bb.trc[1];
              ymax := bb.trc[2];
              ## The phasecenter is in the middle
              x0 := (xmax + xmin)/2;
              y0 := (ymax + ymin)/2;
              w.writecode('x0 := (xmax + xmin)/2;');
              w.writecode('y0 := (ymax + ymin)/2;');
              
              # OK, what is the phasecenter?
              w.writecode('phasecenter := myim.coordmeasures([x0, y0]).direction');
              phasecenter := myim.coordmeasures([x0, y0]).direction;
      
      	      mylengthx := dq.mul( mycellx, (xmax - xmin) );
      	      mylengthy := dq.mul( mycelly, (ymax - ymin) );
      	      mylength  := mylengthx;
      	      if (mylengthx.value < mylengthy.value) {
      	         mylength  := mylengthy;
   	      }
              qi.updateparms(phasecenter, mylength)
            }
          } 
   
          imshape:=myim.shape();
          region1 := drm.box([1,1,imshape[3],1], imshape);
          w.writecode('region1 := drm.box([1,1,',imshape[3],',1], ',
            as_evalstr(imshape),')');
          stats:=[=];
          w.writecode('myim.statistics(statsout=stats, axes=[1,2,4], region=region1, async=F)');
          myim.statistics(statsout=stats, axes=[1,2,4], region=region1, async=F);
          w.writecode('myim.close()');
          myim.close();
          myim.done();
      
          w.message('');      
     
       }  # end of "if (qi.getscale() < 1.0)"
    }  # end of "while (qi.getscale() < 1.0) "

#   perform the final deconvolution
    step := step + 1;
    #### 7 - Make the final image
    stepstring := spaste(step, '. Final imaging and cleaning');
    w.writestep(stepstring);
    w.writeinfo('Make, deconvolve, and view the final mosaic image. ');
    w.message('Deconvolving full resolution mosaic...');

    w.disable();
    w.laststep();
    private.widgetset.tk_hold();
    private.wholeworkframe := F;
    private.wholeworkframe := w.workframe(new=T);
    private.widgetset.tk_release();

    restored:='';model:='';
    result := qi.deconvolveimage(name=imgname, previous=previousname,
				mask=maskname,
			    	writecode=w.writecode, 
				restored=restored, model=model);
    if(is_fail(result)) {
      deactivate private.whenevers;
      qi.done();
      w.done();
      return throw(paste('imager failed to create final restored image',
			 restored, result::message));
    }

    w.enable();
    w.message(paste('Full field restored image is ',restored));

    w.message('Imaging and deconvolution has finished');

    if(!tableexists(restored)) {
      deactivate private.whenevers;
      qi.done();
      w.done();
      return throw(paste('imager failed to create full field restored image', restored));
    }

    myim := image(restored); 
    if(!is_image(myim)) {
      deactivate private.whenevers;
      qi.done();
      w.done();
      return throw(paste('Failed to open image ', restored));
    }
    w.message('Please press Finish after viewing final image');
    result := myim.view(parent=private.wholeworkframe, raster=T, widgetset=private.widgetset);
    more := w.waitfornext();
    myim.close();
    myim.done();

    if (!more) {
      w.writecode('myimager.done()');
      w.writecode('# end of script written by mosaicwizard.g');
      deactivate private.whenevers;
      qi.done();
      w.done();
      return F;
    }
    
#    w.writecode('myimager.done()');
#    w.writecode('# end of script written by mosaicwizard.g');
#    w.message('That\'s it!');
    deactivate private.whenevers;
    qi.done();
    w.done();
    return T;
}

