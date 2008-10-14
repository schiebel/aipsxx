# separableconvolutiongui.g: GUI for separable convolution
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: separableconvolutiongui.g,v 19.2 2004/08/25 01:01:11 cvsmgr Exp $
#
#
 
pragma include once

include 'note.g'
include 'widgetserver.g'
include 'unset.g'


const separableconvolutiongui := subsequence(ref parent=F, names, axes, widgetset=dws)
{
   if (!have_gui()) {
      return throw('No Gui is available, possibly the  DISPLAY environment is unset',
                   origin='separableconvolutiongui.g');
   }
   if (!is_string(names)) {
      return throw('The "names" variable must be a string',
                    origin='separableconvolutiongui.g');
   }
   if (!is_integer(axes)) {
      return throw('The "axes" variable must be integer',
                    origin='separableconvolutiongui.g');
   }
   if (length(names)!=length(axes)) {
      return throw ('Arguments names and axes must be the same length',
                    origin='separable convolutiongui.g');
   }
#
   prvt := [=]; 
   prvt.ge := widgetset.guientry();         # GUI entry server
   if (is_fail(prvt.ge)) fail;
   prvt.names := names;
   prvt.axes := axes;                    
   prvt.isDisabled := T;                             # Is whole widget disabled
   prvt.kernels := "Gaussian Boxcar Hanning";
#
   widgetset.tk_hold();
   prvt.f0 := widgetset.frame(parent, side='top', expand='x');
   prvt.f0->unmap();
   widgetset.tk_release();
#
   const n := length(names);
   labelLength := 1;
   for (i in 1:n) {
      labelLength := max(labelLength, strlen(names[i]));
   }
#
   for (i in as_string(axes)) {
      prvt.f0[i] := widgetset.frame(prvt.f0, side='left', expand='x');
      prvt.f0[i]['label'] := widgetset.label(prvt.f0[i], text=names[as_integer(i)],
                                              width=labelLength);
      prvt.f0[i]['check'] := widgetset.button(prvt.f0[i], type='check', text='Convolve');
      widgetset.popuphelp(prvt.f0[i]['check'], 'Check to convolve this axis');
      prvt.f0[i]['check']['index'] := i;
#
      prvt.f0[i]['type'] := widgetset.optionmenu(prvt.f0[i], 
                                                 labels=prvt.kernels,
                                                 hlp='Select convolution kernel type');
      prvt.f0[i]['type']['index'] := i;
      prvt.f0[i]['type'].disabled(T);
#
      prvt.f0[i]['width'] := prvt.ge.string(prvt.f0[i], value=unset, default='5',
                                            allowunset=T, editable=T,
                                            hlp='Kernel width, e.g. 10pix or 3arcsec');
      prvt.f0[i]['width'].disable(T);
#
      whenever prvt.f0[i]['check']->press do {
         checked := $agent->state();
         idx := $agent.index;
         if (checked) {
            prvt.f0[idx]['type'].disabled(F);
            prvt.f0[idx]['width'].disable(F);
            prvt.f0.f1.smoothout.disable(F);
         } else {
            prvt.f0[idx]['type'].disabled(T);
            prvt.f0[idx]['width'].disable(T);
            if (self.nonechecked()) prvt.f0.f1.smoothout.disable(T);
         }
         self->check(checked);
      }
#
      whenever prvt.f0[i]['type']->select do {
         idx := $agent.index;
         if ($value.label=='Hanning') {
            prvt.f0[idx]['width'].insert('3pix');
            prvt.f0[idx]['width'].disable(T);
         } else {
            prvt.f0[idx]['width'].disable(F);
         }
      }
   }
#
# We don't allow unset because the user must give a physical file name
#
   labWidth := 17;
   prvt.f0.f1 := widgetset.frame(prvt.f0, side='left');
   prvt.f0.f1.label := widgetset.label(prvt.f0.f1, 'Convolved image',
                                       width=labWidth);
   hlp := spaste('This is an optional argument, you may not wish to store it');
   widgetset.popuphelp(prvt.f0.f1.label, hlp,
             'Enter the name of the output convolved image', combi=T, width=70);
   prvt.f0.f1.smoothout := prvt.ge.file(prvt.f0.f1, value='', default='',
                                        allowunset=F, editable=T, types='Image');
   prvt.f0.f1.smoothout.disable(T);
#
   prvt.f0->map();  



###
   const self.disabled := function (disable=T)
   {
      wider prvt;
      if (disable) {
         if (prvt.isDisabled) return T;
         prvt.f0->disable();
      } else {
         if (!prvt.isDisabled) return T;
         prvt.f0->enable();
      }
      prvt.isDisabled := disable;
      return T;
   }
 
###
   const self.done := function ()
   {
      wider prvt, self;
      for (i in as_string(prvt.axes)) {
         prvt.f0[i]['type'].done();
         prvt.f0[i]['width'].done();
      }
      prvt.f0.f1.smoothout.done();
      prvt.ge.done();
      val prvt := F;
      val self := F;
      return T;
   }

###
   const self.getstate := function (check=T)
   {
      rec := [=];
      rec.kernels := [=];
      rec.outfile := '';
#
      for (i in as_string(prvt.axes)) {
         rec.kernels[i] := [=];
         rec.kernels[i]['check'] := prvt.f0[i]['check']->state();
         rec.kernels[i]['type'] := prvt.f0[i]['type'].getlabel();
         tmp := prvt.f0[i]['width'].get();
#
         if (check && rec.kernels[i]['check']==T) {
            if (is_unset(tmp)) {
               note ('You must specify all smoothing kernel widths',
                      priority='WARN', origin='separableconvolutiongui.g');
               return F;
            } else if (is_fail(tmp)) {
               note ('Some of the kernel widths are illegal',
                     priority='WARN', origin='separableconvolutiongui.g');
               return F;
            }
         }
         rec.kernels[i]['width'] := tmp;
      }
#
      tmp := prvt.f0.f1.smoothout.get();
      if (check && !self.nonechecked()) {
         if (is_fail(tmp)) {
            note ('The output smoothed image name is illegal',
                  priority='WARN', origin='separableconvolutiongui.g');
            return F;
         }
      }
      rec['outfile'] := tmp;
#
      return rec;
   }

###
   const self.setstate := function (rec)
#
# Fills in the values and enables if appropriate
#
   {
      if (!is_record(rec)) return F;
#
      if (has_field(rec, 'kernels')) {
#
# Try and find the appropriate axis in the record.
# If it's not there, clear that entry
#
         for (i in as_string(prvt.axes)) {
            if (has_field(rec.kernels, i)) {
               prvt.f0[i]['check']->state(rec.kernels[i]['check']);
               prvt.f0[i]['type'].selectlabel(rec.kernels[i]['type']);
               prvt.f0[i]['width'].insert(rec.kernels[i]['width']);
#
               if (prvt.f0[i]['check']->state()==F) {
                  prvt.f0[i]['type'].disabled(T);
                  prvt.f0[i]['width'].disable(T);
               } else {
                 prvt.f0[i]['type'].disabled(F);
                 if (prvt.f0[i]['type'].getlabel()=='Hanning') {
                     prvt.f0[i]['width'].disable(T);
                  } else {
                     prvt.f0[i]['width'].disable(F);
                  }
               }
            } else {
               prvt.f0[i]['check']->state(F);
               prvt.f0[i]['type'].selectindex(1);
               prvt.f0[i]['width'].insert(0.0);
            }
         }
      }
      if (has_field(rec, 'outfile')) {
         prvt.f0.f1.smoothout.insert(rec['outfile']);
         if (self.nonechecked()) {
            prvt.f0.f1.smoothout.disable(T);
         } else {
            prvt.f0.f1.smoothout.disable(F);
         }
      }
      return T;
   }


###
   const self.nonechecked := function ()
   {
      noneChecked := T;
      for (i in as_string(prvt.axes)) {
         state := prvt.f0[i]['check']->state();
         if (state) {
            noneChecked := F;
            break;      
         }
      }
      return noneChecked;
   }

###
   const self.reset := function ()
   {
      wider prvt;
      for (i in as_string(prvt.axes)) {
         prvt.f0[i]['check']->disabled(F);
         prvt.f0[i]['check']->state(F);
#
         prvt.f0[i]['type'].selectindex(1);
         prvt.f0[i]['type'].disabled(T);
#
         prvt.f0[i]['width'].disable(F);
         prvt.f0[i]['width'].insert(unset);
         prvt.f0[i]['width'].disable(T);
      }
#
      prvt.f0.f1.smoothout.disable(F);
      prvt.f0.f1.smoothout.insert('');
      prvt.f0.f1.smoothout.disable(T);
#
      return T;
   }
}
