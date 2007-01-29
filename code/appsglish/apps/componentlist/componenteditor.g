# componenteditor.g: Glish/tk frame for editing/viewing for model components
# Copyright (C) 1996,1997,1998,1999,2000,2001
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
# $Id: componenteditor.g,v 19.2 2004/08/25 01:06:29 cvsmgr Exp $

pragma include once

include 'widgetserver.g'
include 'popuphelp.g';

#componenteditor := function (list, which=1, edit=T, parentframe=F,
const componenteditor := function (list, which=1, edit=T, parentframe=F, 
				   widgetserver=dws) {
  include 'componentlist.g';

  if (!is_componentlist(list)) {
    return throw('componenteditor needs an componentlist tool',
		 origin='componenteditor');
  }

  if (!widgetserver.have_gui()) {
    return throw('Cannot create a component editor.\n',
		 'Perhaps you are not in a windowing environment\n',
		 'or the DISPLAY environment variable is not correctly set.',
		 origin='componenteditor');
  }

  private := [=];
  if (list.length() == 0) {
    return throw('The componentlist tool does not contain any components',
		 origin='componenteditor');
  }

  if (!is_integer(which) | (which < 1) | (which > list.length())) {
    return throw('The which argument must be an integer between 1 and ',
		 list.length(), ' (the length of the list)',
		 origin='componenteditor');
  }
  private.which := which;
  private.edit := edit;
  private.modified := F;
  private.doingUndo := F;
  private.cl := emptycomponentlist(log=F);
  private.cl.concatenate(list, which, log=F)

  const private.create := function(gui) {
    wider private;
    widgetserver.tk_hold();
    gui.mode := widgetserver.frame(gui, side='left', relief='flat', 
				   height=0, width=0);
    private.createModeFrame(gui.mode);
    gui.label := widgetserver.frame(gui, side='left', expand='x', 
				    relief='flat', height=0, width=0);
    private.createLabelFrame(gui.label);
    gui.flux := widgetserver.rollup(gui, title='Flux');
    private.createFluxFrame(gui.flux.frame());
    gui.shape := widgetserver.rollup(gui, title='Shape');
    private.createShapeFrame(gui.shape.frame());
    gui.spectrum := widgetserver.rollup(gui, title='Spectrum');
    private.createSpectrumFrame(gui.spectrum.frame());
    gui.spectrum.up();
    gui.actions := 
      widgetserver.frame(gui, side='left', relief='flat', height=0, width=0);
    private.createActionFrame(gui.actions);
    widgetserver.tk_release();
    include 'popuphelp.g';
    ok := addpopuphelp(gui, maxlevels=7); if (is_fail(ok)) fail;
  }

  const private.redraw := function(gui) {
    wider private;
    widgetserver.busy(gui);
    widgetserver.tk_hold();
    private.redrawLabel(gui.label);
    private.redrawFlux(gui.flux.frame());
    private.redrawShape(gui.shape.frame());
    private.redrawSpectrumFrame(gui.spectrum.frame());
    private.redrawActionFrame(gui.actions);
    widgetserver.tk_release();
    widgetserver.notbusy(gui);
  }

  const private.enableentry := function(entry, enable) {
    if (enable) {
      entry -> disabled(F);
      entry -> background(widgetserver.resources('entry').background);
    } else {
      entry -> disabled(T);
      entry -> background(widgetserver.resources('frame').background);
    }
  }
# ---------------------------------------------------------------------------
# create the mode frame and define all the things that can be done with it
  private.createModeFrame := function(mode) {
    wider private;
    mode.view := widgetserver.button(mode, text='View', type='radio', 
				     relief='flat');
    mode.view -> state(!private.edit);
#     mode.view.shorthelp := 'Change to view mode';
    whenever mode.view -> press do {
      wider private;
      private.edit := F;
      private.redraw(private.gui);
    }
    mode.edit := widgetserver.button(mode, text='Edit', type='radio', 
				     relief='flat');
    mode.edit -> state(private.edit);
#     mode.edit.shorthelp := 'Change to edit mode';
    whenever mode.edit -> press do {
      wider private;
      private.edit := T;
      private.redraw(private.gui);
    }
    return T;
  }
# ---------------------------------------------------------------------------
# create the label frame and define all the things that can be done with it
  private.createLabelFrame := function(clabel) {
    wider private;
    clabel.label := widgetserver.label(clabel, 'Label:');
    popuphelp(clabel.label, 'Arbitrary text string')
    clabel.entry := widgetserver.entry(clabel, width=22, fill='x');
    clabel.entry -> insert(list.getlabel(1));
    whenever clabel.entry -> return do {
      value := clabel.entry -> get();
      list.setlabel(private.which, value, log=F);
    }
    return T;
  }
# ---------------------------------------------------------------------------
# Refresh the label frame using the string in  the current component.
  const private.redrawLabel := function (clabel) {
    wider private;
    clabel.entry -> delete('start','end');
    clabel.entry -> insert(list.getlabel(private.which));
    private.enableentry(clabel.entry, private.edit);
    return T;
  }
# ---------------------------------------------------------------------------
# create the flux frame and define all the things that can be done with it. 
  const private.createFluxFrame := function (flux) {
    wider private;
    const lwidth := 2;
    const uwidth := 3;

# Make frames for each line 
    flux.row := [=];
    for (i in [1:4]) {
      flux.row[i] := widgetserver.frame(flux, side='left');
    }
# Make labels for each line
    flux.row[1].label := 
      widgetserver.optionmenu(flux.row[1], 
			      ['Stokes', 'I only', 'Linear', 'Circular'],
			      width=lwidth-1);
    popuphelp(flux.row[1].label, 'The flux representation')
    whenever flux.row[1].label -> select do {
      pol :=  $value.value;
      if (pol == 'I only') pol := 'Stokes';
      if (private.edit) {
	value := list.getfluxvalue(private.which);
	unit := list.getfluxunit(private.which);
	list.setflux(private.which, value, unit, pol, log=F);
      } else {
	list.convertfluxpol(private.which, pol);
      }
    }
    for (i in [2:4]) {
      flux.row[i].label := widgetserver.label(flux.row[i], width=lwidth);
    }
# Make entries for each line
    for (i in [1:4]) {
      flux.row[i].entry := widgetserver.entry(flux.row[i], width=10);
    }
# Make units for each line
    flux.row[1].unit := widgetserver.optionmenu(flux.row[1], "Jy mJy WU", 
						width=uwidth);
    whenever flux.row[1].unit -> select do {
      unit :=  $value.value;
      if (private.edit) {
	value := list.getfluxvalue(private.which);
	pol := list.getfluxpol(private.which);
	list.setflux(private.which, value, unit, pol, log=F);
      } else {
	list.convertfluxunit(private.which, unit);
      }
    }
    flux.row[2].unit := widgetserver.optionmenu(flux.row[2]);
    whenever flux.row[2].unit -> select do {
      unit :=  $value.value;
      if (unit == '%') {
	unit := flux.row[1].unit.getlabel();
      }
      if (private.edit) {
	value := list.getfluxvalue(private.which);
	pol := list.getfluxpol(private.which);
	list.setflux(private.which, value, unit, pol, log=F);
      } else {
	list.convertfluxunit(private.which, unit);
      }
    }
    for (i in [3:4]) {
      flux.row[i].unit := widgetserver.label(flux.row[i], width=uwidth);
    }
    for (i in [1:4]) {
      whenever flux.row[i].entry -> return do {
	value := [];
	for (i in [1:4]) {
	  value[i] := as_dcomplex(flux.row[i].entry -> get());
	}
	if (flux.row[2].unit.getlabel() == '%') {
	  value[2:4] *:= value[1]/100.0;
	}
	unit := list.getfluxunit(private.which);
	pol := list.getfluxpol(private.which);
	list.setflux(private.which, value, unit, pol, log=F);
      }
    }
    return T;
  }
# ---------------------------------------------------------------------------
# Refresh the flux frame using the values, units and polarizations in
# the current component.  Convert to percentage polarization if
# necessary.
  const private.redrawFlux := function (flux) {
    wider private;
    value := list.getfluxvalue(private.which);
    value::print.precision := 8;
    unit := list.getfluxunit(private.which);
    pol := list.getfluxpol(private.which);
    if (pol == "Stokes") {
      stokes := "I Q U V";
    } else if (pol == "Linear") {
      stokes := "XX XY YX YY";
    } else if (pol == "Circular") {
      stokes := "RR RL LR LL";
    }
#    flux.row[1].unit.text := unit;
    const allowPct := (pol == 'Stokes') & (value[1] > 0);
    s := flux.row[2].unit.getlabel();
    const displayPct := allowPct & (is_string(s) && s=='%');
    if (displayPct) {
      value[2:4] := value[2:4]/value[1] * 100.0;
    }
    for (i in [1:4]) {
      flux.row[i].entry -> delete('start','end');
      flux.row[i].entry -> insert(as_string(value[i]));
      private.enableentry(flux.row[i].entry, private.edit);
    }

    flux.row[1].unit.setlabel(unit);
    if (allowPct) {
      flux.row[2].unit.replace([unit, '%'], width=3);
      if (displayPct) {
	flux.row[2].unit.setlabel('%');
	unit := '%';
      }
    } else {
      flux.row[2].unit.replace([unit]);
    }
    for (i in [3:4]) {
      flux.row[i].unit -> text(unit);
    }

    flux.row[1].label.setlabel(stokes[1]);
    for (i in [2:4]) {
	flux.row[i].label -> text(stokes[i]);
    }
    const Ionly := (flux.row[1].label.getvalue() == 'I only');
    for (i in [2:4]) {
      if (Ionly) {
	flux.row[i] -> unmap();
      } else {
	flux.row[i] -> map();
      }
    }
  }
# ---------------------------------------------------------------------------
# constructs the direction sub-frame.
  const private.createDirSubFrame := function (dir) {
    wider private;
    const ewidth := 14;
    const lwidth := 5;
    dir.row := [=];
    const fields := "ra dec";
    local aUnits := 
      "HH:MM:SS.sss HH:MM:SS HH:MM +DDD.MM.SS +DDD.MM.SS.sss +DDD.MM deg rad";
    local aLabels := "H:M:S.s H:M:S H:M D.M.S.s D.M.S D.M. deg rad";
    for (f in [1:2]) {
      dir.row[f] := widgetserver.frame(dir, side='left');
      dir.row[f].label := widgetserver.label(dir.row[f], width=lwidth);
      dir.row[f].entry := widgetserver.entry(dir.row[f], width=ewidth);
      if (f == 2) {
	end :=len(aUnits); 
	aUnits := aUnits[4:end];
	aLabels := aLabels[4:end];
      }
      dir.row[f].unit := 
	widgetserver.optionmenu(dir.row[f], aLabels, aUnits, width=7, 
				hlp='Select the angular units');
    }

    dir.row[3] := widgetserver.frame(dir, side='left');
    dir.row[3].label := 
      widgetserver.label(dir.row[3], 'Frame', width=lwidth);
    dir.row[3].unit := 
      widgetserver.optionmenu(dir.row[3], "J2000 B1950 GALACTIC",
			      hlp='Select the direction reference frame');
    whenever dir.row[1].entry -> return, dir.row[2].entry -> return, 
      dir.row[1].unit -> select, dir.row[2].unit -> select,
      dir.row[3].unit -> select do {
	private.readDirSubFrame(dir);
      }
  }
# ---------------------------------------------------------------------------
# Refresh the dir sub-frame using the values in the current component.
  const private.readDirSubFrame := function (dir) {
    wider private;
    frame := dir.row[3].unit.getlabel();
    if (private.edit ) {
      for (f in [1:2]) {
	value[f] := dir.row[f].entry -> get();
	unit[f] := dir.row[f].unit.getlabel();
	if (unit[f] == 'H:M:S' | unit[f] == 'H:M' | unit[f] == 'H:M:S.s') {
	  unit[f] := 'time';
	} else if (unit[f] == 'D.M.S' | unit[f] == 'D.M.' |
		   unit[f] == 'D.M.S.s') {
	  unit[f] := 'angle';
	}
      }
      list.setrefdir(private.which, 
		     value[1], unit[1], value[2], unit[2], log=F);
      list.setrefdirframe(private.which, frame, log=F);
    } else {
      list.convertrefdir(private.which, frame);
    }
  }
# ---------------------------------------------------------------------------
# Refresh the dir sub-frame using the values in the current component.
  const private.redrawDirSubFrame := function (dir) {
    wider private;
    const fields := "ra dec";
    dirString := [=];
    for (f in [1:2]) {
      dunit := dir.row[f].unit.getlabel();
      if (dunit == 'H:M:S') {
 	unit := 'time'; precision := 6;
      } else if (dunit == 'H:M:S.s') {
 	unit := 'time'; precision := 9;
      } else if (dunit == 'H:M') {
 	unit := 'time'; precision := 3;
      } else if (dunit == 'D.M.S') {
 	unit := 'angle'; precision := 6;
      } else if (dunit == 'D.M.S.s') {
 	unit := 'angle'; precision := 9;
      } else if (dunit == 'D.M.') {
 	unit := 'angle'; precision := 3;
      } else {
 	unit := dunit; precision := 12;
      }
      if (f == 1) {
 	dirString := list.getrefdirra(private.which, unit, precision);
      } else {
 	dirString := list.getrefdirdec(private.which, unit, precision);
      }
      dir.row[f].entry -> delete('start','end');
      dir.row[f].entry -> insert(dirString);
      private.enableentry(dir.row[f].entry, private.edit);
    }
    frame := list.getrefdirframe(private.which);
    if (frame == 'GALACTIC') {
      dir.row[1].label -> text('GLAT');
      dir.row[2].label -> text('GLON');
    } else {
      dir.row[1].label -> text('RA');
      dir.row[2].label -> text('Dec');
    }
    dir.row[3].unit.selectlabel(frame);
  }
# ---------------------------------------------------------------------------
# create the shape frame and define all the things that can be done with it. 
  const private.createShapeFrame := function (shape) {
    wider private;
# Make the dir sub-frame
    shape.dir := widgetserver.frame(shape, side='top');
    private.createDirSubFrame(shape.dir);
# Make the shape type sub-frame
    shape.type := widgetserver.frame(shape, side='left');
    private.createShapeTypeSubFrame(shape.type);
# Make frames for all the shape parameters (only one will be mapped)
    shape.point := widgetserver.frame(shape, side='top', height=0, width=0);
    private.createPointShapeSubFrame(shape.point);
    shape.gaussian := widgetserver.frame(shape, side='top', height=0, width=0);
    private.createGaussianShapeSubFrame(shape.gaussian);
    shape.disk := widgetserver.frame(shape, side='top', height=0, width=0);
    private.createDiskShapeSubFrame(shape.disk);
  }
# ---------------------------------------------------------------------------
# Redraw the shape frame.
  const private.redrawShape := function (shape) {
    wider private;
    private.redrawShapeTypeSubFrame(shape.type);
    private.redrawDirSubFrame(shape.dir);
    local type := list.shapetype(private.which);
    if (type == 'Point') {
      shape.gaussian -> unmap();
      shape.disk -> unmap();
      private.redrawPointShape(shape.point);
      shape.point -> map();
    } else if (type == 'Gaussian') {
      shape.point -> unmap();
      shape.disk -> unmap();
      private.redrawGaussianShape(shape.gaussian);
      shape.gaussian -> map();
    } else if (type == 'Disk') {
      shape.point -> unmap();
      shape.gaussian -> unmap();
      private.redrawDiskShape(shape.disk);
      shape.disk -> map();
    }
  }
# ---------------------------------------------------------------------------
# create the shape.type subframe and define all the things that can be
# done with it. 
  const private.createShapeTypeSubFrame := function (type) {
#   wider private;
#   const lpad := 6;
    type.label := widgetserver.label(type, text='Shape', width=5);
    type.entry := widgetserver.optionmenu(type, "Point Gaussian Disk");
    popuphelp(type.label, 'Select the shape');
    whenever type.entry -> select do {
      value :=  $value.value;
      if (value != list.shapetype(private.which)) {
	list.setshape(private.which, value, log=F);
      }
    }
 }
# ---------------------------------------------------------------------------
# Redraw the shape-type sub-frame.
  const private.redrawShapeTypeSubFrame := function (type) {
    wider private;
    type.entry.setlabel(list.shapetype(private.which));
    if (private.edit) {
      type.entry.disabled(F);
    } else {
      type.entry.disabled(T);
    }
  }
# ---------------------------------------------------------------------------
# create the point shape subframe and define all the things that can be
# done with it. 
  const private.createPointShapeSubFrame := function (point) {
  }
# ---------------------------------------------------------------------------
# Redraw the Point shape sub frame
  const private.redrawPointShape := function (point) {
  }
# ---------------------------------------------------------------------------
# create the shape.gaussian subframe and define all the things that can be
# done with it.  The structure used (print private.gui.shape.gaussian)
  const private.createGaussianShapeSubFrame := function (gaussian) {
    wider private;
    gaussian.row := [=];
    local lab := ['Major Axis', 'Minor Axis', 'Position Angle'];
    local hlp := ['FWHM of the larger axis',
		  'FWHM of the smaller axis',
		  'Inclination (North thru East) of the major axis'];
    local angleUnits := "arcsec mas arcmin deg rad";
    for (i in [1:3]) {
      gaussian.row[i] := widgetserver.frame(gaussian, side='left');
      gaussian.row[i].label := 
	widgetserver.label(gaussian.row[i], text=lab[i], width=14);
      popuphelp(gaussian.row[i].label, hlp[i]);
      gaussian.row[i].entry :=  widgetserver.entry(gaussian.row[i], width=13);
      whenever gaussian.row[i].entry -> return do {
	maj := as_double(gaussian.row[1].entry -> get());
	majUnit := gaussian.row[1].unit.getvalue();
	min := as_double(gaussian.row[2].entry -> get());
	minUnit := gaussian.row[2].unit.getvalue();
	pa := as_double(gaussian.row[3].entry -> get());
	paUnit := gaussian.row[3].unit.getvalue();
	list.setshape(private.which, 'Gaussian', 
		      majoraxis=spaste(maj, majUnit),
		      minoraxis=spaste(min, minUnit),
		      positionangle=spaste(pa, paUnit), log=F);
      }
      if (i == 3) {
	angleUnits := "deg rad";
      } 
      gaussian.row[i].unit := 
	widgetserver.optionmenu(gaussian.row[i], angleUnits, 
				hlp='Select the angular units', width=6);
      whenever gaussian.row[i].unit -> select do {
	maj := as_double(gaussian.row[1].entry -> get());
	majUnit := gaussian.row[1].unit.getvalue();
	min := as_double(gaussian.row[2].entry -> get());
	minUnit := gaussian.row[2].unit.getvalue();
	pa := as_double(gaussian.row[3].entry -> get());
	paUnit := gaussian.row[3].unit.getvalue();
	if (private.edit) {
	  list.setshape(private.which, 'Gaussian', 
			majoraxis=spaste(maj, majUnit),
			minoraxis=spaste(min, minUnit),
			positionangle=spaste(pa, paUnit), log=F);
	} else {
	  list.convertshape(private.which, 
			    majoraxis=majUnit,
			    minoraxis=minUnit,
			    positionangle=paUnit);
	}
      }
    }
  }
# ---------------------------------------------------------------------------
# Redraw the Gaussian shape sub frame
  const private.redrawGaussianShape := function (gaussian) {
    wider private;
    const gaussianShape := list.getshape(private.which);
    const fields := "majoraxis minoraxis positionangle";
    for (f in [1:3]) {
      fld := fields[f];
      value := gaussianShape[fld].value;
      unit := gaussianShape[fld].unit
      value::print.precision := 10;
      gaussian.row[f].entry -> delete('start', 'end');
      gaussian.row[f].entry -> insert(as_string(value));
      private.enableentry(gaussian.row[f].entry, private.edit);
      gaussian.row[f].unit.selectlabel(unit);
    }
  }
# ---------------------------------------------------------------------------
# create the shape.gaussian subframe and define all the things that can be
# done with it.
  const private.createDiskShapeSubFrame := function (disk) {
    wider private;
    disk.row := [=];
    local lab := ['Major Axis', 'Minor Axis', 'Position Angle'];
    local hlp := ['FWHM of the larger axis',
		  'FWHM of the smaller axis',
		  'Inclination (North thru East) of the major axis'];
    local angleUnits := "arcsec mas arcmin deg rad";
    for (i in [1:3]) {
      disk.row[i] := widgetserver.frame(disk, side='left');
      disk.row[i].label := 
	widgetserver.label(disk.row[i], text=lab[i], width=14);
      popuphelp(disk.row[i].label, hlp[i]);
      disk.row[i].entry :=  widgetserver.entry(disk.row[i], width=13);
      whenever disk.row[i].entry -> return do {
	maj := as_double(disk.row[1].entry -> get());
	majUnit := disk.row[1].unit.getvalue();
	min := as_double(disk.row[2].entry -> get());
	minUnit := disk.row[2].unit.getvalue();
	pa := as_double(disk.row[3].entry -> get());
	paUnit := disk.row[3].unit.getvalue();
	list.setshape(private.which, 'Disk', 
		      majoraxis=spaste(maj, majUnit),
		      minoraxis=spaste(min, minUnit),
		      positionangle=spaste(pa, paUnit), log=F);
      }
      if (i == 3) {
	angleUnits := "deg rad";
      } 
      disk.row[i].unit := 
	widgetserver.optionmenu(disk.row[i], angleUnits, 
				hlp='Select the angular units', width=6);
      whenever disk.row[i].unit -> select do {
	maj := as_double(disk.row[1].entry -> get());
	majUnit := disk.row[1].unit.getvalue();
	min := as_double(disk.row[2].entry -> get());
	minUnit := disk.row[2].unit.getvalue();
	pa := as_double(disk.row[3].entry -> get());
	paUnit := disk.row[3].unit.getvalue();
	if (private.edit) {
	  list.setshape(private.which, 'Disk', 
			majoraxis=spaste(maj, majUnit),
			minoraxis=spaste(min, minUnit),
			positionangle=spaste(pa, paUnit), log=F);
	} else {
	  list.convertshape(private.which, 
			    majoraxis=majUnit,
			    minoraxis=minUnit,
			    positionangle=paUnit);
	}
      }
    }
  }
# ---------------------------------------------------------------------------
# Redraw the Disk shape sub frame
  const private.redrawDiskShape := function (disk) {
    wider private;
    const diskShape := list.getshape(private.which);
    const fields := "majoraxis minoraxis positionangle";
    for (f in [1:3]) {
      fld := fields[f];
      value := diskShape[fld].value;
      unit := diskShape[fld].unit
      value::print.precision := 10;
      disk.row[f].entry -> delete('start', 'end');
      disk.row[f].entry -> insert(as_string(value));
      private.enableentry(disk.row[f].entry, private.edit);
      disk.row[f].unit.selectlabel(unit);
    }
  }
# ---------------------------------------------------------------------------
# create the spectrum frame and define all the things that can be done
# with it. 
  const private.createSpectrumFrame := function (spectrum) {
    wider private;
# Make the spectrum type sub-frame
    spectrum.type := widgetserver.frame(spectrum, side='left');
    private.createSpectralTypeSubFrame(spectrum.type);
# Make the freq sub-frame
    spectrum.freq := widgetserver.frame(spectrum, side='top',height=0,width=0);
    private.createFreqSubFrame(spectrum.freq);
# Make frames for all the spectrum parameters (only one will be mapped)
    spectrum.constant := widgetserver.frame(spectrum, side='top', 
					    height=0, width=0);
    private.createConstantSpectrumSubFrame(spectrum.constant);
    spectrum.si := widgetserver.frame(spectrum, side='top', height=0, width=0);
    private.createSpectralIndexSubFrame(spectrum.si);
    return T;
  }
# ---------------------------------------------------------------------------
# Redraw the spectral frame.
  const private.redrawSpectrumFrame := function (spectrum) {
    wider private;
    private.redrawSpectralTypeSubFrame(spectrum.type);
    local spectralType := list.spectrumtype(private.which);
    if (spectralType == 'Constant') {
      spectrum.freq -> unmap();
    } else {
      private.redrawFreqSubFrame(spectrum.freq);
      spectrum.freq -> map();
    }
    for (s in "constant si") {
      spectrum[s] -> unmap();
    }
    if (spectralType == 'Constant') {
      private.redrawConstantSpectrumSubFrame(spectrum.constant);
      spectrum.constant -> map();
    } else if (spectralType == 'Spectral Index') {
      private.redrawSpectralIndexSubFrame(spectrum.si);
      spectrum.si -> map();
    }
  }
# ---------------------------------------------------------------------------
# Create the spectral type subframe and define all the things that can be
# done with it.
  const private.createSpectralTypeSubFrame := function (type) {
    wider private;
    type.label := widgetserver.label(type, text='Spectrum:', width=10);
    type.entry := widgetserver.optionmenu(type,['Constant', 'Spectral Index']);
    popuphelp(type.label, 'The spectral model')
    whenever type.entry -> select do {
      value :=  $value.value;
      if (value != list.spectrumtype(private.which)) {
	list.setspectrum(private.which, value, log=F);
      }
    }
    return T;
  }
# ---------------------------------------------------------------------------
# Redraw the spectral-type sub-frame.
  const private.redrawSpectralTypeSubFrame := function (type) {
    wider private;
    type.entry.selectlabel(list.spectrumtype(private.which));
    if (private.edit) {
      type.entry.disabled(F);
    } else {
      type.entry.disabled(T);
    }
  }
# ---------------------------------------------------------------------------
# Create the frequency sub-frame and define all the things that can be
# done with it.
  const private.createFreqSubFrame := function (freq) {
    wider private;

    freq.row := [=];
    freq.row[1] := widgetserver.frame(freq, side='left');
    freq.row[1].label := widgetserver.label(freq.row[1],"Frequency:",width=10);
    popuphelp(freq.row[1].label, 'The reference frequency')
    freq.row[1].entry := widgetserver.entry(freq.row[1], width=10);
    whenever freq.row[1].entry -> return do {
      value := as_double(freq.row[1].entry -> get());
      unit := freq.row[1].unit.getvalue();
      list.setfreq(private.which, value, unit, log=F);
    }
    freq.row[1].unit := widgetserver.optionmenu(freq.row[1], "MHz GHz Hz kHz");
    whenever freq.row[1].unit -> select do {
      unit :=  $value.value;
      if (private.edit) {
	value := list.getfreqvalue(private.which);
	list.setfreq(private.which, value, unit, log=F);
      } else {
	list.convertfrequnit(private.which, unit);
      }
    }

    freq.row[2] := widgetserver.frame(freq, side='left');
    freq.row[2].label := widgetserver.label(freq.row[2], 'Frame:', width=10);
    popuphelp(freq.row[2].label, 'The frequency frame')
    labels := ['Local standard of rest (kinematic)', 'Barycentric', 
	       'Geocentric', 'Topocentric', 'Rest frequency',
	       'Galactocentric'];
    names := "LSRK BARY GEO TOPO REST GALACTO"
    freq.row[2].unit := widgetserver.optionmenu(freq.row[2], names, labels);
    whenever freq.row[2].unit -> select do {
      frame :=  $value.value;
      if (private.edit) {
	list.setfreqframe(private.which, frame, log=F);
      } else {
# This function DOES not exist yet.
#	list.convertreffreq(private.which, frame); 
	list.setfreqframe(private.which, frame, log=F);
      }
    }
    return T;
  }
# ---------------------------------------------------------------------------
# Redraw the frequency sub-frame.
  const private.redrawFreqSubFrame := function (freq) {
    wider private;
    freq.row[1].entry -> delete('start', 'end');
    freq.row[1].entry -> insert(as_string(list.getfreqvalue(private.which)));
    private.enableentry(freq.row[1].entry, private.edit);
    freq.row[1].unit.selectlabel(list.getfrequnit(private.which));
    freq.row[2].unit.selectlabel(list.getfreqframe(private.which));
  }

# ---------------------------------------------------------------------------
# Create the constant spectrum subframe and define all the things that can be
# done with it.
  const private.createConstantSpectrumSubFrame := function (constant) {
    return T;
  }
# ---------------------------------------------------------------------------
# Redraw the constant spectrum sub-frame.
  const private.redrawConstantSpectrumSubFrame := function (constant) {
    return T;
  }
# ---------------------------------------------------------------------------
# Create the spectral-index subframe and define all the things that can be 
# done with it. 
  const private.createSpectralIndexSubFrame := function (si) {
    si.row := widgetserver.frame(si, side='left');
    si.row.label := widgetserver.label(si.row, text='Index:', width=10);
    si.row.entry := widgetserver.entry(si.row, width=10);
    whenever si.row.entry -> return do {
      value := as_double(si.row.entry -> get());
      list.setspectrum(private.which, 'Spectral Index', index=value, log=F);
    }
    popuphelp(si.row.label, 'Spectral index of all polarizations');
    return T;
  }
# ---------------------------------------------------------------------------
# Redraw the spectral-index sub frame
  const private.redrawSpectralIndexSubFrame := function (si) {
    wider private;
    spectrum := list.getspectrum(1);
    spectrum.index::precision := 10;
    si.row.entry -> delete('start', 'end');
    si.row.entry -> insert(as_string(spectrum.index));
    private.enableentry(si.row.entry, private.edit);
    return T;
  }
# ---------------------------------------------------------------------------
# make the action buttons and define what they should do
  const private.createActionFrame := function (action) {
    wider private;
    action.leftspace := widgetserver.frame(action, width=0, height=0);
    action.undo := widgetserver.button(action, text='Undo');
    whenever action.undo -> press do {
      wider private;
      private.modified := F;
      private.doingUndo := T;
      list.replace(private.which, private.cl, 1, log=F);
    };
    action.middlespace := widgetserver.frame(action, width=0, height=0);
    action.dismiss := 
      widgetserver.button(action, type='Dismiss');
    whenever action.dismiss->press do {
      widgetserver.busy(private.gui);
      list.stopevents(private.which);
      private.dismiss();
    }
    action.rightspace := widgetserver.frame(action, width=0, height=0);
  }
# ---------------------------------------------------------------------------
# Redraw the action frame
  const private.redrawActionFrame := function (action) {
    wider private;
    action.undo -> disabled(!private.modified);
    if (private.edit) {
      action.dismiss -> text('Apply');
    } else {
      action.dismiss -> text('Dismiss');
    }
  }
# ---------------------------------------------------------------------------
# Now that all the gui creation functions are defined we are ready to
# create the gui.
  widgetserver.tk_hold();
  if (is_agent(parentframe)) {
    private.gui := widgetserver.frame(parentframe);
  } else {
    private.gui := widgetserver.frame(title=spaste('Component ', private.which));
  }
  private.create(private.gui);
  private.redraw(private.gui);
  widgetserver.tk_release();

  whenever private.gui->killed do {
    list.stopevents(private.which);
    private.dismiss();
  }

# I need to deactivate the whenevers associated with the list as it
# has a lifetime that is longer than the gui. Hence these whenevers
# will continue to exist when the gui is removed.
  private.whenevers := [];
  const private.dismiss := function() {
    wider private;
    deactivate private.whenevers;
    private.cl.done();
    private.gui.flux.done();
    private.gui.shape.done();
    private.gui.spectrum.frame().type.entry.done();
    private.gui.spectrum.frame().freq.row[1].unit.done();
    private.gui.spectrum.frame().freq.row[2].unit.done();
    private.gui.spectrum.done();
    val private.gui := F;
    val private := F;
  }

  whenever list->changed do {
#    print 'Component ', which, ' has changed'
    if (any($value == private.which)) {
#      print 'Hey thats me. I am component', private.which;
      # This is a kludge because I cannot compare components.
      if (private.doingUndo) {
	private.modified := F;
      } else {
	private.modified := T;
      }
      private.doingUndo := F;
      private.redraw(private.gui);
#    } else {
#      print 'Thats not me. I am component', private.which;
    }
  }
  private.whenevers[len(private.whenevers) + 1] := last_whenever_executed();

  whenever list->dismiss do {
    if (any($value == private.which)) {
      widgetserver.busy(private.gui);
      private.dismiss();
    }
  }
  private.whenevers[len(private.whenevers) + 1] := last_whenever_executed();

# Tell the list to start sending change events.
  list.sendevents(private.which);
};  # closing bracket of const componenteditor := function(...
#=========================================================

