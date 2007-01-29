# profilefittergui.g: Secondary GUI for imageprofilefitter.g
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003,2004
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
#   $Id: profilefittergui.g,v 19.6 2004/08/25 01:00:34 cvsmgr Exp $
#
# Emits events  
#
# Event            Value                     Meaning
# done               -                       when this subsequence has been doned
# fit                                        User user wants to do a fit. 
#               rec.estimate                 The estimate (componentlist) of the fit
#               rec.nmax
#                                            which parameter is fixed (fpw)
# replot          F/T                        Replot data or all plots
# autoestimate    rec.nmax                   Get autoestimate, plot it and fill in
#                 rec.xunit
#                 rec.yunit
#                 rec.doppler
#
# evaluate      model container              Evaluate and add to plot
# plotmenuselect                             User selected something in plot menu
# clipboard                                  User pressed 'copy' to clipboard
# add                                        User pressed 'add' to internal store
# saveplot      rec.filename                 Save data, model, fit to file
#                  .ascii
# abs pixel coordinates are 1-rel
# The model container is
#
#                         Optional
# xabs                       N
# xunit                      N
# yunit                      N
# doppler                    Y
# nmax                       Y
# elements                   N
#         .type              N
#         .parameters        N
#         .errors            Y
#         .fixed             Y 
#

pragma include once
include 'imageprofilesupport.g'
include 'clipboard.g';
include 'os.g';
include 'printer.g';
include 'specfitcompgui.g'
include 'coordsys.g';
include 'quanta.g';
include 'note.g';
include 'widgetserver.g';
include 'serverexists.g';
include 'unset.g';


const profilefittergui := subsequence (ref csys, shp, axis, ncomp=1, bunit='Jy', 
                                       hasdone=T, hasdismiss=F, plotter=unset, 
                                       widgetset=dws)
{
   if (!have_gui()) {
      return throw('No Gui is available, possibly the  DISPLAY environment variable is not set',
                   origin='profilefittergui.g');
   }
#
    if (!serverexists('dq', 'quanta', dq)) {
       return throw('The quanta server "dq" is not running',
                     origin='profilefittergui');
    }
#
   its := [=];
#
   its.ips := [=];               # Imageprofilesupport
   its.csys := [=];              # Coordinate system (a copy)
   its.bunit := bunit;           # Brightness unit
   its.doppler := '';            # Current doppler (not stored in parameters GUI)
   its.xabs := T;                # Current abs/rel (not stored in parameters GUI)
   its.shape := shp;             # Shape of parent image
#
   its.plotmenu := [=];          # Hold things for 'Plot' menu in menubar
#              [idx]
#                   .label
#                   .items
#                   .widget
#
   its.paxis := axis;            # Pixel axis of profile
   its.waxis := -1;              # World axis of profile
   its.w2p := [];                # Maps world to pixel axes in CS
   its.p2w := [];                # Maps pixel to world axes in CS
#
   its.msg := [=];               # Message line widget
   its.enabled := T;
#
   its.busy := [=];
   its.busy['estimate'] := F;
   its.busy['fit'] := F;
#
   its.gewidth := 15;
   its.ge := widgetset.guientry(width=its.gewidth);
   if (is_fail(its.ge)) fail;
#
   its.widths := [5, 15+its.gewidth, 3, 11, 11];
                                 # Widths for entry widgets: flux, estimate, fixed, fit, error
#
   its.sfcg := [=];              # The GUI holding just the components stuff
#
   its.printer := printer();
   if (is_fail(its.printer)) fail;
   its.plotcounter := 0;         # How many plots have we saved to disk ?
#


### Private functions

###
   const its.checkModel := function (rec)
   {
      if (!has_field(rec, 'elements') ||
          !has_field(rec, 'xunit') ||
          !has_field(rec, 'yunit')) {
         return throw ('Model is missing primary fields', 
                       origin='profilefittergui.checkModel');
      }   
#
      if (dq.compare(rec.xunit, 'm/s')) {
         if (!has_field(rec, 'doppler')) {
            return throw ('Model is missing doppler field', 
                           origin='profilefittergui.checkModel');
         }
      }
#
      n := length(rec.elements);
      for (i in 1:n) {
         if (!has_field(rec.elements[i], 'type') ||
             !has_field(rec.elements[i], 'parameters')) {
            return throw ('Model is missing secondary fields', 
                          origin='profilefittergui.checkModel');
         }
      }      
      return T;
   }


###
   const its.convertModel := function (model, xabsout, xunitout, yunitout, 
                                       dopplerout)
   {
      wider its;
#
      outModel := model;
      outModel.xunit := xunitout;
      outModel.xabs := xabsout;
      outModel.yunit := yunitout;
      outModel.doppler := dopplerout;
#
      coordIn := its.csys.referencevalue();
      nAxes := length(coordIn);
#
      absIn := array(T, nAxes);
      absOut := absIn;
#
      unitsIn := its.csys.units();
      unitsIn[its.waxis] := model.xunit;
      unitsOut := unitsIn;
      unitsOut[its.waxis] := outModel.xunit;
#
      dopplerIn := 'radio';
      if (has_field(model, 'doppler')) dopplerIn := model.doppler;
      dopplerOut := outModel.doppler;
#
      const n := length(model.elements);
      for (i in 1:n) {
         t := to_upper(model.elements[i].type);
         if (t=='GAUSSIAN') {
            pars := model.elements[i].parameters;
            hasErrors := has_field(model.elements[i], 'errors');

# Flux and error (scale factor)

            if (model.yunit != outModel.yunit) {
               q1 := dq.quantity(pars[1], model.yunit);
               q2 := dq.convert(q1, outModel.yunit);
               outModel.elements[i].parameters[1] := dq.getvalue(q2);
               fac := abs(outModel.elements[i].parameters[1] / pars[1]);
#
               if (hasErrors) {
                  outModel.elements[i].errors[1] *:= fac;
               }
            }

# Position and error (not just a scale factor)

            if (!(model.xunit==outModel.xunit &&
                  model.xabs==outModel.xabs &&
                  dopplerIn==dopplerOut)) {

               absIn[its.waxis] := model.xabs;
               absOut[its.waxis] := outModel.xabs;
               coordIn[its.waxis] := pars[2];
               coordOut := its.csys.convert (coordIn, 
                                             absIn, dopplerIn, unitsIn,
                                             absOut, dopplerOut, unitsOut,
                                             its.shape);
               outModel.elements[i].parameters[2] := coordOut[its.waxis];     
#
               if (hasErrors) {
                  coordIn[its.waxis] := pars[2] + model.elements[i].errors[2];
                  coordOut := its.csys.convert (coordIn, 
                                                absIn, dopplerIn, unitsIn,
                                                absOut, dopplerOut, unitsOut,
                                                its.shape);
                  outModel.elements[i].errors[2] := 
                      abs(coordOut[its.waxis] - outModel.elements[i].parameters[2]);
               }

# Width (scale factor)

               absIn[its.waxis] := F;
               absOut[its.waxis] := F;
               coordIn[its.waxis] := pars[3];
               coordOut := its.csys.convert (coordIn, 
                                             absIn, dopplerIn, unitsIn,
                                             absOut, dopplerOut, unitsOut,
                                             its.shape);
               outModel.elements[i].parameters[3] := abs(coordOut[its.waxis]);
#
               if (hasErrors) {
                  fac := abs(outModel.elements[i].parameters[3] / pars[3]);
                  outModel.elements[i].errors[3] *:= fac;
               }
#
               if (hasErrors) {
                  outModel.elements[i].errors[1] *:= 
                     abs(outModel.elements[i].parameters[1] / pars[1]);
               }
            }
         } else {
            print 'unrecognized component type'
         }
      }
#
      return outModel;
   }

###
    const its.generateFileName := function (table=F)
    {
      wider its;
      its.plotcounter +:= 1;
#      
      ext := '.ps';
      if (table) ext := '.plot';
      base := 'profilefitter';
      name := spaste(base, '.',
                     split(dq.time(dq.quantity('today'),
                           form="dmy local"), '/')[1], 
                     '_', its.plotcounter, ext);
#
      note (spaste('Creating file ', name),
            priority='NORMAL', origin='profilefittergui.generateFileName');
#
      if (dos.fileexists(name)) {
         note (spaste('Removing pre-existing file ', name),
               priority='WARN', origin='profilefittergui.generateFileName');
        ok := dos.remove(name);
        if (is_fail(ok)) fail;
      }
#
      return name;
    }


###
   const its.getExtras := function (ref r)
   {
      wider its;
#
      if (!has_field(r, 'xabs'))     r.xabs := its.xabs;
      if (!has_field(r, 'xunit'))    r.xunit :=  its.ips.getabcissaunit();
      if (!has_field(r, 'yunit'))    r.yunit := its.bunit;
      if (!has_field(r, 'doppler'))  r.doppler := its.doppler;
      if (!has_field(r, 'nmax'))     r.nmax := its.sfcg.ncomponents();
      if (!has_field(r, 'baseline')) r.baseline := its.f0.f0.f0.baseline.getvalue();
#
      return T;
   }



###
   const its.interactiveEstimate := function (type, color=7)
   {
      wider its;
#
      self.insertmessage ('Put cursor at line center & click (any)');
      rv := its.csys.referencevalue(format='n');
      wxy := its.ips.getxy(color=color);
      self.insertmessage ('Put cursor at line HWHM & click (any)');
      wx := 2 * abs(its.ips.getx(color=color) - wxy[1]);

# Create container

      r := [=];
      r.xunit := its.ips.getabcissaunit();
      r.xabs := its.ips.getisabs();
      r.yunit := its.ips.getordinateunit();
      r.doppler := its.ips.getdoppler();
      r.elements := [=];
      r.elements[1].type := type;
      r.elements[1].parameters := [wxy[2], wxy[1], wx];
#
      return r;      
   }

###
   its.updateEstimateAndFit := function (xunit=unset)
#
# When units or abs/rel change, update values
# in estimates and fit
#
   {
      wider its;

# Get estimate and fit.  

      est := self.getestimate();
      if (is_fail(est)) fail;
#
      fit := self.getfit();
      if (is_fail(fit)) fail;
# 
      its.sfcg.clearestimate();
      its.sfcg.clearfit();

# Update fitter parameter entry unit menus. Must do this
# first so that the insert steps don't attempt to convert
# the units again (the quantumentry widget will do this)

      if (!is_unset(xunit)) {
        its.sfcg.setposunit(xunit);
        its.sfcg.setwidthunit(xunit);
      }
      if (length(est)==0) return T;              # No estimate yet

# Insert 

      ok := T;
      if (length(est)>0) {
         ok := self.insertestimate(est);
         if (is_fail(ok)) fail;
      }
      if (length(fit)>0) {
         ok := self.insertfit(fit);
      }
      return ok;
   }



### Public functions

###
   const self.addplot := function (ordinate, mask=unset, ci=1, autoscale=T, which=unset)
   {
      return its.ips.setordinate (data=ordinate, mask=mask, ci=ci, which=which);
   }

###
   const self.setplot := function (pos, ordinate, mask=unset, ci, unit, which)
   {
      its.ips.setnoprofile();
#
      ok := its.ips.makeabcissa (pos);
      if (is_fail(ok)) fail;
#
      its.ips.setordinateunit(unit);
      if (is_fail(ok)) fail;
#
      return its.ips.setordinate (data=ordinate, mask=mask, ci=ci, which=which);
   }

###
   const self.plot := function (xautoscale=F, yautoscale=T, which=unset)
   {
      return its.ips.plot(xautoscale=xautoscale, yautoscale=yautoscale, 
                          which=which);
   }


###
   const self.addplotmenucheckmenu := function (label, items, states)
   {
      wider its;
#
      if (!has_field(its.plotmenu, label)) {
         its.plotmenu[label] := [=];
         its.plotmenu[label].items := items;
         its.plotmenu[label].widget := widgetset.checkmenu(its.f0.menubar.plot, 
                                                           label=label,
                                                           names=items);
         if (is_fail(its.plotmenu[label].widget)) fail;
         for (i in 1:length(states)) {
            its.plotmenu[label].widget.selectindex(i,states[i]);
         }
#
         whenever its.plotmenu[label].widget->select do {
            self->plotmenuselect($value);
         }
     }
   }

###
   const self.clearandresetplot := function ()
   {  
      wider its;
      its.ips.setnoprofile();
      return its.ips.clearplotter();
   }


###
   const self.clearplot := function ()
   {  
      wider its;
      return its.ips.clearplotter();
   }


###
   const self.disable := function ()
   {
      wider its;
      if (its.enabled) {
         its.f0->disable();
         its.enabled := F;
      }
      return T;
   }


###
   const self.done := function ()
   {
      wider its;
      wider self;
#
      self->done();
#
      its.ge.done();
      its.sfcg.done();
      its.msg.done();
      its.csys.done();
      its.printer.done();
      its.ips.done();
      its.saveplot.done();
#
      val its := F;
      val self := F;
      return T;
   }

###
   const self.enable := function ()
   {
      wider its;
      if (!its.enabled) {
        its.f0->enable();
        its.enabled := T;
      }
      return T;
   }

###
   const self.getabcissa := function ()
   {
      return [values=its.ips.getabcissa(), 
              unit=its.ips.getabcissaunit(),
              doppler=its.ips.getdoppler()];
   }

###
   const self.getestimate := function ()
   {
      r := its.sfcg.getestimate();
      if (is_fail(r)) fail;
      if (length(r)==0) return r;         # No estimate yet
#
      its.getExtras(r);
#
      return r;
   }

###
   const self.getfit := function ()
#
# xunit   
# yunit
# doppler
# elements
#         .type
#         .parameters
#         .errors
#
   {
      r := its.sfcg.getfit();
      if (is_fail(r)) fail;
#
      its.getExtras(r);
#
      return r;
   }


###
   const self.getplotmenucheckstate := function (label, item)
   {
      wider its;
#
      if (has_field(its.plotmenu, label)) {
         idx := its.plotmenu[label].widget.findname(item);
         state := its.plotmenu[label].widget.getstate(idx);
         return state;
      }
      return F;
   }

###
   const self.gui := function () 
   {
      wider its;
      its.f0->map();
   }

###
   const self.insertestimate := function (estimate, which=unset)
   {
      if (is_fail(its.checkModel(estimate))) fail;

# Work out what units we need to convert the model to.
# The parameter gui is kept in synch with the profile
# plotter

      absout := its.ips.getisabs();
      xunitout := its.ips.getabcissaunit();
      yunitout := its.ips.getordinateunit();
      dopplerout := its.ips.getdoppler();
#
      est2 := its.convertModel (estimate, absout, xunitout, yunitout, dopplerout);
      if (is_fail(est2)) fail;
#     
      return its.sfcg.insertestimate(est2, which);
   }


###
   const self.insertfit := function (fit)
   {
      wider its;
#
      absout := its.ips.getisabs();
      xunitout := its.ips.getabcissaunit();
      yunitout := its.ips.getordinateunit();
      dopplerout := its.ips.getdoppler();
#
      fit2 := its.convertModel (fit, absout, xunitout, yunitout, dopplerout);
      if (is_fail(fit2)) fail;
#
      ok := its.sfcg.insertfit (fit2);
      if (is_fail(ok)) fail;
#
      return fit2;
   }


###
   const self.insertmessage := function (text)
   {
      wider its;
      its.msg->clear();
      its.msg->postnoforward(text);
      return T;
   }

###
   const self.map := function () 
   {
      wider its;
      return its.f0->map();
   }

###
   const self.markmodel := function (model, ci)
#
# No conversions.  This container must have correct x-units
# c.f. the plot
#
   {
      const n := length(model.elements);
      for (i in 1:n) {
         t := to_upper(model.elements[i].type);
         if (t=='GAUSSIAN') {
            pars := model.elements[i].parameters;
            errors := array(0, length(pars));
            if (has_field(model.elements[i], 'errors')) errors := model.elements[i].errors;

# Flux/Position

            its.ips.point (pars[2], pars[1], errors[2], errors[1], 17, ci);

# Width

            its.ips.point (pars[2]-(pars[3]/2), pars[1]/2,
                           errors[3], 0.0, 17, ci);

         } else {
            print 'unrecognized component type'
         }
      }
   }

###
   const self.ncomponents := function ()
   {
      return its.sfcg.ncomponents();
   }

###
   const self.nprofiles := function ()
   {
      return its.ips.nprofiles();
   }

###
   const self.settitle := function (text, ci)
   {
      return its.ips.settitle(text, ci);
   }

###
   const self.setfitbuttonname := function (text)
   {
      return its.f0.f4.fit->text(text);
   }

###
   const self.unmap := function ()
   {
      wider its;
      return its.f0->unmap();
   }

###
   const its.setcoordsys := function (csys)
   {
      wider its;
#
      if (!is_coordsys(csys)) {
         return throw ('Invalid coordinate system provided',
                       origin='profilefittergui.setcoordsys');
      }

# Shutdown old tool

      if (is_coordsys(its.csys)) {
         ok := its.csys.done();
         if (is_fail(ok)) fail;
      }

# New cSys tool

      its.csys := csys.copy();
      const nPixelAxes := its.csys.naxes(world=F);
      if (its.paxis > nPixelAxes) {
         return throw ('Invalid pixel profile axis',
                       origin='profilefittergui.setcoordsys');
      }

# Pull out some often used quantities from the CS

      its.w2p := its.csys.axesmap(toworld=F);    
      its.p2w := its.csys.axesmap(toworld=T);    
      its.waxis := its.p2w[its.paxis];
#
      return T;
   }


###
   const self.setcoordsys := function (csys, shp)
   {
      wider its;

# Install new cSys

      ok := its.setcoordsys(csys);
      if (is_fail(ok)) fail;

# Set new cSys in imageprofilesupport object

      its.shape := shp;             # Shape of parent image
      return its.ips.setcoordinatesystem (its.csys, its.shape);
   }


### Constructor

   ok := its.setcoordsys (csys);
   if (is_fail(ok)) fail;
#
   its.ips := imageprofilesupport (its.csys, its.shape, widgetset);   # Profile support
   if (is_fail(its.ips)) fail;
#
# Set given plotter (e.g. dish plotter) if there is one
#
   if (!is_unset(plotter)) {
      ok := its.ips.setplotter(plotter);
      if (is_fail(ok)) fail;
   }
#
# Top frame
#
   widgetset.tk_hold();
   its.f0 := widgetset.frame(side='top', title='Profile Fitter');
   its.f0->unmap();
   widgetset.tk_release();
#
# Menu  bar
#
   its.f0.menubar := widgetset.frame(its.f0, side='left',
                                     relief='raised', expand='x');
#
# File menu
#
   its.f0.menubar.file  := widgetset.button(its.f0.menubar, type='menu',
                                            text='File', relief='flat');
   t := widgetset.resources('button', 'dismiss');
   its.f0.menubar.file.dismiss := widgetset.button(its.f0.menubar.file,
                                                   text='Dismiss window', background=t.background, 
                                                   foreground=t.foreground);
   widgetset.popuphelp(its.f0.menubar.file.dismiss, 'Dismiss this window');
   whenever its.f0.menubar.file.dismiss->press do {
      self.unmap();
   }
#
# Plot menu
#
   its.f0.menubar.plot := widgetset.button(its.f0.menubar, type='menu',
                                           text='Plot', relief='flat');
#
# Help menu
#
   its.f0.menubar.spacer := widgetset.frame(its.f0.menubar, expand='x',   
                                             height=1);
   its.f0.menubar.help := 
      widgetset.helpmenu(parent=its.f0.menubar,
                         menuitems="Imageprofilefitter Image",
                         refmanitems=['Refman:imageprofilefitter', 'Refman:images'],
                         helpitems=['about the imageprofilefitter','about images']);
#
# Embed plotter
#
   its.f0.f0 := widgetset.frame(its.f0, side='top', relief='raised');
   ok := its.ips.makeplotter (its.f0.f0, size=[310,240]);
   if (is_fail(ok)) fail;
#
# Add plotter control menus
#
   its.f0.f1 := widgetset.frame(its.f0, side='left', expand='none');
#
#   its.f0.f1.saveplot := widgetset.button(its.f0.f1, 'Save');
#   widgetset.popuphelp (its.f0.f1.saveplot, 'Save the plot commands into a Table');
#   whenever its.f0.f1.saveplot->press do {
#      fileName := its.generateFileName(table=T)
#      its.ips.plotfile (fileName);
#   }
#
   include 'filesavergui.g';
   its.f0.f1.saveplot := widgetset.button(its.f0.f1, 'Save');
   its.saveplot := filesavergui();
   its.saveplot.insertfilename ('profiles.txt');
   widgetset.popuphelp (its.f0.f1.saveplot, 'Save the data, estimate, and fit into a file');
   whenever its.f0.f1.saveplot->press do {
      its.saveplot.gui();
   }
   whenever its.saveplot->go do {
      self->saveplot ($value);
   }
#
   its.f0.f1.printplot := widgetset.button(its.f0.f1, 'Print');
   widgetset.popuphelp (its.f0.f1.printplot, 'Print the plot');
   whenever its.f0.f1.printplot->press do {
      fileName := its.generateFileName(table=F);
      its.ips.postscript (fileName, T, T);
      its.printer.gui(files=fileName);
   }
#
   its.f0.f1.spacer0 := widgetset.frame(its.f0.f1, expand='x',   height=1, width=40);
   its.f0.f1.replotdata := widgetset.button(its.f0.f1, 'Replot Data');
   widgetset.popuphelp (its.f0.f1.replotdata, 'Replot just the data profile');
   whenever its.f0.f1.replotdata->press do {
      self->replot(F);
   }
   its.f0.f1.replotall := widgetset.button(its.f0.f1, 'Replot All');
   longTxt := spaste ('  From the "Plot" menu on the menubar, you can select\n',
                      '  which profiles you wish to see.  The data profile is\n',
                      '  always plotted.  When you press this button, the \n',
                      '  selected profiles are replotted');
   widgetset.popuphelp (its.f0.f1.replotall, longTxt, 'Replot the selected profiles', combi=T);
   whenever its.f0.f1.replotall->press do {
      self->replot(T);
   }
#
   its.f0.f1.space0 := widgetset.frame(its.f0.f1, height=1, expand='x', width=40);
   ok := its.ips.setprofileaxis(its.paxis);
   if (is_fail(ok)) fail;
   ok := its.ips.makemenus (its.f0.f1);
   if (is_fail(ok)) fail;
   its.doppler := its.ips.getdoppler();
   its.xabs := its.ips.getisabs();

# We can't yet handle reference frame changes in the fitter, so disable this possibility

   ok := its.ips.disablespectralrefmenu();
   if (is_fail(ok)) fail;
#
# Add component selection GUI
#
   its.f0.f2 := widgetset.frame(its.f0, side='top', relief='raised', expand='x');
   posunits := its.ips.getabcissaunit();
   widthunits := its.ips.getabcissaunit();
   units := its.ips.getabcissaunits();
   unitwidth := max(strlen(units));
   its.sfcg := specfitcompgui (its.f0.f2, ncomp, its.bunit, posunits,
                               widthunits, 
                               fluxunitwidth=unitwidth, 
                               posunitwidth=unitwidth, 
                               widthunitwidth=unitwidth, 
                               widgetset=widgetset);

   if (is_fail(its.sfcg)) fail;
#
   whenever its.sfcg->getinterestimate do {

# Get locations

     which := $value.which;
     type := $value.type;
     est := its.interactiveEstimate(type);
     if (is_fail(est)) {
        note (est::message, priority='SEVERE',
              origin='profilefittergui.g');
     } else {

# Insert into GUI

        self.insertestimate(est, which);

# Send out evaluation and plot request.

        self->evaluate(est);
      }
      self.insertmessage('Make estimate and then fit');
   }

# User entered something in estimate and hit CR
# so we need to re-evaluate and plot

   whenever its.sfcg->estimateCR do {

# Get locations

     est := self.getestimate();
     if (is_fail(est)) {
        note (est::message, priority='SEVERE',
              origin='profilefittergui.g');
     } else {

# Send out evaluation and plot request.

        self->evaluate(est);
      }
   }
#
   whenever its.ips->unitchange do {
      its.updateEstimateAndFit($value);
   }
   whenever its.ips->absrelchange do {
      its.updateEstimateAndFit();
      its.xabs := its.ips.getisabs();
   }
   whenever its.ips->dopplerchange do {
      its.updateEstimateAndFit();
      its.doppler := its.ips.getdoppler();
   }
#
# Frame for extra things
#
   its.f0.f3 := widgetset.frame(its.f0, side='left', relief='raised', expand='x');
#
   its.f0.f3.f0 := widgetset.frame(its.f0.f3, side='left', relief='flat', expand='x');
   its.f0.f3.f0.label := widgetset.label (its.f0.f3.f0, 'Baseline ');
   longTxt := 'You may include a baseline in the fit by selecting the order here';
   widgetset.popuphelp (its.f0.f3.f0.label, longTxt, 'Baseline to fit for', combi=T);
   its.f0.f0.f0.baseline := widgetset.optionmenu(its.f0.f3.f0, labels="None 0 1 2 3 4 5 6",
                                                 values=[-1,0,1,2,3,4,5,6]);
   its.f0.f3.f0.fill := widgetset.frame(its.f0.f3.f0, side='left', height=1, expand='x');
#
# Frame for buttons at bottom
#
   its.f0.f4 := widgetset.frame(its.f0, side='left', relief='raised', expand='x');
   its.msg := widgetset.messageline(its.f0.f4, width=40);
   its.f0.f4.space0 := widgetset.frame(its.f0.f4, height=1, width=1, expand='x');
#
   its.f0.f4.add := widgetset.button(its.f0.f4, 'Store')
   longTxt := 'This can be recovered with function imageprofilefitter.getstore';
   widgetset.popuphelp (its.f0.f4.add, longTxt, 'Add estimate & fit to internal store', combi=T);
   whenever its.f0.f4.add->press do {
      self->add();
   }
#
   its.f0.f4.copy := widgetset.button(its.f0.f4, 'Copy')
   widgetset.popuphelp (its.f0.f4.copy, 'Copy estimate & fit to default clipboard tool (dcb)');
   whenever its.f0.f4.copy->press do {
      self->clipboard();
   }
#
   its.f0.f4.autoest := widgetset.button(its.f0.f4, 'Estimate', type='action');
   longTxt := spaste (' This makes an automatic estimate consisting of N \n',
                      ' gaussians, where N is the number of components you\n',
                      ' have specified with the slider');
   widgetset.popuphelp (its.f0.f4.autoest, longTxt, 'Make an estimate for the profile', combi=T);
   whenever its.f0.f4.autoest->press do {
      if (!its.busy['estimate']) {
         its.busy['estimate'] := T;
         self.disable();
#
         r := [=];
         its.getExtras(r);
         self->autoestimate(r);
#
         self.enable();
         its.busy['estimate'] := F;
      }
   }
#
   its.f0.f4.fit := widgetset.button(its.f0.f4, text='Fit profile', 
                                     width=9, type='action');
   longTxt := spaste(' This will activate the simultaneous fit of \n',
                     ' the specified number of components. \n\n',
                     ' When this button says "Fit Profile", just the\n',
                     ' plotted profile is fitted.\n\n',
                     ' When this button says "Fit Region", all the \n',
                     ' profiles in the region you selected on the \n',
                     ' primary GUI are fit and images of the fit and \n',
                     ' model are written out');
   widgetset.popuphelp(its.f0.f4.fit, longTxt, 'Compute fit', combi=T, width=100);
#
   if (hasdismiss) {
      its.f0.f4.dismiss := widgetset.button(its.f0.f4, text='Dismiss', type='dismiss');
      widgetset.popuphelp(its.f0.f4.dismiss, 'Dismiss this GUI');
      whenever its.f0.f4.dismiss->press do {
         self.unmap();
      }
   }
#
   if (hasdone) {
      its.f0.f4.done := widgetset.button(its.f0.f4, text='Done', type='halt');
      widgetset.popuphelp(its.f0.f4.done, 'Destroy this GUI');
      whenever its.f0.f4.done->press do {
         self.done();
      }
   }
#
# User has pressed fit, send out event that we wish to do the fit
# with the current estimate in hand
#
   whenever its.f0.f4.fit->press do {
      if (!its.busy['fit']) {
         its.busy['fit'] := T;
         rec := self.getestimate();
         if (is_fail(rec)) {
            note(rec.estimate::message, priority='SEVERE',
                 origin='profilefittergui.g');
         } else {
            self->fit(rec);
         }
         its.busy['fit'] := F;
      }
   }
#
# Initial message
#
   self.insertmessage('Make estimate and then fit');
#
# We defer this whenever because otherwise it will be activated
# during the construction of the GUI
#
   whenever its.f0->resize do {
      self->replot(T);
   }
}
