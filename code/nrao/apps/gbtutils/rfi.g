# rfi: GBT RFI utilities
# Copyright (C) 1999,2000,2003
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
# $Id: rfi.g,v 19.1 2003/07/16 21:11:08 bgarwood Exp $

# include guard
pragma include once;

global __rfi_gui := [=];

include 'dishentries.g'
include 'widgetserver.g'

const rfiutils := function() {
 
private := [=];
	
public := [=];
#
#
#
# ----- private methods -----
#
private.disablemain := function () {
        wider private;
        rfimain.app.cmd.f.rfis->disable();
        rfimain.app.cmd.f.rfiq->disable();
        }
 
private.enablemain := function () {
        wider private;
        rfimain.app.cmd.f.rfis->enable();
        rfimain.app.cmd.f.rfiq->enable();
        }
 
private.pressCallback := function(name) { 
	wider private;
	private.FBand:=name;
	return T;
	}

private.enableEntry := function () {
	wider private;
	private.TimeEntry.disabledAppearance(F);
	private.AzEntry.disabledAppearance(F);
	private.ElEntry.disabledAppearance(F);
        private.FreqEntry.disabledAppearance(F);
        private.IniEntry.disabledAppearance(F);
        private.ComEntry.disabledAppearance(F);
	}

private.enableEntryQuery := function () {
        wider private;
        private.StartTimeEntry.disabledAppearance(F);
        private.StopTimeEntry.disabledAppearance(F);
        private.FreqEntry.disabledAppearance(F);
	private.AzEntry.disabledAppearance(F);
	private.ElEntry.disabledAppearance(F);
	private.BWidthEntry.disabledAppearance(F);
        private.IniEntry.disabledAppearance(F);
        }
 

private.clearEntry := function () {
	wider private;
	private.TimeEntry.setValue('');
	private.FreqEntry.setValue('');
	private.AzEntry.setValue('');
	private.ElEntry.setValue('');
	private.RecEntry->delete('start','end');
	private.PolEntry->delete('start','end');
	private.PropEntry1->delete('start','end');
	private.PropEntry2->delete('start','end');
	private.PropEntry3->delete('start','end');
	private.SourEntry->delete('start','end');
	private.TeleEntry->delete('start','end');
	private.BackEntry->delete('start','end');
	private.IniEntry.setValue('');
	private.ComEntry.setValue('');
	}

private.clearQueryEntry := function () {
        wider private;
        private.StartTimeEntry.setValue('');
        private.StopTimeEntry.setValue('');
        private.FreqEntry.setValue('');
        private.BWidthEntry.setValue('');
	private.AzEntry.setValue('');
	private.ElEntry.setValue('');
        private.RecEntry->delete('start','end');
        private.PolEntry->delete('start','end');
        private.PropEntry1->delete('start','end');
        private.PropEntry2->delete('start','end');
        private.PropEntry3->delete('start','end');
        private.SourEntry->delete('start','end');
        private.TeleEntry->delete('start','end');
        private.BackEntry->delete('start','end');
        private.IniEntry.setValue('');
        }
 
private.storequery := function () {
	wider private;
	private.Field1a:=private.StartTimeEntry.getValue();
	private.Field1b:=private.StopTimeEntry.getValue();
	private.Field2a:=as_double(private.FreqEntry.getValue());
        private.Field2b:=private.RecEntry->get();
	private.Field2c:=as_float(private.BWidthEntry.getValue());
#use only float precision for az and el to aid matching
	private.Field3a:=as_float(private.AzEntry.getValue());
	private.Field3b:=as_float(private.ElEntry.getValue());
        private.Field4:=private.PolEntry->get();
        private.Field5a:=private.PropEntry1->get();
        private.Field5b:=private.PropEntry2->get();
        private.Field5c:=private.PropEntry3->get();
        private.Field6:=private.SourEntry->get();
        private.Field7:=private.TeleEntry->get();
        private.Field8:=private.BackEntry->get();
	private.Field9:=private.IniEntry.getValue();
}

private.testprint := function () {
	wider private;
	private.Field1:=private.TimeEntry.getValue();
        private.Field2a:=as_double(private.FreqEntry.getValue());
	private.Field2b:=private.RecEntry->get();
	private.Field3a:=as_float(private.AzEntry.getValue());
	private.Field3b:=as_float(private.ElEntry.getValue());
	private.Field4:=private.PolEntry->get();
        private.Field5a:=private.PropEntry1->get();
        private.Field5b:=private.PropEntry2->get();
        private.Field5c:=private.PropEntry3->get();
        private.Field6:=private.SourEntry->get();
        private.Field7:=private.TeleEntry->get();
	private.Field8:=private.BackEntry->get();
        private.Field9:=private.ComEntry.getValue();
        private.Field10:=private.IniEntry.getValue();

	print private.Field1,private.Field2a,private.Field2b,private.Field3a,private.Field3b,private.Field4,private.Field5a,private.Field5b,private.Field5c,private.Field6,private.Field7,private.Field8,private.Field9,private.Field10;
}

private.convertTime := function (theTime) {
	wider private;
	temp:=dm.epoch('utc',theTime);
	if (is_record(temp)) {
		mjdtime:=temp.m0.value;
	} else {
		print 'Wrong format for Time: Leaving Blank';
		mjdtime:="";
	}
	print 'mjdtime',mjdtime;
	return mjdtime;
}

private.writeRow := function () {
	wider private;
	private.rfiTable := table('/aips++/rfi.aips++',readonly=F, ack=F);
	print 'is table ',is_table(private.rfiTable);
	nrows:=private.rfiTable.nrows();
	private.rfiTable.addrows(1);
	private.mjd:=private.convertTime(private.Field1);
	private.rfiTable.putcell("Time",nrows+1,private.mjd);
	private.rfiTable.putcell("Date",nrows+1,private.Field1);
	private.rfiTable.putcell("Freq",nrows+1,private.Field2a);
	private.rfiTable.putcell("Receiver",nrows+1,private.Field2b);
	private.rfiTable.putcell("Azimuth",nrows+1,private.Field3a);
	private.rfiTable.putcell("Elevation",nrows+1,private.Field3b);
	private.rfiTable.putcell("Polarization",nrows+1,private.Field4);
	private.rfiTable.putcell("Temp_Prop",nrows+1,private.Field5a);
	private.rfiTable.putcell("Mod_Prop",nrows+1,private.Field5b);
	private.rfiTable.putcell("Freq_Prop",nrows+1,private.Field5c);
	private.rfiTable.putcell("Source",nrows+1,private.Field6);
	private.rfiTable.putcell("Telescope",nrows+1,private.Field7);
	private.rfiTable.putcell("Backend",nrows+1,private.Field8);
	private.rfiTable.putcell("Comments",nrows+1,private.Field9);
	newini:=tr('[A-Z]','[a-z]',private.Field10);
	private.rfiTable.putcell("Initials",nrows+1,newini);
	private.rfiTable.flush();
	private.rfiTable.close();
	private.rfiTable:=F;
}

private.formquery := function () {
	wider private;
	print 'freq is ',private.Field2a, private.Field2c;
	if (strlen(private.Field1a) == 0 && strlen(private.Field1b) == 0) {
		q1 := paste('Time > 0.');
	} else if (strlen(private.Field1a) == 0 && strlen(private.Field1b)!= 0){
		private.Field1b:=private.convertTime(private.Field1b);
		q1 := paste('Time < ',private.Field1b);
	} else if (strlen(private.Field1a) != 0 && strlen(private.Field1b)== 0){
		private.Field1a:=private.convertTime(private.Field1a);
		q1 := paste('Time > ',private.Field1a);
	} else {
                private.Field1a:=private.convertTime(private.Field1a);
                private.Field1b:=private.convertTime(private.Field1b);
#		print private.Field1a,private.Field1b;
		q1:=paste('Time >',private.Field1a,'&& Time <',private.Field1b);
	}
#	
	if (private.Field2a == 0 && private.Field2c ==0) {
		q2a := paste('Freq > 0.');
	} else if (private.Field2a != 0 && private.Field2c ==0) {
		q2a := paste('Freq ==', private.Field2a);
	} else {
		t1:=private.Field2a-private.Field2c/2.;
		t2:=private.Field2a+private.Field2c/2.;
		q2a := paste('Freq > ',t1,' && Freq < ',t2);
	}
	if (private.Field3a == 0) {
		q3a:=paste('Azimuth > -200.'); 
	} else {
		q3a:=paste('Azimuth ==', private.Field3a);
	}
	if (private.Field3b == 0) {
                q3b:=paste('Elevation > -20.'); 
        } else {
                q3b:=paste('Elevation ==', private.Field3b);
        }
	if (strlen(private.Field2b) == 0) private.Field2b := "*";
	if (strlen(private.Field4) == 0) private.Field4 := "*";
	if (strlen(private.Field5a) == 0) private.Field5a := "*";
	if (strlen(private.Field5b) == 0) private.Field5b := "*";
	if (strlen(private.Field5c) == 0) private.Field5c := "*";
	if (strlen(private.Field6) == 0) private.Field6 := "*";
	if (strlen(private.Field7) == 0) private.Field7 := "*";
	if (strlen(private.Field8) == 0) private.Field8 := "*";
	if (strlen(private.Field9) == 0) private.Field9 := "*";
	q2b := paste('Receiver == pattern("',private.Field2b,'")',sep="");
	q4 := paste('Polarization == pattern("',private.Field4,'")',sep="");
	q5a := paste('Temp_Prop == pattern("',private.Field5a,'")',sep="");
	q5b := paste('Mod_Prop == pattern("',private.Field5b,'")',sep="");
	q5c := paste('Freq_Prop == pattern("',private.Field5c,'")',sep="");
	q6 := paste('Source == pattern("',private.Field6,'")',sep="");
	q7 := paste('Telescope == pattern("',private.Field7,'")',sep="");
	q8 := paste('Backend == pattern("',private.Field8,'")',sep="");
	newini:=tr('[A-Z]','[a-z]',private.Field9);
	q9 := paste('Initials == pattern("',newini,'")',sep="");
	qall := paste(q1,"&&",q2a,"&&",q2b,"&&",q3a,"&&",q3b,"&&",q4,"&&",q5a,"&&",q5b,"&&",q5c,"&&",q6,"&&",q7,"&&",q8,"&&",q9);
	return qall;
}

private.query := function () {
	wider private;
	private.rfiTable := table('/aips++/rfi.aips++', ack=F);
	qweery:=private.formquery();
	print qweery;
	subtable := private.rfiTable.query(query=qweery);
	if (is_table(subtable) && subtable.nrows() != 0) {
		subtable.browse();
		subtable.close();
		subtable:=F;
	} else {
		print 'No Data found for those parameters';
	}
	private.rfiTable.close();
	private.rfiTable:=F;
}

#
# ----- public2 methods -----
#
public.private := function () {
	wider private;
	return private;
}

public.callrfiquery := function () {
	wider private;
	sl.show('Select Search Parameters then Press "Query Table"');
	rfig := ref __rfi_gui;
#
        recbut:=[=];
        reclist[1]:='L Band [1150. - 1730. MHz]';
        reclist[2]:='S Band [1730. - 3950. MHz]';
        reclist[3]:='C Band [3950. - 8200. MHz]';
        reclist[4]:='X Band [8200. - 12400. MHz]'
        reclist[5]:='Ku Band [12400. - 18000. MHz]';
        reclist[6]:='K Band [18000. - 26500. MHz]';
        reclist[7]:='Ka Band [26500. - 33000. MHz]';
        reclist[8]:='Q Band [40000. - 50000. MHz]';
        polbut:=[=];
        pollist:="Linear-X Linear-Y RCP LCP Both-Linear Both-Circular Unknown";
        temppropbut:=[=];
        tempproplist:="Continuous Regularly_Pulsed Intermittent Transient Other"
	modpropbut:=[=];
	modproplist:="Voice 60/120_Hz Telemetry Noisy None Other"
	freqpropbut:=[=];
	freqproplist:="Broadband One_Narrow Several_Narrow Many_Narrow Other"
        sourbut:=[=];
        sourlist:="Satellite Internal Unknown";
        telebut:=[=];
        telelist:="140foot GBT";
        backbut:=[=];
        backlist:="Spectral_Processor DCR Mark_IV_Autocorrelator GBT_Spectrometer Other";
#
	dws.tk_hold();
	rfig.qfm := dws.frame(wf_us,title="Query RFI Database",background="blue");
# Entry frames for query
        private.StartTimeEntry := labeledEntryWithUnits(rfig.qfm,'1a. Start Time ','','[dd-Mmm-yyyy/hh:mm:ss]', entryWidth=22);
        private.StopTimeEntry := labeledEntryWithUnits(rfig.qfm,'1b. Stop  Time ','','[dd-Mmm-yyyy/hh:mm:ss]', entryWidth=22);
	RcFrame := dws.frame(rfig.qfm,side='left');
        private.FreqEntry := labeledEntryWithUnits(RcFrame,'2a. Frequency  ','','[MHz]', entryWidth=10);
#
        RecFrame := dws.frame(RcFrame,side='left');
        RecLabel := dws.label(RecFrame,'2b. Receiver');
        private.RecEntry :=dws.entry(RecFrame,width=10,background='white');
        private.RecButton:=dws.button(RecFrame,'List',type="menu");
        for (i in 1:len(reclist)) {
                recbut[i]:=dws.button(private.RecButton,reclist[i]);
        }
#
	private.BWidthEntry := labeledEntryWithUnits(rfig.qfm,'2c. Sig. Bandwidth','','[MHz] Search +/- BW/2 around Frequency', entryWidth=10);
#
	PosFrame:=dws.frame(rfig.qfm,side='left');
        private.AzEntry := labeledEntryWithUnits(PosFrame,'3a. Azimuth    ','','Deg.', entryWidth=8);
        private.ElEntry := labeledEntryWithUnits(PosFrame,'3b. Elevation','','Deg.',entryWidth=8);
        PolFrame := dws.frame(rfig.qfm,side='left');
        PolLabel := dws.label(PolFrame,'4. Polarization     ');
        private.PolEntry := dws.entry(PolFrame,width=10,background='white');
        private.PolButton:= dws.button(PolFrame,'List',type='menu')
        for (i in 1:len(pollist)){
                polbut[i]:=dws.button(private.PolButton,pollist[i]);
        }
#
        PropFrame1 := dws.frame(rfig.qfm,side='left');
        PropLabel1 := dws.label(PropFrame1,'5a. Temporal Properties');
        private.PropEntry1 := dws.entry(PropFrame1,width=15,background='white');
        private.PropButton1:= dws.button(PropFrame1,'List',type='menu');
        for (i in 1:len(tempproplist)) {
                temppropbut[i]:=dws.button(private.PropButton1,tempproplist[i]);
        }
        PropFrame2 := dws.frame(rfig.qfm,side='left');
        PropLabel2 := dws.label(PropFrame2,'5b. Modulation Properties');
        private.PropEntry2 := dws.entry(PropFrame2,width=15,background='white');
        private.PropButton2:= dws.button(PropFrame2,'List',type='menu');
        for (i in 1:len(modproplist)) {
                modpropbut[i]:=dws.button(private.PropButton2,modproplist[i]);
        }
        PropFrame3 := dws.frame(rfig.qfm,side='left');
        PropLabel3 := dws.label(PropFrame3,'5c. Frequency Properties');
        private.PropEntry3 := dws.entry(PropFrame3,width=15,background='white');
        private.PropButton3:= dws.button(PropFrame3,'List',type='menu');
        for (i in 1:len(freqproplist)) {
                freqpropbut[i]:=dws.button(private.PropButton3,freqproplist[i]);
        }
#
       SourFrame := dws.frame(rfig.qfm,side='left');
       SourLabel := dws.label(SourFrame,'6. Source           ');
       private.SourEntry := dws.entry(SourFrame,width=10,background='white');
       private.SourButton:= dws.button(SourFrame,'List',type='menu');
       for (i in 1:len(sourlist)) {
               sourbut[i]:=dws.button(private.SourButton,sourlist[i]);
       }
#
        TlFrame :=dws.frame(rfig.qfm,side='left');
       TeleFrame := dws.frame(TlFrame,side='left');
       TeleLabel := dws.label(TeleFrame,'7. Telescope       ');
       private.TeleEntry := dws.entry(TeleFrame,width=10,background='white');
       private.TeleButton:= dws.button(TeleFrame,'List',type='menu');
       for (i in 1:len(telelist)) {
               telebut[i]:=dws.button(private.TeleButton,telelist[i]);
       }
#
       BackFrame := dws.frame(TlFrame,side='left');
       BackLabel := dws.label(BackFrame,'8. Backend ');
       private.BackEntry := dws.entry(BackFrame,width=10,background='white');
       private.BackButton:= dws.button(BackFrame,'List',type='menu');
       for (i in 1:len(backlist)) {
               backbut[i]:=dws.button(private.BackButton,backlist[i]);
       }
# Receiver Button Fills
        whenever recbut[1]->press do {
                private.RecEntry->delete('start','end');
                temp:=split(reclist[1],"")
                temp2:=paste(temp[1],temp[2],sep="");
                private.RecEntry->insert(temp2);
        }
        whenever recbut[2]->press do {
                private.RecEntry->delete('start','end');
                temp:=split(reclist[2],"")
                temp2:=paste(temp[1],temp[2],sep="");
                private.RecEntry->insert(temp2);
        }
         whenever recbut[3]->press do {
                private.RecEntry->delete('start','end');
                temp:=split(reclist[3],"")
                temp2:=paste(temp[1],temp[2],sep="");
                private.RecEntry->insert(temp2);
        }
         whenever recbut[4]->press do {
                private.RecEntry->delete('start','end');
                temp:=split(reclist[4],"")
                temp2:=paste(temp[1],temp[2],sep="");
                private.RecEntry->insert(temp2);
        }
         whenever recbut[5]->press do {
                private.RecEntry->delete('start','end');
                temp:=split(reclist[5],"")
                temp2:=paste(temp[1],temp[2],sep="");
                private.RecEntry->insert(temp2);
        }
         whenever recbut[6]->press do {
                private.RecEntry->delete('start','end');
                temp:=split(reclist[6],"")
                temp2:=paste(temp[1],temp[2],sep="");
                private.RecEntry->insert(temp2);
        }
         whenever recbut[7]->press do {
                private.RecEntry->delete('start','end');
                temp:=split(reclist[7],"")
                temp2:=paste(temp[1],temp[2],sep="");
                private.RecEntry->insert(temp2);
        }
         whenever recbut[8]->press do {
                private.RecEntry->delete('start','end');
                temp:=split(reclist[8],"")
                temp2:=paste(temp[1],temp[2],sep="");
                private.RecEntry->insert(temp2);
        }
# Polarization Button Fills
        whenever polbut[1]->press do {
                private.PolEntry->delete('start','end');
                private.PolEntry->insert(pollist[1]);
        }
        whenever polbut[2]->press do {
                private.PolEntry->delete('start','end');
                private.PolEntry->insert(pollist[2]);
        }
        whenever polbut[3]->press do {
                private.PolEntry->delete('start','end');
                private.PolEntry->insert(pollist[3]);
        }
        whenever polbut[4]->press do {
                private.PolEntry->delete('start','end');
                private.PolEntry->insert(pollist[4]);
        }
        whenever polbut[5]->press do {
                private.PolEntry->delete('start','end');
                private.PolEntry->insert(pollist[5]);
        }
        whenever polbut[6]->press do {
                private.PolEntry->delete('start','end');
                private.PolEntry->insert(pollist[6]);
        }
        whenever polbut[7]->press do {
                private.PolEntry->delete('start','end');
                private.PolEntry->insert(pollist[7]);
	}
# Temporal Properties Button Fills
        whenever temppropbut[1]->press do {
                private.PropEntry1->delete('start','end');
                private.PropEntry1->insert(tempproplist[1]);
        }
        whenever temppropbut[2]->press do {
                private.PropEntry1->delete('start','end');
                private.PropEntry1->insert(tempproplist[2]);
        }
        whenever temppropbut[3]->press do {
                private.PropEntry1->delete('start','end');
                private.PropEntry1->insert(tempproplist[3]);
        }
        whenever temppropbut[4]->press do {
                private.PropEntry1->delete('start','end');
                private.PropEntry1->insert(tempproplist[4]);
        }
        whenever temppropbut[5]->press do {
                private.PropEntry1->delete('start','end');
                private.PropEntry1->insert(tempproplist[5]);
        }
# Modulation Properties
        whenever modpropbut[1]->press do {
                private.PropEntry2->delete('start','end');
                private.PropEntry2->insert(modproplist[1]);
        }
        whenever modpropbut[2]->press do {
                private.PropEntry2->delete('start','end');
                private.PropEntry2->insert(modproplist[2]);
        }
        whenever modpropbut[3]->press do {
                private.PropEntry2->delete('start','end');
                private.PropEntry2->insert(modproplist[3]);
        }
        whenever modpropbut[4]->press do {
                private.PropEntry2->delete('start','end');
                private.PropEntry2->insert(modproplist[4]);
        }
        whenever modpropbut[5]->press do {
                private.PropEntry2->delete('start','end');
                private.PropEntry2->insert(modproplist[5]);
        }
        whenever modpropbut[6]->press do {
                private.PropEntry2->delete('start','end');
                private.PropEntry2->insert(modproplist[6]);
        }
# Frequency Properties
        whenever freqpropbut[1]->press do {
                private.PropEntry3->delete('start','end');
                private.PropEntry3->insert(freqproplist[1]);
        }
        whenever freqpropbut[2]->press do {
                private.PropEntry3->delete('start','end');
                private.PropEntry3->insert(freqproplist[2]);
        }
        whenever freqpropbut[3]->press do {
                private.PropEntry3->delete('start','end');
                private.PropEntry3->insert(freqproplist[3]);
        }
        whenever freqpropbut[4]->press do {
                private.PropEntry3->delete('start','end');
                private.PropEntry3->insert(freqproplist[4]);
        }
        whenever freqpropbut[5]->press do {
                private.PropEntry3->delete('start','end');
                private.PropEntry3->insert(freqproplist[5]);
        }
# Source Button Fills
        whenever sourbut[1]->press do {
                private.SourEntry->delete('start','end');
                private.SourEntry->insert(sourlist[1]);
        }
        whenever sourbut[2]->press do {
                private.SourEntry->delete('start','end');
                private.SourEntry->insert(sourlist[2]);
        }
        whenever sourbut[3]->press do {
                private.SourEntry->delete('start','end');
                private.SourEntry->insert(sourlist[3]);
        }
# Telescope Button Fills
        whenever telebut[1]->press do {
                private.TeleEntry->delete('start','end');
                private.TeleEntry->insert(telelist[1]);
        }
        whenever telebut[2]->press do {
                private.TeleEntry->delete('start','end');
                private.TeleEntry->insert(telelist[2]);
        }
# Backend Button Fills
        whenever backbut[1]->press do {
                private.BackEntry->delete('start','end');
                private.BackEntry->insert(backlist[1]);
        }
        whenever backbut[2]->press do {
                private.BackEntry->delete('start','end');
                private.BackEntry->insert(backlist[2]);
        }
        whenever backbut[3]->press do {
                private.BackEntry->delete('start','end');
                private.BackEntry->insert(backlist[3]);
        }
        whenever backbut[4]->press do {
                private.BackEntry->delete('start','end');
                private.BackEntry->insert(backlist[4]);
        }
        whenever backbut[5]->press do {
                private.BackEntry->delete('start','end');
                private.BackEntry->insert(backlist[5]);
        }
# 
        private.IniEntry := labeledEntryWithUnits(rfig.qfm,'9. Initials   ','','[Initials of Submitter]',entryWidth=10);
        private.enableEntryQuery();
# Button frame
        rfig.bf := dws.frame(rfig.qfm,side='left');
        rfig.query := dws.button (rfig.bf,' Query Table');
#        rfig.space1 := dws.button (rfig.bf,'    ',relief='flat',disabled=T,
#                       borderwidth=0);
        rfig.clear := dws.button (rfig.bf,'Clear Entries');
        rfig.browse := dws.button (rfig.bf,'Browse Data');
#        rfig.space2 := dws.button (rfig.bf,'    ',relief='flat',disabled=T,
#                       borderwidth=0);
        rfig.return := dws.button(rfig.bf,'Return to Main Menu');
        private.disablemain();
        dws.tk_release();
#
        whenever rfig.return->press do {
                sl.show('Choose an action with the buttons');
                rfig.qfm->unmap();
		private.enablemain();
		private.enablemain();
        }

        whenever rfig.clear->press do {
                private.clearQueryEntry();
        }

        whenever rfig.browse->press do {
                tableb := table('/aips++/rfi.aips++', ack=F);
               tableb.browse();
        }

	whenever rfig.query->press do {
		private.storequery();
#		print '1',private.Field1,'2',private.Field2,'3',private.Field3,'4',private.Field5,'5',private.Field6,'6',private.Field7,'7',private.Field8,'8',private.Field9,private.Field2c;
		private.query();
	}
  
	private.disablemain();
}

public.callauthorize := function () {
	wider private;
	sl.show('Enter authorization password');
	auth := ref __rfi_gui;
	dws.tk_hold();
	auth.sfm := dws.frame(wf_us,title="Submit Password",side='left');
	private.authEntry:=labeledEntryWithUnits(auth.sfm,' Password ','','[Peekaboo]',entryWidth=10);
	private.authEntry.disabledAppearance(F);
	private.disablemain();
	auth.submit := dws.button(auth.sfm,'Submit');
	whenever auth.submit->press do {
		pass := private.authEntry.getValue();	
		if (pass == "Peekaboo") {
			auth.sfm->unmap();
			rfi.callrfisubmit();
		} else {
			sl.show('Wrong Password -- Try again');
		}
	}
	dws.tk_release();
}

public.callrfisubmit := function () {
	wider private;
	sl.show('Fill Entry Fields then Press "Submit Data"');
	private.FBand := 'L';
	rfig := ref __rfi_gui;
#
	recbut:=[=];
	reclist[1]:='L Band [1150. - 1730. MHz]';
	reclist[2]:='S Band [1730. - 3950. MHz]';
	reclist[3]:='C Band [3950. - 8200. MHz]';
	reclist[4]:='X Band [8200. - 12400. MHz]'
	reclist[5]:='Ku Band [12400. - 18000. MHz]';
	reclist[6]:='K Band [18000. - 26500. MHz]';
	reclist[7]:='Ka Band [26500. - 33000. MHz]';
	reclist[8]:='Q Band [40000. - 50000. MHz]';
	polbut:=[=];
	pollist:="Linear-X Linear-Y RCP LCP Both-Linear Both-Circular Unknown";
        temppropbut:=[=];
        tempproplist:="Continuous Regularly_Pulsed Intermittent Transient Other"
        modpropbut:=[=];
        modproplist:="Voice 60/120_Hz Telemetry Noisy None Other"
        freqpropbut:=[=];
        freqproplist:="Broadband One_Narrow Several_Narrow Many_Narrow Other"
	sourbut:=[=];
	sourlist:="Satellite Internal Unknown";
	telebut:=[=];
	telelist:="140foot GBT";
	backbut:=[=];
	backlist:="Spectral_Processor DCR Mark_IV_Autocorrelator GBT_Spectrometer Other";
#
	dws.tk_hold();
	rfig.sfm := dws.frame(wf_us,title="Submit RFI Data",background="blue");
# Entry frames for input
        private.TimeEntry := labeledEntryWithUnits(rfig.sfm,'1. Time        ','','[dd-Mmm-yyyy/hh:mm:ss]', entryWidth=22);
	FqFrame:=dws.frame(rfig.sfm,side='left');
        private.FreqEntry := labeledEntryWithUnits(FqFrame,'2a. Frequency  ','','GHz', entryWidth=10);
#
        RecFrame := dws.frame(FqFrame,side='left');
        RecLabel := dws.label(RecFrame,'2b. Receiver');
        private.RecEntry :=dws.entry(RecFrame,width=10,background='white');
        private.RecButton:=dws.button(RecFrame,'List',type="menu");
        for (i in 1:len(reclist)) {
                recbut[i]:=dws.button(private.RecButton,reclist[i]);
        }
#
	PosFrame:=dws.frame(rfig.sfm,side='left');
	private.AzEntry := labeledEntryWithUnits(PosFrame,'3a. Azimuth    ','','Deg.', entryWidth=8);
	private.ElEntry := labeledEntryWithUnits(PosFrame,'3b. Elevation','','Deg.',entryWidth=8);
#
	PolFrame := dws.frame(rfig.sfm,side='left');
	PolLabel := dws.label(PolFrame,'4. Polarization     ');
	private.PolEntry := dws.entry(PolFrame,width=10,background='white');
	private.PolButton:= dws.button(PolFrame,'List',type='menu')
	for (i in 1:len(pollist)){
		polbut[i]:=dws.button(private.PolButton,pollist[i]);
	}
#
	PropFrame1 := dws.frame(rfig.sfm,side='left');
	PropLabel1 := dws.label(PropFrame1,'5a. Temporal Properties');
	private.PropEntry1 := dws.entry(PropFrame1,width=15,background='white');
	private.PropButton1:= dws.button(PropFrame1,'List',type='menu');
	for (i in 1:len(tempproplist)) {
		temppropbut[i]:=dws.button(private.PropButton1,tempproplist[i]);
	}
        PropFrame2 := dws.frame(rfig.sfm,side='left');
        PropLabel2 := dws.label(PropFrame2,'5b. Modulation Properties');
        private.PropEntry2 := dws.entry(PropFrame2,width=15,background='white');
        private.PropButton2:= dws.button(PropFrame2,'List',type='menu');
        for (i in 1:len(modproplist)) {
                modpropbut[i]:=dws.button(private.PropButton2,modproplist[i]);
        }
        PropFrame3 := dws.frame(rfig.sfm,side='left');
        PropLabel3 := dws.label(PropFrame3,'5c. Frequency Properties');
        private.PropEntry3 := dws.entry(PropFrame3,width=15,background='white');
        private.PropButton3:= dws.button(PropFrame3,'List',type='menu');
        for (i in 1:len(freqproplist)) {
                freqpropbut[i]:=dws.button(private.PropButton3,freqproplist[i]);
        }
#
       SourFrame := dws.frame(rfig.sfm,side='left');
       SourLabel := dws.label(SourFrame,'6. Source           ');
       private.SourEntry := dws.entry(SourFrame,width=10,background='white');
       private.SourButton:= dws.button(SourFrame,'List',type='menu');
       for (i in 1:len(sourlist)) {
               sourbut[i]:=dws.button(private.SourButton,sourlist[i]);
       }
#
	TlFrame :=dws.frame(rfig.sfm,side='left');
       TeleFrame := dws.frame(TlFrame,side='left');
       TeleLabel := dws.label(TeleFrame,'7. Telescope       ');
       private.TeleEntry := dws.entry(TeleFrame,width=10,background='white');
       private.TeleButton:= dws.button(TeleFrame,'List',type='menu');
       for (i in 1:len(telelist)) {
               telebut[i]:=dws.button(private.TeleButton,telelist[i]);
       }
#
       BackFrame := dws.frame(TlFrame,side='left');
       BackLabel := dws.label(BackFrame,'8. Backend ');
       private.BackEntry := dws.entry(BackFrame,width=10,background='white');
       private.BackButton:= dws.button(BackFrame,'List',type='menu');
       for (i in 1:len(backlist)) {
               backbut[i]:=dws.button(private.BackButton,backlist[i]);
       }
# Receiver Button Fills
	whenever recbut[1]->press do {
		private.RecEntry->delete('start','end');
		temp:=split(reclist[1],"")
		temp2:=paste(temp[1],temp[2],sep="");
		private.RecEntry->insert(temp2);
	}
        whenever recbut[2]->press do {
                private.RecEntry->delete('start','end');
                temp:=split(reclist[2],"")
                temp2:=paste(temp[1],temp[2],sep="");
                private.RecEntry->insert(temp2);
        }
         whenever recbut[3]->press do {
                private.RecEntry->delete('start','end');
                temp:=split(reclist[3],"")
                temp2:=paste(temp[1],temp[2],sep="");
                private.RecEntry->insert(temp2);
        }
         whenever recbut[4]->press do {
                private.RecEntry->delete('start','end');
                temp:=split(reclist[4],"")
                temp2:=paste(temp[1],temp[2],sep="");
                private.RecEntry->insert(temp2);
        }
         whenever recbut[5]->press do {
                private.RecEntry->delete('start','end');
                temp:=split(reclist[5],"")
                temp2:=paste(temp[1],temp[2],sep="");
                private.RecEntry->insert(temp2);
        }
         whenever recbut[6]->press do {
                private.RecEntry->delete('start','end');
                temp:=split(reclist[6],"")
                temp2:=paste(temp[1],temp[2],sep="");
                private.RecEntry->insert(temp2);
        }
         whenever recbut[7]->press do {
                private.RecEntry->delete('start','end');
                temp:=split(reclist[7],"")
                temp2:=paste(temp[1],temp[2],sep="");
                private.RecEntry->insert(temp2);
        }
         whenever recbut[8]->press do {
                private.RecEntry->delete('start','end');
                temp:=split(reclist[8],"")
                temp2:=paste(temp[1],temp[2],sep="");
                private.RecEntry->insert(temp2);
        }
# Polarization Button Fills
	whenever polbut[1]->press do {
		private.PolEntry->delete('start','end');
		private.PolEntry->insert(pollist[1]);
	}
        whenever polbut[2]->press do {
                private.PolEntry->delete('start','end');
                private.PolEntry->insert(pollist[2]);
        }
        whenever polbut[3]->press do {
                private.PolEntry->delete('start','end');
                private.PolEntry->insert(pollist[3]);
        }
        whenever polbut[4]->press do {
                private.PolEntry->delete('start','end');
                private.PolEntry->insert(pollist[4]);
        }
        whenever polbut[5]->press do {
                private.PolEntry->delete('start','end');
                private.PolEntry->insert(pollist[5]);
        }
        whenever polbut[6]->press do {
                private.PolEntry->delete('start','end');
                private.PolEntry->insert(pollist[6]);
        }
        whenever polbut[7]->press do {
                private.PolEntry->delete('start','end');
                private.PolEntry->insert(pollist[7]);
	}
# Temporal Properties Button Fills
        whenever temppropbut[1]->press do {
                private.PropEntry1->delete('start','end');
                private.PropEntry1->insert(tempproplist[1]);
        }
        whenever temppropbut[2]->press do {
                private.PropEntry1->delete('start','end');
                private.PropEntry1->insert(tempproplist[2]);
        }
        whenever temppropbut[3]->press do {
                private.PropEntry1->delete('start','end');
                private.PropEntry1->insert(tempproplist[3]);
        }
        whenever temppropbut[4]->press do {
                private.PropEntry1->delete('start','end');
                private.PropEntry1->insert(tempproplist[4]);
        }
        whenever temppropbut[5]->press do {
                private.PropEntry1->delete('start','end');
                private.PropEntry1->insert(tempproplist[5]);
        }
# Modulation Properties
        whenever modpropbut[1]->press do {
                private.PropEntry2->delete('start','end');
                private.PropEntry2->insert(modproplist[1]);
        }
        whenever modpropbut[2]->press do {
                private.PropEntry2->delete('start','end');
                private.PropEntry2->insert(modproplist[2]);
        }
        whenever modpropbut[3]->press do {
                private.PropEntry2->delete('start','end');
                private.PropEntry2->insert(modproplist[3]);
        }
        whenever modpropbut[4]->press do {
                private.PropEntry2->delete('start','end');
                private.PropEntry2->insert(modproplist[4]);
        }
        whenever modpropbut[5]->press do {
                private.PropEntry2->delete('start','end');
                private.PropEntry2->insert(modproplist[5]);
        }
        whenever modpropbut[6]->press do {
                private.PropEntry2->delete('start','end');
                private.PropEntry2->insert(modproplist[6]);
        }
# Frequency Properties
        whenever freqpropbut[1]->press do {
                private.PropEntry3->delete('start','end');
                private.PropEntry3->insert(freqproplist[1]);
        }
        whenever freqpropbut[2]->press do {
                private.PropEntry3->delete('start','end');
                private.PropEntry3->insert(freqproplist[2]);
        }
        whenever freqpropbut[3]->press do {
                private.PropEntry3->delete('start','end');
                private.PropEntry3->insert(freqproplist[3]);
        }
        whenever freqpropbut[4]->press do {
                private.PropEntry3->delete('start','end');
                private.PropEntry3->insert(freqproplist[4]);
        }
        whenever freqpropbut[5]->press do {
                private.PropEntry3->delete('start','end');
                private.PropEntry3->insert(freqproplist[5]);
        }
# Source Button Fills
        whenever sourbut[1]->press do {
                private.SourEntry->delete('start','end');
                private.SourEntry->insert(sourlist[1]);
        }
        whenever sourbut[2]->press do {
                private.SourEntry->delete('start','end');
                private.SourEntry->insert(sourlist[2]);
        }
        whenever sourbut[3]->press do {
                private.SourEntry->delete('start','end');
                private.SourEntry->insert(sourlist[3]);
        }
# Telescope Button Fills
        whenever telebut[1]->press do {
                private.TeleEntry->delete('start','end');
                private.TeleEntry->insert(telelist[1]);
        }
        whenever telebut[2]->press do {
                private.TeleEntry->delete('start','end');
                private.TeleEntry->insert(telelist[2]);
        }
# Backend Button Fills
        whenever backbut[1]->press do {
                private.BackEntry->delete('start','end');
                private.BackEntry->insert(backlist[1]);
        }
        whenever backbut[2]->press do {
                private.BackEntry->delete('start','end');
                private.BackEntry->insert(backlist[2]);
        }
        whenever backbut[3]->press do {
                private.BackEntry->delete('start','end');
                private.BackEntry->insert(backlist[3]);
        }
        whenever backbut[4]->press do {
                private.BackEntry->delete('start','end');
                private.BackEntry->insert(backlist[4]);
        }
        whenever backbut[5]->press do {
                private.BackEntry->delete('start','end');
                private.BackEntry->insert(backlist[5]);
        }
#
	private.ComEntry := labeledEntryWithUnits(rfig.sfm,'9. Comments    ','','[In single quotes]',entryWidth=25);
	private.IniEntry := labeledEntryWithUnits(rfig.sfm,'10. Initials   ','','[Initials of Submitter]',entryWidth=10);
	private.enableEntry();
# Button frame
	rfig.bf := dws.frame(rfig.sfm,side='left');
	rfig.submit := dws.button (rfig.bf,'Submit Data');
#	rfig.space1 := dws.button (rfig.bf,'    ',relief='flat',disabled=T,
#			borderwidth=0);
	rfig.clear := dws.button (rfig.bf,'Clear Entries');
#	rfig.space2 := dws.button (rfig.bf,'    ',relief='flat',disabled=T,
#			borderwidth=0);
	rfig.browse := dws.button (rfig.bf,'Browse Data');
	rfig.return := dws.button(rfig.bf,'Return to Main Menu'); 
	private.disablemain();
#
	dws.tk_release();
#
	whenever rfig.clear->press do {
		private.clearEntry();
	}
#
	whenever rfig.return->press do {
		sl.show('Choose an action with the buttons');
		rfig.sfm->unmap();
		private.enablemain();
                private.enablemain();
	}
	whenever rfig.submit->press do {
		private.testprint();
		if (strlen(private.Field1) != 0 && private.Field2a != 0 && 
		strlen(private.Field4) != 0 && strlen(private.Field10) != 0) {
			sl.show('Fill Entry Fields then Press "Submit Data"');
			private.writeRow();
		} else {
			sl.show('Must specify the Time,Freq,Polarization and Initials Fields');
			ok:=fmessagebox('Must specify the Time, Frequency, Polarization and Initials Fields','RED');
		}
	}
	whenever rfig.browse->press do {
		tableb := table('/aips++/rfi.aips++', ack=F);
		tableb.browse();
	}
#
}

const public.leave := function() {
	exit;
}

return public;

}

# make standard abbreviation
const rfi := ref rfiutils();
#
#
