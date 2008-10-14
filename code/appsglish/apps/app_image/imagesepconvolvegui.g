# imagesepconvolvegui.g: GUI for image::sepconvolve
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001
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
#   $Id: imagesepconvolvegui.g,v 19.2 2004/08/25 00:59:54 cvsmgr Exp $
#
#
 
pragma include once

include 'messageline.g'
include 'note.g'
include 'helpmenu.g'
include 'widgetserver.g'
include 'separableconvolutiongui.g'
include 'image.g'
include 'unset.g'
include 'coordsys.g'


const imagesepconvolvegui := subsequence (ref parent=F, imageobject, widgetset=dws)
{
   if (!have_gui()) {
      return throw('No Gui is available, possibly the  DISPLAY environment variable is not set',
                   origin='imagesepconvolvegui.g');
   }
   if (!is_image(imageobject)) {
      return throw('The value of the "image" variable is not a valid image object',
                    origin='imagesepconvolvegui.g');
   }
#
   prvt := [=];
   prvt.ge := widgetset.guientry();         # GUI entry server
   if (is_fail(prvt.ge)) fail;
   prvt.standalone := (is_boolean(parent) && parent==F);
#
   prvt.image.object := [=];       # Image object. Don't done it
   prvt.image := [=];              # The image stuff
   prvt.image.csys := [=];         # The coordinate system tool



### Constructor

   prvt.image.object := imageobject;
   prvt.image.csys := prvt.image.object.coordsys();
   if (is_fail(prvt.image.csys)) fail;
#
   tk_hold();
   title := spaste('sepconvolve(', prvt.image.object.name(strippath=F), ')');
   prvt.f0 := widgetset.frame(parent, expand='x', side='top', 
                              relief='raised', title=title);
   prvt.f0->unmap();
   tk_release();
   whenever prvt.f0->resize do {
      self->resize();
   }
#
   if(prvt.standalone) {
     prvt.f0.menubar := widgetset.frame(prvt.f0, side='left', relief='raised',
					expand='x');
     prvt.f0.menubar.file  := widgetset.button(prvt.f0.menubar, type='menu', 
					       text='File', relief='flat');
     prvt.f0.menubar.file.dismiss := widgetset.button(prvt.f0.menubar.file,
                                                   text='Dismiss Window', type='dismiss');
     prvt.f0.menubar.file.done := widgetset.button(prvt.f0.menubar.file,
                                                   text='Done', type='dismiss');
     helptxt := spaste('- dismiss window, preserving state\n',
                       '- destroy window, destroying state');
     widgetset.popuphelp(prvt.f0.menubar.file, helptxt, 'Menu of File operations', combi=T);
#
     whenever prvt.f0.menubar.file.done->press do {
       self->exit();
       self.done();
     }
     whenever prvt.f0.menubar.file.dismiss->press do {
       prvt.f0->unmap();
     }
#
     prvt.f0.menubar.spacer := widgetset.frame(prvt.f0.menubar, expand='x',
                                               height=1);
#   
     prvt.f0.menubar.help := widgetset.helpmenu(parent=prvt.f0.menubar,
                              menuitems="Image SeparableConvolution SeparableConvolutionGUI",
                              refmanitems=['Refman:images.image', 'Refman:images.image.sepconvolve',
                                           'Refman:images.image.sepconvolvegui'],
                              helpitems=['about Images', 'about separable convolution', 'about separable convolution GUI']);
   }
#
# Region
#
   labWidth := 15;
   prvt.f0.f0 := widgetset.frame(prvt.f0, side='left');
   prvt.f0.f0.label := widgetset.label(prvt.f0.f0, text='Region', width=labWidth);
   widgetset.popuphelp(prvt.f0.f0.label, 'Enter region of interest');
   prvt.f0.f0.region := prvt.ge.region(parent=prvt.f0.f0, allowunset=T);
#
# Convolution GUI
#
   prvt.f0.smooth := separableconvolutiongui(prvt.f0, names=prvt.image.csys.names(),
                                             axes=[1:length(prvt.image.csys.names())],
                                             widgetset=widgetset);
#
# Set a default output file name.  Because we don't pass the output
# image tool on to the user, we must have a physical file name
#
   rec := [=];
   rec.outfile := spaste(prvt.image.object.name(strippath=F), '.sepcon');
   prvt.f0.smooth.setstate(rec);
#
# Go, reset and dismiss
#
   if (prvt.standalone) {
      prvt.f0.f1 := widgetset.frame(prvt.f0, side='left', expand='x',
                                    relief='raised');
      prvt.f0.f1.go := widgetset.button(prvt.f0.f1, text='Go',
                                        type='action');
      prvt.f0.f1.space := widgetset.frame(prvt.f0.f1, width=1, height=1, expand='x')
      prvt.f0.f1.reset := widgetset.button(prvt.f0.f1, text='Reset',
                                           type='action')
      widgetset.popuphelp(prvt.f0.f1.reset, 'Reset GUI');
      whenever prvt.f0.f1.reset->press do {
        self.reset();
      }
      prvt.f0.f1.dismiss := widgetset.button(prvt.f0.f1, text='Dismiss',
                                             type='dismiss');
      widgetset.popuphelp(prvt.f0.f1.dismiss, 'Dismiss Window (preserving state)');
      whenever prvt.f0.f1.dismiss->press do {
        ok := prvt.f0->unmap();
      }
      whenever prvt.f0.f1.go->press do {
        self.go();
      }
  }
#
   ok := prvt.f0->map();
#

###
   const self.done := function ()
   {
      wider prvt, self;
      prvt.f0.f0.region.done();
      prvt.f0.smooth.done();
      prvt.ge.done();
      prvt.image.csys.done();
#
# If this first line is not explicitly here, the outer
# frame does not go away.  Something is maintaining
# a reference somewhere that i cant find.
#
      val prvt.f0 := F;
      val prvt := F;
      val self := F;
      return T;
   }

###
   const self.gui := function ()
   {
      prvt.f0->map();
      return T;
   }


###
   const self.setimage := function (imageobject)
   {
      wider prvt;
      if (!is_image(imageobject)) fail;
#
# Set image object
#
      widgetset.tk_hold();
      prvt.image.object := imageobject;
      if (is_coordsys(prvt.image.csys)) {
         ok := prvt.image.csys.done();            
         if (is_fail(ok)) fail;
      }
      prvt.image.csys := prvt.image.object.coordsys();
      if (is_fail(prvt.image.csys)) fail;
#
# Set title
#
      title := spaste('sepconvolve (', prvt.image.object.name(strippath=F), ')');
      prvt.f0->title(title);
#
# Convolution
#
      if (has_field(prvt.f0, 'smooth')) prvt.f0.smooth.done();
      if (prvt.standalone) prvt.f0.f1->unmap();
      prvt.f0.smooth := separableconvolutiongui(prvt.f0, names=prvt.image.csys.names(),
                                                axes=[1:length(prvt.image.csys.names())],
                                                widgetset=widgetset);
      rec := [=];
      rec.outfile := spaste(prvt.image.object.name(strippath=F), '.sepcon');
      prvt.f0.smooth.setstate(rec);
      if (prvt.standalone) prvt.f0.f1->map();
      widgetset.tk_release();
#
      return T;
   }



###
   const self.getstate := function (check=T)
#
# Get the state of the GUI.  Optionally check values
# for validity.  Only smoothing and data selection
# rollups are potentially disabled at this point
#
   {
      rec := [=];
#
# Region
#
      tmp := prvt.f0.f0.region.get();
      if (check) {
         if (is_fail(tmp)) {
            note ('The region is illegal', priority='WARN',
                  origin='imagesepconvolvegui.getstate');
            return F;
         }                 
      }
      rec.region := tmp;
#
# Smoothing
#
      rec.axes := [];
      rec.types := "";
      rec.widths := "";
      rec.outfile := '';
#
      smooth := prvt.f0.smooth.getstate(check);
      if (check && is_boolean(smooth) && smooth==F) return F;
#
      j := 0;
      fieldNames := field_names(smooth.kernels);
      for (i in fieldNames) {
         if (smooth['kernels'][i]['check']==T) {
            j +:= 1;
            rec.axes[j] := as_integer(i);
            rec.types[j] := smooth['kernels'][i]['type'];
            rec.widths[j] := smooth['kernels'][i]['width'];
         }
      }
      if (j==0) {
         note ('You have not specified any convolution parameters', priority='WARN',
                  origin='imagesepconvolvegui.getstate');
         return F;
      }
#
      rec.outfile := smooth.outfile;
      if (check) {
        if (is_unset(rec.outfile) || strlen(rec.outfile)==0) {
           note ('You must give the output file name', 
                  origin='imagesepconvolvegui.getstate');
           return F;
        }
      }
#
      rec.async := F;
      return rec;
   }



###
   const self.reset := function ()
   {
      wider prvt;
#
# Insert an unset region
#
      prvt.f0.f0.region.insert(unset);
#
# Reset convolution
#
      prvt.f0.smooth.reset();
#
      return T;   
   }


###
   const self.setstate := function (rec)
   {
      wider prvt;
      self.reset();
      if (has_field(rec, 'region')) {
         prvt.f0.f0.region.insert(rec.region);
      }
#
      if (has_field(rec, 'axes') &&
          has_field(rec, 'types') &&
          has_field(rec, 'widths')) {
         n1 := length(rec.axes);
         n2 := length(rec.types);
         n3 := length(rec.widths);
#
         if (n1==n2 && n1==n3 && n1>0) {
            rec2 := [=];  
            rec2.kernels := [=];
            rec2.outfile := '';
#
            for (i in 1:n1) {  
               fN := as_string(rec.axes[i]);
               rec2.kernels[fN] := [=];
               rec2.kernels[fN]['check'] := T;
               rec2.kernels[fN]['type'] := rec.types[i];
               rec2.kernels[fN]['width'] := rec.widths[i];
            }
         }
         rec2['outfile'] := rec.outfile;
         prvt.f0.smooth.setstate(rec2);
      }
#
      if (has_field(rec, 'async')) {
      }
#
      return T;
   }


###
   const self.go := function (rec=[=], async=F)
   {
#
# Get the parameters and see if they are good.
#
      if (length(rec)==0) rec := self.getstate(T);
      if (is_boolean(rec) && rec==F) return F;
      if (async) {
         async.rec := T;
      } else {
         async.rec := F;
      }
#
# Final check on fields, as some idiot might give us 
# a useless record.  
#
      local ok;
      if (has_field(rec, 'region') && 
          has_field(rec, 'axes') && 
          has_field(rec, 'types') && 
          has_field(rec, 'widths') && 
          has_field(rec, 'outfile') && 
          has_field(rec, 'async')) {
         if (!rec.async) prvt.f0->disable();
         ok := prvt.image.object.sepconvolve(region=rec.region,
                                             axes=rec.axes,
                                             types=rec.types, 
                                             widths=rec.widths,
                                             outfile=rec.outfile,
                                             async=rec.async);
         if (!rec.async) prvt.f0->enable();
         if (is_fail(ok)) {
            note (spaste('Failed to run function because ', ok::message),
                  origin='imagesepconvolvegui.go', priority='SEVERE');
            return F;
         }
#
# sepconvolve returns an image tool.  because we are not
# passing this on to the user in this interface, done it
# so that it is not tied up
#
         if (is_image(ok)) ok.done();
      } else {
         note ('The supplied record is invalid', 
               priority='WARN', origin='imagesepconvolvegui.go');
         return F;
      }
      return T;
   }
}
