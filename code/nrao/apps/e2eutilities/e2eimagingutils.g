# e2eimagingutils: useful utilities for e2e imaging
# Copyright (C) 1999,2000,2001,2002
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
# $Id: e2eimagingutils.g,v 19.0 2003/07/16 03:44:58 aips2adm Exp $

pragma include once;

e2eimagingutils := function() {

  public := [=];

  public.image := function(thread) {

    wider public;

    if(!thread.valid()) return T;
    include 'e2emsutils.g';
    msutil := e2emsutils(thread.msname());
    frequency := msutil.frequency(thread.query());
    telescope := unique(msutil.telescope(thread.query()));
    config    := unique(msutil.config(thread.query()));
    spwid     := thread.spwid();

    fieldid := [=];
    for (source in thread.sources().all) {
      fieldid[source] := msutil.nametofieldid(source);
    }
    msutil.done();
    
    include 'e2estandards.g';
    ip   := e2estandards().imageparameters(frequency[1], telescope, config);
    if(is_fail(ip)) fail;

    for (source in thread.sources().all) {

      nchan := thread.nchan();
      usemfs := e2estandards().usemfs(frequency, telescope, config, nchan);
      
      if(thread.niter()>0) {
	model    := thread.image(source, 'clean');
	restored := thread.image(source, 'clean.restored');
      }
      else {
	restored := thread.image(source, 'dirty');
      }

      if(!tableexists(restored)) {
	include "imager.g";
	img := imager(thread.msname());
#
# Now set up imager correctly. For calibraters, we image only 512 pixels with 1 facet.
#
	if(usemfs) {
	  note ('Imaging ', source, ' all channels at once');
	  img.setdata(fieldid=fieldid[source], msselect=thread.query());
	  if(any(source==thread.sources().Target)) {
	    img.setimage(nx=ip.pixels, ny=ip.pixels, cellx=ip.cell, celly=ip.cell,
			 fieldid=fieldid[source], spwid=spwid,
			 stokes='IV', facets=ip.facets);
	  }
	  else {
	    img.setimage(nx=512, ny=512, cellx=ip.cell, celly=ip.cell,
			 fieldid=fieldid[source], spwid=spwid,
			 stokes='IV', facets=1);
	  }
	  thread.addhistory('Imaged ', source, ' in all channels at once');
	}
	else {
	  note ('Imaging ', source, ' channel by channel');
	  img.setdata(mode='channel', nchan=sum(nchan), start=1, 
		      fieldid=fieldid[source], msselect=thread.query());
	  if(any(source==thread.sources().Target)) {
	    img.setimage(mode='channel', nchan=sum(nchan), start=1,
			 nx=ip.pixels, ny=ip.pixels, cellx=ip.cell, celly=ip.cell,
			 fieldid=fieldid[source], spwid=spwid,
			 stokes='IV', facets=ip.facets);
	  }
	  else {
	    img.setimage(mode='channel', nchan=sum(nchan), start=1,
			 nx=512, ny=512, cellx=ip.cell, celly=ip.cell,
			 fieldid=fieldid[source], spwid=spwid,
			 stokes='IV', facets=1);
	  }
	  thread.addhistory('Imaged ', source, ' channel by channel');
	}
	img.setoptions(cache=1024*1024*1024);
	img.summary()
	img.weight('robust');
	if(thread.niter()>0) {
	  tabledelete(model);
	  img.clean(algorithm=ip.algorithm, model=model, image=restored, threshold='0Jy',
		    niter=thread.niter());
	  thread.addhistory('Cleaned ', source, ' with ', thread.niter(), ' iterations');
	}
	else {
	  thread.addhistory('Made dirty image for ', source);
	  img.makeimage('corrected', restored);
	}
	img.done();
      }
    } 
    return T;
  }

  public.selfcal := function(thread) {

    if(!thread.valid()) return T;

    include 'e2emsutils.g';
    msutil := e2emsutils(thread.msname());
    frequency := msutil.frequency(thread.query());
    telescope := unique(msutil.telescope(thread.query()));
    config    := unique(msutil.config(thread.query()));
    interval  := min(msutil.interval(thread.query()));
    msutil.done();

    include 'e2estandards.g';
    scp  := e2estandards().selfcalparameters(frequency[1], telescope, config);
    if(is_fail(scp)) fail;

    fieldid := [=];
    for (source in thread.sources().all) {
      fieldid[source] := msutil.nametofieldid(source);
    }
    
    for (source in thread.sources().all) {

      model        := thread.image(source, 'clean');
      selfcalmodel := thread.image(source, 'clean.selfcalmodel');
      restored     := thread.image(source, 'clean.restored');
      
      if(tableexists(restored)) {
	include 'image.g';
	im := image(restored);
	s := [=];
	im.statistics(s);
	im.done();
	if(s.max > dq.convert(scp.threshold, 'Jy').value) {
	  paste('Making Selfcalibrated image for ', source);
	  global e2eimageim;
	  e2eimageim:=image(model);
	  imf:=imagecalc(selfcalmodel, '$e2eimageim[$e2eimageim>0.0]', T);
	  e2eimageim.done(); imf.done();
	  include "imager.g";
	  img:=imager(thread.msname());
	  if(is_fail(img)) fail;
	  img.setdata(fieldid=fieldid[source], msselect=thread.query());
	  note('Transforming model images');
	  img.ft(model=selfcalmodel);
	  img.done();
	  tsolint := dq.convert(scp.tsol, 's').value;
	  if(tsolint<interval) {
	    note('Integration time ', interval, 's longer than atmospheric coherence time', tsolint, 's', priority='WARN');
	    return T;
	  }
	  else {
	    note('Solving for T Jones with solution interval ', tsolint, 's');
	  }
	  include "calibrater.g";
	  cal:=calibrater(thread.msname());
	  if(is_fail(cal)) fail;
	  msselect:=spaste('FIELD_ID== ', fieldid[source]);
	  cal.setdata(msselect=msselect);
	  if(tableexists(thread.caltable('scaledG'))) {
	    cal.setapply('G', table=thread.caltable('scaledG'));
	  }
	  else {
	    cal.setapply('G', table=thread.caltable('G'));
	  }
	  Tcaltable := thread.caltable('T');
	  cal.setsolve('T', table=Tcaltable, preavg=tsolint, t=tsolint, phaseonly=T);
	  cal.solve();
	  cal.setapply('T', table=Tcaltable);
	  cal.correct();
	  cal.done();
	  thread.addhistory('Selfcalibrated ', source, ' in T Jones with solution interval ', tsolint, 's');
	  tabledelete(restored);
	}
      }
      e2eimagingutils().image(thread);
    }
    return T;
  }

  public.imlin := function(thread) {
    wider public;

    include 'imlin.g';

    if(!thread.valid()) return T;

    for (source in thread.sources().all) {

      if(thread.niter()>0) {
	restored := thread.image(source, 'clean.restored');
      }
      else {
	restored := thread.image(source, 'dirty');
      }
      if(tableexists(restored)) {
	imlin(restored);
	thread.addhistory('Removed continuum for ', restored, ' by image plane fit');
      }
    } 
    return T;
  }

  return ref public;
}
