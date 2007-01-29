# dish_recbrowser.g: an SDRecord browser for dish
#------------------------------------------------------------------------------
#   Copyright (C) 1997,1998,1999,2000
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
#    $Id: dish_recbrowser.g,v 19.1 2004/08/25 01:08:54 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include "sditerator.g";
include "dishRecBrowser.g";
include "dishentries.g";
#include "arraybrowser.g";
include "dishArrBrowser.g";
include "widgetserver.g";

const sdrecordbrowser := subsequence(ref theRecord, itsName="", baseFrame=F)
{
    private := [=];

    private.rec := theRecord;
    
    dws.tk_hold();
    private.baseFrame := baseFrame;
    if (!is_agent(private.baseFrame)) {
	private.baseFrame := dws.frame(title='SD Record Browser');
    }
    private.outerFrame := dws.frame(private.baseFrame,borderwidth=0,side='top');
    private.canvasFrame := dws.frame(private.outerFrame,side='left',
		borderwidth=0);
    private.canvas := dws.canvas(private.canvasFrame,region=[0,0,600,1200],
			  width=600,height=300,borderwidth=0);
    private.vsb := dws.scrollbar(private.canvasFrame);
    private.hsbFrame := dws.frame(private.outerFrame,side='right',borderwidth=0,		expand='x');
    private.hsbPad := dws.frame(private.hsbFrame,expand='none',width=23,
		height=23,relief='groove');
    private.hsb := dws.scrollbar(private.hsbFrame,orient='horizontal');
    whenever private.vsb->scroll,private.hsb->scroll do 
	private.canvas->view($value);
    whenever private.canvas->yscroll do
	private.vsb->view($value);
    whenever private.canvas->xscroll do
	private.hsb->view($value);
    private.browserFrame := private.canvas->frame(0,0,borderwidth=0);

    self.dismiss := function() 
    {
	wider private;
	val private.baseFrame := F;
	self->dismissed();
    }

    whenever private.baseFrame->killed do {
	self.dismiss();
    }

    if (!is_agent(baseFrame)) {
	private.bottomFrame := dws.frame(private.outerFrame,side='right',
		borderwidth=0);
	private.dismissButton := dws.button(private.bottomFrame,'Dismiss',
		type='dismiss');
	whenever private.dismissButton->press do { self.dismiss();}
    }

    private.label := dws.label(private.browserFrame, itsName); 

    private.headerFrame := dws.frame(private.browserFrame,relief='ridge',
		borderwidth=0);
    private.headerRow1 := dws.frame(private.headerFrame,side='left',
		borderwidth=0,expand='x');
    private.scanEntry := labeledEntry(private.headerRow1,"Scan",
		as_string(private.rec.header.scan_number),widgetset=dws);
    private.objectEntry := labeledEntry(private.headerRow1,"Object",
		as_string(private.rec.header.source_name),widgetset=dws);
    de := dm.epoch('utc','today');
    private.timeEntry := epochEntry(private.headerRow1,"Time", de,'day ymd',
		widgetset=dws);
    private.setTime := function()
    {
	te:=private.rec.header.time;
	if (!is_boolean(te)) dm.doframe(te);
	private.timeEntry.setValue(te);
    }
    private.setTime();
    private.headerRow1Pad := dws.frame(private.headerRow1,borderwidth=0,
		expand='x',width=0,height=2);

    private.headerRow2 := dws.frame(private.headerFrame,side='left',
		borderwidth=0,expand='x');
    private.setADuration := function(which)
    {
	dd := F;
	if (!is_nan(which)) {
	    dd := dq.quantity(which,"s");
	} else {
	    dd := dq.quantity(0.0,"s");
	    dd.value := 0/0;
	}
	return dd;
    }
    private.exposureEntry := durationEntry(private.headerRow2,"Exposure",
		private.setADuration(private.rec.header.exposure),"seconds",
		widgetset=dws);
    private.durationEntry := durationEntry(private.headerRow2,"Duration",
		private.setADuration(private.rec.header.duration),"seconds",
		widgetset=dws);
    private.headerRow2Pad := dws.frame(private.headerRow2,borderwidth=0,
		expand='x',width=0,height=2);


    private.headerRow2a := dws.frame(private.headerFrame,side='left',
		borderwidth=0,expand='x');
    private.tcal := labeledEntryWithUnits(private.headerRow2a,"Tcal",
	       as_string(private.rec.header.tcal),"K",widgetset=dws);
    private.trx := labeledEntryWithUnits(private.headerRow2a,"Trx",
	       as_string(private.rec.header.trx),"K",widgetset=dws);
    private.tsys := labeledEntryWithUnits(private.headerRow2a,"Tsys",
	       as_string(private.rec.header.tsys),"K",widgetset=dws);
    private.sigma := labeledEntryWithUnits(private.headerRow2a,"sigma",
	      	as_string(private.rec.data.sigma[1][1]),
		private.rec.data.desc.chan_freq.unit,widgetset=dws);
    private.headerRow2aPad := dws.frame(private.headerRow2a,borderwidth=0,
		expand='x',width=0,height=2);


    private.headerRow3 := dws.frame(private.headerFrame,side='left',
		borderwidth=0,expand='x');
    dd := dm.direction('j2000','0deg','0deg');
    private.directionEntry := directionEntry(private.headerRow3,"Direction",
		dd,widgetset=dws);
    private.setDirection := function()
    {
	private.directionEntry.setValue(private.rec.header.direction);
    }
    private.setDirection();
    private.dirRateFrame := dws.frame(private.headerRow3,borderwidth=0,
		side='top');
    private.directionRateXEntry := labeledEntryWithUnits(private.dirRateFrame,
	       'Direction rate',"0",'\" s-1', labelWidth=15);
    private.directionRateYEntry:=labeledEntryWithUnits(private.dirRateFrame, '',
		"0",'\" s-1', labelWidth=15,widgetset=dws);
    private.headerRow3Pad := dws.frame(private.headerRow3,borderwidth=0,
		expand='x',width=0,height=2);

    private.headerRow4 := dws.frame(private.headerFrame,side='left',
		borderwidth=0,expand='x');
    dd := dm.direction('j2000','0deg','0deg');
    private.referenceEntry := directionEntry(private.headerRow4,"Reference",
		dd,widgetset=dws);
    private.setReference := function()
    {
	private.referenceEntry.setValue(private.rec.header.refdirection);
    }
    private.setReference();
    private.headerRow4Pad := dws.frame(private.headerRow4,borderwidth=0,
		expand='x',width=0,height=2);
#    private.headerRow5 := dws.frame(private.headerFrame,side='left',
#		borderwidth=0,expand='x');
    dd := dm.direction('azel','0deg','0deg');
    private.azelEntry := directionEntry(private.headerRow4,'AzEl',dd,
		widgetset=dws);
    private.setAzel := function()
    {
	private.azelEntry.setValue(private.rec.header.azel);
    }
    private.setAzel();
#    private.headerRow5Pad := dws.frame(private.headerRow5,borderwidth=0,
#	expand='x',width=0,height=2);
    

    private.headerRow6 := dws.frame(private.headerFrame,side='left',
		borderwidth=0,expand='x');
    df := dq.quantity("0Hz");
    private.restFreqEntry := quantityEntry(private.headerRow6,'Rest Frequency',
		df, 'MHz',[1,1e9],widgetset=dws);
    private.resolutionEntry := quantityEntry(private.headerRow6,'Resolution',
		df,'kHz',[1,1e9],widgetset=dws);
    private.headerRow6Pad := dws.frame(private.headerRow6,borderwidth=0,
		expand='x',width=0,height=2);
    private.headerRow7 := dws.frame(private.headerFrame,side='left',
		borderwidth=0,expand='x');
    private.obsFreqEntry := quantityEntry(private.headerRow7,
		'Observed Frequency',df,'MHz',[1,1e9],widgetset=dws);
    private.bandwidthEntry := quantityEntry(private.headerRow7,'Bandwidth',
		df,'MHz',[1,1e9],widgetset=dws);
    private.headerRow7Pad := dws.frame(private.headerRow7,borderwidth=0,
		expand='x',width=0,height=2);
    private.headerRow8 := dws.frame(private.headerFrame,side='left',
		borderwidth=0,expand='x');
    private.refFreqEntry := quantityEntry(private.headerRow8,
		'Reference Frequency',df,'MHz',[1,1e9],widgetset=dws);
    private.headerRow8Pad := dws.frame(private.headerRow8,borderwidth=0,
		expand='x',width=0,height=2);
    private.setAFreq := function(which)
    {
	qq := which;
	if (!is_nan(which)) {
	    qq := dq.quantity(which,'Hz');
	}
	return qq;
    }
    private.setRestFreq := function() 
    {
	wider private;
	private.restFreqEntry.setValue(private.setAFreq(private.rec.data.desc.restfrequency));
    }
    private.setResolution := function() 
    {
	wider private;
	private.resolutionEntry.setValue(private.setAFreq(private.rec.header.resolution));
    }
    private.setObsFreq := function() 
    {
	wider private;
	private.obsFreqEntry.setValue(private.setAFreq(private.rec.data.desc.restfrequency));
    }
    private.setBandwidth := function() 
    {
	wider private;
	private.bandwidthEntry.setValue(private.setAFreq(private.rec.header.bandwidth));
    }
    private.setRefFreq := function() 
    {
	wider private;
# JPM 
# this is needed for freq switching later
# for now, fill with rest frequency
	private.refFreqEntry.setValue(private.setAFreq(private.rec.data.desc.chan_freq.value));
    }
    private.setRestFreq();
    private.setResolution();
    private.setObsFreq();
    private.setBandwidth();
    private.setRefFreq();

    private.headerRow9 := dws.frame(private.headerFrame,side='left',
		borderwidth=0,expand='x');
    private.pressureEntry:=labeledEntryWithUnits(private.headerRow9,'Pressure',
		as_string(private.rec.header.pressure),'Pa',widgetset=dws);
    private.dewpointEntry:=labeledEntryWithUnits(private.headerRow9,'Dew Point',
		as_string(private.rec.header.dewpoint),'K',widgetset=dws);
    private.tambientEntry := labeledEntryWithUnits(private.headerRow9,'Tamb',
		as_string(private.rec.header.tambient),'K',widgetset=dws);
    private.headerRow9Pad := dws.frame(private.headerRow9,borderwidth=0,
		expand='x',width=0,height=2);

    private.headerRow10 := dws.frame(private.headerFrame,side='left',
		borderwidth=0,expand='x');
    private.windDirEntry:=labeledEntryWithUnits(private.headerRow10,'Wind Dir',
		as_string(private.rec.header.wind_dir),'deg',widgetset=dws);
    private.windSpeedEntry := labeledEntryWithUnits(private.headerRow10,
		'Wind Speed',as_string(private.rec.header.wind_speed),
		'm s-1',widgetset=dws);
    private.headerRow10Pad := dws.frame(private.headerRow10,borderwidth=0,
		expand='x',width=0,height=2);

    private.headerRow11 := dws.frame(private.headerFrame,side='left',
		borderwidth=0,expand='x');
    private.observerEntry := labeledEntry(private.headerRow11,'Observer',
		private.rec.header.observer,widgetset=dws);
    private.projectEntry := labeledEntry(private.headerRow11,'Project',
		private.rec.header.project,widgetset=dws);
    private.headerRow11Pad := dws.frame(private.headerRow11,borderwidth=0,
		expand='x',width=0,height=2);

    private.headerRow12 := dws.frame(private.headerFrame,side='left',
		borderwidth=0,expand='x');
    private.headerRow12top := dws.frame(private.headerRow12,side='top',
		borderwidth=0,expand='y');
    private.telescopeEntry := labeledEntry(private.headerRow12top,'Telescope',
		private.rec.header.telescope,widgetset=dws);
    private.telescopeMountEntry := labeledEntry(private.headerRow12top,
		'Mount Type',private.rec.header.telescope,widgetset=dws);
    private.telescopeDiameter := labeledEntryWithUnits(private.headerRow12top,
		'Diameter',as_string(private.rec.header.telescope),
		'm',widgetset=dws);
    private.headerRow12TopPad := dws.frame(private.headerRow12top,borderwidth=0,
		expand='y',width=1,height=0);
    private.setPosition := function() 
    {
	tp:= private.rec.header.telescope_position;\
	if (!is_boolean(tp)) dm.doframe(tp);
	return tp;
    }
    private.telescopePositionEntry:=positionEntry(private.headerRow12,
		'Position',
		private.setPosition(),
		widgetset=dws);
    private.headerRow12Pad := dws.frame(private.headerRow12,borderwidth=0,
		expand='x',width=0,height=2);

    private.dataFrame := dws.frame(private.browserFrame,relief='ridge');
    private.dataLabel := dws.label(private.dataFrame,'Data');
    private.dataRow1 := dws.frame(private.dataFrame,side='left',borderwidth=0,
		expand='x');
    private.setShapeString := function(shape) {
	shapeString := '[';
	if (len(shape) >= 1) {
	    shapeString := spaste(shapeString,shape[1]);
	    if (len(shape) > 1) {
		for (i in 2:len(shape)) {
		    shapeString := spaste(shapeString,",",as_string(shape[i]));
		}
	    }
	}
	shapeString := spaste(shapeString,"]");
	return shapeString;
    }
    private.shapeString := private.setShapeString(private.rec.data.arr::shape);
    private.shapeEntry := labeledEntry(private.dataRow1, "shape",
		private.shapeString,widgetset=dws);
    private.dataArrBut := dws.button(private.dataRow1,'Browse arr');
    private.dataArrBrowser := F;
    whenever private.dataArrBut->press do {
	if (is_boolean(private.dataArrBrowser) || 
	!private.dataArrBrowser.isactive()) {
#	    private.dataArrBrowser := arrayBrowser(private.rec.data.arr, 'arr');
	    private.dataArrBrowser:= dishArrBrowser(private.rec.data.arr,'arr');
	} else {
	    private.dataArrBrowser.dismiss();
	    private.dataArrBrowser := F;
	}
    }
    private.dataFlagBut := dws.button(private.dataRow1,'Browse flag');
    private.dataFlagBrowser := F;
    whenever private.dataFlagBut->press do {
	if (is_boolean(private.dataFlagBrowser) || 
	!private.dataFlagBrowser.isactive()) {
#	    private.dataFlagBrowser:=arrayBrowser(private.rec.data.flag,'flag');
	    private.dataFlagBrowser:=dishArrBrowser(private.rec.data.flag,'flag')
	} else {
	    private.dataFlagBrowser.dismiss();
	    private.dataFlagBrowser := F;
	}
    }
    private.dataWeightsBut := dws.button(private.dataRow1,'Browse weight');
    private.dataWeightsBrowser := F;
    whenever private.dataWeightsBut->press do {
	if (is_boolean(private.dataWeightsBrowser) || 
	!private.dataWeightsBrowser.isactive()) {
	    private.dataWeightsBrowser:=dishArrBrowser(private.rec.data.weight,
		'weight');
	} else {
	    private.dataWeightsBrowser.dismiss();
	    private.dataWeightsBrowser := F;
	}
    }
    private.dataRow1Pad := dws.frame(private.dataRow1,borderwidth=0,
		expand='x',width=0,height=2);
    private.dataRow2 := dws.frame(private.dataFrame,side='left',
		borderwidth=0,expand='x');
    private.ctypeEntry := labeledEntry(private.dataRow2,"refframe",
		as_string(private.rec.data.desc.refframe),widgetset=dws);
#    private.crvalEntry := labeledEntry(private.dataRow2,"crval",
#		as_string(private.rec.data.desc.crval),widgetset=dws);
#    private.crpixEntry := labeledEntry(private.dataRow2,"crpix",
#		as_string(private.rec.data.desc.crpix),widgetset=dws);
    private.cdeltEntry := labeledEntry(private.dataRow2,"chan_width",
		as_string(private.rec.data.desc.chan_width),widgetset=dws);
    private.dataRow2Pad := dws.frame(private.dataRow2,borderwidth=0,
		expand='x',width=0,height=2);
    private.dataRow3 := dws.frame(private.dataFrame,side='left',
		borderwidth=0,expand='x');
    private.cunitEntry := labeledEntry(private.dataRow3,"units",
		as_string(private.rec.data.desc.units),widgetset=dws);
#    private.dataunitsEntry := labeledEntry(private.dataRow3,"dataunits",
#		as_string(private.rec.data.desc.dataunits),widgetset=dws);
    private.stokesEntry := labeledEntry(private.dataRow3,"corr_type",
		as_string(private.rec.data.desc.corr_type),widgetset=dws);
    private.dataRow3Pad := dws.frame(private.dataRow3,borderwidth=0,
		expand='x',width=0,height=2);

    private.nsFrame := dws.frame(private.browserFrame,relief='ridge');

    private.nsButtonFrame := dws.frame(private.nsFrame,side='left', expand='x');
    private.nsButton := dws.button(private.nsButtonFrame,"ns_header");
    private.nsbrowserFrame := F;
    private.nsbrowser := F;
    whenever private.nsButton->press do {
	if (is_boolean(private.nsbrowserFrame)) {
	    private.nsbrowserFrame := dws.frame(private.nsFrame);
	    val private.nsbrowser := recordBrowser(private.rec.ns_header, 
	       'Non standard header',private.nsbrowserFrame,hasDismissButton=F);
	} else {
	    private.nsbrowser.dismiss();
	    val private.nsbrowserFrame := F;
	}
    }


    private.historyFrame := dws.frame(private.browserFrame,relief='ridge');
    private.histButtonFrame := dws.frame(private.historyFrame,side='left',
		expand='x');
    private.histButton := dws.button(private.histButtonFrame,"history");
    private.histTextFrame := F;
    private.histbf := F;
    private.histText := F;
    whenever private.histButton->press do {
	if (is_boolean(private.histTextFrame)) {
	    private.histTextFrame := dws.frame(private.historyFrame,side='left',
		borderwidth=0);
	    height := min(len(private.rec.hist)+1,5);
	    private.histText := dws.text(private.histTextFrame,relief='sunken',
		wrap='none',height=height);
	    private.histvsb := dws.scrollbar(private.histTextFrame);
	    private.histbf := dws.frame(private.historyFrame,side='right',
		borderwidth=0);
	    private.histpad := dws.frame(private.histbf,expand='none',width=23,
		height=23,relief='groove');
	    private.histhsb:=dws.scrollbar(private.histbf,orient='horizontal');
	    whenever private.histvsb->scroll, private.histhsb->scroll do
		private.histText->view($value);
	    whenever private.histText->yscroll do
		private.histvsb->view($value);
	    whenever private.histText->xscroll do
		private.histhsb->view($value);
	    private.setHistText();
	} else {
	    private.histbf := F;
	    private.histTextFrame := F;
	    private.histText := F;
	}
    }
    private.setHistText := function()
    {
	wider private;
	if (is_agent(private.histText)) {
	    private.histText->delete('start','end');
	    height := min(len(private.rec.hist)+1,5);
	    private.histText->height(height);
	    if (len(private.rec.hist) > 0) {
		for (i in private.rec.hist) {
		    private.histText->append(spaste(i,'\n'));
		}
	    } else {
		private.histText->append(spaste('<Empty>\n'));
	    }
	}
    }

#    self.private := function() { wider private; return private;}

    self.setRecord := function(ref newRecord, newName = '') 
    {
	wider private;
	dws.tk_hold();
	private.rec := newRecord;
	if (newName != '') private.label->text(newName);
	# header
	private.scanEntry.setValue(as_string(private.rec.header.scan_number));
	private.objectEntry.setValue(as_string(private.rec.header.source_name));
	private.setTime();
	private.exposureEntry.setValue(private.setADuration(private.rec.header.exposure));
	private.durationEntry.setValue(private.setADuration(private.rec.header.duration));
	private.tcal.setValue(as_string(private.rec.header.tcal));
	private.trx.setValue(as_string(private.rec.header.trx));
	private.tsys.setValue(as_string(private.rec.header.tsys));
	private.sigma.setValue(as_string(private.rec.data.sigma));
	private.sigma.setUnits(private.rec.data.desc.chan_freq.unit);
	private.setDirection();
	private.setReference();
#	private.directionRateXEntry.setValue(as_string(private.rec.header.direction_rate[1]));
#	private.directionRateYEntry.setValue(as_string(private.rec.header.direction_rate[2]));
	private.setAzel();
	private.setRestFreq();
	private.setResolution();
	private.setObsFreq();
	private.setBandwidth();
	private.setRefFreq();
	private.setRefFreq();
	private.pressureEntry.setValue(as_string(private.rec.header.pressure));
	private.dewpointEntry.setValue(as_string(private.rec.header.dewpoint));
	private.tambientEntry.setValue(as_string(private.rec.header.tambient));
	private.windDirEntry.setValue(as_string(private.rec.header.wind_dir));
	private.windSpeedEntry.setValue(as_string(private.rec.header.wind_speed));
	private.observerEntry.setValue(private.rec.header.observer);
	private.projectEntry.setValue(private.rec.header.project);
	private.telescopeEntry.setValue(private.rec.header.telescope);
	private.telescopeMountEntry.setValue(private.rec.header.telescope);
#	tempmeas:=dm.getvalue(private.rec.header.telescope_position);
#	for (i in 1:3){
#		junk[i]:=tempmeas[i].value;
#	}
	tp := private.setPosition();
	private.telescopePositionEntry.setValue(tp);
#	private.telescopeDiameter.setValue(as_string(private.rec.header.telescope_diameter));
	# data
	private.shapeString := private.setShapeString(private.rec.data.arr::shape);
	private.shapeEntry.setValue(private.shapeString);
	private.ctypeEntry.setValue(as_string(private.rec.data.desc.refframe));
#	private.crvalEntry.setValue(as_string(private.rec.data.desc.crval));
#	private.crpixEntry.setValue(as_string(private.rec.data.desc.crpix));
	private.cdeltEntry.setValue(as_string(private.rec.data.desc.chan_width));
	private.cunitEntry.setValue(as_string(private.rec.data.desc.units));
#	private.dataunitsEntry.setValue(as_string(private.rec.data.desc.dataunits));
	private.stokesEntry.setValue(as_string(private.rec.data.desc.corr_type));
	if (!is_boolean(private.dataArrBrowser) && 
	private.dataArrBrowser.isactive()) {
	    private.dataArrBrowser.setValue(private.rec.data.arr);
	} 
	if (!is_boolean(private.dataFlagBrowser) && 
	private.dataFlagBrowser.isactive()) {
	    private.dataFlagBrowser.setValue(private.rec.data.flag);
	} 
	if (!is_boolean(private.dataWeightsBrowser) && 
	private.dataWeightsBrowser.isactive()) {
	    private.dataWeightsBrowser.setValue(private.rec.data.weight);
	} 
	if (!is_boolean(private.nsbrowserFrame)) {
		private.nsbrowser.setValue(private.rec.ns_header);
	}
	private.setHistText();
	dws.tk_release();
    }

    # there is not yet any state associated with this browser
    self.getstate := function() {
	return [=];
    }

    self.setstate := function(state) {
    }

    junk := dws.tk_release();
}
