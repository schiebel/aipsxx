# dishregridgui.g: dish regridder GUI
#------------------------------------------------------------------------------
# Copyright (C) 1997,1998,1999,2000,2001,2002
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
#    $Id: dishregridgui.g,v 19.1 2004/08/25 01:11:00 cvsmgr Exp $
#------------------------------------------------------------------------------

pragma include once;

include 'widgetserver.g';
  
const dishregridgui := subsequence(parent, itsdish, logcommand, widgetset=dws)
{
    # a subsequence returns an agent named "self"

    widgetset.tk_hold();

    private:=[=];
    private.dish:=itsdish;
    private.currType:=F;
    
    private.op := itsdish.ops().regrid;
    private.logcommand := logcommand;

  private.HANNING := 0;
  private.BOXCAR := 1;
  private.GAUSSIAN := 2;
  private.SPLINEINT:=3;
  private.FTINT:=4;
  private.maxtype := private.FTINT;
  private.gridfac:='';

  private.GWCHANNELUNITS := 1;
  private.GWAXISUNITS := 2;
  private.gwunits := [=];
  private.gwunits[private.GWCHANNELUNITS] := 'Channels';
  private.gwunits[private.GWAXISUNITS] := 'Native Units';

  private.outerFrame := dws.frame(parent, side='top', relief='ridge');
  private.label := dws.label(private.outerFrame, 'Regridding');
  private.mainFrame := dws.frame(private.outerFrame, side='left',borderwidth=0);

  private.typeFrame := dws.frame(private.mainFrame, side='top',expand='none');
  private.hanningType := dws.button(private.typeFrame, 'Hanning ', type='radio', 
				    value=private.HANNING, relief='flat');
  popuphelp(private.hanningType,hlp='Selects a hanning smooth');
  private.boxcarType := dws.button(private.typeFrame,  'Boxcar  ', type='radio', 
				   value=private.BOXCAR, relief='flat');
  popuphelp(private.boxcarType,hlp='Selects a boxcar smooth');
  private.gaussianType := dws.button(private.typeFrame,'Gaussian', type='radio',
				     value=private.GAUSSIAN, relief='flat');
  popuphelp(private.gaussianType,hlp='Selects a Gaussian smooth');

    private.splineType:= dws.button(private.typeFrame,'Spline Int',type='radio',
                                     value=private.SPLINEINT, relief='flat');
    popuphelp(private.splineType,hlp='Selects a spline interpolation');
    private.ftintType := dws.button(private.typeFrame,'  FT Int  ',type='radio',
                                    value=private.FTINT, relief='flat');
   popuphelp(private.ftintType,hlp='Selects a Fourier Transform interpolation');

  private.widthsFrame := dws.frame(private.mainFrame, side='top', expand='none',
				   height=1,width=1);
  # use an empty button as a spacer
  private.widthsPad := dws.button(private.widthsFrame,'',relief='flat',
				  disabled=F, borderwidth=0);
  private.bwidthEntry := 
      labeledEntryWithUnits(private.widthsFrame,'Width',
			    '','channels', entryWidth=10,
			    hlp='The boxcar width',widgetset=dws);
#  private.bwidthEntry.disabled(F);
  private.gwidthEntryFrame := dws.frame(private.widthsFrame,borderwidth=0,side='left');
  private.gwidthLabel := dws.label(private.gwidthEntryFrame,text='Width');
  private.gwidthEntry := dws.entry(private.gwidthEntryFrame,
				   disabled=F,width=10);
  popuphelp(private.gwidthEntry,
	    hlp='The Gaussian Width',
	    txt='in the current units', combi=T);
  private.gwidthConverterWidget := 
      dishConverterWidget(private.gwidthEntryFrame,
			  private.gwunits[private.GWCHANNELUNITS],
			  private.gwunits[private.GWAXISUNITS],
			  F, F, private.gwunits[private.GWAXISUNITS],side='left',
			  optionalButtonWidth=12, optionalLabel='(FWHM)',
			  widgetset=dws);
    private.intEntry := labeledEntryWithUnits(private.widthsFrame,'Grid Factor','','',
                                              entryWidth=10,
                                              hlp='Old channel width/new channel width',
                                              txt='for spline and FT interpolation.  Must be < 1 for FT interpolation.',
                                              combi=T, widgetset=dws);
    private.widthsPad2 := dws.button(private.widthsFrame,'',
                                     disabled=T, borderwidth=0);
  private.optionsFrame := dws.frame(private.mainFrame, side='top',expand='none',
				    height=1,width=1);
  private.horizontalPad := dws.frame(private.mainFrame, width=5, expand='x');

  private.rightFrame := dws.frame(private.mainFrame,side='top',borderwidth=2,expand='none');

  private.rightTopPad := dws.frame(private.rightFrame, borderwidth=0,expand='y',
				   height=1);
  private.decimateButton := dws.button(private.rightFrame,'Decimate', type='check', relief='flat');
  popuphelp(private.decimateButton,
	    hlp='Reduce the number of channels',
	    txt=paste('When "on", the result will have fewer channels that the original data.',
		      'Hanning is reduced by 2, boxcar by the width of the boxcar'));
  private.decimateButton->state(F);
  private.decimateState := private.decimateButton->state();
  whenever private.decimateButton->press do {
	self.setdecimate(private.decimateButton->state());
  }

  private.doSmoothButtonFrame := dws.frame (private.rightFrame, side='right',
					    borderwidth=2, expand='none');
  private.doSmoothButton := dws.button (private.doSmoothButtonFrame,
					text='Apply',height=3,type='action');
  popuphelp(private.doSmoothButton,
	    hlp='Do the indicated regridding');
  private.rightBottomPad := dws.frame(private.rightFrame, borderwidth=0,expand='y',
				      height=1);
  private.dismissButton := dws.button(private.rightFrame, 'Dismiss',type='dismiss');
  popuphelp(private.dismissButton,
	    hlp='Dismiss this operation GUI',
	    txt='This is equivalent to using the Operations menu to turn off this GUI.',
	    combi=T);

    self.outerframe := function() {
        wider private;
        return private.outerFrame;
    }

    whenever private.dismissButton->press do {
        self->dismiss(private.op.opmenuname());
    }


  private.hanningType->state(T);
  private.currType := private.HANNING;
  private.bwidthEntry.disabledAppearance(T);
  private.gwidthAppearance:=function(disabled)
  {
	wider private;
	if (disabled) {
	    private.gwidthLabel->foreground('grey60');
	    private.gwidthEntry->background('lightgrey');
	    private.gwidthEntry->foreground('grey60');
	} else {
	    private.gwidthLabel->foreground('black');
	    private.gwidthEntry->background('white');
	    private.gwidthEntry->foreground('black');
	}
	private.gwidthEntry->disabled(disabled);
	private.gwidthConverterWidget.disabledappearance(disabled);
    }
  private.gwidthAppearance(T);

  private.allowDecimation := function(tOrF)
  {
	if (tOrF) {
	    private.decimateButton->disabled(F);
	    private.decimateButton->state(private.decimateState);
	} else {
	    private.decimateButton->state(F);
	    private.decimateButton->disabled(T);
	}
    }

  self.decimateState:=function() {
	wider private;
	return private.decimateState;
  }

  self.setdecimate := function(tOrF=F) {
	wider private;	
	private.decimateButton->state(tOrF);
	private.decimateState:=tOrF;
	private.decimate:=tOrF;
        private.logcommand('dish.ops().regrid.setdecimate',[tOrF=tOrF]);
	return T;
  }

  self.gausswidth := function() {
        wider private;
	temp:=private.gwidthEntry->get();
        return temp;
  }

  self.gridfac := function() {
	wider private;
	private.gridfac:=private.intEntry.getValue();
	return private.gridfac;
  }

  self.setgridfac := function(gridfac) {
	wider private;
	private.gridfac:=gridfac
	ok:=private.intEntry.setValue(gridfac);
	return T;
  }

  self.setgausswidth:=function(gausswidth){
        wider private;
	ok:=private.gwidthEntry->delete('start','end');
        ok:=private.gwidthEntry->insert(gausswidth);
        return T;
  }

  self.boxwidth := function() {
	wider private;
	return private.bwidthEntry.getValue();
  }

  self.gwunits := function() {
	wider private;
	return private.gwcurrUnits;
  }

  self.setboxwidth:=function(boxwidth){
	wider private;
	ok:=private.bwidthEntry.setValue(boxwidth);
	return T;
  }

  self.currType := function() {
	wider private;
	return private.currType;
  }

  self.settype := function(whichType) {
      wider private;
      private.currType := whichType;
      if (private.currType == private.HANNING) {
	private.hanningType->state(T);
	private.bwidthEntry.disabledAppearance(T);
	private.gwidthAppearance(T);
        private.allowDecimation(T);
        private.intEntry.disabledAppearance(T);
        private.logcommand('dish.ops().regrid.settype',[type='HANNING']);

      } else if (private.currType == private.BOXCAR) {
	private.boxcarType->state(T);
	private.bwidthEntry.disabledAppearance(F); 
	private.gwidthAppearance(T);
	private.allowDecimation(T);
        private.intEntry.disabledAppearance(T);
        private.logcommand('dish.ops().regrid.settype', [type='BOXCAR']);

      } else if (private.currType == private.GAUSSIAN) {
	private.gaussianType->state(T);
        private.bwidthEntry.disabledAppearance(T);
        private.gwidthAppearance(F);
	private.allowDecimation(F);
        private.intEntry.disabledAppearance(T);
        private.logcommand('dish.ops().regrid.settype', [type='GAUSSIAN']);

      } else if (private.currType == private.SPLINEINT) {
	private.splineType->state(T);
	private.bwidthEntry.disabledAppearance(T);
	private.gwidthAppearance(T);
	private.allowDecimation(F);
	private.intEntry.disabledAppearance(F);
	private.logcommand('dish.ops().regrid.settype', [type='SPLINEINT']);

      } else if (private.currType == private.FTINT) {
	private.ftintType->state(T);
        private.bwidthEntry.disabledAppearance(T);
        private.gwidthAppearance(T);
        private.allowDecimation(F);
        private.intEntry.disabledAppearance(F);
	private.logcommand('dish.ops().regrid.settype', [type='FTINT']);
      }
      return private.currType;
  }

  whenever private.hanningType->press, private.boxcarType->press, private.gaussianType->press, private.splineType->press, private.ftintType->press do {
      wider private;
      self.settype($value);
  }

  private.gwcurrUnits := -1;
  private.setGWUnits := function(whichUnits) {
	wider private;
	if (private.gwcurrUnits != whichUnits) {
	    private.gwcurrUnits := private.gwidthConverterWidget.setunits(whichUnits);
	}
    }

  self.setGWUnits:=function(whichunits) { wider private; return private.setGWUnits(whichunits);};

  private.regridder := itsdish.ops().regrid;
  self.regridder := function() { wider private; return private.regridder;}


  private.convertGWUnits := function() {
	wider private;

	currWidth := as_double(private.gwidthEntry->get());
	lv := ref private.dish.rm().getlastviewed();
	nominee := ref lv.value;
	if (is_sdrecord(nominee)) {
	    # convert currWidth as indicated
	    if (private.gwcurrUnits == private.GWCHANNELUNITS) {
		# to X-axis units
		currWidth *:= nominee.data.desc.cdelt;
		private.setGWUnits(private.GWAXISUNITS);
	    } else {
		# to channels
		currWidth /:= nominee.data.desc.cdelt;
		private.setGWUnits(private.GWCHANNELUNITS);
	    }
    # and replace this value in the entry
    # unless its exactly zero, which might mean that
    # either it really was zero, in which case its still zero
    # or it was some invalid non-numeric string, in which just leave as is
	    if (currWidth != 0) {
		global system;
		currPrec := system.print.precision;
		# this should be enough for floating point precision
		system.print.precision := 8;
		private.gwidthEntry->delete('start','end');
		private.gwidthEntry->insert(as_string(currWidth));
		system.print.precision := currPrec;
	    }
	}
    }
  private.setGWUnits(private.GWAXISUNITS);

  private.gwidthConvertCallback := function(oldUnits) {
	wider private;
	if (oldUnits != private.gwcurrUnits) {
	    private.setGWUnits(oldUnits);
	}
	private.convertGWUnits();
    }

  private.gwidthConverterWidget.setconvertcallback(private.gwidthConvertCallback);
  private.gwidthConverterWidget.setunitcallback(private.setGWUnits);


    whenever private.doSmoothButton->press do {
	wider private;
	private.op.apply();
	private.logcommand('dish.ops().regrid.apply');
    }


    self.done := function() 
    { 
	self->done(T);
    }

    self.getstate := function() {
	wider private;
	state := [=];

	state.type := private.currType;
	state.boxwidth := private.bwidthEntry.getValue();
	state.gwidth := private.gwidthEntry->get();
	state.gunits := private.gwcurrUnits;
	state.decimate := private.decimateState;
	state.gridfac := private.gridfac;

	return state;
    }

    self.setstate := function(state) {
	wider private;
	result := F;
	if (is_record(state)) {
	    # default values
	    private.currType := private.HANNING;
	    private.bwidthEntry.setValue('');
	    private.gwidthEntry->delete('start','end');
	    private.intEntry.setValue('');
	    private.gwcurrUnits := private.GWCHANNELUNITS;
	    private.decimateState := F;
	    private.gridfac := '';

	    # and set these from the state record if possible
	    if (has_field(state,'type') &&
		is_integer(state.type) &&
		state.type >= 0 && state.type <= private.maxtype) {
		private.currType := state.type;
	    }
	    if (has_field(state,'boxwidth') &&
		is_string(state.boxwidth)) {
		private.bwidthEntry.setValue(state.boxwidth);
	    }
	    if (has_field(state,'gridfac') &&
		is_string(state.gridfac)) {
		private.intEntry.setValue(state.gridfac);
		private.gridfac := state.gridfac;
	    }
	    if (has_field(state,'gwidth') &&
		is_string(state.gwidth)) {
		private.gwidthEntry->insert(state.gwidth);
	    }
	    if (has_field(state,'gunits') &&
		is_integer(state.gunits) &&
		state.gunits >= 0 && state.gunits <= len(private.gwunits)) {
		private.gwcurrUnits := state.gunits;
	    }
	    if (has_field(state,'decimate') &&
		is_boolean(state.decimate)) {
		private.decimateState := state.decimate;
	    }
	    # finally make sure things are still coordinated
	    private.gwcurrUnits := private.gwidthConverterWidget.setunits(private.gwcurrUnits);
	    if (private.currType == private.HANNING) {
		private.hanningType->state(T);
	    } else if (private.currType == private.BOXCAR) {
		private.boxcarType->state(T);
	    } else if (private.currType == private.GAUSSIAN) {
		private.gaussianType->state(T);
	    }
	    self.settype(private.currType);
	    result := T;
	}
	return result;
    }
    junk:=dws.tk_release();
    # self is returned, no need to explicitly return it
}
