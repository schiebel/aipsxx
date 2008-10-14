# imagerwizard.g: Make images from AIPS++ MeasurementSets the easy way
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2003
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
#   $Id: imagerwizard.g,v 19.2 2004/08/25 01:20:35 cvsmgr Exp $
#

pragma include once

include 'image.g';
include 'ms.g';
include 'table.g';
include 'note.g';
include 'widgetserver.g';
include 'imager.g';
include 'measures.g';
include 'quanta.g';
include 'os.g';
include 'wizard.g';
include 'viewer.g';

const imagerwizardquickimage := subsequence(msname, widgetset=ddlws) {

  private := [=];

  private.widgetset := widgetset;

  private.whenevers := [=];
  private.pushwhenever := function() {
    wider private;
    private.whenevers[len(private.whenevers) + 1] := last_whenever_executed();
  }

  for (field in "pixels wavelength antennadiameter maxbaseline cell") {
    private[field] := unset;
  }
  private.weighting := 'uniform';
  private.algorithm := 'clark';
  private.niter := 1000;
  private.stokes := 'IV';
  private.doshift := F;
  private.phasecenter := dm.direction('j2000', '0deg', '0deg');

# Useful output routines
  const info := function(...) { note(...,origin='quickimage') }
  const stop := function(...) { 
    return throw(paste(...) ,origin='quickimage')
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

  const private.getvalues:=function(label='lastsave') {
    wider private;
    include 'inputsmanager.g';
    values := inputs.getvalues('imagerwizard', 'imagerwizard', label);
    if(is_record(values)) {
      for (field in "pixels wavelength antennadiameter maxbaseline cell niter stokes algorithm") {
        if(has_field(values, field)) private[field] := values[field];
      }
    }
    return T;
  }

  const private.checkinputs:=function() {
    wider private;
    for (field in "pixels wavelength antennadiameter maxbaseline cell doshift phasecenter niter stokes algorithm") {
      if(is_unset(private[field])) {
        return throw(paste(field, 'is <unset>'));
      }
      if(is_fail(private[field])) {
        return throw(paste(field, 'is incorrect: ', private[field]::message));
      }
    }
    return T;
  }

  const self.setdefaults  := function (parent=F) {
    wider private;
    if(!has_field(private, 'fieldid')) private.fieldid := 1;
    if(!has_field(private, 'imagefieldid')) private.imagefieldid := 1;
    if(!has_field(private, 'ddid')) private.ddid := [1];      # data decsriptor id
    if(!has_field(private, 'spwid')) private.spwid := 1;

    if(!is_agent(parent)) {
      parent := private.widgetset.frame(title='Control for imagerwizard');
    }

    private.widgets.parameters := [=];

#    private.getvalues();

    private.widgets.parameters.cell :=
	[dlformat='cell',
	 listname='Cell size',
         help='Cell size to use in calculating number of pixels',
	 allowunset=T,
	 ptype='quantity',
	 default='1arcsec',
	 value=private.cell];

    private.widgets.parameters.antennadiameter :=
	[dlformat='antennadiameter',
	 listname='Antenna diameter',
         help='Antenna diameter to use in calculating field of view',
	 allowunset=T,
	 ptype='quantity',
	 default='25m',
	 value=private.antennadiameter];

    private.widgets.parameters.wavelength :=
	[dlformat='wavelength',
	 listname='Wavelength',
         help='Wavelength',
	 allowunset=T,
	 ptype='quantity',
	 default='0.21m',
	 value=private.wavelength];

    private.widgets.parameters.maxbaseline :=
	[dlformat='maxbaseline',
	 listname='Maximum baseline',
         help='Maximum baseline to use in calculating resolution',
	 allowunset=T,
	 ptype='quantity',
	 default='25m',
	 value=private.maxbaseline];

    private.widgets.parameters.pixels :=
	[dlformat='pixels',
	 listname='Number of pixels',
         help='Number of pixels to use in initial image',
	 allowunset=T,
	 ptype='scalar',
	 default=128,
	 value=private.pixels];

    private.widgets.parameters.weighting :=
	[dlformat='weighting',
	 listname='Visibility weighting',
         help='Form of visibility weighting to be used',
	 ptype='choice',
	 popt="uniform natural",
	 default='uniform',
	 value=private.weighting];
    
    private.widgets.parameters.stokes :=
	[dlformat='stokes',
	 listname='Stokes',
         help='Which Stokes images to make (I or IV or IQU or IQUV)',
	 ptype='choice',
         popt= "I IV IQU IQUV",
	 default='IV',
	 value=private.stokes];

    private.widgets.parameters.niter :=
	[dlformat='niter',
	 listname='Number of clean iterations',
         help='Number of clean algorithms to use',
	 ptype='scalar',
	 default=10000,
	 value=private.niter];
        
    private.widgets.parameters.algorithm :=
	[dlformat='algorithm',
	 listname='Type of clean algorithm',
         help='Type of clean algorithm to use',
	 ptype='choice',
	 popt="clark hogbom mf",
	 default="clark",
	 value=private.algorithm];
    
    private.widgets.parameters.imagefieldid :=
	[dlformat='imagefieldid',
	 listname='Field id for phase center',
	 help='Field id to use for defining the phase center',
	 ptype='choice',
	 popt=split(as_string(private.fieldid)),
	 default=as_string(min(private.fieldid)),
	 value=as_string(min(private.fieldid))];
    
    private.widgetset.tk_hold();
    private.widgets.autogui :=
	autogui(toplevel=parent,
		title='Control parameters for imagerwizard',
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
	  inputs.savevalues('imagerwizard', 'imagerwizard', values, label, dosave=T);
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
    inputs.savevalues('imagerwizard', 'imagerwizard', values, 'lastsave', dosave=T);

    private.pixels := values.pixels;
    private.antennadiameter := values.antennadiameter;
    private.wavelength := values.wavelength;
    private.cell := values.cell;
    private.maxbaseline := values.maxbaseline;
    private.weighting := values.weighting;
    private.niter := values.niter;
    private.stokes := values.stokes;
    private.algorithm := values.algorithm;
    private.imagefieldid := as_integer(values.imagefieldid);

    self.setparameters();

    private.widgets.autogui.done();

    parent->unmap();

    return private.checkinputs();
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


  const self.setfieldid:=function(fieldid) {
    wider private;
    if(is_integer(fieldid)) {
      private.fieldid:=fieldid;
    }
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
    info('   Antenna diameter = ', dq.getvalue(private.antennadiameter), 'meters');
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
    info('   Wavelength = ', dq.getvalue(private.wavelength), ' meters');
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
    info('   Maximum baseline = ', dq.getvalue(private.maxbaseline), ' meters');
    return T;
  }

# Find the field of view required to image the whole primary
# beam. Find the corresponding number of pixels and cell size 
  const self.getpixels := function() {
    wider private;
    if(is_unset(private.pixels)) {
      x := dq.getvalue(private.maxbaseline) / dq.getvalue(private.antennadiameter);
      private.pixels := composite(2*as_integer(x+1));
      if(private.pixels<128) private.pixels:=64;
      private.cell := dq.quantity(dq.getvalue(private.wavelength)/(3*dq.getvalue(private.maxbaseline)),
			       'rad');
      private.cell := dq.convert(private.cell, 'arcsec');
    }
    info('Cellsize = ', dq.getvalue(private.cell), ' arcsec');
    info('Pixels   = ', private.pixels);
    return T;
  }

  const self.setparms := function(phasecenter, nx)
  {
      wider private;
      private.doshift:=T;
      private.phasecenter := phasecenter;
      private.pixels := composite(nx + 1);
  }

# Get all the parameters
  const self.setparameters := function() {
    wider private;
    info('The parameters used are:');
    self.getantennadiameter();
    self.getwavelength();
    self.getmaxbaseline();
    self.getpixels();
    private.parametersset := T;
    return private.parametersset;
  }


#  this assumes we have a quantity in a record
#  return a quantity as a string (with quotes around it even!)
# - qq := dq.quantity(10, "arcmin");
# - answer := myevalstr(qq);
# - print answer;
# '10arcmin' 
const myevalstr := function(it=[=]) {
	answer := spaste( '\'', dq.getvalue(it), dq.getunit(it),  '\'');
	return answer;
}


# Clean an image. If scale is < 1 then only the inner fraction
# of the uv plane is cleaned.
# 1. Set the number of pixels and cellsize
# 2. Weight the data
# 3. Set a uv range
# 4. Clean
# 5. Restore
#
# This returns in a string the code that was executed (roughly)
  const self.cleanimage := function(name='image',scale=1.0, 
				    threshold=dq.quantity(0, 'Jy'),
				    ref writecode, ref restored) {
    wider private;

    if(!private.parametersset) self.setparameters();

    if(scale<1.0) {
      model:=spaste(name, '.scale=',scale);
      val restored:=spaste(name, '.scale=',scale, '.restored');
      if(dos.fileexists(model)&&!tabledelete(model)) {
        return throw('Cannot delete existing model image');
      }
      if(dos.fileexists(restored)&&!tabledelete(restored)) {
        return throw('Cannot delete existing restored image');
      }
      cell:=dq.quantity(dq.getvalue(private.cell)/scale, dq.getunit(private.cell));
      pixels:=max(128, composite(as_integer(private.pixels*scale)));

      if (len(private.ddid) == 1) {
         selectstring := spaste('DATA_DESC_ID == ', private.ddid[1]-1);
      } else {
         selectstring := spaste('DATA_DESC_ID in [', private.ddid[1]-1 );
         for (i in [2:len(private.ddid)]) {
	   selectstring := spaste(selectstring, ',', private.ddid[i]-1);
         }
         selectstring := spaste(selectstring, ']');
      }

      writecode('myimager.setdata(fieldid=', private.fieldid, ', msselect=\'',selectstring,
		'\', async=F)');
      private.imager.setdata(fieldid=private.fieldid, msselect=selectstring, async=F);

      if(private.doshift) {
	writecode('myimager.setimage(nx=', pixels,', ny=',pixels,
		  ', cellx=', myevalstr(cell), ', celly=', myevalstr(cell),
		  ', phasecenter=phasecenter, doshift=', private.doshift,
		  ', stokes=\'',private.stokes, '\', spwid=',private.spwid,
		  ', fieldid=', private.imagefieldid,')');
	private.imager.setimage(nx=pixels, ny=pixels,
				cellx=cell, celly=cell,
				phasecenter=private.phasecenter, doshift=private.doshift,
				stokes=private.stokes, spwid=private.spwid, fieldid=private.imagefieldid);
      }
      else {
	writecode('myimager.setimage(nx=', pixels,', ny=',pixels,
		  ', cellx=', myevalstr(cell), ', celly=', myevalstr(cell),
		  ', stokes=\'',private.stokes, '\', spwid=',private.spwid, ', fieldid=',private.imagefieldid,')');
	private.imager.setimage(nx=pixels, ny=pixels,
			     cellx=cell, celly=cell,
			     stokes=private.stokes, spwid=private.spwid, fieldid=private.imagefieldid);
      }
      writecode('myimager.weight(type=', as_evalstr(private.weighting),', async=F)');
      private.imager.weight(type=private.weighting, async=F);
      writecode( 'myimager.uvrange(uvmin=0, uvmax=',
		   dq.getvalue(private.maxbaseline)*scale/dq.getvalue(private.wavelength), ', async=F)');
      private.imager.uvrange(uvmin=0, uvmax=dq.getvalue(private.maxbaseline)*scale/dq.getvalue(private.wavelength),
                       async=F);
    }
    else {
      model:=name;
      val restored:=spaste(name, '.restored');
      if(dos.fileexists(model)&&!tabledelete(model)) {
        return throw('Cannot delete existing model image');
      }
      if(dos.fileexists(restored)&&!tabledelete(restored)) {
        return throw('Cannot delete existing restored image');
      }
      cell:=private.cell;
      pixels:=max(128, composite(as_integer(private.pixels)));
      if(private.doshift) {
	writecode('myimager.setimage(nx=', pixels,', ny=',pixels,
		  ', cellx=', myevalstr(cell), ', celly=', myevalstr(cell),
		  ', phasecenter=phasecenter, doshift=', private.doshift,
		  ', stokes=\'',private.stokes,  '\', spwid=',private.spwid, ', fieldid=',private.imagefieldid,')');
	private.imager.setimage(nx=private.pixels, ny=private.pixels,
			     cellx=private.cell, celly=private.cell,
			     phasecenter=private.phasecenter, doshift=private.doshift,
			     stokes=private.stokes, spwid=private.spwid, fieldid=private.imagefieldid);
      }
      else {
	writecode('myimager.setimage(nx=', pixels,', ny=',pixels,
		  ', cellx=', myevalstr(cell), ', celly=', myevalstr(cell),
		  ', stokes=\'',private.stokes, '\', spwid=',private.spwid, ', fieldid=',private.imagefieldid,')');
	private.imager.setimage(nx=private.pixels, ny=private.pixels,
			     cellx=private.cell, celly=private.cell,
			     stokes= private.stokes, spwid=private.spwid, fieldid=private.imagefieldid);
      }
      writecode('myimager.weight(type=', as_evalstr(private.weighting),', async=F)');
      private.imager.weight(type=private.weighting, async=F);
      writecode( 'myimager.uvrange(uvmin=0, uvmax=',
		dq.getvalue(private.maxbaseline)*scale/dq.getvalue(private.wavelength), ', async=F)');
      private.imager.uvrange(uvmin=0,
			  uvmax=dq.getvalue(private.maxbaseline)*scale/dq.getvalue(private.wavelength),
			  async=F);
    }
    writecode( 'myimager.summary()');
    private.imager.summary();

    info('Cleaning image ', model);

    writecode('myimager.clean(algorithm=', as_evalstr(private.algorithm), ', model=', as_evalstr(model),
	      ', image=', as_evalstr(restored),
	      ', threshold=', as_evalstr(threshold), ', niter=', private.niter, ', async=F)');
    return  private.imager.clean(algorithm=private.algorithm, model=model, threshold=threshold,
				 niter=private.niter,
				 image=restored, async=F);
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

imagerwizard := function(writetoscripter=T, widgetset=ddlws)
{
    note('Starting imagerwizard');

    private := [=];
    private.widgetset := widgetset;

    w := wizard('imagerwizard', writetoscripter=writetoscripter, needviewer=T,
		widgetset=private.widgetset);

    if(is_fail(w)) {
      return throw(paste('Failed to create wizard', w::message));
    }
    w.writecode('# script written by imagerwizard.g');

    private.stopnow := F;
    private.fullregion := unset;

    private.whenevers := [=];
    private.pushwhenever := function() {
      wider private;
      private.whenevers[len(private.whenevers) + 1] := last_whenever_executed();
    }

    private.font     := '-*-courier-medium-r-normal--12-*';
    private.boldfont := '-*-courier-bold-r-normal--12-*';
    
    ##### Step 1 - get a valid MS
    w.writestep('1. Select an AIPS++ MeasurementSet or UVFITS file');

    w.writeinfo(
'Imagerwizard makes a cleaned image of a selected region of the primary beam. ',
'It is recommended for ATCA, BIMA, WSRT, or for D, C, B configurations of the VLA. ',
'First you must select the input UV data set to work with. You may start either',
' from a UVFITS file, or from an already formed AIPS++ MeasurementSet.',
' The default action is to use the standard test MeasurementSet (an 8GHz',
' VLA observation of 3C273 in VLA C-configuration).');

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
          name := 'imagerwizard.ms';
	  private.fileentry.insert('imagerwizard.ms');
	  w.writecode('imagermaketestms(\'imagerwizard.ms\')');
	  w.writeerror('');
	  w.disable();
	  imagermaketestms('imagerwizard.ms');
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
                w.writeerror('Not a FITS file!');
                continue;
            }
            f := open(spaste('< ',name));
            header := read(f, num=2880, what='c');
            # Make sure it has SIMPLE=T
            ok := header ~ m/^SIMPLE *= *T/;
            if (!ok) {
                w.writeerror('Not a FITS file - no SIMPLE = T!');
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
                w.writeerror('FITS conversion failed!');
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

    ##### Step 2 - Select data
    private.widgetset.tk_hold();
    w.writestep('2. Selection of spectral windows from ', name);
    w.writeinfo('Select which spectral windows you want to image.');
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
    ##### Step 3 - field ids
    private.widgetset.tk_hold();
    w.writestep('3. Selection of fields from ', name);
    w.writeinfo('Select which fields you want to image.');
    w.disable();
    private.wholeworkframe := F;
    private.wholeworkframe := w.workframe(new=T);

    fieldtable := table(spaste(name, '/FIELD'), ack=F);
    if(!is_table(fieldtable)) fail 'Cannot open FIELD table';
    fieldnames := fieldtable.getcol('NAME');
    phasedirs := fieldtable.getcol('PHASE_DIR');
    phaseepoch := fieldtable.getcolkeyword('PHASE_DIR', 'MEASINFO').Ref;
#    phaseunit := fieldtable.getcolkeyword('PHASE_DIR', 'QuantumUnits');
    phaseunit := 'rad';
    fieldtable.close();
    numfields := len(fieldnames);

    subframe := [=];
    for (i in 1:numfields) {
        subframe[i] := private.widgetset.frame(private.wholeworkframe, side='left', expand='x');
        subframe[i].button := private.widgetset.button(subframe[i], spaste('Field ',i),
                                     type='check');
        subframe[i].button->state(i==1);
        subframe[i].desc := private.widgetset.text(subframe[i], height=2, width=40, disabled=T,
				 font=private.font);
	dmeasure:=dm.direction(phaseepoch,
			       [value=phasedirs[1,,i], unit=phaseunit],
			       [value=phasedirs[2,,i], unit=phaseunit]);
        if(is_measure(dmeasure)) {
	  string := paste(fieldnames[i], ': ', phaseepoch,
			  dq.angle(dmeasure.m0, prec=7, form='tim'),
			  dq.angle(dmeasure.m1, prec=7));
	  subframe[i].desc->insert(string, 'start');
	}
	else {
	  subframe[i].desc->insert(fieldnames[i], 'start');
	}
    }
    private.widgetset.tk_release();
    w.enable();

    done := F;
    fieldids := array(F, numfields);
    possiblefields := 1:numfields;
    while (!done) {
        if (!w.waitfornext()) {
            w.done();
            return F;
        }
        fieldids := array(F, numfields);
        for (i in 1:numfields) {
            fieldids[i] := subframe[i].button->state();
        }
        done := any(fieldids);
        if (!done) {
            w.writeerror('You must select one field');
            done := F;
        }
        if (done>1) {
            w.writeerror('You must select only one field!');
            done := F;
        }
    }
    
    if(dos.isvalidpathname(fieldnames[possiblefields[fieldids]])) {
      fieldname:=spaste(fieldnames[possiblefields[fieldids]], '.spw=',
			as_string(possibleddids[ddids]));
    }
    else {
      fieldname:=spaste(msname, '.fieldid=', as_string(fieldids), '.spw=',
			as_string(possibleddids[ddids]));
    }
    fieldname~:=s/ //g;
    fieldname~:=s/\[//g;
    fieldname~:=s/\]//g;

    # Clear ourself, output of this section is spids (array (T/F) of spectral
    # window selections. We pass this onto quickimage when we create it.
    w.writeerror('');

    ##### Step 4 - Set imaging parameters
    private.widgetset.tk_hold();
    w.writestep('4. Set initial parameters');
    w.writeinfo('Next we will image and clean a low resolution version of the primary beam. ',
		'First you will be given the opportunity to change the imaging parameters. ',
		'Leave a value unset if you wish to make the program choose a value. ',
		'Press the Apply button when you have finished setting parameters.');
    w.disable();
    subframe := F;
    private.wholeworkframe := F;
    private.wholeworkframe := w.workframe(new=T);
    private.widgetset.tk_release();

    w.message('Starting imager...');
    w.writecode('include \'imager.g\'');
    w.writecode('myimager:=imager(', as_evalstr(msname), ')');
    qi := imagerwizardquickimage(msname, widgetset=private.widgetset);

    qi.setddid(possibleddids[ddids]);
    qi.setfieldid(possiblefields[fieldids]);
    w.message('Please set imaging parameters and press the Apply button');
    if(is_fail(qi.setdefaults(private.wholeworkframe))) fail;
    w.enable();

    w.message('Please press Next to continue');
    if (!w.waitfornext()) {
      deactivate private.whenevers;
      qi.done();
      w.done();
      return F;
    }

    ##### Step 5 - Initial inspection
    private.widgetset.tk_hold();
    w.writestep('5. Initial imaging and display');
    w.writeinfo('Now we image and clean a low resolution version of the primary beam. ',
                'Then we will use the viewer to display the resulting image. Please ',
		'select a region to be the area imaged in the final step. To select ',
		'a region, first click at the left display border on either the box ',
		'or polygon. To make a box region, left click and drag the outline, ',
		'to make a polygon, left click on the vertices. Once the region is ',
		'complete double-click within the region. To continue once the region ',
		'is defined, press the Next button');
    w.disable();
    private.wholeworkframe := F;
    private.wholeworkframe := w.workframe(new=T);
    private.widgetset.tk_release();

    w.message('Imaging and cleaning full primary beam area...');
    # Clean the image with uvmax set to 33% of the true
    # maximum baseline. Arbitrarily use 1000 iterations
    # to clear away brightest sources
    restored:='';
    result := qi.cleanimage(name=fieldname, scale=0.33, writecode=w.writecode,
			    restored=restored);
    if(is_fail(result)) {
      deactivate private.whenevers;
      qi.done();
      w.done();
      return throw(paste('imager failed to create restored image', restored, result::message));
    }
    w.message('Imaging and cleaning has finished');

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
    phasecenter := myim.coordmeasures().direction;
    private.fullregion := unset;
    bb := myim.boundingbox(region=private.fullregion);
    xmin := bb.blc[1]; ymin := bb.blc[2]; xmax := bb.trc[1]; ymax := bb.trc[2];
    
    w.message('Displaying image. Use Adjust button to control display');
    result := myim.view(parent=private.wholeworkframe, raster=T,
			widgetset=private.widgetset);
    if(is_boolean(result)&&result) {
      w.message('Please define a rectangular region to be cleaned at full resolution');
      whenever myim->region do {
	w.message('Received region definition from the viewer');
	private.fullregion := $value.region;
        if(is_region(private.fullregion)) {
	  w.message('Region is valid: you may proceed by pressing Next');
	}
	else {
	  w.message('Region is invalid: please try again');
	}
      } private.pushwhenever();
    }
    else if(is_fail(result)) {
      w.message('Failed to start viewer: ', result::message, ' proceeding');
    }
    else {
      w.message('Failed to start viewer, proceeding');
    }

    w.enable();
    note(paste('Restored initial image is ',restored));
    if (!w.waitfornext()) {
      note('imagerwizard cancelled', origin='imagerwizard');
      if(is_image(myim)) {
	myim.close();
	myim.done();
      }
      w.done();
      qi.done();
      deactivate private.whenevers;
      return F;
    }

    # If we have a valid region then find the bounding box
    if(is_region(private.fullregion)) {
      bb := myim.boundingbox(region=private.fullregion);
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
      }
    }
	
    # and vnoise?
    w.message('Now calculating statistics of whole image in Stokes V polarization');
    w.writecode('stats:=[=]');
#
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
    vnoise := stats.sigma;

    w.message('');

    #### 6 - Make the final image
    w.writestep('6. Final imaging and cleaning');
    w.writeinfo('Make and clean the final image. We clean down to 3 times ',
		'the rms Stokes V noise in the last image. After the clean has ',
		'finished, the final restored image will be displayed. ',
		'Press Finish to exit from imagerwizard.');
    w.disable();
    w.laststep();
    private.widgetset.tk_hold();
    private.wholeworkframe := F;
    private.wholeworkframe := w.workframe(new=T);
    private.widgetset.tk_release();

    qi.setparms(phasecenter, max(128, 3*max(xmax - xmin, ymax - ymin)));
    restored:='';
    result := qi.cleanimage(name=fieldname, threshold=dq.quantity(3.0*(3)*vnoise, 'Jy'),
			    writecode=w.writecode, restored=restored);
    if(is_fail(result)) {
      deactivate private.whenevers;
      qi.done();
      w.done();
      return throw(paste('imager failed to create final restored image',
			 restored, result::message));
    }

    w.enable();
    w.message(paste('Full field restored image is ',restored));

    w.message('Imaging and cleaning has finished');

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
    result := myim.view(parent=private.wholeworkframe, raster=T, widgetset=private.widgetset);
    more := w.waitfornext();
    myim.close();
    myim.done();

    if (!more) {
      w.writecode('myimager.done()');
      w.writecode('# end of script written by imagerwizard.g');
      deactivate private.whenevers;
      qi.done();
      w.done();
      return F;
    }

    w.writecode('myimager.done()');
    w.writecode('# end of script written by imagerwizard.g');
    w.message('That\'s it!');
    deactivate private.whenevers;
    qi.done();
    w.done();
    return T;
}


