#   dishimagergui.g: GUI for dishimagergui
#------------------------------------------------------------------------------
#   Copyright (C) 1999,2000,2001
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
#    $Id: dishimagergui.g,v 19.1 2004/08/25 01:10:29 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include	'widgetserver.g';

const dishimagergui := subsequence(parent, itsop, logcommand, 
				     widgetset=dws) {

    widgetset.tk_hold();

    private := [=];

    private.op := itsop;
    private.logcommand := logcommand;

    private.outerFrame :=
	widgetset.frame(parent, side='top', relief='ridge');
    # all GUI operations should be labeled, doing it this way ensures
    # that it remains centered at the top of the outer frame
    private.labelFrame := 
	widgetset.frame(private.outerFrame, expand='x');
    private.mainLabel := 
	widgetset.label(private.labelFrame, 'Use imager module');

# setdata combobox
    private.combo := widgetset.combobox(private.outerFrame, 'MeasurementSet:',
                                        autoinsertorder='head',
                                        canclearpopup=T,entrywidth=20,
                                        help='MeasurementSet to image');

    private.sdcombo := widgetset.combobox(private.outerFrame, 'setdata:',
					autoinsertorder='head',
					canclearpopup=T,entrywidth=20,
					help='imager setdata function');
#setimage combobox
    private.sicombo := widgetset.combobox(private.outerFrame, 'setimage:',
                                        autoinsertorder='head',
                                        canclearpopup=T,entrywidth=20,
                                        help='imager setimage function');
#setoptions combobox
    private.socombo := widgetset.combobox(private.outerFrame, 'setoptions:',
                                        autoinsertorder='head',
                                        canclearpopup=T,entrywidth=20,
                                        help='imager setoptions function');
#weighting combobox
    private.wcombo := widgetset.combobox(private.outerFrame, 'weighting:',
                                        autoinsertorder='head',
                                        canclearpopup=T,entrywidth=20,
                                        help='imager weighting function');
#phase dir combobox
    private.rcombo := widgetset.combobox(private.outerFrame, 'row of phase center:',autoinsertorder='head',canclearpopup=T,entrywidth=10,help='the row of the phase center in the POINTING table');
#
    private.bottomFrame := 
	widgetset.frame(private.outerFrame, expand='x', borderwidth=0,
			side='left');
    # this padding ensures that the apply button is centered and the
    # dismiss button is all the way on the right
    private.leftPad :=
	widgetset.frame(private.bottomFrame, expand='x', width=1, borderwidth=0);
    private.applyFrame :=
	widgetset.frame(private.bottomFrame, side='right', borderwidth=0,expand='none');
    private.applyButton := 
	widgetset.button(private.applyFrame, 'Image', type='action');
    # make sure you add popup help
    private.applyButton.shorthelp := 'Display the MS indicated';
    private.rightPad :=
	widgetset.frame(private.bottomFrame, expand='x', width=1, borderwidth=0);
    private.dismissButton := 
	widgetset.button(private.bottomFrame, 'Dismiss', type='dismiss');
    private.dismissButton.shorthelp := 'Dismiss this operation GUI';

    # the apply handler
    private.doapply := function() {
	wider private;
	# first, make sure the operation knows the GUIs state
	myms      := private.combo.getentry();
	mysetdata := private.sdcombo.getentry();
	mysetimage:= private.sicombo.getentry();
	mysetoptions:=private.socombo.getentry();
	myweighting:=private.wcombo.getentry();
	myrow := as_integer(private.rcombo.getentry());
	currselected := private.combo.get('selected');
#fix this
#	if (ent != '' && 
#	    (is_fail(currselected) || ent != currselected)) {
#	    private.sdcombo.insert(ent,select=T);
#	}
#	private.logcommand('dish.ops().imager.setms',[myms=ent]);
	private.op.apply(myms,mysetdata,mysetimage,mysetoptions,myweighting,myrow);
#	private.logcommand('dish.ops().imager.apply',[=]);
    }

    # the handlers for the above buttons
    whenever private.applyButton->press do {
	# invoke the apply function in the operation
	private.doapply();
    }

    whenever private.dismissButton->press do {
	self->dismiss(private.op.opmenuname());
    }

    self.outerframe := function() {
	wider private;
	return private.outerFrame;
    }

    # a done function which makes this GUI unusable
    self.done := function() {
	wider private, self;
	self->done();
    }

    self.setms := function(myms) {
	wider private;
	if (is_unset(myms)) {
	    private.combo.insertentry('');
	} else {
	    myms := as_string(myms);
	    private.combo.insertentry(myms);
	    currselected := private.combo.get('selected');
	    if (is_fail(currselected) || myms != currselected) {
		private.combo.insert(myms,select=T);
	    }
	}
    }
    self.setsd := function(mysd) {
        wider private;
        if (is_unset(mysd)) {
            private.sdcombo.insertentry('');
        } else {
            mysd := as_string(mysd);
            private.sdcombo.insertentry(mysd);
            currselected := private.sdcombo.get('selected');
            if (is_fail(currselected) || mysd != currselected) {
                private.sdcombo.insert(mysd,select=T);
            }
        }
    }
    self.setsi := function(mysi) {
        wider private;
        if (is_unset(mysi)) {
            private.sicombo.insertentry('');
        } else {
            mysi := as_string(mysi);
            private.sicombo.insertentry(mysi);
            currselected := private.sicombo.get('selected');
            if (is_fail(currselected) || mysi != currselected) {
                private.sicombo.insert(mysi,select=T);
            }
        }
    }
    self.setso := function(myso) {
        wider private;
        if (is_unset(myso)) {
            private.socombo.insertentry('');
        } else {
            myso := as_string(myso);
            private.socombo.insertentry(myso);
            currselected := private.socombo.get('selected');
            if (is_fail(currselected) || myso != currselected) {
                private.socombo.insert(myso,select=T);
            }
        }
    }

   self.setw := function(myw) {
        wider private;
        if (is_unset(myw)) {
            private.wcombo.insertentry('');
        } else {
            myw := as_string(myw);
            private.wcombo.insertentry(myw);
            currselected := private.wcombo.get('selected');
            if (is_fail(currselected) || myw != currselected) {
                private.wcombo.insert(myw,select=T);
            }
        }
    }

    self.getms := function() {
	wider private;
	return private.combo.getentry();
    }
    self.getsd := function() {
	wider private;
	return private.sdcombo.getentry();
    }
    self.getsi := function() {
	wider private;
	return private.sicombo.getentry();
    }
    self.getso := function() {
	wider private;
	return private.socombo.getentry();
    }
    self.getw  := function() {
	wider private;
	return private.wcombo.getentry();
    }

    self.sethistory := function(histrecord) {
	wider private;
	private.combo.delete('start','end');
	private.sdcombo.delete('start','end');
	private.sicombo.delete('start','end');
	private.socombo.delete('start','end');
	private.wcombo.delete('start','end');
	if (is_unset(histrecord)) return;
	for (i in 1:5) {
	   history:=histrecord[i]; 
	      for (j in 1:len(history)) {
		if (i==1) {
		   private.combo.insert(history[j],(j-1));
	        } else if (i==2) {
		   private.sdcombo.insert(history[j],(j-1));
		} else if (i==3) {
		   private.sicombo.insert(history[j],(j-1));
		} else if (i==4) {
		   private.socombo.insert(history[j],(j-1));
		} else if (i==5) {
		   private.wcombo.insert(history[j],(j-1));
		}
	      }
        }
    }

    self.gethistory := function() {
	wider private;
	hist:=[=];
	hist.mshist:=private.combo.get(0,'end');
	hist.sdhist:=private.sdcombo.get(0,'end');
	hist.sihist:=private.sicombo.get(0,'end');
	hist.sohist:=private.socombo.get(0,'end');
	hist.whist:=private.wcombo.get(0,'end');
	return hist;
    }

    junk := widgetset.tk_release();

    # self is returned automatically, it should NOT be explicitly returned here
}
