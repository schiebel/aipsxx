# e2edisplayutils: Useful utilities for displaying images
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
#   $Id: e2edisplayutils.g,v 19.0 2003/07/16 03:44:59 aips2adm Exp $

pragma include once;

include 'ddlws.g';

e2edisplayutils := function(imfile, ws=ddlws) {

  private := [=];
  public := [=];
  include 'viewer.g';
  include 'images.g';
  
  if(is_image(imfile)) {
    private.imfile := imfile;
  }
  else {
    private.imfile := image(imfile);
  }
  if(!is_image(private.imfile)) {
    return throw('Argument is not an image or the name of an image file');
  }
  private.units := private.imfile.brightnessunit();
#
# Set up a private viewer, and a display panel
#
  private.viewer := viewer(widgetset=ws);
  if (is_fail(private.viewer)) {
    return throw('Cannot start the viewer. The error was:',
		 private.viewer::message);
  }
  private.dp := 
      private.viewer.newdisplaypanel(hasgui=T, guihasmenubar=T,
                                     isolationmode=T);
  if (is_fail(private.dp)) {
    return throw('Failed to construct displaypanel:',
		 private.dp::message);
  }
#
# Set up a raster display data and register it
#
  private.dd := 
      private.viewer.loaddata(private.imfile, drawtype='raster');
  if (is_fail(private.dd)) {
    private.viewer.done();
    return throw('Failed to construct displaydata. Error was:\n',
		 private.dd::message);
  }
  private.dp.register(private.dd);

#
# Save some useful stuff
#
  opt := private.dd.getoptions();
  private.min := opt.datamin.value;
  private.max := opt.datamax.value;
  note('Image range is   ', private.min, ' to ', private.max, ' ', private.units);
#
# Set personal options
#
  include 'aipsrc.g';
  private.arc := aipsrc();
  opt := private.dd.getoptions();
  for (o in field_names(opt)) {
    v := F;
    if(private.arc.find(v, spaste('qv.', o), F, T)) {
      note('Setting qv personal preference for ', o);
      opt[o].value := v;
    }
  }
  private.dd.setoptions(opt);
#
# Set the colormap
#
  public.colormap := function(colormap='Rainbow 3') {
    wider private, public;
    opt := private.dd.getoptions();
    if(any(opt.colormap.popt==colormap)) {
      opt.colormap.value := colormap;
      return private.dd.setoptions(opt);
    }
    else {
      return throw('Unknown colormap ', colormap);
    }
  }
#
# Label the display
#
  public.label := function(titletext='', on=T) {
    wider private, public;
    opt := private.dd.getoptions();
    opt.titletext.value := titletext;
    opt.axislabelswitch.value := on;
    return private.dd.setoptions(opt);
  }
#
# Display just a range
#
  public.range := function(min=F, max=F) {
    wider private, public;
    opt := private.dd.getoptions();
    if(!is_boolean(min)) {
      opt.datamin.value := min;
    }
    else {
      opt.datamin.value := private.min;
    }
    if(!is_boolean(max)) {
      opt.datamax.value := max;
    }
    else {
      opt.datamax.value := private.max;
    }
    note('Display range is ', opt.datamin.value, ' to ', opt.datamax.value, ' ', private.units);
    return private.dd.setoptions(opt);
  }
#
# Invert the display
#
  public.invert := function() {
    wider private, public;
    opt := private.dd.getoptions();
    s := opt.datamin.value;
    opt.datamin.value := opt.datamax.value;
    opt.datamax.value := s;
    return private.dd.setoptions(opt);
  }
#
# Display a region: default is the entire image
#
  public.region := function(region=unset) {
    wider private, public;
    opt := private.dd.getoptions();
    if(is_unset(region)) {
      opt.region.value := opt.region.default;
    }
    else {
      opt.region.value := region;
    }
    return private.dd.setoptions(opt);
  }
#
# Add a contour plot
#
  public.contour := function(levs=[-2,2,4,8,16,32,64], scale=0.01,
			     type='frac') {
    wider private, public;
    if(!has_field(private, 'ddc')) {
      private.ddc := 
	  private.viewer.loaddata(private.imfile, drawtype='contour');
      if (is_fail(private.ddc)) {
	return throw('Failed to construct displaydata. Error was:\n',
		     private.ddc::message);
      }
      private.dp.register(private.ddc);
    }
    opt := private.ddc.getoptions();
    opt.levels.value := levs;
    opt.scale.value := scale;
    opt.type.value := type;
    return private.ddc.setoptions(opt);
  }
#
# Turn off the contour
#
  public.nocontour := function() {
    wider private, public;
    if(has_field(private, 'ddc')&&is_record(private.ddc)) {
      private.dp.unregister(private.ddc);
    }
    return T;
  }

#
# Set paper colors
#
  public.papercolors := function(papercolors=T) {
    wider private, public;
    opt := private.dp.canvasmanager().getoptions();
    opt.papercolors.value := papercolors;
    return private.dp.canvasmanager().setoptions(opt);
  }
#
# List options
#
  public.listoptions := function() {
    wider private, public;
    opt :=private.dd.getoptions();
    note('Options for viewer: ');
    for (o in field_names(opt)) {
      note('   ', o, ' : ', opt[o].value);
    }
    return T;
  }
#
# Get options
#
  public.getoptions := function() {
    wider private, public;
    return private.dd.getoptions();
  }
#
# Set options
#
  public.setoptions := function(opt) {
    wider private, public;
    return private.dd.setoptions(opt);
  }
#
# Get specific option value
#
  public.getoption := function(name) {
    wider private, public;
    opt := private.dd.getoptions();
    if(has_field(opt, name)) {
      return opt[name].value
    }
    else {
      return throw('No option called ', name);
    }
  }
#
# Set specific option value
#
  public.setoption := function(name, value) {
    wider private, public;
    opt := private.dd.getoptions();
    if(has_field(opt, name)) {
      opt[name].value := value;
      return private.dd.setoptions(opt);
    }
    else {
      return throw('No option called ', name);
    }
  }
#
# Set specific option value
#
  public.resetoption := function(name) {
    wider private, public;
    opt := private.dd.getoptions();
    if(has_field(opt, name)) {
      opt[name].value := opt[name].default;
      return private.dd.setoptions(opt);
    }
    else {
      return throw('No option called ', name);
    }
  }
#
# Write an xpm version of the image
#
  public.writexpm := function(filename='') {
    wider private, public;
    if(filename=='') {
      filename := spaste(private.imfile.name(), '.xpm');
    }
    note('Printing xpm image to ', filename);
    return private.dp.canvasprintmanager().writexpm(filename);
  }
#
# Write a postscript version of the image
#
  public.writeps := function(filename='', media='letter', landscape=F,
						   dpi=100, zoom=1.0, eps=F) {
    wider private, public;
    if(filename=='') {
      filename := spaste(private.imfile.name(), '.ps');
    }
    note('Printing postscript image to ', filename);
    return private.dp.canvasprintmanager().writeps(filename, media=media, landscape=landscape,
						   dpi=dpi, zoom=zoom, eps=eps);
  }
#
# Typing
#
  public.type := function() {
    return "e2edisplayutils";
  }
#
# Done!
#
  public.done := function() {
    wider private, public;
    private.dp.unregister(private.dd);
    private.dd.done();
    if(is_record(private.ddc)) {
      private.dp.unregister(private.ddc);
      private.ddc.done();
    }
    private.dp.done();
    return T;
  }
#
# Debugging aid
#
  public.debug := function() {return ref private};

  return ref public;
}

e2edisplayutilstest := function(file='') {
  include 'image.g';
  im:=[=];
  if(file=='') {
    im:= imagemaketestimage('qvtest.image');
    file := 'qvtest.image';
  }
  else {
    im:= image(file);
  }
  t := e2edisplayutils(im);

  t.label('Test of e2edisplayutils.g');

  t.region(drm.quarter());
  t.region();

#  t.contour(type='abs', scale=0.5);

  t.range(0, 10);
  t.range();


  t.invert();
  t.colormap();
  t.invert();

  note(as_evalstr(t.getoptions()));

  t.listoptions();

  t.writexpm();
  t.writeps();
  t.done();
  return T;
}
