# specfitcompgui.g: 
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
#   $Id: specfitcompgui.g,v 19.2 2004/08/25 01:01:30 cvsmgr Exp $
#
#
# Events:
#    getinterestimate ([which,type])
#    done
#
pragma include once


include 'coordsys.g';
include 'fitterparameters.g'
include 'illegal.g';
include 'note.g';
include 'serverexists.g';
include 'unset.g';
include 'widgetserver.g';

 const specfitcompgui := subsequence (parent, n=1, fluxunits, posunits, widthunits, 
                                      fluxunitwidth, posunitwidth, widthunitwidth,
                                      widgetset=dws)
{
   if (!have_gui()) {
      return throw('No Gui is available, possibly the  DISPLAY environment variable is not set',
                   origin='spectralfittergui.g');
   }
#
   its := [=];
#
   its.enabled := T;
#
   its.hasEstimate := F;         # Has an estimate been inserted into the GUI ?
   its.hasFit := F;              # Has a fit been inserted into the GUI ?
   its.scale := [=];             # No. of components scale
   its.frames := [=];            # Where all the component frames go
   its.tab := [=];               # tabdialog widget
   its.tabframe := [=];
   its.n := n;                   # Number components
   its.type := [=];              # Model types of all components
   its.fluxunits := fluxunits;
   its.posunits := posunits;
   its.widthunits := widthunits;
   its.fluxunitwidth := fluxunitwidth;    # Width of optionmenu units for estimate quantum entry
   its.posunitwidth := posunitwidth;      # Width of optionmenu units for estimate quantum entry
   its.widthunitwidth := widthunitwidth;  # Width of optionmenu units for estimate quantum entry
#
   its.ge := widgetset.guientry();
   if (is_fail(its.ge)) fail;
#
   its.fp := fitterparameters(widgetset=widgetset);   # Tool to make parameter entries
   if (is_fail(its.fp)) fail;
   whenever its.fp->estimateCR do {            # User typed something in
      self->estimateCR($value);                # in estimate fields
   }
#
                                 # Widths for entry widgets: label, estimate, fixed, fit, error
   its.widths := [5, 15, 3, 13, 13];


### Private functions

###
   const its.getonefixed := function (which)
   {
      wider its;
      fn := spaste(which);
      type := its.type[fn];
#
      fixed := [F,F,F];
      if (its.fp.getfixed(its.frames[fn].f1.pars.flux))  fixed[1] := T;
      if (its.fp.getfixed(its.frames[fn].f1.pars.pos))   fixed[2] := T;
      if (its.fp.getfixed(its.frames[fn].f1.pars.width)) fixed[3] := T;
#
      return fixed;
   }


###
   const its.makeOneFrame := function (i)
#
# Make the GUI for one component
#
   {
      wider its;
      fn := spaste(i);
      its.frames[fn] := widgetset.frame(its.tabframe, side='top', relief='raised');
      its.frames[fn]->unmap();
#
# Frame for buttons at top
#
      its.frames[fn].f0 := widgetset.frame(its.frames[fn], side='left', relief='flat');
#
# Select component type
#
      its.frames[fn].f0.f0 := widgetset.frame(its.frames[fn].f0, side='top', 
                                              relief='flat', expand='none');
      its.frames[fn].f0.f0.l0 := widgetset.label(its.frames[fn].f0.f0, 'Type');
      widgetset.popuphelp(its.frames[fn].f0.f0.l0, 'Select component type');
      types := "Gaussian";
      its.frames[fn].f0.f0.om := widgetset.optionmenu(parent=its.frames[fn].f0.f0, names=types, 
                                                      values=types, labels=types);
      its.frames[fn].f0.f0.om.index := i;
      its.type[fn] := to_upper(its.frames[fn].f0.f0.om.getlabel());
#
# Spacer
#
      its.frames[fn].f0.f1 := widgetset.frame(parent=its.frames[fn].f0, 
                                              height=3, expand='x', relief='flat');
#
# Buttons for estimates. 
#
      its.frames[fn].f0.f2 := widgetset.frame(its.frames[fn].f0, side='top', 
                                              relief='flat', width=1, expand='none');
      its.frames[fn].f0.f2.l0 := widgetset.label(its.frames[fn].f0.f2, 'Estimates');
#
      its.frames[fn].f0.f2.f0 := widgetset.frame(its.frames[fn].f0.f2, width=1, 
                                                 side='left', relief='flat');
      its.frames[fn].f0.f2.f0.intest := widgetset.button(parent=its.frames[fn].f0.f2.f0, 
                                                         text='Inter');
      longTxt := spaste ('  This will activate the cursor so that you can \n',
                         '  select the peak, position and width. Follow the \n',
                         '  instructions in the messageline window');
      widgetset.popuphelp (its.frames[fn].f0.f2.f0.intest, longTxt, 
                           'Make an interactive estimate for this component', combi=T);
      its.frames[fn].f0.f2.f0.clear := widgetset.button(parent=its.frames[fn].f0.f2.f0,
                                                        text='Clear');
      widgetset.popuphelp(its.frames[fn].f0.f2.f0.clear, 'Clear estimate for this component');
#
# Activate interactive estimator for component
#
      whenever  its.frames[fn].f0.f2.f0.intest->press do {
         r := [=];
         r.which := its.tab.which().index;
         fn := spaste(r.which);
         r.type := its.type[fn];            # its.type is a record
         self->getinterestimate(r);
      }
#
# Clear estimate
#
      whenever  its.frames[fn].f0.f2.f0.clear->press do {
         self.clearestimate();
      }
#
# Buttons for fit. 
#
      its.frames[fn].f0.f3 := widgetset.frame(its.frames[fn].f0, side='top', 
                                              relief='flat', width=1, expand='none');
      its.frames[fn].f0.f3.l0 := widgetset.label(its.frames[fn].f0.f3, 'Fits');
#
      its.frames[fn].f0.f3.f0 := widgetset.frame(its.frames[fn].f0.f3, width=1, 
                                                 side='left', relief='flat');
      its.frames[fn].f0.f3.f0.clear := widgetset.button(parent=its.frames[fn].f0.f3.f0,
                                                           text='Clear');
      widgetset.popuphelp(its.frames[fn].f0.f3.f0.clear, 'Clear fit for this component');
#
# Clear fit
#
      whenever  its.frames[fn].f0.f3.f0.clear->press do {
         self.clearfit();
      }
#
# Frame for parameters.  
#
      its.frames[fn].f1 := widgetset.frame(its.frames[fn], side='left', relief='flat');
#
# Align in vertical frames
#
      its.frames[fn].f1.labels := widgetset.frame(its.frames[fn].f1, side='top', relief='flat');
      its.frames[fn].f1.estimates := widgetset.frame(its.frames[fn].f1, side='top', relief='flat');
      its.frames[fn].f1.fixeds := widgetset.frame(its.frames[fn].f1, side='top', relief='flat');
      its.frames[fn].f1.fits := widgetset.frame(its.frames[fn].f1, side='top', relief='flat');
      its.frames[fn].f1.errors := widgetset.frame(its.frames[fn].f1, side='top', relief='flat');
#
      its.frames[fn].f1.labels.labtop := widgetset.label(its.frames[fn].f1.labels, 'Param', 
                                                         width=its.widths[1]);
      its.frames[fn].f1.estimates.labtop := widgetset.label(its.frames[fn].f1.estimates, 'Estimate', 
                                                            width=its.widths[2]);
      its.frames[fn].f1.fixeds.labtop := widgetset.label(its.frames[fn].f1.fixeds, '', width=its.widths[3]);
      its.frames[fn].f1.fits.labtop := widgetset.label(its.frames[fn].f1.fits, 'Fit', width=its.widths[4]);
      its.frames[fn].f1.errors.labtop := widgetset.label(its.frames[fn].f1.errors, 'Error', 
                                                         width=its.widths[5]);
#
# Destroy extant parameter widgets for this component
#
      its.frames[fn].f1.pars := [=];
#
# Create parameters entry/fit/error widgets
#
      its.makeParameters(its.frames[fn].f1.labels,
                         its.frames[fn].f1.estimates,
                         its.frames[fn].f1.fixeds,
                         its.frames[fn].f1.fits,
                         its.frames[fn].f1.errors,
                         'gaussian', its.widths, i);
#
# Add to TAB
#
      its.tab.add(its.frames[fn], fn);
#
# When user selects a new component type, destroy and remake parameters
#
      whenever its.frames[fn].f0.f0.om->select do {
         ag := $agent;
         gn := spaste(ag.index);
         type := to_upper(ag.getlabel());
         if (its.type[gn] != type) {
            widgetset.tk_hold();
            its.fp.cleanquantum(its.frames[gn].f1.pars.flux);
            its.fp.cleanquantum(its.frames[gn].f1.pars.pos);
            its.fp.cleanquantum(its.frames[gn].f1.pars.width);
            its.frames[gn].f1.pars := F;
#
            its.makeParameters(its.frames[fn].f1.labels,
                               its.frames[fn].f1.estimates,
                               its.frames[fn].f1.fixeds,
                               its.frames[fn].f1.fits,
                               its.frames[fn].f1.errors,
                               $value.label, its.widths, ag.index);
            its.tab.replace(its.frames[gn], gn);
            its.tab.front(gn);
            widgetset.tk_release();
#
            its.type[gn] := type;
         }
      }
      return T;
   }

###
   const its.makeParameters := function (ref labels, ref estimates, 
                                         ref fixeds, ref fits, 
                                         ref errors, type, widths, i)
#
# Make entry/fix/fit/error widgets for component i of given type
#
   {
      wider its;
#
      fn := spaste(i);
      t := to_upper(type);
      ok := its.fp.makequantum (labels, estimates, fixeds, fits, errors,
                                its.frames[fn].f1.pars, 'flux', widths,
                                its.fluxunits);
      if (is_fail(ok)) fail;
      ok := its.fp.setestimateunitwidth (its.frames[fn].f1.pars.flux, its.fluxunitwidth);
      if (is_fail(ok)) fail;
#
      ok := its.fp.makequantum (labels, estimates, fixeds, fits, errors,
                                its.frames[fn].f1.pars, 'pos', widths, 
                                its.posunits);
      if (is_fail(ok)) fail;
      ok := its.fp.setestimateunitwidth (its.frames[fn].f1.pars.pos, its.posunitwidth);
      if (is_fail(ok)) fail;
#
      ok := its.fp.makequantum (labels, estimates, fixeds, fits, errors,
                                its.frames[fn].f1.pars, 'width', widths, 
                                its.widthunits);
      ok := its.fp.setestimateunitwidth (its.frames[fn].f1.pars.width, its.widthunitwidth);
      if (is_fail(ok)) fail;

      if (is_fail(ok)) fail;
#
      return T;
   }



### Public functions

###
   const self.clearestimate := function (which=unset)
   {
      wider its;
#
      if (is_unset(which)) {
         which := its.tab.which(); 
      }
#
      fn := spaste(which.index);
      type := its.type[fn];
#
      its.fp.clearestimate(its.frames[fn].f1.pars.flux);
      its.fp.clearestimate(its.frames[fn].f1.pars.pos);
      its.fp.clearestimate(its.frames[fn].f1.pars.width);
#
      its.hasEstimate := F;
#
      return T;
   }

### 
   const self.clearfit := function (which=unset)
   {
      wider its;
#
      local fn;
      if (is_unset(which)) {
         which := its.tab.which(); 
         fn := spaste(which.index);
      } else {
         fn := spaste(which);
      }
      type := its.type[fn];
#
      its.fp.clearfit(its.frames[fn].f1.pars.flux);
      its.fp.clearfit(its.frames[fn].f1.pars.pos);
      its.fp.clearfit(its.frames[fn].f1.pars.width);
#
      its.hasFit := F;
#
      return T;
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
   const self.dismiss := function ()
   {
      its.f0->unmap();
      return T;
   }

###
   const self.done := function ()
   {
      wider its, self;
      self->done();
      its.tab.done();
      its.ge.done();
      its.fp.done();
      its.scale.done();
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
   const self.getestimate := function ()
   {
      r := [=];
      if (!its.hasEstimate) return r;
#
      r.elements := [=];
      for (i in 1:its.n) {
         fn := spaste(i);
         r.elements[i] := [=];
         r.elements[i].type := its.type[fn];
         pars := [];
#
         t := to_upper(its.type[fn]);
         if (t=='GAUSSIAN') {
            f := its.fp.getestimate(its.frames[fn].f1.pars.flux);
            p := its.fp.getestimate(its.frames[fn].f1.pars.pos);
            w := its.fp.getestimate(its.frames[fn].f1.pars.width);
#
            pars[1] := dq.getvalue(f);
            pars[2] := dq.getvalue(p);
            pars[3] := dq.getvalue(w);
         } else {
           note ('This type of component not supported yet',
                 origin='specfitcompgui.getestimate',
                 priority='SEVERE');
         }
         r.elements[i].parameters := pars;

# Get fixed indicators

         r.elements[i].fixed:= its.getonefixed(i);         
      }
#
      r.xunit := its.fp.getestimateunit(its.frames['1'].f1.pars.pos);
      return r;
   }


###
   const self.getfit := function ()
   {
      r := [=];
      if (!its.hasFit) return r;
#
      r.elements := [=];
      for (i in 1:its.n) {
         fn := spaste(i);
         r.elements[i] := [=];
         r.elements[i].type := its.type[fn];
         pars := [];
#
         t := to_upper(its.type[fn]);
         if (t=='GAUSSIAN') {
            f := its.fp.getfit(its.frames[fn].f1.pars.flux);
            p := its.fp.getfit(its.frames[fn].f1.pars.pos);
            w := its.fp.getfit(its.frames[fn].f1.pars.width);
#
            pars[1] := f.value;
            pars[2] := p.value;
            pars[3] := w.value;
            errors[1] := f.error;
            errors[2] := p.error;
            errors[3] := w.error;
         } else {
           note ('This type of component not supported yet',
                 origin='specfitcompgui.getestimate',
                 priority='SEVERE');
         }
         r.elements[i].parameters := pars;
         r.elements[i].errors := errors;
      }
#
      r.xunit := its.fp.getestimateunit(its.frames['1'].f1.pars.pos);
      return r;
   }


###
   const self.getmodeltypes := function ()
   {
      types := array('', its.n);
      for (i in 1:its.n) {
         fn := spaste(i);
         types[i] := its.type[fn];
      }
      return types;
   }


###
   const self.insertestimate := function (estimate, which=unset)
   {
      wider its;
      list := 1:(its.n);
#
      if (is_unset(which)) {

# If the estimate has less components than in the GUI, shrink the GUI

         n := min(length(estimate.elements), its.n);
         list := 1:n;
#
         if (n < its.n) {
            note ('There are fewer elements in the estimate than GUI elements',
                  origin='specfitcompgui.insertestimate', priority='WARN');
            note ('Deleting the excessive GUI elements',
                  origin='specfitcompgui.insertestimate', priority='WARN');
            its.scale.setvalues([n]);
#
            its.f0->disable();
            its.scale.disable();
#
            widgetset.tk_hold();
            for (i in (n+1):its.n) {
              its.tab.delete(spaste(i));
            }
            its.n := n;
            widgetset.tk_release();
            its.scale.enable();
            its.f0->enable();
         }
      } else {
         if (length(estimate.elements) != 1) {
            return throw ('Wrong number of elements in estimate', 
                          origin='specfitcompgui.insertestimate');
         }
         if (which < 1 || which > its.n) {
            return throw ('Wrong elements index specified', 
                          origin='specfitcompgui.insertestimate'); 
         }
         list := which;
      }
#
      xunit := estimate.xunit;
      yunit := estimate.yunit;

# index j indexes the element in the container (always starts at 1)
# index i indexes the element in the GUI we are putting it in

      j := 1;
      for (i in list) {
         fn := spaste(i);
         t := to_upper(estimate.elements[j].type);
#
         if (t=='GAUSSIAN') {
            v := dq.quantity(estimate.elements[j].parameters[1], yunit);
            its.fp.insertestimate(its.frames[fn].f1.pars.flux, v);
#
            v := dq.quantity(estimate.elements[j].parameters[2], xunit);
            its.fp.insertestimate(its.frames[fn].f1.pars.pos, v);
#
            v := dq.quantity(estimate.elements[j].parameters[3], xunit);
            its.fp.insertestimate(its.frames[fn].f1.pars.width, v);
         } else {
            s := spaste(t, ' is an unsupported estimate component type');
            note(s, origin='specfitcompgui.insertestimate', priority='SEVERE');
         }
#
         j +:= 1;
      }
#
      its.hasEstimate := T;
      return T;
   }

###
   const self.insertfit := function (fit)
   {
      wider its;
#
      n := length(fit.elements);
      if (n <  its.n) {
         note ('There are less elements in the fit container than elements in the GUI',
               origin='specfitcompgui.insertfit', priority='WARN');
#
         for (i in n+1:its.n) {
            self.clearfit(which=i);
         }
      }
#
      if (n >  its.n) {
         note ('There are more elements in the fit container than elements in the GUI',
               origin='specfitcompgui.insertfit', priority='WARN');
         note ('Discarding the excess',
               origin='specfitcompgui.insertfit', priority='WARN');
      }
#
      xunit := fit.xunit;
      yunit := fit.yunit;
#
      local errors;
      for (i in 1:n) {
         fn := spaste(i);
         t := to_upper(fit.elements[i].type);
         if (has_field(fit.elements[i], 'errors')) {
            errors := fit.elements[i].errors;
         } else {
            errors := array(0.0, length(fit.elements[i].parameters));
         }
#
         if (t=='GAUSSIAN') {
            v := fit.elements[i].parameters[1];
            its.fp.insertfit(its.frames[fn].f1.pars.flux, v, errors[1]);
#
            v := fit.elements[i].parameters[2];
            its.fp.insertfit(its.frames[fn].f1.pars.pos, v, errors[2]);
#
            v := fit.elements[i].parameters[3];
            its.fp.insertfit(its.frames[fn].f1.pars.width, v, errors[3]);
         } else {
            s := spaste(t, ' is an unsupported component type');
            note(s, origin='specfitcompgui.insertfit', priority='SEVERE');
         }
      }
#
      its.hasFit := T;
      return T;
   }

###
   const self.makeframes := function (parent, n)
   {
      wider its;
      its.n := n;
      widgetset.tk_hold();
#
# Destroy old tabs and make new
#
      if (is_agent(its.tab)) its.tab.done();
      its.tab := widgetset.tabdialog(parent, title=unset);
      its.tabframe := its.tab.dialogframe();
#
# Wipe out all old frames
#
      val its.frames := [=];
#
# Make new frames, unmapping them as they are made
# and adding them to the tabber
#
      for (i in 1:n)  {
         its.makeOneFrame(i);
      }
      widgetset.tk_release();
#
      return T;
   }

###
   const self.ncomponents := function ()
   {
      return its.n;
   }

###
   const self.getposunit := function ()
   {

# Units are the same for all components

     fn := '1';
     return its.fp.getestimateunit (its.frames[fn].f1.pars.pos);
   }

###
   const self.getfluxunit := function ()
   {

# Units are the same for all components

     fn := '1';
     return its.fp.getestimateunit (its.frames[fn].f1.pars.flux);
   }

###
   const self.setposunit := function (unit)
   {
      wider its;
#
      for (i in 1:its.n) {
         fn := spaste(i);
         ok := its.fp.setestimateunit (its.frames[fn].f1.pars.pos, unit,
                                       its.posunitwidth);
         if (is_fail(ok)) fail;
      }
      its.posunits := unit;
#
      return T;
   }

###
   const self.setwidthunit := function (unit)
   {
      wider its;
#
      for (i in 1:its.n) {
         fn := spaste(i);
         ok := its.fp.setestimateunit (its.frames[fn].f1.pars.width, unit,
                                       its.widthunitwidth);
         if (is_fail(ok)) fail;
      }
      its.widthunits := unit;
#
      return T;
   }



### Constructor

#
# Top frame
#
   its.f0 := widgetset.frame(parent, side='top');
#
# Frame for slider
#
   its.f0.f0 := widgetset.frame(its.f0, side='left');
   its.scale := widgetset.multiscale (its.f0.f0, 1, max(5,its.n), 
                                      [its.n], ['No. components'],
                                      entry=T, extend=T, fill='x',
                                      helps=['Set number of components to fit']);
   its.f0.f0.space0 := widgetset.frame(its.f0.f0, height=1, expand='x');
#
# Frame for TAB
#
   its.f0.f1 := widgetset.frame(its.f0, side='left', relief='flat', expand='x');
#
# Initial number of components
#
   self.makeframes(its.f0.f1, its.n);
#
# Update number of components if user fiddles with slider
# Defer until now so that we have  viable tab agent
#
   whenever its.scale->values do {
       its.f0->disable();
       its.scale.disable();
#
       widgetset.tk_hold();
       n := $value[1];
       if (n < 1) {
          note ('You must have at least one component',
                origin='specfitcompgui.g', priority='WARN');
#
          its.scale.setvalues([1]);
          its.scale.setrange(start=1);
          n := 1;
       }
#
       if (n < its.n) {
          for (i in (n+1):its.n) {
             its.tab.delete(spaste(i));
          }
       } else if (n > its.n) {
          for (i in (its.n+1):n) {
             its.makeOneFrame(i);
          }
       }
#
       its.n := n;
       its.scale.enable();
       its.f0->enable();
#
       for (i in 1:n) {
          self.clearfit(i);
       }
       widgetset.tk_release();
   }
}

